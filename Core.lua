-- BookReader – Core.lua
-- No external library dependencies at all.
-- Persistence: plain SavedVariables table "BookReaderDB", merged with
-- defaults on load.  WoW serialises it automatically.

BookReader = {}
BookReader.books       = {}
BookReader.currentBook = nil
BookReader.currentPage = 1

-- ── defaults ──────────────────────────────────────────────────────────────
local DEFAULTS = {
    hide            = false,
    pageSize        = 25,
    windowWidth     = 600,
    windowHeight    = 450,
    minimapAngle    = 315,
}

local function ApplyDefaults(t)
    for k, v in pairs(DEFAULTS) do
        if t[k] == nil then t[k] = v end
    end
end

-- SavedVariables are already populated by WoW before any addon Lua runs.
-- Init here so that BookList.lua (which executes right after this file)
-- can safely read BookReaderDB.pageSize.
BookReaderDB = BookReaderDB or {}
ApplyDefaults(BookReaderDB)
BookReader.db = { profile = BookReaderDB }

-- Load custom books from saved data
local function LoadCustomBooks()
    if not BookReaderDB.customBooks then return end
    
    for title, content in pairs(BookReaderDB.customBooks) do
        local lines = {}
        for line in content:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
        end
        
        local pageSize = BookReaderDB.pageSize or 25
        local totalPages = math.ceil(#lines / pageSize)
        if totalPages < 1 then totalPages = 1 end
        
        BookReader.books[title] = {
            title = title,
            lines = lines,
            totalPages = totalPages,
            custom = true,
        }
    end
end

LoadCustomBooks()

-- ── minimap icon ──────────────────────────────────────────────────────────
local function PositionIcon(btn)
    local angle  = math.rad(BookReaderDB.minimapAngle or 315)
    local radius = 80
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius,
        math.sin(angle) * radius)
end

local function CreateMinimapIcon()
    local btn = CreateFrame("Button", "BookReaderMinimapBtn", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("anyUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetClampedToScreen(true)

    -- Icon (book texture)
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")

    -- Border ring overlay
    local ring = btn:CreateTexture(nil, "OVERLAY")
    ring:SetSize(53, 53)
    ring:SetTexture(136430)
    ring:SetPoint("CENTER", btn, "CENTER", 0, 0)

    -- Hover highlight
    local hi = btn:CreateTexture(nil, "HIGHLIGHT")
    hi:SetAllPoints(icon)
    hi:SetColorTexture(1, 1, 1, 0.3)
    hi:Hide()

    btn:SetScript("OnEnter", function(self)
        hi:Show()
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFFFFCC00Parchment Reader|r")
        GameTooltip:AddLine("|cFF00FFFFLeft-click|r – open reader", 1,1,1)
        GameTooltip:AddLine("|cFF00FFFFRight-click|r – settings",   1,1,1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        hi:Hide()
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            BookReader:ToggleReader()
        elseif mouseButton == "RightButton" then
            BookReader:ToggleSettings()
        end
    end)

    -- ── drag around minimap edge ──
    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local s      = Minimap:GetEffectiveScale()
            cx, cy = cx / s, cy / s

            local angle = math.atan2(cy - my, cx - mx)
            BookReaderDB.minimapAngle = math.deg(angle)
            PositionIcon(self)
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    PositionIcon(btn)
    return btn
end

-- ── toggle reader / settings ──────────────────────────────────────────────
function BookReader:ToggleReader()
    if BookReaderFrame and BookReaderFrame:IsShown() then
        BookReaderFrame:Hide()
    else
        if not BookReaderFrame then
            self:CreateReaderFrame()
        end
        BookReaderFrame:Show()
        self:UpdateReader()
    end
end

function BookReader:ToggleSettings()
    if BookReaderSettingsFrame and BookReaderSettingsFrame:IsShown() then
        BookReaderSettingsFrame:Hide()
    else
        if not BookReaderSettingsFrame then
            self:CreateSettingsFrame()
        end
        BookReaderSettingsFrame:Show()
    end
end

-- ── book management ───────────────────────────────────────────────────────
function BookReader:LoadBook(bookName)
    if not self.books[bookName] then
        print("|cFF33FF99BookReader:|r Book not found: " .. bookName)
        return false
    end

    self.currentBook = bookName
    self.currentPage = 1

    if BookReaderFrame and BookReaderFrame.title then
        BookReaderFrame.title:SetText(bookName)
    end

    self:UpdateReader()
    
    if BookReaderFrame then
        self:RefreshBookList()
    end
    
    return true
end

function BookReader:NextPage()
    if not self.currentBook then return end
    local book = self.books[self.currentBook]
    if self.currentPage < book.totalPages then
        self.currentPage = self.currentPage + 1
        self:UpdateReader()
    end
end

function BookReader:PrevPage()
    if not self.currentBook then return end
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:UpdateReader()
    end
end

-- ── render current page ───────────────────────────────────────────────────
function BookReader:UpdateReader()
    if not BookReaderFrame then return end

    if not self.currentBook or not self.books[self.currentBook] then
        BookReaderFrame.contentText:SetText("Select a book from the list on the left.")
        BookReaderFrame.pageText:SetText("")
        BookReaderFrame.prevButton:Disable()
        BookReaderFrame.nextButton:Disable()
        return
    end

    local book      = self.books[self.currentBook]
    local pageSize  = BookReaderDB.pageSize
    local startLine = (self.currentPage - 1) * pageSize + 1
    local endLine   = math.min(startLine + pageSize - 1, #book.lines)

    local pageLines = {}
    for i = startLine, endLine do
        table.insert(pageLines, book.lines[i])
    end

    BookReaderFrame.contentText:SetText(table.concat(pageLines, "\n"))
    BookReaderFrame.pageText:SetText(
        string.format("Page %d / %d", self.currentPage, book.totalPages))

    if self.currentPage > 1 then
        BookReaderFrame.prevButton:Enable()
    else
        BookReaderFrame.prevButton:Disable()
    end
    
    if self.currentPage < book.totalPages then
        BookReaderFrame.nextButton:Enable()
    else
        BookReaderFrame.nextButton:Disable()
    end
end

-- ── bootstrap ─────────────────────────────────────────────────────────────
local _boot = CreateFrame("Frame")
_boot:RegisterEvent("PLAYER_ENTERING_WORLD")

_boot:SetScript("OnEvent", function(self, event, addonName)

    if event == "PLAYER_ENTERING_WORLD" then
        if not BookReader.minimapBtn then
            BookReader.minimapBtn = CreateMinimapIcon()
        end

        if BookReaderDB.hide then
            BookReader.minimapBtn:Hide()
        else
            BookReader.minimapBtn:Show()
        end
        
        print("|cFF33FF99Parchment Reader|r loaded – click the minimap icon to start reading.")
    end
end)

-- ── slash commands ────────────────────────────────────────────────────────
SLASH_BOOKREADER1 = "/br"
SLASH_BOOKREADER2 = "/bookreader"
SlashCmdList["BOOKREADER"] = function(msg)
    msg = strtrim(msg):lower()

    if msg == "reload" or msg == "reset" then
        -- Recreate the reader frame to apply UI changes
        if BookReaderFrame then
            BookReaderFrame:Hide()
            BookReaderFrame = nil
        end
        print("|cFF33FF99BookReader:|r Frame reset. Open the reader again to see changes.")
    else
        -- Default: toggle the reader
        BookReader:ToggleReader()
    end
end

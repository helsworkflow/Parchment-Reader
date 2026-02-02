-- ParchmentReader – Core.lua
-- No external library dependencies at all.
-- Persistence: plain SavedVariables table "ParchmentReaderDB", merged with
-- defaults on load.  WoW serialises it automatically.

ParchmentReader = {}
ParchmentReader.books       = {}
ParchmentReader.currentBook = nil
ParchmentReader.currentPage = 1

-- ── defaults ──────────────────────────────────────────────────────────────
local DEFAULTS = {
    hide            = false,
    pageSize        = 25,
    windowWidth     = 600,
    windowHeight    = 450,
    minimapAngle    = 315,
    fontSize        = 14,
    fontName        = "QuestFont",
}

local function ApplyDefaults(t)
    for k, v in pairs(DEFAULTS) do
        if t[k] == nil then t[k] = v end
    end
end

-- SavedVariables are already populated by WoW before any addon Lua runs.
-- Init here so that BookList.lua (which executes right after this file)
-- can safely read ParchmentReaderDB.pageSize.
ParchmentReaderDB = ParchmentReaderDB or {}
ApplyDefaults(ParchmentReaderDB)
ParchmentReader.db = { profile = ParchmentReaderDB }

-- Load custom books from saved data
local function LoadCustomBooks()
    if not ParchmentReaderDB.customBooks then return end
    
    for title, content in pairs(ParchmentReaderDB.customBooks) do
        local lines = {}
        for line in content:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
        end
        
        local pageSize = ParchmentReaderDB.pageSize or 25
        local totalPages = math.ceil(#lines / pageSize)
        if totalPages < 1 then totalPages = 1 end
        
        ParchmentReader.books[title] = {
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
    local angle  = math.rad(ParchmentReaderDB.minimapAngle or 315)
    local radius = 80
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius,
        math.sin(angle) * radius)
end

local function CreateMinimapIcon()
    local btn = CreateFrame("Button", "ParchmentReaderMinimapBtn", Minimap)
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
            ParchmentReader:ToggleReader()
        elseif mouseButton == "RightButton" then
            ParchmentReader:ToggleSettings()
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
            ParchmentReaderDB.minimapAngle = math.deg(angle)
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
function ParchmentReader:ToggleReader()
    if ParchmentReaderFrame and ParchmentReaderFrame:IsShown() then
        ParchmentReaderFrame:Hide()
    else
        if not ParchmentReaderFrame then
            self:CreateReaderFrame()
        end
        ParchmentReaderFrame:Show()
        self:UpdateReader()
    end
end

function ParchmentReader:ToggleSettings()
    if ParchmentReaderSettingsFrame and ParchmentReaderSettingsFrame:IsShown() then
        ParchmentReaderSettingsFrame:Hide()
    else
        if not ParchmentReaderSettingsFrame then
            self:CreateSettingsFrame()
        end
        ParchmentReaderSettingsFrame:Show()
    end
end

function ParchmentReader:ToggleSidebar()
    if not ParchmentReaderFrame then return end

    ParchmentReaderDB.sidebarCollapsed = not ParchmentReaderDB.sidebarCollapsed

    local frame = ParchmentReaderFrame
    local sidebar = frame.sidebar
    local parchment = frame.parchment
    local toggleBtn = frame.toggleBtn

    if ParchmentReaderDB.sidebarCollapsed then
        -- Collapse: hide sidebar completely
        sidebar:Hide()

        -- Move toggle button to bottom left corner of main frame
        toggleBtn:SetParent(frame)
        toggleBtn:ClearAllPoints()
        toggleBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
        toggleBtn:SetText("Show Books")

        -- Reposition parchment to fill the whole area
        parchment:ClearAllPoints()
        parchment:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -24)
        parchment:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 44)
    else
        -- Expand: show sidebar
        sidebar:Show()

        -- Move toggle button back to sidebar
        toggleBtn:SetParent(sidebar)
        toggleBtn:ClearAllPoints()
        toggleBtn:SetPoint("BOTTOM", sidebar, "BOTTOM", 0, 8)
        toggleBtn:SetText("Hide Books")

        -- Reposition parchment to be next to sidebar
        parchment:ClearAllPoints()
        parchment:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 4, -24)
        parchment:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 44)
    end
end

-- ── book management ───────────────────────────────────────────────────────
function ParchmentReader:LoadBook(bookName)
    if not self.books[bookName] then
        print("|cFF33FF99ParchmentReader:|r Book not found: " .. bookName)
        return false
    end

    self.currentBook = bookName
    self.currentPage = 1

    if ParchmentReaderFrame and ParchmentReaderFrame.title then
        ParchmentReaderFrame.title:SetText(bookName)
    end

    self:UpdateReader()
    
    if ParchmentReaderFrame then
        self:RefreshBookList()
    end
    
    return true
end

function ParchmentReader:NextPage()
    if not self.currentBook then return end
    local book = self.books[self.currentBook]
    if self.currentPage < book.totalPages then
        self.currentPage = self.currentPage + 1
        self:UpdateReader()
    end
end

function ParchmentReader:PrevPage()
    if not self.currentBook then return end
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:UpdateReader()
    end
end

-- ── render current page ───────────────────────────────────────────────────
function ParchmentReader:UpdateReader()
    if not ParchmentReaderFrame then return end

    if not self.currentBook or not self.books[self.currentBook] then
        ParchmentReaderFrame.contentText:SetText("Select a book from the list on the left.")
        ParchmentReaderFrame.pageText:SetText("")
        ParchmentReaderFrame.prevButton:Disable()
        ParchmentReaderFrame.nextButton:Disable()
        return
    end

    local book      = self.books[self.currentBook]
    local pageSize  = ParchmentReaderDB.pageSize
    local startLine = (self.currentPage - 1) * pageSize + 1
    local endLine   = math.min(startLine + pageSize - 1, #book.lines)

    local pageLines = {}
    for i = startLine, endLine do
        table.insert(pageLines, book.lines[i])
    end

    ParchmentReaderFrame.contentText:SetText(table.concat(pageLines, "\n"))
    ParchmentReaderFrame.pageText:SetText(
        string.format("Page %d / %d", self.currentPage, book.totalPages))

    if self.currentPage > 1 then
        ParchmentReaderFrame.prevButton:Enable()
    else
        ParchmentReaderFrame.prevButton:Disable()
    end
    
    if self.currentPage < book.totalPages then
        ParchmentReaderFrame.nextButton:Enable()
    else
        ParchmentReaderFrame.nextButton:Disable()
    end
end

-- ── update font ────────────────────────────────────────────────────────────
function ParchmentReader:UpdateFont()
    if not ParchmentReaderFrame or not ParchmentReaderFrame.contentText then return end

    local contentText = ParchmentReaderFrame.contentText
    local fontName = ParchmentReaderDB.fontName or "QuestFont"
    local fontSize = ParchmentReaderDB.fontSize or 14

    if fontName:match("%.TTF$") then
        -- If it's a TTF file
        contentText:SetFont("Fonts\\" .. fontName, fontSize)
    else
        -- If it's a font object (QuestFont, GameFontNormal, etc)
        local fontObject = _G[fontName]
        if fontObject then
            local file, height, flags = fontObject:GetFont()
            contentText:SetFont(file, fontSize, flags)
        else
            -- Fallback
            contentText:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
        end
    end

    self:UpdateReader()
end

-- ── bootstrap ─────────────────────────────────────────────────────────────
local _boot = CreateFrame("Frame")
_boot:RegisterEvent("PLAYER_ENTERING_WORLD")

_boot:SetScript("OnEvent", function(self, event, addonName)

    if event == "PLAYER_ENTERING_WORLD" then
        if not ParchmentReader.minimapBtn then
            ParchmentReader.minimapBtn = CreateMinimapIcon()
        end

        if ParchmentReaderDB.hide then
            ParchmentReader.minimapBtn:Hide()
        else
            ParchmentReader.minimapBtn:Show()
        end
        
        print("|cFF33FF99Parchment Reader|r loaded – click the minimap icon to start reading.")
    end
end)

-- ── slash commands ────────────────────────────────────────────────────────
SLASH_PARCHMENTREADER1 = "/pr"
SLASH_PARCHMENTREADER2 = "/parchmentreader"
SlashCmdList["PARCHMENTREADER"] = function(msg)
    msg = strtrim(msg):lower()

    if msg == "reload" or msg == "reset" then
        -- Recreate the reader frame to apply UI changes
        if ParchmentReaderFrame then
            ParchmentReaderFrame:Hide()
            ParchmentReaderFrame = nil
        end
        print("|cFF33FF99ParchmentReader:|r Frame reset. Open the reader again to see changes.")
    else
        -- Default: toggle the reader
        ParchmentReader:ToggleReader()
    end
end

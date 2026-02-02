-- ReaderFrame.lua
-- Parchment-style reader with sidebar book list on the left.

function ParchmentReader:CreateReaderFrame()
    local frame = CreateFrame("Frame", "ParchmentReaderFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(self.db.profile.windowWidth, self.db.profile.windowHeight)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame.TitleBg, 0, -3)
    frame.title:SetText("Parchment Reader")
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- LEFT SIDEBAR: Book list
    -- ═══════════════════════════════════════════════════════════════════════
    
    local sidebar = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -24)
    sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4)
    sidebar:SetWidth(180)
    
    local sidebarTitle = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sidebarTitle:SetPoint("TOP", sidebar, "TOP", 0, -8)
    sidebarTitle:SetText("Books")
    frame.sidebarTitle = sidebarTitle
    
    -- Scrollable book list
    local scrollFrame = CreateFrame("ScrollFrame", nil, sidebar, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 4, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -26, 36)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(140, 1)
    scrollFrame:SetScrollChild(scrollChild)
    frame.bookListScroll = scrollChild
    frame.sidebarScroll = scrollFrame

    -- "Add Book" button at bottom of sidebar
    local addBookBtn = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    addBookBtn:SetSize(140, 24)
    addBookBtn:SetPoint("BOTTOM", sidebar, "BOTTOM", 0, 42)
    addBookBtn:SetText("+ Add Book")
    addBookBtn:SetScript("OnClick", function()
        ParchmentReader:ShowBookEditor(nil)
    end)
    frame.addBookBtn = addBookBtn

    -- "Hide Books" button
    local toggleBtn = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    toggleBtn:SetSize(150, 24)
    toggleBtn:SetPoint("BOTTOM", sidebar, "BOTTOM", 0, 8)
    toggleBtn:SetText("Hide Books")
    toggleBtn:SetScript("OnClick", function()
        ParchmentReader:ToggleSidebar()
    end)
    frame.toggleBtn = toggleBtn
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- RIGHT SIDE: Parchment content area
    -- ═══════════════════════════════════════════════════════════════════════
    
    local parchment = CreateFrame("Frame", nil, frame)
    parchment:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 4, -24)
    parchment:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 44)
    frame.parchment = parchment
    frame.sidebar = sidebar
    
    -- Parchment background (warm beige)
    local parchBg = parchment:CreateTexture(nil, "BACKGROUND")
    parchBg:SetAllPoints()
    parchBg:SetColorTexture(0.88, 0.82, 0.68, 1)
    
    -- Try to layer parchment texture on top
    local parchTile = parchment:CreateTexture(nil, "BACKGROUND")
    parchTile:SetAllPoints()
    parchTile:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-BG-Tile")
    
    -- Subtle border
    local bColor = {0.35, 0.3, 0.2}
    
    local borderTop = parchment:CreateTexture(nil, "OVERLAY")
    borderTop:SetPoint("TOPLEFT", parchment, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", parchment, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(2)
    borderTop:SetColorTexture(bColor[1], bColor[2], bColor[3], 0.8)
    
    local borderBot = parchment:CreateTexture(nil, "OVERLAY")
    borderBot:SetPoint("BOTTOMLEFT", parchment, "BOTTOMLEFT", 0, 0)
    borderBot:SetPoint("BOTTOMRIGHT", parchment, "BOTTOMRIGHT", 0, 0)
    borderBot:SetHeight(2)
    borderBot:SetColorTexture(bColor[1], bColor[2], bColor[3], 0.8)
    
    local borderLeft = parchment:CreateTexture(nil, "OVERLAY")
    borderLeft:SetPoint("TOPLEFT", parchment, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", parchment, "BOTTOMLEFT", 0, 0)
    borderLeft:SetWidth(2)
    borderLeft:SetColorTexture(bColor[1], bColor[2], bColor[3], 0.8)
    
    local borderRight = parchment:CreateTexture(nil, "OVERLAY")
    borderRight:SetPoint("TOPRIGHT", parchment, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", parchment, "BOTTOMRIGHT", 0, 0)
    borderRight:SetWidth(2)
    borderRight:SetColorTexture(bColor[1], bColor[2], bColor[3], 0.8)

    -- Content text (scrollable)
    local contentScroll = CreateFrame("ScrollFrame", nil, parchment, "UIPanelScrollFrameTemplate")
    contentScroll:SetPoint("TOPLEFT", parchment, "TOPLEFT", 8, -8)
    contentScroll:SetPoint("BOTTOMRIGHT", parchment, "BOTTOMRIGHT", -26, 32)
    
    local contentChild = CreateFrame("Frame", nil, contentScroll)
    contentChild:SetSize(contentScroll:GetWidth() - 10, 1)
    contentScroll:SetScrollChild(contentChild)

    local contentText = contentChild:CreateFontString(nil, "OVERLAY")
    contentText:SetPoint("TOPLEFT", contentChild, "TOPLEFT", 8, -8)
    contentText:SetWidth(contentChild:GetWidth() - 16)
    contentText:SetJustifyH("LEFT")
    contentText:SetJustifyV("TOP")
    contentText:SetSpacing(2)
    contentText:SetTextColor(0.1, 0.1, 0.1)

    -- Apply font settings
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

    contentText:SetText("Select a book from the list on the left.")
    frame.contentText = contentText
    
    -- Page indicator
    local pageText = parchment:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageText:SetPoint("BOTTOM", parchment, "BOTTOM", 0, 8)
    pageText:SetTextColor(0.4, 0.35, 0.25)
    pageText:SetText("")
    frame.pageText = pageText
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- BOTTOM: Navigation buttons
    -- ═══════════════════════════════════════════════════════════════════════
    
    local prevBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    prevBtn:SetSize(100, 22)
    prevBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 190, 10)
    prevBtn:SetText("< Previous")
    prevBtn:SetScript("OnClick", function() ParchmentReader:PrevPage() end)
    frame.prevButton = prevBtn
    
    local nextBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    nextBtn:SetSize(100, 22)
    nextBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    nextBtn:SetText("Next >")
    nextBtn:SetScript("OnClick", function() ParchmentReader:NextPage() end)
    frame.nextButton = nextBtn
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- Populate book list
    -- ═══════════════════════════════════════════════════════════════════════

    frame.bookButtons = {}
    self:RefreshBookList()

    -- Apply saved sidebar state
    if ParchmentReaderDB.sidebarCollapsed then
        self:ToggleSidebar()
    end

    frame:Hide()
    return frame
end

-- Refresh the book list (call after adding/deleting books)
function ParchmentReader:RefreshBookList()
    if not ParchmentReaderFrame then return end
    
    local scrollChild = ParchmentReaderFrame.bookListScroll
    
    -- Clear existing buttons
    for _, btn in pairs(ParchmentReaderFrame.bookButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    ParchmentReaderFrame.bookButtons = {}
    
    -- Create buttons for all books
    local yOffset = 0
    local buttonHeight = 26
    local index = 1
    
    -- Sort books alphabetically
    local sortedBooks = {}
    for name, bookData in pairs(self.books) do
        table.insert(sortedBooks, {name = name, data = bookData})
    end
    table.sort(sortedBooks, function(a, b) return a.name < b.name end)
    
    for _, entry in ipairs(sortedBooks) do
        local bookName = entry.name
        local bookData = entry.data
        
        local btn = CreateFrame("Button", nil, scrollChild)
        btn:SetSize(150, buttonHeight)
        btn:SetPoint("TOPLEFT", 0, -yOffset)
        
        -- Background
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        btn.bg = bg
        
        -- Text
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", 8, 0)
        text:SetText(bookName)
        text:SetJustifyH("LEFT")
        text:SetWidth(110)
        
        -- Highlight on hover
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.3, 0.3, 0.3, 0.4)
        
        -- Click to read
        btn:SetScript("OnClick", function(self, mouseBtn)
            if mouseBtn == "LeftButton" then
                ParchmentReader:LoadBook(bookName)
                ParchmentReader:RefreshBookList()  -- refresh to show selection
            elseif mouseBtn == "RightButton" and bookData.custom then
                -- Right-click to edit (only for custom books)
                ParchmentReader:ShowBookEditor(bookName)
            end
        end)
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(bookName)
            if bookData.custom then
                GameTooltip:AddLine("Right-click to edit", 0.5, 1, 0.5)
            end
            GameTooltip:Show()
        end)
        
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Highlight if this is the current book
        if ParchmentReader.currentBook == bookName then
            bg:SetColorTexture(0.2, 0.5, 0.8, 0.3)
        end
        
        ParchmentReaderFrame.bookButtons[index] = btn
        index = index + 1
        yOffset = yOffset + buttonHeight
    end
    
    scrollChild:SetHeight(math.max(yOffset, 1))
end

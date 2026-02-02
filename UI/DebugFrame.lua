-- DebugFrame.lua - Debug information panel

function ParchmentReader:CreateDebugFrame()
    local frame = CreateFrame("Frame", "ParchmentReaderDebugFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame.TitleBg, 0, -3)
    frame.title:SetText("Debug Information")

    -- Scrollable debug text area
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 50)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth() - 10, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local debugText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    debugText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, -8)
    debugText:SetWidth(scrollChild:GetWidth() - 16)
    debugText:SetJustifyH("LEFT")
    debugText:SetJustifyV("TOP")
    debugText:SetSpacing(2)
    debugText:SetTextColor(1, 1, 1)
    debugText:SetFont("Fonts\\FRIZQT__.TTF", 11)

    frame.debugText = debugText

    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshBtn:SetSize(100, 25)
    refreshBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        ParchmentReader:UpdateDebugInfo()
    end)

    -- Copy to Chat button
    local copyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    copyBtn:SetSize(120, 25)
    copyBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 10, 0)
    copyBtn:SetText("Print to Chat")
    copyBtn:SetScript("OnClick", function()
        ParchmentReader:PrintDebugToChat()
    end)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(100, 25)
    closeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:Hide()
    return frame
end

function ParchmentReader:ShowDebugInfo()
    if not ParchmentReaderDebugFrame then
        self:CreateDebugFrame()
    end

    self:UpdateDebugInfo()
    ParchmentReaderDebugFrame:Show()
end

function ParchmentReader:UpdateDebugInfo()
    if not ParchmentReaderDebugFrame then return end

    local info = {}

    -- Header
    table.insert(info, "|cFFFFFF00=== ParchmentReader Debug Info ===|r")
    table.insert(info, "")

    -- SavedVariables info
    table.insert(info, "|cFF00FF00[SavedVariables Status]|r")
    table.insert(info, "ParchmentReaderDB exists: " .. tostring(ParchmentReaderDB ~= nil))

    if ParchmentReaderDB then
        table.insert(info, "customBooks exists: " .. tostring(ParchmentReaderDB.customBooks ~= nil))

        if ParchmentReaderDB.customBooks then
            local savedCount = 0
            for _ in pairs(ParchmentReaderDB.customBooks) do
                savedCount = savedCount + 1
            end
            table.insert(info, "Books in SavedVariables: " .. savedCount)
        end

        -- Settings
        table.insert(info, "")
        table.insert(info, "|cFF00FF00[Settings]|r")
        table.insert(info, "Page Size: " .. tostring(ParchmentReaderDB.pageSize))
        table.insert(info, "Window Width: " .. tostring(ParchmentReaderDB.windowWidth))
        table.insert(info, "Window Height: " .. tostring(ParchmentReaderDB.windowHeight))
        table.insert(info, "Font Name: " .. tostring(ParchmentReaderDB.fontName))
        table.insert(info, "Font Size: " .. tostring(ParchmentReaderDB.fontSize))
        table.insert(info, "Minimap Hidden: " .. tostring(ParchmentReaderDB.hide))
        table.insert(info, "Sidebar Collapsed: " .. tostring(ParchmentReaderDB.sidebarCollapsed))
    end

    -- Memory info
    table.insert(info, "")
    table.insert(info, "|cFF00FF00[Books in Memory]|r")

    local memoryCount = 0
    local customCount = 0
    local defaultCount = 0

    for _ in pairs(self.books) do
        memoryCount = memoryCount + 1
    end

    for _, book in pairs(self.books) do
        if book.custom then
            customCount = customCount + 1
        else
            defaultCount = defaultCount + 1
        end
    end

    table.insert(info, "Total books loaded: " .. memoryCount)
    table.insert(info, "Custom books: " .. customCount)
    table.insert(info, "Default books: " .. defaultCount)

    -- Current state
    table.insert(info, "")
    table.insert(info, "|cFF00FF00[Current State]|r")
    table.insert(info, "Current book: " .. tostring(self.currentBook or "none"))
    table.insert(info, "Current page: " .. tostring(self.currentPage))
    table.insert(info, "Reader frame exists: " .. tostring(ParchmentReaderFrame ~= nil))
    table.insert(info, "Settings frame exists: " .. tostring(ParchmentReaderSettingsFrame ~= nil))
    table.insert(info, "Editor frame exists: " .. tostring(ParchmentReaderEditorFrame ~= nil))

    -- List all books
    table.insert(info, "")
    table.insert(info, "|cFF00FF00[Book List]|r")

    local sortedBooks = {}
    for name, bookData in pairs(self.books) do
        table.insert(sortedBooks, {name = name, data = bookData})
    end
    table.sort(sortedBooks, function(a, b) return a.name < b.name end)

    for _, entry in ipairs(sortedBooks) do
        local bookName = entry.name
        local bookData = entry.data

        local bookType = bookData.custom and "|cFFFFAA00[CUSTOM]|r" or "|cFF00AAFF[DEFAULT]|r"
        local lineInfo = string.format("(%d lines, %d pages)", #bookData.lines, bookData.totalPages)

        table.insert(info, string.format("%s %s %s", bookType, bookName, lineInfo))
    end

    -- SavedVariables book list (if different from memory)
    if ParchmentReaderDB and ParchmentReaderDB.customBooks then
        local savedBooksCount = 0
        for _ in pairs(ParchmentReaderDB.customBooks) do
            savedBooksCount = savedBooksCount + 1
        end

        if savedBooksCount ~= customCount then
            table.insert(info, "")
            table.insert(info, "|cFFFF0000[WARNING]|r Mismatch between SavedVariables and Memory!")
            table.insert(info, "SavedVariables has " .. savedBooksCount .. " books, but " .. customCount .. " are loaded in memory.")
        end
    end

    -- Memory usage
    table.insert(info, "")
    table.insert(info, "|cFF00FF00[Memory Usage]|r")
    local memUsage = collectgarbage("count")
    table.insert(info, string.format("Lua memory: %.2f KB", memUsage))

    -- Join all info with newlines
    local fullText = table.concat(info, "\n")

    ParchmentReaderDebugFrame.debugText:SetText(fullText)
end

function ParchmentReader:PrintDebugToChat()
    print("|cFF33FF99=== ParchmentReader Debug Info ===|r")

    -- SavedVariables count
    local savedCount = 0
    if ParchmentReaderDB and ParchmentReaderDB.customBooks then
        for _ in pairs(ParchmentReaderDB.customBooks) do
            savedCount = savedCount + 1
        end
    end

    -- Memory count
    local memoryCount = 0
    local customCount = 0
    for _, book in pairs(self.books) do
        memoryCount = memoryCount + 1
        if book.custom then
            customCount = customCount + 1
        end
    end

    print(string.format("Books in SavedVariables: %d", savedCount))
    print(string.format("Books in Memory: %d (custom: %d)", memoryCount, customCount))
    print(string.format("Current book: %s", tostring(self.currentBook or "none")))
    print(string.format("Current page: %d", self.currentPage))

    -- List all books
    print("Loaded books:")
    local sortedBooks = {}
    for name, bookData in pairs(self.books) do
        table.insert(sortedBooks, {name = name, data = bookData})
    end
    table.sort(sortedBooks, function(a, b) return a.name < b.name end)

    for _, entry in ipairs(sortedBooks) do
        local bookType = entry.data.custom and "[CUSTOM]" or "[DEFAULT]"
        print(string.format("  %s %s (%d lines, %d pages)", bookType, entry.name, #entry.data.lines, entry.data.totalPages))
    end
end

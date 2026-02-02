-- BookEditor.lua
-- UI for adding and editing books in-game without touching files.

-- Helper: trim whitespace
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

function BookReader:CreateBookEditorFrame()
    local frame = CreateFrame("Frame", "BookReaderEditorFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(500, 450)
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
    frame.title:SetText("Add / Edit Book")
    
    -- Book Title input
    local titleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -30)
    titleLabel:SetText("Book Title:")
    
    local titleInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    titleInput:SetSize(460, 25)
    titleInput:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 5, -5)
    titleInput:SetAutoFocus(false)
    titleInput:SetMaxLetters(100)
    frame.titleInput = titleInput
    
    -- Book Content (multiline)
    local contentLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contentLabel:SetPoint("TOPLEFT", titleInput, "BOTTOMLEFT", -5, -10)
    contentLabel:SetText("Book Content:")
    
    -- Scrollable text area
    local scrollFrame = CreateFrame("ScrollFrame", "BookEditorScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentLabel, "BOTTOMLEFT", 0, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 50)
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetSize(scrollFrame:GetWidth() - 10, scrollFrame:GetHeight())
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Background for the text area
    local bg = editBox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    
    scrollFrame:SetScrollChild(editBox)
    frame.contentInput = editBox
    
    -- Save button
    local saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 25)
    saveBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
    saveBtn:SetText("Save Book")
    saveBtn:SetScript("OnClick", function()
        BookReader:SaveBook()
    end)
    
    -- Delete button (only shown when editing existing book)
    local deleteBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteBtn:SetSize(100, 25)
    deleteBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
    deleteBtn:SetText("Delete")
    deleteBtn:SetScript("OnClick", function()
        BookReader:DeleteBook()
    end)
    frame.deleteBtn = deleteBtn
    
    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelBtn:SetSize(100, 25)
    cancelBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    frame:Hide()
    return frame
end

function BookReader:ShowBookEditor(bookName)
    if not BookReaderEditorFrame then
        self:CreateBookEditorFrame()
    end
    
    local frame = BookReaderEditorFrame
    frame.editingBook = bookName
    
    if bookName then
        -- Editing existing book
        frame.title:SetText("Edit Book: " .. bookName)
        frame.titleInput:SetText(bookName)
        frame.titleInput:Disable()  -- Can't rename
        
        local book = self.books[bookName]
        if book then
            frame.contentInput:SetText(table.concat(book.lines, "\n"))
        end
        
        frame.deleteBtn:Show()
    else
        -- Adding new book
        frame.title:SetText("Add New Book")
        frame.titleInput:SetText("")
        frame.titleInput:Enable()
        frame.contentInput:SetText("")
        frame.deleteBtn:Hide()
    end
    
    frame:Show()
end

function BookReader:SaveBook()
    local frame = BookReaderEditorFrame
    local title = frame.titleInput:GetText()
    local content = frame.contentInput:GetText()
    
    if not title or trim(title) == "" then
        print("|cFF33FF99BookReader:|r Please enter a book title.")
        return
    end
    
    if not content or trim(content) == "" then
        print("|cFF33FF99BookReader:|r Please enter some content.")
        return
    end
    
    -- Save to BookReaderDB
    BookReaderDB.customBooks = BookReaderDB.customBooks or {}
    BookReaderDB.customBooks[title] = content
    
    -- Register the book in memory
    local lines = {}
    for line in content:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end
    
    local pageSize = BookReaderDB.pageSize or 25
    local totalPages = math.ceil(#lines / pageSize)
    if totalPages < 1 then totalPages = 1 end
    
    self.books[title] = {
        title = title,
        lines = lines,
        totalPages = totalPages,
        custom = true,  -- mark as user-created
    }
    
    print("|cFF33FF99BookReader:|r Book '" .. title .. "' saved!")
    frame:Hide()
    
    -- Refresh the book list sidebar
    if BookReaderFrame then
        BookReader:RefreshBookList()
    end
    
    -- Refresh reader if it's open
    if BookReaderFrame and BookReaderFrame:IsShown() then
        -- If we were editing the current book, reload it
        if self.currentBook == title then
            self:UpdateReader()
        end
    end
end

function BookReader:DeleteBook()
    local frame = BookReaderEditorFrame
    local bookName = frame.editingBook
    
    if not bookName then return end
    
    -- Show confirmation
    StaticPopupDialogs["BOOKREADER_DELETE"] = {
        text = "Delete book '" .. bookName .. "'?",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function()
            -- Remove from saved data
            if BookReaderDB.customBooks then
                BookReaderDB.customBooks[bookName] = nil
            end
            
            -- Remove from memory
            BookReader.books[bookName] = nil
            
            -- If this was the current book, clear it
            if BookReader.currentBook == bookName then
                BookReader.currentBook = nil
                BookReader.currentPage = 1
                if BookReaderFrame then
                    BookReaderFrame.title:SetText("Parchment Reader")
                    BookReader:UpdateReader()
                end
            end
            
            -- Refresh the book list sidebar
            if BookReaderFrame then
                BookReader:RefreshBookList()
            end
            
            print("|cFF33FF99BookReader:|r Book '" .. bookName .. "' deleted.")
            frame:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    
    StaticPopup_Show("BOOKREADER_DELETE")
end

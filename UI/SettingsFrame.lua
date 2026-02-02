-- SettingsFrame.lua - Settings interface

function BookReader:CreateSettingsFrame()
    local frame = CreateFrame("Frame", "BookReaderSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame.TitleBg, 0, -3)
    frame.title:SetText("BookReader Settings")
    
    local yOffset = -40
    local spacing = 40
    
    -- Page Size Slider
    local pageSizeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageSizeText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    pageSizeText:SetText("Lines per page:")
    
    local pageSizeSlider = CreateFrame("Slider", "BookReaderPageSizeSlider", frame, "OptionsSliderTemplate")
    pageSizeSlider:SetPoint("TOPLEFT", pageSizeText, "BOTTOMLEFT", 0, -10)
    pageSizeSlider:SetMinMaxValues(10, 50)
    pageSizeSlider:SetValue(self.db.profile.pageSize)
    pageSizeSlider:SetValueStep(1)
    pageSizeSlider:SetObeyStepOnDrag(true)
    pageSizeSlider:SetWidth(300)
    
    _G[pageSizeSlider:GetName().."Low"]:SetText("10")
    _G[pageSizeSlider:GetName().."High"]:SetText("50")
    _G[pageSizeSlider:GetName().."Text"]:SetText(self.db.profile.pageSize)
    
    pageSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName().."Text"]:SetText(value)
        BookReader.db.profile.pageSize = value
        
        -- Recalculate all books' page counts
        for bookName, book in pairs(BookReader.books) do
            book.totalPages = math.ceil(#book.lines / value)
        end
        
        -- Update reader if open
        if BookReaderFrame and BookReaderFrame:IsShown() then
            -- Adjust current page if needed
            if BookReader.currentBook then
                local totalPages = BookReader.books[BookReader.currentBook].totalPages
                if BookReader.currentPage > totalPages then
                    BookReader.currentPage = totalPages
                end
            end
            BookReader:UpdateReader()
        end
    end)
    
    yOffset = yOffset - spacing - 30
    
    -- Window Width Slider
    local widthText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    widthText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    widthText:SetText("Window width:")
    
    local widthSlider = CreateFrame("Slider", "BookReaderWidthSlider", frame, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", widthText, "BOTTOMLEFT", 0, -10)
    widthSlider:SetMinMaxValues(400, 1000)
    widthSlider:SetValue(self.db.profile.windowWidth)
    widthSlider:SetValueStep(50)
    widthSlider:SetObeyStepOnDrag(true)
    widthSlider:SetWidth(300)
    
    _G[widthSlider:GetName().."Low"]:SetText("400")
    _G[widthSlider:GetName().."High"]:SetText("1000")
    _G[widthSlider:GetName().."Text"]:SetText(self.db.profile.windowWidth)
    
    widthSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName().."Text"]:SetText(value)
        BookReader.db.profile.windowWidth = value
        
        if BookReaderFrame then
            BookReaderFrame:SetWidth(value)
        end
    end)
    
    yOffset = yOffset - spacing - 30
    
    -- Window Height Slider
    local heightText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heightText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    heightText:SetText("Window height:")
    
    local heightSlider = CreateFrame("Slider", "BookReaderHeightSlider", frame, "OptionsSliderTemplate")
    heightSlider:SetPoint("TOPLEFT", heightText, "BOTTOMLEFT", 0, -10)
    heightSlider:SetMinMaxValues(300, 800)
    heightSlider:SetValue(self.db.profile.windowHeight)
    heightSlider:SetValueStep(50)
    heightSlider:SetObeyStepOnDrag(true)
    heightSlider:SetWidth(300)
    
    _G[heightSlider:GetName().."Low"]:SetText("300")
    _G[heightSlider:GetName().."High"]:SetText("800")
    _G[heightSlider:GetName().."Text"]:SetText(self.db.profile.windowHeight)
    
    heightSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName().."Text"]:SetText(value)
        BookReader.db.profile.windowHeight = value
        
        if BookReaderFrame then
            BookReaderFrame:SetHeight(value)
        end
    end)
    
    yOffset = yOffset - spacing - 30
    
    -- Minimap Button Toggle
    local minimapCheck = CreateFrame("CheckButton", "BookReaderMinimapCheck", frame, "InterfaceOptionsCheckButtonTemplate")
    minimapCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    _G[minimapCheck:GetName().."Text"]:SetText("Show minimap button")
    minimapCheck:SetChecked(not BookReaderDB.hide)
    
    minimapCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        BookReaderDB.hide = not checked

        if BookReader.minimapBtn then
            if checked then
                BookReader.minimapBtn:Show()
            else
                BookReader.minimapBtn:Hide()
            end
        end
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 22)
    closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    frame:Hide()
    return frame
end

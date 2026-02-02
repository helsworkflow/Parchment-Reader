-- SettingsFrame.lua - Settings interface

function ParchmentReader:CreateSettingsFrame()
    local frame = CreateFrame("Frame", "ParchmentReaderSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(360, 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame.TitleBg, 0, -3)
    frame.title:SetText("ParchmentReader Settings")
    
    local yOffset = -40
    local spacing = 40
    
    -- Page Size Slider
    local pageSizeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageSizeText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    pageSizeText:SetText("Lines per page:")
    
    local pageSizeSlider = CreateFrame("Slider", "ParchmentReaderPageSizeSlider", frame, "OptionsSliderTemplate")
    pageSizeSlider:SetPoint("TOPLEFT", pageSizeText, "BOTTOMLEFT", 0, -10)
    pageSizeSlider:SetMinMaxValues(10, 50)
    pageSizeSlider:SetValue(ParchmentReaderDB.pageSize or 25)
    pageSizeSlider:SetValueStep(1)
    pageSizeSlider:SetObeyStepOnDrag(true)
    pageSizeSlider:SetWidth(300)

    _G[pageSizeSlider:GetName().."Low"]:SetText("10")
    _G[pageSizeSlider:GetName().."High"]:SetText("50")
    _G[pageSizeSlider:GetName().."Text"]:SetText(ParchmentReaderDB.pageSize or 25)

    pageSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName().."Text"]:SetText(value)
        ParchmentReaderDB.pageSize = value
        
        -- Recalculate all books' page counts
        for bookName, book in pairs(ParchmentReader.books) do
            book.totalPages = math.ceil(#book.lines / value)
        end
        
        -- Update reader if open
        if ParchmentReaderFrame and ParchmentReaderFrame:IsShown() then
            -- Adjust current page if needed
            if ParchmentReader.currentBook then
                local totalPages = ParchmentReader.books[ParchmentReader.currentBook].totalPages
                if ParchmentReader.currentPage > totalPages then
                    ParchmentReader.currentPage = totalPages
                end
            end
            ParchmentReader:UpdateReader()
        end
    end)
    
    yOffset = yOffset - spacing - 30
    
    -- Window Width Slider
    local widthText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    widthText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    widthText:SetText("Window width:")
    
    local widthSlider = CreateFrame("Slider", "ParchmentReaderWidthSlider", frame, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", widthText, "BOTTOMLEFT", 0, -10)
    widthSlider:SetMinMaxValues(400, 1000)
    widthSlider:SetValue(ParchmentReaderDB.windowWidth or 600)
    widthSlider:SetValueStep(50)
    widthSlider:SetObeyStepOnDrag(true)
    widthSlider:SetWidth(300)

    _G[widthSlider:GetName().."Low"]:SetText("400")
    _G[widthSlider:GetName().."High"]:SetText("1000")
    _G[widthSlider:GetName().."Text"]:SetText(ParchmentReaderDB.windowWidth or 600)

    widthSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName().."Text"]:SetText(value)
        ParchmentReaderDB.windowWidth = value
        
        if ParchmentReaderFrame then
            ParchmentReaderFrame:SetWidth(value)
        end
    end)
    
    yOffset = yOffset - spacing - 30
    
    -- Window Height Slider
    local heightText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heightText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    heightText:SetText("Window height:")
    
    local heightSlider = CreateFrame("Slider", "ParchmentReaderHeightSlider", frame, "OptionsSliderTemplate")
    heightSlider:SetPoint("TOPLEFT", heightText, "BOTTOMLEFT", 0, -10)
    heightSlider:SetMinMaxValues(300, 800)
    heightSlider:SetValue(ParchmentReaderDB.windowHeight or 450)
    heightSlider:SetValueStep(50)
    heightSlider:SetObeyStepOnDrag(true)
    heightSlider:SetWidth(300)

    _G[heightSlider:GetName().."Low"]:SetText("300")
    _G[heightSlider:GetName().."High"]:SetText("800")
    _G[heightSlider:GetName().."Text"]:SetText(ParchmentReaderDB.windowHeight or 450)

    heightSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName().."Text"]:SetText(value)
        ParchmentReaderDB.windowHeight = value
        
        if ParchmentReaderFrame then
            ParchmentReaderFrame:SetHeight(value)
        end
    end)
    
    yOffset = yOffset - spacing - 30

    -- Font Selection Dropdown
    local fontText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    fontText:SetText("Font:")

    local fontDropdown = CreateFrame("Frame", "ParchmentReaderFontDropdown", frame, "UIDropDownMenuTemplate")
    fontDropdown:SetPoint("TOPLEFT", fontText, "BOTTOMLEFT", -15, -5)

    UIDropDownMenu_Initialize(fontDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()

        local fonts = {
            {name = "QuestFont", display = "Quest Font"},
            {name = "GameFontNormal", display = "Game Font"},
            {name = "ChatFontNormal", display = "Chat Font"},
            {name = "SystemFont_Med1", display = "System Font"},
            {name = "FRIZQT__.TTF", display = "Friz Quadrata"},
            {name = "MORPHEUS.TTF", display = "Morpheus"},
        }

        for _, font in ipairs(fonts) do
            info.text = font.display
            info.value = font.name
            info.func = function()
                ParchmentReaderDB.fontName = font.name
                UIDropDownMenu_SetSelectedValue(fontDropdown, font.name)
                ParchmentReader:UpdateFont()
            end
            info.checked = (ParchmentReaderDB.fontName == font.name)
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetWidth(fontDropdown, 150)
    UIDropDownMenu_SetSelectedValue(fontDropdown, ParchmentReaderDB.fontName or "QuestFont")

    yOffset = yOffset - 60

    -- Font Size Slider
    local fontSizeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontSizeText:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    fontSizeText:SetText("Font size:")

    local fontSizeSlider = CreateFrame("Slider", "ParchmentReaderFontSizeSlider", frame, "OptionsSliderTemplate")
    fontSizeSlider:SetPoint("TOPLEFT", fontSizeText, "BOTTOMLEFT", 0, -10)
    fontSizeSlider:SetMinMaxValues(8, 24)
    fontSizeSlider:SetValue(ParchmentReaderDB.fontSize or 14)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)
    fontSizeSlider:SetWidth(300)

    _G[fontSizeSlider:GetName().."Low"]:SetText("8")
    _G[fontSizeSlider:GetName().."High"]:SetText("24")
    _G[fontSizeSlider:GetName().."Text"]:SetText(ParchmentReaderDB.fontSize or 14)

    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        _G[self:GetName().."Text"]:SetText(value)
        ParchmentReaderDB.fontSize = value
        ParchmentReader:UpdateFont()
    end)

    yOffset = yOffset - spacing - 30

    -- Minimap Button Toggle
    local minimapCheck = CreateFrame("CheckButton", "ParchmentReaderMinimapCheck", frame, "InterfaceOptionsCheckButtonTemplate")
    minimapCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    _G[minimapCheck:GetName().."Text"]:SetText("Show minimap button")
    minimapCheck:SetChecked(not ParchmentReaderDB.hide)
    
    minimapCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        ParchmentReaderDB.hide = not checked

        if ParchmentReader.minimapBtn then
            if checked then
                ParchmentReader.minimapBtn:Show()
            else
                ParchmentReader.minimapBtn:Hide()
            end
        end
    end)
    
    -- Reset to Default button
    local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 22)
    resetButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 10)
    resetButton:SetText("Reset to Default")
    resetButton:SetScript("OnClick", function()
        -- Show confirmation dialog
        StaticPopupDialogs["PARCHMENTREADER_RESET"] = {
            text = "Reset all settings to defaults?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                -- Reset all settings to defaults
                ParchmentReaderDB.pageSize = 25
                ParchmentReaderDB.windowWidth = 600
                ParchmentReaderDB.windowHeight = 450
                ParchmentReaderDB.fontSize = 14
                ParchmentReaderDB.fontName = "QuestFont"
                ParchmentReaderDB.hide = false

                -- Update UI
                pageSizeSlider:SetValue(25)
                widthSlider:SetValue(600)
                heightSlider:SetValue(450)
                fontSizeSlider:SetValue(14)
                UIDropDownMenu_SetSelectedValue(fontDropdown, "QuestFont")
                minimapCheck:SetChecked(true)

                -- Apply changes
                if ParchmentReaderFrame then
                    ParchmentReaderFrame:SetWidth(600)
                    ParchmentReaderFrame:SetHeight(450)
                end

                if ParchmentReader.minimapBtn then
                    ParchmentReader.minimapBtn:Show()
                end

                ParchmentReader:UpdateFont()

                -- Recalculate all books' page counts
                for bookName, book in pairs(ParchmentReader.books) do
                    book.totalPages = math.ceil(#book.lines / 25)
                end

                if ParchmentReaderFrame and ParchmentReaderFrame:IsShown() then
                    if ParchmentReader.currentBook then
                        local totalPages = ParchmentReader.books[ParchmentReader.currentBook].totalPages
                        if ParchmentReader.currentPage > totalPages then
                            ParchmentReader.currentPage = totalPages
                        end
                    end
                    ParchmentReader:UpdateReader()
                end

                print("|cFF33FF99ParchmentReader:|r Settings reset to defaults.")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }

        StaticPopup_Show("PARCHMENTREADER_RESET")
    end)

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 22)
    closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    frame:Hide()
    return frame
end

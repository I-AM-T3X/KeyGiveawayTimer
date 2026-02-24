local addonName, addon = ...

addon.configCreated = false
addon.settingsCategory = nil

function addon:CreateConfig()
    if self.configCreated then return end
    self.configCreated = true
    
    -- Create main container frame
    local container = CreateFrame("Frame", "KeyGiveawayTimerContainer")
    container:SetSize(600, 500)
    container.name = "Key Giveaway Timer"
    
    -- Create scrollframe inside container
    local scrollFrame = CreateFrame("ScrollFrame", "KeyGiveawayTimerScrollFrame", container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)
    
    -- Create the content frame
    local settingsPanel = CreateFrame("FRAME", "KeyGiveawayTimerSettingsPanel")
    settingsPanel:SetSize(560, 800)
    settingsPanel.name = "Key Giveaway Timer"
    
    scrollFrame:SetScrollChild(settingsPanel)
    
    -- Title
    local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cffffd100Key Giveaway Timer Settings|r")
    title:SetFontObject("GameFontNormalHuge")
    
    -- Subtitle
    local subtitle = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -6)
    subtitle:SetText("Configure timer display, fonts, and branding")
    subtitle:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- Helper function for sections
    local function CreateSection(parent, headerText, descText, yPos, height)
        local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        box:SetPoint("TOPLEFT", 12, yPos)
        box:SetPoint("TOPRIGHT", -12, yPos)
        box:SetHeight(height)
        box:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        box:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        box:SetBackdropColor(0, 0, 0, 0.8)
        
        local header = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", 12, -10)
        header:SetText("|cffffd100" .. headerText .. "|r")
        header:SetFontObject("GameFontNormalLarge")
        
        if descText then
            local desc = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
            desc:SetText(descText)
            desc:SetTextColor(0.6, 0.6, 0.6, 1)
        end
        
        return box
    end
    
    -- Helper for edit boxes - all save immediately to KeyGiveawayTimerDB (SavedVariables)
    local function CreateEditBox(parent, label, yPos, width, xOffset, defaultText, onTextChanged)
        xOffset = xOffset or 12
        
        local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        box:SetSize(width or 420, 22)
        box:SetPoint("TOPLEFT", xOffset, yPos)
        box:SetAutoFocus(false)
        
        local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("BOTTOMLEFT", box, "TOPLEFT", 0, 8)
        text:SetText(label)
        text:SetTextColor(0.8, 0.8, 0.8, 1)
        
        -- Set initial text
        box:SetText(defaultText or "")
        
        -- FIX: Force text refresh when shown to prevent "invisible until clicked" bug
        box:SetScript("OnShow", function(self)
            local current = self:GetText()
            self:SetText("")
            self:SetText(current)
        end)
        
        -- Save on any change (typing)
        if onTextChanged then
            box:SetScript("OnTextChanged", function(self)
                onTextChanged(self)
            end)
        end
        
        -- Also save when pressing enter
        box:SetScript("OnEnterPressed", function(self)
            if onTextChanged then
                onTextChanged(self)
            end
            self:ClearFocus()
        end)
        
        -- Also save when losing focus (clicking away)
        box:SetScript("OnEditFocusLost", function(self)
            if onTextChanged then
                onTextChanged(self)
            end
        end)
        
        return box, yPos - 52
    end
    
    -- Helper for color picker - FIXED: Properly renders colors
    local function CreateColorPicker(parent, label, colorTable, x, y)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(24, 24)
        btn:SetPoint("TOPLEFT", x, y)
        
        -- FIX: Use ARTWORK layer instead of BACKGROUND to ensure visibility
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        -- FIX: Ensure values are numbers and defaults are set
        local r = tonumber(colorTable.r) or 1
        local g = tonumber(colorTable.g) or 1
        local b = tonumber(colorTable.b) or 1
        local a = tonumber(colorTable.a) or 1
        tex:SetColorTexture(r, g, b, a)
        
        local border = btn:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0.3, 0.3, 0.3, 1)
        
        local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "RIGHT", 12, 0)
        text:SetText(label)
        
        local originalR, originalG, originalB, originalA = r, g, b, a
        
        btn:SetScript("OnClick", function()
            local info = {
                r = colorTable.r or 1,
                g = colorTable.g or 1,
                b = colorTable.b or 1,
                opacity = colorTable.a or 1,
                hasOpacity = true,
                swatchFunc = function()
                    local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                    local newA = ColorPickerFrame:GetColorAlpha()
                    tex:SetColorTexture(newR, newG, newB, newA)
                    colorTable.r, colorTable.g, colorTable.b, colorTable.a = newR, newG, newB, newA
                    if KeyGiveawayTimerFrame then
                        KeyGiveawayTimerFrame:UpdateAppearance()
                    end
                end,
                cancelFunc = function()
                    tex:SetColorTexture(originalR, originalG, originalB, originalA)
                    colorTable.r, colorTable.g, colorTable.b, colorTable.a = originalR, originalG, originalB, originalA
                    if KeyGiveawayTimerFrame then
                        KeyGiveawayTimerFrame:UpdateAppearance()
                    end
                end,
            }
            ColorPickerFrame:SetupColorPickerAndShow(info)
        end)
        
        return btn
    end
    
    -- Ensure DB exists and color tables are properly initialized
    if not KeyGiveawayTimerDB then
        KeyGiveawayTimerDB = {}
    end
    
    -- FIX: Force reset color tables if they're invalid (grey bug fix)
    local function ValidateColor(colorTable, defaultR, defaultG, defaultB)
        if type(colorTable) ~= "table" then 
            return {r=defaultR, g=defaultG, b=defaultB, a=1} 
        end
        -- Check if any value is missing or not a number
        if type(colorTable.r) ~= "number" or type(colorTable.g) ~= "number" or type(colorTable.b) ~= "number" then
            return {r=defaultR, g=defaultG, b=defaultB, a=1}
        end
        return colorTable
    end
    
    KeyGiveawayTimerDB.textColor = ValidateColor(KeyGiveawayTimerDB.textColor, 1, 1, 1)
    KeyGiveawayTimerDB.barColor = ValidateColor(KeyGiveawayTimerDB.barColor, 1, 0.8, 0)
    
    -- Section 1: Text & Branding
    local textBox = CreateSection(settingsPanel, "Text & Branding", "Customize the title and subtitle text displayed on the timer", -75, 160)
    
    local yPos = -65
    
    -- Title Text - saves immediately to SavedVariables
    local titleEdit
    titleEdit, yPos = CreateEditBox(textBox, "Title Text", yPos, 420, 12, 
        KeyGiveawayTimerDB.titleText or "GIVEAWAY TIME!",
        function(self) 
            KeyGiveawayTimerDB.titleText = self:GetText()
            if KeyGiveawayTimerFrame then
                KeyGiveawayTimerFrame:UpdateAppearance()
            end
        end
    )
    
    -- Subtitle Text - saves immediately to SavedVariables
    local subEdit
    subEdit, _ = CreateEditBox(textBox, "Subtitle Text", yPos, 420, 12,
        KeyGiveawayTimerDB.subText or "Keys remaining: 5",
        function(self)
            KeyGiveawayTimerDB.subText = self:GetText()
            if KeyGiveawayTimerFrame then
                KeyGiveawayTimerFrame:UpdateAppearance()
            end
        end
    )
    
    -- Section 2: Timer Display (height reduced from 230 to 195)
    local timerBox = CreateSection(settingsPanel, "Timer Display", "Configure how the timer appears and behaves", -255, 195)
    
    yPos = -45
    local col2X = 260
    
    -- Display Mode Dropdown
    local modeLabel = timerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", 12, yPos)
    modeLabel:SetText("Display Mode")
    modeLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local modeDropdown = CreateFrame("Frame", nil, timerBox, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("TOPLEFT", 12, yPos - 22)
    UIDropDownMenu_SetWidth(modeDropdown, 140)
    
    local modes = {
        {text = "Digital Only", value = "digital"},
        {text = "Bar Only", value = "bar"},
        {text = "Both", value = "both"}
    }
    
    local currentMode = KeyGiveawayTimerDB.timerMode or "both"
    UIDropDownMenu_SetText(modeDropdown, currentMode:gsub("^%l", string.upper))
    
    UIDropDownMenu_Initialize(modeDropdown, function()
        for _, mode in ipairs(modes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = mode.text
            info.func = function()
                KeyGiveawayTimerDB.timerMode = mode.value
                UIDropDownMenu_SetText(modeDropdown, mode.text)
                if KeyGiveawayTimerFrame then
                    KeyGiveawayTimerFrame:UpdateAppearance()
                end
            end
            info.checked = (KeyGiveawayTimerDB.timerMode or "both") == mode.value
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Duration
    local durLabel = timerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    durLabel:SetPoint("TOPLEFT", col2X, yPos)
    durLabel:SetText("Duration (seconds)")
    durLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local durEdit = CreateFrame("EditBox", nil, timerBox, "InputBoxTemplate")
    durEdit:SetSize(100, 22)
    durEdit:SetPoint("TOPLEFT", col2X, yPos - 22)
    durEdit:SetAutoFocus(false)
    durEdit:SetText(tostring(KeyGiveawayTimerDB.timerDuration or 300))
    
    -- FIX: Force text refresh when shown to prevent "invisible until clicked" bug
    durEdit:SetScript("OnShow", function(self)
        local current = self:GetText()
        self:SetText("")
        self:SetText(current)
    end)
    
    local function SaveDuration(self)
        local num = tonumber(self:GetText())
        if num then
            KeyGiveawayTimerDB.timerDuration = num
            if KeyGiveawayTimerFrame then
                KeyGiveawayTimerFrame:UpdateAppearance()
            end
        end
    end
    
    durEdit:SetScript("OnTextChanged", SaveDuration)
    durEdit:SetScript("OnEnterPressed", function(self)
        SaveDuration(self)
        self:ClearFocus()
    end)
    durEdit:SetScript("OnEditFocusLost", SaveDuration)
    
    -- Font Sliders
    yPos = -110
    
    -- Title Font Size
    local fontLabel = timerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", 12, yPos)
    fontLabel:SetText("Title Font Size")
    fontLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local fontValue = timerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontValue:SetPoint("LEFT", fontLabel, "RIGHT", 8, 0)
    fontValue:SetText(KeyGiveawayTimerDB.fontSize or 24)
    fontValue:SetTextColor(1, 0.82, 0, 1)
    
    local fontSlider = CreateFrame("Slider", "KGT_FontSizeSlider", timerBox, "OptionsSliderTemplate")
    fontSlider:SetPoint("TOPLEFT", 12, yPos - 24)
    fontSlider:SetWidth(160)
    fontSlider:SetHeight(16)
    fontSlider:SetMinMaxValues(8, 72)
    fontSlider:SetValueStep(1)
    fontSlider:SetObeyStepOnDrag(true)
    fontSlider:SetValue(KeyGiveawayTimerDB.fontSize or 24)
    
    fontSlider.Low:SetText("8")
    fontSlider.High:SetText("72")
    fontSlider.Text:SetText("")
    
    fontSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        KeyGiveawayTimerDB.fontSize = value
        fontValue:SetText(value)
        if KeyGiveawayTimerFrame then
            KeyGiveawayTimerFrame:UpdateAppearance()
        end
    end)
    
    -- Timer Font Size
    local timerFontLabel = timerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerFontLabel:SetPoint("TOPLEFT", col2X, yPos)
    timerFontLabel:SetText("Timer Font Size")
    timerFontLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local timerFontValue = timerBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerFontValue:SetPoint("LEFT", timerFontLabel, "RIGHT", 8, 0)
    timerFontValue:SetText(KeyGiveawayTimerDB.timerFontSize or 48)
    timerFontValue:SetTextColor(1, 0.82, 0, 1)
    
    local timerFontSlider = CreateFrame("Slider", "KGT_TimerFontSizeSlider", timerBox, "OptionsSliderTemplate")
    timerFontSlider:SetPoint("TOPLEFT", col2X, yPos - 24)
    timerFontSlider:SetWidth(140)
    timerFontSlider:SetHeight(16)
    timerFontSlider:SetMinMaxValues(8, 96)
    timerFontSlider:SetValueStep(1)
    timerFontSlider:SetObeyStepOnDrag(true)
    timerFontSlider:SetValue(KeyGiveawayTimerDB.timerFontSize or 48)
    
    timerFontSlider.Low:SetText("8")
    timerFontSlider.High:SetText("96")
    timerFontSlider.Text:SetText("")
    
    timerFontSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        KeyGiveawayTimerDB.timerFontSize = value
        timerFontValue:SetText(value)
        if KeyGiveawayTimerFrame then
            KeyGiveawayTimerFrame:UpdateAppearance()
        end
    end)
    
    -- Section 3: Appearance (moved up from -505 to -470)
    local appearBox = CreateSection(settingsPanel, "Appearance", "Colors and background options", -470, 190)
    
    yPos = -50
    
    -- Color pickers - now using validated color tables
    CreateColorPicker(appearBox, "Text Color", KeyGiveawayTimerDB.textColor, 12, yPos)
    CreateColorPicker(appearBox, "Bar Color", KeyGiveawayTimerDB.barColor, 200, yPos)
    
    -- Background Texture
    local bgLabel = appearBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bgLabel:SetPoint("TOPLEFT", 12, yPos - 45)
    bgLabel:SetText("Background Texture")
    bgLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local bgDesc = appearBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bgDesc:SetPoint("TOPLEFT", bgLabel, "BOTTOMLEFT", 0, -2)
    bgDesc:SetText("(filename in Textures folder, leave blank for none)")
    bgDesc:SetTextColor(0.6, 0.6, 0.6, 1)
    
    local bgEdit = CreateFrame("EditBox", nil, appearBox, "InputBoxTemplate")
    bgEdit:SetSize(150, 22)
    bgEdit:SetPoint("TOPLEFT", 12, yPos - 75)
    bgEdit:SetAutoFocus(false)
    bgEdit:SetText(KeyGiveawayTimerDB.bgTexture or "")
    
    -- FIX: Force text refresh when shown to prevent "invisible until clicked" bug
    bgEdit:SetScript("OnShow", function(self)
        local current = self:GetText()
        self:SetText("")
        self:SetText(current)
    end)
    
    local function SaveBg(self)
        local text = self:GetText()
        KeyGiveawayTimerDB.bgTexture = text ~= "" and text or nil
        if KeyGiveawayTimerFrame then
            KeyGiveawayTimerFrame:UpdateAppearance()
        end
    end
    
    bgEdit:SetScript("OnTextChanged", SaveBg)
    bgEdit:SetScript("OnEnterPressed", function(self)
        SaveBg(self)
        self:ClearFocus()
    end)
    bgEdit:SetScript("OnEditFocusLost", SaveBg)
    
    -- Custom Font
    local fontFileLabel = appearBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontFileLabel:SetPoint("TOPLEFT", 280, yPos - 45)
    fontFileLabel:SetText("Custom Font")
    fontFileLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local fontFileDesc = appearBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontFileDesc:SetPoint("TOPLEFT", fontFileLabel, "BOTTOMLEFT", 0, -2)
    fontFileDesc:SetText("(filename in Fonts folder, leave blank for default)")
    fontFileDesc:SetTextColor(0.6, 0.6, 0.6, 1)
    
    local fontFileEdit = CreateFrame("EditBox", nil, appearBox, "InputBoxTemplate")
    fontFileEdit:SetSize(150, 22)
    fontFileEdit:SetPoint("TOPLEFT", 280, yPos - 75)
    fontFileEdit:SetAutoFocus(false)
    fontFileEdit:SetText(KeyGiveawayTimerDB.fontFile == "Fonts\\FRIZQT__.TTF" and "" or (KeyGiveawayTimerDB.fontFile or ""))
    
    -- FIX: Force text refresh when shown to prevent "invisible until clicked" bug
    fontFileEdit:SetScript("OnShow", function(self)
        local current = self:GetText()
        self:SetText("")
        self:SetText(current)
    end)
    
    local function SaveFont(self)
        local text = self:GetText()
        if text == "" then
            KeyGiveawayTimerDB.fontFile = "Fonts\\FRIZQT__.TTF"
        else
            if not text:find("\\") and not text:find("/") then
                text = "Interface\\AddOns\\KeyGiveawayTimer\\Fonts\\"..text
            end
            KeyGiveawayTimerDB.fontFile = text
        end
        if KeyGiveawayTimerFrame then
            KeyGiveawayTimerFrame:UpdateAppearance()
        end
    end
    
    fontFileEdit:SetScript("OnTextChanged", SaveFont)
    fontFileEdit:SetScript("OnEnterPressed", function(self)
        SaveFont(self)
        self:ClearFocus()
    end)
    fontFileEdit:SetScript("OnEditFocusLost", SaveFont)
    
    -- Section 4: Quick Controls (moved up from -715 to -680)
    local ctrlBox = CreateSection(settingsPanel, "Quick Controls", "Start, stop, or show the timer frame", -680, 105)
    
    local startBtn = CreateFrame("Button", nil, ctrlBox, "UIPanelButtonTemplate")
    startBtn:SetPoint("TOPLEFT", 12, -42)
    startBtn:SetSize(100, 24)
    startBtn:SetText("Start Timer")
    startBtn:SetScript("OnClick", function()
        if KeyGiveawayTimerFrame then
            KeyGiveawayTimerFrame:StartTimer()
        end
    end)
    
    local stopBtn = CreateFrame("Button", nil, ctrlBox, "UIPanelButtonTemplate")
    stopBtn:SetPoint("LEFT", startBtn, "RIGHT", 12, 0)
    stopBtn:SetSize(100, 24)
    stopBtn:SetText("Stop")
    stopBtn:SetScript("OnClick", function()
        if KeyGiveawayTimerFrame then
            KeyGiveawayTimerFrame:StopTimer()
        end
    end)
    
    local showBtn = CreateFrame("Button", nil, ctrlBox, "UIPanelButtonTemplate")
    showBtn:SetPoint("LEFT", stopBtn, "RIGHT", 12, 0)
    showBtn:SetSize(100, 24)
    showBtn:SetText("Show/Hide")
    showBtn:SetScript("OnClick", function()
        if KeyGiveawayTimerFrame then
            if KeyGiveawayTimerFrame:IsShown() then
                KeyGiveawayTimerFrame:Hide()
            else
                KeyGiveawayTimerFrame:Show()
            end
        end
    end)
    
    -- Register the container
    local category = Settings.RegisterCanvasLayoutCategory(container, "Key Giveaway Timer")
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory = category
end
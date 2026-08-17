local addonName, addon = ...
local KGT = CreateFrame("Frame", "KeyGiveawayTimerFrame", UIParent, "BackdropTemplate")

-- Default Settings
local defaults = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    width = 300,
    height = 160,
    titleText = "KEY GIVEAWAY",
    subText = "Type !giveaway to enter",
    fontFile = "Fonts\\FRIZQT__.TTF",
    fontSize = 18,
    timerFontSize = 36,
    timerMode = "both",
    barColor = {r=0.8, g=0.6, b=0, a=1},
    textColor = {r=1, g=1, b=1, a=1},
    bgColor = {r=0.08, g=0.08, b=0.08, a=0.95},
    timerDuration = 300,
    isRunning = false,
    timeRemaining = 0,
    minimap = {hide = false}
}

function KGT:Init()
    if not KeyGiveawayTimerDB then
        KeyGiveawayTimerDB = CopyTable(defaults)
    else
        for k, v in pairs(defaults) do
            if KeyGiveawayTimerDB[k] == nil then
                KeyGiveawayTimerDB[k] = v
            end
        end
    end
    self.db = KeyGiveawayTimerDB
    
    self:CreateUI()
    self:CreateMinimapButton()
    
    if addon.CreateConfig then
        addon:CreateConfig()
    end
    
    SLASH_KEYGIVEAWAYTIMER1 = "/kgt"
    SlashCmdList["KEYGIVEAWAYTIMER"] = function(msg) self:HandleSlash(msg) end
    
    self:Hide()
end

function KGT:CreateUI()
    self:SetFrameStrata("MEDIUM")
    self:SetPoint(self.db.point, UIParent, self.db.relativePoint, self.db.x, self.db.y)
    self:SetMovable(true)
    self:EnableMouse(true)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", self.StartMoving)
    self:SetScript("OnDragStop", function()
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        self.db.point = point
        self.db.relativePoint = relativePoint
        self.db.x = x
        self.db.y = y
    end)
    
    -- Dark modern backdrop
    self:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    self:SetBackdropColor(self.db.bgColor.r, self.db.bgColor.g, self.db.bgColor.b, self.db.bgColor.a)
    self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    
    -- Accent border frame (inner glow)
    self.border = CreateFrame("Frame", nil, self, "BackdropTemplate")
    self.border:SetPoint("TOPLEFT", 1, -1)
    self.border:SetPoint("BOTTOMRIGHT", -1, 1)
    self.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    self.border:SetBackdropBorderColor(0.6, 0.5, 0.1, 0.3)
    self.border:SetFrameLevel(self:GetFrameLevel() + 1)
    
    -- Header background
    self.headerBg = self:CreateTexture(nil, "BACKGROUND")
    self.headerBg:SetPoint("TOPLEFT", 2, -2)
    self.headerBg:SetPoint("TOPRIGHT", -2, -2)
    self.headerBg:SetHeight(36)
    self.headerBg:SetColorTexture(0.12, 0.12, 0.12, 1)
    
    -- Title (centered in header)
    self.title = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.title:SetPoint("CENTER", self.headerBg, "CENTER", 0, 0)
    self.title:SetFont(self.db.fontFile, self.db.fontSize, "OUTLINE")
    
    -- Close button (X) - BIGGER: increased from 16x16 to 24x24
    self.closeBtn = CreateFrame("Button", nil, self)
    self.closeBtn:SetPoint("TOPRIGHT", -4, -4)
    self.closeBtn:SetSize(24, 24)  -- Changed from 16,16
    self.closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    self.closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    self.closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    self.closeBtn:SetScript("OnClick", function() self:Hide() end)
    
    -- Subtitle (anchored below header)
    self.subtitle = self:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.subtitle:SetPoint("TOP", self.headerBg, "BOTTOM", 0, -8)
    self.subtitle:SetTextColor(0.7, 0.7, 0.7, 1)
    self.subtitle:SetFont(self.db.fontFile, 11, "")
    
    -- Timer container
    self.timerContainer = CreateFrame("Frame", nil, self)
    self.timerContainer:SetPoint("TOP", self.subtitle, "BOTTOM", 0, -8)
    self.timerContainer:SetSize(200, 40)
    
    -- Timer label
    self.timerLabel = self.timerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.timerLabel:SetPoint("TOP", 0, 0)
    self.timerLabel:SetText("TIME REMAINING")
    self.timerLabel:SetTextColor(0.5, 0.5, 0.5, 1)
    self.timerLabel:SetFont(self.db.fontFile, 9, "OUTLINE")
    
    -- Digital Timer (big)
    self.digitalTimer = self.timerContainer:CreateFontString(nil, "OVERLAY")
    self.digitalTimer:SetPoint("TOP", self.timerLabel, "BOTTOM", 0, -2)
    self.digitalTimer:SetFont("Fonts\\FRIZQT__.TTF", self.db.timerFontSize, "OUTLINE")
    self.digitalTimer:SetTextColor(1, 0.8, 0, 1)
    
    -- Progress Bar (below timer)
    self.barContainer = CreateFrame("Frame", nil, self)
    self.barContainer:SetPoint("TOP", self.timerContainer, "BOTTOM", 0, -8)
    self.barContainer:SetSize(240, 12)
    
    -- Bar background
    self.barBg = self.barContainer:CreateTexture(nil, "BACKGROUND")
    self.barBg:SetAllPoints()
    self.barBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    -- Status Bar
    self.bar = CreateFrame("StatusBar", nil, self.barContainer)
    self.bar:SetAllPoints()
    self.bar:SetMinMaxValues(0, 1)
    self.bar:SetValue(1)
    self.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    self.bar:SetStatusBarColor(0.8, 0.6, 0, 1)
    
    -- Button container at bottom (will be repositioned dynamically)
    self.buttonContainer = CreateFrame("Frame", nil, self)
    self.buttonContainer:SetSize(240, 26)
    
    -- Start Button
    self.startBtn = CreateFrame("Button", nil, self.buttonContainer, "UIPanelButtonTemplate")
    self.startBtn:SetPoint("LEFT", 0, 0)
    self.startBtn:SetSize(115, 24)
    self.startBtn:SetText("START")
    self.startBtn:SetScript("OnClick", function()
        if self.db.isRunning then
            self:ResetTimer()
        else
            self:StartTimer()
        end
    end)
    
    -- Stop Button
    self.stopBtn = CreateFrame("Button", nil, self.buttonContainer, "UIPanelButtonTemplate")
    self.stopBtn:SetPoint("RIGHT", 0, 0)
    self.stopBtn:SetSize(115, 24)
    self.stopBtn:SetText("STOP")
    self.stopBtn:SetScript("OnClick", function()
        self:StopTimer()
    end)
    
    -- Initial layout
    self:UpdateAppearance()
end

function KGT:UpdateAppearance()
    -- Apply font settings first so we can measure them
    self.title:SetFont(self.db.fontFile, self.db.fontSize, "OUTLINE")
    self.subtitle:SetFont(self.db.fontFile, math.max(10, self.db.fontSize * 0.6), "")
    self.timerLabel:SetFont(self.db.fontFile, math.max(8, self.db.fontSize * 0.5), "OUTLINE")
    self.digitalTimer:SetFont(self.db.fontFile, self.db.timerFontSize, "OUTLINE")
    
    -- Set text content (apply defaults if empty)
    local titleText = self.db.titleText
    if not titleText or titleText == "" then
        titleText = "KEY GIVEAWAY"
    end
    
    local subText = self.db.subText
    if not subText or subText == "" then
        subText = "Type !giveaway to enter"
    end
    
    self.title:SetText(titleText)
    self.subtitle:SetText(subText)
	
    -- Calculate required widths
    local padding = 20
    local minWidth = 280
    local maxWidth = 600
    
    -- Measure text widths
    local titleWidth = self.title:GetStringWidth() + 40 -- extra for close button
    local subtitleWidth = self.subtitle:GetStringWidth()
    local timerWidth = self.digitalTimer:GetStringWidth() + 40
    local buttonsWidth = 240 -- minimum for buttons
    
    -- Determine frame width based on widest element
    local contentWidth = math.max(titleWidth, subtitleWidth, timerWidth, buttonsWidth)
    local frameWidth = math.max(minWidth, math.min(maxWidth, contentWidth + (padding * 2)))
    
    -- Update frame width
    self:SetWidth(frameWidth)
    
    -- Update header width
    self.headerBg:SetWidth(frameWidth - 4)
    
    -- Update bar width
    self.barContainer:SetWidth(frameWidth - 40)
    
    -- Now calculate height based on what's visible
    local currentY = -2 -- Start from top
    local spacing = 8
    
    -- Header height (fixed)
    currentY = currentY - 36
    
    -- Space between header and subtitle
    currentY = currentY - spacing
    
    -- Subtitle height
    local subtitleHeight = self.subtitle:GetStringHeight()
    self.subtitle:ClearAllPoints()
    self.subtitle:SetPoint("TOP", self.headerBg, "BOTTOM", 0, -spacing)
    currentY = currentY - subtitleHeight
    
    -- Timer container (conditional)
    local showTimer = self.db.timerMode == "digital" or self.db.timerMode == "both"
    local showBar = self.db.timerMode == "bar" or self.db.timerMode == "both"
    
    if showTimer then
        self.timerContainer:Show()
        -- Space before timer
        currentY = currentY - spacing
        -- Timer label height + timer height
        local timerHeight = self.timerLabel:GetStringHeight() + self.digitalTimer:GetStringHeight() + 4
        self.timerContainer:SetHeight(timerHeight)
        self.timerContainer:ClearAllPoints()
        self.timerContainer:SetPoint("TOP", self.subtitle, "BOTTOM", 0, -spacing)
        currentY = currentY - timerHeight
    else
        self.timerContainer:Hide()
    end
    
    if showBar then
        self.barContainer:Show()
        -- Space before bar
        if showTimer then
            currentY = currentY - 4 -- smaller gap if both shown
        else
            currentY = currentY - spacing
        end
        -- Bar height
        local barHeight = math.max(8, self.db.timerFontSize * 0.15) -- Scale bar with font
        self.barContainer:SetHeight(barHeight)
        self.barContainer:ClearAllPoints()
        if showTimer then
            self.barContainer:SetPoint("TOP", self.timerContainer, "BOTTOM", 0, -8)
        else
            self.barContainer:SetPoint("TOP", self.subtitle, "BOTTOM", 0, -spacing)
        end
        currentY = currentY - barHeight
    else
        self.barContainer:Hide()
    end
    
    -- Space before buttons
    currentY = currentY - spacing - 4
    
    -- Button container
    self.buttonContainer:ClearAllPoints()
    self.buttonContainer:SetPoint("TOP", 0, currentY)
    currentY = currentY - 26 -- button height
    
    -- Bottom padding
    currentY = currentY - spacing
    
    -- Calculate total height (absolute value of currentY since it's negative)
    local totalHeight = math.abs(currentY)
    local minHeight = 100
    self:SetHeight(math.max(minHeight, totalHeight))
    
    self:UpdateTimerDisplay()
end

function KGT:UpdateTimerDisplay()
    local minutes = math.floor(self.db.timeRemaining / 60)
    local seconds = math.floor(self.db.timeRemaining % 60)
    local timeStr = string.format("%02d:%02d", minutes, seconds)
    
    if not self.db.isRunning then
        local durMin = math.floor(self.db.timerDuration / 60)
        local durSec = self.db.timerDuration % 60
        self.digitalTimer:SetText(string.format("%02d:%02d", durMin, durSec))
        self.bar:SetValue(1)
        self.startBtn:SetText("START")
        self.startBtn:SetEnabled(true)
        self.border:SetBackdropBorderColor(0.6, 0.5, 0.1, 0.3)
    else
        self.digitalTimer:SetText(timeStr)
        local progress = self.db.timeRemaining / self.db.timerDuration
        self.bar:SetValue(progress)
        self.startBtn:SetText("RESET")
        
        if self.db.timeRemaining <= 10 then
            self.digitalTimer:SetTextColor(1, 0.2, 0.2, 1)
            self.bar:SetStatusBarColor(1, 0.2, 0.2, 1)
            self.border:SetBackdropBorderColor(1, 0.2, 0.2, 0.6)
        elseif self.db.timeRemaining <= 30 then
            self.digitalTimer:SetTextColor(1, 0.6, 0, 1)
            self.bar:SetStatusBarColor(1, 0.6, 0, 1)
            self.border:SetBackdropBorderColor(1, 0.6, 0, 0.4)
        else
            self.digitalTimer:SetTextColor(1, 0.8, 0, 1)
            self.bar:SetStatusBarColor(self.db.barColor.r, self.db.barColor.g, self.db.barColor.b, 1)
            self.border:SetBackdropBorderColor(0.6, 0.5, 0.1, 0.6)
        end
    end
end

function KGT:CreateMinimapButton()
    local LibDataBroker = LibStub and LibStub("LibDataBroker-1.1", true)
    local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    
    if not LibDataBroker or not LibDBIcon then
        self:CreateFallbackMinimapButton()
        return
    end
    
    local launcher = LibDataBroker:NewDataObject("KeyGiveawayTimer", {
        type = "launcher",
        text = "Key Giveaway Timer",
        icon = "Interface\\Icons\\INV_Relics_Hourglass",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if KGT:IsShown() then
                    KGT:Hide()
                else
                    KGT:Show()
                end
            elseif button == "RightButton" then
                Settings.OpenToCategory(addon.settingsCategory and addon.settingsCategory.ID or "Key Giveaway Timer")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Key Giveaway Timer")
            tooltip:AddLine("Left-click: Show/Hide", 0.8, 0.8, 0.8)
            tooltip:AddLine("Right-click: Settings", 0.8, 0.8, 0.8)
            if KGT.db.isRunning then
                local min = math.floor(KGT.db.timeRemaining / 60)
                local sec = math.floor(KGT.db.timeRemaining % 60)
                tooltip:AddLine(string.format("Time: %02d:%02d", min, sec), 1, 0.8, 0)
            end
        end,
    })
    
    LibDBIcon:Register("KeyGiveawayTimer", launcher, self.db.minimap)
end

function KGT:CreateFallbackMinimapButton()
    local btn = CreateFrame("Button", "KeyGiveawayTimerMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    
    local angle = 225
    local x = 80 * math.cos(math.rad(angle))
    local y = 80 * math.sin(math.rad(angle))
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    
    btn:SetNormalTexture("Interface\\Icons\\INV_Relics_Hourglass")
    btn:SetPushedTexture("Interface\\Icons\\INV_Relics_Hourglass")
    btn:GetPushedTexture():SetVertexColor(0.8, 0.8, 0.8)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", -11, 11)
    
    btn:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            if KGT:IsShown() then
                KGT:Hide()
            else
                KGT:Show()
            end
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Key Giveaway Timer")
        GameTooltip:AddLine("Click to show/hide", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function KGT:StartTimer(duration)
    self.db.timerDuration = duration or self.db.timerDuration
    self.db.timeRemaining = self.db.timerDuration
    self.db.isRunning = true
    
    if self.timerTicker then
        self.timerTicker:Cancel()
    end
    
    self.timerTicker = C_Timer.NewTicker(0.1, function()
        self.db.timeRemaining = self.db.timeRemaining - 0.1
        if self.db.timeRemaining <= 0 then
            self.db.timeRemaining = 0
            self:StopTimer()
            self:TimerFinished()
        end
        self:UpdateTimerDisplay()
    end)
    
    self:Show()
    self:UpdateTimerDisplay()
end

function KGT:StopTimer()
    self.db.isRunning = false
    if self.timerTicker then
        self.timerTicker:Cancel()
        self.timerTicker = nil
    end
    self:UpdateTimerDisplay()
end

function KGT:ResetTimer()
    self:StopTimer()
    self.db.timeRemaining = self.db.timerDuration
    self:UpdateTimerDisplay()
end

function KGT:TimerFinished()
    UIFrameFlash(self, 0.3, 0.3, 2, false)
    PlaySound(10571)
    
    -- Flash border red
    self.border:SetBackdropBorderColor(1, 0, 0, 1)
    
    -- Hide for 5 seconds then show again
    self:Hide()
    C_Timer.After(5, function()
        -- Only show if user hasn't manually opened it and we're not running again
        if not self.db.isRunning then
            self:Show()
        end
    end)
    
    C_Timer.After(2, function()
        self.border:SetBackdropBorderColor(0.6, 0.5, 0.1, 0.3)
    end)
end

function KGT:HandleSlash(msg)
    msg = msg:lower()
    if msg == "start" then
        self:StartTimer()
    elseif msg == "stop" then
        self:StopTimer()
    elseif msg == "reset" then
        self:ResetTimer()
    elseif msg == "show" then
        self:Show()
    elseif msg == "hide" then
        self:Hide()
    else
        if self:IsShown() then
            self:Hide()
        else
            self:Show()
        end
    end
end

KGT:RegisterEvent("ADDON_LOADED")
KGT:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        self:Init()
    end
end)
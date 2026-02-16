local ADDON_NAME = ...

local defaults = {
    useAccountWide = true,
    showText = true,
    text = "Skill issue detected",
    font = "Fonts\\FRIZQT__.TTF",
    size = 32,
    posX = 0,
    posY = 300,
    color = { 1, 0, 0 },
}

local FONT_OPTIONS = {
    { label = "Friz Quadrata", value = "Fonts\\FRIZQT__.TTF" },
    { label = "Arial Narrow", value = "Fonts\\ARIALN.TTF" },
    { label = "Morpheus", value = "Fonts\\MORPHEUS.TTF" },
    { label = "Skurri", value = "Fonts\\SKURRI.TTF" },
}

local function copy_defaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            target[key] = target[key] or {}
            copy_defaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function ensure_db()
    SkillIssueDB = SkillIssueDB or {}
    SkillIssueCharDB = SkillIssueCharDB or {}
    copy_defaults(SkillIssueDB, defaults)
    copy_defaults(SkillIssueCharDB, defaults)
end

local function get_active_db()
    if SkillIssueDB.useAccountWide then
        return SkillIssueDB
    else
        return SkillIssueCharDB
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_UNGHOST")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local textFrame = CreateFrame("Frame", nil, UIParent)
textFrame:SetSize(1, 1)
textFrame:SetPoint("CENTER")
textFrame:SetFrameStrata("TOOLTIP")
textFrame:SetToplevel(true)
textFrame:Hide()

local textDisplay = textFrame:CreateFontString(nil, "OVERLAY")
textDisplay:SetPoint("CENTER")
textDisplay:SetFont(defaults.font, defaults.size, "OUTLINE")
textDisplay:SetTextColor(defaults.color[1], defaults.color[2], defaults.color[3])
textDisplay:SetText(defaults.text)

local blinkAnimation = textFrame:CreateAnimationGroup()
blinkAnimation:SetLooping("REPEAT")

local fadeOut = blinkAnimation:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0.1)
fadeOut:SetDuration(0.35)
fadeOut:SetOrder(1)

local fadeIn = blinkAnimation:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0.1)
fadeIn:SetToAlpha(1)
fadeIn:SetDuration(0.35)
fadeIn:SetOrder(2)

local previewTimer

local function apply_settings()
    local db = get_active_db()

    textDisplay:SetText(db.text or defaults.text)
    textDisplay:SetFont(db.font or defaults.font, db.size or defaults.size, "OUTLINE")

    local color = db.color or defaults.color
    textDisplay:SetTextColor(color[1], color[2], color[3])

    local posX = db.posX or defaults.posX
    local posY = db.posY or defaults.posY
    textFrame:ClearAllPoints()
    textFrame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
end

local function show_blink_text()
    local db = get_active_db()

    if not db.showText then
        return
    end

    apply_settings()
    textFrame:Show()
    if not blinkAnimation:IsPlaying() then
        blinkAnimation:Play()
    end
end

local function hide_blink_text()
    if blinkAnimation:IsPlaying() then
        blinkAnimation:Stop()
    end
    textFrame:Hide()
end

local function update_death_state()
    if UnitIsDeadOrGhost("player") then
        show_blink_text()
    else
        hide_blink_text()
    end
end

local function preview_blink_text()
    apply_settings()
    textFrame:Show()
    if not blinkAnimation:IsPlaying() then
        blinkAnimation:Play()
    end

    if previewTimer then
        previewTimer:Cancel()
    end

    previewTimer = C_Timer.NewTimer(3, function()
        previewTimer = nil
        update_death_state()
    end)
end

local function open_color_picker(initialColor, onColor, onCancel)
    if not ColorPickerFrame then
        return
    end

    local r, g, b = initialColor[1], initialColor[2], initialColor[3]

    if ColorPickerFrame.SetupColorPickerAndShow then
        local info = {
            r = r,
            g = g,
            b = b,
            hasOpacity = false,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                onColor(nr, ng, nb)
            end,
            cancelFunc = function(restore)
                if restore and restore.r and restore.g and restore.b then
                    onColor(restore.r, restore.g, restore.b)
                else
                    onCancel()
                end
            end,
        }

        ColorPickerFrame:SetupColorPickerAndShow(info)
        return
    end

    ColorPickerFrame:Hide()
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.previousValues = { r, g, b }
    ColorPickerFrame.func = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        onColor(nr, ng, nb)
    end
    ColorPickerFrame.cancelFunc = function()
        local pv = ColorPickerFrame.previousValues
        onColor(pv[1], pv[2], pv[3])
    end

    if ColorPickerFrame.SetColorRGB then
        ColorPickerFrame:SetColorRGB(r, g, b)
    end
    ColorPickerFrame:Show()
end

local function create_options_panel()
    local panel = CreateFrame("Frame")
    panel.name = "Skill Issue"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Skill Issue")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure the on-death text display")

    local accountWideCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    accountWideCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
    accountWideCheck.Text:SetText("Use account-wide settings")

    local enableCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", accountWideCheck, "BOTTOMLEFT", 0, -8)
    enableCheck.Text:SetText("Show blinking text on death")

    local textLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    textLabel:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -16)
    textLabel:SetText("Text")

    local textBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    textBox:SetPoint("TOPLEFT", textLabel, "BOTTOMLEFT", 0, -6)
    textBox:SetSize(260, 24)
    textBox:SetAutoFocus(false)

    local fontLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", textBox, "BOTTOMLEFT", 0, -16)
    fontLabel:SetText("Font")

    local fontDropDown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    fontDropDown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", -16, -4)

    local sizeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", fontDropDown, "BOTTOMLEFT", 16, -12)
    sizeLabel:SetText("Size")

    local sizeSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -8)
    sizeSlider:SetMinMaxValues(12, 72)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetObeyStepOnDrag(true)
    sizeSlider:SetWidth(260)
    sizeSlider.Low:SetText("12")
    sizeSlider.High:SetText("72")
    sizeSlider.Text:SetText("Font Size")

    local positionLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    positionLabel:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -16)
    positionLabel:SetText("Position")

    local xLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    xLabel:SetPoint("TOPLEFT", positionLabel, "BOTTOMLEFT", 0, -6)
    xLabel:SetText("X")

    local xBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    xBox:SetPoint("LEFT", xLabel, "RIGHT", 8, 0)
    xBox:SetSize(70, 24)
    xBox:SetAutoFocus(false)
    xBox:SetMaxLetters(7)

    local yLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    yLabel:SetPoint("LEFT", xBox, "RIGHT", 16, 0)
    yLabel:SetText("Y")

    local yBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    yBox:SetPoint("LEFT", yLabel, "RIGHT", 8, 0)
    yBox:SetSize(70, 24)
    yBox:SetAutoFocus(false)
    yBox:SetMaxLetters(7)

    local colorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", positionLabel, "BOTTOMLEFT", 0, -32)
    colorLabel:SetText("Color")

    local colorSwatch = CreateFrame("Button", nil, panel)
    colorSwatch:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -8)
    colorSwatch:SetSize(20, 20)

    local colorTexture = colorSwatch:CreateTexture(nil, "OVERLAY")
    colorTexture:SetAllPoints()

    local previewButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    previewButton:SetPoint("TOPLEFT", colorSwatch, "BOTTOMLEFT", 0, -16)
    previewButton:SetSize(120, 22)
    previewButton:SetText("Preview")

    local function refresh_controls()
        local db = get_active_db()
        
        accountWideCheck:SetChecked(SkillIssueDB.useAccountWide)
        enableCheck:SetChecked(db.showText)
        textBox:SetText(db.text)
        sizeSlider:SetValue(db.size)
        xBox:SetText(tostring(db.posX))
        yBox:SetText(tostring(db.posY))
        colorTexture:SetColorTexture(db.color[1], db.color[2], db.color[3])

        local selected
        for _, option in ipairs(FONT_OPTIONS) do
            if option.value == db.font then
                selected = option.label
                break
            end
        end
        UIDropDownMenu_SetText(fontDropDown, selected or FONT_OPTIONS[1].label)
    end

    accountWideCheck:SetScript("OnClick", function(self)
        SkillIssueDB.useAccountWide = self:GetChecked()
        refresh_controls()
        apply_settings()
    end)

    enableCheck:SetScript("OnClick", function(self)
        local db = get_active_db()
        db.showText = self:GetChecked()
    end)

    textBox:SetScript("OnEnterPressed", function(self)
        local db = get_active_db()
        db.text = self:GetText()
        apply_settings()
        self:ClearFocus()
    end)

    textBox:SetScript("OnEditFocusLost", function(self)
        local db = get_active_db()
        db.text = self:GetText()
        apply_settings()
    end)

    UIDropDownMenu_Initialize(fontDropDown, function(self, level)
        for _, option in ipairs(FONT_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.func = function()
                local db = get_active_db()
                db.font = option.value
                UIDropDownMenu_SetText(fontDropDown, option.label)
                apply_settings()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    sizeSlider:SetScript("OnValueChanged", function(self, value)
        local db = get_active_db()
        db.size = math.floor(value + 0.5)
        apply_settings()
    end)

    local function update_position_from_boxes()
        local db = get_active_db()
        local xValue = tonumber(xBox:GetText())
        local yValue = tonumber(yBox:GetText())
        if xValue then
            db.posX = xValue
        end
        if yValue then
            db.posY = yValue
        end
        apply_settings()
    end

    xBox:SetScript("OnEnterPressed", function(self)
        update_position_from_boxes()
        self:ClearFocus()
    end)

    xBox:SetScript("OnEditFocusLost", function()
        update_position_from_boxes()
    end)

    yBox:SetScript("OnEnterPressed", function(self)
        update_position_from_boxes()
        self:ClearFocus()
    end)

    yBox:SetScript("OnEditFocusLost", function()
        update_position_from_boxes()
    end)

    colorSwatch:SetScript("OnClick", function()
        local db = get_active_db()
        local original = { db.color[1], db.color[2], db.color[3] }
        open_color_picker(original, function(r, g, b)
            db.color = { r, g, b }
            colorTexture:SetColorTexture(r, g, b)
            apply_settings()
        end, function()
            colorTexture:SetColorTexture(original[1], original[2], original[3])
        end)
    end)

    previewButton:SetScript("OnClick", function()
        preview_blink_text()
    end)

    panel:SetScript("OnShow", function()
        refresh_controls()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "Skill Issue")
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= ADDON_NAME then
            return
        end
        ensure_db()
        apply_settings()
        create_options_panel()
        update_death_state()
        return
    end

    if event == "PLAYER_DEAD" then
        PlaySoundFile("Interface\\AddOns\\SkillIssue\\Ion_wisdom.ogg", "Master")
        show_blink_text()
        return
    end

    if event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        hide_blink_text()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        update_death_state()
    end
end)

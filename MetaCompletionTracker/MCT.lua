-- MCT.lua: User Interface and Event Controller for MetaCompletionTracker
local addonName, MCT = ...

-- Global SavedVariables database
MCT_DB = MCT_DB or {}

-- Active state
local currentMetaID = nil
local activeTree = nil
local expandedNodes = {}
local activeRows = {}
local rowPool = {}

---------------------------------------------------------------------------
-- 1. Main Window Creation
---------------------------------------------------------------------------
local mainFrame = CreateFrame("Frame", "MCT_MainFrame", UIParent, "BackdropTemplate")
mainFrame:SetSize(520, 680)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    if MCT_DB then
        MCT_DB.point = point
        MCT_DB.relativePoint = relativePoint
        MCT_DB.x = x
        MCT_DB.y = y
    end
end)
mainFrame:SetClampedToScreen(true)
mainFrame:SetFrameStrata("HIGH")

-- Backdrop styling for the main window frame
mainFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
mainFrame:SetBackdropColor(0.07, 0.08, 0.11, 0.95)
mainFrame:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.8)

-- Register in UISpecialFrames so Escape key closes it
tinsert(UISpecialFrames, "MCT_MainFrame")
mainFrame:Hide()

---------------------------------------------------------------------------
-- 2. Title Bar and Close Button
---------------------------------------------------------------------------
local titleBar = CreateFrame("Frame", nil, mainFrame)
titleBar:SetHeight(32)
titleBar:SetPoint("TOPLEFT", 6, -6)
titleBar:SetPoint("TOPRIGHT", -6, -6)

local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
titleIcon:SetSize(22, 22)
titleIcon:SetPoint("LEFT", 6, 0)
titleIcon:SetTexture("Interface\\Icons\\Achievement_General")

local titleText = titleBar:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
titleText:SetPoint("LEFT", titleIcon, "RIGHT", 8)
titleText:SetText("|cFF00BFFFMetaCompletionTracker|r")

local versionText = titleBar:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
versionText:SetPoint("LEFT", titleText, "RIGHT", 6)
versionText:SetText("v2.0")

local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
closeButton:SetScript("OnClick", function()
    mainFrame:Hide()
end)

---------------------------------------------------------------------------
-- 2.5 Wowhead URL Copy Dialog
---------------------------------------------------------------------------
local copyPopup = CreateFrame("Frame", "MCT_CopyURLDialog", UIParent, "BackdropTemplate")
copyPopup:SetSize(440, 130)
copyPopup:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
copyPopup:SetFrameStrata("DIALOG")
copyPopup:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
copyPopup:SetBackdropColor(0.08, 0.09, 0.12, 0.98)
copyPopup:SetBackdropBorderColor(0.2, 0.6, 1.0, 0.9)
copyPopup:EnableMouse(true)
copyPopup:Hide()
tinsert(UISpecialFrames, "MCT_CopyURLDialog")

local popupTitle = copyPopup:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
popupTitle:SetPoint("TOPLEFT", 14, -14)
popupTitle:SetPoint("TOPRIGHT", -30, -14)
popupTitle:SetJustifyH("LEFT")
popupTitle:SetWordWrap(false)
popupTitle:SetText("Wowhead Link")

local popupSubtitle = copyPopup:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
popupSubtitle:SetPoint("TOPLEFT", popupTitle, "BOTTOMLEFT", 0, -6)
popupSubtitle:SetText("Press |cFF00FF00Ctrl+C|r to copy, then paste into your web browser:")

local popupEditBox = CreateFrame("EditBox", nil, copyPopup, "InputBoxTemplate")
popupEditBox:SetSize(400, 22)
popupEditBox:SetPoint("TOPLEFT", popupSubtitle, "BOTTOMLEFT", 4, -8)
popupEditBox:SetAutoFocus(true)
popupEditBox:SetScript("OnEscapePressed", function() copyPopup:Hide() end)
popupEditBox:SetScript("OnEnterPressed", function() copyPopup:Hide() end)
popupEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

local popupCloseBtn = CreateFrame("Button", nil, copyPopup, "UIPanelButtonTemplate")
popupCloseBtn:SetSize(80, 22)
popupCloseBtn:SetPoint("BOTTOM", 0, 10)
popupCloseBtn:SetText("Done")
popupCloseBtn:SetNormalFontObject("GameFontNormalSmall")
popupCloseBtn:SetScript("OnClick", function() copyPopup:Hide() end)

local popupXBtn = CreateFrame("Button", nil, copyPopup, "UIPanelCloseButton")
popupXBtn:SetPoint("TOPRIGHT", -2, -2)
popupXBtn:SetScript("OnClick", function() copyPopup:Hide() end)

function MCT.ShowWowheadURL(data, parentID)
    local url = nil
    local title = "Achievement"

    if data and data.id then
        url = "https://www.wowhead.com/achievement=" .. data.id
        title = data.name or ("Achievement #" .. data.id)
    elseif data and data.assetID and data.criteriaType == 27 then
        url = "https://www.wowhead.com/quest=" .. data.assetID
        title = (data.criteriaString and data.criteriaString ~= "" and data.criteriaString) or ("Quest #" .. data.assetID)
    elseif data and data.assetID and data.criteriaType == 0 then
        url = "https://www.wowhead.com/npc=" .. data.assetID
        title = (data.criteriaString and data.criteriaString ~= "" and data.criteriaString) or ("NPC #" .. data.assetID)
    elseif parentID then
        url = "https://www.wowhead.com/achievement=" .. parentID
        local pData = MCT.Engine.GetAchievementData(parentID)
        title = (pData and pData.name) or ("Achievement #" .. parentID)
        if data and data.criteriaString and data.criteriaString ~= "" then
            title = data.criteriaString .. " (" .. title .. ")"
        end
    end

    if not url then return end

    popupTitle:SetText("|cFF00BFFFWowhead Link:|r " .. title)
    popupEditBox:SetText(url)
    copyPopup:Show()
    popupEditBox:SetFocus()
    popupEditBox:HighlightText()

    print("|cFF00A6FFMCT Wowhead URL:|r " .. title .. " - |cFF33BBFF" .. url .. "|r")
end


---------------------------------------------------------------------------
-- 3. Preset Selector Bar
---------------------------------------------------------------------------
local presetBar = CreateFrame("Frame", nil, mainFrame)
presetBar:SetHeight(30)
presetBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -4)
presetBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -4)

local barPresets = {}
for _, preset in ipairs(MCT.Presets) do
    if preset.shortName then
        table.insert(barPresets, preset)
    end
end

local presetButtons = {}
local numPresets = #barPresets
local presetSpacing = 3
local totalBarWidth = 504
local presetWidth = math.floor((totalBarWidth - (numPresets - 1) * presetSpacing) / numPresets)

for i, preset in ipairs(barPresets) do
    local btn = CreateFrame("Button", nil, presetBar, "UIPanelButtonTemplate")
    btn:SetSize(presetWidth, 24)
    btn:SetPoint("LEFT", (i - 1) * (presetWidth + presetSpacing) + 4, 0)
    
    btn:SetText(preset.shortName or "Meta")
    btn:SetNormalFontObject("GameFontNormalSmall")
    btn:SetHighlightFontObject("GameFontHighlightSmall")
    
    btn:SetScript("OnClick", function()
        MCT.SelectAchievement(preset.id)
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(preset.name, 1, 0.82, 0)
        GameTooltip:AddLine(preset.expansion .. " (" .. preset.category .. ")", 0.7, 0.7, 0.7)
        if preset.reward and preset.reward ~= "" then
            GameTooltip:AddLine("Reward: " .. preset.reward, 0, 1, 0.8)
        end
        GameTooltip:AddLine(preset.description, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    presetButtons[preset.id] = btn
end

---------------------------------------------------------------------------
-- 4. Custom ID Search / Filter Controls
---------------------------------------------------------------------------
local searchBar = CreateFrame("Frame", nil, mainFrame)
searchBar:SetHeight(26)
searchBar:SetPoint("TOPLEFT", presetBar, "BOTTOMLEFT", 4, -4)
searchBar:SetPoint("TOPRIGHT", presetBar, "BOTTOMRIGHT", -4, -4)

local searchLabel = searchBar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
searchLabel:SetPoint("LEFT", 2, 0)
searchLabel:SetText("Custom ID:")

local searchEditBox = CreateFrame("EditBox", nil, searchBar, "InputBoxTemplate")
searchEditBox:SetSize(110, 20)
searchEditBox:SetPoint("LEFT", searchLabel, "RIGHT", 6, 0)
searchEditBox:SetAutoFocus(false)
searchEditBox:SetNumeric(false)
searchEditBox:SetMaxLetters(60)

local searchGoBtn = CreateFrame("Button", nil, searchBar, "UIPanelButtonTemplate")
searchGoBtn:SetSize(52, 22)
searchGoBtn:SetPoint("LEFT", searchEditBox, "RIGHT", 6, 0)
searchGoBtn:SetText("Track")
searchGoBtn:SetNormalFontObject("GameFontNormalSmall")

local function ProcessInput()
    local text = searchEditBox:GetText()
    if text and text ~= "" then
        local achID = text:match("achievement:(%d+)") or text:match("(%d+)")
        if achID then
            MCT.SelectAchievement(tonumber(achID))
            searchEditBox:SetText("")
            searchEditBox:ClearFocus()
        end
    end
end

searchGoBtn:SetScript("OnClick", ProcessInput)
searchEditBox:SetScript("OnEnterPressed", ProcessInput)

-- Expand / Collapse All Button
local toggleAllBtn = CreateFrame("Button", nil, searchBar, "UIPanelButtonTemplate")
toggleAllBtn:SetSize(65, 22)
toggleAllBtn:SetPoint("RIGHT", searchBar, "RIGHT", -4, 0)
toggleAllBtn:SetText("Expand")
toggleAllBtn:SetNormalFontObject("GameFontNormalSmall")
local allExpanded = false

-- Hide Completed Checkbox (Anchored relative to toggleAllBtn with clean spacing)
local hideCompletedLabel = searchBar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
hideCompletedLabel:SetPoint("RIGHT", toggleAllBtn, "LEFT", -12, 0)
hideCompletedLabel:SetText("Hide Done")

local hideCompletedCheck = CreateFrame("CheckButton", nil, searchBar, "UICheckButtonTemplate")
hideCompletedCheck:SetSize(22, 22)
hideCompletedCheck:SetPoint("RIGHT", hideCompletedLabel, "LEFT", -2, 0)

hideCompletedCheck:SetScript("OnClick", function(self)
    MCT_DB.hideCompleted = self:GetChecked()
    MCT.RefreshDisplay()
end)

toggleAllBtn:SetScript("OnClick", function(self)
    allExpanded = not allExpanded
    if not allExpanded then
        expandedNodes = {}
        self:SetText("Expand")
    else
        self:SetText("Collapse")
        if activeTree and activeTree.criteria then
            local function ExpandAll(criteriaList)
                for _, item in ipairs(criteriaList) do
                    if item.isSubAchievement and item.assetID then
                        expandedNodes[item.assetID] = true
                        if item.subTree and item.subTree.criteria then
                            ExpandAll(item.subTree.criteria)
                        end
                    end
                end
            end
            ExpandAll(activeTree.criteria)
        end
    end
    MCT.RefreshDisplay()
end)

---------------------------------------------------------------------------
-- 5. Meta Achievement Header Banner (Icon, Title, Reward, Progress)
---------------------------------------------------------------------------
local headerCard = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
headerCard:SetHeight(76)
headerCard:SetPoint("TOPLEFT", searchBar, "BOTTOMLEFT", 0, -6)
headerCard:SetPoint("TOPRIGHT", searchBar, "BOTTOMRIGHT", 0, -6)
headerCard:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
headerCard:SetBackdropColor(0.12, 0.14, 0.18, 0.9)
headerCard:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.7)

local metaIcon = headerCard:CreateTexture(nil, "ARTWORK")
metaIcon:SetSize(52, 52)
metaIcon:SetPoint("TOPLEFT", 10, -10)
metaIcon:SetTexture("Interface\\Icons\\Achievement_General")

local metaTitle = headerCard:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
metaTitle:SetPoint("TOPLEFT", metaIcon, "TOPRIGHT", 10, -2)
metaTitle:SetPoint("RIGHT", headerCard, "RIGHT", -10, 0)
metaTitle:SetJustifyH("LEFT")
metaTitle:SetText("Loading...")

local metaReward = headerCard:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
metaReward:SetPoint("TOPLEFT", metaTitle, "BOTTOMLEFT", 0, -3)
metaReward:SetPoint("RIGHT", headerCard, "RIGHT", -10, 0)
metaReward:SetJustifyH("LEFT")
metaReward:SetText("")

-- Progress Bar
local progressBar = CreateFrame("StatusBar", nil, headerCard)
progressBar:SetHeight(16)
progressBar:SetPoint("BOTTOMLEFT", metaIcon, "BOTTOMRIGHT", 10, 2)
progressBar:SetPoint("BOTTOMRIGHT", headerCard, "BOTTOMRIGHT", -10, 10)
progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
progressBar:SetStatusBarColor(0.15, 0.55, 0.95)
progressBar:SetMinMaxValues(0, 100)
progressBar:SetValue(0)

local progressBg = progressBar:CreateTexture(nil, "BACKGROUND")
progressBg:SetAllPoints()
progressBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
progressBg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

local progressText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
progressText:SetPoint("CENTER", progressBar, "CENTER", 0, 0)
progressText:SetText("0 / 0 (0%)")

headerCard:EnableMouse(true)
headerCard:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        if currentMetaID and type(currentMetaID) == "number" then
            MCT.ShowWowheadURL({ id = currentMetaID, name = metaTitle:GetText() })
        end
    else
        if currentMetaID and type(currentMetaID) == "number" then
            MCT.Engine.OpenAchievement(currentMetaID)
        end
    end
end)
headerCard:SetScript("OnEnter", function(self)
    if currentMetaID then
        if type(currentMetaID) == "number" then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetHyperlink(GetAchievementLink(currentMetaID) or ("achievement:" .. currentMetaID))
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFF00FF00Left-Click|r: View in Achievement UI", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("|cFF00FF00Right-Click|r: Copy Wowhead Link", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        else
            local activePreset = nil
            for _, p in ipairs(MCT.Presets) do
                if p.id == currentMetaID then
                    activePreset = p
                    break
                end
            end
            if activePreset then
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:AddLine(activePreset.name, 1, 0.82, 0)
                GameTooltip:AddLine(activePreset.expansion .. " (" .. activePreset.category .. ")", 0.7, 0.7, 0.7)
                if activePreset.reward and activePreset.reward ~= "" then
                    GameTooltip:AddLine("Reward: " .. activePreset.reward, 0, 1, 0.8)
                end
                GameTooltip:AddLine(activePreset.description, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end
    end
end)
headerCard:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

---------------------------------------------------------------------------
-- 6. Scrollable Content Area & Frame Pool
---------------------------------------------------------------------------
local scrollFrame = CreateFrame("ScrollFrame", "MCT_ScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", headerCard, "BOTTOMLEFT", 0, -8)
scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -28, 10)
scrollFrame:EnableMouseWheel(true)

local scrollChild = CreateFrame("Frame", "MCT_ScrollContent", scrollFrame)
scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
scrollChild:SetWidth(480)
scrollChild:SetHeight(100)
scrollFrame:SetScrollChild(scrollChild)

-- Smooth mouse wheel handler
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local step = 36
    local newScroll = current - (delta * step)
    if newScroll < 0 then newScroll = 0 end
    if newScroll > maxScroll then newScroll = maxScroll end
    self:SetVerticalScroll(newScroll)
end)

-- Reusable Row Frame Pool (Hardware-accelerated color textures, zero backdrop overhead)
local function AcquireRow()
    local row = table.remove(rowPool)
    if not row then
        row = CreateFrame("Button", nil, scrollChild)
        row:SetHeight(28)

        -- Flat background texture
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        row.bg = bg

        -- Subtle bottom separator line
        local sep = row:CreateTexture(nil, "BORDER")
        sep:SetHeight(1)
        sep:SetPoint("BOTTOMLEFT", 0, 0)
        sep:SetPoint("BOTTOMRIGHT", 0, 0)
        sep:SetColorTexture(0.2, 0.25, 0.32, 0.25)
        row.sep = sep

        -- Hover highlight
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(0.25, 0.4, 0.65, 0.25)
        row.hl = hl

        -- Expand/Collapse Button
        local chevron = CreateFrame("Button", nil, row)
        chevron:SetSize(18, 18)
        local chevronText = chevron:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        chevronText:SetPoint("CENTER")
        chevron.text = chevronText
        row.chevron = chevron

        -- Status Icon (Checkmark / Cross)
        local statusIcon = row:CreateTexture(nil, "ARTWORK")
        statusIcon:SetSize(16, 16)
        row.statusIcon = statusIcon

        -- Achievement Icon (for sub-achievements)
        local achIcon = row:CreateTexture(nil, "ARTWORK")
        achIcon:SetSize(20, 20)
        row.achIcon = achIcon

        -- Achievement Title / Criteria Text
        local nameText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nameText:SetJustifyH("LEFT")
        nameText:SetWordWrap(false)
        row.nameText = nameText

        -- Progress Label (e.g. 14/18)
        local progressLabel = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        progressLabel:SetPoint("RIGHT", row, "RIGHT", -32, 0)
        progressLabel:SetJustifyH("RIGHT")
        row.progressLabel = progressLabel

        -- Native Track Pin Button
        local trackBtn = CreateFrame("Button", nil, row)
        trackBtn:SetSize(22, 22)
        trackBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        local trackIcon = trackBtn:CreateTexture(nil, "ARTWORK")
        trackIcon:SetSize(16, 16)
        trackIcon:SetPoint("CENTER")
        trackIcon:SetTexture("Interface\\Icons\\INV_Misc_Map02")
        trackBtn.icon = trackIcon
        row.trackBtn = trackBtn

        -- Tooltips
        row:SetScript("OnEnter", function(self)
            if self.data and self.data.id then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(GetAchievementLink(self.data.id) or ("achievement:" .. self.data.id))
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cFF00FF00Left-Click|r: View in Achievement UI", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("|cFF00FF00Right-Click|r: Copy Wowhead Link", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("|cFF00FF00Shift-Click|r: Toggle Native Tracking", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            elseif self.data and self.data.criteriaString then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(self.data.criteriaString, 1, 0.82, 0)
                if self.data.quantityString and self.data.quantityString ~= "" then
                    GameTooltip:AddLine("Progress: " .. self.data.quantityString, 1, 1, 1)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cFF00FF00Right-Click|r: Copy Wowhead Link", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                MCT.ShowWowheadURL(self.data, self.parentID)
            elseif IsShiftKeyDown() then
                if self.data and self.data.id then
                    MCT.Engine.ToggleTrackAchievement(self.data.id)
                    MCT.RefreshDisplay()
                end
            else
                if self.data and self.data.id then
                    MCT.Engine.OpenAchievement(self.data.id)
                elseif self.parentID then
                    MCT.Engine.OpenAchievement(self.parentID)
                end
            end
        end)
    end

    row:Show()
    table.insert(activeRows, row)
    return row
end

local function ReleaseAllRows()
    for _, row in ipairs(activeRows) do
        row:Hide()
        row:ClearAllPoints()
        row.data = nil
        table.insert(rowPool, row)
    end
    activeRows = {}
end

---------------------------------------------------------------------------
-- 7. Rendering Rows & Tree Layout
---------------------------------------------------------------------------
function MCT.RefreshDisplay()
    ReleaseAllRows()

    if not activeTree or not activeTree.criteria then
        return
    end

    -- Match scroll child width to scrollFrame
    local frameWidth = scrollFrame:GetWidth()
    if frameWidth and frameWidth > 100 then
        scrollChild:SetWidth(frameWidth)
    else
        scrollChild:SetWidth(480)
    end

    local hideDone = MCT_DB.hideCompleted or false
    local yOffset = 0
    local rowIndex = 0

    local function RenderItem(item, indent, parentID)
        local isComplete = item.completed
        if hideDone and isComplete then
            return
        end

        rowIndex = rowIndex + 1
        local row = AcquireRow()

        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
        row:SetHeight(28)

        -- Alternating flat background colors
        if rowIndex % 2 == 0 then
            row.bg:SetColorTexture(0.09, 0.11, 0.14, 0.7)
        else
            row.bg:SetColorTexture(0.06, 0.07, 0.09, 0.7)
        end

        local indentPx = indent * 14
        local leftOffset = 4 + indentPx

        -- Sub-achievement row
        if item.isSubAchievement and item.subAchievementData then
            local subData = item.subAchievementData
            row.data = subData
            row.parentID = parentID

            local hasSubTree = item.subTree and item.subTree.criteria and #item.subTree.criteria > 0

            -- Chevron positioning
            row.chevron:ClearAllPoints()
            row.chevron:SetPoint("LEFT", row, "LEFT", leftOffset, 0)

            if hasSubTree then
                row.chevron:Show()
                local isExpanded = expandedNodes[subData.id] or false
                row.chevron.text:SetText(isExpanded and "|cFFFFD100[-]|r" or "|cFF00BFFF[+]|r")
                row.chevron:SetScript("OnClick", function()
                    expandedNodes[subData.id] = not expandedNodes[subData.id]
                    MCT.RefreshDisplay()
                end)
            else
                row.chevron:Hide()
            end

            -- Status icon
            row.statusIcon:ClearAllPoints()
            row.statusIcon:SetPoint("LEFT", row, "LEFT", leftOffset + 20, 0)
            if subData.completed then
                row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            else
                row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
            end

            -- Achievement icon
            row.achIcon:ClearAllPoints()
            row.achIcon:SetPoint("LEFT", row, "LEFT", leftOffset + 38, 0)
            row.achIcon:SetTexture(subData.icon or 134400)
            row.achIcon:Show()

            -- Title
            row.nameText:ClearAllPoints()
            row.nameText:SetPoint("LEFT", row, "LEFT", leftOffset + 62, 0)
            row.nameText:SetPoint("RIGHT", row, "RIGHT", -90, 0)
            local nameColor = subData.completed and "|cFF888888" or "|cFFFFFFFF"
            row.nameText:SetText(nameColor .. (subData.name or ("Achievement #" .. subData.id)) .. "|r")

            -- Sub-progress (e.g. 14/18)
            if item.subTree and item.subTree.totalCriteria > 0 then
                local subPct = item.subTree.percent
                local pColor = subPct == 100 and "|cFF00FF00" or "|cFFFFCC00"
                row.progressLabel:SetText(pColor .. item.subTree.completedCriteria .. "/" .. item.subTree.totalCriteria .. "|r")
            else
                row.progressLabel:SetText("")
            end

            -- Track button
            local isTracked = MCT.Engine.IsTracked(subData.id)
            row.trackBtn:Show()
            row.trackBtn.icon:SetVertexColor(isTracked and 1 or 0.4, isTracked and 0.82 or 0.4, isTracked and 0 or 0.4)
            row.trackBtn:SetScript("OnClick", function()
                MCT.Engine.ToggleTrackAchievement(subData.id)
                MCT.RefreshDisplay()
            end)

            yOffset = yOffset + 29

            -- Recursively render children if expanded
            if hasSubTree and (expandedNodes[subData.id] or false) then
                for _, child in ipairs(item.subTree.criteria) do
                    RenderItem(child, indent + 1, subData.id)
                end
            end

        else
            -- Direct criteria row (Quest, Kill, Explore, etc.)
            row.data = item
            row.parentID = parentID

            row.chevron:Hide()
            row.achIcon:Hide()
            row.trackBtn:Hide()

            -- Status icon
            row.statusIcon:ClearAllPoints()
            row.statusIcon:SetPoint("LEFT", row, "LEFT", leftOffset + 20, 0)
            if item.completed then
                row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            else
                row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
            end

            -- Criteria Text
            local cName = item.criteriaString
            if not cName or cName == "" then
                cName = "Requirement #" .. item.index
            end

            row.nameText:ClearAllPoints()
            row.nameText:SetPoint("LEFT", row, "LEFT", leftOffset + 40, 0)
            row.nameText:SetPoint("RIGHT", row, "RIGHT", -90, 0)
            local textColor = item.completed and "|cFF888888" or "|cFFD0D0D0"
            row.nameText:SetText(textColor .. cName .. "|r")

            -- Quantity Progress
            if item.quantityString and item.quantityString ~= "" then
                row.progressLabel:SetText("|cFF88AAFF" .. item.quantityString .. "|r")
            elseif item.reqQuantity and item.reqQuantity > 1 then
                row.progressLabel:SetText("|cFF88AAFF" .. (item.quantity or 0) .. "/" .. item.reqQuantity .. "|r")
            else
                row.progressLabel:SetText("")
            end

            yOffset = yOffset + 29
        end
    end

    for _, item in ipairs(activeTree.criteria) do
        RenderItem(item, 0, currentMetaID)
    end

    scrollChild:SetHeight(math.max(yOffset + 20, 300))
end

---------------------------------------------------------------------------
-- 8. Select and Load Meta Achievement
---------------------------------------------------------------------------
function MCT.SelectAchievement(achievementID)
    if not achievementID then return end
    if type(achievementID) == "number" and achievementID <= 0 then return end
    currentMetaID = achievementID
    MCT_DB.selectedPresetID = achievementID

    -- Update Preset Buttons Highlights
    for pid, btn in pairs(presetButtons) do
        if pid == achievementID then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end

    -- Build Tree (depth 5 allows exploring full hierarchies like Hot Tropic, Mecha-Done, etc.)
    activeTree = MCT.Engine.GetCriteriaTree(achievementID, 5, 1)
    if not activeTree then return end

    local metaData = activeTree.data

    -- Update Header Card
    metaIcon:SetTexture(metaData.icon or 134400)

    local activePreset = nil
    for _, p in ipairs(MCT.Presets) do
        if p.id == achievementID then
            activePreset = p
            break
        end
    end

    local displayTitle = metaData.name or ("Achievement #" .. achievementID)
    if activePreset and (activePreset.category == "Expansion Super-Meta" or activePreset.category == "Expansion Meta") then
        local rawName = (metaData.isLoaded and metaData.name) or activePreset.name or metaData.name
        if rawName and not rawName:find(activePreset.expansion, 1, true) then
            displayTitle = activePreset.expansion .. ": " .. rawName
        else
            displayTitle = rawName or activePreset.expansion
        end
    end
    metaTitle:SetText(displayTitle)

    local presetReward = activePreset and activePreset.reward

    local rewardStr = presetReward or metaData.rewardText
    if rewardStr and rewardStr ~= "" then
        metaReward:SetText("|cFF00FFCCReward: " .. rewardStr .. "|r")
    else
        metaReward:SetText("|cFF888888Category: " .. (metaData.points or 0) .. " Points|r")
    end

    -- Update Progress Bar
    progressBar:SetValue(activeTree.percent)
    if activeTree.percent == 100 then
        progressBar:SetStatusBarColor(0.1, 0.8, 0.3)
        progressText:SetText("|cFF00FF00COMPLETED! (100%)|r")
    else
        progressBar:SetStatusBarColor(0.15, 0.55, 0.95)
        progressText:SetText(activeTree.completedCriteria .. " / " .. activeTree.totalCriteria .. " (" .. activeTree.percent .. "%)")
    end

    -- Reset vertical scroll to top on switching achievements
    scrollFrame:SetVerticalScroll(0)

    MCT.RefreshDisplay()
end

---------------------------------------------------------------------------
-- 9. Slash Commands & Throttled Event Registration
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CRITERIA_UPDATE")
eventFrame:RegisterEvent("ACHIEVEMENT_SEARCH_UPDATED")
eventFrame:RegisterEvent("TRACKED_ACHIEVEMENT_LIST_CHANGED")

-- Throttled refresh to prevent visual hitching during event bursts
local refreshPending = false
local function RequestThrottledRefresh()
    if refreshPending or not mainFrame:IsShown() or not currentMetaID then return end
    refreshPending = true
    C_Timer.After(0.2, function()
        refreshPending = false
        if mainFrame:IsShown() and currentMetaID then
            -- Re-evaluate tree data and smoothly update UI
            activeTree = MCT.Engine.GetCriteriaTree(currentMetaID, 5, 1)
            if activeTree then
                progressBar:SetValue(activeTree.percent)
                progressText:SetText(activeTree.completedCriteria .. " / " .. activeTree.totalCriteria .. " (" .. activeTree.percent .. "%)")
                MCT.RefreshDisplay()
            end
        end
    end)
end

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        MCT_DB = MCT_DB or {}
        if MCT_DB.hideCompleted ~= nil then
            hideCompletedCheck:SetChecked(MCT_DB.hideCompleted)
        end

        if MCT_DB.point then
            mainFrame:ClearAllPoints()
            mainFrame:SetPoint(MCT_DB.point, UIParent, MCT_DB.relativePoint or "CENTER", MCT_DB.x or 0, MCT_DB.y or 0)
        end

        local targetID = MCT_DB.selectedPresetID or MCT.DefaultPresetID
        MCT.SelectAchievement(targetID)

        print("|cFF00A6FFMetaCompletionTracker|r v2.0 loaded. Type |cFF00FF00/mct|r to toggle.")

    elseif event == "CRITERIA_UPDATE" or event == "ACHIEVEMENT_SEARCH_UPDATED" or event == "TRACKED_ACHIEVEMENT_LIST_CHANGED" then
        RequestThrottledRefresh()
    end
end)

-- Slash Commands
SLASH_MCT1 = "/mct"
SlashCmdList["MCT"] = function(msg)
    local command = msg and msg:trim() or ""
    
    if command == "reset" then
        MCT_DB = {}
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        MCT.SelectAchievement(MCT.DefaultPresetID)
        print("|cFF00A6FFMCT:|r Settings and position have been reset.")
        return
    end

    local customID = tonumber(command)
    if customID and customID > 0 then
        MCT.SelectAchievement(customID)
        mainFrame:Show()
        return
    end

    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        if currentMetaID then
            MCT.SelectAchievement(currentMetaID)
        else
            MCT.SelectAchievement(MCT.DefaultPresetID)
        end
    end
end

SLASH_HIDEMCT1 = "/hidemct"
SlashCmdList["HIDEMCT"] = function()
    mainFrame:Hide()
end
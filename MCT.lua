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

local addonVersion = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")) or "2.1.2"

local versionText = titleBar:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
versionText:SetPoint("LEFT", titleText, "RIGHT", 6)
versionText:SetText("v" .. addonVersion)

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
popupEditBox:SetAutoFocus(false)
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

    if data and data.questID then
        url = "https://www.wowhead.com/quest=" .. data.questID
        title = data.title or data.name or ("Quest #" .. data.questID)
    elseif data and data.id then
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
-- 3. Expansion Level Headers & Achievement Sub-Headings
---------------------------------------------------------------------------
local currentExpansionKey = "BfA"
local expansionButtons = {}
local subHeadingButtons = {}
local lastPresetByExpansion = {}

-- Top-Level Expansion Headers Bar
local expansionBar = CreateFrame("Frame", nil, mainFrame)
expansionBar:SetHeight(26)
expansionBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -4)
expansionBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -4)

-- Sub-Headings Bar (Achievements for the selected expansion)
local subPresetBar = CreateFrame("Frame", nil, mainFrame)
subPresetBar:SetHeight(24)
subPresetBar:SetPoint("TOPLEFT", expansionBar, "BOTTOMLEFT", 0, -3)
subPresetBar:SetPoint("TOPRIGHT", expansionBar, "BOTTOMRIGHT", 0, -3)

local function UpdatePresetNavigation(targetAchID)
    -- 1. Highlight active expansion button
    for _, btn in ipairs(expansionButtons) do
        if btn.expansionKey == currentExpansionKey then
            btn:SetBackdropColor(0.16, 0.20, 0.28, 0.98)
            btn:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
            btn.text:SetTextColor(1.0, 0.82, 0.0)
        else
            btn:SetBackdropColor(0.08, 0.09, 0.12, 0.85)
            btn:SetBackdropBorderColor(0.25, 0.30, 0.40, 0.6)
            btn.text:SetTextColor(0.80, 0.80, 0.80)
        end
    end

    -- 2. Populate and layout sub-heading buttons for current expansion
    local expPresets = {}
    if MCT.Presets then
        for _, p in ipairs(MCT.Presets) do
            if p.expansionKey == currentExpansionKey then
                table.insert(expPresets, p)
            end
        end
    end

    for _, btn in ipairs(subHeadingButtons) do
        btn:Hide()
    end

    local numSub = #expPresets
    if numSub == 0 then return end

    local spacing = 4
    local totalWidth = 504
    local btnWidth = math.floor((totalWidth - (numSub - 1) * spacing) / numSub)

    for i, p in ipairs(expPresets) do
        local btn = subHeadingButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, subPresetBar, "BackdropTemplate")
            btn:SetHeight(22)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = false,
                edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })

            local btnText = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            btnText:SetPoint("CENTER", 0, 0)
            btnText:SetPoint("LEFT", 4, 0)
            btnText:SetPoint("RIGHT", -4, 0)
            btnText:SetJustifyH("CENTER")
            btnText:SetWordWrap(false)
            btn.text = btnText

            btn:SetScript("OnClick", function(self)
                if self.presetID then
                    MCT.SelectAchievement(self.presetID)
                end
            end)

            btn:SetScript("OnEnter", function(self)
                local pData = self.preset
                if not pData then return end
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(pData.name, 1, 0.82, 0)
                GameTooltip:AddLine(pData.expansion .. " (" .. pData.category .. ")", 0.7, 0.7, 0.7)
                if pData.reward and pData.reward ~= "" then
                    GameTooltip:AddLine("Reward: " .. pData.reward, 0, 1, 0.8)
                end
                GameTooltip:AddLine(pData.description, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            table.insert(subHeadingButtons, btn)
        end

        btn:SetSize(btnWidth, 22)
        btn:ClearAllPoints()
        btn:SetPoint("LEFT", (i - 1) * (btnWidth + spacing) + 4, 0)
        btn.preset = p
        btn.presetID = p.id
        btn.text:SetText(p.subHeading or p.shortName or p.name)

        if p.id == targetAchID then
            btn:SetBackdropColor(0.12, 0.18, 0.26, 0.98)
            btn:SetBackdropBorderColor(0.1, 0.85, 0.95, 1.0)
            btn.text:SetTextColor(0.1, 0.9, 1.0)
        else
            btn:SetBackdropColor(0.06, 0.08, 0.11, 0.8)
            btn:SetBackdropBorderColor(0.2, 0.25, 0.35, 0.5)
            btn.text:SetTextColor(0.75, 0.75, 0.75)
        end

        btn:Show()
    end
end

-- Create Expansion Buttons
local numExp = MCT.Expansions and #MCT.Expansions or 0
local expSpacing = 4
local totalExpWidth = 504
local expWidth = numExp > 0 and math.floor((totalExpWidth - (numExp - 1) * expSpacing) / numExp) or 80

if MCT.Expansions then
    for i, exp in ipairs(MCT.Expansions) do
        local btn = CreateFrame("Button", nil, expansionBar, "BackdropTemplate")
        btn:SetSize(expWidth, 24)
        btn:SetPoint("LEFT", (i - 1) * (expWidth + expSpacing) + 4, 0)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        btn:SetBackdropColor(0.08, 0.09, 0.12, 0.85)
        btn:SetBackdropBorderColor(0.25, 0.30, 0.40, 0.6)

        local btnText = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        btnText:SetPoint("CENTER", 0, 0)
        btnText:SetText(exp.label or exp.name)
        btnText:SetWordWrap(false)
        btn.text = btnText
        btn.expansionKey = exp.key

        btn:SetScript("OnClick", function(self)
            currentExpansionKey = self.expansionKey
            local targetID = lastPresetByExpansion[self.expansionKey]
            if not targetID then
                for _, p in ipairs(MCT.Presets) do
                    if p.expansionKey == self.expansionKey then
                        targetID = p.id
                        break
                    end
                end
            end
            if targetID then
                MCT.SelectAchievement(targetID)
            else
                UpdatePresetNavigation(nil)
            end
        end)

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(exp.name, 1, 0.82, 0)
            GameTooltip:AddLine("Expansion Level Meta Achievements", 0.7, 0.7, 0.7)
            GameTooltip:AddLine(" ")
            for _, p in ipairs(MCT.Presets) do
                if p.expansionKey == exp.key then
                    GameTooltip:AddLine("• |cFFFFFFFF" .. (p.subHeading or p.name) .. "|r", 0.9, 0.9, 0.9)
                end
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFF00FF00Click|r: View " .. exp.name .. " meta achievements", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        table.insert(expansionButtons, btn)
    end
end

---------------------------------------------------------------------------
-- 4. Custom ID Search / Filter Controls
---------------------------------------------------------------------------
local searchBar = CreateFrame("Frame", nil, mainFrame)
searchBar:SetHeight(26)
searchBar:SetPoint("TOPLEFT", subPresetBar, "BOTTOMLEFT", 4, -4)
searchBar:SetPoint("TOPRIGHT", subPresetBar, "BOTTOMRIGHT", -4, -4)

local searchLabel = searchBar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
searchLabel:SetPoint("LEFT", 2, 0)
searchLabel:SetText("Custom ID:")

local searchEditBox = CreateFrame("EditBox", nil, searchBar, "InputBoxTemplate")
searchEditBox:SetSize(110, 20)
searchEditBox:SetPoint("LEFT", searchLabel, "RIGHT", 6, 0)
searchEditBox:SetAutoFocus(false)
searchEditBox:SetNumeric(false)
searchEditBox:SetMaxLetters(200)

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
searchEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

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
-- 4.5 Active World Quests Alert Bar
---------------------------------------------------------------------------
local wqAlertBar = CreateFrame("Button", "MCT_WQAlertBar", mainFrame, "BackdropTemplate")
wqAlertBar:SetHeight(24)
wqAlertBar:SetPoint("TOPLEFT", searchBar, "BOTTOMLEFT", 0, -3)
wqAlertBar:SetPoint("TOPRIGHT", searchBar, "BOTTOMRIGHT", 0, -3)
wqAlertBar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
wqAlertBar:SetBackdropColor(0.04, 0.16, 0.08, 0.95)
wqAlertBar:SetBackdropBorderColor(0.1, 0.9, 0.35, 0.9)
wqAlertBar:Hide()

local wqAlertIcon = wqAlertBar:CreateTexture(nil, "ARTWORK")
wqAlertIcon:SetSize(16, 16)
wqAlertIcon:SetPoint("LEFT", 6, 0)
wqAlertIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-WorldQuest-Tracker-Icon")
wqAlertIcon:SetVertexColor(0.2, 1.0, 0.4)

local wqAlertText = wqAlertBar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
wqAlertText:SetPoint("LEFT", wqAlertIcon, "RIGHT", 6, 0)
wqAlertText:SetPoint("RIGHT", -6, 0)
wqAlertText:SetJustifyH("LEFT")
wqAlertText:SetWordWrap(false)
wqAlertText:SetText("")

local wqAlertEntries = {}
local wqAlertAllEntries = {}

wqAlertBar:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    if wqAlertEntries and #wqAlertEntries > 0 then
        GameTooltip:AddLine("|cFF00FF00★ Active World Quests for Missing Requirements|r", 1, 1, 1)
        GameTooltip:AddLine("The following World Quests are currently UP and needed for this meta:", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ")
        for _, item in ipairs(wqAlertEntries) do
            local q = item.activeQuest
            local timeLeft = (q.timeLeftFormatted ~= "" and (" (" .. q.timeLeftFormatted .. ")")) or ""
            GameTooltip:AddLine("|cFFFFFFFF" .. item.achievementName .. "|r", 1, 0.82, 0)
            GameTooltip:AddLine("  • World Quest: |cFF00FF00" .. q.title .. "|r in |cFFFFD100" .. q.zoneName .. "|r" .. timeLeft, 0.9, 0.9, 0.9)
            if q.notes and q.notes ~= "" then
                GameTooltip:AddLine("    |cFFBBBBBB" .. q.notes .. "|r", 0.7, 0.7, 0.7, true)
            end
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFF00FF00Left-Click|r: Expand all sections to reveal active requirements", 0.7, 0.7, 0.7)
    elseif wqAlertAllEntries and #wqAlertAllEntries > 0 then
        GameTooltip:AddLine("|cFF00BFFF★ Overall Meta World Quest Requirements|r", 1, 1, 1)
        GameTooltip:AddLine("The following achievements in this meta require rotating World Quests:", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ")
        for _, item in ipairs(wqAlertAllEntries) do
            GameTooltip:AddLine("|cFFFFFFFF" .. item.achievementName .. "|r", 1, 0.82, 0)
            local statusStr = item.hasActive and "|cFF00FF00● UP NOW|r" or "|cFFFF5555Offline / Inactive|r"
            GameTooltip:AddLine("  • World Quest: |cFFFFD100" .. item.questName .. "|r in |cFFFFFFFF" .. (item.zoneName or "Unknown") .. "|r - " .. statusStr, 0.9, 0.9, 0.9)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFF00FF00Left-Click|r: Expand all sections to reveal World Quest requirements", 0.7, 0.7, 0.7)
    else
        return
    end
    GameTooltip:Show()
end)
wqAlertBar:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
wqAlertBar:SetScript("OnClick", function()
    if activeTree and activeTree.criteria then
        local function ExpandTargets(criteriaList)
            for _, item in ipairs(criteriaList) do
                if item.isSubAchievement and item.assetID then
                    if (item.worldQuestData) or item.hasChildActiveWQ or item.hasChildWQ then
                        expandedNodes[item.assetID] = true
                        if item.subTree and item.subTree.criteria then
                            ExpandTargets(item.subTree.criteria)
                        end
                    end
                end
            end
        end
        ExpandTargets(activeTree.criteria)
        MCT.RefreshDisplay()
    end
end)

---------------------------------------------------------------------------
-- 5. Meta Achievement Header Banner (Icon, Title, Reward, Progress)
---------------------------------------------------------------------------
local headerCard = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
headerCard:SetHeight(92)
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
metaReward:SetPoint("TOPLEFT", metaTitle, "BOTTOMLEFT", 0, -2)
metaReward:SetPoint("RIGHT", headerCard, "RIGHT", -10, 0)
metaReward:SetJustifyH("LEFT")
metaReward:SetText("")

-- Header Meta View / Part of Meta Indicator Button
local metaParentBtn = CreateFrame("Button", nil, headerCard, "BackdropTemplate")
metaParentBtn:SetHeight(18)
metaParentBtn:SetPoint("TOPLEFT", metaReward, "BOTTOMLEFT", 0, -2)
metaParentBtn:SetPoint("RIGHT", headerCard, "RIGHT", -10, 0)
metaParentBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
metaParentBtn:Hide()

local metaParentIcon = metaParentBtn:CreateTexture(nil, "ARTWORK")
metaParentIcon:SetSize(14, 14)
metaParentIcon:SetPoint("LEFT", 4, 0)
metaParentIcon:SetTexture("Interface\\Icons\\Achievement_General")
metaParentBtn.icon = metaParentIcon

local metaParentText = metaParentBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
metaParentText:SetPoint("LEFT", metaParentIcon, "RIGHT", 4, 0)
metaParentText:SetPoint("RIGHT", -4, 0)
metaParentText:SetJustifyH("LEFT")
metaParentBtn.text = metaParentText

metaParentBtn:SetScript("OnClick", function(self)
    if self.parentPresetID then
        local targetID = self.targetAchID
        MCT.SelectAchievement(self.parentPresetID)
        if targetID then
            expandedNodes[targetID] = true
            MCT.RefreshDisplay()
        end
    end
end)
metaParentBtn:SetScript("OnEnter", function(self)
    if self.parentPresetID then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("|cFF00FFCCPart of Overall Meta Achievement|r", 1, 1, 1)
        GameTooltip:AddLine("This achievement is a requirement for the overall meta view.", 0.8, 0.8, 0.8)
        if self.parentMetaPath then
            GameTooltip:AddLine("Hierarchy: |cFFFFD100" .. self.parentMetaPath .. "|r", 0.9, 0.9, 0.9)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFF00FF00Left-Click|r: Switch to overall meta view and reveal this achievement", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end
end)
metaParentBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Header World Quest Status Banner
local metaWQBtn = CreateFrame("Button", nil, headerCard, "BackdropTemplate")
metaWQBtn:SetHeight(18)
metaWQBtn:SetPoint("TOPLEFT", metaReward, "BOTTOMLEFT", 0, -2)
metaWQBtn:SetPoint("RIGHT", headerCard, "RIGHT", -10, 0)
metaWQBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
metaWQBtn:Hide()

local metaWQIcon = metaWQBtn:CreateTexture(nil, "ARTWORK")
metaWQIcon:SetSize(14, 14)
metaWQIcon:SetPoint("LEFT", 4, 0)
metaWQIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-WorldQuest-Tracker-Icon")
metaWQBtn.icon = metaWQIcon

local metaWQText = metaWQBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
metaWQText:SetPoint("LEFT", metaWQIcon, "RIGHT", 4, 0)
metaWQText:SetPoint("RIGHT", -4, 0)
metaWQText:SetJustifyH("LEFT")
metaWQBtn.text = metaWQText

metaWQBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
metaWQBtn:SetScript("OnEnter", function(self)
    local q = self.worldQuest
    if not q then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("|cFF00BFFFWorld Quest Requirement|r", 1, 1, 1)
    local statusStr = q.isActive and ("|cFF00FF00Active Now (" .. (q.timeLeftFormatted ~= "" and q.timeLeftFormatted or "Up") .. ")|r") or (q.isCompleted and "|cFF55AAFFCompleted Today|r" or "|cFFFF5555Offline / Inactive|r")
    GameTooltip:AddLine(q.title, 1, 0.82, 0)
    GameTooltip:AddLine("Zone: |cFFFFFFFF" .. (q.zoneName or "Unknown") .. "|r", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Status: " .. statusStr, 1, 1, 1)
    if q.notes and q.notes ~= "" then
        GameTooltip:AddLine(q.notes, 0.7, 0.7, 0.7, true)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFF00FF00Left-Click|r: View Zone on World Map", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cFF00FF00Right-Click|r: Copy Wowhead Quest Link", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cFF00FF00Shift-Click|r: Track World Quest in Objectives", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
metaWQBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
metaWQBtn:SetScript("OnClick", function(self, button)
    local q = self.worldQuest
    if not q then return end
    if button == "RightButton" then
        MCT.ShowWowheadURL({ questID = q.questID, title = q.title })
    elseif IsShiftKeyDown() then
        MCT.Engine.TrackWorldQuest(q.questID)
    else
        if q.mapID then
            MCT.Engine.OpenWorldQuestMap(q.mapID)
        end
    end
end)

-- Progress Bar
local progressBar = CreateFrame("StatusBar", nil, headerCard)
progressBar:SetHeight(16)
progressBar:SetPoint("BOTTOMLEFT", headerCard, "BOTTOMLEFT", 72, 8)
progressBar:SetPoint("BOTTOMRIGHT", headerCard, "BOTTOMRIGHT", -10, 8)
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
        chevron:SetScript("OnClick", function(self)
            local pRow = self:GetParent()
            if pRow and pRow.subID then
                expandedNodes[pRow.subID] = not expandedNodes[pRow.subID]
                MCT.RefreshDisplay()
            end
        end)
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
        progressLabel:SetPoint("RIGHT", row, "RIGHT", -30, 0)
        progressLabel:SetWidth(48)
        progressLabel:SetJustifyH("RIGHT")
        progressLabel:SetWordWrap(false)
        row.progressLabel = progressLabel

        -- World Quest Status Badge Button
        local wqBadge = CreateFrame("Button", nil, row, "BackdropTemplate")
        wqBadge:SetSize(86, 18)
        wqBadge:SetPoint("RIGHT", row, "RIGHT", -80, 0)
        wqBadge:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        local wqBadgeIcon = wqBadge:CreateTexture(nil, "ARTWORK")
        wqBadgeIcon:SetSize(12, 12)
        wqBadgeIcon:SetPoint("LEFT", 3, 0)
        wqBadgeIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-WorldQuest-Tracker-Icon")
        wqBadge.icon = wqBadgeIcon

        local wqBadgeText = wqBadge:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        wqBadgeText:SetPoint("LEFT", wqBadgeIcon, "RIGHT", 3, 0)
        wqBadgeText:SetPoint("RIGHT", -2, 0)
        wqBadgeText:SetJustifyH("LEFT")
        wqBadge.text = wqBadgeText
        row.wqBadge = wqBadge

        wqBadge:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        wqBadge:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.worldQuestData then
                -- Direct WQ requirement on this achievement
                GameTooltip:AddLine("|cFF00BFFFWorld Quest Requirement|r", 1, 1, 1)
                for _, q in ipairs(self.worldQuestData.quests) do
                    local statusStr = q.isActive and ("|cFF00FF00Active Now (" .. (q.timeLeftFormatted ~= "" and q.timeLeftFormatted or "Up") .. ")|r") or (q.isCompleted and "|cFF55AAFFCompleted Today|r" or "|cFFFF5555Offline / Inactive|r")
                    GameTooltip:AddLine("• |cFFFFFFFF" .. q.title .. "|r in |cFFFFD100" .. (q.zoneName or "Unknown") .. "|r", 1, 0.82, 0)
                    GameTooltip:AddLine("  Status: " .. statusStr, 1, 1, 1)
                    if q.notes and q.notes ~= "" then
                        GameTooltip:AddLine("  |cFFCCCCCC" .. q.notes .. "|r", 0.8, 0.8, 0.8, true)
                    end
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cFF00FF00Left-Click|r: View Zone on World Map", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("|cFF00FF00Right-Click|r: Copy Wowhead Quest Link", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("|cFF00FF00Shift-Click|r: Track World Quest in Objectives", 0.7, 0.7, 0.7)
            elseif self.childActiveWQs and #self.childActiveWQs > 0 then
                -- Parent category in overall meta containing active WQ!
                GameTooltip:AddLine("|cFF00FF00★ Active World Quest in this category!|r", 1, 1, 1)
                GameTooltip:AddLine("This meta requirement contains active World Quests:", 0.8, 0.8, 0.8)
                GameTooltip:AddLine(" ")
                for _, item in ipairs(self.childActiveWQs) do
                    local q = item.activeQuest
                    local t = (q.timeLeftFormatted ~= "" and (" (" .. q.timeLeftFormatted .. ")")) or ""
                    GameTooltip:AddLine("• |cFFFFD100" .. item.achievementName .. "|r: |cFF00FF00" .. q.title .. "|r in |cFFFFFFFF" .. q.zoneName .. "|r" .. t, 1, 1, 1)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cFF00FF00Click|r: Expand to view active requirements", 0.7, 0.7, 0.7)
            elseif self.childAllWQs and #self.childAllWQs > 0 then
                -- Parent category in overall meta with WQ requirements
                GameTooltip:AddLine("|cFF00BFFFWorld Quest Requirements in Category|r", 1, 1, 1)
                for _, item in ipairs(self.childAllWQs) do
                    GameTooltip:AddLine("• |cFFFFD100" .. item.achievementName .. "|r: " .. item.questName .. " (" .. item.zoneName .. ") - |cFFFF5555Offline|r", 0.8, 0.8, 0.8)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cFF00FF00Click|r: Expand category", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end)
        wqBadge:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        wqBadge:SetScript("OnClick", function(self, button)
            if self.worldQuestData then
                local q = self.worldQuestData.activeQuest or self.worldQuestData.firstQuest
                if not q then return end
                if button == "RightButton" then
                    MCT.ShowWowheadURL({ questID = q.questID, title = q.title })
                elseif IsShiftKeyDown() then
                    MCT.Engine.TrackWorldQuest(q.questID)
                else
                    if q.mapID then
                        MCT.Engine.OpenWorldQuestMap(q.mapID)
                    end
                end
            elseif (self.childActiveWQs and #self.childActiveWQs > 0) or (self.childAllWQs and #self.childAllWQs > 0) then
                if self.subData and self.subData.id then
                    expandedNodes[self.subData.id] = true
                    MCT.RefreshDisplay()
                end
            end
        end)

        -- Native Track Pin Button
        local trackBtn = CreateFrame("Button", nil, row)
        trackBtn:SetSize(22, 22)
        trackBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        local trackIcon = trackBtn:CreateTexture(nil, "ARTWORK")
        trackIcon:SetSize(16, 16)
        trackIcon:SetPoint("CENTER")
        trackIcon:SetTexture("Interface\\Icons\\INV_Misc_Map02")
        trackBtn.icon = trackIcon
        trackBtn:SetScript("OnClick", function(self)
            local pRow = self:GetParent()
            if pRow and pRow.subID then
                MCT.Engine.ToggleTrackAchievement(pRow.subID)
                MCT.RefreshDisplay()
            end
        end)
        row.trackBtn = trackBtn

        -- Tooltips
        row:SetScript("OnEnter", function(self)
            if self.data and self.data.id then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(GetAchievementLink(self.data.id) or ("achievement:" .. self.data.id))
                
                if self.wqBadge and self.wqBadge.worldQuestData then
                    local wq = self.wqBadge.worldQuestData
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cFF00BFFFWorld Quest Required:|r", 1, 1, 1)
                    for _, q in ipairs(wq.quests) do
                        local s = q.isActive and ("|cFF00FF00Active Now (" .. (q.timeLeftFormatted ~= "" and q.timeLeftFormatted or "Up") .. ")|r") or (q.isCompleted and "|cFF55AAFFCompleted Today|r" or "|cFFFF5555Offline / Inactive|r")
                        GameTooltip:AddLine("• |cFFFFFFFF" .. q.title .. "|r in |cFFFFD100" .. (q.zoneName or "Unknown") .. "|r - " .. s, 1, 1, 1)
                        if q.notes and q.notes ~= "" then
                            GameTooltip:AddLine("  |cFFCCCCCC" .. q.notes .. "|r", 0.8, 0.8, 0.8, true)
                        end
                    end
                elseif self.wqBadge and self.wqBadge.childActiveWQs and #self.wqBadge.childActiveWQs > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cFF00FF00★ Active World Quest in this category:|r", 1, 1, 1)
                    for _, item in ipairs(self.wqBadge.childActiveWQs) do
                        local q = item.activeQuest
                        local t = (q.timeLeftFormatted ~= "" and (" (" .. q.timeLeftFormatted .. ")")) or ""
                        GameTooltip:AddLine("• |cFFFFD100" .. item.achievementName .. "|r: |cFF00FF00" .. q.title .. "|r in |cFFFFFFFF" .. q.zoneName .. "|r" .. t, 1, 1, 1)
                    end
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cFF00FF00Click [★ WQ UP] badge|r: Expand to view active requirements", 0.7, 0.7, 0.7)
                end

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

                if self.wqBadge and self.wqBadge.worldQuestData then
                    local wq = self.wqBadge.worldQuestData
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cFF00BFFFWorld Quest Required:|r", 1, 1, 1)
                    for _, q in ipairs(wq.quests) do
                        local s = q.isActive and ("|cFF00FF00Active Now (" .. (q.timeLeftFormatted ~= "" and q.timeLeftFormatted or "Up") .. ")|r") or (q.isCompleted and "|cFF55AAFFCompleted Today|r" or "|cFFFF5555Offline / Inactive|r")
                        GameTooltip:AddLine("• |cFFFFFFFF" .. q.title .. "|r in |cFFFFD100" .. (q.zoneName or "Unknown") .. "|r - " .. s, 1, 1, 1)
                    end
                elseif self.parentID then
                    local pWq = MCT.Engine.GetAchievementWorldQuests and MCT.Engine.GetAchievementWorldQuests(self.parentID)
                    if pWq and pWq.firstQuest then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cFF00BFFFRequired from World Quest:|r " .. pWq.firstQuest.title .. " (" .. pWq.firstQuest.zoneName .. ")", 1, 0.82, 0)
                        local sStr = pWq.hasActive and ("|cFF00FF00Active Now (" .. (pWq.activeQuest.timeLeftFormatted ~= "" and pWq.activeQuest.timeLeftFormatted or "Up") .. ")|r") or "|cFFFF5555Offline / Inactive|r"
                        GameTooltip:AddLine("Status: " .. sStr, 1, 1, 1)
                        if pWq.firstQuest.notes and pWq.firstQuest.notes ~= "" then
                            GameTooltip:AddLine(pWq.firstQuest.notes, 0.7, 0.7, 0.7, true)
                        end
                    end
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
        row.parentID = nil
        row.subID = nil
        if row.wqBadge then
            row.wqBadge:Hide()
            row.wqBadge.worldQuestData = nil
            row.wqBadge.subData = nil
            row.wqBadge.childActiveWQs = nil
            row.wqBadge.childAllWQs = nil
        end
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
            row.subID = subData.id
            row.parentID = parentID

            local hasSubTree = item.subTree and item.subTree.criteria and #item.subTree.criteria > 0

            -- Chevron positioning
            row.chevron:ClearAllPoints()
            row.chevron:SetPoint("LEFT", row, "LEFT", leftOffset, 0)

            if hasSubTree then
                row.chevron:Show()
                local isExpanded = expandedNodes[subData.id] or false
                row.chevron.text:SetText(isExpanded and "|cFFFFD100[-]|r" or "|cFF00BFFF[+]|r")
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
            local nameColor = subData.completed and "|cFF888888" or "|cFFFFFFFF"
            row.nameText:SetText(nameColor .. (subData.name or ("Achievement #" .. subData.id)) .. "|r")

            -- World Quest Badge Check
            local wqData = item.worldQuestData
            if not wqData and item.isSubAchievement and item.subAchievementData then
                wqData = MCT.Engine.GetAchievementWorldQuests and MCT.Engine.GetAchievementWorldQuests(item.subAchievementData.id)
            end

            local hasChildActive = item.hasChildActiveWQ or (item.childActiveWQs and #item.childActiveWQs > 0)
            local hasChildWQ = item.hasChildWQ or (item.childAllWQs and #item.childAllWQs > 0)

            row.wqBadge.worldQuestData = wqData
            row.wqBadge.subData = subData
            row.wqBadge.childActiveWQs = item.childActiveWQs
            row.wqBadge.childAllWQs = item.childAllWQs

            if wqData and not subData.completed then
                row.wqBadge:Show()
                if wqData.hasActive and wqData.activeQuest then
                    local q = wqData.activeQuest
                    local timeStr = (q.timeLeftFormatted ~= "" and q.timeLeftFormatted) or "UP"
                    row.wqBadge.text:SetText("|cFF00FF00" .. timeStr .. "|r")
                    row.wqBadge:SetBackdropColor(0.04, 0.16, 0.08, 0.95)
                    row.wqBadge:SetBackdropBorderColor(0.1, 0.9, 0.35, 0.9)
                    row.wqBadge.icon:SetVertexColor(0.2, 1.0, 0.4)
                elseif wqData.hasCompleted then
                    row.wqBadge.text:SetText("|cFF55AAFFDone|r")
                    row.wqBadge:SetBackdropColor(0.06, 0.10, 0.16, 0.9)
                    row.wqBadge:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.7)
                    row.wqBadge.icon:SetVertexColor(0.3, 0.7, 1.0)
                else
                    local qName = wqData.firstQuest and wqData.firstQuest.title or "WQ"
                    if #qName > 8 then qName = qName:sub(1, 8) end
                    row.wqBadge.text:SetText("|cFFFFCC00" .. qName .. "|r")
                    row.wqBadge:SetBackdropColor(0.08, 0.08, 0.06, 0.85)
                    row.wqBadge:SetBackdropBorderColor(0.7, 0.6, 0.2, 0.6)
                    row.wqBadge.icon:SetVertexColor(0.9, 0.8, 0.2)
                end
                row.nameText:SetPoint("RIGHT", row, "RIGHT", -172, 0)
            elseif hasChildActive and not subData.completed then
                -- Parent category has active WQ among its children
                row.wqBadge:Show()
                local count = item.childActiveWQs and #item.childActiveWQs or 1
                row.wqBadge.text:SetText("|cFF00FF00★ WQ UP" .. (count > 1 and (" ("..count..")") or "") .. "|r")
                row.wqBadge:SetBackdropColor(0.04, 0.18, 0.08, 0.95)
                row.wqBadge:SetBackdropBorderColor(0.1, 1.0, 0.4, 0.95)
                row.wqBadge.icon:SetVertexColor(0.2, 1.0, 0.4)
                row.nameText:SetPoint("RIGHT", row, "RIGHT", -172, 0)
            elseif hasChildWQ and not subData.completed then
                -- Parent category in overall meta view has rotating WQs required
                row.wqBadge:Show()
                row.wqBadge.text:SetText("|cFF66B2FF[WQ Meta]|r")
                row.wqBadge:SetBackdropColor(0.06, 0.09, 0.14, 0.85)
                row.wqBadge:SetBackdropBorderColor(0.2, 0.4, 0.7, 0.7)
                row.wqBadge.icon:SetVertexColor(0.4, 0.7, 1.0)
                row.nameText:SetPoint("RIGHT", row, "RIGHT", -172, 0)
            else
                row.wqBadge:Hide()
                row.nameText:SetPoint("RIGHT", row, "RIGHT", -84, 0)
            end

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
            local textColor = item.completed and "|cFF888888" or "|cFFD0D0D0"
            row.nameText:SetText(textColor .. cName .. "|r")

            -- World Quest Badge Check for Criteria
            local parentWQ = parentID and MCT.Engine.GetAchievementWorldQuests and MCT.Engine.GetAchievementWorldQuests(parentID)
            local wqData = item.worldQuestData or parentWQ
            row.wqBadge.worldQuestData = wqData
            row.wqBadge.subData = nil
            row.wqBadge.childActiveWQs = nil
            row.wqBadge.childAllWQs = nil

            if wqData and not item.completed then
                row.wqBadge:Show()
                if wqData.hasActive and wqData.activeQuest then
                    local q = wqData.activeQuest
                    local timeStr = (q.timeLeftFormatted ~= "" and q.timeLeftFormatted) or "UP"
                    row.wqBadge.text:SetText("|cFF00FF00" .. timeStr .. "|r")
                    row.wqBadge:SetBackdropColor(0.04, 0.16, 0.08, 0.95)
                    row.wqBadge:SetBackdropBorderColor(0.1, 0.9, 0.35, 0.9)
                    row.wqBadge.icon:SetVertexColor(0.2, 1.0, 0.4)
                elseif wqData.hasCompleted then
                    row.wqBadge.text:SetText("|cFF55AAFFDone|r")
                    row.wqBadge:SetBackdropColor(0.06, 0.10, 0.16, 0.9)
                    row.wqBadge:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.7)
                    row.wqBadge.icon:SetVertexColor(0.3, 0.7, 1.0)
                else
                    row.wqBadge.text:SetText("|cFFFFCC00WQ Item|r")
                    row.wqBadge:SetBackdropColor(0.08, 0.08, 0.06, 0.85)
                    row.wqBadge:SetBackdropBorderColor(0.7, 0.6, 0.2, 0.6)
                    row.wqBadge.icon:SetVertexColor(0.9, 0.8, 0.2)
                end
                row.nameText:SetPoint("RIGHT", row, "RIGHT", -172, 0)
            else
                row.wqBadge:Hide()
                row.nameText:SetPoint("RIGHT", row, "RIGHT", -80, 0)
            end

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
    expandedNodes = {}
    allExpanded = false
    if toggleAllBtn then
        toggleAllBtn:SetText("Expand")
    end

    -- Update Expansion and Sub-Heading Navigation Highlights
    if MCT.Presets then
        for _, p in ipairs(MCT.Presets) do
            if p.id == achievementID and p.expansionKey then
                currentExpansionKey = p.expansionKey
                lastPresetByExpansion[p.expansionKey] = achievementID
                break
            end
        end
    end
    UpdatePresetNavigation(achievementID)

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

    local displayTitle = (metaData.isLoaded and metaData.name) or (activePreset and activePreset.name) or metaData.name or ("Achievement #" .. achievementID)
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

    -- Update World Quest Alert Bar and Header WQ Status
    local activeWQs = activeTree.activeWorldQuests or {}
    local allWQs = activeTree.allWorldQuests or {}
    wqAlertEntries = activeWQs
    wqAlertAllEntries = allWQs

    if #activeWQs > 0 then
        wqAlertBar:Show()
        wqAlertBar:SetBackdropColor(0.04, 0.18, 0.08, 0.95)
        wqAlertBar:SetBackdropBorderColor(0.1, 1.0, 0.4, 0.95)
        wqAlertIcon:SetVertexColor(0.2, 1.0, 0.4)
        headerCard:ClearAllPoints()
        headerCard:SetPoint("TOPLEFT", wqAlertBar, "BOTTOMLEFT", 0, -4)
        headerCard:SetPoint("TOPRIGHT", searchBar, "BOTTOMRIGHT", 0, -4)
        if #activeWQs == 1 then
            local q = activeWQs[1].activeQuest
            local timeStr = (q.timeLeftFormatted ~= "" and (" (" .. q.timeLeftFormatted .. ")")) or ""
            wqAlertText:SetText("|cFF00FF00★ ACTIVE WQ AVAILABLE:|r |cFFFFFFFF" .. q.title .. "|r in |cFFFFD100" .. q.zoneName .. "|r" .. timeStr .. " |cFF33CCFF[Click to Expand]|r")
        else
            wqAlertText:SetText("|cFF00FF00★ " .. #activeWQs .. " World Quests are UP for missing requirements!|r |cFF33CCFF[Click to Expand]|r")
        end
    elseif #allWQs > 0 then
        -- Meta has rotating WQs required, show informative banner even if currently offline
        wqAlertBar:Show()
        wqAlertBar:SetBackdropColor(0.06, 0.09, 0.14, 0.95)
        wqAlertBar:SetBackdropBorderColor(0.2, 0.45, 0.75, 0.8)
        wqAlertIcon:SetVertexColor(0.4, 0.7, 1.0)
        wqAlertText:SetText("|cFF00BFFF★ Overall Meta WQ Requirements:|r |cFFFFFFFF" .. #allWQs .. " achievements require rotating World Quests|r |cFF88AAFF[Click to Reveal]|r")
        headerCard:ClearAllPoints()
        headerCard:SetPoint("TOPLEFT", wqAlertBar, "BOTTOMLEFT", 0, -4)
        headerCard:SetPoint("TOPRIGHT", searchBar, "BOTTOMRIGHT", 0, -4)
    else
        wqAlertBar:Hide()
        headerCard:ClearAllPoints()
        headerCard:SetPoint("TOPLEFT", searchBar, "BOTTOMLEFT", 0, -6)
        headerCard:SetPoint("TOPRIGHT", searchBar, "BOTTOMRIGHT", 0, -6)
    end

    -- Update Parent Meta Indicator (Is this achievement part of an overall meta?)
    local parentMeta = MCT.Engine.GetParentMetaForAchievement and MCT.Engine.GetParentMetaForAchievement(achievementID)
    if parentMeta and parentMeta.presetID ~= achievementID and (not activePreset or activePreset.category ~= "Expansion Super-Meta") then
        metaParentBtn:Show()
        metaParentBtn.parentPresetID = parentMeta.presetID
        metaParentBtn.targetAchID = achievementID
        metaParentBtn.parentMetaPath = parentMeta.path
        metaParentBtn.text:SetText("|cFF00FFCC★ Part of Overall Meta:|r " .. parentMeta.shortName .. " - " .. parentMeta.presetName .. " |cFF33CCFF[View in Meta]|r")
        metaParentBtn:SetBackdropColor(0.06, 0.12, 0.18, 0.9)
        metaParentBtn:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.8)
        metaParentIcon:SetVertexColor(0.3, 0.8, 1.0)
    else
        metaParentBtn:Hide()
        metaParentBtn.parentPresetID = nil
        metaParentBtn.targetAchID = nil
        metaParentBtn.parentMetaPath = nil
    end

    -- Update Header World Quest Button if current meta achievement has a World Quest
    if activeTree.worldQuestData and activeTree.worldQuestData.firstQuest then
        local q = activeTree.worldQuestData.activeQuest or activeTree.worldQuestData.firstQuest
        metaWQBtn:Show()
        metaWQBtn.worldQuest = q
        metaWQBtn:ClearAllPoints()
        if metaParentBtn:IsShown() then
            metaWQBtn:SetPoint("TOPLEFT", metaParentBtn, "BOTTOMLEFT", 0, -3)
        else
            metaWQBtn:SetPoint("TOPLEFT", metaReward, "BOTTOMLEFT", 0, -3)
        end
        metaWQBtn:SetPoint("RIGHT", headerCard, "RIGHT", -10, 0)

        if q.isActive then
            metaWQBtn.text:SetText("|cFF00BFFFWorld Quest:|r |cFFFFFFFF" .. q.title .. "|r - |cFF00FF00● UP (" .. (q.timeLeftFormatted ~= "" and q.timeLeftFormatted or "Active") .. ")|r [|cFFFFD100" .. q.zoneName .. "|r]")
            metaWQBtn:SetBackdropColor(0.04, 0.16, 0.08, 0.9)
            metaWQBtn:SetBackdropBorderColor(0.1, 0.9, 0.3, 0.9)
            metaWQBtn.icon:SetVertexColor(0.1, 1.0, 0.3)
        elseif q.isCompleted then
            metaWQBtn.text:SetText("|cFF00BFFFWorld Quest:|r |cFFFFFFFF" .. q.title .. "|r - |cFF55AAFFCompleted Today|r [|cFFFFD100" .. q.zoneName .. "|r]")
            metaWQBtn:SetBackdropColor(0.06, 0.10, 0.16, 0.9)
            metaWQBtn:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.7)
            metaWQBtn.icon:SetVertexColor(0.3, 0.7, 1.0)
        else
            metaWQBtn.text:SetText("|cFF00BFFFWorld Quest:|r |cFFFFFFFF" .. q.title .. "|r - |cFFFF5555Offline / Inactive|r [|cFFFFD100" .. q.zoneName .. "|r]")
            metaWQBtn:SetBackdropColor(0.08, 0.08, 0.10, 0.7)
            metaWQBtn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.5)
            metaWQBtn.icon:SetVertexColor(0.5, 0.5, 0.5)
        end
    else
        metaWQBtn:Hide()
        metaWQBtn.worldQuest = nil
    end

    -- Adjust headerCard height based on visible banner buttons
    if metaWQBtn:IsShown() and metaParentBtn:IsShown() then
        headerCard:SetHeight(116)
    elseif metaWQBtn:IsShown() or metaParentBtn:IsShown() then
        headerCard:SetHeight(96)
    else
        headerCard:SetHeight(78)
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
eventFrame:RegisterEvent("ACHIEVEMENT_EARNED")
eventFrame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
eventFrame:RegisterEvent("TRACKED_ACHIEVEMENT_LIST_CHANGED")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("TASK_PROGRESS_UPDATE")
eventFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")

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
                
                -- Refresh alerts
                local activeWQs = activeTree.activeWorldQuests or {}
                local allWQs = activeTree.allWorldQuests or {}
                wqAlertEntries = activeWQs
                wqAlertAllEntries = allWQs
                if #activeWQs > 0 or #allWQs > 0 then
                    wqAlertBar:Show()
                    headerCard:ClearAllPoints()
                    headerCard:SetPoint("TOPLEFT", wqAlertBar, "BOTTOMLEFT", 0, -4)
                    headerCard:SetPoint("TOPRIGHT", searchBar, "BOTTOMRIGHT", 0, -4)
                else
                    wqAlertBar:Hide()
                    headerCard:ClearAllPoints()
                    headerCard:SetPoint("TOPLEFT", searchBar, "BOTTOMLEFT", 0, -6)
                    headerCard:SetPoint("TOPRIGHT", searchBar, "BOTTOMRIGHT", 0, -6)
                end

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

        print("|cFF00A6FFMetaCompletionTracker|r v" .. addonVersion .. " loaded. Type |cFF00FF00/mct|r to toggle.")

    elseif event == "CRITERIA_UPDATE" or event == "ACHIEVEMENT_SEARCH_UPDATED" or event == "ACHIEVEMENT_EARNED" or event == "QUEST_DATA_LOAD_RESULT" or event == "TRACKED_ACHIEVEMENT_LIST_CHANGED" or event == "QUEST_LOG_UPDATE" or event == "TASK_PROGRESS_UPDATE" or event == "QUEST_WATCH_LIST_CHANGED" then
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
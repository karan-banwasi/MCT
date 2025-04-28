-- Create a frame to display the output
local frame = CreateFrame("Frame", "TSOutputFrame", UIParent, "BackdropTemplate")
frame:SetSize(400, 600)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

-- Create a scrollable text area
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(380, 560)
scrollFrame:SetPoint("TOP", 0, -10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(380, 560)
scrollFrame:SetScrollChild(content)

local text = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
text:SetPoint("TOPLEFT")
text:SetPoint("TOPRIGHT")
text:SetJustifyH("LEFT")
text:SetJustifyV("TOP")
text:SetText("")
text:SetWidth(380)

-- Create a close button
local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
closeButton:SetSize(80, 20) -- Size of the close button
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10) -- Position it at the top-right corner
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
    frame:Hide()  -- Hide the frame when clicked
end)

local function AchievementCriteria(achievementID, parentID)
    local numCriteria = GetAchievementNumCriteria(achievementID)
    print("Parent: ", parentID,  " - Ach ID:", achievementID or "None")
    
    if numCriteria == 0 then
        print("This achievement has no criteria.")
        return
    end

    -- print("Criteria for Achievement ID:", achievementID)

    for i = 1, numCriteria do
        -- Get information about each criterion
        local criteriaString, criteriaType, completed, quantity, reqQuantity, _, _, assetID, quantityString = GetAchievementCriteriaInfo(achievementID, i)
        
        -- Print the details
        -- print(string.format("Criterion %d:", i))
        -- print(" - Name:", criteriaString or "None")
        -- print(" - Type:", criteriaType)
        -- print(" - Completed:", completed and "Yes" or "No")
        -- print(" - Progress:", quantity, "/", reqQuantity)
        -- print(" - Quantity String:", quantityString or "None")
        -- print(" - Asset ID:", assetID or "None")
        if criteriaType == 8 then
            AchievementCriteria(assetID, achievementID)
        end
        
    end
end

local function IsWorldQuestActive(questID)
    if not C_QuestLog.IsQuestFlaggedCompleted(questID) then
        local isOnQuest = C_QuestLog.IsOnQuest(questID)
        local isQuestAvailable = C_TaskQuest.IsActive(questID)
        
        if isOnQuest or isQuestAvailable then
            return true  -- The world quest is currently active
        end
    end
    return false  -- The world quest is not active
end

-- Define the function to show the achievements
local function ShowAchievements(msg, editbox)
    if msg == "bfa" then
        print("test")
        local faction = UnitFactionGroup("player")
        local allianceList = {13286,13287,13288,12087,13049,13062,13053,13082,12473,12497,12496,12582,12997,13251,13553,13710,13133,13925}
        local hordeList = {13289,13290,13291,12614,13020,13038,13022,13021,11861,11868,12478,12719,13700,13709,12555,13135,13009,13017,13437,13924,12873}
        local bothList = {12521,12522,12523,13414,13718,13719,13725,14193,14194,14195,14196,12505,12501,12484,12832,12837,12825,12841,12845,12944,12851,12482,13036,13029,12939,12852,13050,13057,13061,13058,12942,12771,13024,13023,12588,13028,12940,13047,13046,13051,13045,12853,12943,12849,13016,13018,13011,12941,12995,13087,13083,13064,13094,12556,12557,12558,12559,12561,12560,13144,14157,12947,13122,13101,13126,13127,13124,13128,13132,13121,12595,13517,13141}
        local a = bothList;
        if faction == "Horde" then
            for i = 1, #hordeList do
                a[#a + 1] = hordeList[i]
            end
        elseif faction == "Alliance" then
            for i = 1, #allianceList do
                a[#a + 1] = allianceList[i]
            end
        end
        local output = ""
        local allComplete = true
        local lastYPos = 20
        for i = 1, #a do
            local id, name, _, completed = GetAchievementInfo(a[i])
            if not completed then
                allComplete = false
                -- Create a clickable achievement name
                local achievementText = "|cFF1E90FF" .. name .. "|r"
                -- Add a script to open the achievement window when clicked
                local clickableAchievement = CreateFrame("Button", nil, content)
                clickableAchievement:SetPoint("TOPLEFT", 0, -lastYPos)
                clickableAchievement:SetSize(380, 20)
                clickableAchievement:SetText(achievementText)
                clickableAchievement:SetNormalFontObject("GameFontNormal")
                clickableAchievement:SetScript("OnClick", function()
                    -- Ensure the Achievement UI is loaded before selecting the achievement
                    if not AchievementFrame then
                        AchievementFrame_LoadUI()  -- Load the AchievementFrame UI if it's not loaded
                    end
                    AchievementFrame:Show()  -- Show the Achievement Frame
                    AchievementFrame_SelectAchievement(id)  -- Correct method to open achievement by ID
                end)
                lastYPos = lastYPos + 20
            else
                
            end
        end
        if allComplete then
            output = "You are All Done! YAY"
        else
            output = "You are missing the following achievements" 
        end
        text:SetText(output)
        frame:Show()
    else
        local wqlist = {51173}
        local questID = 0
        for i = 1, #wqlist do
            questID = wqlist[i]
            if IsWorldQuestActive(questID) then
                print("The world quest is currently active! " .. questID)
            else
                print("The world quest is not active." .. questID)
            end
        end

        
        -- World Awoken
        -- local achievementID = 16490
        -- Uldir  Glory
        -- local achievementID = 12806
        -- AchievementCriteria(achievementID, 0)
    end    
end

-- Define the function to hide the frame
local function HideFrame()
    frame:Hide()
end




-- Slash commands to run the functions
SLASH_MCT1 = "/mct" -- Show achievements
SlashCmdList["MCT"] = ShowAchievements

-- Register the hide frame slash command
SLASH_HIDEMCT1 = "/hidemct" -- Hide the frame
SlashCmdList["HIDEMCT"] = function()
    HideFrame()
end
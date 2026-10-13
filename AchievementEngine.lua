-- AchievementEngine.lua: Data extraction and recursive criteria walker for MCT
local addonName, MCT = ...

MCT.Engine = MCT.Engine or {}

---------------------------------------------------------------------------
-- Parent Meta Lookup Registry
---------------------------------------------------------------------------
MCT.AchievementParentMeta = MCT.AchievementParentMeta or {}

-- Pre-seed known major sub-achievements for quick instant lookup
local knownMetaParents = {
    -- Battle for Azeroth: A Farewell to Arms (40953)
    [40953] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth" },
    [12988] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "I'm On Island Time" },
    [13025] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "Hot Tropic" },
    [13026] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "Sound Off" },
    [13028] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "Songs of Storms" },
    [13027] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "Dune Squad" },
    [13009] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "I'm On Island Time > Dune Squad" },
    [13437] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "I'm On Island Time > Dune Squad" },
    [13017] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "I'm On Island Time > Songs of Storms" },
    [13010] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "I'm On Island Time > Sound Off" },
    [13013] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "I'm On Island Time" },
    [13029] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "War Stories" },
    [13541] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "Mecha-Done" },
    [13638] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "Undersea Usurper" },
    [13517] = { presetID = 40953, presetName = "Battle for Azeroth: A Farewell to Arms", shortName = "BfA", expansion = "Battle for Azeroth", path = "Two Sides to Every Tale" },
    
    -- Mecha-Done sub-achievements (13541)
    [13554] = { presetID = 13541, presetName = "Mecha-Done", shortName = "Mecha", expansion = "Battle for Azeroth" },
    [13545] = { presetID = 13638, presetName = "Undersea Usurper", shortName = "Nazjatar", expansion = "Battle for Azeroth" },
    [13691] = { presetID = 13638, presetName = "Undersea Usurper", shortName = "Nazjatar", expansion = "Battle for Azeroth" },
    [13699] = { presetID = 13638, presetName = "Undersea Usurper", shortName = "Nazjatar", expansion = "Battle for Azeroth" },

    -- Dragonflight: A World Awoken (19458)
    [19458] = { presetID = 19458, presetName = "Dragonflight: A World Awoken", shortName = "DF", expansion = "Dragonflight" },
    [16588] = { presetID = 19458, presetName = "Dragonflight: A World Awoken", shortName = "DF", expansion = "Dragonflight" },
    [16493] = { presetID = 19458, presetName = "Dragonflight: A World Awoken", shortName = "DF", expansion = "Dragonflight" },
    
    -- Shadowlands: Back from the Beyond (20501)
    [20501] = { presetID = 20501, presetName = "Shadowlands: Back from the Beyond", shortName = "SL", expansion = "Shadowlands" },

    -- Midnight
    [62386] = { presetID = 62386, presetName = "Midnight: Light Up the Night", shortName = "MID", expansion = "Midnight" },
    [63630] = { presetID = 63630, presetName = "Assault the Vault", shortName = "Vault", expansion = "Midnight" },
    [64150] = { presetID = 64150, presetName = "Bane of the Swarm", shortName = "Aqir", expansion = "Midnight" },
}

for k, v in pairs(knownMetaParents) do
    MCT.AchievementParentMeta[k] = v
end

function MCT.Engine.GetParentMetaForAchievement(achievementID)
    if not achievementID or type(achievementID) ~= "number" then return nil end
    return MCT.AchievementParentMeta[achievementID]
end

---------------------------------------------------------------------------
-- Main Engine Functions
---------------------------------------------------------------------------
-- Cache for achievement meta-data
local achievementCache = {}

-- Safe retrieval of achievement info with fallback defaults
function MCT.Engine.GetAchievementData(achievementID)
    if not achievementID then
        return nil
    end
    if type(achievementID) == "number" and achievementID <= 0 then
        return nil
    end

    if MCT.Presets then
        for _, p in ipairs(MCT.Presets) do
            if p.id == achievementID and p.achievements then
                return {
                    id = achievementID,
                    name = p.name,
                    points = 0,
                    completed = false,
                    wasEarnedByMe = false,
                    description = p.description or "",
                    icon = p.icon or 5342938,
                    rewardText = p.reward or "",
                    isLoaded = true,
                }
            end
        end
    end

    if type(achievementID) ~= "number" then
        return nil
    end

    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementID)
    
    if not id or not name or name == "" then
        -- Return temporary fallback while client requests data from server
        return {
            id = achievementID,
            name = "Achievement #" .. tostring(achievementID),
            points = 0,
            completed = false,
            wasEarnedByMe = false,
            description = "Loading achievement details...",
            icon = 134400, -- Default question mark
            rewardText = "",
            isLoaded = false,
        }
    end

    -- Query modern reward item if available
    local rewardItemID = nil
    if C_AchievementInfo and C_AchievementInfo.GetRewardItemID then
        rewardItemID = C_AchievementInfo.GetRewardItemID(achievementID)
    end

    local data = {
        id = id,
        name = name,
        points = points or 0,
        completed = completed or false,
        wasEarnedByMe = wasEarnedByMe or false,
        earnedBy = earnedBy,
        description = description or "",
        icon = icon or 134400,
        rewardText = rewardText or "",
        rewardItemID = rewardItemID,
        isLoaded = true,
    }

    achievementCache[achievementID] = data
    return data
end

-- Get criteria tree recursively for a meta-achievement
-- maxDepth: default 5 to support deep hierarchies (Mega Meta -> Zone Meta -> Sub Meta -> Achievement -> Criteria)
function MCT.Engine.GetCriteriaTree(achievementID, maxDepth, currentDepth, visited, rootMetaPreset)
    currentDepth = currentDepth or 1
    maxDepth = maxDepth or 5
    visited = visited or {}

    if visited[achievementID] then
        return nil
    end

    if not rootMetaPreset and MCT.Presets then
        for _, p in ipairs(MCT.Presets) do
            if p.id == achievementID then
                rootMetaPreset = p
                break
            end
        end
    end

    local customPreset = nil
    if MCT.Presets then
        for _, p in ipairs(MCT.Presets) do
            if p.id == achievementID and p.achievements then
                customPreset = p
                break
            end
        end
    end

    if customPreset then
        local tree = {
            id = achievementID,
            data = MCT.Engine.GetAchievementData(achievementID),
            criteria = {},
            totalCriteria = #customPreset.achievements,
            completedCriteria = 0,
            percent = 0,
        }

        for i, subAchID in ipairs(customPreset.achievements) do
            local subData = MCT.Engine.GetAchievementData(subAchID)
            local isSubComplete = (subData and subData.completed) or false
            if isSubComplete then
                tree.completedCriteria = tree.completedCriteria + 1
            end

            if rootMetaPreset and subAchID then
                MCT.AchievementParentMeta[subAchID] = MCT.AchievementParentMeta[subAchID] or {
                    presetID = rootMetaPreset.id,
                    presetName = rootMetaPreset.name,
                    shortName = rootMetaPreset.shortName or rootMetaPreset.name,
                    expansion = rootMetaPreset.expansion,
                }
            end

            local nextVisited = {}
            for k, v in pairs(visited) do nextVisited[k] = v end
            nextVisited[achievementID] = true

            local subTree = nil
            if currentDepth < maxDepth then
                subTree = MCT.Engine.GetCriteriaTree(subAchID, maxDepth, currentDepth + 1, nextVisited, rootMetaPreset)
            end

            local wqData = MCT.Engine.GetAchievementWorldQuests(subAchID)
            local childActiveWQs = (subTree and subTree.activeWorldQuests) or {}
            local childAllWQs = (subTree and subTree.allWorldQuests) or {}

            local item = {
                index = i,
                criteriaID = subAchID,
                criteriaString = (subData and subData.name) or ("Achievement #" .. tostring(subAchID)),
                criteriaType = 8,
                completed = isSubComplete,
                quantity = isSubComplete and 1 or 0,
                reqQuantity = 1,
                assetID = subAchID,
                depth = currentDepth,
                isSubAchievement = true,
                subAchievementData = subData,
                subTree = subTree,
                worldQuestData = wqData,
                hasChildActiveWQ = (#childActiveWQs > 0),
                childActiveWQs = childActiveWQs,
                hasChildWQ = (#childAllWQs > 0),
                childAllWQs = childAllWQs,
            }

            table.insert(tree.criteria, item)
        end

        if tree.totalCriteria > 0 then
            tree.percent = math.floor((tree.completedCriteria / tree.totalCriteria) * 100)
        else
            tree.percent = 0
        end

        if tree.data then
            tree.data.completed = (tree.totalCriteria > 0 and tree.completedCriteria == tree.totalCriteria)
        end

        tree.worldQuestData = MCT.Engine.GetAchievementWorldQuests(achievementID)
        tree.activeWorldQuests = MCT.Engine.FindActiveWorldQuestsInTree(tree)
        tree.allWorldQuests = MCT.Engine.FindAllWorldQuestsInTree(tree)

        return tree
    end

    local achData = MCT.Engine.GetAchievementData(achievementID)
    if not achData then
        return nil
    end

    local tree = {
        id = achievementID,
        data = achData,
        criteria = {},
        totalCriteria = 0,
        completedCriteria = 0,
        percent = 0,
    }

    local numCriteria = GetAchievementNumCriteria(achievementID) or 0
    tree.totalCriteria = numCriteria

    for i = 1, numCriteria do
        local criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID, quantityString, criteriaID = GetAchievementCriteriaInfo(achievementID, i)
        
        local item = {
            index = i,
            criteriaID = criteriaID,
            criteriaString = criteriaString or "",
            criteriaType = criteriaType,
            completed = completed or false,
            quantity = quantity or 0,
            reqQuantity = reqQuantity or 0,
            quantityString = quantityString or "",
            assetID = assetID,
            depth = currentDepth,
        }

        -- criteriaType == 8 indicates the requirement is another achievement!
        if criteriaType == 8 and assetID and assetID > 0 then
            item.isSubAchievement = true
            item.subAchievementData = MCT.Engine.GetAchievementData(assetID)
            item.worldQuestData = MCT.Engine.GetAchievementWorldQuests(assetID)

            -- Keep item.completed and subAchievementData.completed in sync
            if item.subAchievementData and item.subAchievementData.completed then
                item.completed = true
            elseif item.completed and item.subAchievementData then
                item.subAchievementData.completed = true
            end

            if rootMetaPreset and assetID then
                MCT.AchievementParentMeta[assetID] = MCT.AchievementParentMeta[assetID] or {
                    presetID = rootMetaPreset.id,
                    presetName = rootMetaPreset.name,
                    shortName = rootMetaPreset.shortName or rootMetaPreset.name,
                    expansion = rootMetaPreset.expansion,
                }
            end
            
            -- If sub-achievement has criteria and depth permits, query its sub-tree
            if currentDepth < maxDepth then
                local subNumCriteria = GetAchievementNumCriteria(assetID) or 0
                if subNumCriteria > 0 then
                    local nextVisited = {}
                    for k, v in pairs(visited) do nextVisited[k] = v end
                    nextVisited[achievementID] = true
                    item.subTree = MCT.Engine.GetCriteriaTree(assetID, maxDepth, currentDepth + 1, nextVisited, rootMetaPreset)
                end
            end

            local childActiveWQs = (item.subTree and item.subTree.activeWorldQuests) or {}
            local childAllWQs = (item.subTree and item.subTree.allWorldQuests) or {}
            item.hasChildActiveWQ = (#childActiveWQs > 0)
            item.childActiveWQs = childActiveWQs
            item.hasChildWQ = (#childAllWQs > 0)
            item.childAllWQs = childAllWQs
        else
            item.isSubAchievement = false
            -- If criteria is a direct quest requirement or mapped
            if criteriaType == 27 and assetID and assetID > 0 then
                local qInfo = MCT.Engine.GetWorldQuestInfo(assetID)
                if qInfo then
                    item.worldQuestData = {
                        achievementID = achievementID,
                        quests = { qInfo },
                        hasActive = qInfo.isActive,
                        hasCompleted = qInfo.isCompleted,
                        activeQuest = qInfo.isActive and qInfo or nil,
                        firstQuest = qInfo,
                    }
                end
            end
        end

        if item.completed then
            tree.completedCriteria = tree.completedCriteria + 1
        end

        table.insert(tree.criteria, item)
    end

    if tree.totalCriteria > 0 then
        tree.percent = math.floor((tree.completedCriteria / tree.totalCriteria) * 100)
    else
        tree.percent = achData.completed and 100 or 0
    end

    tree.worldQuestData = MCT.Engine.GetAchievementWorldQuests(achievementID)
    tree.activeWorldQuests = MCT.Engine.FindActiveWorldQuestsInTree(tree)
    tree.allWorldQuests = MCT.Engine.FindAllWorldQuestsInTree(tree)

    return tree
end

-- Check if an achievement is tracked in native Objective Tracker
function MCT.Engine.IsTracked(achievementID)
    if not achievementID or type(achievementID) ~= "number" then return false end

    -- Modern Retail Content Tracking API
    if C_ContentTracking and C_ContentTracking.GetTrackedIDs and Enum and Enum.ContentTrackingType then
        local trackedIDs = C_ContentTracking.GetTrackedIDs(Enum.ContentTrackingType.Achievement)
        if trackedIDs then
            for _, id in ipairs(trackedIDs) do
                if id == achievementID then
                    return true
                end
            end
        end
        return false
    end

    -- Fallback for older APIs
    if IsTrackedAchievement then
        return IsTrackedAchievement(achievementID)
    end

    return false
end

-- Toggle native Objective Tracker tracking for an achievement
function MCT.Engine.ToggleTrackAchievement(achievementID)
    if not achievementID or type(achievementID) ~= "number" then return end

    local isTracked = MCT.Engine.IsTracked(achievementID)

    if C_ContentTracking and C_ContentTracking.StartTracking and Enum and Enum.ContentTrackingType then
        if isTracked then
            local stopType = (Enum and Enum.ContentTrackingStopType and Enum.ContentTrackingStopType.Manual) or 2
            C_ContentTracking.StopTracking(Enum.ContentTrackingType.Achievement, achievementID, stopType)
            print("|cFF00A6FFMCT:|r Untracked: " .. (GetAchievementLink(achievementID) or ("Achievement #" .. achievementID)))
        else
            C_ContentTracking.StartTracking(Enum.ContentTrackingType.Achievement, achievementID)
            print("|cFF00A6FFMCT:|r Now tracking: " .. (GetAchievementLink(achievementID) or ("Achievement #" .. achievementID)))
        end
        return
    end

    -- Fallback
    if isTracked and RemoveTrackedAchievement then
        RemoveTrackedAchievement(achievementID)
    elseif AddTrackedAchievement then
        AddTrackedAchievement(achievementID)
    end
end

-- Open achievement in native Blizzard UI safely
function MCT.Engine.OpenAchievement(achievementID)
    if not achievementID or type(achievementID) ~= "number" or achievementID <= 0 then return end

    -- Verify achievement exists in client database before opening to prevent Blizzard UI nil category error
    local id, name = GetAchievementInfo(achievementID)
    if not id or not name or name == "" then
        print("|cFF00A6FFMCT:|r Achievement #" .. achievementID .. " is not available in the current client database.")
        return
    end

    -- Modern Retail standard utility function
    if OpenAchievementFrameToAchievement then
        OpenAchievementFrameToAchievement(achievementID)
        return
    end

    -- Fallback
    if not AchievementFrame then
        if C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_AchievementUI")
        elseif AchievementFrame_LoadUI then
            AchievementFrame_LoadUI()
        end
    end

    if AchievementFrame then
        AchievementFrame:Show()
        if AchievementFrame_SelectAchievement then
            AchievementFrame_SelectAchievement(achievementID)
        end
    end
end

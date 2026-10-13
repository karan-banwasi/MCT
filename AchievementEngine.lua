-- AchievementEngine.lua: Data extraction and recursive criteria walker for MCT
local addonName, MCT = ...

MCT.Engine = MCT.Engine or {}

---------------------------------------------------------------------------
-- World Quest Registry (Embedded to guarantee availability on /reload)
---------------------------------------------------------------------------
MCT.WorldQuests = MCT.WorldQuests or {
    -- [AchievementID] = { { questID = number, altQuestIDs = { number }, name = string, zone = string, mapID = number, notes = string }, ... }

    -----------------------------------------------------------------------
    -- Battle for Azeroth
    -----------------------------------------------------------------------
    [13009] = { -- Adept Sandfisher
        {
            questID = 51173,
            name = "Sandfishing",
            zone = "Vol'dun",
            mapID = 864,
            notes = "Summon sandworms using the Sandfishing Pole in Vol'dun. Manually loot the 5 specific Sandworm Scales (Cobalt, Silver, Emerald, Ruby, Onyx). Turn off auto-loot and DO NOT finish quest objective fangs until all 5 scales are collected!",
        }
    },
    [13437] = { -- Scavenge like a Vulpera
        {
            questID = 51635,
            altQuestIDs = { 51636 },
            name = "Vulpera for a Day",
            zone = "Vol'dun",
            mapID = 864,
            notes = "Speak to the NPC to receive the Vulpera disguise buff, then complete any Archaeology digsite in Vol'dun while the buff is active.",
        }
    },
    [13017] = { -- Sabertron Assemble
        {
            questID = 51978,
            altQuestIDs = { 51979, 51980, 51981, 51982 },
            name = "Sabertron",
            zone = "Stormsong Valley",
            mapID = 942,
            notes = "Defeat all 5 color variants of Sabertron. Yellow, Green, Orange, and Copper only spawn when this World Quest is active (the color is random per spawn). Red is available when inactive.",
        }
    },
    [13010] = { -- Shroom With a View
        {
            questID = 50444,
            name = "Fungal Frenzy",
            zone = "Tiragarde Sound",
            mapID = 895,
            notes = "Bounce on the required giant mushrooms during the World Quest in Tiragarde Sound.",
        }
    },
    [13013] = { -- Bow to the Loa
        {
            questID = 50810,
            altQuestIDs = { 50811, 50812, 50813, 50814 },
            name = "Loa Blessings / Offerings",
            zone = "Nazmir",
            mapID = 863,
            notes = "Visit and pay tribute to each Loa shrine across Nazmir during relevant daily / world quest offerings.",
        }
    },

    -----------------------------------------------------------------------
    -- Nazjatar (Undersea Usurper)
    -----------------------------------------------------------------------
    [13545] = { -- Puzzle Performer
        {
            questID = 56170,
            altQuestIDs = { 56171, 56172, 56173, 56174 },
            name = "Runelocked / Leylocked Chest",
            zone = "Nazjatar",
            mapID = 1355,
            notes = "Solve the rotating Runelocked and Leylocked Chest puzzle World Quests across Nazjatar.",
        }
    },
    [13691] = { -- Aqua Team Murder Force
        {
            questID = 56501,
            altQuestIDs = { 56502, 56503 },
            name = "Summoning from the Depths",
            zone = "Nazjatar",
            mapID = 1355,
            notes = "Defeat the abyssal champions summoned during the Summoning from the Depths World Quest event.",
        }
    },
    [13699] = { -- Periodic Destruction
        {
            questID = 56116,
            altQuestIDs = { 56117 },
            name = "Mardivas's Laboratory",
            zone = "Nazjatar",
            mapID = 1355,
            notes = "Summon and defeat all 13 elemental creations in Mardivas's Laboratory using rotating weekly arcano-elemental reagents.",
        }
    },

    -----------------------------------------------------------------------
    -- Mechagon (Mecha-Done)
    -----------------------------------------------------------------------
    [13470] = { -- Outside Influences
        {
            questID = 55760,
            altQuestIDs = { 55761, 55762, 55763, 55764, 55765, 55766, 55767 },
            name = "Mechagon Daily Visitors",
            zone = "Mechagon",
            mapID = 1462,
            notes = "Complete quests for rotating daily visitors in Rustbolt.",
        }
    },

    -----------------------------------------------------------------------
    -- Shadowlands (Back from the Beyond)
    -----------------------------------------------------------------------
    [15112] = { -- On the Offensive
        {
            questID = 63544,
            altQuestIDs = { 63822, 63823, 63824 },
            name = "Maw Covenant Assault",
            zone = "The Maw",
            mapID = 1543,
            notes = "Complete the 4 bi-weekly rotating Covenant Assaults in the Maw (Kyrian, Necrolord, Night Fae, and Venthyr).",
        }
    },
    [14755] = { -- Tea Tales
        {
            questID = 57865,
            name = "Tubbins's Tea Gathering",
            zone = "Revendreth",
            mapID = 1525,
            notes = "Serve tea to rotating VIP guests during the Ember Court weekly scenario.",
        }
    },

    -----------------------------------------------------------------------
    -- Dragonflight (A World Awoken)
    -----------------------------------------------------------------------
    [16424] = { -- Climbing the Walls
        {
            questID = 70760,
            altQuestIDs = { 70761, 70762 },
            name = "Rock Climbing World Quest",
            zone = "Dragon Isles",
            mapID = 2022,
            notes = "Complete Expedition Rock Climbing World Quests across the Dragon Isles.",
        }
    },
    [16423] = { -- Rafting Rush
        {
            questID = 70757,
            altQuestIDs = { 70758, 70759 },
            name = "River Rafting World Quest",
            zone = "Dragon Isles",
            mapID = 2022,
            notes = "Complete Expedition River Rafting World Quests across the Dragon Isles.",
        }
    },
    [16584] = { -- Cataloging the Wilds
        {
            questID = 70752,
            altQuestIDs = { 70753, 70754 },
            name = "Cataloging World Quest",
            zone = "Dragon Isles",
            mapID = 2022,
            notes = "Photograph rare wildlife during Expedition Cataloging World Quests across the Dragon Isles.",
        }
    },
}

-- Format remaining minutes into human-readable duration
function MCT.Engine.FormatTimeRemaining(minutes)
    if not minutes or minutes <= 0 then
        return "Expired"
    end
    if minutes >= 1440 then
        local days = math.floor(minutes / 1440)
        local hours = math.floor((minutes % 1440) / 60)
        if hours > 0 then
            return days .. "d " .. hours .. "h"
        else
            return days .. "d"
        end
    elseif minutes >= 60 then
        local hours = math.floor(minutes / 60)
        local mins = minutes % 60
        if mins > 0 then
            return hours .. "h " .. mins .. "m"
        else
            return hours .. "h"
        end
    else
        return minutes .. "m"
    end
end

-- Reverse index of known World Quest questIDs from MCT.WorldQuests
local knownWorldQuestIDs = nil

function MCT.Engine.IsWorldQuest(questID)
    if not questID or type(questID) ~= "number" or questID <= 0 then
        return false
    end

    if not knownWorldQuestIDs then
        knownWorldQuestIDs = {}
        if MCT.WorldQuests then
            for achID, entries in pairs(MCT.WorldQuests) do
                for _, entry in ipairs(entries) do
                    if entry.questID then
                        knownWorldQuestIDs[entry.questID] = achID
                    end
                    if entry.altQuestIDs then
                        for _, altID in ipairs(entry.altQuestIDs) do
                            knownWorldQuestIDs[altID] = achID
                        end
                    end
                end
            end
        end
    end

    if knownWorldQuestIDs[questID] then
        return true
    end

    if QuestUtils_IsQuestWorldQuest and QuestUtils_IsQuestWorldQuest(questID) then
        return true
    end

    if C_QuestLog and C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID) then
        return true
    end

    return false
end

-- Query live state of a single World Quest ID
function MCT.Engine.GetWorldQuestInfo(questID, fallbackData)
    if not questID or type(questID) ~= "number" or questID <= 0 then
        return nil
    end

    -- If no explicit fallbackData was provided from our database, verify it is truly a World Quest
    if not fallbackData and not MCT.Engine.IsWorldQuest(questID) then
        return nil
    end

    local isActive = false
    if C_TaskQuest and C_TaskQuest.IsActive then
        isActive = C_TaskQuest.IsActive(questID) or false
    end

    local isCompleted = false
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID) or false
    end

    local timeLeftMinutes = nil
    if C_TaskQuest and C_TaskQuest.GetQuestTimeLeftMinutes then
        timeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes(questID)
    end

    local timeLeftFormatted = ""
    if isActive and timeLeftMinutes and timeLeftMinutes > 0 then
        timeLeftFormatted = MCT.Engine.FormatTimeRemaining(timeLeftMinutes)
    end

    -- Title
    local title = nil
    if C_TaskQuest and C_TaskQuest.GetQuestInfoByQuestID then
        title = C_TaskQuest.GetQuestInfoByQuestID(questID)
    end
    if (not title or title == "") and C_QuestLog and C_QuestLog.GetTitleForQuestID then
        title = C_QuestLog.GetTitleForQuestID(questID)
    end
    if not title or title == "" then
        title = (fallbackData and fallbackData.name) or ("Quest #" .. questID)
    end

    -- Map / Zone
    local mapID = (fallbackData and fallbackData.mapID)
    if not mapID and C_TaskQuest and C_TaskQuest.GetQuestZoneID then
        mapID = C_TaskQuest.GetQuestZoneID(questID)
    end

    local zoneName = (fallbackData and fallbackData.zone)
    if mapID and C_Map and C_Map.GetMapInfo then
        local mapInfo = C_Map.GetMapInfo(mapID)
        if mapInfo and mapInfo.name then
            zoneName = mapInfo.name
        end
    end

    return {
        questID = questID,
        title = title,
        isActive = isActive,
        isCompleted = isCompleted,
        timeLeftMinutes = timeLeftMinutes,
        timeLeftFormatted = timeLeftFormatted,
        mapID = mapID,
        zoneName = zoneName or "Unknown Zone",
        notes = fallbackData and fallbackData.notes,
    }
end

-- Query all World Quests associated with an Achievement ID
function MCT.Engine.GetAchievementWorldQuests(achievementID)
    if not achievementID or type(achievementID) ~= "number" then
        return nil
    end

    local wqEntries = MCT.WorldQuests and MCT.WorldQuests[achievementID]
    if not wqEntries or #wqEntries == 0 then
        return nil
    end

    local results = {}
    local anyActive = false
    local anyCompleted = false
    local firstActive = nil

    for _, entry in ipairs(wqEntries) do
        local qInfo = MCT.Engine.GetWorldQuestInfo(entry.questID, entry)
        if qInfo then
            -- If primary ID not active, check alt IDs
            if not qInfo.isActive and entry.altQuestIDs then
                for _, altID in ipairs(entry.altQuestIDs) do
                    local altInfo = MCT.Engine.GetWorldQuestInfo(altID, entry)
                    if altInfo and altInfo.isActive then
                        qInfo = altInfo
                        break
                    end
                end
            end

            table.insert(results, qInfo)
            if qInfo.isActive then
                anyActive = true
                if not firstActive then
                    firstActive = qInfo
                end
            end
            if qInfo.isCompleted then
                anyCompleted = true
            end
        end
    end

    return {
        achievementID = achievementID,
        quests = results,
        hasActive = anyActive,
        hasCompleted = anyCompleted,
        activeQuest = firstActive,
        firstQuest = results[1],
    }
end

-- Open World Map directly to the zone
function MCT.Engine.OpenWorldQuestMap(mapID)
    if not mapID or mapID <= 0 then return end

    if OpenWorldMap then
        OpenWorldMap(mapID)
        return
    end

    if WorldMapFrame then
        WorldMapFrame:Show()
        if WorldMapFrame.SetMapID then
            WorldMapFrame:SetMapID(mapID)
        end
    end
end

-- Track World Quest in Blizzard Objective Tracker
function MCT.Engine.TrackWorldQuest(questID)
    if not questID or questID <= 0 then return end

    if C_ContentTracking and C_ContentTracking.StartTracking and Enum and Enum.ContentTrackingType then
        C_ContentTracking.StartTracking(Enum.ContentTrackingType.Quest, questID)
        print("|cFF00A6FFMCT:|r Tracking World Quest #" .. questID)
        return
    end

    if C_QuestLog and C_QuestLog.AddWorldQuestWatch then
        C_QuestLog.AddWorldQuestWatch(questID, 1)
        print("|cFF00A6FFMCT:|r Tracking World Quest #" .. questID)
    end
end

-- Recursively find all uncompleted achievements in a criteria tree that have active World Quests
function MCT.Engine.FindActiveWorldQuestsInTree(tree)
    local found = {}
    local visited = {}
    if not tree or not tree.criteria then return found end

    local function SearchCriteria(criteriaList)
        for _, item in ipairs(criteriaList) do
            if item.isSubAchievement and item.subAchievementData then
                local subData = item.subAchievementData
                if not subData.completed and not visited[subData.id] then
                    visited[subData.id] = true
                    local wqData = MCT.Engine.GetAchievementWorldQuests(subData.id)
                    if wqData and wqData.hasActive then
                        table.insert(found, {
                            achievementID = subData.id,
                            achievementName = subData.name,
                            activeQuest = wqData.activeQuest,
                            allQuests = wqData.quests,
                        })
                    end
                    if item.subTree and item.subTree.criteria then
                        SearchCriteria(item.subTree.criteria)
                    end
                end
            end
        end
    end

    SearchCriteria(tree.criteria)
    return found
end

-- Recursively find all achievements in a criteria tree that have any World Quest requirements
function MCT.Engine.FindAllWorldQuestsInTree(tree)
    local found = {}
    local visited = {}
    if not tree or not tree.criteria then return found end

    local function SearchCriteria(criteriaList)
        for _, item in ipairs(criteriaList) do
            if item.isSubAchievement and item.subAchievementData then
                local subData = item.subAchievementData
                if not subData.completed and not visited[subData.id] then
                    visited[subData.id] = true
                    local wqData = MCT.Engine.GetAchievementWorldQuests(subData.id)
                    if wqData and wqData.firstQuest then
                        table.insert(found, {
                            achievementID = subData.id,
                            achievementName = subData.name,
                            questName = wqData.firstQuest.title,
                            zoneName = wqData.firstQuest.zoneName,
                            hasActive = wqData.hasActive,
                            activeQuest = wqData.activeQuest,
                            allQuests = wqData.quests,
                        })
                    end
                    if item.subTree and item.subTree.criteria then
                        SearchCriteria(item.subTree.criteria)
                    end
                end
            end
        end
    end

    SearchCriteria(tree.criteria)
    return found
end

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
        
        if completed then
            tree.completedCriteria = tree.completedCriteria + 1
        end

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

    -- Modern Retail 11.x Content Tracking API
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
            C_ContentTracking.StopTracking(Enum.ContentTrackingType.Achievement, achievementID, 2)
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

    -- Modern Retail 10.x/11.x standard utility function
    if OpenAchievementFrameToAchievement then
        OpenAchievementFrameToAchievement(achievementID)
        return
    end

    -- Fallback
    if not AchievementFrame then
        if AchievementFrame_LoadUI then
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

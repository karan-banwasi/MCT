-- WorldQuests.lua: World Quest mapping and live status engine for MetaCompletionTracker
local addonName, MCT = ...

MCT.WorldQuests = {
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
            notes = "Summon sandworms using the Sandfishing Pole. Manually loot the 5 specific Sandworm Scales. Turn off auto-loot and DO NOT finish quest objective fangs until all scales are collected!",
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
    -----------------------------------------------------------------------
    -- Midnight (Vaults of Atal'Utek / Assault the Vault)
    -----------------------------------------------------------------------
    [63598] = { -- Roll the Patrol
        {
            questID = 82401,
            name = "Temple Patrol",
            zone = "Vaults of Atal'Utek",
            notes = "Complete 12 unique Temple Patrol variants in the Vaults of Atal'Utek. Patrols rotate every 10 minutes.",
        }
    },
    [63630] = { -- Assault the Vault
        {
            questID = 82400,
            name = "Vaults of Atal'Utek Assaults",
            zone = "Vaults of Atal'Utek",
            notes = "Complete rotating Temple Patrols (10m), Temple Strikes, Temple Incursions, and defeat Ancient Foes.",
        }
    },
}

---------------------------------------------------------------------------
-- Engine Helpers for World Quests
---------------------------------------------------------------------------
MCT.Engine = MCT.Engine or {}

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
    if not tree or not tree.criteria then return found end

    local function SearchCriteria(criteriaList)
        for _, item in ipairs(criteriaList) do
            if item.isSubAchievement and item.subAchievementData then
                local subData = item.subAchievementData
                if not subData.completed then
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

    -- Also check the root achievement itself if uncompleted
    if tree.data and not tree.data.completed then
        local rootWq = MCT.Engine.GetAchievementWorldQuests(tree.id)
        if rootWq and rootWq.hasActive then
            table.insert(found, {
                achievementID = tree.id,
                achievementName = tree.data.name,
                activeQuest = rootWq.activeQuest,
                allQuests = rootWq.quests,
            })
        end
    end

    SearchCriteria(tree.criteria)
    return found
end

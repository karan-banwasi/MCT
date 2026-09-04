-- AchievementEngine.lua: Data extraction and recursive criteria walker for MCT
local addonName, MCT = ...

MCT.Engine = {}

-- Cache for achievement meta-data
local achievementCache = {}

-- Safe retrieval of achievement info with fallback defaults
function MCT.Engine.GetAchievementData(achievementID)
    if not achievementID or achievementID <= 0 then
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
-- maxDepth: 1 = direct criteria only, 2 = drill into sub-achievements
-- Get criteria tree recursively for a meta-achievement
-- maxDepth: default 5 to support deep hierarchies (Mega Meta -> Zone Meta -> Sub Meta -> Achievement -> Criteria)
function MCT.Engine.GetCriteriaTree(achievementID, maxDepth, currentDepth, visited)
    currentDepth = currentDepth or 1
    maxDepth = maxDepth or 5
    visited = visited or {}

    if visited[achievementID] then
        return nil
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
            
            -- If sub-achievement has criteria and depth permits, query its sub-tree
            if currentDepth < maxDepth then
                local subNumCriteria = GetAchievementNumCriteria(assetID) or 0
                if subNumCriteria > 0 then
                    local nextVisited = {}
                    for k, v in pairs(visited) do nextVisited[k] = v end
                    nextVisited[achievementID] = true
                    item.subTree = MCT.Engine.GetCriteriaTree(assetID, maxDepth, currentDepth + 1, nextVisited)
                end
            end
        else
            item.isSubAchievement = false
        end

        table.insert(tree.criteria, item)
    end

    if tree.totalCriteria > 0 then
        tree.percent = math.floor((tree.completedCriteria / tree.totalCriteria) * 100)
    else
        tree.percent = achData.completed and 100 or 0
    end

    return tree
end

-- Check if an achievement is tracked in native Objective Tracker
function MCT.Engine.IsTracked(achievementID)
    if not achievementID then return false end

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
    if not achievementID then return end

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
    if not achievementID or achievementID <= 0 then return end

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

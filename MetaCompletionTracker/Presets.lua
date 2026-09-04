-- Presets.lua: Expansion-specific and iconic meta-achievement definitions for MCT
local addonName, MCT = ...

MCT.Presets = {
    {
        id = 40953,
        name = "A Farewell to Arms",
        expansion = "Battle for Azeroth",
        category = "Expansion Super-Meta",
        reward = "Jani's Trashpile (Mount)",
        icon = 237272,
        description = "Complete all major Battle for Azeroth raid, dungeon, zone, quest, and exploration achievements.",
    },
    {
        id = 19458,
        name = "A World Awoken",
        expansion = "Dragonflight",
        category = "Expansion Super-Meta",
        reward = "Taivan (Mount)",
        icon = 4638575,
        description = "Complete all major Dragonflight raid, dungeon, zone, faction, and exploration achievements.",
    },
    {
        id = 20501,
        name = "Back from the Beyond",
        expansion = "Shadowlands",
        category = "Expansion Super-Meta",
        reward = "Zovaal's Shadebeast Collar (Mount)",
        icon = 3565449,
        description = "Complete all major Shadowlands raid, dungeon, covenant, and exploration achievements.",
    },
    {
        id = 40537,
        name = "Khaz Algar Diplomat",
        expansion = "The War Within",
        category = "Expansion Meta",
        reward = "Renown Progress",
        icon = 5342938,
        description = "Attain maximum renown with the primary factions of Khaz Algar.",
    },
    {
        id = 13541,
        name = "Mecha-Done",
        expansion = "Battle for Azeroth",
        category = "Zone Super-Meta",
        reward = "Keys to the Model W (Mount)",
        icon = 2967114,
        description = "Complete all Mechagon Island achievements, collectibles, and inventions.",
    },
    {
        id = 13638,
        name = "Undersea Usurper",
        expansion = "Battle for Azeroth",
        category = "Zone Super-Meta",
        reward = "Snapback Scuttler (Mount)",
        icon = 2967115,
        description = "Complete all Nazjatar achievements, rare hunting, and undersea exploration.",
    },
    {
        id = 13517,
        name = "Two Sides to Every Tale",
        expansion = "Battle for Azeroth",
        category = "Faction Campaign",
        reward = "Bloodflank Charger & Ironclad Frostclaw (Mounts)",
        icon = 2058260,
        description = "Experience both sides of the Fourth War campaign on Alliance and Horde.",
    },
    {
        id = 2144,
        name = "What a Long, Strange Trip It's Been",
        expansion = "World Events",
        category = "Holiday Super-Meta",
        reward = "Reins of the Violet Proto-Drake (310% Mount)",
        icon = 236391,
        description = "Complete all the major world event holiday achievements throughout the year.",
    },
}

-- Default preset ID on first install
MCT.DefaultPresetID = 40953 -- A Farewell to Arms

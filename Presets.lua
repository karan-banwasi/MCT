-- Presets.lua: Expansion-specific and iconic meta-achievement definitions for MCT
local addonName, MCT = ...

---------------------------------------------------------------------------
-- Top-Level Expansion Definitions
---------------------------------------------------------------------------
MCT.Expansions = {
    {
        key = "BfA",
        name = "Battle for Azeroth",
        label = "BfA",
        icon = 237272,
    },
    {
        key = "SL",
        name = "Shadowlands",
        label = "Shadowlands",
        icon = 3565449,
    },
    {
        key = "DF",
        name = "Dragonflight",
        label = "Dragonflight",
        icon = 4638575,
    },
    {
        key = "TWW",
        name = "The War Within",
        label = "War Within",
        icon = 5342938,
    },
    {
        key = "MID",
        name = "Midnight",
        label = "Midnight",
        icon = 5342938,
    },
    {
        key = "World",
        name = "World Events",
        label = "World Events",
        icon = 236391,
    },
}

---------------------------------------------------------------------------
-- Meta-Achievement Presets (Organized under Expansions)
---------------------------------------------------------------------------
MCT.Presets = {
    -- Battle for Azeroth
    {
        id = 40953,
        name = "Battle for Azeroth: A Farewell to Arms",
        subHeading = "A Farewell to Arms",
        shortName = "BfA",
        expansionKey = "BfA",
        expansion = "Battle for Azeroth",
        category = "Expansion Super-Meta",
        reward = "Jani's Trashpile (Mount)",
        icon = 237272,
        description = "Complete all major Battle for Azeroth raid, dungeon, zone, quest, and exploration achievements.",
    },
    {
        id = 13541,
        name = "Mecha-Done",
        subHeading = "Mecha-Done",
        shortName = "Mecha",
        expansionKey = "BfA",
        expansion = "Battle for Azeroth",
        category = "Zone Super-Meta",
        reward = "Keys to the Model W (Mount)",
        icon = 2967114,
        description = "Complete all Mechagon Island achievements, collectibles, and inventions.",
    },
    {
        id = 13638,
        name = "Undersea Usurper",
        subHeading = "Undersea Usurper",
        shortName = "Nazjatar",
        expansionKey = "BfA",
        expansion = "Battle for Azeroth",
        category = "Zone Super-Meta",
        reward = "Snapback Scuttler (Mount)",
        icon = 2967115,
        description = "Complete all Nazjatar achievements, rare hunting, and undersea exploration.",
    },
    {
        id = 13517,
        name = "Two Sides to Every Tale",
        subHeading = "Two Sides to Every Tale",
        shortName = "2-Sides",
        expansionKey = "BfA",
        expansion = "Battle for Azeroth",
        category = "Faction Campaign",
        reward = "Bloodflank Charger & Ironclad Frostclaw (Mounts)",
        icon = 2058260,
        description = "Experience both sides of the Fourth War campaign on Alliance and Horde.",
    },

    -- Shadowlands
    {
        id = 20501,
        name = "Shadowlands: Back from the Beyond",
        subHeading = "Back from the Beyond",
        shortName = "SL",
        expansionKey = "SL",
        expansion = "Shadowlands",
        category = "Expansion Super-Meta",
        reward = "Zovaal's Shadebeast Collar (Mount)",
        icon = 3565449,
        description = "Complete all major Shadowlands raid, dungeon, covenant, and exploration achievements.",
    },

    -- Dragonflight
    {
        id = 19458,
        name = "Dragonflight: A World Awoken",
        subHeading = "A World Awoken",
        shortName = "DF",
        expansionKey = "DF",
        expansion = "Dragonflight",
        category = "Expansion Super-Meta",
        reward = "Taivan (Mount)",
        icon = 4638575,
        description = "Complete all major Dragonflight raid, dungeon, zone, faction, and exploration achievements.",
    },

    -- The War Within
    {
        id = 40537,
        name = "The War Within: Khaz Algar Diplomat",
        subHeading = "Khaz Algar Diplomat",
        shortName = "TWW",
        expansionKey = "TWW",
        expansion = "The War Within",
        category = "Expansion Meta",
        reward = "Renown Progress",
        icon = 5342938,
        description = "Attain maximum renown with the primary factions of Khaz Algar.",
    },

    -- Midnight
    {
        id = 62386,
        name = "Midnight: Light Up the Night",
        subHeading = "Light Up the Night",
        shortName = "MID",
        expansionKey = "MID",
        expansion = "Midnight",
        category = "Expansion Super-Meta",
        reward = "Brilliant Petalwing (Mount)",
        icon = 5342938,
        description = "Complete all major Midnight zone meta-achievements across Eversong Woods, Zul'Aman, Harandar, and Voidstorm.",
    },
    {
        id = 63630,
        name = "Assault the Vault",
        subHeading = "Assault the Vault",
        shortName = "Vault",
        expansionKey = "MID",
        expansion = "Midnight",
        category = "Zone Super-Meta",
        reward = "Venomous Coiler (Mount)",
        icon = 5342938,
        description = "Complete all outdoor activities and meta-achievements within the Vaults of Atal'Utek on the Coiled Isle.",
    },
    {
        id = 64150,
        name = "Bane of the Swarm",
        subHeading = "Bane of the Swarm",
        shortName = "Aqir",
        expansionKey = "MID",
        expansion = "Midnight",
        category = "Zone Super-Meta",
        reward = "Bane of the Swarm (Title)",
        icon = 5342938,
        description = "Repel the Aqir Invasions across Eversong Woods and Zul'Aman, complete invasion scenarios, and attain Exalted with the Aqir Research Enclave.",
    },

    -- World Events
    {
        id = 2144,
        name = "What a Long, Strange Trip It's Been",
        subHeading = "What a Long, Strange Trip",
        shortName = "World",
        expansionKey = "World",
        expansion = "World Events",
        category = "Holiday Super-Meta",
        reward = "Reins of the Violet Proto-Drake (310% Mount)",
        icon = 236391,
        description = "Complete all the major world event holiday achievements throughout the year.",
    },
}

-- Default preset ID on first install
MCT.DefaultPresetID = 40953 -- A Farewell to Arms

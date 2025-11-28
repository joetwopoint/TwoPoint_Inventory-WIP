-- TwoPoint Development - kq_link
Config = {}

-- DB adapter: 'auto' | 'oxmysql' | 'mysql-async'
Config.DB = 'auto'

-- Whitelist enforcement (uses kqde_itemdefs)
Config.RequireWhitelist = true

-- Capacity
Config.MaxUniqueItems = 256
Config.MaxWeight = 0 -- 0 = ignore
Config.MaxGiveAmountPerCall = 100000

-- Jobs toggle (unused on vMenu)
Config.EnableJobs = false

-- Money: notifications only (no framework)
Config.ShowMoneyNotifications = true
Config.MoneyCurrency = '$'


-- Search (LEO) settings
Config.Search = {
    RequireAce = false,            -- set true to require ACE permission below
    Ace = 'kq_link.search',        -- ACE permission to allow /search
    MaxDistance = 1.25,             -- meters; 0 disables distance check
    NotifyTarget = true,           -- send 'you are being searched' chat message
    TargetMessage = 'You are being searched.'
}


-- Proximity settings
Config.GiveMaxDistance = 1.25   -- meters; 0 disables distance check for /give


-- Weapon detection (for /search weapons)
Config.WeaponDetect = {
    -- Extra addon weapon names/hashes to check (if a pack adds unique weapon names).
    -- Example: 'WEAPON_TLS_GLOCK19' or 'WEAPON_BEANBAG' if provided by a mod.
    AddonNames = {
        -- Put your TLS addon weapon names here if they are true addon hashes
        -- (most TLS packs are REPLACEMENTS and use vanilla hashes, which are already detected).
        -- "WEAPON_TLS_GLOCK19",
        -- "WEAPON_TLS_TASERX26",
        -- "WEAPON_BEANBAG"
    },

    -- Optional label overrides: map GTA/tls names to pretty labels
    Labels = {
        WEAPON_PISTOL = "Glock 19 (TLS replacement)",
        WEAPON_COMBATPISTOL = "Glock 19 (TLS replacement)",
        WEAPON_STUNGUN = "Taser X26 (TLS)",
        WEAPON_NIGHTSTICK = "ASP Baton (TLS)",
        WEAPON_FLASHLIGHT = "Streamlight Stinger (TLS)",
        WEAPON_KNIFE = "Spyderco Endura 4 (TLS)",
        WEAPON_CARBINERIFLE = "DDM4V7 (TLS)",
    }
}


-- Currency + P2P Pay
Config.MoneyCurrency = '$'   -- symbol
Config.Pay = {
    MaxDistance = 1.25,      -- meters; must be right next to them
    MinAmount = 1,           -- smallest pay
    MaxAmount = 1000000,     -- sanity limit per transaction
    NotifyBoth = true        -- chat notices for both players
}


-- Self-setup starting cash: /setcash <amount>
Config.SetCash = {
    Enable = true,            -- allow players to self-set starting cash
    RequireAce = false,       -- if true, requires ACE 'kq_link.setcash'
    Ace = 'kq_link.setcash',
    OneTime = true,           -- only once per identifier
    RequireZeroBalance = true,-- only allowed if current cash is exactly 0
    Min = 0,                  -- minimum allowed amount
    Max = 100000              -- max allowed starting cash
}


-- NPC drug selling (press E near a civilian ped)
Config.Sell = {
    -- Random refusal (no sale) chance per approach
    Refusal = {
        Enable = true,
        Chance = 0.25,                -- 25% refuse default
        Messages = {
            "Not interested.",
            "Get lost.",
            "No, not here.",
            "You a cop? Nah."
        }
    },

    -- Random heat alert (notify on-duty LEO) after a successful sale
    Heat = {
        PostalCooldownMs = 120000,   -- 2 min per-postal cooldown for alerts
        SellerSuppressedMessage = "Area is hot — lay low for %d:%02d minutes.",
        
        PostalCooldownMs = 120000,   -- 2 min per-postal cooldown for alerts
        
        Enable = true,
        Chance = 0.15,                -- 15% chance per sale
        Depts = { "TPD", "PCSO", "AZDPS", "BP" },  -- allowed tags/prefixes
        Message = "Possible hand-to-hand reported near %s."
    },
    -- Per-item price ranges override global PriceMin/PriceMax when present
    Prices = {
        meth_bag = {10, 50},
        weed_bud = {10, 50},
        coke_brick = {100, 250},
        methamphetamine = {25, 50},
    },
    Enable = true,
    KeyControl = 38,           -- E key (INPUT_PICKUP / INPUT_CONTEXT variants)
    MaxDistance = 1.5,         -- must be right next to the NPC
    Cooldown = 3000,           -- ms between sales per player
    PriceMin = 10,
    PriceMax = 50,
    Items = {                  -- item names eligible for sale (1 unit per press)
        'meth_bag', 'weed_bud', 'coke_brick', 'methamphetamine'
    },
    Prompt = 'Press ~INPUT_PICKUP~ to sell',
    NoDrugsMessage = 'You have no drugs to sell.',
    SoldMessage = 'Sold 1x %s for $%d.'
}


-- Shared drug lockers
Config.Lockers = {
    Enable = true,
    MaxDistance = 1.5,
    ShowPrompt = true,
    Prompt = 'Press ~INPUT_PICKUP~ to open locker',

    -- 1) Auto-detect these prop models and treat them as lockers
    Models = {
        `prop_ld_int_safe_01`,   -- interior safe (PlebMasters/Forge)
        `p_v_43_safe_s`          -- police station style safe
    },

    -- 2) Coordinate-defined lockers (work even without a prop in the world)
    Static = {
        -- { x, y, z, heading }
        { -46.56, -1759.1, 29.42, 90.0 },
        { 24.5, -1346.9, 29.5, 0.0 },
    }
}

Config = {}

-- money symbol
Config.MoneyCurrency = '$'

-- /pay
Config.Pay = { MaxDistance = 1.25, MinAmount = 1, MaxAmount = 1000000, NotifyBoth = true }

-- /setcash
Config.SetCash = {
  Enable = true, RequireAce = false, Ace = 'kq_link.setcash',
  OneTime = true, RequireZeroBalance = true, Min = 0, Max = 100000
}

-- items and prices for selling
Config.Sell = {
  Enable = true, KeyControl = 38, MaxDistance = 1.5, Cooldown = 3000,
  PriceMin = 10, PriceMax = 50,
  Items = { 'meth_bag','weed_bud','coke_brick','methamphetamine' },
  Prices = {
    meth_bag = {10,50},
    weed_bud = {10,50},
    coke_brick = {100,250},
    methamphetamine = {25,50},
  },
  Refusal = { Enable = true, Chance = 0.25, Messages = { "Not interested.","Get lost.","No, not here.","You a cop? Nah." } },
  Heat = {
    Enable = true, Chance = 0.15,
    Depts = { "TPD","PCSO","AZDPS","BP" },
    Message = "Possible hand-to-hand reported near %s.",
    PostalCooldownMs = 120000,
    SellerSuppressedMessage = "Area is hot — lay low for %d:%02d minutes."
  },
  Prompt = 'Press ~INPUT_PICKUP~ to sell',
  NoDrugsMessage = 'You have no drugs to sell.',
  SoldMessage = 'Sold 1x %s for $%d.'
}

-- lockers (props + coords + cash)
Config.Lockers = {
  Enable = true, MaxDistance = 1.5, ShowPrompt = true, Prompt = 'Press ~INPUT_PICKUP~ to open locker',
  Models = { `prop_ld_int_safe_01`, `p_v_43_safe_s` },
  Static = { { -46.56, -1759.1, 29.42, 90.0 }, { 24.5, -1346.9, 29.5, 0.0 } },
  Cash = { Enable = true, MaxPerLocker = 1000000, MaxPerTxn = 50000 }
}

-- TLS weapon labels (optional)
Config.WeaponDetect = {
  AddonNames = {},
  Labels = {
    WEAPON_COMBATPISTOL = "Combat Pistol",
    WEAPON_STUNGUN = "Taser",
    WEAPON_PUMPSHOTGUN = "Pump Shotgun",
    WEAPON_CARBINERIFLE = "Carbine Rifle"
  }
}

-- item labels (shown in chat)
ItemDefs = {
  meth_bag = { label = "Crystal Meth" },
  weed_bud = { label = "Weed Bud" },
  coke_brick = { label = "Cocaine Brick" },
  methamphetamine = { label = "Methamphetamine" }
}

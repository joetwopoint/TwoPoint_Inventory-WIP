-- kq_link / config.lua
Config = {}

-- DB adapter: 'auto' | 'oxmysql' | 'mysql-async'
Config.DB = 'auto'

-- Item whitelist enforcement (uses SQL table kqde_itemdefs)
Config.RequireWhitelist = true

-- Caps
Config.MaxUniqueItems = 256
Config.MaxWeight = 0
Config.MaxGiveAmountPerCall = 100000

-- Jobs toggle (no framework by default)
Config.EnableJobs = false

-- Money behavior: notifications only
Config.ShowMoneyNotifications = true
Config.MoneyCurrency = '$'

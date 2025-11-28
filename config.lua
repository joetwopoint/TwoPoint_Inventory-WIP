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

-- Jobs toggle (unused)
Config.EnableJobs = false

-- Money: notifications only (no framework)
Config.ShowMoneyNotifications = true
Config.MoneyCurrency = '$'

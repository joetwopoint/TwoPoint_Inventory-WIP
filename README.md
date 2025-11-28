
⚠️ **REQUIRED DEPENDENCIES — INSTALL THESE FIRST (BEFORE DOWNLOADING/RUNNING THIS RESOURCE):**
1) **PoliceEMSActivity** (Badger) — used to detect on‑duty LEO for heat alerts  
   Docs: https://docs.badger.store/fivem-discord-scripts/policeemsactivity
2) **BigDaddy Postal Map** — provides postals for street/cross‑street alerts  
   Product page: https://bigdaddyscripts.com/Products/View/2963/Postal-Map  
   Resource name must be **`BigDaddy-PostalMap`** and include `dev/postals.json`.
3) **MySQL adapter** — one of: **oxmysql** (recommended) or **mysql-async**  
   This resource persists **inventory**, **wallets**, **lockers**, and **locker cash** in MySQL.

**Do not proceed** until these are installed and working. This resource will not function correctly without them.

# TwoPoint_Inventory

A **Partial standalone, SQL-backed inventory & money** system tailored for **KuzQuality Drug Empire** on a vMenu server. 
Single drop-in resource that powers items, cash, NPC selling, lockers, weapon checks, and proximity actions—**without** touching your other scripts.

> **Hard dependency for heat alerts:** [Badger’s PoliceEMSActivity](https://docs.badger.store/fivem-discord-scripts/policeemsactivity) — used to detect on‑duty LEO for heat notifications.

---

## Highlights

- **Standalone SQL inventory** designed for KuzQuality Drug Empire items (meth, weed, cocaine, methamphetamine).
- **Simple chat UI only** (no extra NUI): clean white text for all player feedback.
- **/inventory** command (no keybind) to view what you have.
- **Proximity actions (nearest only):**
  - **/give `<item>` `<amount>`** – give drugs to the **closest** player (must be right next to them).
  - **/search** – search the **closest** player and print their items **and weapons** (vMenu + TLS replacements/addons).
- **Weapons listing** in `/search`:
  - Detects **vMenu-equipped** weapons via GTA natives.
  - Detects **TLS replacements** automatically; supports **TLS addon** hashes via config.
- **SQL wallet** + P2P money:
  - **/pay `<amount>`** – pay the **closest** player (strict proximity).
  - **/setcash `<amount>`** – player one‑time starting cash (config‑gated; zero‑balance by default).
- **NPC street selling** (press **E** near a civilian):
  - Sells **1 unit** per press if you actually have drugs (server‑verified).
  - Price ranges (per item):
    - `meth_bag` **$10–$50**
    - `weed_bud` **$10–$50**
    - `coke_brick` **$100–$250**
    - `methamphetamine` **$25–$50**
  - **Random refusal** lines (no sale), **random heat alerts** after successful sales.
  - Heat alerts only go to **on‑duty** LEO from **TPD, PCSO, AZDPS, BP** (via PoliceEMSActivity).
  - Alerts include **street & cross‑street** and **nearest postal** (reads `dev/postals.json` from **BigDaddy-PostalMap**).
  - **Per‑postal cooldown** (default 2 min) prevents alert spam; seller gets a chat **mm:ss** “corner is hot” notice while suppressed.
- **Lockers (shared stashes)**:
  - Walk up to **any configured safe prop** **or** to a **coordinate-defined locker**, press **E** to view.
  - Store only **drug items** (from config) using chat commands.
  - **Cash storage** inside lockers with caps (per locker & per transaction).
  - Everything persists in SQL.

---

## Commands (all proximity‑guarded where applicable)

- `/inventory`  
  Show your inventory.

- `/give <item> <amount>`  
  Give to the **nearest** player (must be right next to them).

- `/search`  
  Search the **nearest** player and print **items + weapons** (vMenu + TLS). Sends a chat line to the target: “You are being searched (wdif).”

- `/pay <amount>`  
  Pay the **nearest** player from your wallet.

- `/setcash <amount>`  
  Set your **starting** wallet balance (defaults: once, only at **$0**, min/max in config).

- `/locker put <item> <amount>`  
- `/locker take <item> <amount>`  
  Put/take **drug items** into/from the nearest locker.

- `/lockercash put <amount>`  
- `/lockercash take <amount>`  
  Put/take **cash** into/from the nearest locker (respects per‑txn and per‑locker limits).

> Keys: **E** (INPUT_PICKUP / control 38) is used for NPC selling and locker open prompts.

---

## Configuration (`config.lua`)

### Currency & Wallet
```lua
Config.MoneyCurrency = '$'

Config.Pay = {
  MaxDistance = 1.25,
  MinAmount = 1,
  MaxAmount = 1000000,
  NotifyBoth = true
}

Config.SetCash = {
  Enable = true,
  RequireAce = false, Ace = 'kq_link.setcash',
  OneTime = true, RequireZeroBalance = true,
  Min = 0, Max = 100000
}
```

### Weapons (TLS support)
```lua
Config.WeaponDetect = {
  AddonNames = {
    -- e.g. "WEAPON_TLS_GLOCK19", "WEAPON_TLS_TASERX26"
  },
  Labels = {
    WEAPON_COMBATPISTOL = "Glock 19 (TLS)",
    WEAPON_STUNGUN = "Taser X26 (TLS)",
    -- etc.
  }
}
```

### NPC Selling
```lua
Config.Sell = {
  Enable = true,
  KeyControl = 38, MaxDistance = 1.5, Cooldown = 3000,
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
  }
}
```

### Lockers (props + coords + cash)
```lua
Config.Lockers = {
  Enable = true,
  MaxDistance = 1.5,
  ShowPrompt = true,
  Prompt = 'Press ~INPUT_PICKUP~ to open locker',

  -- any of these prop models will act as lockers (add more freely)
  Models = {
    `prop_ld_int_safe_01`,
    `p_v_43_safe_s`
  },

  -- works even if there is no prop
  Static = {
    { -46.56, -1759.1, 29.42, 90.0 },
    { 24.5, -1346.9, 29.5, 0.0 },
  },

  Cash = {
    Enable = true,
    MaxPerLocker = 1000000,
    MaxPerTxn = 50000
  }
}
```

---

## Installation

1) **Drop the folder** into `resources/` as **`TwoPoint_Inventory`** and `ensure TwoPoint_Inventory` early in `server.cfg` (before KuzQuality drug scripts).
2) **Database**
   - Install **oxmysql** (recommended) or mysql-async.
   - Import **`sql/TwoPoint_Inventory_all_in_one.sql`**.
3) **Dependencies**
   - **PoliceEMSActivity** (for heat alerts & on‑duty detection):  
     https://docs.badger.store/fivem-discord-scripts/policeemsactivity
   - **BigDaddy-PostalMap** (to add postals to alerts); ensure the resource is named exactly **`BigDaddy-PostalMap`** and includes `dev/postals.json`.
4) (Optional) **ACE** permissions
   - Restrict `/setcash` or other commands with `IsPlayerAceAllowed` + your `server.cfg` `add_ace`/`add_principal` lines.

---

## File layout

```
TwoPoint_Inventory/
  fxmanifest.lua
  config.lua
  client/
    npc_sell.lua
    lockers.lua
    weapons.lua
    notify.lua
  server/
    db.lua
    link.lua
  sql/
    TwoPoint_Inventory_all_in_one.sql
    kq_link_inventory.sql
  README.md
```

---

## Credits & Notes

- Heat alerts + on‑duty detection: **PoliceEMSActivity** by Badger.  
- Postals: reads from **BigDaddy-PostalMap/dev/postals.json** (comment‑stripping + JSON parse).  
- This resource avoids frameworks; it’s aimed at vMenu/KQ Drug Empire servers where you want a **contained, drag‑and‑drop** package.

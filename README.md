⚠️ **REQUIRED DEPENDENCIES — INSTALL THESE FIRST:**
1) **PoliceEMSActivity** (Badger) — on‑duty LEO detection for heat alerts  
   Docs: https://docs.badger.store/fivem-discord-scripts/policeemsactivity
2) **BigDaddy Postal Map** — postals for street/cross‑street alerts  
   Product page: https://bigdaddyscripts.com/Products/View/2963/Postal-Map  
   Resource name must be **`BigDaddy-PostalMap`** and include `dev/postals.json`.
3) **MySQL adapter** — **oxmysql** (recommended) or **mysql-async**

# TwoPoint_Inventory
Standalone, SQL‑backed inventory + wallet for **KuzQuality Drug Empire** on vMenu. Includes NPC street‑selling with refusal + heat alerts, lockers (items + cash), and P2P /give, /search, /pay.

## Commands
/inventory  
/give <item> <amount> (nearest)  
/search (nearest; items + weapons note)  
/pay <amount> (nearest)  
/setcash <amount> (one‑time, $0‑balance by default)  
/locker put|take <item> <amount> (nearest locker)  
/lockercash put|take <amount> (nearest locker)

## Install
- Drop **TwoPoint_Inventory/** in resources and `ensure TwoPoint_Inventory` (after deps).
- Import SQL in `sql/` if needed (tables are auto‑created on start).

## Notes
- Heat alerts go only to on‑duty TPD/PCSO/AZDPS/BP via PoliceEMSActivity.
- Alerts include street, cross‑street, and postal; per‑postal cooldown + seller toast.
- Lockers work on safe props (config list) and coordinate‑only definitions.

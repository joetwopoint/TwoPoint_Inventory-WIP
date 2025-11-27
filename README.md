
# TwoPoint_Inventory

## What’s inside
- SQL-backed inventory just for KuzQuality Drug Empire (vMenu friendly; no ESX/QBCore).
- No external money integration — money calls show notifications only.
- `/inventory` command (labels-only). Use `/inventory count` to sort by quantity.
- Server exports match the original `kq_link` API.

## Install
1) Drop the **kq_link** folder into `resources/`.
2) Import SQL (MySQL):
   - `sql/kq_link_inventory.sql`
   - `sql/kqde_itemdefs_ALL_upsert.sql` (re-runnable; recommended)
3) `server.cfg` example:
```
ensure oxmysql              # or mysql-async
ensure kq_link
ensure kq_meth
ensure kq_weed
ensure kq_cocaine
ensure kq_amphetamines
```
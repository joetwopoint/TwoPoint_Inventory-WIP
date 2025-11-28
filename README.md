# TwoPoint_Inventory — Single-Folder Build (**kq_link**) with /inventory Hotfix

This folder must be named **kq_link** so KuzQuality (`exports.kq_link:*`) works.

## Setup (quick)
1) Import SQL (pick one):
   - `sql/kq_link_inventory.sql` **and** `sql/kqde_itemdefs_ALL_upsert.sql`, or
   - `sql/TwoPoint_Inventory_all_in_one.sql` (creates tables + upserts in one go)
2) server.cfg
```
ensure oxmysql                 # or mysql-async
ensure kq_link
ensure kq_meth
ensure kq_weed
ensure kq_cocaine
ensure kq_amphetamines
```
3) /inventory
   - `/inventory` → alphabetic by label
   - `/inventory count` → by quantity

## Notes
- Inventory is SQL-only and scoped for Drug Empire modules.
- Money calls show notifications only.
- Includes server-side `/inventory` so it works even if the client file doesn't load.

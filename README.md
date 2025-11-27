
# TwoPoint_Inventory — Single-Folder Build (**kq_link**)

This is the **Option A** single-folder build. The folder **must be named `kq_link`** so KuzQuality scripts that call `exports.kq_link:*` keep working.  
Branding remains **TwoPoint_Inventory** inside the files/README.

## What’s inside
- SQL-backed inventory just for KuzQuality Drug Empire (vMenu friendly; no ESX/QBCore).
- No external money integration — money calls show notifications only.
- `/inventory` command (labels-only, white text). Use `/inventory count` to sort by quantity.
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

## Notes
- Exports namespace is the folder name (`kq_link`), so keep this folder named exactly `kq_link`.
- You can keep the TwoPoint branding internally (this README, code comments, etc.).

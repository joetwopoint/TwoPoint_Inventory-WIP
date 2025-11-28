-- TwoPoint Development — All-in-one setup for kq_link / TwoPoint_Inventory
-- Generated: 2025-11-28T09:06:26.810683Z
-- This script will:
--   1) Create the required tables (kqde_inventories, kqde_itemdefs)
--   2) Upsert the item whitelist/labels/weights
-- Notes:
--   - Run this against your target database (use `USE your_db;` first, or add it below).
--   - Safe to re-run: itemdefs use ON DUPLICATE KEY UPDATE.

SET NAMES utf8mb4;
SET SQL_MODE='STRICT_ALL_TABLES,NO_AUTO_VALUE_ON_ZERO';


-- 1) Tables
-- Tables for TwoPoint_Inventory (kq_link)
CREATE TABLE IF NOT EXISTS `kqde_inventories` (
  `identifier` VARCHAR(64) NOT NULL,
  `item`       VARCHAR(64) NOT NULL,
  `amount`     INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`, `item`),
  KEY `idx_item` (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kqde_itemdefs` (
  `item`       VARCHAR(64) NOT NULL,
  `label`      VARCHAR(64) NOT NULL,
  `weight`     DECIMAL(8,3) NOT NULL DEFAULT 0,
  `max_stack`  INT NOT NULL DEFAULT 2147483647,
  PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2) Item whitelist upsert
-- Minimal example itemdefs (extend as needed)
INSERT INTO `kqde_itemdefs` (`item`,`label`,`weight`,`max_stack`) VALUES
  ('meth_bag','Crystal Meth',0.100,500),
  ('coke_brick','Cocaine Brick',2.000,20),
  ('weed_bud','Weed Bud',0.050,200)
ON DUPLICATE KEY UPDATE label=VALUES(label), weight=VALUES(weight), max_stack=VALUES(max_stack);


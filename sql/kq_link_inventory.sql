-- kq_link / sql/kq_link_inventory.sql
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

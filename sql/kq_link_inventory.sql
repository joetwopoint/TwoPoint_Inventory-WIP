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

-- Wallets (per-player cash)
CREATE TABLE IF NOT EXISTS `kqde_wallets` (
  `identifier` VARCHAR(64) NOT NULL,
  `cash` BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Wallet flags
CREATE TABLE IF NOT EXISTS `kqde_wallet_flags` (
  `identifier` VARCHAR(64) NOT NULL,
  `setcash_used` TINYINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Lockers
CREATE TABLE IF NOT EXISTS `kqde_lockers` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `x` DOUBLE NOT NULL,
  `y` DOUBLE NOT NULL,
  `z` DOUBLE NOT NULL,
  `heading` DOUBLE NOT NULL DEFAULT 0,
  `cash` BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kqde_locker_items` (
  `locker_id` INT NOT NULL,
  `item` VARCHAR(64) NOT NULL,
  `amount` BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (`locker_id`,`item`),
  CONSTRAINT `fk_locker_items_lockers` FOREIGN KEY (`locker_id`) REFERENCES `kqde_lockers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Add cash column to lockers (if not present)
ALTER TABLE `kqde_lockers` ADD COLUMN `cash` BIGINT NOT NULL DEFAULT 0;



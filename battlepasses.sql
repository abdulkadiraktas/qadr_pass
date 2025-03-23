-- Battle Pass Ana Tablosu
CREATE TABLE `battle_passes` (
	`id` VARCHAR(10) NOT NULL COLLATE 'armscii8_bin',
	`name` VARCHAR(255) NOT NULL COLLATE 'armscii8_bin',
	`start_date` DATE NOT NULL,
	`end_date` DATE NOT NULL,
	`total_players` INT(10) NOT NULL,
	`premium_players` INT(10) NOT NULL,
	`status` VARCHAR(50) NOT NULL COLLATE 'armscii8_bin',
	PRIMARY KEY (`id`) USING BTREE
)
ENGINE=InnoDB;


-- Battle Pass Detayları Tablosu
CREATE TABLE `battle_pass_details` (
	`battle_pass_id` VARCHAR(10) NOT NULL COLLATE 'armscii8_bin',
	`buy_prompt_text` VARCHAR(255) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`background_dict` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`background_texture` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`background_gradient_dict` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`background_gradient_texture` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`logo_dict` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`logo_texture` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`body_title` VARCHAR(255) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`body_line1` TEXT NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`body_line2` TEXT NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`progress_tile_texture_dict` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`progress_tile_texture` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`progress_rank_text_color` VARCHAR(50) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`progress_large_texture_dict` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`progress_large_texture` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`progress_large_texture_alpha` INT(10) NULL DEFAULT NULL,
	`progress_enabled` TINYINT(1) NULL DEFAULT NULL,
	`progress_tile_overlay_visible` TINYINT(1) NULL DEFAULT NULL,
	`progress_season_tool_tip_text` VARCHAR(255) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	PRIMARY KEY (`battle_pass_id`) USING BTREE,
	CONSTRAINT `battle_pass_details_ibfk_1` FOREIGN KEY (`battle_pass_id`) REFERENCES `redemrp2023reboot`.`battle_passes` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

-- Battle Pass Itemları Tablosu (Premium & Free)
CREATE TABLE `battle_pass_items` (
	`item_id` INT(10) NOT NULL AUTO_INCREMENT,
	`battle_pass_id` VARCHAR(10) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`category` VARCHAR(50) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`itemTexture` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`itemTextureDict` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`selectedBackgroundTexture` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`selectedBackgroundTextureDict` VARCHAR(100) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`label` VARCHAR(255) NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`description` TEXT NULL DEFAULT NULL COLLATE 'armscii8_bin',
	`rank` INT(10) NULL DEFAULT NULL,
	`owned` TINYINT(1) NULL DEFAULT NULL,
	`rewards` JSON NULL DEFAULT NULL,
	PRIMARY KEY (`item_id`) USING BTREE,
	INDEX `battle_pass_id` (`battle_pass_id`) USING BTREE,
	CONSTRAINT `battle_pass_items_ibfk_1` FOREIGN KEY (`battle_pass_id`) REFERENCES `redemrp2023reboot`.`battle_passes` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE `battle_pass_users` (
	`user_id` VARCHAR(36) NOT NULL COLLATE 'armscii8_bin',
	`battle_pass_id` VARCHAR(10) NOT NULL COLLATE 'armscii8_bin',
	`join_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`rank` INT(10) NOT NULL DEFAULT '0',
	`xp` INT(10) NOT NULL DEFAULT '0',
	`xpmax` INT(10) NOT NULL DEFAULT '100',
	`seasonPassOwned` TINYINT(1) NOT NULL DEFAULT '0',
	PRIMARY KEY (`user_id`, `battle_pass_id`) USING BTREE,
	INDEX `fk_battle_pass` (`battle_pass_id`) USING BTREE,
	CONSTRAINT `fk_battle_pass` FOREIGN KEY (`battle_pass_id`) REFERENCES `redemrp2023reboot`.`battle_passes` (`id`) ON UPDATE CASCADE ON DELETE CASCADE
)
ENGINE=InnoDB;

CREATE TABLE `battle_pass_user_items` (
	`user_id` VARCHAR(36) NOT NULL COLLATE 'armscii8_bin',
	`battle_pass_id` VARCHAR(10) NOT NULL COLLATE 'armscii8_bin',
	`item_id` INT(10) NOT NULL,
	`acquired_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`user_id`, `battle_pass_id`, `item_id`) USING BTREE,
	INDEX `fk_user_item_item` (`item_id`) USING BTREE,
	CONSTRAINT `fk_user_item_item` FOREIGN KEY (`item_id`) REFERENCES `redemrp2023reboot`.`battle_pass_items` (`item_id`) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT `fk_user_item_user` FOREIGN KEY (`user_id`, `battle_pass_id`) REFERENCES `redemrp2023reboot`.`battle_pass_users` (`user_id`, `battle_pass_id`) ON UPDATE CASCADE ON DELETE CASCADE
)
ENGINE=InnoDB;


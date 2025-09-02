-- KiezKrieg Database Schema
-- Compatible with ESX Framework

-- Player statistics table
CREATE TABLE IF NOT EXISTS `kk_player_stats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `player_name` varchar(255) NOT NULL,
  `headshot_kills` int(11) DEFAULT 0,
  `headshot_deaths` int(11) DEFAULT 0,
  `bodyshot_kills` int(11) DEFAULT 0,
  `bodyshot_deaths` int(11) DEFAULT 0,
  `ffa_kills` int(11) DEFAULT 0,
  `ffa_deaths` int(11) DEFAULT 0,
  `custom_kills` int(11) DEFAULT 0,
  `custom_deaths` int(11) DEFAULT 0,
  `helifight_kills` int(11) DEFAULT 0,
  `helifight_deaths` int(11) DEFAULT 0,
  `gangwar_kills` int(11) DEFAULT 0,
  `gangwar_deaths` int(11) DEFAULT 0,
  `total_playtime` int(11) DEFAULT 0,
  `last_seen` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
);

-- Factions table
CREATE TABLE IF NOT EXISTS `kk_factions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `leader_identifier` varchar(255) NOT NULL,
  `color` varchar(7) DEFAULT '#3498db',
  `is_open_world` tinyint(1) DEFAULT 0,
  `max_members` int(11) DEFAULT 10,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
);

-- Faction members table
CREATE TABLE IF NOT EXISTS `kk_faction_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `faction_id` int(11) NOT NULL,
  `identifier` varchar(255) NOT NULL,
  `rank` varchar(50) DEFAULT 'member',
  `joined_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`faction_id`) REFERENCES `kk_factions`(`id`) ON DELETE CASCADE,
  UNIQUE KEY `faction_member` (`faction_id`, `identifier`)
);

-- Zones table
CREATE TABLE IF NOT EXISTS `kk_zones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `type` varchar(50) NOT NULL, -- 'ffa', 'custom', 'helifight', 'gangwar'
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `radius` float DEFAULT 100.0,
  `color` varchar(7) DEFAULT '#3498db',
  `max_players` int(11) DEFAULT 10,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `zone_name` (`name`)
);

-- Custom lobbies table
CREATE TABLE IF NOT EXISTS `kk_lobbies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `creator_identifier` varchar(255) NOT NULL,
  `zone_id` int(11) NOT NULL,
  `max_players` int(11) DEFAULT 20,
  `is_private` tinyint(1) DEFAULT 0,
  `password` varchar(255) DEFAULT NULL,
  `current_players` int(11) DEFAULT 0,
  `status` varchar(20) DEFAULT 'waiting', -- 'waiting', 'active', 'finished'
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`zone_id`) REFERENCES `kk_zones`(`id`) ON DELETE CASCADE
);

-- Lobby players table
CREATE TABLE IF NOT EXISTS `kk_lobby_players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lobby_id` int(11) NOT NULL,
  `identifier` varchar(255) NOT NULL,
  `team` int(11) DEFAULT 1, -- 1 or 2 for teams
  `joined_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`lobby_id`) REFERENCES `kk_lobbies`(`id`) ON DELETE CASCADE,
  UNIQUE KEY `lobby_player` (`lobby_id`, `identifier`)
);

-- User preferences table
CREATE TABLE IF NOT EXISTS `kk_user_preferences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `auto_open_menu` tinyint(1) DEFAULT 1,
  `preferred_weapon_mode` varchar(20) DEFAULT 'bodyshot',
  `ui_color_theme` varchar(20) DEFAULT 'blue_pink',
  `sound_enabled` tinyint(1) DEFAULT 1,
  `notifications_enabled` tinyint(1) DEFAULT 1,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
);

-- Insert default FFA zones
INSERT INTO `kk_zones` (`name`, `type`, `x`, `y`, `z`, `radius`, `color`, `max_players`) VALUES
('FFA Zone 1', 'ffa', 200.0, 200.0, 30.0, 100.0, '#e74c3c', 10),
('FFA Zone 2', 'ffa', -500.0, -300.0, 35.0, 100.0, '#3498db', 10),
('FFA Zone 3', 'ffa', 1000.0, -1000.0, 40.0, 100.0, '#f39c12', 10),
('FFA Zone 4', 'ffa', -800.0, 800.0, 25.0, 100.0, '#9b59b6', 10),
('FFA Zone 5', 'ffa', 1500.0, 2000.0, 50.0, 100.0, '#27ae60', 10);

-- Insert default helifight zone
INSERT INTO `kk_zones` (`name`, `type`, `x`, `y`, `z`, `radius`, `color`, `max_players`) VALUES
('Helifight Arena', 'helifight', 0.0, 0.0, 500.0, 200.0, '#ff6b6b', 6);
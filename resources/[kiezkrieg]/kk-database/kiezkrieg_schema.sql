-- KiezKrieg Database Schema
-- Run this SQL script to create the required database tables

-- Player statistics table
CREATE TABLE IF NOT EXISTS `kk_player_stats` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(255) NOT NULL,
    `headshot_kills` int(11) DEFAULT 0,
    `headshot_deaths` int(11) DEFAULT 0,
    `headshot_kda` decimal(5,2) DEFAULT 0.00,
    `bodyshot_kills` int(11) DEFAULT 0,
    `bodyshot_deaths` int(11) DEFAULT 0,
    `bodyshot_kda` decimal(5,2) DEFAULT 0.00,
    `helifight_kills` int(11) DEFAULT 0,
    `helifight_deaths` int(11) DEFAULT 0,
    `helifight_kda` decimal(5,2) DEFAULT 0.00,
    `total_playtime` int(11) DEFAULT 0,
    `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Factions table
CREATE TABLE IF NOT EXISTS `kk_factions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `tag` varchar(10) NOT NULL,
    `description` text,
    `leader_identifier` varchar(255) NOT NULL,
    `color` varchar(7) DEFAULT '#FF0000',
    `max_members` int(11) DEFAULT 50,
    `is_private` tinyint(1) DEFAULT 0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`),
    UNIQUE KEY `tag` (`tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Faction members table
CREATE TABLE IF NOT EXISTS `kk_faction_members` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `faction_id` int(11) NOT NULL,
    `identifier` varchar(255) NOT NULL,
    `rank` varchar(50) DEFAULT 'Member',
    `joined_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `faction_member` (`faction_id`, `identifier`),
    FOREIGN KEY (`faction_id`) REFERENCES `kk_factions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Lobbies table (for persistent lobby data)
CREATE TABLE IF NOT EXISTS `kk_lobbies` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `lobby_id` int(11) NOT NULL,
    `name` varchar(100) NOT NULL,
    `creator_identifier` varchar(255) NOT NULL,
    `password` varchar(255) NULL,
    `is_private` tinyint(1) DEFAULT 0,
    `max_players` int(11) DEFAULT 10,
    `map` varchar(50) DEFAULT 'default',
    `status` enum('waiting', 'active', 'finished') DEFAULT 'waiting',
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `lobby_id` (`lobby_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Zone configurations table
CREATE TABLE IF NOT EXISTS `kk_zones` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `zone_type` enum('ffa', 'lobby', 'helifight', 'gangwar') NOT NULL,
    `coords_x` decimal(10,3) NOT NULL,
    `coords_y` decimal(10,3) NOT NULL,
    `coords_z` decimal(10,3) NOT NULL,
    `radius` decimal(10,3) NOT NULL,
    `max_players` int(11) DEFAULT 10,
    `color_r` int(3) DEFAULT 0,
    `color_g` int(3) DEFAULT 100,
    `color_b` int(3) DEFAULT 255,
    `color_a` int(3) DEFAULT 100,
    `is_active` tinyint(1) DEFAULT 1,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- User preferences table
CREATE TABLE IF NOT EXISTS `kk_user_preferences` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(255) NOT NULL,
    `ui_scale` decimal(3,2) DEFAULT 1.00,
    `auto_spawn` tinyint(1) DEFAULT 1,
    `notifications` tinyint(1) DEFAULT 1,
    `sound_effects` tinyint(1) DEFAULT 1,
    `preferred_mode` enum('headshot', 'bodyshot', 'helifight') DEFAULT 'headshot',
    `last_zone` int(11) NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Admin logs table
CREATE TABLE IF NOT EXISTS `kk_admin_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `admin_identifier` varchar(255) NOT NULL,
    `action` varchar(100) NOT NULL,
    `target_identifier` varchar(255) NULL,
    `details` text NULL,
    `timestamp` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `admin_identifier` (`admin_identifier`),
    INDEX `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Game sessions table (for tracking active games)
CREATE TABLE IF NOT EXISTS `kk_game_sessions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `session_id` varchar(100) NOT NULL,
    `game_mode` enum('ffa_headshot', 'ffa_bodyshot', 'custom_lobby', 'helifight', 'gangwar') NOT NULL,
    `zone_id` int(11) NULL,
    `lobby_id` int(11) NULL,
    `players` text NULL, -- JSON array of player identifiers
    `start_time` timestamp DEFAULT CURRENT_TIMESTAMP,
    `end_time` timestamp NULL,
    `status` enum('active', 'finished', 'aborted') DEFAULT 'active',
    PRIMARY KEY (`id`),
    UNIQUE KEY `session_id` (`session_id`),
    INDEX `game_mode` (`game_mode`),
    INDEX `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default zones
INSERT IGNORE INTO `kk_zones` (`name`, `zone_type`, `coords_x`, `coords_y`, `coords_z`, `radius`, `max_players`, `color_r`, `color_g`, `color_b`, `color_a`) VALUES
('Downtown FFA', 'ffa', -1037.000, -2737.000, 20.200, 100.000, 10, 0, 100, 255, 100),
('Airport FFA', 'ffa', -1336.000, -3044.000, 13.900, 100.000, 10, 0, 100, 255, 100),
('Industrial FFA', 'ffa', 715.000, -962.000, 30.400, 100.000, 10, 0, 100, 255, 100),
('Beach FFA', 'ffa', -1212.000, -1607.000, 4.600, 100.000, 10, 0, 100, 255, 100),
('Hills FFA', 'ffa', -2072.000, 3170.000, 32.800, 100.000, 10, 0, 100, 255, 100);

-- Create database views for easier queries
CREATE VIEW `kk_player_stats_view` AS
SELECT 
    ps.*,
    (ps.headshot_kills + ps.bodyshot_kills + ps.helifight_kills) as total_kills,
    (ps.headshot_deaths + ps.bodyshot_deaths + ps.helifight_deaths) as total_deaths,
    CASE 
        WHEN (ps.headshot_deaths + ps.bodyshot_deaths + ps.helifight_deaths) = 0 THEN 
            (ps.headshot_kills + ps.bodyshot_kills + ps.helifight_kills)
        ELSE 
            ROUND((ps.headshot_kills + ps.bodyshot_kills + ps.helifight_kills) / (ps.headshot_deaths + ps.bodyshot_deaths + ps.helifight_deaths), 2)
    END as total_kda
FROM `kk_player_stats` ps;

CREATE VIEW `kk_faction_stats_view` AS
SELECT 
    f.*,
    COUNT(fm.id) as member_count,
    (SELECT COUNT(*) FROM kk_faction_members fm2 WHERE fm2.faction_id = f.id AND fm2.rank = 'Leader') as leader_count
FROM `kk_factions` f
LEFT JOIN `kk_faction_members` fm ON f.id = fm.faction_id
GROUP BY f.id;
-- KiezKrieg Database Setup
-- This resource handles database initialization and schema management

Citizen.CreateThread(function()
    print('[KK-Database] Initializing database schema...')
    
    -- Player Statistics Table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_player_stats (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL UNIQUE,
            ffa_headshot_kills INT DEFAULT 0,
            ffa_headshot_deaths INT DEFAULT 0,
            ffa_headshot_assists INT DEFAULT 0,
            ffa_bodyshot_kills INT DEFAULT 0,
            ffa_bodyshot_deaths INT DEFAULT 0,
            ffa_bodyshot_assists INT DEFAULT 0,
            custom_lobby_kills INT DEFAULT 0,
            custom_lobby_deaths INT DEFAULT 0,
            custom_lobby_assists INT DEFAULT 0,
            helifight_kills INT DEFAULT 0,
            helifight_deaths INT DEFAULT 0,
            helifight_assists INT DEFAULT 0,
            gangwar_kills INT DEFAULT 0,
            gangwar_deaths INT DEFAULT 0,
            gangwar_assists INT DEFAULT 0,
            total_playtime INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_identifier (identifier)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Factions Table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_factions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL UNIQUE,
            tag VARCHAR(10),
            leader VARCHAR(50) NOT NULL,
            description TEXT,
            members JSON,
            territories JSON,
            bank_balance INT DEFAULT 0,
            max_members INT DEFAULT 50,
            faction_type ENUM('public', 'private') DEFAULT 'private',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_leader (leader),
            INDEX idx_name (name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Custom Lobbies Table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_custom_lobbies (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            creator VARCHAR(50) NOT NULL,
            password VARCHAR(255),
            max_players INT DEFAULT 20,
            map_name VARCHAR(100),
            game_mode VARCHAR(50),
            settings JSON,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_creator (creator),
            INDEX idx_active (is_active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Zone Configurations Table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_zones (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            zone_type VARCHAR(50) NOT NULL,
            coordinates JSON NOT NULL,
            radius FLOAT DEFAULT 100.0,
            settings JSON,
            is_active BOOLEAN DEFAULT true,
            created_by VARCHAR(50),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_type (zone_type),
            INDEX idx_active (is_active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Match History Table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_match_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            match_type VARCHAR(50) NOT NULL,
            participants JSON NOT NULL,
            winner VARCHAR(50),
            match_data JSON,
            duration INT,
            started_at TIMESTAMP,
            ended_at TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_match_type (match_type),
            INDEX idx_winner (winner),
            INDEX idx_started_at (started_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Player Preferences Table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_player_preferences (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL UNIQUE,
            ui_theme VARCHAR(20) DEFAULT 'default',
            keybinds JSON,
            settings JSON,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_identifier (identifier)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Faction Wars Table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_faction_wars (
            id INT AUTO_INCREMENT PRIMARY KEY,
            faction1_id INT NOT NULL,
            faction2_id INT NOT NULL,
            status ENUM('pending', 'active', 'completed') DEFAULT 'pending',
            winner_faction_id INT,
            war_data JSON,
            started_at TIMESTAMP,
            ended_at TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (faction1_id) REFERENCES kk_factions(id),
            FOREIGN KEY (faction2_id) REFERENCES kk_factions(id),
            FOREIGN KEY (winner_faction_id) REFERENCES kk_factions(id),
            INDEX idx_status (status),
            INDEX idx_factions (faction1_id, faction2_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Insert default zones if they don't exist
    MySQL.query('SELECT COUNT(*) as count FROM kk_zones', {}, function(result)
        if result[1] and result[1].count == 0 then
            -- Insert default FFA zones
            local defaultZones = {
                {
                    name = 'Downtown Arena',
                    zone_type = 'ffa',
                    coordinates = json.encode({x = -265.0, y = -957.0, z = 31.0}),
                    radius = 100.0
                },
                {
                    name = 'Airport Battleground',
                    zone_type = 'ffa',
                    coordinates = json.encode({x = -1037.0, y = -2737.0, z = 20.0}),
                    radius = 100.0
                },
                {
                    name = 'Beach Combat Zone',
                    zone_type = 'ffa',
                    coordinates = json.encode({x = -1223.0, y = -1491.0, z = 4.0}),
                    radius = 100.0
                },
                {
                    name = 'Industrial Warfare',
                    zone_type = 'ffa',
                    coordinates = json.encode({x = 170.0, y = -1799.0, z = 29.0}),
                    radius = 100.0
                },
                {
                    name = 'Mountain Peak',
                    zone_type = 'ffa',
                    coordinates = json.encode({x = -1616.0, y = 4763.0, z = 53.0}),
                    radius = 100.0
                }
            }
            
            for _, zone in pairs(defaultZones) do
                MySQL.insert('INSERT INTO kk_zones (name, zone_type, coordinates, radius, created_by) VALUES (?, ?, ?, ?, ?)', {
                    zone.name,
                    zone.zone_type,
                    zone.coordinates,
                    zone.radius,
                    'system'
                })
            end
            
            print('[KK-Database] Default zones inserted')
        end
    end)
    
    print('[KK-Database] Database schema initialized successfully')
end)

-- Export database functions
exports('ExecuteQuery', function(query, parameters, callback)
    MySQL.query(query, parameters, callback)
end)

exports('ExecuteInsert', function(query, parameters, callback)
    MySQL.insert(query, parameters, callback)
end)

exports('ExecuteUpdate', function(query, parameters, callback)
    MySQL.update(query, parameters, callback)
end)

exports('GetPlayerStats', function(identifier, callback)
    MySQL.query('SELECT * FROM kk_player_stats WHERE identifier = ?', {identifier}, callback)
end)

exports('UpdatePlayerStats', function(identifier, stats, callback)
    MySQL.update([[
        INSERT INTO kk_player_stats (identifier, ffa_headshot_kills, ffa_headshot_deaths, ffa_headshot_assists,
                                     ffa_bodyshot_kills, ffa_bodyshot_deaths, ffa_bodyshot_assists,
                                     custom_lobby_kills, custom_lobby_deaths, custom_lobby_assists,
                                     helifight_kills, helifight_deaths, helifight_assists,
                                     gangwar_kills, gangwar_deaths, gangwar_assists)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            ffa_headshot_kills = VALUES(ffa_headshot_kills),
            ffa_headshot_deaths = VALUES(ffa_headshot_deaths),
            ffa_headshot_assists = VALUES(ffa_headshot_assists),
            ffa_bodyshot_kills = VALUES(ffa_bodyshot_kills),
            ffa_bodyshot_deaths = VALUES(ffa_bodyshot_deaths),
            ffa_bodyshot_assists = VALUES(ffa_bodyshot_assists),
            custom_lobby_kills = VALUES(custom_lobby_kills),
            custom_lobby_deaths = VALUES(custom_lobby_deaths),
            custom_lobby_assists = VALUES(custom_lobby_assists),
            helifight_kills = VALUES(helifight_kills),
            helifight_deaths = VALUES(helifight_deaths),
            helifight_assists = VALUES(helifight_assists),
            gangwar_kills = VALUES(gangwar_kills),
            gangwar_deaths = VALUES(gangwar_deaths),
            gangwar_assists = VALUES(gangwar_assists),
            updated_at = CURRENT_TIMESTAMP
    ]], {
        identifier,
        stats.ffa_headshot_kills, stats.ffa_headshot_deaths, stats.ffa_headshot_assists,
        stats.ffa_bodyshot_kills, stats.ffa_bodyshot_deaths, stats.ffa_bodyshot_assists,
        stats.custom_lobby_kills, stats.custom_lobby_deaths, stats.custom_lobby_assists,
        stats.helifight_kills, stats.helifight_deaths, stats.helifight_assists,
        stats.gangwar_kills, stats.gangwar_deaths, stats.gangwar_assists
    }, callback)
end)
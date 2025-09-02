# KiezKrieg Database Setup Instructions

## Prerequisites
- MySQL/MariaDB server running
- ESX Legacy server with oxmysql

## Installation Steps

1. **Import the database schema**
   ```sql
   -- Connect to your MySQL server and run:
   SOURCE kiezkrieg_schema.sql;
   ```

2. **Configure your server.cfg**
   Add the following resources to your server.cfg in order:
   ```
   # KiezKrieg Framework
   ensure kk-database
   ensure kk-core
   ensure kk-ui
   ensure kk-zones
   ensure kk-factions
   ensure kk-admin
   ```

3. **ESX Configuration**
   Make sure your ESX server has the following settings:
   - `Config.Multichar = true` (for character selection)
   - `Config.StartingAccountMoney` configured
   - Database connection properly configured

## Database Tables Created

- `kk_player_stats` - Player kill/death statistics per game mode
- `kk_factions` - Faction information and settings
- `kk_faction_members` - Faction membership data
- `kk_lobbies` - Custom lobby configurations
- `kk_zones` - Zone coordinates and settings
- `kk_user_preferences` - User interface and gameplay preferences
- `kk_admin_logs` - Administrative action logging
- `kk_game_sessions` - Active game session tracking

## Default Data

The schema automatically creates 5 default FFA zones:
- Downtown FFA
- Airport FFA
- Industrial FFA
- Beach FFA
- Hills FFA

## Configuration Notes

- All coordinates are placeholder values and can be modified
- Zone radius is set to 100m by default
- Maximum players per zone is 10 by default
- All settings are configurable through the database

## Maintenance

Regular maintenance queries:
```sql
-- Clean up old game sessions (older than 24 hours)
DELETE FROM kk_game_sessions WHERE end_time < NOW() - INTERVAL 24 HOUR;

-- Clean up inactive lobbies
DELETE FROM kk_lobbies WHERE status = 'finished' AND updated_at < NOW() - INTERVAL 1 HOUR;

-- Update KDA calculations
UPDATE kk_player_stats SET 
    headshot_kda = CASE WHEN headshot_deaths = 0 THEN headshot_kills ELSE ROUND(headshot_kills / headshot_deaths, 2) END,
    bodyshot_kda = CASE WHEN bodyshot_deaths = 0 THEN bodyshot_kills ELSE ROUND(bodyshot_kills / bodyshot_deaths, 2) END,
    helifight_kda = CASE WHEN helifight_deaths = 0 THEN helifight_kills ELSE ROUND(helifight_kills / helifight_deaths, 2) END;
```
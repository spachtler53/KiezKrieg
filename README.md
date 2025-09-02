# KiezKrieg - FiveM Gangwar & Crimelife Framework

## Overview
KiezKrieg is a comprehensive FiveM framework designed for gangwar and crimelife roleplay servers. It provides multiple game modes, faction systems, zone management, and modern UI interfaces.

## Features
- **ESX Legacy Compatible** - Fully integrated with ESX framework
- **Multiple Game Modes**:
  - FreeForAll (FFA) with headshot/bodyshot modes
  - Custom Lobbies with team-based gameplay
  - Helifight (3v3) helicopter combat
  - Gangwar faction battles
- **Modern UI** - Blue-to-pink gradient with rounded corners
- **Zone System** - Colored markers and area management
- **Admin Tools** - Comprehensive admin commands and management
- **Faction System** - Player-created and admin-managed factions
- **Statistics Tracking** - KDA tracking per game mode
- **Routing Buckets** - Isolated gameplay instances

## Installation

### Prerequisites
- ESX Legacy Framework
- oxmysql resource
- MySQL/MariaDB database

### Database Setup
1. Import the database schema:
   ```sql
   source resources/[kiezkrieg]/kk-database/kiezkrieg_database.sql
   ```

### Server Configuration
Add these resources to your `server.cfg`:
```
ensure kk-core
ensure kk-ui
ensure kk-zones
ensure kk-admin
ensure kk-factions
```

### Dependencies
Make sure these resources are started before KiezKrieg:
- es_extended
- oxmysql

## Configuration

### Core Settings
Edit `resources/[kiezkrieg]/kk-core/config/config.lua`:
- Adjust game mode settings
- Configure spawn points
- Modify weapon configurations
- Set admin groups

### Zone Configuration
Default FFA zones are created automatically. To add custom zones:
```sql
INSERT INTO kk_zones (name, type, x, y, z, radius, color, max_players) VALUES
('Custom Zone', 'ffa', 100.0, 200.0, 30.0, 150.0, '#ff6b6b', 15);
```

## Usage

### Player Commands
- `F2` - Open main menu
- `F3` - Leave current FFA zone
- `/faction invite [player_id]` - Invite player to faction (leaders only)
- `/faction leave` - Leave current faction
- `/faction accept` - Accept faction invite
- `/faction decline` - Decline faction invite
- `/faction info` - Show faction information

### Admin Commands
- `/aduty` - Toggle admin duty
- `/goto [player_id]` - Teleport to player
- `/tpm` - Teleport to marker
- `/bring [player_id]` - Bring player to you
- `/vehicle [model]` - Spawn vehicle
- `/dv` - Delete vehicle
- `/nametags` - Toggle nametags
- `/createfaction [name] [label]` - Create faction
- `/deletefaction [name]` - Delete faction

## Game Modes

### FreeForAll (FFA)
- 5 default zones with 100m radius
- Two weapon modes:
  - **Headshot**: Pistol only
  - **Bodyshot**: Special Carbine + Advanced Rifle
- Max 10 players per zone
- Automatic respawning
- Health/armor regeneration

### Custom Lobbies
- Player-created lobbies
- Public/Private with password protection
- 2 teams with balanced gameplay
- Custom vehicle spawns
- Configurable maps

### Helifight
- 3v3 helicopter combat
- Role-based gameplay:
  - Pilot (flying only)
  - Co-Pilot (Revolver)
  - Rear Passenger (Special Carbine)
- Supervolito helicopters
- Round-based matches

### Gangwar
- Faction-based combat
- Open world and private factions
- Leader invitation system
- Territory control

## API

### Core Exports
```lua
-- Get player data
local playerData = exports['kk-core']:GetPlayerData(identifier)

-- Get zones
local zones = exports['kk-core']:GetZones()

-- Check if player is admin
local isAdmin = exports['kk-admin']:IsPlayerAdmin(playerId)

-- Get player faction
local faction = exports['kk-factions']:GetPlayerFaction(identifier)
```

### UI Exports
```lua
-- Show notification
exports['kk-ui']:ShowNotificationToPlayer(playerId, 'Message', 'type')

-- Open menu
exports['kk-ui']:OpenMenuForPlayer(playerId, playerData, zones, config)
```

## Troubleshooting

### Common Issues
1. **Menu not opening**: Check F2 key binding and ESX loading
2. **Database errors**: Verify MySQL connection and table creation
3. **Zone not loading**: Check database entries and resource dependencies
4. **Admin commands not working**: Verify admin group configuration

### Performance Optimization
- Adjust zone check intervals in client scripts
- Limit concurrent players in zones
- Use server-side validation for all actions

## Development

### Adding New Game Modes
1. Create new resource folder
2. Implement server/client logic
3. Add UI integration
4. Update database schema if needed

### Custom Zones
Add zones through the database or admin commands. Each zone supports:
- Custom coordinates and radius
- Player limits
- Color customization
- Type-specific behavior

## Support
For issues and feature requests, please check the resource documentation or contact the development team.

## License
This resource is provided as-is for educational and development purposes.

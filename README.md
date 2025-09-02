# KiezKrieg - FiveM Gangwar & Crimelife Framework

A comprehensive FiveM framework for gangwar and crimelife servers built on ESX Legacy.

## Features

### ✅ Implemented Features

#### Core System
- **ESX Integration**: Full compatibility with ESX Legacy framework
- **Modern UI**: Blue-to-pink gradient design with rounded corners
- **F2 Main Menu**: Comprehensive game mode selection and statistics
- **Auto Character Loading**: Seamless integration with ESX character system
- **Routing Buckets**: Separate dimensions for different game modes
- **MySQL Database**: Complete schema for stats, factions, and configurations

#### Game Modes
- **FreeForAll (FFA)**: 
  - 5 configurable zones with 100m radius
  - Headshot mode (Pistol only)
  - Bodyshot mode (Special Carbine + Advanced Rifle)
  - Max 10 players per zone
  - Visual zone markers and blips

- **Custom Lobbies**: Framework ready for team-based gameplay
- **Helifight (3v3)**: Structure for helicopter combat
- **Gangwar**: Faction-based combat system

#### Admin System
- **F3 Admin Menu**: Comprehensive admin interface
- **Admin Duty**: Toggle admin status
- **Teleportation**: goto, bring, teleport to marker
- **Vehicle Management**: Spawn/delete vehicles
- **Nametags**: Toggle player nametags
- **Faction Management**: Create and manage factions

#### Zone System
- **Visual Markers**: Blue zone indicators on map and in-game
- **Interactive Zones**: Press E to open menu when near zones
- **Configurable Coordinates**: Easy to modify zone locations
- **Map Blips**: Clear zone identification

#### Database System
- **Player Statistics**: KDA tracking per game mode
- **Faction Management**: Complete faction system
- **Match History**: Game tracking and analytics
- **Player Preferences**: Customizable settings
- **Zone Configurations**: Dynamic zone management

## Installation

### Prerequisites
- FiveM Server with TxAdmin
- ESX Legacy Framework
- MySQL/MariaDB Database
- oxmysql resource

### Step-by-Step Installation

1. **Clone or Download**
   ```bash
   git clone https://github.com/spachtler53/KiezKrieg.git
   cd KiezKrieg
   ```

2. **Copy Resources**
   Copy the `resources/[kiezkrieg]/` folder to your FiveM server's resources directory

3. **Configure server.cfg**
   Add these lines to your `server.cfg`:
   ```cfg
   # KiezKrieg Framework
   ensure kk-database
   ensure kk-core
   ensure kk-zones
   ensure kk-admin
   ensure kk-factions
   ```

4. **Database Setup**
   - Ensure your MySQL connection is configured
   - Database tables will be created automatically on first start

5. **Start Server**
   Restart your FiveM server and the resources will initialize

## Usage

### Player Controls
- **F2**: Open main KiezKrieg menu
- **E**: Interact with zones (when near FFA zones)
- **ESC**: Close any open menu

### Admin Controls
- **F3**: Open admin panel (admins only)

### Commands

#### Player Commands
```
/leavegame - Leave current game mode
/faction create [name] - Create new faction
/faction invite [player_id] - Invite player to faction
/faction leave - Leave current faction
/faction info - Show faction information
```

#### Admin Commands
```
/aduty - Toggle admin duty
/goto [player_id] - Teleport to player
/tpm - Teleport to map marker
/bring [player_id] - Bring player to you
/car [model] - Spawn vehicle
/dv - Delete nearby vehicles
/nametags - Toggle nametags
/createfaction [name] - Create faction as admin
```

## Configuration

### Zone Coordinates
Edit `resources/[kiezkrieg]/kk-core/config.lua` to modify zone locations:

```lua
Config.FFAZones = {
    {
        id = 1,
        name = 'Downtown Arena',
        coords = vector3(-265.0, -957.0, 31.0),
        radius = 100.0,
        -- ... more settings
    }
}
```

### Admin Permissions
Configure admin groups in `resources/[kiezkrieg]/kk-admin/config.lua`:

```lua
Config.AdminGroups = {
    'admin',
    'superadmin',
    'owner'
}
```

### Game Mode Settings
Customize weapons and settings in `resources/[kiezkrieg]/kk-core/config.lua`:

```lua
Config.GameModes = {
    FFA = {
        modes = {
            headshot = {
                weapon = 'WEAPON_PISTOL',
                ammo = 250
            }
        }
    }
}
```

## File Structure

```
resources/[kiezkrieg]/
├── kk-core/          # Main framework with UI and game logic
│   ├── client/       # Client-side scripts
│   ├── server/       # Server-side scripts
│   ├── html/         # NUI interface
│   ├── config.lua    # Main configuration
│   └── fxmanifest.lua
├── kk-database/      # Database management
├── kk-zones/         # Zone system and markers
├── kk-admin/         # Admin system
├── kk-factions/      # Faction management
└── README.md         # Documentation
```

## Technical Details

### Routing Buckets
- **FFA**: 1000+ (separate instance per zone)
- **Custom Lobbies**: 2000+
- **Helifight**: 3000+
- **Gangwar**: 4000+

### Database Schema
- `kk_player_stats` - Player statistics and KDA
- `kk_factions` - Faction information and members
- `kk_custom_lobbies` - Custom lobby configurations
- `kk_zones` - Zone definitions and settings
- `kk_match_history` - Game match tracking
- `kk_player_preferences` - User settings

### UI Framework
- Modern CSS with blue-pink gradient
- Responsive design for different screen sizes
- NUI-based interface with smooth animations
- Modular component system

## Development

### Adding New Game Modes
1. Extend the config in `kk-core/config.lua`
2. Add client-side logic in `kk-core/client/main.lua`
3. Implement server-side handling in `kk-core/server/main.lua`
4. Update the UI in `kk-core/html/`

### Creating Custom Zones
1. Add zone data to the database via `kk_zones` table
2. Use the zone system API to create visual markers
3. Implement zone-specific logic in your custom resources

### Extending Admin Features
1. Add new commands to `kk-admin/config.lua`
2. Implement command handlers in `kk-admin/server/main.lua`
3. Update the admin UI if needed

## Support

- **Repository**: [GitHub Repository](https://github.com/spachtler53/KiezKrieg)
- **Issues**: Use GitHub Issues for bug reports
- **Documentation**: Check the README files in each resource folder

## License

This project is open source. Please check the license file for details.

## Credits

Developed by the KiezKrieg Development Team for the FiveM community.

---

**Note**: This framework provides a solid foundation for gangwar servers. Additional game modes and features can be built upon this base system.
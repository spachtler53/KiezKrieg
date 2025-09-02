# KiezKrieg - FiveM Gangwar & Crimelife Framework

## Installation Guide

### Prerequisites
- FiveM Server with TxAdmin
- ESX Legacy Framework
- MySQL/MariaDB Database
- oxmysql resource

### Installation Steps

1. **Extract Resources**
   - Extract all resources to your `resources/[kiezkrieg]/` folder
   - Ensure the folder structure matches the provided layout

2. **Configure server.cfg**
   Add the following to your `server.cfg` file:
   ```cfg
   # KiezKrieg Framework
   ensure kk-database
   ensure kk-core
   ensure kk-zones
   ensure kk-admin
   ensure kk-factions
   ```

3. **Database Setup**
   - The database tables will be created automatically when you start the `kk-database` resource
   - Ensure your MySQL credentials are correctly configured in your server

4. **ESX Configuration**
   - Make sure ESX Legacy is properly installed and running
   - The framework is designed to work with ESX's default setup

### Resource Structure
```
resources/[kiezkrieg]/
├── kk-core/          # Main framework with UI and game modes
├── kk-database/      # Database setup and management
├── kk-zones/         # Zone management and visual markers
├── kk-admin/         # Admin system with F3 menu
├── kk-factions/      # Faction system (to be implemented)
└── README.md         # This file
```

### Features Implemented

#### Core Features
- ✅ ESX Integration
- ✅ Modern UI with blue-to-pink gradient
- ✅ F2 Main Menu
- ✅ Automatic character loading integration
- ✅ MySQL database with comprehensive schema
- ✅ Routing buckets for separate game instances

#### Game Modes
- ✅ FreeForAll (FFA) with headshot/bodyshot modes
- ✅ Zone system with visual markers and blips
- ✅ Custom Lobbies structure
- ✅ Helifight framework
- ✅ Gangwar foundation

#### Admin System
- ✅ F3 Admin Menu
- ✅ Admin duty system
- ✅ Teleportation (goto, bring, tpm)
- ✅ Vehicle spawn/despawn
- ✅ Nametag toggle
- ✅ Faction creation commands

#### Database
- ✅ Player statistics tracking
- ✅ Faction management
- ✅ Custom lobby configurations
- ✅ Zone management
- ✅ Match history
- ✅ Player preferences

### Configuration

#### Zone Coordinates
FFA zones are configured in `kk-core/config.lua`. Default zones include:
- Downtown Arena (-265, -957, 31)
- Airport Battleground (-1037, -2737, 20)
- Beach Combat Zone (-1223, -1491, 4)
- Industrial Warfare (170, -1799, 29)
- Mountain Peak (-1616, 4763, 53)

These coordinates can be easily modified to match your server's map.

#### Admin Permissions
Admin access is controlled via ESX groups in `kk-admin/config.lua`:
- admin
- superadmin
- owner

### Key Bindings
- **F2**: Main KiezKrieg Menu
- **F3**: Admin Menu (for admins only)
- **E**: Interact with zones (when near FFA zones)

### Commands

#### Player Commands
- `/leavegame` - Leave current game mode

#### Admin Commands
- `/aduty` - Toggle admin duty
- `/goto [player_id]` - Teleport to player
- `/tpm` - Teleport to map marker
- `/bring [player_id]` - Bring player to you
- `/car [model]` - Spawn vehicle
- `/dv` - Delete nearby vehicles
- `/nametags` - Toggle nametags
- `/createfaction [name]` - Create new faction

### Customization

#### UI Theming
The UI uses CSS custom properties for easy theming. Main colors can be changed in the CSS files:
- Primary gradient: `linear-gradient(135deg, #667eea 0%, #764ba2 100%)`
- Border radius: `12px` for modern rounded corners

#### Game Mode Settings
All game mode settings are configurable in `kk-core/config.lua`:
- Weapon configurations
- Player limits
- Zone settings
- Vehicle lists

### Troubleshooting

#### Common Issues
1. **Database Connection**: Ensure oxmysql is properly configured
2. **ESX Integration**: Verify ESX Legacy is running before KiezKrieg resources
3. **Admin Access**: Check that your user has the correct ESX group

#### Debug Mode
Enable debug mode in `kk-core/config.lua` by setting `Config.Debug = true` for additional console output.

### Development Notes

#### Routing Buckets
The framework uses routing buckets for dimension separation:
- FFA: Starting at bucket 1000
- Custom Lobbies: Starting at bucket 2000
- Helifight: Starting at bucket 3000
- Gangwar: Starting at bucket 4000

#### Extension Points
The framework is designed to be modular and extensible:
- Add new game modes by extending the core system
- Create custom zones via the database
- Implement additional admin tools
- Extend the faction system

### Support

For support and updates, please refer to the repository documentation or contact the development team.

### Version History
- v1.0.0: Initial release with core features
  - FFA system with zones
  - Admin panel
  - Database structure
  - ESX integration
  - Modern UI implementation
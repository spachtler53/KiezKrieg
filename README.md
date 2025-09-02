# KiezKrieg - FiveM Gangwar & Crimelife Framework

A complete FiveM framework for gangwar and crimelife gameplay, featuring multiple game modes, faction systems, and modern UI design.

## Features

### 🎮 Game Modes
- **FreeForAll (FFA)**: Headshot and Bodyshot modes with zone-based gameplay
- **Custom Lobbies**: Private/Public lobbies with team-based gameplay
- **Helifight**: 3v3 helicopter combat with role assignments
- **Gangwar**: Faction-based open world and private battles

### 🎨 Modern UI
- Blue-to-pink gradient design with rounded corners
- F2 key binding for main menu
- Real-time statistics display (K/D ratios per mode)
- Responsive design for all screen sizes

### 👥 Faction System
- Create and manage factions
- Rank-based permission system
- Invitation and member management
- Public and private faction options

### 🛠️ Admin System
- Admin duty system with noclip and godmode
- Player management (teleport, heal, etc.)
- Vehicle spawning and management
- Comprehensive logging system

### 🗺️ Zone Management
- Visual zone markers and boundaries
- Configurable zone coordinates and settings
- Real-time player count tracking
- Admin zone creation tools

## Installation

### Prerequisites
- ESX Legacy server
- MySQL/MariaDB database
- oxmysql resource

### Step 1: Database Setup
1. Import the database schema:
```sql
SOURCE resources/[kiezkrieg]/kk-database/kiezkrieg_schema.sql;
```

### Step 2: Resource Installation
1. Copy the `resources/[kiezkrieg]/` folder to your FiveM server resources directory
2. Add the following to your `server.cfg`:
```
# KiezKrieg Framework (load in order)
ensure kk-database
ensure kk-core
ensure kk-ui
ensure kk-zones
ensure kk-factions
ensure kk-admin
```

### Step 3: Configuration
1. Configure zone coordinates in `kk-core/shared/config.lua`
2. Adjust admin permissions in `kk-admin/shared/config.lua`
3. Modify faction settings in `kk-factions/shared/config.lua`

## Usage

### For Players
- **F2**: Open main menu
- **Join FFA**: Select zone and mode (headshot/bodyshot)
- **Custom Lobbies**: Create or join custom games
- **Factions**: Create/join factions for gangwar

### For Admins
- **/aduty**: Toggle admin duty
- **F6**: Open admin menu (while on duty)
- **/goto [id]**: Teleport to player
- **/bring [id]**: Bring player to you
- **/tpm**: Teleport to map marker

## Game Modes

### FreeForAll (FFA)
- **Zones**: 5 predefined zones with 100m radius
- **Modes**: 
  - Headshot: Pistol only
  - Bodyshot: Special Carbine + Advanced Rifle
- **Players**: Max 10 per zone
- **Routing**: Separate dimensions for each game

### Custom Lobbies
- **Teams**: 2 teams with no friendly fire
- **Vehicles**: Drafter, Schafter, Jugular, Revolter available
- **Maps**: Multiple selectable maps
- **Privacy**: Public or password-protected

### Helifight
- **Teams**: 3v3 helicopter combat
- **Roles**: Pilot, Co-Pilot (Revolver), Rear (Special Carbine)
- **Vehicle**: Supervolito helicopters
- **Rounds**: Up to 15 rounds per match

### Gangwar
- **Open World**: Dynamic faction-based combat
- **Private Factions**: Admin-created exclusive factions
- **Territory**: Zone-based control system

## Configuration

### Zone Configuration
```lua
-- Example zone configuration
{
    id = 1,
    name = "Downtown FFA",
    coords = vector3(-1037.0, -2737.0, 20.2),
    radius = 100.0,
    maxPlayers = 10,
    color = {r = 0, g = 100, b = 255, a = 100}
}
```

### Weapons Configuration
```lua
-- Mode-specific weapons
HEADSHOT_MODE = {
    primary = GetHashKey("WEAPON_PISTOL")
},
BODYSHOT_MODE = {
    primary = GetHashKey("WEAPON_SPECIALCARBINE"),
    secondary = GetHashKey("WEAPON_ADVANCEDRIFLE")
}
```

## Database Tables

- `kk_player_stats`: Player statistics per game mode
- `kk_factions`: Faction information
- `kk_faction_members`: Faction membership
- `kk_lobbies`: Custom lobby data
- `kk_zones`: Zone configurations
- `kk_user_preferences`: Player preferences
- `kk_admin_logs`: Administrative actions
- `kk_game_sessions`: Active game tracking

## Technical Features

### ESX Integration
- Automatic character loading
- ESX money system integration
- Permission-based admin system
- Player data persistence

### Routing Buckets
- Separate dimensions for each game mode
- Isolated player instances
- No interference between games

### Modern Architecture
- Modular resource structure
- Event-driven communication
- Efficient database queries
- Optimized client performance

## Development

### Adding New Zones
1. Add zone data to `kk-core/shared/config.lua`
2. Update database with new zone entry
3. Restart `kk-zones` resource

### Adding New Game Modes
1. Define mode in `KiezKrieg.GAME_MODES`
2. Create client/server handlers
3. Add UI elements for mode selection
4. Implement routing bucket logic

### Customizing UI
- Modify `kk-ui/html/css/style.css` for styling
- Update `kk-ui/html/index.html` for structure
- Extend `kk-ui/html/js/main.js` for functionality

## Support

### Troubleshooting
- Check server console for error messages
- Verify database connection and tables
- Ensure proper resource load order
- Check ESX compatibility

### Performance
- Optimized for 32+ players
- Efficient zone detection
- Minimal client impact
- Database query optimization

## License

This framework is provided as-is for educational and development purposes.

## Credits

Developed by the KiezKrieg Team for the FiveM community.

---

**Version**: 1.0.0  
**Compatibility**: ESX Legacy, FiveM  
**Database**: MySQL/MariaDB with oxmysql

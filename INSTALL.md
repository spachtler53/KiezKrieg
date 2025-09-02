# KiezKrieg Installation Guide

## Prerequisites

1. **FiveM Server** - Windows 2019 with TxAdmin
2. **ESX Legacy Framework** - Latest version
3. **oxmysql Resource** - For database connectivity
4. **MySQL/MariaDB Database** - For data storage

## Step-by-Step Installation

### 1. Database Setup

1. Connect to your MySQL database
2. Execute the database schema:
   ```bash
   mysql -u username -p database_name < resources/[kiezkrieg]/kk-database/kiezkrieg_database.sql
   ```

### 2. Resource Installation

1. Copy the entire `resources/[kiezkrieg]/` folder to your server's resources directory
2. Ensure the folder structure looks like this:
   ```
   resources/
   └── [kiezkrieg]/
       ├── kk-core/
       ├── kk-ui/
       ├── kk-zones/
       ├── kk-admin/
       ├── kk-factions/
       └── kk-database/
   ```

### 3. Server Configuration

Add these lines to your `server.cfg` (order matters):
```cfg
# KiezKrieg Framework - Add AFTER ESX and oxmysql
ensure kk-core
ensure kk-ui
ensure kk-zones
ensure kk-admin
ensure kk-factions
```

### 4. ESX Configuration

Ensure your ESX groups include admin permissions. Edit your ESX database:
```sql
-- Add admin groups if they don't exist
INSERT IGNORE INTO addon_account (name, label, shared) VALUES 
('admin_account', 'Admin Account', 0);

-- Ensure admin groups exist in your user management
```

### 5. TxAdmin Configuration

In TxAdmin, add the following permissions for your admin group:
- `kk.admin.commands` - Basic admin commands
- `kk.admin.factions` - Faction management
- `kk.admin.zones` - Zone management

### 6. First Launch

1. Start your server
2. Connect as an admin
3. Use `/aduty` to enable admin mode
4. Test the F2 menu
5. Create a test faction: `/createfaction test "Test Faction"`

## Configuration

### Admin Groups
Edit `resources/[kiezkrieg]/kk-core/config/config.lua`:
```lua
Config.Admin = {
    groups = {'admin', 'superadmin', 'owner', 'mod'}, -- Add your admin groups here
    -- ... rest of config
}
```

### Zone Customization
To add custom FFA zones, use SQL or admin commands:
```sql
INSERT INTO kk_zones (name, type, x, y, z, radius, color, max_players) VALUES
('Airport FFA', 'ffa', -1037.8, -2737.9, 20.2, 150.0, '#e74c3c', 12);
```

### Spawn Points
Modify spawn points in the config file:
```lua
Config.SpawnPoints = {
    lobby = {
        {x = -1037.8, y = -2737.9, z = 20.2, h = 240.0} -- Change to your lobby location
    },
    -- ... other spawn points
}
```

## Testing

### Test Checklist
- [ ] Server starts without errors
- [ ] Database tables are created
- [ ] F2 menu opens correctly
- [ ] FFA zones appear on map
- [ ] Admin commands work with `/aduty`
- [ ] Faction system allows creation/joining
- [ ] Players can join FFA zones
- [ ] Statistics are tracked correctly

### Common Issues

**Menu doesn't open:**
- Check console for JavaScript errors
- Verify ESX is loaded before KiezKrieg
- Ensure oxmysql is working

**Database errors:**
- Verify MySQL credentials
- Check if tables were created successfully
- Ensure oxmysql resource is running

**Admin commands not working:**
- Check if player group is in Config.Admin.groups
- Verify permissions in ESX
- Try `/aduty` first

**Zones not visible:**
- Check database for zone entries
- Verify coordinates are valid
- Restart kk-zones resource

## Performance Optimization

### Server Resources
- Recommended: 2GB+ RAM
- MySQL on SSD storage recommended
- Good network connectivity for smooth gameplay

### Configuration Tweaks
```lua
-- In config.lua, adjust these for performance:
Config.Zones.drawDistance = 50.0  -- Reduce for better performance
-- Zone check interval in client scripts (increase for better performance)
```

## Support

If you encounter issues:
1. Check server console for errors
2. Verify all dependencies are installed
3. Test with a minimal server setup
4. Check the README.md for API documentation

## Updates

To update KiezKrieg:
1. Backup your database
2. Replace resource files
3. Check for new database migrations
4. Restart affected resources
5. Test functionality

Remember to always backup your database before making changes!
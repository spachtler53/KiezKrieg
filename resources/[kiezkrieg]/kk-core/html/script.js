let currentMode = 'headshot';
let playerStats = {};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeMenu();
    setupEventListeners();
});

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'showMainMenu':
            playerStats = data.stats;
            updateStatsDisplay();
            showMenu();
            break;
        case 'hideMainMenu':
            hideMenu();
            break;
    }
});

function initializeMenu() {
    // Initialize FFA zones
    populateFFAZones();
    
    // Initialize custom lobbies
    populateCustomLobbies();
}

function setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            switchTab(this.dataset.tab);
        });
    });
    
    // Mode switching for FFA
    document.querySelectorAll('.mode-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            switchMode(this.dataset.mode);
        });
    });
    
    // Close menu
    document.getElementById('close-menu-btn').addEventListener('click', function() {
        closeMenu();
    });
    
    // Create lobby modal
    document.getElementById('create-lobby-btn').addEventListener('click', function() {
        showCreateLobbyModal();
    });
    
    document.getElementById('cancel-create-btn').addEventListener('click', function() {
        hideCreateLobbyModal();
    });
    
    document.getElementById('create-lobby-form').addEventListener('submit', function(e) {
        e.preventDefault();
        createCustomLobby();
    });
    
    // Helifight
    document.getElementById('join-helifight-btn').addEventListener('click', function() {
        joinHelifight();
    });
    
    // Gangwar
    document.getElementById('join-gangwar-btn').addEventListener('click', function() {
        joinGangwar();
    });
    
    // Faction buttons
    document.getElementById('create-faction-btn').addEventListener('click', function() {
        createFaction();
    });
    
    document.getElementById('manage-faction-btn').addEventListener('click', function() {
        manageFaction();
    });
    
    // ESC key to close
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeMenu();
        }
    });
}

function switchTab(tabName) {
    // Remove active class from all tabs and content
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
    
    // Add active class to selected tab
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    document.getElementById(`${tabName}-tab`).classList.add('active');
}

function switchMode(mode) {
    currentMode = mode;
    
    // Update mode button styling
    document.querySelectorAll('.mode-btn').forEach(btn => btn.classList.remove('active'));
    document.querySelector(`[data-mode="${mode}"]`).classList.add('active');
    
    // Update zone display based on mode
    populateFFAZones();
}

function updateStatsDisplay() {
    // Update KDA displays
    document.getElementById('ffa-headshot-kda').textContent = 
        `${playerStats.ffa_headshot.kills}/${playerStats.ffa_headshot.deaths}/${playerStats.ffa_headshot.assists}`;
    
    document.getElementById('ffa-bodyshot-kda').textContent = 
        `${playerStats.ffa_bodyshot.kills}/${playerStats.ffa_bodyshot.deaths}/${playerStats.ffa_bodyshot.assists}`;
    
    document.getElementById('custom-lobby-kda').textContent = 
        `${playerStats.custom_lobby.kills}/${playerStats.custom_lobby.deaths}/${playerStats.custom_lobby.assists}`;
    
    document.getElementById('helifight-kda').textContent = 
        `${playerStats.helifight.kills}/${playerStats.helifight.deaths}/${playerStats.helifight.assists}`;
    
    document.getElementById('gangwar-kda').textContent = 
        `${playerStats.gangwar.kills}/${playerStats.gangwar.deaths}/${playerStats.gangwar.assists}`;
}

function populateFFAZones() {
    const zonesContainer = document.getElementById('ffa-zones');
    zonesContainer.innerHTML = '';
    
    // These would normally come from the server, but we'll use the config data
    const zones = [
        { id: 1, name: 'Downtown Arena', players: '3/10' },
        { id: 2, name: 'Airport Battleground', players: '7/10' },
        { id: 3, name: 'Beach Combat Zone', players: '1/10' },
        { id: 4, name: 'Industrial Warfare', players: '5/10' },
        { id: 5, name: 'Mountain Peak', players: '0/10' }
    ];
    
    zones.forEach(zone => {
        const zoneElement = document.createElement('div');
        zoneElement.className = 'zone-item';
        zoneElement.innerHTML = `
            <div class="zone-name">${zone.name}</div>
            <div class="zone-info">
                <div>Mode: ${currentMode.charAt(0).toUpperCase() + currentMode.slice(1)}</div>
                <div>Players: ${zone.players}</div>
            </div>
        `;
        
        zoneElement.addEventListener('click', function() {
            joinFFA(zone.id);
        });
        
        zonesContainer.appendChild(zoneElement);
    });
}

function populateCustomLobbies() {
    const lobbiesContainer = document.getElementById('custom-lobbies');
    lobbiesContainer.innerHTML = '';
    
    // Sample lobbies - these would come from server
    const lobbies = [
        { id: 1, name: 'Team Deathmatch #1', players: '12/20', hasPassword: false },
        { id: 2, name: 'Private Match', players: '4/10', hasPassword: true },
        { id: 3, name: 'Tournament Final', players: '18/20', hasPassword: false }
    ];
    
    lobbies.forEach(lobby => {
        const lobbyElement = document.createElement('div');
        lobbyElement.className = 'lobby-item';
        lobbyElement.innerHTML = `
            <div class="lobby-name">${lobby.name}</div>
            <div class="lobby-info">
                <div>Players: ${lobby.players}</div>
                <div>${lobby.hasPassword ? '🔒 Password Protected' : '🌐 Public'}</div>
            </div>
        `;
        
        lobbyElement.addEventListener('click', function() {
            joinCustomLobby(lobby.id);
        });
        
        lobbiesContainer.appendChild(lobbyElement);
    });
}

function showMenu() {
    document.getElementById('mainMenu').style.display = 'block';
}

function hideMenu() {
    document.getElementById('mainMenu').style.display = 'none';
}

function closeMenu() {
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

function joinFFA(zoneId) {
    fetch(`https://${GetParentResourceName()}/joinFFA`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            mode: currentMode,
            zoneId: zoneId
        })
    });
}

function showCreateLobbyModal() {
    document.getElementById('create-lobby-modal').style.display = 'flex';
}

function hideCreateLobbyModal() {
    document.getElementById('create-lobby-modal').style.display = 'none';
}

function createCustomLobby() {
    const formData = new FormData(document.getElementById('create-lobby-form'));
    const lobbyData = {
        name: formData.get('lobby-name') || document.getElementById('lobby-name').value,
        password: formData.get('lobby-password') || document.getElementById('lobby-password').value,
        maxPlayers: parseInt(formData.get('max-players') || document.getElementById('max-players').value)
    };
    
    fetch(`https://${GetParentResourceName()}/createCustomLobby`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(lobbyData)
    });
    
    hideCreateLobbyModal();
}

function joinCustomLobby(lobbyId) {
    fetch(`https://${GetParentResourceName()}/joinCustomLobby`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            lobbyId: lobbyId
        })
    });
}

function joinHelifight() {
    const rounds = parseInt(document.getElementById('rounds-select').value);
    
    fetch(`https://${GetParentResourceName()}/joinHelifight`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            rounds: rounds
        })
    });
}

function joinGangwar() {
    fetch(`https://${GetParentResourceName()}/joinGangwar`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

function createFaction() {
    // This would open another modal for faction creation
    alert('Faction creation coming soon!');
}

function manageFaction() {
    // This would open faction management interface
    alert('Faction management coming soon!');
}

// Helper function to get current resource name
function GetParentResourceName() {
    return 'kk-core';
}
// KiezKrieg Main Menu JavaScript
let currentStats = {};
let currentZones = [];
let selectedMode = 'headshot';

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
});

// Setup event listeners
function setupEventListeners() {
    // Mode selector buttons
    document.querySelectorAll('.mode-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            document.querySelectorAll('.mode-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            selectedMode = this.dataset.mode;
            updateZoneCards();
        });
    });

    // Close menu with ESC key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeMenu();
        }
    });
}

// Listen for messages from FiveM
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openMenu':
            openMenu(data.stats, data.zones);
            break;
        case 'closeMenu':
            closeMenu();
            break;
        case 'updateStats':
            updateStats(data.stats);
            break;
    }
});

// Open menu with data
function openMenu(stats, zones) {
    currentStats = stats || {};
    currentZones = zones || [];
    
    updateStats(currentStats);
    updateZoneCards();
    
    document.getElementById('main-container').classList.remove('hidden');
    document.body.style.overflow = 'hidden';
}

// Close menu
function closeMenu() {
    document.getElementById('main-container').classList.add('hidden');
    document.body.style.overflow = 'auto';
    
    // Send close message to FiveM
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Update stats display
function updateStats(stats) {
    if (!stats) return;
    
    // Headshot stats
    if (stats.headshot) {
        document.getElementById('headshot-kills').textContent = stats.headshot.kills || 0;
        document.getElementById('headshot-deaths').textContent = stats.headshot.deaths || 0;
        document.getElementById('headshot-kda').textContent = (stats.headshot.kda || 0).toFixed(2);
    }
    
    // Bodyshot stats
    if (stats.bodyshot) {
        document.getElementById('bodyshot-kills').textContent = stats.bodyshot.kills || 0;
        document.getElementById('bodyshot-deaths').textContent = stats.bodyshot.deaths || 0;
        document.getElementById('bodyshot-kda').textContent = (stats.bodyshot.kda || 0).toFixed(2);
    }
    
    // Helifight stats
    if (stats.helifight) {
        document.getElementById('helifight-kills').textContent = stats.helifight.kills || 0;
        document.getElementById('helifight-deaths').textContent = stats.helifight.deaths || 0;
        document.getElementById('helifight-kda').textContent = (stats.helifight.kda || 0).toFixed(2);
    }
}

// Show category
function showCategory(categoryName) {
    // Update nav buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    
    // Hide all categories
    document.querySelectorAll('.category-content').forEach(content => {
        content.classList.add('hidden');
    });
    
    // Show selected category
    const category = document.getElementById(`category-${categoryName}`);
    if (category) {
        category.classList.remove('hidden');
    }
    
    // Load category-specific data
    if (categoryName === 'ffa') {
        updateZoneCards();
    } else if (categoryName === 'lobbies') {
        refreshLobbies();
    }
}

// Update zone cards
function updateZoneCards() {
    const zonesContainer = document.getElementById('ffa-zones');
    if (!zonesContainer) return;
    
    zonesContainer.innerHTML = '';
    
    currentZones.forEach(zone => {
        const zoneCard = document.createElement('div');
        zoneCard.className = 'zone-card';
        zoneCard.onclick = () => joinFFA(zone.id);
        
        zoneCard.innerHTML = `
            <h4>${zone.name}</h4>
            <div class="zone-info">
                <p>Radius: ${zone.radius}m</p>
                <p>Mode: ${selectedMode.charAt(0).toUpperCase() + selectedMode.slice(1)}</p>
            </div>
            <div class="zone-players">Players: 0/${zone.maxPlayers}</div>
            <button class="action-btn primary">Join Zone</button>
        `;
        
        zonesContainer.appendChild(zoneCard);
    });
}

// Join FFA
function joinFFA(zoneId) {
    fetch(`https://${GetParentResourceName()}/joinFFA`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            mode: selectedMode,
            zoneId: zoneId
        })
    });
}

// Create lobby functions
function showCreateLobby() {
    document.getElementById('create-lobby-form').classList.remove('hidden');
}

function hideCreateLobby() {
    document.getElementById('create-lobby-form').classList.add('hidden');
    // Clear form
    document.getElementById('lobby-name').value = '';
    document.getElementById('lobby-password').value = '';
    document.getElementById('lobby-map').value = 'default';
    document.getElementById('lobby-maxplayers').value = '10';
}

function createLobby() {
    const name = document.getElementById('lobby-name').value.trim();
    const password = document.getElementById('lobby-password').value;
    const map = document.getElementById('lobby-map').value;
    const maxPlayers = parseInt(document.getElementById('lobby-maxplayers').value);
    
    if (!name) {
        alert('Please enter a lobby name');
        return;
    }
    
    if (maxPlayers < 2 || maxPlayers > 20) {
        alert('Max players must be between 2 and 20');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/createLobby`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            name: name,
            password: password,
            map: map,
            maxPlayers: maxPlayers,
            isPrivate: password.length > 0
        })
    });
    
    hideCreateLobby();
}

// Refresh lobbies
function refreshLobbies() {
    const lobbiesContainer = document.getElementById('lobbies-list');
    lobbiesContainer.innerHTML = '<p style="text-align: center; opacity: 0.7;">Loading lobbies...</p>';
    
    // This would typically fetch from server
    setTimeout(() => {
        lobbiesContainer.innerHTML = '<p style="text-align: center; opacity: 0.7;">No active lobbies found</p>';
    }, 1000);
}

// Join lobby
function joinLobby(lobbyId, isPrivate) {
    let password = '';
    
    if (isPrivate) {
        password = prompt('Enter lobby password:');
        if (password === null) return; // User cancelled
    }
    
    fetch(`https://${GetParentResourceName()}/joinLobby`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            lobbyId: lobbyId,
            password: password
        })
    });
}

// Join Helifight
function joinHelifight() {
    fetch(`https://${GetParentResourceName()}/joinHelifight`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Open faction menu
function openFactionMenu() {
    fetch(`https://${GetParentResourceName()}/openFactionMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Utility function to get parent resource name
function GetParentResourceName() {
    return window.location.hostname === 'nui-game' ? 'kk-core' : 'kk-core';
}
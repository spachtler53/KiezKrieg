let isOnDuty = false;
let showNametags = false;

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
});

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'showAdminMenu':
            isOnDuty = data.isOnDuty;
            showNametags = data.showNametags;
            updateUI();
            showMenu();
            break;
        case 'hideAdminMenu':
            hideMenu();
            break;
    }
});

function setupEventListeners() {
    // Close menu
    document.getElementById('close-admin-btn').addEventListener('click', function() {
        closeMenu();
    });
    
    // Toggle duty
    document.getElementById('toggle-duty-btn').addEventListener('click', function() {
        toggleDuty();
    });
    
    // Teleportation
    document.getElementById('goto-btn').addEventListener('click', function() {
        const playerId = document.getElementById('goto-player-id').value;
        if (playerId) {
            gotoPlayer(parseInt(playerId));
        }
    });
    
    document.getElementById('bring-btn').addEventListener('click', function() {
        const playerId = document.getElementById('bring-player-id').value;
        if (playerId) {
            bringPlayer(parseInt(playerId));
        }
    });
    
    document.getElementById('tpm-btn').addEventListener('click', function() {
        teleportToMarker();
    });
    
    // Vehicle management
    document.getElementById('spawn-vehicle-btn').addEventListener('click', function() {
        const model = document.getElementById('vehicle-model').value;
        if (model) {
            spawnVehicle(model);
        }
    });
    
    document.getElementById('delete-vehicles-btn').addEventListener('click', function() {
        deleteVehicles();
    });
    
    // Display options
    document.getElementById('toggle-nametags-btn').addEventListener('click', function() {
        toggleNametags();
    });
    
    // Faction management
    document.getElementById('create-faction-btn').addEventListener('click', function() {
        const factionName = document.getElementById('faction-name').value;
        if (factionName) {
            createFaction(factionName);
        }
    });
    
    // ESC key to close
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeMenu();
        }
    });
}

function updateUI() {
    // Update duty status
    const dutyStatusText = document.getElementById('duty-status-text');
    const dutyBtn = document.getElementById('toggle-duty-btn');
    
    if (isOnDuty) {
        dutyStatusText.textContent = 'On Duty';
        dutyStatusText.className = 'status-on';
        dutyBtn.classList.add('on-duty');
    } else {
        dutyStatusText.textContent = 'Off Duty';
        dutyStatusText.className = 'status-off';
        dutyBtn.classList.remove('on-duty');
    }
    
    // Update nametags button
    const nametagsBtn = document.getElementById('toggle-nametags-btn');
    nametagsBtn.textContent = showNametags ? 'Hide Nametags' : 'Show Nametags';
}

function showMenu() {
    document.getElementById('adminMenu').style.display = 'block';
    populatePlayerList();
}

function hideMenu() {
    document.getElementById('adminMenu').style.display = 'none';
}

function closeMenu() {
    fetch(`https://${GetParentResourceName()}/closeAdminMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

function toggleDuty() {
    fetch(`https://${GetParentResourceName()}/toggleDuty`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
    
    // Toggle local state for immediate UI feedback
    isOnDuty = !isOnDuty;
    updateUI();
}

function gotoPlayer(playerId) {
    fetch(`https://${GetParentResourceName()}/gotoPlayer`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ playerId: playerId })
    });
    
    // Clear input
    document.getElementById('goto-player-id').value = '';
}

function bringPlayer(playerId) {
    fetch(`https://${GetParentResourceName()}/bringPlayer`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ playerId: playerId })
    });
    
    // Clear input
    document.getElementById('bring-player-id').value = '';
}

function teleportToMarker() {
    fetch(`https://${GetParentResourceName()}/teleportToMarker`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

function spawnVehicle(model) {
    fetch(`https://${GetParentResourceName()}/spawnVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ model: model })
    });
    
    // Clear input
    document.getElementById('vehicle-model').value = '';
}

function deleteVehicles() {
    fetch(`https://${GetParentResourceName()}/deleteVehicles`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

function toggleNametags() {
    fetch(`https://${GetParentResourceName()}/toggleNametags`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
    
    // Toggle local state for immediate UI feedback
    showNametags = !showNametags;
    updateUI();
}

function createFaction(factionName) {
    fetch(`https://${GetParentResourceName()}/createFaction`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name: factionName })
    });
    
    // Clear input
    document.getElementById('faction-name').value = '';
}

function populatePlayerList() {
    const playerListContainer = document.getElementById('player-list');
    playerListContainer.innerHTML = '';
    
    // This would normally get real player data from the server
    // For now, we'll show a placeholder
    const placeholder = document.createElement('div');
    placeholder.className = 'player-item';
    placeholder.innerHTML = `
        <div class="player-info">
            <span class="player-name">Player list will be populated</span>
            <span class="player-id">when integrated with server</span>
        </div>
    `;
    
    playerListContainer.appendChild(placeholder);
}

function createPlayerItem(player) {
    const playerElement = document.createElement('div');
    playerElement.className = 'player-item';
    playerElement.innerHTML = `
        <div class="player-info">
            <span class="player-name">${player.name}</span>
            <span class="player-id">ID: ${player.id}</span>
        </div>
        <div class="player-actions">
            <button class="player-action-btn" onclick="gotoPlayer(${player.id})">Goto</button>
            <button class="player-action-btn" onclick="bringPlayer(${player.id})">Bring</button>
        </div>
    `;
    
    return playerElement;
}

// Helper function to get current resource name
function GetParentResourceName() {
    return 'kk-admin';
}
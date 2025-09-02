// KiezKrieg UI JavaScript
class KiezKriegUI {
    constructor() {
        this.currentTab = 'ffa';
        this.selectedWeaponMode = 'headshot';
        this.playerData = null;
        this.zones = {};
        this.config = {};
        
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.setupTabSwitching();
        this.setupWeaponModeSelection();
        this.setupModalHandlers();
        
        // Listen for messages from the game
        window.addEventListener('message', this.handleMessage.bind(this));
    }
    
    bindEvents() {
        // Close menu
        document.getElementById('closeMenuBtn').addEventListener('click', () => {
            this.closeMenu();
        });
        
        // Settings save
        document.getElementById('saveSettingsBtn').addEventListener('click', () => {
            this.saveSettings();
        });
        
        // Create lobby
        document.getElementById('createLobbyBtn').addEventListener('click', () => {
            this.showCreateLobbyModal();
        });
        
        // Refresh lobbies
        document.getElementById('refreshLobbiesBtn').addEventListener('click', () => {
            this.refreshLobbies();
        });
        
        // Join helifight
        document.getElementById('joinHelifightBtn').addEventListener('click', () => {
            this.joinHelifight();
        });
        
        // Join gangwar
        document.getElementById('joinGangwarBtn').addEventListener('click', () => {
            this.joinGangwar();
        });
        
        // Private lobby toggle
        document.getElementById('lobbyPrivate').addEventListener('change', (e) => {
            const passwordGroup = document.getElementById('passwordGroup');
            passwordGroup.style.display = e.target.checked ? 'block' : 'none';
        });
        
        // ESC key to close menu
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeMenu();
            }
        });
    }
    
    setupTabSwitching() {
        const tabs = document.querySelectorAll('.nav-tab');
        const tabPanes = document.querySelectorAll('.tab-pane');
        
        tabs.forEach(tab => {
            tab.addEventListener('click', () => {
                // Remove active class from all tabs and panes
                tabs.forEach(t => t.classList.remove('active'));
                tabPanes.forEach(pane => pane.classList.remove('active'));
                
                // Add active class to clicked tab
                tab.classList.add('active');
                
                // Show corresponding tab pane
                const tabId = tab.getAttribute('data-tab');
                const targetPane = document.getElementById(`${tabId}-tab`);
                if (targetPane) {
                    targetPane.classList.add('active');
                    this.currentTab = tabId;
                }
            });
        });
    }
    
    setupWeaponModeSelection() {
        const weaponModes = document.querySelectorAll('.weapon-mode-btn');
        
        weaponModes.forEach(btn => {
            btn.addEventListener('click', () => {
                weaponModes.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this.selectedWeaponMode = btn.getAttribute('data-mode');
            });
        });
    }
    
    setupModalHandlers() {
        // Create lobby modal
        const modal = document.getElementById('createLobbyModal');
        const cancelBtn = document.getElementById('cancelCreateLobby');
        const confirmBtn = document.getElementById('confirmCreateLobby');
        const closeBtn = modal.querySelector('.modal-close');
        
        [cancelBtn, closeBtn].forEach(btn => {
            btn.addEventListener('click', () => {
                this.hideCreateLobbyModal();
            });
        });
        
        confirmBtn.addEventListener('click', () => {
            this.createLobby();
        });
        
        // Close modal on outside click
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                this.hideCreateLobbyModal();
            }
        });
    }
    
    handleMessage(event) {
        const data = event.data;
        
        switch (data.type) {
            case 'openMenu':
                this.openMenu(data.playerData, data.zones, data.config);
                break;
            case 'closeMenu':
                this.closeMenu();
                break;
            case 'showNotification':
                this.showNotification(data.message, data.notificationType);
                break;
            case 'updatePlayerData':
                this.updatePlayerData(data.playerData);
                break;
            case 'updateZones':
                this.updateZones(data.zones);
                break;
            case 'updateLobbies':
                this.updateLobbies(data.lobbies);
                break;
        }
    }
    
    openMenu(playerData, zones, config) {
        this.playerData = playerData;
        this.zones = zones;
        this.config = config;
        
        this.updateUI();
        this.populateZones();
        this.loadSettings();
        
        document.getElementById('app').classList.remove('hidden');
    }
    
    closeMenu() {
        document.getElementById('app').classList.add('hidden');
        
        // Send close message to game
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
    
    updateUI() {
        if (!this.playerData) return;
        
        // Update player name
        document.getElementById('playerName').textContent = this.playerData.playerName;
        
        // Update overall KDA
        const overallKDA = this.calculateOverallKDA();
        document.getElementById('overallKDA').textContent = overallKDA.toFixed(2);
        
        // Update mode-specific KDAs
        this.updateModeKDAs();
    }
    
    calculateOverallKDA() {
        if (!this.playerData || !this.playerData.stats) return 0;
        
        const stats = this.playerData.stats;
        const totalKills = stats.headshot.kills + stats.bodyshot.kills + 
                          stats.ffa.kills + stats.custom.kills + 
                          stats.helifight.kills + stats.gangwar.kills;
        const totalDeaths = stats.headshot.deaths + stats.bodyshot.deaths + 
                           stats.ffa.deaths + stats.custom.deaths + 
                           stats.helifight.deaths + stats.gangwar.deaths;
        
        return totalDeaths > 0 ? totalKills / totalDeaths : totalKills;
    }
    
    updateModeKDAs() {
        if (!this.playerData || !this.playerData.stats) return;
        
        const stats = this.playerData.stats;
        
        // Headshot KDA
        const headshotKDA = stats.headshot.deaths > 0 ? 
            stats.headshot.kills / stats.headshot.deaths : stats.headshot.kills;
        document.getElementById('headshotKDA').textContent = headshotKDA.toFixed(2);
        
        // Bodyshot KDA
        const bodyshotKDA = stats.bodyshot.deaths > 0 ? 
            stats.bodyshot.kills / stats.bodyshot.deaths : stats.bodyshot.kills;
        document.getElementById('bodyshotKDA').textContent = bodyshotKDA.toFixed(2);
        
        // Custom KDA
        const customKDA = stats.custom.deaths > 0 ? 
            stats.custom.kills / stats.custom.deaths : stats.custom.kills;
        document.getElementById('customKDA').textContent = customKDA.toFixed(2);
        
        // Helifight KDA
        const helifightKDA = stats.helifight.deaths > 0 ? 
            stats.helifight.kills / stats.helifight.deaths : stats.helifight.kills;
        document.getElementById('helifightKDA').textContent = helifightKDA.toFixed(2);
        
        // Gangwar KDA
        const gangwarKDA = stats.gangwar.deaths > 0 ? 
            stats.gangwar.kills / stats.gangwar.deaths : stats.gangwar.kills;
        document.getElementById('gangwarKDA').textContent = gangwarKDA.toFixed(2);
    }
    
    populateZones() {
        const ffaZonesList = document.getElementById('ffaZonesList');
        ffaZonesList.innerHTML = '';
        
        Object.values(this.zones).forEach(zone => {
            if (zone.type === 'ffa') {
                const zoneCard = this.createZoneCard(zone);
                ffaZonesList.appendChild(zoneCard);
            }
        });
    }
    
    createZoneCard(zone) {
        const card = document.createElement('div');
        card.className = 'zone-card';
        card.innerHTML = `
            <div class="zone-name">${zone.name}</div>
            <div class="zone-info">
                <span>Players:</span>
                <span class="zone-players">${zone.currentPlayers ? zone.currentPlayers.length : 0}/${zone.maxPlayers}</span>
            </div>
        `;
        
        card.addEventListener('click', () => {
            this.joinFFA(zone.id);
        });
        
        return card;
    }
    
    joinFFA(zoneId) {
        fetch(`https://${GetParentResourceName()}/joinFFA`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                zoneId: zoneId,
                weaponMode: this.selectedWeaponMode
            })
        });
    }
    
    joinHelifight() {
        fetch(`https://${GetParentResourceName()}/joinHelifight`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
    
    joinGangwar() {
        fetch(`https://${GetParentResourceName()}/joinGangwar`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
    
    showCreateLobbyModal() {
        document.getElementById('createLobbyModal').classList.remove('hidden');
    }
    
    hideCreateLobbyModal() {
        document.getElementById('createLobbyModal').classList.add('hidden');
        // Clear form
        document.getElementById('lobbyName').value = '';
        document.getElementById('lobbyMaxPlayers').value = '20';
        document.getElementById('lobbyPrivate').checked = false;
        document.getElementById('lobbyPassword').value = '';
        document.getElementById('passwordGroup').style.display = 'none';
    }
    
    createLobby() {
        const name = document.getElementById('lobbyName').value.trim();
        const maxPlayers = parseInt(document.getElementById('lobbyMaxPlayers').value);
        const isPrivate = document.getElementById('lobbyPrivate').checked;
        const password = document.getElementById('lobbyPassword').value;
        
        if (!name || name.length < 3) {
            this.showNotification('Lobby name must be at least 3 characters', 'error');
            return;
        }
        
        if (isPrivate && !password) {
            this.showNotification('Private lobbies require a password', 'error');
            return;
        }
        
        fetch(`https://${GetParentResourceName()}/createCustomLobby`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                name: name,
                maxPlayers: maxPlayers,
                isPrivate: isPrivate,
                password: password
            })
        });
        
        this.hideCreateLobbyModal();
    }
    
    refreshLobbies() {
        // This would typically request updated lobby data from the server
        this.showNotification('Refreshing lobbies...', 'info');
    }
    
    loadSettings() {
        if (!this.playerData || !this.playerData.preferences) return;
        
        const prefs = this.playerData.preferences;
        
        document.getElementById('autoOpenMenu').checked = prefs.autoOpenMenu;
        document.getElementById('preferredWeaponMode').value = prefs.preferredWeaponMode;
        document.getElementById('soundEnabled').checked = prefs.soundEnabled;
        document.getElementById('notificationsEnabled').checked = prefs.notificationsEnabled;
    }
    
    saveSettings() {
        const preferences = {
            autoOpenMenu: document.getElementById('autoOpenMenu').checked,
            preferredWeaponMode: document.getElementById('preferredWeaponMode').value,
            uiColorTheme: 'blue_pink', // Fixed for now
            soundEnabled: document.getElementById('soundEnabled').checked,
            notificationsEnabled: document.getElementById('notificationsEnabled').checked
        };
        
        fetch(`https://${GetParentResourceName()}/updatePreferences`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(preferences)
        });
        
        this.showNotification('Settings saved!', 'success');
    }
    
    showNotification(message, type = 'info') {
        const container = document.getElementById('notifications');
        
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        container.appendChild(notification);
        
        // Remove notification after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 5000);
    }
    
    updatePlayerData(playerData) {
        this.playerData = playerData;
        this.updateUI();
    }
    
    updateZones(zones) {
        this.zones = zones;
        this.populateZones();
    }
    
    updateLobbies(lobbies) {
        // Update custom lobbies list
        const lobbiesList = document.getElementById('customLobbiesList');
        lobbiesList.innerHTML = '';
        
        Object.values(lobbies).forEach(lobby => {
            const lobbyCard = this.createLobbyCard(lobby);
            lobbiesList.appendChild(lobbyCard);
        });
    }
    
    createLobbyCard(lobby) {
        const card = document.createElement('div');
        card.className = 'lobby-card';
        card.innerHTML = `
            <div class="lobby-name">${lobby.name} ${lobby.isPrivate ? '🔒' : ''}</div>
            <div class="lobby-info">
                <span>Players:</span>
                <span class="lobby-players">${lobby.currentPlayers ? lobby.currentPlayers.length : 0}/${lobby.maxPlayers}</span>
            </div>
            <div class="lobby-status">${lobby.status}</div>
        `;
        
        card.addEventListener('click', () => {
            this.joinCustomLobby(lobby.id);
        });
        
        return card;
    }
    
    joinCustomLobby(lobbyId) {
        fetch(`https://${GetParentResourceName()}/joinCustomLobby`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                lobbyId: lobbyId
            })
        });
    }
}

// Helper function to get parent resource name
function GetParentResourceName() {
    return window.location.hostname === '' ? 'kk-ui' : window.location.hostname;
}

// Initialize UI when page loads
document.addEventListener('DOMContentLoaded', () => {
    window.KiezKriegUI = new KiezKriegUI();
});
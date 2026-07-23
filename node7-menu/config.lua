Node7MenuConfig = Node7MenuConfig or {}

Node7MenuConfig.Debug = false
Node7MenuConfig.InventoryImageResource = 'node7-inventory'

Node7MenuConfig.Sounds = {
    Enabled = true,
    Open = { name = 'MENU_ENTER', set = 'HUD_PLAYER_MENU' },
    Close = { name = 'MENU_CLOSE', set = 'HUD_PLAYER_MENU' },
    Select = { name = 'SELECT', set = 'RDRO_Character_Creator_Sounds' },
    Navigate = { name = 'NAV_LEFT', set = 'PAUSE_MENU_SOUNDSET' },
    Error = { name = 'ERROR', set = 'HUD_PLAYER_MENU' }
}

Node7MenuConfig.Commands = {
    Test = 'node7menutest',
    Debug = 'node7menudebug',
    Reload = 'node7menureload',
    CloseAll = 'node7menuclose'
}

Node7MenuConfig.Ace = {
    -- Keep this simple: /node7menutest is open for testing.
    -- Admin/dev commands use your existing NODE7 hierarchy only.
    Enabled = true,
    Test = false,
    Debug = 'node7.admin',
    Reload = 'node7.admin',
    CloseAll = 'node7.admin',
    Fallback = {
        'node7.owner',
        'node7.admin'
    }
}

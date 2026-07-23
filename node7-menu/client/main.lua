local menus = {}
local open = false
local currentMenuId = nil
local menuStack = {}
local requestId = 0
local permissionCallbacks = {}

local function notify(message, kind)
    local ok = pcall(function()
        exports['node7-core']:Notify(message, kind or 'info')
    end)

    if not ok then
        TriggerEvent('chat:addMessage', {
            args = { '^3NODE7', tostring(message) }
        })
    end
end

RegisterNetEvent('node7-menu:client:notify', notify)

local function normalizeItem(item, index)
    if type(item) ~= 'table' then return nil end

    local normalized = {
        id = tostring(item.id or ('item_' .. index)),
        label = tostring(item.label or 'Unnamed Option'),
        description = tostring(item.description or ''),
        icon = tostring(item.icon or ''),
        disabled = item.disabled == true,
        hidden = item.hidden == true,
        close = item.close,
        ace = type(item.ace) == 'string' and item.ace or nil,
        submenu = type(item.submenu) == 'string' and item.submenu or nil,
        action = type(item.action) == 'table' and item.action or nil,
        metadata = type(item.metadata) == 'table' and item.metadata or nil
    }

    return normalized
end

local function normalizeMenu(menu)
    if type(menu) ~= 'table' then return nil end
    if type(menu.id) ~= 'string' or menu.id == '' then return nil end

    local normalized = {
        id = menu.id,
        title = tostring(menu.title or Node7Menu.Theme.title),
        subtitle = tostring(menu.subtitle or Node7Menu.Theme.subtitle),
        description = tostring(menu.description or ''),
        parent = type(menu.parent) == 'string' and menu.parent or nil,
        items = {}
    }

    for index, item in ipairs(menu.items or {}) do
        local value = normalizeItem(item, index)
        if value then
            normalized.items[#normalized.items + 1] = value
        end
    end

    return normalized
end

local function checkPermission(ace, cb)
    if not ace or ace == '' then
        cb(true)
        return
    end

    requestId = requestId + 1
    permissionCallbacks[requestId] = cb
    TriggerServerEvent('node7-menu:server:checkPermission', requestId, ace)

    local captured = requestId
    SetTimeout(5000, function()
        if permissionCallbacks[captured] then
            permissionCallbacks[captured] = nil
            cb(false)
        end
    end)
end

RegisterNetEvent('node7-menu:client:permissionResult', function(id, allowed)
    local cb = permissionCallbacks[id]
    if not cb then return end

    permissionCallbacks[id] = nil
    cb(allowed == true)
end)

local function sendMenu(menu)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        theme = Node7Menu.Theme,
        menu = menu,
        canGoBack = #menuStack > 0 or menu.parent ~= nil
    })
end

local function openMenu(menuId, pushCurrent)
    local menu = menus[menuId]
    if not menu then
        notify(('Menu "%s" is not registered.'):format(tostring(menuId)), 'error')
        return false
    end

    if pushCurrent and currentMenuId then
        menuStack[#menuStack + 1] = currentMenuId
    end

    currentMenuId = menuId
    open = true
    sendMenu(menu)
    return true
end

local function closeMenu()
    open = false
    currentMenuId = nil
    menuStack = {}
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function goBack()
    if #menuStack > 0 then
        local previous = menuStack[#menuStack]
        menuStack[#menuStack] = nil
        currentMenuId = previous
        sendMenu(menus[previous])
        return
    end

    local current = menus[currentMenuId]
    if current and current.parent and menus[current.parent] then
        currentMenuId = current.parent
        sendMenu(menus[current.parent])
        return
    end

    closeMenu()
end

local function executeAction(item)
    if item.submenu then
        openMenu(item.submenu, true)
        return
    end

    if not item.action then return end

    local action = item.action
    local actionType = tostring(action.type or '')
    local value = action.value
    local args = action.args

    if actionType == 'clientEvent' and type(value) == 'string' then
        TriggerEvent(value, args)
    elseif actionType == 'serverEvent' and type(value) == 'string' then
        TriggerServerEvent('node7-menu:server:execute', action, item.ace)
    elseif actionType == 'command' and type(value) == 'string' then
        ExecuteCommand(value:gsub('^/', ''))
    elseif actionType == 'callback' and type(action.callback) == 'function' then
        action.callback(item)
    end

    local shouldClose = item.close
    if shouldClose == nil then
        shouldClose = Node7Menu.CloseOnSelect
    end

    if shouldClose then
        closeMenu()
    end
end

RegisterNUICallback('select', function(data, cb)
    local menu = menus[currentMenuId]
    local itemIndex = tonumber(data.index)

    if not open or not menu or not itemIndex then
        cb({ ok = false })
        return
    end

    local item = menu.items[itemIndex]
    if not item or item.disabled or item.hidden then
        cb({ ok = false })
        return
    end

    checkPermission(item.ace, function(allowed)
        if not allowed then
            notify('You do not have permission to use this option.', 'error')
            cb({ ok = false, denied = true })
            return
        end

        executeAction(item)
        cb({ ok = true })
    end)
end)

RegisterNUICallback('back', function(_, cb)
    goBack()
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

local function registerMenu(menu)
    local normalized = normalizeMenu(menu)
    if not normalized then return false end

    menus[normalized.id] = normalized
    return true
end

local function unregisterMenu(menuId)
    menus[menuId] = nil

    if currentMenuId == menuId then
        closeMenu()
    end

    return true
end

exports('RegisterMenu', registerMenu)
exports('UnregisterMenu', unregisterMenu)
exports('OpenMenu', function(menuId)
    return openMenu(menuId, false)
end)
exports('CloseMenu', closeMenu)
exports('IsOpen', function()
    return open
end)
exports('GetCurrentMenu', function()
    return currentMenuId
end)

RegisterNetEvent('node7-menu:client:register', registerMenu)
RegisterNetEvent('node7-menu:client:open', function(menuId)
    openMenu(menuId, false)
end)
RegisterNetEvent('node7-menu:client:close', closeMenu)

RegisterNetEvent('node7-menu:client:showPermissions', function(permissions)
    registerMenu({
        id = 'node7_permissions',
        title = 'Permission Test',
        subtitle = 'ACE STATUS',
        items = {
            {
                label = 'Configured Owner Match',
                description = tostring(permissions.configuredOwner),
                disabled = true
            },
            {
                label = 'Staff',
                description = tostring(permissions.staff),
                disabled = true
            },
            {
                label = 'Moderator',
                description = tostring(permissions.moderator),
                disabled = true
            },
            {
                label = 'Administrator',
                description = tostring(permissions.admin),
                disabled = true
            },
            {
                label = 'Owner',
                description = tostring(permissions.owner),
                disabled = true
            }
        }
    })

    openMenu('node7_permissions', false)
end)

local function registerTestMenus()
    registerMenu({
        id = 'node7_main',
        title = 'NODE7 LABS',
        subtitle = 'FRONTIER MENU',
        description = 'Nested menu demonstration',
        items = {
            {
                label = 'Citizen',
                description = 'Civilian actions and character tools',
                submenu = 'node7_citizen',
                close = false
            },
            {
                label = 'Horse & Wagon',
                description = 'Stable-related commands',
                submenu = 'node7_stables',
                close = false
            },
            {
                label = 'Staff Tools',
                description = 'ACE-gated moderator and admin actions',
                submenu = 'node7_staff',
                ace = Node7Menu.Permissions.staff,
                close = false
            },
            {
                label = 'Server Action Test',
                description = 'Tests a protected server event',
                ace = Node7Menu.Permissions.admin,
                action = {
                    type = 'serverEvent',
                    value = 'node7-menu:test:serverAction',
                    args = { source = 'menu', passed = true }
                }
            },
            {
                label = 'Close Menu',
                description = 'Return to the game',
                action = {
                    type = 'clientEvent',
                    value = 'node7-menu:client:close'
                }
            }
        }
    })

    registerMenu({
        id = 'node7_citizen',
        title = 'Citizen',
        subtitle = 'CHARACTER ACTIONS',
        parent = 'node7_main',
        items = {
            {
                label = 'Character Selection',
                description = 'Open the NODE7 character menu',
                action = {
                    type = 'command',
                    value = 'characters'
                }
            },
            {
                label = 'Logout Character',
                description = 'Return to character selection',
                action = {
                    type = 'command',
                    value = 'logout'
                }
            },
            {
                label = 'Toggle Duty',
                description = 'Toggle current job duty',
                action = {
                    type = 'command',
                    value = 'duty'
                }
            }
        }
    })

    registerMenu({
        id = 'node7_stables',
        title = 'Horse & Wagon',
        subtitle = 'STABLE ACTIONS',
        parent = 'node7_main',
        items = {
            {
                label = 'My Horses',
                description = 'List owned horses',
                action = { type = 'command', value = 'myhorses' }
            },
            {
                label = 'My Wagons',
                description = 'List owned wagons',
                action = { type = 'command', value = 'mywagons' }
            },
            {
                label = 'Dismiss Horse',
                description = 'Dismiss the active horse',
                action = { type = 'command', value = 'dismisshorse' }
            },
            {
                label = 'Dismiss Wagon',
                description = 'Dismiss the active wagon',
                action = { type = 'command', value = 'dismisswagon' }
            }
        }
    })

    registerMenu({
        id = 'node7_staff',
        title = 'Staff Tools',
        subtitle = 'AUTHORIZED PERSONNEL',
        parent = 'node7_main',
        items = {
            {
                label = 'Permission Status',
                description = 'Display current ACE permissions',
                ace = Node7Menu.Permissions.staff,
                action = { type = 'command', value = 'n7menuperms' }
            },
            {
                label = 'Admin Test',
                description = 'Admin-only test notification',
                ace = Node7Menu.Permissions.admin,
                action = {
                    type = 'serverEvent',
                    value = 'node7-menu:test:serverAction',
                    args = { permission = 'admin' }
                }
            },
            {
                label = 'Owner Test',
                description = 'Owner-only client action',
                ace = Node7Menu.Permissions.owner,
                action = {
                    type = 'clientEvent',
                    value = 'node7-menu:client:ownerTest'
                }
            }
        }
    })
end

RegisterNetEvent('node7-menu:client:ownerTest', function()
    notify('Owner permission confirmed.', 'success')
end)

CreateThread(function()
    registerTestMenus()
end)

RegisterCommand(Node7Menu.Command, function()
    openMenu('node7_main', false)
end, false)

RegisterCommand(Node7Menu.TestCommand, function()
    openMenu('node7_main', false)
end, false)

RegisterCommand(Node7Menu.AdminTestCommand, function()
    openMenu('node7_staff', false)
end, false)

if Node7Menu.EnableKeyMapping and type(RegisterKeyMapping) == 'function' then
    RegisterKeyMapping(
        Node7Menu.Command,
        'Open NODE7 Menu',
        'keyboard',
        Node7Menu.DefaultKey
    )
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    closeMenu()
end)

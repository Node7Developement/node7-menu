local permissionRanks = {
    ['node7.staff'] = 1,
    ['node7.moderator'] = 2,
    ['node7.admin'] = 3,
    ['node7.owner'] = 4
}

local function identifierSet(source)
    local result = {}

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        result[string.lower(identifier)] = true
    end

    return result
end

local function configuredOwner(source)
    local identifiers = identifierSet(source)

    for _, identifier in ipairs(Node7Menu.OwnerIdentifiers or {}) do
        if identifiers[string.lower(identifier)] then
            return true
        end
    end

    return false
end

local function aceRank(source)
    if IsPlayerAceAllowed(source, Node7Menu.Permissions.owner) then return 4 end
    if IsPlayerAceAllowed(source, Node7Menu.Permissions.admin) then return 3 end
    if IsPlayerAceAllowed(source, Node7Menu.Permissions.moderator) then return 2 end
    if IsPlayerAceAllowed(source, Node7Menu.Permissions.staff) then return 1 end
    return 0
end

local function allowed(source, ace)
    if type(ace) ~= 'string' or ace == '' then
        return true
    end

    source = tonumber(source)
    if not source or source <= 0 then
        return false
    end

    -- Primary path: native ACE permission.
    if IsPlayerAceAllowed(source, ace) then
        return true
    end

    -- Owner fallback: only the configured owner identifiers receive owner
    -- rank, which inherits admin, moderator, and staff menu options.
    local rank = aceRank(source)
    if configuredOwner(source) then
        rank = math.max(rank, 4)
    end

    local requiredRank = permissionRanks[ace]
    return requiredRank ~= nil and rank >= requiredRank
end

local function permissionSnapshot(source)
    return {
        identifiers = GetPlayerIdentifiers(source),
        configuredOwner = configuredOwner(source),
        staff = allowed(source, Node7Menu.Permissions.staff),
        moderator = allowed(source, Node7Menu.Permissions.moderator),
        admin = allowed(source, Node7Menu.Permissions.admin),
        owner = allowed(source, Node7Menu.Permissions.owner)
    }
end

local function sanitizeAction(action)
    if type(action) ~= 'table' then return nil end

    local actionType = tostring(action.type or '')
    local value = action.value

    if actionType == 'serverEvent' then
        if type(value) ~= 'string' or value == '' then return nil end
        return { type = actionType, value = value, args = action.args }
    end

    if actionType == 'clientEvent' then
        if type(value) ~= 'string' or value == '' then return nil end
        return { type = actionType, value = value, args = action.args }
    end

    if actionType == 'command' then
        if type(value) ~= 'string' or value == '' then return nil end
        return { type = actionType, value = value }
    end

    return nil
end

RegisterNetEvent('node7-menu:server:checkPermission', function(requestId, ace)
    local src = source
    TriggerClientEvent(
        'node7-menu:client:permissionResult',
        src,
        requestId,
        allowed(src, ace)
    )
end)

RegisterNetEvent('node7-menu:server:execute', function(action, requiredAce)
    local src = source

    if not allowed(src, requiredAce) then
        TriggerClientEvent(
            'node7-menu:client:notify',
            src,
            'You do not have permission to use this option.',
            'error'
        )
        return
    end

    local safeAction = sanitizeAction(action)
    if not safeAction then return end

    if safeAction.type == 'serverEvent' then
        TriggerEvent(safeAction.value, src, safeAction.args)
        return
    end

    if safeAction.type == 'clientEvent' then
        TriggerClientEvent(safeAction.value, src, safeAction.args)
        return
    end

    if safeAction.type == 'command' then
        ExecuteCommand(safeAction.value:gsub('^/', ''))
    end
end)

RegisterCommand('n7menuperms', function(source)
    if source == 0 then
        print('[node7-menu] This test command must be run by a player.')
        return
    end

    local snapshot = permissionSnapshot(source)

    print(('[node7-menu] ACE diagnostic for %s (%s)'):format(
        GetPlayerName(source) or 'unknown',
        tostring(source)
    ))

    for _, identifier in ipairs(snapshot.identifiers) do
        print(('  identifier: %s'):format(identifier))
    end

    print(('  node7.staff: %s'):format(tostring(snapshot.staff)))
    print(('  node7.moderator: %s'):format(tostring(snapshot.moderator)))
    print(('  node7.admin: %s'):format(tostring(snapshot.admin)))
    print(('  node7.owner: %s'):format(tostring(snapshot.owner)))

    TriggerClientEvent('node7-menu:client:showPermissions', source, snapshot)
end, false)

RegisterCommand('n7acecheck', function(source)
    if source == 0 then
        print('[node7-menu] This test command must be run by a player.')
        return
    end

    TriggerClientEvent(
        'node7-menu:client:showPermissions',
        source,
        permissionSnapshot(source)
    )
end, false)

RegisterNetEvent('node7-menu:test:serverAction', function(source, args)
    local src = tonumber(source) or source
    print(('[node7-menu] server action test from %s: %s'):format(
        tostring(src),
        json.encode(args or {})
    ))

    TriggerClientEvent(
        'node7-menu:client:notify',
        src,
        'Server action executed successfully.',
        'success'
    )
end)

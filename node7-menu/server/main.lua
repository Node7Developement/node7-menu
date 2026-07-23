local Config = Node7MenuConfig or {}
local ResourceName = GetCurrentResourceName()

local function log(message)
    print(('[%s] %s'):format(ResourceName, message))
end

local function safeAceAllowed(source, permission)
    if not permission or permission == '' then
        return false
    end

    local ok, allowed = pcall(IsPlayerAceAllowed, source, permission)
    return ok and allowed == true
end

local function aceAllowed(source, permission)
    source = tonumber(source) or 0

    if source == 0 then
        return true
    end

    local ace = Config.Ace or {}
    if ace.Enabled == false then
        return true
    end

    if permission == false or permission == nil or permission == '' then
        return true
    end

    local checks = { permission }

    if type(ace.Fallback) == 'table' then
        for _, aceName in ipairs(ace.Fallback) do
            checks[#checks + 1] = aceName
        end
    else
        checks[#checks + 1] = 'node7.owner'
        checks[#checks + 1] = 'node7.admin'
    end

    for _, aceName in ipairs(checks) do
        if safeAceAllowed(source, aceName) then
            return true
        end
    end

    return false
end

local function deny(source, permission)
    TriggerClientEvent('chat:addMessage', source, {
        args = { 'NODE7 MENU', ('Missing ACE permission: %s'):format(permission or 'node7.admin') }
    })
end

local function registerAceCommand(commandName, permission, handler)
    if not commandName or commandName == '' then
        return
    end

    RegisterCommand(commandName, function(source, args, raw)
        if not aceAllowed(source, permission) then
            deny(source, permission)
            return
        end

        handler(source, args or {}, raw or '')
    end, false)
end

CreateThread(function()
    Wait(250)
    log(('started v%s'):format(GetResourceMetadata(ResourceName, 'version', 0) or '1.0.0'))
end)

registerAceCommand(Config.Commands and Config.Commands.Test, Config.Ace and Config.Ace.Test, function(source)
    if source == 0 then
        log('Console cannot open a client menu.')
        return
    end

    TriggerClientEvent('node7-menu:client:openTest', source)
end)

registerAceCommand(Config.Commands and Config.Commands.Debug, Config.Ace and Config.Ace.Debug, function(source)
    if source == 0 then
        log('Debug command can only inspect a client instance.')
        return
    end

    TriggerClientEvent('node7-menu:client:debug', source)
end)

registerAceCommand(Config.Commands and Config.Commands.Reload, Config.Ace and Config.Ace.Reload, function(source)
    if source == 0 then
        log('Reload command can only refresh a client instance.')
        return
    end

    TriggerClientEvent('node7-menu:client:reloadUi', source)
end)

registerAceCommand(Config.Commands and Config.Commands.CloseAll, Config.Ace and Config.Ace.CloseAll, function(source)
    if source == 0 then
        log('Close command can only close a client menu instance.')
        return
    end

    TriggerClientEvent('node7-menu:client:closeAll', source)
end)

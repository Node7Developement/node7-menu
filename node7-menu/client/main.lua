MenuData = {}
MenuData.Opened = {}
MenuData.RegisteredTypes = {}
MenuData.LastSelectedIndex = {}


local Config = Node7MenuConfig or {}
local ResourceName = GetCurrentResourceName()

local function debugPrint(message)
    if Config.Debug then
        print(('[%s] %s'):format(ResourceName, tostring(message)))
    end
end

local function safeNative(fn, ...)
    if type(fn) ~= 'function' then
        return false
    end

    local ok, result = pcall(fn, ...)
    if not ok then
        debugPrint(result)
        return false
    end

    return true, result
end

local function safeDisplayRadar(enabled)
    safeNative(DisplayRadar, enabled == true)
end

local function safeSetNuiFocus(hasFocus, hasCursor)
    safeNative(SetNuiFocus, hasFocus == true, hasCursor == true)
end

local function hasOpenMenu()
    for _, menu in pairs(MenuData.Opened or {}) do
        if menu then
            return true
        end
    end

    return false
end

local function menuWantsCursor()
    for _, menu in pairs(MenuData.Opened or {}) do
        if menu and menu.data and menu.data.enableCursor == true then
            return true
        end
    end

    return false
end

local function releaseMenuFocus()
    safeNative(SetNuiFocusKeepInput, false)
    safeSetNuiFocus(false, false)
end

local function refreshMenuFocus(forceCursor)
    local opened = hasOpenMenu()

    if opened then
        local cursor = forceCursor == true or menuWantsCursor()
        safeNative(SetNuiFocusKeepInput, false)
        safeSetNuiFocus(true, cursor)
        return
    end

    releaseMenuFocus()
end

local function safeIsNuiFocused()
    local ok, result = safeNative(IsNuiFocused)
    return ok and result == true
end

local function safeIsPauseMenuActive()
    local ok, result = safeNative(IsPauseMenuActive)
    return ok and result == true
end

local function safeControlJustReleased(group, control)
    local okA, resultA = safeNative(IsControlJustPressed, group, control)
    if okA and resultA == true then
        return true
    end

    local okB, resultB = safeNative(IsDisabledControlJustPressed, group, control)
    if okB and resultB == true then
        return true
    end

    local okC, resultC = safeNative(IsControlJustReleased, group, control)
    if okC and resultC == true then
        return true
    end

    local okD, resultD = safeNative(IsDisabledControlJustReleased, group, control)
    return okD and resultD == true
end

local function playNode7Sound(soundType)
    if Config.Sounds and Config.Sounds.Enabled == false then
        return
    end

    local soundConfig = Config.Sounds or {}
    local sound = soundConfig.Select

    if soundType == 'open' then
        sound = soundConfig.Open or sound
    elseif soundType == 'close' then
        sound = soundConfig.Close or sound
    elseif soundType == 'nav' or soundType == 'navigate' then
        sound = soundConfig.Navigate or sound
    elseif soundType == 'error' then
        sound = soundConfig.Error or sound
    elseif soundType == 'select' or soundType == 'submit' then
        sound = soundConfig.Select or sound
    end

    if not sound or not sound.name or not sound.set then
        return
    end

    safeNative(PlaySoundFrontend, sound.name, sound.set, true, 0)
end

Node7Menu = MenuData

local function cloneTable(source)
    if type(source) ~= 'table' then
        return source
    end

    local copy = {}
    for key, value in pairs(source) do
        copy[key] = cloneTable(value)
    end

    return copy
end

local function nestedElementsFromElement(element)
    if type(element) ~= 'table' then
        return nil
    end

    if type(element.children) == 'table' then
        return element.children
    end

    if type(element.options) == 'table' then
        return element.options
    end

    if type(element.items) == 'table' then
        return element.items
    end

    if type(element.submenu) == 'table' then
        if type(element.submenu.elements) == 'table' then
            return element.submenu.elements
        end
        return element.submenu
    end

    if type(element.menu) == 'table' then
        if type(element.menu.elements) == 'table' then
            return element.menu.elements
        end
        return element.menu
    end

    return nil
end

local function elementHasChildren(element)
    local childElements = nestedElementsFromElement(element)
    return type(childElements) == 'table' and #childElements > 0
end

local function sanitizeMenuElements(elements)
    if type(elements) ~= 'table' then
        return {}
    end

    for index = 1, #elements do
        local element = elements[index]
        if type(element) == 'table' then
            if not element.label then
                element.label = element.title or element.name or ('Option ' .. tostring(index))
            end

            if elementHasChildren(element) then
                element.isCategory = true
                element.hasChildren = true
                element.type = element.type or 'category'
                element.desc = element.desc or element.description or 'Open category.'
                element.rightLabel = element.rightLabel or '›'
                local nested = nestedElementsFromElement(element)
                sanitizeMenuElements(nested)
            end
        end
    end

    return elements
end

local function nestedTitleFromElement(element)
    if type(element) ~= 'table' then
        return 'Menu'
    end

    if type(element.title) == 'string' and element.title ~= '' then
        return element.title
    end

    if type(element.label) == 'string' and element.label ~= '' then
        return element.label
    end

    if type(element.name) == 'string' and element.name ~= '' then
        return element.name
    end

    return 'Menu'
end

local function openNestedMenu(parentMenu, selectedElement)
    if type(parentMenu) ~= 'table' or type(selectedElement) ~= 'table' then
        return false
    end

    local childElements = nestedElementsFromElement(selectedElement)
    if type(childElements) ~= 'table' or #childElements < 1 then
        return false
    end

    local childData = {}

    if type(selectedElement.submenu) == 'table' and type(selectedElement.submenu.elements) == 'table' then
        childData = cloneTable(selectedElement.submenu)
    elseif type(selectedElement.menu) == 'table' and type(selectedElement.menu.elements) == 'table' then
        childData = cloneTable(selectedElement.menu)
    else
        childData = {
            elements = cloneTable(childElements)
        }
    end

    childData.title = childData.title or nestedTitleFromElement(selectedElement)
    childData.subtext = childData.subtext or selectedElement.desc or selectedElement.description or parentMenu.data.subtext or ''
    childData.align = childData.align or parentMenu.data.align or 'top-left'
    childData.enableCursor = parentMenu.data.enableCursor == true
    childData.hideRadar = parentMenu.data.hideRadar == true
    childData.parentTitle = parentMenu.data.title or parentMenu.name
    childData.soundOpen = selectedElement.soundOpen
    childData.elements = sanitizeMenuElements(childData.elements or {})

    local cleanValue = tostring(selectedElement.value or selectedElement.label or selectedElement.title or 'submenu'):gsub('[^%w_%-]', '_')
    local childName = tostring(parentMenu.name) .. '_' .. cleanValue

    MenuData.Open(
        parentMenu.type,
        parentMenu.namespace,
        childName,
        childData,
        parentMenu.submit,
        function(data, menu)
            menu.close(false, true, false)
        end,
        parentMenu.change,
        parentMenu.close
    )

    playNode7Sound('select')
    return true
end


MenuData.RegisteredTypes['default'] = {
    open  = function(namespace, name, data)
        SendNUIMessage({
            ak_menubase_action = 'openMenu',
            ak_menubase_namespace = namespace,
            ak_menubase_name = name,
            ak_menubase_data = data
        })
    end,
    close = function(namespace, name)
        SendNUIMessage({
            ak_menubase_action = 'closeMenu',
            ak_menubase_namespace = namespace,
            ak_menubase_name = name,
            -- ak_menubase_data = data
        })
    end
}


function MenuData.Open(menuType, namespace, name, data, submit, cancel, change, close)
    data = type(data) == 'table' and data or {}
    data.elements = sanitizeMenuElements(data.elements or {})

    local menu         = {}

    menu.type          = menuType
    menu.namespace     = namespace
    menu.name          = name
    menu.data          = data
    menu.submit        = submit
    menu.cancel        = cancel
    menu.change        = change
    menu.data.selected = MenuData.LastSelectedIndex[menu.type .. "_" .. menu.namespace .. "_" .. menu.name] or 0

    menu.close         = function(showRadar, closeSound, triggerCloseEvent)
        MenuData.RegisteredTypes[menuType].close(namespace, name)

        for i = 1, #MenuData.Opened, 1 do
            if MenuData.Opened[i] then
                if MenuData.Opened[i].type == menuType and MenuData.Opened[i].namespace == namespace and MenuData.Opened[i].name == name then
                    MenuData.Opened[i] = nil
                end
            end
        end

        if showRadar then
            safeDisplayRadar(true)
        end

        if closeSound then
            playNode7Sound('close')
        end
        -- flag to trigger the close event or leave false to not trigger the event, if nil by default will close for backwards compatibility
        if triggerCloseEvent or triggerCloseEvent == nil then
            TriggerEvent("node7-menu:closemenu")
        end

        refreshMenuFocus(false)

        if close then
            close()
        end
    end

    if data.hideRadar then
        safeDisplayRadar(false)
    end

    menu.update               = function(query, newData)
        for i = 1, #menu.data.elements, 1 do
            local match = true

            for k, v in pairs(query) do
                if menu.data.elements[i][k] ~= v then
                    match = false
                end
            end

            if match then
                for k, v in pairs(newData) do
                    menu.data.elements[i][k] = v
                end
            end
        end
    end

    menu.addNewElement        = function(element)
        local list = sanitizeMenuElements({ element })
        menu.data.elements[#menu.data.elements + 1] = list[1]
    end

    menu.removeElementByValue = function(value, stop)
        for i = 1, #menu.data.elements, 1 do
            if menu.data.elements[i] then
                if menu.data.elements[i].value == value then
                    table.remove(menu.data.elements, i)
                    if stop then
                        break
                    end
                end
            end
        end
    end

    menu.removeElementByIndex = function(index, stop)
        for i = 1, #menu.data.elements, 1 do
            if menu.data.elements[i] then
                if i == index then
                    table.remove(menu.data.elements, i)
                    if stop then
                        break
                    end
                end
            end
        end
    end

    menu.refresh              = function()
        MenuData.RegisteredTypes[menuType].open(namespace, name, menu.data)
    end

    menu.setElement           = function(i, key, val)
        menu.data.elements[i][key] = val
    end

    menu.setElements          = function(newElements)
        menu.data.elements = sanitizeMenuElements(newElements or {})
    end

    menu.setTitle             = function(val)
        menu.data.title = val
    end

    menu.setSubtext           = function(val)
        menu.data.subtext = val
    end

    menu.displayInput         = function(inputConfig, onSubmit, onCancel)
        Wait(500)
        if MenuData.InputCallbacks then
            return
        end

        MenuData.InputCallbacks = {
            onSubmit = onSubmit,
            onCancel = onCancel
        }

        SendNUIMessage({
            ak_menubase_action = 'displayInput',
            ak_menubase_namespace = namespace,
            ak_menubase_name = name,
            ak_menubase_inputConfig = inputConfig
        })
    end

    menu.isInputActive        = function()
        return MenuData.InputCallbacks ~= nil
    end

    menu.removeElement        = function(query)
        for i = 1, #menu.data.elements, 1 do
            for k, v in pairs(query) do
                if menu.data.elements[i] then
                    if menu.data.elements[i][k] == v then
                        menu.data.elements[i] = nil
                        break
                    end
                end
            end
        end
    end

    -- Check if action buttons are defined but cursor is not enabled
    if (data.confirmButton or data.cancelButton) and not data.enableCursor then
        print("^3[node7-menu warning]^7 action buttons (confirmButton/cancelButton) require enableCursor = true to be clickable!")

        -- remove buttons from data to prevent them from being created
        data.confirmButton = nil
        data.cancelButton = nil
    end

    local function checkProperties(min, max, value, elements)
        -- check if properties are all there
        if not min then
            return print("^3[node7-menu warning]^7 no min property found for slider  you must add one ")
        end

        if not max then
            return print("^3[node7-menu warning]^7 no max property found for slider  you must add one ")
        end

        if not value then
            return print("^3[node7-menu warning]^7 no value property found for slider  you must add one ")
        end

        -- check if custom key is there
        local customKey = nil
        for key, _ in pairs(elements) do
            if key ~= "label" and key ~= "value" and key ~= "min" and key ~= "max" and key ~= "hop" and key ~= "options" and key ~= "attributes" then
                customKey = key
                break
            end
        end

        if not customKey then
            return print("^3[node7-menu warning]^7 no custom key found for slider add one so you can detect it")
        end
    end

    if data.elements then
        for i = 1, #data.elements do
            if data.elements[i].type then
                if data.elements[i].type == "label-slider" then
                    -- set itemHeight for label-slider elements if not set
                    if not data.elements[i].itemHeight then
                        data.elements[i].itemHeight = "4vh"
                    end

                    checkProperties(data.elements[i].min, data.elements[i].max, data.elements[i].value, data.elements[i])
                elseif data.elements[i].type == "desc-slider" then
                    -- description slider requires cursor
                    if not data.enableCursor then
                        return print("^3[node7-menu warning]^7 desc-slider elements require enableCursor = true to be clickable!")
                    end

                    -- multiple sliders
                    if data.elements[i].sliders then
                        if type(data.elements[i].sliders) == "table" then
                            for j = 1, #data.elements[i].sliders do
                                local slider = data.elements[i].sliders[j]
                                checkProperties(slider.min, slider.max, slider.value, slider)
                            end
                        else
                            return print("^3[node7-menu warning]^7 sliders must be a table")
                        end
                    else
                        checkProperties(data.elements[i].min, data.elements[i].max, data.elements[i].value, data.elements[i])
                    end
                end
            end
            -- convert to strings to display the floats
            if data.elements[i].descPrice then
                data.elements[i].descPrice.amount = tostring(data.elements[i].descPrice.amount)
            end
        end
    end

    MenuData.Opened[#MenuData.Opened + 1] = menu
    MenuData.RegisteredTypes[menuType].open(namespace, name, data)
    refreshMenuFocus(data.enableCursor == true)

    if data.soundOpen ~= false then
        playNode7Sound('open')
    end

    if not data.skipOpenEvent then
        TriggerEvent("node7-menu:openmenu")
    end
    return menu
end

function MenuData.Close(type, namespace, name, showRadar, closeSound, triggerCloseEvent)
    for i = 1, #MenuData.Opened, 1 do
        if MenuData.Opened[i] then
            if MenuData.Opened[i].type == type and MenuData.Opened[i].namespace == namespace and MenuData.Opened[i].name == name then
                MenuData.Opened[i].close(showRadar, closeSound, triggerCloseEvent)
                MenuData.Opened[i] = nil
            end
        end
    end
end

function MenuData.CloseAll(showRadar, closeSound, triggerCloseEvent)
    local openedMenus = MenuData.Opened or {}

    for _, menu in pairs(openedMenus) do
        if menu and type(menu.close) == 'function' then
            menu.close(showRadar, closeSound, triggerCloseEvent)
        end
    end

    MenuData.Opened = {}
    SendNUIMessage({ ak_menubase_action = 'closeAll' })

    if showRadar == nil or showRadar == true then
        safeDisplayRadar(true)
    end

    refreshMenuFocus(false)
end

function MenuData.ForceCloseAll(showRadar, closeSound, triggerCloseEvent)
    MenuData.Opened = {}
    MenuData.InputCallbacks = nil
    SendNUIMessage({ ak_menubase_action = 'closeAll' })

    if showRadar == nil or showRadar == true then
        safeDisplayRadar(true)
    end

    if closeSound then
        playNode7Sound('close')
    end

    if triggerCloseEvent == true then
        TriggerEvent("node7-menu:closemenu")
    end

    releaseMenuFocus()
end

function MenuData.GetOpened(type, namespace, name)
    for i = 1, #MenuData.Opened, 1 do
        if MenuData.Opened[i] then
            if MenuData.Opened[i].type == type and MenuData.Opened[i].namespace == namespace and MenuData.Opened[i].name == name then
                return MenuData.Opened[i]
            end
        end
    end
end

function MenuData.GetOpenedMenus()
    return MenuData.Opened
end

function MenuData.IsOpen(type, namespace, name)
    return MenuData.GetOpened(type, namespace, name) ~= nil
end

function MenuData.ReOpen(oldMenu)
    MenuData.Open(oldMenu.type, oldMenu.namespace, oldMenu.name, oldMenu.data, oldMenu.submit, oldMenu.cancel, oldMenu.change, oldMenu.close)
end

function MenuData.IsInputActive()
    return MenuData.InputCallbacks ~= nil
end

function MenuData.RegisterControls(controls, onPress)
    SendNUIMessage({
        ak_menubase_action = 'useControls',
        ak_menubase_controls = controls
    })

    local isRelease = false
    RegisterNUICallback('useControlsCallback', function(data, cb)
        -- if press and hold send only one callback until release is called for optimization
        if data.type == 'press' then
            isRelease = false
        end

        if data.type == 'release' then
            isRelease = true
        end

        if data.button then
            -- for mouse press
            local button = data.button == 0 and 'left' or data.button == 2 and 'right'
            data.control = data.control .. '_' .. button
        end

        repeat
            onPress(data.control)
            Wait(0)
        until isRelease

        if cb then
            cb('ok')
        end
    end)
end

function MenuData.UnregisterControls()
    SendNUIMessage({
        ak_menubase_action = 'unregisterControls'
    })
end

local MenuType = 'default'

RegisterNUICallback('menu_submit', function(data, cb)
    playNode7Sound('select')
    local menu = MenuData.GetOpened(MenuType, data._namespace, data._name)

    if menu and type(data) == 'table' and type(data.current) == 'table' and elementHasChildren(data.current) then
        if openNestedMenu(menu, data.current) then
            if cb then
                cb('ok')
            end
            return
        end
    end

    if menu and menu.submit ~= nil then
        menu.submit(data, menu)
    end

    if cb then
        cb('ok')
    end
end)


RegisterNUICallback('playsound', function(data, cb)
    local soundType = 'nav'

    if type(data) == 'table' and data.type then
        soundType = tostring(data.type)
    end

    playNode7Sound(soundType)

    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('menu_cancel', function(data, cb)
    local menu = MenuData.GetOpened(MenuType, data._namespace, data._name)
    if not menu then
        print("menu not found", data._namespace, data._name)
        if cb then
            cb('missing')
        end
        return
    end

    if menu.cancel ~= nil then
        menu.cancel(data, menu)
    else
        menu.close(true, true, true)
    end

    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('menu_change', function(data, cb)
    local menu = MenuData.GetOpened(MenuType, data._namespace, data._name)
    if not menu then
        print("menu not found", data._namespace, data._name)
        if cb then
            cb('missing')
        end
        return
    end

    for i = 1, #data.elements, 1 do
        menu.setElement(i, 'value', data.elements[i].value)

        if data.elements[i].selected then
            menu.setElement(i, 'selected', true)
        else
            menu.setElement(i, 'selected', false)
        end
    end

    if menu.change ~= nil then
        menu.change(data, menu)
    end

    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('update_last_selected', function(data, cb)
    local menu = MenuData.GetOpened(MenuType, data._namespace, data._name)
    if not menu then
        print("menu not found", data._namespace, data._name)
        if cb then
            cb('missing')
        end
        return
    end
    local menuKey = menu.type .. "_" .. menu.namespace .. "_" .. menu.name
    if data.selected ~= nil then
        MenuData.LastSelectedIndex[menuKey] = data.selected
    end

    if cb then
        cb('ok')
    end
end)

-- is fired when pressing backspace or right mouse click if enableCursor is true
RegisterNUICallback('closeui', function(data, cb)
    MenuData.ForceCloseAll(true, true, false)

    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('setCursor', function(data, cb)
    refreshMenuFocus(type(data) == 'table' and data.enabled == true)
    if cb then
        cb('ok')
    end
end)

RegisterNUICallback("inputResult", function(data, cb)
    local inputData = data.inputData
    local cancelled = data.cancelled
    local escPressed = data.escPressed

    if MenuData.InputCallbacks then
        -- ESC was pressed
        if escPressed then
            MenuData.InputCallbacks = nil
        else
            if cancelled and MenuData.InputCallbacks.onCancel then
                MenuData.InputCallbacks.onCancel()
            elseif not cancelled and MenuData.InputCallbacks.onSubmit then
                MenuData.InputCallbacks.onSubmit(inputData)
            end

            MenuData.InputCallbacks = nil
        end
    end

    if cb then
        cb("ok")
    end
end)


local SendNUIMessage = SendNUIMessage
local Wait = Wait

local MenuControls = {
    ENTER = { 0xC7B5340A, 0x43DBF61F, 0xCEFD9220 },
    BACKSPACE = { 0x156F7119, 0x308588E6, 0x8AAA0AD4 },
    TOP = { 0x6319DB71, 0x911CB09E, 0x8FD015D8 },
    DOWN = { 0x05CA7C52, 0x4403F97F, 0xD27782E3 },
    LEFT = { 0xA65EBAB4, 0xAD7FCC5B },
    RIGHT = { 0xDEB34313, 0x65F9EC5B }
}

local function menuControlReleased(controlName)
    local controls = MenuControls[controlName]
    if type(controls) ~= 'table' then
        return false
    end

    for _, control in ipairs(controls) do
        if safeControlJustReleased(0, control) or safeControlJustReleased(2, control) then
            return true
        end
    end

    return false
end

local function sendMenuControl(controlName)
    SendNUIMessage({
        ak_menubase_action = 'controlPressed',
        ak_menubase_control = controlName
    })
end

CreateThread(function()
    local PauseMenuState = false
    local MenusToReOpen  = {}

    while true do
        Wait(0)
        if #MenuData.Opened > 0 and not safeIsNuiFocused() then -- if cursor is enabled these dont need to work
            if menuControlReleased('ENTER') then
                sendMenuControl('ENTER')
            end

            if menuControlReleased('BACKSPACE') then
                sendMenuControl('BACKSPACE')
            end

            if menuControlReleased('TOP') then
                sendMenuControl('TOP')
            end

            if menuControlReleased('DOWN') then
                sendMenuControl('DOWN')
            end

            if menuControlReleased('LEFT') then
                sendMenuControl('LEFT')
            end

            if menuControlReleased('RIGHT') then
                sendMenuControl('RIGHT')
            end

            if safeIsPauseMenuActive() then
                if not PauseMenuState then
                    PauseMenuState = true
                    for _, v in pairs(MenuData.GetOpenedMenus()) do
                        table.insert(MenusToReOpen, v)
                    end
                    MenuData.CloseAll()
                end
            end
        else
            if not hasOpenMenu() then
                releaseMenuFocus()
            end

            if PauseMenuState and not safeIsPauseMenuActive() then
                PauseMenuState = false
                Wait(1000)
                for _, v in pairs(MenusToReOpen) do
                    MenuData.ReOpen(v)
                end
                MenusToReOpen = {}
            end
        end
    end
end)

AddEventHandler('node7-menu:getData', function(cb)
    cb(MenuData)
end)

AddEventHandler("node7_menu:getData", function(cb)
    return cb(MenuData)
end)


AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MenuData.LastSelectedIndex = {}
    end
end)

exports("GetMenuData", function()
    return MenuData
end)


RegisterNetEvent('node7-menu:client:closeAll', function()
    MenuData.ForceCloseAll(true, true, true)
end)

RegisterNetEvent('node7-menu:client:reloadUi', function()
    MenuData.ForceCloseAll(true, false, false)
    Wait(250)
    SendNUIMessage({ ak_menubase_action = 'node7Reload' })
    playNode7Sound('select')
end)

RegisterNetEvent('node7-menu:client:debug', function()
    print(('[%s] opened menus: %s'):format(ResourceName, tostring(#MenuData.Opened)))
    for index, menu in pairs(MenuData.Opened) do
        if menu then
            print(('[%s] #%s %s/%s/%s elements=%s'):format(ResourceName, index, tostring(menu.type), tostring(menu.namespace), tostring(menu.name), tostring(menu.data and menu.data.elements and #menu.data.elements or 0)))
        end
    end
end)

RegisterNetEvent('node7-menu:client:openTest', function()
    MenuData.Open('default', 'node7', 'main', {
        title = 'NODE7 MENU',
        subtext = 'Nested category menu',
        align = 'top-left',
        enableCursor = true,
        elements = {
            {
                label = 'Character',
                value = 'character',
                desc = 'Character actions and setup.',
                children = {
                    { label = 'View Character', value = 'view_character', desc = 'Example character action.' },
                    { label = 'Appearance', value = 'appearance', desc = 'Example appearance action.' },
                    { label = 'Logout', value = 'logout', desc = 'Example logout action.' }
                }
            },
            {
                label = 'Player',
                value = 'player',
                desc = 'Player tools and player-side options.',
                children = {
                    { label = 'Status', value = 'status', desc = 'Example player status.' },
                    { label = 'Inventory', value = 'inventory', desc = 'Example inventory action.' },
                    { label = 'Settings', value = 'settings', desc = 'Example settings action.' }
                }
            },
            {
                label = 'World',
                value = 'world',
                desc = 'World interaction category.',
                children = {
                    { label = 'Target Debug', value = 'target_debug', desc = 'Example world action.' },
                    { label = 'Nearby Shops', value = 'nearby_shops', desc = 'Example shop action.' }
                }
            },
            {
                label = 'Controls',
                value = 'controls',
                desc = 'Menu control examples.',
                children = {
                    { label = 'Volume', value = 5, min = 0, max = 10, type = 'slider', desc = 'Left/right slider test.' },
                    { label = 'Toggle Example', value = 'unticked', tickBox = true, desc = 'Enter toggles this option.' }
                }
            },
            { label = 'Close', value = 'close', desc = 'Close this menu.' }
        }
    }, function(data, menu)
        if data.current and data.current.value == 'close' then
            menu.close(true, true, true)
            return
        end

        playNode7Sound('submit')
        print(('[%s] menu submit: %s'):format(ResourceName, tostring(data.current and data.current.value)))
    end, function(data, menu)
        menu.close(true, true, true)
    end, function(data)
        playNode7Sound('nav')
    end)
end)

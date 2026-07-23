-- Register a nested custom menu from another client resource.

CreateThread(function()
    exports['node7-menu']:RegisterMenu({
        id = 'example_main',
        title = 'Example Menu',
        subtitle = 'NODE7 LABS',
        items = {
            {
                label = 'Open Submenu',
                description = 'Demonstrates nested navigation',
                submenu = 'example_submenu',
                close = false
            },
            {
                label = 'Client Event',
                description = 'Runs a local event',
                action = {
                    type = 'clientEvent',
                    value = 'example:client:test'
                }
            },
            {
                label = 'Admin Server Action',
                description = 'Requires node7.admin',
                ace = 'node7.admin',
                action = {
                    type = 'serverEvent',
                    value = 'example:server:test',
                    args = { value = 123 }
                }
            }
        }
    })

    exports['node7-menu']:RegisterMenu({
        id = 'example_submenu',
        title = 'Example Submenu',
        subtitle = 'NESTED MENU',
        parent = 'example_main',
        items = {
            {
                label = 'Run Command',
                description = 'Executes /duty',
                action = {
                    type = 'command',
                    value = 'duty'
                }
            }
        }
    })
end)

RegisterNetEvent('example:client:test', function()
    print('NODE7 menu client event worked')
end)

RegisterCommand('examplemenu', function()
    exports['node7-menu']:OpenMenu('example_main')
end, false)

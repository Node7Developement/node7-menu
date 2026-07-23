# node7-menu

Standalone nested Red Dead-style menu system for NODE7 LABS.

It does not modify NODE7 Core, multicharacter, spawn logic, player loading, or persistence.

## Features

- Unlimited nested menus
- Mouse and keyboard navigation
- Back stack
- ACE-gated menu options
- Client events
- Server events
- Commands
- Runtime registration
- Runtime unregistration
- Red Dead-style transparent UI
- Built-in demonstration menus
- Permission test menu
- Automatic resource cleanup
- F6 default key binding

## Installation

```cfg
ensure node7-core
ensure node7-menu
```

## Built-in commands

```text
/n7menu
/n7menutest
/n7adminmenu
/n7menuperms
```

Default key:

```text
F6
```

## Client exports

```lua
exports['node7-menu']:RegisterMenu(menu)
exports['node7-menu']:UnregisterMenu(menuId)
exports['node7-menu']:OpenMenu(menuId)
exports['node7-menu']:CloseMenu()
exports['node7-menu']:IsOpen()
exports['node7-menu']:GetCurrentMenu()
```

## Menu format

```lua
exports['node7-menu']:RegisterMenu({
    id = 'my_menu',
    title = 'My Menu',
    subtitle = 'NODE7 LABS',
    description = 'Choose an option',
    items = {
        {
            label = 'Nested Menu',
            description = 'Open another menu',
            submenu = 'my_submenu',
            close = false
        },
        {
            label = 'Admin Action',
            description = 'Requires administrator permission',
            ace = 'node7.admin',
            action = {
                type = 'serverEvent',
                value = 'my-resource:server:action',
                args = { example = true }
            }
        }
    }
})
```

## Supported action types

```lua
{ type = 'clientEvent', value = 'resource:client:event', args = {} }
{ type = 'serverEvent', value = 'resource:server:event', args = {} }
{ type = 'command', value = 'commandname' }
```

A client callback function can also be used from the same resource:

```lua
{
    type = 'callback',
    callback = function(item)
        print(item.label)
    end
}
```

## ACE behavior

A menu option can include:

```lua
ace = 'node7.admin'
```

The permission is checked by the server before execution.

## Test sequence

1. Run `/n7menu`.
2. Open Citizen, Horse & Wagon, and Staff Tools.
3. Run `/n7menuperms`.
4. Run `/n7adminmenu`.
5. Use the Server Action Test as an administrator.
6. Confirm denied options do not execute for unauthorized players.


## ACE diagnostics

Run `/n7menuperms` or `/n7acecheck`. The server console prints every identifier
RedM exposes and the result of `node7.staff`, `node7.moderator`, `node7.admin`,
and `node7.owner`.

Use one of the printed identifiers in `add_principal`.

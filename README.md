[README.md](https://github.com/user-attachments/files/30312022/README.md)
# node7-menu

<img width="552" height="697" alt="menusystemmmm" src="https://github.com/user-attachments/assets/c46a5d75-d776-4e6f-858e-11d5708b4893" />




Premium RedM nested menu API for NODE7 resources.

## Start order

ensure node7-core
ensure node7-menu

## What it does

- keyboard navigation with arrow keys
- Enter selects
- Left/Right adjusts sliders
- Escape/Backspace backs out or closes
- stacked nested menus
- RedM-safe control fallback
- premium NODE7 UI
- no SQL
- no persistence
- no oxmysql

## API

Use exports['node7-menu']:GetMenuData() from client resources, then call MenuData.Open with elements and callbacks.

## Recipe style

This resource keeps the NODE7 recipe layout with .gitignore, .editorconfig, RECIPE.md, VERSIONS.md, config.lua, client, server, and html files.


## Nested menus

Any option can contain `children`, `options`, `items`, `menu`, or `submenu`. Selecting that option opens the next menu level. Backspace/Escape returns to the previous level.

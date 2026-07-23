Node7Menu = {}

Node7Menu.Debug = false
Node7Menu.Command = 'n7menu'
Node7Menu.TestCommand = 'n7menutest'
Node7Menu.AdminTestCommand = 'n7adminmenu'
Node7Menu.DefaultKey = 'F6'
Node7Menu.EnableKeyMapping = true
Node7Menu.CloseOnSelect = true
Node7Menu.AllowEscapeClose = true

Node7Menu.Theme = {
    title = 'NODE7 LABS',
    subtitle = 'FRONTIER MENU',
    accent = '#c6a15b'
}

Node7Menu.Permissions = {
    staff = 'node7.staff',
    moderator = 'node7.moderator',
    admin = 'node7.admin',
    owner = 'node7.owner'
}


-- Used only as an owner fallback when the server has not attached the ACE
-- principal to the player yet. ACE remains the primary permission system.
Node7Menu.OwnerIdentifiers = {
    'fivem:19380766',
    'discord:1019014170458456074'
}

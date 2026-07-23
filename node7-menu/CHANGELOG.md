# Changelog

## 1.0.2

- Fixed invalid `fx_version` introduced in 1.0.1.
- ACE remains the primary permission check.
- Added configured owner identifier fallback for RedM principal timing/mapping issues.
- Owner fallback inherits admin, moderator, and staff menu permissions.
- Added configured-owner status to the permission test menu.


## 1.0.1

- Added full ACE diagnostics with exposed player identifiers.
- Added `/n7acecheck`.
- Hardened server-side ACE evaluation.
- Added direct owner identifier fallback configuration.


## 1.0.0

- Initial NODE7 nested menu system.
- Added Red Dead-style NUI.
- Added nested menus and back navigation.
- Added ACE-gated actions.
- Added client events, server events, and commands.
- Added runtime exports.
- Added test menus and permission commands.

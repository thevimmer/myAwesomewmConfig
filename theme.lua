-- [[ Requirements ]]

local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

-- [[ Variables ]]

local theme = {}

-- [[ Desktop ]]

theme.wibox_position = "top"
theme.wallpaper_color = "#292e42"
theme.useless_gap = dpi(7)

-- [[ General ]]

theme.font = "JetBrainsMonoNFP 11"

theme.bg_normal = "#1a1b26"
theme.bg_focus = "#2e3440"
theme.bg_urgent = "#ef6155"
theme.bg_minimize = "#1a1b26"
theme.bg_systray = theme.bg_normal

theme.fg_normal = "#c0caf5"
theme.fg_focus = "#7aa2f7"
theme.fg_urgent = "#ffffff"
theme.fg_minimize = "#a9b1d6"

theme.border_width = dpi(2)
theme.border_normal = "#2e3440"
theme.border_focus = "#7aa2f7"
theme.border_marked = "#ff0000"

-- [[ Taglist ]]

theme.taglist_fg_empty = "#2e3440"
theme.taglist_bg_empty = "#1a1b26"
theme.taglist_fg_focus = "#1a1b26"
theme.taglist_bg_focus = "#7aa2f7"
theme.taglist_bg_urgent = "#ef6155"
theme.taglist_fg_urgent = "#ffffff"

-- [[ Clocktext ]]

theme.textclock_bg = "#7aa2f7"
theme.textclock_fg = "#1a1b26"

-- [[ Notifications ]]

theme.notification_font = theme.font
theme.notification_bg = "#1a1b26"
theme.notification_fg = "#c0caf5"
theme.notification_border_color = "#7aa2f7"
theme.notification_border_width = dpi(2)
theme.notification_margin = dpi(3)
theme.notification_icon_size = dpi(100)

return theme

-- [[ Requerements ]]

pcall(require, "luarocks.loader")

local awful = require("awful")

local gears = require("gears")

local wibox = require("wibox")

local beautiful = require("beautiful")

local naughty = require("naughty")

require("awful.autofocus")

-- [[ Error Handling ]]

if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors,
	})
end

do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		if in_error then
			return
		end
		in_error = true
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err),
		})
		in_error = false
	end)
end

-- [[ Definitions ]]

local terminal = "kitty" --NOTE make sure you change the classname too below
local modkey = "Mod4"
local default_widget_text = "n/a"

-- [[ Cache ]]

local cache = {}

-- [[ Layouts ]]

awful.layout.layouts = {
	awful.layout.suit.tile,
}

local default_layout = awful.layout.layouts[1]

-- [[ Theme ]]

beautiful.init(os.getenv("HOME") .. "/.config/awesome/myAwesomewmConfig/theme.lua")

naughty.config.defaults["icon_size"] = beautiful.notification_icon_size

-- [[ Utils ]]

local function read_file(filename)
	local file, _ = io.open(filename, "r")
	if not file then
		return nil
	end
	local output = file:read("a"):match("^%s*(.-)%s*$" or "")
	file:close()
	return output
end

local function h(color)
	return string.gsub(color, "#", "")
end

local function add_padding(...)
	local args = { ... }
	local ret = " "
	for _, text in ipairs(args) do
		ret = ret .. text .. " "
	end
	return ret
end

-- [[ Icons ]]

local battery_icons = {
	["100_charging"] = "󰂅",
	["100"] = "󰁹",
	["90_charging"] = "󰂋",
	["90"] = "󰂂",
	["80_charging"] = "󰂊",
	["80"] = "󰂁",
	["70_charging"] = "󰢞",
	["70"] = "󰂀",
	["60_charging"] = "󰂉",
	["60"] = "󰁿",
	["50_charging"] = "󰢝",
	["50"] = "󰁾",
	["40_charging"] = "󰂈",
	["40"] = "󰁽",
	["30_charging"] = "󰂇",
	["30"] = "󰁼",
	["20_charging"] = "󰂆",
	["20"] = "󰁻",
	["10_charging"] = "󰢜",
	["10"] = "󰁺",
}

local windows_icons = {
	["firefox"] = "",
	["Spotify"] = "",
	["MuPDF"] = "",
	["kitty"] = "",
	["_"] = "󰘔",
}

local volume_icons = {
	["volume_up"] = "󰕾",
	["mute"] = "󰖁",
}

local brightness_icon = "󰖨"

local temperature_icons = {
	["empty"] = "",
	["quarter"] = "",
	["half"] = "",
	["three_quarters"] = "",
	["full"] = "",
}

local wifi_icons = {
	["off"] = "󰤮",
	["4"] = "󰤨",
	["3"] = "󰤥",
	["2"] = "󰤢",
	["1"] = "󰤟",
}

-- [[ Functions ]]

local function set_tags(s)
	local default_tags_names = { "1", "2", "3", "4", "5", "6", "7 ", "8", "9" }
	for i, name in ipairs(default_tags_names) do
		awful.tag.add(name, {
			screen = s,
			layout = awful.layout.suit.tile,
			num = i,
			is_win_sticky = false,
		}, default_layout)
	end
end

local function set_wallpaper()
	if beautiful.wallpaper then
		gears.wallpaper.maximized(beautiful.wallpaper)
	elseif beautiful.wallpaper_color then
		gears.wallpaper.set(beautiful.wallpaper_color)
	end
end

local function update_tagname(tag)
	if #tag:clients() == 0 or tag:clients()[1].class == "fzf_run" then
		tag.name = tag.num
	else
		local tag_icon = windows_icons["_"]
		for _, c in ipairs(tag:clients()) do
			if windows_icons[c.class] ~= nil then
				tag_icon = windows_icons[c.class]
				break
			end
		end
		tag.name = tag.num .. ": " .. tag_icon
	end

	if tag.is_win_sticky then
		tag.name = tag.name .. "~"
	end
end

local function update_battery(mywidget)
	local battery_capacity_file_output = read_file("/sys/class/power_supply/BAT0/capacity")
	if not battery_capacity_file_output then --FIX the battery widget disapeared once for no raison
		mywidget.text = add_padding(default_widget_text)
		return
	end

	local battery_status_file_output = read_file("/sys/class/power_supply/BAT0/status")
	if not battery_status_file_output then
		mywidget.text = add_padding(default_widget_text)
		return
	end

	local battery_capacity = tonumber(battery_capacity_file_output)
	local is_charging = battery_status_file_output == "Charging"

	local icon_name = tostring(math.floor(battery_capacity / 10) * 10)
	if is_charging then
		icon_name = icon_name .. "_charging"
	end

	mywidget.text = add_padding(battery_icons[icon_name], battery_capacity .. "%")
end

local function update_brightness(mywidget)
	if not cache["max_brightness_file_output"] then
		cache["max_brightness_file_output"] = read_file("/sys/class/backlight/intel_backlight/max_brightness")
		if not cache["max_brightness_file_output"] then
			mywidget.text = add_padding(default_widget_text)
			return
		end
	end
	local max_brightness_file_output = cache["max_brightness_file_output"]

	local brightness_file_output = read_file("/sys/class/backlight/intel_backlight/brightness")
	if not brightness_file_output then
		mywidget.text = default_widget_text
		return
	end

	local max_brightness = tonumber(max_brightness_file_output)
	local brightness = tonumber(brightness_file_output)

	local brightness_perc = math.floor((brightness / max_brightness) * 100)

	mywidget.text = add_padding(brightness_icon, brightness_perc .. "%")
end

local function update_soundvolume(mywidget)
	awful.spawn.easy_async_with_shell("amixer get Master | rg -oP '\\d+%' | head -n 1", function(volume_cmd_output)
		local volume_str = volume_cmd_output:match("^[^\n\r]+")
		if volume_str == nil then
			mywidget.text = add_padding(default_widget_text)
			return
		end

		local icon = volume_icons["volume_up"]
		if volume_str == "0%" then
			icon = volume_icons["mute"]
		end

		mywidget.text = add_padding(icon, volume_str) --NOTE volume_str includes the % sign
	end)
end

local function update_temperature(mywidget)
	local temperature_file_output = read_file("/sys/class/thermal/thermal_zone0/temp")
	if not temperature_file_output then
		mywidget.text = add_padding(default_widget_text)
		return
	end

	local temperature = math.floor(tonumber(temperature_file_output) / 1000)

	local icon
	if temperature <= 40 then
		icon = temperature_icons["empty"]
	elseif temperature <= 50 then
		icon = temperature_icons["quarter"]
	elseif temperature <= 60 then
		icon = temperature_icons["half"]
	elseif temperature <= 70 then
		icon = temperature_icons["three_quarters"]
	else
		icon = temperature_icons["full"]
	end

	mywidget.text = add_padding(icon, temperature .. "°C")
end

local function update_wifisignal(mywidget)
	awful.spawn.easy_async_with_shell(
		"nmcli -t -f active,ssid,signal dev wifi | rg '^yes' | awk -F: '{print $3}' | awk '{print $1}'",
		function(signal_strength_output)
			local signal_strength = tonumber(signal_strength_output:match("^[^\n\r]+"))

			local icon
			if not signal_strength then
				icon = wifi_icons["off"]
				mywidget.text = add_padding(icon)
				return
			elseif signal_strength >= 80 then
				icon = wifi_icons["4"]
			elseif signal_strength >= 60 then
				icon = wifi_icons["3"]
			elseif signal_strength >= 40 then
				icon = wifi_icons["2"]
			else
				icon = wifi_icons["1"]
			end

			mywidget.text = add_padding(icon, signal_strength .. "%")
		end
	)
end

-- [[ Clock widget ]]

local myclockwidget_format = '<span foreground="' .. beautiful.textclock_fg .. '"> %a %b %d, %H:%M </span>'
local myclockwidget = wibox.widget.textclock(myclockwidget_format)
do
	myclockwidget = wibox.container.background(myclockwidget, beautiful.textclock_bg)
	myclockwidget.widget:buttons(awful.util.table.join(awful.button({}, 1, nil, function()
		awful.spawn(terminal .. ' -e nvim "' .. os.getenv("HOME") .. '/Organizer/home.wiki"')
	end)))
end

-- [[ Tags widgets ]]

local mytaglistwidget_template = {
	{
		{
			id = "text_role",
			widget = wibox.widget.textbox,
		},
		left = 10,
		right = 10,
		widget = wibox.container.margin,
	},
	id = "background_role",
	widget = wibox.container.background,
}

local function mytaglistwidget_callback(self, tag, index, objects)
	if tag.selected or tag == awful.screen.focused().selected_tag then
		self:get_children_by_id("background_role")[1].bg = beautiful.taglist_bg_focus
	else
		self:get_children_by_id("background_role")[1].bg = beautiful.taglist_bg_normal
	end
end

local function mytaglistwidget_filter(t)
	return #t:clients() > 0 or t == awful.screen.focused().selected_tag
end

local mytaglistwidget_buttons = gears.table.join(
	awful.button({}, 1, function(t)
		t:view_only()
	end),

	awful.button({ modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),

	awful.button({}, 3, awful.tag.viewtoggle),

	awful.button({ modkey }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),

	awful.button({}, 4, function(t)
		awful.tag.viewnext(t.screen)
	end),

	awful.button({}, 5, function(t)
		awful.tag.viewprev(t.screen)
	end)
)

-- [[ Right-side widgets ]]

local mybatterywidget = wibox.widget.textbox()
update_battery(mybatterywidget)

local mybrightnesswidget = wibox.widget.textbox()
update_brightness(mybrightnesswidget)

--ADD capslock widget

local mysoundvolumewidget = wibox.widget.textbox()
update_soundvolume(mysoundvolumewidget)

local mytemperaturewidget = wibox.widget.textbox()
update_temperature(mytemperaturewidget)

local mywifisignalwidget = wibox.widget.textbox()
update_wifisignal(mywifisignalwidget)

local mywidgets_timer = gears.timer({ timeout = 2 })
mywidgets_timer:connect_signal("timeout", function()
	update_battery(mybatterywidget)
	update_brightness(mybrightnesswidget)
	update_soundvolume(mysoundvolumewidget)
	update_temperature(mytemperaturewidget)
	update_wifisignal(mywifisignalwidget)
end)
mywidgets_timer:start()

-- [[ Screens setup ]]

awful.screen.connect_for_each_screen(function(s)
	set_tags(s)
	set_wallpaper()

	s.mytaglistwidget = awful.widget.taglist({
		screen = s,
		filter = mytaglistwidget_filter,
		buttons = mytaglistwidget_buttons,
		widget_template = mytaglistwidget_template,
		layout = wibox.layout.fixed.horizontal,
		create_callback = mytaglistwidget_callback,
	})

	s.mywibox = awful.wibar({ position = beautiful.wibox_position, screen = s })

	s.mywibox:setup({
		{
			layout = wibox.layout.fixed.horizontal,
			s.mytaglistwidget,
		},
		nil,
		{
			layout = wibox.layout.fixed.horizontal,
			-- wibox.widget.systray(),
			mywifisignalwidget,
			mysoundvolumewidget,
			mytemperaturewidget,
			mybrightnesswidget,
			mybatterywidget,
			myclockwidget,
		},
		layout = wibox.layout.align.horizontal,
	})
	--ADD an indication for the current layout
end)

-- [[ Commands ]]

local locker_cmd = "i3lock --color="
	.. h(beautiful.wallpaper_color)
	.. " --keyhl-color="
	.. h(beautiful.fg_focus)
	.. " --inside-color="
	.. h(beautiful.bg_normal)
	.. " --ring-color="
	.. h(beautiful.fg_focus)
	.. " --line-color="
	.. h(beautiful.bg_normal)
	.. " --separator-color="
	.. h(beautiful.bg_normal)
	.. " --time-color="
	.. h(beautiful.fg_normal)
	.. " --date-color="
	.. h(beautiful.fg_normal)
	.. " --verif-color="
	.. h(beautiful.fg_normal)
	.. " --wrong-color="
	.. h(beautiful.bg_urgent)
	.. " --layout-color="
	.. h(beautiful.fg_normal)
	.. " --indicator --radius=100 --clock"

local screenshot_cmd = 'scrot -s -F "$HOME/Screenshots/$(date +"%s").png"'

local prompt_cmd = terminal .. ' --class fzf_run -e "$HOME/Scripts/fzf_run.sh"'
--FIX make it scripts-independent

-- [[ Some key bindings functions ]]

local last_client = nil

local function move_to_the_last_selected_win()
	if last_client and last_client.valid then
		if last_client.screen then
			awful.screen.focus(last_client.screen)
		end

		local last_tag = last_client.first_tag
		if last_tag then
			last_tag:view_only()
		end

		client.focus = last_client
		last_client:raise()
	end
end

local function toggle_stickiness(c)
	c.sticky = not c.sticky
	for _, tag in ipairs(c:tags()) do
		if c.sticky then
			tag.name = tag.name .. "~"
			tag.is_win_sticky = true
		else
			tag.name = string.gsub(tag.name, "~", "")
			tag.is_win_sticky = false
		end
	end
end

-- [[ Key bindings ]]

globalkeys = gears.table.join(
	awful.key({ modkey, "Shift" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),

	awful.key({ modkey, "Shift" }, "q", awesome.quit, { description = "quit awesome", group = "awesome" }),

	awful.key({ modkey }, "b", function()
		myscreen = awful.screen.focused()
		myscreen.mywibox.visible = not myscreen.mywibox.visible
	end, { description = "toggle statusbar", group = "awesome" }),

	awful.key({ modkey, "Control" }, "j", function()
		awful.screen.focus_relative(1)
	end, { description = "focus the next screen", group = "screen" }),

	awful.key({ modkey, "Control" }, "k", function()
		awful.screen.focus_relative(-1)
	end, { description = "focus the previous screen", group = "screen" }),

	awful.key({ modkey }, "Left", awful.tag.viewprev, { description = "view previous", group = "tag" }),

	awful.key({ modkey }, "Right", awful.tag.viewnext, { description = "view next", group = "tag" }),

	awful.key({ modkey }, "Escape", awful.tag.history.restore, { description = "go back", group = "tag" }),

	awful.key(
		{ modkey },
		"Tab",
		move_to_the_last_selected_win,
		{ description = "move to the last selected window", group = "client" }
	),

	awful.key({ modkey }, "l", function()
		awful.tag.incmwfact(0.05)
	end, { description = "increase master width factor", group = "layout" }),

	awful.key({ modkey }, "h", function()
		awful.tag.incmwfact(-0.05)
	end, { description = "decrease master width factor", group = "layout" }),

	awful.key({ modkey, "Shift" }, "h", function()
		awful.tag.incnmaster(1, nil, true)
	end, { description = "increase the number of master clients", group = "layout" }),

	awful.key({ modkey, "Shift" }, "l", function()
		awful.tag.incnmaster(-1, nil, true)
	end, { description = "decrease the number of master clients", group = "layout" }),

	awful.key({ modkey, "Control" }, "h", function()
		awful.tag.incncol(1, nil, true)
	end, { description = "increase the number of columns", group = "layout" }),

	awful.key({ modkey, "Control" }, "l", function()
		awful.tag.incncol(-1, nil, true)
	end, { description = "decrease the number of columns", group = "layout" }),

	awful.key({ modkey }, "space", function()
		awful.layout.inc(1)
	end, { description = "select next", group = "layout" }),

	awful.key({ modkey, "Shift" }, "space", function()
		awful.layout.inc(-1)
	end, { description = "select previous", group = "layout" }),

	awful.key({ modkey, "Shift" }, "Return", function()
		awful.spawn(terminal)
	end, { description = "open a terminal", group = "launcher" }),

	awful.key({ modkey }, "p", function()
		awful.spawn.with_shell(prompt_cmd)
	end, { description = "open the prompt", group = "launcher" }),
	--FIX the window is slow to open

	awful.key({ modkey }, "d", function()
		awful.spawn(locker_cmd)
	end, { description = "lock the screen", group = "awesome" }),

	awful.key({ modkey }, "s", function()
		awful.spawn.with_shell(screenshot_cmd)
	end, { description = "take a screenshot", group = "launcher" }),

	awful.key({ modkey }, "j", function()
		awful.client.focus.byidx(1)
	end, { description = "focus next by index", group = "client" }),

	awful.key({ modkey }, "k", function()
		awful.client.focus.byidx(-1)
	end, { description = "focus previous by index", group = "client" }),

	awful.key({ modkey, "Shift" }, "j", function()
		awful.client.swap.byidx(1)
	end, { description = "swap with next client by index", group = "client" }),

	awful.key({ modkey, "Shift" }, "k", function()
		awful.client.swap.byidx(-1)
	end, { description = "swap with previous client by index", group = "client" }),

	awful.key({ modkey }, "u", awful.client.urgent.jumpto, { description = "jump to urgent client", group = "client" })
)

clientkeys = gears.table.join(
	awful.key({ modkey }, "m", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, { description = "toggle fullscreen", group = "client" }),

	awful.key({ modkey, "Shift" }, "c", function(c)
		c:kill()
	end, { description = "close", group = "client" }),

	awful.key({ modkey }, "f", function(c)
		awful.client.floating.toggle()
		local g = c:geometry()
		c:geometry({ x = 0, y = 0, width = g.width, height = g.height })
	end, { description = "toggle floating", group = "client" }),

	awful.key({ modkey }, "Return", function(c)
		c:swap(awful.client.getmaster())
	end, { description = "move to master", group = "client" }),

	awful.key({ modkey }, "o", function(c)
		c:move_to_screen()
	end, { description = "move to screen", group = "client" }),

	awful.key({ modkey }, "t", function(c)
		c.ontop = not c.ontop
	end, { description = "toggle keep on top", group = "client" }),

	awful.key({ modkey }, "0", toggle_stickiness, { description = "toggle stickiness", group = "client" })
)

for i = 1, 9 do
	globalkeys = gears.table.join(
		globalkeys,

		awful.key({ modkey }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, { description = "view tag #" .. i, group = "tag" }),

		awful.key({ modkey, "Control" }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end, { description = "toggle tag #" .. i, group = "tag" }),

		awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end, { description = "move focused client to tag #" .. i, group = "tag" }),

		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end, { description = "toggle focused client on tag #" .. i, group = "tag" })
	)
end

root.keys(globalkeys)

-- [[ Buttons ]]

clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
	end),

	awful.button({ modkey }, 1, function(c)
		if not c.floating then
			c.floating = true
		end
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.move(c)
	end),

	awful.button({ modkey }, 3, function(c)
		if not c.floating then
			c.floating = true
		end
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.resize(c)
	end)
)

-- [[ Rules ]]

awful.rules.rules = {
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
		},
	},
	{
		rule = { floating = true },
		properties = {
			ontop = true,
		},
	},
	{
		rule_any = {},
		properties = { floating = true },
	},
	{
		rule_any = {
			class = { "Firefox" },
			name = { "Picture-in-Picture" },
		},
		properties = {
			sticky = true,
			focusable = false,
			ontop = true,
		},
	},
	{
		rule = { class = "fzf_run" },
		properties = {
			focus = true,
			floating = true,
			width = 400,
			height = 308,
			focusable = true,
			skip_taskbar = true,
			ontop = true,
			placement = function(c)
				awful.placement.centered(c, { honor_workarea = true })
			end,
			callback = function(c)
				c:connect_signal("unfocus", function()
					c:kill()
				end)

				c:connect_signal("property::geometry", function()
					c:geometry({ width = 400, height = 308 })
					awful.placement.centered(c, nil)
				end)

				c:connect_signal("button::press", function()
					awful.placement.centered(c, nil)
				end)

				c:connect_signal("request::geometry", function(c, context, hints)
					if context ~= "mouse.move" and context ~= "mouse.resize" then
						return awful.placement.centered(c, nil)
					end
				end)
			end,
		},
	},
}

-- [[ Signals ]]

client.connect_signal("manage", function(c)
	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		awful.placement.no_offscreen(c)
	end
	for _, t in ipairs(c:tags()) do
		update_tagname(t)
	end
end)

client.connect_signal("unmanage", function(c)
	for _, t in ipairs(c:tags()) do
		update_tagname(t)
	end
end)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
	last_client = c
end)

client.connect_signal("tagged", function(c, t)
	update_tagname(t)
end)

client.connect_signal("untagged", function(c, t)
	update_tagname(t)
end)

client.connect_signal("mouse::enter", function(c)
	c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

screen.connect_signal("property::geometry", set_wallpaper)

tag.connect_signal("property::clients", function(t)
	update_tagname(t)
end)

tag.connect_signal("property::selected", function(t)
	update_tagname(t)
end)

--FIX select primary screen by default at startup

--ADD run an xrandr script when a screen is attached

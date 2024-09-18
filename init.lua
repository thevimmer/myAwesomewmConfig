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

local terminal = "alacritty"
local modkey = "Mod4"

-- [[ Layouts ]]

awful.layout.layouts = {
	awful.layout.suit.tile,
}

local default_layout = awful.layout.layouts[1]

-- [[ Theme ]]

beautiful.init(os.getenv("HOME") .. "/.config/awesome/myAwesomewmConfig/theme.lua")

naughty.config.defaults["icon_size"] = beautiful.notification_icon_size

-- [[ Functions ]]

local function set_wallpaper(s)
	if beautiful.wallpaper then
		gears.wallpaper.maximized(beautiful.wallpaper)
	else
		gears.wallpaper.set(beautiful.wallpaper_color)
	end
end

local function h(color)
	return string.gsub(color, "#", "")
end

local function is_client_class(tag, className)
	for _, c in ipairs(tag:clients()) do
		if c.class == className then
			return true
		end
	end
	return false
end

local function update_tagname(tag)
	if #tag:clients() <= 0 then
		tag.name = tag.num
	elseif is_client_class(tag, "firefox") then
		tag.name = tag.num .. ": "
	elseif is_client_class(tag, "Spotify") then
		tag.name = tag.num .. ": "
	elseif is_client_class(tag, "MuPDF") then
		tag.name = tag.num .. ": "
	elseif is_client_class(tag, "Alacritty") then
		tag.name = tag.num .. ": "
	elseif is_client_class(tag, "fzf_run") then
		tag.name = tag.num
	else
		tag.name = tag.num .. ": 󰘔"
	end

	if tag.is_win_sticky then
		tag.name = tag.name .. "~"
	end
end

local last_client = nil

local function move_to_the_last_selected_win()
	if last_client then
		if last_client.screen then --FIX this line causes an 'invalid object' error
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

local function update_battery(batterywidget)
	local capacity_file, err = io.open("/sys/class/power_supply/BAT0/capacity", "r")
	if not capacity_file then
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, error when reading the battery capacity sys file: " .. err,
			text = awesome.startup_errors,
		})
		return
	end
	local battery_capacity = tonumber(capacity_file:read("a"))
	capacity_file:close()

	local status_file, err = io.open("/sys/class/power_supply/BAT0/status", "r")
	if not status_file then
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, error when reading the battery capacity file: " .. err,
			text = awesome.startup_errors,
		})
		return
	end
	local battery_status = status_file:read("a"):match("^%s*(.-)%s*$")
	status_file:close()

	local is_charging = battery_status == "Charging"
	local battery_icon
	if battery_capacity == 100 then
		if is_charging then
			battery_icon = "󰂅"
		else
			battery_icon = "󰁹"
		end
	elseif battery_capacity >= 90 then
		if is_charging then
			battery_icon = "󰂋"
		else
			battery_icon = "󰂂"
		end
	elseif battery_capacity >= 80 then
		if is_charging then
			battery_icon = "󰂊"
		else
			battery_icon = "󰂁"
		end
	elseif battery_capacity >= 70 then
		if is_charging then
			battery_icon = "󰢞"
		else
			battery_icon = "󰂀"
		end
	elseif battery_capacity >= 60 then
		if is_charging then
			battery_icon = "󰂈"
		else
			battery_icon = "󰁿"
		end
	elseif battery_capacity >= 50 then
		if is_charging then
			battery_icon = "󰂈"
		else
			battery_icon = "󰁾"
		end
	elseif battery_capacity >= 40 then
		if is_charging then
			battery_icon = "󰂈"
		else
			battery_icon = "󰁽"
		end
	elseif battery_capacity >= 30 then
		if is_charging then
			battery_icon = "󰂇"
		else
			battery_icon = "󰁼"
		end
	elseif battery_capacity >= 20 then
		if is_charging then
			battery_icon = "󰂆"
		else
			battery_icon = "󰁻"
		end
	else
		if is_charging then
			battery_icon = "󰢜"
		else
			battery_icon = "󰁺"
		end
	end

	batterywidget.text = " " .. battery_icon .. " " .. battery_capacity .. "% "
end

local function update_brightness(mybrightnesswidget)
	local max_brightness_file, err = io.open("/sys/class/backlight/intel_backlight/max_brightness", "r")
	if not max_brightness_file then
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, error when reading the max brightness sys file: " .. err,
			text = awesome.startup_errors,
		})
		return
	end
	local max_brightness = tonumber(max_brightness_file:read("a"))
	max_brightness_file:close()

	local brightness_file, err = io.open("/sys/class/backlight/intel_backlight/brightness", "r")
	if not brightness_file then
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, error when reading the brightness sys file: " .. err,
			text = awesome.startup_errors,
		})
		return
	end
	local brightness = tonumber(brightness_file:read("a"))
	brightness_file:close()

	local brightness_perc = math.floor((brightness / max_brightness) * 100)

	mybrightnesswidget.text = " 󰖨 " .. brightness_perc .. "% "
end

local function update_capslock(mycapslockwidget)
	local handle = io.popen("xset -q | grep Caps")
	if not handle then
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, error when reading the command output: " .. err,
			text = awesome.startup_errors,
		})
		return
	end
	local output = handle:read("*a"):match("^%s*(.-)%s*$" or "")
	handle:close()
	local is_capslock_on = output:find("^00: Caps Lock:   on")
	if is_capslock_on then
		mycapslockwidget.text = " 󰪛 "
	else
		mycapslockwidget.text = ""
	end
end

local function update_soundvolume(mysoundvolumewidget)
	local handle = io.popen("amixer get Master | grep -oP '\\d+%' | head -n 1")
	if not handle then
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, error when reading the command output: " .. err,
			text = awesome.startup_errors,
		})
		return
	end
	local output = handle:read("*a"):match("^%s*(.-)%s*$" or "")
	local icon = "󰕾"
	local volume = string.gsub(output, "%%", "")
	volume = tonumber(volume)
	if volume <= 0 then
		icon = "󰖁"
	end
	handle:close()
	mysoundvolumewidget.text = " " .. icon .. " " .. output .. " "
end

local function update_temperature(mytemperaturewidget)
	local handle = io.popen("sensors | grep 'acpitz-acpi-0' -A 2 | grep 'temp1:' | awk '{print $2}'")
	if not handle then
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, error when reading the command output: " .. err,
			text = awesome.startup_errors,
		})
		return
	end
	local output = handle:read("*a"):match("^%s*(.-)%s*$" or "")
	handle:close()
	local value_s = string.gsub(output, "+", "")
	value_s = string.gsub(value_s, "°C", "")
	local value = tonumber(value_s)
	local icon
	if value <= 40 then
		icon = ""
	elseif value <= 50 then
		icon = ""
	elseif value <= 60 then
		icon = ""
	elseif value <= 70 then
		icon = ""
	else
		icon = ""
	end
	mytemperaturewidget.text = " " .. icon .. " " .. value .. "°C "
end

local function update_wifisignal(mywifisignalwidget)
	awful.spawn.easy_async_with_shell(
		"nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | awk -F: '{print $3}' | awk '{print $1}'",
		function(stdout)
			local signal_strength = tonumber(stdout:match("^[^\n\r]+"))

			if not signal_strength then
				mywifisignalwidget.text = " 󰤮 "
			elseif signal_strength >= 80 then
				mywifisignalwidget.text = " 󰤨 "
			elseif signal_strength >= 60 then
				mywifisignalwidget.text = " 󰤥 "
			elseif signal_strength >= 40 then
				mywifisignalwidget.text = " 󰤢 "
			else
				mywifisignalwidget.text = " 󰤟 "
			end
		end
	)
end

local function setup_tags(s)
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

-- [[ Wibox ]]

local n_tags = 9 --NOTE and for some raison a mystrious number

local mytextclock_format = '<span foreground="' .. beautiful.textclock_fg .. '"> %a %b %d, %H:%M </span>'
local mytextclock = wibox.widget.textclock(mytextclock_format)
do
	mytextclock = wibox.container.background(mytextclock, beautiful.textclock_bg)
	mytextclock.widget:buttons(awful.util.table.join(awful.button({}, 1, nil, function()
		awful.spawn(terminal .. ' -e nvim "' .. os.getenv("HOME") .. '/Organizer/home.wiki"')
	end)))
end

local mytaglist_buttons = gears.table.join(
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

local mytaglist_widget_template = {
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

local function mytaglist_callback(self, tag, index, objects)
	if tag.selected or tag == awful.screen.focused().selected_tag then
		self:get_children_by_id("background_role")[1].bg = beautiful.taglist_bg_focus
	else
		self:get_children_by_id("background_role")[1].bg = beautiful.taglist_bg_normal
	end
end

local function mytaglist_filter(t)
	return #t:clients() > 0 or t == awful.screen.focused().selected_tag
end

local mybatterywidget = wibox.widget.textbox()
update_battery(mybatterywidget)

local mybrightnesswidget = wibox.widget.textbox()
update_brightness(mybrightnesswidget)

local mycapslockwidget = wibox.widget.textbox()
update_capslock(mycapslockwidget)

local mysoundvolumewidget = wibox.widget.textbox()
update_soundvolume(mysoundvolumewidget)

local mytemperaturewidget = wibox.widget.textbox()
update_temperature(mytemperaturewidget)

local mywifisignalwidget = wibox.widget.textbox()
update_wifisignal(mywifisignalwidget)

local mytimer = gears.timer({ timeout = 1 })
mytimer:connect_signal("timeout", function()
	update_battery(mybatterywidget)
	update_brightness(mybrightnesswidget)
	update_capslock(mycapslockwidget)
	update_soundvolume(mysoundvolumewidget)
	update_temperature(mytemperaturewidget)
	update_wifisignal(mywifisignalwidget)
end)
mytimer:start()

gears.timer({
	timeout = 10,
	call_now = true,
	autostart = true,
	callback = function() end,
})

awful.screen.connect_for_each_screen(function(s)
	set_wallpaper(s)
	setup_tags(s)

	s.mytaglist = awful.widget.taglist({
		screen = s,
		filter = mytaglist_filter,
		buttons = mytaglist_buttons,
		widget_template = mytaglist_widget_template,
		layout = wibox.layout.fixed.horizontal,
		create_callback = mytaglist_callback,
	})

	s.mywibox = awful.wibar({ position = beautiful.wibox_position, screen = s })

	s.mywibox:setup({
		{
			layout = wibox.layout.fixed.horizontal,
			s.mytaglist,
		},
		nil,
		{
			layout = wibox.layout.fixed.horizontal,
			-- mycapslockwidget,
			-- wibox.widget.systray(),
			mywifisignalwidget,
			mysoundvolumewidget,
			mytemperaturewidget,
			mybrightnesswidget,
			mybatterywidget,
			mytextclock,
		},
		layout = wibox.layout.align.horizontal,
	})
	--ADD an indication of the current layout
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

-- [[ Key Bindings ]]

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
		awful.spawn.with_shell(terminal .. ' --class fzf_run -e "$HOME/Scripts/fzf_run.sh"')
	end, { description = "open fzf_run", group = "launcher" }),
	--FIX the window is slow to open

	awful.key({ modkey }, "d", function()
		awful.spawn(locker_cmd)
	end, { description = "lock the screen", group = "awesome" }),

	awful.key({ modkey }, "s", function()
		awful.spawn.with_shell('scrot -s -F "$HOME/Screenshots/$(date +"%s").png"')
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

	awful.key({ modkey }, "0", function(c)
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
	end, { description = "toggle stickiness", group = "client" })
)

for i = 1, n_tags do
	globalkeys = gears.table.join(
		globalkeys,

		awful.key({ modkey }, "#" .. i + 9, function()
			last_selected_tag = client.focus and client.focus.first_tag or nil
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

root.keys(globalkeys)

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

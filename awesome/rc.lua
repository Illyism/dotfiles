-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local common = require("awful.widget.common")

local lain = require("lain")
local vicious = require("vicious")


-- Initialize widget
datewidget = wibox.widget.textbox()
-- Register widget
vicious.register(datewidget, vicious.widgets.date, " %b %d, %R ", 60)

-- Initialize widget
batwidget = wibox.widget.textbox()
-- Register widget
vicious.register(batwidget, vicious.widgets.bat, " $2% • $3 ", 120, "BAT0")

-- Systray is added later to widgets
widgets = {datewidget, batwidget}

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({ preset = naughty.config.presets.critical,
			 title = "Oops, there were errors during startup!",
			 text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function (err)
		-- Make sure we don't go into an endless error loop
		if in_error then return end
		in_error = true

		naughty.notify({ preset = naughty.config.presets.critical,
				 title = "Oops, an error happened!",
				 text = err })
		in_error = false
	end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- Theme can be changed, but must contain bg_widgets array for each widget. 
beautiful.init(awful.util.getdir("config") .. "/" .. "themes/peura/theme.lua")

local bg_widgets = beautiful.bg_widgets
table.insert(bg_widgets, 1, beautiful.bg_normal)

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
	lain.layout.termfair,
	lain.layout.centerfair,
	lain.layout.cascade,
	lain.layout.cascadetile,
	lain.layout.centerwork,
	lain.layout.uselessfair,
	lain.layout.uselesspiral,
	lain.layout.uselesstile
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
	for s = 1, screen.count() do
		gears.wallpaper.maximized(beautiful.wallpaper, s, true)
	end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
	-- Each screen has its own tag table.
	tags[s] = awful.tag({ 1, 2, 3, 4 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
	{ "manual", terminal .. " -e man awesome" },
	{ "edit config", editor_cmd .. " " .. awesome.conffile },
	{ "restart", awesome.restart },
	{ "quit", awesome.quit },
	{ "shutdown", terminal .. " -e shutdown" }
}

mymainmenu = awful.menu({ items = { 
	{ "awesome", myawesomemenu, beautiful.awesome_icon },
}})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
					 menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
	awful.button({ }, 1, awful.tag.viewonly),
	awful.button({ modkey }, 1, awful.client.movetotag),
	awful.button({ }, 3, awful.tag.viewtoggle),
	awful.button({ modkey }, 3, awful.client.toggletag),
	awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
	awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
)
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
	awful.button({ }, 1, function (c)
		if c == client.focus then
			c.minimized = true
		else
			-- Without this, the following
			-- :isvisible() makes no sense
			c.minimized = false
			if not c:isvisible() then
			  awful.tag.viewonly(c:tags()[1])
			end
			-- This will also un-minimize
			-- the client, if needed
			client.focus = c
			c:raise()
		end
	end),
	awful.button({ }, 3, function ()
		if instance then
			instance:hide()
			instance = nil
		else
			instance = awful.menu.clients({
				theme = { width = 250 }
			})
		end
	end),
	awful.button({ }, 4, function ()
		awful.client.focus.byidx(1)
		if client.focus then client.focus:raise() end
	end),
	awful.button({ }, 5, function ()
		awful.client.focus.byidx(-1)
		if client.focus then client.focus:raise() end
	end)
)

local separator_text = wibox.widget.textbox()
separator_text:set_markup("◢")
separator_text:set_font("sans 46")

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function update_function(w, buttons, label, data, objects)
	-- update the widgets, creating them if needed
	w:reset()
	updateFirstSeparator(beautiful.bg_normal)
	local len = tablelength(objects)
	for i, o in ipairs(objects) do
		local cache = data[o]
		local ib, tb, bgb, l
		if cache then
			ib = cache.ib
			tb = cache.tb
			bgb = cache.bgb
		else
			ib = wibox.widget.imagebox()
			tb = wibox.widget.textbox()
			bgb = wibox.widget.background()
			l = wibox.layout.fixed.horizontal()

			-- All of this is added in a fixed widget
			l:fill_space(true)
			l:add(ib)
			l:add(tb)

			-- And all of this gets a background
			bgb:set_widget(l)

			bgb:buttons(common.create_buttons(buttons, o))

			data[o] = {
				ib = ib,
				tb = tb,
				bgb = bgb,
			}
		end

		local text, bg, bg_image, icon = label(o)
		-- The text might be invalid, so use pcall
		if not pcall(tb.set_markup, tb, text) then
			tb:set_markup("<i>&lt;Invalid text&gt;</i>")
		end
		bgb:set_bg(bg)
		if type(bg_image) == "function" then
			bg_image = bg_image(tb,o,m,objects,i)
		end
		bgb:set_bgimage(bg_image)
		ib:set_image(icon)

		local prevtext, prevBg = nil
		if i > 1 then
			prevtext, prevBg = label(objects[i - 1])
		end

		local nextText, nextBg = nil
		if i < len then
			nextText, nextBg = label(objects[i + 1])
		end

		local bgbContainer = wibox.layout.align.horizontal()
		if prevBg == nil then 
			local lDecoration = wibox.widget.background()
			lDecoration:set_widget(separator_text)
			lDecoration:set_bg(beautiful.bg_normal)
			lDecoration:set_fg(bg)
			bgbContainer:set_left(lDecoration)
		end

		bgbContainer:set_middle(bgb)

		local rDecoration = wibox.widget.background()
		rDecoration:set_widget(separator_text)
		if nextBg ~= beautiful.bg_normal then
			rDecoration:set_bg(bg)
			rDecoration:set_fg(nextBg)
		else
			rDecoration:set_fg(beautiful.bg_normal)
		end
		if nextBg ~= nil then
			bgbContainer:set_right(rDecoration)
			updateFirstSeparator(beautiful.bg_normal)
		else
			updateFirstSeparator(bg)
		end

		local bgbWrapper = wibox.widget.background()
		bgbWrapper:set_widget(bgbContainer)
		bgbWrapper:set_bg(bg)
		bgbWrapper:set_fg(beautiful.bg_normal)
		w:add(bgbWrapper)
	end
end

for s = 1, screen.count() do
	-- Create a promptbox for each screen
	mypromptbox[s] = awful.widget.prompt()
	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	mylayoutbox[s] = awful.widget.layoutbox(s)
	mylayoutbox[s]:buttons(awful.util.table.join(
		awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
		awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
		awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
		awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)
	))
	-- Create a taglist widget
	mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

	-- Widgets that are aligned to the right
	local right_layout = wibox.layout.fixed.horizontal()

	if s == 1 then 
		table.insert(widgets, 1, wibox.widget.systray())
	end

	local firstSeparator = nil
	function updateFirstSeparator (bg)
		firstSeparator:set_bg(bg)
	end

	local i = 1 
	local len = tablelength(widgets)

	-- Function for adding widgets to wibox
	function addW (w)
		local separator = wibox.widget.background()
		separator:set_widget(separator_text)
		if i == 1 then
			firstSeparator = separator
		elseif i == len then
			w = wibox.layout.margin(w, 0, 10, 0, 0)
		end
		separator:set_bg(bg_widgets[i])
		separator:set_fg(bg_widgets[i + 1])
		right_layout:add(separator)
		local wgb = wibox.widget.background()
		wgb:set_widget(w)
		wgb:set_bg(bg_widgets[i + 1])
		wgb:set_fg(beautiful.fg_widget)
		right_layout:add(wgb)
		i = i + 1
	end

	-- Add all widgets in widgets-array to wibox
	for i, v in pairs(widgets) do
		addW(v)
	end

	local tasklist_layout = wibox.layout.flex.horizontal()
	mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons, nil, update_function, tasklist_layout)

	-- Create the wibox
	mywibox[s] = awful.wibox({ position = "top", screen = s })

	-- Widgets that are aligned to the left
	local left_layout = wibox.layout.fixed.horizontal()
--	left_layout:add(mylauncher)
	left_layout:add(mytaglist[s])
	left_layout:add(mypromptbox[s])

	-- Now bring it all together (with the tasklist in the middle)
	local layout = wibox.layout.align.horizontal()
	layout:set_left(left_layout)
	layout:set_middle(mytasklist[s])
	layout:set_right(right_layout)

	mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
	awful.button({ }, 3, function () mymainmenu:toggle() end),
	awful.button({ }, 4, awful.tag.viewnext),
	awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}


local brightnessLocation = "/sys/class/backlight/radeon_bl0/brightness"
function getBrightness()
	 return awful.util.pread("cat " .. brightnessLocation)
end

-- {{{ Key bindings
globalkeys = awful.util.table.join(
	awful.key({ }, "XF86AudioRaiseVolume", function ()
	    awful.util.spawn("amixer set Master 5%+") end),
	awful.key({ }, "XF86AudioLowerVolume", function ()
	    awful.util.spawn("amixer set Master 5%-") end),
	awful.key({ }, "XF86AudioMute", function ()
	    awful.util.spawn("amixer sset Master toggle") end),
	awful.key({ }, "XF86HomePage", function ()
	    awful.util.spawn("firefox") end),
	awful.key({ }, "XF86Calculator", function ()
	    awful.util.spawn(terminal) end),
	awful.key({ }, "XF86MonBrightnessDown", function ()
	    awful.util.spawn_with_shell("echo ".. (getBrightness() - 10) .. " > " .. brightnessLocation) end),
	awful.key({ }, "XF86MonBrightnessUp", function ()
	    awful.util.spawn_with_shell("echo ".. (getBrightness() + 10) .. " > " .. brightnessLocation) end),
	awful.key({ modkey, }, "Left",   awful.tag.viewprev ),
	awful.key({ modkey, }, "Right",  awful.tag.viewnext ),
	awful.key({ modkey, }, "Escape", awful.tag.history.restore),

	awful.key({ modkey,		   }, "j",
		function ()
			awful.client.focus.byidx( 1)
			if client.focus then client.focus:raise() end
		end),
	awful.key({ modkey,}, "k",
		function ()
			awful.client.focus.byidx(-1)
			if client.focus then client.focus:raise() end
		end),
	awful.key({ modkey, }, "w", function () mymainmenu:show() end),

	-- Layout manipulation
	awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)	end),
	awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)	end),
	awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
	awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
	awful.key({ modkey, }, "u", awful.client.urgent.jumpto),
	awful.key({ modkey, }, "Tab",
		function ()
			awful.client.focus.history.previous()
			if client.focus then
				client.focus:raise()
			end
		end),

	-- Standard program
	awful.key({ modkey, }, "Return", function () awful.util.spawn(terminal) end),
	awful.key({ modkey, "Shift" }, "Return", function () awful.util.spawn("firefox") end),
	awful.key({ modkey, "Control" }, "r", awesome.restart),
	-- awful.key({ modkey, "Shift"   }, "q", awesome.quit),

	awful.key({ modkey, }, "l", function () awful.tag.incmwfact( 0.05) end),
	awful.key({ modkey, }, "h", function () awful.tag.incmwfact(-0.05) end),
	awful.key({ modkey, "Shift"   }, "h",	 function () awful.tag.incnmaster( 1) end),
	awful.key({ modkey, "Shift"   }, "l",	 function () awful.tag.incnmaster(-1) end),
	awful.key({ modkey, "Control" }, "h",	 function () awful.tag.incncol( 1) end),
	awful.key({ modkey, "Control" }, "l",	 function () awful.tag.incncol(-1) end),
	awful.key({ modkey, }, "space", function () awful.layout.inc(layouts,  1) end),
	awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

	awful.key({ modkey, "Control" }, "n", awful.client.restore),

	-- Prompt
	awful.key({ modkey }, "r", function () mypromptbox[mouse.screen]:run() end),

	awful.key({ modkey }, "x",
			  function ()
				  awful.prompt.run({ prompt = "Run Lua code: " },
				  mypromptbox[mouse.screen].widget,
				  awful.util.eval, nil,
				  awful.util.getdir("cache") .. "/history_eval")
			  end),
	-- Menubar
	awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
	awful.key({ modkey, }, "f", function (c) c.fullscreen = not c.fullscreen  end),
	awful.key({ modkey, "Shift"   }, "c", function (c) c:kill() end),
	awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle),
	awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
	awful.key({ modkey,}, "o", awful.client.movetoscreen),
	awful.key({ modkey, }, "t", function (c) c.ontop = not c.ontop end),
	awful.key({ modkey, }, "n",
		function (c)
			-- The client currently has the input focus, so it cannot be
			-- minimized, since minimized clients can't have the focus.
			c.minimized = true
		end),
	awful.key({ modkey, }, "m",
		function (c)
			c.maximized_horizontal = not c.maximized_horizontal
			c.maximized_vertical   = not c.maximized_vertical
		end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = awful.util.table.join(globalkeys,
		-- View tag only.
		awful.key({ modkey }, "#" .. i + 9,
				  function ()
						local screen = mouse.screen
						local tag = awful.tag.gettags(screen)[i]
						if tag then
						   awful.tag.viewonly(tag)
						end
				  end),
		-- Toggle tag.
		awful.key({ modkey, "Control" }, "#" .. i + 9,
				  function ()
					  local screen = mouse.screen
					  local tag = awful.tag.gettags(screen)[i]
					  if tag then
						 awful.tag.viewtoggle(tag)
					  end
				  end),
		-- Move client to tag.
		awful.key({ modkey, "Shift" }, "#" .. i + 9,
				  function ()
					  if client.focus then
						  local tag = awful.tag.gettags(client.focus.screen)[i]
						  if tag then
							  awful.client.movetotag(tag)
						  end
					 end
				  end),
		-- Toggle tag.
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
				  function ()
					  if client.focus then
						  local tag = awful.tag.gettags(client.focus.screen)[i]
						  if tag then
							  awful.client.toggletag(tag)
						  end
					  end
				  end))
end

clientbuttons = awful.util.table.join(
	awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
	awful.button({ modkey }, 1, awful.mouse.client.move),
	awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	-- All clients will match this rule.
	{ rule = { },
	  properties = { border_width = beautiful.border_width,
					 border_color = beautiful.border_normal,
					 focus = awful.client.focus.filter,
					 raise = true,
					 keys = clientkeys,
					 buttons = clientbuttons } },
	{ rule = { class = "MPlayer" },
	  properties = { floating = true } },
	{ rule = { class = "pinentry" },
	  properties = { floating = true } },
	{ rule = { class = "gimp" },
	  properties = { floating = true } },
	-- Set Firefox to always map on tags number 2 of screen 1.
	-- { rule = { class = "Firefox" },
	--   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
	-- Enable sloppy focus
	c:connect_signal("mouse::enter", function(c)
		if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
			and awful.client.focus.filter(c) then
			client.focus = c
		end
	end)

	if not startup then
		-- Set the windows at the slave,
		-- i.e. put it at the end of others instead of setting it master.
		-- awful.client.setslave(c)

		-- Put windows in a smart way, only if they does not set an initial position.
		if not c.size_hints.user_position and not c.size_hints.program_position then
			awful.placement.no_overlap(c)
			awful.placement.no_offscreen(c)
		end
	end

	local titlebars_enabled = false
	if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
		-- buttons for the titlebar
		local buttons = awful.util.table.join(
				awful.button({ }, 1, function()
					client.focus = c
					c:raise()
					awful.mouse.client.move(c)
				end),
				awful.button({ }, 3, function()
					client.focus = c
					c:raise()
					awful.mouse.client.resize(c)
				end)
				)

		-- Widgets that are aligned to the left
		local left_layout = wibox.layout.fixed.horizontal()
		left_layout:add(awful.titlebar.widget.iconwidget(c))
		left_layout:buttons(buttons)

		-- Widgets that are aligned to the right
		local right_layout = wibox.layout.fixed.horizontal()
		right_layout:add(awful.titlebar.widget.floatingbutton(c))
		right_layout:add(awful.titlebar.widget.maximizedbutton(c))
		right_layout:add(awful.titlebar.widget.stickybutton(c))
		right_layout:add(awful.titlebar.widget.ontopbutton(c))
		right_layout:add(awful.titlebar.widget.closebutton(c))

		-- The title goes in the middle
		local middle_layout = wibox.layout.flex.horizontal()
		local title = awful.titlebar.widget.titlewidget(c)
		title:set_align("center")
		middle_layout:add(title)
		middle_layout:buttons(buttons)

		-- Now bring it all together
		local layout = wibox.layout.align.horizontal()
		layout:set_left(left_layout)
		layout:set_right(right_layout)
		layout:set_middle(middle_layout)

		awful.titlebar(c):set_widget(layout)
	end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

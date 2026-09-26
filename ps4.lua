--[[
	PS4 / console platform layer.

	Handles everything that differs when Mari0 runs on a PS4 (or on PC with --ps4):
	 - DualShock 4 controls through the SDL GameController API (love.gamepad*)
	 - right analog stick aims the portal gun, L2 = blue portal, R2 = orange portal
	 - menu navigation with the D-pad / left stick / Cross / Circle / Options
	 - fixed TV resolution: the game renders into a canvas that is letterboxed onto the screen

	Pad bindings are stored in the regular controls table as {"pad", <pad number>, <action>}
	so they survive saveconfig/loadconfig like any other binding.
]]

ps4 = {}

-- DualShock 4 layout (SDL gamepad names: a = Cross, b = Circle, x = Square, y = Triangle, start = Options, back = Share)
ps4.buttons = {
	jump = "a",
	run = "x",
	use = "b",
	reload = "y",
}
ps4.triggers = {
	portal1 = "triggerleft",  -- L2: blue portal
	portal2 = "triggerright", -- R2: orange portal
}
ps4.buttonnames = {a = "cross", b = "circle", x = "square", y = "triangle", start = "options", back = "share",
	leftshoulder = "l1", rightshoulder = "r1", triggerleft = "l2", triggerright = "r2"}

ps4.movedeadzone = 0.4     -- left stick, digital movement
ps4.aimdeadzone = 0.3      -- right stick, below this the last aim angle is kept
ps4.triggerpress = 0.5     -- trigger pulled past this fires a portal...
ps4.triggerrelease = 0.3   -- ...and must come back below this before it can fire again
ps4.menurepeatdelay = 0.4
ps4.menurepeatrate = 0.08

ps4.console = false

function ps4.load()
	ps4.console = love.system.getOS() == "PS4"
	for i, v in ipairs(arg or {}) do
		if v == "--ps4" then
			ps4.console = true
		end
	end

	ps4.triggerheld = {}  -- [joystickid][axis] = true while a trigger is past its press threshold
	ps4.stickdir = {}     -- [joystickid] = "left"/"right"/"up"/"down"/nil, left stick as a digital direction
	ps4.menuheld = nil    -- {key, timer} for menu key repeat
end

-- pad n is the nth connected joystick that SDL recognises as a gamepad
function ps4.getpad(n)
	local count = 0
	for i, v in ipairs(love.joystick.getJoysticks()) do
		if v:isGamepad() then
			count = count + 1
			if count == n then
				return v
			end
		end
	end
end

function ps4.padnumber(joystick)
	local count = 0
	for i, v in ipairs(love.joystick.getJoysticks()) do
		if v:isGamepad() then
			count = count + 1
			if v == joystick then
				return count
			end
		end
	end
end

function ps4.setpadcontrols(i, pad)
	controls[i] = {}
	for _, action in ipairs({"right", "left", "down", "up", "run", "jump", "aimx", "aimy", "portal1", "portal2", "reload", "use"}) do
		controls[i][action] = {"pad", pad, action}
	end
end

-- after the config is loaded: on console every player is a controller and nobody owns the mouse
function ps4.applyconsoleconfig()
	if not ps4.console then
		return
	end
	mouseowner = 0
	for i = 1, 4 do
		ps4.setpadcontrols(i, i)
	end
	love.mouse.setVisible(false)
end

-- which players are bound to pad n
function ps4.playersforpad(n)
	local t = {}
	for i = 1, players do
		local s = controls[i] and controls[i]["jump"]
		if s and s[1] == "pad" and s[2] == n then
			table.insert(t, i)
		end
	end
	return t
end

function ps4.stickdirection(x, y, deadzone)
	if math.abs(x) < deadzone and math.abs(y) < deadzone then
		return nil
	end
	if math.abs(x) >= math.abs(y) then
		return x < 0 and "left" or "right"
	end
	return y < 0 and "up" or "down"
end

-- held state for checkkey()
function ps4.padheld(n, action)
	local pad = ps4.getpad(n)
	if not pad then
		return false
	end

	if action == "left" then
		return pad:isGamepadDown("dpleft") or pad:getGamepadAxis("leftx") < -ps4.movedeadzone
	elseif action == "right" then
		return pad:isGamepadDown("dpright") or pad:getGamepadAxis("leftx") > ps4.movedeadzone
	elseif action == "up" then
		return pad:isGamepadDown("dpup") or pad:getGamepadAxis("lefty") < -ps4.movedeadzone
	elseif action == "down" then
		return pad:isGamepadDown("dpdown") or pad:getGamepadAxis("lefty") > ps4.movedeadzone
	elseif ps4.buttons[action] then
		return pad:isGamepadDown(ps4.buttons[action])
	elseif ps4.triggers[action] then
		return pad:getGamepadAxis(ps4.triggers[action]) > ps4.triggerpress
	end
	return false
end

-- right stick aim; returns x, y in the convention mario:updateangle expects, or nil when centered
function ps4.aim(n)
	local pad = ps4.getpad(n)
	if not pad then
		return
	end
	local x, y = pad:getGamepadAxis("rightx"), pad:getGamepadAxis("righty")
	if x*x + y*y < ps4.aimdeadzone*ps4.aimdeadzone then
		return
	end
	return -x, -y
end

function ps4.describe(s)
	local action = s[3]
	local name
	if action == "left" or action == "right" or action == "up" or action == "down" then
		name = "l stick"
	elseif action == "aimx" or action == "aimy" then
		name = "r stick"
	elseif ps4.buttons[action] then
		name = ps4.buttonnames[ps4.buttons[action]]
	elseif ps4.triggers[action] then
		name = ps4.buttonnames[ps4.triggers[action]]
	end
	return "pad" .. s[2] .. " " .. (name or "")
end

--------------
-- GAMEPLAY --
--------------

local function playercanact(i)
	local p = objects["player"][i]
	return not noupdate and p and p.controlsenabled and not p.vine
end

local function gameinputactive()
	return gamestate == "game" and not pausemenuopen and not editormode
end

-- menus, title screen, and the in-game pause menu (the level editor is mouse-only)
local function menuinputactive()
	return gamestate ~= "game" or pausemenuopen
end

local function gamebuttonpressed(n, button)
	if endpressbutton then
		endgame()
		return true
	end

	for _, i in ipairs(ps4.playersforpad(n)) do
		if playercanact(i) then
			local p = objects["player"][i]
			if button == ps4.buttons.jump then
				p:jump()
			elseif button == ps4.buttons.run then
				p:fire()
			elseif button == ps4.buttons.reload then
				p:removeportals()
			elseif button == ps4.buttons.use then
				p:use()
			elseif button == "dpleft" then
				p:leftkey()
			elseif button == "dpright" then
				p:rightkey()
			end
		end
	end
	return false
end

local function gamestickmoved(n, dir)
	for _, i in ipairs(ps4.playersforpad(n)) do
		local p = objects["player"][i]
		if not noupdate and p and p.controlsenabled then
			if dir == "left" then
				p:leftkey()
			elseif dir == "right" then
				p:rightkey()
			end
		end
	end
end

local function gametriggerpulled(n, axis)
	if endpressbutton then
		endgame()
		return
	end
	for portal, trigger in pairs(ps4.triggers) do
		if trigger == axis then
			for _, i in ipairs(ps4.playersforpad(n)) do
				if playercanact(i) then
					playerportalbutton(i, portal == "portal1" and 1 or 2)
				end
			end
		end
	end
end

-----------
-- MENUS --
-----------

local menukeys = {dpup = "up", dpdown = "down", dpleft = "left", dpright = "right", a = "return", b = "escape", start = "return"}

local function menukey(key)
	-- Circle on the title screen would quit the game; on console that's what the PS button is for
	if ps4.console and key == "escape" and gamestate == "menu" and not selectworldopen then
		return
	end
	love.keypressed(key)
end

local function menupress(key)
	menukey(key)
	if key == "up" or key == "down" or key == "left" or key == "right" then
		ps4.menuheld = {key = key, timer = ps4.menurepeatdelay}
	end
end

local function menurelease(key)
	if ps4.menuheld and ps4.menuheld.key == key then
		ps4.menuheld = nil
	end
end

---------------
-- CALLBACKS --
---------------

function ps4.gamepadpressed(joystick, button)
	if keyprompt then
		return -- the raw love.joystickpressed callback handles rebinding
	end
	local n = ps4.padnumber(joystick)
	if not n then
		return
	end

	if gameinputactive() then
		if button == "start" or button == "back" then
			love.keypressed("escape") -- pause
		else
			gamebuttonpressed(n, button)
		end
	elseif menuinputactive() and menukeys[button] then
		if button == "start" and gamestate == "game" then
			menukey("escape") -- Options closes the pause menu
		else
			menupress(menukeys[button])
		end
	end
end

function ps4.gamepadreleased(joystick, button)
	local n = ps4.padnumber(joystick)
	if not n then
		return
	end

	if gamestate == "game" and button == ps4.buttons.jump then
		for _, i in ipairs(ps4.playersforpad(n)) do
			if objects["player"][i] then
				objects["player"][i]:stopjump()
			end
		end
	end
	if menukeys[button] then
		menurelease(menukeys[button])
	end
end

function ps4.gamepadaxis(joystick, axis, value)
	if keyprompt then
		return
	end
	local n = ps4.padnumber(joystick)
	if not n then
		return
	end
	local id = joystick:getID()

	if axis == "triggerleft" or axis == "triggerright" then
		ps4.triggerheld[id] = ps4.triggerheld[id] or {}
		local held = ps4.triggerheld[id]
		if not held[axis] and value > ps4.triggerpress then
			held[axis] = true
			if gameinputactive() then
				gametriggerpulled(n, axis)
			end
		elseif held[axis] and value < ps4.triggerrelease then
			held[axis] = false
		end
	elseif axis == "leftx" or axis == "lefty" then
		local dir = ps4.stickdirection(joystick:getGamepadAxis("leftx"), joystick:getGamepadAxis("lefty"), ps4.movedeadzone)
		local olddir = ps4.stickdir[id]
		if dir ~= olddir then
			ps4.stickdir[id] = dir
			if olddir then
				menurelease(olddir)
			end
			if dir then
				if gameinputactive() then
					gamestickmoved(n, dir)
				elseif menuinputactive() then
					menupress(dir)
				end
			end
		end
	end
end

function ps4.update(dt)
	if ps4.menuheld then
		if not menuinputactive() then
			ps4.menuheld = nil
			return
		end
		ps4.menuheld.timer = ps4.menuheld.timer - dt
		if ps4.menuheld.timer <= 0 then
			ps4.menuheld.timer = ps4.menurepeatrate
			menukey(ps4.menuheld.key)
		end
	end
end

-------------
-- DISPLAY --
-------------

-- On console the screen resolution is fixed, so pick the biggest integer scale that fits
-- and render into a canvas that gets centered on screen (scissor rects are in canvas space that way).
function ps4.changescale()
	if love.system.getOS() == "PS4" then
		love.window.setMode(0, 0, {fullscreen=true, vsync=true})
	else
		love.window.setMode(1280, 720, {vsync=vsync}) -- --ps4 on PC: pretend the window is a 720p TV
	end

	local screenw, screenh = love.graphics.getDimensions()
	scale = math.max(1, math.min(math.floor(screenh/224), math.floor(screenw/(width*16))))
	uispace = math.floor(width*16*scale/4)
	gamewidth = width*16*scale
	gameheight = 224*scale

	ps4.frame = love.graphics.newCanvas(gamewidth, gameheight)
	ps4.frame:setFilter("nearest", "nearest")
end

function ps4.predraw()
	if not ps4.frame then
		return
	end
	love.graphics.setCanvas(ps4.frame)
	love.graphics.clear(love.graphics.getBackgroundColor())
	if shaders then
		shaders.outputcanvas = ps4.frame
	end
end

function ps4.postdraw()
	if not ps4.frame then
		return
	end
	love.graphics.setCanvas()
	love.graphics.clear(0, 0, 0)
	love.graphics.setColor(1, 1, 1)
	local blendmode, alphamode = love.graphics.getBlendMode()
	love.graphics.setBlendMode("alpha", "premultiplied")
	local screenw, screenh = love.graphics.getDimensions()
	love.graphics.draw(ps4.frame, math.floor((screenw-gamewidth)/2), math.floor((screenh-gameheight)/2))
	love.graphics.setBlendMode(blendmode, alphamode)
end

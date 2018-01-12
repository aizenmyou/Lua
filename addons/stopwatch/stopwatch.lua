_addon.name = 'stopwatch'
_addon.author = 'freeZerg'
_addon.version = '1.1'
_addon.commands = {'sw', 'stopwatch'}

config = require('config')
local texts = require('texts')
local render_regid = nil

local defaults = {}
defaults.saved_time = 0
local fast_time = 0
defaults.extra_time = 0
defaults.is_shown = false
defaults.is_paused = false
defaults.display = {}
defaults.display.pos = {}
defaults.display.pos.x = windower.get_windower_settings().x_res / 2
defaults.display.pos.y = 100
defaults.display.text = {}
defaults.display.text.font = 'Arial'
defaults.display.text.size = 12
local settings = config.load(defaults)

local timer_display = texts.new(settings.display, settings)
local MAX_TIME = 99*3600 + 99 * 59 + 59
if settings.is_paused == false then
	settings.extra_time = settings.extra_time + (os.time() - settings.saved_time)
	settings.saved_time = os.time()
	fast_time = os.clock()
end

render_stopwatch = function()
	local total_time = settings.extra_time
	if not settings.is_paused then
		total_time = total_time + (os.clock() - fast_time)
	end
	total_time = math.floor(total_time)
	timer_display:text(string.format('%0.2d:%0.2d:%0.2d', (total_time / 3600), (total_time / 60) % 60, (total_time) % 60))
end

function set_show(mode)
	if mode ~= nil then
		settings.is_shown = mode
	end
	if settings.is_shown == false then
		settings.is_paused = true
		timer_display:hide()
		if render_regid ~= nil then
			windower.unregister_event(render_regid)
			render_regid = nil
		end
	else
		settings.is_paused = false
		timer_display:show()
		if render_regid == nil then
			render_regid = windower.register_event('prerender', render_stopwatch)
		end
	end
end

windower.register_event('logout', function()
	set_show(false)
end)

windower.register_event('login', function()
	set_show()
end)

windower.register_event('load', function()
	-- just because the plugin loaded doesn't mean we're logged in -- could be at char select screen
	-- also could have just reloaded from being logged in
	if windower.ffxi.get_info().logged_in == false then
		set_show(false)
		return
	end
	set_show()
end)

local HELP_MESSAGE = [[
StopWatch - Commands listing:
//stopwatch [command]       -- (aka. //sw)
  //sw start     -- start and show the stopwatch
  //sw pause     -- pause the timer, time still displayed
  //sw reset     -- reset the time to 0
  //sw stop      -- stop and hide the stopwatch
  //sw resetpos  -- display the stopwatch near the top-center of your screen]]
windower.register_event('addon command', function(command)
	command = command:lower()

	if command == 'start' then
		if settings.is_shown == false then
			settings.saved_time = os.time()
			fast_time = os.clock()
			settings.extra_time = 0
			set_show(true)
			settings:save()
		end
	elseif command == 'pause' then
		if settings.is_shown == true then
			if settings.is_paused then -- unpause
				settings.saved_time = os.time()
				fast_time = os.clock()
				settings.is_paused = false
				windower.add_to_chat(100, 'not paused no mo')
			else
				settings.extra_time = settings.extra_time + (os.clock() - fast_time)
				settings.is_paused = true
				windower.add_to_chat(100, 'i pause nao')
			end
			settings:save()
		end
	elseif command == 'stop' then
		if settings.is_shown == true then
			set_show(false)
			settings:save()
		end
	elseif command == 'reset' then
		settings.saved_time = os.time()
		fast_time = os.clock()
		settings.extra_time = 0
		settings:save()
	elseif command == 'resetpos' then
		settings.display.pos.x = windower.get_windower_settings().x_res / 2
		settings.display.pos.y = 100
		settings:save()
		timer_display:pos(settings.display.pos.x, settings.display.pos.y)
	else
		windower.add_to_chat(100, HELP_MESSAGE)
	end
end)

--[[
Copyright © 2015, Patrick Finnigan
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of stopwatch nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Patrick Finnigan BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

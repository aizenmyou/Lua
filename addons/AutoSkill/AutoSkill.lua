-- TODO: only show shield skill if SHIELD IS EQUIPPED LIKE AN OFFHAND YOU DIPSHIT
-- TODO: wait for body to fade before marking as dead --- currently just tacking on MOB_TRACKER_FADE_TIME

--TODO: page tracking needs completion and testing
--TODO: fancy ordered insertion based on different respawn times
--TODO: change buffs, cure spells, and ability lists to use res.spells etc
--TODO: change zoneid and nm/ph information to use strings

--Copyright (c) 2018, freeZerg
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of <addon name> nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

_addon.name = 'AutoSkill'
_addon.version = '0.1'
_addon.author = 'freeZerg'
_addon.commands = {'autoskill','ask'}

require('HelperMikeLuaLib')

res = require('resources')
config = require('config')
local texts = require('texts')
require('HelperSkillCapData')
require('HelperSkillCapFunctions')

local MAX_LENGTH = 15
local MAX_PAGES_TO_TRACK = 6
z_mobdata = {}
z_mobdata.nms = {}
z_mobdata.phs = {}
for i,zoneinfo in pairs(res.zones) do
	z_mobdata.nms[zoneinfo.search] = {}
	z_mobdata.phs[zoneinfo.search] = {}
end
require('HelperMobData')
require('HelperTracker')

local z_page_tracker = {}
function clearPageTracker(settings_data)
	z_page_tracker = {}
	settings_data.page_tracker = {}
	for i=1,MAX_PAGES_TO_TRACK,1 do
		local key = 'page'..i
		settings_data.page_tracker[key] = {}
        settings_data.page_tracker[key].name      = 'Unknown'
		settings_data.page_tracker[key].is_family = false
        settings_data.page_tracker[key].needed    = 0
        settings_data.page_tracker[key].progress  = 0
	end
end

local z_mob_tracker = {}
local z_mob_tracker_order = {}
local z_mob_tracker_kills = 0
local MOB_TRACKER_FADE_TIME = 18
local z_phnm_spawn = {}
local z_skill_tracker = {}
local z_skill_tracker_weapon_order = {}
local z_skill_tracker_magic_order = {}
local z_skill_tracker_defense_order = {}
local z_player = {}
z_player.level_sync = 0
z_player.skills = {}
z_player.obtains_msg = 'PLAYERNAME obtains a'
z_player.obtains_msg_len = z_player.obtains_msg:len()
z_player.finds_msg = 'You find a'
z_player.finds_msg_len = z_player.finds_msg:len()
z_player.throws_msg = 'You throw away a'
z_player.throws_msg_len = z_player.throws_msg:len()
local z_pause_autodrop = false
local z_autodrop_filter_time = 0
local z_autodrop_filter_items = {}

-- Conventional settings layout
local default_settings = {}
default_settings.nm_scan_repeat = 5
default_settings.sound_files = {}
default_settings.sound_files.alert = 'call20.wav'
default_settings.sound_files.book_complete = {}
default_settings.sound_files.book_complete['e']  = 'book_finish_e.wav'
default_settings.sound_files.book_complete['f']  = 'book_finish_f.wav'
default_settings.sound_files.book_complete['fs'] = 'book_finish_fsharp.wav'
default_settings.sound_files.book_complete['g']  = 'book_finish_g.wav'
clearPageTracker(default_settings)
-- TODO: implement persistent NM last kill seen measurements
-- default_settings.mob_tracker = {}
default_settings.play_sounds = 'on'
default_settings.ammunition_name = 'Horn Arrow'
default_settings.ammunition_id = 18156
default_settings.tracking_skills = 'on'
default_settings.display = {}
default_settings.display.pos = {}
default_settings.display.pos.x = 100
default_settings.display.pos.y = 100
default_settings.display.bg = {}
default_settings.display.bg.red   = 0
default_settings.display.bg.green = 0
default_settings.display.bg.blue  = 0
default_settings.display.bg.alpha = 102
default_settings.display.text = {}
default_settings.display.text.font = 'Consolas'
default_settings.display.text.size = 12
default_settings.display.text.red   = 255
default_settings.display.text.green = 255
default_settings.display.text.blue  = 255
default_settings.display.text.alpha = 255
default_settings.skilldisplay = {}
default_settings.skilldisplay.pos = {}
default_settings.skilldisplay.pos.x = 100
default_settings.skilldisplay.pos.y = 200
default_settings.skilldisplay.bg = {}
default_settings.skilldisplay.bg.red   = 0
default_settings.skilldisplay.bg.green = 0
default_settings.skilldisplay.bg.blue  = 0
default_settings.skilldisplay.bg.alpha = 192
default_settings.skilldisplay.flags = {}
default_settings.skilldisplay.flags.italic = true
default_settings.skilldisplay.text = {}
default_settings.skilldisplay.text.font = 'Consolas'
default_settings.skilldisplay.text.size = 10
default_settings.skilldisplay.text.red   = 210
default_settings.skilldisplay.text.green = 210
default_settings.skilldisplay.text.blue  = 214
default_settings.skilldisplay.text.alpha = 255
default_settings.skilldisplay.text.stroke = {}
-- capped font: red 53, green 140, blue 196
-- stroke: red 17, green 28, blue 48
default_settings.skilldisplay.text.stroke.width = 2
default_settings.skilldisplay.text.stroke.red   = 17
default_settings.skilldisplay.text.stroke.green = 28
default_settings.skilldisplay.text.stroke.blue  = 48
default_settings.skilldisplay.text.stroke.alpha = 255
default_settings.autodrop = {}
default_settings.nms = {}
default_settings.nms['Leaping_Lizzy'] = {}
default_settings.nms['Leaping_Lizzy'].time_last_kill = 0
default_settings.nms['Leaping_Lizzy'].ph_kills = 0

settings = config.load(default_settings)
local z_textbox_misc = texts.new(settings.display, settings)
local z_textbox_skills = texts.new(settings.skilldisplay, settings)
local z_default_color = ''

local WINDOW_PADDING = 50
function is_within_bounds(display)
	local xres = windower.get_windower_settings().x_res
	local yres = windower.get_windower_settings().y_res
	local need_relocate = false
	if display.pos.x < 0 or display.pos.x + WINDOW_PADDING > xres then
		display.pos.x = xres/2
		need_relocate = true
	end
	if display.pos.y < 0 or display.pos.y + WINDOW_PADDING > yres then
		display.pos.y = yres/2
		need_relocate = true
	end
	return need_relocate
end

config.register(settings, function ()
	if not is_within_bounds(settings.display) then
		z_textbox_misc:pos(settings.display.pos.x, settings.display.pos.y)
	end
	if not is_within_bounds(settings.skilldisplay) then
		z_textbox_skills:pos(settings.skilldisplay.pos.x, settings.skilldisplay.pos.y)
	end
	if settings.nm_scan_repeat ~= 0 and settings.nm_scan_repeat < 5 then settings.nm_scan_repeat = 5 end
	if settings.play_sounds ~= 'on' then settings.play_sounds = 'off' end
	if settings.tracking_skills ~= 'on' then 
		settings.tracking_skills = 'off'
		z_textbox_skills:clear()
		z_textbox_skills:hide()
	else
		z_textbox_skills:show()
	end
	z_default_color = '\\cs('..settings.display.text.red..','
	z_default_color = z_default_color..settings.display.text.green..','
	z_default_color = z_default_color..settings.display.text.blue..')'

	if settings.page_tracker ~= nil and table.size(settings.page_tracker) > 0 then
		z_page_tracker = {}
		for index,pagedata in pairs(settings.page_tracker) do
			local i = tonumber(string.sub(index,5)) -- 'page3'
			if pagedata.name == nil then 
				windower.add_to_chat(17, ' -- Were looping on page_tracker yet name was nil, dump: '..table.tostring(pagedata))
			end
			if pagedata.needed == 0 then break end
			z_page_tracker[i] = {}
			z_page_tracker[i].name      = string.padright(pagedata.name, MAX_LENGTH)
			z_page_tracker[i].progress  = pagedata.progress
			z_page_tracker[i].needed    = pagedata.needed
			z_page_tracker[i].is_family = pagedata.is_family
		end
		textbox_reinitialize_function(z_textbox_misc, settings)
	end
end)

textbox_reinitialize_function = function(textbox, settings)
	local contents = L{}
	local elements = 0
	contents:append(string.padcenter('== AutoSkill ==', MAX_LENGTH+5))
	if table.getn(z_page_tracker) > 0 then
		elements = elements + 1
		contents:append('Page status:')
		for i, pagedata in ipairs(z_page_tracker) do
			local padded_name = string.padright(pagedata.name, MAX_LENGTH)
			contents:append('${pagec'..i..'}'..pagedata.name..' ${pagep'..i..'}/'..pagedata.needed..'\\cr')
		end
	end
	if table.size(z_mob_tracker) > 0 then
		if elements > 0 then contents:append('') end
		elements = elements + 1
		contents:append('Total : '..z_mob_tracker_kills)
		local phnmcount = 0
		for nmid, phtrackdata in pairs(z_phnm_spawn) do
			contents:append('PH for '..phtrackdata.name..' kills='..phtrackdata.ph_kills)
			contents:append('  geo.distrib: '..string.format('%02.02f', (1-phtrackdata.probability)*100)..'%')
			contents:append('  dead/total: ${phdead'..nmid..'}/'..phtrackdata.total_phs)
			if z_mob_tracker[nmid] ~= nil then
				contents:append(string.padright(z_mob_tracker[nmid].name, MAX_LENGTH)..' ${mobt'..nmid..'}')
			end
			for i, mobid in ipairs(z_mob_tracker_order) do
				if z_mob_tracker[mobid].phnm == nmid then
					contents:append(string.padright(z_mob_tracker[mobid].name, MAX_LENGTH)..' ${mobt'..mobid..'}')
					phnmcount = phnmcount + 1
				end
			end
		end

		if phnmcount < table.getn(z_mob_tracker_order) then 
			if table.size(z_phnm_spawn) > 0 then
				contents:append('')
				contents:append('--- Regular Mobs')
			end
			for i, mobid in ipairs(z_mob_tracker_order) do
				if z_mob_tracker[mobid].phnm == 0 and z_mob_tracker[mobid].is_nm == false then
					contents:append(string.padright(z_mob_tracker[mobid].name, MAX_LENGTH)..' ${mobt'..mobid..'}')
				end
			end
		end
	end
	textbox:clear()
	if elements > 0 then
		textbox:append(contents:concat('\n'))
		textbox:show()
	else
		textbox:hide()
	end
end

local SKILL_PADDING = 12
local SKILL_WIDTH_TOTAL = (SKILL_PADDING + 8)*2 + 2
local function textbox_skills_add_data(data, skillid, templine)
	local add_to_data = false
	if templine:len() > 0 then
		add_to_data = true
		templine = templine..'  '
	end
	if z_skill_tracker[skillid].is_capped then
		templine = templine..z_skill_tracker[skillid].name.. ' \\cs(53,140,196)'..z_skill_tracker[skillid].cap..'/'..z_skill_tracker[skillid].cap..'\\cr'
	else
		templine = templine..z_skill_tracker[skillid].name.. ' ${cur'..skillid..'}/'..z_skill_tracker[skillid].cap
	end

	if add_to_data then
		data:append(templine)
		return ''
	end
	return templine
end

textbox_skills_reinitialize_function = function(textbox, settings)
	--windower.add_to_chat(17, 'Skill text box='..settings.tracking_skills..' and size='..table.size(z_skill_tracker))
	if settings.tracking_skills == 'off' then return end

	windower.add_to_chat(100, 'RERENDERING SKILL SCREEN: '..debug.traceback())
	local contents = L{}
	--contents:append(string.padcenter('== Skill Caps ==', SKILL_WIDTH_TOTAL))
	if z_player.mjlvl == nil then
		windower.add_to_chat(17, ' -- about to crash! '..debug.traceback())
	end

	local header = '=== Skill Caps lv'..z_player.effective_level..' '..z_player.mjtla..' ==='
	-- '== Skill Caps =='
	contents:append(string.padcenter(header, SKILL_WIDTH_TOTAL))
	--contents:append(header)

	local templine = ''
	for i, skillgroup in ipairs( { z_skill_tracker_weapon_order, z_skill_tracker_magic_order, z_skill_tracker_defense_order } ) do
		for j, skillid in ipairs(skillgroup) do
			templine = textbox_skills_add_data(contents, skillid, templine)
		end
	end
	-- added two skills at a time. if there's an odd number, add the last one
	if templine:len() > 0 then contents:append(templine) end

	textbox:clear()
	textbox:append(contents:concat('\n'))
	textbox_render_skill_update()
end

function textbox_render_page_update(data)
	local needs_update = false
	for i, pagedata in ipairs(z_page_tracker) do
		if pagedata.progress == pagedata.needed then
			needs_update = true
		end
		data['pagep'..i] = pagedata.progress
	end
	return needs_update
end

local ANGLE_DIRECTIONS = { 
	'E', 'ENE', 'NE', 'NNE', 
	'N', 'NNW', 'NW', 'WNW', 
	'W', 'WSW', 'SW', 'SSW', 
	'S', 'SSE', 'SE', 'ESE',  }

function rads_to_degs(rads)
	return 360.0 * rads / (2 * math.pi)
end

local MESSAGE_SPAM_PREVENTER = 0
local TWOPI = 2.0 * math.pi
local NEGSIXTEENTHPI = -math.pi / 16.0
function getRelativeDirection(px, py, tx, ty)
	-- tan(angle) = y / x    -->  arctan(tan(angle)) = arctan(y/x)   -->  angle = arctan(y/x)
	-- output is unexpected if not normalized, so compute length and divide
	local dx = tx - px
	local dy = ty - py
	local len = math.sqrt(dx*dx + dy*dy)
	local angle2 = math.atan2(dy/len, dx/len)
	-- (0,+2pi) -> [1,16] - and shift it a half an angle category... (prevent overflow with carfeful comparison)
	if angle2 < NEGSIXTEENTHPI then angle2 = angle2 + 2*math.pi end
	angle2 = 8.0*angle2/math.pi + 1.5
	local direction = math.floor(angle2)

	local curtime = os.time()
	if direction < 1 or direction > 16 then
		if curtime > MESSAGE_SPAM_PREVENTER then
			windower.add_to_chat(100, string.format('direction=%d  -- angle2r=%1.3f -- angle2d=%3.1f', direction, angle2, rads_to_degs(angle2) ) )
			MESSAGE_SPAM_PREVENTER = curtime
		end
		return string.format('%1.3f %d %3.1f', angle2, direction, rads_to_degs(angle2))
	end
	return ANGLE_DIRECTIONS[direction], len
end

function textbox_render_tracker_update(data)
	if table.size(z_mob_tracker) == 0 then return false end

	local player_data = windower.ffxi.get_mob_by_target('me')
	local needs_update = false
	local curtime = os.time()
	local removemobs = {}
	data.mobkills = z_mob_tracker_kills
	for nmid, phtrackdata in pairs(z_phnm_spawn) do
		data['phdead'..nmid] = phtrackdata.phs_currently_dead
	end
	for i, mobid in ipairs(z_mob_tracker_order) do
		local mob_data = z_mob_tracker[mobid]
		local colorprefix = ''
		local colorsuffix = ''
		local remaining_time = mob_data.respawn - curtime
		if remaining_time < 10 then
			colorprefix = '\\cs(255,64,64)'
			colorsuffix = '\\cr'
		end
		if remaining_time > 0 then
			data['mobt'..mobid] = colorprefix..remaining_time:string():lpad(' ', 3)..'s'..colorsuffix
		elseif z_mob_tracker[mobid].phnm ~= 0 and z_phnm_spawn[z_mob_tracker[mobid].phnm].time_last_kill < curtime then
			local mob_data = windower.ffxi.get_mob_by_id(mobid)
			if mob_data ~= nil and mob_data.valid_target then
				z_mob_tracker[mobid].x = mob_data.x
				z_mob_tracker[mobid].y = mob_data.y
				if z_mob_tracker[mobid].name == 'Unknown' then
					z_mob_tracker[mobid].name = mob_data.name
					needs_update = true
				end
				local reldir, distance = getRelativeDirection(player_data.x, player_data.y, mob_data.x, mob_data.y)
				local distancestr = string.padleft(string.format('%2.1fy', distance), 5)
				data['mobt'..mobid] = '\\cs(128,255,128)'..distancestr..' '..reldir..'\\cr'
			elseif z_mob_tracker[mobid].x ~= nil then
				local reldir, distance = getRelativeDirection(player_data.x, player_data.y, z_mob_tracker[mobid].x, z_mob_tracker[mobid].y)
				local distancestr = string.padleft(string.format('%2.1fy', distance), 5)
				data['mobt'..mobid] = '\\cs(128,255,128)'..distancestr..' '..reldir..'\\cr'
			else
				data['mobt'..mobid] = 'unknown'
			end
			if z_mob_tracker[mobid].is_dead == true then
				z_mob_tracker[mobid].is_dead = false
				z_phnm_spawn[z_mob_tracker[mobid].phnm].phs_currently_dead = z_phnm_spawn[z_mob_tracker[mobid].phnm].phs_currently_dead - 1
			end
		elseif z_mob_tracker[mobid].is_nm then
			local mob_data = windower.ffxi.get_mob_by_id(mobid)
			if mob_data ~= nil and mob_data.valid_target then
				z_mob_tracker[mobid].x = mob_data.x
				z_mob_tracker[mobid].y = mob_data.y
				local reldir, distance = getRelativeDirection(player_data.x, player_data.y, mob_data.x, mob_data.y)
				local distancestr = string.padleft(string.format('%2.1fy', distance), 5)
				data['mobt'..mobid] = '\\cs(128,255,128)'..distancestr..' '..reldir..'\\cr'
			elseif z_mob_tracker[mobid].x ~= nil then
				local reldir, distance = getRelativeDirection(player_data.x, player_data.y, z_mob_tracker[mobid].x, z_mob_tracker[mobid].y)
				local distancestr = string.padleft(string.format('%2.1fy', distance), 5)
				data['mobt'..mobid] = '\\cs(128,255,128)'..distancestr..' '..reldir..'\\cr'
			else
				data['mobt'..mobid] = '\\cs(128,128,128)not found\\cr '
			end
		else
			table.insert(removemobs, mobid)
		end
	end
	for i,mobid in ipairs(removemobs) do
		windower.add_to_chat(100, 'Attempting to remove mobid='..mobid)
		for j, mobjd in ipairs(z_mob_tracker_order) do
			if mobid == mobjd then
				table.remove(z_mob_tracker_order, j)
				needs_update = true
				break
			end
		end
	end
	return needs_update
end

function textbox_render_skill_update()
	if settings.tracking_skills ~= 'on' then return	end

	local data = {}

	for i, skillgroup in ipairs( { z_skill_tracker_weapon_order, z_skill_tracker_magic_order, z_skill_tracker_defense_order } ) do
		for j, skillid in ipairs(skillgroup) do
			data['cur'..skillid] = z_skill_tracker[skillid].current
		end
	end
	z_textbox_skills:update(data)
end


function textbox_render_update()
	local data = {}

	local page_update = textbox_render_page_update(data)
	local tracker_update = textbox_render_tracker_update(data)

	local made_changes_prioir_to_render = false

	if page_update or tracker_update then
		textbox_reinitialize_function(z_textbox_misc, settings)
	end
	z_textbox_misc:update(data)
end

--windower.register_event('prerender', function()
--end)

local z_last_tracker_render_update = 0
function do_render_loop()
	local curtime = os.time()
	--if z_last_tracker_render_update + 2 < curtime then
	z_last_tracker_render_update = curtime
	textbox_render_update()
	coroutine.schedule(do_render_loop, 0.5)
end

windower.register_event('load', function ()
	regid_action = nil
	z_locked_target_id = 0
	z_track_mode = true
	z_super_verbose = false
	z_operational_mode = {}
	z_paused = true
	z_latest_status = 'Unknown'

	-- generate junk skill data
	for skillid,junk in pairs(res.skills) do
		addSkillTrackCategory(skillid)
	end
	-- then populate with player data
	resetAllStats()

	z_textbox_misc:register_event('reload', textbox_reinitialize_function)
	z_textbox_skills:register_event('reload', textbox_skills_reinitialize_function)
	textbox_render_update()
	textbox_render_skill_update()

	local window_settings = windower.get_windower_settings()
	if window_settings ~= nil then
		local x_max = window_settings.x_res
		local y_max = window_settings.y_res
		local buffer_region = 50
		local reset_display = false
		if settings.display.pos.x > x_max - buffer_region or settings.display.pos.x < 0 then reset_display = true end
		if settings.display.pos.y > y_max - buffer_region or settings.display.pos.y < 0 then reset_display = true end
		if reset_display then
			settings.display.pos.x = default_settings.display.pos.x
			settings.display.pos.y = default_settings.display.pos.y
		end
		reset_display = false
		if settings.skilldisplay.pos.x > x_max - buffer_region or settings.skilldisplay.pos.x < 0 then reset_display = true end
		if settings.skilldisplay.pos.y > y_max - buffer_region or settings.skilldisplay.pos.y < 0 then reset_display = true end
		if reset_display then
			settings.skilldisplay.pos.x = default_settings.skilldisplay.pos.x
			settings.skilldisplay.pos.y = default_settings.skilldisplay.pos.y
		end
	end

	EQUIPMENT_AMMO_SLOT = nil
	for slotindex, slotdata in pairs(res.slots) do
		if slotdata.en =='Ammo' then EQUIPMENT_AMMO_SLOT = slotdata.id end
	end
	if settings.nm_scan_repeat > 0 then periodicNMScan() end
	do_render_loop()
end)


function resetAllStats()
	z_most_damage_taken = 0
	z_health_danger = 9999
	z_last_ability_tick = {}
	z_last_ability_tick['ranged'] = 0

	recalculateVitals()
	--scanMobsInArea()
	recalculateAbilities()
end

function recalculateRangedDelay(gear)
	z_ranged_delay = 0

	if gear == nil then gear = windower.ffxi.get_items()['equipment'] end
	-- windower.add_to_chat(100, 'Player Equipment dump is as follows:')
	-- windower.add_to_chat(100, 'table type='..type(gear)..'   contents: '..table.tostring(gear))
	z_ranged_skilltype = 0
	z_ranged_weapon = nil
	z_ammo_bag = nil
	z_ammo_count = nil
	if gear.range > 0 then
		z_ranged_weapon = windower.ffxi.get_items(gear.range_bag, gear.range)
		local candidate_skill = res.items[z_ranged_weapon.id].skill
		if candidate_skill ~= nil then z_ranged_skilltype = candidate_skill end
	end
	if gear.ammo > 0 then
		z_ammo_info = windower.ffxi.get_items(gear.ammo_bag, gear.ammo)
		z_ammo_bag = gear.ammo_bag
		z_ammo_type = z_ammo_info.id
		z_ammo_count = z_ammo_info.count
		local candidate_skill = res.items[z_ammo_type].skill
		if z_ranged_skilltype == 0 and candidate_skill ~= nil and res.skills[candidate_skill] == 'Throwing' then
			z_ranged_weapon = z_ammo_info
			z_ranged_skilltype = candidate_skill
		end
		windower.add_to_chat(100, 'Player has ' ..z_ammo_count..' ammo of type '..z_ammo_type..' in bag='..z_ammo_bag..' of rskilltype='..z_ranged_skilltype)
	else
		-- ammo slot is empty, default the ammo type to what's saved/preferred instead of equipped
		z_ammo_type = settings.ammunition_id
	end
end

-- TODO: can you have weapons that you have no skill in? will tracker crashz0r?
function addSkillTrackCategory(skillid)
	if skillid == nil or skillid == 0 then return end
	local key = SKILL_KEYS[skillid]
	local skillname = SKILL_KEYS[key]
	if z_skill_tracker[skillid] == nil then
		z_skill_tracker[skillid] = {}
		z_skill_tracker[skillid].name = skillname:rpad(' ', SKILL_PADDING)
		z_skill_tracker[skillid].current = '-5'
		z_skill_tracker[skillid].cap = '-6'
		z_skill_tracker[skillid].is_capped = false
		z_skill_tracker[skillid].tracking = false
		return
	end
	z_skill_tracker[skillid].current = (z_player.skills[key]):string():lpad(' ', 3)
	z_skill_tracker[skillid].cap = getSkillCapFor(z_player.mjtla, z_player.effective_level, skillname):string():lpad(' ', 3)
	z_skill_tracker[skillid].is_capped = (z_skill_tracker[skillid].current == z_skill_tracker[skillid].cap)
	z_skill_tracker[skillid].tracking = true
end

function recalculateWeaponry(just_weapons)
	local gear = windower.ffxi.get_items()['equipment']

	local mainwep_skillid = 0
	local subwep_skillid = 0
	-- check if main weapon exists, pull it's information
	if gear.main > 0 then
		local mainweapon_info = windower.ffxi.get_items(gear.main_bag, gear.main)
		if mainweapon_info ~= nil then
			if mainweapon_info.id == nil then
				windower.add_to_chat(17, 'ON INITIAL LOAD DEBUG ATTEMPT: mainwep info='..table.tostring(mainweapon_info))
			elseif res.items[mainweapon_info.id] == nil then
				windower.add_to_chat(17, 'Res.items gave us a nil table on id='..mainweapon_info.id)
			end
				
			mainwep_skillid = res.items[mainweapon_info.id].skill
		else
			windower.add_to_chat(17, 'Main hand contained index='..gear.main..' but weapon_info could not be found.')
		end
	elseif JOB_WEAPON_RATINGS[z_player.mjtla]['Hand-to-Hand'] ~= nil then -- no main weapon, h2h skill?
		mainwep_skillid = SKILL_IDS['Hand-to-Hand']
	end

	-- if main hand exists, offhand may be a duplicate. this may also be a shield.
	if gear.sub > 0 then 
		local subweapon_info = windower.ffxi.get_items(gear.sub_bag, gear.sub)
		if subweapon_info ~= nil then
			subwep_skillid = res.items[subweapon_info.id].skill
			if subwep_skillid == nil and res.items[subweapon_info.id].shield_size ~= nil then
				subwep_skillid = SKILL_IDS['Shield']
			end
		end
	end

	-- computer ranged weapon's ammunition and skill mode
	recalculateRangedDelay(gear)

	-- now clean it up and compare against what we have
	if mainwep_skillid == subwep_skillid then subwep_skillid = 0 end
	local weapons_after = 0
	local ranged_index = 1
	if mainwep_skillid > 0 then ranged_index = 2 end
	if subwep_skillid > 0 then ranged_index = 3 end
	local weapons_after = ranged_index
	if z_ranged_skilltype == 0 then
		weapons_after = weapons_after - 1
	end

	local any_changes = false
	local weapons_before = table.getn(z_skill_tracker_weapon_order)
	if weapons_after ~= weapons_before then
		any_changes = true
	else
		if z_skill_tracker_weapon_order[1] ~= mainwep_skillid then any_changes = true end
		if subwep_skillid > 0 and z_skill_tracker_weapon_order[2] ~= subwep_skillid then any_changes = true end
		if z_ranged_skilltype > 0 and z_skill_tracker_weapon_order[ranged_index] ~= z_ranged_skilltype then any_changes = true end
	end

	windower.add_to_chat(100, 'Recalculating weaponry...')
	for i,skillid in ipairs(z_skill_tracker_weapon_order) do
		z_skill_tracker[skillid].tracking = false
	end
	addSkillTrackCategory(mainwep_skillid)
	addSkillTrackCategory(subwep_skillid)
	addSkillTrackCategory(z_ranged_skilltype)
	if any_changes then
		windower.add_to_chat(17, ' -- AutoSkill: detected some changes.')

		z_skill_tracker_weapon_order = {}
		if mainwep_skillid > 0 then table.insert(z_skill_tracker_weapon_order, mainwep_skillid) end
		if subwep_skillid > 0 then table.insert(z_skill_tracker_weapon_order, subwep_skillid) end
		if z_ranged_skilltype > 0 then table.insert(z_skill_tracker_weapon_order, z_ranged_skilltype) end

		if just_weapons then
			textbox_skills_reinitialize_function(z_textbox_skills, settings)
		end
	else
		windower.add_to_chat(17, ' -- AutoSkill: no changes were detected. The improvements saved a lot of string processing!')
	end
end

function recalculateAllSkills()
	-- do melee and ranged weapons
	recalculateWeaponry(false)
	-- any magical abilities this job may have
	for i,skillid in ipairs(z_skill_tracker_magic_order) do
		z_skill_tracker[skillid].tracking = false
	end
	z_skill_tracker_magic_order = {}
	for magname, rating in npairs(JOB_MAGIC_RATINGS[z_player.mjtla]) do
		local magid = SKILL_IDS[magname]
		addSkillTrackCategory(magid)
		table.insert(z_skill_tracker_magic_order, magid)
	end
	-- then defensive skills listed
	for i,skillid in ipairs(z_skill_tracker_defense_order) do
		z_skill_tracker[skillid].tracking = false
	end
	z_skill_tracker_defense_order = {}
	for defname, rating in pairs(JOB_DEFENSIVE_RATINGS[z_player.mjtla]) do
		local defid = SKILL_IDS[defname]
		addSkillTrackCategory(defid)
		table.insert(z_skill_tracker_defense_order, defid)
	end
	textbox_skills_reinitialize_function(z_textbox_skills, settings)
end

function recalculateVitals()
	windower.add_to_chat(100, ' =========== Recalculating vitals.')
	local player = windower.ffxi.get_player()
	z_player.obtains_msg = player.name..' obtains a'
	z_player.obtains_msg_len = z_player.obtains_msg:len()
	z_player.hp    = player.vitals['hp']
	z_player.maxhp = player.vitals['max_hp']
	z_player.mp    = player.vitals['mp']
	z_player.maxmp = player.vitals['max_mp']
	z_player.tp    = player.vitals['tp']
	z_player.jobs = {}
	z_player.jobs[player.main_job_id] = player.main_job_level
	z_player.mjtla = res.jobs[player.main_job_id].ens
	z_player.mjlvl = player.main_job_level
	z_player.effective_level = z_player.mjlvl
	if z_player.level_sync ~= 0 and z_player.level_sync < z_player.mjlvl then z_player.effective_level = z_player.level_sync end

	if player.sub_job_id ~= nil then 
	    z_player.jobs[player.sub_job_id] = player.sub_job_level
		z_player.sjtla = res.jobs[player.sub_job_id].ens
	end

	-- copy the skills table, don't just assign a reference which can go out of date
	for k,v in pairs(player.skills) do
		z_player.skills[k] = v
	end
	recalculateAllSkills()

	z_weakest_cure = 9999
	z_curing_abilities = {}
	z_required_buffs = {}
	z_missing_buffs = {}
	for job,lvl in pairs(z_player.jobs) do
		local jobname = res.jobs[job].ens
		if settings.buff_list[jobname] ~= nil then
			for id, abilityinfo in pairs(settings.buff_list[jobname]) do
				if abilityinfo.reqlvl <= lvl then
					if z_required_buffs[abilityinfo.buffid] == nil then
						abilityinfo.abilityid = id
						z_required_buffs[abilityinfo.buffid] = abilityinfo
					elseif z_required_buffs[abilityinfo.buffid].reqlvl < abilityinfo.reqlvl then
						abilityinfo.abilityid = id
						z_required_buffs[abilityinfo.buffid] = abilityinfo
						windower.add_to_chat(17, 'Required buff overwritten='..abilityinfo.buffid)
					end
				end
			end
		end
		if settings.cure_ability_list[jobname] ~= nil then
			for id, abilityinfo in pairs(settings.cure_ability_list[jobname]) do
				if abilityinfo.reqlvl <= lvl then
					z_curing_abilities[id] = abilityinfo
					if abilityinfo.amount < z_weakest_cure then z_weakest_cure = abilityinfo.amount end
				end
			end
		end
	end
	recalculateDangerZone()

	-- scan current buffs
	for reqid,reqbuffinfo in pairs(z_required_buffs) do
		local foundit = false
		for i,buffid in ipairs(player.buffs) do
			if buffid == reqid then
				foundit = true
				break
			end
		end
		if not foundit then
			table.insert(z_missing_buffs, reqid) 
		end
	end
end

function recalculateDangerZone()
	local low_health = 0.10 * z_player.maxhp
	local high_health = z_player.maxhp - (2*z_weakest_cure)
	z_health_danger = 2*z_most_damage_taken
	if z_health_danger > z_player.maxhp then
		if z_most_damage_taken >= z_player.maxhp then
			z_health_danger = 0
		else
			z_health_danger = z_most_damage_taken
		end
	end
	if z_health_danger < high_health then z_health_danger = high_health end
	if z_health_danger < low_health then z_health_danger = math.ceil(low_health) end
end

function recalculateAbilities()
	local abilities = windower.ffxi.get_abilities()
	local ability_recasts = windower.ffxi.get_ability_recasts()
	local spells = windower.ffxi.get_spells()
	local spell_recasts = windower.ffxi.get_spell_recasts()
	--windower.add_to_chat(17,  'Player abilities: '..table.tostring(abilities))
	--windower.add_to_chat(100, 'Player ability recasts: '..table.tostring(ability_recasts))
	--windower.add_to_chat(17,  'Player spells: '..table.tostring(spells))
	--windower.add_to_chat(100, 'Player spell recasts: '..table.tostring(spell_recasts))
end

function playSoundEffect(sound_file)
	if settings.play_sounds then
		windower.play_sound(windower.addon_path..sound_file)
	end
end

local function scanMobsInArea()
	local monsters = windower.ffxi.get_mob_array()
	local count = 0
	local lowest_distance = 9999
	windower.add_to_chat(17, 'Monsters scanned: '..table.getn(monsters))
	for i,mob in ipairs(monsters) do
		if count == 0 then
			--windower.add_to_chat(17, 'First monster, full data: '..table.tostring(mob))
		end
		--if distance < 50 then 
		--	windower.add_to_chat(17, 'Monster nearby: '..mob.name..' distance='..mob.distance)
		--end
		if mob.distance < lowest_distance then lowest_distance = mob.distance end
		count = count + 1
	end
	windower.add_to_chat(17, 'The closest monster was distance='..lowest_distance)
end

windower.register_event('gain buff', function (buffid)
	if table.getn(z_missing_buffs) == 0 then return end
	for i,reqbuffid in ipairs(z_missing_buffs) do
		if buffid == reqbuffid then
			table.remove(z_missing_buffs, i)
			return
		end
	end
end)

windower.register_event('lose buff', function (lostid)
	if lostid == 269 then -- Level sync
		z_player.level_sync = 0
		coroutine.schedule(recalculateVitals, 8)
	else
		for reqid,buffinfo in pairs(z_required_buffs) do
			if lostid == reqid then
				table.insert(z_missing_buffs, lostid)
			end
		end
	end
end)

windower.register_event('hpmax change', function (hpmax)
	z_player.maxhp = hpmax
	recalculateDangerZone()
end)

windower.register_event('hp change', function (hp)
	local hpdiff = z_player.hp - hp
	z_player.hp = hp

	if hpdiff > z_most_damage_taken then
		z_most_damage_taken = hpdiff
		recalculateDangerZone()
	end
end)

windower.register_event('mpmax change', function (mpmax)
	z_player.maxmp = mpmax
end)

windower.register_event('mp change', function (mp)
	z_player.mp = mp
end)

windower.register_event('tp change', function (tp)
	z_player.tp = tp
	if tp == 0 then -- there's a chance we just changed weaponry
		recalculateWeaponry(true)
	end
end)

windower.register_event('job change', function (main_job_id, main_job_level, sub_job_id, sub_job_level)
	coroutine.schedule(resetAllStats, 8)
end)

windower.register_event('level up', function (level)
	if level <= z_player.level_sync or z_player.level_sync == 0 then
		coroutine.schedule(recalculateVitals, 8)
	end
end)

windower.register_event('level down', function (level)
	if level <= z_player.level_sync or z_player.level_sync == 0 then
		coroutine.schedule(recalculateVitals, 8)
	end
end)

windower.register_event('status change', function (newstatus, oldstatus)
	if not recomputePauseStatus(newstatus) then
		windower.add_to_chat(100, "Status change unknown:   old="..oldstatus..'    new='..newstatus.. ' description='..status_name)
	end
end)

local function isTargetValidEnemy(target_index)
	local mob_data = windower.ffxi.get_mob_by_index(target_index)
	if mob_data == nil or mob_data.valid_target == false or mob_data.is_npc == false then
		return false
	end
	if mob_data.charmed == true then
		return false
	end
	return true
end

local function isTargetEnemySkillable(should_dump)
	local mob_data = windower.ffxi.get_mob_by_target('t')
	if mob_data == nil then
		return false
	end
	if should_dump then
		windower.add_to_chat(100, 'Target check dump: '..table.tostring(mob_data))
	end
	if mob_data.valid_target == false or mob_data.is_npc == false or mob_data.charmed == true then
		return false
	end
	if mob_data.claim_id == 0 then
		return false
	end
	if z_latest_status == 'Engaged' then
		-- TODO: examine if we're facing the enemy
		-- don't dump twice
		if should_dump then 
			local player = windower.ffxi.get_player()
			windower.add_to_chat(100, 'Player data dump: '..table.tostring(player))
		end
	end
	if mob_data.claim_id ~= z_player_id and should_dump then
		windower.add_to_chat(100, 'Target claim_id in nonzero but not player.id?: '..mob_data.claim_id)
	end
	
	return true
end

function verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	if actor_id == nil then actor_id = 'nil' end
	if actor_index == nil then actor_index = 'nil' end
	if target_id == nil then target_id = 'nil' end
	if target_index == nil then target_index = 'nil' end
	if param_1 == nil then param_1 = 'nil' end
	if param_2 == nil then param_2 = 'nil' end
	if param_3 == nil then param_3 = 'nil' end
	windower.add_to_chat(17, 'VERBOSE: action msg -- actor_id='..actor_id..' target_id='..target_id..'  target_index='..target_index..' message_id='..message_id..' param1='..param_1..' param2='..param_2..' param3='..param_3)
end

local z_candidate_mob_page_entries = {}
local z_reading_mob_kill_list = false
on_incomingtext_function = function (original, modified, orig_mode, mod_mode, blocked)
	--if original:find('You find') ~= nil then
	if original:find('knot quipu') ~= nil then
		local fulldata = {original:byte(1, original:len())}
		local strdata = ''
		for i,v in ipairs(fulldata) do 
			strdata = strdata..v..' '
		end
		windower.add_to_chat(17, 'found, strlen is '..original:len()..' om='..orig_mode..' mm='..mod_mode..' -- and the codes are: '..strdata)
		return false
	end
	
	local is_page_finalized = false
	if orig_mode == 121 then 
		-- "You find a bird egg on the Zu." 
		-- "You throw away a bird egg."
		local color_padding = 2
		if z_player.finds_msg == original:sub(1 + color_padding,z_player.finds_msg_len + color_padding) then
			-- adjust for 'a CCitem' or 'an CCitem' (color code)
			local item_start_index = original:find(' ', color_padding + z_player.finds_msg_len) + 3
			local item_stop_index = original:find(' on the ', item_start_index + 3) - 3
			local drop_name_guess = original:sub(item_start_index, item_stop_index)
			--windower.add_to_chat(100, 'my best guess at the You find item name="'..drop_name_guess..'" start='..item_start_index..' stop='..item_stop_index)
			for i,filter in ipairs(z_autodrop_filter_items) do
				if drop_name_guess:find(filter) ~= nil then
					if os.time() >= z_autodrop_filter_time then
						windower.add_to_chat(100, 'out of bounds of the drop timer window, but you find in the filter list! blocking msg about '..drop_name_guess)
					end
					return true -- block this message
				end
			end
		elseif z_player.throws_msg == original:sub(1 + color_padding, z_player.throws_msg_len + color_padding) then
			-- adjust for 'a CCitem' or 'an CCitem' (color code)
			modified = modified:gsub('You throw away a', 'You find and throw away a')
			return modified, newmode
		end
	elseif orig_mode == 127 then -- "PLAYERNAME obtains a bird egg."
		local color_padding = 2
		if z_player.obtains_msg == original:sub(1 + color_padding,z_player.obtains_msg_len + color_padding) then
			local item_start_index = original:find(' ', color_padding + z_player.obtains_msg_len) + 3
			local item_stop_index = original:len() - 5
			local drop_name_guess = original:sub(item_start_index, item_stop_index)
			--windower.add_to_chat(100, 'my best guess at the Frezer obtained item name="'..drop_name_guess..'" start='..item_start_index..' stop='..item_stop_index)
			for i,filter in ipairs(z_autodrop_filter_items) do
				if drop_name_guess:find(filter) ~= nil then
					if os.time() >= z_autodrop_filter_time then
						windower.add_to_chat(100, 'oob drop timer, but found a match for the obtained drop in the filter list! blocking msg about '..drop_name_guess)
					end
					return true -- block this message
				end
			end
		end
	elseif orig_mode == 141 then
		local original_length = original:len()
		if original_length == 86 and original:sub(3,84) == "Changing your job will result in the cancellation of your current training regime." then
			-- clear the book page (not, might be a color code in here?)
			clearPageTracker(settings)
			settings:save()
			textbox_reinitialize_function(z_textbox_misc, settings)
		end
	elseif orig_mode == 142 then
		local original_length = original:len()
		if original_length == 33 and original:sub(1,31) == 'New training regime registered!' then
			is_page_finalized = true
		end
	elseif orig_mode == 151 then
		local original_length = original:len()
		--if original_length == 69 and original:find('The information on this page instructs you to defeat the following:') ~= nil then
		--	windower.add_to_chat(17, ' -- AutoSkill: mob kill list is as follows')
		--	-- mob kill now follows:
		--	z_reading_mob_kill_list = true
		--	z_page_tracker = {}
		--elseif original_length == 173 and original:sub(1, 86) == "A grounds tome has been placed here by the Adventurers' Mutual Aid Network (A.M.A.N.)." then
		--	z_reading_mob_kill_list = true
		--	windower.add_to_chat(17, ' -- AutoSkill: talking to the Grounds tome...')
		--elseif original_length > 19 and original:sub(1, 19) == 'Target level range:' then
		--	-- end of mob kill list detected
		--	z_reading_mob_kill_list = false
		--	windower.add_to_chat(17, ' -- AutoSkill: mob kill list ended')
		--	textbox_reinitialize_function(z_textbox_misc, settings)
		if original:byte(1) >= 48 and original:byte(1) <= 57 then
			z_candidate_mob_page_entries = {}
			local curpos = 1
			local total_loops = 0
			while curpos + 4 < original_length do
				local slashpos = original:find('/', curpos, true)
				local spacepos = original:find(' ', curpos, true)
				local dotpos = original:find('.', curpos, true)
				if spacepos == nil and dotpos == nil then break end

				local amount = 0
				local max = 0
				local mobname = original:sub(spacepos+1, dotpos - 1)
				if slashpos ~= nil then -- we checked the Manual Progress
					is_page_finalized = true
					amount = tonumber(original:sub(curpos, slashpos-1))
					max = tonumber(original:sub(slashpos+1, spacepos-1))
				else -- we've selected a regime for the first time
					max = tonumber(original:sub(curpos, spacepos - 1))
				end
				if slashpos == nil then slashpos = 'nil' end
				if spacepos == nil then spacepos = 'nil' end
				if dotpos == nil then dotpos = 'nil' end
				if max ~= nil and max > 0 then
					local is_family = nil
					if mobname:sub(1, 15) == 'members of the ' then
						mobname = mobname:sub(16, 16):upper()..mobname:sub(17)
						is_family = true
						--windower.add_to_chat(17, ' -- AutoSkill: family detected -- '..table.size(z_candidate_mob_page_entries))
					end
					local candidate = {}
					candidate.name = mobname
					candidate.progress = amount
					candidate.needed = max
					candidate.is_family = is_family
					table.insert(z_candidate_mob_page_entries, candidate)
				end
				curpos = dotpos + 2
				total_loops = total_loops + 1
				if total_loops > 10 then
					playSoundEffect(settings.sound_files.alert)
					windower.add_to_chat(17, ' -- AutoSkill: ERROR SOMETHING VERY WRONG HAPPENED -- exceeded 10 loops???')
					break
				end
			end
		end
	end

	local candidate_entry_count = table.getn(z_candidate_mob_page_entries)
	if is_page_finalized and candidate_entry_count > 0 then
		clearPageTracker(settings)
		for i, pagedata in ipairs(z_candidate_mob_page_entries) do
			if i > MAX_PAGES_TO_TRACK then
				windower.add_to_chat(100, '!!!ERROR!!! AutoSkill expected no more than '..MAX_PAGES_TO_TRACK..' entries, yet there were '..tablecandidate_entry_count)
				break
			end
			z_page_tracker[i] = {}
			z_page_tracker[i].name      = string.padright(pagedata.name, MAX_LENGTH)
			z_page_tracker[i].progress  = pagedata.progress
			z_page_tracker[i].needed    = pagedata.needed
			z_page_tracker[i].is_family = pagedata.is_family
			local index = 'page'..i
			settings.page_tracker[index].name      = pagedata.name
			settings.page_tracker[index].progress  = tonumber(pagedata.progress)
			settings.page_tracker[index].needed    = tonumber(pagedata.needed)
			settings.page_tracker[index].is_family = pagedata.is_family
		end
		settings:save()

		textbox_reinitialize_function(z_textbox_misc, settings)
		z_candidate_mob_page_entries = {}
	end

	if z_super_verbose and original:sub(1, 7) ~= 'VERBOSE' then
		local blockstr = blocked and 'true' or 'false'
		windower.add_to_chat(17, 'VERBOSE: om='..orig_mode..' mm='..mod_mode..' block='..blockstr.. ' -- orig: "'..original..'"')
		return true
	end
	return -- no return let's the message pass
end
windower.register_event('incoming text', on_incomingtext_function)

local z_most_recent_kill_id = 0
local z_most_recent_kill_time = 0
-- The programmer that wrote this thinks that they're clever.
-- Does anyone know if this is performant? Does anybody care?
local z_message_to_function_map = {}

-- Unable to see <target>.
z_message_to_function_map[5] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
end

function loadNMsettingsToTracker(nm_id)
	if type(nm_id) == 'string' then
		windower.add_to_chat(100, 'nm_id in loadNMsettingsToTracker was string, expecting integer: '..nm_id)
		nm_id = tonumber(nm_id)
	end
	local nm_name = z_phnm_spawn[nm_id].name
	local nm_key = string.toluakey(nm_name)
	if settings.nms[nm_key] == nil then -- no entries found, create a new one
		settings.nms[nm_key] = {}
		settings.nms[nm_key].name = nm_name
		settings.nms[nm_key].time_last_kill = 0
		settings.nms[nm_key].ph_kills = 0
	else -- found some data, can we fill in any gaps?
		if z_phnm_spawn[nm_id].time_last_kill == 0 then
			z_phnm_spawn[nm_id].time_last_kill = settings.nms[nm_key].time_last_kill
			z_phnm_spawn[nm_id].ph_kills = settings.nms[nm_key].ph_kills
			for i = 1,z_phnm_spawn[nm_id].ph_kills,1 do
				-- TODO: scrape the placeholder chance
				z_phnm_spawn[nm_id].probability = z_phnm_spawn[nm_id].probability * 0.95
			end
		end
		if z_mob_tracker[nm_id].respawn == 0 then
			--windower.add_to_chat(100, 'wtfa: '..nm_key)
			--windower.add_to_chat(100, 'wtfb: '..nm_id)
			--windower.add_to_chat(100, 'wtfc: '..settings.nms[nm_key].time_last_kill)
			--windower.add_to_chat(100, 'wtfd: '..z_mob_tracker[nm_id].respawn_time)
			z_mob_tracker[nm_id].respawn = settings.nms[nm_key].time_last_kill + z_mob_tracker[nm_id].respawn_time + MOB_TRACKER_FADE_TIME
		end
	end
	return nm_key
end

function beginTrackingMob(mobid, curzone)
	if z_mob_tracker[mobid] ~= nil then return end

	if curzone == nil then curzone = res.zones[windower.ffxi.get_info().zone].search end

	local mob_name = 'Unknown'
	if z_mobdata.nms[curzone][mobid] ~= nil then
		mob_name = z_mobdata.nms[curzone][mobid].name
	else
		local mob_data = windower.ffxi.get_mob_by_id(mobid)
		if mob_data ~= nil then
			mob_name = mob_data.name
		end
	end

	z_mob_tracker[mobid] = {}
	z_mob_tracker[mobid].name = mob_name
	z_mob_tracker[mobid].is_nm = false
	z_mob_tracker[mobid].respawn = 0
	-- TODO: scrape respawn times from SQL
	z_mob_tracker[mobid].respawn_time = 330 -- about 5 1/2 minutes by default
	if curzone == 'Oztroja' then z_mob_tracker[mobid].respawn_time = 792 end

	-- was target a placeholder?
	if z_mobdata.phs[curzone][mobid] == nil then
		z_mob_tracker[mobid].phnm = 0
	else
		local nm_id = z_mobdata.phs[curzone][mobid].related_nm
		z_mob_tracker[mobid].phnm = nm_id
		-- track my related NM
		beginTrackingMob(nm_id, curzone)
	end
	-- was target an NM?
	if z_mobdata.nms[curzone][mobid] ~= nil then
		z_mob_tracker[mobid].is_nm = true
		z_mob_tracker[mobid].respawn_time = z_mobdata.nms[curzone][mobid].respawn_minimum
		if z_phnm_spawn[mobid] == nil then
			-- create the NM tracking group data
			z_phnm_spawn[mobid] = {}
			z_phnm_spawn[mobid].name = z_mobdata.nms[curzone][mobid].name
			z_phnm_spawn[mobid].time_last_kill = 0
			z_phnm_spawn[mobid].ph_kills = 0
			z_phnm_spawn[mobid].probability = 1
			z_phnm_spawn[mobid].phs_currently_dead = 0
			z_phnm_spawn[mobid].total_phs = 0
			-- check for duplicate NMs with the same name e.g. Leaping Lizzy has two IDs in the same zone
			local alter_egos = {}
			for otherid,otherdata in pairs(z_mobdata.nms[curzone]) do
				if otherid ~= mobid and otherdata.name == z_phnm_spawn[mobid].name then
					if z_phnm_spawn[otherid] == nil then
						table.insert(alter_egos, otherid)
						-- TODO: does this link the references, or does this make a copy?
						z_phnm_spawn[otherid] = z_phnm_spawn[mobid]
						beginTrackingMob(otherid, curzone)
					end
				end
			end
			-- update with any settngs we can
			z_phnm_spawn[mobid].key = loadNMsettingsToTracker(mobid)
			if z_phnm_spawn[mobid].time_last_kill > 0 then
				z_mob_tracker[mobid].respawn = z_phnm_spawn[mobid].time_last_kill + z_mob_tracker[mobid].respawn_time + MOB_TRACKER_FADE_TIME
				for i,otherid in ipairs(alter_egos) do
					z_mob_tracker[mobid].otherid = z_phnm_spawn[mobid].time_last_kill + z_mob_tracker[mobid].respawn_time + MOB_TRACKER_FADE_TIME
				end
			end
			-- track self 
			table.insert(z_mob_tracker_order, mobid)
			-- and all related placeholders
			if os.time() > z_mob_tracker[mobid].respawn then
				for phid,phdata in npairs(z_mobdata.phs[curzone]) do
					if mobid == phdata.related_nm then
						z_phnm_spawn[mobid].total_phs = z_phnm_spawn[mobid].total_phs + 1
						beginTrackingMob(phid, curzone)
						table.insert(z_mob_tracker_order, phid)
					end
					for i,otherid in ipairs(alter_egos) do
						if otherid == phdata.related_nm then
							z_phnm_spawn[mobid].total_phs = z_phnm_spawn[mobid].total_phs + 1
							beginTrackingMob(phid, curzone)
							table.insert(z_mob_tracker_order, phid)
						end
					end
				end
			end
		end
	end
end

-- <actor> defeats <target>.
z_message_to_function_map[6] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	local curtime = os.time()
	z_most_recent_kill_id = target_id
	z_most_recent_kill_time = curtime
	if not z_track_mode then return end
	z_mob_tracker_kills = z_mob_tracker_kills + 1

	--z_mob_tracker[target_id].last_death = curtime
	local curzone = res.zones[windower.ffxi.get_info().zone].search
	beginTrackingMob(target_id, curzone)

	-- was target a placeholder?
	if z_mobdata.phs[curzone][target_id] ~= nil then
		local nm_id = z_mobdata.phs[curzone][target_id].related_nm
		z_mob_tracker[target_id].is_dead = true
		z_phnm_spawn[nm_id].ph_kills = z_phnm_spawn[nm_id].ph_kills + 1
		z_phnm_spawn[nm_id].phs_currently_dead = z_phnm_spawn[nm_id].phs_currently_dead + 1
		-- TODO: scrape the placeholder chance
		z_phnm_spawn[nm_id].probability = z_phnm_spawn[nm_id].probability * 0.95
		-- update the persistent record of this NM
		if curtime > z_mob_tracker[nm_id].respawn then
			local nm_key = z_phnm_spawn[nm_id].key
			settings.nms[nm_key].ph_kills = settings.nms[nm_key].ph_kills + 1
			settings:save()
		end
	end
	-- was target an NM?
	if z_mobdata.nms[curzone][target_id] ~= nil then
		z_phnm_spawn[target_id].ph_kills = 0
		z_phnm_spawn[target_id].phs_currently_dead = 0
		z_phnm_spawn[target_id].probability = 1
		z_phnm_spawn[target_id].time_last_kill = curtime
		-- update the persistent record of this NM
		local nm_key = z_phnm_spawn[target_id].key
		settings.nms[nm_key].time_last_kill = z_phnm_spawn[target_id].time_last_kill
		settings.nms[nm_key].ph_kills = 0
		settings:save()
		-- stop tracking the placeholders
		local removemobs = {}
		for i, mobid in ipairs(z_mob_tracker_order) do
			if z_mob_tracker[mobid].phnm == target_id then
				table.insert(removemobs, mobid)
			end
		end
		windower.add_to_chat(100, 'Killed PHNM. Removing placeholders...')
		for i,mobid in ipairs(removemobs) do
			windower.add_to_chat(100, 'Attempting to remove mobid='..mobid)
			for j, mobjd in ipairs(z_mob_tracker_order) do
				if mobid == mobjd then
					table.remove(z_mob_tracker_order, j)
					break
				end
			end
		end
	end
	z_mob_tracker[target_id].respawn = curtime + z_mob_tracker[target_id].respawn_time + MOB_TRACKER_FADE_TIME
	local insert_at = 0
	local old_index = 0
	for i,mobid in ipairs(z_mob_tracker_order) do
		if mobid == target_id then old_index = i end
		if z_mob_tracker[mobid].respawn > z_mob_tracker[target_id].respawn then
			insert_at = i
			break
		end
	end
	-- oldindex == 0 and insertat == 0 (wasn't found, add at end)
	-- oldindex == 5 and insertat == 0 (was at pos 5, add at end)
	-- oldindex == 0 and insertat == 5 (wasn't found, insert in middle at pos 5)
	-- oldindex == 3 and insertat == 5 (was found, insert in middle at pos 5)
	-- oldindex == 5 and insertat == 3 (does this make sense?)
	-- oldindex == 5 and insertat == 5 (does this make sense?)
	if insert_at == 0 then
		if old_index > 0 then
			table.remove(z_mob_tracker_order, old_index)
		end
		table.insert(z_mob_tracker_order, target_id)
	else
		if old_index < insert_at then
			if old_index == 0 then
				table.insert(z_mob_tracker_order, insert_at, target_id)
			else
				table.remove(z_mob_tracker_order, old_index)
				table.insert(z_mob_tracker_order, insert_at-1, target_id)
			end
		end
	end

	textbox_reinitialize_function(z_textbox_misc, settings)
	verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
end

--	<target>'s <skill> skill rises 0.<number> points.
z_message_to_function_map[38] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	if CRAFTING_IDS[param_1] ~= nil then return end
	if not z_skill_tracker[param_1].tracking then
		-- got a skill up on a weapon we weren't tracking, must have changed gear
		recalculateWeaponry(true)
	end
end

-- <target>'s <skill> skill reaches level <number>.
z_message_to_function_map[53] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	if CRAFTING_IDS[param_1] ~= nil then return end
	if not z_skill_tracker[param_1].tracking then
		-- got a skill up on a weapon we weren't tracking, must have changed gear
		recalculateWeaponry(true)
	else -- update the skill's current value
		z_player.skills[param_1] = param_2
		z_skill_tracker[param_1].current = param_2:string():lpad(' ', 3)
		if z_skill_tracker[param_1].current == z_skill_tracker[param_1].cap then
			z_skill_tracker[param_1].is_capped = true
			textbox_skills_reinitialize_function()
		end
		textbox_render_skill_update()
	end
end

-- <actor> uses <weapon_skill>.
z_message_to_function_map[101] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	if actor_id == z_player_id then
		LAST_ACTION_TICK = os.time() + 2
	end
end

-- You do not have an appropriate ranged weapon equipped.
z_message_to_function_map[216] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	if z_operational_mode['ranged'] then
		tryEquipMoreAmmo()
	end
end

-- TODO: this code goes away once NM tracking/scraping from DSP is complete
-- /check gave "is impossible to guage!"
z_message_to_function_map[249] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
--	windower.add_to_chat(17, 'actor='..actor_id..' target='..target_id..'  target_index='..target_index..' messageid='..message_id..' param1='..param_1..' param2='..param_2..' param3='..param_3)
	local zoneidstr = tostring(windower.ffxi.get_info().zone)
	if settings.mob_ids.nms[zoneidstr] == nil then settings.mob_ids.nms[zoneidstr] = {} end
	local mob_data = windower.ffxi.get_mob_by_id(target_id)
	if mob_data == nil then return end
	local mobidstr = tostring(target_id)
	if settings.mob_ids.nms[zoneidstr][mobidstr] ~= nil then return end
	settings.mob_ids.nms[zoneidstr][mobidstr] = mob_data.name
	settings:save()
	windower.add_to_chat(100, 'NM added and saved to persistent settings.')
end

-- <ability> can only be performed during battle.
z_message_to_function_map[525] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	playSoundEffect(settings.sound_files.alert)
end

-- Level Sync activated. Your level has been restricted to <number>. Equipment affected by the level restriction will be adjusted accordingly. Experience points will become unavailable for all party members should the Level Sync designee stray too far from the enemy.
z_message_to_function_map[540] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	z_player.level_sync = param_2
	coroutine.schedule(recalculateVitals, 8)
end

-- You defeated a designated target. (Progress: <number>/<number>)
z_message_to_function_map[558] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	if z_most_recent_kill_id ~= 0 and z_most_recent_kill_time + 2 >= os.time() then
		local mob_data = windower.ffxi.get_mob_by_id(z_most_recent_kill_id)
		local latest_kill_index = 0
		for i,pagedata in ipairs(z_page_tracker) do
			if pagedata.name == mob_data.name then
				-- exact match
				latest_kill_index = i
				break
			elseif pagedata.name:len() > mob_data.name:len() and pagedata.name:sub(1, mob_data.name:len()) == mob_data.name then
				-- something like you killed a Werebat instead of 5 Werebats, this was close enough
				latest_kill_index = i
				break
			end
			if pagedata.is_family and pagedata.needed == param_2 and pagedata.progress + 1 == param_1 then
				-- here, we're guessing. we found a mob family, a kill progress message that matched
				-- but we have no clue if they really are the same entry.
				-- We'll keep looking, just in case. If we find an exact match after this, we'll quit and use that instead.
				latest_kill_index = i
			end
		end
		if latest_kill_index == 0 then
			-- still couldn't find it, start a new entry
			if table.getn(z_page_tracker) < MAX_PAGES_TO_TRACK then
				local page_entry = {}
				page_entry.name      = string.padright(mob_data.name, MAX_LENGTH)
				page_entry.progress  = param_1
				page_entry.needed    = param_2
				page_entry.is_family = false
				table.insert(z_page_tracker, page_entry)

				local index = 'page'..table.getn(z_page_tracker)
				settings.page_tracker[index].name      = mob_data.name
				settings.page_tracker[index].progress  = param_1
				settings.page_tracker[index].needed    = param_2
				settings.page_tracker[index].is_family = false
				textbox_reinitialize_function(z_textbox_misc, settings)
			end
		else
			z_page_tracker[latest_kill_index].progress = param_1
			settings.page_tracker['page'..latest_kill_index].progress = param_1
		end
		settings:save()
		z_most_recent_kill_id = 0
		return
	end
	
	-- We missed the kill message. Are we able to guess?
	windower.add_to_chat(100, ' -- AutoSkill error: page requirement completion message with no kill message? (too far away?)')
	local candidate_index = 0
	local possible = 0
	for i,pagedata in ipairs(z_page_tracker) do
		if pagedata.needed == param_2 and pagedata.progress + 1 == param_1 then
			candidate_index = i
			possible = possible + 1
		end
	end
	if possible == 1 then
		z_page_tracker[candidate_index].progress = param_1
		settings.page_tracker['page'..candidate_index].progress = param_1
		settings:save()
		return
	end

	windower.add_to_chat(17, ' -- AutoSkill: unable to identify page kill index -- WE SHOULD BE SMARTER SOMEHOW - candidates='..possible..' -- examine dump: ')
	verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
end

-- You have successfully completed the training regime.
z_message_to_function_map[559] = function (actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	local remove_mobs = {}
	for pagename, trackinfo in pairs(z_page_tracker) do
		if trackinfo.progress == trackinfo.needed then
			trackinfo.progress = 0
		else
			table.insert(remove_mobs, pagename)
		end
	end
	for i,pagename in ipairs(remove_mobs) do z_page_tracker[pagename] = nil end
	textbox_render_update()
	if settings.play_sounds then
		local files = {}
		for key,name in pairs(settings.sound_files.book_complete) do table.insert(files, name) end
		playSoundEffect(files[math.random(table.getn(files))])
	end
	settings:save()
end

windower.register_event('action message', function(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	if z_super_verbose then
		windower.add_to_chat(17, 'messsage in verbose mode:')
		verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
		return
	end

	if z_message_to_function_map[message_id] ~= nil then
		z_message_to_function_map[message_id](actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	else
		--verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	end
end)

 on_action_function = function (act)
	if z_locked_target_id == 0 then
		windower.add_to_chat(17, 'AutoSkill  WARNING! action triggered when not active')
		stopAuto()
		return
	end

	local actor = act.actor_id
	local category = act.category
	
	if actor == z_player_id then
		if category == 1 then
			-- melee attack performed
		elseif category == 6 then -- Job Ability but not DNC moves
			--windower.add_to_chat(100, 'Debug category='..category..' -- '..table.tostring(act))
		elseif category == 7 then -- WeaponSkill has begun
			LAST_ACTION_TICK = os.time() + 3
		elseif category == 11 then
			windower.add_to_chat(100, 'Debug category='..category..' -- '..table.tostring(act))
		elseif category == 14 then -- DNC TP moves
			if z_curing_abilities[act.param] ~= nil then
				local tpmovename = z_curing_abilities[act.param].name
				z_last_ability_tick[tpmovename] = os.time() + act.recast
			end			
		elseif category == 12 then
			if act.param == 24931 then -- Ranged attack begun, now frozen until after z_ranged_delay
				z_last_ability_tick['ranged'] = os.clock()
				LAST_ACTION_TICK = os.time() + z_ranged_delay
			elseif act.param == 28787 then -- You move and interrupt your aim.
				z_last_ability_tick['ranged'] = os.clock()
				LAST_ACTION_TICK = os.time()
			else
				windower.add_to_chat(100, 'Debug category='..category..' -- '..table.tostring(act))
			end
		elseif category == 2 then -- Ranged attack completed
			if z_ammo_count ~= nil then 
				z_ammo_count = z_ammo_count - 1
				if z_ammo_count <= 0 then
					tryEquipMoreAmmo()
				end
			end
			if z_last_ability_tick['ranged'] ~= 0 then
				local latest_shot_time = os.clock() - z_last_ability_tick['ranged']
				if z_ranged_delay == 0 then
					z_ranged_delay = latest_shot_time
				else
					z_ranged_delay = (z_ranged_delay + (3*latest_shot_time)) / 4
				end
			end
		else
			--windower.add_to_chat(100, 'Debug category='..category..' -- '..table.tostring(act))
		end
		--windower.send_command('@wait ' .. z_ranged_delay .. ';input /shoot <t>')
	end
	if not z_paused then
		trySomeAction(category)
	end
end

local LAST_ACTION_TICK = os.time()
function trySomeAction(category)
	if z_paused then return end
	local curtime = os.time()
	if curtime < LAST_ACTION_TICK + 1 then return end
	if z_operational_mode.state == nil then return end

	local action = nil
	if z_player.hp < z_health_danger then -- emergency! cure immediately
		local best_gain_per_cost = 0
		local best_cure_name = nil
		local available_cures = 0
		for id,cure in pairs(z_curing_abilities) do
			if z_last_ability_tick[cure.name] == nil then z_last_ability_tick[cure.name] = 0 end
			if z_last_ability_tick[cure.name] < curtime then
				local expected_amount = cure.amount
				if expected_amount + z_player.hp > z_player.maxhp then expected_amount = z_player.maxhp - z_player.hp end
				local expected_efficiency = 0
				if cure.mpcost > 0 and cure.mpcost <= z_player.mp then
					expected_efficiency = expected_amount / cure.mpcost
					available_cures = available_cures + 1
				elseif cure.tpcost > 0 and cure.tpcost <= z_player.tp then
					expected_efficiency = expected_amount / cure.tpcost
					available_cures = available_cures + 1
				end
				if expected_efficiency > best_gain_per_cost then
					best_gain_per_cost = expected_efficiency
					best_cure_name = cure.name
				end
			end
		end
		if best_cure_name ~= nil then
			action = 'input /ja "'..best_cure_name..'" <me>'
			if available_cures > 1 then coroutine.schedule(trySomeAction, 2) end
		end
	end
	if action == nil and table.getn(z_missing_buffs) > 0 then -- no emergency, time to buff up?
		-- {['reqlvl']= 5, ['category']='samba', ['id']=368, ['name']='Drain Samba',   ['mpcost']=0,['tpcost']=100, ['cooldown']=60, ['meleeonly']=true},
		for i,missingbuffid in ipairs(z_missing_buffs) do
			for reqbuffid,abilityinfo in pairs(z_required_buffs) do
				if missingbuffid == reqbuffid then
					if z_player.mp < abilityinfo.mpcost or z_player.tp < abilityinfo.tpcost then break end
					if abilityinfo.tpcost > 0 then -- tp cost implies it's melee only
						if z_operational_mode['melee'] == nil then break end
						if category ~= 1 then break end
					end
					if z_last_ability_tick[abilityinfo.name] == nil then z_last_ability_tick[abilityinfo.name] = 0 end
					if z_last_ability_tick[abilityinfo.name] < curtime then
						action = 'input /ja "'..abilityinfo.name..'" <me>'
						break
					end
				end
			end
			if action ~= nil then break end
		end
	end

	-- now examining actions that could be performed on the enemy
	if action == nil then
		if isTargetEnemySkillable(false) then
			if category == 1 and z_player.hp > z_health_danger and z_player.tp > 1000 then 
				-- TODO: compute appropriate weaponskill
				action = 'input /ws "Gust Slash" <t>'
			elseif z_operational_mode['ranged'] and (z_operational_mode.state ~= 'both' or category == 1) then 
				local mstime = os.clock()
				local penalty = 0
				if z_operational_mode.state == 'both' then penalty = 5 end
				if z_last_ability_tick['ranged'] + z_ranged_delay + penalty < mstime then
					action = 'input /ra <t>'
				end
			end
		end
	end

	if action ~= nil then
		windower.send_command(action)
		LAST_ACTION_TICK = curtime
	end
end

function autoDropOrKeep(mode, args)
	if mode ~= 'keep' and mode ~= 'drop' then return end
	if args == nil then return end
	local item_id = tonumber(args)
	local item_data = nil
	if item_id ~= nil then
		item_data = res.items[item_id]
		if item_data == nil then
			windower.add_to_chat(100, ' -- AutoSkill: item with ID#'..itemid..' could not be found.')
			return
		end
	else
		local total_searched = 0
		local candidate_id = {}
		local search_name = args:lower()
		local results = 0
		for i,idata in pairs(res.items) do
			local en = idata.en:lower()
			local enl = idata.enl:lower()
			if en:find(search_name) ~= nil or enl:find(search_name) ~= nil then
				table.insert(candidate_id, i)
				results = results + 1
				if results >= 10 then break end
			end
			total_searched = total_searched + 1
		end
		if results == 0 then
			windower.add_to_chat(17, ' -- Item with name="'..search_name..'" was not found in '..total_searched..' items searched.')
			return
		elseif results > 1 then
			windower.add_to_chat(17, ' -- Too many results. Item candidates found: '..results)
			for i,id in ipairs(candidate_id) do
				windower.add_to_chat(17, '  id='..id..' en='..res.items[id].en..' -- enl='..res.items[id].enl)
			end
			if results >= 10 then windower.add_to_chat(17, ' -- Note: Too many results. (Stopped after the first ten.)') end
			return
		end
		item_id = candidate_id[1]
		item_data = res.items[item_id]
	end

	settings.autodrop['id'..item_id] = mode
	settings:save()
	windower.add_to_chat(100, ' -- AutoSkill: item '..item_data.en..' ('..item_id..') will now alway '..mode:upper())
end

windower.register_event('add item', function(bag, index, id, count)
	if z_pause_autodrop then return end
	if bag ~= 0 then return end
	local key = 'id'..id
	if settings.autodrop[key] == nil or settings.autodrop[key] == 'keep' then 
		return
	else
		local curtime = os.time()
		if curtime > z_autodrop_filter_time then
			z_autodrop_filter_items = {}
		end
		table.insert(z_autodrop_filter_items, res.items[id].enl)
		z_autodrop_filter_time = curtime + 2
		windower.ffxi.drop_item(index, count)
		windower.add_to_chat(100, 'I autodropped a thing! I tried to drop ItemID='..id..' '..res.items[id].en)
	end
end)

local function equipAmmoFromInventory()
	for invindex,itemdata in pairs(windower.ffxi.get_items(z_ammo_bag)) do
		if type(itemdata) == 'table' then
			if itemdata.id == z_ammo_type then
				z_ammo_count = itemdata.count
				windower.ffxi.set_equip(invindex, EQUIPMENT_AMMO_SLOT, z_ammo_bag)
				return true
			end
		end
	end
end

local function searchAndEquipFromBag(baginventory, bagid)
	for invindex,itemdata in pairs(baginventory) do
		if type(itemdata) == 'table' then
			if itemdata.id == z_ammo_type then
				z_ammo_count = itemdata.count
				if res.bags[bagid].equippable == 'false' and res.bags[bagid].access == 'Everywhere' then
					-- special mode, need to pull out of the bag into inventory. assumed we already made sure inventory has space.
					windower.ffxi.get_item(bagid, invindex, z_ammo_count)
					windower.add_to_chat(17, ' -- AutoSkill: Found '..z_ammo_count..' ammunition in storage '..res.bags[bagid].en..' -- moving it to main inventory.')
					z_ammo_bag = 0 -- inventory
					coroutine.schedule(equipAmmoFromInventory, 1)
					return true
				else
					z_ammo_bag = bagid
				end
				windower.ffxi.set_equip(invindex, EQUIPMENT_AMMO_SLOT, z_ammo_bag)
				windower.add_to_chat(17, ' -- AutoSkill: Found and equipped '..z_ammo_count..' ammunition of the same type in '..res.bags[z_ammo_bag].en)
				return true
			end
		end
	end
	return false
end

local function tryEquipMoreAmmo()
	-- [0] = {id=0,en="Inventory",access="Everywhere",command="inventory",equippable="true"},
	if z_ammo_type == nil then
		windower.add_to_chat(17, 'Error: specify ammunition with //ask ammo [ammo_name]')
		return
	end
	local full_inventory = windower.ffxi.get_items()

	local initial_bag = ''
	if z_ammo_bag ~= nil then
		initial_bag = res.bags[z_ammo_bag].command
		if searchAndEquipFromBag(full_inventory[initial_bag], z_ammo_bag) then return end
	end
	for bagid,baginfo in ipairs(res.bags) do
		if baginfo.command ~= initial_bag and baginfo.equippable == 'true' then
			if searchAndEquipFromBag(full_inventory[baginfo.command], bagid) then return end
		end
	end
	if full_inventory.inventory.count == full_inventory.inventory.max then
		windower.add_to_chat(17, ' -- AutoSkill: Could not find any ammo in inventory/wardrobes.')
		windower.add_to_chat(17, 'WarningInventory is full! Cannot move items from satchel, etc. to equippable bags. Stopping ranged.')
		if z_operational_mode['melee'] then
			startAuto('melee')
			return
		else
			stopAuto()
			return
		end
	end
	for bagid,baginfo in ipairs(res.bags) do
		if baginfo.command ~= initial_bag and baginfo.equippable == 'false' and baginfo.access == 'Everywhere' then
			if searchAndEquipFromBag(full_inventory[baginfo.command], bagid) then return end
		end
	end
	windower.add_to_chat(17, ' -- AutoSkill: Could not find any ammo in inventory/wardrobes/satchels. Stopping ranged.')
	if z_operational_mode['melee'] then
		startAuto('melee')
		return
	else
		stopAuto()
		return
	end
end

local function startAuto(mode)
	if mode == 'both' then
		z_operational_mode.state = mode
		z_operational_mode['ranged'] = true
		z_operational_mode['melee'] = true
	else
		z_operational_mode = {}
		z_operational_mode.state = mode
		z_operational_mode[mode] = true
	end
	if regid_action ~= nil then
		windower.add_to_chat(17, 'AutoSkill now running in mode: '..z_operational_mode.state)
		return
	end
	local player = windower.ffxi.get_player()
	z_player_id = player.id
	recomputePauseStatus(player.status)
	--if isTargetValidEnemy(player.target_index) then
	--windower.add_to_chat(17, 'Mob data: ' .. table.tostring(mob_data))
	
	z_locked_target_id = player.target_index
	windower.add_to_chat(17, 'AutoSkill  ~~STARTING~~ mode: '..z_operational_mode.state)
	trySomeAction()
	regid_action = windower.register_event('action', on_action_function)
end

local function stopAuto()
	z_operational_mode = {}
	if regid_action == nil then return end
	windower.unregister_event(regid_action)
	regid_action = nil
	windower.add_to_chat(17, 'AutoSkill  ~~STOPPED~~')
end

function recomputePauseStatus(newstatus)
	if newstatus == nil then
		local player = windower.ffxi.get_player()
		newstatus = player.status
	end
	z_latest_status = res.statuses[newstatus].en
	if z_latest_status == 'Dead' then
		stopAuto()
	elseif z_latest_status == 'Event' or z_latest_status == 'Chocobo' or z_latest_status == 'Mount' then 
		z_paused = true
	elseif z_latest_status == 'Resting' or z_latest_status == 'Sitting' or z_latest_status == 'Kneeling' or z_latest_status =='Crafting' then
		z_paused = true
	elseif z_latest_status == 'Idle' then
		if z_operational_mode.state == 'melee' then
			z_paused = true
		else
			z_paused = false
		end
	elseif z_latest_status == 'Engaged' then
		z_paused = false
		trySomeAction(1) -- should we Drain Samba or something?
	else
		z_paused = true
		return false
	end
	return true
end

local function displayStats()
	windower.add_to_chat(100, 'Most damage taken: '..z_most_damage_taken)
	windower.add_to_chat(100, 'Danger health computed as: '..z_health_danger)
	local pretty_delay = tostring(z_ranged_delay)
	if pretty_delay:len() > 4 then
		pretty_delay = pretty_delay:sub(1, 4)
	end
	local penalty_msg = ''
	if z_operational_mode.state == 'both' then
		penalty_msg = " (in 'both' mode, giving extra melee time)"
	end
	windower.add_to_chat(100, 'Computed ranged delay as: '..pretty_delay..penalty_msg)

	local zonephcount, zonenmcount = 0, 0
	local zonestr = res.zones[windower.ffxi.get_info().zone].search
	zonephcount = table.size(settings.mob_ids.placeholders[zoneidstr])
	zonenmcount = table.size(settings.mob_ids.nms[zoneidstr])
	windower.add_to_chat(100, 'Current zone has '..zonenmcount..' NMs recorded and '..zonephcount..' placeholders.')
end

local HELP_MESSAGE = [[
AutoSkill - Commands listing:
//autoskill [options]             -- (aka. //ask)
    melee  - Starts automated melee skilling
    ranged - Starts ranged spamming
    stop   - Stops any automated actions
	ammo [name] - The default ammunition to search for.
	----- NM Scanner Settings ---------------------
	scan [period] - time in seconds to scan, [5+]. If period is "off", will disable scanning.
	addnm  - uses player <t> to record NM ID. Will scan for it in the future.
	addph  - Marks a mob as a placeholder. Will message the player on selection.
	----- Drop Commands ---------------------------
	drop [item] - either the item name or item ID. will auto drop from now on, but not drop what you have
	keep [item] - will undo a drop command, will not auto-drop that item permanently
	pausedrop   - temporarily suspend all auto-drops. (does not persist between addon reloads)
	----- Text Commands ---------------------------
    buffs  - Displays current player's active buff IDs
    stats  - Displays all recorded stats since last loaded
    help   - Displays this help text
	----- Exmaples ---------------------------
  //ask ammo horn arrow -- Sets the default ammunition to "Horn Arrow"
  //ask ranged          -- begins automatic ranged spam skilling   
  //ask scan 60         -- modifies the NM scanner to check every 60 seconds
  //ask addph           -- if a player target exists, this is recorded as a placeholder mob]]
local function displayHelp()
	windower.add_to_chat(100, HELP_MESSAGE)
end

windower.register_event('addon command',function (...)
	local varargs = {...}
	local param = {}
	local paramcount = 0
	for i,v in ipairs(varargs) do
		table.insert(param, tonumber(v) or v:lower())
		paramcount = paramcount + 1
	end
	if paramcount == 0 or param[1] == 'help' or param[1] == '?' then
		displayHelp()
		return
	end
	local paramtwoall = ''
	if paramcount > 1 then
		paramtwoall = varargs[2]
		for i=3,paramcount,1 do paramtwoall = paramtwoall..' '..varargs[i] end
	end
	
	if param[1] == 'melee' or param[1] == 'ranged' or param[1] == 'both' then
		if param[1] == 'ranged' or param[1] == 'both' then
			recalculateRangedDelay(nil)
			if z_ranged_weapon == nil then
				param[1] = 'melee'
				windower.add_to_chat(17, 'Warning: No ranged weapon equipped. Starting in melee mode instead.')
			end
		end
		startAuto(param[1])
	elseif param[1] == 'ammo' then
		if paramcount == 1 then
			windower.add_to_chat(17, ' -- AutoSkill: Default ammunition is "' ..settings.ammunition_name..'"')
		else
			local ammoname = paramtwoall:lower()
			local invalid_ammo_type, foundammoname = false, false
			local items_searched = 0
			for itemid,iteminfo in pairs(res.items) do
				items_searched = items_searched + 1
				if iteminfo.enl == ammoname then
					if iteminfo.skill == nil then invalid_ammo_type = true; break; end
					local ammo_skill_name = res.skills[iteminfo.skill].en
					if ammo_skill_name ~= 'Archery' and ammo_skill_name ~= 'Marksmanship' and ammo_skill_name ~= 'Throwing' then 
						invalid_ammo_type = true; break; 
					end
					settings.ammunition_name = iteminfo.en
					settings.ammunition_id = itemid
					settings:save()
					windower.add_to_chat(17, '  -- AutoSkill: Saved "'..settings.ammunition_name..'" as default ammunition.')
					foundammoname = true
					break
				end
			end
			if invalid_ammo_type then
				windower.add_to_chat(17, ' -- AutoSkill Error: The "ammunition" specified was not for Archery/Marksmanship/Throwing.')
			elseif foundammoname == false then
				windower.add_to_chat(17, ' -- AutoSkill Error: Could not find ammunition with name "'..ammoname..'" in any of '..items_searched..' items searched.')
			end
		end
	elseif param[1] == 'stop' then
		stopAuto()
	elseif param[1] == 'buffs' then
		local player = windower.ffxi.get_player()
		windower.add_to_chat(17, 'Current Buffs: ' ..  table.tostring(player.buffs))
	elseif param[1] == 'stats' then
		displayStats()
	elseif param[1] == 'track' then
		if paramcount == 1 then
			local pos_str = 'posX='..settings.display.pos.x..' posY='..settings.display.pos.y
			if z_track_mode then
				z_track_mode = false
				windower.add_to_chat(17, ' -- AutoSkill: mob kill tracking is now off. '..pos_str)
			else
				z_track_mode = true
				windower.add_to_chat(17, ' -- AutoSkill: mob kill tracking is now on.'..pos_str)
			end
		elseif param[2] == 'reset' then
			settings.display.pos = {}
			settings.display.pos.x = 100
			settings.display.pos.y = 100
			settings:save()
			windower.add_to_chat(17, ' -- AutoSkill: tracking position reset.')
		end
	elseif param[1] == 'verbose' then
		if z_super_verbose then
			windower.add_to_chat(17, ' -- AutoSkill: super-verbose mode is off.')
			z_super_verbose = false
		else
			windower.add_to_chat(17, ' -- AutoSkill: super-verbose mode is ON.')
			z_super_verbose = true
		end
	elseif param[1] == 'sound' then
		if paramcount == 1 then
			windower.add_to_chat(17, ' -- AutoSkill: Sound notifications are set to: '..settings.sound_alert_toggle)
		elseif param[2] == 'on' then
			settings.sound_alert_toggle = 'on'
			settings:save()
			windower.add_to_chat(17, ' -- AutoSkill: Enabled sound notifications.')
		else
			settings.sound_alert_toggle = 'off'
			settings:save()
			windower.add_to_chat(17, ' -- AutoSkill: Disabled all sound notification.')
		end
	elseif param[1] == 'pausedrop' then
		z_pause_autodrop = not z_pause_autodrop
	elseif param[1] == 'drop' or param[1] == 'keep' then
		if paramcount == 1 then
			windower.add_to_chat(17, ' -- AutoSkill: specify the item name or id# that you want to always drop. Note: Please be careful with this.')
		else
			autoDropOrKeep(param[1], paramtwoall)
		end
	elseif param[1] == 'skills' then
		if paramcount == 1 then
			local pos_str = 'posX='..settings.skilldisplay.pos.x..' posY='..settings.skilldisplay.pos.y
			windower.add_to_chat(17, ' -- AutoSkill: Skill tracking set to: '..settings.tracking_skills..'. Use param "reset" to reset x,y position. '..pos_str)
		elseif param[2] == 'reset' then
			settings.skilldisplay.pos = {}
			settings.skilldisplay.pos.x = 100
			settings.skilldisplay.pos.y = 200
			settings:save()
			windower.add_to_chat(17, ' -- AutoSkill: Skill tracking position reset.')
		elseif param[2] == 'on' then
			settings.tracking_skills = 'on'
			settings:save()
			windower.add_to_chat(17, ' -- AutoSkill: Skill tracking enabled.')
			textbox_skills_reinitialize_function(z_textbox_skills, settings)
		else
			settings.tracking_skills = 'off'
			settings:save()
			windower.add_to_chat(17, ' -- AutoSkill: Skill tracking disabled.')
		end
	elseif param[1] == 'check' then
		isTargetEnemySkillable(true)
	elseif trackerCommand(param, paramcount, paramtwoall) then
		-- one of the tracker commands worked
	elseif skillCommand(param, paramcount, paramtwoall) then
		-- one of the SkillCap commands worked
	else
		windower.add_to_chat(100, ' -- AutoSkill Error: invalid argument command "'..param[1]..'"')
	end
end)

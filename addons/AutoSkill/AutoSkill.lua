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
res = require('resources')
config = require('config')
local texts = require('texts')
require('HelperMikeLuaLib')
require('HelperSkillCapData')
require('HelperSkillCapFunctions')

z_mobdata = {}
z_mobdata.nms = {}
z_mobdata.phs = {}
for i,zoneinfo in pairs(res.zones) do
	z_mobdata.nms[zoneinfo.search] = {}
	z_mobdata.phs[zoneinfo.search] = {}
end
require('HelperMobData')
require('HelperTracker')

-- TODO: change buffs, cure spells, and ability lists to use res.spells etc
-- TODO: change zoneid and nm/ph information to use strings

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
default_settings.plays_sounds = 'on'
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
default_settings.skilldisplay.text.stroke.width = 2
default_settings.skilldisplay.text.stroke.red   = 17
default_settings.skilldisplay.text.stroke.green = 28
default_settings.skilldisplay.text.stroke.blue  = 48
default_settings.skilldisplay.text.stroke.alpha = 255
default_settings.nms = {}
default_settings.nms['Leaping_Lizzy'] = {}
default_settings.nms['Leaping_Lizzy'].time_last_kill = 0
default_settings.nms['Leaping_Lizzy'].ph_kills = 0

settings = config.load(default_settings)
local z_default_color = ''
config.register(settings, function ()
	if settings.nm_scan_repeat ~= 0 and settings.nm_scan_repeat < 5 then settings.nm_scan_repeat = 5 end
	if settings.play_sounds ~= 'on' then settings.play_sounds = 'off' end
	if settings.tracking_skills ~= 'on' then 
		settings.tracking_skills = 'off'
	end
	z_default_color = '\\cs('..settings.display.text.red..','
	z_default_color = z_default_color..settings.display.text.green..','
	z_default_color = z_default_color..settings.display.text.blue..')'

end)

local z_page_tracker = {}
local z_mob_tracker = {}
local z_mob_tracker_kills = 0
local z_phnm_spawn_probability = 1
local z_skill_tracker = {}
local z_player = {}
z_player.level_sync = 0
z_player.skills = {}
local z_textbox_misc = texts.new(settings.display, settings)
local z_textbox_skills = texts.new(settings.skilldisplay, settings)

local MAX_LENGTH = 15
textbox_reinitialize_function = function(textbox, settings)
	local contents = L{}
	local elements = 0
	contents:append(string.padcenter('== AutoSkill ==', MAX_LENGTH+5))
	if table.size(z_page_tracker) > 0 then
		elements = elements + 1
		contents:append('Page status:')
		for mobname, trackdata in pairs(z_page_tracker) do
			local padded_name = string.padright(mobname, MAX_LENGTH)
			contents:append(padded_name..' ${pagea'..mobname..'}/${pageb'..mobname..'}')
		end
	end
	if table.size(z_mob_tracker) > 0 then
		elements = elements + 1
		contents:append('Mob deaths: '..z_mob_tracker_kills)
		if z_phnm_spawn_probability ~= 1 then
			contents:append('PH NM probability: '..string.format('%2.2f', (1-z_phnm_spawn_probability)*100)..'%')
		end
		for mobid, mob_data in pairs(z_mob_tracker) do
			contents:append(string.padright(mob_data.name, MAX_LENGTH)..' ${mobt'..mobid..'}s')
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
z_textbox_misc:register_event('reload', textbox_reinitialize_function)

textbox_skills_reinitialize_function = function(textbox, settings)
	--windower.add_to_chat(17, 'Skill text box='..settings.tracking_skills..' and size='..table.size(z_skill_tracker))
	if table.size(z_skill_tracker) == 0 or settings.tracking_skills == 'off' then
		textbox:clear()
		textbox:hide()
		return
	end

	local SKILL_PADDING = 12
	local contents = L{}
	-- TODO: smarter way to inject these but still enforce the desired order
	local templine = ''
	local subwepskill = ''
	local cappedprefix = '\\cs(128,128,128)'
	local cappedsuffix = '\\cr'

	-- TODO: create a key to reference main and sub directly, no for-loop needed
	for skillname, rating in pairs(JOB_WEAPON_RATINGS[z_player.mjtla]) do
		local key = SKILL_KEYS[skillname]
		if z_skill_tracker[key] ~= nil then
			if z_skill_tracker[key].type == 'main' then
				if z_skill_tracker[key].current == z_skill_tracker[key].cap then
					local paddedcap = z_skill_tracker[key].cap:string():lpad(' ', 3)
					templine = cappedprefix..skillname:rpad(' ', SKILL_PADDING).. ' '..paddedcap..' / '..paddedcap..cappedsuffix
				else
					templine = skillname:rpad(' ', SKILL_PADDING).. ' ${cur'..key..'} / ${cap'..key..'}'
				end
			else
				subwepskill = skillname
			end
		end
	end
	if subwepskill:len() > 0 then
		local subkey = SKILL_KEYS[subwepskill]
		-- TODO: finish engraining these values, they don't change very often
		--if z_skill_tracker[key].current == z_skill_tracker[key].cap then
		templine = templine..'   '..subwepskill:rpad(' ', SKILL_PADDING).. ' ${cur'..subkey..'} / ${cap'..subkey..'}'
	end
	if templine:len() > 0 then contents:append(templine) end
	
	if z_ranged_skilltype > 0 and JOB_RANGED_RATINGS[z_player.mjtla] ~= nil then
		local skillname = res.skills[z_ranged_skilltype].en
		local key = SKILL_KEYS[skillname]
		contents:append(skillname:rpad(' ', SKILL_PADDING).. ' ${cur'..key..'} / ${cap'..key..'}')
	end

	if JOB_MAGIC_RATINGS[z_player.mjtla] ~= nil then
		templine = ''
		for skillname, rating in pairs(JOB_MAGIC_RATINGS[z_player.mjtla]) do
			local key = SKILL_KEYS[skillname]
			if templine:len() == 0 then
				templine = skillname:rpad(' ', SKILL_PADDING).. ' ${cur'..key..'} / ${cap'..key..'}'
			else
				templine = templine..'   '..skillname:rpad(' ', SKILL_PADDING).. ' ${cur'..key..'} / ${cap'..key..'}'
				contents:append(templine)
				templine = ''
			end
		end
		if templine:len() > 0 then contents:append(templine) end
	end

	templine = ''
	for skillname, rating in pairs(JOB_DEFENSIVE_RATINGS[z_player.mjtla]) do
		local key = SKILL_KEYS[skillname]
		if templine:len() == 0 then
			templine = skillname:rpad(' ', SKILL_PADDING)..' ${cur'..key..'} / ${cap'..key..'}'
		else
			templine = templine..'   '..skillname:rpad(' ', SKILL_PADDING).. ' ${cur'..key..'} / ${cap'..key..'}'
			contents:append(templine)
			templine = ''
		end
	end
	if templine:len() > 0 then contents:append(templine) end

	textbox:clear()
	textbox:append(contents:concat('\n'))
	textbox:show()
end
z_textbox_skills:register_event('reload', textbox_skills_reinitialize_function)

windower.register_event('prerender', function()
	local data = {}
	if table.size(z_page_tracker) > 0 then
		for mobname, trackdata in pairs(z_page_tracker) do
			local colorprefix = ''
			local colorpostfix = ''
			if trackdata.progress == trackdata.needed then
				colorprefix = '\\cs(128,128,128)'
				colorpostfix = '\\cr'
			end
			data['pagea'..mobname] = colorprefix..trackdata.progress
			data['pageb'..mobname] = trackdata.needed..colorpostfix
		end
	end
	if table.size(z_mob_tracker) > 0 then
		local curtime = os.time()
		local removemobs = {}
		data.mobkills = z_mob_tracker_kills
		for mobid, mob_data in pairs(z_mob_tracker) do
			local colorprefix = ''
			local colorpostfix = ''
			local remaining_time = z_mob_tracker[mobid].respawn - curtime
			if remaining_time < 10 then
				colorprefix = '\\cs(255,200,200)'
				colorpostfix = '\\cr'
			end
			if remaining_time > 0 then
				data['mobt'..mobid] = colorprefix..remaining_time:string():lpad(' ', 3)..colorpostfix
			else
				table.insert(removemobs, mobid)
			end
		end
		for i,mobid in ipairs(removemobs) do
			z_mob_tracker[mobid] = nil
		end
		if table.getn(removemobs) > 0 then textbox_reinitialize_function(z_textbox_misc, settings) end
	end
	z_textbox_misc:update(data)

	if table.size(z_skill_tracker) > 0 and settings.tracking_skills == 'on' then
		-- red 53, green 140, blue 196
		-- red 17, green 28, blue 48
		local data = {}
		local capcolor = '\\cs(53,140,196)'
		for key, skilldata in pairs(z_skill_tracker) do
			local colorprefix = ''
			local colorpostfix = ''
			if skilldata.current == skilldata.cap then
				colorprefix = capcolor
				colorpostfix = '\\cr'
			end
			if skilldata.current == nil then skilldata.current = -98 end
			if skilldata.cap == nil then skilldata.cap = -99 end
			data['cur'..key] = colorprefix..(skilldata.current):string():lpad(' ', 3)
			data['cap'..key] = (skilldata.cap):string():lpad(' ', 3)..colorpostfix
		end
		z_textbox_skills:update(data)
	end
end)

windower.register_event('load', function ()
	regid_action = nil
	z_locked_target_id = 0
	resetAllStats()
	z_track_mode = true
	z_super_verbose = false
	z_operational_mode = {}
	z_paused = true
	z_latest_status = 'Unknown'

	EQUIPMENT_AMMO_SLOT = nil
	for slotindex, slotdata in pairs(res.slots) do
		if slotdata.en =='Ammo' then EQUIPMENT_AMMO_SLOT = slotdata.id end
	end
	--periodicNMScan()
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

function recalculateRangedDelay()
	z_ranged_delay = 0

	local gear = windower.ffxi.get_items()['equipment']
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
		windower.add_to_chat(100, 'Player has ' ..z_ammo_count..' ammo of type '..z_ammo_type..' in bag='..z_ammo_bag)
	else
		-- ammo slot is empty, default the ammo type to what's saved/preferred instead of equipped
		z_ammo_type = settings.ammunition_id
	end
end

function recalculateWeaponry()
	local effective_level = z_player.mjlvl
	if z_player.level_sync ~= 0 and z_player.level_sync < z_player.mjlvl then effective_level = z_player.level_sync end
	z_skill_tracker = {}
	local gear = windower.ffxi.get_items()['equipment']
	--windower.add_to_chat(17, 'error finding thingy, player skill dump: '..table.tostring(z_player.skills))
	if gear.main > 0 then -- check if main weapon exists, pull it's information
		local mainweapon_info = windower.ffxi.get_items(gear.main_bag, gear.main)
		if mainweapon_info ~= nil then
			local mainwepskillname = res.skills[res.items[mainweapon_info.id].skill].en
			local mainkey = SKILL_KEYS[mainwepskillname]
			if z_player.skills[mainkey] ~= nil then
				z_skill_tracker[mainkey] = {}
				z_skill_tracker[mainkey].type = 'main'
				z_skill_tracker[mainkey].current = z_player.skills[mainkey]
				z_skill_tracker[mainkey].cap = getSkillCapFor(z_player.mjtla, effective_level, mainwepskillname)
			else
				windower.add_to_chat(17, 'error finding thingy, player skill dump: '..table.tostring(z_player.skills))
			end
			
			if gear.sub > 0 then -- if main hand exists, maybe offhand? attempt to pull sub weapon information
				local subweapon_info = windower.ffxi.get_items(gear.sub_bag, gear.sub)
				--if subweapon_info ~= nil then
				local subwepskillname = res.skills[res.items[subweapon_info.id].skill].en
				local subkey = SKILL_KEYS[subwepskillname]
				if mainwepskillname ~= subwepskillname then
					z_skill_tracker[subkey] = {}
					z_skill_tracker[subkey].type = 'sub'
					z_skill_tracker[subkey].current = z_player.skills[subkey]
					z_skill_tracker[subkey].cap = getSkillCapFor(z_player.mjtla, effective_level, subwepskillname)
				end
			end
		else
			windower.add_to_chat(17, 'Main hand contained index='..gear.main..' but weapon_info could not be found.')
		end
	elseif JOB_WEAPON_RATINGS[z_player.mjtla]['Hand-to-Hand'] ~= nil then -- no main weapon, h2h skill?
		local key = 'hand_to_hand'
		z_skill_tracker[key] = {}
		z_skill_tracker[key].type = 'main'
		z_skill_tracker[key].current = z_player.skills[key]
		z_skill_tracker[key].cap = getSkillCapFor(z_player.mjtla, effective_level, 'Hand-to-Hand')
	end

	-- computer ranged weapon's ammunition and skill mode
	recalculateRangedDelay()
	if z_ranged_skilltype > 0 then
		local rangeskillname = res.skills[z_ranged_skilltype].en
		local key = SKILL_KEYS[rangeskillname]
		z_skill_tracker[key] = {}
		z_skill_tracker[key].current = z_player.skills[key]
		z_skill_tracker[key].cap = getSkillCapFor(z_player.mjtla, effective_level, rangeskillname)
	end
	if JOB_MAGIC_RATINGS[z_player.mjtla] ~= nil then -- sparse table, not all jobs
		for magname, rating in pairs(JOB_MAGIC_RATINGS[z_player.mjtla]) do
			local key = SKILL_KEYS[magname]
			z_skill_tracker[key] = {}
			z_skill_tracker[key].current = z_player.skills[key]
			z_skill_tracker[key].cap = getSkillCapFor(z_player.mjtla, effective_level, magname)
		end
	end
	for defname, rating in pairs(JOB_DEFENSIVE_RATINGS[z_player.mjtla]) do
		local key = SKILL_KEYS[defname]
		z_skill_tracker[key] = {}
		z_skill_tracker[key].current = z_player.skills[key]
		z_skill_tracker[key].cap = getSkillCapFor(z_player.mjtla, effective_level, defname)
	end
	textbox_skills_reinitialize_function(z_textbox_skills, settings)
end

function recalculateVitals()
	windower.add_to_chat(100, ' =========== Recalculating vitals.')
	local player = windower.ffxi.get_player()
	
	z_player.hp    = player.vitals['hp']
	z_player.maxhp = player.vitals['max_hp']
	z_player.mp    = player.vitals['mp']
	z_player.maxmp = player.vitals['max_mp']
	z_player.tp    = player.vitals['tp']
	z_player.jobs = {}
	z_player.jobs[player.main_job_id] = player.main_job_level
	z_player.mjtla = res.jobs[player.main_job_id].ens
	z_player.mjlvl = player.main_job_level
	if player.sub_job_id ~= nil then 
	    z_player.jobs[player.sub_job_id] = player.sub_job_level
		z_player.sjtla = res.jobs[player.sub_job_id].ens
	end

	-- copy the skills table, don't just assign a reference which can go out of date
	for k,v in pairs(player.skills) do
		z_player.skills[k] = v
	end
	recalculateWeaponry()

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

local function playSoundEffect(sound_file)
	if settings.plays_sounds then
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
		recalculateWeaponry()
	end
end)

windower.register_event('job change', function (main_job_id, main_job_level, sub_job_id, sub_job_level)
	coroutine.schedule(resetAllStats, 8)
end)

windower.register_event('level up', function (level)
	if z_player.level_sync >= level then
		coroutine.schedule(recalculateVitals, 8)
	end
end)

windower.register_event('level down', function (level)
	coroutine.schedule(recalculateVitals, 8)
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
	windower.add_to_chat(17, 'actor_id='..actor_id..' target_id='..target_id..'  target_index='..target_index..' message_id='..message_id..' param1='..param_1..' param2='..param_2..' param3='..param_3)
end

local z_candidate_mob_page_entries = {}
local z_reading_mob_kill_list = false
on_incomingtext_function = function (original, modified, orig_mode, mod_mode, blocked)
	--if original:find('training regime register') ~= nil then
	--	local fulldata = {original:byte(1, original:len())}
	--	local strdata = ''
	--	for i,v in ipairs(fulldata) do 
	--		strdata = strdata..v..' '
	--	end
	--	windower.add_to_chat(17, 'found, strlen is '..original:len()..' om='..orig_mode..' mm='..mod_mode..' -- and the codes are: '..strdata)
	--	return false
	--end
	
	local is_page_finalized = false
	if orig_mode == 141 then
		local original_length = original:len()
		if original_length == 86 and original:sub(3,84) == "Changing your job will result in the cancellation of your current training regime." then
			-- clear the book page (not, might be a color code in here?)
			z_page_tracker = {}
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
					z_candidate_mob_page_entries[mobname] = {}
					z_candidate_mob_page_entries[mobname].progress = amount
					z_candidate_mob_page_entries[mobname].needed = max
					z_candidate_mob_page_entries[mobname].is_family = is_family
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

	if is_page_finalized and table.size(z_candidate_mob_page_entries) > 0 then
		z_page_tracker = {}
		for mobname, pagedata in pairs(z_candidate_mob_page_entries) do
			z_page_tracker[mobname] = {}
			z_page_tracker[mobname].progress = pagedata.progress
			z_page_tracker[mobname].needed = pagedata.needed
			z_page_tracker[mobname].is_family = pagedata.is_family
		end
		textbox_reinitialize_function(z_textbox_misc, settings)
		z_candidate_mob_page_entries = {}
	end
--
--	if z_super_verbose and original:sub(1, 7) ~= 'VERBOSE' then
--		local blockstr = blocked and 'true' or 'false'
--		windower.add_to_chat(17, 'VERBOSE: om='..orig_mode..' mm='..mod_mode..' block='..blockstr.. ' -- orig: "'..original..'"')
--		return true
--	end
--	return false
end
windower.register_event('incoming text', on_incomingtext_function)

local z_most_recent_kill_id = 0
windower.register_event('action message', function(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	if z_super_verbose then
		windower.add_to_chat(17, 'messsage in verbose mode:')
		verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
		return
	end

	if message_id == 5 then -- Unable to see <target>.
		verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	elseif message_id == 6 then -- <actor> defeats <target>.
		z_most_recent_kill_id = target_id
		if z_track_mode then
			local respawn_time = 330 -- about 5 1/2 minutes by default
			local curzone = res.zones[windower.ffxi.get_info().zone].search
			local mob_data = windower.ffxi.get_mob_by_id(target_id)
			--z_ph_info[target_id].last_death = os.time()
			z_mob_tracker[target_id] = {}
			z_mob_tracker[target_id].name = mob_data.name
			if z_mobdata.phs[curzone][target_id] ~= nil then 
				if curzone == 'Oztroja' then respawn_time = 792 end
				z_phnm_spawn_probability = z_phnm_spawn_probability * 0.95
			elseif z_mobdata.nms[curzone][target_id] ~= nil then
				z_phnm_spawn_probability = 1
				respawn_time = z_mobdata.nms[curzone][target_id].respawn_minimum
			end
			z_mob_tracker[target_id].respawn = os.time() + respawn_time
			z_mob_tracker_kills = z_mob_tracker_kills + 1
			textbox_reinitialize_function(z_textbox_misc, settings)
		end
		verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	elseif message_id == 38 then --	<target>'s <skill> skill rises 0.<number> points.
		if z_skill_tracker[SKILL_KEYS[param_1]] == nil then -- got a skill up on a weapon we weren't tracking, must have changed gear
			recalculateWeaponry()
		end
	elseif message_id == 53 then -- <target>'s <skill> skill reaches level <number>.
		if z_skill_tracker[SKILL_KEYS[param_1]] == nil then -- must have changed weapons?
			recalculateWeaponry()
		else -- update the skill listing
			z_skill_tracker[SKILL_KEYS[param_1]].current = param_2
		end
	elseif message_id == 101 then -- <actor> uses <weapon_skill>.
		if actor_id == z_player_id then
			LAST_ACTION_TICK = os.time() + 2
		end
	elseif message_id == 216 then -- You do not have an appropriate ranged weapon equipped.
		if z_operational_mode['ranged'] then
			tryEquipMoreAmmo()
		end
	elseif message_id == 249 then -- /check gave "is impossible to guage!"
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
	elseif message_id == 525 then -- <ability> can only be performed during battle.
		verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
		playSoundEffect(settings.sound_files.alert)
	elseif message_id == 540 then -- Level Sync activated. Your level has been restricted to <number>. Equipment affected by the level restriction will be adjusted accordingly. Experience points will become unavailable for all party members should the Level Sync designee stray too far from the enemy.
		verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
		z_player.level_sync = param_2
		coroutine.schedule(recalculateVitals, 8)
	elseif message_id == 558 then -- You defeated a designated target. (Progress: <number>/<number>)
		if z_most_recent_kill_id ~= 0 then
			local mob_data = windower.ffxi.get_mob_by_id(z_most_recent_kill_id)
			local entry_name = mob_data.name
			if z_page_tracker[mob_data.name] == nil then
				for pagename,pagedata in pairs(z_page_tracker) do
					if pagename:len() > entry_name:len() and pagename:sub(1,entry_name:len()) == entry_name then
						-- something like Werebat instead of Werebats, this was close enough
						entry_name = pagename
						break
					end
					if pagedata.is_family and pagedata.needed == param_2 and pagedata.progress + 1 == param_1 then
						-- here, we're guessing. we found a mob family, a kill progress message that matched
						-- but we have no clue if they really are the same entry.
						-- We'll keep looking, just in case. If we find an exact match after this, we'll quit and use that instead.
						entry_name = pagename
					end
				end
				if z_page_tracker[entry_name] == nil then -- still couldn't find it, start a new entry
					z_page_tracker[entry_name] = {}
					z_page_tracker[entry_name].needed = param_2
				end
				textbox_reinitialize_function(z_textbox_misc, settings)
			end
			z_page_tracker[entry_name].progress = param_1
			z_most_recent_kill_id = 0
		else -- We missed the kill message. Are we able to guess?
			windower.add_to_chat(100, ' -- AutoSkill error: page completion message with no kill message?')
			local candidate = ''
			local possible = 0
			for pagename,pagedata in pairs(z_page_tracker) do
				if pagedata.needed == param_2 and pagedata.progress + 1 == param_1 then
					candidate = pagename
					possible = possible + 1
				end
			end
			if possible == 1 then
				z_page_tracker[candidate].progress = param_1
			end
		end
		verboseActionMessage(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
	elseif message_id == 559 then -- You have successfully completed the training regime.
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
		if settings.plays_sounds then
			local files = {}
			for key,name in pairs(settings.sound_files.book_complete) do table.insert(files, name) end
			playSoundEffect(files[math.random(table.getn(files))])
		end
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
	if table.isnotempty(z_mobdata.phs[zonestr]) then zonephcount = table.size(settings.mob_ids.placeholders[zoneidstr]) end
	if table.isnotempty(z_mobdata.nms[zonestr]) then zonenmcount = table.size(settings.mob_ids.nms[zoneidstr]) end
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
		paramtwoall =varargs[2]
		for i=3,paramcount,1 do paramtwoall = paramtwoall..' '..varargs[i] end
	end
	
	if param[1] == 'melee' or param[1] == 'ranged' or param[1] == 'both' then
		if param[1] == 'ranged' or param[1] == 'both' then
			recalculateRangedDelay()
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
			textbox_skills_reinitialize_function(z_textbox_skills, settings)
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

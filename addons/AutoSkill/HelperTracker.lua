require('HelperMobData.lua')

windower.register_event('target change',  function (target_index)
	if target_index == 0 or target_index == 1024 then return end -- nothing or self
	local zoneidstr = tostring(windower.ffxi.get_info().zone)
	if table.isempty(settings.mob_ids.placeholders[zoneidstr]) then return end

	local mob_data = windower.ffxi.get_mob_by_index(target_index)
	local mobidstr = tostring(mob_data.id)
	for i,v in pairs(mobdata.phs[zoneidstr]) do
		if mobidstr == i then
			windower.add_to_chat(17, ' -- '..mob_data.name..' id='..mobidstr..' is a placeholder for '..v)
			return
		end
	end
end)


LAST_PACKET_TICK = 0
INJECTED_PACKETS = {}
BLOCKED_PACKETS = {}
REGULAR_PACKETS = {}
EXAMPLE_PACKET = {}
on_incomingchunk_function = function (id, original, modified, injected, blocked)
	local msg = nil
	if injected == true then
		if INJECTED_PACKETS[id] == nil then INJECTED_PACKETS[id] = 0 end
		INJECTED_PACKETS[id] = INJECTED_PACKETS[id] + 1
		msg = 'Received an injected packet with id='..id
	elseif blocked == true then
		if BLOCKED_PACKETS[id] == nil then BLOCKED_PACKETS[id] = 0 end
		BLOCKED_PACKETS[id] = BLOCKED_PACKETS[id] + 1
		msg = 'Received a blocked packet with id='..id
	else
		if REGULAR_PACKETS[id] == nil then 
			REGULAR_PACKETS[id] = 0
			EXAMPLE_PACKET[id] = original
		end
		REGULAR_PACKETS[id] = REGULAR_PACKETS[id] + 1
		msg = 'New packet id='..id..' contents='..original
	end
	--curtime = os.time()
	--if msg ~= nil and curtime > LAST_PACKET_TICK then
	--	windower.add_to_chat(100, msg)
	--	LAST_PACKET_TICK = curtime+10
	--end
	return false
end
--windower.register_event('incoming chunk', on_incomingchunk_function)

function displayPackets()
	local injected = 0
	for k,v in pairs(INJECTED_PACKETS) do
		injected = injected + v
	end
	local blocked = 0
	for k,v in pairs(BLOCKED_PACKETS) do
		blocked = blocked + v
	end
	local regular = 0
	local highest_id = 0
	local highest_regular = 0
	for k,v in pairs(REGULAR_PACKETS) do
		regular = regular + v
		if v > highest_regular then
			highest_id = k
			highest_regular = v
		end
	end
	windower.add_to_chat(100, 'There were '..blocked..' blocked packets, '..injected..' injected packets, and '..regular..' regular packets.')
	--windower.add_to_chat(100, 'packet id type='..highest_id..' was the most common with '..highest_regular)
	for k,v in pairs(REGULAR_PACKETS) do
		windower.add_to_chat(100, 'packet id type='..k..' has had num packets='..v)
	end
end

z_last_nm_scan = 0
z_next_scheduled_scan = 0
function periodicNMScan()
	local curtime = os.time()
	z_last_nm_scan = curtime
	z_next_scheduled_scan = 0
	if type(settings.nm_scan_repeat) ~= 'number' then
		windower.add_to_chat(17, 'Warning: NM scanner frequency setting was missing/invalid. Defaulted to "off".')
		settings.nm_scan_repeat = 0
		settings:save()
		return
	elseif settings.nm_scan_repeat == 0 then
		return
	end

	local zoneidstr = tostring(windower.ffxi.get_info().zone)
	if table.isempty(settings.mob_ids.nms[zoneidstr]) then return end
	local found_something = false
	for k,v in pairs(settings.mob_ids.nms[zoneidstr]) do
		local mob_data = windower.ffxi.get_mob_by_id(tonumber(k))
		if mob_data ~= nil and mob_data.valid_target then
			found_something = true
			windower.add_to_chat(17, 'Found NM: '..mob_data.name..' distance='..math.sqrt(mob_data.distance))
		end
	end
	if found_something then playSoundEffect(settings.sound_files.alert) end

	z_next_scheduled_scan = curtime + settings.nm_scan_repeat
	coroutine.schedule(periodicNMScan, settings.nm_scan_repeat)
end

function trackerCommand(param, paramcount, paramtwoall)
	if param[1] == 'help' then
	elseif param[1] == 'addph' then
		local zoneidstr = tostring(windower.ffxi.get_info().zone)
		if settings.mob_ids.placeholders[zoneidstr] == nil then settings.mob_ids.placeholders[zoneidstr] = {} end
		local mob_data = windower.ffxi.get_mob_by_target('t')
		local mobidstr = tostring(mob_data.id)
		settings.mob_ids.placeholders[zoneidstr][mobidstr] = paramtwoall
		settings:save()
		windower.add_to_chat(100, 'Placeholder '..mob_data.name..'('..mobidstr..') recorded to spawn NM '..paramtwoall)
		return true
	elseif param[1] == 'addnm' then
		local zoneidstr = tostring(windower.ffxi.get_info().zone)
		if settings.mob_ids.nms[zoneidstr] == nil then settings.mob_ids.nms[zoneidstr] = {} end
		local mob_data = windower.ffxi.get_mob_by_target('t')
		if mob_data ~= nil then
			local mobidstr = tostring(mob_data.id)
			if settings.mob_ids.nms[zoneidstr][mobidstr] ~= nil then
				windower.add_to_chat(100, 'NM was already saved.')
			else
				settings.mob_ids.nms[zoneidstr][mobidstr] = mob_data.name
				settings:save()
				windower.add_to_chat(100, 'NM added and saved to persistent settings.')
			end
		else
			windower.add_to_chat(100, 'Error: Target invalid.')
		end
		return true
	elseif param[1] == 'scan' then
		if paramcount == 1 then
			if settings.nm_scan_repeat == 0 then
				windower.add_to_chat(17, ' -- AutoSkill: NM scanner is currently off.')
			else
				local nextscanin = ''
				local curtime = os.time()
				local tdiff = z_next_scheduled_scan - curtime
				if tdiff > 0 then nextscanin = ' -- next scan in '..tdiff..' seconds.' end
				windower.add_to_chat(17, ' -- AutoSkill: current scan frequency is set to '..settings.nm_scan_repeat..' seconds'..nextscanin)
			end
		else
			local freqval = tonumber(param[2])
			if freqval == nil then freqval = 0 end
			if freqval == 0 then
				windower.add_to_chat(17, ' -- AutoSkill: NM scanner is now disabled.')
			else
				if freqval < 5 then freqval = 5 end
				windower.add_to_chat(17, 'NM scan frequency set to '..freqval..' seconds.')
			end
			settings.nm_scan_repeat = freqval
			settings:save()
			if z_next_scheduled_scan == 0 and freqval > 0 then periodicNMScan() end
		end
		return true
	elseif param[1] == 'packets' then
		displayPackets()
		return true
	elseif param[1] == 'packet' then
		if EXAMPLE_PACKET[param[2]] ~= nil then
			windower.add_to_chat(100, 'Packet example: '..EXAMPLE_PACKET[param[2]])
		end
		return true
	end
	return false
end
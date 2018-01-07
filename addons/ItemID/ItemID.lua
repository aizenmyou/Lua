-- DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
--                   Version 2, December 2004
--License Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
--Everyone is permitted to copy and distribute verbatim or modified
--copies of this license document, and changing it is allowed as long
--as the name is changed.
--
--           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
--  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
--
-- 0. You just DO WHAT THE FUCK YOU WANT TO.
 
 _addon.name = 'ItemID'
_addon.version = '0.1'
_addon.author = 'freeZerg'
_addon.commands = {'itemid','iid'}

res = require('resources')

windower.register_event('addon command',function (...)
	local varargs = {...}
	local param = {}
	local param_count = 0
	local param_all = ''
	for i,v in ipairs(varargs) do
		table.insert(param, tonumber(v) or v:lower())
		param_count = param_count + 1
		if param_all:len() > 0 then param_all = param_all..' ' end
		param_all = param_all..v
	end
	
	if param_count == 0 then
		windower.add_to_chat(17, ' -- Specify an item ID or an item name. Ie. //iid arrow    or  //iid jujitsu')
		return
	end

	-- gave a number, examine as an Item ID
	if type(param[1]) == 'number' then
		if res.items[param[1]] ~= nil then
			windower.add_to_chat(17, ' -- Item ID='..param[1]..' name='..res.items[param[1]].en..' -- enl='..res.items[param[1]].enl)
		else
			windower.add_to_chat(17, ' -- Item with index/ID='..param[1]..' was not found.')
		end
		return
	end
	
	-- not a number, examine all items for a string or substring match
	local itemname = param_all:lower()
	local total_searched = 0
	local candidate_id = {}
	for itemid,itemdata in pairs(res.items) do
		local en = itemdata.en:lower()
		local enl= itemdata.enl:lower()
		if en:find(itemname) ~= nil then
			table.insert(candidate_id, itemid)
		elseif enl:find(itemname) ~= nil then
			table.insert(candidate_id, itemid)
		end
		total_searched = total_searched + 1
	end
	local results = table.getn(candidate_id)
	if results == 0 then
		windower.add_to_chat(17, ' -- Item with name="'..itemname..'" was not found in '..total_searched..' items searched.')
	elseif results == 1 then
		windower.add_to_chat(17, ' -- Item ID='..candidate_id[1]..' name='..res.items[candidate_id[1]].en..' -- enl='..res.items[candidate_id[1]].enl)
	else
		windower.add_to_chat(17, ' -- Item candidates found: '..results)
		local display_count = 0
		local idpadding = 0
		local namepadding = 0
		for i,id in ipairs(candidate_id) do
			windower.add_to_chat(17, '  id='..id..' name='..res.items[id].en..' -- enl='..res.items[id].enl)
			display_count = display_count + 1
			if display_count >= 10 then
				windower.add_to_chat(17, ' -- Note: Too many results. (Stopped after the first ten.)')
				break
			end
		end
	end
end)

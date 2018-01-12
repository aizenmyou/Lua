--           DWTFYWT PUBLIC LICENSE
--  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
--
-- 1. You just DO WHAT THE FUCK YOU WANT TO.

_addon.name = 'ItemID'
_addon.version = '0.2'
_addon.author = 'freeZerg'
_addon.commands = {'itemid','iid'}

res = require('resources')

function display_item(id)
	windower.add_to_chat(100, 'Found Item ID='..id..' name="'..res.items[id].en..'" -- enl="'..res.items[id].enl..'" with the following description:')
	windower.add_to_chat(100, res.item_descriptions[id].en)
end

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
		windower.add_to_chat(100, ' -- Specify an item ID or an item name. Ie. //iid arrow    or  //iid jujitsu')
		return
	end

	-- gave a number, examine as an Item ID
	if type(param[1]) == 'number' then
		if res.items[param[1]] ~= nil then
			display_item(param[1])
		else
			windower.add_to_chat(100, ' -- Item with index/ID='..param[1]..' was not found.')
		end
		return
	end
	
	-- not a number, examine all items for a string or substring match
	local itemname = param_all:lower()
	local results, total_searched = 0, 0
	local candidate_id = {}
	for itemid,itemdata in pairs(res.items) do
		local en = itemdata.en:lower()
		local enl = itemdata.enl:lower()
		if en:find(itemname) ~= nil or enl:find(itemname) ~= nil then
			if en == itemname or enl == itemname then
				table.insert(candidate_id, 1, itemid) -- inject to the top of the candidate list
			elseif results < 10 then
				table.insert(candidate_id, itemid)
			end
			results = results + 1
		end
		total_searched = total_searched + 1
	end
	if results == 0 then
		windower.add_to_chat(100, ' -- Item with name="'..itemname..'" was not found in '..total_searched..' items searched.')
	elseif results == 1 then
		display_item(candidate_id[1])
	else
		local too_many_note = (table.getn(candidate_id) > 10) and ' Note: Too many results; displaying the first ten.' or ''
		windower.add_to_chat(100, 'Item candidates found: '..results..' of '..total_searched..' items searched had a partial match.'..too_many_note)
		local display_count = 0
		local idpadding = 0
		local namepadding = 0
		for i,id in ipairs(candidate_id) do
			local exact_match = (res.items[id].en == itemname or res.items[id].enl == itemname) and '     (EXACT MATCH) ' or ''
			windower.add_to_chat(100, 'id='..id..' name='..res.items[id].en..' -- enl='..res.items[id].enl..exact_match)
			display_count = display_count + 1
			if display_count >= 10 then break end
		end
	end
end)

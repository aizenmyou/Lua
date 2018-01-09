function npairs(tbl)
	if tbl == nil then return pairs({}) end
	return pairs(tbl)
end

function table.val_to_str(v)
	if "string" == type(v) then
		v = string.gsub(v, '\n', '\\n')
		if string.match(string.gsub(v, "[^'\"]",""), '^"+$') then
			return "'"..v.."'"
		end
		return '"'..string.gsub(v,'"', '\\"')..'"'
	else
		return "table" == type(v) and table.tostring(v) or tostring(v)
	end
end

function table.key_to_str(k)
	if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
		return k
	else
		return "["..table.val_to_str(k).."]"
	end
end

function table.tostring(tbl)
	local result, done = {}, {}
	for k, v in ipairs(tbl) do
		table.insert(result, table.val_to_str(v))
		done[k] = true
	end
	for k, v in pairs(tbl) do
		if not done[k] then
			table.insert(result, table.key_to_str(k).."="..table.val_to_str(v))
		end
	end
	return "{"..table.concat(result, ",").."}"
end

function table.size(tbl)
	local count = 0
	for k,v in pairs(tbl) do count = count + 1 end
	return count
end

function table.isempty(tbl)
	if tbl == nil then return true end
	for k,v in pairs(tbl) do return false end
	return true
end

function table.isnotempty(tbl)
	if table.isempty(tbl) then return false end
	return true
end
--function string:padleft(max_len)
--	local len = self:len()
--	if len >= max_len then return self:sub(1, max_len) end
--	return ' ':rep(max_len - len)..self
--end
--function string.padleft(str, max_len)
--	return str:padleft(max_len)
--end
function string.padleft(str, max_len)
	local len = str:len()
	if len >= max_len then return str:sub(1, max_len) end
	return ' ':rep(max_len - len)..str
end

function string.padright(str, max_len)
	local len = str:len()
	if len == nil or max_len == nil then
		windower.add_to_chat(17, ' -- nil catch in string.padright: '..debug.traceback())
		return '0xBAADF00D'
	end

	if len >= max_len then return str:sub(1, max_len) end
	return str..' ':rep(max_len - len)
end

function string.padcenter(str, max_len)
	local len = str:len()
	if len >= max_len then return str:sub(1, max_len) end
	local leftpad = math.floor((max_len - len) / 2)
	return ' ':rep(leftpad)..str..' ':rep(max_len - (len + leftpad))
end

function string.toluakey(str)
	return str:lower():gsub('[ -]', '_')
end
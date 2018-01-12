local default_map = {
    ['Alt+1']  = 'input /map',
}

local player_data = windower.ffxi.get_player()
local mjlvl = player_data.main_job_level

if player_data.sub_job_id ~= nil then 
	local res = require('resources')
	local sjlvl = player_data.sub_job_level
	local sjtla = res.jobs[player_data.sub_job_id].ens
end

return default_map

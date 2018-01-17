local default_map = {
    ['Ctrl+5'] = 'input /ja "Repair" <me>',
    ['Ctrl+6'] = 'input /ja "Maintenance" <me>',
    ['Ctrl+7'] = 'input /ja "Activate" <me>',
    ['Ctrl+8'] = 'input /ja "Deus Ex Automata" <me>',
    ['Ctrl+9'] = 'input /checkparam <pet>',
    ['Ctrl+0'] = 'cancel Sneak;cancel Invisible;input /ja "Spectral Jig" <me>',
    ['Alt+1']  = 'input /map',
    ['Alt+2']  = 'input /pet "Deploy" <t>',
    ['Alt+3']  = 'input /pet "Retrieve" <me>',
    ['Alt+4']  = '',
    ['Alt+5']  = 'input /pet "Deactivate" <me>',
    ['Alt+6']  = '',
    ['Alt+7']  = 'input //maneuver',
    ['Alt+8']  = 'input //flman10',
    ['Alt+9']  = 'input //pupcure10',
    ['Alt+0']  = 'input //stopall',
}

local player_data = windower.ffxi.get_player()
local mjlvl = player_data.main_job_level
if player_data.sub_job_id ~= nil then 
	local res = require('resources')
	local sjlvl = player_data.sub_job_level
	local sjtla = res.jobs[player_data.sub_job_id].ens
	if sjtla == 'DNC' then 
		if sjlvl >= 35 then
			default_map['Ctrl+1'] = 'input /ja "Drain Samba II" <me>'
		elseif sjlvl >= 5 then
			default_map['Ctrl+1'] = 'input /ja "Drain Samba" <me>'
		end

		if sjlvl >= 15 then default_map['Ctrl+2'] = 'input /ja "Curing Waltz" <stpc>' end
		if sjlvl >= 30 then default_map['Ctrl+3'] = 'input /ja "Curing Waltz II" <stpc>' end
		if sjlvl >= 25 then default_map['Ctrl+4'] = 'input /ja "Divine Waltz" <me>' end
		
	end
end

return default_map

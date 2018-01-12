local default_map = {
	['Ctrl+7'] = '', -- reserved for AutoSkill reload but I don't want it tied to Yush working or not
	['Ctrl+8'] = 'input /ja "Flee" <me>',
	['Ctrl+9'] = 'input /ja "Hide" <me>',
	['Ctrl+0'] = 'cancel Sneak;cancel Invisible;input /ja "Spectral Jig" <me>',
	['Alt+1']  = 'input /map',
	['Alt+2']  = 'input /ja "Sneak Attack" <me>',
	['Alt+3']  = 'input /ja "Trick Attack" <me>',
	--['Ctrl+5'] = 'input //gs c SAWS',
	['Alt+6']  = 'input /ja "Quickstep" <me>',
	['Alt+7']  = 'input /ja "Box Step" <me>',
	['Alt+9']  = 'input /ra <t>',
	['Alt+0']  = 'input /ra <t>',
}

local player_data = windower.ffxi.get_player()
local mjlvl = player_data.main_job_level

if mjlvl >= 60 then 
	default_map['Alt+4']  = 'input /ws "Dancing Edge" <t>'
elseif mjlvl >= 33 then 
	default_map['Alt+4']  = 'input /ws "Viper Bite" <t>'
else
	default_map['Alt+4']  = 'input /ws "Wasp Sting" <t>'
end

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

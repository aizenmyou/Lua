local default_map = {
	['Ctrl+1'] = 'input /ja "Drain Samba" <me>',
    ['Ctrl+2'] = 'input /ja "Curing Waltz" <stpc>',
    ['Ctrl+3'] = 'input /ja "Curing Waltz II" <stpc>',
    ['Ctrl+4'] = 'input /ja "Divine Waltz" <me>',
    ['Ctrl+5'] = 'input /ja "Curing Waltz III" <stpc>',
    ['Ctrl+6'] = 'input /ja "Haste Samba" <me>',
    ['Ctrl+7'] = 'input /ja "Aspir Samba" <me>',
    ['Ctrl+8'] = 'input /ja "Healing Waltz" <stpc>',
    ['Ctrl+0'] = 'cancel Sneak;cancel Invisible;input /ja "Spectral Jig" <me>',
    --['Ctrl+5'] = 'input //gs c SAWS',
    ['Alt+1']  = 'input /map',
    ['Alt+3']  = 'input /ja "Box Step" <t>',
    ['Alt+4']  = 'input /ja "Quickstep" <t>',
    ['Alt+5']  = 'input /ja "Stutter Step" <t>',
    ['Alt+7']  = 'input /ja "Reverse Flourish" <me>',
    ['Alt+9']  = 'input /ra <t>',
    ['Alt+0']  = 'input /ra <t>',
}

local player_data = windower.ffxi.get_player()
local mjlvl = player_data.main_job_level

if mjlvl >= 65 then 
    default_map['Ctrl+1'] = 'input /ja "Drain Samba III" <me>'
elseif mjlvl >= 35 then 
    default_map['Ctrl+1'] = 'input /ja "Drain Samba II" <me>'
end
if mjlvl >= 60 then 
    default_map['Ctrl+7'] = 'input /ja "Aspir Samba II" <me>'
end

if player_data.sub_job_id ~= nil then 
	local res = require('resources')
	local sjlvl = player_data.sub_job_level
	local sjtla = res.jobs[player_data.sub_job_id].ens
	
	if sjtla == 'WAR' then 
		if sjlvl > 5 then
			default_map['Alt+2'] = 'input /ja "Provoke" <t>'
		end
	elseif sjtla == 'THF' then 
		if sjlvl >= 15 then
			default_map['Alt+2'] = 'input /ja "Sneak Attack" <me>'
		end
	end
end

return default_map

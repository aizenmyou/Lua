local default_map = {
    ['Ctrl+3'] = 'input /pet "Healing Ruby" <t>',
    ['Ctrl+0'] = 'lua r AutoSkill',
    ['Ctrl+8'] = 'input /ma "Carbuncle" <me>',
    ['Ctrl+9'] = 'input /item "Kitron Juice" <me>',
    ['Alt+1']  = 'input /map',
    ['Alt+2']  = 'input /pet "Assault" <t>',
    ['Alt+3']  = 'input /pet "Retreat" <me>',
    ['Alt+4']  = 'input /pet "Poison Nails" <t>',
    ['Alt+5']  = 'input /pet "Release" <me>',
    --['Alt+9']  = 'summoncycle',
    --['Alt+0']  = 'stopall',
}

local player_data = windower.ffxi.get_player()
local mjlvl = player_data.main_job_level
if player_data.sub_job_id ~= nil then 
	local res = require('resources')
	local sjlvl = player_data.sub_job_level
	local sjtla = res.jobs[player_data.sub_job_id].ens
	if sjtla == 'WHM' then 
		default_map['Ctrl+1'] = 'input /ma "Cure" <t>'
		default_map['Ctrl+2'] = 'input /ma "Cure II" <t>'
		default_map['Ctrl+4'] = 'input /ma "Curaga" <t>'
		default_map['Ctrl+5'] = 'input /ma "Barwatera" <me>'
		default_map['Ctrl+6'] = 'input /ma "Poisona" <t>'
	elseif sjtla == 'DNC' then 
		default_map['Ctrl+1'] = 'input /ja "Drain Samba" <me>'
		default_map['Ctrl+3'] = 'input /ja "Curing Waltz" <stpc>'
		default_map['Ctrl+0'] = 'cancel Sneak;cancel Invisible;input /ja "Spectral Jig" <me>'
	end
end

return default_map

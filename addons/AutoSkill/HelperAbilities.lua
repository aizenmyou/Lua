-- Required buffs. Cast these if missing.
req_buff_list = {
	['Drain Samba'] = { 'Drain Samba', 'Drain Samba II', 'Drain Samba III' },
	['Protect'] = { 'Protect', 'Protect II', 'Protect III', 'Protect IV', 'Protect V',
		'Protectra', 'Protectra II', 'Protectra III', 'Protectra IV', 'Protectra V' },
    ['Shell'] = { 'Shell', 'Shell II', 'Shell III', 'Shell IV', 'Shell V',
		'Shellra', 'Shellra II', 'Shellra III', 'Shellra IV', 'Shellra V' },
    ['Regen'] = { 'Regen', 'Regen II', 'Regen III' },
    ['Refresh'] = { 'Refresh' },
    ['Blink'] = { 'Blink', 'Utsusemi: Ichi', 'Utsusemi: Ni' },
    ['Stoneskin'] = { 'Stoneskin' },
    ['Aquaveil'] = { 'Aquaveil' },
	['Reraise'] = { 'Reraise', 'Reraise II', 'Reraise III' },
	['Phalanx'] = { 'Phalanx', 'Phalanx II' },
}

-- Replace these if we observe gaining/losing them, but don't actively look for them.
parrot_buff_list = {
    ['Spikes'] = { 'Blaze Spikes', 'Ice Spikes', 'Shock Spikes', 'Dread Spikes' },
    ['Enweapon'] = { 'Enfire', 'Enblizzard', 'Enaero', 'Enstone', 'Enthunder', 'Enwater',
		'Enfire II', 'Enblizzard II', 'Enaero II', 'Enstone II', 'Enthunder II', 'Enwater II' },
	['Barelement'] = { 'Barfire', 'Barblizzard', 'Baraero', 'Barstone', 'Barthunder', 'Barwater', 
		'Barfira', 'Barblizzara', 'Baraera', 'Barstonra', 'Barthundra', 'Barwatera' },
	['Barstatus'] = { 'Barsleep', 'Barpoison', 'Barparalyze', 'Barblind', 'Barsilence', 'Barpetrify', 'Barvirus', 'Baramnesia',
		'Barsleepra', 'Barpoisonra', 'Barparalyzra', 'Barblindra', 'Barsilencera', 'Barpetra', 'Barvira', 'Baramnesra' },
}

-- If we notice these debuffs, cancel them.
cancel_buff_list = {
	['sleep'] = { 'Cure', 'Curing Waltz' },
	['poison'] = { 'Poisona' },
	['paralysis'] = { 'Paralyna' },
	['blindness'] = { 'Blindna' },
	['silence'] = { 'Silena' },
	['petrification'] = { 'Stona' },
	['disease'] = { 'Viruna' },
	['curse'] = { 'Cursna' },
	['bind'] = { 'Erase', 'Healing Waltz' },
	['weight'] = { 'Erase', 'Healing Waltz' },
	['slow'] = { 'Haste', 'Healing Waltz' },
	['Dia'] = { 'Erase', 'Healing Waltz' },
	['Bio'] = { 'Erase', 'Healing Waltz' },
}

-- Estimated cure result data.
cure_ability_list = {
	['Cure'] = 30,
	['Cure II'] = 90,
	['Cure III'] = 180,
	['Cure IV'] = 360,
	['Cure V'] = 720,
	['Curing Waltz'] = 60
	['Curing Waltz II'] = 130,
	['Curing Waltz III'] = 270,
	['Curing Waltz IV'] = 450,
	['Divine Waltz'] = 60,
}

-- Ranged spam for Ninjutsu
ninjutsu_nuke_list = {
	'Katon: Ichi', 'Hyoton: Ichi', 'Huton: Ichi', 'Doton: Ichi', 'Raiton: Ichi', 'Suiton: Ichi',
	'Katon: Ni', 'Hyoton: Ni', 'Huton: Ni', 'Doton: Ni', 'Raiton: Ni', 'Suiton: Ni',
}

-- Weaponskills which are particularly potent. Use these, and only these, when available.
rec_weaponskills = {
	['Hand-to-Hand'] = { 'Combo', 'Raging Fists', 'Asuran Fists', 'Final Heaven' },
	['Dagger'] = { 'Wasp Sting', 'Viper Bite', 'Gust Slash', 'Dancing Edge', 'Evisceration', 'Mercy Stroke' },
	['Sword'] = { 'Fast Blade', 'Shining Blade', 'Spirits Within', 'Vorpal Blade', 'Savage Blade' },
	['Great Sword'] = { 'Hard Slash', 'Power Slash', 'Crescent Moon' },
	['Axe'] = { 'Raging Axe', 'Gale Axe', 'Rampage', 'Calamity', 'Decimation' },
	['Great Axe'] = { 'Shield Break', 'Sturmwind', 'Keen Edge', 'Raging Rush', 'Full Break' },
	['Scythe'] = { 'Slice', 'Dark Harvest', 'Nightmare Scythe', 'Vorpal Scythe', 'Guillotine' },
	['Polearm'] = { 'Double Thrust', 'Penta Thrust', 'Vorpal Thrust', 'Impulse Drive' },
	['Katana'] = { 'Blade: Rin', 'Blade: Retsu', 'Blade: Chi', 'Blade: Ten' },
	['Great Katana'] = { 'Tachi: Enpi', 'Tachi: Goten', 'Tachi: Jinpu', 'Tachi: Gekko' },
	['Club'] = { 'Shining Strike', 'Seraph Strike', 'True Strike', 'Judgment', 'Hexa Strike', 'Black Halo' },
	['Staff'] = { 'Heavy Swing', 'Rock Crusher', 'Earth Crusher', 'Starburst', 'Shell Crusher', 'Retribution' },
	['Archery'] = { 'Flaming Arrow', 'Piercing Arrow', 'Sidewinder', 'Empyreal Arrow' },
	['Marksmanship'] = { 'Hot Shot', 'Split Shot', 'Slug Shot', 'Heavy Shot' },
}

-- I made this myself, in a cave, with a box of scraps.
-- DON'T MESS IT UP!

CRAFTING_SKILLS = {
	'Fishing', 'Woodworking', 'Smithing', 'Goldsmithing', 'Clothcraft',
	'Leathercraft', 'Bonecraft', 'Alchemy', 'Cooking', 'Synergy'
}
CRAFTING_IDS = {}
for i,craft in ipairs(CRAFTING_SKILLS) do
	for j,skilldata in pairs(res.skills) do
		if skilldata.en == craft then
			CRAFTING_IDS[j] = string.toluakey(craft)
			break
		end
	end
end
AUTOMATON_SKILLS = { 'Automaton Melee', 'Automaton Ranged', 'Automaton Magic' }
AUTOMATON_SKILL_KEYS = { 'melee', 'ranged', 'magic' }

-- descending order of skill listing
CAP_ORDER = { 'A+', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'E', 'F', 'G' }
CAP_BY_VALUE = { 'H', 'G', 'F', 'E', 'D', 'C-', 'C', 'C+', 'B-', 'B', 'B+', 'A-', 'A+' }

-- levels 60 and below have sparse data (ie A+=A-)
RATING_SPARSE = {
	['A+']='A+', ['A']='A+', ['A-']='A+',
	['B+']='B+', ['B']='B+', ['B-']='B+',
	['C+']='C+', ['C']='C+', ['C-']='C+',
	['D']='D',
	['E']='E',
	['F']='F',
	['G']='G',
}

-- BRD, BLM, BLU, COR...
VALID_JOBS = {}
for i,jobdata in pairs(res.jobs) do
	VALID_JOBS[jobdata.ens] = 1
end
SKILL_KEYS = {}
SKILL_IDS = {}
for i,skilldata in pairs(res.skills) do
	if i > 0 then
		local skillname = skilldata.en
		-- seriously, the fuck, Windower?
		if skillname == 'Automaton Archery' then skillname = 'Automaton Ranged' end
		local key = string.toluakey(skillname)
		local shortened = skillname
		if shortened:find('Automaton') then
			shortened = shortened:gsub('Automaton ', 'Auto ')
		else -- don't turn Automaton Magic into just "Automaton"
			shortened = shortened:gsub(' Magic', '')
		end
		shortened = shortened:gsub(' Instrument', '')
		SKILL_KEYS[shortened] = key -- ['Hand-to-Hand'] -> 'hand_to_hand'
		SKILL_KEYS[key] = shortened -- ['Hand-to-Hand'] -> 'hand_to_hand'
		SKILL_KEYS[i] = key -- store [1] -> 'hand_to_hand'
		SKILL_IDS[shortened] = i
		SKILL_IDS[key] = i
	end
end

-- Skill caps for A+ through G for levels [1, 99]
SKILL_CAPS = {
	 [1] = {['A+']=  6, ['B+']=  5, ['C+']=  5, ['D']=  4, ['E']=  4, ['F']=  4, ['G']=  3},
	 [2] = {['A+']=  9, ['B+']=  7, ['C+']=  7, ['D']=  6, ['E']=  6, ['F']=  6, ['G']=  5},
	 [3] = {['A+']= 12, ['B+']= 10, ['C+']= 10, ['D']=  9, ['E']=  9, ['F']=  8, ['G']=  7},
	 [4] = {['A+']= 15, ['B+']= 13, ['C+']= 13, ['D']= 12, ['E']= 11, ['F']= 10, ['G']=  9},
	 [5] = {['A+']= 18, ['B+']= 16, ['C+']= 16, ['D']= 14, ['E']= 14, ['F']= 13, ['G']= 11},
	 [6] = {['A+']= 21, ['B+']= 19, ['C+']= 19, ['D']= 17, ['E']= 16, ['F']= 15, ['G']= 13},
	 [7] = {['A+']= 24, ['B+']= 22, ['C+']= 21, ['D']= 20, ['E']= 19, ['F']= 17, ['G']= 15},
	 [8] = {['A+']= 27, ['B+']= 25, ['C+']= 24, ['D']= 22, ['E']= 21, ['F']= 20, ['G']= 17},
	 [9] = {['A+']= 30, ['B+']= 28, ['C+']= 27, ['D']= 25, ['E']= 24, ['F']= 22, ['G']= 19},
	[10] = {['A+']= 33, ['B+']= 31, ['C+']= 30, ['D']= 28, ['E']= 26, ['F']= 24, ['G']= 21},
	[11] = {['A+']= 36, ['B+']= 34, ['C+']= 33, ['D']= 31, ['E']= 29, ['F']= 27, ['G']= 23},
	[12] = {['A+']= 39, ['B+']= 36, ['C+']= 35, ['D']= 33, ['E']= 31, ['F']= 29, ['G']= 25},
	[13] = {['A+']= 42, ['B+']= 39, ['C+']= 38, ['D']= 36, ['E']= 34, ['F']= 31, ['G']= 27},
	[14] = {['A+']= 45, ['B+']= 42, ['C+']= 41, ['D']= 39, ['E']= 36, ['F']= 33, ['G']= 29},
	[15] = {['A+']= 48, ['B+']= 45, ['C+']= 44, ['D']= 41, ['E']= 39, ['F']= 36, ['G']= 31},
	[16] = {['A+']= 51, ['B+']= 48, ['C+']= 47, ['D']= 44, ['E']= 41, ['F']= 38, ['G']= 33},
	[17] = {['A+']= 54, ['B+']= 51, ['C+']= 49, ['D']= 47, ['E']= 44, ['F']= 40, ['G']= 35},
	[18] = {['A+']= 57, ['B+']= 54, ['C+']= 52, ['D']= 49, ['E']= 46, ['F']= 43, ['G']= 37},
	[19] = {['A+']= 60, ['B+']= 57, ['C+']= 55, ['D']= 52, ['E']= 49, ['F']= 45, ['G']= 39},
	[20] = {['A+']= 63, ['B+']= 60, ['C+']= 58, ['D']= 55, ['E']= 51, ['F']= 47, ['G']= 41},
	[21] = {['A+']= 66, ['B+']= 63, ['C+']= 61, ['D']= 58, ['E']= 54, ['F']= 50, ['G']= 43},
	[22] = {['A+']= 69, ['B+']= 65, ['C+']= 63, ['D']= 60, ['E']= 56, ['F']= 52, ['G']= 45},
	[23] = {['A+']= 72, ['B+']= 68, ['C+']= 66, ['D']= 63, ['E']= 59, ['F']= 54, ['G']= 47},
	[24] = {['A+']= 75, ['B+']= 71, ['C+']= 69, ['D']= 66, ['E']= 61, ['F']= 56, ['G']= 49},
	[25] = {['A+']= 78, ['B+']= 74, ['C+']= 72, ['D']= 68, ['E']= 64, ['F']= 59, ['G']= 51},
	[26] = {['A+']= 81, ['B+']= 77, ['C+']= 75, ['D']= 71, ['E']= 66, ['F']= 61, ['G']= 53},
	[27] = {['A+']= 84, ['B+']= 80, ['C+']= 77, ['D']= 74, ['E']= 69, ['F']= 63, ['G']= 55},
	[28] = {['A+']= 87, ['B+']= 83, ['C+']= 80, ['D']= 76, ['E']= 71, ['F']= 66, ['G']= 57},
	[29] = {['A+']= 90, ['B+']= 86, ['C+']= 83, ['D']= 79, ['E']= 74, ['F']= 68, ['G']= 59},
	[30] = {['A+']= 93, ['B+']= 89, ['C+']= 86, ['D']= 82, ['E']= 76, ['F']= 70, ['G']= 61},
	[31] = {['A+']= 96, ['B+']= 92, ['C+']= 89, ['D']= 85, ['E']= 79, ['F']= 73, ['G']= 63},
	[32] = {['A+']= 99, ['B+']= 94, ['C+']= 91, ['D']= 87, ['E']= 81, ['F']= 75, ['G']= 65},
	[33] = {['A+']=102, ['B+']= 97, ['C+']= 94, ['D']= 90, ['E']= 84, ['F']= 77, ['G']= 67},
	[34] = {['A+']=105, ['B+']=100, ['C+']= 97, ['D']= 93, ['E']= 86, ['F']= 79, ['G']= 69},
	[35] = {['A+']=108, ['B+']=103, ['C+']=100, ['D']= 95, ['E']= 89, ['F']= 82, ['G']= 71},
	[36] = {['A+']=111, ['B+']=106, ['C+']=103, ['D']= 98, ['E']= 91, ['F']= 84, ['G']= 73},
	[37] = {['A+']=114, ['B+']=109, ['C+']=105, ['D']=101, ['E']= 94, ['F']= 86, ['G']= 75},
	[38] = {['A+']=117, ['B+']=112, ['C+']=108, ['D']=103, ['E']= 96, ['F']= 89, ['G']= 77},
	[39] = {['A+']=120, ['B+']=115, ['C+']=111, ['D']=106, ['E']= 99, ['F']= 91, ['G']= 79},
	[40] = {['A+']=123, ['B+']=118, ['C+']=114, ['D']=109, ['E']=101, ['F']= 93, ['G']= 81},
	[41] = {['A+']=126, ['B+']=121, ['C+']=117, ['D']=112, ['E']=104, ['F']= 96, ['G']= 83},
	[42] = {['A+']=129, ['B+']=123, ['C+']=119, ['D']=114, ['E']=106, ['F']= 98, ['G']= 85},
	[43] = {['A+']=132, ['B+']=126, ['C+']=122, ['D']=117, ['E']=109, ['F']=100, ['G']= 87},
	[44] = {['A+']=135, ['B+']=129, ['C+']=125, ['D']=120, ['E']=111, ['F']=102, ['G']= 89},
	[45] = {['A+']=138, ['B+']=132, ['C+']=128, ['D']=122, ['E']=114, ['F']=105, ['G']= 91},
	[46] = {['A+']=141, ['B+']=135, ['C+']=131, ['D']=125, ['E']=116, ['F']=107, ['G']= 93},
	[47] = {['A+']=144, ['B+']=138, ['C+']=133, ['D']=128, ['E']=119, ['F']=109, ['G']= 95},
	[48] = {['A+']=147, ['B+']=141, ['C+']=136, ['D']=130, ['E']=121, ['F']=112, ['G']= 97},
	[49] = {['A+']=150, ['B+']=144, ['C+']=139, ['D']=133, ['E']=124, ['F']=114, ['G']= 99},
	[50] = {['A+']=153, ['B+']=147, ['C+']=142, ['D']=136, ['E']=126, ['F']=116, ['G']=101},
	[51] = {['A+']=158, ['B+']=151, ['C+']=146, ['D']=140, ['E']=130, ['F']=120, ['G']=104},
	[52] = {['A+']=163, ['B+']=156, ['C+']=151, ['D']=145, ['E']=135, ['F']=124, ['G']=107},
	[53] = {['A+']=168, ['B+']=161, ['C+']=156, ['D']=150, ['E']=139, ['F']=128, ['G']=110},
	[54] = {['A+']=173, ['B+']=166, ['C+']=161, ['D']=154, ['E']=144, ['F']=133, ['G']=113},
	[55] = {['A+']=178, ['B+']=171, ['C+']=166, ['D']=159, ['E']=148, ['F']=137, ['G']=116},
	[56] = {['A+']=183, ['B+']=176, ['C+']=170, ['D']=164, ['E']=153, ['F']=141, ['G']=119},
	[57] = {['A+']=188, ['B+']=181, ['C+']=175, ['D']=168, ['E']=157, ['F']=146, ['G']=122},
	[58] = {['A+']=193, ['B+']=186, ['C+']=180, ['D']=173, ['E']=162, ['F']=150, ['G']=125},
	[59] = {['A+']=198, ['B+']=191, ['C+']=185, ['D']=178, ['E']=166, ['F']=154, ['G']=128},
	[60] = {['A+']=203, ['B+']=196, ['C+']=190, ['D']=183, ['E']=171, ['F']=159, ['G']=131},
	[61] = {['A+']=207, ['A-']=207, ['B+']=199, ['B']=199, ['B-']=198, ['C+']=192, ['C']=192, ['C-']=192, ['D']=184, ['E']=172, ['F']=161, ['G']=134},
	[62] = {['A+']=212, ['A-']=211, ['B+']=203, ['B']=202, ['B-']=201, ['C+']=195, ['C']=194, ['C-']=194, ['D']=186, ['E']=174, ['F']=163, ['G']=137},
	[63] = {['A+']=217, ['A-']=215, ['B+']=207, ['B']=205, ['B-']=204, ['C+']=197, ['C']=196, ['C-']=196, ['D']=188, ['E']=176, ['F']=165, ['G']=140},
	[64] = {['A+']=222, ['A-']=219, ['B+']=210, ['B']=208, ['B-']=206, ['C+']=200, ['C']=199, ['C-']=198, ['D']=190, ['E']=178, ['F']=167, ['G']=143},
	[65] = {['A+']=227, ['A-']=223, ['B+']=214, ['B']=212, ['B-']=209, ['C+']=202, ['C']=201, ['C-']=200, ['D']=192, ['E']=180, ['F']=169, ['G']=146},
	[66] = {['A+']=232, ['A-']=227, ['B+']=218, ['B']=215, ['B-']=212, ['C+']=205, ['C']=203, ['C-']=202, ['D']=194, ['E']=182, ['F']=171, ['G']=149},
	[67] = {['A+']=236, ['A-']=231, ['B+']=221, ['B']=218, ['B-']=214, ['C+']=207, ['C']=205, ['C-']=204, ['D']=195, ['E']=184, ['F']=173, ['G']=152},
	[68] = {['A+']=241, ['A-']=235, ['B+']=225, ['B']=221, ['B-']=217, ['C+']=210, ['C']=208, ['C-']=206, ['D']=197, ['E']=186, ['F']=175, ['G']=155},
	[69] = {['A+']=246, ['A-']=239, ['B+']=229, ['B']=225, ['B-']=220, ['C+']=212, ['C']=210, ['C-']=208, ['D']=199, ['E']=188, ['F']=177, ['G']=158},
	[70] = {['A+']=251, ['A-']=244, ['B+']=233, ['B']=228, ['B-']=223, ['C+']=215, ['C']=212, ['C-']=210, ['D']=201, ['E']=190, ['F']=179, ['G']=161},
	[71] = {['A+']=256, ['A-']=249, ['B+']=237, ['B']=232, ['B-']=226, ['C+']=218, ['C']=214, ['C-']=212, ['D']=203, ['E']=192, ['F']=181, ['G']=163},
	[72] = {['A+']=261, ['A-']=254, ['B+']=241, ['B']=236, ['B-']=229, ['C+']=221, ['C']=217, ['C-']=214, ['D']=205, ['E']=194, ['F']=183, ['G']=165},
	[73] = {['A+']=266, ['A-']=259, ['B+']=246, ['B']=240, ['B-']=232, ['C+']=224, ['C']=219, ['C-']=216, ['D']=207, ['E']=196, ['F']=185, ['G']=167},
	[74] = {['A+']=271, ['A-']=264, ['B+']=251, ['B']=245, ['B-']=236, ['C+']=227, ['C']=222, ['C-']=218, ['D']=208, ['E']=198, ['F']=187, ['G']=169},
	[75] = {['A+']=276, ['A-']=269, ['B+']=256, ['B']=250, ['B-']=240, ['C+']=230, ['C']=225, ['C-']=220, ['D']=210, ['E']=200, ['F']=189, ['G']=171},
	[76] = {['A+']=281, ['A-']=274, ['B+']=261, ['B']=255, ['B-']=245, ['C+']=235, ['C']=230, ['C-']=225, ['D']=214, ['E']=203, ['F']=191, ['G']=173},
	[77] = {['A+']=286, ['A-']=279, ['B+']=266, ['B']=260, ['B-']=250, ['C+']=240, ['C']=235, ['C-']=230, ['D']=218, ['E']=206, ['F']=193, ['G']=175},
	[78] = {['A+']=291, ['A-']=284, ['B+']=271, ['B']=265, ['B-']=255, ['C+']=245, ['C']=240, ['C-']=235, ['D']=222, ['E']=209, ['F']=195, ['G']=177},
	[79] = {['A+']=296, ['A-']=289, ['B+']=276, ['B']=270, ['B-']=260, ['C+']=250, ['C']=245, ['C-']=240, ['D']=226, ['E']=212, ['F']=197, ['G']=179},
	[80] = {['A+']=301, ['A-']=294, ['B+']=281, ['B']=275, ['B-']=265, ['C+']=255, ['C']=250, ['C-']=245, ['D']=230, ['E']=215, ['F']=199, ['G']=181},
	[81] = {['A+']=307, ['A-']=300, ['B+']=287, ['B']=281, ['B-']=271, ['C+']=261, ['C']=256, ['C-']=251, ['D']=235, ['E']=219, ['F']=202, ['G']=183},
	[82] = {['A+']=313, ['A-']=306, ['B+']=293, ['B']=287, ['B-']=277, ['C+']=267, ['C']=262, ['C-']=257, ['D']=240, ['E']=223, ['F']=205, ['G']=185},
	[83] = {['A+']=319, ['A-']=312, ['B+']=299, ['B']=293, ['B-']=283, ['C+']=273, ['C']=268, ['C-']=263, ['D']=245, ['E']=227, ['F']=208, ['G']=187},
	[84] = {['A+']=325, ['A-']=318, ['B+']=305, ['B']=299, ['B-']=289, ['C+']=279, ['C']=274, ['C-']=269, ['D']=250, ['E']=231, ['F']=211, ['G']=189},
	[85] = {['A+']=331, ['A-']=324, ['B+']=311, ['B']=305, ['B-']=295, ['C+']=285, ['C']=280, ['C-']=275, ['D']=255, ['E']=235, ['F']=214, ['G']=191},
	[86] = {['A+']=337, ['A-']=330, ['B+']=317, ['B']=311, ['B-']=301, ['C+']=291, ['C']=286, ['C-']=281, ['D']=260, ['E']=239, ['F']=217, ['G']=193},
	[87] = {['A+']=343, ['A-']=336, ['B+']=323, ['B']=317, ['B-']=307, ['C+']=297, ['C']=292, ['C-']=287, ['D']=265, ['E']=243, ['F']=220, ['G']=195},
	[88] = {['A+']=349, ['A-']=342, ['B+']=329, ['B']=323, ['B-']=313, ['C+']=303, ['C']=298, ['C-']=293, ['D']=270, ['E']=247, ['F']=223, ['G']=197},
	[89] = {['A+']=355, ['A-']=348, ['B+']=335, ['B']=329, ['B-']=319, ['C+']=309, ['C']=304, ['C-']=299, ['D']=275, ['E']=251, ['F']=226, ['G']=199},
	[90] = {['A+']=361, ['A-']=354, ['B+']=341, ['B']=335, ['B-']=325, ['C+']=315, ['C']=310, ['C-']=305, ['D']=280, ['E']=255, ['F']=229, ['G']=201},
	[91] = {['A+']=368, ['A-']=361, ['B+']=348, ['B']=342, ['B-']=332, ['C+']=322, ['C']=317, ['C-']=312, ['D']=286, ['E']=260, ['F']=233, ['G']=204},
	[92] = {['A+']=375, ['A-']=368, ['B+']=355, ['B']=349, ['B-']=339, ['C+']=329, ['C']=324, ['C-']=319, ['D']=292, ['E']=265, ['F']=237, ['G']=207},
	[93] = {['A+']=382, ['A-']=375, ['B+']=362, ['B']=356, ['B-']=346, ['C+']=336, ['C']=331, ['C-']=326, ['D']=298, ['E']=270, ['F']=241, ['G']=210},
	[94] = {['A+']=389, ['A-']=382, ['B+']=369, ['B']=363, ['B-']=353, ['C+']=343, ['C']=338, ['C-']=333, ['D']=304, ['E']=275, ['F']=245, ['G']=213},
	[95] = {['A+']=396, ['A-']=389, ['B+']=376, ['B']=370, ['B-']=360, ['C+']=350, ['C']=345, ['C-']=340, ['D']=310, ['E']=280, ['F']=249, ['G']=216},
	[96] = {['A+']=403, ['A-']=396, ['B+']=383, ['B']=377, ['B-']=367, ['C+']=357, ['C']=352, ['C-']=347, ['D']=316, ['E']=285, ['F']=253, ['G']=219},
	[97] = {['A+']=410, ['A-']=403, ['B+']=390, ['B']=384, ['B-']=374, ['C+']=364, ['C']=359, ['C-']=354, ['D']=322, ['E']=290, ['F']=257, ['G']=222},
	[98] = {['A+']=417, ['A-']=410, ['B+']=397, ['B']=391, ['B-']=381, ['C+']=371, ['C']=366, ['C-']=361, ['D']=328, ['E']=295, ['F']=261, ['G']=225},
	[99] = {['A+']=424, ['A-']=417, ['B+']=404, ['B']=398, ['B-']=388, ['C+']=378, ['C']=373, ['C-']=368, ['D']=334, ['E']=300, ['F']=265, ['G']=228},
}

-- Melee Weapon ratings per job
JOB_WEAPON_RATINGS = {
	['BRD'] = {['Club']='D',    ['Dagger']='B-',       ['Staff']='C+',  ['Sword']='C-'},
	['BST'] = {['Axe']='A+',    ['Club']='D',          ['Dagger']='C+', ['Scythe']='B-', ['Sword']='E'},
	['BLM'] = {['Club']='C+',   ['Dagger']='D',        ['Scythe']='E',  ['Staff']='B-'},
	['BLU'] = {['Club']='B-',   ['Sword']='A+'},
	['COR'] = {['Dagger']='B+', ['Sword']='B-'},
	['DNC'] = {['Dagger']='A+', ['Hand-to-Hand']='D',  ['Sword']='D'},
	['DRK'] = {['Axe']='B-',    ['Great Axe']='B-',    ['Club']='C-', ['Dagger']='C', ['Scythe']='A+', ['Sword']='B-', ['Great Sword']='A-'},
	['DRG'] = {['Club']='E',    ['Dagger']='E',        ['Polearm']='A+', ['Staff']='B-', ['Sword']='C-'},
	['GEO'] = {['Club']='B+',   ['Dagger']='C-',       ['Staff']='C+'},
	['MNK'] = {['Club']='C+',   ['Hand-to-Hand']='A+', ['Staff']='B'},
	['NIN'] = {['Club']='E',    ['Dagger']='C+',       ['Hand-to-Hand']='E', ['Katana']='A+', ['Great Katana']='C-', ['Sword']='C'},
	['PLD'] = {['Club']='A-',   ['Dagger']='C-',       ['Polearm']='E', ['Staff']='A-', ['Sword']='A+', ['Great Sword']='B'},
	['PUP'] = {['Club']='D',    ['Dagger']='C-',       ['Hand-to-Hand']='A+'},
	['RNG'] = {['Axe']='B-',    ['Club']='E',          ['Dagger']='B-', ['Sword']='D'},
	['RDM'] = {['Club']='D',    ['Dagger']='B',        ['Sword']='B'},
	['RUN'] = {['Axe']='B-',    ['Great Axe']='B',     ['Club']='C-', ['Sword']='A-', ['Great Sword']='A-'},
	['SAM'] = {['Club']='E',    ['Dagger']='E',        ['Great Katana']='A+', ['Polearm']='B-', ['Sword']='C+'},
	['SCH'] = {['Club']='C+',   ['Dagger']='D',        ['Staff']='C+'},
	['SMN'] = {['Club']='C+',   ['Dagger']='E',        ['Staff']='B'},
	['THF'] = {['Club']='E',    ['Dagger']='A+',       ['Hand-to-Hand']='E', ['Sword']='D'},
	['WAR'] = {['Axe']='A-',    ['Great Axe']='A+',    ['Club']='B-', ['Dagger']='B-', ['Hand-to-Hand']='D', ['Polearm']='B-', ['Scythe']='B+', ['Staff']='B', ['Sword']='B', ['Great Sword']='B+'},
	['WHM'] = {['Club']='B+',   ['Staff']='C+'},
}

-- Ranged Weapon ratings per job: Archery, Marksmanship, Throwing
JOB_RANGED_RATINGS = {
	['BRD']={['Throwing']='E'},
	['BLM']={['Throwing']='D'},
	['COR']={['Marksmanship']='B', ['Throwing']='C+'},
	['DNC']={['Throwing']='C+'},
	['DRK']={['Marksmanship']='E'},
	['MNK']={['Throwing']='E'},
	['NIN']={['Archery']='E', ['Marksmanship']='C', ['Throwing']='A+'},
	['PUP']={['Throwing']='C+'},
	['RNG']={['Archery']='A+', ['Marksmanship']='A+', ['Throwing']='C-'},
	['RDM']={['Archery']='D', ['Throwing']='F'},
	['SAM']={['Archery']='C+', ['Throwing']='C+'},
	['SCH']={['Throwing']='D'},
	['THF']={['Archery']='C-', ['Marksmanship']='C+', ['Throwing']='D'},
	['WAR']={['Archery']='D', ['Marksmanship']='D', ['Throwing']='D'},
	['WHM']={['Throwing']='E'},
}

-- Defensive ratings: Evasion, Parrying, Guard, Shield
JOB_DEFENSIVE_RATINGS = {
	['BRD']={['Evasion']='D',  ['Parrying']='E'},
	['BST']={['Evasion']='C',  ['Parrying']='C', ['Shield']='E'},
	['BLM']={['Evasion']='E'},
	['BLU']={['Evasion']='C-', ['Parrying']='D'},
	['COR']={['Evasion']='D',  ['Parrying']='A-'},
	['DNC']={['Evasion']='B+', ['Parrying']='B'},
	['DRK']={['Evasion']='C',  ['Parrying']='E'},
	['DRG']={['Evasion']='B',  ['Parrying']='B-'},
	['GEO']={['Evasion']='D',  ['Parrying']='E'},
	['MNK']={['Evasion']='B+', ['Guard']='A-',   ['Parrying']='E'},
	['NIN']={['Evasion']='A-', ['Parrying']='A-'},
	['PLD']={['Evasion']='C',  ['Parrying']='C', ['Shield']='A+'},
	['PUP']={['Evasion']='B',  ['Guard']='B-',   ['Parrying']='D'},
	['RNG']={['Evasion']='E'},
	['RDM']={['Evasion']='D',  ['Parrying']='E', ['Shield']='F'},
	['RUN']={['Evasion']='B+', ['Parrying']='A+'},
	['SAM']={['Evasion']='B+', ['Parrying']='A-'},
	['SCH']={['Evasion']='E',  ['Parrying']='E'},
	['SMN']={['Evasion']='E'},
	['THF']={['Evasion']='A+', ['Parrying']='A-', ['Shield']='F'},
	['WAR']={['Evasion']='C',  ['Parrying']='C-', ['Shield']='C+'},
	['WHM']={['Evasion']='E',  ['Shield']='D'},
}

-- Magic ratings: Dark, Divine, Elemental, Healing, Enfeebling, Enhancing, and job-specific
JOB_MAGIC_RATINGS = {
	['BRD']={['Singing']='C', ['Stringed']='C', ['Wind']='C'},
	['BLM']={['Dark']='A-', ['Elemental']='A+', ['Enfeebling']='C+', ['Enhancing']='E'},
	['BLU']={['Blue']='A+'},
	['DRK']={['Dark']='A-', ['Elemental']='B+', ['Enfeebling']='C'},
	['GEO']={['Dark']='C', ['Elemental']='B+', ['Enfeebling']='C+', ['Geomancy']='C', ['Handbell']='C'},
	['NIN']={['Ninjutsu']='A-'},
	['PLD']={['Divine']='B+', ['Enhancing']='D', ['Healing']='C'},
	['RDM']={['Dark']='E', ['Divine']='E', ['Elemental']='C+', ['Enfeebling']='A+', ['Enhancing']='B+', ['Healing']='C-'},
	['RUN']={['Divine']='B', ['Enhancing']='B-'},
	['SCH']={['Dark']='D', ['Divine']='D', ['Elemental']='D', ['Enfeebling']='D', ['Enhancing']='D', ['Healing']='D'},
	['SMN']={['Summoning']='A-'},
	['WHM']={['Divine']='A-', ['Enfeebling']='C', ['Enhancing']='C+', ['Healing']='A+'},
}

AUTOMATON_RATINGS = {
	['HARLEQUIN'] ={['AutoMelee']='B-',['AutoMagic']='B-',['AutoRanged']='B-'},
	['VALOREDGE'] ={['AutoMelee']='B+'},
	['SHARPSHOT'] ={['AutoMelee']='C+',['AutoRanged']='B+'},
	['STORMWAKER']={['AutoMelee']='C',['AutoMagic']='B+'},
}

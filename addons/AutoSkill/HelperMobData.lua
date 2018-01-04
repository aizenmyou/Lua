-- We want to poll/pull information from here 'mob_spawn_points.sql'
-- ex: INSERT INTO `mob_spawn_points` VALUES (17395800,'Mee_Deggi_the_Punisher','Mee Deggi the Punisher',8087,-223,1,119,127);

-- We want to pull data from every scripts/zones/*
-- ex: MobIDs.lua
-- FUNGUS_BEETLE_PH =
-- {
--     [17187046] = 17187047, -- -133.001 -20.636 -141.110
--     [17187115] = 17187047, -- -287.202 -20.826 -199.075
--     [17187114] = 17187047, -- -295.626 -21.389 -192.191
-- };
-- 
-- JAGGEDY_EARED_JACK_PH =
-- {
--     [17187110] = 17187111, -- -262.780 -22.384 -253.873
--     [17187109] = 17187111, -- -267.389 -21.669 -252.720
--     [17187108] = 17187111, -- -273.558 -19.943 -284.081
--     [17187042] = 17187111, -- -248.681 -21.336 -163.987
--     [17187154] = 17187111, -- -329.892 -9.702 -313.713
--     [17187152] = 17187111, -- -278.421 -11.691 -351.425
--     [17187132] = 17187111, -- -204.492 -20.754 -324.770
-- };

-- or looks like
-- ARGUS                   = 17588674;
-- LEECH_KING              = 17588685;

-- and we want to parse the Zone.lua and mobs/* for specific instances of stuff like
-- DisallowRespawn(LEECH_KING, true);
-- DisallowRespawn(ARGUS, false);
-- UpdateNMSpawnPoint(ARGUS);
-- GetMobByID(ARGUS):setRespawnTime(math.random(64800, 108000)); -- 18-30 hours

-- All, in order to automatically generate data like the following:



-- ====== West Ronfaure ======
z_mobdata.nms['WRonfaure'] = {} 
--Jaggedy-Eared Jack
z_mobdata.nms['WRonfaure'][17187111] = {}
z_mobdata.nms['WRonfaure'][17187111].respawn_minimum = 3600
z_mobdata.nms['WRonfaure'][17187111].ph_probability = 0.05
z_mobdata.phs['WRonfaure'][17187042] = { ['related_nm'] = 17187111 }
z_mobdata.phs['WRonfaure'][17187108] = { ['related_nm'] = 17187111 }
z_mobdata.phs['WRonfaure'][17187109] = { ['related_nm'] = 17187111 }
z_mobdata.phs['WRonfaure'][17187110] = { ['related_nm'] = 17187111 }
z_mobdata.phs['WRonfaure'][17187132] = { ['related_nm'] = 17187111 }
z_mobdata.phs['WRonfaure'][17187152] = { ['related_nm'] = 17187111 }
z_mobdata.phs['WRonfaure'][17187154] = { ['related_nm'] = 17187111 }
-- Fungus Beetle
z_mobdata.nms['WRonfaure'][17187047] = {}
z_mobdata.nms['WRonfaure'][17187047].respawn_minimum = 3600
z_mobdata.nms['WRonfaure'][17187111].ph_probability = 0.15
z_mobdata.phs['WRonfaure'][17187046] = { ['related_nm'] = 17187047 }
z_mobdata.phs['WRonfaure'][17187114] = { ['related_nm'] = 17187047 }
z_mobdata.phs['WRonfaure'][17187115] = { ['related_nm'] = 17187047 }
-- ====== Castle Oztroja ======
-- Mee Deggi the Punisher
z_mobdata.nms['Oztroja'][17395800] = {}
z_mobdata.nms['Oztroja'][17395800].respawn_minimum =  3600
z_mobdata.nms['Oztroja'][17395800].respawn_maximum = 10800
z_mobdata.phs['Oztroja'][17395798] = { ['related_nm'] = 17395800 }
z_mobdata.phs['Oztroja'][17395766] = { ['related_nm'] = 17395800 }
z_mobdata.phs['Oztroja'][17395769] = { ['related_nm'] = 17395800 }
z_mobdata.phs['Oztroja'][17395783] = { ['related_nm'] = 17395800 }
z_mobdata.phs['Oztroja'][17395784] = { ['related_nm'] = 17395800 }
z_mobdata.phs['Oztroja'][17395799] = { ['related_nm'] = 17395800 }
z_mobdata.phs['Oztroja'][17395761] = { ['related_nm'] = 17395800 }
z_mobdata.phs['Oztroja'][17395775] = { ['related_nm'] = 17395800 }
-- Saa Doyi the Fervid
z_mobdata.nms['Oztroja'][17395731] = {}
z_mobdata.nms['Oztroja'][17395731].respawn_minimum = 3600 
-- ====== South Gustaberg ======
-- Leaping Lizzy -- in this case there are two placeholders and two Leaping Lizzy definitions?
z_mobdata.nms['SGustaberg'][17215868] = {}
z_mobdata.nms['SGustaberg'][17215868].respawn_minimum = 3600
z_mobdata.nms['SGustaberg'][17215888] = {}
z_mobdata.nms['SGustaberg'][17215888].respawn_maximum = 3600
z_mobdata.phs['SGustaberg'][17215867] = { ['related_nm'] = 17215868 }
z_mobdata.phs['SGustaberg'][17215887] = { ['related_nm'] = 17215888 }
-- ====== Maze of Shakhrami ======
-- Argus
z_mobdata.nms['Shakhrami'][17588674] = {}
z_mobdata.nms['Shakhrami'][17588674].respawn_minimum = 14400
-- Leech King
z_mobdata.nms['Shakhrami'][17588675] = {}
z_mobdata.nms['Shakhrami'][17588675].respawn_maximum = 14400

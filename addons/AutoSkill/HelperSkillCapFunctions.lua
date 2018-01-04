-- Skill Cap calculation and display functions

local DELAYED_MESSAGE_LOG = {}
function SKILLCAPdisplayDelayedMessages()
	if table.getn(DELAYED_MESSAGE_LOG) == 0 then return end
	
	msg = table.remove(DELAYED_MESSAGE_LOG, 1)
	windower.chat.input(msg)
	if table.getn(DELAYED_MESSAGE_LOG) > 0 then
		coroutine.schedule(SKILLCAPdisplayDelayedMessages, 2)
	end
end

function SKILLCAPgenerateDelayedMessage(mode, category, content)
	if content == nil or content == '' then return end
	local message = (category ~= nil and ' -- '..category..': ') or ''
	message = message..content
	if mode == nil then
		windower.add_to_chat(17, message)
	else
		table.insert(DELAYED_MESSAGE_LOG, mode..message)
	end
end

function SKILLCAPdisplayRawLevelCaps(mode, lvl)
	local caps = SKILL_CAPS[lvl]
	local output = ''
	
	for i,rkey in ipairs(CAP_ORDER) do
		if caps[rkey] ~= nil then
			if lvl <= 60 then
				if output ~= '' then output = output..' / ' end
				output = output..string.gsub(rkey, "+", "")..' '..caps[rkey]
			else
				if output ~= '' then output = output..'/ ' end
				output = output..rkey..caps[rkey]
			end
		end
	end
	SKILLCAPgenerateDelayedMessage(mode, nil, 'Skillcaps lv'..lvl..': '..output)
	SKILLCAPdisplayDelayedMessages()
end

local z_aggregate_skill_ratings = {}
for i,ratingset in ipairs( { JOB_WEAPON_RATINGS, JOB_RANGED_RATINGS, JOB_DEFENSIVE_RATINGS, JOB_MAGIC_RATINGS} ) do
	for job,skillset in pairs(ratingset) do
		if z_aggregate_skill_ratings[job] == nil then z_aggregate_skill_ratings[job] = {} end
		for skill,rating in pairs(skillset) do
			z_aggregate_skill_ratings[job][skill] = rating
		end
	end
end

function getSkillCapFor(job, level, skill)
	if job == nil then return -1 end
	if level == nil then return -2 end
	if skill == nil then return -3 end
	if z_aggregate_skill_ratings[job] == nil then return 'bad job='..job end
	if SKILL_CAPS[level] == nil then return -5 end
	local rating = z_aggregate_skill_ratings[job][skill]
	if rating == nil then return 'bad skill='..skill end
	if level <= 60 then rating = RATING_SPARSE[rating] end
	if rating == nil then return -7 end
	if SKILL_CAPS[level][rating] == nil then return '"'..rating..'"' end
	return SKILL_CAPS[level][rating]
end

function SKILLCAPprocessAndInsert(level, job_ratings)
	local output = ''
	if job_ratings == nil then return output end -- e.g. PUP has no magic, 
	local lvlcaps = SKILL_CAPS[level]
	local prev_rank = ''
	local prev_value = 0
	for i,rkey in ipairs(CAP_ORDER) do
		if level >= 61 or prev_rank ~= RATING_SPARSE[rkey] then -- no Lua continue, so gotta embed here
			local outlist = {}
			for category,cat_rank in pairs(job_ratings) do
				if (level >= 61 and cat_rank == rkey) or 
				   (level <= 60 and RATING_SPARSE[cat_rank] == RATING_SPARSE[rkey]) then
					table.insert(outlist, category)
				end
			end
			if table.getn(outlist) > 0 then
				if prev_value == lvlcaps[rkey] then
					-- for silly things like lv1 DRK, B and C rank are the same value, just squish 'em together
					output = output..'/'..table.concat(outlist, '/')
				else
					if output ~= '' then output = output..', ' end
					output = output..lvlcaps[rkey]..' '..table.concat(outlist, '/')
					prev_value = lvlcaps[rkey]
				end
			end
			prev_rank = rkey
		end
	end
	return output
end

function SKILLCAPdisplayJobLevelCaps(mode, job, lvl)
	DELAYED_MESSAGE_LOG = {}
	SKILLCAPgenerateDelayedMessage(mode, nil, 'Skillcaps for lv'..lvl..' '..job)
	SKILLCAPgenerateDelayedMessage(mode, 'Melee',   SKILLCAPprocessAndInsert(lvl, JOB_WEAPON_RATINGS[job]))
	SKILLCAPgenerateDelayedMessage(mode, 'Ranged',  SKILLCAPprocessAndInsert(lvl, JOB_RANGED_RATINGS[job]))
	SKILLCAPgenerateDelayedMessage(mode, 'Defense', SKILLCAPprocessAndInsert(lvl, JOB_DEFENSIVE_RATINGS[job]))
	SKILLCAPgenerateDelayedMessage(mode, 'Magic',   SKILLCAPprocessAndInsert(lvl, JOB_MAGIC_RATINGS[job]))
	SKILLCAPdisplayDelayedMessages()
end

function skillCommand(param, paramcount, paramtwoall)
	if paramcount < 2 then return false end
	local lvl = tonumber(param[1])
	if lvl == nil then return false end
	lvl = math.floor(lvl)
	if lvl < 1 or lvl > 99 then return false end
	local job = param[2]:upper()
	if VALID_JOBS[job] ~= 1 then return false end

	local chatmode = ''
	if paramcount > 2 then chatmode = param[3]:lower() end
	if chatmode ~= 'p' and chatmode ~= 'party' then
		chatmode = nil
	else
		chatmode = '/p '
	end
	SKILLCAPdisplayJobLevelCaps(chatmode, job, lvl)
	return true
end

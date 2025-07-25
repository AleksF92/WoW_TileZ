local data = {}

data.tiers = {}

-- Tier 1 (Level 10 - 19)
data.tiers[1] = {
	389,	-- Ragefire Chasm (13�18)
	43,		-- Wailing Caverns (15�25)
	36,		-- The Deadmines (17�26)
	33		-- Shadowfang Keep (18�25)
}

-- Tier 2 (Level 20 - 29)
data.tiers[2] = {
	48,		-- Blackfathom Deeps (20�30)
	34,		-- Stormwind Stockade (22�30)
	90,		-- Gnomeregan (25�35)
	47		-- Razorfen Kraul (25�35)
}

-- Tier 3 (Level 30 - 39)
data.tiers[3] = {
	129,	-- Razorfen Downs (35�45)
	189,	-- SM: Graveyard (28�35)
	189,	-- SM: Library (29�39)
	189,	-- SM: Armory (32�42)
	189,	-- SM: Cathedral (35�45)
	70		-- Uldaman (35�45)
}

-- Tier 4 (Level 40 - 49)
data.tiers[4] = {
	209,	-- Zul'Farrak (44�54)
	349		-- Maraudon (45�55)
}

-- Tier 5 (Level 50 - 59)
data.tiers[5] = {
	109,	-- Sunken Temple (50�55)
	230,	-- Blackrock Depths (52�60)
	229,	-- Blackrock Spire (UBRS/LBRS) (55�60)
	429,	-- Dire Maul (East/North/West) (54�60)
	289,	-- Scholomance (56�60)
	329		-- Stratholme (Live/Dead) (56�60)
}

data.freeTier = {
	369		-- Deeprun Tram
}

data.unlockCosts = {
	50, 100, 150, 200, 250
}

ledii.instances = data
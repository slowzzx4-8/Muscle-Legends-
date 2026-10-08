--[[
    Supreme Hub | Muscle Legends
    Custom UI — Black transparent + red borders
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	LocalPlayer = Players.PlayerAdded:Wait()
end
local Camera = Workspace.CurrentCamera
local NormalClockTime = Lighting.ClockTime

local CONFIG_PATH = "Muscle Legends.json"
local CLICK_SOUND_ID = "rbxassetid://2818606146"

-- polyfills
if not table.clear then
	function table.clear(t)
		for k in pairs(t) do t[k] = nil end
	end
end
local function safeHttpGet(url)
	local ok, res = pcall(function()
		if game.HttpGetAsync then return game:HttpGetAsync(url) end
		return game:HttpGet(url)
	end)
	if ok then return res end
	return nil
end

local function notify(title, text)
	-- notifications disabled
end

pcall(function()
	if LocalPlayer then
		LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end
end)

-- ==========================================
-- ICONS V2
-- ==========================================
local IconsV2
pcall(function()
	local srcIcons = safeHttpGet("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua")
	if srcIcons then
		IconsV2 = loadstring(srcIcons)()
		if IconsV2 and IconsV2.SetIconsType then
			IconsV2.SetIconsType("lucide")
		end
	end
end)

local function GetIcon(icon)
	if not icon or icon == "" then return nil end
	if typeof(icon) == "string" and icon:find("rbxassetid://") then
		return icon
	end
	if not IconsV2 then return nil end
	local ok, result = pcall(function()
		if typeof(icon) == "string" and icon:find(":") then
			local pack, name = icon:match("([^:]+):(.+)")
			if pack and name then
				IconsV2.SetIconsType(string.lower(pack))
				return IconsV2.GetIcon(name)
			end
		end
		IconsV2.SetIconsType("lucide")
		return IconsV2.GetIcon(icon)
	end)
	if ok and result then return result end
	return nil
end


-- Wrapped to stay under Luau 200-local limit
local function __SupremeMain()
-- ==========================================
-- HELPERS
-- ==========================================
local function char() return LocalPlayer.Character end
local function hum() local c = char() return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = char() return c and c:FindFirstChild("HumanoidRootPart") end
local function muscleEv() return LocalPlayer:FindFirstChild("muscleEvent") end

local function fireRep()
	local e = muscleEv()
	if e then pcall(function() e:FireServer("rep") end) end
end

local function firePunch()
	local e = muscleEv()
	if not e then return end
	pcall(function()
		e:FireServer("punch", "leftHand")
		e:FireServer("punch", "rightHand")
	end)
end

local function equipPunch()
	local c, h = char(), hum()
	if not c or not h then return end
	local t = c:FindFirstChild("Punch") or LocalPlayer.Backpack:FindFirstChild("Punch")
	if t and t.Parent ~= c then pcall(function() h:EquipTool(t) end) end
end

local function safeTouch(a, b, t)
	if firetouchinterest then pcall(function() firetouchinterest(a, b, t) end) end
end

local function isAlive(p)
	return p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0
end

local function isProtected(p)
	if not p or not p.Character then return false end
	if p.Character:FindFirstChildOfClass("ForceField") or p.Character:FindFirstChild("spawnProtectionHighlight") then return true end
	local u = p.Character:GetAttribute("SpawnProtectedUntil")
	return typeof(u) == "number" and Workspace:GetServerTimeNow() < u
end

local Suffixes = {K=3,M=6,B=9,T=12,Qa=15,Qi=18,Sx=21,Sp=24,Oc=27,No=30,Dc=33}
local function ParseValue(str)
	if not str then return 0 end
	str = string.gsub(tostring(str), ",", "")
	local numStr, suffix = string.match(str, "^([%d%.]+)(%a*)")
	local num = tonumber(numStr)
	if not num then return 0 end
	if suffix and Suffixes[suffix] then num = num * (10 ^ Suffixes[suffix]) end
	return num
end

local function getStrength(p)
	local s = p:FindFirstChild("leaderstats")
	return ParseValue(s and s:FindFirstChild("Strength") and s.Strength.Value or 0)
end

pcall(function()
	for _, o in pairs(game:GetDescendants()) do
		if o.Name == "RobloxForwardPortals" then o:Destroy() end
	end
	game.DescendantAdded:Connect(function(d)
		if d.Name == "RobloxForwardPortals" then d:Destroy() end
	end)
end)

-- ==========================================
-- STATE
-- ==========================================
local State = {
	Size = 2, Speed = 120, FOV = 70,
	SetSize = false, SetSpeed = false, SetFOV = false,
	LockPos = false, LockPosVec = nil,
	InfJump = false, SpinFortune = false,

	AutoRebirth = false, AutoFastRebirth = false, RebirthTarget = 0, AutoSize1 = false, AutoKing = false,
	Exercise = "Weight", AutoExercise = false, AutoSquat = false, AutoLift = false,
	SelectedSquat = nil, SelectedLift = nil, AutoRep = false, AutoRepSpeed = 10,
	AutoRock = false, SelectedRock = nil,
	PushupIndustrial = false, PushupJungle = false, PushupKing = false, PushupLegends = false,

	AutoKillBoss = false,
	AutoFarmSeconds = true,
	TimeFarm = 12,
	ContinueBoss = true,
	AutoBossChest = false,

	EatEggs = false, EatBoosts = false,
	AutoQuestFarm = false, AutoQuestCollect = false, AutoClanQuest = false,
	AutoJoinBrawl = false, AutoKillBrawl = false, AutoResetBrawl = false,

	AutoLoad = false, AutoRejoin = false, AutoReconnect = false,
	WebhookURL = "",
	WebhookPingEveryone = false,
	WebhookBossNotify = false,
	WebhookDisconnectNotify = false,
	WebhookSelectedBosses = {},

	TimeMode = "Day",
	Render3D = false,
	HidePets = false,
	HidePopups = true,
	HidePlayers = false,
	HideSound = false,
	Optimizer = false,
	WalkWater = true,
	Whitelist = {},
	Keybinds = {},
}

local RockData = {
	["Tiny Rock - 0 Dura"] = 0, ["Large Rock - 100 Dura"] = 100, ["Punching Rock - 10 Dura"] = 10,
	["Golden Rock - 5k Dura"] = 5000, ["Frost Rock - 150k Dura"] = 150000, ["Mythical Rock - 400k Dura"] = 400000,
	["Eternal Rock - 750k Dura"] = 750000, ["Legend Rock - 1m Dura"] = 1000000, ["Muscle King Rock - 5m Dura"] = 5000000,
	["Jungle Rock - 10m Dura"] = 10000000, ["Industrial Rock - 25m Dura"] = 25000000,
}

local Teleports = {
	["Tiny Island"] = CFrame.new(-37.1, 9.2, 1919),
	["Main Island"] = CFrame.new(16.07, 9.08, 133.8),
	["Beach"] = CFrame.new(-8, 9, -169.2),
	["Overcharged Gym"] = CFrame.new(-2941.766, 151.797, 4994.552),
	["Industrial Gym"] = CFrame.new(-5254.681641, 58.342850, 4931.850586),
	["Jungle Gym"] = CFrame.new(-8543, 6.8, 2400),
	["Muscle King Gym"] = CFrame.new(-8665.4, 17.21, -5792.9),
	["Legends Gym"] = CFrame.new(4516, 991.5, -3856),
	["Infernal Gym"] = CFrame.new(-6759, 7.36, -1284),
	["Mythical Gym"] = CFrame.new(2250, 7.37, 1073.2),
	["Frost Gym"] = CFrame.new(-2623, 7.36, -409),
}

local KingPos = CFrame.new(-8665.4, 17.21, -5792.9)

-- ==========================================
-- CONFIG SAVE / LOAD
-- ==========================================
local function ensureFolder()
end

local function serializeState()
	return {
		Size = State.Size, Speed = State.Speed, FOV = State.FOV,
		SetSize = State.SetSize, SetSpeed = State.SetSpeed, SetFOV = State.SetFOV,
		InfJump = State.InfJump, SpinFortune = State.SpinFortune,
		AutoRep = State.AutoRep,
		AutoRepSpeed = State.AutoRepSpeed,
		AutoKillBoss = State.AutoKillBoss,
		AutoFarmSeconds = State.AutoFarmSeconds,
		TimeFarm = State.TimeFarm,
		ContinueBoss = State.ContinueBoss,
		AutoBossChest = State.AutoBossChest,
		AutoJoinBrawl = State.AutoJoinBrawl,
		AutoKillBrawl = State.AutoKillBrawl,
		AutoResetBrawl = State.AutoResetBrawl,
		AutoLoad = State.AutoLoad, AutoRejoin = State.AutoRejoin, AutoReconnect = State.AutoReconnect,
		WebhookURL = State.WebhookURL,
		WebhookPingEveryone = State.WebhookPingEveryone,
		WebhookBossNotify = State.WebhookBossNotify,
		WebhookDisconnectNotify = State.WebhookDisconnectNotify,
		WebhookSelectedBosses = State.WebhookSelectedBosses,
		Exercise = State.Exercise, AutoExercise = State.AutoExercise,
		AutoRock = State.AutoRock, SelectedRock = State.SelectedRock,
		SelectedSquat = State.SelectedSquat, SelectedLift = State.SelectedLift,
		Dropdowns = {
			Exercise = State.Exercise,
			SelectedSquat = State.SelectedSquat,
			SelectedLift = State.SelectedLift,
			SelectedRock = State.SelectedRock,
			TimeMode = State.TimeMode,
			WebhookSelectedBosses = State.WebhookSelectedBosses,
		},
		PushupIndustrial = State.PushupIndustrial, PushupJungle = State.PushupJungle,
		PushupKing = State.PushupKing, PushupLegends = State.PushupLegends,
		EatEggs = State.EatEggs, EatBoosts = State.EatBoosts,
		AutoQuestFarm = State.AutoQuestFarm, AutoQuestCollect = State.AutoQuestCollect,
		AutoClanQuest = State.AutoClanQuest,
		TimeMode = State.TimeMode,
		Render3D = State.Render3D,
		HidePopups = State.HidePopups,
		HideSound = State.HideSound,
		Optimizer = State.Optimizer,
		WalkWater = State.WalkWater,
		Whitelist = State.Whitelist,
		Keybinds = State.Keybinds,
		HidePlayers = State.HidePlayers,
	}
end

local function applyConfig(cfg)
	if type(cfg) ~= "table" then return end
	if cfg.AutoBrawl == true then
		if cfg.AutoJoinBrawl == nil then cfg.AutoJoinBrawl = true end
		if cfg.AutoKillBrawl == nil then cfg.AutoKillBrawl = true end
		if cfg.AutoResetBrawl == nil then cfg.AutoResetBrawl = true end
	end
	if cfg.AutoBoss == true and cfg.AutoKillBoss == nil then
		cfg.AutoKillBoss = true
	end
	if cfg.AutoAllBosses ~= nil and cfg.AutoKillBoss == nil then
		cfg.AutoKillBoss = cfg.AutoAllBosses
	end
	local skipSave = {
		AutoRebirth = true, AutoFastRebirth = true, RebirthTarget = true,
		AutoSize1 = true, AutoKing = true, LockPos = true, LockPosVec = true,
		HidePlayers = true, HidePets = true,
	}
	for k, v in pairs(cfg) do
		if State[k] ~= nil and not skipSave[k] then
			State[k] = v
		end
	end
	State.HidePlayers = false
	State.HidePets = false
	if type(cfg.Dropdowns) == "table" then
		if cfg.Dropdowns.Exercise then State.Exercise = cfg.Dropdowns.Exercise end
		if cfg.Dropdowns.SelectedSquat then State.SelectedSquat = cfg.Dropdowns.SelectedSquat end
		if cfg.Dropdowns.SelectedLift then State.SelectedLift = cfg.Dropdowns.SelectedLift end
		if cfg.Dropdowns.SelectedRock then State.SelectedRock = cfg.Dropdowns.SelectedRock end
		if cfg.Dropdowns.TimeMode then State.TimeMode = cfg.Dropdowns.TimeMode end
		if cfg.Dropdowns.WebhookSelectedBosses then
			State.WebhookSelectedBosses = cfg.Dropdowns.WebhookSelectedBosses
		end
	end
	if cfg.WebhookBossRarity and (not cfg.WebhookSelectedBosses or next(cfg.WebhookSelectedBosses) == nil) then
		local r = cfg.WebhookBossRarity
		if r and r ~= "" then
			State.WebhookSelectedBosses = State.WebhookSelectedBosses or {}
			State.WebhookSelectedBosses[r] = true
		end
	end
	if type(cfg.WebhookSelectedBosses) == "table" then
		State.WebhookSelectedBosses = cfg.WebhookSelectedBosses
	end
end

local function saveConfig()
	if type(writefile) ~= "function" then return end
	ensureFolder()
	pcall(function()
		writefile(CONFIG_PATH, HttpService:JSONEncode(serializeState()))
	end)
end

local function loadConfig()
	if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
	pcall(function()
		if not isfile(CONFIG_PATH) then return end
		local data = HttpService:JSONDecode(readfile(CONFIG_PATH))
		applyConfig(data)
	end)
end

loadConfig()

local function markDirty()
	task.defer(saveConfig)
end

pcall(function()
	local ub = Window and Window.UtilityButtons
	if ub and ub.Config then
		ub.Config.MouseButton1Click:Connect(function()
			loadConfig()
			saveConfig()
			notify("Supreme Hub", "Config saved/loaded.")
		end)
	end
end)

-- ==========================================
-- FARM PRIORITY
-- ==========================================
local BossPresent = false
local PlayerInBrawl = false
local JumpOnceBrawlSeat = false
local QuestBusy = {
	CharmedBrawl = false,
	Spellbound = false,
	Arcane = false,
	Mystic = false,
	Rune = false,
}

local function bossExistsNow()
	for _, c in ipairs(CollectionService:GetTagged("BossEventBoss")) do
		if c:IsA("Model") and c:IsDescendantOf(Workspace) then
			local hitbox = c:FindFirstChild("BossDamageHitbox", true)
			if hitbox and hitbox:IsA("BasePart") then
				local stats = c:FindFirstChild("stats")
				local health = stats and stats:FindFirstChild("Health")
				local hp = health and health.Value or Workspace:GetAttribute("BossHealth") or 0
				if typeof(hp) == "number" and hp > 0 then
					return true
				end
			end
		end
	end
	return false
end

local function brawlFeatureOn()
	return State.AutoJoinBrawl or State.AutoKillBrawl or State.AutoResetBrawl
end

local function findBossChestPrompt()
	local chest = Workspace:FindFirstChild("BossChest")
	if not chest then return nil end
	local rootPart = chest:FindFirstChild("Root") or chest:FindFirstChild("HumanoidRootPart")
	local prompt = rootPart and rootPart:FindFirstChild("bossChestPrompt")
	if not prompt then
		prompt = chest:FindFirstChild("bossChestPrompt", true)
	end
	if prompt and prompt:IsA("ProximityPrompt") then
		return chest, rootPart or prompt.Parent, prompt
	end
	return nil
end

local function canRunBoss()
	return State.AutoKillBoss == true and BossPresent == true
end

local function questBlocking()
	if not State.AutoQuestFarm then return false end
	if QuestBusy.Arcane or QuestBusy.Mystic or QuestBusy.Rune then
		return true
	end
	if QuestBusy.Spellbound then
		if State.AutoKillBoss and BossPresent then
			return false
		end
		return true
	end
	return false
end

local function bossBlocking()
	return canRunBoss()
end

local function canRunJoinBrawl()
	if not State.AutoJoinBrawl then return false end
	if bossBlocking() then return false end
	if questBlocking() then return false end
	return true
end

local function canRunKillBrawl()
	if not State.AutoKillBrawl then return false end
	if bossBlocking() then return false end
	if questBlocking() then return false end
	return true
end

local function canRunResetBrawl()
	if not State.AutoResetBrawl then return false end
	if bossBlocking() then return false end
	if questBlocking() then return false end
	return true
end

local function canRunRebirth()
	if not State.AutoRebirth then return false end
	if State.AutoFastRebirth then return false end
	if bossBlocking() then return false end
	if questBlocking() then return false end
	if brawlFeatureOn() and PlayerInBrawl then return false end
	return true
end

local function canRunFastRebirth()
	if not State.AutoFastRebirth then return false end
	if bossBlocking() then return false end
	if questBlocking() then return false end
	if brawlFeatureOn() and PlayerInBrawl then return false end
	return true
end

local function canRunOtherFarm()
	if bossBlocking() then return false end
	if questBlocking() then return false end
	if brawlFeatureOn() and PlayerInBrawl then return false end
	return true
end

local function firePrompt(prompt, times)
	times = times or 1
	if not prompt then return end
	for _ = 1, times do
		pcall(function()
			if fireproximityprompt then
				fireproximityprompt(prompt)
			else
				prompt:InputHoldBegin()
				task.wait(prompt.HoldDuration or 0.1)
				prompt:InputHoldEnd()
			end
		end)
		task.wait(0.15)
	end
end

local function hideBossPrompts()
	pcall(function()
		local events = Workspace:FindFirstChild("Events")
		local arena = events and events:FindFirstChild("BossArena")
		if arena then
			local board = arena:FindFirstChild("Board")
			local ad = board and board:FindFirstChild("Inner") and board.Inner:FindFirstChild("Front") and board.Inner.Front:FindFirstChild("AdPart")
			local rp = ad and ad:FindFirstChild("bossRewardsPrompt")
			if rp and rp:IsA("ProximityPrompt") then rp.Enabled = false end
			local refresh = arena:FindFirstChild("RefreshBoss")
			local podium = refresh and refresh:FindFirstChild("Podium")
			local cube = podium and (podium:FindFirstChild("Cube.001") or podium:FindFirstChild("Cube"))
			local bp = cube and cube:FindFirstChild("bossRefreshPrompt")
			if bp and bp:IsA("ProximityPrompt") then bp.Enabled = false end
		end
	end)
end

task.spawn(function()
	while true do
		pcall(function() BossPresent = bossExistsNow() end)
		task.wait(0.25)
	end
end)

local function inBossArena(pos)
	local events = Workspace:FindFirstChild("Events")
	local arena = events and events:FindFirstChild("BossArena")
	if not arena or not pos then return false end
	local ok, cf, size = pcall(function()
		if arena:IsA("BasePart") then
			return arena.CFrame, arena.Size
		end
		if arena:IsA("Model") then
			return arena:GetBoundingBox()
		end
		return nil, nil
	end)
	if not ok or not cf or not size then return false end
	local localPos = cf:PointToObjectSpace(pos)
	local half = size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z
end

task.spawn(function()
	while true do
		if State.AutoBossChest then
			hideBossPrompts()
			local r = root()
			local inside = r and inBossArena(r.Position)
			local _, part, prompt = findBossChestPrompt()
			if prompt and r and part and part:IsA("BasePart") then
				local dist = (r.Position - part.Position).Magnitude
				local allow = false
				if inside then
					if inBossArena(part.Position) then
						pcall(function()
							prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 0, 400)
						end)
						allow = true
					end
				elseif dist <= 300 then
					pcall(function()
						prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 0, 300)
					end)
					allow = true
				end
				if allow then firePrompt(prompt, 5) end
			end
			task.wait(inside and 1 or 20)
		else
			task.wait(0.5)
		end
	end
end)

local function hasInteractSeat()
	local h = hum()
	local miu = LocalPlayer:FindFirstChild("machineInUse")
	if miu and miu.Value ~= nil and miu.Value ~= false and tostring(miu.Value) ~= "" and tostring(miu.Value) ~= "nil" then
		return true
	end
	if h and (h.SeatPart ~= nil or h.Sit == true) then
		return true
	end
	return false
end

task.spawn(function()
	while true do
		if PlayerInBrawl then
			local h = hum()
			if h and hasInteractSeat() then
				if not JumpOnceBrawlSeat then
					h.Jump = true
					pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
					pcall(function() h.Sit = false end)
					JumpOnceBrawlSeat = true
				end
			else
				JumpOnceBrawlSeat = false
			end
		else
			JumpOnceBrawlSeat = false
		end
		task.wait(0.2)
	end
end)

-- Boss hide players
local BossFarmHideActive = false
local bossHiddenParts = {}
local bossHiddenGuis = {}
local bossHiddenCanCollide = {}

local function findBoss()
	for _, c in ipairs(CollectionService:GetTagged("BossEventBoss")) do
		if c:IsA("Model") and c:IsDescendantOf(Workspace) then
			local hitbox = c:FindFirstChild("BossDamageHitbox", true)
			if hitbox and hitbox:IsA("BasePart") then
				local stats = c:FindFirstChild("stats")
				local health = stats and stats:FindFirstChild("Health")
				local hp = health and health.Value or Workspace:GetAttribute("BossHealth") or 0
				if typeof(hp) == "number" and hp > 0 then return c, hitbox end
			end
		end
	end
end

local function bossHidePlayersOn()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local ch = p.Character
			for _, part in ipairs(ch:GetDescendants()) do
				if part:IsA("BasePart") then
					if bossHiddenParts[part] == nil then
						bossHiddenParts[part] = part.LocalTransparencyModifier
						part.LocalTransparencyModifier = 1
					end
					if bossHiddenCanCollide[part] == nil then
						bossHiddenCanCollide[part] = part.CanCollide
						part.CanCollide = false
					end
					if part.Name == "HumanoidRootPart" or string.find(string.lower(part.Name), "hitbox") then
						part.LocalTransparencyModifier = 1
						part.CanCollide = false
					end
				elseif part:IsA("Decal") or part:IsA("Texture") then
					if bossHiddenParts[part] == nil then
						bossHiddenParts[part] = part.Transparency
						part.Transparency = 1
					end
				elseif part:IsA("BillboardGui") and (part.Name == "nameGui" or string.lower(part.Name):find("name")) then
					if bossHiddenGuis[part] == nil then
						bossHiddenGuis[part] = part.Enabled
						part.Enabled = false
					end
				end
			end
			local head = ch:FindFirstChild("Head")
			if head then
				local ng = head:FindFirstChild("nameGui")
				if ng and ng:IsA("BillboardGui") and bossHiddenGuis[ng] == nil then
					bossHiddenGuis[ng] = ng.Enabled
					ng.Enabled = false
				end
			end
		end
	end
end

local function bossHidePlayersOff()
	for part, old in pairs(bossHiddenParts) do
		pcall(function()
			if part and part.Parent then
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = old
				elseif part:IsA("Decal") or part:IsA("Texture") then
					part.Transparency = old
				end
			end
		end)
	end
	table.clear(bossHiddenParts)
	for part, old in pairs(bossHiddenCanCollide) do
		pcall(function()
			if part and part.Parent and part:IsA("BasePart") then
				part.CanCollide = old
			end
		end)
	end
	table.clear(bossHiddenCanCollide)
	for gui, old in pairs(bossHiddenGuis) do
		pcall(function()
			if gui and gui.Parent then
				gui.Enabled = old
			end
		end)
	end
	table.clear(bossHiddenGuis)
end

task.spawn(function()
	while true do
		local farming = canRunBoss() and findBoss() ~= nil
		if farming then
			BossFarmHideActive = true
			bossHidePlayersOn()
		else
			if BossFarmHideActive then
				BossFarmHideActive = false
				bossHidePlayersOff()
			end
		end
		task.wait(0.4)
	end
end)

-- ==========================================
-- COMBAT / MOVEMENT
-- ==========================================
LocalPlayer.CharacterAdded:Connect(function(c)
	c:WaitForChild("HumanoidRootPart", 5)
	if State.LockPos and c:FindFirstChild("HumanoidRootPart") then
		State.LockPosVec = c.HumanoidRootPart.Position
	end
end)

task.spawn(function()
	while true do
		if State.SetSize then
			pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", State.Size) end)
		end
		if State.SetSpeed then
			pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSpeed", State.Speed) end)
		end
		if State.SetFOV and Camera then Camera.FieldOfView = State.FOV end
		if State.LockPos and State.LockPosVec then
			local r = root()
			if r then
				local bp = r:FindFirstChild("PositionLocker")
				if bp then bp.Position = State.LockPosVec
				else
					bp = Instance.new("BodyPosition")
					bp.Name = "PositionLocker"
					bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					bp.Position = State.LockPosVec
					bp.P = 100000
					bp.Parent = r
				end
			end
		end
		task.wait(0.05)
	end
end)

UserInputService.JumpRequest:Connect(function()
	if State.InfJump then
		local h = hum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

task.spawn(function()
	local parts = {}
	local ps, td = 2048, 40000
	local st = Vector3.new(-2, -9.5, -2)
	for x = 0, math.ceil(td/ps)-1 do
		for z = 0, math.ceil(td/ps)-1 do
			for _, o in ipairs({{x*ps,z*ps},{-x*ps,z*ps},{-x*ps,-z*ps},{x*ps,-z*ps}}) do
				local p = Instance.new("Part")
				p.Size = Vector3.new(ps, 1, ps)
				p.Position = st + Vector3.new(o[1], 0, o[2])
				p.Anchored = true
				p.Transparency = 1
				p.CanCollide = State.WalkWater
				p.Name = "MLWater"
				p.Parent = Workspace
				table.insert(parts, p)
			end
		end
	end
	_G.MLWater = parts
end)

-- Rebirth
task.spawn(function()
	while true do
		if canRunRebirth() and State.RebirthTarget > 0 then
			local rb = LocalPlayer.leaderstats and LocalPlayer.leaderstats:FindFirstChild("Rebirths")
			if rb and rb.Value < State.RebirthTarget then
				pcall(function() ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest") end)
			end
			task.wait(0.05)
		else task.wait(0.3) end
	end
end)

task.spawn(function()
	while true do
		if canRunOtherFarm() and State.AutoSize1 then
			pcall(function() ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 1) end)
		end
		task.wait(0.05)
	end
end)

task.spawn(function()
	while true do
		if canRunOtherFarm() and State.AutoKing then
			local r, h = root(), hum()
			if r and h and h.Health > 0 and (r.Position - KingPos.Position).Magnitude > 5 then
				pcall(function() r.CFrame = KingPos end)
			end
			task.wait(0.1)
		else task.wait(0.3) end
	end
end)

task.spawn(function()
	while true do
		if canRunOtherFarm() and State.AutoExercise and State.Exercise then
			local c, h = char(), hum()
			if c and h and h.Health > 0 then
				if not c:FindFirstChild(State.Exercise) then
					local t = LocalPlayer.Backpack:FindFirstChild(State.Exercise)
					if t then pcall(function() h:EquipTool(t) end) task.wait(0.2) end
				end
				if c:FindFirstChild(State.Exercise) then fireRep() end
			end
			task.wait()
		else task.wait(0.2) end
	end
end)

task.spawn(function()
	while true do
		if canRunOtherFarm() and State.AutoRep then
			local speed = math.clamp(tonumber(State.AutoRepSpeed) or 10, 1, 600)
			fireRep()
			task.wait(1 / speed)
		else task.wait(0.3) end
	end
end)

local function getInteract(machine)
	for _, d in ipairs(machine:GetDescendants()) do
		if d:IsA("BasePart") and string.lower(d.Name) == "interactseat" then return d end
	end
end

local function enterMachine(machine)
	if not machine or not machine.Parent then return false end
	local r = root()
	local part = getInteract(machine)
	if not r or not part then return false end
	r.CFrame = part.CFrame * CFrame.new(0, 3, 0)
	r.AssemblyLinearVelocity = Vector3.zero
	task.wait(0.4)
	if VirtualInputManager then
		pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)
		task.wait(0.1)
		pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
	end
	task.wait(0.4)
	return true
end

local SquatChoices, LiftChoices = {}, {}
local SquatNames, LiftNames = {}, {}
pcall(function()
	local folder = Workspace:FindFirstChild("machinesFolder") or Workspace:WaitForChild("machinesFolder", 3)
	if not folder then return end
	local squatsByName = {}
	for _, m in ipairs(folder:GetChildren()) do
		local ln = string.lower(m.Name)
		if string.find(ln, "squat", 1, true) and ln ~= "squat rack" then
			squatsByName[m.Name] = squatsByName[m.Name] or {}
			table.insert(squatsByName[m.Name], m)
		elseif string.find(ln, "lift", 1, true) and ln ~= "deadlift" then
			LiftChoices[m.Name] = m
			table.insert(LiftNames, m.Name)
		end
	end
	for n, list in pairs(squatsByName) do
		SquatChoices[n] = list[1]
		table.insert(SquatNames, n)
	end
	table.sort(SquatNames)
	table.sort(LiftNames)
end)

local machineState = {
	Squat = {Running = false, Active = nil, Seat = nil, Reenter = 0},
	Lift = {Running = false, Active = nil, Seat = nil, Reenter = 0},
}

local function isOnMachine()
	local h = hum()
	if not h then return false end
	if h.SeatPart ~= nil or h.Sit == true then return true end
	local miu = LocalPlayer:FindFirstChild("machineInUse")
	if miu and miu.Value ~= nil and miu.Value ~= false and tostring(miu.Value) ~= "" and tostring(miu.Value) ~= "nil" then
		return true
	end
	return false
end

local function runMachine(kind)
	local ms = machineState[kind]
	task.spawn(function()
		local lastChar = char()
		while ms.Running do
			if canRunOtherFarm() then
				local c, h = char(), hum()
				if c ~= lastChar then
					lastChar = c
					ms.Active = nil
					ms.Seat = nil
					ms.Reenter = 0
				end
				if not c or not h or h.Health <= 0 then
					ms.Active = nil
					ms.Seat = nil
					task.wait(0.15)
				else
					if isOnMachine() then
						ms.Active = ms.Active or true
						ms.Seat = h.SeatPart
						fireRep()
						task.wait(0.05)
					else
						ms.Active = nil
						ms.Seat = nil
						if os.clock() >= (ms.Reenter or 0) then
							local selected = (kind == "Squat" and State.SelectedSquat and SquatChoices[State.SelectedSquat])
								or (kind == "Lift" and State.SelectedLift and LiftChoices[State.SelectedLift])
							if not selected then
								if kind == "Squat" then
									for _, m in pairs(SquatChoices) do selected = m break end
								else
									for _, m in pairs(LiftChoices) do selected = m break end
								end
							end
							if selected then
								local ok = enterMachine(selected)
								if ok and isOnMachine() then
									ms.Active = selected
									ms.Seat = h.SeatPart
									ms.Reenter = 0
								else
									ms.Reenter = os.clock() + 0.6
								end
							else
								ms.Reenter = os.clock() + 1
							end
						end
						task.wait(0.15)
					end
				end
			else
				task.wait(0.25)
			end
		end
	end)
end

local function machineJumpOnce()
	pcall(function()
		local h = hum()
		if h then
			h.Jump = true
			h:ChangeState(Enum.HumanoidStateType.Jumping)
			h.Sit = false
		end
	end)
end

task.spawn(function()
	while true do
		if canRunOtherFarm() and State.AutoRock and State.SelectedRock and RockData[State.SelectedRock] ~= nil then
			local need = RockData[State.SelectedRock]
			local dura = LocalPlayer:FindFirstChild("Durability")
			if dura and typeof(dura.Value) == "number" and dura.Value >= need then
				local folder = Workspace:FindFirstChild("machinesFolder")
				if folder then
					for _, v in pairs(folder:GetDescendants()) do
						if v.Name == "neededDurability" and v.Value == need
							and v.Parent and v.Parent:FindFirstChild("Rock") then
							local L = char() and char():FindFirstChild("LeftHand")
							local R = char() and char():FindFirstChild("RightHand")
							if L and R then
								safeTouch(v.Parent.Rock, R, 0) safeTouch(v.Parent.Rock, R, 1)
								safeTouch(v.Parent.Rock, L, 0) safeTouch(v.Parent.Rock, L, 1)
								equipPunch() firePunch()
							end
						end
					end
				end
			end
			task.wait(0.12)
		else task.wait(0.3) end
	end
end)

local StrengthConfigs = {
	{key = "PushupIndustrial", tool = "Pushups", rock = "Industrial Rock"},
	{key = "PushupJungle", tool = "Pushups", rock = "Ancient Jungle Rock"},
	{key = "PushupKing", tool = "Pushups", rock = "Muscle King Mountain"},
	{key = "PushupLegends", tool = "Pushups", rock = "Rock Of Legends"},
}

for _, cfg in ipairs(StrengthConfigs) do
	task.spawn(function()
		while true do
			if canRunOtherFarm() and State[cfg.key] then
				local c, h = char(), hum()
				if c and h then
					if LocalPlayer.Backpack:FindFirstChild(cfg.tool) and not c:FindFirstChild(cfg.tool) then
						pcall(function() h:EquipTool(LocalPlayer.Backpack[cfg.tool]) end)
					end
					fireRep()
					local folder = Workspace:FindFirstChild("machinesFolder")
					if folder and folder:FindFirstChild(cfg.rock) and c:FindFirstChild("LeftHand") then
						safeTouch(folder[cfg.rock].Rock, c.LeftHand, 0)
						safeTouch(folder[cfg.rock].Rock, c.LeftHand, 1)
					end
					if LocalPlayer.Backpack:FindFirstChild("Punch") then
						pcall(function() h:EquipTool(LocalPlayer.Backpack.Punch) end)
						firePunch()
					end
					RunService.RenderStepped:Wait()
					if LocalPlayer.Backpack:FindFirstChild(cfg.tool) then
						pcall(function() h:EquipTool(LocalPlayer.Backpack[cfg.tool]) end)
					end
				else task.wait(0.1) end
			else task.wait(0.3) end
		end
	end)
end

task.spawn(function()
	while true do
		if State.SpinFortune then
			pcall(function()
				local remote = ReplicatedStorage.rEvents:FindFirstChild("openFortuneWheelRemote")
				local chances = ReplicatedStorage.shared.catalogs.fortuneWheelChances["Fortune Wheel"]
				if remote and chances then remote:InvokeServer("openFortuneWheel", chances) end
			end)
			task.wait(1)
		else task.wait(0.5) end
	end
end)

-- Boss farm
local BossPrepUntil = 0
local BossPrepActive = false
local BossPrepForModel = nil
local BossJumpDone = false
local BossFarmSecondsJumpDone = false

local function doBossJump()
	pcall(function()
		local h = hum()
		if h then
			h.Jump = true
			h:ChangeState(Enum.HumanoidStateType.Jumping)
			h.Sit = false
		end
	end)
end

task.spawn(function()
	while true do
		if canRunBoss() then
			local model, hitbox = findBoss()
			if model and hitbox then
				if BossPrepForModel ~= model then
					BossPrepForModel = model
					BossJumpDone = false
					BossFarmSecondsJumpDone = false
					if State.AutoFarmSeconds then
						doBossJump()
						BossFarmSecondsJumpDone = true
						local secs = tonumber(State.TimeFarm) or 12
						secs = math.clamp(secs, 5, 100)
						BossPrepUntil = os.clock() + secs
						BossPrepActive = true
					else
						BossPrepActive = false
						BossPrepUntil = 0
					end
				end
				if State.AutoFarmSeconds and BossPrepActive and os.clock() < BossPrepUntil then
					local h = hum()
					local bp = LocalPlayer:FindFirstChild("Backpack")
					local ch = char()
					local tool = (ch and ch:FindFirstChild("Pushups"))
						or (bp and bp:FindFirstChild("Pushups"))
					if tool and h and tool.Parent ~= ch then
						pcall(function() h:EquipTool(tool) end)
					end
					pcall(function()
						local ev = LocalPlayer:FindFirstChild("muscleEvent")
						if ev then ev:FireServer("rep") else fireRep() end
					end)
					task.wait(0.01)
				else
					BossPrepActive = false
					if not BossJumpDone then
						doBossJump()
						BossJumpDone = true
					end
					local c, r, h = char(), root(), hum()
					if r and h and h.Health > 0 then
						local head = model:FindFirstChild("Head", true)
						local center = (head and head:IsA("BasePart") and head.Position)
							or (hitbox.Position + Vector3.new(0, hitbox.Size.Y * 0.35, 0))
						r.CFrame = CFrame.lookAt(center, center + hitbox.CFrame.LookVector)
						r.AssemblyLinearVelocity = Vector3.zero
						equipPunch()
						local L = c and c:FindFirstChild("LeftHand")
						local R = c and c:FindFirstChild("RightHand")
						if L then safeTouch(hitbox, L, 0) safeTouch(hitbox, L, 1) end
						if R then safeTouch(hitbox, R, 0) safeTouch(hitbox, R, 1) end
						firePunch()
					end
					task.wait(0.03)
				end
			else
				BossPrepForModel = nil
				BossPrepActive = false
				BossJumpDone = false
				BossFarmSecondsJumpDone = false
				task.wait(0.25)
			end
		else
			BossPrepForModel = nil
			BossPrepActive = false
			BossJumpDone = false
			BossFarmSecondsJumpDone = false
			task.wait(0.3)
		end
	end
end)

task.spawn(function()
	while true do
		if State.EatEggs then
			local t = (char() and char():FindFirstChild("Protein Egg")) or LocalPlayer.Backpack:FindFirstChild("Protein Egg")
			if t then pcall(function() muscleEv():FireServer("proteinEgg", t) end) end
			task.wait(0.25)
		else task.wait(0.5) end
	end
end)

task.spawn(function()
	local items = {"Tropical Shake","Energy Shake","Protein Bar","TOUGH Bar","Protein Shake","ULTRA Shake","Energy Bar"}
	while true do
		if State.EatBoosts then
			for _, name in ipairs(items) do
				local t = (char() and char():FindFirstChild(name)) or LocalPlayer.Backpack:FindFirstChild(name)
				if t then
					local parts = {}
					for w in name:gmatch("%S+") do table.insert(parts, w:lower()) end
					for i = 2, #parts do parts[i] = parts[i]:sub(1,1):upper() .. parts[i]:sub(2) end
					for _ = 1, 10 do pcall(function() muscleEv():FireServer(table.concat(parts), t) end) end
				end
			end
			task.wait(0.15)
		else task.wait(0.5) end
	end
end)

-- Brawl
local BrawlAreas = {
	{Pos = Vector3.new(4465, 177, -8851), Size = Vector3.new(562, 410, 558)},
	{Pos = Vector3.new(-1856.5, 175, -6315), Size = Vector3.new(509, 410, 506)},
	{Pos = Vector3.new(978, 177, -7433), Size = Vector3.new(512, 410, 514)},
}
local function inBrawl(pos)
	for _, a in ipairs(BrawlAreas) do
		local o = pos - a.Pos
		local h = a.Size / 2
		if math.abs(o.X) <= h.X and math.abs(o.Y) <= h.Y and math.abs(o.Z) <= h.Z then return true end
	end
	return false
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "MLBrawlESP"
pcall(function()
	if gethui then ESPFolder.Parent = gethui() else ESPFolder.Parent = CoreGui end
end)
if not ESPFolder.Parent then ESPFolder.Parent = CoreGui end

local function updESP(p, weak)
	local e = ESPFolder:FindFirstChild(p.Name)
	if not e then
		e = Instance.new("Folder")
		e.Name = p.Name
		e.Parent = ESPFolder
		local hl = Instance.new("Highlight")
		hl.Name = "Highlight"
		hl.FillTransparency = 0.5
		hl.Parent = e
		local bg = Instance.new("BillboardGui")
		bg.Name = "NameTag"
		bg.Size = UDim2.new(0, 100, 0, 25)
		bg.StudsOffset = Vector3.new(0, 2.5, 0)
		bg.AlwaysOnTop = true
		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.TextColor3 = Color3.new(1, 1, 1)
		txt.TextStrokeTransparency = 0
		txt.Font = Enum.Font.GothamBold
		txt.TextSize = 14
		txt.Parent = bg
		bg.Parent = e
	end
	local hl = e:FindFirstChild("Highlight")
	if hl then hl.Adornee = p.Character; hl.FillColor = weak and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0) end
	local bg = e:FindFirstChild("NameTag")
	if bg then
		bg.Adornee = p.Character and p.Character:FindFirstChild("Head")
		local t = bg:FindFirstChildOfClass("TextLabel")
		if t then t.Text = p.Name end
	end
end

task.spawn(function()
	while true do
		local r = root()
		if r and inBrawl(r.Position) then
			PlayerInBrawl = true
		else
			if not (root() and inBrawl(root().Position)) then
				PlayerInBrawl = false
			end
		end
		task.wait(0.25)
	end
end)

task.spawn(function()
	while true do
		if canRunJoinBrawl() then
			pcall(function() ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl") end)
			task.wait(2)
		else task.wait(0.5) end
	end
end)

task.spawn(function()
	local aggro = {}
	while true do
		if canRunKillBrawl() then
			local c, r, h = char(), root(), hum()
			if c and r and h and h.Health > 0 then
				local myPos = r.Position
				local myMap = LocalPlayer:FindFirstChild("currentMap") and LocalPlayer.currentMap.Value
				local myStr = getStrength(LocalPlayer)
				if inBrawl(myPos) then
					PlayerInBrawl = true
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= LocalPlayer and isAlive(p) and inBrawl(p.Character.HumanoidRootPart.Position) then
							local skip = false
							for _, wn in ipairs(State.Whitelist or {}) do
								if string.lower(tostring(wn)) == string.lower(p.Name) or string.lower(tostring(wn)) == string.lower(p.DisplayName) then
									skip = true; break
								end
							end
							if not skip then aggro[p] = true end
						end
					end
					local weakT, strongT = nil, nil
					local dW, dS = math.huge, math.huge
					local cur = {}
					for p, _ in pairs(aggro) do
						if p.Parent and isAlive(p) then
							local tm = p:FindFirstChild("currentMap") and p.currentMap.Value
							if tm == myMap then
								local weak = getStrength(p) < myStr
								updESP(p, weak)
								cur[p.Name] = true
								local d = (myPos - p.Character.HumanoidRootPart.Position).Magnitude
								if weak then if d < dW then dW = d; weakT = p.Character end
								else if d < dS then dS = d; strongT = p.Character end end
							else aggro[p] = nil end
						else aggro[p] = nil end
					end
					for _, e in ipairs(ESPFolder:GetChildren()) do
						if not cur[e.Name] then e:Destroy() end
					end
					local alvo = weakT or strongT
					if not alvo then
						local best, bd = nil, math.huge
						for _, p in ipairs(Players:GetPlayers()) do
							if p ~= LocalPlayer and isAlive(p) then
								local skip = false
								for _, wn in ipairs(State.Whitelist or {}) do
									if string.lower(tostring(wn)) == string.lower(p.Name) or string.lower(tostring(wn)) == string.lower(p.DisplayName) then
										skip = true
										break
									end
								end
								local tm = p:FindFirstChild("currentMap") and p.currentMap.Value
								local pp = p.Character.HumanoidRootPart.Position
								if not skip and tm == myMap and (inBrawl(pp) or tm == myMap) then
									local d = (myPos - pp).Magnitude
									if d < bd then bd = d; best = p.Character end
								end
							end
						end
						alvo = best
					end
					if alvo and alvo:FindFirstChild("HumanoidRootPart") then
						local goal = alvo.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
						local dist = (r.Position - goal.Position).Magnitude
						if dist > 12 then
							local dur = math.clamp(dist / 220, 0.2, 2.2)
							local tw = TweenService:Create(r, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = goal})
							tw:Play()
							pcall(function() tw.Completed:Wait() end)
						else
							pcall(function() c:SetPrimaryPartCFrame(goal) end)
						end
						equipPunch()
						local punch = c:FindFirstChild("Punch")
						if punch then pcall(function() punch:Activate() end) end
						for _ = 1, 4 do firePunch() end
					end
				else
					local center = BrawlAreas[1].Pos
					local bd = math.huge
					for _, a in ipairs(BrawlAreas) do
						local d = (myPos - a.Pos).Magnitude
						if d < bd then bd = d; center = a.Pos end
					end
					local goal = CFrame.new(center + Vector3.new(0, 6, 0))
					local dur = math.clamp(bd / 220, 0.25, 2.4)
					local tw = TweenService:Create(r, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = goal})
					tw:Play()
					pcall(function() tw.Completed:Wait() end)
				end
			end
			task.wait(0.05)
		else
			PlayerInBrawl = false
			ESPFolder:ClearAllChildren()
			task.wait(0.3)
		end
	end
end)

task.spawn(function()
	while true do
		if canRunResetBrawl() then
			pcall(function()
				local gui = LocalPlayer.PlayerGui:FindFirstChild("gameGui")
				if gui then
					local sb = gui:FindFirstChild("survivorBonusLabel")
					local nb = gui:FindFirstChild("noBrawlersLabel")
					if (sb and sb.Visible) and not (nb and nb.Visible) then
						local h = hum()
						if h and h.Health > 0 then h.Health = 0 task.wait(5) end
					end
				end
			end)
			task.wait(0.5)
		else task.wait(0.5) end
	end
end)

-- ==========================================
-- MISC: Hides / Optimizer
-- ==========================================
local function setRender3D(on)
	State.Render3D = on
	markDirty()
end

local function applyHidePets()
	pcall(function()
		ReplicatedStorage.rEvents.showPetsEvent:FireServer(State.HidePets and "hidePets" or "showPets")
	end)
end

local function applyHidePopups()
	pcall(function()
		ReplicatedStorage.rEvents.savePlayerSizeEvent:FireServer("showPopupsOption")
	end)
end

local hiddenPlayerParts = {}
local hiddenNameGuis = {}

local function remember(inst, data)
	if hiddenPlayerParts[inst] == nil then
		hiddenPlayerParts[inst] = data
		return true
	end
	return false
end

local function hideCharacterVisuals(character)
	if not character then return end
	local humObj = character:FindFirstChildOfClass("Humanoid")
	if humObj and remember(humObj, {
		DisplayDistanceType = humObj.DisplayDistanceType,
		NameDisplayDistance = humObj.NameDisplayDistance,
		HealthDisplayDistance = humObj.HealthDisplayDistance,
	}) then
		humObj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humObj.NameDisplayDistance = 0
		humObj.HealthDisplayDistance = 0
	end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if remember(part, {LocalTransparencyModifier = part.LocalTransparencyModifier, CanQuery = part.CanQuery, CanTouch = part.CanTouch}) then
				part.LocalTransparencyModifier = 1
				part.CanQuery = false
				part.CanTouch = false
			end
		elseif part:IsA("Decal") or part:IsA("Texture") then
			if remember(part, {Transparency = part.Transparency}) then
				part.Transparency = 1
			end
		elseif part:IsA("BillboardGui") or part:IsA("SurfaceGui") or part:IsA("Highlight") then
			if remember(part, {Enabled = part.Enabled}) then
				part.Enabled = false
			end
		elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") or part:IsA("Smoke") or part:IsA("Fire") or part:IsA("Sparkles") or part:IsA("Light") then
			if remember(part, {Enabled = part.Enabled}) then
				part.Enabled = false
			end
		end
	end
end

local function restoreCharacterVisuals()
	for inst, data in pairs(hiddenPlayerParts) do
		pcall(function()
			if inst and inst.Parent and type(data) == "table" then
				for k, v in pairs(data) do
					inst[k] = v
				end
			end
		end)
	end
	table.clear(hiddenPlayerParts)
	table.clear(hiddenNameGuis)
end

local function applyHidePlayers()
	if not State.HidePlayers then
		restoreCharacterVisuals()
		return
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			hideCharacterVisuals(p.Character)
		end
	end
end

Players.PlayerRemoving:Connect(function(p)
	if p.Character then
		for _, d in ipairs(p.Character:GetDescendants()) do
			hiddenPlayerParts[d] = nil
			hiddenNameGuis[d] = nil
		end
	end
end)

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(ch)
		if State.HidePlayers and p ~= LocalPlayer then
			task.wait(0.5)
			hideCharacterVisuals(ch)
		end
	end)
end)

local mutedSounds = {}
local function applyHideSound()
	for _, s in ipairs(Workspace:GetDescendants()) do
		if s:IsA("Sound") then
			local isMine = s:IsDescendantOf(char() or LocalPlayer)
			if State.HideSound and not isMine then
				if mutedSounds[s] == nil then
					mutedSounds[s] = s.Volume
					s.Volume = 0
				end
			elseif mutedSounds[s] ~= nil then
				s.Volume = mutedSounds[s]
				mutedSounds[s] = nil
			end
		end
	end
	for _, s in ipairs(SoundService:GetDescendants()) do
		if s:IsA("Sound") then
			if State.HideSound then
				if mutedSounds[s] == nil then
					mutedSounds[s] = s.Volume
					s.Volume = 0
				end
			elseif mutedSounds[s] ~= nil then
				s.Volume = mutedSounds[s]
				mutedSounds[s] = nil
			end
		end
	end
end

local function applyOptimizer()
	if State.Optimizer then
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end)
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
		end)
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
				or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
				obj.Enabled = false
				obj:SetAttribute("SH_Opt", true)
			end
		end
	else
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:GetAttribute("SH_Opt") then
				if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
					or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
					obj.Enabled = true
				end
				obj:SetAttribute("SH_Opt", nil)
			end
		end
	end
end

task.spawn(function()
	while true do
		if State.HidePlayers then applyHidePlayers() end
		if State.HideSound then applyHideSound() end
		task.wait(1)
	end
end)

task.defer(function()
	applyHidePets()
	if State.Render3D then setRender3D(true) end
	if State.Optimizer then applyOptimizer() end
	if State.TimeMode then
		local map = {Day = 9, Noon = 12, Afternoon = 16, Night = 0, Midnight = 2}
		Lighting.ClockTime = map[State.TimeMode] or 9
	end
end)

-- ==========================================
-- SERVER
-- ==========================================
local function setupQueueOnTeleport()
	if not State.AutoLoad then return end
	if type(queue_on_teleport) ~= "function" then return end
	local code = [=[
		repeat task.wait() until game:IsLoaded()
		local Players = game:GetService("Players")
		repeat task.wait() until Players.LocalPlayer
		task.wait(2)
		local function tryLoad(src)
			if type(src) == "string" and #src > 50 then
				local fn, err = loadstring(src)
				if fn then fn() return true end
			end
			return false
		end
		local loaded = false
		pcall(function()
			if readfile and isfile and isfile("SupremeHub/MuscleLegends.lua") then
				loaded = tryLoad(readfile("SupremeHub/MuscleLegends.lua"))
			end
		end)
		if not loaded then
			pcall(function()
				if getgenv and getgenv().SupremeHubSource then
					loaded = tryLoad(getgenv().SupremeHubSource)
				end
			end)
		end
	]=]
	pcall(function() queue_on_teleport(code) end)
end

local function serverHop()
	notify("Supreme Hub", "Server hopping...")
	setupQueueOnTeleport()
	pcall(function()
		local placeId = game.PlaceId
		local cursor = ""
		local servers = {}
		for _ = 1, 5 do
			local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and ("&cursor=" .. cursor) or "")
			local body = game:HttpGet(url)
			local data = HttpService:JSONDecode(body)
			if data and data.data then
				for _, s in ipairs(data.data) do
					if s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.id then
						table.insert(servers, s.id)
					end
				end
				cursor = data.nextPageCursor or ""
				if cursor == "" then break end
			else
				break
			end
		end
		if #servers == 0 then
			TeleportService:Teleport(placeId, LocalPlayer)
			return
		end
		local id = servers[math.random(1, #servers)]
		TeleportService:TeleportToPlaceInstance(placeId, id, LocalPlayer)
	end)
end

task.spawn(function()
	local start = os.clock()
	while true do
		task.wait(30)
		if State.AutoRejoin then
			if os.clock() - start >= 3600 then
				notify("Supreme Hub", "Auto rejoin (1h)")
				setupQueueOnTeleport()
				pcall(function()
					TeleportService:Teleport(game.PlaceId, LocalPlayer)
				end)
				start = os.clock()
			end
		else
			start = os.clock()
		end
	end
end)

local reconnecting = false
local function doReconnect(reason)
	if not State.AutoReconnect then return end
	if reconnecting then return end
	reconnecting = true
	notify("Supreme Hub", "Auto Reconnect: " .. tostring(reason or "network"))
	setupQueueOnTeleport()
	pcall(function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end)
	task.delay(8, function() reconnecting = false end)
end

pcall(function()
	local GuiService = game:GetService("GuiService")
	GuiService.ErrorMessageChanged:Connect(function(msg)
		if not State.AutoReconnect then return end
		if msg and tostring(msg) ~= "" then
			doReconnect("error")
		end
	end)
end)

task.spawn(function()
	while true do
		if State.AutoReconnect then
			pcall(function()
				local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
				if promptGui then
					local overlay = promptGui:FindFirstChild("promptOverlay") or promptGui
					for _, d in ipairs(overlay:GetDescendants()) do
						if d:IsA("TextLabel") or d:IsA("TextButton") then
							local t = string.lower(tostring(d.Text or ""))
							if string.find(t, "disconnect", 1, true)
								or string.find(t, "lost connection", 1, true)
								or string.find(t, "reconnect", 1, true)
								or string.find(t, "connection failed", 1, true)
								or string.find(t, "check your internet", 1, true)
								or string.find(t, "id=17", 1, true)
								or string.find(t, "id=279", 1, true) then
								doReconnect("prompt")
								return
							end
						end
					end
				end
			end)
			pcall(function()
				local stats = game:GetService("Stats")
				local item = stats.Network.ServerStatsItem["Data Ping"]
				local ping = item and item:GetValue()
				if typeof(ping) == "number" and ping > 50000 then
					doReconnect("ping")
				end
			end)
		end
		task.wait(0.5)
	end
end)

if State.AutoLoad then
	task.defer(setupQueueOnTeleport)
end

-- ==========================================
-- AUTO QUEST
-- ==========================================
local QUEST_PHOENIX_NAMES = {
	"Golden Pheonix", "Golden Phoenix", "GoldenPhoenix",
	"Phoenix Gold", "Gold Phoenix", "Blue Phoenix", "Blue Pheonix",
}

local CharmedJoinCount = 0
local MysticEvolveDone = 0
local SpellboundLiftSeat = nil
local SpellboundReenterAt = 0

local function getEnchantQuestsFolder()
	local q = LocalPlayer:FindFirstChild("Quests")
	if not q then return nil end
	return q:FindFirstChild("Enchant Quests")
end

local function hasQuest(name)
	local eq = getEnchantQuestsFolder()
	return eq and eq:FindFirstChild(name) or nil
end

local function readNumber(obj)
	if not obj then return nil end
	if typeof(obj) == "number" then return obj end
	if typeof(obj.Value) == "number" then return obj.Value end
	return tonumber(tostring(obj.Value or obj))
end

local function getAnyProgress(questObj)
	local req = questObj and questObj:FindFirstChild("requirements")
	if not req then return nil end
	for _, child in ipairs(req:GetChildren()) do
		local progress = child:FindFirstChild("progress") or child:FindFirstChild("Progress")
		local p = readNumber(progress)
		if p ~= nil then return p, child.Name end
	end
	return nil
end

local function unequipTools()
	local h = hum()
	if h then pcall(function() h:UnequipTools() end) end
end

local function doCharacterReset()
	local h = hum()
	if h and h.Health > 0 then
		pcall(function() h.Health = 0 end)
	end
end

local function isSeated()
	local h = hum()
	if not h then return false end
	if h.SeatPart ~= nil then return true end
	if h.Sit == true then return true end
	local miu = LocalPlayer:FindFirstChild("machineInUse")
	if miu and miu.Value ~= nil and miu.Value ~= false and tostring(miu.Value) ~= "" then
		return true
	end
	return false
end

local function joinBrawlOnce()
	pcall(function()
		ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl")
	end)
end

local function findPetShopItem(nameCandidates)
	local folder = nil
	pcall(function()
		folder = ReplicatedStorage:FindFirstChild("shared")
			and ReplicatedStorage.shared:FindFirstChild("runtime")
			and ReplicatedStorage.shared.runtime:FindFirstChild("cPetShopFolder")
	end)
	if not folder then return nil end
	for _, n in ipairs(nameCandidates) do
		local item = folder:FindFirstChild(n)
		if item then return item, n end
	end
	for _, item in ipairs(folder:GetChildren()) do
		local ln = string.lower(item.Name):gsub("%s+", "")
		if string.find(ln, "golden", 1, true) and (string.find(ln, "phoenix", 1, true) or string.find(ln, "pheonix", 1, true)) then
			return item, item.Name
		end
	end
	return nil
end

local function buyPetItem(item)
	pcall(function()
		local remote = ReplicatedStorage.rEvents:FindFirstChild("cPetShopRemote")
		if remote and item then
			remote:InvokeServer(item)
		end
	end)
end

local function evolvePet(name)
	pcall(function()
		local ev = ReplicatedStorage.rEvents:FindFirstChild("petEvolveEvent")
		if ev then
			ev:FireServer("evolvePet", name)
		end
	end)
end

local function isGoldenPhoenixPet(pet)
	if not pet then return false end
	local ln = string.lower(pet.Name):gsub("%s+", "")
	local hasPhoenix = string.find(ln, "phoenix", 1, true) or string.find(ln, "pheonix", 1, true)
	local hasGold = string.find(ln, "gold", 1, true)
	return hasPhoenix and hasGold
end

local function isPetEvolved(pet)
	local evolved = pet:FindFirstChild("evolved") or pet:FindFirstChild("Evolved")
	if not evolved then
		if pet:GetAttribute("evolved") == true then return true end
		return false
	end
	if typeof(evolved.Value) == "boolean" then return evolved.Value end
	if typeof(evolved.Value) == "number" then return evolved.Value ~= 0 end
	return tostring(evolved.Value) == "true" or tostring(evolved.Value) == "1"
end

local function sellGoldenPhoenix(onlyEvolved)
	local petsFolder = LocalPlayer:FindFirstChild("petsFolder")
	if not petsFolder then return 0 end
	local sold = 0
	local remote = ReplicatedStorage.rEvents:FindFirstChild("sellPetEvent")
	if not remote then return 0 end
	for _, rar in ipairs(petsFolder:GetChildren()) do
		if rar:IsA("Folder") or rar:IsA("Model") then
			for _, pet in ipairs(rar:GetChildren()) do
				if isGoldenPhoenixPet(pet) then
					local evolved = isPetEvolved(pet)
					if onlyEvolved and not evolved then
					else
						local ok = pcall(function()
							remote:FireServer("sellPet", pet)
						end)
						if ok then sold = sold + 1 end
						task.wait(0.1)
					end
				end
			end
		end
	end
	return sold
end

local function doQuestJump()
	pcall(function()
		local h = hum()
		if h then
			h.Jump = true
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

-- Rune Agility
task.spawn(function()
	while true do
		if not State.AutoQuestFarm then
			task.wait(0.4)
		else
			local q = hasQuest("Rune Agility")
			if q then
				QuestBusy.Rune = true
				local h = hum()
				local bp = LocalPlayer:FindFirstChild("Backpack")
				local ch = char()
				local tool = (ch and ch:FindFirstChild("Pushups")) or (bp and bp:FindFirstChild("Pushups"))
				if tool and h and tool.Parent ~= ch then
					pcall(function() h:EquipTool(tool) end)
					task.wait(0.05)
				end
				pcall(function()
					local ev = LocalPlayer:FindFirstChild("muscleEvent")
					if ev then ev:FireServer("rep") else fireRep() end
				end)
				task.wait(0.01)
			else
				task.wait(0.35)
			end
			if not hasQuest("Rune Agility") and not hasQuest("Rune Durability") then
				if QuestBusy.Rune then
					QuestBusy.Rune = false
					unequipTools()
				end
			end
		end
	end
end)

-- Rune Durability
task.spawn(function()
	while true do
		if not State.AutoQuestFarm then
			task.wait(0.4)
		else
			local q = hasQuest("Rune Durability")
			if q then
				QuestBusy.Rune = true
				local h = hum()
				local bp = LocalPlayer:FindFirstChild("Backpack")
				local ch = char()
				local tool = (ch and ch:FindFirstChild("Pushups")) or (bp and bp:FindFirstChild("Pushups"))
				if tool and h and tool.Parent ~= ch then
					pcall(function() h:EquipTool(tool) end)
					task.wait(0.05)
				end
				pcall(function()
					local ev = LocalPlayer:FindFirstChild("muscleEvent")
					if ev then ev:FireServer("rep") else fireRep() end
				end)
				task.wait(0.01)
			else
				task.wait(0.35)
			end
			if not hasQuest("Rune Agility") and not hasQuest("Rune Durability") then
				if QuestBusy.Rune then
					QuestBusy.Rune = false
					unequipTools()
				end
			end
		end
	end
end)

-- Charmed Brawler
task.spawn(function()
	while true do
		if not State.AutoQuestFarm then
			QuestBusy.CharmedBrawl = false
			CharmedJoinCount = 0
			task.wait(0.5)
		else
			local q = hasQuest("Charmed Brawler")
			if q then
				QuestBusy.CharmedBrawl = true
				local r = root()
				local inZone = r and inBrawl(r.Position)
				if not inZone then
					joinBrawlOnce()
				else
					PlayerInBrawl = true
				end
				local h = hum()
				local bp = LocalPlayer:FindFirstChild("Backpack")
				local ch = char()
				local tool = (ch and ch:FindFirstChild("Weight")) or (bp and bp:FindFirstChild("Weight"))
				if tool and h and tool.Parent ~= ch then
					pcall(function() h:EquipTool(tool) end)
				end
				pcall(function()
					local ev = LocalPlayer:FindFirstChild("muscleEvent")
					if ev then ev:FireServer("rep") else fireRep() end
				end)
				task.wait(0.01)
			else
				if QuestBusy.CharmedBrawl then
					QuestBusy.CharmedBrawl = false
					pcall(function() unequipTools() end)
				end
				CharmedJoinCount = 0
				task.wait(0.5)
			end
		end
	end
end)

-- Spellbound Reps
local SpellboundLiftList = {}
local SpellboundLiftIdx = 1
local SpellboundFailCount = 0
local SpellboundWasActive = false

local function refreshSpellboundLifts()
	SpellboundLiftList = {}
	for _, name in ipairs(LiftNames) do
		if LiftChoices[name] then
			table.insert(SpellboundLiftList, LiftChoices[name])
		end
	end
	if #SpellboundLiftList == 0 then
		for _, m in pairs(LiftChoices) do
			table.insert(SpellboundLiftList, m)
		end
	end
	while #SpellboundLiftList > 4 do
		table.remove(SpellboundLiftList)
	end
end

task.spawn(function()
	refreshSpellboundLifts()
	while true do
		if not State.AutoQuestFarm then
			if SpellboundWasActive then
				doQuestJump()
				SpellboundWasActive = false
			end
			QuestBusy.Spellbound = false
			SpellboundLiftSeat = nil
			task.wait(0.4)
		else
			local q = hasQuest("Spellbound Reps")
			if q then
				if State.AutoKillBoss and BossPresent then
					if QuestBusy.Spellbound or SpellboundWasActive then
						doQuestJump()
					end
					QuestBusy.Spellbound = false
					SpellboundWasActive = true
					task.wait(0.3)
				else
					QuestBusy.Spellbound = true
					SpellboundWasActive = true
					if #SpellboundLiftList == 0 then refreshSpellboundLifts() end
					local h = hum()
					local machine = SpellboundLiftList[SpellboundLiftIdx]
					if not machine and #SpellboundLiftList > 0 then
						SpellboundLiftIdx = 1
						machine = SpellboundLiftList[1]
					end
					if not isSeated() then
						SpellboundFailCount = SpellboundFailCount + 1
						if machine and os.clock() >= SpellboundReenterAt then
							if enterMachine(machine) then
								SpellboundLiftSeat = h and h.SeatPart
								SpellboundReenterAt = os.clock() + 2
								SpellboundFailCount = 0
							else
								SpellboundReenterAt = os.clock() + 1.2
							end
						end
						if SpellboundFailCount >= 4 and #SpellboundLiftList > 1 then
							SpellboundLiftIdx = (SpellboundLiftIdx % #SpellboundLiftList) + 1
							SpellboundFailCount = 0
							SpellboundReenterAt = 0
						end
						task.wait(0.2)
					else
						SpellboundFailCount = 0
						SpellboundLiftSeat = h and h.SeatPart
						pcall(function()
							local ev = LocalPlayer:FindFirstChild("muscleEvent")
							if ev then ev:FireServer("rep") else fireRep() end
						end)
						local prog = select(1, getAnyProgress(q))
						if typeof(prog) == "number" and prog >= 5000 then
							doCharacterReset()
							SpellboundLiftSeat = nil
							SpellboundReenterAt = os.clock() + 5
							task.wait(5)
						else
							task.wait(0.01)
						end
					end
				end
			else
				if SpellboundWasActive or QuestBusy.Spellbound then
					doQuestJump()
				end
				QuestBusy.Spellbound = false
				SpellboundWasActive = false
				SpellboundLiftSeat = nil
				SpellboundLiftIdx = 1
				SpellboundFailCount = 0
				task.wait(0.4)
			end
		end
	end
end)

-- Arcane Slayer
task.spawn(function()
	while true do
		if not State.AutoQuestFarm then
			QuestBusy.Arcane = false
			task.wait(0.4)
		else
			local q = hasQuest("Arcane Slayer")
			if q then
				local model, hitbox = findBoss()
				if model and hitbox then
					QuestBusy.Arcane = true
					local c, r, h = char(), root(), hum()
					if r and h and h.Health > 0 then
						local head = model:FindFirstChild("Head", true)
						local center = (head and head:IsA("BasePart") and head.Position)
							or (hitbox.Position + Vector3.new(0, hitbox.Size.Y * 0.35, 0))
						r.CFrame = CFrame.lookAt(center, center + hitbox.CFrame.LookVector)
						r.AssemblyLinearVelocity = Vector3.zero
						equipPunch()
						local L = c and c:FindFirstChild("LeftHand")
						local R = c and c:FindFirstChild("RightHand")
						if L then safeTouch(hitbox, L, 0) safeTouch(hitbox, L, 1) end
						if R then safeTouch(hitbox, R, 0) safeTouch(hitbox, R, 1) end
						firePunch()
					end
					task.wait(0.03)
				else
					QuestBusy.Arcane = false
					task.wait(0.3)
				end
			else
				QuestBusy.Arcane = false
				task.wait(0.4)
			end
		end
	end
end)

-- Mystic Evolution
local MysticWasActive = false
task.spawn(function()
	while true do
		if not State.AutoQuestFarm then
			if MysticWasActive then
				sellGoldenPhoenix(false)
			end
			QuestBusy.Mystic = false
			MysticWasActive = false
			MysticEvolveDone = 0
			task.wait(0.5)
		else
			local q = hasQuest("Mystic Evolution")
			if q then
				QuestBusy.Mystic = true
				MysticWasActive = true
				local item, petName = findPetShopItem(QUEST_PHOENIX_NAMES)
				if item then
					for _ = 1, 3 do
						buyPetItem(item)
						task.wait(0.15)
					end
				end
				local evolveName = petName or "Golden Phoenix"
				local names = {evolveName, "Golden Phoenix", "Golden Pheonix"}
				for _, n in ipairs(names) do
					for _ = 1, 25 do
						evolvePet(n)
					end
				end
				sellGoldenPhoenix(true)
				MysticEvolveDone = MysticEvolveDone + 25
				task.wait(0.6)
			else
				if MysticWasActive then
					sellGoldenPhoenix(false)
				end
				QuestBusy.Mystic = false
				MysticWasActive = false
				MysticEvolveDone = 0
				task.wait(0.5)
			end
		end
	end
end)

-- Clan Quest
task.spawn(function()
	while true do
		if State.AutoClanQuest then
			pcall(function()
				local remote = ReplicatedStorage.rEvents:FindFirstChild("clanQuestRemote")
				if not remote then return end
				for slot = 1, 9 do
					pcall(function()
						remote:InvokeServer("Claim", { SlotIndex = slot })
					end)
					task.wait(0.05)
				end
			end)
			task.wait(0.8)
		else
			task.wait(0.5)
		end
	end
end)

-- Auto Collect
task.spawn(function()
	while true do
		if State.AutoQuestCollect then
			pcall(function()
				local eq = getEnchantQuestsFolder()
				if not eq then return end
				local ev = ReplicatedStorage:FindFirstChild("rEvents")
				local qe = ev and ev:FindFirstChild("questsEvent")
				if not qe then return end
				for _, questObj in ipairs(eq:GetChildren()) do
					pcall(function()
						qe:FireServer("collectQuest", questObj)
					end)
				end
			end)
			task.wait(1.5)
		else
			task.wait(0.5)
		end
	end
end)

-- ==========================================
-- WEBHOOK
-- ==========================================
local BossRarityOptions = {"All"}
local BossRarityByDisplay = {}
local LastWebhookBossModel = nil

pcall(function()
	local shared = ReplicatedStorage:FindFirstChild("shared")
	local config = shared and shared:FindFirstChild("config")
	local bossCfg = config and config:FindFirstChild("BossEventConfig")
	if not bossCfg then return end
	local cfg = require(bossCfg)
	if cfg and cfg.RARITIES then
		for _, rarity in ipairs(cfg.RARITIES) do
			local display = rarity.DisplayName or rarity.Name or rarity.BossModel or "Unknown"
			local modelName = rarity.BossModel or display
			table.insert(BossRarityOptions, tostring(display))
			BossRarityByDisplay[tostring(display)] = tostring(modelName)
		end
	end
end)
if #BossRarityOptions == 1 then
	for _, n in ipairs({"Common", "Rare", "Epic", "Legendary", "Mythical", "Godly"}) do
		table.insert(BossRarityOptions, n)
	end
end

local function httpRequest(opts)
	local req = (syn and syn.request)
		or (http and http.request)
		or http_request
		or request
		or (fluxus and fluxus.request)
	if req then return req(opts) end
	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = opts.Url,
			Method = opts.Method or "POST",
			Headers = opts.Headers,
			Body = opts.Body,
		})
	end)
	if ok then return res end
	return nil
end

local function sendDiscordWebhook(content, embeds)
	local url = tostring(State.WebhookURL or "")
	if url == "" or not string.find(url, "discord.com/api/webhooks") then
		return false
	end
	local body = {
		username = "Supreme Hub",
		avatar_url = "https://cdn.discordapp.com/embed/avatars/0.png",
		allowed_mentions = State.WebhookPingEveryone and { parse = {"everyone"} } or { parse = {} },
	}
	if State.WebhookPingEveryone then
		body.content = "@everyone"
	elseif content and content ~= "" then
		body.content = content
	end
	if embeds then body.embeds = embeds end
	local payload = HttpService:JSONEncode(body)
	local res = httpRequest({
		Url = url,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = payload,
	})
	return res ~= nil
end

local function listSelectedWebhookBosses()
	local t = {}
	if type(State.WebhookSelectedBosses) ~= "table" then return t end
	for name, on in pairs(State.WebhookSelectedBosses) do
		if on then table.insert(t, name) end
	end
	table.sort(t)
	return t
end

local function bossMatchesWebhookFilter(model)
	if not model then return false end
	local selected = listSelectedWebhookBosses()
	if #selected == 0 then return false end
	for _, name in ipairs(selected) do
		if name == "All" then return true end
	end
	local display = tostring(Workspace:GetAttribute("BossDisplayName") or model.Name)
	local modelName = tostring(model.Name)
	for _, name in ipairs(selected) do
		local wantModel = BossRarityByDisplay[name]
		if wantModel and modelName == wantModel then return true end
		if display == name or modelName == name then return true end
		local dn, sn = string.lower(display), string.lower(name)
		if string.find(dn, sn, 1, true) or string.find(string.lower(modelName), sn, 1, true) then
			return true
		end
	end
	return false
end

local function webhookEmbedBoss(display)
	return {{
		title = "Boss Spawned",
		description = "A boss has appeared on the map.",
		color = 15158332,
		fields = {
			{ name = "Boss", value = "`" .. tostring(display) .. "`", inline = true },
			{ name = "Player", value = LocalPlayer.DisplayName .. " (`@" .. LocalPlayer.Name .. "`)", inline = true },
			{ name = "Place", value = tostring(game.PlaceId), inline = true },
		},
		footer = { text = "Supreme Hub • Muscle Legends" },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}}
end

local function webhookEmbedDisconnect(reason)
	return {{
		title = "Disconnected",
		description = "Your account left the session or lost connection.",
		color = 15105570,
		fields = {
			{ name = "Account", value = "`@" .. LocalPlayer.Name .. "`", inline = true },
			{ name = "Display", value = LocalPlayer.DisplayName, inline = true },
			{ name = "Reason", value = "`" .. tostring(reason or "unknown") .. "`", inline = false },
		},
		footer = { text = "Supreme Hub • Muscle Legends" },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}}
end

task.spawn(function()
	while true do
		if State.WebhookBossNotify and State.WebhookURL ~= "" then
			local model = select(1, findBoss())
			if model and model ~= LastWebhookBossModel then
				if bossMatchesWebhookFilter(model) then
					local display = Workspace:GetAttribute("BossDisplayName") or model.Name
					sendDiscordWebhook(nil, webhookEmbedBoss(display))
				end
				LastWebhookBossModel = model
			elseif not model then
				LastWebhookBossModel = nil
			end
		end
		task.wait(0.5)
	end
end)

local DisconnectWebhookSent = false
local function notifyDisconnectWebhook(reason)
	if not State.WebhookDisconnectNotify then return end
	if DisconnectWebhookSent then return end
	if State.WebhookURL == "" then return end
	DisconnectWebhookSent = true
	sendDiscordWebhook(nil, webhookEmbedDisconnect(reason))
end

pcall(function()
	local GuiService = game:GetService("GuiService")
	GuiService.ErrorMessageChanged:Connect(function(msg)
		if msg and tostring(msg) ~= "" then
			notifyDisconnectWebhook(msg)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	if p == LocalPlayer then
		notifyDisconnectWebhook("left game")
	end
end)

-- ==========================================

local function buildUi()
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local parentGui = (gethui and gethui()) or playerGui

local posAberta = UDim2.new(0.5, 0, 0.46, 0)
local posFechada = UDim2.new(0.5, 0, -0.7, 0)

local GREEN = Color3.fromRGB(58, 255, 55)
local RED = Color3.fromRGB(175, 0, 0)
local TEXT = Color3.fromRGB(255, 255, 255)
local ARROW_COLOR = Color3.fromRGB(255, 255, 255)
local BORDER = 1.8

local IconsV2
pcall(function()
	IconsV2 = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))()
	IconsV2.SetIconsType("lucide")
end)

local function searchIconId()
	if not IconsV2 then return "" end
	local ok, id = pcall(function()
		return IconsV2.GetIcon("search")
	end)
	if ok and id then return id end
	ok, id = pcall(function()
		return IconsV2.Get("search")
	end)
	return (ok and id) or ""
end

local function aplicarCanto(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = parent
	return c
end

local function aplicarBordaPreta(parent, thickness)
	local s = Instance.new("UIStroke")
	s.Name = "BordaPreta"
	s.Color = Color3.fromRGB(0, 0, 0)
	s.Thickness = thickness or BORDER
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function aplicarContornoTexto(parent, thickness)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(0, 0, 0)
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
	return s
end

local function aplicarDegradeVertical(parent, c0, c1)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c0 or Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, c1 or Color3.fromRGB(180, 180, 180)),
	})
	g.Parent = parent
	return g
end

-- Seta de seção: fica na esquerda, com vão, sem cobrir o título
local function criarSetaSecao(parent, pixel, color, z)
	local clip = Instance.new("Frame")
	clip.Name = "SetaSecao"
	clip.Size = UDim2.fromOffset(pixel or 18, pixel or 18)
	clip.Position = UDim2.new(0, 4, 0.5, 0)
	clip.AnchorPoint = Vector2.new(0, 0.5)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.ZIndex = z or 6
	clip.Parent = parent

	local arrow = Instance.new("Frame")
	arrow.Name = "Arrow"
	arrow.Size = UDim2.fromOffset(15, 15)
	arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.BackgroundTransparency = 1
	arrow.ZIndex = z or 6
	arrow.Parent = clip

	local function arm(sx, sy, px, zi, rot)
		local f = Instance.new("Frame")
		f.Name = "Arm"
		f.Size = UDim2.new(sx, 0, sy, 0)
		f.Position = UDim2.new(px, 0, 0.5389, 0)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BackgroundColor3 = color or TEXT
		f.BorderSizePixel = 0
		f.Rotation = rot
		f.ZIndex = zi
		f.Parent = arrow
		aplicarDegradeVertical(f, Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190))
		return f
	end

	arm(0.8757, 0.42, 0.3389, (z or 6), 42)
	arm(0.8757, 0.42, 0.6611, (z or 6), -42)
	arm(0.6757, 0.22, 0.3389, (z or 6) + 1, 42)
	arm(0.6757, 0.22, 0.6611, (z or 6) + 1, -42)
	return clip, arrow
end

local function criarSetaDropdown(parent, color)
	local caret = Instance.new("Frame")
	caret.Name = "Caret"
	caret.Size = UDim2.new(0.16, 0, 0.56, 0)
	caret.Position = UDim2.new(0.888, 0, 0.5, 0)
	caret.AnchorPoint = Vector2.new(0.5, 0.5)
	caret.BackgroundTransparency = 1
	caret.ZIndex = 8
	caret.Parent = parent

	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.Parent = caret

	local function arm(px)
		local f = Instance.new("Frame")
		f.Name = "Arm"
		f.Size = UDim2.new(0.6657, 0, 0.2, 0)
		f.Position = UDim2.new(px, 0, 0.5354, 0)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BackgroundColor3 = color or GREEN
		f.BorderSizePixel = 0
		f.Rotation = px < 0.5 and 42 or -42
		f.ZIndex = 9
		f.Parent = caret
	end
	arm(0.3354)
	arm(0.6646)
	return caret
end

-- ============================================================
-- SHELL
-- ============================================================
local oldCustomGui = parentGui:FindFirstChild("CustomMenuGui") or playerGui:FindFirstChild("CustomMenuGui")
if oldCustomGui then oldCustomGui:Destroy() end

local customScreenGui = Instance.new("ScreenGui")
customScreenGui.Name = "CustomMenuGui"
customScreenGui.ResetOnSpawn = false
customScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
customScreenGui.Parent = parentGui

local customMenuFrame = Instance.new("Frame")
customMenuFrame.Name = "CustomSettingsMenu"
customMenuFrame.Size = UDim2.new(0.62, 0, 0.72, 0)
customMenuFrame.Position = posFechada
customMenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
customMenuFrame.BackgroundTransparency = 1
customMenuFrame.ClipsDescendants = false
customMenuFrame.Visible = false
customMenuFrame.ZIndex = 100
customMenuFrame.Parent = customScreenGui

local elements = Instance.new("Frame")
elements.Name = "Elements"
elements.Size = UDim2.new(1, 0, 1, 0)
elements.Position = UDim2.new(0.5, 0, 0.5, 0)
elements.AnchorPoint = Vector2.new(0.5, 0.5)
elements.BackgroundTransparency = 1
elements.ZIndex = 0
elements.Parent = customMenuFrame

local base = Instance.new("ImageLabel")
base.Name = "Base"
base.Size = UDim2.new(1, 0, 1, 0)
base.Position = UDim2.new(0.5, 0, 0.5, 0)
base.AnchorPoint = Vector2.new(0.5, 0.5)
base.BackgroundTransparency = 1
base.Image = "rbxassetid://137469878965534"
base.ImageColor3 = Color3.fromRGB(210, 35, 35)
base.ScaleType = Enum.ScaleType.Fit
base.ZIndex = 0
base.Parent = elements

local uiShadow = Instance.new("Folder")
uiShadow.Name = "UIShadow"
uiShadow.Parent = base

local topFrame = Instance.new("Frame")
topFrame.Name = "Top"
topFrame.Size = UDim2.new(0, 460, 0, 40)
topFrame.Position = UDim2.new(0.5, 0, 0, -22)
topFrame.AnchorPoint = Vector2.new(0.5, 0)
topFrame.BackgroundTransparency = 1
topFrame.ClipsDescendants = true
topFrame.ZIndex = 5
topFrame.Parent = customMenuFrame
aplicarCanto(topFrame, 6)
aplicarBordaPreta(topFrame, 1.2)

local strengthBase = Instance.new("ImageLabel")
strengthBase.Name = "StrengthBase"
strengthBase.Size = UDim2.new(1, 0, 1, 0)
strengthBase.Position = UDim2.new(0.5, 0, 0.5, 0)
strengthBase.AnchorPoint = Vector2.new(0.5, 0.5)
strengthBase.BackgroundTransparency = 1
strengthBase.Image = "rbxassetid://87988555080673"
strengthBase.ScaleType = Enum.ScaleType.Stretch
strengthBase.ZIndex = 1
strengthBase.Parent = topFrame

local colorFrame = Instance.new("Frame")
colorFrame.Name = "Color"
colorFrame.Size = UDim2.new(1, 0, 1, 0)
colorFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
colorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
colorFrame.BackgroundColor3 = TEXT
colorFrame.BackgroundTransparency = 0.35
colorFrame.ZIndex = 2
colorFrame.Parent = topFrame
aplicarCanto(colorFrame, 6)
aplicarDegradeVertical(colorFrame, Color3.fromRGB(90, 0, 5), Color3.fromRGB(175, 15, 20))

local label = Instance.new("TextLabel")
label.Name = "Label"
label.Size = UDim2.new(0.75, 0, 0.8, 0)
label.Position = UDim2.new(0.04, 0, 0.5, 0)
label.AnchorPoint = Vector2.new(0, 0.5)
label.BackgroundTransparency = 1
label.Text = "Muscle Legends"
label.TextColor3 = ARROW_COLOR
label.Font = Enum.Font.Arcade
label.TextScaled = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.ZIndex = 10
label.Parent = topFrame
aplicarContornoTexto(label, 1.5)

local exitButton = Instance.new("ImageButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.new(0.0854, 0, 0.9, 0)
exitButton.Position = UDim2.new(0.999, 0, 0.5, 0)
exitButton.AnchorPoint = Vector2.new(1, 0.5)
exitButton.BackgroundTransparency = 1
exitButton.Image = "rbxassetid://93133669414479"
exitButton.ScaleType = Enum.ScaleType.Fit
exitButton.ZIndex = 15
exitButton.Parent = topFrame

local sideButtons = Instance.new("Frame")
sideButtons.Name = "SideButtons"
sideButtons.Size = UDim2.new(0.195, 0, 0.88, 0)
sideButtons.Position = UDim2.new(0, -50, 0, 8)
sideButtons.BackgroundTransparency = 1
sideButtons.ZIndex = 55
sideButtons.Parent = customMenuFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0.015, 0)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = sideButtons

local buttonNames = {"Player", "Farm", "Rebirth", "Combat", "World", "Server", "Misc"}
local sideButtonRefs = {}

local function createClickSound(parent)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://2818606146"
	s.Volume = 0.5
	s.Parent = parent
	return s
end

local function createHoverSound(parent)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://3610999518"
	s.Volume = 0.4
	s.Parent = parent
	return s
end

local function createSideButton(name, order)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0.125, 0)
	btn.BackgroundTransparency = 1
	btn.Image = "rbxassetid://124788545790346"
	btn.ImageColor3 = Color3.fromRGB(175, 0, 0)
	btn.ScaleType = Enum.ScaleType.Fit
	btn.AutoButtonColor = false
	btn.ZIndex = 56
	btn.LayoutOrder = order
	btn.Parent = sideButtons

	local btnLabel = Instance.new("TextLabel")
	btnLabel.Size = UDim2.new(0.88, 0, 0.65, 0)
	btnLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	btnLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	btnLabel.BackgroundTransparency = 1
	btnLabel.Text = name
	btnLabel.TextColor3 = TEXT
	btnLabel.Font = Enum.Font.GothamBold
	btnLabel.TextScaled = true
	btnLabel.ZIndex = 58
	btnLabel.Parent = btn
	aplicarContornoTexto(btnLabel, 1.35)

	local clickSoundBtn = createClickSound(btn)
	local hoverSoundBtn = createHoverSound(btn)
	local colorNormal = Color3.fromRGB(175, 0, 0)
	local colorHover = Color3.fromRGB(230, 30, 30)
	local colorActive = Color3.fromRGB(255, 70, 70)
	local sizeNormal = UDim2.new(1, 0, 0.125, 0)
	local sizeHover = UDim2.new(1.06, 0, 0.135, 0)
	local sizePress = UDim2.new(0.94, 0, 0.115, 0)
	local tweenInfo = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	btn:SetAttribute("Active", false)

	btn.MouseEnter:Connect(function()
		hoverSoundBtn:Play()
		if not btn:GetAttribute("Active") then
			TweenService:Create(btn, tweenInfo, {ImageColor3 = colorHover, Size = sizeHover}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if not btn:GetAttribute("Active") then
			TweenService:Create(btn, tweenInfo, {ImageColor3 = colorNormal, Size = sizeNormal}):Play()
		end
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, tweenInfo, {Size = sizePress}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, tweenInfo, {Size = sizeNormal}):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		clickSoundBtn:Play()
	end)

	sideButtonRefs[name] = btn
	return btn
end

for i, name in ipairs(buttonNames) do
	createSideButton(name, i)
end

local rightButtons = Instance.new("Frame")
rightButtons.Name = "RightButtons"
rightButtons.Size = UDim2.new(0.195, 0, 0.28, 0)
rightButtons.Position = UDim2.new(1, 8, 0, 8)
rightButtons.BackgroundTransparency = 1
rightButtons.ZIndex = 55
rightButtons.Parent = customMenuFrame
local rightLayout = Instance.new("UIListLayout")
rightLayout.Padding = UDim.new(0.04, 0)
rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightLayout.Parent = rightButtons

local function createRightButton(name, order, callback)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0.42, 0)
	btn.BackgroundTransparency = 1
	btn.Image = "rbxassetid://124788545790346"
	btn.ImageColor3 = Color3.fromRGB(175, 0, 0)
	btn.ScaleType = Enum.ScaleType.Fit
	btn.AutoButtonColor = false
	btn.ZIndex = 56
	btn.LayoutOrder = order
	btn.Parent = rightButtons
	local btnLabel = Instance.new("TextLabel")
	btnLabel.Size = UDim2.new(0.88, 0, 0.65, 0)
	btnLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	btnLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	btnLabel.BackgroundTransparency = 1
	btnLabel.Text = name
	btnLabel.TextColor3 = TEXT
	btnLabel.Font = Enum.Font.GothamBold
	btnLabel.TextScaled = true
	btnLabel.ZIndex = 58
	btnLabel.Parent = btn
	aplicarContornoTexto(btnLabel, 1.35)
	local clickSoundBtn = createClickSound(btn)
	btn.MouseButton1Click:Connect(function()
		clickSoundBtn:Play()
		if callback then callback() end
	end)
	return btn
end
createRightButton("Discord", 1, function()
	pcall(function()
		if setclipboard then setclipboard("Muscle Legends") end
	end)
end)
createRightButton("Edit KeyBind", 2, function()
	if openKeyBind then openKeyBind() end
end)

local resizeGrip = Instance.new("TextButton")
resizeGrip.Name = "ResizeGrip"
resizeGrip.Size = UDim2.new(0.05, 0, 0.05, 0)
resizeGrip.Position = UDim2.new(1, -75, 1, -3)
resizeGrip.AnchorPoint = Vector2.new(1, 1)
resizeGrip.BackgroundTransparency = 1
resizeGrip.Text = ""
resizeGrip.ZIndex = 120
resizeGrip.Active = false
resizeGrip.Parent = customMenuFrame
Instance.new("UIAspectRatioConstraint", resizeGrip).Parent = resizeGrip

local function makeGrip(size, pos)
	local bar = Instance.new("Frame")
	bar.Size = size
	bar.Position = pos
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.BackgroundColor3 = TEXT
	bar.BackgroundTransparency = 0.35
	bar.BorderSizePixel = 0
	bar.Rotation = -45
	bar.ZIndex = 121
	bar.Parent = resizeGrip
end
makeGrip(UDim2.new(0.9, 0, 0.13, 0), UDim2.new(0.5, 0, 0.5, 0))
makeGrip(UDim2.new(0.54, 0, 0.13, 0), UDim2.new(0.68, 0, 0.68, 0))
makeGrip(UDim2.new(0.22, 0, 0.13, 0), UDim2.new(0.84, 0, 0.84, 0))

-- ============================================================
-- CONTEÚDO DENTRO DO PAINEL, ABAIXO DO TOP
-- Left fica fora do frame, então o miolo é centralizado na base
-- ============================================================
base.ClipsDescendants = true

-- Miolo dentro da imagem da UI, logo abaixo do Top, com folga nas bordas
local contentRoot = Instance.new("Frame")
contentRoot.Name = "PainelFuncoes"
contentRoot.Size = UDim2.new(0.74, 0, 0.90, 0)
contentRoot.Position = UDim2.new(0.5, 0, 0.045, 0)
contentRoot.AnchorPoint = Vector2.new(0.5, 0)
contentRoot.BackgroundTransparency = 1
contentRoot.ClipsDescendants = true
contentRoot.ZIndex = 20
contentRoot.Parent = base

local somCliqueFuncoes = Instance.new("Sound")
somCliqueFuncoes.Name = "ClickSound"
somCliqueFuncoes.SoundId = "rbxassetid://2818606146"
somCliqueFuncoes.Volume = 0.5
somCliqueFuncoes.Parent = contentRoot

local function tocarClique()
	somCliqueFuncoes.TimePosition = 0
	somCliqueFuncoes:Play()
end

local pages = {}
	local KeybindList = {}
	local openKeyBind
local currentPageName = nil

local function criarPagina(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 5
	page.ScrollBarImageColor3 = TEXT
	page.ScrollBarImageTransparency = 0.35
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new()
	page.Visible = false
	page.ZIndex = 21
	page.Parent = contentRoot

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = page

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = page

	pages[name] = page
	return page
end

local function abrirPagina(name)
	currentPageName = name
	for pageName, page in pairs(pages) do
		page.Visible = pageName == name
	end
	for btnName, btn in pairs(sideButtonRefs) do
		local active = btnName == name
		btn:SetAttribute("Active", active)
		btn.ImageColor3 = active and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(175, 0, 0)
	end
end

local function criarLinhaFuncao(parent, height)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0.94, 0, 0, height or 38)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 22
	holder.Parent = parent

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(1, 0, 0.85, 0)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	main.BackgroundTransparency = 0.5
	main.ZIndex = 23
	main.Parent = holder
	aplicarBordaPreta(main)
	return holder, main
end

local function criarTextoLinha(parent, text, size, pos, anchor)
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Label"
	lbl.Size = size
	lbl.Position = pos
	lbl.AnchorPoint = anchor or Vector2.new(0, 0.5)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = TEXT
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 25
	lbl.Parent = parent
	aplicarContornoTexto(lbl, 1)
	return lbl
end

local function criarSecao(parent, titleText, startOpen)
	local section = Instance.new("Frame")
	section.Name = titleText .. "Section"
	section.Size = UDim2.new(1, 0, 0, 28)
	section.BackgroundTransparency = 1
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.ZIndex = 22
	section.Parent = parent

	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 2)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.Parent = section

	local header = Instance.new("Frame")
	header.Name = titleText
	header.Size = UDim2.new(0.94, 0, 0, 24)
	header.BackgroundTransparency = 1
	header.ZIndex = 24
	header.LayoutOrder = 1
	header.Parent = section

	local arrowSlot = Instance.new("Frame")
	arrowSlot.Name = "EspacoSeta"
	arrowSlot.Size = UDim2.fromOffset(22, 22)
	arrowSlot.Position = UDim2.new(0, 0, 0.5, 0)
	arrowSlot.AnchorPoint = Vector2.new(0, 0.5)
	arrowSlot.BackgroundTransparency = 1
	arrowSlot.ClipsDescendants = true
	arrowSlot.ZIndex = 25
	arrowSlot.Parent = header

	local _, arrow = criarSetaSecao(arrowSlot, 16, ARROW_COLOR, 6)
	arrow.Rotation = startOpen and 0 or -90

	local title = Instance.new("TextLabel")
	title.Name = "TituloSecao"
	title.Size = UDim2.new(1, -30, 1, 0)
	title.Position = UDim2.new(0, 30, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = ARROW_COLOR
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 24
	title.Parent = header
	aplicarContornoTexto(title, 1)

	local hit = Instance.new("TextButton")
	hit.Name = "SectionButton"
	hit.Size = UDim2.new(1, 0, 1, 0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 8
	hit.Parent = header

	local content = Instance.new("Frame")
	content.Name = "CollapsibleContent"
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.Visible = startOpen and true or false
	content.ZIndex = 22
	content.LayoutOrder = 2
	content.Parent = section

	local contentLay = Instance.new("UIListLayout")
	contentLay.Padding = UDim.new(0, 0)
	contentLay.SortOrder = Enum.SortOrder.LayoutOrder
	contentLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLay.Parent = content

	local open = startOpen and true or false
	hit.MouseButton1Click:Connect(function()
		tocarClique()
		open = not open
		content.Visible = open
		TweenService:Create(arrow, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = open and 0 or -90,
		}):Play()
	end)

	return content
end

local function adicionarStatus(parent, text)
	local holder, main = criarLinhaFuncao(parent, 38)
	holder.Name = text
	local lbl = criarTextoLinha(main, text, UDim2.new(0.94, 0, 0.64, 0), UDim2.new(0.025, 0, 0.5, 0))
	return holder, lbl
end

local function adicionarInterruptor(parent, text, defaultState, callback)
	local state = defaultState and true or false
	local holder, main = criarLinhaFuncao(parent, 38)
	holder.Name = text
	criarTextoLinha(main, text, UDim2.new(0.68, 0, 0.64, 0), UDim2.new(0.025, 0, 0.5, 0))

	local sw = Instance.new("TextButton")
	sw.Name = "Interruptor"
	sw.Size = UDim2.fromOffset(34, 16)
	sw.Position = UDim2.new(1, -8, 0.5, 0)
	sw.AnchorPoint = Vector2.new(1, 0.5)
	sw.BackgroundColor3 = state and GREEN or Color3.fromRGB(20, 20, 20)
	sw.BackgroundTransparency = state and 0.05 or 0.35
	sw.Text = ""
	sw.AutoButtonColor = false
	sw.ZIndex = 26
	sw.Parent = main
	aplicarCanto(sw, 3)
	aplicarBordaPreta(sw)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 12)
	knob.Position = state and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
	knob.AnchorPoint = Vector2.new(state and 1 or 0, 0.5)
	knob.BackgroundColor3 = TEXT
	knob.ZIndex = 27
	knob.Parent = sw
	aplicarCanto(knob, 2)

	local function paintSwitch()
		sw.BackgroundColor3 = state and GREEN or Color3.fromRGB(20, 20, 20)
		sw.BackgroundTransparency = state and 0.05 or 0.35
		knob.Position = state and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		knob.AnchorPoint = Vector2.new(state and 1 or 0, 0.5)
	end
	local function setSwitch(v, fire)
		state = v and true or false
		paintSwitch()
		if fire and callback then callback(state) end
	end
	table.insert(KeybindList, {name = text, get = function() return state end, set = function(v) setSwitch(v, true) end, key = ""})

	sw.MouseButton1Click:Connect(function()
		tocarClique()
		state = not state
		TweenService:Create(sw, TweenInfo.new(0.14), {
			BackgroundColor3 = state and GREEN or Color3.fromRGB(20, 20, 20),
			BackgroundTransparency = state and 0.05 or 0.35,
		}):Play()
		TweenService:Create(knob, TweenInfo.new(0.14), {
			Position = state and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			AnchorPoint = Vector2.new(state and 1 or 0, 0.5),
		}):Play()
		if callback then callback(state) end
	end)
	return holder
end

local function adicionarSlider(parent, text, minV, maxV, defaultV, unit, callback)
	local value = defaultV or minV
	local holder, main = criarLinhaFuncao(parent, 38)
	holder.Name = text
	criarTextoLinha(main, text, UDim2.new(0.45, 0, 0.64, 0), UDim2.new(0.025, 0, 0.5, 0))

	local box = Instance.new("TextBox")
	box.Name = "Value"
	box.Size = UDim2.new(0.16, 0, 0.56, 0)
	box.Position = UDim2.new(0.5, 0, 0.5, 0)
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	box.BackgroundTransparency = 0.6
	box.RichText = true
	box.Text = ""
	box.TextColor3 = TEXT
	box.Font = Enum.Font.GothamBold
	box.TextScaled = true
	box.ZIndex = 26
	box.Parent = main
	aplicarBordaPreta(box)
	aplicarContornoTexto(box, 1)

	local slider = Instance.new("TextButton")
	slider.Name = "Slider"
	slider.Size = UDim2.new(0.3, 0, 0.42, 0)
	slider.Position = UDim2.new(0.97, 0, 0.5, 0)
	slider.AnchorPoint = Vector2.new(1, 0.5)
	slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	slider.BackgroundTransparency = 0.6
	slider.Text = ""
	slider.AutoButtonColor = false
	slider.ZIndex = 26
	slider.Parent = main
	aplicarBordaPreta(slider)

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(math.clamp((value - minV) / (maxV - minV), 0, 1), 0, 1, 0)
	bar.BackgroundColor3 = GREEN
	bar.BorderSizePixel = 0
	bar.ZIndex = 27
	bar.Parent = slider
	aplicarDegradeVertical(bar, Color3.fromRGB(120, 255, 110), Color3.fromRGB(30, 170, 40))

	local hold = Instance.new("Frame")
	hold.Name = "Hold"
	hold.Size = UDim2.new(0.08, 0, 1.35, 0)
	hold.Position = UDim2.new(math.clamp((value - minV) / (maxV - minV), 0, 1), 0, 0.5, 0)
	hold.AnchorPoint = Vector2.new(0.5, 0.5)
	hold.BackgroundColor3 = TEXT
	hold.ZIndex = 28
	hold.Parent = slider
	aplicarBordaPreta(hold)

	local dragging = false
	local function setVal(v)
		value = math.clamp(math.floor(v + 0.5), minV, maxV)
		local pct = (value - minV) / (maxV - minV)
		bar.Size = UDim2.new(pct, 0, 1, 0)
		hold.Position = UDim2.new(pct, 0, 0.5, 0)
		if unit == "s" then
			box.RichText = true
			box.Text = tostring(value) .. '<font color="rgb(58,255,55)">s</font>'
		else
			box.RichText = false
			box.Text = tostring(value) .. (unit and unit ~= "" and (" " .. unit) or "")
		end
		if callback then callback(value) end
	end

	slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tocarClique()
			dragging = true
			local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
			setVal(minV + (maxV - minV) * pos)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
			setVal(minV + (maxV - minV) * pos)
		end
	end)
	box.FocusLost:Connect(function()
		local num = tonumber((box.Text:gsub("[^%d]", "")))
		if num then setVal(num) else setVal(value) end
	end)
	if unit == "s" then
		box.RichText = true
		box.Text = tostring(value) .. '<font color="rgb(58,255,55)">s</font>'
	else
		box.Text = tostring(value) .. (unit and unit ~= "" and (" " .. unit) or "")
	end
	return holder
end

local function adicionarLista(parent, text, options, defaultOpt, multi, callback)
	local selected
	if multi then
		selected = {}
		if type(defaultOpt) == "table" then
			for _, v in ipairs(defaultOpt) do
				if type(v) == "string" then table.insert(selected, v) end
			end
			for k, v in pairs(defaultOpt) do
				if type(k) == "string" and v == true and not table.find(selected, k) then
					table.insert(selected, k)
				end
			end
		end
	else
		selected = defaultOpt or options[1]
	end
	local open = false
	local holder = Instance.new("Frame")
	holder.Name = text
	holder.Size = UDim2.new(0.94, 0, 0, 38)
	holder.BackgroundTransparency = 1
	holder.ClipsDescendants = false
	holder.ZIndex = 22
	holder.Parent = parent

	local head, main = criarLinhaFuncao(holder, 38)
	head.Size = UDim2.new(1, 0, 0, 38)
	criarTextoLinha(main, text, UDim2.new(0.62, 0, 0.64, 0), UDim2.new(0.025, 0, 0.5, 0))

	local dropBtn = Instance.new("TextButton")
	dropBtn.Name = "Dropdown"
	dropBtn.Size = UDim2.new(0.28, 0, 0.62, 0)
	dropBtn.Position = UDim2.new(0.845, 0, 0.5, 0)
	dropBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	dropBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dropBtn.BackgroundTransparency = 0.42
	dropBtn.Text = ""
	dropBtn.AutoButtonColor = false
	dropBtn.ZIndex = 26
	dropBtn.Parent = main
	aplicarBordaPreta(dropBtn)

	local valueLbl = Instance.new("TextLabel")
	valueLbl.Name = "Value"
	valueLbl.Size = UDim2.new(0.7, 0, 0.58, 0)
	valueLbl.Position = UDim2.new(0.405, 0, 0.5, 0)
	valueLbl.AnchorPoint = Vector2.new(0.5, 0.5)
	valueLbl.BackgroundTransparency = 1
	valueLbl.Text = multi and "0 selected" or tostring(selected)
	valueLbl.TextColor3 = TEXT
	valueLbl.Font = Enum.Font.GothamBold
	valueLbl.TextScaled = true
	valueLbl.ZIndex = 27
	valueLbl.Parent = dropBtn
	aplicarContornoTexto(valueLbl, 1)

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(0.014, 0, 0.66, 0)
	divider.Position = UDim2.new(0.8, 0, 0.5, 0)
	divider.AnchorPoint = Vector2.new(0.5, 0.5)
	divider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	divider.BackgroundTransparency = 0.3
	divider.ZIndex = 27
	divider.Parent = dropBtn

	local caret = criarSetaDropdown(dropBtn, GREEN)

	local menu = Instance.new("Frame")
	menu.Name = "Menu"
	menu.Size = UDim2.new(1, 0, 0, 0)
	menu.Position = UDim2.new(0.5, 0, 0, 38)
	menu.AnchorPoint = Vector2.new(0.5, 0)
	menu.BackgroundTransparency = 1
	menu.ClipsDescendants = true
	menu.Visible = false
	menu.ZIndex = 28
	menu.Parent = holder

	local search = Instance.new("Frame")
	search.Name = "Search"
	search.Size = UDim2.new(1, -4, 0, 23)
	search.Position = UDim2.new(0, 2, 0, 2)
	search.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	search.BackgroundTransparency = 0.6
	search.ZIndex = 29
	search.Parent = menu
	aplicarBordaPreta(search)

	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Name = "IconeBusca"
	searchIcon.BackgroundTransparency = 1
	searchIcon.Size = UDim2.fromOffset(14, 14)
	searchIcon.Position = UDim2.new(0, 6, 0.5, 0)
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.Image = searchIconId()
	searchIcon.ImageColor3 = ARROW_COLOR
	searchIcon.ScaleType = Enum.ScaleType.Fit
	searchIcon.ZIndex = 31
	searchIcon.Parent = search

	local input = Instance.new("TextBox")
	input.Name = "CampoBusca"
	input.Size = UDim2.new(1, -28, 0.56, 0)
	input.Position = UDim2.new(0, 24, 0.5, 0)
	input.AnchorPoint = Vector2.new(0, 0.5)
	input.BackgroundTransparency = 1
	input.PlaceholderText = "Search..."
	input.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
	input.Text = ""
	input.TextColor3 = TEXT
	input.Font = Enum.Font.Gotham
	input.TextScaled = true
	input.ZIndex = 30
	input.Parent = search
	aplicarContornoTexto(input, 1)

	local empty = Instance.new("TextLabel")
	empty.Name = "Empty"
	empty.Size = UDim2.new(1, 0, 0, 20)
	empty.Position = UDim2.new(0, 0, 0, 28)
	empty.BackgroundTransparency = 1
	empty.Text = "No match"
	empty.TextColor3 = TEXT
	empty.Font = Enum.Font.GothamBold
	empty.TextScaled = true
	empty.Visible = false
	empty.ZIndex = 30
	empty.Parent = menu

	local grid = Instance.new("Frame")
	grid.Name = "Options"
	grid.Size = UDim2.new(1, -4, 0, 0)
	grid.Position = UDim2.new(0, 2, 0, 28)
	grid.BackgroundTransparency = 1
	grid.ZIndex = 29
	grid.Parent = menu

	local gridLay = Instance.new("UIGridLayout")
	gridLay.CellSize = UDim2.new(0.24, -4, 0, 23)
	gridLay.CellPadding = UDim2.new(0, 6, 0, 6)
	gridLay.SortOrder = Enum.SortOrder.LayoutOrder
	gridLay.Parent = grid

	local buttons = {}

	local function refreshCount()
		if multi then
			valueLbl.Text = #selected .. " selected"
		else
			valueLbl.Text = tostring(selected)
		end
	end

	local function paint()
		local shown = 0
		local q = string.lower(input.Text)
		for _, info in ipairs(buttons) do
			local ok = q == "" or string.find(string.lower(info.name), q, 1, true)
			info.button.Visible = ok and true or false
			if ok then shown += 1 end
			local on = multi and table.find(selected, info.name) or selected == info.name
			info.button.BackgroundTransparency = on and 0.2 or 0.45
			if info.accent then
				info.accent.Size = UDim2.new(0, on and 4 or 0, 1, 0)
			end
			if info.fill then
				info.fill.Visible = on and true or false
			end
		end
		empty.Visible = shown == 0
		local rows = math.max(1, math.ceil(shown / 4))
		grid.Size = UDim2.new(1, -4, 0, rows * 29)
		return 30 + rows * 29 + 6
	end

	for i, opt in ipairs(options) do
		local b = Instance.new("TextButton")
		b.Name = "Option" .. i
		b.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		b.BackgroundTransparency = 0.45
		b.Text = ""
		b.AutoButtonColor = false
		b.LayoutOrder = i
		b.ZIndex = 30
		b.Parent = grid
		aplicarBordaPreta(b)

		local accent, fill
		if not multi then
			accent = Instance.new("Frame")
			accent.Name = "Accent"
			accent.Size = UDim2.new(0, 0, 1, 0)
			accent.Position = UDim2.new(0, 0, 0.5, 0)
			accent.AnchorPoint = Vector2.new(0, 0.5)
			accent.BackgroundColor3 = GREEN
			accent.BorderSizePixel = 0
			accent.ZIndex = 31
			accent.Parent = b
			aplicarDegradeVertical(accent, GREEN, Color3.fromRGB(20, 120, 30))
		else
			local tick = Instance.new("Frame")
			tick.Name = "Tick"
			tick.Size = UDim2.new(0.16, 0, 0.44, 0)
			tick.Position = UDim2.new(0.055, 0, 0.5, 0)
			tick.AnchorPoint = Vector2.new(0, 0.5)
			tick.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			tick.BackgroundTransparency = 0.3
			tick.ZIndex = 31
			tick.Parent = b
			aplicarBordaPreta(tick)
			local ratio = Instance.new("UIAspectRatioConstraint")
			ratio.Parent = tick
			fill = Instance.new("Frame")
			fill.Name = "Fill"
			fill.Size = UDim2.new(0.85, 0, 0.85, 0)
			fill.Position = UDim2.new(0.5, 0, 0.5, 0)
			fill.AnchorPoint = Vector2.new(0.5, 0.5)
			fill.BackgroundColor3 = GREEN
			fill.Visible = false
			fill.ZIndex = 32
			fill.Parent = tick
		end

		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(multi and 0.62 or 0.78, 0, 0.56, 0)
		t.Position = UDim2.new(multi and 0.56 or 0.5, 0, 0.5, 0)
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.BackgroundTransparency = 1
		t.Text = opt
		t.TextColor3 = TEXT
		t.Font = Enum.Font.GothamBold
		t.TextScaled = true
		t.ZIndex = 32
		t.Parent = b
		aplicarContornoTexto(t, 1)

		buttons[#buttons + 1] = {name = opt, button = b, accent = accent, fill = fill}
		b.MouseButton1Click:Connect(function()
			tocarClique()
			if multi then
				local idx = table.find(selected, opt)
				if idx then table.remove(selected, idx) else table.insert(selected, opt) end
				refreshCount()
				paint()
				if callback then callback(selected) end
			else
				selected = opt
				refreshCount()
				paint()
				open = false
				menu.Visible = false
				holder.Size = UDim2.new(0.94, 0, 0, 38)
				TweenService:Create(caret, TweenInfo.new(0.12), {Rotation = 0}):Play()
				if callback then callback(selected) end
			end
		end)
	end

	input:GetPropertyChangedSignal("Text"):Connect(function()
		if open then
			local h = paint()
			menu.Size = UDim2.new(1, 0, 0, h)
			holder.Size = UDim2.new(0.94, 0, 0, 38 + h)
		end
	end)

	dropBtn.MouseButton1Click:Connect(function()
		tocarClique()
		open = not open
		menu.Visible = open
		local h = open and paint() or 0
		menu.Size = UDim2.new(1, 0, 0, h)
		holder.Size = UDim2.new(0.94, 0, 0, 38 + h)
		TweenService:Create(caret, TweenInfo.new(0.12), {Rotation = open and 180 or 0}):Play()
	end)

	refreshCount()
	paint()
	return holder
end

local function adicionarCampoNome(parent, text, placeholder)
	local holder, main = criarLinhaFuncao(parent, 38)
	holder.Name = text
	criarTextoLinha(main, text, UDim2.new(0.62, 0, 0.64, 0), UDim2.new(0.025, 0, 0.5, 0))

	local field = Instance.new("Frame")
	field.Name = "Field"
	field.Size = UDim2.new(0.28, 0, 0.62, 0)
	field.Position = UDim2.new(0.845, 0, 0.5, 0)
	field.AnchorPoint = Vector2.new(0.5, 0.5)
	field.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	field.BackgroundTransparency = 0.6
	field.ZIndex = 26
	field.Parent = main
	aplicarBordaPreta(field)

	local line = Instance.new("Frame")
	line.Name = "Underline"
	line.Size = UDim2.new(0.7, 0, 0, 1)
	line.Position = UDim2.new(0.5, 0, 1, 0)
	line.AnchorPoint = Vector2.new(0.5, 1)
	line.BackgroundColor3 = TEXT
	line.BackgroundTransparency = 0.4
	line.ZIndex = 27
	line.Parent = field

	local box = Instance.new("TextBox")
	box.Name = "Input"
	box.Size = UDim2.new(0.9, 0, 0.56, 0)
	box.Position = UDim2.new(0.5, 0, 0.5, 0)
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.BackgroundTransparency = 1
	box.PlaceholderText = placeholder or ""
	box.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
	box.Text = ""
	box.TextColor3 = TEXT
	box.Font = Enum.Font.Gotham
	box.TextScaled = true
	box.ZIndex = 28
	box.Parent = field
	aplicarContornoTexto(box, 1)
	return holder, box
end

local function adicionarBotaoCriar(parent, callback, getText)
	local holder, main = criarLinhaFuncao(parent, 51)
	holder.Name = "Create New Config"
	criarTextoLinha(main, "Create New Config", UDim2.new(0.62, 0, 0.4, 0), UDim2.new(0.025, 0, 0.34, 0))

	local note = Instance.new("TextLabel")
	note.Name = "Note"
	note.Size = UDim2.new(0.62, 0, 0.28, 0)
	note.Position = UDim2.new(0.025, 0, 0.75, 0)
	note.AnchorPoint = Vector2.new(0, 0.5)
	note.BackgroundTransparency = 1
	note.Text = "New config copies current settings"
	note.TextColor3 = TEXT
	note.Font = Enum.Font.Gotham
	note.TextScaled = true
	note.TextXAlignment = Enum.TextXAlignment.Left
	note.ZIndex = 25
	note.Parent = main
	aplicarContornoTexto(note, 1)

	local action = Instance.new("TextButton")
	action.Name = "Action"
	action.Size = UDim2.new(0.2, 0, 0.5, 0)
	action.Position = UDim2.new(0.885, 0, 0.5, 0)
	action.AnchorPoint = Vector2.new(0.5, 0.5)
	action.BackgroundTransparency = 1
	action.Text = ""
	action.ZIndex = 26
	action.Parent = main

	local btnMain = Instance.new("Frame")
	btnMain.Name = "Main"
	btnMain.Size = UDim2.new(1, 0, 0.92, 0)
	btnMain.Position = UDim2.new(0.5, 0, 0.5, 0)
	btnMain.AnchorPoint = Vector2.new(0.5, 0.5)
	btnMain.BackgroundColor3 = RED
	btnMain.ZIndex = 26
	btnMain.Parent = action
	aplicarBordaPreta(btnMain)

	local color = Instance.new("Frame")
	color.Name = "ColorFrame"
	color.Size = UDim2.new(1, 0, 0.9, 0)
	color.Position = UDim2.new(0.5, 0, 0, 0)
	color.AnchorPoint = Vector2.new(0.5, 0)
	color.BackgroundColor3 = TEXT
	color.ZIndex = 27
	color.Parent = btnMain
	aplicarDegradeVertical(color, Color3.fromRGB(230, 70, 70), Color3.fromRGB(120, 0, 0))

	local btnText = Instance.new("TextLabel")
	btnText.Size = UDim2.new(0.9, 0, 0.62, 0)
	btnText.Position = UDim2.new(0.5, 0, 0.5, 0)
	btnText.AnchorPoint = Vector2.new(0.5, 0.5)
	btnText.BackgroundTransparency = 1
	btnText.Text = "Create New"
	btnText.TextColor3 = TEXT
	btnText.Font = Enum.Font.GothamBold
	btnText.TextScaled = true
	btnText.ZIndex = 28
	btnText.Parent = color
	aplicarContornoTexto(btnText, 1)

	action.MouseButton1Click:Connect(function()
		tocarClique()
		local textoOriginal = btnText.Text
		btnText.Text = "Clicked!"
		task.delay(0.7, function()
			if btnText.Parent then
				btnText.Text = textoOriginal
			end
		end)
		if callback then callback(getText and getText() or "") end
	end)
	return holder
end


local function criarBotaoOriginal(parent, text, callback)
	local action = Instance.new("TextButton")
	action.Name = "Action"
	action.Size = UDim2.new(0.2, 0, 0.5, 0)
	action.Position = UDim2.new(0.885, 0, 0.5, 0)
	action.AnchorPoint = Vector2.new(0.5, 0.5)
	action.BackgroundTransparency = 1
	action.Text = ""
	action.AutoButtonColor = false
	action.ZIndex = 26
	action.Parent = parent

	local btnMain = Instance.new("Frame")
	btnMain.Name = "Main"
	btnMain.Size = UDim2.new(1, 0, 0.92, 0)
	btnMain.Position = UDim2.new(0.5, 0, 0.5, 0)
	btnMain.AnchorPoint = Vector2.new(0.5, 0.5)
	btnMain.BackgroundColor3 = RED
	btnMain.ZIndex = 26
	btnMain.Parent = action
	aplicarBordaPreta(btnMain)

	local color = Instance.new("Frame")
	color.Name = "ColorFrame"
	color.Size = UDim2.new(1, 0, 0.9, 0)
	color.Position = UDim2.new(0.5, 0, 0, 0)
	color.AnchorPoint = Vector2.new(0.5, 0)
	color.BackgroundColor3 = TEXT
	color.ZIndex = 27
	color.Parent = btnMain
	aplicarDegradeVertical(color, Color3.fromRGB(230, 70, 70), Color3.fromRGB(120, 0, 0))

	local btnText = Instance.new("TextLabel")
	btnText.Size = UDim2.new(0.9, 0, 0.62, 0)
	btnText.Position = UDim2.new(0.5, 0, 0.5, 0)
	btnText.AnchorPoint = Vector2.new(0.5, 0.5)
	btnText.BackgroundTransparency = 1
	btnText.Text = text
	btnText.TextColor3 = TEXT
	btnText.Font = Enum.Font.GothamBold
	btnText.TextScaled = true
	btnText.ZIndex = 28
	btnText.Parent = color
	aplicarContornoTexto(btnText, 1)

	action.MouseButton1Click:Connect(function()
		tocarClique()
		local textoOriginal = btnText.Text
		btnText.Text = "Clicked!"
		task.delay(0.7, function()
			if btnText.Parent then
				btnText.Text = textoOriginal
			end
		end)
		if callback then callback() end
	end)
	return action, btnText
end

local function adicionarBotao(parent, text, callback)
	local holder, main = criarLinhaFuncao(parent, 38)
	holder.Name = text
	criarTextoLinha(main, text, UDim2.new(0.62, 0, 0.64, 0), UDim2.new(0.025, 0, 0.5, 0))
	criarBotaoOriginal(main, text, callback)
	return holder
end

local function adicionarTeleport(parent, placeName, callback)
	local holder, main = criarLinhaFuncao(parent, 38)
	holder.Name = placeName
	criarTextoLinha(main, placeName, UDim2.new(0.62, 0, 0.64, 0), UDim2.new(0.025, 0, 0.5, 0))
	criarBotaoOriginal(main, "Teleport", callback)
	return holder
end

	local function rockOptionsSorted()
		local list = {}
		for name, dura in pairs(RockData) do
			table.insert(list, {name = name, dura = dura})
		end
		table.sort(list, function(a, b) return a.dura > b.dura end)
		local o = {}
		for _, item in ipairs(list) do table.insert(o, item.name) end
		if #o == 0 then table.insert(o, "None") end
		return o
	end

	local function brawlPlayerOpts()
		local o = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then table.insert(o, p.Name) end
		end
		if #o == 0 then table.insert(o, "No players") end
		table.sort(o)
		return o
	end

	local function formatStatNum(n)
		n = tonumber(n) or 0
		if n >= 1e15 then return string.format("%.2fQa", n/1e15) end
		if n >= 1e12 then return string.format("%.2fT", n/1e12) end
		if n >= 1e9 then return string.format("%.2fB", n/1e9) end
		if n >= 1e6 then return string.format("%.2fM", n/1e6) end
		if n >= 1e3 then return string.format("%.2fK", n/1e3) end
		return tostring(math.floor(n))
	end

	local function formatBossNum(n)
		n = tonumber(n) or 0
		if n >= 1e12 then return string.format("%.2fT", n/1e12) end
		if n >= 1e9 then return string.format("%.2fB", n/1e9) end
		if n >= 1e6 then return string.format("%.2fM", n/1e6) end
		if n >= 1e3 then return string.format("%.2fK", n/1e3) end
		return tostring(math.floor(n))
	end

	local function formatBossCountdown(seconds)
		seconds = math.max(0, math.floor(tonumber(seconds) or 0))
		local hours = math.floor(seconds / 3600)
		local minutes = math.floor((seconds % 3600) / 60)
		local secs = seconds % 60
		return string.format("%dh %dm %ds", hours, minutes, secs)
	end

	-- Farm: rep, exercise, rocks, strength, quest
	local playerPage = criarPagina("Player")
	local secSize = criarSecao(playerPage, "Size", true)
	adicionarSlider(secSize, "Size", 1, 100, State.Size, "", function(v) State.Size = v markDirty() end)
	adicionarInterruptor(secSize, "Set Size", State.SetSize, function(v) State.SetSize = v markDirty() end)
	local secSpeed = criarSecao(playerPage, "Speed", true)
	adicionarSlider(secSpeed, "Speed", 16, 500, State.Speed, "", function(v) State.Speed = v markDirty() end)
	adicionarInterruptor(secSpeed, "Set Speed", State.SetSpeed, function(v) State.SetSpeed = v markDirty() end)
	local secFov = criarSecao(playerPage, "Fov", true)
	adicionarSlider(secFov, "Fov", 1, 250, State.FOV, "", function(v) State.FOV = v markDirty() end)
	adicionarInterruptor(secFov, "Set Fov", State.SetFOV, function(v)
		State.SetFOV = v
		if Camera then Camera.FieldOfView = v and State.FOV or 70 end
		markDirty()
	end)
	local secMove = criarSecao(playerPage, "Movement", true)
	adicionarInterruptor(secMove, "Walk On Water", State.WalkWater, function(v)
		State.WalkWater = v
		if _G.MLWater then
			for _, p in ipairs(_G.MLWater) do
				if p and p.Parent then p.CanCollide = v end
			end
		end
		markDirty()
	end)
	adicionarInterruptor(secMove, "Infinite Jump", State.InfJump, function(v) State.InfJump = v markDirty() end)

	local farmPage = criarPagina("Farm")
	local secRep = criarSecao(farmPage, "Auto Rep", true)
	adicionarSlider(secRep, "Reps Per Second", 1, 600, State.AutoRepSpeed or 10, "", function(v)
		State.AutoRepSpeed = math.clamp(math.floor(tonumber(v) or 10), 1, 600)
		markDirty()
	end)
	adicionarInterruptor(secRep, "Auto Rep", State.AutoRep, function(v) State.AutoRep = v markDirty() end)
	local secEx = criarSecao(farmPage, "Exercises", true)
	adicionarLista(secEx, "Select Exercise", {"Weight", "Pushups", "Situps", "Handstands"}, State.Exercise or "Weight", false, function(v)
		State.Exercise = v
		markDirty()
	end)
	adicionarInterruptor(secEx, "Start Exercising", State.AutoExercise, function(v)
		State.AutoExercise = v
		if v then
			machineState.Squat.Running = false
			machineState.Lift.Running = false
			State.AutoSquat = false
			State.AutoLift = false
		end
		markDirty()
	end)
	if #SquatNames > 0 then
		adicionarLista(secEx, "Select Squat", SquatNames, State.SelectedSquat, false, function(v)
			State.SelectedSquat = v
			markDirty()
		end)
	end
	adicionarInterruptor(secEx, "Auto Squat", State.AutoSquat, function(v)
		State.AutoSquat = v
		machineState.Squat.Running = v
		machineState.Squat.Active = nil
		if v then
			State.AutoExercise = false
			machineState.Lift.Running = false
			State.AutoLift = false
			machineState.Squat.Reenter = 0
			runMachine("Squat")
		else
			machineJumpOnce()
		end
		markDirty()
	end)
	if #LiftNames > 0 then
		adicionarLista(secEx, "Select Lift", LiftNames, State.SelectedLift, false, function(v)
			State.SelectedLift = v
			markDirty()
		end)
	end
	adicionarInterruptor(secEx, "Auto Lift", State.AutoLift, function(v)
		State.AutoLift = v
		machineState.Lift.Running = v
		machineState.Lift.Active = nil
		if v then
			State.AutoExercise = false
			machineState.Squat.Running = false
			State.AutoSquat = false
			machineState.Lift.Reenter = 0
			runMachine("Lift")
		else
			machineJumpOnce()
		end
		markDirty()
	end)
	local secRock = criarSecao(farmPage, "Rocks", true)
	adicionarLista(secRock, "Select Rock", rockOptionsSorted(), State.SelectedRock, false, function(v)
		State.SelectedRock = v
		markDirty()
	end)
	adicionarInterruptor(secRock, "Auto Rock", State.AutoRock, function(v) State.AutoRock = v markDirty() end)
	local secStr = criarSecao(farmPage, "Better Strength", false)
	adicionarInterruptor(secStr, "Pushup + Industrial Rock", State.PushupIndustrial, function(v) State.PushupIndustrial = v markDirty() end)
	adicionarInterruptor(secStr, "Pushup + Jungle Rock", State.PushupJungle, function(v) State.PushupJungle = v markDirty() end)
	adicionarInterruptor(secStr, "Pushup + Muscle King Rock", State.PushupKing, function(v) State.PushupKing = v markDirty() end)
	adicionarInterruptor(secStr, "Pushup + Legends Rock", State.PushupLegends, function(v) State.PushupLegends = v markDirty() end)
	local secQuest = criarSecao(farmPage, "Enchant Quests", false)
	adicionarInterruptor(secQuest, "Auto Quest Farm", State.AutoQuestFarm, function(v)
		State.AutoQuestFarm = v
		if not v then unequipTools() end
		markDirty()
	end)
	adicionarInterruptor(secQuest, "Auto Collect Quests", State.AutoQuestCollect, function(v) State.AutoQuestCollect = v markDirty() end)
	local secClan = criarSecao(farmPage, "Clan", false)
	adicionarInterruptor(secClan, "Collect Clan Quest", State.AutoClanQuest, function(v) State.AutoClanQuest = v markDirty() end)

	local rebirthPage = criarPagina("Rebirth")
	local secRbStat = criarSecao(rebirthPage, "Status View", true)
	local _, lblStr = adicionarStatus(secRbStat, "Strength: 0")
	local _, lblRb = adicionarStatus(secRbStat, "Rebirth: 0")
	task.spawn(function()
		while lblStr and lblStr.Parent do
			pcall(function()
				local ls = LocalPlayer:FindFirstChild("leaderstats")
				local strVal = ls and ls:FindFirstChild("Strength")
				local rbVal = ls and ls:FindFirstChild("Rebirths")
				local strength = ParseValue(strVal and strVal.Value or 0)
				local rebirths = 0
				if rbVal then
					if typeof(rbVal.Value) == "number" then rebirths = rbVal.Value
					else rebirths = ParseValue(rbVal.Value) end
				end
				lblStr.Text = "Strength: " .. formatStatNum(strength)
				lblRb.Text = "Rebirth: " .. formatStatNum(rebirths)
			end)
			task.wait(0.25)
		end
	end)
	local secRb = criarSecao(rebirthPage, "Rebirth", true)
	local _, targetBox = adicionarCampoNome(secRb, "Rebirth Target", tostring(State.RebirthTarget or 0))
	targetBox.Text = tostring(State.RebirthTarget or 0)
	targetBox.FocusLost:Connect(function()
		local n = tonumber(targetBox.Text)
		if n and n >= 0 then State.RebirthTarget = n end
	end)
	adicionarInterruptor(secRb, "Auto Rebirth", State.AutoRebirth, function(v) State.AutoRebirth = v end)
	adicionarInterruptor(secRb, "Auto Fast Rebirth", State.AutoFastRebirth, function(v) State.AutoFastRebirth = v end)
	local secMore = criarSecao(rebirthPage, "Mores", false)
	adicionarInterruptor(secMore, "Lock Position", State.LockPos, function(v)
		State.LockPos = v
		if v then
			local r = root()
			if r then State.LockPosVec = r.Position end
		else
			local r = root()
			if r then
				local bp = r:FindFirstChild("PositionLocker")
				if bp then bp:Destroy() end
			end
			State.LockPosVec = nil
		end
	end)
	adicionarInterruptor(secMore, "Auto Size 1", State.AutoSize1, function(v) State.AutoSize1 = v end)
	adicionarInterruptor(secMore, "Auto Muscle King", State.AutoKing, function(v) State.AutoKing = v end)

	local combatPage = criarPagina("Combat")
	local secBossSt = criarSecao(combatPage, "Boss Status", true)
	local _, lblPhase = adicionarStatus(secBossSt, "Waiting For Boss")
	local _, lblBoss = adicionarStatus(secBossSt, "Boss: None")
	local _, lblHp = adicionarStatus(secBossSt, "Health: 0 / 0")
	local _, lblNext = adicionarStatus(secBossSt, "Next Boss: N/A")
	task.spawn(function()
		while lblPhase and lblPhase.Parent do
			pcall(function()
				local model = select(1, findBoss())
				if not model then
					lblPhase.Text = "Waiting For Boss"
					lblPhase.TextColor3 = TEXT
					lblBoss.Text = "Boss: None"
					lblBoss.TextColor3 = TEXT
					lblHp.Text = "Health: None"
					lblHp.TextColor3 = TEXT
					local nextTime = Workspace:GetAttribute("BossSpawnNextTime")
					if typeof(nextTime) == "number" then
						lblNext.Text = "Next Boss: " .. formatBossCountdown(nextTime - Workspace:GetServerTimeNow())
					else
						lblNext.Text = "Next Boss: N/A"
					end
					return
				end
				local display = Workspace:GetAttribute("BossDisplayName") or model.Name
				local stats = model:FindFirstChild("stats")
				local health = stats and stats:FindFirstChild("Health")
				local maxH = stats and (stats:FindFirstChild("MaxHealth") or stats:FindFirstChild("maxHealth"))
				local hp = health and health.Value or Workspace:GetAttribute("BossHealth") or 0
				local mhp = maxH and maxH.Value or Workspace:GetAttribute("BossMaxHealth") or hp
				local phase = "Boss Present"
				if State.AutoFarmSeconds and BossPrepActive then phase = "Tool Farm"
				elseif State.AutoKillBoss then phase = "Attacking" end
				local function rarityColor(name)
					local n = string.lower(tostring(name or ""))
					if string.find(n, "admin", 1, true) or string.find(n, "rainbow", 1, true) or string.find(n, "godly", 1, true) then
						local t = os.clock() % 3
						if t < 1 then return Color3.fromRGB(255, 70, 70)
						elseif t < 2 then return Color3.fromRGB(70, 255, 120)
						else return Color3.fromRGB(80, 140, 255) end
					end
					if string.find(n, "myth", 1, true) then return Color3.fromRGB(220, 40, 50) end
					if string.find(n, "legend", 1, true) then return Color3.fromRGB(255, 140, 30) end
					if string.find(n, "epic", 1, true) then return Color3.fromRGB(160, 70, 255) end
					if string.find(n, "rare", 1, true) then return Color3.fromRGB(60, 130, 255) end
					if string.find(n, "common", 1, true) then return Color3.fromRGB(160, 160, 170) end
					return Color3.fromRGB(210, 210, 210)
				end
				local function hpColor(cur, maxv)
					maxv = tonumber(maxv) or 0
					cur = tonumber(cur) or 0
					if maxv <= 0 or cur <= 0 then return TEXT end
					local ratio = cur / maxv
					if ratio > 0.5 then return Color3.fromRGB(50, 205, 90) end
					if ratio > 0.25 then return Color3.fromRGB(255, 150, 40) end
					return Color3.fromRGB(220, 40, 40)
				end
				lblPhase.Text = phase
				lblPhase.TextColor3 = TEXT
				lblBoss.Text = "Boss: " .. tostring(display)
				lblBoss.TextColor3 = rarityColor(display)
				if tonumber(mhp) and tonumber(mhp) > 0 then
					lblHp.Text = string.format("Health: %s / %s", formatBossNum(hp), formatBossNum(mhp))
					lblHp.TextColor3 = hpColor(hp, mhp)
				else
					lblHp.Text = "Health: None"
					lblHp.TextColor3 = TEXT
				end
				lblNext.Text = "Next Boss: Current Boss Active"
				lblNext.TextColor3 = TEXT
			end)
			task.wait(0.25)
		end
	end)
	local secBoss = criarSecao(combatPage, "Boss Farm", true)
	adicionarSlider(secBoss, "Time Farm", 5, 100, State.TimeFarm or 12, "s", function(v)
		State.TimeFarm = math.clamp(math.floor(tonumber(v) or 12), 5, 100)
		markDirty()
	end)
	adicionarInterruptor(secBoss, "Auto Farm Seconds", State.AutoFarmSeconds, function(v) State.AutoFarmSeconds = v markDirty() end)
	adicionarInterruptor(secBoss, "Auto Kill Boss", State.AutoKillBoss, function(v) State.AutoKillBoss = v markDirty() end)
	adicionarInterruptor(secBoss, "Auto Boss Chest", State.AutoBossChest, function(v)
		State.AutoBossChest = v
		if v then hideBossPrompts() end
		markDirty()
	end)
	adicionarInterruptor(secBoss, "Continue Farming After Boss Kill", State.ContinueBoss, function(v) State.ContinueBoss = v markDirty() end)
	local secBrawl = criarSecao(combatPage, "Brawl", true)
	adicionarLista(secBrawl, "WhiteList Player", brawlPlayerOpts(), State.Whitelist or {}, true, function(v)
		if type(v) == "table" then
			State.Whitelist = {}
			for _, name in ipairs(v) do
				if name ~= "No players" then table.insert(State.Whitelist, name) end
			end
		end
		markDirty()
	end)
	adicionarInterruptor(secBrawl, "Auto Join In Brawl", State.AutoJoinBrawl, function(v) State.AutoJoinBrawl = v markDirty() end)
	adicionarInterruptor(secBrawl, "Auto Kill In Brawl", State.AutoKillBrawl, function(v)
		State.AutoKillBrawl = v
		if not v and ESPFolder then ESPFolder:ClearAllChildren() end
		markDirty()
	end)
	adicionarInterruptor(secBrawl, "Auto Reset Brawl", State.AutoResetBrawl, function(v) State.AutoResetBrawl = v markDirty() end)

	local worldPage = criarPagina("World")
	local secIsl = criarSecao(worldPage, "Islands", true)
	for _, name in ipairs({"Tiny Island", "Main Island", "Beach"}) do
		local cf = Teleports[name]
		adicionarTeleport(secIsl, name, function()
			local r = root()
			if r and cf then r.CFrame = cf end
		end)
	end
	local secGym = criarSecao(worldPage, "Gyms", true)
	for _, name in ipairs({
		"Overcharged Gym", "Industrial Gym", "Jungle Gym", "Muscle King Gym",
		"Legends Gym", "Infernal Gym", "Mythical Gym", "Frost Gym"
	}) do
		local cf = Teleports[name]
		adicionarTeleport(secGym, name, function()
			local r = root()
			if r and cf then r.CFrame = cf end
		end)
	end
	local secRew = criarSecao(worldPage, "Rewards", true)
	adicionarInterruptor(secRew, "Spin Fortune Wheel", State.SpinFortune, function(v) State.SpinFortune = v markDirty() end)
	local secCons = criarSecao(worldPage, "Consumables", true)
	adicionarInterruptor(secCons, "Eat All Eggs", State.EatEggs, function(v) State.EatEggs = v markDirty() end)
	adicionarInterruptor(secCons, "Eat All Boosts", State.EatBoosts, function(v) State.EatBoosts = v markDirty() end)

	local serverPage = criarPagina("Server")
	local secSess = criarSecao(serverPage, "Session", true)
	adicionarInterruptor(secSess, "Auto Load Script", State.AutoLoad, function(v)
		State.AutoLoad = v
		if v then setupQueueOnTeleport() end
		markDirty()
	end)
	adicionarInterruptor(secSess, "Auto Rejoin (1 Hour)", State.AutoRejoin, function(v) State.AutoRejoin = v markDirty() end)
	adicionarInterruptor(secSess, "Auto Reconnect", State.AutoReconnect, function(v) State.AutoReconnect = v markDirty() end)
	adicionarBotao(secSess, "Server Hop", function() serverHop() end)
	local secWh = criarSecao(serverPage, "Webhook", false)
	local _, hookBox = adicionarCampoNome(secWh, "Webhook URL", "webhook...")
	hookBox.Text = tostring(State.WebhookURL or "")
	hookBox.FocusLost:Connect(function()
		State.WebhookURL = tostring(hookBox.Text or "")
		markDirty()
	end)
	adicionarInterruptor(secWh, "Ping @everyone", State.WebhookPingEveryone, function(v) State.WebhookPingEveryone = v markDirty() end)
	adicionarLista(secWh, "Boss Rarity", BossRarityOptions, listSelectedWebhookBosses(), true, function(v)
		if type(v) == "table" then
			local map = {}
			for _, name in ipairs(v) do map[name] = true end
			for k, val in pairs(v) do
				if type(k) == "string" and val == true then map[k] = true end
				if type(val) == "string" then map[val] = true end
			end
			State.WebhookSelectedBosses = map
		elseif type(v) == "string" then
			State.WebhookSelectedBosses = State.WebhookSelectedBosses or {}
			if State.WebhookSelectedBosses[v] then State.WebhookSelectedBosses[v] = nil
			else State.WebhookSelectedBosses[v] = true end
		end
		markDirty()
	end)
	adicionarInterruptor(secWh, "Boss Notification", State.WebhookBossNotify, function(v) State.WebhookBossNotify = v markDirty() end)
	adicionarInterruptor(secWh, "Disconnect Notification", State.WebhookDisconnectNotify, function(v) State.WebhookDisconnectNotify = v markDirty() end)
	adicionarBotao(secWh, "Test Webhook", function()
		sendDiscordWebhook(nil, {{
			title = "Test Notification",
			description = "Webhook is working correctly.",
			color = 5763719,
			fields = {
				{ name = "Player", value = LocalPlayer.DisplayName .. " (`@" .. LocalPlayer.Name .. "`)", inline = true },
				{ name = "Place", value = tostring(game.PlaceId), inline = true },
			},
			footer = { text = "Supreme Hub • Muscle Legends" },
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}})
	end)

	local miscPage = criarPagina("Misc")
	local secTime = criarSecao(miscPage, "Time", true)
	adicionarLista(secTime, "Change Time", {"Day", "Noon", "Afternoon", "Night", "Midnight"}, State.TimeMode or "Day", false, function(v)
		State.TimeMode = v
		local map = {Day = 9, Noon = 12, Afternoon = 16, Night = 0, Midnight = 2}
		Lighting.ClockTime = map[v] or 9
		markDirty()
	end)
	adicionarBotao(secTime, "Reset Time", function()
		Lighting.ClockTime = NormalClockTime
		State.TimeMode = "Day"
		markDirty()
	end)
	local secRend = criarSecao(miscPage, "Render", true)
	adicionarInterruptor(secRend, "Render 3D", State.Render3D, function(v) setRender3D(v) end)
	local secHide = criarSecao(miscPage, "Hides", false)
	adicionarInterruptor(secHide, "Hide Players", State.HidePlayers, function(v)
		State.HidePlayers = v
		applyHidePlayers()
		markDirty()
	end)
	adicionarInterruptor(secHide, "Hide Sounds", State.HideSound, function(v)
		State.HideSound = v
		applyHideSound()
		markDirty()
	end)
	local secPerf = criarSecao(miscPage, "Performance", true)
	adicionarInterruptor(secPerf, "Optimizer", State.Optimizer, function(v)
		State.Optimizer = v
		applyOptimizer()
		markDirty()
	end)
	adicionarBotao(secPerf, "Save JSON", function()
		saveConfig()
	end)

	local keyPage = criarPagina("KeyBind")
	local secKeys = criarSecao(keyPage, "KeyBind", true)
	State.Keybinds = State.Keybinds or {}
	for _, info in ipairs(KeybindList) do
		local holder, main = criarLinhaFuncao(secKeys, 38)
		holder.Name = info.name
		criarTextoLinha(main, info.name, UDim2.new(0.68, 0, 0.64, 0), UDim2.new(0.025, 0, 0.5, 0))
		local slot = Instance.new("Frame")
		slot.Name = "KeySlot"
		slot.Size = UDim2.fromOffset(42, 22)
		slot.Position = UDim2.new(1, -8, 0.5, 0)
		slot.AnchorPoint = Vector2.new(1, 0.5)
		slot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		slot.BackgroundTransparency = 0.35
		slot.ZIndex = 26
		slot.Parent = main
		aplicarBordaPreta(slot, 1.8)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -6, 1, -4)
		box.Position = UDim2.new(0.5, 0, 0.5, 0)
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.BackgroundTransparency = 1
		box.PlaceholderText = "Key"
		box.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
		box.Text = tostring(State.Keybinds[info.name] or "")
		box.TextColor3 = TEXT
		box.Font = Enum.Font.GothamBold
		box.TextScaled = true
		box.ClearTextOnFocus = false
		box.ZIndex = 28
		box.Parent = slot
		aplicarContornoTexto(box, 1)
		info.key = string.upper(box.Text)
		box.FocusLost:Connect(function()
			local key = string.upper((box.Text or ""):gsub("%s", ""))
			box.Text = key
			info.key = key
			State.Keybinds[info.name] = key
			markDirty()
		end)
	end
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if UserInputService:GetFocusedTextBox() then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local key = input.KeyCode.Name
		for _, info in ipairs(KeybindList) do
			if info.key ~= "" and info.key == key then
				info.set(not info.get())
			end
		end
	end)

	for name, btn in pairs(sideButtonRefs) do
		btn.MouseButton1Click:Connect(function()
			if pages[name] then abrirPagina(name) end
		end)
	end
	abrirPagina("Player")

	-- HUD button. Missing BTNList does not stop the script.
	local gameGui = playerGui:FindFirstChild("gameGui") or playerGui:WaitForChild("gameGui", 15)
	local hudNewMenu = gameGui and (gameGui:FindFirstChild("hudNewMenu") or gameGui:WaitForChild("hudNewMenu", 10))
	local middleLeft = hudNewMenu and (hudNewMenu:FindFirstChild("MiddleLeft") or hudNewMenu:WaitForChild("MiddleLeft", 5))
	local btnList = middleLeft and (middleLeft:FindFirstChild("BTNList") or middleLeft:WaitForChild("BTNList", 5))

	local isAnimating = false
	local isOpen = false
	local tweenOpenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tweenCloseInfo = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

	local function abrirMenu()
		if isAnimating or isOpen then return end
		isAnimating = true
		isOpen = true
		customMenuFrame.Position = posFechada
		customMenuFrame.Visible = true
		local tween = TweenService:Create(customMenuFrame, tweenOpenInfo, {Position = posAberta})
		tween:Play()
		tween.Completed:Connect(function() isAnimating = false end)
	end

	local function fecharMenu()
		if isAnimating or not isOpen then return end
		isAnimating = true
		isOpen = false
		local tween = TweenService:Create(customMenuFrame, tweenCloseInfo, {Position = posFechada})
		tween:Play()
		tween.Completed:Connect(function()
			customMenuFrame.Visible = false
			isAnimating = false
		end)
	end
	openKeyBind = function()
		if pages["KeyBind"] then abrirPagina("KeyBind") end
		if not isOpen then abrirMenu() end
	end

	if btnList then
		local oldMenu = btnList:FindFirstChild("Menu")
		if oldMenu then oldMenu:Destroy() end
		local targetButton = btnList:FindFirstChild("Status") or btnList:FindFirstChild("Stats")
		local menuFrame = Instance.new("Frame")
		menuFrame.Name = "Menu"
		menuFrame.Size = UDim2.new(1.0003, 0, 0.1769, 0)
		menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		menuFrame.BackgroundTransparency = 1
		menuFrame.ZIndex = 20
		menuFrame.Parent = btnList
		if targetButton then
			menuFrame.LayoutOrder = targetButton.LayoutOrder - 1
			menuFrame.Position = targetButton.Position
		else
			menuFrame.LayoutOrder = 0
			menuFrame.Position = UDim2.new(0.5, 0, 0.46, 0)
		end
		local container = Instance.new("ImageButton")
		container.Name = "Container"
		container.Size = UDim2.new(1.0511, 0, 1.0511, 0)
		container.Position = UDim2.new(0.51, 0, 0.5, 0)
		container.AnchorPoint = Vector2.new(0.5, 0.5)
		container.BackgroundTransparency = 1
		container.Image = "rbxassetid://124788545790346"
		container.ImageColor3 = Color3.fromRGB(210, 35, 35)
		container.ScaleType = Enum.ScaleType.Fit
		container.AutoButtonColor = false
		container.ZIndex = 21
		container.Parent = menuFrame
		local btnLabel = Instance.new("TextLabel")
		btnLabel.Size = UDim2.new(0.8464, 0, 0.6202, 0)
		btnLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		btnLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		btnLabel.BackgroundTransparency = 1
		btnLabel.Text = "MENU"
		btnLabel.TextColor3 = TEXT
		btnLabel.Font = Enum.Font.GothamBold
		btnLabel.TextScaled = true
		btnLabel.ZIndex = 22
		btnLabel.Parent = container
		aplicarContornoTexto(btnLabel, 1.25)
		local clickSound = createClickSound(container)
		local hoverSound = createHoverSound(container)
		local colorNormalHud = Color3.fromRGB(210, 35, 35)
		local colorHoverHud = Color3.fromRGB(245, 55, 55)
		local sizeNormalHud = UDim2.new(1.0511, 0, 1.0511, 0)
		local sizeHoverHud = UDim2.new(1.12, 0, 1.12, 0)
		local sizePressHud = UDim2.new(0.95, 0, 0.95, 0)
		local tweenBtn = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		container.MouseEnter:Connect(function()
			hoverSound:Play()
			TweenService:Create(container, tweenBtn, {ImageColor3 = colorHoverHud, Size = sizeHoverHud}):Play()
		end)
		container.MouseLeave:Connect(function()
			TweenService:Create(container, tweenBtn, {ImageColor3 = colorNormalHud, Size = sizeNormalHud}):Play()
		end)
		container.MouseButton1Down:Connect(function()
			TweenService:Create(container, tweenBtn, {Size = sizePressHud}):Play()
		end)
		container.MouseButton1Up:Connect(function()
			TweenService:Create(container, tweenBtn, {Size = sizeHoverHud}):Play()
		end)
		container.MouseButton1Click:Connect(function()
			clickSound:Play()
			if isOpen then fecharMenu() else abrirMenu() end
		end)
	else
		warn("[Menu Button] BTNList nao encontrada")
	end

	exitButton.MouseButton1Click:Connect(function()
		fecharMenu()
	end)
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.RightControl then
			if isOpen then fecharMenu() else abrirMenu() end
		end
	end)

end

buildUi()


-- Resume machines
task.defer(function()
	if State.AutoSquat then
		machineState.Squat.Running = true
		runMachine("Squat")
	end
	if State.AutoLift then
		machineState.Lift.Running = true
		runMachine("Lift")
	end
end)

-- ==========================================
-- AUTO FAST REBIRTH
-- ==========================================
task.spawn(function()
	local STRENGTH_PET_PRIORITY = {
		"Inferno Drake", "Omega Overlord", "Swift Samurai",
		"Mythic Boss Pet", "Legendary Boss Pet", "Rainbow Boss Pet", "Epic Boss Pet",
	}
	local REBIRTH_PET_PRIORITY = { "Titanium Hydra", "Tribal Overlord" }

	local function getEquipPetRemote()
		local ev = ReplicatedStorage:FindFirstChild("rEvents")
		return ev and ev:FindFirstChild("equipPetEvent")
	end

	local function findAllPetsNamed(petName)
		local found = {}
		local folder = LocalPlayer:FindFirstChild("petsFolder")
		if not folder then return found end
		for _, rar in ipairs(folder:GetChildren()) do
			for _, pet in ipairs(rar:GetChildren()) do
				if pet.Name == petName then table.insert(found, pet) end
			end
		end
		return found
	end

	local function collectOwnedPetsByPriority(priorityList)
		local owned, seen = {}, {}
		for _, name in ipairs(priorityList) do
			for _, pet in ipairs(findAllPetsNamed(name)) do
				if not seen[pet] then seen[pet] = true table.insert(owned, pet) end
			end
		end
		return owned
	end

	local function getEquippedPetNames()
		local names = {}
		local eq = LocalPlayer:FindFirstChild("equippedPets")
		if not eq then return names end
		for i = 1, 12 do
			local slot = eq:FindFirstChild("pet" .. tostring(i))
			if slot then
				local val = slot.Value
				if typeof(val) == "Instance" then table.insert(names, val.Name)
				elseif val ~= nil and val ~= false and tostring(val) ~= "" and tostring(val) ~= "nil" then
					table.insert(names, tostring(val))
				end
			end
		end
		return names
	end

	local function equipPetInstance(pet)
		local remote = getEquipPetRemote()
		if not remote or not pet then return end
		pcall(function() remote:FireServer("equipPet", pet) end)
	end

	local function unequipPetInstance(pet)
		local remote = getEquipPetRemote()
		if not remote or not pet then return end
		pcall(function() remote:FireServer("unequipPet", pet) end)
	end

	local function isNameInList(name, list)
		for _, n in ipairs(list) do if n == name then return true end end
		return false
	end

	local function unequipPetsNotInPriority(priorityList)
		local eq = LocalPlayer:FindFirstChild("equippedPets")
		if not eq then return end
		for i = 1, 12 do
			local slot = eq:FindFirstChild("pet" .. tostring(i))
			if slot then
				local val = slot.Value
				local name, inst = nil, nil
				if typeof(val) == "Instance" then name = val.Name inst = val
				elseif val ~= nil and val ~= false and tostring(val) ~= "" and tostring(val) ~= "nil" then
					name = tostring(val)
					inst = findAllPetsNamed(name)[1]
				end
				if name and not isNameInList(name, priorityList) and inst then
					unequipPetInstance(inst)
					task.wait(0.06)
				end
			end
		end
	end

	local function equipPriorityPetsMixed(priorityList)
		unequipPetsNotInPriority(priorityList)
		task.wait(0.1)
		local owned = collectOwnedPetsByPriority(priorityList)
		local toEquip = math.min(#owned, 12)
		if toEquip <= 0 then return 0 end
		for i = 1, toEquip do
			equipPetInstance(owned[i])
			task.wait(0.08)
		end
		return toEquip
	end

	local function countEquippedFromPriority(priorityList)
		local n = 0
		for _, name in ipairs(getEquippedPetNames()) do
			if isNameInList(name, priorityList) then n = n + 1 end
		end
		return n
	end

	local function hasAllPriorityPetsEquipped(priorityList)
		local owned = collectOwnedPetsByPriority(priorityList)
		if #owned == 0 then return false end
		return countEquippedFromPriority(priorityList) >= math.min(#owned, 12)
	end

	local function getLeaderStrength() return getStrength(LocalPlayer) end

	local function getRebirthRequirement()
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		local gg = pg and pg:FindFirstChild("gameGui")
		local menu = gg and gg:FindFirstChild("rebirthNewMenu")
		if not menu then return 0 end
		local content = menu:FindFirstChild("Content")
		local top = content and content:FindFirstChild("TopBG")
		local amount = top and top:FindFirstChild("AmountText")
		if amount and (amount:IsA("TextLabel") or amount:IsA("TextButton")) then
			return ParseValue(amount.Text)
		end
		for _, d in ipairs(menu:GetDescendants()) do
			if d.Name == "AmountText" and (d:IsA("TextLabel") or d:IsA("TextButton")) then
				return ParseValue(d.Text)
			end
		end
		return 0
	end

	local function getRebirthCount()
		local ls = LocalPlayer:FindFirstChild("leaderstats")
		local rb = ls and ls:FindFirstChild("Rebirths")
		if not rb then return 0 end
		if typeof(rb.Value) == "number" then return rb.Value end
		return ParseValue(rb.Value)
	end

	local function doWeightRepBurst()
		local h = hum()
		local bp = LocalPlayer:FindFirstChild("Backpack")
		local ch = char()
		local tool = (ch and ch:FindFirstChild("Weight")) or (bp and bp:FindFirstChild("Weight"))
		if tool and h and tool.Parent ~= ch then
			pcall(function() h:EquipTool(tool) end)
			task.wait(0.05)
		end
		for _ = 1, 20 do
			pcall(function()
				local ev = LocalPlayer:FindFirstChild("muscleEvent")
				if ev then ev:FireServer("rep") else fireRep() end
			end)
			task.wait(0.005)
		end
	end

	local function doRebirthRequest()
		pcall(function()
			local remote = ReplicatedStorage.rEvents:FindFirstChild("rebirthRemote")
			if remote then remote:InvokeServer("rebirthRequest") end
		end)
	end

	local function hasAnyRebirthPets()
		return #collectOwnedPetsByPriority(REBIRTH_PET_PRIORITY) > 0
	end

	while true do
		if not canRunFastRebirth() then
			task.wait(0.4)
		else
			equipPriorityPetsMixed(STRENGTH_PET_PRIORITY)
			local waitEquip = 0
			while canRunFastRebirth() and not hasAllPriorityPetsEquipped(STRENGTH_PET_PRIORITY) and waitEquip < 40 do
				equipPriorityPetsMixed(STRENGTH_PET_PRIORITY)
				waitEquip = waitEquip + 1
				task.wait(0.25)
			end

			local ownedStr = collectOwnedPetsByPriority(STRENGTH_PET_PRIORITY)
			if #ownedStr == 0 or hasAllPriorityPetsEquipped(STRENGTH_PET_PRIORITY) then
				local safety = 0
				while canRunFastRebirth() and safety < 600 do
					local req = getRebirthRequirement()
					local str = getLeaderStrength()
					if req > 0 and str >= req then break end
					doWeightRepBurst()
					safety = safety + 1
				end
			end

			if canRunFastRebirth() then
				local before = getRebirthCount()
				if hasAnyRebirthPets() then
					unequipPetsNotInPriority(REBIRTH_PET_PRIORITY)
					task.wait(0.1)
					equipPriorityPetsMixed(REBIRTH_PET_PRIORITY)
					local waitRb = 0
					while canRunFastRebirth() and not hasAllPriorityPetsEquipped(REBIRTH_PET_PRIORITY) and waitRb < 40 do
						equipPriorityPetsMixed(REBIRTH_PET_PRIORITY)
						waitRb = waitRb + 1
						task.wait(0.25)
					end
					if hasAllPriorityPetsEquipped(REBIRTH_PET_PRIORITY) then
						doRebirthRequest()
						task.wait(0.45)
					end
				else
					doRebirthRequest()
					task.wait(0.45)
				end
				local after = getRebirthCount()
				equipPriorityPetsMixed(STRENGTH_PET_PRIORITY)
				if after <= before then task.wait(0.55) else task.wait(0.2) end
			else
				task.wait(0.25)
			end
		end
	end
end)

notify("Supreme Hub", "Loaded")
print("[Supreme Hub] Loaded")

end

local __ok, __err = pcall(__SupremeMain)
if not __ok then
	warn("[Supreme Hub] Fatal:", __err)
end
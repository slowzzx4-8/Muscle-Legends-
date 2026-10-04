--[[
    Supreme Hub | Muscle Legends
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local NormalClockTime = Lighting.ClockTime

local CONFIG_PATH = "SupremeHub/MuscleLegends.json"

local function notify(title, text)
	-- notifications disabled
end

local function showConfirmWarning(message, onYes, onNo)
	task.spawn(function()
		local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
		local old = pg:FindFirstChild("SupremeHub_Confirm")
		if old then old:Destroy() end
		local gui = Instance.new("ScreenGui")
		gui.Name = "SupremeHub_Confirm"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 999999
		gui.Parent = pg
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(360, 160)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		frame.Parent = gui
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -20, 0, 28)
		title.Position = UDim2.fromOffset(10, 10)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 16
		title.TextColor3 = Color3.fromRGB(255, 200, 80)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = "Warning"
		title.Parent = frame
		local body = Instance.new("TextLabel")
		body.Size = UDim2.new(1, -20, 0, 50)
		body.Position = UDim2.fromOffset(10, 42)
		body.BackgroundTransparency = 1
		body.Font = Enum.Font.Gotham
		body.TextSize = 14
		body.TextColor3 = Color3.fromRGB(230, 230, 235)
		body.TextWrapped = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.Text = tostring(message)
		body.Parent = frame
		local function mkBtn(text, x, color)
			local b = Instance.new("TextButton")
			b.Size = UDim2.fromOffset(140, 34)
			b.Position = UDim2.new(0, x, 1, -48)
			b.BackgroundColor3 = color
			b.Text = text
			b.Font = Enum.Font.GothamBold
			b.TextSize = 14
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
			b.Parent = frame
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
			return b
		end
		local yes = mkBtn("Confirm", 30, Color3.fromRGB(200, 60, 60))
		local no = mkBtn("Cancel", 190, Color3.fromRGB(60, 60, 70))
		yes.MouseButton1Click:Connect(function()
			gui:Destroy()
			if onYes then onYes() end
		end)
		no.MouseButton1Click:Connect(function()
			gui:Destroy()
			if onNo then onNo() end
		end)
	end)
end

LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- ==========================================
-- VOID UI
-- ==========================================
local VoidUI
do
	local ok, err = pcall(function()
		VoidUI = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/slowzzx4-8/Ui-library/refs/heads/main/Void%20Ui%20Library.lua",
			true
		))()
	end)
	if not ok or not VoidUI or type(VoidUI) ~= "table" or not VoidUI.CreateWindow then
		notify("Supreme Hub", "UI failed: " .. tostring(err))
		warn("[Supreme Hub] UI failed:", err)
		return
	end
end

local ICON_WHITE = Color3.fromRGB(255, 255, 255)
local ACCENT_WHITE = Color3.fromRGB(230, 230, 235)

local Window = VoidUI:CreateWindow({
	Name = "Supreme Hub",
	Icon = "dumbbell",
	Theme = "Dark",
	Accent = ACCENT_WHITE,
	Font = Enum.Font.Arcade,
	IconColor = ICON_WHITE,
	TabIconColor = ICON_WHITE,
	SectionIconColor = ICON_WHITE,
	ControlIconColor = ICON_WHITE,
	ToggleKey = Enum.KeyCode.RightControl,
})

pcall(function()
	Window:EditOpenButton({
		Title = "Supreme Hub",
		Icon = "dumbbell",
		Transparency = 0.15,
		Color = ColorSequence.new(Color3.fromRGB(90, 90, 95), Color3.fromRGB(55, 55, 60)),
		IconColor = ICON_WHITE,
		StrokeThickness = 1,
	})
end)

pcall(function()
	if Window.SetAccent then Window:SetAccent(ACCENT_WHITE) end
	if Window.SetFont then Window:SetFont(Enum.Font.Arcade) end
	if Window.SetIconColor then Window:SetIconColor(ICON_WHITE) end
end)
pcall(function() if Window.Open then Window:Open() end end)

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

	AutoRebirth = false, AutoFastRebirth = false, FastStrength = false, RepControls = 100,
	RebirthTarget = 0, AutoSize1 = false, AutoKing = false,
	KillSelectedBosses = {}, -- multi boss filter for Auto Kill
	PriorityRanks = {
		AutoKillBoss = 1,
		AutoQuest = 2,
		AutoBrawl = 3,
		FastStrength = 4,
		FastRebirth = 5,
		AutoRebirth = 6,
	},
	Exercise = "Weight", AutoExercise = false, AutoSquat = false, AutoLift = false,
	SelectedSquat = nil, SelectedLift = nil, AutoRep = false,
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
	WebhookSelectedBosses = {}, -- multi: { [displayName] = true }


	TimeMode = "Day",
	Render3D = false,
	HidePets = true,
	HidePopups = true,
	HidePlayers = false,
	HideSound = false,
	Optimizer = false,
	WalkWater = true,
	Whitelist = {},
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
	if type(makefolder) == "function" then
		pcall(makefolder, "SupremeHub")
	end
end

local function serializeState()
	return {
		Size = State.Size, Speed = State.Speed, FOV = State.FOV,
		SetSize = State.SetSize, SetSpeed = State.SetSpeed, SetFOV = State.SetFOV,
		InfJump = State.InfJump, SpinFortune = State.SpinFortune, LockPos = State.LockPos,
		AutoRep = State.AutoRep,
		AutoKillBoss = State.AutoKillBoss,
		AutoFarmSeconds = State.AutoFarmSeconds,
		TimeFarm = State.TimeFarm,
		ContinueBoss = State.ContinueBoss,
		AutoBossChest = State.AutoBossChest,
		AutoJoinBrawl = State.AutoJoinBrawl,
		AutoKillBrawl = State.AutoKillBrawl,
		AutoResetBrawl = State.AutoResetBrawl,
		AutoRebirth = State.AutoRebirth, AutoFastRebirth = State.AutoFastRebirth, FastStrength = State.FastStrength,
		RepControls = State.RepControls, RebirthTarget = State.RebirthTarget,
		KillSelectedBosses = State.KillSelectedBosses,
		PriorityRanks = State.PriorityRanks,
		AutoLoad = State.AutoLoad, AutoRejoin = State.AutoRejoin, AutoReconnect = State.AutoReconnect,
		WebhookURL = State.WebhookURL,
		WebhookPingEveryone = State.WebhookPingEveryone,
		WebhookBossNotify = State.WebhookBossNotify,
		WebhookDisconnectNotify = State.WebhookDisconnectNotify,
		WebhookSelectedBosses = State.WebhookSelectedBosses,
		AutoSize1 = State.AutoSize1, AutoKing = State.AutoKing,
		Exercise = State.Exercise, AutoExercise = State.AutoExercise,
		AutoRock = State.AutoRock, SelectedRock = State.SelectedRock,
		SelectedSquat = State.SelectedSquat, SelectedLift = State.SelectedLift,
		-- Dropdown selections (string value = selected option)
		Dropdowns = {
			Exercise = State.Exercise,
			SelectedSquat = State.SelectedSquat,
			SelectedLift = State.SelectedLift,
			SelectedRock = State.SelectedRock,
			TimeMode = State.TimeMode,
			WebhookSelectedBosses = State.WebhookSelectedBosses,
			KillSelectedBosses = State.KillSelectedBosses,
			Exercise = State.Exercise,
			SelectedSquat = State.SelectedSquat,
			SelectedLift = State.SelectedLift,
			SelectedRock = State.SelectedRock,
			TimeMode = State.TimeMode,
			PriorityRanks = State.PriorityRanks,
		},
		PushupIndustrial = State.PushupIndustrial, PushupJungle = State.PushupJungle,
		PushupKing = State.PushupKing, PushupLegends = State.PushupLegends,
		EatEggs = State.EatEggs, EatBoosts = State.EatBoosts,
		AutoQuestFarm = State.AutoQuestFarm, AutoQuestCollect = State.AutoQuestCollect,
		AutoClanQuest = State.AutoClanQuest,
		TimeMode = State.TimeMode,
		Render3D = State.Render3D,
		HidePets = State.HidePets,
		HidePopups = State.HidePopups,
		HidePlayers = State.HidePlayers,
		HideSound = State.HideSound,
		Optimizer = State.Optimizer,
		WalkWater = State.WalkWater,
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
	for k, v in pairs(cfg) do
		if State[k] ~= nil then
			State[k] = v
		end
	end
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
	-- migrate old single rarity
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
	if type(cfg.KillSelectedBosses) == "table" then
		State.KillSelectedBosses = cfg.KillSelectedBosses
	end
	if type(cfg.PriorityRanks) == "table" then
		State.PriorityRanks = State.PriorityRanks or {}
		for k, v in pairs(cfg.PriorityRanks) do
			State.PriorityRanks[k] = v
		end
	end
	if type(cfg.Dropdowns) == "table" and type(cfg.Dropdowns.KillSelectedBosses) == "table" then
		State.KillSelectedBosses = cfg.Dropdowns.KillSelectedBosses
	end
	if type(cfg.Dropdowns) == "table" and type(cfg.Dropdowns.PriorityRanks) == "table" then
		State.PriorityRanks = State.PriorityRanks or {}
		for k, v in pairs(cfg.Dropdowns.PriorityRanks) do
			State.PriorityRanks[k] = v
		end
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

-- ==========================================
-- FARM PRIORITY (automatic, no master toggle)
-- Boss (if exists) > Brawl (if in brawl) > Rebirth
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

-- Priority: Boss > Auto Quest > Brawl > Rebirth (Chest independent)
local PrioSys = {}
function PrioSys.rank(key)
	local ranks = State.PriorityRanks
	if type(ranks) ~= "table" then return 100 end
	local r = ranks[key]
	if type(r) == "number" and r >= 1 and r <= 20 then return r end
	return 100
end
function PrioSys.featureWants(key)
	if key == "AutoKillBoss" then return State.AutoKillBoss == true and BossPresent == true end
	if key == "AutoQuest" then
		if not State.AutoQuestFarm then return false end
		return QuestBusy.Arcane or QuestBusy.Mystic or QuestBusy.Rune or QuestBusy.Spellbound or QuestBusy.CharmedBrawl
	end
	if key == "AutoBrawl" then return (State.AutoJoinBrawl or State.AutoKillBrawl or State.AutoResetBrawl) and PlayerInBrawl end
	if key == "FastStrength" then return State.FastStrength == true end
	if key == "FastRebirth" then return State.AutoFastRebirth == true end
	if key == "AutoRebirth" then return State.AutoRebirth == true end
	return false
end
function PrioSys.allowed(myKey)
	local my = PrioSys.rank(myKey)
	local keys = {"AutoKillBoss", "AutoQuest", "AutoBrawl", "FastStrength", "FastRebirth", "AutoRebirth"}
	for i = 1, #keys do
		local key = keys[i]
		if key ~= myKey and PrioSys.featureWants(key) and PrioSys.rank(key) < my then return false end
	end
	return true
end
function PrioSys.PrioSys.bossIsSelected(model)
	if not model then return false end
	local sel = State.KillSelectedBosses
	if type(sel) ~= "table" then return true end
	local any = false
	for _, on in pairs(sel) do if on then any = true break end end
	if not any then return true end
	local display = tostring(Workspace:GetAttribute("BossDisplayName") or model.Name)
	if sel[display] or sel[model.Name] then return true end
	for name, on in pairs(sel) do
		if on and (display == name or model.Name == name) then return true end
	end
	return false
end
local function canRunBoss()
	return State.AutoKillBoss == true and BossPresent == true and PrioSys.allowed("AutoKillBoss")
end
local function canRunFastStrength()
	return State.FastStrength == true and PrioSys.allowed("FastStrength")
end

-- Bloqueia farm so quando quest esta ativa de verdade.
-- Charmed Brawler NAO bloqueia (rebirth/farm continua).
-- Spellbound NAO bloqueia se Boss presente + Auto Kill Boss (cede ao boss).
-- Arcane so bloqueia se Boss existir.
local function questBlocking()
	if not State.AutoQuestFarm then return false end
	if QuestBusy.Arcane or QuestBusy.Mystic or QuestBusy.Rune then
		return true
	end
	if QuestBusy.Spellbound then
		-- se boss no mapa e Auto Boss ligado, nao bloqueia (boss tem prioridade)
		if State.AutoKillBoss and BossPresent then
			return false
		end
		return true
	end
	-- CharmedBrawl: never blocks
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
	return PrioSys.allowed("AutoRebirth")
end

local function canRunFastRebirth()
	if not State.AutoFastRebirth then return false end
	return PrioSys.allowed("FastRebirth")
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

-- Track boss presence
task.spawn(function()
	while true do
		BossPresent = bossExistsNow()
		task.wait(0.25)
	end
end)

-- Auto Boss Chest: independent, every 2s, prompt only (no TP)
task.spawn(function()
	while true do
		if State.AutoBossChest then
			hideBossPrompts()
			local chest, _, prompt = findBossChestPrompt()
			if prompt then
				firePrompt(prompt, 5)
			end
		end
		task.wait(2)
	end
end)

-- Jump once in brawl maps when machineInUse / interactSeat / sitting
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
		-- sempre que estiver nos mapas do brawl (PlayerInBrawl atualizado pelos loops de brawl)
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


-- Hide outros players + hitbox so enquanto farmando Boss
local BossFarmHideActive = false
local bossHiddenParts = {}
local bossHiddenGuis = {}
local bossHiddenCanCollide = {}

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
					-- hitbox / HRP
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
-- COMBAT HELPERS
-- ==========================================
local function inList(list, name)
	for _, n in ipairs(list) do if n:lower() == name:lower() then return true end end
	return false
end

local function addUnique(list, name)
	if not inList(list, name) then table.insert(list, name) end
end

local function toggleList(list, value)
	for i = #list, 1, -1 do
		if list[i] == value then table.remove(list, i) return false end
	end
	table.insert(list, value)
	return true
end

local function isWL(p) return inList(State.Whitelist, p.Name) end
local function isBL(p) return inList(State.Killlist, p.Name) end

local function matchKarma(p, evil, good)
	local g, e = p:FindFirstChild("goodKarma"), p:FindFirstChild("evilKarma")
	if not g or not e then return false end
	local gv, ev = g.Value or 0, e.Value or 0
	if gv + ev < 5 then return false end
	return (evil and gv > ev) or (good and ev > gv)
end

local function posNear(target, h)
	if not isAlive(target) or isProtected(target) or isProtected(LocalPlayer) then return false end
	local lr, tr = root(), target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not lr or not tr then return false end
	lr.CFrame = tr.CFrame * CFrame.new(0, h or 3.5, 0)
	lr.AssemblyLinearVelocity = Vector3.zero
	lr.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function touchPunch(target, h)
	if not posNear(target, h) then return false end
	RunService.Heartbeat:Wait()
	if not posNear(target, h) then return false end
	local c = char()
	local tr = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not c or not tr then return false end
	local hand = c:FindFirstChild("LeftHand") or c:FindFirstChild("RightHand")
	if not hand then return false end
	equipPunch()
	safeTouch(tr, hand, 0) safeTouch(tr, hand, 1)
	firePunch()
	return true
end

local function attackDur(target, dur, cont, h)
	local t0 = os.clock()
	while os.clock() - t0 < dur and (not cont or cont()) and isAlive(target) and not isProtected(target) do
		if posNear(target, h or 3.5) then
			local c = char()
			local tr = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			local L = c and c:FindFirstChild("LeftHand")
			local R = c and c:FindFirstChild("RightHand")
			equipPunch()
			if tr and L and R then
				safeTouch(tr, L, 0) safeTouch(tr, L, 1)
				safeTouch(tr, R, 0) safeTouch(tr, R, 1)
				firePunch()
			end
		end
		RunService.Heartbeat:Wait()
	end
end

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

-- Kill loops
-- Rebirth (priority aware)
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
			fireRep()
			task.wait(0.1)
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
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(0.1)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
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
					-- se toggle ativo e nao esta na maquina, tenta de novo ate conseguir
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
							-- fallback: qualquer maquina do tipo
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
									-- falhou: tenta de novo logo
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

-- Boss (priority)
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
			if model and hitbox and PrioSys.bossIsSelected(model) then
				-- nova aparicao do boss
				if BossPrepForModel ~= model then
					BossPrepForModel = model
					BossJumpDone = false
					BossFarmSecondsJumpDone = false
					if State.AutoFarmSeconds then
						-- Jump so se Auto Farm Seconds ativo e boss apareceu
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
					-- matando o boss: Jump uma vez
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

-- Brawl (priority)
local BrawlAreas = {
	{Pos = Vector3.new(4465, 177, -8851), Size = Vector3.new(552, 400, 548)},
	{Pos = Vector3.new(-1856.5, 175, -6315), Size = Vector3.new(499, 400, 496)},
	{Pos = Vector3.new(978, 177, -7433), Size = Vector3.new(502, 400, 504)},
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
			-- only clear if not being set by kill loop this tick; safe to clear when outside
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
					-- jump once handled by dedicated loop
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= LocalPlayer and isAlive(p) and inBrawl(p.Character.HumanoidRootPart.Position) then
							aggro[p] = true
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
					if alvo and alvo:FindFirstChild("HumanoidRootPart") then
						pcall(function() c:SetPrimaryPartCFrame(alvo.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)) end)
						equipPunch()
						local punch = c:FindFirstChild("Punch")
						if punch then pcall(function() punch:Activate() end) end
						for _ = 1, 4 do firePunch() end
					end
				else
					PlayerInBrawl = false
					aggro = {}
					ESPFolder:ClearAllChildren()
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
-- MISC: Render3D black overlay / Hides / Optimizer
-- ==========================================
local BlackOverlay
local Render3DConn

local function isOurUI(gui)
	if not gui or not gui:IsA("ScreenGui") then return false end
	local n = string.lower(gui.Name or "")
	if gui.Name == "SupremeHubBlackOverlay" then return true end
	if string.find(n, "supreme", 1, true) or string.find(n, "void", 1, true) then return true end
	-- Void UI ScreenGui often has no custom name; detect by content
	local ok, found = pcall(function()
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				local t = tostring(d.Text or "")
				if string.find(t, "Supreme Hub", 1, true) then return true end
			end
			if d.Name == "Drag" or d.Name == "WindowDragBar" or d.Name == "NotificationHolder" then
				return true
			end
		end
		return false
	end)
	return ok and found == true
end

local function getGuiParents()
	local list = {CoreGui}
	pcall(function()
		if gethui then table.insert(list, 1, gethui()) end
	end)
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg then table.insert(list, pg) end
	return list
end

local function ensureBlackOverlay()
	if BlackOverlay and BlackOverlay.Parent then return BlackOverlay end
	local parent = CoreGui
	pcall(function() if gethui then parent = gethui() end end)
	local sg = Instance.new("ScreenGui")
	sg.Name = "SupremeHubBlackOverlay"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	-- Below Void Hub (we force Void DisplayOrder higher)
	sg.DisplayOrder = 100
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = parent
	local f = Instance.new("Frame")
	f.Name = "Black"
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.ZIndex = 1
	f.Active = false
	f.Parent = sg
	BlackOverlay = sg
	return sg
end

local function promoteOurUI()
	for _, parent in ipairs(getGuiParents()) do
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") and isOurUI(gui) and gui.Name ~= "SupremeHubBlackOverlay" then
				pcall(function()
					gui.Enabled = true
					gui.DisplayOrder = 200000
					gui:SetAttribute("SH_OurUI", true)
				end)
			end
		end
	end
end

local function hideOtherGuis()
	local sg = BlackOverlay
	for _, parent in ipairs(getGuiParents()) do
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") and gui ~= sg then
				if isOurUI(gui) or gui:GetAttribute("SH_OurUI") then
					pcall(function()
						gui.Enabled = true
						gui.DisplayOrder = 200000
					end)
				else
					if gui.Enabled then
						gui:SetAttribute("SH_HiddenBy3D", true)
						gui.Enabled = false
					end
				end
			end
		end
	end
end

local function restoreOtherGuis()
	for _, parent in ipairs(getGuiParents()) do
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") and gui:GetAttribute("SH_HiddenBy3D") then
				gui.Enabled = true
				gui:SetAttribute("SH_HiddenBy3D", nil)
			end
		end
	end
end

local function setRender3D(on)
	-- desativado por enquanto (toggle sem funcao)
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

local function hideCharacterVisuals(character)
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if hiddenPlayerParts[part] == nil then
				hiddenPlayerParts[part] = part.LocalTransparencyModifier
				part.LocalTransparencyModifier = 1
			end
		elseif part:IsA("Decal") or part:IsA("Texture") then
			if hiddenPlayerParts[part] == nil then
				hiddenPlayerParts[part] = part.Transparency
				part.Transparency = 1
			end
		elseif part:IsA("BillboardGui") and (part.Name == "nameGui" or string.lower(part.Name):find("name")) then
			if hiddenNameGuis[part] == nil then
				hiddenNameGuis[part] = part.Enabled
				part.Enabled = false
			end
		end
	end
	-- Head.nameGui path
	local head = character:FindFirstChild("Head")
	if head then
		local ng = head:FindFirstChild("nameGui")
		if ng and ng:IsA("BillboardGui") and hiddenNameGuis[ng] == nil then
			hiddenNameGuis[ng] = ng.Enabled
			ng.Enabled = false
		end
	end
end

local function restoreCharacterVisuals()
	for part, old in pairs(hiddenPlayerParts) do
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
	table.clear(hiddenPlayerParts)
	for gui, old in pairs(hiddenNameGuis) do
		pcall(function()
			if gui and gui.Parent then
				gui.Enabled = old
			end
		end)
	end
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
	-- cleanup refs for left players
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
	-- also SoundService children not mine
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

-- Apply saved hides on load
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
-- SERVER: hop / auto load / auto rejoin
-- ==========================================
local function setupQueueOnTeleport()
	if not State.AutoLoad then return end
	if type(queue_on_teleport) ~= "function" then
		warn("[Supreme Hub] queue_on_teleport not available")
		return
	end
	-- always refresh queue
	local code = [=[
		repeat task.wait() until game:IsLoaded()
		local Players = game:GetService("Players")
		repeat task.wait() until Players.LocalPlayer
		task.wait(2)
		local function tryLoad(src)
			if type(src) == "string" and #src > 50 then
				local fn, err = loadstring(src)
				if fn then fn() return true end
				warn("[Supreme Hub] load error:", err)
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
		if not loaded then
			warn("[Supreme Hub] Auto Load: no script source found")
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

-- Auto Reconnect: network drop / freeze / error before Roblox message
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

-- GuiService error message (disconnect / kick UI)
pcall(function()
	local GuiService = game:GetService("GuiService")
	GuiService.ErrorMessageChanged:Connect(function(msg)
		if not State.AutoReconnect then return end
		if msg and tostring(msg) ~= "" then
			doReconnect("error")
		end
	end)
end)

-- Watch RobloxPromptGui for connection errors
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
			-- high / frozen ping
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
-- UI TABS (order: Main, Rebirth, Killing, ...)
-- ==========================================
local function playerOpts()
	local o = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(o, p.DisplayName .. " | " .. p.Name) end
	end
	if #o == 0 then table.insert(o, "No players") end
	return o
end

local function petList(isAura)
	local list = {}
	pcall(function()
		for _, item in ipairs(ReplicatedStorage.shared.runtime.cPetShopFolder:GetChildren()) do
			if (item:GetAttribute("IsPowerUp") == true) == isAura then table.insert(list, item.Name) end
		end
	end)
	table.sort(list)
	if #list == 0 then table.insert(list, "None") end
	return list
end

local function optsFrom(t)
	local o = {}
	for k in pairs(t) do table.insert(o, k) end
	table.sort(o)
	return o
end

local function rockOptionsSorted()
	local list = {}
	for name, dura in pairs(RockData) do
		table.insert(list, {name = name, dura = dura})
	end
	table.sort(list, function(a, b) return a.dura > b.dura end)
	local o = {}
	for _, item in ipairs(list) do table.insert(o, item.name) end
	return o
end

local function parsePlayer(v)
	local n = v:match("| (.+)$") or v
	return n:gsub("^%s*(.-)%s*$", "%1")
end

-- ==========================================
-- UI TABS
-- ==========================================



-- ==========================================
-- AUTO QUEST (Enchant Quests)
-- ==========================================
local QUEST_TOOL_FALLBACK = {"Pushups", "Weight", "Situps", "Handstands", "Punch"}
-- Nome real no jogo: Golden Phoenix (wiki / shop)
local QUEST_PHOENIX_NAMES = {
	"Golden Pheonix", "Golden Phoenix", "GoldenPhoenix",
	"Phoenix Gold", "Gold Phoenix", "Blue Phoenix", "Blue Pheonix",
}

local CharmedJoinCount = 0
local questToolEquipped = nil
local SpellboundLiftSeat = nil
local SpellboundReenterAt = 0
local MysticEvolveDone = 0

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

-- true when all requirements progress >= goal (or completed attribute)
local function isQuestComplete(questObj)
	if not questObj then return true end
	if questObj:GetAttribute("Completed") == true then return true end
	if questObj:GetAttribute("complete") == true then return true end
	local req = questObj:FindFirstChild("requirements")
	if not req then
		-- no requirements folder: treat missing as not complete if object still exists
		return false
	end
	local any = false
	for _, child in ipairs(req:GetChildren()) do
		any = true
		local progress = child:FindFirstChild("progress") or child:FindFirstChild("Progress")
		local goal = child:FindFirstChild("goal") or child:FindFirstChild("Goal")
			or child:FindFirstChild("required") or child:FindFirstChild("Required")
			or child:FindFirstChild("target") or child:FindFirstChild("Target")
			or child:FindFirstChild("max") or child:FindFirstChild("Max")
		local p = readNumber(progress)
		local g = readNumber(goal)
		if g == nil and child:GetAttribute("goal") then g = tonumber(child:GetAttribute("goal")) end
		if g == nil and child:GetAttribute("required") then g = tonumber(child:GetAttribute("required")) end
		if p ~= nil and g ~= nil then
			if p < g then return false end
		elseif p ~= nil and g == nil then
			-- known targets for specific req names
			local ln = string.lower(child.Name)
			if string.find(ln, "brawl", 1, true) and p < 10 then return false end
			if (string.find(ln, "rep", 1, true) or string.find(ln, "spellbound", 1, true)) and p < 5000 then return false end
			if string.find(ln, "evolve", 1, true) and p < 25 then return false end
			if string.find(ln, "boss", 1, true) and p < 1 then return false end
		else
			return false
		end
	end
	return any
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

local function toolFromRequirements(questObj)
	local req = questObj and questObj:FindFirstChild("requirements")
	if not req then return nil end
	local names = {}
	for _, child in ipairs(req:GetChildren()) do
		table.insert(names, child.Name)
		pcall(function()
			if child:IsA("StringValue") then table.insert(names, tostring(child.Value)) end
			if child:IsA("ObjectValue") and child.Value then table.insert(names, child.Value.Name) end
		end)
	end
	local bp = LocalPlayer:FindFirstChild("Backpack")
	local ch = char()
	for _, n in ipairs(names) do
		if bp and bp:FindFirstChild(n) then return n end
		if ch and ch:FindFirstChild(n) then return n end
	end
	return nil
end

local function equipToolByName(name)
	if not name then return false end
	local h, c = hum(), char()
	if not h or not c then return false end
	if c:FindFirstChild(name) then return true end
	local t = LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild(name)
	if t then
		pcall(function() h:EquipTool(t) end)
		return true
	end
	return false
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
	if not folder then
		pcall(function()
			folder = ReplicatedStorage.shared.runtime.cPetShopFolder
		end)
	end
	if not folder then return nil end
	for _, n in ipairs(nameCandidates) do
		local item = folder:FindFirstChild(n)
		if item then return item, n end
	end
	for _, item in ipairs(folder:GetChildren()) do
		local ln = string.lower(item.Name):gsub("%s+", "")
		if string.find(ln, "golden", 1, true) and string.find(ln, "phoenix", 1, true) then
			return item, item.Name
		end
		if string.find(ln, "golden", 1, true) and string.find(ln, "pheonix", 1, true) then
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

local function pickLiftMachine()
	if State.SelectedLift and LiftChoices[State.SelectedLift] then
		return LiftChoices[State.SelectedLift]
	end
	for _, m in pairs(LiftChoices) do
		return m
	end
	return nil
end

-- ---------- Rune Agility (independente) ----------
-- Se a missao existir: equipa Pushups e rep @ 10ms. Sem requirements.
task.spawn(function()
	while true do
		if not State.AutoQuestFarm then
			task.wait(0.4)
		else
			local q = hasQuest("Rune Agility")
			if q then -- existe = farm (some = para)
				QuestBusy.Rune = true
				local h = hum()
				local bp = LocalPlayer:FindFirstChild("Backpack")
				local ch = char()
				local tool = (ch and ch:FindFirstChild("Pushups"))
					or (bp and bp:FindFirstChild("Pushups"))
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
			-- limpa busy se nenhuma rune ativa
			if not hasQuest("Rune Agility") and not hasQuest("Rune Durability") then
				if QuestBusy.Rune then
					QuestBusy.Rune = false
					unequipTools()
				end
			end
		end
	end
end)

-- ---------- Rune Durability (independente) ----------
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
				local tool = (ch and ch:FindFirstChild("Pushups"))
					or (bp and bp:FindFirstChild("Pushups"))
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

-- ---------- Charmed Brawler: join brawl + Weight + rep (nao bloqueia rebirth) ----------
task.spawn(function()
	while true do
		if not State.AutoQuestFarm then
			QuestBusy.CharmedBrawl = false
			CharmedJoinCount = 0
			task.wait(0.5)
		else
			local q = hasQuest("Charmed Brawler")
			if q then
				QuestBusy.CharmedBrawl = true -- flag only; questBlocking ignores it
				-- tenta entrar no brawl periodicamente
				local r = root()
				local inZone = r and inBrawl(r.Position)
				if not inZone then
					joinBrawlOnce()
				else
					PlayerInBrawl = true
				end
				-- farm forca com Weight + rep (dentro ou fora do brawl)
				local h = hum()
				local bp = LocalPlayer:FindFirstChild("Backpack")
				local ch = char()
				local tool = (ch and ch:FindFirstChild("Weight"))
					or (bp and bp:FindFirstChild("Weight"))
				if tool and h and tool.Parent ~= ch then
					pcall(function() h:EquipTool(tool) end)
				end
				pcall(function()
					local ev = LocalPlayer:FindFirstChild("muscleEvent")
					if ev then ev:FireServer("rep") else fireRep() end
				end)
				task.wait(0.01)
			else
				-- missao sumiu: para farm da quest e volta ao normal
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

-- ---------- Spellbound Reps: ate 4 Lifts, seated, rep 10ms; Jump ao completar / cede ao Boss ----------
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

local function doQuestJump()
	pcall(function()
		local h = hum()
		if h then
			h.Jump = true
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
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
				-- se Boss presente e Auto Boss ligado: Jump e cede (nao seta busy bloqueante)
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
				-- missao sumiu / completa -> Jump
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

-- ---------- Arcane Slayer: boss if present, stop when complete ----------
task.spawn(function()
	while true do
		if not State.AutoQuestFarm then
			QuestBusy.Arcane = false
			task.wait(0.4)
		else
			local q = hasQuest("Arcane Slayer")
			-- Boss quest: so bloqueia farm se boss existir; sem boss continua farm normal
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
		-- attribute
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
						-- skip non-evolved while quest active
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

local function sellEvolvedGoldenPhoenix()
	return sellGoldenPhoenix(true)
end

-- ---------- Mystic Evolution: buy + evolve + sell (evolved while active; all when gone) ----------
local MysticWasActive = false
task.spawn(function()
	while true do
		if not State.AutoQuestFarm then
			if MysticWasActive then
				-- missao acabou / toggle off: vende evolved e nao evolved
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
				-- com missao ativa: vende so evolved
				sellGoldenPhoenix(true)
				MysticEvolveDone = MysticEvolveDone + 25
				task.wait(0.6)
			else
				if MysticWasActive then
					-- missao sumiu: vende evolved e nao evolved
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


-- ---------- Clan Quest: Claim slots 1-9 every 800ms ----------
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

-- ---------- Auto Collect ----------
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


-- 1 MAIN FEATURES
local Main = Window:Tab({ Title = "Main Features", Icon = "user" })
Main:Section({ Title = "Size", Icon = "maximize" })
Main:Slider({
	Title = "Size",
	Value = { Min = 1, Max = 100, Default = State.Size },
	Step = 1,
	Callback = function(v) State.Size = v markDirty() end
})
Main:Toggle({ Title = "Set Size", Default = State.SetSize, Callback = function(v) State.SetSize = v markDirty() end })
Main:Section({ Title = "Speed", Icon = "gauge" })
Main:Slider({
	Title = "Speed",
	Value = { Min = 16, Max = 500, Default = State.Speed },
	Step = 1,
	Callback = function(v) State.Speed = v markDirty() end
})
Main:Toggle({ Title = "Set Speed", Default = State.SetSpeed, Callback = function(v) State.SetSpeed = v markDirty() end })
Main:Section({ Title = "Fov", Icon = "eye" })
Main:Slider({
	Title = "Fov",
	Value = { Min = 1, Max = 250, Default = State.FOV },
	Step = 1,
	Callback = function(v) State.FOV = v markDirty() end
})
Main:Toggle({ Title = "Set Fov", Default = State.SetFOV, Callback = function(v)
	State.SetFOV = v
	if Camera then Camera.FieldOfView = v and State.FOV or 70 end
	markDirty()
end })
Main:Section({ Title = "Movement", Icon = "footprints" })
Main:Toggle({ Title = "Walk On Water", Default = State.WalkWater, Callback = function(v)
	State.WalkWater = v
	if _G.MLWater then
		for _, p in ipairs(_G.MLWater) do
			if p and p.Parent then p.CanCollide = v end
		end
	end
	markDirty()
end })
Main:Toggle({ Title = "Infinite Jump", Default = State.InfJump, Callback = function(v) State.InfJump = v markDirty() end })

-- 2 AUTO FARMING
local AutoFarm = Window:Tab({ Title = "Auto Farming", Icon = "dumbbell" })
AutoFarm:Section({ Title = "Status", Icon = "activity" })
local YELLOW_S = Color3.fromRGB(250, 204, 21)
local BLUE_D = Color3.fromRGB(59, 130, 246)
local FarmStats = AutoFarm:StatsFrame({
	Title = "Live Status",
	Desc = "Strength And Durability",
	Icon = "activity",
	Rows = {
		{
			Label = "Strength",
			Value = "0",
			Icon = "zap",
			LabelColor = Color3.fromRGB(180, 180, 190),
			ValueColor = YELLOW_S,
			IconColor = YELLOW_S,
		},
		{
			Label = "Durability",
			Value = "0",
			Icon = "shield",
			LabelColor = Color3.fromRGB(180, 180, 190),
			ValueColor = BLUE_D,
			IconColor = BLUE_D,
		},
	},
})
local function formatBoth(n)
	n = tonumber(n) or 0
	local raw = tostring(math.floor(n))
	local suf
	if n >= 1e15 then suf = string.format("%.2fQa", n/1e15)
	elseif n >= 1e12 then suf = string.format("%.2fT", n/1e12)
	elseif n >= 1e9 then suf = string.format("%.2fB", n/1e9)
	elseif n >= 1e6 then suf = string.format("%.2fM", n/1e6)
	elseif n >= 1e3 then suf = string.format("%.2fK", n/1e3)
	else suf = raw end
	return suf .. "  [" .. raw .. "]"
end
task.spawn(function()
	while true do
		pcall(function()
			local str = getStrength(LocalPlayer)
			local duraObj = LocalPlayer:FindFirstChild("Durability")
			local dura = 0
			if duraObj then
				if typeof(duraObj.Value) == "number" then dura = duraObj.Value
				else dura = ParseValue(duraObj.Value) end
			end
			if FarmStats and FarmStats.SetRow then
				FarmStats:SetRow(1, formatBoth(str), YELLOW_S)
				FarmStats:SetRow(2, formatBoth(dura), BLUE_D)
			end
		end)
		task.wait(0.25)
	end
end)

AutoFarm:Section({ Title = "Fast Strength", Icon = "zap" })
AutoFarm:Slider({
	Title = "Rep Controls",
	Value = { Min = 1, Max = 700, Default = State.RepControls or 100 },
	Step = 1,
	Callback = function(v)
		State.RepControls = math.clamp(math.floor(tonumber(v) or 100), 1, 700)
		-- not required in JSON per request; still keep runtime value
	end
})
AutoFarm:Toggle({ Title = "Fast Strength", Default = State.FastStrength, Callback = function(v)
	if v then
		showConfirmWarning("This option may cause lag.", function()
			State.FastStrength = true
			markDirty()
		end, function()
			State.FastStrength = false
		end)
	else
		State.FastStrength = false
		markDirty()
	end
end })

AutoFarm:Section({ Title = "Exercises", Icon = "dumbbell" })
AutoFarm:Dropdown({
	Title = "Select Exercise",
	Option = {"Weight", "Pushups", "Situps", "Handstands"},
	Default = State.Exercise or "Weight",
	Placeholder = State.Exercise or "Weight",
	Callback = function(v)
		State.Exercise = v
		markDirty()
	end
})
AutoFarm:Toggle({ Title = "Start Exercising", Default = State.AutoExercise, Callback = function(v)
	State.AutoExercise = v
	if v then
		machineState.Squat.Running = false
		machineState.Lift.Running = false
		State.AutoSquat = false
		State.AutoLift = false
	end
	markDirty()
end })
AutoFarm:Toggle({ Title = "Auto Rep", Default = State.AutoRep, Callback = function(v) State.AutoRep = v markDirty() end })
if #SquatNames > 0 then
	AutoFarm:Dropdown({
		Title = "Select Squat",
		Option = SquatNames,
		Default = State.SelectedSquat,
		Placeholder = State.SelectedSquat,
		Callback = function(v)
			State.SelectedSquat = v
			markDirty()
		end
	})
end
AutoFarm:Toggle({ Title = "Auto Squat", Default = State.AutoSquat, Callback = function(v)
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
end })
if #LiftNames > 0 then
	AutoFarm:Dropdown({
		Title = "Select Lift",
		Option = LiftNames,
		Default = State.SelectedLift,
		Placeholder = State.SelectedLift,
		Callback = function(v)
			State.SelectedLift = v
			markDirty()
		end
	})
end
AutoFarm:Toggle({ Title = "Auto Lift", Default = State.AutoLift, Callback = function(v)
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
end })
AutoFarm:Section({ Title = "Rocks", Icon = "mountain" })
AutoFarm:Dropdown({
	Title = "Select Rock",
	Option = rockOptionsSorted(),
	Default = State.SelectedRock,
	Placeholder = State.SelectedRock,
	Callback = function(v)
		State.SelectedRock = v
		markDirty()
	end
})
AutoFarm:Toggle({ Title = "Auto Rock", Default = State.AutoRock, Callback = function(v) State.AutoRock = v markDirty() end })
AutoFarm:Section({ Title = "Better Strength", Icon = "zap" })
AutoFarm:Toggle({ Title = "Pushup + Industrial Rock", Default = State.PushupIndustrial, Callback = function(v) State.PushupIndustrial = v markDirty() end })
AutoFarm:Toggle({ Title = "Pushup + Jungle Rock", Default = State.PushupJungle, Callback = function(v) State.PushupJungle = v markDirty() end })
AutoFarm:Toggle({ Title = "Pushup + Muscle King Rock", Default = State.PushupKing, Callback = function(v) State.PushupKing = v markDirty() end })
AutoFarm:Toggle({ Title = "Pushup + Legends Rock", Default = State.PushupLegends, Callback = function(v) State.PushupLegends = v markDirty() end })

-- 3 FARM REBIRTH
local Rebirth = Window:Tab({ Title = "Farm Rebirth", Icon = "refresh-cw" })
Rebirth:Section({ Title = "Fast Rebirth", Icon = "refresh-cw" })

local YELLOW = Color3.fromRGB(250, 204, 21)
local ORANGE = Color3.fromRGB(249, 115, 22)

local RebirthStats = Rebirth:StatsFrame({
	Title = "Status View",
	Desc = "Live Status",
	Icon = "activity",
	Rows = {
		{
			Label = "Strength",
			Value = "0",
			Icon = "zap",
			LabelColor = Color3.fromRGB(180, 180, 190),
			ValueColor = YELLOW,
			IconColor  = YELLOW,
		},
		{
			Label = "Rebirth",
			Value = "0",
			Icon = "refresh-cw",
			LabelColor = Color3.fromRGB(180, 180, 190),
			ValueColor = ORANGE,
			IconColor  = ORANGE,
		},
	},
})

local function formatStatNum(n)
	n = tonumber(n) or 0
	if n >= 1e15 then return string.format("%.2fQa", n/1e15) end
	if n >= 1e12 then return string.format("%.2fT", n/1e12) end
	if n >= 1e9 then return string.format("%.2fB", n/1e9) end
	if n >= 1e6 then return string.format("%.2fM", n/1e6) end
	if n >= 1e3 then return string.format("%.2fK", n/1e3) end
	return tostring(math.floor(n))
end

local function setRebirthRow(index, value, color)
	pcall(function()
		if RebirthStats and RebirthStats.SetRow then
			RebirthStats:SetRow(index, value, color)
		end
	end)
end

task.spawn(function()
	while true do
		pcall(function()
			local ls = LocalPlayer:FindFirstChild("leaderstats")
			local strVal = ls and ls:FindFirstChild("Strength")
			local rbVal = ls and ls:FindFirstChild("Rebirths")
			local strength = ParseValue(strVal and strVal.Value or 0)
			local rebirths = 0
			if rbVal then
				if typeof(rbVal.Value) == "number" then
					rebirths = rbVal.Value
				else
					rebirths = ParseValue(rbVal.Value)
				end
			end
			setRebirthRow(1, formatStatNum(strength), YELLOW)
			setRebirthRow(2, formatStatNum(rebirths), ORANGE)
		end)
		task.wait(0.25)
	end
end)

Rebirth:Toggle({ Title = "Auto Fast Rebirth", Default = State.AutoFastRebirth, Callback = function(v)
	if v then
		showConfirmWarning("This option may cause lag.", function()
			State.AutoFastRebirth = true
			markDirty()
		end, function()
			State.AutoFastRebirth = false
		end)
	else
		State.AutoFastRebirth = false
		markDirty()
	end
end })

Rebirth:Section({ Title = "Rebirth", Icon = "refresh-cw" })
Rebirth:Input({
	Title = "Rebirth Target",
	Placeholder = tostring(State.RebirthTarget or 0),
	Default = tostring(State.RebirthTarget or 0),
	Text = tostring(State.RebirthTarget or 0),
	Value = tostring(State.RebirthTarget or 0),
	Callback = function(v)
		local n = tonumber(v)
		if n and n >= 0 then State.RebirthTarget = n markDirty() end
	end
})
Rebirth:Toggle({ Title = "Auto Rebirth", Default = State.AutoRebirth, Callback = function(v) State.AutoRebirth = v markDirty() end })
Rebirth:Section({ Title = "Mores", Icon = "layers" })
Rebirth:Toggle({ Title = "Lock Position", Default = State.LockPos, Callback = function(v)
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
	markDirty()
end })
Rebirth:Toggle({ Title = "Auto Size 1", Default = State.AutoSize1, Callback = function(v) State.AutoSize1 = v markDirty() end })
Rebirth:Toggle({ Title = "Auto Muscle King", Default = State.AutoKing, Callback = function(v) State.AutoKing = v markDirty() end })

-- 4 FARM BRAWL
local Brawl = Window:Tab({ Title = "Farm Brawl", Icon = "shield" })
Brawl:Section({ Title = "Brawl", Icon = "shield" })
Brawl:Toggle({ Title = "Auto Join In Brawl", Default = State.AutoJoinBrawl, Callback = function(v)
	State.AutoJoinBrawl = v
	markDirty()
end })
Brawl:Toggle({ Title = "Auto Kill In Brawl", Default = State.AutoKillBrawl, Callback = function(v)
	State.AutoKillBrawl = v
	if not v then ESPFolder:ClearAllChildren() end
	markDirty()
end })
Brawl:Toggle({ Title = "Auto Reset Brawl", Default = State.AutoResetBrawl, Callback = function(v)
	State.AutoResetBrawl = v
	markDirty()
end })


local KillBossOptions = {"All"}
pcall(function()
	local shared = ReplicatedStorage:FindFirstChild("shared")
	local config = shared and shared:FindFirstChild("config")
	local bossCfg = config and config:FindFirstChild("BossEventConfig")
	if not bossCfg then return end
	local cfg = require(bossCfg)
	if cfg and cfg.RARITIES then
		for _, rarity in ipairs(cfg.RARITIES) do
			local display = rarity.DisplayName or rarity.Name or rarity.BossModel or "Unknown"
			table.insert(KillBossOptions, tostring(display))
		end
	end
end)

-- 5 FARM BOSS
local Boss = Window:Tab({ Title = "Farm Boss", Icon = "skull" })
Boss:Section({ Title = "Status", Icon = "activity" })

local BossStats = Boss:StatsFrame({
	Title = "Boss Status",
	Desc = "Live Status",
	Icon = "skull",
	Rows = {
		{
			Label = "Status",
			Value = "Waiting For Boss",
			Icon = "activity",
			LabelColor = Color3.fromRGB(180, 180, 190),
			ValueColor = Color3.fromRGB(255, 255, 255),
			IconColor  = Color3.fromRGB(255, 255, 255),
		},
		{
			Label = "Boss",
			Value = "None",
			Icon = "skull",
			LabelColor = Color3.fromRGB(180, 180, 190),
			ValueColor = Color3.fromRGB(255, 255, 255),
			IconColor  = Color3.fromRGB(255, 255, 255),
		},
		{
			Label = "Health",
			Value = "0 / 0",
			Icon = "heart",
			LabelColor = Color3.fromRGB(180, 180, 190),
			ValueColor = Color3.fromRGB(255, 255, 255),
			IconColor  = Color3.fromRGB(255, 255, 255),
		},
		{
			Label = "Next Boss",
			Value = "N/A",
			Icon = "clock",
			LabelColor = Color3.fromRGB(180, 180, 190),
			ValueColor = Color3.fromRGB(255, 255, 255),
			IconColor  = Color3.fromRGB(255, 255, 255),
		},
	},
})

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
	return string.format("%dh %dmin %ds", hours, minutes, secs)
end

local function setBossRow(index, value, color)
	pcall(function()
		if BossStats and BossStats.SetRow then
			BossStats:SetRow(index, value, color or Color3.fromRGB(255, 255, 255))
		end
	end)
end

local function updateBossStatusUI(model, hitbox)
	local WHITE = Color3.fromRGB(255, 255, 255)
	if not model then
		setBossRow(1, "Waiting For Boss", WHITE)
		setBossRow(2, "None", WHITE)
		setBossRow(3, "0 / 0", WHITE)
		-- igual original: BossSpawnNextTime - GetServerTimeNow()
		local nextTime = Workspace:GetAttribute("BossSpawnNextTime")
		if typeof(nextTime) == "number" then
			local left = nextTime - Workspace:GetServerTimeNow()
			setBossRow(4, formatBossCountdown(left), WHITE)
		else
			setBossRow(4, "N/A", WHITE)
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
	if State.AutoFarmSeconds and BossPrepActive then
		phase = "Tool Farm"
	elseif State.AutoKillBoss then
		phase = "Attacking"
	end
	setBossRow(1, phase, WHITE)
	setBossRow(2, tostring(display), WHITE)
	setBossRow(3, string.format("%s / %s", formatBossNum(hp), formatBossNum(mhp)), WHITE)
	setBossRow(4, "Current Boss Active", WHITE)
end

-- tempo real (igual original)
task.spawn(function()
	while true do
		pcall(function()
			local model, hitbox = findBoss()
			updateBossStatusUI(model, hitbox)
		end)
		task.wait(0.25)
	end
end)

Boss:Section({ Title = "Boss Farm", Icon = "swords" })
Boss:Slider({
	Title = "Farm Before Killing The Boss",
	Value = { Min = 5, Max = 100, Default = State.TimeFarm or 12 },
	Step = 1,
	Callback = function(v)
		State.TimeFarm = math.clamp(math.floor(tonumber(v) or 12), 5, 100)
		markDirty()
	end
})
Boss:Toggle({ Title = "Auto Farm Seconds", Default = State.AutoFarmSeconds, Callback = function(v)
	State.AutoFarmSeconds = v
	markDirty()
end })
Boss:Dropdown({
	Title = "Select Bosses",
	Option = _G.SH_BossRarityOptions or KillBossOptions or {"All"},
	Multi = true,
	MultiSelect = true,
	Default = (function()
		local t = {}
		if type(State.KillSelectedBosses) == "table" then
			for name, on in pairs(State.KillSelectedBosses) do
				if on then table.insert(t, name) end
			end
		end
		return t
	end)(),
	Callback = function(v)
		if type(v) == "table" then
			local map = {}
			for _, name in ipairs(v) do map[name] = true end
			for k, val in pairs(v) do
				if type(k) == "string" and val == true then map[k] = true end
				if type(val) == "string" then map[val] = true end
			end
			State.KillSelectedBosses = map
		elseif type(v) == "string" then
			State.KillSelectedBosses = State.KillSelectedBosses or {}
			if State.KillSelectedBosses[v] then State.KillSelectedBosses[v] = nil
			else State.KillSelectedBosses[v] = true end
		end
		markDirty()
	end
})
Boss:Toggle({ Title = "Auto Kill Boss", Default = State.AutoKillBoss, Callback = function(v)
	State.AutoKillBoss = v
	markDirty()
end })
Boss:Toggle({ Title = "Auto Boss Chest", Default = State.AutoBossChest, Callback = function(v)
	State.AutoBossChest = v
	if v then hideBossPrompts() end
	markDirty()
end })
Boss:Toggle({ Title = "Continue Farming After Boss Kill", Default = State.ContinueBoss, Callback = function(v)
	State.ContinueBoss = v
	markDirty()
end })

-- 6 AUTO QUEST
local Quest = Window:Tab({ Title = "Auto Quest", Icon = "scroll" })
Quest:Section({ Title = "Enchant Quests", Icon = "scroll" })
Quest:Toggle({ Title = "Auto Quest Farm", Default = State.AutoQuestFarm, Callback = function(v)
	State.AutoQuestFarm = v
	if not v then
		questToolEquipped = nil
		unequipTools()
	end
	markDirty()
end })
Quest:Toggle({ Title = "Auto Collect Quests", Default = State.AutoQuestCollect, Callback = function(v)
	State.AutoQuestCollect = v
	markDirty()
end })
Quest:Section({ Title = "Clan", Icon = "users" })
Quest:Toggle({ Title = "Collect Clan Quest", Default = State.AutoClanQuest, Callback = function(v)
	State.AutoClanQuest = v
	markDirty()
end })

-- 7 REWARDS
local Rewards = Window:Tab({ Title = "Rewards", Icon = "gift" })
Rewards:Section({ Title = "Rewards", Icon = "gift" })
Rewards:Toggle({ Title = "Spin Fortune Wheel", Default = State.SpinFortune, Callback = function(v)
	State.SpinFortune = v
	markDirty()
end })
Rewards:Section({ Title = "Consumables", Icon = "package" })
Rewards:Toggle({ Title = "Eat All Eggs", Default = State.EatEggs, Callback = function(v) State.EatEggs = v markDirty() end })
Rewards:Toggle({ Title = "Eat All Boosts", Default = State.EatBoosts, Callback = function(v) State.EatBoosts = v markDirty() end })

-- 8 TELEPORTS
local Teleport = Window:Tab({ Title = "Teleports", Icon = "map-pin" })
Teleport:Section({ Title = "Islands", Icon = "map" })
for _, name in ipairs({"Tiny Island", "Main Island", "Beach"}) do
	local cf = Teleports[name]
	Teleport:Button({ Title = name, Callback = function()
		local r = root()
		if r and cf then r.CFrame = cf end
	end })
end
Teleport:Section({ Title = "Gyms", Icon = "building" })
for _, name in ipairs({
	"Overcharged Gym", "Industrial Gym", "Jungle Gym", "Muscle King Gym",
	"Legends Gym", "Infernal Gym", "Mythical Gym", "Frost Gym"
}) do
	local cf = Teleports[name]
	Teleport:Button({ Title = name, Callback = function()
		local r = root()
		if r and cf then r.CFrame = cf end
	end })
end


-- WEBHOOK (Discord) nested function scope
(function()
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

	_G.SH_BossRarityOptions = BossRarityOptions
	_G.SH_BossRarityByDisplay = BossRarityByDisplay

	local function httpRequest(opts)
		local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
		if req then return req(opts) end
		local ok, res = pcall(function()
			return HttpService:RequestAsync({
				Url = opts.Url, Method = opts.Method or "POST", Headers = opts.Headers, Body = opts.Body,
			})
		end)
		if ok then return res end
		return nil
	end

	local function sendDiscordWebhook(content, embeds)
		local url = tostring(State.WebhookURL or "")
		if url == "" or not string.find(url, "discord.com/api/webhooks") then return false end
		local body = {
			username = "Supreme Hub",
			allowed_mentions = State.WebhookPingEveryone and { parse = {"everyone"} } or { parse = {} },
		}
		if State.WebhookPingEveryone then body.content = "@everyone"
		elseif content and content ~= "" then body.content = content end
		if embeds then body.embeds = embeds end
		local res = httpRequest({
			Url = url, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(body),
		})
		return res ~= nil
	end
	_G.SH_sendDiscordWebhook = sendDiscordWebhook

	local function listSelectedWebhookBosses()
		local t = {}
		if type(State.WebhookSelectedBosses) ~= "table" then return t end
		for name, on in pairs(State.WebhookSelectedBosses) do
			if on then table.insert(t, name) end
		end
		table.sort(t)
		return t
	end
	_G.SH_listSelectedWebhookBosses = listSelectedWebhookBosses

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
		game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
			if msg and tostring(msg) ~= "" then notifyDisconnectWebhook(msg) end
		end)
	end)
	Players.PlayerRemoving:Connect(function(p)
		if p == LocalPlayer then notifyDisconnectWebhook("left game") end
	end)
end)()


-- PRIORITY FARM TAB
local PriorityTab = Window:Tab({ Title = "Priority Farm", Icon = "list-ordered" })
PriorityTab:Section({ Title = "Farm Priority", Icon = "list-ordered" })
local PRIORITY_ITEMS = {
	{ Key = "AutoKillBoss", Title = "Auto Kill Boss" },
	{ Key = "AutoQuest", Title = "Auto Quest" },
	{ Key = "AutoBrawl", Title = "Auto Brawl" },
	{ Key = "FastStrength", Title = "Fast Strength" },
	{ Key = "FastRebirth", Title = "Fast Rebirth" },
	{ Key = "AutoRebirth", Title = "Auto Rebirth" },
}
local PriorityOptions = {"None"}
for i = 1, 20 do table.insert(PriorityOptions, tostring(i)) end
local function rankToOption(key)
	local r = State.PriorityRanks and State.PriorityRanks[key]
	if type(r) == "number" and r >= 1 and r <= 20 then return tostring(r) end
	return "None"
end
for _, item in ipairs(PRIORITY_ITEMS) do
	PriorityTab:Dropdown({
		Title = item.Title,
		Option = PriorityOptions,
		Default = rankToOption(item.Key),
		Placeholder = rankToOption(item.Key),
		Callback = function(v)
			State.PriorityRanks = State.PriorityRanks or {}
			if v == "None" then
				State.PriorityRanks[item.Key] = 100
			else
				State.PriorityRanks[item.Key] = tonumber(v) or 100
			end
			markDirty()
		end
	})
end
PriorityTab:Button({ Title = "Reset Priority", Callback = function()
	State.PriorityRanks = {
		AutoKillBoss = 100,
		AutoQuest = 100,
		AutoBrawl = 100,
		FastStrength = 100,
		FastRebirth = 100,
		AutoRebirth = 100,
	}
	markDirty()
end })


-- 9 SERVER
local Server = Window:Tab({ Title = "Server", Icon = "server" })
Server:Section({ Title = "Session", Icon = "server" })
Server:Toggle({ Title = "Auto Load Script", Default = State.AutoLoad, Callback = function(v)
	State.AutoLoad = v
	if v then
		setupQueueOnTeleport()
		notify("Supreme Hub", "Auto Load On Hop/Rejoin")
	end
	markDirty()
end })
Server:Toggle({ Title = "Auto Rejoin (1 Hour)", Default = State.AutoRejoin, Callback = function(v)
	State.AutoRejoin = v
	markDirty()
end })
Server:Toggle({ Title = "Auto Reconnect", Default = State.AutoReconnect, Callback = function(v)
	State.AutoReconnect = v
	markDirty()
end })
Server:Button({ Title = "Server Hop", Callback = function()
	serverHop()
end })

Server:Section({ Title = "Webhook", Icon = "bell" })
Server:Input({
	Title = "Webhook URL",
	Placeholder = (State.WebhookURL ~= "" and State.WebhookURL) or "https://discord.com/api/webhooks/...",
	Default = State.WebhookURL or "",
	Text = State.WebhookURL or "",
	Value = State.WebhookURL or "",
	Callback = function(v)
		State.WebhookURL = tostring(v or "")
		markDirty()
	end
})
Server:Toggle({ Title = "Ping @everyone", Default = State.WebhookPingEveryone, Callback = function(v)
	State.WebhookPingEveryone = v
	markDirty()
end })
Server:Dropdown({
	Title = "Boss Rarity",
	Option = _G.SH_BossRarityOptions or {"All"},
	Multi = true,
	MultiSelect = true,
	Default = (_G.SH_listSelectedWebhookBosses and _G.SH_listSelectedWebhookBosses()) or {},
	Callback = function(v)
		-- multi: table of selected OR single toggle click
		if type(v) == "table" then
			local map = {}
			for _, name in ipairs(v) do map[name] = true end
			-- also handle dict style
			for k, val in pairs(v) do
				if type(k) == "string" and val == true then map[k] = true end
				if type(val) == "string" then map[val] = true end
			end
			State.WebhookSelectedBosses = map
		elseif type(v) == "string" then
			State.WebhookSelectedBosses = State.WebhookSelectedBosses or {}
			if State.WebhookSelectedBosses[v] then
				State.WebhookSelectedBosses[v] = nil
			else
				State.WebhookSelectedBosses[v] = true
			end
		end
		markDirty()
	end
})
Server:Toggle({ Title = "Boss Notification", Default = State.WebhookBossNotify, Callback = function(v)
	State.WebhookBossNotify = v
	markDirty()
end })
Server:Toggle({ Title = "Disconnect Notification", Default = State.WebhookDisconnectNotify, Callback = function(v)
	State.WebhookDisconnectNotify = v
	markDirty()
end })
Server:Button({ Title = "Test Webhook", Callback = function()
	local ok = _G.SH_sendDiscordWebhook and _G.SH_sendDiscordWebhook(nil, {
		{
			title = "Test Notification",
			description = "Webhook is working correctly.",
			color = 5763719, -- green
			fields = {
				{ name = "Player", value = LocalPlayer.DisplayName .. " (`@" .. LocalPlayer.Name .. "`)", inline = true },
				{ name = "Place", value = tostring(game.PlaceId), inline = true },
			},
			footer = { text = "Supreme Hub • Muscle Legends" },
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}
	})
	notify("Supreme Hub", ok and "Webhook Sent" or "Webhook Failed")
end })

-- 10 MISC
local Misc = Window:Tab({ Title = "Misc", Icon = "settings" })
Misc:Section({ Title = "Time", Icon = "clock" })
Misc:Dropdown({
	Title = "Change Time",
	Option = {"Day", "Noon", "Afternoon", "Night", "Midnight"},
	Default = State.TimeMode or "Day",
	Callback = function(v)
		State.TimeMode = v
		local map = {Day = 9, Noon = 12, Afternoon = 16, Night = 0, Midnight = 2}
		Lighting.ClockTime = map[v] or 9
		markDirty()
	end
})
Misc:Button({ Title = "Reset Time", Callback = function()
	Lighting.ClockTime = NormalClockTime
	State.TimeMode = "Day"
	markDirty()
	notify("Supreme Hub", "Time Reset")
end })
Misc:Section({ Title = "Render", Icon = "monitor" })
Misc:Toggle({ Title = "Render 3D", Default = State.Render3D, Callback = function(v)
	setRender3D(v)
end })
Misc:Section({ Title = "Hides", Icon = "eye-off" })
Misc:Toggle({ Title = "Hide Players", Default = State.HidePlayers, Callback = function(v)
	State.HidePlayers = v
	applyHidePlayers()
	markDirty()
end })
Misc:Toggle({ Title = "Hide Popups", Default = State.HidePopups, Callback = function(v)
	State.HidePopups = v
	applyHidePopups()
	markDirty()
end })
Misc:Toggle({ Title = "Hide Sounds", Default = State.HideSound, Callback = function(v)
	State.HideSound = v
	applyHideSound()
	markDirty()
end })
Misc:Toggle({ Title = "Hide All Pets", Default = State.HidePets, Callback = function(v)
	State.HidePets = v
	applyHidePets()
	markDirty()
end })
Misc:Section({ Title = "Performance", Icon = "cpu" })
Misc:Toggle({ Title = "Optimizer", Default = State.Optimizer, Callback = function(v)
	State.Optimizer = v
	applyOptimizer()
	markDirty()
end })
Misc:Button({ Title = "Save Config", Callback = function()
	saveConfig()
	notify("Supreme Hub", "Config Saved")
end })
Misc:Button({ Title = "Destroy Ui", Callback = function()
	saveConfig()
	pcall(function() Window:Destroy() end)
end })

task.defer(function()
	pcall(function()
		if Window.Open then Window:Open() end
		if Window.SelectFirstTab then Window:SelectFirstTab() end
	end)
	applyHidePets()
	if State.Render3D then setRender3D(true) end
	if State.Optimizer then applyOptimizer() end
	if State.TimeMode then
		local map = {Day = 9, Noon = 12, Afternoon = 16, Night = 0, Midnight = 2}
		Lighting.ClockTime = map[State.TimeMode] or 9
	end
end)

-- resume saved farming machines
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



-- Fast Strength (nested scope)
task.spawn(function()
	while true do
		if canRunFastStrength() then
			local n = math.clamp(math.floor(tonumber(State.RepControls) or 100), 1, 700)
			for _ = 1, n do
				if not canRunFastStrength() then break end
				pcall(function()
					local ev = LocalPlayer:FindFirstChild("muscleEvent")
					if ev then
						ev:FireServer("rep")
					else
						fireRep()
					end
				end)
			end
			task.wait(1) -- n reps per second
		else
			task.wait(0.25)
		end
	end
end)

-- ==========================================
-- AUTO FAST REBIRTH (scoped to avoid Luau 200-local limit)
-- ==========================================
task.spawn(function()
	local STRENGTH_PET_PRIORITY = {
		"Inferno Drake",
		"Omega Overlord",
		"Swift Samurai",
		"Mythic Boss Pet",
		"Legendary Boss Pet",
		"Rainbow Boss Pet",
		"Epic Boss Pet",
	}

	local REBIRTH_PET_PRIORITY = {
		"Titanium Hydra",
		"Tribal Overlord",
	}

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
				if pet.Name == petName then
					table.insert(found, pet)
				end
			end
		end
		return found
	end

	local function collectOwnedPetsByPriority(priorityList)
		local owned = {}
		local seen = {}
		for _, name in ipairs(priorityList) do
			for _, pet in ipairs(findAllPetsNamed(name)) do
				if not seen[pet] then
					seen[pet] = true
					table.insert(owned, pet)
				end
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
				if typeof(val) == "Instance" then
					table.insert(names, val.Name)
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
		pcall(function()
			remote:FireServer("equipPet", pet)
		end)
	end

	local function unequipPetInstance(pet)
		local remote = getEquipPetRemote()
		if not remote or not pet then return end
		pcall(function()
			remote:FireServer("unequipPet", pet)
		end)
	end

	local function isNameInList(name, list)
		for _, n in ipairs(list) do
			if n == name then return true end
		end
		return false
	end

	local function unequipPetsNotInPriority(priorityList)
		local eq = LocalPlayer:FindFirstChild("equippedPets")
		if not eq then return end
		for i = 1, 12 do
			local slot = eq:FindFirstChild("pet" .. tostring(i))
			if slot then
				local val = slot.Value
				local name = nil
				local inst = nil
				if typeof(val) == "Instance" then
					name = val.Name
					inst = val
				elseif val ~= nil and val ~= false and tostring(val) ~= "" and tostring(val) ~= "nil" then
					name = tostring(val)
					local found = findAllPetsNamed(name)
					inst = found[1]
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
		local maxSlots = 12
		local toEquip = math.min(#owned, maxSlots)
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
			if isNameInList(name, priorityList) then
				n = n + 1
			end
		end
		return n
	end

	local function hasAllPriorityPetsEquipped(priorityList)
		local owned = collectOwnedPetsByPriority(priorityList)
		if #owned == 0 then return false end
		local need = math.min(#owned, 12)
		return countEquippedFromPriority(priorityList) >= need
	end

	local function getLeaderStrength()
		return getStrength(LocalPlayer)
	end

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
		local tool = nil
		if bp then tool = bp:FindFirstChild("Weight") end
		if not tool and ch then tool = ch:FindFirstChild("Weight") end
		if tool and h then
			pcall(function()
				h:EquipTool(tool)
			end)
			task.wait(0.08)
		end
		-- 300 reps per second
		for _ = 1, 300 do
			pcall(function()
				local ev = LocalPlayer:FindFirstChild("muscleEvent")
				if ev then
					ev:FireServer("rep")
				else
					fireRep()
				end
			end)
		end
		task.wait(1)
	end

	local function doRebirthRequest()
		pcall(function()
			local remote = ReplicatedStorage.rEvents:FindFirstChild("rebirthRemote")
			if remote then
				remote:InvokeServer("rebirthRequest")
			end
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
				local req = getRebirthRequirement()
				local str = getLeaderStrength()
				local safety = 0
				while canRunFastRebirth() and safety < 600 do
					req = getRebirthRequirement()
					str = getLeaderStrength()
					if req > 0 and str >= req then
						break
					end
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
				if after <= before then
					task.wait(0.55)
				else
					task.wait(0.2)
				end
			else
				task.wait(0.25)
			end
		end
	end
end)


notify("Supreme Hub", "Loaded")
print("[Supreme Hub] Loaded")

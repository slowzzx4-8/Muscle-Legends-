--[[
    Supreme Hub | Muscle Legends
    Farm Brawl + Farm Kill
    Priority: Brawl > Farm Kill
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CONFIG_PATH = "SupremeHub/MuscleLegends_BrawlKill.json"

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = tostring(title),
			Text = tostring(text),
			Duration = 4
		})
	end)
end

-- ==========================================
-- ANTI AFK / ANTI KICK
-- ==========================================
LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

pcall(function()
	local vu = game:GetService("VirtualUser")
	LocalPlayer.Idled:Connect(function()
		vu:CaptureController()
		vu:ClickButton2(Vector2.new())
	end)
end)

-- Anti kick soft (block common kick remotes if present)
pcall(function()
	local mt = getrawmetatable and getrawmetatable(game)
	if not mt then return end
	local oldNamecall = mt.__namecall
	if setreadonly then setreadonly(mt, false) end
	mt.__namecall = newcclosure and newcclosure(function(self, ...)
		local method = getnamecallmethod and getnamecallmethod()
		if method == "Kick" or method == "kick" then
			return
		end
		return oldNamecall(self, ...)
	end) or function(self, ...)
		local method = getnamecallmethod and getnamecallmethod()
		if method == "Kick" or method == "kick" then
			return
		end
		return oldNamecall(self, ...)
	end
	if setreadonly then setreadonly(mt, true) end
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
	if t and t.Parent ~= c then
		pcall(function() h:EquipTool(t) end)
	end
end

local function isAlive(p)
	return p and p.Character
		and p.Character:FindFirstChild("HumanoidRootPart")
		and p.Character:FindFirstChild("Humanoid")
		and p.Character.Humanoid.Health > 0
end

local function isProtected(p)
	if not p or not p.Character then return false end
	if p.Character:FindFirstChildOfClass("ForceField")
		or p.Character:FindFirstChild("spawnProtectionHighlight") then
		return true
	end
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
	if suffix and Suffixes[suffix] then
		num = num * (10 ^ Suffixes[suffix])
	end
	return num
end

local function getStrength(p)
	local s = p:FindFirstChild("leaderstats")
	return ParseValue(s and s:FindFirstChild("Strength") and s.Strength.Value or 0)
end

-- ==========================================
-- STATE + CONFIG
-- ==========================================
local State = {
	-- Brawl
	AutoJoinBrawl = false,
	AutoKillBrawl = false,
	AutoResetBrawl = false,

	-- Kill
	AutoKill = false,
	AuraKill = false,
	AuraRange = 50,
	WhitelistFriends = false,
	Whitelist = {}, -- { [playerName] = true }

	-- Misc
	AntiAfk = true,
	AntiKick = true,
}

local function ensureFolder()
	if type(makefolder) == "function" then
		pcall(makefolder, "SupremeHub")
	end
end

local function serializeState()
	return {
		AutoJoinBrawl = State.AutoJoinBrawl,
		AutoKillBrawl = State.AutoKillBrawl,
		AutoResetBrawl = State.AutoResetBrawl,
		AutoKill = State.AutoKill,
		AuraKill = State.AuraKill,
		AuraRange = State.AuraRange,
		WhitelistFriends = State.WhitelistFriends,
		Whitelist = State.Whitelist,
		AntiAfk = State.AntiAfk,
		AntiKick = State.AntiKick,
	}
end

local function applyConfig(cfg)
	if type(cfg) ~= "table" then return end
	for k, v in pairs(cfg) do
		if State[k] ~= nil then
			State[k] = v
		end
	end
	if type(cfg.Whitelist) == "table" then
		State.Whitelist = cfg.Whitelist
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
-- PRIORITY: Brawl > Farm Kill
-- ==========================================
local PlayerInBrawl = false

local function brawlFeatureOn()
	return State.AutoJoinBrawl or State.AutoKillBrawl or State.AutoResetBrawl
end

local function canRunJoinBrawl()
	return State.AutoJoinBrawl == true
end

local function canRunKillBrawl()
	return State.AutoKillBrawl == true
end

local function canRunResetBrawl()
	return State.AutoResetBrawl == true
end

-- Farm Kill only runs when NOT actively in brawl with brawl features on
local function canRunFarmKill()
	if brawlFeatureOn() and PlayerInBrawl then
		return false
	end
	return true
end

-- ==========================================
-- WHITELIST HELPERS
-- ==========================================
local function isWhitelisted(player)
	if not player then return false end
	if State.Whitelist[player.Name] then return true end
	if State.WhitelistFriends then
		local ok, friends = pcall(function()
			return player:IsFriendsWith(LocalPlayer.UserId)
		end)
		if ok and friends then return true end
	end
	return false
end

local function getPlayerList()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(list, p.DisplayName .. " | " .. p.Name)
		end
	end
	table.sort(list)
	return list
end

local function nameFromDropdown(text)
	if not text then return nil end
	return text:match(" | (.+)$") or text
end

-- ==========================================
-- BRAWL SYSTEM
-- ==========================================
local BrawlAreas = {
	{Pos = Vector3.new(4465, 177, -8851), Size = Vector3.new(552, 400, 548)},
	{Pos = Vector3.new(-1856.5, 175, -6315), Size = Vector3.new(499, 400, 496)},
	{Pos = Vector3.new(978, 177, -7433), Size = Vector3.new(502, 400, 504)},
}

local function inBrawl(pos)
	for _, a in ipairs(BrawlAreas) do
		local o = pos - a.Pos
		local h = a.Size / 2
		if math.abs(o.X) <= h.X and math.abs(o.Y) <= h.Y and math.abs(o.Z) <= h.Z then
			return true
		end
	end
	return false
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "MLBrawlESP"
pcall(function()
	if gethui then
		ESPFolder.Parent = gethui()
	else
		ESPFolder.Parent = CoreGui
	end
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
	if hl then
		hl.Adornee = p.Character
		hl.FillColor = weak and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
	end
	local bg = e:FindFirstChild("NameTag")
	if bg then
		bg.Adornee = p.Character and p.Character:FindFirstChild("Head")
		local t = bg:FindFirstChildOfClass("TextLabel")
		if t then t.Text = p.Name end
	end
end

-- Track brawl presence
task.spawn(function()
	while true do
		local r = root()
		if r and inBrawl(r.Position) then
			PlayerInBrawl = true
		else
			PlayerInBrawl = false
		end
		task.wait(0.25)
	end
end)

-- Auto Join Brawl
task.spawn(function()
	while true do
		if canRunJoinBrawl() then
			pcall(function()
				ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl")
			end)
			task.wait(2)
		else
			task.wait(0.5)
		end
	end
end)

-- Auto Kill In Brawl
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
							if not isWhitelisted(p) then
								aggro[p] = true
							end
						end
					end
					local weakT, strongT = nil, nil
					local dW, dS = math.huge, math.huge
					local cur = {}
					for p, _ in pairs(aggro) do
						if p.Parent and isAlive(p) and not isWhitelisted(p) then
							local tm = p:FindFirstChild("currentMap") and p.currentMap.Value
							if tm == myMap then
								local weak = getStrength(p) < myStr
								updESP(p, weak)
								cur[p.Name] = true
								local d = (myPos - p.Character.HumanoidRootPart.Position).Magnitude
								if weak then
									if d < dW then dW = d; weakT = p.Character end
								else
									if d < dS then dS = d; strongT = p.Character end
								end
							else
								aggro[p] = nil
							end
						else
							aggro[p] = nil
						end
					end
					for _, e in ipairs(ESPFolder:GetChildren()) do
						if not cur[e.Name] then e:Destroy() end
					end
					local alvo = weakT or strongT
					if alvo and alvo:FindFirstChild("HumanoidRootPart") then
						pcall(function()
							c:SetPrimaryPartCFrame(alvo.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
						end)
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

-- Auto Reset Brawl
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
						if h and h.Health > 0 then
							h.Health = 0
							task.wait(5)
						end
					end
				end
			end)
			task.wait(0.5)
		else
			task.wait(0.5)
		end
	end
end)

-- ==========================================
-- FARM KILL SYSTEM
-- ==========================================
local function positionNearTarget(target, heightOffset)
	if not isAlive(target) or isProtected(target) or isProtected(LocalPlayer) then
		return false
	end
	local localRoot = root()
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not localRoot or not targetRoot then return false end
	localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, heightOffset or 3.5, 0)
	localRoot.AssemblyLinearVelocity = Vector3.zero
	localRoot.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function attackTarget(target, heightOffset)
	if not positionNearTarget(target, heightOffset) then return false end
	RunService.Heartbeat:Wait()
	if not positionNearTarget(target, heightOffset) then return false end

	local c = char()
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	local targetHum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if not c or not targetRoot or not targetHum or isProtected(target) then return false end

	local leftHand = c:FindFirstChild("LeftHand")
	local rightHand = c:FindFirstChild("RightHand")
	equipPunch()

	pcall(function()
		if firetouchinterest and leftHand then
			firetouchinterest(targetRoot, leftHand, 0)
			firetouchinterest(targetRoot, leftHand, 1)
		end
		if firetouchinterest and rightHand then
			firetouchinterest(targetRoot, rightHand, 0)
			firetouchinterest(targetRoot, rightHand, 1)
		end
		firePunch()
	end)
	return true
end

local function attackPlayerForDuration(target, duration, shouldContinue, heightOffset)
	local started = tick()
	while (tick() - started) < duration
		and (not shouldContinue or shouldContinue())
		and isAlive(target)
		and not isProtected(target) do
		attackTarget(target, heightOffset or 3.5)
		RunService.Heartbeat:Wait()
	end
end

-- Auto Kill (chase all non-whitelisted)
local AutoKillGeneration = 0
task.spawn(function()
	while true do
		if State.AutoKill and canRunFarmKill() then
			local gen = AutoKillGeneration
			local found = false
			for _, player in ipairs(Players:GetPlayers()) do
				if not State.AutoKill or AutoKillGeneration ~= gen then break end
				if not canRunFarmKill() then break end
				if player ~= LocalPlayer
					and not isWhitelisted(player)
					and isAlive(player)
					and not isProtected(player) then
					found = true
					attackPlayerForDuration(player, 4, function()
						return State.AutoKill
							and AutoKillGeneration == gen
							and not isWhitelisted(player)
							and canRunFarmKill()
					end, 3.5)
				end
			end
			if found then
				RunService.Heartbeat:Wait()
			else
				task.wait(0.1)
			end
		else
			task.wait(0.25)
		end
	end
end)

-- Aura Kill (range based, default 50)
task.spawn(function()
	while true do
		if State.AuraKill and canRunFarmKill() then
			local r = root()
			local c = char()
			if r and c and isAlive(LocalPlayer) and not isProtected(LocalPlayer) then
				local range = tonumber(State.AuraRange) or 50
				equipPunch()
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer
						and not isWhitelisted(player)
						and isAlive(player)
						and not isProtected(player) then
						local tr = player.Character.HumanoidRootPart
						local dist = (r.Position - tr.Position).Magnitude
						if dist <= range then
							pcall(function()
								local leftHand = c:FindFirstChild("LeftHand")
								local rightHand = c:FindFirstChild("RightHand")
								if firetouchinterest and leftHand then
									firetouchinterest(tr, leftHand, 0)
									firetouchinterest(tr, leftHand, 1)
								end
								if firetouchinterest and rightHand then
									firetouchinterest(tr, rightHand, 0)
									firetouchinterest(tr, rightHand, 1)
								end
								firePunch()
							end)
						end
					end
				end
			end
			task.wait(0.05)
		else
			task.wait(0.2)
		end
	end
end)

-- ==========================================
-- UI TABS
-- Order: Farm Brawl (priority) → Farm Kill → Misc
-- ==========================================

-- 1 FARM BRAWL
local Brawl = Window:Tab({ Title = "Farm Brawl", Icon = "shield" })
Brawl:Section({ Title = "Brawl", Icon = "shield" })
Brawl:Toggle({
	Title = "Auto Join In Brawl",
	Default = State.AutoJoinBrawl,
	Callback = function(v)
		State.AutoJoinBrawl = v
		markDirty()
	end
})
Brawl:Toggle({
	Title = "Auto Kill In Brawl",
	Default = State.AutoKillBrawl,
	Callback = function(v)
		State.AutoKillBrawl = v
		if not v then ESPFolder:ClearAllChildren() end
		markDirty()
	end
})
Brawl:Toggle({
	Title = "Auto Reset Brawl",
	Default = State.AutoResetBrawl,
	Callback = function(v)
		State.AutoResetBrawl = v
		markDirty()
	end
})
Brawl:Section({ Title = "Info", Icon = "info" })
Brawl:Button({
	Title = "Priority: Brawl > Farm Kill",
	Callback = function()
		notify("Supreme Hub", "While in Brawl with features ON, Farm Kill pauses")
	end
})

-- 2 FARM KILL
local Kill = Window:Tab({ Title = "Farm Kill", Icon = "swords" })

Kill:Section({ Title = "Combat", Icon = "swords" })
Kill:Toggle({
	Title = "Aura Kill (Range 50)",
	Default = State.AuraKill,
	Callback = function(v)
		State.AuraKill = v
		markDirty()
		notify("Supreme Hub", v and ("Aura Kill ON · Range " .. tostring(State.AuraRange)) or "Aura Kill OFF")
	end
})
Kill:Toggle({
	Title = "Auto Kill",
	Default = State.AutoKill,
	Callback = function(v)
		State.AutoKill = v
		AutoKillGeneration = AutoKillGeneration + 1
		markDirty()
		notify("Supreme Hub", v and "Auto Kill ON" or "Auto Kill OFF")
	end
})

Kill:Section({ Title = "Range", Icon = "circle" })
Kill:Input({
	Title = "Aura Range",
	Placeholder = tostring(State.AuraRange or 50),
	Default = tostring(State.AuraRange or 50),
	Callback = function(v)
		local n = tonumber(v)
		if n and n > 0 then
			State.AuraRange = math.clamp(math.floor(n), 1, 200)
			markDirty()
			notify("Supreme Hub", "Aura Range: " .. State.AuraRange)
		end
	end
})

Kill:Section({ Title = "Whitelist", Icon = "users" })
Kill:Toggle({
	Title = "Whitelist Friends",
	Default = State.WhitelistFriends,
	Callback = function(v)
		State.WhitelistFriends = v
		markDirty()
	end
})

local function whitelistOptions()
	return getPlayerList()
end

Kill:Dropdown({
	Title = "Select Players (Ignore)",
	Option = whitelistOptions(),
	Multi = true,
	MultiSelect = true,
	Default = (function()
		local t = {}
		for name, on in pairs(State.Whitelist) do
			if on then
				-- try match current players
				for _, p in ipairs(Players:GetPlayers()) do
					if p.Name == name then
						table.insert(t, p.DisplayName .. " | " .. p.Name)
					end
				end
			end
		end
		return t
	end)(),
	Callback = function(v)
		if type(v) == "table" then
			local map = {}
			for _, entry in ipairs(v) do
				local name = nameFromDropdown(entry)
				if name then map[name] = true end
			end
			for k, val in pairs(v) do
				if type(k) == "string" and val == true then
					map[nameFromDropdown(k) or k] = true
				elseif type(val) == "string" then
					local name = nameFromDropdown(val)
					if name then map[name] = true end
				end
			end
			State.Whitelist = map
		elseif type(v) == "string" then
			local name = nameFromDropdown(v)
			if name then
				State.Whitelist = State.Whitelist or {}
				if State.Whitelist[name] then
					State.Whitelist[name] = nil
				else
					State.Whitelist[name] = true
				end
			end
		end
		markDirty()
	end
})

Kill:Button({
	Title = "Clear Whitelist",
	Callback = function()
		State.Whitelist = {}
		markDirty()
		notify("Supreme Hub", "Whitelist cleared")
	end
})

Kill:Section({ Title = "Protection", Icon = "shield" })
Kill:Toggle({
	Title = "Anti AFK",
	Default = State.AntiAfk,
	Callback = function(v)
		State.AntiAfk = v
		markDirty()
	end
})
Kill:Toggle({
	Title = "Anti Kick",
	Default = State.AntiKick,
	Callback = function(v)
		State.AntiKick = v
		markDirty()
	end
})

-- Keep Anti AFK active when toggle is on (Idled already connected; this reinforces)
task.spawn(function()
	while true do
		if State.AntiAfk then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end
		task.wait(60)
	end
end)

-- 3 MISC
local Misc = Window:Tab({ Title = "Misc", Icon = "settings" })
Misc:Section({ Title = "Config", Icon = "save" })
Misc:Button({
	Title = "Save Config",
	Callback = function()
		saveConfig()
		notify("Supreme Hub", "Config Saved")
	end
})
Misc:Button({
	Title = "Destroy UI",
	Callback = function()
		saveConfig()
		pcall(function() Window:Destroy() end)
	end
})
Misc:Section({ Title = "Info", Icon = "info" })
Misc:Button({
	Title = "Priority: Brawl → Farm Kill",
	Callback = function()
		notify("Supreme Hub", "Brawl has priority over Farm Kill")
	end
})

task.defer(function()
	pcall(function()
		if Window.Open then Window:Open() end
		if Window.SelectFirstTab then Window:SelectFirstTab() end
	end)
end)

notify("Supreme Hub", "Loaded · Brawl + Kill")
print("[Supreme Hub] Muscle Legends Brawl/Kill Loaded")

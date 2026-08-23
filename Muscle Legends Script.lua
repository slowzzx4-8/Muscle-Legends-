--[[
    Muscle Legends Script
    By Slowzzx4 (Ultimate Complete Edition)
    - Save System Configurado
    - Server Hop (1m 30s)
    - Fix Brawl Auto Kill & Spawn Protection
    - Fast Farm Restaurado
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========== Save System ==========
local SaveFileName = "MuscleLegends_Slowzzx4_Save.json"
local SaveData = {}

if isfile and isfile(SaveFileName) then
    local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(SaveFileName)) end)
    if success and type(decoded) == "table" then
        SaveData = decoded
    end
end

local function GetSave(key, default)
    if SaveData[key] == nil then return default end
    return SaveData[key]
end

local function SetSave(key, value)
    SaveData[key] = value
    if writefile then
        pcall(function() writefile(SaveFileName, HttpService:JSONEncode(SaveData)) end)
    end
end

-- ========== Anti AFK ==========
do
    local antiAfk = getgenv and getgenv() or _G
    antiAfk.Young0xPersistentAntiAfk = antiAfk.Young0xPersistentAntiAfk or {}
    if not antiAfk.Young0xPersistentAntiAfk.connection or not antiAfk.Young0xPersistentAntiAfk.connection.Connected then
        antiAfk.Young0xPersistentAntiAfk.connection = LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                local cam = workspace.CurrentCamera
                local cf = cam and cam.CFrame or CFrame.new()
                VirtualUser:Button2Down(Vector2.new(0, 0), cf)
                task.wait(0.05)
                VirtualUser:Button2Up(Vector2.new(0, 0), cf)
            end)
        end)
    end
end

-- ========== Config ==========
local Config = {
    Rocks = {
        { name = "Ancient Rock", durability = 10000000 },
        { name = "Muscle King Rock", durability = 5000000 },
        { name = "Legend Rock", durability = 1000000 },
        { name = "Eternal Rock", durability = 750000 },
        { name = "Mythical Rock", durability = 400000 },
        { name = "Frost Rock", durability = 150000 },
        { name = "Beach Rock", durability = 5000 },
        { name = "Starter Rock", durability = 100 },
        { name = "Tiny Rock", durability = 0 },
    },
    Teleports = {
        { "Jungle Gym", Vector3.new(-7894, 6, 2386) },
        { "Muscle King", Vector3.new(-8799, 17, -5798) },
        { "Legends Gym", Vector3.new(4429, 991, -3880) },
        { "Eternal Gym", Vector3.new(-6768, 7, -1287) },
        { "Mythical Gym", Vector3.new(2255, 7, 1071) },
        { "Frost Gym", Vector3.new(-2650, 7, -393) },
        { "Tiny Gym", Vector3.new(50, 7, 1918) },
        { "Beach", Vector3.new(9, 7, 100) },
        { "Secret Area", Vector3.new(1947, 2, 6191) },
        { "Desert Brawl", Vector3.new(960, 17, -7398) },
        { "Lava Brawl", Vector3.new(4471, 119, -8836) },
    },
    AutoEgg = { Interval = 1800, Names = { "ProteinEgg", "Protein Egg" } },
    ServerHop = {
        Interval = 90, -- 1 Minuto e 30 Segundos
        ServerApi = "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100",
        MinimumPlayers = 16,
        RetryDelay = 5,
    },
}

local PROTEIN_ITEMS = {
    { tool = "TOUGH Bar", event = "toughBar" },
    { tool = "ULTRA Shake", event = "ultraShake" },
    { tool = "Energy Shake", event = "energyShake" },
    { tool = "Protein Shake", event = "proteinShake" },
    { tool = "Energy Bar", event = "energyBar" },
    { tool = "Protein Bar", event = "proteinBar" },
}

-- ========== State ==========
local State = {
    running = true,
    fastPunch = false,
    selectedRock = nil,
    rockGeneration = 0,
    rockSessionStartedAt = nil,
    autoWeight = false, autoHandstands = false, autoLift = false, autoSitups = false,
    hideFrames = false, hideDurability = false,
    fastFarmMode = nil, machine = nil, autoPet = false, autoAura = false,
    walkWater = false, autoSpinWheel = false,
    mainAutoSize = false, mainAutoSpeed = false, mainSize = 2, mainSpeed = 125,
    infiniteJump = false, removePortals = false, fastSpeed = false, antiKnockback = false, spin = false, spy = false, spyTarget = nil,
    kill = { auto = false, karmaMode = nil, protectFriends = false, targetMode = false, target = nil, serverHop = false, friendCache = {} },
    tradeExt = { sendToPlayer = nil, acceptFromPlayer = nil, selectedPet = nil, selectedAura = nil, amount = 1 },
    rebirth = { objective = 0, autoRebirth = false, infinite = false, sizeOne = false, fastWeight = false, king = false, lockPosition = false, lockCFrame = nil },
    exerciseMovement = { active = {}, humanoid = nil, walkSpeed = nil, jumpValue = nil, usesJumpPower = true },
}

local taskHandles, connections = {}, {}
local function cancelTask(name) if taskHandles[name] then pcall(task.cancel, taskHandles[name]) taskHandles[name] = nil end end
local function spawnTask(name, fn) cancelTask(name) taskHandles[name] = task.spawn(function() pcall(fn) taskHandles[name] = nil end) return taskHandles[name] end
local function cleanupAll() for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end table.clear(connections) for k in pairs(taskHandles) do cancelTask(k) end end
local function track(conn) connections[#connections + 1] = conn return conn end

-- ========== Helpers ==========
local function getCharacter() return LocalPlayer.Character end
local function getHumanoid() local char = getCharacter() return char and char:FindFirstChildWhichIsA("Humanoid") end
local function getHRP() local char = getCharacter() return char and char:FindFirstChild("HumanoidRootPart") end

local function formatNumber(n)
    n = tonumber(n) or 0
    local neg = n < 0
    local v = math.abs(n)
    local units = { { 1e63, "VG" }, { 1e60, "ND" }, { 1e57, "OD" }, { 1e54, "SP" }, { 1e51, "SX" }, { 1e48, "QI" }, { 1e45, "QA" }, { 1e42, "T" }, { 1e39, "D" }, { 1e36, "U" }, { 1e33, "DC" }, { 1e30, "N" }, { 1e27, "O" }, { 1e24, "S" }, { 1e21, "S" }, { 1e18, "QI" }, { 1e15, "QA" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
    for _, entry in ipairs(units) do
        if v >= entry[1] then
            local num = v / entry[1]
            local text = string.format(num >= 100 and "%.0f" or (num >= 10 and "%.1f" or "%.2f"), num):gsub("%.0$", ""):gsub("(%..-)0+$", "%1"):gsub("%.$", "")
            return (neg and "-" or "") .. text .. entry[2]
        end
    end
    return (neg and "-" or "") .. string.format("%.0f", v)
end

local function getPing()
    local ok, result = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    return ok and math.floor((tonumber(result) or 0) + 0.5) or 0
end

local function equipTool(names)
    local char, hum = getCharacter(), getHumanoid()
    if not char or not hum then return nil end
    local lower = {}
    for _, n in ipairs(names) do lower[n:lower()] = true end
    for _, parent in ipairs({ char, LocalPlayer:FindFirstChild("Backpack") }) do
        if parent then
            for _, item in ipairs(parent:GetChildren()) do
                if item:IsA("Tool") and lower[item.Name:lower()] then
                    if item.Parent ~= char then hum:EquipTool(item) end return item
                end
            end
        end
    end
    return nil
end
local function equipPunch() return equipTool({ "Punch" }) end

-- ========== Rock / Fast Punch ==========
local rockCache, capturedRock = {}, nil
local function cacheRockCFrame(rock)
    if not rock or rockCache[rock] then return end
    local touch = rock:FindFirstChild("TouchPart")
    rockCache[rock] = { rockCFrame = rock.CFrame, touchCFrame = touch and touch:IsA("BasePart") and touch.CFrame or nil }
end

local function restoreRock(rock)
    if not rock or not rock.Parent then return end
    local left = getCharacter() and getCharacter():FindFirstChild("LeftHand")
    local right = getCharacter() and getCharacter():FindFirstChild("RightHand")
    if type(firetouchinterest) == "function" then
        if right then pcall(firetouchinterest, rock, right, 1) end
        if left then pcall(firetouchinterest, rock, left, 1) end
    end
    local cached = rockCache[rock]
    if cached then
        pcall(function() rock.CFrame = cached.rockCFrame local touch = rock:FindFirstChild("TouchPart") if touch and cached.touchCFrame then touch.CFrame = cached.touchCFrame end end)
    end
end

local function clearRockSession()
    State.rockGeneration = State.rockGeneration + 1
    State.selectedRock = nil
    if capturedRock then restoreRock(capturedRock) capturedRock = nil end
end

local function findRockByDurability(dur)
    dur = tonumber(dur)
    if not dur and dur ~= 0 then return nil end
    if typeof(rockCache[dur]) == "Instance" and rockCache[dur].Parent then return rockCache[dur] end
    local folder = workspace:FindFirstChild("machinesFolder")
    if not folder then return nil end
    for _, item in pairs(folder:GetDescendants()) do
        if item.Name == "neededDurability" and item:IsA("ValueBase") and tonumber(item.Value) == dur then
            local rock = item.Parent and item.Parent:FindFirstChild("Rock")
            if rock and rock:IsA("BasePart") then cacheRockCFrame(rock) rockCache[dur] = rock return rock end
        end
    end
    return nil
end

local function attachRockToHand()
    local selected, gen = State.selectedRock, State.rockGeneration
    if not selected then return end
    local char = getCharacter()
    local left, right = char and char:FindFirstChild("LeftHand"), char and char:FindFirstChild("RightHand")
    if not left or not right then return end
    local rock = findRockByDurability(selected.durability)
    if not rock then return end
    if capturedRock ~= rock then if capturedRock then restoreRock(capturedRock) end capturedRock = rock end
    
    cacheRockCFrame(rock)
    pcall(function()
        rock.Size, rock.Transparency, rock.CanCollide = Vector3.new(2, 1, 1), 1, false
        for _, name in ipairs({ "rockEmitter", "hoopParticle", "lavaParticle", "rockGui" }) do
            local x = rock:FindFirstChild(name) if x then if x:IsA("GuiObject") or x:IsA("ScreenGui") then x:Destroy() else x:Destroy() end end
        end
        rock.CFrame = left.CFrame
        local touch = rock:FindFirstChild("TouchPart")
        if touch then touch.CFrame = left.CFrame end
    end)
    
    if type(firetouchinterest) == "function" then
        pcall(firetouchinterest, rock, right, 0) pcall(firetouchinterest, rock, right, 1)
        pcall(firetouchinterest, rock, left, 0) pcall(firetouchinterest, rock, left, 1)
    end
    equipPunch()
end

local function punchSystemActive() return State.running and (State.fastPunch == true or State.selectedRock ~= nil) end
local function stopPunchTasks()
    cancelTask("fastPunchEquip") cancelTask("fastPunchHit") cancelTask("fastPunchRock")
    pcall(function() local punch = equipPunch() if punch then local at = punch:FindFirstChild("attackTime") if at then at.Value = 0.3 end end end)
end

local function startPunchTasks()
    stopPunchTasks()
    spawnTask("fastPunchEquip", function()
        while punchSystemActive() do
            if State.selectedRock then pcall(function() local punch = equipPunch() if punch then local at = punch:FindFirstChild("attackTime") if at then at.Value = 0 end end end) end
            task.wait(0.05)
        end
    end)
    spawnTask("fastPunchHit", function()
        while punchSystemActive() do
            pcall(function()
                local punch = getCharacter() and getCharacter():FindFirstChild("Punch")
                if punch then local at = punch:FindFirstChild("attackTime") if at then at.Value = 0 end pcall(punch.Activate, punch) end
                local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                if muscleEvent then muscleEvent:FireServer("punch", "rightHand") muscleEvent:FireServer("punch", "leftHand") end
            end)
            task.wait(0.01)
        end
    end)
    spawnTask("fastPunchRock", function()
        while punchSystemActive() do
            if State.selectedRock then
                pcall(attachRockToHand)
                local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                if muscleEvent then pcall(muscleEvent.FireServer, muscleEvent, "punch", "rightHand") pcall(muscleEvent.FireServer, muscleEvent, "punch", "leftHand") end
            end
            task.wait(0.4) -- Velocidade balanceada
        end
    end)
end

local function setFastPunch(enabled)
    State.fastPunch = enabled == true
    if not punchSystemActive() then if not State.fastPunch then clearRockSession() end stopPunchTasks() return end
    startPunchTasks()
end

local function setRockSelection(rockOrNil)
    clearRockSession()
    State.selectedRock = rockOrNil
    if rockOrNil then startPunchTasks() pcall(function() findRockByDurability(rockOrNil.durability) attachRockToHand() equipPunch() end)
    else if not State.fastPunch then stopPunchTasks() end end
end

-- ========== Auto Rep / Exercise ==========
local repValueBackup = {}
local function zeroRepTime(key, tool)
    if not tool then return end
    local repTime = tool:FindFirstChild("repTime")
    if not repTime or not repTime:IsA("ValueBase") then return end
    repValueBackup[key] = repValueBackup[key] or {}
    if repValueBackup[key][repTime] == nil then repValueBackup[key][repTime] = repTime.Value end
    repTime.Value = 0
end
local function restoreRepTime(key)
    if not repValueBackup[key] then return end
    for val, original in pairs(repValueBackup[key]) do if val and val.Parent then pcall(function() val.Value = original end) end end
    repValueBackup[key] = nil
end

local function setExercise(key, enabled, toolNames, delay)
    State[key] = enabled == true
    local em = State.exerciseMovement
    em.active[key] = State[key] or nil
    local taskName = "rep_" .. key
    if not State[key] then
        cancelTask(taskName) restoreRepTime(key)
        local char, bp = getCharacter(), LocalPlayer:FindFirstChild("Backpack")
        if char and bp and toolNames then
            for _, n in ipairs(toolNames) do
                for _, item in ipairs(char:GetChildren()) do
                    if item:IsA("Tool") and item.Name:lower() == n:lower() then pcall(function() item.Parent = bp end) end
                end
            end
        end
        if next(em.active) == nil then
            cancelTask("exerciseMovement")
            if em.humanoid and em.humanoid.Parent then pcall(function() if not State.fastSpeed and em.walkSpeed then em.humanoid.WalkSpeed = em.walkSpeed end end) end
            em.humanoid = nil
        end
        return
    end
    spawnTask("exerciseMovement", function()
        while State.running and next(em.active) do
            local hum, hrp = getHumanoid(), getHRP()
            if hum then
                if em.humanoid ~= hum then em.humanoid = hum em.walkSpeed = hum.WalkSpeed > 0 and hum.WalkSpeed or 16 end
                if hrp then hrp.Anchored = false end
                hum.PlatformStand, hum.Sit = false, false
                local ws = State.fastSpeed and 1000 or em.walkSpeed
                if ws and hum.WalkSpeed < ws then hum.WalkSpeed = ws end
            end
            RunService.Heartbeat:Wait()
        end
    end)
    spawnTask(taskName, function()
        while State.running and State[key] do
            pcall(function()
                local tool
                if toolNames and #toolNames > 0 then tool = equipTool(toolNames) zeroRepTime(key, tool) end
                local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                if muscleEvent then muscleEvent:FireServer("rep") end
                if tool then tool:Activate() end
            end)
            task.wait(delay or 0.05)
        end
    end)
end

-- ========== Walk on Water ==========
local waterParts = {}
local function setWalkWater(enabled)
    State.walkWater = enabled == true
    for _, p in ipairs(waterParts) do if p and p.Parent then p:Destroy() end end
    table.clear(waterParts)
    if not State.walkWater then return end
    local origin = Vector3.new(-3072, -9.5, -3072)
    for x = -4, 4 do
        for z = -4, 4 do
            local part = Instance.new("Part")
            part.Name, part.Size, part.Position = "WaterFloor", Vector3.new(2048, 1, 2048), origin + Vector3.new(x * 2048, 0, z * 2048)
            part.Anchored, part.CanCollide, part.Transparency, part.CastShadow, part.Parent = true, true, 1, false, workspace
            waterParts[#waterParts + 1] = part
        end
    end
end

-- ========== UI Visibility / Portals ==========
local framesHidden = {}
local function hideFrameObject(obj)
    if obj and obj.Parent == ReplicatedStorage and obj:IsA("GuiObject") and obj.Name:lower():match("frame$") then
        if framesHidden[obj] == nil then framesHidden[obj] = obj.Visible end
        pcall(function() obj.Visible = false end)
    end
end

local function setHideFrames(enabled)
    State.hideFrames = enabled == true
    cancelTask("hideFramesLoop")
    local function applyStatGui()
        local gui = PlayerGui:FindFirstChild("statEffectsGui")
        if not gui then return end
        if State.hideFrames then
            if framesHidden[gui] == nil then framesHidden[gui] = gui:IsA("ScreenGui") and gui.Enabled or (gui:IsA("GuiObject") and gui.Visible) end
            pcall(function() if gui:IsA("ScreenGui") then gui.Enabled = false end if gui:IsA("GuiObject") then gui.Visible = false end end)
        else
            local prev = framesHidden[gui]
            if prev ~= nil then pcall(function() if gui:IsA("ScreenGui") then gui.Enabled = prev end if gui:IsA("GuiObject") then gui.Visible = prev end end) framesHidden[gui] = nil end
        end
    end
    if State.hideFrames then
        spawnTask("hideFramesLoop", function()
            while State.running and State.hideFrames do
                applyStatGui()
                for _, item in ipairs(ReplicatedStorage:GetChildren()) do pcall(hideFrameObject, item) end
                task.wait(0.5)
            end
        end)
    else
        for obj, vis in pairs(framesHidden) do
            if obj and obj.Parent then pcall(function() if obj:IsA("ScreenGui") then obj.Enabled = vis elseif obj:IsA("GuiObject") then obj.Visible = vis end end) end
        end
        table.clear(framesHidden)
    end
end

local removedPortals, portalConn = {}, nil
local function setRemovePortals(enabled)
    State.removePortals = enabled == true
    cancelTask("removePortals")
    if portalConn then pcall(function() portalConn:Disconnect() end) portalConn = nil end
    if not State.removePortals then
        for _, e in ipairs(removedPortals) do if e.object and not e.object.Parent and e.parent then pcall(function() e.object.Parent = e.parent end) end end
        table.clear(removedPortals) return
    end
    local function checkAndRemove(obj)
        if obj and obj.Parent and string.match(string.lower(obj.Name), "portal|ad|sponsor|advert") then
            pcall(function() removedPortals[#removedPortals + 1] = { object = obj, parent = obj.Parent } obj.Parent = nil end)
        end
    end
    portalConn = workspace.DescendantAdded:Connect(function(obj) task.defer(checkAndRemove, obj) end)
    spawnTask("removePortals", function() while State.running and State.removePortals do for _, obj in ipairs(workspace:GetDescendants()) do checkAndRemove(obj) end task.wait(2) end end)
end

-- ========== Fast Farm / Macros ==========
local function applySizeOrSpeed(kind, value)
    value = tonumber(value)
    if not value then return false end
    local events = ReplicatedStorage:FindFirstChild("rEvents") or ReplicatedStorage:FindFirstChild("Events")
    local remote = events and events:FindFirstChild("changeSpeedSizeRemote") or ReplicatedStorage:FindFirstChild("changeSpeedSizeRemote", true)
    if remote then
        pcall(function()
            if remote:IsA("RemoteFunction") then remote:InvokeServer(kind == "changeSize" and "changeSize" or "changeSpeed", value)
            else remote:FireServer(kind == "changeSize" and "changeSize" or "changeSpeed", value) end
        end)
    end
end

local function setSizeOne()
    local hum = getHumanoid()
    if hum then
        for _, n in ipairs({"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale"}) do
            local s = hum:FindFirstChild(n) if s and s:IsA("NumberValue") then pcall(function() s.Value = 1 end) end
        end
    end
    task.spawn(function() applySizeOrSpeed("changeSize", 1) end)
end

local function requestRebirth()
    local events = ReplicatedStorage:FindFirstChild("rEvents")
    local remote = events and events:FindFirstChild("rebirthRemote")
    if remote then
        pcall(function()
            if remote:IsA("RemoteFunction") then remote:InvokeServer("rebirthRequest") remote:InvokeServer("rebirth")
            else remote:FireServer("rebirthRequest") remote:FireServer("rebirth") end
        end)
    end
    if not State.preventRebirth then
        pcall(function()
            local btn = PlayerGui and PlayerGui:FindFirstChild("gameGui") and PlayerGui.gameGui:FindFirstChild("rebirthMenu") and PlayerGui.gameGui.rebirthMenu:FindFirstChild("confirmButton")
            if btn and btn:IsA("GuiButton") and btn.Visible then firesignal(btn.MouseButton1Click) end
        end)
    end
end

local FastFarm = { mode = nil }
function FastFarm:Stop()
    self.mode = nil
    cancelTask("fastFarmMain")
end
function FastFarm:Start(mode)
    self:Stop()
    self.mode = mode
    spawnTask("fastFarmMain", function()
        setSizeOne()
        while State.running and self.mode == mode do
            pcall(function()
                local tool = equipTool({"Weight", "Heavy Weight"})
                if tool then
                    local ev = LocalPlayer:FindFirstChild("muscleEvent")
                    if ev then for _=1, 3 do ev:FireServer("rep") end end
                    tool:Activate()
                end
                if mode == "rebirth" then requestRebirth() end
            end)
            task.wait(0.05)
        end
    end)
end

-- ========== KILLS & SPAWN PROTECTION ==========
local function hasSpawnProtection(player)
    if not player then return false end
    local head = player.Character and player.Character:FindFirstChild("Head")
    return head and head:FindFirstChild("spawnProtectionGui") ~= nil
end

local function isFriend(player)
    local lower = (tostring(player and player.DisplayName or "")):lower()
    if lower:find("0x", 1, true) then return true end
    if not State.kill.protectFriends then return false end
    if State.kill.friendCache[player.UserId] ~= nil then return State.kill.friendCache[player.UserId] end
    local ok, res = pcall(LocalPlayer.IsFriendsWith, LocalPlayer, player.UserId)
    State.kill.friendCache[player.UserId] = ok and res or true
    return State.kill.friendCache[player.UserId]
end

local function getFireTouch()
    local ft = rawget(_G, "firetouchinterest") or firetouchinterest
    if type(ft) == "function" then return ft end
    local ok, v = pcall(function() return getgenv and getgenv().firetouchinterest end)
    return ok and type(v) == "function" and v or nil
end

local function punchPlayer(player)
    if not player or player == LocalPlayer or isFriend(player) or hasSpawnProtection(player) then return false end
    local targetHrp = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso"))
    local myChar, myHrp = getCharacter(), getHRP()
    if not targetHrp or not myChar or not myHrp then return false end
    
    local punch = equipPunch()
    if punch then pcall(function() punch:Activate() end) end
    local ev = LocalPlayer:FindFirstChild("muscleEvent")
    if ev then pcall(function() ev:FireServer("punch", "rightHand") ev:FireServer("punch", "leftHand") ev:FireServer("punch") end) end
    
    local ft = getFireTouch()
    if ft then
        local parts = {myChar:FindFirstChild("RightHand"), myChar:FindFirstChild("LeftHand"), punch and punch:FindFirstChild("Handle")}
        for _, p in ipairs(parts) do
            if p then pcall(ft, targetHrp, p, 0) pcall(ft, targetHrp, p, 1) end
        end
    end
    return true
end

local function karmaMatch(player, mode)
    if not mode or not player or player == LocalPlayer then return mode == nil end
    local ls = player:FindFirstChild("leaderstats") or player
    local g = tonumber(ls:FindFirstChild("GoodKarma") and ls.GoodKarma.Value or 0) or 0
    local e = tonumber(ls:FindFirstChild("EvilKarma") and ls.EvilKarma.Value or 0) or 0
    if mode == "evil" then return g >= e end
    if mode == "good" then return e >= g end
    return false
end

local function runKillLoop()
    cancelTask("killFarm")
    if not (State.kill.auto or State.kill.karmaMode or State.kill.targetMode) then return end
    spawnTask("killFarm", function()
        while State.running and (State.kill.auto or State.kill.karmaMode or State.kill.targetMode) do
            pcall(function()
                if State.kill.targetMode and State.kill.target then
                    local p = Players:FindFirstChild(State.kill.target)
                    if p then punchPlayer(p) end
                else
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and karmaMatch(p, State.kill.karmaMode) then punchPlayer(p) end
                    end
                end
            end)
            task.wait(0.05)
        end
    end)
end

State.setServerHop = function(enabled)
    State.kill.serverHop = enabled == true
    cancelTask("killServerHop")
    if State.kill.serverHop then
        spawnTask("killServerHop", function()
            while State.running and State.kill.serverHop do
                local interval = Config.ServerHop.Interval
                while interval > 0 do if not State.running or not State.kill.serverHop then return end task.wait(1) interval = interval - 1 end
                
                local ok, result = pcall(game.HttpGet, game, string.format(Config.ServerHop.ServerApi, game.PlaceId), true)
                if ok and type(result) == "string" then
                    local dOk, data = pcall(HttpService.JSONDecode, HttpService, result)
                    if dOk and data and data.data then
                        local cands = {}
                        for _, s in ipairs(data.data) do
                            if type(s)=="table" and s.id ~= game.JobId and tonumber(s.playing) and tonumber(s.maxPlayers) and tonumber(s.playing) < tonumber(s.maxPlayers) and tonumber(s.playing) >= Config.ServerHop.MinimumPlayers then
                                cands[#cands+1] = s
                            end
                        end
                        if #cands > 0 then
                            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, cands[math.random(1, #cands)].id, LocalPlayer) end)
                        end
                    end
                end
                task.wait(Config.ServerHop.RetryDelay)
            end
        end)
    end
end

-- ========== Loop Movimento ==========
local spinAngular, spinHum, spinAutoRotate = nil, nil, nil
local function clearSpin() if spinAngular then spinAngular:Destroy() spinAngular = nil end if spinHum then spinHum.AutoRotate = spinAutoRotate spinHum = nil end end

track(RunService.Heartbeat:Connect(function()
    if not State.running then return end
    local hum, hrp = getHumanoid(), getHRP()
    
    if State.fastSpeed and hum then hum.WalkSpeed = 1000 end
    
    if State.antiKnockback and hrp and hum then
        if not State.antiKnockbackVelocity or State.antiKnockbackVelocity.Parent ~= hrp then
            if State.antiKnockbackVelocity then State.antiKnockbackVelocity:Destroy() end
            State.antiKnockbackVelocity = Instance.new("BodyVelocity")
            State.antiKnockbackVelocity.Name, State.antiKnockbackVelocity.P, State.antiKnockbackVelocity.MaxForce, State.antiKnockbackVelocity.Parent = "AntiKnockback", 50000, Vector3.new(1e9, 1e9, 1e9), hrp
        end
        local md, spd = hum.MoveDirection, (State.fastSpeed and 1000 or math.max(hum.WalkSpeed, 16))
        State.antiKnockbackVelocity.Velocity = Vector3.new(md.X * spd, math.clamp(hrp.AssemblyLinearVelocity.Y, -35, 50), md.Z * spd)
        hrp.AssemblyAngularVelocity = Vector3.zero
    elseif State.antiKnockbackVelocity then State.antiKnockbackVelocity:Destroy() State.antiKnockbackVelocity = nil end
    
    if State.spin and hrp and hum then
        if not spinAngular or spinAngular.Parent ~= hrp then
            clearSpin() spinHum, spinAutoRotate, hum.AutoRotate = hum, hum.AutoRotate, false
            spinAngular = Instance.new("BodyAngularVelocity")
            spinAngular.Name, spinAngular.AngularVelocity, spinAngular.MaxTorque, spinAngular.P, spinAngular.Parent = "Spin", Vector3.new(0, 7, 0), Vector3.new(0, 9e9, 0), 6000, hrp
        end
    elseif spinAngular then clearSpin() end
    
    if State.spy and workspace.CurrentCamera then
        local target = State.spyTarget and Players:FindFirstChild(State.spyTarget)
        local subj = target and target.Character and target.Character:FindFirstChildWhichIsA("Humanoid")
        if subj then workspace.CurrentCamera.CameraSubject = subj end
    end
end))

track(UserInputService.JumpRequest:Connect(function() if State.infiniteJump then local h = getHumanoid() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))

-- ========== VOID UI ==========
local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/slowzzx4-8/Ui-library/refs/heads/main/Void%20Ui%20Library.lua"))()
local Window = VoidUI:CreateWindow({
    Name = "Muscle Legends", Icon = "dumbbell", SideBarWidth = 160, Theme = "Dark",
    Transparent = true, Author = "By Slowzzx4", User = { Enabled = true, Anonymous = true }, Folder = "MuscleLegendsScript",
})

Window:EditOpenButton({ Title = "Muscle Legends", Icon = "dumbbell", Transparency = 0.2, StrokeThickness = 1.2, AutoRotation = false, Speed = 12, CornerRadius = UDim.new(0, 16) })
pcall(function() Window:SetToggleKey(Enum.KeyCode[GetSave("ToggleKey", "RightControl")]) end)

local Tabs = { 
    Main = Window:Tab({ Title = "Home", Icon = "house", Border = true }), 
    AutoFarm = Window:Tab({ Title = "Auto Farm", Icon = "sprout", Border = true }), 
    Rebirths = Window:Tab({ Title = "Auto Rebirth", Icon = "refresh-cw", Border = true }), 
    Kills = Window:Tab({ Title = "Kills", Icon = "crosshair", Border = true }), 
    Gifts = Window:Tab({ Title = "Gifts", Icon = "gift", Border = true }), 
    Trade = Window:Tab({ Title = "Trade", Icon = "repeat", Border = true }), 
    Teleports = Window:Tab({ Title = "Teleports", Icon = "map-pin", Border = true }), 
    Stats = Window:Tab({ Title = "Stats", Icon = "activity", Border = true }), 
    Misc = Window:Tab({ Title = "Misc", Icon = "settings", Border = true }) 
}

local function playerList() local list = {} for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then list[#list + 1] = p.DisplayName .. " (" .. p.Name .. ")" end end table.sort(list) return list end
local function resolvePlayer(label) if not label then return nil end return Players:FindFirstChild(label:match("%((.-)%)") or label) end

-- ========== MAIN (Salvo) ==========
Tabs.Main:TabSection({ Title = "Size / Speed" })
Tabs.Main:Slider({
    Title = "Size", Value = { Min = 1, Max = 100, Default = GetSave("MainSize", 2) }, Step = 1,
    Callback = function(v) State.mainSize = v SetSave("MainSize", v) if State.mainAutoSize then applySizeOrSpeed("changeSize", v) end end
})
Tabs.Main:Toggle({
    Title = "Auto Size", Default = GetSave("MainAutoSize", false),
    Callback = function(v)
        State.mainAutoSize = v SetSave("MainAutoSize", v) cancelTask("mainAutoSize")
        if v then spawnTask("mainAutoSize", function() while State.running and State.mainAutoSize do applySizeOrSpeed("changeSize", State.mainSize) task.wait(0.35) end end) end
    end
})
Tabs.Main:Slider({
    Title = "Speed", Value = { Min = 16, Max = 500, Default = GetSave("MainSpeed", 125) }, Step = 1,
    Callback = function(v) State.mainSpeed = v SetSave("MainSpeed", v) if State.mainAutoSpeed then applySizeOrSpeed("changeSpeed", v) end end
})
Tabs.Main:Toggle({
    Title = "Auto Speed", Default = GetSave("MainAutoSpeed", false),
    Callback = function(v)
        State.mainAutoSpeed = v SetSave("MainAutoSpeed", v) cancelTask("mainAutoSpeed")
        if v then spawnTask("mainAutoSpeed", function() while State.running and State.mainAutoSpeed do applySizeOrSpeed("changeSpeed", State.mainSpeed) task.wait(0.35) end end) end
    end
})
Tabs.Main:Toggle({ Title = "Walk On Water", Default = GetSave("WalkOnWater", false), Callback = function(v) SetSave("WalkOnWater", v) setWalkWater(v) end })
Tabs.Main:Toggle({ Title = "Infinite Jump", Default = GetSave("InfiniteJump", false), Callback = function(v) SetSave("InfiniteJump", v) State.infiniteJump = v end })
Tabs.Main:Toggle({ Title = "Anti Stun", Default = GetSave("AntiStun", false), Callback = function(v) SetSave("AntiStun", v) State.antiKnockback = v end })
Tabs.Main:Toggle({ Title = "Spin Character", Default = GetSave("SpinChar", false), Callback = function(v) SetSave("SpinChar", v) State.spin = v end })

-- ========== AUTO FARM (Salvo) ==========
Tabs.AutoFarm:TabSection({ Title = "Rocks" })
local rockNames, rockByName = {}, {}
for _, r in ipairs(Config.Rocks) do rockNames[#rockNames + 1] = r.name rockByName[r.name] = r end
local selectedRockName = GetSave("SelectRock", rockNames[1])
Tabs.AutoFarm:Dropdown({
    Title = "Select Rock", Option = rockNames, Value = selectedRockName,
    Callback = function(v) selectedRockName = v SetSave("SelectRock", v) if State._autoRock then setRockSelection(rockByName[v]) end end
})
Tabs.AutoFarm:Toggle({
    Title = "Auto Rock", Default = GetSave("AutoRock", false),
    Callback = function(v) State._autoRock = v SetSave("AutoRock", v) setRockSelection(v and rockByName[selectedRockName] or nil) end
})
Tabs.AutoFarm:Toggle({ Title = "Fast Punch", Default = GetSave("FastPunch", false), Callback = function(v) SetSave("FastPunch", v) setFastPunch(v) end })

Tabs.AutoFarm:TabSection({ Title = "Brawl & Tools" })
Tabs.AutoFarm:Toggle({
    Title = "Auto Join Brawl", Default = GetSave("AutoJoinBrawl", false),
    Callback = function(v)
        State._autoBrawl = v SetSave("AutoJoinBrawl", v) cancelTask("autoBrawlJoin")
        if v then spawnTask("autoBrawlJoin", function() while State.running and State._autoBrawl do pcall(function() local lbl = PlayerGui:FindFirstChild("gameGui") and PlayerGui.gameGui:FindFirstChild("brawlJoinLabel") if lbl and lbl.Visible then ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl") task.wait(3) end end) task.wait(0.5) end end) end
    end
})
Tabs.AutoFarm:Toggle({
    Title = "Auto Kill In Brawl", Default = GetSave("AutoKillBrawl", false),
    Callback = function(v)
        State._brawlAutoKill = v SetSave("AutoKillBrawl", v) cancelTask("brawlAutoKill")
        if v then 
            spawnTask("brawlAutoKill", function() 
                while State.running and State._brawlAutoKill do 
                    local lbl = PlayerGui:FindFirstChild("gameGui") and PlayerGui.gameGui:FindFirstChild("participationRewardLabel") 
                    if LocalPlayer:FindFirstChild("currentMap") and LocalPlayer.currentMap.Value:find("Ring") and lbl and lbl.Visible then 
                        for _, p in ipairs(Players:GetPlayers()) do 
                            if p ~= LocalPlayer and p:FindFirstChild("currentMap") and p.currentMap.Value == LocalPlayer.currentMap.Value then 
                                pcall(punchPlayer, p) 
                            end 
                        end 
                    end 
                    task.wait(0.05) 
                end 
            end) 
        end
    end
})
Tabs.AutoFarm:Toggle({
    Title = "Auto Use Tools", Default = GetSave("AutoUseTools", false),
    Callback = function(v)
        State.autoUseTools = v SetSave("AutoUseTools", v) cancelTask("autoUseTools")
        if v then spawnTask("autoUseTools", function() while State.running and State.autoUseTools do pcall(function() local ev = LocalPlayer:FindFirstChild("muscleEvent") if ev then for _=1,3 do ev:FireServer("rep") end end end) task.wait(0.18) end end) end
    end
})

Tabs.AutoFarm:TabSection({ Title = "Exercises" })
for _, def in ipairs({ {"Auto Handstands", "autoHandstands", {"Handstands", "Handstand"}}, {"Auto Situps", "autoSitups", {"Situps", "Situp"}}, {"Auto Weight", "autoWeight", {"Weight"}}, {"Auto Lift", "autoLift", {"Pushup", "Pushups"}} }) do
    Tabs.AutoFarm:Toggle({ Title = def[1], Default = GetSave(def[2], false), Callback = function(v) SetSave(def[2], v) setExercise(def[2], v, def[3], 0.05) end })
end

Tabs.AutoFarm:TabSection({ Title = "Protein" })
local proteinNamesList = {}
for _, def in ipairs(PROTEIN_ITEMS) do proteinNamesList[#proteinNamesList + 1] = def.tool end
Tabs.AutoFarm:Dropdown({
    Title = "Select Protein Items", Option = proteinNamesList, Multi = true, Value = GetSave("SelectedProteinItems", nil),
    Callback = function(v)
        local map = {}
        if type(v) == "table" then for _, name in ipairs(v) do map[name] = true end elseif type(v) == "string" then map[v] = true end
        State.selectedProteinItems = map
        SetSave("SelectedProteinItems", v)
    end,
})
Tabs.AutoFarm:Toggle({
    Title = "Auto Eat Protein", Default = GetSave("AutoEatProtein", false),
    Callback = function(v)
        State.autoEatProtein = v SetSave("AutoEatProtein", v) cancelTask("autoEatProtein")
        if v then spawnTask("autoEatProtein", function() while State.running and State.autoEatProtein do pcall(function() local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent") if not muscleEvent then return end local selected = State.selectedProteinItems if type(selected) ~= "table" or next(selected) == nil then return end for _, def in ipairs(PROTEIN_ITEMS) do if selected[def.tool] then local tool = equipTool({def.tool}) if tool then muscleEvent:FireServer(def.event, tool) end end end end) task.wait(0.28) end end) end
    end
})

-- ========== REBIRTHS (Só Prevent Rebirth é Salvo) ==========
Tabs.Rebirths:TabSection({ Title = "Fast Farm" })
Tabs.Rebirths:Toggle({ Title = "Fast Rebirth", Default = false, Callback = function(v) if v then FastFarm:Start("rebirth") else FastFarm:Stop() end end })
Tabs.Rebirths:Toggle({ Title = "Fast Strength", Default = false, Callback = function(v) if v then FastFarm:Start("strength") else FastFarm:Stop() end end })

Tabs.Rebirths:TabSection({ Title = "Auto Rebirth" })
Tabs.Rebirths:Input({ Title = "Rebirth Objective", Placeholder = "18980", Default = nil, Value = nil, Callback = function(text) local num = tonumber(string.match(tostring(text or ""), "%d+")) State.rebirth.objective = num or 0 end })
Tabs.Rebirths:Toggle({
    Title = "Auto Rebirth", Default = false,
    Callback = function(v)
        State.rebirth.autoRebirth = v if v then State.rebirth.infinite = false end cancelTask("smartAutoRebirthTask")
        if v then spawnTask("smartAutoRebirthTask", function() while State.running and State.rebirth.autoRebirth do pcall(function() local rStat = tonumber(LocalPlayer.leaderstats.Rebirths.Value) or 0 if State.rebirth.objective > 0 and rStat >= State.rebirth.objective then State.rebirth.autoRebirth = false return end requestRebirth() end) task.wait(1.5) end end) end
    end
})
Tabs.Rebirths:Toggle({ Title = "Infinite Rebirths", Default = false, Callback = function(v) State.rebirth.infinite = v if v then State.rebirth.autoRebirth = false end cancelTask("rebirthLoop") if v then spawnTask("rebirthLoop", function() while State.running and State.rebirth.infinite do requestRebirth() task.wait(0.1) end end) end end })

Tabs.Rebirths:TabSection({ Title = "Extras" })
Tabs.Rebirths:Toggle({
    Title = "Prevent Rebirth", Default = GetSave("PreventRebirth", false),
    Callback = function(v)
        State.preventRebirth = v SetSave("PreventRebirth", v) cancelTask("prevRebirth")
        if v then spawnTask("prevRebirth", function() while State.running and State.preventRebirth do pcall(function() local btn = PlayerGui:FindFirstChild("gameGui") and PlayerGui.gameGui:FindFirstChild("rebirthMenu") and PlayerGui.gameGui.rebirthMenu:FindFirstChild("confirmButton") if btn then btn.Visible = false btn.Active = false end end) task.wait(0.25) end end) end
    end
})
Tabs.Rebirths:Toggle({
    Title = "Auto Muscle King", Default = false,
    Callback = function(v)
        State.rebirth.king = v cancelTask("rebirthKing")
        if v then local kingPos = Vector3.new(-8646, 13.25, -5738) spawnTask("rebirthKing", function() while State.running and State.rebirth.king do local hrp = getHRP() if hrp and (hrp.Position - kingPos).Magnitude > 42 then hrp.CFrame = CFrame.new(kingPos) hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero end task.wait(0.2) end end) end
    end
})

-- ========== KILLS (Salvo) ==========
Tabs.Kills:TabSection({ Title = "Target" })
Tabs.Kills:Dropdown({ Title = "Choose Player", Option = playerList(), Value = GetSave("KillTarget", nil), Callback = function(v) local p = resolvePlayer(v) State.kill.target = p and p.Name SetSave("KillTarget", v) end })
Tabs.Kills:Toggle({ Title = "View Player", Default = GetSave("ViewPlayer", false), Callback = function(v) SetSave("ViewPlayer", v) State.spyTarget = State.kill.target State.spy = v end })
Tabs.Kills:Toggle({ Title = "Kill Selected Player", Default = GetSave("KillSelected", false), Callback = function(v) SetSave("KillSelected", v) State.kill.targetMode = v State.kill.auto = false State.kill.karmaMode = nil runKillLoop() end })
Tabs.Kills:Toggle({ Title = "Kill ALL", Default = GetSave("KillAll", false), Callback = function(v) SetSave("KillAll", v) State.kill.auto = v State.kill.targetMode = false State.kill.karmaMode = nil runKillLoop() end })
Tabs.Kills:Toggle({ Title = "Protect Friends", Default = GetSave("ProtectFriends", false), Callback = function(v) SetSave("ProtectFriends", v) State.kill.protectFriends = v end })
Tabs.Kills:Toggle({ Title = "Evil Karma", Default = GetSave("KillEvil", false), Callback = function(v) SetSave("KillEvil", v) State.kill.karmaMode = v and "evil" or nil State.kill.auto, State.kill.targetMode = false, false runKillLoop() end })
Tabs.Kills:Toggle({ Title = "Good Karma", Default = GetSave("KillGood", false), Callback = function(v) SetSave("KillGood", v) State.kill.karmaMode = v and "good" or nil State.kill.auto, State.kill.targetMode = false, false runKillLoop() end })
Tabs.Kills:Toggle({ Title = "Server Hop (1m 30s)", Default = GetSave("KillHop", false), Callback = function(v) SetSave("KillHop", v) State.setServerHop(v) end })

-- ========== GIFTS (Salvo) ==========
Tabs.Gifts:TabSection({ Title = "Send" })
local giftItemOptions = { "Protein Egg", "Tropical Shake" }
Tabs.Gifts:Dropdown({ Title = "Select Players", Option = playerList(), Multi = true, Value = GetSave("GiftSelectedPlayers", nil), Callback = function(v) SetSave("GiftSelectedPlayers", v) State.giftSelectedPlayers = v end })
Tabs.Gifts:Dropdown({ Title = "Select Item", Option = giftItemOptions, Value = GetSave("GiftItem", "Protein Egg"), Callback = function(v) SetSave("GiftItem", v) State.giftItem = v end })
Tabs.Gifts:Dropdown({ Title = "Amount", Option = {"1","2","3","4","5","6","7","8","9","10"}, Value = GetSave("GiftAmount", "1"), Callback = function(v) SetSave("GiftAmount", v) State.giftAmount = tonumber(v) or 1 end })
Tabs.Gifts:Button({
    Title = "Confirm Send",
    Callback = function()
        if not State.giftSelectedPlayers or type(State.giftSelectedPlayers) ~= "table" or #State.giftSelectedPlayers == 0 then Window:Notify({ Title = "Gifts", Content = "Select Players First", Icon = "gift", Duration = 2 }) return end
        local folder = LocalPlayer:FindFirstChild("consumablesFolder")
        local remote = ReplicatedStorage:FindFirstChild("rEvents") and ReplicatedStorage.rEvents:FindFirstChild("giftRemote")
        if not remote then return end
        spawnTask("giftSender", function()
            for _, label in ipairs(State.giftSelectedPlayers) do
                local target = resolvePlayer(label)
                if target and State.running then
                    for _ = 1, (State.giftAmount or 1) do
                        if not State.running then break end
                        local item = nil
                        if folder then
                            if State.giftItem == "Protein Egg" then for _, n in ipairs(Config.AutoEgg.Names) do item = folder:FindFirstChild(n) if item then break end end else item = folder:FindFirstChild(State.giftItem) end
                        end
                        if not item then break end
                        pcall(function() if remote:IsA("RemoteFunction") then remote:InvokeServer("giftRequest", target, item) else remote:FireServer("giftRequest", target, item) end end)
                        task.wait(0.16)
                    end
                end
            end
            Window:Notify({ Title = "Gifts", Content = "Send Finished", Icon = "gift", Duration = 2 })
        end)
    end
})
Tabs.Gifts:Toggle({
    Title = "Spin Wheel", Default = GetSave("SpinWheel", false),
    Callback = function(v)
        State.autoSpinWheel = v SetSave("SpinWheel", v) cancelTask("fortuneWheel")
        if v then spawnTask("fortuneWheel", function() while State.running and State.autoSpinWheel do pcall(function() local wheelGui = PlayerGui:FindFirstChild("fortuneWheelMenuGui") if not wheelGui then return end local spinLabel = wheelGui:FindFirstChild("spinAmountLabel", true) if not spinLabel or not spinLabel.Text then return end local text = tostring(spinLabel.Text) local spinsLeft = 0 if text:lower():find("inf", 1, true) or text:find("∞") then spinsLeft = math.huge else spinsLeft = tonumber(string.match(text, "%d+")) or 0 end if spinsLeft >= 1 then ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer("openFortuneWheel", ReplicatedStorage.shared.catalogs.fortuneWheelChances["Fortune Wheel"]) end end) task.wait(1.5) end end) end
    end
})

-- ========== TRADE (Salvo) ==========
local function getPlayerNames() local list = {} for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LocalPlayer then list[#list + 1] = pl.Name end end table.sort(list) return list end
local function getInventoryList(folderName) local counts = {} local folder = LocalPlayer:FindFirstChild(folderName) if folder then for _, category in ipairs(folder:GetChildren()) do if category:IsA("Folder") then for _, item in ipairs(category:GetChildren()) do counts[item.Name] = (counts[item.Name] or 0) + 1 end end end end local list = {} for name, count in pairs(counts) do list[#list + 1] = name .. " x" .. count end table.sort(list) if #list == 0 then return { "None" } end return list end
local function getInstancesToOffer(folderName, formattedName, amountToOffer) local instances = {} if not formattedName or formattedName == "None" then return instances end local targetName = formattedName:match("^(.-)%s+x%d+") or formattedName local folder = LocalPlayer:FindFirstChild(folderName) if not folder then return instances end for _, category in ipairs(folder:GetChildren()) do if category:IsA("Folder") then for _, item in ipairs(category:GetChildren()) do if item.Name == targetName then instances[#instances + 1] = item if #instances >= (amountToOffer or 1) then return instances end end end end end return instances end

Tabs.Trade:TabSection({ Title = "Send / Accept" })
Tabs.Trade:Dropdown({ Title = "Send To Player", Option = getPlayerNames(), Value = GetSave("TradeSendTo", nil), Callback = function(v) State.tradeExt.sendToPlayer = v SetSave("TradeSendTo", v) end })
Tabs.Trade:Toggle({ Title = "Auto Send Request", Default = GetSave("TradeAutoSend", false), Callback = function(v) SetSave("TradeAutoSend", v) State._tradeSend = v spawnTask("tradeSend", function() while State.running and State._tradeSend do local p = Players:FindFirstChild(State.tradeExt.sendToPlayer or "") if p then pcall(function() ReplicatedStorage.rEvents.tradingEvent:FireServer("sendTradeRequest", p) end) end task.wait(1) end end) end })
Tabs.Trade:Dropdown({ Title = "Accept Invites From", Option = getPlayerNames(), Value = GetSave("TradeAcceptFrom", nil), Callback = function(v) State.tradeExt.acceptFromPlayer = v SetSave("TradeAcceptFrom", v) end })
Tabs.Trade:Toggle({ Title = "Auto Accept Invite", Default = GetSave("TradeAutoAccept", false), Callback = function(v) SetSave("TradeAutoAccept", v) State._tradeAccept = v spawnTask("tradeAcc", function() while State.running and State._tradeAccept do pcall(function() local p = Players:FindFirstChild(State.tradeExt.acceptFromPlayer or "") if p and PlayerGui.gameGui.tradeRequestMenu.Visible and PlayerGui.gameGui.tradeRequestMenu.msgLabel.Text:find(p.Name) then ReplicatedStorage.rEvents.tradingEvent:FireServer("requestAccepted", p) task.wait(2) end end) task.wait(0.5) end end) end })

Tabs.Trade:TabSection({ Title = "Items & Offers" })
Tabs.Trade:Dropdown({ Title = "Select Pet", Option = getInventoryList("petsFolder"), Value = GetSave("TradeSelectPet", nil), Callback = function(v) State.tradeExt.selectedPet = v SetSave("TradeSelectPet", v) end })
Tabs.Trade:Dropdown({ Title = "Select Aura", Option = getInventoryList("powerUpsFolder"), Value = GetSave("TradeSelectAura", nil), Callback = function(v) State.tradeExt.selectedAura = v SetSave("TradeSelectAura", v) end })
Tabs.Trade:Dropdown({ Title = "Amount Of Items", Option = { "1", "2", "3", "4", "5", "6" }, Value = GetSave("TradeAmount", "1"), Callback = function(v) State.tradeExt.amount = tonumber(v) or 1 SetSave("TradeAmount", v) end })
Tabs.Trade:Toggle({ Title = "Auto Put Pet", Default = GetSave("TradePutPet", false), Callback = function(v) SetSave("TradePutPet", v) State._autoPutPet = v cancelTask("autoPutPet") if v then spawnTask("autoPutPet", function() while State.running and State._autoPutPet do if State.tradeExt.selectedPet then local pets = getInstancesToOffer("petsFolder", State.tradeExt.selectedPet, State.tradeExt.amount or 1) for _, pet in ipairs(pets) do pcall(function() ReplicatedStorage.rEvents.tradingEvent:FireServer("offerItem", pet) end) task.wait(0.1) end end task.wait(1.5) end end) end end })
Tabs.Trade:Toggle({ Title = "Auto Put Aura", Default = GetSave("TradePutAura", false), Callback = function(v) SetSave("TradePutAura", v) State._autoPutAura = v cancelTask("autoPutAura") if v then spawnTask("autoPutAura", function() while State.running and State._autoPutAura do if State.tradeExt.selectedAura then local auras = getInstancesToOffer("powerUpsFolder", State.tradeExt.selectedAura, State.tradeExt.amount or 1) for _, aura in ipairs(auras) do pcall(function() ReplicatedStorage.rEvents.tradingEvent:FireServer("offerItem", aura) end) task.wait(0.1) end end task.wait(1.5) end end) end end })
Tabs.Trade:Toggle({ Title = "Auto Confirm Trade", Default = GetSave("TradeConfirm", false), Callback = function(v) SetSave("TradeConfirm", v) State._autoConfirmFinal = v cancelTask("autoConfirmFinal") if v then spawnTask("autoConfirmFinal", function() while State.running and State._autoConfirmFinal do pcall(function() local acceptedLabel = PlayerGui:FindFirstChild("gameGui") and PlayerGui.gameGui:FindFirstChild("acceptedLabel", true) if acceptedLabel and acceptedLabel.Visible then for _ = 1, 3 do ReplicatedStorage.rEvents.tradingEvent:FireServer("acceptTrade") task.wait(0.1) end while State.running and State._autoConfirmFinal and acceptedLabel.Visible do task.wait(0.2) end end end) task.wait(0.1) end end) end end })

-- ========== TELEPORTS ==========
Tabs.Teleports:TabSection({ Title = "Locations" })
for _, tp in ipairs(Config.Teleports) do Tabs.Teleports:Button({ Title = tp[1], Callback = function() local hrp = getHRP() if hrp then hrp.CFrame = CFrame.new(tp[2]) end end }) end

-- ========== STATS ==========
Tabs.Stats:TabSection({ Title = "Live Stats" })
local sessionStart = os.time()
local baseline = {}
local statNames = { { "Strength", { "Strength", "Fuerza" } }, { "Durability", { "Durability", "Durabilidad" } }, { "Rebirths", { "Rebirths", "Rebirth" } }, { "Kills", { "Kills" } }, { "Evil Karma", { "evilKarma", "Evil Karma" } }, { "Good Karma", { "goodKarma", "Good Karma" } } }
local sessionKV = Tabs.Stats:KeyValue({ Title = "Session", Value = "0d 0h 0m 0s" })
local strengthKV = Tabs.Stats:KeyValue({ Title = "Strength", Value = "0 (+0)" })
local durabilityKV = Tabs.Stats:KeyValue({ Title = "Durability", Value = "0 (+0)" })
local rebirthsKV = Tabs.Stats:KeyValue({ Title = "Rebirths", Value = "0 (+0)" })
local killsKV = Tabs.Stats:KeyValue({ Title = "Kills", Value = "0 (+0)" })
local evilKV = Tabs.Stats:KeyValue({ Title = "Evil Karma", Value = "0 (+0)" })
local goodKV = Tabs.Stats:KeyValue({ Title = "Good Karma", Value = "0 (+0)" })
local pingKV = Tabs.Stats:KeyValue({ Title = "Ping", Value = "0 ms" })
local paraMap = { Strength = strengthKV, Durability = durabilityKV, Rebirths = rebirthsKV, Kills = killsKV, ["Evil Karma"] = evilKV, ["Good Karma"] = goodKV }

local function setParagraphContent(para, text) if not para then return end pcall(function() if para.Set then para:Set(text) elseif para.SetContent then para:SetContent(text) elseif para.Content ~= nil then para.Content = text end end) end
spawnTask("statsUpdater", function()
    while State.running do
        local elapsed = os.time() - sessionStart
        setParagraphContent(sessionKV, string.format("%dd %dh %dm %ds", math.floor(elapsed / 86400), math.floor((elapsed % 86400) / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60))
        setParagraphContent(pingKV, tostring(getPing()) .. " ms")
        for _, entry in ipairs(statNames) do
            local stat = getStat(entry[2]) local val = tonumber(stat and stat.Value) or 0 if baseline[entry[1]] == nil then baseline[entry[1]] = val end
            local delta = val - baseline[entry[1]] local sign = delta >= 0 and "+" or "" local text = formatNumber(val) .. " " .. sign .. formatNumber(delta) setParagraphContent(paraMap[entry[1]], text)
        end
        task.wait(0.5)
    end
end)
Tabs.Stats:Button({ Title = "Reset Session Baseline", Callback = function() for _, entry in ipairs(statNames) do local stat = getStat(entry[2]) baseline[entry[1]] = tonumber(stat and stat.Value) or 0 end sessionStart = os.time() Window:Notify({ Title = "Stats", Content = "Baseline reset", Icon = "bar-chart-2", Duration = 2 }) end })

-- ========== MISC (Salvo) ==========
Tabs.Misc:TabSection({ Title = "Performance & UI" })
Tabs.Misc:Toggle({ Title = "Hide Frames", Default = GetSave("HideFrames", false), Callback = function(v) SetSave("HideFrames", v) setHideFrames(v) end })
Tabs.Misc:Toggle({ Title = "Remove Ad Portal", Default = GetSave("RemoveAds", false), Callback = function(v) SetSave("RemoveAds", v) setRemovePortals(v) end })
Tabs.Misc:Keybind({ Title = "Toggle UI Key", Default = GetSave("ToggleKey", "RightControl"), Callback = function(k) pcall(function() if typeof(k)=="string" and Enum.KeyCode[k] then Window:SetToggleKey(Enum.KeyCode[k]) SetSave("ToggleKey", k) end end) end })
Tabs.Misc:Input({ Title = "Bg Image ID", Placeholder = "ID", Callback = function(t) local txt = tostring(t or ""):gsub("%s+","") if txt~="" then SetSave("BgImage", txt) pcall(function() Window:SetBackgroundImage(txt, 0.3) end) end end })

-- Open
task.wait(0.08) pcall(function() Window:SelectTab(1) Window:Open() end)
local bg = GetSave("BgImage", "") if bg~="" then pcall(function() Window:SetBackgroundImage(bg, 0.3) end) end
print("[Muscle Legends] Saved Settings + Full Rebuild Edition Loaded")
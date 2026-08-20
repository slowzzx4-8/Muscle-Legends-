--[[
    Muscle Legends Script
    By Slowzzx4
    Void UI port - icons only, no external website links
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
    Machines = {
        { label = "Jungle Bench", object = "Jungle Bench", fallback = CFrame.new(-8173, 64, 1898) },
        { label = "Jungle Lift", object = "Jungle Bar Lift", fallback = CFrame.new(-8652.8672, 29.2667, 2089.2617) },
        { label = "Jungle Squat", object = "Jungle Squat", fallback = CFrame.new(-8352, 34, 2878) },
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
    UniqueAuras = { "Muscle King", "Entropic Blast" },
    UniquePets = {
        "Neon Guardian", "Cybernetic Showdown Dragon", "Darkstar Hunter",
        "Muscle Sensei", "Infernal Dragon", "Aether Spirit Bunny",
        "Magic Butterfly", "Ultra Birdie",
    },
    AutoEgg = { Interval = 1800, Names = { "ProteinEgg", "Protein Egg" } },
    FastFarm = {
        StrengthPet = "Swift Samurai",
        RebirthPet = "Tribal Overlord",
        MaxPets = 8,
        RepsPerCycle = 70,
        RepDelay = 0.005,
        PingSoft = 180, PingMedium = 300, PingHigh = 450, PingCritical = 600,
        PingPause = 999, PingResume = 400,
        StrengthStartBatch = 14, StrengthMaxBatch = 42,
        StrengthRampPing = 140, StrengthRampInterval = 4, StrengthDelay = 0.02,
        SizeInvokeInterval = 0.75, SizeReleaseDuration = 5, FramesReleaseDuration = 10,
        RockName = "Rock5M", RockInterval = 5,
        RebirthCycleDelay = 0.2, RebirthRequestWindow = 0.75,
    },
    ServerHop = {
        Interval = 120,
        ServerApi = "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100",
        PreferredPlayers = 18, MinimumPlayers = 16,
        NoTargetsDelay = 10, RetryDelay = 5, HistoryLimit = 60,
    },
}

-- ========== State ==========
local State = {
    running = true,
    fastPunch = false,
    selectedRock = nil,
    rockGeneration = 0,
    rockSessionStartedAt = nil,
    autoWeight = false,
    autoHandstands = false,
    autoLift = false,
    autoSitups = false,
    autoEgg = false,
    hideFrames = false,
    hideDurability = false,
    fastFarmMode = nil,
    machine = nil,
    autoPet = false,
    autoAura = false,
    antiLag = false,
    antiLagGeneration = 0,
    walkWater = false,
    autoSpinWheel = false,
    autoClaimChests = false,
    mainAutoSize = false,
    mainAutoSpeed = false,
    mainSize = 2,
    mainSpeed = 125,
    infiniteJump = false,
    removePortals = false,
    fastSpeed = false,
    fly = false,
    flyLevel = 10,
    antiKnockback = false,
    noclip = false,
    spin = false,
    spy = false,
    spyTarget = nil,
    kill = {
        auto = false, karmaMode = nil, protectFriends = false,
        targetMode = false, target = nil, serverHop = false,
        friendCache = {}, serverHistory = {}, serversVisited = 1,
        hopNow = false, noTargetsSince = nil, lockCFrame = nil, lockCharacter = nil,
    },
    trade = { busy = false, requestGeneration = 0, delivered = 0, total = 0 },
    rebirth = {
        target = nil, autoTarget = false, infinite = false,
        sizeOne = false, fastWeight = false, king = false,
        lockPosition = false, lockCFrame = nil, ultimateRunning = false,
    },
    exerciseMovement = {
        active = {}, humanoid = nil, walkSpeed = nil, jumpValue = nil, usesJumpPower = true,
    },
}

-- Task tracking
local taskHandles = {}
local connections = {}

local function cancelTask(name)
    if taskHandles[name] then
        pcall(task.cancel, taskHandles[name])
        taskHandles[name] = nil
    end
end

local function spawnTask(name, fn)
    cancelTask(name)
    taskHandles[name] = task.spawn(function()
        pcall(fn)
        taskHandles[name] = nil
    end)
    return taskHandles[name]
end

local function cleanupAll()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(connections)
    for k in pairs(taskHandles) do
        cancelTask(k)
    end
end

local function track(conn)
    connections[#connections + 1] = conn
    return conn
end

-- ========== Helpers ==========
local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function findPlayer(search)
    search = (tostring(search or "")):lower()
    if search == "" then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == search or p.DisplayName:lower() == search then
            return p
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(search, 1, true) or p.DisplayName:lower():find(search, 1, true) then
            return p
        end
    end
    return nil
end

local function findStat(container, names)
    if not container then return nil end
    local map = {}
    for _, n in ipairs(names) do
        map[(n:lower()):gsub("%s+", "")] = true
    end
    for _, child in ipairs(container:GetChildren()) do
        local key = (child.Name:lower()):gsub("%s+", "")
        if map[key] and child:IsA("ValueBase") then
            return child
        end
    end
    return nil
end

local function getStat(names)
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    return findStat(ls, names) or findStat(LocalPlayer, names)
end

local function formatNumber(n)
    n = tonumber(n) or 0
    local neg = n < 0
    local v = math.abs(n)
    -- K M B T QA QI e escalas maiores (maiúsculas)
    local units = {
        { 1e63, "VG" },
        { 1e60, "ND" },
        { 1e57, "OD" },
        { 1e54, "SP" },
        { 1e51, "SX" },
        { 1e48, "QI" },
        { 1e45, "QA" },
        { 1e42, "T" },
        { 1e39, "D" },
        { 1e36, "U" },
        { 1e33, "DC" },
        { 1e30, "N" },
        { 1e27, "O" },
        { 1e24, "S" },
        { 1e21, "S" },
        { 1e18, "QI" },
        { 1e15, "QA" },
        { 1e12, "T" },
        { 1e9,  "B" },
        { 1e6,  "M" },
        { 1e3,  "K" },
    }
    for _, entry in ipairs(units) do
        local div, suf = entry[1], entry[2]
        if v >= div then
            local num = v / div
            local text
            if num >= 100 then
                text = string.format("%.0f", num)
            elseif num >= 10 then
                text = string.format("%.1f", num)
                text = text:gsub("%.0$", "")
            else
                text = string.format("%.2f", num)
                text = text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
            end
            return (neg and "-" or "") .. text .. suf
        end
    end
    return (neg and "-" or "") .. string.format("%.0f", v)
end

local function getPing()
    local ok, result = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ok and math.floor((tonumber(result) or 0) + 0.5) or 0
end

local function serverTime()
    local ok, t = pcall(workspace.GetServerTimeNow, workspace)
    if ok and type(t) == "number" then return t end
    return os.clock()
end

local function equipTool(names)
    local char = getCharacter()
    local hum = getHumanoid()
    if not char or not hum then return nil end
    local lower = {}
    for _, n in ipairs(names) do lower[n:lower()] = true end
    for _, parent in ipairs({ char, LocalPlayer:FindFirstChild("Backpack") }) do
        if parent then
            for _, item in ipairs(parent:GetChildren()) do
                if item:IsA("Tool") and lower[item.Name:lower()] then
                    if item.Parent ~= char then
                        hum:EquipTool(item)
                    end
                    return item
                end
            end
        end
    end
    return nil
end

local function equipPunch()
    return equipTool({ "Punch" })
end

-- ========== Rock / Fast Punch ==========
local rockCache = {}
local capturedRock = nil

local function cacheRockCFrame(rock)
    if not rock or rockCache[rock] then return end
    local touch = rock:FindFirstChild("TouchPart")
    rockCache[rock] = {
        rockCFrame = rock.CFrame,
        touchCFrame = touch and touch:IsA("BasePart") and touch.CFrame or nil,
    }
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
        pcall(function()
            rock.CFrame = cached.rockCFrame
            local touch = rock:FindFirstChild("TouchPart")
            if touch and cached.touchCFrame then
                touch.CFrame = cached.touchCFrame
            end
        end)
    end
end

local function clearRockSession()
    State.rockGeneration = State.rockGeneration + 1
    State.selectedRock = nil
    State.rockSessionStartedAt = nil
    if capturedRock then
        restoreRock(capturedRock)
        capturedRock = nil
    end
end

local function findRockByDurability(dur)
    dur = tonumber(dur)
    if not dur and dur ~= 0 then return nil end
    local cached = rockCache[dur]
    if typeof(cached) == "Instance" and cached.Parent then
        return cached
    end
    local folder = workspace:FindFirstChild("machinesFolder")
    if not folder then return nil end
    for _, item in pairs(folder:GetDescendants()) do
        if item.Name == "neededDurability" and item:IsA("ValueBase") and tonumber(item.Value) == dur then
            local rock = item.Parent and item.Parent:FindFirstChild("Rock")
            if rock and rock:IsA("BasePart") then
                cacheRockCFrame(rock)
                rockCache[dur] = rock
                return rock
            end
        end
    end
    return nil
end

local function applyRockVisual(rock, hand)
    if not rock or not hand then return end
    cacheRockCFrame(rock)
    pcall(function()
        rock.Size = Vector3.new(2, 1, 1)
        rock.Transparency = 1
        rock.CanCollide = false
        if rock:FindFirstChild("rockGui") then
            for _, c in pairs(rock.rockGui:GetChildren()) do
                c.Visible = false
            end
        end
        for _, name in ipairs({ "rockEmitter", "hoopParticle", "lavaParticle" }) do
            if rock:FindFirstChild(name) then rock[name]:Destroy() end
        end
        rock.CFrame = hand.CFrame
        local touch = rock:FindFirstChild("TouchPart")
        if touch then touch.CFrame = hand.CFrame end
    end)
end

-- mesmo sistema do script original (Young0x / FG100)
local function attachRockToHand()
    local selected = State.selectedRock
    local gen = State.rockGeneration
    if not selected then return end
    local durability = LocalPlayer:FindFirstChild("Durability")
    if durability and tonumber(durability.Value) < selected.durability then return end
    local char = getCharacter()
    local left = char and char:FindFirstChild("LeftHand")
    local right = char and char:FindFirstChild("RightHand")
    if not left or not right then return end
    local rock = findRockByDurability(selected.durability)
    if not rock then return end
    if State.rockGeneration ~= gen or State.selectedRock ~= selected then return end
    if capturedRock ~= rock then
        if capturedRock then restoreRock(capturedRock) end
        if State.rockGeneration ~= gen or State.selectedRock ~= selected then return end
        capturedRock = rock
    end
    applyRockVisual(rock, left)
    if State.rockGeneration ~= gen or State.selectedRock ~= selected then return end
    if type(firetouchinterest) ~= "function" then return end
    -- sequência igual ao original (com checks de generation)
    pcall(firetouchinterest, rock, right, 0)
    if State.rockGeneration ~= gen or State.selectedRock ~= selected or capturedRock ~= rock then
        pcall(firetouchinterest, rock, right, 1)
        return
    end
    pcall(firetouchinterest, rock, right, 1)
    if State.rockGeneration ~= gen or State.selectedRock ~= selected or capturedRock ~= rock then
        return
    end
    pcall(firetouchinterest, rock, left, 0)
    if State.rockGeneration ~= gen or State.selectedRock ~= selected or capturedRock ~= rock then
        pcall(firetouchinterest, rock, left, 1)
        return
    end
    pcall(firetouchinterest, rock, left, 1)
    equipPunch()
end

-- ativo se Fast Punch OU alguma rock selecionada
local function punchSystemActive()
    return State.running and (State.fastPunch == true or State.selectedRock ~= nil)
end

local function stopPunchTasks()
    cancelTask("fastPunchEquip")
    cancelTask("fastPunchHit")
    cancelTask("fastPunchRock")
    pcall(function()
        local char = getCharacter()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local punch = (char and char:FindFirstChild("Punch"))
            or (backpack and backpack:FindFirstChild("Punch"))
        local at = punch and punch:FindFirstChild("attackTime")
        if at then at.Value = 0.3 end
    end)
end

local function startPunchTasks()
    cancelTask("fastPunchEquip")
    cancelTask("fastPunchHit")
    cancelTask("fastPunchRock")
    -- rocks: equipa tool; Fast Punch sozinho: só se já estiver equipado (evita lag)
    spawnTask("fastPunchEquip", function()
        while punchSystemActive() do
            if State.selectedRock then
                pcall(function()
                    local punch = equipPunch()
                    if punch then
                        local at = punch:FindFirstChild("attackTime")
                        if at then at.Value = 0 end
                    end
                end)
            end
            task.wait(0.05)
        end
    end)
    spawnTask("fastPunchHit", function()
        while punchSystemActive() do
            pcall(function()
                local char = getCharacter()
                local punch = char and char:FindFirstChild("Punch")
                -- Fast Punch puro: só funciona com tool já equipada
                if not punch and State.fastPunch and not State.selectedRock then
                    return
                end
                if punch then
                    local at = punch:FindFirstChild("attackTime")
                    if at then at.Value = 0 end
                    pcall(punch.Activate, punch)
                end
                local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                if muscleEvent then
                    muscleEvent:FireServer("punch", "rightHand")
                    muscleEvent:FireServer("punch", "leftHand")
                end
            end)
            task.wait(0.01)
        end
    end)
    spawnTask("fastPunchRock", function()
        while punchSystemActive() do
            if State.selectedRock then
                pcall(attachRockToHand)
                local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                if muscleEvent then
                    pcall(muscleEvent.FireServer, muscleEvent, "punch", "rightHand")
                    pcall(muscleEvent.FireServer, muscleEvent, "punch", "leftHand")
                end
            end
            task.wait()
        end
    end)
end

local function setFastPunch(enabled)
    State.fastPunch = enabled == true
    if not punchSystemActive() then
        if not State.fastPunch then
            clearRockSession()
        end
        stopPunchTasks()
        return
    end
    startPunchTasks()
end

local function setRockSelection(rockOrNil)
    if rockOrNil then
        clearRockSession()
        State.selectedRock = rockOrNil
        State.rockSessionStartedAt = serverTime()
        startPunchTasks()
        pcall(function()
            findRockByDurability(rockOrNil.durability)
            attachRockToHand()
            equipPunch()
        end)
    else
        clearRockSession()
        if not State.fastPunch then
            stopPunchTasks()
        end
    end
end

-- ========== Auto Rep / Exercise ==========
local repValueBackup = {}

local function zeroRepTime(key, tool)
    if not tool then return end
    local repTime = tool:FindFirstChild("repTime")
    if not repTime or not repTime:IsA("ValueBase") then return end
    repValueBackup[key] = repValueBackup[key] or {}
    if repValueBackup[key][repTime] == nil then
        repValueBackup[key][repTime] = repTime.Value
    end
    repTime.Value = 0
end

local function restoreRepTime(key)
    local data = repValueBackup[key]
    if not data then return end
    for val, original in pairs(data) do
        if val and val.Parent then
            pcall(function() val.Value = original end)
        end
    end
    repValueBackup[key] = nil
end

local function unequipTools(names)
    local char = getCharacter()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack or not names then return end
    local lower = {}
    for _, n in ipairs(names) do lower[n:lower()] = true end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and lower[item.Name:lower()] then
            pcall(function() item.Parent = backpack end)
        end
    end
end

local function setExercise(key, enabled, toolNames, delay)
    State[key] = enabled == true
    local em = State.exerciseMovement
    em.active[key] = State[key] or nil
    local taskName = "rep_" .. key
    if not State[key] then
        cancelTask(taskName)
        restoreRepTime(key)
        unequipTools(toolNames)
        local anyActive = false
        for _ in pairs(em.active) do anyActive = true break end
        if not anyActive then
            cancelTask("exerciseMovement")
            local hum = em.humanoid
            if hum and hum.Parent then
                pcall(function()
                    if not State.fastSpeed and em.walkSpeed then
                        hum.WalkSpeed = em.walkSpeed
                    end
                    if em.jumpValue then
                        if em.usesJumpPower then
                            hum.JumpPower = em.jumpValue
                        else
                            hum.JumpHeight = em.jumpValue
                        end
                    end
                end)
            end
            em.humanoid = nil
            em.walkSpeed = nil
            em.jumpValue = nil
        end
        return
    end
    local hum = getHumanoid()
    if hum and em.humanoid ~= hum then
        em.humanoid = hum
        em.walkSpeed = hum.WalkSpeed > 0 and hum.WalkSpeed or 16
        em.usesJumpPower = hum.UseJumpPower
        em.jumpValue = em.usesJumpPower and hum.JumpPower or hum.JumpHeight
    end
    spawnTask("exerciseMovement", function()
        while State.running and next(em.active) do
            local hum = getHumanoid()
            local hrp = getHRP()
            if hum then
                if em.humanoid ~= hum then
                    em.humanoid = hum
                    em.walkSpeed = hum.WalkSpeed > 0 and hum.WalkSpeed or 16
                    em.usesJumpPower = hum.UseJumpPower
                    em.jumpValue = em.usesJumpPower and hum.JumpPower or hum.JumpHeight
                end
                if not State.machine and not State.fly then
                    if hrp then hrp.Anchored = false end
                    hum.PlatformStand = false
                    hum.Sit = false
                    local ws = State.fastSpeed and 1000 or em.walkSpeed
                    if ws and hum.WalkSpeed < ws then hum.WalkSpeed = ws end
                    if em.jumpValue then
                        if em.usesJumpPower and hum.JumpPower < em.jumpValue then
                            hum.JumpPower = em.jumpValue
                        elseif not em.usesJumpPower and hum.JumpHeight < em.jumpValue then
                            hum.JumpHeight = em.jumpValue
                        end
                    end
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
    spawnTask(taskName, function()
        while State.running and State[key] do
            pcall(function()
                local tool
                if toolNames and #toolNames > 0 then
                    tool = equipTool(toolNames)
                    zeroRepTime(key, tool)
                end
                local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                if muscleEvent then
                    muscleEvent:FireServer("rep")
                end
                if tool then tool:Activate() end
            end)
            task.wait(delay or 0.01)
        end
    end)
end

-- ========== Auto Egg ==========
State.autoEggSources = { manual = false, fastFarm = false, rebirth = false }
State.autoEggNextAt = 0

local function eatProteinEgg()
    local char = getCharacter()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
    for _, parent in ipairs({ backpack, char, LocalPlayer:FindFirstChild("consumablesFolder") }) do
        if parent then
            for _, name in ipairs(Config.AutoEgg.Names) do
                local egg = parent:FindFirstChild(name)
                if egg then
                    pcall(function()
                        local remote = rEvents and rEvents:FindFirstChild("eatEvent")
                        if remote then remote:FireServer("eat", egg) end
                    end)
                    pcall(function()
                        if backpack and char and egg.Parent == backpack then
                            egg.Parent = char
                            task.wait(0.05)
                        end
                        if egg.Activate then egg:Activate() end
                    end)
                    return true
                end
            end
        end
    end
    return false
end

local function setAutoEgg(enabled, source)
    source = source or "manual"
    State.autoEggSources[source] = enabled == true
    local any = false
    for _, v in pairs(State.autoEggSources) do
        if v then any = true break end
    end
    if State.autoEgg == any then return end
    State.autoEgg = any
    if not any then
        cancelTask("autoEgg")
        return
    end
    spawnTask("autoEgg", function()
        while State.running and State.autoEgg do
            local now = time()
            if now >= State.autoEggNextAt then
                if eatProteinEgg() then
                    State.autoEggNextAt = now + Config.AutoEgg.Interval
                else
                    State.autoEggNextAt = now + 10
                end
            end
            task.wait(1)
        end
    end)
end

-- ========== Gamepass unlock (client-side) ==========
local gamepassUnlocked = false
local function unlockAutoLiftGamepass()
    local owned = LocalPlayer:FindFirstChild("ownedGamepasses")
    if not owned then
        owned = Instance.new("Folder")
        owned.Name = "ownedGamepasses"
        owned.Parent = LocalPlayer
    end
    local ids = ReplicatedStorage:FindFirstChild("gamepassIds")
    local added = 0
    if ids then
        for _, item in ipairs(ids:GetChildren()) do
            if item:IsA("ValueBase") and not owned:FindFirstChild(item.Name) then
                local iv = Instance.new("IntValue")
                iv.Name = item.Name
                iv.Value = tonumber(item.Value) or 0
                iv.Parent = owned
                added = added + 1
            end
        end
    end
    local fallbackNames = {
        "AutoLift", "Auto Lift", "autolift", "2xStrength", "2x Strength",
        "Infinity", "VIP", "FastRun", "Fast Run",
    }
    for _, name in ipairs(fallbackNames) do
        if not owned:FindFirstChild(name) then
            local iv = Instance.new("IntValue")
            iv.Name = name
            iv.Value = 1
            iv.Parent = owned
            added = added + 1
        end
    end
    for _, child in ipairs(LocalPlayer:GetChildren()) do
        if child:IsA("Folder") and child.Name:lower():find("gamepass", 1, true) and child ~= owned then
            for _, item in ipairs(child:GetChildren()) do
                if item:IsA("ValueBase") and not owned:FindFirstChild(item.Name) then
                    local iv = Instance.new(item.ClassName)
                    iv.Name = item.Name
                    pcall(function() iv.Value = item.Value end)
                    iv.Parent = owned
                    added = added + 1
                end
            end
        end
    end
    gamepassUnlocked = true
    return true
end

-- ========== Hide UI ==========
local durabilityHidden = {}
local framesHidden = {}
local durabilityConns = {}
local framesConn = nil

local function hideDurabilityObject(obj)
    if obj and obj:IsA("GuiObject") and obj.Name == "durabilityFrame" and durabilityHidden[obj] == nil then
        durabilityHidden[obj] = obj.Visible
        obj.Visible = false
    end
end

local function setHideDurability(enabled)
    State.hideDurability = enabled == true
    for _, c in ipairs(durabilityConns) do pcall(function() c:Disconnect() end) end
    table.clear(durabilityConns)
    if State.hideDurability then
        for _, item in ipairs(ReplicatedStorage:GetChildren()) do pcall(hideDurabilityObject, item) end
        for _, item in ipairs(PlayerGui:GetDescendants()) do pcall(hideDurabilityObject, item) end
        durabilityConns[#durabilityConns + 1] = ReplicatedStorage.ChildAdded:Connect(function(obj)
            if State.hideDurability then task.defer(hideDurabilityObject, obj) end
        end)
        durabilityConns[#durabilityConns + 1] = PlayerGui.DescendantAdded:Connect(function(obj)
            if State.hideDurability then task.defer(hideDurabilityObject, obj) end
        end)
    else
        for obj, vis in pairs(durabilityHidden) do
            if obj and obj.Parent then pcall(function() obj.Visible = vis end) end
        end
        table.clear(durabilityHidden)
    end
end

-- Hide Frames = statEffectsGui + frames antigos do ReplicatedStorage
local function hideFrameObject(obj)
    if obj and obj.Parent == ReplicatedStorage and obj:IsA("GuiObject") and obj.Name:lower():match("frame$") then
        if framesHidden[obj] == nil then
            framesHidden[obj] = obj.Visible
        end
        pcall(function() obj.Visible = false end)
    end
end

local function setHideFrames(enabled)
    State.hideFrames = enabled == true
    if framesConn then framesConn:Disconnect() framesConn = nil end
    cancelTask("hideFramesLoop")
    local function applyStatGui()
        local gui = PlayerGui:FindFirstChild("statEffectsGui")
        if not gui then return end
        if State.hideFrames then
            if framesHidden[gui] == nil then
                framesHidden[gui] = gui:IsA("ScreenGui") and gui.Enabled or (gui:IsA("GuiObject") and gui.Visible)
            end
            pcall(function()
                if gui:IsA("ScreenGui") then gui.Enabled = false end
                if gui:IsA("GuiObject") then gui.Visible = false end
            end)
        else
            local prev = framesHidden[gui]
            if prev ~= nil then
                pcall(function()
                    if gui:IsA("ScreenGui") then gui.Enabled = prev end
                    if gui:IsA("GuiObject") then gui.Visible = prev end
                end)
                framesHidden[gui] = nil
            end
        end
    end
    if State.hideFrames then
        for _, item in ipairs(ReplicatedStorage:GetChildren()) do
            pcall(hideFrameObject, item)
        end
        applyStatGui()
        framesConn = ReplicatedStorage.ChildAdded:Connect(function(obj)
            if State.hideFrames then task.defer(hideFrameObject, obj) end
        end)
        local pgConn
        pgConn = PlayerGui.ChildAdded:Connect(function(child)
            if State.hideFrames and child.Name == "statEffectsGui" then
                task.defer(applyStatGui)
            end
        end)
        -- guarda junto no framesConn via wrapper
        local oldDisc = framesConn
        framesConn = {
            Disconnect = function()
                pcall(function() oldDisc:Disconnect() end)
                pcall(function() pgConn:Disconnect() end)
            end,
        }
        spawnTask("hideFramesLoop", function()
            while State.running and State.hideFrames do
                applyStatGui()
                for _, item in ipairs(ReplicatedStorage:GetChildren()) do
                    pcall(hideFrameObject, item)
                end
                task.wait(0.5)
            end
        end)
    else
        for obj, vis in pairs(framesHidden) do
            if obj and obj.Parent then
                pcall(function()
                    if obj:IsA("ScreenGui") then
                        obj.Enabled = vis
                    elseif obj:IsA("GuiObject") then
                        obj.Visible = vis
                    end
                end)
            end
        end
        table.clear(framesHidden)
    end
end

-- Prevent Rebirth: esconde confirmButton do rebirthMenu
local function setPreventRebirth(enabled)
    State.preventRebirth = enabled == true
    cancelTask("preventRebirthLoop")
    local function apply()
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui") or PlayerGui
            local gameGui = pg and pg:FindFirstChild("gameGui")
            local menu = gameGui and gameGui:FindFirstChild("rebirthMenu")
            local btn = menu and menu:FindFirstChild("confirmButton")
            if btn then
                if State.preventRebirth then
                    if btn:IsA("GuiObject") then
                        btn.Visible = false
                        btn.Active = false
                    end
                    if btn:IsA("GuiButton") then
                        btn.AutoButtonColor = false
                    end
                else
                    if btn:IsA("GuiObject") then
                        btn.Visible = true
                        btn.Active = true
                    end
                end
            end
        end)
    end
    apply()
    if State.preventRebirth then
        spawnTask("preventRebirthLoop", function()
            while State.running and State.preventRebirth do
                apply()
                task.wait(0.25)
            end
        end)
    end
end

-- ========== Machines ==========
local machineGen = 0

local function pressE()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.045)
        vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

local function findMachineSeat(machine)
    local folder = workspace:FindFirstChild("machinesFolder")
    if not folder then return nil, nil end
    local obj = folder:FindFirstChild(machine.object)
    if not obj then
        -- fallback: search by partial name
        for _, child in ipairs(folder:GetChildren()) do
            if child.Name:lower():find((machine.object:lower():gsub("%s+", "")), 1, true)
                or child.Name:lower():find(machine.label and machine.label:lower() or "", 1, true) then
                obj = child
                break
            end
        end
    end
    if not obj then return nil, nil end
    local seat = obj:FindFirstChild("interactSeat", true)
        or obj:FindFirstChildWhichIsA("Seat", true)
        or obj:FindFirstChildWhichIsA("VehicleSeat", true)
    return obj, seat
end

local function interactMachineSeat(seat)
    if not seat then return end
    local events = getREvents and getREvents() or ReplicatedStorage:FindFirstChild("rEvents")
    local remote = events and events:FindFirstChild("machineInteractRemote")
    if remote then
        pcall(function()
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer("useMachine", seat)
            else
                remote:FireServer("useMachine", seat)
            end
        end)
    end
    -- caminho alternativo
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild("rEvents")
        local m = r and r:FindFirstChild("machineInteractRemote")
        if m then m:InvokeServer("useMachine", seat) end
    end)
end

local function useMachine(machine)
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return false end
    local obj, seat = findMachineSeat(machine)
    if seat and seat:IsA("BasePart") then
        hrp.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0)
    else
        hrp.CFrame = machine.fallback
    end
    task.wait(0.12)
    interactMachineSeat(seat)
    task.wait(0.08)
    pressE()
    task.wait(0.25)
    if seat and (not hum.SeatPart) then
        interactMachineSeat(seat)
        pressE()
    end
    return true
end

local function setMachine(machine, enabled)
    machineGen = machineGen + 1
    local gen = machineGen
    cancelTask("machine")
    cancelTask("machineRep")
    if not enabled then
        State.machine = nil
        local hum = getHumanoid()
        if hum and hum.SeatPart then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        return
    end
    State.machine = machine
    spawnTask("machine", function()
        useMachine(machine)
        while State.running and State.machine == machine and machineGen == gen do
            local hum = getHumanoid()
            local hrp = getHRP()
            local _, seat = findMachineSeat(machine)
            local need = not hum or not hum.SeatPart
            if seat and hrp and (hrp.Position - seat.Position).Magnitude > 14 then
                need = true
            end
            if need then useMachine(machine) end
            -- reps sem tool: muscleEvent "rep"
            pcall(function()
                local ev = LocalPlayer:FindFirstChild("muscleEvent")
                if ev then
                    for _ = 1, 8 do
                        ev:FireServer("rep")
                    end
                end
            end)
            task.wait(0.35)
        end
    end)
end

-- ========== Fast Farm ==========
local FastFarm = {
    generation = 0,
    mode = nil,
    startedAt = nil,
    startStats = nil,
    lockCFrame = nil,
    lockCharacter = nil,
    hideFramesOwned = false,
    packCount = 0,
    cachedPing = 0,
    pingCheckedAt = 0,
    pingPaused = false,
    resumeSamples = 0,
    strengthBatch = Config.FastFarm.StrengthStartBatch,
    lastBatchAdjust = 0,
    sizeInvokeBusy = false,
    lastSizeInvoke = 0,
    sizeReleaseGeneration = 0,
    frameReleaseGeneration = 0,
}

local function readStats()
    local function val(names)
        local s = getStat(names)
        return s and tonumber(s.Value) or 0, s
    end
    local r = val({ "Rebirths", "Rebirth" })
    local s = val({ "Strength", "Fuerza" })
    local d = val({ "Durability", "Resistencia" })
    return { rebirths = r, strength = s, durability = d }
end

local function getREvents()
    return ReplicatedStorage:FindFirstChild("rEvents")
        or ReplicatedStorage:FindFirstChild("REvents")
        or ReplicatedStorage:FindFirstChild("Events")
end

local function applySizeOrSpeed(kind, value)
    value = tonumber(value)
    if not value then return false end
    local okAny = false
    local events = getREvents()
    local candidates = {}
    local function add(rem)
        if not rem then return end
        for _, c in ipairs(candidates) do
            if c == rem then return end
        end
        candidates[#candidates + 1] = rem
    end
    if events then
        add(events:FindFirstChild("changeSpeedSizeRemote"))
        add(events:FindFirstChild("ChangeSpeedSizeRemote"))
        add(events:FindFirstChild("speedSizeRemote"))
        add(events:FindFirstChild("SizeSpeedRemote"))
    end
    add(ReplicatedStorage:FindFirstChild("changeSpeedSizeRemote", true))
    local keys = {
        kind,
        kind == "changeSize" and "changeSize" or "changeSpeed",
        kind == "changeSize" and "Size" or "Speed",
        kind == "changeSize" and "size" or "speed",
    }
    for _, remote in ipairs(candidates) do
        for _, key in ipairs(keys) do
            local ok = pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer(key, value)
                else
                    remote:FireServer(key, value)
                end
            end)
            if ok then okAny = true end
        end
    end
    return okAny
end

local function unequipAllPets()
    local events = getREvents()
    local equip = events and events:FindFirstChild("equipPetEvent")
    local folder = LocalPlayer:FindFirstChild("petsFolder")
    if not equip or not folder then return end
    for _, cat in ipairs(folder:GetChildren()) do
        if cat:IsA("Folder") then
            for _, pet in ipairs(cat:GetChildren()) do
                pcall(equip.FireServer, equip, "unequipPet", pet)
            end
        end
    end
    task.wait(0.035)
end

local function equipPetByName(name)
    local events = getREvents()
    local equip = events and events:FindFirstChild("equipPetEvent")
    local folder = LocalPlayer:FindFirstChild("petsFolder")
    if not equip or not folder then return 0 end
    local count = 0
    for _, cat in ipairs(folder:GetChildren()) do
        if cat:IsA("Folder") then
            for _, pet in ipairs(cat:GetChildren()) do
                if pet.Name == name then
                    pcall(equip.FireServer, equip, "equipPet", pet)
                    count = count + 1
                    if count >= Config.FastFarm.MaxPets then return count end
                end
            end
        end
    end
    return count
end

local function fireReps(count)
    local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
    if not muscleEvent then return false end
    for _ = 1, count or Config.FastFarm.RepsPerCycle do
        pcall(muscleEvent.FireServer, muscleEvent, "rep")
    end
    return true
end

local function adaptiveDelay(mode)
    local now = time()
    local refreshed = false
    if now - FastFarm.pingCheckedAt >= 0.25 then
        FastFarm.cachedPing = getPing()
        FastFarm.pingCheckedAt = now
        refreshed = true
    end
    local ping = FastFarm.cachedPing
    if not FastFarm.pingPaused and ping >= Config.FastFarm.PingPause then
        FastFarm.pingPaused = true
        FastFarm.resumeSamples = 0
        FastFarm.strengthBatch = Config.FastFarm.StrengthStartBatch
        FastFarm.lastBatchAdjust = now
    end
    if FastFarm.pingPaused then
        if refreshed then
            if ping <= Config.FastFarm.PingResume then
                FastFarm.resumeSamples = FastFarm.resumeSamples + 1
            else
                FastFarm.resumeSamples = 0
            end
            if FastFarm.resumeSamples >= 4 then
                FastFarm.pingPaused = false
                FastFarm.resumeSamples = 0
            end
        end
        if FastFarm.pingPaused then return 0.25, false end
    end
    if mode == "strength" then
        if refreshed then
            if ping >= Config.FastFarm.PingSoft and now - FastFarm.lastBatchAdjust >= 0.75 then
                FastFarm.strengthBatch = math.max(Config.FastFarm.StrengthStartBatch, FastFarm.strengthBatch - 4)
                FastFarm.lastBatchAdjust = now
            elseif ping <= Config.FastFarm.StrengthRampPing and now - FastFarm.lastBatchAdjust >= Config.FastFarm.StrengthRampInterval then
                FastFarm.strengthBatch = math.min(Config.FastFarm.StrengthMaxBatch, FastFarm.strengthBatch + 2)
                FastFarm.lastBatchAdjust = now
            end
        end
        if ping >= Config.FastFarm.PingCritical then
            fireReps(2) return 0.2, true
        elseif ping >= Config.FastFarm.PingHigh then
            fireReps(3) return 0.13, true
        elseif ping >= Config.FastFarm.PingMedium then
            fireReps(math.max(4, math.floor(FastFarm.strengthBatch * 0.3))) return 0.07, true
        elseif ping >= Config.FastFarm.PingSoft then
            fireReps(math.max(6, math.floor(FastFarm.strengthBatch * 0.5))) return 0.04, true
        end
        fireReps(FastFarm.strengthBatch)
        return Config.FastFarm.StrengthDelay, true
    end
    if ping >= Config.FastFarm.PingCritical then
        return 0.7, true
    elseif ping >= Config.FastFarm.PingHigh then
        fireReps(10) return 0.18, true
    elseif ping >= Config.FastFarm.PingMedium then
        fireReps(24) return 0.075, true
    elseif ping >= Config.FastFarm.PingSoft then
        fireReps(45) return 0.025, true
    end
    fireReps(Config.FastFarm.RepsPerCycle)
    return Config.FastFarm.RepDelay, true
end

local function goldenRebirthLevel()
    local folder = LocalPlayer:FindFirstChild("ultimatesFolder")
    local gr = folder and folder:FindFirstChild("Golden Rebirth")
    return gr and tonumber(gr.Value) or 0
end

local function strengthNeeded(rebirths)
    local sum = 10000 + 5000 * (tonumber(rebirths) or 0)
    local gr = goldenRebirthLevel()
    if gr >= 1 and gr <= 5 then
        sum = sum * (1 - gr * 0.1)
    end
    return math.floor(sum)
end

local function requestRebirth()
    local events = getREvents()
    local names = { "rebirthRemote", "RebirthRemote", "rebirthEvent", "RebirthEvent" }
    for _, n in ipairs(names) do
        local remote = events and events:FindFirstChild(n)
        if remote then
            pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer("rebirthRequest")
                    remote:InvokeServer("rebirth")
                else
                    remote:FireServer("rebirthRequest")
                    remote:FireServer("rebirth")
                end
            end)
        end
    end
    -- tenta clicar confirm se menu aberto (quando não prevent)
    if not State.preventRebirth then
        pcall(function()
            local pg = PlayerGui
            local btn = pg and pg:FindFirstChild("gameGui")
            btn = btn and btn:FindFirstChild("rebirthMenu")
            btn = btn and btn:FindFirstChild("confirmButton")
            if btn and btn:IsA("GuiButton") and btn.Visible then
                firesignal(btn.MouseButton1Click)
            end
        end)
    end
end

local function setSizeOne()
    local hum = getHumanoid()
    if not hum then return end
    for _, name in ipairs({ "BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale" }) do
        local scale = hum:FindFirstChild(name)
        if scale and scale:IsA("NumberValue") then
            pcall(function() scale.Value = 1 end)
        end
    end
    local now = time()
    if FastFarm.sizeInvokeBusy or now - FastFarm.lastSizeInvoke < Config.FastFarm.SizeInvokeInterval then
        return
    end
    local events = getREvents()
    local remote = events and events:FindFirstChild("changeSpeedSizeRemote")
    if remote then
        FastFarm.sizeInvokeBusy = true
        FastFarm.lastSizeInvoke = now
        task.spawn(function()
            applySizeOrSpeed("changeSize", 1)
            FastFarm.sizeInvokeBusy = false
        end)
    end
end

local function hitFarmRock()
    setSizeOne()
    local rock = workspace:FindFirstChild(Config.FastFarm.RockName)
    local hrp = getHRP()
    local events = getREvents()
    local hitEvent = events and events:FindFirstChild("hitEvent")
    if rock and hrp and hitEvent then
        pcall(function()
            hrp.CFrame = rock.CFrame * CFrame.new(0, 0, -5)
            hitEvent:FireServer("hit", rock)
        end)
        task.delay(0.08, setSizeOne)
    end
end

local function findMachine(objectName)
    for _, m in ipairs(Config.Machines) do
        if m.object == objectName then return m end
    end
    return nil
end

local function lockLiftSeat(gen)
    local machine = findMachine("Jungle Bar Lift")
    if not machine then return false end
    for _ = 1, 3 do
        if FastFarm.generation ~= gen or FastFarm.mode ~= "rebirth" then return false end
        useMachine(machine)
        local deadline = time() + 1.4
        repeat
            local hum = getHumanoid()
            if hum and hum.SeatPart then
                local hrp = getHRP()
                if hrp then
                    FastFarm.lockCharacter = getCharacter()
                    FastFarm.lockCFrame = hrp.CFrame
                    return true
                end
            end
            task.wait(0.08)
        until time() >= deadline
    end
    local hrp = getHRP()
    if hrp and (hrp.Position - machine.fallback.Position).Magnitude <= 20 then
        FastFarm.lockCharacter = getCharacter()
        FastFarm.lockCFrame = hrp.CFrame
        return true
    end
    return false
end

function FastFarm:Stop(releaseFrames)
    local wasActive = self.mode ~= nil
    self.generation = self.generation + 1
    self.mode = nil
    State.fastFarmMode = nil
    self.lockCFrame = nil
    self.lockCharacter = nil
    self.startedAt = nil
    self.startStats = nil
    for _, name in ipairs({ "fastFarmSize", "fastFarmLock", "fastFarmMachine", "fastFarmRebirth", "fastFarmStrength" }) do
        cancelTask(name)
    end
    local hum = getHumanoid()
    if hum and hum.SeatPart then
        hum.Sit = false
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    if wasActive then
        FastFarm.sizeReleaseGeneration = FastFarm.sizeReleaseGeneration + 1
        local gen = FastFarm.sizeReleaseGeneration
        task.spawn(function()
            local until_ = time() + Config.FastFarm.SizeReleaseDuration
            while State.running and FastFarm.mode == nil and FastFarm.sizeReleaseGeneration == gen and time() < until_ do
                setSizeOne()
                task.wait(0.1)
            end
        end)
        setAutoEgg(false, "fastFarm")
    end
    if releaseFrames and self.hideFramesOwned then
        self.frameReleaseGeneration = self.frameReleaseGeneration + 1
        local gen = self.frameReleaseGeneration
        task.delay(Config.FastFarm.FramesReleaseDuration, function()
            if State.running and self.mode == nil and self.frameReleaseGeneration == gen and self.hideFramesOwned then
                setHideFrames(false)
                self.hideFramesOwned = false
            end
        end)
    end
end

function FastFarm:Start(mode)
    if mode ~= "rebirth" and mode ~= "strength" then return false end
    if self.mode == mode then return true end
    self:Stop(false)
    self.frameReleaseGeneration = self.frameReleaseGeneration + 1
    self.sizeReleaseGeneration = self.sizeReleaseGeneration + 1
    self.mode = mode
    State.fastFarmMode = mode
    self.generation = self.generation + 1
    local gen = self.generation
    self.startedAt = mode == "rebirth" and serverTime() or nil
    self.startStats = mode == "rebirth" and readStats() or nil
    self.packCount = 0
    self.cachedPing = getPing()
    self.pingCheckedAt = time()
    self.pingPaused = false
    self.resumeSamples = 0
    self.strengthBatch = Config.FastFarm.StrengthStartBatch
    self.lastBatchAdjust = time()
    if not State.hideFrames then
        self.hideFramesOwned = true
        setHideFrames(true)
    end
    setAutoEgg(true, "fastFarm")
    setSizeOne()
    spawnTask("fastFarmSize", function()
        while State.running and self.mode == mode and self.generation == gen do
            setSizeOne()
            task.wait(0.1)
        end
    end)
    if mode == "rebirth" then
        spawnTask("fastFarmLock", function()
            while State.running and self.mode == mode and self.generation == gen do
                local hrp = getHRP()
                if hrp and self.lockCFrame and self.lockCharacter == getCharacter() then
                    hrp.CFrame = self.lockCFrame
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
                RunService.Heartbeat:Wait()
            end
        end)
        spawnTask("fastFarmMachine", function()
            while State.running and self.mode == mode and self.generation == gen do
                if not self.lockCFrame or self.lockCharacter ~= getCharacter() then
                    self.lockCFrame = nil
                    lockLiftSeat(gen)
                end
                task.wait(0.8)
            end
        end)
        spawnTask("fastFarmRebirth", function()
            while self.mode == mode and self.generation == gen and not self.lockCFrame do
                task.wait(0.1)
            end
            while State.running and self.mode == mode and self.generation == gen do
                while self.mode == mode and self.generation == gen and not self.lockCFrame do
                    task.wait(0.1)
                end
                if self.mode ~= mode or self.generation ~= gen then break end
                local cycleStart = time()
                local rebirths, rebirthStat = (function()
                    local s = getStat({ "Rebirths", "Rebirth" })
                    return s and tonumber(s.Value) or 0, s
                end)()
                local strength, strengthStat = (function()
                    local s = getStat({ "Strength", "Fuerza" })
                    return s and tonumber(s.Value) or 0, s
                end)()
                local needed = strengthNeeded(rebirths)
                unequipAllPets()
                self.packCount = equipPetByName(Config.FastFarm.StrengthPet)
                while State.running and self.mode == mode and self.generation == gen
                    and strengthStat and tonumber(strengthStat.Value) < needed do
                    local delay = adaptiveDelay("rebirth")
                    task.wait(delay)
                end
                if self.mode == mode and self.generation == gen then
                    unequipAllPets()
                    self.packCount = equipPetByName(Config.FastFarm.RebirthPet)
                    local before = rebirthStat and tonumber(rebirthStat.Value) or rebirths
                    local windowStart = time()
                    repeat
                        requestRebirth()
                        task.wait(0.025)
                    until self.mode ~= mode or self.generation ~= gen
                        or (rebirthStat and tonumber(rebirthStat.Value) > before)
                        or time() - windowStart >= Config.FastFarm.RebirthRequestWindow
                end
                local remain = Config.FastFarm.RebirthCycleDelay - (time() - cycleStart)
                task.wait(math.max(remain, 0))
            end
        end)
    else
        spawnTask("fastFarmStrength", function()
            setSizeOne()
            task.wait(0.3)
            unequipAllPets()
            self.packCount = equipPetByName(Config.FastFarm.StrengthPet)
            local startStats = readStats()
            local bench = findMachine("Jungle Bench")
            if bench then
                useMachine(bench)
                setSizeOne()
            end
            local lastRock = 0
            local lastCheck = 0
            local lastMachine = time()
            local lastChar = getCharacter()
            while State.running and self.mode == mode and self.generation == gen do
                if lastChar ~= getCharacter() then
                    lastChar = getCharacter()
                    self.startedAt = nil
                    self.startStats = nil
                    setSizeOne()
                    task.wait(0.3)
                    unequipAllPets()
                    self.packCount = equipPetByName(Config.FastFarm.StrengthPet)
                    startStats = readStats()
                    if bench then
                        useMachine(bench)
                        setSizeOne()
                        lastMachine = time()
                    end
                end
                if not self.startedAt and bench and time() - lastMachine >= 3.2 then
                    setSizeOne()
                    useMachine(bench)
                    setSizeOne()
                    lastMachine = time()
                end
                local delay, ok = adaptiveDelay("strength")
                if ok and time() - lastRock >= Config.FastFarm.RockInterval then
                    hitFarmRock()
                    lastRock = time()
                end
                if not self.startedAt and time() - lastCheck >= 0.15 then
                    lastCheck = time()
                    local current = readStats()
                    if current.strength > startStats.strength then
                        self.startedAt = serverTime()
                        self.startStats = startStats
                    end
                end
                task.wait(delay)
            end
        end)
    end
    return true
end

-- ========== Anti Lag ==========
local antiLagBackup = {}
local antiLagConn = nil
local effectBackup = nil
local qualityBackup = nil

local function backupProp(obj, prop)
    antiLagBackup[obj] = antiLagBackup[obj] or {}
    if antiLagBackup[obj][prop] == nil then
        local ok, val = pcall(function() return obj[prop] end)
        if ok then antiLagBackup[obj][prop] = val end
    end
end

local function setProp(obj, prop, val)
    backupProp(obj, prop)
    pcall(function() obj[prop] = val end)
end

local function optimizeObject(obj)
    if obj:IsA("BasePart") then
        setProp(obj, "Material", Enum.Material.SmoothPlastic)
        setProp(obj, "Reflectance", 0)
        setProp(obj, "CastShadow", false)
        if obj:IsA("MeshPart") then setProp(obj, "TextureID", "") end
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        setProp(obj, "Transparency", 1)
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
        or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
        setProp(obj, "Enabled", false)
    elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
        setProp(obj, "Enabled", false)
    elseif obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") then
        setProp(obj, "Enabled", false)
    elseif obj:IsA("Explosion") then
        setProp(obj, "BlastPressure", 0)
        setProp(obj, "BlastRadius", 0)
    end
end

local function restoreAntiLag(gen, yield)
    local count = 0
    for obj, props in pairs(antiLagBackup) do
        if State.antiLagGeneration ~= gen then return false end
        if obj and obj.Parent then
            for prop, val in pairs(props) do
                pcall(function() obj[prop] = val end)
            end
        end
        count = count + 1
        if yield and count % 260 == 0 then RunService.Heartbeat:Wait() end
    end
    antiLagBackup = {}
    if effectBackup then
        Lighting.GlobalShadows = effectBackup.GlobalShadows
        Lighting.FogEnd = effectBackup.FogEnd
        Lighting.Brightness = effectBackup.Brightness
    end
    pcall(function()
        if qualityBackup then settings().Rendering.QualityLevel = qualityBackup end
    end)
    return true
end

local function setAntiLag(enabled)
    State.antiLag = enabled == true
    State.antiLagGeneration = State.antiLagGeneration + 1
    local gen = State.antiLagGeneration
    cancelTask("antiLag")
    if antiLagConn then antiLagConn:Disconnect() antiLagConn = nil end
    if State.antiLag then
        effectBackup = effectBackup or {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            Brightness = Lighting.Brightness,
        }
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e9
        Lighting.Brightness = 0
        pcall(function()
            qualityBackup = qualityBackup or settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            setProp(terrain, "WaterWaveSize", 0)
            setProp(terrain, "WaterWaveSpeed", 0)
            setProp(terrain, "WaterReflectance", 0)
            setProp(terrain, "WaterTransparency", 1)
        end
        antiLagConn = workspace.DescendantAdded:Connect(function(obj)
            if State.antiLag then task.defer(function() pcall(optimizeObject, obj) end) end
        end)
        spawnTask("antiLag", function()
            local queue = { workspace, Lighting }
            local i = 1
            local count = 0
            while i <= #queue and State.running and State.antiLag and State.antiLagGeneration == gen do
                local container = queue[i]
                i = i + 1
                local ok, children = pcall(function() return container:GetChildren() end)
                if ok then
                    for _, child in ipairs(children) do
                        queue[#queue + 1] = child
                        pcall(optimizeObject, child)
                        count = count + 1
                        if count % 260 == 0 then RunService.Heartbeat:Wait() end
                    end
                end
            end
        end)
    else
        spawnTask("antiLag", function()
            restoreAntiLag(gen, true)
        end)
    end
end

-- ========== Walk on Water ==========
local waterParts = {}
local function setWalkWater(enabled)
    State.walkWater = enabled == true
    for _, p in ipairs(waterParts) do
        if p and p.Parent then p:Destroy() end
    end
    table.clear(waterParts)
    if not State.walkWater then return end
    local origin = Vector3.new(-3072, -9.5, -3072)
    for x = -4, 4 do
        for z = -4, 4 do
            local part = Instance.new("Part")
            part.Name = "WaterFloor"
            part.Size = Vector3.new(2048, 1, 2048)
            part.Position = origin + Vector3.new(x * 2048, 0, z * 2048)
            part.Anchored = true
            part.CanCollide = true
            part.Transparency = 1
            part.CastShadow = false
            part.Parent = workspace
            waterParts[#waterParts + 1] = part
        end
        RunService.Heartbeat:Wait()
    end
end

-- ========== Fortune Wheel / Chests ==========
local function findRemote(parent, names)
    if not parent then return nil end
    for _, n in ipairs(names) do
        local r = parent:FindFirstChild(n)
        if r then return r end
    end
    for _, child in ipairs(parent:GetChildren()) do
        local lower = child.Name:lower()
        for _, n in ipairs(names) do
            if lower:find(n:lower(), 1, true) then return child end
        end
    end
    return nil
end

local function invokeOrFire(remote, ...)
    if not remote then return false end
    if remote:IsA("RemoteFunction") then
        return pcall(remote.InvokeServer, remote, ...)
    end
    return pcall(remote.FireServer, remote, ...)
end

local function getFortuneSpinAmount()
    local amount = nil
    pcall(function()
        local label = nil
        -- caminho principal
        local gui = PlayerGui:FindFirstChild("fortuneWheelMenuGui")
            or PlayerGui:FindFirstChild("FortuneWheelMenuGui")
        if gui then
            label = gui:FindFirstChild("spinAmountLabel", true)
        end
        -- busca em todo PlayerGui se não achou
        if not label then
            for _, d in ipairs(PlayerGui:GetDescendants()) do
                if d.Name == "spinAmountLabel" and (d:IsA("TextLabel") or d:IsA("TextBox") or d:IsA("TextButton")) then
                    label = d
                    break
                end
            end
        end
        if not label then
            amount = nil -- desconhecido
            return
        end
        local text = tostring(label.Text or label.ContentText or "")
        text = text:gsub(",", ""):gsub("%s+", " ")
        if text:lower():find("inf", 1, true) or text:find("∞") or text:find("unlimited", 1, true) then
            amount = math.huge
            return
        end
        -- pega o primeiro número (ex: "You have 3 spins" ou só "3")
        local n = tonumber(text:match("(-?%d+%.?%d*)"))
        amount = n or 0
    end)
    return amount
end

local function doFortuneSpin()
    local ok = false
    -- path do script novo (shared.catalogs)
    pcall(function()
        local Event = ReplicatedStorage.rEvents.openFortuneWheelRemote
        local arg = ReplicatedStorage.shared.catalogs.fortuneWheelChances["Fortune Wheel"]
        Event:InvokeServer("openFortuneWheel", arg)
        ok = true
    end)
    if not ok then
        pcall(function()
            local Event = ReplicatedStorage.rEvents.openFortuneWheelRemote
            local chances = ReplicatedStorage:FindFirstChild("fortuneWheelChances")
                or (ReplicatedStorage:FindFirstChild("shared")
                    and ReplicatedStorage.shared:FindFirstChild("catalogs")
                    and ReplicatedStorage.shared.catalogs:FindFirstChild("fortuneWheelChances"))
            local wheel = chances and chances:FindFirstChild("Fortune Wheel")
            if Event and wheel then
                Event:InvokeServer("openFortuneWheel", wheel)
                ok = true
            end
        end)
    end
    return ok
end

local function setAutoSpinWheel(enabled)
    State.autoSpinWheel = enabled == true
    if not State.autoSpinWheel then
        cancelTask("fortuneWheel")
        return
    end
    spawnTask("fortuneWheel", function()
        while State.running and State.autoSpinWheel do
            pcall(function()
                local wheelGui = PlayerGui:FindFirstChild("fortuneWheelMenuGui")
                local spinsLeft = 0
                if wheelGui then
                    local spinLabel = nil
                    pcall(function()
                        spinLabel = wheelGui.fortuneMenu.youHaveLabel.spinAmountLabel
                    end)
                    if not spinLabel then
                        spinLabel = wheelGui:FindFirstChild("spinAmountLabel", true)
                    end
                    if spinLabel and spinLabel.Text then
                        local text = tostring(spinLabel.Text)
                        if text:lower():find("inf", 1, true) or text:find("∞") then
                            spinsLeft = math.huge
                        else
                            local numStr = string.match(text, "%d+")
                            spinsLeft = tonumber(numStr) or 0
                        end
                    end
                else
                    -- gui fechada: ainda tenta se getFortuneSpinAmount achar algo
                    local s = getFortuneSpinAmount()
                    spinsLeft = (s == nil and 0) or s
                end
                if spinsLeft >= 1 then
                    doFortuneSpin()
                end
            end)
            task.wait(1.5)
        end
    end)
end

-- Auto Eat Protein (só verifica se existe; não equipa)
local PROTEIN_ITEMS = {
    { tool = "TOUGH Bar", event = "toughBar" },
    { tool = "ULTRA Shake", event = "ultraShake" },
    { tool = "Energy Shake", event = "energyShake" },
    { tool = "Protein Shake", event = "proteinShake" },
    { tool = "Energy Bar", event = "energyBar" },
    { tool = "Protein Bar", event = "proteinBar" },
}

local function findProteinTool(name)
    local char = getCharacter()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if char then
        local t = char:FindFirstChild(name)
        if t and t:IsA("Tool") then return t end
    end
    if backpack then
        local t = backpack:FindFirstChild(name)
        if t and t:IsA("Tool") then return t end
    end
    return nil
end

local function setAutoEatProtein(enabled)
    State.autoEatProtein = enabled == true
    cancelTask("autoEatProtein")
    if not State.autoEatProtein then return end
    spawnTask("autoEatProtein", function()
        while State.running and State.autoEatProtein do
            pcall(function()
                local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                if not muscleEvent then return end
                for _, def in ipairs(PROTEIN_ITEMS) do
                    local tool = findProteinTool(def.tool)
                    -- só fire se o item existir (não equipa, não spamma se não tiver)
                    if tool then
                        muscleEvent:FireServer(def.event, tool)
                    end
                end
            end)
            task.wait(0.28)
        end
    end)
end

local chestNames = {
    "Magma Chest", "Mythical Chest", "Golden Chest", "Enchanted Chest", "Legends Chest",
}
local function setAutoClaimChests(enabled)
    State.autoClaimChests = enabled == true
    if not State.autoClaimChests then
        cancelTask("autoClaimChests")
        return
    end
    spawnTask("autoClaimChests", function()
        while State.running and State.autoClaimChests do
            pcall(function()
                local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
                local remote = rEvents and rEvents:FindFirstChild("checkChestRemote")
                if remote then
                    for _, name in ipairs(chestNames) do
                        if not State.running or not State.autoClaimChests then break end
                        pcall(function()
                            if remote:IsA("RemoteFunction") then
                                remote:InvokeServer(name)
                            else
                                remote:FireServer(name)
                            end
                        end)
                        task.wait(0.15)
                    end
                end
            end)
            task.wait(15)
        end
    end)
end

-- ========== Remove Portals ==========
local removedPortals = {}
local portalConn = nil
local function onPortalAdded(obj)
    if obj and obj.Name == "RobloxForwardPortals" and obj.Parent then
        removedPortals[#removedPortals + 1] = { object = obj, parent = obj.Parent }
        obj.Parent = nil
    end
end


-- Mute punchSound de outros players (mantém o seu)
local punchSoundConns = {}
local function isUnderLocalCharacter(inst)
    local char = getCharacter()
    if not char or not inst then return false end
    return inst:IsDescendantOf(char)
end

local function muteForeignPunchSound(obj)
    if not obj or not obj:IsA("Sound") then return end
    local name = obj.Name:lower()
    local isPunch = name == "punchsound" or name:find("punch", 1, true)
    if not isPunch then
        -- também pelo asset path
        local ok = pcall(function()
            local shared = ReplicatedStorage:FindFirstChild("shared")
            local assets = shared and shared:FindFirstChild("assets")
            local sounds = assets and assets:FindFirstChild("sounds")
            local tpl = sounds and sounds:FindFirstChild("punchSound")
            if tpl and obj.SoundId == tpl.SoundId then
                isPunch = true
            end
        end)
    end
    if not isPunch then return end
    if isUnderLocalCharacter(obj) then return end
    -- se estiver em outro character / workspace geral
    local model = obj:FindFirstAncestorOfClass("Model")
    local plr = model and Players:GetPlayerFromCharacter(model)
    if plr == LocalPlayer then return end
    pcall(function()
        obj.Volume = 0
        obj.Playing = false
        obj:Stop()
    end)
end

local function startMuteOtherPunchSounds()
    for _, c in ipairs(punchSoundConns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(punchSoundConns)
    punchSoundConns[#punchSoundConns + 1] = workspace.DescendantAdded:Connect(function(obj)
        task.defer(muteForeignPunchSound, obj)
    end)
    -- varredura inicial
    for _, obj in ipairs(workspace:GetDescendants()) do
        muteForeignPunchSound(obj)
    end
    -- monitora sons que começam a tocar
    spawnTask("mutePunchLoop", function()
        while State.running do
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Sound") and obj.Playing then
                        muteForeignPunchSound(obj)
                    end
                end
            end)
            task.wait(0.4)
        end
    end)
end

-- sobrescreve volume do template compartilhado para clones de outros (não remove o seu)
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    local assets = shared and shared:FindFirstChild("assets")
    local sounds = assets and assets:FindFirstChild("sounds")
    local punchSound = sounds and sounds:FindFirstChild("punchSound")
    if punchSound and punchSound:IsA("Sound") then
        -- não zera o template global; só muta instâncias de terceiros
    end
end)

task.defer(startMuteOtherPunchSounds)

local function setRemovePortals(enabled)
    State.removePortals = enabled == true
    cancelTask("removePortals")
    if portalConn then portalConn:Disconnect() portalConn = nil end
    if not State.removePortals then
        for _, entry in ipairs(removedPortals) do
            if entry.object and not entry.object.Parent then
                pcall(function()
                    entry.object.Parent = entry.parent and entry.parent.Parent and entry.parent or workspace
                end)
            end
        end
        table.clear(removedPortals)
        return
    end
    portalConn = game.DescendantAdded:Connect(onPortalAdded)
    spawnTask("removePortals", function()
        local queue = { workspace }
        local i = 1
        local count = 0
        while i <= #queue and State.running and State.removePortals do
            local container = queue[i]
            i = i + 1
            local ok, children = pcall(function() return container:GetChildren() end)
            if ok then
                for _, child in ipairs(children) do
                    queue[#queue + 1] = child
                    onPortalAdded(child)
                    count = count + 1
                    if count % 300 == 0 then RunService.Heartbeat:Wait() end
                end
            end
        end
    end)
end

-- ========== Movement: Fast Speed / Fly / Noclip / Spin / Anti Knockback ==========
local savedWalkSpeed = nil
local bodyGyro, bodyVelocity = nil, nil
local flyUp, flyDown = false, false
local noclipBackup = {}
local noclipConn = nil
local spinAngular = nil
local spinHum = nil
local spinAutoRotate = true

local function updateWalkSpeed()
    local hum = getHumanoid()
    if not hum then return end
    if State.fastSpeed then
        hum.WalkSpeed = 1000
    elseif savedWalkSpeed ~= nil then
        hum.WalkSpeed = savedWalkSpeed
    end
end

-- Fast Speed do script original (usado no toggle Anti Stun)
local function setFastSpeed(enabled)
    local hum = getHumanoid()
    if enabled and hum and not State.fastSpeed then
        savedWalkSpeed = hum.WalkSpeed
    end
    local was = State.fastSpeed
    State.fastSpeed = enabled == true
    if State.fastSpeed or was then
        updateWalkSpeed()
    end
    if was and not State.fastSpeed then
        savedWalkSpeed = nil
    end
end

-- mantém WalkSpeed forçado enquanto ativo (igual original Heartbeat)
cancelTask("fastSpeedLoop")
spawnTask("fastSpeedLoop", function()
    while State.running do
        if State.fastSpeed then
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = 1000
            end
        end
        RunService.Heartbeat:Wait()
    end
end)

local function clearFly()
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end

local function setFly(enabled)
    State.fly = enabled == true
    if not State.fly then clearFly() end
end

local function restoreNoclip()
    for part, canCollide in pairs(noclipBackup) do
        if part and part.Parent then
            pcall(function() part.CanCollide = canCollide end)
        end
    end
    table.clear(noclipBackup)
end

local function setNoclip(enabled)
    State.noclip = enabled == true
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if State.noclip then
        noclipConn = RunService.Stepped:Connect(function()
            if not State.running or not State.noclip then return end
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if noclipBackup[part] == nil then
                            noclipBackup[part] = part.CanCollide
                        end
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        restoreNoclip()
    end
end

local function clearSpin()
    if spinAngular then
        local parent = spinAngular.Parent
        if parent and parent:IsA("BasePart") then
            parent.AssemblyAngularVelocity = Vector3.zero
        end
        spinAngular:Destroy()
        spinAngular = nil
    end
    if spinHum and spinHum.Parent then
        spinHum.AutoRotate = spinAutoRotate
    end
    spinHum = nil
end

local function setSpin(enabled)
    State.spin = enabled == true
    if not State.spin then clearSpin() end
end

State.clearAntiKnockback = function()
    if State.antiKnockbackVelocity then
        State.antiKnockbackVelocity:Destroy()
        State.antiKnockbackVelocity = nil
    end
end

-- Anti Stun usa este anti-knockback
State.setAntiKnockback = function(enabled)
    State.antiKnockback = enabled == true
    if not State.antiKnockback then State.clearAntiKnockback() end
end

local function setSpy(enabled)
    State.spy = enabled == true
    if not State.spy then
        local hum = getHumanoid()
        if workspace.CurrentCamera and hum then
            workspace.CurrentCamera.CameraSubject = hum
        end
    end
end

-- ========== Kills ==========
local function isFriend(player)
    local lower = (tostring(player and player.DisplayName or "")):lower()
    if lower:find("0x", 1, true) then return true end
    if not State.kill.protectFriends then return false end
    local cached = State.kill.friendCache[player.UserId]
    if cached ~= nil then return cached end
    local ok, result = pcall(LocalPlayer.IsFriendsWith, LocalPlayer, player.UserId)
    if ok then
        State.kill.friendCache[player.UserId] = result == true
    else
        State.kill.friendCache[player.UserId] = true
    end
    return State.kill.friendCache[player.UserId]
end

local function punchPlayer(player)
    if not player or player == LocalPlayer or isFriend(player) then return false end
    local char = player.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not hrp then return false end
    local myChar = getCharacter()
    local myHum = getHumanoid()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not myChar or not myHum then return false end
    local punch = myChar:FindFirstChild("Punch") or (backpack and backpack:FindFirstChild("Punch"))
    if punch and punch.Parent == backpack then myHum:EquipTool(punch) end
    local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
    if muscleEvent then
        pcall(muscleEvent.FireServer, muscleEvent, "punch", "leftHand")
        pcall(muscleEvent.FireServer, muscleEvent, "punch", "rightHand")
    end
    if type(firetouchinterest) ~= "function" then return false end
    local hand = myChar:FindFirstChild("LeftHand") or myChar:FindFirstChild("Left Arm")
        or myChar:FindFirstChild("RightHand") or myChar:FindFirstChild("Right Arm")
    if not hand then return false end
    local cf = hrp.CFrame
    local lin = hrp.AssemblyLinearVelocity
    local ang = hrp.AssemblyAngularVelocity
    local function restore()
        if hrp and hrp.Parent then
            hrp.CFrame = cf
            hrp.AssemblyLinearVelocity = lin
            hrp.AssemblyAngularVelocity = ang
        end
    end
    pcall(firetouchinterest, hrp, hand, 0)
    pcall(restore)
    pcall(firetouchinterest, hrp, hand, 1)
    pcall(restore)
    return true
end

local function findPlayerKarma(player)
    if not player then return 0, 0 end
    local containers = {
        player:FindFirstChild("leaderstats"),
        player:FindFirstChild("stats"),
        player:FindFirstChild("Stats"),
        player,
    }
    local good, evil = nil, nil
    local goodNames = { goodkarma = true, ["good karma"] = true, good = true }
    local evilNames = { evilkarma = true, ["evil karma"] = true, evil = true }
    for _, container in ipairs(containers) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("ValueBase") then
                    local key = (child.Name:lower()):gsub("%s+", " ")
                    local compact = key:gsub("%s+", "")
                    if not good and (goodNames[key] or goodNames[compact] or compact:find("goodkarma", 1, true)) then
                        good = child
                    elseif not evil and (evilNames[key] or evilNames[compact] or compact:find("evilkarma", 1, true)) then
                        evil = child
                    end
                end
            end
        end
        if good and evil then break end
    end
    -- busca profunda se ainda não achou
    if not good or not evil then
        for _, child in ipairs(player:GetDescendants()) do
            if child:IsA("ValueBase") then
                local compact = (child.Name:lower()):gsub("%s+", "")
                if not good and compact:find("goodkarma", 1, true) then
                    good = child
                elseif not evil and compact:find("evilkarma", 1, true) then
                    evil = child
                end
            end
            if good and evil then break end
        end
    end
    return tonumber(good and good.Value) or 0, tonumber(evil and evil.Value) or 0
end

local function karmaMatch(player, mode)
    if not mode then return true end
    if not player or player == LocalPlayer then return false end
    local g, e = findPlayerKarma(player)
    -- Evil farm: alvos com mais Good Karma (ganha Evil)
    -- Good farm: alvos com mais Evil Karma (ganha Good)
    if mode == "evil" then
        return g > e or (g > 0 and g >= e)
    end
    if mode == "good" then
        return e > g or (e > 0 and e >= g)
    end
    return false
end

local function killActive()
    return State.kill.auto or State.kill.karmaMode ~= nil
end

local function runKillLoop()
    cancelTask("killFarm")
    if not killActive() and not State.kill.targetMode then
        return
    end
    spawnTask("killFarm", function()
        while State.running and (killActive() or State.kill.targetMode) do
            if State.kill.targetMode then
                punchPlayer(State.kill.target and Players:FindFirstChild(State.kill.target))
            else
                local hits = 0
                for _, p in ipairs(Players:GetPlayers()) do
                    if not State.running or not killActive() then break end
                    if karmaMatch(p, State.kill.karmaMode) and punchPlayer(p) then
                        hits = hits + 1
                    end
                end
                if State.kill.serverHop then
                    if hits == 0 then
                        State.kill.noTargetsSince = State.kill.noTargetsSince or time()
                        if time() - State.kill.noTargetsSince >= Config.ServerHop.NoTargetsDelay then
                            State.kill.hopNow = true
                        end
                    else
                        State.kill.noTargetsSince = nil
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end

local function lockKillPosition()
    -- desativado: auto kill sem travar o personagem
    cancelTask("killPositionLock")
    State.kill.lockCFrame = nil
    State.kill.lockCharacter = nil
end

State.setAutoKill = function(enabled)
    if enabled and type(firetouchinterest) ~= "function" then return false end
    State.kill.auto = enabled == true
    if State.kill.auto then
        State.kill.targetMode = false
        State.kill.karmaMode = nil
        cancelTask("killSizeOne")
        cancelTask("killPositionLock")
    else
        cancelTask("killSizeOne")
        cancelTask("killPositionLock")
    end
    runKillLoop()
    return true
end

State.setTargetKill = function(enabled)
    if enabled and type(firetouchinterest) ~= "function" then return false end
    State.kill.targetMode = enabled == true
    if State.kill.targetMode then
        State.kill.auto = false
        State.kill.karmaMode = nil
        cancelTask("killSizeOne")
        cancelTask("killPositionLock")
    else
        cancelTask("killSizeOne")
        cancelTask("killPositionLock")
    end
    runKillLoop()
    return true
end

State.setKarmaKill = function(mode, enabled)
    if enabled and type(firetouchinterest) ~= "function" then return false end
    if enabled then
        State.kill.karmaMode = mode
        State.kill.auto = false
        State.kill.targetMode = false
        cancelTask("killSizeOne")
        cancelTask("killPositionLock")
    else
        if State.kill.karmaMode == mode then
            State.kill.karmaMode = nil
        end
        cancelTask("killSizeOne")
        cancelTask("killPositionLock")
    end
    runKillLoop()
    return true
end

State.setProtectFriends = function(enabled)
    State.kill.protectFriends = enabled == true
    if not State.kill.protectFriends then
        table.clear(State.kill.friendCache)
    end
    return true
end

State.setServerHop = function(enabled)
    if enabled and State.kill.targetMode then return false end
    State.kill.serverHop = enabled == true
    State.kill.hopNow = false
    State.kill.noTargetsSince = nil
    cancelTask("killServerHop")
    if State.kill.serverHop then
        spawnTask("killServerHop", function()
            while State.running and State.kill.serverHop do
                local interval = Config.ServerHop.Interval
                while interval > 0 and not State.kill.hopNow do
                    if not State.running or not State.kill.serverHop then return end
                    task.wait(1)
                    interval = interval - 1
                end
                State.kill.hopNow = false
                if not State.running or not State.kill.serverHop then return end
                -- Simple hop: pick a random public server
                local ok, result = pcall(game.HttpGet, game, string.format(Config.ServerHop.ServerApi, game.PlaceId), true)
                if ok and type(result) == "string" then
                    local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, result)
                    if decodeOk and type(data) == "table" and data.data then
                        local candidates = {}
                        for _, s in ipairs(data.data) do
                            if type(s) == "table" and type(s.id) == "string" and s.id ~= game.JobId
                                and tonumber(s.playing) and tonumber(s.maxPlayers)
                                and tonumber(s.playing) < tonumber(s.maxPlayers)
                                and tonumber(s.playing) >= Config.ServerHop.MinimumPlayers then
                                candidates[#candidates + 1] = s
                            end
                        end
                        if #candidates > 0 then
                            table.sort(candidates, function(a, b)
                                return tonumber(a.playing) > tonumber(b.playing)
                            end)
                            local pick = candidates[math.random(1, math.min(#candidates, 8))]
                            pcall(function()
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer)
                            end)
                            task.wait(12)
                        end
                    end
                end
                task.wait(Config.ServerHop.RetryDelay)
                State.kill.hopNow = true
            end
        end)
    end
    return true
end

State.stopKills = function()
    State.kill.auto = false
    State.kill.karmaMode = nil
    State.kill.targetMode = false
    State.kill.serverHop = false
    cancelTask("killFarm")
    cancelTask("killSizeOne")
    cancelTask("killPositionLock")
    cancelTask("killServerHop")
end

-- ========== Heartbeat movement loop ==========
track(RunService.Heartbeat:Connect(function()
    if not State.running then return end
    local char = getCharacter()
    local hum = getHumanoid()
    local hrp = getHRP()

    if State.fastSpeed and hum then
        hum.WalkSpeed = 1000
    end

    if State.fly and hum and hrp and workspace.CurrentCamera then
        if not bodyGyro or bodyGyro.Parent ~= hrp then
            clearFly()
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.Name = "FlyGyro"
            bodyGyro.P = 12000
            bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bodyGyro.Parent = hrp
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "FlyVelocity"
            bodyVelocity.P = 15000
            bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocity.Parent = hrp
        end
        local cam = workspace.CurrentCamera
        local speed = 160 + (math.clamp(State.flyLevel, 1, 30) - 1) * 24
        if State.fastSpeed then speed = speed + 1000 end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if dir.Magnitude < 0.05 and hum.MoveDirection.Magnitude > 0.05 then
            dir = hum.MoveDirection
        end
        if dir.Magnitude > 0 then dir = dir.Unit end
        local y = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump or flyUp then
            y = 1
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or flyDown then
            y = -1
        end
        hum.PlatformStand = true
        bodyGyro.MaxTorque = State.spin and Vector3.new(9e9, 0, 9e9) or Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.CFrame = cam.CFrame
        bodyVelocity.Velocity = dir * speed + Vector3.new(0, y * speed, 0)
    elseif not State.fly and (bodyGyro or bodyVelocity) then
        clearFly()
    end

    if State.antiKnockback and hrp and hum and not State.fly then
        if not State.antiKnockbackVelocity or State.antiKnockbackVelocity.Parent ~= hrp then
            State.clearAntiKnockback()
            State.antiKnockbackVelocity = Instance.new("BodyVelocity")
            State.antiKnockbackVelocity.Name = "AntiKnockback"
            State.antiKnockbackVelocity.P = 25000
            State.antiKnockbackVelocity.MaxForce = Vector3.new(1e9, 0, 1e9)
            State.antiKnockbackVelocity.Parent = hrp
        end
        local md = hum.MoveDirection
        local spd = State.fastSpeed and 1000 or math.max(hum.WalkSpeed, 16)
        State.antiKnockbackVelocity.Velocity = Vector3.new(md.X * spd, 0, md.Z * spd)
        hrp.AssemblyLinearVelocity = Vector3.new(
            md.X * spd,
            math.clamp(hrp.AssemblyLinearVelocity.Y, -90, 90),
            md.Z * spd
        )
        hrp.AssemblyAngularVelocity = Vector3.zero
    elseif State.antiKnockbackVelocity then
        State.clearAntiKnockback()
    end

    if State.spin and hrp and hum then
        if not spinAngular or spinAngular.Parent ~= hrp then
            clearSpin()
            spinHum = hum
            spinAutoRotate = hum.AutoRotate
            hum.AutoRotate = false
            spinAngular = Instance.new("BodyAngularVelocity")
            spinAngular.Name = "Spin"
            spinAngular.AngularVelocity = Vector3.new(0, 7, 0)
            spinAngular.MaxTorque = Vector3.new(0, 9e9, 0)
            spinAngular.P = 6000
            spinAngular.Parent = hrp
        end
    elseif spinAngular then
        clearSpin()
    end

    if State.spy and workspace.CurrentCamera then
        local target = State.spyTarget and Players:FindFirstChild(State.spyTarget)
        local subj = target and target.Character and target.Character:FindFirstChildWhichIsA("Humanoid")
        if subj then
            workspace.CurrentCamera.CameraSubject = subj
        end
    end
end))

-- Infinite jump
track(UserInputService.JumpRequest:Connect(function()
    if State.infiniteJump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

-- Character respawn hooks
track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    if State.fastSpeed then updateWalkSpeed() end
    if State.fastPunch then setFastPunch(true) end
    if not State.spy then
        local hum = getHumanoid()
        if workspace.CurrentCamera and hum then
            workspace.CurrentCamera.CameraSubject = hum
        end
    end
end))

-- ========== Shutdown ==========
local function shutdown()
    State.running = false
    FastFarm:Stop(true)
    setFastPunch(false)
    setExercise("autoWeight", false)
    setExercise("autoHandstands", false)
    setExercise("autoLift", false)
    setExercise("autoSitups", false)
    setAutoEgg(false)
    setHideDurability(false)
    setHideFrames(false)
    setMachine(nil, false)
    setAntiLag(false)
    setWalkWater(false)
    setAutoSpinWheel(false)
    if setAutoEatProtein then setAutoEatProtein(false) end
    setAutoClaimChests(false)
    setRemovePortals(false)
    setFastSpeed(false)
    State.setAntiKnockback(false)
    setNoclip(false)
    setSpin(false)
    setSpy(false)
    State.stopKills()
    State.autoPet = false
    State.autoAura = false
    cancelTask("autoPet")
    cancelTask("autoAura")
    cleanupAll()
end

-- ========== VOID UI ==========
local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/slowzzx4-8/Ui-library/refs/heads/main/Void%20Ui%20Library.lua"))()

local Window = VoidUI:CreateWindow({
    Name = "Muscle Legends",
    Icon = "dumbbell",
    SideBarWidth = 160,
    Theme = "Dark",
    Transparent = true,
    Author = "By Slowzzx4",
    User = { Enabled = true, Anonymous = true },
    Folder = "MuscleLegendsScript",
})

-- UI Dark original + contorno cinza com tom branco
local OUTLINE_GRAY = Color3.fromRGB(180, 180, 190)
pcall(function()
    Window:SetTheme("Dark")
    if VoidUI and VoidUI.Theme then
        VoidUI.Theme.Outline = OUTLINE_GRAY
        VoidUI.Theme.IconColor = Color3.fromRGB(200, 200, 210)
    end
    if VoidUI.UpdateTheme then
        VoidUI:UpdateTheme()
    end
end)

Window:EditOpenButton({
    Title = "Muscle Legends",
    Icon = "dumbbell",
    Transparency = 0.2,
    StrokeThickness = 1.2,
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 160, 170)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 220, 230)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 140, 150)),
    },
    AutoRotation = false,
    Speed = 12,
    CornerRadius = UDim.new(0, 16),
})

pcall(function() Window:SetToggleKey(Enum.KeyCode.RightControl) end)
pcall(function() Window:UserEnabled(true) end)
pcall(function() Window:Anonymous(true) end)

task.defer(function()
    task.wait(0.25)
    pcall(function()
        if VoidUI and VoidUI.Theme then
            VoidUI.Theme.Outline = OUTLINE_GRAY
            VoidUI.Theme.IconColor = Color3.fromRGB(200, 200, 210)
        end
        if VoidUI.UpdateTheme then VoidUI:UpdateTheme() end
    end)
end)

-- Watermark FPS / PING
local fpsValue = 60
pcall(function()
    local last = tick()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames += 1
        local now = tick()
        if now - last >= 1 then
            fpsValue = frames
            frames = 0
            last = now
        end
    end)
end)

local function updateWatermark()
    local ping = 0
    pcall(function() ping = getPing() end)
    pcall(function()
        Window:SetWatermark(string.format("FPS %d   /   PING %d ms", fpsValue, ping))
    end)
end
updateWatermark()
spawnTask("watermarkFpsPing", function()
    while State.running do
        updateWatermark()
        task.wait(0.5)
    end
end)


-- Config JSON real (toggle / slider / dropdown / input) — sem notificação
local CONFIG_FOLDER = "MuscleLegendsScript"
local CONFIG_PATH = CONFIG_FOLDER .. "/config.json"
State.UIConfig = State.UIConfig or { toggles = {}, sliders = {}, dropdowns = {}, inputs = {} }

local function saveUserConfig()
    pcall(function()
        local payload = {
            toggles = State.UIConfig.toggles or {},
            sliders = State.UIConfig.sliders or {},
            dropdowns = State.UIConfig.dropdowns or {},
            inputs = State.UIConfig.inputs or {},
            -- espelho de state importante
            mainSize = State.mainSize,
            mainSpeed = State.mainSpeed,
            fastSpeed = State.fastSpeed == true,
            selectedRock = State.selectedRock and State.selectedRock.name or nil,
        }
        local encoded = HttpService:JSONEncode(payload)
        if isfolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        if writefile then writefile(CONFIG_PATH, encoded) end
    end)
end

local function loadUserConfig()
    pcall(function()
        if not (readfile and isfile and isfile(CONFIG_PATH)) then return end
        local data = HttpService:JSONDecode(readfile(CONFIG_PATH))
        if type(data) ~= "table" then return end
        State.UIConfig.toggles = type(data.toggles) == "table" and data.toggles or {}
        State.UIConfig.sliders = type(data.sliders) == "table" and data.sliders or {}
        State.UIConfig.dropdowns = type(data.dropdowns) == "table" and data.dropdowns or {}
        State.UIConfig.inputs = type(data.inputs) == "table" and data.inputs or {}
        if data.mainSize ~= nil then State.mainSize = tonumber(data.mainSize) or State.mainSize end
        if data.mainSpeed ~= nil then State.mainSpeed = tonumber(data.mainSpeed) or State.mainSpeed end
        if data.fastSpeed ~= nil then State.fastSpeed = data.fastSpeed == true end
        State._savedRockName = data.selectedRock
    end)
end

local function cfgToggle(key, default)
    local v = State.UIConfig.toggles[key]
    if v == nil then return default end
    return v == true
end
local function cfgSlider(key, default)
    local v = State.UIConfig.sliders[key]
    if v == nil then return default end
    return tonumber(v) or default
end
local function cfgDrop(key, default)
    local v = State.UIConfig.dropdowns[key]
    if v == nil then return default end
    return v
end
local function cfgInput(key, default)
    local v = State.UIConfig.inputs[key]
    if v == nil then return default end
    return tostring(v)
end
local function setCfgToggle(key, v)
    State.UIConfig.toggles[key] = v == true
    saveUserConfig()
end
local function setCfgSlider(key, v)
    State.UIConfig.sliders[key] = tonumber(v) or v
    saveUserConfig()
end
local function setCfgDrop(key, v)
    State.UIConfig.dropdowns[key] = v
    saveUserConfig()
end
local function setCfgInput(key, v)
    State.UIConfig.inputs[key] = tostring(v or "")
    saveUserConfig()
end

loadUserConfig()

spawnTask("autoSaveConfig", function()
    while State.running do
        task.wait(20)
        saveUserConfig()
    end
end)

pcall(function()
    Window:OnDestroy(function()
        pcall(saveUserConfig)
        pcall(shutdown)
    end)
end)

local Tabs = {}
for _, def in ipairs({
    { "Main Features", "layout-dashboard" },
    { "Auto Farm", "sprout" },
    { "Auto Rebirth", "refresh-cw" },
    { "Fast Farm", "gauge" },
    { "Kills", "swords" },
    { "Gifts", "gift" },
    { "Trade", "repeat" },
    { "Teleports", "map-pin" },
    { "Stats", "activity" },
    { "Misc", "settings" },
}) do
    Tabs[def[1]] = Window:Tab({ Title = def[1], Icon = def[2], Border = true })
end
-- Aliases (código interno)
Tabs.Main = Tabs["Main Features"]
Tabs.AutoFarm = Tabs["Auto Farm"]
Tabs.FastFarm = Tabs["Fast Farm"]
Tabs.Glitch = Tabs["Auto Farm"] -- rocks agora em Auto Farm
Tabs.Rebirths = Tabs["Auto Rebirth"]

local function playerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            list[#list + 1] = p.DisplayName .. " (" .. p.Name .. ")"
        end
    end
    table.sort(list)
    return list
end

local function resolvePlayer(label)
    if not label then return nil end
    local name = label:match("%((.-)%)") or label
    return Players:FindFirstChild(name)
end

-- ========== MAIN ==========
Tabs.Main:TabSection({ Title = "Size Speed" })
Tabs.Main:Slider({
    Title = "Size",
    Value = { Min = 1, Max = 100, Default = cfgSlider("mainSize", State.mainSize or 2) },
    Step = 1,
    Callback = function(v)
        State.mainSize = v
        applySizeOrSpeed("changeSize", v)
        setCfgSlider("mainSize", v)
    end,
})
Tabs.Main:Toggle({
    Title = "Auto Size",
    Default = cfgToggle("autoSize", false),
    Callback = function(v)
        State.mainAutoSize = v
        setCfgToggle("autoSize", v)
        cancelTask("mainAutoSize")
        if v then
            spawnTask("mainAutoSize", function()
                while State.running and State.mainAutoSize do
                    applySizeOrSpeed("changeSize", State.mainSize)
                    task.wait(0.35)
                end
            end)
        end
    end,
})
Tabs.Main:Slider({
    Title = "Speed",
    Value = { Min = 16, Max = 500, Default = cfgSlider("mainSpeed", State.mainSpeed or 125) },
    Step = 1,
    Callback = function(v)
        State.mainSpeed = v
        applySizeOrSpeed("changeSpeed", v)
        setCfgSlider("mainSpeed", v)
    end,
})
Tabs.Main:Toggle({
    Title = "Auto Speed",
    Default = cfgToggle("autoSpeed", false),
    Callback = function(v)
        State.mainAutoSpeed = v
        setCfgToggle("autoSpeed", v)
        cancelTask("mainAutoSpeed")
        if v then
            spawnTask("mainAutoSpeed", function()
                while State.running and State.mainAutoSpeed do
                    applySizeOrSpeed("changeSpeed", State.mainSpeed)
                    task.wait(0.35)
                end
            end)
        end
    end,
})
Tabs.Main:Toggle({
    Title = "Infinite Jump",
    Default = cfgToggle("infiniteJump", false),
    Callback = function(v)
        State.infiniteJump = v
        setCfgToggle("infiniteJump", v)
    end,
})

Tabs.Main:TabSection({ Title = "Movement" })
Tabs.Main:Toggle({
    Title = "Spin",
    Default = cfgToggle("spin", false),
    Callback = function(v) setSpin(v); setCfgToggle("spin", v) end,
})
Tabs.Main:Toggle({
    Title = "Anti Stun",
    Default = cfgToggle("antiStun", false),
    Callback = function(v)
        -- Anti Stun = anti-knockback clássico (BodyVelocity)
        State.setAntiKnockback(v)
        setCfgToggle("antiStun", v)
    end,
})
Tabs.Main:Toggle({
    Title = "Walk On Water",
    Default = cfgToggle("walkWater", false),
    Callback = function(v) setWalkWater(v); setCfgToggle("walkWater", v) end,
})
Tabs.Main:Toggle({
    Title = "Noclip",
    Default = cfgToggle("noclip", false),
    Callback = function(v) setNoclip(v); setCfgToggle("noclip", v) end,
})
-- ========== AUTO FARM ==========
Tabs.AutoFarm:TabSection({ Title = "Punch" })
Tabs.AutoFarm:Toggle({
    Title = "Fast Punch",
    Default = cfgToggle("fastPunch", false),
    Callback = function(v)
        setFastPunch(v)
        setCfgToggle("fastPunch", v)
        if not v and not State.selectedRock then
            stopPunchTasks()
        elseif v then
            startPunchTasks()
        end
    end,
})
Tabs.AutoFarm:Toggle({
    Title = "Auto Use Tools",
    Default = cfgToggle("autoUseTools", false),
    Callback = function(v)
        State.autoUseTools = v == true
        setCfgToggle("autoUseTools", v)
        cancelTask("autoUseTools")
        if v then
            spawnTask("autoUseTools", function()
                while State.running and State.autoUseTools do
                    pcall(function()
                        local ev = LocalPlayer:FindFirstChild("muscleEvent")
                        if ev then
                            for _ = 1, 3 do
                                ev:FireServer("rep")
                            end
                        end
                    end)
                    task.wait(0.18)
                end
            end)
        end
    end,
})

Tabs.AutoFarm:TabSection({ Title = "Rocks" })
local rockNameList = {}
local rockByName = {}
for _, rock in ipairs(Config.Rocks) do
    rockNameList[#rockNameList + 1] = rock.name
    rockByName[rock.name] = rock
end
local selectedRockName = State._savedRockName or rockNameList[1]
Tabs.AutoFarm:Dropdown({
    Title = "Select Rock",
    Option = #rockNameList > 0 and rockNameList or { "None" },
    Value = selectedRockName,
    Callback = function(v)
        selectedRockName = v
        setCfgDrop("selectedRock", v)
        if State._autoRock then
            local r = rockByName[v]
            if r then setRockSelection(r) end
        end
    end,
})
Tabs.AutoFarm:Toggle({
    Title = "Auto Rock",
    Default = cfgToggle("autoRock", false),
    Callback = function(v)
        State._autoRock = v == true
        setCfgToggle("autoRock", v)
        if v then
            local r = rockByName[selectedRockName]
            if not r then
                Window:Notify({ Title = "Auto Farm", Content = "Select A Rock First", Icon = "mountain", Duration = 2 })
                return false
            end
            setRockSelection(r)
        else
            setRockSelection(nil)
        end
    end,
})
Tabs.AutoFarm:Toggle({
    Title = "Hide Durability",
    Default = cfgToggle("hideDurability", false),
    Callback = function(v) setHideDurability(v); setCfgToggle("hideDurability", v) end,
})

Tabs.AutoFarm:TabSection({ Title = "Brawl" })
local validBrawlMaps = {
    ["Magma Ring"] = true,
    ["Desert Ring"] = true,
    ["Boxing Ring"] = true,
}
local function isInBrawlMap(plr)
    if not plr then return false end
    local mapData = plr:FindFirstChild("currentMap")
    return mapData and validBrawlMaps[mapData.Value] == true
end

Tabs.AutoFarm:Toggle({
    Title = "Auto Join Brawl",
    Default = cfgToggle("autoBrawl", false),
    Callback = function(v)
        State._autoBrawl = v == true
        setCfgToggle("autoBrawl", v)
        cancelTask("autoBrawlJoin")
        if not v then return end
        spawnTask("autoBrawlJoin", function()
            while State.running and State._autoBrawl do
                pcall(function()
                    local gameGui = PlayerGui:FindFirstChild("gameGui")
                    local label = gameGui and gameGui:FindFirstChild("brawlJoinLabel")
                    if label and label.Visible then
                        local yes = label:FindFirstChild("yesButton")
                        local ev = ReplicatedStorage:FindFirstChild("rEvents")
                        ev = ev and ev:FindFirstChild("brawlEvent")
                        if ev then
                            ev:FireServer("joinBrawl")
                            task.wait(3)
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end,
})

Tabs.AutoFarm:Toggle({
    Title = "Auto Kill In Brawl",
    Default = cfgToggle("brawlAutoKill", false),
    Callback = function(v)
        State._brawlAutoKill = v == true
        setCfgToggle("brawlAutoKill", v)
        cancelTask("brawlAutoKill")
        if not v then return end
        spawnTask("brawlAutoKill", function()
            while State.running and State._brawlAutoKill do
                if isInBrawlMap(LocalPlayer) then
                    for _, targetPlayer in ipairs(Players:GetPlayers()) do
                        if targetPlayer ~= LocalPlayer and isInBrawlMap(targetPlayer) then
                            pcall(punchPlayer, targetPlayer)
                        end
                    end
                end
                task.wait(0.05)
            end
        end)
    end,
})

Tabs.AutoFarm:TabSection({ Title = "Exercises" })
local exerciseKeys = {
    { "Auto Weight", "autoWeight", { "Weight" } },
    { "Auto Handstands", "autoHandstands", { "Handstands", "Handstand" } },
    { "Auto Lift", "autoLift", { "Pushup", "Pushups" } },
    { "Auto Situps", "autoSitups", { "Situps", "Situp" } },
}
local exerciseToggles = {}
for _, def in ipairs(exerciseKeys) do
    local title, key, tools = def[1], def[2], def[3]
    Tabs.AutoFarm:Toggle({
        Title = title,
        Default = false,
        Callback = function(v)
            if v then
                for otherKey, setFn in pairs(exerciseToggles) do
                    if otherKey ~= key then setFn(false) end
                end
            end
            setExercise(key, v, tools, 0.01)
        end,
    })
end
Tabs.AutoFarm:Toggle({
    Title = "Auto Egg 30 Min",
    Default = false,
    Callback = function(v) setAutoEgg(v, "manual") end,
})
Tabs.AutoFarm:TabSection({ Title = "Machines" })
for _, m in ipairs(Config.Machines) do
    local machine = m
    Tabs.AutoFarm:Toggle({
        Title = machine.label,
        Default = false,
        Callback = function(v)
            if v then
                setMachine(machine, true)
            elseif State.machine == machine then
                setMachine(machine, false)
            end
        end,
    })
end

-- ========== FAST FARM ==========
Tabs.FastFarm:TabSection({ Title = "Modes" })
Tabs.FastFarm:Paragraph({
    Title = "Requirement",
    Desc = "Needs 7 or 8 pet packs (Swift Samurai / Tribal Overlord). Do not enable without them.",
})
local fastRebirthToggle, fastStrengthToggle
Tabs.FastFarm:Toggle({
    Title = "Fast Rebirth",
    Default = false,
    Callback = function(v)
        if v then
            FastFarm:Start("rebirth")
        elseif FastFarm.mode == "rebirth" then
            FastFarm:Stop(true)
        end
    end,
})
Tabs.FastFarm:Toggle({
    Title = "Fast Strength",
    Default = false,
    Callback = function(v)
        if v then
            FastFarm:Start("strength")
        elseif FastFarm.mode == "strength" then
            FastFarm:Stop(true)
        end
    end,
})

-- ========== REBIRTHS ==========
Tabs.Rebirths:TabSection({ Title = "Tools" })
Tabs.Rebirths:Toggle({
    Title = "Set Size 1",
    Default = false,
    Callback = function(v)
        State.rebirth.sizeOne = v
        cancelTask("rebirthSizeOne")
        if v then
            setSizeOne()
            spawnTask("rebirthSizeOne", function()
                while State.running and State.rebirth.sizeOne do
                    setSizeOne()
                    task.wait(0.75)
                end
            end)
        end
    end,
})
Tabs.Rebirths:Toggle({
    Title = "Fast Weight",
    Default = false,
    Callback = function(v)
        State.rebirth.fastWeight = v
        setExercise("rebirthFastWeight", v, { "Weight", "Heavy Weight" }, 0.005)
    end,
})
Tabs.Rebirths:Toggle({
    Title = "King Position",
    Default = false,
    Callback = function(v)
        State.rebirth.king = v
        cancelTask("rebirthKing")
        if v then
            local kingPos = Vector3.new(-8646, 13.25, -5738)
            spawnTask("rebirthKing", function()
                while State.running and State.rebirth.king do
                    local hrp = getHRP()
                    if hrp and (hrp.Position - kingPos).Magnitude > 42 then
                        local target = kingPos
                        if State.rebirth.lockPosition then
                            State.rebirth.lockCFrame = CFrame.new(target)
                        end
                        hrp.CFrame = CFrame.new(target)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                    task.wait(0.25)
                end
            end)
        end
    end,
})
Tabs.Rebirths:Toggle({
    Title = "Lock Position",
    Default = false,
    Callback = function(v)
        State.rebirth.lockPosition = v
        local hrp = getHRP()
        State.rebirth.lockCFrame = v and hrp and hrp.CFrame or nil
        cancelTask("rebirthLock")
        if v and State.rebirth.lockCFrame then
            spawnTask("rebirthLock", function()
                while State.running and State.rebirth.lockPosition do
                    local hrp = getHRP()
                    if hrp and State.rebirth.lockCFrame then
                        hrp.CFrame = State.rebirth.lockCFrame
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end,
})
Tabs.Rebirths:Toggle({
    Title = "Egg Every 30 Min",
    Default = false,
    Callback = function(v) setAutoEgg(v, "rebirth") end,
})
Tabs.Rebirths:TabSection({ Title = "Auto Rebirth" })
local rebirthTargetText = cfgInput("rebirthObjective", "")
local function parseRebirthTarget(text)
    local n = tonumber((tostring(text or "")):gsub("[^%d]", ""))
    if n and n > 0 then
        State.rebirth.target = math.floor(n)
        setCfgInput("rebirthObjective", tostring(State.rebirth.target))
        return true
    end
    State.rebirth.target = nil
    return false
end
if rebirthTargetText ~= "" then
    parseRebirthTarget(rebirthTargetText)
end
local rebirthTargetInput = Tabs.Rebirths:Input({
    Title = "Rebirths Objective",
    Placeholder = "Example: 18980",
    Default = rebirthTargetText,
    Value = rebirthTargetText,
    Callback = function(text)
        parseRebirthTarget(text)
    end,
})
Tabs.Rebirths:Toggle({
    Title = "Rebirth Until Objective",
    Default = false,
    Callback = function(v)
        -- tenta ler de novo do input salvo
        if v and not State.rebirth.target and rebirthTargetText ~= "" then
            parseRebirthTarget(rebirthTargetText)
        end
        if v and not State.rebirth.target then
            Window:Notify({ Title = "Rebirths", Content = "Set Objective First", Icon = "refresh-cw", Duration = 2 })
            return false
        end
        State.rebirth.autoTarget = v == true
        if v then State.rebirth.infinite = false end
        cancelTask("rebirthLoop")
        if State.rebirth.autoTarget or State.rebirth.infinite then
            spawnTask("rebirthLoop", function()
                while State.running and (State.rebirth.autoTarget or State.rebirth.infinite) do
                    local stat = getStat({ "Rebirths", "Rebirth" })
                    local val = tonumber(stat and stat.Value) or 0
                    if State.rebirth.autoTarget and State.rebirth.target and val >= State.rebirth.target then
                        State.rebirth.autoTarget = false
                        break
                    end
                    requestRebirth()
                    task.wait(0.12)
                end
            end)
        end
    end,
})
Tabs.Rebirths:Toggle({
    Title = "Infinite Rebirths",
    Default = false,
    Callback = function(v)
        State.rebirth.infinite = v
        if v then State.rebirth.autoTarget = false end
        cancelTask("rebirthLoop")
        if State.rebirth.autoTarget or State.rebirth.infinite then
            spawnTask("rebirthLoop", function()
                while State.running and (State.rebirth.autoTarget or State.rebirth.infinite) do
                    requestRebirth()
                    task.wait(0.1)
                end
            end)
        end
    end,
})
Tabs.Rebirths:Toggle({
    Title = "Prevent Rebirth",
    Default = cfgToggle("preventRebirth", false),
    Callback = function(v)
        setPreventRebirth(v)
        setCfgToggle("preventRebirth", v)
    end,
})

-- ========== KILLS ==========
Tabs.Kills:TabSection({ Title = "Modes" })
Tabs.Kills:Toggle({
    Title = "Server Hop 2 Min",
    Default = false,
    Callback = function(v) return State.setServerHop(v) end,
})
Tabs.Kills:TabSection({ Title = "Target" })
local killPlayerDropdown = Tabs.Kills:Dropdown({
    Title = "Choose Player",
    Option = playerList(),
    Value = nil,
    Callback = function(v)
        local p = resolvePlayer(v)
        State.kill.target = p and p.Name or nil
    end,
})
Tabs.Kills:Toggle({
    Title = "Kill Selected Player",
    Default = false,
    Callback = function(v) return State.setTargetKill(v) end,
})
Tabs.Kills:Toggle({
    Title = "Kill ALL",
    Default = false,
    Callback = function(v) return State.setAutoKill(v) end,
})
Tabs.Kills:Toggle({
    Title = "Protect Friends",
    Default = false,
    Callback = function(v) return State.setProtectFriends(v) end,
})
Tabs.Kills:Toggle({
    Title = "Evil Karma",
    Default = false,
    Callback = function(v) return State.setKarmaKill("evil", v) end,
})
Tabs.Kills:Toggle({
    Title = "Good Karma",
    Default = false,
    Callback = function(v) return State.setKarmaKill("good", v) end,
})
Tabs.Kills:Button({
    Title = "Refresh Players",
    Callback = function()
        pcall(function()
            killPlayerDropdown:SetValues(playerList())
        end)
        pcall(function()
            if viewPlayerDropdown and viewPlayerDropdown.SetValues then
                viewPlayerDropdown:SetValues(playerList())
            end
        end)
    end,
})

Tabs.Kills:TabSection({ Title = "View Player" })
local viewPlayerDropdown = Tabs.Kills:Dropdown({
    Title = "Choose Player",
    Option = playerList(),
    Value = nil,
    Callback = function(v)
        local p = resolvePlayer(v)
        State.spyTarget = p and p.Name or nil
    end,
})
Tabs.Kills:Toggle({
    Title = "View Player",
    Default = false,
    Callback = function(v)
        if v and not State.spyTarget then
            Window:Notify({ Title = "View Player", Content = "Select a player first", Icon = "eye", Duration = 2 })
            return false
        end
        setSpy(v)
    end,
})

-- ========== GIFTS ==========
Tabs.Gifts:TabSection({ Title = "Send" })
local giftPlayer = nil
Tabs.Gifts:Dropdown({
    Title = "Player",
    Option = playerList(),
    Value = nil,
    Callback = function(v)
        local p = resolvePlayer(v)
        giftPlayer = p
    end,
})
local eggAmount, shakeAmount = 1, 1
Tabs.Gifts:Input({
    Title = "Eggs Amount",
    Placeholder = "1",
    Callback = function(t)
        eggAmount = math.clamp(math.floor(tonumber(t) or 1), 1, 9999)
    end,
})
Tabs.Gifts:Button({
    Title = "Send Protein Eggs",
    Callback = function()
        if not giftPlayer then
            Window:Notify({ Title = "Gifts", Content = "Choose a player", Icon = "gift", Duration = 2 })
            return
        end
        local folder = LocalPlayer:FindFirstChild("consumablesFolder")
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        local remote = rEvents and rEvents:FindFirstChild("giftRemote")
        if not folder or not remote then return end
        spawnTask("giftSender", function()
            for i = 1, eggAmount do
                if not State.running then break end
                local egg
                for _, name in ipairs(Config.AutoEgg.Names) do
                    egg = folder:FindFirstChild(name)
                    if egg then break end
                end
                if not egg then break end
                pcall(function()
                    remote:InvokeServer("giftRequest", giftPlayer, egg)
                end)
                task.wait(0.16)
            end
        end)
    end,
})
Tabs.Gifts:Input({
    Title = "Shakes Amount",
    Placeholder = "1",
    Callback = function(t)
        shakeAmount = math.clamp(math.floor(tonumber(t) or 1), 1, 9999)
    end,
})
Tabs.Gifts:Button({
    Title = "Send Tropical Shakes",
    Callback = function()
        if not giftPlayer then
            Window:Notify({ Title = "Gifts", Content = "Choose a player", Icon = "gift", Duration = 2 })
            return
        end
        local folder = LocalPlayer:FindFirstChild("consumablesFolder")
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        local remote = rEvents and rEvents:FindFirstChild("giftRemote")
        if not folder or not remote then return end
        spawnTask("giftSender", function()
            for i = 1, shakeAmount do
                if not State.running then break end
                local shake = folder:FindFirstChild("Tropical Shake")
                if not shake then break end
                pcall(function()
                    remote:InvokeServer("giftRequest", giftPlayer, shake)
                end)
                task.wait(0.16)
            end
        end)
    end,
})

Tabs.Gifts:TabSection({ Title = "Extras" })
Tabs.Gifts:Toggle({
    Title = "Spin Wheel",
    Default = cfgToggle("spinWheel", false),
    Callback = function(v)
        setAutoSpinWheel(v)
        setCfgToggle("spinWheel", v)
    end,
})
Tabs.Gifts:Toggle({
    Title = "Auto Eat Protein",
    Default = cfgToggle("autoEatProtein", false),
    Callback = function(v)
        setAutoEatProtein(v)
        setCfgToggle("autoEatProtein", v)
    end,
})

-- ========== TRADE ==========
Tabs.Trade:TabSection({ Title = "1. Send Trade Request" })

local function getPlayerNames()
    local list = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            list[#list + 1] = pl.Name
        end
    end
    table.sort(list)
    return list
end

local function getPetInventoryList()
    local counts = {}
    local folder = LocalPlayer:FindFirstChild("petsFolder")
    if folder then
        for _, category in ipairs(folder:GetChildren()) do
            if category:IsA("Folder") then
                for _, item in ipairs(category:GetChildren()) do
                    counts[item.Name] = (counts[item.Name] or 0) + 1
                end
            end
        end
    end
    local list = {}
    for name, count in pairs(counts) do
        list[#list + 1] = name .. " x" .. count
    end
    table.sort(list)
    if #list == 0 then return { "None" } end
    return list
end

local function getPetInstances(formattedName, amountToOffer)
    local instances = {}
    if not formattedName or formattedName == "None" then return instances end
    local targetName = formattedName:match("^(.-)%s+x%d+") or formattedName
    local folder = LocalPlayer:FindFirstChild("petsFolder")
    if not folder then return instances end
    for _, category in ipairs(folder:GetChildren()) do
        if category:IsA("Folder") then
            for _, item in ipairs(category:GetChildren()) do
                if item.Name == targetName then
                    instances[#instances + 1] = item
                    if #instances >= amountToOffer then return instances end
                end
            end
        end
    end
    return instances
end

State.tradeExt = State.tradeExt or {
    sendToPlayer = nil,
    acceptFromPlayer = nil,
    selectedPet = nil,
    amount = 1,
}

local tradeSendDropdown = Tabs.Trade:Dropdown({
    Title = "Send To Player",
    Option = getPlayerNames(),
    Value = nil,
    Callback = function(v)
        State.tradeExt.sendToPlayer = v
        setCfgDrop("tradeSendTo", v)
    end,
})

Tabs.Trade:Toggle({
    Title = "Auto Send Request",
    Default = cfgToggle("autoSendRequest", false),
    Callback = function(v)
        State._autoSendRequest = v == true
        setCfgToggle("autoSendRequest", v)
        cancelTask("autoSendRequest")
        if not v then return end
        spawnTask("autoSendRequest", function()
            while State.running and State._autoSendRequest do
                local name = State.tradeExt.sendToPlayer
                if name then
                    local target = Players:FindFirstChild(name)
                    if target then
                        pcall(function()
                            ReplicatedStorage.rEvents.tradingEvent:FireServer("sendTradeRequest", target)
                        end)
                    end
                end
                task.wait(1)
            end
        end)
    end,
})

Tabs.Trade:TabSection({ Title = "2. Accept Trade Invites" })

local tradeAcceptDropdown = Tabs.Trade:Dropdown({
    Title = "Accept Invites From",
    Option = getPlayerNames(),
    Value = nil,
    Callback = function(v)
        State.tradeExt.acceptFromPlayer = v
        setCfgDrop("tradeAcceptFrom", v)
    end,
})

Tabs.Trade:Toggle({
    Title = "Auto Accept Invite",
    Default = cfgToggle("autoAcceptInvite", false),
    Callback = function(v)
        State._autoAcceptInvite = v == true
        setCfgToggle("autoAcceptInvite", v)
        cancelTask("autoAcceptInvite")
        if not v then return end
        spawnTask("autoAcceptInvite", function()
            while State.running and State._autoAcceptInvite do
                pcall(function()
                    local name = State.tradeExt.acceptFromPlayer
                    if not name then return end
                    local targetPlayer = Players:FindFirstChild(name)
                    if not targetPlayer then return end
                    local gameGui = PlayerGui:FindFirstChild("gameGui")
                    if not gameGui then return end
                    local menu = gameGui:FindFirstChild("tradeRequestMenu", true)
                    if not menu or not menu.Visible then return end
                    local msgLabel = menu:FindFirstChild("msgLabel")
                    if not msgLabel then return end
                    local expectedName = targetPlayer.Name .. " has sent you a trade request!"
                    local expectedDisplay = targetPlayer.DisplayName .. " has sent you a trade request!"
                    if msgLabel.Text == expectedName or msgLabel.Text == expectedDisplay then
                        ReplicatedStorage.rEvents.tradingEvent:FireServer("requestAccepted", targetPlayer)
                        task.wait(2)
                    end
                end)
                task.wait(0.5)
            end
        end)
    end,
})

Tabs.Trade:TabSection({ Title = "3. Choose Items" })

local tradePetDropdown = Tabs.Trade:Dropdown({
    Title = "Select Pet",
    Option = getPetInventoryList(),
    Value = nil,
    Callback = function(v)
        State.tradeExt.selectedPet = v
        setCfgDrop("tradePet", v)
    end,
})

Tabs.Trade:Dropdown({
    Title = "Amount Of Pets",
    Option = { "1", "2", "3", "4", "5", "6" },
    Value = "1",
    Callback = function(v)
        State.tradeExt.amount = tonumber(v) or 1
        setCfgDrop("tradeAmount", v)
    end,
})

Tabs.Trade:Button({
    Title = "Refresh All Lists",
    Callback = function()
        local players = getPlayerNames()
        pcall(function() tradeSendDropdown:SetValues(players) end)
        pcall(function() tradeAcceptDropdown:SetValues(players) end)
        pcall(function() tradePetDropdown:SetValues(getPetInventoryList()) end)
    end,
})

Tabs.Trade:TabSection({ Title = "4. Auto Put Items" })

Tabs.Trade:Toggle({
    Title = "Auto Put Pet In Trade",
    Default = cfgToggle("autoPutPet", false),
    Callback = function(v)
        State._autoPutPet = v == true
        setCfgToggle("autoPutPet", v)
        cancelTask("autoPutPet")
        if not v then return end
        spawnTask("autoPutPet", function()
            while State.running and State._autoPutPet do
                if State.tradeExt.selectedPet then
                    local pets = getPetInstances(State.tradeExt.selectedPet, State.tradeExt.amount or 1)
                    for _, pet in ipairs(pets) do
                        pcall(function()
                            ReplicatedStorage.rEvents.tradingEvent:FireServer("offerItem", pet)
                        end)
                        task.wait(0.1)
                    end
                end
                task.wait(1.5)
            end
        end)
    end,
})

Tabs.Trade:TabSection({ Title = "5. Final Confirmation" })

Tabs.Trade:Toggle({
    Title = "Auto Confirm Final Trade",
    Default = cfgToggle("autoConfirmFinal", false),
    Callback = function(v)
        State._autoConfirmFinal = v == true
        setCfgToggle("autoConfirmFinal", v)
        cancelTask("autoConfirmFinal")
        if not v then return end
        spawnTask("autoConfirmFinal", function()
            while State.running and State._autoConfirmFinal do
                pcall(function()
                    local gameGui = PlayerGui:FindFirstChild("gameGui")
                    if not gameGui then return end
                    local acceptedLabel = gameGui:FindFirstChild("acceptedLabel", true)
                    -- path original
                    pcall(function()
                        acceptedLabel = gameGui.tradePanel.otherOfferMenu.itemFrames.backImageFolder.acceptedCover.acceptedLabel
                    end)
                    if acceptedLabel and acceptedLabel.Visible then
                        for _ = 1, 3 do
                            ReplicatedStorage.rEvents.tradingEvent:FireServer("acceptTrade")
                            task.wait(0.1)
                        end
                        while State.running and State._autoConfirmFinal and acceptedLabel.Visible do
                            task.wait(0.2)
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end,
})

-- ========== TELEPORTS ==========
Tabs.Teleports:TabSection({ Title = "Locations" })
for _, tp in ipairs(Config.Teleports) do
    local name, pos = tp[1], tp[2]
    Tabs.Teleports:Button({
        Title = name,
        Callback = function()
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = CFrame.new(pos)
            end
        end,
    })
end

-- ========== STATS ==========
Tabs.Stats:TabSection({ Title = "Live Stats" })
local sessionStart = os.time()
local baseline = {}
local statNames = {
    { "Strength", { "Strength", "Fuerza" } },
    { "Durability", { "Durability", "Durabilidad" } },
    { "Rebirths", { "Rebirths", "Rebirth" } },
    { "Kills", { "Kills" } },
    { "Evil Karma", { "evilKarma", "Evil Karma" } },
    { "Good Karma", { "goodKarma", "Good Karma" } },
}

-- Status (ícone dumbbell) + linhas nome esquerda / valor direita
local statusParagraph = Tabs.Stats:Paragraph({
    Title = "Status",
    Desc = "Loading...",
    Icon = "dumbbell",
})
local sessionKV = Tabs.Stats:KeyValue({ Title = "Session", Value = "0d 0h 0m 0s" })
local strengthKV = Tabs.Stats:KeyValue({ Title = "Strength", Value = "0 (+0)" })
local durabilityKV = Tabs.Stats:KeyValue({ Title = "Durability", Value = "0 (+0)" })
local rebirthsKV = Tabs.Stats:KeyValue({ Title = "Rebirths", Value = "0 (+0)" })
local killsKV = Tabs.Stats:KeyValue({ Title = "Kills", Value = "0 (+0)" })
local evilKV = Tabs.Stats:KeyValue({ Title = "Evil Karma", Value = "0 (+0)" })
local goodKV = Tabs.Stats:KeyValue({ Title = "Good Karma", Value = "0 (+0)" })
local pingKV = Tabs.Stats:KeyValue({ Title = "Ping", Value = "0 ms" })

local paraMap = {
    Strength = strengthKV,
    Durability = durabilityKV,
    Rebirths = rebirthsKV,
    Kills = killsKV,
    ["Evil Karma"] = evilKV,
    ["Good Karma"] = goodKV,
}

local function setParagraphContent(para, text)
    if not para then return end
    pcall(function()
        if para.Set then
            para:Set(text)
        elseif para.SetContent then
            para:SetContent(text)
        elseif para.Content ~= nil then
            para.Content = text
        end
    end)
end

local function activeStatusText()
    local parts = {}
    if State.fastPunch then parts[#parts + 1] = "Fast Punch" end
    if State.selectedRock then parts[#parts + 1] = "Rock " .. State.selectedRock.name end
    if State.autoWeight then parts[#parts + 1] = "Auto Weight" end
    if State.autoHandstands then parts[#parts + 1] = "Auto Handstands" end
    if State.autoLift then parts[#parts + 1] = "Auto Lift" end
    if State.autoSitups then parts[#parts + 1] = "Auto Situps" end
    if State.machine then parts[#parts + 1] = "Machine " .. (State.machine.label or "") end
    if FastFarm.mode then parts[#parts + 1] = "Fast Farm " .. FastFarm.mode end
    if State.kill.auto then parts[#parts + 1] = "Kill ALL" end
    if State.kill.karmaMode then parts[#parts + 1] = "Karma " .. State.kill.karmaMode end
    if State.kill.targetMode then parts[#parts + 1] = "Kill Target" end
    if State.antiKnockback then parts[#parts + 1] = "Anti Stun" end
    if State.noclip then parts[#parts + 1] = "Noclip" end
    if State.autoSpinWheel then parts[#parts + 1] = "Spin Wheel" end
    if State.autoClaimChests then parts[#parts + 1] = "Claim Chests" end
    if State.antiLag then parts[#parts + 1] = "Anti Lag" end
    if #parts == 0 then return "Idle - nothing running" end
    return table.concat(parts, " | ")
end

spawnTask("statsUpdater", function()
    while State.running do
        local elapsed = os.time() - sessionStart
        setParagraphContent(sessionKV, string.format("%dd %dh %dm %ds",
            math.floor(elapsed / 86400),
            math.floor((elapsed % 86400) / 3600),
            math.floor((elapsed % 3600) / 60),
            elapsed % 60))
        setParagraphContent(statusParagraph, activeStatusText())
        setParagraphContent(pingKV, tostring(getPing()) .. " ms")
        for _, entry in ipairs(statNames) do
            local stat = getStat(entry[2])
            local val = tonumber(stat and stat.Value) or 0
            if baseline[entry[1]] == nil then baseline[entry[1]] = val end
            local delta = val - baseline[entry[1]]
            local sign = delta >= 0 and "+" or ""
            local text = formatNumber(val) .. " " .. sign .. formatNumber(delta)
            setParagraphContent(paraMap[entry[1]], text)
        end
        task.wait(0.5)
    end
end)

Tabs.Stats:Button({
    Title = "Reset Session Baseline",
    Callback = function()
        for _, entry in ipairs(statNames) do
            local stat = getStat(entry[2])
            baseline[entry[1]] = tonumber(stat and stat.Value) or 0
        end
        sessionStart = os.time()
        Window:Notify({ Title = "Stats", Content = "Baseline reset", Icon = "bar-chart-2", Duration = 2 })
    end,
})

-- ========== MISC ==========
Tabs.Misc:TabSection({ Title = "Performance" })
Tabs.Misc:Toggle({
    Title = "Anti Lag",
    Default = false,
    Callback = function(v) setAntiLag(v) end,
})
Tabs.Misc:Toggle({
    Title = "Hide Frames",
    Default = cfgToggle("hideFrames", false),
    Callback = function(v)
        setHideFrames(v)
        setCfgToggle("hideFrames", v)
    end,
})
Tabs.Misc:TabSection({ Title = "Auto" })
Tabs.Misc:Toggle({
    Title = "Collect Chests",
    Default = false,
    Callback = function(v) setAutoClaimChests(v) end,
})
Tabs.Misc:Toggle({
    Title = "Remove Ad Portal",
    Default = false,
    Callback = function(v) setRemovePortals(v) end,
})
Tabs.Misc:TabSection({ Title = "Window" })
Tabs.Misc:Keybind({
    Title = "Toggle UI Key",
    Default = "RightControl",
    Callback = function(k)
        pcall(function()
            if typeof(k) == "string" and Enum.KeyCode[k] then
                Window:SetToggleKey(Enum.KeyCode[k])
            end
        end)
    end,
})

Tabs.Misc:TabSection({ Title = "Background / Acrylic" })
local bgInputText = ""
Tabs.Misc:Input({
    Title = "Background Image ID",
    Placeholder = "rbxassetid or numbers only",
    Callback = function(text)
        bgInputText = tostring(text or ""):gsub("%s+", "")
    end,
})
Tabs.Misc:Button({
    Title = "Apply Background",
    Callback = function()
        if bgInputText == "" then
            Window:Notify({ Title = "Background", Content = "Enter an image id first", Icon = "image", Duration = 2 })
            return
        end
        local ok = pcall(function()
            Window:SetBackgroundImage(bgInputText, 0.3)
        end)
        Window:Notify({
            Title = "Background",
            Content = ok and "Applied" or "Failed to apply",
            Icon = ok and "check" or "x",
            Duration = 2,
        })
    end,
})
Tabs.Misc:Button({
    Title = "Clear Background",
    Callback = function()
        pcall(function() Window:ClearBackground() end)
        Window:Notify({ Title = "Background", Content = "Cleared", Icon = "image-off", Duration = 2 })
    end,
})
Tabs.Misc:Button({
    Title = "Acrylic On",
    Callback = function()
        pcall(function() Window:ToggleAcrylic(true) end)
        Window:Notify({ Title = "Acrylic", Content = "Enabled", Icon = "sparkles", Duration = 2 })
    end,
})
Tabs.Misc:Button({
    Title = "Reset Acrylic",
    Callback = function()
        pcall(function()
            Window:ToggleAcrylic(false)
            Window:SetTransparency(Window.Transparent and 0.1 or 0)
        end)
        Window:Notify({ Title = "Acrylic", Content = "Reset", Icon = "rotate-ccw", Duration = 2 })
    end,
})

Tabs.Misc:TabSection({ Title = "User" })
Tabs.Misc:Toggle({
    Title = "Show User Panel",
    Default = true,
    Callback = function(v)
        pcall(function() Window:UserEnabled(v == true) end)
    end,
})
Tabs.Misc:Toggle({
    Title = "Anonymous",
    Default = true,
    Callback = function(v)
        pcall(function() Window:Anonymous(v == true) end)
    end,
})

-- Refresh player lists on join/leave
track(Players.PlayerAdded:Connect(function()
    task.defer(function()
        local list = playerList()
        pcall(function()
            if killPlayerDropdown and killPlayerDropdown.SetValues then
                killPlayerDropdown:SetValues(list)
            end
        end)
        pcall(function()
            if viewPlayerDropdown and viewPlayerDropdown.SetValues then
                viewPlayerDropdown:SetValues(list)
            end
        end)
    end)
end))
track(Players.PlayerRemoving:Connect(function(p)
    if State.spyTarget == p.Name then setSpy(false) end
    if State.kill.target == p.Name then State.setTargetKill(false) end
end))

-- restaura rock salva
task.defer(function()
    if State._savedRockName then
        for _, rock in ipairs(Config.Rocks) do
            if rock.name == State._savedRockName then
                setRockSelection(rock)
                break
            end
        end
    end
    if cfgToggle("antiStun", false) then
        State.setAntiKnockback(true)
    end

end)

-- Open
task.wait(0.08)
pcall(function()
    Window._SavedTabIndex = Window._SavedTabIndex or 1
    Window:SelectTab(Window._SavedTabIndex or 1)
end)
pcall(function() Window:Open() end)

print("[Muscle Legends Script] By Slowzzx4 - Loaded")

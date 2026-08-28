--[[
    Muscle Legends Script
    By Slowzzx4 (Pure Farm & Perfect Rock Cache Edition)
    - Kills completely removed
    - Advanced Rock Cache (Restores Size, CFrame, GUIs, Particles flawlessly)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========== Save System ==========
local SaveFileName = "MuscleLegends_Slowzzx4_Save.json"
local SaveData = {}

if isfile and isfile(SaveFileName) then
    local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(SaveFileName)) end)
    if success and type(decoded) == "table" then SaveData = decoded end
end

local function GetSave(key, default)
    if SaveData[key] == nil then return default end
    return SaveData[key]
end

local function SetSave(key, value)
    SaveData[key] = value
    if writefile then pcall(function() writefile(SaveFileName, HttpService:JSONEncode(SaveData)) end) end
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
        { name = "Industrial Rock", exactName = "Industrial Rock", durability = math.huge },
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
        { "Industrial Gym", Vector3.new(-5198, 57, 4942) },
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
    }
}

local PROTEIN_ITEMS = { { tool = "TOUGH Bar", event = "toughBar" }, { tool = "ULTRA Shake", event = "ultraShake" }, { tool = "Energy Shake", event = "energyShake" }, { tool = "Protein Shake", event = "proteinShake" }, { tool = "Energy Bar", event = "energyBar" }, { tool = "Protein Bar", event = "proteinBar" } }

-- ========== State ==========
local State = {
    running = true, fastPunch = false, selectedRock = nil, rockGeneration = 0,
    autoWeight = false, autoHandstands = false, autoLift = false, autoSitups = false,
    hideDurability = false, mainAutoSize = false, mainAutoSpeed = false,
    mainSize = 2, mainSpeed = 125, infiniteJump = false, fastSpeed = false,
    spin = false, spy = false, spyTarget = nil,
    rebirth = { objective = 0, autoRebirth = false, infinite = false, sizeOne = false, fastWeight = false, king = false, lockPosition = false, lockCFrame = nil },
    exerciseMovement = { active = {}, humanoid = nil, walkSpeed = nil, jumpValue = nil, usesJumpPower = true },
}

local taskHandles, connections = {}, {}
local function cancelTask(name) if taskHandles[name] then pcall(task.cancel, taskHandles[name]) taskHandles[name] = nil end end
local function spawnTask(name, fn) cancelTask(name) taskHandles[name] = task.spawn(function() pcall(fn) taskHandles[name] = nil end) return taskHandles[name] end
local function track(conn) connections[#connections + 1] = conn return conn end

-- ========== Permanent Always-On Functions ==========
workspace.DescendantAdded:Connect(function(obj)
    if obj and string.match(string.lower(obj.Name), "portal|ad|sponsor|advert") then
        task.defer(function() pcall(function() obj:Destroy() end) end)
    end
end)
for _, obj in ipairs(workspace:GetDescendants()) do
    if string.match(string.lower(obj.Name), "portal|ad|sponsor|advert") then pcall(function() obj:Destroy() end) end
end

spawnTask("permanentPreventRebirth", function()
    while State.running do
        pcall(function()
            local btn = PlayerGui:FindFirstChild("gameGui") and PlayerGui.gameGui:FindFirstChild("rebirthMenu") and PlayerGui.gameGui.rebirthMenu:FindFirstChild("confirmButton")
            if btn then btn.Visible = false btn.Active = false end
        end)
        task.wait(1)
    end
end)

-- ========== Helpers ==========
local function getCharacter() return LocalPlayer.Character end
local function getHumanoid() local char = getCharacter() return char and char:FindFirstChildWhichIsA("Humanoid") end
local function getHRP() local char = getCharacter() return char and char:FindFirstChild("HumanoidRootPart") end

local function formatNumber(n)
    n = tonumber(n) or 0
    local neg = n < 0
    local v = math.abs(n)
    local units = { { 1e18, "QI" }, { 1e15, "QA" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
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

-- ========== Advanced Rock Cache & Hide System ==========
local rockCache, capturedRock = {}, nil

local function cacheRock(rock)
    if not rock or rockCache[rock] then return end
    local childrenToHide = {}
    
    -- Cache effects directly inside the Rock
    for _, x in ipairs(rock:GetChildren()) do
        if x:IsA("GuiObject") or x:IsA("SurfaceGui") or x:IsA("BillboardGui") or x:IsA("ParticleEmitter") or x.Name:lower():match("particle") or x.Name:lower():match("emitter") then
            childrenToHide[x] = x.Parent
        end
    end

    -- Cache sibling GUIs (like the rockGui in the Machine folder)
    if rock.Parent then
        for _, x in ipairs(rock.Parent:GetChildren()) do
            if x:IsA("GuiObject") or x:IsA("SurfaceGui") or x:IsA("BillboardGui") or x.Name:lower():match("gui") then
                childrenToHide[x] = x.Parent
            end
        end
    end

    rockCache[rock] = { 
        rockCFrame = rock.CFrame, 
        transparency = rock.Transparency,
        size = rock.Size,
        canCollide = rock.CanCollide,
        touchCFrame = rock:FindFirstChild("TouchPart") and rock.TouchPart.CFrame or nil,
        children = childrenToHide
    }
end

local function restoreAllRocks()
    for rock, cached in pairs(rockCache) do
        if rock and rock.Parent then
            pcall(function()
                rock.Transparency = cached.transparency
                rock.Size = cached.size
                rock.CanCollide = cached.canCollide
                rock.CFrame = cached.rockCFrame
                local touch = rock:FindFirstChild("TouchPart")
                if touch and cached.touchCFrame then touch.CFrame = cached.touchCFrame end
                
                -- Restore all GUIs and Particles
                for child, parent in pairs(cached.children) do 
                    pcall(function() child.Parent = parent end) 
                end
            end)
        end
    end
    table.clear(rockCache)
    capturedRock = nil
end

local function hideAllSelectedRocks(rockDef)
    if not rockDef then return end
    local folder = workspace:FindFirstChild("machinesFolder")
    if not folder then return end
    
    local foundOne = nil
    for _, item in pairs(folder:GetDescendants()) do
        local rock = nil
        if rockDef.exactName and item.Name == rockDef.exactName then
            rock = item:FindFirstChild("Rock")
        elseif not rockDef.exactName and item.Name == "neededDurability" and item:IsA("ValueBase") and tonumber(item.Value) == tonumber(rockDef.durability) then
            rock = item.Parent and item.Parent:FindFirstChild("Rock")
        end
        
        if rock and rock:IsA("BasePart") then
            if not foundOne then foundOne = rock end
            if not rockCache[rock] then cacheRock(rock) end
            
            pcall(function()
                rock.Transparency = 1
                rock.CanCollide = false
                -- Hide all GUIs and Particles
                for child, _ in pairs(rockCache[rock].children) do child.Parent = nil end
            end)
        end
    end
    return foundOne
end

local function attachRockToHand()
    local selected = State.selectedRock
    if not selected then return end
    local char = getCharacter()
    local left, right = char and char:FindFirstChild("LeftHand"), char and char:FindFirstChild("RightHand")
    if not left or not right then return end
    
    local rock = hideAllSelectedRocks(selected)
    if not rock then return end
    capturedRock = rock
    
    pcall(function()
        rock.Size = Vector3.new(2, 1, 1) -- Set small size ONLY for the attached one
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
                if punch then local at = punch:FindFirstChild("attackTime") if at then at.Value = 0 end end
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
            task.wait(0.4)
        end
    end)
end

local function setFastPunch(enabled)
    State.fastPunch = enabled == true
    if not punchSystemActive() then if not State.fastPunch then restoreAllRocks() end stopPunchTasks() return end
    startPunchTasks()
end

local function setRockSelection(rockOrNil)
    restoreAllRocks()
    State.selectedRock = rockOrNil
    if rockOrNil then startPunchTasks() pcall(function() attachRockToHand() equipPunch() end) else if not State.fastPunch then stopPunchTasks() end end
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

-- ========== Hide Durability ==========
local durabilityHidden = {}
local durabilityConns = {}
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
        durabilityConns[#durabilityConns + 1] = ReplicatedStorage.ChildAdded:Connect(function(obj) if State.hideDurability then task.defer(hideDurabilityObject, obj) end end)
        durabilityConns[#durabilityConns + 1] = PlayerGui.DescendantAdded:Connect(function(obj) if State.hideDurability then task.defer(hideDurabilityObject, obj) end end)
    else
        for obj, vis in pairs(durabilityHidden) do if obj and obj.Parent then pcall(function() obj.Visible = vis end) end end
        table.clear(durabilityHidden)
    end
end

-- ========== Macros / Rebirth ==========
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
    if remote then pcall(function() if remote:IsA("RemoteFunction") then remote:InvokeServer("rebirthRequest") remote:InvokeServer("rebirth") else remote:FireServer("rebirthRequest") remote:FireServer("rebirth") end end) end
end

local FastFarm = { mode = nil }
function FastFarm:Stop() self.mode = nil cancelTask("fastFarmMain") end
function FastFarm:Start(mode)
    self:Stop() self.mode = mode
    spawnTask("fastFarmMain", function()
        setSizeOne()
        while State.running and self.mode == mode do
            pcall(function()
                local tool = equipTool({"Weight", "Heavy Weight"})
                if tool then
                    local ev = LocalPlayer:FindFirstChild("muscleEvent")
                    if ev then for _=1, 3 do ev:FireServer("rep") end end
                end
                if mode == "rebirth" then requestRebirth() end
            end)
            task.wait(0.05)
        end
    end)
end

-- ========== Loop Movimento & Limpeza de Animação ==========
local spinAngular, spinHum, spinAutoRotate = nil, nil, nil
local function clearSpin() if spinAngular then spinAngular:Destroy() spinAngular = nil end if spinHum then spinHum.AutoRotate = spinAutoRotate spinHum = nil end end

track(RunService.Heartbeat:Connect(function()
    if not State.running then return end
    local hum, hrp = getHumanoid(), getHRP()
    
    if hum then
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local n = track.Name:lower()
            if n:match("punch") or n:match("attack") then track:Stop() end
        end
    end
    
    if State.fastSpeed and hum then hum.WalkSpeed = 1000 end
    
    if State.spin and hrp and hum then
        if not spinAngular or spinAngular.Parent ~= hrp then
            clearSpin() spinHum, spinAutoRotate, hum.AutoRotate = hum, hum.AutoRotate, false
            spinAngular = Instance.new("BodyAngularVelocity")
            spinAngular.Name, spinAngular.AngularVelocity, spinAngular.MaxTorque, spinAngular.P, spinAngular.Parent = "Spin", Vector3.new(0, 7, 0), Vector3.new(0, 9e9, 0), 6000, hrp
        end
    elseif spinAngular then clearSpin() end
end))

track(UserInputService.JumpRequest:Connect(function() if State.infiniteJump then local h = getHumanoid() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))

-- ========== VOID UI ==========
local userEnabledFlag = GetSave("UserEnabled", true) == true
local userAnonFlag = GetSave("UserAnon", true) == true

local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/slowzzx4-8/Ui-library/refs/heads/main/Void%20Ui%20Library.lua"))()
local Window = VoidUI:CreateWindow({
    Name = "Muscle Legends", Icon = "dumbbell", SideBarWidth = 160, Theme = "Dark",
    Transparent = true, Author = "By Slowzzx4", User = { Enabled = userEnabledFlag, Anonymous = userAnonFlag }, Folder = "MuscleLegendsScript",
})

Window:EditOpenButton({ Title = "Muscle Legends", Icon = "dumbbell", Transparency = 0.2, StrokeThickness = 1.2, AutoRotation = false, Speed = 12, CornerRadius = UDim.new(0, 16) })

local Tabs = { 
    Main = Window:Tab({ Title = "Home", Icon = "house", Border = true }), 
    AutoFarm = Window:Tab({ Title = "Auto Farm", Icon = "sprout", Border = true }), 
    Rebirths = Window:Tab({ Title = "Auto Rebirth", Icon = "refresh-cw", Border = true }), 
    Rewards = Window:Tab({ Title = "Rewards", Icon = "gift", Border = true }), 
    Teleports = Window:Tab({ Title = "Teleports", Icon = "map-pin", Border = true }), 
    Stats = Window:Tab({ Title = "Stats", Icon = "activity", Border = true }), 
    Misc = Window:Tab({ Title = "Misc", Icon = "settings", Border = true }) 
}

-- ========== MAIN ==========
Tabs.Main:TabSection({ Title = "Size / Speed" })
Tabs.Main:Slider({ Title = "Size", Value = { Min = 1, Max = 100, Default = GetSave("MainSize", 2) }, Step = 0.1, Callback = function(v) State.mainSize = v SetSave("MainSize", v) if State.mainAutoSize then applySizeOrSpeed("changeSize", v) end end })
Tabs.Main:Toggle({ Title = "Auto Size", Default = GetSave("MainAutoSize", false), Callback = function(v) State.mainAutoSize = v SetSave("MainAutoSize", v) cancelTask("mainAutoSize") if v then spawnTask("mainAutoSize", function() while State.running and State.mainAutoSize do applySizeOrSpeed("changeSize", State.mainSize) task.wait(0.35) end end) end end })
Tabs.Main:Slider({ Title = "Speed", Value = { Min = 16, Max = 500, Default = GetSave("MainSpeed", 125) }, Step = 1, Callback = function(v) State.mainSpeed = v SetSave("MainSpeed", v) if State.mainAutoSpeed then applySizeOrSpeed("changeSpeed", v) end end })
Tabs.Main:Toggle({ Title = "Auto Speed", Default = GetSave("MainAutoSpeed", false), Callback = function(v) State.mainAutoSpeed = v SetSave("MainAutoSpeed", v) cancelTask("mainAutoSpeed") if v then spawnTask("mainAutoSpeed", function() while State.running and State.mainAutoSpeed do applySizeOrSpeed("changeSpeed", State.mainSpeed) task.wait(0.35) end end) end end })
Tabs.Main:Toggle({ Title = "Walk On Water", Default = GetSave("WalkOnWater", false), Callback = function(v) SetSave("WalkOnWater", v) setWalkWater(v) end })
Tabs.Main:Toggle({ Title = "Infinite Jump", Default = GetSave("InfiniteJump", false), Callback = function(v) SetSave("InfiniteJump", v) State.infiniteJump = v end })
Tabs.Main:Toggle({ Title = "Spin Character", Default = GetSave("SpinChar", false), Callback = function(v) SetSave("SpinChar", v) State.spin = v end })

-- ========== AUTO FARM ==========
Tabs.AutoFarm:TabSection({ Title = "Rocks" })
local rockNames, rockByName = {}, {}
for _, r in ipairs(Config.Rocks) do rockNames[#rockNames + 1] = r.name rockByName[r.name] = r end
local selectedRockName = GetSave("SelectRock", rockNames[1])
Tabs.AutoFarm:Dropdown({ Title = "Select Rock", Option = rockNames, Value = selectedRockName, Callback = function(v) selectedRockName = v SetSave("SelectRock", v) if State._autoRock then setRockSelection(rockByName[v]) end end })
Tabs.AutoFarm:Toggle({ Title = "Auto Rock", Default = GetSave("AutoRock", false), Callback = function(v) State._autoRock = v SetSave("AutoRock", v) setRockSelection(v and rockByName[selectedRockName] or nil) end })
Tabs.AutoFarm:Toggle({ Title = "Fast Punch", Default = GetSave("FastPunch", false), Callback = function(v) SetSave("FastPunch", v) setFastPunch(v) end })

Tabs.AutoFarm:TabSection({ Title = "Brawl" })
Tabs.AutoFarm:Toggle({ Title = "Auto Join Brawl", Default = GetSave("AutoJoinBrawl", false), Callback = function(v) State._autoBrawl = v SetSave("AutoJoinBrawl", v) cancelTask("autoBrawlJoin") if v then spawnTask("autoBrawlJoin", function() while State.running and State._autoBrawl do pcall(function() local lbl = PlayerGui:FindFirstChild("gameGui") and PlayerGui.gameGui:FindFirstChild("brawlJoinLabel") if lbl and lbl.Visible then ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl") task.wait(3) end end) task.wait(0.5) end end) end end })

Tabs.AutoFarm:TabSection({ Title = "Exercises" })
Tabs.AutoFarm:Toggle({ Title = "Auto Use Tools", Default = GetSave("AutoUseTools", false), Callback = function(v) State.autoUseTools = v SetSave("AutoUseTools", v) cancelTask("autoUseTools") if v then spawnTask("autoUseTools", function() while State.running and State.autoUseTools do pcall(function() local ev = LocalPlayer:FindFirstChild("muscleEvent") if ev then for _=1,3 do ev:FireServer("rep") end end end) task.wait(0.18) end end) end end })
for _, def in ipairs({ {"Auto Handstands", "autoHandstands", {"Handstands", "Handstand"}}, {"Auto Situps", "autoSitups", {"Situps", "Situp"}}, {"Auto Weight", "autoWeight", {"Weight"}}, {"Auto Lift", "autoLift", {"Pushup", "Pushups"}} }) do
    Tabs.AutoFarm:Toggle({ Title = def[1], Default = GetSave(def[2], false), Callback = function(v) SetSave(def[2], v) setExercise(def[2], v, def[3], 0.05) end })
end

-- ========== REBIRTHS ==========
Tabs.Rebirths:TabSection({ Title = "Fast Farm" })
Tabs.Rebirths:Toggle({ Title = "Fast Rebirth", Default = false, Callback = function(v) if v then FastFarm:Start("rebirth") else FastFarm:Stop() end end })
Tabs.Rebirths:Toggle({ Title = "Fast Strength", Default = false, Callback = function(v) if v then FastFarm:Start("strength") else FastFarm:Stop() end end })

Tabs.Rebirths:TabSection({ Title = "Auto Rebirth" })
Tabs.Rebirths:Input({ Title = "Rebirth Objective", Placeholder = "18980", Default = nil, Value = nil, Callback = function(text) local num = tonumber(string.match(tostring(text or ""), "%d+")) State.rebirth.objective = num or 0 end })
Tabs.Rebirths:Toggle({ Title = "Auto Rebirth", Default = false, Callback = function(v) State.rebirth.autoRebirth = v if v then State.rebirth.infinite = false end cancelTask("smartAutoRebirthTask") if v then spawnTask("smartAutoRebirthTask", function() while State.running and State.rebirth.autoRebirth do pcall(function() local rStat = tonumber(LocalPlayer.leaderstats.Rebirths.Value) or 0 if State.rebirth.objective > 0 and rStat >= State.rebirth.objective then State.rebirth.autoRebirth = false return end requestRebirth() end) task.wait(1.5) end end) end end })
Tabs.Rebirths:Toggle({ Title = "Infinite Rebirths", Default = false, Callback = function(v) State.rebirth.infinite = v if v then State.rebirth.autoRebirth = false end cancelTask("rebirthLoop") if v then spawnTask("rebirthLoop", function() while State.running and State.rebirth.infinite do requestRebirth() task.wait(0.1) end end) end end })

Tabs.Rebirths:TabSection({ Title = "Extras" })
Tabs.Rebirths:Toggle({ Title = "Auto Muscle King", Default = false, Callback = function(v) State.rebirth.king = v cancelTask("rebirthKing") if v then local kingPos = Vector3.new(-8646, 13.25, -5738) spawnTask("rebirthKing", function() while State.running and State.rebirth.king do local hrp = getHRP() if hrp and (hrp.Position - kingPos).Magnitude > 42 then hrp.CFrame = CFrame.new(kingPos) hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero end task.wait(0.2) end end) end end })
Tabs.Rebirths:Toggle({ Title = "Auto Lock Position", Default = false, Callback = function(v) State.rebirth.lockPosition = v local hrp = getHRP() State.rebirth.lockCFrame = v and hrp and hrp.CFrame or nil cancelTask("rebirthLock") if v and State.rebirth.lockCFrame then spawnTask("rebirthLock", function() while State.running and State.rebirth.lockPosition do local h = getHRP() if h and State.rebirth.lockCFrame then h.CFrame = State.rebirth.lockCFrame h.AssemblyLinearVelocity = Vector3.zero h.AssemblyAngularVelocity = Vector3.zero end RunService.Heartbeat:Wait() end end) end end })

-- ========== REWARDS ==========
Tabs.Rewards:TabSection({ Title = "Fortune" })
Tabs.Rewards:Toggle({ Title = "Spin Wheel", Default = GetSave("SpinWheel", false), Callback = function(v) State.autoSpinWheel = v SetSave("SpinWheel", v) cancelTask("fortuneWheel") if v then spawnTask("fortuneWheel", function() while State.running and State.autoSpinWheel do pcall(function() local wheelGui = PlayerGui:FindFirstChild("fortuneWheelMenuGui") if not wheelGui then return end local spinLabel = wheelGui:FindFirstChild("spinAmountLabel", true) if not spinLabel or not spinLabel.Text then return end local text = tostring(spinLabel.Text) local spinsLeft = 0 if text:lower():find("inf", 1, true) or text:find("∞") then spinsLeft = math.huge else spinsLeft = tonumber(string.match(text, "%d+")) or 0 end if spinsLeft >= 1 then ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer("openFortuneWheel", ReplicatedStorage.shared.catalogs.fortuneWheelChances["Fortune Wheel"]) end end) task.wait(1.5) end end) end end })

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

-- ========== MISC ==========
Tabs.Misc:TabSection({ Title = "Performance" })
Tabs.Misc:Toggle({ Title = "Hide Durability", Default = GetSave("HideDurability", false), Callback = function(v) SetSave("HideDurability", v) setHideDurability(v) end })

Tabs.Misc:TabSection({ Title = "Protein" })
local proteinNamesList = {}
for _, def in ipairs(PROTEIN_ITEMS) do proteinNamesList[#proteinNamesList + 1] = def.tool end
Tabs.Misc:Dropdown({ Title = "Select Protein Items", Option = proteinNamesList, Multi = true, Value = GetSave("SelectedProteinItems", nil), Callback = function(v) local map = {} if type(v) == "table" then for _, name in ipairs(v) do map[name] = true end elseif type(v) == "string" then map[v] = true end State.selectedProteinItems = map SetSave("SelectedProteinItems", v) end })
Tabs.Misc:Toggle({ Title = "Auto Eat Protein", Default = GetSave("AutoEatProtein", false), Callback = function(v) State.autoEatProtein = v SetSave("AutoEatProtein", v) cancelTask("autoEatProtein") if v then spawnTask("autoEatProtein", function() while State.running and State.autoEatProtein do pcall(function() local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent") if not muscleEvent then return end local selected = State.selectedProteinItems if type(selected) ~= "table" or next(selected) == nil then return end for _, def in ipairs(PROTEIN_ITEMS) do if selected[def.tool] then local tool = equipTool({def.tool}) if tool then muscleEvent:FireServer(def.event, tool) end end end end) task.wait(0.28) end end) end end })

Tabs.Misc:TabSection({ Title = "Window Settings" })
Tabs.Misc:Toggle({ Title = "Enable User Profile", Default = GetSave("UserEnabled", true), Callback = function(v) SetSave("UserEnabled", v == true) Window:Notify({Title = "Notice", Content = "Setting Saved. Re-execute script to apply.", Duration = 3}) end })
Tabs.Misc:Toggle({ Title = "Anonymous Mode", Default = GetSave("UserAnon", true), Callback = function(v) SetSave("UserAnon", v == true) Window:Notify({Title = "Notice", Content = "Setting Saved. Re-execute script to apply.", Duration = 3}) end })

-- ========== INICIALIZAÇÃO DE SALVAMENTO ==========
local function initSavedState()
    if GetSave("MainAutoSize", false) then State.mainAutoSize = true spawnTask("mainAutoSize", function() while State.running and State.mainAutoSize do applySizeOrSpeed("changeSize", State.mainSize) task.wait(0.35) end end) end
    if GetSave("MainAutoSpeed", false) then State.mainAutoSpeed = true spawnTask("mainAutoSpeed", function() while State.running and State.mainAutoSpeed do applySizeOrSpeed("changeSpeed", State.mainSpeed) task.wait(0.35) end end) end
    if GetSave("WalkOnWater", false) then setWalkWater(true) end
    if GetSave("InfiniteJump", false) then State.infiniteJump = true end
    if GetSave("SpinChar", false) then State.spin = true end
    if GetSave("AutoRock", false) then State._autoRock = true setRockSelection(rockByName[selectedRockName]) end
    if GetSave("FastPunch", false) then setFastPunch(true) end
    if GetSave("AutoJoinBrawl", false) then State._autoBrawl = true spawnTask("autoBrawlJoin", function() while State.running and State._autoBrawl do pcall(function() local lbl = PlayerGui:FindFirstChild("gameGui") and PlayerGui.gameGui:FindFirstChild("brawlJoinLabel") if lbl and lbl.Visible then ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl") task.wait(3) end end) task.wait(0.5) end end) end
    if GetSave("AutoUseTools", false) then State.autoUseTools = true spawnTask("autoUseTools", function() while State.running and State.autoUseTools do pcall(function() local ev = LocalPlayer:FindFirstChild("muscleEvent") if ev then for _=1,3 do ev:FireServer("rep") end end end) task.wait(0.18) end end) end
    if GetSave("autoHandstands", false) then setExercise("autoHandstands", true, {"Handstands", "Handstand"}, 0.05) end
    if GetSave("autoSitups", false) then setExercise("autoSitups", true, {"Situps", "Situp"}, 0.05) end
    if GetSave("autoWeight", false) then setExercise("autoWeight", true, {"Weight"}, 0.05) end
    if GetSave("autoLift", false) then setExercise("autoLift", true, {"Pushup", "Pushups"}, 0.05) end
    if GetSave("AutoEatProtein", false) then State.autoEatProtein = true spawnTask("autoEatProtein", function() while State.running and State.autoEatProtein do pcall(function() local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent") if not muscleEvent then return end local selected = State.selectedProteinItems if type(selected) ~= "table" or next(selected) == nil then return end for _, def in ipairs(PROTEIN_ITEMS) do if selected[def.tool] then local tool = equipTool({def.tool}) if tool then muscleEvent:FireServer(def.event, tool) end end end end) task.wait(0.28) end end) end
    if GetSave("SpinWheel", false) then State.autoSpinWheel = true spawnTask("fortuneWheel", function() while State.running and State.autoSpinWheel do pcall(function() local wheelGui = PlayerGui:FindFirstChild("fortuneWheelMenuGui") if not wheelGui then return end local spinLabel = wheelGui:FindFirstChild("spinAmountLabel", true) if not spinLabel or not spinLabel.Text then return end local text = tostring(spinLabel.Text) local spinsLeft = 0 if text:lower():find("inf", 1, true) or text:find("∞") then spinsLeft = math.huge else spinsLeft = tonumber(string.match(text, "%d+")) or 0 end if spinsLeft >= 1 then ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer("openFortuneWheel", ReplicatedStorage.shared.catalogs.fortuneWheelChances["Fortune Wheel"]) end end) task.wait(1.5) end end) end
    if GetSave("HideDurability", false) then setHideDurability(true) end
end
initSavedState()

task.wait(0.08) pcall(function() Window:SelectTab(1) Window:Open() end)
print("[Muscle Legends] Flawless Farm Edition Loaded")
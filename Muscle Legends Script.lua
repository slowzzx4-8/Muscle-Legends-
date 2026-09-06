--[[
    Muscle Legends Script
    By Slowzzx4
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========== Save ==========
local SaveFileName = "MuscleLegends_Slowzzx4_Save.json"
local SaveData = {}
if isfile and isfile(SaveFileName) then
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(SaveFileName))
    end)
    if ok and type(decoded) == "table" then SaveData = decoded end
end

local function GetSave(key, default)
    if SaveData[key] == nil then return default end
    return SaveData[key]
end

local function SetSave(key, value)
    SaveData[key] = value
    if writefile then
        pcall(function()
            writefile(SaveFileName, HttpService:JSONEncode(SaveData))
        end)
    end
end

-- ========== Anti AFK ==========
do
    local g = getgenv and getgenv() or _G
    g.Young0xPersistentAntiAfk = g.Young0xPersistentAntiAfk or {}
    if not g.Young0xPersistentAntiAfk.connection or not g.Young0xPersistentAntiAfk.connection.Connected then
        g.Young0xPersistentAntiAfk.connection = LocalPlayer.Idled:Connect(function()
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
        { name = "Industrial Rock", exactName = "Industrial Rock", durability = 25000000 },
        { name = "Ancient Rock", exactName = "Ancient Jungle Rock", durability = 10000000 },
        { name = "Muscle King Rock", exactName = "Muscle King Mountain", durability = 5000000 },
        { name = "Legend Rock", exactName = "Rock Of Legends", durability = 1000000 },
        { name = "Inferno Rock", exactName = "Inferno Rock", durability = 800000 },
        { name = "Eternal Rock", durability = 750000 },
        { name = "Mythical Rock", durability = 400000 },
        { name = "Frost Rock", exactName = "Frozen Rock", durability = 150000 },
        { name = "Punching Rock", exactName = "Punching Rock", durability = 50000 },
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
    autoWeight = false,
    autoHandstands = false,
    autoLift = false,
    autoSitups = false,
    mainAutoSize = false,
    mainAutoSpeed = false,
    mainSize = 2,
    mainSpeed = 125,
    infiniteJump = false,
    fastSpeed = false,
    spin = false,
    walkWater = false,
    autoUseTools = false,
    autoEatProtein = false,
    autoSpinWheel = false,
    autoClaimGifts = false,
    autoUseCodes = false,
    autoWinBrawl = false,
    selectedProteinItems = {},
    _autoRock = false,
    _autoBrawl = false,
    rebirth = {
        objective = 0,
        autoRebirth = false,
        infinite = false,
        king = false,
        lockPosition = false,
        lockCFrame = nil,
    },
    exerciseMovement = {
        active = {},
        humanoid = nil,
        walkSpeed = nil,
    },
}

local taskHandles, connections = {}, {}

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

local function track(conn)
    connections[#connections + 1] = conn
    return conn
end

workspace.DescendantAdded:Connect(function(obj)
    if obj and string.match(string.lower(obj.Name), "portal|ad|sponsor|advert") then
        task.defer(function() pcall(function() obj:Destroy() end) end)
    end
end)
for _, obj in ipairs(workspace:GetDescendants()) do
    if string.match(string.lower(obj.Name), "portal|ad|sponsor|advert") then
        pcall(function() obj:Destroy() end)
    end
end

spawnTask("permanentPreventRebirth", function()
    while State.running do
        pcall(function()
            local btn = PlayerGui:FindFirstChild("gameGui")
                and PlayerGui.gameGui:FindFirstChild("rebirthMenu")
                and PlayerGui.gameGui.rebirthMenu:FindFirstChild("confirmButton")
            if btn then
                btn.Visible = false
                btn.Active = false
            end
        end)
        task.wait(1)
    end
end)

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

local function equipTool(names)
    local char, hum = getCharacter(), getHumanoid()
    if not char or not hum then return nil end
    local lower = {}
    for _, n in ipairs(names) do
        lower[n:lower()] = true
    end
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

local function getFireTouch()
    local ft = rawget(_G, "firetouchinterest") or (typeof(firetouchinterest) == "function" and firetouchinterest)
    if type(ft) == "function" then return ft end
    local ok, v = pcall(function()
        return getgenv and getgenv().firetouchinterest
    end)
    if ok and type(v) == "function" then return v end
    return nil
end

local function doPunch(targetHrp)
    local punch = equipPunch()
    if not punch then return end
    local at = punch:FindFirstChild("attackTime")
    if at and at:IsA("ValueBase") then
        pcall(function() at.Value = 0 end)
    end
    local ev = LocalPlayer:FindFirstChild("muscleEvent")
    if ev then
        pcall(function()
            ev:FireServer("punch", "rightHand")
            ev:FireServer("punch", "leftHand")
            ev:FireServer("punch")
        end)
    end
    local handle = punch:FindFirstChild("Handle")
    local ft = getFireTouch()
    if ft and handle and targetHrp then
        pcall(ft, targetHrp, handle, 0)
        pcall(ft, targetHrp, handle, 1)
    end
end

-- ========== Rock Cache + Fake Visual ==========
local rockCache = {} -- [rock] = { original data + fake }
local capturedRock = nil

local function isGuiOrVfx(obj)
    if not obj then return false end
    if obj:IsA("GuiObject") or obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then return true end
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then return true end
    local n = obj.Name:lower()
    if n:find("gui", 1, true) or n:find("particle", 1, true) or n:find("emitter", 1, true) then
        return true
    end
    return false
end

local function stripRockGuis(rock)
    if not rock then return end
    -- remove GUIs/VFX dentro da rock
    for _, x in ipairs(rock:GetDescendants()) do
        if isGuiOrVfx(x) then
            pcall(function() x:Destroy() end)
        end
    end
    -- remove GUIs irmaos no parent (machine)
    if rock.Parent then
        for _, x in ipairs(rock.Parent:GetChildren()) do
            if isGuiOrVfx(x) then
                pcall(function() x:Destroy() end)
            end
        end
        for _, x in ipairs(rock.Parent:GetDescendants()) do
            if isGuiOrVfx(x) then
                pcall(function() x:Destroy() end)
            end
        end
    end
end

local function makeFakeRock(rock)
    if not rock or not rock:IsA("BasePart") then return nil end
    local fake = rock:Clone()
    fake.Name = rock.Name .. "_FakeVisual"
    fake.Anchored = true
    fake.CanCollide = false
    fake.CanQuery = false
    fake.CanTouch = false
    fake.CFrame = rock.CFrame
    fake.Size = rock.Size
    fake.Transparency = rock.Transparency
    -- remove scripts/remotes da copia
    for _, d in ipairs(fake:GetDescendants()) do
        if d:IsA("BaseScript") or d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent") then
            pcall(function() d:Destroy() end)
        end
    end
    fake.Parent = rock.Parent or workspace
    return fake
end

local function cacheRock(rock)
    if not rock or rockCache[rock] then return end

    local childrenBackup = {}
    for _, x in ipairs(rock:GetChildren()) do
        if isGuiOrVfx(x) then
            childrenBackup[x] = { parent = x.Parent, name = x.Name }
        end
    end
    if rock.Parent then
        for _, x in ipairs(rock.Parent:GetChildren()) do
            if isGuiOrVfx(x) then
                childrenBackup[x] = { parent = x.Parent, name = x.Name }
            end
        end
    end

    local fake = makeFakeRock(rock)

    local touchPart = rock:FindFirstChild("TouchPart")
    rockCache[rock] = {
        rockCFrame = rock.CFrame,
        transparency = rock.Transparency,
        size = rock.Size,
        canCollide = rock.CanCollide,
        anchored = rock.Anchored,
        touchCFrame = touchPart and touchPart.CFrame or nil,
        touchSize = touchPart and touchPart.Size or nil,
        touchCanCollide = touchPart and touchPart.CanCollide or false,
        touchTransparency = touchPart and touchPart.Transparency or 0,
        parent = rock.Parent,
        children = childrenBackup,
        fake = fake,
    }
end

local function restoreAllRocks()
    for rock, cached in pairs(rockCache) do
        if cached.fake then
            pcall(function()
                if cached.fake and cached.fake.Parent then
                    cached.fake:Destroy()
                end
            end)
            cached.fake = nil
        end

        if rock then
            pcall(function()
                if cached.parent and rock.Parent ~= cached.parent then
                    rock.Parent = cached.parent
                end
                for _, d in ipairs(rock:GetDescendants()) do
                    if d:IsA("Weld") or d:IsA("WeldConstraint") then
                        if tostring(d.Name):find("ML_", 1, true) then
                            d:Destroy()
                        end
                    end
                end
                if rock:IsA("BasePart") then
                    rock.Anchored = true
                    pcall(function()
                        rock.AssemblyLinearVelocity = Vector3.zero
                        rock.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
                if cached.rockCFrame then
                    rock.CFrame = cached.rockCFrame
                end
                if cached.size then rock.Size = cached.size end
                if cached.transparency ~= nil then rock.Transparency = cached.transparency end
                if cached.canCollide ~= nil then rock.CanCollide = cached.canCollide end
                if cached.anchored ~= nil then rock.Anchored = cached.anchored end

                local touch = rock:FindFirstChild("TouchPart")
                if touch and touch:IsA("BasePart") then
                    touch.Anchored = true
                    pcall(function()
                        touch.AssemblyLinearVelocity = Vector3.zero
                        touch.AssemblyAngularVelocity = Vector3.zero
                    end)
                    if cached.touchCFrame then touch.CFrame = cached.touchCFrame end
                    if cached.touchSize then touch.Size = cached.touchSize end
                    if cached.touchCanCollide ~= nil then touch.CanCollide = cached.touchCanCollide end
                    if cached.touchTransparency ~= nil then touch.Transparency = cached.touchTransparency end
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
    -- Match por nome da machine (exactName) no folder + Rock filho
    if rockDef.exactName then
        local machine = folder:FindFirstChild(rockDef.exactName)
        if machine then
            local rock = machine:FindFirstChild("Rock")
            if rock and rock:IsA("BasePart") then
                if not rockCache[rock] then cacheRock(rock) end
                stripRockGuis(rock)
                foundOne = foundOne or rock
            end
            -- também procura Rock em descendants da machine
            for _, d in ipairs(machine:GetDescendants()) do
                if d.Name == "Rock" and d:IsA("BasePart") then
                    if not rockCache[d] then cacheRock(d) end
                    stripRockGuis(d)
                    foundOne = foundOne or d
                    pcall(function()
                        d.Transparency = 1
                        d.CanCollide = false
                        local touch = d:FindFirstChild("TouchPart")
                        if touch then
                            touch.Transparency = 1
                            touch.CanCollide = false
                        end
                    end)
                    local cached = rockCache[d]
                    if cached and (not cached.fake or not cached.fake.Parent) then
                        local f = makeFakeRock(d)
                        if f then
                            f.CFrame = cached.rockCFrame
                            f.Size = cached.size
                            f.Transparency = cached.transparency
                            cached.fake = f
                        end
                    end
                end
            end
        end
    end

    for _, item in pairs(folder:GetDescendants()) do
        local rock = nil
        if rockDef.exactName and item.Name == rockDef.exactName then
            rock = item:FindFirstChild("Rock")
            if not rock and item:IsA("BasePart") and item.Name == "Rock" then
                rock = item
            end
        elseif not rockDef.exactName
            and item.Name == "neededDurability"
            and item:IsA("ValueBase")
            and tonumber(item.Value) == tonumber(rockDef.durability) then
            rock = item.Parent and item.Parent:FindFirstChild("Rock")
        end

        if rock and rock:IsA("BasePart") then
            if not foundOne then foundOne = rock end
            if not rockCache[rock] then
                cacheRock(rock)
            end

            -- remove todas GUIs da rock
            stripRockGuis(rock)

            pcall(function()
                rock.Transparency = 1
                rock.CanCollide = false
                local touch = rock:FindFirstChild("TouchPart")
                if touch then
                    touch.Transparency = 1
                    touch.CanCollide = false
                end
            end)

            -- garante fake no lugar original
            local cached = rockCache[rock]
            if cached and (not cached.fake or not cached.fake.Parent) then
                local f = makeFakeRock(rock)
                if f then
                    f.CFrame = cached.rockCFrame
                    f.Size = cached.size
                    f.Transparency = cached.transparency
                    cached.fake = f
                end
            elseif cached and cached.fake then
                pcall(function()
                    cached.fake.CFrame = cached.rockCFrame
                    cached.fake.Size = cached.size
                end)
            end
        end
    end
    return foundOne
end

local function attachRockToHand()
    local selected = State.selectedRock
    if not selected then return end
    local char = getCharacter()
    local left = char and char:FindFirstChild("LeftHand")
    local right = char and char:FindFirstChild("RightHand")
    if not left or not right then return end

    local rock = hideAllSelectedRocks(selected)
    if not rock then return end
    capturedRock = rock

    pcall(function()
        rock.Transparency = 1
        rock.CanCollide = false
        rock.Size = Vector3.new(2, 1, 1)
        rock.CFrame = left.CFrame
        local touch = rock:FindFirstChild("TouchPart")
        if touch then
            touch.Transparency = 1
            touch.CFrame = left.CFrame
        end
    end)

    local ft = getFireTouch()
    if ft then
        pcall(ft, rock, right, 0)
        pcall(ft, rock, right, 1)
        pcall(ft, rock, left, 0)
        pcall(ft, rock, left, 1)
    end
    equipPunch()
end

local function punchSystemActive()
    return State.running and (State.fastPunch == true or State.selectedRock ~= nil)
end

local function stopPunchTasks()
    cancelTask("fastPunchEquip")
    cancelTask("fastPunchHit")
    cancelTask("fastPunchRock")
    -- NÃO equipa punch aqui (só reseta attackTime se já estiver equipado)
    pcall(function()
        local char = getCharacter()
        local punch = char and char:FindFirstChild("Punch")
        if punch then
            local at = punch:FindFirstChild("attackTime")
            if at then at.Value = 0.3 end
            -- unequip de volta pro backpack
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp then punch.Parent = bp end
        end
    end)
end

local function startPunchTasks()
    stopPunchTasks()

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
                local punch = getCharacter() and getCharacter():FindFirstChild("Punch")
                if punch then
                    local at = punch:FindFirstChild("attackTime")
                    if at then at.Value = 0 end
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
            task.wait(0.4)
        end
    end)
end

local function setFastPunch(enabled)
    State.fastPunch = enabled == true
    if not punchSystemActive() then
        if not State.fastPunch then
            restoreAllRocks()
        end
        stopPunchTasks()
        return
    end
    startPunchTasks()
end

local function setRockSelection(rockOrNil)
    restoreAllRocks()
    State.selectedRock = rockOrNil
    if rockOrNil then
        startPunchTasks()
        pcall(function()
            attachRockToHand()
            equipPunch()
        end)
    else
        if not State.fastPunch then
            stopPunchTasks()
        end
    end
end

-- ========== Brawl Auto Win (kill style, so no brawl) ==========
-- ========== Brawl Auto Win (TP Behind + Fast Punch) ==========
local function isInBrawlMap()
    local mapVal = LocalPlayer:FindFirstChild("currentMap")
    if not mapVal then return false end
    local v = tostring(mapVal.Value or ""):lower()
    return v:find("brawl", 1, true) ~= nil or v:find("ring", 1, true) ~= nil
end

local function runBrawlWin()
    cancelTask("brawlWin")
    if not State.autoWinBrawl then return end

    spawnTask("brawlWin", function()
        while State.running and State.autoWinBrawl do
            pcall(function()
                if not isInBrawlMap() then return end

                local myMap = LocalPlayer:FindFirstChild("currentMap")
                myMap = myMap and myMap.Value
                local myHrp = getHRP()
                local myHum = getHumanoid()
                if not myHrp or not myHum or myHum.Health <= 0 then return end

                for _, p in ipairs(Players:GetPlayers()) do
                    if not State.autoWinBrawl then break end
                    if p ~= LocalPlayer and p.Character then
                        local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        local tHum = p.Character:FindFirstChildWhichIsA("Humanoid")
                        if tHrp and tHum and tHum.Health > 0 then
                            local pMap = p:FindFirstChild("currentMap")
                            pMap = pMap and pMap.Value
                            -- mesmo mapa de brawl
                            if pMap == myMap then
                                -- TP atras do inimigo
                                myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
                                myHrp.AssemblyLinearVelocity = Vector3.zero
                                myHrp.AssemblyAngularVelocity = Vector3.zero

                                doPunch(tHrp)
                            end
                        end
                    end
                end
            end)
            task.wait(0.01)
        end
    end)
end


-- ========== ADVANCED BRAWL (areas + auto join/kill/reset) ==========
local function criarAreaInvisivel(nome, posX, posY, posZ, sizeX, sizeY, sizeZ)
    if workspace:FindFirstChild(nome) then workspace[nome]:Destroy() end
    local part = Instance.new("Part")
    part.Name = nome
    part.Size = Vector3.new(sizeX, sizeY, sizeZ)
    part.Position = Vector3.new(posX, posY, posZ)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = workspace
    return part
end

local BrawlArea1 = criarAreaInvisivel("BrawlArea1", 4465, 177, -8851, 552, 400, 548)
local BrawlArea2 = criarAreaInvisivel("BrawlArea2", -1856.5, 175, -6315, 499, 400, 496)
local BrawlArea3 = criarAreaInvisivel("BrawlArea3", 978, 177, -7433, 502, 400, 504)

local function isDentroDasAreas(posicao)
    for _, area in ipairs({BrawlArea1, BrawlArea2, BrawlArea3}) do
        local offset = area.CFrame:PointToObjectSpace(posicao)
        local size = area.Size
        if math.abs(offset.X) <= size.X/2 and math.abs(offset.Y) <= size.Y/2 and math.abs(offset.Z) <= size.Z/2 then
            return true
        end
    end
    return false
end

State.brawl = State.brawl or {
    autoJoin = false,
    autoKill = false,
    autoReset = false,
    attackMode = "Punch",
}

local modosDeAtaque = {"Punch", "Stomp", "Ground Slam"}
local alvosValidos = {}
local mapasAlvo = { ["Magma Ring"] = true, ["Desert Ring"] = true, ["Boxing Ring"] = true }
local multiplicadores = { ["k"]=1e3, ["m"]=1e6, ["b"]=1e9, ["t"]=1e12, ["q"]=1e15, ["qi"]=1e18, ["sx"]=1e21, ["sp"]=1e24 }

local function converterForca(jogador)
    if not jogador or not jogador:FindFirstChild("leaderstats") or not jogador.leaderstats:FindFirstChild("Strength") then return 0 end
    local str = string.lower(string.gsub(string.gsub(tostring(jogador.leaderstats.Strength.Value), ",", ""), " ", ""))
    local numero, sufixo = string.match(str, "^([%d%.]+)([a-z]*)$")
    if not numero then return 0 end
    return (tonumber(numero) or 0) * (multiplicadores[sufixo] or 1)
end

local function atualizarAlvos(player, nomeDoMapa)
    if not nomeDoMapa then return end
    if mapasAlvo[nomeDoMapa] and player ~= LocalPlayer then
        alvosValidos[player] = true
    else
        alvosValidos[player] = nil
    end
end

local function monitorarJogador(player)
    if player == LocalPlayer then return end
    local currentMap = player:WaitForChild("currentMap", 10)
    if currentMap then
        atualizarAlvos(player, currentMap.Value)
        currentMap:GetPropertyChangedSignal("Value"):Connect(function()
            atualizarAlvos(player, currentMap.Value)
        end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do task.spawn(monitorarJogador, player) end
Players.PlayerAdded:Connect(function(p) task.spawn(monitorarJogador, p) end)
Players.PlayerRemoving:Connect(function(p) alvosValidos[p] = nil end)

local function equiparToolBrawl(nomeTool)
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if character and backpack then
        local tool = backpack:FindFirstChild(nomeTool) or character:FindFirstChild(nomeTool)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if tool and humanoid and not character:FindFirstChild(nomeTool) then
            humanoid:EquipTool(tool)
        end
    end
end

local function atacarAlvoBrawl()
    local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
    if not muscleEvent then return end
    local mode = State.brawl.attackMode or "Punch"
    if mode == "Punch" then
        equiparToolBrawl("Punch")
        pcall(function()
            muscleEvent:FireServer("punch", "leftHand")
            muscleEvent:FireServer("punch", "rightHand")
        end)
    elseif mode == "Stomp" then
        equiparToolBrawl("Stomp")
        pcall(function() muscleEvent:FireServer("stomp") end)
    elseif mode == "Ground Slam" then
        equiparToolBrawl("Ground Slam")
        pcall(function() muscleEvent:FireServer("groundSlam") end)
    end
end

-- Auto Join loop
task.spawn(function()
    while task.wait(0.5) do
        if not State.running then break end
        if State.brawl.autoJoin then
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui and pGui:FindFirstChild("gameGui") then
                local baseChoice = pGui.gameGui:FindFirstChild("baseChoiceMenu")
                local joinLabel = pGui.gameGui:FindFirstChild("brawlJoinLabel")
                if (baseChoice and baseChoice.Visible) or (joinLabel and joinLabel.Visible) then
                    pcall(function() ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl") end)
                    task.wait(2)
                end
            end
        end
    end
end)

-- Auto Reset Win loop
task.spawn(function()
    while task.wait(0.5) do
        if not State.running then break end
        if State.brawl.autoReset then
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui and pGui:FindFirstChild("gameGui") then
                local survivorBonus = pGui.gameGui:FindFirstChild("survivorBonusLabel")
                if survivorBonus and survivorBonus.Visible then
                    local myChar = LocalPlayer.Character
                    if myChar and myChar:FindFirstChild("Humanoid") and myChar.Humanoid.Health > 0 then
                        myChar.Humanoid.Health = 0
                        task.wait(5)
                    end
                end
            end
        end
    end
end)

-- Auto Kill loop (fast, rock-style punch)
task.spawn(function()
    while task.wait(0.01) do
        if not State.running then break end
        if State.brawl.autoKill then
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui and pGui:FindFirstChild("gameGui") then
                local participationReward = pGui.gameGui:FindFirstChild("participationRewardLabel")
                if participationReward and participationReward.Visible then
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        local listaOrdenada = {}
                        for alvo, _ in pairs(alvosValidos) do
                            if alvo.Character and alvo.Character:FindFirstChild("HumanoidRootPart") and alvo.Character:FindFirstChild("Humanoid") then
                                if alvo.Character.Humanoid.Health > 0 then
                                    local targetRoot = alvo.Character.HumanoidRootPart
                                    if isDentroDasAreas(targetRoot.Position) then
                                        table.insert(listaOrdenada, {
                                            target = alvo,
                                            root = targetRoot,
                                            force = converterForca(alvo)
                                        })
                                    end
                                else
                                    alvosValidos[alvo] = nil
                                end
                            end
                        end
                        if #listaOrdenada > 0 then
                            table.sort(listaOrdenada, function(a, b) return a.force < b.force end)
                            local alvoAtual = listaOrdenada[1]
                            if alvoAtual then
                                local tChar = alvoAtual.target.Character
                                local torso = tChar and (tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("Torso") or tChar:FindFirstChild("HumanoidRootPart"))
                                local targetCF = (torso and torso.CFrame) or alvoAtual.root.CFrame
                                pcall(function()
                                    myRoot.Velocity = Vector3.new(0, 0, 0)
                                    myRoot.RotVelocity = Vector3.new(0, 0, 0)
                                    if myRoot.AssemblyLinearVelocity then
                                        myRoot.AssemblyLinearVelocity = Vector3.zero
                                        myRoot.AssemblyAngularVelocity = Vector3.zero
                                    end
                                end)
                                -- dentro do torso do player (mesmo estilo rock fast punch)
                                myRoot.CFrame = targetCF
                                -- punch rápido estilo rock (attackTime 0 + fire server)
                                local mode = State.brawl.attackMode or "Punch"
                                if mode == "Punch" then
                                    equiparToolBrawl("Punch")
                                    local punch = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Punch")
                                    if punch then
                                        local at = punch:FindFirstChild("attackTime")
                                        if at then pcall(function() at.Value = 0 end) end
                                    end
                                    local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                                    if muscleEvent then
                                        pcall(function()
                                            muscleEvent:FireServer("punch", "rightHand")
                                            muscleEvent:FireServer("punch", "leftHand")
                                            muscleEvent:FireServer("punch")
                                        end)
                                    end
                                    local ft = getFireTouch and getFireTouch() or nil
                                    local handle = punch and punch:FindFirstChild("Handle")
                                    if ft and handle and torso then
                                        pcall(ft, torso, handle, 0)
                                        pcall(ft, torso, handle, 1)
                                    end
                                else
                                    atacarAlvoBrawl()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)


-- ========== Exercises ==========
local function setExercise(key, enabled, toolNames, delay)
    State[key] = enabled == true
    local em = State.exerciseMovement
    em.active[key] = State[key] or nil
    local taskName = "rep_" .. key

    if not State[key] then
        cancelTask(taskName)
        local char, bp = getCharacter(), LocalPlayer:FindFirstChild("Backpack")
        if char and bp and toolNames then
            for _, n in ipairs(toolNames) do
                for _, item in ipairs(char:GetChildren()) do
                    if item:IsA("Tool") and item.Name:lower() == n:lower() then
                        pcall(function() item.Parent = bp end)
                    end
                end
            end
        end
        if next(em.active) == nil then
            cancelTask("exerciseMovement")
            if em.humanoid and em.humanoid.Parent then
                pcall(function()
                    if not State.fastSpeed and em.walkSpeed then
                        em.humanoid.WalkSpeed = em.walkSpeed
                    end
                end)
            end
            em.humanoid = nil
        end
        return
    end

    spawnTask("exerciseMovement", function()
        while State.running and next(em.active) do
            local hum, hrp = getHumanoid(), getHRP()
            if hum then
                if em.humanoid ~= hum then
                    em.humanoid = hum
                    em.walkSpeed = hum.WalkSpeed > 0 and hum.WalkSpeed or 16
                end
                if hrp then hrp.Anchored = false end
                hum.PlatformStand = false
                hum.Sit = false
                local ws = State.fastSpeed and 1000 or em.walkSpeed
                if ws and hum.WalkSpeed < ws then
                    hum.WalkSpeed = ws
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)

    spawnTask(taskName, function()
        while State.running and State[key] do
            pcall(function()
                if toolNames and #toolNames > 0 then
                    equipTool(toolNames)
                end
                local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                if muscleEvent then
                    muscleEvent:FireServer("rep")
                end
            end)
            task.wait(delay or 0.15)
        end
    end)
end

-- ========== Walk Water ==========
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
    end
end

-- ========== Size / Speed ==========
local function applySizeOrSpeed(kind, value)
    value = tonumber(value)
    if not value then return false end
    local remote = ReplicatedStorage:FindFirstChild("changeSpeedSizeRemote", true)
    if not remote then return false end
    return pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(kind, value)
        else
            remote:FireServer(kind, value)
        end
    end)
end

-- ========== Rebirth ==========
local function requestRebirth()
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("rEvents")
            and ReplicatedStorage.rEvents:FindFirstChild("rebirthRemote")
        if remote then
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer("rebirthRequest")
            else
                remote:FireServer("rebirthRequest")
            end
        end
    end)
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("rebirthEvent", true)
        if remote then remote:FireServer() end
    end)
end

local FastFarm = {}
function FastFarm:Start(mode)
    self:Stop()
    State._fastFarmMode = mode
    spawnTask("fastFarm", function()
        while State.running and State._fastFarmMode == mode do
            pcall(function()
                if mode == "rebirth" then
                    requestRebirth()
                elseif mode == "strength" then
                    local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                    if muscleEvent then
                        for _ = 1, 5 do muscleEvent:FireServer("rep") end
                    end
                end
            end)
            task.wait(mode == "rebirth" and 0.15 or 0.05)
        end
    end)
end

function FastFarm:Stop()
    State._fastFarmMode = nil
    cancelTask("fastFarm")
end

-- ========== Spin ==========
local spinAngular, spinHum, spinAutoRotate

local function clearSpin()
    if spinAngular then
        pcall(function() spinAngular:Destroy() end)
        spinAngular = nil
    end
    if spinHum and spinHum.Parent and spinAutoRotate ~= nil then
        pcall(function() spinHum.AutoRotate = spinAutoRotate end)
    end
    spinHum, spinAutoRotate = nil, nil
end

track(RunService.Heartbeat:Connect(function()
    if not State.running then return end
    local hum, hrp = getHumanoid(), getHRP()
    if State.fastSpeed and hum then hum.WalkSpeed = 1000 end
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
end))

track(UserInputService.JumpRequest:Connect(function()
    if State.infiniteJump then
        local h = getHumanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- ========== Gifts 1-8 ==========
local function claimAllGifts()
    local remote = ReplicatedStorage:FindFirstChild("rEvents")
        and ReplicatedStorage.rEvents:FindFirstChild("freeGiftClaimRemote")
    if not remote then return end
    for i = 1, 8 do
        if not State.autoClaimGifts then break end
        pcall(function()
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer("claimGift", i)
            else
                remote:FireServer("claimGift", i)
            end
        end)
        task.wait(0.5) -- 500ms anti-detect
    end
end

-- ========== UI ==========
local userEnabledFlag = GetSave("UserEnabled", true) == true
local userAnonFlag = GetSave("UserAnon", true) == true

local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/slowzzx4-8/Ui-library/refs/heads/main/Void%20Ui%20Library.lua"))()

local Window = VoidUI:CreateWindow({
    Name = "Muscle Legends",
    Icon = "dumbbell",
    SideBarWidth = 160,
    Theme = "Dark",
    Transparent = true,
    Author = "By Slowzzx4",
    User = { Enabled = userEnabledFlag, Anonymous = userAnonFlag },
    Folder = "MuscleLegendsScript",
})

Window:EditOpenButton({
    Title = "Muscle Legends",
    Icon = "dumbbell",
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 230, 230)),
    }),
    Transparency = 0.1,
    StrokeThickness = 1.2,
    AutoRotation = false,
    Speed = 12,
    CornerRadius = UDim.new(0, 16),
})

local Tabs = {
    Main = Window:Tab({ Title = "Home", Icon = "house", Border = true }),
    AutoFarm = Window:Tab({ Title = "Farm", Icon = "sprout", Border = true }),
    Rebirths = Window:Tab({ Title = "Rebirth", Icon = "refresh-cw", Border = true }),
    Brawl = Window:Tab({ Title = "Brawl", Icon = "swords", Border = true }),
    Pets = Window:Tab({ Title = "Pets", Icon = "paw-print", Border = true }),
    Rewards = Window:Tab({ Title = "Rewards", Icon = "gift", Border = true }),
    Teleports = Window:Tab({ Title = "Teleport", Icon = "map-pin", Border = true }),
    Misc = Window:Tab({ Title = "Misc", Icon = "settings", Border = true }),
}

-- Home
Tabs.Main:TabSection({ Title = "Size / Speed" })
Tabs.Main:Slider({
    Title = "Size",
    Value = { Min = 1, Max = 100, Default = GetSave("MainSize", 2) },
    Step = 0.1,
    Callback = function(v)
        State.mainSize = v
        SetSave("MainSize", v)
        if State.mainAutoSize then applySizeOrSpeed("changeSize", v) end
    end,
})
Tabs.Main:Toggle({
    Title = "Auto Size",
    Default = GetSave("MainAutoSize", false),
    Callback = function(v)
        State.mainAutoSize = v
        SetSave("MainAutoSize", v)
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
    Value = { Min = 16, Max = 500, Default = GetSave("MainSpeed", 125) },
    Step = 1,
    Callback = function(v)
        State.mainSpeed = v
        SetSave("MainSpeed", v)
        if State.mainAutoSpeed then applySizeOrSpeed("changeSpeed", v) end
    end,
})
Tabs.Main:Toggle({
    Title = "Auto Speed",
    Default = GetSave("MainAutoSpeed", false),
    Callback = function(v)
        State.mainAutoSpeed = v
        SetSave("MainAutoSpeed", v)
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
    Title = "Walk Water",
    Default = GetSave("WalkOnWater", false),
    Callback = function(v)
        SetSave("WalkOnWater", v)
        setWalkWater(v)
    end,
})
Tabs.Main:Toggle({
    Title = "Inf Jump",
    Default = GetSave("InfiniteJump", false),
    Callback = function(v)
        SetSave("InfiniteJump", v)
        State.infiniteJump = v
    end,
})
Tabs.Main:Toggle({
    Title = "Spin",
    Default = GetSave("SpinChar", false),
    Callback = function(v)
        SetSave("SpinChar", v)
        State.spin = v
    end,
})

-- Farm

-- Rock list
local rockNames, rockByName = {}, {}
for _, r in ipairs(Config.Rocks) do
    rockNames[#rockNames + 1] = r.name
    rockByName[r.name] = r
end
local selectedRockName = GetSave("SelectRock", rockNames[1]) or rockNames[1]

Tabs.AutoFarm:TabSection({ Title = "Rock" })
Tabs.AutoFarm:Dropdown({
    Title = "Rock",
    Option = rockNames,
    Value = (table.find(rockNames, selectedRockName) and selectedRockName) or rockNames[1],
    Callback = function(v)
        selectedRockName = v
        SetSave("SelectRock", v)
        if State._autoRock then
            setRockSelection(rockByName[v])
        end
    end,
})
Tabs.AutoFarm:Toggle({
    Title = "Auto Rock",
    Default = GetSave("AutoRock", false),
    Callback = function(v)
        State._autoRock = v
        SetSave("AutoRock", v)
        setRockSelection(v and rockByName[selectedRockName] or nil)
    end,
})
Tabs.AutoFarm:Toggle({
    Title = "Fast Punch",
    Default = GetSave("FastPunch", false),
    Callback = function(v)
        SetSave("FastPunch", v)
        setFastPunch(v)
    end,
})

-- Brawl controls moved to dedicated Brawl tab


Tabs.AutoFarm:TabSection({ Title = "Exercise" })
Tabs.AutoFarm:Toggle({
    Title = "Auto Tools",
    Default = GetSave("AutoUseTools", false),
    Callback = function(v)
        State.autoUseTools = v
        SetSave("AutoUseTools", v)
        cancelTask("autoUseTools")
        if v then
            spawnTask("autoUseTools", function()
                while State.running and State.autoUseTools do
                    pcall(function()
                        local ev = LocalPlayer:FindFirstChild("muscleEvent")
                        if ev then
                            for _ = 1, 3 do ev:FireServer("rep") end
                        end
                    end)
                    task.wait(0.18)
                end
            end)
        end
    end,
})

for _, def in ipairs({
    { "Auto Handstands", "autoHandstands", { "Handstands", "Handstand" } },
    { "Auto Situps", "autoSitups", { "Situps", "Situp" } },
    { "Auto Weight", "autoWeight", { "Weight" } },
    { "Auto Lift", "autoLift", { "Pushup", "Pushups" } },
}) do
    Tabs.AutoFarm:Toggle({
        Title = def[1],
        Default = GetSave(def[2], false),
        Callback = function(v)
            SetSave(def[2], v)
            setExercise(def[2], v, def[3], 0.15)
        end,
    })
end


-- ========== BRAWL TAB ==========
Tabs.Brawl:TabSection({ Title = "Auto Brawl" })
Tabs.Brawl:Dropdown({
    Title = "Modo de Ataque",
    Option = modosDeAtaque,
    Value = (function()
        local s = GetSave("BrawlAttackMode", modosDeAtaque[1])
        return table.find(modosDeAtaque, s) and s or modosDeAtaque[1]
    end)(),
    Callback = function(v)
        State.brawl.attackMode = v
        SetSave("BrawlAttackMode", v)
    end,
})
Tabs.Brawl:Toggle({
    Title = "Auto Join Brawl",
    Default = GetSave("BrawlAutoJoin", false),
    Callback = function(v)
        State.brawl.autoJoin = v == true
        SetSave("BrawlAutoJoin", v == true)
    end,
})
Tabs.Brawl:Toggle({
    Title = "Auto Kill",
    Default = GetSave("BrawlAutoKill", false),
    Callback = function(v)
        State.brawl.autoKill = v == true
        SetSave("BrawlAutoKill", v == true)
    end,
})
Tabs.Brawl:Toggle({
    Title = "Auto Reset Win",
    Default = GetSave("BrawlAutoReset", false),
    Callback = function(v)
        State.brawl.autoReset = v == true
        SetSave("BrawlAutoReset", v == true)
    end,
})
Tabs.Brawl:TabSection({ Title = "Legacy" })
Tabs.Brawl:Toggle({
    Title = "Auto Win Brawl (Legacy TP)",
    Default = GetSave("AutoWinBrawl", false),
    Callback = function(v)
        State.autoWinBrawl = v == true
        SetSave("AutoWinBrawl", v == true)
        runBrawlWin()
    end,
})

-- ========== PETS LOGIC ==========
local function waitChild(parent, name, timeout)
    if not parent then return nil end
    local t = 0
    local obj = parent:FindFirstChild(name)
    while not obj and t < (timeout or 8) do
        task.wait(0.15)
        t = t + 0.15
        obj = parent:FindFirstChild(name)
    end
    return obj
end

local rEvents = waitChild(ReplicatedStorage, "rEvents", 10)
local BuyEvent = rEvents and waitChild(rEvents, "cPetShopRemote", 8)
local EvolvePetEvent = rEvents and waitChild(rEvents, "petEvolveEvent", 8)
local SellPetEvent = rEvents and waitChild(rEvents, "sellPetEvent", 8)
local EvolvePowerUpEvent = rEvents and waitChild(rEvents, "evolvePowerUpEvent", 8)
local SellPowerUpEvent = rEvents and waitChild(rEvents, "sellPowerUpEvent", 8)

local shared = waitChild(ReplicatedStorage, "shared", 8)
local runtime = shared and waitChild(shared, "runtime", 8)
local PetShopFolder = runtime and waitChild(runtime, "cPetShopFolder", 8)

local function GetPetsFolder()
    return LocalPlayer:FindFirstChild("petsFolder")
end

local function GetAurasFolder()
    return LocalPlayer:FindFirstChild("powerUpsFolder")
end

local RarityList = {"Basic", "Advanced", "Rare", "Epic", "Unique"}

local PetsByRarity = {
    Basic = {
        "Silver Dog", "Orange Hedgehog", "Blue Birdie", "Red Kitty", "Blue Bunny",
    },
    Advanced = {
        "Dark Golem", "Green Butterfly", "Yellow Butterfly", "Dark Vampy",
    },
    Rare = {
        "Eternal Strike Leviathan", "Crimson Falcon", "Frostwave Legends Penguin",
        "Phantom Genesis Dragon", "White Pegasus", "Red Dragon", "Purple Falcon",
        "Purple Dragon", "Orange Pegasus",
    },
    Epic = {
        "Golden Viking", "Core Pup", "Volt Talon", "Lightning Strike Phantom",
        "Dark Legends Manticore", "Ultimate Supernova Pegasus", "Green Firecaster",
        "White Pheonix", "Red Firecaster", "Golden Pheonix", "Blue Firecaster", "Blue Pheonix",
    },
    Unique = {
        "Muscle Sensei", "Neon Guardian", "Reactor Beast", "Plasma Ravager",
        "Titan Reactor", "Apex Overlord", "Darkstar Hunter", "Aether Spirit Bunny",
        "Cybernetic Showdown Dragon", "Magic Butterfly", "Ultra Birdie", "Infernal Dragon",
    },
}

local AurasByRarity = {
    Basic = {"Basic", "Green", "Blue", "Yellow", "Purple", "Red"},
    Advanced = {"Advanced"},
    Rare = {"Rare"},
    Epic = {
        "Epic", "Lightning", "Azure Tundra", "Grand SuperNova", "Ultra Inferno",
        "Enchanted Mirage", "Unstable Mirage",
    },
    Unique = {
        "Muscle King", "Entropic Blast", "Eternal Megastrike",
        "Dark Storm", "Inferno", "Dark Lightning",
    },
}

local PetCrystalNames = {
    "Blue Crystal", "Green Crystal", "Frost Crystal", "Mythical Crystal",
    "Inferno Crystal", "Legends Crystal", "Muscle Elite Crystal",
    "Galaxy Oracle Crystal", "Jungle Crystal", "Industrial Crystal",
}

local PetCrystalData = {
    ["Blue Crystal"] = {"Orange Hedgehog", "Blue Birdie", "Red Kitty", "Blue Bunny", "Dark Vampy"},
    ["Green Crystal"] = {"Silver Dog", "Dark Golem", "Green Butterfly", "Crimson Falcon"},
    ["Frost Crystal"] = {"Yellow Butterfly", "Purple Dragon", "Orange Pegasus", "Blue Pheonix"},
    ["Mythical Crystal"] = {"Red Dragon", "Purple Falcon", "Blue Firecaster", "Golden Pheonix"},
    ["Inferno Crystal"] = {"Red Firecaster", "White Pegasus", "Golden Pheonix", "Infernal Dragon"},
    ["Legends Crystal"] = {"Green Firecaster", "White Pheonix", "Magic Butterfly", "Ultra Birdie"},
    ["Muscle Elite Crystal"] = {
        "Frostwave Legends Penguin", "Phantom Genesis Dragon", "Dark Legends Manticore",
        "Ultimate Supernova Pegasus", "Aether Spirit Bunny", "Cybernetic Showdown Dragon",
    },
    ["Galaxy Oracle Crystal"] = {"Eternal Strike Leviathan", "Lightning Strike Phantom", "Darkstar Hunter"},
    ["Jungle Crystal"] = {"Golden Viking", "Muscle Sensei", "Neon Guardian"},
    ["Industrial Crystal"] = {
        "Core Pup", "Volt Talon", "Reactor Beast", "Plasma Ravager", "Titan Reactor", "Apex Overlord",
    },
}

local AuraList = {
    "Muscle King", "Entropic Blast", "Eternal Megastrike",
    "Dark Storm", "Inferno", "Dark Lightning",
    "Azure Tundra", "Grand SuperNova", "Ultra Inferno",
    "Basic", "Advanced", "Rare", "Epic",
}

local AllPetsList = {}
for _, list in pairs(PetsByRarity) do
    for _, name in ipairs(list) do
        if not table.find(AllPetsList, name) then
            table.insert(AllPetsList, name)
        end
    end
end
table.sort(AllPetsList)

local SelectedPetCrystal, SelectedPet = "Blue Crystal", "Orange Hedgehog"
local SelectedAura = "Muscle King"
local SelectedEvolvePets, SelectedEvolveAuras = {}, {}

local SelectedSellPets = GetSave("SelectedSellPets", {})
local SelectedSellAuras = GetSave("SelectedSellAuras", {})
if type(SelectedSellPets) ~= "table" then SelectedSellPets = {} end
if type(SelectedSellAuras) ~= "table" then SelectedSellAuras = {} end

local savedPetModes = GetSave("SellPetModes", { Normal = true, Evolved = false })
local savedAuraModes = GetSave("SellAuraModes", { Normal = true, Evolved = false })
local SellPetModes = {
    Normal = savedPetModes.Normal ~= false,
    Evolved = savedPetModes.Evolved == true,
}
local SellAuraModes = {
    Normal = savedAuraModes.Normal ~= false,
    Evolved = savedAuraModes.Evolved == true,
}

local SellPetRarity = GetSave("SellPetRarity", "Basic")
local SellAuraRarity = GetSave("SellAuraRarity", "Unique")
if not table.find(RarityList, SellPetRarity) then SellPetRarity = "Basic" end
if not table.find(RarityList, SellAuraRarity) then SellAuraRarity = "Unique" end

local userEnabledFlag = GetSave("UserEnabled", true) == true
local userAnonFlag = GetSave("UserAnon", true) == true

_G.AutoBuyPets, _G.AutoBuyAuras = false, false
_G.AutoEvolvePets, _G.AutoEvolveAuras = false, false
_G.AutoSellPets, _G.AutoSellAuras = false, false

local function FindShopItem(name)
    if not name or not PetShopFolder then return nil end
    local variants = { name, name .. " Aura", tostring(name):gsub(" Aura$", "") }
    for _, v in ipairs(variants) do
        local item = PetShopFolder:FindFirstChild(v)
        if item then return item end
    end
    local lower = tostring(name):lower()
    for _, child in ipairs(PetShopFolder:GetChildren()) do
        local n = child.Name:lower()
        if n == lower or n == lower .. " aura" or n:find(lower, 1, true) then
            return child
        end
    end
    return nil
end

local function IsEvolved(item)
    if not item then return false end
    local e = item:FindFirstChild("evolved")
    if not e then return false end
    if e:IsA("BoolValue") then return e.Value == true end
    if e:IsA("IntValue") or e:IsA("NumberValue") then return e.Value ~= 0 end
    if e:IsA("StringValue") then return e.Value ~= "" and e.Value:lower() ~= "false" end
    return true
end

local function CleanName(name)
    if type(name) ~= "string" then return "" end
    return name:lower():gsub("%s*aura$", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function NameMatches(objName, target)
    return CleanName(objName) == CleanName(target)
end

local function NormalizeList(value)
    local out = {}
    if type(value) == "table" then
        for k, v in pairs(value) do
            if type(v) == "string" and v ~= "" then
                table.insert(out, v)
            elseif type(k) == "string" and v == true then
                table.insert(out, k)
            end
        end
    elseif type(value) == "string" and value ~= "" then
        table.insert(out, value)
    end
    return out
end

local function NormalizeModes(value)
    local modes = { Normal = false, Evolved = false }
    if type(value) == "table" then
        for k, v in pairs(value) do
            local s = nil
            if type(v) == "string" then
                s = v
            elseif type(k) == "string" and v == true then
                s = k
            end
            if s == "Normal" then modes.Normal = true end
            if s == "Evolved" then modes.Evolved = true end
        end
    elseif type(value) == "string" then
        if value == "Normal" then modes.Normal = true end
        if value == "Evolved" then modes.Evolved = true end
    end
    if not modes.Normal and not modes.Evolved then
        modes.Normal = true
    end
    return modes
end

local function ModeAllows(modes, evolved)
    if evolved then return modes.Evolved == true end
    return modes.Normal == true
end

local function GetListByRarity(map, rarity)
    local list = map[rarity] or {}
    local copy = {}
    for _, n in ipairs(list) do
        copy[#copy + 1] = n
    end
    table.sort(copy)
    return copy
end

-- Conta quantas instancias com o mesmo nome existem no folder
local function CountByName(folder, name)
    if not folder or not name then return 0 end
    local count = 0
    local target = CleanName(name)
    pcall(function()
        for _, obj in ipairs(folder:GetDescendants()) do
            if CleanName(obj.Name) == target then
                -- evita contar pastas de raridade
                if not table.find(RarityList, obj.Name) then
                    count = count + 1
                end
            end
        end
    end)
    return count
end

local function CollectSellTargets(folder, names, modes, rarity)
    local result = {}
    names = NormalizeList(names)
    if not folder or #names == 0 then return result end
    modes = modes or { Normal = true }

    local function tryAdd(obj)
        if not obj or not obj.Parent then return end
        if table.find(RarityList, obj.Name) then return end
        for _, name in ipairs(names) do
            if NameMatches(obj.Name, name) then
                if ModeAllows(modes, IsEvolved(obj)) then
                    table.insert(result, obj)
                end
                return
            end
        end
    end

    local roots = {}
    if rarity and rarity ~= "" then
        local rar = folder:FindFirstChild(rarity)
        if rar then table.insert(roots, rar) end
    end
    if #roots == 0 then
        for _, r in ipairs(RarityList) do
            local f = folder:FindFirstChild(r)
            if f then table.insert(roots, f) end
        end
        table.insert(roots, folder)
    end

    local seen = {}
    for _, root in ipairs(roots) do
        pcall(function()
            for _, child in ipairs(root:GetChildren()) do
                if not seen[child] then
                    seen[child] = true
                    tryAdd(child)
                end
            end
            for _, desc in ipairs(root:GetDescendants()) do
                if not seen[desc] then
                    seen[desc] = true
                    tryAdd(desc)
                end
            end
        end)
    end
    return result
end

local function DoSellPet(item)
    if not item or not SellPetEvent then return false end
    local ok = false
    ok = pcall(function() SellPetEvent:FireServer("sellPet", item) end) or ok
    if item.Parent then
        ok = pcall(function() SellPetEvent:FireServer(item) end) or ok
    end
    if item.Parent then
        ok = pcall(function() SellPetEvent:InvokeServer("sellPet", item) end) or ok
    end
    if item.Parent then
        ok = pcall(function() SellPetEvent:FireServer("sellPet", item.Name) end) or ok
    end
    return ok
end

local function DoSellAura(item)
    if not item or not SellPowerUpEvent then return false end
    local ok = false
    ok = pcall(function() SellPowerUpEvent:FireServer("sellPowerUp", item) end) or ok
    if item.Parent then
        ok = pcall(function() SellPowerUpEvent:FireServer(item) end) or ok
    end
    if item.Parent then
        ok = pcall(function() SellPowerUpEvent:InvokeServer("sellPowerUp", item) end) or ok
    end
    if item.Parent then
        ok = pcall(function() SellPowerUpEvent:FireServer("sellPowerUp", item.Name) end) or ok
    end
    return ok
end

-- restore State.brawl defaults from save
State.brawl.autoJoin = GetSave("BrawlAutoJoin", false) == true
State.brawl.autoKill = GetSave("BrawlAutoKill", false) == true
State.brawl.autoReset = GetSave("BrawlAutoReset", false) == true
State.brawl.attackMode = GetSave("BrawlAttackMode", "Punch")

-- ========== PETS TAB ==========
Tabs.Pets:TabSection({ Title = "Buy / Evolve Pet" })
local PetDropdown
Tabs.Pets:Dropdown({
    Title = "Crystal",
    Option = PetCrystalNames,
    Value = GetSave("SelectedPetCrystal", PetCrystalNames[1]) or PetCrystalNames[1],
    Callback = function(Value)
        SelectedPetCrystal = Value
        SetSave("SelectedPetCrystal", Value)
        if PetDropdown and PetCrystalData[Value] then
            pcall(function()
                PetDropdown:Refresh(PetCrystalData[Value])
                SelectedPet = PetCrystalData[Value][1]
                SetSave("SelectedPet", SelectedPet)
                PetDropdown:SetValue(SelectedPet)
            end)
        end
    end,
})
local _petOpts = PetCrystalData[GetSave("SelectedPetCrystal", PetCrystalNames[1]) or PetCrystalNames[1]] or PetCrystalData["Blue Crystal"]
local _petDefault = GetSave("SelectedPet", _petOpts[1]) or _petOpts[1]
if not table.find(_petOpts, _petDefault) then _petDefault = _petOpts[1] end
SelectedPet = _petDefault
PetDropdown = Tabs.Pets:Dropdown({
    Title = "Pet",
    Option = _petOpts,
    Value = _petDefault,
    Callback = function(Value)
        SelectedPet = Value
        SetSave("SelectedPet", Value)
    end,
})
Tabs.Pets:Button({
    Title = "Buy Pet",
    Callback = function()
        local item = FindShopItem(SelectedPet)
        if item and BuyEvent then
            pcall(function() BuyEvent:InvokeServer(item) end)
        end
    end,
})
Tabs.Pets:Toggle({
    Title = "Auto Buy Pet",
    Default = GetSave("AutoBuyPets", false) == true,
    Callback = function(Value)
        _G.AutoBuyPets = Value == true
        SetSave("AutoBuyPets", Value == true)
        if _G.AutoBuyPets then
            task.spawn(function()
                while _G.AutoBuyPets and State.running do
                    local item = FindShopItem(SelectedPet)
                    if item and BuyEvent then
                        pcall(function() BuyEvent:InvokeServer(item) end)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})
Tabs.Pets:Dropdown({
    Title = "Evolve Pets",
    Option = AllPetsList,
    Multi = true,
    Value = GetSave("SelectedEvolvePets", {}) or {},
    Callback = function(Value)
        SelectedEvolvePets = NormalizeList(Value)
        SetSave("SelectedEvolvePets", SelectedEvolvePets)
    end,
})
Tabs.Pets:Toggle({
    Title = "Auto Evolve Pets",
    Default = GetSave("AutoEvolvePets", false) == true,
    Callback = function(Value)
        _G.AutoEvolvePets = Value == true
        SetSave("AutoEvolvePets", Value == true)
        if _G.AutoEvolvePets then
            task.spawn(function()
                while _G.AutoEvolvePets and State.running do
                    local folder = GetPetsFolder()
                    for _, petName in ipairs(NormalizeList(SelectedEvolvePets)) do
                        if CountByName(folder, petName) >= 5 then
                            if EvolvePetEvent then
                                pcall(function() EvolvePetEvent:FireServer("evolvePet", petName) end)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})
-- Sell Pets (embaixo do evolve)
local function modeValueFromTable(modes)
    local t = {}
    if modes.Normal then table.insert(t, "Normal") end
    if modes.Evolved then table.insert(t, "Evolved") end
    if #t == 0 then t = {"Normal"} end
    return t
end
Tabs.Pets:Dropdown({
    Title = "Sell Pet Mode",
    Option = {"Normal", "Evolved"},
    Multi = true,
    Value = modeValueFromTable(SellPetModes),
    Callback = function(Value)
        SellPetModes = NormalizeModes(Value)
        SetSave("SellPetModes", SellPetModes)
    end,
})
Tabs.Pets:Dropdown({
    Title = "Sell Pet Rarity",
    Option = RarityList,
    Value = (table.find(RarityList, SellPetRarity) and SellPetRarity) or RarityList[1],
    Callback = function(Value)
        SellPetRarity = Value
        SetSave("SellPetRarity", Value)
    end,
})
Tabs.Pets:Dropdown({
    Title = "Pets to Sell",
    Option = AllPetsList,
    Multi = true,
    Value = SelectedSellPets,
    Callback = function(Value)
        SelectedSellPets = NormalizeList(Value)
        SetSave("SelectedSellPets", SelectedSellPets)
    end,
})
Tabs.Pets:Button({
    Title = "Sell Pet",
    Callback = function()
        local folder = GetPetsFolder()
        local names = NormalizeList(SelectedSellPets)
        if #names == 0 then return end
        local items = CollectSellTargets(folder, names, SellPetModes, SellPetRarity)
        if #items == 0 then items = CollectSellTargets(folder, names, SellPetModes, nil) end
        if #items >= 1 then DoSellPet(items[1]) end
    end,
})
Tabs.Pets:Toggle({
    Title = "Auto Sell Pets",
    Default = GetSave("AutoSellPets", false) == true,
    Callback = function(Value)
        _G.AutoSellPets = Value == true
        SetSave("AutoSellPets", Value == true)
        if _G.AutoSellPets then
            task.spawn(function()
                while _G.AutoSellPets and State.running do
                    local folder = GetPetsFolder()
                    local names = NormalizeList(SelectedSellPets)
                    if #names > 0 then
                        local items = CollectSellTargets(folder, names, SellPetModes, SellPetRarity)
                        if #items == 0 then items = CollectSellTargets(folder, names, SellPetModes, nil) end
                        if #items >= 1 then DoSellPet(items[1]) end
                    end
                    task.wait(0.4)
                end
            end)
        end
    end,
})

Tabs.Pets:TabSection({ Title = "Buy / Evolve Aura" })
Tabs.Pets:Dropdown({
    Title = "Aura",
    Option = AuraList,
    Value = (function()
        local s = GetSave("SelectedAura", AuraList[1])
        return table.find(AuraList, s) and s or AuraList[1]
    end)(),
    Callback = function(Value)
        SelectedAura = Value
        SetSave("SelectedAura", Value)
    end,
})
Tabs.Pets:Button({
    Title = "Buy Aura",
    Callback = function()
        local item = FindShopItem(SelectedAura)
        if item and BuyEvent then
            pcall(function() BuyEvent:InvokeServer(item) end)
        end
    end,
})
Tabs.Pets:Toggle({
    Title = "Auto Buy Aura",
    Default = GetSave("AutoBuyAuras", false) == true,
    Callback = function(Value)
        _G.AutoBuyAuras = Value == true
        SetSave("AutoBuyAuras", Value == true)
        if _G.AutoBuyAuras then
            task.spawn(function()
                while _G.AutoBuyAuras and State.running do
                    local item = FindShopItem(SelectedAura)
                    if item and BuyEvent then
                        pcall(function() BuyEvent:InvokeServer(item) end)
                    end
                    task.wait(0.15)
                end
            end)
        end
    end,
})
Tabs.Pets:Dropdown({
    Title = "Evolve Auras",
    Option = AuraList,
    Multi = true,
    Value = GetSave("SelectedEvolveAuras", {}) or {},
    Callback = function(Value)
        SelectedEvolveAuras = NormalizeList(Value)
        SetSave("SelectedEvolveAuras", SelectedEvolveAuras)
    end,
})
Tabs.Pets:Toggle({
    Title = "Auto Evolve Auras",
    Default = GetSave("AutoEvolveAuras", false) == true,
    Callback = function(Value)
        _G.AutoEvolveAuras = Value == true
        SetSave("AutoEvolveAuras", Value == true)
        if _G.AutoEvolveAuras then
            task.spawn(function()
                while _G.AutoEvolveAuras and State.running do
                    local folder = GetAurasFolder()
                    for _, auraName in ipairs(NormalizeList(SelectedEvolveAuras)) do
                        if CountByName(folder, auraName) >= 5 then
                            if EvolvePowerUpEvent then
                                pcall(function() EvolvePowerUpEvent:FireServer("evolvePowerUp", auraName) end)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})
-- Sell Auras (embaixo do evolve aura)
Tabs.Pets:Dropdown({
    Title = "Sell Aura Mode",
    Option = {"Normal", "Evolved"},
    Multi = true,
    Value = modeValueFromTable(SellAuraModes),
    Callback = function(Value)
        SellAuraModes = NormalizeModes(Value)
        SetSave("SellAuraModes", SellAuraModes)
    end,
})
Tabs.Pets:Dropdown({
    Title = "Sell Aura Rarity",
    Option = RarityList,
    Value = (table.find(RarityList, SellAuraRarity) and SellAuraRarity) or RarityList[1],
    Callback = function(Value)
        SellAuraRarity = Value
        SetSave("SellAuraRarity", Value)
    end,
})
Tabs.Pets:Dropdown({
    Title = "Auras to Sell",
    Option = AuraList,
    Multi = true,
    Value = SelectedSellAuras,
    Callback = function(Value)
        SelectedSellAuras = NormalizeList(Value)
        SetSave("SelectedSellAuras", SelectedSellAuras)
    end,
})
Tabs.Pets:Button({
    Title = "Sell Aura",
    Callback = function()
        local folder = GetAurasFolder()
        local names = NormalizeList(SelectedSellAuras)
        if #names == 0 then return end
        local items = CollectSellTargets(folder, names, SellAuraModes, SellAuraRarity)
        if #items == 0 then items = CollectSellTargets(folder, names, SellAuraModes, nil) end
        if #items >= 1 then DoSellAura(items[1]) end
    end,
})
Tabs.Pets:Toggle({
    Title = "Auto Sell Auras",
    Default = GetSave("AutoSellAuras", false) == true,
    Callback = function(Value)
        _G.AutoSellAuras = Value == true
        SetSave("AutoSellAuras", Value == true)
        if _G.AutoSellAuras then
            task.spawn(function()
                while _G.AutoSellAuras and State.running do
                    local folder = GetAurasFolder()
                    local names = NormalizeList(SelectedSellAuras)
                    if #names > 0 then
                        local items = CollectSellTargets(folder, names, SellAuraModes, SellAuraRarity)
                        if #items == 0 then items = CollectSellTargets(folder, names, SellAuraModes, nil) end
                        if #items >= 1 then DoSellAura(items[1]) end
                    end
                    task.wait(0.4)
                end
            end)
        end
    end,
})


-- Rebirth
Tabs.Rebirths:TabSection({ Title = "Auto" })
Tabs.Rebirths:Input({
    Title = "Rebirth objective",
    Placeholder = "18980",
    Default = tostring(GetSave("RebirthObjective", "") or ""),
    Value = tostring(GetSave("RebirthObjective", "") or ""),
    Callback = function(text)
        local num = tonumber(string.match(tostring(text or ""), "%d+"))
        State.rebirth.objective = num or 0
        SetSave("RebirthObjective", State.rebirth.objective)
    end,
})
Tabs.Rebirths:Toggle({
    Title = "Auto Rebirth",
    Default = false,
    Callback = function(v)
        State.rebirth.autoRebirth = v
        if v then State.rebirth.infinite = false end
        cancelTask("smartAutoRebirthTask")
        if v then
            spawnTask("smartAutoRebirthTask", function()
                while State.running and State.rebirth.autoRebirth do
                    pcall(function()
                        local rStat = tonumber(LocalPlayer.leaderstats.Rebirths.Value) or 0
                        if State.rebirth.objective > 0 and rStat >= State.rebirth.objective then
                            State.rebirth.autoRebirth = false
                            return
                        end
                        requestRebirth()
                    end)
                    task.wait(1.5)
                end
            end)
        end
    end,
})
Tabs.Rebirths:Toggle({
    Title = "Infinite",
    Default = false,
    Callback = function(v)
        State.rebirth.infinite = v
        if v then State.rebirth.autoRebirth = false end
        cancelTask("rebirthLoop")
        if v then
            spawnTask("rebirthLoop", function()
                while State.running and State.rebirth.infinite do
                    requestRebirth()
                    task.wait(0.1)
                end
            end)
        end
    end,
})

Tabs.Rebirths:TabSection({ Title = "Extra" })
Tabs.Rebirths:Toggle({
    Title = "Muscle King",
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
                        hrp.CFrame = CFrame.new(kingPos)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                    task.wait(0.2)
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
                    local h = getHRP()
                    if h and State.rebirth.lockCFrame then
                        h.CFrame = State.rebirth.lockCFrame
                        h.AssemblyLinearVelocity = Vector3.zero
                        h.AssemblyAngularVelocity = Vector3.zero
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end,
})

-- Rewards (tudo na mesma section)
Tabs.Rewards:TabSection({ Title = "Rewards" })
Tabs.Rewards:Toggle({
    Title = "Spin Wheel",
    Default = GetSave("SpinWheel", false),
    Callback = function(v)
        State.autoSpinWheel = v
        SetSave("SpinWheel", v)
        cancelTask("fortuneWheel")
        if v then
            spawnTask("fortuneWheel", function()
                while State.running and State.autoSpinWheel do
                    pcall(function()
                        local wheelGui = PlayerGui:FindFirstChild("fortuneWheelMenuGui")
                        if not wheelGui then return end
                        local spinLabel = wheelGui:FindFirstChild("spinAmountLabel", true)
                        if not spinLabel or not spinLabel.Text then return end
                        local text = tostring(spinLabel.Text)
                        local spinsLeft = 0
                        if text:lower():find("inf", 1, true) or text:find("∞") then
                            spinsLeft = math.huge
                        else
                            spinsLeft = tonumber(string.match(text, "%d+")) or 0
                        end
                        if spinsLeft >= 1 then
                            ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer(
                                "openFortuneWheel",
                                ReplicatedStorage.shared.catalogs.fortuneWheelChances["Fortune Wheel"]
                            )
                        end
                    end)
                    task.wait(1.5)
                end
            end)
        end
    end,
})
Tabs.Rewards:Toggle({
    Title = "Auto Claim Gifts",
    Default = GetSave("AutoClaimGifts", false),
    Callback = function(v)
        State.autoClaimGifts = v == true
        SetSave("AutoClaimGifts", v == true)
        cancelTask("claimGifts")
        if v then
            spawnTask("claimGifts", function()
                while State.running and State.autoClaimGifts do
                    claimAllGifts()
                    task.wait(2)
                end
            end)
        end
    end,
})
Tabs.Rewards:TabSection({ Title = "Codes" })
Tabs.Rewards:Toggle({
    Title = "Auto Use Codes",
    Default = GetSave("AutoUseCodes", false) == true,
    Callback = function(v)
        State.autoUseCodes = v == true
        SetSave("AutoUseCodes", v == true)
        cancelTask("autoUseCodes")
        if v then
            spawnTask("autoUseCodes", function()
                local codesList = {
                    "mightygems2500", "ultimate250", "spacegems50", "megalift50",
                    "speedy50", "epicreward500", "MillionWarriors", "frostgems10",
                    "Musclestorm50", "Skyagility50", "galaxycrystal50", "supermuscle100",
                    "superpunch100", "launch250", "MLREVIVED", "INDUSTRIALGYM500",
                    "BOSSSTRIKE", "BOSSGUARD"
                }
                local eventPath = ReplicatedStorage:FindFirstChild("rEvents")
                    and ReplicatedStorage.rEvents:FindFirstChild("codeRemote")
                if not eventPath then return end
                for _, code in ipairs(codesList) do
                    if not State.running or not State.autoUseCodes then break end
                    pcall(function()
                        eventPath:InvokeServer(code)
                    end)
                    task.wait(0.8)
                end
                State.autoUseCodes = false
            end)
        end
    end,
})

-- Teleport
Tabs.Teleports:TabSection({ Title = "Places" })
for _, tp in ipairs(Config.Teleports) do
    Tabs.Teleports:Button({
        Title = tp[1],
        Callback = function()
            local hrp = getHRP()
            if hrp then hrp.CFrame = CFrame.new(tp[2]) end
        end,
    })
end

-- Misc
Tabs.Misc:TabSection({ Title = "Protein" })
local proteinNamesList = {}
for _, def in ipairs(PROTEIN_ITEMS) do
    proteinNamesList[#proteinNamesList + 1] = def.tool
end
local savedProtein = GetSave("SelectedProteinItems", { proteinNamesList[1] })
if type(savedProtein) ~= "table" then
    if type(savedProtein) == "string" and savedProtein ~= "" then
        savedProtein = { savedProtein }
    else
        savedProtein = { proteinNamesList[1] }
    end
end
if #savedProtein == 0 then savedProtein = { proteinNamesList[1] } end
do
    local map = {}
    for _, name in ipairs(savedProtein) do map[name] = true end
    State.selectedProteinItems = map
end
Tabs.Misc:Dropdown({
    Title = "Items",
    Option = proteinNamesList,
    Multi = true,
    Value = savedProtein,
    Callback = function(v)
        local map = {}
        local list = {}
        if type(v) == "table" then
            for _, name in ipairs(v) do
                map[name] = true
                table.insert(list, name)
            end
        elseif type(v) == "string" then
            map[v] = true
            table.insert(list, v)
        end
        if #list == 0 and proteinNamesList[1] then
            map[proteinNamesList[1]] = true
            list = { proteinNamesList[1] }
        end
        State.selectedProteinItems = map
        SetSave("SelectedProteinItems", list)
    end,
})
Tabs.Misc:Toggle({
    Title = "Auto Eat",
    Default = GetSave("AutoEatProtein", false),
    Callback = function(v)
        State.autoEatProtein = v
        SetSave("AutoEatProtein", v)
        cancelTask("autoEatProtein")
        if v then
            spawnTask("autoEatProtein", function()
                while State.running and State.autoEatProtein do
                    pcall(function()
                        local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                        if not muscleEvent then return end
                        local selected = State.selectedProteinItems
                        if type(selected) ~= "table" or next(selected) == nil then return end
                        for _, def in ipairs(PROTEIN_ITEMS) do
                            if selected[def.tool] then
                                local tool = equipTool({ def.tool })
                                if tool then
                                    muscleEvent:FireServer(def.event, tool)
                                end
                            end
                        end
                    end)
                    task.wait(0.28)
                end
            end)
        end
    end,
})

Tabs.Misc:TabSection({ Title = "Window" })
Tabs.Misc:Toggle({
    Title = "User",
    Default = GetSave("UserEnabled", true),
    Callback = function(v)
        SetSave("UserEnabled", v == true)
        pcall(function() Window:UserEnabled(v) end)
    end,
})
Tabs.Misc:Toggle({
    Title = "Anonymous",
    Default = GetSave("UserAnon", true),
    Callback = function(v)
        SetSave("UserAnon", v == true)
        pcall(function() Window:Anonymous(v) end)
    end,
})

-- init
local function initSavedState()
    -- Rebirth: só salva o objective (não toggles da aba)
    local obj = GetSave("RebirthObjective", 0)
    State.rebirth.objective = tonumber(obj) or 0

    State.mainSize = GetSave("MainSize", 2)
    State.mainSpeed = GetSave("MainSpeed", 125)

    if GetSave("MainAutoSize", false) then
        State.mainAutoSize = true
        spawnTask("mainAutoSize", function()
            while State.running and State.mainAutoSize do
                applySizeOrSpeed("changeSize", State.mainSize)
                task.wait(0.35)
            end
        end)
    end
    if GetSave("MainAutoSpeed", false) then
        State.mainAutoSpeed = true
        spawnTask("mainAutoSpeed", function()
            while State.running and State.mainAutoSpeed do
                applySizeOrSpeed("changeSpeed", State.mainSpeed)
                task.wait(0.35)
            end
        end)
    end
    if GetSave("WalkOnWater", false) then setWalkWater(true) end
    if GetSave("InfiniteJump", false) then State.infiniteJump = true end
    if GetSave("SpinChar", false) then State.spin = true end
    if GetSave("AutoRock", false) then
        State._autoRock = true
        setRockSelection(rockByName[selectedRockName])
    end
    if GetSave("FastPunch", false) then setFastPunch(true) end
    if GetSave("AutoJoinBrawl", false) then
        State._autoBrawl = true
        spawnTask("autoBrawlJoin", function()
            while State.running and State._autoBrawl do
                pcall(function()
                    local lbl = PlayerGui:FindFirstChild("gameGui")
                        and PlayerGui.gameGui:FindFirstChild("brawlJoinLabel")
                    if lbl and lbl.Visible then
                        ReplicatedStorage.rEvents.brawlEvent:FireServer("joinBrawl")
                        task.wait(3)
                    end
                end)
                task.wait(0.5)
            end
        end)
    end
    if GetSave("AutoWinBrawl", false) then
        State.autoWinBrawl = true
        runBrawlWin()
    end
    if GetSave("AutoUseTools", false) then
        State.autoUseTools = true
        spawnTask("autoUseTools", function()
            while State.running and State.autoUseTools do
                pcall(function()
                    local ev = LocalPlayer:FindFirstChild("muscleEvent")
                    if ev then for _ = 1, 3 do ev:FireServer("rep") end end
                end)
                task.wait(0.18)
            end
        end)
    end
    if GetSave("autoHandstands", false) then
        setExercise("autoHandstands", true, { "Handstands", "Handstand" }, 0.15)
    end
    if GetSave("autoSitups", false) then
        setExercise("autoSitups", true, { "Situps", "Situp" }, 0.15)
    end
    if GetSave("autoWeight", false) then
        setExercise("autoWeight", true, { "Weight" }, 0.15)
    end
    if GetSave("autoLift", false) then
        setExercise("autoLift", true, { "Pushup", "Pushups" }, 0.15)
    end
    if GetSave("AutoEatProtein", false) then
        State.autoEatProtein = true
        spawnTask("autoEatProtein", function()
            while State.running and State.autoEatProtein do
                pcall(function()
                    local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                    if not muscleEvent then return end
                    local selected = State.selectedProteinItems
                    if type(selected) ~= "table" or next(selected) == nil then return end
                    for _, def in ipairs(PROTEIN_ITEMS) do
                        if selected[def.tool] then
                            local tool = equipTool({ def.tool })
                            if tool then muscleEvent:FireServer(def.event, tool) end
                        end
                    end
                end)
                task.wait(0.28)
            end
        end)
    end
    if GetSave("SpinWheel", false) then
        State.autoSpinWheel = true
        spawnTask("fortuneWheel", function()
            while State.running and State.autoSpinWheel do
                pcall(function()
                    local wheelGui = PlayerGui:FindFirstChild("fortuneWheelMenuGui")
                    if not wheelGui then return end
                    local spinLabel = wheelGui:FindFirstChild("spinAmountLabel", true)
                    if not spinLabel or not spinLabel.Text then return end
                    local text = tostring(spinLabel.Text)
                    local spinsLeft = 0
                    if text:lower():find("inf", 1, true) or text:find("∞") then
                        spinsLeft = math.huge
                    else
                        spinsLeft = tonumber(string.match(text, "%d+")) or 0
                    end
                    if spinsLeft >= 1 then
                        ReplicatedStorage.rEvents.openFortuneWheelRemote:InvokeServer(
                            "openFortuneWheel",
                            ReplicatedStorage.shared.catalogs.fortuneWheelChances["Fortune Wheel"]
                        )
                    end
                end)
                task.wait(1.5)
            end
        end)
    end
    if GetSave("AutoClaimGifts", false) then
        State.autoClaimGifts = true
        spawnTask("claimGifts", function()
            while State.running and State.autoClaimGifts do
                claimAllGifts()
                task.wait(2)
            end
        end)
    end
    -- Pets autos from save (toggles da UI)
    if GetSave("AutoBuyPets", false) then
        _G.AutoBuyPets = true
        task.spawn(function()
            while _G.AutoBuyPets and State.running do
                local item = FindShopItem(SelectedPet)
                if item and BuyEvent then pcall(function() BuyEvent:InvokeServer(item) end) end
                task.wait(0.1)
            end
        end)
    end
    if GetSave("AutoBuyAuras", false) then
        _G.AutoBuyAuras = true
        task.spawn(function()
            while _G.AutoBuyAuras and State.running do
                local item = FindShopItem(SelectedAura)
                if item and BuyEvent then pcall(function() BuyEvent:InvokeServer(item) end) end
                task.wait(0.15)
            end
        end)
    end
    if GetSave("AutoEvolvePets", false) then
        _G.AutoEvolvePets = true
        task.spawn(function()
            while _G.AutoEvolvePets and State.running do
                local folder = GetPetsFolder()
                for _, petName in ipairs(NormalizeList(SelectedEvolvePets)) do
                    if CountByName(folder, petName) >= 5 and EvolvePetEvent then
                        pcall(function() EvolvePetEvent:FireServer("evolvePet", petName) end)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
    if GetSave("AutoEvolveAuras", false) then
        _G.AutoEvolveAuras = true
        task.spawn(function()
            while _G.AutoEvolveAuras and State.running do
                local folder = GetAurasFolder()
                for _, auraName in ipairs(NormalizeList(SelectedEvolveAuras)) do
                    if CountByName(folder, auraName) >= 5 and EvolvePowerUpEvent then
                        pcall(function() EvolvePowerUpEvent:FireServer("evolvePowerUp", auraName) end)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
    if GetSave("AutoSellPets", false) then
        _G.AutoSellPets = true
        task.spawn(function()
            while _G.AutoSellPets and State.running do
                local folder = GetPetsFolder()
                local names = NormalizeList(SelectedSellPets)
                if #names > 0 then
                    local items = CollectSellTargets(folder, names, SellPetModes, SellPetRarity)
                    if #items == 0 then items = CollectSellTargets(folder, names, SellPetModes, nil) end
                    if #items >= 1 then DoSellPet(items[1]) end
                end
                task.wait(0.4)
            end
        end)
    end
    if GetSave("AutoSellAuras", false) then
        _G.AutoSellAuras = true
        task.spawn(function()
            while _G.AutoSellAuras and State.running do
                local folder = GetAurasFolder()
                local names = NormalizeList(SelectedSellAuras)
                if #names > 0 then
                    local items = CollectSellTargets(folder, names, SellAuraModes, SellAuraRarity)
                    if #items == 0 then items = CollectSellTargets(folder, names, SellAuraModes, nil) end
                    if #items >= 1 then DoSellAura(items[1]) end
                end
                task.wait(0.4)
            end
        end)
    end
    if GetSave("AutoUseCodes", false) then
        State.autoUseCodes = true
        spawnTask("autoUseCodes", function()
            local codesList = {
                "mightygems2500", "ultimate250", "spacegems50", "megalift50",
                "speedy50", "epicreward500", "MillionWarriors", "frostgems10",
                "Musclestorm50", "Skyagility50", "galaxycrystal50", "supermuscle100",
                "superpunch100", "launch250", "MLREVIVED", "INDUSTRIALGYM500",
                "BOSSSTRIKE", "BOSSGUARD"
            }
            local eventPath = ReplicatedStorage:FindFirstChild("rEvents")
                and ReplicatedStorage.rEvents:FindFirstChild("codeRemote")
            if not eventPath then return end
            for _, code in ipairs(codesList) do
                if not State.running or not State.autoUseCodes then break end
                pcall(function() eventPath:InvokeServer(code) end)
                task.wait(0.8)
            end
            State.autoUseCodes = false
            SetSave("AutoUseCodes", false)
        end)
    end
end
initSavedState()

-- Garante que Punch não fica equipado ao abrir o script
task.defer(function()
    pcall(function()
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if char and bp then
            local punch = char:FindFirstChild("Punch")
            if punch then punch.Parent = bp end
        end
    end)
end)

task.wait(0.08)
pcall(function()
    Window:SelectTab(1)
    Window:Open()
end)

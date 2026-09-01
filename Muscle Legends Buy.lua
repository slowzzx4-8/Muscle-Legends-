-- Load UI Library
local VoidUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/slowzzx4-8/Ui-library/refs/heads/main/Void%20Ui%20Library.lua"))()

local WHITE = Color3.fromRGB(255, 255, 255)
local WHITE_SOFT = Color3.fromRGB(230, 230, 230)

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ========== SAVE (apenas Sell + Misc) ==========
local SaveFileName = "MuscleLegends_Buy_SellMisc_Save.json"
local SaveData = {}

if isfile and isfile(SaveFileName) then
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(SaveFileName))
    end)
    if ok and type(decoded) == "table" then
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
        pcall(function()
            writefile(SaveFileName, HttpService:JSONEncode(SaveData))
        end)
    end
end

local function SaveSellMisc()
    SetSave("SellPetModes", {
        Normal = SellPetModes.Normal == true,
        Evolved = SellPetModes.Evolved == true,
    })
    SetSave("SellAuraModes", {
        Normal = SellAuraModes.Normal == true,
        Evolved = SellAuraModes.Evolved == true,
    })
    SetSave("SellPetRarity", SellPetRarity)
    SetSave("SellAuraRarity", SellAuraRarity)
    SetSave("SelectedSellPets", SelectedSellPets)
    SetSave("SelectedSellAuras", SelectedSellAuras)
    SetSave("UserEnabled", userEnabledFlag)
    SetSave("UserAnon", userAnonFlag)
end

local Window = VoidUI:CreateWindow({
    Name = "Muscle Legends",
    Icon = "dumbbell",
    SideBarWidth = 160,
    Theme = "Dark",
    Transparent = true,
    Author = "By Slowzzx4",
    User = {
        Enabled = GetSave("UserEnabled", true) == true,
        Anonymous = GetSave("UserAnon", true) == true,
    },
    Folder = "MuscleLegendsScript",
})

pcall(function()
    if Window.SetTheme then Window:SetTheme("Dark") end
end)

Window:EditOpenButton({
    Title = "Muscle Legends",
    Icon = "dumbbell",
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, WHITE),
        ColorSequenceKeypoint.new(1, WHITE_SOFT),
    }),
    Transparency = 0.1,
    StrokeThickness = 1.2,
    AutoRotation = false,
    Speed = 12,
    CornerRadius = UDim.new(0, 16),
})

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

-- ========== AUTO BUY PET ==========
local BuyPetsTab = Window:Tab({ Title = "Auto Buy Pet", Icon = "shopping-cart", Border = true })
local PetDropdown

BuyPetsTab:Dropdown({
    Title = "Crystal",
    Option = PetCrystalNames,
    Value = "Blue Crystal",
    Callback = function(Value)
        SelectedPetCrystal = Value
        if PetDropdown and PetCrystalData[Value] then
            PetDropdown:Refresh(PetCrystalData[Value])
            SelectedPet = PetCrystalData[Value][1]
            pcall(function() PetDropdown:SetValue(SelectedPet) end)
        end
    end,
})

PetDropdown = BuyPetsTab:Dropdown({
    Title = "Pet",
    Option = PetCrystalData["Blue Crystal"],
    Value = "Orange Hedgehog",
    Callback = function(Value) SelectedPet = Value end,
})

BuyPetsTab:Button({
    Title = "Buy Pet",
    Callback = function()
        local item = FindShopItem(SelectedPet)
        if item and BuyEvent then
            pcall(function() BuyEvent:InvokeServer(item) end)
        end
    end,
})

BuyPetsTab:Toggle({
    Title = "Auto Buy",
    Default = false,
    Callback = function(Value)
        _G.AutoBuyPets = Value == true
        if _G.AutoBuyPets then
            task.spawn(function()
                while _G.AutoBuyPets do
                    local item = FindShopItem(SelectedPet)
                    if item and BuyEvent then
                        pcall(function() BuyEvent:InvokeServer(item) end)
                        pcall(function() BuyEvent:InvokeServer(item) end)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

BuyPetsTab:Dropdown({
    Title = "Evolve Pets",
    Option = AllPetsList,
    Multi = true,
    Callback = function(Value) SelectedEvolvePets = NormalizeList(Value) end,
})

BuyPetsTab:Toggle({
    Title = "Auto Evolve",
    Default = false,
    Callback = function(Value)
        _G.AutoEvolvePets = Value == true
        if _G.AutoEvolvePets then
            task.spawn(function()
                while _G.AutoEvolvePets do
                    local folder = GetPetsFolder()
                    for _, petName in ipairs(NormalizeList(SelectedEvolvePets)) do
                        -- so evolve se tiver pelo menos 5 do mesmo pet
                        if CountByName(folder, petName) >= 5 then
                            if EvolvePetEvent then
                                pcall(function()
                                    EvolvePetEvent:FireServer("evolvePet", petName)
                                end)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})

-- ========== AUTO BUY AURA ==========
local BuyAurasTab = Window:Tab({ Title = "Auto Buy Aura", Icon = "sparkles", Border = true })

BuyAurasTab:Dropdown({
    Title = "Aura",
    Option = AuraList,
    Value = "Muscle King",
    Callback = function(Value) SelectedAura = Value end,
})

BuyAurasTab:Button({
    Title = "Buy Aura",
    Callback = function()
        local item = FindShopItem(SelectedAura)
        if item and BuyEvent then
            pcall(function() BuyEvent:InvokeServer(item) end)
        end
    end,
})

BuyAurasTab:Toggle({
    Title = "Auto Buy",
    Default = false,
    Callback = function(Value)
        _G.AutoBuyAuras = Value == true
        if _G.AutoBuyAuras then
            task.spawn(function()
                while _G.AutoBuyAuras do
                    local item = FindShopItem(SelectedAura)
                    if item and BuyEvent then
                        pcall(function() BuyEvent:InvokeServer(item) end)
                    end
                    task.wait(0.2)
                end
            end)
        end
    end,
})

BuyAurasTab:Dropdown({
    Title = "Evolve Auras",
    Option = AuraList,
    Multi = true,
    Callback = function(Value) SelectedEvolveAuras = NormalizeList(Value) end,
})

BuyAurasTab:Toggle({
    Title = "Auto Evolve",
    Default = false,
    Callback = function(Value)
        _G.AutoEvolveAuras = Value == true
        if _G.AutoEvolveAuras then
            task.spawn(function()
                while _G.AutoEvolveAuras do
                    local folder = GetAurasFolder()
                    for _, auraName in ipairs(NormalizeList(SelectedEvolveAuras)) do
                        -- so evolve se tiver pelo menos 5 da mesma aura
                        if CountByName(folder, auraName) >= 5 then
                            local items = CollectSellTargets(
                                folder,
                                { auraName },
                                { Normal = true, Evolved = true },
                                nil
                            )
                            for _, inst in ipairs(items) do
                                if EvolvePowerUpEvent then
                                    pcall(function()
                                        EvolvePowerUpEvent:FireServer("evolvePowerUp", inst)
                                    end)
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})

-- ========== SELL ==========
local SellTab = Window:Tab({ Title = "Sell", Icon = "paw-print", Border = true })
local SellPetDropdown, SellAuraDropdown

local function modeValueFromTable(modes)
    local v = {}
    if modes.Normal then table.insert(v, "Normal") end
    if modes.Evolved then table.insert(v, "Evolved") end
    if #v == 0 then v = { "Normal" } end
    return v
end

SellTab:Dropdown({
    Title = "Pet Mode",
    Option = { "Normal", "Evolved" },
    Multi = true,
    Value = modeValueFromTable(SellPetModes),
    Callback = function(Value)
        SellPetModes = NormalizeModes(Value)
        SaveSellMisc()
    end,
})

SellTab:Dropdown({
    Title = "Pet Rarity",
    Option = RarityList,
    Value = SellPetRarity,
    Callback = function(Value)
        SellPetRarity = Value
        local list = GetListByRarity(PetsByRarity, Value)
        if SellPetDropdown then
            pcall(function() SellPetDropdown:Refresh(list) end)
            SelectedSellPets = {}
        end
        SaveSellMisc()
    end,
})

SellPetDropdown = SellTab:Dropdown({
    Title = "Pets",
    Option = GetListByRarity(PetsByRarity, SellPetRarity),
    Multi = true,
    Value = SelectedSellPets,
    Callback = function(Value)
        SelectedSellPets = NormalizeList(Value)
        SaveSellMisc()
    end,
})

SellTab:Button({
    Title = "Sell Pet",
    Callback = function()
        local folder = GetPetsFolder()
        local names = NormalizeList(SelectedSellPets)
        if #names == 0 then return end

        -- so vende se existir pelo menos 1 no inventario
        local items = CollectSellTargets(folder, names, SellPetModes, SellPetRarity)
        if #items == 0 then
            items = CollectSellTargets(folder, names, SellPetModes, nil)
        end
        if #items == 0 then
            items = CollectSellTargets(folder, names, { Normal = true, Evolved = true }, nil)
        end

        if #items >= 1 then
            DoSellPet(items[1])
        end
    end,
})

SellTab:Toggle({
    Title = "Auto Sell Pet",
    Default = false,
    Callback = function(Value)
        _G.AutoSellPets = Value == true
        if _G.AutoSellPets then
            task.spawn(function()
                while _G.AutoSellPets do
                    local folder = GetPetsFolder()
                    local names = NormalizeList(SelectedSellPets)
                    if #names > 0 then
                        local items = CollectSellTargets(folder, names, SellPetModes, SellPetRarity)
                        if #items == 0 then
                            items = CollectSellTargets(folder, names, SellPetModes, nil)
                        end
                        if #items == 0 then
                            items = CollectSellTargets(folder, names, { Normal = true, Evolved = true }, nil)
                        end
                        if #items >= 1 then
                            DoSellPet(items[1])
                        end
                    end
                    task.wait(0.4)
                end
            end)
        end
    end,
})

SellTab:Dropdown({
    Title = "Aura Mode",
    Option = { "Normal", "Evolved" },
    Multi = true,
    Value = modeValueFromTable(SellAuraModes),
    Callback = function(Value)
        SellAuraModes = NormalizeModes(Value)
        SaveSellMisc()
    end,
})

SellTab:Dropdown({
    Title = "Aura Rarity",
    Option = RarityList,
    Value = SellAuraRarity,
    Callback = function(Value)
        SellAuraRarity = Value
        local list = GetListByRarity(AurasByRarity, Value)
        if SellAuraDropdown then
            pcall(function() SellAuraDropdown:Refresh(list) end)
            SelectedSellAuras = {}
        end
        SaveSellMisc()
    end,
})

SellAuraDropdown = SellTab:Dropdown({
    Title = "Auras",
    Option = GetListByRarity(AurasByRarity, SellAuraRarity),
    Multi = true,
    Value = SelectedSellAuras,
    Callback = function(Value)
        SelectedSellAuras = NormalizeList(Value)
        SaveSellMisc()
    end,
})

SellTab:Button({
    Title = "Sell Aura",
    Callback = function()
        local folder = GetAurasFolder()
        local names = NormalizeList(SelectedSellAuras)
        if #names == 0 then return end

        local items = CollectSellTargets(folder, names, SellAuraModes, SellAuraRarity)
        if #items == 0 then
            items = CollectSellTargets(folder, names, SellAuraModes, nil)
        end
        if #items == 0 then
            items = CollectSellTargets(folder, names, { Normal = true, Evolved = true }, nil)
        end

        if #items >= 1 then
            DoSellAura(items[1])
        end
    end,
})

SellTab:Toggle({
    Title = "Auto Sell Aura",
    Default = false,
    Callback = function(Value)
        _G.AutoSellAuras = Value == true
        if _G.AutoSellAuras then
            task.spawn(function()
                while _G.AutoSellAuras do
                    local folder = GetAurasFolder()
                    local names = NormalizeList(SelectedSellAuras)
                    if #names > 0 then
                        local items = CollectSellTargets(folder, names, SellAuraModes, SellAuraRarity)
                        if #items == 0 then
                            items = CollectSellTargets(folder, names, SellAuraModes, nil)
                        end
                        if #items == 0 then
                            items = CollectSellTargets(folder, names, { Normal = true, Evolved = true }, nil)
                        end
                        if #items >= 1 then
                            DoSellAura(items[1])
                        end
                    end
                    task.wait(0.4)
                end
            end)
        end
    end,
})

-- ========== MISC ==========
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings", Border = true })

MiscTab:Toggle({
    Title = "User",
    Default = userEnabledFlag,
    Callback = function(Value)
        userEnabledFlag = Value == true
        pcall(function() Window:UserEnabled(Value) end)
        SaveSellMisc()
    end,
})

MiscTab:Toggle({
    Title = "Anonymous",
    Default = userAnonFlag,
    Callback = function(Value)
        userAnonFlag = Value == true
        pcall(function() Window:Anonymous(Value) end)
        SaveSellMisc()
    end,
})

task.wait(0.1)
pcall(function()
    Window:SelectTab(1)
    Window:Open()
end)

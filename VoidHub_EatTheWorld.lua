--==================================================
-- PLACE / GAME IDS (Eat The World) — reference only
--==================================================
local PLACE_ID = 16480898254
local GAME_ID = 5677613211

--==================================================
-- MAIN SERVICES & SAVE SYSTEM
--==================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

local ConfigFile = "VoidHub_EatTheWorld.json"
local loadedConfig = {}

if isfile and isfile(ConfigFile) then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigFile))
    end)
    if success and type(data) == "table" then
        loadedConfig = data
    end
end

local skyGrabEnabled = loadedConfig.skyGrabEnabled or false
local eatEnabled = loadedConfig.eatEnabled or false
local cubeCoinsEnabled = loadedConfig.cubeCoinsEnabled or false
local rewardsEnabled = loadedConfig.rewardsEnabled or false
local autoSpinEnabled = loadedConfig.autoSpinEnabled or false
local warningSellEnabled = loadedConfig.warningSellEnabled or false
local sellThreshold = loadedConfig.sellThreshold or 0
local sellEnabled = loadedConfig.sellEnabled or false
local preventSellEnabled = loadedConfig.preventSellEnabled or false
local antiRagdollEnabled = loadedConfig.antiRagdollEnabled or false
local hideBuildsEnabled = loadedConfig.hideBuildsEnabled or false
local autoSkipMapEnabled = loadedConfig.autoSkipMapEnabled or false
local autoReconnectEnabled = loadedConfig.autoReconnectEnabled
if autoReconnectEnabled == nil then autoReconnectEnabled = true end
local autoRejoinTimedEnabled = loadedConfig.autoRejoinTimedEnabled or false
local antiLagEnabled = loadedConfig.antiLagEnabled or false
local infiniteJumpEnabled = loadedConfig.infiniteJumpEnabled or false
local autoBuyMaxSizeEnabled = loadedConfig.autoBuyMaxSizeEnabled or false
local autoBuySpeedEnabled = loadedConfig.autoBuySpeedEnabled or false
local autoBuyMultiplierEnabled = loadedConfig.autoBuyMultiplierEnabled or false
local autoBuyEatSpeedEnabled = loadedConfig.autoBuyEatSpeedEnabled or false
local autoMoneyRainEnabled = loadedConfig.autoMoneyRainEnabled or false
local savedBgId = loadedConfig.backgroundImageId or ""

local applyCustomSpeed = false
local customWalkSpeed = 16
local applyCustomJump = false
local customJumpPower = 50
local noclipEnabled = false

local autoRejoinTimer = 0
local lastGrabMoveTime = 0
local currentGrabTarget = nil
local currentTween = nil
local currentTweenTarget = nil

Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

math.randomseed(os.time())

--==================================================
-- VOID UI
--==================================================
local UI_URL = "https://raw.githubusercontent.com/slowzzx4-8/Ui-library/refs/heads/main/Void%20Hub%20Library.lua"
local VexUI
do
    local ok, res = pcall(function()
        local srcCode = game:HttpGet(UI_URL)
        assert(type(srcCode) == "string" and #srcCode > 100, "empty library")
        local fn, err = loadstring(srcCode)
        assert(fn, tostring(err))
        return fn()
    end)
    if not ok or not res then
        warn("[VoidHub] Failed to load UI library: " .. tostring(res))
        return
    end
    VexUI = res
end

local Window = VexUI:CreateWindow({
    Name = "Void Hub",
    Icon = "box",
    SideBarWidth = 160,
    Theme = "Dark",
    Transparent = true,
    Author = "By Slowzzx4",
    Resizable = false,
    Size = UDim2.new(0, 537, 0, 361),
    Position = UDim2.new(0.5, 7, 0.5, -47),
    ScrollableSidebar = true,
    User = { Enabled = false, Anonymous = false },
})

pcall(function() VexUI:CreateTopbarButton({ Order = 1, Title = "@Slowzzx4", Icon = "at-sign", Callback = function() end }) end)

pcall(function()
    Window:EditOpenButton({
        Title = "Eat The World",
        Icon = "box",
        Transparency = 0.2,
        StrokeThickness = 2,
        Size = UDim2.new(0, 150, 0, 50),
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80))
        },
        AutoRotation = false,
        CornerRadius = UDim.new(0, 16),
    })
end)

--==================================================
-- BACKGROUND HELPERS
--==================================================
local customImageBg = nil
local customImageID = savedBgId or ""

local function findWindowMain()
    local function search(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ScreenGui") then
                local main = child:FindFirstChild("Void Hub")
                if main and main:IsA("Frame") then return main end
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA("Frame") and sub.Name == "Void Hub" then return sub end
                end
            end
        end
        return nil
    end
    local main = search(CoreGui)
    if main then return main end
    pcall(function() main = search(Player:WaitForChild("PlayerGui")) end)
    return main
end

local function applyBackgroundImage(id)
    id = tostring(id or ""):gsub("%s+", "")
    id = id:match("%d+") or id:match("rbxassetid://(%d+)") or ""
    if id == "" then
        VexUI:Notification({ Title = "Background", Desc = "Invalid image ID.", Icon = "x", Duration = 3 })
        return false
    end
    -- Prefer library API if available
    if Window.SetBackgroundImage then
        local ok = pcall(function() Window:SetBackgroundImage("rbxassetid://" .. id, 0.35) end)
        if ok then
            customImageID = id
            VexUI:Notification({ Title = "Background Applied", Desc = "ID: " .. id, Icon = "image", Duration = 3 })
            return true
        end
    end
    local main = findWindowMain()
    if not main then
        VexUI:Notification({ Title = "Background", Desc = "Could not find window frame.", Icon = "x", Duration = 3 })
        return false
    end
    if customImageBg and customImageBg.Parent then customImageBg:Destroy() end
    customImageBg = Instance.new("ImageLabel")
    customImageBg.Name = "VoidHub_CustomBackground"
    customImageBg.Size = UDim2.new(1, 0, 1, 0)
    customImageBg.BackgroundTransparency = 1
    customImageBg.BorderSizePixel = 0
    customImageBg.ZIndex = 0
    customImageBg.ScaleType = Enum.ScaleType.Crop
    customImageBg.ImageTransparency = 0.35
    customImageBg.Image = "rbxassetid://" .. id
    customImageBg.Parent = main
    customImageID = id
    VexUI:Notification({ Title = "Background Applied", Desc = "ID: " .. id, Icon = "image", Duration = 3 })
    return true
end

local function clearBackgroundImage()
    if Window.ClearBackground then pcall(function() Window:ClearBackground() end) end
    if customImageBg then pcall(function() customImageBg:Destroy() end) customImageBg = nil end
    local main = findWindowMain()
    if main then
        local old = main:FindFirstChild("VoidHub_CustomBackground")
        if old then old:Destroy() end
    end
    customImageID = ""
end

if savedBgId and savedBgId ~= "" then
    task.defer(function()
        task.wait(0.4)
        applyBackgroundImage(savedBgId)
    end)
end

local function getValidFragments(mapFolder)
    local frags = {}
    if mapFolder and mapFolder:FindFirstChild("Fragmentable") then
        local bedrock = mapFolder:FindFirstChild("Bedrock")
        local bedrockY = -50
        if bedrock and bedrock:IsA("BasePart") then
            bedrockY = bedrock.Position.Y + (bedrock.Size.Y / 2) - 2
        end
        for _, obj in ipairs(mapFolder.Fragmentable:GetChildren()) do
            if obj:IsA("BasePart") and obj.Position.Y >= bedrockY and obj.Position.Y <= (bedrockY + 5000) then
                table.insert(frags, obj)
            end
        end
    end
    return frags
end

local function fireRemote(pathParts, ...)
    local node = ReplicatedStorage
    for _, name in ipairs(pathParts) do
        if not node then return end
        node = node:FindFirstChild(name)
    end
    if node and (node:IsA("RemoteEvent") or node:IsA("RemoteFunction")) then
        pcall(function()
            if node:IsA("RemoteEvent") then
                node:FireServer(...)
            else
                node:InvokeServer(...)
            end
        end)
    end
end

--==================================================
-- TABS
--==================================================
local PlayerTab = Window:Tab({ Title = "Local Player", Icon = "user", Border = true })
local AutomationTab = Window:Tab({ Title = "Automation", Icon = "cpu", Border = true })
local EconomyTab = Window:Tab({ Title = "Economy", Icon = "shopping-cart", Border = true })
local WorldTab = Window:Tab({ Title = "World & Net", Icon = "globe", Border = true })
local ConfigTab = Window:Tab({ Title = "Configs", Icon = "save", Border = true })
local Section = Window:Section({ Title = "Other", Icon = "hash" })
local Settings = Section:Tab({ Title = "Settings", Icon = "settings", Border = true })

Window:SelectTab(1)

task.defer(function()
    task.wait(0.5)
    pcall(function()
        VexUI:Notification({
            Title = "!",
            Desc = "Recommended for private server!!!",
            Icon = "triangle-alert",
            Duration = 10,
        })
    end)
end)

--==================================================
-- 1. LOCAL PLAYER (Slider first, Toggle below)
--==================================================
PlayerTab:Section({ Title = "Movement Adjustments" })

PlayerTab:Slider({
    Title = "Speed Power",
    Value = { Min = 1, Max = 200, Default = 16 },
    Step = 1,
    Callback = function(Value) customWalkSpeed = Value end
})
PlayerTab:Toggle({
    Title = "Enable Custom WalkSpeed",
    Default = false,
    Callback = function(State) applyCustomSpeed = State end
})

PlayerTab:Slider({
    Title = "Jump Power",
    Value = { Min = 1, Max = 200, Default = 50 },
    Step = 1,
    Callback = function(Value) customJumpPower = Value end
})
PlayerTab:Toggle({
    Title = "Enable Custom JumpPower",
    Default = false,
    Callback = function(State) applyCustomJump = State end
})

PlayerTab:Toggle({
    Title = "Noclip",
    Desc = "Walk through walls without bugging.",
    Default = false,
    Callback = function(State) noclipEnabled = State end
})
PlayerTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Allows mid-air jumps.",
    Default = infiniteJumpEnabled,
    Callback = function(State) infiniteJumpEnabled = State end
})
PlayerTab:Toggle({
    Title = "Anti Ragdoll",
    Desc = "Prevents falling down / tripping.",
    Default = antiRagdollEnabled,
    Callback = function(State) antiRagdollEnabled = State end
})

RunService.Stepped:Connect(function()
    if noclipEnabled then
        local char = Player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

--==================================================
-- 2. AUTOMATION
--==================================================
AutomationTab:Section({ Title = "Main Exploits" })
AutomationTab:Toggle({
    Title = "Auto Eat Block",
    Desc = "Fast eat exploit.",
    Default = eatEnabled,
    Callback = function(State) eatEnabled = State end
})
AutomationTab:Toggle({
    Title = "Auto Grab (Sky Tween)",
    Desc = "Black transparent platform 120 studs above bedrock.",
    Default = skyGrabEnabled,
    Callback = function(State)
        skyGrabEnabled = State
        if State then
            VexUI:Notification({ Title = "Sky Grab Enabled", Desc = "Platform at 120 studs up.", Icon = "cloud", Duration = 4 })
        else
            local plat = workspace:FindFirstChild("VoidHub_SkyPlatform")
            if plat then plat:Destroy() end
            if currentTween then currentTween:Cancel(); currentTween = nil; currentTweenTarget = nil end
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Anchored = false
            end
        end
    end
})

AutomationTab:Section({ Title = "Auto Upgrades" })
AutomationTab:Toggle({ Title = "Auto Buy Max Size", Default = autoBuyMaxSizeEnabled, Callback = function(State) autoBuyMaxSizeEnabled = State end })
AutomationTab:Toggle({ Title = "Auto Buy Speed", Default = autoBuySpeedEnabled, Callback = function(State) autoBuySpeedEnabled = State end })
AutomationTab:Toggle({ Title = "Auto Buy Multiplier", Default = autoBuyMultiplierEnabled, Callback = function(State) autoBuyMultiplierEnabled = State end })
AutomationTab:Toggle({ Title = "Auto Buy Eat Speed", Default = autoBuyEatSpeedEnabled, Callback = function(State) autoBuyEatSpeedEnabled = State end })

AutomationTab:Section({ Title = "Misc Automation" })
AutomationTab:Toggle({
    Title = "Auto Collect Rewards",
    Desc = "Instantly claims timed rewards.",
    Default = rewardsEnabled,
    Callback = function(State) rewardsEnabled = State end
})
AutomationTab:Toggle({
    Title = "Auto Spin",
    Desc = "Spins the wheel when ready.",
    Default = autoSpinEnabled,
    Callback = function(State) autoSpinEnabled = State end
})

--==================================================
-- 3. ECONOMY
--==================================================
EconomyTab:Section({ Title = "Auto Sell Settings" })
EconomyTab:Toggle({
    Title = "Auto Sell Max Block",
    Desc = "Sells when max warning shows.",
    Default = warningSellEnabled,
    Callback = function(State) warningSellEnabled = State end
})
EconomyTab:Toggle({
    Title = "Auto Sell Number",
    Desc = "Sells at custom threshold.",
    Default = sellEnabled,
    Callback = function(State) sellEnabled = State end
})
EconomyTab:Input({
    Title = "Set Auto Sell Limit",
    Desc = "Current limit: " .. tostring(sellThreshold),
    Callback = function(Text)
        local parsed = tonumber(string.match(Text, "%d+"))
        sellThreshold = parsed or 0
    end
})
EconomyTab:Toggle({
    Title = "Prevent Sell Button",
    Desc = "Hides manual sell button on UI.",
    Default = preventSellEnabled,
    Callback = function(State)
        preventSellEnabled = State
        pcall(function()
            local sellBtn = Player.PlayerGui.ScreenGui.Sell:FindFirstChild("SellButton")
            if sellBtn then sellBtn.Visible = not State end
        end)
    end
})

EconomyTab:Section({ Title = "Event Snipers" })
EconomyTab:Toggle({
    Title = "Auto Collect Cubes",
    Desc = "Collects all map cubes, including other players'.",
    Default = cubeCoinsEnabled,
    Callback = function(State) cubeCoinsEnabled = State end
})
EconomyTab:Toggle({
    Title = "Auto Money Rain",
    Desc = "Triggers money rain event.",
    Default = autoMoneyRainEnabled,
    Callback = function(State) autoMoneyRainEnabled = State end
})

--==================================================
-- 4. WORLD & NET
--==================================================
WorldTab:Section({ Title = "Environment Optimizations" })
WorldTab:Toggle({
    Title = "Anti Lag",
    Desc = "Removes shadows, effects and heavy materials.",
    Default = antiLagEnabled,
    Callback = function(State)
        antiLagEnabled = State
        if State then
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                pcall(function()
                    local s = settings()
                    if s and s.Rendering then
                        s.Rendering.QualityLevel = 1
                    end
                end)
            end)
        end
    end
})
WorldTab:Toggle({
    Title = "Hide ALL Buildings",
    Desc = "Hides buildings to boost FPS.",
    Default = hideBuildsEnabled,
    Callback = function(State) hideBuildsEnabled = State end
})
WorldTab:Toggle({
    Title = "Auto Skip Map",
    Desc = "Skips map automatically.",
    Default = autoSkipMapEnabled,
    Callback = function(State) autoSkipMapEnabled = State end
})

WorldTab:Section({ Title = "Network Controllers" })
WorldTab:Toggle({
    Title = "Auto Reconnect",
    Desc = "Rejoins on Roblox disconnect error.",
    Default = autoReconnectEnabled,
    Callback = function(State) autoReconnectEnabled = State end
})
WorldTab:Toggle({
    Title = "Auto Rejoin",
    Desc = "Forces server rejoin periodically (100 min).",
    Default = autoRejoinTimedEnabled,
    Callback = function(State) autoRejoinTimedEnabled = State; autoRejoinTimer = 0 end
})

--==================================================
-- 5. CONFIGS
--==================================================
ConfigTab:Section({ Title = "Configuration Data" })
ConfigTab:Button({
    Title = "Save Configuration",
    Callback = function()
        local currentSettings = {
            eatEnabled = eatEnabled,
            skyGrabEnabled = skyGrabEnabled,
            cubeCoinsEnabled = cubeCoinsEnabled,
            rewardsEnabled = rewardsEnabled,
            autoSpinEnabled = autoSpinEnabled,
            warningSellEnabled = warningSellEnabled,
            sellThreshold = sellThreshold,
            sellEnabled = sellEnabled,
            preventSellEnabled = preventSellEnabled,
            antiRagdollEnabled = antiRagdollEnabled,
            hideBuildsEnabled = hideBuildsEnabled,
            autoSkipMapEnabled = autoSkipMapEnabled,
            autoReconnectEnabled = autoReconnectEnabled,
            autoRejoinTimedEnabled = autoRejoinTimedEnabled,
            antiLagEnabled = antiLagEnabled,
            infiniteJumpEnabled = infiniteJumpEnabled,
            autoBuyMaxSizeEnabled = autoBuyMaxSizeEnabled,
            autoBuySpeedEnabled = autoBuySpeedEnabled,
            autoBuyMultiplierEnabled = autoBuyMultiplierEnabled,
            autoBuyEatSpeedEnabled = autoBuyEatSpeedEnabled,
            autoMoneyRainEnabled = autoMoneyRainEnabled,
            backgroundImageId = customImageID,
        }
        if writefile then
            writefile(ConfigFile, HttpService:JSONEncode(currentSettings))
            VexUI:Notification({ Title = "Saved", Desc = "Configuration saved.", Icon = "check", Duration = 3 })
        end
    end
})
ConfigTab:Button({
    Title = "Delete Configuration",
    Callback = function()
        if delfile and isfile and isfile(ConfigFile) then
            delfile(ConfigFile)
            VexUI:Notification({ Title = "Deleted", Desc = "Configuration deleted.", Icon = "trash", Duration = 3 })
        end
    end
})

--==================================================
-- 6. SETTINGS
--==================================================
Settings:Section({ Title = "Theme & UI" })
Settings:Dropdown({
    Title = "Theme",
    Option = {
        "Dark", "Light", "Pink", "Blue", "Purple", "Yellow", "Green", "Brown", "Red", "Cyan",
        "Orange", "Lime", "Teal", "Indigo", "Violet", "Magenta", "Sky", "Amber", "Emerald",
        "Coral", "Gold", "Silver", "Navy", "Mint", "Peach", "Lavender", "Crimson", "Forest",
        "Midnight", "Neon", "Sunset", "Ocean", "Grape", "White", "Gray", "Stone", "Zinc", "Slate", "Rose"
    },
    Value = "Dark",
    Callback = function(Value) Window:SetTheme(Value) end
})
Settings:Toggle({
    Title = "Transparent UI",
    Default = true,
    Callback = function(Value) Window:SetTransparency(Value) end
})
Settings:Toggle({
    Title = "Acrylic Mode (Blur)",
    Default = false,
    Callback = function(Value)
        -- New Void Hub uses ToggleAcrylic (simulated acrylic blur)
        local ok = pcall(function()
            if Window.ToggleAcrylic then
                Window:ToggleAcrylic(Value)
            elseif Window.SetAcrylic then
                Window:SetAcrylic(Value)
            else
                -- Fallback: strong transparency
                Window:SetTransparency(Value and 0.55 or (true and 0.1 or 0))
            end
        end)
        if not ok then
            pcall(function() Window:SetTransparency(Value and 0.55 or 0.1) end)
        end
    end
})

Settings:Section({ Title = "Custom Background" })
Settings:Input({
    Title = "Custom Background ID",
    Desc = "Numbers only or rbxassetid://...",
    Value = customImageID,
    Callback = function(Text)
        local id = tostring(Text or ""):gsub("%s+", "")
        id = id:match("%d+") or id:match("rbxassetid://(%d+)") or ""
        customImageID = id
    end
})
Settings:Button({
    Title = "Apply Background",
    Callback = function() applyBackgroundImage(customImageID) end
})
Settings:Button({
    Title = "Clear Background",
    Callback = function()
        clearBackgroundImage()
        VexUI:Notification({ Title = "Background Cleared", Desc = "Custom image removed.", Icon = "check", Duration = 3 })
    end
})

Settings:Section({ Title = "Actions" })
Settings:Button({ Title = "Destroy UI", Callback = function() Window:Destroy() end })

--==================================================
-- LOOPS
--==================================================

-- Speed / Jump
task.spawn(function()
    while task.wait(0.1) do
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
            if applyCustomSpeed then hum.WalkSpeed = customWalkSpeed end
            if applyCustomJump then
                hum.UseJumpPower = true
                hum.JumpPower = customJumpPower
            end
        end
    end
end)

-- Timed rejoin (100 min)
task.spawn(function()
    while task.wait(1) do
        if autoRejoinTimedEnabled then
            autoRejoinTimer = autoRejoinTimer + 1
            if autoRejoinTimer >= 6000 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
            end
        end
    end
end)

-- Hide TemplateChunk far away
task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local chunks = workspace:FindFirstChild("Chunks")
            if chunks and root then
                for _, chunk in ipairs(chunks:GetChildren()) do
                    if chunk.Name == "TemplateChunk" then
                        local firstPart = chunk:FindFirstChildWhichIsA("BasePart", true)
                        if firstPart and (firstPart.Position - root.Position).Magnitude > 30 then
                            for _, part in ipairs(chunk:GetDescendants()) do
                                if part:IsA("BasePart") and part.Transparency ~= 1 then
                                    part.Transparency = 1
                                    part.CanCollide = false
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

GuiService.ErrorMessageChanged:Connect(function()
    if autoReconnectEnabled then
        task.wait(0.1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end
end)

-- Anti-void / bedrock clamp
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local char = Player.Character
            if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
            local root = char.HumanoidRootPart
            local hum = char:FindFirstChild("Humanoid")
            local map = workspace:FindFirstChild("Map")
            local bedrock = map and map:FindFirstChild("Bedrock")
            if not (bedrock and bedrock:IsA("BasePart")) then return end

            local lowestY = bedrock.Position.Y + (bedrock.Size.Y / 2) - 3
            if root.Position.Y < lowestY or math.abs(root.Position.Y - bedrock.Position.Y) < 5 then
                if not skyGrabEnabled then
                    root.Anchored = false
                    root.CFrame = root.CFrame + Vector3.new(0, 18, 0)
                    currentGrabTarget = nil
                    if hum then hum.Jump = true end
                end
            end

            local bedSize, bedPos = bedrock.Size, bedrock.Position
            local minX, maxX = bedPos.X - bedSize.X / 2, bedPos.X + bedSize.X / 2
            local minZ, maxZ = bedPos.Z - bedSize.Z / 2, bedPos.Z + bedSize.Z / 2
            local cx = math.clamp(root.Position.X, minX, maxX)
            local cz = math.clamp(root.Position.Z, minZ, maxZ)
            if root.Position.X ~= cx or root.Position.Z ~= cz then
                root.CFrame = CFrame.new(cx, root.Position.Y, cz)
                if currentTween then currentTween:Cancel(); currentTweenTarget = nil end
            end
        end)
    end
end)

-- Auto Eat
task.spawn(function()
    while task.wait(0.05) do
        if eatEnabled then
            pcall(function()
                local char = Player.Character
                if char and char:FindFirstChild("Events") and char.Events:FindFirstChild("Eat") then
                    char.Events.Eat:FireServer()
                end
            end)
        end
    end
end)

-- Auto Grab Sky (120 studs) — locked on top of platform
local SKY_HEIGHT = 120

local function getStandHeight(char, hum)
    local hip = 2
    pcall(function()
        if hum and hum.HipHeight then hip = math.max(hum.HipHeight, 1) end
    end)
    local half = hip
    pcall(function()
        local size = char:GetExtentsSize()
        half = math.clamp(size.Y / 2, hip, 12)
    end)
    return half + 1.5
end

local function syncSkyPlatform(bedrock)
    local platform = workspace:FindFirstChild("VoidHub_SkyPlatform")
    local targetSize = Vector3.new(bedrock.Size.X, 2, bedrock.Size.Z)
    local targetPos = bedrock.Position + Vector3.new(0, SKY_HEIGHT, 0)
    if not platform then
        platform = Instance.new("Part")
        platform.Name = "VoidHub_SkyPlatform"
        platform.Anchored = true
        platform.CanCollide = true
        platform.Transparency = 0.5
        platform.BrickColor = BrickColor.new("Really black")
        platform.Material = Enum.Material.SmoothPlastic
        platform.Parent = workspace
    end
    platform.Size = targetSize
    platform.CFrame = CFrame.new(targetPos)
    return platform
end

task.spawn(function()
    while task.wait(0.05) do
        if skyGrabEnabled then
            pcall(function()
                local char = Player.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                local mapFolder = workspace:FindFirstChild("Map")
                local bedrock = mapFolder and mapFolder:FindFirstChild("Bedrock")
                if not (root and hum and hum.Health > 0 and bedrock and bedrock:IsA("BasePart")) then return end

                if char:FindFirstChild("Events") and char.Events:FindFirstChild("Grab") then
                    char.Events.Grab:FireServer(false, false, false)
                end

                local platform = syncSkyPlatform(bedrock)
                local standH = getStandHeight(char, hum)
                local lockY = platform.Position.Y + (platform.Size.Y / 2) + standH

                root.Anchored = true
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end)

                if math.abs(root.Position.Y - lockY) > 0.05 then
                    root.CFrame = CFrame.new(root.Position.X, lockY, root.Position.Z)
                end

                local bedSize, bedPos = bedrock.Size, bedrock.Position
                local minX = bedPos.X - bedSize.X / 2 + 2
                local maxX = bedPos.X + bedSize.X / 2 - 2
                local minZ = bedPos.Z - bedSize.Z / 2 + 2
                local maxZ = bedPos.Z + bedSize.Z / 2 - 2

                local fragments = getValidFragments(mapFolder)
                if #fragments > 0 then
                    if currentGrabTarget and not currentGrabTarget:IsDescendantOf(workspace) then
                        currentGrabTarget = nil
                    end
                    local reachDist = 8
                    local distToTarget = math.huge
                    if currentGrabTarget then
                        distToTarget = Vector2.new(
                            root.Position.X - currentGrabTarget.Position.X,
                            root.Position.Z - currentGrabTarget.Position.Z
                        ).Magnitude
                    end
                    if not currentGrabTarget or distToTarget < reachDist or (tick() - lastGrabMoveTime > 5) then
                        lastGrabMoveTime = tick()
                        currentGrabTarget = fragments[math.random(1, #fragments)]
                        currentTweenTarget = nil
                    end
                    if currentGrabTarget then
                        local tx = math.clamp(currentGrabTarget.Position.X, minX, maxX)
                        local tz = math.clamp(currentGrabTarget.Position.Z, minZ, maxZ)
                        if currentTweenTarget ~= currentGrabTarget then
                            currentTweenTarget = currentGrabTarget
                            if currentTween then pcall(function() currentTween:Cancel() end) end
                            local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(tx, 0, tz)).Magnitude
                            local tTime = math.max(dist / 70, 0.08)
                            currentTween = TweenService:Create(
                                root,
                                TweenInfo.new(tTime, Enum.EasingStyle.Linear),
                                { CFrame = CFrame.new(tx, lockY, tz) }
                            )
                            currentTween:Play()
                        end
                        if math.abs(root.Position.Y - lockY) > 0.1 then
                            root.CFrame = CFrame.new(root.Position.X, lockY, root.Position.Z)
                        end
                    end
                else
                    root.CFrame = CFrame.new(
                        math.clamp(root.Position.X, minX, maxX),
                        lockY,
                        math.clamp(root.Position.Z, minZ, maxZ)
                    )
                end
            end)
        end
    end
end)

-- Auto Collect Cubes (all cubes, including other players)
local function isCubeLike(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = string.lower(obj.Name)
    if n:find("cube") or n:find("coin") or n:find("money") or n:find("cash") or n:find("gem") then
        return true
    end
    if obj:GetAttribute("IsCube") or obj:GetAttribute("Coin") then return true end
    return false
end

local function collectCube(part)
    pcall(function()
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then
            for _, evName in ipairs({ "CollectCube", "CollectCoin", "PickupCube", "Cube", "Coin", "Collect" }) do
                local ev = events:FindFirstChild(evName)
                if ev and ev:IsA("RemoteEvent") then
                    pcall(function() ev:FireServer(part) end)
                    pcall(function() ev:FireServer(part.Name) end)
                end
            end
        end
        if part.Parent and part:IsA("BasePart") then
            part.CanCollide = false
            part.Anchored = false
            part.CFrame = root.CFrame
            if typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(root, part, 0)
                    firetouchinterest(root, part, 1)
                end)
            end
        end
    end)
end

task.spawn(function()
    while task.wait(0.15) do
        if cubeCoinsEnabled then
            pcall(function()
                local found = {}
                local function scan(container)
                    if not container then return end
                    for _, obj in ipairs(container:GetDescendants()) do
                        if isCubeLike(obj) then table.insert(found, obj) end
                    end
                end
                scan(workspace:FindFirstChild("Map"))
                scan(workspace:FindFirstChild("Cubes"))
                scan(workspace:FindFirstChild("Coins"))
                scan(workspace:FindFirstChild("Drops"))
                scan(workspace:FindFirstChild("Pickups"))
                for _, obj in ipairs(workspace:GetChildren()) do
                    if isCubeLike(obj) then
                        table.insert(found, obj)
                    elseif obj:IsA("Folder") or obj:IsA("Model") then
                        local ln = string.lower(obj.Name)
                        if ln:find("cube") or ln:find("coin") or ln:find("drop") or ln:find("pickup") then
                            scan(obj)
                        end
                    end
                end
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character then scan(plr.Character) end
                end
                for _, cube in ipairs(found) do collectCube(cube) end
            end)
        end
    end
end)

-- Auto Collect Rewards
task.spawn(function()
    while task.wait(3) do
        if rewardsEnabled then
            pcall(function()
                local timedRewards = Player:FindFirstChild("TimedRewards")
                if timedRewards then
                    for i = 1, 12 do
                        fireRemote({ "Events", "RewardEvent" }, i)
                        fireRemote({ "Events", "RewardEvent" }, tostring(i))
                    end
                    for _, child in ipairs(timedRewards:GetChildren()) do
                        fireRemote({ "Events", "RewardEvent" }, child.Name)
                        fireRemote({ "Events", "RewardEvent" }, child)
                    end
                end
                -- fallback names
                fireRemote({ "Events", "ClaimReward" })
                fireRemote({ "Events", "CollectReward" })
            end)
        end
    end
end)

-- Auto Spin (wheel)
task.spawn(function()
    while task.wait(1.5) do
        if autoSpinEnabled then
            pcall(function()
                local events = ReplicatedStorage:FindFirstChild("Events")
                if events then
                    for _, name in ipairs({ "Spin", "SpinWheel", "WheelSpin", "UseSpin", "FreeSpin", "ClaimSpin" }) do
                        local ev = events:FindFirstChild(name)
                        if ev then
                            pcall(function()
                                if ev:IsA("RemoteEvent") then ev:FireServer() end
                                if ev:IsA("RemoteFunction") then ev:InvokeServer() end
                            end)
                        end
                    end
                end
                -- Character events
                local char = Player.Character
                if char and char:FindFirstChild("Events") then
                    for _, name in ipairs({ "Spin", "SpinWheel" }) do
                        local ev = char.Events:FindFirstChild(name)
                        if ev and ev:IsA("RemoteEvent") then
                            pcall(function() ev:FireServer() end)
                        end
                    end
                end
                -- GUI click fallback removed (was freezing some executors)

            end)
        end
    end
end)

-- Auto Buy upgrades
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local events = ReplicatedStorage:FindFirstChild("Events")
            local buy = events and (events:FindFirstChild("Buy") or events:FindFirstChild("Purchase") or events:FindFirstChild("Upgrade"))
            local function tryBuy(id)
                if not buy then return end
                pcall(function()
                    if buy:IsA("RemoteEvent") then
                        buy:FireServer(id)
                        buy:FireServer(tostring(id))
                        buy:FireServer({ Upgrade = id })
                    elseif buy:IsA("RemoteFunction") then
                        buy:InvokeServer(id)
                    end
                end)
            end
            if autoBuyMaxSizeEnabled then
                for _, id in ipairs({ "MaxSize", "Size", "Max Size", "SizeUpgrade", 1, "1" }) do tryBuy(id) end
                fireRemote({ "Events", "BuyMaxSize" })
                fireRemote({ "Events", "UpgradeSize" })
            end
            if autoBuySpeedEnabled then
                for _, id in ipairs({ "Speed", "WalkSpeed", "SpeedUpgrade", 2, "2" }) do tryBuy(id) end
                fireRemote({ "Events", "BuySpeed" })
                fireRemote({ "Events", "UpgradeSpeed" })
            end
            if autoBuyMultiplierEnabled then
                for _, id in ipairs({ "Multiplier", "Multi", "MoneyMulti", 3, "3" }) do tryBuy(id) end
                fireRemote({ "Events", "BuyMultiplier" })
                fireRemote({ "Events", "UpgradeMultiplier" })
            end
            if autoBuyEatSpeedEnabled then
                for _, id in ipairs({ "EatSpeed", "Eat", "EatUpgrade", 4, "4" }) do tryBuy(id) end
                fireRemote({ "Events", "BuyEatSpeed" })
                fireRemote({ "Events", "UpgradeEatSpeed" })
            end
        end)
    end
end)

-- Auto Money Rain
task.spawn(function()
    while task.wait(2) do
        if autoMoneyRainEnabled then
            pcall(function()
                for _, name in ipairs({ "MoneyRain", "StartMoneyRain", "Rain", "CashRain", "TriggerMoneyRain" }) do
                    fireRemote({ "Events", name })
                end
                local events = ReplicatedStorage:FindFirstChild("Events")
                if events then
                    for _, child in ipairs(events:GetChildren()) do
                        local n = string.lower(child.Name)
                        if n:find("rain") or n:find("moneyrain") then
                            pcall(function()
                                if child:IsA("RemoteEvent") then child:FireServer() end
                            end)
                        end
                    end
                end
            end)
        end
    end
end)

-- Anti Lag continuous (lightweight — does not scan whole workspace every tick)
task.spawn(function()
    while task.wait(3) do
        if antiLagEnabled then
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                pcall(function()
                    local s = settings()
                    if s and s.Rendering then
                        s.Rendering.QualityLevel = 1
                    end
                end)
            end)
            -- Only disable effects under Map / common folders (avoids lagging the executor)
            pcall(function()
                local targets = {
                    workspace:FindFirstChild("Map"),
                    workspace:FindFirstChild("Chunks"),
                    workspace:FindFirstChild("Buildings"),
                    workspace:FindFirstChild("Effects"),
                }
                for _, folder in ipairs(targets) do
                    if folder then
                        for _, obj in ipairs(folder:GetDescendants()) do
                            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                                pcall(function() obj.Enabled = false end)
                            elseif obj:IsA("BasePart") then
                                pcall(function() obj.CastShadow = false end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Hide buildings
task.spawn(function()
    while task.wait(1) do
        if hideBuildsEnabled then
            pcall(function()
                for _, name in ipairs({ "Buildings", "Building", "Decor", "Decorations", "Trees", "Props" }) do
                    local folder = workspace:FindFirstChild(name)
                    if folder then
                        for _, part in ipairs(folder:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Transparency = 1
                                part.CanCollide = false
                            elseif part:IsA("Decal") or part:IsA("Texture") then
                                part.Transparency = 1
                            end
                        end
                    end
                end
                local map = workspace:FindFirstChild("Map")
                if map then
                    for _, child in ipairs(map:GetChildren()) do
                        local n = string.lower(child.Name)
                        if n:find("build") or n:find("decor") or n:find("tree") or n:find("prop") then
                            for _, part in ipairs(child:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.Transparency = 1
                                    part.CanCollide = false
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Anti Ragdoll
task.spawn(function()
    while task.wait(0.5) do
        if antiRagdollEnabled then
            pcall(function()
                fireRemote({ "Events", "unRagdoll" })
                fireRemote({ "Events", "UnRagdoll" })
                local char = Player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end
    end
end)

-- Auto Skip Map
task.spawn(function()
    while task.wait(60) do
        if autoSkipMapEnabled then
            pcall(function()
                local ev = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("SetServerSettings")
                if ev then ev:FireServer({ MapTime = 0 }) end
                fireRemote({ "Events", "SkipMap" })
                fireRemote({ "Events", "Skip" })
            end)
        end
    end
end)

-- Auto Sell (warning + threshold)
task.spawn(function()
    while task.wait(1) do
        if warningSellEnabled then
            pcall(function()
                local s = Player.PlayerGui.ScreenGui.Sell
                if s and s:FindFirstChild("WarningText") and s.WarningText.Visible then
                    Player.Character.Events.Sell:FireServer()
                end
            end)
        end
        if sellEnabled and sellThreshold > 0 then
            pcall(function()
                if tonumber(Player.leaderstats.Size.Value) >= sellThreshold then
                    Player.Character.Events.Sell:FireServer()
                end
            end)
        end
    end
end)

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

local CONFIG_PATH = "SupremeHub/MuscleLegends.json"
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
-- CUSTOM UI LIBRARY
-- ==========================================
local UI = {}
UI.__index = UI

local COLORS = {
	Bg = Color3.fromRGB(0, 0, 0),
	BgTrans = Color3.fromRGB(8, 8, 8),
	Sidebar = Color3.fromRGB(0, 0, 0),
	Section = Color3.fromRGB(10, 10, 10),
	Control = Color3.fromRGB(16, 16, 16),
	ControlHover = Color3.fromRGB(28, 28, 28),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(180, 180, 180),
	Red = Color3.fromRGB(220, 40, 40), -- only for @By author + critical
	RedDim = Color3.fromRGB(80, 80, 80),
	Accent = Color3.fromRGB(255, 255, 255),
	Blue = Color3.fromRGB(255, 255, 255),
	BlueLight = Color3.fromRGB(255, 255, 255),
	ToggleOn = Color3.fromRGB(255, 255, 255),
	ToggleOff = Color3.fromRGB(40, 40, 40),
	Stroke = Color3.fromRGB(50, 50, 50),
	White = Color3.fromRGB(255, 255, 255),
	Green = Color3.fromRGB(50, 205, 90),
	Orange = Color3.fromRGB(255, 160, 40),
	Black = Color3.fromRGB(0, 0, 0),
}

local OpenDropdowns = {} -- close others when one opens

local function playClick()
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = CLICK_SOUND_ID
		s.Volume = 0.35
		s.Parent = SoundService
		s:Play()
		task.delay(1, function() s:Destroy() end)
	end)
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.Stroke
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function pad(parent, t, r, b, l)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.PaddingLeft = UDim.new(0, l or 0)
	p.Parent = parent
	return p
end

local function gradient(parent, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1 or COLORS.Bg),
		ColorSequenceKeypoint.new(1, c2 or COLORS.Blue),
	})
	g.Rotation = rot or 90
	g.Parent = parent
	return g
end

local function makeIcon(parent, iconName, size, color)
	local img = Instance.new("ImageLabel")
	img.Name = "Icon"
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromOffset(size or 16, size or 16)
	img.ImageColor3 = color or COLORS.Text
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = parent
	local id = GetIcon(iconName)
	if id then
		img.Image = id
	else
		img.Visible = false
	end
	return img
end


local function textStroke(lbl, thickness)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(0, 0, 0)
	s.Thickness = thickness or 1.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = lbl
	return s
end

local function closeAllDropdowns()
	for _, closer in pairs(OpenDropdowns) do
		pcall(closer)
	end
	table.clear(OpenDropdowns)
end

function UI.CreateWindow(opts)
	opts = opts or {}
	local self = setmetatable({}, UI)
	self.Tabs = {}
	self.CurrentTab = nil
	self.Visible = true
	self.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightControl
	self.Minimized = false

	local guiParent = CoreGui
	pcall(function() if gethui then guiParent = gethui() end end)

	pcall(function()
		local old = guiParent:FindFirstChild("SupremeHubUI")
		if old then old:Destroy() end
		local oldBtn = guiParent:FindFirstChild("SupremeHubOpenBtn")
		if oldBtn then oldBtn:Destroy() end
	end)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SupremeHubUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.DisplayOrder = 200000
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = guiParent
	self.Gui = screenGui

	-- Main frame (dark blue + red glow border)
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(480, 360)
	main.Position = UDim2.new(0.5, -240, 0.5, -180)
	main.BackgroundColor3 = COLORS.Bg
	main.BackgroundTransparency = 0.25
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = screenGui
	corner(main, 12)
	stroke(main, Color3.fromRGB(180, 180, 180), 0.6)
	gradient(main, Color3.fromRGB(0, 0, 0), Color3.fromRGB(20, 20, 20), 135)
	self.Main = main

	-- Header bar
	local dragBar = Instance.new("Frame")
	dragBar.Name = "DragBar"
	dragBar.Size = UDim2.new(1, 0, 0, 35)
	dragBar.BackgroundColor3 = COLORS.Sidebar
	dragBar.BackgroundTransparency = 0.2
	dragBar.BorderSizePixel = 0
	dragBar.Parent = main
	corner(dragBar, 12)

	local titleIcon = makeIcon(dragBar, opts.Icon or "dumbbell", 14, COLORS.White)
	titleIcon.Position = UDim2.fromOffset(10, 10)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(36, 3)
	title.Size = UDim2.new(0, 160, 0, 18)
	title.Font = Enum.Font.GothamBold
	title.Text = "Supreme Hub MuscleLegends"
	title.TextColor3 = COLORS.White
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = dragBar
	textStroke(title, 1.2)

	local author = Instance.new("TextLabel")
	author.Name = "Author"
	author.BackgroundTransparency = 1
	author.Position = UDim2.fromOffset(36, 18)
	author.Size = UDim2.new(0, 160, 0, 14)
	author.Font = Enum.Font.GothamBold
	author.Text = "@By Slowzzx4"
	author.TextColor3 = COLORS.Red
	author.TextSize = 10
	author.TextXAlignment = Enum.TextXAlignment.Left
	author.Parent = dragBar
	textStroke(author, 1.2)

	-- Header action buttons (right side)
	local function headerBtn(name, iconName, order)
		local b = Instance.new("TextButton")
		b.Name = name
		b.Size = UDim2.fromOffset(22, 22)
		b.Position = UDim2.new(1, -10 - order * 28, 0.5, -11)
		b.BackgroundColor3 = COLORS.Control
		b.BackgroundTransparency = 0.3
		b.BorderSizePixel = 0
		b.Text = ""
		b.AutoButtonColor = false
		b.Parent = dragBar
		corner(b, 5)
		stroke(b, Color3.fromRGB(40, 40, 40), 1)
		local ic = makeIcon(b, iconName, 12, COLORS.White)
		ic.Position = UDim2.fromOffset(5, 5)
		b.MouseEnter:Connect(function()
			b.BackgroundTransparency = 0.05
			ic.ImageColor3 = COLORS.White
		end)
		b.MouseLeave:Connect(function()
			b.BackgroundTransparency = 0.3
			ic.ImageColor3 = COLORS.TextDim
		end)
		return b
	end

	local btnDestroy = headerBtn("Destroy", "x", 1)
	local btnFull = headerBtn("Fullscreen", "maximize", 2)
	local btnMin = headerBtn("Minimize", "minus", 3)

	-- Search box (Void UI style) next to minimize
	-- Void-style Search (button expands, results panel)
	self.SearchItems = {}
	local searchBtn = Instance.new("TextButton")
	searchBtn.Name = "SearchButton"
	searchBtn.Size = UDim2.fromOffset(34, 26)
	-- keep clear of minimize (order 3): position further left with gap
	searchBtn.Position = UDim2.new(1, -10 - 3 * 28 - 42, 0.5, -13)
	searchBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
	searchBtn.BackgroundTransparency = 0.2
	searchBtn.BorderSizePixel = 0
	searchBtn.Text = ""
	searchBtn.AutoButtonColor = false
	searchBtn.Parent = dragBar
	corner(searchBtn, 8)
	stroke(searchBtn, Color3.fromRGB(180, 180, 180), 0.6)
	local searchBtnIcon = Instance.new("TextLabel")
	searchBtnIcon.Size = UDim2.fromScale(1, 1)
	searchBtnIcon.BackgroundTransparency = 1
	searchBtnIcon.Text = "⌕"
	searchBtnIcon.TextColor3 = Color3.fromRGB(230, 230, 230)
	searchBtnIcon.TextSize = 16
	searchBtnIcon.Font = Enum.Font.Gotham
	searchBtnIcon.Parent = searchBtn

	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchFrame"
	searchFrame.Size = UDim2.fromOffset(0, 28)
	searchFrame.Position = UDim2.new(1, -10 - 3 * 28 - 42, 0.5, -14)
	searchFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
	searchFrame.BackgroundTransparency = 0.05
	searchFrame.BorderSizePixel = 0
	searchFrame.ClipsDescendants = true
	searchFrame.Visible = false
	searchFrame.Parent = dragBar
	corner(searchFrame, 8)
	stroke(searchFrame, Color3.fromRGB(180, 180, 180), 0.6)
	local searchIcon2 = Instance.new("TextLabel")
	searchIcon2.Size = UDim2.fromOffset(24, 28)
	searchIcon2.BackgroundTransparency = 1
	searchIcon2.Text = "⌕"
	searchIcon2.TextColor3 = Color3.fromRGB(200, 200, 200)
	searchIcon2.TextSize = 14
	searchIcon2.Font = Enum.Font.Gotham
	searchIcon2.Parent = searchFrame
	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchInput"
	searchBox.Size = UDim2.new(1, -28, 1, 0)
	searchBox.Position = UDim2.fromOffset(26, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 11
	searchBox.TextColor3 = COLORS.White
	searchBox.PlaceholderText = "Search..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
	searchBox.Text = ""
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchFrame
	self.SearchBox = searchBox

	local resultsFrame = Instance.new("Frame")
	resultsFrame.Name = "SearchResults"
	resultsFrame.Size = UDim2.fromOffset(280, 0)
	resultsFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
	resultsFrame.BackgroundTransparency = 0.05
	resultsFrame.BorderSizePixel = 0
	resultsFrame.Visible = false
	resultsFrame.ClipsDescendants = true
	resultsFrame.ZIndex = 50
	resultsFrame.Parent = self.Gui
	corner(resultsFrame, 10)
	stroke(resultsFrame, Color3.fromRGB(180, 180, 180), 0.6)
	local resultsScroll = Instance.new("ScrollingFrame")
	resultsScroll.Size = UDim2.new(1, -8, 1, -8)
	resultsScroll.Position = UDim2.fromOffset(4, 4)
	resultsScroll.BackgroundTransparency = 1
	resultsScroll.BorderSizePixel = 0
	resultsScroll.ScrollBarThickness = 2
	resultsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	resultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	resultsScroll.ZIndex = 51
	resultsScroll.Parent = resultsFrame
	local resultsLayout = Instance.new("UIListLayout")
	resultsLayout.Padding = UDim.new(0, 4)
	resultsLayout.Parent = resultsScroll
	local noResults = Instance.new("TextLabel")
	noResults.Size = UDim2.new(1, -10, 0, 40)
	noResults.BackgroundTransparency = 1
	noResults.Text = "No results found"
	noResults.TextColor3 = Color3.fromRGB(140, 140, 140)
	noResults.TextSize = 12
	noResults.Font = Enum.Font.Gotham
	noResults.Visible = false
	noResults.ZIndex = 52
	noResults.Parent = resultsScroll

	local searchOpened = false
	local function positionResults()
		local mp = main.AbsolutePosition
		local ms = main.AbsoluteSize
		resultsFrame.Position = UDim2.fromOffset(mp.X + ms.X - 290, mp.Y + 40)
	end
	local function clearResults()
		for _, ch in ipairs(resultsScroll:GetChildren()) do
			if ch:IsA("TextButton") then ch:Destroy() end
		end
	end
	local function closeSearch()
		searchOpened = false
		searchBox.Text = ""
		resultsFrame.Visible = false
		resultsFrame.Size = UDim2.fromOffset(280, 0)
		TweenService:Create(searchFrame, TweenInfo.new(0.15), {Size = UDim2.fromOffset(0, 28)}):Play()
		task.delay(0.16, function()
			if not searchOpened then
				searchFrame.Visible = false
				searchBtn.Visible = true
			end
		end)
	end
	local function openSearch()
		if searchOpened then return end
		searchOpened = true
		searchBtn.Visible = false
		searchFrame.Visible = true
		searchFrame.Size = UDim2.fromOffset(0, 28)
		TweenService:Create(searchFrame, TweenInfo.new(0.18), {Size = UDim2.fromOffset(180, 28)}):Play()
		task.defer(function() searchBox:CaptureFocus() end)
	end
	local function updateSearch(query)
		query = string.lower(tostring(query or ""))
		clearResults()
		noResults.Visible = false
		if query == "" then
			resultsFrame.Visible = false
			resultsFrame.Size = UDim2.fromOffset(280, 0)
			return
		end
		local matches = {}
		for _, item in ipairs(self.SearchItems) do
			local text = string.lower((item.Title or "") .. " " .. (item.Type or "") .. " " .. (item.TabTitle or ""))
			if string.find(text, query, 1, true) then
				table.insert(matches, item)
			end
		end
		positionResults()
		resultsFrame.Visible = true
		if #matches == 0 then
			noResults.Visible = true
			resultsFrame.Size = UDim2.fromOffset(280, 52)
			return
		end
		for _, item in ipairs(matches) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -4, 0, 44)
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 32)
			btn.BackgroundTransparency = 1
			btn.BorderSizePixel = 0
			btn.Text = ""
			btn.AutoButtonColor = false
			btn.ZIndex = 52
			btn.Parent = resultsScroll
			corner(btn, 6)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Position = UDim2.fromOffset(10, 4)
			t.Size = UDim2.new(1, -16, 0, 18)
			t.Font = Enum.Font.GothamBold
			t.Text = item.Title or ""
			t.TextColor3 = COLORS.White
			t.TextSize = 12
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.ZIndex = 53
			t.Parent = btn
			local d = Instance.new("TextLabel")
			d.BackgroundTransparency = 1
			d.Position = UDim2.fromOffset(10, 22)
			d.Size = UDim2.new(1, -16, 0, 16)
			d.Font = Enum.Font.Gotham
			d.Text = (item.TabTitle or "") .. (item.Type and (" • " .. item.Type) or "")
			d.TextColor3 = Color3.fromRGB(150, 150, 150)
			d.TextSize = 10
			d.TextXAlignment = Enum.TextXAlignment.Left
			d.ZIndex = 53
			d.Parent = btn
			btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.4 end)
			btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 1 end)
			btn.MouseButton1Click:Connect(function()
				playClick()
				if item.SelectFn then pcall(item.SelectFn) end
				if item.Frame then pcall(function() item.Frame.Visible = true end) end
				closeSearch()
			end)
		end
		local n = math.min(#matches, 6)
		resultsFrame.Size = UDim2.fromOffset(280, 8 + n * 48)
	end
	searchBtn.MouseButton1Click:Connect(function() playClick() openSearch() end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		updateSearch(searchBox.Text)
	end)
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.Escape and searchOpened then
			closeSearch()
		end
		if searchOpened and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			task.defer(function()
				local pos = input.Position
				local function inside(fr)
					if not fr or not fr.Visible then return false end
					local p, s = fr.AbsolutePosition, fr.AbsoluteSize
					return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
				end
				if not inside(searchFrame) and not inside(resultsFrame) and not inside(searchBtn) then
					closeSearch()
				end
			end)
		end
	end)
	function self:RegisterSearch(data)
		table.insert(self.SearchItems, {
			Title = data.Title or "",
			Type = data.Type or "",
			TabTitle = data.TabTitle or (self.CurrentTab and self.CurrentTab.Title) or "",
			Frame = data.Frame,
			SelectFn = data.SelectFn,
		})
	end

	-- Sidebar (wider, text labels)
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 160, 1, -35)
	sidebar.Position = UDim2.fromOffset(0, 35)
	sidebar.BackgroundColor3 = COLORS.Sidebar
	sidebar.BackgroundTransparency = 0.15
	sidebar.BorderSizePixel = 0
	sidebar.Parent = main
	self.Sidebar = sidebar

	local sideList = Instance.new("ScrollingFrame")
	sideList.Name = "TabList"
	sideList.Size = UDim2.new(1, 0, 1, -8)
	sideList.Position = UDim2.fromOffset(0, 4)
	sideList.BackgroundTransparency = 1
	sideList.BorderSizePixel = 0
	sideList.ScrollBarThickness = 2
	sideList.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120)
	sideList.CanvasSize = UDim2.new(0, 0, 0, 0)
	sideList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sideList.Parent = sidebar
	self.TabList = sideList

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0, 4)
	sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Parent = sideList
	pad(sideList, 6, 8, 10, 8)


	-- Content (center panel)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -160, 1, -35)
	content.Position = UDim2.fromOffset(160, 35)
	content.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	content.BackgroundTransparency = 0.3
	content.BorderSizePixel = 0
	content.ClipsDescendants = true
	content.Parent = main
	self.Content = content
	corner(content, 4)
	stroke(content, Color3.fromRGB(160, 160, 160), 0.5)

	-- Open button
	local openGui = Instance.new("ScreenGui")
	openGui.Name = "SupremeHubOpenBtn"
	openGui.ResetOnSpawn = false
	openGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	openGui.DisplayOrder = 200001
	openGui.IgnoreGuiInset = true
	openGui.Parent = guiParent

	local openBtn = Instance.new("TextButton")
	openBtn.Name = "OpenBtn"
	openBtn.Size = UDim2.fromOffset(40, 40)
	openBtn.Position = UDim2.new(0, 16, 0.5, -23)
	openBtn.BackgroundColor3 = COLORS.Bg
	openBtn.BackgroundTransparency = 0.15
	openBtn.BorderSizePixel = 0
	openBtn.Text = ""
	openBtn.AutoButtonColor = false
	openBtn.Parent = openGui
	corner(openBtn, 12)
	stroke(openBtn, Color3.fromRGB(80, 80, 80), 0.6)
	local openIcon = makeIcon(openBtn, opts.Icon or "dumbbell", 16, COLORS.White)
	openIcon.Position = UDim2.fromOffset(10, 10)
	openIcon.Visible = true
	self.OpenBtn = openBtn
	self.OpenGui = openGui

	local function setVisible(v)
		self.Visible = v
		main.Visible = v
		if not v then closeAllDropdowns() end
	end



	btnDestroy.MouseButton1Click:Connect(function()
		playClick()
		closeAllDropdowns()
		pcall(function() self:Destroy() end)
	end)

	btnMin.MouseButton1Click:Connect(function()
		playClick()
		setVisible(false)
	end)

	btnFull.MouseButton1Click:Connect(function()
		playClick()
		-- style only
	end)


	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == self.ToggleKey then
			setVisible(not self.Visible)
		end
	end)

	-- Dragging
	local dragging, dragStart, startPos
	dragBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	dragBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	local oDragging, oStart, oPos, oMoved
	openBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			oDragging = true
			oMoved = false
			oStart = input.Position
			oPos = openBtn.Position
		end
	end)
	openBtn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if oDragging and not oMoved then
				playClick()
				setVisible(not self.Visible)
			end
			oDragging = false
			oMoved = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if oDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - oStart
			if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
				oMoved = true
				openBtn.Position = UDim2.new(oPos.X.Scale, oPos.X.Offset + delta.X, oPos.Y.Scale, oPos.Y.Offset + delta.Y)
			end
		end
	end)

	function self:Tab(opts)
		opts = opts or {}
		local tab = {}
		tab.Title = opts.Title or "Tab"
		tab.Icon = opts.Icon
		tab.Sections = {}
		local order = #self.Tabs + 1

		-- Sidebar tab button (text + icon, like image)
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "Tab_" .. tab.Title
		tabBtn.Size = UDim2.new(1, -10, 0, 32)
		tabBtn.BackgroundColor3 = COLORS.Control
		tabBtn.BackgroundTransparency = 0.05
		tabBtn.BorderSizePixel = 0
		tabBtn.Text = ""
		tabBtn.AutoButtonColor = false
		tabBtn.LayoutOrder = order
		tabBtn.Parent = self.TabList
		corner(tabBtn, 8)
		local tabStroke = stroke(tabBtn, Color3.fromRGB(0, 0, 0), 0)
		tabStroke.Transparency = 1

		local tabIcon = makeIcon(tabBtn, tab.Icon or "circle", 14, COLORS.White)
		tabIcon.Position = UDim2.fromOffset(10, 8)

		local tabLbl = Instance.new("TextLabel")
		tabLbl.BackgroundTransparency = 1
		tabLbl.Position = UDim2.fromOffset(32, 0)
		tabLbl.Size = UDim2.new(1, -40, 1, 0)
		tabLbl.Font = Enum.Font.Gotham
		tabLbl.Text = tab.Title
		tabLbl.TextColor3 = COLORS.White
		tabLbl.TextSize = 12
		tabLbl.TextXAlignment = Enum.TextXAlignment.Left
		tabLbl.Parent = tabBtn
		textStroke(tabLbl, 1)

		local page = Instance.new("ScrollingFrame")
		page.Name = "Page_" .. tab.Title
		page.Size = UDim2.fromScale(1, 1)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 3
		page.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120)
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.Visible = false
		page.Parent = self.Content
		pad(page, 10, 10, 12, 10)

		local pageLayout = Instance.new("UIListLayout")
		pageLayout.Padding = UDim.new(0, 8)
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Parent = page

		-- Page header
		local pageHead = Instance.new("Frame")
		pageHead.Size = UDim2.new(1, 0, 0, 36)
		pageHead.BackgroundTransparency = 1
		pageHead.LayoutOrder = 0
		pageHead.Parent = page
		local phIcon = makeIcon(pageHead, tab.Icon or "circle", 12, COLORS.White)
		phIcon.Position = UDim2.fromOffset(0, 4)
		local phTitle = Instance.new("TextLabel")
		phTitle.BackgroundTransparency = 1
		phTitle.Position = UDim2.fromOffset(26, 0)
		phTitle.Size = UDim2.new(1, -26, 0, 20)
		phTitle.Font = Enum.Font.GothamBold
		phTitle.Text = tab.Title
		phTitle.TextColor3 = COLORS.White
		phTitle.TextSize = 12
		phTitle.TextXAlignment = Enum.TextXAlignment.Left
		phTitle.Parent = pageHead
		textStroke(phTitle, 1.1)
		local phDesc = Instance.new("TextLabel")
		phDesc.BackgroundTransparency = 1
		phDesc.Position = UDim2.fromOffset(20, 16)
		phDesc.Size = UDim2.new(1, -20, 0, 12)
		phDesc.Font = Enum.Font.Gotham
		phDesc.Text = ""
		phDesc.Visible = false
		phDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
		phDesc.TextSize = 9
		phDesc.TextXAlignment = Enum.TextXAlignment.Left
		phDesc.Parent = pageHead
		textStroke(phDesc, 1)

		tab.Page = page
		tab.Button = tabBtn

		local function selectTab()
			playClick()
			closeAllDropdowns()
			for _, t in ipairs(self.Tabs) do
				t.Page.Visible = false
				t.Button.BackgroundTransparency = 1
				t.Button.BackgroundColor3 = COLORS.Control
				local ic = t.Button:FindFirstChild("Icon")
				if ic then ic.ImageColor3 = COLORS.TextDim end
				local tl = t.Button:FindFirstChildOfClass("TextLabel")
				if tl then tl.TextColor3 = COLORS.TextDim end
				local st = t.Button:FindFirstChildOfClass("UIStroke")
				if st then st.Transparency = 1 end
			end
			page.Visible = true
			tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			tabBtn.BackgroundTransparency = 0
			if tabIcon then tabIcon.ImageColor3 = COLORS.White end
			tabLbl.TextColor3 = COLORS.White
			tabStroke.Color = Color3.fromRGB(80, 80, 80)
			tabStroke.Transparency = 0
			tabStroke.Thickness = 1
			self.CurrentTab = tab
		end

		tab._Select = selectTab
		tabBtn.MouseButton1Click:Connect(selectTab)
		tabBtn.MouseEnter:Connect(function()
			if self.CurrentTab ~= tab then
				tabBtn.BackgroundTransparency = 0.7
				tabBtn.BackgroundColor3 = COLORS.ControlHover
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if self.CurrentTab ~= tab then
				tabBtn.BackgroundTransparency = 0.65
				 tabBtn.BackgroundColor3 = COLORS.Control
			end
		end)

		table.insert(self.Tabs, tab)
		if #self.Tabs == 1 then task.defer(selectTab) end

		function tab:Section(sopts)
			sopts = sopts or {}
			local sec = {}
			local frame = Instance.new("Frame")
			frame.Name = "Section"
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.BackgroundColor3 = COLORS.Section
			frame.BackgroundTransparency = 0.08
			frame.BorderSizePixel = 0
			frame.LayoutOrder = #tab.Sections + 1
			frame.Parent = page
			corner(frame, 10)
			stroke(frame, Color3.fromRGB(200, 200, 200), 0.6)
			pad(frame, 7, 8, 8, 8)

			local header = Instance.new("Frame")
			header.Size = UDim2.new(1, 0, 0, 18)
			header.BackgroundTransparency = 1
			header.Parent = frame

			-- red accent bar
			local accent = Instance.new("Frame")
			accent.Size = UDim2.fromOffset(3, 16)
			accent.Position = UDim2.fromOffset(0, 3)
			accent.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			accent.BorderSizePixel = 0
			accent.Parent = header
			corner(accent, 2)

			if sopts.Icon then
				local si = makeIcon(header, sopts.Icon, 11, COLORS.White)
				si.Position = UDim2.fromOffset(10, 4)
			end

			local stitle = Instance.new("TextLabel")
			stitle.BackgroundTransparency = 1
			stitle.Position = UDim2.fromOffset(sopts.Icon and 28 or 10, 0)
			stitle.Size = UDim2.new(1, -30, 1, 0)
			stitle.Font = Enum.Font.GothamBold
			stitle.Text = sopts.Title or "Section"
			stitle.TextColor3 = COLORS.White
			stitle.TextSize = 12
			stitle.TextXAlignment = Enum.TextXAlignment.Left
			stitle.Parent = header
			textStroke(stitle, 1.1)

			-- Locked section: click header plays lock sound
			if false and sopts.Locked then
				frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				frame.BackgroundTransparency = 0.35
				local lockBtn = Instance.new("TextButton")
				lockBtn.Size = UDim2.new(1, 0, 0, 22)
				lockBtn.BackgroundTransparency = 1
				lockBtn.Text = ""
				lockBtn.ZIndex = 5
				lockBtn.Parent = header
				lockBtn.MouseButton1Click:Connect(function()
					pcall(function()
						local s = Instance.new("Sound")
						s.SoundId = "rbxassetid://3611171767"
						s.Volume = 0.5
						s.Parent = SoundService
						s:Play()
						task.delay(2, function() s:Destroy() end)
					end)
				end)
			end

			local body = Instance.new("Frame")
			body.Name = "Body"
			body.Size = UDim2.new(1, 0, 0, 0)
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.Position = UDim2.fromOffset(0, 20)
			body.BackgroundTransparency = 1
			body.Parent = frame

			local bodyLayout = Instance.new("UIListLayout")
			bodyLayout.Padding = UDim.new(0, 4)
			bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
			bodyLayout.Parent = body

			table.insert(tab.Sections, sec)

			local function addControl(name, height)
				local row = Instance.new("Frame")
				row.Name = name
				row.Size = UDim2.new(1, 0, 0, height or 36)
				row.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
				row.BackgroundTransparency = 0.4
				row.BorderSizePixel = 0
				row.Parent = body
				corner(row, 8)
				return row
			end

			function sec:Toggle(topts)
				topts = topts or {}
				local row = addControl("Toggle", 36)
				local leftPad = 12
				if topts.Icon then
					local tic = makeIcon(row, topts.Icon, 14, COLORS.White)
					tic.Position = UDim2.fromOffset(10, 10)
					leftPad = 30
				end
				local lbl = Instance.new("TextLabel")
				lbl.BackgroundTransparency = 1
				lbl.Position = UDim2.fromOffset(leftPad, 4)
				lbl.Size = UDim2.new(1, -70 - leftPad, 0, 18)
				lbl.Font = Enum.Font.GothamBold
				lbl.Text = topts.Title or "Toggle"
				lbl.TextColor3 = COLORS.White
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row
				textStroke(lbl, 1.2)
				if false and topts.Desc then
					local d = Instance.new("TextLabel")
					d.BackgroundTransparency = 1
					d.Position = UDim2.fromOffset(12, 20)
					d.Size = UDim2.new(1, -70, 0, 14)
					d.Font = Enum.Font.Gotham
					d.Text = topts.Desc
					d.TextColor3 = Color3.fromRGB(180, 180, 180)
					d.TextSize = 9
					d.TextXAlignment = Enum.TextXAlignment.Left
					d.Parent = row
					textStroke(d, 1)
				end
				local state = topts.Default == true
				local box = Instance.new("TextButton")
				box.Size = UDim2.fromOffset(36, 20)
				box.Position = UDim2.new(1, -44, 0.5, -9)
				box.BackgroundColor3 = state and COLORS.ToggleOn or COLORS.ToggleOff
				box.BorderSizePixel = 0
				box.Text = ""
				box.AutoButtonColor = false
				box.Parent = row
				corner(box, 11)
				stroke(box, state and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(50, 50, 50), 1)
				local knob = Instance.new("Frame")
				knob.Size = UDim2.fromOffset(14, 14)
				knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.fromOffset(2, 2)
				knob.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				knob.BorderSizePixel = 0
				knob.Parent = box
				corner(knob, 9)
				box.MouseButton1Click:Connect(function()
					playClick()
					state = not state
					box.BackgroundColor3 = state and COLORS.ToggleOn or COLORS.ToggleOff
					local st = box:FindFirstChildOfClass("UIStroke")
					if st then st.Color = state and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(50, 50, 50) end
					TweenService:Create(knob, TweenInfo.new(0.15), {
						Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.fromOffset(2, 2)
					}):Play()
					if topts.Callback then pcall(topts.Callback, state) end
				end)
				return { Set = function(_, v)
					state = v == true
					box.BackgroundColor3 = state and COLORS.ToggleOn or COLORS.ToggleOff
					knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.fromOffset(2, 2)
				end }
			end

			function sec:Slider(sopts)
				sopts = sopts or {}
				local val = sopts.Value or {}
				local minV = val.Min or 0
				local maxV = val.Max or 100
				local cur = val.Default or minV
				local step = sopts.Step or 1
				local row = addControl("Slider", 48)
				local lbl = Instance.new("TextLabel")
				lbl.BackgroundTransparency = 1
				lbl.Position = UDim2.fromOffset(12, 4)
				lbl.Size = UDim2.new(0.65, 0, 0, 16)
				lbl.Font = Enum.Font.Gotham
				lbl.Text = sopts.Title or "Slider"
				lbl.TextColor3 = COLORS.Text
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row
				local valLbl = Instance.new("TextLabel")
				valLbl.BackgroundTransparency = 1
				valLbl.Position = UDim2.new(0.65, 0, 0, 4)
				valLbl.Size = UDim2.new(0.35, -12, 0, 16)
				valLbl.Font = Enum.Font.GothamBold
				valLbl.Text = tostring(cur)
				valLbl.TextColor3 = COLORS.White
				valLbl.TextSize = 12
				valLbl.TextXAlignment = Enum.TextXAlignment.Right
				valLbl.Parent = row
				local track = Instance.new("Frame")
				track.Size = UDim2.new(1, -24, 0, 6)
				track.Position = UDim2.fromOffset(12, 32)
				track.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
				track.BorderSizePixel = 0
				track.Parent = row
				corner(track, 3)
				local fill = Instance.new("Frame")
				fill.Size = UDim2.new((cur - minV) / math.max(maxV - minV, 1), 0, 1, 0)
				fill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
				fill.BorderSizePixel = 0
				fill.Parent = track
				corner(fill, 3)
				gradient(fill, Color3.fromRGB(180, 180, 180), Color3.fromRGB(255, 255, 255), 0)
				local sliding = false
				local function update(rel)
					rel = math.clamp(rel, 0, 1)
					local raw = minV + rel * (maxV - minV)
					cur = math.floor(raw / step + 0.5) * step
					cur = math.clamp(cur, minV, maxV)
					fill.Size = UDim2.new((cur - minV) / math.max(maxV - minV, 1), 0, 1, 0)
					valLbl.Text = tostring(cur)
					if sopts.Callback then pcall(sopts.Callback, cur) end
				end
				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = true
						playClick()
						update((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1))
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = false
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						update((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1))
					end
				end)
			end

			function sec:Dropdown(dopts)
				dopts = dopts or {}
				local options = dopts.Option or {}
				local multi = dopts.Multi or dopts.MultiSelect
				local selected = {}
				local current = dopts.Default
				if multi then
					if type(current) == "table" then
						for _, v in ipairs(current) do selected[v] = true end
						for k, v in pairs(current) do
							if type(k) == "string" and v == true then selected[k] = true end
						end
					end
				elseif type(current) == "table" then
					current = current[1]
				end

				-- Closed row: full width ~40px
				local row = Instance.new("Frame")
				row.Name = "Dropdown"
				row.Size = UDim2.new(1, 0, 0, 40)
				row.BackgroundTransparency = 1
				row.BorderSizePixel = 0
				row.Parent = body

				local lbl = Instance.new("TextLabel")
				lbl.BackgroundTransparency = 1
				lbl.Position = UDim2.fromOffset(4, 2)
				lbl.Size = UDim2.new(1, -8, 0, 14)
				lbl.Font = Enum.Font.GothamBold
				lbl.Text = dopts.Title or "Dropdown"
				lbl.TextColor3 = COLORS.White
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row
				textStroke(lbl, 1.2)
				if false and dopts.Desc then
					local d = Instance.new("TextLabel")
					d.BackgroundTransparency = 1
					d.Position = UDim2.fromOffset(4, 16)
					d.Size = UDim2.new(0.4, 0, 0, 12)
					d.Font = Enum.Font.Gotham
					d.Text = dopts.Desc
					d.TextColor3 = Color3.fromRGB(180, 180, 180)
					d.TextSize = 10
					d.TextXAlignment = Enum.TextXAlignment.Left
					d.Parent = row
					textStroke(d, 1)
				end

				local display = Instance.new("TextButton")
				display.Name = "Value"
				display.Size = UDim2.new(0.55, -4, 0, 28)
				display.Position = UDim2.new(0.45, 0, 0, 10)
				display.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
				display.BackgroundTransparency = 0.1
				display.BorderSizePixel = 0
				display.Font = Enum.Font.Gotham
				display.TextSize = 11
				display.TextColor3 = COLORS.White
				display.TextXAlignment = Enum.TextXAlignment.Left
				display.TextTruncate = Enum.TextTruncate.AtEnd
				display.AutoButtonColor = false
				display.Parent = row
				corner(display, 8)
				stroke(display, Color3.fromRGB(70, 70, 70), 0.6)
				pad(display, 0, 22, 0, 8)

				local arrow = Instance.new("TextLabel")
				arrow.BackgroundTransparency = 1
				arrow.Size = UDim2.fromOffset(16, 16)
				arrow.Position = UDim2.new(1, -18, 0.5, -8)
				arrow.Font = Enum.Font.GothamBold
				arrow.Text = "▾"
				arrow.TextColor3 = COLORS.White
				arrow.TextSize = 12
				arrow.Parent = display

				local function refreshDisplay()
					if multi then
						local list = {}
						for k, v in pairs(selected) do if v then table.insert(list, k) end end
						table.sort(list)
						display.Text = #list > 0 and table.concat(list, ", ") or "Select..."
					else
						display.Text = tostring(current or "Select...")
					end
				end
				refreshDisplay()

				local open = false
				local dropFrame = nil
				local dropId = "dd_" .. tostring(math.random(1, 1e9))

				local function closeThis()
					if dropFrame then pcall(function() dropFrame:Destroy() end) dropFrame = nil end
					open = false
					OpenDropdowns[dropId] = nil
					arrow.Text = "▾"
				end

				display.MouseButton1Click:Connect(function()
					playClick()
					if open then closeThis() return end
					closeAllDropdowns()
					open = true
					OpenDropdowns[dropId] = closeThis
					arrow.Text = "▴"

					local host = row
					do
						local cur = row
						for _ = 1, 30 do
							if not cur then break end
							if cur:IsA("ScreenGui") then host = cur break end
							cur = cur.Parent
						end
					end
					pcall(function()
						local old = host:FindFirstChild("SH_Dropdown")
						if old then old:Destroy() end
					end)

					local mainFrame = host:FindFirstChild("Main")
					local gap = 6
					local function getMenuGeom()
						local mx, my, mw, mh = 0, 0, 200, 200
						if mainFrame then
							mx = mainFrame.AbsolutePosition.X
							my = mainFrame.AbsolutePosition.Y
							mw = mainFrame.AbsoluteSize.X
							mh = mainFrame.AbsoluteSize.Y
						end
						local dw = math.clamp(mw * 0.5, 170, 240)
						return mx + mw + gap, my, dw, mh
					end
					local x, y, dw, dh = getMenuGeom()

					dropFrame = Instance.new("Frame")
					dropFrame.Name = "SH_Dropdown"
					dropFrame.Size = UDim2.fromOffset(dw, dh)
					dropFrame.Position = UDim2.fromOffset(x, y)
					dropFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
					dropFrame.BackgroundTransparency = 0.05
					dropFrame.BorderSizePixel = 0
					dropFrame.ZIndex = 10000
					dropFrame.ClipsDescendants = true
					dropFrame.Parent = host
					corner(dropFrame, 12)
					stroke(dropFrame, Color3.fromRGB(200, 200, 200), 0.6)

					local followConn
					followConn = RunService.RenderStepped:Connect(function()
						if not dropFrame or not dropFrame.Parent then
							if followConn then followConn:Disconnect() end
							return
						end
						local nx, ny, nw, nh = getMenuGeom()
						dropFrame.Position = UDim2.fromOffset(nx, ny)
						dropFrame.Size = UDim2.fromOffset(nw, nh)
					end)
					local prevClose = closeThis
					closeThis = function()
						if followConn then pcall(function() followConn:Disconnect() end) followConn = nil end
						prevClose()
					end
					OpenDropdowns[dropId] = closeThis

					local searchRow = Instance.new("Frame")
					searchRow.Size = UDim2.new(1, -12, 0, 32)
					searchRow.Position = UDim2.fromOffset(6, 6)
					searchRow.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
					searchRow.BorderSizePixel = 0
					searchRow.ZIndex = 10001
					searchRow.Parent = dropFrame
					corner(searchRow, 8)
					stroke(searchRow, Color3.fromRGB(180, 180, 180), 0.5)
					local sIcon = Instance.new("TextLabel")
					sIcon.Size = UDim2.fromOffset(24, 32)
					sIcon.BackgroundTransparency = 1
					sIcon.Text = "⌕"
					sIcon.TextColor3 = Color3.fromRGB(200, 200, 200)
					sIcon.TextSize = 14
					sIcon.Font = Enum.Font.Gotham
					sIcon.ZIndex = 10002
					sIcon.Parent = searchRow
					local searchBox = Instance.new("TextBox")
					searchBox.Size = UDim2.new(1, -30, 1, 0)
					searchBox.Position = UDim2.fromOffset(28, 0)
					searchBox.BackgroundTransparency = 1
					searchBox.Font = Enum.Font.Gotham
					searchBox.TextSize = 12
					searchBox.TextColor3 = COLORS.White
					searchBox.PlaceholderText = "Search..."
					searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
					searchBox.Text = ""
					searchBox.ClearTextOnFocus = false
					searchBox.ZIndex = 10002
					searchBox.Parent = searchRow

					local sf = Instance.new("ScrollingFrame")
					sf.Size = UDim2.new(1, -8, 1, -48)
					sf.Position = UDim2.fromOffset(4, 42)
					sf.BackgroundTransparency = 1
					sf.BorderSizePixel = 0
					sf.ScrollBarThickness = 2
					sf.ScrollBarImageTransparency = 0.5
					sf.CanvasSize = UDim2.new(0, 0, 0, 0)
					sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
					sf.ZIndex = 10001
					sf.Parent = dropFrame
					local lay = Instance.new("UIListLayout")
					lay.Padding = UDim.new(0, 2)
					lay.SortOrder = Enum.SortOrder.LayoutOrder
					lay.Parent = sf
					pad(sf, 2, 4, 4, 4)

					local function buildList(filter)
						for _, ch in ipairs(sf:GetChildren()) do
							if ch:IsA("TextButton") then ch:Destroy() end
						end
						local f = string.lower(filter or "")
						for _, opt in ipairs(options) do
							if f == "" or string.find(string.lower(tostring(opt)), f, 1, true) then
								local btn = Instance.new("TextButton")
								btn.Size = UDim2.new(1, 0, 0, 32)
								btn.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
								btn.BackgroundTransparency = 1
								btn.BorderSizePixel = 0
								btn.Font = Enum.Font.Gotham
								btn.TextSize = 13
								btn.TextColor3 = COLORS.White
								btn.Text = "  " .. tostring(opt)
								btn.TextXAlignment = Enum.TextXAlignment.Left
								btn.TextTransparency = 0.35
								btn.ZIndex = 10002
								btn.AutoButtonColor = false
								btn.Parent = sf
								corner(btn, 8)
								local isSel = (multi and selected[opt]) or (not multi and current == opt)
								if isSel then
									btn.BackgroundTransparency = 0.05
									btn.TextTransparency = 0
								end
								btn.MouseEnter:Connect(function()
									if not ((multi and selected[opt]) or (not multi and current == opt)) then
										btn.BackgroundTransparency = 0.45
									end
								end)
								btn.MouseLeave:Connect(function()
									local sel = (multi and selected[opt]) or (not multi and current == opt)
									btn.BackgroundTransparency = sel and 0.05 or 1
									btn.TextTransparency = sel and 0 or 0.35
								end)
								btn.MouseButton1Click:Connect(function()
									playClick()
									if multi then
										selected[opt] = not selected[opt]
										refreshDisplay()
										buildList(searchBox.Text)
										local list = {}
										for k, v in pairs(selected) do if v then table.insert(list, k) end end
										if dopts.Callback then pcall(dopts.Callback, list) end
									else
										current = opt
										refreshDisplay()
										closeThis()
										if dopts.Callback then pcall(dopts.Callback, opt) end
									end
								end)
							end
						end
					end
					buildList("")
					searchBox:GetPropertyChangedSignal("Text"):Connect(function()
						buildList(searchBox.Text)
					end)
				end)
			end

			function sec:Input(iopts)
				iopts = iopts or {}
				local row = addControl("Input", 36)
				local lbl = Instance.new("TextLabel")
				lbl.BackgroundTransparency = 1
				lbl.Position = UDim2.fromOffset(12, 0)
				lbl.Size = UDim2.new(0.4, 0, 1, 0)
				lbl.Font = Enum.Font.Gotham
				lbl.Text = iopts.Title or "Input"
				lbl.TextColor3 = COLORS.Text
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row
				local box = Instance.new("TextBox")
				box.Size = UDim2.new(0.55, -12, 0, 26)
				box.Position = UDim2.new(0.45, 0, 0.5, -13)
				box.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
				box.BorderSizePixel = 0
				box.Font = Enum.Font.Gotham
				box.TextSize = 11
				box.TextColor3 = COLORS.Text
				box.PlaceholderText = iopts.Placeholder or ""
				box.PlaceholderColor3 = COLORS.TextDim
				box.Text = tostring(iopts.Default or iopts.Text or iopts.Value or "")
				box.ClearTextOnFocus = false
				box.Parent = row
				corner(box, 6)
				stroke(box, Color3.fromRGB(200, 200, 200), 0.6)
				pad(box, 0, 6, 0, 6)
				box.FocusLost:Connect(function()
					playClick()
					if iopts.Callback then pcall(iopts.Callback, box.Text) end
				end)
			end

			function sec:Button(bopts)
				bopts = bopts or {}
				local row = addControl("Button", 34)
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -8, 1, -8)
				btn.Position = UDim2.fromOffset(4, 4)
				btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
				btn.BorderSizePixel = 0
				btn.Font = Enum.Font.GothamBold
				btn.TextSize = 12
				btn.TextColor3 = COLORS.Text
				btn.Text = bopts.Title or "Button"
				btn.AutoButtonColor = false
				btn.Parent = row
				corner(btn, 6)
				stroke(btn, Color3.fromRGB(60, 60, 60), 1)
				btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end)
				btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22) end)
				btn.MouseButton1Click:Connect(function()
					playClick()
					if bopts.Callback then pcall(bopts.Callback) end
				end)
			end

			function sec:Profile()
				local row = Instance.new("Frame")
				row.Name = "Profile"
				row.Size = UDim2.new(1, 0, 0, 56)
				row.BackgroundColor3 = COLORS.Control
				row.BackgroundTransparency = 0.35
				row.BorderSizePixel = 0
				row.Parent = body
				corner(row, 10)
				stroke(row, Color3.fromRGB(40, 70, 120), 1)

				local avatar = Instance.new("ImageLabel")
				avatar.Size = UDim2.fromOffset(40, 40)
				avatar.Position = UDim2.fromOffset(8, 8)
				avatar.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
				avatar.BorderSizePixel = 0
				avatar.ScaleType = Enum.ScaleType.Crop
				avatar.Parent = row
				corner(avatar, 12)
				stroke(avatar, COLORS.Blue, 1.5)
				pcall(function()
					local ok, content = pcall(function()
						return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
					end)
					if ok and content then avatar.Image = content end
				end)

				local nameLbl = Instance.new("TextLabel")
				nameLbl.BackgroundTransparency = 1
				nameLbl.Position = UDim2.fromOffset(88, 14)
				nameLbl.Size = UDim2.new(1, -180, 0, 20)
				nameLbl.Font = Enum.Font.GothamBold
				nameLbl.Text = "ANONYMUS"
				nameLbl.TextColor3 = COLORS.White
				nameLbl.TextSize = 14
				nameLbl.TextXAlignment = Enum.TextXAlignment.Left
				nameLbl.Parent = row
				textStroke(nameLbl, 1)

				local userLbl = Instance.new("TextLabel")
				userLbl.BackgroundTransparency = 1
				userLbl.Position = UDim2.fromOffset(88, 34)
				userLbl.Size = UDim2.new(1, -180, 0, 16)
				userLbl.Font = Enum.Font.Gotham
				userLbl.Text = "@ANONYMUS"
				userLbl.TextColor3 = COLORS.TextDim
				userLbl.TextSize = 11
				userLbl.TextXAlignment = Enum.TextXAlignment.Left
				userLbl.Parent = row
				textStroke(userLbl, 1)

				local idLbl = Instance.new("TextLabel")
				idLbl.BackgroundTransparency = 1
				idLbl.Position = UDim2.fromOffset(88, 52)
				idLbl.Size = UDim2.new(1, -180, 0, 16)
				idLbl.Font = Enum.Font.Gotham
				idLbl.Text = "ID: Erro Callback"
				idLbl.TextColor3 = COLORS.White
				idLbl.TextSize = 11
				idLbl.TextXAlignment = Enum.TextXAlignment.Left
				idLbl.Parent = row
				textStroke(idLbl, 1)

				local pingLbl = Instance.new("TextLabel")
				pingLbl.BackgroundTransparency = 1
				pingLbl.Position = UDim2.new(1, -100, 0.5, -12)
				pingLbl.Size = UDim2.fromOffset(88, 24)
				pingLbl.Font = Enum.Font.GothamBold
				pingLbl.Text = "-- ms"
				pingLbl.TextColor3 = COLORS.Green
				pingLbl.TextSize = 13
				pingLbl.TextXAlignment = Enum.TextXAlignment.Right
				pingLbl.Parent = row
				textStroke(pingLbl, 1)

				task.spawn(function()
					while pingLbl.Parent do
						pcall(function()
							local stats = game:GetService("Stats")
							local item = stats.Network.ServerStatsItem["Data Ping"]
							local ping = item and item:GetValue()
							if typeof(ping) == "number" then
								local ms = math.floor(ping)
								pingLbl.Text = ms .. " ms"
								if ms <= 100 then pingLbl.TextColor3 = COLORS.Green
								elseif ms <= 200 then pingLbl.TextColor3 = COLORS.Orange
								else pingLbl.TextColor3 = COLORS.Red end
							end
						end)
						task.wait(1)
					end
				end)
			end

			function sec:StatsFrame(sfopts)
				sfopts = sfopts or {}
				local rows = sfopts.Rows or {}
				local height = 28 + #rows * 26
				local frame = Instance.new("Frame")
				frame.Name = "Stats"
				frame.Size = UDim2.new(1, 0, 0, height)
				frame.BackgroundColor3 = COLORS.Control
				frame.BackgroundTransparency = 0.35
				frame.BorderSizePixel = 0
				frame.Parent = body
				corner(frame, 8)
				stroke(frame, Color3.fromRGB(200, 200, 200), 0.6)
				pad(frame, 6, 10, 6, 10)
				local hdr = Instance.new("TextLabel")
				hdr.BackgroundTransparency = 1
				hdr.Size = UDim2.new(1, 0, 0, 18)
				hdr.Font = Enum.Font.GothamBold
				hdr.Text = sfopts.Title or "Status"
				hdr.TextColor3 = COLORS.Text
				hdr.TextSize = 12
				hdr.TextXAlignment = Enum.TextXAlignment.Left
				hdr.Parent = frame
				local valueLabels = {}
				for i, r in ipairs(rows) do
					local rl = Instance.new("TextLabel")
					rl.BackgroundTransparency = 1
					rl.Position = UDim2.fromOffset(0, 18 + (i - 1) * 26)
					rl.Size = UDim2.new(0.4, 0, 0, 24)
					rl.Font = Enum.Font.Gotham
					rl.Text = r.Label or ""
					rl.TextColor3 = r.LabelColor or COLORS.TextDim
					rl.TextSize = 11
					rl.TextXAlignment = Enum.TextXAlignment.Left
					rl.Parent = frame
					local rv = Instance.new("TextLabel")
					rv.BackgroundTransparency = 1
					rv.Position = UDim2.new(0.4, 0, 0, 18 + (i - 1) * 26)
					rv.Size = UDim2.new(0.6, 0, 0, 24)
					rv.Font = Enum.Font.GothamBold
					rv.Text = tostring(r.Value or "")
					rv.TextColor3 = r.ValueColor or COLORS.Text
					rv.TextSize = 11
					rv.TextXAlignment = Enum.TextXAlignment.Right
					rv.Parent = frame
					valueLabels[i] = rv
				end
				return {
					SetRow = function(_, index, value, color)
						local lbl = valueLabels[index]
						if lbl then
							lbl.Text = tostring(value)
							if color then lbl.TextColor3 = color end
						end
					end
				}
			end

			return sec
		end

		return tab
	end

	function self:SelectTabByTitle(title)
		for _, t in ipairs(self.Tabs) do
			if tostring(t.Title):lower() == tostring(title):lower() then
				if t._Select then t._Select() end
				return true
			end
		end
		return false
	end

	function self:Destroy()
		closeAllDropdowns()
		pcall(function() self.Gui:Destroy() end)
		pcall(function() self.OpenGui:Destroy() end)
	end

	function self:Open()
		self.Visible = true
		self.Main.Visible = true
	end

	return self
end

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
		AutoRepSpeed = State.AutoRepSpeed,
		AutoKillBoss = State.AutoKillBoss,
		AutoFarmSeconds = State.AutoFarmSeconds,
		TimeFarm = State.TimeFarm,
		ContinueBoss = State.ContinueBoss,
		AutoBossChest = State.AutoBossChest,
		AutoJoinBrawl = State.AutoJoinBrawl,
		AutoKillBrawl = State.AutoKillBrawl,
		AutoResetBrawl = State.AutoResetBrawl,
		AutoRebirth = State.AutoRebirth, AutoFastRebirth = State.AutoFastRebirth, RebirthTarget = State.RebirthTarget,
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
		HidePets = State.HidePets,
		HidePopups = State.HidePopups,
		HidePlayers = State.HidePlayers,
		HideSound = State.HideSound,
		Optimizer = State.Optimizer,
		WalkWater = State.WalkWater,
		Whitelist = State.Whitelist,
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
	return true
end

local function canRunOtherFarm()
	if State.AutoFastRebirth then return false end
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
	local acc = 0
	while true do
		if canRunOtherFarm() and State.AutoRep then
			local speed = math.clamp(tonumber(State.AutoRepSpeed) or 10, 1, 600)
			local dt = RunService.Heartbeat:Wait()
			acc = acc + dt
			local interval = 1 / speed
			while acc >= interval do
				acc = acc - interval
				fireRep()
			end
		else
			acc = 0
			task.wait(0.25)
		end
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
	local currentTarget = nil
	local didTeleport = false
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
						if p ~= LocalPlayer and isAlive(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and inBrawl(p.Character.HumanoidRootPart.Position) then
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
						if p.Parent and isAlive(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
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
						local th = alvo:FindFirstChildOfClass("Humanoid")
						if currentTarget ~= alvo then
							currentTarget = alvo
							didTeleport = false
						end
						-- Teleport once to target
						if not didTeleport then
							pcall(function()
								r.CFrame = alvo.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
								r.AssemblyLinearVelocity = Vector3.zero
							end)
							-- Arm touch on torso once
							local hand = c:FindFirstChild("RightHand") or c:FindFirstChild("LeftHand")
							local torso = alvo:FindFirstChild("UpperTorso") or alvo:FindFirstChild("Torso") or alvo.HumanoidRootPart
							if hand and torso then
								safeTouch(torso, hand, 0)
								safeTouch(torso, hand, 1)
							end
							didTeleport = true
						end
						-- Tween toward target while attacking until dead
						pcall(function()
							local goal = alvo.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2.2)
							TweenService:Create(r, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {CFrame = goal}):Play()
						end)
						equipPunch()
						local L = c:FindFirstChild("LeftHand")
						local R = c:FindFirstChild("RightHand")
						local hit = alvo.HumanoidRootPart
						if L then safeTouch(hit, L, 0) safeTouch(hit, L, 1) end
						if R then safeTouch(hit, R, 0) safeTouch(hit, R, 1) end
						firePunch()
						local punch = c:FindFirstChild("Punch")
						if punch then pcall(function() punch:Activate() end) end
						-- Target died -> next player
						if not th or th.Health <= 0 then
							currentTarget = nil
							didTeleport = false
						end
					else
						currentTarget = nil
						didTeleport = false
					end
				else
					PlayerInBrawl = false
					aggro = {}
					currentTarget = nil
					didTeleport = false
					ESPFolder:ClearAllChildren()
				end
			end
			task.wait(0.03)
		else
			PlayerInBrawl = false
			currentTarget = nil
			didTeleport = false
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
-- UI BUILD
-- ==========================================
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

local Window
local winOk, winErr = pcall(function()
	Window = UI.CreateWindow({
		Name = "Supreme Hub",
		Icon = "mouse-pointer-click",
		ToggleKey = Enum.KeyCode.RightControl,
	})
end)
if not winOk or not Window then
	warn("[Supreme Hub] UI error:", winErr)
	notify("Supreme Hub", "UI failed: " .. tostring(winErr))
	return
end

-- Video-style utility buttons. They keep the original script features intact.
pcall(function()
	local ub = Window.UtilityButtons or {}
	if ub.Discord then
		ub.Discord.MouseButton1Click:Connect(function()
			notify("Supreme Hub", "Discord/Webhook options are available in Rewards.")
		end)
	end
	if ub.QuickKeys then
		ub.QuickKeys.MouseButton1Click:Connect(function()
			notify("Supreme Hub", "Open/close UI: RightControl")
		end)
	end
	if ub.Settings then
		ub.Settings.MouseButton1Click:Connect(function()
			Window:SelectTabByTitle("Main")
		end)
	end
	if ub.Config then
		ub.Config.MouseButton1Click:Connect(function()
			notify("Supreme Hub", "Config is saved automatically when options change.")
		end)
	end
end)

-- 1 MAIN
local Main = Window:Tab({ Title = "Main", Icon = "user", Desc = "Player settings" })
local sSize = Main:Section({ Title = "Size", Icon = "maximize" })
sSize:Slider({ Title = "Size", Value = { Min = 1, Max = 100, Default = State.Size }, Step = 1, Callback = function(v) State.Size = v markDirty() end })
sSize:Toggle({ Title = "Set Size", Default = State.SetSize, Callback = function(v) State.SetSize = v markDirty() end })
local sSpeed = Main:Section({ Title = "Speed", Icon = "gauge" })
sSpeed:Slider({ Title = "Speed", Value = { Min = 16, Max = 500, Default = State.Speed }, Step = 1, Callback = function(v) State.Speed = v markDirty() end })
sSpeed:Toggle({ Title = "Set Speed", Default = State.SetSpeed, Callback = function(v) State.SetSpeed = v markDirty() end })
local sFov = Main:Section({ Title = "Fov", Icon = "eye" })
sFov:Slider({ Title = "Fov", Value = { Min = 1, Max = 250, Default = State.FOV }, Step = 1, Callback = function(v) State.FOV = v markDirty() end })
sFov:Toggle({ Title = "Set Fov", Default = State.SetFOV, Callback = function(v)
	State.SetFOV = v
	if Camera then Camera.FieldOfView = v and State.FOV or 70 end
	markDirty()
end })
local sMove = Main:Section({ Title = "Movement", Icon = "footprints" })
sMove:Toggle({ Title = "Walk On Water", Default = State.WalkWater, Callback = function(v)
	State.WalkWater = v
	if _G.MLWater then
		for _, p in ipairs(_G.MLWater) do
			if p and p.Parent then p.CanCollide = v end
		end
	end
	markDirty()
end })
sMove:Toggle({ Title = "Infinite Jump", Default = State.InfJump, Callback = function(v) State.InfJump = v markDirty() end })

-- 2 AUTO FARMING
local AutoFarm = Window:Tab({ Title = "Farm", Icon = "dumbbell", Desc = "Configure your training" })
local sRep = AutoFarm:Section({ Title = "Auto Rep", Icon = "zap" })
sRep:Slider({
	Title = "Reps Per Second",
	Value = { Min = 1, Max = 600, Default = State.AutoRepSpeed or 10 },
	Step = 1,
	Callback = function(v) State.AutoRepSpeed = math.clamp(math.floor(tonumber(v) or 10), 1, 600) markDirty() end
})
sRep:Toggle({ Title = "Auto Rep", Default = State.AutoRep, Desc = "Executes reps at the speed above", Callback = function(v) State.AutoRep = v markDirty() end })
local sEx = AutoFarm:Section({ Title = "Exercises", Icon = "dumbbell" })
sEx:Dropdown({ Title = "Select Exercise", Option = {"Weight", "Pushups", "Situps", "Handstands"}, Default = State.Exercise or "Weight", Desc = "Choose exercise type", Callback = function(v) State.Exercise = v markDirty() end })
sEx:Toggle({ Title = "Start Exercising", Default = State.AutoExercise, Desc = "Start training automatically", Callback = function(v)
	State.AutoExercise = v
	if v then
		machineState.Squat.Running = false
		machineState.Lift.Running = false
		State.AutoSquat = false
		State.AutoLift = false
	end
	markDirty()
end })
if #SquatNames > 0 then
	sEx:Dropdown({ Title = "Select Squat", Option = SquatNames, Default = State.SelectedSquat, Callback = function(v) State.SelectedSquat = v markDirty() end })
end
sEx:Toggle({ Title = "Auto Squat", Default = State.AutoSquat, Callback = function(v)
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
	sEx:Dropdown({ Title = "Select Lift", Option = LiftNames, Default = State.SelectedLift, Callback = function(v) State.SelectedLift = v markDirty() end })
end
sEx:Toggle({ Title = "Auto Lift", Default = State.AutoLift, Callback = function(v)
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
local sRock = AutoFarm:Section({ Title = "Rocks", Icon = "mountain" })
sRock:Dropdown({ Title = "Select Rock", Option = rockOptionsSorted(), Default = State.SelectedRock, Callback = function(v) State.SelectedRock = v markDirty() end })
sRock:Toggle({ Title = "Auto Rock", Default = State.AutoRock, Callback = function(v) State.AutoRock = v markDirty() end })
local sStr = AutoFarm:Section({ Title = "Better Strength", Icon = "zap" })
sStr:Toggle({ Title = "Pushup + Industrial Rock", Default = State.PushupIndustrial, Callback = function(v) State.PushupIndustrial = v markDirty() end })
sStr:Toggle({ Title = "Pushup + Jungle Rock", Default = State.PushupJungle, Callback = function(v) State.PushupJungle = v markDirty() end })
sStr:Toggle({ Title = "Pushup + Muscle King Rock", Default = State.PushupKing, Callback = function(v) State.PushupKing = v markDirty() end })
sStr:Toggle({ Title = "Pushup + Legends Rock", Default = State.PushupLegends, Callback = function(v) State.PushupLegends = v markDirty() end })

-- 3 REBIRTH
local Rebirth = Window:Tab({ Title = "Rebirth", Icon = "refresh-cw" })
local sFast = Rebirth:Section({ Title = "Fast Rebirth", Icon = "refresh-cw" })

local YELLOW = Color3.fromRGB(250, 204, 21)
local ORANGE = Color3.fromRGB(249, 115, 22)

local RebirthStats = sFast:StatsFrame({
	Title = "Status View",
	Rows = {
		{ Label = "Strength", Value = "0", ValueColor = YELLOW },
		{ Label = "Rebirth", Value = "0", ValueColor = ORANGE },
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

task.spawn(function()
	while true do
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
			if RebirthStats and RebirthStats.SetRow then
				RebirthStats:SetRow(1, formatStatNum(strength), YELLOW)
				RebirthStats:SetRow(2, formatStatNum(rebirths), ORANGE)
			end
		end)
		task.wait(0.25)
	end
end)

sFast:Toggle({ Title = "Auto Fast Rebirth", Default = State.AutoFastRebirth, Callback = function(v)
	State.AutoFastRebirth = v
	markDirty()
end })

local sRb = Rebirth:Section({ Title = "Rebirth", Icon = "refresh-cw" })
sRb:Input({ Title = "Rebirth Target", Placeholder = tostring(State.RebirthTarget or 0), Default = tostring(State.RebirthTarget or 0), Callback = function(v)
	local n = tonumber(v)
	if n and n >= 0 then State.RebirthTarget = n markDirty() end
end })
sRb:Toggle({ Title = "Auto Rebirth", Default = State.AutoRebirth, Callback = function(v) State.AutoRebirth = v markDirty() end })
local sMore = Rebirth:Section({ Title = "Mores", Icon = "layers" })
sMore:Toggle({ Title = "Lock Position", Default = State.LockPos, Callback = function(v)
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
sMore:Toggle({ Title = "Auto Size 1", Default = State.AutoSize1, Callback = function(v) State.AutoSize1 = v markDirty() end })
sMore:Toggle({ Title = "Auto Muscle King", Default = State.AutoKing, Callback = function(v) State.AutoKing = v markDirty() end })

-- 4 BRAWL
local Brawl = Window:Tab({ Title = "Brawl", Icon = "sword", Desc = "Auto brawl features" })
local function brawlPlayerOpts()
	local o = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(o, p.Name) end
	end
	if #o == 0 then table.insert(o, "No players") end
	table.sort(o)
	return o
end
local sWl = Brawl:Section({ Title = "WhiteList", Icon = "shield" })
sWl:Dropdown({
	Title = "WhiteList Player",
	Option = brawlPlayerOpts(),
	Multi = true,
	Default = State.Whitelist or {},
	Desc = "Ignore auto kill on selected players",
	Callback = function(v)
		if type(v) == "table" then
			State.Whitelist = {}
			for _, name in ipairs(v) do
				if name ~= "No players" then table.insert(State.Whitelist, name) end
			end
		end
		markDirty()
	end
})
local sBr = Brawl:Section({ Title = "Brawl", Icon = "sword" })
sBr:Toggle({ Title = "Auto Join In Brawl", Default = State.AutoJoinBrawl, Callback = function(v) State.AutoJoinBrawl = v markDirty() end })
sBr:Toggle({ Title = "Auto Kill In Brawl", Default = State.AutoKillBrawl, Callback = function(v)
	State.AutoKillBrawl = v
	if not v then ESPFolder:ClearAllChildren() end
	markDirty()
end })
sBr:Toggle({ Title = "Auto Reset Brawl", Default = State.AutoResetBrawl, Callback = function(v) State.AutoResetBrawl = v markDirty() end })

-- 5 BOSS
local Boss = Window:Tab({ Title = "Boss", Icon = "skull" })
local sBossSt = Boss:Section({ Title = "Status", Icon = "activity" })

local BossStats = sBossSt:StatsFrame({
	Title = "Boss Status",
	Rows = {
		{ Label = "Status", Value = "Waiting For Boss" },
		{ Label = "Boss", Value = "None" },
		{ Label = "Health", Value = "0 / 0" },
		{ Label = "Next Boss", Value = "N/A" },
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

local function bossRarityColor(display)
	local n = string.lower(tostring(display or ""))
	if string.find(n, "admin", 1, true) or string.find(n, "rainbow", 1, true) or string.find(n, "godly", 1, true) then
		-- rainbow approx cycling via clock
		local t = os.clock() % 3
		if t < 1 then return Color3.fromRGB(255, 80, 80)
		elseif t < 2 then return Color3.fromRGB(80, 255, 120)
		else return Color3.fromRGB(80, 140, 255) end
	end
	if string.find(n, "myth", 1, true) then return Color3.fromRGB(220, 40, 50) end
	if string.find(n, "legend", 1, true) then return Color3.fromRGB(250, 204, 21) end
	if string.find(n, "epic", 1, true) then return Color3.fromRGB(160, 80, 255) end
	if string.find(n, "rare", 1, true) then return Color3.fromRGB(60, 130, 255) end
	if string.find(n, "common", 1, true) then return Color3.fromRGB(160, 160, 170) end
	return Color3.fromRGB(200, 200, 210)
end

local function bossHealthColor(hp, mhp)
	mhp = tonumber(mhp) or 1
	hp = tonumber(hp) or 0
	if mhp <= 0 then return Color3.fromRGB(50, 205, 90) end
	local ratio = hp / mhp
	if ratio > 0.5 then return Color3.fromRGB(50, 205, 90) end
	if ratio > 0.25 then return Color3.fromRGB(255, 160, 40) end
	return Color3.fromRGB(220, 40, 50)
end

task.spawn(function()
	while true do
		pcall(function()
			local model = select(1, findBoss())
			local WHITE = Color3.fromRGB(255, 255, 255)
			if not model then
				if BossStats then
					BossStats:SetRow(1, "Waiting For Boss", WHITE)
					BossStats:SetRow(2, "None", WHITE)
					BossStats:SetRow(3, "0 / 0", WHITE)
					local nextTime = Workspace:GetAttribute("BossSpawnNextTime")
					if typeof(nextTime) == "number" then
						BossStats:SetRow(4, formatBossCountdown(nextTime - Workspace:GetServerTimeNow()), WHITE)
					else
						BossStats:SetRow(4, "N/A", WHITE)
					end
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
			local rcol = bossRarityColor(display)
			local hcol = bossHealthColor(hp, mhp)
			if BossStats then
				BossStats:SetRow(1, phase, WHITE)
				BossStats:SetRow(2, tostring(display), rcol)
				BossStats:SetRow(3, string.format("%s / %s", formatBossNum(hp), formatBossNum(mhp)), hcol)
				BossStats:SetRow(4, "Current Boss Active", WHITE)
			end
		end)
		task.wait(0.25)
	end
end)

local sBossF = Boss:Section({ Title = "Boss Farm", Icon = "swords" })
sBossF:Slider({ Title = "Time Farm", Value = { Min = 5, Max = 100, Default = State.TimeFarm or 12 }, Step = 1, Callback = function(v)
	State.TimeFarm = math.clamp(math.floor(tonumber(v) or 12), 5, 100)
	markDirty()
end })
sBossF:Toggle({ Title = "Auto Farm Seconds", Default = State.AutoFarmSeconds, Callback = function(v) State.AutoFarmSeconds = v markDirty() end })
sBossF:Toggle({ Title = "Auto Kill Boss", Default = State.AutoKillBoss, Callback = function(v) State.AutoKillBoss = v markDirty() end })
sBossF:Toggle({ Title = "Auto Boss Chest", Default = State.AutoBossChest, Callback = function(v)
	State.AutoBossChest = v
	if v then hideBossPrompts() end
	markDirty()
end })
sBossF:Toggle({ Title = "Continue Farming After Boss Kill", Default = State.ContinueBoss, Callback = function(v) State.ContinueBoss = v markDirty() end })

-- 6 QUEST
local Quest = Window:Tab({ Title = "Quest", Icon = "scroll" })
local sQ = Quest:Section({ Title = "Enchant Quests", Icon = "scroll" })
sQ:Toggle({ Title = "Auto Quest Farm", Default = State.AutoQuestFarm, Callback = function(v)
	State.AutoQuestFarm = v
	if not v then unequipTools() end
	markDirty()
end })
sQ:Toggle({ Title = "Auto Collect Quests", Default = State.AutoQuestCollect, Callback = function(v) State.AutoQuestCollect = v markDirty() end })
local sClan = Quest:Section({ Title = "Clan", Icon = "users" })
sClan:Toggle({ Title = "Collect Clan Quest", Default = State.AutoClanQuest, Callback = function(v) State.AutoClanQuest = v markDirty() end })

-- 7 REWARDS
local Rewards = Window:Tab({ Title = "Rewards", Icon = "gift" })
local sRew = Rewards:Section({ Title = "Rewards", Icon = "gift" })
sRew:Toggle({ Title = "Spin Fortune Wheel", Default = State.SpinFortune, Callback = function(v) State.SpinFortune = v markDirty() end })
local sCons = Rewards:Section({ Title = "Consumables", Icon = "package" })
sCons:Toggle({ Title = "Eat All Eggs", Default = State.EatEggs, Callback = function(v) State.EatEggs = v markDirty() end })
sCons:Toggle({ Title = "Eat All Boosts", Default = State.EatBoosts, Callback = function(v) State.EatBoosts = v markDirty() end })

-- 8 TELEPORTS
local Teleport = Window:Tab({ Title = "TP", Icon = "map-pin" })
local sIsl = Teleport:Section({ Title = "Islands", Icon = "map" })
for _, name in ipairs({"Tiny Island", "Main Island", "Beach"}) do
	local cf = Teleports[name]
	sIsl:Button({ Title = name, Callback = function()
		local r = root()
		if r and cf then r.CFrame = cf end
	end })
end
local sGym = Teleport:Section({ Title = "Gyms", Icon = "building" })
for _, name in ipairs({
	"Overcharged Gym", "Industrial Gym", "Jungle Gym", "Muscle King Gym",
	"Legends Gym", "Infernal Gym", "Mythical Gym", "Frost Gym"
}) do
	local cf = Teleports[name]
	sGym:Button({ Title = name, Callback = function()
		local r = root()
		if r and cf then r.CFrame = cf end
	end })
end

-- 9 SERVER
local Server = Window:Tab({ Title = "Server", Icon = "server" })
local sSess = Server:Section({ Title = "Session", Icon = "server" })
sSess:Toggle({ Title = "Auto Load Script", Default = State.AutoLoad, Callback = function(v)
	State.AutoLoad = v
	if v then setupQueueOnTeleport() notify("Supreme Hub", "Auto Load On Hop/Rejoin") end
	markDirty()
end })
sSess:Toggle({ Title = "Auto Rejoin (1 Hour)", Default = State.AutoRejoin, Callback = function(v) State.AutoRejoin = v markDirty() end })
sSess:Toggle({ Title = "Auto Reconnect", Default = State.AutoReconnect, Callback = function(v) State.AutoReconnect = v markDirty() end })
sSess:Button({ Title = "Server Hop", Callback = function() serverHop() end })

local sWh = Server:Section({ Title = "Webhook", Icon = "bell" })
sWh:Input({ Title = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...", Default = State.WebhookURL or "", Callback = function(v)
	State.WebhookURL = tostring(v or "")
	markDirty()
end })
sWh:Toggle({ Title = "Ping @everyone", Default = State.WebhookPingEveryone, Callback = function(v) State.WebhookPingEveryone = v markDirty() end })
sWh:Dropdown({ Title = "Boss Rarity", Option = BossRarityOptions, Multi = true, Default = listSelectedWebhookBosses(), Callback = function(v)
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
end })
sWh:Toggle({ Title = "Boss Notification", Default = State.WebhookBossNotify, Callback = function(v) State.WebhookBossNotify = v markDirty() end })
sWh:Toggle({ Title = "Disconnect Notification", Default = State.WebhookDisconnectNotify, Callback = function(v) State.WebhookDisconnectNotify = v markDirty() end })
sWh:Button({ Title = "Test Webhook", Callback = function()
	local ok = sendDiscordWebhook(nil, {{
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
	notify("Supreme Hub", ok and "Webhook Sent" or "Webhook Failed")
end })

-- 10 MISC
local Misc = Window:Tab({ Title = "Misc", Icon = "settings" })
local sTime = Misc:Section({ Title = "Time", Icon = "clock" })
sTime:Dropdown({ Title = "Change Time", Option = {"Day", "Noon", "Afternoon", "Night", "Midnight"}, Default = State.TimeMode or "Day", Callback = function(v)
	State.TimeMode = v
	local map = {Day = 9, Noon = 12, Afternoon = 16, Night = 0, Midnight = 2}
	Lighting.ClockTime = map[v] or 9
	markDirty()
end })
sTime:Button({ Title = "Reset Time", Callback = function()
	Lighting.ClockTime = NormalClockTime
	State.TimeMode = "Day"
	markDirty()
	notify("Supreme Hub", "Time Reset")
end })
local sRend = Misc:Section({ Title = "Render", Icon = "monitor" })
sRend:Toggle({ Title = "Render 3D", Default = State.Render3D, Callback = function(v) setRender3D(v) end })
local sHide = Misc:Section({ Title = "Hides", Icon = "eye-off" })
sHide:Toggle({ Title = "Hide Players", Default = State.HidePlayers, Callback = function(v)
	State.HidePlayers = v
	applyHidePlayers()
	markDirty()
end })
sHide:Toggle({ Title = "Hide Popups", Default = State.HidePopups, Callback = function(v)
	State.HidePopups = v
	applyHidePopups()
	markDirty()
end })
sHide:Toggle({ Title = "Hide Sounds", Default = State.HideSound, Callback = function(v)
	State.HideSound = v
	applyHideSound()
	markDirty()
end })
sHide:Toggle({ Title = "Hide All Pets", Default = State.HidePets, Callback = function(v)
	State.HidePets = v
	applyHidePets()
	markDirty()
end })
local sPerf = Misc:Section({ Title = "Performance", Icon = "cpu" })
sPerf:Toggle({ Title = "Optimizer", Default = State.Optimizer, Callback = function(v)
	State.Optimizer = v
	applyOptimizer()
	markDirty()
end })
sPerf:Button({ Title = "Save Config", Callback = function()
	saveConfig()
	notify("Supreme Hub", "Config Saved")
end })

-- Register searchable items
pcall(function()
	if not Window or not Window.RegisterSearch then return end
	for _, tab in ipairs(Window.Tabs or {}) do
		local page = tab.Page
		if page then
			for _, desc in ipairs(page:GetDescendants()) do
				if desc:IsA("TextLabel") and desc.Parent and (desc.Parent.Name == "Toggle" or desc.Parent.Name == "Dropdown") then
					local t = tab
					Window:RegisterSearch({
						Title = desc.Text,
						Type = desc.Parent.Name,
						TabTitle = tab.Title,
						SelectFn = function()
							pcall(function()
								if t.Button then
									firesignal(t.Button.MouseButton1Click)
								end
							end)
						end,
						Frame = desc.Parent,
					})
				elseif desc:IsA("TextButton") and desc.Parent and desc.Parent.Name == "Button" and desc.Text ~= "" then
					local t = tab
					Window:RegisterSearch({
						Title = desc.Text,
						Type = "Button",
						TabTitle = tab.Title,
						SelectFn = function()
							pcall(function()
								if t.Button then
									firesignal(t.Button.MouseButton1Click)
								end
							end)
						end,
						Frame = desc.Parent,
					})
				end
			end
		end
	end
end)

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

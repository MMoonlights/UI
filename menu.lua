local Menu = {}
Menu.__index = Menu

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse  = Player:GetMouse()

local MIN_W, MIN_H = 500, 350

local Theme = {
    Background  = Color3.fromRGB(14, 14, 18),
    Topbar      = Color3.fromRGB(20, 20, 26),
    Sidebar     = Color3.fromRGB(18, 18, 24),
    Card        = Color3.fromRGB(26, 26, 34),
    CardHover   = Color3.fromRGB(34, 34, 44),
    CardActive  = Color3.fromRGB(40, 40, 52),
    Accent      = Color3.fromRGB(230, 60, 80),
    AccentHover = Color3.fromRGB(255, 90, 110),
    AccentDim   = Color3.fromRGB(80, 25, 35),
    Text        = Color3.fromRGB(240, 240, 248),
    TextDim     = Color3.fromRGB(140, 140, 160),
    TextMuted   = Color3.fromRGB(90, 90, 110),
    Border      = Color3.fromRGB(38, 38, 50),
    Success     = Color3.fromRGB(60, 200, 130),
    Danger      = Color3.fromRGB(230, 70, 90),
    Font        = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
    FontLight   = Enum.Font.Gotham,
}

local function getScreenSize()
    local cam = workspace.CurrentCamera
    if cam and cam.ViewportSize.X > 0 then
        return cam.ViewportSize
    end
    return Vector2.new(Mouse.ViewSizeX, Mouse.ViewSizeY)
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function Padding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.Parent = parent
    return p
end

local function AddShadow(parent)
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"
    s.BackgroundTransparency = 1
    s.Image = "rbxassetid://6014261993"
    s.ImageColor3 = Color3.new(0, 0, 0)
    s.ImageTransparency = 0.55
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(49, 49, 450, 450)
    s.Size = UDim2.new(1, 40, 1, 40)
    s.Position = UDim2.new(0.5, 0, 0.5, 0)
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.ZIndex = -1
    s.Parent = parent
    return s
end

local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.18,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out
    ), props):Play()
end

function Menu:CreateWindow(opts)
    opts = opts or {}

    local guiName = "MUI_" .. (opts.Title or "Menu")
    
    do
        local old = CoreGui:FindFirstChild(guiName)
        if not old and gethui then
            local ok, ui = pcall(gethui)
            if ok and ui then old = ui:FindFirstChild(guiName) end
        end
        if old then old:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true

    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then
            ScreenGui.Parent = ui
        else
            ScreenGui.Parent = Player:WaitForChild("PlayerGui")
        end
    else
        local ok = pcall(function() ScreenGui.Parent = CoreGui end)
        if not ok then ScreenGui.Parent = Player:WaitForChild("PlayerGui") end
    end

    local winSize = opts.Size or Vector2.new(580, 420)
    winSize = Vector2.new(math.max(winSize.X, MIN_W), math.max(winSize.Y, MIN_H))

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    ToggleButton.Size = UDim2.new(0, 50, 0, 50)
    ToggleButton.Position = UDim2.new(0, 43, 0.5, 0)
    ToggleButton.BackgroundColor3 = Theme.Accent
    ToggleButton.Text = ""
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = ScreenGui
    Corner(ToggleButton, 14)
    Stroke(ToggleButton, Theme.AccentHover, 2)
    AddShadow(ToggleButton)

    local ToggleIcon = Instance.new("TextLabel")
    ToggleIcon.BackgroundTransparency = 1
    ToggleIcon.Size = UDim2.new(1, 0, 1, 0)
    ToggleIcon.Font = Theme.FontBold
    ToggleIcon.TextSize = 24
    ToggleIcon.TextColor3 = Theme.Text
    ToggleIcon.Text = "M"
    ToggleIcon.Parent = ToggleButton

    local toggleHovered = false
    local function toggleSize()
        local s = toggleHovered and 54 or 50
        Tween(ToggleButton, {Size = UDim2.new(0, s, 0, s)}, 0.15, Enum.EasingStyle.Back)
    end
    ToggleButton.MouseEnter:Connect(function()
        toggleHovered = true
        Tween(ToggleButton, {BackgroundColor3 = Theme.AccentHover}, 0.15)
        toggleSize()
    end)
    ToggleButton.MouseLeave:Connect(function()
        toggleHovered = false
        Tween(ToggleButton, {BackgroundColor3 = Theme.Accent}, 0.15)
        toggleSize()
    end)
    ToggleButton.MouseButton1Down:Connect(function()
        Tween(ToggleButton, {Size = UDim2.new(0, 45, 0, 45)}, 0.08)
    end)
    ToggleButton.MouseButton1Up:Connect(toggleSize)

    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = UDim2.fromOffset(winSize.X, winSize.Y)
    Window.Position = UDim2.fromOffset(
        math.max(8, (getScreenSize().X - winSize.X) / 2),
        math.max(8, (getScreenSize().Y - winSize.Y) / 2)
    )
    Window.BackgroundColor3 = Theme.Background
    Window.BorderSizePixel = 0
    Window.Visible = false
    Window.Parent = ScreenGui
    Corner(Window, 12)
    local windowStroke = Stroke(Window, Theme.Border, 1)
    AddShadow(Window)

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 44)
    TitleBar.BackgroundColor3 = Theme.Topbar
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Window
    Corner(TitleBar, 12)

    local TitleMask = Instance.new("Frame")
    TitleMask.Size = UDim2.new(1, 0, 0, 14)
    TitleMask.Position = UDim2.new(0, 0, 1, -14)
    TitleMask.BackgroundColor3 = Theme.Topbar
    TitleMask.BorderSizePixel = 0
    TitleMask.Parent = TitleBar

    local TitleAccent = Instance.new("Frame")
    TitleAccent.Size = UDim2.new(0, 4, 0, 22)
    TitleAccent.Position = UDim2.new(0, 14, 0.5, -11)
    TitleAccent.BackgroundColor3 = Theme.Accent
    TitleAccent.BorderSizePixel = 0
    TitleAccent.Parent = TitleBar
    Corner(TitleAccent, 2)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 28, 0, 0)
    TitleLabel.Size = UDim2.new(1, -90, 1, 0)
    TitleLabel.Font = Theme.FontBold
    TitleLabel.TextSize = 15
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TitleLabel.Text = opts.Title or "Menu"
    TitleLabel.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -38, 0.5, -15)
    CloseBtn.BackgroundColor3 = Theme.Card
    CloseBtn.Text = ""
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = TitleBar
    Corner(CloseBtn, 8)
    Stroke(CloseBtn, Theme.Border, 1)

    local CloseIcon = Instance.new("TextLabel")
    CloseIcon.BackgroundTransparency = 1
    CloseIcon.Size = UDim2.new(1, 0, 1, 0)
    CloseIcon.Font = Theme.FontBold
    CloseIcon.TextSize = 14
    CloseIcon.TextColor3 = Theme.TextDim
    CloseIcon.Text = "X"
    CloseIcon.Parent = CloseBtn

    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Theme.Accent}, 0.15)
        Tween(CloseIcon, {TextColor3 = Theme.Text}, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, {BackgroundColor3 = Theme.Card}, 0.15)
        Tween(CloseIcon, {TextColor3 = Theme.TextDim}, 0.15)
    end)

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 150, 1, -44)
    Sidebar.Position = UDim2.new(0, 0, 0, 44)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Window
    Corner(Sidebar, 12)

    local sbTopMask = Instance.new("Frame")
    sbTopMask.Size = UDim2.new(1, 0, 0, 12)
    sbTopMask.BackgroundColor3 = Theme.Sidebar
    sbTopMask.BorderSizePixel = 0
    sbTopMask.Parent = Sidebar

    local sbBRMask = Instance.new("Frame")
    sbBRMask.Size = UDim2.new(0, 12, 0, 12)
    sbBRMask.Position = UDim2.new(1, -12, 1, -12)
    sbBRMask.BackgroundColor3 = Theme.Sidebar
    sbBRMask.BorderSizePixel = 0
    sbBRMask.Parent = Sidebar

    local SidebarDivider = Instance.new("Frame")
    SidebarDivider.Size = UDim2.new(0, 1, 1, -16)
    SidebarDivider.Position = UDim2.new(1, -1, 0, 8)
    SidebarDivider.BackgroundColor3 = Theme.Border
    SidebarDivider.BorderSizePixel = 0
    SidebarDivider.Parent = Sidebar

    local TabsList = Instance.new("ScrollingFrame")
    TabsList.Size = UDim2.new(1, -12, 1, -12)
    TabsList.Position = UDim2.new(0, 6, 0, 6)
    TabsList.BackgroundTransparency = 1
    TabsList.BorderSizePixel = 0
    TabsList.ScrollBarThickness = 2
    TabsList.ScrollBarImageColor3 = Theme.Accent
    TabsList.ScrollBarImageTransparency = 0.5
    TabsList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabsList.Parent = Sidebar

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.Padding = UDim.new(0, 4)
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.Parent = TabsList

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -150, 1, -44)
    Content.Position = UDim2.new(0, 150, 0, 44)
    Content.BackgroundColor3 = Theme.Background
    Content.BorderSizePixel = 0
    Content.ClipsDescendants = true
    Content.Parent = Window

    local DropdownLayer = Instance.new("Frame")
    DropdownLayer.Name = "DropdownLayer"
    DropdownLayer.Size = UDim2.new(1, 0, 1, 0)
    DropdownLayer.BackgroundTransparency = 1
    DropdownLayer.Visible = false
    DropdownLayer.ZIndex = 10
    DropdownLayer.Parent = ScreenGui

    local Shield = Instance.new("TextButton")
    Shield.Name = "Shield"
    Shield.Size = UDim2.new(1, 0, 1, 0)
    Shield.BackgroundColor3 = Color3.new(0, 0, 0)
    Shield.BackgroundTransparency = 1
    Shield.BorderSizePixel = 0
    Shield.Text = ""
    Shield.AutoButtonColor = false
    Shield.ZIndex = 1
    Shield.Parent = DropdownLayer

    local activeDropdown = nil
    local function closeActiveDropdown()
        local dd = activeDropdown
        activeDropdown = nil
        if dd then dd.hide() end
    end
    Shield.MouseButton1Click:Connect(closeActiveDropdown)

    local function makeOverlay(hit, arrow)
        local holder = Instance.new("ScrollingFrame")
        holder.Name = "DropdownList"
        holder.BackgroundColor3 = Theme.Card
        holder.BorderSizePixel = 0
        holder.Visible = false
        holder.ZIndex = 2
        holder.ScrollBarThickness = 3
        holder.ScrollBarImageColor3 = Theme.Accent
        holder.ScrollBarImageTransparency = 0.3
        holder.ScrollingDirection = Enum.ScrollingDirection.Y
        holder.CanvasSize = UDim2.new(0, 0, 0, 0)
        holder.ClipsDescendants = true
        holder.Parent = DropdownLayer
        Corner(holder, 8)
        Stroke(holder, Theme.Border, 1)
        Padding(holder, 4, 6, 4, 4)

        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 2)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = holder

        local W = 0
        local isOpen = false
        local overlay = nil

        local function show(targetH, canvasH)
            if isOpen then return end
            isOpen = true
            local scr = getScreenSize()
            local hp, hs = hit.AbsolutePosition, hit.AbsoluteSize
            local wp, ws = Window.AbsolutePosition, Window.AbsoluteSize
            W = math.max(hs.X, 60)
            if W > scr.X - 16 then W = scr.X - 16 end

            local h = targetH
            local y

            if hp.Y + hs.Y + 6 + h <= wp.Y + ws.Y - 6 then
                y = hp.Y + hs.Y + 6
            elseif hp.Y - 6 - h >= wp.Y + 4 then
                y = hp.Y - 6 - h
            else
                local avail = scr.Y - 8 - (hp.Y + hs.Y + 6)
                if avail >= 100 then
                    h = math.min(h, avail)
                    y = hp.Y + hs.Y + 6
                else
                    h = math.min(h, math.max(hp.Y - 8, 80))
                    y = math.max(8, hp.Y - h)
                end
            end

            local x = hp.X
            local maxX = wp.X + ws.X - W - 6
            if x > maxX then x = maxX end
            if x < wp.X + 6 then x = wp.X + 6 end
            if x > scr.X - W - 8 then x = scr.X - W - 8 end
            if x < 8 then x = 8 end

            holder.CanvasSize = UDim2.new(0, 0, 0, canvasH)
            holder.Position = UDim2.fromOffset(x, y)
            holder.Size = UDim2.fromOffset(W, 0)
            DropdownLayer.Visible = true
            holder.Visible = true
            Tween(Shield, {BackgroundTransparency = 0.6}, 0.15)
            Tween(arrow, {Rotation = 180}, 0.2)
            Tween(holder, {Size = UDim2.fromOffset(W, h)}, 0.22, Enum.EasingStyle.Back)
        end

        local function hide()
            if not isOpen then return end
            isOpen = false
            Tween(arrow, {Rotation = 0}, 0.2)
            Tween(Shield, {BackgroundTransparency = 1}, 0.15)
            Tween(holder, {Size = UDim2.fromOffset(W, 0)}, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.2, function()
                if not isOpen then
                    holder.Visible = false
                    if not (activeDropdown and activeDropdown.isOpen()) then
                        DropdownLayer.Visible = false
                    end
                end
            end)
        end

        overlay = {
            holder = holder,
            show   = show,
            hide   = hide,
            isOpen = function() return isOpen end,
            close  = function()
                hide()
                if activeDropdown == overlay then activeDropdown = nil end
            end,
        }
        return overlay
    end

    local Grip = Instance.new("Frame")
    Grip.Size = UDim2.new(0, 18, 0, 18)
    Grip.Position = UDim2.new(1, -18, 1, -18)
    Grip.BackgroundTransparency = 1
    Grip.ZIndex = 6
    Grip.Parent = Window

    local gripDots = {}
    for i = 0, 2 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 3, 0, 3)
        dot.Position = UDim2.new(1, -6 - i * 5, 1, -6 - i * 5)
        dot.BackgroundColor3 = Theme.TextMuted
        dot.BorderSizePixel = 0
        dot.Parent = Grip
        Corner(dot, 1)
        gripDots[#gripDots + 1] = dot
    end
    Grip.MouseEnter:Connect(function()
        for _, d in ipairs(gripDots) do Tween(d, {BackgroundColor3 = Theme.TextDim}, 0.15) end
    end)
    Grip.MouseLeave:Connect(function()
        for _, d in ipairs(gripDots) do Tween(d, {BackgroundColor3 = Theme.TextMuted}, 0.15) end
    end)

    do
        local resizing, startInput, startSize
        Grip.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                startInput = input.Position
                startSize = Window.AbsoluteSize
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then resizing = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - startInput
                local scr = getScreenSize()
                local wp = Window.AbsolutePosition
                local maxW = math.max(MIN_W, scr.X - wp.X - 12)
                local maxH = math.max(MIN_H, scr.Y - wp.Y - 12)
                local w = math.clamp(startSize.X + delta.X, MIN_W, maxW)
                local h = math.clamp(startSize.Y + delta.Y, MIN_H, maxH)
                Window.Size = UDim2.fromOffset(w, h)
                winSize = Vector2.new(w, h)
            end
        end)
    end

    do
        local dragging, dragStart, startPos
        TitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Window.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local scr = getScreenSize()
                local w, h = Window.AbsoluteSize.X, Window.AbsoluteSize.Y
                local x = startPos.X.Offset + delta.X
                local y = startPos.Y.Offset + delta.Y
                if x > scr.X - 120 then x = scr.X - 120 end
                if x < -w + 120 then x = -w + 120 end
                if y > scr.Y - 44 then y = scr.Y - 44 end
                if y < 0 then y = 0 end
                Window.Position = UDim2.fromOffset(x, y)
            end
        end)
    end

    local open = false

    local function RefreshIcon(state)
        if ToggleIcon:IsA("TextLabel") then
            ToggleIcon.Text = state and "x" or "M"
        elseif ToggleIcon:IsA("ImageLabel") then
            Tween(ToggleIcon, {
                ImageTransparency = state and 0.5 or 0,
                ImageColor3 = state and Theme.Accent or Theme.Text
            }, 0.18)
        end
    end

    local function SetOpen(state)
        if state == open then return end
        open = state
        RefreshIcon(state)

        if state then
            Window.Visible = true
            Window.BackgroundTransparency = 1
            windowStroke.Transparency = 1
            local px, py = Window.Position.X.Offset, Window.Position.Y.Offset
            Window.Size = UDim2.fromOffset(winSize.X - 44, winSize.Y - 34)
            Window.Position = UDim2.fromOffset(px + 22, py + 17)
            Tween(Window, {
                Size = UDim2.fromOffset(winSize.X, winSize.Y),
                Position = UDim2.fromOffset(px, py),
                BackgroundTransparency = 0
            }, 0.28, Enum.EasingStyle.Back)
            Tween(windowStroke, {Transparency = 0}, 0.28)
        else
            closeActiveDropdown()
            local px, py = Window.Position.X.Offset, Window.Position.Y.Offset
            Tween(Window, {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(winSize.X - 44, winSize.Y - 34),
                Position = UDim2.fromOffset(px + 22, py + 17)
            }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            Tween(windowStroke, {Transparency = 1}, 0.22)
            task.delay(0.24, function()
                if not open then
                    Window.Visible = false
                    Window.Size = UDim2.fromOffset(winSize.X, winSize.Y)
                    Window.Position = UDim2.fromOffset(px, py)
                end
            end)
        end
    end

    ToggleButton.MouseButton1Click:Connect(function() SetOpen(not open) end)
    CloseBtn.MouseButton1Click:Connect(function() SetOpen(false) end)

    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            SetOpen(not open)
        end
    end)

    if opts.Logo then
        if type(opts.Logo) == "string" and opts.Logo:sub(1, 13) == "rbxassetid://" then
            ToggleIcon:Destroy()
            local img = Instance.new("ImageLabel")
            img.BackgroundTransparency = 1
            img.Size = UDim2.new(0.7, 0, 0.7, 0)
            img.Position = UDim2.new(0.5, 0, 0.5, 0)
            img.AnchorPoint = Vector2.new(0.5, 0.5)
            img.Image = opts.Logo
            img.ImageColor3 = Theme.Text
            img.ScaleType = Enum.ScaleType.Fit
            img.Parent = ToggleButton
            ToggleIcon = img
        else
            ToggleIcon.Text = tostring(opts.Logo)
        end
    end

    local window = {}
    local tabs = {}
    local tabCount = 0
    local currentTab = nil

    local function showTab(name)
        if currentTab == name then return end
        closeActiveDropdown()

        if currentTab and tabs[currentTab] then
            local t = tabs[currentTab]
            t.Container.Visible = false
            Tween(t.Button, {BackgroundColor3 = Theme.Card}, 0.15)
            Tween(t.Label, {TextColor3 = Theme.TextDim}, 0.15)
            Tween(t.Indicator, {BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0, 6)}, 0.15)
        end

        currentTab = name
        local t = tabs[name]
        if t then
            t.Container.Visible = true
            t.Container.CanvasPosition = Vector2.zero
            t.Container.Position = UDim2.new(0, 0, 0, 8)
            Tween(t.Container, {Position = UDim2.new(0, 0, 0, 0)}, 0.22)
            Tween(t.Button, {BackgroundColor3 = Theme.CardActive}, 0.15)
            Tween(t.Label, {TextColor3 = Theme.Text}, 0.15)
            Tween(t.Indicator, {BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0, 18)}, 0.2)
        end
    end

    function window:CreateTab(name, icon)
        name = tostring(name)
        tabCount += 1
        local order = tabCount

        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Theme.Card
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = order
        btn.Parent = TabsList
        Corner(btn, 8)
        Stroke(btn, Theme.Border, 1)

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 0, 6)
        indicator.Position = UDim2.new(0, 6, 0.5, -3)
        indicator.BackgroundColor3 = Theme.Accent
        indicator.BorderSizePixel = 0
        indicator.BackgroundTransparency = 1
        indicator.Parent = btn
        Corner(indicator, 2)

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 16, 0, 0)
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Font = Theme.Font
        label.TextSize = 13
        label.TextColor3 = Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Text = (icon and (icon .. "  ") or "") .. name
        label.Parent = btn

        btn.MouseEnter:Connect(function()
            if currentTab ~= name then
                Tween(btn, {BackgroundColor3 = Theme.CardHover}, 0.15)
                Tween(label, {TextColor3 = Theme.Text}, 0.15)
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= name then
                Tween(btn, {BackgroundColor3 = Theme.Card}, 0.15)
                Tween(label, {TextColor3 = Theme.TextDim}, 0.15)
            end
        end)
        btn.MouseButton1Click:Connect(function() showTab(name) end)

        local container = Instance.new("ScrollingFrame")
        container.Name = name
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = Theme.Accent
        container.ScrollBarImageTransparency = 0.4
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        container.Visible = false
        container.Parent = Content

        local cPad = Padding(container, 12, 12, 12, 12)
        local cLayout = Instance.new("UIListLayout")
        cLayout.Padding = UDim.new(0, 8)
        cLayout.SortOrder = Enum.SortOrder.LayoutOrder
        cLayout.Parent = container

        tabs[name] = {Button = btn, Label = label, Container = container, Indicator = indicator}
        if order == 1 then showTab(name) end

        local elements = {}
        elements._currentSection = container

        local function MakeSection(labelText)
            labelText = labelText or "Section"
            local sec = Instance.new("Frame")
            sec.Size = UDim2.new(1, 0, 0, 0)
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.BackgroundTransparency = 1
            sec.Parent = container

            local header = Instance.new("TextButton")
            header.Size = UDim2.new(1, 0, 0, 24)
            header.BackgroundColor3 = Theme.Card
            header.BackgroundTransparency = 1
            header.Text = ""
            header.AutoButtonColor = false
            header.Parent = sec
            Corner(header, 6)

            local hTitle = Instance.new("TextLabel")
            hTitle.BackgroundTransparency = 1
            hTitle.Position = UDim2.new(0, 8, 0, 0)
            hTitle.Size = UDim2.new(1, -28, 1, 0)
            hTitle.Font = Theme.FontBold
            hTitle.TextSize = 11
            hTitle.TextColor3 = Theme.Accent
            hTitle.TextXAlignment = Enum.TextXAlignment.Left
            hTitle.Text = string.upper(labelText)
            hTitle.Parent = header

            local hArrow = Instance.new("TextLabel")
            hArrow.BackgroundTransparency = 1
            hArrow.Position = UDim2.new(1, -20, 0, 0)
            hArrow.Size = UDim2.new(0, 14, 1, 0)
            hArrow.Font = Theme.FontBold
            hArrow.TextSize = 11
            hArrow.TextColor3 = Theme.TextMuted
            hArrow.Text = "v"
            hArrow.Parent = header

            local list = Instance.new("Frame")
            list.Size = UDim2.new(1, 0, 0, 0)
            list.BackgroundColor3 = Theme.Card
            list.BorderSizePixel = 0
            list.ClipsDescendants = true
            list.Visible = false
            list.Parent = sec
            Corner(list, 10)
            Stroke(list, Theme.Border, 1)
            Padding(list, 6, 6, 6, 6)

            local secLayout = Instance.new("UIListLayout")
            secLayout.Padding = UDim.new(0, 4)
            secLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secLayout.Parent = list

            local collapsed = false
            local function applyHeight(instant)
                local h = collapsed and 0 or (secLayout.AbsoluteContentSize.Y + 12)
                if not collapsed and h > 0 then list.Visible = true end
                if instant then
                    list.Size = UDim2.new(1, 0, 0, h)
                else
                    Tween(list, {Size = UDim2.new(1, 0, 0, h)}, 0.2)
                end
                if h <= 0 then list.Visible = false end
            end

            local pending = false
            secLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if collapsed or pending then return end
                pending = true
                task.defer(function()
                    pending = false
                    applyHeight(false)
                end)
            end)

            header.MouseEnter:Connect(function() Tween(header, {BackgroundTransparency = 0.6}, 0.15) end)
            header.MouseLeave:Connect(function() Tween(header, {BackgroundTransparency = 1}, 0.15) end)
            header.MouseButton1Click:Connect(function()
                collapsed = not collapsed
                Tween(hArrow, {Rotation = collapsed and 180 or 0}, 0.2)
                if collapsed then
                    Tween(list, {Size = UDim2.new(1, 0, 0, 0)}, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                    task.delay(0.2, function() if collapsed then list.Visible = false end end)
                else
                    list.Visible = true
                    applyHeight(false)
                end
            end)

            return list
        end

        local function MakeRow(height)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, height or 36)
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0
            row.Parent = elements._currentSection or container
            return row
        end

        function elements:CreateToggle(text, default, callback)
            callback = callback or function() end
            local state = default and true or false

            local row = MakeRow(36)
            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundColor3 = Theme.CardHover
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Parent = row
            Corner(hit, 6)
            local hitStroke = Stroke(hit, Theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(1, -64, 1, 0)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Text = text
            label.Parent = hit

            local switch = Instance.new("Frame")
            switch.Size = UDim2.new(0, 38, 0, 22)
            switch.Position = UDim2.new(1, -50, 0.5, -11)
            switch.BackgroundColor3 = Theme.Background
            switch.BorderSizePixel = 0
            switch.Parent = hit
            Corner(switch, 11)
            local switchStroke = Stroke(switch, Theme.Border, 1)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = UDim2.new(0, 3, 0.5, -8)
            knob.BackgroundColor3 = Theme.Text
            knob.BorderSizePixel = 0
            knob.Parent = switch
            Corner(knob, 8)

            local function refresh()
                Tween(switch, {BackgroundColor3 = state and Theme.Accent or Theme.Background}, 0.18)
                Tween(switchStroke, {Color = state and Theme.Accent or Theme.Border}, 0.18)
                Tween(hitStroke, {Color = state and Theme.AccentDim or Theme.Border}, 0.18)
                Tween(knob, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.18, Enum.EasingStyle.Back)
            end
            refresh()

            hit.MouseEnter:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardActive}, 0.15) end)
            hit.MouseLeave:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardHover}, 0.15) end)
            hit.MouseButton1Click:Connect(function()
                state = not state
                refresh()
                callback(state)
            end)

            local api = {}
            function api:Set(val)
                val = val and true or false
                if val == state then return end
                state = val
                refresh()
                callback(state)
            end
            function api:Get() return state end
            return api
        end

        function elements:CreateButton(text, callback)
            callback = callback or function() end
            local row = MakeRow(36)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundColor3 = Theme.Accent
            btn.Text = text
            btn.TextColor3 = Theme.Text
            btn.Font = Theme.FontBold
            btn.TextSize = 13
            btn.TextTruncate = Enum.TextTruncate.AtEnd
            btn.AutoButtonColor = false
            btn.Parent = row
            Corner(btn, 6)
            Stroke(btn, Theme.AccentHover, 1)

            local function rest()
                Tween(btn, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}, 0.12, Enum.EasingStyle.Back)
            end
            btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = Theme.AccentHover}, 0.15) end)
            btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Theme.Accent}, 0.15) rest() end)
            btn.MouseButton1Down:Connect(function()
                Tween(btn, {Size = UDim2.new(1, -6, 1, -3), Position = UDim2.new(0, 3, 0, 1)}, 0.06)
            end)
            btn.MouseButton1Up:Connect(rest)
            btn.MouseButton1Click:Connect(function() callback() end)
        end

        function elements:CreateSlider(text, sopts, callback)
            sopts = sopts or {}
            callback = callback or function() end
            local min, max = sopts.Min or 0, sopts.Max or 100
            if max <= min then max = min + 1 end
            local precise = sopts.Precise or false
            local suffix = sopts.Suffix or ""
            local value = math.clamp(sopts.Default or min, min, max)

            local function fmt(v)
                if precise then
                    return string.format("%.2f", v) .. suffix
                end
                return tostring(math.floor(v + 0.5)) .. suffix
            end

            local row = MakeRow(58)
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = Theme.CardHover
            bg.BorderSizePixel = 0
            bg.Parent = row
            Corner(bg, 8)
            Stroke(bg, Theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 7)
            label.Size = UDim2.new(1, -110, 0, 15)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Text = text
            label.Parent = bg

            local valueLabel = Instance.new("TextLabel")
            valueLabel.BackgroundTransparency = 1
            valueLabel.AnchorPoint = Vector2.new(1, 0)
            valueLabel.Position = UDim2.new(1, -12, 0, 7)
            valueLabel.Size = UDim2.new(0, 90, 0, 15)
            valueLabel.Font = Theme.FontBold
            valueLabel.TextSize = 12
            valueLabel.TextColor3 = Theme.Accent
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Text = fmt(value)
            valueLabel.Parent = bg

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -24, 0, 6)
            track.Position = UDim2.new(0, 12, 0, 38)
            track.BackgroundColor3 = Theme.Background
            track.BorderSizePixel = 0
            track.Parent = bg
            Corner(track, 3)

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            Corner(fill, 3)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 14, 0, 14)
            knob.BackgroundColor3 = Theme.Text
            knob.BorderSizePixel = 0
            knob.Parent = track
            Corner(knob, 7)

            local function visual(ratio)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                knob.Position = UDim2.new(ratio, -7, 0.5, -7)
            end
            visual((value - min) / (max - min))

            local dragging = false
            local function update(input)
                local abs, size = track.AbsolutePosition.X, track.AbsoluteSize.X
                if size <= 0 then return end
                local r = math.clamp((input.Position.X - abs) / size, 0, 1)
                local v = min + (max - min) * r
                if not precise then v = math.floor(v + 0.5) end
                value = v
                visual(r)
                valueLabel.Text = fmt(value)
                callback(value)
            end
            local function begin(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Tween(knob, {Size = UDim2.new(0, 16, 0, 16)}, 0.1)
                    update(input)
                end
            end
            for _, obj in ipairs({bg, track, fill, knob}) do
                obj.InputBegan:Connect(begin)
            end
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then
                        dragging = false
                        Tween(knob, {Size = UDim2.new(0, 14, 0, 14)}, 0.15)
                    end
                end
            end)

            local api = {}
            function api:Set(val)
                value = math.clamp(val, min, max)
                visual((value - min) / (max - min))
                valueLabel.Text = fmt(value)
                callback(value)
            end
            function api:Get() return value end
            return api
        end

        function elements:CreateDropdown(text, options, default, callback)
            callback = callback or function() end
            options = options or {}
            local selected = default
            if selected == nil then selected = options[1] end

            local row = MakeRow(36)
            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundColor3 = Theme.CardHover
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Parent = row
            Corner(hit, 6)
            Stroke(hit, Theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(1, -36, 1, 0)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Text = text .. ":  " .. tostring(selected)
            label.Parent = hit

            local arrow = Instance.new("TextLabel")
            arrow.BackgroundTransparency = 1
            arrow.AnchorPoint = Vector2.new(1, 0)
            arrow.Position = UDim2.new(1, -10, 0, 0)
            arrow.Size = UDim2.new(0, 16, 1, 0)
            arrow.Font = Theme.FontBold
            arrow.TextSize = 12
            arrow.TextColor3 = Theme.TextDim
            arrow.Text = "v"
            arrow.Parent = hit

            local overlay = makeOverlay(hit, arrow)

            local function refreshLabel()
                label.Text = text .. ":  " .. tostring(selected)
            end

            local function build()
                for _, c in ipairs(overlay.holder:GetChildren()) do
                    if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
                end
                local n = #options
                local itemH, gap = 26, 2
                local contentH = n * itemH + math.max(0, n - 1) * gap + 8
                local targetH = math.min(contentH, 180)

                if n == 0 then
                    local empty = Instance.new("TextLabel")
                    empty.Size = UDim2.new(1, 0, 0, 24)
                    empty.BackgroundTransparency = 1
                    empty.Font = Theme.Font
                    empty.TextSize = 12
                    empty.TextColor3 = Theme.TextMuted
                    empty.Text = "— пусто —"
                    empty.Parent = overlay.holder
                end

                for i, opt in ipairs(options) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1, 0, 0, itemH)
                    b.BackgroundColor3 = (opt == selected) and Theme.AccentDim or Theme.CardHover
                    b.Text = tostring(opt)
                    b.TextColor3 = (opt == selected) and Theme.Text or Theme.TextDim
                    b.Font = Theme.Font
                    b.TextSize = 12
                    b.TextXAlignment = Enum.TextXAlignment.Left
                    b.TextTruncate = Enum.TextTruncate.AtEnd
                    b.AutoButtonColor = false
                    b.LayoutOrder = i
                    b.Parent = overlay.holder
                    Corner(b, 6)
                    Padding(b, 0, 10, 0, 10)

                    b.MouseEnter:Connect(function()
                        if opt ~= selected then Tween(b, {BackgroundColor3 = Theme.CardActive}, 0.12) end
                    end)
                    b.MouseLeave:Connect(function()
                        Tween(b, {BackgroundColor3 = (opt == selected) and Theme.AccentDim or Theme.CardHover}, 0.12)
                    end)
                    b.MouseButton1Click:Connect(function()
                        selected = opt
                        refreshLabel()
                        callback(selected)
                        overlay.close()
                    end)
                end
                return targetH, contentH
            end

            hit.MouseEnter:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardActive}, 0.15) end)
            hit.MouseLeave:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardHover}, 0.15) end)
            hit.MouseButton1Click:Connect(function()
                closeActiveDropdown()
                activeDropdown = overlay
                local targetH, contentH = build()
                overlay.show(targetH, contentH)
            end)

            local api = {}
            function api:Refresh(newOptions)
                options = newOptions or {}
                if selected ~= nil and not table.find(options, selected) then
                    selected = options[1]
                end
                refreshLabel()
            end
            function api:Set(val)
                selected = val
                refreshLabel()
                callback(selected)
            end
            function api:Get() return selected end
            return api
        end

        function elements:CreateMultiDropdown(text, options, defaults, callback)
            callback = callback or function() end
            options = options or {}
            local selectedSet = {}
            for _, v in ipairs(defaults or {}) do selectedSet[v] = true end

            local row = MakeRow(36)
            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundColor3 = Theme.CardHover
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Parent = row
            Corner(hit, 6)
            Stroke(hit, Theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(1, -36, 1, 0)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Parent = hit

            local arrow = Instance.new("TextLabel")
            arrow.BackgroundTransparency = 1
            arrow.AnchorPoint = Vector2.new(1, 0)
            arrow.Position = UDim2.new(1, -10, 0, 0)
            arrow.Size = UDim2.new(0, 16, 1, 0)
            arrow.Font = Theme.FontBold
            arrow.TextSize = 12
            arrow.TextColor3 = Theme.TextDim
            arrow.Text = "v"
            arrow.Parent = hit

            local overlay = makeOverlay(hit, arrow)

            local function getSelected()
                local out = {}
                for _, opt in ipairs(options) do
                    if selectedSet[opt] then out[#out + 1] = opt end
                end
                return out
            end

            local function refreshLabel()
                local sel = getSelected()
                local s
                if #sel == 0 then
                    s = "None"
                elseif #sel <= 2 then
                    local names = {}
                    for i, v in ipairs(sel) do names[i] = tostring(v) end
                    s = table.concat(names, ", ")
                else
                    s = #sel .. " selected"
                end
                label.Text = text .. ":  " .. s
            end
            refreshLabel()

            local function build()
                for _, c in ipairs(overlay.holder:GetChildren()) do
                    if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
                end
                local n = #options
                local itemH, gap = 30, 2
                local contentH = n * itemH + math.max(0, n - 1) * gap + 8
                local targetH = math.min(contentH, 190)

                for i, opt in ipairs(options) do
                    local isSel = selectedSet[opt] and true or false
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1, 0, 0, itemH)
                    b.BackgroundColor3 = Theme.CardHover
                    b.Text = ""
                    b.AutoButtonColor = false
                    b.LayoutOrder = i
                    b.Parent = overlay.holder
                    Corner(b, 6)

                    local check = Instance.new("Frame")
                    check.Size = UDim2.new(0, 16, 0, 16)
                    check.Position = UDim2.new(0, 8, 0.5, -8)
                    check.BackgroundColor3 = isSel and Theme.Accent or Theme.Background
                    check.BorderSizePixel = 0
                    check.Parent = b
                    Corner(check, 5)
                    Stroke(check, Theme.Border, 1)

                    local mark = Instance.new("TextLabel")
                    mark.BackgroundTransparency = 1
                    mark.Size = UDim2.new(1, 0, 1, 0)
                    mark.Font = Theme.FontBold
                    mark.TextSize = 12
                    mark.TextColor3 = Theme.Text
                    mark.Text = isSel and "✓" or ""
                    mark.Parent = check

                    local optLabel = Instance.new("TextLabel")
                    optLabel.BackgroundTransparency = 1
                    optLabel.Position = UDim2.new(0, 32, 0, 0)
                    optLabel.Size = UDim2.new(1, -40, 1, 0)
                    optLabel.Font = Theme.Font
                    optLabel.TextSize = 12
                    optLabel.TextColor3 = isSel and Theme.Text or Theme.TextDim
                    optLabel.TextXAlignment = Enum.TextXAlignment.Left
                    optLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    optLabel.Text = tostring(opt)
                    optLabel.Parent = b

                    local function style(sel)
                        Tween(check, {BackgroundColor3 = sel and Theme.Accent or Theme.Background}, 0.12)
                        mark.Text = sel and "✓" or ""
                        Tween(optLabel, {TextColor3 = sel and Theme.Text or Theme.TextDim}, 0.12)
                    end

                    b.MouseEnter:Connect(function() Tween(b, {BackgroundColor3 = Theme.CardActive}, 0.12) end)
                    b.MouseLeave:Connect(function() Tween(b, {BackgroundColor3 = Theme.CardHover}, 0.12) end)
                    b.MouseButton1Click:Connect(function()
                        if selectedSet[opt] then selectedSet[opt] = nil else selectedSet[opt] = true end
                        style(selectedSet[opt] and true or false)
                        refreshLabel()
                        callback(getSelected())
                    end)
                end
                return targetH, contentH
            end

            hit.MouseEnter:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardActive}, 0.15) end)
            hit.MouseLeave:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardHover}, 0.15) end)
            hit.MouseButton1Click:Connect(function()
                closeActiveDropdown()
                activeDropdown = overlay
                local targetH, contentH = build()
                overlay.show(targetH, contentH)
            end)

            local api = {}
            function api:Refresh(newOptions)
                options = newOptions or {}
                for k in pairs(selectedSet) do
                    if not table.find(options, k) then selectedSet[k] = nil end
                end
                refreshLabel()
            end
            function api:Set(list)
                selectedSet = {}
                for _, v in ipairs(list or {}) do selectedSet[v] = true end
                refreshLabel()
                callback(getSelected())
            end
            function api:Get() return getSelected() end
            return api
        end

        function elements:CreateInput(text, placeholder, callback, live)
            callback = callback or function() end
            local row = MakeRow(58)
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = Theme.CardHover
            bg.BorderSizePixel = 0
            bg.Parent = row
            Corner(bg, 8)
            Stroke(bg, Theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 7)
            label.Size = UDim2.new(1, -24, 0, 15)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Text = text
            label.Parent = bg

            local box = Instance.new("TextBox")
            box.Position = UDim2.new(0, 8, 0, 27)
            box.Size = UDim2.new(1, -16, 0, 22)
            box.BackgroundColor3 = Theme.Background
            box.BorderSizePixel = 0
            box.Font = Theme.Font
            box.TextSize = 12
            box.TextColor3 = Theme.Text
            box.PlaceholderText = placeholder or text
            box.PlaceholderColor3 = Theme.TextMuted
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.Text = ""
            box.Parent = bg
            Corner(box, 6)
            local boxStroke = Stroke(box, Theme.Border, 1)
            Padding(box, 0, 10, 0, 10)

            box.Focused:Connect(function() Tween(boxStroke, {Color = Theme.Accent}, 0.15) end)
            box.FocusLost:Connect(function(enter)
                Tween(boxStroke, {Color = Theme.Border}, 0.15)
                if enter then callback(box.Text) end
            end)
            if live then
                box:GetPropertyChangedSignal("Text"):Connect(function() callback(box.Text) end)
            end

            local api = {}
            function api:Set(txt) box.Text = tostring(txt or "") end
            function api:Get() return box.Text end
            return api
        end

        function elements:CreateKeybind(text, default, callback)
            callback = callback or function() end
            local key = default

            local row = MakeRow(36)
            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundColor3 = Theme.CardHover
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Parent = row
            Corner(hit, 6)
            Stroke(hit, Theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(1, -110, 1, 0)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Text = text
            label.Parent = hit

            local chip = Instance.new("Frame")
            chip.AnchorPoint = Vector2.new(1, 0.5)
            chip.Position = UDim2.new(1, -10, 0.5, 0)
            chip.Size = UDim2.new(0, 80, 0, 22)
            chip.BackgroundColor3 = Theme.Card
            chip.BorderSizePixel = 0
            chip.Parent = hit
            Corner(chip, 6)
            local chipStroke = Stroke(chip, Theme.Border, 1)

            local chipLabel = Instance.new("TextLabel")
            chipLabel.BackgroundTransparency = 1
            chipLabel.Position = UDim2.new(0, 4, 0, 0)
            chipLabel.Size = UDim2.new(1, -8, 1, 0)
            chipLabel.Font = Theme.FontBold
            chipLabel.TextSize = 10
            chipLabel.TextColor3 = Theme.TextDim
            chipLabel.TextTruncate = Enum.TextTruncate.AtEnd
            chipLabel.Text = key and key.Name or "None"
            chipLabel.Parent = chip

            local listening = false
            local function refresh()
                chipLabel.Text = key and key.Name or "None"
                Tween(chipStroke, {Color = listening and Theme.Accent or Theme.Border}, 0.15)
                Tween(chipLabel, {TextColor3 = listening and Theme.Text or Theme.TextDim}, 0.15)
                Tween(chip, {BackgroundColor3 = listening and Theme.AccentDim or Theme.Card}, 0.15)
            end

            hit.MouseEnter:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardActive}, 0.15) end)
            hit.MouseLeave:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardHover}, 0.15) end)
            hit.MouseButton1Click:Connect(function()
                listening = not listening
                refresh()
                if listening then chipLabel.Text = "..." end
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                            key = nil
                        else
                            key = input.KeyCode
                        end
                        listening = false
                        refresh()
                        callback(key)
                    end
                    return
                end
                if key and not gpe and input.KeyCode == key then
                    callback(key)
                end
            end)

            local api = {}
            function api:Set(k) key = k refresh() end
            function api:Get() return key end
            return api
        end

        function elements:CreateLabel(text)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.BackgroundTransparency = 1
            row.Parent = elements._currentSection or container

            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Position = UDim2.new(0, 10, 0, 2)
            l.Size = UDim2.new(1, -20, 0, 0)
            l.AutomaticSize = Enum.AutomaticSize.Y
            l.TextWrapped = true
            l.Font = Theme.Font
            l.TextSize = 12
            l.TextColor3 = Theme.TextDim
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextYAlignment = Enum.TextYAlignment.Top
            l.Text = tostring(text)
            l.Parent = row

            local api = {}
            function api:Set(txt) l.Text = tostring(txt) end
            return api
        end

        function elements:CreateSection(text)
            elements._currentSection = MakeSection(text)
            return elements
        end

        function elements:Clear()
            closeActiveDropdown()
            for _, child in ipairs(container:GetChildren()) do
                if child ~= cPad and child ~= cLayout then
                    child:Destroy()
                end
            end
            elements._currentSection = container
            container.CanvasPosition = Vector2.zero
        end

        return elements
    end

    function window:SelectTab(name)
        if tabs[name] then showTab(name) end
    end

    function window:Destroy()
        ScreenGui:Destroy()
    end

    task.defer(function() SetOpen(true) end)
    return window
end

return Menu

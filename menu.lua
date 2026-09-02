local Menu = {}
Menu.__index = Menu

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse  = Player:GetMouse()

local Theme = {
    Background    = Color3.fromRGB(14, 14, 18),
    Topbar        = Color3.fromRGB(20, 20, 26),
    Sidebar       = Color3.fromRGB(18, 18, 24),
    Card          = Color3.fromRGB(26, 26, 34),
    CardHover     = Color3.fromRGB(34, 34, 44),
    CardActive    = Color3.fromRGB(40, 40, 52),
    Accent        = Color3.fromRGB(230, 60, 80),
    AccentHover   = Color3.fromRGB(255, 90, 110),
    AccentDim     = Color3.fromRGB(80, 25, 35),
    Text          = Color3.fromRGB(240, 240, 248),
    TextDim       = Color3.fromRGB(140, 140, 160),
    TextMuted     = Color3.fromRGB(90, 90, 110),
    Border        = Color3.fromRGB(38, 38, 50),
    BorderAccent  = Color3.fromRGB(230, 60, 80),
    Success       = Color3.fromRGB(60, 200, 130),
    Danger        = Color3.fromRGB(230, 70, 90),
    Font          = Enum.Font.GothamMedium,
    FontBold      = Enum.Font.GothamBold,
    FontLight     = Enum.Font.Gotham,
}

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
    p.PaddingTop    = UDim.new(0, top    or 8)
    p.PaddingRight  = UDim.new(0, right  or 8)
    p.PaddingBottom = UDim.new(0, bottom or 8)
    p.PaddingLeft   = UDim.new(0, left   or 8)
    p.Parent = parent
    return p
end

local function ListLayout(parent, gap, dir)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, gap or 6)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

local function AddShadow(parent)
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"
    s.BackgroundTransparency = 1
    s.Image = "rbxassetid://6014261993"
    s.ImageColor3 = Color3.fromRGB(0, 0, 0)
    s.ImageTransparency = 0.55
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(49, 49, 450, 450)
    s.Size = UDim2.new(1, 40, 1, 40)
    s.Position = UDim2.new(0.5, 0, 0.5, 0)
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.ZIndex = -1
    s.Parent = parent
end

local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.18,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out
    ), props):Play()
end

local function MakeDraggable(topbar, object)
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            object.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

if CoreGui:FindFirstChild("Menu") then
    CoreGui:FindFirstChild("Menu"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end

local WindowSize = Vector2.new(580, 400)

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Toggle"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 18, 0.5, -25)
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
ToggleIcon.TextSize = 26
ToggleIcon.TextColor3 = Theme.Text
ToggleIcon.Text = "M"
ToggleIcon.Parent = ToggleButton

ToggleButton.MouseEnter:Connect(function()
    Tween(ToggleButton, {BackgroundColor3 = Theme.AccentHover}, 0.15)
end)
ToggleButton.MouseLeave:Connect(function()
    Tween(ToggleButton, {BackgroundColor3 = Theme.Accent}, 0.15)
end)

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.fromOffset(WindowSize.X, WindowSize.Y)
Window.Position = UDim2.fromOffset(
    (Mouse.ViewSizeX - WindowSize.X) / 2,
    (Mouse.ViewSizeY - WindowSize.Y) / 2
)
Window.BackgroundColor3 = Theme.Background
Window.BorderSizePixel = 0
Window.Visible = false
Window.Parent = ScreenGui
Corner(Window, 12)
Stroke(Window, Theme.Border, 1)
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
TitleLabel.Text = "Menu"
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
    CloseIcon.TextColor3 = Theme.Text
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, {BackgroundColor3 = Theme.Card}, 0.15)
    CloseIcon.TextColor3 = Theme.TextDim
end)

MakeDraggable(TitleBar, Window)

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 150, 1, -44)
Sidebar.Position = UDim2.new(0, 0, 0, 44)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Window

local SidebarMask = Instance.new("Frame")
SidebarMask.Size = UDim2.new(0, 12, 1, 0)
SidebarMask.Position = UDim2.new(1, -12, 0, 0)
SidebarMask.BackgroundColor3 = Theme.Sidebar
SidebarMask.BorderSizePixel = 0
SidebarMask.Parent = Sidebar

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
ListLayout(TabsList, 4)

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -150, 1, -44)
Content.Position = UDim2.new(0, 150, 0, 44)
Content.BackgroundColor3 = Theme.Background
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.Parent = Window

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
    open = state
    Window.Visible = true
    Window.BackgroundTransparency = 1
    Tween(Window, {BackgroundTransparency = 0}, 0.15)
    RefreshIcon(state)
    if not state then
        task.delay(0.15, function()
            if not open then Window.Visible = false end
        end)
    end
end

ToggleButton.MouseButton1Click:Connect(function() SetOpen(not open) end)
CloseBtn.MouseButton1Click:Connect(function() SetOpen(false) end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        SetOpen(not open)
    end
end)

function Menu:CreateWindow(opts)
    opts = opts or {}
    TitleLabel.Text = opts.Title or "Menu"

    if opts.Logo then
        if type(opts.Logo) == "string" and opts.Logo:find("rbxassetid://") == 1 then
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
            ToggleIcon.Text = opts.Logo
        end
    end

    local window = {}

    local tabs = {}
    local currentTab = nil

    local function showTab(name)
        if currentTab and tabs[currentTab] then
            tabs[currentTab].Container.Visible = false
            tabs[currentTab].Button.BackgroundColor3 = Theme.Card
            tabs[currentTab].Button.TextColor3 = Theme.TextDim
            if tabs[currentTab].Indicator then
                Tween(tabs[currentTab].Indicator, {BackgroundTransparency = 1}, 0.15)
            end
        end
        currentTab = name
        if tabs[name] then
            tabs[name].Container.Visible = true
            tabs[name].Button.BackgroundColor3 = Theme.CardActive
            tabs[name].Button.TextColor3 = Theme.Text
            if tabs[name].Indicator then
                Tween(tabs[name].Indicator, {BackgroundTransparency = 0}, 0.15)
            end
        end
    end

    function window:CreateTab(name, icon)
        local order = #tabs + 1

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
        indicator.Size = UDim2.new(0, 3, 0, 18)
        indicator.Position = UDim2.new(0, 6, 0.5, -9)
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

        local pad = Instance.new("UIPadding")
        pad.PaddingTop    = UDim.new(0, 12)
        pad.PaddingRight  = UDim.new(0, 12)
        pad.PaddingBottom = UDim.new(0, 12)
        pad.PaddingLeft   = UDim.new(0, 12)
        pad.Parent = container

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container

        tabs[name] = {Button = btn, Container = container, Indicator = indicator}

        btn.MouseButton1Click:Connect(function() showTab(name) end)

        if order == 1 then showTab(name) end

        local elements = {}

        local function MakeSection(label)
            local sec = Instance.new("Frame")
            sec.Size = UDim2.new(1, 0, 0, 0)
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.BackgroundTransparency = 1
            sec.Parent = container

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 22)
            title.BackgroundTransparency = 1
            title.Font = Theme.FontBold
            title.TextSize = 11
            title.TextColor3 = Theme.Accent
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Text = string.upper(label or "Section")
            title.Parent = sec

            local list = Instance.new("Frame")
            list.Size = UDim2.new(1, 0, 0, 0)
            list.AutomaticSize = Enum.AutomaticSize.Y
            list.BackgroundColor3 = Theme.Card
            list.BorderSizePixel = 0
            list.Parent = sec
            Corner(list, 10)
            Stroke(list, Theme.Border, 1)

            local secPad = Instance.new("UIPadding")
            secPad.PaddingTop    = UDim.new(0, 6)
            secPad.PaddingRight  = UDim.new(0, 6)
            secPad.PaddingBottom = UDim.new(0, 6)
            secPad.PaddingLeft   = UDim.new(0, 6)
            secPad.Parent = list

            local secLayout = Instance.new("UIListLayout")
            secLayout.Padding = UDim.new(0, 4)
            secLayout.FillDirection = Enum.FillDirection.Vertical
            secLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            secLayout.SortOrder = Enum.SortOrder.LayoutOrder
            secLayout.Parent = list

            return list
        end

        local function MakeRow(parent, height)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, height or 36)
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0
            row.Parent = parent
            return row
        end

        function elements:CreateToggle(text, default, callback)
            callback = callback or function() end
            local state = default or false

            local row = MakeRow(elements._currentSection or container, 36)
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
            label.Size = UDim2.new(1, -64, 1, 0)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = text
            label.Parent = hit

            local switch = Instance.new("Frame")
            switch.Size = UDim2.new(0, 38, 0, 22)
            switch.Position = UDim2.new(1, -50, 0.5, -11)
            switch.BackgroundColor3 = state and Theme.Accent or Theme.Background
            switch.BorderSizePixel = 0
            switch.Parent = hit
            Corner(switch, 11)
            Stroke(switch, state and Theme.Accent or Theme.Border, 1)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            knob.BackgroundColor3 = Theme.Text
            knob.BorderSizePixel = 0
            knob.Parent = switch
            Corner(knob, 8)

            local function refresh()
                Tween(switch, {BackgroundColor3 = state and Theme.Accent or Theme.Background}, 0.18)
                Tween(knob, {
                    Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                }, 0.18)
                Tween(switch, {
                    Color = state and Theme.Accent or Theme.Border
                }, 0.18)
            end

            hit.MouseEnter:Connect(function()
                if not state then Tween(hit, {BackgroundColor3 = Theme.CardActive}, 0.15) end
            end)
            hit.MouseLeave:Connect(function()
                if not state then Tween(hit, {BackgroundColor3 = Theme.CardHover}, 0.15) end
            end)

            hit.MouseButton1Click:Connect(function()
                state = not state
                refresh()
                callback(state)
            end)
        end

        function elements:CreateButton(text, callback)
            callback = callback or function() end
            local row = MakeRow(elements._currentSection or container, 36)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundColor3 = Theme.Accent
            btn.Text = text
            btn.TextColor3 = Theme.Text
            btn.Font = Theme.FontBold
            btn.TextSize = 13
            btn.AutoButtonColor = false
            btn.Parent = row
            Corner(btn, 6)
            Stroke(btn, Theme.AccentHover, 1)

            btn.MouseEnter:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.AccentHover}, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.Accent}, 0.15)
            end)
            btn.MouseButton1Down:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.AccentDim}, 0.05)
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.AccentHover}, 0.1)
            end)
            btn.MouseButton1Click:Connect(function() callback() end)
        end

        function elements:CreateSlider(text, opts, callback)
            opts = opts or {}
            callback = callback or function() end
            local min    = opts.Min or 0
            local max    = opts.Max or 100
            local value  = opts.Default or min
            local suffix = opts.Suffix or ""

            local row = MakeRow(elements._currentSection or container, 54)
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = Theme.CardHover
            bg.BorderSizePixel = 0
            bg.Parent = row
            Corner(bg, 8)
            Stroke(bg, Theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 6)
            label.Size = UDim2.new(1, -24, 0, 16)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = text
            label.Parent = bg

            local valueLabel = Instance.new("TextLabel")
            valueLabel.BackgroundTransparency = 1
            valueLabel.Position = UDim2.new(0, 12, 0, 6)
            valueLabel.Size = UDim2.new(1, -24, 0, 16)
            valueLabel.Font = Theme.FontBold
            valueLabel.TextSize = 12
            valueLabel.TextColor3 = Theme.Accent
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Text = tostring(value) .. suffix
            valueLabel.Parent = bg

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -24, 0, 6)
            track.Position = UDim2.new(0, 12, 0, 36)
            track.BackgroundColor3 = Theme.Background
            track.BorderSizePixel = 0
            track.Parent = bg
            Corner(track, 3)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((max - min) == 0 and 0 or (value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            Corner(fill, 3)

            local function update(input)
                local abs  = track.AbsolutePosition.X
                local size = track.AbsoluteSize.X
                if size == 0 then return end
                local pos = math.clamp((input.Position.X - abs) / size, 0, 1)
                value = math.floor(min + (max - min) * pos + 0.5)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                valueLabel.Text = tostring(value) .. suffix
                callback(value)
            end

            local dragging = false
            local function begin(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end
            local function finish(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end
            track.InputBegan:Connect(begin)
            track.InputEnded:Connect(finish)
            bg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
        end

        function elements:CreateDropdown(text, options, default, callback)
            callback = callback or function() end
            options = options or {}
            local selected = default or options[1] or ""

            local row = MakeRow(elements._currentSection or container, 36)
            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundColor3 = Theme.CardHover
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.ZIndex = 3
            hit.Parent = row
            Corner(hit, 6)
            Stroke(hit, Theme.Border, 1)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(1, -30, 1, 0)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = text .. ":  " .. tostring(selected)
            label.ZIndex = 4
            label.Parent = hit

            local arrow = Instance.new("TextLabel")
            arrow.BackgroundTransparency = 1
            arrow.Position = UDim2.new(1, -22, 0, 0)
            arrow.Size = UDim2.new(0, 16, 1, 0)
            arrow.Font = Theme.FontBold
            arrow.TextSize = 12
            arrow.TextColor3 = Theme.TextDim
            arrow.Text = "v"
            arrow.ZIndex = 4
            arrow.Parent = hit

            local listHolder = Instance.new("Frame")
            listHolder.Size = UDim2.new(1, 0, 0, math.max(#options * 30 + 8, 38))
            listHolder.Position = UDim2.new(0, 0, 1, 4)
            listHolder.BackgroundColor3 = Theme.Card
            listHolder.BorderSizePixel = 0
            listHolder.Visible = false
            listHolder.ZIndex = 10
            listHolder.Parent = hit
            Corner(listHolder, 6)
            Stroke(listHolder, Theme.Border, 1)

            local listPad = Instance.new("UIPadding")
            listPad.PaddingTop    = UDim.new(0, 4)
            listPad.PaddingRight  = UDim.new(0, 4)
            listPad.PaddingBottom = UDim.new(0, 4)
            listPad.PaddingLeft   = UDim.new(0, 4)
            listPad.Parent = listHolder

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 2)
            listLayout.FillDirection = Enum.FillDirection.Vertical
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listHolder

            for i, opt in ipairs(options) do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, 0, 0, 28)
                b.BackgroundColor3 = Theme.CardHover
                b.Text = tostring(opt)
                b.TextColor3 = Theme.Text
                b.Font = Theme.Font
                b.TextSize = 12
                b.AutoButtonColor = false
                b.ZIndex = 11
                b.LayoutOrder = i
                b.Parent = listHolder
                Corner(b, 4)
                b.MouseEnter:Connect(function() Tween(b, {BackgroundColor3 = Theme.Accent}, 0.12) end)
                b.MouseLeave:Connect(function() Tween(b, {BackgroundColor3 = Theme.CardHover}, 0.12) end)
                b.MouseButton1Click:Connect(function()
                    selected = opt
                    label.Text = text .. ":  " .. tostring(selected)
                    listHolder.Visible = false
                    arrow.Text = "v"
                    callback(selected)
                end)
            end

            hit.MouseEnter:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardActive}, 0.15) end)
            hit.MouseLeave:Connect(function() Tween(hit, {BackgroundColor3 = Theme.CardHover}, 0.15) end)

            hit.MouseButton1Click:Connect(function()
                listHolder.Visible = not listHolder.Visible
                arrow.Text = listHolder.Visible and "^" or "v"
            end)
        end

        function elements:CreateInput(text, placeholder, callback)
            callback = callback or function() end
            local row = MakeRow(elements._currentSection or container, 36)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, 0, 1, 0)
            box.BackgroundColor3 = Theme.CardHover
            box.Font = Theme.Font
            box.TextSize = 13
            box.TextColor3 = Theme.Text
            box.PlaceholderText = text
            box.PlaceholderColor3 = Theme.TextMuted
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.Text = ""
            box.Parent = row
            Corner(box, 6)
            Stroke(box, Theme.Border, 1)

            local boxPad = Instance.new("UIPadding")
            boxPad.PaddingLeft  = UDim.new(0, 12)
            boxPad.PaddingRight = UDim.new(0, 12)
            boxPad.Parent = box

            box.Focused:Connect(function()
                Tween(box, {Color = Theme.Accent}, 0.15)
            end)
            box.FocusLost:Connect(function(enter)
                Tween(box, {Color = Theme.Border}, 0.15)
                if enter then callback(box.Text) end
            end)
        end

        function elements:CreateLabel(text)
            local row = MakeRow(elements._currentSection or container, 24)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(1, 0, 1, 0)
            l.Font = Theme.Font
            l.TextSize = 12
            l.TextColor3 = Theme.TextDim
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Text = "  " .. text
            l.Parent = row
        end

        function elements:CreateSection(text)
            elements._currentSection = MakeSection(text or "Section")
            return elements
        end

        elements._currentSection = container

        return elements
    end

    task.defer(function() SetOpen(true) end)

    return window
end

return Menu
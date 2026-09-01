local Menu = {}
Menu.__index = Menu

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")

local Player    = Players.LocalPlayer
local Mouse     = Player:GetMouse()

local Theme = {
    Background    = Color3.fromRGB(20, 20, 26),
    Topbar        = Color3.fromRGB(28, 28, 38),
    Card          = Color3.fromRGB(32, 32, 44),
    CardHover     = Color3.fromRGB(40, 40, 56),
    Accent        = Color3.fromRGB(110, 90, 255),
    AccentHover   = Color3.fromRGB(140, 120, 255),
    Text          = Color3.fromRGB(235, 235, 245),
    TextDim       = Color3.fromRGB(150, 150, 170),
    Border        = Color3.fromRGB(45, 45, 60),
    Success       = Color3.fromRGB(80, 200, 120),
    Danger        = Color3.fromRGB(230, 80, 100),
    Font          = Enum.Font.GothamMedium,
    FontBold      = Enum.Font.GothamBold,
}

local function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim2.new(0, radius or 8, 0, radius or 8)
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
    p.PaddingTop    = UDim2.new(0, top or 8)
    p.PaddingRight  = UDim2.new(0, right or 8)
    p.PaddingBottom = UDim2.new(0, bottom or 8)
    p.PaddingLeft   = UDim2.new(0, left or 8)
    p.Parent = parent
    return p
end

local function ListLayout(parent, gap, dir)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, gap or 6)
    l.FillDirection = dir or Enum.FillDirection.Vertical
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
    s.ImageTransparency = 0.5
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(49, 49, 450, 450)
    s.Size = UDim2.new(1, 30, 1, 30)
    s.Position = UDim2.new(0, -15, 0, -15)
    s.ZIndex = -1
    s.Parent = parent
end

local function Tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function MakeDraggable(topbar, object)
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
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

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "Toggle"
ToggleButton.Size = UDim2.new(0, 46, 0, 46)
ToggleButton.Position = UDim2.new(0, 16, 0.5, -23)
ToggleButton.BackgroundColor3 = Theme.Accent
ToggleButton.Text = "+"
ToggleButton.TextColor3 = Theme.Text
ToggleButton.TextSize = 24
ToggleButton.Font = Theme.FontBold
ToggleButton.AutoButtonColor = false
ToggleButton.Parent = ScreenGui
Corner(ToggleButton, 12)
Stroke(ToggleButton, Theme.AccentHover, 2)
AddShadow(ToggleButton)

ToggleButton.MouseEnter:Connect(function() Tween(ToggleButton, {BackgroundColor3 = Theme.AccentHover}) end)
ToggleButton.MouseLeave:Connect(function() Tween(ToggleButton, {BackgroundColor3 = Theme.Accent}) end)

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 560, 0, 380)
Window.Position = UDim2.new(0.5, -280, 0.5, -190)
Window.BackgroundColor3 = Theme.Background
Window.BorderSizePixel = 0
Window.Visible = false
Window.Parent = ScreenGui
Corner(Window, 10)
Stroke(Window, Theme.Border, 1)
AddShadow(Window)

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Theme.Topbar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Window
Corner(TitleBar, 10)

local fix = Instance.new("Frame")
fix.Size = UDim2.new(1, 0, 0, 12)
fix.Position = UDim2.new(0, 0, 1, -12)
fix.BackgroundColor3 = Theme.Topbar
fix.BorderSizePixel = 0
fix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Font = Theme.FontBold
TitleLabel.TextSize = 15
TitleLabel.TextColor3 = Theme.Text
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Text = "Menu"
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Theme.Card
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.Text
CloseBtn.Font = Theme.FontBold
CloseBtn.TextSize = 14
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Corner(CloseBtn, 6)
CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {BackgroundColor3 = Theme.Danger}) end)
CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {BackgroundColor3 = Theme.Card}) end)

MakeDraggable(TitleBar, Window)

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 140, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Theme.Topbar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Window

local SidebarCorner = Corner(Sidebar, 0)
local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 12, 1, 0)
SidebarFix.Position = UDim2.new(1, -12, 0, 0)
SidebarFix.BackgroundColor3 = Theme.Topbar
SidebarFix.BorderSizePixel = 0
SidebarFix.Parent = Sidebar

local TabsList = Instance.new("ScrollingFrame")
TabsList.Size = UDim2.new(1, -8, 1, -8)
TabsList.Position = UDim2.new(0, 4, 0, 4)
TabsList.BackgroundTransparency = 1
TabsList.BorderSizePixel = 0
TabsList.ScrollBarThickness = 2
TabsList.ScrollBarImageColor3 = Theme.Accent
TabsList.CanvasSize = UDim2.new(0, 0, 0, 0)
TabsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabsList.Parent = Sidebar
ListLayout(TabsList, 4)

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -140, 1, -40)
Content.Position = UDim2.new(0, 140, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = Window

local open = false
local function SetOpen(state)
    open = state
    Window.Visible = true
    Window.BackgroundTransparency = 1
    Tween(Window, {BackgroundTransparency = 0}, 0.15)
    ToggleButton.Text = state and "x" or "+"
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
    local window = {}

    local tabs = {}
    local currentTab = nil

    local function showTab(name)
        if currentTab and tabs[currentTab] then
            tabs[currentTab].Container.Visible = false
        end
        currentTab = name
        if tabs[name] then
            tabs[name].Container.Visible = true
            tabs[name].Button.BackgroundColor3 = Theme.Accent
            tabs[name].Button.TextColor3 = Theme.Text
        end
    end

    function window:CreateTab(name, icon)
        local order = #tabs + 1

        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = Theme.Card
        btn.Text = (icon and (icon .. "  ") or "") .. name
        btn.TextColor3 = Theme.TextDim
        btn.Font = Theme.Font
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.LayoutOrder = order
        btn.Parent = TabsList
        Corner(btn, 6)
        Padding(btn, 0, 10, 0, 10)

        btn.MouseEnter:Connect(function()
            if currentTab ~= name then
                Tween(btn, {BackgroundColor3 = Theme.CardHover})
            end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= name then
                Tween(btn, {BackgroundColor3 = Theme.Card})
            end
        end)

        local container = Instance.new("ScrollingFrame")
        container.Name = name
        container.Size = UDim2.new(1, -8, 1, -8)
        container.Position = UDim2.new(0, 4, 0, 4)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = Theme.Accent
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.AutomaticCanvasSize = Enum.AutomaticSize.Y
        container.Visible = false
        container.Parent = Content
        ListLayout(container, 6)

        tabs[name] = {Button = btn, Container = container}

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
            title.Size = UDim2.new(1, 0, 0, 18)
            title.BackgroundTransparency = 1
            title.Font = Theme.FontBold
            title.TextSize = 11
            title.TextColor3 = Theme.TextDim
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Text = string.upper(label)
            title.Parent = sec

            local list = Instance.new("Frame")
            list.Size = UDim2.new(1, 0, 0, 0)
            list.AutomaticSize = Enum.AutomaticSize.Y
            list.BackgroundColor3 = Theme.Card
            list.BorderSizePixel = 0
            list.Parent = sec
            Corner(list, 8)
            Stroke(list, Theme.Border, 1)
            Padding(list, 6, 6, 6, 6)
            ListLayout(list, 4)
            return list
        end

        local function MakeRow(parent, height)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, height or 34)
            row.BackgroundColor3 = Theme.Card
            row.BorderSizePixel = 0
            row.Parent = parent
            Corner(row, 6)
            return row
        end

        function elements:CreateToggle(text, default, callback)
            callback = callback or function() end
            local state = default or false

            local row = MakeRow(elements._currentSection or container)
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(1, -70, 1, 0)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = text
            label.Parent = row

            local switch = Instance.new("Frame")
            switch.Size = UDim2.new(0, 40, 0, 22)
            switch.Position = UDim2.new(1, -52, 0.5, -11)
            switch.BackgroundColor3 = state and Theme.Accent or Theme.Background
            switch.BorderSizePixel = 0
            switch.Parent = row
            Corner(switch, 11)
            Stroke(switch, Theme.Border, 1)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            knob.BackgroundColor3 = Theme.Text
            knob.BorderSizePixel = 0
            knob.Parent = switch
            Corner(knob, 8)

            local function refresh()
                Tween(switch, {BackgroundColor3 = state and Theme.Accent or Theme.Background}, 0.15)
                Tween(knob, {
                    Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                }, 0.15)
            end

            row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    state = not state
                    refresh()
                    callback(state)
                end
            end)
        end

        function elements:CreateButton(text, callback)
            callback = callback or function() end
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 34)
            btn.BackgroundColor3 = Theme.Card
            btn.Text = text
            btn.TextColor3 = Theme.Text
            btn.Font = Theme.Font
            btn.TextSize = 13
            btn.AutoButtonColor = false
            btn.Parent = elements._currentSection or container
            Corner(btn, 6)
            Stroke(btn, Theme.Border, 1)
            Padding(btn, 0, 12, 0, 12)

            btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = Theme.CardHover}) end)
            btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Theme.Card}) end)
            btn.MouseButton1Click:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.Accent}, 0.1)
                task.wait(0.1)
                Tween(btn, {BackgroundColor3 = Theme.CardHover}, 0.15)
                callback()
            end)
        end

        function elements:CreateSlider(text, opts, callback)
            opts = opts or {}
            callback = callback or function() end
            local min   = opts.Min or 0
            local max   = opts.Max or 100
            local value = opts.Default or min
            local suffix = opts.Suffix or ""

            local row = MakeRow(elements._currentSection or container, 50)
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 6)
            label.Size = UDim2.new(1, -24, 0, 16)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = text
            label.Parent = row

            local valueLabel = Instance.new("TextLabel")
            valueLabel.BackgroundTransparency = 1
            valueLabel.Position = UDim2.new(0, 12, 0, 6)
            valueLabel.Size = UDim2.new(1, -24, 0, 16)
            valueLabel.Font = Theme.Font
            valueLabel.TextSize = 13
            valueLabel.TextColor3 = Theme.Accent
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Text = tostring(value) .. suffix
            valueLabel.Parent = row

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -24, 0, 6)
            track.Position = UDim2.new(0, 12, 0, 32)
            track.BackgroundColor3 = Theme.Background
            track.BorderSizePixel = 0
            track.Parent = row
            Corner(track, 3)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            Corner(fill, 3)

            local function update(input)
                local abs = track.AbsolutePosition.X
                local size = track.AbsoluteSize.X
                local pos = math.clamp((input.Position.X - abs) / size, 0, 1)
                value = math.floor(min + (max - min) * pos + 0.5)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                valueLabel.Text = tostring(value) .. suffix
                callback(value)
            end

            local dragging = false
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end)
            track.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)
        end

        function elements:CreateDropdown(text, options, default, callback)
            callback = callback or function() end
            options = options or {}
            local selected = default or options[1] or ""

            local row = MakeRow(elements._currentSection or container, 34)
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Size = UDim2.new(1, -24, 1, 0)
            label.Font = Theme.Font
            label.TextSize = 13
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = text .. ":  " .. tostring(selected)
            label.Parent = row

            local arrow = Instance.new("TextLabel")
            arrow.BackgroundTransparency = 1
            arrow.Position = UDim2.new(1, -22, 0, 0)
            arrow.Size = UDim2.new(0, 16, 1, 0)
            arrow.Font = Theme.FontBold
            arrow.TextSize = 12
            arrow.TextColor3 = Theme.TextDim
            arrow.Text = "v"
            arrow.Parent = row

            local list = Instance.new("Frame")
            list.Size = UDim2.new(1, 0, 0, #options * 26 + 8)
            list.BackgroundColor3 = Theme.Background
            list.BorderSizePixel = 0
            list.Visible = false
            list.Parent = row
            list.ZIndex = 5
            Corner(list, 6)
            Stroke(list, Theme.Border, 1)
            Padding(list, 4, 4, 4, 4)
            ListLayout(list, 2)

            for _, opt in ipairs(options) do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, 0, 0, 24)
                b.BackgroundColor3 = Theme.Card
                b.Text = tostring(opt)
                b.TextColor3 = Theme.Text
                b.Font = Theme.Font
                b.TextSize = 12
                b.AutoButtonColor = false
                b.ZIndex = 6
                b.Parent = list
                Corner(b, 4)
                b.MouseEnter:Connect(function() Tween(b, {BackgroundColor3 = Theme.Accent}, 0.1) end)
                b.MouseLeave:Connect(function() Tween(b, {BackgroundColor3 = Theme.Card}, 0.1) end)
                b.MouseButton1Click:Connect(function()
                    selected = opt
                    label.Text = text .. ":  " .. tostring(selected)
                    list.Visible = false
                    arrow.Text = "v"
                    callback(selected)
                end)
            end

            row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    list.Visible = not list.Visible
                    arrow.Text = list.Visible and "^" or "v"
                end
            end)
        end

        function elements:CreateInput(text, placeholder, callback)
            callback = callback or function() end
            local row = MakeRow(elements._currentSection or container, 34)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, 0, 1, 0)
            box.BackgroundTransparency = 1
            box.Font = Theme.Font
            box.TextSize = 13
            box.TextColor3 = Theme.Text
            box.PlaceholderText = text
            box.PlaceholderColor3 = Theme.TextDim
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.Text = ""
            box.Parent = row
            Padding(box, 0, 12, 0, 12)

            box.FocusLost:Connect(function(enter)
                if enter then callback(box.Text) end
            end)
        end

        function elements:CreateLabel(text)
            local row = MakeRow(elements._currentSection or container, 26)
            row.BackgroundTransparency = 1
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(1, 0, 1, 0)
            l.Font = Theme.Font
            l.TextSize = 12
            l.TextColor3 = Theme.TextDim
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Text = text
            l.Parent = row
            Padding(l, 0, 12, 0, 12)
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

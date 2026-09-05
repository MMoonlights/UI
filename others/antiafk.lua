local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "AntiAFK"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 125, 0, 42)
frame.Position = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

local timer = Instance.new("TextLabel")
timer.Size = UDim2.new(0, 58, 1, 0)
timer.Position = UDim2.new(0, 8, 0, 0)
timer.BackgroundTransparency = 1
timer.Text = "00:00"
timer.TextColor3 = Color3.fromRGB(255, 255, 255)
timer.TextSize = 14
timer.Font = Enum.Font.GothamMedium
timer.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 50, 0, 26)
button.Position = UDim2.new(1, -58, 0.5, -13)
button.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
button.BorderSizePixel = 0
button.Text = "OFF"
button.TextColor3 = Color3.fromRGB(180, 180, 185)
button.TextSize = 11
button.Font = Enum.Font.GothamBold
button.Parent = frame

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)

local enabled = false
local startTime = 0

player.Idled:Connect(function()
    if enabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

button.MouseButton1Click:Connect(function()
    enabled = not enabled

    if enabled then
        startTime = tick()
        button.Text = "ON"
        button.BackgroundColor3 = Color3.fromRGB(55, 120, 75)
    else
        button.Text = "OFF"
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
        timer.Text = "00:00"
    end
end)

task.spawn(function()
    while gui.Parent do
        if enabled then
            local elapsed = math.floor(tick() - startTime)
            local minutes = math.floor(elapsed / 60)
            local seconds = elapsed % 60
            timer.Text = string.format("%02d:%02d", minutes, seconds)
        end

        task.wait(1)
    end
end)

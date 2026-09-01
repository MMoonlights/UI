local Menu = loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonlights/UI/refs/heads/main/menu.lua"))()

local Window = Menu:CreateWindow({
    Title = "My Cool Hub",
    Logo = "rbxassetid://123456789",
})

local PlayerTab = Window:CreateTab("Player")
PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle("Fly", false, function(state)
    print("Fly:", state)
end)

PlayerTab:CreateSlider("WalkSpeed", {Min = 16, Max = 500, Default = 16, Suffix = " studs"}, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end)

PlayerTab:CreateSlider("JumpPower", {Min = 50, Max = 500, Default = 50}, function(value)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = value
end)

PlayerTab:CreateSection("Teleport")
PlayerTab:CreateDropdown("Location", {"Spawn", "Shop", "PvP Arena", "Secret Base"}, "Spawn", function(place)
    print("Teleport to:", place)
end)

PlayerTab:CreateButton("Save Position", function()
    print("Position saved!")
end)

local CombatTab = Window:CreateTab("Combat")
CombatTab:CreateToggle("ESP", false, function(state)
    print("ESP:", state)
end)

CombatTab:CreateToggle("Aimbot", false, function(state)
    print("Aimbot:", state)
end)

CombatTab:CreateSlider("FOV", {Min = 30, Max = 800, Default = 200}, function(value)
    print("FOV:", value)
end)

CombatTab:CreateSection("Misc")
CombatTab:CreateButton("Kill All", function()
    print("Killed everyone")
end)

local SettingsTab = Window:CreateTab("Settings")
SettingsTab:CreateLabel("Welcome to Menu")
SettingsTab:CreateInput("Custom Title", "Enter text...", function(text)
    print("New title:", text)
end)
SettingsTab:CreateToggle("Dark Mode", true, function(state)
    print("Dark Mode:", state)
end)

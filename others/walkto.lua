local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local PathLib = {}
PathLib.DebugMode = false
PathLib.GhostMode = false
PathLib.PhantomTransparency = 0.9

local PHANTOM_NAMES = {"hitbox", "barrier", "wall", "zone", "bounds", "collision", "invis", "block", "gate"}

local DEFAULTS = {
    AgentRadius = 2.2,
    AgentHeight = 5,
    AgentCanJump = true,
    WaypointSpacing = 4,
    ReachDistance = 3.5,
    StopDistance = 4,
    DirectWalkDist = 75,
    ClimbForcePath = 6,
    RepathInterval = 1.25,
    ProgressInterval = 0.5,
    ProgressRequired = 0.6,
    StuckJumpTicks = 2,
    StuckStrafeTicks = 3,
    StuckRepathTicks = 4,
    MaxTotalTime = 300,
    CornerCutWindow = 8,
    CornerCutInterval = 0.15,
    Visualize = false,
    OnArrive = nil,
}

local phantoms = {}
local realBlockers = {}
local ghostApplied = {}

local walkers = {}
local hbConn = nil

local function ensureHB()
    if hbConn then return end
    hbConn = RunService.Heartbeat:Connect(function(dt)
        for w in pairs(walkers) do
            local ok, err = pcall(w._update, w, dt)
            if not ok then w:_finish(false, "error: " .. tostring(err)) end
        end
    end)
end

local function stopHB()
    if hbConn and not next(walkers) then
        hbConn:Disconnect()
        hbConn = nil
    end
end

local function nameHint(name)
    local n = string.lower(name)
    for _, k in ipairs(PHANTOM_NAMES) do
        if string.find(n, k, 1, true) then return true end
    end
    return false
end

local function isFloorLike(part)
    if part.CFrame.UpVector.Y > 0.6 then return true end
    return false
end

local function classifyPart(part)
    if not part:IsA("BasePart") then return end
    if not part.CanCollide then return end
    if part.Transparency >= PathLib.PhantomTransparency or nameHint(part.Name) then
        if not isFloorLike(part) then
            phantoms[part] = true
        end
    end
end

function PathLib.Rescan()
    table.clear(phantoms)
    for _, d in ipairs(workspace:GetDescendants()) do
        classifyPart(d)
    end
end

workspace.DescendantAdded:Connect(function(d)
    task.defer(classifyPart, d)
end)

task.spawn(PathLib.Rescan)

local function applyGhost()
    local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local y = hrp and hrp.Position.Y or 0
    for part in pairs(phantoms) do
        if not realBlockers[part] and part.Parent and ghostApplied[part] == nil then
            if not (isFloorLike(part) and part.Position.Y < y - 1) then
                ghostApplied[part] = part.CanCollide
                part.CanCollide = false
            end
        end
    end
end

local function restoreGhost()
    for part, v in pairs(ghostApplied) do
        if part.Parent then part.CanCollide = v end
    end
    table.clear(ghostApplied)
end

local debugFolder = nil
local function dbgFolder()
    if debugFolder and debugFolder.Parent then return debugFolder end
    debugFolder = workspace:FindFirstChild("PathLib_Debug")
    if not debugFolder then
        debugFolder = Instance.new("Folder")
        debugFolder.Name = "PathLib_Debug"
        debugFolder.Parent = workspace
    end
    return debugFolder
end

local function clearDebug()
    local f = debugFolder
    if f and f.Parent then f:ClearAllChildren() end
end

local function makeBall(pos, color, size, shape)
    local m = Instance.new("Part")
    m.Size = Vector3.one * (size or 0.5)
    if shape then m.Shape = shape else m.Shape = Enum.PartType.Ball end
    m.Position = pos
    m.Anchored = true
    m.CanCollide = false
    m.CanQuery = false
    m.CanTouch = false
    m.Material = Enum.Material.Neon
    m.Color = color
    m.Parent = dbgFolder()
    return m
end

local function drawWaypoints(wps)
    clearDebug()
    for i, wp in ipairs(wps) do
        local c = (wp.Action == Enum.PathWaypointAction.Jump)
            and Color3.fromRGB(255, 160, 0)
            or Color3.fromRGB(60, 255, 130)
        makeBall(wp.Position + Vector3.new(0, 0.6, 0), c, 0.5)
    end
end

local function snapToGround(pos, rp)
    local hit = workspace:Raycast(pos + Vector3.new(0, 5, 0), Vector3.new(0, -14, 0), rp)
    if hit and (pos.Y - hit.Position.Y) <= 6 then
        return hit.Position
    end
    return pos
end

local Walker = {}
Walker.__index = Walker

function PathLib.WalkTo(targetPos, opts)
    opts = opts or {}
    local char = Players.LocalPlayer.Character

    local self = setmetatable({}, Walker)
    self.opts = {}
    for k, v in pairs(DEFAULTS) do
        self.opts[k] = (opts[k] ~= nil) and opts[k] or v
    end
    if PathLib.DebugMode then self.opts.Visualize = true end

    self.char = char
    self.rp = RaycastParams.new()
    self.rp.FilterType = Enum.RaycastFilterType.Exclude
    self.rp.RespectCanCollide = true
    self.rp.FilterDescendantsInstances = {char}

    self.path = PathfindingService:CreatePath({
        AgentRadius = self.opts.AgentRadius,
        AgentHeight = self.opts.AgentHeight,
        AgentCanJump = self.opts.AgentCanJump,
        WaypointSpacing = self.opts.WaypointSpacing,
        Costs = { Water = 20 },
    })

    self.mode = "wait"
    self.waypoints = {}
    self.wpIndex = 1
    self.finished = false
    self.computing = false
    self.failRetries = 0
    self.lastCompute = 0
    self.waitTimer = 0
    self.progressTimer = 0
    self.losTimer = 0
    self.cornerTimer = 0
    self.stuckTicks = 0
    self.strafeSide = 1
    self.lastMoveTo = nil
    self.moveTimer = 0
    self.stopTimer = 0

    local hrp = self:_hrp()
    self.startClock = os.clock()
    self.bestDist = hrp and (self.target - hrp.Position).Magnitude or math.huge

    self.target = snapToGround(Vector3.new(targetPos.X, targetPos.Y, targetPos.Z), self.rp)
    self.bestDist = hrp and (self.target - hrp.Position).Magnitude or math.huge

    if PathLib.GhostMode then applyGhost() end

    if hum and hrp then
        local hum2, hrp2 = self:_humanoid(), self:_hrp()
        if hum2 and hrp2 then hum2:MoveTo(hrp2.Position) end
    end

    walkers[self] = true
    ensureHB()
    self:_repath(true)
    return self
end

local hum = nil

function PathLib.StopAll()
    for w in pairs(walkers) do w:_finish(false, "stopAll") end
    restoreGhost()
end

function Walker:SetTarget(pos)
    if self.finished then return end
    local hrp = self:_hrp()
    self.target = snapToGround(Vector3.new(pos.X, pos.Y, pos.Z), self.rp)
    self.bestDist = hrp and (self.target - hrp.Position).Magnitude or math.huge
    self.failRetries = 0
    self.stuckTicks = 0
    local hum, hrp2 = self:_humanoid(), self:_hrp()
    if hum and hrp2 then hum:MoveTo(hrp2.Position) end
    self:_repath(true)
end

function Walker:Cancel()
    self:_finish(false, "cancelled")
end

function Walker:_finish(success, reason)
    if self.finished then return end
    self.finished = true
    walkers[self] = nil
    stopHB()
    local hum, hrp = self:_humanoid(), self:_hrp()
    if hum and hrp then hum:MoveTo(hrp.Position) end
    if self.opts.Visualize and success then
        task.delay(2, clearDebug)
    end
    if self.opts.OnArrive then
        task.spawn(self.opts.OnArrive, success, reason)
    end
end

function Walker:_humanoid()
    local c = self.char
    if not (c and c.Parent) then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not (h and h.Health > 0) then return nil end
    return h
end

function Walker:_hrp()
    local c = self.char
    return c and c:FindFirstChild("HumanoidRootPart")
end

function Walker:_hasLOS(fromPos, toPos)
    local dir = toPos - fromPos
    local dist = dir.Magnitude
    if dist < 0.5 then return true end
    local unit = dir.Unit
    local perp = Vector3.new(-unit.Z, 0, unit.X) * (self.opts.AgentRadius * 0.85)
    local heights = {1.5, 3.2}
    local offsets = {Vector3.zero, perp, -perp}
    for _, h in ipairs(heights) do
        local a = fromPos + Vector3.new(0, h, 0)
        local b = toPos + Vector3.new(0, h, 0)
        for _, o in ipairs(offsets) do
            if workspace:Raycast(a + o, b - a, self.rp) then
                return false
            end
        end
    end
    return true
end

function Walker:_disablePhantoms(hrpY)
    if PathLib.GhostMode then return nil end
    local disabled = {}
    for part in pairs(phantoms) do
        if not realBlockers[part] and part.Parent then
            if not (isFloorLike(part) and part.Position.Y < hrpY - 1) then
                disabled[part] = part.CanCollide
                part.CanCollide = false
            end
        end
    end
    return disabled
end

local function restoreDisabled(disabled)
    if not disabled then return end
    for part, v in pairs(disabled) do
        if part.Parent then part.CanCollide = v end
    end
end

function Walker:_repath(force)
    if self.computing or self.finished then return end
    local now = os.clock()
    if not force and now - self.lastCompute < self.opts.RepathInterval then return end
    self.lastCompute = now
    self.computing = true

    local hrp0 = self:_hrp()
    local disabled = hrp0 and self:_disablePhantoms(hrp0.Position.Y) or nil

    task.spawn(function()
        local hrp = self:_hrp()
        if not hrp or self.finished then
            restoreDisabled(disabled)
            self.computing = false
            return
        end

        local ok = pcall(function()
            self.path:ComputeAsync(hrp.Position, self.target)
        end)
        restoreDisabled(disabled)
        self.computing = false
        if self.finished then return end

        if not ok or self.path.Status ~= Enum.PathStatus.Success or #self.path:GetWaypoints() == 0 then
            if self:_hasLOS(hrp.Position, self.target) then
                self.failRetries = 0
                self.mode = "direct"
                self.waypoints = {}
                if self.opts.Visualize then
                    clearDebug()
                    makeBall(self.target + Vector3.new(0, 1, 0), Color3.fromRGB(255, 255, 255), 0.9)
                end
            else
                self.mode = "wait"
                self.failRetries += 1
            end
        else
            self.failRetries = 0
            self.waypoints = self.path:GetWaypoints()
            self.wpIndex = math.min(2, #self.waypoints)
            self.mode = "path"
            if self.opts.Visualize then
                drawWaypoints(self.waypoints)
                makeBall(self.target + Vector3.new(0, 1, 0), Color3.fromRGB(255, 255, 255), 0.9)
            end
        end
    end)
end

function Walker:_stop()
    local now = os.clock()
    if now - self.stopTimer > 0.4 then
        self.stopTimer = now
        local hum, hrp = self:_humanoid(), self:_hrp()
        if hum and hrp then hum:MoveTo(hrp.Position) end
    end
end

function Walker:_moveTo(pos)
    local now = os.clock()
    if self.lastMoveTo
    and (pos - self.lastMoveTo).Magnitude < 0.6
    and now - self.moveTimer < 5 then
        return
    end
    self.lastMoveTo = pos
    self.moveTimer = now
    local hum = self:_humanoid()
    if hum then hum:MoveTo(pos) end
end

function Walker:_tryCornerCut()
    local hrp = self:_hrp()
    if not hrp then return end
    local wps = self.waypoints
    local maxJ = math.min(self.wpIndex + self.opts.CornerCutWindow, #wps)
    for j = self.wpIndex + 1, maxJ do
        if self:_hasLOS(hrp.Position, wps[j].Position) then
            self.wpIndex = j
            self:_moveTo(wps[j].Position)
        else
            break
        end
    end
end

function Walker:_findBlocker()
    local hrp = self:_hrp()
    if not hrp then return nil end
    local hum = self:_humanoid()
    local fwd = hum and hum.MoveDirection
    if not fwd or fwd.Magnitude < 0.1 then
        fwd = hrp.CFrame.LookVector
    end
    for h = 0.5, 3.5, 0.75 do
        local hit = workspace:Raycast(hrp.Position + Vector3.new(0, h, 0), fwd * 3, self.rp)
        if hit then return hit.Instance end
    end
    return nil
end

function Walker:_progressCheck(dt, hrp)
    local dist = (self.target - hrp.Position).Magnitude
    self.progressTimer += dt
    if self.progressTimer < self.opts.ProgressInterval then return end
    self.progressTimer = 0

    if dist < self.bestDist - self.opts.ProgressRequired then
        self.bestDist = dist
        self.stuckTicks = 0
    else
        self.stuckTicks += 1
        local hum = self:_humanoid()
        if self.stuckTicks == self.opts.StuckJumpTicks then
            if hum then hum.Jump = true end
        elseif self.stuckTicks == self.opts.StuckStrafeTicks then
            if hum then
                local fwd = hum.MoveDirection
                if fwd.Magnitude > 0.1 then
                    self.strafeSide = -self.strafeSide
                    local perp = Vector3.new(-fwd.Z, 0, fwd.X) * self.strafeSide
                    self.lastMoveTo = nil
                    self:_moveTo(hrp.Position + perp * 4)
                end
            end
        elseif self.stuckTicks >= self.opts.StuckRepathTicks then
            self.stuckTicks = 0
            local blocker = self:_findBlocker()
            if blocker and phantoms[blocker] and not realBlockers[blocker] then
                realBlockers[blocker] = true
                if ghostApplied[blocker] ~= nil then
                    if blocker.Parent then blocker.CanCollide = ghostApplied[blocker] end
                    ghostApplied[blocker] = nil
                end
                if self.opts.Visualize then
                    makeBall(blocker.Position, Color3.fromRGB(255, 40, 40), 1.2, Enum.PartType.Block)
                end
            end
            self:_repath(true)
        end
    end
end

function Walker:_update(dt)
    if self.finished then return end
    local hum, hrp = self:_humanoid(), self:_hrp()
    if not (hum and hrp) then return self:_finish(false, "no character") end

    local state = hum:GetState()
    if state == Enum.HumanoidStateType.FallingDown
    or state == Enum.HumanoidStateType.Ragdoll
    or state == Enum.HumanoidStateType.PlatformStanding then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    local pos = hrp.Position
    local dist = (self.target - pos).Magnitude
    if dist <= self.opts.StopDistance then
        return self:_finish(true, "arrived")
    end
    if os.clock() - self.startClock > self.opts.MaxTotalTime then
        return self:_finish(false, "timeout")
    end

    self:_progressCheck(dt, hrp)
    if self.finished then return end

    if self.mode == "wait" then
        self:_stop()
        self.waitTimer += dt
        if self.waitTimer >= self.opts.RepathInterval then
            self.waitTimer = 0
            self:_repath(true)
        end
        return
    end

    if self.mode == "direct" then
        self.losTimer += dt
        if self.losTimer >= 0.35 then
            self.losTimer = 0
            if not self:_hasLOS(pos, self.target) then
                self.mode = "wait"
                self:_stop()
                return self:_repath(true)
            end
        end
        self:_moveTo(Vector3.new(self.target.X, pos.Y, self.target.Z))
        return
    end

    local wps = self.waypoints
    if #wps == 0 then
        self.mode = "wait"
        self:_stop()
        return self:_repath(true)
    end

    if self.wpIndex > #wps then
        if self:_hasLOS(pos, self.target) then
            self:_moveTo(self.target)
        else
            self.mode = "wait"
            self:_stop()
            self:_repath(true)
        end
        return
    end

    local wp = wps[self.wpIndex]
    if (wp.Position - pos).Magnitude <= self.opts.ReachDistance then
        self.wpIndex += 1
        if self.wpIndex <= #wps then
            local nwp = wps[self.wpIndex]
            if nwp.Action == Enum.PathWaypointAction.Jump then
                hum.Jump = true
            end
            self.lastMoveTo = nil
            self:_moveTo(nwp.Position)
        end
        return
    end

    if wp.Action == Enum.PathWaypointAction.Jump
    and (wp.Position - pos).Magnitude <= 6 then
        hum.Jump = true
    end

    self.cornerTimer += dt
    if self.cornerTimer >= self.opts.CornerCutInterval then
        self.cornerTimer = 0
        self:_tryCornerCut()
    end

    local cur = wps[math.min(self.wpIndex, #wps)]
    self:_moveTo(cur.Position)
end
return PathLib

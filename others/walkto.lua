local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local PathLib = {}
PathLib.DebugMode = false
PathLib.GhostMode = false
PathLib.PhantomTransparency = 0.85
PathLib.RescanInterval = 25

local DEFAULTS = {
    AgentRadius = 2.2,
    AgentHeight = 5,
    AgentCanJump = true,
    WaypointSpacing = 4,
    ReachDistance = 3.5,
    StopDistance = 4,
    DirectWalkDist = 75,
    RepathInterval = 1.2,
    StuckInterval = 0.35,
    VelocityStuck = 1.2,
    JumpStuckTicks = 2,
    StrafeStuckTicks = 4,
    RepathStuckTicks = 7,
    SkipAboveTicks = 12,
    MaxTotalTime = 300,
    CornerCutWindow = 5,
    CornerCutInterval = 0.2,
    CornerCutHeight = 3.5,
    WallFollowAngle = 40,
    Visualize = false,
    OnArrive = nil,
}

local phantoms = {}
local disabledNow = {}
local walkersActive = 0

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

local function isFloorLike(part)
    return part.CFrame.UpVector.Y > 0.6
end

local function disablePhantom(part)
    if disabledNow[part] then return end
    disabledNow[part] = part.CanCollide
    part.CanCollide = false
end

local function restorePhantoms()
    for part, v in pairs(disabledNow) do
        if part.Parent then part.CanCollide = v end
    end
    table.clear(disabledNow)
end

local function syncPhantoms()
    if walkersActive <= 0 then
        restorePhantoms()
        return
    end
    if PathLib.GhostMode then
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide and not isFloorLike(d) then
                disablePhantom(d)
            end
        end
    else
        for part in pairs(phantoms) do
            if part.Parent then disablePhantom(part) end
        end
    end
end

local function classifyPart(inst)
    if not inst:IsA("BasePart") then return end
    if not inst.CanCollide then return end
    if isFloorLike(inst) then return end
    local t = inst.Transparency
    local ltm = inst.LocalTransparencyModifier
    if t >= PathLib.PhantomTransparency
    or ltm >= PathLib.PhantomTransparency
    or (not inst.CanQuery and not inst.CanTouch) then
        phantoms[inst] = true
        if walkersActive > 0 then disablePhantom(inst) end
    end
end

function PathLib.Rescan()
    table.clear(phantoms)
    for _, d in ipairs(workspace:GetDescendants()) do
        classifyPart(d)
    end
    syncPhantoms()
end

workspace.DescendantAdded:Connect(function(d)
    task.defer(classifyPart, d)
end)

task.spawn(function()
    PathLib.Rescan()
    while true do
        task.wait(PathLib.RescanInterval)
        PathLib.Rescan()
    end
end)

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
    m.Shape = shape or Enum.PartType.Ball
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
    local hit = workspace:Raycast(pos + Vector3.new(0, 10, 0), Vector3.new(0, -70, 0), rp)
    if hit then
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

    self.mode = "greedy"
    self.waypoints = {}
    self.wpIndex = 1
    self.finished = false
    self.computing = false
    self.lastCompute = 0
    self.repathTimer = 0
    self.losTimer = 0
    self.cornerTimer = 0
    self.blockedTicks = 0
    self.stuckTimer = 0
    self.strafeSide = 1
    self.blockedAngle = 0
    self.lastMoveTo = nil
    self.moveTimer = 0
    self.stopTimer = 0

    local hrp = self:_hrp()
    self.startClock = os.clock()

    self.target = snapToGround(Vector3.new(targetPos.X, targetPos.Y, targetPos.Z), self.rp)
    self.bestDist = hrp and (self.target - hrp.Position).Magnitude or math.huge

    local hum0 = self:_humanoid()
    if hum0 and hrp then
        hum0:MoveTo(hrp.Position)
    end

    walkersActive += 1
    syncPhantoms()

    if self.opts.Visualize then
        makeBall(self.target + Vector3.new(0, 1, 0), Color3.fromRGB(255, 255, 255), 0.9)
    end

    walkers[self] = true
    ensureHB()
    self:_repath(true)
    return self
end

function PathLib.StopAll()
    for w in pairs(walkers) do w:_finish(false, "stopAll") end
end

function Walker:SetTarget(pos)
    if self.finished then return end
    local hrp = self:_hrp()
    self.target = snapToGround(Vector3.new(pos.X, pos.Y, pos.Z), self.rp)
    self.bestDist = hrp and (self.target - hrp.Position).Magnitude or math.huge
    self.blockedTicks = 0
    self.blockedAngle = 0
    local hum, hrp2 = self:_humanoid(), self:_hrp()
    if hum and hrp2 then hum:MoveTo(hrp2.Position) end
    if self.opts.Visualize then
        clearDebug()
        makeBall(self.target + Vector3.new(0, 1, 0), Color3.fromRGB(255, 255, 255), 0.9)
    end
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
    walkersActive = math.max(0, walkersActive - 1)
    if walkersActive == 0 then
        restorePhantoms()
    end
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
    if math.abs(toPos.Y - fromPos.Y) > self.opts.CornerCutHeight * 2 then return false end
    local unit = dir.Unit
    local perp = Vector3.new(-unit.Z, 0, unit.X) * (self.opts.AgentRadius * 0.85)
    local heights = {1.5, 3}
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

function Walker:_repath(force)
    if self.computing or self.finished then return end
    local now = os.clock()
    if not force and now - self.lastCompute < self.opts.RepathInterval then return end
    self.lastCompute = now
    self.computing = true

    task.spawn(function()
        local hrp = self:_hrp()
        if not hrp or self.finished then
            self.computing = false
            return
        end

        local ok = pcall(function()
            self.path:ComputeAsync(hrp.Position, self.target)
        end)
        self.computing = false
        if self.finished then return end

        if ok and self.path.Status == Enum.PathStatus.Success and #self.path:GetWaypoints() > 0 then
            self.waypoints = self.path:GetWaypoints()
            self.wpIndex = math.min(2, #self.waypoints)
            self.mode = "path"
            self.blockedAngle = 0
            if self.opts.Visualize then
                drawWaypoints(self.waypoints)
                makeBall(self.target + Vector3.new(0, 1, 0), Color3.fromRGB(255, 255, 255), 0.9)
            end
        else
            self.waypoints = {}
            if self:_hasLOS(hrp.Position, self.target) then
                self.mode = "direct"
            else
                self.mode = "greedy"
            end
        end
    end)
end

function Walker:_forceMove(pos)
    self.lastMoveTo = nil
    self:_moveTo(pos)
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
        local wp = wps[j]
        if math.abs(wp.Position.Y - hrp.Position.Y) > self.opts.CornerCutHeight then break end
        if self:_hasLOS(hrp.Position, wp.Position) then
            self.wpIndex = j
            self:_moveTo(wp.Position)
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
        if hit and hit.Instance and hit.Instance:IsA("BasePart") then
            return hit.Instance
        end
    end
    return nil
end

function Walker:_learnBlocker()
    local blocker = self:_findBlocker()
    if not blocker or phantoms[blocker] then return end
    if not blocker.CanCollide or isFloorLike(blocker) then return end
    local minDim = math.min(blocker.Size.X, blocker.Size.Y, blocker.Size.Z)
    if blocker.Transparency >= 0.5 or minDim <= 1 then
        phantoms[blocker] = true
        if walkersActive > 0 then disablePhantom(blocker) end
        if self.opts.Visualize then
            makeBall(blocker.Position, Color3.fromRGB(160, 60, 255), 1.2, Enum.PartType.Block)
        end
        self:_repath(true)
    end
end

function Walker:_stuckCheck(hrp, hum)
    self.stuckTimer += 0.35
    if self.stuckTimer < self.opts.StuckInterval then return end
    self.stuckTimer = 0

    local v = hrp.AssemblyLinearVelocity
    local speed = Vector3.new(v.X, 0, v.Z).Magnitude

    if speed > self.opts.VelocityStuck then
        if self.blockedTicks > 0 then self.blockedTicks -= 1 end
        if self.blockedAngle ~= 0 and speed > 3 then
            self.blockedAngle = math.max(0, self.blockedAngle - math.rad(30))
        end
        return
    end

    self.blockedTicks += 1
    if self.blockedTicks == self.opts.JumpStuckTicks then
        hum.Jump = true
    elseif self.blockedTicks == self.opts.StrafeStuckTicks then
        self.strafeSide = -self.strafeSide
        self.blockedAngle = math.rad(self.opts.WallFollowAngle) * self.strafeSide
        local pos = hrp.Position
        local flat = Vector3.new(self.target.X - pos.X, 0, self.target.Z - pos.Z)
        if flat.Magnitude > 0.1 then
            local c, s = math.cos(self.blockedAngle), math.sin(self.blockedAngle)
            local dir = flat.Unit
            dir = Vector3.new(dir.X * c - dir.Z * s, 0, dir.X * s + dir.Z * c)
            self:_forceMove(pos + dir * 5)
        end
    elseif self.blockedTicks >= self.opts.RepathStuckTicks then
        self.blockedTicks = 0
        self:_learnBlocker()
        self:_repath(true)
    end
end

function Walker:_greedyUpdate(hrp, hum)
    local pos = hrp.Position
    local flat = Vector3.new(self.target.X - pos.X, 0, self.target.Z - pos.Z)
    local dist = flat.Magnitude

    if self.target.Y - pos.Y > 2.2 and dist < 10 then
        hum.Jump = true
    end

    local dir
    if dist > 0.1 then
        dir = flat.Unit
        if self.blockedAngle > 0 then
            local c, s = math.cos(self.blockedAngle), math.sin(self.blockedAngle)
            dir = Vector3.new(dir.X * c - dir.Z * s, 0, dir.X * s + dir.Z * c)
        end
    else
        dir = Vector3.zero
    end

    self:_moveTo(pos + dir * 5)
end

function Walker:_directUpdate(hrp, hum)
    local pos = hrp.Position
    self.losTimer += 0.35
    if self.losTimer >= 0.35 then
        self.losTimer = 0
        if not self:_hasLOS(pos, self.target) then
            self.mode = "greedy"
            return self:_repath(true)
        end
    end
    if self.target.Y - pos.Y > 2.2
    and Vector3.new(self.target.X - pos.X, 0, self.target.Z - pos.Z).Magnitude < 10 then
        hum.Jump = true
    end
    self:_moveTo(Vector3.new(self.target.X, pos.Y, self.target.Z))
end

function Walker:_pathUpdate(hrp, hum)
    local pos = hrp.Position
    local wps = self.waypoints

    if #wps == 0 or self.wpIndex > #wps then
        self.mode = "greedy"
        return self:_repath(true)
    end

    local wp = wps[self.wpIndex]
    local diff = wp.Position - pos
    local flatDist = Vector3.new(diff.X, 0, diff.Z).Magnitude

    if flatDist <= self.opts.ReachDistance and math.abs(diff.Y) < 5 then
        self.wpIndex += 1
        if self.wpIndex <= #wps then
            local nwp = wps[self.wpIndex]
            if nwp.Action == Enum.PathWaypointAction.Jump then
                hum.Jump = true
            end
            self:_forceMove(nwp.Position)
        end
        return
    end

    if wp.Position.Y - pos.Y > 6.5 and self.blockedTicks >= self.opts.SkipAboveTicks then
        self.wpIndex += 1
        return
    end

    if wp.Action == Enum.PathWaypointAction.Jump and flatDist <= 7 then
        hum.Jump = true
    end

    self.cornerTimer += 0.35
    if self.cornerTimer >= self.opts.CornerCutInterval then
        self.cornerTimer = 0
        self:_tryCornerCut()
    end

    local cur = wps[math.min(self.wpIndex, #wps)]
    self:_moveTo(cur.Position)
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
    if dist <= self.opts.StopDistance and math.abs(self.target.Y - pos.Y) < 6 then
        return self:_finish(true, "arrived")
    end
    if os.clock() - self.startClock > self.opts.MaxTotalTime then
        return self:_finish(false, "timeout")
    end

    self.repathTimer += dt
    if self.repathTimer >= self.opts.RepathInterval then
        self.repathTimer = 0
        self:_repath(false)
    end

    self:_stuckCheck(hrp, hum)
    if self.finished then return end

    if self.mode == "path" then
        self:_pathUpdate(hrp, hum)
    elseif self.mode == "direct" then
        self:_directUpdate(hrp, hum)
    else
        self:_greedyUpdate(hrp, hum)
    end
end

return PathLib

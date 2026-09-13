local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local PathLib = {}

PathLib.DebugMode = false               
PathLib.GhostMode = false               
PathLib.PhantomTransparency = 0.6       
PathLib.RescanInterval = 20             
PathLib.DisablePlayerCharacters = false 

local DEFAULTS = {
    AgentRadius = 2.2,
    AgentHeight = 5,
    AgentCanJump = true,
    AgentCanClimb = false,
    WaypointSpacing = 4,

    ReachDistance = 3.5,
    StopDistance = 4,
    StopHeight = 6,

    DirectWalkDist = 0,
    RepathInterval = 1.2,
    ComputeTimeout = 4,

    StuckWindow = 0.5,        
    StuckMoveDist = 1.0,      
    VelocityStuck = 1.0,
    JumpStuckTicks = 2,
    StrafeStuckTicks = 4,
    RepathStuckTicks = 7,
    SkipAboveTicks = 12,
    SkipAboveHeight = 6.5,

    NoProgressTime = 8,       
    MissingCharTime = 3,
    MaxTotalTime = 300,

    CornerCutWindow = 0,
    CornerCutInterval = 0.2,
    CornerCutHeight = 3.5,

    WallFollowAngle = 45,
    JumpHeightGain = 2.2,
    LearnBlockerTransparency = 0.5,
    LearnBlockerMinDim = 1,

    Visualize = false,
    OnArrive = nil,
}

local RADIUS_FALLBACK = { 1, 0.7, 0.45 }

local phantoms = {}
local disabledNow = {}
local walkersActive = 0
local walkers = {}
local hbConn = nil
local phantomTimer = 0
local destroyed = false
local descAddedConn = nil
local descRemovingConn = nil
local renderBound = false
local RENDER_NAME = "PathLib_Walker"

local function isFloorLike(part)
    return part.CFrame.UpVector.Y > 0.6
end

local function isPlayerCharacterPart(inst)
    local model = inst:FindFirstAncestorOfClass("Model")
    while model do
        if Players:GetPlayerFromCharacter(model) then return true end
        model = model:FindFirstAncestorOfClass("Model")
    end
    return false
end

local function disablePhantom(part)
    if disabledNow[part] == nil then
        disabledNow[part] = part.CanCollide
    end
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
        local myChar = Players.LocalPlayer and Players.LocalPlayer.Character or nil
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide and not isFloorLike(d) then
                if myChar and d:IsDescendantOf(myChar) then continue end
                if not PathLib.DisablePlayerCharacters and isPlayerCharacterPart(d) then continue end
                disablePhantom(d)
            end
        end
    else
        for part in pairs(phantoms) do
            if part.Parent then disablePhantom(part) end
        end
    end
end

local function reapplyPhantoms()
    if walkersActive <= 0 then return end
    if PathLib.GhostMode then
        syncPhantoms()
    else
        for part, v in pairs(disabledNow) do
            if not phantoms[part] then
                if part.Parent then part.CanCollide = v end
                disabledNow[part] = nil
            end
        end
        for part in pairs(phantoms) do
            if part.Parent and part.CanCollide then
                disablePhantom(part)
            end
        end
    end
end

local function classifyPart(inst)
    if not inst:IsA("BasePart") then return end
    if not inst.CanCollide then return end
    if isFloorLike(inst) then return end

    local myChar = Players.LocalPlayer and Players.LocalPlayer.Character
    if myChar and inst:IsDescendantOf(myChar) then return end
    if not PathLib.DisablePlayerCharacters and isPlayerCharacterPart(inst) then return end

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
    if destroyed then return end
    table.clear(phantoms)
    for _, d in ipairs(workspace:GetDescendants()) do
        classifyPart(d)
    end
    syncPhantoms()
end

descAddedConn = workspace.DescendantAdded:Connect(function(d)
    if destroyed then return end
    task.defer(classifyPart, d)
end)

descRemovingConn = workspace.DescendantRemoving:Connect(function(d)
    phantoms[d] = nil
    disabledNow[d] = nil
end)

task.spawn(function()
    if not destroyed then PathLib.Rescan() end
    while not destroyed do
        task.wait(PathLib.RescanInterval)
        if destroyed then break end
        if walkersActive > 0 or PathLib.GhostMode then
            PathLib.Rescan()
        end
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
    for _, wp in ipairs(wps) do
        local c = (wp.Action == Enum.PathWaypointAction.Jump)
            and Color3.fromRGB(255, 160, 0)
            or Color3.fromRGB(60, 255, 130)
        makeBall(wp.Position + Vector3.new(0, 0.6, 0), c, 0.5)
    end
end

local function makeTargetMarker(pos)
    local m = makeBall(pos + Vector3.new(0, 1, 0), Color3.fromRGB(255, 255, 255), 0.9)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(160, 36)
    bb.StudsOffset = Vector3.new(0, 2.2, 0)
    bb.AlwaysOnTop = true
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.fromScale(1, 1)
    tl.BackgroundTransparency = 1
    tl.Font = Enum.Font.Code
    tl.TextScaled = true
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextStrokeTransparency = 0.3
    tl.Text = "target"
    tl.Parent = bb
    bb.Parent = m
    return m, tl
end

local function snapToGround(pos, rp)
    local casts = {
        { pos + Vector3.new(0, 4, 0), 55 },
        { pos + Vector3.new(0, 25, 0), 110 },
        { pos + Vector3.new(2, 4, 0), 60 },
        { pos + Vector3.new(-2, 4, 0), 60 },
        { pos + Vector3.new(0, 4, 2), 60 },
        { pos + Vector3.new(0, 4, -2), 60 },
    }
    for _, c in ipairs(casts) do
        local hit = workspace:Raycast(c[1], Vector3.new(0, -c[2], 0), rp)
        if hit then return hit.Position end
    end
    return Vector3.new(pos.X, pos.Y, pos.Z)
end

local function stopHB()
    if hbConn and not next(walkers) then
        hbConn:Disconnect()
        hbConn = nil
    end
end

local function ensureHB()
    if hbConn then return end
    phantomTimer = 0
    hbConn = RunService.Heartbeat:Connect(function(dt)
        if walkersActive > 0 then
            phantomTimer += dt
            if phantomTimer >= (PathLib.GhostMode and 3 or 1) then
                phantomTimer = 0
                local ok, err = pcall(reapplyPhantoms)
                if not ok then warn("[PathLib] reapply:", err) end
            end
        end
        if hbConn and not next(walkers) then
            stopHB()
        end
    end)
end

local function ensureRender()
    if renderBound then return end
    renderBound = true
    RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Last.Value, function(dt)
        if destroyed then
            RunService:UnbindFromRenderStep(RENDER_NAME)
            renderBound = false
            return
        end
        for w in pairs(walkers) do
            local ok, err = pcall(w._update, w, math.min(dt, 0.2))
            if not ok then
                warn("[PathLib] update:", err)
                w:_finish(false, "error: " .. tostring(err))
            end
        end
        if not next(walkers) then
            RunService:UnbindFromRenderStep(RENDER_NAME)
            renderBound = false
        end
    end)
end

local Walker = {}
Walker.__index = Walker

function PathLib.WalkTo(targetPos, opts)
    if destroyed then return nil end
    opts = opts or {}
    assert(typeof(targetPos) == "Vector3", "PathLib.WalkTo: targetPos должен быть Vector3")

    local player = opts.Player or Players.LocalPlayer
    local char = player.Character

    local self = setmetatable({}, Walker)
    self.player = player
    self.char = char

    self.opts = {}
    for k, v in pairs(DEFAULTS) do
        self.opts[k] = (opts[k] ~= nil) and opts[k] or v
    end
    if PathLib.DebugMode then self.opts.Visualize = true end

    self.rp = RaycastParams.new()
    self.rp.FilterType = Enum.RaycastFilterType.Exclude
    self.rp.RespectCanCollide = true
    self.rp.IgnoreWater = true
    self.rp.FilterDescendantsInstances = char and { char } or {}

    self.paths = {}
    self.mode = "greedy"
    self.waypoints = {}
    self.wpIndex = 1
    self.finished = false
    self.computing = false
    self.computeSeq = 0
    self.computeStart = 0
    self.repathQueued = false
    self.lastCompute = 0
    self.repathTimer = 0
    self.losTimer = 0
    self.cornerTimer = 0
    self.directTimer = 0
    self.dbgTimer = 0
    self.blockedTicks = 0
    self.stuckAcc = 0
    self.strafeSide = 1
    self.blockedAngle = 0
    self.steerDir = Vector3.zero
    self.moveTimer = 0
    self.lastJump = 0
    self.missingT = 0
    self.frozenT = 0
    self.noProgress = 0
    self.bestWpDist = math.huge
    self.greedyUntil = 0
    self.startClock = os.clock()
    self.dbgText = nil

    walkersActive += 1
    syncPhantoms()

    local hrp = self:_hrp()
    self.lastStuckPos = hrp and hrp.Position or Vector3.zero
    self.target = snapToGround(targetPos, self.rp)
    self.bestDist = hrp
        and Vector3.new(self.target.X - hrp.Position.X, 0, self.target.Z - hrp.Position.Z).Magnitude
        or math.huge

    if self.opts.Visualize then
        local _, label = makeTargetMarker(self.target)
        self.dbgText = label
    end

    walkers[self] = true
    ensureHB()
    ensureRender()
    self:_repath(true)
    return self
end

function PathLib.StopAll()
    for w in pairs(walkers) do
        w:_finish(false, "stopAll")
    end
end

function Walker:_refreshChar()
    local c = self.char
    if c and c.Parent then return c end
    c = self.player and self.player.Character
    if c and c.Parent then
        self.char = c
        self.rp.FilterDescendantsInstances = { c }
        return c
    end
    return nil
end

function Walker:_humanoid()
    local c = self:_refreshChar()
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not (h and h.Health > 0) then return nil end
    return h
end

function Walker:_hrp()
    local c = self:_refreshChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

function Walker:_rotFlat(v, ang)
    local c, s = math.cos(ang), math.sin(ang)
    return Vector3.new(v.X * c - v.Z * s, 0, v.X * s + v.Z * c)
end

function Walker:_steer(dir)
    local hum = self:_humanoid()
    local hrp = self:_hrp()
    if not hum or not hrp then return end
    local flat = Vector3.new(dir.X, 0, dir.Z)
    if flat.Magnitude > 1e-3 then
        if self.blockedAngle ~= 0 then
            flat = self:_rotFlat(flat, self.blockedAngle)
        end
        self.steerDir = flat.Unit
    else
        self.steerDir = Vector3.zero
    end
end

function Walker:_commandMove(_, _)
    local hum = self:_humanoid()
    if not hum then return end
    hum:Move(self.steerDir, false)
end

function Walker:_tryJump()
    local now = os.clock()
    if now - self.lastJump < 0.4 then return end
    local hum = self:_humanoid()
    if not hum then return end
    if hum:GetState() == Enum.HumanoidStateType.Freefall then return end
    self.lastJump = now
    hum.Jump = true
end

function Walker:_rayAhead(dir, dist)
    local hrp = self:_hrp()
    if not hrp then return false end
    for h = 0.75, 3.25, 1.25 do
        local hit = workspace:Raycast(hrp.Position + Vector3.new(0, h, 0), dir * dist, self.rp)
        if hit then return true end
    end
    return false
end

function Walker:_hasLOS(fromPos, toPos)
    local dir = toPos - fromPos
    if dir.Magnitude < 0.5 then return true end
    if math.abs(toPos.Y - fromPos.Y) > self.opts.CornerCutHeight * 2 then return false end
    local unit = dir.Unit
    local perp = Vector3.new(-unit.Z, 0, unit.X) * (self.opts.AgentRadius * 0.85)
    for _, h in ipairs({ 1, 2, 3 }) do
        local a = fromPos + Vector3.new(0, h, 0)
        local b = toPos + Vector3.new(0, h, 0)
        for _, o in ipairs({ Vector3.zero, perp, -perp }) do
            if workspace:Raycast(a + o, b - a, self.rp) then
                return false
            end
        end
    end
    return true
end

function Walker:_corridorClear(fromPos, toPos)
    local flat = Vector3.new(toPos.X - fromPos.X, 0, toPos.Z - fromPos.Z)
    local d = flat.Magnitude
    if d < 2 then return true end
    local n = math.max(2, math.ceil(d / 3.5))
    for i = 0, n do
        local sample = fromPos + flat * (i / n)
        local hit = workspace:Raycast(sample + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), self.rp)
        if not hit then return false end
        if math.abs(hit.Position.Y - fromPos.Y) > 5.5 then return false end
    end
    return true
end

function Walker:_simplifyWaypoints(wps)
    if #wps <= 2 then return wps end
    local out = { wps[1] }
    local i = 2
    while i <= #wps do
        local best = i
        for j = #wps, i + 1, -1 do
            local a = out[#out].Position
            local b = wps[j].Position
            if math.abs(a.Y - b.Y) <= self.opts.CornerCutHeight
            and self:_hasLOS(a, b)
            and self:_corridorClear(a, b) then
                best = j
                break
            end
        end
        out[#out + 1] = wps[best]
        i = best + 1
    end
    return out
end

function Walker:_repath(force)
    if self.finished then return end
    if self.computing then
        self.repathQueued = true
        return
    end
    local now = os.clock()
    if not force then
        if now - self.lastCompute < self.opts.RepathInterval then return end
        if now < self.greedyUntil then return end 
    end
    self.lastCompute = now
    self.computing = true
    self.computeStart = now
    self.computeSeq += 1
    local seq = self.computeSeq
    local target = self.target

    task.spawn(function()
        local hrp = self:_hrp()
        if not hrp or self.finished or seq ~= self.computeSeq then
            if seq == self.computeSeq then self.computing = false end
            return
        end
        local startPos = hrp.Position

        for attempt, scale in ipairs(RADIUS_FALLBACK) do
            if self.finished or seq ~= self.computeSeq then break end

            local path = self.paths[attempt]
            if not path then
                path = PathfindingService:CreatePath({
                    AgentRadius = math.max(0.5, self.opts.AgentRadius * scale),
                    AgentHeight = self.opts.AgentHeight,
                    AgentCanJump = self.opts.AgentCanJump,
                    AgentCanClimb = self.opts.AgentCanClimb,
                    WaypointSpacing = self.opts.WaypointSpacing,
                    Costs = { Water = 20 },
                })
                self.paths[attempt] = path
            end

            local ok = pcall(path.ComputeAsync, path, startPos, target)
            if self.finished or seq ~= self.computeSeq then break end

            if ok and path.Status == Enum.PathStatus.Success then
                local wps = path:GetWaypoints()
                if #wps > 0 then
                    self.waypoints = self:_simplifyWaypoints(wps)
                    self.wpIndex = math.min(2, #self.waypoints)
                    self.mode = "path"
                    self.blockedAngle = 0
                    self.bestWpDist = math.huge
                    self.greedyUntil = 0
                    self.computing = false
                    if self.opts.Visualize then
                        clearDebug()
                        local _, label = makeTargetMarker(self.target)
                        self.dbgText = label
                    end
                    if self.repathQueued then
                        self.repathQueued = false
                        task.defer(function()
                            if not self.finished then self:_repath(true) end
                        end)
                    end
                    return
                end
            end
        end

        if self.finished or seq ~= self.computeSeq then return end
        self.computing = false
        self.waypoints = {}
        self.mode = "greedy"
        if self.repathQueued then
            self.repathQueued = false
            task.defer(function()
                if not self.finished then self:_repath(true) end
            end)
        end
    end)
end

function Walker:_advanceWaypoint()
    self.wpIndex += 1
    self.bestWpDist = math.huge
    local wps = self.waypoints
    if self.wpIndex <= #wps then
        if wps[self.wpIndex].Action == Enum.PathWaypointAction.Jump then
            self:_tryJump()
        end
    end
end

function Walker:_tryCornerCut()
    local hrp = self:_hrp()
    if not hrp then return end
    local wps = self.waypoints
    if #wps == 0 then return end
    local maxJ = math.min(self.wpIndex + self.opts.CornerCutWindow, #wps)
    for j = self.wpIndex + 1, maxJ do
        local wp = wps[j]
        if math.abs(wp.Position.Y - hrp.Position.Y) > self.opts.CornerCutHeight then break end
        if self:_hasLOS(hrp.Position, wp.Position) then
            self.wpIndex = j
            self.bestWpDist = math.huge
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
    fwd = Vector3.new(fwd.X, 0, fwd.Z)
    if fwd.Magnitude < 0.1 then return nil end
    fwd = fwd.Unit
    for h = 0.5, 3.5, 0.75 do
        local hit = workspace:Raycast(hrp.Position + Vector3.new(0, h, 0), fwd * 3.5, self.rp)
        if hit and hit.Instance and hit.Instance:IsA("BasePart") then
            return hit.Instance
        end
    end
    return nil
end

function Walker:_learnBlocker()
    local blocker = self:_findBlocker()
    if not blocker or phantoms[blocker] then return false end
    if isFloorLike(blocker) then return false end
    local myChar = Players.LocalPlayer and Players.LocalPlayer.Character
    if myChar and blocker:IsDescendantOf(myChar) then return false end
    if not PathLib.DisablePlayerCharacters and isPlayerCharacterPart(blocker) then return false end

    local minDim = math.min(blocker.Size.X, blocker.Size.Y, blocker.Size.Z)
    if blocker.Transparency >= self.opts.LearnBlockerTransparency
    or minDim <= self.opts.LearnBlockerMinDim
    or not blocker.CanQuery then
        phantoms[blocker] = true
        if walkersActive > 0 then disablePhantom(blocker) end
        return true
    end
    return false
end

function Walker:_hardReset()
    self.blockedTicks = 0
    self.noProgress = 0
    self.bestDist = math.huge
    local learned = self:_learnBlocker()
    self.mode = "greedy"
    if learned then
        self.greedyUntil = 0
        self:_repath(true)
    else
        self.greedyUntil = os.clock() + 6 
    end
end

function Walker:_stuckCheck(hrp, hum, dt)
    self.stuckAcc += dt
    if self.stuckAcc < self.opts.StuckWindow then return end
    self.stuckAcc = 0

    local pos = hrp.Position
    local moved = (Vector3.new(pos.X, 0, pos.Z)
        - Vector3.new(self.lastStuckPos.X, 0, self.lastStuckPos.Z)).Magnitude
    self.lastStuckPos = pos

    local v = hrp.AssemblyLinearVelocity
    local speed = Vector3.new(v.X, 0, v.Z).Magnitude

    if moved >= self.opts.StuckMoveDist and speed > self.opts.VelocityStuck then
        if self.blockedTicks > 0 then self.blockedTicks -= 1 end
        if self.blockedAngle ~= 0 and speed > 3 then
            if self.blockedAngle > 0 then
                self.blockedAngle = math.max(0, self.blockedAngle - math.rad(30))
            else
                self.blockedAngle = math.min(0, self.blockedAngle + math.rad(30))
            end
        end
        return
    end

    if hum:GetState() == Enum.HumanoidStateType.Freefall then return end

    self.blockedTicks += 1
    if self.blockedTicks == self.opts.JumpStuckTicks then
        self:_tryJump()
    elseif self.blockedTicks == self.opts.StrafeStuckTicks then
        self.strafeSide = -self.strafeSide
        self.blockedAngle = math.rad(self.opts.WallFollowAngle) * self.strafeSide
    elseif self.blockedTicks >= self.opts.RepathStuckTicks then
        self:_hardReset()
    end
end

function Walker:_greedyUpdate(hrp, hum, dt)
    local pos = hrp.Position
    local tdiff = self.target - pos
    local flat = Vector3.new(tdiff.X, 0, tdiff.Z)
    local dist = flat.Magnitude

    if tdiff.Y > self.opts.JumpHeightGain and dist < 10 then
        self:_tryJump()
    end

    local v = hrp.AssemblyLinearVelocity
    local speed = Vector3.new(v.X, 0, v.Z).Magnitude

    if self.blockedAngle ~= 0 then
        
        if dist > 0.1 and speed > 2.5 and not self:_rayAhead(flat.Unit, 3.5) then
            self.blockedAngle = 0
        end
    elseif dist > 0.1 and self:_rayAhead(flat.Unit, 4) then
        
        local lClear = not self:_rayAhead(self:_rotFlat(flat.Unit, math.rad(55)), 5)
        local rClear = not self:_rayAhead(self:_rotFlat(flat.Unit, -math.rad(55)), 5)
        if lClear and not rClear then
            self.strafeSide = 1
        elseif rClear and not lClear then
            self.strafeSide = -1
        elseif (not lClear) and (not rClear) then
            self.strafeSide = -self.strafeSide
        end
        self.blockedAngle = math.rad(self.opts.WallFollowAngle) * self.strafeSide
    end

    if dist > 0.1 then
        self:_steer(flat.Unit)
        self:_commandMove(pos + self.steerDir * 12, dt)
    else
        self:_steer(Vector3.zero)
        self:_commandMove(pos, dt)
    end
end

function Walker:_directUpdate(hrp, hum, dt)
    local pos = hrp.Position
    self.losTimer += dt
    if self.losTimer >= 0.4 then
        self.losTimer = 0
        if not self:_hasLOS(pos, self.target) or not self:_corridorClear(pos, self.target) then
            self.mode = "greedy"
            self:_repath(true)
            return
        end
    end
    local tdiff = self.target - pos
    local flat = Vector3.new(tdiff.X, 0, tdiff.Z)
    if tdiff.Y > self.opts.JumpHeightGain and flat.Magnitude < 10 then
        self:_tryJump()
    end
    if flat.Magnitude > 0.1 then
        self:_steer(flat.Unit)
        self:_commandMove(self.target, dt)
    else
        self:_steer(Vector3.zero)
        self:_commandMove(pos, dt)
    end
end

function Walker:_pathUpdate(hrp, hum, dt)
    local pos = hrp.Position
    local wps = self.waypoints

    if #wps == 0 or self.wpIndex > #wps then
        self.mode = "greedy"
        self:_repath(true)
        return
    end

    local wp = wps[self.wpIndex]
    local diff = wp.Position - pos
    local flatDiff = Vector3.new(diff.X, 0, diff.Z)
    local flatDist = flatDiff.Magnitude

    if flatDist <= self.opts.ReachDistance and math.abs(diff.Y) < 5 then
        self:_advanceWaypoint()
        return
    end



    if (wp.Position.Y - pos.Y) > self.opts.SkipAboveHeight
    and self.blockedTicks >= self.opts.SkipAboveTicks then
        self:_advanceWaypoint()
        return
    end

    if wp.Action == Enum.PathWaypointAction.Jump and flatDist <= 7 then
        self:_tryJump()
    end

    self.cornerTimer += dt
    if self.cornerTimer >= self.opts.CornerCutInterval then
        self.cornerTimer = 0
        self:_tryCornerCut()
    end

    self.directTimer += dt
    if self.directTimer >= 0.5 then
        self.directTimer = 0
        if flatDist > self.bestWpDist + 8 then
            self.bestWpDist = flatDist
            self:_repath(true)
            return
        end
        self.bestWpDist = math.min(self.bestWpDist, flatDist)
    end

    if flatDist > 0.1 then
        self:_steer(flatDiff.Unit)
        self:_commandMove(wp.Position, dt)
    else
        self:_steer(Vector3.zero)
        self:_commandMove(pos, dt)
    end
end

function Walker:_update(dt)
    if self.finished then return end
    dt = math.min(dt, 0.2)

    local hum, hrp = self:_humanoid(), self:_hrp()
    if not (hum and hrp) then
        self.missingT += dt
        if self.missingT > self.opts.MissingCharTime then
            self:_finish(false, "no character")
        end
        return
    end
    self.missingT = 0

    if hum.WalkSpeed <= 0.05 then
        self.frozenT += dt
        if self.frozenT > 5 then
            return self:_finish(false, "walkspeed 0")
        end
    else
        self.frozenT = 0
    end

    local state = hum:GetState()
    if state == Enum.HumanoidStateType.FallingDown
    or state == Enum.HumanoidStateType.Ragdoll
    or state == Enum.HumanoidStateType.PlatformStanding then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    elseif state == Enum.HumanoidStateType.Seated then
        hum.Sit = false
    end

    if self.computing and os.clock() - self.computeStart > self.opts.ComputeTimeout then
        self.computeSeq += 1
        self.computing = false
    end

    local pos = hrp.Position
    local tdiff = self.target - pos
    local flatDist = Vector3.new(tdiff.X, 0, tdiff.Z).Magnitude

    if flatDist <= self.opts.StopDistance and math.abs(tdiff.Y) <= self.opts.StopHeight then
        return self:_finish(true, "arrived")
    end
    if os.clock() - self.startClock > self.opts.MaxTotalTime then
        return self:_finish(false, "timeout")
    end

    if flatDist < self.bestDist - 0.5 then
        self.bestDist = flatDist
        self.noProgress = 0
    else
        self.noProgress += dt
        if self.noProgress >= self.opts.NoProgressTime then
            self:_hardReset()
        end
    end

    self.repathTimer += dt
    if self.repathTimer >= self.opts.RepathInterval then
        self.repathTimer = 0
        self:_repath(false)
    end

    self:_stuckCheck(hrp, hum, dt)
    if self.finished then return end

    if self.mode == "path" then
        self:_pathUpdate(hrp, hum, dt)
    else
        self:_greedyUpdate(hrp, hum, dt)
    end

    if self.opts.Visualize then
        self.dbgTimer += dt
        if self.dbgTimer >= 0.25 then
            self.dbgTimer = 0
            if self.dbgText and self.dbgText.Parent then
                self.dbgText.Text = string.format("%s · %.0fm", self.mode, flatDist)
            end
        end
    end
end

function Walker:_finish(success, reason)
    if self.finished then return end
    self.finished = true
    self.lastSuccess = success
    self.lastReason = reason
    self.computeSeq += 1
    self.computing = false

    walkers[self] = nil
    walkersActive = math.max(0, walkersActive - 1)

    local hum, hrp = self:_humanoid(), self:_hrp()
    if hum and hrp then
        hum:MoveTo(hrp.Position)
    end

    if walkersActive == 0 then
        restorePhantoms()
    end
    stopHB()

    if self.opts.Visualize and success then
        task.delay(2, clearDebug)
    end

    if self.opts.OnArrive then
        task.spawn(self.opts.OnArrive, success, reason)
    end
end

function Walker:SetTarget(pos)
    if self.finished then return end
    assert(typeof(pos) == "Vector3", "SetTarget: pos должен быть Vector3")
    self.target = snapToGround(pos, self.rp)
    local hrp = self:_hrp()
    self.bestDist = hrp
        and Vector3.new(self.target.X - hrp.Position.X, 0, self.target.Z - hrp.Position.Z).Magnitude
        or math.huge
    self.bestWpDist = math.huge
    self.blockedTicks = 0
    self.blockedAngle = 0
    self.noProgress = 0
    self.losTimer = 0
    self.cornerTimer = 0
    self.directTimer = 0
    self.moveTimer = 0
    self.greedyUntil = 0
    if self.opts.Visualize then
        clearDebug()
        local _, label = makeTargetMarker(self.target)
        self.dbgText = label
    end
    self:_repath(true)
end

function Walker:Cancel()
    self:_finish(false, "cancelled")
end

function Walker:Wait()
    while not self.finished do
        task.wait(0.05)
    end
    return self.lastSuccess, self.lastReason
end

function PathLib.Shutdown()
    if destroyed then return end
    destroyed = true
    PathLib.StopAll()
    if hbConn then
        hbConn:Disconnect()
        hbConn = nil
    end
    RunService:UnbindFromRenderStep(RENDER_NAME)
    renderBound = false
    if descAddedConn then
        descAddedConn:Disconnect()
        descAddedConn = nil
    end
    if descRemovingConn then
        descRemovingConn:Disconnect()
        descRemovingConn = nil
    end
    restorePhantoms()
    clearDebug()
end

return PathLib

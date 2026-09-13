local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Debris             = game:GetService("Debris")

local PathLib = {}
PathLib.DebugMode = false

local DEFAULTS = {
    AgentRadius       = 2.5,
    AgentHeight       = 5,
    AgentCanJump      = true,
    AgentCanClimb     = true,
    WaypointSpacing   = 4,
    ReachDistance     = 3.5,
    StopDistance      = 4,
    DirectWalkDist    = 150,
    RepathInterval    = 1.5,
    StuckJumpTicks    = 2,
    StuckRepathTicks  = 4,
    MaxRepaths        = 5,
    CornerCutWindow   = 6,
    RepathFailRetries = 3,
    Visualize         = false,
    OnArrive          = nil,
}


local function makeRP()
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.RespectCanCollide = true
    rp.IgnoreWater = false
    return rp
end


local walkers = {}
local hbConn = nil

local function ensureHeartbeat()
    if hbConn then return end
    hbConn = RunService.Heartbeat:Connect(function(dt)
        for w in pairs(walkers) do
            local ok, err = pcall(w._update, w, dt)
            if not ok then w:_finish(false, "error: " .. tostring(err)) end
        end
    end)
end

local function stopHeartbeat()
    if hbConn and not next(walkers) then
        hbConn:Disconnect()
        hbConn = nil
    end
end


local debugFolder = nil
local function getDebugFolder()
    if debugFolder and debugFolder.Parent then return debugFolder end
    debugFolder = workspace:FindFirstChild("PathLib_Debug")
    if not debugFolder then
        debugFolder = Instance.new("Folder")
        debugFolder.Name = "PathLib_Debug"
        debugFolder.Parent = workspace
    end
    return debugFolder
end

local function drawPath(waypoints)
    local folder = getDebugFolder()
    for _, c in ipairs(folder:GetChildren()) do c:Destroy() end
    for i, wp in ipairs(waypoints) do
        local m = Instance.new("Part")
        m.Size = Vector3.new(0.45, 0.45, 0.45)
        m.Shape = Enum.PartType.Ball
        m.Position = wp.Position + Vector3.new(0, 0.5, 0)
        m.Anchored, m.CanCollide, m.CanQuery, m.CanTouch = true, false, false, false
        m.Material = Enum.Material.Neon
        m.Color = (wp.Action == Enum.PathWaypointAction.Jump)
            and Color3.fromRGB(255, 170, 0)
            or  Color3.fromRGB(60, 255, 130)
        m.Name = "WP" .. i
        m.Parent = folder
    end
end

local function clearDebug()
    if debugFolder and debugFolder.Parent then
        for _, c in ipairs(debugFolder:GetChildren()) do c:Destroy() end
    end
end


local Walker = {}
Walker.__index = Walker

function PathLib.WalkTo(targetPos, opts)
    opts = opts or {}
    local player = Players.LocalPlayer
    local char = player.Character

    local self = setmetatable({}, Walker)
    self.target = Vector3.new(targetPos.X, targetPos.Y, targetPos.Z)
    self.opts = {}
    for k, v in pairs(DEFAULTS) do self.opts[k] = (opts[k] ~= nil) and opts[k] or v end
    if PathLib.DebugMode then self.opts.Visualize = true end

    self.char = char
    self.hum = char and char:FindFirstChildOfClass("Humanoid")
    self.hrp = char and char:FindFirstChild("HumanoidRootPart")
    self.rp = makeRP()
    self.rp.FilterDescendantsInstances = {char}

    self.path = PathfindingService:CreatePath({
        AgentRadius = self.opts.AgentRadius,
        AgentHeight = self.opts.AgentHeight,
        AgentCanJump = self.opts.AgentCanJump,
        AgentCanClimb = self.opts.AgentCanClimb,
        WaypointSpacing = self.opts.WaypointSpacing,
        Costs = { Water = 20 },
    })

    self.mode = "path"
    self.waypoints = {}
    self.wpIndex = 1
    self.finished = false
    self.repathCount = 0
    self.failRetries = 0
    self._moveTimer = 0
    self._lastMoveTo = nil
    self._repathTimer = 0
    self._losTimer = 0
    self._stuckTicks = 0
    self._stuckTimer = 0
    self._lastPos = self.hrp and self.hrp.Position or Vector3.zero

    walkers[self] = true
    ensureHeartbeat()
    self:_chooseMode(true)
    return self
end

function PathLib.StopAll()
    for w in pairs(walkers) do w:_finish(false, "stopAll") end
end


function Walker:SetTarget(pos)
    if self.finished then return end
    self.target = Vector3.new(pos.X, pos.Y, pos.Z)
    self.repathCount = 0
    self.failRetries = 0
    self._repathTimer = self.opts.RepathInterval
    self:_chooseMode(false)
end

function Walker:Cancel()
    self:_finish(false, "cancelled")
end


function Walker:_finish(success, reason)
    if self.finished then return end
    self.finished = true
    walkers[self] = nil
    stopHeartbeat()
    local hum = self:_humanoid()
    if hum then
        local hrp = self:_hrp()
        if hrp then hum:MoveTo(hrp.Position) end
    end
    if self.opts.Visualize and success then task.delay(2, clearDebug) end
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
    local perp = Vector3.new(-unit.Z, 0, unit.X) * (self.opts.AgentRadius * 0.7)
    local a = fromPos + Vector3.new(0, 2, 0)
    local b = toPos + Vector3.new(0, 2, 0)
    for _, offset in ipairs({Vector3.zero, perp, -perp}) do
        local hit = workspace:Raycast(a + offset, b - a, self.rp)
        if hit then return false end
    end
    return true
end


function Walker:_chooseMode(initial)
    local hrp = self:_hrp()
    if not hrp then return self:_finish(false, "no character") end
    local dist = (self.target - hrp.Position).Magnitude

    if dist <= self.opts.StopDistance then
        return self:_finish(true, "arrived")
    end

    if dist <= self.opts.DirectWalkDist and self:_hasLOS(hrp.Position, self.target) then
        self.mode = "direct"
        self.waypoints = {}
        if self.opts.Visualize then clearDebug() end
    else
        self.mode = "path"
        self:_computePath()
    end
end


function Walker:_computePath()
    local hrp = self:_hrp()
    if not hrp then return self:_finish(false, "no character") end

    local ok, err = pcall(function()
        self.path:ComputeAsync(hrp.Position, self.target)
    end)
    if not ok then return self:_retryOrFail("path error") end

    local status = self.path.Status
    if status == Enum.PathStatus.NoPath then

        if self:_hasLOS(hrp.Position, self.target) then
            self.mode = "direct"
            return
        end
        return self:_retryOrFail("no path")
    end

    self.waypoints = self.path:GetWaypoints()

    self.wpIndex = (#self.waypoints > 1) and 2 or 1
    self.failRetries = 0
    self._repathTimer = 0

    if self.opts.Visualize then drawPath(self.waypoints) end
end

function Walker:_retryOrFail(reason)
    self.failRetries += 1
    if self.failRetries > self.opts.RepathFailRetries then
        self:_finish(false, reason)
    else
        task.wait(0.3)
        self:_computePath()
    end
end


function Walker:_moveTo(pos)
    local now = os.clock()
    if self._lastMoveTo
    and (pos - self._lastMoveTo).Magnitude < 0.6
    and now - self._moveTimer < 6 then
        return
    end
    self._lastMoveTo = pos
    self._moveTimer = now
    local hum = self:_humanoid()
    if hum then hum:MoveTo(Vector3.new(pos.X, pos.Y, pos.Z)) end
end


function Walker:_tryCornerCut()
    local hrp = self:_hrp()
    if not hrp then return end
    local wps = self.waypoints
    local best = nil
    local maxJ = math.min(self.wpIndex + self.opts.CornerCutWindow, #wps)
    for j = maxJ, self.wpIndex + 1, -1 do
        if self:_hasLOS(hrp.Position, wps[j].Position) then
            best = j
            break
        end
    end
    if best then
        local changed = best ~= self.wpIndex
        self.wpIndex = best
        if changed then self:_moveTo(wps[best].Position) end
    end
end


function Walker:_stuckCheck(dt)
    local hrp = self:_hrp()
    if not hrp then return end
    self._stuckTimer += dt
    if self._stuckTimer < 0.4 then return end
    self._stuckTimer = 0

    local moved = (hrp.Position - self._lastPos).Magnitude
    self._lastPos = hrp.Position

    if moved < 0.35 then
        self._stuckTicks += 1
        if self._stuckTicks >= self.opts.StuckRepathTicks then
            self._stuckTicks = 0
            self.repathCount += 1
            if self.repathCount > self.opts.MaxRepaths then
                return self:_finish(false, "stuck permanently")
            end
            if self.mode == "direct" then
                self:_chooseMode(false)
            else
                self:_computePath()
            end
        elseif self._stuckTicks >= self.opts.StuckJumpTicks then
            local hum = self:_humanoid()
            if hum then hum.Jump = true end
        end
    else
        self._stuckTicks = math.max(0, self._stuckTicks - 1)
    end
end


function Walker:_update(dt)
    if self.finished then return end
    local hum, hrp = self:_humanoid(), self:_hrp()
    if not (hum and hrp) then return self:_finish(false, "no character") end


    local state = hum:GetState()
    if state == Enum.HumanoidStateType.FallingDown
    or state == Enum.HumanoidStateType.PlatformStanding then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    local dist = (self.target - hrp.Position).Magnitude
    if dist <= self.opts.StopDistance then
        return self:_finish(true, "arrived")
    end


    self._repathTimer += dt
    if self.mode == "path" and self._repathTimer >= self.opts.RepathInterval then
        self._repathTimer = 0
        self:_computePath()
        return
    end

    self:_stuckCheck(dt)
    if self.finished then return end

    if self.mode == "direct" then

        self._losTimer += dt
        if self._losTimer >= 0.4 then
            self._losTimer = 0
            if not self:_hasLOS(hrp.Position, self.target) then
                self.mode = "path"
                return self:_computePath()
            end
        end

        self:_moveTo(Vector3.new(self.target.X, hrp.Position.Y, self.target.Z))
    else

        local wps = self.waypoints
        if #wps == 0 then return self:_chooseMode(false) end

        if self.wpIndex > #wps then

            if self:_hasLOS(hrp.Position, self.target) then
                self:_moveTo(self.target)
            else
                self:_chooseMode(false)
            end
            return
        end

        local wp = wps[self.wpIndex]

        if (wp.Position - hrp.Position).Magnitude <= self.opts.ReachDistance then
            self.wpIndex += 1
            if self.wpIndex <= #wps then
                local nwp = wps[self.wpIndex]
                if nwp.Action == Enum.PathWaypointAction.Jump then
                    hum.Jump = true
                end
                self._lastMoveTo = nil
                self:_moveTo(nwp.Position)
            end
            return
        end


        if wp.Action == Enum.PathWaypointAction.Jump
        and (wp.Position - hrp.Position).Magnitude <= 6 then
            hum.Jump = true
        end

        self:_tryCornerCut()
        local cur = wps[math.min(self.wpIndex, #wps)]
        self:_moveTo(cur.Position)
    end
end

return PathLib

--[[
    ╔══════════════════════════════════════════╗
    ║       ADRIAN RIVALS CHEAT v1.3           ║
    ║       Developer: MR Adrian               ║
    ║       URL Whitelist + Full Debug         ║
    ╚══════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════
--  ⚙️ WHITELIST URLS - اینجا URL پروفایل بذار
-- ═══════════════════════════════════════════════

local WHITELIST_URLS = {
    "https://www.roblox.com/users/11190031157/profile",
    "https://www.roblox.com/users/8445116028/profile",
    "https://www.roblox.com/users/6021189744/profile",
}

-- ═══════════════════════════════════════════════
--  PARSE
-- ═══════════════════════════════════════════════

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local myUserId = LocalPlayer.UserId

local WHITELIST = {}
for _, url in ipairs(WHITELIST_URLS) do
    local id = tonumber(url:match("users/(%d+)")) or tonumber(url:match("(%d+)"))
    if id then WHITELIST[id] = true end
end

-- ═══════════════════════════════════════════════
--  SAFE UI (works on ALL executors)
-- ═══════════════════════════════════════════════

local function createSafeUI(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 9999

    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then
        pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) end)
    end
    return gui
end

-- ═══════════════════════════════════════════════
--  ❌ NOT WHITELISTED
-- ═══════════════════════════════════════════════

if not WHITELIST[myUserId] then
    task.spawn(function()
        local gui = createSafeUI("AdrianError")
        if not gui then return end

        local popup = Instance.new("Frame")
        popup.Size = UDim2.new(0, 340, 0, 190)
        popup.Position = UDim2.new(0.5, -170, 0.5, -95)
        popup.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
        popup.BorderSizePixel = 0
        popup.Parent = gui

        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = popup
        local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(220, 50, 50); s.Thickness = 2; s.Parent = popup

        local function label(size, pos, text, color, sizeNum, font)
            local l = Instance.new("TextLabel")
            l.Size = size; l.Position = pos; l.BackgroundTransparency = 1
            l.Text = text; l.TextColor3 = color; l.TextSize = sizeNum; l.Font = font
            l.Parent = popup
            return l
        end

        label(UDim2.new(1,0,0,40), UDim2.new(0,0,0,18), "❌", Color3.new(1,1,1), 32, Enum.Font.GothamBold)
        label(UDim2.new(1,0,0,26), UDim2.new(0,0,0,65), "URL SET NIST SIKTIR", Color3.fromRGB(255,80,80), 18, Enum.Font.GothamBold)
        label(UDim2.new(1,-20,0,18), UDim2.new(0,10,0,98), "شما مجاز به استفاده نیستید", Color3.fromRGB(180,180,200), 12, Enum.Font.Gotham)
        label(UDim2.new(1,-20,0,16), UDim2.new(0,10,0,125), "Name: " .. LocalPlayer.Name .. " | ID: " .. myUserId, Color3.fromRGB(130,130,150), 11, Enum.Font.Code)
        label(UDim2.new(1,-20,0,16), UDim2.new(0,10,0,155), "Contact MR Adrian", Color3.fromRGB(147,51,234), 11, Enum.Font.Gotham)

        task.delay(6, function() pcall(function() gui:Destroy() end) end)
    end)
    return
end

-- ═══════════════════════════════════════════════
--  ✅ WHITELISTED - FULL CHEAT
-- ═══════════════════════════════════════════════

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local Camera = Workspace.CurrentCamera

-- SETTINGS
local Settings = {
    Aimbot = {Enabled=false, FOV=150, TargetPart="Head", TeamCheck=false, ShowFOV=true, AimKey=Enum.UserInputType.MouseButton2, Prediction=0.12, Method="Mouse", Smoothness=2.5, AimBehindWall=true, HighlightTarget=true},
    GodMode = {Enabled=false},
    TriggerBot = {Enabled=false, Delay=0.15, TeamCheck=true, CheckWalls=false, Range=500},
    ESP = {Enabled=false, Boxes=true, BoxColor=Color3.fromRGB(147,51,234), BoxType="Corner", Names=true, Health=true, HealthType="Left", Distance=true, Tracers=false, TracerOrigin="Bottom", TracerColor=Color3.fromRGB(147,51,234), TeamCheck=false, MaxDistance=2000, BoxThickness=1.5, TextSize=13, Chams=false, ChamsColor=Color3.fromRGB(147,51,234), ChamsTransparency=0.5, ToolESP=false},
    Visuals = {Fullbright=false, NoFog=false, Crosshair=false, CrosshairSize=8, CrosshairColor=Color3.fromRGB(147,51,234), CrosshairGap=4},
    Misc = {InfiniteJump=false, NoClip=false, Fly=false, FlySpeed=50, AntiAFK=false, SpeedEnabled=false, SpeedValue=16, JumpEnabled=false, JumpValue=50}
}

-- STATE
local uiVisible = true
local aiming = false
local espObjects = {}
local connections = {}
local currentTarget = nil
local lastTrigger = 0
local godModeConn = nil
local infJumpConn, noclipConn, flyConn = nil, nil, nil
local bodyVelocity, bodyGyro = nil, nil
local flying = false

-- UTILITY
local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local function getCharacter(player)
    if not player or player == LocalPlayer then return nil end
    local ok, char = pcall(function() return player.Character end)
    if not ok or not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not root then return nil end
    return char, humanoid, root
end

local function getTargetPart(char, partName)
    local fallbacks = {
        ["Head"] = {"Head","UpperTorso","Torso","HumanoidRootPart"},
        ["HumanoidRootPart"] = {"HumanoidRootPart","UpperTorso","Torso","Head"},
        ["UpperTorso"] = {"UpperTorso","Torso","HumanoidRootPart"},
        ["Torso"] = {"Torso","UpperTorso","HumanoidRootPart"},
    }
    for _, n in ipairs(fallbacks[partName] or {"Head","HumanoidRootPart"}) do
        local p = char:FindFirstChild(n)
        if p then return p end
    end
    return nil
end

local function isWallBetween(targetPart, targetChar)
    local myChar = LocalPlayer.Character
    if not myChar then return true end
    local myHead = myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart")
    if not myHead then return true end
    local ok, result = pcall(function()
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {myChar, targetChar, Camera}
        return Workspace:Raycast(myHead.Position, targetPart.Position - myHead.Position, rp)
    end)
    if ok and result then return not result.Instance:IsDescendantOf(targetChar) end
    return false
end

local function getVelocity(char)
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    if root then
        local ok, vel = pcall(function() return root.AssemblyLinearVelocity end)
        if ok then return vel end
    end
    return Vector3.new(0,0,0)
end

-- ═══ GOD MODE ═══
local function applyGodMode()
    if godModeConn then godModeConn:Disconnect() godModeConn = nil end
    if Settings.GodMode.Enabled then
        godModeConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local h = char:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then
                        h.MaxHealth = math.huge
                        h.Health = math.huge
                    end
                end
            end)
        end)
    else
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local h = char:FindFirstChildOfClass("Humanoid")
                if h then h.MaxHealth = 100 h.Health = 100 end
            end
        end)
    end
end

-- ═══ TRIGGER BOT ═══
local function getTriggerTarget()
    local ok, unitRay = pcall(function()
        local mp = UserInputService:GetMouseLocation()
        return Camera:ViewportPointToRay(mp.X, mp.Y)
    end)
    if not ok or not unitRay then return nil end

    local ok2, result = pcall(function()
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        return Workspace:Raycast(unitRay.Origin, unitRay.Direction * Settings.TriggerBot.Range, rp)
    end)
    if not ok2 or not result then return nil end

    local char = result.Instance.Parent
    while char and not char:FindFirstChildOfClass("Humanoid") do
        char = char.Parent
    end
    if not char then return nil end

    local player = Players:GetPlayerFromCharacter(char)
    if not player or player == LocalPlayer then return nil end

    if Settings.TriggerBot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return nil
    end

    if Settings.TriggerBot.CheckWalls then
        local head = getTargetPart(char, "Head")
        if head and isWallBetween(head, char) then return nil end
    end

    return player, char
end

local function doShoot()
    pcall(function() mouse1click() end)
end

-- ═══ AIMBOT ═══
local fovCircle = Drawing and Drawing.new("Circle") or nil
if fovCircle then
    fovCircle.Thickness = 1.5
    fovCircle.Filled = false
    fovCircle.Color = Color3.fromRGB(147,51,234)
    fovCircle.Visible = false
    fovCircle.Radius = 150
    fovCircle.NumSides = 100
end

local targetHighlight = Instance.new("Highlight")
targetHighlight.FillColor = Color3.fromRGB(147,51,234)
targetHighlight.FillTransparency = 0.75
targetHighlight.OutlineColor = Color3.fromRGB(200,120,255)
targetHighlight.OutlineTransparency = 0
targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
targetHighlight.Enabled = false
targetHighlight.Parent = createSafeUI("AdrianHl") or game:GetService("CoreGui")

local function getBestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local mouseVec = Vector2.new(mousePos.X, mousePos.Y)
    local closest, closestDist = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not (Settings.Aimbot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team) then
                local char, humanoid, rootPart = getCharacter(player)
                if char then
                    local tp = getTargetPart(char, Settings.Aimbot.TargetPart)
                    if tp then
                        if Settings.Aimbot.AimBehindWall or not isWallBetween(tp, char) then
                            local ok, sp = pcall(function() return Camera:WorldToViewportPoint(tp.Position) end)
                            if ok and sp and sp.Z > 0 then
                                local d = (Vector2.new(sp.X, sp.Y) - mouseVec).Magnitude
                                if d <= Settings.Aimbot.FOV and d < closestDist then
                                    closestDist = d
                                    closest = {part=tp, char=char, humanoid=humanoid, player=player}
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function aimAtTarget(target)
    if not target or not target.part then return end
    local predictedPos = target.part.Position

    if Settings.Aimbot.Prediction > 0 then
        local vel = getVelocity(target.char)
        local dist = (Camera.CFrame.Position - target.part.Position).Magnitude
        predictedPos = target.part.Position + vel * Settings.Aimbot.Prediction * (dist / 500) * 10
    end

    if Settings.Aimbot.Method == "Mouse" then
        local ok, sp = pcall(function() return Camera:WorldToViewportPoint(predictedPos) end)
        if ok and sp and sp.Z > 0 then
            local mp = UserInputService:GetMouseLocation()
            local mx = clamp((sp.X - mp.X) / Settings.Aimbot.Smoothness, -300, 300)
            local my = clamp((sp.Y - mp.Y) / Settings.Aimbot.Smoothness, -300, 300)
            pcall(function() mousemoverel(mx, my) end)
        end
    elseif Settings.Aimbot.Method == "Camera" then
        local cf = Camera.CFrame
        local look = CFrame.lookAt(cf.Position, predictedPos)
        Camera.CFrame = cf:Lerp(look, clamp(1 / Settings.Aimbot.Smoothness, 0.02, 1))
    end
end

-- ═══ ESP ═══
local function createESPObjects(player)
    if espObjects[player] then return end
    local objs = {cornerLines = {}}

    if Drawing then
        pcall(function()
            objs.box = Drawing.new("Square")
            objs.box.Thickness = 1.5; objs.box.Filled = false; objs.box.Visible = false

            for i = 1, 8 do
                local l = Drawing.new("Line")
                l.Thickness = 2; l.Visible = false
                objs.cornerLines[i] = l
            end

            objs.name = Drawing.new("Text")
            objs.name.Size = 13; objs.name.Center = true; objs.name.Outline = true
            objs.name.Color = Color3.fromRGB(255,255,255); objs.name.Visible = false

            objs.healthBG = Drawing.new("Square")
            objs.healthBG.Thickness = 0; objs.healthBG.Filled = true
            objs.healthBG.Color = Color3.fromRGB(20,20,25); objs.healthBG.Visible = false

            objs.healthFill = Drawing.new("Square")
            objs.healthFill.Thickness = 0; objs.healthFill.Filled = true; objs.healthFill.Visible = false

            objs.distance = Drawing.new("Text")
            objs.distance.Size = 12; objs.distance.Center = true; objs.distance.Outline = true
            objs.distance.Color = Color3.fromRGB(200,200,200); objs.distance.Visible = false

            objs.tracer = Drawing.new("Line")
            objs.tracer.Thickness = 1.5; objs.tracer.Visible = false

            objs.weapon = Drawing.new("Text")
            objs.weapon.Size = 11; objs.weapon.Center = true; objs.weapon.Outline = true
            objs.weapon.Visible = false
        end)
    end

    objs.highlight = Instance.new("Highlight")
    objs.highlight.FillColor = Color3.fromRGB(147,51,234)
    objs.highlight.FillTransparency = 0.5
    objs.highlight.OutlineColor = Color3.fromRGB(147,51,234)
    objs.highlight.OutlineTransparency = 0.2
    objs.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    objs.highlight.Enabled = false
    pcall(function() objs.highlight.Parent = game:GetService("CoreGui") end)
    if not objs.highlight.Parent then objs.highlight.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    espObjects[player] = objs
end

local function removeESPObjects(player)
    local objs = espObjects[player]
    if not objs then return end
    pcall(function()
        for _, k in ipairs({"box","name","healthBG","healthFill","distance","tracer","weapon"}) do
            if objs[k] then objs[k]:Remove() end
        end
        for _, l in ipairs(objs.cornerLines or {}) do pcall(function() l:Remove() end) end
        if objs.highlight then objs.highlight:Destroy() end
    end)
    espObjects[player] = nil
end

local function hideESP(objs)
    pcall(function()
        for _, k in ipairs({"box","name","healthBG","healthFill","distance","tracer","weapon"}) do
            if objs[k] then objs[k].Visible = false end
        end
        for _, l in ipairs(objs.cornerLines or {}) do l.Visible = false end
        if objs.highlight then objs.highlight.Enabled = false end
    end)
end

local function renderESP()
    if not Drawing then return end
    for player, objs in pairs(espObjects) do
        local char, humanoid, rootPart = getCharacter(player)
        local teamBlocked = Settings.ESP.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team

        if not Settings.ESP.Enabled or teamBlocked or not char then
            hideESP(objs)
        else
            local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
            if dist > Settings.ESP.MaxDistance then
                hideESP(objs)
            else
                local ok, sp = pcall(function() return Camera:WorldToViewportPoint(rootPart.Position) end)
                if not ok or not sp or sp.Z <= 0 then
                    hideESP(objs)
                else
                    local head = char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or rootPart
                    local headS = Camera:WorldToViewportPoint(head.Position)
                    local footS = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, rootPart.Size.Y * 0.5 + 1, 0))

                    local boxY = headS.Y - (sp.Y - headS.Y) * 0.3
                    local bh = math.abs(footS.Y - boxY)
                    local bw = bh * 0.65
                    local bx = sp.X - bw / 2

                    local hp = clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local hpC = hp > 0.5 and Color3.fromRGB(60,220,60) or (hp > 0.25 and Color3.fromRGB(220,200,40) or Color3.fromRGB(220,50,50))

                    pcall(function()
                        -- Box
                        if Settings.ESP.Boxes then
                            if Settings.ESP.BoxType == "Full" then
                                objs.box.Visible = true
                                objs.box.Position = Vector2.new(bx, boxY)
                                objs.box.Size = Vector2.new(bw, bh)
                                objs.box.Color = Settings.ESP.BoxColor
                                for _, l in ipairs(objs.cornerLines) do l.Visible = false end
                            else
                                objs.box.Visible = false
                                local cl = math.min(bw, bh) * 0.25
                                local corners = {
                                    {Vector2.new(bx,boxY), Vector2.new(bx+cl,boxY)},
                                    {Vector2.new(bx,boxY), Vector2.new(bx,boxY+cl)},
                                    {Vector2.new(bx+bw,boxY), Vector2.new(bx+bw-cl,boxY)},
                                    {Vector2.new(bx+bw,boxY), Vector2.new(bx+bw,boxY+cl)},
                                    {Vector2.new(bx,boxY+bh), Vector2.new(bx+cl,boxY+bh)},
                                    {Vector2.new(bx,boxY+bh), Vector2.new(bx,boxY+bh-cl)},
                                    {Vector2.new(bx+bw,boxY+bh), Vector2.new(bx+bw-cl,boxY+bh)},
                                    {Vector2.new(bx+bw,boxY+bh), Vector2.new(bx+bw,boxY+bh-cl)},
                                }
                                for i, cn in ipairs(corners) do
                                    objs.cornerLines[i].Visible = true
                                    objs.cornerLines[i].From = cn[1]
                                    objs.cornerLines[i].To = cn[2]
                                    objs.cornerLines[i].Color = Settings.ESP.BoxColor
                                end
                            end
                        else
                            objs.box.Visible = false
                            for _, l in ipairs(objs.cornerLines) do l.Visible = false end
                        end

                        -- Name
                        if Settings.ESP.Names then
                            objs.name.Visible = true
                            objs.name.Text = player.DisplayName
                            objs.name.Position = Vector2.new(sp.X, boxY - 16)
                        else objs.name.Visible = false end

                        -- Health
                        if Settings.ESP.Health then
                            if Settings.ESP.HealthType == "Left" then
                                objs.healthBG.Visible = true
                                objs.healthBG.Position = Vector2.new(bx-7, boxY)
                                objs.healthBG.Size = Vector2.new(4, bh)
                                local fh = bh * hp
                                objs.healthFill.Visible = true
                                objs.healthFill.Position = Vector2.new(bx-6, boxY+(bh-fh))
                                objs.healthFill.Size = Vector2.new(2, fh)
                                objs.healthFill.Color = hpC
                            else
                                objs.healthBG.Visible = true
                                objs.healthBG.Position = Vector2.new(bx, boxY+bh+14)
                                objs.healthBG.Size = Vector2.new(bw, 4)
                                local fw = bw * hp
                                objs.healthFill.Visible = true
                                objs.healthFill.Position = Vector2.new(bx, boxY+bh+14)
                                objs.healthFill.Size = Vector2.new(fw, 2)
                                objs.healthFill.Color = hpC
                            end
                        else
                            objs.healthBG.Visible = false
                            objs.healthFill.Visible = false
                        end

                        -- Distance
                        if Settings.ESP.Distance then
                            objs.distance.Visible = true
                            objs.distance.Text = math.floor(dist) .. "m"
                            objs.distance.Position = Vector2.new(sp.X, boxY+bh+2)
                        else objs.distance.Visible = false end

                        -- Tracer
                        if Settings.ESP.Tracers then
                            objs.tracer.Visible = true
                            objs.tracer.Color = Settings.ESP.TracerColor
                            local origin
                            if Settings.ESP.TracerOrigin == "Bottom" then
                                origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            elseif Settings.ESP.TracerOrigin == "Center" then
                                origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                            else
                                local mp = UserInputService:GetMouseLocation()
                                origin = Vector2.new(mp.X, mp.Y)
                            end
                            objs.tracer.From = origin
                            objs.tracer.To = Vector2.new(sp.X, boxY+bh)
                        else objs.tracer.Visible = false end

                        -- Tool
                        if Settings.ESP.ToolESP then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                objs.weapon.Visible = true
                                objs.weapon.Text = tool.Name
                                objs.weapon.Position = Vector2.new(sp.X, boxY+bh+14)
                                objs.weapon.Color = Color3.fromRGB(255,200,0)
                            else objs.weapon.Visible = false end
                        else objs.weapon.Visible = false end

                        -- Chams
                        if Settings.ESP.Chams then
                            objs.highlight.Enabled = true
                            objs.highlight.Adornee = char
                            objs.highlight.FillColor = Settings.ESP.ChamsColor
                            objs.highlight.FillTransparency = Settings.ESP.ChamsTransparency
                        else objs.highlight.Enabled = false end
                    end)
                end
            end
        end
    end
end

-- ═══ VISUALS ═══
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local function applyVisuals()
    pcall(function()
        if Settings.Visuals.Fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178,178,178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
        else
            Lighting.Brightness = originalLighting.Brightness
            Lighting.ClockTime = originalLighting.ClockTime
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.Ambient = originalLighting.Ambient
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        end
        if Settings.Visuals.NoFog then
            Lighting.FogEnd = 100000
        elseif not Settings.Visuals.Fullbright then
            Lighting.FogEnd = originalLighting.FogEnd
        end
    end)
end

local crosshairLines = {}
if Drawing then
    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Thickness = 1.5; l.Visible = false
        crosshairLines[i] = l
    end
end

local function renderCrosshair()
    if not Drawing then return end
    if Settings.Visuals.Crosshair then
        local cx = Camera.ViewportSize.X / 2
        local cy = Camera.ViewportSize.Y / 2
        local sz = Settings.Visuals.CrosshairSize
        local gp = Settings.Visuals.CrosshairGap
        local pos = {
            {Vector2.new(cx-sz-gp, cy), Vector2.new(cx-gp, cy)},
            {Vector2.new(cx+gp, cy), Vector2.new(cx+sz+gp, cy)},
            {Vector2.new(cx, cy-sz-gp), Vector2.new(cx, cy-gp)},
            {Vector2.new(cx, cy+gp), Vector2.new(cx, cy+sz+gp)},
        }
        for i, p in ipairs(pos) do
            crosshairLines[i].Visible = true
            crosshairLines[i].From = p[1]
            crosshairLines[i].To = p[2]
            crosshairLines[i].Color = Settings.Visuals.CrosshairColor
        end
    else
        for _, l in ipairs(crosshairLines) do l.Visible = false end
    end
end

-- ═══ MISC ═══
local function stopFly()
    flying = false
    if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) bodyVelocity = nil end
    if bodyGyro then pcall(function() bodyGyro:Destroy() end) bodyGyro = nil end
end

local function applyMisc()
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if Settings.Misc.InfiniteJump then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local h = char:FindFirstChildOfClass("Humanoid")
                if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
            end
        end)
    end

    if Settings.Misc.AntiAFK then
        LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end

    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if Settings.Misc.NoClip then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
                end
            end
        end)
    end

    if flyConn then flyConn:Disconnect() flyConn = nil end
    if Settings.Misc.Fly then
        stopFly()
        flying = true
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local root = char.HumanoidRootPart
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(4e5, 4e5, 4e5)
            bodyVelocity.Velocity = Vector3.new(0,0,0)
            bodyVelocity.Parent = root

            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
            bodyGyro.P = 1e4
            bodyGyro.D = 500
            bodyGyro.Parent = root

            flyConn = RunService.RenderStepped:Connect(function()
                if not flying or not bodyVelocity then return end
                local spd = Settings.Misc.FlySpeed
                local mv = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
                bodyVelocity.Velocity = mv * spd
                if bodyGyro then bodyGyro.CFrame = Camera.CFrame end
            end)
        end
    else
        stopFly()
    end
end

-- ═══════════════════════════════════════════════
--  UI
-- ═══════════════════════════════════════════════

local Accent = Color3.fromRGB(147,51,234)
local BG = Color3.fromRGB(8,8,12)
local SidebarBG = Color3.fromRGB(12,12,18)
local Elem = Color3.fromRGB(20,20,28)
local ElemHover = Color3.fromRGB(28,28,38)
local TxtC = Color3.fromRGB(235,235,245)
local SubTxt = Color3.fromRGB(130,130,155)
local StrokeC = Color3.fromRGB(35,35,50)

local ScreenGui = createSafeUI("AdrianCheatV13")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 680, 0, 480)
Main.Position = UDim2.new(0.5, -340, 0.5, -240)
Main.BackgroundColor3 = BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = StrokeC
MainStroke.Thickness = 1.5
MainStroke.Parent = Main

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = SidebarBG
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 14)
TitleCorner.Parent = TitleBar

local TitleCover = Instance.new("Frame")
TitleCover.Size = UDim2.new(1, 0, 0, 28)
TitleCover.Position = UDim2.new(0, 0, 1, -28)
TitleCover.BackgroundColor3 = SidebarBG
TitleCover.BorderSizePixel = 0
TitleCover.Parent = TitleBar

local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, 0, 0, 1)
AccentLine.Position = UDim2.new(0, 0, 1, 0)
AccentLine.BackgroundColor3 = Accent
AccentLine.BackgroundTransparency = 0.5
AccentLine.BorderSizePixel = 0
AccentLine.Parent = TitleBar

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 32, 0, 32)
Logo.Position = UDim2.new(0, 12, 0.5, -16)
Logo.BackgroundColor3 = Accent
Logo.BorderSizePixel = 0
Logo.Parent = TitleBar

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 8)
LogoCorner.Parent = Logo

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "A"
LogoText.TextColor3 = Color3.new(1,1,1)
LogoText.TextSize = 18
LogoText.Font = Enum.Font.GothamBold
LogoText.Parent = Logo

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 300, 1, 0)
TitleText.Position = UDim2.new(0, 55, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "ADRIAN RIVALS"
TitleText.TextColor3 = TxtC
TitleText.TextSize = 15
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, 40, 1, 0)
VersionLabel.Position = UDim2.new(0, 195, 0, 0)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "v1.3"
VersionLabel.TextColor3 = Accent
VersionLabel.TextSize = 11
VersionLabel.Font = Enum.Font.GothamBold
VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
VersionLabel.Parent = TitleBar

local DevLabel = Instance.new("TextLabel")
DevLabel.Size = UDim2.new(0, 150, 1, 0)
DevLabel.Position = UDim2.new(1, -190, 0, 0)
DevLabel.BackgroundTransparency = 1
DevLabel.Text = "by MR Adrian"
DevLabel.TextColor3 = SubTxt
DevLabel.TextSize = 11
DevLabel.Font = Enum.Font.Gotham
DevLabel.TextXAlignment = Enum.TextXAlignment.Right
DevLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = CloseBtn

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 165, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = SidebarBG
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local tabs = {}
local currentTab = nil

local function selectTab(name)
    local tab = tabs[name]
    if not tab then return end
    for _, t in pairs(tabs) do
        t.page.Visible = false
        t.button.BackgroundColor3 = Elem
        t.accentBar.Visible = false
        t.textLabel.TextColor3 = SubTxt
    end
    tab.page.Visible = true
    tab.button.BackgroundColor3 = Color3.fromRGB(25,18,40)
    tab.accentBar.Visible = true
    tab.textLabel.TextColor3 = Accent
    currentTab = name
end

local function createTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 36)
    btn.Position = UDim2.new(0, 8, 0, 8 + (order-1)*42)
    btn.BackgroundColor3 = Elem
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = Sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 24, 1, 0)
    iconLabel.Position = UDim2.new(0, 8, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 15
    iconLabel.Parent = btn

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -40, 1, 0)
    textLabel.Position = UDim2.new(0, 36, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = name
    textLabel.TextColor3 = SubTxt
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = btn

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 0.6, 0)
    accentBar.Position = UDim2.new(0, 0, 0.2, 0)
    accentBar.BackgroundColor3 = Accent
    accentBar.BorderSizePixel = 0
    accentBar.Visible = false
    accentBar.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -180, 1, -62)
    page.Position = UDim2.new(0, 172, 0, 56)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = Main

    local pp = Instance.new("UIPadding")
    pp.PaddingLeft = UDim.new(0, 8)
    pp.PaddingRight = UDim.new(0, 12)
    pp.PaddingTop = UDim.new(0, 4)
    pp.Parent = page

    local pl = Instance.new("UIListLayout")
    pl.Padding = UDim.new(0, 4)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    pl.Parent = page

    tabs[name] = {button = btn, page = page, accentBar = accentBar, textLabel = textLabel}
    btn.MouseButton1Click:Connect(function() selectTab(name) end)

    return page
end

-- UI Factory
local function createSection(page, title)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = #page:GetChildren()
    frame.Parent = page

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = StrokeC
    line.BackgroundTransparency = 0.5
    line.BorderSizePixel = 0
    line.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, -4)
    label.BackgroundTransparency = 1
    label.Text = "  " .. string.upper(title)
    label.TextColor3 = Accent
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
end

local function createToggle(page, name, default, callback)
    local enabled = default

    local frame = Instance.new("TextButton")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Elem
    frame.Text = ""
    frame.BorderSizePixel = 0
    frame.AutoButtonColor = false
    frame.LayoutOrder = #page:GetChildren()
    frame.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = TxtC
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 36, 0, 18)
    toggleBg.Position = UDim2.new(1, -46, 0.5, -9)
    toggleBg.BackgroundColor3 = enabled and Accent or Color3.fromRGB(40,40,55)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    frame.MouseButton1Click:Connect(function()
        enabled = not enabled
        pcall(function()
            TweenService:Create(toggleBg, TweenInfo.new(0.15), {BackgroundColor3 = enabled and Accent or Color3.fromRGB(40,40,55)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
        end)
        callback(enabled)
    end)

    return frame
end

local function createSlider(page, name, min, max, default, decimals, callback)
    local dragging = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = Elem
    frame.BorderSizePixel = 0
    frame.LayoutOrder = #page:GetChildren()
    frame.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 0, 16)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = TxtC
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 80, 0, 16)
    valueLabel.Position = UDim2.new(1, -88, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = string.format("%." .. decimals .. "f", default)
    valueLabel.TextColor3 = Accent
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, -24, 0, 5)
    sliderBack.Position = UDim2.new(0, 12, 0, 32)
    sliderBack.BackgroundColor3 = Color3.fromRGB(35,35,50)
    sliderBack.BorderSizePixel = 0
    sliderBack.Parent = frame

    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(1, 0)
    backCorner.Parent = sliderBack

    local rel = (default - min) / (max - min)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(rel, 0, 1, 0)
    sliderFill.BackgroundColor3 = Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(rel, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = sliderBack

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1, 0, 0, 20)
    clickArea.Position = UDim2.new(0, 0, 0.5, -10)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.Parent = sliderBack

    local function update(inputPos)
        local rel2 = clamp((inputPos.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * rel2
        val = math.floor(val * (10^decimals) + 0.5) / (10^decimals)
        sliderFill.Size = UDim2.new(rel2, 0, 1, 0)
        knob.Position = UDim2.new(rel2, -7, 0.5, -7)
        valueLabel.Text = string.format("%." .. decimals .. "f", val)
        callback(val)
    end

    clickArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return frame
end

local function createDropdown(page, name, options, default, callback)
    local isOpen = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Elem
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.LayoutOrder = #page:GetChildren()
    frame.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 32)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = TxtC
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(0.35, 0, 0, 32)
    selectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = default
    selectedLabel.TextColor3 = Accent
    selectedLabel.TextSize = 12
    selectedLabel.Font = Enum.Font.GothamBold
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
    selectedLabel.Parent = frame

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 18, 0, 32)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = SubTxt
    arrow.TextSize = 9
    arrow.Parent = frame

    local optionsContainer = Instance.new("Frame")
    optionsContainer.Size = UDim2.new(1, -8, 0, #options * 26)
    optionsContainer.Position = UDim2.new(0, 4, 0, 36)
    optionsContainer.BackgroundColor3 = Color3.fromRGB(15,15,22)
    optionsContainer.BorderSizePixel = 0
    optionsContainer.Visible = false
    optionsContainer.ZIndex = 10
    optionsContainer.Parent = frame

    local ocCorner = Instance.new("UICorner")
    ocCorner.CornerRadius = UDim.new(0, 8)
    ocCorner.Parent = optionsContainer

    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, -4, 0, 24)
        optBtn.Position = UDim2.new(0, 2, 0, 2 + (i-1)*26)
        optBtn.BackgroundColor3 = option == default and Color3.fromRGB(30,20,45) or Color3.fromRGB(20,20,30)
        optBtn.Text = "  " .. option
        optBtn.TextColor3 = option == default and Accent or SubTxt
        optBtn.TextSize = 12
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.BorderSizePixel = 0
        optBtn.AutoButtonColor = false
        optBtn.ZIndex = 11
        optBtn.Parent = optionsContainer

        local optCorner = Instance.new("UICorner")
        optCorner.CornerRadius = UDim.new(0, 6)
        optCorner.Parent = optBtn

        optBtn.MouseButton1Click:Connect(function()
            selectedLabel.Text = option
            optionsContainer.Visible = false
            isOpen = false
            arrow.Text = "▼"
            frame.Size = UDim2.new(1, 0, 0, 32)
            callback(option)
        end)
    end

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 0, 32)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 5
    clickBtn.Parent = frame

    clickBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optionsContainer.Visible = isOpen
        arrow.Text = isOpen and "▲" or "▼"
        frame.Size = isOpen and UDim2.new(1, 0, 0, 40 + #options*26) or UDim2.new(1, 0, 0, 32)
    end)

    return frame
end

-- ═══════════════════════════════════════════════
--  BUILD PAGES
-- ═══════════════════════════════════════════════

-- AIMBOT
local aimbotPage = createTab("Aimbot", "🎯", 1)
createSection(aimbotPage, "aimbot")
createToggle(aimbotPage, "Enable Aimbot", false, function(v) Settings.Aimbot.Enabled = v end)
createDropdown(aimbotPage, "Method", {"Mouse", "Camera"}, "Mouse", function(v) Settings.Aimbot.Method = v end)
createDropdown(aimbotPage, "Target Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "Head", function(v) Settings.Aimbot.TargetPart = v end)
createSlider(aimbotPage, "FOV", 20, 500, 150, 0, function(v) Settings.Aimbot.FOV = v if fovCircle then fovCircle.Radius = v end end)
createSlider(aimbotPage, "Smoothness", 1, 20, 2.5, 1, function(v) Settings.Aimbot.Smoothness = v end)
createSlider(aimbotPage, "Prediction", 0, 1, 0.12, 2, function(v) Settings.Aimbot.Prediction = v end)
createToggle(aimbotPage, "Show FOV", true, function(v) Settings.Aimbot.ShowFOV = v end)
createToggle(aimbotPage, "Team Check", false, function(v) Settings.Aimbot.TeamCheck = v end)
createToggle(aimbotPage, "Aim Through Wall", true, function(v) Settings.Aimbot.AimBehindWall = v end)
createToggle(aimbotPage, "Highlight Target", true, function(v) Settings.Aimbot.HighlightTarget = v end)

-- GOD MODE
local godPage = createTab("God Mode", "🛡", 2)
createSection(godPage, "god mode")
createToggle(godPage, "Enable God Mode", false, function(v)
    Settings.GodMode.Enabled = v
    applyGodMode()
end)

-- TRIGGER BOT
local triggerPage = createTab("Trigger Bot", "🔫", 3)
createSection(triggerPage, "trigger bot")
createToggle(triggerPage, "Enable Trigger Bot", false, function(v) Settings.TriggerBot.Enabled = v end)
createSlider(triggerPage, "Reaction Delay", 0.05, 1, 0.15, 2, function(v) Settings.TriggerBot.Delay = v end)
createSlider(triggerPage, "Range", 50, 1000, 500, 0, function(v) Settings.TriggerBot.Range = v end)
createToggle(triggerPage, "Team Check", true, function(v) Settings.TriggerBot.TeamCheck = v end)
createToggle(triggerPage, "Check Walls", false, function(v) Settings.TriggerBot.CheckWalls = v end)

-- ESP
local espPage = createTab("ESP", "👁", 4)
createSection(espPage, "esp")
createToggle(espPage, "Enable ESP", false, function(v) Settings.ESP.Enabled = v end)
createDropdown(espPage, "Box Style", {"Corner", "Full"}, "Corner", function(v) Settings.ESP.BoxType = v end)
createSlider(espPage, "Max Distance", 100, 5000, 2000, 0, function(v) Settings.ESP.MaxDistance = v end)
createSection(espPage, "elements")
createToggle(espPage, "Boxes", true, function(v) Settings.ESP.Boxes = v end)
createToggle(espPage, "Names", true, function(v) Settings.ESP.Names = v end)
createToggle(espPage, "Health Bar", true, function(v) Settings.ESP.Health = v end)
createDropdown(espPage, "Health Position", {"Left", "Bottom"}, "Left", function(v) Settings.ESP.HealthType = v end)
createToggle(espPage, "Distance", true, function(v) Settings.ESP.Distance = v end)
createToggle(espPage, "Tool ESP", false, function(v) Settings.ESP.ToolESP = v end)
createSection(espPage, "tracers")
createToggle(espPage, "Tracers", false, function(v) Settings.ESP.Tracers = v end)
createDropdown(espPage, "Tracer Origin", {"Bottom", "Center", "Mouse"}, "Bottom", function(v) Settings.ESP.TracerOrigin = v end)
createSection(espPage, "chams")
createToggle(espPage, "Chams (Wall Hack)", false, function(v) Settings.ESP.Chams = v end)
createToggle(espPage, "Team Check", false, function(v) Settings.ESP.TeamCheck = v end)

-- VISUALS
local visualsPage = createTab("Visuals", "🎨", 5)
createSection(visualsPage, "world")
createToggle(visualsPage, "Fullbright", false, function(v) Settings.Visuals.Fullbright = v applyVisuals() end)
createToggle(visualsPage, "No Fog", false, function(v) Settings.Visuals.NoFog = v applyVisuals() end)
createSection(visualsPage, "crosshair")
createToggle(visualsPage, "Custom Crosshair", false, function(v) Settings.Visuals.Crosshair = v end)
createSlider(visualsPage, "Crosshair Size", 2, 30, 8, 0, function(v) Settings.Visuals.CrosshairSize = v end)
createSlider(visualsPage, "Crosshair Gap", 0, 15, 4, 0, function(v) Settings.Visuals.CrosshairGap = v end)

-- MISC
local miscPage = createTab("Misc", "⚡", 6)
createSection(miscPage, "movement")
createToggle(miscPage, "Infinite Jump", false, function(v) Settings.Misc.InfiniteJump = v applyMisc() end)
createToggle(miscPage, "NoClip", false, function(v) Settings.Misc.NoClip = v applyMisc() end)
createToggle(miscPage, "Fly", false, function(v) Settings.Misc.Fly = v applyMisc() end)
createSlider(miscPage, "Fly Speed", 10, 200, 50, 0, function(v) Settings.Misc.FlySpeed = v end)
createToggle(miscPage, "Anti AFK", false, function(v) Settings.Misc.AntiAFK = v end)
createSection(miscPage, "custom speed")
createToggle(miscPage, "Custom Walk Speed", false, function(v)
    Settings.Misc.SpeedEnabled = v
    if not v then
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 16 end
        end
    end
end)
createSlider(miscPage, "Walk Speed", 16, 100, 16, 0, function(v)
    Settings.Misc.SpeedValue = v
    if Settings.Misc.SpeedEnabled then
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v end
        end
    end
end)
createToggle(miscPage, "Custom Jump Power", false, function(v)
    Settings.Misc.JumpEnabled = v
    if not v then
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower = true h.JumpPower = 50 end
        end
    end
end)
createSlider(miscPage, "Jump Power", 50, 150, 50, 0, function(v)
    Settings.Misc.JumpValue = v
    if Settings.Misc.JumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.UseJumpPower = true h.JumpPower = v end
        end
    end
end)

-- SETTINGS
local settingsPage = createTab("Settings", "⚙", 7)
createSection(settingsPage, "info")
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, 0, 0, 100)
infoFrame.BackgroundColor3 = Elem
infoFrame.BorderSizePixel = 0
infoFrame.LayoutOrder = #settingsPage:GetChildren()
infoFrame.Parent = settingsPage

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 8)
infoCorner.Parent = infoFrame

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -20, 1, -10)
infoText.Position = UDim2.new(0, 10, 0, 5)
infoText.BackgroundTransparency = 1
infoText.Text = "Adrian Rivals Cheat v1.3\nDeveloper: MR Adrian\n\nUI Toggle: Right Shift\nAimbot: Right Click (Hold)"
infoText.TextColor3 = SubTxt
infoText.TextSize = 11
infoText.Font = Enum.Font.Gotham
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.Parent = infoFrame

createSection(settingsPage, "unload")
local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(1, 0, 0, 36)
unloadBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
unloadBtn.Text = "☠  UNLOAD CHEAT"
unloadBtn.TextColor3 = Color3.new(1,1,1)
unloadBtn.TextSize = 14
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.BorderSizePixel = 0
unloadBtn.LayoutOrder = #settingsPage:GetChildren()
unloadBtn.Parent = settingsPage

local unloadCorner = Instance.new("UICorner")
unloadCorner.CornerRadius = UDim.new(0, 8)
unloadCorner.Parent = unloadBtn

unloadBtn.MouseButton1Click:Connect(function()
    for player, objs in pairs(espObjects) do removeESPObjects(player) end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    pcall(function() targetHighlight:Destroy() end)
    for _, l in ipairs(crosshairLines) do pcall(function() l:Remove() end) end
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    if infJumpConn then infJumpConn:Disconnect() end
    if noclipConn then noclipConn:Disconnect() end
    if flyConn then flyConn:Disconnect() end
    if godModeConn then godModeConn:Disconnect() end
    stopFly()
    pcall(function()
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end)
    ScreenGui:Destroy()
end)

selectTab("Aimbot")

-- ═══════════════════════════════════════════════
--  INPUT
-- ═══════════════════════════════════════════════

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightShift and not gameProcessed then
        uiVisible = not uiVisible
        Main.Visible = uiVisible
    end
    if input.UserInputType == Settings.Aimbot.AimKey then
        aiming = true
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Settings.Aimbot.AimKey then
        aiming = false
    end
end))

CloseBtn.MouseButton1Click:Connect(function()
    for player, objs in pairs(espObjects) do removeESPObjects(player) end
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    pcall(function() targetHighlight:Destroy() end)
    for _, l in ipairs(crosshairLines) do pcall(function() l:Remove() end) end
    stopFly()
    ScreenGui:Destroy()
end)

-- ═══════════════════════════════════════════════
--  PLAYERS
-- ═══════════════════════════════════════════════

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESPObjects(player)
    end
end

table.insert(connections, Players.PlayerAdded:Connect(function(player)
    createESPObjects(player)
end))

table.insert(connections, Players.PlayerRemoving:Connect(function(player)
    removeESPObjects(player)
end))

-- ═══════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════

table.insert(connections, RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Trigger Bot
        if Settings.TriggerBot.Enabled then
            local now = tick()
            if now - lastTrigger >= Settings.TriggerBot.Delay then
                local tp = getTriggerTarget()
                if tp then
                    lastTrigger = now
                    doShoot()
                end
            end
        end

        -- Aimbot
        if Settings.Aimbot.Enabled and aiming then
            currentTarget = getBestTarget()
            if currentTarget then
                if Settings.Aimbot.HighlightTarget then
                    targetHighlight.Enabled = true
                    targetHighlight.Adornee = currentTarget.char
                end
                aimAtTarget(currentTarget)
            else
                targetHighlight.Enabled = false
            end
        else
            currentTarget = nil
            targetHighlight.Enabled = false
        end

        -- FOV Circle
        if fovCircle then
            if Settings.Aimbot.Enabled and Settings.Aimbot.ShowFOV then
                local mp = UserInputService:GetMouseLocation()
                fovCircle.Position = Vector2.new(mp.X, mp.Y)
                fovCircle.Radius = Settings.Aimbot.FOV
                fovCircle.Visible = true
            else
                fovCircle.Visible = false
            end
        end

        -- ESP + Crosshair
        renderESP()
        renderCrosshair()

        -- Speed/Jump maintenance
        if Settings.Misc.SpeedEnabled then
            local char = LocalPlayer.Character
            if char then
                local h = char:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed = Settings.Misc.SpeedValue end
            end
        end

        if Settings.Misc.JumpEnabled then
            local char = LocalPlayer.Character
            if char then
                local h = char:FindFirstChildOfClass("Humanoid")
                if h then h.UseJumpPower = true h.JumpPower = Settings.Misc.JumpValue end
            end
        end
    end)
end))

print("[Adrian Rivals Cheat v1.3] Loaded for " .. LocalPlayer.Name)

--[[
    ╔══════════════════════════════════════════╗
    ║       ADRIAN RIVALS CHEAT v1.1           ║
    ║       Developer: MR Adrian               ║
    ║       Toggle: Right Shift                ║
    ╚══════════════════════════════════════════╝
]]

-- ═══════════ SERVICES ═══════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ═══════════ SETTINGS ═══════════
local Settings = {
    Aimbot = {
        Enabled = false,
        FOV = 150,
        TargetPart = "Head",
        TeamCheck = false,
        ShowFOV = true,
        FOVColor = Color3.fromRGB(147, 51, 234),
        AimKey = Enum.UserInputType.MouseButton2,
        Prediction = 0.12,
        Method = "Mouse",
        Smoothness = 2.5,
        AimBehindWall = true,
        HighlightTarget = true,
    },
    SilentAim = {
        Enabled = false,
        FOV = 250,
        TargetPart = "Head",
        TeamCheck = false,
        ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 120, 0),
        AimBehindWall = true,
        HitChance = 100,
    },
    TriggerBot = {
        Enabled = false,
        Delay = 0.1,
        TeamCheck = true,
        CheckWalls = false,
        Range = 300,
    },
    ESP = {
        Enabled = false,
        Boxes = true,
        BoxColor = Color3.fromRGB(147, 51, 234),
        BoxType = "Corner",
        Names = true,
        Health = true,
        HealthType = "Left",
        Distance = true,
        Tracers = false,
        TracerOrigin = "Bottom",
        TracerColor = Color3.fromRGB(147, 51, 234),
        TeamCheck = false,
        MaxDistance = 2000,
        BoxThickness = 1.5,
        TextSize = 13,
        Chams = false,
        ChamsColor = Color3.fromRGB(147, 51, 234),
        ChamsTransparency = 0.5,
        ToolESP = false,
    },
    Visuals = {
        Fullbright = false,
        NoFog = false,
        Crosshair = false,
        CrosshairSize = 8,
        CrosshairColor = Color3.fromRGB(147, 51, 234),
        CrosshairGap = 4,
    },
    Misc = {
        InfiniteJump = false,
        NoClip = false,
        Fly = false,
        FlySpeed = 50,
        AntiAFK = false,
        SpeedEnabled = false,
        SpeedValue = 16,
        JumpEnabled = false,
        JumpValue = 50,
    }
}

-- ═══════════ STATE ═══════════
local uiVisible = true
local aiming = false
local espObjects = {}
local connections = {}
local currentTarget = nil
local silentTarget = nil
local lastTrigger = 0
local triggerShooting = false

-- ═══════════ UTILITY ═══════════
local function clamp(v, min, max)
    return math.max(min, math.min(max, v))
end

local function getCharacter(player)
    if not player or player == LocalPlayer then return nil end
    local ok, char = pcall(function() return player.Character end)
    if not ok or not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not rootPart then return nil end
    return char, humanoid, rootPart
end

local function getTargetPart(char, partName)
    local fallbacks = {
        ["Head"] = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"},
        ["HumanoidRootPart"] = {"HumanoidRootPart", "UpperTorso", "Torso", "Head"},
        ["UpperTorso"] = {"UpperTorso", "Torso", "HumanoidRootPart"},
        ["Torso"] = {"Torso", "UpperTorso", "HumanoidRootPart"},
    }
    local list = fallbacks[partName] or {"Head", "HumanoidRootPart"}
    for _, name in ipairs(list) do
        local part = char:FindFirstChild(name)
        if part then return part end
    end
    return nil
end

local function isWallBetween(targetPart, targetChar)
    local myChar = LocalPlayer.Character
    if not myChar then return true end
    local myHead = myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart")
    if not myHead then return true end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {myChar, targetChar, Camera}
    
    local direction = targetPart.Position - myHead.Position
    local result = Workspace:Raycast(myHead.Position, direction, rayParams)
    
    if result then
        return not result.Instance:IsDescendantOf(targetChar)
    end
    return false
end

local function getVelocity(char)
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    if root then
        local ok, vel = pcall(function() return root.AssemblyLinearVelocity end)
        if ok then return vel end
    end
    return Vector3.new(0, 0, 0)
end

-- ═══════════ TRIGGER BOT (FIXED) ═══════════
-- روش: raycast از camera از طریق mouse position
local function getTriggerTarget()
    local mousePos = UserInputService:GetMouseLocation()
    -- ViewportPointToRay = دقیق‌ترین روش برای چک کردن چی زیر موسه
    local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * Settings.TriggerBot.Range, rayParams)
    
    if result and result.Instance then
        -- پیدا کردن character از instance
        local char = result.Instance.Parent
        while char and not char:FindFirstChildOfClass("Humanoid") do
            char = char.Parent
        end
        
        if char then
            local player = Players:GetPlayerFromCharacter(char)
            if player and player ~= LocalPlayer then
                -- team check
                if Settings.TriggerBot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    return nil
                end
                -- wall check
                if Settings.TriggerBot.CheckWalls then
                    local targetPart = getTargetPart(char, "Head")
                    if targetPart and isWallBetween(targetPart, char) then
                        return nil
                    end
                end
                return player, char
            end
        end
    end
    return nil
end

-- تابع شلیک با چند روش fallback
local function doTriggerShoot()
    -- روش ۱: mouse1click (ساده‌ترین)
    local ok = pcall(function()
        mouse1click()
    end)
    
    if not ok then
        -- روش ۲: mouse1press/release
        ok = pcall(function()
            mouse1press()
            task.wait(0.01)
            mouse1release()
        end)
    end
    
    if not ok then
        -- روش ۳: VirtualUser
        pcall(function()
            VirtualUser:ClickButton1(Vector2.new())
        end)
    end
end

-- ═══════════ SILENT AIM (FIXED) ═══════════
-- چند روش مختلف برای سازگاری

-- روش ۱: hookmetamethod برای Raycast
local hookSuccess = false
local originalNamecall = nil

local function tryHookSilentAim()
    if hookSuccess then return true end
    
    local ok = pcall(function()
        if not hookmetamethod then error("no hookmetamethod") end
        
        originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if Settings.SilentAim.Enabled and silentTarget and silentTarget.part and silentTarget.part.Parent then
                -- Raycast hook
                if method == "Raycast" and self == Workspace then
                    local origin = args[1]
                    if origin then
                        local hitPos = silentTarget.part.Position
                        local direction = hitPos - origin
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = {LocalPlayer.Character}
                        return Workspace:Raycast(origin, direction, params)
                    end
                end
                
                -- FindPartOnRay hook
                if method == "FindPartOnRay" then
                    local ray = args[1]
                    if ray then
                        local hitPos = silentTarget.part.Position
                        local newRay = Ray.new(ray.Origin, hitPos - ray.Origin)
                        return originalNamecall and originalNamecall(self, newRay, unpack(args, 2)) or Workspace:FindPartOnRay(newRay)
                    end
                end
            end
            
            return originalNamecall(self, unpack(args))
        end)
    end)
    
    hookSuccess = ok
    return ok
end

-- روش ۲ fallback: تغییر Camera موقتاً وقتی shooting (برای بازی‌هایی که از camera direction استفاده می‌کنن)
local isSilentShooting = false

local function silentAimCameraHook()
    -- این کار نمی‌کنه به صورت hook چون روبlox client-side هست
    -- ولی می‌تونیم موقع aiming, camera رو briefly بچرخونیم
    -- این خیلی visible هست پس فقط fallback هست
end

-- روش ۳: تغییر mouse target
local function getSilentTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local mouseVec = Vector2.new(mousePos.X, mousePos.Y)
    local closest = nil
    local closestDist = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not (Settings.SilentAim.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team) then
                local char, humanoid, rootPart = getCharacter(player)
                if char then
                    local targetPart = getTargetPart(char, Settings.SilentAim.TargetPart)
                    if targetPart then
                        if Settings.SilentAim.AimBehindWall or not isWallBetween(targetPart, char) then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                            if onScreen then
                                local targetVec = Vector2.new(screenPos.X, screenPos.Y)
                                local dist = (targetVec - mouseVec).Magnitude
                                if dist <= Settings.SilentAim.FOV and dist < closestDist then
                                    closestDist = dist
                                    closest = {part = targetPart, char = char, player = player}
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

-- ═══════════ AIMBOT ═══════════
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Color = Settings.Aimbot.FOVColor
fovCircle.Visible = false
fovCircle.Radius = Settings.Aimbot.FOV
fovCircle.NumSides = 100

local silentFOVCircle = Drawing.new("Circle")
silentFOVCircle.Thickness = 1
silentFOVCircle.Filled = false
silentFOVCircle.Color = Settings.SilentAim.FOVColor
silentFOVCircle.Visible = false
silentFOVCircle.Radius = Settings.SilentAim.FOV
silentFOVCircle.NumSides = 80

local targetHighlight = Instance.new("Highlight")
targetHighlight.Name = "AdrianTarget"
targetHighlight.FillColor = Color3.fromRGB(147, 51, 234)
targetHighlight.FillTransparency = 0.75
targetHighlight.OutlineColor = Color3.fromRGB(200, 120, 255)
targetHighlight.OutlineTransparency = 0
targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
targetHighlight.Enabled = false
targetHighlight.Parent = game.CoreGui

local function getBestAimbotTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local mouseVec = Vector2.new(mousePos.X, mousePos.Y)
    local closest = nil
    local closestDist = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not (Settings.Aimbot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team) then
                local char, humanoid, rootPart = getCharacter(player)
                if char then
                    local targetPart = getTargetPart(char, Settings.Aimbot.TargetPart)
                    if targetPart then
                        if Settings.Aimbot.AimBehindWall or not isWallBetween(targetPart, char) then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                            if onScreen then
                                local targetVec = Vector2.new(screenPos.X, screenPos.Y)
                                local dist = (targetVec - mouseVec).Magnitude
                                if dist <= Settings.Aimbot.FOV and dist < closestDist then
                                    closestDist = dist
                                    closest = {part = targetPart, char = char, humanoid = humanoid, player = player}
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
    
    local targetPart = target.part
    local predictedPos = targetPart.Position
    
    if Settings.Aimbot.Prediction > 0 then
        local velocity = getVelocity(target.char)
        local dist = (Camera.CFrame.Position - targetPart.Position).Magnitude
        predictedPos = targetPart.Position + velocity * Settings.Aimbot.Prediction * (dist / 500) * 10
    end
    
    if Settings.Aimbot.Method == "Mouse" then
        local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
        if not onScreen then return end
        
        local mousePos = UserInputService:GetMouseLocation()
        local moveX = (screenPos.X - mousePos.X) / Settings.Aimbot.Smoothness
        local moveY = (screenPos.Y - mousePos.Y) / Settings.Aimbot.Smoothness
        moveX = clamp(moveX, -300, 300)
        moveY = clamp(moveY, -300, 300)
        
        pcall(function() mousemoverel(moveX, moveY) end)
        
    elseif Settings.Aimbot.Method == "Camera" then
        local currentCF = Camera.CFrame
        local lookCF = CFrame.lookAt(currentCF.Position, predictedPos)
        local alpha = clamp(1 / Settings.Aimbot.Smoothness, 0.02, 1)
        Camera.CFrame = currentCF:Lerp(lookCF, alpha)
    end
end

-- ═══════════ ESP ═══════════
local function createESPObjects(player)
    if espObjects[player] then return end
    
    local objs = {}
    
    pcall(function()
        objs.box = Drawing.new("Square")
        objs.box.Thickness = Settings.ESP.BoxThickness
        objs.box.Filled = false
        objs.box.Visible = false
        
        objs.cornerLines = {}
        for i = 1, 8 do
            local line = Drawing.new("Line")
            line.Thickness = Settings.ESP.BoxThickness + 1
            line.Visible = false
            objs.cornerLines[i] = line
        end
        
        objs.name = Drawing.new("Text")
        objs.name.Size = Settings.ESP.TextSize
        objs.name.Center = true
        objs.name.Outline = true
        objs.name.Color = Color3.fromRGB(255, 255, 255)
        objs.name.Visible = false
        
        objs.healthBG = Drawing.new("Square")
        objs.healthBG.Thickness = 0
        objs.healthBG.Filled = true
        objs.healthBG.Color = Color3.fromRGB(20, 20, 25)
        objs.healthBG.Visible = false
        
        objs.healthFill = Drawing.new("Square")
        objs.healthFill.Thickness = 0
        objs.healthFill.Filled = true
        objs.healthFill.Visible = false
        
        objs.distance = Drawing.new("Text")
        objs.distance.Size = Settings.ESP.TextSize - 1
        objs.distance.Center = true
        objs.distance.Outline = true
        objs.distance.Color = Color3.fromRGB(200, 200, 200)
        objs.distance.Visible = false
        
        objs.tracer = Drawing.new("Line")
        objs.tracer.Thickness = 1.5
        objs.tracer.Visible = false
        
        objs.weapon = Drawing.new("Text")
        objs.weapon.Size = Settings.ESP.TextSize - 2
        objs.weapon.Center = true
        objs.weapon.Outline = true
        objs.weapon.Visible = false
    end)
    
    objs.highlight = Instance.new("Highlight")
    objs.highlight.FillColor = Settings.ESP.ChamsColor
    objs.highlight.FillTransparency = Settings.ESP.ChamsTransparency
    objs.highlight.OutlineColor = Settings.ESP.BoxColor
    objs.highlight.OutlineTransparency = 0.2
    objs.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    objs.highlight.Enabled = false
    objs.highlight.Parent = game.CoreGui
    
    espObjects[player] = objs
end

local function removeESPObjects(player)
    local objs = espObjects[player]
    if not objs then return end
    pcall(function()
        for _, key in ipairs({"box", "name", "healthBG", "healthFill", "distance", "tracer", "weapon"}) do
            if objs[key] then objs[key]:Remove() end
        end
        for _, line in ipairs(objs.cornerLines or {}) do
            pcall(function() line:Remove() end)
        end
        if objs.highlight then objs.highlight:Destroy() end
    end)
    espObjects[player] = nil
end

local function hideESP(objs)
    pcall(function()
        if objs.box then objs.box.Visible = false end
        if objs.name then objs.name.Visible = false end
        if objs.healthBG then objs.healthBG.Visible = false end
        if objs.healthFill then objs.healthFill.Visible = false end
        if objs.distance then objs.distance.Visible = false end
        if objs.tracer then objs.tracer.Visible = false end
        if objs.weapon then objs.weapon.Visible = false end
        for _, line in ipairs(objs.cornerLines or {}) do
            line.Visible = false
        end
        if objs.highlight then objs.highlight.Enabled = false end
    end)
end

local function renderESP()
    for player, objs in pairs(espObjects) do
        local char, humanoid, rootPart = getCharacter(player)
        local teamBlocked = Settings.ESP.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
        
        if not Settings.ESP.Enabled or teamBlocked or not char then
            hideESP(objs)
            continue
        end
        
        local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
        if dist > Settings.ESP.MaxDistance then
            hideESP(objs)
            continue
        end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen then
            hideESP(objs)
            continue
        end
        
        local head = char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or rootPart
        local headScreen = Camera:WorldToViewportPoint(head.Position)
        local footScreen = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, rootPart.Size.Y * 0.5 + 1, 0))
        
        local boxY = headScreen.Y - (screenPos.Y - headScreen.Y) * 0.3
        local boxHeight = math.abs(footScreen.Y - boxY)
        local boxWidth = boxHeight * 0.65
        local boxX = screenPos.X - boxWidth / 2
        
        local hp = clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        local hpColor = hp > 0.5 and Color3.fromRGB(60, 220, 60) or (hp > 0.25 and Color3.fromRGB(220, 200, 40) or Color3.fromRGB(220, 50, 50))
        
        pcall(function()
            if Settings.ESP.Boxes then
                if Settings.ESP.BoxType == "Full" then
                    objs.box.Visible = true
                    objs.box.Position = Vector2.new(boxX, boxY)
                    objs.box.Size = Vector2.new(boxWidth, boxHeight)
                    objs.box.Color = Settings.ESP.BoxColor
                    objs.box.Thickness = Settings.ESP.BoxThickness
                    for _, l in ipairs(objs.cornerLines) do l.Visible = false end
                else
                    objs.box.Visible = false
                    local cornerLen = math.min(boxWidth, boxHeight) * 0.25
                    local corners = {
                        {Vector2.new(boxX, boxY), Vector2.new(boxX + cornerLen, boxY)},
                        {Vector2.new(boxX, boxY), Vector2.new(boxX, boxY + cornerLen)},
                        {Vector2.new(boxX + boxWidth, boxY), Vector2.new(boxX + boxWidth - cornerLen, boxY)},
                        {Vector2.new(boxX + boxWidth, boxY), Vector2.new(boxX + boxWidth, boxY + cornerLen)},
                        {Vector2.new(boxX, boxY + boxHeight), Vector2.new(boxX + cornerLen, boxY + boxHeight)},
                        {Vector2.new(boxX, boxY + boxHeight), Vector2.new(boxX, boxY + boxHeight - cornerLen)},
                        {Vector2.new(boxX + boxWidth, boxY + boxHeight), Vector2.new(boxX + boxWidth - cornerLen, boxY + boxHeight)},
                        {Vector2.new(boxX + boxWidth, boxY + boxHeight), Vector2.new(boxX + boxWidth, boxY + boxHeight - cornerLen)},
                    }
                    for i, c in ipairs(corners) do
                        objs.cornerLines[i].Visible = true
                        objs.cornerLines[i].From = c[1]
                        objs.cornerLines[i].To = c[2]
                        objs.cornerLines[i].Color = Settings.ESP.BoxColor
                    end
                end
            else
                objs.box.Visible = false
                for _, l in ipairs(objs.cornerLines) do l.Visible = false end
            end
            
            if Settings.ESP.Names then
                objs.name.Visible = true
                objs.name.Text = player.DisplayName
                objs.name.Position = Vector2.new(screenPos.X, boxY - 16)
            else
                objs.name.Visible = false
            end
            
            if Settings.ESP.Health then
                if Settings.ESP.HealthType == "Left" then
                    objs.healthBG.Visible = true
                    objs.healthBG.Position = Vector2.new(boxX - 7, boxY)
                    objs.healthBG.Size = Vector2.new(4, boxHeight)
                    local fillH = boxHeight * hp
                    objs.healthFill.Visible = true
                    objs.healthFill.Position = Vector2.new(boxX - 6, boxY + (boxHeight - fillH))
                    objs.healthFill.Size = Vector2.new(2, fillH)
                    objs.healthFill.Color = hpColor
                else
                    objs.healthBG.Visible = true
                    objs.healthBG.Position = Vector2.new(boxX, boxY + boxHeight + 14)
                    objs.healthBG.Size = Vector2.new(boxWidth, 4)
                    local fillW = boxWidth * hp
                    objs.healthFill.Visible = true
                    objs.healthFill.Position = Vector2.new(boxX, boxY + boxHeight + 14)
                    objs.healthFill.Size = Vector2.new(fillW, 2)
                    objs.healthFill.Color = hpColor
                end
            else
                objs.healthBG.Visible = false
                objs.healthFill.Visible = false
            end
            
            if Settings.ESP.Distance then
                objs.distance.Visible = true
                objs.distance.Text = math.floor(dist) .. "m"
                objs.distance.Position = Vector2.new(screenPos.X, boxY + boxHeight + 2)
            else
                objs.distance.Visible = false
            end
            
            if Settings.ESP.Tracers then
                objs.tracer.Visible = true
                objs.tracer.Color = Settings.ESP.TracerColor
                local origin
                if Settings.ESP.TracerOrigin == "Bottom" then
                    origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                elseif Settings.ESP.TracerOrigin == "Center" then
                    origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                else
                    local mp = UserInputService:GetMouseLocation()
                    origin = Vector2.new(mp.X, mp.Y)
                end
                objs.tracer.From = origin
                objs.tracer.To = Vector2.new(screenPos.X, boxY + boxHeight)
            else
                objs.tracer.Visible = false
            end
            
            if Settings.ESP.ToolESP then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    objs.weapon.Visible = true
                    objs.weapon.Text = tool.Name
                    objs.weapon.Position = Vector2.new(screenPos.X, boxY + boxHeight + 14)
                    objs.weapon.Color = Color3.fromRGB(255, 200, 0)
                else
                    objs.weapon.Visible = false
                end
            else
                objs.weapon.Visible = false
            end
            
            if Settings.ESP.Chams then
                objs.highlight.Enabled = true
                objs.highlight.Adornee = char
                objs.highlight.FillColor = Settings.ESP.ChamsColor
                objs.highlight.FillTransparency = Settings.ESP.ChamsTransparency
            else
                objs.highlight.Enabled = false
            end
        end)
    end
end

-- ═══════════ VISUALS ═══════════
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
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
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
for i = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Visible = false
    crosshairLines[i] = line
end

local function renderCrosshair()
    if Settings.Visuals.Crosshair then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local size = Settings.Visuals.CrosshairSize
        local gap = Settings.Visuals.CrosshairGap
        
        local positions = {
            {Vector2.new(center.X - size - gap, center.Y), Vector2.new(center.X - gap, center.Y)},
            {Vector2.new(center.X + gap, center.Y), Vector2.new(center.X + size + gap, center.Y)},
            {Vector2.new(center.X, center.Y - size - gap), Vector2.new(center.X, center.Y - gap)},
            {Vector2.new(center.X, center.Y + gap), Vector2.new(center.X, center.Y + size + gap)},
        }
        for i, pos in ipairs(positions) do
            crosshairLines[i].Visible = true
            crosshairLines[i].From = pos[1]
            crosshairLines[i].To = pos[2]
            crosshairLines[i].Color = Settings.Visuals.CrosshairColor
        end
    else
        for _, line in ipairs(crosshairLines) do
            line.Visible = false
        end
    end
end

-- ═══════════ MISC ═══════════
local infJumpConn, antiAfkConn, noclipConn, flyConn = nil, nil, nil, nil
local bodyVelocity, bodyGyro = nil, nil
local flying = false

local function stopFly()
    flying = false
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
end

local function applyMisc()
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if Settings.Misc.InfiniteJump then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end
    
    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
    if Settings.Misc.AntiAFK then
        antiAfkConn = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
    
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if Settings.Misc.NoClip then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
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
            bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.Parent = root
            
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
            bodyGyro.P = 10000
            bodyGyro.D = 500
            bodyGyro.Parent = root
            
            flyConn = RunService.RenderStepped:Connect(function()
                if not flying or not bodyVelocity then return end
                local speed = Settings.Misc.FlySpeed
                local moveVec = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec = moveVec - Vector3.new(0, 1, 0) end
                bodyVelocity.Velocity = moveVec * speed
                if bodyGyro then bodyGyro.CFrame = Camera.CFrame end
            end)
        end
    else
        stopFly()
    end
end

-- ═══════════ UI ═══════════
local Accent = Color3.fromRGB(147, 51, 234)
local BG = Color3.fromRGB(8, 8, 12)
local Sidebar_bg = Color3.fromRGB(12, 12, 18)
local Element = Color3.fromRGB(20, 20, 28)
local ElementHover = Color3.fromRGB(28, 28, 38)
local TextColor = Color3.fromRGB(235, 235, 245)
local SubText = Color3.fromRGB(130, 130, 155)
local Stroke = Color3.fromRGB(35, 35, 50)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdrianCheatV11"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

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
MainStroke.Color = Stroke
MainStroke.Thickness = 1.5
MainStroke.Parent = Main

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Sidebar_bg
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 14)
TitleCorner.Parent = TitleBar

local TitleCover = Instance.new("Frame")
TitleCover.Size = UDim2.new(1, 0, 0, 28)
TitleCover.Position = UDim2.new(0, 0, 1, -28)
TitleCover.BackgroundColor3 = Sidebar_bg
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
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.TextSize = 18
LogoText.Font = Enum.Font.GothamBold
LogoText.Parent = Logo

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 300, 1, 0)
TitleText.Position = UDim2.new(0, 55, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "ADRIAN RIVALS"
TitleText.TextColor3 = TextColor
TitleText.TextSize = 15
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, 40, 1, 0)
VersionLabel.Position = UDim2.new(0, 195, 0, 0)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "v1.1"
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
DevLabel.TextColor3 = SubText
DevLabel.TextSize = 11
DevLabel.Font = Enum.Font.Gotham
DevLabel.TextXAlignment = Enum.TextXAlignment.Right
DevLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
Sidebar.BackgroundColor3 = Sidebar_bg
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local tabs = {}
local currentTab = nil

local function createTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 36)
    btn.Position = UDim2.new(0, 8, 0, 8 + (order - 1) * 42)
    btn.BackgroundColor3 = Element
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
    textLabel.TextColor3 = SubText
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
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 2)
    accentCorner.Parent = accentBar
    
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
    
    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingLeft = UDim.new(0, 8)
    pagePadding.PaddingRight = UDim.new(0, 12)
    pagePadding.PaddingTop = UDim.new(0, 4)
    pagePadding.Parent = page
    
    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 4)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page
    
    local tab = {button = btn, page = page, name = name, accentBar = accentBar, textLabel = textLabel}
    tabs[name] = tab
    
    btn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)
    
    return page
end

function selectTab(name)
    local tab = tabs[name]
    if not tab then return end
    for tabName, t in pairs(tabs) do
        t.page.Visible = false
        t.button.BackgroundColor3 = Element
        t.accentBar.Visible = false
        t.textLabel.TextColor3 = SubText
    end
    tab.page.Visible = true
    tab.button.BackgroundColor3 = Color3.fromRGB(25, 18, 40)
    tab.accentBar.Visible = true
    tab.textLabel.TextColor3 = Accent
    currentTab = name
end

-- UI Elements
local function createSection(page, title)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = #page:GetChildren()
    frame.Parent = page
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = Stroke
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
    frame.BackgroundColor3 = Element
    frame.Text = ""
    frame.BorderSizePixel = 0
    frame.AutoButtonColor = false
    frame.LayoutOrder = #page:GetChildren()
    frame.Parent = page
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Stroke
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = TextColor
    label.TextSize = 12
    label.Parent = frame
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 36, 0, 18)
    toggleBg.Position = UDim2.new(1, -46, 0.5, -9)
    toggleBg.BackgroundColor3 = enabled and Accent or Color3.fromRGB(40, 40, 55)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBg
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    frame.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(toggleBg, TweenInfo.new(0.15), {
            BackgroundColor3 = enabled and Accent or Color3.fromRGB(40, 40, 55)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
        callback(enabled)
    end)
    
    return frame
end

local function createSlider(page, name, min, max, default, decimals, callback)
    local value = default
    local dragging = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = Element
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
    label.TextColor3 = TextColor
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
    sliderBack.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
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
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
        local relative = clamp((inputPos.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        value = min + (max - min) * relative
        value = math.floor(value * (10 ^ decimals) + 0.5) / (10 ^ decimals)
        sliderFill.Size = UDim2.new(relative, 0, 1, 0)
        knob.Position = UDim2.new(relative, -7, 0.5, -7)
        valueLabel.Text = string.format("%." .. decimals .. "f", value)
        callback(value)
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
    local selected = default
    local isOpen = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Element
    frame.BorderSizePixel = 0
    frame.LayoutOrder = #page:GetChildren()
    frame.ClipsDescendants = true
    frame.Parent = page
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 32)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = TextColor
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(0.35, 0, 0, 32)
    selectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = selected
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
    arrow.TextColor3 = SubText
    arrow.TextSize = 9
    arrow.Parent = frame
    
    local optionsContainer = Instance.new("Frame")
    optionsContainer.Size = UDim2.new(1, -8, 0, #options * 26)
    optionsContainer.Position = UDim2.new(0, 4, 0, 36)
    optionsContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
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
        optBtn.Position = UDim2.new(0, 2, 0, 2 + (i-1) * 26)
        optBtn.BackgroundColor3 = option == selected and Color3.fromRGB(30, 20, 45) or Color3.fromRGB(20, 20, 30)
        optBtn.Text = "  " .. option
        optBtn.TextColor3 = option == selected and Accent or SubText
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
            selected = option
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
        frame.Size = isOpen and UDim2.new(1, 0, 0, 40 + #options * 26) or UDim2.new(1, 0, 0, 32)
    end)
    
    return frame
end

-- ═══════════ BUILD PAGES ═══════════

-- AIMBOT
local aimbotPage = createTab("Aimbot", "🎯", 1)

createSection(aimbotPage, "aimbot core")
createToggle(aimbotPage, "Enable Aimbot", Settings.Aimbot.Enabled, function(v) Settings.Aimbot.Enabled = v end)
createDropdown(aimbotPage, "Aim Method", {"Mouse", "Camera"}, "Mouse", function(v) Settings.Aimbot.Method = v end)
createDropdown(aimbotPage, "Target Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "Head", function(v) Settings.Aimbot.TargetPart = v end)

createSection(aimbotPage, "aim settings")
createSlider(aimbotPage, "FOV", 20, 500, Settings.Aimbot.FOV, 0, function(v) Settings.Aimbot.FOV = v fovCircle.Radius = v end)
createSlider(aimbotPage, "Smoothness", 1, 20, Settings.Aimbot.Smoothness, 1, function(v) Settings.Aimbot.Smoothness = v end)
createSlider(aimbotPage, "Prediction", 0, 1, Settings.Aimbot.Prediction, 2, function(v) Settings.Aimbot.Prediction = v end)

createSection(aimbotPage, "checks")
createToggle(aimbotPage, "Show FOV", Settings.Aimbot.ShowFOV, function(v) Settings.Aimbot.ShowFOV = v end)
createToggle(aimbotPage, "Team Check", Settings.Aimbot.TeamCheck, function(v) Settings.Aimbot.TeamCheck = v end)
createToggle(aimbotPage, "Aim Through Wall", Settings.Aimbot.AimBehindWall, function(v) Settings.Aimbot.AimBehindWall = v end)
createToggle(aimbotPage, "Highlight Target", Settings.Aimbot.HighlightTarget, function(v) Settings.Aimbot.HighlightTarget = v end)

-- SILENT AIM
local silentPage = createTab("Silent Aim", "🔇", 2)

createSection(silentPage, "silent aim")
createToggle(silentPage, "Enable Silent Aim", Settings.SilentAim.Enabled, function(v)
    Settings.SilentAim.Enabled = v
    if v then tryHookSilentAim() end
end)

createSection(silentPage, "silent settings")
createDropdown(silentPage, "Target Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "Head", function(v) Settings.SilentAim.TargetPart = v end)
createSlider(silentPage, "FOV", 20, 500, Settings.SilentAim.FOV, 0, function(v) Settings.SilentAim.FOV = v silentFOVCircle.Radius = v end)

createSection(silentPage, "silent checks")
createToggle(silentPage, "Show FOV", Settings.SilentAim.ShowFOV, function(v) Settings.SilentAim.ShowFOV = v end)
createToggle(silentPage, "Team Check", Settings.SilentAim.TeamCheck, function(v) Settings.SilentAim.TeamCheck = v end)
createToggle(silentPage, "Shoot Through Wall", Settings.SilentAim.AimBehindWall, function(v) Settings.SilentAim.AimBehindWall = v end)

local silentInfo = Instance.new("Frame")
silentInfo.Size = UDim2.new(1, 0, 0, 60)
silentInfo.BackgroundColor3 = Element
silentInfo.BorderSizePixel = 0
silentInfo.LayoutOrder = #silentPage:GetChildren()
silentInfo.Parent = silentPage

local silentInfoCorner = Instance.new("UICorner")
silentInfoCorner.CornerRadius = UDim.new(0, 8)
silentInfoCorner.Parent = silentInfo

local silentInfoText = Instance.new("TextLabel")
silentInfoText.Size = UDim2.new(1, -16, 1, -8)
silentInfoText.Position = UDim2.new(0, 8, 0, 4)
silentInfoText.BackgroundTransparency = 1
silentInfoText.Text = "ℹ دشمن تو FOV نارنجی باشه = گلوله می‌خوره\nحتی اگه crosshair جای دیگه‌ست یا دیواره"
silentInfoText.TextColor3 = SubText
silentInfoText.TextSize = 11
silentInfoText.Font = Enum.Font.Gotham
silentInfoText.TextXAlignment = Enum.TextXAlignment.Left
silentInfoText.TextYAlignment = Enum.TextYAlignment.Center
silentInfoText.Parent = silentInfo

-- TRIGGER BOT
local triggerPage = createTab("Trigger Bot", "🔫", 3)

createSection(triggerPage, "trigger bot")
createToggle(triggerPage, "Enable Trigger Bot", Settings.TriggerBot.Enabled, function(v) Settings.TriggerBot.Enabled = v end)
createSlider(triggerPage, "Reaction Delay", 0.05, 1, Settings.TriggerBot.Delay, 2, function(v) Settings.TriggerBot.Delay = v end)
createSlider(triggerPage, "Range", 50, 1000, Settings.TriggerBot.Range, 0, function(v) Settings.TriggerBot.Range = v end)

createSection(triggerPage, "trigger checks")
createToggle(triggerPage, "Team Check", Settings.TriggerBot.TeamCheck, function(v) Settings.TriggerBot.TeamCheck = v end)
createToggle(triggerPage, "Check Walls", Settings.TriggerBot.CheckWalls, function(v) Settings.TriggerBot.CheckWalls = v end)

local triggerInfo = Instance.new("Frame")
triggerInfo.Size = UDim2.new(1, 0, 0, 60)
triggerInfo.BackgroundColor3 = Element
triggerInfo.BorderSizePixel = 0
triggerInfo.LayoutOrder = #triggerPage:GetChildren()
triggerInfo.Parent = triggerPage

local triggerInfoCorner = Instance.new("UICorner")
triggerInfoCorner.CornerRadius = UDim.new(0, 8)
triggerInfoCorner.Parent = triggerInfo

local triggerInfoText = Instance.new("TextLabel")
triggerInfoText.Size = UDim2.new(1, -16, 1, -8)
triggerInfoText.Position = UDim2.new(0, 8, 0, 4)
triggerInfoText.BackgroundTransparency = 1
triggerInfoText.Text = "ℹ وقتی crosshair روی دشمنه خودکار شلیک می‌کنه\nDelay کم = سریع‌تر ولی خطرناک‌تر"
triggerInfoText.TextColor3 = SubText
triggerInfoText.TextSize = 11
triggerInfoText.Font = Enum.Font.Gotham
triggerInfoText.TextXAlignment = Enum.TextXAlignment.Left
triggerInfoText.TextYAlignment = Enum.TextYAlignment.Center
triggerInfoText.Parent = triggerInfo

-- ESP
local espPage = createTab("ESP", "👁", 4)

createSection(espPage, "esp main")
createToggle(espPage, "Enable ESP", Settings.ESP.Enabled, function(v) Settings.ESP.Enabled = v end)
createDropdown(espPage, "Box Style", {"Corner", "Full"}, "Corner", function(v) Settings.ESP.BoxType = v end)
createSlider(espPage, "Box Thickness", 1, 5, Settings.ESP.BoxThickness, 1, function(v) Settings.ESP.BoxThickness = v end)
createSlider(espPage, "Max Distance", 100, 5000, Settings.ESP.MaxDistance, 0, function(v) Settings.ESP.MaxDistance = v end)

createSection(espPage, "esp elements")
createToggle(espPage, "Boxes", Settings.ESP.Boxes, function(v) Settings.ESP.Boxes = v end)
createToggle(espPage, "Names", Settings.ESP.Names, function(v) Settings.ESP.Names = v end)
createToggle(espPage, "Health Bar", Settings.ESP.Health, function(v) Settings.ESP.Health = v end)
createDropdown(espPage, "Health Position", {"Left", "Bottom"}, "Left", function(v) Settings.ESP.HealthType = v end)
createToggle(espPage, "Distance", Settings.ESP.Distance, function(v) Settings.ESP.Distance = v end)
createToggle(espPage, "Tool ESP", Settings.ESP.ToolESP, function(v) Settings.ESP.ToolESP = v end)

createSection(espPage, "tracers")
createToggle(espPage, "Tracers", Settings.ESP.Tracers, function(v) Settings.ESP.Tracers = v end)
createDropdown(espPage, "Tracer Origin", {"Bottom", "Center", "Mouse"}, "Bottom", function(v) Settings.ESP.TracerOrigin = v end)

createSection(espPage, "chams")
createToggle(espPage, "Chams (Wall Hack)", Settings.ESP.Chams, function(v) Settings.ESP.Chams = v end)
createSlider(espPage, "Transparency", 0, 1, Settings.ESP.ChamsTransparency, 1, function(v) Settings.ESP.ChamsTransparency = v end)

createSection(espPage, "checks")
createToggle(espPage, "Team Check", Settings.ESP.TeamCheck, function(v) Settings.ESP.TeamCheck = v end)

-- VISUALS
local visualsPage = createTab("Visuals", "🎨", 5)

createSection(visualsPage, "world")
createToggle(visualsPage, "Fullbright", Settings.Visuals.Fullbright, function(v) Settings.Visuals.Fullbright = v applyVisuals() end)
createToggle(visualsPage, "No Fog", Settings.Visuals.NoFog, function(v) Settings.Visuals.NoFog = v applyVisuals() end)

createSection(visualsPage, "crosshair")
createToggle(visualsPage, "Custom Crosshair", Settings.Visuals.Crosshair, function(v) Settings.Visuals.Crosshair = v end)
createSlider(visualsPage, "Crosshair Size", 2, 30, Settings.Visuals.CrosshairSize, 0, function(v) Settings.Visuals.CrosshairSize = v end)
createSlider(visualsPage, "Crosshair Gap", 0, 15, Settings.Visuals.CrosshairGap, 0, function(v) Settings.Visuals.CrosshairGap = v end)

-- MISC
local miscPage = createTab("Misc", "⚡", 6)

createSection(miscPage, "movement")
createToggle(miscPage, "Infinite Jump", Settings.Misc.InfiniteJump, function(v) Settings.Misc.InfiniteJump = v applyMisc() end)
createToggle(miscPage, "NoClip", Settings.Misc.NoClip, function(v) Settings.Misc.NoClip = v applyMisc() end)
createToggle(miscPage, "Fly", Settings.Misc.Fly, function(v) Settings.Misc.Fly = v applyMisc() end)
createSlider(miscPage, "Fly Speed", 10, 200, Settings.Misc.FlySpeed, 0, function(v) Settings.Misc.FlySpeed = v end)

createSection(miscPage, "speed & jump")
createToggle(miscPage, "Custom Walk Speed", Settings.Misc.SpeedEnabled, function(v)
    Settings.Misc.SpeedEnabled = v
    if not v then
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 16 end
        end
    end
end)
createSlider(miscPage, "Walk Speed", 16, 250, 16, 0, function(v)
    Settings.Misc.SpeedValue = v
    if Settings.Misc.SpeedEnabled then
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v end
        end
    end
end)

createToggle(miscPage, "Custom Jump Power", Settings.Misc.JumpEnabled, function(v)
    Settings.Misc.JumpEnabled = v
    if not v then
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then
                h.UseJumpPower = true
                h.JumpPower = 50
            end
        end
    end
end)
createSlider(miscPage, "Jump Power", 50, 300, 50, 0, function(v)
    Settings.Misc.JumpValue = v
    if Settings.Misc.JumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then
                h.UseJumpPower = true
                h.JumpPower = v
            end
        end
    end
end)

createSection(miscPage, "other")
createToggle(miscPage, "Anti AFK", Settings.Misc.AntiAFK, function(v) Settings.Misc.AntiAFK = v applyMisc() end)

-- SETTINGS
local settingsPage = createTab("Settings", "⚙", 7)

createSection(settingsPage, "info")
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, 0, 0, 100)
infoFrame.BackgroundColor3 = Element
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
infoText.Text = "Adrian Rivals Cheat v1.1\nDeveloper: MR Adrian\n\nUI Toggle: Right Shift\nAimbot: Right Click (Hold)\nFly: WASD + Space/Ctrl"
infoText.TextColor3 = SubText
infoText.TextSize = 11
infoText.Font = Enum.Font.Gotham
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.Parent = infoFrame

createSection(settingsPage, "danger zone")
local unloadBtn = Instance.new("TextButton")
unloadBtn.Size = UDim2.new(1, 0, 0, 36)
unloadBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
unloadBtn.Text = "☠  UNLOAD CHEAT"
unloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    pcall(function() fovCircle:Remove() end)
    pcall(function() silentFOVCircle:Remove() end)
    pcall(function() targetHighlight:Destroy() end)
    for _, line in ipairs(crosshairLines) do pcall(function() line:Remove() end) end
    for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
    if infJumpConn then infJumpConn:Disconnect() end
    if antiAfkConn then antiAfkConn:Disconnect() end
    if noclipConn then noclipConn:Disconnect() end
    if flyConn then flyConn:Disconnect() end
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

-- ═══════════ INPUT ═══════════
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
    pcall(function() fovCircle:Remove() end)
    pcall(function() silentFOVCircle:Remove() end)
    pcall(function() targetHighlight:Destroy() end)
    for _, line in ipairs(crosshairLines) do pcall(function() line:Remove() end) end
    stopFly()
    ScreenGui:Destroy()
end)

-- ═══════════ PLAYERS ═══════════
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

-- ═══════════ MAIN LOOP ═══════════
table.insert(connections, RunService.RenderStepped:Connect(function()
    pcall(function()
        -- ═══ TRIGGER BOT (FIXED) ═══
        if Settings.TriggerBot.Enabled then
            local now = tick()
            if now - lastTrigger >= Settings.TriggerBot.Delay then
                local targetPlayer = getTriggerTarget()
                if targetPlayer then
                    lastTrigger = now
                    doTriggerShoot()
                end
            end
        end
        
        -- ═══ SILENT AIM TARGET ═══
        if Settings.SilentAim.Enabled then
            silentTarget = getSilentTarget()
        else
            silentTarget = nil
        end
        
        -- ═══ AIMBOT ═══
        if Settings.Aimbot.Enabled and aiming then
            currentTarget = getBestAimbotTarget()
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
        
        -- ═══ FOV CIRCLES ═══
        if Settings.Aimbot.Enabled and Settings.Aimbot.ShowFOV then
            local mp = UserInputService:GetMouseLocation()
            fovCircle.Position = Vector2.new(mp.X, mp.Y)
            fovCircle.Radius = Settings.Aimbot.FOV
            fovCircle.Visible = true
        else
            fovCircle.Visible = false
        end
        
        if Settings.SilentAim.Enabled and Settings.SilentAim.ShowFOV then
            local mp = UserInputService:GetMouseLocation()
            silentFOVCircle.Position = Vector2.new(mp.X, mp.Y)
            silentFOVCircle.Radius = Settings.SilentAim.FOV
            silentFOVCircle.Color = Settings.SilentAim.FOVColor
            silentFOVCircle.Visible = true
        else
            silentFOVCircle.Visible = false
        end
        
        -- ═══ ESP + CROSSHAIR ═══
        renderESP()
        renderCrosshair()
        
        -- ═══ SPEED/JUMP ═══
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
                if h then
                    h.UseJumpPower = true
                    h.JumpPower = Settings.Misc.JumpValue
                end
            end
        end
    end)
end))

print("[Adrian Rivals Cheat v1.1] Loaded!")
print("[Adrian] Right Shift = UI | Right Click = Aim")

-- LITE MAX v4: POTATO NO-LAG + SPEED + FLY/NOCLIP + INFINITE JUMP + ESP (client-side)
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local lp = Players.LocalPlayer
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local CFG = {
    FpsCap = 120,
    HidePlayers = true,
    MuteSounds = false,
    KillWorldGuis = true,
    HideCoreUI = false,
}

local state = {
    speed = false, speedValue = 50,
    fly = false, flySpeed = 60,
    infJump = false,
    up = false, down = false,
}

---------------------------------------------------------------- NO LAG
local kill = {}
for _, c in ipairs({
    "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Explosion",
    "Highlight", "PointLight", "SpotLight", "SurfaceLight", "ForceField",
    "BloomEffect", "BlurEffect", "SunRaysEffect", "DepthOfFieldEffect",
    "ColorCorrectionEffect", "Atmosphere", "Sky", "Clouds",
    "SelectionBox", "SelectionSphere", "PostEffect", "LensFlare",
    "Fire", "Smoke", "Sparkles", "ParticleEmitter",
}) do kill[c] = true end

local texCls = { Decal = true, Texture = true, SurfaceAppearance = true }

pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04 end)
pcall(function() settings().Rendering.EagerBulkExecution = true end)
pcall(function() settings().Physics.AllowSleep = true end)
pcall(function() settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Skip2 end)
pcall(function() SoundService.AmbientReverb = Enum.ReverbType.NoReverb end)
pcall(function() SoundService.RespectFilteringEnabled = true end)
if setfpscap then pcall(setfpscap, CFG.FpsCap) end

if CFG.MuteSounds then pcall(function() SoundService.Volume = 0 end) end
if CFG.HideCoreUI then
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
end

local function applyLighting()
    Lighting.GlobalShadows = false
    Lighting.FogStart = 9e9
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 2
    Lighting.ExposureCompensation = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.Ambient = Color3.fromRGB(170, 170, 170)
    Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
    pcall(function() Lighting.ShadowSoftness = 0 end)
    pcall(function() Lighting.Technology = Enum.Technology.Compatibility end)
    for _, o in ipairs(Lighting:GetChildren()) do
        if kill[o.ClassName] or o:IsA("PostEffect") then
            pcall(function() o:Destroy() end)
        end
    end
end

local function applyTerrain()
    if not Terrain then return end
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 1
    pcall(function() Terrain.Decoration = false end)
end

applyLighting()
applyTerrain()

local function charOwner(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    while model do
        local plr = Players:GetPlayerFromCharacter(model)
        if plr then return plr end
        model = model:FindFirstAncestorOfClass("Model")
    end
end

local function optimize(o)
    local owner = charOwner(o)
    local isOwn = owner == lp
    local isOther = owner and not isOwn

    if isOther and CFG.HidePlayers then
        if o:IsA("BasePart") then
            o.LocalTransparencyModifier = 1
            o.CastShadow = false
        elseif o:IsA("Accessory") or o:IsA("Clothing") or o:IsA("ShirtGraphic")
            or o:IsA("BillboardGui") or o:IsA("SurfaceGui") or o:IsA("Animator")
            or kill[o.ClassName] or texCls[o.ClassName] then
            pcall(function() o:Destroy() end)
        end
        return
    end

    if o:IsA("BasePart") then
        o.Material = Enum.Material.SmoothPlastic
        o.Reflectance = 0
        o.CastShadow = false
        if o:IsA("MeshPart") then
            pcall(function() o.RenderFidelity = Enum.RenderFidelity.Performance end)
            if not isOwn then pcall(function() o.TextureID = "" end) end
        end
    elseif kill[o.ClassName] then
        pcall(function() o:Destroy() end)
    elseif texCls[o.ClassName] and not isOwn then
        pcall(function() o:Destroy() end)
    elseif o:IsA("SpecialMesh") and not isOwn then
        pcall(function() o.TextureId = "" end)
    elseif CFG.KillWorldGuis and (o:IsA("SurfaceGui") or (o:IsA("BillboardGui") and not isOwn)) then
        pcall(function() o:Destroy() end)
    elseif CFG.MuteSounds and o:IsA("Sound") then
        pcall(function() o:Destroy() end)
    end
end

local function processAll(root)
    local n = 0
    for _, o in ipairs(root:GetDescendants()) do
        pcall(optimize, o)
        n += 1
        if n % 250 == 0 then task.wait() end
    end
end

task.spawn(function()
    processAll(Lighting)
    processAll(Workspace)
end)

Workspace.DescendantAdded:Connect(function(o) task.defer(pcall, optimize, o) end)
Lighting.DescendantAdded:Connect(function(o) task.defer(pcall, optimize, o) end)

local function setCharHidden(char, hidden)
    for _, o in ipairs(char:GetDescendants()) do
        if o:IsA("BasePart") then
            o.LocalTransparencyModifier = hidden and 1 or 0
        end
    end
end

local function watchPlayer(plr)
    if plr == lp then return end
    local function onChar(char)
        task.wait(0.3)
        if CFG.HidePlayers then
            for _, o in ipairs(char:GetDescendants()) do pcall(optimize, o) end
        end
        char.DescendantAdded:Connect(function(o) task.defer(pcall, optimize, o) end)
    end
    if plr.Character then task.spawn(onChar, plr.Character) end
    plr.CharacterAdded:Connect(onChar)
end

for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)

task.spawn(function()
    while true do
        task.wait(3)
        applyLighting()
        applyTerrain()
        if CFG.HidePlayers then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    setCharHidden(plr.Character, true)
                end
            end
        end
    end
end)

---------------------------------------------------------------- GUI
local parent = (gethui and gethui()) or lp:WaitForChild("PlayerGui")
for _, n in ipairs({ "LiteMaxMenu", "LiteMaxBlack" }) do
    local old = parent:FindFirstChild(n)
    if old then old:Destroy() end
end

local blackGui = Instance.new("ScreenGui")
blackGui.Name = "LiteMaxBlack"
blackGui.ResetOnSpawn = false
blackGui.IgnoreGuiInset = true
blackGui.DisplayOrder = 1
blackGui.Parent = parent

local blackFrame = Instance.new("Frame")
blackFrame.Size = UDim2.new(1, 0, 1, 0)
blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
blackFrame.BorderSizePixel = 0
blackFrame.Active = false
blackFrame.Visible = false
blackFrame.Parent = blackGui

local gui = Instance.new("ScreenGui")
gui.Name = "LiteMaxMenu"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = parent

local FULL_H = 345
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 230, 0, FULL_H)
main.Position = UDim2.new(0, 10, 0.15, 0)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
title.BorderSizePixel = 0
title.Text = "  Lite Max v4 | FPS: --"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -28, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
minBtn.BorderSizePixel = 0
minBtn.Text = "-"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.Parent = main
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -28)
body.Position = UDim2.new(0, 0, 0, 28)
body.BackgroundTransparency = 1
body.Parent = main

minBtn.MouseButton1Click:Connect(function()
    body.Visible = not body.Visible
    main.Size = body.Visible and UDim2.new(0, 230, 0, FULL_H) or UDim2.new(0, 230, 0, 28)
    minBtn.Text = body.Visible and "-" or "+"
end)

do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local green, red = Color3.fromRGB(35, 90, 45), Color3.fromRGB(70, 35, 35)

local function makeToggle(text, y, default, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.Parent = body
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local on = default
    local function refresh()
        b.Text = text .. (on and ": ON" or ": OFF")
        b.BackgroundColor3 = on and green or red
    end
    refresh()
    b.MouseButton1Click:Connect(function()
        on = not on
        refresh()
        callback(on)
    end)
end

local function makeInput(labelText, y, default, callback)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 90, 0, 26)
    l.Position = UDim2.new(0, 10, 0, y)
    l.BackgroundTransparency = 1
    l.Text = labelText
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.Parent = body

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 100, 0, 26)
    box.Position = UDim2.new(1, -110, 0, y)
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = body
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            n = math.clamp(n, 1, 500)
            box.Text = tostring(n)
            callback(n)
        else
            box.Text = tostring(default)
        end
    end)
end

local function makeHoldButton(text, pos, key)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 60, 0, 60)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    b.BackgroundTransparency = 0.3
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 22
    b.Visible = false
    b.Parent = gui
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            state[key] = true
        end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            state[key] = false
        end
    end)
    return b
end

local upBtn = makeHoldButton("▲", UDim2.new(1, -80, 0.55, 0), "up")
local downBtn = makeHoldButton("▼", UDim2.new(1, -80, 0.55, 70), "down")

---------------------------------------------------------------- FLY + NOCLIP
local bv, bg
local charParts = {}

local function cacheParts(char)
    charParts = {}
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(charParts, p) end
    end
end

local function getParts()
    local char = lp.Character
    if not char then return end
    return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function startFly()
    local root, hum = getParts()
    if not root or not hum or bv then return end
    cacheParts(lp.Character)
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 9e4
    bg.CFrame = root.CFrame
    bg.Parent = root
    hum.PlatformStand = true
end

local function stopFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    local _, hum = getParts()
    if hum then hum.PlatformStand = false end
    state.up, state.down = false, false
end

RunService.Stepped:Connect(function()
    if state.fly then
        for i = 1, #charParts do
            local p = charParts[i]
            if p.Parent and p.CanCollide then p.CanCollide = false end
        end
    end
end)

---------------------------------------------------------------- XoXo ESP MODULE
do
    local _xesp_Players     = Players
    local _xesp_RunService  = RunService
    local _xesp_Workspace   = Workspace

    local _xesp_CFG = {
        Enabled   = true,
        TeamCheck = false,
        BoxColor  = Color3.fromRGB(255, 0, 80),
        NameColor = Color3.fromRGB(255, 255, 255),
        ShowBox   = true,
        ShowName  = true,
        ShowDist  = true,
        MaxDist   = 1000,
    }

    local _xesp_parent = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

    local _xesp_folder = Instance.new("Folder")
    _xesp_folder.Name = "XoXoESP_"..tostring(math.random(1000,9999))
    _xesp_folder.Parent = _xesp_parent

    local _xesp_cache = {}

    local function _xesp_build(plr)
        if plr == lp or _xesp_cache[plr] then return end

        local hl = Instance.new("Highlight")
        hl.FillColor           = _xesp_CFG.BoxColor
        hl.OutlineColor        = Color3.new(1,1,1)
        hl.FillTransparency    = 0.6
        hl.OutlineTransparency = 0
        hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent              = _xesp_folder

        local bb = Instance.new("BillboardGui")
        bb.Size        = UDim2.new(0, 160, 0, 36)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = _xesp_CFG.MaxDist
        bb.Parent      = _xesp_folder

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                   = UDim2.new(1,0,0.55,0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextColor3             = _xesp_CFG.NameColor
        nameLbl.TextStrokeTransparency = 0
        nameLbl.TextStrokeColor3       = Color3.new(0,0,0)
        nameLbl.TextScaled             = true
        nameLbl.Font                   = Enum.Font.GothamBold
        nameLbl.Parent                 = bb

        local infoLbl = Instance.new("TextLabel")
        infoLbl.Size                   = UDim2.new(1,0,0.45,0)
        infoLbl.Position               = UDim2.new(0,0,0.55,0)
        infoLbl.BackgroundTransparency = 1
        infoLbl.TextColor3             = _xesp_CFG.BoxColor
        infoLbl.TextStrokeTransparency = 0
        infoLbl.TextStrokeColor3       = Color3.new(0,0,0)
        infoLbl.TextScaled             = true
        infoLbl.Font                   = Enum.Font.Gotham
        infoLbl.Parent                 = bb

        _xesp_cache[plr] = {hl = hl, bb = bb, name = nameLbl, info = infoLbl}
    end

    local function _xesp_remove(plr)
        local d = _xesp_cache[plr]
        if d then
            pcall(function() d.hl:Destroy() end)
            pcall(function() d.bb:Destroy() end)
            _xesp_cache[plr] = nil
        end
    end

    for _, p in ipairs(_xesp_Players:GetPlayers()) do _xesp_build(p) end
    _xesp_Players.PlayerAdded:Connect(_xesp_build)
    _xesp_Players.PlayerRemoving:Connect(_xesp_remove)

    _xesp_RunService.RenderStepped:Connect(function()
        if not _xesp_CFG.Enabled then return end
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

        for plr, d in pairs(_xesp_cache) do
            pcall(function()
                local char = plr.Character
                if not char then
                    d.hl.Adornee = nil; d.bb.Adornee = nil
                    return
                end
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
                local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart

                if not hum or hum.Health <= 0 or not root then
                    d.hl.Adornee = nil; d.bb.Adornee = nil
                    return
                end

                if _xesp_CFG.TeamCheck and plr.Team and lp.Team and plr.Team == lp.Team then
                    d.hl.Adornee = nil; d.bb.Adornee = nil
                    return
                end

                local dist = 0
                if myRoot then
                    dist = (root.Position - myRoot.Position).Magnitude
                    if dist > _xesp_CFG.MaxDist then
                        d.hl.Adornee = nil; d.bb.Adornee = nil
                        return
                    end
                end

                d.hl.Adornee = char
                d.hl.Enabled = _xesp_CFG.ShowBox

                d.bb.Adornee = head
                d.bb.Enabled = (_xesp_CFG.ShowName or _xesp_CFG.ShowDist)

                d.name.Text = _xesp_CFG.ShowName and plr.Name or ""
                d.name.Visible = _xesp_CFG.ShowName

                if _xesp_CFG.ShowDist then
                    d.info.Text = string.format("[%d HP] %dm", math.floor(hum.Health), math.floor(dist))
                    d.info.Visible = true
                else
                    d.info.Visible = false
                end
            end)
        end
    end)

    _G.XoXoESP = {
        SetEnabled = function(on)
            _xesp_CFG.Enabled = on
            if not on then
                for _, d in pairs(_xesp_cache) do
                    d.hl.Adornee = nil
                    d.bb.Adornee = nil
                end
            end
        end,
        IsEnabled = function() return _xesp_CFG.Enabled end,
        CFG = _xesp_CFG,
    }

    print("[XoXo ESP] module attached.")
end

---------------------------------------------------------------- MENU ITEMS
makeToggle("Hide Players", 10, CFG.HidePlayers, function(on)
    CFG.HidePlayers = on
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then setCharHidden(plr.Character, on) end
    end
end)

makeToggle("Layar Hitam", 46, false, function(on)
    blackFrame.Visible = on
    pcall(function() RunService:Set3dRenderingEnabled(not on) end)
end)

makeToggle("Speed", 82, false, function(on)
    state.speed = on
    if not on then
        local _, hum = getParts()
        if hum then hum.WalkSpeed = 16 end
    end
end)
makeInput("Kecepatan", 118, state.speedValue, function(n) state.speedValue = n end)

makeToggle("Fly + Noclip", 154, false, function(on)
    state.fly = on
    upBtn.Visible, downBtn.Visible = on, on
    if on then startFly() else stopFly() end
end)
makeInput("Fly speed", 190, state.flySpeed, function(n) state.flySpeed = n end)

makeToggle("Infinite Jump", 226, false, function(on) state.infJump = on end)

makeToggle("ESP", 262, true, function(on)
    if _G.XoXoESP then _G.XoXoESP.SetEnabled(on) end
end)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 20)
hint.Position = UDim2.new(0, 10, 0, 296)
hint.BackgroundTransparency = 1
hint.Text = "PC: Space naik, Ctrl turun"
hint.TextColor3 = Color3.fromRGB(150, 150, 160)
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.Parent = body

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.Space then state.up = true end
    if i.KeyCode == Enum.KeyCode.LeftControl then state.down = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Space then state.up = false end
    if i.KeyCode == Enum.KeyCode.LeftControl then state.down = false end
end)

UIS.JumpRequest:Connect(function()
    if state.infJump and not state.fly then
        local _, hum = getParts()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    local root, hum = getParts()
    if not root or not hum then return end

    if state.speed then hum.WalkSpeed = state.speedValue end

    if state.fly and bv and bg then
        local cam = Workspace.CurrentCamera
        local look = cam.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        flat = flat.Magnitude > 0 and flat.Unit or Vector3.new(0, 0, -1)

        local move = hum.MoveDirection
        local forward = move:Dot(flat)
        local vel = move * state.flySpeed + Vector3.new(0, look.Y * forward * state.flySpeed, 0)
        if state.up then vel += Vector3.new(0, state.flySpeed, 0) end
        if state.down then vel -= Vector3.new(0, state.flySpeed, 0) end

        bv.Velocity = vel
        bg.CFrame = CFrame.new(root.Position, root.Position + flat)
    end
end)

lp.CharacterAdded:Connect(function(char)
    bv, bg = nil, nil
    task.wait(1)
    cacheParts(char)
    if state.fly then startFly() end
end)

do
    local frames, last = 0, os.clock()
    RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - last >= 1 then
            title.Text = "  Lite Max v4 | FPS: " .. frames
            frames, last = 0, now
        end
    end)
end

print("[Lite Max v4] aktif")
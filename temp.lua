-- [[ CLEANUP PREVIOUS ]] --
pcall(function()
if cleardrawings then cleardrawings() end
end)

if _G.ZHubFOVCircle then
pcall(function() _G.ZHubFOVCircle:Remove() end)
pcall(function() _G.ZHubFOVCircle:Destroy() end)
_G.ZHubFOVCircle = nil
end

local function PurgePreviousGUIs(parent)
    if not parent then return end
    pcall(function()
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("ScreenGui") and v.Name == "ZHub" then
                pcall(function() v:Destroy() end)
            end
        end
    end)
end

PurgePreviousGUIs(game:GetService("CoreGui"))
if pcall(function() return gethui() end) and gethui() then
PurgePreviousGUIs(gethui())
end
if game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") then
PurgePreviousGUIs(game:GetService("Players").LocalPlayer.PlayerGui)
end

local CurrentLoopID = tick()
_G.MovementLoopID = CurrentLoopID

-- [[ SERVICES ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
repeat
    task.wait()
    LocalPlayer = Players.LocalPlayer
until LocalPlayer
end

local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA("Camera")

-- [[ THEME ]] --
local Theme = {
Background = Color3.fromRGB(12, 12, 16),
Surface = Color3.fromRGB(18, 18, 24),
SurfaceHover = Color3.fromRGB(24, 24, 32),
Accent = Color3.fromRGB(99, 102, 241),
AccentGlow = Color3.fromRGB(129, 140, 248),
Success = Color3.fromRGB(34, 197, 94),
Danger = Color3.fromRGB(239, 68, 68),
Warning = Color3.fromRGB(251, 191, 36),
Text = Color3.fromRGB(250, 250, 250),
TextMuted = Color3.fromRGB(148, 148, 160),
Border = Color3.fromRGB(38, 38, 48),
GradientStart = Color3.fromRGB(99, 102, 241),
GradientEnd = Color3.fromRGB(168, 85, 247),
}

-- [[ LIGHTING CACHE ]] --
local LightCache = {
Brightness = Lighting.Brightness,
ClockTime = Lighting.ClockTime,
FogEnd = Lighting.FogEnd,
GlobalShadows = Lighting.GlobalShadows,
OutdoorAmbient = Lighting.OutdoorAmbient
}

-- [[ GLOBAL STATES ]] --
_G.Noclip, _G.Fly, _G.SpeedEnabled, _G.EspEnabled, _G.InfJump, _G.FreeCam, _G.FullBright = false, false, false, false, false, false, false
_G.ReachEnabled = false
_G.HitboxExpander = false
_G.HitboxSize = 15
_G.KillAura = false
_G.AutoAim = false
_G.ShowFOV = true
_G.AimFOV = 150
_G.AimSmoothness = 0.15
_G.AimPart = "Head"
_G.AimWallCheck = true
_G.HeadshotChance = 0.40
_G.SmoothAim = false  -- false = Direct Aim (default), true = Smooth Aim (natural glide)
_G.NearMode = false   -- true = target closest enemy by 3D world distance (skips FOV check)
_G.TeamCheck = true   -- true = skip teammates in auto aim
_G.AutoShoot = false  -- true = automatically fire at locked/valid target
_G.MovementSpeed, _G.SafeMode, _G.TimeScale = 50, true, 1
_G.ReachDistance = 15
_G.KillAuraRange = 40
_G.ESPRange = 1000
_G.SelectedPlayer = ""
_G.IgnoredPlayers = _G.IgnoredPlayers or {}

-- [[ CONFIG / STATE SAVE SYSTEM ]] --
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "ZHub_FOV_Config.json"

local function SaveConfig()
pcall(function()
    if writefile then
    local data = {
        ShowFOV = _G.ShowFOV,
        AimFOV = _G.AimFOV,
        AimSmoothness = _G.AimSmoothness,
        HeadshotChance = _G.HeadshotChance,
        SmoothAim = _G.SmoothAim,
        NearMode = _G.NearMode,
        TeamCheck = _G.TeamCheck,
        AutoShoot = _G.AutoShoot,
        EspEnabled = _G.EspEnabled,
        ESPRange = _G.ESPRange,
        ReachDistance = _G.ReachDistance,
        HitboxExpander = _G.HitboxExpander,
        HitboxSize = _G.HitboxSize,
        KillAuraRange = _G.KillAuraRange,
        MovementSpeed = _G.MovementSpeed
    }
    writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end
end)
end

local function LoadConfig()
pcall(function()
    if readfile and isfile and isfile(CONFIG_FILE) then
    local content = readfile(CONFIG_FILE)
    local data = HttpService:JSONDecode(content)
    if type(data) == "table" then
        if data.ShowFOV ~= nil then _G.ShowFOV = data.ShowFOV end
        if data.AimFOV ~= nil then _G.AimFOV = data.AimFOV end
        if data.AimSmoothness ~= nil then _G.AimSmoothness = data.AimSmoothness end
        if data.HeadshotChance ~= nil then _G.HeadshotChance = data.HeadshotChance end
        if data.SmoothAim ~= nil then _G.SmoothAim = data.SmoothAim end
        if data.NearMode ~= nil then _G.NearMode = data.NearMode end
        if data.TeamCheck ~= nil then _G.TeamCheck = data.TeamCheck end
        if data.AutoShoot ~= nil then _G.AutoShoot = data.AutoShoot end
        if data.EspEnabled ~= nil then _G.EspEnabled = data.EspEnabled end
        if data.ESPRange ~= nil then _G.ESPRange = data.ESPRange end
        if data.ReachDistance ~= nil then _G.ReachDistance = data.ReachDistance end
        if data.HitboxExpander ~= nil then _G.HitboxExpander = data.HitboxExpander end
        if data.HitboxSize ~= nil then _G.HitboxSize = data.HitboxSize end
        if data.KillAuraRange ~= nil then _G.KillAuraRange = data.KillAuraRange end
        if data.MovementSpeed ~= nil then _G.MovementSpeed = data.MovementSpeed end
    end
    end
end)
end

LoadConfig()

-- [[ UI UTILITIES ]] --
local function CreateTween(obj, props, duration, style, direction)
return TweenService:Create(obj, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out), props)
end

local function ApplyCorner(obj, radius)
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, radius or 8)
corner.Parent = obj
return corner
end

local function ApplyStroke(obj, color, thickness, transparency)
local stroke = Instance.new("UIStroke")
stroke.Color = color or Theme.Border
stroke.Thickness = thickness or 1
stroke.Transparency = transparency or 0
stroke.Parent = obj
return stroke
end

local function ApplyGradient(obj, startColor, endColor, rotation)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, startColor or Theme.GradientStart),
    ColorSequenceKeypoint.new(1, endColor or Theme.GradientEnd)
})
gradient.Rotation = rotation or 45
gradient.Parent = obj
return gradient
end

local function ApplyPadding(obj, padding)
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, padding)
pad.PaddingBottom = UDim.new(0, padding)
pad.PaddingLeft = UDim.new(0, padding)
pad.PaddingRight = UDim.new(0, padding)
pad.Parent = obj
return pad
end

-- [[ MAIN UI ]] --
local parentContainer = nil
if pcall(function() return gethui() end) and gethui() then
parentContainer = gethui()
elseif LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
parentContainer = LocalPlayer.PlayerGui
else
parentContainer = game:GetService("CoreGui")
end

-- Cleanup old ZHub instances in parentContainer safely without destroying game controls
if parentContainer then
for _, child in pairs(parentContainer:GetChildren()) do
    if child.Name == "ZHub" then
    pcall(function() child:Destroy() end)
    end
end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentContainer

-- Main Container
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.BackgroundColor3 = Theme.Background
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Size = UDim2.new(0, 360, 0, 480)
Main.Parent = ScreenGui
ApplyCorner(Main, 12)
ApplyStroke(Main, Theme.Border, 1)

-- Mobile UI Scale (automatically scales entire UI comfortably smaller on mobile devices)
local MainScale = Instance.new("UIScale")
MainScale.Name = "MainScale"
MainScale.Scale = UserInputService.TouchEnabled and 0.65 or 1.0
MainScale.Parent = Main

-- Glow Effect
local Glow = Instance.new("ImageLabel")
Glow.Name = "Glow"
Glow.BackgroundTransparency = 1
Glow.Position = UDim2.new(0.5, 0, 0, -20)
Glow.AnchorPoint = Vector2.new(0.5, 0)
Glow.Size = UDim2.new(0, 200, 0, 60)
Glow.Image = "rbxassetid://5028857084"
Glow.ImageColor3 = Theme.Accent
Glow.ImageTransparency = 0.7
Glow.Parent = Main

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.BackgroundColor3 = Theme.Surface
Header.Size = UDim2.new(1, 0, 0, 50)
Header.Parent = Main
ApplyCorner(Header, 12)

-- Fix bottom corners of header
local HeaderFix = Instance.new("Frame")
HeaderFix.BackgroundColor3 = Theme.Surface
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Logo/Brand
local Logo = Instance.new("TextLabel")
Logo.Name = "Logo"
Logo.Parent = Header
Logo.BackgroundTransparency = 1
Logo.Position = UDim2.new(0, 16, 0, 0)
Logo.Size = UDim2.new(0, 120, 1, 0)
Logo.Font = Enum.Font.GothamBlack
Logo.Text = "Z"
Logo.TextColor3 = Theme.Text
Logo.TextSize = 18
Logo.TextXAlignment = Enum.TextXAlignment.Left

local LogoAccent = Instance.new("TextLabel")
LogoAccent.Name = "LogoAccent"
LogoAccent.Parent = Header
LogoAccent.BackgroundTransparency = 1
LogoAccent.Position = UDim2.new(0, 32, 0, 0) 
LogoAccent.Size = UDim2.new(0, 40, 1, 0)
LogoAccent.Font = Enum.Font.GothamBlack
LogoAccent.Text = "HUB"
LogoAccent.TextColor3 = Theme.Accent
LogoAccent.TextSize = 18
LogoAccent.TextXAlignment = Enum.TextXAlignment.Left

-- Session Timer
local SessionLabel = Instance.new("TextLabel")
SessionLabel.Name = "Session"
SessionLabel.BackgroundTransparency = 1
SessionLabel.Position = UDim2.new(0.5, -40, 0, 0)
SessionLabel.Size = UDim2.new(0, 80, 1, 0)
SessionLabel.Font = Enum.Font.GothamMedium
SessionLabel.Text = "00:00:00"
SessionLabel.TextColor3 = Theme.TextMuted
SessionLabel.TextSize = 11
SessionLabel.Parent = Header

-- Window Controls (Scoped in do-end)
do
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.BackgroundTransparency = 1
    Controls.Position = UDim2.new(1, -80, 0, 0)
    Controls.Size = UDim2.new(0, 70, 1, 0)
    Controls.Parent = Header

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "Minimize"
    MinimizeBtn.BackgroundColor3 = Theme.SurfaceHover
    MinimizeBtn.Position = UDim2.new(0, 0, 0.5, -12)
    MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = Theme.TextMuted
    MinimizeBtn.TextSize = 16
    MinimizeBtn.Parent = Controls
    ApplyCorner(MinimizeBtn, 6)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "Close"
    CloseBtn.BackgroundColor3 = Theme.Danger
    CloseBtn.BackgroundTransparency = 0.8
    CloseBtn.Position = UDim2.new(0, 34, 0.5, -12)
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Theme.Danger
    CloseBtn.TextSize = 16
    CloseBtn.Parent = Controls
    ApplyCorner(CloseBtn, 6)

    CloseBtn.MouseButton1Click:Connect(function()
    if _G.ZHubFOVCircle then pcall(function() _G.ZHubFOVCircle:Remove() end) end
    CreateTween(Main, {Size = UDim2.new(0, 360, 0, 0), BackgroundTransparency = 1}, 0.3):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
    end)

    local isMinimized = false

    local function ToggleMinimize()
    isMinimized = not isMinimized
    local content = Main:FindFirstChild("Content")
    if isMinimized then
        -- Minimize: Collapse into a sleek small curved square (50x50) showing only the 'Z' Logo
        if content then content.Visible = false end
        SessionLabel.Visible = false
        Controls.Visible = false
        HeaderFix.Visible = false
        LogoAccent.Visible = false
    
        Logo.Position = UDim2.new(0, 0, 0, 0)
        Logo.Size = UDim2.new(1, 0, 1, 0)
        Logo.TextXAlignment = Enum.TextXAlignment.Center
        Logo.Text = "Z"
        Logo.TextColor3 = Theme.Accent

        CreateTween(Main, {Size = UDim2.new(0, 50, 0, 50)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()
    else
        -- Expand: Expand back to full size menu (360x480)
        Logo.Position = UDim2.new(0, 16, 0, 0)
        Logo.Size = UDim2.new(0, 120, 1, 0)
        Logo.TextXAlignment = Enum.TextXAlignment.Left
        Logo.Text = "Z"
        Logo.TextColor3 = Theme.Text

        LogoAccent.Visible = true
        SessionLabel.Visible = true
        Controls.Visible = true
        HeaderFix.Visible = true

        local tw = CreateTween(Main, {Size = UDim2.new(0, 360, 0, 480)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        tw:Play()
        task.delay(0.1, function()
            local c = Main:FindFirstChild("Content")
            if not isMinimized and c then
                c.Visible = true
            end
        end)
    end
    end

    MinimizeBtn.MouseButton1Click:Connect(function()
    ToggleMinimize()
    end)

    -- Make tapping the header/logo when minimized also expand the menu back
    Header.InputBegan:Connect(function(input)
    if isMinimized and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        ToggleMinimize()
    end
    end)
end

-- Content Area
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 0, 0, 55)
Content.Size = UDim2.new(1, 0, 1, -55)
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Theme.Accent
Content.ScrollBarImageTransparency = 0.5
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.new(0, 0, 0, 1250)
Content.Parent = Main
ApplyPadding(Content, 12)

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

-- [[ PLAYER LIST UI REGISTRY ]] --
local PlayerListUI = {}

-- [[ CORE FUNCTIONS ]] --
local function RestoreLighting()
    Lighting.Brightness = LightCache.Brightness
    Lighting.ClockTime = LightCache.ClockTime
    Lighting.FogEnd = LightCache.FogEnd
    Lighting.GlobalShadows = LightCache.GlobalShadows
    Lighting.OutdoorAmbient = LightCache.OutdoorAmbient
end

local FreeCamPart, freecamConnection
local function ToggleFreeCam()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if _G.FreeCam then
    if hrp then hrp.Anchored = true end
    if not FreeCamPart then
        FreeCamPart = Instance.new("Part")
        FreeCamPart.Anchored = true
        FreeCamPart.CanCollide = false
        FreeCamPart.Transparency = 1
        FreeCamPart.CFrame = Camera.CFrame
        FreeCamPart.Parent = workspace
    end
    Camera.CameraSubject = FreeCamPart

    freecamConnection = RunService.RenderStepped:Connect(function(dt)
        local dir = Vector3.new()
        local hum = char and char:FindFirstChild("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then
            dir = hum.MoveDirection
        else
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end
        end

        local camSpeed = _G.SpeedEnabled and _G.MovementSpeed or 50
        if dir.Magnitude > 0 then
            FreeCamPart.CFrame = FreeCamPart.CFrame + (dir.Unit * (camSpeed * dt))
        end
    end)
    else
    if hrp then hrp.Anchored = false end
    if freecamConnection then freecamConnection:Disconnect() end
    if FreeCamPart then FreeCamPart:Destroy(); FreeCamPart = nil end
    if char and char:FindFirstChild("Humanoid") then
        Camera.CameraSubject = char.Humanoid
    end
    end
end

local function GetFlyDirection()
    local dir = Vector3.new()
    local cam = workspace.CurrentCamera or Camera
    if not cam then return dir end
    local camCF = cam.CFrame
    local look = camCF.LookVector
    local right = camCF.RightVector
    local up = Vector3.new(0, 1, 0)

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + up end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - up end

    -- Mobile / Touchpad integration
    if _padDragging and _mobileMoveVector and _mobileMoveVector.Magnitude > 0 then
        dir = dir + (look * _mobileMoveVector.Y) + (right * _mobileMoveVector.X)
    elseif dir.Magnitude == 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humMove = LocalPlayer.Character.Humanoid.MoveDirection
        if humMove.Magnitude > 0 then
            dir = dir + (look * humMove.Z * -1) + (right * humMove.X)
        end
    end

    if dir.Magnitude > 0 then
        return dir.Unit
    end
    return Vector3.new(0, 0, 0)
end

local function StopFly()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if hrp then
            local bv = hrp:FindFirstChild("ZHub_FlyVelocity") or hrp:FindFirstChild("VelocityGrip")
            local bg = hrp:FindFirstChild("ZHub_FlyGyro") or hrp:FindFirstChild("GyroGrip")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
        end
        if hum then
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end
end

-- [[ REACH SYSTEM ]] --
local ReachPart = nil
local OriginalSizes = {}

local function CreateReachPart()
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if ReachPart then ReachPart:Destroy() end

    ReachPart = Instance.new("Part")
    ReachPart.Name = "ReachPart"
    ReachPart.Size = Vector3.new(_G.ReachDistance, _G.ReachDistance, _G.ReachDistance)
    ReachPart.Transparency = 1
    ReachPart.CanCollide = false
    ReachPart.Anchored = false
    ReachPart.Massless = true
    ReachPart.Parent = char

    local weld = Instance.new("Weld")
    weld.Part0 = hrp
    weld.Part1 = ReachPart
    weld.C0 = CFrame.new(0, 0, -_G.ReachDistance / 2)
    weld.Parent = ReachPart

    ReachPart.Touched:Connect(function(hit)
    if not _G.ReachEnabled then return end

    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid and hit.Parent ~= char then
        firetouchinterest(ReachPart, hit, 0)
        task.wait()
        firetouchinterest(ReachPart, hit, 1)
    end
    end)
end

local function UpdateReachSize()
    if ReachPart then
    ReachPart.Size = Vector3.new(_G.ReachDistance, _G.ReachDistance, _G.ReachDistance)
    local weld = ReachPart:FindFirstChild("Weld")
    if weld then
        weld.C0 = CFrame.new(0, 0, -_G.ReachDistance / 2)
    end
    end
end

local function DestroyReachPart()
    if ReachPart then
    ReachPart:Destroy()
    ReachPart = nil
    end
end

local function ExpandToolHitbox()
    local char = LocalPlayer.Character
    if not char then return end

    for _, tool in pairs(char:GetChildren()) do
    if tool:IsA("Tool") then
        local handle = tool:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            if not OriginalSizes[handle] then
                OriginalSizes[handle] = handle.Size
            end
            handle.Size = Vector3.new(_G.ReachDistance, _G.ReachDistance, _G.ReachDistance)
            handle.Massless = true
            handle.Transparency = 1
        end
    end
    end
end

local function RestoreToolHitbox()
    for handle, originalSize in pairs(OriginalSizes) do
    if handle and handle.Parent then
        handle.Size = originalSize
    end
    end
    OriginalSizes = {}
end

-- [[ KILL AURA SYSTEM ]] --
-- Tracks last-hit time per NPC to throttle damage ticks
local KillAuraLastHit = {}
-- How many times per second kill aura deals damage
local KILL_AURA_RATE = 0.08 -- seconds between damage applications per NPC

--[[
    IsPlayerCharacter: returns true if a model belongs to a real player.
    Uses GetPlayerFromCharacter (O(1)) instead of looping all players.
]]
local function IsPlayerCharacter(model)
    if not model then return false end
    if model == LocalPlayer.Character then return true end
    return Players:GetPlayerFromCharacter(model) ~= nil
end

--[[
    GetNPCsInRange: Universal, comprehensive NPC scanner.
    Finds 100% of enemy mobs, NPCs, and bosses across any game map hierarchy.
]]
-- [[ CACHED COMBAT REMOTES (ZERO-LAG SCAN) ]] --
local _cachedCombatRemotes = {}
local _lastRemoteCacheScan = 0

local function GetCachedCombatRemotes()
    local now = tick()
    if (now - _lastRemoteCacheScan) >= 8 then
        _lastRemoteCacheScan = now
        local rems = {}
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            for _, rem in ipairs(rs:GetDescendants()) do
                if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                    local rName = rem.Name:lower()
                    local pName = rem.Parent and rem.Parent.Name:lower() or ""
                    if rName:find("attack") or rName:find("hit") or rName:find("combat") or rName:find("damage")
                        or rName:find("swing") or rName:find("slash") or rName:find("m1") or rName:find("skill")
                        or rName:find("weapon") or rName:find("action") or rName:find("cast") or rName:find("dungeon")
                        or rName:find("battle") or rName:find("enemy") or rName:find("strike") or rName:find("fire")
                        or pName:find("combat") or pName:find("remotes") or pName:find("skill") or pName:find("attack") then
                        table.insert(rems, rem)
                    end
                end
            end
        end)
        _cachedCombatRemotes = rems
    end
    return _cachedCombatRemotes
end

local _allKnownNPCs = {}
local _lastNpcScan = 0
local NPC_SCAN_INTERVAL = 1.0 -- scan at most 1x/sec (zero lag)

local function RefreshNPCList()
    local list = {}
    local seen = {}

    local function AddMobCandidate(model, hum)
        if not model or not model:IsA("Model") or seen[model] or IsPlayerCharacter(model) then return end
        seen[model] = true
        local root = model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("Torso")
            or model:FindFirstChild("UpperTorso")
            or model:FindFirstChild("Head")
            or model.PrimaryPart
            or model:FindFirstChildWhichIsA("BasePart", true)
        if root then
            table.insert(list, {model = model, humanoid = hum, root = root})
        end
    end

    -- 1. Scan Iron Soul Enemy Container (Workspace.EnemyNpc) - INSTANT & ZERO-LAG!
    local enemyNpcFolder = workspace:FindFirstChild("EnemyNpc")
    if enemyNpcFolder then
        for _, model in ipairs(enemyNpcFolder:GetChildren()) do
            if model:IsA("Model") and not IsPlayerCharacter(model) then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model.PrimaryPart
                if root then
                    AddMobCandidate(model, hum)
                end
            end
        end
    end

    -- 2. Scan Iron Soul World Hierarchy (Workspace.World.<Stage>)
    local worldFolder = workspace:FindFirstChild("World")
    if worldFolder then
        for _, stage in ipairs(worldFolder:GetChildren()) do
            for _, child in ipairs(stage:GetChildren()) do
                if child.Name ~= "Scene" and child.Name ~= "Collide" and not IsPlayerCharacter(child) then
                    if child:IsA("Model") then
                        AddMobCandidate(child, child:FindFirstChildOfClass("Humanoid"))
                    elseif child:IsA("Folder") then
                        for _, sub in ipairs(child:GetChildren()) do
                            if sub:IsA("Model") then
                                AddMobCandidate(sub, sub:FindFirstChildOfClass("Humanoid"))
                            end
                        end
                    end
                end
            end
        end
    end

    -- 3. Scan Standard RPG Enemy Containers in Workspace
    local enemyFolders = {
        workspace:FindFirstChild("EnemyNpc"),
        workspace:FindFirstChild("Monsters"),
        workspace:FindFirstChild("Monster"),
        workspace:FindFirstChild("Enemies"),
        workspace:FindFirstChild("Enemy"),
        workspace:FindFirstChild("Mobs"),
        workspace:FindFirstChild("Entities"),
        workspace:FindFirstChild("Dungeon"),
        workspace:FindFirstChild("Living"),
        workspace:FindFirstChild("Characters")
    }
    for _, folder in ipairs(enemyFolders) do
        if folder and folder ~= enemyNpcFolder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    AddMobCandidate(child, child:FindFirstChildOfClass("Humanoid"))
                end
            end
        end
    end

    -- 4. Top-Level Workspace Models (Lightweight, zero deep scanning)
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and not IsPlayerCharacter(child) and child.Name ~= "Terrain" and child.Name ~= "Camera" then
            local hum = child:FindFirstChildOfClass("Humanoid")
            if hum then
                AddMobCandidate(child, hum)
            end
        end
    end

    _allKnownNPCs = list
end

local function GetNPCsInRange(hrp)
    local results = {}
    local range = _G.KillAuraRange or 40
    local now = tick()

    if (now - _lastNpcScan) >= NPC_SCAN_INTERVAL then
        _lastNpcScan = now
        pcall(RefreshNPCList)
    end

    local myPos = hrp.Position
    for _, entry in ipairs(_allKnownNPCs) do
        local model = entry.model
        local root = entry.root
        if root and root.Parent and model and model.Parent and model:IsDescendantOf(workspace) then
            local dist = (root.Position - myPos).Magnitude
            if dist <= range then
                table.insert(results, {entry = entry, dist = dist})
            end
        end
    end

    -- Target closest mobs first (up to 8 nearest mobs to avoid network choking)
    table.sort(results, function(a, b) return a.dist < b.dist end)
    local capped = {}
    for i = 1, math.min(#results, 8) do
        table.insert(capped, results[i].entry)
    end
    return capped
end

-- Hook EnemyNpc container for instant respawn updates
pcall(function()
    local enemyNpcFolder = workspace:FindFirstChild("EnemyNpc")
    if enemyNpcFolder then
        enemyNpcFolder.ChildAdded:Connect(function()
            _lastNpcScan = 0
            pcall(RefreshNPCList)
        end)
        enemyNpcFolder.ChildRemoved:Connect(function()
            _lastNpcScan = 0
            pcall(RefreshNPCList)
        end)
    end
end)

--[[
    RunKillAura: Smooth, Desync-Proof Damage System.
    Zero screen hijack, zero mouse interference, zero packet flood.
    Uses clean physics touch and safe remote dispatch with per-mob cooldowns.
]]
local function RunKillAura()
    if not _G.KillAura then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local npcs = GetNPCsInRange(hrp)
    if #npcs == 0 then return end

    local now = tick()

    -- 1. Auto-equip tool from Backpack if available
    local equippedTool = char:FindFirstChildOfClass("Tool")
    if not equippedTool and LocalPlayer.Backpack then
        local bpTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bpTool and char:FindFirstChildOfClass("Humanoid") then
            pcall(function() char.Humanoid:EquipTool(bpTool) end)
            equippedTool = bpTool
        end
    end

    -- 2. Select ONLY the player's weapon parts & fists (lightweight, zero lag)
    local playerAttackParts = {}
    if equippedTool then
        for _, desc in ipairs(equippedTool:GetDescendants()) do
            if desc:IsA("BasePart") then table.insert(playerAttackParts, desc) end
        end
    end

    local wepPart = char:FindFirstChild("Weapon")
    if wepPart and wepPart:IsA("BasePart") then
        table.insert(playerAttackParts, wepPart)
    end

    for _, ch in ipairs(char:GetChildren()) do
        if ch:IsA("Model") and ch ~= equippedTool then
            local n = ch.Name:lower()
            if n:find("weapon") or n:find("sword") or n:find("blade") or n:find("axe") or n:find("dagger") or ch:FindFirstChild("Setting") then
                for _, desc in ipairs(ch:GetDescendants()) do
                    if desc:IsA("BasePart") then table.insert(playerAttackParts, desc) end
                end
            end
        end
    end

    if #playerAttackParts == 0 then
        local limb = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
        if limb then table.insert(playerAttackParts, limb) end
    end

    local combatRemotes = GetCachedCombatRemotes()

    for _, entry in ipairs(npcs) do
        local targetModel = entry.model
        local targetRoot = entry.root

        -- Per-NPC Cooldown (0.12s) prevents network desync and packet drops
        if not KillAuraLastHit[targetModel] or (now - KillAuraLastHit[targetModel]) >= 0.12 then
            KillAuraLastHit[targetModel] = now

            -- Target Parts: Torso, HumanoidRootPart, Head
            local hitTargets = {}
            if targetRoot then table.insert(hitTargets, targetRoot) end
            local torso = targetModel:FindFirstChild("Torso")
            if torso and torso ~= targetRoot then table.insert(hitTargets, torso) end
            local head = targetModel:FindFirstChild("Head")
            if head and head ~= targetRoot then table.insert(hitTargets, head) end

            -- 1. Physics Weapon Blade & Limb Touch
            if firetouchinterest then
                for _, attPart in ipairs(playerAttackParts) do
                    for _, tObj in ipairs(hitTargets) do
                        pcall(function()
                            firetouchinterest(attPart, tObj, 0)
                            firetouchinterest(attPart, tObj, 1)
                        end)
                    end
                end
            end

            -- 2. Tool Activation
            if equippedTool then
                pcall(function() equippedTool:Activate() end)
            end

            -- 3. Safe Combat Remote Dispatch (RemoteEvents only, NO InvokeServer)
            for _, rem in ipairs(combatRemotes) do
                if rem:IsA("RemoteEvent") then
                    pcall(function() rem:FireServer(targetModel) end)
                end
            end

            -- 4. ClickDetector & ProximityPrompt
            pcall(function()
                if fireclickdetector then
                    local cd = targetModel:FindFirstChildOfClass("ClickDetector", true)
                    if cd then fireclickdetector(cd) end
                end
                if fireproximityprompt then
                    local pp = targetModel:FindFirstChildOfClass("ProximityPrompt", true)
                    if pp then fireproximityprompt(pp) end
                end
            end)
        end
    end

    -- Clean up stale entries
    for modelRef, lastTime in pairs(KillAuraLastHit) do
        if (now - lastTime) > 3 or not modelRef.Parent then
            KillAuraLastHit[modelRef] = nil
        end
    end
end

-- [[ SHOOT BUTTON TARGET WIDGET (MOBILE NATIVE TOUCH AUTO-SHOOT) ]] --
local ShootTargetWidget = Instance.new("Frame")
ShootTargetWidget.Name = "ShootTargetWidget"
ShootTargetWidget.Size = UDim2.new(0, 44, 0, 44)
ShootTargetWidget.Position = UDim2.new(0.8, -22, 0.7, -22) -- Positioned near right bottom by default (typical shoot button area)
ShootTargetWidget.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
ShootTargetWidget.BackgroundTransparency = 0.35
ShootTargetWidget.Visible = _G.AutoShoot and UserInputService.TouchEnabled
ShootTargetWidget.ZIndex = 2000
ShootTargetWidget.Parent = ScreenGui
ApplyCorner(ShootTargetWidget, 999)
local strokeRef = ApplyStroke(ShootTargetWidget, Color3.fromRGB(255, 255, 255), 2, 0.2)

local TargetIcon = Instance.new("TextLabel")
TargetIcon.Size = UDim2.new(1, 0, 1, 0)
TargetIcon.BackgroundTransparency = 1
TargetIcon.Font = Enum.Font.GothamBlack
TargetIcon.Text = "🎯"
TargetIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetIcon.TextSize = 20
TargetIcon.Parent = ShootTargetWidget

local _stDragging = false
local _stUnlocked = false
local _stHoldThread = nil
local _stDragStart = nil
local _stStartPos = nil

ShootTargetWidget.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        _stDragStart = input.Position
        _stStartPos = ShootTargetWidget.Position
        _stUnlocked = false
        _stDragging = false

        -- Visual indicator: Amber outline while holding 2 seconds to unlock drag
        strokeRef.Color = Color3.fromRGB(251, 191, 36)

        if _stHoldThread then task.cancel(_stHoldThread) end

        _stHoldThread = task.delay(2.0, function()
            _stUnlocked = true
            _stDragging = true
            -- Green outline + scale up when unlocked!
            strokeRef.Color = Color3.fromRGB(34, 197, 94)
            CreateTween(ShootTargetWidget, {Size = UDim2.new(0, 50, 0, 50)}, 0.15):Play()
        end)

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                if _stHoldThread then
                    task.cancel(_stHoldThread)
                    _stHoldThread = nil
                end
                _stDragging = false
                _stUnlocked = false
                strokeRef.Color = Color3.fromRGB(255, 255, 255)
                CreateTween(ShootTargetWidget, {Size = UDim2.new(0, 44, 0, 44)}, 0.15):Play()
                if conn then conn:Disconnect() end
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if _stUnlocked and _stDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - _stDragStart
        ShootTargetWidget.Position = UDim2.new(_stStartPos.X.Scale, _stStartPos.X.Offset + delta.X, _stStartPos.Y.Scale, _stStartPos.Y.Offset + delta.Y)
    end
end)

-- [[ AUTO AIM & FOV CIRCLE SYSTEM ]] --
local _updateAutoAimFunc = nil
local CurrentLockedTarget = nil  -- The character Model we're locked onto
local _lastTargetChar = nil      -- Grace period tracking
local function ToggleAutoAim(forcedState)
    if forcedState ~= nil then
        _G.AutoAim = forcedState
    else
        _G.AutoAim = not _G.AutoAim
    end
    if not _G.AutoAim then
        CurrentLockedTarget = nil
        _lastTargetChar = nil
    end
    if _updateAutoAimFunc then
        pcall(function() _updateAutoAimFunc(_G.AutoAim) end)
    end
    if UpdateFOVCircle then
        pcall(UpdateFOVCircle)
    end
    SaveConfig()
end

local _lastToggleTime = 0
local function HandleToggleAutoAimKey()
    local now = tick()
    if (now - _lastToggleTime) < 0.18 then return end
    _lastToggleTime = now
    ToggleAutoAim()
end

local function IsTypingInTextBox()
    local focused = UserInputService:GetFocusedTextBox()
    if focused and focused:IsA("TextBox") and focused.Visible and focused.AbsoluteSize.Y > 5 then
        return true
    end
    return false
end

-- 1. ContextActionService Binding (High Priority 3000)
local CAS = game:GetService("ContextActionService")
pcall(function()
    CAS:UnbindAction("ZHub_ToggleAutoAim")
    CAS:BindActionAtPriority(
        "ZHub_ToggleAutoAim",
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                if IsTypingInTextBox() then return Enum.ContextActionResult.Pass end
                HandleToggleAutoAimKey()
            end
            return Enum.ContextActionResult.Pass
        end,
        false,
        3000,
        Enum.KeyCode.T
    )

end)

-- 2. UserInputService InputBegan
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.T then
        if IsTypingInTextBox() then return end
        HandleToggleAutoAimKey()
    end
end)

-- 3. Mouse.KeyDown Fallback
pcall(function()
    if Mouse and Mouse.KeyDown then
        Mouse.KeyDown:Connect(function(key)
            if key then
                local lk = string.lower(key)
                if lk == "t" then
                    if IsTypingInTextBox() then return end
                    HandleToggleAutoAimKey()
                end
            end
        end)
    end
end)

local GuiService = game:GetService("GuiService")
local function GetCrosshairPosition()
    local vp = Camera.ViewportSize
    local inset = GuiService:GetGuiInset()
    return Vector2.new(vp.X / 2, vp.Y / 2 + inset.Y / 2)
end

local UpdateFOVCircle
do
    if _G.ZHubFOVCircle then
        pcall(function() _G.ZHubFOVCircle:Remove() end)
        pcall(function() _G.ZHubFOVCircle:Destroy() end)
        _G.ZHubFOVCircle = nil
    end

    if parentContainer then
        for _, child in pairs(parentContainer:GetChildren()) do
            if child.Name == "FOVCircleGui" or child.Name == "ZHubFOVCircle" then
                pcall(function() child:Destroy() end)
            end
        end
    end

    local isTouch = UserInputService.TouchEnabled
    local FOVCircle = nil

    -- On PC/non-touch devices, try Drawing API first
    if not isTouch then
        pcall(function()
            if Drawing and typeof(Drawing.new) == "function" then
                FOVCircle = Drawing.new("Circle")
                FOVCircle.Thickness = 2
                FOVCircle.Color = Theme.Accent
                FOVCircle.Filled = false
                FOVCircle.Transparency = 1
                FOVCircle.Radius = _G.AimFOV or 100
                FOVCircle.Visible = false
                _G.ZHubFOVCircle = FOVCircle
            end
        end)
    end

    -- Create GuiFOVCircle on mobile OR if Drawing API is absent/failed
    local GuiFOVCircle = nil
    if isTouch or not FOVCircle then
        GuiFOVCircle = Instance.new("Frame")
        GuiFOVCircle.Name = "FOVCircleGui"
        GuiFOVCircle.BackgroundTransparency = 1
        GuiFOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
        GuiFOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        GuiFOVCircle.Visible = false
        GuiFOVCircle.ZIndex = 1000
        GuiFOVCircle.Active = false -- Never block touch inputs on mobile
        GuiFOVCircle.Parent = ScreenGui
        ApplyCorner(GuiFOVCircle, 999)
        ApplyStroke(GuiFOVCircle, Theme.Accent, 2, 0)
    end

    function UpdateFOVCircle()
        local shouldShow = (_G.ShowFOV == true) and (not _G.NearMode)

        if not shouldShow then
            if FOVCircle then pcall(function() FOVCircle.Visible = false end) end
            if GuiFOVCircle then GuiFOVCircle.Visible = false end
            return
        end

        local isDotMode = (not _G.AutoAim) and _G.AutoShoot
        local rawFOV = isDotMode and 5 or (_G.AimFOV or 100)
        
        -- Proportional scale factor for mobile screens (1080p base reference height)
        local scaleFactor = math.clamp(Camera.ViewportSize.Y / 1080, 0.35, 1.0)
        local fovRadius = isDotMode and 5 or (rawFOV * scaleFactor)

        if FOVCircle then
            local crosshairPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            pcall(function()
                FOVCircle.Radius = fovRadius
                FOVCircle.Position = crosshairPos
                FOVCircle.Color = Theme.Accent
                FOVCircle.Visible = true
            end)
        elseif GuiFOVCircle then
            GuiFOVCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
            GuiFOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
            GuiFOVCircle.Visible = true
        end
    end
end

-- [[ WALL CHECK ]] --
local AimRayParams = RaycastParams.new()
AimRayParams.FilterType = Enum.RaycastFilterType.Exclude
AimRayParams.IgnoreWater = true

local function IsPartVisible(targetPart)
    if not _G.AimWallCheck then return true end
    local myChar = LocalPlayer.Character
    if not myChar or not targetPart then return false end

    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = targetPos - origin
    if direction.Magnitude < 3.0 then return true end

    -- Exclude only our own character so any wall or obstacle between camera and target is caught
    AimRayParams.FilterDescendantsInstances = {myChar}

    local hit = workspace:Raycast(origin, direction, AimRayParams)
    if not hit then return true end

    local inst = hit.Instance
    if not inst then return true end

    -- If the ray directly hits the target character or one of its parts, it has clear line of sight
    local targetModel = targetPart.Parent
    if targetModel and inst:IsDescendantOf(targetModel) then
        return true
    end

    -- Hit a wall or obstacle
    return false
end

-- [[ TARGET SELECTION ]] --
-- CurrentLockedTarget declared above ToggleAutoAim so both systems share the same variable
local CurrentAimIsHead = false   -- Whether this engagement aims at head height

-- [[ TEAMMATE / HARMABILITY CHECK ]] --
local function IsTeammate(player, charModel)
    if not _G.TeamCheck then return false end
    if not player and not charModel then return false end
    if player == LocalPlayer then return true end

    local myChar = LocalPlayer.Character
    local char = charModel or (player and player.Character)
    if not player and char then
        player = Players:GetPlayerFromCharacter(char)
        if not player and char.Name then
            -- Fallback: try finding player by character name or display name
            player = Players:FindFirstChild(char.Name)
            if not player then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.DisplayName == char.Name or p.Name == char.Name then
                        player = p
                        break
                    end
                end
            end
        end
    end
    if player == LocalPlayer then return true end

    -- ForceField check: player has spawn protection / invincibility
    if char and char:FindFirstChildOfClass("ForceField") then
        return true
    end

    -- 1. Native Roblox Team check (pcall-protected for mobile executors)
    local sameTeam = false
    pcall(function()
        if player and LocalPlayer.Team and player.Team then
            if LocalPlayer.Team == player.Team then
                sameTeam = true
            elseif LocalPlayer.Team.Name ~= "" and LocalPlayer.Team.Name == player.Team.Name then
                sameTeam = true
            end
        end
    end)
    if sameTeam then return true end

    -- 2. TeamColor property check (pcall-protected for mobile executors)
    local sameColor = false
    pcall(function()
        if player and LocalPlayer.TeamColor and player.TeamColor and LocalPlayer.TeamColor == player.TeamColor then
            local colName = LocalPlayer.TeamColor.Name
            if colName ~= "White" and colName ~= "Medium stone grey" then
                sameColor = true
            end
        end
    end)
    if sameColor then return true end

    -- 3. Custom Attributes (Rivals TeamId, MatchTeam, SquadId, etc.)
    local teamKeys = {"Team", "team", "TeamId", "teamId", "MatchTeam", "matchTeam", "SquadId", "Squad", "squad", "TeamName", "teamName", "Faction", "Side", "Clan", "Party", "GameTeam", "TeamColor", "Color"}
    pcall(function()
        for _, key in ipairs(teamKeys) do
            local myAttr = LocalPlayer:GetAttribute(key) or (myChar and myChar:GetAttribute(key))
            local targetAttr = (player and player:GetAttribute(key)) or (char and char:GetAttribute(key))
            if myAttr ~= nil and targetAttr ~= nil then
                local strMy = tostring(myAttr)
                local strTarget = tostring(targetAttr)
                if strMy == strTarget and strMy ~= "" and strMy ~= "None" and strMy ~= "Neutral" and strMy ~= "0" and strMy ~= "nil" and strMy ~= "FFA" then
                    sameTeam = true
                end
            end
        end
    end)
    if sameTeam then return true end

    -- 4. Custom ValueObjects in Player / Character / leaderstats
    local function GetTeamValue(parent)
        if not parent then return nil end
        for _, key in ipairs(teamKeys) do
            local valObj = parent:FindFirstChild(key)
            if valObj and valObj:IsA("ValueBase") then
                return valObj.Value
            end
        end
        local ls = parent:FindFirstChild("leaderstats")
        if ls then
            for _, key in ipairs(teamKeys) do
                local valObj = ls:FindFirstChild(key)
                if valObj and valObj:IsA("ValueBase") then
                    return valObj.Value
                end
            end
        end
        return nil
    end

    local myVal = GetTeamValue(LocalPlayer) or GetTeamValue(myChar)
    local targetVal = (player and GetTeamValue(player)) or GetTeamValue(char)
    if myVal ~= nil and targetVal ~= nil then
        local strMy = tostring(myVal)
        local strTarget = tostring(targetVal)
        if strMy == strTarget and strMy ~= "" and strMy ~= "None" and strMy ~= "Neutral" and strMy ~= "0" and strMy ~= "nil" and strMy ~= "FFA" then
            return true
        end
    end

    -- 5. Body Color Matching (many mobile games distinguish teams by character body colors)
    if myChar and char then
        local function GetBodyColor(c)
            local bc = c:FindFirstChildOfClass("BodyColors")
            if bc then
                return bc.TorsoColor3 or bc.TorsoColor
            end
            local torso = c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("HumanoidRootPart")
            if torso and torso:IsA("BasePart") then
                return torso.Color
            end
            return nil
        end

        local myColor = GetBodyColor(myChar)
        local targetColor = GetBodyColor(char)
        if myColor and targetColor and typeof(myColor) == "Color3" and typeof(targetColor) == "Color3" then
            -- Check if colors are very similar (within tolerance for slight rendering differences on mobile)
            local diff = math.abs(myColor.R - targetColor.R) + math.abs(myColor.G - targetColor.G) + math.abs(myColor.B - targetColor.B)
            if diff < 0.15 then
                -- Same body color = likely same team (skip neutral grey/default colors)
                local brightness = myColor.R + myColor.G + myColor.B
                if brightness > 0.3 and brightness < 2.7 then
                    return true
                end
            end
        end
    end

    -- 6. Floating Teammate Icon / Custom Healthbar / Overhead GUI Detection
    --    Scans BillboardGui AND SurfaceGui on character descendants (mobile games use both)
    if char then
        for _, gui in ipairs(char:GetDescendants()) do
            if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                local gName = string.lower(gui.Name)
                -- Explicitly named team/ally/friendly indicators
                if gName:find("team") or gName:find("ally") or gName:find("friend") or gName:find("mate") or gName:find("squad") or gName:find("health") or gName:find("name") then
                    -- For "health" or "name" tags, only count as teammate if my character has one too
                    if gName:find("team") or gName:find("ally") or gName:find("friend") or gName:find("mate") or gName:find("squad") then
                        return true
                    end
                    -- For healthbar/nametag, check if ONLY teammates have them (my character should have one too)
                    if myChar then
                        local myHasGui = false
                        for _, mg in ipairs(myChar:GetDescendants()) do
                            if (mg:IsA("BillboardGui") or mg:IsA("SurfaceGui")) and string.lower(mg.Name) == gName then
                                myHasGui = true
                                break
                            end
                        end
                        -- Both characters have the same named GUI = likely same team system
                        if myHasGui then
                            -- Check for matching color indicators inside
                            local myLabel, targetLabel
                            for _, mg in ipairs(myChar:GetDescendants()) do
                                if (mg:IsA("BillboardGui") or mg:IsA("SurfaceGui")) and string.lower(mg.Name) == gName then
                                    myLabel = mg:FindFirstChildOfClass("TextLabel")
                                    break
                                end
                            end
                            targetLabel = gui:FindFirstChildOfClass("TextLabel")
                            if myLabel and targetLabel and myLabel.TextColor3 == targetLabel.TextColor3 then
                                return true
                            end
                        end
                    end
                end

                -- Check for floating icons (ImageLabel inside BillboardGui)
                local img = gui:FindFirstChildOfClass("ImageLabel")
                if img and img.Visible then
                    local imgName = string.lower(img.Name)
                    if imgName:find("team") or imgName:find("icon") or imgName:find("ally") or imgName:find("marker") or imgName:find("indicator") then
                        return true
                    end
                end

                -- Check for custom healthbar / overhead indicators with friendly colors
                for _, elem in ipairs(gui:GetDescendants()) do
                    if elem:IsA("TextLabel") then
                        local c = elem.TextColor3
                        -- Friendly green or cyan text
                        if (c.G > 0.6 and c.R < 0.4) or (c.B > 0.6 and c.R < 0.4) then
                            return true
                        end
                    elseif elem:IsA("Frame") or elem:IsA("ImageLabel") then
                        local c = elem.BackgroundColor3
                        if elem:IsA("ImageLabel") and elem.ImageColor3 then
                            c = elem.ImageColor3
                        end
                        if c and typeof(c) == "Color3" and ((c.G > 0.7 and c.R < 0.3) or (c.B > 0.7 and c.R < 0.3)) then
                            return true
                        end
                    end
                end
            end
        end
    end

    -- 7. Rivals In-Game Highlight Detection (Friendly = Green/Cyan/Blue highlight)
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Highlight") and child.Name ~= "ZESP" then
                local oc = child.OutlineColor
                local fc = child.FillColor
                if oc and typeof(oc) == "Color3" and ((oc.G > 0.6 and oc.R < 0.4) or (oc.B > 0.7 and oc.R < 0.3)) then
                    return true
                end
                if fc and typeof(fc) == "Color3" and ((fc.G > 0.6 and fc.R < 0.4) or (fc.B > 0.7 and fc.R < 0.3)) then
                    return true
                end
            end
        end
    end

    return false
end

-- [[ HITBOX EXPANDER SYSTEM (PLAYERS ONLY) ]] --
local OriginalHitboxProperties = {} -- [hrp] = {Size = Vector3, Transparency = number, CanCollide = boolean}

local function RestorePlayerHitboxes()
    for hrp, props in pairs(OriginalHitboxProperties) do
        if hrp and hrp.Parent then
            pcall(function()
                hrp.Size = props.Size
                hrp.Transparency = props.Transparency
                hrp.CanCollide = props.CanCollide
            end)
        end
    end
    OriginalHitboxProperties = {}
end

local function UpdatePlayerHitboxes()
    if not _G.HitboxExpander then return end
    local size = _G.HitboxSize or 15
    local targetSize = Vector3.new(size, size, size)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char.Parent then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then
                    local isTeammate = _G.TeamCheck and IsTeammate(player, char)
                    local isIgnored = _G.IgnoredPlayers and (_G.IgnoredPlayers[player.Name] or _G.IgnoredPlayers[player.DisplayName])

                    if not isTeammate and not isIgnored then
                        if not OriginalHitboxProperties[hrp] then
                            OriginalHitboxProperties[hrp] = {
                                Size = hrp.Size,
                                Transparency = hrp.Transparency,
                                CanCollide = hrp.CanCollide
                            }
                        end
                        if (hrp.Size - targetSize).Magnitude > 0.05 or hrp.CanCollide == true then
                            pcall(function()
                                hrp.Size = targetSize
                                hrp.Transparency = 0.65
                                hrp.CanCollide = false
                            end)
                        end
                    else
                        -- Teammate or ignored: restore original properties if expanded
                        if OriginalHitboxProperties[hrp] then
                            local props = OriginalHitboxProperties[hrp]
                            pcall(function()
                                hrp.Size = props.Size
                                hrp.Transparency = props.Transparency
                                hrp.CanCollide = props.CanCollide
                            end)
                            OriginalHitboxProperties[hrp] = nil
                        end
                    end
                end
            end
        end
    end

    -- Clean up invalid / dead references
    for hrp, _ in pairs(OriginalHitboxProperties) do
        if not hrp or not hrp.Parent or not hrp.Parent.Parent then
            OriginalHitboxProperties[hrp] = nil
        end
    end
end

pcall(function()
    Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and OriginalHitboxProperties[hrp] then
                OriginalHitboxProperties[hrp] = nil
            end
        end
    end)
end)

local function FindBestTarget()
    local crosshairPos = GetCrosshairPosition()
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end -- Can't calculate distances without our own HRP

    -- Helper: validate a character is a live, non-ignored, non-teammate enemy
    local function IsValidEnemy(char)
        if not char or not char.Parent then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        local player = Players:GetPlayerFromCharacter(char) or Players:FindFirstChild(char.Name)
        if player then
            local ign = _G.IgnoredPlayers[player.Name] or _G.IgnoredPlayers[player.DisplayName] or _G.IgnoredPlayers[tostring(player.UserId)]
            if ign then return false end
        end
        if IsTeammate(player, char) then return false end
        return true
    end

    -- Helper: check if character has line of sight from camera
    local function HasLineOfSight(char)
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        local head = char:FindFirstChild("Head")
        if hrp and IsPartVisible(hrp) then return true end
        if head and IsPartVisible(head) then return true end
        return false
    end

    -- Helper: get distance from myHRP to character
    local function GetDist3D(char)
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not hrp then return math.huge end
        return (hrp.Position - myHRP.Position).Magnitude
    end

    -- Sticky lock: keep tracking same character if still valid
    if CurrentLockedTarget and CurrentLockedTarget.Parent and IsValidEnemy(CurrentLockedTarget) then
        local dist3D = GetDist3D(CurrentLockedTarget)
        if dist3D <= _G.ESPRange then
            if _G.NearMode then
                -- Near Mode sticky: keep lock BUT allow switch if a much closer enemy appeared (within 60% of current distance)
                local hrp = CurrentLockedTarget:FindFirstChild("HumanoidRootPart") or CurrentLockedTarget:FindFirstChild("Torso") or CurrentLockedTarget:FindFirstChild("UpperTorso")
                -- For close-range (< 30 studs) skip wall check since target may be just around corner
                local hasLOS = (dist3D < 30) or HasLineOfSight(CurrentLockedTarget)
                if hasLOS then
                    -- Check if there's a significantly closer enemy
                    local closerThreshold = dist3D * 0.6
                    local foundCloser = false
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer then
                            local char = p.Character
                            if char and char ~= CurrentLockedTarget and IsValidEnemy(char) then
                                local d = GetDist3D(char)
                                if d < closerThreshold and HasLineOfSight(char) then
                                    foundCloser = true
                                    break
                                end
                            end
                        end
                    end
                    if not foundCloser then
                        return CurrentLockedTarget
                    end
                end
            else
                -- FOV Mode sticky: keep lock if target is on screen within relaxed FOV
                if HasLineOfSight(CurrentLockedTarget) then
                    local hrp = CurrentLockedTarget:FindFirstChild("HumanoidRootPart") or CurrentLockedTarget:FindFirstChild("Torso") or CurrentLockedTarget:FindFirstChild("UpperTorso")
                    if hrp then
                        local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local d = (Vector2.new(sp.X, sp.Y) - crosshairPos).Magnitude
                            if d <= _G.AimFOV * 2.0 then
                                return CurrentLockedTarget
                            end
                        elseif dist3D <= 10 then
                            -- Close-quarters pass-through exception
                            return CurrentLockedTarget
                        end
                    end
                end
            end
        end
    end

    -- Find new closest target
    local bestChar = nil

    if _G.NearMode then
        -- NEAR MODE: Find target closest by 3D world distance (ignores FOV & screen bounds)
        local bestDist3D = _G.ESPRange or 1000

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                if char and IsValidEnemy(char) then
                    local dist3D = GetDist3D(char)
                    if dist3D < bestDist3D then
                        -- For close range (< 30 studs), skip wall check to avoid losing targets around corners
                        if dist3D < 30 or HasLineOfSight(char) then
                            bestDist3D = dist3D
                            bestChar = char
                        end
                    end
                end
            end
        end
    else
        -- FOV MODE: Find target closest to crosshair within 2D screen FOV radius
        local bestFOV = _G.AimFOV or 150

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                if char and IsValidEnemy(char) then
                    local dist3D = GetDist3D(char)
                    if dist3D <= _G.ESPRange then
                        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                        local head = char:FindFirstChild("Head")
                        local checkPart = (CurrentAimIsHead and head) or hrp or head
                        if checkPart then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(checkPart.Position)
                            if onScreen then
                                local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - crosshairPos).Magnitude
                                if dist2D <= bestFOV then
                                    if HasLineOfSight(char) then
                                        bestFOV = dist2D
                                        bestChar = char
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- New target acquired — roll headshot chance once per engagement
    if bestChar ~= CurrentLockedTarget then
        CurrentLockedTarget = bestChar
        CurrentAimIsHead = bestChar and (math.random() <= (_G.HeadshotChance or 0.40))
    end

    return bestChar
end

local _smoothedCameraRotation = nil
local _targetGraceTime = 0

local function RunAutoAim(dt)
    if not _G.AutoAim then
        CurrentLockedTarget = nil
        _lastTargetChar = nil
        _smoothedCameraRotation = nil
        return
    end

    local targetChar = FindBestTarget()
    local now = tick()

    if targetChar then
        _lastTargetChar = targetChar
        _targetGraceTime = now
    elseif _lastTargetChar and _lastTargetChar.Parent and (now - _targetGraceTime < 0.25) then
        -- 0.25s Grace period: maintain lock across minor 1-frame raycast/animation slips
        local hum = _lastTargetChar:FindFirstChildOfClass("Humanoid")
        local p = Players:GetPlayerFromCharacter(_lastTargetChar) or Players:FindFirstChild(_lastTargetChar.Name)
        if hum and hum.Health > 0 and not IsTeammate(p, _lastTargetChar) then
            targetChar = _lastTargetChar
        else
            _lastTargetChar = nil
        end
    else
        _lastTargetChar = nil
    end

    if not targetChar then
        CurrentLockedTarget = nil
        _smoothedCameraRotation = nil
        return
    end

    local hrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
    if not hrp then return end

    -- Stable aim point: HumanoidRootPart position + fixed Y offset (no animation jitter)
    local yOffset = CurrentAimIsHead and 1.5 or 0
    local aimPoint = hrp.Position + Vector3.new(0, yOffset, 0)

    -- Gentle velocity lead (horizontal only, prevents vertical jumping jitter)
    local vel = Vector3.new()
    pcall(function()
        local v = hrp.AssemblyLinearVelocity or hrp.Velocity
        if v then vel = Vector3.new(v.X, 0, v.Z) end
    end)
    aimPoint = aimPoint + vel * 0.015

    local targetCFrame = CFrame.new(Camera.CFrame.Position, aimPoint)

    if _G.SmoothAim then
        -- Initialize smoothed rotation on target acquisition to current camera view
        if not _smoothedCameraRotation then
            _smoothedCameraRotation = Camera.CFrame.Rotation
        end

        local smoothVal = math.clamp(_G.AimSmoothness or 0.15, 0.01, 1.0)
        local alpha = math.clamp(smoothVal * math.clamp(dt * 60, 0.5, 2.0), 0.02, 0.35)
        _smoothedCameraRotation = _smoothedCameraRotation:Lerp(targetCFrame.Rotation, alpha)

        -- Apply persistent smoothly-interpolated rotation at current physical camera position
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * _smoothedCameraRotation
    else
        _smoothedCameraRotation = nil
        -- Direct Aim: snap camera directly to target
        Camera.CFrame = targetCFrame
    end
end

-- [[ AUTO SHOOT SYSTEM ]] --
local _lastShootTime = 0
local AUTO_SHOOT_RATE = 0.1 -- 10 shots per second max

local VIM = game:GetService("VirtualInputManager")

local function RunAutoShoot()
    if not _G.AutoShoot then return end
    if not _G.AutoAim then return end

    local targetChar = CurrentLockedTarget or _lastTargetChar
    if not targetChar or not targetChar.Parent then
        targetChar = FindBestTarget()
    end
    if not targetChar or not targetChar.Parent then return end

    -- Verify target is an enemy and alive
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local p = Players:GetPlayerFromCharacter(targetChar) or Players:FindFirstChild(targetChar.Name)
    if IsTeammate(p, targetChar) then return end

    -- Instant Wall Check Guard: Never shoot if target is behind a wall or obstacle!
    local hrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
    local head = targetChar:FindFirstChild("Head")
    local checkPart = (CurrentAimIsHead and head) or hrp or head
    if not checkPart then return end

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetDist3D = (myHRP and hrp) and (hrp.Position - myHRP.Position).Magnitude or 999

    if _G.AimWallCheck then
        -- Near Mode relaxes wall check for close-range targets (< 30 studs)
        local isClose = _G.NearMode and targetDist3D < 30
        if not isClose and not (IsPartVisible(checkPart) or (head and IsPartVisible(head)) or (hrp and IsPartVisible(hrp))) then
            return -- Target is behind a wall!
        end
    end

    -- Check all body parts to determine if crosshair is aligned with enemy
    local crosshair = GetCrosshairPosition()
    local minPartDist = 99999
    local anyOnScreen = false

    local checkParts = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
    for _, partName in ipairs(checkParts) do
        local part = targetChar:FindFirstChild(partName)
        if part then
            local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                anyOnScreen = true
                local d = (Vector2.new(sp.X, sp.Y) - crosshair).Magnitude
                if d < minPartDist then
                    minPartDist = d
                end
            end
        end
    end

    -- In Near Mode, camera is forced to track the target, so if nothing is on screen yet
    -- it's likely a 1-frame delay — allow firing for close targets
    if not anyOnScreen then
        if _G.NearMode and targetDist3D < 30 then
            minPartDist = 0 -- Trust camera tracking, allow shot
        else
            return
        end
    end

    -- Alignment threshold: Near Mode snaps camera directly so use tight tolerance
    -- SmoothAim needs wider tolerance since camera is still gliding
    local maxAllowedDist
    if _G.NearMode then
        maxAllowedDist = _G.SmoothAim and math.clamp(120 * (Camera.ViewportSize.Y / 1080), 60, 150) or 200
    else
        maxAllowedDist = _G.SmoothAim and math.clamp(80 * (Camera.ViewportSize.Y / 1080), 40, 100) or math.max(_G.AimFOV or 150, 100)
    end
    if minPartDist > maxAllowedDist then
        return
    end

    local now = tick()
    if (now - _lastShootTime) < AUTO_SHOOT_RATE then return end
    _lastShootTime = now

    local char = LocalPlayer.Character
    if not char then return end

    -- 1. Fire tool natively via Roblox API (if standard tool exists)
    local toolFired = false
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function()
            tool:Activate()
            toolFired = true
        end)

        pcall(function()
            for _, child in ipairs(tool:GetDescendants()) do
                if child:IsA("RemoteEvent") then
                    local lname = string.lower(child.Name)
                    if lname:find("shoot") or lname:find("fire") or lname:find("remote") or lname:find("gun") or lname:find("action") or lname:find("bullet") or lname:find("attack") or lname:find("damage") then
                        pcall(function() child:FireServer() end)
                        toolFired = true
                    end
                end
            end
        end)
    end

    -- 2. Input-specific firing method (for games like Rivals that use input controllers):
    if not toolFired then
        pcall(function()
            if UserInputService.TouchEnabled then
                -- MOBILE (Delta executor compatible): Fire game's input connections directly
                local vp = Camera.ViewportSize
                local posX, posY = vp.X / 2, vp.Y / 2

                if ShootTargetWidget and ShootTargetWidget.Parent and ShootTargetWidget.Visible then
                    local centerPos = ShootTargetWidget.AbsolutePosition + (ShootTargetWidget.AbsoluteSize / 2)
                    posX, posY = centerPos.X, centerPos.Y
                end

                local function fireConn(conn, ...)
                    local args = {...}
                    pcall(function()
                        if conn.Function then
                            conn.Function(unpack(args))
                        end
                    end)
                    pcall(function()
                        if conn.Fire then
                            conn:Fire(unpack(args))
                        end
                    end)
                end

                local fakeMouseDown = {
                    UserInputType = Enum.UserInputType.MouseButton1,
                    UserInputState = Enum.UserInputState.Begin,
                    Position = Vector3.new(posX, posY, 0),
                    Delta = Vector3.new(0, 0, 0),
                    KeyCode = Enum.KeyCode.Unknown
                }
                local fakeTouchDown = {
                    UserInputType = Enum.UserInputType.Touch,
                    UserInputState = Enum.UserInputState.Begin,
                    Position = Vector3.new(posX, posY, 0),
                    Delta = Vector3.new(0, 0, 0),
                    KeyCode = Enum.KeyCode.Unknown
                }
                local fakeMouseUp = {
                    UserInputType = Enum.UserInputType.MouseButton1,
                    UserInputState = Enum.UserInputState.End,
                    Position = Vector3.new(posX, posY, 0),
                    Delta = Vector3.new(0, 0, 0),
                    KeyCode = Enum.KeyCode.Unknown
                }
                local fakeTouchUp = {
                    UserInputType = Enum.UserInputType.Touch,
                    UserInputState = Enum.UserInputState.End,
                    Position = Vector3.new(posX, posY, 0),
                    Delta = Vector3.new(0, 0, 0),
                    KeyCode = Enum.KeyCode.Unknown
                }

                pcall(function()
                    if getconnections then
                        local conns = getconnections(UserInputService.InputBegan)
                        for i = 1, #conns do
                            fireConn(conns[i], fakeMouseDown, false)
                            fireConn(conns[i], fakeTouchDown, false)
                        end

                        task.delay(0.02, function()
                            pcall(function()
                                local endConns = getconnections(UserInputService.InputEnded)
                                for i = 1, #endConns do
                                    fireConn(endConns[i], fakeMouseUp, false)
                                    fireConn(endConns[i], fakeTouchUp, false)
                                end
                            end)
                        end)
                    end
                end)
            else
                -- PC: Universal Mouse Click & Virtual Input Simulation
                local vp = Camera.ViewportSize
                if mouse1click then
                    mouse1click()
                elseif mouse1press then
                    mouse1press()
                    task.delay(0.02, function() pcall(mouse1release) end)
                else
                    pcall(function()
                        local VU = game:GetService("VirtualUser")
                        VU:Button1Down(Vector2.new(vp.X / 2, vp.Y / 2))
                        task.delay(0.02, function()
                            pcall(function() VU:Button1Up(Vector2.new(vp.X / 2, vp.Y / 2)) end)
                        end)
                    end)
                    pcall(function()
                        VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0)
                        task.delay(0.02, function()
                            pcall(function()
                                VIM:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0)
                            end)
                        end)
                    end)
                end
            end
        end)
    end
end


-- [[ ZERO-ALLOCATION ESP SYSTEM ]] --
local function GetOrCreateESP(player)
    if player == LocalPlayer then return nil, nil end
    local char = player.Character
    if not char or not char:FindFirstChild("Head") then return nil, nil end

    local high = char:FindFirstChild("ZESP")
    if not high then
    high = Instance.new("Highlight")
    high.Name = "ZESP"
    high.FillColor = Theme.Accent
    high.FillTransparency = 0.5
    high.OutlineColor = Theme.AccentGlow
    high.OutlineTransparency = 0
    high.Enabled = false
    high.Parent = char
    end

    local head = char:FindFirstChild("Head")
    local tag = char:FindFirstChild("ZTag") or (head and head:FindFirstChild("ZTag"))
    if not tag then
    tag = Instance.new("BillboardGui")
    tag.Name = "ZTag"
    tag.Size = UDim2.new(0, 100, 0, 40)
    tag.AlwaysOnTop = true
    tag.ExtentsOffset = Vector3.new(0, 2.5, 0)
    tag.MaxDistance = _G.ESPRange or 1000
    tag.Enabled = false
    if head then tag.Adornee = head end
    tag.Parent = char

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = Theme.Text
    tl.TextStrokeColor3 = Theme.Background
    tl.TextStrokeTransparency = 0.5
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 13
    tl.Text = player.DisplayName
    tl.Parent = tag
    end

    return high, tag
end

local function SetESPState(player, visible)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    local head = char:FindFirstChild("Head")
    local high = char:FindFirstChild("ZESP")
    local tag = char:FindFirstChild("ZTag") or (head and head:FindFirstChild("ZTag"))

    if visible then
    if not high or not tag then
        high, tag = GetOrCreateESP(player)
    end
    if high then high.Enabled = true end
    if tag then
        tag.MaxDistance = _G.ESPRange or 1000
        tag.Enabled = true
    end
    else
    if high then high.Enabled = false end
    if tag then tag.Enabled = false end
    end
end

-- ESP_RANGE is now controlled by _G.ESPRange (default 1000 studs)

local ESPRayParams = RaycastParams.new()
ESPRayParams.FilterType = Enum.RaycastFilterType.Exclude
ESPRayParams.IgnoreWater = true

local function IsPlayerOccluded(targetChar)
    local myChar = LocalPlayer.Character
    if not myChar or not targetChar then return false end

    local hrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("Head")
    if not hrp then return false end

    local origin = Camera.CFrame.Position
    local direction = hrp.Position - origin
    local dist = direction.Magnitude
    if dist < 0.5 or dist > _G.ESPRange then return false end

    -- Fast check: don't raycast for players off-screen
    local _, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then return false end

    ESPRayParams.FilterDescendantsInstances = {myChar, targetChar}

    local hit = workspace:Raycast(origin, direction, ESPRayParams)
    if not hit then return false end

    local inst = hit.Instance
    if not inst then return false end

    if inst:IsDescendantOf(targetChar) or inst:IsDescendantOf(myChar) then return false end
    if inst.CanCollide == false then return false end
    if inst.Transparency >= 0.5 then return false end
    if inst:IsA("Accessory") or inst:FindFirstAncestorWhichIsA("Accessory") then return false end

    return true
end

local function RefreshAllESP()
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        if _G.EspEnabled and myHRP then
            local theirChar = p.Character
            if theirChar then
                local theirHRP = theirChar:FindFirstChild("HumanoidRootPart") or theirChar:FindFirstChild("Torso")
                if theirHRP and (theirHRP.Position - myHRP.Position).Magnitude <= _G.ESPRange then
                    SetESPState(p, true)
                else
                    SetESPState(p, false)
                end
            else
                SetESPState(p, false)
            end
        else
            SetESPState(p, false)
        end
    end
    end
end

-- Auto-apply ESP to new characters
local function HookPlayerESP(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if _G.EspEnabled then
        RefreshAllESP()
    end
    end)
end

for _, p in pairs(Players:GetPlayers()) do
    HookPlayerESP(p)
end
Players.PlayerAdded:Connect(HookPlayerESP)

do
    -- SINGLE UserInputService Input handlers for all sliders and draggers
    local draggingSlider = nil

    local function CreateInputBox(name, placeholder, width, parentFrame)
        local Container = Instance.new("Frame")
        Container.Name = name
        Container.BackgroundColor3 = Theme.Surface
        Container.Size = UDim2.new(0, width, 0, 40)
        Container.Parent = parentFrame
        ApplyCorner(Container, 8)
        ApplyStroke(Container, Theme.Border, 1) 

        local iconMap = {
            Speed = "⚡",
            Time = "⏱",
            Reach = "🗡",
            KillAuraRange = "💀",
            ESPRange = "👁",
            AimFOV = "🎯"
        }

        local Icon = Instance.new("TextLabel")
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0, 12, 0, 0)
        Icon.Size = UDim2.new(0, 20, 1, 0)
        Icon.Font = Enum.Font.GothamBold
        Icon.Text = iconMap[name] or "⏱"
        Icon.TextColor3 = Theme.Accent
        Icon.TextSize = 14
        Icon.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 35, 0, 0)
        Label.Size = UDim2.new(0, 80, 1, 0)
        Label.Font = Enum.Font.GothamMedium
        Label.Text = (name == "KillAuraRange" and "Aura Range:") or (name == "ESPRange" and "ESP Range:") or (name == "AimFOV" and "Aim FOV:") or name .. ":"
        Label.TextColor3 = Theme.TextMuted
        Label.TextSize = 12
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container

        local Input = Instance.new("TextBox")
        Input.Name = "Input"
        Input.BackgroundTransparency = 1
        Input.Position = UDim2.new(0, 115, 0, 0)
        Input.Size = UDim2.new(1, -125, 1, 0)
        if name == "Speed" or name == "Time" then
            Label.Size = UDim2.new(0, 0, 1, 0)
            Label.Text = ""
            Input.Position = UDim2.new(0, 35, 0, 0)
            Input.Size = UDim2.new(1, -45, 1, 0)
        end
        Input.Font = Enum.Font.GothamMedium
        Input.PlaceholderText = placeholder
        Input.TextColor3 = Theme.Text
        Input.PlaceholderColor3 = Theme.TextMuted
        Input.TextSize = 12
        Input.TextXAlignment = Enum.TextXAlignment.Left
        Input.ClearTextOnFocus = false
        Input.Parent = Container

        return Input, Container
    end

    local function CreateSlider(name, layoutOrder, icon, min, max, default, updateFunc)
        local Frame = Instance.new("Frame")
        Frame.Name = name .. "Slider"
        Frame.LayoutOrder = layoutOrder
        Frame.BackgroundColor3 = Theme.Surface
        Frame.Size = UDim2.new(1, 0, 0, 60)
        Frame.Parent = Content
        ApplyCorner(Frame, 8)
        ApplyStroke(Frame, Theme.Border, 1)

        local Header = Instance.new("Frame")
        Header.BackgroundTransparency = 1
        Header.Size = UDim2.new(1, 0, 0, 30)
        Header.Parent = Frame

        local IconLabel = Instance.new("TextLabel")
        IconLabel.BackgroundTransparency = 1
        IconLabel.Position = UDim2.new(0, 12, 0, 0)
        IconLabel.Size = UDim2.new(0, 20, 1, 0)
        IconLabel.Font = Enum.Font.GothamBold
        IconLabel.Text = icon
        IconLabel.TextColor3 = Theme.Accent
        IconLabel.TextSize = 14
        IconLabel.Parent = Header

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Position = UDim2.new(0, 35, 0, 0)
        TitleLabel.Size = UDim2.new(0, 150, 1, 0)
        TitleLabel.Font = Enum.Font.GothamMedium
        TitleLabel.Text = name
        TitleLabel.TextColor3 = Theme.Text
        TitleLabel.TextSize = 12
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = Header

        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Position = UDim2.new(1, -60, 0, 0)
        ValueLabel.Size = UDim2.new(0, 50, 1, 0)
        ValueLabel.Font = Enum.Font.GothamBold
        ValueLabel.Text = tostring(default)
        ValueLabel.TextColor3 = Theme.Accent
        ValueLabel.TextSize = 12
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        ValueLabel.Parent = Header

        local Track = Instance.new("Frame")
        Track.Name = "Track"
        Track.BackgroundColor3 = Theme.Background
        Track.Position = UDim2.new(0, 15, 0, 40)
        Track.Size = UDim2.new(1, -30, 0, 6)
        Track.Parent = Frame
        ApplyCorner(Track, 3)

        local Fill = Instance.new("Frame")
        Fill.BackgroundColor3 = Theme.Accent
        Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
        Fill.Parent = Track
        ApplyCorner(Fill, 3)
        ApplyGradient(Fill, Theme.AccentGlow, Theme.Accent)

        local Knob = Instance.new("Frame")
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Knob.Position = UDim2.new(1, -8, 0.5, -8)
        Knob.Size = UDim2.new(0, 16, 0, 16)
        Knob.Parent = Fill
        ApplyCorner(Knob, 8)
        ApplyStroke(Knob, Theme.Border, 1)

        local DragBtn = Instance.new("TextButton")
        DragBtn.BackgroundTransparency = 1
        DragBtn.Size = UDim2.new(1, 0, 1, 0)
        DragBtn.Text = ""
        DragBtn.Parent = Track

        local function UpdateValue(val)
            val = math.clamp(val, min, max)
            local pct = (val - min) / (max - min)
            Fill.Size = UDim2.new(pct, 0, 1, 0)
            if name == "Aim Smoothness" then
                ValueLabel.Text = string.format("%.2f", val)
            elseif name == "Headshot Rate" then
                ValueLabel.Text = string.format("%d%%", math.floor(val))
            else
                ValueLabel.Text = tostring(math.floor(val))
            end
            updateFunc(val)
        end

        DragBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = {Track = Track, Min = min, Max = max, Update = UpdateValue}
                local pos = input.Position.X
                local pct = math.clamp((pos - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                UpdateValue(min + pct * (max - min))
            end
        end)

        return Frame, UpdateValue, ValueLabel
    end

    -- 1. Toggle Grid
    local ToggleGrid = Instance.new("Frame")
    ToggleGrid.Name = "ToggleGrid"
    ToggleGrid.LayoutOrder = 1
    ToggleGrid.BackgroundTransparency = 1
    ToggleGrid.AutomaticSize = Enum.AutomaticSize.Y
    ToggleGrid.Size = UDim2.new(1, 0, 0, 470)
    ToggleGrid.Parent = Content

    local GridLayout = Instance.new("UIGridLayout")
    GridLayout.CellSize = UDim2.new(0, 155, 0, 40)
    GridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    GridLayout.Parent = ToggleGrid

    local function CreateToggleButton(name, icon, isActive)
        local Button = Instance.new("TextButton")
        Button.Name = name
        Button.BackgroundColor3 = isActive and Theme.Accent or Theme.Surface
        Button.Size = UDim2.new(0, 155, 0, 40)
        Button.Font = Enum.Font.GothamBold
        Button.Text = ""
        Button.AutoButtonColor = false
        Button.Parent = ToggleGrid
        ApplyCorner(Button, 8)

        local stroke = ApplyStroke(Button, isActive and Theme.AccentGlow or Theme.Border, 1)

        local IconLabel = Instance.new("TextLabel")
        IconLabel.BackgroundTransparency = 1
        IconLabel.Position = UDim2.new(0, 12, 0, 0)
        IconLabel.Size = UDim2.new(0, 20, 1, 0)
        IconLabel.Font = Enum.Font.SourceSans
        IconLabel.Text = icon
        IconLabel.TextColor3 = isActive and Theme.Text or Theme.TextMuted
        IconLabel.TextSize = 16
        IconLabel.Parent = Button

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 35, 0, 0)
        Label.Size = UDim2.new(1, -70, 1, 0)
        Label.Font = Enum.Font.GothamMedium
        Label.Text = name
        Label.TextColor3 = isActive and Theme.Text or Theme.TextMuted
        Label.TextSize = 11
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Button

        local Status = Instance.new("Frame")
        Status.BackgroundColor3 = isActive and Theme.Success or Theme.Danger
        Status.Position = UDim2.new(1, -20, 0.5, -5)
        Status.Size = UDim2.new(0, 10, 0, 10)
        Status.Parent = Button
        ApplyCorner(Status, 999)

        local function UpdateState(active)
            Button.BackgroundColor3 = active and Theme.Accent or Theme.Surface
            IconLabel.TextColor3 = active and Theme.Text or Theme.TextMuted
            Label.TextColor3 = active and Theme.Text or Theme.TextMuted
            Status.BackgroundColor3 = active and Theme.Success or Theme.Danger
            stroke.Color = active and Theme.AccentGlow or Theme.Border
        end

        return Button, UpdateState
    end

    local AutoAimBtn,   UpdateAutoAim         = CreateToggleButton("Auto Aim [T]", "🎯", false)
    _updateAutoAimFunc = UpdateAutoAim
    local AutoShootBtn, UpdateAutoShoot       = CreateToggleButton("Auto Shoot",   "🔫", _G.AutoShoot)
    local AimModeBtn,   UpdateAimMode         = CreateToggleButton("Smooth Aim",   "🔄", false)
    local NearModeBtn,  UpdateNearMode        = CreateToggleButton("Near Mode",    "📍", _G.NearMode or false)
    local TeamCheckBtn, UpdateTeamCheck       = CreateToggleButton("Team Check",   "🤝", _G.TeamCheck)
    local FOVBtn,       UpdateShowFOV         = CreateToggleButton("Show FOV",     "⭕", _G.ShowFOV)
    local EspBtn,       UpdateEsp             = CreateToggleButton("ESP",          "👁", _G.EspEnabled or false)
    local BrightBtn,    UpdateBright          = CreateToggleButton("FullBright",   "☀️", false)
    local NoclipBtn,    UpdateNoclip          = CreateToggleButton("Noclip",       "👻", false)
    local FlyBtn,       UpdateFly             = CreateToggleButton("Fly",          "🚀", false)
    local SpeedBtn,     UpdateSpeed           = CreateToggleButton("Speed",        "⚡", false)
    local InfJumpBtn,   UpdateInfJump         = CreateToggleButton("Inf Jump",     "🦘", false)
    local KillAuraBtn,  UpdateKillAura        = CreateToggleButton("Kill Aura",    "💀", false)
    local ReachBtn,     UpdateReach           = CreateToggleButton("Reach",        "🗡", false)
    local HitboxBtn,    UpdateHitbox          = CreateToggleButton("Hitbox [H]",   "📦", _G.HitboxExpander or false)
    local FreeCamBtn,   UpdateFreeCam         = CreateToggleButton("FreeCam",      "🎥", false)
    local SafeBtn,      UpdateSafe            = CreateToggleButton("Safe Mode",    "🛡",  true)

    AutoAimBtn.MouseButton1Click:Connect(function() ToggleAutoAim() end)
    AutoShootBtn.MouseButton1Click:Connect(function() _G.AutoShoot = not _G.AutoShoot; UpdateAutoShoot(_G.AutoShoot); if ShootTargetWidget then ShootTargetWidget.Visible = _G.AutoShoot and UserInputService.TouchEnabled end; SaveConfig() end)
    AimModeBtn.MouseButton1Click:Connect(function() _G.SmoothAim = not _G.SmoothAim; UpdateAimMode(_G.SmoothAim); SaveConfig() end)
    NearModeBtn.MouseButton1Click:Connect(function() _G.NearMode = not _G.NearMode; UpdateNearMode(_G.NearMode); UpdateFOVCircle(); SaveConfig() end)
    TeamCheckBtn.MouseButton1Click:Connect(function() _G.TeamCheck = not _G.TeamCheck; UpdateTeamCheck(_G.TeamCheck); SaveConfig() end)
    FOVBtn.MouseButton1Click:Connect(function() _G.ShowFOV = not _G.ShowFOV; UpdateShowFOV(_G.ShowFOV); SaveConfig() end)
    EspBtn.MouseButton1Click:Connect(function() _G.EspEnabled = not _G.EspEnabled; UpdateEsp(_G.EspEnabled); RefreshAllESP(); SaveConfig() end)
    BrightBtn.MouseButton1Click:Connect(function() _G.FullBright = not _G.FullBright; UpdateBright(_G.FullBright); if not _G.FullBright then RestoreLighting() end end)
    NoclipBtn.MouseButton1Click:Connect(function() _G.Noclip = not _G.Noclip; UpdateNoclip(_G.Noclip) end)
    FlyBtn.MouseButton1Click:Connect(function()
        _G.Fly = not _G.Fly
        UpdateFly(_G.Fly)
        if not _G.Fly then
            StopFly()
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.PlatformStand = false end
        end
    end)
    SpeedBtn.MouseButton1Click:Connect(function()
        _G.SpeedEnabled = not _G.SpeedEnabled
        UpdateSpeed(_G.SpeedEnabled)
        if not _G.SpeedEnabled then
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = 16 end
        end
    end)
    InfJumpBtn.MouseButton1Click:Connect(function() _G.InfJump = not _G.InfJump; UpdateInfJump(_G.InfJump) end)
    KillAuraBtn.MouseButton1Click:Connect(function()
        _G.KillAura = not _G.KillAura
        UpdateKillAura(_G.KillAura)
        if not _G.KillAura then
            KillAuraLastHit = {}
        end
    end)
    ReachBtn.MouseButton1Click:Connect(function()
        _G.ReachEnabled = not _G.ReachEnabled
        UpdateReach(_G.ReachEnabled)
        if not _G.ReachEnabled then
            DestroyReachPart()
            RestoreToolHitbox()
        else
            CreateReachPart()
        end
    end)
    HitboxBtn.MouseButton1Click:Connect(function()
        _G.HitboxExpander = not _G.HitboxExpander
        UpdateHitbox(_G.HitboxExpander)
        if _G.HitboxExpander then
            UpdatePlayerHitboxes()
        else
            RestorePlayerHitboxes()
        end
        SaveConfig()
    end)
    FreeCamBtn.MouseButton1Click:Connect(function()
        _G.FreeCam = not _G.FreeCam
        UpdateFreeCam(_G.FreeCam)
        ToggleFreeCam()
    end)
    SafeBtn.MouseButton1Click:Connect(function() _G.SafeMode = not _G.SafeMode; UpdateSafe(_G.SafeMode); SaveConfig() end)

    -- 2,3,4. Sliders
    local _, _, FovValueLabel = CreateSlider("Aim FOV", 2, "🎯", 10, 600, _G.AimFOV, function(val) _G.AimFOV = val; SaveConfig() end)
    local _, _, _ = CreateSlider("Headshot Rate", 3, "🎯", 0, 100, _G.HeadshotChance * 100, function(val) _G.HeadshotChance = val / 100; SaveConfig() end)
    local _, _, _ = CreateSlider("Aim Smoothness", 4, "🔄", 0.01, 1, _G.AimSmoothness, function(val) _G.AimSmoothness = val; SaveConfig() end)

    -- 5. Speed & Time Input
    local InputSection = Instance.new("Frame")
    InputSection.LayoutOrder = 5
    InputSection.BackgroundTransparency = 1
    InputSection.Size = UDim2.new(1, 0, 0, 45)
    InputSection.Parent = Content
    local InputLayout = Instance.new("UIListLayout")
    InputLayout.FillDirection = Enum.FillDirection.Horizontal
    InputLayout.Padding = UDim.new(0, 10)
    InputLayout.Parent = InputSection

    local SpeedInput, _ = CreateInputBox("Speed", "Speed: 50", 155, InputSection)
    SpeedInput.Text = tostring(_G.MovementSpeed)
    SpeedInput.FocusLost:Connect(function()
        local val = tonumber(SpeedInput.Text:match("%d+"))
        if val then _G.MovementSpeed = val; SaveConfig() end
        SpeedInput.Text = tostring(_G.MovementSpeed)
    end)

    local TimeInput, _ = CreateInputBox("Time", "Time: 1x", 155, InputSection)
    TimeInput.Text = tostring(_G.TimeScale) .. "x"
    TimeInput.FocusLost:Connect(function()
        local val = tonumber(TimeInput.Text:match("%d+%.?%d*"))
        if val then _G.TimeScale = val; SaveConfig() end
        TimeInput.Text = tostring(_G.TimeScale) .. "x"
    end)

    -- 6. Reach & Hitbox Inputs
    local ReachInputSection = Instance.new("Frame")
    ReachInputSection.LayoutOrder = 6
    ReachInputSection.BackgroundTransparency = 1
    ReachInputSection.Size = UDim2.new(1, 0, 0, 45)
    ReachInputSection.Parent = Content
    local ReachInputLayout = Instance.new("UIListLayout")
    ReachInputLayout.FillDirection = Enum.FillDirection.Horizontal
    ReachInputLayout.Padding = UDim.new(0, 10)
    ReachInputLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ReachInputLayout.Parent = ReachInputSection
    local ReachInput, ReachContainer = CreateInputBox("Reach", "15", 155, ReachInputSection)
    ReachInput.Text = tostring(_G.ReachDistance)
    ReachInput.FocusLost:Connect(function()
        local val = tonumber(ReachInput.Text:match("%d+%.?%d*"))
        if val then _G.ReachDistance = val; SaveConfig() end
        ReachInput.Text = tostring(_G.ReachDistance)
    end)
    local HitboxInput, HitboxContainer = CreateInputBox("Hitbox", "15", 155, ReachInputSection)
    HitboxInput.Text = tostring(_G.HitboxSize or 15)
    HitboxInput.FocusLost:Connect(function()
        local val = tonumber(HitboxInput.Text:match("%d+%.?%d*"))
        if val then
            _G.HitboxSize = math.clamp(val, 2, 100)
            SaveConfig()
            if _G.HitboxExpander then UpdatePlayerHitboxes() end
        end
        HitboxInput.Text = tostring(_G.HitboxSize or 15)
    end)

    -- 7. Kill Aura Range
    local KillAuraInputSection = Instance.new("Frame")
    KillAuraInputSection.LayoutOrder = 7
    KillAuraInputSection.BackgroundTransparency = 1
    KillAuraInputSection.Size = UDim2.new(1, 0, 0, 45)
    KillAuraInputSection.Parent = Content
    local KillAuraInputLayout = Instance.new("UIListLayout")
    KillAuraInputLayout.FillDirection = Enum.FillDirection.Horizontal
    KillAuraInputLayout.Padding = UDim.new(0, 10)
    KillAuraInputLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    KillAuraInputLayout.Parent = KillAuraInputSection
    local KillAuraInput, KillAuraContainer = CreateInputBox("KillAuraRange", "40", 320, KillAuraInputSection)
    KillAuraInput.Text = tostring(_G.KillAuraRange)
    KillAuraInput.FocusLost:Connect(function()
        local val = tonumber(KillAuraInput.Text)
        if val then _G.KillAuraRange = val; SaveConfig() end
    end)

    -- 8. ESP Range
    local ESPRangeInputSection = Instance.new("Frame")
    ESPRangeInputSection.LayoutOrder = 8
    ESPRangeInputSection.BackgroundTransparency = 1
    ESPRangeInputSection.Size = UDim2.new(1, 0, 0, 45)
    ESPRangeInputSection.Parent = Content
    local ESPRangeInputLayout = Instance.new("UIListLayout")
    ESPRangeInputLayout.FillDirection = Enum.FillDirection.Horizontal
    ESPRangeInputLayout.Padding = UDim.new(0, 10)
    ESPRangeInputLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ESPRangeInputLayout.Parent = ESPRangeInputSection
    local ESPRangeInput, ESPRangeContainer = CreateInputBox("ESPRange", "1000", 320, ESPRangeInputSection)
    ESPRangeInput.Text = tostring(_G.ESPRange)
    ESPRangeInput.FocusLost:Connect(function()
        local val = tonumber(ESPRangeInput.Text)
        if val then _G.ESPRange = val; SaveConfig() end
    end)

    -- 9. Action Buttons
    local ActionFrame = Instance.new("Frame")
    ActionFrame.LayoutOrder = 9
    ActionFrame.BackgroundTransparency = 1
    ActionFrame.Size = UDim2.new(1, 0, 0, 40)
    ActionFrame.Parent = Content

    local ActionLayout = Instance.new("UIListLayout")
    ActionLayout.FillDirection = Enum.FillDirection.Horizontal
    ActionLayout.Padding = UDim.new(0, 10)
    ActionLayout.Parent = ActionFrame

    local function CreateActionButton(name, width)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.BackgroundColor3 = Theme.Surface
        btn.Size = UDim2.new(0, width, 1, 0)
        btn.Font = Enum.Font.GothamMedium
        btn.Text = name
        btn.TextColor3 = Theme.Text
        btn.TextSize = 12
        btn.AutoButtonColor = false
        btn.Parent = ActionFrame
        ApplyCorner(btn, 8)
        ApplyStroke(btn, Theme.Border, 1)

        -- btn.MouseEnter:Connect(function() ApplyTween(btn, {BackgroundColor3 = Theme.SurfaceHighlight}) end)
        -- btn.MouseLeave:Connect(function() ApplyTween(btn, {BackgroundColor3 = Theme.Surface}) end)
        return btn
    end

    local TpBtn = CreateActionButton("TP (Click)", 75)
    local TpToolBtn = CreateActionButton("TP Tool", 75)
    local IgnoreBtn = CreateActionButton("Ignore", 75)
    local InspectBtn = CreateActionButton("Inspect", 75)

    TpBtn.MouseButton1Click:Connect(function()
        local m = LocalPlayer:GetMouse()
        if m.Hit and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = m.Hit + Vector3.new(0, 5, 0)
        end
    end)
    
    TpToolBtn.MouseButton1Click:Connect(function()
        local tool = Instance.new("Tool")
        tool.Name = "TP Tool"
        tool.RequiresHandle = false
        tool.Activated:Connect(function()
            local m = LocalPlayer:GetMouse()
            if m.Hit and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = m.Hit + Vector3.new(0, 5, 0)
            end
        end)
        tool.Parent = LocalPlayer.Backpack
    end)

    IgnoreBtn.MouseButton1Click:Connect(function()
        if CurrentLockedTarget then
            local targetPlayer = Players:GetPlayerFromCharacter(CurrentLockedTarget) or Players:FindFirstChild(CurrentLockedTarget.Name)
            if targetPlayer then
                _G.IgnoredPlayers[targetPlayer.Name] = true
                _G.IgnoredPlayers[targetPlayer.DisplayName] = true
                CurrentLockedTarget = nil
                _lastTargetChar = nil
            end
        end
    end)

    local InspectBtn = CreateActionButton("Inspect [K]", 75)

    local function RunInspect()
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myPos = myHRP and myHRP.Position or Camera.CFrame.Position

        -- 1. Find Closest Monster/NPC (ignores rocks and ground)
        local nearestMob = nil
        local nearestDist = math.huge

        for _, entry in ipairs(_allKnownNPCs or {}) do
            if entry.root and entry.model then
                local d = (entry.root.Position - myPos).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearestMob = entry
                end
            end
        end

        -- Check Workspace.World for any non-Scene entities
        local worldStages = {}
        pcall(function()
            if workspace:FindFirstChild("World") then
                for _, stg in ipairs(workspace.World:GetChildren()) do
                    local chList = {}
                    for _, ch in ipairs(stg:GetChildren()) do
                        if ch.Name ~= "Scene" and ch.Name ~= "Collide" and not IsPlayerCharacter(ch) then
                            table.insert(chList, string.format("%s [%s] (%d children)", ch.Name, ch.ClassName, #ch:GetChildren()))
                            local r = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChildWhichIsA("BasePart", true)
                            if r then
                                local d = (r.Position - myPos).Magnitude
                                if d < nearestDist then
                                    nearestDist = d
                                    nearestMob = {model = ch, humanoid = ch:FindFirstChildOfClass("Humanoid"), root = r}
                                end
                            end
                        end
                    end
                    table.insert(worldStages, string.format("Stage: %s -> %s", stg.Name, #chList > 0 and table.concat(chList, ", ") or "Only Scene"))
                end
            end
        end)

        -- 2. Combat Remotes
        local remList = {}
        pcall(function()
            for _, rem in ipairs(GetCachedCombatRemotes()) do
                table.insert(remList, string.format("%s [%s]", rem.Name, rem.ClassName))
            end
        end)

        -- Build Report
        local lines = {}
        table.insert(lines, "=== IRON SOUL INSPECTOR REPORT ===")
        if nearestMob and nearestMob.model then
            local hum = nearestMob.humanoid
            local hp = hum and string.format("%.0f/%.0f", hum.Health, hum.MaxHealth) or "No Humanoid"
            table.insert(lines, string.format("Nearest Mob: %s (Dist: %.1f studs)", nearestMob.model.Name, nearestDist))
            table.insert(lines, string.format("Full Path: %s", nearestMob.model:GetFullName()))
            table.insert(lines, string.format("Health: %s", hp))
        else
            table.insert(lines, "Nearest Mob: None detected within range!")
        end

        table.insert(lines, "")
        table.insert(lines, "--- WORLD STAGES & ENEMY FOLDERS ---")
        if #worldStages > 0 then
            for _, s in ipairs(worldStages) do table.insert(lines, s) end
        else
            table.insert(lines, "No Workspace.World folder found")
        end

        table.insert(lines, "")
        table.insert(lines, string.format("--- DETECTED MOBS (%d TOTAL) ---", #(_allKnownNPCs or {})))
        for i, entry in ipairs(_allKnownNPCs or {}) do
            if i <= 8 and entry.model then
                table.insert(lines, string.format("  #%d: %s at %.1f studs", i, entry.model.Name, (entry.root.Position - myPos).Magnitude))
            end
        end

        -- 3. Player Combat Info
        local playerInfo = {}
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, ch in ipairs(char:GetChildren()) do
                    if ch:IsA("Tool") or ch:IsA("Model") or (ch:IsA("BasePart") and ch.Name:lower():find("weapon")) then
                        table.insert(playerInfo, string.format("  Weapon: %s [%s]", ch.Name, ch.ClassName))
                    elseif ch:IsA("LocalScript") or ch:IsA("Script") then
                        table.insert(playerInfo, string.format("  Script: %s [%s]", ch.Name, ch.ClassName))
                    end
                end
            end
            if LocalPlayer.Backpack then
                for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    table.insert(playerInfo, string.format("  Backpack Tool: %s", t.Name))
                end
            end
        end)

        -- 4. All ReplicatedStorage Remotes (First 15)
        local allRemotes = {}
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local count = 0
            for _, r in ipairs(rs:GetDescendants()) do
                if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and count < 15 then
                    count = count + 1
                    table.insert(allRemotes, string.format("  %s [%s] in %s", r.Name, r.ClassName, r.Parent and r.Parent.Name or "RS"))
                end
            end
        end)

        table.insert(lines, "")
        table.insert(lines, "--- PLAYER COMBAT INFO ---")
        if #playerInfo > 0 then
            for _, p in ipairs(playerInfo) do table.insert(lines, p) end
        else
            table.insert(lines, "  No weapons or tools found in character/backpack")
        end

        table.insert(lines, "")
        table.insert(lines, "--- REPLICATEDSTORAGE REMOTES (SAMPLE) ---")
        if #allRemotes > 0 then
            for _, r in ipairs(allRemotes) do table.insert(lines, r) end
        else
            table.insert(lines, "  None detected")
        end

        table.insert(lines, "")
        table.insert(lines, "--- COMBAT REMOTES ---")
        if #remList > 0 then
            for _, r in ipairs(remList) do table.insert(lines, "  - " .. r) end
        else
            table.insert(lines, "  None detected")
        end

        local dump = table.concat(lines, "\n")
        print(dump)
        if setclipboard then
            setclipboard(dump)
            InspectBtn.Text = "Copied!"
            task.delay(1.5, function() InspectBtn.Text = "Inspect [K]" end)
        end
    end

    InspectBtn.MouseButton1Click:Connect(RunInspect)

    -- K Key Shortcut to Inspect
    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.K then
            if IsTypingInTextBox() then return end
            RunInspect()
        end
    end)

    -- H Key Shortcut for Hitbox
    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.H then
            if IsTypingInTextBox() then return end
            _G.HitboxExpander = not _G.HitboxExpander
            UpdateHitbox(_G.HitboxExpander)
            if _G.HitboxExpander then
                UpdatePlayerHitboxes()
            else
                RestorePlayerHitboxes()
            end
            SaveConfig()
        end
    end)

    -- 10. Players Online List
    local PlayerSection = Instance.new("Frame")
    PlayerSection.LayoutOrder = 10
    PlayerSection.BackgroundTransparency = 1
    PlayerSection.Size = UDim2.new(1, 0, 0, 300)
    PlayerSection.Parent = Content

    local PlayerHeader = Instance.new("TextLabel")
    PlayerHeader.BackgroundTransparency = 1
    PlayerHeader.Size = UDim2.new(1, 0, 0, 20)
    PlayerHeader.Font = Enum.Font.GothamBold
    PlayerHeader.Text = "Players Online"
    PlayerHeader.TextColor3 = Theme.Text
    PlayerHeader.TextSize = 14
    PlayerHeader.TextXAlignment = Enum.TextXAlignment.Left
    PlayerHeader.Parent = PlayerSection

    local PlayerCount = Instance.new("TextLabel")
    PlayerCount.BackgroundTransparency = 1
    PlayerCount.Position = UDim2.new(1, -50, 0, 0)
    PlayerCount.Size = UDim2.new(0, 50, 0, 20)
    PlayerCount.Font = Enum.Font.GothamMedium
    PlayerCount.Text = "0/0"
    PlayerCount.TextColor3 = Theme.TextMuted
    PlayerCount.TextSize = 12
    PlayerCount.TextXAlignment = Enum.TextXAlignment.Right
    PlayerCount.Parent = PlayerSection

    local PlayerScroll = Instance.new("ScrollingFrame")
    PlayerScroll.BackgroundColor3 = Theme.Surface
    PlayerScroll.Position = UDim2.new(0, 0, 0, 30)
    PlayerScroll.Size = UDim2.new(1, 0, 1, -30)
    PlayerScroll.ScrollBarThickness = 2
    PlayerScroll.ScrollBarImageColor3 = Theme.Accent
    PlayerScroll.Parent = PlayerSection
    ApplyCorner(PlayerScroll, 8)
    ApplyStroke(PlayerScroll, Theme.Border, 1)

    local PlayerListLayout = Instance.new("UIListLayout")
    PlayerListLayout.Padding = UDim.new(0, 5)
    PlayerListLayout.SortOrder = Enum.SortOrder.Name
    PlayerListLayout.Parent = PlayerScroll

    PlayerListUI.Scroll = PlayerScroll
    PlayerListUI.Count = PlayerCount

    local function RefreshPlayers()
        for _, c in ipairs(PlayerScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local count = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                count = count + 1
                local item = Instance.new("Frame")
                item.Name = p.Name
                item.BackgroundColor3 = Theme.Background
                item.Size = UDim2.new(1, 0, 0, 30)
                item.Parent = PlayerScroll
                ApplyCorner(item, 4)

                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Position = UDim2.new(0, 10, 0, 0)
                lbl.Size = UDim2.new(1, -70, 1, 0)
                lbl.Font = Enum.Font.GothamMedium
                lbl.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                lbl.TextColor3 = Theme.Text
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = item

                local ignBtn = Instance.new("TextButton")
                ignBtn.BackgroundColor3 = Theme.Surface
                ignBtn.Position = UDim2.new(1, -60, 0, 5)
                ignBtn.Size = UDim2.new(0, 50, 0, 20)
                ignBtn.Font = Enum.Font.GothamBold
                ignBtn.TextColor3 = Theme.Danger
                ignBtn.TextSize = 10
                ignBtn.Parent = item
                ApplyCorner(ignBtn, 4)

                local isIgnored = _G.IgnoredPlayers[p.Name] or _G.IgnoredPlayers[p.DisplayName]
                ignBtn.Text = isIgnored and "Unignore" or "Ignore"
                if isIgnored then
                    ignBtn.BackgroundColor3 = Theme.Danger
                    ignBtn.TextColor3 = Theme.Text
                end

                ignBtn.MouseButton1Click:Connect(function()
                    if _G.IgnoredPlayers[p.Name] or _G.IgnoredPlayers[p.DisplayName] then
                        _G.IgnoredPlayers[p.Name] = nil
                        _G.IgnoredPlayers[p.DisplayName] = nil
                        ignBtn.Text = "Ignore"
                        ignBtn.BackgroundColor3 = Theme.Surface
                        ignBtn.TextColor3 = Theme.Danger
                    else
                        _G.IgnoredPlayers[p.Name] = true
                        _G.IgnoredPlayers[p.DisplayName] = true
                        ignBtn.Text = "Unignore"
                        ignBtn.BackgroundColor3 = Theme.Danger
                        ignBtn.TextColor3 = Theme.Text
                    end
                end)
            end
        end
        PlayerCount.Text = tostring(count) .. "/" .. tostring(#Players:GetPlayers())
        PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, count * 35)
    end

    RefreshPlayers()
    Players.PlayerAdded:Connect(RefreshPlayers)
    Players.PlayerRemoving:Connect(RefreshPlayers)

    -- Input Services
    local draggingUI = nil
    local dragInput = nil
    local dragStartUI = nil
    local startPosUI = nil

    local function update(input)
        local delta = input.Position - dragStartUI
        local rawX = startPosUI.X.Offset + delta.X
        local rawY = startPosUI.Y.Offset + delta.Y

        -- Clamp position so Main window stays inside Viewport bounds
        local vp = Camera.ViewportSize
        local scale = (MainScale and MainScale.Scale) or 1.0
        local halfW = (Main.Size.X.Offset * scale) / 2
        local halfH = (Main.Size.Y.Offset * scale) / 2

        local minX = -vp.X / 2 + halfW + 5
        local maxX = vp.X / 2 - halfW - 5
        local minY = -vp.Y / 2 + halfH + 5
        local maxY = vp.Y / 2 - halfH - 5

        local clampedX = math.clamp(rawX, minX, maxX)
        local clampedY = math.clamp(rawY, minY, maxY)

        Main.Position = UDim2.new(0.5, clampedX, 0.5, clampedY)
    end

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingUI = true
            dragStartUI = input.Position
            startPosUI = Main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingUI = false
                end
            end)
        end
    end)
    HeaderFix.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingUI = true
            dragStartUI = input.Position
            startPosUI = Main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingUI = false
                end
            end)
        end
    end)

    -- NOTE: Minimize/expand is handled by ToggleMinimize() in the header section (line ~474).
    -- No separate OpenBtn needed.

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if draggingUI then 
                update(input) 
            end
            if draggingSlider then
                local pos = input.Position.X
                local tr = draggingSlider.Track
                local pct = math.clamp((pos - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1)
                draggingSlider.Update(draggingSlider.Min + pct * (draggingSlider.Max - draggingSlider.Min))
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = nil
        end
    end)

    -- Session Timer
    task.spawn(function()
        local startTime = tick()
        while task.wait(1) do
            local elapsed = tick() - startTime
            local h = math.floor(elapsed / 3600)
            local m = math.floor((elapsed % 3600) / 60)
            local s = math.floor(elapsed % 60)
            SessionLabel.Text = string.format("%02d:%02d:%02d", h, m, s)
        end
    end)
end

-- [[ INFINITE JUMP HANDLER (HOLDABLE) ]] --
local _spaceHeld = false
local _lastHoldJump = 0
local HOLD_JUMP_INTERVAL = 0.18

local function TriggerInfiniteJump()
    if not _G.InfJump then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp then
        pcall(function()
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
        pcall(function()
            local jumpPower = (hum.UseJumpPower and hum.JumpPower > 0 and hum.JumpPower) or (hum.JumpHeight > 0 and math.sqrt(2 * workspace.Gravity * hum.JumpHeight)) or 50
            local curVel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(curVel.X, math.max(jumpPower, 50), curVel.Z)
            pcall(function() hrp.Velocity = Vector3.new(curVel.X, math.max(jumpPower, 50), curVel.Z) end)
        end)
    end
end

UserInputService.JumpRequest:Connect(TriggerInfiniteJump)

UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.Space then
        if IsTypingInTextBox() then return end
        _spaceHeld = true
        TriggerInfiniteJump()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        _spaceHeld = false
    end
end)

-- Continuous Ascension while Space is held
RunService.Heartbeat:Connect(function()
    if _G.MovementLoopID ~= CurrentLoopID then return end
    if not _G.InfJump then return end
    if _spaceHeld or (UserInputService:IsKeyDown(Enum.KeyCode.Space) and not IsTypingInTextBox()) then
        local now = tick()
        if (now - _lastHoldJump) >= HOLD_JUMP_INTERVAL then
            _lastHoldJump = now
            TriggerInfiniteJump()
        end
    end
end)

-- [[ AIMBOT & FOV RENDER LOOP ]] --
pcall(function() RunService:UnbindFromRenderStep("ZHub_CameraTrack") end)
RunService:BindToRenderStep("ZHub_CameraTrack", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if _G.MovementLoopID ~= CurrentLoopID then return end
    UpdateFOVCircle()
    if _G.AutoAim then RunAutoAim(dt) end
    if _G.AutoShoot then RunAutoShoot() end
end)

-- [[ ZERO-ALLOCATION NOCLIP PART CACHE (PREVENTS GC FRAME DROPS) ]] --
local _noclipPartsList = {}
local _noclipCharTracked = nil
local _noclipAddedConn, _noclipRemovedConn

local function SetupNoclipCache(char)
_noclipPartsList = {}
if not char then return end
for _, v in ipairs(char:GetDescendants()) do
    if v:IsA("BasePart") then
    table.insert(_noclipPartsList, v)
    end
end
if _noclipAddedConn then _noclipAddedConn:Disconnect() _noclipAddedConn = nil end
if _noclipRemovedConn then _noclipRemovedConn:Disconnect() _noclipRemovedConn = nil end

_noclipAddedConn = char.DescendantAdded:Connect(function(v)
    if v:IsA("BasePart") then
    table.insert(_noclipPartsList, v)
    end
end)
_noclipRemovedConn = char.DescendantRemoving:Connect(function(v)
    if v:IsA("BasePart") then
    for i = #_noclipPartsList, 1, -1 do
        if _noclipPartsList[i] == v then
            table.remove(_noclipPartsList, i)
            break
        end
    end
    end
end)
end


-- [[ CHARACTER RESPAWN CLEANUP (Preserves Roblox Native Touch Controls on Spawn) ]] --
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if _G.MovementLoopID ~= CurrentLoopID then return end
    task.wait(0.2)
    local hum = newChar:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        if _G.SpeedEnabled then
            hum.WalkSpeed = _G.MovementSpeed
        end
    end
    if _G.Noclip then
        _noclipCharTracked = newChar
        SetupNoclipCache(newChar)
    end
    if _G.ReachEnabled then
        CreateReachPart()
    end
end)

-- [[ MAIN LOOP ]] --
RunService.Stepped:Connect(function()
if _G.MovementLoopID ~= CurrentLoopID then return end

if _G.FullBright then
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end

if _G.TimeScale and _G.TimeScale ~= 1 then
    pcall(function() workspace:SetAttribute("TimeScale", _G.TimeScale) end)
end

-- Kill Aura tick (continuous execution)
if _G.KillAura then
    RunKillAura()
end

-- ESP (throttled: refresh every 10 frames (~6x/sec) for wall occlusion checks)
if _G.EspEnabled then
    if not _G._espTick then _G._espTick = 0 end
    _G._espTick = _G._espTick + 1
    if _G._espTick >= 10 then
    _G._espTick = 0
    RefreshAllESP()
    end
end

-- Hitbox Expander tick (players only, throttled every 6 frames)
if _G.HitboxExpander then
    if not _G._hitboxTick then _G._hitboxTick = 0 end
    _G._hitboxTick = _G._hitboxTick + 1
    if _G._hitboxTick >= 6 then
        _G._hitboxTick = 0
        UpdatePlayerHitboxes()
    end
end

-- Skip character logic entirely if all character-modifying features are disabled
if not (_G.Noclip or _G.SpeedEnabled or _G.Fly or _G.ReachEnabled) then return end

local char = LocalPlayer.Character
if char and char:FindFirstChild("Humanoid") then
    -- Noclip (Zero-Allocation: zero memory allocation per frame -> zero GC frame drops)
    if _G.Noclip then
    if _noclipCharTracked ~= char then
        _noclipCharTracked = char
        SetupNoclipCache(char)
    end
    for i = 1, #_noclipPartsList do
        local p = _noclipPartsList[i]
        if p and p.Parent then
            p.CanCollide = false
        end
    end
    else
    if _noclipCharTracked then
        _noclipCharTracked = nil
        _noclipPartsList = {}
        if _noclipAddedConn then _noclipAddedConn:Disconnect() _noclipAddedConn = nil end
        if _noclipRemovedConn then _noclipRemovedConn:Disconnect() _noclipRemovedConn = nil end
    end
    end



    -- Walk Speed (Dual-Layer: WalkSpeed override + Velocity assist for anti-cheat bypass)
    if _G.SpeedEnabled and not _G.Fly then
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = _G.MovementSpeed
            if hrp and hum.MoveDirection.Magnitude > 0 then
                local moveDir = hum.MoveDirection
                local speedVal = _G.MovementSpeed
                local curY = hrp.AssemblyLinearVelocity.Y
                hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * speedVal, curY, moveDir.Z * speedVal)
            end
        end
    end

    -- Fly (Full 3D Camera-Oriented Flying + Hover Physics + LinearVelocity)
    if _G.Fly then
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum.PlatformStand = true

            local flySpeed = _G.SpeedEnabled and _G.MovementSpeed or 50
            local dir = GetFlyDirection()

            if dir.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = dir * flySpeed
            else
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end

            -- Backup BodyVelocity & BodyGyro for older engines
            local bv = hrp:FindFirstChild("ZHub_FlyVelocity")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "ZHub_FlyVelocity"
                bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                bv.Parent = hrp
            end
            bv.Velocity = dir.Magnitude > 0 and (dir * flySpeed) or Vector3.new(0, 0, 0)

            local bg = hrp:FindFirstChild("ZHub_FlyGyro")
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.Name = "ZHub_FlyGyro"
                bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                bg.D = 100
                bg.P = 10000
                bg.Parent = hrp
            end
            bg.CFrame = Camera.CFrame
        end
    end

    -- Reach - Update tool hitboxes when equipped
    if _G.ReachEnabled then
    ExpandToolHitbox()
    UpdateReachSize()
    end
end
end)

-- Initial animation
Main.BackgroundTransparency = 1
Main.Size = UDim2.new(0, 360, 0, 0)
CreateTween(Main, {BackgroundTransparency = 0, Size = UDim2.new(0, 360, 0, 480)}, 0.4, Enum.EasingStyle.Back):Play()

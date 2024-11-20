--[[

controls
- P (close/hide/open)

info;
this probably won't become configurable because I don't care enough.
don't ask for updates, won't happen

it's open-sourced, you can figure it out yourself if you can scape through my code ;)

won't work in specific games where the developer actually put SOME effort in.
uhm, lastly upvote the reddit post.

showcase - https://youtu.be/i6aQvS8IUok?si=4Af912IvZ_WIBRS5
credit - @https://github.com/elitefps find more of my work.
--]]

-- // roblox
local localPlayer = Players.LocalPlayer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- // radar
local rVis = true
local rRadius = 50
local mRadius = math.min(workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y) / 6
local screenSize = workspace.CurrentCamera.ViewportSize

local rPos = Vector2.new(screenSize.X - mRadius - 20, mRadius + 20)
local isDragging = false
local dragOffset = Vector2.new(0, 0)


local cfg = {
    radarColor = Color3.new(0.3, 0.3, 0.3),
    strokeColor = Color3.new(0.5, 0.5, 0.5),
    localDotColor = Color3.new(1, 1, 1),
    dotDefaultColor = Color3.new(0, 1, 0),
    gradientMax = Color3.new(1, 0, 0),
    gradientMin = Color3.new(0, 1, 0),
}

-- // elements
local radarCircle = Drawing.new("Circle")
radarCircle.Position = rPos
radarCircle.Radius = mRadius
radarCircle.Color = cfg.radarColor
radarCircle.Thickness = 3
radarCircle.Transparency = 0.8
radarCircle.Filled = true
radarCircle.Visible = rVis

local radarStroke = Drawing.new("Circle")
radarStroke.Position = rPos
radarStroke.Radius = mRadius + 4
radarStroke.Color = cfg.strokeColor
radarStroke.Thickness = 0.5
radarStroke.Transparency = 0.8
radarStroke.Filled = false
radarStroke.Visible = rVis

local localPlayerDot = Drawing.new("Circle")
localPlayerDot.Color = cfg.localDotColor
localPlayerDot.Transparency = 1
localPlayerDot.Filled = true
localPlayerDot.Thickness = 1
localPlayerDot.Radius = 6
localPlayerDot.Visible = rVis

local localPlayerName = Drawing.new("Text")
localPlayerName.Text = localPlayer.Name
localPlayerName.Size = 15
localPlayerName.Center = true
localPlayerName.Outline = true
localPlayerName.Color = Color3.new(1, 1, 1)
localPlayerName.Font = Drawing.Fonts.UI
localPlayerName.Visible = rVis

-- // cache
local playerDots = {}

-- // helper functions
local function createDot()
    local dot = Drawing.new("Circle")
    dot.Color = cfg.dotDefaultColor
    dot.Transparency = 0.8
    dot.Filled = true
    dot.Thickness = 1
    dot.Radius = 4
    return dot
end

local function removeDot(player)
    if playerDots[player] then
        playerDots[player]:Remove()
        playerDots[player] = nil
    end
end

-- // update dot
local function updateDot(player, localPosition)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local root = character.HumanoidRootPart
    local relativePosition = (root.Position - localPosition) * Vector3.new(1, 0, 1) -- Ignore Y-axis
    local distance = relativePosition.Magnitude

    if distance <= rRadius then
        local scaledPosition = relativePosition.Unit * math.min((distance / rRadius) * mRadius, mRadius)
        local screenPosition = rPos + Vector2.new(scaledPosition.X, -scaledPosition.Z)

        local dot = playerDots[player] or createDot()
        playerDots[player] = dot
        dot.Position = screenPosition
        dot.Color = cfg.gradientMax:Lerp(cfg.gradientMin, distance / rRadius)
        dot.Visible = rVis
    else
        removeDot(player)
    end
end

local function updateRadar()
    if not rVis then return end
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local localPosition = localPlayer.Character.HumanoidRootPart.Position
   
    localPlayerDot.Position = rPos
    localPlayerName.Position = localPlayerDot.Position + Vector2.new(0, -15)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            updateDot(player, localPosition)
        end
    end

    for player, _ in pairs(playerDots) do
        if not Players:FindFirstChild(player.Name) then
            removeDot(player)
        end
    end
end

-- // isDragging?
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePosition = UIS:GetMouseLocation()
        if (mousePosition - rPos).Magnitude <= mRadius then
            isDragging = true
            dragOffset = rPos - mousePosition
        end
    end
end)

UIS.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        rPos = UIS:GetMouseLocation() + dragOffset
        rPos = Vector2.new(
            math.clamp(rPos.X, mRadius + 10, screenSize.X - mRadius - 10),
            math.clamp(rPos.Y, mRadius + 10, screenSize.Y - mRadius - 10)
        )
        radarCircle.Position = rPos
        radarStroke.Position = rPos
        localPlayerDot.Position = rPos
        localPlayerName.Position = rPos + Vector2.new(0, -15)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

-- // input (you can change your activate/toggle key here)
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.K then
        rVis = not rVis
        radarCircle.Visible = rVis
        radarStroke.Visible = rVis
        localPlayerDot.Visible = rVis
        localPlayerName.Visible = rVis
        for _, dot in pairs(playerDots) do
            dot.Visible = rVis
        end
    elseif input.KeyCode == Enum.KeyCode.R then
        rPos = Vector2.new(screenSize.X - mRadius - 20, mRadius + 20)
    end
end)


RunService.RenderStepped:Connect(updateRadar)

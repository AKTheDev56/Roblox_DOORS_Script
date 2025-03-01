local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Predefined colors
local colourTable = {
    Yellow = Color3.fromRGB(241, 196, 15),
    Green = Color3.fromRGB(0, 255, 0)
}
local colourChosen = colourTable.Green
local doorHighlightColor = colourTable.Yellow

-- Highlight targets
local highlightParts = { Key = true, Inset = true, Ring = true, Tag = true }
local highlightModels = { LeverForGate = true, LiveHintBook = true, FigureRig = true }

-- Caches for performance
local highlightedCache = {}
local doorCache = {}

local function getPlayerPrimaryPart()
    local character = player.Character
    return character and character.PrimaryPart
end

local function round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power) / power
end

local function addHighlight(instance, color)
    if not highlightedCache[instance] then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = instance
        highlight.Parent = instance
        highlight.FillColor = color
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.5
        highlightedCache[instance] = highlight
    end
end

local function cleanupHighlights()
    for instance, highlight in pairs(highlightedCache) do
        if not instance:IsDescendantOf(Workspace) or not instance.Parent then
            highlight:Destroy()
            highlightedCache[instance] = nil
        end
    end
end

local function updateDistanceLabel(door)
    local playerPrimaryPart = getPlayerPrimaryPart()
    if not playerPrimaryPart or not door then return end

    local bb = door:FindFirstChild("BillBoard")
    local distLabel = bb and bb:FindFirstChild("Dist")
    if distLabel then
        distLabel.Text = round((playerPrimaryPart.Position - door.Position).magnitude, 1) .. " Studs"
    end
end

local function processDoor(instance)
    if doorCache[instance] then return end  -- Prevent duplicate processing

    local door = instance:FindFirstChild("Door")
    if door and door:FindFirstChild("Door") then
        local doorPart = door.Door
        addHighlight(doorPart, doorHighlightColor)
        doorCache[doorPart] = true

        -- Add distance label if not already present
        if not doorPart:FindFirstChild("BillBoard") then
            local bb = Instance.new("BillboardGui")
            bb.Adornee = doorPart
            bb.ExtentsOffset = Vector3.new(0, 1, 0)
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 6, 0, 6)
            bb.Name = "BillBoard"
            bb.Parent = doorPart

            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.ZIndex = 10
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.Position = UDim2.new(0, 0, 0, -15)
            distanceLabel.Size = UDim2.new(1, 0, 10, 0)
            distanceLabel.Font = Enum.Font.ArialBold
            distanceLabel.TextStrokeTransparency = 0.5
            distanceLabel.TextColor3 = doorHighlightColor
            distanceLabel.Name = "Dist"
            distanceLabel.Text = "..."  -- Temporary placeholder
            distanceLabel.Parent = bb
        end

        -- Immediately update distance label
        updateDistanceLabel(doorPart)
    end
end

local function processObject(instance)
    if instance:IsA("MeshPart") and highlightParts[instance.Name] then
        addHighlight(instance, colourChosen)
    elseif instance:IsA("Model") and highlightModels[instance.Name] then
        addHighlight(instance, colourChosen)
    elseif instance:IsA("Model") then
        processDoor(instance)
    end
end

local function updateAllDistanceLabels()
    local playerPrimaryPart = getPlayerPrimaryPart()
    if not playerPrimaryPart then return end

    for door, _ in pairs(doorCache) do
        updateDistanceLabel(door)
    end
end

local function setupWorkspaceListeners()
    Workspace.DescendantAdded:Connect(processObject)

    Workspace.DescendantRemoving:Connect(function(instance)
        if highlightedCache[instance] then
            highlightedCache[instance]:Destroy()
            highlightedCache[instance] = nil
        end

        if doorCache[instance] then
            doorCache[instance] = nil
        end
    end)
end

RunService.Heartbeat:Connect(function()
    cleanupHighlights()
    updateAllDistanceLabels()
end)

-- Initialize
setupWorkspaceListeners()
for _, instance in ipairs(Workspace:GetDescendants()) do
    processObject(instance)
end

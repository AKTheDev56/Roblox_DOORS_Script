local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

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

-- Cache for performance
local highlightedCache = {}

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

local function processObject(instance)
    -- Highlight mesh parts
    if instance:IsA("MeshPart") and highlightParts[instance.Name] then
        addHighlight(instance, colourChosen)
    -- Highlight specific models
    elseif instance:IsA("Model") and highlightModels[instance.Name] then
        addHighlight(instance, colourChosen)
    -- Highlight doors and add distance labels
    elseif instance:IsA("Model") and instance:FindFirstChild("Door") and instance.Door:FindFirstChild("Door") then
        local door = instance.Door.Door
        addHighlight(door, doorHighlightColor)

        -- Add distance label
        if not door:FindFirstChild("BillBoard") then
            local bb = Instance.new("BillboardGui", door)
            bb.Adornee = door
            bb.ExtentsOffset = Vector3.new(0, 1, 0)
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 6, 0, 6)
            bb.Name = "BillBoard"

            local distanceLabel = Instance.new("TextLabel", bb)
            distanceLabel.ZIndex = 10
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.Position = UDim2.new(0, 0, 0, -15)
            distanceLabel.Size = UDim2.new(1, 0, 10, 0)
            distanceLabel.Font = Enum.Font.ArialBold
            distanceLabel.TextStrokeTransparency = 0.5
            distanceLabel.TextColor3 = doorHighlightColor
            distanceLabel.Name = "Dist"
        end
    end
end

local function updateDistanceLabels()
    local playerPrimaryPart = getPlayerPrimaryPart()
    if not playerPrimaryPart then return end

    for instance, highlight in pairs(highlightedCache) do
        if instance:IsA("Model") and instance:FindFirstChild("Door") and instance.Door:FindFirstChild("Door") then
            local door = instance.Door.Door
            local bb = door:FindFirstChild("BillBoard")
            local distLabel = bb and bb:FindFirstChild("Dist")
            if distLabel then
                distLabel.Text = round((playerPrimaryPart.Position - door.Position).magnitude, 1) .. " Studs"
            end
        end
    end
end

local function setupWorkspaceListeners()
    Workspace.DescendantAdded:Connect(function(instance)
        processObject(instance)
    end)

    Workspace.DescendantRemoving:Connect(function(instance)
        if highlightedCache[instance] then
            highlightedCache[instance]:Destroy()
            highlightedCache[instance] = nil
        end
    end)
end

RunService.Heartbeat:Connect(function()
    cleanupHighlights() -- Clean up invalid highlights
    updateDistanceLabels() -- Update distance labels for doors
end)

-- Initialize
setupWorkspaceListeners()
for _, instance in ipairs(Workspace:GetDescendants()) do
    processObject(instance) -- Process existing objects
end

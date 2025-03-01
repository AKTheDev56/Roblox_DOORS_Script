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
local figureRigHighlighted = false -- To track if FigureRig has been highlighted

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
        if not instance:IsDescendantOf(Workspace.CurrentRooms) or not instance.Parent then
            highlight:Destroy()
            highlightedCache[instance] = nil
        end
    end
end

local function processWorkspace()
    local playerPrimaryPart = getPlayerPrimaryPart()
    if not playerPrimaryPart then return end

    -- Search for doors in CurrentRooms
    for _, child in ipairs(Workspace.CurrentRooms:GetDescendants()) do
        if child:IsA("Model") and child:FindFirstChild("Door") and child.Door:FindFirstChild("Door") then
            local door = child.Door.Door
            addHighlight(door, doorHighlightColor)

            -- Add or update distance label
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

            local bb = door:FindFirstChild("BillBoard")
            local distLabel = bb and bb:FindFirstChild("Dist")
            if distLabel then
                distLabel.Text = round((playerPrimaryPart.Position - door.Position).magnitude, 1) .. " Studs"
            end
        end

        -- Highlight mesh parts and models in CurrentRooms
        if child:IsA("MeshPart") then
            if highlightParts[child.Name] and not highlightedCache[child] then
                addHighlight(child, colourChosen)
            end
        elseif child:IsA("Model") then
            if highlightModels[child.Name] and not highlightedCache[child] then
                addHighlight(child, colourChosen)
            end
        end
    end

    -- Check for FigureRig in workspace.CurrentRooms.50, and wait if it doesn't exist
    if not figureRigHighlighted then
        local figureRigFolder = Workspace.CurrentRooms:FindFirstChild("50")
        if figureRigFolder then
            local figureRig = figureRigFolder:FindFirstChild("FigureRig")
            if figureRig then
                addHighlight(figureRig, colourChosen)
                figureRigHighlighted = true -- Ensure we don't highlight again
            end
        else
            -- Wait for the folder to exist
            Workspace.CurrentRooms.ChildAdded:Wait()
        end
    end
end

RunService.Heartbeat:Connect(function()
    cleanupHighlights() -- Clean up invalid highlights
    processWorkspace() -- Process all doors, mesh parts, and models dynamically in CurrentRooms
end)

processWorkspace()

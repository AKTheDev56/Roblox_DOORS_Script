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
local highlightModels = { 
    KeyObtain = true, 
    LeverForGate = true, 
    LiveHintBook = true, 
    FigureRig = true, 
    LiveBreakerPolePickup = true,
    Snare = true -- Added Snare
}

-- Cache to prevent duplicate highlights
local highlightedCache = {}
local highlightQueue = {}

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

local function processDoors()
    local playerPrimaryPart = getPlayerPrimaryPart()
    if not playerPrimaryPart then return end

    for _, child in ipairs(Workspace.CurrentRooms:GetDescendants()) do
        if child:IsA("Model") and child:FindFirstChild("Door") and child.Door:FindFirstChild("Door") then
            local door = child.Door.Door
            if not highlightedCache[door] then
                addHighlight(door, doorHighlightColor)
            end

            -- Ensure Billboard GUI exists
            local bb = door:FindFirstChild("BillBoard")
            if not bb then
                bb = Instance.new("BillboardGui", door)
                bb.Adornee = door
                bb.ExtentsOffset = Vector3.new(0, 1, 0)
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 6, 0, 6)
                bb.Name = "BillBoard"
            end

            local distLabel = bb:FindFirstChild("Dist")
            if not distLabel then
                distLabel = Instance.new("TextLabel", bb)
                distLabel.ZIndex = 10
                distLabel.BackgroundTransparency = 1
                distLabel.Position = UDim2.new(0, 0, 0, -15)
                distLabel.Size = UDim2.new(1, 0, 10, 0)
                distLabel.Font = Enum.Font.ArialBold
                distLabel.TextStrokeTransparency = 0.5
                distLabel.TextColor3 = doorHighlightColor
                distLabel.Name = "Dist"
            end

            -- Update distance
            distLabel.Text = round((playerPrimaryPart.Position - door.Position).magnitude, 1) .. " Studs"
        end
    end
end

local function processExistingObjects()
    for _, child in ipairs(Workspace.CurrentRooms:GetDescendants()) do
        if child:IsA("Model") and highlightModels[child.Name] then
            addHighlight(child, colourChosen)
        end
    end
end

local function trackNewInstances()
    Workspace.CurrentRooms.ChildAdded:Connect(function(newChild)
        task.wait(0.2) -- Slight delay to ensure it's fully parented

        for _, descendant in ipairs(newChild:GetDescendants()) do
            if descendant:IsA("Model") and highlightModels[descendant.Name] then
                addHighlight(descendant, colourChosen)
            elseif descendant:IsA("Model") and descendant:FindFirstChild("Door") and descendant.Door:FindFirstChild("Door") then
                addHighlight(descendant.Door.Door, doorHighlightColor)
            end
        end
    end)
end

local function trackFigureRig()
    task.spawn(function()
        while true do
            local figureRigContainer = Workspace.CurrentRooms:FindFirstChild("50")
            if figureRigContainer then
                local figureRig = figureRigContainer:FindFirstChild("FigureRig")
                if figureRig and not highlightedCache[figureRig] then
                    addHighlight(figureRig, colourChosen)
                    break -- Stop checking once highlighted
                end
            end
            task.wait(1) -- Check every second to reduce lag
        end
    end)
end

-- Ensures objects that fail to highlight are retried
local function retryFailedHighlights()
    for instance, _ in pairs(highlightQueue) do
        if instance and instance.Parent then
            addHighlight(instance, colourChosen)
            highlightQueue[instance] = nil -- Remove from queue once successful
        end
    end
end

local function setupWorkspaceListeners()
    -- Check for specific models (RushMoving, AmbushMoving, Eyes) in Workspace
    Workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            if child.Name == "RushMoving" then
                StarterGui:SetCore("SendNotification", { Title = "RUSH", Text = "HIDE", Duration = 5 })
            elseif child.Name == "AmbushMoving" then
                StarterGui:SetCore("SendNotification", { Title = "AMBUSH", Text = "HIDE", Duration = 5 })
            elseif child.Name == "Eyes" then
                StarterGui:SetCore("SendNotification", { Title = "EYES", Text = "LOOK AWAY", Duration = 5 })
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    retryFailedHighlights() -- Retries failed highlights
    processDoors()
    processExistingObjects()
end)

setupWorkspaceListeners()
trackNewInstances()
trackFigureRig()
processDoors()
processExistingObjects()

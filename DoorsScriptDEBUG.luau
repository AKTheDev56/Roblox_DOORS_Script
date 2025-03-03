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

-- Cache to prevent duplicate highlights
local highlightedCache = {}
local highlightQueue = {} -- Queue for objects that failed to highlight initially

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
        return true -- Successfully highlighted
    end
    return false -- Already highlighted
end

local function cleanupHighlights()
    for instance, highlight in pairs(highlightedCache) do
        if not instance.Parent then
            highlight:Destroy()
            highlightedCache[instance] = nil
        end
    end
end

local function processDoors()
    local playerPrimaryPart = getPlayerPrimaryPart()
    if not playerPrimaryPart then return end

    for _, child in ipairs(Workspace.CurrentRooms:GetDescendants()) do
        if child:IsA("Model") and child:FindFirstChild("Door") and child.Door:FindFirstChild("Door") then
            local door = child.Door.Door
            if addHighlight(door, doorHighlightColor) then
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
            end

            -- Update distance label
            local bb = door:FindFirstChild("BillBoard")
            if bb then
                local distLabel = bb:FindFirstChild("Dist")
                if distLabel then
                    distLabel.Text = round((playerPrimaryPart.Position - door.Position).magnitude, 1) .. " Studs"
                end
            end
        end
    end
end

local function processExistingObjects()
    for _, child in ipairs(Workspace.CurrentRooms:GetDescendants()) do
        if (child:IsA("MeshPart") and highlightParts[child.Name]) or 
           (child:IsA("Model") and highlightModels[child.Name]) then
            if not addHighlight(child, colourChosen) then
                table.insert(highlightQueue, {instance = child, color = colourChosen})
            end
        end
    end
end

local function trackNewInstances()
    Workspace.CurrentRooms.ChildAdded:Connect(function(newChild)
        task.wait(0.2) -- Ensure object is fully loaded
        for _, descendant in ipairs(newChild:GetDescendants()) do
            if (descendant:IsA("MeshPart") and highlightParts[descendant.Name]) or 
               (descendant:IsA("Model") and highlightModels[descendant.Name]) then
                if not addHighlight(descendant, colourChosen) then
                    table.insert(highlightQueue, {instance = descendant, color = colourChosen})
                end
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

local function setupWorkspaceListeners()
    Workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            local alerts = {
                ["RushMoving"] = {Title = "RUSH", Text = "HIDE"},
                ["AmbushMoving"] = {Title = "AMBUSH", Text = "HIDE"},
                ["Eyes"] = {Title = "EYES", Text = "LOOK AWAY"}
            }
            if alerts[child.Name] then
                StarterGui:SetCore("SendNotification", {Title = alerts[child.Name].Title, Text = alerts[child.Name].Text, Duration = 5})
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    cleanupHighlights()
    processDoors()

    -- Retry highlighting objects that failed before
    for i = #highlightQueue, 1, -1 do
        local obj = highlightQueue[i]
        if obj.instance and obj.instance.Parent then
            if addHighlight(obj.instance, obj.color) then
                table.remove(highlightQueue, i) -- Remove from queue once highlighted
            end
        else
            table.remove(highlightQueue, i) -- Remove invalid objects
        end
    end
end)

setupWorkspaceListeners()
trackNewInstances()
trackFigureRig()
processDoors()
processExistingObjects()

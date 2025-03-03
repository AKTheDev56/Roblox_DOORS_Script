local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local colourTable = {
    Yellow = Color3.fromRGB(241, 196, 15),
    Green = Color3.fromRGB(0, 255, 0)
}
local colourChosen = colourTable.Green
local doorHighlightColor = colourTable.Yellow

local highlightParts = { Key = true, Inset = true, Ring = true, Tag = true }
local highlightModels = { LeverForGate = true, LiveHintBook = true, FigureRig = true }

local highlightedCache = {}
local highlightedDoors = {}
local taskQueue = {} -- Queue for thread pooling
local workerThreads = {} -- Pool of worker threads

local function getPlayerPrimaryPart()
    local character = player.Character
    return character and character.PrimaryPart
end

local function addHighlight(instance, color)
    if not highlightedCache[instance] and instance.Parent then
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
        if not instance.Parent then
            highlight:Destroy()
            highlightedCache[instance] = nil
        end
    end
end

local function processDoors()
    local playerPrimaryPart = getPlayerPrimaryPart()
    if not playerPrimaryPart then return end

    for _, child in ipairs(Workspace.CurrentRooms:GetChildren()) do
        local doorModel = child:FindFirstChild("Door")
        if doorModel and doorModel:FindFirstChild("Door") then
            local door = doorModel.Door
            if not highlightedDoors[door] then
                addHighlight(door, doorHighlightColor)
                highlightedDoors[door] = true
            end

            local bb = door:FindFirstChild("BillBoard")
            if not bb then
                bb = Instance.new("BillboardGui")
                bb.Adornee = door
                bb.ExtentsOffset = Vector3.new(0, 1, 0)
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 6, 0, 6)
                bb.Name = "BillBoard"
                bb.Parent = door
            end

            local distLabel = bb:FindFirstChild("Dist")
            if not distLabel then
                distLabel = Instance.new("TextLabel")
                distLabel.ZIndex = 10
                distLabel.BackgroundTransparency = 1
                distLabel.Position = UDim2.new(0, 0, 0, -15)
                distLabel.Size = UDim2.new(1, 0, 10, 0)
                distLabel.Font = Enum.Font.ArialBold
                distLabel.TextStrokeTransparency = 0.5
                distLabel.TextColor3 = doorHighlightColor
                distLabel.Name = "Dist"
                distLabel.Parent = bb
            end

            distLabel.Text = string.format("%.1f Studs", (playerPrimaryPart.Position - door.Position).magnitude)
        end
    end
end

local function processExistingObjects()
    for _, child in ipairs(Workspace.CurrentRooms:GetDescendants()) do
        if highlightParts[child.Name] and child:IsA("MeshPart") then
            addHighlight(child, colourChosen)
        elseif highlightModels[child.Name] and child:IsA("Model") then
            addHighlight(child, colourChosen)
        end
    end
end

local function addToQueue(taskFunc)
    table.insert(taskQueue, taskFunc)
end

local function workerThread()
    while true do
        if #taskQueue > 0 then
            local taskFunc = table.remove(taskQueue, 1)
            pcall(taskFunc)
        end
        task.wait() -- Prevents infinite loop hogging CPU
    end
end

local function setupWorkers(workerCount)
    for i = 1, workerCount do
        task.spawn(workerThread)
    end
end

local function trackNewInstances()
    Workspace.CurrentRooms.ChildAdded:Connect(function(newChild)
        task.wait(0.2) -- Ensure it is fully parented before checking

        for _, descendant in ipairs(newChild:GetDescendants()) do
            addToQueue(function()
                if highlightParts[descendant.Name] and descendant:IsA("MeshPart") then
                    addHighlight(descendant, colourChosen)
                elseif highlightModels[descendant.Name] and descendant:IsA("Model") then
                    addHighlight(descendant, colourChosen)
                elseif descendant:IsA("Model") and descendant:FindFirstChild("Door") and descendant.Door:FindFirstChild("Door") then
                    addHighlight(descendant.Door.Door, doorHighlightColor)
                end
            end)
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
                    addToQueue(function()
                        addHighlight(figureRig, colourChosen)
                    end)
                    break -- Stop checking once highlighted
                end
            end
            task.wait(1)
        end
    end)
end

local function setupWorkspaceListeners()
    Workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            local notifications = {
                RushMoving = { Title = "RUSH", Text = "HIDE", Duration = 5 },
                AmbushMoving = { Title = "AMBUSH", Text = "HIDE", Duration = 5 },
                Eyes = { Title = "EYES", Text = "LOOK AWAY", Duration = 5 }
            }
            local notification = notifications[child.Name]
            if notification then
                StarterGui:SetCore("SendNotification", notification)
            end
        end
    end)
end

setupWorkers(4) -- Creates 4 worker threads
RunService.Heartbeat:Connect(function()
    cleanupHighlights()
    processDoors()
end)

setupWorkspaceListeners()
trackNewInstances()
trackFigureRig()
task.defer(processExistingObjects)

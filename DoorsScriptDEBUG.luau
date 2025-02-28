local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local colourTable = {
    Red = Color3.fromRGB(255, 0, 0),
    Yellow = Color3.fromRGB(241, 196, 15),
    Green = Color3.fromRGB(0, 255, 0)
}
local colourChosen = colourTable.Green
local doorHighlightColor = colourTable.Yellow

local highlightParts = { Key = true, Inset = true, Ring = true, Tag = true }
local highlightModels = { LeverForGate = true, LiveHintBook = true, FigureRig = true }
local highlightedCache = {}
local staticPartsCache = {}

local player = Players.LocalPlayer

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
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
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

local function sendNotification(title, text)
    local NotificationBindable = Instance.new("BindableFunction")
    NotificationBindable.OnInvoke = function() end

    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 5,
        Callback = NotificationBindable
    })
end

local function cacheStaticParts(folder)
    staticPartsCache = {} -- Clear previous cache
    for _, child in ipairs(folder:GetDescendants()) do
        if child:IsA("MeshPart") and highlightParts[child.Name] then
            table.insert(staticPartsCache, child)
        elseif child:IsA("Model") and highlightModels[child.Name] then
            table.insert(staticPartsCache, child)
        end
    end
end

local function findAndHighlightInstances()
    for _, part in ipairs(staticPartsCache) do
        addHighlight(part, colourChosen)
    end
end

local function highlightDoors(folder)
    local playerPrimaryPart = getPlayerPrimaryPart()
    if not playerPrimaryPart then return end

    for _, room in ipairs(folder:GetChildren()) do
        local door = room:FindFirstChild("Door") and room.Door:FindFirstChild("Door")
        if door and not highlightedCache[door] then
            addHighlight(door, doorHighlightColor)

            if not door:FindFirstChild("BillBoard") then
                local bb = Instance.new("BillboardGui")
                bb.Adornee = door
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 6, 0, 6)
                bb.StudsOffset = Vector3.new(0, 1, 0)
                bb.Name = "BillBoard"
                bb.Parent = door

                local nameLabel = Instance.new("TextLabel")
                nameLabel.BackgroundTransparency = 1
                nameLabel.Position = UDim2.new(0, 0, 0, -45)
                nameLabel.Size = UDim2.new(1, 0, 10, 0)
                nameLabel.Font = Enum.Font.ArialBold
                nameLabel.Text = "Door " .. room.Name
                nameLabel.TextStrokeTransparency = 0.5
                nameLabel.TextColor3 = doorHighlightColor
                nameLabel.ZIndex = 10
                nameLabel.Parent = bb

                local distLabel = Instance.new("TextLabel")
                distLabel.Name = "Dist"
                distLabel.BackgroundTransparency = 1
                distLabel.Position = UDim2.new(0, 0, 0, -15)
                distLabel.Size = UDim2.new(1, 0, 10, 0)
                distLabel.Font = Enum.Font.ArialBold
                distLabel.TextStrokeTransparency = 0.5
                distLabel.TextColor3 = doorHighlightColor
                distLabel.ZIndex = 10
                distLabel.Parent = bb
            end
        end

        local bb = door and door:FindFirstChild("BillBoard")
        local distLabel = bb and bb:FindFirstChild("Dist")
        if distLabel then
            distLabel.Text = round((playerPrimaryPart.Position - door.Position).magnitude, 1) .. " Studs"
        end
    end
end

local function highlightFigureRig()
    local room50 = Workspace:WaitForChild("50")
    local figureRig = room50:WaitForChild("FigureRig")

    addHighlight(figureRig, colourChosen)
end

local function setupWorkspaceListeners(workspace)
    workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            if child.Name == "RushMoving" then
                sendNotification("RUSH", "HIDE")
            elseif child.Name == "AmbushMoving" then
                sendNotification("AMBUSH", "HIDE")
            elseif child.Name == "Eyes" then
                sendNotification("EYES", "LOOK AWAY")
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    findAndHighlightInstances()
    highlightDoors(Workspace)
    cleanupHighlights()
end)

setupWorkspaceListeners(Workspace)
highlightFigureRig()

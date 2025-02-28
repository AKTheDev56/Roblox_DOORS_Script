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

local function cacheStaticParts()
    staticPartsCache = {} -- Clear previous cache
    for _, child in ipairs(Workspace:GetDescendants()) do
        -- Cache both mesh parts and models
        if child:IsA("MeshPart") and highlightParts[child.Name] then
            table.insert(staticPartsCache, child) -- Ensure Key, Inset, Ring, Tag are included
        elseif child:IsA("Model") and highlightModels[child.Name] then
            table.insert(staticPartsCache, child)
        end
    end
end

local function findAndHighlightInstances()
    for _, part in ipairs(staticPartsCache) do
        addHighlight(part, colourChosen) -- Apply highlighting to all cached parts
    end
end

local function highlightDoors()
    local playerPrimaryPart = getPlayerPrimaryPart()
    if not playerPrimaryPart then return end

    local currentRoomsFolder = Workspace:FindFirstChild("CurrentRooms")
    if not currentRoomsFolder then return end

    for _, room in ipairs(currentRoomsFolder:GetChildren()) do
        if room:IsA("Model") and room:FindFirstChild("Door") and room.Door:FindFirstChild("Door") then
            local door = room.Door.Door

            -- Always ensure a Highlight exists for the door
            if not highlightedCache[door] then
                addHighlight(door, doorHighlightColor)

                -- Add a BillboardGui for distance labeling
                if not door:FindFirstChild("BillBoard") then
                    local bb = Instance.new("BillboardGui", door)
                    bb.Adornee = door
                    bb.ExtentsOffset = Vector3.new(0, 1, 0)
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 6, 0, 6)
                    bb.StudsOffset = Vector3.new(0, 1, 0)
                    bb.Name = "BillBoard"

                    local txtlbl = Instance.new("TextLabel", bb)
                    txtlbl.ZIndex = 10
                    txtlbl.BackgroundTransparency = 1
                    txtlbl.Position = UDim2.new(0, 0, 0, -45)
                    txtlbl.Size = UDim2.new(1, 0, 10, 0)
                    txtlbl.Font = Enum.Font.ArialBold
                    txtlbl.Text = "Door " .. room.Name
                    txtlbl.TextStrokeTransparency = 0.5
                    txtlbl.TextColor3 = doorHighlightColor

                    local txtlbl2 = Instance.new("TextLabel", bb)
                    txtlbl2.ZIndex = 10
                    txtlbl2.BackgroundTransparency = 1
                    txtlbl2.Position = UDim2.new(0, 0, 0, -15)
                    txtlbl2.Size = UDim2.new(1, 0, 10, 0)
                    txtlbl2.Font = Enum.Font.ArialBold
                    txtlbl2.TextStrokeTransparency = 0.5
                    txtlbl2.TextColor3 = doorHighlightColor
                    txtlbl2.Name = "Dist"
                end
            end

            -- Update distance label dynamically
            local bb = door:FindFirstChild("BillBoard")
            local distLabel = bb and bb:FindFirstChild("Dist")
            if distLabel then
                distLabel.Text = round((playerPrimaryPart.Position - door.Position).magnitude, 1) .. " Studs"
            end
        end
    end
end

local function setupWorkspaceListeners()
    Workspace.ChildAdded:Connect(function(child)
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
    cleanupHighlights()
    cacheStaticParts() -- Update the cache with Key, Inset, Ring, and Tag
    findAndHighlightInstances() -- Highlight mesh parts
    highlightDoors() -- Ensure doors are highlighted with text and distance
end)

setupWorkspaceListeners()
cacheStaticParts()
findAndHighlightInstances()
highlightDoors()

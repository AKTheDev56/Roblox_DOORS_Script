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

local function cacheStaticParts()
    staticPartsCache = {} -- Clear previous cache
    for _, child in ipairs(Workspace:GetDescendants()) do
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

local function setupWorkspaceListeners()
    cacheStaticParts()

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
        
        cacheStaticParts()
        findAndHighlightInstances()
    end)

    Workspace.DescendantRemoving:Connect(function(instance)
        highlightedCache[instance] = nil
        
        cacheStaticParts()
    end)
end

RunService.Heartbeat:Connect(function()
    cleanupHighlights()
    findAndHighlightInstances()
end)

setupWorkspaceListeners()
cacheStaticParts()
findAndHighlightInstances()

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

local function highlightKeyRingTagParts()
    for _, child in ipairs(Workspace:GetDescendants()) do
        -- Highlight mesh parts like Key, Inset, Ring, and Tag
        if child:IsA("MeshPart") and highlightParts[child.Name] then
            addHighlight(child, colourChosen)
        -- Highlight specific models like LeverForGate, LiveHintBook, and FigureRig
        elseif child:IsA("Model") and highlightModels[child.Name] then
            addHighlight(child, colourChosen)
        end
    end
end

spawn(function()
    while wait(0.04) do
        for _, room in ipairs(Workspace.CurrentRooms:GetChildren()) do
            if room:FindFirstChild("Door") and room.Door:FindFirstChild("Door") and not room.Door.Door:FindFirstChild("Highlight") then
                local door = room.Door.Door

                -- Add highlight to the door
                local hg = Instance.new("Highlight", door)
                hg.FillColor = Color3.fromRGB(241, 196, 15)
                hg.FillTransparency = 0.5

                -- Add BillboardGui for distance labels
                local bb = Instance.new("BillboardGui", door)
                bb.Adornee = door
                bb.ExtentsOffset = Vector3.new(0, 1, 0)
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 6, 0, 6)
                bb.Name = "BillBoard"

                local txtlbl = Instance.new("TextLabel", bb)
                txtlbl.ZIndex = 10
                txtlbl.BackgroundTransparency = 1
                txtlbl.Position = UDim2.new(0, 0, 0, -15)
                txtlbl.Size = UDim2.new(1, 0, 10, 0)
                txtlbl.Font = Enum.Font.ArialBold
                txtlbl.FontSize = "Size12"
                txtlbl.TextStrokeTransparency = 0.5
                txtlbl.TextColor3 = Color3.fromRGB(241, 196, 15)
                txtlbl.Name = "Dist"
                txtlbl.Text = "? Studs"
            end

            -- Update distance dynamically
            if room:FindFirstChild("Door") and room.Door:FindFirstChild("Door") and room.Door.Door:FindFirstChild("BillBoard") then
                local door = room.Door.Door
                local distLabel = door.BillBoard:FindFirstChild("Dist")
                if distLabel then
                    local playerPrimaryPart = getPlayerPrimaryPart()
                    if playerPrimaryPart then
                        distLabel.Text = round((playerPrimaryPart.Position - door.Position).magnitude, 1) .. " Studs"
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    cleanupHighlights() -- Clean up invalid highlights
    highlightKeyRingTagParts() -- Highlight Key, Inset, Ring, Tag, and models
end)

local function addHighlight(instance, color)
    if not highlightedCache[instance] and instance:IsDescendantOf(Workspace) then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = instance
        highlight.FillColor = color
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = instance
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

local function findAndHighlightInstances(folder)
    for _, child in ipairs(folder:GetDescendants()) do
        if highlightParts[child.Name] and child:IsA("MeshPart") then
            addHighlight(child, colourChosen)
        elseif highlightModels[child.Name] and child:IsA("Model") then
            addHighlight(child, colourChosen)
        end
    end
end

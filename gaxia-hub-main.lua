-- Thaiban City Complete Hub v3.0 - LinoriaLib UI
-- By NotGaxia

getgenv().ThaibanHub = getgenv().ThaibanHub or {}
local hub = getgenv().ThaibanHub

-- Prevent double load
if hub.Loaded then
    if hub.PlayerESP then hub.PlayerESP.Destroy() end
    if hub.PuddleESP then hub.PuddleESP.Destroy() end
end

hub.Loaded = true
hub.FarmRunning = false
hub.PuddlesCleaned = 0

local lp = game:GetService("Players").LocalPlayer
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local pathfindingService = game:GetService("PathfindingService")
local vim = game:GetService("VirtualInputManager")

print("[Hub] Loading LinoriaLib...")

-- Load LinoriaLib
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()

-- Create Window
local Window = Library:CreateWindow({
    Title = "Thaiban City Hub v3.0",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab("Main"),
    ESP = Window:AddTab("ESP"),
    Settings = Window:AddTab("Settings")
}

print("[Hub] UI Framework loaded")

--// ========== ESP SYSTEM ========== \\--

-- Player ESP
local PlayerESPObjects = {}
local TEAMCOLOR_MAP = {
    ["Forest green"]  = Color3.fromRGB(100, 220, 100),
    ["Bright red"]    = Color3.fromRGB(255,  60,  60),
    ["Bright orange"] = Color3.fromRGB(255, 165,   0),
    ["Really blue"]   = Color3.fromRGB(60,  140, 255),
    ["Storm blue"]    = Color3.fromRGB(130, 180, 255),
}

local SKELETON_JOINTS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

local PlayerESPSettings = {
    Enabled = false,
    Box = true,
    Skeleton = true,
    Name = true,
    Traceline = true,
    MaxDistance = 500,
}

local function createPlayerESP(player)
    if player == lp then return end

    local esp = {
        Player = player,
        Box = {},
        Skeleton = {},
        NameLabel = nil,
        Traceline = nil,
    }

    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Visible = false
        esp.Box[i] = line
    end

    for i = 1, 14 do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Visible = false
        esp.Skeleton[i] = line
    end

    local text = Drawing.new("Text")
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.Visible = false
    esp.NameLabel = text

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Visible = false
    esp.Traceline = line

    PlayerESPObjects[player] = esp
end

local function updatePlayerESP()
    if not PlayerESPSettings.Enabled then return end

    local cam = workspace.CurrentCamera
    local vp = cam.ViewportSize

    for player, esp in pairs(PlayerESPObjects) do
        if not player.Parent or not player.Character then
            for _, line in ipairs(esp.Box) do line.Visible = false end
            for _, line in ipairs(esp.Skeleton) do line.Visible = false end
            esp.NameLabel.Visible = false
            esp.Traceline.Visible = false
            continue
        end

        local char = player.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if not hrp then
            for _, line in ipairs(esp.Box) do line.Visible = false end
            for _, line in ipairs(esp.Skeleton) do line.Visible = false end
            esp.NameLabel.Visible = false
            esp.Traceline.Visible = false
            continue
        end

        local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then continue end

        local dist = (hrp.Position - myHrp.Position).Magnitude

        if dist > PlayerESPSettings.MaxDistance then
            for _, line in ipairs(esp.Box) do line.Visible = false end
            for _, line in ipairs(esp.Skeleton) do line.Visible = false end
            esp.NameLabel.Visible = false
            esp.Traceline.Visible = false
            continue
        end

        local color = Color3.new(1, 1, 1)
        if player.Team then
            local teamColorStr = tostring(player.Team.TeamColor)
            color = TEAMCOLOR_MAP[teamColorStr] or Color3.new(1, 1, 1)
        end

        local rootPos, rootOnScreen = cam:WorldToViewportPoint(hrp.Position)

        if not rootOnScreen then
            for _, line in ipairs(esp.Box) do line.Visible = false end
            for _, line in ipairs(esp.Skeleton) do line.Visible = false end
            esp.NameLabel.Visible = false
            esp.Traceline.Visible = false
            continue
        end

        if PlayerESPSettings.Box then
            local parts = {"Head", "HumanoidRootPart", "LeftFoot", "RightFoot", "LeftHand", "RightHand"}
            local positions = {}
            for _, name in ipairs(parts) do
                local part = char:FindFirstChild(name)
                if part then
                    local pos = cam:WorldToViewportPoint(part.Position)
                    table.insert(positions, Vector2.new(pos.X, pos.Y))
                end
            end

            if #positions > 0 then
                local minX, maxX = math.huge, -math.huge
                local minY, maxY = math.huge, -math.huge

                for _, pos in ipairs(positions) do
                    minX = math.min(minX, pos.X)
                    maxX = math.max(maxX, pos.X)
                    minY = math.min(minY, pos.Y)
                    maxY = math.max(maxY, pos.Y)
                end

                esp.Box[1].From = Vector2.new(minX, minY)
                esp.Box[1].To = Vector2.new(maxX, minY)
                esp.Box[2].From = Vector2.new(maxX, minY)
                esp.Box[2].To = Vector2.new(maxX, maxY)
                esp.Box[3].From = Vector2.new(maxX, maxY)
                esp.Box[3].To = Vector2.new(minX, maxY)
                esp.Box[4].From = Vector2.new(minX, maxY)
                esp.Box[4].To = Vector2.new(minX, minY)

                for _, line in ipairs(esp.Box) do
                    line.Color = color
                    line.Visible = true
                end
            end
        else
            for _, line in ipairs(esp.Box) do line.Visible = false end
        end

        if PlayerESPSettings.Skeleton then
            for i, joint in ipairs(SKELETON_JOINTS) do
                local part1 = char:FindFirstChild(joint[1])
                local part2 = char:FindFirstChild(joint[2])

                if part1 and part2 then
                    local pos1, onScreen1 = cam:WorldToViewportPoint(part1.Position)
                    local pos2, onScreen2 = cam:WorldToViewportPoint(part2.Position)

                    if onScreen1 and onScreen2 then
                        esp.Skeleton[i].From = Vector2.new(pos1.X, pos1.Y)
                        esp.Skeleton[i].To = Vector2.new(pos2.X, pos2.Y)
                        esp.Skeleton[i].Color = color
                        esp.Skeleton[i].Visible = true
                    else
                        esp.Skeleton[i].Visible = false
                    end
                else
                    esp.Skeleton[i].Visible = false
                end
            end
        else
            for _, line in ipairs(esp.Skeleton) do line.Visible = false end
        end

        if PlayerESPSettings.Name then
            local teamName = player.Team and player.Team.Name or "No Team"
            esp.NameLabel.Text = player.DisplayName .. " [" .. teamName .. "]  " .. math.floor(dist) .. "m"
            esp.NameLabel.Position = Vector2.new(rootPos.X, rootPos.Y - 40)
            esp.NameLabel.Color = color
            esp.NameLabel.Visible = true
        else
            esp.NameLabel.Visible = false
        end

        if PlayerESPSettings.Traceline then
            esp.Traceline.From = Vector2.new(vp.X / 2, vp.Y)
            esp.Traceline.To = Vector2.new(rootPos.X, rootPos.Y)
            esp.Traceline.Color = color
            esp.Traceline.Visible = true
        else
            esp.Traceline.Visible = false
        end
    end
end

-- Puddle ESP
local PuddleESPObjects = {}
local PuddleESPSettings = {
    Enabled = false,
    Color = Color3.fromRGB(100, 200, 255),
}

local function updatePuddleESP()
    if not PuddleESPSettings.Enabled then
        for _, esp in pairs(PuddleESPObjects) do
            if esp.Text then esp.Text:Remove() end
        end
        PuddleESPObjects = {}
        return
    end

    local cam = workspace.CurrentCamera
    local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    local currentPuddles = {}

    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "Puddle" and v:IsA("BasePart") and v.Parent then
            currentPuddles[v] = true

            if not PuddleESPObjects[v] then
                local text = Drawing.new("Text")
                text.Size = 16
                text.Center = true
                text.Outline = true
                text.Color = PuddleESPSettings.Color
                PuddleESPObjects[v] = {Text = text, Puddle = v}
            end
        end
    end

    for puddle, esp in pairs(PuddleESPObjects) do
        if not currentPuddles[puddle] then
            esp.Text:Remove()
            PuddleESPObjects[puddle] = nil
        end
    end

    for puddle, esp in pairs(PuddleESPObjects) do
        local pos, onScreen = cam:WorldToViewportPoint(puddle.Position)

        if onScreen then
            local dist = (puddle.Position - myHrp.Position).Magnitude

            local hp = 1.0
            local ui = puddle:FindFirstChild("JobUI")
            local fill = ui and ui:FindFirstChild("Fill", true)
            if fill then
                hp = fill.Size.X.Scale
            end

            esp.Text.Text = string.format("Puddle [%.0f%%]  %dm", hp * 100, math.floor(dist))
            esp.Text.Position = Vector2.new(pos.X, pos.Y)
            esp.Text.Visible = true
        else
            esp.Text.Visible = false
        end
    end
end

print("[Hub] ESP systems ready")

--// ========== SMOOTH PATHFINDING ========== \\--

local function walkToPositionSmooth(position, timeout)
    timeout = timeout or 10

    local char = lp.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then return false end

    local path = pathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = false,
    })

    local success, err = pcall(function()
        path:ComputeAsync(hrp.Position, position)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        humanoid:MoveTo(position)
        return true
    end

    local waypoints = path:GetWaypoints()

    local filteredWaypoints = {}
    local lastWaypoint = nil
    for i, waypoint in ipairs(waypoints) do
        if not lastWaypoint or (waypoint.Position - lastWaypoint.Position).Magnitude > 3 then
            table.insert(filteredWaypoints, waypoint)
            lastWaypoint = waypoint
        end
    end

    local startTime = tick()

    for i, waypoint in ipairs(filteredWaypoints) do
        if tick() - startTime > timeout then break end
        if not hub.FarmRunning then break end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        humanoid:MoveTo(waypoint.Position)

        local moveStart = tick()
        while tick() - moveStart < 2 and hub.FarmRunning do
            local dist = (hrp.Position - waypoint.Position).Magnitude
            if dist < 4 then break end
            task.wait(0.03)
        end
    end

    humanoid:MoveTo(position)
    local finalWaitStart = tick()
    while tick() - finalWaitStart < 1 and hub.FarmRunning do
        local dist = (hrp.Position - position).Magnitude
        if dist < 3 then break end
        task.wait(0.03)
    end

    return true
end

print("[Hub] Pathfinding system ready")

--// ========== FARM LOGIC ========== \\--

local FarmSettings = {
    AutoAcceptJob = true,
    ClickDelay = 0.4,
    SelectNearest = true,
    WalkSpeed = 16,
}

local function getPuddles()
    local puddles = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "Puddle" and v:IsA("BasePart") and v.Parent then
            table.insert(puddles, v)
        end
    end
    return puddles
end

local function getNearestPuddle(puddles)
    local myHrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp or #puddles == 0 then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, puddle in ipairs(puddles) do
        local dist = (puddle.Position - myHrp.Position).Magnitude
        if dist < nearestDist then
            nearestDist = dist
            nearest = puddle
        end
    end

    return nearest
end

local function acceptJobFromNPC()
    local char = lp.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if not humanoid then return false end

    local npc = workspace:FindFirstChild("JobInteractions")
        and workspace.JobInteractions:FindFirstChild("NPCJobGiver")
        and workspace.JobInteractions.NPCJobGiver:FindFirstChild("SevenEleven")

    if not npc then return false end

    local prompt = npc:FindFirstChildOfClass("ProximityPrompt", true)
    local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")

    if not prompt or not root then return false end

    walkToPositionSmooth(root.Position, 5)
    task.wait(0.5)
    fireproximityprompt(prompt)
    task.wait(1.5)

    return true
end

local function cleanPuddle(puddle)
    local char = lp.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp or not puddle.Parent then return false end

    walkToPositionSmooth(puddle.Position, 8)
    task.wait(0.2)

    if not hub.FarmRunning then return false end

    local ui = puddle:FindFirstChild("JobUI")
    local fill = ui and ui:FindFirstChild("Fill", true)
    if not fill then return false end

    local clicks = 0
    while puddle.Parent and clicks < 15 and hub.FarmRunning do
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        task.wait(FarmSettings.ClickDelay)
        clicks = clicks + 1

        if fill.Size.X.Scale <= 0.05 then
            task.wait(0.3)
            break
        end
    end

    return not puddle.Parent
end

local StatusLabel = nil

local function FarmLoop()
    while hub.FarmRunning do
        local char = lp.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not humanoid then
            if StatusLabel then
                StatusLabel:SetValue("Waiting for character...")
            end
            task.wait(2)
            continue
        end

        if humanoid.WalkSpeed ~= FarmSettings.WalkSpeed then
            humanoid.WalkSpeed = FarmSettings.WalkSpeed
        end

        if humanoid.SeatPart then
            humanoid.Sit = false
            task.wait(0.5)
        end

        local broom = char:FindFirstChild("Broom")
        if not broom then
            broom = lp.Backpack:FindFirstChild("Broom")
            if broom then
                humanoid:EquipTool(broom)
                task.wait(0.5)
            else
                if FarmSettings.AutoAcceptJob then
                    if StatusLabel then
                        StatusLabel:SetValue("Getting job...")
                    end
                    acceptJobFromNPC()
                    task.wait(2)
                    continue
                else
                    if StatusLabel then
                        StatusLabel:SetValue("No broom!")
                    end
                    task.wait(3)
                    continue
                end
            end
        end

        local puddles = getPuddles()

        if #puddles == 0 then
            if FarmSettings.AutoAcceptJob then
                if StatusLabel then
                    StatusLabel:SetValue("No puddles, getting new job...")
                end
                acceptJobFromNPC()
                task.wait(2)
            else
                if StatusLabel then
                    StatusLabel:SetValue("No puddles, waiting...")
                end
                task.wait(2)
            end
            continue
        end

        if StatusLabel then
            StatusLabel:SetValue(string.format("Cleaning %d puddles...", #puddles))
        end

        local cleaned = 0
        while #puddles > 0 and hub.FarmRunning do
            local targetPuddle

            if FarmSettings.SelectNearest then
                targetPuddle = getNearestPuddle(puddles)
            else
                targetPuddle = puddles[1]
            end

            if not targetPuddle then break end

            for i, p in ipairs(puddles) do
                if p == targetPuddle then
                    table.remove(puddles, i)
                    break
                end
            end

            cleaned = cleaned + 1
            if StatusLabel then
                StatusLabel:SetValue(string.format("Cleaning %d/%d", cleaned, cleaned + #puddles))
            end

            if cleanPuddle(targetPuddle) then
                hub.PuddlesCleaned = hub.PuddlesCleaned + 1
            end

            task.wait(0.3)
        end

        if StatusLabel then
            StatusLabel:SetValue("Cycle complete")
        end
        task.wait(1)
    end

    if StatusLabel then
        StatusLabel:SetValue("Stopped")
    end
end

print("[Hub] Farm system ready")

--// ========== UI SETUP ========== \\--

-- Main Tab
local MainGroup = Tabs.Main:AddLeftGroupbox("Seven-Eleven Farm")

MainGroup:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = false,
    Callback = function(v)
        hub.FarmRunning = v
        if v then
            task.spawn(FarmLoop)
        end
    end
})

MainGroup:AddToggle("AutoAcceptJob", {
    Text = "Auto Accept Job",
    Default = true,
    Callback = function(v)
        FarmSettings.AutoAcceptJob = v
    end
})

MainGroup:AddToggle("SelectNearest", {
    Text = "Select Nearest Puddle",
    Default = true,
    Callback = function(v)
        FarmSettings.SelectNearest = v
    end
})

StatusLabel = MainGroup:AddLabel("Status: Idle")

local PuddlesCleanedLabel = MainGroup:AddLabel("Puddles Cleaned: 0")

task.spawn(function()
    while true do
        task.wait(0.5)
        if PuddlesCleanedLabel then
            PuddlesCleanedLabel:SetValue("Puddles Cleaned: " .. hub.PuddlesCleaned)
        end
    end
end)

local MainRightGroup = Tabs.Main:AddRightGroupbox("Farm Settings")

MainRightGroup:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 50,
    Rounding = 0,
    Callback = function(v)
        FarmSettings.WalkSpeed = v
        local humanoid = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = v
        end
    end
})

MainRightGroup:AddSlider("ClickDelay", {
    Text = "Click Delay (ms)",
    Default = 400,
    Min = 200,
    Max = 1000,
    Rounding = 0,
    Callback = function(v)
        FarmSettings.ClickDelay = v / 1000
    end
})

-- ESP Tab
local PlayerESPGroup = Tabs.ESP:AddLeftGroupbox("Player ESP")

PlayerESPGroup:AddToggle("PlayerESPEnabled", {
    Text = "Enable Player ESP",
    Default = false,
    Callback = function(v)
        PlayerESPSettings.Enabled = v
        if not v then
            for _, esp in pairs(PlayerESPObjects) do
                for _, line in ipairs(esp.Box) do line.Visible = false end
                for _, line in ipairs(esp.Skeleton) do line.Visible = false end
                esp.NameLabel.Visible = false
                esp.Traceline.Visible = false
            end
        end
    end
})

PlayerESPGroup:AddToggle("PlayerBox", {
    Text = "Box",
    Default = true,
    Callback = function(v) PlayerESPSettings.Box = v end
})

PlayerESPGroup:AddToggle("PlayerSkeleton", {
    Text = "Skeleton",
    Default = true,
    Callback = function(v) PlayerESPSettings.Skeleton = v end
})

PlayerESPGroup:AddToggle("PlayerName", {
    Text = "Name + Distance",
    Default = true,
    Callback = function(v) PlayerESPSettings.Name = v end
})

PlayerESPGroup:AddToggle("PlayerTraceline", {
    Text = "Traceline",
    Default = true,
    Callback = function(v) PlayerESPSettings.Traceline = v end
})

PlayerESPGroup:AddSlider("PlayerESPDistance", {
    Text = "Max Distance",
    Default = 500,
    Min = 100,
    Max = 1000,
    Rounding = 0,
    Suffix = "m",
    Callback = function(v)
        PlayerESPSettings.MaxDistance = v
    end
})

local PuddleESPGroup = Tabs.ESP:AddRightGroupbox("Puddle ESP")

PuddleESPGroup:AddToggle("PuddleESPEnabled", {
    Text = "Enable Puddle ESP",
    Default = false,
    Callback = function(v)
        PuddleESPSettings.Enabled = v
    end
})

-- Settings Tab (UI Settings)
local UISettingsGroup = Tabs.Settings:AddLeftGroupbox("UI Settings")

UISettingsGroup:AddButton("Unload GUI", function()
    Library:Unload()
end)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("ThaibanHub")
ThemeManager:ApplyToTab(Tabs.Settings)

print("[Hub] UI created")

--// ========== INITIALIZE ========== \\--

for _, player in ipairs(players:GetPlayers()) do
    createPlayerESP(player)
end

players.PlayerAdded:Connect(createPlayerESP)

players.PlayerRemoving:Connect(function(player)
    if PlayerESPObjects[player] then
        local esp = PlayerESPObjects[player]
        for _, line in ipairs(esp.Box) do line:Remove() end
        for _, line in ipairs(esp.Skeleton) do line:Remove() end
        esp.NameLabel:Remove()
        esp.Traceline:Remove()
        PlayerESPObjects[player] = nil
    end
end)

runService.RenderStepped:Connect(function()
    pcall(updatePlayerESP)
    pcall(updatePuddleESP)
end)

hub.PlayerESP = {
    Enabled = function(v) PlayerESPSettings.Enabled = v end,
    Destroy = function()
        for _, esp in pairs(PlayerESPObjects) do
            for _, line in ipairs(esp.Box) do pcall(function() line:Remove() end) end
            for _, line in ipairs(esp.Skeleton) do pcall(function() line:Remove() end) end
            pcall(function() esp.NameLabel:Remove() end)
            pcall(function() esp.Traceline:Remove() end)
        end
        PlayerESPObjects = {}
    end
}

hub.PuddleESP = {
    Enabled = function(v) PuddleESPSettings.Enabled = v end,
    Destroy = function()
        for _, esp in pairs(PuddleESPObjects) do
            pcall(function() esp.Text:Remove() end)
        end
        PuddleESPObjects = {}
    end
}

print("[Thaiban Hub] ✓ v3.0 Loaded with LinoriaLib!")
print("[Thaiban Hub] ✓ Features: ESP, Auto Farm, Settings")

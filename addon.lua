local api = getfenv().api or {};
local tabs = {
    lua = api:AddTab("extra");
}

local framework = {
    connections = {},   
    elements = {},     
    ui = {},
    EquippedTools = {},
    MultiToolActive = false,
    IsHoldingKey = false,
    antifling = false,
    antisitinactive = false,
    spinning = false
}

do
    local tab = api:GetTab("extra");
    local credits = tabs.lua:AddLeftGroupbox("credits")
    credits:AddLabel(
        'script by: d6jrz\n' ..
        'contributors: ender (thanks babe❤❤)', true
    )
end;

do
    local tab = api:GetTab("extra");
    local updates = tabs.lua:AddRightGroupbox("updates")
    updates:AddLabel(
        'update logs:\n' ..
        '[+] made for new ui\n' ..
        '[-] multi tool\n' ..
        'if there is ANY bugs or ANY suggestions at all please dm me😁👍', true
    )
end;

do
    local server = tabs.lua:AddLeftGroupbox("server");
    server:AddButton("vc unban", function()
        local success, VCEnabled = pcall(function()
            return cloneref(game:GetService("VoiceChatService")):IsVoiceEnabledForUserIdAsync(game.Players.LocalPlayer.UserId);
        end);

        if not success then
            api:notify("vc failed", 5);
            return
        end

        if VCEnabled then
            cloneref(game:GetService("VoiceChatService")):JoinVoice();
            api:notify("unbanned vc", 3);
        else
            api:notify("vc disabled", 5);
        end;
    end);
end;

do
    local tab = api:GetTab("extra");
    local server = tab:GetGroupbox("server");
    server:AddButton("rejoin server", function()
        queue_on_teleport(([[
            script_key = "%s";
            if not (game:IsLoaded()) then game.Loaded:Wait() end
            if (getgenv().UC_LOADED) then
                return;
            end;
            getgenv().UC_LOADED = true;
            loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/e15033fd74a9b2664dc7b85699c78b69.lua"))();
]]):format(script_key));
        cloneref(game:GetService("TeleportService")):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer);
        api:notify("rejoining server", 5);
    end);
end;

do
    local tab = api:GetTab("extra");
    local server = tab:GetGroupbox("server");
    server:AddButton("copy server join script", function()
        setclipboard(string.format("cloneref(game:GetService('TeleportService')):TeleportToPlaceInstance(%d, '%s', game.Players.LocalPlayer)", game.PlaceId, game.JobId));
        api:notify("copied server join script", 5);
    end);
end;

do
    local tab = api:GetTab("extra");
    local misc = tabs.lua:AddLeftGroupbox("misc");
    local block = misc:AddToggle("auto_block", {
        Text = "god block", Default = false;
    });
    table.insert(framework.connections, cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
        if block.Value then
            local char = game.Players.LocalPlayer.Character
            if not char then return end
            game.ReplicatedStorage.MainEvent:FireServer("Block", true)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, anim in ipairs(hum:GetPlayingAnimationTracks()) do
                    if anim.Animation.AnimationId:match("2788354405") then
                        anim:Stop()
                    end;
                end;
            end;
            local effects = char:FindFirstChild("BodyEffects")
            if effects and effects:FindFirstChild("Block") then
                effects.Block:Destroy()
            end;
        end;
    end));
end;

local CollectDHC = false;

local function CashAura()
    while CollectDHC do
        local dhc = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Drop")
        if dhc then
            for _, MoneyDrop in ipairs(dhc:GetChildren()) do
                if MoneyDrop:IsA("Part") and MoneyDrop.Name == "MoneyDrop" then
                    local distance = (game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart").Position - MoneyDrop.Position).Magnitude
                    if distance <= 20 then
                        local ClickDetector = MoneyDrop:FindFirstChildOfClass("ClickDetector")
                        if ClickDetector then
                            fireclickdetector(ClickDetector)
                        end;
                    end;
                end;
            end;
        end;
        task.wait(1);
    end;
end;

local tab = api:GetTab("extra");
local misc = tab:GetGroupbox("misc");
misc:AddToggle("dhc_aura", {
    Text = "cash aura", Default = false,
    Callback = function(state)
        CollectDHC = state
        if state then
            task.spawn(CashAura)
        end;
    end,
});

if Toggles.dhc_aura and Toggles.dhc_aura.Value then
    CollectDHC = true;
    task.spawn(CashAura);
end;

do
    local tab = api:GetTab("extra");
    local misc = tab:GetGroupbox("misc");
    local joins, leave = nil, nil
    misc:AddToggle("logs_toggle", {
        Text = "actitivty logs", Default = false, Tooltip = "leave and join logs",
        Callback = function(enabled)
            if enabled then
                misc:AddInput("notify_text", {
                    Text = "Notification Text",
                    Default = "{NAME} has {ACTIVITY} the game.",
                    Placeholder = "ex: {NAME}, {ACTIVITY}",
                    Finished = true
                })
                misc:AddSlider("notify_duration", {
                    Text = "Notify Duration",
                    Default = 3,
                    Min = 0.5,
                    Max = 10,
                    Rounding = 1,
                    Suffix = "s"
                })
                joins = game.Players.PlayerAdded:Connect(function(p)
                    api:notify(Options.notify_text.Value:gsub("{NAME}", p.Name):gsub("{ACTIVITY}", "joined"), Options.notify_duration.Value)
                end);
                leave = game.Players.PlayerRemoving:Connect(function(p)
                    api:notify(Options.notify_text.Value:gsub("{NAME}", p.Name):gsub("{ACTIVITY}", "left"), Options.notify_duration.Value)
                end);
                table.insert(framework.connections, joins)
                table.insert(framework.connections, leave)
            else
                if joins then joins:Disconnect() end
                if leave then leave:Disconnect() end
            end;
        end;
    });
end;

local tab = api:GetTab("extra");
local misc = tab:GetGroupbox("misc");
misc:AddToggle("anti_fling", {
    Text = "anti fling", Default = false,
});
    
local collision = {};

table.insert(framework.connections, cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
    local toggle = Toggles.anti_fling
    if not toggle or not toggle.Value then
        for player, parts in pairs(collision) do
            if player and player.Character then
                for part, properties in pairs(parts) do
                    if part and part:IsA("BasePart") then
                        part.CanCollide = properties.CanCollide
                        if part.Name == "Torso" then
                            part.Massless = properties.Massless
                        end;
                    end;
                end;
            end;
        end;
        return;
    end;
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player == game.Players.LocalPlayer or not player.Character then continue end
        
        pcall(function()
            local parts = {}
            for _, part in ipairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    parts[part] = {
                        CanCollide = part.CanCollide,
                        Massless = part.Name == "Torso" and part.Massless or false
                    }
                    part.CanCollide = false
                    if part.Name == "Torso" then
                        part.Massless = true
                    end
                    if toggle.Value then
                        part.Velocity = Vector3.zero
                        part.RotVelocity = Vector3.zero
                    end;
                end;
            end;
            collision[player] = parts
        end);
    end;
end));

local CreateTool, RemoveTool
local jerk = nil
local respawn = nil

CreateTool = function()
    local plr = game:GetService("Players").LocalPlayer
    local pack = plr:WaitForChild("Backpack")
    if jerk and jerk.Parent == pack then return end
    
    if jerk then jerk:Destroy() end
    local existing = workspace:FindFirstChild("aaa")
    if existing then existing:Destroy() end
    
    local animation = Instance.new("Animation")
    animation.Name = "aaa"
    animation.AnimationId = (plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15)
        and "rbxassetid://698251653" or "rbxassetid://72042024"
    
    local doing, anim = false, nil
    jerk = Instance.new("Tool")
    jerk.Name = "Jerk"
    jerk.RequiresHandle = false
    jerk.Parent = pack

    jerk.Equipped:Connect(function()
        doing = true
        while doing do
            if not anim then
                local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
                local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator"))
                if not animator then break end
                anim = animator:LoadAnimation(animation)
            end
            anim:Play()
            anim:AdjustSpeed(0.7)
            anim.TimePosition = 0.6
            task.wait(0.1)
            while doing and anim and anim.TimePosition < 0.7 do task.wait(0.05) end
            if anim then anim:Stop(); anim:Destroy(); anim = nil end
        end
    end)

    local function StopAnim()
        doing = false
        if anim then anim:Stop(); anim:Destroy(); anim = nil end
    end

    jerk.Unequipped:Connect(StopAnim)
    local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
    if hum then hum.Died:Connect(StopAnim) end

    respawn = plr.CharacterAdded:Connect(function(char)
        local ff = char:FindFirstChildOfClass("ForceField")
        if ff then ff.AncestryChanged:Wait() end
        RemoveTool()
        CreateTool()
    end)
end

RemoveTool = function()
    if jerk then
        jerk:Destroy()
        jerk = nil
    end
    local existing = workspace:FindFirstChild("aaa")
    if existing then existing:Destroy() end
    if respawn then
        respawn:Disconnect()
        respawn = nil
    end
end

local tab = api:GetTab("extra");
local troll = tabs.lua:AddLeftGroupbox("troll");

troll:AddToggle("jerk_toggle", {
    Text = "jerk tool", Default = false,
    Callback = function(state)
        if state then CreateTool() else RemoveTool() end
    end;
})
local words = {
    "where are you aiming at?",
    "sonned",
    "bad",
    "even my grandma has faster reactions",
    ":clown:",
    "gg = get good",
    "im just better",
    "my gaming chair is just better",
    "clip me",
    "skill",
    ":Skull:",
    "go play adopt me",
    "go play brookhaven",
    "omg you are so good :screm:",
    "awesome",
    "fridge",
    "do not bully pliisss :sobv:",
    "it was your lag ofc",
    "fly high",
    "*cough* *cough*",
    "son",
    "already mad?",
    "please don't report :sobv:",
    "sob harder",
    "UE on top",
    "alt + f4 for better aim",
    "Get sonned",
    "Where are you aiming? 💀",
    "You just got outplayed...",
    "Omg you're so good... said no one ever",
    "You built like Gru, but with zero braincells 💀",
    "Fly high but your aim is still low 😹",
    "Bet you've never heard of UE",
    "UE is best, sorry but its facts",
    "UE > your skills 😭",
    "UE always wins",
    "UE doesn't miss, unlike you 💀",
    "UE made me get ekittens"
}
local enabled = false
local tab = api:GetTab("extra");
local troll = tab:GetGroupbox("troll");
troll:AddToggle("trash_e", { 
    Text = "trash talk", Default = false, Tooltip = "e to trash talk" }):OnChanged(function(v)
        enabled = v
    end);
    local function SendChatMessage(message)
        if cloneref(game:GetService("TextChatService")).ChatVersion == Enum.ChatVersion.TextChatService then
            cloneref(game:GetService("TextChatService")).TextChannels.RBXGeneral:SendAsync(message)
        else
            cloneref(game:GetService("ReplicatedStorage")).DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
        end;
    end;
table.insert(framework.connections, cloneref(game:GetService("UserInputService")).InputBegan:Connect(function(input, gpe)
    if gpe or not enabled then return end
    if input.KeyCode == Enum.KeyCode.E then
        local msg = words[math.random(1, #words)]
        SendChatMessage(msg)
    end;
end));

local tab = api:GetTab("extra");
local troll = tab:GetGroupbox("troll");
troll:AddToggle("anti_rpg", {
    Text = "anti rpg", Default = false; }):OnChanged(function(v)
    framework.RPGActive = v
end);
local function find_first_child(obj, name)
    return obj and obj:FindFirstChild(name)
end

local function GetLauncher()
    return find_first_child(workspace, "Ignored")
    and find_first_child(workspace.Ignored, "Model")
    and find_first_child(workspace.Ignored.Model, "Launcher")
end;
local function IsLauncherNear()
    local HRP = LocalPlayer.Character and find_first_child(LocalPlayer.Character, "HumanoidRootPart")
    local Launcher = GetLauncher()
    if not HRP or not Launcher then return false end
    return (Launcher.Position - HRP.Position).Magnitude < 20
end;

local position = nil;
local void = false;
local unvoid = false;
local function VoidCharacter()
    if unvoid then return end
    unvoid = true;
    
    local char = LocalPlayer.Character
    local hrp = char and find_first_child(char, "HumanoidRootPart")
    if not hrp then return end

    position = hrp.CFrame
    hrp.CFrame = CFrame.new(0, -10000, 0)
    void = true;
    
    task.delay(1, function()
        if char and char:FindFirstChild("HumanoidRootPart") and position then
            char.HumanoidRootPart.CFrame = position
        end;
        void = false;
        task.delay(0.5, function()
            unvoid = false;
        end);
    end);
end;

table.insert(framework.connections, cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
    if not framework.antiRpgActive then return end
    if IsLauncherNear() and not void then
        VoidCharacter()
    end;
end));

local died = nil
local savedpos

local function flashback()
    if not game.Players.LocalPlayer.Character then return end
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if hum and hrp then
        hum.Died:Connect(function()
            died = hrp.Position
        end)
    end
end

if game.Players.LocalPlayer.Character then
    task.spawn(flashback)
end

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    flashback()
end)

do
    local tab = api:GetTab("extra");
    local teleports = tabs.lua:AddLeftGroupbox("teleports");
    teleports:AddButton("save position", function()
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            savedpos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
            api:notify("position updated", 2);
        end
    end);
end;

local tab = api:GetTab("extra");
local teleports = tab:GetGroupbox("teleports");
teleports:AddButton("teleport to last saved position", function()
    if savedpos then
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = savedpos
        end;
    else
        api:notify("no saved position", 2);
    end;
end);

local tab = api:GetTab("extra");
local teleports = tab:GetGroupbox("teleports");
teleports:AddButton("flashback", function()
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and died then
        hrp.CFrame = CFrame.new(died + Vector3.new(0, 5, 0))
    end;
end);

local enabled = true
local Position = {}

local tab = api:GetTab("extra")
local teleports = tab:GetGroupbox("teleports")
teleports:AddToggle("t_teleport", {
    Text = "teleport to target",
    Tooltip = "j to teleport rightshift to tp back",
    Default = false,
}):OnChanged(function(value)
    enabled = value
end)

table.insert(framework.connections, cloneref(game:GetService("UserInputService")).InputBegan:Connect(function(input, gpe)
    if gpe or not enabled then return end

    if input.KeyCode == Enum.KeyCode.J then
        local target = api:get_target("silent") and api:get_target("aimbot")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = target.Character.HumanoidRootPart
            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(Position, game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame)
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame
            end
        end
    
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        if #Position > 0 and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local lastPos = table.remove(Position)
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = lastPos
        end
    end
end))

local tab = api:GetTab("extra");
local visual = tabs.lua:AddLeftGroupbox("visuals")
    framework.elements.enabled = visual:AddToggle("target_hud_enabled", {
    Text = "target hud",
    Tooltip = "fps drops for bad devices",
    Default = false
})

framework.elements.opacity = visual:AddSlider("target_hud_opacity", {
    Text = "hud ppacity",
    Default = 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Suffix = "%"
})

local Players = cloneref(game:GetService("Players"));

function framework:CreateUI()
    if self.ui.screenGui then
        self.ui.screenGui:Destroy()
        table.clear(self.ui)
    end

self.ui.screenGui = Instance.new("ScreenGui")
self.ui.screenGui.Name = "TargetHUD"
self.ui.screenGui.ResetOnSpawn = false
self.ui.screenGui.Parent = game:GetService("CoreGui")

self.ui.mainFrame = Instance.new("Frame")
self.ui.mainFrame.Size = UDim2.new(0, 320, 0, 160)
self.ui.mainFrame.Position = UDim2.new(0.5, -160, 0.8, -80)
self.ui.mainFrame.BackgroundColor3 = Color3.fromRGB(20, 35, 40)
self.ui.mainFrame.BorderSizePixel = 0
self.ui.mainFrame.Visible = false
self.ui.mainFrame.Parent = self.ui.screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 0)
mainCorner.Parent = self.ui.mainFrame

local mainOutline = Instance.new("UIStroke")
mainOutline.Color = Color3.fromRGB(10, 20, 25)
mainOutline.Thickness = 2
mainOutline.Parent = self.ui.mainFrame

self.ui.avatarFrame = Instance.new("Frame")
self.ui.avatarFrame.Size = UDim2.new(0, 64, 0, 64)
self.ui.avatarFrame.Position = UDim2.new(0, 12, 0, 12)
self.ui.avatarFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 30)
self.ui.avatarFrame.BorderSizePixel = 0
self.ui.avatarFrame.Parent = self.ui.mainFrame

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(0, 6)
avatarCorner.Parent = self.ui.avatarFrame

local avatarOutline = Instance.new("UIStroke")
avatarOutline.Color = Color3.fromRGB(20, 40, 50)
avatarOutline.Thickness = 2
avatarOutline.Parent = self.ui.avatarFrame

self.ui.avatarImage = Instance.new("ImageLabel")
self.ui.avatarImage.Size = UDim2.new(1, -6, 1, -6)
self.ui.avatarImage.Position = UDim2.new(0, 3, 0, 3)
self.ui.avatarImage.BackgroundTransparency = 1
self.ui.avatarImage.Image = "rbxassetid://0"
self.ui.avatarImage.Parent = self.ui.avatarFrame

self.ui.textContainer = Instance.new("Frame")
self.ui.textContainer.Size = UDim2.new(0, 220, 0, 90)
self.ui.textContainer.Position = UDim2.new(0, 88, 0, 12)
self.ui.textContainer.BackgroundTransparency = 1
self.ui.textContainer.Parent = self.ui.mainFrame

self.ui.nameLabel = Instance.new("TextLabel")
self.ui.nameLabel.Size = UDim2.new(1, -4, 0, 24)
self.ui.nameLabel.Font = Enum.Font.GothamBold
self.ui.nameLabel.TextSize = 18
self.ui.nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
self.ui.nameLabel.TextXAlignment = Enum.TextXAlignment.Left
self.ui.nameLabel.BackgroundTransparency = 1
self.ui.nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
self.ui.nameLabel.Parent = self.ui.textContainer

local nameOutline = Instance.new("UIStroke")
nameOutline.Color = Color3.fromRGB(0, 0, 0)
nameOutline.Thickness = 1
nameOutline.Parent = self.ui.nameLabel

self.ui.usernameLabel = Instance.new("TextLabel")
self.ui.usernameLabel.Size = UDim2.new(1, -4, 0, 20)
self.ui.usernameLabel.Position = UDim2.new(0, 0, 0, 26)
self.ui.usernameLabel.Font = Enum.Font.GothamBold
self.ui.usernameLabel.TextSize = 14
self.ui.usernameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
self.ui.usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
self.ui.usernameLabel.BackgroundTransparency = 1
self.ui.usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
self.ui.usernameLabel.Parent = self.ui.textContainer

local userOutline = Instance.new("UIStroke")
userOutline.Color = Color3.fromRGB(0, 0, 0)
userOutline.Thickness = 1
userOutline.Transparency = 0.5
userOutline.Parent = self.ui.usernameLabel

self.ui.toolLabel = Instance.new("TextLabel")
self.ui.toolLabel.Size = UDim2.new(1, -24, 0, 18)
self.ui.toolLabel.Position = UDim2.new(0, 12, 0, 84)
self.ui.toolLabel.Font = Enum.Font.GothamBold
self.ui.toolLabel.TextSize = 12
self.ui.toolLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
self.ui.toolLabel.TextXAlignment = Enum.TextXAlignment.Left
self.ui.toolLabel.BackgroundTransparency = 1
self.ui.toolLabel.TextTruncate = Enum.TextTruncate.AtEnd
self.ui.toolLabel.Text = "Tool: None"
self.ui.toolLabel.Parent = self.ui.mainFrame

self.ui.healthContainer = Instance.new("Frame")
self.ui.healthContainer.Size = UDim2.new(1, -24, 0, 24)
self.ui.healthContainer.Position = UDim2.new(0, 12, 0, 104)
self.ui.healthContainer.BackgroundColor3 = Color3.fromRGB(15, 25, 30)
self.ui.healthContainer.Parent = self.ui.mainFrame

local healthContainerCorner = Instance.new("UICorner")
healthContainerCorner.CornerRadius = UDim.new(0, 4)
healthContainerCorner.Parent = self.ui.healthContainer

local healthContainerOutline = Instance.new("UIStroke")
healthContainerOutline.Color = Color3.fromRGB(30, 50, 60)
healthContainerOutline.Thickness = 1
healthContainerOutline.Parent = self.ui.healthContainer

self.ui.healthBar = Instance.new("Frame")
self.ui.healthBar.Size = UDim2.new(0, 0, 1, 0)
self.ui.healthBar.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
self.ui.healthBar.BorderSizePixel = 0
self.ui.healthBar.Parent = self.ui.healthContainer

local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(0, 4)
healthBarCorner.Parent = self.ui.healthBar

local healthBarOutline = Instance.new("UIStroke")
healthBarOutline.Color = Color3.fromRGB(120, 20, 20)
healthBarOutline.Thickness = 1
healthBarOutline.Parent = self.ui.healthBar

self.ui.healthText = Instance.new("TextLabel")
self.ui.healthText.Size = UDim2.new(1, 0, 1, 0)
self.ui.healthText.Font = Enum.Font.GothamBold
self.ui.healthText.TextSize = 12
self.ui.healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
self.ui.healthText.BackgroundTransparency = 1
self.ui.healthText.TextXAlignment = Enum.TextXAlignment.Center
self.ui.healthText.TextYAlignment = Enum.TextYAlignment.Center
self.ui.healthText.Parent = self.ui.healthContainer

self.ui.armorContainer = Instance.new("Frame")
self.ui.armorContainer.Size = UDim2.new(1, -24, 0, 24)
self.ui.armorContainer.Position = UDim2.new(0, 12, 0, 132)
self.ui.armorContainer.BackgroundColor3 = Color3.fromRGB(15, 25, 30)
self.ui.armorContainer.Parent = self.ui.mainFrame

local armorContainerCorner = Instance.new("UICorner")
armorContainerCorner.CornerRadius = UDim.new(0, 4)
armorContainerCorner.Parent = self.ui.armorContainer

local armorContainerOutline = Instance.new("UIStroke")
armorContainerOutline.Color = Color3.fromRGB(30, 50, 60)
armorContainerOutline.Thickness = 1
armorContainerOutline.Parent = self.ui.armorContainer

self.ui.armorBar = Instance.new("Frame")
self.ui.armorBar.Size = UDim2.new(0, 0, 1, 0)
self.ui.armorBar.BackgroundColor3 = Color3.fromRGB(0, 100, 130)
self.ui.armorBar.BorderSizePixel = 0
self.ui.armorBar.Parent = self.ui.armorContainer

local armorBarCorner = Instance.new("UICorner")
armorBarCorner.CornerRadius = UDim.new(0, 4)
armorBarCorner.Parent = self.ui.armorBar

local armorBarOutline = Instance.new("UIStroke")
armorBarOutline.Color = Color3.fromRGB(0, 75, 100)
armorBarOutline.Thickness = 1
armorBarOutline.Parent = self.ui.armorBar

self.ui.armorText = Instance.new("TextLabel")
self.ui.armorText.Size = UDim2.new(1, 0, 1, 0)
self.ui.armorText.Font = Enum.Font.GothamBold
self.ui.armorText.TextSize = 12
self.ui.armorText.TextColor3 = Color3.fromRGB(255, 255, 255)
self.ui.armorText.BackgroundTransparency = 1
self.ui.armorText.TextXAlignment = Enum.TextXAlignment.Center
self.ui.armorText.TextYAlignment = Enum.TextYAlignment.Center
self.ui.armorText.Parent = self.ui.armorContainer
end

function framework:GetEquippedTool(target)
    if not target then return "None" end
    
    local character = target.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then return tool.Name end
    end
    
    local backpack = target:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                return item.Name
            end
        end
    end
    
    return "None"
end

function framework:UpdateTarget()
    if not self.ui.mainFrame then return end

    local target = api:get_target("silent");
    local enabled = self.elements.enabled.Value
    local opacity = self.elements.opacity.Value / 100

    self.ui.mainFrame.Visible = enabled and target ~= nil
    self.ui.mainFrame.BackgroundTransparency = 1 - opacity

    if target and target:IsA("Player") then
        if self.ui.avatarImage then
            pcall(function()
                self.ui.avatarImage.Image = Players:GetUserThumbnailAsync(
                    target.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size420x420
                )
            end)
        end

        if self.ui.nameLabel then
            self.ui.nameLabel.Text = string.sub(target.DisplayName, 1, 20)
        end
        if self.ui.usernameLabel then
            self.ui.usernameLabel.Text = "@"..string.sub(target.Name, 1, 15)
        end
        if self.ui.toolLabel then
            self.ui.toolLabel.Text = "Tool: "..self:GetEquippedTool(target)
        end

        if target.Character then
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
            local bodyEffects = target.Character:FindFirstChild("BodyEffects")

            if humanoid and self.ui.healthBar and self.ui.healthText then
                local health = math.floor(humanoid.Health)
                local maxHealth = math.floor(humanoid.MaxHealth)
                local healthRatio = math.clamp(health / math.max(maxHealth, 1), 0, 1)
                
                self.ui.healthBar.Size = UDim2.new(healthRatio, 0, 1, 0)
                self.ui.healthText.Text = string.format("%d/%d HP", health, maxHealth)
            end

            if bodyEffects and self.ui.armorBar and self.ui.armorText then
                local armor = math.floor(bodyEffects.Armor.Value or 0)
                local armorRatio = math.clamp(armor / 100, 0, 1)
                
                self.ui.armorBar.Size = UDim2.new(armorRatio, 0, 1, 0)
                self.ui.armorText.Text = string.format("%03d Armor", armor) 
            end
        end
    else
        if self.ui.healthBar then self.ui.healthBar.Size = UDim2.new(0, 0, 1, 0) end
        if self.ui.armorBar then self.ui.armorBar.Size = UDim2.new(0, 0, 1, 0) end
        if self.ui.healthText then self.ui.healthText.Text = "0/0 HP" end
        if self.ui.armorText then self.ui.armorText.Text = "0 Armor" end
        if self.ui.toolLabel then self.ui.toolLabel.Text = "Tool: None" end
    end
end

function framework:Init()
    pcall(function()
        self:CreateUI()
        table.insert(self.connections, cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
            self:UpdateTarget()
        end));
    end);
end;

do
    local tab = api:GetTab("extra");
    local sort = tabs.lua:AddRightGroupbox("inventory sorter");
    sort:AddToggle("sort_toggle", {
    Text = "inventory sorter",
    Tooltip = "will now be used 😁👍",
    Default = false,
    Callback = function()
        local toggle = Toggles.sort_toggle
        if not toggle then return end

        local keybind = Options.sort_keybind
        if keybind then
            keybind.NoUI = not toggle.Value
        end
    end
}):AddKeyPicker("sort_keybind", {
        Default = "I",
        Mode = "Hold",
        Text = "sort inventory",
        NoUI = false
    })
    
Options.sort_keybind.NoUI = true

    local Weapons = {
        "(Empty)",
        
        "[Double-Barrel SG]", "[TacticalShotgun]", "[Drum-Shotgun]", "[Shotgun]",
        "[Glock]", "[Revolver]", "[Flintlock]", "[Silencer]", "[Pistol]",
        "[DrumGun]", "[SMG]", "[P90]", "[Phone]", "[Wallet]",
        "[Rifle]", "[AUG]", "[SilencerAR]", "[AR]", "[AK-47]",
        "[LMG]", "[Flamethrower]", "[GrenadeLauncher]", "[RPG]",
        "[Knife]", "[Food]", "[Grenade]", "[Flashbang]", "[Whip]"
    }

    for i = 1, 10 do
        sort:AddDropdown("gun_sort_slot_" .. i, {
            Values = Weapons,
            Default = 1,
            Multi = false,
            Text = "slot " .. i
        })
    end

    local InputConnection

    local function IsFood(name)
        name = string.lower(name)
        return name:find("hamburger") or name:find("pizza") or name:find("chicken") or name:find("popcorn")
            or name:find("milk") or name:find("meat") or name:find("taco") or name:find("donut")
            or name:find("hotdog") or name:find("cranberry")
    end

    local function PreciseSort()
        local backpack = game.Players.LocalPlayer:FindFirstChild("Backpack")
        if not backpack then return end

        local tools = {}
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then table.insert(tools, item) end
        end

        local temp = Instance.new("Folder")
        temp.Name = "TempInventory"
        temp.Parent = workspace
        for _, tool in ipairs(tools) do tool.Parent = temp end
        task.wait(0.2)

        local used, slotList = {}, {}
        for i = 1, 10 do
            local v = Options["gun_sort_slot_" .. i] and Options["gun_sort_slot_" .. i].Value
            slotList[i] = v and v ~= "(Empty)" and string.lower(v) or nil
        end

        for _, name in ipairs(slotList) do
            for _, tool in ipairs(tools) do
                if tool.Parent == temp and not used[tool] then
                    local lname = string.lower(tool.Name)
                    local match = name == "[food]" and IsFood(lname) or lname == name
                    if match then
                        tool.Parent = backpack
                        used[tool] = true
                        break
                    end
                end
            end
        end

        for _, tool in ipairs(tools) do
            if tool.Parent == temp then
                tool.Parent = backpack
            end
        end

        temp:Destroy()
    end

    Toggles.sort_toggle:OnChanged(function(state)
        if InputConnection then InputConnection:Disconnect() InputConnection = nil end
        if state then
            InputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
                if processed then return end
                local key = Options.sort_keybind
                if key and key:GetState() then
                    PreciseSort()
                end
            end)
            table.insert(framework.connections, InputConnection)
        end
    end)
end

local tab = api:GetTab("extra");
local character = tabs.lua:AddRightGroupbox("character");

character:AddToggle("char_spin", {
    Text = "character spin", Default = false,
    Callback = function()
        local toggle = Toggles.char_spin
        if not toggle then return end
        
        local keybind = Options.char_spin_keybind
        if keybind then
            keybind.NoUI = not toggle.Value
        end;
    end;
}):AddKeyPicker("char_spin_keybind", {
    Default = "LeftAlt",
    Mode = "Toggle",
    Text = "character spin",
    NoUI = false,
    Callback = function()
        local mode = Options.char_spin_keybind.Mode
        if mode == "Toggle" and Toggles.char_spin.Value then
            framework.spinning = not framework.spinning
        end
    end
});
character:AddSlider("spin_speed", {
    Text = "spin speed",
    Default = 50,
    Min = 1,
    Max = 50,
    Rounding = 0
});

table.insert(framework.connections, cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
    if not Toggles.char_spin.Value then
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.AutoRotate = true
        end;
        return
    end;

    local KeybindMode = Options.char_spin_keybind
    local active = false

    if KeybindMode.Mode == "Always" then
        active = true
    elseif KeybindMode.Mode == "Hold" then
        active = KeybindMode:GetState()
    elseif KeybindMode.Mode == "Toggle" then
        active = framework.spinning
    end;

    if not active then
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.AutoRotate = true
        end;
        return
    end;
    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    game.Players.LocalPlayer.Character.Humanoid.AutoRotate = false
    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Options.spin_speed.Value), 0)
end));


local tab = api:GetTab("extra");
local character = tab:GetGroupbox("character");
local AntiSit = character:AddToggle("anti_sit", {
    Text = "anti sit", Default = false,
})

AntiSit:OnChanged(function()
    framework.antisitinactive = AntiSit.Value
end)

table.insert(framework.connections, cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
    if not framework.antisitinactive then return end
    if not game.Players.LocalPlayer.Character then return end

    local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if humanoid:GetState() == Enum.HumanoidStateType.Seated then
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end;
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
end));

table.insert(framework.connections, cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
    if not framework.antisitinactive then
        if not game.Players.LocalPlayer.Character then return end
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if not humanoid then return end
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    end;
end));

local tab = api:GetTab("extra");
local character = tab:GetGroupbox("character");
character:AddToggle("no_jump_cd", {
    Text = "no jump cooldown", Default = false,
})

table.insert(framework.connections, cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
    local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if Toggles.no_jump_cd and Toggles.no_jump_cd.Value then
            if hum.UseJumpPower ~= false then
                hum.UseJumpPower = false 
            end;
        else
            if hum.UseJumpPower ~= true then
                hum.UseJumpPower = true 
            end;
        end;
    end;
end));

local tab = api:GetTab("extra");
local character = tab:GetGroupbox("character");
character:AddButton("animation pack", function()
    
    repeat
        wait()
    until game:IsLoaded()
    and game.Players.LocalPlayer.Character:FindFirstChild("FULLY_LOADED_CHAR")
    and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack")
    and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")
    
    local Animations = game.ReplicatedStorage:WaitForChild("ClientAnimations")

    local anims = {
        "Lean", "Lay", "Dance1", "Dance2", "Greet", "Chest Pump", "Praying",
        "TheDefault", "Sturdy", "Rossy", "Griddy", "TPose", "SpeedBlitz"
    }
    for _, name in ipairs(anims) do
        local a = Animations:FindFirstChild(name)
        if a then a:Destroy() end
    end

    local function NewAnim(name, id)
        local a = Instance.new("Animation", Animations)
        a.Name = name
        a.AnimationId = "rbxassetid://" .. id
        return a
    end

    local LeanAnimation = NewAnim("Lean", "3152375249")
    local LayAnimation = NewAnim("Lay", "3152378852")
    local Dance1Animation = NewAnim("Dance1", "3189773368")
    local Dance2Animation = NewAnim("Dance2", "3189776546")
    local GreetAnimation = NewAnim("Greet", "3189777795")
    local ChestPumpAnimation = NewAnim("Chest Pump", "3189779152")
    local PrayingAnimation = NewAnim("Praying", "3487719500")
    local TheDefaultAnimation = NewAnim("TheDefault", "11710529975")
    local SturdyAnimation = NewAnim("Sturdy", "11710524717")
    local RossyAnimation = NewAnim("Rossy", "11710527244")
    local GriddyAnimation = NewAnim("Griddy", "11710529220")
    local TPoseAnimation = NewAnim("TPose", "11710524200")
    local SpeedBlitzAnimation = NewAnim("SpeedBlitz", "11710541744")

    function AnimationPack(Character)
        Character:WaitForChild("Humanoid")
        repeat wait() until Character:FindFirstChild("FULLY_LOADED_CHAR")
            and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack")
            and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")

        local Player = game.Players.LocalPlayer
        local Humanoid = Character.Humanoid
        local AnimationPack = Player.PlayerGui.MainScreenGui.AnimationPack
        local AnimationPackPlus = Player.PlayerGui.MainScreenGui.AnimationPlusPack
        local ScrollingFrame = AnimationPack.ScrollingFrame
        local CloseButton = AnimationPack.CloseButton
        local ScrollingFramePlus = AnimationPackPlus.ScrollingFrame
        local CloseButtonPlus = AnimationPackPlus.CloseButton

        local Animator = Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", Humanoid)

        local animations = {
            Lean = Humanoid:LoadAnimation(LeanAnimation),
            Lay = Humanoid:LoadAnimation(LayAnimation),
            Dance1 = Humanoid:LoadAnimation(Dance1Animation),
            Dance2 = Humanoid:LoadAnimation(Dance2Animation),
            Greet = Humanoid:LoadAnimation(GreetAnimation),
            ChestPump = Humanoid:LoadAnimation(ChestPumpAnimation),
            Praying = Humanoid:LoadAnimation(PrayingAnimation),
            TheDefault = Humanoid:LoadAnimation(TheDefaultAnimation),
            Sturdy = Humanoid:LoadAnimation(SturdyAnimation),
            Rossy = Humanoid:LoadAnimation(RossyAnimation),
            Griddy = Humanoid:LoadAnimation(GriddyAnimation),
            TPose = Humanoid:LoadAnimation(TPoseAnimation),
            SpeedBlitz = Humanoid:LoadAnimation(SpeedBlitzAnimation)
        }

        AnimationPack.Visible = true
        AnimationPackPlus.Visible = true
        ScrollingFrame.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ScrollingFramePlus.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local function RenameButtons(frame, RenameMap)
            for _, btn in pairs(frame:GetChildren()) do
                if btn:IsA("TextButton") and RenameMap[btn.Text] then
                    btn.Name = RenameMap[btn.Text]
                end
            end
        end

        RenameButtons(ScrollingFrame, {
            ["Lean"] = "LeanButton",
            ["Lay"] = "LayButton",
            ["Dance1"] = "Dance1Button",
            ["Dance2"] = "Dance2Button",
            ["Greet"] = "GreetButton",
            ["Chest Pump"] = "ChestPumpButton",
            ["Praying"] = "PrayingButton",
        })

        RenameButtons(ScrollingFramePlus, {
            ["The Default"] = "TheDefaultButton",
            ["Sturdy"] = "SturdyButton",
            ["Rossy"] = "RossyButton",
            ["Griddy"] = "GriddyButton",
            ["T Pose"] = "TPoseButton",
            ["Speed Blitz"] = "SpeedBlitzButton",
        })

        local function StopAll()
            for _, anim in pairs(animations) do anim:Stop() end
        end

        local function ConnectButton(ButtonName, AnimKey, parent)
            local btn = parent:FindFirstChild(ButtonName)
            if btn then
                btn.MouseButton1Click:Connect(function()
                    StopAll()
                    animations[AnimKey]:Play()
                end)
            end
        end

        ConnectButton("LeanButton", "Lean", ScrollingFrame)
        ConnectButton("LayButton", "Lay", ScrollingFrame)
        ConnectButton("Dance1Button", "Dance1", ScrollingFrame)
        ConnectButton("Dance2Button", "Dance2", ScrollingFrame)
        ConnectButton("GreetButton", "Greet", ScrollingFrame)
        ConnectButton("ChestPumpButton", "ChestPump", ScrollingFrame)
        ConnectButton("PrayingButton", "Praying", ScrollingFrame)

        ConnectButton("TheDefaultButton", "TheDefault", ScrollingFramePlus)
        ConnectButton("SturdyButton", "Sturdy", ScrollingFramePlus)
        ConnectButton("RossyButton", "Rossy", ScrollingFramePlus)
        ConnectButton("GriddyButton", "Griddy", ScrollingFramePlus)
        ConnectButton("TPoseButton", "TPose", ScrollingFramePlus)
        ConnectButton("SpeedBlitzButton", "SpeedBlitz", ScrollingFramePlus)

        AnimationPack.MouseButton1Click:Connect(function()
            ScrollingFrame.Visible = true
            CloseButton.Visible = true
            AnimationPackPlus.Visible = false
        end)

        AnimationPackPlus.MouseButton1Click:Connect(function()
            ScrollingFramePlus.Visible = true
            CloseButtonPlus.Visible = true
            AnimationPack.Visible = false
        end)

        CloseButton.MouseButton1Click:Connect(function()
            ScrollingFrame.Visible = false
            CloseButton.Visible = false
            AnimationPackPlus.Visible = true
        end)

        CloseButtonPlus.MouseButton1Click:Connect(function()
            ScrollingFramePlus.Visible = false
            CloseButtonPlus.Visible = false
            AnimationPack.Visible = true
        end)

        Humanoid.Running:Connect(StopAll)
        game.Players.LocalPlayer.CharacterAdded:Connect(StopAll)
    end

    AnimationPack(game.Players.LocalPlayer.Character)
    game.Players.LocalPlayer.CharacterAdded:Connect(AnimationPack)

end)

local tab = api:GetTab("extra");
local character = tab:GetGroupbox("character");
character:AddButton("R6 force", function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    RunCustomAnimation(character)
end)
	
function RunCustomAnimation(Char)
	if Char:WaitForChild("Animate") ~= nil then
		Char.Animate.Disabled = true
	end
	
	Char:WaitForChild("Humanoid")

	for i,v in next, Char.Humanoid:GetPlayingAnimationTracks() do
		v:Stop()
	end

	local script = Char.Animate

	local Character = Char
	local Humanoid = Character:WaitForChild("Humanoid")
	local pose = "Standing"

	local UserGameSettings = UserSettings():GetService("UserGameSettings")

	local userNoUpdateOnLoopSuccess, userNoUpdateOnLoopValue = pcall(function() return UserSettings():IsUserFeatureEnabled("UserNoUpdateOnLoop") end)
	local userNoUpdateOnLoop = userNoUpdateOnLoopSuccess and userNoUpdateOnLoopValue

	local AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
	local HumanoidHipHeight = 2

	local humanoidSpeed = 0 
	local cachedRunningSpeed = 0 
	local cachedLocalDirection = {x=0.0, y=0.0} 
	local smallButNotZero = 0.0001 
	local runBlendtime = 0.2
	local lastLookVector = Vector3.new(0.0, 0.0, 0.0) 
	local lastBlendTime = 0 
	local WALK_SPEED = 6.4
	local RUN_SPEED = 12.8

	local EMOTE_TRANSITION_TIME = 0.1

	local currentAnim = ""
	local currentAnimInstance = nil
	local currentAnimTrack = nil
	local currentAnimKeyframeHandler = nil
	local currentAnimSpeed = 1.0

	local PreloadedAnims = {}

	local animTable = {}
	local animNames = { 
		idle = 	{
			{ id = "http://www.roblox.com/asset/?id=12521158637", weight = 9 },
			{ id = "http://www.roblox.com/asset/?id=12521162526", weight = 1 },
		},
		walk = 	{
			{ id = "http://www.roblox.com/asset/?id=12518152696", weight = 10 }
		},
		run = 	{
			{ id = "http://www.roblox.com/asset/?id=12518152696", weight = 10 } 
		},
		jump = 	{
			{ id = "http://www.roblox.com/asset/?id=12520880485", weight = 10 }
		},
		fall = 	{
			{ id = "http://www.roblox.com/asset/?id=12520972571", weight = 10 }
		},
		climb = {
			{ id = "http://www.roblox.com/asset/?id=12520982150", weight = 10 }
		},
		sit = 	{
			{ id = "http://www.roblox.com/asset/?id=12520993168", weight = 10 }
		},
		toolnone = {
			{ id = "http://www.roblox.com/asset/?id=12520996634", weight = 10 }
		},
		toolslash = {
			{ id = "http://www.roblox.com/asset/?id=12520999032", weight = 10 }
		},
		toollunge = {
			{ id = "http://www.roblox.com/asset/?id=12521002003", weight = 10 }
		},
		wave = {
			{ id = "http://www.roblox.com/asset/?id=12521004586", weight = 10 }
		},
		point = {
			{ id = "http://www.roblox.com/asset/?id=12521007694", weight = 10 }
		},
		dance = {
			{ id = "http://www.roblox.com/asset/?id=12521009666", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521151637", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521015053", weight = 10 }
		},
		dance2 = {
			{ id = "http://www.roblox.com/asset/?id=12521169800", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521173533", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521027874", weight = 10 }
		},
		dance3 = {
			{ id = "http://www.roblox.com/asset/?id=12521178362", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521181508", weight = 10 },
			{ id = "http://www.roblox.com/asset/?id=12521184133", weight = 10 }
		},
		laugh = {
			{ id = "http://www.roblox.com/asset/?id=12521018724", weight = 10 }
		},
		cheer = {
			{ id = "http://www.roblox.com/asset/?id=12521021991", weight = 10 }
		},
	}


	local strafingLocomotionMap = {}
	local fallbackLocomotionMap = {}
	local locomotionMap = strafingLocomotionMap
	local emoteNames = { wave = false, point = false, dance = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

	math.randomseed(tick())

	function findExistingAnimationInSet(set, anim)
		if set == nil or anim == nil then
			return 0
		end;

		for idx = 1, set.count, 1 do
			if set[idx].anim.AnimationId == anim.AnimationId then
				return idx
			end;
		end;

		return 0
	end;

	function configureAnimationSet(name, fileList)
		if (animTable[name] ~= nil) then
			for _, connection in pairs(animTable[name].connections) do
				connection:disconnect()
			end;
		end;
		animTable[name] = {}
		animTable[name].count = 0
		animTable[name].totalWeight = 0
		animTable[name].connections = {}

		if name == "run" or name == "walk" then
			local speed = name == "run" and RUN_SPEED or WALK_SPEED
			fallbackLocomotionMap[name] = {lv=Vector2.new(0.0, speed), speed = speed}
			locomotionMap = fallbackLocomotionMap
			end;


		if (animTable[name].count <= 0) then
			for idx, anim in pairs(fileList) do
				animTable[name][idx] = {}
				animTable[name][idx].anim = Instance.new("Animation")
				animTable[name][idx].anim.Name = name
				animTable[name][idx].anim.AnimationId = anim.id
				animTable[name][idx].weight = anim.weight
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
			end;
		end;

		for i, animType in pairs(animTable) do
			for idx = 1, animType.count, 1 do
				if PreloadedAnims[animType[idx].anim.AnimationId] == nil then
					Humanoid:LoadAnimation(animType[idx].anim)
					PreloadedAnims[animType[idx].anim.AnimationId] = true
				end;
			end;
		end;
	end;

	function scriptChildModified(child)
		local fileList = animNames[child.Name]
		if (fileList ~= nil) then
			configureAnimationSet(child.Name, fileList)
		else
			if child:isA("StringValue") then
				animNames[child.Name] = {}
				configureAnimationSet(child.Name, animNames[child.Name])
			end;
		end;
	end;

	script.ChildAdded:connect(scriptChildModified)
	script.ChildRemoved:connect(scriptChildModified)

	local animator = if Humanoid then Humanoid:FindFirstChildOfClass("Animator") else nil
	if animator then
		local animTracks = animator:GetPlayingAnimationTracks()
		for i,track in ipairs(animTracks) do
			track:Stop(0)
			track:Destroy()
		end;
	end;

	for name, fileList in pairs(animNames) do
		configureAnimationSet(name, fileList)
	end;
	for _,child in script:GetChildren() do
		if child:isA("StringValue") and not animNames[child.name] then
			animNames[child.Name] = {}
			configureAnimationSet(child.Name, animNames[child.Name])
		end;
	end;

	local toolAnim = "None"
	local toolAnimTime = 0

	local jumpAnimTime = 0
	local jumpAnimDuration = 0.31

	local toolTransitionTime = 0.1
	local fallTransitionTime = 0.2

	local currentlyPlayingEmote = false

	function stopAllAnimations()
		local oldAnim = currentAnim

		if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
			oldAnim = "idle"
		end;

		if currentlyPlayingEmote then
			oldAnim = "idle"
			currentlyPlayingEmote = false
		end;

		currentAnim = ""
		currentAnimInstance = nil
		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end;

		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop()
			currentAnimTrack:Destroy()
			currentAnimTrack = nil
		end;

		for _,v in pairs(locomotionMap) do
			if v.track then
				v.track:Stop()
				v.track:Destroy()
				v.track = nil
			end;
		end;

		return oldAnim
	end;

	function getHeightScale()
		if Humanoid then
			if not Humanoid.AutomaticScalingEnabled then
				return 1
			end;

			local scale = Humanoid.HipHeight / HumanoidHipHeight
			if AnimationSpeedDampeningObject == nil then
				AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
			end;
			if AnimationSpeedDampeningObject ~= nil then
				scale = 1 + (Humanoid.HipHeight - HumanoidHipHeight) * AnimationSpeedDampeningObject.Value / HumanoidHipHeight
			end;
			return scale
		end;
		return 1
	end;


	local function signedAngle(a, b)
		return -math.atan2(a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y)
	end;

	local angleWeight = 2.0
	local function get2DWeight(px, p1, p2, sx, s1, s2)
		local avgLength = 0.5 * (s1 + s2)

		local p_1 = {x = (sx - s1)/avgLength, y = (angleWeight * signedAngle(p1, px))}
		local p12 = {x = (s2 - s1)/avgLength, y = (angleWeight * signedAngle(p1, p2))}	
		local denom = smallButNotZero + (p12.x*p12.x + p12.y*p12.y)
		local numer = p_1.x * p12.x + p_1.y * p12.y
		local r = math.clamp(1.0 - numer/denom, 0.0, 1.0)
		return r
	end;

	local function blend2D(targetVelo, targetSpeed)
		local h = {}
		local sum = 0.0
		for n,v1 in pairs(locomotionMap) do
			if targetVelo.x * v1.lv.x < 0.0 or targetVelo.y * v1.lv.y < 0 then
				h[n] = 0.0
				continue
			end;
			h[n] = math.huge
			for j,v2 in pairs(locomotionMap) do
				if targetVelo.x * v2.lv.x < 0.0 or targetVelo.y * v2.lv.y < 0 then
					continue
				end;
				h[n] = math.min(h[n], get2DWeight(targetVelo, v1.lv, v2.lv, targetSpeed, v1.speed, v2.speed))
			end;
			sum += h[n]
		end;

		local sum2 = 0.0
		local weightedVeloX = 0
		local weightedVeloY = 0
		for n,v in pairs(locomotionMap) do

			if (h[n] / sum > 0.1) then
				sum2 += h[n]
				weightedVeloX += h[n] * v.lv.x
				weightedVeloY += h[n] * v.lv.y
			else
				h[n] = 0.0
			end;
		end;
		local animSpeed
		local weightedSpeedSquared = weightedVeloX * weightedVeloX + weightedVeloY * weightedVeloY
		if weightedSpeedSquared > smallButNotZero then
			animSpeed = math.sqrt(targetSpeed * targetSpeed / weightedSpeedSquared)
		else
			animSpeed = 0
		end;

		animSpeed = animSpeed / getHeightScale()
		local groupTimePosition = 0
		for n,v in pairs(locomotionMap) do
			if v.track.IsPlaying then
				groupTimePosition = v.track.TimePosition
				break
			end;
		end;
		for n,v in pairs(locomotionMap) do
			if h[n] > 0.0 then
				if not v.track.IsPlaying then 
					v.track:Play(runBlendtime)
					v.track.TimePosition = groupTimePosition
				end;

				local weight = math.max(smallButNotZero, h[n] / sum2)
				v.track:AdjustWeight(weight, runBlendtime)
				v.track:AdjustSpeed(animSpeed)
			else
				v.track:Stop(runBlendtime)
			end;
		end;
    end;

	local function getWalkDirection()
		local walkToPoint = Humanoid.WalkToPoint
		local walkToPart = Humanoid.WalkToPart
		if Humanoid.MoveDirection ~= Vector3.zero then
			return Humanoid.MoveDirection
		elseif walkToPart or walkToPoint ~= Vector3.zero then
			local destination
			if walkToPart then
				destination = walkToPart.CFrame:PointToWorldSpace(walkToPoint)
			else
				destination = walkToPoint
			end
			local moveVector = Vector3.zero
			if Humanoid.RootPart then
				moveVector = destination - Humanoid.RootPart.CFrame.Position
				moveVector = Vector3.new(moveVector.x, 0.0, moveVector.z)
				local mag = moveVector.Magnitude
				if mag > 0.01 then
					moveVector /= mag
				end;
			end;
			return moveVector
		else
			return Humanoid.MoveDirection
		end;
	end;

	local function updateVelocity(currentTime)

		local tempDir

		if locomotionMap == strafingLocomotionMap then

			local moveDirection = getWalkDirection()

			if not Humanoid.RootPart then
				return
			end;

			local cframe = Humanoid.RootPart.CFrame
			if math.abs(cframe.UpVector.Y) < smallButNotZero or pose ~= "Running" or humanoidSpeed < 0.001 then
				for n,v in pairs(locomotionMap) do
					if v.track then
						v.track:AdjustWeight(smallButNotZero, runBlendtime)
					end;
				end;
				return
			end;
			local lookat = cframe.LookVector
			local direction = Vector3.new(lookat.X, 0.0, lookat.Z)
			direction = direction / direction.Magnitude 
			local ly = moveDirection:Dot(direction)
			if ly <= 0.0 and ly > -0.05 then
				ly = smallButNotZero 
			end;
			local lx = direction.X*moveDirection.Z - direction.Z*moveDirection.X
			local tempDir = Vector2.new(lx, ly) 
			local delta = Vector2.new(tempDir.x-cachedLocalDirection.x, tempDir.y-cachedLocalDirection.y)
			if delta:Dot(delta) > 0.001 or math.abs(humanoidSpeed - cachedRunningSpeed) > 0.01 or currentTime - lastBlendTime > 1 then
				cachedLocalDirection = tempDir
				cachedRunningSpeed = humanoidSpeed
				lastBlendTime = currentTime
				blend2D(cachedLocalDirection, cachedRunningSpeed)
			end ;
		else
			if math.abs(humanoidSpeed - cachedRunningSpeed) > 0.01 or currentTime - lastBlendTime > 1 then
				cachedRunningSpeed = humanoidSpeed
				lastBlendTime = currentTime
				blend2D(Vector2.yAxis, cachedRunningSpeed)
			end;
		end;
	end;

	function setAnimationSpeed(speed)
		if currentAnim ~= "walk" then
			if speed ~= currentAnimSpeed then
				currentAnimSpeed = speed
				currentAnimTrack:AdjustSpeed(currentAnimSpeed)
			end;
		end;
	end;

	function keyFrameReachedFunc(frameName)
		if (frameName == "End") then
			local repeatAnim = currentAnim
			if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
				repeatAnim = "idle"
			end;

			if currentlyPlayingEmote then
				if currentAnimTrack.Looped then
					return
				end;

				repeatAnim = "idle"
				currentlyPlayingEmote = false
			end;

			local animSpeed = currentAnimSpeed
			playAnimation(repeatAnim, 0.15, Humanoid)
			setAnimationSpeed(animSpeed)
		end;
	end;

	function rollAnimation(animName)
		local roll = math.random(1, animTable[animName].totalWeight)
		local origRoll = roll
		local idx = 1
		while (roll > animTable[animName][idx].weight) do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end;
		return idx
	end;

	local maxVeloX, minVeloX, maxVeloY, minVeloY

	local function destroyRunAnimations()
		for _,v in pairs(strafingLocomotionMap) do
			if v.track then
				v.track:Stop()
				v.track:Destroy()
				v.track = nil
			end;
		end;
		for _,v in pairs(fallbackLocomotionMap) do
			if v.track then
				v.track:Stop()
				v.track:Destroy()
				v.track = nil
			end;
		end;
		cachedRunningSpeed = 0
	end;

	local function resetVelocityBounds(velo)
		minVeloX = 0
		maxVeloX = 0
		minVeloY = 0
		maxVeloY = 0
	end;

	local function updateVelocityBounds(velo)
		if velo then 
			if velo.x > maxVeloX then maxVeloX = velo.x end
			if velo.y > maxVeloY then maxVeloY = velo.y end
			if velo.x < minVeloX then minVeloX = velo.x end
			if velo.y < minVeloY then minVeloY = velo.y end
		end;
	end;

	local function checkVelocityBounds(velo)
		if maxVeloX == 0 or minVeloX == 0 or maxVeloY == 0 or minVeloY == 0 then
			if locomotionMap == strafingLocomotionMap then
				warn("Strafe blending disabled.  Not all quadrants of motion represented.")
			end;
			locomotionMap = fallbackLocomotionMap
		else
			locomotionMap = strafingLocomotionMap
		end;
	end;

	local function setupWalkAnimation(anim, animName, transitionTime, humanoid)
		resetVelocityBounds()
		for n,v in pairs(locomotionMap) do
			v.track = humanoid:LoadAnimation(animTable[n][1].anim)
			v.track.Priority = Enum.AnimationPriority.Core
			updateVelocityBounds(v.lv)
		end;
		checkVelocityBounds()
	end;

	local function switchToAnim(anim, animName, transitionTime, humanoid)
				if (anim ~= currentAnimInstance) then

			if (currentAnimTrack ~= nil) then
				currentAnimTrack:Stop(transitionTime)
				currentAnimTrack:Destroy()
			end;
			if (currentAnimKeyframeHandler ~= nil) then
				currentAnimKeyframeHandler:disconnect()
			end;

			currentAnimSpeed = 1.0

			currentAnim = animName
			currentAnimInstance = anim	

			if animName == "walk" then
				setupWalkAnimation(anim, animName, transitionTime, humanoid)
			else
				destroyRunAnimations()
				currentAnimTrack = humanoid:LoadAnimation(anim)
				currentAnimTrack.Priority = Enum.AnimationPriority.Core

				currentAnimTrack:Play(transitionTime)	

				currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
			end;
		end;
	end;

	function playAnimation(animName, transitionTime, humanoid)
		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		switchToAnim(anim, animName, transitionTime, humanoid)
		currentlyPlayingEmote = false
	end;

	function playEmote(emoteAnim, transitionTime, humanoid)
		switchToAnim(emoteAnim, emoteAnim.Name, transitionTime, humanoid)
		currentlyPlayingEmote = true
	end;

	local toolAnimName = ""
	local toolAnimTrack = nil
	local toolAnimInstance = nil
	local currentToolAnimKeyframeHandler = nil

	function toolKeyFrameReachedFunc(frameName)
		if (frameName == "End") then
			playToolAnimation(toolAnimName, 0.0, Humanoid)
		end;
	end;

	function playToolAnimation(animName, transitionTime, humanoid, priority)
		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		if (toolAnimInstance ~= anim) then

			if (toolAnimTrack ~= nil) then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				transitionTime = 0
			end

			toolAnimTrack = humanoid:LoadAnimation(anim)
			if priority then
				toolAnimTrack.Priority = priority
			end

			toolAnimTrack:Play(transitionTime)
			toolAnimName = animName
			toolAnimInstance = anim

			currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
		end;
	end;

	function stopToolAnimations()
		local oldAnim = toolAnimName

		if (currentToolAnimKeyframeHandler ~= nil) then
			currentToolAnimKeyframeHandler:disconnect()
		end;

		toolAnimName = ""
		toolAnimInstance = nil
		if (toolAnimTrack ~= nil) then
			toolAnimTrack:Stop()
			toolAnimTrack:Destroy()
			toolAnimTrack = nil
		end;

		return oldAnim
	end;

	function onRunning(speed)
		local movedDuringEmote = currentlyPlayingEmote and Humanoid.MoveDirection == Vector3.new(0, 0, 0)
		local speedThreshold = movedDuringEmote and Humanoid.WalkSpeed or 0.75
		humanoidSpeed = speed
		if speed > speedThreshold then
			playAnimation("walk", 0.2, Humanoid)
			if pose ~= "Running" then
				pose = "Running"
				updateVelocity(0) 
			end;
		else
			if emoteNames[currentAnim] == nil and not currentlyPlayingEmote then
				playAnimation("idle", 0.2, Humanoid)
				pose = "Standing"
			end;
		end;
	end;

	function onDied()
		pose = "Dead"
	end;

	function onJumping()
		playAnimation("jump", 0.1, Humanoid)
		jumpAnimTime = jumpAnimDuration
		pose = "Jumping"
	end;

	function onClimbing(speed)
		local scale = 5.0
		playAnimation("climb", 0.1, Humanoid)
		setAnimationSpeed(speed / scale)
		pose = "Climbing"
	end;

	function onGettingUp()
		pose = "GettingUp"
	end;

	function onFreeFall()
		if (jumpAnimTime <= 0) then
			playAnimation("fall", fallTransitionTime, Humanoid)
		end;
		pose = "FreeFall"
	end;

	function onFallingDown()
		pose = "FallingDown"
	end;

	function onSeated()
		pose = "Seated"
	end;

	function onPlatformStanding()
		pose = "PlatformStanding"
	end;

	
	function onSwimming(speed)
		if speed > 0 then
			pose = "Running"
		else
			pose = "Standing"
		end;
	end;

	function animateTool()
		if (toolAnim == "None") then
			playToolAnimation("toolnone", toolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
			return
		end;

		if (toolAnim == "Slash") then
			playToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
			return
		end;

		if (toolAnim == "Lunge") then
			playToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
			return
		end;
	end;

	function getToolAnim(tool)
		for _, c in ipairs(tool:GetChildren()) do
			if c.Name == "toolanim" and c.className == "StringValue" then
				return c
			end;
		end;
		return nil
	end;

	local lastTick = 0

	function stepAnimate(currentTime)
		local amplitude = 1
		local frequency = 1
		local deltaTime = currentTime - lastTick
		lastTick = currentTime

		local climbFudge = 0
		local setAngles = false

		if (jumpAnimTime > 0) then
			jumpAnimTime = jumpAnimTime - deltaTime
		end;

		if (pose == "FreeFall" and jumpAnimTime <= 0) then
			playAnimation("fall", fallTransitionTime, Humanoid)
		elseif (pose == "Seated") then
			playAnimation("sit", 0.5, Humanoid)
			return
		elseif (pose == "Running") then
			playAnimation("walk", 0.2, Humanoid)
			updateVelocity(currentTime)
		elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
			stopAllAnimations()
			amplitude = 0.1
			frequency = 1
			setAngles = true
		end;

		local tool = Character:FindFirstChildOfClass("Tool")
		if tool and tool:FindFirstChild("Handle") then
			local animStringValueObject = getToolAnim(tool)

			if animStringValueObject then
				toolAnim = animStringValueObject.Value
				animStringValueObject.Parent = nil
				toolAnimTime = currentTime + .3
			end;

			if currentTime > toolAnimTime then
				toolAnimTime = 0
				toolAnim = "None"
			end;

			animateTool()
		else
			stopToolAnimations()
			toolAnim = "None"
			toolAnimInstance = nil
			toolAnimTime = 0
		end;
	end;

	Humanoid.Died:connect(onDied)
	Humanoid.Running:connect(onRunning)
	Humanoid.Jumping:connect(onJumping)
	Humanoid.Climbing:connect(onClimbing)
	Humanoid.GettingUp:connect(onGettingUp)
	Humanoid.FreeFalling:connect(onFreeFall)
	Humanoid.FallingDown:connect(onFallingDown)
	Humanoid.Seated:connect(onSeated)
	Humanoid.PlatformStanding:connect(onPlatformStanding)
	Humanoid.Swimming:connect(onSwimming)

	cloneref(game:GetService("Players")).LocalPlayer.Chatted:connect(function(msg)
		local emote = ""
		if (string.sub(msg, 1, 3) == "/e ") then
			emote = string.sub(msg, 4)
		elseif (string.sub(msg, 1, 7) == "/emote ") then
			emote = string.sub(msg, 8)
		end;

		if (pose == "Standing" and emoteNames[emote] ~= nil) then
			playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)
		end;
	end);

	script:WaitForChild("PlayEmote").OnInvoke = function(emote)
		if pose ~= "Standing" then
			return
		end

		if emoteNames[emote] ~= nil then
			playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)

			return true, currentAnimTrack
		elseif typeof(emote) == "Instance" and emote:IsA("Animation") then
			playEmote(emote, EMOTE_TRANSITION_TIME, Humanoid)

			return true, currentAnimTrack
		end

		return false
	end;

	if Character.Parent ~= nil then
		playAnimation("idle", 0.1, Humanoid)
		pose = "Standing"
	end;

	task.spawn(function()
		while Character.Parent ~= nil do
			local _, currentGameTime = wait(0.1)
			stepAnimate(currentGameTime)
		end;
	end);
end;

local tab = api:GetTab("extra");
local character = tab:GetGroupbox("character");
character:AddButton("force reset", function()
    if game.Players.LocalPlayer.Character then
        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end;
    api:Notify("reset character", 3);
end);

function api:Unload()
    for _, connection in pairs(framework.connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(framework.connections)

for _, toggle in pairs(Toggles) do
    if toggle.Name and (
        toggle.Name == "anti_sit" or
        toggle.Name == "auto_block" or
        toggle.Name == "logs_toggle" or
        toggle.Name == "anti_fling" or
        toggle.Name == "target_hud_enabled" or
        toggle.Name == "target_hud_opacity" or
        toggle.Name == "jerk_toggle" or
        toggle.Name == "trash_e" or
        toggle.Name == "anti_rpg" or
        toggle.Name == "sort_toggle" or
        toggle.Name == "char_spin" or
        toggle.Name == "no_jump_cd" or
        toggle.Name == "dhc_aura" or
        toggle.Name == "t_teleport"
    ) then
        toggle.Value = false
    end;
end;

    if Options.char_spin_keybind then
        Options.char_spin_keybind.NoUI = true
    end;

    if Options.char_multi_tool_keybind then
        Options.char_multi_tool_keybind.NoUI = true
    end;

    if Options.sort_keybind then
        Options.sort_keybind.NoUI = true
    end;

    if CollectDHC then
        CollectDHC = false
    end;

    framework.MultiToolActive = false
    framework.spinning = false
    framework.antisitinactive = false
    framework.antiFlingActive = false
    framework.RPGActive = false
    framework.IsHoldingKey = false

    if game.Players.LocalPlayer.Character then
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            if framework.spinning then humanoid.AutoRotate = true end
            if framework.antisitinactive then humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
        end
    end

    position = nil
    void = false
    unvoid = false
    IsShooting = false
    table.clear(framework.EquippedTools)
    table.clear(LastFiredTimes)

    if framework.antifling then
        for player, parts in pairs(collision) do
            if player and player.Character then
                for part, properties in pairs(parts) do
                    if part and part:IsA("BasePart") then
                        part.CanCollide = properties.CanCollide
                        if part.Name == "Torso" then part.Massless = properties.Massless end
                    end
                end
            end
        end
        table.clear(collision)
    end
end
pcall(framework.Init, framework)

return framework

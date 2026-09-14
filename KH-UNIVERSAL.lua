--[[
    Kento Hub / 総合ユーティリティ v9
    機能: スピードハック, 無限ジャンプ, カメラTP, 壁貫通, 
          視認性向上, ESP (Highlight), クロスヘア (シンプル＆クール), Fly (外部読み込み), 
          位置記憶TP, プレイヤーTP
    テーマ: オレンジ × 黒
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- ============================================
-- OrionLib 読み込み
-- ============================================
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

-- ============================================
-- 設定変数
-- ============================================
local Settings = {
    SpeedHack = false,
    SpeedValue = 50,
    InfiniteJump = false,
    Noclip = false,
    Wallhack = false,
    ESP = false,
    Fly = false,
    Crosshair = false,
    SavedPosition = nil,
}

local espHighlights = {}
local noclipConnection = nil
local flyLoaded = false
local crosshairGui = nil

-- ============================================
-- シンプル＆クールなクロスヘア
-- ============================================
local function CreateCrosshair()
    if crosshairGui then
        pcall(function() crosshairGui:Destroy() end)
        crosshairGui = nil
    end

    if not Settings.Crosshair then return end

    crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "KentoCrosshair"
    crosshairGui.ResetOnSpawn = false
    crosshairGui.IgnoreGuiInset = true
    crosshairGui.Parent = CoreGui

    local lineLength = 8
    local gap = 6
    local thickness = 1.5
    local color = Color3.fromRGB(255, 170, 0)
    local dotSize = 3

    -- メインフレーム
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = crosshairGui

    -- 中央ドット
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, dotSize, 0, dotSize)
    dot.Position = UDim2.new(0.5, -dotSize/2, 0.5, -dotSize/2)
    dot.BackgroundColor3 = color
    dot.BackgroundTransparency = 0.3
    dot.BorderSizePixel = 0
    dot.Parent = frame
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    -- 中央ドットの内側 (白)
    local innerDot = Instance.new("Frame")
    innerDot.Size = UDim2.new(0, 1.5, 0, 1.5)
    innerDot.Position = UDim2.new(0.5, -0.75, 0.5, -0.75)
    innerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    innerDot.BackgroundTransparency = 0.4
    innerDot.BorderSizePixel = 0
    innerDot.Parent = frame
    local innerDotCorner = Instance.new("UICorner")
    innerDotCorner.CornerRadius = UDim.new(1, 0)
    innerDotCorner.Parent = innerDot

    -- 上ライン
    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(0, thickness, 0, lineLength)
    topLine.Position = UDim2.new(0.5, -thickness/2, 0, -gap - lineLength)
    topLine.BackgroundColor3 = color
    topLine.BackgroundTransparency = 0.5
    topLine.BorderSizePixel = 0
    topLine.Parent = frame

    -- 下ライン
    local bottomLine = Instance.new("Frame")
    bottomLine.Size = UDim2.new(0, thickness, 0, lineLength)
    bottomLine.Position = UDim2.new(0.5, -thickness/2, 0, gap)
    bottomLine.BackgroundColor3 = color
    bottomLine.BackgroundTransparency = 0.5
    bottomLine.BorderSizePixel = 0
    bottomLine.Parent = frame

    -- 左ライン
    local leftLine = Instance.new("Frame")
    leftLine.Size = UDim2.new(0, lineLength, 0, thickness)
    leftLine.Position = UDim2.new(0, -gap - lineLength, 0.5, -thickness/2)
    leftLine.BackgroundColor3 = color
    leftLine.BackgroundTransparency = 0.5
    leftLine.BorderSizePixel = 0
    leftLine.Parent = frame

    -- 右ライン
    local rightLine = Instance.new("Frame")
    rightLine.Size = UDim2.new(0, lineLength, 0, thickness)
    rightLine.Position = UDim2.new(0, gap, 0.5, -thickness/2)
    rightLine.BackgroundColor3 = color
    rightLine.BackgroundTransparency = 0.5
    rightLine.BorderSizePixel = 0
    rightLine.Parent = frame

    -- ライン先端の装飾 (小さな点)
    local dotSizeSmall = 2
    local dotPositions = {
        {x = 0, y = -gap - lineLength - dotSizeSmall},
        {x = 0, y = gap + lineLength + dotSizeSmall},
        {x = -gap - lineLength - dotSizeSmall, y = 0},
        {x = gap + lineLength + dotSizeSmall, y = 0},
    }

    for _, pos in pairs(dotPositions) do
        local smallDot = Instance.new("Frame")
        smallDot.Size = UDim2.new(0, dotSizeSmall, 0, dotSizeSmall)
        smallDot.Position = UDim2.new(0.5, pos.x - dotSizeSmall/2, 0.5, pos.y - dotSizeSmall/2)
        smallDot.BackgroundColor3 = color
        smallDot.BackgroundTransparency = 0.6
        smallDot.BorderSizePixel = 0
        smallDot.Parent = frame
        local smallCorner = Instance.new("UICorner")
        smallCorner.CornerRadius = UDim.new(1, 0)
        smallCorner.Parent = smallDot
    end

    -- 外側の薄いリング (クールさのアクセント)
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, gap * 2 + lineLength * 2 + 6, 0, gap * 2 + lineLength * 2 + 6)
    ring.Position = UDim2.new(0.5, -(gap + lineLength + 3), 0.5, -(gap + lineLength + 3))
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 1
    ring.BorderColor3 = color
    ring.BorderMode = Enum.BorderMode.Inset
    ring.BackgroundColor3 = color
    ring.BackgroundTransparency = 0.9
    ring.Parent = frame
    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = ring

    -- 4隅の小さな点 (さらにクールに)
    local cornerOffset = gap + lineLength + 4
    local cornerPositions = {
        {x = -cornerOffset, y = -cornerOffset},
        {x = cornerOffset, y = -cornerOffset},
        {x = -cornerOffset, y = cornerOffset},
        {x = cornerOffset, y = cornerOffset},
    }

    for _, pos in pairs(cornerPositions) do
        local cornerDot = Instance.new("Frame")
        cornerDot.Size = UDim2.new(0, 2, 0, 2)
        cornerDot.Position = UDim2.new(0.5, pos.x - 1, 0.5, pos.y - 1)
        cornerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        cornerDot.BackgroundTransparency = 0.6
        cornerDot.BorderSizePixel = 0
        cornerDot.Parent = frame
        local cornerCorner = Instance.new("UICorner")
        cornerCorner.CornerRadius = UDim.new(1, 0)
        cornerCorner.Parent = cornerDot
    end
end

-- ============================================
-- ユーティリティ関数
-- ============================================
local function getChar() return LocalPlayer.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ============================================
-- Fly読み込み (Pastefyから)
-- ============================================
local function LoadFly()
    if flyLoaded then
        OrionLib:MakeNotification({Name = "Kento Hub", Content = "✈️ Flyは既に読み込まれています", Time = 2})
        return
    end
    
    local success, result = pcall(function()
        return game:HttpGet("https://pastefy.app/oDUJGaqE/raw")
    end)
    
    if success and result then
        local func, err = loadstring(result)
        if func then
            flyLoaded = true
            task.spawn(function()
                func()
            end)
            OrionLib:MakeNotification({Name = "Kento Hub", Content = "✅ Flyを読み込みました (FキーでON/OFF)", Time = 3})
        else
            OrionLib:MakeNotification({Name = "Kento Hub", Content = "❌ Flyの読み込みに失敗: " .. tostring(err), Time = 3})
        end
    else
        OrionLib:MakeNotification({Name = "Kento Hub", Content = "❌ Flyのダウンロードに失敗", Time = 3})
    end
end

-- ============================================
-- スピードハック
-- ============================================
local function ToggleSpeedHack(enabled)
    Settings.SpeedHack = enabled
    if enabled then
        local hum = getHum()
        if hum then
            hum.WalkSpeed = Settings.SpeedValue
        end
    else
        local hum = getHum()
        if hum then
            hum.WalkSpeed = 16
        end
    end
end

local function UpdateSpeed()
    if Settings.SpeedHack then
        local hum = getHum()
        if hum then
            hum.WalkSpeed = Settings.SpeedValue
        end
    end
end

-- ============================================
-- 無限ジャンプ
-- ============================================
UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump then
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ============================================
-- 壁貫通 (Noclip)
-- ============================================
local function ToggleNoclip(enabled)
    Settings.Noclip = enabled
    if enabled then
        noclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

-- ============================================
-- 視認性向上 (Wallhack)
-- ============================================
local function ToggleWallhack(enabled)
    Settings.Wallhack = enabled
    if enabled then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Material ~= Enum.Material.Neon then
                pcall(function()
                    v.Material = Enum.Material.Neon
                    v.Transparency = 0.3
                end)
            end
        end
        Workspace.DescendantAdded:Connect(function(obj)
            if Settings.Wallhack and obj:IsA("BasePart") and obj.Material ~= Enum.Material.Neon then
                pcall(function()
                    obj.Material = Enum.Material.Neon
                    obj.Transparency = 0.3
                end)
            end
        end)
    else
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Material == Enum.Material.Neon then
                pcall(function()
                    v.Material = Enum.Material.Plastic
                    v.Transparency = 0
                end)
            end
        end
    end
end

-- ============================================
-- ESP (Highlight使用 - 壁の奥も表示)
-- ============================================
local function UpdateESP()
    if not Settings.ESP then
        for player, highlight in pairs(espHighlights) do
            pcall(function() highlight:Destroy() end)
        end
        espHighlights = {}
        return
    end

    for player, highlight in pairs(espHighlights) do
        if not player or not player.Parent then
            pcall(function() highlight:Destroy() end)
            espHighlights[player] = nil
        end
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            if espHighlights[player] then
                pcall(function() espHighlights[player]:Destroy() end)
                espHighlights[player] = nil
            end
            continue
        end

        if not espHighlights[player] then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = player.Character
            highlight.FillColor = Color3.fromRGB(255, 170, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0.3
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = player.Character
            espHighlights[player] = highlight
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.wait(0.5)
        UpdateESP()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then
        pcall(function() espHighlights[player]:Destroy() end)
        espHighlights[player] = nil
    end
end)

task.wait(1)
UpdateESP()

-- ============================================
-- カメラTP (現在地にカメラを移動)
-- ============================================
local function TeleportCamera()
    local root = getRoot()
    if root then
        local pos = root.Position
        TweenService:Create(Camera, TweenInfo.new(0.5), {CFrame = CFrame.new(pos + Vector3.new(0, 5, 0), pos)}):Play()
    end
end

-- ============================================
-- 位置記憶TP
-- ============================================
local function SavePosition()
    local root = getRoot()
    if root then
        Settings.SavedPosition = root.CFrame
        OrionLib:MakeNotification({Name = "Kento Hub", Content = "✅ 位置を保存しました", Time = 2})
    end
end

local function TeleportToSaved()
    local char = getChar()
    if char and Settings.SavedPosition then
        local root = getRoot()
        if root then
            root.CFrame = Settings.SavedPosition
            OrionLib:MakeNotification({Name = "Kento Hub", Content = "✅ TPしました", Time = 2})
        end
    else
        OrionLib:MakeNotification({Name = "Kento Hub", Content = "❌ 保存された位置がありません", Time = 2})
    end
end

-- ============================================
-- プレイヤーTP (選択式)
-- ============================================
local function GetPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

local function TeleportToPlayer(playerName)
    local target = Players:FindFirstChild(playerName)
    if target and target.Character then
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local myRoot = getRoot()
            if myRoot then
                myRoot.CFrame = root.CFrame + Vector3.new(0, 3, 0)
                OrionLib:MakeNotification({Name = "Kento Hub", Content = "✅ " .. target.Name .. " にTPしました", Time = 2})
            end
        end
    else
        OrionLib:MakeNotification({Name = "Kento Hub", Content = "❌ プレイヤーが見つかりません", Time = 2})
    end
end

-- ============================================
-- UI構築 (Kento Hub オレンジテーマ)
-- ============================================
local Window = OrionLib:MakeWindow({
    Name = "Kento Hub 🧡",
    HidePremium = true,
    SaveConfig = false,
    IntroEnabled = true,
    IntroText = "Kento Hub"
})

-- メインタブ
local MainTab = Window:MakeTab({
    Name = "メイン",
    Icon = "rbxassetid://4483345998"
})

MainTab:AddSection({Name = "⚡ 移動系"})

MainTab:AddToggle({
    Name = "🏃 スピードハック",
    Default = false,
    Callback = function(v)
        ToggleSpeedHack(v)
    end
})

MainTab:AddSlider({
    Name = "速度",
    Min = 16,
    Max = 250,
    Default = 50,
    Increment = 1,
    ValueName = "速度",
    Callback = function(v)
        Settings.SpeedValue = v
        UpdateSpeed()
    end
})

MainTab:AddToggle({
    Name = "🦘 無限ジャンプ",
    Default = false,
    Callback = function(v)
        Settings.InfiniteJump = v
    end
})

MainTab:AddToggle({
    Name = "🌀 壁貫通 (Noclip)",
    Default = false,
    Callback = function(v)
        ToggleNoclip(v)
    end
})

MainTab:AddToggle({
    Name = "✈️ Fly読み込み (FキーでON/OFF)",
    Default = false,
    Callback = function(v)
        if v then
            LoadFly()
        end
    end
})

MainTab:AddSection({Name = "🎯 照準"})

MainTab:AddToggle({
    Name = "🎯 クロスヘア (シンプル＆クール)",
    Default = false,
    Callback = function(v)
        Settings.Crosshair = v
        if v then
            CreateCrosshair()
        else
            if crosshairGui then
                pcall(function() crosshairGui:Destroy() end)
                crosshairGui = nil
            end
        end
    end
})

MainTab:AddSection({Name = "👁️ 視覚系"})

MainTab:AddToggle({
    Name = "🔍 視認性向上 (Wallhack)",
    Default = false,
    Callback = function(v)
        ToggleWallhack(v)
    end
})

MainTab:AddToggle({
    Name = "👤 プレイヤーESP (Highlight)",
    Default = false,
    Callback = function(v)
        Settings.ESP = v
        if not v then
            for player, highlight in pairs(espHighlights) do
                pcall(function() highlight:Destroy() end)
            end
            espHighlights = {}
        else
            UpdateESP()
        end
    end
})

-- TPタブ
local TPTab = Window:MakeTab({
    Name = "テレポート",
    Icon = "rbxassetid://4483345998"
})

TPTab:AddSection({Name = "📍 位置保存"})

TPTab:AddButton({
    Name = "💾 現在地を保存",
    Callback = SavePosition
})

TPTab:AddButton({
    Name = "🔄 保存位置にTP",
    Callback = TeleportToSaved
})

TPTab:AddSection({Name = "🎯 プレイヤーTP"})

local playerDropdown = TPTab:AddDropdown({
    Name = "プレイヤー選択",
    Options = GetPlayerList(),
    Callback = function(v)
        if v then
            TeleportToPlayer(v)
        end
    end
})

TPTab:AddButton({
    Name = "🔄 リスト更新",
    Callback = function()
        playerDropdown:Refresh(GetPlayerList(), true)
    end
})

TPTab:AddSection({Name = "📷 カメラ"})

TPTab:AddButton({
    Name = "📷 カメラを現在地にTP",
    Callback = TeleportCamera
})

-- ============================================
-- ESP更新ループ (常時更新)
-- ============================================
RunService.RenderStepped:Connect(function()
    if Settings.ESP then
        UpdateESP()
    end
end)

-- ============================================
-- 起動完了
-- ============================================
OrionLib:MakeNotification({
    Name = "Kento Hub 🧡",
    Content = "総合ユーティリティ 読み込み完了!",
    Time = 3
})

OrionLib:Init()

print("🧡 Kento Hub / 総合ユーティリティ v9 読み込み完了!")
print("🧡 テーマ: オレンジ × 黒")
print("📌 FlyはFキーでON/OFF (読み込み後に有効)")
print("📌 ESPはHighlightを使用 (壁の奥も表示)")
print("🎯 シンプル＆クールなクロスヘア搭載!")

-- config (everything off by default, flip them in the menu)
local Config = {
    Enabled = true,  TeamCheck = false,
    Box = false, Health = false, Name = false, Item = false, Dist = false,
    Bones = false, RootDot = false,
    Warn = false, Counter = false, Fps = false,

    -- character mods (value + enable flag)
    SpeedOn = false, Speed = 16,
    JumpOn  = false, Jump  = 50,
    GravOn  = false, Grav  = 196,
    HeadOn  = false, Head  = 1,
    TransOn = false, Trans = 0,

    MaxDistance  = 2000,
    BoxColor     = Color3.fromRGB(255, 50, 50),
    NameColor    = Color3.fromRGB(204, 170, 0),
    ItemColor    = Color3.fromRGB(0, 60, 200),
    DistColor    = Color3.fromRGB(255, 255, 255),
    VisColor     = Color3.fromRGB(0, 255, 0),
    HiddenColor  = Color3.fromRGB(255, 0, 0),
    TextSize     = 13,

    WarnAngleDeg = 8,    WarnMaxDist = 500,   WarnNeedLOS = true,
    WarnY        = 0.05, WarnTextSize = 30,   WarnFlip = 0.8,
    WarnColorA   = Color3.fromRGB(255, 220, 0),
    WarnColorB   = Color3.fromRGB(255, 0, 0),
    WarnText     = "⚠️ ENEMY IS AIMING AT YOU ⚠️",

    CountRadius  = 500,  HudY = 0.12,  HudTextSize = 18,
    HudBg        = Color3.fromRGB(45, 25, 25),
    HudBorder    = Color3.fromRGB(200, 40, 40),

    MenuTitle    = "haxbey engine",
    TitleIcon    = "",     -- FILL: paste your unicode between the quotes, shows next to the title
    RobuxIcon    = "R$",   -- FILL: paste your robux unicode here, used on every price
    KickMessage  = "left via haxbey engine",   -- shown on the disconnect screen when you kick yourself
    MenuKey      = Enum.KeyCode.RightShift,
    ExitKey      = Enum.KeyCode.End,
}

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp  = Players.LocalPlayer
local cam = workspace.CurrentCamera

local R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}

local function mk(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function inst(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props) do i[k] = v end
    i.Parent = parent
    return i
end

local function label(parent, text, color, size, font)
    return inst("TextLabel", {
        BackgroundTransparency = 1, Text = text, TextColor3 = color,
        TextSize = size, Font = font or Enum.Font.GothamBold,
        TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.new(0, 0, 0),
    }, parent)
end

---------------------------------------------------------------- gui root
local gui = inst("ScreenGui", {
    Name = "ESP_UI", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, (gethui and gethui()) or game:GetService("CoreGui"))

---------------------------------------------------------------- hud
local hud = inst("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, Config.HudY, 0),
    AutomaticSize = Enum.AutomaticSize.XY,
    BackgroundTransparency = 1,
}, gui)
inst("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 8),
}, hud)

local function pill(order)
    local f = inst("Frame", {
        LayoutOrder = order, AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Config.HudBg, BackgroundTransparency = 0.2, Visible = false,
    }, hud)
    inst("UICorner", { CornerRadius = UDim.new(0, 8) }, f)
    inst("UIStroke", { Color = Config.HudBorder, Thickness = 2 }, f)
    inst("UIPadding", {
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
        PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7),
    }, f)
    local t = label(f, "", Color3.new(1, 1, 1), Config.HudTextSize, Enum.Font.GothamMedium)
    t.TextStrokeTransparency = 1
    t.AutomaticSize = Enum.AutomaticSize.XY
    return f, t
end

local countPill, countText = pill(1)
local fpsPill,   fpsText   = pill(2)
countText.Text, fpsText.Text = "Total enemy around you: 0", "60 FPS"

local warnLabel = label(gui, Config.WarnText, Config.WarnColorA, Config.WarnTextSize, Enum.Font.GothamBlack)
warnLabel.AnchorPoint = Vector2.new(0.5, 0)
warnLabel.Position = UDim2.new(0.5, 0, Config.WarnY, 0)
warnLabel.AutomaticSize = Enum.AutomaticSize.XY
warnLabel.TextStrokeTransparency = 0
warnLabel.Visible = false

---------------------------------------------------------------- menu
local conns = {}
local BG     = Color3.fromRGB(12, 12, 14)
local PANEL  = Color3.fromRGB(18, 18, 21)
local ROW    = Color3.fromRGB(38, 38, 42)
local RED    = Color3.fromRGB(190, 45, 45)
local DARKRED= Color3.fromRGB(135, 35, 35)
local DIM    = Color3.fromRGB(70, 70, 78)
local WHITE  = Color3.new(1, 1, 1)

local WIN_W, WIN_H = 540, 420

local window = inst("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WIN_W, WIN_H), BackgroundColor3 = BG,
    BackgroundTransparency = 0.05, Visible = false, ClipsDescendants = true,
}, gui)
inst("UICorner", { CornerRadius = UDim.new(0, 8) }, window)
inst("UIStroke", { Color = DIM, Thickness = 1.5 }, window)

-- title bar
local title = inst("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = DARKRED }, window)
inst("UICorner", { CornerRadius = UDim.new(0, 8) }, title)
inst("Frame", {
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = DARKRED, BorderSizePixel = 0,
}, title)
local titleText = Config.MenuTitle
if Config.TitleIcon ~= "" then titleText = titleText .. " " .. Config.TitleIcon end
local tl = label(title, titleText, WHITE, 14, Enum.Font.GothamMedium)
tl.Size = UDim2.new(1, 0, 1, 0) tl.TextStrokeTransparency = 1

local collapseBtn = inst("TextButton", {
    Size = UDim2.fromOffset(28, 26), Position = UDim2.fromOffset(6, 2), BackgroundTransparency = 1,
    Text = "▼", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14,
}, title)
local closeBtn = inst("TextButton", {
    Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -6, 0, 2), BackgroundTransparency = 1,
    Text = "✕", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14,
}, title)
closeBtn.Activated:Connect(function() window.Visible = false end)

-- tab bar
local tabBar = inst("Frame", {
    Position = UDim2.fromOffset(8, 36), Size = UDim2.new(1, -16, 0, 28), BackgroundTransparency = 1,
}, window)
inst("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, tabBar)

-- bordered content panel
local panel = inst("Frame", {
    Position = UDim2.fromOffset(8, 70), Size = UDim2.new(1, -16, 1, -78), BackgroundColor3 = PANEL,
}, window)
inst("UICorner", { CornerRadius = UDim.new(0, 4) }, panel)
inst("UIStroke", { Color = DIM, Thickness = 1 }, panel)

local pages, tabBtns, currentTab, collapsed = {}, {}, nil, false
local function selectTab(name)
    currentTab = name
    for n, p in pairs(pages) do p.Visible = (n == name) and not collapsed end
    for n, b in pairs(tabBtns) do b.BackgroundColor3 = (n == name) and RED or ROW end
end

collapseBtn.Activated:Connect(function()
    collapsed = not collapsed
    collapseBtn.Text = collapsed and "▶" or "▼"
    tabBar.Visible, panel.Visible = not collapsed, not collapsed
    window.Size = UDim2.fromOffset(WIN_W, collapsed and 30 or WIN_H)
    selectTab(currentTab)
end)

local function addTab(name, scroll)
    local b = inst("TextButton", {
        Size = UDim2.new(1 / 5, -5, 1, 0), BackgroundColor3 = ROW, Text = name,
        TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = false,
    }, tabBar)
    inst("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
    inst("UIStroke", { Color = DIM, Thickness = 1 }, b)
    local p = inst(scroll and "ScrollingFrame" or "Frame", {
        Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16),
        BackgroundTransparency = 1, Visible = false,
    }, panel)
    if scroll then
        p.BorderSizePixel = 0 p.ScrollBarThickness = 3
        p.CanvasSize = UDim2.new() p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end
    b.Activated:Connect(function() selectTab(name) end)
    tabBtns[name], pages[name] = b, p
    return p
end

-- checkbox: dark square, red tick
local refreshers = {}
local function checkbox(parent, key, pos, size)
    local box = inst("TextButton", {
        Position = pos, Size = UDim2.fromOffset(size, size), Text = "",
        BackgroundColor3 = Color3.fromRGB(8, 8, 10), AutoButtonColor = false,
    }, parent)
    inst("UIStroke", { Color = DIM, Thickness = 1 }, box)
    local tick = inst("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "✔",
        TextColor3 = Color3.fromRGB(235, 50, 50), Font = Enum.Font.GothamBold, TextSize = size - 4,
    }, box)
    local function refresh() tick.Visible = Config[key] and true or false end
    refreshers[key] = refresh
    box.Activated:Connect(function() Config[key] = not Config[key] refresh() end)
    refresh()
    return box
end

local function toggle(parent, order, text, key)
    local row = inst("Frame", { LayoutOrder = order, BackgroundTransparency = 1 }, parent)
    checkbox(row, key, UDim2.new(0, 0, 0.5, -13), 26)
    local l = label(row, text, WHITE, 15, Enum.Font.GothamMedium)
    l.Position = UDim2.fromOffset(36, 0) l.Size = UDim2.new(1, -40, 1, 0)
    l.TextXAlignment = Enum.TextXAlignment.Left l.TextStrokeTransparency = 1
    return row
end

-- imgui-style slider: bar with value centered inside, name on the right
local activeSlider
local function slider(parent, order, text, key, mn, mx, step, fmt, enableKey)
    local row = inst("Frame", {
        LayoutOrder = order, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
    }, parent)

    local x = 0
    if enableKey then checkbox(row, enableKey, UDim2.new(0, 0, 0.5, -11), 22) x = 30 end

    local bar = inst("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundColor3 = ROW,
        Position = UDim2.fromOffset(x, 2), Size = UDim2.new(1, -(x + 150), 1, -4),
    }, row)
    inst("UIStroke", { Color = DIM, Thickness = 1 }, bar)
    local fill = inst("Frame", {
        Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = RED, BackgroundTransparency = 0.15, BorderSizePixel = 0,
    }, bar)
    local vl = label(bar, "", WHITE, 13, Enum.Font.GothamMedium)
    vl.Size = UDim2.fromScale(1, 1) vl.TextStrokeTransparency = 1 vl.ZIndex = 2

    local nl = label(row, text, WHITE, 13, Enum.Font.GothamMedium)
    nl.AnchorPoint = Vector2.new(1, 0) nl.Position = UDim2.new(1, 0, 0, 0)
    nl.Size = UDim2.new(0, 142, 1, 0) nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.TextStrokeTransparency = 1

    local function set(v)
        v = math.clamp(math.floor(v / step + 0.5) * step, mn, mx)
        Config[key] = v
        fill.Size = UDim2.new((v - mn) / (mx - mn), 0, 1, 0)
        vl.Text = fmt:format(v)
    end
    local function fromX(px)
        local a = math.clamp((px - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        set(mn + a * (mx - mn))
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            activeSlider = fromX
            fromX(i.Position.X)
        end
    end)
    set(Config[key])
end

local function listPage(page, pad)
    inst("UIListLayout", { Padding = UDim.new(0, pad or 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
end

local function bigButton(parent, order, text, color, size)
    local b = inst("TextButton", {
        LayoutOrder = order, Size = size, BackgroundColor3 = color, Text = text,
        TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 15, AutoButtonColor = true,
    }, parent)
    inst("UIStroke", { Color = DIM, Thickness = 1 }, b)
    return b
end

-- ESP tab
local espPage = addTab("👁️ ESP", false)

local espKeys = {
    "Enabled", "Box", "Health", "Name", "Item", "Dist", "Bones", "RootDot", "Warn", "Counter", "Fps",
}
local function setAll(v)
    for _, k in ipairs(espKeys) do
        Config[k] = v
        if refreshers[k] then refreshers[k]() end
    end
end

local topRow = inst("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 }, espPage)
local onBtn  = bigButton(topRow, 1, "ESP ALL ON",  RED, UDim2.new(0.5, -4, 1, 0))
local offBtn = bigButton(topRow, 2, "ESP ALL OFF", Color3.fromRGB(70, 70, 80), UDim2.new(0.5, -4, 1, 0))
offBtn.AnchorPoint = Vector2.new(1, 0) offBtn.Position = UDim2.new(1, 0, 0, 0)
onBtn.Activated:Connect(function() setAll(true) end)
offBtn.Activated:Connect(function() setAll(false) end)

local grid = inst("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, espPage)
inst("UIGridLayout", {
    CellSize = UDim2.new(0.5, -6, 0, 30), CellPadding = UDim2.fromOffset(8, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, grid)
local espItems = {
    {"Box", "Box"},           {"Team check", "TeamCheck"},
    {"Health", "Health"},     {"Aim warning", "Warn"},
    {"Name", "Name"},         {"Enemy counter", "Counter"},
    {"Held item", "Item"},    {"FPS", "Fps"},
    {"Distance", "Dist"},     {"ESP master", "Enabled"},
    {"Skeleton", "Bones"},    {"Root dot", "RootDot"},
}
for i, it in ipairs(espItems) do toggle(grid, i, it[1], it[2]) end

-- Character tab
local charPage = addTab("🧍 Character", false)
listPage(charPage, 8)
slider(charPage, 1, "Walk speed",   "Speed", 16, 150, 1,    "%d",    "SpeedOn")
slider(charPage, 2, "Jump power",   "Jump",  50, 250, 1,    "%d",    "JumpOn")
slider(charPage, 3, "Gravity",      "Grav",  20, 196, 1,    "%d",    "GravOn")
slider(charPage, 4, "Head size",    "Head",  1,  5,   0.1,  "%.1fx", "HeadOn")
slider(charPage, 5, "Transparency", "Trans", 0,  1,   0.05, "%.2f",  "TransOn")
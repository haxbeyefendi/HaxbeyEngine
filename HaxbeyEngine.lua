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

-- Catalog and Creator Store tabs
do
    local HttpService = game:GetService("HttpService")
    local Market = game:GetService("MarketplaceService")
    local httpReq = request or http_request or (syn and syn.request) or (http and http.request)
    local clip = setclipboard or toclipboard

    -- Both pages share a small request gap to reduce rate-limit pressure.
    local lastRequest = 0
    local REQUEST_GAP = 0.75

    local FILTERS = {
        { name = "All" },
        { name = "Accessories", types = { [8]=true, [41]=true, [42]=true, [43]=true, [44]=true, [45]=true, [46]=true, [47]=true } },
        { name = "Hats", types = { [8]=true } },
        { name = "Hair", types = { [41]=true } },
        { name = "Face", types = { [42]=true } },
        { name = "Neck", types = { [43]=true } },
        { name = "Shoulder", types = { [44]=true } },
        { name = "Front", types = { [45]=true } },
        { name = "Back", types = { [46]=true } },
        { name = "Waist", types = { [47]=true } },
        { name = "Classic T-Shirts", types = { [2]=true } },
        { name = "Classic Shirts", types = { [11]=true } },
        { name = "Classic Pants", types = { [12]=true } },
        { name = "Gear", types = { [19]=true } },
    }
    local PRICE_FILTERS = {
        { name = "Any price", query = "" },
        { name = "Free", query = "&MaxPrice=0" },
        { name = "Paid", query = "&MinPrice=1" },
    }
    local SORTS = {
        { name = "Relevance", value = 1 },
        { name = "Best selling", value = 2 },
        { name = "Newest", value = 3 },
        { name = "Price ↑", value = 4 },
        { name = "Price ↓", value = 5 },
    }
    local CREATOR_TYPES = {
        { name = "Models", category = "Model" },
        { name = "Decals", category = "Decal" },
        { name = "Audio", category = "Audio" },
        { name = "Plugins", category = "Plugin" },
    }

    local function requestJson(url, token)
        if not httpReq then return nil, "request() unavailable" end
        local waitFor = lastRequest + REQUEST_GAP - os.clock()
        if waitFor > 0 then task.wait(waitFor) end
        if token and token.cancelled then return nil, "search cancelled" end
        lastRequest = os.clock()

        local ok, response = pcall(httpReq, { Url = url, Method = "GET" })
        if not ok or not response then return nil, "no response" end
        local code = tonumber(response.StatusCode)
        if code == 429 then return nil, "Roblox rate limit (429). Wait a little, then search again." end
        if code ~= 200 then return nil, "HTTP " .. tostring(code or "?") end

        local decoded, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
        if not decoded then return nil, "invalid JSON response" end
        return data
    end

    local function makeStorePage(pageName, isCatalog)
        local pageFrame = addTab(pageName, false)
        local state = {
            query = "", page = 1, cursor = nil, nextCursor = nil,
            selected = nil, token = nil, busy = false,
            filter = 1, price = 1, sort = 1, creatorType = 1,
        }
        local top = inst("Frame", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
        }, pageFrame)
        local searchBox = inst("TextBox", {
            Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -78, 1, 0),
            BackgroundColor3 = ROW, Text = "", PlaceholderText = isCatalog and "Search avatar catalog..." or "Search Creator Store...",
            PlaceholderColor3 = Color3.fromRGB(130, 130, 140), TextColor3 = WHITE,
            Font = Enum.Font.GothamMedium, TextSize = 13, ClearTextOnFocus = false,
        }, top)
        inst("UIStroke", { Color = DIM, Thickness = 1 }, searchBox)
        local searchBtn = inst("TextButton", {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(72, 30), BackgroundColor3 = RED, Text = "Search",
            TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 13,
        }, top)

        local chips = inst("ScrollingFrame", {
            Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 27),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.X,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
        }, pageFrame)
        inst("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, chips)

        local chipButtons = {}
        local function addChip(text, order, callback)
            local b = inst("TextButton", {
                LayoutOrder = order, Size = UDim2.fromOffset(0, 26),
                AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = ROW,
                Text = text, TextColor3 = WHITE, Font = Enum.Font.GothamMedium,
                TextSize = 12, AutoButtonColor = false,
            }, chips)
            inst("UIPadding", {
                PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
            }, b)
            inst("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
            inst("UIStroke", { Color = DIM, Thickness = 1 }, b)
            b.Activated:Connect(callback)
            chipButtons[#chipButtons + 1] = b
            return b
        end

        local function refreshChips()
            for i, b in ipairs(chipButtons) do
                local active = false
                if isCatalog then
                    if i <= #PRICE_FILTERS then
                        active = i == state.price
                    elseif i <= #PRICE_FILTERS + #SORTS then
                        active = i - #PRICE_FILTERS == state.sort
                    else
                        active = i - #PRICE_FILTERS - #SORTS == state.filter
                    end
                else
                    active = i == state.creatorType
                end
                b.BackgroundColor3 = active and RED or ROW
            end
        end

        if isCatalog then
            for i, item in ipairs(PRICE_FILTERS) do
                addChip(item.name, i, function()
                    state.price = i
                    refreshChips()
                    state.page = 1
                    state.cursor = nil
                    state.nextCursor = nil
                    state.token = nil
                    -- Search is defined below.
                    searchBox:ReleaseFocus()
                    searchBtn:Activate()
                end)
            end
            for i, item in ipairs(SORTS) do
                addChip(item.name, 10 + i, function()
                    state.sort = i
                    refreshChips()
                    state.page = 1
                    state.cursor = nil
                    state.nextCursor = nil
                    state.token = nil
                    searchBtn:Activate()
                end)
            end
            for i, item in ipairs(FILTERS) do
                addChip(item.name, 30 + i, function()
                    state.filter = i
                    refreshChips()
                    state.page = 1
                    state.cursor = nil
                    state.nextCursor = nil
                    state.token = nil
                    searchBtn:Activate()
                end)
            end
        else
            for i, item in ipairs(CREATOR_TYPES) do
                addChip(item.name, i, function()
                    state.creatorType = i
                    refreshChips()
                    state.page = 1
                    state.cursor = nil
                    state.nextCursor = nil
                    state.token = nil
                    searchBtn:Activate()
                end)
            end
        end
        refreshChips()

        local results = inst("ScrollingFrame", {
            Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 1, -138),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, pageFrame)
        inst("UIGridLayout", {
            CellSize = UDim2.fromOffset(104, 140), CellPadding = UDim2.fromOffset(6, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, results)
        local status = label(results, "Search for an item above.", WHITE, 13, Enum.Font.GothamMedium)
        status.Size = UDim2.fromOffset(360, 30)
        status.TextStrokeTransparency = 1
        status.LayoutOrder = -1
        status.TextXAlignment = Enum.TextXAlignment.Left

        local pager = inst("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -38),
            Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
        }, pageFrame)
        local prevBtn = inst("TextButton", {
            Size = UDim2.fromOffset(90, 28), BackgroundColor3 = ROW, Text = "◀ Prev",
            TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 13,
        }, pager)
        local nextBtn = inst("TextButton", {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(90, 28), BackgroundColor3 = ROW, Text = "Next ▶",
            TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 13,
        }, pager)
        local pageLabel = label(pager, "Page 1", WHITE, 13, Enum.Font.GothamMedium)
        pageLabel.Size = UDim2.fromScale(1, 1)
        pageLabel.TextStrokeTransparency = 1

        local actionBar = inst("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = ROW,
        }, pageFrame)
        inst("UIStroke", { Color = DIM, Thickness = 1 }, actionBar)
        local selectedLabel = label(actionBar, "Select an item to see its ID.", WHITE, 12, Enum.Font.GothamMedium)
        selectedLabel.Position = UDim2.fromOffset(8, 0)
        selectedLabel.Size = UDim2.new(1, -190, 1, 0)
        selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
        selectedLabel.TextStrokeTransparency = 1
        selectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
        local copyBtn = inst("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -96, 0.5, 0),
            Size = UDim2.fromOffset(84, 24), BackgroundColor3 = DIM,
            Text = "Copy ID", TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 12,
        }, actionBar)
        local actionBtn = inst("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.fromOffset(84, 24), BackgroundColor3 = RED,
            Text = isCatalog and "Get / Buy" or "Open ID", TextColor3 = WHITE,
            Font = Enum.Font.GothamMedium, TextSize = 12,
        }, actionBar)

        local function clearResults()
            for _, child in ipairs(results:GetChildren()) do
                if child:IsA("GuiButton") then child:Destroy() end
            end
            results.CanvasPosition = Vector2.zero
        end

        local function addResult(item, order)
            local card = inst("TextButton", {
                LayoutOrder = order, BackgroundColor3 = ROW, Text = "",
                AutoButtonColor = true,
            }, results)
            inst("UIStroke", { Color = DIM, Thickness = 1 }, card)
            local thumbType = item.itemType == "Bundle" and "BundleThumbnail" or "Asset"
            inst("ImageLabel", {
                Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 82),
                BackgroundTransparency = 1,
                Image = ("rbxthumb://type=%s&id=%d&w=150&h=150"):format(thumbType, item.id),
            }, card)
            local name = label(card, item.name or ("ID " .. item.id), WHITE, 11, Enum.Font.GothamMedium)
            name.Position = UDim2.fromOffset(4, 88)
            name.Size = UDim2.new(1, -8, 0, 28)
            name.TextWrapped = true
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.TextYAlignment = Enum.TextYAlignment.Top
            name.TextStrokeTransparency = 1
            local price = label(card, item.priceText or "", Color3.fromRGB(235, 80, 80), 11, Enum.Font.GothamBold)
            price.Position = UDim2.fromOffset(4, 118)
            price.Size = UDim2.new(1, -8, 0, 16)
            price.TextXAlignment = Enum.TextXAlignment.Left
            price.TextStrokeTransparency = 1
            card.Activated:Connect(function()
                state.selected = item
                selectedLabel.Text = ("%s  [%d]"):format(item.name or "Selected item", item.id)
                if clip then
                    pcall(clip, tostring(item.id))
                    selectedLabel.Text = "Copied ID " .. tostring(item.id)
                end
            end)
        end

        local function updatePager()
            pageLabel.Text = "Page " .. state.page
            prevBtn.TextTransparency = state.page > 1 and 0 or 0.55
            nextBtn.TextTransparency = state.nextCursor and 0 or 0.55
        end

        local function runSearch()
            if state.busy then return end
            state.busy = true
            local token = { cancelled = false }
            if state.token then state.token.cancelled = true end
            state.token = token
            clearResults()
            state.selected = nil
            selectedLabel.Text = "Select an item to see its ID."
            status.Text = "Loading..."
            state.nextCursor = nil
            updatePager()

            task.spawn(function()
                local query = searchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
                local encoded = HttpService:UrlEncode(query)
                local items = {}
                local nextCursor
                local data, err

                if isCatalog then
                    local sort = SORTS[state.sort].value
                    local url = "https://catalog.roblox.com/v1/search/items/details?Keyword=" ..
                        encoded .. "&Limit=30&SortType=" .. tostring(sort) ..
                        PRICE_FILTERS[state.price].query
                    if state.cursor and state.cursor ~= "" then
                        url ..= "&Cursor=" .. HttpService:UrlEncode(state.cursor)
                    end
                    data, err = requestJson(url, token)
                    if data then
                        for _, entry in ipairs(data.data or {}) do
                            local assetType = tonumber(entry.assetType)
                            local allowed = FILTERS[state.filter].types
                            local priceValue = entry.price
                            if priceValue == nil then priceValue = entry.lowestPrice end
                            local keep = not allowed or (assetType and allowed[assetType])
                            if state.price == 2 and priceValue ~= nil and priceValue ~= 0 then keep = false end
                            if state.price == 3 and priceValue == 0 then keep = false end
                            if keep and entry.id then
                                items[#items + 1] = {
                                    id = tonumber(entry.id), name = entry.name,
                                    itemType = entry.itemType or "Asset",
                                    priceText = priceValue == 0 and "Free" or
                                        (priceValue and (Config.RobuxIcon .. " " .. tostring(priceValue)) or "Off sale"),
                                }
                            end
                        end
                        nextCursor = data.nextPageCursor
                    end
                else
                    local creatorType = CREATOR_TYPES[state.creatorType]
                    local url = ("https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=%s&query=%s&maxPageSize=30")
                        :format(creatorType.category, encoded)
                    if state.cursor and state.cursor ~= "" then
                        url ..= "&pageToken=" .. HttpService:UrlEncode(state.cursor)
                    end
                    data, err = requestJson(url, token)
                    if data then
                        for _, entry in ipairs(data.creatorStoreAssets or {}) do
                            local asset = entry.asset
                            if asset and asset.id then
                                items[#items + 1] = {
                                    id = tonumber(asset.id), name = asset.name,
                                    itemType = "Asset", priceText = "Creator Store",
                                }
                            end
                        end
                        nextCursor = data.nextPageToken
                    end
                end

                if token.cancelled then state.busy = false return end
                if not data then
                    status.Text = err or "Search failed."
                    state.busy = false
                    updatePager()
                    return
                end

                state.nextCursor = (nextCursor and nextCursor ~= "") and nextCursor or nil
                updatePager()
                if #items == 0 then
                    status.Text = "No results found."
                else
                    status.Text = ""
                    for i, item in ipairs(items) do
                        if item.id then addResult(item, i) end
                    end
                end
                state.busy = false
            end)
        end

        local function resetAndSearch()
            state.page = 1
            state.cursor = nil
            state.nextCursor = nil
            runSearch()
        end

        searchBtn.Activated:Connect(resetAndSearch)
        searchBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then resetAndSearch() end
        end)
        prevBtn.Activated:Connect(function()
            if state.page <= 1 or state.busy then return end
            state.page -= 1
            state.cursor = nil
            -- Previous-page cursor is retained in the cursor stack below.
            state.cursor = state.pageCursors and state.pageCursors[state.page] or nil
            runSearch()
        end)
        nextBtn.Activated:Connect(function()
            if not state.nextCursor or state.busy then return end
            state.pageCursors = state.pageCursors or {}
            state.pageCursors[state.page + 1] = state.nextCursor
            state.cursor = state.nextCursor
            state.page += 1
            runSearch()
        end)
        copyBtn.Activated:Connect(function()
            if state.selected and clip then
                pcall(clip, tostring(state.selected.id))
                selectedLabel.Text = "Copied ID " .. tostring(state.selected.id)
            end
        end)
        actionBtn.Activated:Connect(function()
            local item = state.selected
            if not item then return end
            if isCatalog then
                pcall(function()
                    if item.itemType == "Bundle" then
                        Market:PromptBundlePurchase(lp, item.id)
                    else
                        Market:PromptPurchase(lp, item.id)
                    end
                end)
            elseif clip then
                pcall(clip, tostring(item.id))
                selectedLabel.Text = "Copied Creator Store ID " .. tostring(item.id)
            end
        end)
        state.pageCursors = {}
        updatePager()
    end

    makeStorePage("🛍 Catalog", true)
    makeStorePage("🧰 Creator Store", false)
end

-- Settings tab
local setPage = addTab("⚙️ Settings", false)
listPage(setPage, 8)
slider(setPage, 1, "ESP range",      "MaxDistance", 100, 5000, 50, "%d")
slider(setPage, 2, "Counter radius", "CountRadius", 50, 2000, 50, "%d")
local unloadBtn = bigButton(setPage, 3, "Unload hack", ROW, UDim2.new(1, 0, 0, 40))

-- kick myself: only kicks the local player (you), two taps so it can't happen by accident
local kickBtn = bigButton(setPage, 4, "Kick myself", Color3.fromRGB(150, 40, 40), UDim2.new(1, 0, 0, 40))
local kickArmed = false
kickBtn.Activated:Connect(function()
    if kickArmed then
        lp:Kick(Config.KickMessage)
        return
    end
    kickArmed = true
    kickBtn.Text = "Tap again to confirm"
    task.delay(3, function()
        kickArmed = false
        if kickBtn.Parent then kickBtn.Text = "Kick myself" end
    end)
end)

selectTab("👁️ ESP")

-- window drag + slider drag
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, i.Position, window.Position
    end
end)
table.insert(conns, UserInputService.InputChanged:Connect(function(i)
    local moving = i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
    if not moving then return end
    if activeSlider then
        activeSlider(i.Position.X)
    elseif dragging then
        local d = i.Position - dragStart
        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))
table.insert(conns, UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging, activeSlider = false, nil
    end
end))

-- floating open button (mobile friendly)
local openBtn = inst("TextButton", {
    Position = UDim2.new(0, 8, 0.5, -20), Size = UDim2.fromOffset(44, 40),
    BackgroundColor3 = BG, Text = "HX", TextColor3 = RED,
    Font = Enum.Font.GothamBold, TextSize = 14,
}, gui)
inst("UICorner", { CornerRadius = UDim.new(0, 8) }, openBtn)
inst("UIStroke", { Color = RED, Thickness = 1.5 }, openBtn)
openBtn.Activated:Connect(function() window.Visible = not window.Visible end)

---------------------------------------------------------------- esp objects
local function newEsp()
    local o = { corners = {}, bones = {} }
    for i = 1, 8 do o.corners[i] = mk("Line", { Thickness = 1.5, Color = Config.BoxColor, Visible = false }) end
    for i = 1, #R15 do o.bones[i] = mk("Line", { Thickness = 1.5, Visible = false }) end
    o.hpBack = mk("Line", { Thickness = 4, Color = Color3.new(0, 0, 0), Visible = false })
    o.hpBar  = mk("Line", { Thickness = 2, Color = Color3.new(0, 1, 0), Visible = false })
    o.dot    = mk("Circle", { Radius = 3, Filled = true, NumSides = 12, Visible = false })

    o.holder = inst("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(200, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false,
    }, gui)
    inst("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, o.holder)
    local function row(n, color)
        local l = label(o.holder, "", color, Config.TextSize)
        l.LayoutOrder = n l.Size = UDim2.new(1, 0, 0, Config.TextSize + 2)
        return l
    end
    o.name = row(1, Config.NameColor)
    o.item = row(2, Config.ItemColor)
    o.dist = row(3, Config.DistColor)
    return o
end

local function hide(o)
    for _, l in ipairs(o.corners) do l.Visible = false end
    for _, l in ipairs(o.bones)   do l.Visible = false end
    o.hpBack.Visible, o.hpBar.Visible, o.dot.Visible = false, false, false
    o.holder.Visible = false
end

local function destroy(o)
    for _, l in ipairs(o.corners) do l:Remove() end
    for _, l in ipairs(o.bones)   do l:Remove() end
    o.hpBack:Remove() o.hpBar:Remove() o.dot:Remove()
    o.holder:Destroy()
end

local tracked = {}
local function track(plr)
    if plr ~= lp and not tracked[plr] then tracked[plr] = newEsp() end
end
local function untrack(plr)
    local o = tracked[plr]
    if o then destroy(o) tracked[plr] = nil end
end
for _, p in ipairs(Players:GetPlayers()) do track(p) end
table.insert(conns, Players.PlayerAdded:Connect(track))
table.insert(conns, Players.PlayerRemoving:Connect(untrack))

---------------------------------------------------------------- helpers
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isVisible(char, target)
    local origin = cam.CFrame.Position
    local res = workspace:Raycast(origin, target.Position - origin, rayParams)
    return res == nil or res.Instance:IsDescendantOf(char)
end

local function w2s(pos)
    local v = cam:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), v.Z > 0
end

local cosLimit = math.cos(math.rad(Config.WarnAngleDeg))
local warnRay = RaycastParams.new()
warnRay.FilterType = Enum.RaycastFilterType.Exclude
warnRay.IgnoreWater = true

local function scan(myChar, myRoot)
    local count, aiming = 0, false
    if not myRoot then return 0, false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            local char = plr.Character
            local head = char and char:FindFirstChild("Head")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local skip = not head or not hum or hum.Health <= 0
                or (Config.TeamCheck and plr.Team ~= nil and plr.Team == lp.Team)
            if not skip then
                local toMe = myRoot.Position - head.Position
                local dist = toMe.Magnitude
                if dist <= Config.CountRadius then count += 1 end
                if not aiming and dist <= Config.WarnMaxDist and dist > 0.1
                    and head.CFrame.LookVector:Dot(toMe / dist) >= cosLimit then
                    if not Config.WarnNeedLOS then
                        aiming = true
                    else
                        warnRay.FilterDescendantsInstances = { char }
                        local hit = workspace:Raycast(head.Position, toMe, warnRay)
                        if hit == nil or hit.Instance:IsDescendantOf(myChar) then aiming = true end
                    end
                end
            end
        end
    end
    return count, aiming
end

---------------------------------------------------------------- character mods
local saved, lastHum, transSaved = {}, nil, {}

local function charTick()
    local char = lp.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum ~= lastHum then saved, transSaved, lastHum = {}, {}, hum end
    if not hum then return end

    if Config.SpeedOn then
        if saved.speed == nil then saved.speed = hum.WalkSpeed end
        hum.WalkSpeed = Config.Speed
    elseif saved.speed ~= nil then
        hum.WalkSpeed = saved.speed saved.speed = nil
    end

    if Config.JumpOn then
        if saved.jump == nil then saved.jump = { hum.UseJumpPower, hum.JumpPower } end
        hum.UseJumpPower = true
        hum.JumpPower = Config.Jump
    elseif saved.jump ~= nil then
        hum.UseJumpPower, hum.JumpPower = saved.jump[1], saved.jump[2] saved.jump = nil
    end

    if Config.GravOn then
        if saved.grav == nil then saved.grav = workspace.Gravity end
        workspace.Gravity = Config.Grav
    elseif saved.grav ~= nil then
        workspace.Gravity = saved.grav saved.grav = nil
    end

    local head = char:FindFirstChild("Head")
    local hs = hum:FindFirstChild("HeadScale")
    if Config.HeadOn and head then
        if hs then
            if saved.head == nil then saved.head = hs.Value end
            hs.Value = Config.Head
        else
            if saved.head == nil then saved.head = head.Size end
            head.Size = saved.head * Config.Head
        end
    elseif saved.head ~= nil then
        if hs then hs.Value = saved.head elseif head then head.Size = saved.head end
        saved.head = nil
    end

    if Config.TransOn then
        for _, d in ipairs(char:GetDescendants()) do
            if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then
                if transSaved[d] == nil then transSaved[d] = d.Transparency end
                d.Transparency = Config.Trans
            end
        end
    elseif next(transSaved) then
        for d, t in pairs(transSaved) do
            if d.Parent then d.Transparency = t end
        end
        transSaved = {}
    end
end

local charTimer = 0
local charConn = RunService.Heartbeat:Connect(function(dt)
    charTimer += dt
    if charTimer >= 0.1 then charTimer = 0 charTick() end
end)

---------------------------------------------------------------- main loop
local fps, fpsTimer = 60, 0

local renderConn
renderConn = RunService.RenderStepped:Connect(function(dt)
    cam = workspace.CurrentCamera
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    rayParams.FilterDescendantsInstances = { myChar }

    local anyText = Config.Name or Config.Item or Config.Dist
    local needVis = Config.Bones or Config.RootDot
    local anything = Config.Box or Config.Health or anyText or needVis

    for plr, o in pairs(tracked) do
        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        local ok = Config.Enabled and anything and myRoot and hrp and hum and hum.Health > 0
        if ok and Config.TeamCheck and plr.Team ~= nil and plr.Team == lp.Team then ok = false end

        local dist = 0
        if ok then
            dist = (hrp.Position - myRoot.Position).Magnitude
            if dist > Config.MaxDistance then ok = false end
        end

        local top, topOn = w2s(hrp and (hrp.Position + Vector3.new(0, 3, 0)) or Vector3.zero)
        local bot, botOn = w2s(hrp and (hrp.Position - Vector3.new(0, 3.5, 0)) or Vector3.zero)
        if ok and not (topOn and botOn) then ok = false end

        if not ok then
            hide(o)
        else
            local h = math.abs(bot.Y - top.Y)
            local w = h * 0.6
            local x = (top.X + bot.X) / 2 - w / 2
            local y = top.Y

            if Config.Box then
                local cx, cy = w * 0.3, h * 0.15
                local segs = {
                    {Vector2.new(x, y),         Vector2.new(x + cx, y)},
                    {Vector2.new(x, y),         Vector2.new(x, y + cy)},
                    {Vector2.new(x + w, y),     Vector2.new(x + w - cx, y)},
                    {Vector2.new(x + w, y),     Vector2.new(x + w, y + cy)},
                    {Vector2.new(x, y + h),     Vector2.new(x + cx, y + h)},
                    {Vector2.new(x, y + h),     Vector2.new(x, y + h - cy)},
                    {Vector2.new(x + w, y + h), Vector2.new(x + w - cx, y + h)},
                    {Vector2.new(x + w, y + h), Vector2.new(x + w, y + h - cy)},
                }
                for i = 1, 8 do
                    local l = o.corners[i]
                    l.From, l.To, l.Color, l.Visible = segs[i][1], segs[i][2], Config.BoxColor, true
                end
            else
                for _, l in ipairs(o.corners) do l.Visible = false end
            end

            if Config.Health then
                local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local bx = x - 5
                o.hpBack.From, o.hpBack.To, o.hpBack.Visible = Vector2.new(bx, y + h + 1), Vector2.new(bx, y - 1), true
                o.hpBar.From  = Vector2.new(bx, y + h)
                o.hpBar.To    = Vector2.new(bx, y + h - h * ratio)
                o.hpBar.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), ratio)
                o.hpBar.Visible = true
            else
                o.hpBack.Visible, o.hpBar.Visible = false, false
            end

            o.name.Visible, o.item.Visible, o.dist.Visible = Config.Name, Config.Item, Config.Dist
            if anyText then
                local tool = char:FindFirstChildOfClass("Tool")
                o.name.Text = plr.DisplayName
                o.item.Text = tool and tool.Name or "Nothing"
                o.dist.Text = ("%d studs"):format(math.floor(dist))
                o.holder.Position = UDim2.fromOffset(x + w / 2, y + h + 2)
            end
            o.holder.Visible = anyText

            local col = Config.HiddenColor
            if needVis then
                col = isVisible(char, hrp) and Config.VisColor or Config.HiddenColor
            end

            if Config.RootDot then
                o.dot.Position, o.dot.Color, o.dot.Visible = w2s(hrp.Position), col, true
            else
                o.dot.Visible = false
            end

            if Config.Bones then
                local map = char:FindFirstChild("UpperTorso") and R15 or R6
                for i, l in ipairs(o.bones) do
                    local pair = map[i]
                    local a = pair and char:FindFirstChild(pair[1])
                    local b = pair and char:FindFirstChild(pair[2])
                    if a and b then
                        local pa, oa = w2s(a.Position)
                        local pb, ob = w2s(b.Position)
                        if oa and ob then
                            l.From, l.To, l.Color, l.Visible = pa, pb, col, true
                        else
                            l.Visible = false
                        end
                    else
                        l.Visible = false
                    end
                end
            else
                for _, l in ipairs(o.bones) do l.Visible = false end
            end
        end
    end

    local count, aiming = 0, false
    if Config.Warn or Config.Counter then count, aiming = scan(myChar, myRoot) end

    if Config.Warn and aiming then
        warnLabel.TextColor3 = (math.floor(os.clock() / Config.WarnFlip) % 2 == 0)
            and Config.WarnColorA or Config.WarnColorB
        warnLabel.Visible = true
    else
        warnLabel.Visible = false
    end

    countPill.Visible = Config.Counter
    if Config.Counter then countText.Text = ("Total enemy around you: %d"):format(count) end

    fpsPill.Visible = Config.Fps
    if Config.Fps then
        fps = fps + ((1 / math.max(dt, 1e-4)) - fps) * 0.1
        fpsTimer += dt
        if fpsTimer >= 0.25 then
            fpsTimer = 0
            fpsText.Text = ("%d FPS"):format(math.floor(fps + 0.5))
        end
    end
end)

---------------------------------------------------------------- keys / unload
local inputConn
local function unload()
    Config.SpeedOn, Config.JumpOn, Config.GravOn, Config.HeadOn, Config.TransOn = false, false, false, false, false
    charTick() -- restore everything
    renderConn:Disconnect() charConn:Disconnect() inputConn:Disconnect()
    for _, c in ipairs(conns) do c:Disconnect() end
    for plr in pairs(tracked) do untrack(plr) end
    gui:Destroy()
end

unloadBtn.Activated:Connect(unload)
inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.MenuKey then
        window.Visible = not window.Visible
    elseif input.KeyCode == Config.ExitKey then
        unload()
    end
end)
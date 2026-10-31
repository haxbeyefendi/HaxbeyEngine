-- config (everything off by default, flip them in the menu)[span_3](start_span)[span_3](end_span)
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
    TitleIcon    = "",     -- FILL: paste your unicode between the quotes, shows next to the title[span_4](start_span)[span_4](end_span)
    RobuxIcon    = "R$",   -- FILL: paste your robux unicode here, used on every price[span_5](start_span)[span_5](end_span)
    KickMessage  = "left via haxbey engine",   -- shown on the disconnect screen when you kick yourself[span_6](start_span)[span_6](end_span)
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
        Size = UDim2.new(1 / 4, -5, 1, 0), BackgroundColor3 = ROW, Text = name,
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

-- checkbox: dark square, red tick[span_7](start_span)[span_7](end_span)
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

-- imgui-style slider: bar with value centered inside, name on the right[span_8](start_span)[span_8](end_span)
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

-- ESP tab[span_9](start_span)[span_9](end_span)
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

-- Character tab[span_10](start_span)[span_10](end_span)
local charPage = addTab("🧍 Character", false)
listPage(charPage, 8)
slider(charPage, 1, "Walk speed",   "Speed", 16, 150, 1,    "%d",    "SpeedOn")
slider(charPage, 2, "Jump power",   "Jump",  50, 250, 1,    "%d",    "JumpOn")
slider(charPage, 3, "Gravity",      "Grav",  20, 196, 1,    "%d",    "GravOn")
slider(charPage, 4, "Head size",    "Head",  1,  5,   0.1,  "%.1fx", "HeadOn")
slider(charPage, 5, "Transparency", "Trans", 0,  1,   0.05, "%.2f",  "TransOn")

-- Shop tab (Rate-limit fixed: pinned endpoint, GAP raised to 1.2s)[span_11](start_span)[span_11](end_span)
do
    local HttpService = game:GetService("HttpService")
    local Market      = game:GetService("MarketplaceService")
    local httpReq     = request or http_request or (syn and syn.request) or (http and http.request)
    local clip        = setclipboard or toclipboard

    local shopPage = addTab("🛒 Shop", false)

    local PAGE_SIZE = 30   
    local GAP       = 1.2  -- raised from 0.6s to 1.2s to prevent 429 rate limits[span_12](start_span)[span_12](end_span)
    local MODES = {
        { name = "Catalog" },                                  
        { name = "Models",  cat = "Model",  toolbox = 10 },
        { name = "Decals",  cat = "Decal",  toolbox = 13 },
        { name = "Audio",   cat = "Audio",  toolbox = 3  },
        { name = "Plugins", cat = "Plugin", toolbox = 38 },
    }

    local ACC = { [8]=true, [41]=true, [42]=true, [43]=true, [44]=true, [45]=true, [46]=true, [47]=true }
    local FILTERS = {
        { name = "All" },
        { name = "Accessories",     cat = "Accessories", types = ACC },
        { name = "Hats",            cat = "Accessories", sub = "HatAccessories",      types = { [8]=true } },
        { name = "Hair",            cat = "Accessories", sub = "HairAccessories",     types = { [41]=true } },
        { name = "Face",            cat = "Accessories", sub = "FaceAccessories",     types = { [42]=true } },
        { name = "Neck",            cat = "Accessories", sub = "NeckAccessories",     types = { [43]=true } },
        { name = "Shoulder",        cat = "Accessories", sub = "ShoulderAccessories", types = { [44]=true } },
        { name = "Front",           cat = "Accessories", sub = "FrontAccessories",    types = { [45]=true } },
        { name = "Back",            cat = "Accessories", sub = "BackAccessories",     types = { [46]=true } },
        { name = "Waist",           cat = "Accessories", sub = "WaistAccessories",    types = { [47]=true } },
        { name = "Classic Shirts",  cat = "Clothing", sub = "ClassicShirts",  types = { [11]=true } },
        { name = "Classic T-Shirts",cat = "Clothing", sub = "ClassicTShirts", types = { [2]=true } },
        { name = "Classic Pants",   cat = "Clothing", sub = "ClassicPants",   types = { [12]=true } },
        { name = "Gear",            cat = "Gear", types = { [19]=true } },
    }

    local PRICES = {
        { name = "Any price" },
        { name = "Free", query = "&MaxPrice=0" },
        { name = "Paid", query = "&MinPrice=1" },
    }

    local SORTS = {
        { name = "Relevance" },
        { name = "Best selling", q = "&SortType=2" },
        { name = "Newest",       q = "&SortType=3" },
        { name = "Price ↑",      q = "&SortType=4" },
        { name = "Price ↓",      q = "&SortType=5" },
    }

    local modeIdx, filterIdx, priceIdx, sortIdx, searchToken, selected = 1, 1, 1, 1, 0, nil
    local page, hasNext, cursors = 1, false, {}   
    local lastCode = "?"                           
    local lastReq  = 0                             
    local status                                   

    local function getJson(url, token)
        if not httpReq then return nil end
        for attempt = 1, 4 do
            local wait = lastReq + GAP - os.clock()
            if wait > 0 then task.wait(wait) end
            if token and token ~= searchToken then return nil end
            lastReq = os.clock()

            local ok, res = pcall(httpReq, { Url = url, Method = "GET" })
            if not ok or not res then lastCode = "no response" return nil end
            lastCode = tostring(res.StatusCode)

            if res.StatusCode == 429 then
                if attempt == 4 then return nil end
                local h = res.Headers
                local ra = tonumber(h and (h["retry-after"] or h["Retry-After"])) or (2 * attempt)
                ra = math.clamp(ra, 2, 10)
                if status and status.Parent then
                    status.Text = ("rate limited, retrying in %ds..."):format(ra)
                end
                task.wait(ra)
                if token and token ~= searchToken then return nil end
            else
                if res.StatusCode ~= 200 then return nil end
                local ok2, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
                return ok2 and data or nil
            end
        end
        return nil
    end

    local top = inst("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, shopPage)
    local modeBtn = inst("TextButton", {
        Size = UDim2.fromOffset(90, 30), BackgroundColor3 = ROW, Text = MODES[1].name,
        TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 13,
    }, top)
    inst("UIStroke", { Color = DIM, Thickness = 1 }, modeBtn)
    local goBtn = inst("TextButton", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(70, 30),
        BackgroundColor3 = RED, Text = "Search", TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 13,
    }, top)
    local box = inst("TextBox", {
        Position = UDim2.fromOffset(96, 0), Size = UDim2.new(1, -172, 1, 0), BackgroundColor3 = ROW,
        Text = "", PlaceholderText = "search the store...", PlaceholderColor3 = Color3.fromRGB(130, 130, 140),
        TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 13, ClearTextOnFocus = false,
    }, top)
    inst("UIStroke", { Color = DIM, Thickness = 1 }, box)

    local chips = inst("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
    }, shopPage)
    inst("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, chips)
    local chipBtns, priceBtns, sortBtns = {}, {}, {}

    local results = inst("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 1, -138),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, shopPage)
    inst("UIGridLayout", {
        CellSize = UDim2.fromOffset(104, 140), CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, results)

    status = label(results, "", WHITE, 13, Enum.Font.GothamMedium)
    status.Size = UDim2.fromOffset(300, 30) status.TextStrokeTransparency = 1 status.LayoutOrder = -1
    status.TextXAlignment = Enum.TextXAlignment.Left

    local pager = inst("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -38),
        Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
    }, shopPage)
    local function pagerBtn(text, anchorX, xPos)
        local b = inst("TextButton", {
            AnchorPoint = Vector2.new(anchorX, 0), Position = UDim2.new(xPos, 0, 0, 0), Size = UDim2.fromOffset(90, 28),
            BackgroundColor3 = ROW, Text = text, TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 13,
        }, pager)
        inst("UIStroke", { Color = DIM, Thickness = 1 }, b)
        return b
    end
    local prevBtn = pagerBtn("◀ Prev", 0, 0)
    local nextBtn = pagerBtn("Next ▶", 1, 1)
    local pageLbl = label(pager, "Page 1", WHITE, 13, Enum.Font.GothamMedium)
    pageLbl.Size = UDim2.fromScale(1, 1) pageLbl.TextStrokeTransparency = 1

    local bar = inst("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = ROW,
    }, shopPage)
    inst("UIStroke", { Color = DIM, Thickness = 1 }, bar)
    local selLabel = label(bar, "tap an item to copy its id", WHITE, 12, Enum.Font.GothamMedium)
    selLabel.Position = UDim2.fromOffset(8, 0) selLabel.Size = UDim2.new(1, -190, 1, 0)
    selLabel.TextXAlignment = Enum.TextXAlignment.Left selLabel.TextStrokeTransparency = 1
    selLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local function barBtn(text, xOff, color)
        local b = inst("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(84, 24),
            BackgroundColor3 = color, Text = text, TextColor3 = WHITE, Font = Enum.Font.GothamMedium, TextSize = 12,
        }, bar)
        inst("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
        return b
    end
    local buyBtn  = barBtn("Get / Buy", -6,  RED)
    local copyBtn = barBtn("Copy ID",   -96, Color3.fromRGB(70, 70, 80))

    buyBtn.Activated:Connect(function()
        if not selected then return end
        pcall(function()
            if selected.itemType == "Bundle" then
                Market:PromptBundlePurchase(lp, selected.id)
            else
                Market:PromptPurchase(lp, selected.id)
            end
        end)
    end)
    copyBtn.Activated:Connect(function()
        if selected and clip then
            clip(tostring(selected.id))
            selLabel.Text = "copied " .. selected.id
        end
    end)

    local function clearResults()
        for _, c in ipairs(results:GetChildren()) do
            if c:IsA("GuiButton") then c:Destroy() end
        end
        results.CanvasPosition = Vector2.zero
    end

    local function updatePager()
        pageLbl.Text = "Page " .. page
        prevBtn.TextTransparency = (page > 1) and 0 or 0.6
        nextBtn.TextTransparency = hasNext and 0 or 0.6
    end

    local function applyLayout()
        local showChips = MODES[modeIdx].cat == nil
        chips.Visible = showChips
        if showChips then
            results.Position = UDim2.fromOffset(0, 66)
            results.Size = UDim2.new(1, 0, 1, -138)
        else
            results.Position = UDim2.fromOffset(0, 36)
            results.Size = UDim2.new(1, 0, 1, -108)
        end
    end

    local function fmtPrice(pr, st)
        if pr == nil then return st or "Off sale" end
        if pr == 0 then return "Free" end
        return Config.RobuxIcon .. " " .. pr
    end

    local function setInfo(item, name, priceText)
        if name then item.name = name end
        if priceText then item.priceText = priceText end
        if item.nameLbl and item.nameLbl.Parent then
            item.nameLbl.Text = item.name or ("id " .. item.id)
            item.priceLbl.Text = item.priceText or ""
        end
    end

    local function rankByName(items, text)
        local words = {}
        for w in text:lower():gmatch("%S+") do words[#words + 1] = w end
        if #words == 0 then return end
        for i, it in ipairs(items) do
            local nm = (it.name or ""):lower()
            local s = 0
            for _, w in ipairs(words) do
                if nm:find(w, 1, true) then s += 1 end
            end
            it.score, it.idx = s, i
        end
        table.sort(items, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            return a.idx < b.idx
        end)
    end

    local function addCell(item, order)
        local cell = inst("TextButton", {
            LayoutOrder = order, BackgroundColor3 = ROW, Text = "", AutoButtonColor = true,
        }, results)
        inst("UIStroke", { Color = DIM, Thickness = 1 }, cell)
        local kind = item.itemType == "Bundle" and "BundleThumbnail" or "Asset"
        inst("ImageLabel", {
            Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 82), BackgroundTransparency = 1,
            Image = ("rbxthumb://type=%s&id=%d&w=150&h=150"):format(kind, item.id),
        }, cell)

        local n = label(cell, item.name or ("id " .. item.id), WHITE, 11, Enum.Font.GothamMedium)
        n.Position = UDim2.fromOffset(4, 88) n.Size = UDim2.new(1, -8, 0, 28)
        n.TextWrapped = true n.TextTruncate = Enum.TextTruncate.AtEnd
        n.TextXAlignment = Enum.TextXAlignment.Left n.TextYAlignment = Enum.TextYAlignment.Top
        n.TextStrokeTransparency = 1

        local p = label(cell, item.priceText or "", Color3.fromRGB(235, 80, 80), 11, Enum.Font.GothamBold)
        p.Position = UDim2.fromOffset(4, 118) p.Size = UDim2.new(1, -8, 0, 16)
        p.TextXAlignment = Enum.TextXAlignment.Left p.TextStrokeTransparency = 1

        item.nameLbl, item.priceLbl = n, p

        cell.Activated:Connect(function()
            selected = item
            local nm = item.name or "?"
            if clip then
                clip(tostring(item.id))
                selLabel.Text = ("copied %d  |  %s"):format(item.id, nm)
                p.Text = "✔ copied"
                task.delay(1.2, function()
                    if p.Parent then p.Text = item.priceText or "" end
                end)
            else
                selLabel.Text = ("%s  [%d]  (no clipboard on this executor)"):format(nm, item.id)
            end
        end)
    end

    local function fillNames(items, token)
        local ids = {}
        for _, it in ipairs(items) do ids[#ids + 1] = it.id end
        local d = getJson("https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=" .. table.concat(ids, ","), token)
        local byId = {}
        for _, e in ipairs(d and d.data or {}) do
            local a = e.asset
            if a and a.id then byId[a.id] = a.name end
        end
        if token ~= searchToken then return end
        for _, it in ipairs(items) do
            if byId[it.id] then setInfo(it, byId[it.id]) end
        end

        local n = 0
        for _, it in ipairs(items) do
            if token ~= searchToken then return end
            if not it.name and n < 8 then
                n += 1
                local e = getJson(("https://economy.roblox.com/v2/assets/%d/details"):format(it.id), token)
                if e and e.Name then
                    setInfo(it, e.Name, e.IsForSale and fmtPrice(e.PriceInRobux) or "Off sale")
                else
                    local ok, info = pcall(Market.GetProductInfo, Market, it.id)
                    if ok and info then
                        setInfo(it, info.Name, fmtPrice(info.PriceInRobux))
                    end
                end
            end
        end
    end

    local function search()
        searchToken += 1
        local token = searchToken
        clearResults()
        selected = nil
        selLabel.Text = "tap an item to copy its id"
        hasNext = false
        updatePager()
        if not httpReq then
            status.Text = "your executor has no request() function"
            return
        end
        status.Text = "loading..."
        task.spawn(function()
            local text = (box.Text:gsub("^%s+", ""):gsub("%s+$", ""))
            local kw = HttpService:UrlEncode(text)
            local mode = MODES[modeIdx]
            local items, more, needNames, limited = {}, false, false, false

            if mode.cat then
                local url = ("https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=%s&query=%s&maxPageSize=%d")
                    :format(mode.cat, kw, PAGE_SIZE)
                if cursors[page] and cursors[page] ~= "" then
                    url ..= "&pageToken=" .. HttpService:UrlEncode(cursors[page])
                end
                local d = getJson(url, token)
                if lastCode == "429" then limited = true end
                for _, e in ipairs(d and d.creatorStoreAssets or {}) do
                    local a = e.asset
                    if a and a.id then
                        items[#items + 1] = { id = a.id, itemType = "Asset", name = a.name, priceText = "" }
                    end
                end
                if #items > 0 then
                    if d.nextPageToken and d.nextPageToken ~= "" then
                        cursors[page + 1] = d.nextPageToken
                        more = true
                    end
                elseif not limited then
                    local d2 = getJson(("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=%d&pageNumber=%d&sortType=Relevance")
                        :format(mode.toolbox, kw, PAGE_SIZE, page - 1), token)
                    if lastCode == "429" then limited = true end
                    for _, e in ipairs(d2 and d2.data or {}) do
                        items[#items + 1] = { id = e.id, itemType = "Asset", priceText = "" }
                    end
                    more = #items >= PAGE_SIZE
                    needNames = true
                end
            else
                -- Pinned catalog endpoint implementation (no aggressive multi-attempt fallback loop)[span_13](start_span)[span_13](end_span)
                local f, pf, sf = FILTERS[filterIdx], PRICES[priceIdx], SORTS[sortIdx]
                local api  = "https://catalog.roblox.com/v1/search/items/details?Keyword=" .. kw
                local sq, pq = sf.q or "", pf.query or ""
                local catQ = f.cat and ("&Category=" .. f.cat) or ""
                local subQ = f.sub and ("&Subcategory=" .. f.sub) or ""
                local url = api .. "&Limit=" .. PAGE_SIZE .. "&SalesTypeFilter=1" .. sq .. pq .. catQ .. subQ

                local cursor = cursors[page]
                if cursor and cursor ~= "" then
                    url ..= "&Cursor=" .. HttpService:UrlEncode(cursor)
                end

                local d = getJson(url, token)
                if lastCode == "429" then limited = true end
                if d then
                    for _, e in ipairs(d.data or {}) do
                        local pr = e.price
                        if pr == nil then pr = e.lowestPrice end
                        local keep = true
                        if priceIdx == 2 and pr ~= nil and pr > 0 then keep = false end
                        if priceIdx == 3 and pr ~= nil and pr == 0 then keep = false end
                        if keep then
                            items[#items + 1] = {
                                id = e.id, itemType = e.itemType, name = e.name,
                                priceText = fmtPrice(pr, e.priceStatus),
                            }
                        end
                    end
                    cursor = d.nextPageCursor
                end

                if cursor and cursor ~= "" then
                    cursors[page + 1] = cursor
                    more = true
                end
            end

            if token ~= searchToken then return end
            hasNext = more
            updatePager()
            if #items == 0 then
                if limited or lastCode == "429" then
                    status.Text = "roblox rate limited you (429). wait ~30s, then search again"
                else
                    status.Text = "no results (http " .. lastCode .. ")"
                end
                return
            end
            status.Text = ""
            if not needNames and (mode.cat or sortIdx == 1) then rankByName(items, text) end
            for i, it in ipairs(items) do addCell(it, i) end
            if needNames then fillNames(items, token) end
        end)
    end

    local function newSearch()
        page, cursors = 1, {}
        search()
    end

    local function refreshChips()
        for i, b in ipairs(chipBtns) do b.BackgroundColor3 = (i == filterIdx) and RED or ROW end
        for i, b in ipairs(priceBtns) do b.BackgroundColor3 = (i == priceIdx) and RED or ROW end
        for i, b in ipairs(sortBtns) do b.BackgroundColor3 = (i == sortIdx) and RED or ROW end
    end
    local function makeChip(text, order, onTap)
        local b = inst("TextButton", {
            LayoutOrder = order, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = ROW, Text = text, TextColor3 = WHITE,
            Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false,
        }, chips)
        inst("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, b)
        inst("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
        inst("UIStroke", { Color = DIM, Thickness = 1 }, b)
        b.Activated:Connect(onTap)
        return b
    end
    for i, p in ipairs(PRICES) do
        priceBtns[i] = makeChip(p.name, i, function()
            if priceIdx == i then return end
            priceIdx = i
            refreshChips()
            newSearch()
        end)
    end
    for i, s in ipairs(SORTS) do
        sortBtns[i] = makeChip(s.name, 10 + i, function()
            if sortIdx == i then return end
            sortIdx = i
            refreshChips()
            newSearch()
        end)
    end
    for i, f in ipairs(FILTERS) do
        chipBtns[i] = makeChip(f.name, 30 + i, function()
            if filterIdx == i then return end
            filterIdx = i
            refreshChips()
            newSearch()
        end)
    end
    refreshChips()
    applyLayout()

    modeBtn.Activated:Connect(function()
        modeIdx = modeIdx % #MODES + 1
        modeBtn.Text = MODES[modeIdx].name
        applyLayout()
        newSearch()
    end)
    goBtn.Activated:Connect(newSearch)
    box.FocusLost:Connect(function(enter) if enter then newSearch() end end)
    prevBtn.Activated:Connect(function() if page > 1 then page -= 1 search() end end)
    nextBtn.Activated:Connect(function() if hasNext then page += 1 search() end end)
    updatePager()
end

-- Settings tab[span_14](start_span)[span_14](end_span)
local setPage = addTab("⚙️ Settings", false)
listPage(setPage, 8)
slider(setPage, 1, "ESP range",      "MaxDistance", 100, 5000, 50, "%d")
slider(setPage, 2, "Counter radius", "CountRadius", 50, 2000, 50, "%d")
local unloadBtn = bigButton(setPage, 3, "Unload hack", ROW, UDim2.new(1, 0, 0, 40))

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

local openBtn = inst("TextButton", {
    Position = UDim2.new(0, 8, 0.5, -20), Size = UDim2.fromOffset(44, 40),
    BackgroundColor3 = BG, Text = "HX", TextColor3 = RED,
    Font = Enum.Font.GothamBold, TextSize = 14,
}, gui)
inst("UICorner", { CornerRadius = UDim.new(0, 8) }, openBtn)
inst("UIStroke", { Color = RED, Thickness = 1.5 }, openBtn)
openBtn.Activated:Connect(function() window.Visible = not window.Visible end)

---------------------------------------------------------------- esp objects[span_15](start_span)[span_15](end_span)
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

---------------------------------------------------------------- helpers[span_16](start_span)[span_16](end_span)
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

---------------------------------------------------------------- character mods[span_17](start_span)[span_17](end_span)
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

---------------------------------------------------------------- main loop[span_18](start_span)[span_18](end_span)
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

---------------------------------------------------------------- keys / unload[span_19](start_span)[span_19](end_span)
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

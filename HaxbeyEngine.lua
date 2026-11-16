-- Made by ByHAXBEY(Furkan): https://t.me/zxroorj
-- haxbey engine | Rayfield UI
-- Not run or tested.
--
-- Remote search:
--   Searches the entire client-visible game instance tree.
--   Does not read server-only files, ServerStorage contents, or server scripts.
--   Type comma-separated or newline-separated remote names in Character.
--   Exact matching is the default. All matching instances are targeted.
--   Optional full paths can be entered instead of names.
--   Newly replicated remotes are indexed automatically.
--
-- BlockSnap:
--   Outgoing: drops FireServer / InvokeServer calls to matched remotes.
--   Incoming: disables accessible OnClientEvent listeners on matched events.
--   Refreshes matching/listeners every 1.5 seconds.
--   Changing the search restores listeners on remotes no longer matched.
--   Off/unload restores owned listeners and attempts hook removal.
--
-- This does not identify what a remote actually does.
-- Blocking a name does not guarantee it controls rubberbanding.
-- Direct server position replication is unaffected.
-- Server-side movement checks are unaffected.
-- Executor hook/listener support varies.
-- No remote spy is embedded.
-- Catalog/store endpoint parameters remain unverified.

local Config = {
    Enabled = false,
    TeamCheck = false,
    Box = false,
    Health = false,
    Name = false,
    Item = false,
    Dist = false,
    Bones = false,
    RootDot = false,
    Warn = false,
    Counter = false,
    Fps = false,

    SpeedOn = false,
    Speed = 16,

    BlockSnap = false,
    SnapRemoteNames = "", -- FILL: or type names in Character > Remote search
    SnapExactMatch = true,
    SnapIgnoreCase = true,
    SnapBlockOutgoing = true,
    SnapBlockIncoming = true,
    SnapCheckInterval = 1.5,

    JumpOn = false,
    Jump = 50,
    GravOn = false,
    Grav = 196,
    HeadOn = false,
    Head = 1,
    TransOn = false,
    Trans = 0,

    AimEnabled = false,
    ShowFov = false,
    SilentAim = false,
    CharLock = false,
    CamLock = false,
    VisCheck = false,
    PredictionOn = false,
    PredictionVal = 0.1,
    AimFov = 150,
    AimDist = 500,
    AimSmooth = 1,

    MaxDistance = 2000,
    CountRadius = 500,
    TextSize = 13,
    BoxColor = Color3.fromRGB(255, 50, 50),
    NameColor = Color3.fromRGB(204, 170, 0),
    ItemColor = Color3.fromRGB(0, 60, 200),
    DistColor = Color3.new(1, 1, 1),
    VisColor = Color3.fromRGB(0, 255, 0),
    HiddenColor = Color3.fromRGB(255, 0, 0),

    WarnAngleDeg = 8,
    WarnMaxDist = 500,
    WarnNeedLOS = true,
    WarnY = 0.05,
    WarnTextSize = 30,
    WarnFlip = 0.8,
    WarnColorA = Color3.fromRGB(255, 220, 0),
    WarnColorB = Color3.fromRGB(255, 0, 0),
    WarnText = "ENEMY IS AIMING AT YOU",
    HudY = 0.12,
    HudTextSize = 18,

    MenuTitle = "haxbey engine",
    TitleIcon = "", -- FILL: optional unicode
    RobuxIcon = "R$", -- FILL: optional unicode
    KickMessage = "left via haxbey engine",
    OpenImage = "rbxassetid://138765108919147",
    OpenWidth = 120,
    MenuKey = Enum.KeyCode.RightShift,
    ExitKey = Enum.KeyCode.End,

    HttpGap = 1.2,
    HttpRetries = 4,
    RayfieldUrl = "https://sirius.menu/rayfield",
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")

local lp = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
local httpRequest = request or http_request
    or (syn and syn.request)
    or (http and http.request)
local clipboard = setclipboard or toclipboard

if type(env.HaxbeyEngineUnload) == "function" then
    pcall(env.HaxbeyEngineUnload)
end

assert(Drawing and Drawing.new, "haxbey engine requires Drawing.new")
assert(loadstring, "haxbey engine requires loadstring")

local RedTheme = {
    TextColor = Color3.fromRGB(240, 240, 240),
    Background = Color3.fromRGB(15, 15, 18),
    Topbar = Color3.fromRGB(30, 17, 20),
    Shadow = Color3.fromRGB(8, 8, 10),
    NotificationBackground = Color3.fromRGB(22, 22, 25),
    NotificationActionsBackground = Color3.fromRGB(45, 30, 35),
    TabBackground = Color3.fromRGB(35, 35, 40),
    TabStroke = Color3.fromRGB(55, 55, 60),
    TabBackgroundSelected = Color3.fromRGB(180, 40, 45),
    TabTextColor = Color3.fromRGB(220, 220, 220),
    SelectedTabTextColor = Color3.new(1, 1, 1),
    ElementBackground = Color3.fromRGB(27, 27, 31),
    ElementBackgroundHover = Color3.fromRGB(35, 35, 40),
    SecondaryElementBackground = Color3.fromRGB(23, 23, 27),
    ElementStroke = Color3.fromRGB(55, 55, 60),
    SecondaryElementStroke = Color3.fromRGB(45, 45, 50),
    SliderBackground = Color3.fromRGB(105, 30, 35),
    SliderProgress = Color3.fromRGB(205, 45, 50),
    SliderStroke = Color3.fromRGB(230, 65, 70),
    ToggleBackground = Color3.fromRGB(30, 30, 35),
    ToggleEnabled = Color3.fromRGB(205, 45, 50),
    ToggleDisabled = Color3.fromRGB(80, 80, 85),
    ToggleEnabledStroke = Color3.fromRGB(230, 65, 70),
    ToggleDisabledStroke = Color3.fromRGB(100, 100, 105),
    ToggleEnabledOuterStroke = Color3.fromRGB(80, 25, 30),
    ToggleDisabledOuterStroke = Color3.fromRGB(50, 50, 55),
    DropdownSelected = Color3.fromRGB(55, 25, 30),
    DropdownUnselected = Color3.fromRGB(30, 30, 35),
    InputBackground = Color3.fromRGB(25, 25, 30),
    InputStroke = Color3.fromRGB(65, 65, 70),
    PlaceholderColor = Color3.fromRGB(150, 150, 155),
}

local Rayfield = loadstring(game:HttpGet(Config.RayfieldUrl))()

local alive = true
local connections, drawings, tracked, toggles = {}, {}, {}, {}
local browserStates = {}
local savedProperties, changedTransparency = {}, {}
local originalGravity, lastCharacter, overlay
local cam = workspace.CurrentCamera
local renderName = "haxbey_engine_main"

local Snap = {
    registry = {},
    matches = {},
    disabled = {},
    terms = {},
    hookInstalled = false,
    previousNamecall = nil,
    hook = nil,
    hookError = nil,
    timer = 0,
    outgoingBlocked = 0,
    paragraph = nil,
    results = nil,
    selectedPath = nil,
    lastOptions = "",
    lastStatus = "",
    refreshQueued = false,
}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    connections[#connections + 1] = connection
    return connection
end

local function instance(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function draw(class, properties)
    local object = Drawing.new(class)
    drawings[object] = true
    for key, value in pairs(properties) do
        object[key] = value
    end
    return object
end

local function removeDrawing(object)
    if drawings[object] then
        drawings[object] = nil
        pcall(function()
            object:Remove()
        end)
    end
end

local function notify(title, content)
    if alive then
        pcall(function()
            Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = 5,
            })
        end)
    end
end

local function firstOption(value)
    if type(value) == "table" then
        return value[1]
    end
    return value
end

local function copy(text)
    if not clipboard then
        notify("Clipboard unavailable", tostring(text))
        return false
    end
    local ok, err = pcall(clipboard, tostring(text))
    if not ok then
        notify("Clipboard error", tostring(err))
    end
    return ok
end

local function restoreAllProperties()
    for object, properties in pairs(savedProperties) do
        for property, value in pairs(properties) do
            pcall(function()
                object[property] = value
            end)
        end
    end
    savedProperties = {}

    for object, value in pairs(changedTransparency) do
        pcall(function()
            object.Transparency = value
        end)
    end
    changedTransparency = {}

    if originalGravity ~= nil then
        pcall(function()
            workspace.Gravity = originalGravity
        end)
        originalGravity = nil
    end
end

---------------------------------------------------------------- REMOTE SEARCH / BLOCKING

local function isRemote(object)
    return object:IsA("RemoteEvent")
        or object:IsA("RemoteFunction")
        or object:IsA("UnreliableRemoteEvent")
end

local function fullPath(object)
    local ok, path = pcall(object.GetFullName, object)
    return ok and path or object.Name
end

local function normalize(text)
    return Config.SnapIgnoreCase and text:lower() or text
end

local function parseTerms()
    local terms, seen = {}, {}

    for term in Config.SnapRemoteNames:gmatch("[^,;\r\n]+") do
        term = term:match("^%s*(.-)%s*$")
        term = term:gsub("^game%.", "")
        term = normalize(term)

        if term ~= "" and not seen[term] then
            seen[term] = true
            terms[#terms + 1] = term
        end
    end

    Snap.terms = terms
end

local function matchesRemote(remote)
    if #Snap.terms == 0 then
        return false
    end

    local name = normalize(remote.Name)
    local path = normalize(fullPath(remote))

    for _, term in ipairs(Snap.terms) do
        if Config.SnapExactMatch then
            if name == term or path == term then
                return true
            end
        elseif name:find(term, 1, true) or path:find(term, 1, true) then
            return true
        end
    end

    return false
end

local function restoreRemoteListeners(remote)
    local owned = Snap.disabled[remote]
    if not owned then
        return
    end

    for connection in pairs(owned) do
        pcall(function()
            connection:Enable()
        end)
    end

    Snap.disabled[remote] = nil
end

local function restoreAllSnapListeners()
    local remotes = {}
    for remote in pairs(Snap.disabled) do
        remotes[#remotes + 1] = remote
    end
    for _, remote in ipairs(remotes) do
        restoreRemoteListeners(remote)
    end
end

local function connectionEnabled(connection)
    local ok, value = pcall(function()
        return connection.Enabled
    end)
    if ok and type(value) == "boolean" then
        return value
    end

    ok, value = pcall(function()
        return connection.State
    end)
    if ok and type(value) == "boolean" then
        return value
    end

    return nil
end

local function installSnapHook()
    if Snap.hookInstalled then
        return true
    end

    if type(hookmetamethod) ~= "function"
        or type(getnamecallmethod) ~= "function"
    then
        Snap.hookError = "hookmetamethod/getnamecallmethod unavailable"
        return false
    end

    local previous

    local function interceptor(self, ...)
        if alive and Config.BlockSnap and Config.SnapBlockOutgoing
            and Snap.matches[self]
        then
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                Snap.outgoingBlocked += 1
                return nil
            end
        end

        return previous(self, ...)
    end

    local closure = newcclosure and newcclosure(interceptor) or interceptor
    local ok, result = pcall(hookmetamethod, game, "__namecall", closure)

    if not ok or type(result) ~= "function" then
        Snap.hookError = tostring(result)
        return false
    end

    previous = result
    Snap.previousNamecall = result
    Snap.hook = closure
    Snap.hookInstalled = true
    Snap.hookError = nil
    return true
end

local function removeSnapHook()
    if not Snap.hookInstalled then
        return true
    end

    local ok, err = pcall(
        hookmetamethod, game, "__namecall", Snap.previousNamecall
    )

    if ok then
        Snap.hookInstalled = false
        Snap.previousNamecall = nil
        Snap.hook = nil
        Snap.hookError = nil
        return true
    end

    -- Blocking gates are disabled by callers before restoration.
    Snap.hookError = tostring(err)
    return false, tostring(err)
end

local function disableRemoteListeners(remote)
    if not (
        remote:IsA("RemoteEvent")
        or remote:IsA("UnreliableRemoteEvent")
    ) then
        return 0, 0
    end

    local ok, listeners = pcall(getconnections, remote.OnClientEvent)
    if not ok or type(listeners) ~= "table" then
        return 0, 1
    end

    local owned = Snap.disabled[remote]
    if not owned then
        owned = {}
        Snap.disabled[remote] = owned
    end

    local skipped = 0

    for _, connection in pairs(listeners) do
        if owned[connection] then
            pcall(function()
                connection:Disable()
            end)
        else
            local enabled = connectionEnabled(connection)

            if enabled == true then
                local disabled = pcall(function()
                    connection:Disable()
                end)
                if disabled then
                    owned[connection] = true
                else
                    skipped += 1
                end
            elseif enabled == nil then
                -- Do not modify listeners whose initial state is unknown.
                skipped += 1
            end
        end
    end

    local count = 0
    for _ in pairs(owned) do
        count += 1
    end
    return count, skipped
end

local function updateSnapUI(indexedCount, paths, listenerCount, skipped)
    if Snap.results then
        local signature = table.concat(paths, "\n")
        if signature ~= Snap.lastOptions then
            Snap.lastOptions = signature
            Snap.selectedPath = nil
            pcall(function()
                Snap.results:Refresh(
                    #paths > 0 and paths or { "No matching remotes" }
                )
            end)
        end
    end

    local outgoing
    if not Config.BlockSnap or not Config.SnapBlockOutgoing then
        outgoing = "off"
    elseif Snap.hookInstalled then
        outgoing = "active"
    else
        outgoing = "unavailable: " .. tostring(Snap.hookError)
    end

    local incoming
    if not Config.BlockSnap or not Config.SnapBlockIncoming then
        incoming = "off"
    elseif type(getconnections) ~= "function" then
        incoming = "getconnections unavailable"
    else
        incoming = ("%d owned listeners disabled; %d skipped/errors")
            :format(listenerCount, skipped)
    end

    local text = (
        "%s | Indexed remotes: %d | Matches: %d\n"
        .. "Outgoing: %s | Dropped calls: %d\nIncoming: %s"
    ):format(
        Config.BlockSnap and "BLOCKING ENABLED" or "SEARCH ONLY",
        indexedCount,
        #paths,
        outgoing,
        Snap.outgoingBlocked,
        incoming
    )

    if #Snap.terms == 0 then
        text ..= "\nEnter at least one remote name or full path."
    end

    if text ~= Snap.lastStatus then
        Snap.lastStatus = text
        if alive and Snap.paragraph then
            pcall(function()
                Snap.paragraph:Set({
                    Title = "Remote search status",
                    Content = text,
                })
            end)
        end
    end
end

local function refreshSnap()
    if not alive then
        return
    end

    parseTerms()

    local nextMatches = {}
    local paths = {}
    local indexedCount = 0

    for remote in pairs(Snap.registry) do
        if remote:IsDescendantOf(game) then
            indexedCount += 1
            if matchesRemote(remote) then
                nextMatches[remote] = true
                paths[#paths + 1] = fullPath(remote)
            end
        else
            Snap.registry[remote] = nil
        end
    end

    for remote in pairs(Snap.matches) do
        if not nextMatches[remote] then
            restoreRemoteListeners(remote)
        end
    end

    Snap.matches = nextMatches
    table.sort(paths)

    local listenerCount, skipped = 0, 0

    if Config.BlockSnap and #paths > 0 then
        if Config.SnapBlockOutgoing then
            installSnapHook()
        end

        if Config.SnapBlockIncoming and type(getconnections) == "function" then
            for remote in pairs(Snap.matches) do
                local count, misses = disableRemoteListeners(remote)
                listenerCount += count
                skipped += misses
            end
        else
            restoreAllSnapListeners()
        end
    else
        restoreAllSnapListeners()
    end

    updateSnapUI(indexedCount, paths, listenerCount, skipped)
end

local function queueSnapRefresh()
    if Snap.refreshQueued or not alive then
        return
    end

    Snap.refreshQueued = true
    task.defer(function()
        Snap.refreshQueued = false
        if not alive then
            return
        end
        local ok, err = pcall(refreshSnap)
        if not ok then
            warn("[haxbey engine] Remote search error: " .. tostring(err))
            notify("Remote search error", tostring(err))
        end
    end)
end

local function scanAllRemotes()
    local registry = {}
    for _, object in ipairs(game:GetDescendants()) do
        if isRemote(object) then
            registry[object] = true
        end
    end
    Snap.registry = registry
    queueSnapRefresh()
end

local function setBlockSnap(value)
    Config.BlockSnap = value == true
    Snap.timer = 0

    if not Config.BlockSnap then
        restoreAllSnapListeners()
        local ok, err = removeSnapHook()
        if not ok then
            notify(
                "Hook cleanup",
                "Blocking is off; hook remains pass-through: " .. tostring(err)
            )
        end
    end

    queueSnapRefresh()
end

---------------------------------------------------------------- CLEANUP

local unload
unload = function()
    if not alive then
        return
    end

    Config.BlockSnap = false
    Snap.matches = {}
    alive = false

    restoreAllSnapListeners()
    local hookRemoved, hookError = removeSnapHook()
    if not hookRemoved then
        warn("[haxbey engine] Hook is pass-through; restoration failed: "
            .. tostring(hookError))
    end

    for _, state in ipairs(browserStates) do
        state.token += 1
    end

    RunService:UnbindFromRenderStep(renderName)

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(connections)

    restoreAllProperties()

    local remaining = {}
    for object in pairs(drawings) do
        remaining[#remaining + 1] = object
    end
    for _, object in ipairs(remaining) do
        removeDrawing(object)
    end

    table.clear(tracked)
    table.clear(Snap.registry)

    if overlay then
        pcall(function()
            overlay:Destroy()
        end)
    end
    pcall(function()
        Rayfield:Destroy()
    end)

    if env.HaxbeyEngineUnload == unload then
        env.HaxbeyEngineUnload = nil
    end
end

env.HaxbeyEngineUnload = unload

---------------------------------------------------------------- WINDOW

local title = Config.MenuTitle
if Config.TitleIcon ~= "" then
    title ..= " " .. Config.TitleIcon
end

local Window = Rayfield:CreateWindow({
    Name = title,
    LoadingTitle = "haxbey engine",
    LoadingSubtitle = "by ByHAXBEY (Furkan)",
    Theme = RedTheme,
    ToggleUIKeybind = Config.MenuKey,
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = false },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = false,
    },
    KeySystem = false,
})

local Tabs = {
    ESP = Window:CreateTab("ESP", 4483362458),
    Char = Window:CreateTab("Character", 4483362458),
    Aim = Window:CreateTab("Aim", 4483362458),
    Catalog = Window:CreateTab("Catalog", 4483362458),
    Store = Window:CreateTab("Store", 4483362458),
    Settings = Window:CreateTab("Config", 4483362458),
}

local function toggle(tab, name, key, callback)
    local control = tab:CreateToggle({
        Name = name,
        CurrentValue = Config[key],
        Flag = "HX_" .. key,
        Callback = function(value)
            Config[key] = value
            if callback then
                callback(value)
            end
        end,
    })
    toggles[key] = control
    return control
end

local function slider(tab, name, key, minimum, maximum, increment, suffix)
    return tab:CreateSlider({
        Name = name,
        Range = { minimum, maximum },
        Increment = increment,
        Suffix = suffix or "",
        CurrentValue = Config[key],
        Flag = "HX_" .. key,
        Callback = function(value)
            Config[key] = value
        end,
    })
end

---------------------------------------------------------------- OVERLAY

local overlayParent = CoreGui
if gethui then
    local ok, result = pcall(gethui)
    if ok and result then
        overlayParent = result
    end
end

overlay = instance("ScreenGui", {
    Name = "HaxbeyEngineOverlay",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 998,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, overlayParent)

local function textLabel(parent, text, color, size)
    return instance("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = color,
        TextSize = size,
        Font = Enum.Font.GothamBold,
        TextStrokeTransparency = 0.3,
        TextStrokeColor3 = Color3.new(),
    }, parent)
end

local hud = instance("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.fromScale(0.5, Config.HudY),
    Size = UDim2.fromOffset(0, 0),
    AutomaticSize = Enum.AutomaticSize.XY,
    BackgroundTransparency = 1,
}, overlay)

instance("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, hud)

local function pill(order)
    local frame = instance("Frame", {
        LayoutOrder = order,
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Color3.fromRGB(35, 20, 23),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Visible = false,
    }, hud)
    instance("UICorner", { CornerRadius = UDim.new(0, 8) }, frame)
    instance("UIStroke", {
        Color = Color3.fromRGB(185, 40, 45),
        Thickness = 1.5,
    }, frame)
    instance("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
    }, frame)
    local text = textLabel(frame, "", Color3.new(1, 1, 1), Config.HudTextSize)
    text.AutomaticSize = Enum.AutomaticSize.XY
    text.Size = UDim2.fromOffset(0, 0)
    text.TextStrokeTransparency = 1
    return frame, text
end

local countPill, countText = pill(1)
local fpsPill, fpsText = pill(2)

local warning = textLabel(
    overlay, Config.WarnText, Config.WarnColorA, Config.WarnTextSize
)
warning.AnchorPoint = Vector2.new(0.5, 0)
warning.Position = UDim2.fromScale(0.5, Config.WarnY)
warning.Size = UDim2.fromOffset(0, 0)
warning.AutomaticSize = Enum.AutomaticSize.XY
warning.Visible = false

local openHeight = math.floor(Config.OpenWidth * 122 / 596 + 0.5)
local openButton = instance("ImageButton", {
    Position = UDim2.new(0, 8, 0.5, -openHeight / 2),
    Size = UDim2.fromOffset(Config.OpenWidth, openHeight),
    BackgroundColor3 = Color3.fromRGB(110, 25, 30),
    BackgroundTransparency = 0.15,
    Image = Config.OpenImage,
    ScaleType = Enum.ScaleType.Fit,
    AutoButtonColor = true,
}, overlay)
local openText = textLabel(openButton, "HAXBEY", Color3.new(1, 1, 1), 11)
openText.Size = UDim2.fromScale(1, 1)

connect(openButton.Activated, function()
    if Rayfield.SetVisibility and Rayfield.IsVisible then
        pcall(function()
            Rayfield:SetVisibility(not Rayfield:IsVisible())
        end)
    else
        notify("Menu", "Use Rayfield's mobile reopen control.")
    end
end)

---------------------------------------------------------------- ESP UI

Tabs.ESP:CreateSection("Master controls")

local espKeys = {
    "Enabled", "Box", "Health", "Name", "Item", "Dist",
    "Bones", "RootDot", "Warn", "Counter", "Fps",
}

local function setAll(value)
    for _, key in ipairs(espKeys) do
        Config[key] = value
        if toggles[key] then
            toggles[key]:Set(value)
        end
    end
end

Tabs.ESP:CreateButton({
    Name = "ESP ALL ON",
    Callback = function()
        setAll(true)
    end,
})
Tabs.ESP:CreateButton({
    Name = "ESP ALL OFF",
    Callback = function()
        setAll(false)
    end,
})

for _, entry in ipairs({
    { "ESP master", "Enabled" },
    { "Team check", "TeamCheck" },
    { "Corner boxes", "Box" },
    { "Health bars", "Health" },
    { "Player names", "Name" },
    { "Held item", "Item" },
    { "Distance", "Dist" },
    { "Skeleton", "Bones" },
    { "Root dot", "RootDot" },
    { "Aim warning", "Warn" },
    { "Enemy counter", "Counter" },
    { "FPS", "Fps" },
}) do
    toggle(Tabs.ESP, entry[1], entry[2])
end

---------------------------------------------------------------- CHARACTER / REMOTE UI

Tabs.Char:CreateSection("Movement")
toggle(Tabs.Char, "Enable walk speed", "SpeedOn")
slider(Tabs.Char, "Walk speed", "Speed", 16, 150, 1, "studs/s")

Tabs.Char:CreateSection("Remote search")

Tabs.Char:CreateInput({
    Name = "Remote names or full paths",
    CurrentValue = Config.SnapRemoteNames,
    PlaceholderText = "onPunishment, AnotherRemote",
    RemoveTextAfterFocusLost = false,
    Flag = "HX_SnapRemoteNames",
    Callback = function(value)
        Config.SnapRemoteNames = tostring(value)
        queueSnapRefresh()
    end,
})

toggle(Tabs.Char, "Exact name / full-path matching", "SnapExactMatch", queueSnapRefresh)
toggle(Tabs.Char, "Ignore uppercase / lowercase", "SnapIgnoreCase", queueSnapRefresh)

Snap.paragraph = Tabs.Char:CreateParagraph({
    Title = "Remote search status",
    Content = "Enter remote names, then press Scan all client-visible remotes.",
})

Snap.results = Tabs.Char:CreateDropdown({
    Name = "Matching remote paths",
    Options = { "No matching remotes" },
    CurrentOption = { "No matching remotes" },
    MultipleOptions = false,
    Flag = "HX_SnapRemoteResults",
    Callback = function(value)
        local path = firstOption(value)
        if path and path ~= "No matching remotes" then
            Snap.selectedPath = path
        end
    end,
})

Tabs.Char:CreateButton({
    Name = "Scan all client-visible remotes",
    Callback = scanAllRemotes,
})

Tabs.Char:CreateButton({
    Name = "Copy selected remote path",
    Callback = function()
        if Snap.selectedPath then
            copy(Snap.selectedPath)
        else
            notify("No selection", "Select a matching remote path first.")
        end
    end,
})

Tabs.Char:CreateButton({
    Name = "Copy all matching remote paths",
    Callback = function()
        local paths = {}
        for remote in pairs(Snap.matches) do
            paths[#paths + 1] = fullPath(remote)
        end
        table.sort(paths)
        if #paths > 0 then
            copy(table.concat(paths, "\n"))
        else
            notify("No matches", "Search for a remote name first.")
        end
    end,
})

toggle(Tabs.Char, "Block outgoing remote calls", "SnapBlockOutgoing", function(value)
    if not value then
        removeSnapHook()
    end
    queueSnapRefresh()
end)

toggle(Tabs.Char, "Disable incoming event listeners", "SnapBlockIncoming", function(value)
    if not value then
        restoreAllSnapListeners()
    end
    queueSnapRefresh()
end)

toggle(Tabs.Char, "BlockSnap master", "BlockSnap", setBlockSnap)

Tabs.Char:CreateParagraph({
    Title = "Search and blocking behavior",
    Content = "Names may be separated by commas, semicolons, or newlines. "
        .. "All matching remotes are targeted. Turn exact matching off "
        .. "for substring searches. Full paths narrow duplicate names. "
        .. "New remotes are indexed automatically. Searches cover only "
        .. "instances available to this client, not server-only files.",
})

Tabs.Char:CreateSection("Jump / gravity")
toggle(Tabs.Char, "Enable jump power", "JumpOn")
slider(Tabs.Char, "Jump power", "Jump", 50, 250, 1)
toggle(Tabs.Char, "Enable gravity", "GravOn")
slider(Tabs.Char, "Gravity", "Grav", 20, 196, 1)

Tabs.Char:CreateSection("Appearance")
toggle(Tabs.Char, "Enable head size", "HeadOn")
slider(Tabs.Char, "Head size", "Head", 1, 5, 0.1, "x")
toggle(Tabs.Char, "Enable transparency", "TransOn")
slider(Tabs.Char, "Transparency", "Trans", 0, 1, 0.05)

---------------------------------------------------------------- AIM UI

Tabs.Aim:CreateSection("Targeting")
toggle(Tabs.Aim, "Aimbot", "AimEnabled")
toggle(Tabs.Aim, "Show FOV circle", "ShowFov")
toggle(Tabs.Aim, "Camera lock", "CamLock")
toggle(Tabs.Aim, "Character lock", "CharLock")
toggle(Tabs.Aim, "Teleport to target", "SilentAim")
toggle(Tabs.Aim, "Visibility check", "VisCheck")
toggle(Tabs.Aim, "Prediction", "PredictionOn")
slider(Tabs.Aim, "Prediction", "PredictionVal", 0, 0.5, 0.01, "seconds")
slider(Tabs.Aim, "FOV radius", "AimFov", 10, 1000, 10, "px")
slider(Tabs.Aim, "Maximum distance", "AimDist", 50, 1000, 50, "studs")
slider(Tabs.Aim, "Smoothness", "AimSmooth", 1, 20, 1)

---------------------------------------------------------------- HTTP

local httpBusy = false
local nextRequestAt = 0
local responseCache = {}

local function current(state, token)
    return alive and state.token == token
end

local function setStatus(state, content)
    if alive and state.status then
        pcall(function()
            state.status:Set({ Title = "Status", Content = content })
        end)
    end
end

local function getJson(url, state, token)
    if not current(state, token) then
        return nil, "cancelled"
    end
    if not httpRequest then
        return nil, "request() unavailable"
    end

    local cached = responseCache[url]
    if cached and os.clock() - cached.time < 30 then
        return cached.data, "200 (cached)"
    end

    for attempt = 1, Config.HttpRetries do
        while alive and (httpBusy or os.clock() < nextRequestAt) do
            if not current(state, token) then
                return nil, "cancelled"
            end
            task.wait(0.1)
        end

        if not current(state, token) then
            return nil, "cancelled"
        end

        httpBusy = true
        local ok, response = pcall(httpRequest, {
            Url = url,
            Method = "GET",
            Headers = { Accept = "application/json" },
        })
        nextRequestAt = math.max(nextRequestAt, os.clock() + Config.HttpGap)
        httpBusy = false

        if not current(state, token) then
            return nil, "cancelled"
        end
        if not ok or type(response) ~= "table" then
            return nil, "request failed"
        end

        local code = tonumber(response.StatusCode or response.Status)
        if code == 429 then
            local retryAfter
            for name, value in pairs(response.Headers or {}) do
                if tostring(name):lower() == "retry-after" then
                    retryAfter = tonumber(value)
                    break
                end
            end
            local delay = math.max(retryAfter or (5 * 2 ^ (attempt - 1)), 2)
            nextRequestAt = math.max(nextRequestAt, os.clock() + delay)
            setStatus(state, ("HTTP 429; waiting %.0fs."):format(delay))
            if attempt == Config.HttpRetries then
                return nil, "429"
            end
        elseif code ~= 200 then
            return nil, tostring(code or "unknown HTTP status")
        else
            local decoded, data = pcall(
                HttpService.JSONDecode, HttpService, response.Body or ""
            )
            if not decoded or type(data) ~= "table" then
                return nil, "invalid JSON"
            end
            responseCache[url] = { time = os.clock(), data = data }
            return data, "200"
        end
    end

    return nil, "429"
end

---------------------------------------------------------------- CATALOG / STORE

local catalogCategories = {
    { name = "All" },
    { name = "Accessories", category = "Accessories" },
    { name = "Hats", category = "Accessories", subcategory = "HatAccessories" },
    { name = "Hair", category = "Accessories", subcategory = "HairAccessories" },
    { name = "Face", category = "Accessories", subcategory = "FaceAccessories" },
    { name = "Neck", category = "Accessories", subcategory = "NeckAccessories" },
    { name = "Shoulder", category = "Accessories", subcategory = "ShoulderAccessories" },
    { name = "Front", category = "Accessories", subcategory = "FrontAccessories" },
    { name = "Back", category = "Accessories", subcategory = "BackAccessories" },
    { name = "Waist", category = "Accessories", subcategory = "WaistAccessories" },
    { name = "Classic Shirts", category = "Clothing", subcategory = "ClassicShirts" },
    { name = "Classic T-Shirts", category = "Clothing", subcategory = "ClassicTShirts" },
    { name = "Classic Pants", category = "Clothing", subcategory = "ClassicPants" },
    { name = "Gear", category = "Gear" },
}

local storeModes = {
    { name = "Models", category = "Model", toolbox = 10 },
    { name = "Decals", category = "Decal", toolbox = 13 },
    { name = "Audio", category = "Audio", toolbox = 3 },
    { name = "Plugins", category = "Plugin", toolbox = 38 },
}

local sortIds = {
    ["Best selling"] = 2,
    ["Newest"] = 3,
    ["Price ascending"] = 4,
    ["Price descending"] = 5,
}

local function names(entries)
    local result = {}
    for _, entry in ipairs(entries) do
        result[#result + 1] = entry.name
    end
    return result
end

local function findNamed(entries, name)
    for _, entry in ipairs(entries) do
        if entry.name == name then
            return entry
        end
    end
    return entries[1]
end

local function priceText(price, status)
    if price == nil then
        return status or "Off sale"
    elseif price == 0 then
        return "Free"
    end
    return Config.RobuxIcon .. " " .. tostring(price)
end

local function makeBrowser(tab, isCatalog)
    local state = {
        token = 0, page = 1, cursors = {}, query = "",
        category = isCatalog and "All" or "Models",
        price = "Any", sort = "Relevance",
        selected = nil, nextCursor = nil,
        hasNext = false, lookup = {}, loading = false,
    }
    browserStates[#browserStates + 1] = state

    tab:CreateSection(isCatalog and "Avatar catalog" or "Creator Store")

    local function invalidate()
        state.token += 1
        state.loading = false
        state.page = 1
        state.cursors = {}
        state.hasNext = false
        state.nextCursor = nil
        state.selected = nil
        state.lookup = {}
        if state.results then
            state.results:Refresh({ "Press Search" })
        end
        setStatus(state, "Search settings changed. Press Search.")
    end

    tab:CreateInput({
        Name = "Search text",
        CurrentValue = "",
        PlaceholderText = "Enter a search term",
        RemoveTextAfterFocusLost = false,
        Flag = isCatalog and "HX_CatalogQuery" or "HX_StoreQuery",
        Callback = function(value)
            local query = tostring(value)
            if query ~= state.query then
                state.query = query
                invalidate()
            end
        end,
    })

    tab:CreateDropdown({
        Name = isCatalog and "Category" or "Asset type",
        Options = names(isCatalog and catalogCategories or storeModes),
        CurrentOption = { state.category },
        MultipleOptions = false,
        Flag = isCatalog and "HX_CatalogCategory" or "HX_StoreCategory",
        Callback = function(value)
            local category = firstOption(value)
            if category and category ~= state.category then
                state.category = category
                invalidate()
            end
        end,
    })

    if isCatalog then
        tab:CreateDropdown({
            Name = "Price",
            Options = { "Any", "Free", "Paid" },
            CurrentOption = { "Any" },
            MultipleOptions = false,
            Flag = "HX_CatalogPrice",
            Callback = function(value)
                local price = firstOption(value) or "Any"
                if price ~= state.price then
                    state.price = price
                    invalidate()
                end
            end,
        })

        tab:CreateDropdown({
            Name = "Sort",
            Options = {
                "Relevance", "Best selling", "Newest",
                "Price ascending", "Price descending",
            },
            CurrentOption = { "Relevance" },
            MultipleOptions = false,
            Flag = "HX_CatalogSort",
            Callback = function(value)
                local sort = firstOption(value) or "Relevance"
                if sort ~= state.sort then
                    state.sort = sort
                    invalidate()
                end
            end,
        })
    end

    state.status = tab:CreateParagraph({
        Title = "Status",
        Content = "Ready. Searches are manual; requests share one queue.",
    })

    state.results = tab:CreateDropdown({
        Name = "Results",
        Options = { "No results loaded" },
        CurrentOption = { "No results loaded" },
        MultipleOptions = false,
        Flag = isCatalog and "HX_CatalogResults" or "HX_StoreResults",
        Callback = function(value)
            local item = state.lookup[firstOption(value)]
            if not item then
                return
            end
            state.selected = item
            local copied = copy(item.id)
            setStatus(state, ("Selected %s [%s]. %s"):format(
                item.name, tostring(item.id),
                copied and "ID copied." or "ID not copied."
            ))
        end,
    })

    local function searchPage(reset)
        if state.loading or not alive then
            return
        end
        if reset then
            state.page = 1
            state.cursors = {}
        end

        state.token += 1
        local token, page = state.token, state.page
        local query = state.query:match("^%s*(.-)%s*$")
        local category, price, sort = state.category, state.price, state.sort
        local cursor = state.cursors[page]

        state.loading = true
        state.selected = nil
        state.hasNext = false
        state.nextCursor = nil
        state.lookup = {}
        state.results:Refresh({ "Loading..." })
        setStatus(state, "Loading page " .. page .. "...")

        task.spawn(function()
            local ok, err = pcall(function()
                local items = {}
                local nextCursor, code, data
                local hasNext = false

                if isCatalog then
                    local filter = findNamed(catalogCategories, category)
                    local url = "https://catalog.roblox.com/v1/search/items/details"
                        .. "?Limit=30&SalesTypeFilter=1"
                        .. "&Keyword=" .. HttpService:UrlEncode(query)

                    if filter.category then
                        url ..= "&Category=" .. HttpService:UrlEncode(filter.category)
                    end
                    if filter.subcategory then
                        url ..= "&Subcategory=" .. HttpService:UrlEncode(filter.subcategory)
                    end
                    if sortIds[sort] then
                        url ..= "&SortType=" .. sortIds[sort]
                    end
                    if price == "Free" then
                        url ..= "&MaxPrice=0"
                    elseif price == "Paid" then
                        url ..= "&MinPrice=1"
                    end
                    if cursor then
                        url ..= "&Cursor=" .. HttpService:UrlEncode(cursor)
                    end

                    data, code = getJson(url, state, token)
                    if data then
                        for _, entry in ipairs(data.data or {}) do
                            if tonumber(entry.id) then
                                local amount = entry.price
                                if amount == nil then
                                    amount = entry.lowestPrice
                                end
                                items[#items + 1] = {
                                    id = tonumber(entry.id),
                                    name = entry.name or ("Asset " .. entry.id),
                                    itemType = entry.itemType or "Asset",
                                    price = priceText(amount, entry.priceStatus),
                                }
                            end
                        end
                        nextCursor = data.nextPageCursor
                        hasNext = type(nextCursor) == "string" and nextCursor ~= ""
                    end
                else
                    local mode = findNamed(storeModes, category)
                    local url = (
                        "https://apis.roblox.com/toolbox-service/v2/assets:search"
                        .. "?searchCategoryType=%s&query=%s&maxPageSize=30"
                    ):format(mode.category, HttpService:UrlEncode(query))

                    if cursor then
                        url ..= "&pageToken=" .. HttpService:UrlEncode(cursor)
                    end

                    data, code = getJson(url, state, token)

                    if not data and (code == "400" or code == "404") then
                        url = (
                            "https://apis.roblox.com/toolbox-service/v1/marketplace/%d"
                            .. "?keyword=%s&limit=30&pageNumber=%d&sortType=Relevance"
                        ):format(mode.toolbox, HttpService:UrlEncode(query), page - 1)

                        data, code = getJson(url, state, token)
                        if data then
                            for _, entry in ipairs(data.data or {}) do
                                local asset = entry.asset or entry
                                if tonumber(asset.id) then
                                    items[#items + 1] = {
                                        id = tonumber(asset.id),
                                        name = asset.name or ("Asset " .. asset.id),
                                        itemType = "Asset",
                                        price = "",
                                    }
                                end
                            end
                            hasNext = #items >= 30
                        end
                    elseif data then
                        for _, entry in ipairs(data.creatorStoreAssets or {}) do
                            local asset = entry.asset
                            if asset and tonumber(asset.id) then
                                items[#items + 1] = {
                                    id = tonumber(asset.id),
                                    name = asset.name or ("Asset " .. asset.id),
                                    itemType = "Asset",
                                    price = "",
                                }
                            end
                        end
                        nextCursor = data.nextPageToken
                        hasNext = type(nextCursor) == "string" and nextCursor ~= ""
                    end
                end

                if not current(state, token) then
                    return
                end
                state.loading = false
                state.nextCursor = nextCursor
                state.hasNext = hasNext

                local options = {}
                for index, item in ipairs(items) do
                    local option = ("%02d | %s | %s | ID %s"):format(
                        index, item.name, item.price, tostring(item.id)
                    )
                    options[#options + 1] = option
                    state.lookup[option] = item
                end

                if #options == 0 then
                    state.results:Refresh({ "No results" })
                    setStatus(state, ("Page %d: no results; HTTP %s."):format(
                        page, tostring(code)
                    ))
                else
                    state.results:Refresh(options)
                    setStatus(state, ("Page %d: %d results. Select one to copy its ID.")
                        :format(page, #options))
                end
            end)

            if not ok and current(state, token) then
                state.loading = false
                setStatus(state, "Search error: " .. tostring(err))
                warn("[haxbey engine] Search error: " .. tostring(err))
            end
        end)
    end

    tab:CreateButton({
        Name = "Search",
        Callback = function()
            searchPage(true)
        end,
    })
    tab:CreateButton({
        Name = "Previous page",
        Callback = function()
            if not state.loading and state.page > 1 then
                state.page -= 1
                searchPage(false)
            end
        end,
    })
    tab:CreateButton({
        Name = "Next page",
        Callback = function()
            if state.loading or not state.hasNext then
                return
            end
            state.cursors[state.page + 1] = state.nextCursor
            state.page += 1
            searchPage(false)
        end,
    })
    tab:CreateButton({
        Name = "Copy selected ID",
        Callback = function()
            if state.selected then
                copy(state.selected.id)
            else
                notify("No selection", "Select a search result first.")
            end
        end,
    })
    tab:CreateButton({
        Name = "Get / Buy selected",
        Callback = function()
            local selected = state.selected
            if not selected then
                notify("No selection", "Select a search result first.")
                return
            end
            local ok, err = pcall(function()
                if selected.itemType == "Bundle" then
                    MarketplaceService:PromptBundlePurchase(lp, selected.id)
                else
                    MarketplaceService:PromptPurchase(lp, selected.id)
                end
            end)
            if not ok then
                notify("Purchase prompt unavailable", tostring(err))
            end
        end,
    })
end

makeBrowser(Tabs.Catalog, true)
makeBrowser(Tabs.Store, false)

---------------------------------------------------------------- SETTINGS

Tabs.Settings:CreateSection("Overlay settings")
slider(Tabs.Settings, "ESP range", "MaxDistance", 100, 5000, 50, "studs")
slider(Tabs.Settings, "Counter radius", "CountRadius", 50, 2000, 50, "studs")

local kickDeadline = 0
Tabs.Settings:CreateButton({
    Name = "Kick myself (press twice within 3 seconds)",
    Callback = function()
        if os.clock() <= kickDeadline then
            lp:Kick(Config.KickMessage)
        else
            kickDeadline = os.clock() + 3
            notify("Confirm kick", "Press the same button again within 3 seconds.")
        end
    end,
})
Tabs.Settings:CreateButton({
    Name = "Unload haxbey engine",
    Callback = unload,
})
Tabs.Settings:CreateParagraph({
    Title = "Controls",
    Content = "RightShift: menu. End: unload. "
        .. "Everything starts disabled. Not run or tested.",
})

---------------------------------------------------------------- ESP OBJECTS

local R15 = {
    { "Head", "UpperTorso" },
    { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "RightLowerLeg", "RightFoot" },
}
local R6 = {
    { "Head", "Torso" },
    { "Torso", "Left Arm" },
    { "Torso", "Right Arm" },
    { "Torso", "Left Leg" },
    { "Torso", "Right Leg" },
}

local fovCircle = draw("Circle", {
    Radius = Config.AimFov,
    Filled = false,
    Thickness = 1.5,
    Color = Color3.new(1, 1, 1),
    Visible = false,
    NumSides = 64,
})

local function newESP()
    local object = { corners = {}, bones = {} }
    for i = 1, 8 do
        object.corners[i] = draw("Line", {
            Thickness = 1.5, Color = Config.BoxColor, Visible = false,
        })
    end
    for i = 1, #R15 do
        object.bones[i] = draw("Line", {
            Thickness = 1.5, Visible = false,
        })
    end
    object.hpBack = draw("Line", {
        Thickness = 4, Color = Color3.new(), Visible = false,
    })
    object.hpBar = draw("Line", {
        Thickness = 2, Color = Color3.new(0, 1, 0), Visible = false,
    })
    object.dot = draw("Circle", {
        Radius = 3, Filled = true, NumSides = 12, Visible = false,
    })
    object.holder = instance("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.fromOffset(220, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
    }, overlay)
    instance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, object.holder)

    local function row(order, color)
        local label = textLabel(object.holder, "", color, Config.TextSize)
        label.LayoutOrder = order
        label.Size = UDim2.new(1, 0, 0, Config.TextSize + 2)
        return label
    end
    object.name = row(1, Config.NameColor)
    object.item = row(2, Config.ItemColor)
    object.dist = row(3, Config.DistColor)
    return object
end

local function hideESP(object)
    for _, line in ipairs(object.corners) do
        line.Visible = false
    end
    for _, line in ipairs(object.bones) do
        line.Visible = false
    end
    object.hpBack.Visible = false
    object.hpBar.Visible = false
    object.dot.Visible = false
    object.holder.Visible = false
end

local function untrack(player)
    local object = tracked[player]
    if not object then
        return
    end
    tracked[player] = nil
    for _, line in ipairs(object.corners) do
        removeDrawing(line)
    end
    for _, line in ipairs(object.bones) do
        removeDrawing(line)
    end
    removeDrawing(object.hpBack)
    removeDrawing(object.hpBar)
    removeDrawing(object.dot)
    object.holder:Destroy()
end

local function track(player)
    if alive and player ~= lp and not tracked[player] then
        tracked[player] = newESP()
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    track(player)
end
connect(Players.PlayerAdded, track)
connect(Players.PlayerRemoving, untrack)

---------------------------------------------------------------- REMOTE INDEX LIFECYCLE

connect(game.DescendantAdded, function(object)
    if isRemote(object) then
        Snap.registry[object] = true
        queueSnapRefresh()
    end
end)

connect(game.DescendantRemoving, function(object)
    if Snap.registry[object] or Snap.matches[object] then
        Snap.registry[object] = nil
        Snap.matches[object] = nil
        restoreRemoteListeners(object)
        queueSnapRefresh()
    end
end)

scanAllRemotes()

---------------------------------------------------------------- HELPERS

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local warningRay = RaycastParams.new()
warningRay.FilterType = Enum.RaycastFilterType.Exclude
warningRay.IgnoreWater = true

local function sameTeam(player)
    return Config.TeamCheck and player.Team ~= nil
        and lp.Team ~= nil and player.Team == lp.Team
end

local function visible(character, part)
    local origin = cam.CFrame.Position
    local result = workspace:Raycast(origin, part.Position - origin, rayParams)
    return not result or result.Instance:IsDescendantOf(character)
end

local function project(position)
    local point, onScreen = cam:WorldToViewportPoint(position)
    return Vector2.new(point.X, point.Y), point.Z > 0, onScreen
end

local function scan(myCharacter, myRoot)
    if not myRoot then
        return 0, false
    end
    local count, aiming = 0, false
    local cosLimit = math.cos(math.rad(Config.WarnAngleDeg))

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and not sameTeam(player) then
            local character = player.Character
            local head = character and character:FindFirstChild("Head")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if head and humanoid and humanoid.Health > 0 then
                local delta = myRoot.Position - head.Position
                local distance = delta.Magnitude
                if distance <= Config.CountRadius then
                    count += 1
                end
                if not aiming and distance > 0.1
                    and distance <= Config.WarnMaxDist
                    and head.CFrame.LookVector:Dot(delta.Unit) >= cosLimit
                then
                    if not Config.WarnNeedLOS then
                        aiming = true
                    else
                        warningRay.FilterDescendantsInstances = { character }
                        local hit = workspace:Raycast(head.Position, delta, warningRay)
                        aiming = not hit or (
                            myCharacter ~= nil
                            and hit.Instance:IsDescendantOf(myCharacter)
                        )
                    end
                end
            end
        end
    end
    return count, aiming
end

---------------------------------------------------------------- CHARACTER MODIFICATIONS

local function saveProperty(object, property, value)
    local bucket = savedProperties[object]
    if not bucket then
        bucket = {}
        savedProperties[object] = bucket
    end
    if bucket[property] == nil then
        bucket[property] = object[property]
    end
    object[property] = value
end

local function restoreProperty(object, property)
    local bucket = savedProperties[object]
    if bucket and bucket[property] ~= nil then
        local previous = bucket[property]
        bucket[property] = nil
        pcall(function()
            object[property] = previous
        end)
        if next(bucket) == nil then
            savedProperties[object] = nil
        end
    end
end

local function characterTick()
    local character = lp.Character
    if character ~= lastCharacter then
        restoreAllProperties()
        lastCharacter = character
    end

    if Config.GravOn then
        if originalGravity == nil then
            originalGravity = workspace.Gravity
        end
        workspace.Gravity = Config.Grav
    elseif originalGravity ~= nil then
        workspace.Gravity = originalGravity
        originalGravity = nil
    end

    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    if Config.SpeedOn then
        saveProperty(humanoid, "WalkSpeed", Config.Speed)
    else
        restoreProperty(humanoid, "WalkSpeed")
    end

    if Config.JumpOn then
        saveProperty(humanoid, "UseJumpPower", true)
        saveProperty(humanoid, "JumpPower", Config.Jump)
    else
        restoreProperty(humanoid, "JumpPower")
        restoreProperty(humanoid, "UseJumpPower")
    end

    local head = character:FindFirstChild("Head")
    local headScale = humanoid:FindFirstChild("HeadScale")
    if Config.HeadOn and head then
        if headScale then
            restoreProperty(head, "Size")
            saveProperty(headScale, "Value", Config.Head)
        else
            local bucket = savedProperties[head]
            local original = bucket and bucket.Size or head.Size
            saveProperty(head, "Size", original * Config.Head)
        end
    else
        if headScale then
            restoreProperty(headScale, "Value")
        end
        if head then
            restoreProperty(head, "Size")
        end
    end

    if Config.TransOn then
        for _, object in ipairs(character:GetDescendants()) do
            if (object:IsA("BasePart") and object.Name ~= "HumanoidRootPart")
                or object:IsA("Decal")
            then
                if changedTransparency[object] == nil then
                    changedTransparency[object] = object.Transparency
                end
                object.Transparency = Config.Trans
            end
        end
    else
        for object, value in pairs(changedTransparency) do
            pcall(function()
                object.Transparency = value
            end)
        end
        changedTransparency = {}
    end
end

local characterTimer = 0
connect(RunService.Heartbeat, function(dt)
    if not alive then
        return
    end

    characterTimer += dt
    if characterTimer >= 0.1 then
        characterTimer = 0
        characterTick()
    end

    Snap.timer += dt
    if Snap.timer >= math.max(Config.SnapCheckInterval, 0.5) then
        Snap.timer = 0
        queueSnapRefresh()
    end
end)

---------------------------------------------------------------- MAIN LOOP

local fps, fpsTimer, scanTimer = 60, 0, 0
local cachedCount, cachedAiming = 0, false

RunService:BindToRenderStep(
    renderName,
    Enum.RenderPriority.Camera.Value + 1,
    function(dt)
        if not alive then
            return
        end

        cam = workspace.CurrentCamera
        if not cam then
            fovCircle.Visible = false
            warning.Visible = false
            countPill.Visible = false
            fpsPill.Visible = false
            for _, object in pairs(tracked) do
                hideESP(object)
            end
            return
        end

        local myCharacter = lp.Character
        local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        rayParams.FilterDescendantsInstances = myCharacter and { myCharacter } or {}

        local center = cam.ViewportSize / 2
        fovCircle.Position = center
        fovCircle.Radius = Config.AimFov
        fovCircle.Visible = Config.AimEnabled and Config.ShowFov

        if Config.AimEnabled and myRoot then
            local bestPosition
            local bestDistance = Config.AimFov

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= lp and not sameTeam(player) then
                    local character = player.Character
                    local head = character and character:FindFirstChild("Head")
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if head and root and humanoid and humanoid.Health > 0
                        and (root.Position - myRoot.Position).Magnitude <= Config.AimDist
                        and (not Config.VisCheck or visible(character, head))
                    then
                        local position = head.Position
                        if Config.PredictionOn then
                            position += root.AssemblyLinearVelocity * Config.PredictionVal
                        end
                        local screen, inFront, onScreen = project(position)
                        local distance = (screen - center).Magnitude
                        if inFront and onScreen and distance < bestDistance then
                            bestDistance = distance
                            bestPosition = position
                        end
                    end
                end
            end

            if bestPosition then
                local alpha = Config.AimSmooth <= 1 and 1
                    or (1 - math.exp(-(22 - Config.AimSmooth) * dt))

                if Config.CamLock
                    and (bestPosition - cam.CFrame.Position).Magnitude > 0.001
                then
                    cam.CFrame = cam.CFrame:Lerp(
                        CFrame.lookAt(cam.CFrame.Position, bestPosition), alpha
                    )
                end
                if Config.CharLock then
                    local horizontal = Vector3.new(
                        bestPosition.X, myRoot.Position.Y, bestPosition.Z
                    )
                    if (horizontal - myRoot.Position).Magnitude > 0.001 then
                        myRoot.CFrame = myRoot.CFrame:Lerp(
                            CFrame.lookAt(myRoot.Position, horizontal), alpha
                        )
                    end
                end
                if Config.SilentAim then
                    myRoot.CFrame = CFrame.new(bestPosition - Vector3.new(0, 3, 0))
                end
            end
        end

        local anyText = Config.Name or Config.Item or Config.Dist
        local needVisibility = Config.Bones or Config.RootDot
        local anything = Config.Box or Config.Health or anyText or needVisibility

        for player, object in pairs(tracked) do
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local valid = Config.Enabled and anything and myRoot and root
                and humanoid and humanoid.Health > 0 and not sameTeam(player)
            local distance = valid and (root.Position - myRoot.Position).Magnitude or 0
            if valid and distance > Config.MaxDistance then
                valid = false
            end

            if not valid then
                hideESP(object)
            else
                local cf, size = root.CFrame, Vector3.new(4, 5, 2)
                local ok, boxCF, boxSize = pcall(character.GetBoundingBox, character)
                if ok then
                    cf, size = boxCF, boxSize
                end
                local top, topFront = project(
                    cf.Position + Vector3.new(0, size.Y / 2, 0)
                )
                local bottom, bottomFront = project(
                    cf.Position - Vector3.new(0, size.Y / 2, 0)
                )

                if not topFront or not bottomFront then
                    hideESP(object)
                else
                    local height = math.abs(bottom.Y - top.Y)
                    local width = height * 0.6
                    local x = (top.X + bottom.X) / 2 - width / 2
                    local y = math.min(top.Y, bottom.Y)

                    if Config.Box then
                        local dx, dy = width * 0.3, height * 0.15
                        local segments = {
                            { x, y, x + dx, y },
                            { x, y, x, y + dy },
                            { x + width, y, x + width - dx, y },
                            { x + width, y, x + width, y + dy },
                            { x, y + height, x + dx, y + height },
                            { x, y + height, x, y + height - dy },
                            { x + width, y + height, x + width - dx, y + height },
                            { x + width, y + height, x + width, y + height - dy },
                        }
                        for i, segment in ipairs(segments) do
                            local line = object.corners[i]
                            line.From = Vector2.new(segment[1], segment[2])
                            line.To = Vector2.new(segment[3], segment[4])
                            line.Color = Config.BoxColor
                            line.Visible = true
                        end
                    else
                        for _, line in ipairs(object.corners) do
                            line.Visible = false
                        end
                    end

                    if Config.Health then
                        local ratio = math.clamp(
                            humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1
                        )
                        local barX = x - 5
                        object.hpBack.From = Vector2.new(barX, y + height + 1)
                        object.hpBack.To = Vector2.new(barX, y - 1)
                        object.hpBar.From = Vector2.new(barX, y + height)
                        object.hpBar.To = Vector2.new(barX, y + height * (1 - ratio))
                        object.hpBar.Color = Color3.new(1 - ratio, ratio, 0)
                    end
                    object.hpBack.Visible = Config.Health
                    object.hpBar.Visible = Config.Health
                    object.name.Visible = Config.Name
                    object.item.Visible = Config.Item
                    object.dist.Visible = Config.Dist
                    object.holder.Visible = anyText

                    if anyText then
                        local tool = character:FindFirstChildOfClass("Tool")
                        object.name.Text = player.DisplayName
                        object.item.Text = tool and tool.Name or "Nothing"
                        object.dist.Text = ("%d studs"):format(math.floor(distance))
                        object.holder.Position = UDim2.fromOffset(
                            x + width / 2, y + height + 2
                        )
                    end

                    local color = Config.HiddenColor
                    if needVisibility then
                        color = visible(
                            character, character:FindFirstChild("Head") or root
                        ) and Config.VisColor or Config.HiddenColor
                    end
                    object.dot.Visible = Config.RootDot
                    if Config.RootDot then
                        local position = project(root.Position)
                        object.dot.Position = position
                        object.dot.Color = color
                    end

                    local map = character:FindFirstChild("UpperTorso") and R15 or R6
                    for i, line in ipairs(object.bones) do
                        local pair = Config.Bones and map[i]
                        local a = pair and character:FindFirstChild(pair[1])
                        local b = pair and character:FindFirstChild(pair[2])
                        if a and b then
                            local pa, fa = project(a.Position)
                            local pb, fb = project(b.Position)
                            line.Visible = fa and fb
                            if fa and fb then
                                line.From = pa
                                line.To = pb
                                line.Color = color
                            end
                        else
                            line.Visible = false
                        end
                    end
                end
            end
        end

        scanTimer += dt
        if (Config.Warn or Config.Counter) and scanTimer >= 0.1 then
            scanTimer = 0
            cachedCount, cachedAiming = scan(myCharacter, myRoot)
        elseif not Config.Warn and not Config.Counter then
            scanTimer = 0
            cachedCount, cachedAiming = 0, false
        end

        warning.Visible = Config.Warn and cachedAiming and myRoot ~= nil
        if warning.Visible then
            warning.TextColor3 = math.floor(os.clock() / Config.WarnFlip) % 2 == 0
                and Config.WarnColorA or Config.WarnColorB
        end

        countPill.Visible = Config.Counter
        if Config.Counter then
            countText.Text = ("Total enemy around you: %d"):format(
                myRoot and cachedCount or 0
            )
        end

        fpsPill.Visible = Config.Fps
        if Config.Fps then
            fps += ((1 / math.max(dt, 0.0001)) - fps) * 0.1
            fpsTimer += dt
            if fpsTimer >= 0.25 then
                fpsTimer = 0
                fpsText.Text = ("%d FPS"):format(math.floor(fps + 0.5))
            end
        end
    end
)

connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Config.ExitKey then
        unload()
    end
end)

notify(
    "haxbey engine",
    "Initialized. Enter your remote names under Character > Remote search."
)
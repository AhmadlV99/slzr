--[[
    GoofyzUI — A clean, public-use Roblox GUI library
    Made by goofyz
    Version: 1.0.0
    License: MIT

    Features:
        Window         — draggable, scalable main container
        Tab            — flat card tab navigation
        Section        — labeled group divider inside a page
        Toggle         — animated capsule switch
        Slider         — smooth drag slider with textbox input
        Button         — ripple-effect action button
        Dropdown       — searchable single/multi select
        Input          — text field with copy button
        Keybind        — key capture field
        Label          — info/paragraph row
        ColorPicker    — (coming in v1.1)

    Usage:
        local UI = loadstring(game:HttpGet("RAW_URL_HERE"))()
        local win = UI:Window({ Title = "My Script", SubTitle = "v1.0" })
        local tab = win:Tab({ Title = "Main", Icon = 0 })
        tab:Toggle({ Title = "Fly", Callback = function(v) end })
]]

local GoofyzUI = {}

-- ── Services ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")

-- ── Runtime ───────────────────────────────────────────────────────────────────
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer.PlayerGui
local Mobile      = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ── Palette ───────────────────────────────────────────────────────────────────
local C = {
    Base        = Color3.fromHex("0A0A0F"),   -- window body
    Card        = Color3.fromHex("111118"),   -- row / card bg
    CardHover   = Color3.fromHex("16161F"),   -- hovered card
    Surface     = Color3.fromHex("1A1A28"),   -- dropdown / input bg
    Border      = Color3.fromHex("1E1E30"),   -- subtle borders
    BorderBright= Color3.fromHex("2A2A42"),   -- focused borders
    Accent      = Color3.fromHex("00D4FF"),   -- primary cyan
    AccentDim   = Color3.fromHex("0099BB"),   -- pressed accent
    AccentSoft  = Color3.fromHex("00D4FF"),   -- used at low alpha
    TextPrimary = Color3.fromHex("C8D0FF"),   -- main text
    TextSecond  = Color3.fromHex("6B7299"),   -- secondary / desc
    TextFaint   = Color3.fromHex("363656"),   -- placeholder
    White       = Color3.fromHex("FFFFFF"),
    Black       = Color3.fromHex("000000"),
}

-- ── Tweening helpers ─────────────────────────────────────────────────────────
local function Tween(instance, props, duration, style, direction)
    style     = style     or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    return TweenService:Create(instance, TweenInfo.new(duration or 0.2, style, direction), props)
end

local function TweenPlay(instance, props, duration, style, direction)
    Tween(instance, props, duration, style, direction):Play()
end

-- ── Instance factory ─────────────────────────────────────────────────────────
local function Make(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() inst[k] = v end)
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

-- ── Screen parent ─────────────────────────────────────────────────────────────
local function GuiParent()
    if not RunService:IsStudio() then
        return (pcall(gethui) and gethui()) or CoreGui
    end
    return PlayerGui
end

-- ── Ripple effect ─────────────────────────────────────────────────────────────
local function Ripple(clipFrame, clickBtn)
    clipFrame.ClipsDescendants = true
    local mouse = LocalPlayer:GetMouse()
    local rx    = mouse.X - clickBtn.AbsolutePosition.X
    local ry    = mouse.Y - clickBtn.AbsolutePosition.Y
    if rx < 0 or ry < 0 or rx > clickBtn.AbsoluteSize.X or ry > clickBtn.AbsoluteSize.Y then return end

    local dot = Make("Frame", {
        Parent               = clipFrame,
        BackgroundColor3     = C.Accent,
        BackgroundTransparency = 0.78,
        AnchorPoint          = Vector2.new(0.5, 0.5),
        Position             = UDim2.new(0, rx, 0, ry),
        Size                 = UDim2.new(0, 0, 0, 0),
        BorderSizePixel      = 0,
        ZIndex               = clipFrame.ZIndex + 1,
    })
    Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

    local t = Tween(dot, {
        Size                 = UDim2.new(0, clickBtn.AbsoluteSize.X * 2.2, 0, clickBtn.AbsoluteSize.X * 2.2),
        BackgroundTransparency = 1,
    }, 0.45, Enum.EasingStyle.Quad)
    t.Completed:Once(function() dot:Destroy() end)
    t:Play()
end

-- ── Draggable ─────────────────────────────────────────────────────────────────
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging  = true
        dragStart = inp.Position
        startPos  = frame.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = inp.Position - dragStart
        TweenPlay(frame, {
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        }, 0.07, Enum.EasingStyle.Linear)
    end)
end

-- ── Invisible click button ────────────────────────────────────────────────────
local function ClickBtn(parent)
    return Make("TextButton", {
        Parent               = parent,
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Text                 = "",
        Font                 = Enum.Font.GothamBold,
        TextSize             = 1,
        ZIndex               = parent.ZIndex + 4,
    })
end

-- ── Row base (used by most controls) ─────────────────────────────────────────
local function MakeRow(parent, title, desc, height)
    height = height or 40

    local row = Make("Frame", {
        Parent           = parent,
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, height),
    })
    Make("UICorner", { CornerRadius = UDim.new(0, 5), Parent = row })
    Make("UIStroke", {
        Color           = C.Border,
        Thickness       = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent          = row,
    })

    -- Left side: title + desc
    local leftFrame = Make("Frame", {
        Parent               = row,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Size                 = UDim2.new(0.6, -10, 1, 0),
        Position             = UDim2.new(0, 12, 0, 0),
    })
    Make("UIListLayout", {
        Parent           = leftFrame,
        SortOrder        = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding          = UDim.new(0, 2),
    })

    local titleLabel = Make("TextLabel", {
        Parent               = leftFrame,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Size                 = UDim2.new(1, 0, 0, 14),
        Font                 = Enum.Font.GothamSemibold,
        Text                 = title or "",
        TextColor3           = C.TextPrimary,
        TextSize             = 12,
        TextXAlignment       = Enum.TextXAlignment.Left,
        RichText             = true,
        LayoutOrder          = -1,
    })

    local descLabel = Make("TextLabel", {
        Parent               = leftFrame,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Size                 = UDim2.new(1, 0, 0, 10),
        Font                 = Enum.Font.GothamMedium,
        Text                 = desc or "",
        TextColor3           = C.TextSecond,
        TextSize             = 10,
        TextXAlignment       = Enum.TextXAlignment.Left,
        RichText             = true,
    })

    -- Right side: control area
    local rightFrame = Make("Frame", {
        Parent               = row,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        AnchorPoint          = Vector2.new(1, 0.5),
        Position             = UDim2.new(1, -12, 0.5, 0),
        Size                 = UDim2.new(0.4, -12, 0, height - 10),
    })
    Make("UIListLayout", {
        Parent               = rightFrame,
        HorizontalAlignment  = Enum.HorizontalAlignment.Right,
        VerticalAlignment    = Enum.VerticalAlignment.Center,
        SortOrder            = Enum.SortOrder.LayoutOrder,
        FillDirection        = Enum.FillDirection.Horizontal,
    })

    return row, titleLabel, descLabel, rightFrame
end

-- ─────────────────────────────────────────────────────────────────────────────
-- WINDOW
-- ─────────────────────────────────────────────────────────────────────────────
function GoofyzUI:Window(args)
    args = args or {}
    local winTitle    = args.Title    or "GoofyzUI"
    local winSubtitle = args.SubTitle or "made by goofyz"

    local screenGui = Make("ScreenGui", {
        Name           = "GoofyzUI",
        Parent         = GuiParent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        ResetOnSpawn   = false,
    })

    -- Main container
    local container = Make("Frame", {
        Name             = "Container",
        Parent           = screenGui,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.Base,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = UDim2.new(0, 520, 0, 370),
    })
    Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = container })
    Make("UIStroke", { Color = C.Border, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = container })

    -- Ambient drop shadow
    Make("ImageLabel", {
        Parent               = container,
        AnchorPoint          = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Position             = UDim2.new(0.5, 0, 0.5, 8),
        Size                 = UDim2.new(1, 80, 1, 80),
        ZIndex               = 0,
        Image                = "rbxassetid://8992230677",
        ImageColor3          = Color3.fromHex("020206"),
        ImageTransparency    = 0.2,
        ScaleType            = Enum.ScaleType.Slice,
        SliceCenter          = Rect.new(99, 99, 99, 99),
    })

    -- ── Header ────────────────────────────────────────────────────────────────
    local header = Make("Frame", {
        Name             = "Header",
        Parent           = container,
        BackgroundColor3 = Color3.fromHex("0C0C14"),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 46),
    })
    Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = header })
    -- Fill bottom half of corner so it's only rounded on top
    Make("Frame", {
        Parent           = header,
        BackgroundColor3 = Color3.fromHex("0C0C14"),
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 8),
    })
    -- Header bottom border
    Make("Frame", {
        Parent           = header,
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 1),
    })

    -- ── SIGNATURE: breathing status dot ───────────────────────────────────────
    local pulseDot = Make("Frame", {
        Parent           = header,
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 14, 0.5, 0),
        Size             = UDim2.new(0, 7, 0, 7),
    })
    Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pulseDot })

    -- Glow ring behind dot
    local pulseGlow = Make("Frame", {
        Parent           = header,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 0.6,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 17, 0.5, 0),
        Size             = UDim2.new(0, 7, 0, 7),
        ZIndex           = pulseDot.ZIndex - 1,
    })
    Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pulseGlow })

    -- Animate the pulse
    local pulseRunning = true
    task.spawn(function()
        while pulseRunning do
            TweenPlay(pulseGlow, { Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0.88 }, 0.9, Enum.EasingStyle.Sine)
            task.wait(0.9)
            TweenPlay(pulseGlow, { Size = UDim2.new(0, 7, 0, 7), BackgroundTransparency = 0.6 }, 0.9, Enum.EasingStyle.Sine)
            task.wait(0.9)
        end
    end)

    -- Title / subtitle
    local titleLabel = Make("TextLabel", {
        Parent               = header,
        AnchorPoint          = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Position             = UDim2.new(0, 28, 0.5, -6),
        Size                 = UDim2.new(0.5, -30, 0, 16),
        Font                 = Enum.Font.GothamBold,
        Text                 = winTitle,
        TextColor3           = C.TextPrimary,
        TextSize             = 14,
        TextXAlignment       = Enum.TextXAlignment.Left,
    })

    Make("TextLabel", {
        Parent               = header,
        AnchorPoint          = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Position             = UDim2.new(0, 28, 0.5, 9),
        Size                 = UDim2.new(0.5, -30, 0, 11),
        Font                 = Enum.Font.GothamMedium,
        Text                 = winSubtitle,
        TextColor3           = C.TextSecond,
        TextSize             = 10,
        TextXAlignment       = Enum.TextXAlignment.Left,
    })

    -- Expire / time label (top right)
    local timeLabel = Make("TextLabel", {
        Parent               = header,
        AnchorPoint          = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Position             = UDim2.new(1, -14, 0.5, 0),
        Size                 = UDim2.new(0.4, 0, 0, 12),
        Font                 = Enum.Font.GothamMedium,
        Text                 = "",
        TextColor3           = C.TextSecond,
        TextSize             = 10,
        TextXAlignment       = Enum.TextXAlignment.Right,
    })

    MakeDraggable(container, header)

    -- ── Tab bar ───────────────────────────────────────────────────────────────
    local tabBar = Make("Frame", {
        Name             = "TabBar",
        Parent           = container,
        BackgroundColor3 = Color3.fromHex("0C0C14"),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 46),
        Size             = UDim2.new(1, 0, 0, 38),
    })
    Make("Frame", {   -- bottom border
        Parent           = tabBar,
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 1),
    })

    local tabScroll = Make("ScrollingFrame", {
        Name                 = "TabScroll",
        Parent               = tabBar,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Size                 = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness   = 0,
        ScrollingDirection   = Enum.ScrollingDirection.X,
        AutomaticCanvasSize  = Enum.AutomaticSize.X,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
    })
    Make("UIListLayout", {
        Parent        = tabScroll,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding       = UDim.new(0, 0),
    })
    Make("UIPadding", {
        Parent      = tabScroll,
        PaddingLeft = UDim.new(0, 8),
    })

    -- ── Content area ──────────────────────────────────────────────────────────
    local contentArea = Make("Frame", {
        Name             = "ContentArea",
        Parent           = container,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 85),
        Size             = UDim2.new(1, 0, 1, -85),
        ClipsDescendants = true,
    })

    -- ── UIScale for resolution independence ───────────────────────────────────
    local uiScale = Make("UIScale", {
        Parent = screenGui,
        Scale  = Mobile and 1 or 1.4,
    })

    -- ── Open / close pill button ──────────────────────────────────────────────
    local pillScreen = Make("ScreenGui", {
        Name           = "GoofyzPill",
        Parent         = GuiParent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        ResetOnSpawn   = false,
    })
    local pill = Make("TextButton", {
        Parent           = pillScreen,
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.05, 0, 0.12, 0),
        Size             = UDim2.new(0, 42, 0, 42),
        Text             = "",
        AutoButtonColor  = false,
    })
    Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })
    Make("UIStroke", { Color = C.Accent, Thickness = 1.5, Transparency = 0.4, Parent = pill })
    Make("ImageLabel", {
        Parent               = pill,
        AnchorPoint          = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Position             = UDim2.new(0.5, 0, 0.5, 0),
        Size                 = UDim2.new(0.52, 0, 0.52, 0),
        Image                = "rbxassetid://134528790539968",
        ImageColor3          = C.Accent,
    })
    MakeDraggable(pill)

    local visible = true
    pill.MouseButton1Click:Connect(function()
        visible = not visible
        container.Visible = visible
    end)
    UserInputService.InputBegan:Connect(function(input, proc)
        if proc then return end
        if input.KeyCode == Enum.KeyCode.LeftControl then
            visible = not visible
            container.Visible = visible
        end
    end)

    -- ── Dropdown tracker ─────────────────────────────────────────────────────
    local openDropdown = nil

    -- ── Window object ─────────────────────────────────────────────────────────
    local Win = {}
    Win._tabs     = {}
    Win._pages    = {}
    Win._activePg = nil

    function Win:SetTime(text)
        timeLabel.Text = text
    end

    function Win:SetScale(s)
        uiScale.Scale = s
    end

    -- Destroy on script unload
    function Win:Destroy()
        pulseRunning = false
        screenGui:Destroy()
        pillScreen:Destroy()
    end

    -- ── Switch visible page ───────────────────────────────────────────────────
    local function switchPage(page)
        for _, pg in ipairs(Win._pages) do
            pg.Visible = false
        end
        page.Visible = true
        Win._activePg = page
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- TAB
    -- ─────────────────────────────────────────────────────────────────────────
    function Win:Tab(tabArgs)
        tabArgs = tabArgs or {}
        local tabTitle = tabArgs.Title or "Tab"
        local tabIcon  = tabArgs.Icon

        -- Tab button
        local tabBtn = Make("TextButton", {
            Parent           = tabScroll,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            AutoButtonColor  = false,
            Size             = UDim2.new(0, 0, 1, 0),
            AutomaticSize    = Enum.AutomaticSize.X,
            Text             = "",
            Font             = Enum.Font.GothamBold,
            TextSize         = 12,
        })

        local tabBtnLayout = Make("Frame", {
            Parent               = tabBtn,
            BackgroundTransparency = 1,
            BorderSizePixel      = 0,
            Size                 = UDim2.new(1, 0, 1, 0),
            AutomaticSize        = Enum.AutomaticSize.X,
        })
        Make("UIListLayout", {
            Parent           = tabBtnLayout,
            FillDirection    = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding          = UDim.new(0, 5),
        })
        Make("UIPadding", {
            Parent       = tabBtnLayout,
            PaddingLeft  = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
        })

        if tabIcon and tabIcon ~= 0 then
            Make("ImageLabel", {
                Parent               = tabBtnLayout,
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(0, 14, 0, 14),
                Image                = typeof(tabIcon) == "number" and ("rbxassetid://" .. tabIcon) or tabIcon,
                ImageColor3          = C.TextSecond,
            })
        end

        local tabText = Make("TextLabel", {
            Parent               = tabBtnLayout,
            BackgroundTransparency = 1,
            BorderSizePixel      = 0,
            AutomaticSize        = Enum.AutomaticSize.X,
            Size                 = UDim2.new(0, 0, 1, 0),
            Font                 = Enum.Font.GothamSemibold,
            Text                 = tabTitle,
            TextColor3           = C.TextSecond,
            TextSize             = 12,
        })

        -- Active underline
        local underline = Make("Frame", {
            Parent           = tabBtn,
            AnchorPoint      = Vector2.new(0, 1),
            BackgroundColor3 = C.Accent,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 8, 1, 0),
            Size             = UDim2.new(1, -16, 0, 2),
            Visible          = false,
        })
        Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = underline })

        -- Page for this tab
        local page = Make("ScrollingFrame", {
            Parent               = contentArea,
            BackgroundTransparency = 1,
            BorderSizePixel      = 0,
            Size                 = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness   = 3,
            ScrollBarImageColor3 = C.Border,
            AutomaticCanvasSize  = Enum.AutomaticSize.Y,
            CanvasSize           = UDim2.new(0, 0, 0, 0),
            Visible              = false,
        })
        Make("UIListLayout", {
            Parent        = page,
            Padding       = UDim.new(0, 5),
            SortOrder     = Enum.SortOrder.LayoutOrder,
        })
        Make("UIPadding", {
            Parent        = page,
            PaddingLeft   = UDim.new(0, 12),
            PaddingRight  = UDim.new(0, 12),
            PaddingTop    = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
        })

        table.insert(Win._tabs, { btn = tabBtn, page = page, underline = underline, text = tabText, icon = tabIcon })
        table.insert(Win._pages, page)

        -- Select first tab automatically
        if #Win._tabs == 1 then
            switchPage(page)
            tabText.TextColor3  = C.Accent
            underline.Visible   = true
        end

        tabBtn.MouseButton1Click:Connect(function()
            for _, t in ipairs(Win._tabs) do
                t.underline.Visible = false
                TweenPlay(t.text, { TextColor3 = C.TextSecond }, 0.15)
            end
            underline.Visible = true
            TweenPlay(tabText, { TextColor3 = C.Accent }, 0.15)
            switchPage(page)
        end)

        -- ── Tab object ────────────────────────────────────────────────────────
        local Tab = {}
        Tab._page = page
        Tab._openDropdown = function() return openDropdown end

        -- ── Section ──────────────────────────────────────────────────────────
        function Tab:Section(text)
            local wrapper = Make("Frame", {
                Parent               = page,
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(1, 0, 0, 22),
            })
            Make("UIListLayout", {
                Parent           = wrapper,
                FillDirection    = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding          = UDim.new(0, 8),
            })

            Make("Frame", {   -- left line
                Parent           = wrapper,
                BackgroundColor3 = C.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 2, 0, 10),
                LayoutOrder      = -1,
            })

            Make("TextLabel", {
                Parent               = wrapper,
                AutomaticSize        = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(0, 0, 1, 0),
                Font                 = Enum.Font.GothamBold,
                Text                 = text,
                TextColor3           = C.Accent,
                TextSize             = 10,
                TextXAlignment       = Enum.TextXAlignment.Left,
            })

            -- Right filler line
            Make("Frame", {
                Parent           = wrapper,
                BackgroundColor3 = C.Border,
                BorderSizePixel  = 0,
                LayoutOrder      = 1,
                Size             = UDim2.new(1, 0, 0, 1),
            })

            return wrapper
        end

        -- ── Toggle ────────────────────────────────────────────────────────────
        function Tab:Toggle(tArgs)
            tArgs    = tArgs or {}
            local val = tArgs.Value or false
            local cb  = tArgs.Callback or function() end

            local row, titleL, descL, rightFrame = MakeRow(page, tArgs.Title, tArgs.Desc)

            -- Capsule track
            local track = Make("Frame", {
                Parent           = rightFrame,
                BackgroundColor3 = Color3.fromHex("181824"),
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 38, 0, 20),
            })
            Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
            local trackStroke = Make("UIStroke", { Color = C.Border, Thickness = 1, Parent = track })

            -- Knob
            local knob = Make("Frame", {
                Parent           = track,
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromHex("555570"),
                BorderSizePixel  = 0,
                Position         = UDim2.new(0, 3, 0.5, 0),
                Size             = UDim2.new(0, 14, 0, 14),
            })
            Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

            local click = ClickBtn(row)
            local data  = { Value = val }

            local function apply(v, animate)
                data.Value = v
                local duration = animate and 0.22 or 0
                if v then
                    TweenPlay(track, { BackgroundColor3 = Color3.fromHex("001E28") }, duration)
                    TweenPlay(knob,  { Position = UDim2.new(0, 21, 0.5, 0), BackgroundColor3 = C.Accent }, duration, Enum.EasingStyle.Back)
                    trackStroke.Color = C.Accent
                    trackStroke.Transparency = 0.5
                    TweenPlay(titleL, { TextColor3 = C.Accent }, duration)
                else
                    TweenPlay(track, { BackgroundColor3 = Color3.fromHex("181824") }, duration)
                    TweenPlay(knob,  { Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Color3.fromHex("555570") }, duration)
                    trackStroke.Color = C.Border
                    trackStroke.Transparency = 0
                    TweenPlay(titleL, { TextColor3 = C.TextPrimary }, duration)
                end
                cb(v)
            end

            apply(val, false)

            click.MouseButton1Click:Connect(function()
                if openDropdown then return end
                apply(not data.Value, true)
            end)

            local obj = {}
            function obj:Set(v) apply(v, true) end
            function obj:Get() return data.Value end
            setmetatable(obj, {
                __newindex = function(_, k, v)
                    if k == "Value" then apply(v, true)
                    elseif k == "Title" then titleL.Text = tostring(v)
                    elseif k == "Desc"  then descL.Text  = tostring(v) end
                end,
                __index = data,
            })
            return obj
        end

        -- ── Slider ────────────────────────────────────────────────────────────
        function Tab:Slider(sArgs)
            sArgs    = sArgs or {}
            local min = sArgs.Min      or 0
            local max = sArgs.Max      or 100
            local val = sArgs.Value    or min
            local rnd = sArgs.Rounding or 0
            local cb  = sArgs.Callback or function() end

            local row, titleL, _, rightFrame = MakeRow(page, sArgs.Title, sArgs.Desc, 44)

            -- Value box
            local valBox = Make("TextBox", {
                Parent               = rightFrame,
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(0, 44, 0, 16),
                Font                 = Enum.Font.GothamMedium,
                Text                 = tostring(val),
                TextColor3           = C.TextSecond,
                TextSize             = 11,
                TextXAlignment       = Enum.TextXAlignment.Right,
                ZIndex               = row.ZIndex + 5,
            })

            -- Track container (full width, sits at bottom of row)
            local trackWrap = Make("Frame", {
                Parent               = row,
                AnchorPoint          = Vector2.new(0, 1),
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Position             = UDim2.new(0, 12, 1, -8),
                Size                 = UDim2.new(1, -24, 0, 5),
            })

            local track = Make("Frame", {
                Parent           = trackWrap,
                BackgroundColor3 = Color3.fromHex("1A1A28"),
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 1, 0),
            })
            Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

            local fill = Make("Frame", {
                Parent           = track,
                BackgroundColor3 = C.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 0, 1, 0),
            })
            Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

            -- Thumb
            local thumb = Make("Frame", {
                Parent           = fill,
                AnchorPoint      = Vector2.new(1, 0.5),
                BackgroundColor3 = C.White,
                BorderSizePixel  = 0,
                Position         = UDim2.new(1, 0, 0.5, 0),
                Size             = UDim2.new(0, 8, 0, 8),
                ZIndex           = row.ZIndex + 3,
            })
            Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })

            local data     = { Value = val }
            local dragging = false

            local function round(n, d)
                local f = 10 ^ d
                return math.floor(n * f + 0.5) / f
            end

            local function updateVal(v, animate)
                v = round(math.clamp(v, min, max), rnd)
                data.Value  = v
                valBox.Text = tostring(v)
                local ratio = (v - min) / (max - min)
                local dur   = animate and 0.08 or 0
                TweenPlay(fill, { Size = UDim2.new(ratio, 0, 1, 0) }, dur, Enum.EasingStyle.Linear)
                cb(v)
            end

            local function fromPos(inputPos)
                local ax = track.AbsolutePosition.X
                local aw = track.AbsoluteSize.X
                return math.clamp((inputPos.X - ax) / aw, 0, 1) * (max - min) + min
            end

            local sliderClick = ClickBtn(row)
            sliderClick.InputBegan:Connect(function(inp)
                if openDropdown then return end
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateVal(fromPos(inp.Position), true)
                    TweenPlay(titleL, { TextColor3 = C.Accent }, 0.1)
                    TweenPlay(valBox, { TextColor3 = C.Accent }, 0.1)
                end
            end)
            sliderClick.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    TweenPlay(titleL, { TextColor3 = C.TextPrimary }, 0.1)
                    TweenPlay(valBox, { TextColor3 = C.TextSecond }, 0.1)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if not dragging then return end
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    updateVal(fromPos(inp.Position), true)
                end
            end)
            valBox.FocusLost:Connect(function()
                updateVal(tonumber(valBox.Text) or data.Value, true)
            end)

            updateVal(val, false)

            local obj = {}
            function obj:Set(v) updateVal(v, true) end
            function obj:Get() return data.Value end
            setmetatable(obj, {
                __newindex = function(_, k, v)
                    if k == "Value" then updateVal(v, true) end
                end,
                __index = data,
            })
            return obj
        end

        -- ── Button ────────────────────────────────────────────────────────────
        function Tab:Button(bArgs)
            bArgs  = bArgs or {}
            local cb = bArgs.Callback or function() end

            local row, _, _, rightFrame = MakeRow(page, bArgs.Title, bArgs.Desc)

            local btnText  = bArgs.Text or "Execute"
            local btn = Make("Frame", {
                Parent           = rightFrame,
                BackgroundColor3 = C.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 76, 0, 24),
            })
            Make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })

            local lbl = Make("TextLabel", {
                Parent               = btn,
                AnchorPoint          = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Position             = UDim2.new(0.5, 0, 0.5, 0),
                Size                 = UDim2.new(1, 0, 1, 0),
                Font                 = Enum.Font.GothamBold,
                Text                 = btnText,
                TextColor3           = Color3.fromHex("000D10"),
                TextSize             = 11,
            })
            -- Auto-size
            btn.Size = UDim2.new(0, lbl.TextBounds.X + 28, 0, 24)

            local click = ClickBtn(row)
            click.MouseButton1Click:Connect(function()
                if openDropdown then return end
                task.spawn(Ripple, btn, click)
                TweenPlay(btn, { BackgroundColor3 = C.AccentDim }, 0.08)
                task.delay(0.15, function()
                    TweenPlay(btn, { BackgroundColor3 = C.Accent }, 0.15)
                end)
                cb()
            end)

            return click
        end

        -- ── Input ─────────────────────────────────────────────────────────────
        function Tab:Input(iArgs)
            iArgs = iArgs or {}
            local cb  = iArgs.Callback or function() end
            local val = iArgs.Value    or ""

            local row, _, _, rightFrame = MakeRow(page, iArgs.Title, iArgs.Desc)

            local inputWrap = Make("Frame", {
                Parent           = rightFrame,
                BackgroundColor3 = C.Surface,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 130, 0, 24),
            })
            Make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = inputWrap })
            Make("UIStroke", { Color = C.Border, Thickness = 1, Parent = inputWrap })

            local field = Make("TextBox", {
                Parent               = inputWrap,
                AnchorPoint          = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Position             = UDim2.new(0.5, 0, 0.5, 0),
                Size                 = UDim2.new(1, -12, 1, 0),
                Font                 = Enum.Font.GothamMedium,
                PlaceholderColor3    = C.TextFaint,
                PlaceholderText      = iArgs.Placeholder or "Enter text…",
                Text                 = tostring(val),
                TextColor3           = C.TextPrimary,
                TextSize             = 11,
                TextXAlignment       = Enum.TextXAlignment.Left,
                ClearTextOnFocus     = false,
            })

            local stroke = inputWrap:FindFirstChildOfClass("UIStroke")
            field.Focused:Connect(function()
                if stroke then TweenPlay(stroke, { Color = C.Accent, Transparency = 0.4 }, 0.15) end
            end)
            field.FocusLost:Connect(function(enter)
                if stroke then TweenPlay(stroke, { Color = C.Border, Transparency = 0 }, 0.15) end
                if enter and field.Text ~= "" then cb(field.Text) end
            end)

            local obj = {}
            function obj:Get() return field.Text end
            function obj:Set(v) field.Text = tostring(v) end
            return obj
        end

        -- ── Keybind ───────────────────────────────────────────────────────────
        function Tab:Keybind(kArgs)
            kArgs    = kArgs or {}
            local cb = kArgs.BindPressed or function() end
            local currentKey = kArgs.Value or Enum.KeyCode.Unknown
            local listening  = false

            local row, _, _, rightFrame = MakeRow(page, kArgs.Title, kArgs.Desc)

            local badge = Make("TextButton", {
                Parent           = rightFrame,
                BackgroundColor3 = C.Surface,
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                Size             = UDim2.new(0, 72, 0, 22),
                Font             = Enum.Font.GothamMedium,
                Text             = currentKey.Name,
                TextColor3       = C.TextSecond,
                TextSize         = 11,
            })
            Make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = badge })
            Make("UIStroke", { Color = C.Border, Thickness = 1, Parent = badge })

            local function setKey(key)
                currentKey  = key
                badge.Text  = key.Name
                badge.TextColor3 = C.TextPrimary
                listening   = false
                TweenPlay(badge, { BackgroundColor3 = C.Surface }, 0.15)
            end

            badge.MouseButton1Click:Connect(function()
                listening    = true
                badge.Text   = "…"
                badge.TextColor3 = C.Accent
                TweenPlay(badge, { BackgroundColor3 = Color3.fromHex("001820") }, 0.15)
            end)

            UserInputService.InputBegan:Connect(function(inp, proc)
                if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
                    setKey(inp.KeyCode)
                elseif not proc and inp.KeyCode == currentKey then
                    cb(currentKey)
                end
            end)

            local obj = {}
            function obj:Get() return currentKey end
            function obj:Set(key) setKey(key) end
            return obj
        end

        -- ── Label / Paragraph ─────────────────────────────────────────────────
        function Tab:Label(lArgs)
            lArgs = lArgs or {}
            local row = Make("Frame", {
                Parent               = page,
                BackgroundColor3     = C.Card,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(1, 0, 0, 0),
                AutomaticSize        = Enum.AutomaticSize.Y,
            })
            Make("UICorner", { CornerRadius = UDim.new(0, 5), Parent = row })
            Make("UIStroke", { Color = C.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = row })
            Make("UIPadding", {
                Parent        = row,
                PaddingLeft   = UDim.new(0, 12),
                PaddingRight  = UDim.new(0, 12),
                PaddingTop    = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
            })

            local lbl = Make("TextLabel", {
                Parent               = row,
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(1, 0, 0, 0),
                AutomaticSize        = Enum.AutomaticSize.Y,
                Font                 = Enum.Font.GothamMedium,
                Text                 = lArgs.Text or "",
                TextColor3           = C.TextSecond,
                TextSize             = 12,
                TextXAlignment       = Enum.TextXAlignment.Left,
                TextWrapped          = true,
                RichText             = true,
            })

            local obj = {}
            function obj:Set(text) lbl.Text = tostring(text) end
            function obj:Get() return lbl.Text end
            return obj
        end

        -- ── Dropdown ──────────────────────────────────────────────────────────
        function Tab:Dropdown(dArgs)
            dArgs   = dArgs or {}
            local list    = dArgs.List     or {}
            local multi   = typeof(dArgs.Value) == "table"
            local val     = dArgs.Value    or (multi and {} or nil)
            local cb      = dArgs.Callback or function() end

            local row, titleL, descL, rightFrame = MakeRow(page, dArgs.Title, "")

            -- Show current value in desc
            local function getDisplayText()
                if multi then
                    return #val > 0 and table.concat(val, ", ") or "None"
                end
                return val and tostring(val) or "None"
            end
            descL.Text = getDisplayText()

            local chevron = Make("ImageLabel", {
                Parent               = rightFrame,
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(0, 12, 0, 12),
                Image                = "rbxassetid://132291592681506",
                ImageColor3          = C.Accent,
                ImageTransparency    = 0.2,
            })

            -- Dropdown panel (attached to Background/container level)
            local ddPanel = Make("Frame", {
                Parent           = container,
                BackgroundColor3 = Color3.fromHex("0F0F1C"),
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 280, 0, 0),
                Position         = UDim2.new(0.5, -140, 0.5, 0),
                Visible          = false,
                ZIndex           = 600,
                ClipsDescendants = true,
            })
            Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ddPanel })
            Make("UIStroke", { Color = C.BorderBright, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = ddPanel })

            local ddInner = Make("Frame", {
                Parent               = ddPanel,
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(1, 0, 0, 0),
                AutomaticSize        = Enum.AutomaticSize.Y,
            })
            Make("UIListLayout", {
                Parent        = ddInner,
                Padding       = UDim.new(0, 3),
                SortOrder     = Enum.SortOrder.LayoutOrder,
            })
            Make("UIPadding", {
                Parent        = ddInner,
                PaddingLeft   = UDim.new(0, 8),
                PaddingRight  = UDim.new(0, 8),
                PaddingTop    = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
            })

            -- Search bar
            local searchBox = Make("TextBox", {
                Parent               = ddInner,
                BackgroundColor3     = C.Surface,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(1, 0, 0, 24),
                Font                 = Enum.Font.GothamMedium,
                PlaceholderColor3    = C.TextFaint,
                PlaceholderText      = "Search…",
                Text                 = "",
                TextColor3           = C.TextPrimary,
                TextSize             = 11,
                ZIndex               = ddPanel.ZIndex + 1,
                LayoutOrder          = -1,
            })
            Make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = searchBox })
            Make("UIStroke", { Color = C.Border, Thickness = 1, Parent = searchBox })
            Make("UIPadding", { PaddingLeft = UDim.new(0, 7), Parent = searchBox })

            local listScroll = Make("ScrollingFrame", {
                Parent               = ddInner,
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                Size                 = UDim2.new(1, 0, 0, 150),
                ScrollBarThickness   = 3,
                ScrollBarImageColor3 = C.Border,
                AutomaticCanvasSize  = Enum.AutomaticSize.Y,
                CanvasSize           = UDim2.new(0, 0, 0, 0),
                ZIndex               = ddPanel.ZIndex + 1,
                LayoutOrder          = 0,
            })
            local listLayout = Make("UIListLayout", {
                Parent  = listScroll,
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            local itemFrames = {}

            local function isSelected(name)
                if multi then
                    for _, v in ipairs(val) do if v == name then return true end end
                    return false
                end
                return val == name
            end

            local function addItem(name)
                local item = Make("TextButton", {
                    Parent               = listScroll,
                    BackgroundColor3     = isSelected(name) and Color3.fromHex("00202C") or C.Surface,
                    BackgroundTransparency = isSelected(name) and 0 or 0.4,
                    BorderSizePixel      = 0,
                    AutoButtonColor      = false,
                    Size                 = UDim2.new(1, 0, 0, 26),
                    Font                 = Enum.Font.GothamMedium,
                    Text                 = "",
                    ZIndex               = ddPanel.ZIndex + 2,
                })
                Make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = item })

                Make("TextLabel", {
                    Parent               = item,
                    AnchorPoint          = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel      = 0,
                    Position             = UDim2.new(0, 8, 0.5, 0),
                    Size                 = UDim2.new(1, -26, 0, 16),
                    Font                 = Enum.Font.GothamMedium,
                    Text                 = name,
                    TextColor3           = isSelected(name) and C.Accent or C.TextPrimary,
                    TextSize             = 11,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ZIndex               = item.ZIndex + 1,
                })

                item.MouseButton1Click:Connect(function()
                    if multi then
                        if isSelected(name) then
                            for i, v in ipairs(val) do if v == name then table.remove(val, i); break end end
                        else
                            table.insert(val, name)
                        end
                    else
                        val = name
                        openDropdown = nil
                        TweenPlay(ddPanel, { Size = UDim2.new(0, 280, 0, 0) }, 0.2, Enum.EasingStyle.Quad)
                        task.delay(0.22, function() ddPanel.Visible = false end)
                    end

                    -- refresh items
                    for _, f in ipairs(itemFrames) do
                        local lbl = f:FindFirstChildOfClass("TextLabel")
                        local sel = isSelected(f.Name)
                        TweenPlay(f, { BackgroundColor3 = sel and Color3.fromHex("00202C") or C.Surface, BackgroundTransparency = sel and 0 or 0.4 }, 0.12)
                        if lbl then lbl.TextColor3 = sel and C.Accent or C.TextPrimary end
                    end
                    descL.Text = getDisplayText()
                    cb(val)
                end)

                item.Name = name
                table.insert(itemFrames, item)
            end

            for _, name in ipairs(list) do addItem(name) end

            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local q = searchBox.Text:lower()
                for _, f in ipairs(itemFrames) do
                    f.Visible = f.Name:lower():find(q, 1, true) ~= nil
                end
            end)

            local isOpen = false
            local function toggleDropdown()
                isOpen = not isOpen
                if isOpen then
                    openDropdown = ddPanel
                    ddPanel.Visible = true
                    TweenPlay(ddPanel, { Size = UDim2.new(0, 280, 0, 200) }, 0.25, Enum.EasingStyle.Back)
                else
                    openDropdown = nil
                    TweenPlay(ddPanel, { Size = UDim2.new(0, 280, 0, 0) }, 0.18, Enum.EasingStyle.Quad)
                    task.delay(0.2, function() ddPanel.Visible = false end)
                end
            end

            local rowClick = ClickBtn(row)
            rowClick.MouseButton1Click:Connect(toggleDropdown)

            UserInputService.InputBegan:Connect(function(inp)
                if not isOpen then return end
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                local mx, my = LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y
                local dp, ds = ddPanel.AbsolutePosition, ddPanel.AbsoluteSize
                if not (mx >= dp.X and mx <= dp.X + ds.X and my >= dp.Y and my <= dp.Y + ds.Y) then
                    isOpen = false
                    openDropdown = nil
                    TweenPlay(ddPanel, { Size = UDim2.new(0, 280, 0, 0) }, 0.18)
                    task.delay(0.2, function() ddPanel.Visible = false end)
                end
            end)

            local obj = {}
            function obj:Get() return val end
            function obj:Set(v) val = v; descL.Text = getDisplayText() end
            function obj:Refresh(newList)
                for _, f in ipairs(itemFrames) do f:Destroy() end
                itemFrames = {}
                for _, name in ipairs(newList) do addItem(name) end
            end
            return obj
        end

        return Tab
    end -- Win:Tab

    return Win
end -- GoofyzUI:Window

return GoofyzUI

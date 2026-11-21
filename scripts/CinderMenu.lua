--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║  CINDER — Ember Client · Menu Interface                          ║
    ║  LocalScript · SOLO GUI (sin lógica de juego / sin cheats)       ║
    ║  Parent: gethui() · Un solo archivo · Sin assets externos         ║
    ║                                                                  ║
    ║  Identidad visual: "EMBER STUDY"                                 ║
    ║    · Paleta: obsidiana cálida + brasa (ember → ámbar)            ║
    ║    · Tipografía: GothamBlack / GothamBold / Gotham / Code        ║
    ║    · Iconografía 100% instancias (sin imágenes ni IDs)            ║
    ║                                                                  ║
    ║  Controles:                                                      ║
    ║    · Arrastrar  → barra superior                                 ║
    ║    · —          → minimizar a pill flotante (INSERT restaura)    ║
    ║    · ×          → cerrar (destruye la GUI)                       ║
    ║    · INSERT     → mostrar / minimizar                            ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

------------------------------------------------------------------------
-- 1 · PALETA / IDENTIDAD "EMBER STUDY"
------------------------------------------------------------------------
local C = {
    Background = Color3.fromRGB(17, 13, 12),  -- obsidiana cálida (fondo)
    Panel      = Color3.fromRGB(23, 18, 15),  -- barra superior / sidebar
    SideBottom = Color3.fromRGB(19, 15, 13),  -- sidebar (gradiente inferior)
    Surface    = Color3.fromRGB(33, 27, 23),  -- cards / controles
    SurfaceAlt = Color3.fromRGB(43, 35, 29),  -- hover
    SurfaceHi  = Color3.fromRGB(52, 42, 35),  -- hover fuerte
    Stroke     = Color3.fromRGB(64, 52, 44),  -- bordes sutiles
    StrokeSoft = Color3.fromRGB(48, 39, 33),  -- bordes más tenues
    Text       = Color3.fromRGB(246, 238, 230),
    Muted      = Color3.fromRGB(150, 133, 120),
    AccentA    = Color3.fromRGB(255, 133, 56),  -- brasa (ember)
    AccentB    = Color3.fromRGB(255, 198, 112), -- ámbar claro
    Deep       = Color3.fromRGB(198, 72, 28),   -- brasa profunda
    DeepDark   = Color3.fromRGB(56, 27, 15),    -- banner (extremo)
    Good       = Color3.fromRGB(116, 229, 159),
    Danger     = Color3.fromRGB(255, 92, 88),
    OnAccent   = Color3.fromRGB(46, 23, 9),     -- texto sobre gradiente
}

local F = {
    Black  = Enum.Font.GothamBlack,
    Bold   = Enum.Font.GothamBold,
    Medium = Enum.Font.GothamMedium,
    Reg    = Enum.Font.Gotham,
    Mono   = Enum.Font.Code,
}

local W, H          = 740, 470
local TOPBAR_H      = 52
local FOOTER_H      = 30
local SIDEBAR_W     = 190

------------------------------------------------------------------------
-- 2 · UTILIDADES
------------------------------------------------------------------------
local function create(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function addGradient(parent, colorA, colorB, rotation, transparencySeq)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(colorA, colorB)
    g.Rotation = rotation or 0
    if transparencySeq then
        g.Transparency = transparencySeq
    end
    g.Parent = parent
    return g
end

local function tween(inst, time, style, direction, props)
    local t = TweenService:Create(inst, TweenInfo.new(time, style, direction), props)
    t:Play()
    return t
end

local T_QUINT_OUT = Enum.EasingStyle.Quint
local T_QUART_OUT = Enum.EasingStyle.Quart
local T_SINE      = Enum.EasingStyle.Sine
local OUT         = Enum.EasingDirection.Out
local IN          = Enum.EasingDirection.In
local INOUT       = Enum.EasingDirection.InOut

------------------------------------------------------------------------
-- 3 · PARENT (gethui) + ScreenGui
------------------------------------------------------------------------
local uiParent = (gethui and gethui()) or game:GetService("CoreGui")

local previous = uiParent:FindFirstChild("CinderInterface")
if previous then previous:Destroy() end

local ScreenGui = create("ScreenGui", {
    Name             = "CinderInterface",
    ResetOnSpawn     = false,
    IgnoreGuiInset   = true,
    DisplayOrder     = 100,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    Enabled          = true,
    Parent           = uiParent,
})

-- Flag global: al cerrar/destruir la GUI se desactivan callbacks globales
local closed = false

-- Raíz: CanvasGroup para fades globales del menú completo
local Root = create("CanvasGroup", {
    Name            = "Root",
    BackgroundTransparency = 1,
    Size            = UDim2.fromScale(1, 1),
    GroupTransparency = 1,
    Parent          = ScreenGui,
})

------------------------------------------------------------------------
-- 4 · SOMBRA + MAIN (arrastrable)
------------------------------------------------------------------------
local Shadow = create("Frame", {
    Name             = "Shadow",
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = UDim2.new(0.5, 0, 0.5, 10),
    Size             = UDim2.fromOffset(W + 18, H + 18),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.55,
    Parent           = Root,
})
addCorner(Shadow, 20)

local Main = create("Frame", {
    Name             = "Main",
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = UDim2.new(0.5, 0, 0.5, 0),
    Size             = UDim2.fromOffset(W, H),
    BackgroundColor3 = C.Background,
    ClipsDescendants = true,
    Parent           = Root,
})
addCorner(Main, 14)
addGradient(Main, Color3.fromRGB(24, 19, 16), Color3.fromRGB(14, 11, 10), 90)
addStroke(Main, C.Stroke, 1, 0.15)

local MainScale = create("UIScale", { Scale = 0.92 }, nil)
MainScale.Parent = Main

-- Marca de agua gigante (detalle de profundidad)
create("TextLabel", {
    Name             = "Watermark",
    BackgroundTransparency = 1,
    AnchorPoint      = Vector2.new(1, 1),
    Position         = UDim2.new(1, -14, 1, -FOOTER_H - 4),
    Size             = UDim2.fromOffset(340, 150),
    Text             = "CINDER",
    TextColor3       = C.Text,
    TextTransparency = 0.955,
    Font             = F.Black,
    TextSize         = 132,
    TextXAlignment   = Enum.TextXAlignment.Right,
    ZIndex           = 0,
    Parent           = Main,
})

-- Referencias para labels "live" (FPS / uptime) usados en la sección Sesión
local liveFpsLabel, liveUptimeLabel = nil, nil

------------------------------------------------------------------------
-- 5 · HELPERS DE COMPONENTES (cards, secciones, controles)
------------------------------------------------------------------------
local function card(parent, height)
    local f = create("Frame", {
        BackgroundColor3 = C.Surface,
        Size             = UDim2.new(1, 0, 0, height),
        Parent           = parent,
    })
    addCorner(f, 10)
    addStroke(f, C.StrokeSoft, 1, 0.15)
    return f
end

local function createSection(parent, text)
    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 22),
        Parent           = parent,
    })
    local diamond = create("Frame", {
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 1, 0.5, 0),
        Size             = UDim2.fromOffset(6, 6),
        Rotation         = 45,
        BackgroundColor3 = C.AccentA,
        Parent           = row,
    })
    addCorner(diamond, 1.5)
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(0, 220, 1, 0),
        Text             = text,
        TextColor3       = C.Muted,
        Font             = F.Bold,
        TextSize         = 9,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = row,
    })
    create("Frame", {
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.StrokeSoft,
        BackgroundTransparency = 0.35,
        Parent           = row,
    }).ZIndex = 0
    return row
end

-- ── Toggle ─────────────────────────────────────────────────────────────
local function createToggle(parent, label, desc, defaultOn)
    local state = defaultOn == true

    local row = card(parent, 54)
    local hit = create("TextButton", {
        Name                  = "Hit",
        BackgroundTransparency = 1,
        Text                  = "",
        Size                  = UDim2.fromScale(1, 1),
        ZIndex                = 5,
        Parent                = row,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 8),
        Size             = UDim2.new(1, -84, 0, 17),
        Text             = label,
        TextColor3       = C.Text,
        Font             = F.Bold,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = row,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 26),
        Size             = UDim2.new(1, -84, 0, 15),
        Text             = desc or "",
        TextColor3       = C.Muted,
        Font             = F.Reg,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = row,
    })

    -- Track + overlay con gradiente ember
    local track = create("Frame", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.fromOffset(46, 26),
        BackgroundColor3 = C.SurfaceAlt,
        Parent           = row,
    })
    addCorner(track, 13)
    local trackStroke = addStroke(track, C.Stroke, 1, 0.2)

    local overlay = create("Frame", {
        Size             = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = state and 0 or 1,
        Parent           = track,
    })
    addCorner(overlay, 13)
    addGradient(overlay, C.Deep, C.AccentA, 45)

    local knob = create("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = state and UDim2.new(1, -13, 0.5, 0) or UDim2.new(0, 13, 0.5, 0),
        Size             = UDim2.fromOffset(18, 18),
        BackgroundColor3 = C.Text,
        Parent           = track,
    })
    addCorner(knob, 9)

    -- Hover de card
    hit.MouseEnter:Connect(function()
        tween(row, 0.18, T_QUART_OUT, OUT, { BackgroundColor3 = C.SurfaceAlt })
    end)
    hit.MouseLeave:Connect(function()
        tween(row, 0.25, T_QUART_OUT, OUT, { BackgroundColor3 = C.Surface })
    end)

    local function render(animate)
        local goalKnob   = state and UDim2.new(1, -13, 0.5, 0) or UDim2.new(0, 13, 0.5, 0)
        local overlayGoal = state and 0 or 1
        local strokeGoal  = state and C.Deep or C.Stroke
        if animate then
            tween(knob,    0.32, T_QUINT_OUT, OUT, { Position = goalKnob })
            tween(overlay, 0.28, T_QUART_OUT, OUT, { BackgroundTransparency = overlayGoal })
            tween(trackStroke, 0.28, T_QUART_OUT, OUT, { Color = strokeGoal })
        else
            knob.Position = goalKnob
            overlay.BackgroundTransparency = overlayGoal
            trackStroke.Color = strokeGoal
        end
    end

    hit.MouseButton1Click:Connect(function()
        state = not state
        render(true)
    end)

    render(false)
    return row
end

-- ── Slider ─────────────────────────────────────────────────────────────
local function createSlider(parent, label, min, max, default, suffix)
    local suffix = suffix or ""
    local value  = math.clamp(default or min, min, max)

    local row = card(parent, 64)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 9),
        Size             = UDim2.new(1, -90, 0, 16),
        Text             = label,
        TextColor3       = C.Text,
        Font             = F.Bold,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = row,
    })

    local valueLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, -14, 0, 9),
        Size             = UDim2.new(0, 70, 0, 16),
        Text             = tostring(math.floor(value + 0.5)) .. suffix,
        TextColor3       = C.AccentB,
        Font             = F.Mono,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Right,
        Parent           = row,
    })

    -- Zona de interacción (hit area generosa)
    local hit = create("TextButton", {
        BackgroundTransparency = 1,
        Text                  = "",
        Position              = UDim2.new(0, 8, 0, 28),
        Size                  = UDim2.new(1, -16, 0, 28),
        Parent                = row,
    })

    local bar = create("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = C.SurfaceAlt,
        Parent           = hit,
    })
    addCorner(bar, 3)

    local fill = create("Frame", {
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent           = bar,
    })
    addCorner(fill, 3)
    addGradient(fill, C.Deep, C.AccentA, 0)

    local knobShadow = create("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        Size             = UDim2.fromOffset(21, 21),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        ZIndex           = 2,
        Parent           = hit,
    })
    addCorner(knobShadow, 11)

    local knob = create("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
        Size             = UDim2.fromOffset(16, 16),
        BackgroundColor3 = C.Text,
        ZIndex           = 3,
        Parent           = hit,
    })
    addCorner(knob, 8)
    addStroke(knob, C.Deep, 2, 0)

    local function setValue(v, animate)
        value = math.clamp(v, min, max)
        local pct = (value - min) / (max - min)
        valueLabel.Text = tostring(math.floor(value + 0.5)) .. suffix
        local pos = UDim2.new(pct, 0, 0.5, 0)
        local fillGoal = UDim2.new(pct, 0, 1, 0)
        if animate then
            tween(knob,       0.18, T_QUART_OUT, OUT, { Position = pos })
            tween(knobShadow, 0.18, T_QUART_OUT, OUT, { Position = pos })
            tween(fill,       0.18, T_QUART_OUT, OUT, { Size = fillGoal })
        else
            knob.Position, knobShadow.Position = pos, pos
            fill.Size = fillGoal
        end
    end

    local dragging = false
    local function valueFromInput(input)
        local absPos, absSize = hit.AbsolutePosition, hit.AbsoluteSize
        local rel = (input.Position.X - absPos.X) / absSize.X
        return min + math.clamp(rel, 0, 1) * (max - min)
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setValue(valueFromInput(input), true)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if closed or not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            setValue(valueFromInput(input), false)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return row
end

-- ── Dropdown (acordeón dentro del layout) ──────────────────────────────
local openDropdownClose = nil

local function createDropdown(parent, label, options, defaultIndex)
    local selected = options[defaultIndex or 1]
    local OPTION_H = 34
    local openH = #options * OPTION_H + 10
    local WRAP_OPEN = 50 + openH

    local wrap = create("Frame", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 46),
        Parent           = parent,
    })

    local button = card(wrap, 46)
    button.Size = UDim2.new(1, 0, 1, 0)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(0.55, 0, 1, 0),
        Text             = label,
        TextColor3       = C.Text,
        Font             = F.Bold,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = button,
    })

    local valueLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -38, 0.5, 0),
        Size             = UDim2.new(0.45, 0, 0, 16),
        Text             = selected,
        TextColor3       = C.AccentB,
        Font             = F.Medium,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Right,
        Parent           = button,
    })

    -- Chevron dibujado con instancias
    local chevron = create("Frame", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -12, 0.5, 0),
        Size             = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Parent           = button,
    })
    local barA = create("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, -2.6, 0.5, 0),
        Size             = UDim2.fromOffset(8, 2),
        Rotation         = 45,
        BackgroundColor3 = C.Muted,
        Parent           = chevron,
    })
    local barB = create("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 2.6, 0.5, 0),
        Size             = UDim2.fromOffset(8, 2),
        Rotation         = -45,
        BackgroundColor3 = C.Muted,
        Parent           = chevron,
    })
    addCorner(barA, 1); addCorner(barB, 1)

    -- Acordeón de opciones
    wrap.ClipsDescendants = true
    local accordion = create("Frame", {
        Position         = UDim2.new(0, 0, 0, 50),
        Size             = UDim2.new(1, 0, 0, openH),
        BackgroundColor3 = C.Surface,
        ClipsDescendants = true,
        BackgroundTransparency = 1, -- arranca invisible; se ve al abrir
        Parent           = wrap,
    })
    addCorner(accordion, 10)
    local accordionStroke = addStroke(accordion, C.StrokeSoft, 1, 1)

    local listPad = create("UIPadding", {
        PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5),
        Parent = accordion,
    })

    local optionButtons = {}
    local isOpen = false

    local function setOpen(state, animate)
        isOpen = state
        local goalSize = state
            and UDim2.new(1, 0, 0, WRAP_OPEN)
            or  UDim2.new(1, 0, 0, 46)
        if animate then
            tween(wrap, 0.32, T_QUINT_OUT, OUT, { Size = goalSize })
            tween(accordion, 0.32, T_QUINT_OUT, OUT, { BackgroundTransparency = state and 0 or 1 })
            tween(accordionStroke, 0.32, T_QUINT_OUT, OUT, { Transparency = state and 0.15 or 1 })
            tween(chevron, 0.32, T_QUINT_OUT, OUT, { Rotation = state and 180 or 0 })
        else
            wrap.Size = goalSize
            accordion.BackgroundTransparency = state and 0 or 1
            accordionStroke.Transparency = state and 0.15 or 1
            chevron.Rotation = state and 180 or 0
        end
    end

    for i, option in ipairs(options) do
        local rowBtn = create("TextButton", {
            BackgroundColor3 = C.SurfaceAlt,
            BackgroundTransparency = 1,
            Text                  = "",
            Size                  = UDim2.new(1, 0, 0, OPTION_H),
            LayoutOrder           = i,
            AutoButtonColor       = false,
            Parent                = accordion,
        })
        addCorner(rowBtn, 7)
        local optLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position         = UDim2.new(0, 10, 0, 0),
            Size             = UDim2.new(1, -40, 1, 0),
            Text             = option,
            TextColor3       = (option == selected) and C.AccentB or C.Text,
            Font             = (option == selected) and F.Bold or F.Reg,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = rowBtn,
        })
        local dot = create("Frame", {
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, -10, 0.5, 0),
            Size             = UDim2.fromOffset(6, 6),
            BackgroundColor3 = C.AccentA,
            BackgroundTransparency = (option == selected) and 0 or 1,
            Parent           = rowBtn,
        })
        addCorner(dot, 3)

        rowBtn.MouseEnter:Connect(function()
            tween(rowBtn, 0.15, T_QUART_OUT, OUT, { BackgroundTransparency = 0, BackgroundColor3 = C.SurfaceAlt })
        end)
        rowBtn.MouseLeave:Connect(function()
            tween(rowBtn, 0.2, T_QUART_OUT, OUT, { BackgroundTransparency = 1 })
        end)
        rowBtn.MouseButton1Click:Connect(function()
            selected = option
            valueLabel.Text = option
            for _, other in ipairs(optionButtons) do
                local lbl, d = other[1], other[2]
                local isSel = lbl.Text == option
                lbl.TextColor3 = isSel and C.AccentB or C.Text
                lbl.Font       = isSel and F.Bold or F.Reg
                tween(d, 0.2, T_QUART_OUT, OUT, { BackgroundTransparency = isSel and 0 or 1 })
            end
            setOpen(false, true)
            openDropdownClose = nil
        end)

        table.insert(optionButtons, { optLabel, dot })
    end

    -- Layout interno del acordeón
    local accLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, 2),
        Parent        = accordion,
    })

    local clickZone = create("TextButton", {
        BackgroundTransparency = 1,
        Text                  = "",
        Size                  = UDim2.fromScale(1, 1),
        ZIndex                = 6,
        Parent                = button,
    })
    clickZone.MouseEnter:Connect(function()
        tween(button, 0.18, T_QUART_OUT, OUT, { BackgroundColor3 = C.SurfaceAlt })
    end)
    clickZone.MouseLeave:Connect(function()
        tween(button, 0.25, T_QUART_OUT, OUT, { BackgroundColor3 = C.Surface })
    end)
    clickZone.MouseButton1Click:Connect(function()
        if openDropdownClose and openDropdownClose ~= setOpen then
            openDropdownClose(false, true)
        end
        setOpen(not isOpen, true)
        openDropdownClose = isOpen and setOpen or nil
    end)

    setOpen(false, false)
    return wrap
end

-- ── Botón ──────────────────────────────────────────────────────────────
local function createButton(parent, text, style, onClick)
    local isPrimary = style == "primary"
    local isDanger  = style == "danger"

    local btn = create("TextButton", {
        BackgroundColor3 = isPrimary and C.AccentA or C.Surface,
        Text             = "",
        AutoButtonColor  = false,
        Size             = UDim2.new(0.5, -5, 1, 0),
        Parent           = parent,
    })
    addCorner(btn, 10)

    if isPrimary then
        addGradient(btn, C.AccentB, C.AccentA, 0)
        addStroke(btn, C.Deep, 1, 0.1)
    elseif isDanger then
        addStroke(btn, C.Danger, 1, 0.35)
    else
        addStroke(btn, C.StrokeSoft, 1, 0.15)
    end

    local scale = create("UIScale", { Scale = 1 }, nil)
    scale.Parent = btn

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size                  = UDim2.fromScale(1, 1),
        Text                  = text,
        TextColor3            = isPrimary and C.OnAccent or (isDanger and C.Danger or C.Text),
        Font                  = F.Bold,
        TextSize              = 12,
        Parent                = btn,
    })

    -- Overlay para hover suave
    local overlay = create("Frame", {
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Size                   = UDim2.fromScale(1, 1),
        ZIndex                 = 2,
        Parent                 = btn,
    })
    addCorner(overlay, 10)

    btn.MouseEnter:Connect(function()
        tween(overlay, 0.16, T_QUART_OUT, OUT, { BackgroundTransparency = isPrimary and 0.88 or 0.94 })
        tween(btn, 0.16, T_QUART_OUT, OUT, { BackgroundColor3 = isPrimary and C.AccentA or C.SurfaceAlt })
    end)
    btn.MouseLeave:Connect(function()
        tween(overlay, 0.22, T_QUART_OUT, OUT, { BackgroundTransparency = 1 })
        tween(btn, 0.22, T_QUART_OUT, OUT, { BackgroundColor3 = isPrimary and C.AccentA or C.Surface })
    end)
    btn.MouseButton1Down:Connect(function()
        tween(scale, 0.1, T_QUART_OUT, OUT, { Scale = 0.955 })
    end)
    btn.MouseButton1Up:Connect(function()
        tween(scale, 0.32, Enum.EasingStyle.Back, OUT, { Scale = 1 })
    end)
    if onClick then
        btn.MouseButton1Click:Connect(onClick)
    end
    return btn
end

-- ── TextBox ────────────────────────────────────────────────────────────
local function createTextboxRow(parent, label, defaultText, placeholder)
    local row = card(parent, 46)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(0.45, 0, 1, 0),
        Text             = label,
        TextColor3       = C.Text,
        Font             = F.Bold,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = row,
    })

    local box = create("TextBox", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -12, 0.5, 0),
        Size             = UDim2.new(0.52, 0, 0, 30),
        BackgroundColor3 = C.SurfaceAlt,
        Text             = defaultText or "",
        PlaceholderText  = placeholder or "",
        PlaceholderColor3 = C.Muted,
        TextColor3       = C.Text,
        Font             = F.Medium,
        TextSize         = 11,
        ClearTextOnFocus = false,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = row,
    })
    addCorner(box, 8)
    local stroke = addStroke(box, C.StrokeSoft, 1, 0.1)
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = box })

    box.Focused:Connect(function()
        tween(stroke, 0.18, T_QUART_OUT, OUT, { Color = C.AccentA, Transparency = 0 })
    end)
    box.FocusLost:Connect(function()
        tween(stroke, 0.25, T_QUART_OUT, OUT, { Color = C.StrokeSoft, Transparency = 0.1 })
    end)
    return row
end

-- ── Keybind picker ─────────────────────────────────────────────────────
local function createKeybind(parent, label, defaultKey)
    local keyName = defaultKey

    local row = card(parent, 46)
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 0),
        Size             = UDim2.new(0.55, 0, 1, 0),
        Text             = label,
        TextColor3       = C.Text,
        Font             = F.Bold,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = row,
    })

    local bindButton = create("TextButton", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -12, 0.5, 0),
        Size             = UDim2.fromOffset(96, 28),
        BackgroundColor3 = C.SurfaceAlt,
        Text             = keyName,
        TextColor3       = C.AccentB,
        Font             = F.Mono,
        TextSize         = 11,
        AutoButtonColor  = false,
        Parent           = row,
    })
    addCorner(bindButton, 7)
    local stroke = addStroke(bindButton, C.StrokeSoft, 1, 0.1)

    local listening = false
    bindButton.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        bindButton.Text = "···"
        tween(stroke, 0.15, T_QUART_OUT, OUT, { Color = C.AccentA, Transparency = 0 })

        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            conn:Disconnect()
            listening = false
            if input.KeyCode == Enum.KeyCode.Escape then
                bindButton.Text = keyName -- cancelar: restaurar
            else
                keyName = input.KeyCode.Name
                bindButton.Text = keyName
            end
            tween(stroke, 0.3, T_QUART_OUT, OUT, { Color = C.StrokeSoft, Transparency = 0.1 })
        end)
    end)

    bindButton.MouseEnter:Connect(function()
        if not listening then
            tween(bindButton, 0.15, T_QUART_OUT, OUT, { BackgroundColor3 = C.SurfaceHi })
        end
    end)
    bindButton.MouseLeave:Connect(function()
        tween(bindButton, 0.2, T_QUART_OUT, OUT, { BackgroundColor3 = C.SurfaceAlt })
    end)
    return row
end

-- ── Stat card ──────────────────────────────────────────────────────────
local function createStatCard(parent, label, value, sub, liveKey)
    local c = create("Frame", {
        BackgroundColor3 = C.Surface,
        Size             = UDim2.new(1 / 3, -6, 1, 0),
        Parent           = parent,
    })
    addCorner(c, 10)
    addStroke(c, C.StrokeSoft, 1, 0.15)

    local diamond = create("Frame", {
        Position         = UDim2.new(0, 12, 0, 10),
        Size             = UDim2.fromOffset(5, 5),
        Rotation         = 45,
        BackgroundColor3 = C.AccentA,
        Parent           = c,
    })
    addCorner(diamond, 1.2)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 22, 0, 7),
        Size             = UDim2.new(1, -30, 0, 12),
        Text             = label,
        TextColor3       = C.Muted,
        Font             = F.Bold,
        TextSize         = 8,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = c,
    })

    local valueLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 12, 0, 22),
        Size             = UDim2.new(1, -24, 0, 24),
        Text             = value,
        TextColor3       = C.Text,
        Font             = F.Black,
        TextSize         = 19,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = c,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 12, 0, 46),
        Size             = UDim2.new(1, -24, 0, 12),
        Text             = sub,
        TextColor3       = C.Muted,
        Font             = F.Mono,
        TextSize         = 8,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = c,
    })

    if liveKey == "fps" then
        liveFpsLabel = valueLabel
    elseif liveKey == "uptime" then
        liveUptimeLabel = valueLabel
    end
    return c
end

------------------------------------------------------------------------
-- 6 · TOP BAR (logo, título, breadcrumb, controles)
------------------------------------------------------------------------
local TopBar = create("Frame", {
    Name             = "TopBar",
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, 0, 0, TOPBAR_H),
    Parent           = Main,
})

-- Logo: rombo ember + "C"
local logoMark = create("Frame", {
    Position         = UDim2.new(0, 16, 0.5, 0),
    AnchorPoint      = Vector2.new(0, 0.5),
    Size             = UDim2.fromOffset(26, 26),
    Rotation         = 45,
    BackgroundColor3 = Color3.new(1, 1, 1),
    Parent           = TopBar,
})
addCorner(logoMark, 7)
addGradient(logoMark, C.AccentB, C.Deep, 45)
addStroke(logoMark, C.OnAccent, 1, 0.55)
create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 16, 0.5, 0),
    AnchorPoint      = Vector2.new(0, 0.5),
    Size             = UDim2.fromOffset(26, 26),
    Text             = "C",
    TextColor3       = C.OnAccent,
    Font             = F.Black,
    TextSize         = 15,
    Parent           = TopBar,
})

create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 50, 0.5, -10),
    Size             = UDim2.fromOffset(90, 17),
    Text             = "CINDER",
    TextColor3       = C.Text,
    Font             = F.Black,
    TextSize         = 15,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = TopBar,
})
create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 50, 0.5, 6),
    Size             = UDim2.fromOffset(150, 10),
    Text             = "E M B E R   C L I E N T",
    TextColor3       = C.Muted,
    Font             = F.Bold,
    TextSize         = 7,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = TopBar,
})

-- Breadcrumb central: CINDER / <TAB>
local breadcrumb = create("Frame", {
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = UDim2.new(0.5, 0, 0.5, 0),
    Size             = UDim2.fromOffset(0, 18),
    AutomaticSize    = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Parent           = TopBar,
})
create("UIListLayout", {
    FillDirection    = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding          = UDim.new(0, 7),
    Parent           = breadcrumb,
})
create("TextLabel", {
    BackgroundTransparency = 1,
    Size             = UDim2.new(0, 0, 0, 14),
    AutomaticSize    = Enum.AutomaticSize.X,
    Text             = "CINDER",
    TextColor3       = C.Muted,
    Font             = F.Mono,
    TextSize         = 9,
    Parent           = breadcrumb,
})
create("TextLabel", {
    BackgroundTransparency = 1,
    Size             = UDim2.new(0, 0, 0, 14),
    AutomaticSize    = Enum.AutomaticSize.X,
    Text             = "/",
    TextColor3       = C.AccentA,
    Font             = F.Mono,
    TextSize         = 10,
    Parent           = breadcrumb,
})
local breadcrumbTab = create("TextLabel", {
    BackgroundTransparency = 1,
    Size             = UDim2.new(0, 0, 0, 14),
    AutomaticSize    = Enum.AutomaticSize.X,
    Text             = "DASHBOARD",
    TextColor3       = C.Text,
    Font             = F.Mono,
    TextSize         = 9,
    Parent           = breadcrumb,
})

-- Controles de ventana: minimizar / cerrar (glifos dibujados)
local controls = create("Frame", {
    AnchorPoint      = Vector2.new(1, 0.5),
    Position         = UDim2.new(1, -14, 0.5, 0),
    Size             = UDim2.fromOffset(78, 32),
    BackgroundTransparency = 1,
    Parent           = TopBar,
})

local function windowButton(offsetX, isClose)
    local btn = create("TextButton", {
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, offsetX, 0.5, 0),
        Size             = UDim2.fromOffset(32, 32),
        BackgroundColor3 = C.Surface,
        BackgroundTransparency = 1,
        Text             = "",
        AutoButtonColor  = false,
        Parent           = controls,
    })
    addCorner(btn, 9)

    local glyphs = {}
    if isClose then
        for _, rot in ipairs({ 45, -45 }) do
            local bar = create("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.fromScale(0.5, 0.5),
                Size             = UDim2.fromOffset(12, 1.8),
                Rotation         = rot,
                BackgroundColor3 = C.Muted,
                Parent           = btn,
            })
            addCorner(bar, 1)
            table.insert(glyphs, bar)
        end
    else
        local bar = create("Frame", {
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.fromScale(0.5, 0.5),
            Size             = UDim2.fromOffset(12, 1.8),
            BackgroundColor3 = C.Muted,
            Parent           = btn,
        })
        addCorner(bar, 1)
        table.insert(glyphs, bar)
    end

    btn.MouseEnter:Connect(function()
        tween(btn, 0.16, T_QUART_OUT, OUT, {
            BackgroundTransparency = 0,
            BackgroundColor3       = isClose and C.Danger or C.SurfaceAlt,
        })
        for _, g in ipairs(glyphs) do
            tween(g, 0.16, T_QUART_OUT, OUT, { BackgroundColor3 = isClose and C.OnAccent or C.AccentB })
        end
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.22, T_QUART_OUT, OUT, { BackgroundTransparency = 1 })
        for _, g in ipairs(glyphs) do
            tween(g, 0.22, T_QUART_OUT, OUT, { BackgroundColor3 = C.Muted })
        end
    end)
    return btn
end

local minimizeBtn = windowButton(0, false)
local closeBtn    = windowButton(40, true)

-- Línea de acento inferior de la topbar (desvanecida en los bordes)
local topHairline = create("Frame", {
    Position         = UDim2.new(0, 0, 1, -1),
    Size             = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = C.Stroke,
    Parent           = TopBar,
})
addGradient(topHairline, C.Stroke, C.Stroke, 0, NumberSequence.new{
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.18, 0.2),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(0.82, 0.2),
    NumberSequenceKeypoint.new(1, 1),
})

------------------------------------------------------------------------
-- 7 · SIDEBAR (tabs + indicador + user chip)
------------------------------------------------------------------------
local Sidebar = create("Frame", {
    Name             = "Sidebar",
    BackgroundColor3 = Color3.fromRGB(1, 1, 1),
    Position         = UDim2.new(0, 0, 0, TOPBAR_H),
    Size             = UDim2.new(0, SIDEBAR_W, 1, -(TOPBAR_H + FOOTER_H)),
    Parent           = Main,
})
addGradient(Sidebar, Color3.fromRGB(25, 20, 17), C.SideBottom, 90)

-- Línea lateral derecha
local sideHairline = create("Frame", {
    AnchorPoint      = Vector2.new(1, 0),
    Position         = UDim2.new(1, 0, 0, 0),
    Size             = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = C.StrokeSoft,
    BackgroundTransparency = 0.15,
    Parent           = Sidebar,
})

create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 18, 0, 12),
    Size             = UDim2.fromOffset(120, 12),
    Text             = "M E N U",
    TextColor3       = C.Muted,
    Font             = F.Bold,
    TextSize         = 8,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = Sidebar,
})

local SIDEBAR_H = H - TOPBAR_H - FOOTER_H
local TABS_TOP  = 32
local TAB_H     = 40
local TAB_GAP   = 6
local tabsContainer = create("Frame", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 10, 0, TABS_TOP),
    Size             = UDim2.new(1, -20, 0, 5 * (TAB_H + TAB_GAP)),
    Parent           = Sidebar,
})
create("UIListLayout", {
    Padding           = UDim.new(0, TAB_GAP),
    Parent            = tabsContainer,
})

-- Indicador activo (barra ember + glow), posicionado a nivel de sidebar
local indicatorGlow = create("Frame", {
    Position         = UDim2.new(0, 0, 0, TABS_TOP),
    Size             = UDim2.fromOffset(8, TAB_H - 10),
    BackgroundColor3 = C.AccentA,
    BackgroundTransparency = 0.82,
    Parent           = Sidebar,
})
addCorner(indicatorGlow, 4)
local indicator = create("Frame", {
    Position         = UDim2.new(0, 0, 0, TABS_TOP + 5),
    Size             = UDim2.fromOffset(3, TAB_H - 10),
    BackgroundColor3 = Color3.new(1, 1, 1),
    Parent           = Sidebar,
})
addCorner(indicator, 1.5)
addGradient(indicator, C.AccentB, C.Deep, 90)

------------------------------------------------------------------------
-- Iconos por instancias (tintable)
------------------------------------------------------------------------
local function createIcon(kind, tint)
    local box = create("Frame", {
        Size                  = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
    })
    local fills, strokes = {}, {}

    if kind == "grid" then
        for _, pos in ipairs({ { 0, 0 }, { 11, 0 }, { 0, 11 }, { 11, 11 } }) do
            local p = create("Frame", {
                Position         = UDim2.fromOffset(pos[1], pos[2]),
                Size             = UDim2.fromOffset(7, 7),
                BackgroundColor3 = tint,
                Parent           = box,
            })
            addCorner(p, 2)
            table.insert(fills, p)
        end
    elseif kind == "crosshair" then
        local ring = create("Frame", {
            Position         = UDim2.fromOffset(1, 1),
            Size             = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Parent           = box,
        })
        addCorner(ring, 8)
        table.insert(strokes, addStroke(ring, tint, 1.8, 0))
        local dot = create("Frame", {
            Position         = UDim2.fromOffset(7, 7),
            Size             = UDim2.fromOffset(4, 4),
            BackgroundColor3 = tint,
            Parent           = box,
        })
        addCorner(dot, 2)
        table.insert(fills, dot)
    elseif kind == "chevrons" then
        for i = 0, 1 do
            local x = 2 + i * 8
            local top = create("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.fromOffset(x + 4, 6.2),
                Size             = UDim2.fromOffset(9, 2.4),
                Rotation         = 45,
                BackgroundColor3 = tint,
                Parent           = box,
            })
            addCorner(top, 1.2)
            local bottom = create("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.fromOffset(x + 4, 11.8),
                Size             = UDim2.fromOffset(9, 2.4),
                Rotation         = -45,
                BackgroundColor3 = tint,
                Parent           = box,
            })
            addCorner(bottom, 1.2)
            table.insert(fills, top)
            table.insert(fills, bottom)
        end
    elseif kind == "eye" then
        local stadium = create("Frame", {
            Position         = UDim2.fromOffset(0.5, 4),
            Size             = UDim2.fromOffset(17, 10),
            BackgroundTransparency = 1,
            Parent           = box,
        })
        addCorner(stadium, 5)
        table.insert(strokes, addStroke(stadium, tint, 1.8, 0))
        local dot = create("Frame", {
            Position         = UDim2.fromOffset(7, 7),
            Size             = UDim2.fromOffset(4, 4),
            BackgroundColor3 = tint,
            Parent           = box,
        })
        addCorner(dot, 2)
        table.insert(fills, dot)
    elseif kind == "gear" then
        local ring = create("Frame", {
            Position         = UDim2.fromOffset(4.5, 4.5),
            Size             = UDim2.fromOffset(9, 9),
            BackgroundTransparency = 1,
            Parent           = box,
        })
        addCorner(ring, 5)
        table.insert(strokes, addStroke(ring, tint, 1.6, 0))
        for i = 0, 7 do
            local angle = math.rad(i * 45)
            local spoke = create("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(0.5, math.cos(angle) * 6.9, 0.5, math.sin(angle) * 6.9),
                Size             = UDim2.fromOffset(2.3, 4.6),
                Rotation         = i * 45,
                BackgroundColor3 = tint,
                Parent           = box,
            })
            addCorner(spoke, 1.15)
            table.insert(fills, spoke)
        end
    end

    return box, fills, strokes
end

-- Forward declarations (asignadas más abajo)
local switchTo, closeMenu

------------------------------------------------------------------------
-- 8 · TOAST LAYER (notificaciones demo, solo visual)
------------------------------------------------------------------------
local toastLayer = create("Frame", {
    Name             = "ToastLayer",
    AnchorPoint      = Vector2.new(1, 1),
    Position         = UDim2.new(1, -18, 1, -44),
    Size             = UDim2.fromOffset(300, 260),
    BackgroundTransparency = 1,
    Parent           = ScreenGui,
})
create("UIListLayout", {
    FillDirection      = Enum.FillDirection.Vertical,
    VerticalAlignment  = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding            = UDim.new(0, 8),
    Parent             = toastLayer,
})

local function showToast(title, msg)
    local toast = create("CanvasGroup", {
        BackgroundTransparency = 1,
        ClipsDescendants   = true,
        Size               = UDim2.new(1, 0, 0, 0),
        GroupTransparency  = 1,
        LayoutOrder        = -tick(),
        Parent             = toastLayer,
    })
    local body = create("Frame", {
        BackgroundColor3 = C.Surface,
        Size             = UDim2.fromScale(1, 1),
        Parent           = toast,
    })
    addCorner(body, 10)
    addStroke(body, C.StrokeSoft, 1, 0.1)

    local bar = create("Frame", {
        Position         = UDim2.fromScale(0, 0),
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent           = body,
    })
    addGradient(bar, C.AccentB, C.Deep, 90)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 15, 0, 7),
        Size             = UDim2.new(1, -28, 0, 13),
        Text             = title,
        TextColor3       = C.AccentB,
        Font             = F.Bold,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = body,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 15, 0, 22),
        Size             = UDim2.new(1, -28, 0, 13),
        Text             = msg,
        TextColor3       = C.Muted,
        Font             = F.Reg,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = body,
    })

    tween(toast, 0.38, T_QUINT_OUT, OUT, { GroupTransparency = 0, Size = UDim2.new(1, 0, 0, 52) })
    task.delay(3.6, function()
        tween(toast, 0.3, T_QUART_OUT, IN, { GroupTransparency = 1, Size = UDim2.new(1, 0, 0, 0) })
        task.delay(0.32, function()
            if toast then toast:Destroy() end
        end)
    end)
end

------------------------------------------------------------------------
-- 9 · TABS (sidebar) — creación
------------------------------------------------------------------------
local TABS = {
    { name = "Dashboard", icon = "grid"      },
    { name = "Combat",    icon = "crosshair" },
    { name = "Movement",  icon = "chevrons"  },
    { name = "Visuals",   icon = "eye"       },
    { name = "Settings",  icon = "gear"      },
}

local tabs = {}
for i, def in ipairs(TABS) do
    local rowBg = create("Frame", {
        BackgroundColor3       = C.SurfaceAlt,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, TAB_H),
        LayoutOrder            = i,
        Parent                 = tabsContainer,
    })
    addCorner(rowBg, 9)
    local stroke = addStroke(rowBg, C.StrokeSoft, 1, 1)

    local icon, fills, strokes = createIcon(def.icon, C.Muted)
    icon.Position = UDim2.fromOffset(12, (TAB_H - 18) / 2)
    icon.Parent = rowBg

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 40, 0, 0),
        Size             = UDim2.new(1, -52, 1, 0),
        Text             = def.name,
        TextColor3       = C.Muted,
        Font             = F.Medium,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = rowBg,
    })

    local hit = create("TextButton", {
        BackgroundTransparency = 1,
        Text                  = "",
        Size                  = UDim2.fromScale(1, 1),
        ZIndex                = 5,
        Parent                = rowBg,
    })

    tabs[i] = { def = def, bg = rowBg, stroke = stroke, fills = fills, strokes = strokes, label = label, hit = hit }

    local index = i
    hit.MouseButton1Click:Connect(function()
        switchTo(index, true)
    end)
    hit.MouseEnter:Connect(function()
        if tabs[index].bg.BackgroundTransparency > 0.9 then
            tween(rowBg, 0.18, T_QUART_OUT, OUT, { BackgroundTransparency = 0, BackgroundColor3 = C.Surface })
        end
        tween(label, 0.18, T_QUART_OUT, OUT, { TextColor3 = C.Text })
    end)
    hit.MouseLeave:Connect(function()
        local active = tabs[index].active == true
        if not active then
            tween(rowBg, 0.25, T_QUART_OUT, OUT, { BackgroundTransparency = 1 })
            tween(label, 0.25, T_QUART_OUT, OUT, { TextColor3 = C.Muted })
        end
    end)
end

------------------------------------------------------------------------
-- 10 · CONTENT + PÁGINAS
------------------------------------------------------------------------
local Content = create("Frame", {
    Name             = "Content",
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, SIDEBAR_W, 0, TOPBAR_H),
    Size             = UDim2.new(1, -SIDEBAR_W, 1, -(TOPBAR_H + FOOTER_H)),
    Parent           = Main,
})

local function createPage()
    local page = create("Frame", {
        BackgroundTransparency = 1,
        Size             = UDim2.fromScale(1, 1),
        Visible          = false,
        ZIndex           = 2,
        Parent           = Content,
    })
    local scroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size             = UDim2.fromScale(1, 1),
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.AccentA,
        ScrollBarImageTransparency = 0.2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent           = page,
    })
    create("UIPadding", {
        PaddingLeft   = UDim.new(0, 16),
        PaddingRight  = UDim.new(0, 16),
        PaddingTop    = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 16),
        Parent        = scroll,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 10),
        Parent  = scroll,
    })
    return page, scroll
end

local pages = {}

-- ══ PAGE 1 · DASHBOARD ══
do
    local page, scroll = createPage()
    pages[1] = page

    -- Banner "welcome" con gradiente ember
    local banner = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 96),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ClipsDescendants = true,
        Parent           = scroll,
    })
    addCorner(banner, 12)
    addGradient(banner, Color3.fromRGB(66, 30, 15), Color3.fromRGB(29, 17, 12), 12)
    addStroke(banner, Color3.fromRGB(104, 52, 24), 1, 0.25)

    -- Anillos decorativos (instancias)
    local ring1 = create("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(1, 6, 0.5, 0),
        Size             = UDim2.fromOffset(128, 128),
        BackgroundTransparency = 1,
        Parent           = banner,
    })
    addCorner(ring1, 64)
    addStroke(ring1, C.AccentA, 1.6, 0.72)
    local ring2 = create("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(1, 6, 0.5, 0),
        Size             = UDim2.fromOffset(72, 72),
        BackgroundTransparency = 1,
        Parent           = banner,
    })
    addCorner(ring2, 36)
    addStroke(ring2, C.AccentB, 1.2, 0.8)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 16, 0, 15),
        Size             = UDim2.fromOffset(220, 10),
        Text             = "W E L C O M E   B A C K",
        TextColor3       = C.AccentB,
        Font             = F.Bold,
        TextSize         = 8,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = banner,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 16, 0, 27),
        Size             = UDim2.fromOffset(280, 23),
        Text             = "Raven Vermillion",
        TextColor3       = C.Text,
        Font             = F.Black,
        TextSize         = 21,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = banner,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 16, 0, 52),
        Size             = UDim2.fromOffset(320, 13),
        Text             = "All systems operational — 12 modules loaded.",
        TextColor3       = C.Muted,
        Font             = F.Reg,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = banner,
    })
    local pillTag = create("Frame", {
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 16, 1, -12),
        Size             = UDim2.fromOffset(52, 16),
        BackgroundColor3 = C.Deep,
        BackgroundTransparency = 0.15,
        Parent           = banner,
    })
    addCorner(pillTag, 8)
    create("TextLabel", {
        BackgroundTransparency = 1,
        Size                  = UDim2.fromScale(1, 1),
        Text                  = "v2.4.1",
        TextColor3            = C.AccentB,
        Font                  = F.Mono,
        TextSize              = 9,
        Parent                = pillTag,
    })

    createSection(scroll, "S E S S I O N")

    local statRow = create("Frame", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 78),
        Parent           = scroll,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding       = UDim.new(0, 9),
        Parent        = statRow,
    })
    createStatCard(statRow, "P I N G",    "23 ms",    "EU-WEST · STABLE")
    createStatCard(statRow, "F P S",      "144",      "CLIENT SIDE", "fps")
    createStatCard(statRow, "U P T I M E", "00:00",    "THIS SESSION", "uptime")

    createSection(scroll, "Q U I C K   A C T I O N S")

    local actionRow = create("Frame", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = scroll,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding       = UDim.new(0, 9),
        Parent        = actionRow,
    })
    createButton(actionRow, "Reload Interface", "primary", function()
        showToast("CINDER", "Interface reloaded in 0.03s")
    end)
    createButton(actionRow, "Send Test Toast", "ghost", function()
        showToast("Config", "Settings saved to workspace/Cinder.cfg")
    end)

    createSection(scroll, "P R E F E R E N C E S")
    createToggle(scroll, "Desktop Notifications", "Push toast alerts to the top-right corner", true)
    createToggle(scroll, "Auto-Update Client", "Fetch the latest build on launch", true)
    createToggle(scroll, "Verbose Logs", "Print debug output to the console", false)
end

-- ══ PAGE 2 · COMBAT ══
do
    local page, scroll = createPage()
    pages[2] = page

    createSection(scroll, "E N G A G E M E N T")
    createToggle(scroll, "Silent Aim", "Route corrections without visual snap", true)
    createToggle(scroll, "Auto Fire", "Release shots when the reticle settles", false)
    createToggle(scroll, "Prediction", "Compensate for projectile travel time", true)
    createSlider(scroll, "Field of View", 10, 120, 60, "°")
    createSlider(scroll, "Smoothness", 0, 100, 45, "%")
    createDropdown(scroll, "Target Priority", { "Distance", "Health", "Nearest" }, 1)

    createSection(scroll, "B I N D I N G S")
    createKeybind(scroll, "Aim Key", "Q")
    createKeybind(scroll, "Toggle Menu", "Insert")
end

-- ══ PAGE 3 · MOVEMENT ══
do
    local page, scroll = createPage()
    pages[3] = page

    createSection(scroll, "M O V E M E N T")
    createToggle(scroll, "Infinite Stamina", "Disable stamina drain while sprinting", true)
    createToggle(scroll, "Water Walk", "Maintain footing on water surfaces", false)
    createToggle(scroll, "Air Dash", "Second burst while airborne", true)
    createSlider(scroll, "Walk Speed", 16, 100, 24, " st")
    createSlider(scroll, "Jump Power", 50, 175, 52, " st")
    createDropdown(scroll, "Sprint Mode", { "Hold", "Toggle" }, 1)
end

-- ══ PAGE 4 · VISUALS ══
do
    local page, scroll = createPage()
    pages[4] = page

    createSection(scroll, "R E N D E R")
    createToggle(scroll, "ESP Boxes", "Draw skeletal bounds through walls", true)
    createToggle(scroll, "Tracers", "Beam lines from screen to targets", true)
    createToggle(scroll, "Name Tags", "Username and distance overlay", false)
    createToggle(scroll, "Off-Screen Arrows", "Edge pointers toward targets", true)
    createSlider(scroll, "Render Distance", 100, 2000, 800, " st")
    createDropdown(scroll, "Accent Theme", { "Ember", "Toxic", "Glacier", "Ultraviolet" }, 1)
    createDropdown(scroll, "Box Style", { "Corner", "Full", "Eight-Head" }, 1)
end

-- ══ PAGE 5 · SETTINGS ══
do
    local page, scroll = createPage()
    pages[5] = page

    createSection(scroll, "G E N E R A L")
    createTextboxRow(scroll, "Player Tag", "raven.vfx", "display name…")
    createTextboxRow(scroll, "Clan Tag", "EMBR", "3–4 chars…")
    createDropdown(scroll, "UI Scale", { "75%", "100%", "125%" }, 2)
    createKeybind(scroll, "Menu Toggle", "Insert")
    createKeybind(scroll, "Panic Key", "Delete")

    createSection(scroll, "M A I N T E N A N C E")
    local btnRow = create("Frame", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = scroll,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding       = UDim.new(0, 9),
        Parent        = btnRow,
    })
    createButton(btnRow, "Factory Reset", "ghost", function()
        showToast("Settings", "Configuration reset to defaults")
    end)
    createButton(btnRow, "Unload Interface", "danger", function()
        if closeMenu then closeMenu() end
    end)

    createSection(scroll, "A B O U T")
    create("TextLabel", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 16),
        Text             = "CINDER — Ember Client",
        TextColor3       = C.Text,
        Font             = F.Bold,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = scroll,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 14),
        Text             = "Build 2401 · Single-file LocalScript · Design language: EMBER STUDY",
        TextColor3       = C.Muted,
        Font             = F.Mono,
        TextSize         = 9,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = scroll,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 14),
        Text             = "Palette Ember→Amber on warm obsidian · Gotham series",
        TextColor3       = C.Muted,
        Font             = F.Mono,
        TextSize         = 9,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = scroll,
    })
end

------------------------------------------------------------------------
-- 11 · TAB SWITCHING + INDICADOR
------------------------------------------------------------------------
switchTo = function(index, animate)
    for j, tab in ipairs(tabs) do
        local isActive = (j == index)
        tab.active = isActive

        if animate then
            tween(tab.bg, 0.3, T_QUINT_OUT, OUT, {
                BackgroundTransparency = isActive and 0 or 1,
                BackgroundColor3       = isActive and C.Surface or C.SurfaceAlt,
            })
            tween(tab.stroke, 0.3, T_QUART_OUT, OUT, { Transparency = isActive and 0.15 or 1 })
            tween(tab.label, 0.3, T_QUART_OUT, OUT, { TextColor3 = isActive and C.Text or C.Muted })
            for k, f in ipairs(tab.fills) do
                task.delay(k * 0.025, function()
                    if closed or not f.Parent then return end
                    tween(f, 0.28, T_QUART_OUT, OUT, { BackgroundColor3 = isActive and C.AccentA or C.Muted })
                end)
            end
            for k, s in ipairs(tab.strokes) do
                task.delay(k * 0.025, function()
                    if closed or not s.Parent then return end
                    tween(s, 0.28, T_QUART_OUT, OUT, { Color = isActive and C.AccentA or C.Muted })
                end)
            end
        else
            tab.bg.BackgroundTransparency = isActive and 0 or 1
            tab.bg.BackgroundColor3       = isActive and C.Surface or C.SurfaceAlt
            tab.stroke.Transparency       = isActive and 0.15 or 1
            tab.label.TextColor3          = isActive and C.Text or C.Muted
            for _, f in ipairs(tab.fills)   do f.BackgroundColor3 = isActive and C.AccentA or C.Muted end
            for _, s in ipairs(tab.strokes) do s.Color            = isActive and C.AccentA or C.Muted end
        end
    end

    local targetY = TABS_TOP + (index - 1) * (TAB_H + TAB_GAP) + 5
    if animate then
        tween(indicator, 0.45, T_QUINT_OUT, OUT, { Position = UDim2.new(0, 0, 0, targetY) })
        tween(indicatorGlow, 0.45, T_QUINT_OUT, OUT, { Position = UDim2.new(0, 0, 0, targetY - 5) })
    else
        indicator.Position    = UDim2.new(0, 0, 0, targetY)
        indicatorGlow.Position = UDim2.new(0, 0, 0, targetY - 5)
    end

    for j, p in ipairs(pages) do
        if j == index then
            p.Visible = true
            if animate then
                p.Position = UDim2.new(0, 22, 0, 0)
                tween(p, 0.42, T_QUINT_OUT, OUT, { Position = UDim2.new(0, 0, 0, 0) })
            else
                p.Position = UDim2.new(0, 0, 0, 0)
            end
        else
            p.Visible = false
        end
    end

    breadcrumbTab.Text = string.upper(TABS[index].name)
end

------------------------------------------------------------------------
-- 12 · USER CHIP (sidebar, abajo)
------------------------------------------------------------------------
local sideDivider = create("Frame", {
    Position         = UDim2.new(0, 16, 1, -94),
    Size             = UDim2.new(1, -32, 0, 1),
    BackgroundColor3 = C.StrokeSoft,
    BackgroundTransparency = 0.2,
    Parent           = Sidebar,
})

local chip = create("Frame", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 12, 1, -78),
    Size             = UDim2.new(1, -24, 0, 56),
    Parent           = Sidebar,
})
local avatar = create("Frame", {
    Position         = UDim2.new(0, 0, 0.5, 0),
    AnchorPoint      = Vector2.new(0, 0.5),
    Size             = UDim2.fromOffset(36, 36),
    BackgroundColor3 = Color3.new(1, 1, 1),
    Parent           = chip,
})
addCorner(avatar, 18)
addGradient(avatar, C.AccentB, C.Deep, 45)
addStroke(avatar, C.OnAccent, 1, 0.6)
create("TextLabel", {
    BackgroundTransparency = 1,
    Size                  = UDim2.fromScale(1, 1),
    Text                  = "RV",
    TextColor3            = C.OnAccent,
    Font                  = F.Black,
    TextSize              = 13,
    Parent                = avatar,
})
-- status dot (online)
local statusDot = create("Frame", {
    AnchorPoint      = Vector2.new(1, 1),
    Position         = UDim2.new(0, 36, 0.5, 17),
    Size             = UDim2.fromOffset(11, 11),
    BackgroundColor3 = C.Good,
    ZIndex           = 3,
    Parent           = chip,
})
addCorner(statusDot, 6)
addStroke(statusDot, Color3.fromRGB(19, 15, 13), 2, 0)

create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 46, 0, 6),
    Size             = UDim2.new(1, -46, 0, 15),
    Text             = "raven.vfx",
    TextColor3       = C.Text,
    Font             = F.Bold,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = chip,
})
create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 46, 0, 23),
    Size             = UDim2.new(1, -46, 0, 12),
    Text             = "D E V E L O P E R",
    TextColor3       = C.AccentB,
    Font             = F.Mono,
    TextSize         = 7,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = chip,
})

------------------------------------------------------------------------
-- 13 · FOOTER / STATUS BAR
------------------------------------------------------------------------
local Footer = create("Frame", {
    Name             = "Footer",
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 0, 1, -FOOTER_H),
    Size             = UDim2.new(1, 0, 0, FOOTER_H),
    Parent           = Main,
})
local footHairline = create("Frame", {
    Position         = UDim2.new(0, 0, 0, 0),
    Size             = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = C.Stroke,
    Parent           = Footer,
})
addGradient(footHairline, C.Stroke, C.Stroke, 0, NumberSequence.new{
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.18, 0.2),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(0.82, 0.2),
    NumberSequenceKeypoint.new(1, 1),
})

local footDot = create("Frame", {
    AnchorPoint      = Vector2.new(0, 0.5),
    Position         = UDim2.new(0, 16, 0.5, 0),
    Size             = UDim2.fromOffset(8, 8),
    BackgroundColor3 = C.Good,
    Parent           = Footer,
})
addCorner(footDot, 4)
-- Pulso de estado
do
    local pulse = TweenService:Create(footDot, TweenInfo.new(1.05, T_SINE, INOUT, -1, true), { BackgroundTransparency = 0.65 })
    pulse:Play()
end

create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 30, 0, 0),
    Size             = UDim2.fromOffset(120, FOOTER_H),
    Text             = "SYSTEMS NOMINAL",
    TextColor3       = C.Good,
    Font             = F.Mono,
    TextSize         = 8,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = Footer,
})
create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 138, 0, 0),
    Size             = UDim2.fromOffset(130, FOOTER_H),
    Text             = "·  12/12 MODULES",
    TextColor3       = C.Muted,
    Font             = F.Mono,
    TextSize         = 8,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = Footer,
})

local footRight = create("Frame", {
    AnchorPoint      = Vector2.new(1, 0),
    Position         = UDim2.new(1, -14, 0, 0),
    Size             = UDim2.fromOffset(268, FOOTER_H),
    BackgroundTransparency = 1,
    Parent           = Footer,
})
create("UIListLayout", {
    FillDirection     = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding           = UDim.new(0, 8),
    Parent            = footRight,
})

local uptimeFooter = create("TextLabel", {
    BackgroundTransparency = 1,
    Size             = UDim2.new(0, 62, 0, 14),
    Text             = "UP 00:00:00",
    TextColor3       = C.Muted,
    Font             = F.Mono,
    TextSize         = 8,
    LayoutOrder      = 1,
    Parent           = footRight,
})
create("TextLabel", {
    BackgroundTransparency = 1,
    Size             = UDim2.new(0, 6, 0, 14),
    Text             = "·",
    TextColor3       = C.Stroke,
    Font             = F.Mono,
    TextSize         = 10,
    LayoutOrder      = 2,
    Parent           = footRight,
})
local fpsFooter = create("TextLabel", {
    BackgroundTransparency = 1,
    Size             = UDim2.new(0, 52, 0, 14),
    Text             = "FPS 60",
    TextColor3       = C.AccentB,
    Font             = F.Mono,
    TextSize         = 8,
    LayoutOrder      = 3,
    Parent           = footRight,
})
create("TextLabel", {
    BackgroundTransparency = 1,
    Size             = UDim2.new(0, 6, 0, 14),
    Text             = "·",
    TextColor3       = C.Stroke,
    Font             = F.Mono,
    TextSize         = 10,
    LayoutOrder      = 4,
    Parent           = footRight,
})
create("TextLabel", {
    BackgroundTransparency = 1,
    Size             = UDim2.new(0, 34, 0, 14),
    Text             = "toggle",
    TextColor3       = C.Muted,
    Font             = F.Reg,
    TextSize         = 8,
    LayoutOrder      = 5,
    Parent           = footRight,
})
local kbdChip = create("Frame", {
    Size             = UDim2.fromOffset(46, 16),
    BackgroundColor3 = C.Surface,
    LayoutOrder      = 6,
    Parent           = footRight,
})
addCorner(kbdChip, 4)
addStroke(kbdChip, C.Stroke, 1, 0.1)
create("TextLabel", {
    BackgroundTransparency = 1,
    Size                  = UDim2.fromScale(1, 1),
    Text                  = "INSERT",
    TextColor3            = C.Text,
    Font                  = F.Mono,
    TextSize              = 8,
    Parent                = kbdChip,
})

------------------------------------------------------------------------
-- 14 · VENTANA: minimizar (pill flotante) / restaurar / cerrar
------------------------------------------------------------------------
local pill = create("CanvasGroup", {
    Name             = "Pill",
    AnchorPoint      = Vector2.new(1, 1),
    Position         = UDim2.new(1, -18, 1, -18),
    Size             = UDim2.fromOffset(158, 44),
    GroupTransparency = 1,
    BackgroundTransparency = 1,
    Visible          = false,
    Parent           = ScreenGui,
})
local pillBody = create("TextButton", {
    BackgroundColor3 = C.Surface,
    Text             = "",
    AutoButtonColor  = false,
    Size             = UDim2.fromScale(1, 1),
    Parent           = pill,
})
addCorner(pillBody, 22)
addStroke(pillBody, C.AccentA, 1, 0.45)

local pillMark = create("Frame", {
    Position         = UDim2.new(0, 13, 0.5, 0),
    AnchorPoint      = Vector2.new(0, 0.5),
    Size             = UDim2.fromOffset(16, 16),
    Rotation         = 45,
    BackgroundColor3 = Color3.new(1, 1, 1),
    Parent           = pillBody,
})
addCorner(pillMark, 4.5)
addGradient(pillMark, C.AccentB, C.Deep, 45)

create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 40, 0.5, -8),
    AnchorPoint      = Vector2.new(0, 0),
    Size             = UDim2.fromOffset(70, 13),
    Text             = "CINDER",
    TextColor3       = C.Text,
    Font             = F.Black,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = pillBody,
})
create("TextLabel", {
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 40, 0.5, 5),
    Size             = UDim2.fromOffset(80, 9),
    Text             = "C L I C K   T O   O P E N",
    TextColor3       = C.Muted,
    Font             = F.Mono,
    TextSize         = 7,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = pillBody,
})

pillBody.MouseEnter:Connect(function()
    tween(pillBody, 0.18, T_QUART_OUT, OUT, { BackgroundColor3 = C.SurfaceAlt })
end)
pillBody.MouseLeave:Connect(function()
    tween(pillBody, 0.25, T_QUART_OUT, OUT, { BackgroundColor3 = C.Surface })
end)

local minimized = false

local function minimizeMenu()
    if minimized then return end
    minimized = true
    tween(Root, 0.26, T_QUINT_OUT, IN, { GroupTransparency = 1 })
    tween(MainScale, 0.26, T_QUINT_OUT, IN, { Scale = 0.82 })
    task.delay(0.27, function()
        Root.Visible = false
        pill.Visible = true
        pill.GroupTransparency = 1
        tween(pill, 0.38, Enum.EasingStyle.Back, OUT, { GroupTransparency = 0 })
    end)
end

local function restoreMenu()
    if not minimized then return end
    minimized = false
    tween(pill, 0.2, T_QUART_OUT, IN, { GroupTransparency = 1 })
    task.delay(0.2, function()
        pill.Visible = false
    end)
    Root.Visible = true
    tween(Root, 0.4, T_QUINT_OUT, OUT, { GroupTransparency = 0 })
    tween(MainScale, 0.5, Enum.EasingStyle.Back, OUT, { Scale = 1 })
end

closeMenu = function()
    closed = true
    tween(pill, 0.2, T_QUART_OUT, IN, { GroupTransparency = 1 })
    tween(Root, 0.32, T_QUINT_OUT, IN, { GroupTransparency = 1 })
    tween(MainScale, 0.32, T_QUINT_OUT, IN, { Scale = 0.85 })
    task.delay(0.35, function()
        ScreenGui:Destroy()
    end)
end

pillBody.MouseButton1Click:Connect(restoreMenu)
minimizeBtn.MouseButton1Click:Connect(minimizeMenu)
closeBtn.MouseButton1Click:Connect(closeMenu)

UserInputService.InputBegan:Connect(function(input, gpe)
    if closed or gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if minimized then restoreMenu() else minimizeMenu() end
    end
end)

------------------------------------------------------------------------
-- 15 · DRAG (barra superior)
------------------------------------------------------------------------
local dragActive  = false
local dragStart   = nil
local startOffset = nil

UserInputService.InputBegan:Connect(function(input, gpe)
    if closed or gpe then return end
    local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if not (isMouse or isTouch) then return end

    local a, s = TopBar.AbsolutePosition, TopBar.AbsoluteSize
    local p = input.Position
    local withinY = p.Y >= a.Y and p.Y <= a.Y + s.Y
    local withinX = p.X >= a.X and p.X <= a.X + s.X - 96 -- excluye controles
    if withinX and withinY then
        dragActive  = true
        dragStart   = p
        startOffset = Vector2.new(Main.Position.X.Offset, Main.Position.Y.Offset)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if closed or not dragActive then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(0.5, startOffset.X + delta.X, 0.5, startOffset.Y + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragActive = false
    end
end)

------------------------------------------------------------------------
-- 16 · RELOJ / FPS EN VIVO (cosmético)
------------------------------------------------------------------------
local startTime = os.clock()
local fpsSmoothed = 60
local frameCount, accum = 0, 0
local labelTick = 0

local renderConn
renderConn = RunService.RenderStepped:Connect(function(dt)
    if closed then
        renderConn:Disconnect()
        return
    end
    frameCount += 1
    accum      += dt
    labelTick  += dt

    if accum >= 0.5 then
        fpsSmoothed = frameCount / accum
        frameCount, accum = 0, 0
        fpsFooter.Text = "FPS " .. math.floor(fpsSmoothed + 0.5)
        if liveFpsLabel then
            liveFpsLabel.Text = tostring(math.floor(fpsSmoothed + 0.5))
        end
    end

    if labelTick >= 1 then
        labelTick = 0
        local e = os.clock() - startTime
        local h = math.floor(e / 3600)
        local m = math.floor((e % 3600) / 60)
        local s = math.floor(e % 60)
        uptimeFooter.Text = string.format("UP %02d:%02d:%02d", h, m, s)
        if liveUptimeLabel then
            liveUptimeLabel.Text = string.format("%02d:%02d:%02d", h, m, s)
        end
    end
end)

------------------------------------------------------------------------
-- 17 · ESTADO INICIAL + ANIMACIÓN DE APERTURA
------------------------------------------------------------------------
switchTo(1, false)
Root.GroupTransparency = 1
MainScale.Scale        = 0.92

task.defer(function()
    tween(Root, 0.6, T_QUINT_OUT, OUT, { GroupTransparency = 0 })
    tween(MainScale, 0.72, Enum.EasingStyle.Back, OUT, { Scale = 1 })
end)

print("[CINDER] Ember Client cargado — GUI únicamente (sin lógica de juego).")

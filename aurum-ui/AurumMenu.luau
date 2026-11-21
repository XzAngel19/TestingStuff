--[[
	=====================================================================
	A U R U M  ·  Interface Suite  —  build 1.0.4
	=====================================================================
	Diseño visual de un menú estilo "exploit". SOLO GUI: no hay lógica
	de gameplay, ningún hook, ninguna llamada a remotes.

	· Identidad: obsidiana fría + oro solar + brasa + menta (nada de
	  morado neón genérico). Sans geométrica para la UI y monoespaciada
	  para los datos, para un aire de instrumento de precisión.
	· Cero assets externos: ni imágenes, ni íconos, ni fuentes por ID.
	  Todos los glifos están dibujados con Frames + UIStroke + UICorner.
	· Padre: gethui() (fallback automático a CoreGui / PlayerGui).
	· RightShift muestra / oculta el menú.

	Estructura del archivo:
		1. Servicios y utilidades
		2. Paleta, tipografía y tokens
		3. Fábrica de instancias y helpers (corner/stroke/gradient/tween)
		4. Contenedor (gethui) y sombras
		5. Shell: topbar, sidebar, contenido, footer
		6. Sistema de tabs + indicador deslizante
		7. Componentes (toggle, slider, dropdown, keybind, textbox...)
		8. Páginas de ejemplo
		9. Animaciones de apertura / cierre / minimizar / drag
	=====================================================================
]]

--=====================================================================
-- 1. SERVICIOS
--=====================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--=====================================================================
-- 2. PALETA + TIPOGRAFÍA
--=====================================================================
local C = {
	void   = Color3.fromRGB(10, 11, 16),   -- fondo absoluto
	shell  = Color3.fromRGB(16, 18, 25),   -- cuerpo del menú
	panel  = Color3.fromRGB(21, 24, 33),   -- tarjetas
	raised = Color3.fromRGB(30, 34, 46),   -- controles
	hover  = Color3.fromRGB(41, 47, 62),   -- hover
	line   = Color3.fromRGB(48, 54, 70),   -- bordes
	text   = Color3.fromRGB(236, 239, 247),
	muted  = Color3.fromRGB(135, 143, 166),
	dim    = Color3.fromRGB(92, 99, 122),
	gold   = Color3.fromRGB(242, 184, 64), -- acento primario
	ember  = Color3.fromRGB(255, 122, 77), -- acento secundario
	mint   = Color3.fromRGB(95, 227, 182), -- éxito / estado
	ruby   = Color3.fromRGB(255, 92, 116), -- destructivo
}

-- Fuente segura: si el Enum no existe en el cliente, cae a un fallback.
local function pickFont(name, fallback)
	local ok, value = pcall(function()
		return Enum.Font[name]
	end)
	if ok and value then
		return value
	end
	return Enum.Font[fallback] or Enum.Font.SourceSans
end

local FONT = {
	display = pickFont("GothamBlack", "SourceSansBold"),
	bold    = pickFont("GothamBold", "SourceSansBold"),
	medium  = pickFont("GothamMedium", "Gotham"),
	mono    = pickFont("RobotoMono", "Code"),
}

-- Geometría del shell
local WIDTH = 780
local HEIGHT = 500
local TOPBAR_H = 48
local FOOTER_H = 28
local SIDEBAR_W = 176
local BODY_H = HEIGHT - TOPBAR_H - FOOTER_H
local CONTENT_W = WIDTH - SIDEBAR_W

local TAB_TOP = 96        -- y de la primera tab
local TAB_STEP = 38       -- alto 34 + gap 4

--=====================================================================
-- 3. HELPERS
--=====================================================================
local function mk(class, parent, props)
	local object = Instance.new(class)
	if props then
		for key, value in pairs(props) do
			object[key] = value
		end
	end
	if parent then
		object.Parent = parent
	end
	return object
end

local function round(object, radius)
	return mk("UICorner", object, { CornerRadius = UDim.new(0, radius) })
end

local function stroke(object, color, thickness, transparency)
	return mk("UIStroke", object, {
		Color = color or C.line,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

local function gradient(object, from, to, rotation, transparencySequence)
	local g = mk("UIGradient", object, { Rotation = rotation or 0 })
	g.Color = ColorSequence.new(from, to)
	if transparencySequence then
		g.Transparency = transparencySequence
	end
	return g
end

local function tw(object, duration, props, style, direction)
	local info = TweenInfo.new(
		duration or 0.22,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)
	local anim = TweenService:Create(object, info, props)
	anim:Play()
	return anim
end

local function label(parent, props)
	local base = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		RichText = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
	for key, value in pairs(props or {}) do
		base[key] = value
	end
	return mk("TextLabel", parent, base)
end

local function hairline(parent, width, y, color, alpha, height)
	local line = mk("Frame", parent, {
		Size = width or UDim2.new(1, 0, 0, height or 1),
		Position = UDim2.new(0, 0, 0, y or 0),
		BackgroundColor3 = color or C.line,
		BackgroundTransparency = alpha or 0.4,
		BorderSizePixel = 0,
	})
	return line
end

-- Conecta hover + click de forma uniforme (con soporte touch).
local function interact(object, handlers)
	object.Active = true
	if handlers.hover then
		object.MouseEnter:Connect(function()
			handlers.hover(true)
		end)
		object.MouseLeave:Connect(function()
			handlers.hover(false)
		end)
	end
	if handlers.click then
		object.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				handlers.click(input)
			end
		end)
	end
end

--=====================================================================
-- 4. CONTENEDOR  (gethui con fallbacks)
--=====================================================================
local function makeScreenGui()
	local candidates = {}

	local okHui, hui = pcall(function()
		return gethui()
	end)
	if okHui and typeof(hui) == "Instance" then
		table.insert(candidates, hui)
	end

	local okCore, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and core then
		table.insert(candidates, core)
	end

	if LocalPlayer then
		local okPg, pg = pcall(function()
			return LocalPlayer:WaitForChild("PlayerGui", 5)
		end)
		if okPg and pg then
			table.insert(candidates, pg)
		end
	end

	for _, parent in ipairs(candidates) do
		-- Limpia una instancia previa sin confiar en permisos del contenedor.
		pcall(function()
			local existing = parent:FindFirstChild("AurumUI")
			if existing then
				existing:Destroy()
			end
		end)

		local screen = Instance.new("ScreenGui")
		screen.Name = "AurumUI"
		screen.ResetOnSpawn = false
		screen.IgnoreGuiInset = true
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screen.DisplayOrder = 128

		local okParent = pcall(function()
			screen.Parent = parent
		end)
		if okParent then
			return screen
		end
		screen:Destroy()
	end

	return nil
end

local gui = makeScreenGui()
if not gui then
	warn("[AURUM] No se pudo crear el ScreenGui (gethui/CoreGui/PlayerGui no disponibles).")
	return
end

-- Backdrop: agrupa las sombras del shell y permite desvanecerlas juntas.
local backdrop = mk("CanvasGroup", gui, {
	Name = "Backdrop",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	GroupTransparency = 1,
	ZIndex = 1,
})

local root = mk("CanvasGroup", gui, {
	Name = "Shell",
	Size = UDim2.new(0, WIDTH, 0, HEIGHT),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = C.shell,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	GroupTransparency = 1,
	ZIndex = 2,
})
round(root, 14)

-- Borde del shell: degradado oro→brasa recortado por transparencia.
do
	local shellStroke = stroke(root, C.gold, 1, 0)
	gradient(shellStroke, C.gold, C.ember, 45, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.45, 0.85),
		NumberSequenceKeypoint.new(0.75, 0.95),
		NumberSequenceKeypoint.new(1, 0.45),
	}))
	-- Brillo interior superior (efecto vidrio).
	local inner = mk("Frame", root, {
		Size = UDim2.new(1, -2, 0, 1),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundColor3 = C.text,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 9,
	})
	gradient(inner, C.text, C.text, 0, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0.55),
	}))
end

-- Dos glows de color que sangran desde las esquinas del shell.
do
	local warm = mk("Frame", root, {
		Size = UDim2.fromOffset(420, 420),
		Position = UDim2.fromOffset(-170, -200),
		BackgroundColor3 = C.gold,
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		ZIndex = 1,
	})
	round(warm, 210)

	local cool = mk("Frame", root, {
		Size = UDim2.fromOffset(360, 360),
		Position = UDim2.new(1, -220, 1, -230),
		BackgroundColor3 = C.ember,
		BackgroundTransparency = 0.96,
		BorderSizePixel = 0,
		ZIndex = 1,
	})
	round(cool, 180)
end

-- Sombras (siblings del shell, centradas igual que él).
local shadows = {}
local function addShadow(extra, color, transparency)
	local frame = mk("Frame", backdrop, {
		Size = UDim2.new(0, WIDTH + extra * 2, 0, HEIGHT + extra * 2),
		Position = root.Position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		ZIndex = 1,
	})
	round(frame, 14 + extra)
	table.insert(shadows, { Frame = frame, Extra = extra })
	return frame
end

addShadow(4, C.gold, 0.93)   -- halo cálido muy tenue
addShadow(10, Color3.fromRGB(0, 0, 0), 0.82)
addShadow(26, Color3.fromRGB(0, 0, 0), 0.92)
addShadow(52, Color3.fromRGB(0, 0, 0), 0.96)

-- Mantiene sombras pegadas al shell (drag, minimize, apertura).
RunService.Heartbeat:Connect(function()
	if not gui.Parent then
		return
	end
	for _, entry in ipairs(shadows) do
		local size = root.Size
		entry.Frame.Position = root.Position
		entry.Frame.Size = UDim2.new(
			size.X.Scale,
			size.X.Offset + entry.Extra * 2,
			size.Y.Scale,
			size.Y.Offset + entry.Extra * 2
		)
	end
end)

local scale = mk("UIScale", root, { Scale = 1 })

--=====================================================================
-- 5. SHELL
--=====================================================================

-- ---------- TOPBAR ----------
local topbar = mk("Frame", root, {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, TOPBAR_H),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 5,
})

do
	local under = mk("Frame", root, {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, TOPBAR_H),
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	gradient(under, C.line, C.line, 0, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.45),
		NumberSequenceKeypoint.new(0.7, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	}))
end

-- Logotipo: dos rombos concéntricos + giro lento ambiental.
local logo = mk("Frame", topbar, {
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.fromOffset(20, 12),
	BackgroundTransparency = 1,
	ZIndex = 6,
})
local logoOuter = mk("Frame", logo, {
	Size = UDim2.fromOffset(17, 17),
	Position = UDim2.fromOffset(3.5, 3.5),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Rotation = 45,
	ZIndex = 6,
})
round(logoOuter, 3)
do
	local logoStroke = stroke(logoOuter, C.gold, 1.4, 0.05)
	gradient(logoStroke, C.gold, C.ember, 45)
end
local logoInner = mk("Frame", logo, {
	Size = UDim2.fromOffset(7, 7),
	Position = UDim2.fromOffset(8.5, 8.5),
	BackgroundColor3 = C.gold,
	BorderSizePixel = 0,
	Rotation = 45,
	ZIndex = 7,
})
round(logoInner, 1.5)
gradient(logoInner, C.gold, C.ember, 45)
TweenService:Create(
	logoOuter,
	TweenInfo.new(16, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
	{ Rotation = 405 }
):Play()

label(topbar, {
	Position = UDim2.fromOffset(54, 0),
	Size = UDim2.fromOffset(96, TOPBAR_H),
	Text = "AURUM",
	Font = FONT.display,
	TextSize = 15,
	TextColor3 = C.text,
	ZIndex = 6,
})

-- Chip de versión
local versionChip = mk("Frame", topbar, {
	Size = UDim2.fromOffset(48, 17),
	Position = UDim2.fromOffset(126, 15),
	BackgroundColor3 = C.raised,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	ZIndex = 6,
})
round(versionChip, 5)
stroke(versionChip, C.line, 1, 0.5)
label(versionChip, {
	Size = UDim2.fromScale(1, 1),
	Text = "v1.0.4",
	Font = FONT.mono,
	TextSize = 8.5,
	TextColor3 = C.muted,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 7,
})

-- Separador + subtítulo
mk("Frame", topbar, {
	Size = UDim2.fromOffset(1, 16),
	Position = UDim2.fromOffset(188, 16),
	BackgroundColor3 = C.line,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ZIndex = 6,
})
label(topbar, {
	Position = UDim2.fromOffset(200, 0),
	Size = UDim2.new(0, 200, 0, TOPBAR_H),
	Text = "Interface Suite",
	Font = FONT.medium,
	TextSize = 10.5,
	TextColor3 = C.dim,
	ZIndex = 6,
})

-- Botones de ventana (minimizar / cerrar) dibujados con barras.
local miniBarV, miniBarH

local function windowButton(kind, xOffset)
	local button = mk("Frame", topbar, {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, xOffset, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = C.raised,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 7,
	})
	round(button, 8)
	local hoverFill = mk("Frame", button, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
	})
	round(hoverFill, 8)

	local accent = (kind == "close") and C.ruby or C.gold

	if kind == "close" then
		local barA = mk("Frame", button, {
			Size = UDim2.fromOffset(9, 1.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = C.muted,
			BorderSizePixel = 0,
			Rotation = 45,
			ZIndex = 8,
		})
		round(barA, 1)
		local barB = mk("Frame", button, {
			Size = UDim2.fromOffset(9, 1.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = C.muted,
			BorderSizePixel = 0,
			Rotation = -45,
			ZIndex = 8,
		})
		round(barB, 1)

		interact(button, {
			hover = function(isOver)
				tw(hoverFill, 0.16, { BackgroundTransparency = isOver and 0.55 or 1 })
				tw(barA, 0.16, { BackgroundColor3 = isOver and accent or C.muted })
				tw(barB, 0.16, { BackgroundColor3 = isOver and accent or C.muted })
			end,
		})
		return button, { barA, barB }
	end

	miniBarH = mk("Frame", button, {
		Size = UDim2.fromOffset(10, 1.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.muted,
		BorderSizePixel = 0,
		ZIndex = 8,
	})
	round(miniBarH, 1)

	miniBarV = mk("Frame", button, {
		Size = UDim2.fromOffset(1.5, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.muted,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 8,
	})
	round(miniBarV, 1)

	interact(button, {
		hover = function(isOver)
			tw(hoverFill, 0.16, { BackgroundTransparency = isOver and 0.55 or 1 })
			tw(miniBarH, 0.16, { BackgroundColor3 = isOver and accent or C.muted })
			tw(miniBarV, 0.16, { BackgroundColor3 = isOver and accent or C.muted })
		end,
	})
	return button, { miniBarH, miniBarV }
end

local closeButton = windowButton("close", -14)
local minimizeButton = windowButton("minimize", -46)

-- ---------- SIDEBAR ----------
local sidebar = mk("Frame", root, {
	Name = "Sidebar",
	Size = UDim2.new(0, SIDEBAR_W, 0, BODY_H),
	Position = UDim2.fromOffset(0, TOPBAR_H),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ZIndex = 4,
})
gradient(sidebar, C.panel, C.void, 90)

-- Divisor vertical con degradado
do
	local divider = mk("Frame", root, {
		Size = UDim2.new(0, 1, 0, BODY_H),
		Position = UDim2.fromOffset(SIDEBAR_W, TOPBAR_H),
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	gradient(divider, C.line, C.line, 90, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.4),
		NumberSequenceKeypoint.new(0.8, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	}))
end

-- Tarjeta de perfil
local displayName = "Operator"
if LocalPlayer then
	local okName = pcall(function()
		displayName = LocalPlayer.DisplayName or LocalPlayer.Name or "Operator"
	end)
	if not okName then
		displayName = "Operator"
	end
end
if #displayName > 13 then
	displayName = string.sub(displayName, 1, 12) .. "…"
end

local profile = mk("Frame", sidebar, {
	Size = UDim2.new(1, -24, 0, 54),
	Position = UDim2.fromOffset(12, 12),
	BackgroundColor3 = C.raised,
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
	ZIndex = 5,
})
round(profile, 10)
local profileStroke = stroke(profile, C.line, 1, 0.45)
gradient(profile, C.raised, C.panel, 90)

local avatar = mk("Frame", profile, {
	Size = UDim2.fromOffset(34, 34),
	Position = UDim2.fromOffset(10, 10),
	BackgroundColor3 = C.gold,
	BorderSizePixel = 0,
	ZIndex = 6,
})
round(avatar, 9)
gradient(avatar, C.gold, C.ember, 135)
label(avatar, {
	Size = UDim2.fromScale(1, 1),
	Text = "A",
	Font = FONT.display,
	TextSize = 15,
	TextColor3 = C.void,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 7,
})

label(profile, {
	Position = UDim2.fromOffset(54, 11),
	Size = UDim2.new(1, -64, 0, 15),
	Text = displayName,
	Font = FONT.bold,
	TextSize = 11.5,
	TextColor3 = C.text,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 7,
})

label(profile, {
	Position = UDim2.fromOffset(54, 27),
	Size = UDim2.new(1, -64, 0, 13),
	Text = "premium · tier III",
	Font = FONT.mono,
	TextSize = 8.5,
	TextColor3 = C.muted,
	TextTransparency = 0.1,
	ZIndex = 7,
})

local statusDot = mk("Frame", profile, {
	Size = UDim2.fromOffset(5, 5),
	Position = UDim2.fromOffset(54, 44),
	BackgroundColor3 = C.mint,
	BorderSizePixel = 0,
	ZIndex = 7,
})
round(statusDot, 3)
label(profile, {
	Position = UDim2.fromOffset(64, 38),
	Size = UDim2.fromOffset(80, 12),
	Text = "online",
	Font = FONT.medium,
	TextSize = 8.5,
	TextColor3 = C.mint,
	TextTransparency = 0.15,
	ZIndex = 7,
})

-- Etiqueta de sección "NAVIGATION"
label(sidebar, {
	Position = UDim2.fromOffset(16, 74),
	Size = UDim2.new(1, -32, 0, 14),
	Text = "NAVIGATION",
	Font = FONT.bold,
	TextSize = 8.5,
	TextColor3 = C.dim,
	ZIndex = 5,
})

-- Indicador deslizante de tab activo
local indicator = mk("Frame", sidebar, {
	Size = UDim2.new(0, 3, 0, 18),
	Position = UDim2.new(0, 6, 0, TAB_TOP + 8),
	BackgroundColor3 = C.gold,
	BorderSizePixel = 0,
	ZIndex = 9,
})
round(indicator, 2)
gradient(indicator, C.gold, C.ember, 90)
local indicatorGlow = mk("Frame", indicator, {
	Size = UDim2.new(0, 9, 0, 30),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = C.gold,
	BackgroundTransparency = 0.86,
	BorderSizePixel = 0,
	ZIndex = 8,
})
round(indicatorGlow, 4)

-- Tarjeta inferior de keybind
local hintCard = mk("Frame", sidebar, {
	Size = UDim2.new(1, -24, 0, 56),
	Position = UDim2.new(0, 12, 1, -68),
	BackgroundColor3 = C.raised,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	ZIndex = 5,
})
round(hintCard, 10)
stroke(hintCard, C.line, 1, 0.55)

label(hintCard, {
	Position = UDim2.fromOffset(10, 9),
	Size = UDim2.new(1, -20, 0, 12),
	Text = "TOGGLE MENU",
	Font = FONT.mono,
	TextSize = 8,
	TextColor3 = C.dim,
	ZIndex = 6,
})
local hintChip = mk("Frame", hintCard, {
	Size = UDim2.fromOffset(64, 20),
	Position = UDim2.fromOffset(10, 25),
	BackgroundColor3 = C.void,
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	ZIndex = 6,
})
round(hintChip, 5)
stroke(hintChip, C.gold, 1, 0.7)
label(hintChip, {
	Size = UDim2.fromScale(1, 1),
	Text = "RSHIFT",
	Font = FONT.mono,
	TextSize = 8,
	TextColor3 = C.gold,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 7,
})
label(hintCard, {
	Size = UDim2.new(1, -10, 0, 14),
	Position = UDim2.fromOffset(0, 28),
	Text = "build 1.0.4",
	Font = FONT.mono,
	TextSize = 7.5,
	TextColor3 = C.dim,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 6,
})

-- ---------- CONTENIDO ----------
local content = mk("Frame", root, {
	Name = "Content",
	Size = UDim2.new(0, CONTENT_W, 0, BODY_H),
	Position = UDim2.fromOffset(SIDEBAR_W, TOPBAR_H),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 4,
})

local contentTitle = label(content, {
	Position = UDim2.fromOffset(20, 16),
	Size = UDim2.new(0, 360, 0, 24),
	Text = "AIMBOT",
	Font = FONT.display,
	TextSize = 18,
	TextColor3 = C.text,
	ZIndex = 5,
})

local contentSub = label(content, {
	Position = UDim2.fromOffset(21, 41),
	Size = UDim2.new(0, 360, 0, 14),
	Text = "",
	Font = FONT.medium,
	TextSize = 9.5,
	TextColor3 = C.muted,
	ZIndex = 5,
})

local syncedPill = mk("Frame", content, {
	Size = UDim2.fromOffset(78, 22),
	Position = UDim2.new(1, -20, 0, 18),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = C.raised,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	ZIndex = 5,
})
round(syncedPill, 11)
stroke(syncedPill, C.mint, 1, 0.72)
local pillDot = mk("Frame", syncedPill, {
	Size = UDim2.fromOffset(5, 5),
	Position = UDim2.fromOffset(11, 8.5),
	BackgroundColor3 = C.mint,
	BorderSizePixel = 0,
	ZIndex = 6,
})
round(pillDot, 3)
label(syncedPill, {
	Position = UDim2.fromOffset(22, 0),
	Size = UDim2.new(1, -26, 1, 0),
	Text = "SYNCED",
	Font = FONT.mono,
	TextSize = 8,
	TextColor3 = C.mint,
	ZIndex = 6,
})
TweenService:Create(
	pillDot,
	TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ BackgroundTransparency = 0.55 }
):Play()

-- Subrayado degradado bajo el encabezado
do
	local underline = mk("Frame", content, {
		Size = UDim2.new(1, -40, 0, 1),
		Position = UDim2.fromOffset(20, 68),
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		ZIndex = 5,
	})
	gradient(underline, C.gold, C.ember, 0, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.35, 0.85),
		NumberSequenceKeypoint.new(0.75, 0.95),
		NumberSequenceKeypoint.new(1, 1),
	}))
end

local pagesHolder = mk("Frame", content, {
	Size = UDim2.new(1, -40, 0, BODY_H - 82 - 14),
	Position = UDim2.fromOffset(20, 82),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 5,
})

-- ---------- FOOTER ----------
local footer = mk("Frame", root, {
	Name = "StatusBar",
	Size = UDim2.new(1, 0, 0, FOOTER_H),
	Position = UDim2.new(0, 0, 1, -FOOTER_H),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.55,
	BorderSizePixel = 0,
	ZIndex = 6,
})
do
	local top = mk("Frame", footer, {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.line,
		BorderSizePixel = 0,
		ZIndex = 7,
	})
	gradient(top, C.line, C.line, 0, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.5, 0.95),
		NumberSequenceKeypoint.new(1, 0.55),
	}))
end

local footerDot = mk("Frame", footer, {
	Size = UDim2.fromOffset(5, 5),
	Position = UDim2.fromOffset(16, 11.5),
	BackgroundColor3 = C.mint,
	BorderSizePixel = 0,
	ZIndex = 7,
})
round(footerDot, 3)
TweenService:Create(
	footerDot,
	TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ BackgroundTransparency = 0.6 }
):Play()

label(footer, {
	Position = UDim2.fromOffset(26, 0),
	Size = UDim2.fromOffset(80, FOOTER_H),
	Text = "CONNECTED",
	Font = FONT.mono,
	TextSize = 8,
	TextColor3 = C.mint,
	TextTransparency = 0.1,
	ZIndex = 7,
})

mk("Frame", footer, {
	Size = UDim2.fromOffset(1, 12),
	Position = UDim2.fromOffset(108, 8),
	BackgroundColor3 = C.line,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	ZIndex = 7,
})

label(footer, {
	Position = UDim2.fromOffset(120, 0),
	Size = UDim2.fromOffset(180, FOOTER_H),
	Text = "gethui() · luau · single file",
	Font = FONT.mono,
	TextSize = 8,
	TextColor3 = C.dim,
	ZIndex = 7,
})

label(footer, {
	Position = UDim2.new(0.5, 0, 0, 0),
	Size = UDim2.fromOffset(180, FOOTER_H),
	AnchorPoint = Vector2.new(0.5, 0),
	Text = "RSHIFT · TOGGLE",
	Font = FONT.mono,
	TextSize = 8,
	TextColor3 = C.dim,
	TextTransparency = 0.15,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 7,
})

-- Ecualizador animado + latencia
local barsHolder = mk("Frame", footer, {
	Size = UDim2.fromOffset(36, 12),
	Position = UDim2.new(1, -84, 0.5, 0),
	AnchorPoint = Vector2.new(1, 0.5),
	BackgroundTransparency = 1,
	ZIndex = 7,
})
for i = 1, 6 do
	local bar = mk("Frame", barsHolder, {
		Size = UDim2.new(0, 3, 0, 3 + ((i * 2) % 7)),
		Position = UDim2.new(0, (i - 1) * 6, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = C.gold,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 8,
	})
	round(bar, 1)
	TweenService:Create(bar, TweenInfo.new(
		0.42 + (i * 0.07),
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		true,
		i * 0.05
	), { Size = UDim2.new(0, 3, 0, 6 + ((i * 3) % 8)) }):Play()
end
label(footer, {
	Position = UDim2.new(1, -74, 0, 0),
	Size = UDim2.fromOffset(60, FOOTER_H),
	Text = "1.4 ms",
	Font = FONT.mono,
	TextSize = 8,
	TextColor3 = C.muted,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 7,
})

--=====================================================================
-- 6. TABS
--=====================================================================

-- Glifos 100% dibujados con frames (sin imágenes).
local function buildGlyph(kind, parent)
	local holder = mk("Frame", parent, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(12, 10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 7,
	})
	local parts = {}

	local function fill(x, y, w, h, rotation, radius)
		local f = mk("Frame", holder, {
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(x, y),
			BackgroundColor3 = C.muted,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Rotation = rotation or 0,
			ZIndex = 8,
		})
		round(f, radius or 1)
		table.insert(parts, { Object = f, Kind = "fill" })
		return f
	end

	local function outline(x, y, w, h, radius, rotation, thickness)
		local f = mk("Frame", holder, {
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(x, y),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Rotation = rotation or 0,
			ZIndex = 8,
		})
		round(f, radius or 2)
		local s = stroke(f, C.muted, thickness or 1.4, 0.55)
		table.insert(parts, { Object = s, Kind = "stroke" })
		return f
	end

	if kind == "crosshair" then
		outline(1, 1, 12, 12, 6, 0, 1.4)
		fill(6, 6, 2, 2, 0, 1)
	elseif kind == "layers" then
		outline(2, 2, 10, 10, 2, 45, 1.2)
		fill(5.5, 5.5, 3, 3, 45, 1)
	elseif kind == "person" then
		outline(4, 1, 6, 6, 3, 0, 1.3)
		fill(1, 9, 12, 4.5, 0, 2.2)
	elseif kind == "bars" then
		fill(1, 6, 2, 8, 0, 1)
		fill(6, 2, 2, 12, 0, 1)
		fill(11, 8, 2, 6, 0, 1)
	else
		-- "sliders"
		fill(0, 2.5, 14, 1.4, 0, 1)
		fill(3, 0.5, 3.5, 4, 0, 1.6)
		fill(0, 9.5, 14, 1.4, 0, 1)
		fill(8, 7.5, 3.5, 4, 0, 1.6)
	end

	return parts
end

local function tintGlyph(parts, color, alpha)
	for _, part in ipairs(parts) do
		if part.Kind == "stroke" then
			tw(part.Object, 0.18, { Color = color, Transparency = alpha })
		else
			tw(part.Object, 0.18, { BackgroundColor3 = color, BackgroundTransparency = alpha })
		end
	end
end

local TAB_DATA = {
	{ Key = "aim", Title = "AIMBOT", Glyph = "crosshair" },
	{ Key = "visuals", Title = "VISUALS", Glyph = "layers" },
	{ Key = "player", Title = "PLAYER", Glyph = "person" },
	{ Key = "world", Title = "WORLD", Glyph = "bars" },
	{ Key = "config", Title = "CONFIG", Glyph = "sliders" },
}

local tabs = {}
local pages = {}
local pageList = {}
local currentKey = nil
local selectTab

for index, data in ipairs(TAB_DATA) do
	local y = TAB_TOP + (index - 1) * TAB_STEP

	local tab = mk("Frame", sidebar, {
		Size = UDim2.new(1, -24, 0, 34),
		Position = UDim2.fromOffset(12, y),
		BackgroundColor3 = C.raised,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	round(tab, 8)
	gradient(tab, C.raised, C.panel, 90)
	local tabStroke = stroke(tab, C.gold, 1, 1)

	local text = label(tab, {
		Position = UDim2.fromOffset(34, 0),
		Size = UDim2.new(1, -42, 1, 0),
		Text = data.Title,
		Font = FONT.bold,
		TextSize = 10.5,
		TextColor3 = C.muted,
		ZIndex = 7,
	})

	local parts = buildGlyph(data.Glyph, tab)

	interact(tab, {
		hover = function(isOver)
			if currentKey == data.Key then
				return
			end
			tw(tab, 0.16, { BackgroundTransparency = isOver and 0.86 or 1 })
			tw(text, 0.16, { TextColor3 = isOver and C.text or C.muted })
			tintGlyph(parts, isOver and C.text or C.muted, isOver and 0.35 or 0.55)
		end,
		click = function()
			if selectTab then
				selectTab(data.Key)
			end
		end,
	})

	table.insert(tabs, {
		Frame = tab,
		Text = text,
		Stroke = tabStroke,
		Parts = parts,
		Data = data,
		Index = index,
	})
end

--=====================================================================
-- 7. PÁGINAS Y COMPONENTES
--=====================================================================

local function createPage(key, title, subtitle)
	local group = mk("CanvasGroup", pagesHolder, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 5,
	})

	local scroll = mk("ScrollingFrame", group, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.hover,
		ScrollBarImageTransparency = 0.25,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		ClipsDescendants = true,
		ZIndex = 5,
	})
	mk("UIPadding", scroll, {
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 6),
	})
	mk("UIListLayout", scroll, {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local page = {
		Key = key,
		Title = title,
		Subtitle = subtitle,
		Group = group,
		Scroll = scroll,
		Order = 0,
	}

	pages[key] = page
	table.insert(pageList, page)
	return page
end

-- Tarjeta de sección (crece sola con su contenido)
local function addCard(page, index, title, note)
	page.Order = page.Order + 1

	local card = mk("Frame", page.Scroll, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		LayoutOrder = page.Order,
		ClipsDescendants = false,
		ZIndex = 5,
	})
	round(card, 12)
	stroke(card, C.line, 1, 0.62)
	gradient(card, C.panel, C.void, 90)

	mk("UIPadding", card, {
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	})
	mk("UIListLayout", card, {
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	-- Encabezado de la tarjeta
	local head = mk("Frame", card, {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		ZIndex = 6,
	})

	label(head, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(22, 30),
		Text = string.format("%02d", index),
		Font = FONT.mono,
		TextSize = 8.5,
		TextColor3 = C.gold,
		TextTransparency = 0.15,
		ZIndex = 7,
	})

	label(head, {
		Position = UDim2.fromOffset(26, 0),
		Size = UDim2.new(1, -140, 0, 30),
		Text = title,
		Font = FONT.bold,
		TextSize = 9.5,
		TextColor3 = C.text,
		TextTransparency = 0.05,
		ZIndex = 7,
	})

	if note then
		label(head, {
			Position = UDim2.new(1, -120, 0, 0),
			Size = UDim2.fromOffset(120, 30),
			Text = note,
			Font = FONT.mono,
			TextSize = 8,
			TextColor3 = C.dim,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 7,
		})
	end

	local line = mk("Frame", head, {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = C.line,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	gradient(line, C.gold, C.line, 0, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.4, 0.8),
		NumberSequenceKeypoint.new(1, 0.95),
	}))

	return { Frame = card, Page = page, Count = 0 }
end

local function addRow(card, height)
	card.Count = card.Count + 1
	local ordinal = card.Count

	if ordinal > 1 then
		mk("Frame", card.Frame, {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = C.line,
			BackgroundTransparency = 0.78,
			BorderSizePixel = 0,
			LayoutOrder = ordinal * 10 - 5,
			ZIndex = 6,
		})
	end

	local row = mk("Frame", card.Frame, {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = ordinal * 10,
		ClipsDescendants = false,
	})
	return row
end

local function rowHighlight(row, radius)
	local hl = mk("Frame", row, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1,
	})
	round(hl, radius or 8)
	return hl
end

--------------------------------------------------------------- TOGGLE
local function addToggle(card, title, description, initial)
	local row = addRow(card, 42)
	local hl = rowHighlight(row, 8)

	local name = label(row, {
		Position = UDim2.fromOffset(8, 4),
		Size = UDim2.new(1, -76, 0, 16),
		Text = title,
		Font = FONT.medium,
		TextSize = 11,
		TextColor3 = C.text,
		ZIndex = 2,
	})

	local sub = label(row, {
		Position = UDim2.fromOffset(8, 21),
		Size = UDim2.new(1, -76, 0, 14),
		Text = description or "",
		Font = FONT.medium,
		TextSize = 9,
		TextColor3 = C.muted,
		TextTransparency = 0.15,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
	})

	local track = mk("Frame", row, {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -2, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = C.void,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(track, 10)
	local trackStroke = stroke(track, C.line, 1, 0.25)

	local fill = mk("Frame", track, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.gold,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	round(fill, 10)
	gradient(fill, C.gold, C.ember, 0)

	local knob = mk("Frame", track, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = C.text,
		BorderSizePixel = 0,
		ZIndex = 4,
	})
	round(knob, 7)

	local enabled = initial and true or false

	local function apply(value)
		enabled = value
		tw(fill, 0.22, { BackgroundTransparency = value and 0 or 1 })
		tw(trackStroke, 0.22, {
			Color = value and C.gold or C.line,
			Transparency = value and 0.35 or 0.25,
		})
		tw(knob, 0.26, {
			Position = UDim2.fromOffset(value and 21 or 3, 3),
			BackgroundColor3 = value and C.void or C.text,
		})
		tw(sub, 0.2, { TextTransparency = value and 0.1 or 0.15 })
	end

	apply(enabled)

	local function toggle()
		apply(not enabled)
	end

	interact(row, {
		hover = function(isOver)
			tw(hl, 0.16, { BackgroundTransparency = isOver and 0.9 or 1 })
		end,
		click = toggle,
	})
	interact(track, { click = toggle })

	return {
		Row = row,
		Set = apply,
		IsOn = function()
			return enabled
		end,
	}
end

--------------------------------------------------------------- SLIDER
local function addSlider(card, title, minValue, maxValue, initial, suffix, stepSize)
	local row = addRow(card, 50)

	local name = label(row, {
		Position = UDim2.fromOffset(8, 2),
		Size = UDim2.new(1, -96, 0, 18),
		Text = title,
		Font = FONT.medium,
		TextSize = 11,
		TextColor3 = C.text,
		ZIndex = 2,
	})

	local valuePill = mk("Frame", row, {
		Size = UDim2.fromOffset(52, 18),
		Position = UDim2.new(1, -2, 0, 2),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.raised,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(valuePill, 5)
	stroke(valuePill, C.line, 1, 0.45)

	local valueText = label(valuePill, {
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Font = FONT.mono,
		TextSize = 8.5,
		TextColor3 = C.gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	})

	local track = mk("Frame", row, {
		Size = UDim2.new(1, -4, 0, 5),
		Position = UDim2.fromOffset(2, 32),
		BackgroundColor3 = C.void,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(track, 3)
	stroke(track, C.line, 1, 0.4)

	local fill = mk("Frame", track, {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.gold,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	round(fill, 3)
	gradient(fill, C.gold, C.ember, 0)

	local glow = mk("Frame", track, {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.gold,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	round(glow, 10)

	local knob = mk("Frame", track, {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.text,
		BorderSizePixel = 0,
		ZIndex = 4,
	})
	round(knob, 6)
	local knobStroke = stroke(knob, C.gold, 1.4, 0.35)

	-- marcas de escala
	for i = 0, 4 do
		local tick = mk("Frame", row, {
			Size = UDim2.fromOffset(1, 3),
			Position = UDim2.new(i / 4, 2, 0, 41),
			BackgroundColor3 = C.line,
			BorderSizePixel = 0,
			ZIndex = 2,
		})
		if i == 0 then
			tick.Position = UDim2.fromOffset(2, 41)
		elseif i == 4 then
			tick.Position = UDim2.new(1, -3, 0, 41)
		end
	end

	local step = stepSize or 1
	local currentValue = math.clamp(initial, minValue, maxValue)

	local function formatValue(value)
		if step >= 1 then
			return tostring(math.floor(value + 0.5)) .. (suffix or "")
		end
		return string.format("%.1f", value) .. (suffix or "")
	end

	local function paint(alpha)
		alpha = math.clamp(alpha, 0, 1)

		local raw = minValue + (maxValue - minValue) * alpha
		local value = math.floor(raw / step + 0.5) * step
		value = math.clamp(value, minValue, maxValue)

		local snapped = (value - minValue) / math.max(maxValue - minValue, 0.0001)

		fill.Size = UDim2.new(snapped, 0, 1, 0)
		knob.Position = UDim2.new(snapped, 0, 0.5, 0)
		glow.Position = UDim2.new(snapped, 0, 0.5, 0)
		currentValue = value

		local text = formatValue(value)
		if valueText.Text ~= text then
			valueText.Text = text
		end
	end

	paint((currentValue - minValue) / math.max(maxValue - minValue, 0.0001))

	local dragging = false

	local function fromScreenX(screenX)
		local relative = (screenX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		paint(relative)
	end

	local function startDrag(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			tw(knob, 0.15, { Size = UDim2.fromOffset(14, 14) })
			tw(knobStroke, 0.15, { Transparency = 0.1 })
			tw(glow, 0.15, { BackgroundTransparency = 0.75 })
			fromScreenX(input.Position.X)
		end
	end

	for _, target in ipairs({ track, fill, knob, glow }) do
		target.InputBegan:Connect(startDrag)
	end

	interact(track, {
		hover = function(isOver)
			if dragging then
				return
			end
			tw(knobStroke, 0.16, { Transparency = isOver and 0.15 or 0.35 })
			tw(glow, 0.16, { BackgroundTransparency = isOver and 0.86 or 1 })
			tw(valuePill, 0.16, { BackgroundTransparency = isOver and 0.02 or 0.15 })
		end,
	})

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			fromScreenX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if dragging then
				dragging = false
				tw(knob, 0.15, { Size = UDim2.fromOffset(12, 12) })
				tw(knobStroke, 0.15, { Transparency = 0.35 })
				tw(glow, 0.15, { BackgroundTransparency = 1 })
			end
		end
	end)

	return {
		Row = row,
		Set = paint,
		Get = function()
			return currentValue
		end,
	}
end

------------------------------------------------------------- DROPDOWN
local function addDropdown(card, title, options, defaultIndex)
	local row = addRow(card, 40)

	local name = label(row, {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -200, 1, 0),
		Text = title,
		Font = FONT.medium,
		TextSize = 11,
		TextColor3 = C.text,
		ZIndex = 2,
	})

	local selector = mk("Frame", row, {
		Size = UDim2.fromOffset(178, 26),
		Position = UDim2.new(1, -2, 0, 7),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.raised,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(selector, 7)
	local selectorStroke = stroke(selector, C.line, 1, 0.35)

	local current = options[defaultIndex or 1] or "—"

	local selectorText = label(selector, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -34, 1, 0),
		Text = current,
		Font = FONT.medium,
		TextSize = 9.5,
		TextColor3 = C.text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
	})

	-- Chevron dibujado con dos barras dentro de un holder rotable.
	local chevron = mk("Frame", selector, {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	local chevA = mk("Frame", chevron, {
		Size = UDim2.fromOffset(5.5, 1.4),
		Position = UDim2.fromOffset(1, 6.6),
		BackgroundColor3 = C.muted,
		BorderSizePixel = 0,
		Rotation = 38,
		ZIndex = 4,
	})
	round(chevA, 1)
	local chevB = mk("Frame", chevron, {
		Size = UDim2.fromOffset(5.5, 1.4),
		Position = UDim2.fromOffset(5.5, 6.6),
		BackgroundColor3 = C.muted,
		BorderSizePixel = 0,
		Rotation = -38,
		ZIndex = 4,
	})
	round(chevB, 1)

	local list = mk("Frame", row, {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 4,
	})

	local listFill = mk("Frame", list, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.void,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1,
	})
	round(listFill, 8)
	local listStroke = stroke(listFill, C.line, 1, 1)

	local optionButtons = {}
	local open = false
	local expandedHeight = 40 + 8 + #options * 26

	local function setOpen(value)
		open = value
		tw(row, 0.24, { Size = UDim2.new(1, 0, 0, value and expandedHeight or 40) })
		tw(list, 0.24, {
			Size = UDim2.new(1, 0, 0, value and (expandedHeight - 40) or 0),
		})
		tw(listFill, 0.24, { BackgroundTransparency = value and 0.25 or 1 })
		tw(listStroke, 0.24, { Transparency = value and 0.35 or 1 })
		tw(chevron, 0.26, { Rotation = value and 180 or 0 })
		tw(selectorStroke, 0.2, {
			Color = value and C.gold or C.line,
			Transparency = value and 0.45 or 0.35,
		})
	end

	local function choose(index)
		current = options[index] or current
		selectorText.Text = current
		for i, button in ipairs(optionButtons) do
			tw(button.Label, 0.16, { TextColor3 = (i == index) and C.gold or C.muted })
			tw(button.Dot, 0.16, { BackgroundTransparency = (i == index) and 0 or 1 })
		end
		setOpen(false)
	end

	for i, optionText in ipairs(options) do
		local optionButton = mk("Frame", list, {
			Size = UDim2.new(1, -8, 0, 24),
			Position = UDim2.fromOffset(4, 4 + (i - 1) * 26),
			BackgroundColor3 = C.raised,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
		})
		round(optionButton, 6)

		local dot = mk("Frame", optionButton, {
			Size = UDim2.fromOffset(4, 4),
			Position = UDim2.fromOffset(8, 10),
			BackgroundColor3 = C.gold,
			BackgroundTransparency = (i == (defaultIndex or 1)) and 0 or 1,
			BorderSizePixel = 0,
			ZIndex = 3,
		})
		round(dot, 2)

		local optionLabel = label(optionButton, {
			Position = UDim2.fromOffset(18, 0),
			Size = UDim2.new(1, -26, 1, 0),
			Text = optionText,
			Font = FONT.medium,
			TextSize = 9.5,
			TextColor3 = (i == (defaultIndex or 1)) and C.gold or C.muted,
			ZIndex = 3,
		})

		interact(optionButton, {
			hover = function(isOver)
				tw(optionButton, 0.14, { BackgroundTransparency = isOver and 0.6 or 1 })
				tw(optionLabel, 0.14, { TextColor3 = isOver and C.text or ((i == (defaultIndex or 1)) and C.gold or C.muted) })
			end,
			click = function()
				defaultIndex = i
				choose(i)
			end,
		})

		table.insert(optionButtons, { Button = optionButton, Label = optionLabel, Dot = dot })
	end

	interact(selector, {
		hover = function(isOver)
			if open then
				return
			end
			tw(selector, 0.16, { BackgroundTransparency = isOver and 0.02 or 0.15 })
			tw(selectorStroke, 0.16, { Color = isOver and C.gold or C.line, Transparency = isOver and 0.6 or 0.35 })
			tw(chevA, 0.16, { BackgroundColor3 = isOver and C.gold or C.muted })
			tw(chevB, 0.16, { BackgroundColor3 = isOver and C.gold or C.muted })
		end,
		click = function()
			setOpen(not open)
		end,
	})

	setOpen(false)

	return {
		Row = row,
		Get = function()
			return current
		end,
	}
end

-------------------------------------------------------------- KEYBIND
local function addKeybind(card, title, key)
	local row = addRow(card, 40)
	local hl = rowHighlight(row, 8)

	local name = label(row, {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -110, 1, 0),
		Text = title,
		Font = FONT.medium,
		TextSize = 11,
		TextColor3 = C.text,
		ZIndex = 2,
	})

	local chip = mk("Frame", row, {
		Size = UDim2.fromOffset(78, 24),
		Position = UDim2.new(1, -2, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = C.raised,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(chip, 6)
	local chipStroke = stroke(chip, C.line, 1, 0.3)

	local dot = mk("Frame", chip, {
		Size = UDim2.fromOffset(4, 4),
		Position = UDim2.fromOffset(9, 10),
		BackgroundColor3 = C.gold,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	round(dot, 2)

	local keyText = label(chip, {
		Position = UDim2.fromOffset(19, 0),
		Size = UDim2.new(1, -26, 1, 0),
		Text = key,
		Font = FONT.mono,
		TextSize = 8.5,
		TextColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	})

	local listening = false

	local function listen()
		if listening then
			return
		end
		listening = true

		tw(chipStroke, 0.16, { Color = C.gold, Transparency = 0.1 })
		tw(chip, 0.16, { BackgroundTransparency = 0.02 })
		keyText.Text = "…"
		keyText.TextColor3 = C.gold

		-- Pulso de "escuchando" (solo visual)
		tw(dot, 0.32, { BackgroundTransparency = 0.85 }, Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut)

		task.delay(1.15, function()
			listening = false
			keyText.Text = key
			keyText.TextColor3 = C.muted
			tw(chip, 0.2, { BackgroundTransparency = 0.15 })
			tw(chipStroke, 0.2, { Color = C.line, Transparency = 0.3 })
			tw(dot, 0.2, { BackgroundTransparency = 0.2 })
		end)
	end

	interact(row, {
		hover = function(isOver)
			tw(hl, 0.16, { BackgroundTransparency = isOver and 0.9 or 1 })
		end,
	})
	interact(chip, {
		hover = function(isOver)
			if listening then
				return
			end
			tw(chip, 0.16, { BackgroundTransparency = isOver and 0.02 or 0.15 })
			tw(keyText, 0.16, { TextColor3 = isOver and C.text or C.muted })
		end,
		click = listen,
	})

	return { Row = row, Get = function() return key end }
end

-------------------------------------------------------------- TEXTBOX
local function addTextbox(card, title, placeholder)
	local row = addRow(card, 42)

	label(row, {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(0.4, -8, 1, 0),
		Text = title,
		Font = FONT.medium,
		TextSize = 11,
		TextColor3 = C.text,
		ZIndex = 2,
	})

	local box = mk("Frame", row, {
		Size = UDim2.new(0.58, -2, 0, 28),
		Position = UDim2.new(0.42, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = C.void,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(box, 7)
	local boxStroke = stroke(box, C.line, 1, 0.3)
	mk("UIPadding", box, {
		PaddingLeft = UDim.new(0, 9),
		PaddingRight = UDim.new(0, 9),
	})

	local input = mk("TextBox", box, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = FONT.mono,
		TextSize = 9,
		TextColor3 = C.text,
		Text = "",
		PlaceholderText = placeholder or "…",
		PlaceholderColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ClearTextOnFocus = false,
		ZIndex = 3,
	})

	input.Focused:Connect(function()
		tw(boxStroke, 0.16, { Color = C.gold, Transparency = 0.25 })
		tw(box, 0.16, { BackgroundTransparency = 0.05 })
	end)

	input.FocusLost:Connect(function()
		tw(boxStroke, 0.2, { Color = C.line, Transparency = 0.3 })
		tw(box, 0.2, { BackgroundTransparency = 0.2 })
	end)

	return { Row = row, Input = input }
end

------------------------------------------------------------- PALETTE
local function addPalette(card, title, colors, selected)
	local row = addRow(card, 44)

	label(row, {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -#colors * 26 - 20, 1, 0),
		Text = title,
		Font = FONT.medium,
		TextSize = 11,
		TextColor3 = C.text,
		ZIndex = 2,
	})

	local strip = mk("Frame", row, {
		Size = UDim2.fromOffset(#colors * 26, 22),
		Position = UDim2.new(1, -2, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 2,
	})

	local rings = {}

	for i, color in ipairs(colors) do
		local holder = mk("Frame", strip, {
			Size = UDim2.fromOffset(22, 22),
			Position = UDim2.fromOffset((i - 1) * 26, 0),
			BackgroundTransparency = 1,
			ZIndex = 2,
		})

		local ring = mk("Frame", holder, {
			Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 3,
		})
		round(ring, 11)
		local ringStroke = stroke(ring, color, 1.4, (i == selected) and 0.1 or 1)
		table.insert(rings, ringStroke)

		local dot = mk("Frame", holder, {
			Size = UDim2.fromOffset(15, 15),
			Position = UDim2.fromOffset(3.5, 3.5),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 4,
		})
		round(dot, 8)
		stroke(dot, C.void, 1, 0.55)

		interact(holder, {
			hover = function(isOver)
				tw(dot, 0.14, { Size = UDim2.fromOffset(isOver and 17 or 15, isOver and 17 or 15) })
				if isOver then
					dot.Position = UDim2.fromOffset(2.5, 2.5)
				else
					dot.Position = UDim2.fromOffset(3.5, 3.5)
				end
			end,
			click = function()
				for index, ring in ipairs(rings) do
					tw(ring, 0.18, { Transparency = (index == i) and 0.1 or 1 })
				end
			end,
		})
	end

	return { Row = row }
end

-------------------------------------------------------------- PRESET
local function addPreset(card, name, meta, actionText)
	local row = addRow(card, 48)

	local badge = mk("Frame", row, {
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.fromOffset(8, 13),
		BackgroundColor3 = C.raised,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(badge, 7)
	stroke(badge, C.line, 1, 0.4)

	local innerDot = mk("Frame", badge, {
		Size = UDim2.fromOffset(6, 6),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C.gold,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	round(innerDot, 3)
	gradient(innerDot, C.gold, C.ember, 90)

	label(row, {
		Position = UDim2.fromOffset(40, 7),
		Size = UDim2.new(1, -140, 0, 15),
		Text = name,
		Font = FONT.bold,
		TextSize = 10.5,
		TextColor3 = C.text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
	})

	label(row, {
		Position = UDim2.fromOffset(40, 24),
		Size = UDim2.new(1, -140, 0, 13),
		Text = meta,
		Font = FONT.mono,
		TextSize = 8,
		TextColor3 = C.dim,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
	})

	local pill = mk("Frame", row, {
		Size = UDim2.fromOffset(58, 24),
		Position = UDim2.new(1, -2, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = C.raised,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 2,
	})
	round(pill, 6)
	local pillStroke = stroke(pill, C.line, 1, 0.35)

	local pillText = label(pill, {
		Size = UDim2.fromScale(1, 1),
		Text = actionText or "LOAD",
		Font = FONT.mono,
		TextSize = 8,
		TextColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	})

	interact(pill, {
		hover = function(isOver)
			tw(pill, 0.16, { BackgroundTransparency = isOver and 0.05 or 0.35 })
			tw(pillStroke, 0.16, { Color = isOver and C.gold or C.line, Transparency = isOver and 0.5 or 0.35 })
			tw(pillText, 0.16, { TextColor3 = isOver and C.gold or C.muted })
		end,
		click = function()
			tw(pill, 0.12, { BackgroundColor3 = C.gold, BackgroundTransparency = 0.2 })
			tw(pillText, 0.12, { TextColor3 = C.void })
			task.delay(0.2, function()
				tw(pill, 0.3, { BackgroundColor3 = C.raised, BackgroundTransparency = 0.05 })
				tw(pillText, 0.3, { TextColor3 = C.gold })
				task.delay(0.5, function()
					tw(pill, 0.4, { BackgroundTransparency = 0.35 })
					tw(pillText, 0.4, { TextColor3 = C.muted })
				end)
			end)
		end,
	})

	return { Row = row }
end

------------------------------------------------------------- ACTIONS
local function addActions(card, buttonSpecs)
	local row = addRow(card, 46)
	local inner = mk("Frame", row, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
	})
	mk("UIListLayout", inner, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local count = #buttonSpecs
	local gapCompensation = (8 * (count - 1)) / count

	for i, spec in ipairs(buttonSpecs) do
		local kind = spec.Kind or "ghost"

		local button = mk("Frame", inner, {
			Size = UDim2.new(1 / count, -gapCompensation, 0, 30),
			BackgroundColor3 = C.raised,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			LayoutOrder = i,
			ZIndex = 2,
		})
		round(button, 7)
		local buttonScale = mk("UIScale", button, { Scale = 1 })
		local buttonStroke = nil

		if kind == "primary" then
			button.BackgroundColor3 = C.gold
			button.BackgroundTransparency = 0
			gradient(button, C.gold, C.ember, 0)
		elseif kind == "danger" then
			button.BackgroundTransparency = 1
			buttonStroke = stroke(button, C.ruby, 1, 0.5)
		else
			buttonStroke = stroke(button, C.line, 1, 0.35)
		end

		local caption = label(button, {
			Size = UDim2.fromScale(1, 1),
			Text = spec.Text or "ACTION",
			Font = FONT.bold,
			TextSize = 9.5,
			TextColor3 = (kind == "primary") and C.void or ((kind == "danger") and C.ruby or C.text),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 3,
		})

		interact(button, {
			hover = function(isOver)
				tw(buttonScale, 0.18, { Scale = isOver and 1.025 or 1 })
				if kind == "primary" then
					tw(button, 0.2, { BackgroundTransparency = isOver and 0.08 or 0 })
				elseif kind == "danger" then
					tw(button, 0.18, { BackgroundTransparency = isOver and 0.88 or 1 })
					tw(buttonStroke, 0.18, { Transparency = isOver and 0.2 or 0.5 })
				else
					tw(button, 0.18, { BackgroundTransparency = isOver and 0 or 0.1 })
					tw(buttonStroke, 0.18, { Color = isOver and C.gold or C.line, Transparency = isOver and 0.65 or 0.35 })
				end
			end,
		})

		button.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				tw(buttonScale, 0.1, { Scale = 0.965 })
			end
		end)
		button.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseMovement
			then
				tw(buttonScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end)
	end

	return { Row = row }
end

--------------------------------------------------------------- NOTE
local function addNote(card, text)
	local row = addRow(card, 32)
	label(row, {
		Position = UDim2.fromOffset(8, 4),
		Size = UDim2.new(1, -16, 1, -8),
		Text = text,
		Font = FONT.medium,
		TextSize = 9,
		TextColor3 = C.dim,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 2,
	})
	return { Row = row }
end

--=====================================================================
-- 8. CONTENIDO DE EJEMPLO
--=====================================================================

local pAim = createPage("aim", "AIMBOT", "Objective acquisition, smoothing & keybinds")

local aimTargeting = addCard(pAim, 1, "TARGETING", "who to lock")
addToggle(aimTargeting, "Enable aim assist", "Master switch for the targeting loop", true)
addDropdown(aimTargeting, "Target bone", { "Head", "UpperTorso", "HumanoidRootPart", "Closest to cursor" }, 1)
addSlider(aimTargeting, "Field of view", 10, 360, 120, "°", 1)
addKeybind(aimTargeting, "Hold key", "Q")

local aimBehaviour = addCard(pAim, 2, "BEHAVIOUR", "how it feels")
addSlider(aimBehaviour, "Smoothing", 1, 20, 6, "x", 1)
addSlider(aimBehaviour, "Prediction", 0, 100, 22, " ms", 5)
addToggle(aimBehaviour, "Visibility check", "Ignore targets behind geometry", true)
addToggle(aimBehaviour, "Silent mode", "Never rotates the camera", false)
addActions(aimBehaviour, {
	{ Text = "PREVIEW ARC", Kind = "primary" },
	{ Text = "RESET", Kind = "ghost" },
})

local pVisuals = createPage("visuals", "VISUALS", "Overlay primitives, depth & palette")

local visualPlayers = addCard(pVisuals, 1, "PLAYERS", "drawn every frame")
addToggle(visualPlayers, "Box ESP", "Corner brackets around each target", true)
addToggle(visualPlayers, "Skeleton", "Joint-to-joint bone lines", false)
addToggle(visualPlayers, "Name tags", "Name, distance and health", true)
addDropdown(visualPlayers, "Box style", { "Corners", "Full outline", "Gradient fill", "Filled + glow" }, 1)
addSlider(visualPlayers, "Max distance", 50, 2000, 600, " m", 10)

local visualPalette = addCard(pVisuals, 2, "PALETTE", "accent & fill")
addPalette(visualPalette, "Accent", {
	C.gold,
	C.ember,
	C.mint,
	C.ruby,
	Color3.fromRGB(122, 162, 255),
	Color3.fromRGB(212, 126, 255),
}, 1)
addSlider(visualPalette, "Fill opacity", 0, 100, 18, "%", 1)
addToggle(visualPalette, "Respect team colors", "Keep allies in mint", true)
addNote(visualPalette, "Colors apply to every primitive in real time — no external assets required.")

local pPlayer = createPage("player", "PLAYER", "Locomotion, identity & animation")

local playerMove = addCard(pPlayer, 1, "LOCOMOTION", "how you move")
addSlider(playerMove, "Walk speed", 16, 250, 32, " sp", 1)
addSlider(playerMove, "Jump power", 50, 300, 50, " jp", 5)
addToggle(playerMove, "Infinite jump", "Jump while airborne", false)
addKeybind(playerMove, "Fly toggle", "F")

local playerIdentity = addCard(pPlayer, 2, "IDENTITY", "how you look")
addTextbox(playerIdentity, "Display name", "type a name…")
addDropdown(playerIdentity, "Animation pack", { "Default", "Ninja", "Zombie", "Mage", "Toy" }, 1)
addActions(playerIdentity, {
	{ Text = "APPLY", Kind = "primary" },
	{ Text = "REVERT", Kind = "ghost" },
})

local pWorld = createPage("world", "WORLD", "Camera, lighting & ambience")

local worldCamera = addCard(pWorld, 1, "CAMERA", "framing")
addSlider(worldCamera, "FOV override", 40, 120, 70, "°", 1)
addKeybind(worldCamera, "Free camera", "LALT")
addToggle(worldCamera, "Lock horizon", "Remove roll while flying", true)

local worldAmbience = addCard(pWorld, 2, "AMBIENCE", "mood")
addDropdown(worldAmbience, "Time of day", { "Dawn", "Noon", "Dusk", "Midnight" }, 3)
addSlider(worldAmbience, "Ambient boost", 0, 100, 45, "%", 1)
addToggle(worldAmbience, "Remove fog", "Crisp long-range view", false)
addActions(worldAmbience, {
	{ Text = "SNAPSHOT", Kind = "ghost" },
	{ Text = "RESTORE", Kind = "ghost" },
})

local pConfig = createPage("config", "CONFIG", "Profiles, keybinds & interface")

local configProfiles = addCard(pConfig, 1, "PROFILES", "saved states")
addPreset(configProfiles, "precision.aur", "aimbot · visuals · 12 flags", "LOAD")
addPreset(configProfiles, "cinematic.aur", "camera · ambience · 6 flags", "LOAD")
addPreset(configProfiles, "default.aur", "factory baseline", "LOAD")

local configManage = addCard(pConfig, 2, "MANAGEMENT", "write & read")
addTextbox(configManage, "Profile name", "e.g. ranked.aur")
addActions(configManage, {
	{ Text = "SAVE", Kind = "primary" },
	{ Text = "LOAD", Kind = "ghost" },
	{ Text = "DELETE", Kind = "danger" },
})

local configInterface = addCard(pConfig, 3, "INTERFACE", "this window")
addKeybind(configInterface, "Toggle menu", "RSHIFT")
addSlider(configInterface, "UI opacity", 60, 100, 100, "%", 1)
addToggle(configInterface, "Compact rows", "Reduce vertical padding", false)
addNote(configInterface, "AURUM build 1.0.4 · single-file Luau · UI only, no functional logic.")

--=====================================================================
-- 9. CAMBIO DE TAB
--=====================================================================

selectTab = function(key)
	local page = pages[key]
	if not page or key == currentKey then
		return
	end
	currentKey = key

	-- Sidebar: estado activo (fondo + borde + glifo + texto)
	for _, tab in ipairs(tabs) do
		local isActive = tab.Data.Key == key

		tw(tab.Frame, 0.22, { BackgroundTransparency = isActive and 0.82 or 1 })
		tw(tab.Text, 0.22, { TextColor3 = isActive and C.text or C.muted })
		tw(tab.Stroke, 0.22, {
			Color = C.gold,
			Transparency = isActive and 0.84 or 1,
		})
		tintGlyph(tab.Parts, isActive and C.gold or C.muted, isActive and 0.2 or 0.55)

		if isActive then
			tw(indicator, 0.32, {
				Position = UDim2.new(0, 6, 0, TAB_TOP + (tab.Index - 1) * TAB_STEP + 8),
			}, Enum.EasingStyle.Quint)
			tw(indicatorGlow, 0.32, { BackgroundTransparency = 0.8 })
		end
	end

	-- Encabezado del contenido
	contentTitle.Text = page.Title
	contentSub.Text = page.Subtitle

	-- Cross-fade entre páginas
	for _, other in ipairs(pageList) do
		if other ~= page and other.Group.Visible then
			local leaving = other
			tw(leaving.Group, 0.15, { GroupTransparency = 1 })
			tw(leaving.Scroll, 0.18, { Position = UDim2.fromOffset(-14, 0) })
			task.delay(0.16, function()
				if currentKey ~= leaving.Key then
					leaving.Group.Visible = false
				end
			end)
		end
	end

	page.Group.Visible = true
	page.Group.GroupTransparency = 1
	page.Group.Position = UDim2.fromOffset(16, 0)
	page.Scroll.Position = UDim2.fromOffset(0, 0)

	tw(page.Group, 0.24, { GroupTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	tw(page.Group, 0.3, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
end

--=====================================================================
-- 10. MINIMIZAR / CERRAR / DRAG / TOGGLE
--=====================================================================

local minimized = false
local menuOpen = false

local function setMinimized(value)
	if minimized == value then
		return
	end
	minimized = value

	if not value then
		sidebar.Visible = true
		content.Visible = true
		footer.Visible = true
	end

	tw(root, 0.34, { Size = UDim2.new(0, WIDTH, 0, value and TOPBAR_H or HEIGHT) },
		Enum.EasingStyle.Quint)
	tw(miniBarV, 0.22, {
		Size = value and UDim2.fromOffset(1.5, 10) or UDim2.fromOffset(1.5, 0),
		BackgroundTransparency = value and 0.15 or 1,
	})
	tw(miniBarH, 0.22, { BackgroundColor3 = C.muted })

	if value then
		task.delay(0.34, function()
			if minimized then
				sidebar.Visible = false
				content.Visible = false
				footer.Visible = false
			end
		end)
	end
end

local function playOpenAnimation()
	root.GroupTransparency = 1
	backdrop.GroupTransparency = 1
	scale.Scale = 0.96
	root.Position = UDim2.new(0.5, 0, 0.5, 12)

	tw(backdrop, 0.38, { GroupTransparency = 0 })
	tw(root, 0.32, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
	tw(root, 0.42, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Quint)
	tw(scale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function openMenu()
	if menuOpen then
		if minimized then
			setMinimized(false)
		end
		return
	end
	menuOpen = true
	gui.Enabled = true
	playOpenAnimation()
end

local function closeMenu()
	if not menuOpen then
		return
	end
	menuOpen = false

	tw(root, 0.2, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw(backdrop, 0.22, { GroupTransparency = 1 })
	tw(scale, 0.22, { Scale = 0.95 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	task.delay(0.26, function()
		if not menuOpen then
			gui.Enabled = false
		end
	end)
end

-- Botones de ventana
closeButton.MouseButton1Click:Connect(closeMenu)
minimizeButton.MouseButton1Click:Connect(function()
	setMinimized(not minimized)
end)

-- Drag desde la topbar
do
	local dragging = false
	local dragStart = nil
	local startPosition = nil

	topbar.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPosition = root.Position
		end
	end)

	-- Se escucha el release de forma global para que el drag no se quede pegado
	-- si el cursor se suelta fuera de la topbar.
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not dragStart or not startPosition then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local delta = input.Position - dragStart
			root.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

-- Notificación (toast) de arranque
local function notify(titleText, bodyText, accent)
	local toast = mk("Frame", gui, {
		Size = UDim2.fromOffset(268, 56),
		Position = UDim2.new(1, 300, 0, 30),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
		ZIndex = 50,
	})
	round(toast, 10)
	stroke(toast, C.line, 1, 0.35)

	local accentBar = mk("Frame", toast, {
		Size = UDim2.new(0, 3, 1, -16),
		Position = UDim2.fromOffset(0, 8),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 51,
	})
	round(accentBar, 2)

	label(toast, {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 14),
		Text = titleText,
		Font = FONT.bold,
		TextSize = 9.5,
		TextColor3 = accent,
		ZIndex = 51,
	})
	label(toast, {
		Position = UDim2.fromOffset(14, 27),
		Size = UDim2.new(1, -28, 0, 14),
		Text = bodyText,
		Font = FONT.mono,
		TextSize = 8,
		TextColor3 = C.muted,
		ZIndex = 51,
	})

	tw(toast, 0.5, { Position = UDim2.new(1, -24, 0, 30) }, Enum.EasingStyle.Back,
		Enum.EasingDirection.Out)

	task.delay(3.6, function()
		tw(toast, 0.35, { Position = UDim2.new(1, 300, 0, 30), BackgroundTransparency = 1 })
		task.delay(0.4, function()
			toast:Destroy()
		end)
	end)
end

-- RightShift muestra / oculta
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if not gui.Enabled then
			openMenu()
		elseif minimized then
			setMinimized(false)
		elseif menuOpen then
			closeMenu()
		else
			openMenu()
		end
	end
end)

--=====================================================================
-- 11. ARRANQUE
--=====================================================================
selectTab("aim", true)

task.defer(function()
	playOpenAnimation()
	menuOpen = true
	task.wait(0.55)
	notify("AURUM · READY", "injected via gethui() · rightshift to hide", C.gold)
end)

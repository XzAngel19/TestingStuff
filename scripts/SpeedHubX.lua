--[[
	╔══════════════════════════════════════════════════════════════════╗
	║  SPEED HUB X · GUI Recreation (v3.7.0 layout)                     ║
	║  LocalScript · client-side · script executors                     ║
	║  Visual recreation ONLY — every feature callback is an empty stub ║
	║  No gameplay, farming, combat, movement or automation logic.      ║
	║                                                                   ║
	║  Modules (single file, clearly separated):                        ║
	║    00 · Config / Theme     06 · Pages                             ║
	║    01 · Util               07 · Bootstrap                         ║
	║    02 · Components                                              ║
	║    03 · Features (stubs)                                          ║
	║    04 · Window (top bar, drag, close, open/close animation)       ║
	║    05 · Navigation (sidebar tabs)                                 ║
	║                                                                   ║
	║  Parenting: gethui() → CoreGui → PlayerGui (safe fallback)        ║
	║  INSERT key toggles visibility.                                   ║
	╚══════════════════════════════════════════════════════════════════╝
]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

-- ═══════════════════════════════════════════════════════════════════
-- MODULE 00 · CONFIG / THEME
-- ═══════════════════════════════════════════════════════════════════
local Theme = {
	-- window chrome
	WindowBg        = Color3.fromRGB(13, 13, 13),   -- near-black
	WindowBgDeep    = Color3.fromRGB(9, 9, 9),
	Stroke          = Color3.fromRGB(35, 35, 35),   -- 1px window border
	Shadow          = Color3.fromRGB(0, 0, 0),

	-- surfaces
	Card            = Color3.fromRGB(30, 30, 30),   -- rows / cards
	CardHover       = Color3.fromRGB(36, 36, 36),
	SidebarItem     = Color3.fromRGB(30, 30, 30),
	SidebarItemHover= Color3.fromRGB(38, 38, 38),
	ToggleWell      = Color3.fromRGB(40, 40, 40),   -- ON/OFF toggle container
	ToggleWellStroke= Color3.fromRGB(52, 52, 52),

	-- brand red (sampled from the reference)
	RedTop          = Color3.fromRGB(184, 16, 16),  -- selected tab gradient top
	RedBottom       = Color3.fromRGB(143, 9, 11),   -- selected tab gradient bottom
	RedSolid        = Color3.fromRGB(200, 0, 0),    -- knobs / accents
	RedKnobTop      = Color3.fromRGB(226, 32, 32),
	RedKnobBottom   = Color3.fromRGB(176, 15, 15),
	RedGlow         = Color3.fromRGB(200, 0, 0),
	RedScrollbar    = Color3.fromRGB(140, 20, 20),

	-- text
	Text            = Color3.fromRGB(245, 245, 245), -- primary
	TextSoft        = Color3.fromRGB(196, 196, 196), -- unselected tabs
	TextMuted       = Color3.fromRGB(143, 143, 143), -- sublabels
	TextFaint       = Color3.fromRGB(110, 110, 110), -- BETA tag

	-- selected tab foregrounds (dusty rose on red)
	SelectedText    = Color3.fromRGB(240, 186, 186),
	SelectedIcon    = Color3.fromRGB(224, 165, 165),
	DividerOnRed    = Color3.fromRGB(60, 8, 8),
	DividerOffRed   = Color3.fromRGB(58, 58, 58),
}

local Fonts = {
	Title  = Enum.Font.GothamBold,
	Header = Enum.Font.GothamBold,
	Label  = Enum.Font.GothamBold,
	Body   = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Value  = Enum.Font.GothamBlack,
}

local METRICS = {
	WindowW     = 760,
	WindowH     = 460,
	Corner      = 12,
	TitleBarH   = 52,
	SidebarW    = 196,
	PadL        = 14,    -- sidebar outer padding
	ItemH       = 40,
	ItemGap     = 12,
	ItemIcon    = 20,
	ContentPad  = 18,
	RowH        = 56,
	RowGap      = 10,
}

-- ═══════════════════════════════════════════════════════════════════
-- MODULE 01 · UTIL — thin instance helpers
-- ═══════════════════════════════════════════════════════════════════
local Util = {}

function Util.new(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

function Util.corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

function Util.stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Stroke
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

function Util.gradient(parent, colorA, colorB, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(colorA, colorB)
	g.Rotation = rotation or 0
	g.Parent = parent
	return g
end

local QUINT_OUT = Enum.EasingStyle.Quint
local QUART_OUT = Enum.EasingStyle.Quart
local OUT       = Enum.EasingDirection.Out
local IN        = Enum.EasingDirection.In

function Util.tween(inst, time, style, direction, props)
	local t = TweenService:Create(inst, TweenInfo.new(time, style, direction), props)
	t:Play()
	return t
end

-- TODO (executors): leave "gethui" global detection to the caller.
local function resolveParent()
	if typeof(gethui) == "function" then
		local ok, parent = pcall(gethui)
		if ok and parent then
			return parent
		end
	end
	local okCore, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and coreGui then
		return coreGui
	end
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		return localPlayer:WaitForChild("PlayerGui")
	end
	error("[SpeedHubX] No GUI parent available (gethui / CoreGui / PlayerGui)")
end

-- ═══════════════════════════════════════════════════════════════════
-- MODULE 03 · FEATURES — stubbed callbacks (intentionally empty)
-- Every control routes here. Implement nothing; keep the hooks.
-- ═══════════════════════════════════════════════════════════════════
local Features = {}

function Features.OnAutoUltimate(_enabled) end
function Features.OnAutoDash(_enabled) end
function Features.OnAimlock(_enabled) end
function Features.OnAntiKnockback(_enabled) end -- TODO: BETA stub
function Features.OnAntiStun(_enabled) end       -- TODO: BETA stub
function Features.OnAntiBusy(_enabled) end       -- TODO: BETA stub
function Features.OnAimPart(_part) end           -- TODO: stub (Head default)
function Features.OnTabSelected(_tab) end
function Features.OnClose() end

-- ═══════════════════════════════════════════════════════════════════
-- MODULE 02 · COMPONENTS — reusable controls
-- ═══════════════════════════════════════════════════════════════════
local Components = {}

-- ── Section header ("Skill", "Aim", "Body") ──────────────────────
function Components.Section(parent, text, order)
	local row = Util.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Util.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = text,
		TextColor3 = Theme.Text,
		Font = Fonts.Header,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	return row
end

-- ── Toggle row (card) ──────────────────────────────────────────────
-- Red circular knob inside a dark rounded well, matching the reference.
function Components.ToggleRow(parent, cfg)
	local row = Util.new("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(1, 0, 0, METRICS.RowH),
		LayoutOrder = cfg.order or 0,
		Parent = parent,
	})
	Util.corner(row, 9)

	local hit = Util.new("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = row,
	})

	Util.new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(1, -90, 0, 18),
		Text = cfg.title,
		TextColor3 = Theme.Text,
		Font = Fonts.Label,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	Util.new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 28),
		Size = UDim2.new(1, -90, 0, 15),
		Text = cfg.sub or "",
		TextColor3 = cfg.subColor or Theme.TextMuted,
		Font = Fonts.Body,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	-- toggle well
	local well = Util.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -13, 0.5, 0),
		Size = UDim2.fromOffset(52, 34),
		BackgroundColor3 = Theme.ToggleWell,
		Parent = row,
	})
	Util.corner(well, 10)
	Util.stroke(well, Theme.ToggleWellStroke, 1, 0.35)

	-- knob glow (only visible ON)
	local glow = Util.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Theme.RedGlow,
		BackgroundTransparency = (cfg.default == true) and 0.72 or 1,
		ZIndex = 1,
		Parent = well,
	})
	Util.corner(glow, 17)

	local knob = Util.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = well,
	})
	Util.corner(knob, 11)
	local knobGradient = Util.gradient(knob, Theme.RedKnobTop, Theme.RedKnobBottom, 90)

	local state = cfg.default == true

	local function render(animate)
		if state then
			knob.BackgroundColor3 = Color3.new(1, 1, 1)
			knobGradient.Enabled = true
			if animate then
				Util.tween(glow, 0.28, QUART_OUT, OUT, { BackgroundTransparency = 0.72 })
			else
				glow.BackgroundTransparency = 0.72
			end
		else
			-- OFF: flat dark knob, no gradient
			knob.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
			knobGradient.Enabled = false
			if animate then
				Util.tween(glow, 0.22, QUART_OUT, OUT, { BackgroundTransparency = 1 })
			else
				glow.BackgroundTransparency = 1
			end
		end
	end

	hit.MouseEnter:Connect(function()
		Util.tween(row, 0.18, QUART_OUT, OUT, { BackgroundColor3 = Theme.CardHover })
	end)
	hit.MouseLeave:Connect(function()
		Util.tween(row, 0.25, QUART_OUT, OUT, { BackgroundColor3 = Theme.Card })
	end)

	hit.MouseButton1Click:Connect(function()
		state = not state
		render(true)
		if cfg.onToggle then
			cfg.onToggle(state)
		end
	end)

	render(false)
	return row
end

-- ── Dropdown row (label | caret | divider | value chip) ─────────────
-- Replicates the "Choose Aim Part  ^  |  Head" segmented row.
-- Selection is GUI-only; the callback is a stub.
function Components.DropdownRow(parent, cfg)
	local ROW_H = 50
	local OPTION_H = 34
	local openH = #cfg.options * OPTION_H + 12

	local wrap = Util.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, ROW_H),
		LayoutOrder = cfg.order or 0,
		ClipsDescendants = true,
		Parent = parent,
	})

	local row = Util.new("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(1, 0, 0, ROW_H),
		Parent = wrap,
	})
	Util.corner(row, 9)

	-- left label
	Util.new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0.52, 0, 1, 0),
		Text = cfg.label,
		TextColor3 = Theme.Text,
		Font = Fonts.Label,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	-- caret (^) drawn with two bars
	local caret = Util.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -172, 0.5, 0),
		Size = UDim2.fromOffset(18, 12),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local barA = Util.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, -3.3, 0.42, 0),
		Size = UDim2.fromOffset(9, 1.8),
		Rotation = -42,
		BackgroundColor3 = Color3.fromRGB(216, 216, 216),
		Parent = caret,
	})
	local barB = Util.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 3.3, 0.42, 0),
		Size = UDim2.fromOffset(9, 1.8),
		Rotation = 42,
		BackgroundColor3 = Color3.fromRGB(216, 216, 216),
		Parent = caret,
	})
	Util.corner(barA, 1)
	Util.corner(barB, 1)

	-- vertical divider between caret and value
	Util.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, -138, 0.5, 0),
		Size = UDim2.fromOffset(1, 24),
		BackgroundColor3 = Theme.DividerOffRed,
		BackgroundTransparency = 0.25,
		Parent = row,
	})

	-- value chip (e.g. "Head")
	local valueChip = Util.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 118, 0, ROW_H - 10),
		BackgroundColor3 = Theme.ToggleWell,
		Parent = row,
	})
	Util.corner(valueChip, 7)
	Util.stroke(valueChip, Color3.fromRGB(54, 54, 54), 1, 0.4)

	local valueLabel = Util.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = (cfg.options and cfg.options[cfg.defaultIndex or 1]) or "—",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Fonts.Value,
		TextSize = 15,
		Parent = valueChip,
	})

	-- accordion with options
	local accordion = Util.new("Frame", {
		Position = UDim2.new(0, 0, 0, ROW_H + 4),
		Size = UDim2.new(1, 0, 0, openH),
		BackgroundColor3 = Theme.Card,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = wrap,
	})
	Util.corner(accordion, 9)
	local accStroke = Util.stroke(accordion, Color3.fromRGB(46, 46, 46), 1, 1)

	Util.new("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = accordion,
	})
	Util.new("UIListLayout", {
		Padding = UDim.new(0, 2),
		Parent = accordion,
	})

	local isOpen = false
	local optionButtons = {}

	local function setOpen(open, animate)
		isOpen = open
		local goal = UDim2.new(1, 0, 0, open and (ROW_H + 4 + openH) or ROW_H)
		if animate then
			Util.tween(wrap, 0.3, QUINT_OUT, OUT, { Size = goal })
			Util.tween(accordion, 0.3, QUINT_OUT, OUT, { BackgroundTransparency = open and 0 or 1 })
			Util.tween(accStroke, 0.3, QUINT_OUT, OUT, { Transparency = open and 0.1 or 1 })
			Util.tween(caret, 0.3, QUINT_OUT, OUT, { Rotation = open and 180 or 0 })
		else
			wrap.Size = goal
			accordion.BackgroundTransparency = open and 0 or 1
			accStroke.Transparency = open and 0.1 or 1
			caret.Rotation = open and 180 or 0
		end
	end

	local function isSelected(option)
		return option == valueLabel.Text
	end

	for i, option in ipairs(cfg.options or {}) do
		local optionBtn = Util.new("TextButton", {
			BackgroundColor3 = Theme.CardHover,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, OPTION_H),
			LayoutOrder = i,
			Parent = accordion,
		})
		Util.corner(optionBtn, 7)
		local optLabel = Util.new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(1, -20, 1, 0),
			Text = option,
			TextColor3 = isSelected(option) and Color3.fromRGB(255, 255, 255) or Theme.TextSoft,
			Font = isSelected(option) and Fonts.Label or Fonts.Medium,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = optionBtn,
		})
		optionBtn.MouseEnter:Connect(function()
			Util.tween(optionBtn, 0.15, QUART_OUT, OUT, { BackgroundTransparency = 0 })
		end)
		optionBtn.MouseLeave:Connect(function()
			Util.tween(optionBtn, 0.2, QUART_OUT, OUT, { BackgroundTransparency = 1 })
		end)
		optionBtn.MouseButton1Click:Connect(function()
			valueLabel.Text = option
			for _, other in ipairs(optionButtons) do
				local otherLabel = other[1]
				local sel = otherLabel.Text == option
				otherLabel.TextColor3 = sel and Color3.fromRGB(255, 255, 255) or Theme.TextSoft
				otherLabel.Font = sel and Fonts.Label or Fonts.Medium
			end
			if cfg.onSelect then
				cfg.onSelect(option)
			end
			setOpen(false, true)
		end)
		table.insert(optionButtons, { optLabel })
	end

	-- click zone on the top row only
	local clickZone = Util.new("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 6,
		Parent = row,
	})
	clickZone.MouseEnter:Connect(function()
		Util.tween(row, 0.18, QUART_OUT, OUT, { BackgroundColor3 = Theme.CardHover })
	end)
	clickZone.MouseLeave:Connect(function()
		Util.tween(row, 0.25, QUART_OUT, OUT, { BackgroundColor3 = Theme.Card })
	end)
	clickZone.MouseButton1Click:Connect(function()
		setOpen(not isOpen, true)
	end)

	setOpen(false, false)
	return wrap
end

-- ── Empty state for stub pages (Home / Farming / Killer / Misc) ─────
function Components.EmptyState(parent, title, sub, order)
	local holder = Util.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 150),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	local ghost = Util.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.34),
		Size = UDim2.fromOffset(46, 46),
		BackgroundTransparency = 1,
		Parent = holder,
	})
	Util.corner(ghost, 23)
	Util.stroke(ghost, Color3.fromRGB(52, 52, 52), 2, 0)
	Util.new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0.56, 0),
		Size = UDim2.new(1, 0, 0, 20),
		Text = title,
		TextColor3 = Theme.TextSoft,
		Font = Fonts.Label,
		TextSize = 13,
		Parent = holder,
	})
	Util.new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0.66, 0),
		Size = UDim2.new(1, 0, 0, 16),
		Text = sub,
		TextColor3 = Theme.TextFaint,
		Font = Fonts.Body,
		TextSize = 10,
		Parent = holder,
	})
	return holder
end

-- ═══════════════════════════════════════════════════════════════════
-- MODULE 04 · WINDOW — chrome, drag, close, open/close animation
-- ═══════════════════════════════════════════════════════════════════
local Window = {}

function Window.Build(guiParent)
	-- wipe previous instance
	local previous = guiParent:FindFirstChild("SpeedHubX")
	if previous then
		previous:Destroy()
	end

	local gui = Util.new("ScreenGui", {
		Name = "SpeedHubX",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = true,
		Parent = guiParent,
	})

	-- CanvasGroup so the whole window fades at once
	local root = Util.new("CanvasGroup", {
		Name = "Root",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		Parent = gui,
	})

	local shadow = Util.new("Frame", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 9),
		Size = UDim2.fromOffset(METRICS.WindowW + 16, METRICS.WindowH + 16),
		BackgroundColor3 = Theme.Shadow,
		BackgroundTransparency = 0.52,
		Parent = root,
	})
	Util.corner(shadow, 16)

	local main = Util.new("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(METRICS.WindowW, METRICS.WindowH),
		BackgroundColor3 = Theme.WindowBg,
		ClipsDescendants = true,
		Parent = root,
	})
	Util.corner(main, METRICS.Corner)
	Util.gradient(main, Theme.WindowBg, Theme.WindowBgDeep, 90)
	Util.stroke(main, Theme.Stroke, 1, 0.1)

	local scale = Util.new("UIScale", { Scale = 0.92 })
	scale.Parent = main

	-- ── Title bar ─────────────────────────────────────────────────
	local topBar = Util.new("Frame", {
		Name = "TopBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, METRICS.TitleBarH),
		Parent = main,
	})

	Util.new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Text = "Speed Hub X | Version: 3.7.0",
		TextColor3 = Theme.Text,
		Font = Fonts.Title,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topBar,
	})

	-- close button (×), drawn with two bars
	local closeBtn = Util.new("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = topBar,
	})
	Util.corner(closeBtn, 8)
	local glyphs = {}
	for _, rot in ipairs({ 45, -45 }) do
		local bar = Util.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(12, 1.7),
			Rotation = rot,
			BackgroundColor3 = Theme.Text,
			Parent = closeBtn,
		})
		Util.corner(bar, 1)
		glyphs[#glyphs + 1] = bar
	end

	closeBtn.MouseEnter:Connect(function()
		Util.tween(closeBtn, 0.18, QUART_OUT, OUT, {
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(46, 17, 17),
		})
		for _, g in ipairs(glyphs) do
			Util.tween(g, 0.18, QUART_OUT, OUT, { BackgroundColor3 = Color3.fromRGB(255, 107, 107) })
		end
	end)
	closeBtn.MouseLeave:Connect(function()
		Util.tween(closeBtn, 0.25, QUART_OUT, OUT, { BackgroundTransparency = 1 })
		for _, g in ipairs(glyphs) do
			Util.tween(g, 0.25, QUART_OUT, OUT, { BackgroundColor3 = Theme.Text })
		end
	end)

	-- subtle bottom hairline under the title bar
	Util.new("Frame", {
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.45,
		Parent = topBar,
	})

	-- ── Drag (title bar, excluding the close button) ───────────────
	local dragActive, dragStart, startOffset = false, nil, nil

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		if not (isMouse or isTouch) then
			return
		end
		local a, s = topBar.AbsolutePosition, topBar.AbsoluteSize
		local p = input.Position
		if p.X >= a.X and p.X <= a.X + s.X - 56 and p.Y >= a.Y and p.Y <= a.Y + s.Y then
			dragActive = true
			dragStart = p
			startOffset = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragActive then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(0.5, startOffset.X + delta.X, 0.5, startOffset.Y + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragActive = false
		end
	end)

	-- ── Show / hide / close ─────────────────────────────────────────
	local visible = true

	local function playOpen()
		root.Visible = true
		Util.tween(root, 0.45, QUINT_OUT, OUT, { GroupTransparency = 0 })
		Util.tween(scale, 0.55, Enum.EasingStyle.Back, OUT, { Scale = 1 })
	end

	local function playHide(fadeOnly)
		Util.tween(root, 0.22, QUINT_OUT, IN, { GroupTransparency = 1 })
		Util.tween(scale, 0.22, QUINT_OUT, IN, { Scale = 0.88 })
		if fadeOnly then
			task.delay(0.23, function()
				root.Visible = false
			end)
		end
	end

	local function toggleVisible()
		visible = not visible
		if visible then
			playOpen()
		else
			playHide(true)
		end
	end

	local function close()
		Features.OnClose()
		Util.tween(root, 0.28, QUINT_OUT, IN, { GroupTransparency = 1 })
		Util.tween(scale, 0.28, QUINT_OUT, IN, { Scale = 0.85 })
		task.delay(0.3, function()
			gui:Destroy()
		end)
	end

	closeBtn.MouseButton1Click:Connect(close)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if input.KeyCode == Enum.KeyCode.Insert then
			toggleVisible()
		end
	end)

	return {
		gui = gui,
		root = root,
		main = main,
		scale = scale,
		topBar = topBar,
		show = playOpen,
		hide = function() playHide(true) end,
		close = close,
	}
end

-- ═══════════════════════════════════════════════════════════════════
-- MODULE 05 · NAVIGATION — sidebar tabs + instance-drawn icons
-- ═══════════════════════════════════════════════════════════════════
local Navigation = {}

-- ── Icons built from raw instances (no images) ─────────────────────
-- Each returns (container, fills, strokes) so the caller can tint.
local function createIcon(kind, tint)
	local box = Util.new("Frame", {
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
	})
	local fills, strokes, patches = {}, {}, {}
	local function fill(size, pos, rot, cornerRadius)
		local f = Util.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = pos,
			Size = size,
			Rotation = rot or 0,
			BackgroundColor3 = tint,
			Parent = box,
		})
		Util.corner(f, cornerRadius or 1.2)
		fills[#fills + 1] = f
		return f
	end

	if kind == "home" then
		-- paw print: central pad + three toes
		local pad = fill(UDim2.fromOffset(11, 8.6), UDim2.fromOffset(10, 14.4), 0, 4.4)
		pad.Size = UDim2.fromOffset(11, 9)
		fill(UDim2.fromOffset(3.6, 3.6), UDim2.fromOffset(3.6, 6.4), 0, 1.8)
		fill(UDim2.fromOffset(3.6, 3.6), UDim2.fromOffset(10, 4.6), 0, 1.8)
		fill(UDim2.fromOffset(3.6, 3.6), UDim2.fromOffset(16.4, 6.4), 0, 1.8)
	elseif kind == "main" then
		-- house: body + two-bar roof + door cutout
		fill(UDim2.fromOffset(11, 8), UDim2.fromOffset(10, 13.6), 0, 1.6)   -- body
		fill(UDim2.fromOffset(9.6, 2.2), UDim2.fromOffset(6.6, 6.4), -42, 1.1) -- roof left
		fill(UDim2.fromOffset(9.6, 2.2), UDim2.fromOffset(13.4, 6.4), 42, 1.1) -- roof right
		-- door: fill painted to match the tab background (reads as a cutout)
		local door = Util.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromOffset(10, 17.6),
			Size = UDim2.fromOffset(3.4, 4.8),
			BackgroundColor3 = Color3.fromRGB(13, 13, 13),
			Parent = box,
		})
		Util.corner(door, 1.2)
		patches[#patches + 1] = door
	elseif kind == "farming" then
		-- pickaxe: diagonal handle + perpendicular head
		fill(UDim2.fromOffset(15.4, 2.4), UDim2.fromOffset(9.2, 11.6), -45, 1.2) -- handle
		fill(UDim2.fromOffset(10.6, 2.2), UDim2.fromOffset(13.6, 4.9), 45, 1.1)  -- head
	elseif kind == "killer" then
		-- skeletal hand: four finger bars over a palm
		fill(UDim2.fromOffset(2.5, 6.6), UDim2.fromOffset(5.0, 7.2), 0, 1.25)
		fill(UDim2.fromOffset(2.5, 8.2), UDim2.fromOffset(8.7, 6.6), 0, 1.25)
		fill(UDim2.fromOffset(2.5, 8.2), UDim2.fromOffset(12.3, 6.6), 0, 1.25)
		fill(UDim2.fromOffset(2.5, 6.6), UDim2.fromOffset(15.6, 7.2), 0, 1.25)
		fill(UDim2.fromOffset(13.4, 6.4), UDim2.fromOffset(10.1, 14.4), 0, 2.4)  -- palm
	elseif kind == "misc" then
		-- mountain range: two chevron peaks
		fill(UDim2.fromOffset(8.2, 2.1), UDim2.fromOffset(5.6, 8.6), -42, 1.05)
		fill(UDim2.fromOffset(8.2, 2.1), UDim2.fromOffset(9.4, 8.6), 42, 1.05)
		fill(UDim2.fromOffset(8.2, 2.1), UDim2.fromOffset(11.6, 12.4), -42, 1.05)
		fill(UDim2.fromOffset(8.2, 2.1), UDim2.fromOffset(15.4, 12.4), 42, 1.05)
	end

	return box, fills, strokes, patches
end

-- ── Tab definitions ────────────────────────────────────────────────
local TABS = {
	{ name = "Home",    icon = "home"    },
	{ name = "Main",    icon = "main"    },
	{ name = "Farming", icon = "farming" },
	{ name = "Killer",  icon = "killer"  },
	{ name = "Misc",    icon = "misc"    },
}
local ICON_IDLE   = Color3.fromRGB(168, 168, 168)
local ICON_ACTIVE = Theme.SelectedIcon

-- `onSwitch(index)` is called after the visuals update.
function Navigation.Build(parent, onSwitch)
	local container = Util.new("Frame", {
		Name = "Sidebar",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, METRICS.TitleBarH),
		Size = UDim2.new(0, METRICS.SidebarW, 1, -METRICS.TitleBarH),
		Parent = parent,
	})

	local list = Util.new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, METRICS.PadL, 0, 8),
		Size = UDim2.new(1, -METRICS.PadL * 2, 0, #TABS * (METRICS.ItemH + METRICS.ItemGap)),
		Parent = container,
	})
	Util.new("UIListLayout", {
		Padding = UDim.new(0, METRICS.ItemGap),
		Parent = list,
	})

	local tabs = {}

	for i, def in ipairs(TABS) do
		local row = Util.new("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, METRICS.ItemH),
			LayoutOrder = i,
			Parent = list,
		})
		Util.corner(row, 10)
		local rowGradient = Util.gradient(row, Theme.RedTop, Theme.RedBottom, 90)
		rowGradient.Enabled = false

		local icon, fills, _, patches = createIcon(def.icon, ICON_IDLE)
		icon.Position = UDim2.fromOffset(13, (METRICS.ItemH - 20) / 2)
		icon.Parent = row

		-- vertical divider between icon and label
		local divider = Util.new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 44, 0.5, 0),
			Size = UDim2.fromOffset(1, 16),
			BackgroundColor3 = Theme.DividerOffRed,
			Parent = row,
		})

		local label = Util.new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 55, 0, 0),
			Size = UDim2.new(1, -65, 1, 0),
			Text = def.name,
			TextColor3 = Theme.TextSoft,
			Font = Fonts.Medium,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local hit = Util.new("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
			Parent = row,
		})

		tabs[i] = {
			def = def,
			row = row,
			gradient = rowGradient,
			divider = divider,
			label = label,
			fills = fills,
			patches = patches or {},
			active = false,
		}

		hit.MouseButton1Click:Connect(function()
			Navigation.SwitchTo(tabs, i, true)
			if onSwitch then
				onSwitch(i)
			end
		end)
		hit.MouseEnter:Connect(function()
			if not tabs[i].active then
				Util.tween(row, 0.16, QUART_OUT, OUT, {
					BackgroundTransparency = 0,
					BackgroundColor3 = Theme.SidebarItemHover,
				})
			end
		end)
		hit.MouseLeave:Connect(function()
			if not tabs[i].active then
				Util.tween(row, 0.22, QUART_OUT, OUT, { BackgroundTransparency = 1 })
			end
		end)
	end

	return { container = container, tabs = tabs }
end

-- Central visual-state switcher (also used at boot).
function Navigation.SwitchTo(tabs, index, animate)
	for j, tab in ipairs(tabs) do
		local isActive = (j == index)
		tab.active = isActive
		if isActive then
			tab.row.BackgroundTransparency = 0
			tab.row.BackgroundColor3 = Color3.new(1, 1, 1)
			tab.gradient.Enabled = true
			tab.label.TextColor3 = Theme.SelectedText
			tab.divider.BackgroundColor3 = Theme.DividerOnRed
		else
			tab.gradient.Enabled = false
			tab.row.BackgroundTransparency = 1
			tab.label.TextColor3 = Theme.TextSoft
			tab.divider.BackgroundColor3 = Theme.DividerOffRed
		end
		local tint = isActive and ICON_ACTIVE or ICON_IDLE
		local patchTint = isActive and Color3.fromRGB(120, 10, 10) or Color3.fromRGB(13, 13, 13)
		for _, f in ipairs(tab.fills) do
			if animate then
				Util.tween(f, 0.25, QUART_OUT, OUT, { BackgroundColor3 = tint })
			else
				f.BackgroundColor3 = tint
			end
		end
		for _, p in ipairs(tab.patches) do
			p.BackgroundColor3 = patchTint
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- MODULE 06 · PAGES — content per tab (Main fully replicated)
-- ═══════════════════════════════════════════════════════════════════
local Pages = {}

local CONTENT_X = METRICS.SidebarW
local CONTENT_W = METRICS.WindowW - METRICS.SidebarW
local CONTENT_H = METRICS.WindowH - METRICS.TitleBarH

local function createPage(name, parent)
	local page = Util.new("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 2,
		Parent = parent,
	})
	local scroll = Util.new("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.RedScrollbar,
		ScrollBarImageTransparency = 0.15,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = page,
	})
	Util.new("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 14),
		Parent = scroll,
	})
	Util.new("UIListLayout", {
		Padding = UDim.new(0, METRICS.RowGap),
		Parent = scroll,
	})
	return page, scroll
end

function Pages.Build(parent)
	local pages = {}

	-- ── Tab 1 · Home (stub) ─────────────────────────────────────────
	do
		local _, scroll = createPage("PageHome", parent)
		Pages.PopulateHome(scroll)
		pages[1] = parent:FindFirstChild("PageHome")
	end

	-- ── Tab 2 · Main (fully replicated) ──────────────────────────────
	do
		local _, scroll = createPage("PageMain", parent)

		Components.Section(scroll, "Skill", 1)
		Components.ToggleRow(scroll, {
			title = "Auto Ultimate",
			sub = "This is Meaning Auto Use Ultimate",
			default = true,
			order = 2,
			onToggle = function(state)
				Features.OnAutoUltimate(state)
			end,
		})
		Components.ToggleRow(scroll, {
			title = "Auto Dash",
			sub = "This is Meaning Auto Use Dash",
			default = true,
			order = 3,
			onToggle = function(state)
				Features.OnAutoDash(state)
			end,
		})

		Components.Section(scroll, "Aim", 4)
		Components.DropdownRow(scroll, {
			label = "Choose Aim Part",
			options = { "Head", "Torso", "Random" },
			defaultIndex = 1,
			order = 5,
			onSelect = function(option)
				Features.OnAimPart(option)
			end,
		})
		Components.ToggleRow(scroll, {
			title = "Aimlock",
			sub = "Aimlock = Lock Camera Player",
			default = false,
			order = 6,
			onToggle = function(state)
				Features.OnAimlock(state)
			end,
		})

		Components.Section(scroll, "Body", 7)
		Components.ToggleRow(scroll, {
			title = "Anti-Knockback",
			sub = "BETA",
			subColor = Theme.TextFaint,
			default = false,
			order = 8,
			onToggle = function(state)
				Features.OnAntiKnockback(state)
			end,
		})
		Components.ToggleRow(scroll, {
			title = "Anti-Stun",
			sub = "BETA",
			subColor = Theme.TextFaint,
			default = false,
			order = 9,
			onToggle = function(state)
				Features.OnAntiStun(state)
			end,
		})
		Components.ToggleRow(scroll, {
			title = "Anti-Busy",
			sub = "BETA",
			subColor = Theme.TextFaint,
			default = false,
			order = 10,
			onToggle = function(state)
				Features.OnAntiBusy(state)
			end,
		})

		pages[2] = parent:FindFirstChild("PageMain")
	end

	-- ── Tabs 3-5 · stub pages ───────────────────────────────────────
	do
		local _, scroll = createPage("PageFarming", parent)
		Components.EmptyState(scroll, "Farming", "Stub page — no public modules in this build.", 1)
		pages[3] = parent:FindFirstChild("PageFarming")
	end
	do
		local _, scroll = createPage("PageKiller", parent)
		Components.EmptyState(scroll, "Killer", "Stub page — no public modules in this build.", 1)
		pages[4] = parent:FindFirstChild("PageKiller")
	end
	do
		local _, scroll = createPage("PageMisc", parent)
		Components.EmptyState(scroll, "Misc", "Stub page — no public modules in this build.", 1)
		pages[5] = parent:FindFirstChild("PageMisc")
	end

	return pages
end

-- Home content: a couple of harmless information rows, still stubs.
function Pages.PopulateHome(scroll)
	Components.Section(scroll, "Speed Hub X", 1)
	local info = Util.new("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.new(1, 0, 0, 92),
		LayoutOrder = 2,
		Parent = scroll,
	})
	Util.corner(info, 9)
	Util.new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 12),
		Size = UDim2.new(1, -28, 0, 20),
		Text = "Thank you for using Speed Hub X.",
		TextColor3 = Theme.Text,
		Font = Fonts.Label,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = info,
	})
	Util.new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 34),
		Size = UDim2.new(1, -28, 0, 40),
		Text = "All toggles on the Main tab are interface stubs — no automation, farming or combat logic is implemented or executed.",
		TextColor3 = Theme.TextMuted,
		Font = Fonts.Body,
		TextSize = 10,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = info,
	})
end

function Pages.SwitchTo(pages, index, animate)
	for j, page in ipairs(pages) do
		if j == index then
			page.Visible = true
			if animate then
				page.Position = UDim2.new(0, 18, 0, 0)
				Util.tween(page, 0.38, QUINT_OUT, OUT, { Position = UDim2.new(0, 0, 0, 0) })
			end
		else
			page.Visible = false
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- MODULE 07 · BOOTSTRAP — assemble everything
-- ═══════════════════════════════════════════════════════════════════
local guiParent = resolveParent()

local window = Window.Build(guiParent)
local main = window.main

-- content area right of the sidebar
local content = Util.new("Frame", {
	Name = "Content",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, CONTENT_X, 0, METRICS.TitleBarH),
	Size = UDim2.new(0, CONTENT_W, 0, CONTENT_H),
	Parent = main,
})

local pages = Pages.Build(content)

local nav = Navigation.Build(main, function(index)
	Pages.SwitchTo(pages, index, true)
	Features.OnTabSelected(({
		[1] = "Home",
		[2] = "Main",
		[3] = "Farming",
		[4] = "Killer",
		[5] = "Misc",
	})[index])
end)

-- default selected tab: Main (as in the reference)
Navigation.SwitchTo(nav.tabs, 2, false)
Pages.SwitchTo(pages, 2, false)

-- open animation
window.show()

print("[SpeedHubX] v3.7.0 GUI loaded (visual recreation — stubs only). INSERT toggles visibility.")

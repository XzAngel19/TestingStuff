-- BRUMA / interface lab — LocalScript autocontenido, exclusivamente visual.
-- Requiere un entorno que exponga gethui(); no es una API estándar de Roblox Studio.
-- No modifica el juego, no usa remotes, HTTP, assets ni persistencia.
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
assert(type(gethui) == "function", "BRUMA requiere gethui() en este entorno")
local parent = gethui()
local previous = parent:FindFirstChild("BrumaInterface")
if previous then previous:Destroy() end

local C = {
	bg = Color3.fromRGB(16, 21, 24), panel = Color3.fromRGB(23, 30, 33),
	card = Color3.fromRGB(29, 37, 40), hover = Color3.fromRGB(38, 49, 51),
	line = Color3.fromRGB(54, 67, 69), text = Color3.fromRGB(229, 237, 228),
	muted = Color3.fromRGB(136, 155, 153), mint = Color3.fromRGB(164, 232, 195),
	amber = Color3.fromRGB(238, 187, 115), red = Color3.fromRGB(235, 132, 128),
}
local connections, tweens = {}, setmetatable({}, {__mode = "k"})
local dead, closing = false, false
local function listen(signal, fn)
	local connection = signal:Connect(fn)
	table.insert(connections, connection)
	return connection
end
local function make(class, props, into)
	local obj = Instance.new(class)
	for key, value in pairs(props or {}) do obj[key] = value end
	obj.Parent = into
	return obj
end
local function round(obj, radius)
	make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, obj)
end
local function stroke(obj, color, transparency)
	return make("UIStroke", {Color = color or C.line, Thickness = 1, Transparency = transparency or 0}, obj)
end
local function tween(obj, props, duration)
	if dead then return end
	-- One active tween per object: rapid input never leaves competing transitions.
	if tweens[obj] then tweens[obj]:Cancel() end
	local t = TweenService:Create(obj, TweenInfo.new(duration or .18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tweens[obj] = t
	t:Play()
	return t
end
local function label(into, text, x, y, w, h, size, color, font)
	return make("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h), Text = text, TextSize = size or 13,
		Font = font or Enum.Font.Gotham, TextColor3 = color or C.text,
		TextXAlignment = Enum.TextXAlignment.Left}, into)
end
local function button(into, text, x, y, w, h, accent)
	local b = make("TextButton", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = accent and C.mint or C.card, Text = text, TextSize = 12,
		Font = Enum.Font.GothamMedium, TextColor3 = accent and C.bg or C.text,
		AutoButtonColor = false, BorderSizePixel = 0}, into)
	round(b, 7)
	local normal = b.BackgroundColor3
	local scale = make("UIScale", {Scale = 1}, b)
	listen(b.MouseEnter, function() tween(b, {BackgroundColor3 = accent and Color3.fromRGB(190, 249, 215) or C.hover}) end)
	listen(b.MouseLeave, function() tween(b, {BackgroundColor3 = normal}); tween(scale, {Scale = 1}) end)
	listen(b.MouseButton1Down, function() tween(scale, {Scale = .96}, .09) end)
	listen(b.MouseButton1Up, function() tween(scale, {Scale = 1}, .16) end)
	return b
end
local gui = make("ScreenGui", {Name = "BrumaInterface", ResetOnSpawn = false,
	IgnoreGuiInset = true, DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, parent)
listen(gui.Destroying, function()
	dead = true
	for _, c in ipairs(connections) do c:Disconnect() end
	for _, t in pairs(tweens) do t:Cancel() end
end)
local stage = make("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, gui)
local root = make("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(820, 576), BackgroundTransparency = 1}, stage)
local fit = make("UIScale", {Scale = 1}, root)
local function resize()
	local view = stage.AbsoluteSize
	fit.Scale = math.min(1, math.max(.1, math.min((view.X - 24) / 860, (view.Y - 24) / 616)))
	root.Position = UDim2.fromOffset(view.X / 2, view.Y / 2)
end
listen(stage:GetPropertyChangedSignal("AbsoluteSize"), resize)
resize()
-- Layered, asset-free soft shadow.
local shadows = {}
for i = 4, 1, -1 do
	local s = make("Frame", {Position = UDim2.fromOffset(-i * 4, -i * 3 + 8),
		Size = UDim2.new(1, i * 8, 1, i * 6), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = .89, BorderSizePixel = 0}, root)
	round(s, 18 + i * 2)
	table.insert(shadows, s)
end
local shell = make("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg,
	BorderSizePixel = 0, GroupTransparency = 1, ClipsDescendants = true}, root)
round(shell, 14); stroke(shell)
make("UIGradient", {Color = ColorSequence.new(C.panel, C.bg), Rotation = 30}, shell)
local header = make("Frame", {Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, Active = true}, shell)
local logo = make("Frame", {Position = UDim2.fromOffset(24, 22), Size = UDim2.fromOffset(22, 22),
	BackgroundColor3 = C.mint, Rotation = 45, BorderSizePixel = 0}, header)
round(logo, 5)
label(header, "B", 29, 22, 18, 22, 13, C.bg, Enum.Font.GothamBold).ZIndex = 2
label(header, "BRUMA", 60, 13, 135, 25, 20, C.text, Enum.Font.GothamBold)
label(header, "I N T E R F A C E   L A B", 61, 38, 195, 14, 9, C.muted, Enum.Font.Code)
label(header, "EDICIÓN  /  001", 555, 23, 135, 20, 11, C.muted, Enum.Font.Code)
local minimize = button(header, "–", 718, 18, 32, 30)
local close = button(header, "×", 760, 18, 32, 30)
make("Frame", {Position = UDim2.fromOffset(0, 65), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0}, shell)
local body = make("Frame", {Position = UDim2.fromOffset(0, 66), Size = UDim2.fromOffset(820, 470), BackgroundTransparency = 1}, shell)
local sidebar = make("Frame", {Size = UDim2.fromOffset(184, 470), BackgroundColor3 = C.bg, BackgroundTransparency = .35, BorderSizePixel = 0}, body)
label(sidebar, "ESPACIO DE TRABAJO", 22, 22, 156, 18, 9, C.muted, Enum.Font.Code)
local indicator = make("Frame", {Position = UDim2.fromOffset(12, 60), Size = UDim2.fromOffset(3, 24), BackgroundColor3 = C.mint, BorderSizePixel = 0}, sidebar)
round(indicator, 2)
label(sidebar, "01 / DISEÑO LOCAL", 22, 346, 150, 18, 10, C.mint, Enum.Font.Code)
label(sidebar, "Sin conexiones.\nSin cambios al juego.\nSolo posibilidades.", 22, 374, 150, 64, 12, C.muted).TextYAlignment = Enum.TextYAlignment.Top
local content = make("Frame", {Position = UDim2.fromOffset(184, 0), Size = UDim2.fromOffset(636, 470), BackgroundTransparency = 1}, body)
local footer = make("Frame", {Position = UDim2.fromOffset(0, 536), Size = UDim2.fromOffset(820, 40), BackgroundColor3 = C.bg, BorderSizePixel = 0}, shell)
make("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0}, footer)
local dot = make("Frame", {Position = UDim2.fromOffset(23, 17), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = C.mint, BorderSizePixel = 0}, footer); round(dot, 6)
local status = label(footer, "SANDBOX VISUAL  /  Ninguna función conectada", 40, 10, 555, 20, 10, C.muted, Enum.Font.Code)
label(footer, "BRM–001   •   LOCAL", 649, 10, 160, 20, 10, C.muted, Enum.Font.Code)
local function notify(text)
	status.Text = "VISTA PREVIA  /  " .. text
end
local pages, tabs = {}, {}
local names = {"General", "Apariencia", "Perfiles", "Acerca de"}
local subtitles = {"Tu espacio, a tu manera.", "Pequeños detalles. Otra atmósfera.", "Una colección de posibilidades.", "Diseñado para no pasar desapercibido."}
local function section(page, text, y)
	label(page, text, 26, y, 570, 20, 10, C.muted, Enum.Font.Code)
end
local function card(page, y, height)
	local f = make("Frame", {Position = UDim2.fromOffset(26, y), Size = UDim2.fromOffset(584, height), BackgroundColor3 = C.card, BorderSizePixel = 0}, page)
	round(f, 10); stroke(f, C.line, .35)
	return f
end
local function rowText(f, title, description)
	label(f, title, 16, 10, 390, 22, 13, C.text, Enum.Font.GothamMedium)
	label(f, description, 16, 33, 390, 18, 11, C.muted)
end
local function toggle(f, title, description, initial)
	rowText(f, title, description)
	local on = initial
	local track = button(f, "", 518, 20, 46, 25)
	track.BackgroundColor3 = on and C.mint or C.line
	local knob = make("Frame", {Position = UDim2.fromOffset(on and 24 or 4, 4), Size = UDim2.fromOffset(17, 17), BackgroundColor3 = C.bg, BorderSizePixel = 0}, track)
	round(knob, 20)
	-- Override hover with state-aware colors.
	listen(track.MouseLeave, function() tween(track, {BackgroundColor3 = on and C.mint or C.line}) end)
	listen(track.Activated, function()
		on = not on
		tween(track, {BackgroundColor3 = on and C.mint or C.line})
		tween(knob, {Position = UDim2.fromOffset(on and 24 or 4, 4)}, .24)
		notify(title .. (on and " activado (demo)" or " desactivado (demo)"))
	end)
end
local sliderDrag
local function slider(f, title, description, initial)
	rowText(f, title, description)
	local value = label(f, tostring(initial) .. "%", 494, 12, 70, 22, 13, C.mint, Enum.Font.Code)
	value.TextXAlignment = Enum.TextXAlignment.Right
	local hit = make("TextButton", {Position = UDim2.fromOffset(16, 58), Size = UDim2.fromOffset(548, 24), Text = "", BackgroundTransparency = 1, AutoButtonColor = false}, f)
	local rail = make("Frame", {Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = C.line, BorderSizePixel = 0}, hit); round(rail, 4)
	local fill = make("Frame", {Size = UDim2.fromScale(initial / 100, 1), BackgroundColor3 = C.mint, BorderSizePixel = 0}, rail); round(fill, 4)
	make("UIGradient", {Color = ColorSequence.new(C.mint, C.amber)}, fill)
	local knob = make("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(initial / 100, .5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = C.text, BorderSizePixel = 0}, rail); round(knob, 10)
	local function update(x)
		local ratio = math.clamp((x - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
		value.Text = tostring(math.floor(ratio * 100 + .5)) .. "%"
		tween(fill, {Size = UDim2.fromScale(ratio, 1)}, .08)
		tween(knob, {Position = UDim2.fromScale(ratio, .5)}, .08)
	end
	listen(hit.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliderDrag = {input = input, update = update}; update(input.Position.X)
		end
	end)
end
for i, name in ipairs(names) do
	local b = button(sidebar, string.format("%02d    %s", i, name), 22, 50 + (i - 1) * 49, 148, 42)
	b.TextXAlignment = Enum.TextXAlignment.Left
	make("UIPadding", {PaddingLeft = UDim.new(0, 12)}, b)
	tabs[i] = b
	local page = make("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false}, content)
	pages[i] = page
	label(page, "COLECCIÓN / " .. string.format("%02d", i), 26, 20, 380, 18, 10, C.mint, Enum.Font.Code)
	label(page, name, 26, 43, 570, 35, 28, C.text, Enum.Font.GothamBold)
	label(page, subtitles[i], 26, 83, 570, 22, 12, C.muted)
end
local general = pages[1]
section(general, "01   /   CONTROLES DE MUESTRA", 119)
toggle(card(general, 148, 66), "Modo enfoque", "Un interruptor; ninguna acción sobre el juego.", true)
slider(card(general, 224, 92), "Intensidad", "Ajuste de demostración · arrastra el indicador", 64)
local keyrow = card(general, 326, 66)
rowText(keyrow, "Atajo de muestra", "Selecciona una tecla · Escape cancela · no ejecuta acciones")
local key = button(keyrow, "RSHIFT", 467, 18, 97, 30)
local capturing = false
listen(key.Activated, function() capturing = not capturing; key.Text = capturing and "[ ... ]" or "RSHIFT" end)
local preview = button(general, "Probar interfaz   →", 26, 412, 192, 34, true)
listen(preview.Activated, function() notify("Todo listo. Esto es solo una maqueta interactiva.") end)
label(general, "NO HAY MÓDULOS CONECTADOS", 240, 419, 350, 20, 10, C.muted, Enum.Font.Code)
section(pages[2], "02   /   LENGUAJE VISUAL", 119)
toggle(card(pages[2], 148, 66), "Acentos suaves", "Estado visual independiente, sin cambiar el entorno.", true)
local dropCard = card(pages[2], 224, 66)
rowText(dropCard, "Paleta de muestra", "Explora nombres de una colección cromática.")
local drop = button(dropCard, "Helecho   +", 398, 18, 166, 30)
local dropdown = make("Frame", {Position = UDim2.fromOffset(424, 292), Size = UDim2.fromOffset(166, 0), BackgroundColor3 = C.panel, ClipsDescendants = true, Visible = false, ZIndex = 8}, pages[2]); round(dropdown, 8); stroke(dropdown)
local dropOpen = false
local function setDrop(open)
	dropOpen = open
	if open then dropdown.Visible = true end
	local t = tween(dropdown, {Size = UDim2.fromOffset(166, open and 114 or 0)}, .2)
	if not open and t then
		t.Completed:Once(function() if not dropOpen and not dead then dropdown.Visible = false end end)
	end
end
listen(drop.Activated, function() setDrop(not dropOpen) end)
for i, name in ipairs({"Helecho", "Ámbar", "Niebla"}) do
	local option = button(dropdown, name, 6, 6 + (i - 1) * 35, 154, 31)
	option.ZIndex = 9
	listen(option.Activated, function() drop.Text = name .. "   +"; setDrop(false); notify("Paleta seleccionada: " .. name .. " (muestra)") end)
end
slider(card(pages[2], 306, 92), "Densidad de muestra", "Un segundo control con estado visual propio.", 38)
section(pages[3], "03   /   BORRADOR LOCAL", 119)
local profile = card(pages[3], 148, 152)
rowText(profile, "Dale un nombre", "Campo editable; no se guarda en disco ni en la nube.")
local textbox = make("TextBox", {Position = UDim2.fromOffset(16, 76), Size = UDim2.fromOffset(552, 46),
	BackgroundColor3 = C.bg, Text = "", PlaceholderText = "Mi espacio de trabajo", PlaceholderColor3 = C.muted,
	TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Gotham, ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0}, profile)
round(textbox, 7)
local boxStroke = stroke(textbox)
make("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}, textbox)
listen(textbox.Focused, function() tween(boxStroke, {Color = C.mint}) end)
listen(textbox.FocusLost, function() tween(boxStroke, {Color = C.line}) end)
local save = button(pages[3], "Simular guardado   →", 26, 318, 200, 38, true)
listen(save.Activated, function() notify("Borrador «" .. (textbox.Text ~= "" and string.sub(textbox.Text, 1, 40) or "Sin título") .. "» · no se guardó ningún dato") end)
local note = card(pages[3], 376, 66)
rowText(note, "Efímero por diseño", "Los cambios desaparecen al cerrar o volver a ejecutar.")
section(pages[4], "04   /   MANIFIESTO", 119)
local about = card(pages[4], 148, 210)
label(about, "Menos ruido.\nMás intención.", 22, 22, 530, 80, 28, C.mint, Enum.Font.GothamBold)
local desc = label(about, "Grafito, helecho y un destello de ámbar.\nCada pieza se construye con instancias nativas.\nSin imágenes. Sin fuentes externas. Sin lógica de juego.", 22, 119, 540, 72, 12, C.muted)
desc.TextYAlignment = Enum.TextYAlignment.Top
label(pages[4], "BRUMA   /   VISUAL SYSTEM   /   2026", 26, 388, 570, 25, 12, C.amber, Enum.Font.Code)
local active, tabVersion = 0, 0
local function switch(index)
	if active == index or closing then return end
	tabVersion += 1
	local version = tabVersion
	local old = pages[active]
	active = index
	for i, b in ipairs(tabs) do
		b.TextColor3 = i == index and C.mint or C.muted
		tween(b, {BackgroundColor3 = i == index and C.hover or C.card})
	end
	tween(indicator, {Position = UDim2.fromOffset(12, 60 + (index - 1) * 49)}, .26)
	if old then tween(old, {GroupTransparency = 1}, .1) end
	task.delay(old and .1 or 0, function()
		if dead or version ~= tabVersion then return end
		for i, p in ipairs(pages) do p.Visible = i == index end
		local page = pages[index]
		page.GroupTransparency = 1; page.Position = UDim2.fromOffset(10, 0)
		tween(page, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, .25)
	end)
end
for i, b in ipairs(tabs) do
	listen(b.Activated, function() switch(i) end)
	listen(b.MouseLeave, function() tween(b, {BackgroundColor3 = active == i and C.hover or C.card}) end)
end
switch(1)
-- Shared mouse/touch handling, cleaned up when the GUI is destroyed.
local drag, minimized = nil, false
listen(header.InputBegan, function(input)
	if closing then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		drag = {input = input, start = input.Position, position = root.Position}
	end
end)
listen(UIS.InputChanged, function(input)
	local mouse = input.UserInputType == Enum.UserInputType.MouseMovement
	if sliderDrag and (mouse and sliderDrag.input.UserInputType == Enum.UserInputType.MouseButton1 or input == sliderDrag.input) then
		sliderDrag.update(input.Position.X)
	end
	if drag and (mouse and drag.input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.input) then
		local delta = input.Position - drag.start
		local view, s = stage.AbsoluteSize, fit.Scale
		local x = math.clamp(drag.position.X.Offset + delta.X, 60 * s, math.max(60 * s, view.X - 60 * s))
		local y = math.clamp(drag.position.Y.Offset + delta.Y, root.AbsoluteSize.Y / 2, math.max(root.AbsoluteSize.Y / 2, view.Y - 30 * s))
		root.Position = UDim2.fromOffset(x, y)
	end
end)
listen(UIS.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if drag and drag.input.UserInputType == Enum.UserInputType.MouseButton1 then drag = nil end
		if sliderDrag and sliderDrag.input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDrag = nil end
	end
	if drag and input == drag.input then drag = nil end
	if sliderDrag and input == sliderDrag.input then sliderDrag = nil end
end)
listen(UIS.InputBegan, function(input)
	if capturing and input.UserInputType == Enum.UserInputType.Keyboard and not UIS:GetFocusedTextBox() then
		capturing = false
		key.Text = input.KeyCode == Enum.KeyCode.Escape and "RSHIFT" or input.KeyCode.Name
		notify("Atajo decorativo: " .. key.Text .. " · sin acción asociada")
	end
end)
listen(minimize.Activated, function()
	if closing then return end
	minimized = not minimized
	minimize.Text = minimized and "+" or "–"
	body.Visible = not minimized; footer.Visible = not minimized
	tween(root, {Size = UDim2.fromOffset(820, minimized and 66 or 576)}, .28)
end)
listen(close.Activated, function()
	if closing then return end
	closing = true; drag = nil; sliderDrag = nil
	for _, s in ipairs(shadows) do tween(s, {BackgroundTransparency = 1}, .18) end
	tween(shell, {GroupTransparency = 1}, .22)
	tween(root, {Position = root.Position + UDim2.fromOffset(0, 16)}, .22)
	task.delay(.24, function() if not dead then gui:Destroy() end end)
end)
root.Position = root.Position + UDim2.fromOffset(0, 16)
tween(root, {Position = root.Position - UDim2.fromOffset(0, 16)}, .4)
tween(shell, {GroupTransparency = 0}, .4)

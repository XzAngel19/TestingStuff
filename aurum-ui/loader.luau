--[[
	=====================================================================
	A U R U M  ·  Loader
	=====================================================================
	Pega este archivo completo en tu ejecutor y dale Execute.

	Descarga AurumMenu.luau desde el repo, verifica que el contenido sea
	el correcto y lo ejecuta con loadstring. Prueba 3 fuentes por si
	alguna CDN está bloqueada en tu red.

	Requisitos del ejecutor: loadstring + game:HttpGet (cualquier executor
	moderno los tiene).
	=====================================================================
]]

local REPO = "XzAngel19/TestingStuff"
local REF = "arena/580a8767-testingstuff" -- rama (o un commit si prefieres fijarlo)
local PATH = "aurum-ui/AurumMenu.luau"

local SOURCES = {
	-- 1) raw de GitHub (lo normal)
	string.format("https://raw.githubusercontent.com/%s/%s/%s", REPO, REF, PATH),
	-- 2) misma raw vía github.com (funciona aunque raw.* esté bloqueado)
	string.format("https://github.com/%s/raw/refs/heads/%s/%s", REPO, REF, PATH),
	-- 3) jsDelivr (CDN alternativa)
	string.format("https://cdn.jsdelivr.net/gh/%s@%s/%s", REPO, REF, PATH),
}

local function hasExecutorApi()
	if type(loadstring) ~= "function" and type(load) ~= "function" then
		return false, "tu ejecutor no expone loadstring"
	end
	local ok = pcall(function()
		return game.HttpGet
	end)
	if not ok then
		return false, "tu ejecutor no expone game:HttpGet"
	end
	return true
end

local function fetch(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok then
		return nil, tostring(body)
	end
	if type(body) ~= "string" or #body < 1000 then
		return nil, "respuesta vacía o demasiado corta"
	end
	-- Firma del script: si no aparece, probablemente sea un HTML de error.
	if not string.find(body, "AURUM", 1, true) then
		return nil, "contenido inesperado (¿404 / página de error?)"
	end
	return body
end

local ready, reason = hasExecutorApi()
if not ready then
	warn("[AURUM] No puedo continuar: " .. reason)
	return
end

print("[AURUM] buscando build...")

local source = nil
for _, url in ipairs(SOURCES) do
	local body, err = fetch(url)
	if body then
		source = body
		print("[AURUM] descargado desde " .. url)
		break
	end
	warn("[AURUM] falló " .. url .. " → " .. tostring(err))
end

if not source then
	warn("[AURUM] No se pudo descargar el script desde ninguna fuente.")
	warn("[AURUM] Revisa tu conexión o ejecuta AurumMenu.luau pegado directamente.")
	return
end

local compile = loadstring or load
local chunk, compileError = compile(source, "AURUM")
if not chunk then
	warn("[AURUM] Error de compilación: " .. tostring(compileError))
	return
end

local ok, runError = pcall(chunk)
if not ok then
	warn("[AURUM] Error en ejecución: " .. tostring(runError))
	return
end

print("[AURUM] listo · RightShift para mostrar / ocultar")

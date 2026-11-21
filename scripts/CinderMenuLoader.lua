--[[
    CINDER · Loader
    Ejecuta el menú directamente desde GitHub (rama arena/106e7520-testingstuff).
    Pega este script en tu executor. No necesitas descargar nada.

    Requiere que tu executor tenga game:HttpGet (la gran mayoría lo trae).
]]

local URL = "https://raw.githubusercontent.com/XzAngel19/TestingStuff/arena/106e7520-testingstuff/scripts/CinderMenu.lua"

-- cache-buster: evita que el CDN de GitHub te sirva una copia vieja
local function fetch(url)
    local ok, body = pcall(function()
        return game:HttpGet(url .. "?nocache=" .. tostring(os.time()))
    end)
    if ok and type(body) == "string" and #body > 0 then
        return body
    end
    -- fallback: sin buster
    return game:HttpGet(url)
end

local source = fetch(URL)
if not source or #source < 100 then
    error("[CINDER] No se pudo descargar el script (¿HTTP bloqueado en tu executor?)")
end

local fn, loadErr = loadstring(source)
if not fn then
    error("[CINDER] Error al compilar: " .. tostring(loadErr))
end

local ok, runErr = pcall(fn)
if not ok then
    error("[CINDER] Error en ejecución: " .. tostring(runErr))
end

print("[CINDER] Menú cargado. INSERT para ocultar/restaurar.")

# AURUM · Interface Suite — build 1.0.4

Menú estilo *exploit* hecho **solo de GUI** (sin lógica de gameplay) en un único
LocalScript de Luau. Todo se construye con instancias y `Enum.Font`: cero
imágenes, íconos o fuentes por ID.

```
aurum-ui/
├── AurumMenu.luau   ← script único, listo para ejecutar
└── loader.luau      ← loader: lo descarga del repo y lo ejecuta
```

## Cómo ejecutarlo

### Opción A — con el loader (recomendado)

Pega el contenido de `loader.luau` en tu ejecutor y dale *Execute*. Descarga el
menú desde el repo, comprueba que el contenido sea el correcto y lo ejecuta.

Versión de una línea:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/XzAngel19/TestingStuff/arena/580a8767-testingstuff/aurum-ui/AurumMenu.luau"))()
```

### Opción B — pegado directo

1. Copia el contenido de `AurumMenu.luau`.
2. Pégalo en tu ejecutor y dale *Execute* (o pégalo en un `LocalScript` de
   `StarterPlayerScripts` para probarlo en Studio).

En ambos casos: **RightShift** muestra/oculta el menú. Requiere `loadstring` y
`game:HttpGet`, presentes en cualquier ejecutor moderno.

El `ScreenGui` se crea dentro de `gethui()`. Si no está disponible (Studio o un
entorno sin esa función), cae automáticamente a `CoreGui` y luego a `PlayerGui`.

## Identidad visual

| Token | Color | Uso |
|---|---|---|
| `void` | `#0A0B10` | fondo absoluto, pistas, tracks |
| `shell` | `#101219` | cuerpo del menú |
| `panel` | `#151821` | tarjetas, topbar, footer |
| `raised` | `#1E222E` | controles, chips, toggles |
| `gold` | `#F2B840` | acento primario |
| `ember` | `#FF7A4D` | acento secundario (degradados) |
| `mint` | `#5FE3B6` | éxito, estado, "SYNCED" |
| `ruby` | `#FF5C74` | destructivo / cerrar |

Tipografía: **GothamBlack / GothamBold / GothamMedium** para la UI y
**RobotoMono** para valores, versiones y la barra de estado. Si algún Enum no
existe en tu cliente, un helper (`pickFont`) cae a `SourceSansBold` / `Code`.

## Estructura

```
Shell (CanvasGroup 780×500, esquinas 14)
├── TopBar        logo de rombos, AURUM, chip v1.0.4, minimizar / cerrar
├── Sidebar       tarjeta de perfil, NAVIGATION, 5 tabs, tarjeta de keybind
├── Content       título, subtítulo, pill SYNCED, subrayado, páginas
│   └── Páginas   AIMBOT · VISUALS · PLAYER · WORLD · CONFIG
└── Footer        estado, gethui(), atajo, ecualizador animado, latencia
```

## Componentes

- `addToggle` — knob deslizante, relleno degradado, cambio de borde.
- `addSlider` — drag real (mouse/touch), fill degradado, glow, marcas de escala,
  chip de valor que se actualiza.
- `addDropdown` — selector con chevron dibujado (dos barras en un holder
  rotable), lista desplegable que crece animada y desplaza el resto.
- `addKeybind` — chip con estado "escuchando" (pulso visual).
- `addTextbox` — `TextBox` real con placeholder y borde que se enciende al foco.
- `addActions` — fila de botones *primary / ghost / danger* con squash & stretch.
- `addPalette` — chips de color con anillo de selección.
- `addPreset` — filas de perfiles con pill de acción.
- `addCard` / `addNote` — tarjetas de sección con auto-layout y notas.

## Animaciones (TweenService)

- Apertura/cierre: `GroupTransparency` + `UIScale` con easing `Back`, y el shell
  entra con un desplazamiento vertical leve.
- Cambio de tabs: cross-fade + slide de la página, indicador lateral deslizante,
  color/borde/glifo de la tab activa.
- Hover y click: botones con escala, topbar buttons, chips, filas, dropdown.
- Toggle: posición del knob y transparencia del relleno.
- Slider: knob/fill/glow y resize del knob al arrastrar.
- Minimizar: colapso de altura con `ClipsDescendants` (las sombras siguen el
  tamaño en `Heartbeat`), e ícono que muta de “—” a “+”.

## Detalles

- Sombras: 4 capas concéntricas con radios crecientes + dos glows de color
  (oro/brasa) sangrando desde las esquinas del shell.
- Todas las esquinas con `UICorner`, bordes con `UIStroke` (incluso sobre el
  propio `UIStroke` con `UIGradient`) y acentos con `UIGradient`.
- Sin `ImageLabel`, sin `rbxassetid`, sin `FontFace`, sin remotes ni hooks.

> Solo diseño: ningún control ejecuta acciones del juego. Las interacciones
> existen únicamente para que la GUI se sienta viva.

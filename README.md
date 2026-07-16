# GoofyzUI

A clean, fast, public-use Roblox GUI library for exploit scripts.  
Made by **goofyz** — v1.0.0

---

## Features

| Component | Description |
|-----------|-------------|
| `Window`  | Draggable, scalable main container with pulse dot |
| `Tab`     | Flat tab navigation with animated underline |
| `Section` | Labeled group divider with accent line |
| `Toggle`  | Animated capsule switch |
| `Slider`  | Smooth drag slider with editable textbox |
| `Button`  | Ripple-effect action button |
| `Input`   | Text field with focus highlight |
| `Keybind` | Key capture field |
| `Dropdown`| Searchable single or multi-select |
| `Label`   | Info/paragraph text row |

---

## Quick Start

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/AhmadlV99/slzr/refs/heads/main/Utils/GoofyzUI.lua"))()

local win = UI:Window({
    Title    = "My Script",
    SubTitle = "v1.0",
})

local tab = win:Tab({ Title = "Combat" })

tab:Section("Movement")

local flyToggle = tab:Toggle({
    Title    = "Fly",
    Desc     = "Enable fly mode",
    Value    = false,
    Callback = function(enabled)
        print("Fly:", enabled)
    end,
})

local speedSlider = tab:Slider({
    Title    = "Speed",
    Desc     = "Walk speed",
    Min      = 16,
    Max      = 500,
    Value    = 16,
    Rounding = 0,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
})
```

---

## API Reference

### `UI:Window(args)`

Creates the main window.

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `Title` | string | `"GoofyzUI"` | Window title |
| `SubTitle` | string | `"made by goofyz"` | Subtitle below title |

**Returns:** `Window` object

#### Window methods

```lua
win:Tab(args)          -- create a tab (see below)
win:SetTime("12:00")   -- set the top-right time text
win:SetScale(1.5)      -- adjust UI scale
win:Destroy()          -- remove the entire UI
```

---

### `win:Tab(args)`

Adds a tab to the window's tab bar.

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `Title` | string | `"Tab"` | Tab label |
| `Icon` | number/string | `nil` | Roblox asset ID (optional) |

**Returns:** `Tab` object

---

### `tab:Section(text)`

Inserts a labeled section divider.

```lua
tab:Section("Aimbot")
```

---

### `tab:Toggle(args)`

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `Title` | string | — | Row title |
| `Desc` | string | — | Row description |
| `Value` | boolean | `false` | Initial state |
| `Callback` | function | — | `function(bool)` |

```lua
local t = tab:Toggle({ Title = "Silent Aim", Callback = function(v) end })
t:Set(true)   -- set programmatically
t:Get()       -- returns current bool
t.Value = true  -- also works
```

---

### `tab:Slider(args)`

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `Title` | string | — | Row title |
| `Desc` | string | — | Row description |
| `Min` | number | `0` | Minimum value |
| `Max` | number | `100` | Maximum value |
| `Value` | number | `Min` | Initial value |
| `Rounding` | number | `0` | Decimal places |
| `Callback` | function | — | `function(number)` |

```lua
local s = tab:Slider({ Title = "FOV", Min = 1, Max = 360, Value = 90, Callback = function(v) end })
s:Set(120)
s:Get()  -- returns current number
```

---

### `tab:Button(args)`

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `Title` | string | — | Row title |
| `Desc` | string | — | Row description |
| `Text` | string | `"Execute"` | Button label |
| `Callback` | function | — | Called on click |

```lua
tab:Button({ Title = "Teleport", Text = "Go", Callback = function() end })
```

---

### `tab:Input(args)`

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `Title` | string | — | Row title |
| `Desc` | string | — | Row description |
| `Value` | string | `""` | Initial text |
| `Placeholder` | string | `"Enter text…"` | Placeholder |
| `Callback` | function | — | `function(string)` fired on Enter |

```lua
local inp = tab:Input({ Title = "Target", Callback = function(v) print(v) end })
inp:Get()     -- current text
inp:Set("hi") -- set text
```

---

### `tab:Keybind(args)`

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `Title` | string | — | Row title |
| `Value` | KeyCode | `Unknown` | Default key |
| `BindPressed` | function | — | `function(KeyCode)` fired when key is pressed |

```lua
local kb = tab:Keybind({
    Title       = "Toggle Fly",
    Value       = Enum.KeyCode.F,
    BindPressed = function(key) print("Pressed", key.Name) end,
})
kb:Get()              -- current KeyCode
kb:Set(Enum.KeyCode.G)
```

---

### `tab:Dropdown(args)`

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `Title` | string | — | Row title |
| `List` | table | `{}` | Array of option strings |
| `Value` | string/table | `nil` | Default selection. Use a **table** for multi-select |
| `Callback` | function | — | `function(value)` |

```lua
-- Single select
local dd = tab:Dropdown({
    Title    = "Weapon",
    List     = { "Pistol", "Rifle", "Knife" },
    Value    = "Pistol",
    Callback = function(v) print(v) end,
})

-- Multi select (pass table as Value)
local dd2 = tab:Dropdown({
    Title    = "Teams",
    List     = { "Red", "Blue", "Green" },
    Value    = {},   -- empty table = multi mode
    Callback = function(v) print(table.concat(v, ", ")) end,
})

dd:Get()                         -- returns current selection
dd:Set("Rifle")                  -- set programmatically
dd:Refresh({ "AK", "M4", "P90" }) -- replace list
```

---

### `tab:Label(args)`

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `Text` | string | `""` | Rich text supported |

```lua
local lbl = tab:Label({ Text = "Version: <b>1.0.0</b>" })
lbl:Set("Updated!")
```

---

## Keyboard Shortcut

Press **Left Ctrl** to toggle the window open/close.  
The floating pill button also toggles it.

---

## GitHub Setup

```
your-repo/
├── Utils/
│   └── GoofyzUI.lua      ← the library
├── README.md
└── example.lua           ← usage example
```

Paste the raw URL of `GoofyzUI.lua` into:
```lua
local UI = loadstring(game:HttpGet("RAW_URL"))()
```

---

## License

MIT — free to use, modify, and distribute. Credit appreciated but not required.

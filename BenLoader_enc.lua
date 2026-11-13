--====================================================
--  BEN LOADER - pick ONE script to launch
--  Nothing runs until you select it in the menu below and press
--  "Launch Selected Script". Only the chosen script's hooks/menu get
--  registered; the other ones never start. To switch to another
--  script later, press "< Return" in its window.
--
--  V9 UI: every menu (loader, Auto SB, Vend Helper, Auto Geiger, Auto Crystal,
--  Charger, Tax, Drop) shares the SAME design system below:
--  dark charcoal + orange accent, rounded cards, sidebar navigation,
--  orange ON/OFF toggles. Change the look in ONE place (the PALETTE).
--====================================================

-- CRASH-DEBUG SWITCHES (flip one at a time if the game crashes) ---------
-- NEW_LAYOUT = false  -> old single-window loader layout (same Nyxora colours)
-- HOVER_ANIM = false  -> no hover glow (skips ImGui.IsItemHovered)
-- ANIMATIONS = false  -> every animated value jumps straight to its target
local NEW_LAYOUT = true
local HOVER_ANIM = false
local ANIMATIONS = true
--------------------------------------------------------------------------

-- Set to false if your menu glitches: falls back to plain ImGui widgets.
local FANCY_UI = true
-- true = show the normal window title bar, false = custom header (logo + title + Return)
local SHOW_TITLEBAR = false
-- Overall size of every window / button / text. 1.0 = old size, 0.8 = smaller (default). Try 0.7 for even smaller.
local UI_SCALE = 0.92

---------------- PALETTE (NYXORA look: dark glass + white outline) ----------
local ACC        = { 0.200, 0.205, 0.235, 1 }    -- filled "selected" surfaces (dark slate)
local ACC_HOVER  = { 0.260, 0.265, 0.300, 1 }
local ACC_ACTIVE = { 0.150, 0.155, 0.180, 1 }
local LIGHT      = { 0.93, 0.93, 0.95, 1 }       -- white outline / check / slider grab
local TOG_ON     = { 0.80, 0.81, 0.85, 1 }       -- toggle ON (light pill)
local TOG_ON_HOV = { 0.88, 0.89, 0.92, 1 }
local BG         = { 0.050, 0.054, 0.062, 0.97 }
local PANEL      = { 0.085, 0.090, 0.102, 0.94 }
local FIELD      = { 0.125, 0.130, 0.148, 1.00 }
local FIELD_HOV  = { 0.175, 0.180, 0.200, 1.00 }
local LINE       = { 0.260, 0.270, 0.300, 0.55 }
local CLEAR      = { 0, 0, 0, 0 }

local C = {                                   -- text colours (r, g, b, a)
    accent = { 0.80, 0.81, 0.85, 1 },
    gold   = { 0.95, 0.95, 0.97, 1 },         -- light accent (highlights)
    green  = { 0.30, 0.85, 0.45, 1 },
    red    = { 0.95, 0.36, 0.36, 1 },
    cyan   = { 0.45, 0.80, 1.00, 1 },
    yellow = { 1.00, 0.80, 0.30, 1 },
    gray   = { 0.52, 0.52, 0.56, 1 },
    white  = { 0.93, 0.93, 0.94, 1 },
    purple = { 0.80, 0.81, 0.85, 1 },
}

-- Calls an optional ImGui function; silently does nothing if it doesn't exist.
-- Returns (ok, result) like pcall.
local function ui(name, ...)
    if not FANCY_UI then return false end
    local f = ImGui[name]
    if type(f) ~= "function" then return false end
    return pcall(f, ...)
end

-- Coloured text. Works out which TextColored signature your ImGui uses
-- the first time, then remembers it. Falls back to plain text.
local colorMode = nil
local function textColored(c, text)
    if not FANCY_UI then ImGui.Text(text) return end
    if colorMode == nil then
        colorMode = "none"
        if type(ImGui.TextColored) == "function" then
            if pcall(ImGui.TextColored, c[1], c[2], c[3], c[4], text) then
                colorMode = "rgba"
                return
            elseif type(ImVec4) == "function"
                and pcall(ImGui.TextColored, ImVec4(c[1], c[2], c[3], c[4]), text) then
                colorMode = "vec4"
                return
            end
        end
        ImGui.Text(text)
        return
    end
    if colorMode == "rgba" then
        ImGui.TextColored(c[1], c[2], c[3], c[4], text)
    elseif colorMode == "vec4" then
        ImGui.TextColored(ImVec4(c[1], c[2], c[3], c[4]), text)
    else
        ImGui.Text(text)
    end
end

---------------- THEME (dark + orange) ----------------
-- PushStyleColor / PushStyleVar wrappers. They work out which signature
-- your ImGui uses, and just do nothing if it isn't supported.
local styleMode = nil                         -- "rgba" | "vec4" | "none"

local THEME_COLORS = {
    { "WindowBg",          BG },
    { "ChildBg",           PANEL },
    { "PopupBg",           { 0.09, 0.09, 0.095, 0.98 } },
    { "Text",              C.white },
    { "TextDisabled",      C.gray },
    { "TitleBg",           { 0.06, 0.06, 0.065, 1.00 } },
    { "TitleBgActive",     { 0.06, 0.06, 0.065, 1.00 } },
    { "TitleBgCollapsed",  { 0.06, 0.06, 0.065, 1.00 } },
    { "Border",            LINE },
    { "BorderShadow",      CLEAR },
    { "Separator",         LINE },
    { "SeparatorHovered",  LIGHT },
    { "SeparatorActive",   LIGHT },
    { "Button",            FIELD },
    { "ButtonHovered",     FIELD_HOV },
    { "ButtonActive",      ACC_ACTIVE },
    { "FrameBg",           FIELD },
    { "FrameBgHovered",    FIELD_HOV },
    { "FrameBgActive",     { 0.23, 0.23, 0.24, 1.00 } },
    { "CheckMark",         LIGHT },
    { "SliderGrab",        LIGHT },
    { "SliderGrabActive",  { 1, 1, 1, 1 } },
    { "Header",            { 0.80, 0.82, 0.90, 0.14 } },
    { "HeaderHovered",     { 0.80, 0.82, 0.90, 0.24 } },
    { "HeaderActive",      { 0.80, 0.82, 0.90, 0.34 } },
    { "PlotHistogram",     TOG_ON },
    { "PlotHistogramHovered", TOG_ON_HOV },
    { "ScrollbarBg",       CLEAR },
    { "ScrollbarGrab",     { 0.26, 0.26, 0.28, 1.00 } },
    { "ScrollbarGrabHovered", { 0.36, 0.36, 0.38, 1.00 } },
    { "ScrollbarGrabActive",  LIGHT },
    { "TextSelectedBg",    { 0.80, 0.82, 0.90, 0.30 } },
    { "ResizeGrip",        { 0.80, 0.82, 0.90, 0.15 } },
    { "ResizeGripHovered", { 0.80, 0.82, 0.90, 0.40 } },
    { "ResizeGripActive",  LIGHT },
}
local THEME_VARS = {                           -- numbers or { x, y }
    { "WindowRounding",    16 },
    { "ChildRounding",     14 },
    { "PopupRounding",     10 },
    { "FrameRounding",     10 },
    { "GrabRounding",      10 },
    { "ScrollbarRounding", 8 },
    { "TabRounding",       7 },
    { "WindowBorderSize",  1 },
    { "ChildBorderSize",   1 },
    { "FrameBorderSize",   0 },
    { "ScrollbarSize",     10 },
    { "GrabMinSize",       12 },
    { "WindowPadding",     { 14, 12 } },
    { "FramePadding",      { 10, 6 } },
    { "ItemSpacing",       { 8, 8 } },
    { "ItemInnerSpacing",  { 6, 6 } },
}

for _, e in ipairs(THEME_VARS) do                 -- shrink padding / spacing / rounding with UI_SCALE
    if e[1] ~= "WindowBorderSize" and e[1] ~= "ChildBorderSize" and e[1] ~= "FrameBorderSize" then
        if type(e[2]) == "table" then e[2] = { e[2][1] * UI_SCALE, e[2][2] * UI_SCALE }
        else e[2] = e[2] * UI_SCALE end
    end
end

-- Pushes one colour using the given signature. Returns true if the call worked.
local function tryPush(mode, idx, c)
    if mode == "vec4" then
        if type(ImVec4) ~= "function" then return false end
        return (pcall(ImGui.PushStyleColor, idx, ImVec4(c[1], c[2], c[3], c[4])))
    elseif mode == "u32" then
        if type(ImVec4) ~= "function" or type(ImGui.ColorConvertFloat4ToU32) ~= "function" then
            return false
        end
        local ok, u = pcall(ImGui.ColorConvertFloat4ToU32, ImVec4(c[1], c[2], c[3], c[4]))
        if not ok or type(u) ~= "number" then return false end
        return (pcall(ImGui.PushStyleColor, idx, u))
    end
    -- "rgba": four loose numbers (only kept if the read-back proves it works)
    return (pcall(ImGui.PushStyleColor, idx, c[1], c[2], c[3], c[4]))
end

-- Reads the colour back after pushing it.
-- true = matches, false = wrong colour, nil = can't read it back.
local function verifyCol(idx, c)
    if type(ImGui.GetStyleColorVec4) ~= "function" then return nil end
    local res = { pcall(ImGui.GetStyleColorVec4, idx) }
    if not res[1] or res[2] == nil then return nil end
    local r, g, b, a
    if type(res[2]) == "number" then
        r, g, b, a = res[2], res[3], res[4], res[5]
    else
        local v = res[2]
        local ok = pcall(function() r, g, b, a = v.x, v.y, v.z, v.w end)
        if not ok then return nil end
    end
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return nil end
    return math.abs(r - c[1]) < 0.03 and math.abs(g - c[2]) < 0.03 and math.abs(b - c[3]) < 0.03
end

local function pushCol(name, c)               -- returns true if it was pushed
    if not FANCY_UI or type(ImGui.PushStyleColor) ~= "function" then return false end
    local idx = ImGui.Col and ImGui.Col[name]
    if idx == nil then return false end

    -- First call: find a signature that REALLY gives the right colour.
    if styleMode == nil then
        for _, m in ipairs({ "vec4", "u32", "rgba" }) do
            if tryPush(m, idx, c) then
                local v = verifyCol(idx, c)
                if v == true or (v == nil and m ~= "rgba") then
                    styleMode = m
                    return true
                end
                ui("PopStyleColor", 1)        -- wrong colour: undo and try the next one
            end
        end
        styleMode = "none"                    -- nothing worked: keep default look, no theme
        return false
    end

    if styleMode == "none" then return false end
    return tryPush(styleMode, idx, c)
end

local function pushVar(name, v)
    if not FANCY_UI or type(ImGui.PushStyleVar) ~= "function" then return false end
    local idx = ImGui.StyleVar and ImGui.StyleVar[name]
    if idx == nil then return false end
    if type(v) == "table" then                -- 2D value: ImVec2 first, loose x,y second
        if type(ImVec2) == "function" and pcall(ImGui.PushStyleVar, idx, ImVec2(v[1], v[2])) then
            return true
        end
        return (pcall(ImGui.PushStyleVar, idx, v[1], v[2]))
    end
    return (pcall(ImGui.PushStyleVar, idx, v))
end

---------------- ANIMATION HELPERS ----------------------
-- Smooth value follower (exponential ease). Works on wall-clock time so it
-- is frame-rate independent. speed ~ 10-18 feels snappy.
local ANIM, HOVER = {}, {}
local function lerp(a, b, t) return a + (b - a) * t end
local function mix(c1, c2, t)
    return { lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t), lerp(c1[3], c2[3], t), lerp(c1[4], c2[4], t) }
end
local function animTo(key, target, speed)
    if not ANIMATIONS then return target end
    local now = os.clock()
    local st = ANIM[key]
    if not st then ANIM[key] = { v = target, t = now } return target end
    local dt = math.min(0.05, math.max(0, now - st.t))
    st.t = now
    st.v = st.v + (target - st.v) * (1 - math.exp(-(speed or 12) * dt))
    if math.abs(target - st.v) < 0.002 then st.v = target end
    return st.v
end
local function hoverState(key) return HOVER[key] and 1 or 0 end
local function readHover(key)
    if not HOVER_ANIM then return end
    local ok, h = ui("IsItemHovered")
    HOVER[key] = ok and h == true
end
local function popVars(n) if n > 0 then ui("PopStyleVar", n) end end

-- Window fade-in: restarts whenever the menu was hidden for a moment or a
-- different window opens (loader -> script, minimize -> restore, ...).
local WIN_FADE = { t0 = os.clock(), last = 0, title = "" }
local FADE_TIME = 0.30
local function fadeAlpha()
    local now = os.clock()
    if now - WIN_FADE.last > 0.25 then WIN_FADE.t0 = now end    -- was hidden: replay
    WIN_FADE.last = now
    local p = math.min(1, (now - WIN_FADE.t0) / FADE_TIME)
    local e = 1 - (1 - p) * (1 - p) * (1 - p)                  -- ease-out cubic
    return 0.02 + 0.98 * e
end

local function pushTheme()
    local nc, nv = 0, 0

    for _, e in ipairs(THEME_COLORS) do if pushCol(e[1], e[2]) then nc = nc + 1 end end
    for _, e in ipairs(THEME_VARS)   do if pushVar(e[1], e[2]) then nv = nv + 1 end end
    return nc, nv
end

local function popTheme(nc, nv)
    if nc > 0 then ui("PopStyleColor", nc) end
    if nv > 0 then ui("PopStyleVar", nv) end
end

-- push a set of button colours (+ optional text colour); returns how many to pop
local function pushBtn(base, hover, active, textCol)
    local n = 0
    if base   and pushCol("Button", base)         then n = n + 1 end
    if hover  and pushCol("ButtonHovered", hover) then n = n + 1 end
    if active and pushCol("ButtonActive", active) then n = n + 1 end
    if textCol and pushCol("Text", textCol)       then n = n + 1 end
    return n
end
local function popCols(n) if n > 0 then ui("PopStyleColor", n) end end

---------------- UI WIDGETS --------------------------
-- Section header: small orange caps title with a line under it.
local function section(title)
    ui("Spacing")
    textColored(C.accent, string.upper(tostring(title)))
    ImGui.Separator()
    ui("Spacing")
end

-- plain button with optional size (w, h); falls back to a plain button.
local function rawButton(label, w, h)
    if FANCY_UI and w then
        if w > 0 then w = w * UI_SCALE end
        if h and h > 0 then h = h * UI_SCALE end
        local ok, r = pcall(ImGui.Button, label, w, h or 0)
        if ok then return r end
    end
    return ImGui.Button(label)
end

-- Button drawn with its own colour (normal / hovered / pressed).
local function colorButton(label, w, h, base, hover, active)
    local n = pushBtn(base, hover, active)
    local r = rawButton(label, w, h)
    popCols(n)
    return r
end

-- Button. Any label ending in ": ON" / ": OFF" is drawn as a TOGGLE:
-- orange when ON, dark + dim text when OFF. Everything else = normal button.
local function button(label, w, h)
    if FANCY_UI and type(label) == "string" then
        local isOn  = label:find(":%s*ON%s*$") ~= nil
        local isOff = (not isOn) and label:find(":%s*OFF%s*$") ~= nil
        if isOn or isOff then
            -- animated toggle: colour + outline ease between OFF and ON
            local key = "tg:" .. label:gsub(":%s*O[NF]+%s*$", "")
            local t  = animTo(key, isOn and 1 or 0, 13)
            local hv = animTo(key .. ":h", hoverState(key), 16)
            local base = mix(mix(FIELD, FIELD_HOV, hv), mix(TOG_ON, TOG_ON_HOV, hv), t)
            local txt  = mix(mix(C.gray, C.white, hv * 0.6), { 0.07, 0.07, 0.09, 1 }, t)
            local n = pushBtn(base, base, ACC_ACTIVE, txt)
            if pushCol("Border", { LIGHT[1], LIGHT[2], LIGHT[3], 0.55 * t }) then n = n + 1 end
            local nvar = pushVar("FrameBorderSize", t * 1.2) and 1 or 0
            local r = rawButton(label, w, h)
            readHover(key)
            popVars(nvar)
            popCols(n)
            return r
        end
    end
    return rawButton(label, w, h)
end

-- Button with a real size (ImVec2). Falls back to the normal button.
local function sizedButton(label, w, h)
    if FANCY_UI and type(ImVec2) == "function" then
        local sw = (w > 0) and w * UI_SCALE or w
        local sh = (h > 0) and h * UI_SCALE or h
        local ok, r = pcall(ImGui.Button, label, ImVec2(sw, sh))
        if ok then return r end
    end
    return rawButton(label, w, h)
end

-- Big full-width START (orange) / STOP (red) button.
local function bigButton(label, base, hover, active)
    local n = pushBtn(base or ACC, hover or ACC_HOVER, active or ACC_ACTIVE, { 1, 1, 1, 1 })
    if not base and pushCol("Border", { LIGHT[1], LIGHT[2], LIGHT[3], 0.7 }) then n = n + 1 end
    local nvar = (not base and pushVar("FrameBorderSize", 1.2)) and 1 or 0
    local r = sizedButton(label, -1, 40)
    popVars(nvar)
    popCols(n)
    return r
end

-- "Label            value" with the value in an aligned column.
local VAL_X = 150 * UI_SCALE                             -- minimum x of the value column
local valCol = VAL_X                                     -- grows to fit the widest label seen, so rows stay aligned
local function rowv(label, value, valueColor)
    textColored(C.gray, label)
    -- width of the label: measured if ImGui can do it, otherwise estimated from the character count
    -- (the estimate is always used as a minimum, so the value can never land on top of the label)
    local w = 0
    local okW, mw = ui("CalcTextSize", label)
    if okW then
        if type(mw) ~= "number" then
            local okx, x = pcall(function() return mw.x end)
            mw = okx and x or nil
        end
        if type(mw) == "number" then w = mw end
    end
    local est = #label * 7.6 * UI_SCALE / 0.8
    if est > w then w = est end
    local okc, cx = ui("GetCursorPosX")
    local need = (okc and type(cx) == "number" and cx or 0) + w + 14 * UI_SCALE
    if need > valCol then valCol = need end
    ui("SameLine", valCol)
    textColored(valueColor or C.white, value)
end

-- Real ImGui progress bar if available, text bar otherwise.
local function bar(frac, width)               -- [#########---------------]
    width = width or 24
    frac = math.max(0, math.min(1, frac))
    local filled = math.floor(frac * width + 0.5)
    return "[" .. string.rep("#", filled) .. string.rep("-", width - filled) .. "]"
end

local function progressBar(frac)
    if FANCY_UI and type(ImGui.ProgressBar) == "function" then
        -- " " as overlay = no text inside the bar
        if type(ImVec2) == "function"
            and pcall(ImGui.ProgressBar, frac, ImVec2(-1, 14), " ") then return end
        if pcall(ImGui.ProgressBar, frac, -1, " ") then return end
        if pcall(ImGui.ProgressBar, frac) then return end
    end
    textColored(C.accent, bar(frac, 28))
end

---------------- WINDOW + HEADER + SIDEBAR -------------
-- ACTIVE.stop is set by the launched script (stops its loops/threads).
-- The Return button only raises a flag; the loader's own draw hook does the
-- clean-up (stop script, disable + remove its hooks, show the loader again).
local ACTIVE = { stop = nil, returnReq = false }
local CUR_TITLE = ""
local beginMode = nil                         -- "flags" | "plain"

-- Opens the window. Custom look = no title bar (header is drawn by drawHeader).
-- Always finish with ImGui.End().
local WIN_W, WIN_H = 780, 490                    -- default size of the loader and every script window (resizable)
local MIN_W, MIN_H = 430, 300                   -- window can't be resized smaller than this (tiny windows crashed ImGui)
local FONT_SET = false
local function beginWindow(title, w, h, minW, minH, mini)
    CUR_TITLE = title
    if WIN_FADE.title ~= title then WIN_FADE.title = title; WIN_FADE.t0 = os.clock() end
    minW, minH = (minW or MIN_W) * UI_SCALE, (minH or MIN_H) * UI_SCALE
    if mini then
        ui("SetNextWindowSize", (w or 560) * UI_SCALE, (h or 0) * UI_SCALE, 4)
    else
        ui("SetNextWindowSize", WIN_W * UI_SCALE, WIN_H * UI_SCALE, 4)          -- default size; you can resize
    end
    if FANCY_UI and type(ImVec2) == "function" then
        local done = pcall(ImGui.SetNextWindowSizeConstraints, ImVec2(minW, minH), ImVec2(4000, 4000))
        if not done then pcall(ImGui.SetNextWindowSizeConstraints, minW, minH, 4000, 4000) end
    end
    if FANCY_UI and not SHOW_TITLEBAR and beginMode ~= "plain" then
        -- 33 = NoTitleBar (1) + NoCollapse (32)
        -- mini bars: also AlwaysAutoResize (64) + NoScrollbar (8) + NoScrollWithMouse (16)
        if pcall(ImGui.Begin, title, true, mini and 121 or 33) then
            beginMode = "flags"
            ui("SetWindowFontScale", UI_SCALE)
            return
        end
        beginMode = "plain"
    end
    ImGui.Begin(title)
    ui("SetWindowFontScale", UI_SCALE)
end

-- Animated rainbow text with a moving white "shine" sweeping across it.
local function hsv(h, sat, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t = v * (1 - sat), v * (1 - f * sat), v * (1 - (1 - f) * sat)
    i = i % 6
    if i == 0 then return v, t, p elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v else return v, p, q end
end
local function shinyText(text, scale)
    -- soft white shimmer that sweeps across the title (monochrome, NYXORA style)
    local t = os.clock()
    local n = #text
    local shinePos = (t * 7) % (n + 10) - 5
    ui("SetWindowFontScale", (scale or 1.0) * UI_SCALE)
    for i = 1, n do
        local ch = text:sub(i, i)
        local k = math.max(0, 1 - math.abs(i - shinePos) / 3.0)
        local v = 0.74 + 0.26 * k
        textColored({ v, v, v + 0.02 * k, 1 }, ch)
        if i < n then ui("SameLine", 0, 0) end
    end
    ui("SetWindowFontScale", UI_SCALE)
end

-- Logo tile + title on the left, "< Return" on the right.
local MINIMIZE_REQ = false
local SCRIPT_MIN_REQ = false                    -- set by the "_" button in a launched script window
local function drawHeader(title, withReturn, withMin)
    local ww = 0
    local okw, w = pcall(ImGui.GetWindowWidth)
    if okw and type(w) == "number" then ww = w end
    local _, y = ui("GetCursorPosY")

    local n = pushBtn(ACC, ACC, ACC, { 1, 1, 1, 1 })
    if pushCol("Border", { LIGHT[1], LIGHT[2], LIGHT[3], 0.45 + 0.25 * math.sin(os.clock() * 2) }) then n = n + 1 end
    local nvar = pushVar("FrameBorderSize", 1.2) and 1 or 0
    sizedButton(" B ", 34, 34)                         -- logo tile (not clickable, border gently pulses)
    popVars(nvar)
    popCols(n)

    ui("SameLine")
    if title == "Ben Loader" then
        if type(y) == "number" then ui("SetCursorPosY", y + 2) end
        shinyText(title, 1.45)
    else
        if type(y) == "number" then ui("SetCursorPosY", y + 8) end
        textColored(C.white, title)
    end

    if withReturn then
        ui("SameLine", math.max(160 * UI_SCALE, ww - 160 * UI_SCALE))
        if type(y) == "number" then ui("SetCursorPosY", y + 2) end
        if sizedButton("<  Return", 96, 30) then ACTIVE.returnReq = true end
        -- minimize button for the launched script's window
        ui("SameLine", math.max(160 * UI_SCALE, ww - 52 * UI_SCALE))
        if type(y) == "number" then ui("SetCursorPosY", y + 2) end
        if sizedButton(" _ ", 34, 30) then SCRIPT_MIN_REQ = true end
    end
    if withMin then
        ui("SameLine", math.max(160 * UI_SCALE, ww - 52 * UI_SCALE))
        if type(y) == "number" then ui("SetCursorPosY", y + 2) end
        if sizedButton(" _ ", 34, 30) then MINIMIZE_REQ = true end
    end
    ui("Spacing")
    ImGui.Separator()
    ui("Spacing")
end

local function returnButton()                  -- kept name: every module calls this right after Begin
    drawHeader(CUR_TITLE, true)
end

-- Sidebar nav item: transparent, glows on hover, and gets an animated white
-- outline + filled slate background when selected.
local function navItem(label, active, w, h)
    local key = "nav:" .. tostring(label)
    local a  = animTo(key .. ":a", active and 1 or 0, 14)
    local hv = animTo(key .. ":h", hoverState(key), 16)
    local bg = mix(mix(CLEAR, { FIELD_HOV[1], FIELD_HOV[2], FIELD_HOV[3], 0.65 }, hv), ACC, a)
    local txt = mix(C.gray, C.white, math.max(a, hv * 0.75))
    local n = pushBtn(bg, bg, ACC_ACTIVE, txt)
    if pushCol("Border", { LIGHT[1], LIGHT[2], LIGHT[3], 0.9 * a }) then n = n + 1 end
    local nvar = pushVar("FrameBorderSize", a * 1.4) and 1 or 0
    local r = sizedButton(label, w or -1, h or 30)
    readHover(key)
    popVars(nvar)
    popCols(n)
    return r
end

local NAV_W = 104
local NAV = { contentOpen = false }

local function beginChild(id, w, h, border)
    if not FANCY_UI or type(ImVec2) ~= "function" or type(ImGui.BeginChild) ~= "function" then
        return false
    end
    if w > 0 then w = w * UI_SCALE end
    if h > 0 then h = h * UI_SCALE end
    return (pcall(ImGui.BeginChild, id, ImVec2(w, h), border and true or false))
end

-- Sidebar (left) + content card (right). Returns the selected tab index.
-- After drawing the tab content call navEnd().
local function navBegin(names, cur)
    if beginChild("##nav", NAV_W, 0, false) then
        for i, name in ipairs(names) do
            if navItem(name, cur == i) then cur = i end
        end
        ui("EndChild")
        ui("SameLine")
        NAV.contentOpen = beginChild("##content", 0, 0, true)
    else
        -- no child windows in this ImGui: plain row of buttons on top
        for i, name in ipairs(names) do
            if i > 1 then ui("SameLine") end
            if navItem(name, cur == i, 0, 30) then cur = i end
        end
        ImGui.Separator()
        ui("Spacing")
    end
    return cur
end

local function navEnd()                        -- safe to call any time, only closes what is open
    if NAV.contentOpen then
        NAV.contentOpen = false
        ui("EndChild")
    end
end

local function startAutoSB()
--====================================================
--  AUTO SUPER BROADCAST v4  (/sb <text> <tag>) + ImGui menu
--  - auto warp to target world before every SB
--  - report is said in WORLD CHAT (3 lines, anti-spam gap)
--  - gems counted in main gems (1 Black Gem = 900 gems)
--  - save / load config
--  (new dark UI layout, all original features kept)
--====================================================

-- Set to false if your menu glitches: falls back to plain ImGui widgets.

---------------- SETTINGS (defaults) -----------------
local cfg = {
    text        = "Selling items! Visit my world!",
    tag         = "#PoliceSB",   -- added behind every SB text
    targetWorld = "",            -- world to SB from (empty = SB wherever you are, no warping)
    endWorld    = "",            -- world to warp to after ALL SB are done (empty = stay)
    total       = 100,           -- how many SB to send
    delay       = 180,           -- seconds between each SB (180 = 3 minutes)
    bgRate      = 900,           -- 1 Black Gem = 900 main gems
    confirmWait = 45,            -- seconds to wait for "Super-Broadcast sent"
    maxFails    = 3,             -- stop after this many failed attempts in a row
    warpRetry   = 15,            -- seconds to wait for a warp before trying again
    settle      = 3,             -- seconds to wait after arriving before sending SB
    worldReport = true,          -- report goes to world chat (everyone sees it)
    growmoji    = false,         -- add a random growmoji behind the SB text
    webhookUrl     = "",         -- Discord webhook URL (Server Settings > Integrations > Webhooks)
    webhookEnabled = false,      -- ping it after every confirmed SB
    accountName    = "",         -- name shown in the log (empty = auto-detect from game)
    discordId      = "",         -- your Discord user ID, shown as a @mention in the log (empty = none)
    chatGapMs   = 3000,          -- milliseconds between each chat line (anti-spam)
    debug       = false,         -- print every console line the script sees
}

---------------- CONFIG FILE -------------------------
-- Tries these paths in order (first one that works is remembered).
local CONFIG_PATHS = {
    "autosb_config.txt",
    "scripts/autosb_config.txt",
    "/sdcard/autosb_config.txt",
}
-- Only these settings are saved/loaded.
local SAVE_KEYS = { "text", "tag", "targetWorld", "endWorld", "total", "delay", "bgRate", "worldReport",
                    "growmoji", "webhookUrl", "webhookEnabled", "accountName", "discordId" }
local SAVE_SET = {}
for _, k in ipairs(SAVE_KEYS) do SAVE_SET[k] = true end

---------------- STATE -------------------------------
local S = {
    running   = false,
    done      = 0,
    gemsUsed  = 0,       -- TOTAL in main gems (black gems already converted)
    blackUsed = 0,
    mainUsed  = 0,
    gemsLeft  = nil,
    leftCur   = "",
    nextSend  = 0,
    waiting   = false,   -- SB sent, waiting for confirmation
    sentAt    = 0,
    fails     = 0,
    reportAt  = nil,
    warpSentAt = nil,    -- time the last /warp was sent
    warpTries = 0,
    arrivedAt = nil,     -- time we were first seen inside the target world
    warnedWorld = false,
    finishWarp = false,  -- all SB done: warp to endWorld once the report has been said
    chatQueue = {},      -- report lines waiting to be said in world chat
    chatLastTime  = nil, -- os.time() when the last chat line was sent
    chatLastClock = 0,   -- os.clock() when the last chat line was sent
    cfgPath   = nil,     -- config path that worked
    captureArmed = false, -- true while waiting for the next sign-edit dialog
    uiMsg     = nil,     -- small feedback text under the buttons
    uiOk      = true,
    uiUntil   = 0,
    last      = "-",     -- last event: sent / cooldown / no confirm
}

---------------- API WRAPPERS (edit if needed) -------
local function say(msg)                       -- local console only
    LogToConsole(msg)
end

local function sendText(text)                 -- public world chat / commands
    SendPacket(2, "action|input\n|text|" .. text)
end

local function getWorldName()                 -- current world, nil if unknown
    local ok, v = pcall(function() return GetWorld().name end)
    if ok and type(v) == "string" and v ~= "" then return v end
    ok, v = pcall(function() return GetWorldName() end)
    if ok and type(v) == "string" and v ~= "" then return v end
    return nil
end

---------------- HELPERS -----------------------------
local function strip(s)                       -- remove colour codes (`2, `w, ``)
    return (s:gsub("`%S", ""))
end

local function toNum(s)
    return tonumber((tostring(s):gsub(",", "")))
end

local function comma(n)                       -- 1234567 -> 1,234,567
    local r = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (r:gsub("^,", ""))
end

local function fmtGems(n)                     -- 1390000 -> "1.39m", below 1m -> "950,000"
    if n >= 1000000 then
        local m = math.floor(n / 10000) / 100             -- 2 decimals, rounded down
        local s = string.format("%.2f", m):gsub("0+$", ""):gsub("%.$", "")
        return s .. "m"
    end
    return comma(n)
end

local function trim(s)                        -- remove spaces at both ends
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function norm(s)                        -- world names: no spaces, uppercase
    return (tostring(s or ""):gsub("%s", ""):upper())
end

---------------- DISCORD WEBHOOK ----------------------
-- Uses io.popen + curl (same approach confirmed working for the license
-- server) to POST an embed to a Discord webhook URL. Fire-and-forget: a
-- failed/slow webhook never blocks or breaks the SB loop.
local function jsonEscape(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", ""):gsub("\t", "\\t")
    return s
end

local function sendWebhook(title, fields, color, footer)
    if not cfg.webhookEnabled then
        if cfg.debug then say("`8[Webhook] `wskipped: webhook is OFF") end
        return
    end
    local url = trim(cfg.webhookUrl)
    if url == "" then
        if cfg.debug then say("`8[Webhook] `wskipped: no URL set") end
        return
    end

    local fieldsJson = {}
    for _, f in ipairs(fields) do
        fieldsJson[#fieldsJson + 1] = '{"name":"' .. jsonEscape(f[1]) .. '","value":"'
            .. jsonEscape(f[2]) .. '","inline":' .. (f[3] and "true" or "false") .. '}'
    end

    local json = '{"embeds":[{"title":"' .. jsonEscape(title) .. '","color":' .. tostring(color or 3066993)
        .. ',"fields":[' .. table.concat(fieldsJson, ",")
        .. ']' .. (footer and (',"footer":{"text":"' .. jsonEscape(footer) .. '"}') or "") .. '}]}'

    -- Write the JSON to a file and let curl read it with -d @file instead of
    -- putting it on the command line - quotes/backslashes in the message
    -- (e.g. from a captured sign) would otherwise be mangled by cmd's own
    -- quoting rules. Tested and confirmed this avoids that entirely.
    local tmpPath = "autosb_webhook_payload.json"
    local wf = io.open(tmpPath, "w")
    if not wf then
        say("`4[Webhook] `wcould not write " .. tmpPath .. " (folder not writable?)")
        return
    end
    wf:write(json)
    wf:close()

    -- NON-BLOCKING: "start /B" launches curl in the background and cmd returns
    -- at once, so the game never waits for the network (this removed the ~1s
    -- freeze). curl writes the HTTP status line to a header file and we check
    -- it a few seconds later in tick().
    local hdrPath, bodyPath = "autosb_webhook_hdr.txt", "autosb_webhook_resp.txt"
    pcall(os.remove, hdrPath)
    pcall(os.remove, bodyPath)
    local cmd = 'start "" /B curl -s -m 15 -D "' .. hdrPath .. '" -o "' .. bodyPath
        .. '" -X POST -H "Content-Type: application/json" -d "@' .. tmpPath .. '" "' .. url .. '"'
    if cfg.debug then say("`8[Webhook] `wrunning: " .. cmd) end
    local ok, handle = pcall(io.popen, cmd)
    if not ok or not handle then
        say("`4[Webhook] `wio.popen/curl failed to start")
        return
    end
    pcall(function() handle:close() end)      -- returns immediately (start /B)
    S.webhookCheckAt = os.time() + 6
end

-- Called from tick(): reads the result of the last background webhook.
local function checkWebhookResult()
    if not S.webhookCheckAt or os.time() < S.webhookCheckAt then return end
    S.webhookCheckAt = nil
    local hdr, body = "", ""
    local f = io.open("autosb_webhook_hdr.txt", "r")
    if f then hdr = f:read("*a") or "" f:close() end
    local ok2 = hdr:match("^HTTP/%S+%s+2%d%d")
    if ok2 then
        if cfg.debug then say("`2[Webhook] `wsent OK") end
        return
    end
    local g = io.open("autosb_webhook_resp.txt", "r")
    if g then body = g:read("*a") or "" g:close() end
    say("`4[Webhook] `wfailed: `9" .. (hdr ~= "" and hdr:match("^[^\r\n]+") or "no response (still sending / no internet?)")
        .. (body ~= "" and (" " .. body:sub(1, 120)) or ""))
end

-- Growmojis used by the "random growmoji" option. One is picked per SB.
-- STARTER LIST - add / remove names here (write them without the brackets).
local GROWMOJIS = {
    "fireworks", "wl", "lol", "cry", "wow", "kiss", "heart", "love", "sleep",
    "yes", "no", "oops", "shy", "wink", "tongue", "agree", "grin", "cool",
    "mad", "smile", "evil", "troll", "party",
}

local curEmoji = nil
local function pickEmoji()                    -- new random growmoji (never the same twice in a row)
    local n = #GROWMOJIS
    if n == 0 then curEmoji = nil return end
    local e = GROWMOJIS[math.random(n)]
    local tries = 0
    while n > 1 and e == curEmoji and tries < 10 do
        e = GROWMOJIS[math.random(n)]
        tries = tries + 1
    end
    curEmoji = e
end

local function buildSB()                      -- SB text (+ growmoji) + tag behind it
    local t = cfg.text
    if cfg.tag ~= "" then t = t .. " " .. cfg.tag end
    if cfg.growmoji and curEmoji then t = t .. " (" .. curEmoji .. ")" end   -- behind the tag
    return t
end

local function fmtMins(mins)                  -- 294 -> "4h 54m", 45 -> "45m"
    if mins < 60 then return mins .. "m" end
    return math.floor(mins / 60) .. "h " .. (mins % 60) .. "m"
end

local function fmtK(n)                        -- 212 -> "0.2K", 1500 -> "1.5K", below 100 -> "40"
    if n < 100 then return tostring(math.floor(n)) end
    return string.format("%.1fK", n / 1000)
end

---------------- CONFIG SAVE / LOAD ------------------
local function setMsg(text, ok)
    S.uiMsg, S.uiOk, S.uiUntil = text, ok, os.time() + 5
end

local function saveConfig(silent)
    local lines = {}
    for _, k in ipairs(SAVE_KEYS) do
        local v = cfg[k]
        if type(v) == "boolean" then v = v and "true" or "false" end
        lines[#lines + 1] = k .. "=" .. tostring(v)
    end
    local data = table.concat(lines, "\n") .. "\n"

    local order = {}
    if S.cfgPath then order[1] = S.cfgPath end
    for _, p in ipairs(CONFIG_PATHS) do order[#order + 1] = p end

    for _, p in ipairs(order) do
        local ok, f = pcall(io.open, p, "w")
        if ok and f then
            local wok = pcall(function() f:write(data) f:close() end)
            if wok then
                S.cfgPath = p
                if not silent then setMsg("Config saved (" .. p .. ")", true) end
                return true
            end
        end
    end
    if not silent then setMsg("Could not save config (no writable path)", false) end
    return false
end

local function loadConfig(silent)
    for _, p in ipairs(CONFIG_PATHS) do
        local ok, f = pcall(io.open, p, "r")
        if ok and f then
            local rok, data = pcall(function() local d = f:read("*a") f:close() return d end)
            if rok and data and data ~= "" then
                for line in data:gmatch("[^\r\n]+") do
                    local k, v = line:match("^(%w+)=(.*)$")
                    if k and SAVE_SET[k] and cfg[k] ~= nil then
                        if type(cfg[k]) == "boolean" then cfg[k] = (v == "true")
                        elseif type(cfg[k]) == "number" then cfg[k] = tonumber(v) or cfg[k]
                        else cfg[k] = v end
                    end
                end
                cfg.total  = math.max(1, cfg.total)
                cfg.delay  = math.max(1, cfg.delay)
                cfg.bgRate = math.max(1, cfg.bgRate)
                S.cfgPath = p
                if not silent then setMsg("Config loaded", true) end
                return true
            end
        end
    end
    if not silent then setMsg("No saved config found", false) end
    return false
end

---------------- SB LOG EMBED (Discord) --------------
local WL_ID, DL_ID = 242, 1796                -- World Lock / Diamond Lock item IDs

-- Item count from the inventory. Tries GetItemCount first, then GetInventory.
-- Returns nil if your executor has neither (the log then shows "-").
local function itemCount(id)
    local ok, n = pcall(function() return GetItemCount(id) end)
    if ok and type(n) == "number" then return n end
    ok, n = pcall(function()
        for _, it in pairs(GetInventory()) do
            if it.id == id then return it.amount or it.count or 0 end
        end
        return 0
    end)
    if ok and type(n) == "number" then return n end
    return nil
end

local function getAccountName()
    local n = trim(cfg.accountName)
    if n ~= "" then return n end
    local ok, v = pcall(function() return GetLocal().name end)
    if ok and type(v) == "string" and v ~= "" then return strip(v) end
    return "Unknown"
end

local function fmtShort(n)                    -- 3000000 -> "3.0M", 111200 -> "111.2k"
    if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
    if n >= 1000    then return string.format("%.1fk", n / 1000) end
    return tostring(math.floor(n))
end

local function fmtLong(secs)                  -- 4804 -> "80 minutes and 4 seconds"
    secs = math.max(0, math.floor(secs))
    local m, s = math.floor(secs / 60), secs % 60
    return m .. " minute" .. (m == 1 and "" or "s") .. " and " .. s .. " second" .. (s == 1 and "" or "s")
end

local function secsLeft()                     -- real time until the last SB is done
    local remaining = math.max(0, cfg.total - S.done)
    if remaining == 0 then return 0 end
    return math.max(0, S.nextSend - os.time()) + (remaining - 1) * cfg.delay
end

local function sendLogEmbed()
    local tag   = strip(cfg.tag):upper()
    local title = "SB LOGS" .. (tag ~= "" and (" " .. tag) or "")

    local account = getAccountName()
    if trim(cfg.discordId) ~= "" then account = account .. "\n<@" .. trim(cfg.discordId) .. ">" end

    local world = trim(cfg.targetWorld) ~= "" and cfg.targetWorld or (getWorldName() or "UNKNOWN")

    local dl, wl = itemCount(DL_ID), itemCount(WL_ID)
    local locks = (dl and wl) and (dl .. " DL " .. wl .. " WL") or "-"

    local left = "-"
    if S.gemsLeft then
        left = fmtShort(S.gemsLeft)
        if not S.leftCur:lower():find("black", 1, true) then left = left .. " " .. S.leftCur end
        left = left .. " (left)"
    end

    -- keep the raw colour codes (`2, `8 ...) exactly like they are sent in-game
    local text = cfg.text:gsub("```", "`\226\128\139``")

    sendWebhook(title, {
        { "Account",           account,                          true  },
        { "Total Gems Used",   fmtShort(S.gemsUsed) .. " Gems",  true  },
        { "World",             world:upper(),                    true  },
        { "Broadcast Sending", S.done .. " / " .. cfg.total,     true  },
        { "Total Lock",        locks,                            true  },
        { "Black Gems",        left,                             true  },
        { "Text Broadcast",    "```" .. text .. "```",           false },
        { "SB Time Left",      fmtLong(secsLeft()),              false },
    }, 2829617)                               -- 2829617 = dark grey, same as Discord's dark theme
end

---------------- REPORT (world chat only) ------------
-- Report look (3 lines, one chat message each).
-- If an icon doesn't show in-game, change the growmoji names here.
local REPORT_TAG   = "`b[`2Police`4SB`B]"
local ICON_fireworks  = "(fireworks)"
local ICON_MEGA    = "(megaphone)"

local function report()
    sendLogEmbed()                            -- Discord log (works even if world chat report is OFF)
    if not cfg.worldReport then return end

    local remaining = cfg.total - S.done
    local mins = math.ceil(remaining * cfg.delay / 60)
    local bgUsed = S.gemsUsed / math.max(1, cfg.bgRate)      -- gems used, shown in Black Gems

    -- One line per message (a "|" in chat text would cut the message off).
    local q = S.chatQueue
    q[#q + 1] = REPORT_TAG .. " `1Sending " .. ICON_fireworks .. " `&Super Boardcast"
    q[#q + 1] = REPORT_TAG .. " " .. ICON_MEGA .. " `3SuperBoardcast: `w[`2" .. S.done
                .. "/" .. cfg.total .. "`w]"
    q[#q + 1] = REPORT_TAG .. " `3Using `9" .. fmtK(bgUsed) .. " `7BGems `b"
                .. fmtMins(mins) .. " `4left"
end

local function stop(reason)
    S.running, S.waiting, S.reportAt = false, false, nil
    S.warpSentAt, S.arrivedAt = nil, nil
    S.finishWarp = false
    say("`4[Auto SB] Stopped: `w" .. reason)
end

local function start()
    if cfg.text == "" then say("`4[Auto SB] Please enter a broadcast text first.") return end
    saveConfig(true)                          -- remember the settings you started with

    -- RESUME: if a run was stopped part-way (some SB done, not finished yet),
    -- keep done / gems / black gems and the SB timer. Only a finished run or a
    -- fresh start (nothing done) begins from zero.
    local resuming = S.done > 0 and S.done < cfg.total

    S.running, S.waiting, S.reportAt = true, false, nil
    S.finishWarp = false
    S.fails = 0
    S.warpSentAt, S.arrivedAt, S.warpTries = nil, nil, 0
    if resuming then
        -- S.nextSend is an absolute time, so the cooldown keeps counting while
        -- stopped; if it already passed, the next SB goes out right away.
        say("`2[Auto SB] Resumed at " .. S.done .. "/" .. cfg.total .. " SB, delay " .. cfg.delay .. "s")
    else
        S.done, S.gemsUsed = 0, 0
        S.blackUsed, S.mainUsed = 0, 0
        S.last = "-"
        S.nextSend = os.time()                -- first SB goes out immediately
        say("`2[Auto SB] Started: " .. cfg.total .. " SB, delay " .. cfg.delay .. "s")
    end
    if cfg.targetWorld ~= "" then
        say("`2[Auto SB] Target world: `9" .. cfg.targetWorld)
    end
end

---------------- TARGET WORLD / WARP -----------------
-- Returns true when we are in the right world and it is safe to send the SB.
local function readyToSend(now)
    local target = norm(cfg.targetWorld)
    if target == "" then return true end      -- no target set: SB anywhere

    local cur = getWorldName()

    -- Can't read the world name: warp first, wait a bit, then send.
    if cur == nil then
        if not S.warnedWorld then
            S.warnedWorld = true
            say("`4[Auto SB] `wCan't read current world name, warping before every SB instead.")
        end
        if not S.warpSentAt then
            -- The World Select Menu is a native UI screen, not the chat
            -- box, so /warp as chat text may not even reach the game.
            -- Send BOTH the chat command and the raw join_request packet
            -- (the protocol-level action a direct "Enter World" sends) so
            -- whichever channel the game is actually listening on works.
            pcall(SendPacket, 3, "action|join_request\nname|" .. cfg.targetWorld .. "\ninvitedWorld|0\n")
            sendText("/warp " .. cfg.targetWorld)
            S.warpSentAt = now
            return false
        end
        if now - S.warpSentAt >= cfg.warpRetry then
            S.warpSentAt = nil
            return true
        end
        return false
    end

    -- Already in the target world
    if norm(cur) == target then
        S.warpSentAt, S.warpTries = nil, 0
        if not S.arrivedAt then S.arrivedAt = now end
        return now - S.arrivedAt >= cfg.settle
    end

    -- Somewhere else: warp to the target world
    S.arrivedAt = nil
    if not S.warpSentAt or now - S.warpSentAt >= cfg.warpRetry then
        if S.warpTries >= cfg.maxFails then
            stop("could not reach world " .. cfg.targetWorld .. ".")
            return false
        end
        S.warpTries = S.warpTries + 1
        S.warpSentAt = now
        say("`2[Auto SB] `wWarping to `9" .. cfg.targetWorld .. " `w(from " .. cur .. ")")
        sendText("/warp " .. cfg.targetWorld)
    end
    return false
end

---------------- CONSOLE HOOK ------------------------
-- Messages this reads:
--   >> Super-Broadcast sent. Used 212 Black Gems. (285419 left)
--   >> (2 mins, 35 secs before you can broadcast again)
---------------- SIGN TEXT CAPTURE -------------------
-- Fires on the sign-edit dialog (confirmed with check_sign.lua: var[0] ==
-- "OnDialogRequest", var[1] is the whole dialog definition as one string,
-- with the sign's current text inside an add_text_input|display_text||...
-- line). Only acts while S.captureArmed is true (set by the "Capture from
-- Sign" button), and disarms itself after one attempt either way, so it
-- never grabs text from some other dialog by accident.
AddHook("onvariant", "autosb_sign_capture", function(var)
    if not S.captureArmed then return false end
    if var[0] ~= "OnDialogRequest" then return false end

    local dialog = tostring(var[1] or "")
    if not dialog:find("sign_edit", 1, true) then return false end  -- not a sign dialog

    S.captureArmed = false
    local text = dialog:match("add_text_input|display_text||(.-)|%d+|")
    if not text then
        setMsg("Could not find text in that dialog.", false)
        return false
    end
    -- Keep the color codes as-is (e.g. `5, `b) so the broadcast keeps the
    -- same coloring the sign has - only strip() for display in setMsg/say
    -- below, never for what actually goes into cfg.text.
    cfg.text = text
    setMsg("Captured from sign: " .. strip(text), true)
    say("`2[Auto SB] `wCaptured SB text from sign: `9" .. strip(text))
    return false
end)

AddHook("onvariant", "autosb_console", function(var)
    if var[0] ~= "OnConsoleMessage" then return false end
    if not S.running then return false end

    local msg = strip(tostring(var[1] or ""))
    if msg:find("Auto SB", 1, true) then return false end   -- ignore our own lines
    if cfg.debug then say("`8[dbg] " .. msg) end
    local low = msg:lower()

    -- SUCCESS ------------------------------------------------------
    if low:find("super%-broadcast sent") then
        local cost = toNum(msg:match("Used%s+([%d,]+)")) or 0
        local cur  = msg:match("Used%s+[%d,]+%s+(%a[%a ]-)[%.%(]") or "Gems"
        local left = toNum(msg:match("%(([%d,]+)%s+left%)"))

        if cur:lower():find("black", 1, true) then
            S.blackUsed = S.blackUsed + cost
        else
            S.mainUsed = S.mainUsed + cost
        end
        S.gemsUsed = S.blackUsed * cfg.bgRate + S.mainUsed
        S.gemsLeft = left
        S.leftCur  = cur

        S.done     = S.done + 1
        S.fails    = 0
        S.waiting  = false
        S.nextSend = os.time() + cfg.delay      -- delay counts from the confirmed SB
        S.last     = "sent"
        S.reportAt = os.time() + 1              -- report on the next tick
        return false
    end

    -- JOIN/WARP FAILED: e.g. "Error connecting", world full/busy, etc.
    -- Generic match so we don't depend on one exact error string. Clears
    -- the pending warp so the next tick retries immediately instead of
    -- waiting out the full cfg.warpRetry delay.
    if S.warpSentAt and low:find("error") then
        say("`4[Auto SB] `wCouldn't join " .. cfg.targetWorld .. " (" .. msg .. "), retrying...")
        S.warpSentAt = nil
        return false
    end

    -- COOLDOWN: wait exactly what the server says ---------------------
    if S.waiting and low:find("before you can broadcast again", 1, true) then
        local h = tonumber(msg:match("(%d+)%s*hour")) or 0
        local m = tonumber(msg:match("(%d+)%s*min"))  or 0
        local s = tonumber(msg:match("(%d+)%s*sec"))  or 0
        local wait = h * 3600 + m * 60 + s

        S.waiting  = false
        S.fails    = 0
        S.last     = "cooldown"
        S.nextSend = os.time() + wait + 2
        say("`4[Auto SB] `wCooldown active, retrying in " .. (wait + 2) .. "s")
        return false
    end

    -- NOT ENOUGH GEMS -------------------------------------------------
    if S.waiting and low:find("gem") and
       (low:find("not enough") or low:find("can't afford") or low:find("cannot afford")) then
        stop("not enough gems.")
    end
    return false
end)

---------------- MAIN LOOP ---------------------------
-- True once chatGapMs has passed since the last chat line.
-- os.clock() gives the sub-second precision, os.time() (real clock) is the
-- safety net so the gap can never be much longer than intended.
local function chatGapPassed()
    if S.chatLastTime == nil then return true end
    local gap = cfg.chatGapMs / 1000
    local dt  = os.time()  - S.chatLastTime
    local dc  = os.clock() - S.chatLastClock
    if dt >= math.ceil(gap) + 1 then return true end
    return dc >= gap and dt >= math.floor(gap)
end

local function tick()
    local now = os.time()
    checkWebhookResult()

    -- Say queued report lines in world chat, one every chatGapMs.
    -- Runs even when stopped/finished so the last report is never lost.
    if #S.chatQueue > 0 and chatGapPassed() then
        sendText(table.remove(S.chatQueue, 1))
        S.chatLastTime  = os.time()
        S.chatLastClock = os.clock()
    end

    -- All SB done: warp to the end world, but only AFTER the last report lines
    -- were said (so the report is still said in the SB world).
    if S.finishWarp and #S.chatQueue == 0 and chatGapPassed() then
        S.finishWarp = false
        local dest = trim(cfg.endWorld)
        local cur  = getWorldName()
        if dest ~= "" and not (cur and norm(cur) == norm(dest)) then
            say("`2[Auto SB] `wDone - warping to `9" .. dest)
            sendText("/warp " .. dest)
        end
    end

    -- No proactive pull here - only act once the SB send is actually due
    -- below. getWorldName() == nil just means disconnected (world-select
    -- menu); used only to avoid miscounting that as a confirm failure.
    local disconnected = cfg.targetWorld ~= "" and getWorldName() == nil

    if not S.running then return end

    -- Report after a confirmed SB
    if S.reportAt and now >= S.reportAt then
        S.reportAt = nil
        report()
        if S.done >= cfg.total then
            say("`2[Auto SB] `wAll " .. cfg.total .. " super broadcasts completed!")
            S.running = false
            if trim(cfg.endWorld) ~= "" then S.finishWarp = true end
            return
        end
    end

    -- Confirmation timeout. A disconnect isn't a real "SB failed" - don't
    -- burn through maxFails for it, just wait for reconnect to finish.
    if S.waiting and now - S.sentAt >= cfg.confirmWait then
        S.waiting = false
        if disconnected then
            S.last = "disconnected"
            S.nextSend = now + 10
        else
            S.fails = S.fails + 1
            S.last  = "no confirm"
            say("`4[Auto SB] `wNo confirmation (" .. S.fails .. "/" .. cfg.maxFails .. ")")
            if S.fails >= cfg.maxFails then stop("too many failed attempts.") return end
            S.nextSend = now + 10
        end
    end

    -- SB is ready: make sure we're in the target world, then send
    if not S.waiting and not S.reportAt and now >= S.nextSend then
        if readyToSend(now) then
            pickEmoji()
            sendText("/sb " .. buildSB())
            S.waiting, S.sentAt = true, now
            S.warpTries = 0
        end
    end
end

---------------- UI HELPERS --------------------------
local function fmtHM(mins)                    -- 74 -> "1h 14m"
    if mins < 60 then return mins .. "m" end
    return math.floor(mins / 60) .. "h " .. (mins % 60) .. "m"
end

local function statusInfo()
    if not S.running then
        if #S.chatQueue > 0 then return "Sending Report", C.cyan end
        if S.finishWarp then return "Finishing", C.cyan end
        return "Idle", C.white
    end
    if S.waiting then return "Waiting", C.cyan end
    if S.warpSentAt and norm(cfg.targetWorld) ~= "" then return "Warping", C.yellow end
    if S.reportAt or #S.chatQueue > 0 then return "Sending Report", C.cyan end
    return "Running", C.green
end

local DEFAULTS = {}                           -- snapshot for the "Default" button
for _, k in ipairs(SAVE_KEYS) do DEFAULTS[k] = cfg[k] end

local tab   = 1
local TABS  = { "Stats", "Broadcast", "WebHook", "Advanced" }

local function intInput(label, key, min)
    local _, v = ImGui.InputInt(label, cfg[key])
    if v then cfg[key] = math.max(min, v) end
end

local function resetCount()
    S.done, S.gemsUsed, S.blackUsed, S.mainUsed, S.fails = 0, 0, 0, 0, 0
    S.last = "-"
    setMsg("Count reset", true)
end

local function resetDefaults()
    for _, k in ipairs(SAVE_KEYS) do cfg[k] = DEFAULTS[k] end
    setMsg("Settings reset to default", true)
end

---------------- TAB: STATS ---------------------------
local function tabStats()
    local remaining = math.max(0, cfg.total - S.done)
    local secs = remaining * cfg.delay
    if S.running and not S.waiting then
        secs = math.max(0, S.nextSend - os.time()) + math.max(0, remaining - 1) * cfg.delay
    end
    local mins = math.ceil(secs / 60)
    local frac = cfg.total > 0 and math.min(1, S.done / cfg.total) or 0

    -- status line:  Idle   WORLD > TARGET
    local label, col = statusInfo()
    textColored(col, label)
    ui("SameLine")
    textColored(C.gray, "   " .. (getWorldName() or "unknown")
        .. (norm(cfg.targetWorld) ~= "" and ("  >  " .. cfg.targetWorld) or ""))

    -- progress:  19 / 45  + bar + small info line
    ui("Spacing")
    textColored(C.white, S.done .. " / " .. cfg.total)
    progressBar(frac)
    textColored(C.gray, math.floor(frac * 100) .. "%   left " .. remaining
        .. "   ETA " .. fmtHM(mins) .. "   last: " .. S.last)

    ui("Spacing")
    ImGui.Separator()
    ui("Spacing")

    -- stat rows
    rowv("Gems Used", comma(S.gemsUsed), C.white)
    ui("Spacing")
    rowv("Black Gems", comma(S.blackUsed) .. " used  (x" .. cfg.bgRate .. ")", C.white)
    ui("Spacing")
    rowv("Balance", S.gemsLeft and (comma(S.gemsLeft) .. " " .. S.leftCur) or "-", C.white)
    ui("Spacing")
    rowv("Time Left", fmtHM(mins), C.white)
    if S.running and not S.waiting and not (S.warpSentAt and norm(cfg.targetWorld) ~= "") then
        ui("Spacing")
        rowv("Next SB in", math.max(0, S.nextSend - os.time()) .. "s", C.yellow)
    end
    ui("Spacing")

    if button("Reset Count", -1, 30) then
        if S.running then setMsg("Stop first, then reset.", false) else resetCount() end
    end
end

---------------- TAB: BROADCAST -----------------------
local function tabBroadcast()
    local _, t = ImGui.InputText("SB Text", cfg.text, 128)
    if t then cfg.text = t end

    if S.captureArmed then
        if button(" Waiting... click to cancel ") then
            S.captureArmed = false
            setMsg("Capture cancelled.", true)
        end
        textColored(C.cyan, "Now go wrench/punch the sign in-game.")
    else
        if button(" Capture from Sign ") then
            S.captureArmed = true
            setMsg("Armed - go wrench a sign now.", true)
        end
        textColored(C.gray, "Click, then wrench a sign to copy its text.")
    end

    local _, g = ImGui.InputText("Tag", cfg.tag, 32)
    if g then cfg.tag = g end

    local _, w = ImGui.InputText("Target world", cfg.targetWorld, 32)
    if w then cfg.targetWorld = w end
    textColored(C.gray, "Blank = no warping, SB instantly when ready.")

    local _, ew = ImGui.InputText("End world", cfg.endWorld, 32)
    if ew then cfg.endWorld = ew end
    textColored(C.gray, "Warp here after all SB are done. Blank = stay.")

    textColored(C.gray, "Preview: /sb " .. buildSB())

    ui("Spacing")
    ImGui.Separator()
    intInput("Total SB", "total", 1)
    intInput("Delay (sec)", "delay", 1)
    textColored(C.gray, "180s = 3 minutes (server cooldown)")

    ui("Spacing")
    if button(" World chat report: " .. (cfg.worldReport and "ON" or "OFF") .. " ") then
        cfg.worldReport = not cfg.worldReport
    end
end

---------------- TAB: ADVANCED ------------------------
-- (bgRate, confirmWait, maxFails, warpRetry, settle, chatGapMs and debug keep
--  their default values from the cfg table at the top - just not shown here.)
local function tabAdvanced()
    if button(" Random growmoji: " .. (cfg.growmoji and "ON" or "OFF") .. " ") then
        cfg.growmoji = not cfg.growmoji
    end
    textColored(C.gray, "A random growmoji is added behind the tag on every SB.")
end

---------------- TAB: WEBHOOK --------------------------
local function tabWebhook()
    textColored(C.white, "Discord Webhook")
    textColored(C.gray, "Posts an embed to Discord after every confirmed SB.")
    ui("Spacing")

    local _, wh = ImGui.InputText("Webhook URL", cfg.webhookUrl, 256)
    if wh then cfg.webhookUrl = wh end

    local _, an = ImGui.InputText("Account name", cfg.accountName, 32)
    if an then cfg.accountName = an end
    textColored(C.gray, "Blank = auto-detect from the game.")

    local _, di = ImGui.InputText("Discord ID", cfg.discordId, 32)
    if di then cfg.discordId = di end
    textColored(C.gray, "Your user ID, shown as a @mention. Blank = none.")
    ui("Spacing")

    if button(" Webhook: " .. (cfg.webhookEnabled and "ON" or "OFF") .. " ") then
        cfg.webhookEnabled = not cfg.webhookEnabled
    end
    ui("SameLine")
    if button(" Send test ping ") then
        if trim(cfg.webhookUrl) == "" then
            setMsg("Set a webhook URL first.", false)
        else
            local was = cfg.webhookEnabled
            cfg.webhookEnabled = true
            sendLogEmbed()
            cfg.webhookEnabled = was
            setMsg("Test ping sent - check Discord.", true)
        end
    end
end

---------------- BACKGROUND THREAD --------------------
-- tick() runs in its own thread so Auto SB keeps working when Growtopia is
-- minimized (the draw hook does not fire then). Falls back to the draw hook
-- if this executor has no RunThread.
local bg = { alive = true }
local threaded = false
if type(RunThread) == "function" and type(Sleep) == "function" then
    threaded = pcall(RunThread, function()
        while bg.alive do
            pcall(tick)
            Sleep(200)
        end
    end)
end

---------------- DRAW ---------------------------------
AddHook("ondraw", "autosb_menu", function(dt)
    if not threaded then tick() end

    local nc, nv = pushTheme()

    beginWindow("Auto SB - PoliceMan v4", 600, 520)
    local widthPushed = ui("PushItemWidth", 240 * UI_SCALE)
    returnButton()

    ------------- START / STOP (full width) -------------
    if not S.running then
        local label = (S.done > 0 and S.done < cfg.total) and ">  RESUME SB" or ">  START SB"
        if bigButton(label) then start() end
    else
        if bigButton("[]  STOP SB",
            { 0.72, 0.20, 0.20, 1 }, { 0.85, 0.26, 0.26, 1 }, { 0.60, 0.15, 0.15, 1 }) then
            stop("stopped by user.")
        end
    end

    ------------- CONFIG -------------------
    section("CONFIG")
    textColored(C.gray, S.cfgPath or "autosb_config.txt")
    ui("SameLine")
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    ------------- TABS ---------------------
    tab = navBegin(TABS, tab)

    if     tab == 1 then tabStats()
    elseif tab == 2 then tabBroadcast()
    elseif tab == 3 then tabWebhook()
    else                 tabAdvanced() end
    navEnd()

    if widthPushed then ui("PopItemWidth") end
    navEnd()
    ImGui.End()
    popTheme(nc, nv)
end)


math.randomseed(os.time())
pickEmoji()
loadConfig(true)                              -- load saved settings on startup
say("`2[Auto SB] v4 loaded." .. (S.cfgPath and " Config loaded." or ""))

ACTIVE.stop = function() bg.alive = false stop("returned to loader.") end

end  -- startAutoSB

local function startVendHelper()
-- Vend Helper: wrench-triggered auto ADD (your own vends) + auto BUY (other people's vends)
-- Everything is controlled from the ImGui menu (no chat commands).
-- Add packet format taken from real dumps (vend_edit / addstock / x|..| y|..|).
-- Buy packet is parsed from the buy dialog itself; use Debug to verify it.

---------------------------------------------------------------
-- STATE (edit defaults here, or change live in the menu)
---------------------------------------------------------------
local MAX_AMOUNT = 250        -- upper limit for the buy amount (the game input allows 3 digits)
local MAX_SELL_AMOUNT = 999   -- the "How many to sell?" box only accepts 3 digits (add_text_input|sellamount|How many to sell?|0|3|)


local S = {
    add    = true,   -- auto add stock when wrenching your own vend
    buy    = false,  -- auto buy when wrenching someone's vend
    amount = 1,      -- how many to buy
    sell      = false,  -- auto sell when a "Buying Machine" dialog opens
    sellAmount = 1,     -- how many to sell (ignored if sellAll is on)
    sellAll    = false, -- sell your entire stack instead of a fixed amount
    instant  = true,  -- auto-press Buy on the Purchase Confirmation dialog (always on)
    delay  = 30,     -- ms to wait before sending the buy / confirm packets (0 = instant)
    hide   = true,   -- hide the dialog when the script handles it
    debug  = false,  -- print dialogs / parsed values / packets sent
    menu   = true,   -- show ImGui menu (set to false to hide it)
}

---------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------
local function log(msg)
    LogToConsole("`2[VendHelper] `o" .. tostring(msg))
end

local function dbg(msg)
    if S.debug then log(msg) end
end

-- read a variant field either as var.v1/v2 or var[0]/[1]
local function field(var, name, idx)
    local ok, v = pcall(function() return var[name] end)
    if ok and v ~= nil then return v end
    ok, v = pcall(function() return var[idx] end)
    if ok and v ~= nil then return v end
    return nil
end

-- remove Growtopia color codes like `2 or `` from text
local function clean(t)
    return (tostring(t or ""):gsub("`.", ""))
end

-- how many server replies to show after we confirm a purchase
local watch = 0

-- run fn after ms milliseconds (RunThread if the executor has it, else a short Sleep)
local function later(ms, fn)
    ms = tonumber(ms) or 0
    if ms <= 0 then fn() return end
    if type(RunThread) == "function" then
        local ok = pcall(RunThread, function()
            if type(Sleep) == "function" then pcall(Sleep, ms) end
            fn()
        end)
        if ok then return end
    end
    if type(Sleep) == "function" then pcall(Sleep, ms) end
    fn()
end

local function clampAmount(n)
    n = math.floor(tonumber(n) or 1)
    if n < 1 then n = 1 end
    if n > MAX_AMOUNT then n = MAX_AMOUNT end
    return n
end

local function clampSell(n)
    n = math.floor(tonumber(n) or 1)
    if n < 1 then n = 1 end
    if n > MAX_SELL_AMOUNT then n = MAX_SELL_AMOUNT end
    return n
end

---------------------------------------------------------------
-- AUTO ADD (own vend, dialog has "Add items to the machine")
---------------------------------------------------------------
local function handleAdd(dialog)
    local dialogName = dialog:match("end_dialog|([^|]*)|")
    local button     = dialog:match("add_button|([^|]*)|Add items to the machine")
    local x          = dialog:match("embed_data|x|(%-?%d+)")
    local y          = dialog:match("embed_data|y|(%-?%d+)")

    -- keep the machine's current price settings so nothing changes
    local price      = dialog:match("add_text_input|setprice|[^|]*|([^|]*)|")
    local perItem    = dialog:match("add_checkbox|chk_peritem|[^|]*|(%d)|")
    local perLock    = dialog:match("add_checkbox|chk_perlock|[^|]*|(%d)|")

    dbg(string.format("ADD name=%s button=%s x=%s y=%s price=%s peritem=%s perlock=%s",
        tostring(dialogName), tostring(button), tostring(x), tostring(y),
        tostring(price), tostring(perItem), tostring(perLock)))

    if not (dialogName == "vend_edit" and button and x and y) then return false end

    local pkt = string.format(
        "action|dialog_return\ndialog_name|%s\nx|%s|\ny|%s|\nbuttonClicked|%s\n\n",
        dialogName, x, y, button)
    if price and perItem and perLock then
        pkt = pkt .. string.format("setprice|%s\nchk_peritem|%s\nchk_perlock|%s\n",
            price, perItem, perLock)
    end

    SendPacket(2, pkt)
    log(string.format("Add stock sent for (%s, %s)", x, y))
    return S.hide
end

---------------------------------------------------------------
-- AUTO BUY (someone else's vend)
-- Detects a vend dialog that is NOT vend_edit, finds its amount input
-- and tile x/y from the dialog, and answers with S.amount.
---------------------------------------------------------------
local function handleBuy(dialog)
    local dialogName = dialog:match("end_dialog|([^|]*)|")
    if not dialogName or dialogName == "vend_edit" or dialogName == "vend_buyconfirm" then return false end

    local isVend = dialogName:lower():find("vend", 1, true)
                or dialog:lower():find("add_text_input|buy", 1, true)
    if not isVend then return false end

    local x = dialog:match("embed_data|x|(%-?%d+)") or dialog:match("embed_data|tilex|(%-?%d+)")
    local y = dialog:match("embed_data|y|(%-?%d+)") or dialog:match("embed_data|tiley|(%-?%d+)")
    local inputName = dialog:match("add_text_input|([^|]*)|")

    dbg(string.format("BUY name=%s input=%s x=%s y=%s amount=%d",
        tostring(dialogName), tostring(inputName), tostring(x), tostring(y), S.amount))

    if not (inputName and x and y) then
        log("Buy dialog found but could not parse it. Turn on Debug and send me the output.")
        return false
    end

    local pkt = string.format(
        "action|dialog_return\ndialog_name|%s\nx|%s|\ny|%s|\n%s|%d\n",
        dialogName, x, y, inputName, S.amount)

    local amt = S.amount
    later(S.delay, function()
        SendPacket(2, pkt)
        log(string.format("Buy %d sent for (%s, %s)", amt, x, y))
    end)
    return S.hide
end

---------------------------------------------------------------
-- INSTANT BUY: answer the "Purchase Confirmation" dialog (Buy button)
-- Real packet captured from the game:
--   action|dialog_return
--   dialog_name|vend_buyconfirm
--   x|26|
--   y|35|
--   buyamount|1|
---------------------------------------------------------------
local lastWrench = {}   -- last tile you wrenched (fallback if the dialog has no x/y)

local function handleConfirm(dialog)
    local dialogName = dialog:match("end_dialog|([^|]*)|") or "vend_buyconfirm"
    if dialogName == "vend_edit" then return false end

    local x = dialog:match("embed_data|x|(%-?%d+)") or dialog:match("embed_data|tilex|(%-?%d+)") or lastWrench.x
    local y = dialog:match("embed_data|y|(%-?%d+)") or dialog:match("embed_data|tiley|(%-?%d+)") or lastWrench.y

    -- amount: embed_data first, then the "You'll get" count, then the amount you set
    local amount = dialog:match("embed_data|buyamount|(%d+)")
    if not amount then
        local pos = dialog:find("get:", 1, true)
        if pos then amount = dialog:match("add_label_with_icon|[^|]*|(%d+) x", pos) end
    end
    amount = amount or S.amount

    dbg(string.format("CONFIRM name=%s x=%s y=%s amount=%s", dialogName, tostring(x), tostring(y), tostring(amount)))

    if not (x and y) then
        log("Purchase Confirmation found but no tile x/y. Turn on Debug and send me the output.")
        return false
    end

    local pkt = string.format(
        "action|dialog_return\ndialog_name|%s\nx|%s|\ny|%s|\nbuyamount|%s|\n",
        dialogName, x, y, amount)

    dbg("CONFIRM sending:\n" .. pkt)
    later(S.delay, function()
        SendPacket(2, pkt)
        watch = 5
        log(string.format("Purchase confirmed: %s item(s) at (%s, %s)", tostring(amount), x, y))
    end)
    return S.hide
end

---------------------------------------------------------------
-- AUTO SELL (a "Buying Machine" - you give items, it gives World Locks)
-- Detected by the dialog's own wording ("Buying Machine" header and the
-- "How many to sell?" prompt), not by dialog_name, since that name isn't
-- fixed. Answers with S.sellAmount (or your full stack if sellAll is on)
-- in a single dialog_return - no separate confirm step needed.
---------------------------------------------------------------
local function isSellMachineDialog(dialog)
    local d = dialog:lower()
    return d:find("buying machine", 1, true) ~= nil
        or d:find("how many to sell", 1, true) ~= nil
end

-- The Buying Machine's own "Purchase Confirmation" step (after you answer the
-- first dialog) is marked by the sellamount/wtb fields it embeds - a normal
-- buy's confirmation never has those, only "buyamount".
local function isSellConfirmDialog(dialog)
    return dialog:find("embed_data|sellamount|", 1, true) ~= nil
        or dialog:find("embed_data|wtb|", 1, true) ~= nil
end

-- A Buying Machine's dialog carries an extra embed_data field identifying
-- which item it buys (e.g. "embed_data|wtb|2286", 2286 = the item's id).
-- x/y are handled separately, so skip those here and just echo back
-- whatever else the dialog embeds - the server likely needs it to know
-- which item/listing the sale applies to.
local function extraEmbedFields(dialog)
    local extras = {}
    for k, v in dialog:gmatch("embed_data|([%w_]+)|([^\n\r]*)") do
        if k ~= "x" and k ~= "y" then
            v = v:gsub("|%s*$", "")
            extras[#extras + 1] = { k, v }
        end
    end
    return extras
end

local function handleSellMachine(dialog)
    local dialogName = dialog:match("end_dialog|([^|]*)|")
    if not dialogName or dialogName == "vend_edit" then return false end

    local x = dialog:match("embed_data|x|(%-?%d+)") or dialog:match("embed_data|tilex|(%-?%d+)") or lastWrench.x
    local y = dialog:match("embed_data|y|(%-?%d+)") or dialog:match("embed_data|tiley|(%-?%d+)") or lastWrench.y
    local inputName = dialog:match("add_text_input|([^|]*)|")

    -- some clients label this button something other than plain "Sell" (e.g. with
    -- an icon tag in front), so also accept a button whose label just ends in "Sell"
    local buttonField = dialog:match("add_button|([^|]*)|Sell|")
        or dialog:match("add_button|([^|]*)|[^|]-Sell|")

    local have     = tonumber(dialog:match("You have (%d+)"))
    local itemName = dialog:match("You have %d+ ([^.]+)%.")

    local extraStr = {}
    for _, e in ipairs(extraEmbedFields(dialog)) do extraStr[#extraStr + 1] = e[1] .. "=" .. e[2] end
    dbg(string.format("SELL name=%s input=%s button=%s x=%s y=%s have=%s item=%s extra=%s",
        tostring(dialogName), tostring(inputName), tostring(buttonField), tostring(x), tostring(y),
        tostring(have), tostring(itemName), table.concat(extraStr, ",")))

    if not (inputName and x and y) then
        log("Buying Machine dialog found but could not parse it (no text input / tile found). Turn on Debug and send me the raw [DIALOG ...] output.")
        return false
    end

    local amt
    if S.sellAll then
        amt = math.min(have or 0, MAX_SELL_AMOUNT)
        if have and have > MAX_SELL_AMOUNT then
            log(string.format(
                "You have %d %s but the sell box only takes 3 digits (max %d). Selling %d now - wrench again for the rest.",
                have, tostring(itemName or "item"), MAX_SELL_AMOUNT, amt))
        end
    else
        amt = clampSell(S.sellAmount)
        if have and amt > have then amt = have end
    end

    if not amt or amt <= 0 then
        dbg("Nothing to sell (you have 0" .. (itemName and (" " .. itemName) or "") .. ").")
        return false
    end

    -- trailing "|" after the value matches the real packet format captured for
    -- the other quantity dialog (vend_buyconfirm's buyamount|%s|)
    local pkt = string.format(
        "action|dialog_return\ndialog_name|%s\nx|%s|\ny|%s|\n%s|%d|\n",
        dialogName, x, y, inputName, amt)
    for _, e in ipairs(extraEmbedFields(dialog)) do
        pkt = pkt .. string.format("%s|%s|\n", e[1], e[2])
    end
    if buttonField then
        pkt = pkt .. string.format("buttonClicked|%s\n", buttonField)
    end

    dbg("SELL sending:\n" .. pkt)
    later(S.delay, function()
        SendPacket(2, pkt)
        watch = 5
        log(string.format("Sell sent: %d x %s at (%s, %s)", amt, tostring(itemName or "item"), x, y))
    end)
    return S.hide
end

---------------------------------------------------------------
-- SELL - PURCHASE CONFIRMATION step
-- After the first dialog, the machine asks you to confirm with a second
-- "Purchase Confirmation" dialog. It has no editable fields at all - just
-- embed_data (sellamount, wtb, x, y) that the server already filled in -
-- so the whole reply is just echoing those embed_data fields straight back.
---------------------------------------------------------------
local function handleSellConfirm(dialog)
    local dialogName = dialog:match("end_dialog|([^|]*)|") or "buy_useconfirm"
    if dialogName == "vend_edit" then return false end

    local x = dialog:match("embed_data|x|(%-?%d+)") or dialog:match("embed_data|tilex|(%-?%d+)") or lastWrench.x
    local y = dialog:match("embed_data|y|(%-?%d+)") or dialog:match("embed_data|tiley|(%-?%d+)") or lastWrench.y
    local extras = extraEmbedFields(dialog)   -- everything embedded besides x/y (e.g. sellamount, wtb)

    local extraStr = {}
    for _, e in ipairs(extras) do extraStr[#extraStr + 1] = e[1] .. "=" .. e[2] end
    dbg(string.format("SELL CONFIRM name=%s x=%s y=%s extra=%s",
        tostring(dialogName), tostring(x), tostring(y), table.concat(extraStr, ",")))

    if not (x and y) or #extras == 0 then
        log("Sell confirmation dialog found but could not parse it. Turn on Debug and send me the raw [DIALOG ...] output.")
        return false
    end

    local pkt = string.format("action|dialog_return\ndialog_name|%s\nx|%s|\ny|%s|\n", dialogName, x, y)
    for _, e in ipairs(extras) do
        pkt = pkt .. string.format("%s|%s|\n", e[1], e[2])
    end

    -- grab whichever embedded field looks like the amount, just for the log line
    local amtLabel
    for _, e in ipairs(extras) do
        if e[1]:lower():find("amount", 1, true) then
            amtLabel = e[2]
            break
        end
    end

    dbg("SELL CONFIRM sending:\n" .. pkt)
    later(S.delay, function()
        SendPacket(2, pkt)
        watch = 5
        log(string.format("Sell confirmed: %s item(s) at (%s, %s)", tostring(amtLabel or "?"), x, y))
    end)
    return S.hide
end

---------------------------------------------------------------
-- HOOK: incoming dialog (opens after you wrench a machine)
---------------------------------------------------------------
local function on_variant(var)
    local fname = field(var, "v1", 0)

    -- after we confirm a purchase, show what the server answers
    if watch > 0 and (fname == "OnConsoleMessage" or fname == "OnTalkBubble") then
        local txt = clean(fname == "OnTalkBubble" and field(var, "v3", 2) or field(var, "v2", 1))
        watch = watch - 1
        if txt:find("bought", 1, true) or txt:find("sold", 1, true) then
            watch = 0
            log("RESULT OK: " .. txt)
        else
            log("Server said: " .. txt:sub(1, 160))
        end
    end

    if fname ~= "OnDialogRequest" then return false end
    local dialog = field(var, "v2", 1) or ""
    local dname = dialog:match("end_dialog|([^|]*)|")
    local isConfirm = dname == "vend_buyconfirm" or dialog:find("Purchase Confirmation", 1, true)
    local isSellMachine = isSellMachineDialog(dialog)
    local isSellConfirm = isConfirm and isSellConfirmDialog(dialog)

    -- debug recorder: show every vend / buying-machine related dialog, whatever the toggles are
    if S.debug and (isConfirm or isSellMachine or (dname and dname:lower():find("vend", 1, true))) then
        log("DIALOG [" .. tostring(dname) .. "]:\n" .. dialog)
    end

    -- check the sell-flavoured confirmation BEFORE the generic one: a sell's
    -- confirm dialog also matches isConfirm (it says "Purchase Confirmation"
    -- too), but needs the different handler above, not handleConfirm's
    -- buy-amount logic.
    if S.instant and isSellConfirm then
        return handleSellConfirm(dialog)
    end
    if S.instant and isConfirm then
        return handleConfirm(dialog)
    end
    if S.add and dialog:find("Add items to the machine", 1, true) then
        return handleAdd(dialog)
    end
    if S.sell and isSellMachine then
        return handleSellMachine(dialog)
    end
    if S.buy then
        return handleBuy(dialog)
    end
    return false
end

---------------------------------------------------------------
-- CONFIG SAVE / LOAD
-- Saves: auto add, auto buy, amount, instant buy, step delay, hide dialog.
-- (Debug and menu visibility are not saved.) Loaded automatically on start.
---------------------------------------------------------------
local CONFIG_KEYS  = { "add", "buy", "amount", "sell", "sellAmount", "sellAll", "hide" }  -- instant/delay are fixed (always on / 30ms)
local CONFIG_PATHS = { "scripts/vend_helper.cfg", "vend_helper.cfg" }   -- first one that works is used
local status = ""   -- shown under the buttons in the menu

local function ioAvailable()
    return type(io) == "table" and type(io.open) == "function"
end

local function saveConfig()
    local lines = {}
    for _, k in ipairs(CONFIG_KEYS) do lines[#lines + 1] = k .. "=" .. tostring(S[k]) end
    local text = table.concat(lines, "\n") .. "\n"

    if ioAvailable() then
        for _, path in ipairs(CONFIG_PATHS) do
            local ok, f = pcall(io.open, path, "w")
            if ok and f then
                local wrote = pcall(function() f:write(text) f:close() end)
                if wrote then
                    status = "Config saved"
                    log("Config saved to " .. path)
                    return true
                end
            end
        end
    end

    status = "Save failed (see console)"
    log("Could not write a file from this executor. Your settings as text, "
        .. "paste the values into the S table at the top of the script:\n" .. text)
    return false
end

local function loadConfig(quiet)
    if not ioAvailable() then
        if not quiet then status = "Load failed (no file access)"; log("Load failed: no file access.") end
        return false
    end

    for _, path in ipairs(CONFIG_PATHS) do
        local ok, f = pcall(io.open, path, "r")
        if ok and f then
            local okr, text = pcall(function() local t = f:read("*a"); f:close(); return t end)
            if okr and type(text) == "string" then
                local allowed = {}
                for _, k in ipairs(CONFIG_KEYS) do allowed[k] = true end
                for k, v in text:gmatch("([%w_]+)=([^\n\r]*)") do
                    if allowed[k] then
                        if type(S[k]) == "boolean" then
                            S[k] = (v == "true")
                        elseif type(S[k]) == "number" then
                            local n = tonumber(v)
                            if n then S[k] = n end
                        end
                    end
                end
                S.amount     = clampAmount(S.amount)
                S.sellAmount = clampSell(S.sellAmount)
                S.delay  = math.min(5000, math.max(0, math.floor(S.delay)))
                status = "Config loaded"
                log("Config loaded from " .. path)
                return true
            end
        end
    end

    if not quiet then status = "No saved config found"; log("No saved config found.") end
    return false
end

---------------------------------------------------------------
-- HOOK: outgoing packets (debug print + remember last wrenched tile)
---------------------------------------------------------------
local function on_send(ptype, packet)
    if type(packet) ~= "string" then return false end

    if S.debug and packet:find("dialog_return", 1, true) and packet:find("vend", 1, true) then
        log("OUTGOING:\n" .. packet)
    end

    if packet:find("action|wrench", 1, true) then
        local wx = packet:match("|x|(%-?%d+)")
        local wy = packet:match("|y|(%-?%d+)")
        if wx and wy then lastWrench.x, lastWrench.y = wx, wy end
    end

    return false
end

---------------------------------------------------------------
-- IMGUI MENU
-- ImGui bindings differ between executors: some return (changed, value),
-- others just the value. These wrappers handle both, and the whole
-- draw is pcall-protected so a wrong function name can't crash anything.
---------------------------------------------------------------
local VTABS = { "Stock", "Sell", "Options" }
local vTab = 1
local function drawMenu()
    if not S.menu then return end
    local nc, nv = pushTheme()
    beginWindow("Vend Helper", 560, 430)
    returnButton()

    vTab = navBegin(VTABS, vTab)
    if vTab == 1 then
        section("AUTO ADD / BUY")
        if button(" Auto Add (own vend): " .. (S.add and "ON" or "OFF") .. " ") then
            S.add = not S.add
        end
        if button(" Auto Buy (other vends): " .. (S.buy and "ON" or "OFF") .. " ") then
            S.buy = not S.buy
        end

        ui("Spacing")
        local _, amt = ImGui.InputInt("Buy amount", S.amount)
        if amt then S.amount = clampAmount(amt) end
        if button("-10", 60) then S.amount = clampAmount(S.amount - 10) end
        ui("SameLine")
        if button("+10", 60) then S.amount = clampAmount(S.amount + 10) end
        ui("SameLine")
        if button("Max", 60) then S.amount = MAX_AMOUNT end
    elseif vTab == 2 then
        section("AUTO SELL (Buying Machine)")
        if button(" Auto Sell to Buying Machine: " .. (S.sell and "ON" or "OFF") .. " ") then
            S.sell = not S.sell
        end
        if button(" Sell entire stack: " .. (S.sellAll and "ON" or "OFF") .. " ") then
            S.sellAll = not S.sellAll
        end
        if not S.sellAll then
            ui("Spacing")
            local _, samt = ImGui.InputInt("Sell amount", S.sellAmount)
            if samt then S.sellAmount = clampSell(samt) end
            if button("-10", 60) then S.sellAmount = clampSell(S.sellAmount - 10) end
            ui("SameLine")
            if button("+10", 60) then S.sellAmount = clampSell(S.sellAmount + 10) end
            ui("SameLine")
            if button("+100", 60) then S.sellAmount = clampSell(S.sellAmount + 100) end
        else
            textColored(C.gray, "Will sell everything you have of that item.")
        end
    else
        section("OPTIONS")
        if button(" Hide dialog when handled: " .. (S.hide and "ON" or "OFF") .. " ") then
            S.hide = not S.hide
        end
        if button(" Debug output: " .. (S.debug and "ON" or "OFF") .. " ") then
            S.debug = not S.debug
        end

        section("CONFIG")
        if button(" Save config ") then saveConfig() end
        ui("SameLine")
        if button(" Load config ") then loadConfig() end
        if status ~= "" then textColored(C.gray, status) end
    end
    navEnd()

    navEnd()
    ImGui.End()
    popTheme(nc, nv)
end

local drawErrors = 0
local function on_draw()
    if drawErrors >= 3 then return end
    local ok, err = pcall(drawMenu)
    if not ok then
        drawErrors = drawErrors + 1
        log("ImGui error: " .. tostring(err))
        if drawErrors >= 3 then
            log("Menu disabled. Change the defaults in the S table at the top of the script instead.")
        end
    end
end

---------------------------------------------------------------
-- REGISTER HOOKS
-- Tries both capitalisations of each event. Whichever one fires first
-- becomes the "owner"; the other is ignored, so nothing runs twice.
---------------------------------------------------------------
local function register(events, hookName, fn)
    local owner = nil
    for i, ev in ipairs(events) do
        local wrapped = function(...)
            if owner == nil then owner = i end
            if owner ~= i then return false end
            return fn(...)
        end
        local ok, err = pcall(AddHook, ev, hookName .. i, wrapped)
        log(string.format("hook %s: %s", ev, ok and "registered" or ("FAILED - " .. tostring(err))))
    end
end

register({ "OnVariant", "onvariant" },       "vendh_v", on_variant)
register({ "OnSendPacket", "onsendpacket" }, "vendh_s", on_send)
register({ "OnDraw", "ondraw" },             "vendh_d", on_draw)

loadConfig(true)   -- apply saved settings, if any
log("Loaded. Use the Vend Helper menu.")

end  -- startVendHelper

local function startGeiger()
--====================================================
--  AUTO GEIGER - auto geiger hunter + ImGui menu
--  Original script by Swipez (hola_senor). Same hunting logic, now with
--  a Start/Stop menu, stats, editable worlds/positions and webhook.
--  The hunt runs in its own thread, so the game never freezes.
--====================================================

---------------- SETTINGS (defaults) -----------------
local cfg = {
    worldGeiger = "FGEIGER",     -- world where the geigers are used
    worldSave   = "GEIGERMLS",   -- world where items / dead geigers are dropped
    alivePosX   = 41, alivePosY = 25,   -- where you stand in the save world
    itemDropX   = 46, itemDropY = 25,   -- items are dropped here (moves left if blocked)
    deadDropX   = 46, deadDropY = 25,   -- dead geigers are dropped here
    lowGeiger   = 5,             -- go AFK-drop when this many alive geigers are left
    stepTiles   = 5,             -- max tiles per hop (lower = slower/safer)
    stepDelay   = 300,           -- ms between hops (higher = slower/safer)
    collectTries = 15,           -- tries to pick up alive geigers in the save world (0 = keep trying until it works)
    dynSteps    = true,          -- save-world trips (pick up / drop items / drop dead): hop size adapts between 1 and 5 tiles
    breakMin    = 5,             -- every X minutes do a short "break" move
    webhookUrl     = "",         -- Discord webhook URL (paste it in the WebHook tab)
    webhookEnabled = true,       -- post to it on every item found (needs a URL)
    debug       = false,         -- print every "Given" message the script sees
}

---------------- CONFIG FILE -------------------------
local CONFIG_PATHS = {
    "autogeiger_config.txt",
    "scripts/autogeiger_config.txt",
    "/sdcard/autogeiger_config.txt",
}
local SAVE_KEYS = { "worldGeiger", "worldSave", "alivePosX", "alivePosY", "itemDropX", "itemDropY",
                    "deadDropX", "deadDropY", "lowGeiger", "stepTiles", "stepDelay", "collectTries", "dynSteps", "breakMin",
                    "webhookUrl", "webhookEnabled" }
local SAVE_SET = {}
for _, k in ipairs(SAVE_KEYS) do SAVE_SET[k] = true end

---------------- STATE -------------------------------
local ITEM_NAMES = { "Stuff", "Crystal Black", "Crystal Green", "Crystal Red", "Crystal White",
                     "Chemical Haunted", "Chemical Radioactive", "Growtoken", "Battery",
                     "D Battery", "Charger" }

local S = {
    running     = false,
    threadAlive = false,         -- the hunt thread is still winding down after Stop
    stage       = "Idle",
    stageCol    = nil,
    ring        = "-",
    found       = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    other       = {},            -- items not in the list above: name -> count
    otherNames  = {},            -- ... in the order they were first found
    total       = 0,
    geigerLeft  = nil,
    geigerStart = 1,
    deadDropped = 0,             -- dead geigers already dropped in the save world
    deadOffset  = 0,             -- value at the last "Reset Count"
    deadShown   = 0,             -- dead geigers counted since the last reset
    deadCheckAt = 0,
    startedAt   = 0,
    runAccum    = 0,             -- seconds from earlier runs (until Reset Count)
    lastBreak   = 0,
    cfgPath     = nil,
    uiMsg       = nil,
    uiOk        = true,
    uiUntil     = 0,
}

local red, yellow, green = 0, 1, 2
local currentRing = red
local newRing     = false
local itemFound   = false
local breakLoop   = false
local canDrop     = true
local aliveGeiger = 0

local redPosX = { 25, 5, 5, 25, 15, 14 }
local redPosY = { 5, 25, 5, 25, 25, 3 }

local DROP_IDS  = { [2242]=true, [2244]=true, [2246]=true, [2248]=true, [2250]=true,
                    [3306]=true, [1962]=true, [2206]=true, [1482]=true }
local TRASH_IDS = { [1498]=true, [1500]=true, [2804]=true, [2806]=true, [15250]=true }

local rawFindPath = FindPath                     -- the game's own pathfinder

---------------- HELPERS -----------------------------
local function say(msg) LogToConsole(msg) end

local function log(k)                            -- on-screen overlay + console
    pcall(SendVariantList, { [0] = "OnTextOverlay", [1] = k })
    LogToConsole(k)
end

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function norm(s)                           -- world names: no spaces, uppercase
    return (tostring(s or ""):gsub("%s", ""):upper())
end

local function comma(n)
    local r = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (r:gsub("^,", ""))
end

local function clamp(val, minVal, maxVal)
    return math.max(minVal, math.min(val, maxVal))
end

local function fmtClock(secs)
    secs = math.max(0, math.floor(secs))
    local h, m, s = secs // 3600, (secs % 3600) // 60, secs % 60
    if h > 0 then return string.format("%dh %02dm %02ds", h, m, s) end
    return string.format("%dm %02ds", m, s)
end

local function setMsg(text, ok)
    S.uiMsg, S.uiOk, S.uiUntil = text, ok, os.time() + 5
end

local function setStage(text, col)
    S.stage, S.stageCol = text, col
end

local function getItemCount(id)             -- nil if the inventory can't be read
    local ok, n = pcall(function()
        for _, itm in pairs(GetInventory()) do
            if itm.id == id then return itm.amount end
        end
        return 0
    end)
    if ok and type(n) == "number" then return n end
    return nil
end

local function curWorld()                        -- current world, uppercase ("" if unknown)
    local ok, v = pcall(function() return GetWorld().name end)
    if ok and type(v) == "string" then return v:upper() end
    return ""
end

local function inWorld(name) return curWorld() == norm(name) end

local function warp(name)
    SendPacket(2, "action|input\n|text|/warp " .. name .. "\n")
end

local function px() return GetLocal().pos.x // 32 end
local function py() return GetLocal().pos.y // 32 end

-- Sleep that wakes up every 250 ms so STOP reacts quickly.
local function nap(ms)
    local left = ms
    while left > 0 and S.running do
        local s = math.min(250, left)
        Sleep(s)
        left = left - s
    end
end

-- Dynamic hop size (used on the save-world trips): starts at 5 tiles, shrinks toward 1 whenever the
-- way is blocked and grows back one tile per good hop. Off = the fixed "Max tiles per hop" setting.
local dyn = { on = false, n = 5 }
local function stepLimit()
    if dyn.on then return math.max(1, math.min(5, dyn.n)) end
    return math.max(1, cfg.stepTiles)
end

-- Shrinks a move so its real length (not just per axis) is <= the current hop size.
local function limitStep(dx, dy)
    local len  = math.sqrt(dx * dx + dy * dy)
    local step = stepLimit()
    if len <= step then return dx, dy end
    local f  = step / len
    local mx = math.floor(math.abs(dx) * f) * (dx < 0 and -1 or 1)
    local my = math.floor(math.abs(dy) * f) * (dy < 0 and -1 or 1)
    if mx == 0 and my == 0 then               -- always make some progress
        if math.abs(dx) >= math.abs(dy) then mx = (dx < 0) and -1 or 1
        else my = (dy < 0) and -1 or 1 end
    end
    return mx, my
end

-- One small hop. Waits until we have really arrived (or stopped moving)
-- BEFORE the next hop, so hops can never pile up or get skipped.
-- Returns true if we moved.
local function hop(nx, ny)
    local sx, sy = px(), py()
    rawFindPath(nx, ny)
    local lastx, lasty, still = sx, sy, 0
    for _ = 1, 20 do                          -- at most ~2 seconds
        if not S.running then break end
        nap(100)
        local cx, cy = px(), py()
        if cx == nx and cy == ny then return true end
        if cx == lastx and cy == lasty then still = still + 1 else still = 0 end
        lastx, lasty = cx, cy
        if still >= 4 then break end          -- settled / not moving
    end
    return px() ~= sx or py() ~= sy
end

-- The old walker: straight-line hops toward the target, 1-tile steps when blocked, gives up after
-- 3 tries. It never jumps straight to the target (that long jump is what got you kicked). Only the
-- fallback now - the map-aware FindPath below goes first.
local function FindPathSimple(tx, ty)
    local stuck = 0
    while S.running do
        local cx, cy = px(), py()
        local dx, dy = tx - cx, ty - cy
        if dx == 0 and dy == 0 then return end

        local mx, my = limitStep(dx, dy)
        if stuck > 0 then                     -- blocked before: tiny steps only
            mx = (mx > 0) and 1 or ((mx < 0) and -1 or 0)
            my = (my > 0) and 1 or ((my < 0) and -1 or 0)
        end
        if hop(cx + mx, cy + my) then
            stuck = 0
        else
            stuck = stuck + 1
            if stuck >= 3 then
                say("`4[Auto Geiger] `wBlocked on the way to " .. tx .. "," .. ty .. ", skipping this move.")
                return
            end
        end
        nap(cfg.stepDelay + math.random(0, 100))
    end
end

---------------- WORLD MAP + ROUTE AROUND BLOCKS ------
-- Reads the world's blocks once per world, plans a route over walkable tiles (BFS) and walks it in
-- hops of at most stepTiles. When a hop gets stuck the tile in front is marked as blocked for a while
-- and a NEW route is planned from where you stand - so one block in the way no longer ends the move.
local WORLD_W, WORLD_H = 100, 60
local MAP = { fg = nil, world = "", blocked = {} }
local BLOCK_SECS = 120                            -- how long a tile stays "blocked" after a failed hop

local function tf(t, k)                           -- safe field read
    local ok, v = pcall(function() return t[k] end)
    if ok then return v end
    return nil
end

local function itemInfo(id)
    for _, fn in ipairs({ "GetItemInfoByID", "GetItemByIDSafe", "GetItemInfo" }) do
        local f = _G[fn]
        if type(f) == "function" then
            local ok, info = pcall(f, id)
            if ok and info then return info end
        end
    end
    return nil
end

local colCache = {}
local function collisionOf(fg)                    -- number, or false if the executor can't tell
    local v = colCache[fg]
    if v == nil then
        v = false
        local info = itemInfo(fg)
        if info then
            for _, key in ipairs({ "collision_type", "collisionType", "collision" }) do
                local n = tf(info, key)
                if type(n) == "number" then v = n break end
            end
        end
        colCache[fg] = v
    end
    return v
end

local function fgPassable(fg)                     -- air, or a block with no collision / a platform
    if fg == 0 then return true end
    local c = collisionOf(fg)
    return c == 0 or c == 2
end

local function fgSolid(fg)                        -- holds you up when it is under your feet
    if fg == 0 then return false end
    return collisionOf(fg) ~= 0
end

local function idx(x, y) return y * WORLD_W + x end
local function inb(x, y) return x >= 0 and y >= 0 and x < WORLD_W and y < WORLD_H end

local function scanMap()
    pcall(function()
        local w = GetWorld()
        local ww, hh = tonumber(w.width), tonumber(w.height)
        if ww and hh and ww >= 10 and hh >= 10 and ww <= 400 and hh <= 400 then
            WORLD_W, WORLD_H = math.floor(ww), math.floor(hh)
        end
    end)
    local fg = {}
    for y = 0, WORLD_H - 1 do
        for x = 0, WORLD_W - 1 do
            local ok, t = pcall(GetTile, x, y)
            fg[idx(x, y)] = (ok and t and tonumber(tf(t, "fg"))) or 0
        end
    end
    MAP.fg, MAP.world = fg, curWorld()
end

local function ensureMap()                        -- (re)read the blocks when the world changed
    if MAP.fg == nil or MAP.world ~= curWorld() then
        MAP.blocked = {}
        scanMap()
    end
end

local function isPass(x, y)
    if not inb(x, y) then return false end
    local b = MAP.blocked[idx(x, y)]
    if b and os.time() - b < BLOCK_SECS then return false end
    return fgPassable(MAP.fg[idx(x, y)] or 0)
end

local function isGrounded(x, y)
    if y + 1 >= WORLD_H then return true end
    return fgSolid(MAP.fg[idx(x, y + 1)] or 0)
end

local DX, DY = { 1, -1, 0, 0 }, { 0, 0, 1, -1 }

local function bfs(sx, sy)                        -- parent map of every tile reachable from (sx, sy)
    local par = {}
    local start = idx(sx, sy)
    par[start] = -1
    local q, h, tl = { start }, 1, 1
    while h <= tl do
        local cur = q[h]
        h = h + 1
        local cx, cy = cur % WORLD_W, cur // WORLD_W
        for i = 1, 4 do
            local nx, ny = cx + DX[i], cy + DY[i]
            if isPass(nx, ny) then
                local k = idx(nx, ny)
                if par[k] == nil then
                    par[k] = cur
                    tl = tl + 1
                    q[tl] = k
                end
            end
        end
    end
    return par
end

local function pathTo(par, tx, ty)
    local k = idx(tx, ty)
    if par[k] == nil then return nil end
    local rev = {}
    while par[k] ~= -1 do
        rev[#rev + 1] = { x = k % WORLD_W, y = k // WORLD_W }
        k = par[k]
    end
    local path = {}
    for i = #rev, 1, -1 do path[#path + 1] = rev[i] end
    return path
end

local function closestReachable(par, tx, ty)      -- the reachable tile nearest to the target
    local bx, by, bd
    for k in pairs(par) do
        local x, y = k % WORLD_W, k // WORLD_W
        local d = (tx - x) ^ 2 + (ty - y) ^ 2
        if bd == nil or d < bd or (d == bd and isGrounded(x, y) and not isGrounded(bx, by)) then
            bx, by, bd = x, y, d
        end
    end
    return bx, by
end

-- Walks a planned path in hops. Returns true when done, or false plus the path index of the tile
-- that could not be entered.
local function walkPath(path)
    local i = 0
    while i < #path and S.running do
        local j = math.min(#path, i + math.max(1, cfg.stepTiles))
        local k = j
        while k > i + 1 and not isGrounded(path[k].x, path[k].y) do k = k - 1 end
        if not isGrounded(path[k].x, path[k].y) then k = j end
        if not hop(path[k].x, path[k].y) then
            -- the long hop failed: try just the next tile, so we know exactly which one is stuck
            if k > i + 1 and hop(path[i + 1].x, path[i + 1].y) then
                i = i + 1
            else
                return false, i + 1
            end
        else
            i = k
        end
        nap(cfg.stepDelay + math.random(0, 100))
    end
    return true
end

-- How far (in walkable tiles) every tile is from the target, flooding outward from the target.
local function flood(tx, ty)
    local d = {}
    local start = idx(tx, ty)
    d[start] = 0
    local q, h, tl = { start }, 1, 1
    while h <= tl do
        local cur = q[h]
        h = h + 1
        local cx, cy = cur % WORLD_W, cur // WORLD_W
        local dc = d[cur]
        for i = 1, 4 do
            local nx, ny = cx + DX[i], cy + DY[i]
            if isPass(nx, ny) then
                local k = idx(nx, ny)
                if d[k] == nil then
                    d[k] = dc + 1
                    tl = tl + 1
                    q[tl] = k
                end
            end
        end
    end
    return d
end

-- Smart walk. My map only says which way is "downhill" toward the target; the game's own pathfinder
-- (short hops of at most stepTiles) decides what is really possible - jumps, gravity, gates. From where
-- you stand it tries the standable tiles nearby that are closest to the target, best first. A hop that
-- fails is remembered for this spot and the next best is tried, so a block in the way just means "take
-- the other side". Tiles already visited get a penalty so it never circles. Returns true on arrival.
local function smartWalk(tx, ty)
    local d = flood(tx, ty)
    local seen, failed = {}, {}
    for _ = 1, 300 do
        if not S.running then return false end
        local R = math.max(1, stepLimit())
        local cx, cy = px(), py()
        if cx == tx and cy == ty then return true end
        local pos = idx(cx, cy)
        seen[pos] = (seen[pos] or 0) + 1
        if seen[pos] > 4 then return false end            -- going in circles

        local here = d[pos]
        if here == nil then                               -- my own tile isn't "walkable" on the map: ask the neighbours
            for i = 1, 4 do
                local v = d[idx(cx + DX[i], cy + DY[i])]
                if v and (here == nil or v + 1 < here) then here = v + 1 end
            end
        end
        if here == nil then return false end              -- the map has no way from here to the target

        local cands = {}
        for y = cy - R, cy + R do
            for x = cx - R, cx + R do
                if (x ~= cx or y ~= cy) and inb(x, y) then
                    local k = idx(x, y)
                    local dk = d[k]
                    if dk and (isGrounded(x, y) or (x == tx and y == ty))
                       and not (failed[pos] and failed[pos][k]) then
                        local e = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2)
                        if e <= R + 0.5 then                  -- +0.5 so 1-tile hops can still step diagonally (up a ledge)
                            cands[#cands + 1] = { x = x, y = y, k = k, e = e, score = dk + 6 * (seen[k] or 0) }
                        end
                    end
                end
            end
        end
        table.sort(cands, function(a, b)
            if a.score ~= b.score then return a.score < b.score end
            return a.e < b.e
        end)

        local moved = false
        for i = 1, math.min(#cands, 8) do
            if not S.running then return false end
            local c = cands[i]
            if hop(c.x, c.y) then moved = true break end
            failed[pos] = failed[pos] or {}
            failed[pos][c.k] = true
        end
        if not moved then
            if dyn.on and dyn.n > 1 then
                dyn.n = dyn.n - 1                        -- blocked: try again with smaller hops
                seen[pos] = seen[pos] - 1
            else
                return false
            end
        else
            if dyn.on and dyn.n < 5 then dyn.n = dyn.n + 1 end   -- clear: stretch the hops again
            nap(cfg.stepDelay + math.random(0, 100))
        end
    end
    return false
end

local function FindPath(tx, ty)
    local okMap = pcall(ensureMap)
    if not okMap or MAP.fg == nil then return FindPathSimple(tx, ty) end
    tx = math.max(0, math.min(WORLD_W - 1, tx))
    ty = math.max(0, math.min(WORLD_H - 1, ty))
    if px() == tx and py() == ty then return end

    if smartWalk(tx, ty) then return end
    if not S.running then return end

    -- blocks may have been placed / broken since the scan: read the world again and try once more
    pcall(scanMap)
    MAP.blocked = {}
    if smartWalk(tx, ty) then return end
    if not S.running then return end
    if px() == tx and py() == ty then return end

    -- last resorts, neither looks like a jump: one short run of the game's own pathfinder when close, then the old stepper
    if math.abs(tx - px()) + math.abs(ty - py()) <= 12 then
        hop(tx, ty)
        if px() == tx and py() == ty then return end
    end
    FindPathSimple(tx, ty)
    if px() ~= tx or py() ~= ty then
        say("`4[Auto Geiger] `wCouldn't get to " .. tx .. "," .. ty .. " (stopped at " .. px() .. "," .. py() .. ").")
    end
end

---------------- CONFIG SAVE / LOAD ------------------
local function saveConfig(silent)
    local lines = {}
    for _, k in ipairs(SAVE_KEYS) do
        local v = cfg[k]
        if type(v) == "boolean" then v = v and "true" or "false" end
        lines[#lines + 1] = k .. "=" .. tostring(v)
    end
    local data = table.concat(lines, "\n") .. "\n"

    local order = {}
    if S.cfgPath then order[1] = S.cfgPath end
    for _, p in ipairs(CONFIG_PATHS) do order[#order + 1] = p end

    for _, p in ipairs(order) do
        local ok, f = pcall(io.open, p, "w")
        if ok and f then
            local wok = pcall(function() f:write(data) f:close() end)
            if wok then
                S.cfgPath = p
                if not silent then setMsg("Config saved (" .. p .. ")", true) end
                return true
            end
        end
    end
    if not silent then setMsg("Could not save config (no writable path)", false) end
    return false
end

local function loadConfig(silent)
    for _, p in ipairs(CONFIG_PATHS) do
        local ok, f = pcall(io.open, p, "r")
        if ok and f then
            local rok, data = pcall(function() local d = f:read("*a") f:close() return d end)
            if rok and data and data ~= "" then
                for line in data:gmatch("[^\r\n]+") do
                    local k, v = line:match("^(%w+)=(.*)$")
                    if k and SAVE_SET[k] and cfg[k] ~= nil then
                        if type(cfg[k]) == "boolean" then cfg[k] = (v == "true")
                        elseif type(cfg[k]) == "number" then cfg[k] = tonumber(v) or cfg[k]
                        else cfg[k] = v end
                    end
                end
                cfg.stepTiles = math.max(1, cfg.stepTiles)
                cfg.stepDelay = math.max(0, cfg.stepDelay)
                cfg.collectTries = math.max(0, cfg.collectTries)
                cfg.breakMin  = math.max(1, cfg.breakMin)
                cfg.lowGeiger = math.max(0, cfg.lowGeiger)
                S.cfgPath = p
                if not silent then setMsg("Config loaded", true) end
                return true
            end
        end
    end
    if not silent then setMsg("No saved config found", false) end
    return false
end

---------------- DISCORD WEBHOOK ----------------------
local function siz(str)                          -- clean a Growtopia display name
    str = str:gsub("Dr%.", "")
    str = str:gsub("``", ""):gsub("`.", ""):gsub("@", ""):gsub(" of Legend", "")
    str = str:gsub("%[BOOST%]", ""):gsub("%[ELITE%]", ""):gsub("`w", "")
    return str
end

local function jsonEscape(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", ""):gsub("\t", "\\t")
    return s
end

local function sendFoundWebhook()
    local url = trim(cfg.webhookUrl)
    if not cfg.webhookEnabled or url == "" then return end

    local items = ""
    for i, name in ipairs(ITEM_NAMES) do
        if S.found[i] > 0 then items = items .. name .. " : " .. S.found[i] .. "\n" end
    end
    for _, name in ipairs(S.otherNames) do
        items = items .. name .. " : " .. S.other[name] .. "\n"
    end
    if items == "" then items = "-" end

    local okN, player = pcall(function() return siz(GetLocal().name):match("%S+") end)
    if not okN or not player then player = "Unknown" end
    local world = curWorld()
    if world == "" then world = "UNKNOWN" end

    local data = '{"embeds":[{"title":"Geiger Webhook","fields":['
        .. '{"name":"<a:aOnline:1089435878583173200> Player Name","value":"' .. jsonEscape(player) .. '","inline":false},'
        .. '{"name":"<:growscan:1210567190022070312> Found Items","value":"' .. jsonEscape(items) .. '","inline":true},'
        .. '{"name":"<:globee:1326955204263805001> World Name","value":"' .. jsonEscape(world) .. '","inline":true}'
        .. '],"color":11393254}]}'
    pcall(MakeRequest, url, "POST", { ["Content-Type"] = "application/json" }, data)
end

---------------- HUNTING LOGIC (from the original) ----
local function doBreak()                         -- step 15 tiles away vertically
    if py() <= 15 then
        FindPath(px(), clamp(py() + 15, 0, 29))
    else
        FindPath(px(), clamp(py() - 15, 0, 29))
    end
    breakLoop = false
end

local function reconnect()
    while S.running and not inWorld(cfg.worldGeiger) do
        setStage("Warping to " .. cfg.worldGeiger, C.yellow)
        warp(cfg.worldGeiger)
        nap(5000)
    end
end

local function renewRing()
    local t0 = os.time()
    while S.running and newRing == false do
        if not inWorld(cfg.worldGeiger) then
            reconnect()
            t0 = os.time()
        end
        nap(500)
        if os.time() - t0 >= 15 then          -- no ring update (e.g. we did not move)
            say("`4[Auto Geiger] `wNo ring update for 15s, continuing.")
            break
        end
    end
    newRing = false
end

local function stepAwayY()                       -- fallback when the ring was lost
    if py() >= 20 then
        FindPath(px(), clamp(py() - 8, 0, 29))
    else
        FindPath(px(), clamp(py() + 8, 0, 29))
    end
end

local function foundYellow()
    local foundPosX = px()
    local foundPosY = py()
    local currentLoc = 2
    local isLeft = false
    local isUp = false

    while true do
        if not S.running then return end
        if breakLoop == true then doBreak() return end
        if itemFound == true then return end
        FindPath(clamp(foundPosX + currentLoc, 0, 29), foundPosY)
        isLeft = false
        renewRing()
        if currentRing ~= yellow then break end
        FindPath(clamp(foundPosX - currentLoc, 0, 29), foundPosY)
        isLeft = true
        renewRing()
        if currentRing ~= yellow then break end
        currentLoc = currentLoc + 2
    end
    if not S.running then return end

    -- X: Yellow -> Red
    if currentRing == red then
        FindPath(clamp(px() + (isLeft and 12 or -12), 0, 29), foundPosY)
        renewRing()
        if currentRing ~= green then
            stepAwayY()
            return
        end
        nap(5000)
    -- X: Yellow -> Green
    elseif currentRing == green then
        FindPath(clamp(px() + (isLeft and -4 or 4), 0, 29), foundPosY)
        nap(5000)
    end

    -- Reset for the Y axis
    foundPosX = px()
    foundPosY = py()
    currentLoc = 1

    while true do
        if not S.running then return end
        if breakLoop == true then doBreak() return end
        if itemFound == true then return end
        FindPath(foundPosX, clamp(foundPosY + currentLoc, 0, 29))
        isUp = false
        renewRing()
        if currentRing ~= green then break end
        FindPath(foundPosX, clamp(foundPosY - currentLoc, 0, 29))
        isUp = true
        renewRing()
        if currentRing ~= green then break end
        currentLoc = currentLoc + 1
    end

    -- Y: Green -> Yellow
    if currentRing == yellow then
        FindPath(foundPosX, clamp(py() + (isUp and 5 or -5), 0, 29))
        nap(5000)
    end
end

local function foundGreen()
    local foundPosX = px()
    local foundPosY = py()
    local currentLocX = 1
    local isLeft = false
    local isUp = false

    while true do
        if not S.running then return end
        if breakLoop == true then doBreak() return end
        if itemFound == true then return end
        FindPath(clamp(foundPosX + currentLocX, 0, 29), foundPosY)
        isLeft = false
        renewRing()
        if currentRing ~= green then break end
        FindPath(clamp(foundPosX - currentLocX, 0, 29), foundPosY)
        isLeft = true
        renewRing()
        if currentRing ~= green then break end
        currentLocX = currentLocX + 1
    end
    if not S.running then return end

    -- X: Green -> Yellow
    if currentRing == yellow then
        FindPath(clamp(px() + (isLeft and 5 or -5), 0, 29), foundPosY)
        nap(5000)
    end

    -- Reset for the Y axis
    foundPosX = px()
    foundPosY = py()
    local currentLocY = 1

    while true do
        if not S.running then return end
        if breakLoop == true then doBreak() return end
        if itemFound == true then return end
        FindPath(foundPosX, clamp(foundPosY + currentLocY, 0, 29))
        isUp = false
        renewRing()
        if currentRing ~= green then break end
        FindPath(foundPosX, clamp(foundPosY - currentLocY, 0, 29))
        isUp = true
        renewRing()
        if currentRing ~= green then break end
        currentLocY = currentLocY + 1
    end

    -- Y: Green -> Yellow
    if currentRing == yellow then
        FindPath(foundPosX, clamp(py() + (isUp and 5 or -5), 0, 29))
        nap(5000)
    end
end

-- The alive geigers lie at the geiger spot and are picked up by standing there. Check that the count
-- really went up; if not, walk beside the spot and back and wait again, until it works. cfg.collectTries
-- caps the rounds (0 = keep trying until it works or you press Stop) so an empty spot can't hang it.
local function collectAlive(before)
    if before == nil then nap(3000) return true end      -- can't read the inventory: just wait like before
    local offsets = { 0, -1, 1, -2, 2 }
    local round = 0
    while S.running do
        round = round + 1
        setStage("Collecting alive geigers" .. (round > 1 and (" (try " .. round .. ")") or ""), C.cyan)
        if round > 1 then                                -- nudge: step beside the spot and back
            local off = offsets[((round - 1) % #offsets) + 1]
            FindPath(math.max(0, cfg.alivePosX + off), cfg.alivePosY)
            nap(400)
            FindPath(cfg.alivePosX, cfg.alivePosY)
        end
        local ax, ay = px(), py()
        if math.abs(ax - cfg.alivePosX) + math.abs(ay - cfg.alivePosY) > 3 then
            say("`4[Auto Geiger] `wNot at the geiger spot (" .. cfg.alivePosX .. "," .. cfg.alivePosY
                .. "), standing at " .. ax .. "," .. ay .. " - check the spot in Settings.")
        end
        -- wait for the pickup; once the count starts rising give it a moment more for the rest
        local waited, best = 0, before
        while S.running and waited < 3000 do
            nap(250)
            waited = waited + 250
            local now = getItemCount(2204)
            if now and now > best then best, waited = now, 1500 end
        end
        if best > before then
            say("`2[Auto Geiger] `wCollected " .. (best - before) .. " alive geigers.")
            return true
        end
        if cfg.collectTries > 0 and round >= cfg.collectTries then
            say("`4[Auto Geiger] `wNo alive geigers picked up after " .. round .. " tries.")
            return false
        end
        if round == 1 or round % 5 == 0 then
            say("`4[Auto Geiger] `wAlive geigers not collected yet, trying again...")
        end
    end
    return false
end

local function fullAFKBody()
    local aliveBefore = getItemCount(2204)                -- to see whether the pickup worked
    setStage("Warping to " .. cfg.worldSave, C.yellow)
    warp(cfg.worldSave)
    nap(5000)
    while S.running and not inWorld(cfg.worldSave) do
        nap(5000)
        warp(cfg.worldSave)
    end
    if not S.running then return end
    FindPath(cfg.alivePosX, cfg.alivePosY)

    collectAlive(aliveBefore)
    if not S.running then return end
    setStage("Dropping items", C.cyan)
    canDrop = true
    local passes = 0
    local itemDrop = cfg.itemDropX
    local deadDrop = cfg.deadDropX

    local loop = true
    while loop and S.running do
        if breakLoop == true then doBreak() return end
        passes = passes + 1
        if passes > 40 then say("`4[Auto Geiger] `wCan't drop everything here, moving on.") break end
        loop = false
        FindPath(itemDrop, cfg.itemDropY)
        nap(500)
        for _, cur in pairs(GetInventory()) do
            if not S.running then return end
            if DROP_IDS[cur.id] then
                loop = true
                nap(500)
                SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. cur.id .. "|\nitem_count|" .. cur.amount .. "\n")
                nap(500)
                if canDrop == false then itemDrop = math.max(1, itemDrop - 1) canDrop = true end
            elseif TRASH_IDS[cur.id] then
                SendPacket(2, "action|dialog_return\ndialog_name|trash\nitem_trash|" .. cur.id .. "|\nitem_count|" .. cur.amount .. "\n")
                nap(500)
                if canDrop == false then itemDrop = math.max(1, itemDrop - 1) canDrop = true end
            end
        end
    end

    setStage("Dropping dead geigers", C.cyan)
    local deadBefore = getItemCount(2286)
    loop = true
    passes = 0
    while loop and S.running do
        if breakLoop == true then doBreak() return end
        passes = passes + 1
        if passes > 40 then say("`4[Auto Geiger] `wCan't drop the dead geigers here, moving on.") break end
        loop = false
        FindPath(deadDrop, cfg.deadDropY)
        nap(500)
        for _, cur in pairs(GetInventory()) do
            if not S.running then return end
            if cur.id == 2286 then
                loop = true
                SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. cur.id .. "|\nitem_count|" .. cur.amount .. "\n")
                nap(500)
                if canDrop == false then deadDrop = math.max(1, deadDrop - 1) canDrop = true end
            end
        end
    end

    local deadAfter = getItemCount(2286)
    if deadBefore and deadAfter and deadBefore > deadAfter then
        S.deadDropped = S.deadDropped + (deadBefore - deadAfter)
    end

    setStage("Returning to " .. cfg.worldGeiger, C.yellow)
    warp(cfg.worldGeiger)
    nap(5000)
    while S.running and not inWorld(cfg.worldGeiger) do
        nap(5000)
        warp(cfg.worldGeiger)
    end
end

-- The save-world trip (collect alive geigers, drop items, drop dead geigers) walks with the dynamic hop size.
local function fullAFK()
    dyn.on, dyn.n = cfg.dynSteps, 5
    local ok, err = pcall(fullAFKBody)
    dyn.on = false
    if not ok then error(err, 0) end
end

local stopRun                                 -- defined below (START / STOP)

-- Go to the save world when geigers are low - but only if that can help.
-- If a previous trip did not bring the count back above the limit (nothing
-- to restock), keep using what is left and only go once more at 0.
local function afkNeeded()
    if aliveGeiger <= 0 then return true end
    return aliveGeiger <= cfg.lowGeiger and not S.noRestock
end

local function mainLoop()
    -- auto warp to the geiger world if we are not already there
    if not inWorld(cfg.worldGeiger) then
        say("`2[Auto Geiger] `wNot in `9" .. cfg.worldGeiger .. "`w, warping there first.")
        reconnect()
        if not S.running then return end
        nap(3000)                             -- let the world finish loading
        if not S.running then return end
    end

    local n = getItemCount(2204)
    if n == nil then
        say("`4[Auto Geiger] `wCan't read your inventory, geiger count unknown.")
        n = 999
        S.geigerLeft = nil
    else
        S.geigerLeft = n
    end
    aliveGeiger = n
    S.geigerStart = math.max(1, n)

    while S.running do
        if breakLoop == true then doBreak() end
        setStage("Searching", C.green)
        for i in ipairs(redPosX) do
            if not S.running then return end
            if itemFound == true then
                currentRing = red
                break
            end
            if currentRing ~= red then break end
            FindPath(redPosX[i], redPosY[i])
            renewRing()
        end
        if not S.running then return end

        if currentRing == yellow then
            setStage("Yellow ring", C.yellow)
            foundYellow()
        elseif currentRing == green then
            setStage("Green ring", C.green)
            foundGreen()
        end
        local foundThis = itemFound
        itemFound = false
        if foundThis then nap(500) end        -- let the inventory update
        local c = getItemCount(2204)
        if c ~= nil then
            aliveGeiger = c
        elseif foundThis then
            aliveGeiger = aliveGeiger - 1     -- can't read it: only a find uses one up
        end
        if S.geigerLeft then S.geigerLeft = math.max(0, aliveGeiger) end
        if aliveGeiger > cfg.lowGeiger then S.noRestock = false end

        -- only decide after a find (or at 0): an empty sweep must never trigger a trip
        if (foundThis or aliveGeiger <= 0) and afkNeeded() then
            fullAFK()
            if not S.running then return end
            local c = getItemCount(2204)
            if c ~= nil then
                aliveGeiger = c
                S.geigerLeft = c
                S.geigerStart = math.max(S.geigerStart, c, 1)
            end
            S.noRestock = aliveGeiger <= cfg.lowGeiger
            if aliveGeiger <= 0 then
                stopRun("out of geigers.")
                return
            end
            if S.noRestock then
                say("`2[Auto Geiger] `wNo more geigers to pick up, using the " .. aliveGeiger .. " left.")
            end
        end
    end
end

---------------- START / STOP -------------------------
function stopRun(reason)
    if not S.running then return end
    S.running = false
    S.runAccum = S.runAccum + (os.time() - S.startedAt)
    setStage("Stopping", C.yellow)
    say("`4[Auto Geiger] Stopped: `w" .. (reason or "stopped by user."))
end

local function startRun()
    if S.threadAlive then setMsg("Still stopping, try again in a second.", false) return end
    saveConfig(true)
    currentRing, newRing, itemFound, breakLoop = red, false, false, false
    S.ring = "Red"
    S.noRestock = false
    MAP.fg, MAP.blocked = nil, {}                -- re-read the world's blocks on the first move
    S.running   = true
    S.threadAlive = true
    S.startedAt = os.time()
    S.lastBreak = os.time()
    setStage("Searching", C.green)
    say("`2[Auto Geiger] Started. Geiger world: `9" .. cfg.worldGeiger)
    RunThread(function()
        local ok, err = pcall(mainLoop)
        if not ok then say("`4[Auto Geiger] Error: `w" .. tostring(err)) end
        if S.running then
            S.running = false
            S.runAccum = S.runAccum + (os.time() - S.startedAt)
        end
        S.threadAlive = false
        setStage("Idle", C.white)
    end)
end

---------------- HOOKS --------------------------------
local function ringHook(packet)
    if not S.running then return false end
    if packet.type ~= 17 then return false end
    -- real geiger rings always come with yspeed 114; titles (e.g. Mythical) spam
    -- type 17 particle packets with other yspeeds (62, 32...) that must be ignored
    if math.abs(packet.yspeed - 114) > 0.5 then return false end
    if packet.xspeed == 2.00 then
        log("`2Green...")
        currentRing = green
        S.ring = "Green"
    elseif packet.xspeed == 1.00 then
        log("`9Yellow...")
        currentRing = yellow
        S.ring = "Yellow"
    else
        log("`4Red...")
        currentRing = red
        S.ring = "Red"
    end
    newRing = true
    return false
end

local function foundHook(varlist)
    if not S.running then return false end
    local name = tostring(varlist[0] or "")
    local msg  = tostring(varlist[1] or "")

    if cfg.debug and name:find("OnConsoleMessage") and msg:find("Given", 1, true) then
        say("`8[dbg] `w" .. msg)
    end

    if name:find("OnConsoleMessage") and (msg:find("oGiven") or msg:find("Given `w", 1, true)) then
        local idx
        if msg:find("Stuff") then idx = 1
        elseif msg:find("Crystal") then
            if     msg:find("Black") then idx = 2
            elseif msg:find("Green") then idx = 3
            elseif msg:find("Red")   then idx = 4
            elseif msg:find("White") then idx = 5 end
        elseif msg:find("Haunted")     then idx = 6
        elseif msg:find("Radioactive") then idx = 7
        elseif msg:find("Growtoken")   then idx = 8
        elseif msg:find("`w1 Battery") then idx = 9
        elseif msg:find("D Battery")   then idx = 10
        elseif msg:find("Charger")     then idx = 11 end

        if idx then
            S.found[idx] = S.found[idx] + 1
        else
            -- not one of the known items (e.g. a new crystal): count it by its own name
            local plain = msg:gsub("`.", "")
            local nm = plain:match("Given%s+%d+%s+(.-)%s*[%.!]*%s*$")
                    or plain:match("Given%s+(.-)%s*[%.!]*%s*$") or plain
            nm = trim(nm)
            if nm == "" then nm = "Unknown item" end
            if S.other[nm] == nil then
                S.other[nm] = 0
                S.otherNames[#S.otherNames + 1] = nm
            end
            S.other[nm] = S.other[nm] + 1
        end
        S.total = S.total + 1
        sendFoundWebhook()

        local f = S.found
        local txt = string.format([[
Item Found : %d
Stuff : %d
Crystal Black : %d
Crystal Green : %d
Crystal Red : %d
Crystal White : %d
Chemical Haunted : %d
Chemical Radioactive : %d
Growtoken : %d
Battery : %d
D Battery : %d
Geiger Charger : %d
]], S.total, f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8], f[9], f[10], f[11])
        for _, nm in ipairs(S.otherNames) do txt = txt .. nm .. " : " .. S.other[nm] .. "\n" end
        log(txt)
        itemFound = true
    end
    if name:find("OnTextOverlay") and msg:find("You can't drop") then
        canDrop = false
    end
    return false
end

AddHook("onvariant", "gwk_found", foundHook)
AddHook("onprocesstankupdatepacket", "gwk_ring", ringHook)

---------------- MENU ----------------------------------
local DEFAULTS = {}                           -- snapshot for the "Default" button
for _, k in ipairs(SAVE_KEYS) do DEFAULTS[k] = cfg[k] end

local tab  = 1
local TABS = { "Stats", "Items", "Settings", "WebHook", "Advanced" }

local function intInput(label, key, min)
    local _, v = ImGui.InputInt(label, cfg[key])
    if v then cfg[key] = math.max(min, v) end
end

local function textInput(label, key, len)
    local _, v = ImGui.InputText(label, cfg[key], len)
    if v then cfg[key] = v end
end

local function resetCount()
    S.found = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    S.other, S.otherNames = {}, {}
    S.total, S.runAccum = 0, 0
    S.deadOffset = S.deadDropped + (getItemCount(2286) or 0)
    S.deadShown = 0
    if S.running then S.startedAt = os.time() end
    setMsg("Count reset", true)
end

local function resetDefaults()
    for _, k in ipairs(SAVE_KEYS) do cfg[k] = DEFAULTS[k] end
    setMsg("Settings reset to default", true)
end

local function statusInfo()
    if S.threadAlive and not S.running then return "Stopping", C.yellow end
    if not S.running then return "Idle", C.white end
    return S.stage, S.stageCol or C.green
end

---------------- TAB: STATS ---------------------------
local function tabStats()
    local label, col = statusInfo()
    textColored(col, label)
    ui("SameLine")
    local w = curWorld()
    textColored(C.gray, "   " .. (w ~= "" and w or "unknown"))

    ui("Spacing")
    local left  = S.geigerLeft
    local start = math.max(1, S.geigerStart)
    textColored(C.white, "Alive geiger left   " .. (left and (left .. " / " .. start) or "-"))
    local frac = left and math.min(1, math.max(0, left / start)) or 0
    progressBar(frac)
    textColored(C.gray, "ring: " .. S.ring .. "   items found: " .. S.total
        .. "   AFK at <= " .. cfg.lowGeiger)

    ui("Spacing")
    ImGui.Separator()
    ui("Spacing")

    local elapsed = S.runAccum + (S.running and (os.time() - S.startedAt) or 0)
    local nextBreak = S.running and math.max(0, cfg.breakMin * 60 - (os.time() - S.lastBreak)) or nil

    rowv("Items Found", comma(S.total), C.white)
    ui("Spacing")
    rowv("Dead Geiger", comma(S.deadShown), C.white)
    ui("Spacing")
    rowv("Current Ring", S.ring, C.white)
    ui("Spacing")
    rowv("Run Time", fmtClock(elapsed), C.white)
    ui("Spacing")
    rowv("Next Break", nextBreak and fmtClock(nextBreak) or "-", C.white)
    ui("Spacing")

    if button("Reset Count", -1, 30) then resetCount() end
end

---------------- TAB: ITEMS ---------------------------
local function tabItems()
    textColored(C.white, "Found this session")
    ui("Spacing")
    for i, name in ipairs(ITEM_NAMES) do
        rowv(name, tostring(S.found[i]), S.found[i] > 0 and C.green or C.gray)
        ui("Spacing")
    end
    for _, nm in ipairs(S.otherNames) do
        rowv(nm, tostring(S.other[nm]), C.green)
        ui("Spacing")
    end
    ImGui.Separator()
    ui("Spacing")
    rowv("Total", comma(S.total), C.white)
    ui("Spacing")
    rowv("Dead Geiger", comma(S.deadShown), C.white)
    ui("Spacing")

    if button("Reset Count", -1, 30) then resetCount() end
end

---------------- TAB: SETTINGS ------------------------
-- Copies the tile you are standing on into the two config values.
local function capturePos(kx, ky, what)
    local ok, x, y = pcall(function() return px(), py() end)
    if ok and x and y then
        cfg[kx], cfg[ky] = x, y
        setMsg(what .. " set to " .. x .. ", " .. y, true)
    else
        setMsg("Could not read your position.", false)
    end
end

local function tabSettings()
    textInput("Geiger world", "worldGeiger", 32)
    textColored(C.gray, "Where the geigers are used.")
    textInput("Save world", "worldSave", 32)
    textColored(C.gray, "Where items / dead geigers are dropped.")

    ui("Spacing")
    ImGui.Separator()
    textColored(C.white, "Positions in the save world")
    local okp, mx, my = pcall(function() return px(), py() end)
    textColored(C.gray, "You are standing at: " .. (okp and (mx .. ", " .. my) or "unknown"))
    textColored(C.gray, "Stand on the spot in the save world, then press Capture.")
    ui("Spacing")

    intInput("Geiger spot X", "alivePosX", 0)
    intInput("Geiger spot Y", "alivePosY", 0)
    if button(" Capture geiger spot ") then capturePos("alivePosX", "alivePosY", "Geiger spot") end
    ui("Spacing")

    intInput("Item drop X", "itemDropX", 0)
    intInput("Item drop Y", "itemDropY", 0)
    if button(" Capture item drop ") then capturePos("itemDropX", "itemDropY", "Item drop") end
    ui("Spacing")

    intInput("Dead drop X", "deadDropX", 0)
    intInput("Dead drop Y", "deadDropY", 0)
    if button(" Capture dead drop ") then capturePos("deadDropX", "deadDropY", "Dead drop") end

    ui("Spacing")
    ImGui.Separator()
    intInput("AFK when geiger <=", "lowGeiger", 0)
    textColored(C.gray, "Goes to the save world to drop items and restock at this many geigers left.")
    textColored(C.gray, "If it cannot restock, it uses the rest, drops once at 0 and stops.")
end

---------------- TAB: WEBHOOK -------------------------
local function tabWebhook()
    textColored(C.white, "Discord Webhook")
    textColored(C.gray, "Posts an embed to Discord every time an item is found.")
    ui("Spacing")

    textInput("Webhook URL", "webhookUrl", 256)
    ui("Spacing")

    if button(" Webhook: " .. (cfg.webhookEnabled and "ON" or "OFF") .. " ") then
        cfg.webhookEnabled = not cfg.webhookEnabled
    end
    ui("SameLine")
    if button(" Send test ping ") then
        if trim(cfg.webhookUrl) == "" then
            setMsg("Set a webhook URL first.", false)
        else
            local was = cfg.webhookEnabled
            cfg.webhookEnabled = true
            sendFoundWebhook()
            cfg.webhookEnabled = was
            setMsg("Test ping sent - check Discord.", true)
        end
    end
end

---------------- TAB: ADVANCED ------------------------
local function tabAdvanced()
    intInput("Max tiles per hop", "stepTiles", 1)
    textColored(C.gray, "Lower = slower / safer.")
    intInput("Hop delay (ms)", "stepDelay", 0)
    textColored(C.gray, "Higher = slower / safer.")
    ui("Spacing")
    if button(" Dynamic hops 1-5 on save-world trips: " .. (cfg.dynSteps and "ON" or "OFF") .. " ") then
        cfg.dynSteps = not cfg.dynSteps
    end
    textColored(C.gray, "Pick up / drop trips start with 5-tile hops and shrink to 1 where it is blocked.")
    intInput("Pick-up tries (0 = until done)", "collectTries", 0)
    textColored(C.gray, "Alive geigers not picked up at the geiger spot: how many times to retry.")
    ui("Spacing")
    intInput("Break every (min)", "breakMin", 1)
    textColored(C.gray, "Every X minutes the bot steps 15 tiles away for a moment.")
    ui("Spacing")
    if button(" Debug (log found messages): " .. (cfg.debug and "ON" or "OFF") .. " ") then
        cfg.debug = not cfg.debug
    end
    textColored(C.gray, "Prints every item message to the console - use it if an item isn't counted.")
end

---------------- DRAW ---------------------------------
local function drawBody()
    ------------- START / STOP (full width) -------------
    if S.threadAlive and not S.running then
        textColored(C.yellow, "Stopping... please wait a second.")
    elseif not S.running then
        if bigButton(">  START GEIGER") then startRun() end
    else
        if bigButton("[]  STOP GEIGER",
            { 0.72, 0.20, 0.20, 1 }, { 0.85, 0.26, 0.26, 1 }, { 0.60, 0.15, 0.15, 1 }) then
            stopRun("stopped by user.")
        end
    end

    ------------- CONFIG -------------------
    section("CONFIG")
    textColored(C.gray, S.cfgPath or "autogeiger_config.txt")
    ui("SameLine")
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    ------------- TABS ---------------------
    tab = navBegin(TABS, tab)

    if     tab == 1 then tabStats()
    elseif tab == 2 then tabItems()
    elseif tab == 3 then tabSettings()
    elseif tab == 4 then tabWebhook()
    else                 tabAdvanced() end
    navEnd()
end

local drawErrors = 0
-- Break timer + dead geiger count. Runs in its own thread so it keeps working
-- when Growtopia is minimized (the draw hook does not fire then).
local function bgTick()
    -- break timer (the hunt thread picks up breakLoop)
    if S.running and os.time() - S.lastBreak >= cfg.breakMin * 60 then
        S.lastBreak = os.time()
        breakLoop = true
        log("Break")
    end

    -- refresh the dead geiger count about once a second (dropped + in inventory)
    if os.time() - S.deadCheckAt >= 1 then
        S.deadCheckAt = os.time()
        local inv = getItemCount(2286)
        if inv then
            S.deadShown = math.max(0, S.deadDropped + inv - S.deadOffset)
        end
    end
end

local bgAlive = true
local bgThreaded = false
if type(RunThread) == "function" and type(Sleep) == "function" then
    bgThreaded = pcall(RunThread, function()
        while bgAlive do
            pcall(bgTick)
            Sleep(250)
        end
    end)
end

AddHook("ondraw", "gwk_menu", function(dt)
    if not bgThreaded then bgTick() end

    local nc, nv = pushTheme()
    beginWindow("Auto Geiger", 600, 520)
    local widthPushed = ui("PushItemWidth", 240 * UI_SCALE)
    returnButton()

    if drawErrors < 3 then
        local ok, err = pcall(drawBody)
        if not ok then
            drawErrors = drawErrors + 1
            say("`4[Auto Geiger] Menu error: `w" .. tostring(err))
        end
    end

    if widthPushed then ui("PopItemWidth") end
    navEnd()
    ImGui.End()
    popTheme(nc, nv)
end)

math.randomseed(os.time())
loadConfig(true)                              -- load saved settings on startup
say("`2[Auto Geiger] loaded." .. (S.cfgPath and " Config loaded." or ""))

ACTIVE.stop = function() bgAlive = false stopRun("returned to loader.") end

end  -- startGeiger

local function startAutoCrystal()
--====================================================
--  AUTO CRYSTAL COMBINE
--  Stand on (or set) your combiner tile, pick a recipe, press START.
--  Places the crystals in order, punches, waits for the result, and
--  loops until the amount is done or you run out of crystals.
--====================================================

---------------- RECIPES (from your screenshot) ----------------
-- R=red 2242, G=green 2244, B=blue 2246, W=white 2248, K=black 2250
local CRYSTAL = { R = 2242, G = 2244, B = 2246, W = 2248, K = 2250, FIST = 18 }
local COLOR_ORDER = { "R", "G", "B", "W", "K" }        -- place order: red, green, blue, white, black
local COLOR_NAME  = { R = "Red", G = "Green", B = "Blue", W = "White", K = "Black" }

local RECIPES = {
    { name = "Crystal Tree",            amt = 3,  R = 0, G = 2, B = 3, W = 0, K = 0 },
    { name = "Crystal Spikes",          amt = 5,  R = 2, G = 0, B = 3, W = 0, K = 0 },
    { name = "Crystal Clock",           amt = 1,  R = 0, G = 2, B = 1, W = 2, K = 0 },
    { name = "Crystal Gate",            amt = 1,  R = 3, G = 0, B = 1, W = 1, K = 0 },
    { name = "Stained Glass",           amt = 10, R = 1, G = 2, B = 2, W = 0, K = 0 },
    { name = "Shifty Block",            amt = 5,  R = 2, G = 1, B = 1, W = 1, K = 0 },
    { name = "Sapphire Block",          amt = 1,  R = 0, G = 0, B = 5, W = 0, K = 0 },
    { name = "Yellow Diamond",          amt = 1,  R = 2, G = 2, B = 0, W = 1, K = 0 },
    { name = "Steam Lamp",              amt = 3,  R = 2, G = 2, B = 1, W = 0, K = 0 },
    { name = "Gilded Frame",            amt = 20, R = 3, G = 2, B = 0, W = 0, K = 0 },
    { name = "Golden Cave Crystal",     amt = 1,  R = 2, G = 2, B = 0, W = 0, K = 1 },
    { name = "Amethyst Block",          amt = 1,  R = 2, G = 0, B = 2, W = 0, K = 1 },
    { name = "Plasma Globe",            amt = 1,  R = 2, G = 1, B = 0, W = 2, K = 0 },
    { name = "Harmonic Chimes",         amt = 1,  R = 1, G = 0, B = 2, W = 2, K = 0 },
    { name = "Celestial Kaleidoscope",  amt = 1,  R = 1, G = 1, B = 1, W = 2, K = 0 },
    { name = "Kaleidoscopic Wallpaper", amt = 10, R = 1, G = 2, B = 1, W = 1, K = 0 },
    { name = "Demon Crystal",           amt = 1,  R = 3, G = 1, B = 0, W = 0, K = 1 },
}

---------------- SETTINGS ----------------
local cfg = {
    combineX = 0, combineY = 0,     -- the tile you stand on / place into / punch
    recipe   = 6,                   -- index into RECIPES
    amount   = 0,                   -- how many combines to do (0 = infinite, until you run out of crystals)
    placeDelayMs  = 450,            -- gap between placing each crystal
    confirmWaitMs = 4000,           -- how long to wait for "highest vibration" before punching anyway
    punchWaitMs   = 2500,           -- how long to wait for a result after punching
    punchRetries  = 2,              -- extra punches if the first doesn't seem to land
    cycleGapMs    = 600,            -- pause between one combine finishing and the next starting
}

local CONFIG_PATHS = { "autocrystal_config.txt", "scripts/autocrystal_config.txt", "/sdcard/autocrystal_config.txt" }
local SAVE_KEYS = { "combineX", "combineY", "recipe", "amount", "placeDelayMs", "confirmWaitMs",
                    "punchWaitMs", "punchRetries", "cycleGapMs" }
local SAVE_SET = {}
for _, k in ipairs(SAVE_KEYS) do SAVE_SET[k] = true end

---------------- STATE ----------------
local S = {
    running     = false,
    threadAlive = false,
    stage       = "Idle",
    stageCol    = C.white,
    cycles      = 0,                -- successful combines this session
    runCount    = 0,                -- successful combines in the current run
    lastItem    = nil,
    lastQty     = 0,
    resultSeq   = 0,                -- +1 every time a "Collected ..." message arrives
    vibrated    = false,            -- "highest vibration" seen since last full place
    cfgPath     = nil,
    uiMsg = nil, uiOk = true, uiUntil = 0,
    sendCount   = 0,                -- raw packets sent
    template    = nil,              -- copy of a real packet you sent by hand (auto-captured)
    sending     = false,            -- true while WE send, so we don't capture our own packets
}

local function say(msg) LogToConsole(msg) end
local function setMsg(text, ok) S.uiMsg, S.uiOk, S.uiUntil = text, ok, os.time() + 5 end
local function setStage(text, col) S.stage, S.stageCol = text, col end
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function nap(ms)
    local left = ms
    while left > 0 and S.running do
        local s = math.min(250, left)
        Sleep(s)
        left = left - s
    end
end

---------------- INVENTORY ----------------
local function getItemCount(id)
    local ok, n = pcall(function()
        for _, itm in pairs(GetInventory()) do
            if itm.id == id then return itm.amount end
        end
        return 0
    end)
    if ok and type(n) == "number" then return n end
    return nil
end

local function recipeMax(r)                  -- how many times this recipe can be made right now
    local best = nil
    for _, k in ipairs(COLOR_ORDER) do
        local need = r[k] or 0
        if need > 0 then
            local have = getItemCount(CRYSTAL[k])
            if have == nil then return nil end
            local canMake = math.floor(have / need)
            if best == nil or canMake < best then best = canMake end
        end
    end
    return best or 0
end

---------------- CONFIG SAVE / LOAD ----------------
local function saveConfig(silent)
    local lines = {}
    for _, k in ipairs(SAVE_KEYS) do lines[#lines + 1] = k .. "=" .. tostring(cfg[k]) end
    local data = table.concat(lines, "\n") .. "\n"
    local order = {}
    if S.cfgPath then order[1] = S.cfgPath end
    for _, p in ipairs(CONFIG_PATHS) do order[#order + 1] = p end
    for _, p in ipairs(order) do
        local ok, f = pcall(io.open, p, "w")
        if ok and f then
            if pcall(function() f:write(data) f:close() end) then
                S.cfgPath = p
                if not silent then setMsg("Config saved (" .. p .. ")", true) end
                return true
            end
        end
    end
    if not silent then setMsg("Could not save config", false) end
    return false
end

local function loadConfig(silent)
    for _, p in ipairs(CONFIG_PATHS) do
        local ok, f = pcall(io.open, p, "r")
        if ok and f then
            local rok, data = pcall(function() local d = f:read("*a") f:close() return d end)
            if rok and data and data ~= "" then
                for line in data:gmatch("[^\r\n]+") do
                    local k, v = line:match("^(%w+)=(.*)$")
                    if k and SAVE_SET[k] and cfg[k] ~= nil then
                        cfg[k] = tonumber(v) or cfg[k]
                    end
                end
                S.cfgPath = p
                if not silent then setMsg("Config loaded", true) end
                return true
            end
        end
    end
    if not silent then setMsg("No saved config found", false) end
    return false
end

---------------- RAW PACKET SENDING ----------------
local function rawPacket(value, px, py)
    local x, y = 0, 0
    local netid = 0
    pcall(function()
        local p = GetLocal().pos
        x, y = p.x, p.y
    end)
    local pkt = {
        type = 3, value = value, px = px, py = py,
        x = x, y = y, xspeed = 0, yspeed = 0,
        netid = netid, snetid = netid, state = 0,
        padding1 = 0, padding2 = 0, padding4 = 0.0, padding5 = 0,
        dropped = 0, extrasize = 0,
    }
    -- reuse the extra fields (state, speeds, padding) of a real packet you sent by hand
    if S.template then
        local keep = { type = true, value = true, px = true, py = true,
                       x = true, y = true, netid = true }
        for k, v in pairs(S.template) do
            if not keep[k] then pkt[k] = v end
        end
    end
    return pkt
end

local function send(pkt)
    S.sending = true
    local ok = pcall(SendPacketRaw, false, pkt)
    S.sending = false
    S.sendCount = S.sendCount + 1
    return ok
end

-- the real client follows each tile packet (type 3) with a state packet (type 0)
local STATE_PLACE = 3104
local function sendStatePacket(value)
    local pkt = rawPacket(value, cfg.combineX, cfg.combineY)
    pkt.type  = 0
    pkt.state = STATE_PLACE
    return send(pkt)
end

local function sendTile(id)
    local ok = send(rawPacket(id, cfg.combineX, cfg.combineY))
    if ok then sendStatePacket(id) end
    return ok
end

local function sendPlace(colorKey) return sendTile(CRYSTAL[colorKey]) end
local function sendPunch()         return sendTile(CRYSTAL.FIST) end

---------------- HOOKS ----------------
local function onVariant(var)
    local name = tostring(var[0] or "")
    if name == "OnTalkBubble" then
        local txt = tostring(var[2] or var[1] or "")
        if txt:lower():find("highest vibration", 1, true) then S.vibrated = true end
        return false
    end
    if name == "OnConsoleMessage" then
        local clean = tostring(var[1] or (var[2] or "")):gsub("`.", "")
        local qty, item = clean:match("Collected%s+(%d+)%s+(.-)%.?%s*$")
        if qty then
            S.lastQty  = tonumber(qty) or 0
            S.lastItem = trim(item)
            S.resultSeq = S.resultSeq + 1      -- counts EVERY result, even if the amount is the same
        end
    end
    return false
end

local function register(events, hookName, fn)
    local owner = nil
    for i, ev in ipairs(events) do
        local wrapped = function(...)
            if owner == nil then owner = i end
            if owner ~= i then return false end
            return fn(...)
        end
        pcall(AddHook, ev, hookName .. i, wrapped)
    end
end

local TEMPLATE_FIELDS = { "type", "value", "px", "py", "x", "y", "xspeed", "yspeed",
    "netid", "snetid", "state", "padding1", "padding2", "padding4", "padding5",
    "dropped", "extrasize" }

-- silently remembers the last tile packet you sent by hand
local function onSendRaw(pkt)
    if S.sending then return false end
    local ok, t = pcall(function() return pkt.type end)
    if not ok or t ~= 3 then return false end
    local copy = {}
    for _, k in ipairs(TEMPLATE_FIELDS) do
        local okf, v = pcall(function() return pkt[k] end)
        if okf and v ~= nil then copy[k] = v end
    end
    S.template = copy
    return false
end
register({ "onsendpacketraw", "OnSendPacketRaw", "onsendpacket", "OnSendPacket" }, "ac_send", onSendRaw)
register({ "onvariant", "OnVariant" }, "ac_var", onVariant)

---------------- MOVE TO THE COMBINE TILE ----------------
-- Same safe walking as Auto Geiger: small hops, waits to arrive before the
-- next one, never one long jump (long jumps can get you kicked).
local rawFindPath = FindPath                      -- the game's own pathfinder
local STEP_TILES, STEP_DELAY = 5, 300

local function myTile()
    local ok, tx, ty = pcall(function()
        local p = GetLocal().pos
        return math.floor(p.x / 32), math.floor(p.y / 32)
    end)
    if ok then return tx, ty end
    return nil, nil
end

local function limitStep(dx, dy)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= STEP_TILES then return dx, dy end
    local f  = STEP_TILES / len
    local mx = math.floor(math.abs(dx) * f) * (dx < 0 and -1 or 1)
    local my = math.floor(math.abs(dy) * f) * (dy < 0 and -1 or 1)
    if mx == 0 and my == 0 then
        if math.abs(dx) >= math.abs(dy) then mx = (dx < 0) and -1 or 1
        else my = (dy < 0) and -1 or 1 end
    end
    return mx, my
end

local function hop(nx, ny)
    local sx, sy = myTile()
    pcall(rawFindPath, nx, ny)
    local lastx, lasty, still = sx, sy, 0
    for _ = 1, 20 do                              -- at most ~2 seconds
        if not S.running then break end
        nap(100)
        local cx, cy = myTile()
        if cx == nx and cy == ny then return true end
        if cx == lastx and cy == lasty then still = still + 1 else still = 0 end
        lastx, lasty = cx, cy
        if still >= 4 then break end
    end
    local ex, ey = myTile()
    return ex ~= sx or ey ~= sy
end

local function goToTile()
    if type(rawFindPath) ~= "function" then
        say("`4[Auto Crystal] `wFindPath not found - stand on the tile yourself.")
        return true                               -- don't block the run, just skip moving
    end
    setStage("Moving to tile", C.cyan)
    local stuck = 0
    while S.running do
        local cx, cy = myTile()
        if cx == nil then return true end
        local dx, dy = cfg.combineX - cx, cfg.combineY - cy
        if dx == 0 and dy == 0 then nap(400) return true end   -- arrived, let it settle
        local mx, my = limitStep(dx, dy)
        if stuck > 0 then
            mx = (mx > 0) and 1 or ((mx < 0) and -1 or 0)
            my = (my > 0) and 1 or ((my < 0) and -1 or 0)
        end
        if hop(cx + mx, cy + my) then stuck = 0
        else
            stuck = stuck + 1
            if stuck >= 3 then
                say("`4[Auto Crystal] `wBlocked on the way to " .. cfg.combineX .. "," .. cfg.combineY .. " - stopping.")
                return false
            end
        end
        nap(STEP_DELAY + math.random(0, 100))
    end
    return false
end

---------------- ONE COMBINE CYCLE ----------------
-- Returns "ok" / "no-result" / "stopped"
local function runOneCycle(r)
    S.vibrated = false
    local startSeq = S.resultSeq
    local tStart = os.time()

    setStage("Placing crystals", C.cyan)
    for _, k in ipairs(COLOR_ORDER) do
        for i = 1, (r[k] or 0) do
            if not S.running then return "stopped" end
            sendPlace(k)
            nap(cfg.placeDelayMs + math.random(0, 120))
        end
    end
    if not S.running then return "stopped" end

    -- wait for the "highest vibration" cue (don't block forever on it)
    setStage("Waiting for recipe", C.yellow)
    local t0 = os.time()
    while S.running and not S.vibrated and os.time() - t0 < math.ceil(cfg.confirmWaitMs / 1000) do
        nap(200)
    end
    if not S.running then return "stopped" end

    setStage("Punching", C.green)
    local tries, gotResult = 0, false
    while S.running and tries <= cfg.punchRetries and not gotResult do
        tries = tries + 1
        sendPunch()
        local t1 = os.time()
        while S.running and os.time() - t1 < math.ceil(cfg.punchWaitMs / 1000) do
            if S.resultSeq ~= startSeq then gotResult = true break end
            nap(150)
        end
    end
    if not S.running then return "stopped" end

    if gotResult then return "ok" end
    say("`4[Auto Crystal] `wNo result after punching (vibration: " .. (S.vibrated and "yes" or "no")
        .. ", hand-placed packet captured: " .. (S.template and "yes" or "no")
        .. ", took " .. (os.time() - tStart) .. "s) - wrong combo, or the drop wasn't auto-picked up.")
    return "no-result"
end

---------------- MAIN LOOP ----------------
local function mainLoop()
    local r = RECIPES[cfg.recipe]
    S.runCount = 0
    if not goToTile() then
        S.running = false
        S.threadAlive = false
        setStage("Idle", C.white)
        return
    end
    while S.running do
        if cfg.amount > 0 and S.runCount >= cfg.amount then
            say("`2[Auto Crystal] `wDone: " .. S.runCount .. " x " .. r.name .. " combined.")
            break
        end
        local can = recipeMax(r)
        if can == nil then
            say("`4[Auto Crystal] `wCan't read your inventory - stopping.")
            break
        end
        if can <= 0 then
            say("`2[Auto Crystal] `wOut of crystals for " .. r.name .. ". Stopping (" .. S.runCount .. " made).")
            break
        end

        local result = runOneCycle(r)
        if result == "stopped" then break end
        if result ~= "ok" then
            say("`4[Auto Crystal] `wStopping so you don't waste crystals.")
            break
        end
        S.cycles = S.cycles + 1
        S.runCount = S.runCount + 1

        setStage("Cooldown", C.gray)
        nap(cfg.cycleGapMs)
    end
    S.running = false
    S.threadAlive = false
    setStage("Idle", C.white)
end

local function stopRun(reason)
    if not S.running then return end
    S.running = false
    say("`4[Auto Crystal] `wStopping: " .. (reason or "stopped by user."))
end

local function startRun()
    if S.threadAlive then setMsg("Still stopping, try again in a second.", false) return end
    if cfg.combineX == 0 and cfg.combineY == 0 then
        setMsg("Set the combine tile position first (Recipe tab).", false)
        return
    end
    if type(SendPacketRaw) ~= "function" then
        setMsg("SendPacketRaw not found in this executor.", false)
        return
    end
    saveConfig(true)
    S.running, S.threadAlive = true, true
    S.vibrated = false
    setStage("Starting", C.green)
    say("`2[Auto Crystal] `wStarted: " .. RECIPES[cfg.recipe].name)
    RunThread(function()
        local ok, err = pcall(mainLoop)
        if not ok then say("`4[Auto Crystal] `wError: " .. tostring(err)) end
        S.running, S.threadAlive = false, false
        setStage("Idle", C.white)
    end)
end

---------------- MENU ----------------
local DEFAULTS = {}
for _, k in ipairs(SAVE_KEYS) do DEFAULTS[k] = cfg[k] end

local tab  = 1
local TABS = { "Stats", "Recipe", "Advanced" }

local function intInput(label, key, min)
    local _, v = ImGui.InputInt(label, cfg[key])
    if v then cfg[key] = math.max(min, v) end
end

local function resetCount()
    S.cycles = 0
    setMsg("Count reset", true)
end

local function resetDefaults()
    for _, k in ipairs(SAVE_KEYS) do cfg[k] = DEFAULTS[k] end
    setMsg("Settings reset to default", true)
end

local function statusInfo()
    if S.threadAlive and not S.running then return "Stopping", C.yellow end
    if not S.running then return "Idle", C.white end
    return S.stage, S.stageCol
end

local function tabStats()
    local label, col = statusInfo()
    textColored(col, label)
    ui("SameLine")
    textColored(C.gray, "   tile " .. cfg.combineX .. "," .. cfg.combineY)

    ui("Spacing")
    local r = RECIPES[cfg.recipe]
    textColored(C.white, "Recipe: " .. r.name .. "  (makes x" .. r.amt .. ")")
    local can = recipeMax(r)
    rowv("Can make right now", can and tostring(can) or "-", C.cyan)

    ui("Spacing")
    ImGui.Separator()
    ui("Spacing")
    rowv("This run", S.runCount .. " / " .. (cfg.amount > 0 and cfg.amount or "infinite"), C.white)
    rowv("Combined this session", tostring(S.cycles), C.white)
    rowv("Last result", S.lastItem and (S.lastQty .. " x " .. S.lastItem) or "-", C.green)
    rowv("Hand-placed packet", S.template and "captured" or "not captured", S.template and C.green or C.yellow)
    ui("Spacing")

    if button("Reset Count", -1, 30) then resetCount() end
end

---------------- TAB: RECIPE ----------------
local function tabRecipe()
    textColored(C.white, "Combine tile (stand here, place and punch here)")
    local okp, mx, my = pcall(function() local p = GetLocal().pos return p.x // 32, p.y // 32 end)
    textColored(C.gray, "You are standing at: " .. (okp and (mx .. ", " .. my) or "unknown"))
    intInput("Tile X", "combineX", 0)
    intInput("Tile Y", "combineY", 0)
    if button(" Capture (use my position) ") then
        if okp then
            cfg.combineX, cfg.combineY = mx, my
            setMsg("Combine tile set to " .. mx .. ", " .. my, true)
        else
            setMsg("Could not read your position.", false)
        end
    end

    ui("Spacing")
    ImGui.Separator()
    textColored(C.white, "Recipe")
    local r = RECIPES[cfg.recipe]
    if button(" < ", 40) then cfg.recipe = (cfg.recipe - 2) % #RECIPES + 1 end
    ui("SameLine")
    textColored(C.white, "  " .. r.name .. "  (" .. cfg.recipe .. "/" .. #RECIPES .. ")")
    ui("SameLine")
    if button(" > ", 40) then cfg.recipe = (cfg.recipe % #RECIPES) + 1 end
    r = RECIPES[cfg.recipe]       -- re-read, in case a button above just changed it

    ui("Spacing")
    intInput("Amount (0 = infinite)", "amount", 0)

    ui("Spacing")
    textColored(C.gray, "Needs (place in this order):")
    for _, k in ipairs(COLOR_ORDER) do
        local need = r[k] or 0
        if need > 0 then
            local have = getItemCount(CRYSTAL[k])
            rowv(COLOR_NAME[k] .. " Crystal", need .. "x   (have " .. tostring(have or "?") .. ")",
                (have and have >= need) and C.green or C.red)
        end
    end
    ui("Spacing")
    textColored(C.gray, "Makes " .. r.amt .. " x " .. r.name .. " per combine.")
end

local function tabAdvanced()
    intInput("Place delay (ms)", "placeDelayMs", 100)
    intInput("Wait for vibration (ms)", "confirmWaitMs", 500)
    intInput("Wait after punch (ms)", "punchWaitMs", 500)
    intInput("Punch retries", "punchRetries", 0)
    intInput("Gap between combines (ms)", "cycleGapMs", 0)
end

---------------- DRAW ----------------
local function drawBody()
    if S.threadAlive and not S.running then
        textColored(C.yellow, "Stopping... please wait a second.")
    elseif not S.running then
        if bigButton(">  START COMBINE") then startRun() end
    else
        if bigButton("[]  STOP COMBINE",
            { 0.72, 0.20, 0.20, 1 }, { 0.85, 0.26, 0.26, 1 }, { 0.60, 0.15, 0.15, 1 }) then
            stopRun("stopped by user.")
        end
    end

    section("CONFIG")
    textColored(C.gray, S.cfgPath or "autocrystal_config.txt")
    ui("SameLine")
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    tab = navBegin(TABS, tab)

    if     tab == 1 then tabStats()
    elseif tab == 2 then tabRecipe()
    else                 tabAdvanced() end
    navEnd()
end

local drawErrors = 0
AddHook("ondraw", "ac_menu", function(dt)
    local nc, nv = pushTheme()
    beginWindow("Auto Crystal Combine", 600, 520)
    local widthPushed = ui("PushItemWidth", 220)
    returnButton()

    if drawErrors < 3 then
        local ok, err = pcall(drawBody)
        if not ok then
            drawErrors = drawErrors + 1
            say("`4[Auto Crystal] `wMenu error: " .. tostring(err))
        end
    end

    if widthPushed then ui("PopItemWidth") end
    navEnd()
    ImGui.End()
    popTheme(nc, nv)
end)

math.randomseed(os.time())
loadConfig(true)
say("`2[Auto Crystal] `wloaded." .. (S.cfgPath and " Config loaded." or "")
    .. (type(SendPacketRaw) == "function" and "" or " `4WARNING: SendPacketRaw not found!"))

ACTIVE.stop = function() stopRun("returned to loader.") end

end  -- startAutoCrystal

--====================================================
--  AUTO GEIGER CHARGER v2  (module for Ben Loader)
--
--  Uses the loader's shared helpers (C, ui, textColored, section, button,
--  bigButton, colorButton, rowv, progressBar, pushTheme, popTheme).
--
--  HOW IT WORKS
--    1. Scans the whole world once (tile ids + collision) and finds every
--       Geiger Charger. Chargers are SOLID, so it never walks into them.
--    2. Finds every free tile you could stand on (open space with ground
--       under it) that is connected to where you are, then picks the
--       smallest set of "stops" that covers all chargers within punch reach.
--    3. Walks stop to stop along real walkable tiles (own path search,
--       then the game's FindPath for each short hop).
--    4. At each stop it punches (retrieve) / places a dead geiger (charge)
--       on every charger in reach. Success = your inventory changed.
--
--  EMPTY / FILLED
--    A charger's state lives in its tile "extra data" (the server sends a
--    13-byte tile update every time it changes). The script reads whatever
--    your executor exposes; if that can't tell empty from filled it simply
--    PROBES: punch once -> a geiger comes out = it was filled.
--====================================================
local function startAutoCharger()

---------------- SETTINGS (defaults) -----------------
local cfg = {
    world        = "",      -- world with the chargers (blank = current world, no warping)
    wallpaperId  = 0,       -- wallpaper (background) id placed behind every Geiger Charger (0 = not set)
    deadId       = 2286,    -- dead geiger (what you put into a charger)
    aliveId      = 2204,    -- charged geiger (what comes out)
    mode         = 3,       -- 1 retrieve only, 2 charge only, 3 retrieve + charge
    perCharger   = false,   -- false: retrieve ALL then charge ALL | true: both at every stop
    actionDelay  = 100,     -- ms pause after each punch / place
    waitResultMs = 200,     -- ms to wait for the inventory to change after an action
    stepTiles    = 4,       -- max tiles per walking hop (lower = safer)
    stepDelay    = 100,     -- minimum ms between hops
    msPerTile    = 100,     -- walking pace: wait this long per tile moved (anti speed-hack)
    standOnTop   = true,    -- stand on top of the chargers (the tile above one) when possible
    dropOn       = true,    -- drop alive geigers when the stack is full
    fullAt       = 250,     -- alive geiger count that counts as full
    dropX        = 0,       -- drop spot (tile x)
    dropY        = 0,       -- drop spot (tile y)
    walkOrder    = 2,       -- 1 = nearest next, 2 = left side first, 3 = right side first
    vertDown     = true,    -- inside a side: true = top to bottom, false = bottom to top
    reachX       = 3,       -- punch / place reach left+right (tiles, rectangle)
    reachY       = 3,       -- punch / place reach up+down (tiles, rectangle)
    allowJump    = false,   -- no safe route found: allow ONE long jump with the game's pathfinder (flagged by speed-hack check)
    takeOn       = true,    -- out of dead geigers: walk to the take spot and pick some up
    takeX        = 0,       -- take spot (tile x) - where the dead geigers lie on the floor
    takeY        = 0,       -- take spot (tile y)
    repeatMin    = 0,       -- 0 = run once, otherwise repeat every X minutes
    debug        = false,
}

local CONFIG_PATHS = { "autocharger_config.txt", "scripts/autocharger_config.txt", "/sdcard/autocharger_config.txt" }
local SAVE_KEYS = { "world", "wallpaperId", "deadId", "aliveId", "mode", "perCharger", "standOnTop", "dropOn", "fullAt", "dropX", "dropY", "walkOrder", "vertDown", "takeOn", "takeX", "takeY" }
local SAVE_SET = {}
for _, k in ipairs(SAVE_KEYS) do SAVE_SET[k] = true end

local MODES = { "Retrieve only", "Charge only", "Retrieve + Charge" }

local FLAG_FLIPPED = 0x20
local WORLD_W, WORLD_H = 100, 60
local PUNCH_ID = 18
local PUNCH_STATE = 2608      -- state packet the real client sends after a punch (from your dump)
-- Punch / place reach is a rectangle: cfg.reachX tiles left/right, cfg.reachY tiles up/down (Options tab)
local function inR(dx, dy) return math.abs(dx) <= cfg.reachX and math.abs(dy) <= cfg.reachY end

---------------- STATE -------------------------------
local S = {
    running = false, threadAlive = false, scanning = false,
    stage = "Idle", stageCol = C.white,
    fg = {},              -- idx -> tile id for the whole world
    chargers = {},        -- { x, y, key, flags, sig }
    chargerAt = {},       -- idx -> charger
    known = {},           -- idx -> "empty" | "filled" (learned from our own successful actions)
    stands = 0, unreach = 0,
    step = 0, stepsTotal = 0,
    retrieved = 0, charged = 0, skipped = 0, nothing = 0, failed = 0, runs = 0, dropped = 0,
    taken = 0, takeEmpty = false,
    logN = 0,
    curX = nil, curY = nil, dropShift = 0,
    learnPunch = false, capturePkt = false,
    template = nil, sending = false,
    cfgPath = nil, uiMsg = nil, uiOk = true, uiUntil = 0,
}

local rawFindPath = FindPath                      -- the game's own pathfinder

---------------- HELPERS -----------------------------
local function say(msg) LogToConsole(msg) end
local function setMsg(text, ok) S.uiMsg, S.uiOk, S.uiUntil = text, ok, os.time() + 5 end
local function setStage(text, col) S.stage, S.stageCol = text, col or C.white end
local function norm(s) return (tostring(s or ""):gsub("%s", ""):upper()) end
local function comma(n)
    local r = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (r:gsub("^,", ""))
end

local function nap(ms)                            -- sleep that reacts quickly to STOP
    local left = ms
    while left > 0 and S.running do
        local s = math.min(250, left)
        Sleep(s)
        left = left - s
    end
end

local function myTile()
    local ok, x, y = pcall(function()
        local p = GetLocal().pos
        return math.floor(p.x / 32), math.floor(p.y / 32)
    end)
    if ok then return x, y end
    return nil, nil
end

local function curWorld()
    local ok, v = pcall(function() return GetWorld().name end)
    if ok and type(v) == "string" then return v:upper() end
    return ""
end

local function getItemCount(id)
    local ok, n = pcall(function()
        for _, itm in pairs(GetInventory()) do
            if itm.id == id then return itm.amount end
        end
        return 0
    end)
    if ok and type(n) == "number" then return n end
    return nil
end

local function totalGeigers()                     -- alive + dead (a retrieve raises this)
    local a, d = getItemCount(cfg.aliveId), getItemCount(cfg.deadId)
    if a == nil or d == nil then return nil end
    return a + d
end

local function idx(x, y) return y * WORLD_W + x end
local function inb(x, y) return x >= 0 and y >= 0 and x < WORLD_W and y < WORLD_H end

local function saveConfig(silent)
    local lines = {}
    for _, k in ipairs(SAVE_KEYS) do
        local v = cfg[k]
        if type(v) == "boolean" then v = v and "true" or "false" end
        lines[#lines + 1] = k .. "=" .. tostring(v)
    end
    local data = table.concat(lines, "\n") .. "\n"
    local order = {}
    if S.cfgPath then order[1] = S.cfgPath end
    for _, p in ipairs(CONFIG_PATHS) do order[#order + 1] = p end
    for _, p in ipairs(order) do
        local ok, f = pcall(io.open, p, "w")
        if ok and f then
            if pcall(function() f:write(data) f:close() end) then
                S.cfgPath = p
                if not silent then setMsg("Config saved (" .. p .. ")", true) end
                return true
            end
        end
    end
    if not silent then setMsg("Could not save config (no writable path)", false) end
    return false
end

local function loadConfig(silent)
    for _, p in ipairs(CONFIG_PATHS) do
        local ok, f = pcall(io.open, p, "r")
        if ok and f then
            local rok, data = pcall(function() local d = f:read("*a") f:close() return d end)
            if rok and data and data ~= "" then
                for line in data:gmatch("[^\r\n]+") do
                    local k, v = line:match("^(%w+)=(.*)$")
                    if k and SAVE_SET[k] and cfg[k] ~= nil then
                        if type(cfg[k]) == "boolean" then cfg[k] = (v == "true")
                        elseif type(cfg[k]) == "number" then cfg[k] = tonumber(v) or cfg[k]
                        else cfg[k] = v end
                    end
                end
                cfg.mode      = math.max(1, math.min(3, cfg.mode))
                cfg.stepTiles = math.max(1, cfg.stepTiles)            -- no upper limit
                cfg.stepDelay = math.max(0, cfg.stepDelay)
                cfg.msPerTile = math.max(0, cfg.msPerTile)            -- 0 allowed = no wait
                cfg.actionDelay = math.max(0, cfg.actionDelay)
                cfg.reachX = math.max(0, math.min(10, cfg.reachX))
                cfg.reachY = math.max(0, math.min(10, cfg.reachY))
                cfg.fullAt    = math.max(1, math.min(250, cfg.fullAt))
                S.cfgPath = p
                if not silent then setMsg("Config loaded", true) end
                return true
            end
        end
    end
    if not silent then setMsg("No saved config found", false) end
    return false
end

---------------- TILE / ITEM ACCESS -------------------
local function tf(t, k)                           -- safe field read
    local ok, v = pcall(function() return t[k] end)
    if ok then return v end
    return nil
end

local function growthOf(t)                        -- number the server keeps on the tile (a unix time once it was changed)
    local ex = tf(t, "extra")
    if type(ex) ~= "table" then return nil end
    return tonumber(tf(ex, "growth"))
end

local function getTile(x, y)
    local ok, t = pcall(GetTile, x, y)
    if ok and t then return t end
    return nil
end

local function flagsOf(t)
    local f = tonumber(tf(t, "flags")) or 0
    return math.tointeger(f) or 0
end

local function itemInfo(id)
    for _, fn in ipairs({ "GetItemInfoByID", "GetItemByIDSafe", "GetItemInfo" }) do
        local f = _G[fn]
        if type(f) == "function" then
            local ok, info = pcall(f, id)
            if ok and info then return info end
        end
    end
    return nil
end

local function itemName(id)
    local info = itemInfo(id)
    if info then
        local n = tf(info, "name")
        if type(n) == "string" then return n end
    end
    return nil
end

local colCache = {}
local function collisionOf(fg)                    -- number, or false if the executor can't tell
    local v = colCache[fg]
    if v == nil then
        v = false
        local info = itemInfo(fg)
        if info then
            for _, key in ipairs({ "collision_type", "collisionType", "collision" }) do
                local n = tf(info, key)
                if type(n) == "number" then v = n break end
            end
        end
        colCache[fg] = v
    end
    return v
end

-- A tile you can walk through: air, or a block with no collision / a platform.
local function fgPassable(fg)
    if fg == 0 then return true end
    local c = collisionOf(fg)
    return c == 0 or c == 2
end

-- A tile that holds you up when it is under your feet.
local function fgSolid(fg)
    if fg == 0 then return false end
    return collisionOf(fg) ~= 0                   -- unknown (false) counts as solid
end

local function fgAt(x, y) return S.fg[idx(x, y)] or 0 end

local function isPass(x, y)
    if not inb(x, y) then return false end
    if S.chargerAt[idx(x, y)] then return false end
    return fgPassable(fgAt(x, y))
end

local function isGrounded(x, y)
    if y + 1 >= WORLD_H then return true end
    return fgSolid(fgAt(x, y + 1))
end

---------------- TILE SIGNATURE (empty / filled) ------
local EXTRA_KEYS = { "extra", "extraData", "extradata", "tiledata", "data" }

local function hex(s)
    return (s:sub(1, 32):gsub(".", function(ch) return string.format("%02x", ch:byte()) end))
end

local function valStr(v)
    local tv = type(v)
    if tv == "string" then
        if v:find("[^%g ]") then return hex(v) end
        return v
    elseif tv == "number" or tv == "boolean" then
        return tostring(v)
    end
    return nil
end

local function sigOf(t, flags)
    local parts = { "f" .. (flags & (~FLAG_FLIPPED)) }
    for _, key in ipairs(EXTRA_KEYS) do
        local v = tf(t, key)
        if type(v) == "table" then
            local items = {}
            pcall(function()
                for k, x in pairs(v) do
                    if k == "growth" then
                        -- a unix time (> 1e9) means the server stamped this tile recently; a small number means it was not
                        local gn = tonumber(x)
                        if gn then items[#items + 1] = "g:" .. (gn > 1e9 and "T" or "S") end
                    elseif k ~= "lastupdate" then
                        local s = valStr(x)
                        if s then items[#items + 1] = tostring(k) .. ":" .. s end
                    end
                end
            end)
            table.sort(items)
            if #items > 0 then parts[#parts + 1] = key .. "{" .. table.concat(items, ",") .. "}" end
        else
            local s = valStr(v)
            if s then parts[#parts + 1] = key .. "=" .. s end
        end
    end
    return (table.concat(parts, ";"):gsub("[~\r\n]", "_"))
end

local function inspectTile(t)                     -- everything we can see on a tile, for the console
    local out = {}
    pcall(function()
        if type(t) == "table" then
            for k, v in pairs(t) do
                out[#out + 1] = tostring(k) .. "=" .. (type(v) == "table" and "{table}" or tostring(v))
            end
        end
    end)
    for _, key in ipairs({ "fg", "bg", "flags", "extra", "extraData", "data", "state", "label" }) do
        local v = tf(t, key)
        if v ~= nil then out[#out + 1] = "[" .. key .. "]=" .. (type(v) == "table" and "{table}" or tostring(v)) end
    end
    table.sort(out)
    return table.concat(out, " ")
end

local function refreshCharger(c)
    local t = getTile(c.x, c.y)
    if not t then return end
    c.flags = flagsOf(t)
end

---------------- SCAN WORLD ---------------------------
local function scanWorld()
    -- world size, if the executor knows it
    pcall(function()
        local w = GetWorld()
        local ww, hh = tonumber(w.width), tonumber(w.height)
        if ww and hh and ww >= 20 and hh >= 20 and ww <= 400 and hh <= 400 then
            WORLD_W, WORLD_H = math.floor(ww), math.floor(hh)
        end
    end)

    -- A Geiger Charger = any block (fg > 0) that has the chosen wallpaper (bg) behind it.
    local fg, wpTiles = {}, {}
    local wp = cfg.wallpaperId
    for y = 0, WORLD_H - 1 do
        for x = 0, WORLD_W - 1 do
            local t = getTile(x, y)
            local id = t and tonumber(tf(t, "fg")) or 0
            fg[idx(x, y)] = id
            if wp > 0 and id > 0 and t then
                local bg = tonumber(tf(t, "bg")) or 0
                if bg == wp then wpTiles[#wpTiles + 1] = idx(x, y) end
            end
        end
    end
    S.fg = fg

    local id = wp

    local list, at = {}, {}
    if id > 0 then
        for _, k in ipairs(wpTiles) do
            local x, y = k % WORLD_W, k // WORLD_W
            local t = getTile(x, y)
            local flags = t and flagsOf(t) or 0
            local c = { x = x, y = y, key = k, flags = flags }
            list[#list + 1] = c
            at[k] = c
        end
    end
    S.chargers, S.chargerAt = list, at
    return id, #list
end

---------------- PATH SEARCH (own BFS over walkable tiles) --
local DX, DY = { 1, -1, 0, 0 }, { 0, 0, 1, -1 }

local function bfs(sx, sy)                        -- parent map for every tile reachable from (sx, sy)
    local par = {}
    local start = idx(sx, sy)
    par[start] = -1
    local q, h, tl = { start }, 1, 1
    while h <= tl do
        local cur = q[h]
        h = h + 1
        local cx, cy = cur % WORLD_W, cur // WORLD_W
        for i = 1, 4 do
            local nx, ny = cx + DX[i], cy + DY[i]
            if isPass(nx, ny) then
                local k = idx(nx, ny)
                if par[k] == nil then
                    par[k] = cur
                    tl = tl + 1
                    q[tl] = k
                end
            end
        end
    end
    return par
end

local function pathTo(par, tx, ty)
    local k = idx(tx, ty)
    if par[k] == nil then return nil end
    local rev = {}
    while par[k] ~= -1 do
        rev[#rev + 1] = { x = k % WORLD_W, y = k // WORLD_W }
        k = par[k]
    end
    local path = {}
    for i = #rev, 1, -1 do path[#path + 1] = rev[i] end
    return path
end

---------------- WALKING ------------------------------
-- One hop with the game's pathfinder. Waits until we arrive or stop moving.
local function hop(nx, ny)
    local sx, sy = myTile()
    pcall(rawFindPath, nx, ny)
    local lastx, lasty, still = sx, sy, 0
    for _ = 1, 25 do
        if not S.running then break end
        nap(100)
        local cx, cy = myTile()
        if cx == nx and cy == ny then return true end
        if cx == lastx and cy == lasty then still = still + 1 else still = 0 end
        lastx, lasty = cx, cy
        if still >= 4 then break end
    end
    local ex, ey = myTile()
    return ex ~= sx or ey ~= sy
end

-- Human-like speed. The anti-cheat compares how far you moved with the time since your last move,
-- so after every hop we wait about msPerTile for each tile just moved.
local function pace(tiles)
    local wait = math.max(cfg.stepDelay, (tiles or 0) * cfg.msPerTile)
    if wait <= 0 then return end                  -- 0 = no wait at all
    nap(wait + math.random(0, 150))
end

-- Shrinks a move so its real length is <= stepTiles.
local function limitStep(dx, dy)
    local len  = math.sqrt(dx * dx + dy * dy)
    local step = math.max(1, cfg.stepTiles)
    if len <= step then return dx, dy end
    local f  = step / len
    local mx = math.floor(math.abs(dx) * f) * (dx < 0 and -1 or 1)
    local my = math.floor(math.abs(dy) * f) * (dy < 0 and -1 or 1)
    if mx == 0 and my == 0 then
        if math.abs(dx) >= math.abs(dy) then mx = (dx < 0) and -1 or 1
        else my = (dy < 0) and -1 or 1 end
    end
    return mx, my
end

-- Used when my own map has no route: small paced steps toward the target (never one long jump).
local function stepToward(tx, ty)
    local stuck = 0
    for _ = 1, 400 do
        if not S.running then return false end
        local cx, cy = myTile()
        if cx == nil then return false end
        local dx, dy = tx - cx, ty - cy
        if dx == 0 and dy == 0 then return true end
        local mx, my = limitStep(dx, dy)
        if stuck > 0 then
            mx = (mx > 0) and 1 or ((mx < 0) and -1 or 0)
            my = (my > 0) and 1 or ((my < 0) and -1 or 0)
        end
        if hop(cx + mx, cy + my) then
            stuck = 0
            pace(math.max(math.abs(mx), math.abs(my)))
        else
            stuck = stuck + 1
            if stuck >= 3 then return false end
            nap(300)
        end
    end
    return false
end

-- Walks to (tx, ty) along walkable tiles, at most stepTiles per hop, at a human pace.
local function walkTo(tx, ty)
    if type(rawFindPath) ~= "function" then return false end
    for _ = 1, 3 do
        if not S.running then return false end
        local cx, cy = myTile()
        if cx == nil then return false end
        if cx == tx and cy == ty then return true end

        local path = pathTo(bfs(cx, cy), tx, ty)
        if path then
            local i, broken = 0, false
            while i < #path and S.running do
                local j = math.min(#path, i + cfg.stepTiles)
                local k = j
                while k > i + 1 and not isGrounded(path[k].x, path[k].y) do k = k - 1 end
                if not isGrounded(path[k].x, path[k].y) then k = j end
                local fx, fy = myTile()
                if not hop(path[k].x, path[k].y) then broken = true break end
                local ax, ay = myTile()
                local moved = (fx and ax) and math.max(math.abs(ax - fx), math.abs(ay - fy)) or (k - i)
                i = k
                pace(moved)
            end
            if not broken then
                local ax, ay = myTile()
                if ax == tx and ay == ty then return true end
            end
        else
            if stepToward(tx, ty) then return true end
        end
        nap(300)
    end
    return false
end

-- The game's own pathfinder in one go: it walks the whole route by itself, so it works from far away
-- and where my own map has no route. It is fast, so it is only the fallback (and used for the drop trip).
local function goDirect(tx, ty)
    if type(rawFindPath) ~= "function" then return false end
    local cx, cy = myTile()
    if cx == nil then return false end
    if cx == tx and cy == ty then return true end
    local dist = math.abs(tx - cx) + math.abs(ty - cy)
    pcall(rawFindPath, tx, ty)
    local lastx, lasty, still = cx, cy, 0
    for _ = 1, math.max(40, dist * 10) do        -- about 1 second per tile, at most
        if not S.running then return false end
        nap(100)
        local x, y = myTile()
        if x == tx and y == ty then return true end
        if x == lastx and y == lasty then still = still + 1 else still = 0 end
        lastx, lasty = x, y
        if still >= 20 then break end            -- 2 seconds without moving: it is not going anywhere
    end
    local x, y = myTile()
    return x == tx and y == ty
end

-- Long trips where my own map has no route (gates, entrances, odd tiles) or the route needs real jump
-- physics: the game's pathfinder, but only for SHORT hops along the straight line to the target, each
-- followed by the normal pace wait. It never asks the game for one long run, so it never looks like a jump.
local function chunkWalk(tx, ty)
    if type(rawFindPath) ~= "function" then return false end
    local fails = 0
    for _ = 1, 800 do
        if not S.running then return false end
        local cx, cy = myTile()
        if cx == nil then return false end
        local dx, dy = tx - cx, ty - cy
        if dx == 0 and dy == 0 then return true end
        local len = math.sqrt(dx * dx + dy * dy)
        local hopLen = math.max(2, cfg.stepTiles)
        local wx, wy = tx, ty
        if len > hopLen then
            local f = hopLen / len
            wx = cx + math.floor(dx * f + (dx >= 0 and 0.5 or -0.5))
            wy = cy + math.floor(dy * f + (dy >= 0 and 0.5 or -0.5))
        end
        -- the line point first, then open tiles with ground under them around it that are closer to the target
        local cands = { { wx, wy } }
        if wx ~= tx or wy ~= ty then
            for r = 1, 3 do
                for ox = -r, r do
                    for oy = -r, r do
                        if math.max(math.abs(ox), math.abs(oy)) == r then
                            local x, y = wx + ox, wy + oy
                            if inb(x, y) and isPass(x, y) and isGrounded(x, y)
                               and math.sqrt((tx - x) ^ 2 + (ty - y) ^ 2) < len then
                                cands[#cands + 1] = { x, y }
                            end
                        end
                    end
                end
            end
        end
        local moved = false
        for i = 1, math.min(#cands, 6) do
            if not S.running then return false end
            local bx, by = myTile()
            if hop(cands[i][1], cands[i][2]) then
                local ax, ay = myTile()
                local steps = (bx and ax) and math.max(math.abs(ax - bx), math.abs(ay - by)) or 1
                if steps > 0 then
                    moved = true
                    pace(steps)
                    break
                end
            end
        end
        if moved then fails = 0 else
            fails = fails + 1
            if fails >= 3 then return false end
            nap(300)
        end
    end
    local x, y = myTile()
    return x == tx and y == ty
end

local function whyNoRoute(tx, ty)
    local cx, cy = myTile()
    if not cx then return end
    local par = bfs(cx, cy)
    local n = 0
    for _ in pairs(par) do n = n + 1 end
    say(string.format("`8[Auto Charger] no safe route: you (%d,%d) -> (%d,%d), distance %d | target open in my map: %s, connected to you: %s, ground under it: %s | tiles I can walk: %d",
        cx, cy, tx, ty, math.max(math.abs(tx - cx), math.abs(ty - cy)),
        tostring(isPass(tx, ty)), tostring(par[idx(tx, ty)] ~= nil), tostring(isGrounded(tx, ty)), n))
end

-- Any trip: my own paced path first, then short paced hops with the game's pathfinder. The one-shot
-- jump (goDirect) only if you turned "allow jump" on.
local function travelTo(tx, ty)
    if walkTo(tx, ty) then return true end
    if not S.running then return false end
    if chunkWalk(tx, ty) then return true end
    if not S.running then return false end
    whyNoRoute(tx, ty)
    if cfg.allowJump then
        say("`4[Auto Charger] `wNo safe route - using ONE long jump (can trip the speed-hack check).")
        return goDirect(tx, ty)
    end
    return false
end

---------------- PLAN THE STOPS ------------------------
-- Picks the fewest standing tiles that cover every charger within `reach`.
local function planStands(filter)
    local RX = math.max(0, math.floor(cfg.reachX))
    local RY = math.max(0, math.floor(cfg.reachY))
    local cx, cy = myTile()
    cx, cy = cx or 0, cy or 0
    local par = bfs(cx, cy)
    local nPar = 0
    for _ in pairs(par) do nPar = nPar + 1 end
    local D = { reached = nPar, notPass = 0, notGround = 0, notConn = 0, ok = 0, loose = 0 }

    local targets, uncovered, uncoveredN = {}, {}, 0
    for _, c in ipairs(S.chargers) do
        if not filter or filter(c) then
            targets[#targets + 1] = c
            uncovered[c.key] = c
            uncoveredN = uncoveredN + 1
        end
    end

    local stands = {}

    -- one greedy pass. strict = only tiles my own map can walk to.
    -- loose = any free tile with ground (the game's pathfinder does the walking).
    local function pass(loose, onlyTop)
        if uncoveredN == 0 then return end
        local cand, candAt, cnt = {}, {}, {}
        for _, c in ipairs(targets) do
            if uncovered[c.key] then
                for dy = -RY, RY do
                    for dx = -RX, RX do
                        local x, y = c.x + dx, c.y + dy
                        if inb(x, y) and inR(dx, dy) then
                            local k = idx(x, y)
                            if candAt[k] == nil then
                                local ok = false
                                if onlyTop and not S.chargerAt[idx(x, y + 1)] then
                                    -- not on top of a charger: skip this tile in the stand-on-top pass
                                elseif not isPass(x, y) then
                                    if not loose then D.notPass = D.notPass + 1 end
                                elseif not isGrounded(x, y) then
                                    if not loose then D.notGround = D.notGround + 1 end
                                elseif par[k] == nil and not loose then
                                    D.notConn = D.notConn + 1
                                else
                                    ok = true
                                end
                                candAt[k] = ok and { x = x, y = y, k = k } or false
                                if ok then
                                    if not loose then D.ok = D.ok + 1 end
                                    cand[#cand + 1] = candAt[k]
                                    cnt[k] = 0
                                end
                            end
                        end
                    end
                end
            end
        end
        for _, c in ipairs(targets) do
            if uncovered[c.key] then
                for dy = -RY, RY do
                    for dx = -RX, RX do
                        local x, y = c.x + dx, c.y + dy
                        if inb(x, y) and inR(dx, dy) then
                            local k = idx(x, y)
                            if cnt[k] then cnt[k] = cnt[k] + 1 end
                        end
                    end
                end
            end
        end

        while uncoveredN > 0 do
            local best, bestN = nil, 0
            for _, s in ipairs(cand) do
                local n = cnt[s.k]
                if n > bestN then best, bestN = s, n end
            end
            if not best then break end

            local list = {}
            for dy = -RY, RY do
                for dx = -RX, RX do
                    local x, y = best.x + dx, best.y + dy
                    if inb(x, y) and inR(dx, dy) then
                        local c = uncovered[idx(x, y)]
                        if c then
                            list[#list + 1] = c
                            uncovered[c.key] = nil
                            uncoveredN = uncoveredN - 1
                            for ddy = -RY, RY do
                                for ddx = -RX, RX do
                                    local ax, ay = c.x + ddx, c.y + ddy
                                    if inb(ax, ay) and inR(ddx, ddy) then
                                        local kk = idx(ax, ay)
                                        if cnt[kk] then cnt[kk] = cnt[kk] - 1 end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            table.sort(list, function(a, b) if a.y ~= b.y then return a.y < b.y end return a.x < b.x end)
            stands[#stands + 1] = { x = best.x, y = best.y, list = list, loose = loose }
            if loose then D.loose = D.loose + 1 end
        end
    end

    if cfg.standOnTop then pass(false, true) end  -- first choice: stand on top of a charger
    pass(false, false)
    if cfg.standOnTop then pass(true, true) end
    pass(true, false)                             -- chargers my map can't connect to: let the game's pathfinder try
    S.diag = D

    if cfg.walkOrder == 2 or cfg.walkOrder == 3 then
        -- two-sided layout: finish one whole side (top to bottom or bottom to top), then the other side
        local minX, maxX = math.huge, -math.huge
        for _, c in ipairs(S.chargers) do
            if c.x < minX then minX = c.x end
            if c.x > maxX then maxX = c.x end
        end
        local mid = (minX + maxX) / 2
        local leftFirst = (cfg.walkOrder == 2)
        local function sideRank(st)
            local isLeft = st.x < mid
            if leftFirst then return isLeft and 1 or 2 end
            return isLeft and 2 or 1
        end
        local down = cfg.vertDown ~= false
        table.sort(stands, function(p, q)
            local sp, sq = sideRank(p), sideRank(q)
            if sp ~= sq then return sp < sq end
            if p.y ~= q.y then
                if down then return p.y < q.y end
                return p.y > q.y
            end
            return p.x < q.x
        end)
        S.stands, S.unreach = #stands, uncoveredN
        return stands, uncoveredN
    end

    -- visit the stops in a short walking order (nearest next)
    local ordered, rest = {}, {}
    for i, s in ipairs(stands) do rest[i] = s end
    local ox, oy = cx, cy
    while #rest > 0 do
        local bi, bd = 1, math.huge
        for i, s in ipairs(rest) do
            local d = math.abs(s.x - ox) + math.abs(s.y - oy)
            if d < bd then bi, bd = i, d end
        end
        local s = table.remove(rest, bi)
        ordered[#ordered + 1] = s
        ox, oy = s.x, s.y
    end

    S.stands, S.unreach = #ordered, uncoveredN
    return ordered, uncoveredN
end

local function printDiag()
    local D = S.diag or {}
    local px_, py_ = myTile()
    local ids, known, unknown = {}, 0, 0
    for _, id in pairs(S.fg) do
        if id > 0 and not ids[id] then
            ids[id] = true
            if collisionOf(id) == false then unknown = unknown + 1 else known = known + 1 end
        end
    end
    say(string.format("`4[Auto Charger] `wWhy no stop: you at (%s,%s), world %dx%d, %d chargers",
        tostring(px_), tostring(py_), WORLD_W, WORLD_H, #S.chargers))
    say(string.format("`8  tiles you can reach: %s | near chargers: blocked %s, no ground %s, not connected %s, usable %s",
        tostring(D.reached), tostring(D.notPass), tostring(D.notGround), tostring(D.notConn), tostring(D.ok)))
    say(string.format("`8  block types with known collision: %d, unknown: %d (unknown = treated as solid)", known, unknown))
    if px_ then
        local under = fgAt(px_, py_ + 1)
        say(string.format("`8  under you: id %d, collision %s | your tile id %d", under, tostring(collisionOf(under)), fgAt(px_, py_)))
    end
    local c = S.chargers[1]
    if c then say(string.format("`8  first charger (%d,%d), tile above id %d, below id %d, left id %d, right id %d",
        c.x, c.y, fgAt(c.x, c.y - 1), fgAt(c.x, c.y + 1), fgAt(c.x - 1, c.y), fgAt(c.x + 1, c.y))) end
end

---------------- RAW PACKETS (same method as Auto Crystal) --
local function rawPacket(value, tx, ty)
    local x, y = 0, 0
    pcall(function() local p = GetLocal().pos x, y = p.x, p.y end)
    local pkt = {
        type = 3, value = value, px = tx, py = ty,
        x = x, y = y, xspeed = 0, yspeed = 0,
        netid = 0, snetid = 0, state = 0,
        padding1 = 0, padding2 = 0, padding4 = 0.0, padding5 = 0,
        dropped = 0, extrasize = 0,
    }
    if S.template then
        local keep = { type = true, value = true, px = true, py = true, x = true, y = true, netid = true }
        for k, v in pairs(S.template) do
            if not keep[k] then pkt[k] = v end
        end
    end
    return pkt
end

local function send(pkt)
    S.sending = true
    local ok = pcall(SendPacketRaw, false, pkt)
    S.sending = false
    return ok
end

-- Punch: tile packet (value 18) then the punch state packet (copied from your dump).
local function sendPunch(tx, ty)
    local ok = send(rawPacket(PUNCH_ID, tx, ty))
    if ok then
        local sp = rawPacket(PUNCH_ID, tx, ty)
        sp.type, sp.state, sp.value = 0, PUNCH_STATE, 0
        send(sp)
    end
    return ok
end

-- Place a dead geiger: your dump shows the real client sends just the tile packet.
local function sendPlace(tx, ty)
    return send(rawPacket(cfg.deadId, tx, ty))
end

---------------- ACTIONS ------------------------------
local function punch(c)                           -- true if a geiger came back into the inventory
    local before = totalGeigers()
    sendPunch(c.x, c.y)
    local waited = 0
    while S.running and waited < cfg.waitResultMs do
        nap(100)
        waited = waited + 100
        local now = totalGeigers()
        if before and now and now > before then return true end
        if before == nil then return false end
    end
    return false
end

local function place(c)                           -- true if the dead geiger count dropped
    local before = getItemCount(cfg.deadId)
    sendPlace(c.x, c.y)
    local waited = 0
    while S.running and waited < cfg.waitResultMs do
        nap(100)
        waited = waited + 100
        local now = getItemCount(cfg.deadId)
        if before and now and now < before then return true end
        if before == nil then return false end
    end
    return false
end

-- Alive geiger stack is full: walk to the drop spot, drop them all, then the caller walks back.
-- If the tile is taken (the drop fails), it moves one tile left and tries again.
-- Where to try dropping, best first: the drop spot you captured (and a few tiles to its left),
-- then free tiles with ground under them around where I am standing now.
local function dropTiles()
    local list = {}
    if cfg.dropX ~= 0 or cfg.dropY ~= 0 then
        for sh = 0, 5 do list[#list + 1] = { x = math.max(0, cfg.dropX - sh), y = cfg.dropY, spot = true } end
    end
    local cx, cy = myTile()
    if cx then
        for r = 0, 8 do
            for _, dx in ipairs(r == 0 and { 0 } or { -r, r }) do
                local x = cx + dx
                if inb(x, cy) and isPass(x, cy) and isGrounded(x, cy) then
                    list[#list + 1] = { x = x, y = cy, spot = false }
                end
            end
        end
    end
    return list
end

-- Alive geiger stack is full: drop it all, one tile at a time, until the game accepts a drop.
local function dropAlive()
    local before = getItemCount(cfg.aliveId)
    if before == nil or before <= 0 then return true end
    setStage("Dropping geigers", C.yellow)
    local skipSpot = false
    local tried = 0
    for _, t in ipairs(dropTiles()) do
        if not S.running then return false end
        if t.spot and skipSpot then goto continue end
        tried = tried + 1
        if tried > 14 then break end

        do
            local mx, my = myTile()
            if mx ~= t.x or my ~= t.y then
                -- always the paced walker (short hops, msPerTile per tile). goDirect hands the whole
                -- route to the game's pathfinder at once = an instant jump the speed-hack check flags.
                local reached = travelTo(t.x, t.y)
                if not reached then
                    if t.spot then
                        skipSpot = true
                        say("`4[Auto Charger] `wCan't reach the drop spot (" .. t.x .. "," .. t.y .. "), trying near me.")
                    end
                    goto continue
                end
            end
            nap(500)
            local have = getItemCount(cfg.aliveId) or 0
            if have <= 0 then return true end
            S.cantDrop, S.lastOverlay = false, nil
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. cfg.aliveId
                .. "|\nitem_count|" .. have .. "\n")
            local waited, dropped = 0, false
            while S.running and waited < 2500 do
                nap(250)
                waited = waited + 250
                local now = getItemCount(cfg.aliveId)
                if now and now < have then dropped = true break end
                if S.cantDrop then break end
            end
            if dropped then
                local left = getItemCount(cfg.aliveId) or 0
                S.dropped = S.dropped + (have - left)
                if left <= 0 then
                    say("`2[Auto Charger] `wDropped " .. have .. " alive geigers at (" .. t.x .. "," .. t.y .. ").")
                    return true
                end
            else
                say(string.format("`4[Auto Charger] `wDrop refused at (%d,%d): %s", t.x, t.y,
                    tostring(S.lastOverlay or S.lastMsg or "no reply from the game")))
            end
        end
        ::continue::
    end
    say("`4[Auto Charger] `wCouldn't drop the geigers anywhere near. Pick a drop spot with open floor next to it.")
    return false
end

-- Out of dead geigers: walk to the take spot (paced, never an instant jump), stand on it so the dead
-- geigers lying there are picked up, then walk back to the stop we came from.
-- Returns true if the dead geiger count went up.
local function takeDead()
    if not cfg.takeOn or (cfg.takeX == 0 and cfg.takeY == 0) then return false end
    if S.takeEmpty then return false end            -- already looked this run and found nothing
    local sx, sy = S.curX, S.curY
    local before = getItemCount(cfg.deadId) or 0
    local best = before
    setStage("Taking dead geigers", C.yellow)
    -- items can land a tile or two away from where they were dropped, so also stand beside the spot
    for n, off in ipairs({ 0, -1, 1, -2, 2 }) do
        if not S.running then break end
        local tx = math.max(0, cfg.takeX + off)
        if not travelTo(tx, cfg.takeY) then
            if off == 0 then
                say("`4[Auto Charger] `wCan't reach the take spot (" .. cfg.takeX .. "," .. cfg.takeY .. ").")
                break
            end
        else
            local waited, limit = 0, (best > before) and 1000 or ((n == 1) and 3000 or 1500)
            while S.running and waited < limit do
                nap(250)
                waited = waited + 250
                local now = getItemCount(cfg.deadId) or 0
                if now > best then best, waited = now, 0 end   -- still picking up: keep waiting
            end
        end
    end
    local after = getItemCount(cfg.deadId) or 0
    if after > before then
        S.taken = S.taken + (after - before)
        say("`2[Auto Charger] `wTook " .. (after - before) .. " dead geigers at the take spot.")
    else
        S.takeEmpty = true
        say("`4[Auto Charger] `wNo dead geigers at the take spot (" .. cfg.takeX .. "," .. cfg.takeY .. ").")
    end
    if sx and S.running then travelTo(sx, sy) end      -- back to the chargers
    return after > before
end

-- Remembers chargers that did not get handled, so the end of the run can list them.
local function noteMiss(c, why)
    S.miss = S.miss or {}
    S.miss[#S.miss + 1] = string.format("(%d,%d) %s", c.x, c.y, why)
end

local function doRetrieve(c)
    if cfg.dropOn then                            -- no room to pick up: drop the alive geigers first
        local have = getItemCount(cfg.aliveId)
        if have and have >= cfg.fullAt then
            local sx, sy = S.curX, S.curY
            if not dropAlive() then
                if S.running then say("`4[Auto Charger] `wStopping: the alive geiger stack is full and I can't drop it.") end
                S.running = false
                return "stopped"
            end
            if sx and S.running then                        -- back to where the chargers are (paced, no jump)
                travelTo(sx, sy)
            end
        end
    end
    if not S.running then return "stopped" end
    S.lastMsg = nil
    setStage("Retrieving", C.green)
    if punch(c) then
        S.retrieved = S.retrieved + 1
        nap(cfg.actionDelay)
        return "ok"
    end
    S.nothing = S.nothing + 1                     -- nothing came out (it was empty / charging)
    return "nothing"
end

local function doCharge(c)
    local dead = getItemCount(cfg.deadId)
    if dead ~= nil and dead <= 0 then
        if takeDead() then dead = getItemCount(cfg.deadId) end   -- fetched more from the take spot
        if dead ~= nil and dead <= 0 then return "nodead" end
    end
    setStage("Charging", C.cyan)
    if place(c) then
        S.charged = S.charged + 1
        nap(cfg.actionDelay)
        return "ok"
    end
    S.skipped = S.skipped + 1                     -- refused (already full / charging)
    return "failed"
end

---------------- MAIN LOOP ----------------------------
local function ensureWorld()
    local target = norm(cfg.world)
    if target == "" then return true end
    local tries = 0
    while S.running and curWorld() ~= target do
        if tries >= 4 then say("`4[Auto Charger] `wCould not reach " .. cfg.world) return false end
        tries = tries + 1
        setStage("Warping to " .. cfg.world, C.yellow)
        SendPacket(2, "action|input\n|text|/warp " .. cfg.world .. "\n")
        nap(6000)
    end
    if S.running then nap(2500) end               -- let the world finish loading
    return S.running
end

-- Walks to a stop, then runs fn on every charger in reach from there.
local function visit(st, fn)
    setStage("Moving", C.cyan)
    if not travelTo(st.x, st.y) then
        S.failed = S.failed + #st.list
        S.step = S.step + #st.list
        for _, c in ipairs(st.list) do noteMiss(c, "stop not reachable") end
        say(string.format("`4[Auto Charger] `wCan't reach stop (%d,%d), skipping %d charger(s).", st.x, st.y, #st.list))
        return nil
    end
    S.curX, S.curY = st.x, st.y
    S.stopN = (S.stopN or 0) + 1
    say(string.format("`8[Auto Charger] stop %d at (%d,%d): %d chargers | charged %d, taken %d, refused %d",
        S.stopN, st.x, st.y, #st.list, S.charged or 0, S.retrieved or 0, S.skipped or 0))
    for _, c in ipairs(st.list) do
        if not S.running then return "stopped" end
        local r = fn(c)
        if r == "nodead" then return "nodead" end
    end
    return nil
end

-- Visits only chargers that want(c) says need work. After every stop it re-plans from where you
-- stand, so chargers learned to be empty / charging meanwhile are not walked to.
local function sweep(want, act)
    for _, c in ipairs(S.chargers) do refreshCharger(c) end
    local done = {}
    while S.running do
        local stands = planStands(function(c) return not done[c.key] and want(c) end)
        if #stands == 0 then break end
        local st = stands[1]
        local r = visit(st, act)
        for _, c in ipairs(st.list) do done[c.key] = true end
        if r == "nodead" then saveConfig(true) return "nodead" end
    end
    saveConfig(true)
    return nil
end

local function runOnce()
    if not ensureWorld() then return false end

    setStage("Scanning area", C.cyan)
    local id, n = scanWorld()
    if id <= 0 then say("`4[Auto Charger] `wWallpaper id not set. Use Learn wallpaper (Tools tab) or type the id.") return false end
    if n == 0 then say("`4[Auto Charger] `wNo Geiger Chargers found (no block with wallpaper " .. id .. " behind it).") return false end

    S.miss = {}
    S.stopN = 0
    S.takeEmpty = false
    setStage("Planning route", C.cyan)
    local stands, unreach = planStands()
    S.unreachFirst = unreach
    if #stands == 0 then
        say("`4[Auto Charger] `wNo reachable standing tile next to any charger.")
        printDiag()
        return false
    end
    say(string.format("`2[Auto Charger] `w%d chargers -> %d stops (%d unreachable).", n, #stands, unreach))
    if S.diag and S.diag.loose > 0 then
        say(string.format("`2[Auto Charger] `w%d stop(s) use the game's pathfinder (my own map can't connect them).", S.diag.loose))
    end

    local doRet = cfg.mode == 1 or cfg.mode == 3
    local doChg = cfg.mode == 2 or cfg.mode == 3
    S.step = 0

    local function everyCharger() return true end

    if doRet and doChg and cfg.perCharger then
        S.stepsTotal = n
        local noDead = false
        sweep(everyCharger, function(c)
            doRetrieve(c)
            if not noDead and doCharge(c) == "nodead" then
                noDead = true
                say("`2[Auto Charger] `wNo dead geigers left, only retrieving now.")
            end
            S.step = math.min(S.stepsTotal, S.step + 1)
        end)
        S.step = S.stepsTotal
    else
        S.stepsTotal = n * ((doRet and 1 or 0) + (doChg and 1 or 0))
        if doRet then
            sweep(everyCharger, function(c) doRetrieve(c) S.step = math.min(S.stepsTotal, S.step + 1) end)
            S.step = n
        end
        if doChg and S.running then
            local r = sweep(everyCharger, function(c)
                local res = doCharge(c)
                S.step = math.min(S.stepsTotal, S.step + 1)
                return res
            end)
            if r == "nodead" then say("`2[Auto Charger] `wNo dead geigers left.") end
            S.step = S.stepsTotal
        end
    end

    say(string.format("`2[Auto Charger] `wRun done: charged %d, taken %d, already full/charging %d, nothing came out %d",
        S.charged or 0, S.retrieved or 0, S.skipped or 0, S.nothing or 0))

    -- Summary: which chargers were not handled and why (also counts chargers no stop could cover)
    if S.unreachFirst and S.unreachFirst > 0 then
        say("`4[Auto Charger] `w" .. S.unreachFirst .. " charger(s) had NO standing tile within reach (blocked / no ground). Try a lower reach.")
    end
    if S.miss and #S.miss > 0 then
        say("`4[Auto Charger] `wMissed / unclear (" .. #S.miss .. "): `9" .. table.concat(S.miss, "  ", 1, math.min(#S.miss, 12))
            .. (#S.miss > 12 and ("  ... +" .. (#S.miss - 12)) or ""))
    end
    return true
end

local function mainLoop()
    repeat
        S.runs = S.runs + 1
        local ok = runOnce()
        if not ok or not S.running then break end
        if cfg.repeatMin <= 0 then break end
        local untilT = os.time() + cfg.repeatMin * 60
        while S.running and os.time() < untilT do
            setStage("Next run in " .. (untilT - os.time()) .. "s", C.gray)
            nap(1000)
        end
    until not S.running
end

local function stopRun(reason)
    if not S.running then return end
    S.running = false
    setStage("Stopping", C.yellow)
    say("`4[Auto Charger] Stopped: `w" .. (reason or "stopped by user."))
end

local function startRun()
    if S.threadAlive or S.scanning then setMsg("Busy, try again in a second.", false) return end
    if type(SendPacketRaw) ~= "function" then setMsg("SendPacketRaw not found in this executor.", false) return end
    if cfg.dropOn and cfg.mode ~= 2 and cfg.dropX == 0 and cfg.dropY == 0 then
        setMsg("Set the drop spot first (Main tab) or turn drop OFF.", false)
        return
    end
    if cfg.takeOn and cfg.mode ~= 1 and cfg.takeX == 0 and cfg.takeY == 0 then
        say("`4[Auto Charger] `wTip: no take spot set (Main tab) - it will stop when the dead geigers run out.")
    end
    if not S.template then
        say("`4[Auto Charger] `wTip: punch a tile by hand once first so the script can copy a real packet.")
    end
    saveConfig(true)
    S.running, S.threadAlive = true, true
    setStage("Starting", C.green)
    say("`2[Auto Charger] `wStarted: " .. MODES[cfg.mode])
    RunThread(function()
        local ok, err = pcall(mainLoop)
        if not ok then say("`4[Auto Charger] `wError: " .. tostring(err)) end
        saveConfig(true)
        S.running, S.threadAlive = false, false
        setStage("Idle", C.white)
    end)
end

-- "Scan area" button: scan + plan, without moving.
local function startScan()
    if S.scanning or S.threadAlive then return end
    S.scanning = true
    RunThread(function()
        local ok, err = pcall(function()
            local id, n = scanWorld()
            if id <= 0 then setMsg("Wallpaper id not set - learn it or type it in (Tools tab).", false) return end
            if n == 0 then setMsg("No chargers found (no wallpaper " .. id .. " behind a block).", false) return end
            local _, unreach = planStands()
            if S.stands == 0 then printDiag() end
            setMsg(n .. " chargers, " .. S.stands .. " stops, " .. unreach .. " unreachable", unreach == 0)
        end)
        S.scanning = false
        if not ok then setMsg("Scan failed: " .. tostring(err), false) end
    end)
end

local DUMP_PATHS = { "C:/Users/benwo/AppData/Local/Growtopia/autocharger_dump.txt",
                     "autocharger_dump.txt", "scripts/autocharger_dump.txt", "/sdcard/autocharger_dump.txt" }

-- Writes (or appends) text to the dump file, trying the same folders as the config.
local function writeFile(text, append)
    local order = {}
    if S.dumpPath then order[1] = S.dumpPath end
    for _, pth in ipairs(DUMP_PATHS) do order[#order + 1] = pth end
    for _, pth in ipairs(order) do
        local ok, f = pcall(io.open, pth, append and "a" or "w")
        if ok and f then
            if pcall(function() f:write(text) f:close() end) then
                S.dumpPath = pth
                return pth
            end
        end
    end
    return nil
end

-- "Dump to file": everything the script can see about the chargers, for finding what tells
-- empty / charging / full apart. Runs in its own thread so the game does not freeze.
local function dumpChargers()
    RunThread(function()
        local ok, err = pcall(function()
            if #S.chargers == 0 then scanWorld() end
            local out = {}
            local function add(line) out[#out + 1] = line end
            local px_, py_ = myTile()
            add("AUTO CHARGER DUMP  " .. os.date("%Y-%m-%d %H:%M:%S"))
            add(string.format("world %s  size %dx%d  you at %s,%s", curWorld(), WORLD_W, WORLD_H, tostring(px_), tostring(py_)))
            add(string.format("wallpaper id %d  chargers found %d", cfg.wallpaperId, #S.chargers))
            add("last server text: " .. tostring(S.lastMsg or "-"))
            add("")
            add("ALL CHARGERS (x,y)")
            local rows = {}
            for _, c in ipairs(S.chargers) do rows[#rows + 1] = string.format("%d,%d", c.x, c.y) end
            table.sort(rows)
            for _, r in ipairs(rows) do add(r) end
            add("")
            local path = writeFile(table.concat(out, "\n") .. "\n", false)
            if path then
                setMsg("Dump saved to " .. path, true)
                say("`2[Auto Charger] `wDump saved to `9" .. path .. " `w(" .. #S.chargers .. " chargers)")
            else
                setMsg("Could not write the dump file", false)
                say("`4[Auto Charger] `wCould not write a dump file (no writable folder).")
            end
        end)
        if not ok then setMsg("Dump failed: " .. tostring(err), false) end
    end)
end

---------------- HOOKS --------------------------------
local function register(events, hookName, fn)
    local owner = nil
    for i, ev in ipairs(events) do
        local wrapped = function(...)
            if owner == nil then owner = i end
            if owner ~= i then return false end
            return fn(...)
        end
        pcall(AddHook, ev, hookName .. i, wrapped)
    end
end

local function learnFromTile(x, y)
    S.learnPunch = false
    local t = getTile(x, y)
    local id = t and tonumber(tf(t, "bg")) or 0     -- the wallpaper behind the tile you punched
    if id > 0 then
        cfg.wallpaperId = id
        setMsg("Wallpaper id = " .. id .. (itemName(id) and (" (" .. itemName(id) .. ")") or ""), true)
        say("`2[Auto Charger] `wLearned wallpaper id `9" .. id .. " `wat (" .. x .. "," .. y .. ")")
    else
        setMsg("No wallpaper behind that tile - punch a charger with the wallpaper.", false)
    end
end

local TEMPLATE_FIELDS = { "type", "value", "px", "py", "x", "y", "xspeed", "yspeed",
    "netid", "snetid", "state", "padding1", "padding2", "padding4", "padding5",
    "dropped", "extrasize" }

local function onSendRaw(pkt)                     -- copy a real hand-sent tile packet / learn the charger id
    if S.sending then return false end
    local ok, t = pcall(function() return pkt.type end)
    if not ok or t ~= 3 then return false end
    if S.learnPunch then
        local okv, v = pcall(function() return pkt.value end)
        if okv and (v == PUNCH_ID or v == cfg.deadId) then
            local okx, tx, ty = pcall(function() return pkt.px, pkt.py end)
            if okx and tx and ty then learnFromTile(tx, ty) end
        end
    end
    local copy = {}
    for _, k in ipairs(TEMPLATE_FIELDS) do
        local okf, v = pcall(function() return pkt[k] end)
        if okf and v ~= nil then copy[k] = v end
    end
    S.template = copy
    return false
end

-- Diagnostics only: prints every field of the next tile-update packet (type 5).
local function onTankUpdate(pkt)
    if not S.capturePkt then return false end
    local ok, t = pcall(function() return pkt.type end)
    if not ok or t ~= 5 then return false end
    S.capturePkt = false
    local parts = {}
    pcall(function()
        if type(pkt) == "table" then
            for k, v in pairs(pkt) do
                parts[#parts + 1] = tostring(k) .. "=" .. (type(v) == "table" and "{table}" or tostring(v))
            end
        end
    end)
    for _, key in ipairs({ "tilex", "tiley", "extDataSize", "extdata", "extData", "extra", "data" }) do
        local v = tf(pkt, key)
        if v ~= nil then
            parts[#parts + 1] = "[" .. key .. "]=" .. (type(v) == "table" and "{table}" or tostring(v))
        end
    end
    table.sort(parts)
    say("`2[Auto Charger] `wTile update packet: `9" .. table.concat(parts, " "))
    local wrote = writeFile("TILE UPDATE PACKET " .. os.date("%H:%M:%S") .. ": " .. table.concat(parts, " ") .. "\n", true)
    setMsg(wrote and ("Tile update added to " .. wrote) or "Tile update captured - see the console.", true)
    return false
end

register({ "onsendpacketraw", "OnSendPacketRaw" }, "ach_raw", onSendRaw)
register({ "onprocesstankupdatepacket", "OnProcessTankUpdatePacket" }, "ach_tank", onTankUpdate)

-- Remembers the last chat / bubble text so a failed punch can show what the server said.
local function onVariant(var)
    local ok, name = pcall(function() return tostring(var[0] or "") end)
    if not ok then return false end
    if name == "OnTextOverlay" then
        local okt, txt = pcall(function() return tostring(var[1] or "") end)
        if okt then
            txt = (txt:gsub("`.", ""))
            S.lastOverlay = txt
            if txt:find("can't drop", 1, true) or txt:find("cannot drop", 1, true) or txt:find("no room", 1, true) then
                S.cantDrop = true
            end
        end
        return false
    end
    if name == "OnConsoleMessage" or name == "OnTalkBubble" then
        local okt, txt = pcall(function() return tostring(var[name == "OnTalkBubble" and 2 or 1] or "") end)
        if okt then
            txt = (txt:gsub("`.", ""))
            if txt:find("can't drop", 1, true) or txt:find("cannot drop", 1, true) then S.cantDrop = true S.lastOverlay = txt end
            local chat = txt:find("CP:%d") or txt:find("%*%*") or txt:find("^%[") or txt:find("<")
            if not chat and not txt:find("Auto Charger", 1, true) then S.lastMsg = txt end
        end
    end
    return false
end
register({ "onvariant", "OnVariant" }, "ach_var", onVariant)

---------------- MENU ---------------------------------
local DEFAULTS = {}
for _, k in ipairs(SAVE_KEYS) do DEFAULTS[k] = cfg[k] end

local tab  = 1
local TABS = { "Main", "Options", "Tools" }

local function intInput(label, key, min, max)
    local _, v = ImGui.InputInt(label, cfg[key])
    if v then cfg[key] = math.max(min, max and math.min(max, v) or v) end
end

local function resetCount()
    S.retrieved, S.charged, S.skipped, S.nothing, S.failed, S.runs = 0, 0, 0, 0, 0, 0
    S.dropped, S.taken = 0, 0
    S.step, S.stepsTotal = 0, 0
    setMsg("Count reset", true)
end

local function resetDefaults()
    for _, k in ipairs(SAVE_KEYS) do cfg[k] = DEFAULTS[k] end
    setMsg("Settings reset to default", true)
end

local function statusInfo()
    if S.scanning then return "Scanning", C.cyan end
    if S.threadAlive and not S.running then return "Stopping", C.yellow end
    if not S.running then return "Idle", C.white end
    return S.stage, S.stageCol
end

---------------- SMALL HELPERS ------------------------

local function captureSpot(kx, ky, label)
    local mx, my = myTile()
    if not mx then setMsg("Can't read your position.", false) return end
    cfg[kx], cfg[ky] = mx, my
    if kx == "dropX" then S.dropShift = 0 end
    setMsg(label .. " = " .. mx .. ", " .. my, true)
end

-- "Drop spot: 46, 25 / not set" + a button that stores the tile you are standing on.
local function spotRow(label, kx, ky)
    local set = cfg[kx] ~= 0 or cfg[ky] ~= 0
    rowv(label, set and (cfg[kx] .. ", " .. cfg[ky]) or "not set", set and C.green or C.yellow)
    if button(" Capture - stand on it first ##" .. kx) then captureSpot(kx, ky, label) end
end

---------------- TAB: MAIN ----------------------------
local function tabMain()
    local label, col = statusInfo()
    textColored(col, label)
    ui("SameLine")
    local w = curWorld()
    textColored(C.gray, "   " .. (w ~= "" and w or "unknown"))
    if S.stepsTotal > 0 then
        progressBar(math.min(1, S.step / S.stepsTotal))
        textColored(C.gray, S.step .. " / " .. S.stepsTotal .. "   " .. MODES[cfg.mode] .. "   run #" .. S.runs)
    end

    ui("Spacing")
    rowv("Alive / Dead", tostring(getItemCount(cfg.aliveId) or "?") .. " / " .. tostring(getItemCount(cfg.deadId) or "?"), C.white)
    rowv("Retrieved / Charged", comma(S.retrieved) .. " / " .. comma(S.charged), C.green)
    rowv("Dropped / Taken", comma(S.dropped) .. " / " .. comma(S.taken), C.white)
    if S.failed > 0 then rowv("Failed", comma(S.failed), C.red) end

    ui("Spacing")
    ImGui.Separator()
    textColored(C.white, "Mode")
    for i, name in ipairs(MODES) do
        if i > 1 then ui("SameLine") end              -- all modes on one line
        local a, b = ImGui.RadioButton(name .. "##mode", cfg.mode == i)
        local picked = (b ~= nil) and (b == true) or (a == true)
        if picked then cfg.mode = i end
    end

    ui("Spacing")
    ImGui.Separator()
    if button(" Drop alive geigers when full: " .. (cfg.dropOn and "ON" or "OFF") .. " ") then cfg.dropOn = not cfg.dropOn end
    if cfg.dropOn then
        intInput("Full at", "fullAt", 1, 250)
        spotRow("Drop spot", "dropX", "dropY")
    end

    ui("Spacing")
    ImGui.Separator()
    if button(" Take dead geigers when out: " .. (cfg.takeOn and "ON" or "OFF") .. " ") then cfg.takeOn = not cfg.takeOn end
    if cfg.takeOn then
        spotRow("Take spot", "takeX", "takeY")
        textColored(C.gray, "Walks there at normal pace, picks them up, walks back.")
    end
end

---------------- TAB: OPTIONS -------------------------
local function tabOptions()
    local _, w = ImGui.InputText("World", cfg.world, 32)
    if w then cfg.world = w end
    textColored(C.gray, "Blank = current world, no warping.")

    ui("Spacing")
    if cfg.mode == 3 then
        if button(" Order: " .. (cfg.perCharger and "retrieve + charge at every stop" or "retrieve ALL, then charge ALL") .. " ") then
            cfg.perCharger = not cfg.perCharger
        end
    end
    if button(" Stand on top of chargers: " .. (cfg.standOnTop and "ON" or "OFF") .. " ") then cfg.standOnTop = not cfg.standOnTop end

    ui("Spacing")
    ImGui.Separator()
    local ordName = (cfg.walkOrder == 1 and "NEAREST NEXT") or (cfg.walkOrder == 3 and "RIGHT SIDE FIRST") or "LEFT SIDE FIRST"
    if button(" Walk order: " .. ordName .. " ") then
        cfg.walkOrder = (cfg.walkOrder % 3) + 1
    end
    if cfg.walkOrder ~= 1 then
        if button(" Inside a side: " .. (cfg.vertDown ~= false and "TOP -> BOTTOM" or "BOTTOM -> TOP") .. " ") then
            cfg.vertDown = not (cfg.vertDown ~= false)
        end
    end
    textColored(C.gray, "SIDE FIRST = finish one whole side, then the other (no zig-zag). NEAREST = shortest walk.")
end

---------------- TAB: TOOLS ---------------------------
local function tabTools()
    if button(" Scan area ") then startScan() end
    ui("SameLine")
    if button(" Dump to file ") then dumpChargers() end
    if button(" Reset count ") then
        if S.running then setMsg("Stop first, then reset.", false) else resetCount() end
    end

    ui("Spacing")
    ImGui.Separator()
    textColored(C.white, "Config  " .. (S.cfgPath or "autocharger_config.txt"))
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    ui("Spacing")
    ImGui.Separator()
    textColored(C.white, "Wallpaper id: " .. (cfg.wallpaperId > 0 and cfg.wallpaperId or "not set"))
    textColored(C.gray, "Chargers = blocks with this wallpaper behind them.")
    intInput("Wallpaper id", "wallpaperId", 0)
    if S.learnPunch then
        if button(" Waiting... click to cancel ") then S.learnPunch = false end
        textColored(C.cyan, "Now punch a Geiger Charger (with wallpaper) by hand.")
    else
        if button(" Learn wallpaper (punch a charger) ") then S.learnPunch = true end
    end
    intInput("Dead geiger id", "deadId", 1)
    intInput("Alive geiger id", "aliveId", 1)

    ui("Spacing")
    ImGui.Separator()
    if button(" Debug: " .. (cfg.debug and "ON" or "OFF") .. " ") then cfg.debug = not cfg.debug end
end

---------------- DRAW ---------------------------------
local function drawBody()
    if S.threadAlive and not S.running then
        textColored(C.yellow, "Stopping... please wait a second.")
    elseif not S.running then
        if bigButton(">  START CHARGER") then startRun() end
    else
        if bigButton("[]  STOP CHARGER",
            { 0.72, 0.20, 0.20, 1 }, { 0.85, 0.26, 0.26, 1 }, { 0.60, 0.15, 0.15, 1 }) then
            stopRun("stopped by user.")
        end
    end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    tab = navBegin(TABS, tab)

    if     tab == 1 then tabMain()
    elseif tab == 2 then tabOptions()
    else                 tabTools() end
    navEnd()
end

local drawErrors = 0
AddHook("ondraw", "ach_menu", function(dt)
    local nc, nv = pushTheme()
    beginWindow("Auto Geiger Charger", 600, 520)
    local widthPushed = ui("PushItemWidth", 240 * UI_SCALE)
    returnButton()

    if drawErrors < 3 then
        local ok, err = pcall(drawBody)
        if not ok then
            drawErrors = drawErrors + 1
            say("`4[Auto Charger] `wMenu error: " .. tostring(err))
        end
    end

    if widthPushed then ui("PopItemWidth") end
    navEnd()
    ImGui.End()
    popTheme(nc, nv)
end)

math.randomseed(os.time())
loadConfig(true)
say("`2[Auto Charger] `wv2 loaded." .. (S.cfgPath and " Config loaded." or "")
    .. (type(SendPacketRaw) == "function" and "" or " `4WARNING: SendPacketRaw not found!"))

ACTIVE.stop = function() stopRun("returned to loader.") end

end  -- startAutoCharger

--====================================================
--  TAX TO UWS  (module for Ben Loader)
--  Stand on the tile between the Princess and the Telephone:
--    Princess  = tile LEFT of you      Telephone = tile RIGHT of you
--  Loop: while you hold fewer than "Drop at" items -> Tax to P-Gems via the
--  telephone, wrench the Princess, buy. Once you hold enough -> drop a stack.
--  Uses the loader's shared helpers (C, ui, textColored, section, button,
--  bigButton, colorButton, rowv, pushTheme, popTheme).
--====================================================
local function startTaxToUWS()

---------------- SETTINGS (defaults) -----------------
local cfg = {
    delay      = 200,        -- ms between each step
    phoneNum   = "12345",    -- telephone number dialled for the tax
    itemId     = 12600,      -- item that is counted / dropped
    dropAt     = 249,        -- below this many -> keep buying; at/above -> drop
    dropCount  = 248,        -- how many to drop each time
    buyCount   = 2,          -- buy_count sent to the Princess
}

local CONFIG_PATHS = { "taxuws_config.txt", "scripts/taxuws_config.txt", "/sdcard/taxuws_config.txt" }
local SAVE_KEYS = { "delay", "phoneNum", "itemId", "dropAt", "dropCount", "buyCount" }
local SAVE_SET = {}
for _, k in ipairs(SAVE_KEYS) do SAVE_SET[k] = true end

---------------- STATE -------------------------------
local S = {
    running = false, threadAlive = false,
    stage = "Idle", stageCol = C.white,
    cycles = 0, drops = 0, dropped = 0,
    telX = 0, telY = 0, prX = 0, prY = 0,
    startedAt = 0, runAccum = 0,
    cfgPath = nil, uiMsg = nil, uiOk = true, uiUntil = 0,
}

---------------- HELPERS -----------------------------
local function say(msg) LogToConsole(msg) end
local function setMsg(text, ok) S.uiMsg, S.uiOk, S.uiUntil = text, ok, os.time() + 5 end
local function setStage(text, col) S.stage, S.stageCol = text, col or C.white end
local function comma(n)
    local r = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (r:gsub("^,", ""))
end
local function fmtClock(secs)
    secs = math.max(0, math.floor(secs))
    local h, m, s = secs // 3600, (secs % 3600) // 60, secs % 60
    if h > 0 then return string.format("%dh %02dm %02ds", h, m, s) end
    return string.format("%dm %02ds", m, s)
end

local function nap(ms)                            -- sleep that reacts quickly to STOP
    local left = ms
    while left > 0 and S.running do
        local s = math.min(250, left)
        Sleep(s)
        left = left - s
    end
end

local function myTile()
    local ok, x, y = pcall(function()
        local p = GetLocal().pos
        return p.x // 32, p.y // 32
    end)
    if ok then return x, y end
    return nil, nil
end

local function inv(id)
    local ok, n = pcall(function()
        for _, item in pairs(GetInventory()) do
            if item.id == id then return item.amount end
        end
        return 0
    end)
    if ok and type(n) == "number" then return n end
    return 0
end

local function wrench(x, y)
    SendPacketRaw(false, {
        type = 3, state = 32, value = 32,
        px = x, py = y, x = x * 32, y = y * 32,
    })
end

---------------- CONFIG SAVE / LOAD ------------------
local function saveConfig(silent)
    local lines = {}
    for _, k in ipairs(SAVE_KEYS) do lines[#lines + 1] = k .. "=" .. tostring(cfg[k]) end
    local data = table.concat(lines, "\n") .. "\n"
    local order = {}
    if S.cfgPath then order[1] = S.cfgPath end
    for _, p in ipairs(CONFIG_PATHS) do order[#order + 1] = p end
    for _, p in ipairs(order) do
        local ok, f = pcall(io.open, p, "w")
        if ok and f then
            if pcall(function() f:write(data) f:close() end) then
                S.cfgPath = p
                if not silent then setMsg("Config saved (" .. p .. ")", true) end
                return true
            end
        end
    end
    if not silent then setMsg("Could not save config (no writable path)", false) end
    return false
end

local function loadConfig(silent)
    for _, p in ipairs(CONFIG_PATHS) do
        local ok, f = pcall(io.open, p, "r")
        if ok and f then
            local rok, data = pcall(function() local d = f:read("*a") f:close() return d end)
            if rok and data and data ~= "" then
                for line in data:gmatch("[^\r\n]+") do
                    local k, v = line:match("^(%w+)=(.*)$")
                    if k and SAVE_SET[k] and cfg[k] ~= nil then
                        if type(cfg[k]) == "number" then cfg[k] = tonumber(v) or cfg[k]
                        else cfg[k] = v end
                    end
                end
                cfg.delay     = math.max(0, cfg.delay)
                cfg.dropAt    = math.max(1, cfg.dropAt)
                cfg.dropCount = math.max(1, cfg.dropCount)
                cfg.buyCount  = math.max(1, cfg.buyCount)
                S.cfgPath = p
                if not silent then setMsg("Config loaded", true) end
                return true
            end
        end
    end
    if not silent then setMsg("No saved config found", false) end
    return false
end

---------------- MAIN LOOP ---------------------------
local function mainLoop()
    local mx, my = myTile()
    if not mx then
        say("`4[Tax to UWS] `wCan't read your position.")
        return
    end
    S.telX, S.telY = mx + 1, my       -- telephone: right side
    S.prX,  S.prY  = mx - 1, my       -- princess: left side
    say(string.format("`2[Tax to UWS] `wStanding at %d,%d | Telephone %d,%d | Princess %d,%d",
        mx, my, S.telX, S.telY, S.prX, S.prY))

    while S.running do
        if inv(cfg.itemId) < cfg.dropAt then
            setStage("Tax to P-Gems", C.green)
            SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|" .. cfg.phoneNum
                .. "|\nx|" .. S.telX .. "|\ny|" .. S.telY .. "|\nbuttonClicked|tax_to_pgems")
            nap(cfg.delay)
            if not S.running then break end

            setStage("Wrenching Princess", C.cyan)
            wrench(S.prX, S.prY)
            nap(cfg.delay)
            if not S.running then break end

            setStage("Buying", C.yellow)
            SendPacket(2, "action|dialog_return\ndialog_name|princess_dialog\nx|" .. S.prX
                .. "|\ny|" .. S.prY .. "|\nbuyitem|actuallybuyitem13|\nbuy_count|" .. cfg.buyCount)
            S.cycles = S.cycles + 1
            nap(cfg.delay)
        else
            setStage("Dropping", C.yellow)
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. cfg.itemId
                .. "|\nitem_count|" .. cfg.dropCount)
            S.drops = S.drops + 1
            S.dropped = S.dropped + cfg.dropCount
            nap(cfg.delay)
        end
        if cfg.delay <= 0 then Sleep(10) end      -- never spin the game thread
    end
end

local function stopRun(reason)
    if not S.running then return end
    S.running = false
    S.runAccum = S.runAccum + (os.time() - S.startedAt)
    setStage("Stopping", C.yellow)
    say("`4[Tax to UWS] Stopped: `w" .. (reason or "stopped by user."))
end

local function startRun()
    if S.threadAlive then setMsg("Still stopping, try again in a second.", false) return end
    if type(SendPacketRaw) ~= "function" then setMsg("SendPacketRaw not found in this executor.", false) return end
    saveConfig(true)
    S.running, S.threadAlive = true, true
    S.startedAt = os.time()
    setStage("Starting", C.green)
    say("`2[Tax to UWS] `wStarted.")
    RunThread(function()
        local ok, err = pcall(mainLoop)
        if not ok then say("`4[Tax to UWS] `wError: " .. tostring(err)) end
        if S.running then
            S.running = false
            S.runAccum = S.runAccum + (os.time() - S.startedAt)
        end
        S.threadAlive = false
        setStage("Idle", C.white)
    end)
end

---------------- MENU ---------------------------------
local DEFAULTS = {}
for _, k in ipairs(SAVE_KEYS) do DEFAULTS[k] = cfg[k] end

local tab  = 1
local TABS = { "Stats", "Settings" }

local function intInput(label, key, min)
    local _, v = ImGui.InputInt(label, cfg[key])
    if v then cfg[key] = math.max(min, v) end
end

local function resetCount()
    S.cycles, S.drops, S.dropped, S.runAccum = 0, 0, 0, 0
    if S.running then S.startedAt = os.time() end
    setMsg("Count reset", true)
end

local function resetDefaults()
    for _, k in ipairs(SAVE_KEYS) do cfg[k] = DEFAULTS[k] end
    setMsg("Settings reset to default", true)
end

local function statusInfo()
    if S.threadAlive and not S.running then return "Stopping", C.yellow end
    if not S.running then return "Idle", C.white end
    return S.stage, S.stageCol
end

local function tabStats()
    local label, col = statusInfo()
    textColored(col, label)
    ui("SameLine")
    local mx, my = myTile()
    textColored(C.gray, "   you at " .. (mx and (mx .. "," .. my) or "unknown"))

    ui("Spacing")
    local have = inv(cfg.itemId)
    textColored(C.white, "Holding   " .. have .. " / " .. cfg.dropAt)
    progressBar(math.min(1, have / math.max(1, cfg.dropAt)))
    textColored(C.gray, "Drops a stack of " .. cfg.dropCount .. " when it reaches " .. cfg.dropAt .. ".")

    ui("Spacing")
    ImGui.Separator()
    ui("Spacing")

    local elapsed = S.runAccum + (S.running and (os.time() - S.startedAt) or 0)
    rowv("Buy cycles", comma(S.cycles), C.white)
    ui("Spacing")
    rowv("Drops", comma(S.drops), C.white)
    ui("Spacing")
    rowv("Items dropped", comma(S.dropped), C.green)
    ui("Spacing")
    rowv("Run time", fmtClock(elapsed), C.white)
    if S.running and S.telX ~= 0 then
        ui("Spacing")
        rowv("Telephone", S.telX .. ", " .. S.telY, C.gray)
        rowv("Princess", S.prX .. ", " .. S.prY, C.gray)
    end
    ui("Spacing")

    if button("Reset Count", -1, 30) then resetCount() end
end

local function tabSettings()
    textColored(C.white, "Setup")
    textColored(C.gray, "Stand between them: Princess on your LEFT,")
    textColored(C.gray, "Telephone on your RIGHT, then press START.")
    ui("Spacing")
    ImGui.Separator()

    intInput("Delay (ms)", "delay", 0)
    textColored(C.gray, "Pause between every step. Higher = slower / safer.")
    ui("Spacing")

    local _, n = ImGui.InputText("Phone number", cfg.phoneNum, 16)
    if n then cfg.phoneNum = n end

    intInput("Item id", "itemId", 1)
    intInput("Drop at", "dropAt", 1)
    textColored(C.gray, "Keeps buying while you hold fewer than this.")
    intInput("Drop amount", "dropCount", 1)
    intInput("Buy count", "buyCount", 1)
end

local function drawBody()
    if S.threadAlive and not S.running then
        textColored(C.yellow, "Stopping... please wait a second.")
    elseif not S.running then
        if bigButton(">  START TAX") then startRun() end
    else
        if bigButton("[]  STOP TAX",
            { 0.72, 0.20, 0.20, 1 }, { 0.85, 0.26, 0.26, 1 }, { 0.60, 0.15, 0.15, 1 }) then
            stopRun("stopped by user.")
        end
    end

    section("CONFIG")
    textColored(C.gray, S.cfgPath or "taxuws_config.txt")
    ui("SameLine")
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    tab = navBegin(TABS, tab)

    if tab == 1 then tabStats() else tabSettings() end
    navEnd()
end

local drawErrors = 0
AddHook("ondraw", "taxuws_menu", function(dt)
    local nc, nv = pushTheme()
    beginWindow("Tax to UWS", 600, 520)
    local widthPushed = ui("PushItemWidth", 220)
    returnButton()

    if drawErrors < 3 then
        local ok, err = pcall(drawBody)
        if not ok then
            drawErrors = drawErrors + 1
            say("`4[Tax to UWS] `wMenu error: " .. tostring(err))
        end
    end

    if widthPushed then ui("PopItemWidth") end
    navEnd()
    ImGui.End()
    popTheme(nc, nv)
end)

loadConfig(true)
say("`2[Tax to UWS] `wloaded." .. (S.cfgPath and " Config loaded." or "")
    .. (type(SendPacketRaw) == "function" and "" or " `4WARNING: SendPacketRaw not found!"))

ACTIVE.stop = function() stopRun("returned to loader.") end

end  -- startTaxToUWS

--====================================================
--  AUTO DROP / TRASH  (module for Ben Loader)
--  Pick items from your backpack and set, for each one, the amount at which
--  it should be dropped or trashed (1-250). The script keeps rotating through
--  your list: whenever you hold at least that many of an item, it drops (or
--  trashes / recycles) everything you have of it, then moves on to the next.
--  Uses the loader's shared helpers (C, ui, textColored, section, button,
--  bigButton, colorButton, rowv, pushTheme, popTheme).
--====================================================
local function startAutoDrop()

---------------- SETTINGS (defaults) -----------------
local cfg = {
    mode    = 1,        -- 1 = drop, 2 = trash / recycle
    delay   = 300,      -- ms pause after each drop / trash
    scanMs  = 200,      -- ms between checks of the whole list
    newAt   = 250,      -- amount a newly added item starts with
}
local rules = {}        -- { id = item id, at = amount that triggers it }

local CONFIG_PATHS = { "autodrop_config.txt", "scripts/autodrop_config.txt", "/sdcard/autodrop_config.txt" }
local SAVE_KEYS = { "mode", "delay", "scanMs", "newAt" }
local SAVE_SET = {}
for _, k in ipairs(SAVE_KEYS) do SAVE_SET[k] = true end

local MODE_NAME = { "DROP", "TRASH" }
local PROTECTED = { [18] = true, [32] = true }   -- fist and wrench can never be dropped

---------------- STATE -------------------------------
local S = {
    running = false, threadAlive = false,
    stage = "Idle", stageCol = C.white,
    actions = 0, items = 0, fails = 0,
    last = "-", cantDrop = false,
    perItem = {},                 -- id -> total handled this session
    skipUntil = {},               -- id -> os.time() before which a failed item is not retried
    startedAt = 0, runAccum = 0,
    cfgPath = nil, uiMsg = nil, uiOk = true, uiUntil = 0,
}

---------------- HELPERS -----------------------------
local function say(msg) LogToConsole(msg) end
local function setMsg(text, ok) S.uiMsg, S.uiOk, S.uiUntil = text, ok, os.time() + 5 end
local function setStage(text, col) S.stage, S.stageCol = text, col or C.white end
local function comma(n)
    local r = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (r:gsub("^,", ""))
end
local function fmtClock(secs)
    secs = math.max(0, math.floor(secs))
    local h, m, s = secs // 3600, (secs % 3600) // 60, secs % 60
    if h > 0 then return string.format("%dh %02dm %02ds", h, m, s) end
    return string.format("%dm %02ds", m, s)
end
local function clampAt(n) return math.max(1, math.min(250, math.floor(tonumber(n) or 1))) end

local function nap(ms)                            -- sleep that reacts quickly to STOP
    local left = ms
    while left > 0 and S.running do
        local s = math.min(250, left)
        Sleep(s)
        left = left - s
    end
end

local function getItemCount(id)                   -- nil if the inventory can't be read
    local ok, n = pcall(function()
        for _, itm in pairs(GetInventory()) do
            if itm.id == id then return itm.amount end
        end
        return 0
    end)
    if ok and type(n) == "number" then return n end
    return nil
end

local function tf(t, k)
    local ok, v = pcall(function() return t[k] end)
    if ok then return v end
    return nil
end

local nameCache = {}
local function itemName(id)
    local v = nameCache[id]
    if v then return v end
    v = "Item #" .. id
    for _, fn in ipairs({ "GetItemInfoByID", "GetItemByIDSafe", "GetItemInfo" }) do
        local f = _G[fn]
        if type(f) == "function" then
            local ok, info = pcall(f, id)
            if ok and info then
                local n = tf(info, "name")
                if type(n) == "string" and n ~= "" then v = n break end
            end
        end
    end
    nameCache[id] = v
    return v
end

local function ruleIndex(id)
    for i, r in ipairs(rules) do if r.id == id then return i end end
    return nil
end

local function addRule(id, at)
    id = math.floor(tonumber(id) or 0)
    if id <= 0 then setMsg("Enter a valid item id.", false) return end
    if PROTECTED[id] then setMsg("That item can't be dropped (fist / wrench).", false) return end
    if ruleIndex(id) then setMsg(itemName(id) .. " is already in the list.", false) return end
    rules[#rules + 1] = { id = id, at = clampAt(at or cfg.newAt) }
    setMsg("Added " .. itemName(id), true)
end

---------------- CONFIG SAVE / LOAD ------------------
local function saveConfig(silent)
    local lines = {}
    for _, k in ipairs(SAVE_KEYS) do lines[#lines + 1] = k .. "=" .. tostring(cfg[k]) end
    local rs = {}
    for _, r in ipairs(rules) do rs[#rs + 1] = r.id .. ":" .. r.at end
    lines[#lines + 1] = "rules=" .. table.concat(rs, ",")
    local data = table.concat(lines, "\n") .. "\n"
    local order = {}
    if S.cfgPath then order[1] = S.cfgPath end
    for _, p in ipairs(CONFIG_PATHS) do order[#order + 1] = p end
    for _, p in ipairs(order) do
        local ok, f = pcall(io.open, p, "w")
        if ok and f then
            if pcall(function() f:write(data) f:close() end) then
                S.cfgPath = p
                if not silent then setMsg("Config saved (" .. p .. ")", true) end
                return true
            end
        end
    end
    if not silent then setMsg("Could not save config (no writable path)", false) end
    return false
end

local function loadConfig(silent)
    for _, p in ipairs(CONFIG_PATHS) do
        local ok, f = pcall(io.open, p, "r")
        if ok and f then
            local rok, data = pcall(function() local d = f:read("*a") f:close() return d end)
            if rok and data and data ~= "" then
                for line in data:gmatch("[^\r\n]+") do
                    local k, v = line:match("^(%w+)=(.*)$")
                    if k == "rules" then
                        rules = {}
                        for id, at in v:gmatch("(%d+):(%d+)") do
                            local n = tonumber(id)
                            if n and not PROTECTED[n] and not ruleIndex(n) then
                                rules[#rules + 1] = { id = n, at = clampAt(at) }
                            end
                        end
                    elseif k and SAVE_SET[k] and cfg[k] ~= nil then
                        cfg[k] = tonumber(v) or cfg[k]
                    end
                end
                cfg.mode   = math.max(1, math.min(2, cfg.mode))
                cfg.delay  = math.max(0, cfg.delay)
                cfg.scanMs = math.max(50, cfg.scanMs)
                cfg.newAt  = clampAt(cfg.newAt)
                S.cfgPath = p
                if not silent then setMsg("Config loaded", true) end
                return true
            end
        end
    end
    if not silent then setMsg("No saved config found", false) end
    return false
end

---------------- DROP / TRASH -------------------------
local function packetFor(id, count)
    if cfg.mode == 2 then
        return "action|dialog_return\ndialog_name|trash\nitem_trash|" .. id .. "|\nitem_count|" .. count .. "\n"
    end
    return "action|dialog_return\ndialog_name|drop\nitem_drop|" .. id .. "|\nitem_count|" .. count .. "\n"
end

-- Handles one item: true = it went away, false = refused / nothing changed.
local function handle(r, have)
    local amt = math.min(have, 250)               -- the game box takes at most 250 at a time
    S.cantDrop = false
    SendPacket(2, packetFor(r.id, amt))
    local waited = 0
    while S.running and waited < 2000 do
        nap(100)
        waited = waited + 100
        local now = getItemCount(r.id)
        if now and now < have then
            local gone = have - now
            S.actions = S.actions + 1
            S.items = S.items + gone
            S.perItem[r.id] = (S.perItem[r.id] or 0) + gone
            S.last = MODE_NAME[cfg.mode] .. " " .. gone .. " x " .. itemName(r.id)
            return true
        end
        if S.cantDrop then break end
    end
    return false
end

local function mainLoop()
    while S.running do
        setStage("Watching " .. #rules .. " item(s)", C.green)
        for _, r in ipairs(rules) do
            if not S.running then return end
            local skip = S.skipUntil[r.id]
            if not skip or os.time() >= skip then
                local have = getItemCount(r.id)
                if have and have > 0 and have >= r.at then
                    setStage((cfg.mode == 2 and "Trashing " or "Dropping ") .. itemName(r.id), C.yellow)
                    if handle(r, have) then
                        S.skipUntil[r.id] = nil
                        nap(cfg.delay)
                    elseif S.running then
                        S.fails = S.fails + 1
                        S.skipUntil[r.id] = os.time() + 5       -- don't hammer it, try again in 5 s
                        S.last = "FAILED " .. itemName(r.id) .. (S.cantDrop and " (can't drop here)" or "")
                        say("`4[Auto Drop] `wCouldn't " .. (cfg.mode == 2 and "trash " or "drop ")
                            .. itemName(r.id) .. (S.cantDrop and " - no room to drop here, move to open floor." or "."))
                    end
                end
            end
        end
        nap(cfg.scanMs)
    end
end

local function stopRun(reason)
    if not S.running then return end
    S.running = false
    S.runAccum = S.runAccum + (os.time() - S.startedAt)
    setStage("Stopping", C.yellow)
    say("`4[Auto Drop] Stopped: `w" .. (reason or "stopped by user."))
end

local function startRun()
    if S.threadAlive then setMsg("Still stopping, try again in a second.", false) return end
    if #rules == 0 then setMsg("Add at least one item first (Items tab).", false) return end
    saveConfig(true)
    S.running, S.threadAlive = true, true
    S.skipUntil = {}
    S.startedAt = os.time()
    setStage("Starting", C.green)
    say("`2[Auto Drop] `wStarted: " .. MODE_NAME[cfg.mode] .. ", " .. #rules .. " item(s).")
    RunThread(function()
        local ok, err = pcall(mainLoop)
        if not ok then say("`4[Auto Drop] `wError: " .. tostring(err)) end
        if S.running then
            S.running = false
            S.runAccum = S.runAccum + (os.time() - S.startedAt)
        end
        S.threadAlive = false
        setStage("Idle", C.white)
    end)
end

---------------- HOOK ----------------
AddHook("onvariant", "autodrop_var", function(var)
    local ok, name = pcall(function() return tostring(var[0] or "") end)
    if not ok or name ~= "OnTextOverlay" then return false end
    local okt, txt = pcall(function() return tostring(var[1] or "") end)
    if okt then
        txt = txt:gsub("`.", ""):lower()
        if txt:find("can't drop", 1, true) or txt:find("cannot drop", 1, true) or txt:find("no room", 1, true) then
            S.cantDrop = true
        end
    end
    return false
end)

---------------- MENU ---------------------------------
local DEFAULTS = {}
for _, k in ipairs(SAVE_KEYS) do DEFAULTS[k] = cfg[k] end

local tab  = 1
local TABS = { "Stats", "Items", "Advanced" }

local function intInput(label, key, min)
    local _, v = ImGui.InputInt(label, cfg[key])
    if v then cfg[key] = math.max(min, v) end
end

local function resetCount()
    S.actions, S.items, S.fails, S.runAccum = 0, 0, 0, 0
    S.perItem, S.last = {}, "-"
    if S.running then S.startedAt = os.time() end
    setMsg("Count reset", true)
end

local function resetDefaults()
    for _, k in ipairs(SAVE_KEYS) do cfg[k] = DEFAULTS[k] end
    setMsg("Settings reset to default (item list kept)", true)
end

local function statusInfo()
    if S.threadAlive and not S.running then return "Stopping", C.yellow end
    if not S.running then return "Idle", C.white end
    return S.stage, S.stageCol
end

-- backpack picker: refreshed about once a second
local pick = { at = 0, list = {}, filter = "", addId = 0 }
local function refreshPick()
    if os.time() - pick.at < 1 then return end
    pick.at = os.time()
    local list = {}
    pcall(function()
        for _, itm in pairs(GetInventory()) do
            local id, amt = itm.id, itm.amount
            if id and amt and amt > 0 and not PROTECTED[id] then
                list[#list + 1] = { id = id, amount = amt, name = itemName(id) }
            end
        end
    end)
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    pick.list = list
end

local function tabStats()
    local label, col = statusInfo()
    textColored(col, label)
    ui("SameLine")
    textColored(C.gray, "   " .. MODE_NAME[cfg.mode] .. "   " .. #rules .. " item(s)")

    ui("Spacing")
    ImGui.Separator()
    ui("Spacing")

    local elapsed = S.runAccum + (S.running and (os.time() - S.startedAt) or 0)
    rowv("Actions", comma(S.actions), C.white)
    ui("Spacing")
    rowv("Items " .. (cfg.mode == 2 and "trashed" or "dropped"), comma(S.items), C.green)
    ui("Spacing")
    rowv("Failed", comma(S.fails), S.fails > 0 and C.red or C.white)
    ui("Spacing")
    rowv("Run time", fmtClock(elapsed), C.white)
    ui("Spacing")
    textColored(C.gray, "last: " .. S.last)

    if #rules > 0 then
        ui("Spacing")
        ImGui.Separator()
        textColored(C.white, "Per item")
        for _, r in ipairs(rules) do
            local have = getItemCount(r.id)
            rowv(itemName(r.id), (have or "?") .. " / " .. r.at .. "   done " .. comma(S.perItem[r.id] or 0),
                (have and have >= r.at) and C.yellow or C.gray)
        end
    end

    ui("Spacing")
    if button("Reset Count", -1, 30) then resetCount() end
end

local function tabItems()
    if button(" Action: " .. MODE_NAME[cfg.mode] .. (cfg.mode == 2 and "  (recycle)" or "") .. " ") then
        cfg.mode = (cfg.mode % 2) + 1
    end
    textColored(C.gray, "Click to switch between DROP and TRASH.")

    ui("Spacing")
    ImGui.Separator()
    textColored(C.white, "Selected items  (acts when you hold at least this many)")
    if #rules == 0 then textColored(C.yellow, "None yet - add some below.") end

    local removeAt = nil
    for i, r in ipairs(rules) do
        local have = getItemCount(r.id)
        textColored(C.white, itemName(r.id))
        ui("SameLine", math.max(250 * UI_SCALE, 120))
        textColored(C.gray, "have " .. tostring(have or "?"))
        local _, v = ImGui.InputInt("at##at" .. r.id, r.at)
        if v then r.at = clampAt(v) end
        ui("SameLine")
        if button(" Remove ##rm" .. r.id) then removeAt = i end
    end
    if removeAt then table.remove(rules, removeAt) end

    ui("Spacing")
    ImGui.Separator()
    textColored(C.white, "Add from backpack")
    local _, nat = ImGui.InputInt("New item at", cfg.newAt)
    if nat then cfg.newAt = clampAt(nat) end

    local _, f = ImGui.InputText("Search", pick.filter, 32)
    if f then pick.filter = f end

    refreshPick()
    local q, shown = pick.filter:lower(), 0
    for _, e in ipairs(pick.list) do
        if (q == "" or e.name:lower():find(q, 1, true)) and not ruleIndex(e.id) then
            shown = shown + 1
            if shown > 25 then
                textColored(C.gray, "... more, use Search to narrow it down")
                break
            end
            textColored(C.white, e.name .. "  x" .. e.amount)
            ui("SameLine", math.max(290 * UI_SCALE, 140))
            if button(" Add ##add" .. e.id) then addRule(e.id, cfg.newAt) end
        end
    end
    if shown == 0 then textColored(C.gray, "Nothing matches in your backpack.") end

    ui("Spacing")
    ImGui.Separator()
    local _, aid = ImGui.InputInt("Add by item id", pick.addId)
    if aid then pick.addId = math.max(0, aid) end
    if button(" Add id ") then addRule(pick.addId, cfg.newAt) end
end

local function tabAdvanced()
    intInput("Delay after action (ms)", "delay", 0)
    textColored(C.gray, "Pause after each drop / trash. Higher = slower / safer.")
    ui("Spacing")
    intInput("Check list every (ms)", "scanMs", 50)
    textColored(C.gray, "How often the list is rotated through.")
    ui("Spacing")
    textColored(C.gray, "Drop needs open floor next to you. If it says can't drop,")
    textColored(C.gray, "move and the item is retried after 5 seconds.")
end

local function drawBody()
    if S.threadAlive and not S.running then
        textColored(C.yellow, "Stopping... please wait a second.")
    elseif not S.running then
        if bigButton(">  START " .. MODE_NAME[cfg.mode]) then startRun() end
    else
        if bigButton("[]  STOP " .. MODE_NAME[cfg.mode],
            { 0.72, 0.20, 0.20, 1 }, { 0.85, 0.26, 0.26, 1 }, { 0.60, 0.15, 0.15, 1 }) then
            stopRun("stopped by user.")
        end
    end

    section("CONFIG")
    textColored(C.gray, S.cfgPath or "autodrop_config.txt")
    ui("SameLine")
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    tab = navBegin(TABS, tab)

    if     tab == 1 then tabStats()
    elseif tab == 2 then tabItems()
    else                 tabAdvanced() end
    navEnd()
end

local drawErrors = 0
AddHook("ondraw", "autodrop_menu", function(dt)
    local nc, nv = pushTheme()
    beginWindow("Auto Drop / Trash", 600, 520)
    local widthPushed = ui("PushItemWidth", 200)
    returnButton()

    if drawErrors < 3 then
        local ok, err = pcall(drawBody)
        if not ok then
            drawErrors = drawErrors + 1
            say("`4[Auto Drop] `wMenu error: " .. tostring(err))
        end
    end

    if widthPushed then ui("PopItemWidth") end
    navEnd()
    ImGui.End()
    popTheme(nc, nv)
end)

loadConfig(true)
say("`2[Auto Drop] `wloaded." .. (S.cfgPath and " Config loaded." or ""))

ACTIVE.stop = function() stopRun("returned to loader.") end

end  -- startAutoDrop

---------------- LOADER MENU ---------------------------
--====================================================
--  /buybgl - always-on helper (works with or without a launched script)
--  Type /buybgl in chat to toggle ON/OFF. While ON, wrenching a Telephone
--  automatically: dials 53785 -> picks Blue Gem Lock -> clicks Thank you,
--  with the dialogs hidden.
--
--  /buybgl   toggle ON/OFF (the only command)
--  The world-chat report is said only when you switch it ON or OFF.
--====================================================
do
    local BGL = {
        on       = false,
        debug    = false,
        number   = "53785",
        want     = "blue gem lock",  -- button label to pick (case-insensitive)
        thanks   = "thank",          -- button label to finish with
        delayMs  = 35,               -- pause (ms) before each reply
        lastAct  = nil,              -- time of our last reply
        -- SAFETY: everything is driven by YOUR wrench packets, never by what the
        -- server sends. One wrench = one dial = one buy = one thank-you click.
        c1 = 0, c2 = 0, c3 = 0,      -- dial / buy / thank-you credits
        grantAt  = 0,                -- credits expire 5 s after the last grant
        bought   = 0,                -- this session
        wx = nil, wy = nil,          -- last wrenched tile
    }
    local TAG  = "`b[`2Buy`9BGL`B]"

    local function blog(m) LogToConsole("`2[BuyBGL] `o" .. tostring(m)) end
    local function bdbg(m) if BGL.debug then blog(m) end end
    local function bclean(t) return (tostring(t or ""):gsub("`.", "")) end
    local function fresh() return os.time() - BGL.grantAt <= 5 end
    local function touch() BGL.grantAt = os.time() end
    local function dropOld()
        if not fresh() then BGL.c1, BGL.c2, BGL.c3 = 0, 0, 0 end
    end

    -- One real wrench of yours = one dial credit. Both the text form
    -- ("action|wrench") and the raw tile packet (type 3, item 32) call this;
    -- a second copy within 50 ms (several hooks firing) is ignored.
    local function grantWrench()
        if not BGL.on then return end
        local c = os.clock()
        if BGL.wrenchClock ~= nil and c >= BGL.wrenchClock and c - BGL.wrenchClock <= 0.05 then
            return
        end
        BGL.wrenchClock = c
        dropOld()
        BGL.c1 = BGL.c1 + 1
        touch()
    end

    local function bfield(var, name, idx)
        local ok, v = pcall(function() return var[name] end)
        if ok and v ~= nil then return v end
        ok, v = pcall(function() return var[idx] end)
        if ok and v ~= nil then return v end
        return nil
    end

    ------------------------------------------------ world-chat report
    -- exactly ONE line when switched ON and ONE line when switched OFF
    local function reportToggle(on)
        SendPacket(2, "action|input\n|text|" .. TAG .. " `3Auto Buy BGL "
            .. (on and "`2ON" or "`4OFF"))
    end

    ------------------------------------------------ dialog handling
    local function later(ms, fn)
        if ms <= 0 then fn() return end
        if type(RunThread) == "function" then
            local ok = pcall(RunThread, function()
                if type(Sleep) == "function" then pcall(Sleep, ms) end
                fn()
            end)
            if ok then return end
        end
        fn()
    end

    local function buildReply(dialog, dname, extra)
        local p = "action|dialog_return\ndialog_name|" .. dname .. "\n"
        local got = false
        for k, v in dialog:gmatch("embed_data|([^|\n]+)|([^|\n]*)") do
            p = p .. k .. "|" .. v .. "|\n"
            got = true
        end
        if not got and BGL.wx and BGL.wy then
            p = p .. "tilex|" .. BGL.wx .. "|\ntiley|" .. BGL.wy .. "|\n"
        end
        return p .. extra
    end

    local function send(pkt, what)
        BGL.lastAct = os.time()
        later(BGL.delayMs, function()
            SendPacket(2, pkt)
            bdbg("sent (" .. what .. "):\n" .. pkt)
        end)
    end

    local function findButton(dialog, word)
        for name, label in dialog:gmatch("add_button|([^|\n]*)|([^|\n]*)|") do
            if bclean(label):lower():find(word, 1, true) then return name end
        end
        return nil
    end

    local function isPhoneDialog(dialog, dname)
        if not dialog:find("add_text_input|", 1, true) then return false end
        local low = bclean(dialog):lower()
        return low:find("telephone", 1, true) ~= nil
            or low:find("phone #", 1, true) ~= nil
            or low:find("dial a number", 1, true) ~= nil
            or dname:lower():find("phone", 1, true) ~= nil
    end

    local function onVariant(var)
        if not BGL.on then return false end
        local fname = bfield(var, "v1", 0)
        if fname == "OnTextOverlay" or fname == "OnTalkBubble" or fname == "OnConsoleMessage" then
            local low = (bclean(bfield(var, "v2", 1)) .. " " .. bclean(bfield(var, "v3", 2))):lower()
            if low:find("you got", 1, true) and low:find("blue gem lock", 1, true) then
                return true                                -- hide the banner
            end
            return false
        end
        if fname ~= "OnDialogRequest" then return false end
        local dialog = tostring(bfield(var, "v2", 1) or "")
        local dname  = dialog:match("end_dialog|([^|]*)|") or ""
        if BGL.debug then
            blog(string.format("dialog seen: name=%s\n%s", dname, dialog))
        end

        -- No step counter: every dialog is recognised by what it contains, so
        -- spam-wrenching (several buys at once) can't mix the steps up.

        -- 1) telephone -> type the number, press Dial
        if isPhoneDialog(dialog, dname) then
            local input  = dialog:match("add_text_input|([^|]*)|") or "num"
            local okText = dialog:match("end_dialog|[^|]*|[^|]*|([^|]*)|") or "Dial"
            local btn = bclean(okText):lower()
            if btn == "" then btn = "dial" end
            dropOld()
            if BGL.c1 > 0 then
                BGL.c1, BGL.c2 = BGL.c1 - 1, BGL.c2 + 1
                touch()
                send(buildReply(dialog, dname,
                    input .. "|" .. BGL.number .. "\nbuttonClicked|" .. btn .. "\n"), "dial")
            else
                blog("telephone dialog without a wrench from you - ignored")
            end
            return true
        end

        -- 2) menu with a Blue Gem Lock button -> click it
        local b = findButton(dialog, BGL.want)
        if b then
            dropOld()
            if BGL.c2 > 0 then
                BGL.c2, BGL.c3 = BGL.c2 - 1, BGL.c3 + 1                 -- one wrench = one buy
                touch()
                send(buildReply(dialog, dname, "buttonClicked|" .. b .. "\n"), "pick BGL")
            end
            return true                                                 -- never buy without a credit
        end

        -- 3) "Thank you" dialog of the telephone -> click Thank you
        local inFlow = BGL.lastAct ~= nil and (os.time() - BGL.lastAct) <= 6
        local isPhoneName = dname:lower():find("phone", 1, true) ~= nil
        local t = findButton(dialog, BGL.thanks)
        if t and (isPhoneName or inFlow) then
            dropOld()
            if BGL.c3 > 0 then
                BGL.c3 = BGL.c3 - 1
                send(buildReply(dialog, dname, "buttonClicked|" .. t .. "\n"), "thank you")
                BGL.bought = BGL.bought + 1
                blog("Bought Blue Gem Lock #" .. BGL.bought)
            end
            return true
        end

        -- anything else that belongs to the buy flow: hide it
        local low = bclean(dialog):lower()
        if low:find("blue gem lock", 1, true) or (inFlow and isPhoneName) then
            bdbg("hid extra dialog: " .. dname)
            return true
        end
        return false
    end

    local function onSend(ptype, packet)
        if type(packet) ~= "string" then return false end

        local cmd = packet:match("action|input\n|text|(/buybgl[^\n]*)")
        if cmd then
            BGL.on = not BGL.on
            BGL.c1, BGL.c2, BGL.c3 = 0, 0, 0
            if BGL.on then BGL.bought = 0 end
            local m = BGL.on and "/buybgl ON - wrench a Telephone" or "/buybgl OFF"
            blog(m)
            reportToggle(BGL.on)
            return true   -- don't send the command to the server
        end

        if packet:find("action|wrench", 1, true) and not packet:find("|netid|", 1, true) then grantWrench() end   -- (a wrench on yourself, e.g. from Auto Buff, is not a telephone)
        if packet:find("action|wrench", 1, true) then
            BGL.wx = packet:match("|x|(%-?%d+)") or BGL.wx
            BGL.wy = packet:match("|y|(%-?%d+)") or BGL.wy
        end
        if BGL.debug and packet:find("dialog_return", 1, true) then
            blog("OUTGOING:\n" .. packet)
        end
        return false
    end

    -- Register under both capitalisations, but run the handler ONCE per event
    -- and hand the SAME answer to both hooks. (If one of them answered
    -- "false", the executor could un-hide the dialog.)
    local WRENCH_ID = 32
    local function onSendRaw(pkt)
        if not BGL.on then return false end
        local ok, t, v = pcall(function() return pkt.type, pkt.value end)
        if ok and t == 3 and v == WRENCH_ID then
            local okp, px, py = pcall(function() return pkt.px, pkt.py end)
            if okp and px and py then BGL.wx, BGL.wy = tostring(px), tostring(py) end
            grantWrench()
        end
        return false
    end

    local function reg(events, name, fn, keyOf)
        local lastKey, lastRes, lastT, lastC
        for i, ev in ipairs(events) do
            pcall(AddHook, ev, name .. i, function(...)
                local key = keyOf(...)
                local t, c = os.time(), os.clock()
                if key ~= nil and key == lastKey and t == lastT and (c - lastC) < 0.01 then
                    return lastRes
                end
                local res = fn(...)
                lastKey, lastRes, lastT, lastC = key, res, t, c
                return res
            end)
        end
    end
    reg({ "OnVariant", "onvariant" }, "buybgl_v", onVariant, function(var)
        local v1 = bfield(var, "v1", 0)
        if v1 ~= "OnDialogRequest" then return nil end      -- not worth caching
        return tostring(bfield(var, "v2", 1))
    end)
    reg({ "onsendpacketraw", "OnSendPacketRaw" }, "buybgl_r", onSendRaw, function() return nil end)
    reg({ "OnSendPacket", "onsendpacket" }, "buybgl_s", onSend, function(_, packet)
        return type(packet) == "string" and packet or nil
    end)
    LogToConsole("`2[BuyBGL] `oReady. Type /buybgl to toggle.")
end

local function startAutoSpam()
--====================================================
--  AUTO SPAM  (plain world-chat spam) + ImGui menu
--  - same concept as Auto SB: type the text or capture it from a sign
--  - spam delay in milliseconds, runs until you press STOP
--  - no amount / total, no gems, no warping
--====================================================

local cfg = {
    text  = "Selling items! Visit my world!",
    delay = 3000,            -- milliseconds between each spam line
}

local CONFIG_PATHS = { "autospam_config.txt", "scripts/autospam_config.txt", "/sdcard/autospam_config.txt" }
local SAVE_KEYS = { "text", "delay" }
local SAVE_SET = {}
for _, k in ipairs(SAVE_KEYS) do SAVE_SET[k] = true end

local S = {
    running = false,
    threadAlive = false,
    sent = 0,
    captureArmed = false,
    cfgPath = nil,
    uiMsg = nil, uiOk = true, uiUntil = 0,
}

local function say(msg) LogToConsole(msg) end
local function sendText(text) SendPacket(2, "action|input\n|text|" .. text) end
local function strip(s) return (tostring(s):gsub("`%S", "")) end
local function setMsg(text, ok) S.uiMsg, S.uiOk, S.uiUntil = text, ok, os.time() + 5 end

---------------- CONFIG ----------------
local function saveConfig(silent)
    local lines = {}
    for _, k in ipairs(SAVE_KEYS) do lines[#lines + 1] = k .. "=" .. tostring(cfg[k]) end
    local data = table.concat(lines, "\n") .. "\n"
    local order = {}
    if S.cfgPath then order[1] = S.cfgPath end
    for _, p in ipairs(CONFIG_PATHS) do order[#order + 1] = p end
    for _, p in ipairs(order) do
        local ok, f = pcall(io.open, p, "w")
        if ok and f then
            if pcall(function() f:write(data) f:close() end) then
                S.cfgPath = p
                if not silent then setMsg("Config saved (" .. p .. ")", true) end
                return true
            end
        end
    end
    if not silent then setMsg("Could not save config (no writable path)", false) end
    return false
end

local function loadConfig(silent)
    for _, p in ipairs(CONFIG_PATHS) do
        local ok, f = pcall(io.open, p, "r")
        if ok and f then
            local rok, data = pcall(function() local d = f:read("*a") f:close() return d end)
            if rok and data and data ~= "" then
                for line in data:gmatch("[^\r\n]+") do
                    local k, v = line:match("^(%w+)=(.*)$")
                    if k and SAVE_SET[k] and cfg[k] ~= nil then
                        if type(cfg[k]) == "number" then cfg[k] = tonumber(v) or cfg[k] else cfg[k] = v end
                    end
                end
                cfg.delay = math.max(100, cfg.delay)
                S.cfgPath = p
                if not silent then setMsg("Config loaded", true) end
                return true
            end
        end
    end
    if not silent then setMsg("No saved config found", false) end
    return false
end

local DEFAULTS = {}
for _, k in ipairs(SAVE_KEYS) do DEFAULTS[k] = cfg[k] end

---------------- SIGN TEXT CAPTURE ----------------
-- Armed by the "Capture from Sign" button, grabs the text of the next
-- sign-edit dialog (wrench a sign) and disarms itself after one attempt.
AddHook("onvariant", "autospam_sign_capture", function(var)
    if not S.captureArmed then return false end
    if var[0] ~= "OnDialogRequest" then return false end
    local dialog = tostring(var[1] or "")
    if not dialog:find("sign_edit", 1, true) then return false end

    S.captureArmed = false
    local text = dialog:match("add_text_input|display_text||(.-)|%d+|")
    if not text then
        setMsg("Could not find text in that dialog.", false)
        return false
    end
    cfg.text = text                           -- keep colour codes like the sign has
    setMsg("Captured from sign: " .. strip(text), true)
    say("`2[Auto Spam] `wCaptured spam text from sign: `9" .. strip(text))
    return false
end)

---------------- START / STOP / LOOP ----------------
local function stop(reason)
    S.running = false
    say("`4[Auto Spam] Stopped: `w" .. reason)
end

-- The loop runs in its own thread (not in the draw hook), so it keeps
-- spamming even when Growtopia is minimized and nothing is being drawn.
local function mainLoop()
    while S.running do
        -- not in a world (disconnected / world menu): wait instead of spamming nothing
        local okW, w = pcall(function() return GetWorld() end)
        if not (okW and w == nil) then
            if cfg.text ~= "" then
                sendText(cfg.text)
                S.sent = S.sent + 1
            end
        end
        -- sleep in small steps so STOP reacts fast even with a long delay
        local left = math.max(100, cfg.delay)
        while S.running and left > 0 do
            local step = math.min(left, 200)
            Sleep(step)
            left = left - step
        end
    end
end

local function start()
    if S.threadAlive then setMsg("Still stopping, try again in a second.", false) return end
    if cfg.text == "" then say("`4[Auto Spam] Please enter a spam text first.") return end
    if type(RunThread) ~= "function" then setMsg("RunThread not found in this executor.", false) return end
    cfg.delay = math.max(100, cfg.delay)
    saveConfig(true)
    S.running, S.threadAlive = true, true
    say("`2[Auto Spam] Started, delay " .. cfg.delay .. "ms")
    RunThread(function()
        local ok, err = pcall(mainLoop)
        if not ok then say("`4[Auto Spam] `wError: " .. tostring(err)) end
        S.running, S.threadAlive = false, false
    end)
end

---------------- UI ----------------
local function intInput(label, key, min)
    local _, v = ImGui.InputInt(label, cfg[key])
    if v then cfg[key] = math.max(min, v) end
end

AddHook("ondraw", "autospam_menu", function(dt)
    local nc, nv = pushTheme()
    beginWindow("Auto Spam", 520, 400)
    local widthPushed = ui("PushItemWidth", 240 * UI_SCALE)
    returnButton()

    if not S.running then
        if bigButton(">  START SPAM") then start() end
    else
        if bigButton("[]  STOP SPAM",
            { 0.72, 0.20, 0.20, 1 }, { 0.85, 0.26, 0.26, 1 }, { 0.60, 0.15, 0.15, 1 }) then
            stop("stopped by user.")
        end
    end

    section("CONFIG")
    textColored(C.gray, S.cfgPath or "autospam_config.txt")
    ui("SameLine")
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then
        for _, k in ipairs(SAVE_KEYS) do cfg[k] = DEFAULTS[k] end
        setMsg("Settings reset to default", true)
    end
    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    section("STATUS")
    textColored(S.running and C.green or C.white, S.running and "Running" or "Idle")
    rowv("Lines sent", tostring(S.sent), C.white)
    if button("Reset Count", -1, 26) then S.sent = 0 end

    section("SPAM")
    local _, t = ImGui.InputText("Spam Text", cfg.text, 128)
    if t then cfg.text = t end

    if S.captureArmed then
        if button(" Waiting... click to cancel ") then
            S.captureArmed = false
            setMsg("Capture cancelled.", true)
        end
        textColored(C.cyan, "Now go wrench/punch the sign in-game.")
    else
        if button(" Capture from Sign ") then
            S.captureArmed = true
            setMsg("Armed - go wrench a sign now.", true)
        end
        textColored(C.gray, "Click, then wrench a sign to copy its text.")
    end

    intInput("Delay (ms)", "delay", 100)
    textColored(C.gray, string.format("= %.1f seconds between each line", cfg.delay / 1000))
    textColored(C.gray, "Preview: " .. strip(cfg.text))

    if widthPushed then ui("PopItemWidth") end
    ImGui.End()
    popTheme(nc, nv)
end)

loadConfig(true)
say("`2[Auto Spam] loaded." .. (S.cfgPath and " Config loaded." or ""))

ACTIVE.stop = function() stop("returned to loader.") end

end  -- startAutoSpam

local LOADER_OPTIONS = {
    { name = "Auto Super Broadcast", run = startAutoSB },
    { name = "Vend Helper",          run = startVendHelper },
    { name = "Auto Geiger",           run = startGeiger },
    { name = "Auto Crystal Combine",  run = startAutoCrystal },
    { name = "Auto Geiger Charger",   run = startAutoCharger },
    { name = "Tax to UWS",            run = startTaxToUWS },
    { name = "Auto Drop / Trash",     run = startAutoDrop },
    { name = "Auto Spam",             run = startAutoSpam },
}
local loader = { selected = 1, launched = false, launchedName = nil, err = nil, gate = nil }

---------------- HIDE / SHOW HOTKEY ----------------------
-- Hides / shows ALL menus (loader + launched script). Scripts keep running
-- while hidden: their draw hooks still run, but ImGui is swapped for a
-- do-nothing stand-in, so nothing is drawn.
--   * Chat command  /loader  ALWAYS works (no key reading needed).
--   * Hotkey (default TAB) works when the executor can read keys; the
--     first working method is picked automatically (see BACKENDS).
-- The key can be changed from the loader menu only (benloader_config.txt).
local UI = { hidden = false }
local realImGui = ImGui
local noop = function() return false end
local NULL_IMGUI = setmetatable({}, { __index = function(_, k)
    local v = realImGui[k]
    if type(v) == "function" then return noop end
    return v                                    -- tables like Col / StyleVar stay real
end })

local HK = { name = "Tab", spec = nil, capturing = false, last = 0, wasDown = false,
             base = nil, bk = nil, retry = 0 }
local HK_PATHS = { "benloader_config.txt", "scripts/benloader_config.txt", "/sdcard/benloader_config.txt" }

-- Windows virtual-key codes <-> names
local VKS, VKNAME = {}, {}
local function defVK(name, code) VKS[name] = code VKNAME[code] = name end
defVK("Backspace", 8) defVK("Tab", 9) defVK("Enter", 13) defVK("Escape", 27) defVK("Space", 32)
defVK("PageUp", 33) defVK("PageDown", 34) defVK("End", 35) defVK("Home", 36)
defVK("Left", 37) defVK("Up", 38) defVK("Right", 39) defVK("Down", 40)
defVK("Insert", 45) defVK("Delete", 46) defVK("Grave", 192) defVK("Backslash", 220)
for i = 0, 9 do defVK(tostring(i), 48 + i) end
for i = 0, 25 do defVK(string.char(65 + i), 65 + i) end
for i = 1, 12 do defVK("F" .. i, 111 + i) end

local function keyTable()                         -- ImGui's own key enum, if the binding has one
    for _, get in ipairs({ function() return ImGui.Key end, function() return _G.ImGuiKey end }) do
        local ok, t = pcall(get)
        if ok and (type(t) == "table" or type(t) == "userdata") then return t end
    end
    return nil
end

local function imCode(name)                       -- ImGui key code for a key name (nil = unknown)
    local kt = keyTable()
    if kt then
        for _, k in ipairs({ name, "ImGuiKey_" .. name }) do
            local ok, v = pcall(function() return kt[k] end)
            if ok and v ~= nil then return v end
        end
        return nil
    end
    if name == "Tab" then return 512 end          -- ImGuiKey_Tab in current ImGui
    local n = name:match("^Key#(%d+)$")
    return n and tonumber(n) or nil
end

local function specFor(name)
    return { name = name, vk = VKS[name] or tonumber(name:match("^Key#(%d+)$") or ""), im = imCode(name) }
end

local function winState(fname, k)                 -- GetAsyncKeyState-style: high bit = down
    local f = _G[fname]
    if type(f) ~= "function" or k.vk == nil then return nil end
    local ok, r = pcall(f, k.vk)
    if not ok then return nil end
    if type(r) == "boolean" then return r end
    if type(r) == "number" then
        if r < 0 then return true end
        local i = math.tointeger(r)
        return i ~= nil and (i & 0x8000) ~= 0
    end
    return false
end

local function globalKey(fname, k)                -- IsKeyDown(vk) / IsKeyPressed(vk) style
    local f = _G[fname]
    if type(f) ~= "function" or k.vk == nil then return nil end
    local ok, r = pcall(f, k.vk)
    if not ok then return nil end
    return r == true or (type(r) == "number" and r ~= 0)
end

-- Each backend answers true/false, or nil when it can't be used.
-- "pressed" = true only on the frame the key goes down; "down" = held (edge is detected here).
local BACKENDS = {
    { name = "ImGui.IsKeyPressed", im = true, pressed = function(k)
        local f = ImGui.IsKeyPressed
        if type(f) ~= "function" or k.im == nil then return nil end
        local ok, r = pcall(f, k.im, false)
        if not ok then ok, r = pcall(f, k.im) end
        if ok then return r == true end
        return nil
    end },
    { name = "ImGui.IsKeyDown", im = true, down = function(k)
        local f = ImGui.IsKeyDown
        if type(f) ~= "function" or k.im == nil then return nil end
        local ok, r = pcall(f, k.im)
        if ok then return r == true end
        return nil
    end },
    -- GetKeyState follows the game's own input queue, so it ignores keys pressed in other windows.
    { name = "GetKeyState",      down = function(k) return winState("GetKeyState", k) end },
    -- these see the whole system (even other windows) -> "global": gated by a game-focus check
    { name = "GetAsyncKeyState", global = true, down = function(k) return winState("GetAsyncKeyState", k) end },
    { name = "IsKeyDown",        global = true, down = function(k) return globalKey("IsKeyDown", k) end },
    { name = "IsKeyPressed",     global = true, pressed = function(k) return globalKey("IsKeyPressed", k) end },
}

local function pickBackend()
    if HK.bk then return HK.bk end
    local tab = specFor("Tab")
    for _, b in ipairs(BACKENDS) do
        local f = b.pressed or b.down
        if f(tab) ~= nil then HK.bk = b return b end
    end
    return nil
end

local SKIP_KEY = { "Mouse", "Gamepad", "Mod", "Reserved", "Count", "COUNT", "None", "Nav", "Keys" }
local function candidates()                       -- every key the active backend can test
    local list = {}
    if HK.bk.im then
        local kt = keyTable()
        if kt then
            pcall(function()
                for k, v in pairs(kt) do
                    if type(k) == "string" then
                        local nm, skip = (k:gsub("^ImGuiKey_", "")), false
                        for _, s in ipairs(SKIP_KEY) do
                            if nm:find(s, 1, true) then skip = true break end
                        end
                        if not skip then list[#list + 1] = { name = nm, im = v, vk = VKS[nm] } end
                    end
                end
            end)
        else
            for c = 512, 652 do list[#list + 1] = { name = "Key#" .. c, im = c } end
        end
    else
        for vk = 8, 254 do list[#list + 1] = { name = VKNAME[vk] or ("Key#" .. vk), vk = vk } end
    end
    return list
end

local function captureTick()                      -- returns the key spec being pressed, if any
    local b, list = HK.bk, candidates()
    if b.pressed then
        for _, k in ipairs(list) do if b.pressed(k) == true then return k end end
        return nil
    end
    if not HK.base then                           -- ignore keys that are already held when capture starts
        HK.base = {}
        for _, k in ipairs(list) do if b.down(k) == true then HK.base[k.name] = true end end
        return nil
    end
    for _, k in ipairs(list) do
        local d = b.down(k) == true
        if d and not HK.base[k.name] then return k end
        if not d then HK.base[k.name] = nil end
    end
    return nil
end

local function saveHotkey()
    for _, pth in ipairs(HK_PATHS) do
        local ok, f = pcall(io.open, pth, "w")
        if ok and f and pcall(function() f:write("hotkey=" .. HK.name .. "\n") f:close() end) then return true end
    end
    return false
end

local function setHotkey(name)
    local s = specFor(name)
    if s.vk == nil and s.im == nil then name, s = "Tab", specFor("Tab") end
    HK.name, HK.spec = name, s
end

local function loadHotkey()
    for _, pth in ipairs(HK_PATHS) do
        local ok, f = pcall(io.open, pth, "r")
        if ok and f then
            local rok, data = pcall(function() local d = f:read("*a") f:close() return d end)
            local nm = rok and data and data:match("hotkey=([%w#_]+)")
            if nm then setHotkey(nm) end
            return
        end
    end
end

local function toggleHidden()
    UI.hidden = not UI.hidden
    LogToConsole("`2[Ben Loader] `wMenus " .. (UI.hidden and "hidden" or "shown")
        .. " - type `9/loader `wor press `9" .. HK.name:upper() .. " `wto " .. (UI.hidden and "show" or "hide") .. " them")
end

-- Is the game window the one in front? true / false, or nil when this executor can't tell.
local function focusApi()
    local okIO, gio = pcall(function() return ImGui.GetIO() end)
    if okIO and gio ~= nil then
        local ok, v = pcall(function() return gio.AppFocusLost end)
        if ok and type(v) == "boolean" then return not v end
    end
    for _, fn in ipairs({ "IsGameFocused", "IsAppFocused", "IsWindowFocused", "IsFocused", "HasFocus" }) do
        local f = _G[fn]
        if type(f) == "function" then
            local ok, r = pcall(f)
            if ok and type(r) == "boolean" then return r end
        end
    end
    return nil
end

-- Fallback when there is no focus API: ask Windows which program is in front, through a tiny
-- PowerShell script run in the background (no game freeze; the answer arrives about half a second later).
local FG_PS = [==[
Add-Type -Name W -Namespace N -MemberDefinition '[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow(); [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr h, out int p);'
$m = New-Object System.Threading.Mutex($false, "Global\BenLoaderFg")
if (-not $m.WaitOne(0)) { exit }
$f = "$PSScriptRoot\benloader_fg.txt"
while ($true) {
    $p = 0
    [void][N.W]::GetWindowThreadProcessId([N.W]::GetForegroundWindow(), [ref]$p)
    $n = ""
    try { $n = (Get-Process -Id $p -ErrorAction Stop).ProcessName } catch {}
    try { [IO.File]::WriteAllText($f, $n) } catch {}
    if (-not (Get-Process | Where-Object { $_.ProcessName -like "Growtopia*" })) { break }
    Start-Sleep -Milliseconds 150
}
]==]

-- A tiny background PowerShell loop keeps "which program is in front" in benloader_fg.txt
-- (refreshed every ~150 ms). The hotkey just READS that file, so the check is instant and
-- a key pressed while another window is in front is ignored without any flicker.
local function startFgDaemon()
    if HK.fgStarted then return true end
    pcall(os.remove, "benloader_fg.txt")
    local ok, f = pcall(io.open, "benloader_fg.ps1", "w")
    if not (ok and f) then return false end
    if not pcall(function() f:write(FG_PS) f:close() end) then return false end
    local okp, h = pcall(io.popen,
        'start "" /B powershell -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "benloader_fg.ps1"')
    if not okp or not h then return false end
    pcall(function() h:close() end)
    HK.fgStarted, HK.fgStartClock = true, os.clock()
    return true
end

local function readFg()                          -- name of the program in front, nil = unknown yet
    local name
    pcall(function()
        local f = io.open("benloader_fg.txt", "r")
        if f then name = f:read("*a") f:close() end
    end)
    if name and name:match("%S") then return name end
    return nil
end

local function hotkeyTick()
    if not HK.bk then
        if os.clock() - HK.retry < 3 then return end   -- keep retrying quietly
        HK.retry = os.clock()
        if not pickBackend() then return end
    end
    -- global key readers see keys pressed in ANY window: start the focus watcher once
    if HK.bk.global and not HK.noFg and not HK.fgStarted and focusApi() == nil then
        if not startFgDaemon() then HK.noFg = true end
    end
    if HK.capturing then
        local k = captureTick()
        if k then
            HK.capturing, HK.base = false, nil
            if k.name ~= "Escape" then
                HK.name, HK.spec = k.name, k
                saveHotkey()
                LogToConsole("`2[Ben Loader] `wHotkey set to `9" .. HK.name:upper())
            end
        end
        return
    end
    if os.clock() - HK.last < 0.25 then return end
    local okA, active = pcall(ImGui.IsAnyItemActive)
    if okA and active == true then return end          -- typing in a text box: ignore
    local b = HK.bk
    local fired
    if b.pressed then
        fired = b.pressed(HK.spec) == true
    else
        local d = b.down(HK.spec) == true
        fired = d and not HK.wasDown
        HK.wasDown = d
    end
    if fired then
        HK.last = os.clock()
        if b.global and not HK.noFg then
            local f = focusApi()
            if f == true then
                toggleHidden()
            elseif f == nil then
                local name = readFg()
                if name then
                    if name:lower():find("growtopia", 1, true) then toggleHidden() end
                elseif HK.fgStarted and os.clock() - HK.fgStartClock > 5 then
                    HK.noFg = true               -- watcher never answered: stop gating
                    toggleHidden()
                end                              -- else: watcher still starting, ignore this press
            end                                  -- f == false: game isn't in front, ignore
        else
            toggleHidden()
        end
    end
end

-- Chat command: always available, no key API needed.
local cmdLastPkt, cmdLastClock, cmdLastRes = nil, -1, false
local function cmdHook(ptype, packet)
    if type(packet) ~= "string" then return false end
    local c = os.clock()
    if packet == cmdLastPkt and c - cmdLastClock < 0.01 then return cmdLastRes end   -- same event, 2nd hook
    local res = false
    if packet:find("action|input\n|text|/loader", 1, true) then
        toggleHidden()
        res = true                                -- don't send the command to the server
    end
    cmdLastPkt, cmdLastClock, cmdLastRes = packet, c, res
    return res
end
pcall(AddHook, "OnSendPacket", "benloader_cmd1", cmdHook)
pcall(AddHook, "onsendpacket", "benloader_cmd2", cmdHook)

local function dumpKeySupport()                   -- prints what this executor offers, to the console
    local function names(t, label)
        local out = {}
        pcall(function()
            for k in pairs(t) do
                if type(k) == "string" and k:lower():find("key", 1, true) then out[#out + 1] = k end
            end
        end)
        table.sort(out)
        LogToConsole("`2[Ben Loader] `w" .. label .. ": `9" .. (#out > 0 and table.concat(out, ", ") or "(none found)"))
    end
    names(realImGui, "ImGui key names")
    names(_G, "Global key names")
    LogToConsole("`2[Ben Loader] `wKey reading in use: `9" .. (HK.bk and HK.bk.name or "none"))
    LogToConsole("`2[Ben Loader] `wGame-focus check: `9" .. tostring(focusApi()) .. " `w(nil = unknown, uses PowerShell fallback)")
end

---------------- AUTO BUFF -------------------------------
-- Keeps two 30-minute buffs running by itself (always on, even while a script is
-- launched or the menus are hidden):
--     Songpyeon       -> "Lucky!"
--     Arroz Con Pollo -> "Food: Breaking Gems"
-- How it knows a buff is on / gone:
--   * every time an item is really eaten (backpack count drops) the buff gets a
--     30:00 timer; the timers are saved to benloader_buff.txt, so reloading the
--     script does not make it eat again while the buff is still running
--   * "worn off" game messages clear a buff at once, so it eats again right away
--   * nothing is eaten while a buff is still active (30 min cooldown)
-- Everything is non-blocking (a small state machine in the draw hook).
local AB = {}
do
    local DURATION = 30 * 60
    local PATHS = { "benloader_buff.txt", "scripts/benloader_buff.txt", "/sdcard/benloader_buff.txt" }
    local state = {
        on = false, pending = nil, nextCheck = 0, method = 1, cfgPath = nil,
        buffs = {
            { key = "lucky", title = "Lucky!",        match = "lucky",         item = "songpyeon",
              pats = { "songpyeon", "lucky clover" }, items = "Songpyeon or Lucky Clover", method = 1, icon = 528, grace = 0,
              exp = 0, live = 0, fails = 0, nextTry = 0, id = nil, missing = false },
            { key = "food",  title = "Breaking Gems", match = "breaking gems", item = "arroz con pollo",
              pats = { "arroz con pollo", "arroz" }, items = "Arroz Con Pollo", method = 1, icon = 4604, grace = 0,
              exp = 0, live = 0, fails = 0, nextTry = 0, id = nil, missing = false },
        },
        nextScan = 0, liveAny = 0, onAt = 0, warnedNoLive = false, lastSave = 0,
        profileAt = 0, profFails = 0, profileFailed = false, awaiting = nil, nextProfile = 0, hideUntil = 0,
    }

    local function blog(m) LogToConsole("`2[Auto Buff] `w" .. tostring(m)) end

    ------------- save / load -------------
    local function save()
        local data = "on=" .. (state.on and "1" or "0") .. "\nmethod=" .. state.method .. "\n"
        for _, b in ipairs(state.buffs) do data = data .. b.key .. "_e=" .. math.floor(b.exp) .. "\n" end
        local order = {}
        if state.cfgPath then order[1] = state.cfgPath end
        for _, p in ipairs(PATHS) do order[#order + 1] = p end
        for _, p in ipairs(order) do
            local ok, f = pcall(io.open, p, "w")
            if ok and f and pcall(function() f:write(data) f:close() end) then
                state.cfgPath = p
                return true
            end
        end
        return false
    end

    function AB.load()
        for _, p in ipairs(PATHS) do
            local ok, f = pcall(io.open, p, "r")
            if ok and f then
                local rok, data = pcall(function() local d = f:read("*a") f:close() return d end)
                if rok and data and data ~= "" then
                    local now = os.time()
                    -- timers are stored as "<key>_e=" (set by a real eat). Old "<key>=" lines
                    -- (from the removed Mark button) no longer match, so they are dropped.
                    for k, v in data:gmatch("([%w_]+)=(%d+)") do
                        v = tonumber(v) or 0
                        if k == "on" then state.on = (v == 1)
                        else
                            for _, b in ipairs(state.buffs) do
                                if k == b.key .. "_e" and v > now then b.exp = v end   -- keep only timers still running
                            end
                        end
                    end
                    state.cfgPath = p
                    if state.on then blog("Auto Buff ON (restored from last session).") end
                    return true
                end
            end
        end
        return false
    end

    ------------- inventory -------------
    local nameCache = {}
    local function itemName(id)
        local v = nameCache[id]
        if v ~= nil then return v end
        v = ""
        for _, fn in ipairs({ "GetItemInfoByID", "GetItemByIDSafe", "GetItemInfo" }) do
            local f = _G[fn]
            if type(f) == "function" then
                local ok, info = pcall(f, id)
                if ok and info then
                    local okn, n = pcall(function() return info.name end)
                    if okn and type(n) == "string" and n ~= "" then v = n:lower() break end
                end
            end
        end
        nameCache[id] = v
        return v
    end

    -- returns id, amount  |  nil, 0 = not in backpack  |  nil, nil = backpack unreadable
    -- b.pats is a PRIORITY list: the first name you own wins (e.g. Songpyeon before Lucky Clover).
    -- returns id, amount, name  |  nil, 0 = none in backpack  |  nil, nil = backpack unreadable
    local function findItem(b)
        local ok, inv = pcall(GetInventory)
        if not ok or type(inv) ~= "table" then return nil, nil end
        for _, pat in ipairs(b.pats) do
            local found, amt
            pcall(function()
                for _, it in pairs(inv) do
                    local id, n = it.id, it.amount or 0
                    if id and n > 0 then
                        local nm = itemName(id)
                        -- seeds / blocks named like the food are not food
                        if nm:find(pat, 1, true) and not nm:find("seed", 1, true) then
                            found, amt = id, n
                            break
                        end
                    end
                end
            end)
            if found then return found, amt, pat end
        end
        return nil, 0
    end

    local function countOf(id)
        local ok, n = pcall(function()
            for _, it in pairs(GetInventory()) do
                if it.id == id then return it.amount end
            end
            return 0
        end)
        if ok and type(n) == "number" then return n end
        return nil
    end

    ------------- eating -------------
    -- Eat attempts. Each attempt = { kind, dx, dy } : kind "tile" sends the use packet at
    -- (your tile + dx, + dy), kind "wear" sends the wear packet. A player standing between two
    -- tiles (x or y) is not "on" a single tile, so we try: the rounded tile, the 2 tiles you
    -- straddle (left/right, up/down), then the 4 neighbours (up/down/left/right), then wear.
    -- A try only counts when the backpack count really drops; the attempt that worked goes first.
    local ATTEMPTS = {
        { "tile", 0, 0 },     -- own tile (rounded to the nearest tile)
        { "tile", -1, 0 },    -- between 2 tiles sideways: left one
        { "tile", 1, 0 },     -- ... right one
        { "tile", 0, -1 },    -- between 2 tiles up/down: upper one
        { "tile", 0, 1 },     -- ... lower one
        { "wear" },           -- wear packet
        { "tile", 0, 0, true },  -- own tile + state packet like a real place
    }
    local NATT = #ATTEMPTS

    local function sendConsume(method, id)
        local a = ATTEMPTS[method] or ATTEMPTS[1]
        if a[1] == "wear" then
            SendPacket(2, "action|wear\n|itemID|" .. id)
            return
        end
        local p = GetLocal().pos
        -- sprite position -> tile: +10 / +15 centres the check on the body (not the top-left corner)
        local tx = math.floor((p.x + 10) / 32) + a[2]
        local ty = math.floor((p.y + 15) / 32) + a[3]
        SendPacketRaw(false, {
            type = 3, value = id, px = tx, py = ty,
            x = p.x, y = p.y, xspeed = 0, yspeed = 0,
            netid = 0, snetid = 0, state = 0,
        })
        if a[4] then
            SendPacketRaw(false, {
                type = 0, value = id, px = tx, py = ty,
                x = p.x, y = p.y, xspeed = 0, yspeed = 0,
                netid = 0, snetid = 0, state = 3104,
            })
        end
    end

    ------------- reading the real effect timers -------------
    -- The game lists effects as  "Lucky! (28 mins, 26 secs left)". Any text the game sends (or any
    -- text/table field the executor exposes on your player) that looks like that is parsed, and the
    -- buff's timer is set to the REAL time left. This is what the eat / don't-eat decision uses.
    local function readStatus(text)
        local low = (tostring(text or ""):gsub("`.", "")):lower()
        if not low:find("left", 1, true) then return false end
        local got, now = false, os.time()
        for name, inner in low:gmatch("([^\n%(]+)%(([^%)]*left)%)") do
            local h = tonumber(inner:match("(%d+)%s*hour")) or 0
            local m = tonumber(inner:match("(%d+)%s*min")) or 0
            local s = tonumber(inner:match("(%d+)%s*sec")) or 0
            local rem = h * 3600 + m * 60 + s
            if rem > 0 then
                for _, b in ipairs(state.buffs) do
                    if name:find(b.match, 1, true) then
                        b.exp, b.live, got = now + rem, now, true
                    end
                end
            end
        end
        if got then
            state.liveAny = now
            if now - state.lastSave >= 20 then state.lastSave = now; save() end
        end
        return got
    end

    local function scanLocal()
        local seen, n = {}, 0
        local function walk(t, depth)
            if type(t) == "string" then readStatus(t) return end
            if n > 600 then return end
            pcall(function()
                for _, v in pairs(t) do
                    n = n + 1
                    if type(v) == "string" then
                        if v:find("left", 1, true) then readStatus(v) end
                    elseif type(v) == "table" and depth < 3 and not seen[v] then
                        seen[v] = true
                        walk(v, depth + 1)
                    end
                end
            end)
        end
        local okL, me = pcall(GetLocal)
        if okL and me ~= nil then walk(me, 0) end
        for _, fn in ipairs({ "GetBuffs", "GetEffects", "GetStatusEffects", "GetMods", "GetPlayerBuffs" }) do
            local f = _G[fn]
            if type(f) == "function" then
                local ok, r = pcall(f)
                if ok and r ~= nil then walk(r, 0) end
            end
        end
    end

    ------------- reading your own profile ("Active effects:") -------------
    -- Wrenching yourself opens a dialog that lists every active effect with its time left, e.g.
    --   add_label_with_icon|small|`wLucky!`` (27 mins, 5 secs left)``|left|528|
    -- Auto Buff sends that wrench itself, hides the dialog, and reads the list. An effect that is
    -- not in the list is OFF. This is the real status, so it decides whether to eat.
    local function parseProfile(dialog)
        local low = dialog:lower()
        local at = low:find("active effects", 1, true)
        if not at then return false end
        local section = dialog:sub(at)
        local stop = section:find("add_spacer", 1, true)
        if stop then section = section:sub(1, stop - 1) end

        local now = os.time()
        local found = {}
        for text, icon in section:gmatch("add_label_with_icon|[^|\n]*|([^|\n]*)|left|(%d+)|") do
            local t = (text:gsub("`.", "")):lower()
            local h = tonumber(t:match("(%d+)%s*hour")) or 0
            local m = tonumber(t:match("(%d+)%s*min")) or 0
            local s = tonumber(t:match("(%d+)%s*sec")) or 0
            local rem = h * 3600 + m * 60 + s
            for _, b in ipairs(state.buffs) do
                if tonumber(icon) == b.icon or t:find(b.match, 1, true) then found[b] = rem end
            end
        end
        for _, b in ipairs(state.buffs) do
            local rem = found[b]
            if rem == nil then
                if now >= b.grace then b.exp, b.nextTry = 0, 0 end   -- not listed = not active (grace: just eaten)
            else
                b.exp = now + (rem > 0 and rem or 60)
            end
            b.live = now
        end
        state.profileAt, state.liveAny = now, now
        state.profFails, state.profileFailed, state.awaiting = 0, false, nil
        save()
        return true
    end

    local function requestProfile(clock)
        local ok, id = pcall(function() return GetLocal().netid end)
        if not ok or type(id) ~= "number" then return false end
        state.awaiting = { at = clock }
        state.hideUntil = clock + 3                                   -- hide the profile dialog we asked for
        state.nextProfile = clock + 60
        SendPacket(2, "action|wrench\n|netid|" .. math.floor(id) .. "\n")
        return true
    end

    function AB.tick()
        if not state.on then return end
        local now, clock = os.time(), os.clock()

        -- waiting to see whether the last item was really eaten
        local p = state.pending
        if p then
            local cnt = countOf(p.id)
            if cnt ~= nil and cnt < p.before then
                p.b.exp, p.b.fails, p.b.missing = now + DURATION + 2, 0, false
                p.b.method = p.method                            -- remember what worked for THIS item
                state.pending = nil
                state.eatGap = clock + 1.2                       -- short gap before the next item
                p.b.grace = now + 20                             -- give the effect list time to show it
                state.nextProfile = clock + 6                    -- then read the real time left
                save()
                blog("Ate " .. (p.name or p.b.item) .. " (attempt " .. p.method .. "/" .. NATT .. ") - active for 30 min.")
            elseif clock - p.at >= 1.1 then
                state.pending = nil
                p.b.fails = p.b.fails + 1
                blog("Eating " .. (p.name or p.b.item) .. " attempt " .. p.method .. "/" .. NATT .. ": nothing changed (id " .. p.id
                    .. ", count " .. tostring(countOf(p.id)) .. ")"
                    .. (state.lastMsg and ("; game said: " .. state.lastMsg) or "") .. ".")
                p.b.method = (p.method % NATT) + 1               -- next attempt (other tile / neighbour / wear)
                if p.b.fails >= NATT * 2 then                    -- every attempt tried twice
                    p.b.fails, p.b.nextTry = 0, clock + 8
                    blog("Could not eat " .. (p.name or p.b.item) .. " with any attempt. Trying again in 8s.")
                else
                    p.b.nextTry = clock + 0.15               -- retry right away with the next attempt
                end
            end
            return
        end

        if clock < (state.eatGap or 0) then return end
        if clock < state.nextCheck then return end
        state.nextCheck = clock + 0.4
        local okL, me = pcall(GetLocal)
        if not okL or not me then return end                      -- not in a world right now

        -- profile read: did the dialog we asked for arrive?
        if state.awaiting and clock - state.awaiting.at > 3 then
            state.awaiting = nil
            state.profFails = state.profFails + 1
            if state.profFails >= 3 and not state.profileFailed then
                state.profileFailed = true
                blog("Can't read your profile effects - using eat timers + 'worn off' messages instead.")
            end
        end
        -- regular check of the real status (faster when a buff is about to run out)
        if not state.awaiting and clock >= state.nextProfile then
            local soon = false
            for _, b in ipairs(state.buffs) do
                if b.exp > now and b.exp - now <= 60 then soon = true end
            end
            if not requestProfile(clock) then
                state.profFails = state.profFails + 1
                if state.profFails >= 3 then state.profileFailed = true end
                state.nextProfile = clock + 15
            elseif soon then
                state.nextProfile = clock + 10
            end
        end
        local fresh = state.profileFailed or (now - state.profileAt <= 12)

        for _, b in ipairs(state.buffs) do
            if b.exp <= now and clock >= b.nextTry then           -- buff looks off: find food, confirm, eat
                local id, amt, which = findItem(b)                -- first item of the priority list you own
                if id == nil and amt == nil then
                    b.nextTry = clock + 10                        -- backpack unreadable
                elseif not id then
                    if not b.missing then
                        b.missing = true
                        blog("No " .. b.items .. " in your backpack - checking again every few seconds.")
                    end
                    b.nextTry = clock + 4                         -- keep searching until one shows up
                else
                    if b.missing then
                        b.missing = false
                        blog("Found " .. which .. " in your backpack.")
                    end
                    if not fresh then
                        if not state.awaiting and not requestProfile(clock) then
                            state.profFails = state.profFails + 1
                            if state.profFails >= 3 then state.profileFailed = true end
                        end
                        return                                    -- wait for the real status first
                    end
                    state.lastMsg = nil
                    if pcall(sendConsume, b.method, id) then
                        state.pending = { b = b, id = id, before = amt, at = clock, method = b.method, name = which }
                        return                                    -- one item at a time
                    end
                    b.nextTry = clock + 5
                end
            end
        end
    end

    ------------- game messages -------------
    local function onText(txt)
        if readStatus(txt) then return end                        -- real "x mins left" text from the game
        local low = (tostring(txt or ""):gsub("`.", "")):lower()
        if low == "" then return end
        if state.pending then state.lastMsg = low:sub(1, 90) end   -- what the game answered to the last try
        local now = os.time()
        local lucky, food = state.buffs[1], state.buffs[2]

        if low:find("luckier than before", 1, true) then          -- Songpyeon eaten (also by hand)
            lucky.exp = now + DURATION + 2
            save()
            return
        end
        if low:find("worn off", 1, true) or low:find("wore off", 1, true) or low:find("has expired", 1, true) then
            if low:find("luck", 1, true) then
                lucky.exp, lucky.nextTry = 0, 0
                save()
            elseif low:find("food", 1, true) or low:find("breaking", 1, true) or low:find("gem", 1, true) then
                food.exp, food.nextTry = 0, 0
                save()
            end
        end
    end

    local function onVariant(var)
        local ok, name = pcall(function() return tostring(var[0] or "") end)
        if not ok then return false end
        if name == "OnConsoleMessage" or name == "OnTextOverlay" then
            pcall(function() onText(var[1]) end)
        elseif name == "OnTalkBubble" then
            pcall(function() onText(var[2]) end)
        elseif name == "OnDialogRequest" and state.on then
            -- your profile (also read when you wrench yourself by hand). Hidden only when Auto Buff asked
            -- for it; both hooks give the same answer so the executor keeps it hidden.
            local okd, parsed = pcall(function()
                local d = tostring(var[1] or "")
                return parseProfile(d)
            end)
            if okd and parsed and os.clock() <= (state.hideUntil or 0) then return true end
        elseif state.on then
            pcall(function()
                for i = 1, 4 do
                    local v = var[i]
                    if type(v) == "string" and v:find("left", 1, true) then readStatus(v) end
                end
            end)
        end
        return false
    end
    pcall(AddHook, "onvariant", "benloader_buff_v1", onVariant)
    pcall(AddHook, "OnVariant", "benloader_buff_v2", onVariant)

    ------------- menu -------------
    local function mmss(s)
        s = math.max(0, math.floor(s))
        return string.format("%d:%02d", s // 60, s % 60)
    end

    -- the toggle, drawn on the same row as the hotkey
    function AB.button()
        local n
        if state.on then
            n = pushBtn({ 0.14, 0.62, 0.34, 1 }, { 0.20, 0.74, 0.42, 1 }, { 0.10, 0.50, 0.27, 1 }, { 1, 1, 1, 1 })
        else
            n = pushBtn({ 0.72, 0.20, 0.20, 1 }, { 0.85, 0.26, 0.26, 1 }, { 0.60, 0.15, 0.15, 1 }, { 1, 1, 1, 1 })
        end
        local clicked = rawButton(" Auto Buff: " .. (state.on and "ON" or "OFF") .. " ")
        popCols(n)
        if clicked then
            state.on, state.pending = not state.on, nil
            state.onAt, state.warnedNoLive, state.nextScan = os.clock(), false, 0
            state.profileAt, state.profFails, state.profileFailed, state.awaiting, state.nextProfile = 0, 0, false, nil, 0
            for _, b in ipairs(state.buffs) do b.exp, b.grace = 0, 0 end    -- start from the real status, not old timers
            for _, b in ipairs(state.buffs) do b.nextTry, b.fails, b.missing = 0, 0, false end
            save()
            blog(state.on and "ON - eats Songpyeon + Arroz Con Pollo whenever the buffs are off."
                or "OFF.")
        end
    end

    -- timers, shown under the hotkey row while it is ON
    function AB.status()
        if not state.on then return end
        local now = os.time()
        for _, b in ipairs(state.buffs) do
            local left, txt, col = b.exp - now, nil, nil
            if state.pending and state.pending.b == b then txt, col = "eating...", C.cyan
            elseif state.profileAt == 0 and not state.profileFailed and left <= 0 then txt, col = "checking status...", C.cyan
            elseif left > 0 then txt, col = mmss(left) .. " left", C.green
            elseif b.missing then txt, col = "no item in backpack", C.red
            else txt, col = "off - eating soon", C.yellow end
            textColored(C.white, b.title)
            ui("SameLine", math.max(VAL_X, 150 * UI_SCALE))
            textColored(col, txt)
            if left > 0 and not (state.pending and state.pending.b == b) then
                ui("SameLine")
                textColored(C.gray, (state.profileAt > 0 and now - state.profileAt <= 130) and "live" or "est.")
            end
        end
        ui("Spacing")
    end
end

local function drawHotkeySection()             -- compact, fits the side panel
    if HK.capturing then
        textColored(C.cyan, "Press a key... (Esc = cancel)")
        if button(" Cancel ") then HK.capturing, HK.base = false, nil end
        return
    end
    textColored(C.gray, "Hide/show key")
    ui("SameLine")
    textColored(C.gold, HK.bk and HK.name:upper() or "/loader")
    if HK.bk then
        if button(" Change ") then HK.capturing, HK.base = true, nil end
        ui("SameLine")
        if button(" Reset ") then setHotkey("Tab") saveHotkey() end
        ui("SameLine")
    end
    if button(" ? ") then dumpKeySupport() end      -- prints key support to the console
    ui("Spacing")
    ImGui.Separator()
    ui("Spacing")
    textColored(C.gray, "Auto Buff")
    AB.button()
    ui("Spacing")
    AB.status()
end

loadHotkey()
if HK.spec == nil then setHotkey("Tab") end
AB.load()                                         -- restore Auto Buff on/off + running timers

-- While a script is being launched, AddHook is swapped for a tracking wrapper:
-- every hook it registers gets a unique name, is remembered, and is gated by
-- gate.alive - so on Return the hooks are removed (RemoveHook) and, even if
-- this executor has no RemoveHook, they are turned into harmless no-ops.
local realAddHook = AddHook
local launchCount = 0

local function killGate()
    local g = loader.gate
    if not g then return end
    g.alive = false
    if type(RemoveHook) == "function" then
        for _, h in ipairs(g.hooks) do
            pcall(RemoveHook, h[2])
            pcall(RemoveHook, h[1], h[2])
        end
    end
    loader.gate = nil
end

local function launchScript(opt)
    launchCount = launchCount + 1
    local gate = { alive = true, hooks = {} }
    loader.gate = gate
    ACTIVE.stop, ACTIVE.returnReq = nil, false
    loader.scriptMin, SCRIPT_MIN_REQ = false, false
    local suffix = "_L" .. launchCount
    local function wrapped(ev, name, fn, ...)
        local uname = tostring(name) .. suffix
        gate.hooks[#gate.hooks + 1] = { ev, uname }
        local isDraw = tostring(ev):lower() == "ondraw"
        return realAddHook(ev, uname, function(...)
            if not gate.alive then return false end
            if (UI.hidden or loader.scriptMin) and isDraw then
                -- hidden: still run the hook (timers / ticks), but draw nothing
                if pcall(function() ImGui = NULL_IMGUI end) then
                    pcall(fn, ...)
                    pcall(function() ImGui = realImGui end)
                    return false
                end
            end
            return fn(...)
        end, ...)
    end
    if not pcall(function() AddHook = wrapped end) then
        LogToConsole("`4[Ben Loader] `wCan't track hooks in this executor - Return will stop the script but not remove its hooks.")
    end
    local ok, err = pcall(opt.run)
    pcall(function() AddHook = realAddHook end)
    if not ok then killGate() end
    return ok, err
end

-- RadioButton's return convention isn't certain (varies by ImGui binding),
-- so accept either a single "clicked" bool or a (something, clicked) pair,
-- the same defensive style used throughout this file.
local function radioPicked(a, b)
    if b ~= nil then return b == true end
    return a == true
end

-- Auto Buff runs in its own thread so it keeps eating when Growtopia is minimized.
local abThreaded = false
if type(RunThread) == "function" and type(Sleep) == "function" then
    abThreaded = pcall(RunThread, function()
        while true do
            pcall(AB.tick)
            Sleep(150)
        end
    end)
end


---------------- NYXORA LOADER LAYOUT ------------------
-- Sidebar (brand card, collapsible groups, profile card) + top pill tabs +
-- card panels. Everything eases: group expand/collapse, nav glow, content fade.
local LOADER_GROUPS = {
    { name = "Broadcast",  col = { 1.00, 0.42, 0.72 }, items = { "Auto Super Broadcast", "Auto Spam" } },                          -- pink
    { name = "Economy",    col = { 1.00, 0.80, 0.28 }, items = { "Vend Helper", "Tax to UWS", "Auto Drop / Trash" } },             -- gold
    { name = "Automation", col = { 0.35, 0.85, 1.00 }, items = { "Auto Geiger", "Auto Geiger Charger", "Auto Crystal Combine" } }, -- cyan
}
local LOADER_DESC = {
    ["Auto Super Broadcast"] = "Sends Super Broadcasts on a timer, with stats, advanced options and Discord webhook logging.",
    ["Auto Spam"]            = "Repeats a chat message at an interval you choose.",
    ["Vend Helper"]          = "Speeds up vending machine dialogs: stocking, buying and selling.",
    ["Tax to UWS"]           = "Handles tax payments to a world with fewer manual steps.",
    ["Auto Drop / Trash"]    = "Drops or trashes chosen items automatically.",
    ["Auto Geiger"]          = "Automates Geiger Counter hunting and the steps around it.",
    ["Auto Geiger Charger"]  = "Keeps your Geiger Counter charged automatically.",
    ["Auto Crystal Combine"] = "Combines crystals automatically.",
}
local LUI = { tab = 1, open = { true, true, true }, lastSel = nil }
local LUI_TABS = { "Scripts", "Hotkey & Tools", "About" }

local function findOpt(name)
    for i, o in ipairs(LOADER_OPTIONS) do if o.name == name then return i end end
end
local function groupOf(name)
    for _, g in ipairs(LOADER_GROUPS) do
        for _, n in ipairs(g.items) do if n == name then return g.name end end
    end
    return "General"
end
local function winPx()
    local ok, w = pcall(ImGui.GetWindowWidth)
    return (ok and type(w) == "number") and w or 600
end
local function winPy()
    local ok, h = pcall(ImGui.GetWindowHeight)
    return (ok and type(h) == "number") and h or 400
end
local function rawAccountName()
    local ok, n = pcall(function() return GetLocal().name end)
    if ok and type(n) == "string" and n ~= "" then return n end
    return "Player"
end
local function accountName()
    local ok, n = pcall(function() return GetLocal().name end)
    if ok and type(n) == "string" and n ~= "" then return (n:gsub("`.", "")) end
    return "Player"
end

local function beginCard(id, w, h)
    local pc = pushCol("ChildBg", { 0.085, 0.090, 0.102, 0.90 }) and 1 or 0
    local o = beginChild(id, w, h, true)
    popCols(pc)
    return o
end
local function endCard(o) if o then ui("EndChild") end end
local function cardTitle(title, sub)
    textColored(C.white, title)
    if sub then textColored(C.gray, sub) end
    ui("Spacing"); ImGui.Separator(); ui("Spacing")
end

local function tw(t)                                -- real text width in pixels (falls back to an estimate)
    local ok, mw = ui("CalcTextSize", t)
    if ok then
        if type(mw) ~= "number" then
            local o, x = pcall(function() return mw.x end)
            mw = o and x or nil
        end
        if type(mw) == "number" then return mw end
    end
    return #t * 7.4 * UI_SCALE
end
local function maxChars(wUnscaled) return wUnscaled end      -- kept name: wrapped() now takes a width
local function cutPx(str, px)                         -- shorten with ".." until it fits px pixels
    str = tostring(str)
    if tw(str) <= px then return str end
    while #str > 1 and tw(str .. "..") > px do str = str:sub(1, #str - 1) end
    return str .. ".."
end

-- Growtopia colour codes (`2 green, `4 red, `w white, `` reset ...) -> RGB
local GT_COL = {
    ["0"] = { 1, 1, 1 },        ["1"] = { 0.45, 0.85, 1 },   ["2"] = { 0.31, 1, 0.31 },  ["3"] = { 0.55, 0.75, 1 },
    ["4"] = { 1, 0.35, 0.35 },  ["5"] = { 0.90, 0.60, 1 },   ["6"] = { 0.90, 0.62, 0.25 }, ["7"] = { 0.72, 0.72, 0.72 },
    ["8"] = { 1, 0.60, 0.20 },  ["9"] = { 1, 0.90, 0.40 },   ["!"] = { 0.70, 1, 1 },     ["@"] = { 1, 0.80, 0.80 },
    ["#"] = { 1, 0.35, 0.70 },  ["$"] = { 1, 0.90, 0.30 },   ["%"] = { 1, 0.40, 0.40 },  ["^"] = { 0.60, 1, 0.60 },
    ["&"] = { 1, 0.70, 1 },     w = { 1, 1, 1 },             o = { 0.60, 0.85, 1 },      p = { 1, 0.70, 0.85 },
    q = { 0.30, 0.40, 0.90 },   r = { 0.60, 1, 0.50 },       s = { 0.85, 0.60, 0.35 },   t = { 0.40, 0.90, 0.85 },
    a = { 0.30, 0.70, 0.30 },   b = { 0.45, 0.45, 0.45 },    c = { 0.20, 0.70, 0.70 },   e = { 0.70, 1, 1 },
}
local function gtSegments(raw)                         -- "`2Dr.`4Name``" -> { {text, {r,g,b}}, ... }
    local segs, col, buf, i = {}, { 0.93, 0.93, 0.94 }, "", 1
    raw = tostring(raw or "")
    while i <= #raw do
        local ch = raw:sub(i, i)
        if ch == "`" and i < #raw then
            if #buf > 0 then segs[#segs + 1] = { buf, col }; buf = "" end
            local c = raw:sub(i + 1, i + 1)
            if c == "`" then col = { 0.93, 0.93, 0.94 } else col = GT_COL[c] or col end
            i = i + 2
        else
            buf = buf .. ch
            i = i + 1
        end
    end
    if #buf > 0 then segs[#segs + 1] = { buf, col } end
    return segs
end
-- draws a colour-coded name. If it is wider than maxPx it WRAPS onto the next
-- line (at spaces when possible) so the whole name stays readable. Only after
-- maxLines lines is the rest cut with "..".
local GT_LINES = {}
local function gtLines(raw, maxPx, maxLines)
    local key = tostring(raw) .. "|" .. math.floor(maxPx) .. "|" .. maxLines
    if GT_LINES[key] then return GT_LINES[key] end
    local segs = gtSegments(raw)
    local plain, cols = "", {}
    for _, sg in ipairs(segs) do
        for _ = 1, #sg[1] do cols[#cols + 1] = sg[2] end
        plain = plain .. sg[1]
    end
    local res = { plain = plain, cols = cols, lines = {}, dots = false }
    local pos, n = 1, #plain
    while pos <= n and #res.lines < maxLines do
        local j = pos                                       -- largest j that still fits
        while j < n and tw(plain:sub(pos, j + 1)) <= maxPx do j = j + 1 end
        local e, nxt
        if j >= n then
            e, nxt = n, n + 1
        else
            local sp
            for q = j + 1, pos + 1, -1 do
                if plain:sub(q, q) == " " then sp = q break end
            end
            if sp then e, nxt = sp - 1, sp + 1 else e, nxt = j, j + 1 end
        end
        res.lines[#res.lines + 1] = { pos, e }
        pos = nxt
    end
    if pos <= n and #res.lines > 0 then                     -- still text left: cut the last line with ".."
        local l = res.lines[#res.lines]
        while l[2] > l[1] and tw(plain:sub(l[1], l[2]) .. "..") > maxPx do l[2] = l[2] - 1 end
        res.dots = true
    end
    GT_LINES[key] = res
    return res
end
local function gtName(raw, maxPx)
    local info = gtLines(raw, maxPx, 3)
    if info.plain == "" then textColored(C.white, "Player") return end
    for li, l in ipairs(info.lines) do
        local i = l[1]
        local first = true
        while i <= l[2] do
            local col, j = info.cols[i], i
            while j < l[2] and info.cols[j + 1] == col do j = j + 1 end
            local t = info.plain:sub(i, j)
            if info.dots and li == #info.lines and j == l[2] then t = t .. ".." end
            if not first then ui("SameLine", 0, 0) end
            first = false
            textColored({ col[1], col[2], col[3], 1 }, t)
            i = j + 1
        end
    end
end

local function vecXY(ok, a, b)                           -- number pair or ImVec2 -> x, y
    if not ok then return nil end
    if type(a) == "number" then return a, b end
    local o, x, y = pcall(function() return a.x, a.y end)
    if o and type(x) == "number" then return x, y end
    return nil
end

-- SameLine to an exact x (window space). Some ImGui builds add an extra offset
-- (child padding), so read the real cursor back and correct it.
local function sameLineAt(x)
    if type(ImGui.SetCursorPosX) == "function" then
        ui("SameLine", 0, 0)                      -- stay on the previous line (keeps its Y)
        if pcall(ImGui.SetCursorPosX, x) then return end
    end
    ui("SameLine", x, 0)
    local ok, cx = ui("GetCursorPosX")
    if ok and type(cx) == "number" and math.abs(cx - x) > 0.5 then
        ui("SameLine", x - (cx - x), 0)
    end
end

-- shimmer text: draws chars with a travelling white highlight. Does NOT touch the
-- font scale (set it before calling) so every character has identical metrics.
--   base  = {r,g,b}  tint of the text (nil = soft grey/white)
--   bold  = true     draws the text a second time 1px to the right (fake bold)
--   yTop  = number   force every char to this cursor Y (keeps the whole word on ONE
--                    baseline when it follows a button on the same line)
--   xStart= number   start the first char at this x (window space) with SameLine
local function shinyRun(text, speed, base, bold, yTop, xStart)
    local t = os.clock()
    local n = #text
    local pos = (t * (speed or 7)) % (n + 10) - 5
    local okx, x0 = ui("GetCursorPosX")
    if not (okx and type(x0) == "number") then x0 = nil end
    local smin, emax
    local function pass(startX, measure)
        for i = 1, n do
            if i == 1 then
                if startX then sameLineAt(startX) end
            else
                ui("SameLine", 0, 0)
            end
            if yTop then ui("SetCursorPosY", yTop) end
            local k = math.max(0, 1 - math.abs(i - pos) / 3.0)
            local r, g, b
            if base then
                local m = 0.88 + 0.12 * k
                local w = k * 0.85                           -- how far to push toward white
                r = math.min(1, base[1] * m + (1 - base[1] * m) * w)
                g = math.min(1, base[2] * m + (1 - base[2] * m) * w)
                b = math.min(1, base[3] * m + (1 - base[3] * m) * w)
            else
                local v = 0.62 + 0.38 * k
                r, g, b = v, v, math.min(1, v + 0.04)
            end
            if measure and (i == 1 or i == n) then            -- real cursor x right before the char is drawn
                local okc, cxx = ui("GetCursorPosX")
                if okc and type(cxx) == "number" then
                    if i == 1 then smin = cxx end
                    if i == n then emax = cxx + tw(text:sub(i, i)) end
                end
            end
            textColored({ r, g, b, 1 }, text:sub(i, i))
        end
    end
    pass(xStart, true)
    if bold then
        local sx = xStart or x0
        if sx then pass(sx + 1) end
    end
    return smin, emax
end

-- category header: filled bar tinted with its own colour, pulsing outline and
-- bold shimmering label in that colour (each category gets a different one)
local CAT_W = {}                                             -- per-header real text width
local function catItem(label, base, idx, sign)
    base = base or { 0.80, 0.82, 0.88 }
    local _, cx = ui("GetCursorPosX")
    local _, cy = ui("GetCursorPosY")
    local pulse = 0.5 + 0.5 * math.sin(os.clock() * 2 + (idx or 0) * 1.7)
    local bg  = { base[1] * 0.20 + 0.05, base[2] * 0.20 + 0.05, base[3] * 0.20 + 0.06, 1 }
    local hov = { base[1] * 0.32 + 0.06, base[2] * 0.32 + 0.06, base[3] * 0.32 + 0.07, 1 }
    local act = { base[1] * 0.14 + 0.05, base[2] * 0.14 + 0.05, base[3] * 0.14 + 0.06, 1 }
    local n = pushBtn(bg, hov, act, { 0, 0, 0, 0 })           -- label is drawn by shinyRun on top
    if pushCol("Border", { base[1], base[2], base[3], 0.30 + 0.40 * pulse }) then n = n + 1 end
    local nv = pushVar("FrameBorderSize", 1) and 1 or 0
    local r = sizedButton("##cat" .. tostring(idx or label), -1, 26)
    local bw, bh = vecXY(ui("GetItemRectSize"))
    local bminx = vecXY(ui("GetItemRectMin"))
    local bmaxx = vecXY(ui("GetItemRectMax"))
    popVars(nv); popCols(n)
    bw = bw or (200 * UI_SCALE)
    bh = bh or (26 * UI_SCALE)
    local okh, lh = ui("GetTextLineHeight")
    if not (okh and type(lh) == "number") then lh = 13 * UI_SCALE end
    local fp = 6 * UI_SCALE                                   -- FramePadding.y of the theme
    local textW = CAT_W[idx] or tw(label)                      -- real drawn width (measured, 1 frame lag)
    local textX = winPx() / 2 - textW / 2                      -- the sidebar bar is symmetric -> window middle
    local textY = (cy or 0) + (bh - lh) / 2 - fp
    if sign then                                               -- +/- sits at the left edge of the bar
        shinyRun(sign, 5, base, true, textY, (cx or 0) + 12 * UI_SCALE)
    end
    local smin, emax = shinyRun(label, 5, base, true, textY, textX)   -- the NAME alone is centred
    if smin and emax and emax > smin then CAT_W[idx] = emax - smin end
    if type(cy) == "number" then ui("SetCursorPosY", cy + bh + 8 * UI_SCALE) end   -- back below the bar
    return r
end

local function wrapped(col, text, wUnscaled)
    local px = wUnscaled * UI_SCALE - 44              -- card padding + scrollbar
    local line = ""
    for word in tostring(text):gmatch("%S+") do
        local try = (#line > 0) and (line .. " " .. word) or word
        if tw(try) > px and #line > 0 then
            textColored(col, line); line = word
        else
            line = try
        end
    end
    if #line > 0 then textColored(col, line) end
end

local function launchSelected()
    local opt = LOADER_OPTIONS[loader.selected]
    local ok, err = launchScript(opt)
    if ok then
        loader.launched, loader.launchedName = true, opt.name
    else
        loader.err = tostring(err)
        LogToConsole("`4[Script Loader] Failed to start " .. opt.name .. ": " .. loader.err)
    end
end

-- Layout rule: every panel below is a DIRECT child of the window (no child
-- inside a child), the same structure the original loader used.
local PANEL_H = 395
local SIDE_W = 228

local function drawLoaderHeader()
    local ww = winPx()
    local _, y = ui("GetCursorPosY")
    local n = pushBtn(ACC, ACC, ACC, { 1, 1, 1, 1 })
    if pushCol("Border", { LIGHT[1], LIGHT[2], LIGHT[3], 0.45 + 0.25 * math.sin(os.clock() * 2) }) then n = n + 1 end
    local nv = pushVar("FrameBorderSize", 1.2) and 1 or 0
    sizedButton(" B ", 34, 34)
    popVars(nv); popCols(n)
    ui("SameLine")
    -- every letter gets the same Y (SetCursorPosY used to move only the first letter,
    -- which made the "B" sit lower than "EN LOADER"); y+4 + button baseline = centred on the tile
    shinyRun("BEN LOADER", 7, nil, false, type(y) == "number" and (y + 4) or nil)

    local x = 190 * UI_SCALE
    for i, t in ipairs(LUI_TABS) do
        local tw = math.max(84, #t * 8 + 30)
        ui("SameLine", x)
        if type(y) == "number" then ui("SetCursorPosY", y + 3) end
        if navItem(t, LUI.tab == i, tw, 28) then LUI.tab = i end
        x = x + (tw + 8) * UI_SCALE
    end
    ui("SameLine", math.max(x, ww - 52 * UI_SCALE))
    if type(y) == "number" then ui("SetCursorPosY", y + 3) end
    if sizedButton(" _ ", 34, 28) then MINIMIZE_REQ = true end
    ui("Spacing")
    ImGui.Separator()
    ui("Spacing")
end

local function drawSidebar()
    local pc = pushCol("ChildBg", { 0.060, 0.065, 0.075, 0.92 }) and 1 or 0
    local open = beginChild("##lsb", SIDE_W, 0, true)
    popCols(pc)

    shinyRun("SCRIPT LIBRARY", 6, nil, true)
    ui("Spacing")
    for gi, g in ipairs(LOADER_GROUPS) do
        local o = LUI.open[gi]
        if catItem(string.upper(g.name), g.col, gi, o and "-" or "+") then LUI.open[gi] = not o end
        if o then
            for _, name in ipairs(g.items) do
                local idx = findOpt(name)
                if idx and navItem(cutPx(name, SIDE_W * UI_SCALE - 58), loader.selected == idx, -1, 28) then
                    loader.selected = idx
                    LUI.tab = 1
                end
            end
        end
    end
    ui("Spacing")
    ImGui.Separator()
    ui("Spacing")
    textColored(C.gray, "Player name:")
    gtName(rawAccountName(), SIDE_W * UI_SCALE - 40)
    textColored(C.gray, "Hide/Show: " .. (HK.bk and HK.name:upper() or "/loader"))
    if open then ui("EndChild") end
end

local function rowTight(label, value, valueColor, colX)   -- label + value, value column close to the labels
    textColored(C.gray, label)
    sameLineAt(colX)
    textColored(valueColor or C.white, value)
end

local function drawScriptsCards()
    local opt = LOADER_OPTIONS[loader.selected]
    if LUI.lastSel ~= loader.selected then
        LUI.lastSel = loader.selected
        ANIM["sel:fade"] = { v = 0, t = os.clock() }
    end
    local fa = animTo("sel:fade", 1, 9)
    local avail = winPx() / UI_SCALE - SIDE_W - 46
    local rw = math.min(SIDE_W, math.floor(avail * 0.5))       -- right card = same width as the left sidebar
    local lw = math.max(120, math.floor(avail - rw - 8))       -- middle card takes the rest

    local o1 = beginCard("##c_over", lw, 0)
    cardTitle("Script Overview", "Details about the selected script")
    ui("SetWindowFontScale", 1.3 * UI_SCALE)
    textColored({ 0.96, 0.96, 0.98, fa }, opt.name)
    ui("SetWindowFontScale", UI_SCALE)
    ui("Spacing")
    wrapped({ C.gray[1], C.gray[2], C.gray[3], fa }, LOADER_DESC[opt.name] or "No description.", maxChars(lw))
    ui("Spacing"); ImGui.Separator(); ui("Spacing")
    local _, px0 = ui("GetCursorPosX")                          -- left edge of the card content
    local colX = (type(px0) == "number" and px0 or 0) + tw("Hide / Show") + 14 * UI_SCALE
    rowTight("Category", groupOf(opt.name), C.white, colX)
    rowTight("Status", loader.launched and "Running" or "Ready", loader.launched and C.yellow or C.green, colX)
    ui("Spacing"); ImGui.Separator(); ui("Spacing")
    textColored(C.gray, "Account")
    gtName(rawAccountName(), lw * UI_SCALE - 44)
    rowTight("Hide / Show", HK.bk and HK.name:upper() or "/loader", C.gold, colX)
    rowTight("Scripts", tostring(#LOADER_OPTIONS) .. " available", C.white, colX)
    endCard(o1)

    ui("SameLine")
    local o2 = beginCard("##c_launch", rw, 0)
    cardTitle("Launch", "Only the chosen script starts")
    wrapped(C.gray, "Nothing runs until you press launch. Use Return in the script window to come back here.", maxChars(rw))
    ui("Spacing")
    local lh = animTo("launch:h", hoverState("launch"), 16)
    local lbg = mix({ 0.76, 0.77, 0.81, 1 }, { 0.92, 0.93, 0.96, 1 }, lh)
    local ln = pushBtn(lbg, lbg, { 0.66, 0.67, 0.71, 1 }, { 0.06, 0.06, 0.08, 1 })
    local go = sizedButton(">  LAUNCH", -1, 42)
    readHover("launch")
    popCols(ln)
    if go then launchSelected() end
    if loader.err then
        ui("Spacing")
        wrapped(C.red, "Last error: " .. loader.err, maxChars(rw))
    end
    ui("Spacing"); ImGui.Separator(); ui("Spacing")
    textColored(C.white, "Quick Tips")
    wrapped(C.gray, "Pick a script on the left, then launch it. Scripts keep running while menus are hidden.", maxChars(rw))
    endCard(o2)
end

local function drawLoaderUI()
    drawLoaderHeader()
    drawSidebar()
    ui("SameLine")
    if LUI.tab == 1 then
        drawScriptsCards()
    elseif LUI.tab == 2 then
        local o = beginCard("##c_hk", 0, 0)
        cardTitle("Hotkey & Tools", "Hide or show every menu")
        drawHotkeySection()
        endCard(o)
    else
        local o = beginCard("##c_about", 0, 0)
        cardTitle("About", "Ben Loader")
        ui("SetWindowFontScale", 1.5 * UI_SCALE)
        shinyRun("BEN LOADER", 6, { 0.80, 0.85, 1.00 }, true)
        ui("SetWindowFontScale", UI_SCALE)
        ui("Spacing")
        wrapped(C.gray, "One loader for all your scripts. Only the script you launch registers its hooks; Return stops it and removes them.", maxChars(winPx() / UI_SCALE))   -- inside the card, winPx() IS the card width
        ui("Spacing"); ImGui.Separator(); ui("Spacing")
        textColored(C.gray, "Loader by")
        shinyRun("Ben (PoliceMan)", 6, { 1.00, 0.82, 0.35 }, true)
        ui("Spacing")
        textColored(C.gray, "Discord")
        shinyRun("itsme_wzz", 5, { 0.55, 0.62, 1.00 }, true)
        ui("Spacing")
        if sizedButton("Copy Discord", 120, 26) then
            ui("SetClipboardText", "itsme_wzz")
            LUI.copied = os.clock()
        end
        if LUI.copied and os.clock() - LUI.copied < 2 then
            ui("SameLine")
            textColored(C.green, "Copied!")
        end
        ui("Spacing"); ImGui.Separator(); ui("Spacing")
        rowv("Scripts", tostring(#LOADER_OPTIONS), C.white)
        rowv("Theme", "Nyxora glass", C.white)
        endCard(o)
    end
end

AddHook("ondraw", "script_loader_menu", function(dt)
    pcall(hotkeyTick)
    if not abThreaded then pcall(AB.tick) end     -- Auto Buff keeps running with a script launched / menus hidden
    if loader.launched then
        -- A script is running: only its own window shows, until it asks to Return.
        if SCRIPT_MIN_REQ then SCRIPT_MIN_REQ = false; loader.scriptMin = true end
        if loader.scriptMin and not UI.hidden and not ACTIVE.returnReq then
            -- script window minimized: small bar with restore (B) only
            local mc, mv = pushTheme()
            -- first open: centered horizontally at the top of the screen (you can still drag it)
            pcall(function()
                local io = ImGui.GetIO()
                local ds = io.DisplaySize
                local sw = (type(ds) == "table" or type(ds) == "userdata") and ds.x or io.DisplaySizeX
                if type(sw) == "number" and sw > 0 then
                    ui("SetNextWindowPos", sw / 2 - 80, 12, 4)
                end
            end)
            beginWindow("Ben Loader Script Mini", 200, 0, 140, 34, true)
            local _, my = ui("GetCursorPosY")
            local n = pushBtn(ACC, ACC_HOVER, ACC_ACTIVE, { 1, 1, 1, 1 })
            if pushCol("Border", LIGHT) then n = n + 1 end
            local nvar = pushVar("FrameBorderSize", 1) and 1 or 0
            if sizedButton(" B ", 26, 26) then loader.scriptMin = false end
            popVars(nvar)
            popCols(n)
            ui("SameLine")
            if type(my) == "number" then ui("SetCursorPosY", my + 5) end   -- text centered with the buttons
            textColored(C.white, tostring(loader.launchedName or "Script"))
            ImGui.End()
            popTheme(mc, mv)
        end
        if not ACTIVE.returnReq then return end
        ACTIVE.returnReq = false
        pcall(function() if ACTIVE.stop then ACTIVE.stop() end end)
        killGate()
        ACTIVE.stop = nil
        loader.launched, loader.launchedName, loader.err = false, nil, nil
        loader.scriptMin, SCRIPT_MIN_REQ = false, false
        LogToConsole("`2[Ben Loader] `wReturned to the loader - script stopped, hooks removed.")
    end

    if UI.hidden then return end

    local nc, nv = pushTheme()
    if loader.minimized then
        beginWindow("Ben Loader Mini", 130, 0, 100, 34, true)
        local n = pushBtn(ACC, ACC_HOVER, ACC_ACTIVE, { 1, 1, 1, 1 })
        if pushCol("Border", LIGHT) then n = n + 1 end
        local nvar = pushVar("FrameBorderSize", 1) and 1 or 0
        if sizedButton(" B ", 26, 26) then loader.minimized = false end
        popVars(nvar)
        popCols(n)
        ui("SameLine")
        shinyText("Ben Loader", 1.0)
        ImGui.End()
        popTheme(nc, nv)
        return
    end
    if NEW_LAYOUT then
        beginWindow("Ben Loader", WIN_W, WIN_H, 640, 380)
        if MINIMIZE_REQ then MINIMIZE_REQ = false; loader.minimized = true end
        drawLoaderUI()
    else
        beginWindow("Ben Loader", WIN_W, WIN_H, 640, 380)
        drawHeader("Ben Loader", false, true)
        if MINIMIZE_REQ then MINIMIZE_REQ = false; loader.minimized = true end
        local LIST_H = #LOADER_OPTIONS * 34 + 16
        local sOpen = beginChild("##scripts", 205, LIST_H, true)
        section("SELECT A SCRIPT")
        for i, opt in ipairs(LOADER_OPTIONS) do
            if navItem(opt.name, loader.selected == i, -1, 28) then loader.selected = i end
        end
        if sOpen then ui("EndChild") end
        ui("SameLine")
        local tOpen = beginChild("##tools", 0, LIST_H, true)
        section("HOTKEY & TOOLS")
        drawHotkeySection()
        if tOpen then ui("EndChild") end
        ui("Spacing")
        if sizedButton(">  LAUNCH  " .. string.upper(LOADER_OPTIONS[loader.selected].name), -1, 40) then
            launchSelected()
        end
        if loader.err then textColored(C.red, "Last error: " .. loader.err) end
        navEnd()
    end
    ImGui.End()
    popTheme(nc, nv)
end)

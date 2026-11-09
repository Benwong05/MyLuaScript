--====================================================
--  BEN LOADER - pick ONE script to launch
--  Nothing runs until you select it in the menu below and press
--  "Launch Selected Script". Only the chosen script's hooks/menu get
--  registered; the other one never starts. To switch to the other
--  script later, reload this file and pick again.
--
--  All the menus (this loader, Auto Super Broadcast, Vend Helper, Auto Geiger, Auto Crystal)
--  share the SAME theme/widget helpers below, so they all look and
--  behave the same way.
--====================================================

-- Set to false if your menu glitches: falls back to plain ImGui widgets.
local FANCY_UI = true

local C = {                                   -- colours (r, g, b, a)
    gold   = { 1.00, 0.82, 0.25, 1 },
    green  = { 0.35, 0.90, 0.45, 1 },
    red    = { 1.00, 0.40, 0.40, 1 },
    cyan   = { 0.45, 0.80, 1.00, 1 },
    yellow = { 1.00, 0.88, 0.35, 1 },
    gray   = { 0.45, 0.47, 0.52, 1 },
    white  = { 0.95, 0.95, 0.95, 1 },
    purple = { 0.45, 0.45, 0.95, 1 },
}

-- Calls an optional ImGui function; silently does nothing if it doesn't exist.
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

---------------- THEME (dark look) -------------------
-- PushStyleColor / PushStyleVar wrappers. They work out which signature
-- your ImGui uses, and just do nothing if it isn't supported.
local styleMode = nil                         -- "rgba" | "vec4" | "none"

local THEME_COLORS = {
    { "WindowBg",         { 0.05, 0.05, 0.06, 0.97 } },
    { "TitleBg",          { 0.04, 0.04, 0.05, 1.00 } },
    { "TitleBgActive",    { 0.04, 0.04, 0.05, 1.00 } },
    { "TitleBgCollapsed", { 0.04, 0.04, 0.05, 1.00 } },
    { "Separator",        { 0.20, 0.20, 0.23, 1.00 } },
    { "Border",           { 0.50, 0.50, 0.68, 1.00 } },   -- button / input outline
    { "Button",           { 0.09, 0.09, 0.11, 1.00 } },
    { "ButtonHovered",    { 0.17, 0.17, 0.23, 1.00 } },
    { "ButtonActive",     { 0.27, 0.27, 0.45, 1.00 } },
    { "FrameBg",          { 0.13, 0.13, 0.15, 1.00 } },
    { "FrameBgHovered",   { 0.17, 0.17, 0.20, 1.00 } },
    { "FrameBgActive",    { 0.20, 0.20, 0.25, 1.00 } },
    { "PlotHistogram",    { 0.45, 0.45, 0.95, 1.00 } },
}
local THEME_VARS = {                           -- 0 = sharp corners
    { "WindowRounding",    0 },               -- menu window: sharp
    { "ChildRounding",     0 },
    { "PopupRounding",     0 },
    { "ScrollbarRounding", 0 },
    { "TabRounding",       0 },
    { "FrameRounding",     5 },               -- buttons / inputs: rounded
    { "GrabRounding",      5 },
}

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
    return (pcall(ImGui.PushStyleVar, idx, v))
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

---------------- UI WIDGETS --------------------------
-- Section header: gold-white title with a line under it.
local function section(title)
    ui("Spacing")
    textColored(C.white, title)
    ImGui.Separator()
end

-- Button with optional size (w, h); falls back to a plain button.
local function button(label, w, h)
    if FANCY_UI and w then
        local ok, r = pcall(ImGui.Button, label, w, h or 0)
        if ok then return r end
    end
    return ImGui.Button(label)
end

-- Button with a real size (ImVec2). Falls back to the normal button.
local function sizedButton(label, w, h)
    if FANCY_UI and type(ImVec2) == "function" then
        local ok, r = pcall(ImGui.Button, label, ImVec2(w, h))
        if ok then return r end
    end
    return button(label, w, h)
end

-- Big START / STOP button, centred in the window.
local function bigButton(label, base, hover, active)
    local w, h = 300, 44
    local ok, ww = pcall(ImGui.GetWindowWidth)
    if ok and type(ww) == "number" then
        w = math.max(200, math.floor(ww * 0.70))
        ui("SetCursorPosX", math.max(0, math.floor((ww - w) / 2)))
    end
    local n = 0
    if base then
        if pushCol("Button", base)         then n = n + 1 end
        if pushCol("ButtonHovered", hover) then n = n + 1 end
        if pushCol("ButtonActive", active) then n = n + 1 end
    end
    local r = sizedButton(label, w, h)
    if n > 0 then ui("PopStyleColor", n) end
    return r
end

-- Button drawn with its own colour (normal / hovered / pressed).
local function colorButton(label, w, h, base, hover, active)
    local n = 0
    if pushCol("Button", base)        then n = n + 1 end
    if pushCol("ButtonHovered", hover) then n = n + 1 end
    if pushCol("ButtonActive", active) then n = n + 1 end
    local r = button(label, w, h)
    if n > 0 then ui("PopStyleColor", n) end
    return r
end

-- "Label            value" with the value in an aligned column.
local VAL_X = 170                             -- x position of the value column
local function rowv(label, value, valueColor)
    textColored(C.white, label)
    ui("SameLine", VAL_X)
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
            and pcall(ImGui.ProgressBar, frac, ImVec2(-1, 18), " ") then return end
        if pcall(ImGui.ProgressBar, frac, -1, " ") then return end
        if pcall(ImGui.ProgressBar, frac) then return end
    end
    textColored(C.purple, bar(frac, 28))
end



---------------- RETURN TO LOADER ----------------------
-- ACTIVE.stop is set by the launched script (stops its loops/threads).
-- The Return button only raises a flag; the loader's own draw hook does the
-- clean-up (stop script, disable + remove its hooks, show the loader again).
local ACTIVE = { stop = nil, returnReq = false }

local function returnButton()                  -- small button, top-left of the window
    if colorButton(" < Return ", 0, 0,
        { 0.20, 0.20, 0.32, 1 }, { 0.24, 0.24, 0.38, 1 }, { 0.28, 0.28, 0.45, 1 }) then
        ACTIVE.returnReq = true
    end
    ui("Spacing")
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

---------------- DRAW ---------------------------------
AddHook("ondraw", "autosb_menu", function(dt)
    tick()

    local nc, nv = pushTheme()

    ui("SetNextWindowSize", 440, 0, 4)        -- first-use size, you can still resize
    ImGui.Begin("Auto SB - PoliceMan v4")
    local widthPushed = ui("PushItemWidth", 240)
    returnButton()

    ------------- START / STOP (full width) -------------
    if not S.running then
        local label = (S.done > 0 and S.done < cfg.total) and ">  RESUME SB" or ">  START SB"
        if bigButton(label) then start() end
    else
        if bigButton("[]  STOP SB",
            { 0.45, 0.12, 0.12, 1 }, { 0.60, 0.16, 0.16, 1 }, { 0.75, 0.20, 0.20, 1 }) then
            stop("stopped by user.")
        end
    end

    ------------- CONFIG -------------------
    section("CONFIG")
    textColored(C.white, S.cfgPath or "autosb_config.txt")
    ui("SameLine", 170)
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    ------------- TABS ---------------------
    ui("Spacing")
    for i, name in ipairs(TABS) do
        if i > 1 then ui("SameLine") end
        if tab == i then
            colorButton(" " .. name .. " ", 0, 0,
                { 0.20, 0.20, 0.32, 1 }, { 0.24, 0.24, 0.38, 1 }, { 0.28, 0.28, 0.45, 1 })
        else
            if button(" " .. name .. " ", 0, 0) then tab = i end
        end
    end
    ImGui.Separator()
    ui("Spacing")

    if     tab == 1 then tabStats()
    elseif tab == 2 then tabBroadcast()
    elseif tab == 3 then tabWebhook()
    else                 tabAdvanced() end

    if widthPushed then ui("PopItemWidth") end
    ImGui.End()
    popTheme(nc, nv)
end)


math.randomseed(os.time())
pickEmoji()
loadConfig(true)                              -- load saved settings on startup
say("`2[Auto SB] v4 loaded." .. (S.cfgPath and " Config loaded." or ""))

ACTIVE.stop = function() stop("returned to loader.") end

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
local function drawMenu()
    if not S.menu then return end
    local nc, nv = pushTheme()
    ui("SetNextWindowSize", 360, 0, 4)
    ImGui.Begin("Vend Helper")
    local widthPushed = ui("PushItemWidth", 200)
    returnButton()

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

    section("OPTIONS")
    if button(" Hide dialog when handled: " .. (S.hide and "ON" or "OFF") .. " ") then
        S.hide = not S.hide
    end
    if button(" Debug output: " .. (S.debug and "ON" or "OFF") .. " ") then
        S.debug = not S.debug
    end

    ui("Spacing")
    ImGui.Separator()
    if button(" Save config ") then saveConfig() end
    ui("SameLine")
    if button(" Load config ") then loadConfig() end
    if status ~= "" then textColored(C.gray, status) end

    if widthPushed then ui("PopItemWidth") end
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
            { 0.45, 0.12, 0.12, 1 }, { 0.60, 0.16, 0.16, 1 }, { 0.75, 0.20, 0.20, 1 }) then
            stopRun("stopped by user.")
        end
    end

    ------------- CONFIG -------------------
    section("CONFIG")
    textColored(C.white, S.cfgPath or "autogeiger_config.txt")
    ui("SameLine", 170)
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    ------------- TABS ---------------------
    ui("Spacing")
    for i, name in ipairs(TABS) do
        if i > 1 then ui("SameLine") end
        if tab == i then
            colorButton(" " .. name .. " ", 0, 0,
                { 0.20, 0.20, 0.32, 1 }, { 0.24, 0.24, 0.38, 1 }, { 0.28, 0.28, 0.45, 1 })
        else
            if button(" " .. name .. " ", 0, 0) then tab = i end
        end
    end
    ImGui.Separator()
    ui("Spacing")

    if     tab == 1 then tabStats()
    elseif tab == 2 then tabItems()
    elseif tab == 3 then tabSettings()
    elseif tab == 4 then tabWebhook()
    else                 tabAdvanced() end
end

local drawErrors = 0
AddHook("ondraw", "gwk_menu", function(dt)
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

    local nc, nv = pushTheme()
    ui("SetNextWindowSize", 440, 0, 4)        -- first-use size, you can still resize
    ImGui.Begin("Auto Geiger")
    local widthPushed = ui("PushItemWidth", 240)
    returnButton()

    if drawErrors < 3 then
        local ok, err = pcall(drawBody)
        if not ok then
            drawErrors = drawErrors + 1
            say("`4[Auto Geiger] Menu error: `w" .. tostring(err))
        end
    end

    if widthPushed then ui("PopItemWidth") end
    ImGui.End()
    popTheme(nc, nv)
end)

math.randomseed(os.time())
loadConfig(true)                              -- load saved settings on startup
say("`2[Auto Geiger] loaded." .. (S.cfgPath and " Config loaded." or ""))

ACTIVE.stop = function() stopRun("returned to loader.") end

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
            { 0.45, 0.12, 0.12, 1 }, { 0.60, 0.16, 0.16, 1 }, { 0.75, 0.20, 0.20, 1 }) then
            stopRun("stopped by user.")
        end
    end

    section("CONFIG")
    textColored(C.white, S.cfgPath or "autocrystal_config.txt")
    ui("SameLine", 170)
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    ui("Spacing")
    for i, name in ipairs(TABS) do
        if i > 1 then ui("SameLine") end
        if tab == i then
            colorButton(" " .. name .. " ", 0, 0,
                { 0.20, 0.20, 0.32, 1 }, { 0.24, 0.24, 0.38, 1 }, { 0.28, 0.28, 0.45, 1 })
        else
            if button(" " .. name .. " ", 0, 0) then tab = i end
        end
    end
    ImGui.Separator()
    ui("Spacing")

    if     tab == 1 then tabStats()
    elseif tab == 2 then tabRecipe()
    else                 tabAdvanced() end
end

local drawErrors = 0
AddHook("ondraw", "ac_menu", function(dt)
    local nc, nv = pushTheme()
    ui("SetNextWindowSize", 440, 0, 4)
    ImGui.Begin("Auto Crystal Combine")
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
            { 0.45, 0.12, 0.12, 1 }, { 0.60, 0.16, 0.16, 1 }, { 0.75, 0.20, 0.20, 1 }) then
            stopRun("stopped by user.")
        end
    end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    ui("Spacing")
    for i, name in ipairs(TABS) do
        if i > 1 then ui("SameLine") end
        if tab == i then
            colorButton(" " .. name .. " ", 0, 0,
                { 0.20, 0.20, 0.32, 1 }, { 0.24, 0.24, 0.38, 1 }, { 0.28, 0.28, 0.45, 1 })
        else
            if button(" " .. name .. " ", 0, 0) then tab = i end
        end
    end
    ImGui.Separator()
    ui("Spacing")

    if     tab == 1 then tabMain()
    elseif tab == 2 then tabOptions()
    else                 tabTools() end
end

local drawErrors = 0
AddHook("ondraw", "ach_menu", function(dt)
    local nc, nv = pushTheme()
    ui("SetNextWindowSize", 400, 0, 4)
    ImGui.Begin("Auto Geiger Charger")
    local widthPushed = ui("PushItemWidth", 240)
    returnButton()

    if drawErrors < 3 then
        local ok, err = pcall(drawBody)
        if not ok then
            drawErrors = drawErrors + 1
            say("`4[Auto Charger] `wMenu error: " .. tostring(err))
        end
    end

    if widthPushed then ui("PopItemWidth") end
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
            { 0.45, 0.12, 0.12, 1 }, { 0.60, 0.16, 0.16, 1 }, { 0.75, 0.20, 0.20, 1 }) then
            stopRun("stopped by user.")
        end
    end

    section("CONFIG")
    textColored(C.white, S.cfgPath or "taxuws_config.txt")
    ui("SameLine", 170)
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    ui("Spacing")
    for i, name in ipairs(TABS) do
        if i > 1 then ui("SameLine") end
        if tab == i then
            colorButton(" " .. name .. " ", 0, 0,
                { 0.20, 0.20, 0.32, 1 }, { 0.24, 0.24, 0.38, 1 }, { 0.28, 0.28, 0.45, 1 })
        else
            if button(" " .. name .. " ", 0, 0) then tab = i end
        end
    end
    ImGui.Separator()
    ui("Spacing")

    if tab == 1 then tabStats() else tabSettings() end
end

local drawErrors = 0
AddHook("ondraw", "taxuws_menu", function(dt)
    local nc, nv = pushTheme()
    ui("SetNextWindowSize", 400, 0, 4)
    ImGui.Begin("Tax to UWS")
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
        ui("SameLine", 250)
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
            ui("SameLine", 290)
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
            { 0.45, 0.12, 0.12, 1 }, { 0.60, 0.16, 0.16, 1 }, { 0.75, 0.20, 0.20, 1 }) then
            stopRun("stopped by user.")
        end
    end

    section("CONFIG")
    textColored(C.white, S.cfgPath or "autodrop_config.txt")
    ui("SameLine", 170)
    if button(" Save ", 70, 0) then saveConfig() end
    ui("SameLine")
    if button(" Load ", 70, 0) then loadConfig() end
    ui("SameLine")
    if button(" Default ", 80, 0) then resetDefaults() end

    if S.uiMsg and os.time() < S.uiUntil then
        textColored(S.uiOk and C.green or C.red, S.uiMsg)
    end

    ui("Spacing")
    for i, name in ipairs(TABS) do
        if i > 1 then ui("SameLine") end
        if tab == i then
            colorButton(" " .. name .. " ", 0, 0,
                { 0.20, 0.20, 0.32, 1 }, { 0.24, 0.24, 0.38, 1 }, { 0.28, 0.28, 0.45, 1 })
        else
            if button(" " .. name .. " ", 0, 0) then tab = i end
        end
    end
    ImGui.Separator()
    ui("Spacing")

    if     tab == 1 then tabStats()
    elseif tab == 2 then tabItems()
    else                 tabAdvanced() end
end

local drawErrors = 0
AddHook("ondraw", "autodrop_menu", function(dt)
    local nc, nv = pushTheme()
    ui("SetNextWindowSize", 440, 0, 4)
    ImGui.Begin("Auto Drop / Trash")
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

        if packet:find("action|wrench", 1, true) then grantWrench() end
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

local LOADER_OPTIONS = {
    { name = "Auto Super Broadcast", run = startAutoSB },
    { name = "Vend Helper",          run = startVendHelper },
    { name = "Auto Geiger",           run = startGeiger },
    { name = "Auto Crystal Combine",  run = startAutoCrystal },
    { name = "Auto Geiger Charger",   run = startAutoCharger },
    { name = "Tax to UWS",            run = startTaxToUWS },
    { name = "Auto Drop / Trash",     run = startAutoDrop },
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
    { name = "GetAsyncKeyState", down = function(k) return winState("GetAsyncKeyState", k) end },
    { name = "GetKeyState",      down = function(k) return winState("GetKeyState", k) end },
    { name = "IsKeyDown",        down = function(k) return globalKey("IsKeyDown", k) end },
    { name = "IsKeyPressed",     pressed = function(k) return globalKey("IsKeyPressed", k) end },
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

local function hotkeyTick()
    if not HK.bk then
        if os.clock() - HK.retry < 3 then return end   -- keep retrying quietly
        HK.retry = os.clock()
        if not pickBackend() then return end
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
        toggleHidden()
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
end

local function drawHotkeySection()             -- one compact row
    if HK.capturing then
        textColored(C.cyan, "Press a key... (Esc = cancel)")
        ui("SameLine")
        if button(" Cancel ") then HK.capturing, HK.base = false, nil end
        ui("Spacing")
        return
    end
    textColored(C.white, "Hotkey")
    ui("SameLine")
    textColored(C.gold, HK.bk and HK.name:upper() or "/loader")
    if HK.bk then
        ui("SameLine")
        if button(" Change ") then HK.capturing, HK.base = true, nil end
        ui("SameLine")
        if button(" Reset ") then setHotkey("Tab") saveHotkey() end
    end
    ui("SameLine")
    if button(" ? ") then dumpKeySupport() end      -- prints key support to the console
    ui("Spacing")
end

loadHotkey()
if HK.spec == nil then setHotkey("Tab") end

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
    local suffix = "_L" .. launchCount
    local function wrapped(ev, name, fn, ...)
        local uname = tostring(name) .. suffix
        gate.hooks[#gate.hooks + 1] = { ev, uname }
        local isDraw = tostring(ev):lower() == "ondraw"
        return realAddHook(ev, uname, function(...)
            if not gate.alive then return false end
            if UI.hidden and isDraw then
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

AddHook("ondraw", "script_loader_menu", function(dt)
    pcall(hotkeyTick)
    if loader.launched then
        -- A script is running: only its own window shows, until it asks to Return.
        if not ACTIVE.returnReq then return end
        ACTIVE.returnReq = false
        pcall(function() if ACTIVE.stop then ACTIVE.stop() end end)
        killGate()
        ACTIVE.stop = nil
        loader.launched, loader.launchedName, loader.err = false, nil, nil
        LogToConsole("`2[Ben Loader] `wReturned to the loader - script stopped, hooks removed.")
    end

    if UI.hidden then return end

    local nc, nv = pushTheme()
    ui("SetNextWindowSize", 360, 0, 4)
    ImGui.Begin("Ben Loader")

    section("SELECT A SCRIPT")
    drawHotkeySection()
    textColored(C.gold, "SELECTED: " .. LOADER_OPTIONS[loader.selected].name)
    ui("Spacing")
    for i, opt in ipairs(LOADER_OPTIONS) do
        local a, b = ImGui.RadioButton(opt.name, loader.selected == i)
        if radioPicked(a, b) then loader.selected = i end
    end

    ui("Spacing")
    ImGui.Separator()
    if bigButton(">  LAUNCH SELECTED SCRIPT") then
        local opt = LOADER_OPTIONS[loader.selected]
        local ok, err = launchScript(opt)
        if ok then
            loader.launched, loader.launchedName = true, opt.name
        else
            loader.err = tostring(err)
            LogToConsole("`4[Script Loader] Failed to start " .. opt.name .. ": " .. loader.err)
        end
    end
    if loader.err then textColored(C.red, "Last error: " .. loader.err) end

    ImGui.End()
    popTheme(nc, nv)
end)

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


local S = {
    add    = true,   -- auto add stock when wrenching your own vend
    buy    = false,  -- auto buy when wrenching someone's vend
    amount = 1,      -- how many to buy
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
-- HOOK: incoming dialog (opens after you wrench a machine)
---------------------------------------------------------------
local function on_variant(var)
    local fname = field(var, "v1", 0)

    -- after we confirm a purchase, show what the server answers
    if watch > 0 and (fname == "OnConsoleMessage" or fname == "OnTalkBubble") then
        local txt = clean(fname == "OnTalkBubble" and field(var, "v3", 2) or field(var, "v2", 1))
        watch = watch - 1
        if txt:find("bought", 1, true) then
            watch = 0
            log("PURCHASE OK: " .. txt)
        else
            log("Server said: " .. txt:sub(1, 160))
        end
    end

    if fname ~= "OnDialogRequest" then return false end
    local dialog = field(var, "v2", 1) or ""
    local dname = dialog:match("end_dialog|([^|]*)|")
    local isConfirm = dname == "vend_buyconfirm" or dialog:find("Purchase Confirmation", 1, true)

    -- debug recorder: show every vend related dialog, whatever the toggles are
    if S.debug and (isConfirm or (dname and dname:lower():find("vend", 1, true))) then
        log("DIALOG [" .. tostring(dname) .. "]:\n" .. dialog)
    end

    if S.instant and isConfirm then
        return handleConfirm(dialog)
    end
    if S.add and dialog:find("Add items to the machine", 1, true) then
        return handleAdd(dialog)
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
local CONFIG_KEYS  = { "add", "buy", "amount", "hide" }  -- instant/delay are fixed (always on / 30ms)
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
                S.amount = clampAmount(S.amount)
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
                    "deadDropX", "deadDropY", "lowGeiger", "stepTiles", "stepDelay", "breakMin",
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

-- Shrinks a move so its real length (not just per axis) is <= stepTiles.
local function limitStep(dx, dy)
    local len  = math.sqrt(dx * dx + dy * dy)
    local step = math.max(1, cfg.stepTiles)
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

-- Walks to the target in small hops. If a hop is blocked it retries with
-- 1-tile steps, and gives up after 3 tries. It NEVER jumps straight to the
-- target any more (that long jump is what got you kicked).
local function FindPath(tx, ty)
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

local function fullAFK()
    setStage("Warping to " .. cfg.worldSave, C.yellow)
    warp(cfg.worldSave)
    nap(5000)
    while S.running and not inWorld(cfg.worldSave) do
        nap(5000)
        warp(cfg.worldSave)
    end
    if not S.running then return end
    FindPath(cfg.alivePosX, cfg.alivePosY)

    nap(3000)
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
    if packet.type == 17 then
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
    end
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

end  -- startAutoCrystal

local function startAutoModage()
local function say(msg) LogToConsole(msg) end

AddHook("onvariant", "mommy", function(var)
    if var[0] == "OnConsoleMessage" and var[1]:find("You are recovering") then
        SendPacket(2, "action|input\n|text|/modage 60")
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("not allowed to perform surgery") then
        SendPacket(2, "action|input\n|text|/modage 60")
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("Spam detected!") then
        return true
    end
    if var[0] == "OnTalkBubble" and var[2]:find("You are healed") then
        return true
    end
    if var[0] == "OnTalkBubble" and var[2]:find("!reset") then
        SendPacket(2, "action|input\n|text|/modage 60")
    end
end)

say("`2[Auto Modage] `wloaded.")

end  -- startAutoModage

---------------- LOADER MENU ---------------------------
local LOADER_OPTIONS = {
    { name = "Auto Super Broadcast", run = startAutoSB },
    { name = "Vend Helper",          run = startVendHelper },
    { name = "Auto Geiger",           run = startGeiger },
    { name = "Auto Crystal Combine",  run = startAutoCrystal },
    { name = "Auto Modage",           run = startAutoModage },
}
local loader = { selected = 1, launched = false, launchedName = nil, err = nil }

-- RadioButton's return convention isn't certain (varies by ImGui binding),
-- so accept either a single "clicked" bool or a (something, clicked) pair,
-- the same defensive style used throughout this file.
local function radioPicked(a, b)
    if b ~= nil then return b == true end
    return a == true
end

AddHook("ondraw", "script_loader_menu", function(dt)
    if loader.launched then
        -- Once a script is launched, the loader window is gone for good -
        -- only the launched script's own window(s) show from here on.
        return
    end

    local nc, nv = pushTheme()
    ui("SetNextWindowSize", 360, 0, 4)
    ImGui.Begin("Ben Loader")

    section("SELECT A SCRIPT")
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
        local ok, err = pcall(opt.run)
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

-- LilMVP: joke "dungeon summary" poster.
-- /lilmvp                 post to party (or instance chat in an instance group)
-- /lilmvp preview         print only to your own chat frame
-- /lilmvp say|party|instance  post to that channel
-- /lilmvp auto            toggle auto-post when a Mythic+ key completes (off by default)

---------------------------------------------------------------------------
-- EDIT HERE: the lines that get posted, top to bottom.
-- Keep each line under 255 characters (WoW chat limit). No color codes:
-- chat strips them, and group members' names get class-colored on their own.
---------------------------------------------------------------------------
local LINES = {
    "********sMecKsDungeonData Addon********",
    "MVP: Lilputo-Shadowmoon",
    "Top DMG: Lilputo-Shadowmoon (363.00M)",
    "Top Healing: Kimk-Shadowmoon (194.04M)",
    "Top Interrupts: Lilputo-Shadowmoon (36)",
    "Top Dispels: Kimk-Shadowmoon (45)",
    "Avoidable DMG: Lilputo-Shadowmoon (454.25K)",
    "************************************************",
}

local LINE_DELAY = 0.2   -- seconds between lines

-- Class colors used ONLY by /lilmvp preview (your own chat frame).
-- Posted lines stay plain text. Use the class token (e.g. "PALADIN"),
-- or nil to look it up from your group (falls back to white).
local NAME_CLASSES = {
    ["Lilputo-Shadowmoon"] = "PALADIN",
    ["Kimk-Shadowmoon"]    = nil,
}
---------------------------------------------------------------------------

local ADDON = ...
local PREFIX = "|cff33ff99LilMVP|r: "
local queue = {}          -- pending lines: { text, channel }
local sending = false
local pendingAfterCombat = false

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(msg))
end

local function DefaultChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

local function ValidChannel(ch)
    if ch == "SAY" then return true end
    if ch == "PARTY" then return IsInGroup() end
    if ch == "INSTANCE_CHAT" then return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) end
    if ch == "RAID" then return IsInRaid() end
    return false
end

local function CombatBlocked()
    return InCombatLockdown() or UnitAffectingCombat("player")
end

local SendNext -- forward

local function TrySend(text, channel)
    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    local ok, err = pcall(send, text, channel)
    return ok, err
end

SendNext = function()
    if #queue == 0 then
        sending = false
        return
    end
    if CombatBlocked() then
        -- Midnight may restrict addon chat in combat inside instances: wait.
        sending = false
        if not pendingAfterCombat then
            pendingAfterCombat = true
            Print("In combat - will post when combat ends.")
        end
        return
    end
    local item = queue[1]
    local ok = TrySend(item[1], item[2])
    if not ok then
        -- Leave the line queued and retry after combat / shortly.
        sending = false
        pendingAfterCombat = true
        Print("Chat send blocked - will retry after combat.")
        return
    end
    table.remove(queue, 1)
    if #queue > 0 then
        C_Timer.After(LINE_DELAY, SendNext)
    else
        sending = false
    end
end

local function Post(channel)
    channel = channel or DefaultChannel()
    if not channel then
        Print("You're not in a group. Use /lilmvp say or /lilmvp preview.")
        return
    end
    if not ValidChannel(channel) then
        Print("Can't post to " .. channel .. " right now.")
        return
    end
    if #queue > 0 then
        Print("Already posting, hold on.")
        return
    end
    for _, line in ipairs(LINES) do
        queue[#queue + 1] = { string.sub(line, 1, 254), channel }
    end
    sending = true
    SendNext()
end

local function GroupClassOf(fullName)
    local short = fullName:match("^([^%-]+)")
    local units = { "player" }
    for i = 1, 4 do units[#units + 1] = "party" .. i end
    for i = 1, 40 do units[#units + 1] = "raid" .. i end
    for _, u in ipairs(units) do
        if UnitExists(u) then
            local n, r = UnitName(u)
            if n == short and (not r or r == "" or fullName == n .. "-" .. r) then
                local _, token = UnitClass(u)
                return token
            end
        end
    end
end

local function ColorName(fullName)
    local token = NAME_CLASSES[fullName] or GroupClassOf(fullName)
    local c = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if not c then
        if token == "PALADIN" then return "|cfff48cba" .. fullName .. "|r" end
        return fullName
    end
    return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, fullName)
end

local function Preview()
    for _, line in ipairs(LINES) do
        local colored = line:gsub("([%a]+%-[%a]+)", function(name)
            if name:find("DungeonData") then return name end
            return ColorName(name)
        end)
        DEFAULT_CHAT_FRAME:AddMessage(colored)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        LilMVPDB = LilMVPDB or {}
        if LilMVPDB.auto == nil then LilMVPDB.auto = false end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingAfterCombat and #queue > 0 and not sending then
            pendingAfterCombat = false
            sending = true
            C_Timer.After(1, SendNext)
        end
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        if LilMVPDB and LilMVPDB.auto then
            C_Timer.After(2, function() Post() end)
        end
    end
end)

SLASH_LILMVP1 = "/lilmvp"
SlashCmdList.LILMVP = function(msg)
    msg = string.lower(strtrim(msg or ""))
    if msg == "" then
        Post()
    elseif msg == "preview" then
        Preview()
    elseif msg == "say" then
        Post("SAY")
    elseif msg == "party" then
        Post("PARTY")
    elseif msg == "instance" then
        Post("INSTANCE_CHAT")
    elseif msg == "auto" then
        LilMVPDB.auto = not LilMVPDB.auto
        Print("Auto-post on key completion: " .. (LilMVPDB.auto and "ON" or "OFF"))
    else
        Print("/lilmvp | preview | say | party | instance | auto")
    end
end

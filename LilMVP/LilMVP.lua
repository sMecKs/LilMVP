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

local function Preview()
    for _, line in ipairs(LINES) do
        DEFAULT_CHAT_FRAME:AddMessage(line)
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

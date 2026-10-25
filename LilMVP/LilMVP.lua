-- LilMVP: joke "dungeon summary" poster.
-- /lilmvp                 post to your group (instance / raid / party chat)
-- /lilmvp preview         print only to your own chat frame
-- /lilmvp say|party|instance  post to that channel
-- /lilmvp auto            toggle a "Post LilMVP" button that pops up when a Mythic+ key completes
--
-- WoW only lets addons send chat right when you press a key or click a button,
-- so every line is sent at once from the slash command or the button click.

---------------------------------------------------------------------------
-- EDIT HERE: the lines that get posted, top to bottom.
-- Keep each line under 255 characters. No color codes: chat strips them,
-- and group members' names get class-colored on their own.
---------------------------------------------------------------------------
local LINES = {
    "********sMecKsDungeonData Addon********",
    "MVP: Lilputo-Shadowmoon",
    "Top DMG: Lilputo-Shadowmoon (512.87M)",
    "Top Healing: Kimk-Shadowmoon (194.04M)",
    "Top Interrupts: Lilputo-Shadowmoon (58)",
    "Top Dispels: Kimk-Shadowmoon (45)",
    "Avoidable DMG: Lilputo-Shadowmoon (12.48K)",
    "************************************************",
}

-- Class colors used ONLY by /lilmvp preview (your own chat frame).
local NAME_CLASSES = {
    ["Lilputo-Shadowmoon"] = "PALADIN",
    ["Kimk-Shadowmoon"]    = nil,   -- nil = look it up from your group
}
---------------------------------------------------------------------------

local ADDON = ...
local PREFIX = "|cff33ff99LilMVP|r: "

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

local function Send(text, channel)
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(text, channel)
    else
        SendChatMessage(text, channel)
    end
end

-- Must be called directly from a keypress (slash command) or a button click.
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
    for _, line in ipairs(LINES) do
        Send(string.sub(line, 1, 254), channel)
    end
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

-- Pop-up button shown after a key completes (auto mode). Clicking it posts.
local button = CreateFrame("Button", "LilMVPPostButton", UIParent, "UIPanelButtonTemplate")
button:SetSize(160, 32)
button:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
button:SetText("Post LilMVP")
button:SetMovable(true)
button:EnableMouse(true)
button:RegisterForDrag("LeftButton")
button:SetScript("OnDragStart", button.StartMoving)
button:SetScript("OnDragStop", button.StopMovingOrSizing)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:SetScript("OnClick", function(self, mouse)
    if mouse == "LeftButton" then Post() end
    self:Hide()
end)
button:Hide()

local hideTimer
local function ShowButton()
    button:Show()
    Print("Key done! Click the Post LilMVP button (right-click to dismiss).")
    if hideTimer then hideTimer:Cancel() end
    hideTimer = C_Timer.NewTimer(120, function() button:Hide() end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        LilMVPDB = LilMVPDB or {}
        if LilMVPDB.auto == nil then LilMVPDB.auto = false end
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        if LilMVPDB and LilMVPDB.auto then ShowButton() end
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
        Print("Post button after a key: " .. (LilMVPDB.auto and "ON" or "OFF"))
    elseif msg == "button" then
        ShowButton()
    else
        Print("/lilmvp | preview | say | party | instance | auto | button")
    end
end

-------------------------------------------------------------------------------
-- Advanced Member Tooltip v1.1
-------------------------------------------------------------------------------
-- Author: Arkadius, continued by Calia1120
-- This Add-on is not created by, affiliated with or sponsored by ZeniMax Media
-- Inc. or its affiliates. The Elder Scrolls® and related logos are registered
-- trademarks or trademarks of ZeniMax Media Inc. in the United States and/or
-- other countries.
--
-- You can read the full terms at:
-- https://account.elderscrollsonline.com/add-on-terms
--
---------------------------------------------------------------------------------


local AddonName = "AdvancedMemberTooltip"
AMT = {}
local savedData = nil
local defaultData =
{
    lastCleanUp = 0
}
local scanGuildIndex = nil
local scanCategory = GUILD_HISTORY_GENERAL
local firstScan = true
local scanTimer = 5 * 60 * 1000
local scanInterval = 6000
local initialScan = false

local lang
local langStrings =
{
    en =
    {
        member      = "Member for %s%i %s",
        depositions = "Deposits",
        withdrawals = "Withdrawals",
        total       = "Total: %i |t16:16:EsoUI/Art/currency/currency_gold.dds|t (over %i %s)",
        last        = "Last: %i |t16:16:EsoUI/Art/currency/currency_gold.dds|t (%i %s ago)",
        minute      = "minute",
        hour        = "hour",
        day         = "day"
    },
	fr =
    {
        member      = "Membre pour %s%i %s",
        depositions = "Dépôts",
        withdrawals = "Retraits",
        total       = "Total: %i |t16:16:EsoUI/Art/currency/currency_gold.dds|t (sur %i %s)",
        last        = "Dernier: %i |t16:16:EsoUI/Art/currency/currency_gold.dds|t (%i %s depuis)",
        minute      = "minute",
        hour        = "heure",
        day         = "jour"
    },
    de =
    {
        member      = "Mitglied seit %s%i %s",
        depositions = "Einzahlungen",
        withdrawals = "Auszahlungen",
        total       = "Gesamt: %i |t16:16:EsoUI/Art/currency/currency_gold.dds|t (innerhalb von %i %s)",
        last        = "Zuletzt: %i |t16:16:EsoUI/Art/currency/currency_gold.dds|t (vor %i %s)",
        minute      = "Minute",
        hour        = "Stunde",
        day         = "Tag"
    }
}



-- Hooked functions
local org_ZO_KeyboardGuildRosterRowDisplayName_OnMouseEnter = ZO_KeyboardGuildRosterRowDisplayName_OnMouseEnter
local org_ZO_KeyboardGuildRosterRowDisplayName_OnMouseExit = ZO_KeyboardGuildRosterRowDisplayName_OnMouseExit


local function secToTime(seconds)
    local time = math.floor(seconds / 60)
    local str = langStrings[lang]["minute"]

    if (time > 60) then
        time = math.floor(seconds / (60 * 60))

        if (time > 24) then
            time = math.floor(seconds / (60 * 60 * 24))

            str = langStrings[lang]["day"]
        else
            str = langStrings[lang]["hour"]
        end
    end

    if (time ~= 1) then
        if (lang == "en") then
            str = str .. 's'
        end

        if (lang == "de") then
            if (str == langStrings[lang]["day"]) then
                str = str .. 'en'
            else
                str = str .. 'n'
            end
        end
    end

    return time, str
end


function ZO_KeyboardGuildRosterRowDisplayName_OnMouseEnter(control)
    org_ZO_KeyboardGuildRosterRowDisplayName_OnMouseEnter(control)

    local parent = control:GetParent()
    local data = ZO_ScrollList_GetData(parent)
    local guildName = GetGuildName(GUILD_SELECTOR.guildId)
    local displayName = string.lower(data.displayName)
    local timeStamp = GetTimeStamp()

    local tooltip = data.characterName
    local num, str

    if (savedData[guildName] ~= nil) then
        if (savedData[guildName][displayName] ~= nil) then
            tooltip = tooltip .. "\n\n"

            if (savedData[guildName][displayName].timeJoined == 0) then
                num, str = secToTime(timeStamp - savedData[guildName]["oldestEvents"][GUILD_HISTORY_GENERAL])
                tooltip = tooltip .. string.format(langStrings[lang]["member"], "> ", num, str) .. "\n\n"
            else
                num, str = secToTime(timeStamp - savedData[guildName][displayName].timeJoined)
                tooltip = tooltip .. string.format(langStrings[lang]["member"], "", num, str) .. "\n\n"
            end

            tooltip = tooltip .. langStrings[lang]["depositions"] .. ':' .. "\n"
            num, str = secToTime(timeStamp - savedData[guildName]["oldestEvents"][GUILD_HISTORY_BANK])
            tooltip = tooltip .. string.format(langStrings[lang]["total"], savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_ADDED].total, num, str) .. "\n"

            if (savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_ADDED].timeLast == 0) then
                num, str = secToTime(timeStamp - savedData[guildName]["oldestEvents"][GUILD_HISTORY_BANK])
            else
                num, str = secToTime(timeStamp - savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_ADDED].timeLast)
            end
            tooltip = tooltip .. string.format(langStrings[lang]["last"], savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_ADDED].last, num, str) .. "\n\n"

            tooltip = tooltip .. langStrings[lang]["withdrawals"] .. ':' .. "\n"
            num, str = secToTime(timeStamp - savedData[guildName]["oldestEvents"][GUILD_HISTORY_BANK])
            tooltip = tooltip .. string.format(langStrings[lang]["total"], savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_REMOVED].total, num, str) .. "\n"

            if (savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_REMOVED].timeLast == 0) then
                num, str = secToTime(timeStamp - savedData[guildName]["oldestEvents"][GUILD_HISTORY_BANK])
            else
                num, str = secToTime(timeStamp - savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_REMOVED].timeLast)
            end
            tooltip = tooltip .. string.format(langStrings[lang]["last"], savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_REMOVED].last, num, str)
        end
    end
      
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0, TOPCENTER)
    SetTooltipText(InformationTooltip, tooltip)
end


function ZO_KeyboardGuildRosterRowDisplayName_OnMouseExit(control)
    ClearTooltip(InformationTooltip)

    org_ZO_KeyboardGuildRosterRowDisplayName_OnMouseExit(control)
end


function AMT.createGuild(guildName)
    if (savedData[guildName] == nil) then
        savedData[guildName] = {}
    end

    if (savedData[guildName]["oldestEvents"] == nil) then
        savedData[guildName]["oldestEvents"] = {}
    end

    if (savedData[guildName]["oldestEvents"][GUILD_HISTORY_GENERAL] == nil) then
        savedData[guildName]["oldestEvents"][GUILD_HISTORY_GENERAL] = 0
    end

    if (savedData[guildName]["oldestEvents"][GUILD_HISTORY_BANK] == nil) then
        savedData[guildName]["oldestEvents"][GUILD_HISTORY_BANK] = 0
    end

    if (savedData[guildName]["lastScans"] == nil) then
        savedData[guildName]["lastScans"] = {}
    end

    if (savedData[guildName]["lastScans"][GUILD_HISTORY_GENERAL] == nil) then
        savedData[guildName]["lastScans"][GUILD_HISTORY_GENERAL] = 0
    end

    if (savedData[guildName]["lastScans"][GUILD_HISTORY_BANK] == nil) then
        savedData[guildName]["lastScans"][GUILD_HISTORY_BANK] = 0
    end
end


function AMT.createUser(guildName, displayName)
    if (savedData[guildName][displayName] == nil) then
        savedData[guildName][displayName] = {}
        savedData[guildName][displayName].timeJoined = 0
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_ADDED] = {}
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_ADDED].timeFirst = 0
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_ADDED].timeLast = 0
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_ADDED].last = 0
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_ADDED].total = 0
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_REMOVED] = {}
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_REMOVED].timeFirst = 0
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_REMOVED].timeLast = 0
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_REMOVED].last = 0
        savedData[guildName][displayName][GUILD_EVENT_BANKGOLD_REMOVED].total = 0
    end
end


function AMT.processEvents(guildId, category)
    local guildName = GetGuildName(guildId)
    local numEvents = GetNumGuildEvents(guildId, category)

    if (numEvents == 0) then
        return
    end

    local _, firstEventTime = GetGuildEventInfo(guildId, category, 1)
    local _, lastEventTime = GetGuildEventInfo(guildId, category, numEvents)
    local lastScan = savedData[GetGuildName(guildId)]["lastScans"][category]
    local first = numEvents
    local last = 1
    local inc = -1

    if (firstEventTime > lastEventTime) then
        first = 1
        last = numEvents
        inc = 1
    end

    for i = 1, GetNumGuildMembers(guildId), 1 do
        AMT.createUser(guildName, string.lower(GetGuildMemberInfo(guildId, i)))
    end

    for i = first, last, inc do
        evType, evTime, evName, evGold = GetGuildEventInfo(guildId, category, i)
        local displayName = string.lower(evName)
        local timeStamp = GetTimeStamp() - evTime


        -- Save the timestamp of the oldest event
        -- Some weird bug can cause timestamp to be negative, for whatever reason
        if (savedData[guildName]["oldestEvents"][category] == 0) or (savedData[guildName]["oldestEvents"][category] > timeStamp) then
            if (timeStamp > 0) then
                savedData[guildName]["oldestEvents"][category] = timeStamp
            end
        end

        -- Fix a bug from v0.1.1
        if (savedData[guildName]["oldestEvents"][category] < 0) then
            local t = 1500000000

            for _, displayName in pairs(savedData[guildName]) do
                if (displayName["timeJoined"] ~= nil) then
                    if (category == GUILD_HISTORY_GENERAL) then
                        if (displayName["timeJoined"] > 0) and (displayName["timeJoined"] < t) then
                            t = displayName["timeJoined"]
                        end
                    else
                        if (displayName[GUILD_EVENT_BANKGOLD_ADDED].timeFirst > 0) and (displayName[GUILD_EVENT_BANKGOLD_ADDED].timeFirst < t) then
                            t = displayName[GUILD_EVENT_BANKGOLD_ADDED].timeFirst
                        end
                    end
                end
            end

            savedData[guildName]["oldestEvents"][category] = t
        end

        if (savedData[guildName][displayName] ~= nil) then
            if (timeStamp > lastScan) or (lastScan == 0) then
                if (category == GUILD_HISTORY_GENERAL) then
                    if (evType == GUILD_EVENT_GUILD_JOIN) then
                        if (savedData[guildName][displayName].timeJoined < timeStamp) then
                            savedData[guildName][displayName].timeJoined = timeStamp
                        end
                    end

                    savedData[guildName]["lastScans"][category] = timeStamp
                end

                if (category == GUILD_HISTORY_BANK) then
                    if (evType == GUILD_EVENT_BANKGOLD_ADDED) or (evType == GUILD_EVENT_BANKGOLD_REMOVED) then
                        if (savedData[guildName][displayName][evType].timeLast < timeStamp) and (math.abs(savedData[guildName][displayName][evType].timeLast - timeStamp) > 2) then
                            savedData[guildName][displayName][evType].total = savedData[guildName][displayName][evType].total + evGold
                            savedData[guildName][displayName][evType].last = evGold
                            savedData[guildName][displayName][evType].timeLast = timeStamp

                            if (savedData[guildName][displayName][evType].timeFirst == 0) then
                                savedData[guildName][displayName][evType].timeFirst = timeStamp
                            end
                        end
                    end

                    savedData[guildName]["lastScans"][category] = timeStamp
                end
            end
        end
    end
end


function AMT.onGuildHistoryResponseReceived(eventCode, guildId, category)
    if (category ~= GUILD_HISTORY_GENERAL) and (category ~= GUILD_HISTORY_BANK) then
        return
    end


-- d(GetGuildName(guildId) .. " " .. category .. " " .. eventCode)
    local numEvents = GetNumGuildEvents(guildId, category)
    local _, firstEventTime = GetGuildEventInfo(guildId, category, 1)
    local _, lastEventTime = GetGuildEventInfo(guildId, category, numEvents)
    local lastScan = savedData[GetGuildName(guildId)]["lastScans"][category]
    local timeStamp = GetTimeStamp()

    if ((timeStamp - firstEventTime) > lastScan and (timeStamp  - lastEventTime) > lastScan) or (lastScan == 0) then
        zo_callLater(AMT.requestData, scanInterval)
    else
        AMT.processEvents(guildId, category)
        AMT.scanNext()
    end
end


function AMT.requestData()
    local guildId = GetGuildId(scanGuildIndex)
    local newPage

    if (firstScan) then
        firstScan = false
        AMT.createGuild(GetGuildName(guildId))
        newPage = RequestGuildHistoryCategoryNewest(guildId, scanCategory)
    else
        newPage = RequestGuildHistoryCategoryOlder(guildId, scanCategory)
    end

    -- No more data available. Continue with next guild
    if (not newPage) then
        AMT.processEvents(guildId, scanCategory)
        AMT.scanNext()
    end
end


function AMT.scanNext()
    if (scanCategory == GUILD_HISTORY_GENERAL) then
        AMT.scan(scanGuildIndex, GUILD_HISTORY_BANK)
    else
        if (initialScan == true) then
            local guildId = GetGuildId(scanGuildIndex)
            local guildName = GetGuildName(guildId)
            initialScan = false

            d("[AMT] Initial scan for " .. guildName .. " finished!")
        end

        if (scanGuildIndex < GetNumGuilds()) then
           AMT.scan(scanGuildIndex + 1, GUILD_HISTORY_GENERAL)
        else
            EVENT_MANAGER:UnregisterForEvent(AddonName, EVENT_GUILD_HISTORY_RESPONSE_RECEIVED)
            zo_callLater(AMT.scanGuilds, scanTimer)
        end
    end
end


function AMT.scan(guildIndex, category)
    local guildId = GetGuildId(guildIndex)
    scanGuildIndex = guildIndex
    scanCategory = category
    firstScan = true
    local guildName = GetGuildName(guildId)

    if (savedData[guildName] == nil) then
        initialScan = true
        d("[AMT] Initial scan for " .. guildName .. " running! This may take a few minutes ...")
    end

    zo_callLater(AMT.requestData, scanInterval)
end


function AMT.scanGuilds()
    if (GetNumGuilds() == 0) then
        zo_callLater(AMT.scanGuilds, scanTimer)
    else
        EVENT_MANAGER:RegisterForEvent(AddonName, EVENT_GUILD_HISTORY_RESPONSE_RECEIVED, AMT.onGuildHistoryResponseReceived)
        AMT.scan(1, GUILD_HISTORY_GENERAL)
    end
end


function AMT.OnPlayerActivated(eventCode)
    EVENT_MANAGER:UnregisterForEvent(AddonName, eventCode)
    zo_callLater(AMT.scanGuilds, scanInterval)
end


-- Will be called upon loading the addon
local function onAddOnLoaded(eventCode, addonName)
    if (addonName ~= AddonName) then
        return
    end

    lang = GetCVar("language.2")

    if (lang ~= "en") and (lang ~= "de") then
        lang = "en"
    end

    savedData = ZO_SavedVars:NewAccountWide(AddonName, 1, nil, defaultData)

    EVENT_MANAGER:RegisterForEvent(AddonName, EVENT_PLAYER_ACTIVATED, AMT.OnPlayerActivated)
    EVENT_MANAGER:UnregisterForEvent(AddonName, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(AddonName, EVENT_ADD_ON_LOADED, onAddOnLoaded)



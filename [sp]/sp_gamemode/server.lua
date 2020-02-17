function onPlayerQuit( quitType, reason, responsibleElement )
    local prevLevel = xrPlayerLevels[ source ]
    if prevLevel then
        prevLevel:doPlayerLeave( source )
        prevLevel:removePlayer( source )
    end
end

function onPlayerDeadFinish()
    local prevLevel = xrPlayerLevels[ source ]
    if prevLevel then
        prevLevel:doPlayerLeave( source, true )
    end 
end

function xrGamemodeJoin( player )
    -- Если к игроку не привязаны данные персонажа
    if not getElementData( player, "charId", false ) then
        outputDebugString( "К игроку должен быть привязан персонаж!", 1 )
        return false
    end

    local level = xrLevels[ 1 ]
    if not level then
        return
    end

    local prevLevel = xrPlayerLevels[ player ]
    if level == prevLevel then
        
    else
        if prevLevel then
            prevLevel:removePlayer( player )
        end

        level:addPlayer( player )
        xrPlayerLevels[ player ] = level
    end

    level:doPlayerJoin( player )
    
    return true
end

function xrIsPlayerJoined( player )
    local level = xrPlayerLevels[ player ]
    if level then
        return level:isPlayerJoined( player )
    end

    return false
end

function xrGiveNPCMoney( element, amount, testOnly )
    return true
end

--[[
    xrKillManager
]]
xrKillManager = {
    killers = {}
}

function xrKillManager:onKillEvent( killerId, victimId )
    local killers = self.killers
    local timestamp = getRealTime().timestamp

    local killerData = killers[ killerId ]
    if killerData then
        killerData[ victimId ] = timestamp
    else
        killers[ killerId ] = {
            [ victimId ] = timestamp
        }
    end

    -- Удаляем устаревшие записи
    self:recuperate()
end

function xrKillManager:getKillerLastVictim( killerId, victimId )
    local killers = self.killers

    local killerData = killers[ killerId ]
    if killerData then
        return killerData[ victimId ]
    end
end

function xrKillManager:recuperate()
    local killers = self.killers
    local timestamp = getRealTime().timestamp

    for killerId, killerData in pairs( killers ) do
        local entriesNum = 0

        for id, time in pairs( killerData ) do
            if ( timestamp - time ) >= WANTED_RECUPERATION_TIME then
                killerData[ id ] = nil
            else
                entriesNum = entriesNum + 1
            end
        end

        if entriesNum < 1 then
            killers[ killerId ] = nil
        end
    end
end

--[[
    Initialization
]]
addEvent( "onCoreInitializing", false )
addEventHandler( "onCoreInitializing", root,
    function()
		triggerEvent( "onResourceInitialized", resourceRoot, resource )
    end
, false )

addEventHandler( "onCoreStarted", root,
    function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

        if not xrSettingsInclude( "teams.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации команд!", 2 )
            return
        end

        if not xrSettingsInclude( "quests.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации квестов!", 2 )
            return
        end

        if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
        end

        addEventHandler( "onPlayerQuit", root, onPlayerQuit, true, "high" )
        addEvent( EServerEvents.onPlayerDeadFinish, true )
        addEventHandler( EServerEvents.onPlayerDeadFinish, root, onPlayerDeadFinish )  

        setMinuteDuration( G_TIME_DURATION )
        
        xrInitLevels()
        xrInitTeams()
        initQuests()
        initSurge()
    end
)
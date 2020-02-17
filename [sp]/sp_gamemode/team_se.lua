xrTeamHashes = {}
xrTeamElements = {}

xrTeam = {

}
xrTeamMT = {
    __index = xrTeam
}

function xrTeam:setPlayer( player )
    setPlayerTeam( player, self.element )
end

function xrTeam:printNews( str, sectionName )
    for _, player in ipairs( getPlayersInTeam( self.element ) ) do
        exports.sp_hud_real_new:xrPrintPlayerNews( player, str, sectionName )
    end
end

function xrTeam:onMemberKill( memberPlayer, victimPlayer )
    local killers = self.killers
    local timestamp = getRealTime().timestamp

    local victimTeamElement = getPlayerTeam( victimPlayer )
    local victimId = getElementData( victimPlayer, "charId", false )
    local victimData = killers[ victimId ]
    
    local memberName = tostring( getElementData( memberPlayer, "name", false ) )

    --[[if victimData then
        outputDebugString("onMemberKill: " .. inspect(victimData))
    end]]

    --[[
        Если жертва разыскивалась - награждаем убийцу
    ]]          
    if victimData and victimData.level > 0 then
        local deltaTimestamp = timestamp - victimData.lastKillTime
        local bonusFactor = math.max( WANTED_BONUS_TIM_SECS - deltaTimestamp, 0 ) / WANTED_BONUS_TIM_SECS
        local bonusValue = math.floor( bonusFactor * WANTED_BONUS_MAX_RUBLES )
        local rewardValue = WANTED_LEVEL_REWARDS[ victimData.level ]
        local rewardTotal = rewardValue + bonusValue

        exports.sp_player:xrAddPlayerRank( memberPlayer, math.ceil( bonusFactor * 6 ) )
        xrGiveElementMoney( memberPlayer, rewardTotal )

        -- Оповещаем всех союзников убийцы о получени награды
        self:printNews( 
            "За уничтожение нарушителя, " .. memberName .. " награждается суммой " .. rewardTotal .. " игровых рублей", 
            "ui_inGame2_PD_storonnik_ravnovesiya"
        )

        return true
    end    

    return false
end

function xrTeam:onMemberWasted( victimPlayer, killerPlayer )
    local killers = self.killers
    local timestamp = getRealTime().timestamp

    local victimId = getElementData( victimPlayer, "charId", false )
    local killerTeamElement = getPlayerTeam( killerPlayer )
    local killerTeam = xrTeamElements[ killerTeamElement ]
    local killerId = getElementData( killerPlayer, "charId", false )
    local killerName = tostring( getElementData( killerPlayer, "name", false ) )     

    --[[
        Если убитый был в розыске в команде у розыскиваемого -
        считаем такое убийство законным
    ]]
    local lastVictimKillTime = xrKillManager:getKillerLastVictim( killerId, victimId )
    local isLastKillTimeExpired = not lastVictimKillTime or ( timestamp - lastVictimKillTime ) >= WANTED_RECUPERATION_TIME

    if killerTeam and isLastKillTimeExpired then
        if killerTeam:onMemberKill( killerPlayer, victimPlayer ) then
            return
        end
    end

    --[[
        Убийство игрока во время захвата территории
        не является нарушением
    ]]
    if exports.anomaly:xrIsPlayerCaptureZone( victimPlayer ) then
        return
    end

    --[[
        Обработка убийства не разыскиваемого игрока
    ]]    
    local isKillerAlly = killerTeamElement == self.element
    local victimThreshold = isKillerAlly and WANTED_THRESHOLD_ALLY or WANTED_THRESHOLD_ENEMY

    local lastKillTime = timestamp
    local count = 0
    local level = 0        

    local killerData = killers[ killerId ]
    if killerData then
        lastKillTime = killerData.lastKillTime
        count = killerData.count
        level = killerData.level
    end

    lastKillTime = timestamp
    count = count + 1
    if count >= victimThreshold and level < WANTED_MAX_LEVEL then
        level = level + 1

        local reward = WANTED_LEVEL_REWARDS[ level ]
        self:printNews(
            "За игрока " .. tostring( killerName ) .. " объявлена награда " .. tostring( reward ) .. " рублей. Игрок помечен специальным маркером на карте.", 
            "ui_inGame2_PD_storonnik_ravnovesiya" 
        )       
    end

    killers[ killerId ] = {
        lastKillTime = lastKillTime,
        count = count,
        level = level
    }

    xrUpdatePlayerWantedData( killerPlayer )

    --outputDebugString("onMemberWasted: " .. inspect(killers[ killerId ]))
end

function xrTeam:onPulse()
    local killers = self.killers
    local timestamp = getRealTime().timestamp

    for killerId, killerData in pairs( killers ) do
        local deltaTimestamp = timestamp - killerData.lastKillTime
        local period = WANTED_LEVEL_PERIOD[ killerData.level ] or WANTED_RESET_PERIOD_SECS
        if deltaTimestamp >= period then
            killers[ killerId ] = nil

            local player = exports.sp_player:xrGetPlayerFromCharacterId( killerId )
            if player then
                xrUpdatePlayerWantedData( player )
            end

            outputDebugString( "Розыск " .. killerId .. " завершен" )
        end
    end
end

function xrSetPlayerTeam( player, teamHash )
    if not teamHash then
        setPlayerTeam( player, nil )
        return
    end

    local team = xrTeamHashes[ teamHash ]
    if team then
        team:setPlayer( player )
    end
end

function xrUpdatePlayerWantedData( player )
    local playerId = getElementData( player, "charId", false )

    local result = {

    }

    for teamHash, team in pairs( xrTeamHashes ) do
        local playerData = team.killers[ playerId ]
        if playerData and playerData.level > 0 then
            result[ team.element ] = true
        end
    end

    if #result > 0 then
        setElementData( player, "wanted", result, true )
    else
        removeElementData( player, "wanted" )
    end
end

function xrGetPlayerMaxWantedLevel( player )
    local playerId = getElementData( player, "charId", false )

    local maxLevel = 0

    for teamHash, team in pairs( xrTeamHashes ) do
        local playerData = team.killers[ playerId ]
        if playerData and playerData.level > 0 then
            maxLevel = math.max( maxLevel, playerData.level )
        end
    end

    return maxLevel
end

local function xrTeams_onPlayerDead( killer, bodypart )
    local victimTeam = xrTeamElements[ getPlayerTeam( source ) ]
    local victimId = getElementData( source, "charId", false ) 
    local victimMaxWantedLevel = xrGetPlayerMaxWantedLevel( source )   

    if isElement( killer ) and getElementType( killer ) == "player" and killer ~= source then
        --[[
            Оповещаем группировку, в которой состоит игрок
        ]]
        if victimTeam then
            victimTeam:onMemberWasted( source, killer )
        end

        local killerId = getElementData( killer, "charId", false )
        -- Запоминаем время последнего убийства
        xrKillManager:onKillEvent( killerId, victimId )
    end

    --[[
        Удаляем жертву из розыска во всех группировках
    ]]
    for teamHash, team in pairs( xrTeamHashes ) do
        team.killers[ victimId ] = nil
    end
    
    removeElementData( source, "wanted" )
    setElementData( source, "offender", victimMaxWantedLevel >= 2, false )
end

local function xrTeams_onPlayerJoin()
    xrUpdatePlayerWantedData( source )
end

local function xrTeams_onPulse()
    for teamHash, team in pairs( xrTeamHashes ) do
        team:onPulse()
    end
end

--[[
    Init
]]
function xrInitTeams()
    local listSection = xrSettingsGetSection( _hashFn( "teams_list" ) )
    if not listSection then
        outputDebugString( "Не можем найти список группировок", 2 )
        return
    end

    for _, section in ipairs( listSection ) do
        local element = createTeam( section.name )
        setElementData( element, "cl", section._nameHash )
        setElementData( element, "text", section.text or "Команда" )

        local color = section.color or Vector3( 255, 255, 255 )
        setTeamColor( element, color:getX(), color:getY(), color:getZ() )

        local teamData = {
            section = section,
            element = element,
            killers = {}
        }
        setmetatable( teamData, xrTeamMT )       

        xrTeamHashes[ section._nameHash ] = teamData
        xrTeamElements[ element ] = teamData
    end

    setTimer( xrTeams_onPulse, 5000, 0 )

    addEvent( EServerEvents.onPlayerDead, true )
    addEventHandler( EServerEvents.onPlayerDead, root, xrTeams_onPlayerDead, true, "low-1" )
    addEvent( EServerEvents.onPlayerGamodeJoin, true )
    addEventHandler( EServerEvents.onPlayerGamodeJoin, root, xrTeams_onPlayerJoin, true )
end
--[[
    ZoneSector
]]
xrCaptureZones = {

}

ZSS_IDLE = 1
ZSS_TAKING = 2 -- Идет захват
ZSS_AWAIT = 3 -- В зоне несколько группировок
ZSS_ZERO = 4 -- В зоне никого нет

local stateStrs = {
    "ZSS_IDLE",
    "ZSS_TAKING",
    "ZSS_AWAIT",
    "ZSS_ZERO"
}

local SECTION_TAKING_TIME = 30 -- В секундах

ZoneSector = {
    -- Допустимые для зоны элементы
    elementTypes = {
        [ "player" ] = true
    }
}
setmetatable( ZoneSector, { __index = Zone } )

function ZoneSector:create( typeHash, position, id )
    if Zone.create( self, typeHash, position, id ) then
        --[[local teamHash = tonumber( self.section.team ) or EHashes.TeamStalker
        local teamSection = xrSettingsGetSection( teamHash )
        if teamSection then
            self:setOwnerTeam( getTeamFromName( teamSection.name ) )
        else
            outputDebugString( "Для данной команды не была найдена секция", 2 )
        end]]
        self.occupyTimestamp = nil
        self:setOwnerTeam( false )
 
        self:setState( ZSS_IDLE )

        table.insert( xrCaptureZones, self )
        
        return true
    end

    return false
end

function ZoneSector:destroy()
    Zone.destroy( self )

    table.removeValue( xrCaptureZones, self )
end

function ZoneSector:write( out )
    Zone.write( self, out )

    out[ ZA_STATE ] = self.state
    out[ ZA_OWNER ] = self.team
    out[ ZA_TIMESTAMP ] = self.occupyTimestamp
end

function ZoneSector:setState( newState )
    if newState == self.state then
        return
    end

    self.state = newState

    -- Передаем команду-захватчика
    if newState == ZSS_TAKING then
        triggerClientEvent( EClientEvents.onZoneEvent, resourceRoot, ZONE_TAKING_TEAM, self.id, self.takingTeam )
    end

    outputDebugString( "Sector new state SERVER " .. stateStrs[ newState ] )

    triggerClientEvent( EClientEvents.onZoneEvent, resourceRoot, ZONE_STATE_CHANGE, self.id, newState )
end

function ZoneSector:setOwnerTeam( team )
    if team ~= self.team then
        self.team = team
        self.occupyTimestamp = getRealTime().timestamp

        if isTimer( self.timer ) then
            killTimer( self.timer )
        end

        if isElement( team ) then
            self.timer = setTimer(
                function()
                    self:onZoneRecuperate()
                end
            , ZONE_OCCUPY_PERIOD_SECS * 1000, 1 )
        end

        triggerClientEvent( EClientEvents.onZoneEvent, resourceRoot, ZONE_OWNER, self.id, team )
    end
end

function ZoneSector:onZoneRecuperate()
    self:setOwnerTeam( false )

    local name = tostring( self.section.name )
    exports.sp_hud_real_new:xrPrintNews( 
        "Аванпост " .. name .. " доступен для захвата", 
        "ui_inGame2_Mesta_evakuatsii" 
    )
end

function ZoneSector:onHit( element )
    local playerTeam = getPlayerTeam( element )
    if not playerTeam then
        outputDebugString( "У игрока нет команды!", 2 )
        return
    end

    if isElement( self.team ) then
        return
    end

    if self.state == ZSS_IDLE then
        --if playerTeam ~= self.team then
            if self:hasTeamMemberExcept( playerTeam ) then
                self:setState( ZSS_AWAIT )

                exports.sp_hud_real_new:xrSendPlayerHelpString( element, HSC_CRUSH_AREA )
            else
                self.takingTeam = playerTeam
                self.takingTime = SECTION_TAKING_TIME
                self:setState( ZSS_TAKING )

                exports.sp_hud_real_new:xrSendPlayerHelpString( element, HSC_KEEP_AREA )
            end
        --end
    elseif self.state == ZSS_TAKING then
        if playerTeam ~= self.takingTeam then
            self:setState( ZSS_AWAIT )

            exports.sp_hud_real_new:xrSendPlayerHelpString( element, HSC_CRUSH_AREA )
        end        
    elseif self.state == ZSS_ZERO then
        if self:hasTeamMemberExcept( playerTeam ) then
            self:setState( ZSS_AWAIT )

            exports.sp_hud_real_new:xrSendPlayerHelpString( element, HSC_CRUSH_AREA )
        else
            if playerTeam ~= self.takingTeam then
                self.takingTeam = playerTeam
                self.takingTime = SECTION_TAKING_TIME
            end
            self:setState( ZSS_TAKING )

            exports.sp_hud_real_new:xrSendPlayerHelpString( element, HSC_KEEP_AREA )
        end
    end
end

function ZoneSector:onLeave( element )
    local playerTeam = getPlayerTeam( element )
    if not playerTeam then
        outputDebugString( "У игрока нет команды!", 2 )
        return
    end

    if isElement( self.team ) then
        return
    end

    if self.state == ZSS_AWAIT or self.state == ZSS_TAKING then
        -- Если никого не осталось в зоне
        if #self.nodesInside == 0 then
            self.zeroTime = getTickCount()
            self:setState( ZSS_ZERO )
            return
        end

        --[[
            Ищем господствующую команду, только члены которой находятся в зоне
        ]]
        local singleTeam = self:findSingleTeam()
        if singleTeam then
            if playerTeam ~= singleTeam then
                self.takingTeam = singleTeam
                self.takingTime = SECTION_TAKING_TIME
            end
            self:setState( ZSS_TAKING )
        else
            self:setState( ZSS_AWAIT )
        end
    end
end

function ZoneSector:findSingleTeam()
    local team
    for _, element in ipairs( self.nodesInside ) do
        local playerTeam = getPlayerTeam( element )
        if team and playerTeam ~= team then
            return
        end
        team = playerTeam
    end
    return team
end

function ZoneSector:hasTeamMember( team )
    for _, element in ipairs( self.nodesInside ) do
        if getPlayerTeam( element ) == team then
            return true
        end
    end
    return false
end

function ZoneSector:hasTeamMemberExcept( team )
    for _, element in ipairs( self.nodesInside ) do
        if getPlayerTeam( element ) ~= team then
            return true
        end
    end
    return false
end

function ZoneSector:getTeamMembersNum( team )
    local num = 0
    for _, element in ipairs( self.nodesInside ) do
        if getPlayerTeam( element ) == team then
            num = num + 1
        end
    end
    return num
end

function ZoneSector:onTakingFailed()
    
end

function ZoneSector:onTakingSuccess()
    for _, element in ipairs( self.nodesInside ) do
        local team = getPlayerTeam( element )
        if team == self.takingTeam then
            exports.sp_player:xrAddPlayerRank( element, 6 )
        end
    end

    --[[if self.team == self.takingTeam then
        outputDebugString( "Команда " .. getTeamName( self.team ) .. " успешно отбила свою зону" )

        return
    end]]

    self:setOwnerTeam( self.takingTeam )

    outputDebugString( "Теперь зоной владеет команда " .. getTeamName( self.team ) )
end

function ZoneSector:update( dt )
    local now = getTickCount()

    if self.state == ZSS_ZERO then
        if now - self.zeroTime > 5000 then 
            self:onTakingFailed()           
            self:setState( ZSS_IDLE )            
        end
    elseif self.state == ZSS_TAKING then
        local takersNum = self:getTeamMembersNum( self.takingTeam )
        local takeSpeed = math.pow( takersNum - 1, 2 ) / 5 + 0.3

        self.takingTime = self.takingTime - ( dt * takeSpeed )
        if self.takingTime <= 0 then
            self:onTakingSuccess()
            self:setState( ZSS_IDLE )           
        end
    end
end

--[[
    Exports
]]
function xrIsPlayerCaptureZone( player )
    for _, zone in ipairs( xrCaptureZones ) do
        if ( zone.state == ZSS_TAKING or zone.state == ZSS_AWAIT ) and isElementWithinColShape( player, zone.col ) then
            return true
        end
    end
    
    return false
end
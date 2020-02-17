xrPlayerGuitarSessions = {

}

xrGuitarPhases = {

}

local _phaseName = nil
local _phaseCreate = function( tbl )
    local nameHash = _hashFn( _phaseName )
    xrGuitarPhases[ nameHash ] = tbl
    xrGuitarPhases[ _phaseName ] = nameHash

    tbl.hash = nameHash
end
GuitarPhase = function( name )
    _phaseName = name
    return _phaseCreate
end

function definePhases()
    GuitarPhase "Seat" {
        endless = true
    }
    GuitarPhase "SeatDown" {
        length = 2
    }
    GuitarPhase "SeatUp" {
        length = 2
    }
    GuitarPhase "Play_1" {
        length = 29
    }
    GuitarPhase "Play_2" {
        length = 51
    }
    GuitarPhase "Play_3" {
        length = 46
    }
    GuitarPhase "Play_4" {
        length = 31
    }
    GuitarPhase "Play_5" {
        length = 71
    }
    GuitarPhase "Play_6" {
        length = 31
    }
    GuitarPhase "Play_7" {
        length = 32
    }
    GuitarPhase "Play_8" {
        length = 38
    }
    GuitarPhase "Play_9" {
        length = 32
    }
    GuitarPhase "Play_10" {
        length = 31
    }
    GuitarPhase "Play_11" {
        length = 70
    }
    GuitarPhase "Play_12" {
        length = 47
    }
    GuitarPhase "Play_13" {
        length = 49
    }
    GuitarPhase "Play_14" {
        length = 25
    }
    GuitarPhase "Play_15" {
        length = 31
    }
    GuitarPhase "Play_16" {
        length = 25
    }
    GuitarPhase "Play_Test" {
        length = 286
    }
end

--[[
    xrGuitarSession
]]
GUITAR_SESSION_START = 1
GUITAR_SESSION_STOP = 2
GUITAR_SESSION_PHASE = 3

xrGuitarSession = {

}
xrGuitarSessionMT = {
    __index = xrGuitarSession
}


local function _onPlayerGuitarPhaseEnd( player, phaseHash )
    local session = xrPlayerGuitarSessions[ player ]
    if session then
        session.phaseTimer = nil
        session:onPhaseEnd( phaseHash )
    end
end

function xrGuitarSession_new( player )
    local session = {
        player = player
    }

    return setmetatable( session, xrGuitarSessionMT )
end

function xrGuitarSession:start()
    self:startPhase( xrGuitarPhases.SeatDown )
end

function xrGuitarSession:stop( deferred, callbackFn, ... )
    if deferred then
        if type( callbackFn ) == "function" then
            self.callbackFn = callbackFn
            self.callbackArgs = { ... }
        end
        self:startPhase( xrGuitarPhases.SeatUp )
    end
end

function xrGuitarSession:startPhase( phaseHash )
    local phase = xrGuitarPhases[ phaseHash ]
    if phase then
        --[[
            Убиваем старую фазу
        ]]
        if isTimer( self.phaseTimer ) then
            killTimer( self.phaseTimer )
        end
        self.phaseTimer = nil

        --[[
            Инициализируем новую
        ]]
        self.phase = phase

        if not phase.endless then
            self.startTime = getTickCount()
            self.endTime = self.startTime + phase.length*1000

            self.phaseTimer = setTimer( _onPlayerGuitarPhaseEnd, phase.length*1000, 1, self.player, phaseHash )
        end

        triggerClientEvent( "onClientGuitarSessionEvent", self.player, GUITAR_SESSION_PHASE, phaseHash, 0 )
    end
end

function xrGuitarSession:onPhaseEnd( phaseHash )
    if phaseHash == xrGuitarPhases.SeatUp then
        if type( self.callbackFn ) == "function" then
            self.callbackFn( unpack( self.callbackArgs ) )
            self.callbackFn = nil
            self.callbackArgs = nil

            setPedAnimation( self.player, false )
        end
    elseif phaseHash == xrGuitarPhases.SeatDown then
        self:startPhase( xrGuitarPhases.Seat )
    else
        self:startPhase( xrGuitarPhases.Seat )
    end
end

function xrGuitarSession:onPlayerJoinGame( player )
    local now = getTickCount()
    local phase = self.phase
    if not phase then
        return
    end

    local progress = 0
    if not phase.endless then
        progress = math.min( ( now - self.startTime ) / (phase.length*1000), 1 )
    end

    triggerClientEvent( player, "onClientGuitarSessionEvent", self.player, GUITAR_SESSION_START )
    triggerClientEvent( player, "onClientGuitarSessionEvent", self.player, GUITAR_SESSION_PHASE, phase.hash, progress )
end

local function _onPlayerGuitarStop( player )
    if xrPlayerGuitarSessions[ player ] then
        xrPlayerGuitarSessions[ player ] = nil

        triggerClientEvent( "onClientGuitarSessionEvent", player, GUITAR_SESSION_STOP )
    end
end

function xrStartGuitarSession( player )
    if xrPlayerGuitarSessions[ player ] then
        return
    end

    local session = xrGuitarSession_new( player )
    if session then
        triggerClientEvent( "onClientGuitarSessionEvent", player, GUITAR_SESSION_START )

        session:start()
        xrPlayerGuitarSessions[ player ] = session        
    end
end

function xrStopGuitarSession( player )
    local session = xrPlayerGuitarSessions[ player ]
    if session then
        session:stop( true, _onPlayerGuitarStop, player )
    end
end

local function onGuitarSessionEvent( eventType, phaseHash )
    if eventType == GUITAR_SESSION_START then
        xrStartGuitarSession( client )
    elseif eventType == GUITAR_SESSION_STOP then
        xrStopGuitarSession( client )
    elseif eventType == GUITAR_SESSION_PHASE then
        local session = xrPlayerGuitarSessions[ client ]
        if session and session.phase and session.phase.hash == xrGuitarPhases.Seat then
            session:startPhase( phaseHash )
        end
    end
end

local function onGuitarReactionEvent( reactionHash )
    triggerClientEvent( "onClientGuitarReactionEvent", source, reactionHash )
end

local function onCombatCmdEvent( reactionHash )
    triggerClientEvent( "onClientCombatCmdEvent", source, reactionHash )
end

local function onPlayerEnterLevel()
    for player, session in pairs( xrPlayerGuitarSessions ) do
        session:onPlayerJoinGame( source )
    end
end

local function onPlayerLeaveLevel()
    local session = xrPlayerGuitarSessions[ source ]
    if session then
        session:stop( false )
        xrPlayerGuitarSessions[ source ] = nil
    end
end

local function onPlayerGamodeLeave()
    local session = xrPlayerGuitarSessions[ source ]
    if session then
        session:stop( false )
        xrPlayerGuitarSessions[ source ] = nil
    end
end

local function onPlayerWasted()
    local session = xrPlayerGuitarSessions[ source ]
    if session then
        session:stop( false )
        xrPlayerGuitarSessions[ source ] = nil
    end
end

--[[
    Init
]]
function initGuitar()
    definePhases()

    addEvent( EServerEvents.onPlayerEnterLevel, false )
    addEventHandler( EServerEvents.onPlayerEnterLevel, root, onPlayerEnterLevel )
    addEvent( EServerEvents.onPlayerLeaveLevel, false )
    addEventHandler( EServerEvents.onPlayerLeaveLevel, root, onPlayerLeaveLevel )
    addEvent( EServerEvents.onPlayerGamodeLeave, false )
    addEventHandler( EServerEvents.onPlayerGamodeLeave, root, onPlayerGamodeLeave )
    addEventHandler( "onPlayerWasted", root, onPlayerWasted )

    addEvent( "onGuitarSessionEvent", true )
    addEventHandler( "onGuitarSessionEvent", root, onGuitarSessionEvent )
    addEvent( "onGuitarReactionEvent", true )
    addEventHandler( "onGuitarReactionEvent", root, onGuitarReactionEvent )
    addEvent( "onCombatCmdEvent", true )
    addEventHandler( "onCombatCmdEvent", root, onCombatCmdEvent )
end
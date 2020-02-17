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
        endless = true,
        anim = Animations.GuitarSeat
    }
    GuitarPhase "SeatDown" {
        length = 2,
        anim = Animations.GuitarSeatDown
    }
    GuitarPhase "SeatUp" {
        length = 2,
        anim = Animations.GuitarSeatUp
    }
    GuitarPhase "Play_1" {
        length = 29,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar1
    }
    GuitarPhase "Play_2" {
        length = 51,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar2
    }
    GuitarPhase "Play_3" {
        length = 46,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar3
    }
    GuitarPhase "Play_4" {
        length = 31,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar4
    }
    GuitarPhase "Play_5" {
        length = 71,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar5
    }
    GuitarPhase "Play_6" {
        length = 31,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar6
    }
    GuitarPhase "Play_7" {
        length = 32,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar7
    }
    GuitarPhase "Play_8" {
        length = 38,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar8
    }
    GuitarPhase "Play_9" {
        length = 32,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar9
    }
    GuitarPhase "Play_10" {
        length = 31,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar10
    }
    GuitarPhase "Play_11" {
        length = 70,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar11
    }
    GuitarPhase "Play_12" {
        length = 47,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar12
    }
    GuitarPhase "Play_13" {
        length = 49,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar13
    }
    GuitarPhase "Play_14" {
        length = 25,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar14
    }
    GuitarPhase "Play_15" {
        length = 31,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar15
    }
    GuitarPhase "Play_16" {
        length = 25,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.Guitar16
    }
    GuitarPhase "Play_Test" {
        length = 286,
        anim = Animations.GuitarSeatPlay,
        snd = Sounds.GuitarTest
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

function xrGuitarSession_new( player )
    local session = {
        player = player
    }

    return setmetatable( session, xrGuitarSessionMT )
end

function xrGuitarSession:start()
    
end

function xrGuitarSession:stop()
    if isElement( self.snd ) then
        destroyElement( self.snd )
        self.snd = nil
    end
    self.phase = nil
    
    if self.object then
        exports[ "bone_attach" ]:detachElementFromBone( self.object )

        destroyElement( self.object )
        self.object = nil
    end
    
    if self.player == localPlayer then
        xrRadialMenu:setVar( "GuitarPhase", false )
    end
end

function xrGuitarSession:startPhase( phaseHash, progress )
    local phase = xrGuitarPhases[ phaseHash ]
    if phase then
        --[[
            Уничтожаем предыдущее
        ]]
        if isElement( self.snd ) then
            destroyElement( self.snd )
            self.snd = nil
        end

        --[[
            Создаем новое
        ]]
        if phase.anim then
            setPedAnimDef( self.player, phase.anim, progress )
        end
        if phase.snd then
            self.snd = playSndDef3D( self.player.position, phase.snd, progress )
        end
        self.phase = phase

        if phaseHash ~= xrGuitarPhases.SeatDown and phaseHash ~= xrGuitarPhases.SeatUp then
            if not self.object then
                local x, y, z = getElementPosition( self.player )
                self.object = createObject( 321, x, y + 1, z )

                exports[ "bone_attach" ]:attachElementToBone( self.object, self.player, 3, 0.2, 0.1, 0.12, 20, 90, 68 )
            end
        else
            if self.object then
                exports[ "bone_attach" ]:detachElementFromBone( self.object )

                destroyElement( self.object )
                self.object = nil
            end
        end 

        --[[
            Обновляем переменную для радиального меню
        ]]
        if self.player == localPlayer then
            xrRadialMenu:setVar( "GuitarPhase", phaseHash )
        end
    end
end

local function onGuitarSessionEvent( eventType, phaseHash, progress )
    if eventType == GUITAR_SESSION_START then
        -- На всякий случай проверяем, нет ли старой сессии
        local prevSession = xrPlayerGuitarSessions[ source ]
        if prevSession then
            prevSession:stop()
            xrPlayerGuitarSessions[ source ] = nil
        end

        local session = xrGuitarSession_new( source )
        if session then
            session:start()
            xrPlayerGuitarSessions[ source ] = session
        end
    elseif eventType == GUITAR_SESSION_STOP then
        local prevSession = xrPlayerGuitarSessions[ source ]
        if prevSession then
            prevSession:stop()
            xrPlayerGuitarSessions[ source ] = nil
        end
    elseif eventType == GUITAR_SESSION_PHASE then
        local session = xrPlayerGuitarSessions[ source ]
        if session then
            session:startPhase( phaseHash, progress )
        end
    end
end

local function onGuitarReactionEvent( reactionHash )    
    local snd = playSndDef3D( source.position, reactionHash )
    if snd then
        if source == localPlayer then
            xrRadialMenu:setVar( "LockVoice", true )

            setTimer(
                function()
                    xrRadialMenu:setVar( "LockVoice", false )
                end,
            getSoundLength( snd ) * 1000, 1 )
        end
    end
end

local function onCombatCmdEvent( commandHash )
    local soundName = selectSndDef3D( commandHash )
    if soundName then
        local sound = playSound3D( soundName, source.position, false )
        if sound then
            setSoundMinDistance( sound, 5 )
            setSoundMaxDistance( sound, 60 )

            if source == localPlayer then
                xrRadialMenu:setVar( "LockVoice", true )
    
                setTimer(
                    function()
                        xrRadialMenu:setVar( "LockVoice", false )
                    end,
                getSoundLength( sound ) * 1000, 1 )
            end
        end


    end
end

function onGuitarVariantSelected( phaseHash )
    triggerServerEvent( "onGuitarSessionEvent", localPlayer, GUITAR_SESSION_PHASE, phaseHash )
end

function onReactionVariantSelected( reactionHash )
    triggerServerEvent( "onGuitarReactionEvent", localPlayer, reactionHash )
end

function onVoiceCommandSelected( commandHash )
    triggerServerEvent( "onCombatCmdEvent", localPlayer, commandHash )
end

function onSeatUpCommand()
    xrStartGuitarSession()
end

function xrStartGuitarSession()
    local session = xrPlayerGuitarSessions[ localPlayer ]
    if session then
        local phase = session.phase
        if phase and ( phase.hash == xrGuitarPhases.SeatDown or phase.hash == xrGuitarPhases.SeatUp ) then
            return
        end

        triggerServerEvent( "onGuitarSessionEvent", localPlayer, GUITAR_SESSION_STOP )
    else
        triggerServerEvent( "onGuitarSessionEvent", localPlayer, GUITAR_SESSION_START )
    end
end

local function onPlayerGamemodeLeave()
    local prevSession = xrPlayerGuitarSessions[ source ]
    if prevSession then
        prevSession:stop()
        xrPlayerGuitarSessions[ source ] = nil
    end
end

local function onPlayerLeaveGamemode()
    local prevSession = xrPlayerGuitarSessions[ source ]
    if prevSession then
        prevSession:stop()
        xrPlayerGuitarSessions[ source ] = nil
    end
end

local function onPlayerWasted()
    local prevSession = xrPlayerGuitarSessions[ source ]
    if prevSession then
        prevSession:stop()
        xrPlayerGuitarSessions[ source ] = nil
    end
end

--[[
    Init
]]
function initGuitar()
    definePhases()    

    addEvent( EClientEvents.onClientPlayerLeaveLevel, true )
    addEventHandler( EClientEvents.onClientPlayerLeaveLevel, root, onPlayerGamemodeLeave )
    addEvent( EClientEvents.onClientPlayerGamodeLeave, true )
	addEventHandler( EClientEvents.onClientPlayerGamodeLeave, root, onPlayerLeaveGamemode )
    addEventHandler( "onClientPlayerQuit", root, onPlayerGamemodeLeave )
    addEventHandler( "onClientPlayerWasted", root, onPlayerWasted )

    addEvent( "onClientGuitarSessionEvent", true )
    addEventHandler( "onClientGuitarSessionEvent", root, onGuitarSessionEvent )
    addEvent( "onClientGuitarReactionEvent", true )
    addEventHandler( "onClientGuitarReactionEvent", root, onGuitarReactionEvent )
    addEvent( "onClientCombatCmdEvent", true )
    addEventHandler( "onClientCombatCmdEvent", root, onCombatCmdEvent )
end
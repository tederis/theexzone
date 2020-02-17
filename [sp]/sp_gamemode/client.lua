xrDeadCamera = {
    enabled = false    
}

local DEAD_CAM_TIME = 15000
local DEAD_CAM_MAGNITUDE = 15

function xrDeadCamera:start()
    if self.enabled then
        return
    end

    playSound( "sounds/heart/4.ogg" )

    addEventHandler( "onClientPreRender", root, xrDeadCamera.update, false )

    local x, y, z, lx, ly, lz = getCameraMatrix()

    local startPos = Vector3( x, y, z )   
    local lookVec = startPos - localPlayer.position
    lookVec:normalize()
    local endPos = localPlayer.position + lookVec * DEAD_CAM_MAGNITUDE + Vector3( 0, 0, 8 )

    local hit, hitX, hitY, hitZ = processLineOfSight( startPos, endPos, true, false, false, true, true, false, false, false )
    if hit then
        endPos = Vector3( hitX, hitY, hitZ )
    end

    self.startPos = startPos
    self.startLook = Vector3( lx, ly, lz )
    self.endPos = endPos
    self.endLook = localPlayer.position
    self.elapsedTime = 0
    self.enabled = true

    fadeCamera( false, DEAD_CAM_TIME / 1000 )
end

function xrDeadCamera:stop()
    if self.enabled then
        removeEventHandler( "onClientPreRender", root, xrDeadCamera.update ) 
        
        triggerServerEvent( EServerEvents.onPlayerDeadFinish, localPlayer )
        
        -- Показываем экран загрузки
        exports.sp_loading:xrLoader_start()

        self.enabled = false
    end
end

function xrDeadCamera.update( dt )
    local self = xrDeadCamera

    self.elapsedTime = self.elapsedTime + dt
    if self.elapsedTime > DEAD_CAM_TIME then
        xrDeadCamera:stop()
        return
    end

    local progress = self.elapsedTime / DEAD_CAM_TIME
    progress = getEasingValue( progress*progress, "InQuad" )

    local pos = self.endPos * progress + self.startPos * ( 1 - progress )
    local look = self.endLook * progress + self.startLook * ( 1 - progress )
   
    setCameraMatrix( pos, look )
end

local function onPlayerWasted()
    xrDeadCamera:start()
end

function onPlayerGamemodeJoin()
    xrPlayerJoined = true

    addEventHandler( "onClientPlayerWasted", localPlayer, onPlayerWasted, false )
end

function onPlayerGamemodeLeave()
    xrPlayerJoined = false

    removeEventHandler( "onClientPlayerWasted", localPlayer, onPlayerWasted )
end

function onPedDamage()
    if not getElementData( source, "volatile", false ) then
        cancelEvent()
    end
end

function xrIsPlayerJoined( player )
    if player == localPlayer then
        return xrPlayerJoined
    end

    return false
end

local traderVoice = {
    "sounds/trader/trader_script1c_7.ogg",
    "sounds/trader/trader_script1c_8.ogg",
    "sounds/trader/trader_script1c_9.ogg"
}
local lastTraderTime = getTickCount()

addEventHandler( "onClientCoreStarted", root,
    function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

        setPedTargetingMarkerEnabled( false )

        if not xrSettingsInclude( "teams.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации команд!", 2 )
            return
        end      
        
        addEvent( EClientEvents.onClientPlayerEnterLevel, true )
        addEventHandler( EClientEvents.onClientPlayerEnterLevel, localPlayer, onPlayerGamemodeJoin, false )
        addEvent( EClientEvents.onClientPlayerLeaveLevel, true )
        addEventHandler( EClientEvents.onClientPlayerLeaveLevel, localPlayer, onPlayerGamemodeLeave, false )
        addEventHandler( "onClientPedDamage", root, onPedDamage )

        -- Пасхалка
        local col = createColSphere( -250.8, -127.3, 106, 2 )
        addEventHandler( "onClientColShapeHit", col,
            function( element )
                if element == localPlayer then
                    local now = getTickCount()
                    if now - lastTraderTime < 10000 then
                        return
                    end
                    lastTraderTime = now

                    local randSndName = traderVoice[ math.random( 1, #traderVoice ) ]
                    playSound( randSndName )
                end
            end
        , false )

        initQuests()
    end
)
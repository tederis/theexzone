xrSurge = {
    state = false
}

SURGE_DURATION_SECS = 55*60
SURGE_SAFE_PLACES = {
    { -215.767, -127.873, -23.266 + 125 },
    { -208.93, -129.935, -22.6495 + 125 },
    { -60.6466, -71.7704, -10.312 + 125 },
    { 351.076, -91.8279, 11.7891 + 125 },
    { -85.7415, 124.589, -7.92287 + 125 }
}

function xrSurge:start( timeElapsed )
    if self.state then
        return
    end

    if timeElapsed >= SURGE_DURATION_SECS then
        return
    end

    xrSurge.startTime = xrEnvironment.gameTime - timeElapsed

    xrEnvironment.setWeatherEffect( "weather_effects/fx_surge_day_3", 10*60, 10*60, xrEnvironment.gameTime - timeElapsed )

    exports.sp_hud_real_new:xrPrintNews( 
        "Начинается выброс. Двигайтесь к ближайшему убежищу, оно помечено на карте восклицательным знаком", 
        "ui_inGame2_V_zone_nedavno_proshel_vibros" 
    )

    playSound( "sounds/zat_a2_stalker_barmen_surge_phase_1.ogg" )

    --setCameraShakeLevel( 1 )
    --setCameraShakeLevel( 0 )

    self.blips = {}
    for i, vec in ipairs( SURGE_SAFE_PLACES ) do
        self.blips[ i ] = exports.escape:xrCreateBlip( "ui_common", "ui_pda2_sq_sos", 50, vec[ 1 ], vec[ 2 ], vec[ 3 ] )
    end

    self.state = true
end

function xrSurge:stop()
    if not self.state then
        return
    end

    if self.blowoutSndRumble then
        destroyElement( self.blowoutSndRumble )
        self.blowoutSndRumble = nil
    end

    self.blowoutSndPhase = false
    self.effectPhase = false
    self.secondMessagePhase = false

    --setCameraShakeLevel( 1 )
    --setCameraShakeLevel( 0 )    

    xrEnvironment.setWeatherEffect( false )

    for _, blip in ipairs( self.blips ) do
        destroyElement( blip )
    end
    self.blips = nil

    self.state = false
end

function xrSurge:onFinish()
    if self.state then
        playSound( "sounds/blowout_begin.ogg" )
        playSound( "sounds/zat_a2_stalker_barmen_after_surge.ogg" )

        exports.sp_hud_real_new:xrPrintNews( 
            "Произошел очередной выброс. Аномалии должны породить новые артефакты.", 
            "ui_inGame2_V_zone_nedavno_proshel_vibros" 
        )
    end
end

function xrSurge:onBolt( bolts )
    if not self.state then
        return
    end

    local randBolt = bolts[ math.random( 1, #bolts ) ]

    playSound( "sounds/" .. randBolt.sound .. ".ogg" )
end

function xrSurge:update( timeSlice )
    if not self.state then
        return
    end

    local elapsed = xrEnvironment.timeDiff( xrSurge.startTime, xrEnvironment.gameTime )
    if elapsed >= SURGE_DURATION_SECS then
        xrSurge:stop()
        xrSurge:onFinish()
    else
        if self.blowoutSndRumble then
            local rumbleLevel = elapsed / (SURGE_DURATION_SECS/4)
            setSoundVolume( self.blowoutSndRumble, rumbleLevel )
        end

        if elapsed >= 35*60 and not self.blowoutSndPhase then
            --setCameraShakeLevel( 180 )

            playSound( "sounds/blowout_begin.ogg" )
            self.blowoutSndRumble = playSound( "sounds/blowout_rumble.ogg", true )

            self.blowoutSndPhase = true
        elseif elapsed >= 100 and not self.effectPhase then      

            self.effectPhase = true
        elseif elapsed >= 30*60 and not self.secondMessagePhase then
            playSound( "sounds/zat_a2_stalker_barmen_surge_phase_2.ogg" )

            exports.sp_hud_real_new:xrPrintNews( 
                "Выброс совсем скоро начнется. Немедленно найдите укрытие, оно помечено на карте восклицательным знаком", 
                "ui_inGame2_V_zone_nedavno_proshel_vibros" 
            )

            self.secondMessagePhase = true
        end
    end
end

local function onSurgeStarted( timeElapsed )
    xrSurge:start( timeElapsed )
end

local function onSurgeFinished()
    xrSurge:onFinish()
end

local function onSurgePlayerLeaveLevel()
    xrSurge:stop()
end

local function onSurgePlayerGamodeLeave()
    xrSurge:stop()
end

function xrInitSurge()
    addEvent( EClientEvents.onClientThunderboltStarted, true )
    addEventHandler( EClientEvents.onClientThunderboltStarted, root, onSurgeStarted )
    addEvent( EClientEvents.onClientThunderboltFinished, true )
	addEventHandler( EClientEvents.onClientThunderboltFinished, root, onSurgeFinished )
    addEvent( EClientEvents.onClientPlayerLeaveLevel, true )
    addEventHandler( EClientEvents.onClientPlayerLeaveLevel, localPlayer, onSurgePlayerLeaveLevel )
    addEvent( EClientEvents.onClientPlayerGamodeLeave, true )
	addEventHandler( EClientEvents.onClientPlayerGamodeLeave, localPlayer, onSurgePlayerGamodeLeave )
end
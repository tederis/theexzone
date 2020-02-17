local bulletHitSounds = {
    "sounds/actor/bullet_hit_1.ogg",
    "sounds/actor/bullet_hit_2.ogg",
    "sounds/actor/bullet_hit_3.ogg",
    "sounds/actor/bullet_hit_4.ogg",
}
local bulletHitPainSounds = {
    "sounds/actor/bullet_hit_pain_1.ogg",
    "sounds/actor/bullet_hit_pain_2.ogg",
    "sounds/actor/bullet_hit_pain_3.ogg",
}
local deadSounds = {
    "sounds/actor/die0.ogg",
    "sounds/actor/die1.ogg",
    "sounds/actor/die2.ogg",
    "sounds/actor/die3.ogg",
}
local breathSound = "sounds/actor/breath_1.ogg"
local breathDuration = 5000

local function onPlayerDamage( attacker, weapon, bodypart, loss )
    if source == localPlayer then
        if not g_PlayerAffector.wasted then
            cancelEvent()
        end
        
        if math.random() > 0.8 then
            local randName = bulletHitSounds[ math.random( 1, #bulletHitPainSounds ) ]
            playSound( randName )
        else
            local randName = bulletHitSounds[ math.random( 1, #bulletHitSounds ) ]
            playSound( randName )
        end
    end    
end

local function onPlayerWasted( killer, weapon, bodypart, loss )
    local randName = deadSounds[ math.random( 1, #deadSounds ) ]
    playSound3D( randName, source.position )
end

local function onPlayerStep( leftFoot )
    --[[
        Считаем величину аффекта в зависимости от массы рюкзака игрока
    ]]
    local power = getPedControlState( localPlayer, "sprint" ) and 0.25 or 0.15
    local weight = exports.xritems:xrGetContainerWeight( localPlayer ) or 0
    local overweight = math.max( weight - PLAYER_OVERWEIGHT_START, 0 )
    local progress = math.min( overweight / MAX_PLAYER_WEIGHT, 1 )
    local value = math.interpolate( power, power * 2, progress )

    triggerEvent( EClientEvents.onClientPlayerHit, localPlayer, PTH_POWER, value, 3, false )
end

local lastPowerState = true
local lastPowerSwitchTime = getTickCount()

local function onUpdate()    
    if not g_PlayerAffector then
        return
    end

    local now = getTickCount()    


    --[[
        Обновляем состояние сил
    ]]
    local newPowerState = g_PlayerAffector.power > 0.3
    if newPowerState ~= lastPowerState and now - lastPowerSwitchTime > breathDuration then
        --[[
            Ждем пока наберется некоторое количество сил
        ]]
        if lastPowerState ~= true and g_PlayerAffector.power < 0.6 then
            return
        end

        toggleControl( "sprint", newPowerState )
        toggleControl( "jump", newPowerState )

        if not newPowerState then
            playSound( breathSound )
        end

        lastPowerState = newPowerState
        lastPowerSwitchTime = now
    end
end

local function onPowerConsumingAction()
    --[[
        Считаем величину аффекта в зависимости от массы рюкзака игрока
    ]]
    local power = 0.7
    local weight = exports.xritems:xrGetContainerWeight( localPlayer ) or 0
    local overweight = math.max( weight - PLAYER_OVERWEIGHT_START, 0 )
    local progress = math.min( overweight / MAX_PLAYER_WEIGHT, 1 )
    local value = math.interpolate( power, power * 3, progress )
    
    triggerEvent( EClientEvents.onClientPlayerHit, localPlayer, PTH_POWER, value, 3, false )
end

local _lastLightSwitchTime = getTickCount()
local function onLightSwitch()
    local now = getTickCount()
    if now - _lastLightSwitchTime < 1000 then
        return
    end
    _lastLightSwitchTime = now

    local found = exports.xritems:xrFindContainerItemByType( localPlayer, EHashes.TorchItem, EHashes.SlotBag )
    if found then
        local lightState = getElementData( localPlayer, "lstate", false )
        setElementData( localPlayer, "lstate", not lightState, true )
    else
        setElementData( localPlayer, "lstate", false, true )
    end
end

local function onGamemodeJoin()
    exports.sp_hud_real_new:xrHUDSetEnabled( true )
end

local function onGamemodeLeave()
    destroyAffectors()

    g_PlayerAffector = nil

    removeEventHandler( "onClientPlayerDamage", root, onPlayerDamage )
    removeEventHandler( "onClientPlayerWasted", root, onPlayerWasted )
    removeEventHandler( "onClientPedStep", localPlayer, onPlayerStep )

    unbindKey( "l", "down", onLightSwitch )

    killTimer( g_UpdateTimer )

    exports.sp_hud_real_new:xrHUDSetEnabled( false )
end

addEvent( "onClientSpawned", true )
local function onClientSpawned()
    addEventHandler( "onClientPlayerDamage", root, onPlayerDamage )
    addEventHandler( "onClientPlayerWasted", root, onPlayerWasted )
    addEventHandler( "onClientPedStep", localPlayer, onPlayerStep, false )

    initAffectors()

    PlayerAffector_create( _hashFn( "actor_condition" ) )

    bindKey( "l", "down", onLightSwitch )

    toggleControl( "sprint", true )
    toggleControl( "jump", true )

    --setCameraShakeLevel( 1 )
    --setCameraShakeLevel( 0 )

    g_UpdateTimer = setTimer( onUpdate, 100, 0 )
end

local function onPlayerDead()
    if g_PlayerAffector then
        g_PlayerAffector.health = 0
        g_PlayerAffector.wasted = true
    end
end

local function _setupFakeAnim( ped )
    setPedAnimation( ped, "ped", "KO_shot_front", -1, false, false, false, true, 0 )
end
local function onPedFakeDead( player )
    local rx, ry, rz = getElementRotation( player )
    local x, y, z = getElementPosition( player )
    setElementRotation( source, rx, ry, rz )
    setElementPosition( source, x, y, z )

    setTimer( _setupFakeAnim, 50, 1, source )

    exports.sp_interact:xrInteractInsertElement( source )
end

addEventHandler( "onClientCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

        if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
        end

        if not xrSettingsInclude( "creatures/actor.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
        end

        if not xrSettingsInclude( "teams.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации команд!", 2 )
            return
        end        

        addEvent( EClientEvents.onClientPlayerGamodeJoin, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeJoin, localPlayer, onGamemodeJoin, false )
        addEvent( EClientEvents.onClientPlayerGamodeLeave, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeLeave, localPlayer, onGamemodeLeave, false )          
        addEventHandler( "onClientSpawned", localPlayer, onClientSpawned, false )      
        addEvent( EClientEvents.onClientPlayerDead, true )  
        addEventHandler( EClientEvents.onClientPlayerDead, localPlayer, onPlayerDead, false )
        addEvent( EClientEvents.onClientPedFakeDead, true )
        addEventHandler( EClientEvents.onClientPedFakeDead, root, onPedFakeDead )

        addEventHandler( "onClientElementStreamIn", resourceRoot,
            function()
                if getElementData( source, "fake" ) then
                    setPedAnimation( source, "ped", "KO_shot_front", -1, false, false, false, true, 0 )
                    setPedAnimationProgress( source, "KO_shot_front", 1 )
                end
            end
        )

        for _, ped in ipairs( getElementsByType( "ped" ) ) do
            if getElementData( ped, "fake" ) then
                setPedAnimation( ped, "ped", "KO_shot_front", -1, false, false, false, true, 0 )
                setPedAnimationProgress( ped, "KO_shot_front", 1 )
            end
        end    

        bindKey( "jump", "down", onPowerConsumingAction )
    end
)
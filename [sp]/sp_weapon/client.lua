local HIT_MULTIPLIER = 0.53763440860215053763440860215054

local modelsToReplace = {
    { model = 6200, filename = "abakan/ak47" },
    { model = 6201, filename = "ak-74c/ak74s" },
    { model = 6202, filename = "ak74u/aks74u" },
    { model = 6203, filename = "beretta/beretta" },
    { model = 6204, filename = "colt1911/colt1911" },
    { model = 6205, filename = "deagle/deagle" },
    { model = 6206, filename = "fn2000-wrk/wpn_fn2000" },
    { model = 6207, filename = "fort/wpn_fort" },
    { model = 6208, filename = "mp5/mp5" },
    { model = 6209, filename = "obrez/obrez" },
    { model = 6210, filename = "wpm_l85/wpn_l85" },
    { model = 6211, filename = "wpn_g36/wpn_g36" },
    { model = 6212, filename = "wpn_gauss/wpn_gauss" },
    { model = 6213, filename = "wpn_groza/wpn_groza" },
    { model = 6214, filename = "wpn_hpsa/wpn_hpsa" },
    { model = 6215, filename = "wpn_lr300/wpn_lr300" },
    { model = 6216, filename = "wpn_pb/wpn_pb" },
    { model = 6217, filename = "wpn_pkm/wpn_pkm" },
    { model = 6218, filename = "wpn_pm/wpn_pm" },
    { model = 6219, filename = "wpn_bolt/wpn_bolt" }
}
local modelsLookup = {}
for _, data in ipairs( modelsToReplace ) do
    modelsLookup[ data.model ] = true
end

local gtaWpnModels = {
    346, 347, 348,
    349, 350, 351,
    352, 353, 372,
    355, 356, 357, 358,
    342
}

local wpnUpgradeMasks = {
    "*_glush",
    "*_podstvol",
    "*_pricel"
}

local randomHitSounds = {
    "sounds/bullet/collide/concrete01gr.ogg",
    "sounds/bullet/collide/default01gr.ogg",
    "sounds/bullet/collide/default02gr.ogg",
    "sounds/bullet/collide/dirt01gr.ogg",
    "sounds/bullet/collide/dirt02gr.ogg",
    "sounds/bullet/collide/glass01hl.ogg",
    "sounds/bullet/collide/metall01gr.ogg",
    "sounds/bullet/collide/metall02gr.ogg",
    "sounds/bullet/collide/metall05gr.ogg",
    "sounds/bullet/collide/sand01gr.ogg",
    "sounds/bullet/collide/sand03gr.ogg",
    "sounds/bullet/collide/tree01gr.ogg",
    "sounds/bullet/collide/water01gr.ogg",
    "sounds/bullet/collide/wood01gr.ogg",
    "sounds/bullet/collide/wood02gr.ogg",
}

local playerAttachedWpns = {}

local _weaponShader = nil

local _ammoInClip = 0
local _totalAmmo = 0
local _condition = 0
local _misfire = false
local _fireLocked = false
local _firePermission = true

local function setAmmoData( ammoInClip, totalAmmo, condition )
    _ammoInClip = ammoInClip
    _totalAmmo = totalAmmo
    _condition = condition

    --[[
        Задание данных для рендера HUD
    ]]
    setElementData( localPlayer, "_waic", _ammoInClip, false )
    setElementData( localPlayer, "_wta", _totalAmmo, false )
end

local function playWeaponSoundAt( data, x, y, z )
    if type( data ) == "string" then
        playSound3D( "sounds/" .. data .. ".ogg", x, y, z )
    elseif type( data ) == "table" then
        local sound = playSound3D( "sounds/" .. data[ 1 ] .. ".ogg", x, y, z )
        setSoundSpeed( sound, tonumber( data[ 2 ] ) or 1 )
    end
end

local function onPlayerDamage( attacker, weapon, bodypart, loss )
    local itemHash = getElementData( attacker, "wpn", false )
    if not itemHash then
        outputDebugString( "У нападающего нет оружия", 2 )
        return   
    end

    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection or itemSection.class ~= EHashes.WeaponItem then
        outputDebugString( "У нападающего нет подходящего оружия", 2 )
        return
    end

    if source == localPlayer then
        local hitPower = tonumber( itemSection.hit_power ) or 0
        local influence = hitPower * HIT_MULTIPLIER
        
        -- Хэдшот
        if bodypart == 9 then
            influence = influence * 6
        end        

        triggerEvent( EClientEvents.onClientPlayerHit, localPlayer, PHT_STRIKE, influence, bodypart, attacker )
    end    
end

local function onPlayerWeaponFire( weapon, ammo, ammoInClip, hitX, hitY, hitZ, hitElement, startX, startY, startZ )
    local itemHash = getElementData( source, "wpn", false )
    if not itemHash then
        return   
    end

    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection or itemSection.class ~= EHashes.WeaponItem then
        return
    end
    
    local muzzleX, muzzleY, muzzleZ = getPedWeaponMuzzlePosition( source )
    playWeaponSoundAt( itemSection.snd_shoot, muzzleX, muzzleY, muzzleZ )

    if hitElement and hitElement.type == "object" and math.random() < 0.6 then
        local randSndName = randomHitSounds[ math.random( 1, #randomHitSounds ) ]
        playSound3D( randSndName, hitX, hitY, hitZ )
    end

    if source == localPlayer and not _fireLocked then
        local wpnId = getElementData( localPlayer, "wpnId", false )

        _ammoInClip = math.max( _ammoInClip - 1, 0 )
        if _ammoInClip == 0 and not _fireLocked then
            setPedControlState( localPlayer, "fire", false )
            toggleControl( "fire", false )
            toggleControl( "action", false )
            _fireLocked = true
        end        

        -- Обновляем кол-во патронов на предмете в инвентаре
        exports.xritems:xrSetContainerItemData( localPlayer, wpnId, EIA_AMMO, _ammoInClip )

        -- Параллельно с сервером применяем износ
        _condition = math.max( _condition - itemSection.condition_shot_dec, 0 )

        -- Обновляем состояние на предмете в инвентаре        
        exports.xritems:xrSetContainerItemData( localPlayer, wpnId, EIA_CONDITION, _condition )

        -- Обновляем вспомогательное поле для иконок HUD
        local misfireValue = math.clamp( 0, 1,
            ( itemSection.misfire_start_condition - _condition ) / ( itemSection.misfire_start_condition - itemSection.misfire_end_condition )
        )
        setElementData( localPlayer, "_wcn", misfireValue, false )

        setAmmoData( _ammoInClip, _totalAmmo, _condition )
    end
end

function onWeaponMisfire()
    _misfire = true
    _fireLocked = true

    setPedControlState( localPlayer, "fire", false )
    toggleControl( "fire", false )
    toggleControl( "action", false )

    outputChatBox( "Ваше оружие заклинило" )
end

local function onPlayerReload( ammoInClip, totalAmmo )
    local itemHash = getElementData( source, "wpn", false )
    if not itemHash then
        return   
    end    

    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection or itemSection.class ~= EHashes.WeaponItem then
        return
    end

    if source == localPlayer then
        _misfire = false
        _fireLocked = ammoInClip < 1 or _condition <= 0.0001

        local wpnId = getElementData( localPlayer, "wpnId", false )

        -- Обновляем кол-во патронов на предмете в инвентаре
        exports.xritems:xrSetContainerItemData( localPlayer, wpnId, EIA_AMMO, ammoInClip )        

        setPedControlState( localPlayer, "fire", false )
        toggleControl( "fire", _firePermission and not _fireLocked )   
        toggleControl( "action", _firePermission and not _fireLocked )
        
        setAmmoData( ammoInClip, totalAmmo, _condition )
    end

    if isElementStreamedIn( source ) then
        local posX, posY, posZ = getElementPosition( source )
        playWeaponSoundAt( itemSection.snd_reload, posX, posY, posZ )
    end
end

local function onWeaponSelect( ammoInClip, totalAmmo, condition ) 
    --[[
        Сперва уничтожим объект, который мы ранее прикрепили к кости
    ]] 
    local attachData = playerAttachedWpns[ source ]
    if attachData then
        exports[ "bone_attach" ]:detachElementFromBone( attachData.object )
        engineRemoveShaderFromWorldTexture( _weaponShader, "*", attachData.object )
        for _, maskStr in ipairs( wpnUpgradeMasks ) do
            engineRemoveShaderFromWorldTexture( _weaponShader, maskStr, object )
            engineRemoveShaderFromWorldTexture( _weaponUpgradeShader, maskStr, object )
        end
        destroyElement( attachData.object )

        playerAttachedWpns[ source ] = nil
    end

    local itemHash = getElementData( source, "wpn", false )
    local itemSection = xrSettingsGetSection( itemHash )
    
    if source == localPlayer then
        _misfire = false
        if ammoInClip then
            _fireLocked = ammoInClip < 1 or condition <= 0.0001
        else
            _fireLocked = true
        end

        setPedControlState( localPlayer, "fire", false )

        if itemSection then 
            if itemSection.class == EHashes.WeaponItem then
                local misfireValue = math.clamp( 0, 1,
                    ( itemSection.misfire_start_condition - condition ) / ( itemSection.misfire_start_condition - itemSection.misfire_end_condition )
                )
                setElementData( localPlayer, "_wcn", misfireValue, false )
            elseif itemSection.class == EHashes.GrenadeItem then
                setElementData( localPlayer, "_wcn", 0, false )
            end
            toggleControl( "fire", _firePermission and not _fireLocked )
            toggleControl( "action", _firePermission and not _fireLocked )
            setAmmoData( ammoInClip, totalAmmo, condition )
        else
            setElementData( localPlayer, "_wcn", 0, false )
            toggleControl( "fire", _firePermission and not _fireLocked )
            toggleControl( "action", _firePermission and not _fireLocked )
            setAmmoData( 0, 0, 0 )
        end       
    end

    if itemSection and itemSection.gta_model and modelsLookup[ itemSection.gta_model ] then
        local x, y, z = getElementPosition( source )
        local object = createObject( itemSection.gta_model, x, y, z )
        local offset = itemSection.gta_offset or Vector3( 0, 0, 0 )
        local rot = itemSection.gta_rot or Vector3( 0, -90, 0 )

        engineApplyShaderToWorldTexture( _weaponShader, "*", object, false )
        for _, maskStr in ipairs( wpnUpgradeMasks ) do
            engineRemoveShaderFromWorldTexture( _weaponShader, maskStr, object )
            engineApplyShaderToWorldTexture( _weaponUpgradeShader, maskStr, object, false )
        end

        exports[ "bone_attach" ]:attachElementToBone( object, source, itemSection.gta_bone, offset:getX(), offset:getY(), offset:getZ(), rot:getX(), rot:getY(), rot:getZ() )

        playerAttachedWpns[ source ] = {
            object = object
        }
    end
end

local function onPlayerEmptyFire()
    if not isElementStreamedIn( source ) then
        return
    end

    local itemHash = getElementData( source, "wpn", false )
    if not itemHash then
        return
    end    

    local itemSection = xrSettingsGetSection( itemHash )
    if itemSection then
        local posX, posY, posZ = getElementPosition( source )
        playWeaponSoundAt( itemSection.snd_empty, posX, posY, posZ )
    end
end

local function onProjectileCreation( creator )
    if creator ~= localPlayer or getProjectileType( source ) ~= 16 then
        return
    end

    local itemHash = getElementData( creator, "wpn", false )
    if not itemHash then
        return
    end    

    local itemSection = xrSettingsGetSection( itemHash )
    if itemSection and itemSection.class == EHashes.GrenadeItem then
        local wpnId = getElementData( creator, "wpnId", false )
        _ammoInClip = math.max( _ammoInClip - 1, 0 )
        setAmmoData( _ammoInClip, _ammoInClip, _condition )

        triggerServerEvent( EServerEvents.onPlayerBoltThrow, localPlayer )
    end
end

local blockedTasks =
{
	"TASK_SIMPLE_IN_AIR", -- We're falling or in a jump.
	"TASK_SIMPLE_JUMP", -- We're beginning a jump
	"TASK_SIMPLE_LAND", -- We're landing from a jump
	"TASK_SIMPLE_GO_TO_POINT", -- In MTA, this is the player probably walking to a car to enter it
	"TASK_SIMPLE_NAMED_ANIM", -- We're performing a setPedAnimation
	"TASK_SIMPLE_CAR_OPEN_DOOR_FROM_OUTSIDE", -- Opening a car door
	"TASK_SIMPLE_CAR_GET_IN", -- Entering a car
	"TASK_SIMPLE_CLIMB", -- We're climbing or holding on to something
	"TASK_SIMPLE_SWIM",
	"TASK_SIMPLE_HIT_HEAD", -- When we try to jump but something hits us on the head
	"TASK_SIMPLE_FALL", -- We fell
	"TASK_SIMPLE_GET_UP" -- We're getting up from a fall
}

local function reloadWeapon()
    local itemHash = getElementData( localPlayer, "wpn", false )
    if not itemHash then
        return
    end    

    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection or itemSection.class ~= EHashes.WeaponItem then
        return
    end

	local task = getPedSimplestTask( localPlayer )
	for idx, badTask in ipairs( blockedTasks ) do
		if task == badTask then
			return
		end
    end
    
    for _, keyName in ipairs( getBoundKeys( "fire" ) ) do
        if getKeyState( keyName ) then
            return
        end
    end

	triggerServerEvent( EServerEvents.onReloadWeap, localPlayer )
end

local _lastReloadTime = getTickCount()
local function onReloadKey()
    local now = getTickCount()
    if now - _lastReloadTime < 2000 then
        return
    end
    _lastReloadTime = now

    setTimer( reloadWeapon, 50, 1 )
end

local function onGamemodeJoin()
    if source == localPlayer then
        setAmmoData( 0, 0, 0 )
        setElementData( localPlayer, "_wcn", 0, false )
        setElementData( localPlayer, "_waic", 0, false )
        setElementData( localPlayer, "_wta", 0, false )
        toggleControl( "fire", _firePermission and not _fireLocked )
        toggleControl( "action", _firePermission and not _fireLocked )
    end
end

local function onGamemodeLeave()
    local attachData = playerAttachedWpns[ source ]
    if attachData then
        exports[ "bone_attach" ]:detachElementFromBone( attachData.object )
        engineRemoveShaderFromWorldTexture( _weaponShader, "*", attachData.object )
        destroyElement( attachData.object )

        playerAttachedWpns[ source ] = nil
    end
end

function replaceModels()
    for _, data in ipairs( modelsToReplace ) do
        local txd = engineLoadTXD( "models/" .. data.filename .. ".txd" )
        engineImportTXD( txd, data.model )

        local dff = engineLoadDFF( "models/" .. data.filename .. ".dff" )
        engineReplaceModel( dff, data.model )

        local col = engineLoadCOL( "models/" .. data.filename .. ".col" )
        engineReplaceCOL( col, data.model )
    end

    local removeShader = dxCreateShader( "shaders/removewpn.fx", 10, 0, false, "all" )

    for _, model in ipairs( gtaWpnModels ) do
        for _, texName in ipairs( engineGetModelTextureNames( model ) or EMPTY_TABLE ) do
            engineApplyShaderToWorldTexture( removeShader, texName )
        end
    end
end

--[[
    Exports
]]
function xrToggleFire( toggle )
    if not _fireLocked then
        toggleControl( "fire", toggle )
        toggleControl( "action", toggle )
    end
    _firePermission = toggle
end

--[[
    Init
]]
addEvent( "onClientCoreStarted", false )
addEventHandler( "onClientCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

        if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации!", 2 )
            return
        end

        addEvent( EClientEvents.onClientPlayerGamodeJoin, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeJoin, root, onGamemodeJoin )
        addEvent( EClientEvents.onClientPlayerGamodeLeave, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeLeave, root, onGamemodeLeave )
        addEvent( EClientEvents.onClientMisfire, true )
        addEventHandler( EClientEvents.onClientMisfire, localPlayer, onWeaponMisfire, false )
        addEventHandler( "onClientPlayerWeaponFire", root, onPlayerWeaponFire )
        addEventHandler( "onClientPlayerDamage", root, onPlayerDamage )
        addEvent( EClientEvents.onClientPlayerReload, true )
        addEventHandler( EClientEvents.onClientPlayerReload, root, onPlayerReload )
        addEvent( EClientEvents.onClientWeaponSelect, true )
        addEventHandler( EClientEvents.onClientWeaponSelect, root, onWeaponSelect )
        addEvent( EClientEvents.onPlayerEmptyFire, true )
        addEventHandler( EClientEvents.onPlayerEmptyFire, root, onPlayerEmptyFire )
        addEventHandler( "onClientProjectileCreation", root, onProjectileCreation )

        bindKey( "r", "down", onReloadKey )

        _weaponShader = dxCreateShader( "shaders/weapon.fx", 10, 100, false, "object" )
        _weaponUpgradeShader = dxCreateShader( "shaders/removewpn.fx", 10, 100, false, "object" )
        exports.escape:xrLightInsertShader( _weaponShader )

        replaceModels()
    end
)
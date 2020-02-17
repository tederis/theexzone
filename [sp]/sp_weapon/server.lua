local xrPlayerWeapons = {
    -- [player] = { [31] = itemId, [16] = itemId, ... }
}
setmetatable( xrPlayerWeapons, {
    __index = function( tbl, key )
        local value = {
            
        }
        rawset( tbl, key, value )
        return value
    end    
} )

local function findWeaponSuitableAmmo( player, item )
    local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
    if not itemSection then
        outputDebugString( "Оружие не имеет секции!", 2 )
        return false
    end

    -- Получаем массив допустимых типов боеприпасов
    local ammoTypes = itemSection.ammo_class
    if type( ammoTypes ) ~= "table" then
        ammoTypes = { ammoTypes }
    end
    
    -- Производим поиск боеприпасов и их назначение
    local totalCount = 0
    local ammoItemHash
    for _, ammoType in ipairs( ammoTypes ) do
        ammoItemHash = _hashFn( ammoType ) 
        totalCount = totalCount + exports.xritems:xrCountContainerItemByType( player, ammoItemHash, EHashes.SlotBag )
    end

    return ammoItemHash, totalCount
end

function xrGivePlayerWeapon( player, item, selectWpn )
    local playerWpn = xrPlayerWeapons[ player ]

    local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
    if itemSection then
        if playerWpn[ itemSection.slot ] then
            outputDebugString( "Этот оружейный слот уже занят", 2 )
            return
        end
        
        playerWpn[ itemSection.slot ] = item[ EIA_ID ]

        if selectWpn then
            xrSelectPlayerWeapon( player, item )
        end
    end
end

function xrTakePlayerWeapon( player, item )
    local playerWpn = xrPlayerWeapons[ player ]

    local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
    if itemSection then
        if not playerWpn[ itemSection.slot ] then
            outputDebugString( "Этот оружейный слот уже пуст", 2 )
            return
        end
    
        playerWpn[ itemSection.slot ] = nil

        if playerWpn.currentId == item[ EIA_ID ] then
            xrSelectPlayerWeapon( player, false )
        end
    end    
end

function xrReloadPlayerWeapon( player )
    local playerWpn = xrPlayerWeapons[ player ]

    local weaponItemId = playerWpn.currentId
    if not weaponItemId then
        outputDebugString( "У игрока нет оружия", 2 )
        return false
    end

    local item = exports.xritems:xrGetContainerItem( player, weaponItemId )
    if not item then
        outputDebugString( "Предмет оружия не был найден в инвентаре", 2 )
        return false
    end  

    local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
    if not itemSection or itemSection.class ~= EHashes.WeaponItem then
        return false
    end

    local totalCount = 0
    local magazineSize = itemSection.ammo_mag_size
    local currentNum = playerWpn.ammoInClip
    local ammoDelta = magazineSize - currentNum

    -- Получаем список подходящих патронов в форме таблицы
    local ammoTypes = itemSection.ammo_class
    if type( ammoTypes ) ~= "table" then
        ammoTypes = { ammoTypes }
    end

    local ammoItemHash
    for _, ammoType in ipairs( ammoTypes ) do
        ammoItemHash = _hashFn( ammoType )       

        local extractedNum = exports.xritems:xrDecimateContainerItemsByType( player, ammoItemHash, ammoDelta, EHashes.SlotBag )
        ammoDelta = ammoDelta - extractedNum
        currentNum = currentNum + extractedNum

        totalCount = totalCount + exports.xritems:xrCountContainerItemByType( player, ammoItemHash, EHashes.SlotBag )
    end

    if setWeaponAmmo( player, itemSection.gta_id, 9999, 1000 ) and reloadPedWeapon( player ) then
        playerWpn.ammoInClip = currentNum
        playerWpn.totalAmmo = totalCount
        playerWpn.misfire = false

        -- Обновляем инвентарный предмет
        exports.xritems:xrSetContainerItemData( player, weaponItemId, EIA_AMMO, currentNum, false )

        setElementData( player, "ammo", ammoItemHash )

        triggerClientEvent( EClientEvents.onClientPlayerReload, player, currentNum, totalCount )
    end
end

function xrSelectPlayerWeapon( player, item )
    local playerWpn = xrPlayerWeapons[ player ]

    if type( item ) ~= "table" then

        takeAllWeapons( player )

        removeElementData( player, "ammo" )
        removeElementData( player, "wpn" )
        removeElementData( player, "wpnId" )

        playerWpn.currentId = nil
        playerWpn.currentSlot = nil
        playerWpn.section = nil
        playerWpn.ammoInClip = nil
        playerWpn.totalAmmo = nil
        playerWpn.condition = nil
        playerWpn.misfire = nil
    
        triggerClientEvent( EClientEvents.onClientWeaponSelect, player, false )    

        return true
    end

    local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
    if not itemSection then
        outputDebugString( "Оружие не имеет секции!", 2 )
        return false
    end

    if not playerWpn[ itemSection.slot ] then
        outputDebugString( "Слот игрока не заполнен этим оружием!", 2 )
        return false
    end

    local itemClass = itemSection.class
    if itemClass == EHashes.WeaponItem then
        local ammoItemHash, totalCount = findWeaponSuitableAmmo( player, item )
        local currentNum = tonumber( item[ EIA_AMMO ] ) or 0                      

        onPlayerWeaponSelect( player, item, ammoItemHash, currentNum, totalCount )

        return true
    elseif itemClass == EHashes.GrenadeItem then
        local totalCount = 0
        local currentNum = 0

        local ammoItemHash = itemSection.ammo_class
        if ammoItemHash then
            totalCount = exports.xritems:xrCountContainerItemByType( player, ammoItemHash, EHashes.SlotGrenade )
            currentNum = totalCount
        end

        onPlayerWeaponSelect( player, item, ammoItemHash, currentNum, totalCount )

        return true
    end

    return false
end

local function onPlayerWeaponFire( weapon, endX, endY, endZ, hitElement, startX, startY, startZ )
    local playerWpn = xrPlayerWeapons[ source ] 
    
    local wpnCondition = playerWpn.condition
    local wpnAmmoInClip = playerWpn.ammoInClip
    local wpnSection = playerWpn.section
    local weaponItemId = playerWpn.currentId
    
    if weaponItemId and wpnAmmoInClip > 0 and wpnSection.class == EHashes.WeaponItem then
        playerWpn.ammoInClip = wpnAmmoInClip - 1

        exports.xritems:xrSetContainerItemData( source, weaponItemId, EIA_AMMO, playerWpn.ammoInClip, false )

        playerWpn.condition = math.max( wpnCondition - wpnSection.condition_shot_dec, 0 )
        exports.xritems:xrSetContainerItemData( source, weaponItemId, EIA_CONDITION, playerWpn.condition, false )

        -- Считаем вероятность осечки
        local misfireValue = math.clamp( 0, 1,
            ( wpnSection.misfire_start_condition - playerWpn.condition ) / ( wpnSection.misfire_start_condition - wpnSection.misfire_end_condition )
        )
        if misfireValue > 0.001 then
            local misfireProb = math.interpolate( wpnSection.misfire_start_prob, wpnSection.misfire_end_prob, misfireValue )
            if math.random() <= misfireProb then
                playerWpn.misfire = true
                triggerClientEvent( source, EClientEvents.onClientMisfire, source )
            end
        end
    end
end

function onPlayerWeaponSelect( player, item, ammoItemHash, currentNum, totalCount )
    local playerWpn = xrPlayerWeapons[ player ]

    local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
    if not itemSection then
        outputDebugString( "Оружие не имеет секции!", 2 )
        return false
    end

    playerWpn.section = itemSection
    playerWpn.currentId = item[ EIA_ID ]
    playerWpn.currentSlot = itemSection.slot
    playerWpn.ammoInClip = currentNum
    playerWpn.totalAmmo = totalCount  
    playerWpn.condition = tonumber( item[ EIA_CONDITION ] ) or 1        
    playerWpn.misfire = false

    setElementData( player, "ammo", ammoItemHash )
    setElementData( player, "wpn", item[ EIA_TYPE ] )
    setElementData( player, "wpnId", item[ EIA_ID ] )  

    giveWeapon( player, itemSection.gta_id, 9999, true )
 
    triggerClientEvent( EClientEvents.onClientWeaponSelect, player, currentNum, totalCount, playerWpn.condition )
end

local function onPlayerReloadCmd()
    local now = getTickCount()
    local playerWpn = xrPlayerWeapons[ source ]
    if not playerWpn.currentId or playerWpn.section.class ~= EHashes.WeaponItem then
        return
    end

    if not playerWpn.lastReloadTime or now - playerWpn.lastReloadTime > 2500 then
        xrReloadPlayerWeapon( source )
        playerWpn.lastReloadTime = now
    end
end

local function onPlayerTryFire( player )
    local playerWpn = xrPlayerWeapons[ player ]
    if not playerWpn.currentId or playerWpn.section.class ~= EHashes.WeaponItem then
        return
    end

    if playerWpn.ammoInClip < 1 or playerWpn.condition < 0.001 or playerWpn.misfire then
        triggerClientEvent( EClientEvents.onPlayerEmptyFire, player )
    end
end

local function onPlayerWeaponKey( player, key )
    local playerWpn = xrPlayerWeapons[ player ]

    -- Если игрок находится в инвентаре или диалоге
    if getElementData( player, "uib", false ) then
        return
    end

    local slotHash = EWeaponSlots[ tonumber( key ) ]
    local weaponItemId = playerWpn[ slotHash ]
    if not weaponItemId or playerWpn.currentSlot == slotHash then
        xrSelectPlayerWeapon( player, false )
        return
    end

    local item = exports[ "xritems" ]:xrGetContainerItem( player, weaponItemId )
    if item then
        xrSelectPlayerWeapon( player, item )
    end
end

local function onPlayerWeaponSwitchKey( player, key )
    local playerWpn = xrPlayerWeapons[ player ]

    -- Если игрок находится в инвентаре или диалоге
    if getElementData( player, "uib", false ) then
        return
    end

    local switchValue = key == "mouse_wheel_up" and 1 or -1
    local nextIndex = 0
    if playerWpn.currentSlot then
        nextIndex = EWeaponSlotIndices[ playerWpn.currentSlot ] or 0
    end

    for i = 1, #EWeaponSlots do
        nextIndex = nextIndex + switchValue
        if nextIndex > #EWeaponSlots then
            nextIndex = 0
        elseif nextIndex < 0 then
            nextIndex = #EWeaponSlots
        end 
        
        if nextIndex == 0 then
            xrSelectPlayerWeapon( player, false )
            break
        end

        local slotHash = EWeaponSlots[ nextIndex ]
        local wpnItemId = playerWpn[ slotHash ]
        if wpnItemId then
            local wpnItem = exports[ "xritems" ]:xrGetContainerItem( player, wpnItemId )
            if wpnItem then
                xrSelectPlayerWeapon( player, wpnItem )
                break
            end
        end
    end
end

local function onPlayerBoltThrow()
    local playerWpn = xrPlayerWeapons[ client ]
    if playerWpn and playerWpn.currentId then
        local section = playerWpn.section
        if section.class == EHashes.GrenadeItem then
            exports.xritems:xrDecimateContainerItem( client, playerWpn.currentId, 1, false )
        end
    end
end

local function onPlayerGamodeJoin()		
    removeElementData( source, "ammo" )
    removeElementData( source, "wpn" )

    bindKey( source, "fire", "down", onPlayerTryFire )
    bindKey( source, "mouse_wheel_up", "down", onPlayerWeaponSwitchKey )
    bindKey( source, "mouse_wheel_down", "down", onPlayerWeaponSwitchKey )
    for i = 1, #EWeaponSlots do
        bindKey( source, tostring( i ), "down", onPlayerWeaponKey )
    end

    toggleControl( source, "next_weapon", false )
    toggleControl( source, "previous_weapon", false )
end

local function onPlayerGamodeLeave()
    xrPlayerWeapons[ source ] = nil

    removeElementData( source, "ammo" )
    removeElementData( source, "wpn" )

    unbindKey( source, "fire", "down", onPlayerTryFire )
    unbindKey( source, "mouse_wheel_up", "down", onPlayerWeaponSwitchKey )
    unbindKey( source, "mouse_wheel_down", "down", onPlayerWeaponSwitchKey )
    for i = 1, #EWeaponSlots do
        unbindKey( source, tostring( i ), "down", onPlayerWeaponKey )
    end
end

--[[
    Weapon properties
]]
local weaponIDs = {
    --[ "grenade" ] = true,
    --[ "teargas" ] = true,
    --[ "molotov" ] = true,
    [ "colt 45" ] = true,
    [ "silenced" ] = true,
    [ "deagle" ] = true,
    [ "shotgun" ] = true,
    [ "sawed-off" ] = true,
    [ "combat shotgun" ] = true,
    [ "uzi" ] = true,
    [ "mp5" ] = true,
    [ "ak-47" ] = true,
    [ "m4" ] = true,
    [ "tec-9" ] = true,
    [ "rifle" ] = true,
    [ "sniper" ] = true,
    [ "rocket launcher" ] = true,
    [ "rocket launcher hs" ] = true,
    --[ "flamethrower" ] = true,
    [ "minigun" ] = true,
    --[ "satchel" ] = true,
    --[ "bomb" ] = true,
    --[ "spraycan" ] = true,
    --[ "fire extinguisher" ] = true,
    --[ "camera" ] = true
}
local function xrInitWeapons()
    for name, _ in pairs( weaponIDs ) do
        setWeaponProperty( name, "pro", "maximum_clip_ammo", 1000 )
        setWeaponProperty( name, "std", "maximum_clip_ammo", 1000 )
        setWeaponProperty( name, "poor", "maximum_clip_ammo", 1000 )
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

        if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Конфиги не были прочины надлежащим образом!", 2 )
            return
        end

        xrInitWeapons()

        addEventHandler( "onPlayerWeaponFire", root, onPlayerWeaponFire )
        addEvent( EServerEvents.onReloadWeap, true )
        addEventHandler( EServerEvents.onReloadWeap, root, onPlayerReloadCmd )
        addEvent( EServerEvents.onPlayerBoltThrow, true )
        addEventHandler( EServerEvents.onPlayerBoltThrow, root, onPlayerBoltThrow )
        addEvent( EServerEvents.onPlayerGamodeLeave, false )
        addEventHandler( EServerEvents.onPlayerGamodeLeave, root, onPlayerGamodeLeave )
        addEvent( EServerEvents.onPlayerGamodeJoin, false )
        addEventHandler( EServerEvents.onPlayerGamodeJoin, root, onPlayerGamodeJoin )
    end
)
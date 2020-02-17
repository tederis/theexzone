SERVER_SIDE = type( triggerClientEvent ) == "function"

--[[
    Hash
]]
g_Hashed = {}

function _hashFn( str )
    local result = 0
    for i = 1, string.len( str ) do
        local byte = string.byte( str, i )
        result = byte + bitLShift( result, 6 ) + bitLShift( result, 16 ) - result
    end
    return result
end

local _itemName
local function _createItem( tbl )
    tbl._name = _itemName

    local hash = _hashFn( _itemName )
    g_Hashed[ hash ] = tbl
    _G[ _itemName ] = tbl
end
function Hashed( name )
    _itemName = name
    return _createItem
end

--[[
    Items
]]
Hashed "BaseItem" {
    onCreate = function( body, attrs )
        
    end,

    onDestroy = function( body, attrs )

    end,

    onMove = function( body, section, count )
        return count
    end,

    onUse = function( body, attrs, player )
        if SERVER_SIDE then
            triggerClientEvent( { player }, EClientEvents.onClientItemUse, player, body[ EIA_ID ] )
        end
    end,

    onClientUse = function( body, attrs )
        if attrs.use_sound then
            playSound( "sounds/" .. attrs.use_sound .. ".ogg" )
        end
    end,    

    calcCost = function( body, attrs )
        local count = body[ EIA_COUNT ]
        if attrs.box_size then
            count = count / attrs.box_size
        end

        return math.max( math.floor( attrs.cost * body[ EIA_CONDITION ] * count ), 1 )
    end
}

Hashed "FoodItem" {
    onCreate = function( body, attrs )
        BaseItem.onCreate( body, attrs )
    end,

    onDestroy = function( body, attrs )
        BaseItem.onDestroy( body, attrs )
    end,

    onMove = function( body, section, count )
        return BaseItem.onMove( body, section, count )
    end,

    onUse = function( body, attrs, player )
        BaseItem.onUse( body, attrs, player )

        -- Применяем бустер
        exports.sp_player:PlayerAffector_applyBooster( player, body[ EIA_TYPE ] )

        xrDecimateContainerItem( player, body, 1, false )
    end,

    onClientUse = function( body, attrs )
        BaseItem.onClientUse( body, attrs )
    end,

    calcCost = function( body, attrs )
        local cost = BaseItem.calcCost( body, attrs )
        return cost
    end
}

Hashed "WeaponItem" {
    onCreate = function( body, attrs )
        BaseItem.onCreate( body, attrs )

        body[ EIA_AMMO ] = 0 -- Патронов в патроннике
    end,

    onDestroy = function( body, attrs )
        BaseItem.onDestroy( body, attrs )
    end,

    onMove = function( body, section, count )
        return BaseItem.onMove( body, section, count )
    end,

    onUse = function( body, attrs, player )
        BaseItem.onUse( body, attrs, player )

        if body[ EIA_SLOT ] == attrs.slot then
            xrContainerMoveItem( player, body, player, EHashes.SlotBag, 1 )
        else
            xrContainerMoveItem( player, body, player, attrs.slot, 1 )
        end
    end,

    onClientUse = function( body, attrs )
        BaseItem.onClientUse( body, attrs )
    end,

    calcCost = function( body, attrs )
        local cost = BaseItem.calcCost( body, attrs )
        return cost
    end
}

Hashed "GrenadeItem" {
    onCreate = function( body, attrs )
        BaseItem.onCreate( body, attrs )
    end,

    onDestroy = function( body, attrs )
        BaseItem.onDestroy( body, attrs )
    end,

    onMove = function( body, section, count )
        return BaseItem.onMove( body, section, count )
    end,

    onUse = function( body, attrs, player )
        BaseItem.onUse( body, attrs, player )

        if body[ EIA_SLOT ] == attrs.slot then
            xrContainerMoveItem( player, body, player, EHashes.SlotBag )
        else
            xrContainerMoveItem( player, body, player, attrs.slot )
        end
    end,

    onClientUse = function( body, attrs )
        BaseItem.onClientUse( body, attrs )
    end,

    calcCost = function( body, attrs )
        local cost = BaseItem.calcCost( body, attrs )
        return cost
    end
}

Hashed "KnifeItem" {
    onCreate = function( body, attrs )
        BaseItem.onCreate( body, attrs )
    end,

    onDestroy = function( body, attrs )
        BaseItem.onDestroy( body, attrs )
    end,

    onMove = function( body, section, count )
        return BaseItem.onMove( body, section, count )
    end,

    onUse = function( body, attrs, player )
        BaseItem.onUse( body, attrs, player )

        if body[ EIA_SLOT ] == attrs.slot then
            xrContainerMoveItem( player, body, player, EHashes.SlotBag, 1 )
        else
            xrContainerMoveItem( player, body, player, attrs.slot, 1 )
        end
    end,

    onClientUse = function( body, attrs )
        BaseItem.onClientUse( body, attrs )
    end,

    calcCost = function( body, attrs )
        local cost = BaseItem.calcCost( body, attrs )
        return cost
    end
}

Hashed "AmmoItem" {
    onCreate = function( body, attrs )
        BaseItem.onCreate( body, attrs )        
    end,

    onDestroy = function( body, attrs )
        BaseItem.onDestroy( body, attrs )
    end,

    onMove = function( body, section, count )
        return BaseItem.onMove( body, section, count )
    end,

    onUse = function( body, attrs, player )
        BaseItem.onUse( body, attrs, player )
    end,

    onClientUse = function( body, attrs )
        BaseItem.onClientUse( body, attrs )
    end,

    calcCost = function( body, attrs )
        local cost = BaseItem.calcCost( body, attrs )
        return cost
    end
}

Hashed "ArtefactItem" {
    onCreate = function( body, attrs )
        BaseItem.onCreate( body, attrs )        
    end,

    onDestroy = function( body, attrs )
        BaseItem.onDestroy( body, attrs )
    end,

    onMove = function( body, section, count )
        return BaseItem.onMove( body, section, count )
    end,

    onUse = function( body, attrs, player )
        BaseItem.onUse( body, attrs, player )

        if body[ EIA_SLOT ] == EHashes.SlotBelt then
            xrContainerMoveItem( player, body, player, EHashes.SlotBag, 1 )
        else
            xrContainerMoveItem( player, body, player, EHashes.SlotBelt, 1 )
        end
    end,

    onClientUse = function( body, attrs )
        BaseItem.onClientUse( body, attrs )
    end,

    calcCost = function( body, attrs )
        local cost = BaseItem.calcCost( body, attrs )
        return cost
    end
}

Hashed "DetectorItem" {
    onCreate = function( body, attrs )
        BaseItem.onCreate( body, attrs )        
    end,

    onDestroy = function( body, attrs )
        BaseItem.onDestroy( body, attrs )
    end,

    onMove = function( body, section, count )
        return BaseItem.onMove( body, section, count )
    end,

    onUse = function( body, attrs, player )
        BaseItem.onUse( body, attrs, player )
    end,

    onClientUse = function( body, attrs )
        BaseItem.onClientUse( body, attrs )
    end,

    calcCost = function( body, attrs )
        local cost = BaseItem.calcCost( body, attrs )
        return cost
    end
}

Hashed "QuestItem" {
    onCreate = function( body, attrs )
        BaseItem.onCreate( body, attrs )        
    end,

    onDestroy = function( body, attrs )
        BaseItem.onDestroy( body, attrs )
    end,

    onMove = function( body, section, count )
        return BaseItem.onMove( body, section, count )
    end,

    onUse = function( body, attrs, player )
        BaseItem.onUse( body, attrs, player )
    end,

    onClientUse = function( body, attrs )
        BaseItem.onClientUse( body, attrs )
    end,

    calcCost = function( body, attrs )
        local cost = BaseItem.calcCost( body, attrs )
        return cost
    end
}

Hashed "LightItem" {
    onCreate = function( body, attrs )
        BaseItem.onCreate( body, attrs )        
    end,

    onDestroy = function( body, attrs )
        BaseItem.onDestroy( body, attrs )
    end,

    onMove = function( body, section, count )
        return BaseItem.onMove( body, section, count )
    end,

    onUse = function( body, attrs, player )
        BaseItem.onUse( body, attrs, player )

        if body[ EIA_SLOT ] == EHashes.SlotBelt then
            xrContainerMoveItem( player, body, player, EHashes.SlotBag, 1 )
        else
            xrContainerMoveItem( player, body, player, EHashes.SlotBelt, 1 )
        end
    end,

    onClientUse = function( body, attrs )
        BaseItem.onClientUse( body, attrs )
    end,

    calcCost = function( body, attrs )
        local cost = BaseItem.calcCost( body, attrs )
        return cost
    end
}

--[[
    Containers
]]
Hashed "PlayerContainer" {
    onCreate = function( container )
       --container[ ECA_SLOTS ] = {}
    end
}

Hashed "TraderContainer" {
    onCreate = function( container )
       --container[ ECA_SLOTS ] = {}
    end
}

--[[
    Slots
]]
local _weaponSlotTryPut = function( container, slotHash, itemHash )
    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection then
        return
    end

    if itemSection.slot == slotHash then
        -- Удаляем предыдущий предмет
        xrContainerMoveItems( container, slotHash, container, EHashes.SlotBag )
    end
end
local _weaponSlotTest = function( container, slotHash, itemHash )
    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection or itemSection.slot ~= slotHash then
        return false
    end

    return not xrFindContainerItemBySlot( container, slotHash )
end

Hashed "slot_knife" {
    stackable = true,
    onItemDrag = _weaponSlotTryPut,
    testSlot = _weaponSlotTest,

    onItemPut = function( container, item )
        local owner = container[ ECA_OWNER ]
        if owner then
            exports.sp_weapon:xrGivePlayerWeapon( owner, item )    
        end
    end,
    onItemRemove = function( container, item )
        local owner = container[ ECA_OWNER ]
        if owner then
            exports.sp_weapon:xrTakePlayerWeapon( owner, item )    
        end
    end
}

Hashed "slot_pistol" {
    stackable = true,
    onItemDrag = _weaponSlotTryPut,
    testSlot = _weaponSlotTest,

    onItemPut = function( container, item )
        local owner = container[ ECA_OWNER ]
        if owner then
            exports.sp_weapon:xrGivePlayerWeapon( owner, item )
        end       
    end,
    onItemRemove = function( container, item )
        local owner = container[ ECA_OWNER ]
        if owner then
            exports.sp_weapon:xrTakePlayerWeapon( owner, item )    
        end
    end
}

Hashed "slot_automatic" {
    stackable = true,
    onItemDrag = _weaponSlotTryPut,
    testSlot = _weaponSlotTest,

    onItemPut = function( container, item )
        local owner = container[ ECA_OWNER ]
        if owner then
            exports.sp_weapon:xrGivePlayerWeapon( owner, item )    
        end        
    end,
    onItemRemove = function( container, item )
        local owner = container[ ECA_OWNER ]
        if owner then
            exports.sp_weapon:xrTakePlayerWeapon( owner, item )    
        end 
    end
}

Hashed "slot_grenade" {
    stackable = true,
    onItemDrag = _weaponSlotTryPut,
    testSlot = _weaponSlotTest,

    onItemPut = function( container, item )
        local owner = container[ ECA_OWNER ]
        if owner then
            exports.sp_weapon:xrGivePlayerWeapon( owner, item )    
        end        
    end,
    onItemRemove = function( container, item )
        local owner = container[ ECA_OWNER ]
        if owner then
            exports.sp_weapon:xrTakePlayerWeapon( owner, item )    
        end 
    end
}

Hashed "slot_smth" {
    stackable = true,
    onItemDrag = _weaponSlotTryPut,
    testSlot = _weaponSlotTest,

    onItemPut = function( container, item )
              
    end,
    onItemRemove = function( container, item )
        
    end
}

Hashed "slot_belt" {
    stackable = true,
    onItemDrag = function( container, slotHash, itemHash )
        
    end,

    testSlot = function( container, slotHash, itemHash )
        local itemSection = xrSettingsGetSection( itemHash )
        if not itemSection or itemSection.slot ~= slotHash then
            return false
        end

        local itemsNum = 0
        for _, item in pairs( container[ ECA_ITEMS ] ) do
            if item[ EIA_SLOT ] == slotHash then
                itemsNum = itemsNum + 1
            end
        end

        return itemsNum < 18
    end,
    onItemPut = function( container, item )
        local section = xrSettingsGetSection( item[ EIA_TYPE ] )
        local ownerPlayer = container[ ECA_OWNER ]
        if ownerPlayer then
            if section.class == EHashes.ArtefactItem then
                exports.sp_player:PlayerAffector_applyItemAffects( ownerPlayer, item[ EIA_TYPE ], item[ EIA_ID ] )
            end
        end
    end,
    onItemRemove = function( container, item )
        local section = xrSettingsGetSection( item[ EIA_TYPE ] )
        local ownerPlayer = container[ ECA_OWNER ]
        if ownerPlayer then
            if section.class == EHashes.ArtefactItem then
                exports.sp_player:PlayerAffector_removeItemAffects( ownerPlayer, item[ EIA_TYPE ], item[ EIA_ID ] )
             end
        end
    end,
}

Hashed "slot_bag" {
    stackable = true,
    onItemDrag = function( container, slotHash, itemHash )
        
    end,

    testSlot = function( container, slotHash, itemHash )
        local itemsNum = 0
        for _, item in pairs( container[ ECA_ITEMS ] ) do
            itemsNum = itemsNum + 1
        end

        return itemsNum < 1000
    end,
    onItemPut = function( container, item )
            
    end,
    onItemRemove = function( container, item )
        local section = xrSettingsGetSection( item[ EIA_TYPE ] )
        local ownerPlayer = container[ ECA_OWNER ]
        if ownerPlayer then
            if section.class == EHashes.LightItem then
                setElementData( ownerPlayer, "lstate", false )
            end
        end
    end,
}

Hashed "slot_trade" {
    stackable = true,
    onItemDrag = function( container, slotHash, itemHash )
        
    end,

    testSlot = function( container, slotHash, itemHash )
        local itemsNum = 0
        for _, item in pairs( container[ ECA_ITEMS ] ) do
            itemsNum = itemsNum + 1
        end

        return itemsNum < 1000
    end,
    onItemPut = function( container, item )
           
    end,
    onItemRemove = function( container, item )
      
    end,
}

--[[
    Временный слот для хранения вещей мертвого игрока
]]
Hashed "slot_temp" {
    stackable = true,
    onItemDrag = function( container, slotHash, itemHash )
        
    end,

    testSlot = function( container, slotHash, itemHash )
        return true
    end,
    onItemPut = function( container, item )
           
    end,
    onItemRemove = function( container, item )
      
    end,
}

--[[
    Временный слот для хранения вещей, которые другие игроки могут украсть
    с мертвого игрока
]]
Hashed "slot_dead" {
    stackable = true,
    onItemDrag = function( container, slotHash, itemHash )
        
    end,

    testSlot = function( container, slotHash, itemHash )
        return true
    end,
    onItemPut = function( container, item )
           
    end,
    onItemRemove = function( container, item )
      
    end,
}
--[[
    xrContainer
]]
MAX_CONTAINER_ID = 2^256

xrContainers = {
    -- Карта всех контейнеров
}
_xrObtainContainer = function( arg )
    local container = arg

    if type( arg ) ~= "table" then
        local containerId = arg
        if isElement( arg ) then
            containerId = tonumber( getElementData( arg, "contId", false ) )
        end

        if type( containerId ) ~= "number" then
            return false
        end
            
        container = xrContainers[ containerId ]
    end

    return container
end

function xrContainerUseItem( arg, arg1, player )
    local container = _xrObtainContainer( arg )
    if not container then
        return false
    end

    if type( arg1 ) == "table" then
        arg1 = arg1[ EIA_ID ]
    end

    local item = container[ ECA_ITEMS ][ arg1 ]
    if item then
        local section = xrSettingsGetSection( item[ EIA_TYPE ] )
        if not section then
            return false
        end
    
        local impl = g_Hashed[ section.class ]
        if impl then
            if SERVER_SIDE then
                impl.onUse( item, section, player )
            else
                impl.onClientUse( item, section )
            end

            return true
        end
    end

    return false
end

function xrGetContainerItem( arg, itemId )
    local container = _xrObtainContainer( arg )
    if container then
        local item = container[ ECA_ITEMS ][ itemId ]
        if item then
            return item
        else
            outputDebugString( "Предмет " .. tostring( itemId ) .. " не был найден!", 2 )
        end
    end

    outputDebugString( "Контейнер не был найден", 2 )
    return false
end

local function _doItemsCompare( lhs, rhs )
    for _, field in ipairs( EItemCompareAttributes ) do
        if lhs[ field ] ~= rhs[ field ] then
            return false
        end
    end

    return true
end
function xrFindContainerSimilarItem( container, item, dstSlotHash )
    container = _xrObtainContainer( container )
    if not container then
        outputDebugString( "Контейнер не был найден", 2 )
        return false
    end

    if type( item ) == "number" then
        item = container[ ECA_ITEMS ][ item ]
    end

    if type( item ) == "table" then
        for foundId, foundItem in pairs( container[ ECA_ITEMS ] ) do
            if foundItem ~= item and ( dstSlotHash == EHashes.SlotAny or foundItem[ EIA_SLOT ] == dstSlotHash ) and _doItemsCompare( item, foundItem ) then
                return foundItem
            end
        end
    else
        outputDebugString( "Предмет не был найден", 2 )
    end

    return false
end

function xrFindContainerItemByType( arg, typeHash, slotHash )
    local container = _xrObtainContainer( arg )
    if container then
        for id, item in pairs( container[ ECA_ITEMS ] ) do
            if ( slotHash == EHashes.SlotAny or item[ EIA_SLOT ] == slotHash ) and item[ EIA_TYPE ] == typeHash then
                return item
            end
        end

        return false
    end

    outputDebugString( "Контейнер не был найден", 2 )
    return false
end

function xrFindContainerItemBySlot( arg, slotHash )
    local container = _xrObtainContainer( arg )
    if container then
        for id, item in pairs( container[ ECA_ITEMS ] ) do
            if slotHash == EHashes.SlotAny or item[ EIA_SLOT ] == slotHash then
                return item
            end
        end

        return false
    end

    outputDebugString( "Контейнер не был найден", 2 )
    return false
end

function xrCountContainerItemByType( arg, typeHash, slotHash )
    local container = _xrObtainContainer( arg )
    if container then
        local num = 0

        for id, item in pairs( container[ ECA_ITEMS ] ) do
            if ( slotHash == EHashes.SlotAny or item[ EIA_SLOT ] == slotHash ) and item[ EIA_TYPE ] == typeHash then
                num = num + item[ EIA_COUNT ]
            end
        end

        return num
    end

    outputDebugString( "Контейнер не был найден", 2 )
    return false
end

function xrSetContainerItemData( arg, itemId, key, value, sync )
    local container = _xrObtainContainer( arg )
    if container then
        local item = container[ ECA_ITEMS ][ itemId ]
        if item then
            if not item[ key ] then
                outputDebugString( "Попытка установить значение для инвалидного поля", 2 )
                return false
            end

            item[ key ] = value

            if SERVER_SIDE then
                -- Помечаем как сырой для цикла сохранения
                xrContainerMarkDirty( container )

                -- Отправляем игрокам, просматривающим в данный момент контейнер
                local observers = xrContainerObservers[ container[ ECA_ID ] ]
                if observers and ( sync == nil or sync == true ) then
                    triggerClientEvent( observers, EClientEvents.onClientContainerChange, resourceRoot, 
                        container[ ECA_ID ], ECO_MODIFY, item[ EIA_ID ], key, value
                    )
                end
            end

            return true
        else
            outputDebugString( "Предмет " .. tostring( itemId ) .. " не был найден!", 2 )
        end
    end

    outputDebugString( "Контейнер не был найден", 2 )
    return false
end

function xrGetContainerItemData( container, itemId, key )
    container = _xrObtainContainer( container )
    if container then
        local item = container[ ECA_ITEMS ][ itemId ]
        if item then
            return item[ key ]
        else
            outputDebugString( "Предмет " .. tostring( itemId ) .. " не был найден!", 2 )
        end
    end

    outputDebugString( "Контейнер не был найден", 2 )
    return
end

function xrGetContainerItems( arg )
    local container = _xrObtainContainer( arg )
    if container then
        return container[ ECA_ITEMS ]
    end

    outputDebugString( "Контейнер не был найден", 2 )
    return false
end

function xrContainerGetSlotCost( arg, slotHash, resale )
    local container = _xrObtainContainer( arg )
    if not container then
        return false
    end

    local _mathFloor = math.floor

    local totalCost = 0
    for id, item in pairs( container[ ECA_ITEMS ] ) do
        if slotHash == EHashes.SlotAny or item[ EIA_SLOT ] == slotHash then
            local section = xrSettingsGetSection( item[ EIA_TYPE ] )   
            local impl = g_Hashed[ section.class ]
            local itemCost = impl.calcCost( item, section )
            if resale then
                local resaleFactor = tonumber( section.resale_factor ) or 1
                
                itemCost = _mathFloor( itemCost * resaleFactor )
            end

            totalCost = totalCost + itemCost       
        end
    end

    return totalCost
end

function xrCalculateContainerWeight( container )
    container = _xrObtainContainer( container )
    if not container then
        return false
    end

    local totalWeight = 0
    for id, item in pairs( container[ ECA_ITEMS ] ) do
        if item[ EIA_SLOT ] ~= EHashes.SlotTemp then
            local section = xrSettingsGetSection( item[ EIA_TYPE ] )            

            totalWeight = totalWeight + ( tonumber( section.inv_weight ) or 0 ) * item[ EIA_COUNT ]
        end
    end

    return totalWeight
end

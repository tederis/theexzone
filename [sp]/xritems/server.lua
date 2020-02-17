xrDirtyContainers = {

}

xrContainerObservers = {
    -- Карта игроков, осматривающих в данный момент контейнер
    -- Здесь всегда находится игрок-владелец
}

-- Счетчик для временных контейнеров
local lastTempID = 0

CONT_DEBUG = true

--[[
    Container
]]
local function _onLoadProcess( qh, owner, serialStr )
    local result = dbPoll( qh, 0 )
    if result and #result > 0 then      
        local firstEntry = result[ 1 ]

        local containerId = tonumber( firstEntry.id )
        local containerType = tonumber( firstEntry.type )
        local lastId = tonumber( firstEntry.lastId )
        local items = restoreFromJSON( fromJSON( firstEntry.items ) )
  
        if xrContainers[ containerId ] then
            outputDebugString( "Контейнер уже загружен!", 2 )
            return
        end

        local impl = g_Hashed[ containerType ]
        if not impl then
            outputDebugString( "Контейнера с таким типом не существует!", 1 )
            return
        end        
    
        local container = {
            [ ECA_TYPE ] = containerType,
            [ ECA_ITEMS ] = items,
            [ ECA_LAST_ID ] = lastId,
            [ ECA_PASSWORD ] = 0,
            [ ECA_ID ] = containerId
        }
        
        if isElement( owner ) and ( getElementType( owner ) ~= "player" or getPlayerSerial( owner ) == serialStr ) then
            container[ ECA_OWNER ] = owner
        end

        xrContainers[ containerId ] = container
    else
        outputDebugString( "Ошибка загрузки контейнера!", 1 )
    end
end

function xrContainerLoad( id, owner )
    if xrContainers[ id ] then
        return false
    end

    local serialStr = ""
    if isElement( owner ) and getElementType( owner ) == "player" then
        serialStr = getPlayerSerial( owner )
    end

    local db = exports[ "xrcore" ]:xrCoreGetDB()
    dbQuery( _onLoadProcess, { owner, serialStr }, db, "SELECT * FROM containers WHERE id = ?", id )

    return true
end

function xrSaveContainer( arg )
    local container = _xrObtainContainer( arg )
    if not container then
        return
    end

    if container[ ECA_ID ] < 0 then
        return
    end

    container[ ECA_DIRTY ] = nil

    local itemsStr = toJSON( container[ ECA_ITEMS ], true )
    if not itemsStr then
        outputDebugString( "Ошибка при построении JSON строки", 1 )
        return
    end

    local db = exports[ "xrcore" ]:xrCoreGetDB()
    dbExec( db, 
        "UPDATE `containers` SET `items` = ?, `lastId` = ? WHERE `id` = ?", 
        itemsStr, 
        container[ ECA_LAST_ID ], 
        container[ ECA_ID ]
    )

    local ownerName = isElement( container[ ECA_OWNER ] ) and getPlayerName( container[ ECA_OWNER ] ) or ""
    outputDebugString( "Контейнер " .. container[ ECA_ID ] .. " владельца " .. ownerName .. " сохранен" )
end

function xrCreateContainer( typeHash, temp )
    if type( typeHash ) == "string" then
        typeHash = _hashFn( typeHash )
    end

    local impl = g_Hashed[ typeHash ]
    if not impl then
        outputDebugString( "Контейнера с таким типом не существует!", 1 )
        return
    end

    local containerId
    if temp then
        lastTempID = lastTempID - 1

        -- Если контейнера с таким индексом не существует
        if xrContainers[ lastTempID ] then
            outputDebugString( "Неожиданное поведение. Контейнера с индексом " .. lastTempID .. " не должно существовать!", 1 )
        else
            containerId = lastTempID
        end
    else
        local db = exports[ "xrcore" ]:xrCoreGetDB()
        local qh = dbQuery( db, [[INSERT INTO containers 
            (type, lastId, items) 
            VALUES (?, ?, ?)]]
        , typeHash, 0, toJSON( {} ) )
        local result, affectedRows, lastInsertId = dbPoll( qh, -1 )
        if result and affectedRows > 0 then
            containerId = lastInsertId
        end
    end

    if containerId then
        local container = {
            [ ECA_TYPE ] = typeHash,
            [ ECA_ITEMS ] = {},
            [ ECA_LAST_ID ] = 0,
            [ ECA_PASSWORD ] = 0,
            [ ECA_ID ] = containerId
        }

        impl.onCreate( container )

        xrContainers[ containerId ] = container

        return containerId
    end
end

function xrDestroyContainer( arg )
    local container = _xrObtainContainer( arg )
    if container then
        local observers = xrContainerObservers[ container[ ECA_ID ] ] or EMPTY_TABLE
        for _, observer in ipairs( observers ) do
            -- Отправляем наблюдателю оповещение об удалении контейнера
            triggerClientEvent( { observer }, EClientEvents.onClientContainerDestroy, observer, container[ ECA_ID ] )
        end

        xrContainers[ container[ ECA_ID ] ] = nil
        xrContainerObservers[ container[ ECA_ID ] ] = nil
    end
end

function xrSetContainerOwner( arg, owner )
    local container = _xrObtainContainer( arg )
    if container then
        container[ ECA_OWNER ] = owner
    end    
end

function xrRearrangeContainerSlots( arg )
    local container = _xrObtainContainer( arg )
    if not container then
        return
    end

    for id, item in pairs( container[ ECA_ITEMS ] ) do
        local slotHash = item[ EIA_SLOT ]
        local slotImpl = g_Hashed[ slotHash ]
        if slotImpl then
            slotImpl.onItemPut( container, item )  
        end
    end
end

function xrContainerGenerateID( arg )
    local container = _xrObtainContainer( arg )
    if container then
        local lastId = container[ ECA_LAST_ID ] + 1
        local items = container[ ECA_ITEMS ]

        --[[
            Как только мы израсходуем все индексы -
            начинаем reuse предшествующих индексов
        ]]
        if lastId >= MAX_CONTAINER_ID then				
            for i = 1, MAX_CONTAINER_ID do
                if items[ i ] == nil then
                    return i
                end
            end

            outputDebugString( "Контейнер использовал все доступные индексы! ", 2 )
            return false
        end

        container[ ECA_LAST_ID ] = lastId
        return lastId
    end

    return false
end

function xrContainerMarkDirty( arg )
    local container = _xrObtainContainer( arg )
    if container and container[ ECA_DIRTY ] ~= true and container[ ECA_TYPE ] == EHashes.PlayerContainer then
        table.insert( xrDirtyContainers, container[ ECA_ID ] )

        container[ ECA_DIRTY ] = true
    end
end

function xrContainerAddObserver( arg, player )
    local container = _xrObtainContainer( arg )
    if container then
        local observers = xrContainerObservers[ container[ ECA_ID ] ]
        if not observers then
            observers = {}
            xrContainerObservers[ container[ ECA_ID ] ] = observers
        end

        if table.insertIfNotExists( observers, player ) then
            triggerClientEvent( { player }, EClientEvents.onClientContainerData, player, container )
        end
    end
end

function xrContainerRemoveObserver( arg, player )
    local container = _xrObtainContainer( arg )
    if container then
        local observers = xrContainerObservers[ container[ ECA_ID ] ]
        if observers then
            if table.removeValue( observers, player ) then
                triggerClientEvent( { player }, EClientEvents.onClientContainerDestroy, player, container[ ECA_ID ] )
            end
        end
    end
end

--[[
    Container items
]]
local function xrContainerCreateItem( arg, itemHash, slotHash, count, silent )
    local container = _xrObtainContainer( arg )
    if not container then
        outputDebugString( "Контейнер не найден", 2 )
        return false
    end

    if type( itemHash ) == "string" then
        itemHash = _hashFn( itemHash )
    end

    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection then
        outputDebugString( "Секция для данного предмета не была найдена", 2 )
        return false
    end

    if type( slotHash ) == "string" then
        slotHash = _hashFn( slotHash )
    end
    if slotHash == EHashes.SlotAny then
        local sectionSlot = itemSection.slot or 0
        local sectionSlotImpl = g_Hashed[ sectionSlot ]
        slotHash = ( sectionSlotImpl and sectionSlotImpl.testSlot( container, sectionSlot, itemHash ) ) and sectionSlot or EHashes.SlotBag
    end

    local slotImpl = g_Hashed[ slotHash ]
    if not slotImpl then
        outputDebugString( "Неизвестный слот!", 2 )
        return false
    end    

    count = tonumber( count ) or 1
    
    local itemImpl = g_Hashed[ itemSection.class ]
    if itemImpl then
        -- Производим предварительные действия со слотом
        slotImpl.onItemDrag( container, slotHash, itemHash )

        -- Тестируем слот на свободное место
        if not slotImpl.testSlot( container, slotHash, itemHash ) then            
            outputDebugString( "Слот переполнен", 2 )
            return false
        end

        local id = xrContainerGenerateID( container )
        if not id then
            outputDebugString( "Мы не можем создавать больше предметов!", 2 )
            return false
        end

        local item = {
            [ EIA_ID ] = id,
            [ EIA_TYPE ] = itemHash,			
            [ EIA_SLOT ] = slotHash,
            [ EIA_CONDITION ] = 1.0,
            [ EIA_COUNT ] = count
        }

        itemImpl.onCreate( item, itemSection )

        container[ ECA_ITEMS ][ id ] = item

        -- Оповещаем о перемещении в новый слот
        slotImpl.onItemPut( container, item )  
        
        if silent ~= true then
            -- Отправляем игрокам, просматривающим в данный момент контейнер
            local observers = xrContainerObservers[ container[ ECA_ID ] ]
            if observers then
                triggerClientEvent( observers, EClientEvents.onClientContainerChange, resourceRoot, 
                    container[ ECA_ID ], ECO_CREATE, item
                )
            end

             -- Помечаем как сырой для цикла сохранения
            xrContainerMarkDirty( container )
        end
 
        return item
    else
        outputDebugString( "Имплементация класса для данного предмета не обнаружена!", 2 )
    end

    return false
end

function xrContainerInsertItem( arg, itemHash, slotHash, count, allowBox )
    local container = _xrObtainContainer( arg )
    if not container then
        outputDebugString( "Контейнер не найден", 2 )
        return false
    end

    --[[
        Валидируем предмет
    ]]
    if type( itemHash ) == "string" then
        itemHash = _hashFn( itemHash )
    end

    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection then
        outputDebugString( "Секция для данного предмета не была найдена", 2 )
        return false
    end

    --[[
        Валидируем слот
    ]]
    if type( slotHash ) == "string" then
        slotHash = _hashFn( slotHash )
    end
    if slotHash == EHashes.SlotAny then
        local sectionSlot = itemSection.slot or 0
        local sectionSlotImpl = g_Hashed[ sectionSlot ]
        slotHash = ( sectionSlotImpl and sectionSlotImpl.testSlot( container, sectionSlot, itemHash ) ) and sectionSlot or EHashes.SlotBag
    end

    local slotImpl = g_Hashed[ slotHash ]
    if not slotImpl then
        outputDebugString( "Неизвестный слот!", 1 )
        return false
    end

    --[[
        Валидируем кол-во и создаем предмет
    ]]
    count = tonumber( count ) or 1
    local boxSize = tonumber( itemSection.box_size )
    if boxSize and allowBox then
        count = count * boxSize
    end
    
    local itemImpl = g_Hashed[ itemSection.class ]
    if itemImpl then
        local item = {
            [ EIA_TYPE ] = itemHash,			
            [ EIA_SLOT ] = slotHash,
            [ EIA_CONDITION ] = 1.0,
            [ EIA_COUNT ] = count
        }

        itemImpl.onCreate( item, itemSection )
        
        if slotImpl.stackable then
            local similarItem = xrFindContainerSimilarItem( container, item, slotHash )
            if similarItem then
                xrSetContainerItemData( container, similarItem[ EIA_ID ], EIA_COUNT, similarItem[ EIA_COUNT ] + item[ EIA_COUNT ], true )
                
                return similarItem[ EIA_ID ]
            end
        end

        local newItem = xrContainerCreateItem( arg, itemHash, slotHash, count )
        return newItem[ EIA_ID ]
    else
        outputDebugString( "Предмет имеет инвалидный тип класса", 2 )
    end

    return false
end

--[[
    xrContainerCopyItem( srcContainer, srcItem, dstContainer, dstSlotHash )
]]
function xrContainerCopyItem( srcContainer, srcItem, dstContainer, dstSlotHash )
    srcContainer = _xrObtainContainer( srcContainer )
    dstContainer = _xrObtainContainer( dstContainer )
    if not srcContainer or not dstContainer then
        outputDebugString( "Контейнер не был найден", 2 )
        return false
    end

    if type( srcItem ) == "number" then
        srcItem = srcContainer[ ECA_ITEMS ][ srcItem ]
    end
    
    if type( srcItem ) == "table" then
        local itemSection = xrSettingsGetSection( srcItem[ EIA_TYPE ] )
        if not itemSection then
            outputDebugString( "Секция для данного предмета не была найдена", 2 )
            return false
        end

        if type( dstSlotHash ) == "string" then
            dstSlotHash = _hashFn( dstSlotHash )
        end
        if dstSlotHash == EHashes.SlotAny then
            local sectionSlot = itemSection.slot or 0
            local sectionSlotImpl = g_Hashed[ sectionSlot ]
            dstSlotHash = ( sectionSlotImpl and sectionSlotImpl.testSlot( dstContainer, sectionSlot, srcItem[ EIA_TYPE ] ) ) and sectionSlot or EHashes.SlotBag
        end

        local itemCopy = xrContainerCreateItem( dstContainer, srcItem[ EIA_TYPE ], dstSlotHash, 1, true )
        if itemCopy then
            for _, field in ipairs( EItemCopyAttributes ) do
                itemCopy[ field ] = srcItem[ field ]
            end

            -- Отправляем игрокам, просматривающим в данный момент контейнер
            local observers = xrContainerObservers[ dstContainer[ ECA_ID ] ]
            if observers then
                triggerClientEvent( observers, EClientEvents.onClientContainerChange, resourceRoot, 
                    dstContainer[ ECA_ID ], ECO_CREATE, itemCopy
                )
            end

            -- Помечаем как сырой для цикла сохранения
            xrContainerMarkDirty( dstContainer )

            return itemCopy 
        end       
    end

    return false
end

function xrContainerRemoveItem( arg, arg1 )
    local container = _xrObtainContainer( arg )
    if container then
        if type( arg1 ) == "table" then
            arg1 = arg1[ EIA_ID ]
        end

        local item = container[ ECA_ITEMS ] [ arg1 ]
        if item then
            local itemCount = item[ EIA_COUNT ]
            local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
            local impl = g_Hashed[ itemSection.class ]
            impl.onDestroy( item, itemSection )

            -- Оповещаем об удалении из старого слота
            local slotImpl = g_Hashed[ item[ EIA_SLOT ] ]
            slotImpl.onItemRemove( container, item ) 

            -- Отправляем игрокам, просматривающим в данный момент контейнер
            local observers = xrContainerObservers[ container[ ECA_ID ] ]
            if observers then
                triggerClientEvent( observers, EClientEvents.onClientContainerChange, resourceRoot, 
                    container[ ECA_ID ], ECO_REMOVE, item
                )
            end
            
            container[ ECA_ITEMS ][ arg1 ] = nil

            -- Помечаем как сырой для цикла сохранения
            xrContainerMarkDirty( container )

            return itemCount
        else
            outputDebugString( "Предмет с индексом " .. tostring( arg1 ) .. " не был найден!", 2 )
        end
    else
        outputDebugString( "Данный контейнер не существует", 2 )
    end

    return false
end

function xrContainerRemoveItems( arg, srcSlotHash )
    local srcContainer = _xrObtainContainer( arg )
    if srcContainer then
        -- Если все вместится - перемещаем предметы
        for id, item in pairs( srcContainer[ ECA_ITEMS ] ) do
            if srcSlotHash == EHashes.SlotAny or item[ EIA_SLOT ] == srcSlotHash then
                xrContainerRemoveItem( srcContainer, item )
            end
        end
        
        return true
    end

    return false
end

function xrContainerRemoveRandomItems( arg, percent )
    local container = _xrObtainContainer( arg )
    if not container then
        return
    end

    local items = container[ ECA_ITEMS ]
    local totalNum = 0
    for id, item in pairs( items ) do
        totalNum = totalNum + 1
    end
    
    local wasteNum = math.floor( totalNum * math.clamp( 0, 1, percent ) )
    for i = 1, wasteNum do
        local id, item = next( items )
        if id then
            local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] ) or EMPTY_TABLE
            if not itemSection.quest_item then
                xrContainerRemoveItem( container, id )
            end
        end
    end
end

--[[
    Здесь под count подразумевается условное кол-во
    Например для оружия единица будет равна box_size
]]
function xrContainerMoveItem( srcContainer, srcItem, dstContainer, dstSlotHash, count )
    srcContainer = _xrObtainContainer( srcContainer )
    dstContainer = _xrObtainContainer( dstContainer )
    if not srcContainer or not dstContainer then
        return false
    end

    if type( srcItem ) == "number" then
        srcItem = srcContainer[ ECA_ITEMS ][ srcItem ]
    end

    local itemSection = xrSettingsGetSection( srcItem[ EIA_TYPE ] )
    if not itemSection then
        outputDebugString( "Типа предмета " .. tostring( srcItem[ EIA_TYPE ] ) .. " не существует!", 2 )
        return false
    end

    if type( dstSlotHash ) == "string" then
        dstSlotHash = _hashFn( dstSlotHash )
    end
    if dstSlotHash == EHashes.SlotAny then
        local sectionSlot = itemSection.slot or 0
        local sectionSlotImpl = g_Hashed[ sectionSlot ]
        dstSlotHash = ( sectionSlotImpl and sectionSlotImpl.testSlot( dstContainer, sectionSlot, srcItem[ EIA_TYPE ] ) ) and sectionSlot or EHashes.SlotBag
    end

    if type( srcItem ) == "table" then
        if srcContainer == dstContainer and srcItem[ EIA_SLOT ] == dstSlotHash then
            return true
        end

        --[[
            1. Если не указано кол-во - перемещаем всё
        ]]
        if type( count ) ~= "number" then
            return xrContainerTransferItem( srcContainer, srcItem, dstContainer, dstSlotHash )
        end

        --[[
            2. В противном случае перемещаем указанное кол-во
        ]]
        count = count * ( tonumber( itemSection.box_size ) or 1 )
        return xrContainerSplitItem( srcContainer, srcItem, dstContainer, dstSlotHash, count )
    end

    return false
end

--[[
    xrContainerMoveItems( var srcContainer, var srcSlotHash, var dstContainer, number dstSlotHash )
    srcContainer - ID контейнера, элемент-владелец или таблица контейнера
    srcSlotHash - хэш слота или EHashes.SlotAny если для всех слотов
    dstContainer - ID контейнера, элемент-владелец или таблица контейнера
    dstSlotHash - хэш слота
]]
function xrContainerMoveItems( arg, srcSlotHash, arg1, dstSlotHash )
    if type( srcSlotHash ) == "string" then
        srcSlotHash = _hashFn( srcSlotHash )
    end

    if type( dstSlotHash ) == "string" then
        dstSlotHash = _hashFn( dstSlotHash )
    end

    local srcContainer = _xrObtainContainer( arg )
    local dstContainer = _xrObtainContainer( arg1 )
    if srcContainer and dstContainer then
        for id, item in pairs( srcContainer[ ECA_ITEMS ] ) do
            if srcSlotHash == EHashes.SlotAny or item[ EIA_SLOT ] == srcSlotHash then
                xrContainerTransferItem( srcContainer, item, dstContainer, dstSlotHash )
            end
        end        

        return true
    else
        outputDebugString( "Одного из контейнеров не существует( " .. tostring( srcContainer ) .. ", " .. tostring( dstContainer ) .. ")", 2 )
    end

    return false
end

function xrContainerMoveRandomItems( container, percent, dstContainer, dstSlotHash )
    container = _xrObtainContainer( container )
    if not container then
        outputDebugString( "Указанного контейнера не существует", 2 )
        return
    end

    dstContainer = _xrObtainContainer( dstContainer )
    if not dstContainer then
        outputDebugString( "Указанного контейнера не существует", 2 )
        return
    end

    local items = container[ ECA_ITEMS ]
    local itemsIDs = {}
    for id, item in pairs( items ) do
        local randPlace = math.random( 1, #itemsIDs + 1 )
        table.insert( itemsIDs, randPlace, item )
    end
    
    local wasteNum = math.floor( #itemsIDs * math.clamp( 0, 1, percent ) )
    for i = 1, wasteNum do
        local item = itemsIDs[ i ]
        if item then
            local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] ) or EMPTY_TABLE
            if not itemSection.quest_item then
                xrContainerMoveItem( container, item, dstContainer, dstSlotHash )
            end
        end
    end
end

--[[
    xrContainerTransferItem( srcContainer, srcItem, dstContainer, dstSlotHash )
]]
function xrContainerTransferItem( arg, arg1, arg2, dstSlotHash )
    local srcContainer = _xrObtainContainer( arg )
    local dstContainer = _xrObtainContainer( arg2 )
    if not srcContainer or not dstContainer then
        return false
    end    

    if type( arg1 ) == "table" then
        arg1 = arg1[ EIA_ID ]
    end

    local item = srcContainer[ ECA_ITEMS ] [ arg1 ]
    if item then
        local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
        if not itemSection then
            outputDebugString( "Предмет с таким типом не был найден", 2 )
            return false
        end

        if type( dstSlotHash ) == "string" then
            dstSlotHash = _hashFn( dstSlotHash )
        end
        if dstSlotHash == EHashes.SlotAny then
            local sectionSlot = itemSection.slot or 0
            local sectionSlotImpl = g_Hashed[ sectionSlot ]
            dstSlotHash = ( sectionSlotImpl and sectionSlotImpl.testSlot( dstContainer, sectionSlot, item[ EIA_TYPE ] ) ) and sectionSlot or EHashes.SlotBag
        end
    
        local dstSlotImpl = g_Hashed[ dstSlotHash ]
        if not dstSlotImpl then
            outputDebugString( "Неизвестный слот!", 1 )
            return false
        end

        --[[
            1. Если похожий предмет уже есть - увеличиваем его кол-во
        ]]        
        if dstSlotImpl.stackable then
            local similarItem = xrFindContainerSimilarItem( dstContainer, item, dstSlotHash )
            if similarItem then
                xrSetContainerItemData( dstContainer, similarItem[ EIA_ID ], EIA_COUNT, similarItem[ EIA_COUNT ] + item[ EIA_COUNT ], true )
                xrContainerRemoveItem( srcContainer, item[ EIA_ID ] )

                return true
            end
        end

        --[[
            2. В противном случае перемещаем
        ]]
        -- Если в пределах одного контейнера
        if dstContainer == srcContainer then
            -- Производим предварительные действия со слотом
            dstSlotImpl.onItemDrag( dstContainer, dstSlotHash, item[ EIA_TYPE ] )

            -- Тестируем слот на свободное место
            if not dstSlotImpl.testSlot( dstContainer, dstSlotHash, item[ EIA_TYPE ] ) then
                outputDebugString( "Данный слот переполнен!", 2 )
                return false
            end

            -- Оповещаем об удалении из старого слота
            local prevSlotImpl = g_Hashed[ item[ EIA_SLOT ] ]
            prevSlotImpl.onItemRemove( srcContainer, item )

            xrSetContainerItemData( dstContainer, item[ EIA_ID ], EIA_SLOT, dstSlotHash, true )
            
            -- Оповещаем о перемещении в новый слот
            dstSlotImpl.onItemPut( dstContainer, item )        
            
            return true

        -- Если между разными контейнерами
        else
            -- Если успешно - можем удалить из контейнера-источника
            if xrContainerCopyItem( srcContainer, item, dstContainer, dstSlotHash ) then
                xrContainerRemoveItem( srcContainer, item )

                return true
            end
        end
    else
        outputDebugString( "Предмет с индексом " .. tostring( arg1 ) .. " не был найден!", 2 )
    end

    return false
end

--[[
    xrContainerSplitItem( srcContainer, srcItem, dstContainer, dstSlotHash, count )
]]
function xrContainerSplitItem( arg, arg1, arg2, dstSlotHash, count )
    local srcContainer = _xrObtainContainer( arg )
    local dstContainer = _xrObtainContainer( arg2 )
    if srcContainer and dstContainer then
        if type( arg1 ) == "table" then
            arg1 = arg1[ EIA_ID ]
        end

        local item = srcContainer[ ECA_ITEMS ][ arg1 ]
        if item then
            local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
            if not itemSection then
                outputDebugString( "Предмет с таким типом не был найден", 2 )
                return false
            end

            if type( dstSlotHash ) == "string" then
                dstSlotHash = _hashFn( dstSlotHash )
            end
            if dstSlotHash == EHashes.SlotAny then
                local sectionSlot = itemSection.slot or 0
                local sectionSlotImpl = g_Hashed[ sectionSlot ]
                dstSlotHash = ( sectionSlotImpl and sectionSlotImpl.testSlot( dstContainer, sectionSlot, item[ EIA_TYPE ] ) ) and sectionSlot or EHashes.SlotBag
            end

            local dstSlotImpl = g_Hashed[ dstSlotHash ]
            if not dstSlotImpl then
                outputDebugString( "Неизвестный слот!", 1 )
                return false
            end

            local itemCount = item[ EIA_COUNT ]
            if itemCount <= count then
                 return xrContainerTransferItem( srcContainer, arg1, dstContainer, dstSlotHash )
            end

            --[[
                1. Если похожий предмет уже есть - увеличиваем его кол-во
            ]]
            if dstSlotImpl.stackable then
                local similarItem = xrFindContainerSimilarItem( dstContainer, item, dstSlotHash )
                if similarItem then
                    xrSetContainerItemData( dstContainer, similarItem[ EIA_ID ], EIA_COUNT, similarItem[ EIA_COUNT ] + count, true )
                    xrSetContainerItemData( srcContainer, item[ EIA_ID ], EIA_COUNT, itemCount - count, true )

                    return true
                end
            end

            --[[
                2. В противном случае перемещаем
            ]]
            if xrContainerCreateItem( dstContainer, item[ EIA_TYPE ], dstSlotHash, count ) then
                return xrSetContainerItemData( srcContainer, arg1, EIA_COUNT, itemCount - count, true )
            end
        else
            outputDebugString( "Предмет с индексом " .. tostring( arg1 ) .. " не был найден!", 2 )
        end
    end

    return false
end

function xrDecimateContainerItem( container, item, count, allowBox )
    container = _xrObtainContainer( container )
    if not container then
        outputDebugString( "Контейнер не был найден", 2 )
        return false
    end

    if type( item ) == "number" then
        item = container[ ECA_ITEMS ][ item ]
    end

    if type( item ) == "table" then
        local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
        if not itemSection then
            outputDebugString( "Предмет с таким типом не был найден", 2 )
            return false
        end

        count = tonumber( count ) or 1
        local boxSize = tonumber( itemSection.box_size )
        if boxSize and allowBox then
            count = count * boxSize
        end

        local num = math.min( item[ EIA_COUNT ], count )
        local newCount = item[ EIA_COUNT ] - count
        if newCount <= 0 then
            xrContainerRemoveItem( container, item )
        else
            xrSetContainerItemData( container, item[ EIA_ID ], EIA_COUNT, newCount, true )
        end

        return num
    else
        outputDebugString( "Предмет не был найден", 2 )
    end  
end

function xrContainerDropItem( container, item, x, y, z, dropAll )
    container = _xrObtainContainer( container )
    if not container then
        outputDebugString( "Контейнер не был найден", 2 )
        return false
    end

    if type( item ) == "number" then
        item = container[ ECA_ITEMS ][ item ]
    end

    if type( item ) ~= "table" then
        outputDebugString( "Предмет не был найден", 2 )
        return false
    end

    local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
    if not itemSection then
        outputDebugString( "Предмет с таким типом не был найден", 2 )
        return false
    end
    
    local dropContainerId = xrCreateContainer( "PlayerContainer", true )
    if dropContainerId then
        local dropCount = false
        if not dropAll then
            dropCount = 1
        end

        if xrContainerMoveItem( container, item, dropContainerId, EHashes.SlotBag, dropCount ) then
            if exports.sp_interact:xrDropItemAt( item[ EIA_TYPE ], dropContainerId, x, y, z ) then
                return true
            end
        end

        -- При ошибке удаляем контейнер
        xrDestroyContainer( dropContainerId )
    end

    return false
end

function xrCreateDropItem( itemHash, x, y, z, lifeTime )
    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection then
        outputDebugString( "Предмет с таким типом не был найден", 2 )
        return false
    end
    
    local dropContainerId = xrCreateContainer( "PlayerContainer", true )
    if dropContainerId then
        if xrContainerInsertItem( dropContainerId, itemHash, EHashes.SlotBag, 1, true ) then
            if exports.sp_interact:xrDropItemAt( itemHash, dropContainerId, x, y, z, lifeTime ) then
                return true
            end
        end

        -- При ошибке удаляем контейнер
        xrDestroyContainer( dropContainerId )
    end

    return false
end

function xrDecimateContainerItemsByType( container, typeHash, count, slotHash )
    container = _xrObtainContainer( container )
    if not container then
        outputDebugString( "Контейнер не был найден", 2 )
        return false
    end

    local num = count

    for id, item in pairs( container[ ECA_ITEMS ] ) do
        if ( slotHash == EHashes.SlotAny or item[ EIA_SLOT ] == slotHash ) and item[ EIA_TYPE ] == typeHash then
            local itemSection = xrSettingsGetSection( typeHash )
            if itemSection then                
                local delta = math.min( item[ EIA_COUNT ], num )
                local newCount = item[ EIA_COUNT ] - delta
                if newCount > 0 then
                    xrSetContainerItemData( container, item[ EIA_ID ], EIA_COUNT, newCount, true )
                else
                    xrContainerRemoveItem( container, item )
                end

                num = num - delta
            else
                outputDebugString( "Предмет с таким типом не был найден", 2 )
            end
        end

        if num < 1 then
            break
        end
    end

    -- Возвращаем кол-во удаленных вещей
    return count - num
end

local function onUpdatePulse()
    local lastIndex = #xrDirtyContainers
    if lastIndex < 1 then
        return
    end

    local container = _xrObtainContainer( xrDirtyContainers[ lastIndex ] )
    if container then
        xrSaveContainer( container )
    end

    table.remove( xrDirtyContainers, lastIndex )
end

local function onPlayerGameExit()
    -- Форсируем сохранение
    xrSaveContainer( source )
end

local function onPlayerLeaveLevel()
    -- Удаляем контейнер
    xrDestroyContainer( source )
end

addCommandHandler( "giveitem",
    function( player, _, dstPlayerTraits, itemName, count )
        if not hasObjectPermissionTo( player, "command.giveitem", false ) then
            outputChatBox( "У вас недостаточно прав для использования этой команды", player )
            return
        end

        local dstPlayer = dstPlayerTraits == "self" and player or xrGetPlayerByTraits( dstPlayerTraits )
        if not dstPlayer then
            outputChatBox( "Такого игрока не существует!", player )
            return
        end

        if type( itemName ) ~= "string" then
            outputChatBox( "Вы должны указать имя предмета. Синтаксис /giveitem itemName count", player )
            return
        end

        count = math.max( math.min( tonumber( count ) or 1, 100 ), 1 )

        xrContainerInsertItem( dstPlayer, _hashFn( itemName ), EHashes.SlotAny, count, true )
    end
)

--[[
    Initialization
]]
addEventHandler( "onCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

        if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
        end

        --[[
            Позаимствованные из сталкера конфиги выполняют калькуляцию
            массы по коробкам. Поэтому нужно пересчитать
        ]]
        local boxedSections = xrSettingsFindSections( "box_size" ) or EMPTY_TABLE
        for _, hash in ipairs( boxedSections ) do
            local section = xrSettingsGetSection( hash )
            if section then
                section.inv_weight = section.inv_weight / section.box_size
            end
        end
        

        addEvent( EServerEvents.onPlayerGamodeLeave, false )
        addEventHandler( EServerEvents.onPlayerGamodeLeave, root, onPlayerGameExit )
        addEvent( EServerEvents.onPlayerLeaveLevel, false )
        addEventHandler( EServerEvents.onPlayerLeaveLevel, root, onPlayerLeaveLevel )
    end
)

addEvent( "onCoreInitializing", false )
addEventHandler( "onCoreInitializing", root,
    function()
        local db = exports[ "xrcore" ]:xrCoreGetDB()
        if not db then
            outputDebugString( "Указатель на базу данных не был получен!", 1 )
            return
        end

        triggerEvent( "onResourceInitialized", resourceRoot, resource )

        setTimer( onUpdatePulse, 5000, 0 )
    end
, false )
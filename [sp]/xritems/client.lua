local xrPlayerContainerWeight = 0

local function onContainerData( data )
    local id = data[ ECA_ID ]
    if type( id ) == "number" then
        xrContainers[ id ] = data
        
        -- Подсчитываем массу контейнера игрока за исключением скрытого слота
        if id == getElementData( localPlayer, "contId", false ) then
            xrPlayerContainerWeight = xrCalculateContainerWeight( data )
        end
    else
        outputDebugString( "Инвалидный контейнер", 2 )
    end
end

local function onContainerDestroy( containerId )
    local container = xrContainers[ containerId ]
    if container then
        -- Обнуляем массу игрока
        if container[ ECA_ID ] == getElementData( localPlayer, "contId", false ) then
            xrPlayerContainerWeight = 0
        end

        xrContainers[ containerId ] = nil
        collectgarbage( "collect" )
    end
end

local function onContainerChange( containerId, operation, arg, arg1, arg2 )
    local container = xrContainers[ containerId ]
    if not container then
        outputDebugString( "Инвалидный контейнер", 2 )
        return 
    end    

    local isLocal = container[ ECA_ID ] == getElementData( localPlayer, "contId", false )

    --[[
        Обновление атрибута предмета
    ]]
    if operation == ECO_MODIFY then
        local item = container[ ECA_ITEMS ][ arg ]
        if item then
            local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
            if not itemSection then
                outputDebugString( "Секция для данного предмета не была найдена", 2 )
                return false
            end

            local prevItem = table.copy( item )
            item[ arg1 ] = arg2

            --[[
                Если мы меняем кол-во предметов - обязательно пересчитываем массу контейнера
            ]]
            if isLocal then
                if arg1 == EIA_COUNT then
                    local deltaCount = item[ EIA_COUNT ] - prevItem[ EIA_COUNT ]
                    xrPlayerContainerWeight = xrPlayerContainerWeight + ( itemSection.inv_weight or 0 ) * deltaCount
                elseif item[ EIA_SLOT ] ~= prevItem[ EIA_SLOT ] then
                    local count = 0

                    -- Перемещаем из настоящего во временный
                    if item[ EIA_SLOT ] == EHashes.SlotTemp then
                        count = -item[ EIA_COUNT ]

                    -- Перемещаем из временного в настоящий
                    elseif prevItem[ EIA_SLOT ] == EHashes.SlotTemp then
                        count = item[ EIA_COUNT ]
                    end

                    xrPlayerContainerWeight = xrPlayerContainerWeight + ( itemSection.inv_weight or 0 ) * count
                end
            end
        
            triggerEvent( EClientEvents.onClientItemModify, root, containerId, prevItem, item )
        else
            outputDebugString( "Такого предмета не существует!", 2 )
        end
             
        return
    end

    --[[
        Создание/удаление предмета
    ]]
    local itemSection = xrSettingsGetSection( arg[ EIA_TYPE ] )
    if not itemSection then
        outputDebugString( "Секция для данного предмета не была найдена", 2 )
        return false
    end

    local itemId = arg[ EIA_ID ]
    if operation == ECO_CREATE then
        container[ ECA_ITEMS ][ itemId ] = arg

        if isLocal then
            xrPlayerContainerWeight = xrPlayerContainerWeight + ( itemSection.inv_weight or 0 ) * arg[ EIA_COUNT ]
        end

        triggerEvent( EClientEvents.onClientItemNew, root, containerId, arg )
    elseif operation == ECO_REMOVE then
        if isLocal then
            xrPlayerContainerWeight = xrPlayerContainerWeight - ( itemSection.inv_weight or 0 ) * arg[ EIA_COUNT ]
        end

        container[ ECA_ITEMS ][ itemId ] = nil

        triggerEvent( EClientEvents.onClientItemRemove, root, containerId, arg )
    end
end

local function onUseItem( id )
    xrContainerUseItem( localPlayer, id, localPlayer )
end

function xrGetContainerWeight( container )
    container = _xrObtainContainer( container )
    if container then
        if container[ ECA_ID ] == getElementData( localPlayer, "contId", false ) then
            return xrPlayerContainerWeight
        else
            return 0
        end
    end

    return false
end

--[[
    Initialization
]]
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

        addEvent( EClientEvents.onClientContainerData, true )
        addEventHandler( EClientEvents.onClientContainerData, localPlayer, onContainerData, false )

        addEvent( EClientEvents.onClientContainerDestroy, true )
        addEventHandler( EClientEvents.onClientContainerDestroy, localPlayer, onContainerDestroy, false )

        addEvent( EClientEvents.onClientContainerChange, true )
        addEventHandler( EClientEvents.onClientContainerChange, resourceRoot, onContainerChange, false, "high" )

        addEvent( EClientEvents.onClientItemUse, true )
        addEventHandler( EClientEvents.onClientItemUse, localPlayer, onUseItem, false )
    end
)
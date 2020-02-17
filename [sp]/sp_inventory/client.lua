xrShared = {

}

local _lastSession = nil

local function onSessionStart( id1, sessionType, classHash1 )
    local id0 = localPlayer:getData( "contId" )        
    
    exports.sp_chatbox:xrShowChat( false )      

    -- Мы открыли свой инвентарь
    if sessionType == EST_PLAYER_SELF then
        xrInventory.open( id0, classHash1 )

        _lastSession = {
            type = sessionType,
            id1 = id1
        }
    elseif sessionType == EST_PLAYER_OBJECT then
        xrCarBody.open( id0, id1, classHash1 )

        _lastSession = {
            type = sessionType,
            id1 = id1
        }
    elseif sessionType == EST_PLAYER_NPC or sessionType == EST_PLAYER_PLAYER then
        xrTrade.open( id0, id1, classHash1 )

        _lastSession = {
            type = sessionType,
            id1 = id1
        }
    end
end

function xrGetInventoryStatus()
    return _lastSession ~= nil
end

local function onSessionStop()
    if not _lastSession then
        return
    end

    exports.sp_chatbox:xrShowChat( true )
            
    -- Мы открыли свой инвентарь
    if _lastSession.type == EST_PLAYER_SELF then
        xrInventory.release( )
    elseif _lastSession.type == EST_PLAYER_OBJECT then
        xrCarBody.release( )
    elseif _lastSession.type == EST_PLAYER_NPC or _lastSession.type == EST_PLAYER_PLAYER then
        xrTrade.release( )
    end

    _lastSession = nil
end

local function onItemNew( containerId, item )
    if not _lastSession then
        return
    end
            
    if _lastSession.type == EST_PLAYER_SELF then
        xrInventory.onNewItem( containerId, item )
    elseif _lastSession.type == EST_PLAYER_OBJECT then
        xrCarBody.onNewItem( containerId, item )
    elseif _lastSession.type == EST_PLAYER_NPC or _lastSession.type == EST_PLAYER_PLAYER then
        xrTrade.onNewItem( containerId, item )
    end
end

local function onItemModify( containerId, prevItem, newItem )
    if not _lastSession then
        return
    end
            
    if _lastSession.type == EST_PLAYER_SELF then
        xrInventory.onModifyItem( containerId, prevItem, newItem )
    elseif _lastSession.type == EST_PLAYER_OBJECT then
        xrCarBody.onModifyItem( containerId, prevItem, newItem )
    elseif _lastSession.type == EST_PLAYER_NPC or _lastSession.type == EST_PLAYER_PLAYER then
        xrTrade.onModifyItem( containerId, prevItem, newItem )
    end
end

local function onItemRemove( containerId, item )
    if not _lastSession then
        return
    end
            
    if _lastSession.type == EST_PLAYER_SELF then
        xrInventory.onRemoveItem( containerId, item )
    elseif _lastSession.type == EST_PLAYER_OBJECT then
        xrCarBody.onRemoveItem( containerId, item )
    elseif _lastSession.type == EST_PLAYER_NPC or _lastSession.type == EST_PLAYER_PLAYER then
        xrTrade.onRemoveItem( containerId, item )
    end
end

addEventHandler( "onClientCoreStarted", root,
    function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "uisection.lua" )
        xrIncludeModule( "global.lua" )
        xrIncludeModule( "locale.lua" )

		if not xrSettingsInclude( "items_only.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
        end

        if not xrSettingsInclude( "characters/stalkers.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
        end

        if not xrSettingsInclude( "teams.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
        end
  
        xrIncludeLocaleFile( "st_items_equipment" )
        xrIncludeLocaleFile( "st_items_weapons" )
        xrIncludeLocaleFile( "st_items_mutants" )
        xrIncludeLocaleFile( "st_items_artefacts" )
        xrIncludeLocaleFile( "st_items_artefacts" )
        xrIncludeLocaleFile( "st_items_outfit" )
        xrIncludeLocaleFile( "st_items_quest" )        
        
        addEvent( EClientEvents.onClientItemRemove, false )
        addEventHandler( EClientEvents.onClientItemRemove, root, onItemRemove, false )
        addEvent( EClientEvents.onClientItemModify, false )
        addEventHandler( EClientEvents.onClientItemModify, root, onItemModify, false )
        addEvent( EClientEvents.onClientItemNew, false )
        addEventHandler( EClientEvents.onClientItemNew, root, onItemNew, false )
        addEvent( EClientEvents.onClientSessionStop, true )
        addEventHandler( EClientEvents.onClientSessionStop, localPlayer, onSessionStop, false )
        addEvent( EClientEvents.onClientSessionStart, true )
        addEventHandler( EClientEvents.onClientSessionStart, localPlayer, onSessionStart, false )

        local sw, sh = guiGetScreenSize()
        xrShared.font = dxCreateFont ( "AG Letterica Roman Medium.ttf", sh / 60, true )

        initTrade()
    end
)
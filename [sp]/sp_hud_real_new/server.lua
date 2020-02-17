local function onPlayerSpawn()
    if not exports.sp_player:xrGetPlayerInfo( source, EHashes.InfoTutorialPassed ) then
        xrSendPlayerHelpString( source, HSC_FIRST )
    elseif exports.sp_player:xrGetPlayerInfo( source, EHashes.InfoPlayerNaked ) then
        xrSendPlayerHelpString( source, HSC_ITEMS )
    end
end

local function onPlayerEndTalk()
    xrSendPlayerHelpString( source, HSC_NONE )

    -- Если прошли интро, но не прошли обучение
    if exports.sp_player:xrGetPlayerInfo( source, EHashes.InfoIntroLeft ) and not exports.sp_player:xrGetPlayerInfo( source, EHashes.InfoTutorialPassed ) then
        xrSendPlayerHelpString( source, HSC_FIND_AREA )
        
        exports.sp_player:xrSetPlayerInfo( source, EHashes.InfoTutorialPassed, 1 )
    end
end

--[[
    Exports
]]
function xrSendPlayerHelpString( player, strCode )
    triggerClientEvent( player, EClientEvents.onClientHelpString, player, strCode )
end

function xrPrintPlayerNews( player, text, sectionName )
    triggerClientEvent( player, EClientEvents.onClientNewsMessage, resourceRoot, text, sectionName )
end

function xrPrintNews( text, sectionName )
    triggerClientEvent( EClientEvents.onClientNewsMessage, resourceRoot, text, sectionName )
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

addEvent( "onCoreStarted", false )
addEventHandler( "onCoreStarted", root,
--addEventHandler( "onResourceStart", resourceRoot,
    function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

        addEvent( EServerEvents.onPlayerSpawn, false )
        addEventHandler( EServerEvents.onPlayerSpawn, root, onPlayerSpawn )
        addEvent( EServerEvents.onDialogEndTalk, false )
        addEventHandler( EServerEvents.onDialogEndTalk, root, onPlayerEndTalk )
    end
)
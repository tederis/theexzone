--[[
	Авторизация
]]

addEvent ( "onXrLogin", true )
addEventHandler ( "onXrLogin", resourceRoot,
	function ( name, pass )
		if utfLen ( pass ) < 4 then
			return
		end

		exports[ "sp_player" ]:xrPlayerLogIn( client, name, pass )
	end
, false )

addEvent ( "onXrRegister", true )
addEventHandler ( "onXrRegister", resourceRoot,
	function ( name, pass )
		if utfLen ( pass ) < 4 then
			return
		end

		exports[ "sp_player" ]:xrPlayerRegister( client, name, pass )
	end
, false )

-- Вызывается после логина или регистрации
local function _onPlayerLogin( player )
	local characters = exports[ "sp_player" ]:xrPlayerGetCharacters( player )
	triggerClientEvent( { player }, "onClientCharacterData", player, 1, characters )
end

addEvent( "onPlayerLoginResult", false )
addEventHandler( "onPlayerLoginResult", root,
	function( errorCode )
		--[[
			Нулевой код означает успешную авторизацию
		]]
		if errorCode == 0 then
			_onPlayerLogin( source )
			triggerClientEvent( { source }, "onClientLoginSuccess", source )
			return
		end

		--[[
			В противном случае возникла ошибка с кодом errorCode
		]]
		triggerClientEvent( { source }, "onClientLoginError", source, errorCode )
	end
)

addEvent( "onPlayerRegisterResult", false )
addEventHandler( "onPlayerRegisterResult", root,
	function( errorCode )
		--[[
			Нулевой код означает успешную авторизацию
		]]
		if errorCode == 0 then
			_onPlayerLogin( source )
			triggerClientEvent( { source }, "onClientLoginSuccess", source )
			return
		end

		--[[
			В противном случае возникла ошибка с кодом errorCode
		]]
		triggerClientEvent( { source }, "onClientLoginError", source, errorCode )
	end
)

--[[
	Персонажи
]]
addEvent( "onXrCharacterNew", true )
addEventHandler( "onXrCharacterNew", resourceRoot,
	function( name, factionHash )
		if exports[ "sp_player" ]:xrCreateCharacter( client, name, factionHash ) then
			local character = exports[ "sp_player" ]:xrPlayerGetCharacter( client, name )
			triggerClientEvent( { client }, "onClientCharacterData", client, 2, character )
		end
	end
, false )

addEvent ( "onCharacterJoin", true )
addEventHandler ( "onCharacterJoin", resourceRoot,
	function( characterName, ignoreSurge )
		local surgeTimeRemaining = exports.sp_gamemode:xrGetSurgeRemainingSecs()
		if surgeTimeRemaining and ignoreSurge ~= true then
			triggerClientEvent( { client }, "onClientJoinError", client, surgeTimeRemaining )

			return
		end

		exports[ "sp_player" ]:xrPlayerApplyCharacter( client, characterName )
		exports[ "sp_gamemode" ]:xrGamemodeJoin( client )

		triggerClientEvent( { client }, "onClientSwitchLogin", client, false )
	end
, false )

--[[
    Initialization
]]
local function loadPlayers()
    local db = exports[ "xrcore" ]:xrCoreGetDB()
    if not db then
        outputDebugString( "Указатель на базу данных не был получен!", 1 )
        return
    end

    triggerEvent( "onResourceInitialized", resourceRoot, resource )
end

addEvent( "onCoreInitializing", false )
addEventHandler( "onCoreInitializing", root,
    function()
		loadPlayers()
    end
, false )

addEvent( "onCoreStarted", false )
addEventHandler( "onCoreStarted", root,
	function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
		xrIncludeModule( "player.lua" )
		xrIncludeModule( "global.lua" )

		if not xrSettingsInclude( "teams.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации команд!", 2 )
            return
		end
	end
)
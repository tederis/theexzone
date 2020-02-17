local sw, sh = guiGetScreenSize()

local _textColorSep = { 245, 250, 245 }

function math.lerp ( a, b, t )
	return a + (b-a)*t
end

uiLogos = {
	merc_big        = { x = 1   , y = 1   , width = 249 , height = 194 },
    freedom_big     = { x = 257 , y = 1   , width = 249 , height = 194 },
    stalker_big     = { x = 513 , y = 1   , width = 249 , height = 194 },
    bandit_big      = { x = 769 , y = 1   , width = 249 , height = 194 },
    csky_big        = { x = 1   , y = 202 , width = 249 , height = 194 },
    renegade_big    = { x = 257 , y = 202 , width = 249 , height = 194 },
    dolg_big        = { x = 774   , y = 829   , width = 249 , height = 194 },

    merc_logo        = { x = 579 , y = 513 , width = 244 , height = 238 },
    freedom_logo     = { x = 23  , y = 763 , width = 238 , height = 255 },
    stalker_logo     = { x = 295 , y = 400 , width = 260 , height = 255 },
    bandit_logo      = { x = 286 , y = 658 , width = 280 , height = 366 },
    csky_logo        = { x = 574 , y = 205 , width = 277 , height = 304 },
    renegade_logo    = { x = 12  , y = 402 , width = 276 , height = 356 },
    
	actor_big        = { x = 1023 , y = 1023 , width = 1 , height = 1 },
	actor_logo       = { x = 1023 , y = 1023 , width = 1 , height = 1 },
    logos_big_empty  = { x = 1023 , y = 1023 , width = 1 , height = 1 }
}

uiHud = {
	{ x = 0 , y = 728 , width = 46 , height = 47 },
	{ x = 0 , y = 775 , width = 46 , height = 47 },
    { x = 0 , y = 822 , width = 46 , height = 47 },
    { x = 0 , y = 869 , width = 46 , height = 47 },
    { x = 667 , y = 40 , width = 46 , height = 47 }
}

local sceneInfo = {
	geom = "scene",
	tex = "scene",
	col = "scene",
	model = 1000
}

local errorStrs = {
	-- Login
    "Игрок с такими учетными данными уже авторизован",
    "Неверно указаны логин и/или пароль. Проверьте введенные данные и повторите",
	"Во время авторизации произошла неопознанная ошибка",
	"Логин должен содержать не меньше 4х символов",
	"Пароль должен содержать не меньше 4х символов",
    
    -- Register
    "Игрок с такими учетными данными уже авторизован",
    "Игрок с такими учетными данными уже зарегистрирован",
	"Во время регистрации произошла неопознанная ошибка",
	
	-- Character
	"Вы не можете создать больше 4 персонажей",
	"Имя персонжа должно содержать не меньше 6 символов"
}

xrTeamHashes = {}
xrTeams = {}
xrIsLoggedIn = false

local characters = { 

}

local FADE_NONE = 1
local FADE_IN = 2
local FADE_OUT = 3

xrInterface = { 
	
}

-- Создаем единый интерфейс для управления экранами и меню
function xrInterface.start( screen )
	if xrInterface.enabled then
		xrInterface.setScreen( screen )
		return
	end

	--[[
		Отключаем дефолтные игровые звуки и скрываем интерфейсы
	]]
	for i = 0, 44 do
		setWorldSoundEnabled( i, false )
	end
	setAmbientSoundEnabled( "general", false )

	setPlayerHudComponentVisible( "all", false )
	exports.sp_chatbox:xrShowChat( false )	


	--[[
		Если ядро уже запущено - показываем экран из аргумента
		Если еще нет - показываем экран загрузки
	]]
	local coreRes = getResourceFromName( "xrcore" )
	if coreRes and coreRes.state == "running" and exports.xrcore:xrCoreGetState() then
		xrInterface.setScreen( screen )
	else
		outputDebugString( "Ядро не было запущено!", 2 )
	end

	addEventHandler( "onClientRender", root, xrInterface.onRender )
	addEventHandler( "onClientCursorMove", root, xrInterface.onCursorMove )
	addEventHandler( "onClientClick", root, xrInterface.onClick )
	addEventHandler( "onClientCharacter", root, xrInterface.onCharacter )
	addEventHandler( "onClientKey", root, xrInterface.onKey )

	xrInterface.enabled = true
end

function xrInterface.stop( fadeOut )
	if not xrInterface.enabled then
		return
	end

	-- Моментально удаляем интерфейс
	xrInterface.destroy()
end

function xrInterface.destroy()
	if not xrInterface.enabled then
		return
	end

	exports.sp_chatbox:xrShowChat( true )

	removeEventHandler( "onClientRender", root, xrInterface.onRender )
	removeEventHandler( "onClientCursorMove", root, xrInterface.onCursorMove )
	removeEventHandler( "onClientClick", root, xrInterface.onClick )
	removeEventHandler( "onClientCharacter", root, xrInterface.onCharacter )
	removeEventHandler( "onClientKey", root, xrInterface.onKey )
	
	xrInterface.setScreen( nil )

	if isElement( xrSharedSnd ) then
		stopSound( xrSharedSnd )
	end
	xrSharedSnd = false

	exports.sp_loading:xrStopLoadingSound()
	
	xrInterface.enabled = false
end

function xrInterface.setScreen( screen )
	if xrInterface.screen then
		xrInterface.screen:destroy()
		xrInterface.screen = nil
	end

	if screen then
		xrInterface.screen = screen
		screen:new()
	end
end

function xrInterface.onRender()
	if xrInterface.screen then
		xrInterface.screen:onRender( )
	end
end

function xrInterface.onCursorMove ( _, _, ax, ay )
	if xrInterface.screen then
		xrInterface.screen:onCursorMove( _, _, ax, ay )
	end
end

function xrInterface.onClick( button, state, absoluteX, absoluteY )
	if xrInterface.screen and type( xrInterface.screen.onClick ) == "function" then
		xrInterface.screen:onClick( button, state, absoluteX, absoluteY )
	end
end

function xrInterface.onCharacter( char )
	if xrInterface.screen and type( xrInterface.screen.onCharacter ) == "function" then
		xrInterface.screen:onCharacter( char )
	end
end

function xrInterface.onKey( key, state )
	if xrInterface.screen and type( xrInterface.screen.onKey ) == "function" then
		xrInterface.screen:onKey( key, state )
	end
end

--[[
	xrLoginScreen
]]
local ERROR_MSG_DURATION = 5000

xrLoginScreen = {}

function xrLoginScreen.new( self )
	xrBackground:new()
	
	setCameraMatrix ( 0, 2, 487, 0, 0, 487 )

	showCursor ( true )
	guiSetInputMode ( "no_binds" )

	fadeCamera( false, 0 )

	self.canvas = xrCreateUICanvas( 0, 0, sw, sh )

	local xml = xmlLoadFile( "config/LoginWnd.xml", true )
	if xml then
		self.canvas:load( xml )
		self.canvas:update()

		self.canvas:getFrame( "LoginBtn", true ):addHandler( xrLoginScreen.onLoginBtn, self )
		self.canvas:getFrame( "RegisterBtn", true ):addHandler( xrLoginScreen.onRegisterBtn, self )
		self.usernameEdt = self.canvas:getFrame( "UsernameEdt", true )
		self.passwordEdt = self.canvas:getFrame( "PasswordEdt", true )
		self.errorLbl = self.canvas:getFrame( "ErrorLbl", true )
		self.errorLbl:setVisible( false )

		xmlUnloadFile( xml )
	end
end

function xrLoginScreen.destroy ( self )
	self.canvas:destroy()
	self.canvas = nil

	self.errorTime = nil

	guiSetInputMode ( "allow_binds" )
	showCursor ( false )

	xrBackground:destroy()
end

function xrLoginScreen:onLoginBtn()
	local login = self.usernameEdt.text
	if utfLen ( login ) < 4 then
		xrLoginScreen:showErrorMessage( "Логин должен содержать не меньше 4х символов" )
		return
	end
	local pass = self.passwordEdt.text
	if utfLen ( pass ) < 4 then
		xrLoginScreen:showErrorMessage( "Пароль должен содержать не меньше 4х символов" )
		return
	end

	triggerServerEvent( "onXrLogin", resourceRoot, login, pass )
end 

function xrLoginScreen:onRegisterBtn()
	local login = self.usernameEdt.text
	if utfLen ( login ) < 4 then
		xrLoginScreen:showErrorMessage( "Логин должен содержать не меньше 4х символов" )
		return
	end
	local pass = self.passwordEdt.text
	if utfLen ( pass ) < 4 then
		xrLoginScreen:showErrorMessage( "Пароль должен содержать не меньше 4х символов" )
		return
	end

	triggerServerEvent( "onXrRegister", resourceRoot, login, pass )
end

function xrLoginScreen.onRender ( self )
	xrBackground:render()

	self.canvas:draw()

	if xrLoginScreen.errorTime then
		local now = getTickCount()
		if now >= xrLoginScreen.errorTime then
			self.errorLbl:setVisible( false )
			xrLoginScreen.errorTime = nil
		end
	end
end

function xrLoginScreen:onCursorMove( _, _, ax, ay )
	self.canvas:onCursorMove( ax, ay )
end

function xrLoginScreen:onClick( button, state, absoluteX, absoluteY )
	self.canvas:onCursorClick( button, state, absoluteX, absoluteY )
end

function xrLoginScreen:onCharacter( char )
	self.canvas:onCharacter( char )
end

function xrLoginScreen:onKey( key, state )
	self.canvas:onKey( key, state )
end

function xrLoginScreen:showErrorMessage( str )
	self.errorTime = getTickCount() + ERROR_MSG_DURATION

	self.errorLbl:setVisible( true )
	self.errorLbl:setText( str )
	self.errorLbl:update()
end

addEvent( "onClientLoginSuccess", true )
addEventHandler( "onClientLoginSuccess", localPlayer,
	function()
		if xrInterface.screen ~= xrLoginScreen then
			return			
		end

		xrIsLoggedIn = true

		xrInterface.setScreen( xrCharScreen )		
	end
, false )

addEvent( "onClientLoginError", true )
addEventHandler( "onClientLoginError", localPlayer,
	function( errorCode )
		local errorStr = errorStrs[ errorCode ]
		if errorStr then
			xrLoginScreen:showErrorMessage( errorStr )
		end
	end
, false )

--[[
	xrСharScreen
]]
local FACTION_STALKER = 1
local FACTION_BANDIT = 2

local errorNameStr = "К сожалению, мы не можем принять такое ролевое имя. Имя должно состоять из двух слов, первое из которых может быть именем, а второе фамилией или прозвищем. Например, корректным ролевым именем будет 'Вася Турпан'. Попробуйте это имя, возможно оно еще не занято."

xrCharScreen = {

}

function xrCharScreen:new()
	xrBackground:new()

	self.font = exports.sp_assets:xrLoadAsset( "LettericaRomanMedium" )

	self.pedShader = dxCreateShader( "pedshader.fx", 1, 0, false, "ped" )
	dxSetShaderValue( self.pedShader, "DiffuseColor", 0.4, 0.4, 0.4, 1 )	
	engineApplyShaderToWorldTexture( self.pedShader, "*" )

	self.object = createObject( sceneInfo.model, 0, 0, 500 - 200 )
	setElementAlpha( self.object, 0 )

	setCameraMatrix( 0, 2, 487 - 200, 0, 0, 487 - 200 )
	--setCameraShakeLevel( 1 )
	--setCameraShakeLevel( 0 )

	fadeCamera( true, 0 )

	self.angle = 0
	self.cursorx = 0	
	
	self.createCanvas = nil
	self.selectCanvas = nil
	
	if #characters > 0 then
		self:onFurtherJoint()
	else
		self:onFirstJoint()
	end

	showCursor( true )
	guiSetInputMode( "no_binds" )
end

function xrCharScreen:destroy()
	engineRemoveShaderFromWorldTexture( self.pedShader, "*", self.ped )
	destroyElement( self.pedShader )
	
	if isElement( self.object ) then
		destroyElement( self.object )
	end

	if isElement( xrCharScreen.ped ) then
		destroyElement( xrCharScreen.ped )
	end
	
	if self.createCanvas then
		self.createCanvas:destroy()
		self.createCanvas = nil
	end

	if self.selectCanvas then
		self.selectCanvas:destroy()
		self.selectCanvas = nil
	end

	guiSetInputMode( "allow_binds" )
	showCursor( false )

	xrBackground:destroy()
end

-- Последующие посещения сервера
function xrCharScreen:onFurtherJoint()
	--[[
		Создаем педа
	]]
	local x, y, z = 0, 0, 487
	local firstChar = characters[ 1 ]
	if firstChar then
		self.ped = createPed( firstChar[ E_CHAR_SKIN ], x, y, z - 200 )	
	end

	--[[
		Создаем меню
	]]
	self.selectCanvas = xrCreateUICanvas( 0, 0, sw, sh )

	local xml = xmlLoadFile( "config/CharScreen.xml", true )
	if xml then
		self.selectCanvas:load( xml )
		self.selectCanvas:update()

		self.selectCanvas:getFrame( "JoinBtn", true ):addHandler( xrCharScreen.onJoinBtn, self )
		self.joinErrorWnd = self.selectCanvas:getFrame( "ErrorWnd", true ):setVisible( false )
		self.joinErrorWnd:getFrame( "CancelBtn", true ):addHandler( xrCharScreen.onJoinErrorBtn, self )
		self.joinErrorWnd:getFrame( "OkayBtn", true ):addHandler( xrCharScreen.onJoinProceedBtn, self )

		xmlUnloadFile( xml )
	end
end

-- Первый вход на сервер
function xrCharScreen:onFirstJoint()
	self.createCanvas = xrCreateUICanvas( 0, 0, sw, sh )

	local xml = xmlLoadFile( "config/CharCreateWnd.xml", true )
	if xml then
		self.selectedFaction = FACTION_STALKER

		self.createCanvas:load( xml )
		self.createCanvas:update()

		self.createCanvas:getFrame( "CreateBtn", true ):addHandler( xrCharScreen.onCreateBtn, self )
		self.stalkerImg = self.createCanvas:getFrame( "StalkerFactImg", true )
		self.stalkerImg:addHandler( xrCharScreen.onFactionSelect, self, FACTION_STALKER )
		self.banditImg = self.createCanvas:getFrame( "BanditFactImg", true )
		self.banditImg:addHandler( xrCharScreen.onFactionSelect, self, FACTION_BANDIT )
		self.nameEdt = self.createCanvas:getFrame( "NameEdt", true )
		self.errorWnd = self.createCanvas:getFrame( "NameErrorWnd", true )
		self.errorWnd:setVisible( false )
		self.errorWnd:getFrame( "ErrorOkBtn" ):addHandler( xrCharScreen.onErrorWndBtn, self )

		xmlUnloadFile( xml )
	end
end

-- Мы хотим войти в игру
function xrCharScreen:onJoinBtn()
	local now = getTickCount()
	if self.lastJoinClickTime and now - self.lastJoinClickTime < 1000 then
		return
	end

	self.lastJoinClickTime = now

	local firstChar = characters[ 1 ]
	if firstChar then
		fadeCamera( false, 0 )
		triggerServerEvent( "onCharacterJoin", resourceRoot, firstChar[ E_CHAR_NAME ], false )
	end
end

function xrCharScreen:onJoinErrorBtn()
	self.joinErrorWnd:setVisible( false )
end

function xrCharScreen:onJoinProceedBtn()
	self.joinErrorWnd:setVisible( false )

	local firstChar = characters[ 1 ]
	if firstChar then
		fadeCamera( false, 0 )
		triggerServerEvent( "onCharacterJoin", resourceRoot, firstChar[ E_CHAR_NAME ], true )
	end
end

-- Мы хотим создать персонажа
function xrCharScreen:onCreateBtn()
	local name = self.nameEdt.text
	if utfLen( name ) < 6 then
		xrCharScreen:showErrorMessage( errorNameStr )
		return
	end

	triggerServerEvent( "onXrCharacterNew", resourceRoot, name, xrTeams[ self.selectedFaction ]._nameHash )
end

function xrCharScreen:onFactionSelect( factionIndex )
	self.selectedFaction = factionIndex
end

function xrCharScreen:onErrorWndBtn()
	if self.createCanvas then
		local wnd = self.createCanvas:getFrame( "Wnd", true )
		if wnd then
			wnd:setVisible( true )
		end

		wnd = self.createCanvas:getFrame( "NameErrorWnd", true )
		if wnd then
			wnd:setVisible( false )
		end
	end
end

function xrCharScreen:onRender()
	xrBackground:render()

	if self.createCanvas then
		self.createCanvas:draw()

		if not self.errorWnd.visible then
			local frame = self.selectedFaction == FACTION_STALKER and self.stalkerImg or self.banditImg
			dxDrawLineRect( frame.tx, frame.ty, frame.tw, frame.th, tocolor( 255, 100, 100 ), 3, false )
		end
	end

	if self.selectCanvas then
		self.selectCanvas:draw()
	end	

	if isElement( self.ped ) then
		setPedRotation ( self.ped, self.angle )		

		local character = characters[ 1 ]
		if character then
			local headx, heady, headz = getPedBonePosition ( self.ped, 7 )
			local x, y = getScreenFromWorldPosition ( headx, heady, headz + 0.2 )
			if x then
				local textWidth = dxGetTextWidth ( character[ E_CHAR_NAME ], 1, "default" )
				dxDrawText ( 
					character[ E_CHAR_NAME ], x - textWidth/2, y, 0, 0, 
					tocolor( _textColorSep[ 1 ], _textColorSep[ 2 ], _textColorSep[ 3 ] ), 0.55, self.font
				)			
				
				local rank = math.clamp( 0, 1000, tonumber( character[ E_CHAR_RANK ] ) or 0 )			
				local randIndex = math.floor( ( rank / 1000 ) * 4 )				
				local rankUI = uiHud[ randIndex ]
				if rankUI then
					dxDrawImageSection ( 
						x - 23, y - 50, 46, 47,
						rankUI.x, rankUI.y, rankUI.width, rankUI.height,
						"textures/ui_hud.dds",
						0, 0, 0,
						tocolor( 255, 255, 255 )
					)
				end
			end
		end
	end
end

function xrCharScreen:onCursorMove( _, _, ax, ay )
	if self.createCanvas then
		self.createCanvas:onCursorMove( ax, ay )
	end

	if self.selectCanvas then
		self.selectCanvas:onCursorMove( ax, ay )
	end		

	local x = ax - self.cursorx
	self.cursorx = ax 

	if getKeyState ( "mouse1" ) then
		self.angle = self.angle + x * 0.1745
	end
end

function xrCharScreen:onClick( button, state, absoluteX, absoluteY )
	if self.createCanvas then
		self.createCanvas:onCursorClick( button, state, absoluteX, absoluteY )
	end

	if self.selectCanvas then
		self.selectCanvas:onCursorClick( button, state, absoluteX, absoluteY )
	end	
end

function xrCharScreen:onCharacter( char )
	if self.createCanvas then
		self.createCanvas:onCharacter( char )
	end

	if self.selectCanvas then
		self.selectCanvas:onCharacter( char )
	end	
end

function xrCharScreen:onKey( key, state )
	if self.createCanvas then
		self.createCanvas:onKey( key, state )
	end

	if self.selectCanvas then
		self.selectCanvas:onKey( key, state )
	end	
end

function xrCharScreen:showErrorMessage( str )
	if self.createCanvas then
		local wnd = self.createCanvas:getFrame( "Wnd", true )
		if wnd then
			wnd:setVisible( false )
		end

		wnd = self.createCanvas:getFrame( "NameErrorWnd", true )
		if wnd then
			wnd:setVisible( true )
			wnd:getFrame( "NameErrorLbl" ):setText( str )
			wnd:forward()
		end
	end
end

addEvent( "onClientJoinError", true )
addEventHandler( "onClientJoinError", localPlayer,
	function( remainingSecs )
		if xrInterface.screen == xrCharScreen then
			local errorText = "До окончания выброса в зоне осталось " .. remainingSecs .. " секунд. При входе в игру вы можете в любой момент умереть. Хотите продолжить на свой страх и риск?"

			local textFrame = xrCharScreen.joinErrorWnd:getFrame( "ErrorLbl", true )
			textFrame:setText( errorText )
			textFrame:update()

			xrCharScreen.joinErrorWnd:setVisible( true )
		end
	end
, false )

addEvent( "onClientCharacterData", true )
addEventHandler( "onClientCharacterData", localPlayer,
	function( operationType, data )
		-- Получаем список всех персонажей
		if operationType == 1 then
			characters = data

		-- Получаем только что созданного персонажа
		elseif operationType == 2 then
			table.insert( characters, data )

			--[[
				Мы только что создали нового персонажа.
				Переходим на основной экран
			]]
			if xrInterface.screen == xrCharScreen then
				if xrCharScreen.createCanvas then
					xrCharScreen.createCanvas:destroy()
					xrCharScreen.createCanvas = nil
				end

				xrCharScreen:onFurtherJoint()
			end
		end		
	end
, false )

addEvent( "onClientSwitchLogin", true )
addEventHandler( "onClientSwitchLogin", localPlayer,
	function( screenName )
		if screenName then
			local screen = _G[ screenName ]
			if screen then
				xrInterface.start( screen, false )
			end
		else
			xrInterface.stop( false )
		end
	end
, false )

addEvent( "onClientGameLoaded", false )
addEventHandler( "onClientGameLoaded", localPlayer,
	function()
		-- Если мы авторизованы - показываем экран персонажа
		if xrIsLoggedIn then
			xrInterface.start( xrCharScreen, false )

		-- В противном случае показываем экран авторизации
		else
			xrInterface.start( xrLoginScreen, false )
		end
	end
, false )

local function xrInitTeams()
	local listSection = xrSettingsGetSection( _hashFn( "teams_list" ) )
    if not listSection then
        outputDebugString( "Не можем найти список группировок", 2 )
        return
    end

    for i, section in ipairs( listSection ) do
        xrTeamHashes[ section._nameHash ] = section
		xrTeams[ i ] = section
    end
	
	return #xrTeams > 0
end

addEvent( "onClientCoreStarted", false )
addEventHandler( "onClientCoreStarted", root,
	function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
		xrIncludeModule( "player.lua" )
		xrIncludeModule( "global.lua" )

		if not xrSettingsInclude( "teams.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации команд!", 2 )
            return
		end
		
		if not xrInitTeams() then
			outputDebugString( "Ни одной команды не было найдено!", 2 )
			return
		end

		xrLoadUIColorDict( "color_defs" )
		xrLoadAllUIFileDescriptors()

		-- Load the scene
		do
			local txd = engineLoadTXD ( "models/" .. sceneInfo.tex .. ".txd", true )
			local col = engineLoadCOL ( "models/" .. sceneInfo.col .. ".col" )
			local dff = engineLoadDFF ( "models/" .. sceneInfo.geom .. ".dff", 0 )
			
			if txd and col and dff then
				engineImportTXD ( txd, sceneInfo.model )
				engineReplaceCOL ( col, sceneInfo.model )
				engineReplaceModel ( dff, sceneInfo.model, true )
			else
				outputDebugString ( "Error occurs while scene loading" )
			end
		end

		xrIsLoggedIn = false
	end
)
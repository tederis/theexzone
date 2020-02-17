local sw, sh = guiGetScreenSize ( )

xrMain = {
	isEnabled = false
}

INPUT_GLOBAL = 1
INPUT_FACTION = 2
INPUT_GROUP = 3
INPUT_ADMIN = 4

VOLUME_NORMAL = 1
VOLUME_WHISPER = 2
VOLUME_LOUD = 3
VOLUME_FIRST = 4
VOLUME_THIRD = 5
VOLUME_TRY = 6
-- Temp
VOLUME_ALL = 7

local modeNames = {
	"(Обычный)",
	"(Фракция)",
	"(Группа)",
	"(Админ)"
}

local volumeNames = {
	"(Рядом)",
	"(Шепот)",
	"(Крик)",
	"(Действие)",
	"(Описание)",
	"(Попытка)",
	"(Миру)"
}

local volumeCastNames = {
	"",
	"(Шепотом)",
	"(Кричит)"
}

function xrMain.init()
	local height = sh * 0.4
	local width = sw * 0.3
	
	xrMain.canvas = xrCreateUICanvas( 0, 0, width, height )

	local xml = xmlLoadFile( "qwerty.xml", true )
	if xml then
		xrMain.canvas:load( xml )

		xmlUnloadFile( xml )
	end

	xrMain.inputField = xrMain.canvas:getFrame( "EditField", true ):addHandler( xrMain.onTextAccepted, xrMain )
	xrMain.messagesList = xrMain.canvas:getFrame( "PaneList", true ):setChildLimit( 50 )
	xrMain.helpBar = xrMain.canvas:getFrame( "HelpBar", true ):setVisible( false )
	xrMain.inputBar = xrMain.canvas:getFrame( "Str", true ):setVisible( false )

	xrMain.canvas:update()

	showChat( false )

	bindKey( "t", "down", xrMain.onChatOpenKey )
	bindKey( "y", "down", xrMain.onChatOpenKey )
	bindKey( "u", "down", xrMain.onChatOpenKey )
	bindKey( "o", "down", xrMain.onChatOpenKey )
end

function xrMain.onChatOpenKey( key )
	-- Если открыт какой-либо другой интерфейс - запрещаем показ чата
	if getElementData( localPlayer, "uib", false ) then
		return
	end

	if not xrMain.inputMode then
		if key == "t" then
			xrMain:setVolume( VOLUME_NORMAL )
			xrMain:setInputMode( INPUT_GLOBAL )
		elseif key == "y" then
			xrMain:setInputMode( INPUT_FACTION )
		elseif key == "u" then
			xrMain:setInputMode( INPUT_GROUP )
		elseif key == "o" then
			xrMain:setInputMode( INPUT_ADMIN )
		end
	end
end

function xrMain:open()	
	if xrMain.isEnabled then
		return
	end	

	addEventHandler( "onClientRender", root, xrMain.onRender, false )
	addEventHandler( "onClientCursorMove", root, xrMain.onCursorMove, false )
	addEventHandler( "onClientClick", root, xrMain.onCursorClick, false )
	addEventHandler( "onClientCharacter", root, xrMain.onCharacter, false )
	addEventHandler( "onClientKey", root, xrMain.onKey, false )

	self.inputMode = false
	self.volume = VOLUME_NORMAL

	self.lastChatState = false
	self.lastChatChangeTime = getTickCount()

	self:setInputMode( false )
	self:setVolume( VOLUME_NORMAL )
	
	xrMain.isEnabled = true
end

function xrMain:close()
	if xrMain.isEnabled then
		removeEventHandler( "onClientRender", root, xrMain.onRender )
		removeEventHandler( "onClientCursorMove", root, xrMain.onCursorMove )
		removeEventHandler( "onClientClick", root, xrMain.onCursorClick )
		removeEventHandler( "onClientCharacter", root, xrMain.onCharacter )
		removeEventHandler( "onClientKey", root, xrMain.onKey, false )

		xrMain.inputField:setText( "" )
		self:setInputMode( false )
	
		xrMain.isEnabled = false

		setElementData( localPlayer, "chat", false )
	end
end

function xrMain:onTextAccepted()
	local now = getTickCount()
	local text = source.text

	local ok = true
	if utfLen( text ) == 0 then
		ok = false
	end

	if self.lastMsg and text == self.lastMsg then
		outputChatBox( "Повтор сообщений запрещен" )
		ok = false
	end

	if self.lastMsgTime and now - self.lastMsgTime < 1000 then
		outputChatBox( "Частота отправки сообщений ограничена" )
		ok = false
	end

	if ok then
		self.lastMsg = text
		self.lastMsgTime = now

		triggerServerEvent( "onCustomMessage", resourceRoot, text, self.inputMode, self.volume )
	end

	source:setText( "" )
	self:setInputMode( false )
end

function xrMain.onRender()
	local now = getTickCount()

	xrMain.canvas:draw()

	--[[
        Обновляем состояние чата
    ]]
    local chatState = type( xrMain.inputMode ) == "number"
    if chatState ~= xrMain.lastChatState and now - xrMain.lastChatChangeTime >= 1000 then
        xrMain.lastChatState = chatState
        xrMain.lastChatChangeTime = now

        setElementData( localPlayer, "chat", chatState )
    end
end

function xrMain.onCursorMove( _, _, ax, ay )
	xrMain.canvas:onCursorMove( ax, ay )
end

function xrMain.onCursorClick( btn, state, ax, ay )	
	xrMain.canvas:onCursorClick( btn, state, ax, ax )
end

function xrMain.onCharacter( char )
	if xrMain.firstLock then
		xrMain.firstLock = false
		return
	end

	if xrMain.inputMode then
		xrMain.canvas:onCharacter( char )
	end
end

function xrMain.onKey( btn, pressed )
	if xrMain.inputMode then
		if btn == "escape" and pressed then
			xrMain:setInputMode( false )
			xrMain.inputField:setText( "" )		
			cancelEvent()
		elseif xrMain.inputMode == INPUT_GLOBAL then
			if btn == "F1" and pressed then
				xrMain:setVolume( VOLUME_NORMAL )
			elseif btn == "F2" and pressed then
				xrMain:setVolume( VOLUME_WHISPER )
			elseif btn == "F3" and pressed then
				xrMain:setVolume( VOLUME_LOUD )
			elseif btn == "F4" and pressed then
				xrMain:setVolume( VOLUME_FIRST )
			elseif btn == "F5" and pressed then
				xrMain:setVolume( VOLUME_THIRD )
			elseif btn == "F6" and pressed then
				xrMain:setVolume( VOLUME_TRY )

			-- Temp
			elseif btn == "F7" and pressed then
				xrMain:setVolume( VOLUME_ALL )
			end
		end

		xrMain.canvas:onKey( btn, pressed )	
	end

	if pressed then
		if btn == "pgup" then
			xrMain.messagesList:setScrollValue( math.min( xrMain.messagesList.scrollValue + 10, 0 ) )
		elseif btn == "pgdn" then
			local delta = math.max( xrMain.messagesList.contentHeight - xrMain.messagesList.th, 0 )
			xrMain.messagesList:setScrollValue( math.max( xrMain.messagesList.scrollValue - 10, -delta ) )
		end
	end
end

function xrMain:setInputMode( mode )
	if mode == self.inputMode then
		return
	end

	if mode then
		guiSetInputEnabled( true )
		xrMain.canvas:setInputFrame( xrMain.inputField )
		self.inputMode = mode
		self.firstLock = true

		if mode == INPUT_GLOBAL then
			xrMain.helpBar:setVisible( true )
			xrMain.inputField:setPrefix( modeNames[ mode ] .. volumeNames[ self.volume ] .. " " )
		else
			xrMain.inputField:setPrefix( modeNames[ mode ] .. " " )
		end
		xrMain.inputBar:setVisible( true )
	else
		guiSetInputEnabled( false )
		xrMain.canvas:setInputFrame( false )
		self.inputMode = false
		self.firstLock = false

		xrMain.helpBar:setVisible( false )
		xrMain.inputBar:setVisible( false )
	end
end

function xrMain:setVolume( volume )
	if volume == self.volume then
		return
	end	

	if self.inputMode == INPUT_GLOBAL then
		xrMain.inputField:setPrefix( modeNames[ self.inputMode ] .. volumeNames[ volume ] .. " " )	
	end

	self.volume = volume
end

function xrMain:pushMessage( message, srcPlayer, msgType, msgVolume, msgState )	
	local msgTbl = {}

	if getElementType( srcPlayer ) == "player" then
		local name = getElementData( srcPlayer, "name", false )
		local nameR, nameG, nameB = 255, 255, 255

		local team = getPlayerTeam( srcPlayer )
		if team then
			nameR, nameG, nameB = getTeamColor( team )
		end

		if msgType == INPUT_GLOBAL then 
			if msgVolume < VOLUME_FIRST then
				msgTbl = {					
					"#FFFFFF", volumeCastNames[ msgVolume ], RGBToHex( nameR, nameG, nameB ), name, ": #FFFFFF", message
				}
			elseif msgVolume == VOLUME_FIRST then
				msgTbl = {					
					RGBToHex( nameR, nameG, nameB ), name, " #FFB6C1", message
				}
			elseif msgVolume == VOLUME_THIRD then
				msgTbl = {					
					"#FFEBCD*", message, " #FFFFFF(", RGBToHex( nameR, nameG, nameB ), name, "#FFFFFF)"
				}
			elseif msgVolume == VOLUME_TRY then
				msgTbl = {					
					RGBToHex( nameR, nameG, nameB ), name, " #DAA520попытался ", utf8.lower( message ), ( msgState == true and " #FFFFFF(Удачно)" or " #FFFFFF(Неудачно)" )
				}

			-- Temp
			elseif msgVolume == VOLUME_ALL then
				local teamName = ""
				if team then
					teamName = getElementData( team, "text", false )
				end

				msgTbl = {
					"#FFFFFF(", teamName, ") ",
					RGBToHex( nameR, nameG, nameB ), name, ": #FFFFFF", message
				}
			end
		elseif msgType == INPUT_FACTION then
			local teamName = ""
			if team then
				teamName = getElementData( team, "text", false )
			end

			msgTbl = {
				"#FFFFFF(", teamName, ") ",
				RGBToHex( nameR, nameG, nameB ), name, ": #FFFFFF", message
			}
		elseif msgType == INPUT_ADMIN then
			msgTbl = {
				"#FFFFFF(Админ) ",
				RGBToHex( nameR, nameG, nameB ), name, ": #FFFFFF", message
			}
		end
	else
		msgTbl = {
			message
		}
	end

	local frame = self.messagesList:createChild( "text", "Msg" )
	if frame then
		frame:setWordBreak( true )
		frame:setSize( self.messagesList.originWidth, 0 )
		frame:setHorizontalAlign( HOR_MODE_STRETCH )
		frame:setVerticalAlign( VERT_MODE_TOP )
		frame:setText( table.concat( msgTbl ) )
		frame:setFont( "default-bold" )
		frame:setColorCoded( true )
	end

	self.canvas:update()

	local delta = math.max( xrMain.messagesList.contentHeight - xrMain.messagesList.th, 0 )
	xrMain.messagesList:setScrollValue( -delta )
end

local function onCustomMessage( msg, msgSource, msgType, msgVolume, msgState )
	xrMain:pushMessage( msg, msgSource, msgType, msgVolume, msgState )
end

local function onDefaultChatMessage( text, r, g, b )
	xrMain:pushMessage( text, source, INPUT_GLOBAL, VOLUME_NORMAL )
end

--[[
	Exports
]]
function xrShowChat( state )
	if state then
		xrMain:open()	
	else
		xrMain:close()
	end
end

--[[
	Init
]]
addEventHandler( "onClientCoreStarted", root,
--addEventHandler( "onClientResourceStart", resourceRoot,
	function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
		xrIncludeModule( "global.lua" )

		if not xrSettingsInclude( "teams.ltx" ) then
            return
        end	

		xrLoadAllUIFileDescriptors()

		xrMain.init()
		xrMain:open()

		addEvent( "onClientCustomMessage", true )
		addEventHandler( "onClientCustomMessage", resourceRoot, onCustomMessage, false )
		addEventHandler( "onClientChatMessage", root, onDefaultChatMessage )
    end
)
local sw, sh = guiGetScreenSize ( )

function tryToFitRectangle( x0, y0, width0, height0, x1, y1, width1, height1 )
	if x0 > x1 + width1 or y0 > y1 + height1 then
		return false
	end
	if x0 + width0 < x1 or y0 + height0 < y1 then
		return false
	end
	return true
end

--[[
	UIFrame
	Отрисовка рамки
]]
UIFrame = { }
UIFrame.__index = UIFrame

function UIFrame.new ( x, y, width, height )
	local frame = {
		x = x, y = y,
		width = math.max ( width, 128 ), height = math.max ( height, 128 )
	}
	return setmetatable ( frame, UIFrame )
end

function UIFrame:draw ( )
	local _x = self.x
	local _y = self.y
	dxDrawImage ( _x, _y, 64, 64, "textures/ui_frame_03/ui_frame_03_lt.dds" )
	_x = _x + 64
	local _width = self.width - 128
	dxDrawImageSection ( _x, _y, _width, 64, 0, 0, 128 * (_width/128), 64, "textures/ui_frame_03/ui_frame_03_t.dds" )
	_x = _x + _width
	dxDrawImage ( _x, _y, 64, 64, "textures/ui_frame_03/ui_frame_03_rt.dds" )
	_x = self.x
	_y = _y + 64
	local _height = self.height - 128
	dxDrawImageSection ( _x, _y, 64, _height, 0, 0, 64, 128 * (_height/128), "textures/ui_frame_03/ui_frame_03_l.dds" )
	_x = _x + 64 + _width
	dxDrawImageSection ( _x, _y, 64, _height, 0, 0, 64, 128 * (_height/128), "textures/ui_frame_03/ui_frame_03_r.dds" )
	_x = self.x
	_y = _y + _height
	dxDrawImage ( _x, _y, 64, 64, "textures/ui_frame_03/ui_frame_03_lb.dds" )
	_x = _x + 64
	dxDrawImageSection ( _x, _y, _width, 64, 0, 0, 128 * (_width/128), 64, "textures/ui_frame_03/ui_frame_03_b.dds" )
	_x = _x + _width
	dxDrawImage ( _x, _y, 64, 64, "textures/ui_frame_03/ui_frame_03_rb.dds" )
	_x = self.x + 64
	_y = self.y + 64
	dxDrawImageSection ( _x, _y, _width, _height, 0, 0, 64 * (_width/64), 64 * (_height/64), "textures/ui_frame_03/ui_frame_03_back.dds" )
end

function isPointInRectangle ( px, py, rx, ry, rw, rh )
	return ( px >= rx and px <= rx + rw ) and ( py >= ry and py <= ry + rh )
end

function getRealTextHeight( text, scale, font, width )
	local words = split( text, 32 ) -- space
	local fontHeight = dxGetFontHeight ( scale, font )
	local spaceWidth = dxGetTextWidth ( " ", scale, font )

	local lineWidth = 0
	local height = fontHeight

	for _, word in ipairs( words ) do
		lineWidth = lineWidth + spaceWidth
		if lineWidth >= width then
			height = height + fontHeight
			lineWidth = spaceWidth
		end

		local wordWidth = dxGetTextWidth( word, scale, font )
		lineWidth = lineWidth + wordWidth
		if lineWidth >= width then
			height = height + fontHeight
			lineWidth = wordWidth
		end
	end
	
	return height
end

function resizeControls( ctrls, width, height )
	local factor = sw / width
	local factor2 = sh / height
	
	g_FactorH = factor
	g_FactorV = factor2
	
	for _, control in pairs( ctrls ) do
		if type ( control ) == "table" then
			control.x = control.x * factor
			control.y = control.y * factor2
		
			control.width = control.width * factor
			control.height = control.height * factor2
		end
	end
end

local _scale = function ( x, y )
	x = tonumber ( x ) or 0
	y = tonumber ( y ) or 0
	
	return x * g_FactorH, y * g_FactorV
end

--[[
	xrTalk
]]
xrTalk = {
	ourIcon = {
		x = 27, y = 22,
		width = 143, height = 199
	},
	icon = {
		x = 843, y = 22,
		width = 143, height = 199
	},
	dialogFrame = {
		x = 215, y = 42,
		width = 588, height = 470
	},
	ourPhrasesFrame = {
		x = 215, y = 540,
		width = 588, height = 177
	},
	phrasesList = {
		x = 20, y = 20,
		width = 557, height = 125
	},
	logList = {
		x = 20, y = 20,
		width = 557, height = 417
	},
	tradeBtn = {
		x = 458, y = 722,
		width = 107, height = 36
	}
}
resizeControls( xrTalk, 1024, 768 )

local logMessages = { }
local myPhrases = { }
local selectedPhrase
local logPhraseHeight = 0
local caretPos = 0

FONT_SCALE = 0.66

INFO_ASPECT = 83 / 47
INFO_HEIGHT = sh * 0.05
INFO_WIDTH = INFO_HEIGHT * INFO_ASPECT

function xrTalk.init()
	xrTalk.font = dxCreateFont ( "AG Letterica Roman Medium.ttf", sh / 50, true )
	xrTalk.font2 = dxCreateFont ( "AG Letterica Roman Medium.ttf", sh / 44, true )

	-- Создаем RT для прокрутки лога
	local control = xrTalk.logList
	xrTalk.rt = dxCreateRenderTarget ( control.width, control.height, true )
end

function xrTalk.open( ped )
	if xrTalk.isOpened then
		return false
	end

	local classHash = tonumber( getElementData ( ped, "cl", false ) )
	
	local desc = xrSystem.getCharacterDescription( classHash )
	if desc == nil then
		outputDebugString ( "Для педа не было найдено описания", 2 )
		return false
	end
	
	xrTalk.ped = ped
	xrTalk.pedDesc = desc
	xrTalk.paused = false
	xrTalk.tradeBtnState = false

	logMessages = { }
	myPhrases = { }
	selectedPhrase = nil
	logPhraseHeight = 0
	caretPos = 0	

	g_Frame = UIFrame.new ( xrTalk.dialogFrame.x, xrTalk.dialogFrame.y, xrTalk.dialogFrame.width, xrTalk.dialogFrame.height )
	g_Frame2 = UIFrame.new ( xrTalk.ourPhrasesFrame.x, xrTalk.ourPhrasesFrame.y, xrTalk.ourPhrasesFrame.width, xrTalk.ourPhrasesFrame.height )

	showCursor( true )
	exports.sp_chatbox:xrShowChat( false )

	addEventHandler ( "onClientRender", root, xrTalk.onRender, false )
	addEventHandler ( "onClientCursorMove", root, xrTalk.onCursorMove, false )
	addEventHandler ( "onClientClick", root, xrTalk.onClick, false )
	addEventHandler ( "onClientKey", root, xrTalk.onKey, false )

	xrTalk.isOpened = true

	setElementData( localPlayer, "uib", true, true )
	exports.sp_hud_real_new:xrHUDSetEnabled( false )

	return true
end

function xrTalk.close()
	if xrTalk.isOpened then
		g_Frame = nil
		g_Frame2 = nil

		showCursor( false )	
		exports.sp_chatbox:xrShowChat( true )

		removeEventHandler ( "onClientRender", root, xrTalk.onRender )
		removeEventHandler ( "onClientCursorMove", root, xrTalk.onCursorMove )
		removeEventHandler ( "onClientClick", root, xrTalk.onClick )
		removeEventHandler ( "onClientKey", root, xrTalk.onKey )

		xrTalk.isOpened = false
		
		logMessages = nil

		setElementData( localPlayer, "uib", false, true )

		exports.sp_hud_real_new:xrHUDSetEnabled( true )
	end
end

function xrTalk.sendMessage( typeHash, ... )
	local control = xrTalk.logList

	local msgImpl = g_InfoTypes[ typeHash ]
	if not msgImpl then
		outputDebugString( "Такого типа сообщений не существует!", 2 )
		return
	end

	local msg, msgHeight = msgImpl:onCreate( logPhraseHeight, ... )
	if msg then
		table.insert( logMessages, msg )	

		logPhraseHeight = logPhraseHeight + msgHeight
		caretPos = math.max( logPhraseHeight - control.height, 0 )
	end
end

function xrTalk.addPhrase( text )
	table.insert ( myPhrases, text )
end

function xrTalk.onRender()
	if xrTalk.paused then
		return
	end

	local fontHeight = dxGetFontHeight ( FONT_SCALE, xrTalk.font )

	local control = xrTalk.ourIcon
	--dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 143, 199, "textures/ui_trade_character.dds" )

	control = xrTalk.icon
	--dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 143, 199, "textures/ui_trade_character.dds" )

	--[[
		Поле ответов от собеседника
	]]
	g_Frame:draw ( )
	
	control = xrTalk.logList
	local _x = xrTalk.dialogFrame.x + control.x
	local _y = xrTalk.dialogFrame.y + control.y
	
	dxSetRenderTarget ( xrTalk.rt, true )
	local bias = 0
	if logPhraseHeight > control.height then
		bias = -caretPos

		local _width = 10
		local _height = control.height * ( control.height / logPhraseHeight )
		dxDrawRectangle( control.width - _width, ( control.height - _height ) * ( caretPos / ( logPhraseHeight - control.height ) ), _width, _height, tocolor( 186, 127, 46 ) )
	end
	
	for i, msg in ipairs( logMessages ) do
		-- Отсекаем невидимые сообщения
		if tryToFitRectangle( 0, bias + msg.ypos, control.width, msg.height, 0, 0, control.width, control.height ) then
			msg:onDraw( bias )
		end
	end	
	dxSetRenderTarget ( )
	dxDrawImage ( _x, _y, control.width, control.height, xrTalk.rt )
	
	--[[
		Поле наших вариантов ответов
	]]
	g_Frame2:draw ( )

	control = xrTalk.phrasesList
	_x = xrTalk.ourPhrasesFrame.x + control.x
	_y = xrTalk.ourPhrasesFrame.y + control.y

	for i, text in ipairs ( myPhrases ) do
		local bias = _y + ( fontHeight * ( i - 1 ) )

		local textColor = tocolor ( 186, 127, 46 )
		if i == selectedPhrase then
			textColor = tocolor ( 255, 241, 221 )
		end

		dxDrawText ( text, _x, bias, _x + control.width, 0, textColor, FONT_SCALE, xrTalk.font )
	end

	width, height = _scale ( 1024, 32 )
	dxDrawImage ( 0, sh - height, width, height, "textures/ui_bottom_background.dds" )

	if xrTalk.pedDesc.trade then
		control = xrTalk.tradeBtn
		dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 107, 36, "textures/ui_button_05.dds" )
		dxDrawText ( "Торговать", control.x, control.y, control.x + control.width, control.y + control.height, tocolor ( 238, 153, 26 ), 0.8, xrTalk.font, "center", "center" )
	end
end

function xrTalk.onCursorMove( _, _, ax, ay )
	if xrTalk.paused then
		return
	end

	if xrTalk.pedDesc.trade then
		local control = xrTalk.tradeBtn
		xrTalk.tradeBtnState = isPointInRectangle( ax, ay, control.x, control.y, control.width, control.height )
		if xrTalk.tradeBtnState then
			return
		end
	end

	local control = xrTalk.phrasesList
	local _x = xrTalk.ourPhrasesFrame.x + control.x
	local _y = xrTalk.ourPhrasesFrame.y + control.y
	
	selectedPhrase = nil
	
	if isPointInRectangle( ax, ay, _x, _y, control.width, control.height ) then
		local fontHeight = dxGetFontHeight( FONT_SCALE, xrTalk.font )
		selectedPhrase = math.floor( ( ay - _y ) / fontHeight ) + 1
	end
end

function xrTalk.onClick( btn, state )
	if state ~= "down" or xrTalk.paused then
		return
	end
	
	if xrTalk.tradeBtnState then
		--xrTalk.paused = true
		xrTalk.close()
		triggerServerEvent( EServerEvents.onDialogTradeStart, localPlayer )
		
		return
	end
	
	if selectedPhrase and selectedPhrase <= #myPhrases then
		xrTalk.sendMessage( EHashes.MessageText, myPhrases[ selectedPhrase ], getElementData( localPlayer, "name", false ) )

		triggerServerEvent( EServerEvents.onDialogPhraseSelect, localPlayer, selectedPhrase )
	end
end

function xrTalk.onKey( button )
	if xrTalk.paused then
		return
	end

	local control = xrTalk.logList
	local factor = ( control.height / logPhraseHeight ) * 60
	if button == "mouse_wheel_up" then
		caretPos = math.max ( caretPos - factor, 0 )
	elseif button == "mouse_wheel_down" then
		caretPos = math.min ( caretPos + factor, logPhraseHeight - control.height )
	end
end

local function onDialogData( operation, answerData, variantsData, ped )
	if operation == 1 then
		if not xrTalk.open( ped ) then
			outputDebugString( "Ошибка создания интерфейса диалога!", 2 )
			return
		end
	elseif operation == 3 then
		xrTalk.close()
		return
	elseif operation == 4 then
		xrTalk.paused = false
	elseif operation == 5 then
		-- Здесь answerData, variantsData, ped могут быть чем угодно
		xrTalk.sendMessage( answerData, variantsData, ped )
		return
	end

	--[[
		Добавляем ответ собеседника в список
	]]
	if type( answerData ) == "table" then
		local answerDialogDef = xrSystem.getDialog( answerData[ 1 ] )
		if answerDialogDef then
			local phrase = answerDialogDef.phrases[ answerData[ 2 ] ]
			if phrase then
				xrTalk.sendMessage( EHashes.MessageText, phrase.text or xrSystem.getText( phrase.textHash ), xrTalk.pedDesc.name )
			else
				outputDebugString( "Не можем найти фразу!", 2 )
			end
		else
			outputDebugString( "Не можем найти данный диалог!", 2 )
		end
	end

	--[[
		Добавляем наши варианты ответов
	]]
	myPhrases = { 
		-- Очищаем предыдущие ответы
	}
	for i, variantData in ipairs( variantsData ) do
		local answerDialogDef = xrSystem.getDialog( variantData[ 1 ] )
		if answerDialogDef then
			local phrase = answerDialogDef.phrases[ variantData[ 2 ] ]
			if phrase then
				xrTalk.addPhrase( phrase.text or xrSystem.getText( phrase.textHash ) )
			else
				outputDebugString( "Не можем найти фразу!", 2 )
			end
		else
			outputDebugString( "Не можем найти данный диалог!", 2 )
		end			
	end
end

addEventHandler( "onClientCoreStarted", root,
	function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "global.lua" )
		xrIncludeModule( "config.lua" )
		xrIncludeModule( "uiconfig.lua" )
		xrIncludeModule( "locale.lua" )

		if not xrSettingsInclude( "items_only.ltx" ) then
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

		xrLoadUIFileDescriptor( "ui_iconstotal" )

		addEvent( EClientEvents.onClientDialogData, true )
		addEventHandler( EClientEvents.onClientDialogData, localPlayer, onDialogData, false )

		xrSystem.init()
		xrTalk.init()
		
		initInfoTypes()
    end
)
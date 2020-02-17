local HASH_BREAK_DIALOG = _hashFn( "actor_break_dialog" )

g_Hashes = {
	-- Определения действий в диалогах
}

local _actionName = nil
local _actionCreate = function( tbl )
	local nameHash = _hashFn( _actionName )
	g_Hashes[ nameHash ] = tbl
end
local function Hashed( name )
	_actionName = name
	return _actionCreate
end

function xrDialogStart( player, ped )
	local classHash = tonumber( getElementData( ped, "cl", false ) )
	local desc = xrSystem.getCharacterDescription( classHash )
	if not desc then 
		outputDebugString( "Описания для данного педа не было найдено", 1 )
		return false
	end

	local dialog = {
		player = player,
		ped = ped,
		pedDesc = desc,
		items = {
			-- Текущие варианты ответов
		},
		order = {

		}
	}

	-- Стартовое приветствие
	local startDef = xrSystem.getDialog ( desc.start_dialog )
	if startDef then
		xrDialogInsertDefaultItems( dialog )

		-- Отправляем сообщение о начале диалога
		local greetingPhraseData = {
			desc.start_dialog, -- Хэш диалога
			0 -- Индекс фразы в этом диалоге
		}
		triggerClientEvent( dialog.player, EClientEvents.onClientDialogData, dialog.player, 1, greetingPhraseData, dialog.items, ped )
	else
		outputDebugString ( "Стартовый диалог не был найден", 2 )
		return false
	end

	return dialog
end

function xrDialogStop( dialog )
	-- Отправляем сообщение о конце диалога
	triggerClientEvent( dialog.player, EClientEvents.onClientDialogData, dialog.player, 3 )
end

local function xrPerformDialogSelection( dialog, def )
	for _, infoHash in ipairs( def.has_info or EMPTY_TABLE ) do
		if not exports.sp_player:xrGetPlayerInfo( dialog.player, infoHash ) then
			return false
		end
	end
	
	for _, infoHash in ipairs( def.dont_has_info or EMPTY_TABLE ) do
		if exports.sp_player:xrGetPlayerInfo( dialog.player, infoHash ) then
			return false
		end
	end

	--[[
		Проверяем так же первую фразу
	]]
	local firstPhrase = def.phrases[ 0 ]
	if not firstPhrase or xrPerformPhraseSelection( dialog, firstPhrase ) ~= true then
		return false
	end

	return true
end

function xrDialogInsertDefaultItems( dialog )
	local classHash = tonumber( getElementData ( dialog.ped, "cl", false ) )
	local desc = xrSystem.getCharacterDescription ( classHash )
	if not desc then 
		outputDebugString( "Описания для данного педа не было найдено", 1 )
		return false
	end
	
	--[[
		Заполняем список диалогов
	]]
	for _, dialogHash in ipairs ( desc.actor_dialogs ) do
		local def = xrSystem.getDialog ( dialogHash )
		if def and xrPerformDialogSelection( dialog, def ) then
			table.insert( dialog.items, { dialogHash, 0 } )
		end
	end
	
	local breakDef = xrSystem.getDialog ( HASH_BREAK_DIALOG )
	if breakDef then
		table.insert( dialog.items, { HASH_BREAK_DIALOG, 0 } )
	else
		outputDebugString ( "Конечный диалог не был найден", 2 )
		return false
	end

	return true
end

function xrPerformPhraseSelection( dialog, phrase )
	for _, preconditionData in ipairs( phrase.precondition or EMPTY_TABLE ) do
		local res = preconditionData[ 1 ]
		local fnName = preconditionData[ 2 ]
		
		local result = true
		if res == resource then
			result = _G[ fnName ]( dialog.player )
		else
			result = call( res, fnName, dialog.player )
		end

		if not result then
			return false
		end
	end			

	for _, infoHash in ipairs( phrase.has_info or EMPTY_TABLE ) do
		if not exports.sp_player:xrGetPlayerInfo( dialog.player, infoHash ) then
			return false
		end
	end

	for _, infoHash in ipairs( phrase.dont_has_info or EMPTY_TABLE ) do
		if exports.sp_player:xrGetPlayerInfo( dialog.player, infoHash ) then
			return false
		end
	end

	return true
end

function xrDialogSelectItem( dialog, index )
	local item = dialog.items[ index ]
	if not item then
		outputDebugString( "Такого пункта нет!", 1 )
		return false
	end

	local def = xrSystem.getDialog( item[ 1 ] )
	if not def then
		outputDebugString( "Такого диалога нет!", 1 )
		return false
	end	

	local defPhrases = def:getPhrases()
	local selectedPhrase = defPhrases[ item[ 2 ] ]
	if not selectedPhrase then
		outputDebugString( "Выбранной фразы не существует!", 1 )
		return false
	end

	dialog.items = {
		-- Очищаем
	}
	dialog.order = {

	}

	-- Если есть действие - выполняем
	for _, actionData in ipairs( selectedPhrase.action or EMPTY_TABLE ) do
		local res = actionData[ 1 ]
		local fnName = actionData[ 2 ]
		
		local result = false
		if res == resource then
			result = _G[ fnName ]( dialog.player )
		else
			result = call( res, fnName, dialog.player )
		end

		if result then
			xrPlayerStopTalk( dialog.player )
			return true
		end
	end	

	--[[
		1. Получаем ответную фразу от собеседника
	]]	
	local answerPhraseIndex = nil
	local answerPhrase = nil
	for _, phraseIndex in ipairs( selectedPhrase.nextPhrases ) do
		local phrase = defPhrases[ phraseIndex ]
		if phrase then
			for _, actionData in ipairs( phrase.action or EMPTY_TABLE ) do
				local res = actionData[ 1 ]
				local fnName = actionData[ 2 ]
				
				local result = false
				if res == resource then
					result = _G[ fnName ]( dialog.player )
				else
					result = call( res, fnName, dialog.player )
				end
				
				if result then
					-- TODO
				end
			end

			local condition = xrPerformPhraseSelection( dialog, phrase )

			for _, infoHash in ipairs( phrase.give_info or EMPTY_TABLE ) do
				exports.sp_player:xrSetPlayerInfo( dialog.player, infoHash, true )
			end

			for _, infoHash in ipairs( phrase.disable_info or EMPTY_TABLE ) do
				exports.sp_player:xrRemovePlayerInfo( dialog.player, infoHash )
			end

			if condition then
				answerPhraseIndex = phraseIndex
				answerPhrase = phrase
				break
			end
		else
			outputDebugString( "Такой фразы не существует!", 1 )
		end
	end	

	-- Если ни одна фраза не найдена - возвращаемся в список диалогов
	if not answerPhrase then
		xrDialogInsertDefaultItems( dialog )
		triggerClientEvent( dialog.player, EClientEvents.onClientDialogData, dialog.player, 2, false, dialog.items )
		for _, packed in ipairs( dialog.order ) do
			triggerClientEvent( dialog.player, EClientEvents.onClientDialogData, dialog.player, 5, unpack( packed ) )
		end

		return
	end

	--[[
		2. Ищем наши(игрока) вопросные фразы
	]]
	for _, phraseIndex in ipairs( answerPhrase.nextPhrases ) do
		local phrase = defPhrases[ phraseIndex ]
		if phrase then
			local condition = xrPerformPhraseSelection( dialog, phrase )

			for _, infoHash in ipairs( phrase.give_info or EMPTY_TABLE ) do
				exports.sp_player:xrSetPlayerInfo( dialog.player, infoHash, true )
			end

			for _, infoHash in ipairs( phrase.disable_info or EMPTY_TABLE ) do
				exports.sp_player:xrRemovePlayerInfo( dialog.player, infoHash )
			end

			if condition then				
				table.insert( dialog.items, { item[ 1 ], phraseIndex } )
			end
		else
			outputDebugString( "Такой фразы не существует!", 1 )
		end
	end

	-- Если мы не располагаем доступными фразами - возвращаемся
	if #dialog.items == 0 then
		xrDialogInsertDefaultItems( dialog )		
	end

	-- Отправляем сообщение о начале диалога
	local answerPhraseData = {
		item[ 1 ], -- Хэш диалога
		answerPhraseIndex -- Индекс фразы в этом диалоге
	}
	triggerClientEvent( dialog.player, EClientEvents.onClientDialogData, dialog.player, 2, answerPhraseData, dialog.items )
	for _, packed in ipairs( dialog.order ) do
		triggerClientEvent( dialog.player, EClientEvents.onClientDialogData, dialog.player, 5, unpack( packed ) )
	end
	
	return false
end

function xrDialogGiveItem( dialog, itemHash, slotHash, count )
	count = tonumber( count ) or 1

	local itemId = exports.xritems:xrContainerInsertItem( dialog.player, itemHash, slotHash, count, true )
	if itemId then
		-- Ставим в очередь для корректного показа после сообщения
		table.insert( dialog.order, { EHashes.MessageGiveItem, itemHash, count } )

		return itemId
	end
end

function xrDialogGiveMoney( dialog, value )
	exports[ "sp_player" ]:xrGivePlayerMoney( dialog.player, value )
	-- Ставим в очередь для корректного показа после сообщения
	table.insert( dialog.order, { EHashes.MessageFoundMoney, value } )
end

function xrDialogGiveRank( dialog, value )
	exports.sp_player:xrAddPlayerRank( dialog.player, value )
	-- Ставим в очередь для корректного показа после сообщения
	table.insert( dialog.order, { EHashes.MessageRankIncrease, value } )
end

function xrDialogStartTrade( dialog )
	if dialog.pedDesc.trade then
		xrPlayerStopTalk( dialog.player )
		exports.sp_inventory:xrStartInventorySession( dialog.player, dialog.ped )
	end
end

local function onPlayerDialogPhraseSelect( phraseIndex )
	local talk = xrPlayerTalks[ client ]
	if talk then
		xrDialogSelectItem( talk, phraseIndex )
	else
		outputDebugString( "Игрок" .. getPlayerName( client ) .. " не должен сейчас быть в диалоге!", 2 )
	end
end

local function onPlayerDialogTradeStart()
	local talk = xrPlayerTalks[ client ]
	if talk then
		xrDialogStartTrade( talk )
	else
		outputDebugString( "Игрок" .. getPlayerName( client ) .. " не должен сейчас быть в диалоге!", 2 )
	end		
end

xrPlayerTalks = {

}

--[[
	Export
]]
function xrPlayerStartTalk( player, ped )
	if xrPlayerTalks[ player ] or getElementData( player, "uib", false ) then
		return false
	end

	local talk = xrDialogStart( player, ped )
	if talk then
		xrPlayerTalks[ player ] = talk

		triggerEvent( EServerEvents.onDialogStartTalk, player )

		return true
	end

	return false
end

function xrPlayerStopTalk( player )
	local talk = xrPlayerTalks[ player ]
	if talk then
		xrDialogStop( talk )
		xrPlayerTalks[ player ] = nil		
		collectgarbage( "collect" )

		triggerEvent( EServerEvents.onDialogEndTalk, player )

		return true
	end
	
	return false
end

function xrPlayerSwitchTalk( player, ped )
	if xrPlayerTalks[ player ] then
		xrPlayerStopTalk( player )
	else
		xrPlayerStartTalk( player, ped )
	end
end

function xrPlayerGiveItem( player, itemHash, slotHash, count )
	local talk = xrPlayerTalks[ player ]
	if talk then
		return xrDialogGiveItem( talk, itemHash, slotHash, count )
	else
		outputDebugString( "Игрок должен быть в диалоге!", 2 )
	end		
end

function xrPlayerGiveMoney( player, value )
	local talk = xrPlayerTalks[ player ]
	if talk then
		xrDialogGiveMoney( talk, value )
	else
		outputDebugString( "Игрок должен быть в диалоге!", 2 )
	end		
end

function xrPlayerGiveRank( player, value )
	local talk = xrPlayerTalks[ player ]
	if talk then
		xrDialogGiveRank( talk, value )
	else
		outputDebugString( "Игрок должен быть в диалоге!", 2 )
	end		
end

local function onPlayerWasted()
	xrPlayerStopTalk( source )
end

local function onPlayerGamodeLeave()
	xrPlayerStopTalk( source )
end

--[[
	Export
]]
function xrBreakDialog( player )
	return true
end

function xrGivePlayerStartKit( player )
	xrPlayerGiveItem( player, "wpn_pm", EHashes.SlotAny )
	xrPlayerGiveItem( player, "ammo_9x18_pmm", EHashes.SlotAny )
	xrPlayerGiveItem( player, "bolt", EHashes.SlotAny, 10 )
	xrPlayerGiveItem( player, "device_torch", EHashes.SlotAny )	

	xrPlayerGiveMoney( player, 1000 )

	return false
end

addEventHandler( "onCoreStarted", root,
    function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
		xrIncludeModule( "global.lua" )
		
        addEventHandler( "onPlayerWasted", root, onPlayerWasted )
		addEventHandler( EServerEvents.onPlayerGamodeLeave, root, onPlayerGamodeLeave ) 
		addEvent( EServerEvents.onDialogTradeStart, true )
		addEventHandler( EServerEvents.onDialogTradeStart, root, onPlayerDialogTradeStart )
		addEvent( EServerEvents.onDialogPhraseSelect, true )
		addEventHandler( EServerEvents.onDialogPhraseSelect, root, onPlayerDialogPhraseSelect )
		
		xrSystem.init ( )
    end
)
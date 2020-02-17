local IS_SERVER = triggerClientEvent ~= nil

--[[
	Hash
]]
function _hashFn( str )
	local result = 0
	for i = 1, string.len( str ) do
		local byte = string.byte( str, i )
		result = byte + bitLShift( result, 6 ) + bitLShift( result, 16 ) - result
	end
	return result
end

--Список XML файлов, содержащих диалоги для сталкеров и игрока
local dialogsFiles = {
	"dialogs_escape"
}
-- Список XML файлов, содержащих описания конкретных сталкеров и торговцев
local specific_characters_files = {
	"character_desc_general"
}
-- Список XML файлов, содержащих таблицы символов
local stringFiles = {  
	"st_dialogs_escape"
}

--[[
	xrSystem
	Главный одиночный класс игры
]]
xrSystem = { 
	dialogs = { },
	characters = { },
	strings = { }
}

function xrSystem.init ( )
	-- Парсим XML файлы строк
	local num = 0
	for _, filename in ipairs ( stringFiles ) do
		local xml = xmlLoadFile ( "configs/text/rus/" .. filename .. ".xml" )
		if xml then
			for _, xmlnode in ipairs ( xmlNodeGetChildren ( xml ) ) do
				local id = xmlNodeGetAttribute ( xmlnode, "id" )
				local idHash = _hashFn( id )
				xrSystem.strings [ idHash ] = xrString_new( xmlnode )
				num = num + 1
			end
			
			xmlUnloadFile ( xml )
		end
	end
	outputDebugString ( "Загружено " .. num .. " строк" )

	-- Парсим XML файлы описаний сталкеров и создаем для них классы
	num = 0
	for _, filename in ipairs ( specific_characters_files ) do
		local xml = xmlLoadFile ( "configs/" .. filename .. ".xml" )
		if xml then
			for _, xmlnode in ipairs ( xmlNodeGetChildren ( xml ) ) do
				local id = xmlNodeGetAttribute ( xmlnode, "id" )
				local idHash = _hashFn( id )
				xrSystem.characters[ idHash ] = xrCharacterDesc.new ( xmlnode )
				num = num + 1
			end
			
			xmlUnloadFile ( xml )
		end
	end
	outputDebugString ( "Загружено " .. num .. " персонажей" )

	-- Парсим XML файлы диалогов и создаем для них классы
	num = 0
	for _, filename in ipairs ( dialogsFiles ) do
		local xml = xmlLoadFile ( "configs/gameplay/" .. filename .. ".xml" )
		if xml then
			for _, xmlnode in ipairs ( xmlNodeGetChildren ( xml ) ) do
				local id = xmlNodeGetAttribute ( xmlnode, "id" )
				local idHash = _hashFn( id )
				xrSystem.dialogs[ idHash ] = xrDialog.new ( xmlnode )
				num = num + 1
			end
			
			xmlUnloadFile ( xml )
		end
	end
	outputDebugString ( "Загружено " .. num .. " диалогов" )	
end

function xrSystem.getDialog( id )
	return xrSystem.dialogs [ id ]
end

function xrSystem.getCharacterDescription( id )
	return xrSystem.characters [ id ]
end

function xrSystem.getText( id )
	return xrSystem.strings[ id ] or ""
end

--[[
	xrDialog
	Класс диалогов для сталкеров и игрока
]]
xrDialog = { }
xrDialog.__index = xrDialog

function xrDialog.new ( xmlnode )
	local dialog = {
		phrases = {},
		dont_has_info = {},
		has_info = {}
	}
	
	local dialogId = xmlNodeGetAttribute ( xmlnode, "id" )
	
	for _, xmlnode in ipairs ( xmlNodeGetChildren ( xmlnode ) ) do
		local nodeName = xmlNodeGetName ( xmlnode )

		if IS_SERVER then
			if nodeName == "dont_has_info" then
				table.insert( dialog.dont_has_info, _hashFn( xmlNodeGetValue ( xmlnode ) ) )
			elseif nodeName == "has_info" then
				table.insert( dialog.has_info, _hashFn( xmlNodeGetValue ( xmlnode ) ) )
			end
		end
		
		if nodeName == "phrase_list" then
			for _, xmlnode in ipairs ( xmlNodeGetChildren ( xmlnode ) ) do
				local id = tonumber ( 
					xmlNodeGetAttribute ( xmlnode, "id" )
				)
				if id then
					local phrase = xrDialogPhrase.new( xmlnode )
					phrase.dialog = dialog
					dialog.phrases[ id ] = phrase
				else
					outputDebugString ( "У фразы диалога " .. dialogId .. "отсутствует id", 2 )
				end
			end
		end
	end
	
	return setmetatable ( dialog, xrDialog )
end

function xrDialog:getPhrases ( )
	return self.phrases
end

--[[
	xrDialogPhrase
	Класс фразы для отдельного диалога
]]
xrDialogPhrase = { }
xrDialogPhrase.__index = xrDialogPhrase

function xrDialogPhrase.new ( xmlnode )
	local phrase = { 
		text = nil, -- Если равно nil, сразу переходим к следующим фразам
		textHash = nil,
		nextPhrases = { }, -- Следующие фразы
		action = {},
		precondition = {}, -- Условие для появления фразы
		give_info = {},
		dont_has_info = {},
		has_info = {},
		disable_info = {}
	}

	for _, xmlnode in ipairs ( xmlNodeGetChildren ( xmlnode ) ) do
		local nodeName = xmlNodeGetName ( xmlnode )
		if nodeName == "text" and IS_SERVER ~= true then
			local textValue = xmlNodeGetValue ( xmlnode )
			if textValue then				
				local textHash = _hashFn( textValue )
				if xrSystem.strings[ textHash ] then
					phrase.textHash = textHash
				else
					phrase.text = tostring( textValue )
				end				
			end
		end

		if IS_SERVER then
			if nodeName == "action" then
				local value = xmlNodeGetValue( xmlnode ) or EMPTY_STR								
				local resourceName = gettok( value, 1, 58 )
				local fnName = gettok( value, 2, 58 )
				if resourceName and fnName then
					local res = getResourceFromName( resourceName )
					if res then
						table.insert ( phrase.action, { res, fnName } )
					end
				end
			elseif nodeName == "next" then
				table.insert ( phrase.nextPhrases, tonumber ( xmlNodeGetValue ( xmlnode ) ) )
			elseif nodeName == "precondition" then
				local value = xmlNodeGetValue( xmlnode ) or EMPTY_STR								
				local resourceName = gettok( value, 1, 58 )
				local fnName = gettok( value, 2, 58 )
				if resourceName and fnName then
					local res = getResourceFromName( resourceName )
					if res then
						table.insert ( phrase.precondition, { res, fnName } )
					end
				end
			elseif nodeName == "give_info" then
				table.insert( phrase.give_info, _hashFn( xmlNodeGetValue ( xmlnode ) ) )
			elseif nodeName == "dont_has_info" then
				table.insert( phrase.dont_has_info, _hashFn( xmlNodeGetValue ( xmlnode ) ) )
			elseif nodeName == "has_info" then
				table.insert( phrase.has_info, _hashFn( xmlNodeGetValue ( xmlnode ) ) )
			elseif nodeName == "disable_info" then
				table.insert( phrase.disable_info, _hashFn( xmlNodeGetValue ( xmlnode ) ) )
			end
		end
	end
	
	return setmetatable ( phrase, xrDialogPhrase )
end

--[[
	xrCharacterDesc
	Класс описания сталкеров
]]
xrCharacterDesc = { }
xrCharacterDesc.__index = xrCharacterDesc

function xrCharacterDesc.new ( xmlnode )
	local character = {
		name = "",
		icon = { 0, 0 }, -- uv иконки
		map_icon = { 0, 0 }, -- uv иконки миникарты
		bio = "", -- биография
		team = "",
		rank = 0,
		reputation = 0,
		trade = false,
		visual = nil, -- Модель сталкера
		start_dialog = nil,
		actor_dialogs = {
		
		},
		team_default = nil
	}
	
	character.team_default = xmlNodeGetAttribute ( xmlnode, "team_default" )

	for _, xmlnode in ipairs ( xmlNodeGetChildren ( xmlnode ) ) do
		local nodeName = xmlNodeGetName ( xmlnode )
		if nodeName == "name" then
			character.name = xmlNodeGetValue ( xmlnode )
		elseif nodeName == "icon" then
			local x = xmlNodeGetAttribute ( xmlnode, "x" )
			local y = xmlNodeGetAttribute ( xmlnode, "y" )
			character.icon = { tonumber ( x ) or 0, tonumber ( y ) or 0 }
		elseif nodeName == "map_icon" then
			local x = xmlNodeGetAttribute ( xmlnode, "x" )
			local y = xmlNodeGetAttribute ( xmlnode, "y" )
			character.map_icon = { tonumber ( x ) or 0, tonumber ( y ) or 0 }
		elseif nodeName == "bio" then
			character.bio = xmlNodeGetValue ( xmlnode )
		elseif nodeName == "team" then
			character.team = xmlNodeGetValue ( xmlnode )
		elseif nodeName == "rank" then
			local rank = xmlNodeGetValue ( xmlnode )
			character.rank = tonumber ( rank ) or 0
		elseif nodeName == "reputation" then
			local reputation = xmlNodeGetValue ( xmlnode )
			character.reputation = tonumber ( reputation ) or 0
		elseif nodeName == "visual" then
			character.visual = xmlNodeGetValue ( xmlnode )
		elseif nodeName == "trade" then
			character.trade = xmlNodeGetValue ( xmlnode ) == "true"
			
		-- Стартовый диалог для сталкера
		elseif nodeName == "start_dialog" then
			character.start_dialog = _hashFn( xmlNodeGetValue ( xmlnode ) )
			
		-- Диалоги игрока(варианты)
		elseif nodeName == "actor_dialog" then
			table.insert ( character.actor_dialogs, _hashFn( xmlNodeGetValue ( xmlnode ) ) )
		end
	end
	
	return setmetatable ( character, xrCharacterDesc )
end

function xrCharacterDesc:getActorDialogs ( )
	return self.actor_dialogs
end

--[[
	xrString
	Класс строк
]]
local emptyStr = "NOTHING"

function xrString_new( xmlnode )
	local str = emptyStr
	
	local textNode = xmlFindChild( xmlnode, "text", 0 )
	if textNode then
		str = xmlNodeGetValue( textNode )
	end
	
	return str
end
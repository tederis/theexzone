local IS_CONFIG_RESOURCE = getResourceName( resource ) == "xrcore"

function _hashFn( str )
	local result = 0
	for i = 1, string.len( str ) do
		local byte = string.byte( str, i )
		result = byte + bitLShift( result, 6 ) + bitLShift( result, 16 ) - result
	end
	return result
end

local function _parse ( str )
	if type( str ) ~= "string" then
		return str
	end

	if str:sub ( 1, 1 ) == '"' then
		local endPos = str:find ( '"', 2 )
		if endPos then
			return str:sub ( 2, endPos - 1 )
		else
			outputDebugString ( "Обнаружена незавершенная строка: " .. str, 2 )
			return str:sub ( 2, str:len ( ) )
		end
	elseif str:sub( 1, 1 ) == '#' then
		local endPos = str:find ( '#', 2 )
        if endPos then
			return _hashFn( str:sub ( 2, endPos - 1 ) )
		else
			outputDebugString ( "Обнаружена незавершенная хэш-строка: " .. str, 2 )
			return _hashFn( str:sub ( 2, str:len ( ) ) )
        end
	end
	
	return str
end

local tryReadVector2 = function ( value )
    local first = tonumber ( gettok ( value, 1, "," ) )
    local second = tonumber ( gettok ( value, 2, "," ) )
    if first and second then
        return Vector2 ( first, second )
    end
end
local tryReadVector3 = function ( value )
    local first = tonumber ( gettok ( value, 1, "," ) )
    local second = tonumber ( gettok ( value, 2, "," ) )
    local third = tonumber ( gettok ( value, 3, "," ) )
    if first and second and third then
        return Vector3 ( first, second, third )
    end
end
local tryReadVector4 = function ( value )
    local first = tonumber ( gettok ( value, 1, "," ) )
    local second = tonumber ( gettok ( value, 2, "," ) )
    local third = tonumber ( gettok ( value, 3, "," ) )
    local fourth = tonumber ( gettok ( value, 4, "," ) )
    if first and second and third and fourth then
        return Vector4 ( first, second, third, fourth )
    end
end
local tryReadArray = function( value )
	local fields = split( value, ',' )
	if fields and #fields > 1 then
		local result = {}
		for i, field in ipairs( fields ) do
			result[ i ] = _parse( field )
		end
		return result
	end
end

--[[
	xrSection
]]
local function xrCreateSection( name, nameHash, game_ver )
    local section = {
        _ver = gameVer,
        _name = name,
        _nameHash = nameHash
    }

    return section
end

local function xrInsertItem ( section, key, value )
    if not value then
        table.insert ( section, _parse( key ) )
        return
    end

    if value == "true" then
        section [ key ] = true
    elseif value == "false" then
        section [ key ] = false
    else
        local arg = tonumber( value )
        if arg then
            section [ key ] = arg
            return
        end
        arg = tryReadVector4( value )
        if arg then
            section [ key ] = arg
            return
        end
        arg = tryReadVector3( value )
        if arg then
            section [ key ] = arg
            return
        end
        arg = tryReadVector2( value )
        if arg then
            section [ key ] = arg
            return
		end
		arg = tryReadArray( value )
		if arg then
			section[ key ] = arg
			return
		end
        section [ key ] = _parse( value )
    end			
end

local function xrInheritItems( section, inheritFrom )
	for key, value in pairs ( inheritFrom ) do
		if key ~= "_name" and key ~= "_nameHash" and key ~= "_ver" then
			section[ key ] = value
		end
    end
end

--[[
	xrSettings
]]
xrSettings = { }
xrSettingsMT = { __index = xrSettings }

function xrSettings.new ( filename )
	local ini = {
		sections = { }
	}
	setmetatable ( ini, xrSettingsMT )
	
	-- Парсим базовый файл если указан
	if type( filename ) == "string" and fileExists ( filename ) then
		local file = fileOpen ( filename, true )
		ini:load ( file, filename )
		fileClose ( file )
	end

	return ini
end

function xrSettings:load ( file, filename )
	local str = fileRead ( file, fileGetSize ( file ) )
	local lines = split ( str, "\n" )
	local current
	local gameVer = "soc"
	for _, line in ipairs ( lines ) do
		line = line:gsub ( ";.*$", "" ) -- Удалим комментарии
		line = line:gsub ( "//.*$", "" ) -- Удалим комментарии
		local trimmed = line:gsub ( "%s+", "" ) -- Удаляем все пробелы
		local trimmedLen = trimmed:len ( )
		if trimmedLen > 0 then
			local ch = trimmed:sub ( 1, 1 )
			if ch == "#" and not current then
				if trimmed:find ( "#include" ) == 1 then
					local includeName = _parse ( trimmed:sub ( 9, trimmedLen ) )
					local path = string.match ( filename , "(.*[/\\])" )
                    local includePath = path .. includeName
                    if fileExists ( includePath ) then
						local file = fileOpen ( includePath, true )
						self:load ( file, includePath )
						fileClose ( file )
					else
						outputDebugString ( "Файл для внедрения не был найден: " .. includePath, 2 )
					end
				elseif trimmed:find ( "#game_ver" ) then
					local verName = _parse ( trimmed:sub ( 10, trimmedLen ) )
					gameVer = verName
				end
			elseif ch == "[" then
				local endPos = trimmed:find ( "]" )
				if endPos then
					local secName = trimmed:sub ( 2, endPos - 1 )
					local secNameHash = _hashFn( secName )
					if self.sections [ secNameHash ] == nil then
						current = xrCreateSection ( secName, secNameHash, gameVer )
						self.sections [ secNameHash ] = current
					
						-- Если у секции есть наследование
						if endPos + 1 < trimmedLen and trimmed:sub ( endPos + 1, endPos + 1 ) == ":" then
							local inheritedNames = split ( trimmed:sub ( endPos + 2, trimmedLen ), "," )

							for _, name in ipairs ( inheritedNames ) do
								local nameHash = _hashFn( name )
								local inheritedSection = self.sections [ nameHash ]
                                if inheritedSection then
                                    xrInheritItems( current, inheritedSection )
								else
									outputDebugString ( "Не была найдена секция для наследование: " .. name, 2 )
								end
							end
						end
					else
						--outputDebugString ( "Обнаружен дубликат секции " .. secName .. "!", 2 )
					end
				else
					outputDebugString ( "Обнаружена незавершенная секция: " .. trimmed, 2 )
				end
			else
				-- Если мы вошли в секцию
				if current then
					local key = gettok ( trimmed, 1, "=" )
					local value = gettok ( trimmed, 2, "=" )
					if key and value then
	                    xrInsertItem( current, _parse( key ), value )
                    else
                        if trimmed:sub ( 1, 1 ) == '$' then
                            local trimmedHash = _hashFn( trimmed:sub ( 2, trimmed:len ( ) ) )
                            local section = self.sections[ trimmedHash ]
                            if section then
                                xrInsertItem( current, section )
                            else
                                outputDebugString( "Секция на которую ссылается " .. tostring( trimmed ) .. " не была найдена (" .. filename .. ")", 2 )
                            end
                        else
                            xrInsertItem( current, trimmed )
                        end						
					end
				end
			end
		end
	end
end

function xrSettingsGetSection( arg )
	-- Хэшируем если строка
	if type( arg ) == "string" then
		arg = _hashFn( arg )
	end

	local section = _settings.sections[ arg ]
	if section then
		return section
	end

	--outputDebugString( "Секции " .. tostring( arg ) .. " не существует!", 2 )
	return false
end

function xrSettingsFindSections( arg )
    local result = {}
    for hash, section in pairs( _settings.sections ) do
		if section[ arg ] ~= nil then
            table.insert( result, hash )
        end
    end
    return result
end

local _getOrCreateSettings = function()
	local settings = _G[ "_settings" ]
	if settings then
		return settings
	end

	settings = xrSettings.new()
	_G[ "_settings" ] = settings

	return settings
end
function xrSettingsInclude( filename )
	local filepath = ":xrcore/config/" .. filename
	local settings = _getOrCreateSettings()
	
	local file = fileOpen( filepath, true )
	if file then
		settings:load( file, filepath )
		fileClose( file )

		return true 
	end

	return false
end
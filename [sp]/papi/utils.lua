function utilXmlFindDomain ( node, tagName )
	for _, child in ipairs ( xmlNodeGetChildren ( node ) ) do
		if xmlNodeGetName ( child ) == "domain" and xmlNodeGetAttribute( child, "name" ) == tagName  then
			return child
		end
	end
end

function xmlNodeGetVector2( xml, name, default )
	local value = xmlNodeGetAttribute( xml, name )
	if type( value ) ~= "string" then
		outputDebugString( "Параметр типа Vector2 " .. tostring( name ) .. " не был найден!", 2 )
		return default
	end

	local x = tonumber( gettok( value, 1, ' ' ) )
	local y = tonumber( gettok( value, 2, ' ' ) )
	if x and y then
		return Vector2( x, y )
	end

	outputDebugString( "Параметр типа Vector2 " .. tostring( name ) .. " был прочитан с ошибкой!", 2 )
	return default
end

function xmlNodeGetVector3( xml, name, default, inverse )
	local value = xmlNodeGetAttribute( xml, name )
	if type( value ) ~= "string" then
		outputDebugString( "Параметр типа Vector3 " .. tostring( name ) .. " не был найден!", 2 )
		return default
	end

	local x = tonumber( gettok( value, 1, ' ' ) )
	local y = tonumber( gettok( value, inverse == true and 2 or 3, ' ' ) )
	local z = tonumber( gettok( value, inverse == true and 3 or 2, ' ' ) )
	if x and y and z then
		return Vector3( x, y, z )
	end

	outputDebugString( "Параметр типа Vector3 " .. tostring( name ) .. " был прочитан с ошибкой!", 2 )
	return default
end

function xmlNodeGetNumber( xml, name, default )
	local value = xmlNodeGetAttribute( xml, name )
	if type( value ) == "string" then
		return tonumber( value )
	end	

	outputDebugString( "Параметр типа number " .. tostring( name ) .. " не был найден или прочитан с ошибкой!", 2 )
	return default
end

function xmlNodeGetBool( xml, name, default )
	local value = xmlNodeGetAttribute( xml, name )
	if type( value ) == "string" then
		return value == "true"
	end	

	outputDebugString( "Параметр типа bool " .. tostring( name ) .. " не был найден или прочитан с ошибкой!", 2 )
	return default
end

function randStandardNormal()
	local val = 0
	for i = 1, 12 do
		val = val + math.random()
	end

    return val - 6
end

function randomNormal( meanValue, variance ) 
	return randStandardNormal() * math.sqrt( variance ) + meanValue
end
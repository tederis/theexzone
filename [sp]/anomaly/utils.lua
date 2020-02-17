COLOR_R = 1
COLOR_G = 2
COLOR_B = 3
COlOR_A = 4

Color = {
	build = function( self, r, g, b, a )
		return {
			tonumber( r ) or 0,
			tonumber( g ) or 0,
			tonumber( b ) or 0,
			tonumber( a ) or 1
		}
	end,

	WHITE = { 1, 1, 1, 1 }
}

VECTOR_UP = Vector3( 0, 0, 1 )
VECTOR_ONE = Vector3( 1, 1, 1 )

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

function xmlNodeGetColor( xml, name, default )
	local value = xmlNodeGetAttribute( xml, name )
	if type( value ) ~= "string" then
		outputDebugString( "Параметр типа Color " .. tostring( name ) .. " не был найден!", 2 )
		return default
	end

	local r = tonumber( gettok( value, 1, ' ' ) )
	local g = tonumber( gettok( value, 2, ' ' ) )
	local b = tonumber( gettok( value, 3, ' ' ) )
	local a = tonumber( gettok( value, 4, ' ' ) )
	if r and g and b then
		return Color:build( r, g, b, a )
	end

	outputDebugString( "Параметр типа Color " .. tostring( name ) .. " был прочитан с ошибкой!", 2 )
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
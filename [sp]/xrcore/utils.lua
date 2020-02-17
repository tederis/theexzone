local inline = [[
	_G["xrIncludeModule"]=function(name)
		local content = ""
		local file = fileOpen( ":xrcore/modules/" .. name, true )
		if file then
			content = fileRead( file, fileGetSize( file ) )
			fileClose( file )
		else
			outputDebugString("Такого модуля не существует!", 1)
			return false
		end
		local fn = loadstring( content )
		if type( fn ) == "function" then
			fn()
			return true
		else
			outputDebugString("Ошибка влючения модуля!", 1)			
		end
		return false
	end
]]

xrIncludeModule = function( name )
	local content = ""
	local file = fileOpen( "modules/" .. name, true )
	if file then
		content = fileRead( file, fileGetSize( file ) )
		fileClose( file )
	else
		outputDebugString("Такого модуля не существует!", 1)
		return false
	end
	local fn = loadstring( content )
	if type( fn ) == "function" then
		fn()
		return true
	else
		outputDebugString("Ошибка влючения модуля!", 1)			
	end
	return false
end

function xrSettingsGetInline()
	return inline
end
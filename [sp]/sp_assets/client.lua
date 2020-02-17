local xrAssets = {

}

local function xrAssureAsset( asset, owner )
	if not asset.owners[ owner ] then
		asset.owners[ owner ] = true
		asset.refs = asset.refs + 1

		return true
	end

	return false
end

local function xrReduceAsset( asset, owner )
	if asset.owners[ owner ] then
		asset.owners[ owner ] = nil
		asset.refs = asset.refs - 1

		return true
	end

	return false
end

local function xrCreateAsset( name, filename )
	local asset = {
		name = name,
		filename = filename,
		owners = {},
		refs = 1
	}

	return asset
end

--[[
	TextureDescriptor
]]
TextureDescriptor = {

}
TextureDescriptorMT = {
	__index = TextureDescriptor
}

function TextureDescriptor:getOrCreate( owner )
	if self._texture then
		xrAssureAsset( self, owner )

		return self._texture
	end

	local texture = dxCreateTexture( self.filename, self.textureFormat, self.mipmaps, self.textureEdge )
	if texture then
		self._texture = texture

		xrAssureAsset( self, owner )

		return texture
	end

	return false
end

function TextureDescriptor:unload( owner )
	xrReduceAsset( self, owner )

	if self.refs < 1 and self._texture then
		destroyElement( self._texture )

		self._font = texture

		return true
	end

	return false
end

--[[
	FontDescriptor
]]
FontDescriptor = {

}
FontDescriptorMT = {
	__index = FontDescriptor
}

function FontDescriptor:getOrCreate( owner )
	if self._font then
		xrAssureAsset( self, owner )

		return self._font
	end

	local font = dxCreateFont( self.filename, self.size, self.bold, self.quality )
	if font then
		self._font = font

		xrAssureAsset( self, owner )

		return font
	end

	return false
end

function FontDescriptor:unload( owner )
	xrReduceAsset( self, owner )

	if self.refs < 1 and self._font then
		destroyElement( self._font )

		self._font = nil

		return true
	end

	return false
end

--[[
	Loading
]]
local formatTypeLookup = {
	[ "argb" ] = true,
	[ "dxt1" ] = true,
	[ "dxt3" ] = true,
	[ "dxt5" ] = true
}

local edgeTypeLookup = {
	[ "wrap" ] = true,
	[ "clamp" ] = true
}

local function xrLoadTextures( xml )
	local index = 0
	local node = xmlFindChild( xml, "texture", index )

	while node do
		local name = xmlNodeGetAttribute( node, "name" )
		local filename = xmlNodeGetAttribute( node, "filename" )
		local format = xmlNodeGetAttribute( node, "format" )
		if not formatTypeLookup[ format ] then
			format = "argb"
		end
		local mipmaps = xmlNodeGetAttribute( node, "mipmaps" ) == "true"
		local edge = xmlNodeGetAttribute( node, "edge" )
		if not edgeTypeLookup[ edge ] then
			edge = "wrap"
		end

		if name and filename and fileExists( filename ) then
			if not xrAssets[ name ] then
				local texDesc = xrCreateAsset( name, filename )
				texDesc.format = format
				texDesc.mipmaps = mipmaps
				texDesc.edge = edge

				xrAssets[ name ] = setmetatable( texDesc, TextureDescriptorMT )
			else
				outputDebugString( "Ресурс " .. tostring( name ) .. " уже существует", 2 )
			end
		end

		index = index + 1
		node = xmlFindChild( xml, "texture", index )
	end
end

local qualityTypeLookup = {
	[ "default" ] = true,
	[ "draft" ] = true,
	[ "proof" ] = true,
	[ "nonantialiased" ] = true,
	[ "antialiased" ] = true,
	[ "cleartype" ] = true,
	[ "cleartype_natural" ] = true
}

local function xrLoadFonts( xml )
	local index = 0
	local node = xmlFindChild( xml, "font", index )

	while node do
		local name = xmlNodeGetAttribute( node, "name" )
		local filename = xmlNodeGetAttribute( node, "filename" )
		local size = tonumber( xmlNodeGetAttribute( node, "size" ) ) or 9
		local bold = xmlNodeGetAttribute( node, "bold" ) == "true"
		local quality = xmlNodeGetAttribute( node, "quality" )
		if not qualityTypeLookup[ quality ] then
			quality = "proof"
		end

		if name and filename and fileExists( filename ) then
			if not xrAssets[ name ] then
				local fontDesc = xrCreateAsset( name, filename )
				fontDesc.size = size
				fontDesc.bold = bold
				fontDesc.quality = quality

				xrAssets[ name ] = setmetatable( fontDesc, FontDescriptorMT )
			else
				outputDebugString( "Ресурс " .. tostring( name ) .. " уже существует", 2 )
			end
		end

		index = index + 1
		node = xmlFindChild( xml, "font", index )
	end
end

--[[
	Exports
]]
function xrLoadAsset( name )
	local desc = xrAssets[ name ]
	if not desc then
		outputDebugString( "Описания ресурса " .. tostring( name ) .. " не было найдено", 2 )
		return false
	end

	return desc:getOrCreate( sourceResource )
end

function xrUnloadAsset( name )
	local desc = xrAssets[ name ]
	if not desc then
		outputDebugString( "Описания ресурса " .. tostring( name ) .. " не было найдено", 2 )
		return false
	end

	return desc:unload( sourceResource )
end

--[[
	Init
]]
addEventHandler( "onClientResourceStart", resourceRoot,
	function()
		local xml = xmlLoadFile( "textures.xml", true )
		if xml then
			xrLoadTextures( xml )
			xmlUnloadFile( xml )
		else
			outputDebugString( "Ошибка чтения файла описания текстур", 2 )
		end

		xml = xmlLoadFile( "fonts.xml", true )
		if xml then
			xrLoadFonts( xml )
			xmlUnloadFile( xml )
		else
			outputDebugString( "Ошибка чтения файла описания шрифтов", 2 )
		end
    end
)
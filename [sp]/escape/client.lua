local NUM_LMAPS = 5

local meshes = {}
local lmaps = {}
local shaders = {}
local existsTXDs = {}

function parseMeshesFromFile( xml )
	for _, child in ipairs( xmlNodeGetChildren( xml ) ) do
		if xmlNodeGetName( child ) == "mesh" then
			local model = tonumber( xmlNodeGetAttribute( child, "model" ) )
			local geomName = xmlNodeGetAttribute( child, "geom" )
			local texName = xmlNodeGetAttribute( child, "tex" )
			local shaderName = xmlNodeGetAttribute( child, "shader" )
			local rulesName = xmlNodeGetAttribute( child, "rules" )
			local isTransp = xmlNodeGetAttribute( child, "transp" ) == "true"
			local isLodRef = xmlNodeGetAttribute( child, "lodref" ) == "true"
			local meta = xmlNodeGetAttribute( child, "meta" )

			local meshData = {
				model = model,
				geomName = geomName,
				texName = texName,
				shaderName = shaderName,
				rulesName = rulesName,
				isTransp = isTransp,
				isLodRef = isLodRef,
				meta = meta
			}

			meshes[ model ] = meshData
		end
	end
end

function loadLMaps()
	for i = 1, NUM_LMAPS do
		local tex = dxCreateTexture( "textures/lmap_" .. i .. "_2.dds", "dxt5", true )
		lmaps[ i ] = tex
	end
end

function loadShaders()
	-- Default
	local shader = dxCreateShader( "shaders/default.fx", 0, 0, false, "object" )
	for i, lmapTex in ipairs( lmaps ) do
		dxSetShaderValue( shader, "TexHemi" .. i, lmapTex )
	end
	shaders[ "default" ] = shader
	xrShaders[ "default" ] = shader
	xrLightManager:insertShader ( shader )

	-- Default internal
	shader = dxCreateShader( "shaders/default_internal.fx", 0, 0, false, "object" )
	shaders[ "default_internal" ] = shader
	xrShaders[ "default_internal" ] = shader
	xrLightManager:insertShader ( shader )

	-- Terrain
	shader = dxCreateShader( "shaders/terrain.fx", 0, 0, false, "object" )

	local baseTex = dxCreateTexture( "textures/terrain_escape.dds", "dxt5", true )
	local lmTex = dxCreateTexture( "textures/terrain_escape_lm.dds", "dxt5", true )
	local maskTex = dxCreateTexture( "textures/terrain_escape_mask.dds", "dxt5", true )

	dxSetShaderValue( shader, "TexLMap", lmTex )
	dxSetShaderValue( shader, "TexBase", baseTex )
	dxSetShaderValue( shader, "TexDet", maskTex )	

	local tex1 = dxCreateTexture( "textures/detail_grnd_asphalt.dds", "dxt1", true )
	local tex2 = dxCreateTexture( "textures/detail_grnd_earth.dds", "dxt1", true )
	local tex3 = dxCreateTexture( "textures/detail_grnd_earth.dds", "dxt1", true )
	local tex4 = dxCreateTexture( "textures/detail_grnd_cracked.dds", "dxt1", true )

	dxSetShaderValue( shader, "Tex1", tex2 )
	dxSetShaderValue( shader, "Tex2", tex1 )
	dxSetShaderValue( shader, "Tex3", tex3 )
	dxSetShaderValue( shader, "Tex4", tex4 )

	shaders[ "terrain" ] = shader
	xrShaders[ "terrain" ] = shader
	xrLightManager:insertShader ( shader )

	-- Tree
	shader = dxCreateShader( "shaders/tree.fx", 0, 0, false, "object" )

	shaders[ "tree" ] = shader
	xrShaders[ "tree" ] = shader
	xrLightManager:insertShader ( shader )

	-- Tree lod
	shader = dxCreateShader( "shaders/treelod.fx", 0, 0, false, "object" )
	local tex1 = dxCreateTexture( "textures/level_lods.dds", "dxt5", true )
	dxSetShaderValue( shader, "Tex0", tex1 )
	shaders[ "treelod" ] = shader
	xrShaders[ "treelod" ] = shader
	--xrLightManager:insertShader ( shader )
end

local lodRefStartModel = 8000
local lods = {}
local original = {}
function replaceMeshes()
	existsTXDs = {}

	for model, data in pairs( meshes ) do
		local txd = existsTXDs[ data.texName ]
		if not txd then
			txd = engineLoadTXD ( "models/" .. data.texName .. ".txd" )
			existsTXDs[ data.texName ] = txd
		end

		if txd then
			engineImportTXD( txd, model )

			if data.isLodRef then
				engineImportTXD( txd, lodRefStartModel )
			end
		end

		local col = engineLoadCOL ( "models/" .. data.geomName .. ".col" )
		if col then
			engineReplaceCOL( col, model )

			if data.isLodRef then
				engineReplaceCOL( col, lodRefStartModel )
			end
		end

		local dff = engineLoadDFF ( "models/" .. data.geomName .. ".dff" )
		if dff then
			engineReplaceModel ( dff, model, data.isTransp )

			if data.isLodRef then
				engineReplaceModel ( dff, lodRefStartModel, data.isTransp )
			end
		end		
		
		if data.isLodRef then
			engineSetModelLODDistance( lodRefStartModel, 200 )
			lods[ model ] = lodRefStartModel
			original[ lodRefStartModel ] = model
			lodRefStartModel = lodRefStartModel + 1

			engineSetModelLODDistance( model, 300 )
		else
			engineSetModelLODDistance( model, 1000 )
		end
	end

	for _, object in ipairs( getElementsByType( "object" ) ) do
		local lodModel = lods[ getElementModel( object ) ]
		if lodModel then
			local nx, ny, nz = getElementPosition ( object )
			local rx, ry, rz = getElementRotation ( object )
			local lodObj = createObject ( lodModel, nx, ny, nz + 0.02, rx, ry, rz, true )
			setLowLODElement ( object, lodObj )
		end
	end
end

function applyShaders()
	--[[
		Ped shader
	]]
	local shader = dxCreateShader( "shaders/pedshader.fx", 0, 0, false, "ped" )
	shaders[ "ped" ] = shader
	xrShaders[ "ped" ] = shader
	xrLightManager:insertShader ( shader )


	for _, object in ipairs( getElementsByType( "object", resourceRoot ) ) do
		local meshData = meshes[ getElementModel( object ) ]
		if not meshData then
			local lodModel = original[ getElementModel( object ) ]
			meshData = meshes[ lodModel ]
		end

		if meshData then
			if meshData.meta then
				setElementData( object, "meta", meshData.meta )
			end

			if meshData.rulesName then
				applyRules( meshData.rulesName, object )
			elseif shaders[ meshData.shaderName ] ~= nil then
				engineApplyShaderToWorldTexture( shaders[ meshData.shaderName ], "*", object, false )
			else
				outputDebugString( "К модели не были применены шейдеры " .. tostring( meshData.model ), 2 )
			end
		end
	end
end

function applyRules( fileName, object )
	local xml = xmlLoadFile( "models/" .. fileName .. ".xml", true )
	if xml then
		local rules = {}

		for _, child in ipairs( xmlNodeGetChildren( xml ) ) do
			if xmlNodeGetName( child ) == "rule" then
				local name = xmlNodeGetAttribute( child, "name" )
				local shaderName = xmlNodeGetAttribute( child, "shader" )
				
				local shader = shaders[ shaderName ]
				if shader then
					table.insert( rules, { name = name, shader = shader } )
				else
					outputDebugString( "Такого шейдера не существует " .. tostring( shaderName ), 2 )
				end
			end
		end

		for _, rule in ipairs( rules ) do
			engineApplyShaderToWorldTexture( rule.shader, rule.name, object, false )

			if rule.name == "*" then
				for _, ruleB in ipairs( rules ) do
					if ruleB.name ~= "*" then
						engineRemoveShaderFromWorldTexture( rule.shader, ruleB.name, object )
					end
				end
			end
		end
	else
		outputDebugString( "Файла правил не существует! " .. tostring( fileName ) )
	end
end

local function onPlayerJoinGamemode()
	local shader = shaders.ped 
	if shader then
		engineApplyShaderToWorldTexture( shader, "*" )
	end
end

local function onPlayerLeaveGamemode()
	local shader = shaders.ped 
	if shader then
		engineRemoveShaderFromWorldTexture( shader, "*" )
	end
end

function xrCreateBlip( texName, sectionName, size, x, y, z )
	local blip = createElement( "xrblip" )
	setElementData( blip, "tex", texName )
	setElementData( blip, "sect", sectionName )
	setElementData( blip, "size", size )
	setElementPosition( blip, x, y, z )

	return blip
end

addEventHandler( "onClientCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
		xrIncludeModule( "global.lua" )
		xrIncludeModule( "streamer.lua" )

        -- Загружаем только зоны
        if not xrSettingsInclude( "zones/zones.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации аномалий!", 2 )
            return
		end
		
		if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
		end

		local xml = xmlLoadFile( "defs.xml", true )
		if xml then
			parseMeshesFromFile( xml )
		else
			outputDebugString( "Файла определений не существует!", 2 )
			return
		end

		xrLightManager:init()	

		loadLMaps()

		loadShaders()		

		replaceMeshes()

		applyShaders()
		
		addEvent( EClientEvents.onClientPlayerGamodeJoin, true )
		addEventHandler( EClientEvents.onClientPlayerGamodeJoin, localPlayer, onPlayerJoinGamemode, false )
		addEvent( EClientEvents.onClientPlayerGamodeLeave, true )
		addEventHandler( EClientEvents.onClientPlayerGamodeLeave, localPlayer, onPlayerLeaveGamemode, false )
    end
)
--[[
	TEDERIs Construction Tools
	Script: wbo_cl_streamer.lua
	Desc: Custom streamer
]]

-- DO NOT CHANGE!
SECTOR_SIZE = 60
HALF_SECTOR_SIZE = SECTOR_SIZE / 2
WORLD_WIDTH = 9000
WORLD_HEIGHT = 9000
WORLD_SIZE_X = WORLD_WIDTH / SECTOR_SIZE
WORLD_SIZE_Y = WORLD_HEIGHT / SECTOR_SIZE

GRASS_PATCHES = 6

LOD_LEVEL = 1

local _mathFloor = math.floor

--[[
	xrStreamerWorld
]]
xrStreamerWorld = { 
	sectors = { },
	activated = { }
}

function xrStreamerWorld.init ( )
	-- Вычислим положение мира относительно начала координат(LEFT TOP)
	local sizeX = SECTOR_SIZE * WORLD_SIZE_X
	local sizeY = SECTOR_SIZE * WORLD_SIZE_Y
	xrStreamerWorld.worldX = -sizeX / 2
	xrStreamerWorld.worldY = sizeY / 2
	
	-- Создадим сектора
	for i = 0, WORLD_SIZE_Y-1 do
		local _y = xrStreamerWorld.worldY - SECTOR_SIZE*i
		for j = 0, WORLD_SIZE_X-1 do
			local _x = xrStreamerWorld.worldX + SECTOR_SIZE*j
			
			local sector = xrStreamerSector.new ( _x, _y, SECTOR_SIZE )
			local _index = i * WORLD_SIZE_X + j + 1 -- Пакуем координаты для быстрого поиска
			
			-- Служебные поля для удобной работы
			sector._column = j + 1
			sector._row = i + 1
			sector._index = _index
			
			xrStreamerWorld.sectors [ _index ] = sector
		end
	end

	-- Обозначим соседние сектора
	for i, sector in ipairs ( xrStreamerWorld.sectors ) do
		if sector._column > 1 then -- left sector
			sector._left = xrStreamerWorld.sectors [ i - 1 ]
			sector._left._right = sector
		end
		if sector._column < WORLD_SIZE_X then -- right sector
			sector._right = xrStreamerWorld.sectors [ i + 1 ]
			sector._right._left = sector
		end
		if sector._row > 1 then -- top sector
			sector._top = xrStreamerWorld.sectors [ i - WORLD_SIZE_X ]
			sector._top._bottom = sector
		end
		if sector._row < WORLD_SIZE_Y then -- bottom sector
			sector._bottom = xrStreamerWorld.sectors [ i + WORLD_SIZE_X ]
			sector._bottom._top = sector
		end
	end
end

function xrStreamerWorld.findSector ( x, y )
	x = ( x - xrStreamerWorld.worldX ) / SECTOR_SIZE
	y = ( xrStreamerWorld.worldY - y ) / SECTOR_SIZE
	
	local column = _mathFloor ( x )
	local row = _mathFloor ( y )
	local _index = row * WORLD_SIZE_X + column + 1 -- Пакуем координаты для быстрого поиска
	
	return xrStreamerWorld.sectors [ _index ]
end

function xrStreamerWorld.update ( )
	local x, y = getCameraMatrix ( )
	local sector = xrStreamerWorld.findSector ( x, y )
	if sector ~= xrStreamerWorld.sector then
		xrStreamerWorld.onSectorEnter ( sector )
	end
end

function xrStreamerWorld.onSectorEnter ( sector )
	if xrStreamerWorld.sector then
		-- Выгружаем ненужные сектора
		local _, uncommon = sector:compareSurroundings ( xrStreamerWorld.sector, true )
		for _, _sector in ipairs ( uncommon ) do
			if _sector ~= sector then
				if xrStreamerWorld.activated [ _sector ] then
					_sector.activated = nil
					xrStreamerWorld.activated [ _sector ] = nil
				
					_sector:streamOut ( )
				end
			end
		end
		
		-- Загружаем новые вхождения
		_, uncommon = xrStreamerWorld.sector:compareSurroundings ( sector, true )
		for _, _sector in ipairs ( uncommon ) do
			if xrStreamerWorld.activated [ _sector ] == nil then
				_sector.activated = true
				xrStreamerWorld.activated [ _sector ] = true
			
				_sector:streamIn ( )
			end
		end
	else
		-- Загружаем уровень в первый раз
		local surrounding = sector:getSurroundingSectors ( LOD_LEVEL )
		table.insert ( surrounding, 1, sector )
		for i, _sector in ipairs ( surrounding ) do
			if xrStreamerWorld.activated [ _sector ] == nil then
				_sector.activated = true
				xrStreamerWorld.activated [ _sector ] = true
			
				_sector:streamIn ( )
			end
		end
	end
	
	xrStreamerWorld.sector = sector
end

--[[
	xrStreamerSector
]]
xrStreamerSector = { }
xrStreamerSector.__index = xrStreamerSector

--[[
	1, 2, 3,
	4,    5,
	6, 7, 8
]]

function xrStreamerSector.new ( x, y, size )
	local sector = {
		x = x, y = y,
		size = size,
		elements = { }
	}
	
	return setmetatable ( sector, xrStreamerSector )
end

local _lookup = {
	"_top", "_right", "_bottom", "_left"
}
function xrStreamerSector:getSurroundingSectors ( radius )
	local sectors = { self._left, self._top, self._right, self._bottom }
	local surround = { }
	
	for i = 1, radius do
		local steps = i * 2
		
		local _sectors = { sectors [ 1 ], sectors [ 2 ], sectors [ 3 ], sectors [ 4 ] }
		for i = 1, 4 do
			local sector = _sectors [ i ]
			for j = 1, steps do
				surround [ #surround + 1 ] = sector
				if sector then
					sector = sector [ _lookup [ i ] ]
					if i < 4 then
						sectors [ i + 1 ] = sector
					else
						sectors [ 1 ] = sector
					end
				end
			end
		end
	end
	
	return surround
end

function xrStreamerSector:isMySurroundingSector ( sector )
	local surrounding = self:getSurroundingSectors ( LOD_LEVEL )
	
	for _, _sector in ipairs ( surrounding ) do
		if _sector == sector then
			return true
		end
	end
end

function xrStreamerSector:compareSurroundings ( sector, includeCenter )
	local common = { }
    local uncommon = { }

    local surrounding = sector:getSurroundingSectors ( LOD_LEVEL )
	for _, _sector in ipairs ( surrounding ) do
		if self:isMySurroundingSector ( _sector ) then
			table.insert ( common, _sector )
		else 
			table.insert ( uncommon, _sector )
		end
	end
	
	if includeCenter then
        if self:isMySurroundingSector ( sector ) then
			table.insert ( common, sector )
        else
			table.insert ( uncommon, sector )
		end
    end
	
	return common, uncommon
end

function xrStreamerSector:streamIn ( )
	outputDebugString ( "grass in")

	for i = 1, GRASS_PATCHES do
		local patch = {
			object = createObject ( 3000, self.x + 30 + math.random ( -3, 3 ), self.y - 30 + math.random ( -3, 3 ), 0, 0, 0, math.random ( -45, 45 ) ),
			rt = dxCreateRenderTarget ( 32, 32, false ),
			shader = dxCreateShader ( "shaders/default.fx" ),
			biasx = biasx,
			biasy = biasy
		}
		
		dxSetShaderValue ( patch.shader, "gLevelTex", patch.rt )
		engineApplyShaderToWorldTexture ( patch.shader, "*", patch.object )
		
		self.elements [ i ] = patch
	end
	
	self.patchIndex = 1
	xrGrass.markSectorToUpdate ( self )
end

function xrStreamerSector:streamOut ( )

	outputDebugString ( "grass out")
	for i, patch in ipairs ( self.elements ) do
		destroyElement ( patch.object )
		destroyElement ( patch.rt )
		destroyElement ( patch.shader )
		
		self.elements [ i ] = nil
	end
end

function getPositionFromElementOffset(element,offX,offY,offZ)
    local m = getElementMatrix ( element )  -- Get the matrix
    local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]  -- Apply transform
    local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
    local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
    return x, y, z                               -- Return the transformed point
end

function xrStreamerSector:updateRT ( )
	if self.activated ~= true then
		return
	end
	
	local patch = self.elements [ self.patchIndex ]
	dxSetRenderTarget ( patch.rt )
	for _, element in ipairs ( xrElements ) do
		local rx, ry = getPositionFromElementOffset(patch.object, element.x, element.y, 0)
		local hz = exports.terrain_editor:getTerrainHeight ( rx, ry )
		
		local level = 0
		if hz then
			level = (hz-50) / 100
		end
		
		dxDrawRectangle ( element.tx, element.ty, 1, 1, tocolor ( math.floor ( level * 255 ), 255, 255, 255 ) )
	end
	dxSetRenderTarget ( )
	
	self.patchIndex = self.patchIndex + 1
	return self.patchIndex > #self.elements
end
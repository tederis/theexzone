CELL_WIDTH = 52
CELL_HEIGHT = 52
CELL_EPSILON = 2

sw, sh = guiGetScreenSize ( )

_scale = function ( x, y )
	x = tonumber ( x ) or 0
	y = tonumber ( y ) or 0
	
	return x * g_FactorH, y * g_FactorV
end

function findSlotByTraits( slots, ownerId, slotHash )
	
end

function isPointInRectangle ( x, y, rx, ry, rwidth, rheight )
	return ( x > rx and x < rx + rwidth ) and ( y > ry and y < ry + rheight )
end

function tryToFitRectangle( x0, y0, width0, height0, x1, y1, width1, height1 )
	if x0 > x1 + width1 or y0 > y1 + height1 then
		return false
	end
	if x0 + width0 < x1 or y0 + height0 < y1 then
		return false
	end
	return true
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

--[[
	UIFrame
	Отрисовка рамки
]]
UIFrame = { }
UIFrame.__index = UIFrame

function UIFrame.new ( x, y, width, height, pattern )
	local frame = {
		x = x, y = y,
		width = math.max ( width, pattern.left_top.width*2 ), height = math.max ( height, pattern.left_top.height*2 ),
		pattern = pattern
	}
	
	return setmetatable ( frame, UIFrame )
end

function UIFrame:destroy ( )
end

function UIFrame:draw ( )
	local pattern = self.pattern
	local x = self.x
	local y = self.y
	local corner = pattern.left_top
	local horizontal = pattern.top
	local vertical = pattern.left
	local back = pattern.back
	-- Top left fragment
	local fragment = pattern.left_top
	dxDrawImage ( x, y, corner.width, corner.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Top fragment
	x = x + corner.width
	local width = self.width - corner.width*2
	fragment = pattern.top
	dxDrawImageSection ( x, y, width, corner.width, 0, 0, horizontal.width*(width/horizontal.width), horizontal.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Top right fragment
	x = x + width
	fragment = pattern.right_top
	dxDrawImage ( x, y, corner.width, corner.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Left fragment
	x = self.x
	y = y + corner.height
	local height = self.height - corner.height*2
	fragment = pattern.left
	dxDrawImageSection ( x, y, vertical.width, height, 0, 0, vertical.width, vertical.height * (height/vertical.height), "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Back
	x = x + vertical.width
	fragment = pattern.back
	dxDrawImageSection ( x, y, width, height, 0, 0, back.width * (width/back.width), back.height * (height/back.height), "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Right fragment
	x = x + width
	fragment = pattern.right
	dxDrawImageSection ( x, y, vertical.width, height, 0, 0, vertical.width, vertical.height * (height/vertical.height), "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Bottom left
	x = self.x
	y = y + height
	fragment = pattern.left_bottom
	dxDrawImage ( x, y, corner.width, corner.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Bottom
	x = x + corner.width
	fragment = pattern.bottom
	dxDrawImageSection ( x, y, width, horizontal.height, 0, 0, horizontal.width * (width/horizontal.width), horizontal.height, "textures/" .. fragment [ 1 ] .. ".dds" )
	-- Bottom right
	x = x + width
	fragment = pattern.right_bottom
	dxDrawImage ( x, y, corner.width, corner.height, "textures/" .. fragment [ 1 ] .. ".dds" )
end

--[[
	xrSlot
]]
function xrSlotCreate( cols, rows, x, y, cellWidth, cellHeight, scrollable )
	local slot = {
		cols = cols,
		rows = rows,
		x = x,
		y = y,
		items = { },
		grid = { },

		scrollable = scrollable,
		scroll = 0,
		contentHeight = 0
	}

	slot.cellWidth, slot.cellHeight = _scale ( tonumber( cellWidth ) or CELL_WIDTH, tonumber( cellHeight ) or CELL_HEIGHT )
	slot.width = cols * slot.cellWidth
	slot.height = rows * slot.cellHeight

	if scrollable then
		slot.rt = dxCreateRenderTarget( slot.width, slot.height, true )
	end

	return slot
end

function xrSlotDestroy( slot )
	if slot.rt then
		destroyElement( slot.rt )
	end
end

function xrSlotSetEnvironment( slot, environment )
	slot.environment = environment
end

local function _tryToFitIn( grid, gridWidth, gridHeight, x, y, itemWidth, itemHeight )
    local hor = gridWidth - ( itemWidth + x )
	local vert = gridHeight - ( itemHeight + y )
	if x < 0 or y < 0 or hor < 0 or vert < 0 then
        return false
    end	
    
	for j = 0, itemHeight - 1 do
		for i = 0, itemWidth - 1 do
            local idx = ( y + j )*gridWidth + ( x + i )
			if grid[ idx + 1 ] ~= nil then
                return false
            end
        end
    end

    return true
end
function xrSlotFindPlace( slot, itemHash )
    local itemSection = xrSettingsGetSection( itemHash )
	if itemSection then
		local rowsNum = slot.scrollable and 1000 or slot.rows

		for j = 0, rowsNum-1 do
        	for i = 0, slot.cols-1 do			
                if _tryToFitIn( slot.grid, slot.cols, rowsNum, i, j, itemSection.inv_grid_width, itemSection.inv_grid_height ) then
                    return i, j
                end
            end 
		end
	else
		outputDebugString( "Инвалидный тип предмета!", 2 )
		return
	end
	
	outputDebugString( "Не можем найти место", 2 )
end

function xrSlotTestPlace( slot, itemHash, x, y )
    --[[local itemSection = xrSettingsGetSection( itemHash )
    if itemSection then
        return _tryToFitIn( slot.grid, slot.cols, slot.rows, x, y, itemSection.inv_grid_width, itemSection.inv_grid_height )
	end]]
	
	return true
end

function xrSlotFillGrid( slot, x, y, itemWidth, itemHeight, value )
	local rowsNum = slot.scrollable and 1000 or slot.rows

    local hor = slot.cols - ( itemWidth + x )
    local vert = rowsNum - ( itemHeight + y )
	if x < 0 or y < 0 or hor < 0 or vert < 0 then
		outputDebugString( "Предмет не помещается в сетку!", 2 )
        return false
    end    
    
	for j = 0, itemHeight - 1 do
		for i = 0, itemWidth - 1 do
			local idx = ( y + j )*slot.cols + ( x + i )
			slot.grid[ idx + 1 ] = value
        end
    end

    return true
end

function xrSlotCleanGrid( slot, value )
	local rowsNum = slot.scrollable and 1000 or slot.rows
	local grid = slot.grid

	for i = 1, slot.cols*rowsNum do
		local item = grid[ i ]
		if item and item[ EIA_ID ] == value then
			grid[ i ] = nil
		end
	end
end

function xrSlotGetItemAt( slot, col, row, isAbsolute )
	-- Если мы ищем предмет по абсолютным координатам
	if isAbsolute then
		local relx = col - slot.x
		local rely = row - slot.y

		if relx < 0 or rely < 0 or relx > slot.width or rely > slot.height then
			return false
		end

		col = math.floor( relx / slot.cellWidth )
		row = math.floor( ( rely + slot.scroll ) / slot.cellHeight )
	end

	local idx = row*slot.cols + col
	local item = slot.grid[ idx + 1 ]
	if item then
		return item
	end

	return false
end

function xrSlotAddScroll( slot, delta )
	if not slot.scrollable then
		return
	end
	
	slot.scroll = math.max( math.min( slot.scroll + delta, slot.contentHeight - slot.height ), 0 )
end

function xrSlotGetContentHeight( slot )
	local height = 0
	for _, item in pairs( slot.items ) do
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
		if itemSection then
			height = math.max( height, item.y*slot.cellHeight + itemSection.inv_grid_height*slot.cellHeight )
		end
	end

	return height
end

function xrSlotPutItem( slot, item )
	local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
	if not itemSection then
		return false
	end

	local x, y = xrSlotFindPlace( slot, item[ EIA_TYPE ] )
	if x and xrSlotFillGrid( slot, x, y, itemSection.inv_grid_width, itemSection.inv_grid_height, item ) then
		item.x = x
		item.y = y

		slot.items[ item[ EIA_ID ] ] = item

		-- Обновляем высоту контента
		slot.contentHeight = xrSlotGetContentHeight( slot )

		return true
	else
		outputDebugString( "Предмет не может быть вставлен", 2 )
	end
	
	return false
end

function xrSlotRemoveItem( slot, item )
	local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
	if not itemSection then
		return false
	end

	-- Очищаем область
	xrSlotCleanGrid( slot, item[ EIA_ID ] )
	slot.items[ item[ EIA_ID ] ] = nil

	-- Обновляем высоту контента
	slot.contentHeight = xrSlotGetContentHeight( slot )	

	return true
end

function xrSlotUpdateItem( slot, itemId, newItem )
	local item = slot.items[ itemId ]
	if item then
		for _, field in ipairs( EItemCopyAttributes ) do
			item[ field ] = newItem[ field ]
		end
	end
end

local COLOR_GREEN = Vector3( 0, 255, 0 )
local COLOR_RED = Vector3( 255, 0, 0 )

function xrSlotDraw( slot )
	local env = slot.environment
	local selectedHashes = env.selectedHashes or EMPTY_TABLE
	local clickedItem = env.clickedItem
	
	local biasx = slot.x
	local biasy = slot.y
	local slotX = slot.x
	local slotY = slot.y
	local slotWidth = slot.width
	local slotHeight = slot.height
	local startRow = 0
	local endRow = slot.rows - 1
	local isScrollable = slot.scrollable	

	if slot.rt then
		dxSetRenderTarget( slot.rt, true )
		slotX = 0
		slotY = 0
		biasx = 0
		biasy = -math.max( math.min( slot.scroll, slot.contentHeight - slot.height ), 0 )
		startRow = math.floor( math.abs( biasy / slot.cellHeight ) )
		endRow = math.min( startRow + slot.rows, 1000 )
	end

	-- Рисуем только видимые клетки
	for i = 0, slot.cols-1 do
		local _x = biasx + slot.cellWidth*i
		for j = startRow, endRow do
			local _y = biasy + slot.cellHeight*j
			local bias = 0
			local item = xrSlotGetItemAt( slot, i, j, false )
			if item and item == clickedItem then
				bias = 64
			elseif item and selectedHashes[ item[ EIA_TYPE ] ] then
				bias = 128
			end
			
			dxDrawImageSection( _x, _y, slot.cellWidth, slot.cellHeight, bias, 0, 64, 64, env.gridTexture )
			dxDrawImageSection( _x, _y, slot.cellWidth, slot.cellHeight, bias, 0, 64, 64, env.gridTexture )
			dxDrawImageSection( _x, _y, slot.cellWidth, slot.cellHeight, bias, 0, 64, 64, env.gridTexture )
		end
	end
	
	for id, item in pairs( slot.items ) do
		if not env.movableItem or ( item ~= env.movableItem.item or item[ EIA_COUNT ] > 1 ) then
			local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )

			local _x = biasx + slot.cellWidth*item.x
			local _y = biasy + slot.cellHeight*item.y
			local _width = slot.cellWidth*itemSection.inv_grid_width
			local _height = slot.cellHeight*itemSection.inv_grid_height

			-- Отсекаем невидимые предметы
			if not isScrollable or tryToFitRectangle( _x, _y, _width, _height, slotX, slotY, slotWidth, slotHeight ) then
				dxDrawImageSection( 
					_x, _y, 
					_width, _height,
					50*itemSection.inv_grid_x, 50*itemSection.inv_grid_y,
					50*itemSection.inv_grid_width, 50*itemSection.inv_grid_height,
					"textures/ui_icon_equipment.dds"
				)

				local condition = tonumber( item[ EIA_CONDITION ] ) or 1
				if condition < 0.99 then
					local height = slot.cellHeight * 0.08

					local colorVector = math.interpolate( COLOR_RED, COLOR_GREEN, condition )
					local color = tocolor( colorVector:getX(), colorVector:getY(), colorVector:getZ(), 255 )
					dxDrawRectangle( _x, _y + _height - height, _width * condition, height, color )
				end

				local count = tonumber( item[ EIA_COUNT ] ) or 1
				if count > 1 then
					dxDrawText( "x" .. count, _x, _y, _x + _width, _y + _height, tocolor( 255, 255, 255, 255 ), 1.2, "clear", "right", "bottom" )
				end
			end
		end
	end

	if slot.rt then
		dxSetRenderTarget()
		dxDrawImage( slot.x, slot.y, slot.width, slot.height, slot.rt )
	end
end
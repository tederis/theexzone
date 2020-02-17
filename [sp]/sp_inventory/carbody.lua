--[[
	controls
]]
local controls = {
	ourBag = {
		x = 20, y = 270,
		width = 290, height = 450
	},
	othersBag = {
		x = 685, y = 270,
		width = 305, height = 455
	},
	descWindow = {
		x = 375, y = 274,
		width = 267, height = 460
	},
	ourIcon = {
		x = 27, y = 22,
		width = 256, height = 256
	},
	othersIcon = {
		x = 843, y = 22,
		width = 143, height = 199
	},
	imageStatic = {
		x = 130, y = 95,
		width = 240, height = 190
	},
	descrList = {
		x = 15, y = 220,
		width = 241, height = 200
	},
	
	dragdropOur = {
		x = 20 + 29, y = 270 + 35,
		width = 250, height = 460,
		dragdrop = true,
		cols = 6, rows = 10,
		slot = _hashFn( "slot_bag" ),
		cellSize = 41,
		isMyOwn = true,
		scrollable = true
	},
	dragdropOthers = {
		x = 685 + 30, y = 270 + 35,
		width = 240, height = 400,
		dragdrop = true,
		cols = 6, rows = 10,
		slot = _hashFn( "slot_bag" ),
		cellSize = 41,
		scrollable = true
	}
}
resizeControls( controls, 1024, 768 )

local ui_frame = {
	left_top = { "ui_frame/ui_frame_lt", width = 128, height = 128 },
	top = { "ui_frame/ui_frame_t", width = 128, height = 128 },
	right_top = { "ui_frame/ui_frame_rt", width = 128, height = 128 },
	left = { "ui_frame/ui_frame_l", width = 128, height = 128 },
	back = { "ui_frame/ui_frame_back", width = 128, height = 128 },
	right = { "ui_frame/ui_frame_r", width = 128, height = 128 },
	left_bottom = { "ui_frame/ui_frame_lb", width = 128, height = 128 },
	bottom = { "ui_frame/ui_frame_b", width = 128, height = 128 },
	right_bottom = { "ui_frame/ui_frame_rb", width = 128, height = 128 }
}

--[[
	xrCarBody
]]
xrCarBody = {
	slots = { }
}

function xrCarBody.open( id0, id1 )
	if xrCarBody.visible then
		return
	end

	local items0 = exports[ "xritems" ]:xrGetContainerItems( id0 )
	if not items0 then
		outputDebugString( "У локального игрока нет конейнера!", 1 )
		return
	end

	local items1 = exports[ "xritems" ]:xrGetContainerItems( id1 )
	if not items1 then
		outputDebugString( "У второго элемента нет конейнера!", 1 )
		return
	end

	local control = controls.descWindow
	xrCarBody.frame = UIFrame.new ( control.x, control.y, control.width, control.height, ui_frame )

	xrCarBody.slots = {
		[ id0 ] = {},
		[ id1 ] = {}
	}
	
	-- Создаем слоты
	for _, control in pairs( controls ) do
		if control.dragdrop then
			local slot = xrSlotCreate( control.cols, control.rows, control.x, control.y, control.cellSize, control.cellSize )
			xrSlotSetEnvironment( slot, xrCarBody )
			slot.type = control.slot			

			if control.isMyOwn then
				xrCarBody.slots[ id0 ][ control.slot ] = slot
				slot.owner = id0
			else
				xrCarBody.slots[ id1 ][ control.slot ] = slot
				slot.owner = id1
			end
		end
	end
	
	-- Заполняем слоты нашими вещами
	for id, item in pairs ( items0 ) do
		local itemSlot = item[ EIA_SLOT ]
		if itemSlot ~= EHashes.SlotTemp and xrCarBody.slots[ id0 ][ itemSlot ] then
			xrSlotPutItem( xrCarBody.slots[ id0 ][ itemSlot ], item )
		end
	end

	for id, item in pairs ( items1 ) do
		local itemSlot = item[ EIA_SLOT ]
		if itemSlot ~= EHashes.SlotTemp and xrCarBody.slots[ id1 ][ itemSlot ] then
			xrSlotPutItem( xrCarBody.slots[ id1 ][ itemSlot ], item )
		end
	end

	addEventHandler( "onClientRender", root, xrCarBody.onRender, false )
	addEventHandler( "onClientCursorMove", root, xrCarBody.onCursorMove, false )
	addEventHandler( "onClientClick", root, xrCarBody.onClick, false )
	addEventHandler( "onClientDoubleClick", root, xrCarBody.onDoubleClick, false )
	addEventHandler( "onClientKey", root,  xrCarBody.onKey, false )
	
	showCursor ( true )
	
	xrCarBody.visible = true
	xrCarBody.clickedItem = nil
	xrCarBody.movableItem = nil
	xrCarBody.selectedHashes = {}

	xrCarBody.gridTexture = exports.sp_assets:xrLoadAsset( "ui_grid" )

	setElementData( localPlayer, "uib", true, true )

	exports.sp_hud_real_new:xrHUDSetEnabled( false )
end

function xrCarBody.release ( )
	if xrCarBody.visible ~= true then
		return
	end
	
	removeEventHandler ( "onClientRender", root, xrCarBody.onRender )
	removeEventHandler ( "onClientCursorMove", root, xrCarBody.onCursorMove )
	removeEventHandler ( "onClientClick", root, xrCarBody.onClick )
	removeEventHandler( "onClientDoubleClick", root, xrCarBody.onDoubleClick )
	removeEventHandler( "onClientKey", root,  xrCarBody.onKey )
	
	showCursor ( false )
	
	for _, slots in pairs( xrCarBody.slots ) do
		for _, slot in pairs( slots ) do
			xrSlotDestroy( slot )
		end
	end
	
	xrCarBody.slots = { }	
	xrCarBody.visible = false

	setElementData( localPlayer, "uib", false, true )

	exports.sp_hud_real_new:xrHUDSetEnabled( true )
end

function xrCarBody.onNewItem( containerId, item )
	local itemSlot = item[ EIA_SLOT ]

	local slots = xrCarBody.slots[ containerId ]
	if slots and slots[ itemSlot ] then
		xrSlotPutItem( slots[ itemSlot ], item )
	end
end

function xrCarBody.onRemoveItem( containerId, item )
	local itemSlot = item[ EIA_SLOT ]

	local slots = xrCarBody.slots[ containerId ]
	if slots and slots[ itemSlot ] then
		xrSlotRemoveItem( slots[ itemSlot ], item )
	end

	local clickedItem = xrCarBody.clickedItem
	if clickedItem and clickedItem[ EIA_ID ] == item[ EIA_ID ] then
		xrCarBody.clickedItem = nil
		xrCarBody.onItemSelected( false )
	end

	local selectedItem = xrCarBody.selectedItem
	if selectedItem and selectedItem[ EIA_ID ] == item[ EIA_ID ] then
		xrCarBody.selectedItem = nil
	end
end

function xrCarBody.onModifyItem( containerId, prevItem, newItem )
	local prevItemSlot = prevItem[ EIA_SLOT ]
	local newItemSlot = newItem[ EIA_SLOT ]

	local slots = xrCarBody.slots[ containerId ]
	if slots then
		if prevItemSlot == newItemSlot then
			-- Обновляем предмет в слоте
			if slots[ newItemSlot ] then
				xrSlotUpdateItem( slots[ newItemSlot ], prevItem[ EIA_ID ], newItem )
			end
		else
			-- Удаляем из предыдущего слота
			if slots[ prevItemSlot ] then
				xrSlotRemoveItem( slots[ prevItemSlot ], prevItem )
			end

			-- Создаем в новом
			if slots[ newItemSlot ] then
				xrSlotPutItem( slots[ newItemSlot ], newItem )
			end

			local selectedItem = xrCarBody.selectedItem
			if selectedItem and selectedItem[ EIA_ID ] == prevItem[ EIA_ID ] then
				xrCarBody.selectedItem = nil
			end
		end
	end
end

function xrCarBody.onRender ( )
	local control = controls.ourBag
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 305, 455, "textures/ui_dg_inventory_exchange_trade.dds" )
	
	local control = controls.othersBag
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 305, 455, "textures/ui_dg_inventory_exchange_trade.dds" )
	local biasx, biasy = _scale ( 30, 8 )
	dxDrawText ( "", control.x + biasx, control.y + biasy, 0, 0, tocolor ( 255, 255, 255, 128 ), 0.8, xrShared.font )
		
	--[[control = controls.ourIcon
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 256, 256, "textures/ui_trade_character.dds" )
	
	control = controls.othersIcon
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 143, 199, "textures/ui_trade_character.dds" )]]

	xrCarBody.frame:draw ( )
	
	control = controls.descWindow
	local width, height = _scale ( 256, 64 )
	biasx, biasy = _scale ( 5, 10 )
	dxDrawImageSection ( control.x - biasx, control.y - biasy, width, height, 0, 0, 256, 64, "textures/ui_inv_info_over_lt.dds" )

	width, height = _scale ( 260, 310 )
	biasx, biasy = _scale ( 5, 180 )
	dxDrawImageSection ( control.x + biasx, control.y + biasy, width, height, 0, 0, 260, 310, "textures/ui_inv_info_over_b.dds" )
	
	local item = xrCarBody.clickedItem
	if item then
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )

		local imageStatic = controls.imageStatic
		local _x = control.x + imageStatic.x
		local _y = control.y + imageStatic.y
		local cellWidth, cellHeight = _scale ( CELL_WIDTH, CELL_HEIGHT )
		local _width = cellWidth*itemSection.inv_grid_width
		local _height = cellHeight*itemSection.inv_grid_height
		dxDrawImageSection ( 
			_x - _width/2, _y - _height/2, 
			_width, _height,
			50*itemSection.inv_grid_x, 50*itemSection.inv_grid_y,
			50*itemSection.inv_grid_width, 50*itemSection.inv_grid_height,
			"textures/ui_icon_equipment.dds"
		)
			
		local descrList = controls.descrList
		_x = control.x + descrList.x
		_y = control.y + descrList.y
		local descText = xrGetLocaleText( _hashFn( itemSection.description ) )
		dxDrawText ( 
			tostring( descText ), 
			_x, _y,
			_x + descrList.width, _y + descrList.height,
			tocolor ( 240, 217, 182 ), 0.7, xrShared.font,
			"left", "top", false, true
		)
	end	
	
	width, height = _scale ( 1024, 32 )
	dxDrawImage ( 0, sh - height, width, height, "textures/ui_bottom_background.dds" )
		
	--[[
		Slots
	]]
	for ownerId, slots in pairs ( xrCarBody.slots ) do
		for slotHash, slot in pairs( slots ) do
			xrSlotDraw( slot )
		end
	end	
	
	if xrCarBody.movableItem then
		local item = xrCarBody.movableItem.item
		local dragdrop = xrCarBody.movableItem.dragdrop
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
			
		local ax, ay = getCursorPosition ( )
		ax, ay = ax * sw, ay * sh			

		dxDrawImageSection ( 
			ax - xrCarBody.movableItem.bx, ay - xrCarBody.movableItem.by, 
			dragdrop.cellWidth*itemSection.inv_grid_width, dragdrop.cellHeight*itemSection.inv_grid_height,
			50*itemSection.inv_grid_x, 50*itemSection.inv_grid_y,
			50*itemSection.inv_grid_width, 50*itemSection.inv_grid_height,
			"textures/ui_icon_equipment.dds"
		)
	end
end

function xrCarBody.onItemSelected( item )
	xrCarBody.selectedHashes = {
		-- Очищаем карту хэшей
	}

	if type( item ) == "table" then
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
		if not itemSection then
			return
		end

		xrCarBody.selectedHashes[ item[ EIA_TYPE ] ] = true

		-- Получаем массив допустимых типов боеприпасов
		local ammoTypes = itemSection.ammo_class
		if type( ammoTypes ) ~= "table" then
			ammoTypes = { ammoTypes }
		end

		for _, ammoType in ipairs( ammoTypes ) do
			if type( ammoType ) == "number" then
				xrCarBody.selectedHashes[ ammoType ] = true
			elseif type( ammoType ) == "string" then
				xrCarBody.selectedHashes[ _hashFn( ammoType ) ] = true
			end
		end
	end
end

function xrCarBody.onCursorMove ( _, _, ax, ay )
	xrCarBody.selectedItem = nil
	xrCarBody.selectedDragDrop = nil
		
	for ownerId, slots in pairs ( xrCarBody.slots ) do
		for slotHash, slot in pairs( slots ) do
			if isPointInRectangle ( ax, ay, slot.x, slot.y, slot.width, slot.height ) then			
				xrCarBody.selectedItem = xrSlotGetItemAt( slot, ax, ay, true )
				xrCarBody.selectedDragDrop = slot
				return
			end
		end
	end
end

function xrCarBody.onClick ( button, state, ax, ay )
	if button ~= "left" then
		return
	end
		
	if state == "down" then		
		if xrCarBody.selectedDragDrop and xrCarBody.selectedItem then
			local column, row = xrCarBody.selectedItem.x, xrCarBody.selectedItem.y
			local x = xrCarBody.selectedDragDrop.x + xrCarBody.selectedDragDrop.cellWidth*column
			local y = xrCarBody.selectedDragDrop.y + xrCarBody.selectedDragDrop.cellHeight*row - xrCarBody.selectedDragDrop.scroll
	
			xrCarBody.movableItem = {
				item = xrCarBody.selectedItem,
				dragdrop = xrCarBody.selectedDragDrop,
				bx = ax - x, by = ay - y,
				x = ax, y = ay
			}

			xrCarBody.clickedItem = xrCarBody.selectedItem
			xrCarBody.onItemSelected( xrCarBody.selectedItem )
		else
			xrCarBody.movableItem = nil
		end
	else
		if xrCarBody.movableItem and xrCarBody.selectedDragDrop then
			local deltax = xrCarBody.movableItem.x - ax
			local deltay = xrCarBody.movableItem.y - ay
			if math.abs( deltax ) < 10 or math.abs( deltay ) < 10 then
				xrCarBody.movableItem = nil
				return
			end

			local oldItem = xrCarBody.movableItem.item
			local oldDragDrop = xrCarBody.movableItem.dragdrop
			
			local _x, _y = ax, ay
			local column, row = math.floor ( ( _x - xrCarBody.selectedDragDrop.x ) / xrCarBody.selectedDragDrop.cellWidth ), math.floor ( ( _y - xrCarBody.selectedDragDrop.y ) / xrCarBody.selectedDragDrop.cellHeight )
			
			-- Проверяем на вместимость			
			if xrSlotTestPlace( xrCarBody.selectedDragDrop, oldItem[ EIA_TYPE ], column, row ) then
				local oldSlotHash = oldDragDrop.type
				local newSlotHash = xrCarBody.selectedDragDrop.type				

				triggerServerEvent( EServerEvents.onSessionItemMove, localPlayer, oldItem[ EIA_ID ], oldDragDrop.owner, oldSlotHash, xrCarBody.selectedDragDrop.owner, newSlotHash )
			end			
		end
		xrCarBody.movableItem = nil
	end
end

function xrCarBody.onDoubleClick( button, ax, ay )
	if button ~= "left" then
		return
	end

	if xrCarBody.selectedDragDrop and xrCarBody.selectedItem then
		triggerServerEvent( EServerEvents.onSessionItemUse, localPlayer, xrCarBody.selectedItem[ EIA_ID ], xrCarBody.selectedDragDrop.owner, xrCarBody.selectedItem[ EIA_SLOT ] )
	end
end

function xrCarBody.onKey( btn, btnState )
	if not xrCarBody.selectedDragDrop then
		return
	end

	if btn == "mouse_wheel_up" then
		xrSlotAddScroll( xrCarBody.selectedDragDrop, -30 )	
	elseif btn == "mouse_wheel_down" then
		xrSlotAddScroll( xrCarBody.selectedDragDrop, 30 )
	end
end
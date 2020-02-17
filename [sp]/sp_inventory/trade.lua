--[[
	controls
]]
local controls = {
	ourIcon = {
		x = 27, y = 22,
		width = 256, height = 256
	},
	othersIcon = {
		x = 843, y = 22,
		width = 143, height = 199
	},
	ourBag = {
		x = 20, y = 270,
		width = 290, height = 450
	},
	othersBag = {
		x = 705, y = 270,
		width = 305, height = 455
	},
	ourTrade = {
		x = 338, y = 260,
		width = 347, height = 212
	},
	othersTrade = {
		x = 338, y = 480,
		width = 347, height = 212
	},
	descWindow = {
		x = 350, y = 22,
		width = 320, height = 230
	},
	tradeBtn = {
		x = 350, y = 705,
		width = 107, height = 36
	},
	leaveBtn = {
		x = 570, y = 705,
		width = 107, height = 36
	},
	
	itemName = {
		x = 20, y = 15,
		width = 165, height = 25
	},
	itemWeight = {
		x = 190, y = 15,
		width = 140, height = 18
	},
	itemCost = {
		x = 190, y = 51,
		width = 240, height = 18
	},
	itemCondition = {
		x = 190, y = 33,
		width = 240, height = 18
	},
	itemDesc = {
		x = 20, y = 70,
		width = 289, height = 130
	},
	
	dragdropOur = {
		x = 20 + 29, y = 270 + 37,
		width = 240, height = 450,
		dragdrop = true,
		cols = 6, rows = 10,
		slot = _hashFn( "slot_bag" ),
		cellSize = 41,
		isMyOwn = true,
		scrollable = true
	},
	dragdropOthers = {
		x = 705 + 28, y = 270 + 35,
		width = 240, height = 400,
		dragdrop = true,
		cols = 6, rows = 10,
		slot = _hashFn( "slot_bag" ),
		cellSize = 41,
		scrollable = true
	},
	dragdropTradeOur = {
		x = 338 + 31, y = 260 + 37,
		width = 280, height = 160,
		dragdrop = true,
		cols = 7, rows = 4,
		slot = _hashFn( "slot_trade" ),
		cellSize = 41,
		isMyOwn = true,
		scrollable = true
	},
	dragdropTradeOthers = {
		x = 338 + 31, y = 480 + 37,
		width = 280, height = 160,
		dragdrop = true,
		cols = 7, rows = 4,
		slot = _hashFn( "slot_trade" ),
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
local ui_frame_03 = {
	left_top = { "ui_frame_03/ui_frame_03_lt", width = 64, height = 64 },
	top = { "ui_frame_03/ui_frame_03_t", width = 128, height = 64 },
	right_top = { "ui_frame_03/ui_frame_03_rt", width = 64, height = 64 },
	left = { "ui_frame_03/ui_frame_03_l", width = 64, height = 128 },
	back = { "ui_frame_03/ui_frame_03_back", width = 64, height = 64 },
	right = { "ui_frame_03/ui_frame_03_r", width = 64, height = 128 },
	left_bottom = { "ui_frame_03/ui_frame_03_lb", width = 64, height = 64 },
	bottom = { "ui_frame_03/ui_frame_03_b", width = 128, height = 64 },
	right_bottom = { "ui_frame_03/ui_frame_03_rb", width = 64, height = 64 }
}

local errorCodes = {
	"У вас недостаточно денег",
	"Ваш оппонент отказывается покупать это барахло"
}

--[[
	xrTrade
]]
xrTrade = {
	slots = { }
}

function xrTrade.open( id0, id1, classHash1 )
	if xrTrade.visible then
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
	xrTrade.frame = UIFrame.new ( control.x, control.y, control.width, control.height, ui_frame_03 )

	xrTrade.slots = {
		[ id0 ] = {},
		[ id1 ] = {}
	}
	
	for _, control in pairs ( controls ) do
		if control.dragdrop then
			local slot = xrSlotCreate( control.cols, control.rows, control.x, control.y, control.cellSize, control.cellSize, control.scrollable )
			xrSlotSetEnvironment( slot, xrTrade )
			slot.type = control.slot			

			if control.isMyOwn then
				xrTrade.slots[ id0 ][ control.slot ] = slot
				slot.owner = id0
			else
				xrTrade.slots[ id1 ][ control.slot ] = slot
				slot.owner = id1
			end
		end
	end

	-- Заполняем слоты нашими вещами
	for id, item in pairs ( items0 ) do
		local itemSlot = item[ EIA_SLOT ]
		if itemSlot ~= EHashes.SlotTemp and xrTrade.slots[ id0 ][ itemSlot ] then
			xrSlotPutItem( xrTrade.slots[ id0 ][ itemSlot ], item )
		end
	end

	for id, item in pairs ( items1 ) do
		local itemSlot = item[ EIA_SLOT ]
		if itemSlot ~= EHashes.SlotTemp and xrTrade.slots[ id1 ][ itemSlot ] then
			xrSlotPutItem( xrTrade.slots[ id1 ][ itemSlot ], item )
		end
	end	

	addEventHandler( "onClientRender", root, xrTrade.onRender, false )
	addEventHandler( "onClientCursorMove", root, xrTrade.onCursorMove, false )
	addEventHandler( "onClientClick", root, xrTrade.onClick, false )
	addEventHandler( "onClientDoubleClick", root, xrTrade.onDoubleClick, false )
	addEventHandler( "onClientKey", root,  xrTrade.onKey, false )
	
	showCursor ( true )
	
	xrTrade.ourPrice = 0
	xrTrade.othersPrice = 0
	xrTrade.oursId = id0
	xrTrade.othersHash = classHash1
	
	xrTrade.visible = true
	xrTrade.btnState = 0
	xrTrade.clickedItem = nil
	xrTrade.movableItem = nil
	xrTrade.selectedHashes = {}

	xrTrade.gridTexture = exports.sp_assets:xrLoadAsset( "ui_grid" )
	xrTrade.npcTexture = exports.sp_assets:xrLoadAsset( "ui_icons_npc" )

	setElementData( localPlayer, "uib", true, true )

	exports.sp_hud_real_new:xrHUDSetEnabled( false )
end

function xrTrade.release ( )
	if xrTrade.visible ~= true then
		return
	end
	
	removeEventHandler ( "onClientRender", root, xrTrade.onRender )
	removeEventHandler ( "onClientCursorMove", root, xrTrade.onCursorMove )
	removeEventHandler ( "onClientClick", root, xrTrade.onClick )
	removeEventHandler( "onClientDoubleClick", root, xrTrade.onDoubleClick )
	removeEventHandler( "onClientKey", root, xrTrade.onKey )
	
	showCursor ( false )
	
	for _, slots in pairs( xrTrade.slots ) do
		for _, slot in pairs( slots ) do
			xrSlotDestroy( slot )
		end
	end
	
	xrTrade.slots = { }	
	xrTrade.visible = false

	setElementData( localPlayer, "uib", false, true )

	exports.sp_hud_real_new:xrHUDSetEnabled( true )
end

function xrTrade.onNewItem( containerId, item )
	local itemSlot = item[ EIA_SLOT ]

	local slots = xrTrade.slots[ containerId ]
	if slots and slots[ itemSlot ] then
		xrSlotPutItem( slots[ itemSlot ], item )
		xrTrade.updateCost( containerId )
	end
end

function xrTrade.onRemoveItem( containerId, item )
	local itemSlot = item[ EIA_SLOT ]

	local slots = xrTrade.slots[ containerId ]
	if slots and slots[ itemSlot ] then
		xrSlotRemoveItem( slots[ itemSlot ], item )
		xrTrade.updateCost( containerId )
	end

	local clickedItem = xrTrade.clickedItem
	if clickedItem and clickedItem[ EIA_ID ] == item[ EIA_ID ] then
		xrTrade.clickedItem = nil
		xrTrade.onItemSelected( false )
	end

	local selectedItem = xrTrade.selectedItem
	if selectedItem and selectedItem[ EIA_ID ] == item[ EIA_ID ] then
		xrTrade.selectedItem = nil
	end
end

function xrTrade.onModifyItem( containerId, prevItem, newItem )
	local prevItemSlot = prevItem[ EIA_SLOT ]
	local newItemSlot = newItem[ EIA_SLOT ]	

	local slots = xrTrade.slots[ containerId ]
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

			local selectedItem = xrTrade.selectedItem
			if selectedItem and selectedItem[ EIA_ID ] == prevItem[ EIA_ID ] then
				xrTrade.selectedItem = nil
			end
		end

		xrTrade.updateCost( containerId )
	end
end

function xrTrade.updateCost( containerId )
	local totalCost = exports[ "xritems" ]:xrContainerGetSlotCost( containerId, EHashes.SlotTrade, containerId == xrTrade.oursId )
	if containerId == xrTrade.oursId then
		xrTrade.ourPrice = totalCost
	else
		xrTrade.othersPrice = totalCost
	end
end

function xrTrade.showError( str )
	xrTrade.errorStr = str
	xrTrade.errorTime = getTickCount()
end

function xrTrade.onRender ( )
	local biasx, biasy = _scale ( 35, 10 )

	local iconBiasX, iconBiasY = _scale( 9, 27 )
	local iconWidth, iconHeight = _scale( 133 - 9, 133 - 27 )
	local iconSize = math.min( iconWidth, iconHeight )
	local iconHalfSize = iconSize / 2

	local control = controls.ourBag
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 305, 455, "textures/ui_dg_inventory_exchange_trade.dds" )
	local money = getElementData( localPlayer, "money", false ) or 0
	dxDrawText ( money .. " р.", control.x + biasx, control.y + biasy, 0, 0, tocolor ( 238, 153, 26 ), 0.8, xrShared.font )
	
	control = controls.othersBag
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 305, 455, "textures/ui_dg_inventory_exchange_trade.dds" )
	money = "--"
	dxDrawText ( money .. " р.", control.x + biasx, control.y + biasy, 0, 0, tocolor ( 238, 153, 26 ), 0.8, xrShared.font )
	
	control = controls.ourTrade
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 347, 212, "textures/ui_trade_list_back.dds" )	
	dxDrawText ( "Ваши предметы", control.x + biasx, control.y + biasy, 0, 0, tocolor ( 238, 153, 26 ), 0.8, xrShared.font )
	dxDrawText ( "Цена:", control.x + biasx + _scale ( 175 ), control.y + biasy, 0, 0, tocolor ( 220, 185, 140 ), 0.8, xrShared.font )
	dxDrawText ( xrTrade.ourPrice, control.x + biasx + _scale ( 230 ), control.y + biasy, 0, 0, tocolor ( 240, 215, 185 ), 0.8, xrShared.font )
	
	control = controls.othersTrade
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 347, 212, "textures/ui_trade_list_back.dds" )
	dxDrawText ( "Предметы оппонента", control.x + biasx, control.y + biasy, 0, 0, tocolor ( 238, 153, 26 ), 0.8, xrShared.font )
	dxDrawText ( "Цена:", control.x + biasx + _scale ( 175 ), control.y + biasy, 0, 0, tocolor ( 220, 185, 140 ), 0.8, xrShared.font )
	dxDrawText ( xrTrade.othersPrice, control.x + biasx + _scale ( 230 ), control.y + biasy, 0, 0, tocolor ( 240, 215, 185 ), 0.8, xrShared.font )

	xrTrade.frame:draw ( )
	
	--[[
		Description
	]]
	local item = xrTrade.clickedItem
	if xrTrade.errorStr then
		local base = controls.descWindow
		--control = controls.itemDesc
		dxDrawText ( 
			tostring( xrTrade.errorStr ), 
			base.x, base.y, 
			base.x + base.width, base.y + base.height,
			tocolor ( 238, 155, 23 ), 1, xrShared.font,
			"center", "center", false, true
		)

		local now = getTickCount()
		if now - xrTrade.errorTime > 5000 then
			xrTrade.errorStr = nil
			xrTrade.errorTime = nil
		end
	elseif item then
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )		
			
		local base = controls.descWindow

		local nameText = xrGetLocaleText( _hashFn( itemSection.inv_name ) )
		control = controls.itemName
		dxDrawText ( tostring( nameText ), base.x + control.x, base.y + control.y, 0, 0, tocolor ( 238, 155, 23 ), 0.8, xrShared.font )

		control = controls.itemWeight
		dxDrawText ( "Масса: " .. itemSection.inv_weight .. " кг", base.x + control.x, base.y + control.y, 0, 0, tocolor ( 240, 217, 182 ), 0.8, xrShared.font )

		control = controls.itemCost
		dxDrawText ( "Стоимость: " .. itemSection.cost .. " р.", base.x + control.x, base.y + control.y, 0, 0, tocolor ( 240, 217, 182 ), 0.8, xrShared.font )

		local condition = item[ EIA_CONDITION ] or 1
		control = controls.itemCondition
		dxDrawText ( "Состояние: " .. math.floor( condition * 100 ) .. "%", base.x + control.x, base.y + control.y, 0, 0, tocolor ( 240, 217, 182 ), 0.8, xrShared.font )
		
		local descText = xrGetLocaleText( _hashFn( itemSection.description ) )
		control = controls.itemDesc
		dxDrawText ( 
			tostring( descText ), 
			base.x + control.x, base.y + control.y, 
			base.x + control.x + control.width, base.y + control.y + control.height,
			tocolor ( 240, 217, 182 ), 0.6, xrShared.font,
			"left", "top", false, true
		)
	end

	width, height = _scale ( 1024, 32 )
	dxDrawImage ( 0, 0, width, height, "textures/ui_top_background.dds" )
	
	width, height = _scale ( 1024, 32 )
	dxDrawImage ( 0, sh - height, width, height, "textures/ui_bottom_background.dds" )
	
	control = controls.tradeBtn
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 107, 36, "textures/ui_button_05.dds" )
	dxDrawText ( "Торговать", control.x, control.y, control.x + control.width, control.y + control.height, tocolor ( 238, 153, 26 ), 0.8, xrShared.font, "center", "center" )
	
	control = controls.leaveBtn
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 107, 36, "textures/ui_button_06.dds" )
	dxDrawText ( "Выйти", control.x, control.y, control.x + control.width, control.y + control.height, tocolor ( 238, 153, 26 ), 0.8, xrShared.font, "center", "center" )
		
	--[[
		Slots
	]]
	for ownerId, slots in pairs ( xrTrade.slots ) do
		for slotHash, slot in pairs( slots ) do
			xrSlotDraw( slot )
		end
	end	
	
	if xrTrade.movableItem then
		local item = xrTrade.movableItem.item
		local dragdrop = xrTrade.movableItem.dragdrop
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
			
		local ax, ay = getCursorPosition ( )
		ax, ay = ax * sw, ay * sh
			
		dxDrawImageSection ( 
			ax - xrTrade.movableItem.bx, ay - xrTrade.movableItem.by, 
			dragdrop.cellWidth*itemSection.inv_grid_width, dragdrop.cellHeight*itemSection.inv_grid_height,

			50*itemSection.inv_grid_x, 50*itemSection.inv_grid_y,
			50*itemSection.inv_grid_width, 50*itemSection.inv_grid_height,
			"textures/ui_icon_equipment.dds"
		)
	end
end

function xrTrade.onItemSelected( item )
	xrTrade.selectedHashes = {
		-- Очищаем карту хэшей
	}

	if type( item ) == "table" then
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
		if not itemSection then
			return
		end

		xrTrade.selectedHashes[ item[ EIA_TYPE ] ] = true

		-- Получаем массив допустимых типов боеприпасов
		local ammoTypes = itemSection.ammo_class
		if type( ammoTypes ) ~= "table" then
			ammoTypes = { ammoTypes }
		end

		for _, ammoType in ipairs( ammoTypes ) do
			if type( ammoType ) == "number" then
				xrTrade.selectedHashes[ ammoType ] = true
			elseif type( ammoType ) == "string" then
				xrTrade.selectedHashes[ _hashFn( ammoType ) ] = true
			end
		end
	end
end

function xrTrade.onCursorMove ( _, _, ax, ay )
	xrTrade.btnState = 0
	control = controls.tradeBtn
	if isPointInRectangle ( ax, ay, control.x, control.y, control.width, control.height ) then
		xrTrade.btnState = 1
		return
	end
	control = controls.leaveBtn
	if isPointInRectangle ( ax, ay, control.x, control.y, control.width, control.height ) then
		xrTrade.btnState = 2
		return
	end

	xrTrade.selectedItem = nil
	xrTrade.selectedDragDrop = nil
		
	for ownerId, slots in pairs ( xrTrade.slots ) do
		for slotHash, slot in pairs( slots ) do
			if isPointInRectangle ( ax, ay, slot.x, slot.y, slot.width, slot.height ) then			
				xrTrade.selectedItem = xrSlotGetItemAt( slot, ax, ay, true )
				xrTrade.selectedDragDrop = slot
				return
			end
		end
	end	
end

function xrTrade.onClick ( button, state, ax, ay )
	if button ~= "left" then
		return
	end

	-- Trade button
	if xrTrade.btnState == 1 then
		triggerServerEvent( EServerEvents.onSessionTradeOp, localPlayer )
		return

	-- Leave button
	elseif xrTrade.btnState == 2 then
		triggerServerEvent( EServerEvents.onSessionStop, localPlayer )
		return
	end
		
	if state == "down" then
		if xrTrade.selectedDragDrop and xrTrade.selectedItem then
			local column, row = xrTrade.selectedItem.x, xrTrade.selectedItem.y
			local x = xrTrade.selectedDragDrop.x + xrTrade.selectedDragDrop.cellWidth*column
			local y = xrTrade.selectedDragDrop.y + xrTrade.selectedDragDrop.cellHeight*row - xrTrade.selectedDragDrop.scroll
	
			xrTrade.movableItem = {
				item = xrTrade.selectedItem,
				dragdrop = xrTrade.selectedDragDrop,
				bx = ax - x, by = ay - y,
				x = ax, y = ay
			}

			xrTrade.clickedItem = xrTrade.selectedItem
			xrTrade.onItemSelected( xrTrade.selectedItem )
			xrTrade.errorStr = nil
		else
			xrTrade.movableItem = nil
		end		
	else
		if xrTrade.movableItem and xrTrade.selectedDragDrop then
			local deltax = xrTrade.movableItem.x - ax
			local deltay = xrTrade.movableItem.y - ay
			if math.abs( deltax ) < 10 or math.abs( deltay ) < 10 then
				xrTrade.movableItem = nil
				return
			end

			local oldItem = xrTrade.movableItem.item
			local oldDragDrop = xrTrade.movableItem.dragdrop
			
			--local _x, _y = ax - xrTrade.movableItem.bx + CELL_WIDTH/2, ay - xrTrade.movableItem.by + CELL_HEIGHT/2
			local _x, _y = ax, ay
			local column, row = math.floor ( ( _x - xrTrade.selectedDragDrop.x ) / xrTrade.selectedDragDrop.cellWidth ), math.floor ( ( _y - xrTrade.selectedDragDrop.y ) / xrTrade.selectedDragDrop.cellHeight )
			
			-- Проверяем на вместимость			
			if xrSlotTestPlace( xrTrade.selectedDragDrop, oldItem[ EIA_TYPE ], column, row ) then
				local oldSlotHash = oldDragDrop.type
				local newSlotHash = xrTrade.selectedDragDrop.type				

				triggerServerEvent( EServerEvents.onSessionItemMove, localPlayer, oldItem[ EIA_ID ], oldDragDrop.owner, oldSlotHash, xrTrade.selectedDragDrop.owner, newSlotHash )
			end			
		end
		xrTrade.movableItem = nil
	end
end

function xrTrade.onKey( btn, btnState )
	if not xrTrade.selectedDragDrop then
		return
	end

	if btn == "mouse_wheel_up" then
		xrSlotAddScroll( xrTrade.selectedDragDrop, -30 )
	elseif btn == "mouse_wheel_down" then
		xrSlotAddScroll( xrTrade.selectedDragDrop, 30 )
	end
end

function xrTrade.onDoubleClick( button, ax, ay )
	if button ~= "left" then
		return
	end

	if xrTrade.selectedDragDrop and xrTrade.selectedItem then
		triggerServerEvent( EServerEvents.onSessionItemUse, localPlayer, xrTrade.selectedItem[ EIA_ID ], xrTrade.selectedDragDrop.owner, xrTrade.selectedItem[ EIA_SLOT ] )
	end
end

function onTradeError( errorCode )
	local str = errorCodes[ errorCode ]
	if str then
		xrTrade.showError( str )
	end
end

function initTrade()
	addEvent( EClientEvents.onClientTradeError, true )
	addEventHandler( EClientEvents.onClientTradeError, localPlayer, onTradeError, false )
end

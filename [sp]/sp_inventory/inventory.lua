--[[
	controls
]]
local controls = {
	bagWindow = {
		x = 10, y = 260,
		width = 350, height = 480
	},
	descWindow = {
		x = 370, y = 260,
		width = 335, height = 455
	},
	charWindow = {
		x = 730, y = 260,
		width = 268, height = 460
	},
	beltWindow = {
		x = 10, y = 140,
		width = 1014, height = 128
	},
	quickSlots = {
		x = 15, y = 0,
		width = 1024, height = 128
	},
	
	progressHealth = {
		x = 15, y = 65,
		width = 20, height = 215
	},
	progressSatiety = {
		x = 35, y = 65,
		width = 20, height = 215
	},
	progressPower = {
		x = 55, y = 65,
		width = 20, height = 215
	},
	progressRad = {
		x = 75, y = 65,
		width = 20, height = 215
	},
	charIcon = {
		x = 110, y = 65,
		width = 130, height = 215
	},
		
	dragdropBelt = {
		x = 27, y = 174,
		width = 1024, height = 60,
		dragdrop = true,
		cols = 18, rows = 1,
		slot = _hashFn( "slot_belt" )
	},
	dragdropBag = {
		x = 10 + 30, y = 260 + 35,
		width = 400, height = 350,
		dragdrop = true,
		cols = 7, rows = 10,
		slot = _hashFn( "slot_bag" ),
		cellSize = 41,
		scrollable = true
	},
	dragdropSlot1 = {
		x = 15 + 23, y = 14,
		width = 120, height = 120,
		dragdrop = true,
		cols = 2, rows = 2,
		slot = _hashFn( "slot_knife" ),
		cellSize = 52
	},
	dragdropSlot2 = {
		x = 15 + 168, y = 14,
		width = 120, height = 120,
		dragdrop = true,
		cols = 2, rows = 2,
		slot = _hashFn( "slot_pistol" ),
		cellSize = 52
	},
	dragdropSlot3 = {
		x = 15 + 313, y = 14,
		width = 320, height = 120,
		dragdrop = true,
		cols = 6, rows = 2,
		slot = _hashFn( "slot_automatic" ),
		cellSize = 52
	},
	dragdropSlot4 = {
		x = 15 + 670, y = 14,
		width = 100, height = 120,
		dragdrop = true,
		cols = 2, rows = 2,
		slot = _hashFn( "slot_grenade" ),
		cellSize = 51
	},
	dragdropSlot5 = {
		x = 15 + 818, y = 14,
		width = 150, height = 120,
		dragdrop = true,
		cols = 3, rows = 2,
		slot = _hashFn( "slot_smth" ),
		cellSize = 51
	},
	
	descrList = {
		x = 20, y = 230,
		width = 306, height = 144
	},
	imageStatic = {
		x = 150, y = 115,
		width = 300, height = 160
	},

	affectsList = {
		x = 745, y = 610,
		width = 235, height = 75
	},
	money = {
		x = 760, y = 580,
		width = 200, height = 18
	}
}

resizeControls( controls, 1024, 768 )

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

local itemMenuItems = {
	"Использовать",
	"Выбросить",
	"Выбросить всё"
}
local itemMenuItemHeight = 20
local itemMenuWidth = 100
local itemMenuHeight = #itemMenuItems * itemMenuItemHeight
local itemMenuFunctors = {
	[ 1 ] = function( menu )
		triggerServerEvent( EServerEvents.onSessionItemUse, localPlayer, menu.item[ EIA_ID ], menu.dragdrop.owner, menu.item[ EIA_SLOT ] )
	end,
	[ 2 ] = function( menu )
		triggerServerEvent( EServerEvents.onSessionItemDrop, localPlayer, menu.item[ EIA_ID ], menu.dragdrop.owner, menu.item[ EIA_SLOT ], false )
	end,
	[ 3 ] = function( menu )
		triggerServerEvent( EServerEvents.onSessionItemDrop, localPlayer, menu.item[ EIA_ID ], menu.dragdrop.owner, menu.item[ EIA_SLOT ], true )
	end
}

--[[
	xrInventory
]]
xrInventory = {
	items = {
		-- Все вещи, находящиеся в данный момент в инвентаре
	},
	slots = {},
	selectedHashes = {
		-- Хэши типов предметов, которые должны быть выделены
	}
}

function xrInventory.open( id0 )
	if xrInventory.visible then
		return
	end

	local items0 = exports[ "xritems" ]:xrGetContainerItems( id0 )
	if not items0 then
		outputDebugString( "У локального игрока нет конейтнера!", 1 )
		return
	end
			
	local control = controls.charWindow
	xrInventory.frame = UIFrame.new( control.x, control.y, control.width, control.height, ui_frame_03 )
	
	-- Создаем слоты
	for _, control in pairs( controls ) do
		if control.dragdrop then
			local slot = xrSlotCreate( control.cols, control.rows, control.x, control.y, control.cellSize, control.cellSize, control.scrollable )
			xrSlotSetEnvironment( slot, xrInventory )
			slot.type = control.slot
			slot.owner = id0

			xrInventory.slots[ control.slot ] = slot
		end
	end
	
	-- Заполняем слоты нашими вещами
	for id, item in pairs ( items0 ) do
		local itemSlot = item[ EIA_SLOT ]
		if itemSlot ~= EHashes.SlotTemp then
			xrSlotPutItem( xrInventory.slots[ itemSlot ], item )
		end
	end

	addEventHandler( "onClientRender", root, xrInventory.onRender, false )
	addEventHandler( "onClientCursorMove", root, xrInventory.onCursorMove, false )
	addEventHandler( "onClientClick", root, xrInventory.onClick, false )
	addEventHandler( "onClientDoubleClick", root, xrInventory.onDoubleClick, false )
	addEventHandler( "onClientKey", root, xrInventory.onKey, false )
	
	showCursor ( true )
	
	xrInventory.visible = true
	xrInventory.clickedItem = nil
	xrInventory.movableItem = nil
	xrInventory.itemMenu = nil
	xrInventory.selectedHashes = {}
	xrInventory.totalWeight = exports.xritems:xrGetContainerWeight( localPlayer ) or 0

	xrInventory.gridTexture = exports.sp_assets:xrLoadAsset( "ui_grid" )
	xrInventory.npcTexture = exports.sp_assets:xrLoadAsset( "ui_icons_npc" )

	setElementData( localPlayer, "uib", true, true )

	exports.sp_hud_real_new:xrHUDSetEnabled( false )
end

function xrInventory.release ( )
	if xrInventory.visible ~= true then
		return
	end
	
	removeEventHandler( "onClientRender", root, xrInventory.onRender )
	removeEventHandler( "onClientCursorMove", root, xrInventory.onCursorMove )
	removeEventHandler( "onClientClick", root, xrInventory.onClick )
	removeEventHandler( "onClientDoubleClick", root, xrInventory.onDoubleClick )
	removeEventHandler( "onClientKey", root, xrInventory.onKey )
	
	showCursor ( false )
	
	xrInventory.items = { }

	for _, slot in pairs( xrInventory.slots ) do
		xrSlotDestroy( slot )
	end

	xrInventory.slots = { }	
	xrInventory.visible = false
	xrInventory.itemMenu = nil	

	setElementData( localPlayer, "uib", false, true )

	exports.sp_hud_real_new:xrHUDSetEnabled( true )
end

function xrInventory.onNewItem( containerId, item )
	local itemSlot = item[ EIA_SLOT ]

	local slot = xrInventory.slots[ itemSlot ]
	if slot then
		xrSlotPutItem( slot, item )
	end

	xrInventory.totalWeight = exports.xritems:xrGetContainerWeight( localPlayer ) or 0
end

function xrInventory.onRemoveItem( containerId, item )
	local itemSlot = item[ EIA_SLOT ]

	local slot = xrInventory.slots[ itemSlot ]
	if slot then
		xrSlotRemoveItem( slot, item )
	end

	local clickedItem = xrInventory.clickedItem
	if clickedItem and clickedItem[ EIA_ID ] == item[ EIA_ID ] then
		xrInventory.clickedItem = nil
		xrInventory.onItemSelected( false )
	end

	local selectedItem = xrInventory.selectedItem
	if selectedItem and selectedItem[ EIA_ID ] == item[ EIA_ID ] then
		xrInventory.selectedItem = nil
	end

	xrInventory.totalWeight = exports.xritems:xrGetContainerWeight( localPlayer ) or 0
end

function xrInventory.onModifyItem( containerId, prevItem, newItem )
	local prevItemSlot = prevItem[ EIA_SLOT ]
	local newItemSlot = newItem[ EIA_SLOT ]

	if prevItemSlot == newItemSlot then
		-- Обновляем предмет в слоте
		if xrInventory.slots[ newItemSlot ] then
			xrSlotUpdateItem( xrInventory.slots[ newItemSlot ], prevItem[ EIA_ID ], newItem )
		end
	else
		-- Удаляем из предыдущего слота
		if xrInventory.slots[ prevItemSlot ] then
			xrSlotRemoveItem( xrInventory.slots[ prevItemSlot ], prevItem )
		end

		-- Создаем в новом
		if xrInventory.slots[ newItemSlot ] then
			xrSlotPutItem( xrInventory.slots[ newItemSlot ], newItem )
		end

		local selectedItem = xrInventory.selectedItem
		if selectedItem and selectedItem[ EIA_ID ] == prevItem[ EIA_ID ] then
			xrInventory.selectedItem = nil
		end
	end

	xrInventory.totalWeight = exports.xritems:xrGetContainerWeight( localPlayer ) or 0
end

local sorbationAttributes = {
	{ name = "burn_immunity", text = "Ожог" },
	{ name = "strike_immunity", text = "Пулестойкость" },
	{ name = "shock_immunity", text = "Электрошок" },
	{ name = "wound_immunity", text = "Кровотечение" },
	{ name = "radiation_immunity", text = "Радиация" },
	{ name = "telepatic_immunity", text = "Телепатия" },
	{ name = "chemical_burn_immunity", text = "Хим. ожог" },
	{ name = "explosion_immunity", text = "Разрыв" },
	{ name = "fire_wound_immunity", text = "Удар" }	
}

local restoreAttributes = {
	{ name = "health_restore_speed", text = "Восст. здоровья" },
	{ name = "power_restore_speed", text = "Восст. сил" },
	{ name = "radiation_restore_speed", text = "Рад. здоровье" },
	--{ name = "satiety_restore_speed", text = "Насыщение" },
	{ name = "bleeding_restore_speed", text = "Заживление ран" }
}

function xrInventory.drawItemProperties( item, x, y )
	local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )

	local biasy = 0
	local textHeight = dxGetFontHeight( 0.7, xrShared.font ) + 1

	if itemSection.class == EHashes.ArtefactItem then
	-- Restoring
		for i, attribute in ipairs( restoreAttributes ) do
			local value = itemSection[ attribute.name ]
			if value and math.abs( value ) > 0.0001 then
				local valueStr = tostring( value )
				if value > 0 then
					valueStr = ": #00FF00+" .. valueStr
				else
					valueStr = ": #FF0000" .. valueStr
				end
				dxDrawText( attribute.text .. valueStr, x, y + biasy, 0, textHeight, tocolor( 255, 255, 255 ), 0.7, xrShared.font, "left", "top", false, false, false, true, true )
				biasy = biasy + textHeight
			end
		end

		-- Immunity
		local sorbationSection = xrSettingsGetSection( _hashFn( itemSection.hit_absorbation_sect ) )

		for i, attribute in ipairs( sorbationAttributes ) do
			local value = sorbationSection[ attribute.name ]
			if value and math.abs( value ) > 0.0001 then
				local valueStr = tostring( value )
				if value > 0 then
					valueStr = ": #00FF00+" .. valueStr
				else
					valueStr = ": #FF0000" .. valueStr
				end
				dxDrawText( attribute.text .. valueStr, x, y + biasy, 0, textHeight, tocolor( 255, 255, 255 ), 0.7, xrShared.font, "left", "top", false, false, false, true, true )
				biasy = biasy + textHeight
			end
		end
	end
end

function xrInventory.drawAffects()
	local control = controls.affectsList

	local biasy = 0
	local textHeight = dxGetFontHeight( 0.7, xrShared.font ) + 1
	
	local affects = exports.sp_player:PlayerAffector_getAffects()
	for i, value in ipairs( affects or {} ) do
		if math.abs( value ) > 0.0001 then
			local valueStr = tostring( value )
			if value > 0 then
				valueStr = ": #00FF00+" .. valueStr
			else
				valueStr = ": #FF0000" .. valueStr
			end
			dxDrawText( restoreAttributes[ i ].text .. valueStr, control.x, control.y + biasy, 0, textHeight, tocolor( 255, 255, 255 ), 0.7, xrShared.font, "left", "top", false, false, false, true, true )
			biasy = biasy + textHeight
		end
	end
end

function xrInventory.onRender ( )	
	local control = controls.quickSlots
	dxDrawImage ( control.x, control.y, control.width, control.height, "textures/ui_inv_quick_slots.dds" )

	--[[
		Bag
	]]
	control = controls.bagWindow
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 350, 480, "textures/ui_dg_inventory.dds" )

	biasx, biasy = _scale ( 30, 8 )
	dxDrawText ( "Вес: " .. math.round( xrInventory.totalWeight, 3 ) .. " кг", control.x + biasx, control.y + biasy, 0, 0, tocolor ( 231, 153, 22 ), 0.9, xrShared.font )
	
	--[[
		Description
	]]
	control = controls.descWindow
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 335, 455, "textures/ui_dg_info.dds" )
	local item = xrInventory.clickedItem
	if item then
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
		
		biasx, biasy = _scale ( 20, 197 )

		local nameText = xrGetLocaleText( _hashFn( itemSection.inv_name ) )
		dxDrawText ( tostring( nameText ), control.x + biasx, control.y + biasy, 0, 0, tocolor ( 231, 153, 22 ), 0.9, xrShared.font )
		
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

		biasx, biasy = _scale ( 20, 40 )
		xrInventory.drawItemProperties( item, control.x + biasx, control.y + biasy )
	end
	local biasx, biasy = _scale ( 20, 10 )
	dxDrawText ( "Описание", control.x + biasx, control.y + biasy, 0, 0, tocolor ( 231, 153, 22 ), 0.9, xrShared.font )	
		
	--[[
		Character
	]]
	xrInventory.frame:draw ( )
	local base = controls.charWindow

	-- Health bar
	local health = getElementHealth ( localPlayer ) / 100
	if health then
		control = controls.progressHealth

		dxDrawImageSection ( base.x + control.x, base.y + control.y, control.width, control.height, 0, 0, 20, 215, "textures/ui_inv_progress/ui_inv_progress_blood_empty.dds" )
		dxDrawImageSection ( 
			base.x + control.x, base.y + control.y + control.height, control.width, -control.height*health, 
			0, -41, 20, -215*health, "textures/ui_inv_progress/ui_inv_progress_blood.dds",
			0, 0, 0, tocolor ( 255, 0, 0 ) 
		)
	end
		
	-- Satiety bar
	local satiety = 800 / 1000
	if satiety then
		control = controls.progressSatiety

		dxDrawImageSection ( base.x + control.x, base.y + control.y, control.width, control.height, 0, 0, 20, 215, "textures/ui_inv_progress/ui_inv_progress_food_empty.dds" )
		dxDrawImageSection ( 
			base.x + control.x, base.y + control.y + control.height, control.width, -control.height*satiety, 
			0, -41, 20, -215*satiety, "textures/ui_inv_progress/ui_inv_progress_food.dds",
			0, 0, 0, tocolor ( 255, 255, 0 ) 
		)
	end
	
	-- Power bar
	local power = getElementData( localPlayer, "power", false )
	if power then
		control = controls.progressPower

		dxDrawImageSection ( base.x + control.x, base.y + control.y, control.width, control.height, 0, 0, 20, 215, "textures/ui_inv_progress/ui_inv_progress_end_empty.dds" )
		dxDrawImageSection ( 
			base.x + control.x, base.y + control.y + control.height, control.width, -control.height*power, 
			0, -41, 20, -215*power, "textures/ui_inv_progress/ui_inv_progress_end.dds",
			0, 0, 0, tocolor ( 0, 255, 0 ) 
		)
	end
	
	-- Radiation bar
	local radiation = getElementData( localPlayer, "radiation", false )
	if radiation then
		control = controls.progressRad

		dxDrawImageSection ( base.x + control.x, base.y + control.y, control.width, control.height, 0, 0, 20, 215, "textures/ui_inv_progress/ui_inv_progress_rad_empty.dds" )
		dxDrawImageSection ( 
			base.x + control.x, base.y + control.y + control.height, control.width, -control.height*radiation, 
			0, -41, 20, -215*radiation, "textures/ui_inv_progress/ui_inv_progress_rad.dds",
			0, 0, 0, tocolor ( 0, 255, 255 ) 
		)
	end

	-- Character's icon
	local teamHash = getElementData( localPlayer, "faction", false )
	local teamSection = xrSettingsGetSection( teamHash )
	if teamSection then
		control = controls.charIcon
		local aspect = 128 / 320
		local height = control.height
		local width = height * aspect

		dxDrawImageSection( 
			base.x + control.x + control.width/2 - width/2, 
			base.y + control.y + control.height/2 - height/2,
			width, height, teamSection.icon_outfit.x, teamSection.icon_outfit.y, 128, 320, xrInventory.npcTexture 
		)
	end
		
	biasx, biasy = _scale ( 5, 10 )
	local width, height = _scale ( 0, 256 )
	dxDrawImageSection ( base.x - biasx, base.y - biasy, base.width, height, 0, 0, 268, 256, "textures/ui_inv_personal_over_t.dds" )
	width, height = _scale ( 0, 178 )
	dxDrawImageSection ( base.x, base.y + base.height - height, base.width, height, 0, 0, 268, 178, "textures/ui_inv_personal_over_b.dds" )

	xrInventory.drawAffects()	
	
	biasx, biasy = _scale ( 100, 0 )
	dxDrawText ( "Костюм", base.x + biasx, base.y + biasy, 0, 0, tocolor ( 231, 153, 22 ), 0.9, xrShared.font )
	
	--[[
		Belt
	]]
	control = controls.beltWindow
	dxDrawImageSection ( control.x, control.y, control.width, control.height, 0, 0, 1014, 128, "textures/ui_inv_belt.dds" )
	
	biasx, biasy = _scale ( 25, 2 )
	dxDrawText ( "Пояс", control.x + biasx, control.y + biasy, 0, 0, tocolor ( 231, 153, 22 ), 0.9, xrShared.font )
		
	width, height = _scale ( 1024, 32 )
	dxDrawImage ( 0, sh - height, width, height, "textures/ui_bottom_background.dds" )
		
	--[[
		Slots
	]]
	for _, dragdrop in pairs ( xrInventory.slots ) do
		xrSlotDraw( dragdrop )
	end		

	if xrInventory.movableItem then
		local item = xrInventory.movableItem.item
		local dragdrop = xrInventory.movableItem.dragdrop
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
			
		local ax, ay = getCursorPosition ( )
		ax, ay = ax * sw, ay * sh			
			
		dxDrawImageSection ( 
			ax - xrInventory.movableItem.bx, ay - xrInventory.movableItem.by, 
			dragdrop.cellWidth*itemSection.inv_grid_width, dragdrop.cellHeight*itemSection.inv_grid_height,
			50*itemSection.inv_grid_x, 50*itemSection.inv_grid_y,
			50*itemSection.inv_grid_width, 50*itemSection.inv_grid_height,
			"textures/ui_icon_equipment.dds"
		)
	end

	local money = getElementData( localPlayer, "money", false )
	if money then
		control = controls.money

		dxDrawText ( money .. " р.", control.x, control.y, control.x + control.width, control.y + control.height, tocolor( 231, 153, 22 ), 0.9, xrShared.font, "left", "center" )
	end

	local menu = xrInventory.itemMenu
	if menu then
		local ax, ay = getCursorPosition( )
		ax, ay = ax * sw, ay * sh	

		local y = menu.y
		local index = 0
		if isPointInRectangle( ax, ay, menu.x, y, itemMenuWidth, itemMenuHeight ) then
			index = math.floor( ( ay - y ) / itemMenuItemHeight ) + 1			
		end

		dxDrawRectangle( menu.x, y, itemMenuWidth, itemMenuHeight, tocolor( 20, 20, 20, 200 ) )

		for i, text in ipairs( itemMenuItems ) do
			if i == index then
				dxDrawRectangle( menu.x, y, itemMenuWidth, itemMenuItemHeight, tocolor( 204, 99, 20, 190 ) )
			end

			dxDrawText( text, menu.x, y, menu.x + itemMenuWidth, y + itemMenuItemHeight, tocolor( 255, 255, 255 ), 1, "default", "center", "center" )
			y = y + itemMenuItemHeight
		end
	end
end

function xrInventory.onItemSelected( item )
	xrInventory.selectedHashes = {
		-- Очищаем карту хэшей
	}

	if type( item ) == "table" then
		local itemSection = xrSettingsGetSection( item[ EIA_TYPE ] )
		if not itemSection then
			return
		end

		xrInventory.selectedHashes[ item[ EIA_TYPE ] ] = true

		-- Получаем массив допустимых типов боеприпасов
		local ammoTypes = itemSection.ammo_class
		if type( ammoTypes ) ~= "table" then
			ammoTypes = { ammoTypes }
		end

		for _, ammoType in ipairs( ammoTypes ) do
			if type( ammoType ) == "number" then
				xrInventory.selectedHashes[ ammoType ] = true
			elseif type( ammoType ) == "string" then
				xrInventory.selectedHashes[ _hashFn( ammoType ) ] = true
			end
		end
	end
end

function xrInventory.onCursorMove ( _, _, ax, ay )
	xrInventory.selectedItem = nil
	xrInventory.selectedDragDrop = nil

	if xrInventory.itemMenu then
		return
	end

	for _, dragdrop in pairs ( xrInventory.slots ) do
		if isPointInRectangle ( ax, ay, dragdrop.x, dragdrop.y, dragdrop.width, dragdrop.height ) then			
			xrInventory.selectedItem = xrSlotGetItemAt( dragdrop, ax, ay, true )
			xrInventory.selectedDragDrop = dragdrop
			return
		end
	end
end

function xrInventory.onClick( button, state, ax, ay )
	local menu = xrInventory.itemMenu
	if menu and state == "down" then
		-- Курсор находится в меню?
		if isPointInRectangle( ax, ay, menu.x, menu.y, itemMenuWidth, itemMenuHeight ) then
			local index = math.floor( ( ay - menu.y ) / itemMenuItemHeight ) + 1
			if index > 0 and index <= #itemMenuItems then
				itemMenuFunctors[ index ]( menu )
			end
		end

		-- Закрываем меню
		xrInventory.itemMenu = nil

		return
	end

	if button == "right" and state == "down" then
		if xrInventory.selectedDragDrop and xrInventory.selectedItem then
			xrInventory.itemMenu = {
				item = xrInventory.selectedItem,
				dragdrop = xrInventory.selectedDragDrop,
				x = ax,
				y = ay
			}
		end
	end

	if button == "left" then		
		if state == "down" then		
			if xrInventory.selectedDragDrop and xrInventory.selectedItem then
				local column, row = xrInventory.selectedItem.x, xrInventory.selectedItem.y
				local x = xrInventory.selectedDragDrop.x + xrInventory.selectedDragDrop.cellWidth*column
				local y = xrInventory.selectedDragDrop.y + xrInventory.selectedDragDrop.cellHeight*row - xrInventory.selectedDragDrop.scroll
		
				xrInventory.movableItem = {
					item = xrInventory.selectedItem,
					dragdrop = xrInventory.selectedDragDrop,
					bx = ax - x, by = ay - y,
					x = ax, y = ay
				}

				xrInventory.clickedItem = xrInventory.selectedItem
				xrInventory.onItemSelected( xrInventory.selectedItem )
			else
				xrInventory.movableItem = nil
			end
		else
			if xrInventory.movableItem and xrInventory.selectedDragDrop then
				local deltax = xrInventory.movableItem.x - ax
				local deltay = xrInventory.movableItem.y - ay
				if math.abs( deltax ) < 10 or math.abs( deltay ) < 10 then
					xrInventory.movableItem = nil
					return
				end

				local oldItem = xrInventory.movableItem.item
				local oldDragDrop = xrInventory.movableItem.dragdrop
				
				--local _x, _y = ax - xrInventory.movableItem.bx + CELL_WIDTH/2, ay - xrInventory.movableItem.by + CELL_HEIGHT/2
				local _x, _y = ax, ay
				local column, row = math.floor ( ( _x - xrInventory.selectedDragDrop.x ) / xrInventory.selectedDragDrop.cellWidth ), math.floor ( ( _y - xrInventory.selectedDragDrop.y ) / xrInventory.selectedDragDrop.cellHeight )
				
				-- Проверяем на вместимость			
				if xrSlotTestPlace( xrInventory.selectedDragDrop, oldItem[ EIA_TYPE ], column, row ) then
					local oldSlotHash = oldDragDrop.type
					local newSlotHash = xrInventory.selectedDragDrop.type				

					triggerServerEvent( EServerEvents.onSessionItemMove, localPlayer, oldItem[ EIA_ID ], oldDragDrop.owner, oldSlotHash, xrInventory.selectedDragDrop.owner, newSlotHash )
				end			
			end
			xrInventory.movableItem = nil
		end
	end
end

function xrInventory.onDoubleClick( button, ax, ay )
	if button ~= "left" then
		return
	end

	if xrInventory.itemMenu then
		return
	end

	if xrInventory.selectedDragDrop and xrInventory.selectedItem then
		triggerServerEvent( EServerEvents.onSessionItemUse, localPlayer, xrInventory.selectedItem[ EIA_ID ], xrInventory.selectedDragDrop.owner, xrInventory.selectedItem[ EIA_SLOT ] )
	end
end

function xrInventory.onKey( btn, btnState )
	if not xrInventory.selectedDragDrop then
		return
	end

	if xrInventory.itemMenu then
		return
	end

	if btn == "mouse_wheel_up" then
		xrSlotAddScroll( xrInventory.selectedDragDrop, -30 )	
	elseif btn == "mouse_wheel_down" then
		xrSlotAddScroll( xrInventory.selectedDragDrop, 30 )
	end
end
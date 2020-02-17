local sw, sh = guiGetScreenSize ( )

xrExtraTexDict = {

}

xrMain = {
	isEnabled = false
}

function xrMain.init()
	
end

function xrMain.open()	
	if xrMain.isEnabled then
		return
	end

	local gap = 5
	local width, height = 200, 420
	local btnWidth = ( width - gap*3 ) / 2
	local btnHeight = 30

	--[[
		Frames
	]]
	xrMain.framesWnd = guiCreateWindow( 20, sh / 2 - height / 2, width, height, "Frames", false )

	xrMain.framesList = guiCreateGridList( gap, 25, width - gap*2, height - 25 - btnHeight - gap*2, false, xrMain.framesWnd )
	guiGridListSetSortingEnabled( xrMain.framesList, false )
	xrMain.framesColumnName = guiGridListAddColumn( xrMain.framesList, "Frame", 0.7 )
	addEventHandler( "onClientGUIClick", xrMain.framesList,
		function( btn, state )
			if state == "up" then
				local frameIndex = guiGridListGetSelectedItem( source )
				if frameIndex and frameIndex > -1 then
					local frameName = guiGridListGetItemData( source, frameIndex, xrMain.framesColumnName )
					local selectedFrame = xrMain.canvas:getFrame( frameName, true )
					if selectedFrame then
						xrMain:updatePropertiesWnd( selectedFrame )
					end

					xrMain.lastSelectedFrameName = frameName
				end
			end
		end
	, false )

	xrMain.framesAddBtn = guiCreateButton( gap, height - btnHeight - gap, btnWidth, btnHeight, "Add", false, xrMain.framesWnd )
	addEventHandler( "onClientGUIClick", xrMain.framesAddBtn,
		function( btn, state )
			if state == "up" then
				local selectedFrame = xrMain.canvas:getFrame( xrMain.lastSelectedFrameName, true ) or xrMain.canvas.frame
				if selectedFrame then
					xrFrameCreator:open()
				else
					outputChatBox( "Вы должны выбрать фрейм" )
				end
			end
		end
	, false )

	xrMain.framesRemoveBtn = guiCreateButton( gap + btnWidth + gap, height - btnHeight - gap, btnWidth, btnHeight, "Remove", false, xrMain.framesWnd )
	addEventHandler( "onClientGUIClick", xrMain.framesRemoveBtn,
		function( btn, state )
			if state == "up" then
				local selectedFrame = xrMain.canvas:getFrame( xrMain.lastSelectedFrameName, true ) or xrMain.canvas.frame
				if selectedFrame then
					xrMain.lastSelectedFrameName = nil
					selectedFrame:destroy()

					xrMain.canvas:update()
					xrMain:updateFramesList()
				else
					outputChatBox( "Вы должны выбрать фрейм" )
				end
			end
		end
	, false )

	--[[
		Save
	]]
	xrMain.loadWnd = guiCreateWindow( 20, sh / 2 - height / 2 + height + gap, width, 100, "Save/Load", false )

	xrMain.loadNameEdt = guiCreateEdit( gap, 25, width - gap*2, btnHeight, "", false, xrMain.loadWnd )

	xrMain.loadSaveBtn = guiCreateButton( gap, 25 + btnHeight + gap, btnWidth, btnHeight, "Save", false, xrMain.loadWnd )
	addEventHandler( "onClientGUIClick", xrMain.loadSaveBtn,
		function( btn, state )
			local filename = guiGetText( xrMain.loadNameEdt )
			if string.len( filename ) < 3 then
				outputChatBox( "Длина имени должна превышать 3 символа" )
				return
			end

			local xml = xmlCreateFile( filename .. ".xml", "ui" )
			if xml then
				xrMain.canvas:save( xml )

				xmlSaveFile( xml )
				xmlUnloadFile( xml )
			end
		end
	, false )
	xrMain.loadLoadBtn = guiCreateButton( gap*2 + btnWidth, 25 + btnHeight + gap, btnWidth, btnHeight, "Load", false, xrMain.loadWnd )
	addEventHandler( "onClientGUIClick", xrMain.loadLoadBtn,
		function( btn, state )
			local filename = guiGetText( xrMain.loadNameEdt )
			if string.len( filename ) < 3 then
				outputChatBox( "Длина имени должна превышать 3 символа" )
				return
			end

			local xml = xmlLoadFile( filename .. ".xml", true )
			if xml then
				xrMain.canvas:load( xml )
				xrMain.canvas:update()

				xrMain:updateFramesList()

				xmlUnloadFile( xml )
			end
		end
	, false )

	--[[
		Properties
	]]
	xrMain.propsWnd = guiCreateWindow( sw - width - gap, sh / 2 - height / 2, width, height, "Properties", false )
	xrMain.propsDescBtn = guiCreateButton( gap, 25, width - gap*2, btnHeight, "Toggle", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIClick", xrMain.propsDescBtn,
		function( btn, state )
			local frameIndex = guiGridListGetSelectedItem( xrMain.framesList )
			if frameIndex and frameIndex > -1 then
				local frameName = guiGridListGetItemData( xrMain.framesList, frameIndex, xrMain.framesColumnName )
				local selectedFrame = xrMain.canvas:getFrame( frameName, true )
				if frameName == "Canvas" then
					return
				end
				if selectedFrame then
					selectedFrame:setVisible( not selectedFrame.visible )
				end
			end
		end
	, false )
	
	xrMain.propsNameEdt = guiCreateEdit( gap, 25 + btnHeight + gap, width - gap*2, btnHeight, "", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIAccepted", xrMain.propsNameEdt,
		function()
			local frameIndex = guiGridListGetSelectedItem( xrMain.framesList )
			if frameIndex and frameIndex > -1 then
				local frameName = guiGridListGetItemData( xrMain.framesList, frameIndex, xrMain.framesColumnName )
				local selectedFrame = xrMain.canvas:getFrame( frameName, true )
				if frameName == "Canvas" then
					--return
				end
				if selectedFrame then
					xrMain.canvas:onFrameRename( selectedFrame, guiGetText( source ) )
					xrMain:updateFramesList()
				end
			end
		end
	, false )

	local halfWidth = ( width - gap*3 ) / 2

	xrMain.propsAnchorMinXEdt = guiCreateEdit( gap, 25 + btnHeight*2 + gap*2, halfWidth, btnHeight, "", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIAccepted", xrMain.propsAnchorMinXEdt, xrMain.onAnchorEdtAccepted, false )
	xrMain.propsAnchorMinYEdt = guiCreateEdit( gap + halfWidth + gap, 25 + btnHeight*2 + gap*2, halfWidth, btnHeight, "", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIAccepted", xrMain.propsAnchorMinYEdt, xrMain.onAnchorEdtAccepted, false )
	xrMain.propsAnchorMaxXEdt = guiCreateEdit( gap, 25 + btnHeight*3 + gap*3, halfWidth, btnHeight, "", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIAccepted", xrMain.propsAnchorMaxXEdt, xrMain.onAnchorEdtAccepted, false )
	xrMain.propsAnchorMaxYEdt = guiCreateEdit( gap + halfWidth + gap, 25 + btnHeight*3 + gap*3, halfWidth, btnHeight, "", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIAccepted", xrMain.propsAnchorMaxYEdt, xrMain.onAnchorEdtAccepted, false )

	xrMain.propsXEdt = guiCreateEdit( gap, 25 + btnHeight*4 + gap*4, halfWidth, btnHeight, "", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIAccepted", xrMain.propsXEdt, xrMain.onTransformEdtAccepted, false )
	xrMain.propsYEdt = guiCreateEdit( gap + halfWidth + gap, 25 + btnHeight*4 + gap*4, halfWidth, btnHeight, "", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIAccepted", xrMain.propsYEdt, xrMain.onTransformEdtAccepted, false )
	xrMain.propsWidthEdt = guiCreateEdit( gap, 25 + btnHeight*5 + gap*5, halfWidth, btnHeight, "", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIAccepted", xrMain.propsWidthEdt, xrMain.onTransformEdtAccepted, false )
	xrMain.propsHeightEdt = guiCreateEdit( gap + halfWidth + gap, 25 + btnHeight*5 + gap*5, halfWidth, btnHeight, "", false, xrMain.propsWnd )
	addEventHandler( "onClientGUIAccepted", xrMain.propsHeightEdt, xrMain.onTransformEdtAccepted, false )

	local function _createAnchorBtn( x, y, width, height, text, relative, parent )
		local btn = guiCreateButton( x, y, width, height, text, relative, parent )
		addEventHandler( "onClientGUIClick", btn, xrMain.onAnchorBtnClick, false )
	end

	local btnSize = ( width - gap*6 ) / 5
	_createAnchorBtn( gap*1 + btnSize*0, 25 + btnHeight*6 + gap*6, btnSize, btnSize, "[]", false, xrMain.propsWnd )
	_createAnchorBtn( gap*2 + btnSize*1, 25 + btnHeight*6 + gap*6, btnSize, btnSize, "L", false, xrMain.propsWnd )
	_createAnchorBtn( gap*3 + btnSize*2, 25 + btnHeight*6 + gap*6, btnSize, btnSize, "C", false, xrMain.propsWnd )
	_createAnchorBtn( gap*4 + btnSize*3, 25 + btnHeight*6 + gap*6, btnSize, btnSize, "R", false, xrMain.propsWnd )
	_createAnchorBtn( gap*5 + btnSize*4, 25 + btnHeight*6 + gap*6, btnSize, btnSize, "S", false, xrMain.propsWnd )
	
	_createAnchorBtn( gap*1 + btnSize*0, 25 + btnHeight*7 + gap*7, btnSize, btnSize, "T", false, xrMain.propsWnd )
	_createAnchorBtn( gap*2 + btnSize*1, 25 + btnHeight*7 + gap*7, btnSize, btnSize, "TL", false, xrMain.propsWnd )
	_createAnchorBtn( gap*3 + btnSize*2, 25 + btnHeight*7 + gap*7, btnSize, btnSize, "TC", false, xrMain.propsWnd )
	_createAnchorBtn( gap*4 + btnSize*3, 25 + btnHeight*7 + gap*7, btnSize, btnSize, "TR", false, xrMain.propsWnd )
	_createAnchorBtn( gap*5 + btnSize*4, 25 + btnHeight*7 + gap*7, btnSize, btnSize, "TS", false, xrMain.propsWnd )

	_createAnchorBtn( gap*1 + btnSize*0, 25 + btnHeight*8 + gap*8, btnSize, btnSize, "M", false, xrMain.propsWnd )
	_createAnchorBtn( gap*2 + btnSize*1, 25 + btnHeight*8 + gap*8, btnSize, btnSize, "ML", false, xrMain.propsWnd )
	_createAnchorBtn( gap*3 + btnSize*2, 25 + btnHeight*8 + gap*8, btnSize, btnSize, "MC", false, xrMain.propsWnd )
	_createAnchorBtn( gap*4 + btnSize*3, 25 + btnHeight*8 + gap*8, btnSize, btnSize, "MR", false, xrMain.propsWnd )
	_createAnchorBtn( gap*5 + btnSize*4, 25 + btnHeight*8 + gap*8, btnSize, btnSize, "MS", false, xrMain.propsWnd )

	_createAnchorBtn( gap*1 + btnSize*0, 25 + btnHeight*9 + gap*9, btnSize, btnSize, "B", false, xrMain.propsWnd )
	_createAnchorBtn( gap*2 + btnSize*1, 25 + btnHeight*9 + gap*9, btnSize, btnSize, "BL", false, xrMain.propsWnd )
	_createAnchorBtn( gap*3 + btnSize*2, 25 + btnHeight*9 + gap*9, btnSize, btnSize, "BC", false, xrMain.propsWnd )
	_createAnchorBtn( gap*4 + btnSize*3, 25 + btnHeight*9 + gap*9, btnSize, btnSize, "BR", false, xrMain.propsWnd )
	_createAnchorBtn( gap*5 + btnSize*4, 25 + btnHeight*9 + gap*9, btnSize, btnSize, "BS", false, xrMain.propsWnd )

	_createAnchorBtn( gap*1 + btnSize*0, 25 + btnHeight*10 + gap*10, btnSize, btnSize, "S", false, xrMain.propsWnd )
	_createAnchorBtn( gap*2 + btnSize*1, 25 + btnHeight*10 + gap*10, btnSize, btnSize, "SL", false, xrMain.propsWnd )
	_createAnchorBtn( gap*3 + btnSize*2, 25 + btnHeight*10 + gap*10, btnSize, btnSize, "SC", false, xrMain.propsWnd )
	_createAnchorBtn( gap*4 + btnSize*3, 25 + btnHeight*10 + gap*10, btnSize, btnSize, "SR", false, xrMain.propsWnd )
	_createAnchorBtn( gap*5 + btnSize*4, 25 + btnHeight*10 + gap*10, btnSize, btnSize, "SS", false, xrMain.propsWnd )

	--[[
		Canvas
	]]
	local width, height = 1024, 768
	local scrollSize = sh * 0.4

	xrMain.vertScroll = guiCreateScrollBar( sw / 2 - width / 2 - 50, sh / 2 - scrollSize / 2, 25, scrollSize, false, false )
	guiScrollBarSetScrollPosition( xrMain.vertScroll, 50 )
	addEventHandler( "onClientGUIScroll", xrMain.vertScroll, xrMain.onCanvasScroll, false )
	xrMain.horScroll = guiCreateScrollBar( sw / 2 - scrollSize / 2 - 50, sh / 2 - height / 2 - 50, scrollSize, 25, true, false )
	guiScrollBarSetScrollPosition( xrMain.horScroll, 50 )
	addEventHandler( "onClientGUIScroll", xrMain.horScroll, xrMain.onCanvasScroll, false )

	xrMain.resetCanvasBtn = guiCreateButton( sw / 2 - 100 / 2, 10, 100, 30, "Reset", false )
	addEventHandler( "onClientGUIClick", xrMain.resetCanvasBtn,
		function( btn, state )
			if state == "up" then
				xrMain.canvas:setSize( width, height )
				xrMain.canvas:setPosition( sw / 2 - width / 2, sh / 2 - height / 2 )
				xrMain.canvas:update()

				guiScrollBarSetScrollPosition( xrMain.vertScroll, 50 )
				guiScrollBarSetScrollPosition( xrMain.horScroll, 50 )
			end
		end
	, false )

	xrMain.canvas = xrCreateUICanvas( sw / 2 - width / 2, sh / 2 - height / 2, width, height )
	xrMain.canvas:update()

	xrMain:updateFramesList()

	addEventHandler( "onClientRender", root, xrMain.onRender, false )
	addEventHandler( "onClientCursorMove", root, xrMain.onCursorMove, false )
	addEventHandler( "onClientClick", root, xrMain.onCursorClick, false )
	addEventHandler( "onClientCharacter", root,
		function( char )
			xrMain.canvas:onCharacter( char )
		end
	, false )
	addEventHandler( "onClientKey", root,
		function( key, pressed )
			xrMain.canvas:onKey( key, pressed )
		end
	, false )
	
	showCursor( true )
	guiSetInputEnabled( true )

	xrMain.isEnabled = true
end

function xrMain.close()
	if xrMain.isEnabled then
		removeEventHandler( "onClientRender", root, xrMain.onRender )
		removeEventHandler( "onClientCursorMove", root, xrMain.onCursorMove )
		removeEventHandler( "onClientClick", root, xrMain.onCursorClick )

		xrMain:closeDescriptorEditor()

		destroyElement( xrMain.framesWnd )

		guiSetInputEnabled( false )

		xrMain.isEnabled = false
	end
end

function xrMain:updatePropertiesWnd( frame )
	guiSetText( xrMain.propsNameEdt, frame.name )

	guiSetText( xrMain.propsAnchorMinXEdt, tostring( frame.anchorLeftTopX ) )
	guiSetText( xrMain.propsAnchorMinYEdt, tostring( frame.anchorLeftTopY ) )
	guiSetText( xrMain.propsAnchorMaxXEdt, tostring( frame.anchorRightBottomX ) )
	guiSetText( xrMain.propsAnchorMaxYEdt, tostring( frame.anchorRightBottomY ) )

	guiSetText( xrMain.propsXEdt, tostring( frame.originX ) )
	guiSetText( xrMain.propsYEdt, tostring( frame.originY ) )
	guiSetText( xrMain.propsWidthEdt, tostring( frame.originWidth ) )
	guiSetText( xrMain.propsHeightEdt, tostring( frame.originHeight ) )
end

function xrMain:onFrameCreated( frame )
	local selectedFrame = xrMain.canvas:getFrame( xrMain.lastSelectedFrameName, true ) or xrMain.canvas.frame
	if selectedFrame then
		frame.canvas = selectedFrame.canvas
		frame.parent = selectedFrame      

		selectedFrame:insertChild( frame )

		xrMain.canvas:update()
		xrMain:updateFramesList()

		for i = 0, guiGridListGetRowCount( self.framesList ) - 1 do
			if guiGridListGetItemData( self.framesList, i, xrMain.framesColumnName ) == frame.name then
				guiGridListSetSelectedItem( self.framesList, i, xrMain.framesColumnName )

				xrMain.lastSelectedFrameName = frame.name

				break
			end
		end

		xrMain:updatePropertiesWnd( selectedFrame )
	end
end

local anchorBtnLookup = {
	[ "L" ] = { HOR_MODE_LEFT, false },
	[ "C" ] = { HOR_MODE_CENTER, false },
	[ "R" ] = { HOR_MODE_RIGHT, false },
	[ "S" ] = { HOR_MODE_STRETCH, false },

	[ "T" ] = { HOR_MODE_LEFT, VERT_MODE_TOP },
	[ "TL" ] = { HOR_MODE_LEFT, VERT_MODE_TOP },
	[ "TC" ] = { HOR_MODE_CENTER, VERT_MODE_TOP },
	[ "TR" ] = { HOR_MODE_RIGHT, VERT_MODE_TOP },
	[ "TS" ] = { HOR_MODE_STRETCH, VERT_MODE_TOP },

	[ "M" ] = { HOR_MODE_LEFT, VERT_MODE_CENTER },
	[ "ML" ] = { HOR_MODE_LEFT, VERT_MODE_CENTER },
	[ "MC" ] = { HOR_MODE_CENTER, VERT_MODE_CENTER },
	[ "MR" ] = { HOR_MODE_RIGHT, VERT_MODE_CENTER },
	[ "MS" ] = { HOR_MODE_STRETCH, VERT_MODE_CENTER },

	[ "B" ] = { HOR_MODE_LEFT, VERT_MODE_BOTTOM },
	[ "BL" ] = { HOR_MODE_LEFT, VERT_MODE_BOTTOM },
	[ "BC" ] = { HOR_MODE_CENTER, VERT_MODE_BOTTOM },
	[ "BR" ] = { HOR_MODE_RIGHT, VERT_MODE_BOTTOM },
	[ "BS" ] = { HOR_MODE_STRETCH, VERT_MODE_BOTTOM },

	[ "S" ] = { HOR_MODE_LEFT, VERT_MODE_STRETCH },
	[ "SL" ] = { HOR_MODE_LEFT, VERT_MODE_STRETCH },
	[ "SC" ] = { HOR_MODE_CENTER, VERT_MODE_STRETCH },
	[ "SR" ] = { HOR_MODE_RIGHT, VERT_MODE_STRETCH },
	[ "SS" ] = { HOR_MODE_STRETCH, VERT_MODE_STRETCH },
}

function xrMain.onAnchorBtnClick( btn, state )
	if state ~= "up" then
		return
	end

	local frame = xrMain.canvas:getFrame( xrMain.lastSelectedFrameName, true )
	if not frame then
		return
	end

	local name = guiGetText( source )
	if name == "[]" and frame.parent then
		local parent = frame.parent

		local rx = frame.originX / parent.originWidth
		local ry = frame.originY / parent.originHeight
		frame:setAnchorLeftTop( rx, ry )
		
		rx = ( frame.originX + frame.originWidth ) / parent.originWidth
		ry = ( frame.originY + frame.originHeight ) / parent.originHeight
		frame:setAnchorRightBottom( rx, ry )

		xrMain.canvas:update()
		xrMain:updatePropertiesWnd( frame )

		return
	end

	local alignData = anchorBtnLookup[ name ]
	if alignData then
		if alignData[ 1 ] then
			frame:setHorizontalAlign( alignData[ 1 ] )
		end
		if alignData[ 2 ] then
			frame:setVerticalAlign( alignData[ 2 ] )
		end

		xrMain.canvas:update()
		xrMain:updatePropertiesWnd( frame )
	end
end

function xrMain.onCanvasScroll()
	local width, height = 1024, 768

	local vertFactor = ( guiScrollBarGetScrollPosition( xrMain.vertScroll ) / 100 ) * 2
	local horFactor = ( guiScrollBarGetScrollPosition( xrMain.horScroll ) / 100 ) * 2

	local newWidth = horFactor * width
	local newHeight = vertFactor * height

	xrMain.canvas:setSize( newWidth, newHeight )
	xrMain.canvas:setPosition( sw / 2 - newWidth / 2, sh / 2 - newHeight / 2 )
	xrMain.canvas:update()
end

function xrMain.onCursorMove( _, _, ax, ay )
	xrMain.canvas:onCursorMove( ax, ay )

	if xrMain.currentDragDropResize then
		local frame = xrMain.canvas:getFrame( xrMain.lastSelectedFrameName, true )

		local nx = ax - 0
		local ny = ay - 0

		local nw = nx - frame.tx
		local nh = ny - frame.ty

		frame:setSize( nw, nh )
		xrMain.canvas:update()

		xrMain:updatePropertiesWnd( frame )

		return
	end

	if xrMain.currentDragDropAncher then
		local frame = xrMain.canvas:getFrame( xrMain.lastSelectedFrameName, true )
		if not frame.parent then
			return
		end

		local nx = ax - 0
		local ny = ay - 0

		if xrMain.currentDragDropAncher == 1 then
			local percentHor = ( nx - frame.parent.tx ) / frame.parent.tw
			local percentVert = ( ny - frame.parent.ty ) / frame.parent.th

			frame:setAnchorLeftTop( percentHor, percentVert )
		elseif xrMain.currentDragDropAncher == 2 then
			local percentHor = ( nx - frame.parent.tx ) / frame.parent.tw
			local percentVert = ( ny - frame.parent.ty ) / frame.parent.th

			frame:setAnchorRightBottom( percentHor, percentVert )
		end

		xrMain:updatePropertiesWnd( frame )

		return
	end

	if xrMain.currentDragDropFrameName then
		local frame = xrMain.canvas:getFrame( xrMain.currentDragDropFrameName, true )

		local nx = ax - xrMain.currentDragDropBiasX
		local ny = ay - xrMain.currentDragDropBiasY

		if frame.parent then
			frame:setPosition( nx - frame.parent.tx, ny - frame.parent.ty )	
		else
			frame:setPosition( nx, ny )
		end

		xrMain.canvas:update()

		xrMain:updatePropertiesWnd( frame )

		return
	end
end

function xrMain.onCursorClick( btn, state, ax, ay )	
	xrMain.canvas:onCursorClick( btn, state, ax, ay )

	if state == "down" then
		for _, wnd in ipairs( getElementsByType( "gui-window" ) ) do
			local wx, wy = guiGetPosition( wnd, false )
			local ww, wh = guiGetSize( wnd, false )
			if guiGetVisible( wnd ) and isPointInRect( ax, ay, wx, wy, ww, wh ) then
				return
			end
		end
		for _, wnd in ipairs( getElementsByType( "gui-scrollbar" ) ) do
			local wx, wy = guiGetPosition( wnd, false )
			local ww, wh = guiGetSize( wnd, false )
			if guiGetVisible( wnd ) and isPointInRect( ax, ay, wx, wy, ww, wh ) then
				return
			end
		end	

		local controlRectSize = 25

		if xrMain.lastSelectedFrameName --[[and xrMain.lastSelectedFrameName ~= "Canvas"]] then
			local selectedFrame = xrMain.canvas:getFrame( xrMain.lastSelectedFrameName, true )
			if not selectedFrame --[[or not isPointInRect( ax, ay, selectedFrame.tx, selectedFrame.ty, selectedFrame.tw, selectedFrame.th )]] then
				return
			end

			if isPointInRect( 
				ax, ay, 
				selectedFrame.tx + selectedFrame.tw,
				selectedFrame.ty + selectedFrame.th,
				controlRectSize - 2, controlRectSize - 2
			) then
				xrMain.currentDragDropResize = 1

				return
			end

			local frameParent = selectedFrame.parent
			if frameParent then
				if isPointInRect( 
					ax, ay, 
					frameParent.tx + frameParent.tw*selectedFrame.anchorLeftTopX - controlRectSize,
					frameParent.ty + frameParent.th*selectedFrame.anchorLeftTopY - controlRectSize,
					controlRectSize - 2, controlRectSize - 2
				 ) then
					xrMain.currentDragDropAncher = 1

					return
				 elseif isPointInRect( 
					ax, ay, 
					frameParent.tx + frameParent.tw*selectedFrame.anchorRightBottomX + 2,
					frameParent.ty + frameParent.th*selectedFrame.anchorRightBottomY + 2,
					controlRectSize - 2, controlRectSize - 2
				 ) then
					xrMain.currentDragDropAncher = 2

					return
				 end				
			end

			xrMain.currentDragDropBiasX = ax - selectedFrame.tx
			xrMain.currentDragDropBiasY = ay - selectedFrame.ty
			xrMain.currentDragDropFrameName = xrMain.lastSelectedFrameName
		end
	else
		if xrMain.currentDragDropResize then
			xrMain.currentDragDropResize = nil
		elseif xrMain.currentDragDropAncher then
			xrMain.currentDragDropAncher = nil
		elseif xrMain.currentDragDropFrameName then
			xrMain.currentDragDropFrameName = nil
		end
	end		
end

function xrMain.onAnchorEdtAccepted()
	local frameIndex = guiGridListGetSelectedItem( xrMain.framesList )
	if frameIndex and frameIndex > -1 then
		local frameName = guiGridListGetItemData( xrMain.framesList, frameIndex, xrMain.framesColumnName )
		local selectedFrame = xrMain.canvas:getFrame( frameName, true )
		if frameName == "Canvas" then
			--return
		end
		if selectedFrame then
			local value = guiGetText( xrMain.propsAnchorMinXEdt )
			if tonumber( value ) then
				selectedFrame.anchorLeftTopX = tonumber( value )
			end
			local value = guiGetText( xrMain.propsAnchorMinYEdt )
			if tonumber( value ) then
				selectedFrame.anchorLeftTopY = tonumber( value )
			end
			local value = guiGetText( xrMain.propsAnchorMaxXEdt )
			if tonumber( value ) then
				selectedFrame.anchorRightBottomX  = tonumber( value )
			end
			local value = guiGetText( xrMain.propsAnchorMaxYEdt )
			if tonumber( value ) then
				selectedFrame.anchorRightBottomY = tonumber( value )
			end

			xrMain.canvas:update()
			xrMain:updateFramesList()
		end
	end
end

function xrMain.onTransformEdtAccepted()
	local frameIndex = guiGridListGetSelectedItem( xrMain.framesList )
	if frameIndex and frameIndex > -1 then
		local frameName = guiGridListGetItemData( xrMain.framesList, frameIndex, xrMain.framesColumnName )
		local selectedFrame = xrMain.canvas:getFrame( frameName, true )
		if frameName == "Canvas" then
			--return
		end
		if selectedFrame then
			local xvalue = tonumber( guiGetText( xrMain.propsXEdt ) )
			local yvalue = tonumber( guiGetText( xrMain.propsYEdt ) )
			if xvalue and yvalue then
				selectedFrame:setPosition( xvalue, yvalue )
			end

			local wvalue = tonumber( guiGetText( xrMain.propsWidthEdt ) )
			local hvalue = tonumber( guiGetText( xrMain.propsHeightEdt ) )
			if wvalue and hvalue then
				selectedFrame:setSize( wvalue, hvalue )
			end

			xrMain.canvas:update()
			xrMain:updateFramesList()
		end
	end
end

function xrMain.onDescriptorEditorDraw()
	local x, y = guiGetPosition( xrMain.descWnd, false )
	local width, height = guiGetSize( xrMain.descWnd, false )
	height = height - 50
	
	if xrMain.descTex and not guiComboBoxIsOpen( xrMain.descTypesCombo ) then
		local matWidth, matHeight = dxGetMaterialSize( xrMain.descTex )
		local matAspect = matWidth / matHeight
		local matAspectInv = matHeight / matWidth

		local imgWidth = height * matAspect
		local imgHeight = height
		if imgWidth > width then
			imgWidth = width
			imgHeight = width * matAspectInv
		end

		local imgX = x + width / 2 - imgWidth / 2
		local imgY = ( y + 50 ) + height / 2 - imgHeight / 2
		dxDrawImage( imgX, imgY, imgWidth, imgHeight, xrMain.descShader, 0, 0, 0, tocolor( 255, 255, 255 ), true )

		if xrMain.descSelectedSection then
			local cx, cy = getCursorPosition()
	
			dxDrawText( 
				xrMain.descSelectedSection, 
				cx * sw + 50, cy * sh, 
				sw, sh, 
				tocolor( 255, 255, 255 ), 1, "default", "left", "top", false, false, true 
			)

			local section = xrTextureSections[ xrMain.descSelectedSection ]
			if section then
				local relX = section.x / matWidth
				local relY = section.y / matHeight
				local relWidth = section.width / matWidth
				local relHeight = section.height / matHeight

				dxDrawLineRect( imgX + imgWidth*relX, imgY + imgHeight*relY, imgWidth*relWidth, imgHeight*relHeight, tocolor( 255, 0, 0, 150 ), 2, true )
			end
		end
		
		if xrMain.descClickedSection then
			local cx, cy = getCursorPosition()
			cx = cx * sw
			cy = cy * sh
			local section = xrTextureSections[ xrMain.descClickedSection ]
	
			local relX = section.x / matWidth
			local relY = section.y / matHeight
			local relWidth = section.width / matWidth
			local relHeight = section.height / matHeight

			local biasX = xrMain.descClickX - ( imgX + imgWidth*relX )
			local biasY = xrMain.descClickY - ( imgY + imgHeight*relY )
	
			dxDrawImageSection( 
				cx - biasX, cy - biasY, 
				imgWidth*relWidth, imgHeight*relHeight, 
				section.x, section.y, section.width, section.height,
				xrMain.descShader, 0, 0, 0, tocolor( 255, 255, 255 ), true )
		end
	end	
end

function xrMain.onDescriptorEditorClick( btn, state, ax, ay )
	if state ~= "down" or not xrMain.descSelectedSection then		
		return
	end

	if type( xrMain.descFn ) == "function" then
		xrMain.descFn( xrMain.descName, xrMain.descSelectedSection, unpack( xrMain.descFnArgs ) )
	end
end

function xrMain.onDescriptorEditorCursorMove( _, _, ax, ay )
	if not xrMain.descTex then
		return
	end

	local x, y = guiGetPosition( xrMain.descWnd, false )
	local width, height = guiGetSize( xrMain.descWnd, false )
	height = height - 50

	local matWidth, matHeight = dxGetMaterialSize( xrMain.descTex )
	local matAspect = matWidth / matHeight
	local matAspectInv = matHeight / matWidth

	local imgWidth = height * matAspect
	local imgHeight = height
	if imgWidth > width then
		imgWidth = width
		imgHeight = width * matAspectInv
	end

	local imgX = x + width / 2 - imgWidth / 2
	local imgY = ( y + 50 ) + height / 2 - imgHeight / 2

	local relX = ( ax - imgX ) / imgWidth
	local relY = ( ay - imgY ) / imgHeight
	local texX = matWidth * relX
	local texY = matHeight * relY

	xrMain.descSelectedSection = nil		

	local sections = xrTextureDescriptors[ xrMain.descName ].sections
	for _, section in ipairs( sections ) do

		if texX >= section.x and texX <= section.x + section.width and texY >= section.y and texY <= section.y + section.height then
			xrMain.descSelectedSection = section.id
			break
		end
	end
end

function xrMain:onDescriptorEditorChange( name )
	self.descTex = nil

	local sections = xrTextureDescriptors[ name ]
	if sections then
		local texture = exports.sp_assets:xrLoadAsset( sections.texName )
		if texture then
			self.descTex = texture
			self.descName = name

			--self.canvas:addTexture( texture, sections.texName )

			dxSetShaderValue( xrMain.descShader, "Tex0", texture )
		end	
	end
end

function xrMain:openDescriptorEditor( fn, ... )
	if self.descOpened then
		return
	end

	local gap = 5
	local width, height = sh * 0.9, sh * 0.9

	--[[
		Frames
	]]
	xrMain.descWnd = guiCreateWindow( sw / 2 - width / 2, sh / 2 - height / 2, width, height, "Descriptor editor", false )
	guiBringToFront( xrMain.descWnd )

	local comboWidth = width * 0.4
	xrMain.descTypesCombo = guiCreateComboBox( gap, 25, comboWidth, 50, "Textures", false, xrMain.descWnd )
	guiComboBoxAdjustHeight( xrMain.descTypesCombo, #xrTextureSectionNames )

	for _, name in ipairs( xrTextureSectionNames ) do
		guiComboBoxAddItem( xrMain.descTypesCombo, name )
	end

	addEventHandler( "onClientGUIComboBoxAccepted", xrMain.descTypesCombo,
		function( element )
			local item = guiComboBoxGetSelected( element )
			xrMain:onDescriptorEditorChange( guiComboBoxGetItemText( element, item ) )
		end
	, false )

	xrMain.descBtn = guiCreateButton( gap + comboWidth + gap, 25, comboWidth, 25, "Exit", false, xrMain.descWnd )
	addEventHandler( "onClientGUIClick", xrMain.descBtn,
		function( btn, state )
			if state == "up" then
				xrMain:closeDescriptorEditor()
			end
		end
	, false )

	xrMain.descShader = dxCreateShader( "shader.fx" )
	if isElement( self.descTex ) then
		dxSetShaderValue( xrMain.descShader, "Tex0", self.descTex )
	end

	addEventHandler( "onClientRender", root, xrMain.onDescriptorEditorDraw, false )
	addEventHandler( "onClientCursorMove", root, xrMain.onDescriptorEditorCursorMove, false )
	addEventHandler( "onClientClick", root, xrMain.onDescriptorEditorClick, false )
	
	self.descFn = fn
	self.descFnArgs = { ... }
	self.descOpened = true
end

function xrMain:closeDescriptorEditor()
	if self.descOpened then
		destroyElement( xrMain.descWnd )

		destroyElement( xrMain.descShader )

		removeEventHandler( "onClientRender", root, xrMain.onDescriptorEditorDraw )
		removeEventHandler( "onClientCursorMove", root, xrMain.onDescriptorEditorCursorMove )
		removeEventHandler( "onClientClick", root, xrMain.onDescriptorEditorClick )
		
		self.descFn = nil
		self.descFnArgs = nil
		self.descOpened = false
	end
end

function xrMain.onRender()
	local canvas = xrMain.canvas
	canvas:draw()

	local controlRectSize = 25

	local frameIndex = guiGridListGetSelectedItem( xrMain.framesList )
	if frameIndex and frameIndex > -1 then
		local frameName = guiGridListGetItemData( xrMain.framesList, frameIndex, xrMain.framesColumnName )
		local selectedFrame = canvas:getFrame( frameName, true )
		if selectedFrame then
			dxDrawLineRect( selectedFrame.tx, selectedFrame.ty, selectedFrame.tw, selectedFrame.th, tocolor( 255, 255, 0 ) )

			dxDrawRectangle( 
				selectedFrame.tx + selectedFrame.tw,
				selectedFrame.ty + selectedFrame.th,
				controlRectSize - 2, controlRectSize - 2,
				tocolor( 100, 100, 255 )				
			)

			local frameParent = selectedFrame.parent
			if frameParent then
				dxDrawRectangle( 
					frameParent.tx + frameParent.tw*selectedFrame.anchorLeftTopX - controlRectSize,
					frameParent.ty + frameParent.th*selectedFrame.anchorLeftTopY - controlRectSize,
					controlRectSize - 2, controlRectSize - 2,
					tocolor( 170, 0, 255 )				
				)

				dxDrawRectangle( 
					frameParent.tx + frameParent.tw*selectedFrame.anchorRightBottomX + 2,
					frameParent.ty + frameParent.th*selectedFrame.anchorRightBottomY + 2,
					controlRectSize - 2, controlRectSize - 2,
					tocolor( 170, 0, 255 )				
				)
			end
		end		
	end

    dxDrawLine( canvas.screenX, 0, canvas.screenX, sh, tocolor( 255, 0, 0 ) )
    dxDrawLine( canvas.screenX + canvas.screenWidth, 0, canvas.screenX + canvas.screenWidth, sh, tocolor( 255, 0, 0 ) )
    dxDrawLine( 0, canvas.screenY, sw, canvas.screenY, tocolor( 255, 0, 0 ) )
    dxDrawLine( 0, canvas.screenY + canvas.screenHeight, sw, canvas.screenY + canvas.screenHeight, tocolor( 255, 0, 0 ) )
end

function xrMain:updateFramesList()
	guiGridListClear( self.framesList )

	if self.canvas.frame then
		xrMain:addFrameToListRecursive( self.canvas.frame, 0 )		

		if xrMain.lastSelectedFrameName then
			for i = 0, guiGridListGetRowCount( self.framesList ) - 1 do
				if guiGridListGetItemData( self.framesList, i, xrMain.framesColumnName ) == xrMain.lastSelectedFrameName then
					guiGridListSetSelectedItem( self.framesList, i, xrMain.framesColumnName )
					break
				end
			end
		end
	end
end

function xrMain:addFrameToListRecursive( item, level )
	local text = item.name
	for i = 1, level do
		text = "+ " .. text
	end

	local row = guiGridListAddRow( self.framesList, text .. "(" .. tostring( item.id ) .. ")" )
	guiGridListSetItemData( self.framesList, row, xrMain.framesColumnName, item.name )

	for _, child in ipairs( item.items ) do
		xrMain:addFrameToListRecursive( child, level + 1 )
	end
end

--[[
	Init
]]
addEventHandler( "onClientResourceStart", resourceRoot,
	function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
		--xrIncludeModule( "uiconfig.lua" )
		xrIncludeModule( "global.lua" )

		xrLoadUIColorDict( "color_defs" )
		xrLoadAllUIFileDescriptors()

		xrMain.init()
		xrMain.open()
    end
)
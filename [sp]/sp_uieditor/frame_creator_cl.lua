local sw, sh = guiGetScreenSize ( )

local gap = 5
local sideNames = {
    "_lt", "_l", "_lb", "_t", "_back", "_b", "_rt", "_r", "_rb"
}
local sideLineNames = {
    "_b", "_back", "_e"
}
local defaultFontsLookup = {
    [ "default" ] = true,
    [ "default-bold" ] = true,
    [ "clear" ] = true,
    [ "arial" ] = true,
    [ "sans" ] = true,
    [ "pricedown" ] = true,
    [ "bankgothic" ] = true,
    [ "diploma" ] = true,
    [ "beckett" ] = true
}

xrFrameCreator = {

}

xrFrameTraits = {
    [ "Image" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            meta.nameEdt = guiCreateEdit( x, y, width, 50, "Name", false, wnd )
            meta.texName = guiCreateEdit( x, y + 50 + gap, width, 50, "Texture name", false, wnd )
            meta.left = guiCreateEdit( x, y + 50*2 + gap*2, width, 50, "Section name", false, wnd )
            meta.pickBtn = guiCreateButton( x, y + 50*3 + gap*3, width, 50, "Pick section", false, wnd )
            addEventHandler( "onClientGUIClick", meta.pickBtn,
                function( btn, state )
                    xrMain:openDescriptorEditor( xrFrameTraits[ "Image" ].onSectionPicked, meta )
                end
            , false )

            return meta                
        end,
        onSectionPicked = function( filename, name, meta )
            guiSetText( meta.texName, filename )
            guiSetText( meta.left, name )
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
            destroyElement( meta.texName )
            destroyElement( meta.left )
            destroyElement( meta.pickBtn )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            local textureName = guiGetText( meta.texName )
            local sectionName = guiGetText( meta.left )

            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            if string.len( textureName ) < 3 then
                outputChatBox( "Инвалидное имя текстуры" )
                return
            end

            local texture = exports.sp_assets:xrLoadAsset( textureName )
            if not texture then
                outputChatBox( "Текстуры с таким именем не существует" )
                return
            end

            local width, height = dxGetMaterialSize( texture )

            local section = xrTextureSections[ sectionName ]
            if section then
                width, height = section.width, section.height
            end     

            local frame = UIImage:create( frameName, 0, 0, width, height )
            if frame then
                if texture then
                    frame:setTexture( textureName )
                end

                if section then
                    frame:setTextureSection( sectionName )
                end

                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    },
    [ "Progress" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            meta.nameEdt = guiCreateEdit( x, y, width, 50, "Name", false, wnd )
            meta.texName = guiCreateEdit( x, y + 50 + gap, width, 50, "Texture name", false, wnd )
            meta.left = guiCreateEdit( x, y + 50*2 + gap*2, width, 50, "Section name", false, wnd )
            meta.pickBtn = guiCreateButton( x, y + 50*3 + gap*3, width, 50, "Pick section", false, wnd )
            addEventHandler( "onClientGUIClick", meta.pickBtn,
                function( btn, state )
                    xrMain:openDescriptorEditor( xrFrameTraits[ "Image" ].onSectionPicked, meta )
                end
            , false )

            return meta                
        end,
        onSectionPicked = function( filename, name, meta )
            guiSetText( meta.texName, filename )
            guiSetText( meta.left, name )
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
            destroyElement( meta.texName )
            destroyElement( meta.left )
            destroyElement( meta.pickBtn )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            local textureName = guiGetText( meta.texName )
            local sectionName = guiGetText( meta.left )

            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            if string.len( textureName ) < 3 then
                outputChatBox( "Инвалидное имя текстуры" )
                return
            end

            local texture = exports.sp_assets:xrLoadAsset( textureName )
            if not texture then
                outputChatBox( "Текстуры с таким именем не существует" )
                return
            end

            local width, height = dxGetMaterialSize( texture )

            local section = xrTextureSections[ sectionName ]
            if section then
                width, height = section.width, section.height
            end     

            local frame = UIProgressBar:create( frameName, 0, 0, width, height )
            if frame then
                if texture then
                    frame:setTexture( textureName )
                end

                if section then
                    frame:setTextureSection( sectionName )
                end

                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    },
    [ "Form" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            meta.nameEdt = guiCreateEdit( x, y, width, 50, "Name", false, wnd )            

            return meta                
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            local frame = UIForm:create( frameName, 0, 0, 200, 200 )
            if frame then
                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    },
    [ "List" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            meta.nameEdt = guiCreateEdit( x, y, width, 50, "Name", false, wnd )            

            return meta                
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            local frame = UIList:create( frameName, 0, 0, 200, 200 )
            if frame then
                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    },
    [ "Empty" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            meta.nameEdt = guiCreateEdit( x, y, width, 50, "Name", false, wnd )            

            return meta                
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            local frame = UIDescriptor:create( frameName, 0, 0, 200, 200 )
            if frame then
                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    },
    [ "RenderTarget" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            meta.nameEdt = guiCreateEdit( x, y, width, 50, "Name", false, wnd )            

            return meta                
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            local frame = UIRenderTarget:create( frameName, 0, 0, 200, 200 )
            if frame then
                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    },   
    [ "ScrollPane" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            meta.nameEdt = guiCreateEdit( x, y, width, 50, "Name", false, wnd )            

            return meta                
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            local frame = UIScrollPane:create( frameName, 0, 0, 200, 200 )
            if frame then
                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    }, 
    --[[ "ScrollBar" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            meta.nameEdt = guiCreateEdit( x, y, width, 50, "Name", false, wnd )            

            return meta                
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            local frame = UIScrollBar:create( frameName, 0, 0, 200, 200 )
            if frame then
                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    }, ]]
    [ "ScrollBar" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            local lineHeight = 25
            local buttonWidth = 50

            meta.nameEdt = guiCreateEdit( x, y, width, lineHeight, "Name", false, wnd )
            meta.texEdt = guiCreateEdit( x, y + lineHeight + gap, width, lineHeight, "Texture name", false, wnd )
            meta.defaultName = guiCreateEdit( x, y + lineHeight*2 + gap*2, width - buttonWidth - gap, lineHeight, "Default section name", false, wnd )
            meta.defaultPick = guiCreateButton( x + width - buttonWidth, y + lineHeight*2 + gap*2, buttonWidth, lineHeight, "Pick", false, wnd )
            addEventHandler( "onClientGUIClick", meta.defaultPick,
                function( btn, state )
                    xrMain:openDescriptorEditor( xrFrameTraits[ "Button" ].onSectionPicked, meta.texEdt, meta.defaultName )
                end
            , false )
            meta.selectedName = guiCreateEdit( x, y + lineHeight*3 + gap*3, width - buttonWidth - gap, lineHeight, "Selected section name", false, wnd )
            meta.selectedPick = guiCreateButton( x + width - buttonWidth, y + lineHeight*3 + gap*3, buttonWidth, lineHeight, "Pick", false, wnd )
            addEventHandler( "onClientGUIClick", meta.selectedPick,
                function( btn, state )
                    xrMain:openDescriptorEditor( xrFrameTraits[ "Button" ].onSectionPicked, meta.texEdt, meta.selectedName )
                end
            , false )
            meta.clickedName = guiCreateEdit( x, y + lineHeight*4 + gap*4, width - buttonWidth - gap, lineHeight, "Clicked section name", false, wnd )
            meta.clickedPick = guiCreateButton( x + width - buttonWidth, y + lineHeight*4 + gap*4, buttonWidth, lineHeight, "Pick", false, wnd )
            addEventHandler( "onClientGUIClick", meta.clickedPick,
                function( btn, state )
                    xrMain:openDescriptorEditor( xrFrameTraits[ "Button" ].onSectionPicked, meta.texEdt, meta.clickedName )
                end
            , false )

            return meta                
        end,
        onSectionPicked = function( filename, name, nameField, textField )
            guiSetText( nameField, filename )
            guiSetText( textField, name )
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
            destroyElement( meta.texEdt )
            destroyElement( meta.defaultName )
            destroyElement( meta.defaultPick )
            destroyElement( meta.selectedName )
            destroyElement( meta.selectedPick )
            destroyElement( meta.clickedName )
            destroyElement( meta.clickedPick )
        end,
        onCreate = function( meta )
            local textureName = guiGetText( meta.texEdt )
            local defaultSectionName = guiGetText( meta.defaultName )
            local selectedSectionName = guiGetText( meta.selectedName )
            local clickedSectionName = guiGetText( meta.clickedName )

            local frameName = guiGetText( meta.nameEdt )
            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            if string.len( textureName ) < 3 then
                outputChatBox( "Инвалидное имя текстуры" )
                return
            end

            local texture = exports.sp_assets:xrLoadAsset( textureName )
            if not texture then
                outputChatBox( "Текстуры с таким именем не существует" )
                return
            end

            local defaultSection = xrTextureSections[ defaultSectionName ]
            if not defaultSection then
                outputChatBox( "Секции по-умолчанию с таким именем не существует!" )
                return false
            end            

            local frame = UIScrollBar:create( frameName, 0, 0, defaultSection.width, defaultSection.height )
            if frame then
                frame:setTexture( textureName )

                frame:setTextureSection( UIBTN_DEFAULT, defaultSectionName )
                if xrTextureSections[ selectedSectionName ] then
                    frame:setTextureSection( UIBTN_SELECTED, selectedSectionName )
                end
                if xrTextureSections[ clickedSectionName ] then
                    frame:setTextureSection( UIBTN_CLICKED, clickedSectionName )
                end

                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    },
    [ "Browser" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            meta.nameEdt = guiCreateEdit( x, y, width, 50, "Name", false, wnd )            

            return meta                
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            local frame = UIBrowser:create( frameName, 0, 0, 200, 200 )
            if frame then
                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    }, 
    [ "Button" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            local lineHeight = 25
            local buttonWidth = 50

            meta.nameEdt = guiCreateEdit( x, y, width, lineHeight, "Name", false, wnd )
            meta.texEdt = guiCreateEdit( x, y + lineHeight + gap, width, lineHeight, "Texture name", false, wnd )
            meta.defaultName = guiCreateEdit( x, y + lineHeight*2 + gap*2, width - buttonWidth - gap, lineHeight, "Default section name", false, wnd )
            meta.defaultPick = guiCreateButton( x + width - buttonWidth, y + lineHeight*2 + gap*2, buttonWidth, lineHeight, "Pick", false, wnd )
            addEventHandler( "onClientGUIClick", meta.defaultPick,
                function( btn, state )
                    xrMain:openDescriptorEditor( xrFrameTraits[ "Button" ].onSectionPicked, meta.texEdt, meta.defaultName )
                end
            , false )
            meta.selectedName = guiCreateEdit( x, y + lineHeight*3 + gap*3, width - buttonWidth - gap, lineHeight, "Selected section name", false, wnd )
            meta.selectedPick = guiCreateButton( x + width - buttonWidth, y + lineHeight*3 + gap*3, buttonWidth, lineHeight, "Pick", false, wnd )
            addEventHandler( "onClientGUIClick", meta.selectedPick,
                function( btn, state )
                    xrMain:openDescriptorEditor( xrFrameTraits[ "Button" ].onSectionPicked, meta.texEdt, meta.selectedName )
                end
            , false )
            meta.clickedName = guiCreateEdit( x, y + lineHeight*4 + gap*4, width - buttonWidth - gap, lineHeight, "Clicked section name", false, wnd )
            meta.clickedPick = guiCreateButton( x + width - buttonWidth, y + lineHeight*4 + gap*4, buttonWidth, lineHeight, "Pick", false, wnd )
            addEventHandler( "onClientGUIClick", meta.clickedPick,
                function( btn, state )
                    xrMain:openDescriptorEditor( xrFrameTraits[ "Button" ].onSectionPicked, meta.texEdt, meta.clickedName )
                end
            , false )
            meta.toggledCbx = guiCreateCheckBox( x, y + lineHeight*5 + gap*5, width, lineHeight, "Toggled", false, false, wnd )

            return meta                
        end,
        onSectionPicked = function( filename, name, nameField, textField )
            guiSetText( nameField, filename )
            guiSetText( textField, name )
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
            destroyElement( meta.texEdt )
            destroyElement( meta.defaultName )
            destroyElement( meta.defaultPick )
            destroyElement( meta.selectedName )
            destroyElement( meta.selectedPick )
            destroyElement( meta.clickedName )
            destroyElement( meta.clickedPick )
            destroyElement( meta.toggledCbx )
        end,
        onCreate = function( meta )
            local textureName = guiGetText( meta.texEdt )
            local defaultSectionName = guiGetText( meta.defaultName )
            local selectedSectionName = guiGetText( meta.selectedName )
            local clickedSectionName = guiGetText( meta.clickedName )

            local frameName = guiGetText( meta.nameEdt )
            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            if string.len( textureName ) < 3 then
                outputChatBox( "Инвалидное имя текстуры" )
                return
            end

            local texture = exports.sp_assets:xrLoadAsset( textureName )
            if not texture then
                outputChatBox( "Текстуры с таким именем не существует" )
                return
            end

            local defaultSection = xrTextureSections[ defaultSectionName ]
            if not defaultSection then
                outputChatBox( "Секции по-умолчанию с таким именем не существует!" )
                return false
            end            

            local frame = UIButton:create( frameName, 0, 0, defaultSection.width, defaultSection.height )
            if frame then
                frame:setTexture( textureName )
                frame:setToggled( guiCheckBoxGetSelected( meta.toggledCbx ) )

                frame:setTextureSection( UIBTN_DEFAULT, defaultSectionName )
                if xrTextureSections[ selectedSectionName ] then
                    frame:setTextureSection( UIBTN_SELECTED, selectedSectionName )
                end
                if xrTextureSections[ clickedSectionName ] then
                    frame:setTextureSection( UIBTN_CLICKED, clickedSectionName )
                end

                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    },
    [ "Text" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            local lineHeight = 25
            local buttonWidth = 50

            meta.nameEdt = guiCreateEdit( x, y, width, lineHeight, "Name", false, wnd )
            meta.textEdt = guiCreateEdit( x, y + lineHeight + gap, width, lineHeight, "Text", false, wnd )
            meta.fontEdt = guiCreateEdit( x, y + lineHeight*2 + gap*2, width, lineHeight, "default", false, wnd )
            meta.alignXCmb = guiCreateComboBox( x, y + lineHeight*3 + gap*3, width, 100, "left", false, wnd )
            guiComboBoxAddItem( meta.alignXCmb, "left" )
            guiComboBoxAddItem( meta.alignXCmb, "center" )
            guiComboBoxAddItem( meta.alignXCmb, "right" )
            guiComboBoxSetSelected( meta.alignXCmb, 0 )
            meta.alignYCmb = guiCreateComboBox( x, y + lineHeight*4 + gap*4, width, 100, "top", false, wnd )
            guiComboBoxAddItem( meta.alignYCmb, "top" )
            guiComboBoxAddItem( meta.alignYCmb, "center" )
            guiComboBoxAddItem( meta.alignYCmb, "bottom" )
            guiComboBoxSetSelected( meta.alignYCmb, 0 )
            meta.scaleEdt = guiCreateEdit( x, y + lineHeight*5 + gap*5, width, lineHeight, "1", false, wnd )          
            meta.clipCbx = guiCreateCheckBox( x, y + lineHeight*6 + gap*6, width, lineHeight, "Clip", false, false, wnd )
            meta.breakCbx = guiCreateCheckBox( x, y + lineHeight*7 + gap*7, width, lineHeight, "Word break", false, false, wnd )

            return meta                
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
            destroyElement( meta.textEdt )
            destroyElement( meta.fontEdt )
            destroyElement( meta.alignXCmb )
            destroyElement( meta.alignYCmb )
            destroyElement( meta.scaleEdt )
            destroyElement( meta.clipCbx )
            destroyElement( meta.breakCbx )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            local text = guiGetText( meta.textEdt )
            local fontName = guiGetText( meta.fontEdt )
            local scale = tonumber( guiGetText( meta.scaleEdt ) ) or 1

            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            local font = fontName
            if not defaultFontsLookup[ font ] then
                font = exports.sp_assets:xrLoadAsset( fontName )
                if not font then
                    outputChatBox( "Шрифт с именем " .. tostring( fontName ) .. " не существует!" )
                    return
                end
            end        
    
            local alignX = "left"
            local alignY = "top"
            
            local selectedIdx = guiComboBoxGetSelected( meta.alignXCmb )
            if selectedIdx and selectedIdx > -1 then
                alignX = guiComboBoxGetItemText( meta.alignXCmb, selectedIdx )
            end
            selectedIdx = guiComboBoxGetSelected( meta.alignYCmb )
            if selectedIdx and selectedIdx > -1 then
                alignY = guiComboBoxGetItemText( meta.alignYCmb, selectedIdx )
            end            

            local textWidth = dxGetTextWidth( tostring( text ), scale, font )
            local textHeight = dxGetFontHeight( scale, font )

            local frame = UIText:create( frameName, 0, 0, textWidth, textHeight )
            if frame then
                frame:setText( tostring( text ) )
                frame:setAlign( alignX, alignY )
                frame:setScale( scale )
                frame:setFont( fontName )
                frame:setWordClip( guiCheckBoxGetSelected( meta.clipCbx ) )
                frame:setWordBreak( guiCheckBoxGetSelected( meta.breakCbx ) )

                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    },
    [ "EditField" ] = {
        onShow = function( wnd, x, y, width, height )
            local meta = {}

            local lineHeight = 25
            local buttonWidth = 50

            meta.nameEdt = guiCreateEdit( x, y, width, lineHeight, "Name", false, wnd )
            meta.textEdt = guiCreateEdit( x, y + lineHeight + gap, width, lineHeight, "Text", false, wnd )
            meta.fontEdt = guiCreateEdit( x, y + lineHeight*2 + gap*2, width, lineHeight, "default", false, wnd )
            meta.scaleEdt = guiCreateEdit( x, y + lineHeight*3 + gap*3, width, lineHeight, "1", false, wnd )          
            meta.lengthEdt = guiCreateEdit( x, y + lineHeight*4 + gap*4, width, lineHeight, "10", false, wnd )          
            meta.maskedCbx = guiCreateCheckBox( x, y + lineHeight*5 + gap*5, width, lineHeight, "Masked", false, false, wnd )
            meta.memoCbx = guiCreateCheckBox( x, y + lineHeight*6 + gap*6, width, lineHeight, "Mask", false, false, wnd )

            return meta                
        end,
        onHide = function( meta )
            destroyElement( meta.nameEdt )
            destroyElement( meta.textEdt )
            destroyElement( meta.fontEdt )
            destroyElement( meta.scaleEdt )
            destroyElement( meta.lengthEdt )
            destroyElement( meta.maskedCbx )
            destroyElement( meta.memoCbx )
        end,
        onCreate = function( meta )
            local frameName = guiGetText( meta.nameEdt )
            local text = guiGetText( meta.textEdt )
            local fontName = guiGetText( meta.fontEdt )
            local scale = tonumber( guiGetText( meta.scaleEdt ) ) or 1
            local length = tonumber( guiGetText( meta.lengthEdt ) ) or 10
            local masked = guiCheckBoxGetSelected( meta.maskedCbx )
            local memo = guiCheckBoxGetSelected( meta.memoCbx )

            if xrMain.canvas:getFrame( frameName ) then
                outputChatBox( "Фрейм с таким именем уже существует!" )
                return false
            end

            local font = fontName
            if not defaultFontsLookup[ font ] then
                font = exports.sp_assets:xrLoadAsset( fontName )
                if not font then
                    outputChatBox( "Шрифт с именем " .. tostring( fontName ) .. " не существует!" )
                    return
                end
            end    
   
            local frame = UIEditField:create( frameName, 0, 0, 100, 30 )
            if frame then
                frame:setText( text )
                frame:setScale( scale )
                frame:setFont( fontName )
                frame:setMaxLength( length )
                frame:setMasked( masked )
                frame:setMemo( memo )

                xrMain:onFrameCreated( frame )               

                return true
            end

            return false
        end
    }
}

function xrFrameCreator:open()
    if self.opened then
        return
    end

	local width, height = 500, 800
	local btnWidth = ( width - gap*3 ) / 2
	local btnHeight = 30

    --[[
		Frames
	]]
    self.wnd = guiCreateWindow( sw / 2 - width / 2, sh / 2 - height / 2, width, height, "Frames", false )
    guiBringToFront( self.wnd )

    self.radioImg = guiCreateRadioButton( gap, 25, width - gap*2, 25, "Image", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.radioImg, xrFrameCreator.onRadioClick, false )
    self.formImg = guiCreateRadioButton( gap, 25*2 + gap, width - gap*2, 25, "Form", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.formImg, xrFrameCreator.onRadioClick, false )
    self.buttonImg = guiCreateRadioButton( gap, 25*3 + gap*2, width - gap*2, 25, "Button", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.buttonImg, xrFrameCreator.onRadioClick, false )
    self.textImg = guiCreateRadioButton( gap, 25*4 + gap*3, width - gap*2, 25, "Text", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.textImg, xrFrameCreator.onRadioClick, false )
    self.emptyImg = guiCreateRadioButton( gap, 25*5 + gap*4, width - gap*2, 25, "Empty", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.emptyImg, xrFrameCreator.onRadioClick, false )
    self.rtImg = guiCreateRadioButton( gap, 25*6 + gap*5, width - gap*2, 25, "RenderTarget", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.rtImg, xrFrameCreator.onRadioClick, false )
    self.listImg = guiCreateRadioButton( gap, 25*7 + gap*6, width - gap*2, 25, "List", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.listImg, xrFrameCreator.onRadioClick, false )
    self.paneImg = guiCreateRadioButton( gap, 25*8 + gap*7, width - gap*2, 25, "ScrollPane", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.paneImg, xrFrameCreator.onRadioClick, false )
    self.barImg = guiCreateRadioButton( gap, 25*9 + gap*8, width - gap*2, 25, "ScrollBar", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.barImg, xrFrameCreator.onRadioClick, false )
    self.editImg = guiCreateRadioButton( gap, 25*10 + gap*9, width - gap*2, 25, "EditField", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.editImg, xrFrameCreator.onRadioClick, false )
    self.progressImg = guiCreateRadioButton( gap, 25*11 + gap*10, width - gap*2, 25, "Progress", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.progressImg, xrFrameCreator.onRadioClick, false )
    self.browserImg = guiCreateRadioButton( gap, 25*12 + gap*11, width - gap*2, 25, "Browser", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.browserImg, xrFrameCreator.onRadioClick, false )

    self.btnCreate = guiCreateButton( gap, height - btnHeight - gap, btnWidth, btnHeight, "Create", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.btnCreate, xrFrameCreator.onBtnClick, false )
    self.btnCancel = guiCreateButton( gap*2 + btnWidth, height - btnHeight - gap, btnWidth, btnHeight, "Cancel", false, self.wnd )
    addEventHandler( "onClientGUIClick", self.btnCancel, xrFrameCreator.onBtnClick, false )

    guiRadioButtonSetSelected( self.radioImg, true )
    self.selectedMeta = xrFrameTraits[ "Image" ].onShow( self.wnd, gap, 25*13 + gap*12, width - gap*2, height - 25*5 + gap*4 )
    self.selectedName = "Image"

    self.opened = true
end

function xrFrameCreator:close()
    if not self.opened then
        return
    end

    destroyElement( self.wnd )

    self.opened = false    
end

function xrFrameCreator.onBtnClick( btn, state )
    if source == xrFrameCreator.btnCreate then
        local result = xrFrameTraits[ xrFrameCreator.selectedName ].onCreate( xrFrameCreator.selectedMeta )
        if result then
            xrFrameCreator:close()
        end
    else
        xrFrameCreator:close()
    end
end

function xrFrameCreator.onRadioClick( btn, state )
    local prevName = xrFrameCreator.selectedName
    local name = guiGetText( source )

    if prevName == name then
        return
    end

    if prevName then
        xrFrameTraits[ prevName ].onHide( xrFrameCreator.selectedMeta )
        xrFrameCreator.selectedMeta = nil
        xrFrameCreator.selectedName = nil
    end

    if guiRadioButtonGetSelected( source ) then
        local width, height = 500, 500
        local btnWidth = ( width - gap*3 ) / 2
        local btnHeight = 30

        xrFrameCreator.selectedMeta = xrFrameTraits[ name ].onShow( xrFrameCreator.wnd, gap, 25*13 + gap*12, width - gap*2, height - 25*5 + gap*4 )
        xrFrameCreator.selectedName = name
    end
end
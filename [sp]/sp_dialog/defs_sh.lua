WHITE_COLOR = tocolor( 255, 255, 255, 255 )
INFO_HEADER_COLOR = tocolor( 240, 200, 200 )
INFO_VALUE_COLOR = tocolor( 200, 200, 200 )
INFO_GAP = 5

g_InfoTypes = {

}

g_InfoTexDict = {

}

MessageText = {
    onCreate = function( self, ypos, text, name )
        local control = xrTalk.logList
        local fontHeight = dxGetFontHeight( FONT_SCALE, xrTalk.font )
        local textHeight = getRealTextHeight( text, FONT_SCALE, xrTalk.font, control.width - fontHeight*2 )	
        local height = fontHeight + textHeight

        local msg = {
            name = name,
            text = text,
            ypos = ypos,
            height = height
        }        

        return setmetatable( msg, MessageTextMT ), height
    end,
    onDraw = function( self, scroll )
        local control = xrTalk.logList
        local fontHeight = dxGetFontHeight( FONT_SCALE, xrTalk.font )
        local ypos = self.ypos + scroll

        --local author = textData.side ~= true and getElementData( localPlayer, "name", false ) or xrTalk.pedDesc.name
		dxDrawText( self.name, 0, ypos, control.width, 0, tocolor( 250, 151, 22 ), FONT_SCALE, xrTalk.font )
		dxDrawText( self.text, fontHeight, ypos + fontHeight, control.width - fontHeight, 0, tocolor ( 216, 186, 140 ), FONT_SCALE, xrTalk.font, "left", "top", false, true )
     end
}
MessageTextMT = {
    __index = MessageText
}

MessageFoundMoney = {
    icon = "ui_iconsTotal_found_money",
    label = "Деньги получены",
    onCreate = function( self, ypos, value )
        local height = INFO_HEIGHT + INFO_GAP

        local msg = {
            value = tonumber( value ) or 0,
            ypos = ypos,
            height = height
        }
        return setmetatable( msg, MessageFoundMoneyMT ), height
    end,
    onDraw = function( self, scroll )
        local control = xrTalk.logList
        local fontHeight = dxGetFontHeight( FONT_SCALE, xrTalk.font )    
        local ypos = self.ypos + scroll   

        local xpos = fontHeight
        xrTextureSections[ self.icon ]:draw( g_InfoTexDict, xpos, ypos, INFO_WIDTH, INFO_HEIGHT, WHITE_COLOR )
        xpos = xpos + INFO_WIDTH + 5
        dxDrawText( self.label, xpos, ypos, control.width, ypos + fontHeight, INFO_HEADER_COLOR, FONT_SCALE * 0.9, xrTalk.font )
        dxDrawText( self.value .. " рублей", xpos, ypos + fontHeight, control.width, ypos + fontHeight, INFO_VALUE_COLOR, FONT_SCALE, xrTalk.font )
     end
}
MessageFoundMoneyMT = {
    __index = MessageFoundMoney
}

MessageRankIncrease = {
    icon = "ui_iconsTotal_take_reward",
    label = "Ранг повышен",
    onCreate = function( self, ypos, value )
        local height = INFO_HEIGHT + INFO_GAP

        local msg = {
            value = tonumber( value ) or 0,
            ypos = ypos,
            height = height
        }
        return setmetatable( msg, MessageRankIncreaseMT ), height
    end,
    onDraw = function( self, scroll )
        local control = xrTalk.logList
        local fontHeight = dxGetFontHeight( FONT_SCALE, xrTalk.font )    
        local ypos = self.ypos + scroll   

        local xpos = fontHeight
        xrTextureSections[ self.icon ]:draw( g_InfoTexDict, xpos, ypos, INFO_WIDTH, INFO_HEIGHT, WHITE_COLOR )
        xpos = xpos + INFO_WIDTH + 5
        dxDrawText( self.label, xpos, ypos, control.width, ypos + fontHeight, INFO_HEADER_COLOR, FONT_SCALE * 0.9, xrTalk.font )
        dxDrawText( "+" .. self.value, xpos, ypos + fontHeight, control.width, ypos + fontHeight, INFO_VALUE_COLOR, FONT_SCALE, xrTalk.font )
     end
}
MessageRankIncreaseMT = {
    __index = MessageRankIncrease
}

MessageGiveItem = {
    icon = "ui_iconsTotal_found_thing",
    label = "Предмет получен",
    onCreate = function( self, ypos, itemHash, count )
        local height = INFO_HEIGHT + INFO_GAP

        local itemSection = xrSettingsGetSection( itemHash )
        if itemSection then
            local name = xrGetLocaleText( _hashFn( itemSection.inv_name ) ) or ""
            if count > 1 then
                name = name .. " x" .. count
            end

            local msg = {
                value = tonumber( value ) or 0,
                ypos = ypos,
                name = name,
                height = height
            }
            return setmetatable( msg, MessageGiveItemMT ), height
        else
            outputDebugString( "Предмет такого типа не был найден", 2 )
        end
    end,
    onDraw = function( self, scroll )
        local control = xrTalk.logList
        local fontHeight = dxGetFontHeight( FONT_SCALE, xrTalk.font )    
        local ypos = self.ypos + scroll   

        local xpos = fontHeight
        xrTextureSections[ self.icon ]:draw( g_InfoTexDict, xpos, ypos, INFO_WIDTH, INFO_HEIGHT, WHITE_COLOR )
        xpos = xpos + INFO_WIDTH + 5
        dxDrawText( self.label, xpos, ypos, control.width, ypos + fontHeight, INFO_HEADER_COLOR, FONT_SCALE * 0.9, xrTalk.font )
        dxDrawText( self.name, xpos, ypos + fontHeight, control.width, ypos + fontHeight, INFO_VALUE_COLOR, FONT_SCALE, xrTalk.font )
     end
}
MessageGiveItemMT = {
    __index = MessageGiveItem
}

function initInfoTypes()
    g_InfoTypes[ _hashFn( "MessageFoundMoney" ) ] = MessageFoundMoney
    g_InfoTypes[ _hashFn( "MessageGiveItem" ) ] = MessageGiveItem
    g_InfoTypes[ _hashFn( "MessageRankIncrease" ) ] = MessageRankIncrease
    g_InfoTypes[ _hashFn( "MessageText" ) ] = MessageText


    g_InfoTexDict = {
        [ "ui\\ui_iconsTotal" ] = dxCreateTexture( "textures/ui_iconstotal.dds" ) 
    }
end
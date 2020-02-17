local sw, sh = guiGetScreenSize()

local DEFAULT_DURATION = 2000

xrHelpWindow = {
    bias = sh * 0.3,
    width = sw * 0.5,
    color = tocolor( 245, 255, 250 ),
    messages = {}
}

function xrHelpWindow:setup()
    if self.initialized then
        return false
    end

    self.font = exports.sp_assets:xrLoadAsset( "LettericaRomanMedium" )

    self.initialized = true
end

function xrHelpWindow:destroy()
    if not self.initialized then
        return
    end

    destroyElement( self.font )

    self.initialized = nil
end

function xrHelpWindow:draw( dt )
    if not self.initialized then
        return
    end

    local messages = self.messages

    local firstMsg = messages[ 1 ]
    if firstMsg then
        local xpos = sw / 2 - self.width / 2
        local ypos = sh - self.bias

        dxDrawText( firstMsg.text, xpos, ypos, xpos + self.width, sh, self.color, 0.75, self.font, "center", "top", false, true )

        firstMsg.time = firstMsg.time - dt
        if firstMsg.time <= 0 then
            table.remove( messages, 1 )
        end
    end
end

function xrHelpWindow:update()
    
end

function xrHelpWindow:print( text, priority, time )
    --[[
        Форсируем показ нового сообщения, урезая время показа старых
    ]]
    for _, message in ipairs( self.messages ) do
        message.time = math.max( message.time * 0.5, 3000 )
    end

    --[[
        Вставляем новое сообщение
    ]]
    local msg = {
        text = text,
        priority = tonumber( priority ) or 0,
        time = tonumber( time ) or DEFAULT_DURATION
    }    
    table.insert( self.messages, msg )

    --[[
        Сортируем сообщения по приоритету
    ]]
    table.sort( self.messages,
        function( lhs, rhs )
            return lhs.priority > rhs.priority
        end
    )
end

function xrHelpWindow:hideAll()
    self.messages = {}
end
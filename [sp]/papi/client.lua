--[[
    ParticleRenderer
]]
ParticleRenderer = {
    effects = {}
}

function ParticleRenderer:add( effect )
	table.insert( self.effects, effect )
end

function ParticleRenderer:remove( effect )
    table.removeValue( self.effects, effect )
end

function ParticleRenderer:update( dt )
    local effects = self.effects
    for _, effect in ipairs( effects ) do				
        effect:update( dt )
    end

    for i = #effects, 1, -1 do
        local effect = effects[ i ]
        if effect.isGarbage then
            table.remove( effects, i )
            break
            --outputChatBox( "Effect removed" )
        end
    end
end

function ParticleRenderer:render( dt )
    local effects = self.effects
    for _, effect in ipairs( effects ) do
        effect:preRender( dt )
        effect:render( dt )
    end
end

--[[
	GroupRenderer
]]
GroupRenderer = {
    groups = {},

}

function GroupRenderer:add( group )
	table.insert( self.groups, group )
end

function GroupRenderer:remove( group )
    table.removeValue( self.groups, group )
end

function GroupRenderer:update( dt )
    local groups = self.groups
    for _, group in ipairs( groups ) do
        group:update( dt )
    end

    for i = #groups, 1, -1 do
        local group = groups[ i ]
        if group.isGarbage then
            table.remove( groups, i )
            break
            --outputChatBox( "Group removed" )
        end
    end
end

function GroupRenderer:render( dt )
    local groups = self.groups
    for _, group in ipairs( groups ) do
        group:render( dt )
    end
end

--[[
    ParticleStatistics
]]
ParticleStatistics = {
    clippedNum = 0,
    actionTypes = {},
    actionSum = {}
}

function ParticleStatistics:beginFrame()
    self.clippedNum = 0
    self.actionSum = {}
    self.actionTypes = {}

    for i = 1, 29 do
        self.actionSum[ i ] = 0
    end
end

function ParticleStatistics:addClipped()
    self.clippedNum = self.clippedNum + 1
end

function ParticleStatistics:startAction( actionType )
    self.actionTypes[ actionType ] = getTickCount()
end

function ParticleStatistics:endAction( actionType )
    local delta = getTickCount() - self.actionTypes[ actionType ]
    self.actionSum[ actionType ] = self.actionSum[ actionType ] + delta
end

Plane = {

}
PlaneMT = {
    __index = Plane
}

function Plane_new( normal, position )
    normal = normal:getNormalized()

    local plane = {
        normal = normal,
        position = position,
        d = -normal:dot( position )
    }

    return setmetatable( plane, PlaneMT )
end

function Plane:define( normal, position )
    normal = normal:getNormalized()

    self.normal = normal
    self.position = position
    self.d = -normal:dot( position )
end

function Plane:getDistance( point )
    return self.normal:dot( point ) + self.d
end

local _counter = 5
local _lastDT = 0
function onPreRender( dt )
    dt = dt / 1000
    _lastDT = _lastDT + dt    

    -- Выполяем проход отрисовки
    GroupRenderer:render( dt )
    --ParticleRenderer:render( dt )

    -- Обновление на частоте вдвое меньшей среднему FPS
    if _counter <= 0 then
        -- Обновляем плоскость отсечения
        local viewMatrix = Camera.matrix
        g_ClippingPlane:define( viewMatrix:getForward(), viewMatrix:getPosition() )

        -- Выполяем проход обновления
        GroupRenderer:update( _lastDT )
        --ParticleRenderer:update( extendedDt )

        --local x, y, z = getElementPosition( localPlayer )
        --g_GroupStreamer:update( x, y, z )

        _counter = 5
        _lastDT = 0
    else
        _counter = _counter - 1
    end
end 

--[[
    Particle groups exports
]]
local groupDefs = {

}

local function getOrCreateGroupDefinition( name )
	if groupDefs[ name ] then
		return groupDefs[ name ]
	end

	local xml = xmlLoadFile ( name )
	if xml then
		local def = ParticleGroupDef.load( xml )
		xmlUnloadFile ( xml )
		groupDefs[ name ] = def

		return def
	else
		outputDebugString ( "Файла " .. name .. " не существует!", 1 )
	end
end

function xrGroupPlay( name, x, y, z, rx, ry, rz, streamable )
    streamable = streamable == nil or streamable == true

    local def = getOrCreateGroupDefinition( name )
    if not def then
        return false
    end

    local group = ParticleGroup_create( def )
    if group then
        local rot
        if type( rx ) == "number" then
            rot = Vector3( rx, ry, rz )
        end
        group.matrix = Matrix( Vector3( x, y, z ), rot )

        local id = g_Groups:push( group )
        group.id = id

        GroupRenderer:add( group )
        if streamable then
            group:setVisible( false )
            g_GroupStreamer:pushItem( group, x, y, z )
        end

        group:play()

        return id
    end

    outputDebugString( "При создании группы эффектов " .. tostring( name ) .. " произошли ошибки", 2 )
    return false
end

function xrGroupDestroy( index )
    if not index then
        return
    end

    local group = g_Groups[ index ]
    if group then
        group:stop( false )

        GroupRenderer:remove( group )
        g_GroupStreamer:removeItem( group )

        g_Groups[ index ] = nil
    end
end

function xrGroupExists( index )
    if index then
        return g_Groups[ index ] ~= nil
    end
end

--[[
    Effect exports
]]
--[[
	Test
]]
local effectDefs = {

}

function getOrCreateEffectDefinition ( name )
	if effectDefs[ name ] then
		return effectDefs[ name ]
	end

	local xml = xmlLoadFile ( "Particle/" .. name .. ".xml" )
	if xml then
		local def = ParticleDef.load( xml )
		xmlUnloadFile ( xml )
		effectDefs[ name ] = def

		return def
	else
		outputDebugString ( "Файла " .. name .. " не существует!", 1 )
	end
end

function xrEffectPlay( name, x, y, z, rx, ry, rz, streamable )
    streamable = streamable == nil or streamable == true

    local def = getOrCreateEffectDefinition ( name )
    if not def then
        return false
    end

	local effect = ParticleEffect_create( def )
	if effect then
		local rot
        if type( rx ) == "number" then
            rot = Vector3( rx, ry, rz )
        end
        effect.matrix = Matrix( Vector3( x, y, z ), rot )

        local id = g_Effects:push( effect )
        effect.id = id

        ParticleRenderer:add( effect )
        if streamable then
            effect:setVisible( false )
            g_GroupStreamer:pushItem( effect, x, y, z )
        end

        effect:play()

        return id        
    end
end

function xrEffectDestroy( index )
    if not index then
        return
    end

    local effect = g_Effects[ index ]
    if effect then
        effect:stop( false )

        ParticleRenderer:remove( effect )
        g_GroupStreamer:removeItem( effect )

        g_Effects[ index ] = nil
    end
end

function xrEffectExists( index )
    if index then
        return g_Effects[ index ] ~= nil
    end
end

addEventHandler( "onClientCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "global.lua" )
		xrIncludeModule( "streamer.lua" )

       g_Groups = xrMakeIDTable()
       g_Effects = xrMakeIDTable()
       g_GroupStreamer = xrStreamer_new( 30, 1 )

       g_ClippingPlane = Plane_new( Vector3( 0, 1, 0 ), Vector3( 0, 0, 0 ) )

       addEventHandler( "onClientPreRender", root, onPreRender, false )
    end
)
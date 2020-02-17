--[[
    AnimationSpeed
]]
AnimationSpeed = {

}
AnimationSpeedMT = {
    __index = AnimationSpeed
}

function AnimationSpeed:new()
    local anim = {
        points = {}
    }

    return setmetatable( anim, AnimationSpeedMT )
end

function AnimationSpeed:addPoint( speed, animHash )
    local point = {
        speed, animHash
    }

    table.insert( self.points, point )

    table.sort( self.points,
        function( lhs, rhs )
            return lhs[ 1 ] < rhs[ 2 ]
        end
    )

    return self
end

function AnimationSpeed:perform( agent )
    local points = self.points
    local ped = agent.ped
    local velocity = agent:getVelocity()
    local speed = velocity:getLength()

    if #points < 1 then
        return false
    end

    for i = 1, #points do
        local prevPoint = points[ i - 1 ]
        local point = points[ i ]
        if ( not prevPoint or speed > prevPoint[ 1 ] ) and speed <= point[ 1 ] then
            setPedAnimDef( ped, point[ 2 ] )

            return true
        end
    end
    
    return false
end

--[[
    AnimationData
]]
AnimationData = {

}
AnimationDataMT = {
    __index = AnimationData
}

function AnimationData:new( dataName, dataValue, animHash )
    local anim = {
        dataName = dataName,
        dataValue = dataValue,
        animHash = animHash
    }

    return setmetatable( anim, AnimationDataMT )
end

function AnimationData:perform( agent )
    local ped = agent.ped

    local value = getElementData( ped, self.dataName, false )
    if value == self.dataValue then
        setPedAnimDef( ped, self.animHash )

        return true
    end

    return false
end

--[[
    AnimationFunctor
]]
AnimationFunctor = {

}
AnimationFunctorMT = {
    __index = AnimationFunctor
}

function AnimationFunctor:new( fn, animHash )
    local anim = {
        fn = fn,
        animHash = animHash
    }

    return setmetatable( anim, AnimationFunctorMT )
end

function AnimationFunctor:perform( agent )
    local ped = agent.ped

    local result = self.fn( ped )
    if result then
        setPedAnimDef( ped, self.animHash )

        return true
    end

    return false
end

--[[
    AnimationSelector
]]
AnimationSelector = {

}
AnimationSelectorMT = {
    __index = AnimationSelector
}

function AnimationSelector:new()
    local selector = {
        anims = {}
    }

    return setmetatable( selector, AnimationSelectorMT )
end

function AnimationSelector:update( agent )
    for i, anim in ipairs( self.anims ) do
        -- Анимация успешно применена? Отлично, выходим из цикла
        if anim:perform( agent ) then
            return
        end
    end
end

function AnimationSelector:insert( anim )
    table.insert( self.anims, anim )

    return self
end
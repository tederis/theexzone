function getCurrentTime()
    local now = getTickCount()
    return now / 1000
end

function isPedActuallyDead( ped )
    return isPedDead( ped ) or getElementHealth( ped ) <= 1
end

--[[
    Time
]]
local weakMT = {
    __mode = "k"
}

Time = {

}
TimeMT = {
    __index = Time
}

function Time:new()
    local time = {
        schedules = {},
        delays = {}
    }

    for _, res in ipairs( TIMER_RESOLUTIONS ) do
        time.schedules[ res ] = setmetatable( {}, weakMT )
    end

    return setmetatable( time, TimeMT )
end

function Time:reset()
    self.schedules = {}
    self.delays = setmetatable( {}, weakMT )

    for _, res in ipairs( TIMER_RESOLUTIONS ) do
        self.schedules[ res ] = setmetatable( {}, weakMT )
    end
end

function Time:pulse( res )
    local resTimers = self.schedules[ res ] or EMPTY_TABLE
    for owner, fn in pairs( resTimers ) do
        fn( owner, res )
    end
end

function Time:update( dt )
    local now = getCurrentTime()

    for owner, ownerDelays in pairs( self.delays ) do
        for fn, endTime in pairs( ownerDelays ) do
            if now >= endTime then
                fn( owner, dt )

                --[[
                    При выполнении fn мог быть задан новый таймер на той же функции
                    поэтому обязательно проверяем
                ]]
                endTime = ownerDelays[ fn ]
                if endTime and endTime <= now then
                    ownerDelays[ fn ] = nil
                end
            end
        end
    end
end

function Time:delay( owner, fn, duration )
    local now = getCurrentTime()

    local ownerDelays = self.delays[ owner ]
    if ownerDelays then
        ownerDelays[ fn ] = now + duration
    else
        self.delays[ owner ] = {
            [ fn ] = now + duration
        }
    end

    return true
end

function Time:undelay( owner, fn )
    -- Если функция не указана - удаляем все задержки на объекте
    if type( fn ) ~= "function" then
        self.delays[ owner ] = nil

        return true
    end

    local ownerDelays = self.delays[ owner ]
    if ownerDelays then
        ownerDelays[ fn ] = nil
    end

    return true
end

function Time:schedule( owner, fn, resolution )
    local resTimers = self.schedules[ resolution ]
    if resTimers then
        resTimers[ owner ] = fn
    else
        outputDebugString( "Недопустимое разрешение таймера( " .. tostring( resolution ) .. " )", 2 )
    end

    return true
end

function Time:unschedule( owner, resolution )
    -- Если явно указано разрешение
    if type( resolution ) == "number" then
        local resTimers = self.schedules[ resolution ]
        if resTimers then
            resTimers[ owner ] = nil

            return true
        end
    end

    -- Ищем по всем разрешениям
    for res, resTimers in pairs( self.schedules ) do
        if resTimers[ owner ] then
            resTimers[ owner ] = nil
        end
    end

    return true
end
local UPDATE_PERIOD = 80

--[[
    AffectorEntry
]]
AffectorEntry = {

}
AffectorEntryMT = {
    __index = AffectorEntry
}

function AffectorEntry:new()
    local collection = {
        owners = {},
        value = 0
    }

    return setmetatable( collection, AffectorEntryMT )
end

function AffectorEntry:test( ownerSignature )
    return self.owners[ ownerSignature ] ~= true
end

function AffectorEntry:insert( value, ownerSignature )
    if self.owners[ ownerSignature ] ~= true then
        self.value = self.value + value
        self.owners[ ownerSignature ] = true
    end
end

function AffectorEntry:remove( value, ownerSignature )
    if self.owners[ ownerSignature ] == true then
        self.value = self.value - value
        self.owners[ ownerSignature ] = nil
    end
end

--[[
    PlayerAffector
]]
PlayerAffector = {

}
PlayerAffectorMT = {
    __index = PlayerAffector
}

local _affectorPulseTimer

local boosterTypes = {
    "boost_health_restore",
    "boost_power_restore",
    "boost_radiation_restore",
    "boost_bleeding_restore",
    "boost_max_weight",
    "boost_radiation_protection",
    "boost_telepat_protection",
    "boost_chemburn_protection",
    "boost_burn_immunity",
    "boost_shock_immunity",
    "boost_radiation_immunity",
    "boost_telepat_immunity",
    "boost_chemburn_immunity",
    "boost_explosion_immunity",
    "boost_strike_immunity",
    "boost_fire_wound_immunity",
    "boost_wound_immunity"
}

local artefactBoostTypes = {
    "health_restore_speed",
    "power_restore_speed",
    "radiation_restore_speed",
    --"satiety_restore_speed",
    "bleeding_restore_speed"       
}

local function loadChanger( section, prefix )
    local changer = {
        radiation = section[ "radiation_v" .. prefix ],
        radiationHealth = section[ "radiation_health_v" .. prefix ],
        psyHealth = section[ "psy_health_v" .. prefix ],
        bleeding = section[ "bleeding_v" .. prefix ],
        woundIncarnation = section[ "wound_incarnation_v" .. prefix ],
        healthRestore = 0
    }

    if section[ "health_restore_v" .. prefix ] then
        changer.healthRestore = section[ "health_restore_v" .. prefix ]
    end

    return changer
end

function PlayerAffector:onHit( hitType, power, bodypart, attacker )
    if self.wasted then
        return
    end

    local section = self.section
    local boosters = self.boosters
    local immunity = 1 - self.immunity[ hitType ]

    --outputDebugString( "Hit " .. hitType .. ", " .. power )
    if getElementData( localPlayer, "godmode", false ) then
        return
    end

    if hitType == PHT_RADIATION then
        power = math.max( power - boosters[ EBRadiationProtection ], 0 )
        power = power * ( immunity - boosters[ EBRadiationImmunity ] )
        self.deltaRadiation = self.deltaRadiation + power
    elseif hitType == PHT_STRIKE then
        -- Если игрок находится в зеленой зоне
        if getElementData( localPlayer, "damageProof" ) then
            return
        end

        power = power * ( immunity - boosters[ EBStrikeImmunity ] )

        local damageCoeff = tonumber( getElementData( localPlayer, "damageCoeff", false )  )
        if damageCoeff then
            power = power * damageCoeff
        end

        self.deltaHealth = self.deltaHealth - power * section.health_hit_part
        self.deltaPower = self.deltaPower - power * section.power_hit_part
        self.woundsNum = math.min( self.woundsNum + 1, 30 )

        -- Force health calculation
        self:update()

        if self.health < 0.01 then
            triggerServerEvent( EServerEvents.onPlayerForceDead, localPlayer, attacker, bodypart )
            self.wasted = true
        end
    elseif hitType == PTH_SHOCK then
        power = power * ( immunity - boosters[ EBShockImmunity ] )
        self.deltaHealth = self.deltaHealth - power * section.health_hit_part
        self.deltaPower = self.deltaPower - power * section.power_hit_part
    elseif hitType == PTH_POWER then
        power = power * ( immunity - boosters[ EBMaxWeight ] )
        self.deltaPower = self.deltaPower - power * section.power_hit_part
    end
end

function PlayerAffector:applyBooster( index, value, time )
    self.boosters[ index ] = value
    self.boostTimes[ index ] = time

    triggerEvent( EClientEvents.onClientBoosterApplied, localPlayer, index, time )
end

function PlayerAffector:applyAffect( index, value, ownerSignature )   
    --outputDebugString( "Affect added " .. index .. " = " .. value .. " prev( " .. self.affects[ index ] .. ")" ) 
    --self.affects[ index ] = self.affects[ index ] + value    

    self.affects[ index ]:insert( value, ownerSignature )
end

function PlayerAffector:removeAffect( index, value, ownerSignature )
    --outputDebugString( "Affect removed " .. index .. " = " .. value .. " prev( " .. self.affects[ index ] .. ")" )
    --self.affects[ index ] = self.affects[ index ] - value

    self.affects[ index ]:remove( value, ownerSignature )
end 

local MAX_HEALTH = 1
local MIN_HEALTH = -0.01

local MAX_POWER = 1
local MAX_RADIATION = 1
local MAX_PSY_HEALTH = 1

function PlayerAffector:update()
    local now = getTickCount()
    local dt = ( now - self.lastUpdateTime ) / 1000

    if self.wasted then
        self.deltaPower = 0
        self.deltaHealth = 0
        self.deltaPsyHealth = 0
        self.deltaRadiation = 0
        self.lastUpdateTime = now
        return
    end

    local section = self.section
    local changer = self.changer
    local boosters = self.boosters
    local boostTimes = self.boostTimes
    local affects = self.affects

    --outputDebugString( "Power " .. self.power .. ", Psy " .. self.psyHealth .. ", Rad " .. self.radiation .. ", Health " .. self.health .. ", DeltaH " .. self.deltaHealth )

    --[[
        Power
    ]]
    self.deltaPower = self.deltaPower + section.satiety_power_v + affects[ EAT_POWER_RSPD ].value + boosters[ EBPowerRestore ]

    --[[
        Update boosters
    ]]
    for i, time in ipairs( boostTimes ) do
        local delta = time - dt
        if delta <= 0 then
            boostTimes[ i ] = 0
            boosters[ i ] = 0
        else
            boostTimes[ i ] = delta
        end
    end

    --[[
        Health
    ]]
    local bleedingSpeed = ( self.woundsNum / 30 ) * changer.bleeding * dt
    self.deltaHealth = self.deltaHealth - bleedingSpeed
    local healthRestore = changer.healthRestore + ( boosters[ EBHpRestore ] + affects[ EAT_HEALTH_RSPD ].value )
    self.deltaHealth = self.deltaHealth + healthRestore * dt
    self.woundsNum = math.max( self.woundsNum - ( changer.woundIncarnation + boosters[ EBBleedingRestore ] + affects[ EAT_BLEED_RSPD ].value ) * dt, 0 )
    --[[
        Psy health
    ]]    
    self.deltaPsyHealth = self.deltaPsyHealth + changer.psyHealth * dt
 
    --[[
        Radiation
    ]]
    if self.radiation > 0 then
        local radiationRestore = changer.radiation + ( boosters[ EBRadiationRestore ] + affects[ EAT_RAD_RSPD ].value )
        self.radiation = self.radiation - radiationRestore * dt
        self.deltaHealth = self.deltaHealth - changer.radiationHealth * self.radiation * dt
    end

    self.power = math.clamp( 0, MAX_POWER, self.power + self.deltaPower )
    self.psyHealth = math.clamp( 0, MAX_PSY_HEALTH, self.psyHealth + self.deltaPsyHealth )
    self.radiation = math.clamp( 0, MAX_RADIATION, self.radiation + self.deltaRadiation )
    self.health = math.clamp( MIN_HEALTH, MAX_HEALTH, self.health + self.deltaHealth )

    setElementHealth( localPlayer, self.health * 100 )
    setElementData( localPlayer, "radiation", self.radiation, false )
    setElementData( localPlayer, "power", self.power, false )
    setElementData( localPlayer, "psyHealth", self.psyHealth, false )
    setElementData( localPlayer, "bleeding", self.woundsNum / 30, false )
    
    self.deltaPower = 0
    self.deltaHealth = 0
    self.deltaPsyHealth = 0
    self.deltaRadiation = 0    

    self.lastUpdateTime = now
end

function PlayerAffector_create( typeHash )
    if g_PlayerAffector then
        return
    end

    local section = xrSettingsGetSection( typeHash )
    if not section then
        outputDebugString( "Аффектора такого типа не существует!", 2 )
        return false
    end

    -- Коэффициенты изменения величин
    local changer = loadChanger( section, "" )

    local affector = {
        section = section,
        changer = changer,
        immunity = {
            
        },
        boosters = {
           
        },
        boostTimes = {
            
        },
        affects = {
            
        },
        --[[affectOwners = {

        },]]

        radiation = 0,
        power = MAX_POWER,
        health = getElementHealth( localPlayer ) / 100,
        psyHealth = MAX_PSY_HEALTH,
        woundsNum = 0,

        deltaPower = 0,
        deltaHealth = 0,
        deltaPsyHealth = 0,
        deltaRadiation = 0,

        lastUpdateTime = getTickCount(),

        wasted = false
    }
    setmetatable( affector, PlayerAffectorMT )

    for i, _ in ipairs( PlayerHitType ) do
        affector.immunity[ i ] = 0
    end

    for i, _ in ipairs( boosterTypes ) do
        affector.boosters[ i ] = 0
        affector.boostTimes[ i ] = 0
    end

    for i, _ in ipairs( artefactBoostTypes ) do
        affector.affects[ i ] = AffectorEntry:new()
    end

    g_PlayerAffector = affector
end

function PlayerAffector_pulse()
    g_PlayerAffector:update()

    if g_PlayerAffector.health < 0.01 then
        triggerServerEvent( EServerEvents.onPlayerForceDead, localPlayer )
        g_PlayerAffector.wasted = true
    end
end

function PlayerAffector_onHit( hitType, power, bodypart, attacker )
    g_PlayerAffector:onHit( hitType, power, bodypart, attacker ) 
end

function PlayerAffector_applyBooster( itemHash )
    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection then
        outputDebugString( "Бустера с такой секцией не существует! " .. tostring( itemHash ), 2 )
        return false
    end

    if itemSection.eat_radiation then
        g_PlayerAffector.deltaRadiation = g_PlayerAffector.deltaRadiation + itemSection.eat_radiation
    end
    if itemSection.eat_health then
        g_PlayerAffector.deltaHealth = g_PlayerAffector.deltaHealth + itemSection.eat_health
    end
    if itemSection.eat_bleeding then
        g_PlayerAffector.woundsNum = math.max( g_PlayerAffector.woundsNum - g_PlayerAffector.woundsNum * itemSection.eat_bleeding, 0 )
    end

    for i, fieldName in ipairs( boosterTypes ) do
        local value = tonumber( itemSection[ fieldName ] ) or 0
        if math.abs( value ) > 0.001 then
            g_PlayerAffector:applyBooster( i, value, itemSection.boost_time )
        end
    end
end

function PlayerAffector_applyItemAffects( itemHash, itemId )
    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection then
        outputDebugString( "Аффекта с такой секцией не существует! " .. tostring( itemHash ), 2 )
        return false
    end

    -- Итерируем все типы аффекторов и смотрим какие имеются в предмете
    for affectTypeIndex, fieldName in ipairs( artefactBoostTypes ) do
        local value = tonumber( itemSection[ fieldName ] ) or 0
        g_PlayerAffector:applyAffect( affectTypeIndex, value, itemId )
    end
end

function PlayerAffector_removeItemAffects( itemHash, itemId )
    local itemSection = xrSettingsGetSection( itemHash )
    if not itemSection then
        outputDebugString( "Аффекта с такой секцией не существует! " .. tostring( itemHash ), 2 )
        return false
    end

    -- Итерируем все типы аффекторов и смотрим какие имеются в предмете
    for affectTypeIndex, fieldName in ipairs( artefactBoostTypes ) do
        local value = tonumber( itemSection[ fieldName ] ) or 0
        g_PlayerAffector:removeAffect( affectTypeIndex, value, itemId )
    end
end

function PlayerAffector_applyAffect( affectTypeIndex, value, ownerSignature )
    if g_PlayerAffector then
        g_PlayerAffector:applyAffect( affectTypeIndex, value, ownerSignature )
    end
end

function PlayerAffector_removeAffect( affectTypeIndex, value, ownerSignature )
    if g_PlayerAffector then
        g_PlayerAffector:removeAffect( affectTypeIndex, value, ownerSignature )
    end
end

function PlayerAffector_getAffects()
    if g_PlayerAffector then
        local affects = {}

        for affectTypeIndex, affectEntry in pairs( g_PlayerAffector.affects ) do
            affects[ affectTypeIndex ] = affectEntry.value
        end

        return affects
    end

    return EMPTY_TABLE
end

function initAffectors()
    _affectorPulseTimer = setTimer( PlayerAffector_pulse, UPDATE_PERIOD, 0 ) 
    
    addEvent( EClientEvents.onClientApplyBooster, true )
    addEventHandler( EClientEvents.onClientApplyBooster, localPlayer, PlayerAffector_applyBooster, false )
    addEvent( EClientEvents.onClientApplyItemAffects, true )
    addEventHandler( EClientEvents.onClientApplyItemAffects, localPlayer, PlayerAffector_applyItemAffects, false )
    addEvent( EClientEvents.onClientRemoveItemAffects, true )
    addEventHandler( EClientEvents.onClientRemoveItemAffects, localPlayer, PlayerAffector_removeItemAffects, false )
    addEvent( EClientEvents.onClientPlayerHit, true )
    addEventHandler( EClientEvents.onClientPlayerHit, localPlayer, PlayerAffector_onHit, false )
end

function destroyAffectors()
    killTimer( _affectorPulseTimer )

    removeEventHandler( EClientEvents.onClientApplyBooster, localPlayer, PlayerAffector_applyBooster )
    removeEventHandler( EClientEvents.onClientApplyItemAffects, localPlayer, PlayerAffector_applyItemAffects )
    removeEventHandler( EClientEvents.onClientRemoveItemAffects, localPlayer, PlayerAffector_removeItemAffects )
    removeEventHandler( EClientEvents.onClientPlayerHit, localPlayer, PlayerAffector_onHit )
end
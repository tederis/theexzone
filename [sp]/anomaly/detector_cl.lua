local sw, sh = guiGetScreenSize( )

xrDetectors = {
    -- Реализация логики для различных видов детекторов
}

--[[
    xrDetectorSlot
]]
xrDetectorSlot = {

}
xrDetectorSlotMT = {
    __index = xrDetectorSlot
}

function xrDetectorSlot_create()
    local slot = {

    }

    return setmetatable( slot, xrDetectorSlotMT )
end

function xrDetectorSlot:empty()
    return self.detector == nil
end

function xrDetectorSlot:set( typeHash )    
    local detector = xrDetectors[ typeHash ]
    if detector then
        if self.detector then
            if detector == self.detector then
                return
            end

            self.detector:stop( xrDetectorSlot.onDetectorHided, self )
            self.nextDetector = detector
        else
            self.detector = detector
            detector:start()
        end
    elseif self.detector then
        self.detector:stop( xrDetectorSlot.onDetectorHided, self )
    end
end

function xrDetectorSlot:onDetectorHided()
    self.detector = nil

    local nextDetector = self.nextDetector
    if nextDetector then
        self.detector = nextDetector
        nextDetector:start()
    end
end

function xrDetectorSlot:update( dt )
    local detector = self.detector
    if detector then
        detector:update( dt )
    end
end

function xrDetectorSlot:render()
    local detector = self.detector
    if detector then
        detector:render()
    end
end

--[[
    ClientDetector
]]
ClientDetector = {
    slots = {}
}

function ClientDetector:init()
    local slot = xrDetectorSlot_create()
    if slot then
        slot:set( _hashFn( "detector_geiger" ) )
        self.slots[ EDetectorSlots.SlotGeiger ] = slot
    end

    slot = xrDetectorSlot_create()
    if slot then
        self.slots[ EDetectorSlots.SlotAnomaly ] = slot
    end

    bindKey( "b", "down", ClientDetector.onSwitchKey )
    addEventHandler( "onClientPlayerWasted", localPlayer, ClientDetector.onPlayerWasted, false )
end

function ClientDetector.onSwitchKey()
    local self = ClientDetector

    local slot = self.slots[ EDetectorSlots.SlotAnomaly ]
    if slot then
        if slot:empty() then
            slot:set( _hashFn( "detector_simple" ) )
        else
            slot:set( false )
        end
    end
end

function ClientDetector.onPlayerWasted()
    local self = ClientDetector

    local slot = self.slots[ EDetectorSlots.SlotAnomaly ]
    if slot then
        slot:set( false )
    end
end

function ClientDetector:process( dt )
    for slotHash, slot in pairs( self.slots ) do
        slot:update( dt )
    end
end

function ClientDetector:render( dt )
    for slotHash, slot in pairs( self.slots ) do
        slot:render()
    end
end

--[[
    SoundRepeater
]]
SoundRepeater = {    
}
SoundRepeaterMT = {
    __index = SoundRepeater
}

function SoundRepeater:create( )
    local repeater = {
        snd = nil,
        name = "",
        time = 0,
        period = 0
    }

    return setmetatable( repeater, SoundRepeaterMT )
end

function SoundRepeater:play( name, freq )
    if isElement( self.snd ) then
        stopSound( self.snd )
    end

    self.snd = playSound( name, false )
    if not self.snd then
        outputDebugString( "Не можем найти звук", 2 )
    end
    self.name = name
    self.time = 0
    self.period = 1 / freq
end

function SoundRepeater:kill()
    if isElement( self.snd ) then
        stopSound( self.snd )
    end
    self.snd = nil
    self.name = nil
end

function SoundRepeater:update( dt )
    if not self.name then
        return
    end

    if self.time > self.period then
        self.time = 0
        
        if not isElement( self.snd ) then
            self.snd = playSound( self.name, false )
            if not self.snd then
                outputDebugString( "Не можем найти звук", 2 )
            end
        end        
    else
        self.time = self.time + dt
    end
end

--[[
    Impls
]]
local PHASE_SHOWING = 1
local PHASE_IDLE = 2
local PHASE_HIDING = 3

SimpleDetector = {
   
}

function SimpleDetector:start()
    if self.phase ~= PHASE_SHOWING then
        self.startTime = getTickCount()
        self.phase = PHASE_SHOWING
        self.progress = 0
        self.focusing = false
        self.focusingTime = getTickCount()

        self.blinkingTime = getTickCount()
        self.blinkingFreq = 0
    end
end

function SimpleDetector:stop( fnCallback, ... )
    if self.phase ~= PHASE_HIDING then
        self.startTime = getTickCount()
        self.phase = PHASE_HIDING
        self.progress = 1

        if type( fnCallback ) == "function" then
            self.fnCallback = fnCallback
            self.fnArgs = { ... }
        end
    end
end

function SimpleDetector:load( section )
    -- Загружаем поведение детектора для определенных артефактов
    self.artefacts = {
        
    }

    --[[
        Визуал
    ]]
    self.originSize = sh * 0.7
    self.originX = 0
    self.originY = sh
    self.originRot = 160
    self.targetX = 0
    self.targetY = sh - self.originSize
    self.targetRot = -10

    self.shader = dxCreateShader( "shader.fx" )

	self.tex0 = dxCreateTexture( "textures/detector.png" )
	self.tex1 = dxCreateTexture( "textures/detector_light.png" )
	dxSetShaderValue( self.shader, "Tex0", self.tex0 )
	dxSetShaderValue( self.shader, "Tex1", self.tex1 )

    --[[
        Звуки
    ]]
    for i = 1, 100 do
        if section[ "af_class_" .. i ] then
            local classHash = _hashFn( section[ "af_class_" .. i ] )
            local sound = "Sounds/" .. section[ "af_sound_" .. i .. "_" ] .. ".ogg"
            local freq = section[ "af_freq_" .. i ]

            self.artefacts[ classHash ] = {
                sound = sound,     
                freqMin = freq:getX(),
                freqMax = freq:getY()
            }
        else
            break
        end
    end

    self.detectRadius = tonumber( section.af_radius ) or 30
    self.visRadius = tonumber( section.af_vis_radius ) or 1
    self.sndTime = 0    

    self.repeater = SoundRepeater:create()
end

function SimpleDetector:update( dt )
    if self.phase == PHASE_SHOWING then
        local progress = ( getTickCount() - self.startTime ) / 1000
        if progress <= 1 then
            self.progress = progress
        else
            self.phase = PHASE_IDLE
        end
    elseif self.phase == PHASE_HIDING then
        local progress = ( getTickCount() - self.startTime ) / 1000
        if progress <= 1 then           
            self.progress = 1 - progress
        else
            if type( self.fnCallback ) == "function" then
                self.fnCallback( unpack( self.fnArgs ) )

                self.fnCallback = nil
                self.fnArgs = nil
            end
        end
    elseif self.phase == PHASE_IDLE then
        self:process( dt )

        local value = 0
        if self.blinkingFreq > 0 then
            local t = ( getTickCount() - self.blinkingTime ) / 1000
            value = math.abs( math.sin( self.blinkingFreq * math.pi * t ) )
        end

        dxSetShaderValue( self.shader, "BlendValue", value )
    end
end

function SimpleDetector:render()
    local x = math.interpolate( self.originX, self.targetX, self.progress )
    local y = math.interpolate( self.originY, self.targetY, self.progress )

    dxSetShaderTransform( self.shader, 0, math.interpolate( self.originRot, self.targetRot, self.progress ), 0 )    
    dxDrawImage( x, y, self.originSize, self.originSize, self.shader )

    --dxDrawText( tostring(self.highlighting) .. "; " .. tostring(self.focusing), x, y )
end

function SimpleDetector:process( dt )
    local px, py, pz = getElementPosition( localPlayer )
    local artefacts = xrZoneFindArtefacts( px, py, pz, self.detectRadius )
    if #artefacts < 1 then
        self.repeater:kill()
        self.blinkingFreq = 0
        self.focusingTime = getTickCount()
        self.focusing = false
        self.highlighting = false
        self.targetArt = false
        return
    end
  
    local minDistSqr = nil
    local nearestArt = nil
    for i, artefact in ipairs( artefacts ) do
        local distSqr = ( artefact.x - px )^2 + ( artefact.y - py )^2 + ( artefact.z - pz )^2
        if ( not minDistSqr or distSqr < minDistSqr ) and artefact:isTimeToShow() then
            minDistSqr = distSqr
            nearestArt = artefact
        end        
    end

    if nearestArt ~= self.targetArt then
        self.targetArt = nearestArt

        -- Сбрасываем параметры подсветки
        self.focusingTime = getTickCount()
        self.focusing = false
        self.highlighting = false
    end

    if nearestArt then
        -- Если артефакт в зоне подсвечивания - показываем его
        local focusingState = minDistSqr < self.visRadius*self.visRadius
        if focusingState ~= self.focusing then
            self.focusing = focusingState
            self.highlighting = false
            self.focusingTime = getTickCount()
        end

        local highlightingState = focusingState and getTickCount() - self.focusingTime > 1000
        if highlightingState ~= self.highlighting then
            self.highlighting = highlightingState

            nearestArt:toggleVisibility( true )
        end

        local artefactMeta = self.artefacts[ nearestArt.typeHash ]
        if artefactMeta then
            local relPower = math.clamp( 0, 1, math.sqrt( minDistSqr ) / self.detectRadius )

            local period = artefactMeta.freqMin + ( artefactMeta.freqMax - artefactMeta.freqMin )*( relPower*relPower )
            local sndFreq = 0.9 + 0.5*( 1 - relPower )

            if self.sndTime > period then
                self.sndTime = 0            
                
                -- Звук
                self.repeater:play( artefactMeta.sound, sndFreq )

                -- Визуал
                self.blinkingTime = getTickCount()
                self.blinkingFreq = sndFreq
            else
                self.sndTime = self.sndTime + dt
            end
        end
    end
end

GeigerDetector = {
    
}

function GeigerDetector:start()
    
end

function GeigerDetector:stop()
    
end

function GeigerDetector:load( section ) 
    self.sounds ={}
    for i = 1, 8 do
        self.sounds[ i ] =  "Sounds/" .. section.zone_sound .. i .. ".ogg"
    end

    local freq = section.zone_freq
    self.freqMin = 0.1--freq:getX()
    self.freqMax = 1.8--freq:getY()

    self.sndTime = 0

    self.repeater = SoundRepeater:create()
end

function GeigerDetector:update( dt )
    self:process( dt )
end

function GeigerDetector:process( dt )
    local influence = xrGetPlayerZoneInfluence( EHashes.ZoneRadiation )
    if influence < 0.001 then
        self.repeater:kill()
        return
    end

    local influenceInv = 1 - influence
    local period = self.freqMin + ( self.freqMax - self.freqMin )*influenceInv
    local sndFreq = 0.05*influence

    if self.sndTime > period then
        self.sndTime = 0

        local sound = self.sounds[ math.random( 1, 8 ) ]
        self.repeater:play( sound, sndFreq )
    else
        self.sndTime = self.sndTime + dt
    end
end

function GeigerDetector:render()

end

local function xrDefineDetectorImpl( typeHash, tbl )
    local detectorSection = xrSettingsGetSection( typeHash )
    if detectorSection then
        tbl:load( detectorSection )

        xrDetectors[ typeHash ] = tbl
    else
        outputDebugString( "Такой секции для детектора не существует!", 2 )
    end
end

function xrInitDetectors()
    xrDefineDetectorImpl( _hashFn( "detector_simple" ), SimpleDetector )
    xrDefineDetectorImpl( _hashFn( "detector_geiger" ), GeigerDetector )    

    ClientDetector:init()
end

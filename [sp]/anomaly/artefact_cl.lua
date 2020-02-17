local _activeArtefacts = {

}

Artefact = {
    
}
ArtefactMT = {
    __index = Artefact
}

function Artefact.create( anomaly, typeHash )
    local section = xrSettingsGetSection( typeHash )
    if section then
        local artefact = {
            anomaly = anomaly,
            typeHash = typeHash,
            
            section = section,
            placed = false,
            streamedIn = false,
            visible = false,
            visibleTime = 0,
            lastShowTime = nil,

            lifeTime = 15
        }

        return setmetatable( artefact, ArtefactMT )
    end

    outputDebugString( "Такого артефакта не существует", 2 )
end

function Artefact:destroy()
    -- Отписка от обновления
    table.removeValue( _activeArtefacts, self )

    if isElement( self.object ) then
        destroyElement( self.object )
    end
end

function Artefact:isTimeToShow()
    local timeOut = not self.lastShowTime or getTickCount() - self.lastShowTime > ( self.lifeTime*1000 + 60000 )
    local placed = self.placed == true
    local streamedIn = self.streamedIn == true

    return timeOut and placed and streamedIn
end

function Artefact:findSpot()
    local anomaly = self.anomaly
    local originX, originY, originZ = anomaly.pos:getX(), anomaly.pos:getY(), anomaly.pos:getZ()

    for i = 1, 4 do
        local theta = math.random()*math.pi*2
        local radius = math.random()*3
        local artX = originX + radius * math.cos( theta )
        local artY = originY + radius * math.sin( theta )
        local artZ = originZ

        local hit, hitX, hitY, hitZ, hitElement = processLineOfSight( artX, artY, artZ - 15, artX, artY, artZ + 15, false, false, false, true )
        if hit and isElement( hitElement ) then
            if getElementData( hitElement, "meta", false ) == "terrain" then
                return hitX, hitY, hitZ
            end

            hit, hitX, hitY, hitZ, hitElement = processLineOfSight( artX, artY, artZ - 15, artX, artY, artZ + 15, false, false, false, true, false, false, false, false, hitElement )
            if hit and isElement( hitElement ) then
                if getElementData( hitElement, "meta", false ) == "terrain" then
                    return hitX, hitY, hitZ
                end
            end
        end        
    end

    return false
end

function Artefact:createEntity()
    local section = self.section

    if self.placed ~= true or self.streamedIn ~= true then
        return
    end

    if isElement( self.object ) ~= true then
        self.object = createObject( section.gta_model, self.x, self.y, self.z )
        setElementCollisionsEnabled( self.object, false )
        setElementData( self.object, "int", EHashes.ArtefactClass, false )
        setElementData( self.object, "cl", self.typeHash, false )
        setElementData( self.object, "anomalyId", self.anomaly.id, false )

        self.visibleTime = 0
        self.lastShowTime = getTickCount()

        if section.det_show_snd then
            playSound3D( section.det_show_snd, self.x, self.y, self.z )
        end

        -- Подписываемся на обновление
        table.insert( _activeArtefacts, self )

        -- Добавим объекту интерактивности( возможность подобрать )
        exports.sp_interact:xrInteractInsertElement( self.object )
    end
end

function Artefact:toggleVisibility( state )
    local section = self.section

    if state ~= self.visible then
        self.visible = state

        if state then
            self:createEntity()        
        else
            destroyElement( self.object )        

            -- Отписка от обновления
            table.removeValue( _activeArtefacts, self )
        end    
    end
end

function Artefact:update( dt )
    local section = self.section

    if self.visibleTime < self.lifeTime and self.visibleTime + dt >= self.lifeTime then
        if section.det_hide_snd then
            playSound3D( section.det_hide_snd, self.x, self.y, self.z )
        end
    end

    if self.visibleTime < self.lifeTime then
        local progress = math.min( self.visibleTime / 2, 1 )
        self.object.scale = getEasingValue( progress, "InBounce" )

        progress = ( getTickCount() % 10000 ) / 10000
        local value = getEasingValue( progress, "CosineCurve" )

        setElementPosition( self.object, self.x, self.y, self.z + value*0.4 )

        local rx, ry, rz = getElementRotation( self.object )
        setElementRotation( self.object, rx + dt*4*value, ry + dt*4*value, rz + dt*4*value )
    elseif self.visibleTime < self.lifeTime + 1.5 then
        local progress = math.min( ( self.visibleTime - self.lifeTime ) / 1.5, 1 )
        self.object.scale = 1 - getEasingValue( progress, "OutInBack" )
    else
        self:toggleVisibility( false )
    end

    self.visibleTime = self.visibleTime + dt
end

function Artefact:onStreamedIn()
    self.streamedIn = true

    if not self.placed then
        local x, y, z = self:findSpot()
        if x then
            self.x = x
            self.y = y
            self.z = z + 0.1

            self.placed = true

            --createColSphere( x, y, z, 1 )

            if self.visible then
                self:createEntity()
            end
        end
    end
end

function Artefact:onStreamedOut()
    self.streamedIn = false
end

function initArtefacts()
    addEventHandler( "onClientPreRender", root,
        function( dt )    
            dt = dt / 1000
            
            for _, artefact in ipairs( _activeArtefacts ) do
                artefact:update( dt )
            end
        end 
    , false )
end
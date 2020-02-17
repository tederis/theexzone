--[[
    Дескриптор группы эффектов
]]
ParticleGroupDef = {}

local effectsDefPool = {}
local function getOrCreateEffectDef( name )
    if type( name ) == "string" then
        local def = effectsDefPool[ name ]
        if def then
            return def
        end    

        local xml = xmlLoadFile ( name )
        if xml then
            local def = ParticleDef.load( xml )
            xmlUnloadFile ( xml )
            
            if def then
                effectsDefPool[ name ] = def
                return def
            end
        else
            outputDebugString ( "Файла " .. tostring( name ) .. " не существует!", 1 )
        end
    end

    return false
end

function ParticleGroupDef.load( xml )
    local groupInfo = {
        timeLimit = tonumber( xmlNodeGetAttribute( xml, "timeLimit" ) ) or 0,
        children = {}
    }
    local isRecalcTime = groupInfo.timeLimit <= 0.0001    

    for _, child in ipairs( xmlNodeGetChildren( xml ) ) do
        if xmlNodeGetName( child ) == "effect" then
            local name =  xmlNodeGetAttribute( child, "name" )
            local onPlayChild = xmlNodeGetAttribute( child, "onPlayChild" )
            local onBirthChild = xmlNodeGetAttribute( child, "onBirthChild" )
            local onDeadChild = xmlNodeGetAttribute( child, "onDeadChild" )

            local info = {
                effectDef = getOrCreateEffectDef( name ),
                onPlayChild = getOrCreateEffectDef( onPlayChild ),
                onBirthChild = getOrCreateEffectDef( onBirthChild ),
                onDeadChild = getOrCreateEffectDef( onDeadChild ),
                time0 = xmlNodeGetNumber( child, "time0", 0 ),
                time1 = xmlNodeGetNumber( child, "time1", 0 ),
                deferredStop = xmlNodeGetBool( child, "defferedStop", false ),
                enabled = xmlNodeGetBool( child, "enabled", false ),
                rewind = xmlNodeGetBool( child, "rewind", false ),
            }     

            if isRecalcTime then
                groupInfo.timeLimit = math.max( groupInfo.timeLimit, info.time1 )
            end

            table.insert( groupInfo.children, info )
        end
    end

    return groupInfo
end

--[[
    ParticleGroup
]]
ParticleGroup = {

}
ParticleGroupMT = {
    __index = ParticleGroup
}

function ParticleGroup_create( def )
    local group = {
        def = def,
        playing = false,
        visible = true,
        deferredStop = false,
        elapsedTime = 0,
        matrix = Matrix( Vector3( 0, 0, 0 ) ),
        effects = {},
        onPlayEffects = {},
        framesPerPass = 1,
        framesCounter = 0,
        forced = true
    }

    for i, effectInfo in ipairs( def.children ) do
        local effect = ParticleEffect_create( effectInfo.effectDef )
        if effect then
            effect.group = group
            effect.infoIndex = i     
          
            table.insert( group.effects, effect )
        else
            outputDebugString( "Ошибка создания эффекта!", 2 )
        end
    end

    return setmetatable( group, ParticleGroupMT )
end

function ParticleGroup:play()
    if not self.playing and not self.isGarbage then
        self.playing = true
        self.elapsedTime = 0
        self.deferredStop = false
        self.forced = true
    end
end

function ParticleGroup:stop( deferred )
    if self.playing and not self.isGarbage then
        if deferred then
            for _, effect in ipairs( self.effects ) do
                effect:stop( true )
            end

            self.deferredStop = true
        else
            self.playing = false

            for _, effect in ipairs( self.effects ) do
                effect:stop( false )
            end

            -- Помечаем для удаления в следующей итерации
            self.isGarbage = true
        end
    end
end

function ParticleGroup:setVisible( visible )
    self.visible = visible

    for _, effect in ipairs( self.effects ) do
        effect:setVisible( visible )
    end
end

function ParticleGroup:render( dt )
    local effects = self.effects

    --[[
        Этап предотрисовки требует много процессорного времени.
        Поэтому если игрок находится достаточно далеко от группы - мы можем пропустить ряд кадров
    ]]
    local passing = self.framesCounter >= self.framesPerPass
    if passing then
        self.framesCounter = 0
    else
        self.framesCounter = self.framesCounter + 1
    end

    --[[
        Чтобы частичка заспавнилась на старте эффекта мы должны
        форсировать первый вызов preRender
    ]]
    local forced = self.forced

    for _, effect in ipairs( effects ) do
        if passing or forced or effects.defferedStop then
            effect:preRender( dt )
        end

        -- Этап отрисовки обязательно происходит каждый кадр
        effect:render( dt )
    end  
    
    -- Сбрасываем флаг форсирования
    self.forced = false
end

function ParticleGroup:update( dt )
    if not self.playing then
        return
    end   

    local effects = self.effects
    local position = self.matrix:getPosition()
    local distSqr = math.max( ( position - getCamera().position ):getSquaredLength() - 36, 0 )
    local distFactor = math.min( distSqr / 3600, 1 )
    self.framesPerPass = math.interpolate( 0, 30, distFactor*distFactor*distFactor )
 
    --[[
        Обновляем группу
    ]]
    local def = self.def

    for i, effect in ipairs( effects ) do
        if effect.infoIndex then
            local effectInfo = def.children[ effect.infoIndex ]

            if effect.playing then
                -- Остановка эффекта на определенной временной отметке
                if self.elapsedTime <= effectInfo.time1 and self.elapsedTime + dt >= effectInfo.time1 then
                    effect:stop( effectInfo.deferredStop )
                end
            else
                -- Запуск эффекта на определенной временной отметке
                if self.elapsedTime <= effectInfo.time0 and self.elapsedTime + dt >= effectInfo.time0 and not self.deferredStop then
                    effect:play()
                end
            end
        end
    end

    -- Если нет отложенной остановки и временной лимит преодолен
    if not self.deferredStop and def.timeLimit > 0 then
        if self.elapsedTime >= def.timeLimit then
           self:stop( true )
        end
    end

    self.elapsedTime = self.elapsedTime + dt

    -- Если активна отложенная остановка
    if self.deferredStop then
        local hasPlayingEffects = false
        
        for _, effect in ipairs( effects ) do
            if effect.playing then
                hasPlayingEffects = true
                break
            end
        end

        if not hasPlayingEffects then
            self:stop( false )
        end
    end

    --[[
        Обновляем эффекты группы
    ]]
    for i = #effects, 1, -1 do
        local effect = effects[ i ]
        if effect.isGarbage then
            table.remove( effects, i )
            break
        end
    end

    for _, effect in ipairs( effects ) do				
        effect:update( dt )
    end
end

function ParticleGroup:onStreamedIn()
    self:setVisible( true )
end

function ParticleGroup:onStreamedOut()
    self:setVisible( false )
end

function ParticleGroup:onParticleBirth( effect, position, velocity )
    local def = self.def
    local effectIndex = effect.infoIndex    
    local effectInfo = def.children[ effectIndex ]
    if not effectInfo then
        return
    end    

    -- Если есть описание эффекта, который должен создаваться на новой частице
    if effectInfo.onBirthChild and effectInfo.onBirthChild.timeLimit > 0 then
        local effect = ParticleEffect_create( effectInfo.onBirthChild )
        effect:setVisible( self.visible )
        effect.matrix = Matrix( position )
        effect.group = self
        
        effect:play()

        table.insert( self.effects, effect )
    end

    -- Если есть описание эффекта, который должен создаваться и проигрываться пока частица жива
    if effectInfo.onPlayChild then
        local effect = ParticleEffect_create( effectInfo.onPlayChild )
        effect:setVisible( self.visible )
        effect.matrix = Matrix( position )
        effect.group = self

        effect:play()

        table.insert( self.effects, effect )

        self.onPlayEffects[ effectIndex ] = effect
    end
end

function ParticleGroup:onParticleDead( effect, position, velocity )
    local def = self.def
    local effectIndex = effect.infoIndex
    local effectInfo = def.children[ effectIndex ]
    if not effectInfo then
        return
    end

    -- Если есть описание эффекта, который должен создаваться при удалении частицы
    if effectInfo.onDeadChild and effectInfo.onDeadChild.timeLimit > 0 then
        local effect = ParticleEffect_create( effectInfo.onDeadChild )
        effect:setVisible( self.visible )
        effect.matrix = Matrix( position )
        effect.group = self

        effect:play()

        table.insert( self.effects, effect )
    end

    -- Удаляем зависимый от частицы эффект
    local effect = self.onPlayEffects[ effectIndex ]
    if effect then
        effect:stop( false )
    end
end
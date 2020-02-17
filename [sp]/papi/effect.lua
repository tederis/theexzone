local rad2Deg = 180 / math.pi

--[[
	ParticleDef
]]
ParticleDef = {}

local function _getTimeLimit( xml )
	local child = xmlFindChild( xml, "timeLimit", 0 )
	if child then
		return xmlNodeGetNumber( child, "value" )
	end

	return 0
end

local function _getSpriteName( xml )
	local child = xmlFindChild( xml, "sprite", 0 )
	if child then
		return xmlNodeGetAttribute( child, "material" )
	end

	return false
end

local function _getFrame( xml )
	local child = xmlFindChild( xml, "frame", 0 )
	if child then
		local texSize = xmlNodeGetVector2( child, "size", Vector2( 1, 1 ) )

		local frame = {
			texSize = { w = texSize:getX(), h = texSize:getY() },
			dim = xmlNodeGetNumber( child, "dimension", 0 ),
			count = xmlNodeGetNumber( child, "count", 0 ),
			randomInit = xmlNodeGetBool( child, "randomInit", false )
		}

		child = xmlFindChild( xml, "animated", 0 )
		if child then
			frame.randomPlayback = xmlNodeGetBool( child, "randomPlayback", false )
			frame.speed = xmlNodeGetNumber( child, "speed", 0 )
			frame.animated = true
		end

		return frame
	end

	return false
end

local function _getAlign( xml )
	local child = xmlFindChild( xml, "align", 0 )
	if child then
		local align = {
			faceAlign = xmlNodeGetBool( child, "faceAlign" ),
			worldAlign = xmlNodeGetBool( child, "worldAlign" )
		}

		local defaultRot = xmlNodeGetVector3( child, "defaultRotation" )
		if defaultRot then
			local mat = Matrix( Vector3( 0, 0, 0 ), Vector3( -defaultRot:getX() * rad2Deg, -defaultRot:getZ() * rad2Deg, -defaultRot:getY() * rad2Deg ) )
			align.worldRotate = mat:getForward()			
		end

		return align
	end

	return false
end

local function _getVelocityScale( xml )
	local child = xmlFindChild( xml, "velocityScale", 0 )
	if child then
		return xmlNodeGetVector2( child, "value", Vector2( 0, 0 ) )
	end

	return Vector2( 0, 0 )
end

local function _getCollision( xml )
	local child = xmlFindChild( xml, "collision", 0 )
	if child then
		local collision = {
			collideWithDynamic = xmlNodeGetBool( child, "collideWithDynamic" ),
			destroyOnContact = xmlNodeGetBool( child, "destroyOnContact" ),
			friction = xmlNodeGetNumber( child, "friction" ),
			resilence = xmlNodeGetNumber( child, "resilience" ),
			cutoff = xmlNodeGetNumber( child, "cutoff" )
		}

		return collision
	end

	return false
end

local function _getActions( xml )
	local child = xmlFindChild( xml, "actions", 0 )
	if not child then
		return {}
	end

	local actions = {}
	for _, actionChild in ipairs( xmlNodeGetChildren( child ) ) do
		if xmlNodeGetName( actionChild ) == "action" then
			local actionType = xmlNodeGetAttribute( actionChild, "type" )

			-- Проверим существует ли такой тип
			if PActionEnum[ actionType ] ~= nil and _G[ "PA" .. actionType ] ~= nil then
				local action = _G[ "PA" .. actionType ]:new( )
				if action then					
					action:load( actionChild )

					action.type = PActionEnum[ actionType ]
					action.enabled = xmlNodeGetBool( actionChild, "enabled", true )

					table.insert( actions, action )
				else
					outputDebugString( "При попытке создать экземпляр действия произошла ошибка!", 2 )
				end
			else
				outputDebugString( "Типа действия " .. tostring( actionType ) .. " не существует!", 2 )
			end
		end
	end

	return actions
end

function ParticleDef.load( xml )
	local info = {
		maxParticles = xmlNodeGetNumber( xml, "maxParticles" ) or 0,
		timeLimit = _getTimeLimit( xml ),		
		frame =  _getFrame( xml ),
		align = _getAlign( xml ),
		velocityScale = _getVelocityScale( xml ),
		collision = _getCollision( xml ),
		actions = _getActions( xml )
	}	

	local spriteName = _getSpriteName( xml )
	if spriteName then
		local xml = xmlLoadFile( spriteName, true )
		if xml then
			info.material = Material.load( xml )
			xmlUnloadFile( xml )
		else
			outputDebugString( "Инвалидный файл описания материала " .. tostring( spriteName ) )
		end
	end

	return info
end

function ParticleDef.CalcFrameRect( def, frameIndex )	
	local frameInfo = def.frame	

	local minu, minv = 0, 0
	local maxu, maxv = 1, 1

	if frameInfo then
		local texSize = frameInfo.texSize

		minu = ( frameIndex % frameInfo.dim )*texSize.w
		minv = math.floor( frameIndex / frameInfo.dim )*texSize.h
		maxu = minu + texSize.w
		maxv = minv + texSize.h
	end

	return minu, minv, maxu, maxv
end

--[[
	ParticleEffect
]]
ParticleEffect = {

}
ParticleEffectMT = {
	__index = ParticleEffect
}

function ParticleEffect_create( def )
	local effect = {
		def = def,
		playing = false,
		visible = true,
		emitting = false,
		elapsedTime = 0,
		deferredStop = false,
		parent = nil,
		matrix = Matrix( Vector3( 0, 0, 0 ) ),
		particles = {},
		enabledParticleNum = 0,
		lastAction = 0,

		memDT = 0
	}

	-- Предварительно создаем все частицы
	for i = 1, def.maxParticles do
		local particle = {
			pos = Vector3( 0, 0, 0 ),
			size = Vector3( 0, 0, 0 ),
			rot = Vector3( 0, 0, 0 ),
			vel = Vector3( 0, 0, 0 ),
			color = Vector3( 0, 0, 0 ),
			alpha = 0,
			age = 0,
			frame = 0,
			ccw = false,
			enabled = false
		}

		effect.particles[ i ] = particle
	end

	return setmetatable( effect, ParticleEffectMT )
end

local FORWARD_VECTOR = Vector3( 1, 0, 0 )
local RIGHT_VECTOR = Vector3( 1, 0, 0 )
local UP_VECTOR = Vector3( 0, 0, 1 )
local ZERO_VECTOR = Vector3( 0, 0, 0 )

function ParticleEffect:play()
	if not self.playing and not self.isGarbage then
		self.playing = true
		self.emitting = true
		self.elapsedTime = 0
		self.deferredStop = false
	end
end

function ParticleEffect:stop( deferred )
	if self.playing and not self.isGarbage then
		if deferred then
			self.deferredStop = true
			self.emitting = false
		else
			self.playing = false

			-- Помечаем для удаления в следующей итерации
			self.isGarbage = true
		end
	end
end

-- Обновление на частоте в половину от FPS
function ParticleEffect:update( dt )
	local def = self.def

	if self.playing then
		self.elapsedTime = self.elapsedTime + dt

		if not self.deferredStop and def.timeLimit > 0  then			
			if self.elapsedTime > def.timeLimit then
				self:stop( true )			
			end
		end

		if self.deferredStop and self.enabledParticleNum < 1 then
			self:stop( false )	
		end
	end
end

function ParticleEffect:preRender( dt )
	local def = self.def
	local actions = def.actions
	local particles = self.particles
	local frameInfo = def.frame
	local emitting = self.emitting

	if self.playing then
		-- Обновляем actions
		for i = 1, #actions do
			local action = actions[ i ]

			if action.enabled and ( action.type ~= PActionEnum.Source or emitting ) then
				action:execute( self, dt )
			end
		end

		-- Применяем анимацию
		if frameInfo and frameInfo.animated then
			local speedFac = frameInfo.speed * dt
			local count = frameInfo.count

			for i = 1, #particles do
				local particle = particles[ i ]

				if particle.enabled then
					local f = particle.frame + ( particle.ccw and -1 or 1 )*speedFac
					if f >= count then
						f = f - count
					end
					if f < 0 then
						f = f + count
					end
					particle.frame = f				
				end
			end
		end
	end
end

function ParticleEffect:render()
	if not self.playing or not self.visible then
		return
	end

	local def = self.def	
	local align = def.align
	local material = def.material
	local particles = self.particles	
	local mat = self.matrix
	if self.parent then
		mat = mat * self.parent.matrix
	end
	if self.group then
		mat = mat * self.group.matrix
	end
	local matPos = mat:getPosition()

	--[[
		Отсекаем заднюю полуплоскость
	]]
	if g_ClippingPlane:getDistance( matPos ) < 0 then
		ParticleStatistics:addClipped()
		return
	end

	--[[
		Отсекаем невидимые на экране частицы
	]]
	local ok = getScreenFromWorldPosition( matPos ) ~= false
	if not ok then
		return
	end

	local _tocolor = tocolor
	local _drawLineSection = dxDrawMaterialSectionLine3D
	
	local camPos = Camera.position

	local transformMat = Matrix()		
	local rotMat = Matrix( ZERO_VECTOR )
	local rotVec = Vector3( 0, 0, 0 ) 	
	local halfRightVec = Vector3( 0, 0, 0 )	

	-- Рисуем
	for i = 1, #particles do
		local particle = particles[ i ]

		if particle.enabled then
			local speed = particle.vel:getLength()			
			local position = mat:transformPosition( particle.pos )
			local rotation = particle.rot
			local size = particle.size + speed*def.velocityScale
			local clr = particle.color
			local color = _tocolor(				
				clr.r, clr.g, clr.b, clr.a
			)
			local minu, minv, maxu, maxv = ParticleDef.CalcFrameRect( def, math.floor( particle.frame ) )
			local usize = maxu - minu
			local vsize = maxv - minv

			local direction
			local upside = false
			if align then
				if speed < 0.00001 and align.worldAlign then
					direction = align.worldRotate
				elseif speed >= 0.00001 and align.faceAlign then
					direction = particle.vel / speed 
				else
					if speed >= 0.00001 then
						direction = particle.vel / speed
					else
						direction = align.worldRotate
					end
					
					upside = true
				end
			else
				-- Частица смотрит в камеру
				direction = camPos - position
				direction:normalize()
			end
			
			if upside then
				local halfDir = direction * ( size:getY() / 2 )
				local bottom = position - halfDir
				local top = position + halfDir
				_drawLineSection( top, bottom, minu * material.width, minv * material.height, usize * material.width, vsize * material.height, material.shader, size:getX(), color )
			else			
				local basis = RIGHT_VECTOR
				if math.abs( direction:dot( basis ) ) > 0.99 then
					basis = UP_VECTOR
				end
				local upVector = direction:cross( basis )
				upVector:normalize()
				local rightVector = direction:cross( upVector )
				rightVector:normalize()

				transformMat:setPosition( position )
				transformMat:setForward( direction )
				transformMat:setUp( upVector )
				transformMat:setRight( rightVector )

				rotVec:setY( math.deg( rotation ) )
				rotMat:setRotation( rotVec )

				local localMat = rotMat * transformMat

				halfRightVec:setX( size:getX() / 2 )
				local left = localMat:transformPosition( -halfRightVec )
				local right = localMat:transformPosition( halfRightVec )

				_drawLineSection( left, right, minu * material.width, minv * material.height, usize * material.width, vsize * material.height, material.shader, size:getY(), color, position + direction )
			end
		end
	end
end

function ParticleEffect:add( pos, size, rot, vel, color, age )
	local def = self.def
	local frameInfo = def.frame
	local particles = self.particles

	if self.enabledParticleNum == #self.particles then
		outputDebugString( "Превышен лимит частиц" )
		return 
	end

	-- Ищем свободную частицу
	for i = 1, #particles do
		local particle = particles[ i ]

		if not particle.enabled then
			particle.pos = pos
			particle.size = size			
			particle.rot = rot
			particle.vel = vel
			particle.color = color
			particle.age = age
			particle.frame = 0
			particle.ccw = false
			particle.enabled = true

			self.enabledParticleNum = self.enabledParticleNum + 1

			if frameInfo then
				if frameInfo.randomInit then
					particle.frame = math.random( 0, frameInfo.count - 1 )
				end
				if frameInfo.animated and frameInfo.randomPlayback and math.random() > 0.5 then
					particle.ccw = true
				end
			end

			-- Отправляем событие группе
			if self.group then
				self.group:onParticleBirth( self, pos, vel )
			end

			break
		end
	end
end

function ParticleEffect:remove( i )
	local particle = self.particles[ i ]
	if particle and particle.enabled then
		particle.enabled = false
		self.enabledParticleNum = self.enabledParticleNum - 1

		-- Отправляем событие группе
		if self.group then
			self.group:onParticleDead( self, particle.pos, particle.vel )
		end
	end
end

function ParticleEffect:setVisible( visible )
	self.visible = visible
end
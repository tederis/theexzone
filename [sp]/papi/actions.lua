PActionEnum = {
	Avoid = 1,
	Bounce = 2,
	CopyVertexB = 3,
	Damping = 4,
	Explosion = 5,
	Follow = 6,
	Gravitate = 7,
	Gravity = 8,
	Jet = 9,
	KillOld = 10,
	MatchVelocity = 11,
	Move = 12,
	OrbitLine = 13,
	OrbitPoint = 14,
	RandomAccel = 15,
	RandomDisplace = 16,
	RandomVelocity = 17,
	Restore = 18,
	Scatter = 19,
	Sink = 20,
	SinkVelocity = 21,
	Source = 22,
	SpeedLimit = 23,
	TargetColor = 24,
	TargetRotate = 25,
	TargetSize = 26,
	TargetVelocity = 27,
	Turbulence = 28,
	Vortex = 29
}

domainTypes = {
	Point = 1,
	Line = 2,		
	Triangle = 3,
	Plane = 4,	
	Box = 5,
	Sphere = 6,
	Cylinder = 7,
	Cone = 8,
	Blob = 9,
	Disc = 10,	
	Rectangle = 11
}

local FORWARD_VECTOR = Vector3( 1, 0, 0 )
local RIGHT_VECTOR = Vector3( 1, 0, 0 )
local UP_VECTOR = Vector3( 0, 0, 1 )
local ZERO_VECTOR = Vector3( 0, 0, 0 )

--[[
	PAPI::PATargetRotate
]]
PATargetRotate = {
	new = function ( self )
		local targetRotate = {
			scale = nil, -- float
			rot = nil, -- float3
		}
		
		return setmetatable ( targetRotate, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local scale = self.scale * dt		
		local absRot = math.abs( self.rot )
		local particles = effect.particles
		
		for i = 1, #particles do
			local particle = particles [ i ]

			if particle.enabled then
				local sign = particle.rot > 0 and scale or -scale
				local diff = ( absRot - math.abs( particle.rot ) ) * sign				
				particle.rot = particle.rot + diff
			end
		end
	end,
	load = function ( self, xml )
		local rot = xmlNodeGetVector3 ( xml, "rotation" )
		if rot then
			self.rot = rot:getX()
		else
			self.rot = 0
		end

		self.scale = xmlNodeGetNumber ( xml, "scale", 1 )
	end
}

--[[
	PAPI::PATargetSize
]]
PATargetSize = {
	new = function ( self )
		local targetSize = {
			scale = nil, -- float3
			size = nil, -- float3
		}
		
		return setmetatable ( targetSize, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local scale = self.scale * dt
		local particles = effect.particles
		local targetSize = self.size
		
		for i = 1, #particles do
			local particle = particles[ i ]

			if particle.enabled then				
				local size = targetSize - particle.size
				
				particle.size = particle.size + ( size * scale )
			end
		end
	end,
	load = function ( self, xml )
		self.size = xmlNodeGetVector2 ( xml, "size", Vector2( 1, 1 ) )
		self.scale = xmlNodeGetVector2 ( xml, "scale", Vector2( 1, 1 ) )
	end
}

--[[
	PAPI::PATargetVelocity
]]
PATargetVelocity = {
	new = function ( self )
		local targetVel = {
			scale = nil, -- float
			velocity = nil, -- float3
			flagAllowRotate = nil, -- bool
		}
		
		return setmetatable ( targetVel, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local scale = self.scale * dt
		local particles = effect.particles
		local targetVelocity = self.velocity
		
		for i = 1, #particles do
			local particle = particles [ i ]

			if particle.enabled then
				local vel = targetVelocity - particle.vel
				
				particle.vel = particle.vel + ( vel * scale )
			end
		end
	end,
	load = function ( self, xml )
		self.velocity = xmlNodeGetVector3 ( xml, "velocity", Vector3( 0, 0, 0 ) )
		self.scale = xmlNodeGetNumber ( xml, "scale", 1 )
	end
}

--[[
	PAPI::PATargetColor
]]
PATargetColor = {
	new = function ( self )
		local targetColor = {
			color = nil, -- domain
			alpha = nil, -- float
			scale = nil, -- float
		}
		
		return setmetatable ( targetColor, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local dta = dt * self.scale
		local dstColor = self.color
		local particles = effect.particles
	
		for i = 1, #particles do
			local particle = particles [ i ]
			if particle.enabled then			
				--if particle.age < self.timeFrom or particle.age > self.timeTo then

				--else
					local color = particle.color
					color.r = color.r + ( dstColor.r - color.r ) * dta
					color.g = color.g + ( dstColor.g - color.g ) * dta
					color.b = color.b + ( dstColor.b - color.b ) * dta
					color.a = color.a + ( dstColor.a - color.a ) * dta

					--particle.color = particle.color + ( self.color - particle.color ) * dta
					--particle.alpha = particle.alpha + ( self.alpha - particle.alpha ) * dta
				--end
			end		
		end
	end,
	load = function ( self, xml )
		local color = xmlNodeGetVector3 ( xml, "color", Vector3( 0, 0, 0 ), true )
		local alpha = xmlNodeGetNumber ( xml, "alpha", 0 )
		self.color = { r = color:getX() * 255, g = color:getY() * 255, b = color:getZ() * 255, a = alpha * 255 }
		self.scale = xmlNodeGetNumber ( xml, "scale", 1 )
		self.timeFrom = xmlNodeGetNumber ( xml, "timeFrom", 0 )
		self.timeTo = xmlNodeGetNumber ( xml, "timeTo", 0 )
	end
}

--[[
	PAPI::PARandomAccel
]]
PARandomAccel = {
	new = function ( self )
		local randAccel = {
			
		}
		
		return setmetatable ( randAccel, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local gen_acc = self.gen_acc
		local particles = effect.particles

		for i = 1, #particles do
			local particle = particles[ i ]

			if particle.enabled then				
				local acceleration = gen_acc:generate( )
			
				particle.vel = particle.vel + ( acceleration * dt )
			end
		end
	end,
	load = function ( self, xml )
		local node = xmlFindChild( xml, "domain", 0 )
		if node then
			self.gen_acc = pDomain:new( node )
		else
			outputDebugString( "Невозможно найти нод domain", 2 )
		end
	end
}

--[[
	PAPI::PAGravity
]]
PAGravity = {
	new = function ( self )
		local gravity = {
			direction = nil, -- float3
			flagAllowRotate = nil, -- bool
		}
		
		return setmetatable ( gravity, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local dir = self.direction * dt
		local particles = effect.particles
	
		for i = 1, #particles do
			local particle =particles [ i ]

			if particle.enabled then				
				particle.vel = particle.vel + dir
			end
		end
	end,
	load = function ( self, xml )
		self.direction = xmlNodeGetVector3( xml, "direction", Vector3( 0, 0, 1 ) )
	end
}

--[[
	PAPI::PAScatter
]]
PAScatter = {
	new = function ( self )
		local scatter = {
			magnitude = nil, -- float
			maxRadius = nil, -- float
			center = nil, -- float3
			epsilon = nil, -- float
			flagAllowRotate = nil, -- bool
		}
		
		return setmetatable ( scatter, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local mag = self.magnitude * dt
		local maxRadiusSq = self.maxRadius * self.maxRadius
		local particles = effect.particles
		local center = self.center
		local epsilon = self.epsilon

		local _sqrt = math.sqrt

		if maxRadiusSq < 1.0e16 then
			for i = 1, #particles do
				local particle = particles [ i ]

				if particle.enabled then					
					local dir = particle.pos - center
					local rSqr = dir:getSquaredLength()

					if rSqr < maxRadiusSq then
						local acc = dir / _sqrt( rSqr )

						particle.vel = particle.vel + acc*( mag / ( rSqr + epsilon ) )
					end
				end
			end
		else
			for i = 1, #particles do
				local particle = particles [ i ]

				if particle.enabled then
					local dir = particle.pos - center
					local rSqr = dir:getSquaredLength()
					local acc = dir / _sqrt( rSqr )

					particle.vel = particle.vel + acc*( mag / ( rSqr + epsilon ) )
				end
			end
		end
	end,
	load = function ( self, xml )
		self.center = xmlNodeGetVector3( xml, "center", Vector3( 0, 0, 0 ) )
		self.magnitude = xmlNodeGetNumber( xml, "magnitude", 1 )
		self.epsilon = xmlNodeGetNumber ( xml, "epsilon", 0 )
		self.maxRadius = xmlNodeGetNumber( xml, "maxRadius", 0 )
	end
}

--[[
	PAPI::PASink
]]
PASink = {
	new = function ( self )
		local sink = {
			
		}
		
		return setmetatable ( sink, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local particles = effect.particles
		local position = self.position
		local killInside = self.killInside
		local i = #particles

		while i > 0 do
			local particle = particles[ i ]

			if particle.enabled then
				if not ( position:within( particle.pos ) ~= killInside ) then					
					effect:remove( i )
				end
			end				
			
			i = i - 1
		end
	end,
	load = function ( self, xml )
		self.killInside = xmlNodeGetBool ( xml, "killInside", false )

		local node = xmlFindChild( xml, "domain", 0 )
		if node then
			self.position = pDomain:new( node )
		else
			outputDebugString( "Невозможно найти нод domain", 2 )
		end
	end
}

--[[
	PAPI::PASpeedLimit
]]
PASpeedLimit = {
	new = function ( self )
		local speedLimit = {
			
		}
		
		return setmetatable ( speedLimit, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local min_sqr = self.minSpeed * self.minSpeed
		local max_sqr = self.maxSpeed * self.maxSpeed
		local minSpeed = self.minSpeed
		local maxSpeed = self.maxSpeed
		local particles = effect.particles

		local _sqrt = math.sqrt
		local _abs = math.abs
	
		for i = 1, #particles do
			local particle = particles [ i ]

			if particle.enabled then
				local spd = particle.vel:getSquaredLength()

				if spd < min_sqr and _abs( spd ) > 0.0001 then
					particle.vel = particle.vel * ( minSpeed / _sqrt( spd ) )
				elseif spd > max_sqr then
					particle.vel = particle.vel * ( maxSpeed / _sqrt( spd ) )
				end
			end
		end
	end,
	load = function ( self, xml )
		self.minSpeed = xmlNodeGetNumber( xml, "minSpeed", 0 )
		self.maxSpeed = xmlNodeGetNumber( xml, "maxSpeed", 0 )
	end
}

--[[
	PAPI::PADamping
]]
PADamping = {
	new = function ( self )
		local damping = {
			damping = nil, -- float3
			vlowSqr = nil, -- float
			vhighSqr = nil, -- float
		}
		
		return setmetatable ( damping, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local scale = Vector3( 1, 1, 1 ) - ( Vector3( 1, 1, 1 ) - self.damping ) * dt
		local lowSqrt = self.vlowSqr
		local particles = effect.particles
		
		for i = 1, #particles do
			local particle = particles [ i ]

			if particle.enabled then
				local vSqr = particle.vel:getSquaredLength()

				if vSqr >= lowSqrt and vSqr <= vhighSqr then
					particle.vel = particle.vel*scale
				end
			end
		end
	end,
	load = function ( self, xml )
		self.damping = xmlNodeGetVector3( xml, "damping", Vector3( 0, 0, 0 ) )
		self.vlowSqr = xmlNodeGetNumber ( xml, "vLow", 0 )
		self.vhighSqr = xmlNodeGetNumber ( xml, "vHigh", 0 )
	end
}

--[[
	PAPI::PAKillOld
]]
PAKillOld = {
	new = function ( self )
		local killOld = {
			ageLimit = nil, -- float
			killLessThan = nil, -- bool
		}
		
		return setmetatable ( killOld, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local i = #effect.particles
		local particles = effect.particles
		local killLessThan = self.killLessThan
		local ageLimit = self.ageLimit

		while i > 0 do
			local particle = particles[ i ]

			if particle.enabled then
				if not ( ( particle.age < ageLimit ) ~= killLessThan ) then
					effect:remove( i )
				end
			end		

			i = i - 1
		end
	end,
	load = function ( self, xml )
		self.ageLimit = xmlNodeGetNumber( xml, "ageLimit", 0 )
		self.killLessThan = xmlNodeGetBool( xml, "killLessThan", false )
	end
}

--[[
	PAPI::PAOrbitPoint
]]
PAOrbitPoint = {
	new = function ( self )
		local orbitPoint = {
			
		}
		
		return setmetatable ( orbitPoint, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local mag = self.magnitude * dt
		local epsilon = self.epsilon
		local center = self.center
		local maxRadiusSq = self.maxRadius * self.maxRadius
		local particles = effect.particles

		local _sqrt = math.sqrt

		if maxRadiusSq < 1.0e16 then
			for i = 1, #particles do
				local particle = particles[ i ]

				if particle.enabled then					
					local dir = center - particle.pos
					local rSqr = dir:getSquaredLength()
					local rLen = _sqrt( rSqr )

					if rSqr < maxRadiusSq then
						particle.vel = particle.vel + dir * ( mag / ( rLen + ( rSqr + epsilon ) ) )
					end
				end
			end
		else
			for i = 1, #particles do
				local particle = particles[ i ]

				if particle.enabled then					
					local dir = center - particle.pos
					local rSqr = dir:getSquaredLength()
					local rLen = _sqrt( rSqr )
					local acc = dir / rLen

					particle.vel = particle.vel + dir * ( mag / ( rLen + ( rSqr + epsilon ) ) )
				end
			end
		end
	end,
	load = function ( self, xml )
		self.center = xmlNodeGetVector3( xml, "center", Vector3( 0, 0, 0 ) )
		self.magnitude = xmlNodeGetNumber( xml, "magnitude", 0 )
		self.epsilon = xmlNodeGetNumber( xml, "epsilon", 0 )
		self.maxRadius = xmlNodeGetNumber( xml, "maxRadius", 0 )
	end
}

--[[
	PAPI::PATurbulence
]]
PATurbulence = {
	new = function ( self )
		local turbulence = {
			frequency = nil, -- float
			octaves = nil, -- float
			magnitude = nil, -- float
			epsilon = nil, -- float
			offset = nil, -- float3
			
			age = 0
		}
		
		return setmetatable ( turbulence, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		self.age = dt * self.age

		local particles = effect.particles

		local _fractalsum3 = fractalsum3
		local _sqrt = math.sqrt
	
		for i = 1, #particles do
			local particle = particles[ i ]

			if particle.enabled then
				local pV = {
					x = self.age*self.offset.x + particle.pos.x,
					y = self.age*self.offset.y + particle.pos.y,
					z = self.age*self.offset.z + particle.pos.z
				}
				local vX = {
					x = pV.x + self.epsilon,
					y = pV.y,
					z = pV.z
				}
				local vY = {
					x = pV.x,
					y = pV.y + self.epsilon,
					z = pV.z
				}
				local vZ = {
					x = pV.x,
					y = pV.y,
					z = pV.z + self.epsilon
				}
				
				local dta = _fractalsum3( pV.x, pV.y, pV.z, self.frequency, self.octaves )
				local v14 = ( _fractalsum3( vX.x, vX.y, vX.z, self.frequency, self.octaves ) - dta ) * self.magnitude
				local v17 = ( _fractalsum3( vY.x, vY.y, vY.z, self.frequency, self.octaves ) - dta ) * self.magnitude
				local v20 = ( _fractalsum3( vZ.x, vZ.y, vZ.z, self.frequency, self.octaves ) - dta ) * self.magnitude
				
				local v21 = particle.vel.x * particle.vel.x + particle.vel.y * particle.vel.y + particle.vel.z * particle.vel.z
				
				particle.vel.x = v14 + particle.vel.x
				particle.vel.y = v17 + particle.vel.y
				particle.vel.z = v20 + particle.vel.z
				
				local v22 = particle.vel.x * particle.vel.x + particle.vel.y * particle.vel.y + particle.vel.z * particle.vel.z
				local sqr =_sqrt( v21 ) / _sqrt( v22 )
				
				particle.vel = sqr + particle.vel
			end
		end
	end,
	load = function ( self, xml )
		self.frequency = xmlNodeGetNumber ( xml, "frequency" )
		self.offset = xmlNodeGetVector3 ( xml, "offset" )
		self.octaves = xmlNodeGetNumber ( xml, "octaves" )		
		self.magnitude = xmlNodeGetNumber ( xml, "magnitude" )
		self.epsilon = xmlNodeGetNumber ( xml, "epsilon" )		
	end
}

--[[
	PAPI::PAMove
]]
PAMove = {
	new = function ( self )
		local move = {
			
		}
		
		return setmetatable ( move, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local particles = effect.particles

		for i = 1, #particles do
			local particle = particles [ i ]

			if particle.enabled then
				particle.age = dt + particle.age				
				particle.pos = particle.pos + ( particle.vel * dt )
			end
		end
	end,
	load = function ( self, xml )
	end
}

--[[
	PAPI::PAVortex
]]
PAVortex = {
	new = function ( self )
		local source = {
			center = nil,
			axis = nil,
			magnitude = nil,
			epsilon = nil,
			maxRadius = nil,
		}
		
		return setmetatable ( source, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		local magdt = self.magnitude * dt
		local maxRadiusSq = self.maxRadius*self.maxRadius
		local particles = effect.particles
		local center = self.center
		local axis = self.axis
		local epsilon = self.epsilon

		local _sqrt = math.sqrt
		local _sin = math.sin
		local _cos = math.cos

		if maxRadiusSq < 1.0e16 then
			for i = 1, #particles do
				local particle = particles [ i ]
				if particle.enabled then
					local offset = particle.pos - center
					local rSqr = offset:getSquaredLength()

					if rSqr <= maxRadiusSq then 
						local r = _sqrt( rSqr )
						local offnorm = offset / r

						local axisProj = offnorm:dot( axis )

						local w = axis * axisProj
						local u = offnorm - w
						local v = axis:cross( u )

						local theta = magdt / ( rSqr + epsilon )
						local s = _sin( theta )
						local c = _cos( theta )

						offset = ( u * c + v *s + w ) * r

						particle.pos = offset + self.center
					end
				end
			end
		else
			for i = 1, #particles do
				local particle = particles [ i ]
				if particle.enabled then
					local offset = particle.pos - center
					local rSqr = offset:getSquaredLength()
					local r = _sqrt( rSqr )
					
					local offnorm = offset / r

					local axisProj = offnorm:dot( axis )

					local w = axis * axisProj
					local u = offnorm - w
					local v = axis:cross( u )

					local theta = magdt / ( rSqr + epsilon )
					local s = _sin( theta )
					local c = _cos( theta )

					offset = ( u * c + v *s + w ) * r

					particle.pos = offset + center
				end
			end
		end
	end,
	load = function ( self, xml )				
		self.center = xmlNodeGetVector3 ( xml, "center", Vector3( 0, 0, 0 ) )
		self.axis = xmlNodeGetVector3 ( xml, "axis", Vector3( 0, 0, 0 ) )
		self.magnitude = xmlNodeGetNumber ( xml, "magnitude", 0 )
		self.epsilon = xmlNodeGetNumber ( xml, "epsilon", 0 )
		self.maxRadius = xmlNodeGetNumber ( xml, "maxRadius", 0 )
	end
}

--[[
	PAPI::PASource
]]
PASource = {
	new = function ( self )
		local source = {
			position = nil, -- domain
			size = nil, -- domain
			rot = nil, -- domain
			velocity = nil, -- domain
			color = nil, -- domain
			age = nil, -- float
			age_sigma = nil, -- float
			alpha = nil, -- float
			particle_rate = nil, -- float
			parent_motion = nil, -- float
			flagAllowRotate = nil, -- bool
			flagSingleSize = nil, -- bool
		}
		
		return setmetatable ( source, { __index = self } )
	end,
	execute = function ( self, effect, dt )
		--if bitAnd ( self.flags, 0x40 ) > 0 then
			local rate = math.ceil ( dt * self.particle_rate )

			if math.random() < ( self.particle_rate*dt - rate ) then
				rate = rate + 1
			end

			--[[
				Мы не можем выпустить больше частиц, чем позволяем эффект.
				Редуцируем рейт если необходимо
			]]
			if effect.enabledParticleNum + rate > #effect.particles then
				rate = #effect.particles - effect.enabledParticleNum
			end

			for i = 1, rate do
				local pos = self.position:generate ( )
				
				-- Size
				local size = self.size:generate ( )
				local width = size:getX()
				local height = size:getY()
				if self.flagSingleSize then
					height = width
				end
				size = Vector2( width, height )

				-- Rot
				local rot = self.rot:generate ( ):getX()	

				local vel = self.velocity:generate ( )

				local clr = self.color:generate()
				color = { r = clr:getX() * 255, g = clr:getY() * 255, b = clr:getZ() * 255, a = self.alpha * 255 }

				local age = randomNormal( self.age, self.age_sigma )
	
				effect:add( pos, size, rot, vel, color, age )
			end
		--end
	end,
	load = function ( self, xml )
		local node = utilXmlFindDomain ( xml, "domain" )
		if node then
			self.position = pDomain:new ( node )
		else
			outputDebugString( "Ошибка чтения domain" )
		end
		
		node = utilXmlFindDomain ( xml, "velocity" )
		if node then
			self.velocity = pDomain:new ( node )
		else
			outputDebugString( "Ошибка чтения velocity" )
		end
		
		node = utilXmlFindDomain ( xml, "rotation" )
		if node then
			self.rot = pDomain:new ( node )
		else
			outputDebugString( "Ошибка чтения rotation" )
		end
		
		node = utilXmlFindDomain ( xml, "size" )
		if node then
			self.size = pDomain:new ( node, true )
		else
			outputDebugString( "Ошибка чтения size" )
		end

		node = utilXmlFindDomain ( xml, "color" )
		if node then
			self.color = pDomain:new ( node )
		else
			outputDebugString( "Ошибка чтения color" )
		end	
				
		self.alpha = xmlNodeGetNumber ( xml, "alpha", 0 )
		self.particle_rate = xmlNodeGetNumber ( xml, "rate", 0 )
		self.age = xmlNodeGetNumber ( xml, "startingAge", 0 )
		self.age_sigma = xmlNodeGetNumber ( xml, "ageSigma", 0 )
		self.parent_motion = xmlNodeGetNumber ( xml, "parentMotion", 0 )
		self.flagSingleSize = xmlNodeGetBool ( xml, "singleSize", false )
	end
}

--[[
	PAPI::pDomain
]]
local SQRT2PI = 2.506628274631000502415765284811045253006
local ONEOVERSQRT2PI = 1 / SQRT2PI
local ONE_OVER_SIGMA_EXP = 1.0 / 0.7975

local function NRand( sigma )
	if math.abs( sigma ) < 0.00001 then  
		return 0
	end

	local y = 0
	repeat	
		y = -math.log( math.random() )
	until ( math.random() > math.exp( -( y - 1.0 )*( y - 1.0 )*0.5) )

	if bitAnd( math.random( 1000 ), 0x1 ) then
		return y * sigma * ONE_OVER_SIGMA_EXP;
	else
		return -y * sigma * ONE_OVER_SIGMA_EXP;
	end
end

pDomain = {
	new = function ( self, xml, inverse )		
		if xml then
			local domain = {
				type = domainTypes [ xmlNodeGetAttribute ( xml, "type" ) ]
			}

			local error = true
			if domain.type == domainTypes.Point then
				local v1 = xmlNodeGetVector3( xml, "center", ZERO_VECTOR, inverse )
				if v1 then
					domain.p1 = v1
					error = false
				end
			elseif domain.type == domainTypes.Line then
				local v1 = xmlNodeGetVector3( xml, "point1", ZERO_VECTOR, inverse )
				local v2 = xmlNodeGetVector3( xml, "point2", ZERO_VECTOR, inverse )
				if v1 and v2 then
					domain.p1 = v1
					domain.p2 = v2 - v1
					error = false
				end
			elseif domain.type == domainTypes.Triangle then
				local p1 = xmlNodeGetVector3( xml, "vertex1", ZERO_VECTOR, inverse )
				local p2 = xmlNodeGetVector3( xml, "vertex2", ZERO_VECTOR, inverse )
				local p3 = xmlNodeGetVector3( xml, "vertex3", ZERO_VECTOR, inverse )
				if v1 and v2 and v3 then
					domain.p1 = v1

					domain.u = v2 - v1
					domain.v = v3 - v1

					domain.radius1Sqr = domain.u:getLength()
					domain.radius2Sqr = domain.v:getLength()

					local tu = domain.u / domain.radius1Sqr
					local tv = domain.v / domain.radius2Sqr

					domain.p2 = tu:cross( tv ):getNormalized()

					domain.radius1 = -v1:dot( domain.p2 )
					error = false
				end
			elseif domain.type == domainTypes.Plane then
				local v1 = xmlNodeGetVector3( xml, "origin", ZERO_VECTOR, inverse )
				local v2 = xmlNodeGetVector3( xml, "normal", ZERO_VECTOR, inverse )
				if v1 and v2 then
					domain.p1 = v1
					domain.p2 = v2:getNormalized()

					domain.radius1 = -v1:dot( domain.p2 )
					error = false
				end
			elseif domain.type == domainTypes.Box then
				local v1 = xmlNodeGetVector3( xml, "min", ZERO_VECTOR, inverse )
				local v2 = xmlNodeGetVector3( xml, "max", ZERO_VECTOR, inverse )
				if v1 and v2 then
					domain.p1 = Vector3(
						math.min( v1.x, v2.x ),
						math.min( v1.y, v2.y ),
						math.min( v1.z, v2.z )
					)
					domain.p2 = Vector3(
						math.max( v1.x, v2.x ),
						math.max( v1.y, v2.y ),
						math.max( v1.z, v2.z )
					)
					error = false
				end
			elseif domain.type == domainTypes.Sphere then
				local v1 = xmlNodeGetVector3( xml, "center", ZERO_VECTOR, inverse )
				local v2 = xmlNodeGetNumber( xml, "radiusInner" )
				local v3 = xmlNodeGetNumber( xml, "radiusOuter" )
				if v1 and v2 and v3 then
					domain.p1 = v1
					domain.radius1 = math.max( v2, v3 )
					domain.radius2 = math.min( v2, v3 )
					domain.radius1Sqr = domain.radius1*domain.radius1
					domain.radius2Sqr = domain.radius2*domain.radius2
					error = false
				end
			elseif domain.type == domainTypes.Cylinder then
				local v1 = xmlNodeGetVector3( xml, "point1", ZERO_VECTOR, inverse )
				local v2 = xmlNodeGetVector3( xml, "point2", ZERO_VECTOR, inverse )
				local v3 = xmlNodeGetNumber( xml, "radiusInner" )
				local v4 = xmlNodeGetNumber( xml, "radiusOuter" )
				if v1 and v2 and v3 and v4 then
					domain.p1 = v1
					domain.p2 = v2 - v1

					domain.radius1 = math.max( v3, v4 )
					domain.radius2 = math.min( v3, v4 )
					domain.radius1Sqr = domain.radius1*domain.radius1
								
					local n = domain.p2:getNormalized()
					local p2l2 = domain.p2:getLength()

					domain.radius2Sqr = math.abs( p2l2 ) > 0.0001 and 1 / p2l2 or 0

					local basis = Vector3( 1, 0, 0 )
					if math.abs( basis:dot( n ) ) > 0.999 then
						basis = Vector3( 0, 1, 0 )
					end

					domain.u = basis - n*basis:dot( n )
					domain.u:normalize()
					domain.v = n:cross( domain.u )
					error = false
				end
			elseif domain.type == domainTypes.Cone then
				local v1 = xmlNodeGetVector3( xml, "apex", ZERO_VECTOR, inverse )
				local v2 = xmlNodeGetVector3( xml, "endPoint", ZERO_VECTOR, inverse )
				local v3 = xmlNodeGetNumber( xml, "radiusInner" )
				local v4 = xmlNodeGetNumber( xml, "radiusOuter" )
				if v1 and v2 and v3 and v4 then
					domain.p1 = v1
					domain.p2 = v2 - v1

					domain.radius1 = math.max( v3, v4 )
					domain.radius2 = math.min( v3, v4 )
					domain.radius1Sqr = domain.radius1*domain.radius1
								
					local n = domain.p2:getNormalized()
					local p2l2 = domain.p2:getLength()

					domain.radius2Sqr = math.abs( p2l2 ) > 0.0001 and 1 / p2l2 or 0

					local basis = Vector3( 1, 0, 0 )
					if math.abs( basis:dot( n ) ) > 0.999 then
						basis = Vector3( 0, 1, 0 )
					end

					domain.u = basis - n*basis:dot( n )
					domain.u:normalize()
					domain.v = n:cross( domain.u )
					error = false
				end
			elseif domain.type == domainTypes.Blob then
				local v1 = xmlNodeGetVector3( xml, "center", ZERO_VECTOR, inverse )
				local v2 = xmlNodeGetNumber( xml, "radiusOuter" )
				if v1 and v2 then
					domain.p1 = v1
					domain.radius1 = v2

					local tmp = 1 / v2
					domain.radius2Sqr = -0.5*tmp*tmp
					domain.radius2 = ONEOVERSQRT2PI*tmp
					error = false
				end
			elseif domain.type == domainTypes.Disc then
				local v1 = xmlNodeGetVector3( xml, "center", ZERO_VECTOR, inverse )
				local v2 = xmlNodeGetVector3( xml, "normal", ZERO_VECTOR, inverse )
				local v3 = xmlNodeGetNumber( xml, "radiusInner" )
				local v4 = xmlNodeGetNumber( xml, "radiusOuter" )
				if v1 and v2 and v3 and v4 then
					domain.p1 = v1
					domain.p2 = v2:getNormalized()

					domain.radius1 = math.max( v3, v4 )
					domain.radius2 = math.min( v3, v4 )

					local basis = Vector3( 1, 0, 0 )
					if math.abs( basis:dot( domain.p2 ) ) > 0.999 then
						basis = Vector3( 0, 1, 0 )
					end

					domain.u = basis - domain.p2*basis:dot( domain.p2 )
					domain.u:normalize()
					domain.v = domain.p2:cross( domain.u )

					domain.radius1Sqr = -domain.p1:dot( domain.p2 )
					error = false
				end
			elseif domain.type == domainTypes.Rectangle then
				local v1 = xmlNodeGetVector3( xml, "origin", ZERO_VECTOR, inverse )
				local v2 = xmlNodeGetNumber( xml, "basisU" )
				local v3 = xmlNodeGetNumber( xml, "basisV" )
				if v1 and v2 and v3 then
					domain.p1 = v1
					domain.u = v2
					domain.v = v3

					domain.radius1Sqr = domain.u:getLength()
					domain.radius2Sqr = domain.v:getLength()

					local tu = domain.u / domain.radius1Sqr
					local tv = domain.v / domain.radius2Sqr

					domain.p2 = tu:cross( tv ):getNormalized()

					domain.radius1 = -domain.p1:dot( domain.p2 )	
					error = false
				end
			end	
			
			if error then
				outputDebugString( "При загрузке " .. tostring( xmlNodeGetAttribute ( xml, "type" ) )  .. " не все параметры были прочитаны" )
			else
				return setmetatable ( domain, { __index = pDomain } )
			end
		end
		
		return false
	end,	
	generate = function ( self )
		local result
		if self.type == domainTypes.Point then
			result = Vector3( self.p1 )
		elseif self.type == domainTypes.Line then
			result = self.p1 + self.p2*math.random()
		elseif self.type == domainTypes.Triangle then
			local r1 = math.random()
			local r2 = math.random()
			if r1 + r2 < 1 then
				result = self.p1 + self.u*r1 + self.v*r2
			else
				result = self.p1 + self.u*( 1 - r1 ) + v*( 1 - r2 )
			end
		elseif self.type == domainTypes.Plane then
			result = self.p1
		elseif self.type == domainTypes.Box then
			local size = self.p2 - self.p1
			result = self.p1 + size * Vector3( math.random(), math.random(), math.random() )
		elseif self.type == domainTypes.Sphere then
			local randVec = Vector3( math.random() - 0.5, math.random() - 0.5, math.random() - 0.5 )
			randVec:normalize()

			if math.abs( self.radius1 - self.radius2 ) < 0.0001 then
				result = self.p1 + randVec*self.radius1
			else
				result = self.p1 + randVec*( self.radius2 + math.random() * ( self.radius1 - self.radius2 ) )
			end
		elseif self.type == domainTypes.Cylinder or self.type == domainTypes.Cone then
			local dist = math.random()
			local theta = math.random() * math.pi * 2
			local r = self.radius2 + math.random() * ( self.radius1 - self.radius2 )

			local x = r*math.cos( theta )
			local y = r*math.sin( theta )

			if self.type == domainTypes.Cone then
				x = x * dist
				y = y * dist
			end

			result = self.p1 + self.p2*dist + self.u*x + self.v*y
		elseif self.type == domainTypes.Blob then
			result = self.p1 + Vector3( NRand( self.radius1 ), NRand( self.radius1 ), NRand( self.radius1 ) )
		elseif self.type == domainTypes.Disc then
			local theta = math.random() * math.pi * 2
			local r = self.radius2 + math.random() * ( self.radius1 - self.radius2 )

			local x = r*math.cos( theta )
			local y = r*math.sin( theta )

			result = self.p1 + self.u*x + self.v*y
		elseif self.type == domainTypes.Rectangle then
			result = self.p1 + self.u*math.random() + self.v*math.random()
		end

		return result
	end,
	within = function ( self, pos )
		if self.type == domainTypes.Point then
		elseif self.type == domainTypes.Line then		
		elseif self.type == domainTypes.Triangle then		
		elseif self.type == domainTypes.Plane then
			return pos:dot( self.p2 ) >= -self.radius1
		elseif self.type == domainTypes.Box then
			local exp1 = pos:getX() < self.p1:getX() or pos:getX() > self.p2:getX()
			local exp2 = pos:getY() < self.p1:getY() or pos:getY() > self.p2:getY()
			local exp3 = pos:getZ() < self.p1:getZ() or pos:getZ() > self.p2:getZ()

			return not (exp1 or exp2 or exp3 )
		elseif self.type == domainTypes.Sphere then
			local rvec = pos - self.p1
			local rSqr = rvec:getSquaredLength()

			return rSqr <= self.radius1Sqr and rSqr >= self.radius2Sqr
		elseif self.type == domainTypes.Cylinder or self.type == domainTypes.Cone then
			local rvec = pos - self.p1

			local dist = self.p2:dot( rvec ) * self.radius2Sqr
			if dist < 0 or dist > 1 then
				return false
			end

			local xrad = rvec - self.p2*dist
			local rSqr = xrad:getSquaredLength()

			if self.type == domainTypes.Cone then
				return rSqr <= ( dist * self.radius1 )*( dist * self.radius1 ) and rSqr >= ( dist *self.radius2 )*( dist *self.radius2 )
			else
				return rSqr <= self.radius1Sqr and rSqr >= self.radius2*self.radius2
			end
		elseif self.type == domainTypes.Blob then
			local rvec = pos - self.p1

			local Gx = math.exp( rvec:getSquaredLength() * self.radius2Sqr ) * self.radius2

			return math.random() < Gx
		elseif self.type == domainTypes.Disc then		
		elseif self.type == domainTypes.Rectangle then			
		end	

		return false
	end
}
function math.clamp ( lower, upper, value )
	return math.max ( math.min ( value, upper ), lower )
end

function math.lerp(a, b, k)
	return a * (1-k) + b * k
end

function setVector3HP ( vector, h, p )
	local ch, cp, sh, sp = math.cos ( h ), math.cos ( p ), math.sin ( h ), math.sin ( p )
	vector.x = -cp*sh
	vector.y = sp
	vector.z = cp*ch
end

function Vector4:lerp ( A, B, t )
	local x, y, z = interpolateBetween ( A.x, A.y, A.z, B.x, B.y, B.z, t, "Linear" )
	self.x = x; self.y = y; self.z = z;
	self.w = math.lerp ( A.w, B.w, t )
end

function Vector3:lerp ( A, B, t )
	local x, y, z = interpolateBetween ( A.x, A.y, A.z, B.x, B.y, B.z, t, "Linear" )
	self.x = x; self.y = y; self.z = z;
end

function Vector2:lerp ( A, B, t )
	local x, y = interpolateBetween ( A.x, A.y, 0, B.x, B.y, 0, t, "Linear" )
	self.x = x; self.y = y
end

--[[
	Utils
]]
-- Возвращает текущее игровое время в секундах
function getEnvironmentGameDayTimeSec ( timeFactor )
	return math.floor ( ( getTickCount ( ) * timeFactor ) % 86400000 / 1000 )
end
--[[
    ZoneSector
]]
ZSS_IDLE = 1
ZSS_TAKING = 2 -- Идет захват
ZSS_AWAIT = 3 -- В зоне несколько группировок
ZSS_ZERO = 4 -- В зоне никого нет

local zoneSndFoundEnemy = {
	"/alife/attack/found_enemy_1_pda.ogg",
	"/alife/attack/found_enemy_2_pda.ogg",
	"/alife/attack/found_enemy_3_pda.ogg"
}

local zoneSndZoneCaptured = {
	"/alife/attack/smart_captured_1_pda.ogg",
	"/alife/attack/smart_captured_2_pda.ogg",
	"/alife/attack/smart_captured_3_pda.ogg"
}

local stateStrs = {
    "ZSS_IDLE",
    "ZSS_TAKING",
    "ZSS_AWAIT",
    "ZSS_ZERO"
}

ZoneSector = {

}
setmetatable( ZoneSector, { __index = Zone } )

function ZoneSector:create()
	if Zone.create( self ) then
		self.takingTeam = nil
		self.team = nil
		self.sounds = {}

        return true      
	end
	
	return false
end

function ZoneSector:destroy()
    Zone.destroy( self )
end

function ZoneSector:load( zoneData )
    if not Zone.load( self, zoneData ) then
		return false
	end

	local state = zoneData[ ZA_STATE ]
	if type( state ) ~= "number" then
		return false
	end
	
	local owner = zoneData[ ZA_OWNER ]
	if owner then
		self:setOwnerTeam( owner )
	end

	local timestamp = tonumber( zoneData[ ZA_TIMESTAMP ] )
	if timestamp then
		self.occupyTimestamp = timestamp
		setElementData( self.element, "occupy_ts", timestamp, false )
	end

	self:setState( ZSS_IDLE )
	self:setState( state )

	return true
end

function ZoneSector:update( dt )
   
end

function ZoneSector:playSound( variants, prefix )
	local sounds = self.sounds
	local now = getTickCount()

	local lastPlayed = sounds[ variants ]
	if lastPlayed then
		if now <= lastPlayed.endTime then
			return
		end
	end

	local randName = variants[ math.random( 1, #variants ) ]
	local sound = playSound( "Sounds/human_01/" .. prefix .. randName )
	if sound then
		sounds[ variants ] = {
			endTime = now + getSoundLength( sound ) * 1000
		}
	end
end

function ZoneSector:onHit( element )
	
end

function ZoneSector:onLeave( element )
	
end

function ZoneSector:setState( newState )
	if newState == self.state then
		return
	end

	self.state = newState

	local team = getPlayerTeam( localPlayer )
	if newState == ZSS_TAKING and self.team == team and self.takingTeam ~= team then
		self:playSound( zoneSndFoundEnemy, getTeamName( team ) )
		--outputChatBox( "Вашу зону пытаются захватить! Требуется помощь!" )
	elseif newState == ZSS_IDLE and self.takingTeam == team and self.team == team then
		self:playSound( zoneSndZoneCaptured, getTeamName( team ) )
		--outputChatBox( "Вы успешно отбили свою зону! Так держать!" )
	end

	setElementData( self.element, "zstate", newState, false )

	outputDebugString( "New state CLIENT" .. stateStrs[ newState ] )
end

function ZoneSector:setOwnerTeam( team )
	if self.team ~= team then
		self.team = team

		if isElement( team ) then
			local typeHash = getElementData( team, "cl", false )
			local timestamp = getRealTime().timestamp

			setElementData( self.element, "zowner", typeHash, false )
			setElementData( self.element, "occupy_ts", timestamp, false )
		else
			setElementData( self.element, "zowner", false, false )
			setElementData( self.element, "occupy_ts", false, false )
		end
	end
end

function ZoneSector:onEvent( operation, arg0 )
	if operation == ZONE_STATE_CHANGE then
		self:setState( arg0 )
	elseif operation == ZONE_OWNER then
		self:setOwnerTeam( arg0 )
	elseif operation == ZONE_TAKING_TEAM then
		local typeHash = getElementData( arg0, "cl", false )

		self.takingTeam = arg0

		setElementData( self.element, "ztaker", typeHash, false )
	end
end
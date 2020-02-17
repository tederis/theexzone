--[[
	xrSession
]]
xrSession = {

}
xrSessionMT = {
	__index = xrSession
}

--[[
	xrSessionTrader
]]
xrSessionTrader = {

}
xrSessionTraderMT = {
	__index = xrSessionTrader
}
setmetatable( xrSessionTrader, xrSessionMT )

function xrSessionTrader:create( player, ped )
	local playerContId = getElementData( player, "contId", false )
	if not playerContId then
		outputDebugString( "Игрок не содержит номер контейнера", 1 )
		return false
	end

	local pedClassHash = tonumber( getElementData( ped, "cl", false ) )
	if not pedClassHash then
		outputDebugString( "Торговец не содержит хэш класса", 1 )
		return false
	end

	local pedSection = xrSettingsGetSection( pedClassHash )
	if not pedSection then
		outputDebugString( "Для торговца не было найдено секции описания", 1 )
		return false
	end

	local pedTradeSection = xrSettingsGetSection( pedSection.trade_coeffs )
	if not pedTradeSection then
		outputDebugString( "Не было найдено описание коэффициентов торговли", 1 )
		return false
	end

	local contId = exports.xritems:xrCreateContainer( "TraderContainer", true )

	local session = {
		player = player,
		playerContId = playerContId,
		ped = ped,
		pedSection = pedSection,
		pedClassHash = pedClassHash,
		pedTradeSection = pedTradeSection,
		pedContId = contId,
		lastUpdateTime = nil,
		type = EST_PLAYER_NPC
	}

	return setmetatable( session, xrSessionTraderMT )
end

function xrSessionTrader:destroy()	
	exports.xritems:xrDestroyContainer( self.pedContId )
end

function xrSessionTrader:start()
	local now = getTickCount()
	local rank = getElementData( self.player, "rank", false ) / 1000

	-- По просшествии некоторого времени мы должны обновить содержимое контейнера 
	local period = math.interpolate( 900000 / 2, 300000 / 2, rank )
	if not self.lastUpdateTime or now - self.lastUpdateTime > period then
		self.lastUpdateTime = now

		-- На всякий случай запрещаем игроку подсматривать
		exports.xritems:xrContainerRemoveObserver( self.pedContId, self.player )

		-- Удаляем все предметы
		exports.xritems:xrContainerRemoveItems( self.pedContId, EHashes.SlotAny )

		-- Заполняем новыми
		for itemHash, coeffs in pairs( self.pedTradeSection ) do
			local itemSection = xrSettingsGetSection( itemHash )
			if itemSection then
				-- Выбираем предмет в соответствии со значением вероятности и ранга
				local prob = math.interpolate( coeffs:getY(), coeffs:getX(), rank )
				if math.random() <= prob then
					local count = math.interpolate( coeffs:getW(), coeffs:getZ(), rank )
					exports.xritems:xrContainerInsertItem( self.pedContId, itemHash, EHashes.SlotBag, math.ceil( count ), true )
				end
			end
		end
	end
	
	exports[ "xritems" ]:xrContainerAddObserver( self.pedContId, self.player )

	triggerClientEvent( self.player, EClientEvents.onClientSessionStart, self.player, self.pedContId, self.type, self.pedClassHash )
end

function xrSessionTrader:stop()
	exports[ "xritems" ]:xrContainerRemoveObserver( self.pedContId, self.player )

	-- Восстанавливаем инвентарь
	exports[ "xritems" ]:xrContainerMoveItems( self.playerContId, EHashes.SlotTrade, self.playerContId, EHashes.SlotBag )
	exports[ "xritems" ]:xrContainerMoveItems( self.pedContId, EHashes.SlotTrade, self.pedContId, EHashes.SlotBag )	

	triggerClientEvent( self.player, EClientEvents.onClientSessionStop, self.player )
end

function xrSessionTrader:onMoveItem( itemId, srcId, srcSlotHash, dstId, dstSlotHash )
	if ( srcId ~= self.playerContId and srcId ~= self.pedContId ) or
		( dstId ~= self.playerContId and dstId ~= self.pedContId ) then
		outputDebugString( "Инвалидные участники сессии!", 1 )
		return
	end

	-- Мы не можем напрямую перетаскивать в другой контейнер
	if srcId ~= dstId then
		return
	end

	-- Мы не можем переместить квестовый предмет
	local itemSection = xrGetContainerItemSection( srcId, itemId )
	if not itemSection or itemSection.quest_item then
		return false
	end

	return exports[ "xritems" ]:xrContainerMoveItem( srcId, itemId, dstId, dstSlotHash, 1 )
end

function xrSessionTrader:onUseItem( itemId, contId, slotHash )
	-- Мы не можем использовать квестовый предмет
	local itemSection = xrGetContainerItemSection( contId, itemId )
	if not itemSection or itemSection.quest_item then
		return
	end

	local tradeHash = EHashes.SlotTrade
	if slotHash == tradeHash then
		return exports[ "xritems" ]:xrContainerMoveItem( contId, itemId, contId, EHashes.SlotBag, 1 )
	else
		return exports[ "xritems" ]:xrContainerMoveItem( contId, itemId, contId, EHashes.SlotTrade, 1 )
	end
end

function xrSessionTrader:onTrade()
	-- Расчет суммарной стоимости предметов в слоте торговли
	local cost0 = exports[ "xritems" ]:xrContainerGetSlotCost( self.playerContId, EHashes.SlotTrade, true )
	local cost1 = exports[ "xritems" ]:xrContainerGetSlotCost( self.pedContId, EHashes.SlotTrade, false )
	if not cost0 or not cost1 then
		outputDebugString( "Непредвиденная ошибка!", 1 )
		return false
	end

	local earn0 = cost0 - cost1 -- Сколько заработает/потеряет первая сторона
	local earn1 = cost1 - cost0 -- Сколько заработает/потеряет вторая сторона
	
	-- Выдаем или забираем деньги
	local playerResult = xrGiveElementMoney( self.player, earn0, true )
	local pedResult = xrGiveElementMoney( self.ped, earn1, true )

	if playerResult and pedResult then
		xrGiveElementMoney( self.player, earn0 ) 
		xrGiveElementMoney( self.ped, earn1 )

		-- Обмениваемся предметами
		exports[ "xritems" ]:xrContainerMoveItems( self.playerContId, EHashes.SlotTrade, self.pedContId, EHashes.SlotBag )
		exports[ "xritems" ]:xrContainerMoveItems( self.pedContId, EHashes.SlotTrade, self.playerContId, EHashes.SlotBag )	

		return true
	else
		local errorCode = playerResult ~= true and 1 or 2 
		triggerClientEvent( self.player, EClientEvents.onClientTradeError, self.player, errorCode )
	end

	return false
end

--[[
	xrSessionSelf
]]
xrSessionSelf = {

}
xrSessionSelfMT = {
	__index = xrSessionSelf
}
setmetatable( xrSessionSelf, xrSessionMT )

function xrSessionSelf:create( player )
	local playerContId = getElementData( player, "contId", false )
	if not playerContId then
		outputDebugString( "Игрок не содержит номер контейнера", 1 )
		return false
	end

	local playerClassHash = tonumber( getElementData( player, "cl", false ) )
	if not playerClassHash then
		outputDebugString( "Оппонент не содержит хэш класса", 1 )
		return false
	end

	local session = {
		player = player,
		playerContId = playerContId,
		playerClassHash = playerClassHash,

		type = EST_PLAYER_SELF
	}

	return setmetatable( session, xrSessionSelfMT )
end

function xrSessionSelf:destroy()
	
end

function xrSessionSelf:start()
	triggerClientEvent( self.player, EClientEvents.onClientSessionStart, self.player, self.playerContId, self.type, self.playerClassHash )
end

function xrSessionSelf:stop()
	triggerClientEvent( self.player, EClientEvents.onClientSessionStop, self.player )
end

function xrSessionSelf:onUseItem( itemId, contId, slotHash )
	if contId ~= self.playerContId then
		outputDebugString( "Игрок может обращаться только к своему контейнеру", 2 )
		return
	end

	-- Мы не можем использовать квестовый предмет
	local itemSection = xrGetContainerItemSection( contId, itemId )
	if not itemSection or itemSection.quest_item then
		return
	end

	return exports[ "xritems" ]:xrContainerUseItem( contId, itemId, self.player )
end

function xrSessionSelf:onDropItem( itemId, contId, slotHash, dropAll )
	if contId ~= self.playerContId then
		outputDebugString( "Игрок может обращаться только к своему контейнеру", 2 )
		return
	end

	-- Мы не можем выкинуть квестовый предмет
	local itemSection = xrGetContainerItemSection( contId, itemId )
	if not itemSection or itemSection.quest_item then
		return
	end

	local x, y, z = getElementPosition( self.player )
	exports.xritems:xrContainerDropItem( contId, itemId, x, y, z - 0.7, dropAll )
end

function xrSessionSelf:onMoveItem( itemId, srcId, srcSlotHash, dstId, dstSlotHash )
	if ( srcId ~= self.playerContId and srcId ~= self.pedContId ) or
		( dstId ~= self.playerContId and dstId ~= self.pedContId ) then
		outputDebugString( "Инвалидные участники сессии!", 1 )
		return
	end

	-- Здесь мы не можем перетаскивать в другой контейнер
	if srcId ~= dstId then
		outputDebugString( "Подозрительное обращение к другому контейнеру", 1 )
		return
	end

	-- Мы не можем переместить квестовый предмет
	local itemSection = xrGetContainerItemSection( srcId, itemId )
	if not itemSection or itemSection.quest_item then
		return false
	end

	return exports[ "xritems" ]:xrContainerMoveItem( srcId, itemId, dstId, dstSlotHash, 1 )
end

--[[
	xrSessionObject
]]
xrSessionObject = {

}
xrSessionObjectMT = {
	__index = xrSessionObject
}
setmetatable( xrSessionObject, xrSessionMT )

function xrSessionObject:create( player, object )
	local playerContId = getElementData( player, "contId", false )
	if not playerContId then
		outputDebugString( "Игрок не содержит номер контейнера", 1 )
		return false
	end

	local objContId = getElementData( object, "contId", false )
	if not objContId then
		outputDebugString( "Игрок не содержит номер контейнера", 1 )
		return false
	end

	local objClassHash = tonumber( getElementData( object, "cl", false ) )
	if not objClassHash then
		outputDebugString( "Оппонент не содержит хэш класса", 1 )
		return false
	end

	local session = {
		player = player,
		playerContId = playerContId,
		obj = object,
		objContId = objContId,
		objClassHash = objClassHash,
		type = EST_PLAYER_OBJECT
	}

	return setmetatable( session, xrSessionObjectMT )
end

function xrSessionObject:destroy()

end

function xrSessionObject:start()
	exports[ "xritems" ]:xrContainerAddObserver( self.objContId, self.player )

	triggerClientEvent( self.player, EClientEvents.onClientSessionStart, self.player, self.objContId, self.type, self.objClassHash )
end

function xrSessionObject:stop()
	exports[ "xritems" ]:xrContainerRemoveObserver( self.objContId, self.player )

	triggerClientEvent( self.player, EClientEvents.onClientSessionStop, self.player )
end

function xrSessionObject:onMoveItem( itemId, srcId, srcSlotHash, dstId, dstSlotHash )
	if ( srcId ~= self.playerContId and srcId ~= self.objContId ) or
		( dstId ~= self.playerContId and dstId ~= self.objContId ) then
		outputDebugString( "Инвалидные участники сессии!", 1 )
		return
	end

	-- Мы не можем переместить квестовый предмет
	local itemSection = xrGetContainerItemSection( srcId, itemId )
	if not itemSection or itemSection.quest_item then
		return false
	end

	return exports[ "xritems" ]:xrContainerMoveItem( srcId, itemId, dstId, dstSlotHash, 1 )
end

function xrSessionObject:onUseItem( itemId, contId, slotHash )
	-- Мы не можем использовать квестовый предмет
	local itemSection = xrGetContainerItemSection( contId, itemId )
	if not itemSection or itemSection.quest_item then
		return
	end

	if contId == self.playerContId then
		exports[ "xritems" ]:xrContainerMoveItem( contId, itemId, self.objContId, EHashes.SlotBag )
	else
		exports[ "xritems" ]:xrContainerMoveItem( contId, itemId, self.playerContId, EHashes.SlotBag )
	end
end

--[[
	Logic
]]
local targetRefs = {
	-- Таблица для счета ссылок на элемент
	-- [element] = refsNum
}

xrSessionHolder = {
	
}
xrSessionHolderMT = {
	__index = xrSessionHolder
}

function xrSessionHolder:create( player )
	local holder = {
		player = player,
		sessions = {},
		current = nil
	}

	return setmetatable( holder, xrSessionHolderMT )
end

function xrSessionHolder:destroy()
	-- Оставнока текущей сессии, если она есть
	self:stopSession()

	-- Уничтожение всех сессий игрока
	for element, session in pairs( self.sessions ) do
		session:destroy()
	end
	self.sessions = nil
	self.player = nil
end

function xrSessionHolder:startSession( target )
	if self.current then
		outputDebugString( "Какая-то сессия уже запущена", 2 )
		return false
	end

	local session = self.sessions[ target ]
	if not session then
		if getElementType( target ) == "ped" then
			if getElementData( target, "fake", false ) or getElementData( target, "volatile", false ) then
				session = xrSessionObject:create( self.player, target )
			else
				session = xrSessionTrader:create( self.player, target )
			end
		elseif getElementType( target ) == "player" then
			if self.player == target then
				session = xrSessionSelf:create( self.player, target )	
			end
		else
			session = xrSessionObject:create( self.player, target )
		end
		if not session then
			outputDebugString( "Ошибка при создании сессии", 2 )
			return false
		end

		self.sessions[ target ] = session		
	end

	session:start()
	
	self.current = session
	self.target = target

	-- Инкремент числа ссылок
	local refsNum = targetRefs[ target ] or 0
	targetRefs[ target ] = refsNum + 1

	return true
end

function xrSessionHolder:stopSession()
	local session = self.current
	if not session then
		return false
	end

	-- Декремент числа ссылок
	local refsNum = targetRefs[ self.target ] or 0
	if refsNum > 1 then
		targetRefs[ self.target ] = refsNum - 1
	else
		targetRefs[ self.target ] = nil
	end

	session:stop()

	self.current = nil
	self.target = nil

	return true
end

function xrSessionHolder:onUseItem( itemId, contId, slotHash )
	local session = self.current
	if session then
		session:onUseItem( itemId, contId, slotHash )
	end
end

function xrSessionHolder:onDropItem( itemId, contId, slotHash, dropAll )
	local session = self.current
	if session then
		session:onDropItem( itemId, contId, slotHash, dropAll )
	end
end

function xrSessionHolder:onMoveItem( itemId, prevContainerId, prevSlotHash, newContainerId, newSlotHash )
	local session = self.current
	if session then
		session:onMoveItem( itemId, prevContainerId, prevSlotHash, newContainerId, newSlotHash )
	end
end

function xrSessionHolder:onTrade()
	local session = self.current
	if session then
		session:onTrade()
	end
end

local _sessions = {
	-- Храним сессии всех игроков
}
setmetatable( _sessions, {
	__index = function( self, player )
		local value = rawget( self, player )
		if not value then
			value = xrSessionHolder:create( player )
			rawset( self, player, value )
		end
		return value
	end
} )

function onPlayerInventoryKey( player, key )
	local holder = _sessions[ player ]
	if holder.current then
		holder:stopSession()
	elseif not isPedDead( player ) and not getElementData( player, "uib", false ) then
		holder:startSession( player )
	end
end

function xrStartInventorySession( player, target )
	if getElementData( player, "uib", false ) then
		return false
	end

	local holder = _sessions[ player ]
	holder:startSession( target )

	return true
end

function xrStopInventorySession( player )
	local holder = _sessions[ player ]
	holder:stopSession()
	
	return true
end

--[[
	xrGetElementRefsNum возвращает кол-во ссылок из сессий на данный элемент
]]
function xrGetElementRefsNum( element )
	return targetRefs[ element ] or 0
end

function xrGetInventorySessionStatus( player )
	local holder = _sessions[ player ]
	return holder.current ~= nil
end

function onSessionStop()
	local holder = _sessions[ client ]
	holder:stopSession()
end

local function onSessionItemUse( itemId, contId, slotHash )
	if type( itemId ) ~= "number" or type( contId ) ~= "number" or type( slotHash ) ~= "number" then
		outputDebugString( "Сообщение от клиента скомпрометировано", 2 )
		return
	end

	local holder = _sessions[ client ]
	holder:onUseItem( itemId, contId, slotHash )
end

local function onSessionItemDrop( itemId, contId, slotHash, dropAll )
	if type( itemId ) ~= "number" or type( contId ) ~= "number" or type( slotHash ) ~= "number" then
		outputDebugString( "Сообщение от клиента скомпрометировано", 2 )
		return
	end

	local holder = _sessions[ client ]
	holder:onDropItem( itemId, contId, slotHash, dropAll )
end

local function onSessionItemMove( itemId, prevContainerId, prevSlotHash, newContainerId, newSlotHash )
	if type( itemId ) ~= "number" or type( prevContainerId ) ~= "number" or type( prevSlotHash ) ~= "number" or type( newContainerId ) ~= "number" or type( newSlotHash ) ~= "number" then
		outputDebugString( "Сообщение от клиента скомпрометировано", 2 )
		return
	end

	local holder = _sessions[ client ]
	holder:onMoveItem( itemId, prevContainerId, prevSlotHash, newContainerId, newSlotHash )
end

local function onSessionTradeOp( )
	local holder = _sessions[ client ]
	holder:onTrade()
end

local function onPlayerGamodeJoin()
	exports[ "xritems" ]:xrContainerAddObserver( source, source )	

	bindKey( source, "tab", "down", onPlayerInventoryKey )
end

local function onPlayerGamodeLeave()
	local holder = _sessions[ source ]
	holder:destroy()
	_sessions[ source ] = nil

	exports[ "xritems" ]:xrContainerRemoveObserver( source, source )

	unbindKey( source, "tab", "down", onPlayerInventoryKey )
end

--[[
	Export
]]
function xrReturnPlayerItems( player )
	exports[ "xritems" ]:xrContainerMoveItems( player, EHashes.SlotTemp, player, EHashes.SlotAny )

	return false
end

--[[
    Initialization
]]
addEvent( "onCoreInitializing", false )
addEventHandler( "onCoreInitializing", root,
    function()
		local db = exports[ "xrcore" ]:xrCoreGetDB()
		if not db then
			outputDebugString( "Указатель на базу данных не был получен!", 1 )
			return
		end
	
		triggerEvent( "onResourceInitialized", resourceRoot, resource )
    end
, false )

addEventHandler( "onCoreStarted", root,
    function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
		xrIncludeModule( "player.lua" )
		xrIncludeModule( "global.lua" )
		xrIncludeModule( "items.lua" )

		if not xrSettingsInclude( "items_only.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
		end

		if not xrSettingsInclude( "misc/trade/trade_trader.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
		end

		if not xrSettingsInclude( "characters/stalkers.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
		end

		addEvent( EServerEvents.onPlayerGamodeJoin, false )
		addEventHandler( EServerEvents.onPlayerGamodeJoin, root, onPlayerGamodeJoin )
		addEvent( EServerEvents.onPlayerGamodeLeave, false )
		addEventHandler( EServerEvents.onPlayerGamodeLeave, root, onPlayerGamodeLeave )
		addEvent( EServerEvents.onSessionTradeOp, true )
		addEventHandler( EServerEvents.onSessionTradeOp, root, onSessionTradeOp )
		addEvent( EServerEvents.onSessionItemMove, true )
		addEventHandler( EServerEvents.onSessionItemMove, root, onSessionItemMove )
		addEvent( EServerEvents.onSessionItemUse, true )
		addEventHandler( EServerEvents.onSessionItemUse, root, onSessionItemUse )
		addEvent( EServerEvents.onSessionItemDrop, true )
		addEventHandler( EServerEvents.onSessionItemDrop, root, onSessionItemDrop )
		addEvent( EServerEvents.onSessionStop, true )
		addEventHandler( EServerEvents.onSessionStop, root, onSessionStop )
    end
)
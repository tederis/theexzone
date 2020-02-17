local loadFrameNames = {
	"textures/loading/background.jpg",
	"textures/loading/background2.jpg"
}
local loadSoundName = "sounds/wasteland2.ogg"

ETipStrings = {
    "У костра ваше здоровье восстанавливается быстрее",
    "В лагерях и точках появления можно найти зеленые зоны, в которых вы неуязвимы для огня противника",
    "Процесс захвата аванпоста быстрее, если вы не одни. Собирайтесь в группы и ускоряйте захват",
    "Несмотря на все полезные свойства, большинство артефактов радиоактивны. Данный эффект можно компенсировать другими артефактами, которые поглощают радиацию.",
    "Повышайте ранг и торговцы будут расширять свой ассортимент товара",
    "Умирая, часть ваших вещей попадает к торговцу. Не забудьте после возрождения обратиться к нему",
	"Используйте болт для деактивации аномалий",
	"Вы можете приобрести фонарик у торговца",	
	"Некоторые медикаменты обладают уникальными свойствами - как, например, препарат «Геркулес», позволяющий на время увеличить потенциальную грузоподъёмность, или препарат пси-блокады, повышающий сопротивляемость воздействию на психику",
	"Водка - дешёвая альтернатива противорадиационным препаратам и самый доступный способ снизить воздействие радиации на организм.",
	"Пища не только утоляет голод, но и несколько улучшает состояние здоровья.",
	"Энергетический напиток временно ускоряет восстановление выносливости, что увеличивает потенциальную мобильность.",
	"Некоторые медикаменты повышают уровень сопротивляемости организма вредным воздействиям и могут оказаться единственным спасением во время вылазок в аномальные районы.",
	"Количество переносимого груза напрямую влияет на снижение выносливости. Большой вес ограничит мобильность, а перегрузка не позволит передвигаться вообще.",
	"Большинство артефактов мигрируют внутри аномалий и не видимы глазом, пока не будут выявлены при помощи детектора",
	"При сильном радиоактивном облучении необходимо воспользоваться противорадиационными препаратами или обратиться к медику. Если такой возможности нет, можно воспользоваться аптечкой, чтобы экстренно снизить негативное воздействие радиации на организм.",
	"Прибыль могут принести не только артефакты, но и продажа излишков снаряжения. При этом нужно учесть, что торговцы не заплатят за снаряжение его полную стоимость и не станут покупать слишком повреждённые вещи.",
	"Прямое попадание пули в голову является смертельным для большинства противников",
	"Ключевые индикаторы - состояния здоровья и выносливости - находятся в правом нижнем углу экрана.",
	"В Зоне всегда лучше иметь при себе пару запасных магазинов, поскольку они могут понадобиться в любой момент.",
	"Для рационального применения медикаментов необходимо знать их свойства. Внимательно изучите описание каждого из препаратов.",
	"Многие объекты в Зоне характерны повышенным радиационным фоном, поэтому приближаться к ним без соответствующей защиты опасно",
	"Для остановки кровотечения можно воспользоваться бинтом, армейской аптечкой или препаратом «Барвинок». Не остановленное вовремя кровотечение может нанести значительный урон организму и закончиться гибелью.",
	"Чтобы включить или выключить фонарик, нажмите L",
	"Эффект от приёма медикаментов не является мгновенным, а некоторые препараты отличаются весьма продолжительным действием. При этом эффект препарата, принятого последним, перекрывает аналогичные эффекты от принятых ранее веществ.",
	"Символ в виде капли крови в правом нижнем углу экрана предупреждает о неостановленном кровотечении. Цвет символа указывает на интенсивность кровотечения.",
	"Символ радиационной опасности в правом нижнем углу экрана предупреждает о радиационном облучении организма. Цвет символа указывает на интенсивность облучения.",
	"Обращайте внимание на треск счётчика Гейгера - он сигнализирует о радиационном излучении. Реагируйте и на сигнал аномальной опасности, который начинает звучать вблизи от аномалии."

}

function math.lerp( a, b, t )
	return ( 1 - t ) * a + t * b
end

xrSharedSnd = false

--[[
	xrInterface
]]
xrInterface = { 
	
}

function xrInterface.start()
	if xrInterface.enabled then
		return
	end

	--[[
		Останавливаем звуки оригинальной игры и скрываем HUD
	]]
	for i = 0, 44 do
		setWorldSoundEnabled( i, false )
	end
	setAmbientSoundEnabled( "general", false )

	setPlayerHudComponentVisible( "all", false )
	showChat( false )

	--[[
		Запускаем экран загрузки
	]]
	xrLoadingScreen:new()

	xrInterface.enabled = true
end

function xrInterface.stop()
	if not xrInterface.enabled then
		return
	end

	xrLoadingScreen:destroy()
	
	xrInterface.enabled = false
end

function xrInterface.onRender()
	if xrInterface.enabled then
		xrLoadingScreen:onRender()
	end
end

function xrInterface.setFadeIn( progress )
	if xrInterface.enabled then
		xrLoadingScreen:setFadeIn( progress )
	end
end

--[[
	xrLoadingScreen
]]
xrLoadingScreen = {}

local spinnerRps = 0.1

function xrLoadingScreen:new()
	self.frames = {}
	for i, frameName in ipairs( loadFrameNames ) do
		self.frames[ i ] = dxCreateTexture( frameName )
	end
	self.spinner = dxCreateTexture( "textures/loading/rolling.png" )

	self.tipIndex = math.random( 1, #ETipStrings )
	self.index = 1
	self.rotation = 0
	self.progress = 0
	self.lastFrameTime = getTickCount()

	self:initFrame( 1.2, 15000 )
end

function xrLoadingScreen:destroy()
	for _, frameTex in ipairs( self.frames ) do
		destroyElement( frameTex )
	end
	destroyElement( self.spinner )
end

function xrLoadingScreen:onRender()
	local now = getTickCount()
	local dt = ( now - self.lastFrameTime ) / 1000
	self.lastFrameTime = now

	local sw, sh = guiGetScreenSize()
	dxDrawRectangle( 0, 0, sw, sh, tocolor( 0, 0, 0 ) )

	--[[
		Анимируем фон
	]]
	local elapsed = now - self.startTime
	local t = elapsed / self.duration	
	if t <= 1 then
		local alpha = 1 - math.pow( t*2 - 1, 10 )
		local alpha2 = 1 - math.pow( self.progress, 3 )

		local width = self.startImgWidth * ( 1 - t ) + self.endImgWidth * t
		local height = self.startImgHeight * ( 1 - t ) + self.endImgHeight * t

		local x = sw / 2 - width / 2
		local y = sh / 2 - height / 2

		local texture = self.frames[ self.index ]
		dxDrawImage( math.lerp( x, 0, t ), y, width, height, texture, 0, 0, 0, tocolor( 255, 255, 255, alpha*alpha2*255 ) )

		-- Рисуем подсказки
		local str = ETipStrings[ self.tipIndex ]
		local width = sh * 0.6
		dxDrawText( 
			str, 
			sw / 2 - width / 2, sh * 0.75, 
			sw / 2 + width / 2, sh, 
			tocolor( 255, 255, 255, alpha*alpha2*255 ), 
			1.4, "clear", 
			"center", "top",
			false, true
		)
	else		
		self:initFrame( 1.2, 15000 )
	end

	--[[
		Обновляем и рисуем спиннер
	]]
	local perturbation = math.sin( ( now % 3000 ) / 3000 * math.pi ) * 3
	self.rotation = self.rotation + ( spinnerRps * math.pi * 2 + perturbation ) * dt

	local size = sw * 0.08

	dxDrawImage( 
		sw / 2 - size / 2, sh / 2 - size / 2, size, size, 
		self.spinner,
		math.deg( self.rotation ), 0, 0, 
		tocolor( 255, 255, 255, 100 )
	)
end

function xrLoadingScreen:initFrame( scale, duration )
	self.index = self.index + 1
	if self.index > #loadFrameNames then
		self.index = 1
	end

	-- Обновляем подсказку
	local prevTipIndex = self.tipIndex
	repeat
		self.tipIndex = math.random( 1, #ETipStrings )
	until self.tipIndex ~= prevTipIndex


	local texWidth, texHeight = dxGetMaterialSize( self.frames[ self.index ] )
	local texAspect = texWidth / texHeight
	local texAspectInv = texHeight / texWidth
	local sw, sh = guiGetScreenSize()

	--[[
		Предусматриваем поддержку мониторов любого формата
	]]
	self.startImgWidth = sh * texAspect
	self.startImgHeight = sh
	if self.startImgWidth < sw then
		self.startImgWidth = sw
		self.startImgHeight = sw * texAspectInv
	end

	self.endImgWidth = self.startImgWidth * scale
	self.endImgHeight = self.startImgHeight * scale

	self.startTime = getTickCount()
	self.duration = duration
end

function xrLoadingScreen:setFadeIn( progress )
	self.progress = math.max( math.min( progress, 1 ), 0 )
end

--[[
	Export
]]
local LOADER_DEFAULT = 1 -- Просто рисуем экран
local LOADER_FADEIN = 2 -- Затеняем экран
local LOADER_AWAIT = 3 -- Ждем сигнала

xrLoader = {
	running = false,
	ticksNum = 0,
	signalPermit = false,
	state = LOADER_DEFAULT
}

function xrLoader_start()
	if xrLoader.running then
		return
	end

	-- Запускаем общую фоновую музыку
	xrStartLoadingSound()

	-- Запускаем экран загрузки
	xrInterface.start()

	addEventHandler( "onClientRender", root, xrLoader_update, false, "high" )

	xrLoader.state = LOADER_DEFAULT
	xrLoader.ticksNum = 0
	xrLoader.signalPermit = false
	xrLoader.running = true
end

function xrLoader_stop( deferred )
	if not xrLoader.running then
		return
	end

	removeEventHandler( "onClientRender", root, xrLoader_update )

	if not deferred then
		xrStopLoadingSound()
	end

	xrInterface.stop()

	xrLoader.running = false
end

function xrLoader_signal()
	--[[
		Как только сигнал получен - начинаем процесс затенения
	]]
	if xrLoader.running and xrLoader.signalPermit then
		xrLoader.signalPermit = false
		xrLoader.state = LOADER_FADEIN
		xrLoader.ticksNum = 300
	end
end

function xrLoader_update()
	-- Обновляем состояния загрузчика
	if xrLoader.state < LOADER_AWAIT then
		xrLoader.ticksNum = math.min( xrLoader.ticksNum + 1, 100000 )

		if xrLoader.ticksNum > 500 then
			if xrLoader.state == LOADER_FADEIN then
				xrLoader_stop( true )

				triggerEvent( "onClientGameLoaded", localPlayer )
			else
				local coreRes = getResourceFromName( "xrcore" )
				--[[
					Если к этому момент ядро уже запущено - запускаем процесс затенения экрана
				]]
				if coreRes and coreRes.state == "running" and exports.xrcore:xrCoreGetState() then
					xrLoader.state = LOADER_FADEIN
					xrLoader.ticksNum = 300

				--[[
					Если же ядро еще не запущено - устанавливаем разрешение и ждем сигнала
				]]
				else
					xrLoader.signalPermit = true
					xrLoader.state = LOADER_AWAIT		
				end
			end
		elseif xrLoader.state == LOADER_FADEIN then
			local value = math.max( xrLoader.ticksNum - 300, 0 ) / 200
			xrInterface.setFadeIn( value )
		end
	end

	-- Обновляем интерфейс
	xrInterface.onRender()
end

function xrStartLoadingSound()
	if not xrSharedSnd then
		xrSharedSnd = playSound( loadSoundName, true )
	end
end

function xrStopLoadingSound()
	if isElement( xrSharedSnd ) then
		stopSound( xrSharedSnd )
	end

	xrSharedSnd = false
end

--[[
	Init
]]
addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )		
		xrLoader_start()
	end
, false )

addEvent( "onClientCoreStarted", false )
addEventHandler( "onClientCoreStarted", root,
	function()
		xrLoader_signal()
	end
)
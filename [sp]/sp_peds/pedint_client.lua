addEvent( "onClientElementActionHit", false )
addEventHandler ( "onClientElementActionHit", root,
	function ( )
		if getElementType ( source ) ~= "ped" or getElementData( source, "fake" ) or getElementData( source, "volatile" )  then
			return
		end
		
		if math.random ( 1, 3 ) == 2 then
			return
		end
		
		math.randomseed ( getTickCount ( ) )
		
		local x, y, z = getElementPosition ( source )
		local rndSound = math.random ( 1, 4 )
		if not playSound3D ( "sounds/script/soldier_greeting_" .. rndSound .. ".ogg", x, y, z, false ) then
			outputDebugString( "Не можем найти звук", 2 )
		end
	end
)

addEvent( "onClientElementActionLeave", false )
addEventHandler ( "onClientElementActionLeave", root,
	function ( )
		if getElementType ( source ) ~= "ped" or getElementData( source, "fake" ) or getElementData( source, "volatile" ) then
			return
		end
		
		if math.random ( 1, 3 ) == 2 then
			return
		end
		
		math.randomseed ( getTickCount ( ) )
		
		local x, y, z = getElementPosition ( source )
		local rndSound = math.random ( 1, 4 )
		if not playSound3D ( "sounds/script/soldier_leave_" .. rndSound .. ".ogg", x, y, z, false ) then
			outputDebugString( "Не можем найти звук", 2 )
		end
	end
)

local function importAnims()
	engineLoadIFP( "anims/wounded.ifp", "wounded" )	
end

local pedModels = {
	-- Сталкеры
	{ "models/odinochka.txd", "models/odinochka.dff", 280 },
	{ "models/opitniy.txd", "models/opitniy.dff", 282 },
	{ "models/army.txd", "models/novichek.dff", 32 },

	-- Свобода
	{ "models/freedom.txd", "models/armouredsuit.dff", 31 },
	{ "models/freedom/bmori.txd", "models/freedom/bmori.dff", 90 },
	{ "models/freedom/bmost.txd", "models/freedom/bmost.dff", 91 },
	{ "models/freedom/bmycr.txd", "models/freedom/bmycr.dff", 92 },
	{ "models/freedom/bmyri.txd", "models/freedom/bmyri.dff", 93 },
	{ "models/freedom/mafboss.txd", "models/freedom/mafboss.dff", 129 },
	{ "models/freedom/maffa.txd", "models/freedom/maffa.dff", 130 },
	{ "models/freedom/maffb.txd", "models/freedom/maffb.dff", 131 },
	{ "models/freedom/swmotr1.txd", "models/freedom/swmotr1.dff", 138 },
	{ "models/freedom/triada.txd", "models/freedom/triada.dff", 139 },
	{ "models/freedom/triadb.txd", "models/freedom/triadb.dff", 140 },
	{ "models/freedom/triboss.txd", "models/freedom/triboss.dff", 141 },
	{ "models/freedom/vmaff1.txd", "models/freedom/vmaff1.dff", 145 },
	{ "models/freedom/vmaff2.txd", "models/freedom/vmaff2.dff", 148 },
	{ "models/freedom/vmaff3.txd", "models/freedom/vmaff3.dff", 150 },
	{ "models/freedom/vmaff4.txd", "models/freedom/vmaff4.dff", 151 },

	-- Долг
	{ "models/duty.txd", "models/armouredsuit.dff", 152 },
	{ "models/duty/bmycr.txd", "models/duty/bmycr.dff", 157 },
	{ "models/duty/dnb1.txd", "models/duty/dnb1.dff", 169 },
	{ "models/duty/dnb2.txd", "models/duty/dnb2.dff", 172 },
	{ "models/duty/dnb3.txd", "models/duty/dnb3.dff", 178 },
	{ "models/duty/fam1.txd", "models/duty/fam1.dff", 190 },
	{ "models/duty/fam2.txd", "models/duty/fam2.dff", 191 },
	{ "models/duty/fam3.txd", "models/duty/fam3.dff", 192 },
	{ "models/duty/vla1.txd", "models/duty/vla1.dff", 193 },
	{ "models/duty/vla2.txd", "models/duty/vla2.dff", 194 },
	{ "models/duty/vla3.txd", "models/duty/vla3.dff", 195 },

	-- Бандиты
	{ "models/bandos.txd", "models/bandos.dff", 33 },
	{ "models/opitniy_bandos2.txd", "models/opitniy_bandos2.dff", 284 },

	-- Чистое небо
	{ "models/clearskyhood.txd", "models/clearskyhood.dff", 34 },
	{ "models/male01.txd", "models/male01.dff", 285 },

	-- Военные
	{ "models/voenn.txd", "models/voenn.dff", 281 },
	{ "models/army/army.txd", "models/army/army.dff", 196 },

	-- Ученые
	{ "models/scientist/bikerb.txd", "models/scientist/bikerb.dff", 197 },
	{ "models/scientist/bmori.txd", "models/scientist/bmori.dff", 198 },
	{ "models/scientist/bmost.txd", "models/scientist/bmost.dff", 199 },
	{ "models/scientist/bmyap.txd", "models/scientist/bmyap.dff", 201 },
	{ "models/scientist/bmybar.txd", "models/scientist/bmybar.dff", 205 },
	{ "models/scientist/bmycr.txd", "models/scientist/bmycr.dff", 207 },
	{ "models/scientist/bmyri.txd", "models/scientist/bmyri.dff", 211 },
	{ "models/scientist/bmyst.txd", "models/scientist/bmyst.dff", 214 },
	{ "models/scientist/bmytatt.txd", "models/scientist/bmytatt.dff", 215 },
	{ "models/scientist/sfr1.txd", "models/scientist/sfr1.dff", 216 },
	{ "models/scientist/sfr2.txd", "models/scientist/sfr2.dff", 218 },
	{ "models/scientist/sfr3.txd", "models/scientist/sfr3.dff", 219 },
	{ "models/scientist/shmycr.txd", "models/scientist/shmycr.dff", 224 },
	{ "models/scientist/wmybar.txd", "models/scientist/wmybar.dff", 225 }
}

local function importModels()
	setWorldSoundEnabled ( 20, false )
	setWorldSoundEnabled ( 21, false )
	setWorldSoundEnabled ( 22, false )
	setWorldSoundEnabled ( 24, false )

	local geoms = {

	}
	local textures = {

	}
	local models = {

	}
	
	for _, meta in ipairs( pedModels ) do
		if not models[ meta[ 3 ] ] then
			local txd = textures[ meta[ 1 ] ]
			if not txd then
				txd = engineLoadTXD( meta[ 1 ], true )
				textures[ meta[ 1 ] ] = txd
			end

			local dff = geoms[ meta[ 2 ] ]
			if not dff then
				dff = engineLoadDFF( meta[ 2 ] )
				geoms[ meta[ 2 ] ] = dff
			end
			
			if txd and dff then
				engineImportTXD( txd, meta[ 3 ] )
				engineReplaceModel( dff, meta[ 3 ], false )
			else
				outputDebugString( "Ошибка загрузки скина " .. tostring( meta[ 3 ] ) )
			end

			models[ meta[ 3 ] ] = true
		else
			outputDebugString( "Скин " .. tostring( meta[ 3 ] ) .. " уже зарегистрирован" )
		end
	end
end

addEventHandler( "onClientResourceStart", resourceRoot,
	function()
		importAnims()
		importModels()
	end
)

addEventHandler( "onClientCoreStarted", resourceRoot,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )

		--importAnims()
        --importModels()
    end
)
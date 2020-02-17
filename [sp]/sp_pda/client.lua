local sw, sh = guiGetScreenSize ( )

xrMain = {
	isEnabled = false
}

function xrMain:init()
	local aspect = 1024 / 768
	local height = math.floor( sh * 0.8 )
	local width = math.floor( height * aspect )
	
	xrMain.canvas = xrCreateUICanvas( sw / 2 - width / 2, sh / 2 - height / 2, width, height )

	local xml = xmlLoadFile( "PDAmain.xml", true )
	if xml then
		xrMain.canvas:load( xml )

		xmlUnloadFile( xml )
	end

	xrMap.init( xrMain.canvas )
	xrDonate.init( xrMain.canvas )	

	self.current = xrMap

	--[[do
		showCursor( false )
		exports.sp_chatbox:xrShowChat( true )
		guiSetInputEnabled( false )

		setElementData( localPlayer, "uib", false, true )
		exports.sp_hud_real_new:xrHUDSetEnabled( true )
	end]]

	xrMain.canvas:update()
end

function xrMain:open()	
	if xrMain.isEnabled then
		return
	end	

	addEventHandler( "onClientRender", root, xrMain.onRender, false )
	addEventHandler( "onClientCursorMove", root, xrMain.onCursorMove, false )
	addEventHandler( "onClientClick", root, xrMain.onCursorClick, false )
	addEventHandler( "onClientKey", root, xrMain.onKey, false )

	if self.current then
		self.current:open()
	end

	do
		showCursor( true )
		exports.sp_chatbox:xrShowChat( false )
		guiSetInputEnabled( true )

		setElementData( localPlayer, "uib", true, true )
		exports.sp_hud_real_new:xrHUDSetEnabled( false )
	end

	xrMain.isEnabled = true
end

function xrMain:close()
	if xrMain.isEnabled then
		removeEventHandler( "onClientRender", root, xrMain.onRender )
		removeEventHandler( "onClientCursorMove", root, xrMain.onCursorMove )
		removeEventHandler( "onClientClick", root, xrMain.onCursorClick )
		removeEventHandler( "onClientKey", root, xrMain.onKey, false )

		if self.current then
			self.current:close()
		end

		do
			showCursor( false )
			exports.sp_chatbox:xrShowChat( true )
			guiSetInputEnabled( false )

			setElementData( localPlayer, "uib", false, true )
			exports.sp_hud_real_new:xrHUDSetEnabled( true )
		end

		xrMain.isEnabled = false
	end
end

function xrMain.onTabClicked( class )
	if xrMain.current then
		xrMain.current:close()
	end

	xrMain.current = class

	if xrMain.current then
		xrMain.current:open()
	end
end

function xrMain.onRender()
	xrMain.canvas:draw()

	if xrMain.current then
		xrMain.current.onRender()
	end
end

function xrMain.onCursorMove( _, _, ax, ay )
	xrMain.canvas:onCursorMove( ax, ay )

	if xrMain.current then
		xrMain.current.onCursorMove( _, _, ax, ay )
	end
end


function xrMain.onCursorClick( btn, state, ax, ay )	
	xrMain.canvas:onCursorClick( btn, state, ax, ax )

	if xrMain.current then
		xrMain.current.onCursorClick( btn, state, ax, ay )
	end
end

function xrMain.onKey( btn, pressed )
	if xrMain.current then
		xrMain.current.onKey( btn, pressed )
	end

	
	if btn == "i" and pressed then
		xrMain:close()
	end
end

--[[
	Init
]]
addEventHandler( "onClientCoreStarted", root,
--addEventHandler( "onClientResourceStart", resourceRoot,
	function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
		xrIncludeModule( "global.lua" )
		xrIncludeModule( "player.lua" )

		if not xrSettingsInclude( "teams.ltx" ) then
            return
        end	

		xrLoadUIColorDict( "color_defs" )
		xrLoadAllUIFileDescriptors()

		xrMain:init()

		-- Test
		bindKey( "i", "down",
			function()
				if xrMain.isEnabled then
					xrMain:close()
				elseif getElementData( localPlayer, "uib", false ) ~= true then
					xrMain:open()
				end
			end
		)
    end
)
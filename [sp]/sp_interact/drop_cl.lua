local DROP_ICON_HEIGHT = 0.4
local DROP_COLOR = tocolor( 255, 255, 255 )
local DRAW_RADIUS_SQR = 25*25

local xrDropStreamer = nil
local xrDropTexture = nil
local xrStreamedInDrops = setmetatable( {}, { __mode = "kv" } )
local xrDrops = {

}

--[[
    xrDrop
]]
xrDrop = {

}
xrDropMT = {
    __index = xrDrop
}

function xrDrop:onStreamedIn()
	table.insert( xrStreamedInDrops, self )
end

function xrDrop:onStreamedOut()
	table.removeValue( xrStreamedInDrops, self )
end

function xrDrop:onUpdate( dt )
    local x, y, z = getElementPosition( self.element )
    if getScreenFromWorldPosition( x, y, z ) then
        local cx, cy = getCameraMatrix()

        local section = self.section
        local aspect = section.inv_grid_width / section.inv_grid_height
        local width = DROP_ICON_HEIGHT * aspect
        local height = DROP_ICON_HEIGHT
        local halfHeight = height / 2

        local floating = ( math.sin( getTickCount() / 1000 ) + 1 ) / 2
        z = z + floating*0.2

        local distSqr = ( cx - x )^2 + ( cy - y )^2
        local factor = 1 - math.min( distSqr / DRAW_RADIUS_SQR, 1 )
        local alpha = 255 * factor*factor

        dxDrawMaterialSectionLine3D( 
            x, y, z + halfHeight, 
            x, y, z - halfHeight, 
            
            section.inv_grid_x * 50, section.inv_grid_y * 50,
            section.inv_grid_width * 50, section.inv_grid_height * 50,

            xrDropTexture, width, tocolor( 255, 255, 255, alpha ), false 
        )
    end
end

--[[
    Logic
]]
function createDropFromElement( element )
    local section = xrSettingsGetSection( getElementData( element, "cl", false ) )
    if section and type( section.inv_grid_width ) == "number" and type( section.inv_grid_y ) == "number" then
        local drop = {
            element = element,
            section = section
        }
        setmetatable( drop, xrDropMT )
        
        xrDrops[ element ] = drop

        local x, y, z = getElementPosition( element)
        xrDropStreamer:pushItem( drop, x, y, z )

        local text = xrGetLocaleText( _hashFn( section.inv_name ) )
        if text then
            setElementData( element, "name", text, false )
        end

        return drop
    end
end

function destroyDropElementRelated( element )
    local drop = xrDrops[ element ]
    if drop then
        xrDropStreamer:removeItem( drop )
        xrDrops[ element ] = nil
    end
end

function getNearestDrop( cx, cy )
    local minElement = nil
    local minDistSqr = nil
    for _, drop in ipairs( xrStreamedInDrops ) do
        local x, y = getElementPosition( drop.element )
        local distSqr = ( cx - x )^2 + ( cy - y )^2
        if not minDistSqr or distSqr < minDistSqr then 
            minDistSqr = distSqr
            minElement = drop.element
        end
    end

    return minElement, minDistSqr
end

local function onDropUpdate()
    local x, y, z = getElementPosition( localPlayer )
    xrDropStreamer:update( x, y, z )
end

local function onDropPreRender( dt )
    dt = dt / 1000

    for _, drop in ipairs( xrStreamedInDrops ) do
        drop:onUpdate( dt )
    end
end

local function onDropCreate()
    createDropFromElement( source )
end

local function onDropDestroy()
    if getElementType( source ) ~= "drop" then
        return
    end

    destroyDropElementRelated( source )
end

--[[
    Init
]]
function initDrops()
    xrDropStreamer = xrStreamer_new( 15, 1 )

    xrDropTexture = exports.sp_assets:xrLoadAsset( "ui_icon_equipment" )

    addEvent( "onClientDropCreate", true )
    addEventHandler( "onClientDropCreate", resourceRoot, onDropCreate )
    addEventHandler( "onClientElementDestroy", resourceRoot, onDropDestroy )
    addEventHandler( "onClientPreRender", root, onDropPreRender, false )
    setTimer( onDropUpdate, 200, 0 )

    for _, dropElement in ipairs( getElementsByType( "drop", resourceRoot ) ) do
        createDropFromElement( dropElement )
    end
end 
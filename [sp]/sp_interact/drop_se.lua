
local DROP_LIFETIME = 30
local DROP_SLICES_NUM = 10

--[[
    xrDropSlice
]]
xrDropSlice = {
    slices = {},
    sliceSizes = {},
    depth = 1,

    init = function( self, depth )
        self.depth = depth

        for i = 1, depth do
            table.insert( self.slices, {} )
            table.insert( self.sliceSizes, 0 )
        end
    end,
    insert = function( self, key, value )
        local slices = self.slices
        local sliceSizes = self.sliceSizes

        local minCount = nil
        local minIndex = nil
        for i = 1, self.depth do
            local tbl = slices[ i ]
            local tblSize = sliceSizes[ i ]
            if not minCount or tblSize < minCount then
                minCount = tblSize
                minIndex = i
            end
        end

        if minIndex and not slices[ minIndex ][ key ] then
            slices[ minIndex ][ key ] = value
            sliceSizes[ minIndex ] = sliceSizes[ minIndex ] + 1
        end
    end,
    find = function( self, key )
        local slices = self.slices
        
        local slice = nil
        for i = 1, self.depth do
            if slices[ i ][ key ] then
                slice = i
                break
            end
        end

        if slice then
            return slices[ slice ][ key ]
        end
    end,
    erase = function( self, key )
        local slices = self.slices
        local sliceSizes = self.sliceSizes
        
        local slice = nil
        for i = 1, self.depth do
            if slices[ i ][ key ] then
                slice = i
                break
            end
        end

        if slice and slices[ slice ][ key ] then
            slices[ slice ][ key ] = nil
            sliceSizes[ slice ] = sliceSizes[ slice ] - 1
        end
    end
}

--[[
    Logic
]]
local updateSliceIndex = 1
local function onUpdate()
    local now = getTickCount()

    local drops = xrDropSlice.slices[ updateSliceIndex ]
    for element, drop in pairs( drops ) do
        if now >= drop.endTime then
            xrDestroyDrop( drop )            
            break
        end
    end

    updateSliceIndex = updateSliceIndex + 1
    if updateSliceIndex > xrDropSlice.depth then
        updateSliceIndex = 1
    end
end

function xrDestroyDrop( drop )
    xrDropSlice:erase( drop.element )

    if isElement( drop.element ) then
        destroyElement( drop.element )
        drop.element = nil
    end

    exports.xritems:xrDestroyContainer( drop.containerId )
end

--[[
    Exports
]]
function xrDropItemAt( itemHash, containerId, x, y, z, lifeTime )    
    local element = createElement( "drop" )
    if element then
        if type( lifeTime ) ~= "number" then
            lifeTime = DROP_LIFETIME
        end

        local drop = {
            containerId = containerId,
            element = element,
            endTime = getTickCount() + lifeTime*1000
        }    

        setElementPosition( element, x, y, z )
        setElementData( element, "int", EHashes.DropClass )
        setElementData( element, "cl", itemHash )

        xrDropSlice:insert( element, drop )

        triggerClientEvent( "onClientDropCreate", element )

        return true
    end

    return false
end

function xrUseDropElementRelated( dropElement, player )
    local drop = xrDropSlice:find( dropElement )
    if drop then
        if exports.xritems:xrContainerMoveItems( drop.containerId, EHashes.SlotBag, player, EHashes.SlotBag ) then
            xrDestroyDrop( drop )
        end
    end
end

--[[
    Initialization
]]
function initDrops()
    xrDropSlice:init( DROP_SLICES_NUM )

    setTimer( onUpdate, 100, 0 )
end
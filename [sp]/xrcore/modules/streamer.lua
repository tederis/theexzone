local SIDE_SECTORS_NUM = 65000

--[[
    xrStreamer
]]
xrStreamer = {

}
xrStreamerMT = {
    __index = xrStreamer
}

function xrStreamer_new( sectorSize, radius )
    local worldWidth = SIDE_SECTORS_NUM * sectorSize
    local worldHeight = SIDE_SECTORS_NUM * sectorSize
    local worldX = -worldWidth / 2
    local worldY = -worldHeight / 2

    local streamer = {
        prevIndex = nil,
        sectorSize = sectorSize,
        worldX = worldX,
        worldY = worldY,
        worldWidth = worldWidth,
        worldHeight = worldHeight,
        radius = math.floor( radius ),
        sectors = {},
        indices = {}
    }

    return setmetatable( streamer, xrStreamerMT )
end

function xrStreamer:getSectorIndexFromWorld( x, y, z )
    local column = math.floor( ( x - self.worldX ) / self.sectorSize )
    local row = math.floor( ( y - self.worldY ) / self.sectorSize )

    return row * SIDE_SECTORS_NUM + column
end

function xrStreamer:getSectorIndexFromCell( column, row )
    return row * SIDE_SECTORS_NUM + column
end

function xrStreamer:getSectorWorldPosition( sectorIndex )
    local column = sectorIndex % SIDE_SECTORS_NUM
    local row = math.floor( sectorIndex / SIDE_SECTORS_NUM )

    local x = self.worldX + column*self.sectorSize
    local y = self.worldY + row*self.sectorSize

    return x, y, 0
end

function xrStreamer:getSectorCellPosition( sectorIndex )
    local column = sectorIndex % SIDE_SECTORS_NUM
    local row = math.floor( sectorIndex / SIDE_SECTORS_NUM )

    return column, row
end

function xrStreamer:getOrCreateSector( sectorIndex )
    local sector = self.sectors[ sectorIndex ]
    if not sector then
        sector = xrStreamerSector_new( self, sectorIndex )
        self.sectors[ sectorIndex ] = sector

        -- Если сектор с данным индесом в зоне стриминга
        if self.indices[ sectorIndex ] then
            sector:streamIn()
        end
    end

    return sector
end

function xrStreamer:isWithinStreamingRange( item, x, y, z )
    local sectorIndex
    if item.pos then
        sectorIndex = self:getSectorIndexFromWorld( item.pos:getX(), item.pos:getY(), item.pos:getZ() )
    elseif item.x and item.y and not item.z then
        sectorIndex = self:getSectorIndexFromWorld( item.x, item.y, item.z )
    elseif x and y and z then
        sectorIndex = self:getSectorIndexFromWorld( x, y, z )
    end

    if sectorIndex then
        return self.indices[ sectorIndex ] ~= nil
    end

    return false
end

function xrStreamer:pushItem( item, x, y, z )
    local sectorIndex
    if item.pos then
        sectorIndex = self:getSectorIndexFromWorld( item.pos:getX(), item.pos:getY(), item.pos:getZ() )
    elseif item.x and item.y and not item.z then
        sectorIndex = self:getSectorIndexFromWorld( item.x, item.y, item.z )
    elseif x and y and z then
        sectorIndex = self:getSectorIndexFromWorld( x, y, z )
    end

    if sectorIndex then
        local sector = self:getOrCreateSector( sectorIndex )
        sector:pushItem( item )
    end
end

function xrStreamer:removeItem( item )
    local sectorIndex = item.sectorIdx
    if not sectorIndex then
        return
    end

    local sector = self.sectors[ sectorIndex ]
    if sector then
        sector:removeItem( item )

        if #sector.items == 0 then
            self.sectors[ sectorIndex ] = nil
        end
    end
end

function xrStreamer:updateItem( item, x, y, z )
    local prevSectorIndex = item.sectorIdx
    local sectorIndex
    if item.pos then
        sectorIndex = self:getSectorIndexFromWorld( item.pos:getX(), item.pos:getY(), item.pos:getZ() )
    elseif item.x and item.y and not item.z then
        sectorIndex = self:getSectorIndexFromWorld( item.x, item.y, item.z )
    elseif x and y and z then
        sectorIndex = self:getSectorIndexFromWorld( x, y, z )
    end    

    -- Если сектор не изменился - выходим
    if not sectorIndex or prevSectorIndex == sectorIndex then
        return
    end

    -- Удаляем из предыдущего сектора
    local prevSector = self.sectors[ prevSectorIndex ]
    if prevSector then
        --[[
            Если новый сектор загружен - не нужно выгружать объект удалении
            из старого сектора
        ]]
        local newSectorState = self.indices[ sectorIndex ] ~= nil
        prevSector:removeItem( item, newSectorState )

        if #prevSector.items == 0 then
            self.sectors[ prevSectorIndex ] = nil
        end
    end

    -- Добавляем в новый сектор
    local sector = self:getOrCreateSector( sectorIndex )
    sector:pushItem( item )
end

function xrStreamer:update( x, y, z )
    local newIndex = self:getSectorIndexFromWorld( x, y, z )
    if newIndex == self.prevIndex then
        return
    end

    self:onSectorEnter( newIndex )    
end

function xrStreamer:onSectorEnter( sectorIndex )
    local sectors = self.sectors

    if self.prevIndex then
        local surrounding = self:getSurroundingSectors( self.prevIndex, self.radius )
        for _, index in ipairs( surrounding ) do
            local sector = sectors[ index ]
            if sector then
                sector.dirty = true
            end
            self.indices[ index ] = nil
        end
    end

    local surrounding = self:getSurroundingSectors( sectorIndex, self.radius )
    for _, index in ipairs( surrounding ) do
        local sector = sectors[ index ]
        if sector then
            sector.dirty = nil
            if not sector.streamedIn then
                sector:streamIn()
            end            
        end
        self.indices[ index ] = true
    end

    if self.prevIndex then
        surrounding = self:getSurroundingSectors( self.prevIndex, self.radius )
        for _, index in ipairs( surrounding ) do
            local sector = sectors[ index ]
            if sector and sector.dirty then
                sector.dirty = nil
                if sector.streamedIn then
                    sector:streamOut()
                end            
            end
        end
    end

    self.prevIndex = sectorIndex
end

function xrStreamer:getSurroundingSectors( sectorIndex, radius )
    radius = math.floor( radius )

    local result = {}
    
    local column, row = self:getSectorCellPosition( sectorIndex )
    column = column - radius
    row = row - radius

    local columnsNum = radius*2 + 1
    local rowsNum = radius*2 + 1

    for i = 0, columnsNum-1 do
        for j = 0, rowsNum-1 do            
            local sectorIndex = self:getSectorIndexFromCell( column + i, row + j )
            table.insert( result, sectorIndex )
        end
    end

    return result
end

--[[
    xrStreamerSector
]]
xrStreamerSector = {

}
xrStreamerSectorMT = {
    __index = xrStreamerSector
}

local _weakMT = {
    __mode = "kv"
}

function xrStreamerSector_new( streamer, index )
    local sector = {
        streamer = streamer,
        index = index,
        items = {},
        itemsLookup = setmetatable( {}, _weakMT )
    }

    return setmetatable( sector, xrStreamerSectorMT )
end

function xrStreamerSector:pushItem( item )
    if not item.sectorIdx and not self.itemsLookup[ item ] then
        table.insert( self.items, item )
        self.itemsLookup[ item ] = true
        item.sectorIdx = self.index

        if self.streamedIn and not item.streamedIn then
            item.streamedIn = true
            item:onStreamedIn()
        end

        --outputDebugString( "Объект в сектор " .. self.index .. " добавлен" )
    end    
end

function xrStreamerSector:removeItem( item, silent )
    if self.itemsLookup[ item ] then
        table.removeValue( self.items, item )
        self.itemsLookup[ item ] = nil
        item.sectorIdx = nil

        if not silent and self.streamedIn and item.streamedIn then
            item.streamedIn = false
            item:onStreamedOut()
        end

        --outputDebugString( "Объект из сектора " .. self.index .. " удален" )
    end
end

function xrStreamerSector:streamIn()
    if self.streamedIn then
        return
    end
    self.streamedIn = true

    for _, item in ipairs( self.items ) do
        if not item.streamedIn then
            item.streamedIn = true
            item:onStreamedIn()
        else
            outputDebugString( "Объект уже был загружен!", 2 )
        end
    end

    --outputDebugString( "Сектор " .. self.index .. " загружен( " .. tostring( self ) .. " )" )
end

function xrStreamerSector:streamOut()
    if not self.streamedIn then
        return
    end
    self.streamedIn = false

    for _, item in ipairs( self.items ) do
        if item.streamedIn then
            item.streamedIn = false
            item:onStreamedOut()
        else
            outputDebugString( "Объект уже был выгружен!", 2 )
        end
    end  
    
    --outputDebugString( "Сектор " .. self.index .. " выгружен" )
end
TreeRenderer = {

}
TreeRendererMT = {
    __index = TreeRenderer
}

local treeMeta = {

}

treeMeta = {
    [1] = { x = 593, y = 50 },
    [2] = { x = 803, y = 59 },
    [3] = { x = 363, y = 250 },
    [4] = { x = 827, y = 447 },
    [5] = { x = 146, y = 359 },
    [6] = { x = 908, y = 507 },
    [7] = { x = 144, y = 471 },
    [8] = { x = 37, y = 584 },
    [9] = { x = 223, y = 580 },
    [10] = { x = 361, y = 370 },
    [11] = { x = 382, y = 353 },
    [12] = { x = 907, y = 179 },
    [13] = { x = 613, y = 356 },
    [14] = { x = 544, y = 354 },
    [15] = { x = 544, y = 466 },
    [16] = { x = 461, y = 469 },
    [17] = { x = 636, y = 190 },
    [18] = { x = 680, y = 466 },
    [19] = { x = 795, y = 352 },
    [20] = { x = 605, y = 466 },
    [21] = { x = 953, y = 347 },
    [22] = { x = 686, y = 352 },
    [23] = { x = 1083, y = 351 },
    [24] = { x = 412, y = 203 },
    [25] = { x = 1220, y = 358 },
    [26] = { x = 832, y = 510 },
    [27] = { x = 1360, y = 367 },
    [28] = { x = 944, y = 343 },
    [29] = { x = 400, y = 237 },
    [30] = { x = 313, y = 181 },
    [31] = { x = 1073, y = 338 },
    [32] = { x = 1294, y = 489 },
    [33] = { x = 1413, y = 496 },
    [34] = { x = 1517, y = 371 },
    [35] = { x = 329, y = 187 },
    [36] = { x = 1524, y = 522 },
    [37] = { x = 83, y = 87 },
    [38] = { x = 92, y = 72 },
    [39] = { x = 1646, y = 516 },
    [40] = { x = 107, y = 72 },
    [41] = { x = 1248, y = 464 },
    [42] = { x = 1743, y = 517 },
    [43] = { x = 1487, y = 328 },
    [44] = { x = 137, y = 62 },
    [45] = { x = 1374, y = 154 },
    [46] = { x = 357, y = 237 },
    [47] = { x = 1383, y = 259 },
    [48] = { x = 1485, y = 479 },
    [49] = { x = 110, y = 53 },
    [50] = { x = 156, y = 71 },
    [51] = { x = 136, y = 80 },
    [52] = { x = 1605, y = 484 },
    [53] = { x = 96, y = 73 },
    [54] = { x = 111, y = 70 },
    [55] = { x = 1710, y = 326 },
    [56] = { x = 248, y = 109 },
    [57] = { x = 1740, y = 487 },
    [58] = { x = 0, y = 0 },
    [59] = { x = 0, y = 0 },
    [60] = { x = 0, y = 0 },
    [61] = { x = 0, y = 0 },
    [62] = { x = 0, y = 0 },
    [63] = { x = 0, y = 0 },
    [64] = { x = 0, y = 0 },
    [65] = { x = 0, y = 0 },
    [66] = { x = 0, y = 0 },
    [67] = { x = 0, y = 0 },
    [68] = { x = 0, y = 0 },
    [69] = { x = 0, y = 0 },
    [70] = { x = 0, y = 0 },
    [71] = { x = 0, y = 0 },
    [72] = { x = 0, y = 0 },
    [73] = { x = 0, y = 0 },
    [74] = { x = 0, y = 0 },
    [75] = { x = 0, y = 0 },
    [76] = { x = 0, y = 0 },
    [77] = { x = 0, y = 0 },
    [78] = { x = 0, y = 0 },
    [79] = { x = 0, y = 0 },
    [80] = { x = 0, y = 0 },
    [81] = { x = 0, y = 0 },
    [82] = { x = 0, y = 0 },
    [83] = { x = 0, y = 0 },
    [84] = { x = 0, y = 0 },
    [85] = { x = 0, y = 0 },
    [86] = { x = 0, y = 0 },
    [87] = { x = 0, y = 0 },
    [88] = { x = 0, y = 0 },
    [89] = { x = 0, y = 0 },
    [90] = { x = 0, y = 0 },
    [91] = { x = 0, y = 0 },
    [92] = { x = 0, y = 0 },
    [93] = { x = 0, y = 0 },
    [94] = { x = 0, y = 0 },
    [95] = { x = 0, y = 0 },
    [96] = { x = 0, y = 0 },
    [97] = { x = 0, y = 0 },
    [98] = { x = 0, y = 0 },
    [99] = { x = 0, y = 0 },
    [100] = { x = 0, y = 0 },
    }

addCommandHandler( "printtree",
    function()
        local str = "treeMeta = {\n"
        for i, nodeMeta in ipairs( treeMeta ) do
            str = str .. "[" .. i .. "] = { x = " .. nodeMeta.x .. ", y = " .. nodeMeta.y .. " },\n" 
        end
        str = str .. "}"

        setClipboard( str )
    end
)



local NODE_WIDTH = 100
local NODE_HEIGHT = 70

function TreeRenderer:new( tree )
    local renderer = {
        tree = tree
    }

    return setmetatable( renderer, TreeRendererMT )
end

function TreeRenderer:draw( node )
    local nodeMeta = treeMeta[ node.idx ]
    local x = nodeMeta.x or 0
    local y = nodeMeta.y or 0    

    local parent = node.parent
    if parent then
        local parentMeta = treeMeta[ parent.idx ]
        local px = parentMeta.x or 0
        local py = parentMeta.y or 0
        dxDrawLine( px + NODE_WIDTH/2, py + NODE_HEIGHT/2, x + NODE_WIDTH/2, y + NODE_HEIGHT/2, node.running and tocolor( 255, 9, 9 ) or tocolor( 200, 109, 9, 150 ) )
    end

    dxDrawRectangle( x, y, NODE_WIDTH, NODE_HEIGHT, node.running and tocolor( 255, 180, 210 ) or tocolor( 200, 180, 210, 150 ) )
    dxDrawText( tostring( node.index ) .. " : " .. tostring( node.name or node.type ), x, y, x + NODE_WIDTH, y + NODE_HEIGHT, tocolor( 255, 255, 255 ), 1, "default", "center", "center" )

    for _, child in ipairs( node.children ) do
        self:draw( child )
    end
end

function TreeRenderer:onCursorClick( state, ax, ay )
    if state == "down" then
        self.moveableIdx = self.selectedIdx
    else
        self.moveableIdx = nil
    end
end

local function testRect( cx, cy, rx, ry, rw, rh )
    return cx >= rx and cx <= rx + rw and cy >= ry and cy <= ry + rh
end
function TreeRenderer:onCursorMove( ax, ay )
    if self.moveableIdx then
        local nodeMeta = treeMeta[ self.moveableIdx ]
        nodeMeta.x = ax
        nodeMeta.y = ay

        return
    end

    for idx, _ in pairs( self.tree.nodes ) do
        local nodeMeta = treeMeta[ idx ]
        if testRect( ax, ay, nodeMeta.x, nodeMeta.y, NODE_WIDTH, NODE_HEIGHT ) then
            self.selectedIdx = idx

            return
        end
    end

    self.selectedIdx = nil
end

--[[
    DEBUG
]]
if G_DEBUG then
    local _targetRenderer = nil
    local _treeRendererEnabled = false

    function setDebugTargetAgent( agent )
        local tree = agent.tree

        _targetRenderer = TreeRenderer:new( tree )
    end

    addCommandHandler( "treeviewer",
        function()
            _treeRendererEnabled = not _treeRendererEnabled
        end
    )

    addEventHandler( "onClientRender", root,
        function()
            if _treeRendererEnabled and _targetRenderer then
                _targetRenderer:draw( _targetRenderer.tree )
            end
        end
    , false )

    addEventHandler( "onClientClick", root,
        function( button, state, ax, ay )
            if not isCursorShowing() then
                return
            end

            if _treeRendererEnabled and _targetRenderer then
                _targetRenderer:onCursorClick( state, ax, ay )
            end
        end
    , false )

    addEventHandler( "onClientCursorMove", root,
        function( _, _, ax, ay )
            if not isCursorShowing() then
                return
            end

            if _treeRendererEnabled and _targetRenderer then
                _targetRenderer:onCursorMove( ax, ay )
            end
        end
    , false )
end
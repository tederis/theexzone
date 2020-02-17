local totalNum = 20
local percent = 0.3
local items = {}
for i = 1, totalNum do
    items[ math.random() ] = { i = i }
end

local wasteNum = math.floor( totalNum * percent )
for i = 1, wasteNum do
    local id, item = next( items )
    if id then
        print( id .. ", " .. item.i )
        items[ id ] = nil
    end
end
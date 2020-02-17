--[[
    xrLocaleDict
]]
local xrLocaleDict = {

}

local function xrLoadStringNode( xmlnode )
    local id = xmlNodeGetAttribute( xmlnode, "id" )
    if id then
        local str = "NULL"

        local textNode = xmlFindChild( xmlnode, "text", 0 )
        if textNode then
            str = xmlNodeGetValue( textNode )
        end

        xrLocaleDict [ _hashFn( id ) ] = str
    end
end

function xrIncludeLocaleFile( name )
    local xml = xmlLoadFile( ":xrcore/config/text/rus/" .. name .. ".xml", true )
    if not xml then
        return
    end

    for _, xmlnode in ipairs( xmlNodeGetChildren( xml ) ) do
        if xmlNodeGetName( xmlnode ) == "string" then
            xrLoadStringNode( xmlnode )
        end
    end

    xmlUnloadFile( xml )
end

function xrGetLocaleText( idHash )
    local str = xrLocaleDict[ idHash ]
    return str
end
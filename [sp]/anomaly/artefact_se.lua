Artefact = {

}
ArtefactMT = {
    __index = Artefact
}

local AA_ID = 1
local AA_TYPEHASH = 2
local AA_POS = 3

function Artefact.create( zone, typeHash, pos, artId )
    local artSection = xrSettingsGetSection( typeHash )
	if artSection then
        local artefact = {
            section = artSection,
            typeHash = typeHash,
            zone = zone,
            pos = pos,
            id = artId
        }

        return setmetatable( artefact, ArtefactMT )
    end
end

function Artefact:destroy( )
   
end

function Artefact:write()
    local out = {}
    
    out[ AA_ID ] = self.id
    out[ AA_TYPEHASH ] = self.typeHash
    local pos = self.pos
    out[ AA_POS ] = { pos:getX(), pos:getY(), pos:getZ() }

    return out
end

function Artefact:toggleVisibility( state )

end

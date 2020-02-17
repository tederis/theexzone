Material = {}

function Material.load( xml )
    local mat = {

    }

    local child = xmlFindChild( xml, "texture", 0 )
    if child then
        local name = xmlNodeGetAttribute( child, "name" )
        mat.texture = dxCreateTexture( "textures/" .. name ) 
        if not mat.texture then
            outputDebugString( "Во время загрузки текстуры произошла ошибка!( " .. name .. ")", 2 )
            return
        end
    else
        outputDebugString( "Наименовани текстуры не было найдено!", 2 )
        return
    end

    mat.width, mat.height = dxGetMaterialSize( mat.texture )

    local child = xmlFindChild( xml, "shader", 0 )
    if child then
        local name = xmlNodeGetAttribute( child, "name" )
        local rt = xmlNodeGetAttribute( child, "rt" )

        mat.shader = dxCreateShader( "shaders/" .. name, 0, 0, false ) 
        if not mat.shader then
            outputDebugString( "Во время загрузки шейдера произошла ошибка!", 2 )
            return
        end
    else
        outputDebugString( "Наименовани шейдера не было найдено!", 2 )
        return
    end  
    
    dxSetShaderValue( mat.shader, "Tex0", mat.texture )

    return mat
end


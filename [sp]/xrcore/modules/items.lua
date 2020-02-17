function xrGetContainerItemSection( container, item )
    local itemHash = exports[ "xritems" ]:xrGetContainerItemData( container, item, EIA_TYPE )
    if itemHash then	
        return xrSettingsGetSection( itemHash )
    end

    return false
end
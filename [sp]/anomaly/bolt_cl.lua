xrBolts = {

}

local BOLT_LIFETIME = 6000
local BOLT_MODEL = 6219

addEventHandler( "onClientProjectileCreation", root,
    function( creator )
        if creator ~= localPlayer or getProjectileType( source ) ~= 16 then
            return
        end

        setProjectileCounter( source, BOLT_LIFETIME*10 )

        local x, y, z = getElementPosition( source )
        local object = createObject( BOLT_MODEL, x, y, z )
        
        table.insert( xrBolts, {
            element = source,
            object = object,
            lifeTime = 0,
            colshapes = {}
        } )        
    end
)

local function onBoltsPulse()
    for i = #xrBolts, 1, -1 do
        local bolt = xrBolts[ i ]
        local lifeTime = bolt.lifeTime + 500
        if lifeTime > BOLT_LIFETIME then
            setElementPosition( bolt.element, 3000, 3000, 100 )
            destroyElement( bolt.element )
            destroyElement( bolt.object )
            table.remove( xrBolts, i )
        else
            bolt.lifeTime = lifeTime
        end
    end
end

local function onBoltsUpdate( dt )
    for _, bolt in ipairs( xrBolts ) do
        local colshapes = bolt.colshapes
        local element = bolt.element
        local boltPos = element.position
        local boltRot = element.rotation

        for _, anomaly in ipairs( xrStreamedInAnomalies ) do
            local colshape = anomaly.col

            if not colshapes[ colshape ] and isInsideColShape( colshape, boltPos ) then
                triggerServerEvent( EServerEvents.onAnomalyBoltHit, localPlayer, anomaly.id )
                colshapes[ colshape ] = true
            end
        end

        setElementPosition( bolt.object, boltPos )
        setElementRotation( bolt.object, boltRot )
    end
end

function initBolts()
    setTimer( onBoltsPulse, 500, 0 )
    addEventHandler( "onClientPreRender", root, onBoltsUpdate, false )
end
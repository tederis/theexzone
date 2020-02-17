--[[
    Имплементация Behavior Tree, принцип действия которого взят из Unreal Engine 4.
    Документацию по деревьям данного рода можно найти на официальном сайте движка.

    - TEDERIs
]]

G_DEBUG = false

BEHAVIOR_OK = 1
BEHAVIOR_FAILED = 2
BEHAVIOR_FINISHED = 3
BEHAVIOR_DEFERRED = 4

BLACKBOARD_ABORT_NONE = 1
BLACKBOARD_ABORT_SELF = 2
BLACKBOARD_ABORT_LOW_PRIORITY = 3
BLACKBOARD_ABORT_BOTH = 4

--[[
    Blackboard
]]
Blackboard = {
    type = "blackboard"
}
BlackboardMT = {
    __index = Blackboard
}

function Blackboard:new()
    local board = {
        keys = {}
    }

    return setmetatable( board, BlackboardMT )
end

function Blackboard:clear()
    self.keys = {}
end

function Blackboard:setValue( key, value )
    local keyData = self.keys[ key ]
    if keyData then
        if keyData.value ~= value then
            keyData.value = value

            self:triggerEvent( key, keyData )
        end
    else
        self.keys[ key ] = {
            value = value,
            handlers = {}
        }

        self:triggerEvent( key, self.keys[ key ] )
    end
end

function Blackboard:getValue( key )
    local keyData = self.keys[ key ]
    if keyData then
        return keyData.value
    end

    return false
end

function Blackboard:triggerEvent( key, keyData )
    for _, handlerData in ipairs( keyData.handlers ) do
        handlerData.fn( handlerData.node, keyData.value )
    end
end

function Blackboard:bindEvent( key, node, fn )
    local keyData = self.keys[ key ]
    if keyData then
        table.insert( keyData.handlers, { node = node, fn = fn } )
    else
        self.keys[ key ] = {
            value = nil,
            handlers = {
                { node = node, fn = fn }
            }
        }
    end
end

function Blackboard:unbindEvent( key, node )
    local keyData = self.keys[ key ]
    if keyData then
        for i, handlerData in ipairs( keyData.handlers ) do
            if handlerData.node == node then
                table.remove( keyData.handlers, i )
                break
            end
        end
    end
end

--[[
    Node
]]
Node = {

}
NodeMT = {
    __index = Node
}

function Node:create()
    local node = {
        children = {},
        decorators = {},
        services = {},
        enabled = true,
        running = false,
        current = nil,
        index = nil,
        blackboard = nil,
        tree = nil
    }
    setmetatable( node, NodeMT )

    return node
end

function Node:traverse()
    local tree = self.tree

    local nextIndex = tree.lastIndex + 1

    self.idx = nextIndex
    tree.lastIndex = nextIndex
    tree.nodes[ nextIndex ] = self

    for _, decorator in ipairs( self.decorators ) do
        decorator:traverse()
    end

    for _, child in ipairs( self.children ) do
        child:traverse()
    end

    for _, service in ipairs( self.services ) do
        service:traverse()
    end
end

function Node:run()
    local enabled = true
    for i, decorator in ipairs( self.decorators ) do
        if not decorator:evaluate() then
            enabled = false
            break
        end
    end

    self.enabled = enabled

    if self.running then
        outputDebugString( "Нод " .. tostring( self.name or self.type ) .. " уже запушен!", 2 )
        return BEHAVIOR_FAILED
    end

    if enabled then
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function Node:stop( forced )
    if not self.running then
        outputDebugString( "Нод " .. tostring( self.name or self.type ) .. " уже остановлен!", 2 )
        return BEHAVIOR_FAILED
    end    

    return BEHAVIOR_OK
end

function Node:onChildFinish( child )
    
end

function Node:onChildChanged( child )

end

function Node:onDecoratorChanged( abortType )
    local enabled = true
    for i, decorator in ipairs( self.decorators ) do
        if not decorator.enabled then
            enabled = false
            break
        end
    end

    self.enabled = enabled

    if abortType > BLACKBOARD_ABORT_NONE then
        local parent = self.parent
        parent:onChildChanged( self, abortType )
    end
end

function Node:onInit()
    for i, decorator in ipairs( self.decorators ) do
        decorator:onInit()
    end

    for i, child in ipairs( self.children ) do
        child:onInit()
    end
end

function Node:onDestroy()
    for i, decorator in ipairs( self.decorators ) do
        decorator:onDestroy()
    end

    for i, child in ipairs( self.children ) do
        child:onDestroy()
    end
end

function Node:onStarted()
    if self.running then
        return
    end

    self.running = true

    for _, service in ipairs( self.services ) do
        service:onStart()
    end

    for _, decorator in ipairs( self.decorators ) do
        decorator:onStart()
    end
end

function Node:onStopped()
    if not self.running then
        return
    end

    self.running = false

    for _, service in ipairs( self.services ) do
        service:onStop()
    end
    
    for _, decorator in ipairs( self.decorators ) do
        decorator:onStop()
    end
end

function Node:setTimer( fn, duration )
    local time = self.agent.time
    time:delay( self, fn, duration )
end

function Node:killTimer( fn )
    local time = self.agent.time
    time:undelay( self, fn )
end

--[[
    BehaviorTree
]]
BehaviorTree = {

}
setmetatable( BehaviorTree, NodeMT )
BehaviorTreeMT = {
    __index = BehaviorTree
}

function BehaviorTree:new( blackboard, agent )
    local tree = Node:create()

    tree.blackboard = blackboard
    tree.lastIndex = 0
    tree.agent = agent
    tree.tree = tree
    tree.lastRefreshType = getTickCount()
    tree.nodes = {
        -- Lookup-таблица всех нодов дерева
    }

    setmetatable( tree, BehaviorTreeMT )
    
    return tree
end

function BehaviorTree:insert( node )
    if node.type == "action" or node.type == "selector" or node.type == "sequence" then
        table.insert( self.children, node )
        node.index = #self.children        
    else
        outputDebugString( "Попытка вставки узла запрещенного(неопознанного) типа (" .. tostring( node.type ) .. ")", 2 )
        return false
    end

    node.parent = self    
    node.blackboard = self.blackboard
    node.tree = self.tree
    node.agent = self.agent

    return node
end

function BehaviorTree:run()
    local children = self.children

    if Node.run( self ) == BEHAVIOR_OK then
        --[[
            Сперва инициализируем все ноды
        ]]
        for _, child in ipairs( children ) do
            child:onInit()
        end

        --[[
            Затем делаем первую выборку и запуск
        ]]
        for _, child in ipairs( children ) do
            local invokeCode = child:run()

            if invokeCode == BEHAVIOR_OK then
                self.current = child
                child:onStarted()

                break
            end
        end

        self:onStarted()

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function BehaviorTree:stop( forced )
    local children = self.children
    local current = self.current    

    if Node.stop( self, forced ) == BEHAVIOR_OK then
        --[[
            Останавливаем текущего исполняемого наследника
        ]]
        if current then
            current:stop( forced )
            current:onStopped()
            self.current = nil
        end

        --[[
            Говорим нодам дерева об остановке всего дерева
        ]]
        for _, child in ipairs( children ) do
            child:onDestroy()
        end

        self:onStopped()

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function BehaviorTree:update( dt )
    local now = getTickCount()
    if now - self.lastRefreshType > 1000 then
        self.lastRefreshType = now

        -- Если дерево было заморожено - пытаемся запустить его еще раз
        if not self.current then
            self:onChildFinish()
        end
    end

    local action = self.action
    if action then
        action:update( dt )
    end
end

function BehaviorTree:onActionStart( action )
    self.action = action
end

function BehaviorTree:onActionStop( action )
    self.action = nil
end

function BehaviorTree:onChildFinish( child )
    local children = self.children
    local current = self.current    

    if G_DEBUG then
        outputDebugString( "On three finished" )
    end

    if child and child == current then
        child:stop( false )
        child:onStopped()
        self.current = nil        
    end

    for _, child in ipairs( children ) do
        local invokeCode = child:run()
        
        if invokeCode == BEHAVIOR_OK then
            self.current = child
            child:onStarted()

            break
        end
    end
end

function BehaviorTree:onChildChanged( child, abortType )
    local children = self.children
    local current = self.current   
    
    if child == current then        
        child:stop( false )
        child:onStopped()
        
        for _, child in ipairs( children ) do
            local invokeCode = child:run()
            
            if invokeCode == BEHAVIOR_OK then
                self.current = child
                child:onStarted()

                return
            end
        end
    end
end

--[[
    Selector
]]
Selector = {
    type = "selector"
}
setmetatable( Selector, NodeMT )
SelectorMT = {
    __index = Selector
}

function Selector:new( name )
    local selector = Node:create()

    selector.name = name
    selector.deferredStop = false

    setmetatable( selector, SelectorMT )
    
    return selector
end

function Selector:insert( node )
    if node.type == "decorator" then
        table.insert( self.decorators, node )
    elseif node.type == "service" then
        table.insert( self.services, node )
    elseif node.type == "action" or node.type == "selector" or node.type == "sequence" then
        table.insert( self.children, node )   
        node.index = #self.children
    else
        outputDebugString( "Попытка вставки узла запрещенного(неопознанного) типа" )
        return false
    end

    node.parent = self    
    node.blackboard = self.blackboard
    node.tree = self.tree
    node.agent = self.agent

    return node
end

function Selector:run()
    local children = self.children

    if G_DEBUG then
        outputDebugString( "Trying to run " .. tostring( self.name ) )
    end

    if self.deferredStop then
        return BEHAVIOR_FAILED
    end

    if Node.run( self ) == BEHAVIOR_OK then
        for i, child in ipairs( children ) do
            local invokeCode = child:run()

            if invokeCode == BEHAVIOR_OK then
                self.current = child
                child:onStarted()

                return BEHAVIOR_OK
            elseif invokeCode == BEHAVIOR_FINISHED then

                return BEHAVIOR_FINISHED
            end
        end

        return BEHAVIOR_FAILED
    else
        return BEHAVIOR_FAILED
    end
end

function Selector:onStarted()
    Node.onStarted( self )
end

function Selector:onStopped()
    Node.onStopped( self )
end

function Selector:stop( forced )
    if self.deferredStop and not forced then
        return BEHAVIOR_FAILED
    end 

    if Node.stop( self, forced ) == BEHAVIOR_OK then
        local current = self.current
        
        if current then
            local stopCode = current:stop( forced )

            if stopCode == BEHAVIOR_OK or forced then
                self.current = nil
                current:onStopped()

                return BEHAVIOR_OK
            elseif stopCode == BEHAVIOR_DEFERRED then
                self.deferredStop = true

                return BEHAVIOR_DEFERRED
            end
        end

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function Selector:onChildFinish( child )
    local parent = self.parent
    local current = self.current    

    if child == current then
        if self.deferredStop then
            self.deferredStop = false
            
            child:onStopped()
            self.current = nil

            parent:onChildFinish( self )
    
            return
        end

        self.current = nil
        child:onStopped()

        --[[
            При всяком завершении работы наследника -
            считаем что это было успешно и говорим об этом родителю
        ]]
        parent:onChildFinish( self )
    end
end

function Selector:onChildChanged( child, abortType )
    local parent = self.parent
    local current = self.current
    local children = self.children

    if self.deferredStop then
        return
    end

    if current then
        if child.index > current.index then
            return
        end
        
        if child == current then
            if abortType ~= BLACKBOARD_ABORT_SELF and abortType ~= BLACKBOARD_ABORT_BOTH then  
                return
            end
        else
            if not child.enabled or ( abortType ~= BLACKBOARD_ABORT_LOW_PRIORITY and abortType ~= BLACKBOARD_ABORT_BOTH ) then
                return
            end
        end

        --[[
            При изменении текущего нода или любого нода левее - пытаемся перезапустить поток
        ]]
        local stopCode = current:stop( false )

        if stopCode == BEHAVIOR_OK then
            self.current = nil
            current:onStopped()
            
            for i = child.index, #children do
                local nextChild = children[ i ]
                local invokeCode = nextChild:run()

                if invokeCode == BEHAVIOR_OK then
                    self.current = nextChild
                    nextChild:onStarted()

                    return
                elseif invokeCode == BEHAVIOR_FINISHED then

                    break
                end
            end

            parent:onChildFinish( self )
        elseif stopCode == BEHAVIOR_DEFERRED then
            self.deferredStop = true
        end

    --[[
        Текущего нода на исполнении нет? Идем выше по дереву
    ]]
    elseif abortType == BLACKBOARD_ABORT_LOW_PRIORITY then
        if parent.enabled then
            parent:onChildChanged( self, abortType )
        end
    end
end

--[[
    Sequence
]]
Sequence = {
    type = "sequence"
}
setmetatable( Sequence, NodeMT )
SequenceMT = {
    __index = Sequence
}

function Sequence:new( name )
    local sequence = Node:create()

    sequence.name = name
    sequence.deferredStop = false

    setmetatable( sequence, SequenceMT )
    
    return sequence
end

function Sequence:insert( node )
    if node.type == "decorator" then
        table.insert( self.decorators, node )
    elseif node.type == "service" then
        table.insert( self.services, node )
    elseif node.type == "action" or node.type == "selector" or node.type == "sequence" then
        table.insert( self.children, node )   
        node.index = #self.children   
    else
        outputDebugString( "Попытка вставки узла запрещенного(неопознанного) типа" )
        return false 
    end

    node.parent = self    
    node.blackboard = self.blackboard
    node.tree = self.tree
    node.agent = self.agent

    return node
end

function Sequence:run()
    local children = self.children   

    if G_DEBUG then
        outputDebugString( "Trying to run " .. tostring( self.name ) )
    end

    if self.deferredStop then
        return BEHAVIOR_FAILED
    end

    if Node.run( self ) == BEHAVIOR_OK then
        for _, child in ipairs( children ) do
            local invokeCode = child:run()

            if invokeCode == BEHAVIOR_OK then
                self.current = child
                child:onStarted()

                return BEHAVIOR_OK
            elseif invokeCode == BEHAVIOR_FAILED then

                return BEHAVIOR_FAILED
            end
        end

        return BEHAVIOR_FINISHED
    else
        return BEHAVIOR_FAILED
    end
end

function Sequence:onStarted()
    Node.onStarted( self )
end

function Sequence:onStopped()
    Node.onStopped( self )
end

function Sequence:stop( forced )
    if self.deferredStop and not forced then
        return BEHAVIOR_FAILED
    end 

    if Node.stop( self, forced ) == BEHAVIOR_OK then
        local current = self.current
        
        if current then
            local stopCode = current:stop( forced )

            if stopCode == BEHAVIOR_OK or forced then
                self.current = nil
                current:onStopped()

                return BEHAVIOR_OK
            elseif stopCode == BEHAVIOR_DEFERRED then
                self.deferredStop = true

                return BEHAVIOR_DEFERRED
            end
        end

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function Sequence:onChildFinish( child )
    local parent = self.parent
    local current = self.current
    local children = self.children       

    if child == current then
        if self.deferredStop then
            self.deferredStop = false
    
            child:onStopped()
            self.current = nil

            parent:onChildFinish( self )
    
            return
        end

        child:onStopped()
        self.current = nil

        for i = child.index + 1, #children do
            local nextChild = children[ i ]
            local invokeCode = nextChild:run()

            if invokeCode == BEHAVIOR_OK then
                self.current = nextChild
                nextChild:onStarted()

                return
            elseif invokeCode == BEHAVIOR_FAILED then

                break
            end
        end

        --[[
            Если правее нет нодов или при запуске произошла ошибка -
            считаем что выполнение нода завершено и говорим об этом родителю
        ]]
        parent:onChildFinish( self )
    end
end

function Sequence:onChildChanged( child, abortType )
    local parent = self.parent
    local current = self.current
    local children = self.children

    if self.deferredStop then
        return
    end

    if child == current and abortType == BLACKBOARD_ABORT_SELF then
        --[[
            Если текущий нод все еще активен -
            пытаемся его перезапустить
        ]]
        if child.enabled then
            local stopCode = child:stop( false )

            if stopCode == BEHAVIOR_OK then
                child:onStopped()
                self.current = nil

                for i = child.index, #children do
                    local nextChild = children[ i ]
                    local invokeCode = nextChild:run()
        
                    if invokeCode == BEHAVIOR_OK then
                        self.current = nextChild
                        nextChild:onStarted()
        
                        return
                    elseif invokeCode == BEHAVIOR_FAILED then
        
                        return
                    end
                end
            end

            --[[
                При неудачном перезапуске или деактивации нода - 
                считаем что выполнение нода завершено и говорим об этом родителю
            ]]
            parent:onChildFinish( self )
        elseif stopCode == BEHAVIOR_DEFERRED then
            self.deferredStop = true
        end
    end
end

--[[
    Action
]]
Action = {
    name = "action",
    type = "action"
}
setmetatable( Action, NodeMT )
ActionMT = {
    __index = Action
}

function Action:new()
    local action = Node:create()
    
    setmetatable( action, ActionMT )
    
    return action
end

function Action:insert( node )
    if node.type == "decorator" then
        table.insert( self.decorators, node )
    elseif node.type == "service" then
        table.insert( self.services, node ) 
    else
        outputDebugString( "Попытка вставки узла запрещенного(неопознанного) типа" )
        return false
    end

    node.parent = self    
    node.blackboard = self.blackboard
    node.tree = self.tree
    node.agent = self.agent

    return node
end

function Action:run()
    if Node.run( self ) == BEHAVIOR_OK then
        if G_DEBUG then
            outputDebugString( "Trying to run " .. tostring( self.name ) )
        end

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function Action:stop( forced )
    if Node.stop( self, forced ) == BEHAVIOR_OK then 
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function Action:update( dt )
    -- Виртуальная функция
end

function Action:onStarted()
    Node.onStarted( self )

    -- Говорим дереву о запуске действия
    self.tree:onActionStart( self ) 

    -- Для отладки
    setElementData( self.agent.ped, "dtag", tostring( self.name or self.type ), false )
end

function Action:onStopped()
    Node.onStopped( self )

     -- Говорим дереву о запуске действия
    self.tree:onActionStop( self ) 

    -- Для отладки
    setElementData( self.agent.ped, "dtag", "", false )
end

--[[
    Service
]]
Service = {
    type = "service"
}
setmetatable( Service, NodeMT )
ServiceMT = {
    __index = Service
}

function Service:new()
    local service = Node:create()

    setmetatable( service, ServiceMT )
    
    return service
end

function Service:onStart()

end

function Service:onStop()

end

--[[
    Decorator
]]
Decorator = {
    type = "decorator"
}
setmetatable( Decorator, NodeMT )
DecoratorMT = {
    __index = Decorator
}

function Decorator:new()
    local decorator = Node:create()

    decorator.enabled = false

    setmetatable( decorator, DecoratorMT )
    
    return decorator
end

function Decorator:onInit()

end

function Decorator:onDestroy()

end

--[[
    ActionAttack
]]
ActionTimer = {
    name = "timer"
}
setmetatable( ActionTimer, ActionMT )
ActionTimerMT = {
    __index = ActionTimer
}

function ActionTimer:new( period )
    local action = Action:new()

    action.period = tonumber( period ) or 1

    setmetatable( action, ActionTimerMT )
    
    return action
end

function ActionTimer:run()
    if Action.run( self ) == BEHAVIOR_OK then
        self:setTimer( ActionTimer.onTimerEvent, self.period )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionTimer:stop( forced )
    if Node.stop( self, forced ) == BEHAVIOR_OK then
        self:killTimer( ActionTimer.onTimerEvent )

        return BEHAVIOR_OK
    end
      
    return BEHAVIOR_FAILED
end

function ActionTimer:onTimerEvent()
    local parent = self.parent
    parent:onChildFinish( self )
end

--[[
    DecoratorBlackboard
]]
BLACKBOARD_RESULT_CHANGE = 1
BLACKBOARD_VALUE_CHANGE = 2

BLACKBOARD_THRESHOLD_AND = 1
BLACKBOARD_THRESHOLD_OR = 2

local function _defaultBackboardOperator( value )
    return value ~= false and value ~= nil
end

DecoratorBlackboard = {

}
setmetatable( DecoratorBlackboard, DecoratorMT )
DecoratorBlackboardMT = {
    __index = DecoratorBlackboard
}

function DecoratorBlackboard:new( key )
    local decorator = Decorator:new()

    decorator.prevValue = nil
    decorator.notifyType = BLACKBOARD_RESULT_CHANGE
    decorator.abortType = BLACKBOARD_ABORT_NONE
    decorator.thresholdMode = BLACKBOARD_THRESHOLD_OR
    decorator.key = key
    decorator.fn = _defaultBackboardOperator
    decorator.inversed = false
    decorator.lastTime = getCurrentTime()
    decorator.delay = 0
    decorator.dirty = false
    decorator.nextValue = nil

    setmetatable( decorator, DecoratorBlackboardMT )
    
    return decorator
end

function DecoratorBlackboard:setDelay( delay )
    self.delay = tonumber( delay ) or 0

    return self
end

function DecoratorBlackboard:setInversed( inversed )
    self.inversed = inversed

    return self
end

function DecoratorBlackboard:setNotifyType( notifyType )
    if notifyType == 1 or notifyType == 2 then
        self.notifyType = notifyType
    else
        self.notifyType = BLACKBOARD_RESULT_CHANGE
    end

    return self
end

function DecoratorBlackboard:setAbortType( abortType )
    if abortType >= 1 and abortType <= 4 then
        self.abortType = abortType
    else
        self.abortType = BLACKBOARD_ABORT_NONE
    end

    return self
end

function DecoratorBlackboard:setCallback( fn )
    if type( fn ) == "function" then
        self.fn = fn
    else
        self.fn = _defaultBackboardOperator
    end

    return self
end

function DecoratorBlackboard:setThreshold( startValue, stopValue, mode )
    self.startValue = tonumber( startValue )
    self.endValue = tonumber( endValue )
    self.thresholdMode = mode == 2 and BLACKBOARD_THRESHOLD_AND or BLACKBOARD_THRESHOLD_OR
end

function DecoratorBlackboard:evaluate()
    return self.enabled
end

-- Вызывается при первом запуске дерева
function DecoratorBlackboard:onInit()
    local blackboard = self.blackboard

    local value = blackboard:getValue( self.key )

    -- Функтор
    local result = self.fn( value, self.prevValue )
    if self.inversed then
        result = not result
    end

    do
        self.prevValue = value
        self.enabled = result
        self.lastTime = getCurrentTime()
        self.dirty = false
        self.nextValue = nil
    end

    blackboard:bindEvent( self.key, self, DecoratorBlackboard.onValueChanged )

    if self.delay > 0.01 then
        self:setTimer( DecoratorBlackboard.onTimerEvent, self.delay )
    end
end

-- Вызывается при уничтожении всего дерева
function DecoratorBlackboard:onDestroy()
    local blackboard = self.blackboard
    blackboard:unbindEvent( self.key, self )

    self:killTimer( DecoratorBlackboard.onTimerEvent )
end

function DecoratorBlackboard:onStart()    
end

function DecoratorBlackboard:onStop()    
end

function DecoratorBlackboard:promoteValue( newValue )
    local parent = self.parent
    
    -- Функтор
    local enabled = self.fn( newValue, self.prevValue )
    if self.inversed then
        enabled = not enabled
    end

    local silent = true
    if ( self.notifyType == BLACKBOARD_VALUE_CHANGE and newValue ~= self.prevValue ) or ( self.notifyType == BLACKBOARD_RESULT_CHANGE and enabled ~= self.enabled ) then  
        silent = false
    end    

    self.prevValue = newValue
    self.enabled = enabled

    if silent then
        parent:onDecoratorChanged( BLACKBOARD_ABORT_NONE )
    else
        parent:onDecoratorChanged( self.abortType )
    end
end

function DecoratorBlackboard:onValueChanged( newValue )
    self.nextValue = newValue
    self.dirty = true

    local now = getCurrentTime()
    if now - self.lastTime >= self.delay then
        self.lastTime = now

        self:promoteValue( newValue )
        self.dirty = false
    end
end

function DecoratorBlackboard:onTimerEvent()
    if not self.dirty then
        return
    end

    local now = getCurrentTime()
    if now - self.lastTime >= self.delay then
        self.lastTime = now

        self:promoteValue( self.nextValue )
        self.dirty = false
        self.nextValue = nil
    end
end

--[[
    DecoratorCooldown
]]
DecoratorCooldown = {

}
setmetatable( DecoratorCooldown, DecoratorMT )
DecoratorCooldownMT = {
    __index = DecoratorCooldown
}

function DecoratorCooldown:new( duration )
    local decorator = Decorator:new()

    decorator.duration = duration
    decorator.enabled = true

    setmetatable( decorator, DecoratorCooldownMT )
    
    return decorator
end

function DecoratorCooldown:evaluate()
    return self.enabled
end

function DecoratorCooldown:onStart()
    self:killTimer( DecoratorCooldown.onTimerEvent )
end

function DecoratorCooldown:onStop()    
    self.enabled = false

    self:setTimer( DecoratorCooldown.onTimerEvent, self.duration )
end

function DecoratorCooldown:onTimerEvent()
    self.enabled = true

    local parent = self.parent
    parent:onDecoratorChanged( BLACKBOARD_ABORT_LOW_PRIORITY )
end

--[[
    DecoratorTimeLimit
]]
DecoratorTimeLimit = {

}
setmetatable( DecoratorTimeLimit, DecoratorMT )
DecoratorTimeLimitMT = {
    __index = DecoratorTimeLimit
}

function DecoratorTimeLimit:new( duration )
    local decorator = Decorator:new()

    decorator.duration = duration
    decorator.enabled = true

    setmetatable( decorator, DecoratorTimeLimitMT )
    
    return decorator
end

function DecoratorTimeLimit:evaluate()    
    return true
end

function DecoratorTimeLimit:onStart()
    self:setTimer( DecoratorTimeLimit.onTimerEvent, self.duration )
end

function DecoratorTimeLimit:onStop()    
    self:killTimer( DecoratorTimeLimit.onTimerEvent )
end

function DecoratorTimeLimit:onTimerEvent()
    local parent = self.parent
    parent:onDecoratorChanged( BLACKBOARD_ABORT_SELF )
end

--[[
    ServiceTakeAction
]]
ServiceTakeAction = {

}
setmetatable( ServiceTakeAction, ServiceMT )
ServiceTakeActionMT = {
    __index = ServiceTakeAction
}

function ServiceTakeAction:new( period, fn, ... )
    local service = Service:new()

    service.period = tonumber( period ) or 1
    if type( fn ) == "function" then
        service.fn = fn
    else
        outputDebugString( "The second argument should represents a function" )
    end
    service.args = { ... }

    setmetatable( service, ServiceTakeActionMT )
    
    return service
end

function ServiceTakeAction:onStart()
    local time = self.agent.time
    time:schedule( self, ServiceTakeAction.onTimerEvent, self.period )
end

function ServiceTakeAction:onStop()
    local time = self.agent.time
    time:unschedule( self, self.period )
end

function ServiceTakeAction:onTimerEvent( dt )
    local fn = self.fn
    if fn then
        fn( unpack( self.args ), dt )
    end
end

--[[
    ServiceRandomSound
]]
ServiceRandomSound = {

}
setmetatable( ServiceRandomSound, ServiceMT )
ServiceRandomSoundMT = {
    __index = ServiceRandomSound
}

function ServiceRandomSound:new( period, sndHash, probability )
    local service = Service:new()

    service.period = tonumber( period ) or 1
    service.probability = tonumber( probability ) or 1
    service.sndHash = sndHash

    setmetatable( service, ServiceRandomSoundMT )
    
    return service
end

function ServiceRandomSound:onStart()
    local time = self.agent.time
    time:schedule( self, ServiceRandomSound.onTimerEvent, self.period )
end

function ServiceRandomSound:onStop()
    local time = self.agent.time
    time:unschedule( self, self.period )
end

function ServiceRandomSound:onTimerEvent()
    
end
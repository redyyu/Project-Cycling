require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"
require "ISUI/ISInventoryPaneContextMenu"

local seatNameTable = {"SeatFrontLeft", "SeatFrontRight", "SeatMiddleLeft", "SeatMiddleRight", "SeatRearLeft", "SeatRearRight"}
local soundFX = {
    Riding = {
        name = 'BikeRidingComp',
        radius = 6,
		volume = 2,
    },
    Stop = {
        name = 'BikeStop',
        radius = 8,
		volume = 4,
    },
}

local Bike = {}


Bike.getBikesFromInvertory = function (playerInv)
    local bike_items = {}
    local items = playerInv:getItemsFromCategory("Container") -- same with getAllCategory("Container")
    for j = 0, items:size() - 1 do
        local item = items:get(j)
        if item:hasTag('Bike') then
            table.insert(bike_items, item)
        end
    end
    return bike_items
end


Bike.parseWorldObjects = function (worldobjects, playerNum)
    local squares = {}
    local doneSquare = {}
    local worldObjTable = {}

    for i, v in ipairs(worldobjects) do
        if v:getSquare() and not doneSquare[v:getSquare()] then
            doneSquare[v:getSquare()] = true
            table.insert(squares, v:getSquare())
        end
    end

    if #squares > 0 then
        if JoypadState.players[playerNum+1] then
            for _,square in ipairs(squares) do
                for i=0,square:getWorldObjects():size() - 1 do
                    local obj = square:getWorldObjects():get(i)
                    table.insert(worldObjTable, obj)
                end
            end
        else
            local squares2 = {}
            for idx, v in pairs(squares) do
                squares2[idx] = v
            end
            for _, square in ipairs(squares2) do
                ISWorldObjectContextMenu.getSquaresInRadius(square:getX(), square:getY(), square:getZ(), 1, doneSquare, squares)
            end
            for _, square in ipairs(squares) do
                for i=0, square:getWorldObjects():size() -1 do
                    local obj = square:getWorldObjects():get(i)
                    table.insert(worldObjTable, obj)
                end
            end
        end
    end

    return worldObjTable
end


Bike.dropItemInsanely = function(playerObj, item, square)
    if playerObj and item then
        if not square then
            square = playerObj:getSquare()
        end

        -- if item == playerObj:getPrimaryHandItem() then
        --     playerObj:setPrimaryHandItem(nil)
        -- end
        if item == playerObj:getSecondaryHandItem() then
            playerObj:setSecondaryHandItem(nil)
        end
        
        playerObj:getInventory():Remove(item)
        local dropX,dropY,dropZ = ISInventoryTransferAction.GetDropItemOffset(playerObj, playerObj:getCurrentSquare(), primary)
        playerObj:getCurrentSquare():AddWorldInventoryItem(item, dropX, dropY, dropZ)

        local pdata = getPlayerData(playerObj:getPlayerNum())
        if pdata ~= nil then
            pdata.playerInventory:refreshBackpacks()
            pdata.lootInventory:refreshBackpacks()
        end
    end
end


Bike.onPlayerMove = function (playerObj)
    local playerInv = playerObj:getInventory()
    local handItem = playerObj:getSecondaryHandItem()
    if handItem and handItem:hasTag("Bike") then
        playerObj:setSneaking(false)
        if not playerObj:isRunning() and not playerObj:isSprinting() then
            playerObj:setRunning(true)
        end

        local body_damage = playerObj:getBodyDamage()
        -- make fun when cycling.
        if body_damage:getBoredomLevel() > 0 then
            body_damage:setBoredomLevel(body_damage:getBoredomLevel() - 0.05)
        end
        if body_damage:getUnhappynessLevel() > 0 then
            body_damage:setUnhappynessLevel(body_damage:getUnhappynessLevel() - 0.01)
        end
        -- NO NEED this, running already enough.
        -- playerObj:setMetabolicTarget(Metabolics.Fitness)
    end
end


Bike.onPlayerUpdate = function (playerObj)

    local playerInv = playerObj:getInventory()
    local equippedBike = false

    for idx, item in ipairs(Bike.getBikesFromInvertory(playerInv)) do
        -- DO NOT AUTO equipped, it will cause lot more logic prolbem,
        -- such as conflict with other MOD did samething.
        -- item will keep equip/unequip in millseconds, don't even see the action.
        -- unless check the log.
        
        -- equip first Bike when no Bike equipped.
        -- if not equippedBike and item:hasTag('Bike') then
        --     playerObj:setPrimaryHandItem(item)
        --     playerObj:setSecondaryHandItem(item)
        --     equippedBike = item
        -- end
        -- drop any Bike not equipped.
        if item:isEquipped() then
            equippedBike = item
        else
            Bike.dropItemInsanely(playerObj, item)
            playerObj:Say(getText('IGUI_PlayerText_Cant_Take_Bike_This_Way'))
        end
    end

    if equippedBike then
        if isDebugEnabled() and playerObj:getCurrentState() ~= IdleState.instance() then
            print("================= Bike whit CurrentState =====================")
            print(playerObj:getCurrentState())
            print("================= End Bike whit CurrentState =====================")
        end

        if playerObj:getCurrentState() == IdleState.instance() then

            if playerObj:getVariableString("lefthandmask") == "holdingbike" then
                local player_stats = playerObj:getStats()
                local endurance = player_stats:getEndurance()
                if endurance < 1 then
                    -- dont change modifier numbers, unless know what doing.
                    local edr_modifier = ZombRand(0, 5) / 100000

                    -- recovering faster while can sprint or idle (no walk on bike)
                    if endurance > 0.5 or (not playerObj:isRunning() and not playerObj:isSprinting()) then
                        edr_modifier = ZombRand(0, 20) / 100000
                    end

                    player_stats:setEndurance(endurance + edr_modifier)
                end

                -- attach sound
                playerObj:getEmitter():stopSoundByName('HumanFootstepsCombined')
                if playerObj:isPlayerMoving() then
                    playerObj:getEmitter():stopSoundByName(soundFX.Stop.name)
        
                    if not playerObj:getEmitter():isPlaying(soundFX.Riding.name) then
                        playerObj:getEmitter():playSound(soundFX.Riding.name)
                        addSound(
                            playerObj,
                            playerObj:getX(),
                            playerObj:getY(),
                            playerObj:getZ(),
                            soundFX.Riding.radius,
                            soundFX.Riding.volume
                        )
                    end
                    playerObj:setVariable('RidingBike', true)
                elseif playerObj:getVariableBoolean('RidingBike') then
                    playerObj:getEmitter():stopSoundByName(soundFX.Riding.name)
                    if not playerObj:getEmitter():isPlaying(soundFX.Stop.name) then
                        playerObj:getEmitter():playSound(soundFX.Stop.name)
                        addSound(
                            playerObj,
                            playerObj:getX(),
                            playerObj:getY(),
                            playerObj:getZ(),
                            soundFX.Riding.radius,
                            soundFX.Riding.volume
                        )
                    end
                    playerObj:setVariable('RidingBike', false)
                end
            else
                playerObj:getEmitter():stopSoundByName(soundFX.Stop.name)
                playerObj:setVariable('RidingBike', false)
            end

        else -- Drop bike while do something else.
            -- DO NOT `ISTimedActionQueue.isPlayerDoingAction(playerObj)` this not enough.
            -- forced drop bike while climb window or fence, and others actions.
            playerObj:getEmitter():stopSoundByName(soundFX.Stop.name)
            playerObj:getEmitter():stopSoundByName(soundFX.Riding.name)
            playerObj:setVariable('RidingBike', false)
            Bike.dropItemInsanely(playerObj, equippedBike)
        end
    end
end


Bike.onEnterVehicle = function (playerObj)
    local handItem = playerObj:getSecondaryHandItem()
    if handItem and handItem:hasTag('Bike') then
        local vehicle = playerObj:getVehicle()
        local areaCenter = vehicle:getAreaCenter(seatNameTable[vehicle:getSeat(playerObj)+1])

        if areaCenter then
            local sqr = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
            Bike.dropItemInsanely(playerObj, handItem, sqr)
        end
    end
end


Bike.onEquipBike = function (playerNum, bike)
    local playerObj = getSpecificPlayer(playerNum)
    local walk_to = nil
    if bike:getWorldItem() then
        walk_to = luautils.walkAdj(playerObj, bike:getWorldItem():getSquare())
    elseif bike:getContainer() then
        walk_to = luautils.walkToContainer(bike:getContainer(), playerObj:getPlayerNum())
    else
        walk_to = luautils.walkAdj(playerObj, playerObj:getCurrentSquare())
    end
    
    if walk_to then
        -- if playerObj:getPrimaryHandItem() then
        --     ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50))
        -- end
        if playerObj:getSecondaryHandItem() then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getSecondaryHandItem(), 50))
        end
        ISTimedActionQueue.add(ISTakeBike:new(playerObj, bike, 50))
    end
end


Bike.onUnequipBike = function(playerNum, item)
    local playerObj = getSpecificPlayer(playerNum)
    ISTimedActionQueue.add(ISUntakeBike:new(playerObj, item, playerObj:getCurrentSquare(), 25))
end


Bike.doFillWorldObjectContextMenu = function (playerNum, context, worldobjects, test)
    local playerObj = getSpecificPlayer(playerNum)
    local playerInv = playerObj:getInventory()
    local item = playerObj:getSecondaryHandItem()

    if item and item:hasTag('Bike') then
        context:clear()
        -- context:removeOptionByName(getText("ContextMenu_Drop"))
        -- context:removeOptionByName(getText("ContextMenu_DropNamedItem", item:getDisplayName()))
        -- HeavyItem have own drop option, replace it
        context:addOptionOnTop(getText("ContextMenu_GET_OFF_BIKE"), playerNum, Bike.onUnequipBike, item)
        return
    else
        local worldObjTable = Bike.parseWorldObjects(worldobjects, playerNum)
        if #worldObjTable == 0 then return false end

        for _, obj in ipairs(worldObjTable) do
            local item = obj:getItem()
            if item and item:hasTag('Bike') and not playerObj:isHandItem(item)then
                context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
                context:removeOptionByName(getText("ContextMenu_Equip_Primary"))
                context:removeOptionByName(getText("ContextMenu_Equip_Secondary"))
                context:removeOptionByName(getText("ContextMenu_Unequip"))
                local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
                if old_option then
                    context:removeOptionByName(old_option.name)
                    context:addOptionOnTop(getText("ContextMenu_TAKE_RIDE", item:getDisplayName()), playerNum, Bike.onEquipBike, item)
                    return
                end                
            end
        end
    end
end


Bike.doInventoryContextMenu = function (playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    local items = ISInventoryPane.getActualItems(items)

    for _, item in ipairs(items) do
        if item and item:hasTag('bike') then
            context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
            context:removeOptionByName(getText("ContextMenu_Equip_Primary"))
            context:removeOptionByName(getText("ContextMenu_Equip_Secondary"))
            context:removeOptionByName(getText("ContextMenu_Unequip"))
            context:removeOptionByName(getText("ContextMenu_Grab"))
            
            if playerObj:isHandItem(item) then
                -- replace native Drop
                context:removeOptionByName(getText("ContextMenu_Drop"))
                context:addOptionOnTop(getText("ContextMenu_GET_OFF_BIKE"), playerNum, Bike.onUnequipBike, item)
                return
            else
                -- context:removeOptionByName(old_option.name)
                context:addOptionOnTop(getText("ContextMenu_TAKE_RIDE", item:getDisplayName()), playerNum, Bike.onEquipBike, item)
                return
            end
        end
    end
end

Events.OnPlayerMove.Add(Bike.onPlayerMove)
Events.OnPlayerUpdate.Add(Bike.onPlayerUpdate)
Events.OnEnterVehicle.Add(Bike.onEnterVehicle)

Events.OnFillInventoryObjectContextMenu.Add(Bike.doInventoryContextMenu)
Events.OnFillWorldObjectContextMenu.Add(Bike.doFillWorldObjectContextMenu)
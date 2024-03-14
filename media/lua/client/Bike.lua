require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"

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
    local items = playerInv:getItems()
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

        if item == playerObj:getPrimaryHandItem() then
            playerObj:setPrimaryHandItem(nil)
        end
        if item == playerObj:getSecondaryHandItem() then
            playerObj:setSecondaryHandItem(nil)
        end
        
        playerObj:getInventory():Remove(item)
        local dropX,dropY,dropZ = ISInventoryTransferAction.GetDropItemOffset(playerObj, playerObj:getCurrentSquare(), primary)
        playerObj:getCurrentSquare():AddWorldInventoryItem(item, dropX, dropY, dropZ)

        local pdata = getPlayerData(playerObj:getPlayerNum());
        if pdata ~= nil then
            pdata.playerInventory:refreshBackpacks()
            pdata.lootInventory:refreshBackpacks()
        end
    end
end


Bike.onPlayerUpdate = function (playerObj)

    local playerInv = playerObj:getInventory()
    local handItem = playerObj:getPrimaryHandItem()
    local equippedBike = false

    for _, item in ipairs(Bike.getBikesFromInvertory(playerInv)) do
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
        end
    end

    if equippedBike then
        if isDebugEnabled() and playerObj:getCurrentState() ~= IdleState.instance() then
            print("================= Bike whit CurrentState =====================")
            print(playerObj:getCurrentState())
            print("================= End Bike whit CurrentState =====================")
        end

        if playerObj:getCurrentState() == IdleState.instance() then

            if playerObj:getVariableString("righthandmask") == "holdingbikeright" then
                local player_stats = playerObj:getStats()
                local endurance = player_stats:getEndurance()
                if endurance < 0.95 then
                    player_stats:setEndurance(endurance + 0.00010)  -- dont change this number, unless know what doing.
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
    if playerObj:getPrimaryHandItem() and playerObj:getPrimaryHandItem():hasTag('Bike') then
        local equippedBike = playerObj:getPrimaryHandItem()
        local vehicle = playerObj:getVehicle()
        local areaCenter = vehicle:getAreaCenter(seatNameTable[vehicle:getSeat(playerObj)+1])

        if areaCenter then
            local sqr = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
            Bike.dropItemInsanely(playerObj, equippedBike, sqr)
        end
    end
end


Bike.onEquipBike = function (playerNum, WItem)
    local playerObj = getSpecificPlayer(playerNum)
    if WItem:getSquare() and luautils.walkAdj(playerObj, WItem:getSquare()) then
        if playerObj:getPrimaryHandItem() then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50));
        end
        if playerObj:getSecondaryHandItem() and playerObj:getSecondaryHandItem() ~= playerObj:getPrimaryHandItem() then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getSecondaryHandItem(), 50));
        end
        ISTimedActionQueue.add(ISTakeBike:new(playerObj, WItem, 50))
    end
end


Bike.onUnequipBike = function(playerNum, item)
    local playerObj = getSpecificPlayer(playerNum)
    ISTimedActionQueue.add(ISUntakeBike:new(playerObj, item, playerObj:getCurrentSquare(), 25))
end


Bike.doFillWorldObjectContextMenu = function (playerNum, context, worldobjects, test)
    local playerObj = getSpecificPlayer(playerNum)
    local playerInv = playerObj:getInventory()
    local item = playerObj:getPrimaryHandItem()

    -- Bike Item has tag `HeavyItem`, native will take care many things.

    if item and item:hasTag('Bike') then
        -- HeavyItem have own drop option, replace it
        context:removeOptionByName(getText("ContextMenu_Drop"))
        context:removeOptionByName(getText("ContextMenu_DropNamedItem", item:getDisplayName()))
        context:addOptionOnTop(getText("ContextMenu_GET_OFF_BIKE"), playerNum, Bike.onUnequipBike, item)
        return
    else
        local worldObjTable = Bike.parseWorldObjects(worldobjects, playerNum)
        if #worldObjTable == 0 then return false end

        for _, obj in ipairs(worldObjTable) do
            local item = obj:getItem()
            if item and item:hasTag('Bike') then
                local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
                if old_option then
                    context:removeOptionByName(old_option.name)
                    context:addOptionOnTop(getText("ContextMenu_GET_ON_BIKE"), playerNum, Bike.onEquipBike, obj)
                    return
                end                
            end
        end
    end
end


Bike.onGrabBikeFromContainer = function (playerObj, bike)
    local playerObj = getSpecificPlayer(playerNum)
    local container = bike:getContainer()
    local inventory = getPlayerInventory(playerNum).inventory

    if bike:getContainer() ~= inventory and inventory:hasRoomFor(playerObj, bike) then
        if luautils.walkToContainer(bike:getContainer(), playerNum) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, bike, bike:getContainer(), inventory))
        end
    else
        ISInventoryPaneContextMenu.dropItem(bike, playerNum)
    end
    
end


Bike.doInventoryContextMenu = function (playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    local items = ISInventoryPane.getActualItems(items)

    -- Bike Item has tag `HeavyItem`, native will take care many things.

    for _, item in ipairs(items) do
        if item and item:hasTag('bike') then
            context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
            context:removeOptionByName(getText("ContextMenu_Unequip"))

            -- local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
            -- NO Need this, `HeavyItem` don't have `Grab` option in Inventory.

            if item == playerObj:getPrimaryHandItem() then
                -- replace native Drop
                context:removeOptionByName(getText("ContextMenu_Drop"))
                context:addOptionOnTop(getText("ContextMenu_GET_OFF_BIKE"), playerNum, Bike.onUnequipBike, item)
                return
            else
                -- context:removeOptionByName(old_option.name)
                if item:getContainer():getType() == "floor" then
                    context:addOptionOnTop(getText("ContextMenu_GET_ON_BIKE"), playerNum, Bike.onEquipBike, item:getWorldItem())
                    return
                else
                    context:addOptionOnTop(getText("ContextMenu_GET_ON_BIKE"), playerNum, Bike.onGrabBikeFromContainer, item)
                    return
                end
            end
        end
    end
end


Events.OnPlayerUpdate.Add(Bike.onPlayerUpdate)
Events.OnEnterVehicle.Add(Bike.onEnterVehicle)

Events.OnFillInventoryObjectContextMenu.Add(Bike.doInventoryContextMenu)
Events.OnFillWorldObjectContextMenu.Add(Bike.doFillWorldObjectContextMenu)
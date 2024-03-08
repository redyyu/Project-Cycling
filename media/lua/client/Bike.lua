BIKE_TYPES = {"PROJCycling.Bike"}

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
    local bikes = {}
    for i = 1, #BIKE_TYPES do
        local bikesArray = playerInv:getItemsFromType(BIKE_TYPES[i])
        for j = 0, bikesArray:size() - 1 do
            table.insert(bikes, bikesArray:get(j))
        end
    end
    return bikes
end


Bike.dropBike = function (playerObj, square)
    local item = playerObj:getPrimaryHandItem()
    if not square then
        square = playerObj:getSquare()
    end

    if item and item:hasTag('Bike') then
        playerObj:getInventory():Remove(item)
        local pdata = getPlayerData(playerObj:getPlayerNum());
        if pdata ~= nil then
            pdata.playerInventory:refreshBackpacks()
            pdata.lootInventory:refreshBackpacks()
        end
        playerObj:setPrimaryHandItem(nil)
        playerObj:setSecondaryHandItem(nil)
        square:AddWorldInventoryItem(item, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
    end
end


Bike.parseWorldObjects = function (worldobjects, playerIdx)
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
        if JoypadState.players[playerIdx+1] then
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


Bike.onPlayerUpdate = function (playerObj)

    local playerInv = playerObj:getInventory()
    local bikes = Bike.getBikesFromInvertory(playerInv)
    local item = playerObj:getPrimaryHandItem()
    local hasBike = false

    -- Drop other bike. only keep one bike at time.
    if #bikes > 0 then
        if not item or not item:hasTag('Bike') then
            item = bikes[1]
            playerObj:setPrimaryHandItem(item)
            playerObj:setSecondaryHandItem(item)
        end
        if item:hasTag('Bike') and #bikes > 1 then
            for _, bike in ipairs(bikes) do
                if item ~= bike then
                    playerInv:Remove(bike)
                    playerObj:getCurrentSquare():AddWorldInventoryItem(bike, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
                end
            end
            local pdata = getPlayerData(playerObj:getPlayerNum())
            if pdata ~= nil then
                pdata.playerInventory:refreshBackpacks()
                pdata.lootInventory:refreshBackpacks()
            end
        end
        hasBike = true
    end

    -- Drop bike while do something else.
    if playerObj:getVariableString("righthandmask") == "holdingbikeright" and hasBike then
        local player_stats = playerObj:getStats()
        local endurance = player_stats:getEndurance()
        if endurance < 0.95 then
            player_stats:setEndurance(endurance + 0.00010)  -- dont change this number, unless know what doing.
        end

        -- forced drop bike while climb window or fence, but not wall. 
        -- climb wall already in vanilla, just like taking a bag on hand.
        if not (playerObj:getCurrentState() == IdleState.instance() or 
                playerObj:getCurrentState() == PlayerAimState.instance()) then
            Bike.dropBike(playerObj)
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
end


Bike.onEnterVehicle = function (playerObj)
	local vehicle = playerObj:getVehicle()
    local areaCenter = vehicle:getAreaCenter(seatNameTable[vehicle:getSeat(playerObj)+1])

    if areaCenter then 
        local sqr = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
        Bike.dropBike(playerObj, sqr)
    end
end


Bike.onEquipBike = function (playerObj, WItem)
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


Bike.onUnequipBike = function(playerObj, item)
    ISTimedActionQueue.add(ISUntakeBike:new(playerObj, item, playerObj:getCurrentSquare(), 25))
end


Bike.doFillWorldObjectContextMenu = function (player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()
    local item = playerObj:getPrimaryHandItem()

    if item and item:hasTag('Bike') then
        context:addOptionOnTop(getText("ContextMenu_GET_OFF_BIKE"), playerObj, Bike.onUnequipBike, item)
        return
    else
        local worldObjTable = Bike.parseWorldObjects(worldobjects, player)
        if #worldObjTable == 0 then return false end

        for _, obj in ipairs(worldObjTable) do
            local item = obj:getItem()
            if item and item:hasTag('Bike') then
                local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
                if old_option then
                    -- context:removeOptionByName(old_option.name)
                    context:addOptionOnTop(getText("ContextMenu_GET_ON_BIKE"), playerObj, Bike.onEquipBike, obj)
                    return
                end                
            end
        end
    end
end


Bike.onGrabBikeFromContainer = function (playerObj, bike)
    local container = item:getContainer()
    if container:getType() ~= "floor" then
        container:Remove(item)
        local pdata = getPlayerData(playerObj:getPlayerNum())
        if pdata ~= nil then
            playerObj:getCurrentSquare():AddWorldInventoryItem(bike, 0, 0, 0)
            pdata.playerInventory:refreshBackpacks()
            pdata.lootInventory:refreshBackpacks()
        end
    end
end


Bike.doInventoryContextMenu = function (playerNumber, context, items)
    local playerObj = getSpecificPlayer(playerNumber)
    local items = ISInventoryPane.getActualItems(items)

    for _, item in ipairs(items) do
        if item and item:hasTag('bike') then
            context:removeOptionByName(getText("ContextMenu_Equip_Two_Hands"))
            context:removeOptionByName(getText("ContextMenu_Unequip"))
            local old_option = context:getOptionFromName(getText("ContextMenu_Grab"))
            if old_option then
                -- context:removeOptionByName(old_option.name)
                if item:getContainer():getType() == "floor" then
                    context:addOptionOnTop(getText("ContextMenu_GET_ON_BIKE"), playerObj, Bike.onEquipBike, item:getWorldItem())
                    return
                else
                    context:addOptionOnTop(getText("ContextMenu_GRAB_BIKE_TO_GROUND"), playerObj, Bike.onGrabBikeFromContainer, item)
                    return
                end
            elseif item == playerObj:getPrimaryHandItem() then
                context:addOptionOnTop(getText("ContextMenu_GET_OFF_BIKE"), playerObj, Bike.onUnequipBike, item)
                return
            end
        end
    end
end


Events.OnPlayerUpdate.Add(Bike.onPlayerUpdate)
Events.OnEnterVehicle.Add(Bike.onEnterVehicle)

Events.OnFillInventoryObjectContextMenu.Add(Bike.doInventoryContextMenu)
Events.OnFillWorldObjectContextMenu.Add(Bike.doFillWorldObjectContextMenu)
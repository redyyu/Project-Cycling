--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"
-- require "TimedActions/ISEquipWeaponAction"


ISUntakeBike = ISBaseTimedAction:derive("ISUntakeBike");

function ISUntakeBike:isValid()
    -- Check that the item wasn't picked up by a preceding action
    if self.item == nil or not self.item:hasTag('Bike') or self.item ~= self.character:getPrimaryHandItem() then return false end
    return true
end

function ISUntakeBike:start()
    self:setActionAnim("Loot");
    self:setAnimVariable("LootPosition", "Low");
    self:setOverrideHandModels(nil, nil)
    self.item:setJobType(getText("ContextMenu_GET_OFF_BIKE"))
    self.item:setJobDelta(0.0)
end

function ISUntakeBike:update()
    self.item:setJobDelta(self:getJobDelta());
end

function ISUntakeBike:stop()
    ISBaseTimedAction.stop(self)
    self.item:setJobDelta(0.0);
end

function ISUntakeBike:perform()
    -- forceDropHeavyItems(self.character)
    -- from TimedActions/ISEquipWeaponAction.lua drop Corps and Generator or any other item hasTag `HeavyItem`
    local square = self.character:getCurrentSquare()
    self.character:getInventory():Remove(self.item)
    self.character:setPrimaryHandItem(nil)
    self.character:setSecondaryHandItem(nil)

    self.toSquare:AddWorldInventoryItem(self.item, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
    local pdata = getPlayerData(self.character:getPlayerNum())
    if pdata ~= nil then
        pdata.playerInventory:refreshBackpacks()
        pdata.lootInventory:refreshBackpacks()
    end
    self.item:setJobDelta(0.0);
    ISBaseTimedAction.perform(self);
end

function ISUntakeBike:new(character, item, toSquare, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = true
    o.stopOnRun = true 
    o.maxTime = time
    o.item = item
    o.toSquare = toSquare
    o.loopedAction = false
    return o
end

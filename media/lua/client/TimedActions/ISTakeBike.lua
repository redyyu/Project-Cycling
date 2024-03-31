--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"
-- require "TimedActions/ISEquipWeaponAction"


ISTakeBike = ISBaseTimedAction:derive("ISTakeBike");

function ISTakeBike:isValid()
    -- Check that the item wasn't picked up by a preceding action
    if self.item == nil then return false end
    return true
end

function ISTakeBike:update()
    self.item:setJobDelta(self:getJobDelta());
end

function ISTakeBike:start()
    self:setActionAnim("Loot");
    self:setAnimVariable("LootPosition", "Low");
    self:setOverrideHandModels(nil, nil);
    self.item:setJobType(getText("ContextMenu_TAKE_RIDE"));
    self.item:setJobDelta(0.0);
end

function ISTakeBike:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISTakeBike:stop()
    self.item:setJobDelta(0.0);
    ISBaseTimedAction.stop(self);
end

function ISTakeBike:perform()
    forceDropHeavyItems(self.character)
    -- from TimedActions/ISEquipWeaponAction.lua drop Corps and Generator or any other item hasTag `HeavyItem`
    if self.worldItem then
        self.worldItem:getSquare():transmitRemoveItemFromSquare(self.worldItem)
        self.worldItem:removeFromWorld()
        self.worldItem:removeFromSquare()
        self.worldItem:setSquare(nil)
        self.item:setWorldItem(nil)
    end
    self.item:setJobDelta(0.0)
    self.character:getInventory():setDrawDirty(true)
    self.character:getInventory():AddItem(self.item)
    self.action:stopTimedActionAnim()
    self.action:setLoopedAction(false)
    -- self.character:setPrimaryHandItem(self.item)
    self.character:setSecondaryHandItem(self.item)
    local pdata = getPlayerData(self.character:getPlayerNum())
    if pdata ~= nil then
        pdata.playerInventory:refreshBackpacks()
        pdata.lootInventory:refreshBackpacks()
    end
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);

end

function ISTakeBike:new (character, item, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.worldItem = item:getWorldItem()
    o.stopOnWalk = true
    o.stopOnRun = true   
    o.maxTime = time;
    o.loopedAction = false
    return o
end

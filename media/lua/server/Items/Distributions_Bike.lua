local spawn_chance = SandboxVars.PROJCycling.SpawnChance
local spawn_chance_rate = spawn_chance / 100

local BIKE_TYPES = {
    "PROJCycling.Bike",
}
local SPAWN_TIELS = {
    "lighting_outdoor_01_0",
    "lighting_outdoor_01_1",
    "lighting_outdoor_01_2",
    "lighting_outdoor_01_16",
    "lighting_outdoor_01_17",
}

for _, item_type in ipairs(BIKE_TYPES) do
    table.insert(ProceduralDistributions["list"]["GigamartTools"].items, item_type);
    table.insert(ProceduralDistributions["list"]["GigamartTools"].items, 2 * spawn_chance_rate);

    table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, item_type);
    table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, 2 * spawn_chance_rate);

    table.insert(ProceduralDistributions["list"]["CrateTools"].items, item_type);
    table.insert(ProceduralDistributions["list"]["CrateTools"].items, 1 * spawn_chance_rate);

    table.insert(ProceduralDistributions["list"]["CrateMetalwork"].items, item_type);
    table.insert(ProceduralDistributions["list"]["CrateMetalwork"].items, 1 * spawn_chance_rate);

    table.insert(ProceduralDistributions["list"]["StoreCounterBagsFancy"].items, item_type);
    table.insert(ProceduralDistributions["list"]["StoreCounterBagsFancy"].items, 1 * spawn_chance_rate);

    table.insert(ProceduralDistributions["list"]["JanitorTools"].items, item_type);
    table.insert(ProceduralDistributions["list"]["JanitorTools"].items, 1 * spawn_chance_rate);

    table.insert(ProceduralDistributions["list"]["ToolStoreFarming"].items, item_type);
    table.insert(ProceduralDistributions["list"]["ToolStoreFarming"].items, 1 * spawn_chance_rate);

    table.insert(ProceduralDistributions["list"]["ToolStoreMisc"].items, item_type);
    table.insert(ProceduralDistributions["list"]["ToolStoreMisc"].items, 1 * spawn_chance_rate);

    table.insert(ProceduralDistributions["list"]["ToolStoreTools"].items, item_type);
    table.insert(ProceduralDistributions["list"]["ToolStoreTools"].items, 1 * spawn_chance_rate);

end


local function spawnBikeInGarage(room)
    if ZombRand(1, 100) > (100 - spawn_chance / 5) then
        if room:getName() == 'garagestorage' or room:getName() == 'garage' then
            local square = room:getRandomFreeSquare()
            local num_type = ZombRand(1, #BIKE_TYPES)
            square:AddWorldInventoryItem(BIKE_TYPES[num_type], ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
        end
    end
end
Events.OnSeeNewRoom.Add(spawnBikeInGarage)


local function spawnBikeOnRaod(obj)
    print(obj)
    print('---------------------------Events.OnObjectAdded----------------------')
    if obj:getSpriteName() and ZombRand(1, 100) > (100 - spawn_chance / 5) then
        for _, v in ipairs(SPAWN_TIELS) do
            if v == obj:getSpriteName() then
                local num_type = ZombRand(1, #BIKE_TYPES)
                local square = obj:getSquare()
                if square and ZombRand(1, 100) then
                    square:AddWorldInventoryItem(BIKE_TYPES[num_type], ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
                end
            end
        end
    end
end
Events.OnObjectAdded.Add(spawnBikeOnRaod)


-- local function spawnBikeOnRaod(square)
--     if not square:getModData().RolledSquare then
--         square:getModData().RolledSquare = true
        
--     end
-- end

-- Events.LoadGridsquare.Add(spawnBikeOnRaod)


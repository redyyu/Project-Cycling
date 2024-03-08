local spawn_chance = SandboxVars.PROJCycling.SpawnChance
local spawn_chance_rate = spawn_chance / 100

local BIKE_TYPES = {
    "PROJCycling.Bike",
}

local SPAWN_ROOMS = {
    ["garagestorage"] = 2,
    ["garage"] = 2,
}

local SPAWN_SPRITES = {
    ["lighting_outdoor_01_0"] = 2,
    ["lighting_outdoor_01_1"] = 2,
    ["lighting_outdoor_01_2"] = 2,
    ["lighting_outdoor_01_16"] = 2,
    ["lighting_outdoor_01_17"] = 5,
}


for _, item_type in ipairs(BIKE_TYPES) do
    table.insert(ProceduralDistributions["list"]["GigamartTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["GigamartTools"].items, 2 * spawn_chance_rate)

    table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, item_type)
    table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, 2 * spawn_chance_rate)

    table.insert(ProceduralDistributions["list"]["CrateTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["CrateTools"].items, 1 * spawn_chance_rate)

    table.insert(ProceduralDistributions["list"]["CrateMetalwork"].items, item_type)
    table.insert(ProceduralDistributions["list"]["CrateMetalwork"].items, 1 * spawn_chance_rate)

    table.insert(ProceduralDistributions["list"]["StoreCounterBagsFancy"].items, item_type)
    table.insert(ProceduralDistributions["list"]["StoreCounterBagsFancy"].items, 1 * spawn_chance_rate)

    table.insert(ProceduralDistributions["list"]["JanitorTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["JanitorTools"].items, 1 * spawn_chance_rate)

    table.insert(ProceduralDistributions["list"]["ToolStoreFarming"].items, item_type)
    table.insert(ProceduralDistributions["list"]["ToolStoreFarming"].items, 1 * spawn_chance_rate)

    table.insert(ProceduralDistributions["list"]["ToolStoreMisc"].items, item_type)
    table.insert(ProceduralDistributions["list"]["ToolStoreMisc"].items, 1 * spawn_chance_rate)

    table.insert(ProceduralDistributions["list"]["ToolStoreTools"].items, item_type)
    table.insert(ProceduralDistributions["list"]["ToolStoreTools"].items, 1 * spawn_chance_rate)
end


local function spawnBikeInGarage(room)
    local base_chance = SPAWN_ROOMS[room:getName()]
    if base_chance ~= nil and ZombRand(1, 100) < base_chance * spawn_chance_rate then
        local square = room:getRandomFreeSquare()
        local num_type = ZombRand(1, #BIKE_TYPES)
        square:AddWorldInventoryItem(BIKE_TYPES[num_type], ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
    end
end
Events.OnSeeNewRoom.Add(spawnBikeInGarage)


local function spawnBikeOnRaod(square)
    if not square:getModData().BikeSpawn then
        square:getModData().BikeSpawn = true
        local objects = square:getObjects()
        for j=0, objects:size()-1 do
            local obj = objects:get(j)
            if obj:getSprite() then
                local base_chance = SPAWN_SPRITES[obj:getSprite():getName()]
                if base_chance ~= nil then
                    if ZombRand(1, 100) < base_chance * spawn_chance_rate then
                        local num_type = ZombRand(1, #BIKE_TYPES)
                        square:AddWorldInventoryItem(BIKE_TYPES[num_type], ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
                    end
                end
            end
        end
    else
        if isDebugEnabled() then
            -- print('Square already spawned -----------------------')
        end
    end
end

-- it little big slow down the FPS of game, but seems ok.
Events.LoadGridsquare.Add(spawnBikeOnRaod)


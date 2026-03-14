local config = require("config")
local nests = { }

local function initialize_storage()
    storage.nests_to_clean = storage.nests_to_clean or { }
end

---@param event EventData.on_trigger_created_entity
local function add_nest(event)
    initialize_storage()
    local entity = event.entity
    if not entity or not entity.valid then return end
    if entity.name ~= "bp-buried-biter-nest" then return end
    entity.amount = config.buried_nest.spawn_amount * (math.random() + 0.5)
    -- Resources are not aligned nicely to the grid for the egg extractor
    -- resulting that it's not placeable. It's a 3x3 entity, so the middle
    -- of the resource needs to be in the middle of a tile, but for after 
    -- spawners it spawns on the edges of tiles.
    local halfify = function(value) return math.floor(value) + 0.5 end
    entity.teleport({halfify(entity.position.x), halfify(entity.position.y)})
    table.insert(storage.nests_to_clean, entity)
end

nests.on_nth_tick = {
    [60] = function (event)
        initialize_storage()
        -- Nests that die leaves their corpse on top of the buried biter nest
        -- so we clean it up ourselves after a while
        for _, nest in pairs(storage.nests_to_clean) do
            if nest.valid then 
                for _, entity in pairs(nest.surface.find_entities_filtered{
                    type = "corpse",
                    area = {{nest.position.x - 2, nest.position.y - 2},
                            {nest.position.x + 2, nest.position.y + 2}}
                }) do
                    entity.destroy{ raise_destroy = true }
                end
            end
        end
        storage.nests_to_clean = {}
    end,
}

function nests.on_init(event)
    initialize_storage()
end

function nests.on_configuration_changed(event)
    initialize_storage()
end

nests.events = {
    [defines.events.on_trigger_created_entity] = add_nest,
}

return nests

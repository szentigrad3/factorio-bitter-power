local config = require("config")

local recipe_sync = { }

local direct_unlocks = {
    ["bp-biter-power"] = {
        "bp-cage",
        "bp-cage-trap",
        "bp-generator",
        "bp-incubator",
        "bp-revitalizer",
        "bp-egg-extractor",
    },
    ["bp-biter-power-advanced"] = {
        "bp-generator-reinforced",
        "bp-cage-projectile",
        "bp-cage-cannon",
    },
}

local function set_recipe_enabled(force, recipe_name, enabled)
    local recipe = force.recipes[recipe_name]
    if recipe then
        recipe.enabled = enabled
    end
end

function recipe_sync.sync_force(force)
    for technology_name, recipe_names in pairs(direct_unlocks) do
        local technology = force.technologies[technology_name]
        local researched = technology and technology.researched or false
        for _, recipe_name in pairs(recipe_names) do
            set_recipe_enabled(force, recipe_name, researched)
        end
    end

    for biter_name, biter_config in pairs(config.biter.types) do
        local technology = force.technologies["bp-biter-capture-tier-"..biter_config.tier]
        local researched = technology and technology.researched or false
        set_recipe_enabled(force, "bp-incubate-egg-"..biter_name, researched)
        set_recipe_enabled(force, "bp-revitalization-"..biter_name, researched)
        set_recipe_enabled(force, "bp-revitalization-fish-"..biter_name, researched)
    end
end

function recipe_sync.sync_all_forces()
    for _, force in pairs(game.forces) do
        recipe_sync.sync_force(force)
    end
end

return recipe_sync

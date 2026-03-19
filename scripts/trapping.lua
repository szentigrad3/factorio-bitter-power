local config = require("config")
local technology = require("scripts.technology")

local trapping = { }
local biter_configs = config.biter.types

-- Trigger radius must match the cage-trap prototype definition
local CAGE_TRAP_TRIGGER_RADIUS = 3.5
-- Range values must match the cage-cannon prototype definition
local CAGE_CANNON_MIN_RANGE = 2
local CAGE_CANNON_MAX_RANGE = 15

---Shared logic to cage a biter and register the capture with the trapping force.
---@param trap LuaEntity  The cage trap or cage cannon that is performing the capture
---@param biter LuaEntity The biter being captured
local function capture_biter(trap, biter)
    local biter_config = biter_configs[biter.name]
    if not biter_config then return end
    local caged_name = "bp-caged-"..biter.name
    local force = trap.force ---@cast force LuaForce
    biter.surface.spill_item_stack{position=biter.position, stack={name=caged_name}, enable_looted=true, force=force}
    trap.force.get_item_production_statistics(trap.surface).on_flow(caged_name, 1)
    technology.attemp_tiered_technology_unlock(force.technologies["bp-biter-capture-tier-"..biter_config.tier], biter.name, true)
    biter.destroy{raise_destroy = true}
end

--- @param event EventData.on_script_trigger_effect
local function attempt_trapping_biter(event)
    if event.effect_id ~= "bp-cage-trap-trigger" then return end
    local trap = event.source_entity -- Could also be the cage cannon
    if not trap then return end
    local biter = event.target_entity
    if not biter then return end
    if not biter_configs[biter.name] then return end  -- Will lose the cage
    capture_biter(trap, biter)
end

-- neurotoxic-gas-installation compat:
-- Biters neutralised by neurotoxin are moved to a non-enemy force, so the standard
-- land-mine and turret mechanisms no longer detect them.  When that mod is active we
-- periodically scan each surface ourselves so they can still be caught.

---Try to capture one non-enemy cageable biter that has walked into a cage-trap's radius.
---The trap is destroyed after a successful capture, just like normal detonation.
---@param surface LuaSurface
---@param trap LuaEntity
local function scan_cage_trap(surface, trap)
    if not trap.valid then return end
    local biters = surface.find_entities_filtered{
        position = trap.position,
        radius   = CAGE_TRAP_TRIGGER_RADIUS,
        type     = "unit",
    }
    for _, biter in pairs(biters) do
        if biter.valid and biter.force.name ~= "enemy" and biter_configs[biter.name] then
            capture_biter(trap, biter)
            trap.destroy{raise_destroy = false}
            return  -- trap is gone; nothing more to do
        end
    end
end

---Try to capture one non-enemy cageable biter within a cage cannon's firing range,
---consuming one ammo item as if the cannon had fired.
---@param surface LuaSurface
---@param cannon LuaEntity
local function scan_cage_cannon(surface, cannon)
    if not cannon.valid then return end
    local ammo_inventory = cannon.get_inventory(defines.inventory.turret_ammo)
    if not ammo_inventory or ammo_inventory.is_empty() then return end

    local biters = surface.find_entities_filtered{
        position = cannon.position,
        radius   = CAGE_CANNON_MAX_RANGE,
        type     = "unit",
    }
    for _, biter in pairs(biters) do
        if biter.valid and biter.force.name ~= "enemy" and biter_configs[biter.name] then
            -- Respect the cannon's minimum range
            local dx = biter.position.x - cannon.position.x
            local dy = biter.position.y - cannon.position.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist >= CAGE_CANNON_MIN_RANGE then
                -- Consume one ammo item and capture the biter
                ammo_inventory.remove{name = "bp-cage-projectile", count = 1}
                capture_biter(cannon, biter)
                return
            end
        end
    end
end

---Scan all surfaces for neutralised biters near cage traps / cage cannons.
---Only called when neurotoxic-gas-installation is loaded.
---@param event NthTickEventData
local function scan_for_neurotoxin_biters(event)
    for _, surface in pairs(game.surfaces) do
        for _, trap in pairs(surface.find_entities_filtered{name = "bp-cage-trap"}) do
            scan_cage_trap(surface, trap)
        end
        for _, cannon in pairs(surface.find_entities_filtered{name = "bp-cage-cannon"}) do
            scan_cage_cannon(surface, cannon)
        end
    end
end

trapping.events = {
    [defines.events.on_script_trigger_effect] = attempt_trapping_biter,
}

if script.active_mods["neurotoxic-gas-installation"] then
    trapping.on_nth_tick = { [60] = scan_for_neurotoxin_biters }
end

return trapping

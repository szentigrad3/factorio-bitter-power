for index, force in pairs(game.forces) do
    force.reset_technology_effects()

    -- If player had biter-power researched previously, and have 
    -- produced or captured caged biters, then unlock first tech
    if force.technologies["bp-biter-power"].researched then
        for _, surface in pairs(game.surfaces) do
            if force.get_item_production_statistics(surface).get_input_count("bp-caged-small-biter") > 0 then
                force.technologies["bp-biter-capture-tier-1"].researched = true
                break
            end
        end
    end
end


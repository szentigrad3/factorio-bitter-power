require("prototypes.generator-add-biters")

-- Add the bp-capture science pack to all labs so that the
-- bp-biter-capture-tier-X technologies can be researched.
for _, lab in pairs(data.raw.lab) do
    local inputs = lab.science_pack_ingredients or lab.inputs
    local already_present = false
    for _, input in pairs(inputs) do
        if input == "bp-capture" then
            already_present = true
            break
        end
    end
    if not already_present then
        table.insert(inputs, "bp-capture")
    end
end
data:extend({
    {
        type = "item",
        name = "bp-cage",
        icon = "__biter-power-continued__/graphics/cage/icon.png",
        icon_size = 64,
        subgroup = "bp-peacekeeping",
        order = "b[biter-cage]",
        stack_size = 20
    },
    {
        type = "recipe",
        name = "bp-cage",
        icon = "__biter-power-continued__/graphics/cage/icon.png",
        icon_size = 64,
        energy_required = 5,
        ingredients = {
            {type="item", name="steel-plate", amount=20},
            {type="item", name="copper-cable", amount=20},
        },
        enabled = false,
        results = {{type="item", name="bp-cage", amount=1}}
    },
})
-- flake_gym items for ox_inventory
-- Add these entries into your ox_inventory/data/items.lua return table

return {
    ['pump_and_run'] = {
        label = 'Gym Membership',
        weight = 10,
        stack = false,
        close = true,
        description = 'An active membership card for Pump & Run Gym.',
    },

    ['protein'] = {
        label = 'Protein',
        weight = 500,
        stack = true,
        close = true,
        description = 'Proteins that will help you gain mass faster and strengthen your physical shape.',
    },

    ['runbooster'] = {
        label = 'Run-Booster',
        weight = 250,
        stack = true,
        close = true,
        description = 'A supplement that will significantly make running easier and improve your endurance.',
    },
}

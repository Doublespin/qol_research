--[[

    You can configure multiple sets of research tiers, each set separated by a colon (:).

    Each set has several fields defining amount of levels, cost and ingredients, each field
    is separated by a comma.

    The fields are:

    1. [int]    Level of the previous tier required to start on this tier, or 0 to have no dependency on the previous tier.
    2. [int]    The amount of technologies (levels) in this tier, use 0 for infinite.
    3. [double] The bonus per level of research.
    4. [int]    The duration of each cycle.
    5. [string] A math expression for the cycle cost of each technology. (See count_formula.)
    6. [string] Name of an item for each cycle.
    7. [int]    Amount of previous item.

    Repeat the last two to specify multiple ingredients.

    Example:
    0,3,0.1,15,(L+1)*50,science-pack-1,1:2,4,0.15,20,50*2^(L-1),science-pack-1,1,science-pack-2,1

    This contains two tiers of research:
    0,3,0.1,15,(L+1)*50,science-pack-1,1
    and
    2,4,0.15,20,50*2^(L-1),science-pack-1,1,science-pack-2,1

    The first tier goes as follows:
    0                No tech in the previous (which doesn't exist anyways) tier is required.
    3                There's 3 tech in this tree.
    0.1             Each tech gives a 0.1 = 10% bonus.
    15               Each cycle takes 15 seconds.
    (L+1)*50         Cost of each tech, where L starts at 1.
    science-pack-1   It requires science pack 1
    1                Exactly 1 science pack 1 per cycle

    It creates 3 techs:
    Tech 1-1, 10% bonus, 15 seconds/cycle, 100 cycles of 1 x science-pack-1
    Tech 1-2, 10% bonus, 15 seconds/cycle, 150 cycles of 1 x science-pack-1
    Tech 1-3, 10% bonus, 15 seconds/cycle, 200 cycles of 1 x science-pack-1

    The second tier looks like
    2                It requires "Tech 1-2" to be unlocked before this tier becomes available.
    4                There's 4 tech in this tree.
    0.15             Each tech gives a 0.15 = 15% bonus.
    20               Each cycle takes 20 seconds.
    50*2^(L-1)       Cost of each tech, where L starts at 1.
    science-pack-1   It requires science pack 1
    1                x1
    science-pack-2   and science pack 2
    1                also x1

    This creates an additional 4 techs, which you can only start unlocking after you unlocked Tech 1-2:
    Tech 2-1, 15% bonus, 20 seconds/cycle, 50 * 2^0 = 50 cycles of 1 x science-pack-1 and 1 x science-pack-2
    Tech 2-2, 15% bonus, 20 seconds/cycle, 50 * 2^1 = 100 cycles of 1 x science-pack-1 and 1 x science-pack-2
    Tech 2-3, 15% bonus, 20 seconds/cycle, 50 * 2^2 = 200 cycles of 1 x science-pack-1 and 1 x science-pack-2
    Tech 2-4, 15% bonus, 20 seconds/cycle, 50 * 2^3 = 400 cycles of 1 x science-pack-1 and 1 x science-pack-2
]]

local load_technology_quickbar_bonus

local percentage_description = function (value) return ('%g%%'):format(value * 100) end
local pluralize_description = function (unit) return function (value) return ('%d %s%s'):format(value, unit, value == 1 and '' or 's') end end
local config = {
    {
        name = 'crafting-speed',
        type = 'double',
        default_config = {
            '0,5,0.20,10,150*L,science-pack-1,1',
            '3,5,0.10,15,175*L,science-pack-1,1,science-pack-2,1',
            '3,5,0.05,20,225*L,science-pack-1,1,science-pack-2,1,science-pack-3,1',
            '3,5,0.05,25,300*L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1',
            '5,0,0.05,30,250*2^L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1,space-science-pack,1'
        },
        fields = { 'character-crafting-speed' },
        field_technology = {
            value_scale = 0.01,
            count = 20,
        },
        description_factory = percentage_description
    },
    {
        name = 'inventory-size',
        type = 'int',
        default_config = {
            '0,2,5,10,150*L,science-pack-1,1',
            '1,2,5,15,175*L,science-pack-1,1,science-pack-2,1',
            '1,2,5,20,225*L,science-pack-1,1,science-pack-2,1,science-pack-3,1',
            '1,2,5,25,300*L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1',
            '2,0,5,30,5000*2^L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1,space-science-pack,1'
        },
        fields = { 'character-inventory-slots-bonus' },
        field_technology = {
            value_scale = 1,
            count = 12,
        },
        description_factory = pluralize_description('slot')
    },
    {
        name = 'mining-speed',
        type = 'double',
        default_config = {
            '0,5,0.20,10,150*L,science-pack-1,1',
            '3,5,0.10,15,175*L,science-pack-1,1,science-pack-2,1',
            '3,5,0.05,20,225*L,science-pack-1,1,science-pack-2,1,science-pack-3,1',
            '3,5,0.05,25,300*L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1',
            '5,0,0.05,30,250*2^L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1,space-science-pack,1'
        },
        fields = { 'character-mining-speed' },
        field_technology = {
            value_scale = 0.01,
            count = 20,
        },
        description_factory = percentage_description
    },
    {
        name = 'movement-speed',
        type = 'double',
        default_config = {
            '0,4,0.05,10,150*L,science-pack-1,1',
            '2,4,0.05,15,175*L,science-pack-1,1,science-pack-2,1',
            '2,4,0.05,20,225*L,science-pack-1,1,science-pack-2,1,science-pack-3,1',
            '2,4,0.05,25,300*L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1',
            '4,0,0.05,30,250*2^L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1,space-science-pack,1'
        },
        fields = { 'character-running-speed' },
        field_technology = {
            value_scale = 0.01,
            count = 20,
        },
        description_factory = percentage_description
    },
    {
        name = 'player-reach',
        type = 'int',
        default_config = { 
            '0,4,1,10,150*L,science-pack-1,1',
            '2,4,1,15,175*L,science-pack-1,1,science-pack-2,1',
            '2,4,1,20,225*L,science-pack-1,1,science-pack-2,1,science-pack-3,1',
            '2,4,1,25,300*L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1',
            '4,0,1,30,250*2^L,science-pack-1,1,science-pack-2,1,science-pack-3,1,high-tech-science-pack,1,space-science-pack,1'
        },
        fields =
        {
            'character-build-distance',
            'character-item-drop-distance',
            'character-resource-reach-distance',
            'character-reach-distance',
        },
        field_settings =
        {
            ['character-item-drop-distance'] = 'item-drop-distance',
            ['character-resource-reach-distance'] = 'resource-reach-distance'
        },
        field_technology = {
            value_scale = 1,
            count = 20,
        },
        description_factory = pluralize_description('tile')
    },
    {
        name = 'toolbelts',
        type = 'int',
        default_config = {
            '0,1,1,15,500,science-pack-1,1',
            '1,1,1,30,500,science-pack-1,1,science-pack-2,1'
        },
        fields = { 'quick-bar-count' },
        field_technology = {
            value_scale = 1,
            count = 5,
        },
        description_factory = pluralize_description('belt')
    }
}

return config
-- A util for makin themes. Create a theme, and then add it to the theme pool

local colors = {
    cyan        = 0xff119da4,
    cerulean    = 0xff0c7489,
    midnight_green = 0xff13505b,
    black       = 0xff040404,
    timberwolf  = 0xffd7d9ce,

    oxford_blue = 0xff0b132b,
    space_cadet = 0xff1c2541,
    yinmin_blue = 0xff3a506b,
    vedigris    = 0xff5bc0be,
    white       = 0xffffffff,

    gunmetal    = 0xff253237,
    paynes_dark = 0xff2c3b43,
    paynes_gray = 0xff5c6b73,
    cadet_gray  = 0xff6d94a0,
    light_blue  = 0xff627f93,
    light_cyan  = 0xffc0dbdc,

    techalpha   = 0x00177772,
    techbg1     = 0xff177772,
    techbg2     = 0xff29f9e5,
    techfg1     = 0x800c3d46,
    tech_black  = 0xff000000,
}

-----------------------------------------------------------------------------------

local themes = {
    colors = colors,

    default = function()

        nuklear.set_style(4, 255, 0xffffffff)
    end,
    
    tech = function()

        colors.bg1 = 0xff177772
        colors.bg2 = 0xff29f9e5
        colors.fg1 = 0x800c3d46

        nuklear.set_style(3, 0, colors.white)                 -- Set which style index to use (0->5)

        -- nuklear.set_style_prop(0, colors.white)            -- text color 
        -- nuklear.set_style_prop(1, colors.techalpha)        -- bg color 

        -- nuklear.set_style_prop(2, colors.paynes_gray)      -- header color 
        -- nuklear.set_style_prop(3, colors.white)            -- border color 

        -- nuklear.set_style_prop(4, colors.gunmetal)         -- button color
        -- nuklear.set_style_prop(5, colors.cadet_gray)       -- button hover color
        -- nuklear.set_style_prop(6, colors.light_blue)       -- button active color

        -- nuklear.set_style_prop(7, colors.paynes_gray)      -- toggle color
        -- nuklear.set_style_prop(8, colors.cadet_gray)       -- toggle hover color
        -- nuklear.set_style_prop(9, colors.light_blue)       -- toggle active color

        -- nuklear.set_style_prop(10, colors.paynes_dark)     -- select color
        -- nuklear.set_style_prop(11, colors.light_blue)      -- select active color
        
        -- nuklear.set_style_prop(12, colors.paynes_gray)     -- slider color
        -- nuklear.set_style_prop(13, colors.cadet_gray)      -- slider cursor
        -- nuklear.set_style_prop(14, colors.paynes_gray)     -- slider hover
        -- nuklear.set_style_prop(15, colors.paynes_gray)     -- slider active

        -- nuklear.set_style_prop(16, colors.paynes_gray)     -- property color

        nuklear.set_style_prop(17, colors.techfg1)            -- edit color 
        -- nuklear.set_style_prop(18, colors.light_blue)      -- edit cursor color

        -- nuklear.set_style_prop(19, colors.paynes_gray)     -- combo color
        
        nuklear.set_style_prop(20, colors.tech_black)         -- chart bg color
        -- nuklear.set_style_prop(21, colors.tech_black)      -- chart color
        -- nuklear.set_style_prop(22, colors.tech_black)      -- chart color highlight

        -- nuklear.set_style_prop(23, colors.tech_black)      -- scrollbar color
        -- nuklear.set_style_prop(24, colors.tech_black)      -- scrollbar cursor color
        -- nuklear.set_style_prop(25, colors.tech_black)      -- scrollbar cursor hover color
        -- nuklear.set_style_prop(26, colors.tech_black)      -- scrollbar cursor active color

        nuklear.set_style_prop(27, colors.techfg1)         -- tab header color 
    end,

    gray_blue = function()

        nuklear.set_style(3, 0, colors.white)              -- text color

        nuklear.set_style_prop(1, 0xe0253237)              -- bg color 

        nuklear.set_style_prop(2, colors.paynes_gray)      -- header color 
        nuklear.set_style_prop(3, colors.light_blue)       -- border color 

        nuklear.set_style_prop(4, colors.gunmetal)         -- button color
        nuklear.set_style_prop(5, colors.cadet_gray)       -- button hover color
        nuklear.set_style_prop(6, colors.light_blue)       -- button active color

        nuklear.set_style_prop(7, colors.paynes_gray)      -- toggle color
        nuklear.set_style_prop(8, colors.cadet_gray)       -- toggle hover color
        nuklear.set_style_prop(9, colors.light_blue)       -- toggle active color

        nuklear.set_style_prop(10, colors.paynes_dark)     -- select color
        nuklear.set_style_prop(11, colors.light_blue)      -- select active color
        
        nuklear.set_style_prop(12, colors.paynes_gray)     -- slider color
        nuklear.set_style_prop(13, colors.cadet_gray)      -- slider cursor
        nuklear.set_style_prop(14, colors.paynes_gray)     -- slider hover
        nuklear.set_style_prop(15, colors.paynes_gray)     -- slider active

        nuklear.set_style_prop(16, colors.paynes_gray)     -- property color

        nuklear.set_style_prop(17, colors.paynes_gray)     -- edit color 
        nuklear.set_style_prop(18, colors.light_blue)      -- edit cursor color

        nuklear.set_style_prop(19, colors.paynes_gray)     -- combo color
        
        nuklear.set_style_prop(27, colors.paynes_gray)     -- tab header color 
    end,
}

-----------------------------------------------------------------------------------

return themes

-----------------------------------------------------------------------------------
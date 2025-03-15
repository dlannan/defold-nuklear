-- A util for makin themes. Create a theme, and then add it to the theme pool

local indexes = {
    NK_COLOR_TEXT                = 0,
    NK_COLOR_WINDOW              = 1,
    NK_COLOR_HEADER              = 2,
    NK_COLOR_BORDER              = 3,
    NK_COLOR_BUTTON              = 4,
    NK_COLOR_BUTTON_HOVER        = 5,
    NK_COLOR_BUTTON_ACTIVE       = 6,
    NK_COLOR_TOGGLE              = 7,
    NK_COLOR_TOGGLE_HOVER        = 8,
    NK_COLOR_TOGGLE_CURSOR       = 9,
    NK_COLOR_SELECT              = 10,
    NK_COLOR_SELECT_ACTIVE       = 11,
    NK_COLOR_SLIDER              = 12,
    NK_COLOR_SLIDER_CURSOR       = 13, 
    NK_COLOR_SLIDER_CURSOR_HOVER = 14,
    NK_COLOR_SLIDER_CURSOR_ACTIVE = 15,
    NK_COLOR_PROPERTY            = 16, 
    NK_COLOR_EDIT                = 17,
    NK_COLOR_EDIT_CURSOR         = 18,
    NK_COLOR_COMBO               = 19,
    NK_COLOR_CHART               = 20,
    NK_COLOR_CHART_COLOR         = 21,
    NK_COLOR_CHART_COLOR_HIGHLIGHT = 22,
    NK_COLOR_SCROLLBAR           = 23,
    NK_COLOR_SCROLLBAR_CURSOR    = 24,
    NK_COLOR_SCROLLBAR_CURSOR_HOVER = 25,
    NK_COLOR_SCROLLBAR_CURSOR_ACTIVE = 26,
    NK_COLOR_TAB_HEADER          = 27,
}

local theme_index_keys = {}
for k,v in pairs(indexes) do
    theme_index_keys[v+1] = tostring(k)
end

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

    indexes = indexes,
    editor_theme = {},

    colors = colors,

    theme_names = { "default", "custom", "tech", "gray_blue" },
    
    default = function()

        nuklear.set_style(4, 255, 0xffffffff)
        nuklear.set_style_table()
    end,

    custom = function()
        nuklear.set_style(2, 255, 0xffffffff)
        nuklear.set_style_table()
    end,
    
    tech = function()

        colors.bg1 = 0xff177772
        colors.bg2 = 0xff29f9e5
        colors.fg1 = 0x800c3d46

        nuklear.set_style(3, 0, colors.white)                 -- Set which style index to use (0->5)

        -- nuklear.set_style_prop(indexes.NK_COLOR_TEXT, colors.techfg1)            -- text color 
        -- nuklear.set_style_prop(indexes.NK_COLOR_WINDOW, colors.techalpha)        -- bg color 

        nuklear.set_style_prop(indexes.NK_COLOR_HEADER, colors.techfg1)      -- header color 
        -- nuklear.set_style_prop(indexes.NK_COLOR_BORDER, colors.white)            -- border color 

        nuklear.set_style_prop(indexes.NK_COLOR_BUTTON, colors.gunmetal)         -- button color
        nuklear.set_style_prop(indexes.NK_COLOR_BUTTON_HOVER, colors.cadet_gray)       -- button hover color
        nuklear.set_style_prop(indexes.NK_COLOR_BUTTON_ACTIVE, colors.paynes_gray)       -- button active color

        nuklear.set_style_prop(indexes.NK_COLOR_TOGGLE, colors.paynes_gray)      -- toggle color
        -- nuklear.set_style_prop(indexes.NK_COLOR_TOGGLE_HOVER, colors.cadet_gray)       -- toggle hover color
        -- nuklear.set_style_prop(indexes.NK_COLOR_TOGGLE_CURSOR, colors.light_blue)       -- toggle active color

        nuklear.set_style_prop(indexes.NK_COLOR_SELECT, colors.techfg1)                -- select color
        nuklear.set_style_prop(indexes.NK_COLOR_SELECT_ACTIVE, colors.paynes_dark)        -- select active color
        
        nuklear.set_style_prop(indexes.NK_COLOR_SLIDER, colors.paynes_gray)     -- slider color
        -- nuklear.set_style_prop(indexes.NK_COLOR_SLIDER_CURSOR, colors.cadet_gray)      -- slider cursor
        -- nuklear.set_style_prop(indexes.NK_COLOR_SLIDER_CURSOR_HOVER, colors.paynes_gray)     -- slider hover
        -- nuklear.set_style_prop(indexes.NK_COLOR_SLIDER_CURSOR_ACTIVE, colors.paynes_gray)     -- slider active

        nuklear.set_style_prop(indexes.NK_COLOR_PROPERTY, colors.paynes_gray)     -- property color

        nuklear.set_style_prop(indexes.NK_COLOR_EDIT, colors.techfg1)            -- edit color 
        -- nuklear.set_style_prop(indexes.NK_COLOR_EDIT_CURSOR, colors.light_blue)      -- edit cursor color

        nuklear.set_style_prop(indexes.NK_COLOR_COMBO, colors.techfg1)     -- combo color
        
        nuklear.set_style_prop(indexes.NK_COLOR_CHART, colors.tech_black)         -- chart bg color
        nuklear.set_style_prop(indexes.NK_COLOR_CHART_COLOR, colors.tech_black)      -- chart color
        -- nuklear.set_style_prop(indexes.NK_COLOR_CHART_COLOR_HIGHLIGHT, colors.tech_black)      -- chart color highlight

        nuklear.set_style_prop(indexes.NK_COLOR_SCROLLBAR, colors.tech_black)      -- scrollbar color
        -- nuklear.set_style_prop(indexes.NK_COLOR_SCROLLBAR_CURSOR, colors.tech_black)      -- scrollbar cursor color
        -- nuklear.set_style_prop(indexes.NK_COLOR_SCROLLBAR_CURSOR_HOVER, colors.tech_black)      -- scrollbar cursor hover color
        -- nuklear.set_style_prop(indexes.NK_COLOR_SCROLLBAR_CURSOR_ACTIVE, colors.tech_black)      -- scrollbar cursor active color

        nuklear.set_style_prop(indexes.NK_COLOR_TAB_HEADER, colors.techfg1)         -- tab header color 
        nuklear.set_style_table()
    end,

    gray_blue = function()

        nuklear.set_style(3, 0, colors.white)              -- text color
        
        nuklear.set_style_prop(indexes.NK_COLOR_TEXT, colors.white)
        nuklear.set_style_prop(indexes.NK_COLOR_WINDOW, 0xe0253237)              -- bg color 

        nuklear.set_style_prop(indexes.NK_COLOR_HEADER, colors.paynes_gray)      -- header color 
        nuklear.set_style_prop(indexes.NK_COLOR_BORDER, colors.light_blue)       -- border color 

        nuklear.set_style_prop(indexes.NK_COLOR_BUTTON, colors.gunmetal)         -- button color
        nuklear.set_style_prop(indexes.NK_COLOR_BUTTON_HOVER, colors.cadet_gray)       -- button hover color
        nuklear.set_style_prop(indexes.NK_COLOR_BUTTON_ACTIVE, colors.light_blue)       -- button active color

        nuklear.set_style_prop(indexes.NK_COLOR_TOGGLE, colors.paynes_gray)      -- toggle color
        nuklear.set_style_prop(indexes.NK_COLOR_TOGGLE_HOVER, colors.cadet_gray)       -- toggle hover color
        nuklear.set_style_prop(indexes.NK_COLOR_TOGGLE_CURSOR, colors.light_blue)       -- toggle active color

        nuklear.set_style_prop(indexes.NK_COLOR_SELECT, colors.paynes_dark)     -- select color
        nuklear.set_style_prop(indexes.NK_COLOR_SELECT_ACTIVE, colors.light_blue)      -- select active color
        
        nuklear.set_style_prop(indexes.NK_COLOR_SLIDER, colors.paynes_gray)     -- slider color
        nuklear.set_style_prop(indexes.NK_COLOR_SLIDER_CURSOR, colors.cadet_gray)      -- slider cursor
        nuklear.set_style_prop(indexes.NK_COLOR_SLIDER_CURSOR_HOVER, colors.paynes_gray)     -- slider hover
        nuklear.set_style_prop(indexes.NK_COLOR_SLIDER_CURSOR_ACTIVE, colors.paynes_gray)     -- slider active

        nuklear.set_style_prop(indexes.NK_COLOR_PROPERTY, colors.paynes_gray)     -- property color

        nuklear.set_style_prop(indexes.NK_COLOR_EDIT, colors.paynes_gray)     -- edit color 
        nuklear.set_style_prop(indexes.NK_COLOR_EDIT_CURSOR, colors.light_blue)      -- edit cursor color

        nuklear.set_style_prop(indexes.NK_COLOR_COMBO, colors.paynes_gray)     -- combo color

        -- nuklear.set_style_prop(indexes.NK_COLOR_COMBO, colors.paynes_gray)     -- combo color

        -- nuklear.set_style_prop(indexes.NK_COLOR_CHART, colors.tech_black)      -- chart bg color
        
        -- nuklear.set_style_prop(indexes.NK_COLOR_CHART_COLOR, colors.tech_black)      -- chart color
        -- nuklear.set_style_prop(indexes.NK_COLOR_CHART_COLOR_HIGHLIGHT, colors.tech_black)      -- chart color highlight

        -- nuklear.set_style_prop(indexes.NK_COLOR_SCROLLBAR, colors.tech_black)      -- scrollbar color
        -- nuklear.set_style_prop(indexes.NK_COLOR_SCROLLBAR_CURSOR, colors.tech_black)      -- scrollbar cursor color
        -- nuklear.set_style_prop(indexes.NK_COLOR_SCROLLBAR_CURSOR_HOVER, colors.tech_black)      -- scrollbar cursor hover color
        -- nuklear.set_style_prop(indexes.NK_COLOR_SCROLLBARCURSOR_ACTIVE, colors.tech_black)      -- scrollbar cursor active color
        
        nuklear.set_style_prop(indexes.NK_COLOR_TAB_HEADER, colors.paynes_gray)     -- tab header color 

        nuklear.set_style_table()
    end,
}

-----------------------------------------------------------------------------------
-- Save a theme in the above format as lua. 
--    This allows themes to eb used without the editor and this file. 

local function save_theme( filename )

    local fh = io.open(filename, "w")
    if(fh == nil) then 
        pprint("[Error Save Theme] Cannot save to file: "..filename)
        return nil
    end 

    -- Always save out a theme into the custom style. Dont overwrite builtin styles
    fh:write("-- -----------------------------------------------------------------------\n")
    fh:write("-- Auto generated theme file. Do not edit!\n")
    fh:write("-- -----------------------------------------------------------------------\n")
    fh:write("nuklear.set_style(2, 255, 0xffffffff)  -- set custom style\n")

    for k,v in ipairs(theme_index_keys) do        
        fh:write("nuklear.set_style_prop(indexes."..v..", "..string.format("0x%0x", nuklear.get_style_prop(indexes[v]))..")\n" )
    end
    fh:write("nuklear.set_style_table()\n")
    fh:close()

end

-----------------------------------------------------------------------------------
-- Loading a theme is really simple. 
--    Loadstring and run it. We cannot use require, because it only loads once.

local function load_theme( filename )

    local fh = io.open(filename, "r")
    if(fh == nil) then 
        pprint("[Error Save Theme] Cannot save to file: "..filename)
        return nil
    end 
    local themestr = fh:read("*a")
    fh:close()

    local func = assert(load(themestr, themestr, "t" , {indexes=indexes, nuklear=nuklear}))
    func()
end

-----------------------------------------------------------------------------------
-- Theme editor panel. Load, Save and Modify your theme. 
--    Themes are in the same format as above, and can be used in place of this file.

themes.theme_panel = function ( self, font, left, top, width, height, readonly )

	local y = top
	local x = left

    local flags = bit.bor(self.flags.NK_WINDOW_TITLE, self.flags.NK_WINDOW_BORDER)
	flags = bit.bor(flags, self.flags.NK_WINDOW_MOVABLE)
	flags = bit.bor(flags, self.flags.NK_WINDOW_MINIMIZABLE)
    flags = bit.bor(flags, self.flags.NK_WINDOW_NO_SCROLLBAR)

    local bg_current = nuklear.get_style_prop( indexes.NK_COLOR_WINDOW )
    local txt_current = nuklear.get_style_prop( indexes.NK_COLOR_TEXT )
    nuklear.set_style_prop(indexes.NK_COLOR_WINDOW, 0xff000000)
    nuklear.set_style_prop(indexes.NK_COLOR_TEXT, 0xffffffff)
    nuklear.set_style_table()
        
	local winshow = nuklear.begin_window( "Theme Editor", x, y, width, height, flags)

    -- Using index 2 for this panel. Which means editing it wont change anything.
    local newx, newy, wide, high = nuklear.get_bounds_window()
    -- Ensure alpga is enabled on bg for this panel
    

    nuklear.set_font( font.fontid )
    --nuklear.fill_rect(left, top, width + 30, height + 30, 0, 0x000001ff)

    nuklear.layout_row_dyn(30, 1)
    local select_theme = tonumber(nuklear.combo( themes.theme_names, self.theme_select or 2, 25, 280, 200 ))

    nuklear.layout_row_dyn(30, 1)
    local select_index = nuklear.combo( theme_index_keys, self.theme_index_select or 0, 25, 280, 200 )
    if(select_index ~= self.theme_index_select) then 
    
        local indexcol = nuklear.get_style_prop(select_index)
        self.theme_index_color = indexcol 
        self.theme_index_select = select_index
    end 
            
    local index_color = nuklear.picker_color_complex( self.theme_index_color or 0xffffffff )
    
    nuklear.layout_row_dyn(30, 1)
    local set_style = nuklear.button_label_active( "Apply Style" )

    nuklear.layout_row_dyn(30, 1)
    self.style_path = nuklear.edit_string(10,  self.style_path or "./config/custom_theme.lua", 128, 1)
    
    nuklear.layout_row_dyn(30, 2)
    local load_style = nuklear.button_label_active( "Load Style" )
    local save_style = nuklear.button_label_active( "Save Style" )
    
    if(save_style == 1) then 
        save_theme( self.style_path )
    end

    if(load_style == 1) then 
        load_theme( self.style_path )
    end

    if(select_theme ~= self.theme_select) then 
        self.theme_select = select_theme
        themes[themes.theme_names[self.theme_select+1]]()
    end

    nuklear.set_style_prop(indexes.NK_COLOR_WINDOW, bg_current)
    nuklear.set_style_prop(indexes.NK_COLOR_TEXT, txt_current)
    nuklear.set_style_table()

    if (index_color ~= self.theme_index_color) then 
        self.theme_index_color = index_color
        nuklear.set_style_prop(self.theme_index_select,  self.theme_index_color)
    end
    
    if(set_style == 1) then 
        nuklear.set_style_table()
    end
    
    nuklear.end_window()
end

-----------------------------------------------------------------------------------

themes.load = load_theme 
themes.save = save_theme

-----------------------------------------------------------------------------------

return themes

-----------------------------------------------------------------------------------

local tf = require("nuklear.utils.transforms")

--------------------------------------------------------------------------------
local nuklear_gui = {
    colors = {
        bg1     = 0xffffffff,
        bg2     = 0xff111111, 
        fg1     = 0xffffffff,
    },
    res  = {
        width = 960,
        height = 960, 
        channels = 4,
    }, 
    camera = {
        url = "/camera#camera",
	},
	window = {
		width = 960,
		height = 640,
	},

    win_ctr = 0,
}

--------------------------------------------------------------------------------

nuklear_gui.flags = {
-- /// #### nk_panel_flags
-- /// Flag                            --| Description
-- /// ----------------------------------|----------------------------------------
    NK_WINDOW_BORDER = 1,              --| Draws a border around the window to visually separate window from the background
    NK_WINDOW_MOVABLE = 2,             --| The movable flag indicates that a window can be moved by user input or by dragging the window header
    NK_WINDOW_SCALABLE = 4,            --| The scalable flag indicates that a window can be scaled by user input by dragging a scaler icon at the button of the window
    NK_WINDOW_CLOSABLE = 8,            --| Adds a closable icon into the header
    NK_WINDOW_MINIMIZABLE = 16,        --| Adds a minimize icon into the header
    NK_WINDOW_NO_SCROLLBAR = 32,       --| Removes the scrollbar from the window
    NK_WINDOW_TITLE = 64,              --| Forces a header at the top at the window showing the title
    NK_WINDOW_SCROLL_AUTO_HIDE = 128,  --| Automatically hides the window scrollbar if no user interaction: also requires delta time in `nk_context` to be set each frame
    NK_WINDOW_BACKGROUND = 256,        --| Always keep window in the background
    NK_WINDOW_SCALE_LEFT = 512,        --| Puts window scaler in the left-bottom corner instead right-bottom
    NK_WINDOW_NO_INPUT = 1024,         --| Prevents window of scaling, moving or getting focus
}

--------------------------------------------------------------------------------

nuklear_gui.world_to_screen = function (self, pos, width, height, x, y)
	local proj = go.get(self.camera.url, "projection")
	local view = go.get(self.camera.url, "view")
	local m = proj * view
	local pv = vmath.vector4( pos.x, pos.y, pos.z, 1 )

	pv = m * pv
	pv = pv * (1/pv.w)
	pv.x = (pv.x / 2 + 0.5) * width + x
	pv.y = (pv.y / 2 + 0.5) * height + y

	return vmath.vector3(pv.x, pv.y, 0) 
end

--------------------------------------------------------------------------------

nuklear_gui.get_screen_pos = function( self, x, y, z )
	local issrot = vmath.quat()
	local lp = vmath.rotate(issrot, vmath.vector3(x, y, z))
	local p = self:world_to_screen( lp, self.window.width, self.window.height, 0, 0 )
	return vmath.vector3(p.x, p.y - 60, 0)
end

--------------------------------------------------------------------------------

nuklear_gui.init = function(self, width, height, bgalpha)

	self.winctr = 0
    self.res.width = width
    self.res.height = height
    self.window.width, self.window.height = window.get_size()

 	self.resource_path = go.get("/gui#model", "texture0")
 
 	self.buffer_info = {
 		buffer = buffer.create(width * height, {{
            name = hash("rgba"), 
            type = buffer.VALUE_TYPE_UINT8, 
            count = self.res.channels
        }}),
 		width = width,
 		height = height,
 		channels = self.res.channels,
 		premultiply_alpha = true
 	}
 
 	self.header = {
 		width = width, 
 		height = height, 
 		type = resource.TEXTURE_TYPE_2D, 
 		format = resource.TEXTURE_FORMAT_RGBA, 
 		num_mip_maps = 1
 	}

    self.edge_top = (self.window.width-self.window.height) / 2
    if(self.window.height >= self.window.width) then self.edge_top = 0 end
 
	resource.set_texture(self.resource_path, self.header, self.buffer_info.buffer)
	nuklear.init(width, height, 0, self.buffer_info.buffer, 2, bgalpha, self.colors.bg2)
 
	local fontdata, error = sys.load_resource("/example/fonts/Pixeltype.ttf")
	nuklear.setup_font( fontdata, #fontdata, 14.0, width )
end

--------------------------------------------------------------------------------

nuklear_gui.widget_panel = function (self, title, left, top, width, height, panel_function)

	local y = self.edge_top + top
	local x = left

    local flags = bit.bor(self.flags.NK_WINDOW_TITLE, self.flags.NK_WINDOW_BORDER)
    local flags = bit.bor(flags, self.flags.NK_WINDOW_MOVABLE)
    local flags = bit.bor(flags, self.flags.NK_WINDOW_CLOSABLE)
    local flags = bit.bor(flags, self.flags.NK_WINDOW_SCALABLE)

	local winshow = nuklear.begin_window( title , x, y, width, height, flags)
	if( winshow == 1) then 

	    if(panel_function) then panel_function(left, top, width, height) end
	end
	nuklear.end_window()
	return winshow
end	

--------------------------------------------------------------------------------

nuklear_gui.widget_button = function (self, text, left, top, width, height)

	local y = self.edge_top + top
	local x = left

	local button = nuklear.begin_window( text , x, y, width, height, self.flags.NK_WINDOW_NO_SCROLLBAR)

	nuklear.layout_space_begin(50, 2)
	nuklear.layout_space_push(0, 0, width, height)
	local res = nuklear.button_label(text, 1)
	nuklear.layout_space_end()

	nuklear.end_window()
	return res
end	


--------------------------------------------------------------------------------

nuklear_gui.widget_text = function (self, left, top, text, value, lvl1, lvl2)

	local y = self.edge_top + top
	local x = left

	lvl1 = lvl1 or 1.0
	lvl2 = lvl2 or 1.0

	nuklear.begin_window( "win_"..self.winctr , x, y, 400, 60, self.flags.NK_WINDOW_NO_SCROLLBAR)
	
	nuklear.stroke_rect(x + 4, y, 190, 34, 0, 2, self.colors.bg1)
	nuklear.fill_rect(x + 4, y, 190, 3, 0, self.colors.bg1)

	nuklear.fill_rect(x + 7, y + 5 + (28 * (1.0-lvl1)), 5, 28 * lvl1, 0, self.colors.bg2)
	nuklear.fill_rect(x + 14, y + 5 + (28 * (1.0-lvl2)), 5, 28 * lvl2, 0, self.colors.bg1)

	nuklear.fill_rect(x + 21, y + 5, 173, 28, 0, self.colors.fg1)

	-- nuklear.layout_row_static(10, 400, 1)
	nuklear.layout_space_begin(50, 2)
	nuklear.layout_space_push(22, 0, 300, 20)
	nuklear.label(text, 1)
		
	-- nuklear.layout_row_static(10, 400, 1)
	nuklear.layout_space_push(55, 12, 300, 20)
	nuklear.label(value, 1)
	nuklear.layout_space_end()

	nuklear.end_window()
	self.winctr = self.winctr + 1
end	

--------------------------------------------------------------------------------

nuklear_gui.widget_text_movable = function(self, left, top, spacer, text, value, lvl1, lvl2)

	local y = self.edge_top + top
	local x = left

	lvl1 = lvl1 or 1.0
	lvl2 = lvl2 or 1.0
	
	nuklear.begin_window( "win_"..self.winctr , x, y, 400 + spacer, 60,  self.flags.NK_WINDOW_NO_SCROLLBAR)
	
	nuklear.stroke_rect(x + 100 + spacer, y, 190, 34, 0, 2, self.colors.bg1)
	nuklear.fill_rect(x + 100 + spacer, y, 190, 3, 0, self.colors.bg1)
	
	nuklear.fill_rect(x + 102 + spacer, y + 5 + (28 * (1.0-lvl1)), 5, 28 * lvl1, 0, self.colors.bg1)
	nuklear.fill_rect(x + 109 + spacer, y + 5 + (28 * (1.0-lvl2)), 5, 28 * lvl2, 0, self.colors.bg1)

	nuklear.fill_rect(x + 116 + spacer, y + 5, 173, 28, 0, self.colors.fg1)

	nuklear.stroke_line( x + 20, y + 15 + 20, x + 100, y + 2, 1, self.colors.bg2 )
	nuklear.stroke_line( x + 100, y + 2, x + 100 + spacer, y + 2, 1, self.colors.bg2 )
	nuklear.stroke_circle( x + 10, y + 5 + 20, 20, 20, 1, self.colors.bg1 )
	nuklear.stroke_circle( x + 9, y + 4 + 20, 22, 22, 1, self.colors.bg1 )
	nuklear.stroke_circle( x + 17, y + 12 + 20, 6, 6, 1, self.colors.bg1 )

	nuklear.layout_space_begin(50, 2)
	nuklear.layout_space_push(100 + 22 + spacer, 0, 300, 20)
	nuklear.label(text, 1)

	nuklear.layout_space_push(100 + 55 + spacer, 12, 300, 20)
	nuklear.label(value, 1)

	nuklear.end_window()
	self.winctr = self.winctr + 1
end	

--------------------------------------------------------------------------------

nuklear_gui.render = function(self)
    nuklear.render(0,0,0,0 , self.buffer_info.buffer)
	resource.set_texture(self.resource_path, self.header, self.buffer_info.buffer)
	self.winctr = 0
end

--------------------------------------------------------------------------------

return nuklear_gui

--------------------------------------------------------------------------------
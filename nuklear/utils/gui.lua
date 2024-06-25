
local tf = require("nuklear.utils.transforms")
local themes = require("nuklear.utils.themes")

local tinsert = table.insert 

--------------------------------------------------------------------------------
local nuklear_gui = {

	themes = themes,
    colors = themes.colors,
	fonts = {},

	gui_data = nil,

    res  = {
        width = 960,
        height = 960, 
        channels = 4,
		resolution = 960,
    }, 
    camera = {
        url = "/camera#camera",
	},
	window = {
		width = nil,
		height = 640,
		offx = 0, 
		offy = 0,
	},

    win_ctr = 0,

    mouse = { 
        x = 0, 
        y = 0 
    },
	
    evt_queue = {},
	prev_button = 0,

	updates = {},
	inits = {},
}

--------------------------------------------------------------------------------
-- Helpers

local function getTopDisplayEdge(vertFOV, panel_distance, gui_resolution)
	local visible_vertical = math.tan(vertFOV /2) * panel_distance * gui_resolution * 2.0
	return ( gui_resolution - visible_vertical ) * 0.5
end

local function getCamDistToSeeSize(FOV, size)
	return (size/2) / math.tan(FOV/2)
end

local function getHorizFOV(vertFOV, aspect)
	return 2 * math.atan(math.tan(vertFOV/2) * aspect)
end

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

nuklear_gui.get_screen_pos = function( self, x, y, z, rot )
	local issrot = rot or vmath.quat()
	local lp = vmath.rotate(issrot, vmath.vector3(x, y, z))
	local p = self:world_to_screen( lp, self.window.width, self.window.height, self.window.offx, self.window.offy )

	p.x = p.x * self.window.scalex
	p.y = p.y * self.window.scaley - self.edge_top
	return vmath.vector3(p.x, p.y, 0)
end

--------------------------------------------------------------------------------

nuklear_gui.window_resized = function(self, data)

	self.mouse = { x = 0, y = 0 }
	self.evt_queue = {}
	self.updates = {}

	self:init()
	nuklear.window_scissor(0, 0, data.width, data.height)

	self:reload_fonts()
	nuklear.set_font( self.first_font.fontid )
end

--------------------------------------------------------------------------------

nuklear_gui.setup_gui = function( self, gui_quad, camera_url, scale_texture )

	self.camera.url = camera_url or self.camera.url

	local newwidth, newheight = window.get_size()
	-- Trying to fit width of gui quad into exact position 
	self.window.width = newwidth
	self.window.height = newheight

	local res = self.window.width * scale_texture
	if( self.window.height * scale_texture > res) then 
		res = self.window.height * scale_texture
	end

	self.res.resolution = { w = self.window.width * scale_texture, h = self.window.height * scale_texture }
	local gui_resolution = self.res.resolution

	local aspect = newwidth/newheight
	local vertFOV = go.get(self.camera.url, "fov")
	local horizFOV = getHorizFOV(vertFOV, aspect)
	pprint(horizFOV.."   "..self.res.resolution.w)
	local aspectFOV = horizFOV / vertFOV
	--if( aspect < 1.0) then aspectScale = 0.95 end

	local panel_distance = getCamDistToSeeSize(horizFOV, 1.0)
	go.set_position(vmath.vector3(0,0,-panel_distance), gui_quad)
	go.set_scale(vmath.vector3(1.0, 1.0/aspect, 1.0), gui_quad)

	self.edge_top = 0 --getTopDisplayEdge(vertFOV, panel_distance, gui_resolution.h)
	if(aspect < 1.0) then self.edge_top = 0 end

	self.window.scalex = 1.0 -- gui_resolution.w / newwidth
	self.window.scaley = 1.0 -- aspectYScale
	self.window.offx = 0
end

--------------------------------------------------------------------------------
-- Queue your nkgui calls for update. This allows multiple nuklear scripts to render 
--   different layers or obejcts
nuklear_gui.queue_update = function(self, ctx, delta, func ) 
	
	tinsert(nuklear_gui.updates, { ctx = ctx, delta = delta, func = func } )
end 

--------------------------------------------------------------------------------

nuklear_gui.shutdown = function(self)

	nuklear.shutdown()
end

--------------------------------------------------------------------------------

nuklear_gui.queue_init = function( self, ctx, initfunc )
	tinsert(self.inits, { ctx = ctx, func = initfunc } )
end

--------------------------------------------------------------------------------

nuklear_gui.init = function(self, camera, texture_scale)

	texture_scale = texture_scale or 1.0
	self:setup_gui( "/nuklear_gui", camera, texture_scale )
	
	self.winctr = 0
	self.res.width = self.res.resolution.w
	self.res.height = self.res.resolution.h

	self.resource_path = go.get("/nuklear_gui#model", "texture0")
 
 	self.buffer_info = {
		buffer = buffer.create(self.res.resolution.w * self.res.resolution.h, {{
            name = hash("rgba"), 
            type = buffer.VALUE_TYPE_UINT8, 
            count = self.res.channels
        }}),
		width = self.res.resolution.w,
		height = self.res.resolution.h,
 		channels = self.res.channels,
 		premultiply_alpha = true
 	}
 
 	self.header = {
		width = self.res.resolution.w, 
		height = self.res.resolution.h, 
 		type = resource.TEXTURE_TYPE_2D, 
 		format = resource.TEXTURE_FORMAT_RGBA, 
 		num_mip_maps = 1
 	}

	if(self.new_resource_path) then 
		resource.release(self.new_resource_path)
	end
	self.new_resource_path = "/nuklear_gui.texturec"
	local newres = resource.create_texture(self.new_resource_path, self.header)

    -- self.edge_top = (self.window.width-self.window.height) / 2
    -- if(self.window.height >= self.window.width) then self.edge_top = 0 end
 
	resource.set_texture(self.resource_path, self.header, self.buffer_info.buffer)
	nuklear.init(self.res.resolution.w, self.res.resolution.h, 0, self.buffer_info.buffer)

	-- TODO: Nasty hack. Need to fix
	self.init_done = false 
	timer.delay(0.1, false, function()
		for k,initfunc in ipairs(self.inits) do 
			initfunc.func( initfunc.ctx )
		end
		self.init_done = true
	end)
end

--------------------------------------------------------------------------------

nuklear_gui.add_fonts = function( self, fonts )
	self.first_font = nil
	nuklear.begin_fonts()
	for k,font in pairs(fonts) do
		local fontdata, error = sys.load_resource(font.path)
		font.fontid = nuklear.add_font( fontdata, #fontdata, font.size, font.resolution )
		self.fonts[k] = font
		if(self.first_font == nil) then self.first_font = font end
	end
	nuklear.end_fonts()
end 

--------------------------------------------------------------------------------

nuklear_gui.reload_fonts = function( self )
	nuklear.begin_fonts()
	for k,font in pairs(self.fonts) do
		local fontdata, error = sys.load_resource(font.path)
		font.fontid = nuklear.add_font( fontdata, #fontdata, font.size, font.resolution )
	end
	nuklear.end_fonts()
end 

--------------------------------------------------------------------------------

nuklear_gui.widget_panel = function (self, title, left, top, width, height, panel_function, ctx)

	local y =  self.edge_top + top
	local x = left

    local flags = bit.bor(self.flags.NK_WINDOW_TITLE, self.flags.NK_WINDOW_BORDER)
	flags = bit.bor(flags, self.flags.NK_WINDOW_MOVABLE)
	flags = bit.bor(flags, self.flags.NK_WINDOW_MINIMIZABLE)
    -- flags = bit.bor(flags, self.flags.NK_WINDOW_CLOSABLE)
    flags = bit.bor(flags, self.flags.NK_WINDOW_SCALABLE)

	local winshow = nuklear.begin_window( title , x, y, width, height, flags)
	if( winshow == 1) then 
	    if(panel_function) then panel_function(ctx, left, top, width, height) end
	end
	
	local newx, newy, wide, high = nuklear.get_bounds_window()
	nuklear.end_window()
	return { show=winshow, x=newx, y=newy - self.edge_top, w=wide, h=high }
end	


--------------------------------------------------------------------------------

nuklear_gui.widget_panel_fixed = function (self, title, left, top, width, height, panel_function, ctx)

	local y = self.edge_top + top
	local x = left

	local flags = bit.bor(self.flags.NK_WINDOW_TITLE, self.flags.NK_WINDOW_BORDER)

	local winshow = nuklear.begin_window( title , x, y, width, height, flags)
	if( winshow == 1) then 
		if(panel_function) then panel_function(ctx, left, top, width, height) end
	end

	local newx, newy, wide, high = nuklear.get_bounds_window()
	nuklear.end_window()
	return winshow, newx, newy - self.edge_top , wide, high
end	

--------------------------------------------------------------------------------

nuklear_gui.widget_button = function (self, text, left, top, width, height)

	local y = self.edge_top + top
	local x = left

	local button = nuklear.begin_window( text , x, y, width+10, height+8, self.flags.NK_WINDOW_NO_SCROLLBAR)

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

nuklear_gui.widget_chart = function (self, left, top, text, lvl1, lvl2, charttbl)

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
	nuklear.layout_space_push(18, 12, 170, 18)
	nuklear.line_chart(0x1, charttbl);
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

nuklear_gui.widget_chart_movable = function(self, left, top, spacer, text, lvl1, lvl2, charttbl)

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

	--nuklear.layout_space_push(100 + 55 + spacer, 12, 300, 20)
	nuklear.layout_space_push(112 + spacer, 12, 170, 18)
	nuklear.line_chart( 0x1, charttbl);
	nuklear.layout_space_end()

	nuklear.end_window()
	self.winctr = self.winctr + 1
end	


--------------------------------------------------------------------------------

nuklear_gui.render = function(self)
	if(self.init_done == false) then return end
    nuklear.render(0,0,0,0 , self.buffer_info.buffer)
	resource.set_texture(self.resource_path, self.header, self.buffer_info.buffer)
	self.winctr = 0
end

--------------------------------------------------------------------------------
-- Notes: This handler relies on the input bindings from the example.
--        It is easy enough to modify this behavior if needed.

nuklear_gui.handle_input = function(self, caller, action_id, action)

    local evt_insert = false
    local evt_type = "button"
    local evt_button = 0

	local mousex = action.x + self.window.offx
	local mousey = self.window.height - action.y + self.edge_top

    -- Leftclick handler
	if action_id == hash("touch") or action_id == hash("button_left") then
        evt_insert = true 
        evt_type = "button"
        evt_button = 0
	end

    if action_id == hash("button_middle") then
        evt_insert = true 
        evt_type = "button"
        evt_button = 1
	end

	if action_id == hash("button_right") then
        evt_insert = true 
        evt_type = "button"
        evt_button = 2
	end

    if action_id == hash("wheel_up") then
        evt_type = "wheel"
        evt_dir = 1
    end
    
    if action_id == hash("wheel_down") then
        evt_type = "wheel"
        evt_dir = -1
	end    

    if(evt_type == "wheel") then 
        if(action.value == 1) then 
            tinsert(self.evt_queue, { 
                evt = "wheel", 
                button = 1, 
                x = mousex, 
                y = mousey, 
                value = action.value * evt_dir,
            } )
        end
	end
	if( action_id == hash("text") )  then 
		tinsert(self.evt_queue, { 
			evt = "text", 
			button = 1, 
			x = mousex, 
			y = mousey, 
			value = action.text,
		} )
	end
    
    if(evt_insert == true) then 
        if action.pressed == true then 
            tinsert(self.evt_queue, { 
                evt = evt_type, 
                button = evt_button, 
                x = mousex, 
                y = mousey, 
                down = 1,
            } )	
        end
		if action.released == true then 
            tinsert(self.evt_queue, { 
                evt = evt_type, 
                button = evt_button, 
                x = mousex, 
                y = mousey, 
                down = 0,
            } )	
        end
    end
	
    -- Mouse movement update events
	local xdiff = mousex - self.mouse.x 
	local ydiff = mousey - self.mouse.y 
	if( xdiff ~= 0 or ydiff ~= 0 ) then 
		tinsert(self.evt_queue, { evt = "motion", x = mousex, y = mousey } )
	end

    -- store for previous movememt
	self.mouse.x = mousex
	self.mouse.y = mousey
	return true
end

--------------------------------------------------------------------------------

nuklear_gui.update = function(self, caller, dt)

	if(self.init_done == false) then return end
	local events = #self.evt_queue
	nuklear.input_begin()
	for k,v in pairs(self.evt_queue) do 
		local mx = v.x * self.window.scalex
		local my = v.y * self.window.scaley

		if(v.evt == "button") then 
			nuklear.input_button( v.button, mx, my, v.down )
        elseif (v.evt == "motion") then 
			if(v.evt.down == 1) then nuklear.input_button( 0, mx, my, 1 ) end
			nuklear.input_motion( mx, my )
        elseif (v.evt == "wheel") then 
			nuklear.input_scroll( 0, v.value )
		elseif (v.evt == "text") then 
			nuklear.input_char( string.byte(v.value ) )
		end
	end
	nuklear.input_end()
	self.evt_queue = {}
end

--------------------------------------------------------------------------------

return nuklear_gui

--------------------------------------------------------------------------------
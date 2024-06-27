#define LIB_NAME "Nuklear"
#define MODULE_NAME "nuklear"

#include <dmsdk/sdk.h>
#include <dmsdk/dlib/crypt.h>

#include <vector>
#include <string>
#include <map>

#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_INCLUDE_SOFTWARE_FONT
#define STB_TRUETYPE_IMPLEMENTATION

#include "include/nuklear.h"
#include "include/nuklear_defold.h"

int do_overview(struct nk_context *ctx, int left, int top);

static int RES_WIDTH = 2048;
static int RES_HEIGHT = 2048;

/* init gui state */
static struct nk_context ctx;
static struct defold_context *defoldfb; 
static unsigned char *fb = nullptr;
static unsigned char *tex_scratch = nullptr;

static std::vector<struct nk_image> g_images;
static std::vector<struct nk_font *> g_fonts;

typedef struct stringdata {
    char *  value;
    int  *  length;
} stringdata;
static std::map<uint32_t, stringdata> g_editstrings;

// ----------------------------

static int nuklear_Begin_Window(lua_State *L)
{
    const char * name = luaL_checkstring(L, 1);
    int left = luaL_checknumber(L, 2);
    int top = luaL_checknumber(L, 3);
    int width = luaL_checknumber(L, 4);
    int height = luaL_checknumber(L, 5);
    int flags = luaL_checknumber(L, 6);
   
    // Flags example: NK_WINDOW_BORDER|NK_WINDOW_MOVABLE|NK_WINDOW_CLOSABLE
    int res = nk_begin(&defoldfb->ctx, name, nk_rect(left, top, width, height), flags);

    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_End_Window(lua_State *L)
{
    nk_end(&defoldfb->ctx);
    return 0;
}

// ----------------------------

static int nuklear_Get_Bounds_Window(lua_State *L)
{
    struct nk_rect bnd = nk_window_get_bounds(&defoldfb->ctx);
    lua_pushnumber(L, bnd.x);
    lua_pushnumber(L, bnd.y);
    lua_pushnumber(L, bnd.w);
    lua_pushnumber(L, bnd.h);
    return 4;
}

// ----------------------------

static int nuklear_BGColor_Window(lua_State *L)
{
    unsigned int color = luaL_checknumber(L, 1);

    struct nk_style *style = &defoldfb->ctx.style;
    struct nk_style_window* win = &style->window;
    nk_color old = win->fixed_background.data.color;
    win->fixed_background.data.color = nk_rgba_u32(color);
    lua_pushnumber( L, nk_color_u32(old) );
    return 1;
}

static int nuklear_Tooltip(lua_State *L)
{
    const char *text = luaL_checkstring(L, 1);
    struct nk_rect bounds;
    bounds = nk_widget_bounds(&defoldfb->ctx);
    if (nk_input_is_mouse_hovering_rect(&defoldfb->ctx.input, bounds))
        nk_tooltip(&defoldfb->ctx, text);
    return 0;
}

// ----------------------------

static int nuklear_Layout_Row_Dynamic(lua_State *L)
{
    int height = luaL_checknumber(L, 1);
    int widgets = luaL_checknumber(L, 2);
    nk_layout_row_dynamic(&defoldfb->ctx, height, widgets);    
    return 0;
}

// ----------------------------

static int nuklear_Group_Begin(lua_State *L)
{
    const char *title = luaL_checkstring(L, 1);
    int flags = luaL_checknumber(L, 2);
    int res = nk_group_begin(&defoldfb->ctx, title, flags); 
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Group_End(lua_State *L)
{
    nk_group_end(&defoldfb->ctx); 
    return 0;
}

// ----------------------------

static int nuklear_Push_Scissor(lua_State *L)
{
    float left = luaL_checknumber(L, 1);
    float top = luaL_checknumber(L, 2);
    float width = luaL_checknumber(L, 3);
    float height = luaL_checknumber(L, 4);

    struct nk_command_buffer *canvas = nk_window_get_canvas(&defoldfb->ctx);  

    if(left == -1.0f || top == -1.0f || width == -1.0f || height == -1.0f)
        nk_push_scissor(canvas, nk_null_rect);
    else
        nk_push_scissor(canvas, nk_rect(left, top, width, height));
    return 0;
}

// ----------------------------

static int nuklear_Window_Scissor(lua_State *L)
{
    float left = luaL_checknumber(L, 1);
    float top = luaL_checknumber(L, 2);
    float width = luaL_checknumber(L, 3);
    float height = luaL_checknumber(L, 4);

    nk_defold_scissor(defoldfb, left, top, width, height);
    return 0;
}

// ----------------------------

static int nuklear_Layout_Row_Static(lua_State *L)
{
    int height = luaL_checknumber(L, 1);
    int width = luaL_checknumber(L, 2);
    int widgets = luaL_checknumber(L, 3);
    nk_layout_row_static(&defoldfb->ctx, height, width, widgets);    
    return 0;
}

// ----------------------------

static int nuklear_Layout_Space_Begin(lua_State *L)
{
    int height = luaL_checknumber(L, 1);
    int widgets = luaL_checknumber(L, 2);
    nk_layout_space_begin(&defoldfb->ctx, NK_STATIC, height, widgets);    
    return 0;
}

// ----------------------------

static int nuklear_Layout_Space_Push(lua_State *L)
{
    int x = luaL_checknumber(L, 1);
    int y = luaL_checknumber(L, 2);
    int width = luaL_checknumber(L, 3);
    int height = luaL_checknumber(L, 4);
    nk_layout_space_push(&defoldfb->ctx, nk_rect(x, y, width, height));    
    return 0;
}

// ----------------------------

static int nuklear_Layout_Space_End(lua_State *L)
{
    nk_layout_space_end(&defoldfb->ctx);    
    return 0;
}


// ----------------------------

static int nuklear_Label(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    int ltype = luaL_checknumber(L, 2);
    nk_label(&defoldfb->ctx, name, ltype);
    return 0;
}

// ----------------------------

static int nuklear_Button_Label(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    int res = nk_button_label(&defoldfb->ctx, name);
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Selectable_Label(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    int style = luaL_checknumber(L, 2);
    int value = luaL_checknumber(L, 3);
    nk_selectable_label(&defoldfb->ctx, name, style, &value);
    lua_pushnumber(L, value);
    return 1;
}

// ----------------------------

static int nuklear_Selectable_Image_Label(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    int imageid = luaL_checknumber(L, 2);
    int style = luaL_checknumber(L, 3);
    int value = luaL_checknumber(L, 4);
    nk_selectable_image_label(&defoldfb->ctx,  g_images[imageid], name, style, &value);
    lua_pushnumber(L, value);
    return 1;
}


// ----------------------------

static int nuklear_Button_Label_Active(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    /* active tab gets highlighted */
    struct nk_style_item button_color = defoldfb->ctx.style.button.normal;
    defoldfb->ctx.style.button.normal = defoldfb->ctx.style.button.active;
    int res = nk_button_label(&defoldfb->ctx, name);
    defoldfb->ctx.style.button.normal = button_color;
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Button_Image(lua_State *L)
{
    int imageid = luaL_checknumber(L, 1);
    int res = nk_button_image(&defoldfb->ctx, g_images[imageid]);
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Option_Label(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    int state = luaL_checknumber(L, 2);
    int selected = nk_option_label(&defoldfb->ctx, name, state == 1);
    lua_pushnumber(L, selected);
    return 1;
}

// ----------------------------

static int nuklear_Layout_Tree_Push(lua_State *L)
{
    int treetype = luaL_checknumber(L, 1);
    std::string treetitle = luaL_checkstring(L, 2);
    int treemode = luaL_checknumber(L, 3);
    int res = nk_tree_state_push(&defoldfb->ctx, (enum nk_tree_type)treetype, treetitle.c_str(), (enum nk_collapse_states *)&treemode);
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Layout_Tree_Pop(lua_State *L)
{
    nk_tree_state_pop(&defoldfb->ctx);
    return 0;
}


// ----------------------------

static int nuklear_Layout_Row_Begin(lua_State *L)
{
    int height = luaL_checknumber(L, 1);
    int widgets = luaL_checknumber(L, 2);
    nk_layout_row_begin(&defoldfb->ctx, NK_STATIC, height, widgets);
    return 0;
}

// ----------------------------

static int nuklear_Layout_Row_Push(lua_State *L)
{
    int width = luaL_checknumber(L, 1);
    nk_layout_row_push(&defoldfb->ctx, width);
    return 0;
}


// ----------------------------

static int nuklear_Layout_Row_End(lua_State *L)
{
    nk_layout_row_end(&defoldfb->ctx);
    return 0;
}

// ----------------------------

static int nuklear_Edit_String(lua_State *L)
{
    uint32_t strid = luaL_checknumber(L, 1);
    const char *str  = luaL_checkstring(L, 2);
    const int maxlen = luaL_checknumber(L, 3);
    int filter = luaL_checknumber(L, 4);

    char *value = NULL;
    int *stringlen = NULL;

    // try to get the edit buffer
    if (auto search = g_editstrings.find(strid); search != g_editstrings.end())
    {
        value = search->second.value;
        stringlen = search->second.length;
    }
    else
    {
        value = new char[maxlen];
        memset(value, 0, maxlen);
        strcpy(value, str);
        stringlen = new int[1];
        stringlen[0] = strlen(str);
        stringdata data{value, stringlen};
        g_editstrings.insert(std::pair<uint32_t, stringdata>(strid, data));
    }

    nk_edit_string(&defoldfb->ctx, NK_EDIT_SIMPLE, value, stringlen, maxlen, nk_filter_default);
    lua_pushstring(L, value);
    return 1;
}

// ----------------------------

static int nuklear_Property_Float(lua_State *L)
{
    const char *title = luaL_checkstring(L, 1);
    float minval = luaL_checknumber(L, 2);
    float value = luaL_checknumber(L, 3);
    float maxval = luaL_checknumber(L, 4);
    float step = luaL_checknumber(L, 5);
    float pixelstep = luaL_checknumber(L, 6);
    nk_property_float(&defoldfb->ctx, title, minval, &value, maxval, step, pixelstep);
    lua_pushnumber(L, value);
    return 1;
}

// ----------------------------

static int nuklear_Property_Int(lua_State *L)
{
    const char *title = luaL_checkstring(L, 1);
    int minval = luaL_checknumber(L, 2);
    int value = luaL_checknumber(L, 3);
    int maxval = luaL_checknumber(L, 4);
    int step = luaL_checknumber(L, 5);
    int pixelstep = luaL_checknumber(L, 6);
    nk_property_int(&defoldfb->ctx, title, minval, &value, maxval, step, pixelstep);
    lua_pushnumber(L, value);
    return 1;
}


// ----------------------------

static int nuklear_Slider_Int(lua_State *L)
{
    int minval = luaL_checknumber(L, 1);
    int value = luaL_checknumber(L, 2);
    int maxval = luaL_checknumber(L, 3);
    int step = luaL_checknumber(L, 4);
    nk_slider_int(&defoldfb->ctx, minval, &value, maxval, step);
    lua_pushnumber(L, value);
    return 1;
}

// ----------------------------

static int nuklear_Combo(lua_State *L)
{
    DM_LUA_STACK_CHECK(L, 1);
    luaL_checktype(L, 1, LUA_TTABLE);
    int value = luaL_checknumber(L, 2);
    int height = luaL_checknumber(L, 3);
    int sizex = luaL_checknumber(L, 4);
    int sizey = luaL_checknumber(L, 5);

    // Build string table for combo
    int string_table_len = lua_objlen(L, 1);
    const char *string_table[string_table_len];

    // Iterate indices and set float buffer with correct lookups
    lua_pushnil(L);
    size_t idx = 0;
    // Build a number array matching the buffer. They are all assumed to be type float (for the time being)
    while( lua_next( L, 1 ) != 0) {
        string_table[idx++] = lua_tostring( L, -1 );
        lua_pop( L, 1 );
    }
    
    value = nk_combo(&defoldfb->ctx, string_table, string_table_len, value, height, nk_vec2(sizex, sizey));
    lua_pushnumber(L, value);
    return 1;
}


// ----------------------------

static int nuklear_Combo_End(lua_State *L)
{
    nk_combo_end(&defoldfb->ctx);
    return 0;
}


// ----------------------------

static int nuklear_Combo_Begin_Color(lua_State *L)
{
    unsigned int rgba = luaL_checknumber(L, 1);
    int sizex = luaL_checknumber(L, 2);
    int sizey = luaL_checknumber(L, 3);
    nk_combo_begin_color(&defoldfb->ctx, nk_rgba_u32(rgba), nk_vec2(sizex,sizey));
    return 0;
}

// ----------------------------

static int nuklear_Combo_Begin_Label(lua_State *L)
{
    const char *buffer = luaL_checkstring(L, 1);
    int sizex = luaL_checknumber(L, 2);
    int sizey = luaL_checknumber(L, 3);

    nk_combo_begin_label(&defoldfb->ctx, buffer, nk_vec2(sizex,sizey));
    return 0;
}
// ----------------------------

static int nuklear_Picker_Color(lua_State *L)
{
    unsigned int rgba = luaL_checknumber(L, 1);
    nk_colorf color = nk_color_picker(&defoldfb->ctx, nk_color_cf(nk_rgba_u32(rgba)), NK_RGBA);
    lua_pushnumber(L, nk_color_u32(nk_rgba_cf(color)));
    return 1;
}

// ----------------------------

static int nuklear_Check_Label(lua_State *L)
{
    const char *text = luaL_checkstring(L, 1);
    int check = luaL_checknumber(L, 2);
    int res = nk_check_label(&defoldfb->ctx, text, check);
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Check_Flags_Label(lua_State *L)
{
    const char *text = luaL_checkstring(L, 1);
    int flags = luaL_checknumber(L, 2);
    int check = luaL_checknumber(L, 3);
    int res = nk_check_flags_label(&defoldfb->ctx, text, flags, check);
    lua_pushnumber(L, res);
    return 1;
}


// ----------------------------

static int nuklear_Slider_Float(lua_State *L)
{
    float minval = luaL_checknumber(L, 1);
    float value = luaL_checknumber(L, 2);
    float maxval = luaL_checknumber(L, 3);
    float step = luaL_checknumber(L, 4);
    nk_slider_float(&defoldfb->ctx, minval, &value, maxval, step);
    lua_pushnumber(L, value);
    return 1;
}

// ----------------------------

static int nuklear_Stroke_Line(lua_State *L)
{
    float x0 = luaL_checknumber(L, 1);
    float y0 = luaL_checknumber(L, 2);
    float x1 = luaL_checknumber(L, 3);
    float y1 = luaL_checknumber(L, 4);
    float line_thickness = luaL_checknumber(L, 5);
    unsigned int rgba = luaL_checknumber(L, 6);

    struct nk_command_buffer *canvas = nk_window_get_canvas(&defoldfb->ctx); 
    nk_stroke_line( canvas, x0, y0, x1, y1, line_thickness, nk_rgba_u32(rgba));
    return 0;
}

// ----------------------------

static int nuklear_Stroke_Rect(lua_State *L)
{
    float x0 = luaL_checknumber(L, 1);
    float y0 = luaL_checknumber(L, 2);
    float x1 = luaL_checknumber(L, 3);
    float y1 = luaL_checknumber(L, 4);
    float roundimg = luaL_checknumber(L, 5);
    float thickness = luaL_checknumber(L, 6);
    unsigned int rgba = luaL_checknumber(L, 7);

    struct nk_command_buffer *canvas = nk_window_get_canvas(&defoldfb->ctx);  
    nk_stroke_rect( canvas, nk_rect(x0, y0, x1, y1), roundimg, thickness, nk_rgba_u32(rgba));
    return 0;
}

// ----------------------------

static int nuklear_Stroke_Circle(lua_State *L)
{
    float x0 = luaL_checknumber(L, 1);
    float y0 = luaL_checknumber(L, 2);
    float x1 = luaL_checknumber(L, 3);
    float y1 = luaL_checknumber(L, 4);
    float thickness = luaL_checknumber(L, 5);
    unsigned int rgba = luaL_checknumber(L, 6);

    struct nk_command_buffer *canvas = nk_window_get_canvas(&defoldfb->ctx);  
    nk_stroke_circle( canvas, nk_rect(x0, y0, x1, y1), thickness, nk_rgba_u32(rgba));
    return 0;
}

// ----------------------------

static int nuklear_Fill_Rect(lua_State *L)
{
    float x0 = luaL_checknumber(L, 1);
    float y0 = luaL_checknumber(L, 2);
    float x1 = luaL_checknumber(L, 3);
    float y1 = luaL_checknumber(L, 4);
    float roundimg = luaL_checknumber(L, 5);
    unsigned int rgba = luaL_checknumber(L, 6);

    struct nk_command_buffer *canvas = nk_window_get_canvas(&defoldfb->ctx);    
    nk_fill_rect( canvas, nk_rect(x0, y0, x1, y1), roundimg, nk_rgba_u32(rgba));
    return 0;
}

// ----------------------------

static int nuklear_Line_Chart(lua_State *L)
{
    /* line chart */
    unsigned int bittype = (unsigned int)lua_tonumber( L, 1 ); 
    luaL_checktype(L, 2, LUA_TTABLE);
    int count = lua_objlen(L, 2);

    int index = -1;
    int line_index = -1;
    int i = 0;

    nk_context *ctx = &defoldfb->ctx;

    lua_pushnil(L);
    // First entry is always color of chart
    if( lua_next(L, 2 ) != 0 ) {
        unsigned int color = (unsigned int)lua_tonumber(L, -1);
        lua_pop(L, 1);
        ctx->style.chart.color = nk_rgba_u32(color);        
    }
    else 
    {
        lua_pushnumber(L, index);
        lua_pushnumber(L, line_index);        
        return 2;
    }

    //  Set the start and joined dots visibility
    struct nk_window *win = ctx->current;

    struct nk_rect bounds = nk_widget_bounds(ctx);
    if (nk_chart_begin(ctx, NK_CHART_LINES, count, -1.0f, 1.0f)) {
        struct nk_chart *chart = &win->layout->chart;
        chart->bittype = bittype;

        while( lua_next(L, 2 ) != 0 ) {

            nk_flags res = nk_chart_push(ctx, (float)lua_tonumber( L, -1 ));
            lua_pop( L, 1 );

            if (res & NK_CHART_HOVERING) 
                index = (int)i;
            if (res & NK_CHART_CLICKED)
                line_index = (int)i;
            i++;
        }
        nk_chart_end(ctx);
    }

    lua_pushnumber(L, index);
    lua_pushnumber(L, line_index);
    return 2;
}

// ----------------------------

static int nuklear_Draw_Text(lua_State *L)
{
    float x0 = luaL_checknumber(L, 1);
    float y0 = luaL_checknumber(L, 2);
    float w = luaL_checknumber(L, 3);
    float h = luaL_checknumber(L, 4);
    const char * str = luaL_checkstring(L, 5);
    unsigned int rgba = luaL_checknumber(L, 6);
    unsigned int rgbabg = luaL_checknumber(L, 7);

    struct nk_command_buffer *canvas = nk_window_get_canvas(&defoldfb->ctx);   
    struct nk_rect rect = nk_rect(x0, y0, w, h);
    nk_draw_text(canvas, rect, str, (int)strlen(str), defoldfb->ctx.style.font, nk_rgba_u32(rgba), nk_rgba_u32(rgbabg));
    return 0;
}

// ----------------------------

static int nuklear_Image_Color(lua_State *L)
{
    int imgid = luaL_checknumber(L, 1);
    unsigned int rgba = luaL_checknumber(L, 2);

    struct nk_image img = g_images[imgid];
    //nk_image(&defoldfb->ctx, img);
    nk_image_color(&defoldfb->ctx, img, nk_rgba_u32(rgba));
    return 0;
}

// ----------------------------

static int nuklear_Create_Image(lua_State *L)
{
    unsigned short w = luaL_checknumber(L, 1);
    unsigned short h = luaL_checknumber(L, 2);
    unsigned short bytes = luaL_checknumber(L, 3);
    unsigned char *data = (unsigned char *)luaL_checkstring(L, 4);

    if (data != nullptr) 
    {
        // By default image comes in ARGB and horizonal flipped. Needs conversion.
        unsigned char *ptr = new unsigned char[w * h * 4];
        unsigned char *pptr = ptr;
        for(int y = 0; y < h; y++)
        {
            for(int x = 0; x < w; x++)
            {
                if(bytes == 3) 
                    pptr[0] = 0xff;
                else
                    pptr[0] = data[y * w * bytes + x * bytes + 3];
                pptr[1] = data[y * w * bytes + x * bytes + 0];
                pptr[2] = data[y * w * bytes + x * bytes + 1];
                pptr[3] = data[y * w * bytes + x * bytes + 2];
                pptr += 4;
            }
        }
   
        struct nk_image img = nk_image_ptr(ptr);
        img.w = w;
        img.h = h;
        img.region[2] = w;
        img.region[3] = h;
        img.itype = 0;

        g_images.push_back(img);
        lua_pushnumber(L, g_images.size()-1);
    }
    else
    {
        printf("[Error] nuklear_Create_Image: Unabled to use buffer param.");
        lua_pushnil(L);
    }
    return 1;
}

// ----------------------------

static int nuklear_Stroke_Curve(lua_State *L)
{
    float ax = luaL_checknumber(L, 1);
    float ay = luaL_checknumber(L, 2);
    float ctrl0x = luaL_checknumber(L, 3);
    float ctrl0y = luaL_checknumber(L, 4);
    float ctrl1x = luaL_checknumber(L, 5);
    float ctrl1y = luaL_checknumber(L, 6);
    float bx = luaL_checknumber(L, 7);
    float by = luaL_checknumber(L, 8);
    float line_thickness = luaL_checknumber(L, 9);
    unsigned int rgba = luaL_checknumber(L, 10);

    struct nk_command_buffer *canvas = nk_window_get_canvas(&defoldfb->ctx);  

    nk_stroke_curve( canvas, ax, ay, ctrl0x, ctrl0y, ctrl1x, ctrl1y, bx, by, line_thickness, nk_rgba_u32(rgba));
    return 0;
}

// ----------------------------

static int nuklear_Clear(lua_State *L)
{
    nk_clear(&defoldfb->ctx);
    return 0;
}

// ----------------------------

static int nuklear_Input_Begin(lua_State *L)
{
    nk_input_begin(&defoldfb->ctx);

    if (defoldfb->ctx.input.mouse.grab) {
        defoldfb->ctx.input.mouse.grab = 0;
    } else if (defoldfb->ctx.input.mouse.ungrab) {
        defoldfb->ctx.input.mouse.ungrab = 0;
    }
    return 0;
}

// ----------------------------

static int nuklear_Input_End(lua_State *L)
{
    nk_input_end(&defoldfb->ctx);
    return 0;
}


// ----------------------------

static int nuklear_Is_Window_Minimized(lua_State *L)
{
    const char * name = luaL_checkstring(L, 1);
    int res = nk_window_is_collapsed(&defoldfb->ctx, name);    
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Is_Widget_Mouse_Clicked(lua_State *L)
{
    int buttons = luaL_checknumber(L,1);
    int res = nk_widget_is_mouse_clicked(&defoldfb->ctx, (enum nk_buttons)buttons);    
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Is_Widget_Mouse_Down(lua_State *L)
{
    int buttons = luaL_checknumber(L,1);
    int down = luaL_checknumber(L,2);
    int res = nk_widget_has_mouse_click_down(&defoldfb->ctx, (enum nk_buttons)buttons, down);
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Is_Widget_Hovered(lua_State *L)
{
    int res = nk_widget_is_hovered(&defoldfb->ctx);    
    lua_pushnumber(L, res);
    return 1;
}

// ----------------------------

static int nuklear_Is_Any_Window_Hovered(lua_State *L)
{
    int res = nk_window_is_any_hovered(&defoldfb->ctx);   
    lua_pushnumber(L, res);
    return 1;     
}

// ----------------------------

static int nuklear_Input_Motion(lua_State *L)
{
    float motionx = luaL_checknumber(L, 1);
    float motiony = luaL_checknumber(L, 2);

    nk_input_motion(&defoldfb->ctx, motionx, motiony);    
    return 0;
}

// ----------------------------

static int nuklear_Input_Get_Grabbed(lua_State *L)
{
    lua_pushnumber(L, defoldfb->ctx.input.mouse.grabbed);
    return 1;
}

// ----------------------------

static int nuklear_Input_Key(lua_State *L)
{
    int keypress = luaL_checknumber(L, 1);
    int down = luaL_checknumber(L, 2);
    nk_input_key(&defoldfb->ctx, (enum nk_keys )keypress, down);
    return 0;
}

// ----------------------------

static int nuklear_Input_Button(lua_State *L)
{
    int buttons = luaL_checknumber(L, 1);
    int x = luaL_checknumber(L, 2);
    int y = luaL_checknumber(L, 3);
    int down = luaL_checknumber(L, 4);
    nk_input_button(&defoldfb->ctx, (enum nk_buttons)buttons, x, y, down);
    return 0;
}

// ----------------------------

static int nuklear_Input_Scroll(lua_State *L)
{
    float scrollx = luaL_checknumber(L, 1);
    float scrolly = luaL_checknumber(L, 2);
    nk_input_scroll(&defoldfb->ctx, nk_vec2(scrollx, scrolly));
    return 0;
}

// ----------------------------

static int nuklear_Input_Char(lua_State *L)
{
    char textchar = luaL_checknumber(L, 1);
    nk_input_char(&defoldfb->ctx, textchar);
    return 0;
}

// ----------------------------

static int nuklear_Input_Glyph(lua_State *L)
{
    const char * utf = luaL_checkstring(L, 1);
    const nk_glyph glyph = {utf[0], utf[1], utf[2], utf[3]};
    
    nk_input_glyph(&defoldfb->ctx, glyph);
    return 0;
}

// ----------------------------

static int nuklear_Input_Unicode(lua_State *L)
{
    int ucode = luaL_checknumber(L, 1);
    nk_input_unicode(&defoldfb->ctx, (nk_rune)ucode);
    return 0;
}

// ----------------------------

static int nuklear_Render(lua_State *L)
{
    DM_LUA_STACK_CHECK(L, 0);

    float r = luaL_checknumber(L, 1);
    float g = luaL_checknumber(L, 2);
    float b = luaL_checknumber(L, 3);
    int clear = luaL_checknumber(L, 4);
    dmBuffer::HBuffer buffer = dmScript::CheckBufferUnpack(L, 5);

    memset(fb, 0, RES_WIDTH * RES_HEIGHT * 4);

    nk_defold_render( defoldfb, nk_rgb(r,g,b), clear);

    // uint8_t* bytes = 0x0;
    // uint32_t size = 0;

    // dmBuffer::Result res = dmBuffer::GetBytes(buffer, (void**)&bytes, &size);
    // if (res == dmBuffer::RESULT_OK) {
    //     for (int i = 0; i < size; ++i)
    //     {
    //         bytes[i] = defoldfb->fb.pixels[i];            
    //     }
    // } else {
    //     printf("[Error] Invalid buffer GetBytes operation.\n");
    // }    
    return 0;
}

// ----------------------------

static int nuklear_overview_demo(lua_State *L)
{
    int left = luaL_checknumber(L, 1);
    int top = luaL_checknumber(L, 2);
    do_overview(&defoldfb->ctx, left, top);
    return 0;
}

// ----------------------------

static void nuklear_ExtensionInit()
{
    dmLogInfo("nuklear_Init");
}

static int nuklear_Init(lua_State *L)
{
    int width = luaL_checknumber(L, 1);
    int height = luaL_checknumber(L, 2);
    int layout = luaL_checknumber(L, 3);
    dmBuffer::HBuffer buffer = dmScript::CheckBufferUnpack(L, 4);

    RES_WIDTH = width;
    RES_HEIGHT = height;

    // Optional
    unsigned int txtcolor = 0;
    if(lua_gettop(L) > 6) txtcolor = luaL_checknumber(L, 7);

    if(layout != 0) layout = PIXEL_LAYOUT_RGBX_8888;

    uint8_t* bytes = 0x0;
    uint32_t size = 0;

    dmBuffer::Result res = dmBuffer::GetBytes(buffer, (void**)&bytes, &size);
    if (res == dmBuffer::RESULT_OK) {
        fb = bytes;
    } else {
        printf("[Error] Invalid buffer GetBytes operation.\n");
    }    

    if(tex_scratch) delete [] tex_scratch;
    tex_scratch = new unsigned char[width * height * 4];

    if(defoldfb) nk_defold_shutdown(defoldfb);
    defoldfb = nk_defold_init(fb, tex_scratch, width, height, width * 4, (defold_pl)layout); 
    return 0;  
}

static int nuklear_Window_Resize(lua_State *L)
{
    DM_LUA_STACK_CHECK(L, 0);

    const unsigned int w = luaL_checknumber(L, 1);
    const unsigned int h = luaL_checknumber(L, 2);
    defold_pl layout = (defold_pl)luaL_checknumber(L, 3);

    if(layout != 0) layout = PIXEL_LAYOUT_RGBX_8888;

    nk_defold_resize_fb(defoldfb, fb , w, h, w * 4, layout);
    return 0;
}

static int nuklear_Set_Style(lua_State *L)
{
    int theme = luaL_checknumber(L, 1);
    int bgalpha = luaL_checknumber(L, 2);
    unsigned int txtcolor = luaL_checknumber(L, 3);
    nk_defold_set_style(&defoldfb->ctx, (enum theme)theme, bgalpha, txtcolor);
    return 0;
}

static int nuklear_Set_Style_Prop(lua_State *L)
{
    unsigned int prop = luaL_checknumber(L, 1);
    unsigned int color = luaL_checknumber(L, 2);
    nk_defold_set_style_prop(&defoldfb->ctx, prop, color);
    return 0;
}

static int nuklear_Get_Style_Prop(lua_State *L)
{
    unsigned int prop = luaL_checknumber(L, 1);
    unsigned int color = nk_defold_get_style_prop(&defoldfb->ctx, prop);
    lua_pushnumber(L, color);
    return 1;
}

static int nuklear_Style_Push_Vec2(lua_State *L)
{
    std::string prop = luaL_checkstring(L, 1);
    float vec2x = luaL_checknumber(L, 2);
    float vec2y = luaL_checknumber(L, 3);

    struct nk_vec2 * propHandle = nullptr;
    if(prop == "window.spacing") {
        propHandle = &defoldfb->ctx.style.window.spacing;
    }
    if(prop == "window.padding") {
        propHandle = &defoldfb->ctx.style.window.padding;
    }

    if(propHandle != nullptr)
        nk_style_push_vec2(&defoldfb->ctx, propHandle, nk_vec2(vec2x, vec2y));
    return 0;
}

static int nuklear_Style_Push_Float(lua_State *L)
{
    std::string prop = luaL_checkstring(L, 1);
    float val = luaL_checknumber(L, 2);

    float * propHandle = nullptr;
    if(prop == "button.rounding") {
        propHandle = &defoldfb->ctx.style.button.rounding;
    }

    if(propHandle != nullptr)
        nk_style_push_float(&defoldfb->ctx, propHandle, val);
    return 0;
}

static int nuklear_Style_Pop_Vec2(lua_State *L)
{
    nk_style_pop_vec2(&defoldfb->ctx);
    return 0;
}

static int nuklear_Style_Pop_Float(lua_State *L)
{
    nk_style_pop_float(&defoldfb->ctx);
    return 0;
}

static int nuklear_Widget_Bounds(lua_State *L)
{
    struct nk_rect bounds = nk_widget_bounds(&defoldfb->ctx);
    lua_pushnumber(L, bounds.x);
    lua_pushnumber(L, bounds.y);
    lua_pushnumber(L, bounds.w);
    lua_pushnumber(L, bounds.h);
    return 4;
}

// static int nuklear_Widget_GetState(lua_State *L)
// {
//     struct nk_rect bounds = nk_widget_bounds(&defoldfb->ctx);
//     enum nk_widget_layout_states state = nk_widget(&bounds, &defoldfb->ctx);
//     lua_pushnumber(L, (int)state);
//     return 1;
// }

// static int nuklear_Widget_SetState(lua_State *L)
// {
//     int state = luaL_checknumber(L, 1);
//     struct nk_rect bounds = nk_widget_bounds(&defoldfb->ctx);
//     enum nk_widget_layout_states temp = nk_widget(&bounds, &defoldfb->ctx);
//     defoldfb->ctx.last_widget_state = state;
//     return 0;
// }


static int nuklear_Show_Cursor(lua_State *L)
{
    int show = luaL_checknumber(L, 1);
    if(show > 0)
        nk_style_show_cursor(&defoldfb->ctx);
    else 
        nk_style_hide_cursor(&defoldfb->ctx);
    return 0;
}

static int nuklear_Begin_Fonts(lua_State *L)
{
    nk_defold_begin_fonts(defoldfb);
    return 0;
}

static int nuklear_End_Fonts(lua_State *L)
{
    nk_defold_end_fonts(defoldfb);
    return 0;
}

static int nuklear_Add_Font(lua_State *L)
{
    const char * fontdata = luaL_checkstring(L, 1);
    int datasize = luaL_checknumber(L, 2);
    float fontsize = luaL_checknumber(L, 3);
    int fontres = luaL_checknumber(L, 4);
    //printf("DATASIZE: %d FONTSIZE: %g   FONTDATA: %lu\n", datasize, fontsize, (unsigned long)fontdata);
    struct nk_font * font = nk_defold_add_font(defoldfb, fontres, fontres, (void *)fontdata, datasize, fontsize);
    
    tex_scratch = defoldfb->font_tex.pixels;
    g_fonts.push_back(font);
    lua_pushnumber(L, g_fonts.size() -1 );
    return 1;
}

static int nuklear_Set_Font(lua_State *L)
{
    int fontid = luaL_checknumber(L, 1);
    struct nk_font * font = g_fonts[fontid];
    nk_style_set_font(&defoldfb->ctx, &font->handle);
    return 0;
}

static void nuklear_ExtensionShutdown()
{
    dmLogInfo("nuklear_Shutdown");
    nk_defold_shutdown(defoldfb);
    //delete [] fb;
    delete [] tex_scratch;
}

static int nuklear_Shutdown(lua_State *L)
{
    nk_defold_shutdown(defoldfb);
    return 0;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
    {"init", nuklear_Init},
    {"shutdown", nuklear_Shutdown},
    {"window_resize", nuklear_Window_Resize},
    {"window_scissor", nuklear_Window_Scissor},
    {"show_cursor", nuklear_Show_Cursor},

    {"begin_fonts", nuklear_Begin_Fonts},
    {"end_fonts", nuklear_End_Fonts},
    {"add_font", nuklear_Add_Font},
    {"set_font", nuklear_Set_Font},

    {"set_style", nuklear_Set_Style}, 
    {"set_style_prop", nuklear_Set_Style_Prop}, 
    {"get_style_prop", nuklear_Get_Style_Prop}, 
    {"style_push_vec2", nuklear_Style_Push_Vec2},
    {"style_push_float", nuklear_Style_Push_Float},
    {"style_pop_vec2", nuklear_Style_Pop_Vec2},
    {"style_pop_float", nuklear_Style_Pop_Float},

    {"tooltip", nuklear_Tooltip },

    {"widget_bounds", nuklear_Widget_Bounds},

    {"overview_demo", nuklear_overview_demo },

    {"clear", nuklear_Clear}, 
    {"begin_window", nuklear_Begin_Window },
    {"end_window", nuklear_End_Window }, 
    {"bgcolor_window", nuklear_BGColor_Window },
    {"get_bounds_window",nuklear_Get_Bounds_Window },

    {"image_color", nuklear_Image_Color },
    {"create_image", nuklear_Create_Image },

    {"label", nuklear_Label },
    {"button_label", nuklear_Button_Label },
    {"selectable_label", nuklear_Selectable_Label },
    {"selectable_image_label", nuklear_Selectable_Image_Label },

    {"button_label_active", nuklear_Button_Label_Active },
    {"button_image", nuklear_Button_Image },
    {"option_label", nuklear_Option_Label },
    {"slider_float", nuklear_Slider_Float },
    {"slider_int", nuklear_Slider_Int },

    {"combo", nuklear_Combo },
    {"combo_end", nuklear_Combo_End },
    {"combo_begin_color", nuklear_Combo_Begin_Color },
    {"combo_begin_label", nuklear_Combo_Begin_Label },

    {"picker_color", nuklear_Picker_Color},

    {"check_label", nuklear_Check_Label},
    {"check_flags_label", nuklear_Check_Flags_Label},

    {"edit_string", nuklear_Edit_String },

    {"property_float", nuklear_Property_Float },
    {"property_int", nuklear_Property_Int },

    {"group_begin", nuklear_Group_Begin },
    {"group_end", nuklear_Group_End },

    {"push_scissor", nuklear_Push_Scissor},

    {"layout_row_static", nuklear_Layout_Row_Static },
    {"layout_row_dyn", nuklear_Layout_Row_Dynamic },

    {"layout_tree_push", nuklear_Layout_Tree_Push },
    {"layout_tree_pop", nuklear_Layout_Tree_Pop },

    {"layout_row_begin", nuklear_Layout_Row_Begin },
    {"layout_row_push", nuklear_Layout_Row_Push },
    {"layout_row_end", nuklear_Layout_Row_End },

    {"layout_space_begin", nuklear_Layout_Space_Begin },
    {"layout_space_push", nuklear_Layout_Space_Push },
    {"layout_space_end", nuklear_Layout_Space_End },

    {"stroke_line", nuklear_Stroke_Line},
    {"stroke_circle", nuklear_Stroke_Circle},
    {"stroke_rect", nuklear_Stroke_Rect},
    {"stroke_curve", nuklear_Stroke_Curve},
    {"fill_rect", nuklear_Fill_Rect },
    {"draw_text", nuklear_Draw_Text },

    {"line_chart", nuklear_Line_Chart },
    {"input_begin", nuklear_Input_Begin },
    {"input_end", nuklear_Input_End },

    {"is_window_minimized", nuklear_Is_Window_Minimized},
    {"is_widget_hovered", nuklear_Is_Widget_Hovered},
    {"is_widget_mouse_clicked", nuklear_Is_Widget_Mouse_Clicked},
    {"is_widget_mouse_down", nuklear_Is_Widget_Mouse_Down},
    {"is_any_window_hovered", nuklear_Is_Any_Window_Hovered},

    {"input_motion", nuklear_Input_Motion },
    {"input_key", nuklear_Input_Key },
    {"input_button", nuklear_Input_Button },
    {"input_scroll", nuklear_Input_Scroll },
    {"input_char", nuklear_Input_Char },
    {"input_utf", nuklear_Input_Glyph },
    {"input_unicode", nuklear_Input_Unicode },

    {"input_get_grabbed", nuklear_Input_Get_Grabbed },

    {"render", nuklear_Render },
    
    {0, 0}
};

static void LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    // Register lua names
    luaL_register(L, MODULE_NAME, Module_methods);

    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

dmExtension::Result AppInitializeNuklearExtension(dmExtension::AppParams* params)
{
    dmLogInfo("AppInitializeNuklearExtension\n");
    return dmExtension::RESULT_OK;
}

dmExtension::Result InitializeNuklearExtension(dmExtension::Params* params)
{
    // Init Lua
    nuklear_ExtensionInit();
    LuaInit(params->m_L);
    dmLogInfo("Registered %s Extension\n", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

dmExtension::Result AppFinalizeNuklearExtension(dmExtension::AppParams* params)
{
    dmLogInfo("AppFinalizeNuklearExtension\n");
    return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeNuklearExtension(dmExtension::Params* params)
{
    dmLogInfo("FinalizeNuklearExtension\n");
    nuklear_ExtensionShutdown();
    return dmExtension::RESULT_OK;
}

dmExtension::Result OnUpdateNuklearExtension(dmExtension::Params* params)
{
    // dmLogInfo("OnUpdateNuklearExtension\n");
    return dmExtension::RESULT_OK;
}

void OnEventNuklearExtension(dmExtension::Params* params, const dmExtension::Event* event)
{
    switch(event->m_Event)
    {
        case dmExtension::EVENT_ID_ACTIVATEAPP:
        dmLogInfo("OnEventNuklearExtension - EVENT_ID_ACTIVATEAPP\n");
        break;
        case dmExtension::EVENT_ID_DEACTIVATEAPP:
        dmLogInfo("OnEventNuklearExtension - EVENT_ID_DEACTIVATEAPP\n");
        break;
        case dmExtension::EVENT_ID_ICONIFYAPP:
        dmLogInfo("OnEventNuklearExtension - EVENT_ID_ICONIFYAPP\n");
        break;
        case dmExtension::EVENT_ID_DEICONIFYAPP:
        dmLogInfo("OnEventNuklearExtension - EVENT_ID_DEICONIFYAPP\n");
        break;
        default:
        dmLogWarning("OnEventNuklearExtension - Unknown event id\n");
        break;
    }
}

// Defold SDK uses a macro for setting up extension entry points:
//
// DM_DECLARE_EXTENSION(symbol, name, app_init, app_final, init, update, on_event, final)

// NuklearExtension is the C++ symbol that holds all relevant extension data.
// It must match the name field in the `ext.manifest`
DM_DECLARE_EXTENSION(Nuklear, LIB_NAME, AppInitializeNuklearExtension, AppFinalizeNuklearExtension, InitializeNuklearExtension, OnUpdateNuklearExtension, OnEventNuklearExtension, FinalizeNuklearExtension)
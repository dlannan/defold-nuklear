#define LIB_NAME "Nuklear"
#define MODULE_NAME "nuklear"

#include <dmsdk/sdk.h>
#include <dmsdk/dlib/crypt.h>

#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_INCLUDE_SOFTWARE_FONT

#include "nuklear.h"
#include "nuklear_defold.h"

static int RES_WIDTH = 1024;
static int RES_HEIGHT = 1024;

/* init gui state */
static struct nk_context ctx;
static struct defold_context *defoldfb; 
static unsigned char *fb = nullptr;
static unsigned char *tex_scratch = nullptr;

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

static int nuklear_Get_Pos_Window(lua_State *L)
{
    struct nk_vec2 pos = nk_window_get_position(&defoldfb->ctx);
    lua_pushnumber(L, pos.x);
    lua_pushnumber(L, pos.y);
    return 2;
}

// ----------------------------

static int nuklear_BGColor_Window(lua_State *L)
{
    unsigned int color = luaL_checknumber(L, 1);

    struct nk_style *style = &defoldfb->ctx.style;
    struct nk_style_window* win = &style->window;
    win->background = nk_rgba_u32(color);
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

static int nuklear_Option_Label(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    int state = luaL_checknumber(L, 2);
    int selected = nk_option_label(&defoldfb->ctx, name, state == 1);
    lua_pushnumber(L, selected);
    return 1;
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

static int nuklear_Slider_Float(lua_State *L)
{
    float minval = luaL_checknumber(L, 1);
    float value = luaL_checknumber(L, 2);
    float maxval = luaL_checknumber(L, 3);
    float step = luaL_checknumber(L, 4);
    nk_slider_float(&defoldfb->ctx, minval, &value, maxval, step);
    return 0;
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

    struct nk_window *window = defoldfb->ctx.current;
    struct nk_command_buffer *out = &window->buffer;

    nk_stroke_line( out, x0, y0, x1, y1, line_thickness, nk_rgba_u32(rgba));
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

    struct nk_window *window = defoldfb->ctx.current;
    struct nk_command_buffer *out = &window->buffer;

    nk_stroke_rect( out, nk_rect(x0, y0, x1, y1), roundimg, thickness, nk_rgba_u32(rgba));
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

    struct nk_window *window = defoldfb->ctx.current;
    struct nk_command_buffer *out = &window->buffer;

    nk_stroke_circle( out, nk_rect(x0, y0, x1, y1), thickness, nk_rgba_u32(rgba));
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

    struct nk_window *window = defoldfb->ctx.current;
    struct nk_command_buffer *out = &window->buffer;

    nk_fill_rect( out, nk_rect(x0, y0, x1, y1), roundimg, nk_rgba_u32(rgba));
    return 0;
}

// ----------------------------

static int nuklear_Draw_Text(lua_State *L)
{
    float x0 = luaL_checknumber(L, 1);
    float y0 = luaL_checknumber(L, 2);
    float x1 = luaL_checknumber(L, 3);
    float y1 = luaL_checknumber(L, 4);
    const char * str = luaL_checkstring(L, 5);
    float roundimg = luaL_checknumber(L, 5);
    unsigned int rgba = luaL_checknumber(L, 6);

    struct nk_window *window = defoldfb->ctx.current;
    struct nk_command_buffer *out = &window->buffer;


    //nk_draw_text
    return 0;
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

    struct nk_window *window = defoldfb->ctx.current;
    struct nk_command_buffer *out = &window->buffer;

    nk_stroke_curve( out, ax, ay, ctrl0x, ctrl0y, ctrl1x, ctrl1y, bx, by, line_thickness, nk_rgba_u32(rgba));
    return 0;
}

// ----------------------------

static int nuklear_Clear(lua_State *L)
{
    nk_clear(&defoldfb->ctx);
    memset(fb, 0, RES_WIDTH * RES_HEIGHT * 4);
    return 0;
}

// ----------------------------

static int nuklear_Input_Begin(lua_State *L)
{
    nk_input_begin(&defoldfb->ctx);
    return 0;
}

// ----------------------------

static int nuklear_Input_End(lua_State *L)
{
    nk_input_end(&defoldfb->ctx);
    return 0;
}

// ----------------------------


static int nuklear_Input_Motion(lua_State *L)
{
    float motionx = luaL_checknumber(L, 1);
    float motiony = luaL_checknumber(L, 2);

    if (&defoldfb->ctx.input.mouse.grabbed) {
        int x = (int)&defoldfb->ctx.input.mouse.prev.x;
        int y = (int)&defoldfb->ctx.input.mouse.prev.y;
        printf("----> ref xy motion\n");
        nk_input_motion(&defoldfb->ctx, motionx, motiony);
    }
    else 
    {
        printf("----> xy motion\n");
        nk_input_motion(&defoldfb->ctx, motionx, motiony);    
    }
    return 0;
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
    int theme = luaL_checknumber(L, 5);
    int bgalpha = luaL_checknumber(L, 6);

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

    // fb = new unsigned char[width * height * 4];
    tex_scratch = new unsigned char[width * height * 4];
    defoldfb = nk_defold_init(fb, tex_scratch, width, height, width * 4, (defold_pl)layout); 

    nk_defold_set_style(&defoldfb->ctx, (enum theme)theme, bgalpha, txtcolor);

    return 0;  
}

static int nuklear_Setup_Font(lua_State *L)
{
    const char * fontdata = luaL_checkstring(L, 1);
    int datasize = luaL_checknumber(L, 2);
    float fontsize = luaL_checknumber(L, 3);
    int fontres = luaL_checknumber(L, 4);
    //printf("DATASIZE: %d FONTSIZE: %g   FONTDATA: %lu\n", datasize, fontsize, (unsigned long)fontdata);
    nk_defold_setup_font(defoldfb, fontres, fontres, (void *)fontdata, datasize, fontsize);
    return 0;
}

static void nuklear_ExtensionShutdown()
{
    dmLogInfo("nuklear_Shutdown");
    nk_defold_shutdown(defoldfb);
    //delete [] fb;
    delete [] tex_scratch;
}


// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
    {"init", nuklear_Init},
    {"setup_font", nuklear_Setup_Font},

    {"clear", nuklear_Clear}, 
    {"begin_window", nuklear_Begin_Window },
    {"end_window", nuklear_End_Window }, 
    {"bgcolor_window", nuklear_BGColor_Window},

    {"layout_row_static", nuklear_Layout_Row_Static },
    {"layout_row_dyn", nuklear_Layout_Row_Dynamic },
    {"begin_window", nuklear_Begin_Window },

    {"label", nuklear_Label },
    {"button_label", nuklear_Button_Label },
    {"option_label", nuklear_Option_Label },
    {"slider_float", nuklear_Slider_Float },

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

    { "input_begin", nuklear_Input_Begin },
    { "input_end", nuklear_Input_End },

    { "input_motion", nuklear_Input_Motion },
    { "input_key", nuklear_Input_Key },
    { "input_button", nuklear_Input_Button },
    { "input_scroll", nuklear_Input_Scroll },
    { "input_char", nuklear_Input_Char },
    { "input_utf", nuklear_Input_Glyph },
    { "input_unicode", nuklear_Input_Unicode },

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
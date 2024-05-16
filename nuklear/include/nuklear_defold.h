/*
 * MIT License
 *
 * Copyright (c) 2016-2017 Patrick Rudolph <siro@das-labor.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.

 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
*/
/*
 * ==============================================================
 *
 *                              API
 *
 * ===============================================================
 */
#ifndef NK_DEFOLD_H_
#define NK_DEFOLD_H_

struct defold_context;

typedef enum defold_pixel_layout {
    PIXEL_LAYOUT_XRGB_8888,
    PIXEL_LAYOUT_RGBX_8888,
}
defold_pl;

struct defold_image {
    unsigned char *pixels;
    int w, h, pitch;
    defold_pl pl;
    enum nk_font_atlas_format format;
};

struct defold_context {
    struct nk_context ctx;
    struct nk_rect scissors;
    struct defold_image fb;
    struct defold_image font_tex;
    struct defold_image image;  // Temp image in the context to render
    struct nk_font_atlas atlas;
};

/* All functions are thread-safe */
NK_API struct defold_context *nk_defold_init(void *fb, void *tex_mem, const unsigned int w, const unsigned int h, const unsigned int pitch, const defold_pl pl);
NK_API void                  nk_defold_render(const struct defold_context *defold, const struct nk_color clear, const unsigned char enable_clear);
NK_API void                  nk_defold_shutdown(struct defold_context *defold);
NK_API void                  nk_defold_resize_fb(struct defold_context *defold, void *fb, const unsigned int w, const unsigned int h, const unsigned int pitch, const defold_pl pl);
NK_API struct nk_font *      nk_defold_setup_font(struct defold_context *defold, int w, int h, void *fontdata, int datasize, float fontsize);
NK_API void                  nk_defold_image(struct defold_context *defold, const struct nk_image *image);

enum theme {THEME_BLACK, THEME_WHITE, THEME_RED, THEME_BLUE, THEME_DARK};

NK_API void nk_defold_set_style(struct nk_context *ctx, enum theme theme, int bgalpha, unsigned int txtcolor);
NK_API void nk_defold_set_style_prop(struct nk_context *ctx, unsigned int prop, unsigned int color);
#endif
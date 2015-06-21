import std.stdio;

// For drawing.
import derelict.sdl2.sdl;

// We need to read entities' states to draw them.
import gamestate;

alias ScreenRect = SDL_Rect;

private SDL_Window  *window  = null;
private SDL_Surface *surface = null;

void InitGraphics()
{
    // Set up SDL.
    DerelictSDL2.load();
    SDL_Init(SDL_INIT_VIDEO);

    // Try creating a window.
    // FIXME: Remove magic numbers.
    window = SDL_CreateWindow("Dong",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        640, 480, SDL_WINDOW_OPENGL);

    // FIXME: Raise exception here. Above, do a
    // scope (failure) SDL_Quit()..
    if (window == null) {
        writefln("Error: failed to create window.");
        return;
    }

    // FIXME: scope (failure) SDL_DestroyWindow(window);

    // Create a surface and paint it black.
    surface = SDL_GetWindowSurface(window);
    SDL_FillRect(surface, null, SDL_MapRGB(surface.format, 0, 0, 0));
}

void CleanupGraphics()
{
    if (window != null) {
        SDL_DestroyWindow(window);
    }

    writefln("Exiting.");
    SDL_Quit();
}

void RenderGame()
{
    // FIXME: This will eventually be not the entire screen.
    ScreenRect sWorldRect = {
        x: cast(int) 0,
        y: cast(int) 0,
        w: cast(int) surface.w,
        h: cast(int) surface.h
    };

    ScreenRect sBallRect;

    WorldToScreenRect(sBallRect, sWorldRect, gameState.ball.wRect);

    SDL_FillRect(surface, null,       SDL_MapRGB(surface.format, 0, 0,   0));
    SDL_FillRect(surface, &sBallRect, SDL_MapRGB(surface.format, 0, 191, 0));

    // Update the window to actually display the newly drawn game state.
    SDL_UpdateWindowSurface(window);
}


/**
 * Convert a rect from world coordinates to screen coordinates.
 * The resulting rect will be stored in sRect.
 * sWorldRect is the region of the screen corresponding to the entire world.
 * wRect is the rect to be converted.
 * TODO: Magic markup in function comments so parameter names and such get
 * displayed correctly in generated HTML docs?
 */
void WorldToScreenRect(out ScreenRect sRect, ScreenRect sWorldRect,
                       WorldRect wRect)
{
    // Find the scale factors.
    double horizontalScale = sWorldRect.w / gameState.worldWidth;
    double verticalScale   = sWorldRect.h / gameState.worldHeight;

    // Convert the rect.
    sRect = ScreenRect(
        // Note: if the world started at anything other than (0, 0), we'd need
        // to subtract its top-left coordinates before rescaling x and y.
        cast(int) (horizontalScale * wRect.x + sWorldRect.x), // x
        cast(int) (verticalScale   * wRect.y + sWorldRect.y), // y
        cast(int) (horizontalScale * wRect.w),                // width
        cast(int) (verticalScale   * wRect.h)                 // height
    );
}

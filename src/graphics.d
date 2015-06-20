// For drawing.
import derelict.sdl2.sdl;

// We need to read entities' states to draw them.
import gamestate;

alias ScreenRect = SDL_Rect;

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


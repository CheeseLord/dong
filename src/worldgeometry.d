import std.stdio;

import derelict.sdl2.sdl;

import gamestate;

// TODO: Rename this module, so that ScreenRect actually belongs. It needs to
// be here for the screen/world conversion functions.
alias ScreenRect = SDL_Rect;

// I suppose we could use this in the WorldRect struct, but I don't really want
// to add more indirection there.
struct WorldPoint {
    double x;
    double y;
}

struct WorldRect {
    double x;
    double y;
    double w;
    double h;

    pure @property const double   left() { return x    ; }
    pure @property const double    top() { return y    ; }
    pure @property const double  right() { return x + w; }
    pure @property const double bottom() { return y + h; }

    @property void   left(double newL) { x = newL    ; }
    @property void    top(double newT) { y = newT    ; }
    @property void  right(double newR) { x = newR - w; }
    @property void bottom(double newB) { y = newB - h; }

    pure @property const double centerX() { return x + w / 2; }
    pure @property const double centerY() { return y + h / 2; }

    @property void centerX(double newX) { x = newX - w / 2; }
    @property void centerY(double newY) { y = newY - h / 2; }

    pure @property const WorldPoint TL() { return WorldPoint(x    , y    ); }
    pure @property const WorldPoint TR() { return WorldPoint(x + w, y    ); }
    pure @property const WorldPoint BL() { return WorldPoint(x    , y + h); }
    pure @property const WorldPoint BR() { return WorldPoint(x + w, y + h); }
}

template GetEdgeCorners(string direction) if (direction == "left")   {
    enum GetEdgeCorners : string { corner1 = "TL", corner2 = "BL" }
}
template GetEdgeCorners(string direction) if (direction == "right")  {
    enum GetEdgeCorners : string { corner1 = "TR", corner2 = "BR" }
}
template GetEdgeCorners(string direction) if (direction == "top")    {
    enum GetEdgeCorners : string { corner1 = "TL", corner2 = "TR" }
}
template GetEdgeCorners(string direction) if (direction == "bottom") {
    enum GetEdgeCorners : string { corner1 = "BL", corner2 = "BR" }
}

WorldRect CenteredWRect(double centerX, double centerY, double w, double h)
{
    return WorldRect(
        centerX - w / 2, // x
        centerY - h / 2, // y
        w,               // width
        h                // height
    );
}


/*****************************************************************************
 * World/Screen conversion
 *****************************************************************************/

/**
 * Convert a rect from world coordinates to screen coordinates.
 * The resulting rect will be stored in sRect.
 * sWorldRect is the region of the screen corresponding to the entire world.
 * wRect is the rect to be converted.
 * TODO: Magic markup in function comments so parameter names and such get
 * displayed correctly in generated HTML docs?
 */
ScreenRect WorldToScreenRect(WorldRect wRect, ScreenRect sWorldRect)
{
    // Find the scale factors.
    double horizontalScale = sWorldRect.w / gameState.worldWidth;
    double verticalScale   = sWorldRect.h / gameState.worldHeight;

    // Convert the rect.
    ScreenRect sRect = {
        // Note: if the world started at anything other than (0, 0), we'd need
        // to subtract its top-left coordinates before rescaling x and y.
        x: cast(int) (horizontalScale * wRect.x + sWorldRect.x),
        y: cast(int) (verticalScale   * wRect.y + sWorldRect.y),
        w: cast(int) (horizontalScale * wRect.w),
        h: cast(int) (verticalScale   * wRect.h)
    };

    return sRect;
}


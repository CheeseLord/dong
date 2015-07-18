import std.stdio;

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


struct WorldRect {
    double x;
    double y;
    double w;
    double h;
}

class Entity {
    private WorldRect wRect_;
    private double    xVel_;
    private double    yVel_;

    this(WorldRect startWRect, double startXVel = 0, double startYVel = 0) {
        wRect_ = startWRect;
        xVel_  = startXVel;
        yVel_  = startYVel;
    }

    this(double x, double y, double w, double h,
            double startXVel = 0.0, double startYVel = 0.0) {
        wRect_ = WorldRect(x, y, w, h);
        xVel_ = startXVel;
        yVel_ = startYVel;
    }

    // Accessors and mutators for all of our members.
    // Because encapsulation? What's that?
    pure @property ref WorldRect wRect() { return wRect_;   }
    pure @property ref double        x() { return wRect_.x; }
    pure @property ref double        y() { return wRect_.y; }
    pure @property ref double        w() { return wRect_.w; }
    pure @property ref double        h() { return wRect_.h; }
    pure @property ref double     xVel() { return xVel_;    }
    pure @property ref double     yVel() { return yVel_;    }
}

struct _GameState {
    // Screen-independent size.
    // FIXME: Remove evil magic numbers.
    double worldWidth  = 200.0;
    double worldHeight = 100.0;

    Entity ball;
}

_GameState gameState;


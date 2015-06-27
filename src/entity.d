import std.stdio;

import controller;
import physics;
import graphics;
import gamestate;

class Entity {
    private WorldRect wRect_;
    private double    xVel_;
    private double    yVel_;

    // FIXME: Add more components.
    protected PhysicsComponent physics_;

    this(WorldRect startWRect, double startXVel = 0, double startYVel = 0)
    {
        wRect_ = startWRect;
        xVel_  = startXVel;
        yVel_  = startYVel;

        initComponents();
    }

    this(double x, double y, double w, double h,
            double startXVel = 0.0, double startYVel = 0.0)
    {
        this(WorldRect(x, y, w, h), startXVel, startYVel);
    }

    void update(double elapsedTime)
    {
        // FIXME: Actually do things.
        physics.update(elapsedTime);
    }

    protected void initComponents()
    {
        // Nothing to do here; they'll be initialized lazily.
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

    protected @property PhysicsComponent physics()
    {
        // Lazily initialize a default PhysicsComponent if the subclass didn't
        // create its own.
        if (physics_ is null) {
            physics_ = new PhysicsComponent(this);
        }
        return physics_;
    }
}

class Ball : Entity {
    this(WorldRect startWRect, double startXVel = 30.0, double startYVel = 0)
    {
        super(startWRect, startXVel, startYVel);
    }

    override protected void initComponents()
    {
        physics_ = new BallPhysics(this);
    }
}


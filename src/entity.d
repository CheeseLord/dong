import std.stdio;

import controller;
import physics;
import graphics;
import gamestate;

// For entities that other entities bounce off of, describes the direction
// which those other entities are reflected toward. For all other entities,
// should be set to NO_BOUNCE.
enum BounceDirection {NO_BOUNCE, LEFT, UP, RIGHT, DOWN}

class Entity {
    private WorldRect       wRect_;
    private double          xVel_;
    private double          yVel_;
    private BounceDirection bounceDir_;

    // FIXME: Add more components.
    protected PhysicsComponent physics_;

    this(WorldRect startWRect, double startXVel = 0.0, double startYVel = 0.0,
            BounceDirection bounceDir = BounceDirection.NO_BOUNCE)
    {
        wRect_     = startWRect;
        xVel_      = startXVel;
        yVel_      = startYVel;
        bounceDir_ = bounceDir;

        initComponents();
    }

    this(double x, double y, double w, double h,
            double startXVel = 0.0, double startYVel = 0.0,
            BounceDirection bounceDir = BounceDirection.NO_BOUNCE)
    {
        this(WorldRect(x, y, w, h), startXVel, startYVel, bounceDir);
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
    pure @property ref   WorldRect           wRect() { return wRect_;     }
    pure @property ref   double                  x() { return wRect_.x;   }
    pure @property ref   double                  y() { return wRect_.y;   }
    pure @property ref   double                  w() { return wRect_.w;   }
    pure @property ref   double                  h() { return wRect_.h;   }
    pure @property ref   double               xVel() { return xVel_;      }
    pure @property ref   double               yVel() { return yVel_;      }
    pure @property const BounceDirection bounceDir() { return bounceDir_; }

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

class Wall : Entity {
    private BounceDirection direction_;

    this(WorldRect wRect, BounceDirection direction)
    {
        super(wRect, 0.0, 0.0, direction);
        direction_ = direction;
    }

    // Use default PhysicsComponent.
}


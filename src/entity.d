import std.stdio;

import control;
import physics;
import graphics;
import worldgeometry;
import score;

// TODO: This feels too tightly coupled.
// For event handling.
import derelict.sdl2.sdl;

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
    protected ControlComponent control_;
    protected PhysicsComponent physics_;

    this(WorldRect startWRect, double startXVel = 0.0, double startYVel = 0.0,
            BounceDirection bounceDir = BounceDirection.NO_BOUNCE)
    {
        wRect_     = startWRect;
        xVel_      = startXVel;
        yVel_      = startYVel;
        bounceDir_ = bounceDir;

        InitComponents();
    }

    this(double x, double y, double w, double h,
            double startXVel = 0.0, double startYVel = 0.0,
            BounceDirection bounceDir = BounceDirection.NO_BOUNCE)
    {
        this(WorldRect(x, y, w, h), startXVel, startYVel, bounceDir);
    }

    void HandleEvent(SDL_Event event)
    {
        // Only the control needs to care about the event.
        control.HandleEvent(event);
    }

    void Update(double elapsedTime)
    {
        // FIXME: Actually do things.
        physics.Update(elapsedTime);
        control.Update(elapsedTime);
    }

    protected void InitComponents()
    {
        // Nothing to do here; they'll be initialized lazily.
    }

    protected @property PhysicsComponent physics()
    {
        // Lazily initialize a default PhysicsComponent if the subclass didn't
        // create its own.
        if (physics_ is null) {
            physics_ = new PhysicsComponent(this);
        }
        return physics_;
    }

    protected @property ControlComponent control()
    {
        // Lazily initialize a default ControlComponent if the subclass didn't
        // create its own.
        if (control_ is null) {
            control_ = new ControlComponent(this);
        }
        return control_;
    }

    // Accessors and mutators for all of our members.
    // Because encapsulation? What's that?
    pure @property ref   WorldRect           wRect() { return wRect_;     }
    pure @property ref   double               xVel() { return xVel_;      }
    pure @property ref   double               yVel() { return yVel_;      }
    pure @property const BounceDirection bounceDir() { return bounceDir_; }

    // Pass-through for all the properties of Entity.
    // It'd be better to replace all of these with
    //     alias wRect this;
    // however, currently that breaks downward casts because of dlang Issue
    // 3537:
    //     https://issues.dlang.org/show_bug.cgi?id=3537
    // If that ever gets resolved, we should try the "alias this" solution.
    pure @property ref   double      x() { return wRect_.x; }
    pure @property ref   double      y() { return wRect_.y; }
    pure @property ref   double      w() { return wRect_.w; }
    pure @property ref   double      h() { return wRect_.h; }

    pure @property const double   left() { return wRect_.left  ; }
    pure @property const double    top() { return wRect_.top   ; }
    pure @property const double  right() { return wRect_.right ; }
    pure @property const double bottom() { return wRect_.bottom; }

    @property void     left(double newL) { wRect_.left   = newL; }
    @property void      top(double newT) { wRect_.top    = newT; }
    @property void    right(double newR) { wRect_.right  = newR; }
    @property void   bottom(double newB) { wRect_.bottom = newB; }

    pure @property const double centerX() { return wRect_.centerX ; }
    pure @property const double centerY() { return wRect_.centerY ; }

    @property void centerX(double newX) { wRect_.centerX = newX; }
    @property void centerY(double newY) { wRect_.centerY = newY; }

    pure @property const WorldPoint TL() { return wRect_.TL; }
    pure @property const WorldPoint TR() { return wRect_.TR; }
    pure @property const WorldPoint BL() { return wRect_.BL; }
    pure @property const WorldPoint BR() { return wRect_.BR; }
}

class Ball : Entity {
    this(WorldRect startWRect, double startXVel = 30.0, double startYVel = 0)
    {
        super(startWRect, startXVel, startYVel);
    }

    override protected void InitComponents()
    {
        BallPhysics myPhysics = new BallPhysics(this);
        physics_ = myPhysics;
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

class Paddle : Entity {
    private BounceDirection direction_;
    private double maxSpeed_;
    // TODO: It would be nice to support horizontal paddles too.
    private double minY_;
    private double maxY_;

    this(WorldRect wRect, BounceDirection direction, double maxSpeed,
         double minY, double maxY)
    {
        super(wRect, 0.0, 0.0, direction);
        direction_ = direction;
        maxSpeed_ = maxSpeed;
        minY_ = minY;
        maxY_ = maxY;
    }

    override protected void InitComponents()
    {
        physics_ = new PaddlePhysics(this);
    }

    public void SetControl(ControlComponent control)
    {
        control_ = control;
    }

    pure @property ref double maxSpeed() { return maxSpeed_; }
    pure @property ref double minY()     { return minY_;     }
    pure @property ref double maxY()     { return maxY_;     }
}


import std.stdio;
import std.math: abs;

// We need to access entities' states to move them around in the world.
import gamestate;
import entity;

class PhysicsComponent {
    private Entity parent_;

    this(Entity parent)
    {
        parent_ = parent;
    }

    void Update(double elapsedTime)
    {
        // Update position based on current velocity and elapsed time.
        parent_.x += parent_.xVel * elapsedTime;
        parent_.y += parent_.yVel * elapsedTime;
    }
}

class BallPhysics : PhysicsComponent {
    this(Ball parent)
    {
        super(parent);

        debug writefln("Constructing the Ball's PhysicsComponent.");
    }

    override void Update(double elapsedTime)
    {
        WorldRect oldWRect = parent_.wRect;
        super.Update(elapsedTime);

        WorldPoint oldTR = oldWRect.TR;
        WorldPoint oldTL = oldWRect.TL;
        WorldPoint oldBR = oldWRect.BR;
        WorldPoint oldBL = oldWRect.BL;

        WorldPoint newTR = parent_.TR;
        WorldPoint newTL = parent_.TL;
        WorldPoint newBR = parent_.BR;
        WorldPoint newBL = parent_.BL;

        bool finishedBouncing = false;

        while (!finishedBouncing) {
            foreach (Entity entity; gameState.entities) {
                if (entity.bounceDir == BounceDirection.LEFT) {
                    MaybeBounce!("right",  "left",   false, true,  "left")
                                (parent_, entity, oldWRect);
                }
                else if (entity.bounceDir == BounceDirection.RIGHT) {
                    MaybeBounce!("left",   "right",  false, false, "right")
                                (parent_, entity, oldWRect);
                }
                else if (entity.bounceDir == BounceDirection.UP) {
                    MaybeBounce!("bottom", "top",    true,  true,  "up")
                                (parent_, entity, oldWRect);
                }
                else if (entity.bounceDir == BounceDirection.DOWN) {
                    MaybeBounce!("top",    "bottom", true,  false, "down")
                                (parent_, entity, oldWRect);
                }
            }

            // TODO: Actually check this
            finishedBouncing = true;
        }
    }
}

bool MaybeBounce(string myEdgeName, string wallEdgeName, bool isVertical,
                 bool isNegative, string directionName)
                (Entity me, Entity wall, WorldRect myOldRect)
{
    enum string myEdge   = "me."   ~ myEdgeName;
    enum string wallEdge = "wall." ~ wallEdgeName;

    enum string myNewCorner1 = "me."        ~ GetEdgeCorners!myEdgeName  .corner1;
    enum string myNewCorner2 = "me."        ~ GetEdgeCorners!myEdgeName  .corner2;
    enum string myOldCorner1 = "myOldRect." ~ GetEdgeCorners!myEdgeName  .corner1;
    enum string myOldCorner2 = "myOldRect." ~ GetEdgeCorners!myEdgeName  .corner2;
    enum string wallCorner1  = "wall."      ~ GetEdgeCorners!wallEdgeName.corner1;
    enum string wallCorner2  = "wall."      ~ GetEdgeCorners!wallEdgeName.corner2;

    // TODO: Explain reversal of Intersects.
    static if (isVertical) {
        alias Intersects = SegmentIntersectsHorizontal;
    }
    else {
        alias Intersects = SegmentIntersectsVertical;
    }

    if (    Intersects(mixin(myOldCorner1), mixin(myNewCorner1), mixin(wallCorner1), mixin(wallCorner2)) ||
            Intersects(mixin(myOldCorner2), mixin(myNewCorner2), mixin(wallCorner1), mixin(wallCorner2))) {
        debug writefln("    Bouncing %s.", directionName);

        static if (isNegative) {
            mixin(myEdge) = mixin(wallEdge) - abs(mixin(myEdge)   - mixin(wallEdge));
        }
        else {
            mixin(myEdge) = mixin(wallEdge) + abs(mixin(wallEdge) - mixin(myEdge));
        }

        static if (isVertical) {
            me.yVel = - me.yVel;
        }
        else {
            me.xVel = - me.xVel;
        }

        return true;
    }
    else {
        return false;
    }
}

class PaddlePhysics : PhysicsComponent {
    this(Paddle parent)
    {
        super(parent);

        debug writefln("Constructing a Paddle's PhysicsComponent.");
    }

    override void Update(double elapsedTime)
    {
        double maxSpeed = (cast(Paddle) parent_).maxSpeed;

        // Make sure the paddle's velocity is sensible.
        if (parent_.bounceDir == BounceDirection.LEFT ||
            parent_.bounceDir == BounceDirection.RIGHT)
        {
            parent_.xVel = 0;
            if (parent_.yVel > maxSpeed)  { parent_.yVel = maxSpeed;  }
            if (parent_.yVel < -maxSpeed) { parent_.yVel = -maxSpeed; }
        }
        else if (parent_.bounceDir == BounceDirection.LEFT ||
                 parent_.bounceDir == BounceDirection.RIGHT)
        {
            parent_.yVel = 0;
            if (parent_.xVel > maxSpeed)  { parent_.xVel = maxSpeed;  }
            if (parent_.xVel < -maxSpeed) { parent_.xVel = -maxSpeed; }
        }

        super.Update(elapsedTime);

        // Stop at walls.
        double minY = (cast(Paddle) parent_).minY;
        double maxY = (cast(Paddle) parent_).maxY;

        if (parent_.bottom > maxY) { parent_.bottom = maxY; }
        if (parent_.top    < minY) { parent_.top    = minY; }
        // XXX: It would be polite to set the velocity to zero, but paddles
        // can turn instantaneously, so that's not necessary.
    }
}


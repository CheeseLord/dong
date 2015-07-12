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
            finishedBouncing = true;

            foreach (Entity entity; gameState.entities) {
                if (entity.bounceDir == BounceDirection.LEFT) {
                    if (MaybeBounce!("right",  "left",   false, true)
                                    (parent_, entity, oldWRect)) {
                        debug writefln("    Bouncing left.");
                        finishedBouncing = false;
                        break;
                    }
                }
                else if (entity.bounceDir == BounceDirection.RIGHT) {
                    if (MaybeBounce!("left",   "right",  false, false)
                                    (parent_, entity, oldWRect)) {
                        debug writefln("    Bouncing right.");
                        finishedBouncing = false;
                        break;
                    }
                }
                else if (entity.bounceDir == BounceDirection.UP) {
                    if (MaybeBounce!("bottom", "top",    true,  true)
                                    (parent_, entity, oldWRect)) {
                        debug writefln("    Bouncing up.");
                        finishedBouncing = false;
                        break;
                    }
                }
                else if (entity.bounceDir == BounceDirection.DOWN) {
                    if (MaybeBounce!("top",    "bottom", true,  false)
                                    (parent_, entity, oldWRect)) {
                        debug writefln("    Bouncing down.");
                        finishedBouncing = false;
                        break;
                    }
                }
            }
        }
    }
}

/**
 * Templated function that checks whether one Entity ("me") collides with
 * another ("wall"), and if so reflects me off of wall in a particular
 * direction.
 * Template parameters:
 *     myEdge -- The edge of me that will hit the wall first. For example, if
 *         we're checking for collisions with the top wall, myEdge should be
 *         "top".
 *     wallEdge -- The edge of wall that me will hit first. For example, if
 *         we're checking for collisions with the top wall, myEdge should be
 *         "bottom".
 *     isVertical -- true if this is a vertical collision (that is, if we will
 *         be reflected upward or downward); false otherwise (that is, if we
 *         will be reflected leftward or rightward).
 *     isNegative -- true if the relevant component of me's velocity, after
 *         it bounces (assuming that it does bounce), will be negative (that
 *         is, if this is an upward or leftward bounce); false otherwise.
 * Function parameters:
 *     me -- The entity that may be bouncing. me.wRect should be the position
 *         that me will have assuming it does *not* bounce off of the wall.
 *     wall -- The entity that me may bounce off of.
 *     myOldRect -- The position of me at the start of this frame.
 * Returns true if me bounces off wall, false otherwise.
 */
bool MaybeBounce(string myEdge, string wallEdge, bool isVertical,
                 bool isNegative)
                (Entity me, Entity wall, WorldRect myOldRect)
{
    // TODO: I couldn't figure out a way to create compile-time aliases to
    // these (short of taking their addresses and storing them in pointers), so
    // for now we're just calling mixin on them every time we need to use them.
    // This isn't really the best thing.
    enum string myEdgeCoord   = "me."   ~ myEdge;
    enum string wallEdgeCoord = "wall." ~ wallEdge;

    enum string myNewCorner1 = "me."        ~ GetEdgeCorners!myEdge  .corner1;
    enum string myNewCorner2 = "me."        ~ GetEdgeCorners!myEdge  .corner2;
    enum string myOldCorner1 = "myOldRect." ~ GetEdgeCorners!myEdge  .corner1;
    enum string myOldCorner2 = "myOldRect." ~ GetEdgeCorners!myEdge  .corner2;
    enum string wallCorner1  = "wall."      ~ GetEdgeCorners!wallEdge.corner1;
    enum string wallCorner2  = "wall."      ~ GetEdgeCorners!wallEdge.corner2;

    // Determine the two things that depend on whether this is a vertical
    // bounce or a horizontal bounce:
    //  1. Component of our velocity that should be inverted: x if horizontal,
    //     y if vertical.
    //  2. The function used to check whether a line segment (from old position
    //     to new position) intersects the wall. Note that the edge of the wall
    //     that we bounce off of is perpendicular to the direction of the
    //     bounce: for example, if we're bouncing horizontally, then we must
    //     therefore be bouncing off of a *vertical* edge of a wall.
    static if (isVertical) {
        enum string myVel = "me.yVel";
        alias Intersects = SegmentIntersectsHorizontal;
    }
    else {
        enum string myVel = "me.xVel";
        alias Intersects = SegmentIntersectsVertical;
    }

    // Check whether our displacement vector passes through the wall.
    if (    Intersects(mixin(myOldCorner1), mixin(myNewCorner1),
                       mixin(wallCorner1),  mixin(wallCorner2)) ||
            Intersects(mixin(myOldCorner2), mixin(myNewCorner2),
                       mixin(wallCorner1), mixin(wallCorner2))) {

        // Use abs() to make sure we bounce in the right direction. If
        // isNegative, then our final edge coordinate should be less than the
        // wall's edge coordinate (we should be left of or above the wall);
        // otherwise, our final edge coordinate should be greater than that
        // of the wall (we should be to the right of or below the wall).
        static if (isNegative) {
            mixin(myEdgeCoord) = mixin(wallEdgeCoord) -
                abs(mixin(myEdgeCoord)   - mixin(wallEdgeCoord));
        }
        else {
            mixin(myEdgeCoord) = mixin(wallEdgeCoord) +
                abs(mixin(wallEdgeCoord) - mixin(myEdgeCoord)  );
        }

        // FIXME: Also need to update myOldRect (which we currently can't do
        // because it's passed by value) to our position just after the bounce,
        // so that we can detect any further collisions (in case there are many
        // collisions in a single frame).

        // Actually start moving in the other direction.
        mixin(myVel) = - mixin(myVel);

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


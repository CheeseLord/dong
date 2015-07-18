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

        bool finishedBouncing = false;

        // NOTE: I'm not totally certain this won't be an infinite loop. I
        // can't think of a way that could happen since all of our walls are
        // axis-aligned (either perfectly vertical or perfectly horizontal),
        // but I also can't prove that it won't happen.
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
                (Entity me, Entity wall, ref WorldRect myOldRect)
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

    double deltaX = 0.0;
    double deltaY = 0.0;

    // Check whether our displacement vector passes through the wall, setting
    // deltaX and deltaY if so.
    if     (Intersects(mixin(myOldCorner1), mixin(myNewCorner1),
                       mixin(wallCorner1),  mixin(wallCorner2),
                       deltaX, deltaY) ||
            Intersects(mixin(myOldCorner2), mixin(myNewCorner2),
                       mixin(wallCorner1),  mixin(wallCorner2),
                       deltaX, deltaY)) {

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

        // Also update myOldRect to be at the point of intersection, allowing
        // us to detect additional bounces that happened during this same
        // frame.
        myOldRect.x += deltaX;
        myOldRect.y += deltaY;

        // Actually start moving in the other direction.
        mixin(myVel) = - mixin(myVel);

        return true;
    }
    else {
        return false;
    }
}

/**
 * Check whether two line segments intersect. One segment goes from s1Start to
 * s1End; the other goes from s2Start to s2End. The second one must be
 * perfectly vertical. If they do intersect, set deltaX and deltaY to the
 * offset (x, y) from s1Start to the point of intersection. If they don't
 * intersect, leave deltaX and deltaY unchanged.
 */
private bool SegmentIntersectsVertical(WorldPoint s1Start, WorldPoint s1End,
                                       WorldPoint s2Start, WorldPoint s2End,
                                       ref double deltaX,  ref double deltaY)
{
    // s2Start.x and s2End.x are assumed equal.
    double s2x = s2Start.x;

    if     ((s1Start.x < s2x && s1End.x > s2x) ||
            (s1Start.x > s2x && s1End.x < s2x)) {
        // Segment 1 starts and ends on opposite sides (horizontally speaking)
        // of segment 2, so an intersection is possible.

        // Compute the y-coordinate of segment 1 at s2x. If the two segments
        // intersect, it must be at this y-coordinate, so we call it
        // intersectY. To find this coordinate, we make use of the fact that:
        //      intersectY - s1Start.y       s1End.y - s1Start.y
        //     ------------------------  =  ---------------------
        //             s2x - s1Start.x       s1End.x - s1Start.x
        double intersectY = (s1End.y - s1Start.y) / (s1End.x - s1Start.x) *
                            (s2x - s1Start.x) +
                            s1Start.y;

        if     ((s2Start.y < intersectY && intersectY < s2End.y) ||
                (s2Start.y > intersectY && intersectY > s2End.y)) {
            // The segments intersect.
            deltaX = s2x        - s1Start.x;
            deltaY = intersectY - s1Start.y;
            return true;
        }
    }

    return false;
}

/**
 * Check whether two line segments intersect. One segment goes from s1Start to
 * s1End; the other goes from s2Start to s2End. The second one must be
 * perfectly horizontal. If they do intersect, set deltaX and deltaY to the
 * offset (x, y) from s1Start to the point of intersection. If they don't
 * intersect, leave deltaX and deltaY unchanged.
 */
private bool SegmentIntersectsHorizontal(WorldPoint s1Start, WorldPoint s1End,
                                         WorldPoint s2Start, WorldPoint s2End,
                                         ref double deltaX,  ref double deltaY)
{
    // s2Start.y and s2End.y are assumed equal.
    double s2y = s2Start.y;

    if     ((s1Start.y < s2y && s1End.y > s2y) ||
            (s1Start.y > s2y && s1End.y < s2y)) {
        // Segment 1 starts and ends on opposite sides (vertically speaking)
        // of segment 2, so an intersection is possible.

        // Compute the x-coordinate of segment 1 at s2y. If the two segments
        // intersect, it must be at this x-coordinate, so we call it
        // intersectX. To find this coordinate, we make use of the fact that:
        //      intersectX - s1Start.x       s1End.x - s1Start.x
        //     ------------------------  =  ---------------------
        //             s2y - s1Start.y       s1End.y - s1Start.y
        double intersectX = (s1End.x - s1Start.x) / (s1End.y - s1Start.y) *
                            (s2y - s1Start.y) +
                            s1Start.x;

        if     ((s2Start.x < intersectX && intersectX < s2End.x) ||
                (s2Start.x > intersectX && intersectX > s2End.x)) {
            // The segments intersect.
            deltaX = intersectX - s1Start.x;
            deltaY = s2y        - s1Start.y;
            return true;
        }
    }

    return false;
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


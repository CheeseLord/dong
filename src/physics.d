import std.stdio;
import std.math:      abs;
import std.algorithm: max, min;

// We need to access entities' states to move them around in the world.
import gamestate;
import entity;
import worldgeometry;
import observer;

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
    mixin Subject;

    this(Ball parent)
    {
        super(parent);

        debug writefln("Constructing the Ball's PhysicsComponent.");
    }

    override void Update(double elapsedTime)
    {
        bool finishedBouncing = false;
        Entity prevObstacle   = null;

        // NOTE: I'm not totally certain this won't be an infinite loop. I
        // can't think of a way that could happen since all of our walls are
        // axis-aligned (either perfectly vertical or perfectly horizontal),
        // but I also can't prove that it won't happen.
        while (!finishedBouncing) {
            // TODO: Repeated calls to super.Update could be a problem.
            WorldRect oldWRect = parent_.wRect;
            super.Update(elapsedTime);

            Entity obstacle           = null;
            double firstCollisionTime = elapsedTime;
            double currCollisionTime;

            foreach (Entity entity; gameState.entities) {
                // Special case: we can't bounce off of ourself.
                if (entity is parent_)
                    continue;

                // We also can't bounce off of the same obstacle twice
                // consecutively; this is to prevent us from getting caught in
                // an infinite loop when the ball bounces off of an obstacle
                // and then is temporarily on top of that obstacle.
                if (entity is prevObstacle)
                    continue;

                if (EntityCollides(oldWRect, parent_.wRect, entity.wRect,
                                   elapsedTime, currCollisionTime)) {
                    if (currCollisionTime < firstCollisionTime) {
                        obstacle           = entity;
                        firstCollisionTime = currCollisionTime;
                    }
                }
            }

            // Ensure the first collision time is strictly positive. This
            // shouldn't be an issue, but it seems a good idea to add it
            // anyway, just to make absolute sure we can't get stuck.
            // FIXME: Evil magic numbers.
            firstCollisionTime = max(firstCollisionTime, 1.0e-3);

            if (obstacle !is null) {
                // Simulate forward to the point of the collision, and set
                // elapsedTime to the remaining elapsed time.
                // TODO: Repeated calls to super.Update could be a problem.
                parent_.wRect = oldWRect;
                super.Update(firstCollisionTime);
                elapsedTime -= firstCollisionTime;

                // Primitive bounce: just invert the relevant component of our
                // velocity.
                switch (obstacle.bounceDir) {
                    case BounceDirection.LEFT:
                        parent_.xVel = - abs(parent_.xVel);
                        break;
                    case BounceDirection.RIGHT:
                        parent_.xVel = + abs(parent_.xVel);
                        break;
                    case BounceDirection.UP:
                        parent_.yVel = - abs(parent_.yVel);
                        break;
                    case BounceDirection.DOWN:
                        parent_.yVel = + abs(parent_.yVel);
                        break;
                    default:
                        // NO_BOUNCE; do nothing.
                        break;
                }

                prevObstacle = obstacle;
            }
            else {
                finishedBouncing = true;
            }
        }

        // Send a notification if the ball has passed completely outside of the
        // playing field.
        if      (parent_.right < 0)
            Notify(NotifyType.BALL_PASS_LEFT);
        else if (parent_.left  > gameState.worldWidth)
            Notify(NotifyType.BALL_PASS_RIGHT);
    }
}

/**
 * Check if an entity collides with an obstacle. If so, then also set
 * collisionTime to the amount of time elapsed when the entity first touches
 * the obstacle. The obstacle is located at 'obstacle', and assumed not to
 * move. The entity moves from 'start' to 'end', over a duration 'elapsedTime'.
 * The entity's start and end must have the same width and height, and at least
 * one of its x and y must change.
 */
private bool EntityCollides(WorldRect start, WorldRect end, WorldRect obstacle,
                            double elapsedTime, out double collisionTime)
{
    // The entity is assumed not to change size; that would complicate the
    // collision-detection code considerably.
    assert(abs(end.w - start.w) <  1.0e-6);
    assert(abs(end.h - start.h) <  1.0e-6);

    // The entity must move.
    assert(abs(end.y - start.y) >= 1.0e-6 ||
           abs(end.x - start.x) >= 1.0e-6);

    // Expand obstacle left by the width of entity and up by the height of
    // entity. This allows us to check for collisions between the top-left
    // corner of entity and the expanded obstacle. Collision detection between
    // a moving point and a rect is easier than between a moving rect and a
    // rect.
    WorldRect expandedObstacle = {
        x: obstacle.x - start.w,
        y: obstacle.y - start.h,
        w: obstacle.w + start.w,
        h: obstacle.h + start.h,
    };

    WorldPoint intersection;
    if (TrajectoryIntersects(start.TL, end.TL, expandedObstacle,
                             intersection)) {
        // What fraction of the elapsedTime elapsed before the collision?
        double collisionFraction;

        // Use whichever axis we moved farther along to convert the
        // intersection point to a fraction of time elapsed. These divisions
        // are safe because the entity is required to move.
        if (end.y - start.y > end.x - start.x)
            collisionFraction = (intersection.y - start.y) / (end.y - start.y);
        else
            collisionFraction = (intersection.x - start.x) / (end.x - start.x);

        collisionTime = elapsedTime * collisionFraction;
        return true;
    }
    else {
        return false;
    }
}

/**
 * FIXME: Comment.
 */
private bool TrajectoryIntersects(WorldPoint start, WorldPoint end,
                                  WorldRect obstacle,
                                  out WorldPoint firstIntersection)
{
    // Is the start point outside of the obstacle?
    bool isStartOutside = false;

    // Check if the starting point is horizontally outside.
    if (start.x < obstacle.left) {
        isStartOutside = true;
        if (SegmentIntersectsVertical(start, end, obstacle.TL, obstacle.BL,
                                      firstIntersection)) {
            return true;
        }
    }
    else if (start.x > obstacle.right) {
        isStartOutside = true;
        if (SegmentIntersectsVertical(start, end, obstacle.TR, obstacle.BR,
                                      firstIntersection)) {
            return true;
        }
    }

    // Check if the starting point is vertically outside.
    if (start.y < obstacle.top) {
        isStartOutside = true;
        if (SegmentIntersectsHorizontal(start, end, obstacle.TL, obstacle.TR,
                                        firstIntersection)) {
            return true;
        }
    }
    else if (start.y > obstacle.bottom) {
        isStartOutside = true;
        if (SegmentIntersectsHorizontal(start, end, obstacle.BL, obstacle.BR,
                                        firstIntersection)) {
            return true;
        }
    }

    if (!isStartOutside) {
        // This actually probably shouldn't happen. We'll handle it to be
        // robust, but print a debug message so we can look into why it
        // happened.
        debug writefln("    Note: ball started frame inside paddle.");

        firstIntersection = start;
        return true;
    }

    return false;
}

/**
 * FIXME: Fix comment
 * Check whether two line segments intersect. One segment goes from s1Start to
 * s1End; the other goes from s2Start to s2End. The second one must be
 * perfectly vertical. If they do intersect, set deltaX and deltaY to the
 * offset (x, y) from s1Start to the point of intersection. If they don't
 * intersect, leave deltaX and deltaY unchanged.
 */
private bool SegmentIntersectsVertical(WorldPoint s1Start, WorldPoint s1End,
                                       WorldPoint s2Start, WorldPoint s2End,
                                       out WorldPoint intersection)
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
            intersection = WorldPoint(s2x, intersectY);
            return true;
        }
    }

    return false;
}

/**
 * FIXME: Fix comment
 * Check whether two line segments intersect. One segment goes from s1Start to
 * s1End; the other goes from s2Start to s2End. The second one must be
 * perfectly horizontal. If they do intersect, set deltaX and deltaY to the
 * offset (x, y) from s1Start to the point of intersection. If they don't
 * intersect, leave deltaX and deltaY unchanged.
 */
private bool SegmentIntersectsHorizontal(WorldPoint s1Start, WorldPoint s1End,
                                         WorldPoint s2Start, WorldPoint s2End,
                                         out WorldPoint intersection)
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
            intersection = WorldPoint(intersectX, s2y);
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


import std.stdio;
import std.math;
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
            // FIXME: Magic number.
            firstCollisionTime = max(firstCollisionTime, 1.0e-3);

            if (obstacle !is null) {
                // Simulate forward to the point of the collision, and set
                // elapsedTime to the remaining elapsed time.
                // TODO: Repeated calls to super.Update could be a problem.
                parent_.wRect = oldWRect;
                super.Update(firstCollisionTime);
                elapsedTime -= firstCollisionTime;

                // FIXME: Dymanic casts bad.
                if (cast(Paddle)(obstacle)) {
                    BouncePaddle(parent_, obstacle.wRect, obstacle.bounceDir);
                }
                else if (cast(Wall)(obstacle)) {
                    BounceWall(parent_, obstacle.bounceDir);
                }
                else {
                    // We don't know how to bounce, so don't.
                }

                prevObstacle = obstacle;
            }
            else {
                finishedBouncing = true;
            }
        }

        // Check if the ball has moved outside the play field.
        if      (parent_.right < 0)
            observers.Notify(NotifyType.BALL_PASS_LEFT);
        else if (parent_.left > gameState.worldWidth)
            observers.Notify(NotifyType.BALL_PASS_RIGHT);
    }
}

void BounceWall(Entity entity, BounceDirection bounceDir)
{
    // Primitive bounce: just invert the relevant component of our velocity.
    //
    // Note that the notification types are inverted relative to the bounce
    // direction because the ball bounces inward, so (for example) if it
    // bounces to the right, then it's bouncing at the left edge of the field.
    switch (bounceDir) {
        case BounceDirection.LEFT:
            observers.Notify(NotifyType.BALL_BOUNCE_RIGHT_PADDLE);
            entity.xVel = - abs(entity.xVel);
            break;
        case BounceDirection.RIGHT:
            observers.Notify(NotifyType.BALL_BOUNCE_LEFT_PADDLE);
            entity.xVel = + abs(entity.xVel);
            break;
        case BounceDirection.UP:
            observers.Notify(NotifyType.BALL_BOUNCE_BOTTOM_WALL);
            entity.yVel = - abs(entity.yVel);
            break;
        case BounceDirection.DOWN:
            observers.Notify(NotifyType.BALL_BOUNCE_TOP_WALL);
            entity.yVel = + abs(entity.yVel);
            break;
        default:
            // NO_BOUNCE; do nothing.
            break;
    }
}

// TODO: Comment better
void BouncePaddle(Entity entity, WorldRect obstacle, BounceDirection bounceDir)
{
    // Expand obstacle as in EntityCollides.
    // FIXME: Factor out common calculation.
    WorldRect expandedObstacle = {
        x: obstacle.x - entity.w,
        y: obstacle.y - entity.h,
        w: obstacle.w + entity.w,
        h: obstacle.h + entity.h,
    };

    // Construct a quarter-circle whose center has the same y as the center of
    // the (expanded) obstacle.
    double circleY  = expandedObstacle.centerY;
    double circleR2 = 0.5 * (expandedObstacle.h ^^ 2); // radius squared

    // Find the point on that circle with the same y coordinate as entity.
    // We'll treat this as the point of collision for purposes of reflection
    // calculations.
    // TODO: We don't actually need intersectX; we can use y and r to find the
    // angle instead. But the calculation may be clearer this way.
    double intersectY = entity.y - circleY;
    double intersectX = sqrt(circleR2 - intersectY^^2);

    // The bounce direction determines whether we use the left quarter or the
    // right quarter.
    switch(bounceDir) {
        case BounceDirection.RIGHT: /* intersectX is correct. */ break;
        case BounceDirection.LEFT:  intersectX = -intersectX;    break;
        default: assert(false); // Vertical play not supported yet.
    }

    // Angle of entity's initial velocity.
    double initialAngle   = atan2(entity.yVel, entity.xVel);

    // Angle of vector from center of circle to point of collision.
    double radialAngle    = atan2(intersectY, intersectX);

    // Angle of velocity reflected across the line formed by the radial vector.
    double reflectedAngle = 2*radialAngle - initialAngle - PI;

    // Use a weighted average of the reflected and radial angles, to ensure the
    // entity actually bounces in the right direction and doesn't just skim the
    // surface of the obstacle but keep going in essentially the same
    // direction.
    // FIXME: Magic numbers.
    double finalAngle = WeightedAverageOfAngles(radialAngle, reflectedAngle,
                                                0.39);

    // For now, increase the magnitude of the velocity by a constant.
    // TODO: Make it faster when going more vertically.
    double finalSpeed = hypot(entity.xVel, entity.yVel) + 3.0;

    // TODO: Randomize the final angle and possibly speed a little.

    // TODO: Check that the horizontal component of entity's velocity is in the
    // right direction; impose some sort of minimum.

    entity.xVel = finalSpeed * cos(finalAngle);
    entity.yVel = finalSpeed * sin(finalAngle);
}

/**
 * Find a weighted average of two angles. The weight is the weight on angle2,
 * so a weight of 0 means to return angle1 and a weight of 1 means to return
 * angle2. Weighting is done by taking a weighted sum of unit vectors in the
 * two directions. If weight is 0.5 and the two angles point in exactly
 * opposite directions, you're gonna have a bad time.
 */
double WeightedAverageOfAngles(double angle1, double angle2, double weight2)
{
    return atan2(
            (1 - weight2) * sin(angle1) + weight2 * sin(angle2),
            (1 - weight2) * cos(angle1) + weight2 * cos(angle2)
        );
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
        // intersection point to a fraction of time elapsed. We are safe from
        // division by zero here because the entity is required to move.
        if (abs(end.y - start.y) > abs(end.x - start.x))
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
 * Check if a moving point collides with an obstacle. The point moves from
 * 'start' to 'end'; the obstacle is located at 'obstacle'. If it does collide,
 * set firstIntersection to the first coordinates along the point's trajectory
 * at which it intersects the obstacle.
 */
private bool TrajectoryIntersects(WorldPoint start, WorldPoint end,
                                  WorldRect obstacle,
                                  out WorldPoint firstIntersection)
{
    // High-level explanation:
    //
    // The start point will fall within one of 9 regions, defined by the
    // obstacle rect:
    //
    //           .       .
    //       TL  .   T   .  TR
    //           .       .
    //     . . . +-------+ . . .
    //           |       |
    //        L  |   C   |   R
    //           |       |
    //     . . . +-------+ . . .
    //           .       .
    //       BL  .   B   .  BR
    //           .       .
    //
    // If it's in C, then our job is easy: the answer is "yes, the point
    // collides with the obstacle, and its first intersection is start."
    //
    // If it's not in C, then the only way the point can collide with the
    // obstacle is if its trajectory intersects one of the four edges of the
    // rect (that is, it must enter the rect at some point). If it interects
    // exactly one of them (that is, it ends inside the rect), then our job is
    // also easy; we just need to return that point of intersection. But it's
    // also possible that the point will go all the way through the rect in one
    // frame. This is where the regions are helpful.
    //
    // If the point starts in L, T, R, or B, then there is only one edge it can
    // possibly enter through: respectively the left, top, right, or bottom.
    // If it starts in TL, TR, BL, or BR, then there are two edges it can enter
    // through (for TL the top and left, for TR the top and right, and so on),
    // and it can't exit through either of those two. This means that all we
    // need to do is check for intersections with the possible entry edges,
    // determined based on the point's starting region.
    //
    // The logic for that can be reexpressed as follows:
    //     If we're in TL, L, or BL, check for intersection with left   edge.
    //     If we're in TL, T, or TR, check for intersection with top    edge.
    //     If we're in TR, R, or BR, check for intersection with right  edge.
    //     If we're in BL, B, or BR, check for intersection with bottom edge.

    // Is the start point outside of the obstacle?
    bool isStartOutside = false;

    // If we're in TL, L, or BL, check for intersection with left   edge.
    if (start.x < obstacle.left) {
        isStartOutside = true;
        if (SegmentIntersectsVertical(start, end, obstacle.TL, obstacle.BL,
                                      firstIntersection)) {
            return true;
        }
    }
    // If we're in TR, R, or BR, check for intersection with right  edge.
    else if (start.x > obstacle.right) {
        isStartOutside = true;
        if (SegmentIntersectsVertical(start, end, obstacle.TR, obstacle.BR,
                                      firstIntersection)) {
            return true;
        }
    }

    // If we're in TL, T, or TR, check for intersection with top    edge.
    if (start.y < obstacle.top) {
        isStartOutside = true;
        if (SegmentIntersectsHorizontal(start, end, obstacle.TL, obstacle.TR,
                                        firstIntersection)) {
            return true;
        }
    }
    // If we're in BL, B, or BR, check for intersection with bottom edge.
    else if (start.y > obstacle.bottom) {
        isStartOutside = true;
        if (SegmentIntersectsHorizontal(start, end, obstacle.BL, obstacle.BR,
                                        firstIntersection)) {
            return true;
        }
    }

    // If none of the four checks above triggered, then the only region we can
    // be in is C. In this case, the answer is easy.
    if (!isStartOutside) {
        // This actually probably shouldn't happen. We'll handle it to be
        // robust, but print a debug message so we can look into why it
        // happened.
        debug writefln("Note: ball started frame inside paddle.");

        firstIntersection = start;
        return true;
    }

    // If none of the above checks found an intersection, then there isn't one.
    return false;
}

/**
 * Check whether two line segments intersect. One segment goes from s1Start to
 * s1End; the other goes from s2Start to s2End. The second one must be
 * perfectly vertical. If they do intersect, store the point of intersection in
 * intersection.
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
 * Check whether two line segments intersect. One segment goes from s1Start to
 * s1End; the other goes from s2Start to s2End. The second one must be
 * perfectly horizontal. If they do intersect, store the point of intersection
 * in intersection.
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


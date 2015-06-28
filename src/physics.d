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

    void update(double elapsedTime)
    {
        // Update position based on current velocity and elapsed time.
        parent_.x += parent_.xVel * elapsedTime;
        parent_.y += parent_.yVel * elapsedTime;
    }
}

class BallPhysics : PhysicsComponent {
    this(Entity parent)
    {
        super(parent);

        debug writefln("Constructing the Ball's PhysicsComponent.");
    }

    override void update(double elapsedTime)
    {
        double oldX = parent_.x;
        double oldY = parent_.y;
        super.update(elapsedTime);

        bool finishedBouncing = false;

        while (!finishedBouncing) {
            foreach (Entity entity; gameState.entities) {
                if (entity.bounceDir == BounceDirection.LEFT) {
                    debug writefln("Checking for bounce.");
                    if (SegmentIntersectsVerticalSegment(
                                WorldPoint(oldX,      oldY),
                                WorldPoint(parent_.x, parent_.y),
                                WorldPoint(entity.x,  entity.y),
                                WorldPoint(entity.x + entity.w,
                                           entity.y + entity.h)
                            )) {
                        debug writefln("    Bouncing.");
                        // parent_.right = entity.left -
                        //                 abs(parent_.right - entity.left)
                        parent_.x = entity.x -
                                    abs((parent_.x + parent_.w) - entity.x) -
                                    parent_.w;
                        parent_.xVel = - parent_.xVel;
                    }
                }

                // TODO: More directions
            }

            // TODO: Actually check this
            finishedBouncing = true;
        }
    }
}


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
        WorldRect oldWRect = parent_.wRect;
        super.update(elapsedTime);

        WorldPoint oldTR = oldWRect.TR;
        WorldPoint oldBR = oldWRect.BR;

        WorldPoint newTR = parent_.TR;
        WorldPoint newBR = parent_.BR;

        bool finishedBouncing = false;

        while (!finishedBouncing) {
            foreach (Entity entity; gameState.entities) {
                if (entity.bounceDir == BounceDirection.LEFT) {
                    WorldPoint entityTL = entity.TL;
                    WorldPoint entityBL = entity.BL;
                    if     (SegmentIntersectsVertical(oldTR, newTR,
                                                      entityTL, entityBL) ||
                            SegmentIntersectsVertical(oldBR, newBR,
                                                      entityTL, entityBL)) {
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


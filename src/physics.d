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
                    WorldPoint entityTL = entity.TL;
                    WorldPoint entityBL = entity.BL;
                    if     (SegmentIntersectsVertical(oldTR, newTR,
                                                      entityTL, entityBL) ||
                            SegmentIntersectsVertical(oldBR, newBR,
                                                      entityTL, entityBL)) {
                        debug writefln("    Bouncing left.");
                        // parent_.right = entity.left -
                        //                 abs(parent_.right - entity.left)
                        parent_.x = entity.x -
                                    abs((parent_.x + parent_.w) - entity.x) -
                                    parent_.w;
                        parent_.xVel = - parent_.xVel;
                    }
                }

                else if (entity.bounceDir == BounceDirection.RIGHT) {
                    WorldPoint entityTR = entity.TR;
                    WorldPoint entityBR = entity.BR;
                    if     (SegmentIntersectsVertical(oldTL, newTL,
                                                      entityTR, entityBR) ||
                            SegmentIntersectsVertical(oldBL, newBL,
                                                      entityTR, entityBR)) {
                        debug writefln("    Bouncing right.");
                        // parent_.left = entity.right +
                        //                 abs(entity.right - parent_.left)
                        parent_.x = entity.x + entity.w +
                                    abs((entity.x + entity.w) - parent_.x);
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


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

        // TODO: Make properties for TL, TR, BL, and BR of wRects. Or at least
        // write functions to compute them?
        WorldPoint oldTR = {x: oldWRect.x + oldWRect.w,
                            y: oldWRect.y};
        WorldPoint oldBR = {x: oldWRect.x + oldWRect.w,
                            y: oldWRect.y + oldWRect.h};

        WorldPoint newTR = {x: parent_.x + parent_.w,
                            y: parent_.y};
        WorldPoint newBR = {x: parent_.x + parent_.w,
                            y: parent_.y + parent_.h};

        bool finishedBouncing = false;

        while (!finishedBouncing) {
            foreach (Entity entity; gameState.entities) {
                if (entity.bounceDir == BounceDirection.LEFT) {
                    WorldPoint entityTL = {x: entity.x,
                                           y: entity.y};
                    WorldPoint entityBL = {x: entity.x,
                                           y: entity.y + entity.h};
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


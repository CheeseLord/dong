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
    this(Ball parent)
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
                        parent_.right = entity.left -
                                        abs(parent_.right - entity.left);
                        // parent_.x = entity.x -
                        //             abs((parent_.x + parent_.w) - entity.x) -
                        //             parent_.w;
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
                        parent_.left = entity.right +
                                        abs(entity.right - parent_.left);
                        // parent_.x = entity.x + entity.w +
                        //             abs((entity.x + entity.w) - parent_.x);
                        parent_.xVel = - parent_.xVel;
                    }
                }

                else if (entity.bounceDir == BounceDirection.UP) {
                    WorldPoint entityTL = entity.TL;
                    WorldPoint entityTR = entity.TR;
                    if     (SegmentIntersectsHorizontal(oldBL, newBL,
                                                        entityTL, entityTR) ||
                            SegmentIntersectsHorizontal(oldBR, newBR,
                                                        entityTL, entityTR)) {
                        debug writefln("    Bouncing up.");
                        parent_.bottom = entity.top -
                                         abs(parent_.bottom - entity.top);
                        // parent_.y = entity.y -
                        //             abs((parent_.y + parent_.h) - entity.y) -
                        //             parent_.h;
                        parent_.yVel = - parent_.yVel;
                    }
                }

                else if (entity.bounceDir == BounceDirection.DOWN) {
                    WorldPoint entityBL = entity.BL;
                    WorldPoint entityBR = entity.BR;
                    if     (SegmentIntersectsHorizontal(oldTL, newTL,
                                                        entityBL, entityBR) ||
                            SegmentIntersectsHorizontal(oldTR, newTR,
                                                        entityBL, entityBR)) {
                        debug writefln("    Bouncing down.");
                        parent_.top = entity.bottom +
                                      abs(entity.bottom - parent_.top);
                        // parent_.y = entity.y + entity.h +
                        //             abs((entity.y + entity.h) - parent_.y);
                        parent_.yVel = - parent_.yVel;
                    }
                }
            }

            // TODO: Actually check this
            finishedBouncing = true;
        }
    }
}

class PaddlePhysics : PhysicsComponent {
    this(Paddle parent)
    {
        super(parent);

        debug writefln("Constructing a Paddle's PhysicsComponent.");
    }

    override void update(double elapsedTime)
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

        // FIXME: Remove this.
        parent_.yVel = maxSpeed;

        super.update(elapsedTime);

        // Stop at walls.
        double minY = (cast(Paddle) parent_).minY;
        double maxY = (cast(Paddle) parent_).maxY;

        if (parent_.bottom > maxY) { parent_.bottom = maxY; }
        if (parent_.top    < minY) { parent_.top    = minY; }
        // XXX: It would be polite to set the velocity to zero, but paddles
        // can turn instantaneously, so that's not necessary.
    }
}


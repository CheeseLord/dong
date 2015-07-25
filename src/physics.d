import std.stdio;
import std.math: abs;

// We need to access entities' states to move them around in the world.
import gamestate;
import entity;
import worldgeometry;

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

        // TODO: Make it possible to bounce off top and bottom of paddle.
        // FIXME: Allow bouncing at all.

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


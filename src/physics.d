// We need to access entities' states to move them around in the world.
import gamestate;

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


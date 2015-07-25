import std.stdio;

// These are named after the side of the field on which they occur. Hence
// BALL_BOUNCE_LEFT_PADDLE refers to the ball bouncing off of the left paddle,
// even though that's a rightward bounce.
enum NotifyType {BALL_BOUNCE_LEFT_PADDLE, BALL_BOUNCE_RIGHT_PADDLE,
                 BALL_PASS_LEFT,          BALL_PASS_RIGHT};

alias Observer = void delegate(NotifyType);

mixin template Subject() {
    private Observer[] observers_;

    final void AddObserver(Observer observer)
    {
        observers_ ~= observer;
    }

    // TODO: Mark this somehow so that it produces a (non-fatal) warning if we
    // actually ever call it, because in that case we may accumulate unbounded
    // memory.
    final bool RemoveObserver(Observer observer)
    {
        foreach (i; 0..observers_.length) {
            if (observers_[i] == observer) {
                // Ideally, we'd actually check for blank spaces when running
                // AddObserver. However, since I don't think we'll ever call
                // RemoveObserver, let's not worry about it for now.
                observers_[i] = null;
                return true;
            }
        }

        return false;
    }

    protected final void Notify(NotifyType eventInfo) {
        // TODO: Handle concurrent modification, or at least set a flag so we
        // can assert that no one calls AddObserver or RemoveObserver while
        // we're in the middle of foreach'ing over observers_.
        foreach (observer; observers_) {
            if (observer !is null) {
                observer(eventInfo);
            }
        }
    }
}


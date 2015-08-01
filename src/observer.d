import std.stdio;

import score;
import sound;

// These are named after the side of the field on which they occur. Hence
// BALL_BOUNCE_LEFT_PADDLE refers to the ball bouncing off of the left paddle,
// even though that's a rightward bounce.
enum NotifyType {BALL_BOUNCE_LEFT_PADDLE, BALL_BOUNCE_RIGHT_PADDLE,
                 BALL_BOUNCE_BOTTOM_WALL, BALL_BOUNCE_TOP_WALL,
                 BALL_PASS_LEFT,          BALL_PASS_RIGHT};

alias Observer = void delegate(NotifyType);

class ObserverList {
    Observer[] observers_ = [];

    void AddObserver(Observer observer)
    {
        observers_ ~= observer;
    }

    void Notify(NotifyType eventInfo)
    {
        foreach (Observer observer; observers_) { observer(eventInfo); }
    }
}

ObserverList observers;

void InitObservers()
{
    observers = new ObserverList();

    observers.AddObserver((x) => score.OnBallPass(x));
    observers.AddObserver((x) => sound.OnBallPass(x));
    observers.AddObserver((x) => sound.HitPaddle(x));
    observers.AddObserver((x) => sound.HitWall(x));
}


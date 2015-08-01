import std.stdio;

import observer;

void OnBallPass(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_PASS_LEFT)
    {
        debug writefln("Hey, the ball escaped on the left.");
    }
    else if (eventInfo == NotifyType.BALL_PASS_RIGHT)
    {
        debug writefln("Hey, the ball escaped on the right.");
    }
}


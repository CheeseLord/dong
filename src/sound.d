import std.stdio;

import observer;

void OnBallPass(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_PASS_LEFT)
    {
        debug writefln("Ding: Passed left.");
    }
    else if (eventInfo == NotifyType.BALL_PASS_RIGHT)
    {
        debug writefln("Ding: Passed right.");
    }
}

void HitPaddle(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_BOUNCE_LEFT_PADDLE)
    {
        debug writefln("Dong: Bounced left.");
    }
    else if (eventInfo == NotifyType.BALL_BOUNCE_RIGHT_PADDLE)
    {
        debug writefln("Dong: Bounced right.");
    }
}

void HitWall(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_BOUNCE_BOTTOM_WALL)
    {
        debug writefln("Dong: Bounced bottom.");
    }
    else if (eventInfo == NotifyType.BALL_BOUNCE_TOP_WALL)
    {
        debug writefln("Dong: Bounced top.");
    }
}


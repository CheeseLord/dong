import std.stdio;

import observer;

void OnBallPass(NotifyType eventInfo)
{
    debug writefln("Hey, the ball escaped: %s", eventInfo);
}


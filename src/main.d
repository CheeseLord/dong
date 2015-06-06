import std.stdio;

import core.time;
import core.thread;

void main()
{
    // Run the main game loop.
    while (true)
    {
        // FIXME: Magic number bad.
        int frameRate = 5;
        Duration frameLength = dur!"seconds"(1) / frameRate;

        MonoTime start = MonoTime.currTime;

        // FIXME: Do stuff here.

        MonoTime end = MonoTime.currTime;
        Duration elapsed = end - start;

        Thread.sleep(frameLength - elapsed);

        writefln("Are we there yet?");
        // FIXME: Take this out when there's another way to quit.
        // break;
    }
}


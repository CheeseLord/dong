import std.stdio;
import core.time;

void main()
{
    // Run the main game loop.
    while (true)
    {
        MonoTime start = MonoTime.currTime;
        MonoTime end = MonoTime.currTime;
        Duration elapsed = end - start;
        writefln("Time taken " ~ elapsed.toString());
        break;
    }
}


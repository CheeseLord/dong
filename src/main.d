import std.stdio;

import core.time;
import core.thread;

import derelict.sdl2.sdl;

void main()
{
    // Load shared libraries.
    DerelictSDL2.load();

    SDL_Init(SDL_INIT_VIDEO);

    SDL_Window *window = SDL_CreateWindow("Dong",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        640, 480, SDL_WINDOW_OPENGL);

    if (window == null) {
        writefln("Error: failed to create window.");
        return;
    }

    scope(exit) {
        writefln("Exiting.");
        SDL_DestroyWindow(window);
        SDL_Quit();
    }

    int count = 0;

    // Run the main game loop.
    while (true)
    {
        // FIXME: Magic number bad.
        int frameRate = 5;
        Duration frameLength = dur!"seconds"(1) / frameRate;

        MonoTime start = MonoTime.currTime;

        // FIXME: Do stuff here.
        count += 1;

        if (count > frameRate * 5) {
            break;
        }

        writefln("Are we there yet?");

        MonoTime end = MonoTime.currTime;
        Duration elapsed = end - start;

        Thread.sleep(frameLength - elapsed);
    }
}


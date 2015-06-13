import std.conv;
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

    // Create a surface and paint it black.
    SDL_Surface *surface = SDL_GetWindowSurface(window);
    SDL_FillRect(surface, null,  SDL_MapRGB(surface.format, 0, 0, 0));
    SDL_UpdateWindowSurface(window);

    // Run the main game loop.
    MAIN_LOOP: while (true)
    {
        // FIXME: Magic number bad.
        int frameRate = 5;
        Duration frameLength = dur!"seconds"(1) / frameRate;

        // FIXME: Handle time better.
        MonoTime start = MonoTime.currTime;

        // FIXME: Do stuff here.
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            writefln("Got an event. Type = %s", event.type);
            if (event.type == SDL_QUIT) {
                break MAIN_LOOP;
            }
        }

        writefln("Are we there yet?");

        MonoTime end = MonoTime.currTime;
        Duration elapsed = end - start;

        Thread.sleep(frameLength - elapsed);
    }
}


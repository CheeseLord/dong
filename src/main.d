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

    // Run the main game loop.
    MAIN_LOOP: while (true)
    {
        // FIXME: Magic number bad.
        int frameRate = 5;
        Duration frameLength = dur!"seconds"(1) / frameRate;

        MonoTime start = MonoTime.currTime;

        // FIXME: Do stuff here.
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            writefln("Got an event. Type = %s (%s)", event.type,
                GetEventTypeName(event.type));
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

string GetEventTypeName(uint eventType)
{
    switch(eventType) {
        case SDL_QUIT:              return "quit";
        case SDL_KEYDOWN:           return "key down";
        case SDL_KEYUP:             return "key up";
        case SDL_TEXTEDITING:       return "text editing";
        case SDL_TEXTINPUT:         return "text input";
        case SDL_MOUSEMOTION:       return "mouse motion";
        case SDL_MOUSEBUTTONDOWN:   return "mouse button down";
        case SDL_MOUSEBUTTONUP:     return "mouse button up";
        case SDL_MOUSEWHEEL:        return "mouse wheel";
        default:                    return "<something else>";
    }
}


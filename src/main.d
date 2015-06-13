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

    // The time at which the previous iteration of the event loop began.
    MonoTime prevStartTime = MonoTime.currTime;

    // FIXME: Magic number bad.
    int frameRate = 5;
    Duration frameLength = dur!"seconds"(1) / frameRate;

    // Run the main game loop.
    MAIN_LOOP: while (true)
    {
        // Get the time at which this iteration of the event loop begins.
        MonoTime currStartTime = MonoTime.currTime;

        // Update the game state, based on the amount of time elapsed since
        // the previous event loop iteration.
        UpdateGame(currStartTime - prevStartTime);

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
        SDL_UpdateWindowSurface(window);

        prevStartTime = currStartTime;

        // Sleep for the rest of the frame.
        // Note: we don't need to check whether this is negative because
        // Thread.sleep treats a negative value as if we passed zero.
        Thread.sleep(frameLength - (MonoTime.currTime - currStartTime));
    }
}

void UpdateGame(Duration elapsedTime)
{
    writefln("Updating game. %s elapsed.", elapsedTime);
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


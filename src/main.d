import std.conv;
import std.stdio;

import core.time;
import core.thread;

import derelict.sdl2.sdl;

import gamestate;
import control;
import physics;
import graphics;
import observer;

bool inMenu = true;

void main()
{
    InitGraphics();
    scope (exit) CleanupGraphics();

    InitGameState();
    InitObservers();

    // The time at which the previous iteration of the event loop began.
    MonoTime prevStartTime = MonoTime.currTime;

    // FIXME: Magic number bad.
    int frameRate = 20;
    Duration frameLength = dur!"seconds"(1) / frameRate;

    // Run the main game loop.
    while (true)
    {
        // Get the time at which this iteration of the event loop begins.
        MonoTime currStartTime = MonoTime.currTime;

        if (inMenu) {
            SDL_Event event;
            while (SDL_PollEvent(&event)) {
                if (event.type == SDL_KEYDOWN) {
                    inMenu = false;
                    break;
                }
            }
            RenderMenu();
        }
        else {
            if (HandleEvents()) {
                break;
            }

            // Update the game state, based on the amount of time elapsed since
            // the previous event loop iteration.
            UpdateWorld(currStartTime - prevStartTime);

            // Draw the current game state.
            RenderGame();
        }

        prevStartTime = currStartTime;

        // Sleep for the rest of the frame, unless we've taken too much time
        // already.
        Duration timeToSleep = frameLength -
                               (MonoTime.currTime - currStartTime);
        if (!timeToSleep.isNegative)
            Thread.sleep(timeToSleep);
    }
}



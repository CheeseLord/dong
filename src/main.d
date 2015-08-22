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

bool function(Duration elapsedTime) currentStage = &MainMenuFrame;

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

        // Carry out one frame of the game or current menu.
        if (currentStage(currStartTime - prevStartTime)) {
            break;
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


// FIXME: These should probably go in another file somewhere. Along with
// currentStage.

bool GameFrame(Duration elapsedTime)
{
    if (HandleEvents()) {
        return true;
    }

    // Update the game state, based on the amount of time elapsed since
    // the previous event loop iteration.
    UpdateWorld(elapsedTime);

    // Draw the current game state.
    RenderGame();

    return false;
}

bool MainMenuFrame(Duration elapsedTime)
{
    SDL_Event event;

    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            return true;
        }
        if (event.type == SDL_KEYDOWN) {
            if (event.key.keysym.sym == SDLK_p) {
                currentStage = &GameFrame;
                break;
            }
            else if (event.key.keysym.sym == SDLK_s) {
                currentStage = &SettingsFrame;
                break;
            }
        }
    }

    RenderMainMenu();

    return false;
}

bool SettingsFrame(Duration elapsedTime)
{
    SDL_Event event;

    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            return true;
        }
        if (event.type == SDL_KEYDOWN) {
            if (event.key.keysym.sym == SDLK_m) {
                currentStage = &MainMenuFrame;
                break;
            }
        }
    }

    RenderSettingsMenu();

    return false;
}


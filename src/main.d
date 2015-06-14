import std.conv;
import std.stdio;

import core.time;
import core.thread;

import derelict.sdl2.sdl;


struct _GameState {
    // Screen-independent size.
    // FIXME: Remove evil magic numbers.
    double worldWidth = 200;
    double worldHeight = 100;

    // Coordinates of top-left corner of ball, in pixels, relative to top-left
    // of screen.
    // FIXME: Use screen-independent coordinates. And floats?
    double ballX;
    double ballY;

    // Velocity of the ball, in pixels per second.
    double ballVX;
    double ballVY;

    // Size of the ball, in pixels. I'm still making this a double for now
    // because eventually it's going to need to be in screen-independent
    // coordinates, so it'll be converted along with the rest of these.
    double ballWidth;
    double ballHeight;
}

_GameState gameState;


void main()
{
    // Set up SDL.
    DerelictSDL2.load();
    SDL_Init(SDL_INIT_VIDEO);

    // Try creating a window.
    // FIXME: Remove magic numbers.
    SDL_Window *window = SDL_CreateWindow("Dong",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        640, 480, SDL_WINDOW_OPENGL);

    if (window == null) {
        writefln("Error: failed to create window.");
        return;
    }

    // Create a surface and paint it black.
    SDL_Surface *surface = SDL_GetWindowSurface(window);
    SDL_FillRect(surface, null, SDL_MapRGB(surface.format, 0, 0, 0));

    // Make sure SDL gets cleaned up when we're done.
    scope(exit) {
        writefln("Exiting.");
        SDL_DestroyWindow(window);
        SDL_Quit();
    }

    // Initialize game state.
    gameState.ballX  = gameState.worldWidth / 10;
    gameState.ballY  = gameState.worldHeight / 2;
    gameState.ballVX = 30.0;
    gameState.ballVY = 0.0;
    gameState.ballWidth  = 10.0;
    gameState.ballHeight = 10.0;

    // The time at which the previous iteration of the event loop began.
    MonoTime prevStartTime = MonoTime.currTime;

    // FIXME: Magic number bad.
    int frameRate = 20;
    Duration frameLength = dur!"seconds"(1) / frameRate;

    // Run the main game loop.
    MAIN_LOOP: while (true)
    {
        // Get the time at which this iteration of the event loop begins.
        MonoTime currStartTime = MonoTime.currTime;

        // FIXME: Do stuff here.
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            debug writefln("Got an event. Type = %s (%s)", event.type,
                GetEventTypeName(event.type));
            if (event.type == SDL_QUIT) {
                break MAIN_LOOP;
            }
        }

        // Update the game state, based on the amount of time elapsed since
        // the previous event loop iteration.
        UpdateGame(currStartTime - prevStartTime);

        // Draw the current game state.
        RenderGame(surface);

        // Update the window to actually display the newly drawn game state.
        SDL_UpdateWindowSurface(window);

        prevStartTime = currStartTime;

        // Sleep for the rest of the frame, unless we've taken too much time
        // already.
        Duration timeToSleep = frameLength -
                               (MonoTime.currTime - currStartTime);
        if (!timeToSleep.isNegative)
            Thread.sleep(timeToSleep);
    }
}

void UpdateGame(Duration elapsedTime)
{
    // Convert the elapsedTime to seconds.
    long secs, nsecs;
    elapsedTime.split!("seconds", "nsecs")(secs, nsecs);
    double elapsedSeconds = cast(double)(secs) + cast(double)(nsecs) / 1.0e9;

    debug {
        writefln("Updating game. %s.%07s seconds elapsed.", secs, nsecs / 100);
    }

    // Move the ball, based on its current velocity.
    gameState.ballX += gameState.ballVX * elapsedSeconds;
    gameState.ballY += gameState.ballVY * elapsedSeconds;

    debug {
        writefln("    Ball is at (%s, %s).", gameState.ballX, gameState.ballY);
    }
}

void drawRect(SDL_Surface *surface, SDL_Rect *worldRect, Uint32 color)
{
    // Find the scale factors.
    double horizontalScale = surface.w / gameState.worldWidth;
    double verticalScale   = surface.h / gameState.worldHeight;

    // Create the rectangle.
    SDL_Rect surfaceRect = {
        // NOTE: If we had an offset, we'd subtract it here.
        x: cast(int) (horizontalScale * worldRect.x),
        y: cast(int) (verticalScale   * worldRect.y),
        w: cast(int) (horizontalScale * worldRect.w),
        h: cast(int) (verticalScale   * worldRect.h),
    };

    // Draw to the screen.
    SDL_FillRect(surface, &surfaceRect, color);
}

void RenderGame(SDL_Surface *surface)
{
    SDL_Rect backgroundRect = {
        x: cast(int) 0,
        y: cast(int) 0,
        w: cast(int) gameState.worldWidth,
        h: cast(int) gameState.worldHeight
    };

    SDL_Rect ballRect = {
        x: cast(int) gameState.ballX,
        y: cast(int) gameState.ballY,
        w: cast(int) gameState.ballWidth,
        h: cast(int) gameState.ballHeight,
    };

    drawRect(surface, &backgroundRect, SDL_MapRGB(surface.format, 0, 0,   0));
    drawRect(surface, &ballRect,       SDL_MapRGB(surface.format, 0, 191, 0));
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


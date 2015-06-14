import std.conv;
import std.stdio;

import core.time;
import core.thread;

import derelict.sdl2.sdl;


struct WorldRect {
    double x;
    double y;
    double w;
    double h;
}

alias ScreenRect = SDL_Rect;

struct _GameState {
    // Screen-independent size.
    // FIXME: Remove evil magic numbers.
    double worldWidth  = 200;
    double worldHeight = 100;

    // Coordinates of top-left corner of ball.
    double ballX;
    double ballY;

    // Velocity of the ball.
    double ballVX;
    double ballVY;

    // Size of the ball.
    double ballWidth;
    double ballHeight;
}

_GameState gameState;


void main()
{
    // Set up SDL.
    DerelictSDL2.load();
    SDL_Init(SDL_INIT_VIDEO);

    // Make sure SDL gets cleaned up when we're done.
    scope(exit) {
        writefln("Exiting.");
        SDL_Quit();
    }

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

    // Make sure the window gets cleaned up when we're done.
    scope(exit) SDL_DestroyWindow(window);

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

void RenderGame(SDL_Surface *surface)
{
    // FIXME: This will eventually be not the entire screen.
    ScreenRect sWorldRect = {
        x: cast(int) 0,
        y: cast(int) 0,
        w: cast(int) surface.w,
        h: cast(int) surface.h
    };

    // FIXME: Store as a rect in the gameState.
    WorldRect  wBallRect = {
        x: cast(int) gameState.ballX,
        y: cast(int) gameState.ballY,
        w: cast(int) gameState.ballWidth,
        h: cast(int) gameState.ballHeight,
    };

    ScreenRect sBallRect;

    WorldToScreenRect(sBallRect, sWorldRect, wBallRect);

    SDL_FillRect(surface, null,       SDL_MapRGB(surface.format, 0, 0,   0));
    SDL_FillRect(surface, &sBallRect, SDL_MapRGB(surface.format, 0, 191, 0));
}

/**
 * Convert a rect from world coordinates to screen coordinates.
 * The resulting rect will be stored in sRect.
 * sWorldRect is the region of the screen corresponding to the entire world.
 * wRect is the rect to be converted.
 * TODO: Magic markup in function comments so parameter names and such get
 * displayed correctly in generated HTML docs?
 */
void WorldToScreenRect(out ScreenRect sRect, ScreenRect sWorldRect,
                       WorldRect wRect)
{
    // Find the scale factors.
    double horizontalScale = sWorldRect.w / gameState.worldWidth;
    double verticalScale   = sWorldRect.h / gameState.worldHeight;

    // Convert the rect. Create a copy of the rect on the stack because (as far
    // as I can tell) D won't let us provide names for the fields of a struct
    // when assigning values to them unless we do it as part of a declaration
    // (or initialize them separately).
    ScreenRect mySRect = {
        // Note: if the world started at anything other than (0, 0), we'd need
        // to subtract its top-left coordinates before rescaling x and y.
        x: cast(int) (horizontalScale * wRect.x + sWorldRect.x),
        y: cast(int) (verticalScale   * wRect.y + sWorldRect.y),
        w: cast(int) (horizontalScale * wRect.w),
        h: cast(int) (verticalScale   * wRect.h)
    };

    // Actually store the rect in the output variable where it belongs. If the
    // D compiler is at all intelligent, it should just write the values
    // directly into sRect instead of actually creating a second rect, but I
    // haven't actually checked the generated assembly.
    sRect = mySRect;
}


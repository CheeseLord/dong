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


class Entity {
    private WorldRect wRect_;
    private double    xVel_;
    private double    yVel_;

    this(WorldRect startWRect) {
        wRect_ = startWRect;
    }

    this(double x, double y, double w, double h) {
        wRect_ = WorldRect(x, y, w, h);
    }

    // Accessors and mutators for all of our members.
    // Because encapsulation? What's that?
    pure @property ref WorldRect wRect() { return wRect_;   }
    pure @property ref double        x() { return wRect_.x; }
    pure @property ref double        y() { return wRect_.y; }
    pure @property ref double        w() { return wRect_.w; }
    pure @property ref double        h() { return wRect_.h; }
    pure @property ref double     xVel() { return xVel_;    }
    pure @property ref double     yVel() { return yVel_;    }
}


struct _GameState {
    // Screen-independent size.
    // FIXME: Remove evil magic numbers.
    double worldWidth  = 200.0;
    double worldHeight = 100.0;

    Entity ball;
}

_GameState gameState;


void main()
{
    // Set up SDL.
    DerelictSDL2.load();
    SDL_Init(SDL_INIT_VIDEO);

    // Make sure SDL gets cleaned up when we're done.
    scope (exit) {
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
    scope (exit) SDL_DestroyWindow(window);

    // Initialize game state.
    gameState.ball = new Entity(CenteredWRect(
        gameState.worldWidth  / 10, // x
        gameState.worldHeight / 2,  // y
        3.0,                        // width
        3.0                         // height
    ));
    gameState.ball.xVel = 30.0;
    gameState.ball.yVel = 0.0;

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

WorldRect CenteredWRect(double centerX, double centerY, double w, double h)
{
    return WorldRect(
        centerX - w / 2, // x
        centerY - h / 2, // y
        w,               // width
        h                // height
    );
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
    gameState.ball.x += gameState.ball.xVel * elapsedSeconds;
    gameState.ball.y += gameState.ball.yVel * elapsedSeconds;

    debug {
        writefln("    Ball is at (%s, %s).",
                 gameState.ball.x, gameState.ball.y);
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

    ScreenRect sBallRect;

    WorldToScreenRect(sBallRect, sWorldRect, gameState.ball.wRect);

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

    // Convert the rect.
    sRect = ScreenRect(
        // Note: if the world started at anything other than (0, 0), we'd need
        // to subtract its top-left coordinates before rescaling x and y.
        cast(int) (horizontalScale * wRect.x + sWorldRect.x), // x
        cast(int) (verticalScale   * wRect.y + sWorldRect.y), // y
        cast(int) (horizontalScale * wRect.w),                // width
        cast(int) (verticalScale   * wRect.h)                 // height
    );
}


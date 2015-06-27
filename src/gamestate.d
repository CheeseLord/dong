import std.stdio;
import core.time;

import entity;

struct WorldRect {
    double x;
    double y;
    double w;
    double h;
}

struct _GameState {
    // Screen-independent size.
    // FIXME: Remove evil magic numbers.
    double worldWidth  = 200.0;
    double worldHeight = 100.0;

    Entity[] entities;
}

_GameState gameState;

void InitGameState()
{
    const double WALL_WIDTH = 5.0;

    // Left wall
    gameState.entities ~= new Wall(
        WorldRect(
            0,
            0,
            WALL_WIDTH,
            gameState.worldHeight
        ),
        BounceDirection.RIGHT
    );

    // Top wall
    gameState.entities ~= new Wall(
        WorldRect(
            0,
            0,
            gameState.worldWidth,
            WALL_WIDTH
        ),
        BounceDirection.DOWN
    );

    // Right wall
    gameState.entities ~= new Wall(
        WorldRect(
            gameState.worldWidth - WALL_WIDTH,
            0,
            WALL_WIDTH,
            gameState.worldHeight
        ),
        BounceDirection.LEFT
    );

    // Bottom wall
    gameState.entities ~= new Wall(
        WorldRect(
            0,
            gameState.worldHeight - WALL_WIDTH,
            gameState.worldWidth,
            WALL_WIDTH
        ),
        BounceDirection.UP
    );

    // The ball
    gameState.entities ~= new Ball(
        CenteredWRect(
            gameState.worldWidth  / 10, // x
            gameState.worldHeight / 2,  // y
            3.0,                        // width
            3.0                         // height
        ),
        30.0,                           // x velocity
        0.0,                            // x velocity
    );
}

void UpdateWorld(Duration elapsedTime)
{
    // Convert the elapsedTime to seconds.
    long secs, nsecs;
    elapsedTime.split!("seconds", "nsecs")(secs, nsecs);
    double elapsedSeconds = cast(double)(secs) + cast(double)(nsecs) / 1.0e9;

    debug {
        writefln("Updating game. %s.%07s seconds elapsed.", secs, nsecs / 100);
    }

    // FIXME: Actually loop over a list.
    foreach (Entity entity; gameState.entities) {
        entity.update(elapsedSeconds);

        debug {
            // Quick hack to print the ball's position. I don't like dynamic
            // casts, but I'll put up with this because it's in a debug block
            // anyway.
            if (cast(Ball)(entity) !is null) {
                writefln("    Ball is at (%s, %s).", entity.x, entity.y);
            }
        }
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


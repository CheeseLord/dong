import std.stdio;
import core.time;

import entity;
import worldgeometry;
// TODO: We really want the controllers set in a user menu, not here.
import control;

import derelict.sdl2.sdl;


// TODO: We'll probably want to make the sides of the game area constant
// instead of defining them by these sizes.
const double WALL_WIDTH = 5.0;
const double PADDLE_WIDTH = 5.0;
const double PADDLE_HEIGHT = 10.0;
const double PADDLE_MAX_SPEED = 30.0;

private struct GameState {
    // Screen-independent size.
    // FIXME: Remove evil magic numbers.
    WorldRect gameRect = {
        x: 0,
        y: 0,
        w: 200,
        h: 100,
    };
    pure @property const double worldWidth()  { return gameRect.w; }
    pure @property const double worldHeight() { return gameRect.h; }

    Ball ball;
    Entity[] entities;
}

GameState gameState;

void InitGameState()
{
    // Left paddle
    Paddle leftPaddle = new Paddle(
        WorldRect(
            PADDLE_WIDTH,
            gameState.worldHeight / 2 - PADDLE_HEIGHT / 2,
            PADDLE_WIDTH,
            PADDLE_HEIGHT,
        ),
        BounceDirection.RIGHT,
        PADDLE_MAX_SPEED,
        WALL_WIDTH,
        gameState.worldHeight - WALL_WIDTH,
    );
    leftPaddle.SetControl(new LessDumbAIControlComponent(leftPaddle));
    gameState.entities ~= leftPaddle;

    // Right paddle
    Paddle rightPaddle = new Paddle(
        WorldRect(
            gameState.worldWidth - 2 * PADDLE_WIDTH,
            gameState.worldHeight / 2 - PADDLE_HEIGHT / 2,
            PADDLE_WIDTH,
            PADDLE_HEIGHT,
        ),
        BounceDirection.LEFT,
        PADDLE_MAX_SPEED,
        WALL_WIDTH,
        gameState.worldHeight - WALL_WIDTH,
    );
    rightPaddle.SetControl(new KeyControlComponent(rightPaddle,
                                                   SDL_SCANCODE_UP,
                                                   SDL_SCANCODE_DOWN));
    gameState.entities ~= rightPaddle;

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
    Ball ball = new Ball(
        CenteredWRect(
            gameState.worldWidth  / 2,  // x
            gameState.worldHeight / 2,  // y
            3.0,                        // width
            3.0                         // height
        ),
        25.0,                           // x velocity
        25.0,                           // y velocity
    );
    gameState.entities ~= ball;
    gameState.ball = ball;
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
        entity.Update(elapsedSeconds);

        debug (ShowBallPos) {
            // Quick hack to print the ball's position. I don't like dynamic
            // casts, but I'll put up with this because it's in a debug block
            // anyway.
            if (cast(Ball)(entity) !is null) {
                writefln("    Ball is at (%s, %s).", entity.x, entity.y);
            }
        }
    }
}


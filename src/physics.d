import std.stdio;
import core.time;

// We need to access entities' states to move them around in the world.
import gamestate;

void UpdateWorld(Duration elapsedTime)
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


import std.conv;
import std.stdio;

import core.time;
import core.thread;

import derelict.sdl2.sdl;

import gamestate;
import controller;
import physics;
import graphics;

void main()
{
    InitGraphics();
    scope (exit) CleanupGraphics();

    InitGameState();

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
        if (HandleEvents()) {
            break;
        }

        // Update the game state, based on the amount of time elapsed since
        // the previous event loop iteration.
        UpdateGame(currStartTime - prevStartTime);

        // Draw the current game state.
        RenderGame();

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
    gameState.ball.x += gameState.ball.xVel * elapsedSeconds;
    gameState.ball.y += gameState.ball.yVel * elapsedSeconds;

    debug {
        writefln("    Ball is at (%s, %s).",
                 gameState.ball.x, gameState.ball.y);
    }
}


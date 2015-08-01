import std.stdio;

import gamestate;
import observer;

void OnBallPass(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_PASS_LEFT)
    {
        debug writefln("Hey, the ball escaped on the left.");
        gameState.ball.centerX = gameState.worldWidth / 2;
        gameState.ball.centerY = gameState.worldHeight / 2;
    }
    else if (eventInfo == NotifyType.BALL_PASS_RIGHT)
    {
        debug writefln("Hey, the ball escaped on the right.");
        gameState.ball.centerX = gameState.worldWidth / 2;
        gameState.ball.centerY = gameState.worldHeight / 2;
    }
}


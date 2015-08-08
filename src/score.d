import std.stdio;

import gamestate;
import observer;

void OnBallPass(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_PASS_LEFT)
    {
        debug writefln("Hey, the ball escaped on the left.");
        scores.RightPlayerScore();
        debug writefln("Score: %d - %d", scores.left, scores.right);
        gameState.ball.centerX = gameState.worldWidth / 2;
        gameState.ball.centerY = gameState.worldHeight / 2;
    }
    else if (eventInfo == NotifyType.BALL_PASS_RIGHT)
    {
        debug writefln("Hey, the ball escaped on the right.");
        scores.LeftPlayerScore();
        debug writefln("Score: %d - %d", scores.left, scores.right);
        gameState.ball.centerX = gameState.worldWidth / 2;
        gameState.ball.centerY = gameState.worldHeight / 2;
    }
}

private struct Scores
{
    int left, right;

    void Reset()
    {
        left = 0;
        right = 0;
    }

    void LeftPlayerScore()
    {
        left += 1;
    }

    void RightPlayerScore()
    {
        right += 1;
    }
}

Scores scores;


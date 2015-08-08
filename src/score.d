import std.stdio;

import gamestate;
import observer;
import entity;

void OnBallPass(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_PASS_LEFT)
    {
        debug writefln("Hey, the ball escaped on the left.");
        scores.RightPlayerScore();
        debug writefln("Score: %d - %d", scores.left, scores.right);
        gameState.ball.Reset(BallStartDirection.LEFT);
    }
    else if (eventInfo == NotifyType.BALL_PASS_RIGHT)
    {
        debug writefln("Hey, the ball escaped on the right.");
        scores.LeftPlayerScore();
        debug writefln("Score: %d - %d", scores.left, scores.right);
        gameState.ball.Reset(BallStartDirection.RIGHT);
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


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
    // TODO: If I were a better person, this could be set elsewhere.
    int maxScore = 3;

    void Reset()
    {
        left = 0;
        right = 0;
    }

    void LeftPlayerScore()
    {
        left += 1;
        if (left >= maxScore)
        {
            observers.Notify(NotifyType.LEFT_PLAYER_WIN);
        }
    }

    void RightPlayerScore()
    {
        right += 1;
        if (right >= maxScore)
        {
            observers.Notify(NotifyType.RIGHT_PLAYER_WIN);
        }
    }
}

Scores scores;


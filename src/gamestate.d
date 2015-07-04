import std.stdio;
import core.time;

import entity;

// I suppose we could use this in the WorldRect struct, but I don't really want
// to add more indirection there.
struct WorldPoint {
    double x;
    double y;
}

struct WorldRect {
    double x;
    double y;
    double w;
    double h;

    pure @property const WorldPoint TL() { return WorldPoint(x    , y    ); }
    pure @property const WorldPoint TR() { return WorldPoint(x + w, y    ); }
    pure @property const WorldPoint BL() { return WorldPoint(x    , y + h); }
    pure @property const WorldPoint BR() { return WorldPoint(x + w, y + h); }
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

/**
 * Check whether two line segments intersect. One segment goes from s1Start to
 * s1End; the other goes from s2Start to s2End. The second one must be
 * perfectly vertical.
 */
bool SegmentIntersectsVertical(WorldPoint s1Start, WorldPoint s1End,
                               WorldPoint s2Start, WorldPoint s2End)
{
    // s2Start.x and s2End.x are assumed equal.
    double s2x = s2Start.x;

    if     ((s1Start.x < s2x && s1End.x > s2x) ||
            (s1Start.x > s2x && s1End.x < s2x)) {
        // Segment 1 starts and ends on opposite sides (horizontally speaking)
        // of segment 2, so an intersection is possible.

        // Compute the y-coordinate of segment 1 at s2x. If the two segments
        // intersect, it must be at this y-coordinate, so we call it
        // intersectY. To find this coordinate, we make use of the fact that:
        //      intersectY - s1Start.y       s1End.y - s1Start.y
        //     ------------------------  =  ---------------------
        //             s2x - s1Start.x       s1End.x - s1Start.x
        double intersectY = (s1End.y - s1Start.y) / (s1End.x - s1Start.x) *
                            (s2x - s1Start.x) +
                            s1Start.y;

        return ((s2Start.y < intersectY && intersectY < s2End.y) ||
                (s2Start.y > intersectY && intersectY > s2End.y));
    }

    return false;
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


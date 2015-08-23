import std.stdio;

import derelict.sdl2.sdl;

import observer;

void InitSound()
{
    // Initialize the drivers.
    for (int i = 0; i < SDL_GetNumAudioDrivers(); ++i) {
        const char *driverName = SDL_GetAudioDriver(i);
        if (SDL_AudioInit(driverName)) {
            debug printf("FAILED TO LOAD AUDIO DRIVER %s\n", driverName);
        }
    }
}

void CleanupSound()
{
    SDL_AudioQuit();
}

void OnBallPass(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_PASS_LEFT) {
        debug writefln("Ding: Passed left.");
    }
    else if (eventInfo == NotifyType.BALL_PASS_RIGHT) {
        debug writefln("Ding: Passed right.");
    }
}

void HitPaddle(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_BOUNCE_LEFT_PADDLE) {
        debug writefln("Dong: Bounced off of left paddle.");
    }
    else if (eventInfo == NotifyType.BALL_BOUNCE_RIGHT_PADDLE) {
        debug writefln("Dong: Bounced off of right paddle.");
    }
}

void HitWall(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_BOUNCE_BOTTOM_WALL) {
        debug writefln("Dong: Bounced off of bottom wall.");
    }
    else if (eventInfo == NotifyType.BALL_BOUNCE_TOP_WALL) {
        debug writefln("Dong: Bounced off of top wall.");
    }
}


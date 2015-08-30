import std.stdio;
import std.algorithm: min;

// It's unfortunate that we have to use the unsafe C functions rather than D
// array operations, but since we need to copy data into an array that's passed
// to us by SDL as a pointer, I don't see any other way.
// TODO: Maybe at least copy the audio data into a D array? We'll still need to
// use memcpy to get it into the stream, but it might be an improvement.
import core.stdc.string: memcpy, memset;

import derelict.sdl2.sdl;

import observer;

// The audio playback is done in another thread, so these need to be shared.
private shared const(ubyte)* audioBuffer;
private shared uint          audioBufferLength;

private shared const(ubyte)* audioPos;

void InitSound()
{
    // TODO: Apparently doing this causes the audio *not* to work? That's
    // weird...
    version(none) {
        // Initialize the drivers.
        for (int i = 0; i < SDL_GetNumAudioDrivers(); ++i) {
            const char *driverName = SDL_GetAudioDriver(i);
            if (SDL_AudioInit(driverName)) {
                debug printf("Failed to load audio driver %s\n", driverName);
            }
        }
    }

    SDL_AudioSpec audioSpec;
    ubyte*        myAudioBuffer;
    uint          myAudioBufferLength;

    // FIXME: Magic string bad
    if (SDL_LoadWAV("sounds/ding.wav", &audioSpec,
                    &myAudioBuffer, &myAudioBufferLength) is null) {
        printf("ERROR: Failed to open audio file: %s\n", SDL_GetError());
        // FIXME: Raise exception here.
        return;
    }

    audioBuffer       = cast(shared)(myAudioBuffer);
    audioBufferLength = cast(shared)(myAudioBufferLength);

    // TODO: Use userdata?
    audioPos           = audioBuffer;
    audioSpec.callback = &AudioCallback;

    SDL_AudioDeviceID devId = SDL_OpenAudioDevice(null, false, &audioSpec,
        null, SDL_AUDIO_ALLOW_ANY_CHANGE);
    SDL_PauseAudioDevice(devId, false);

    // TODO: I don't want to just block here, but we really should add a call
    // to SDL_PauseAudioDevice(devId, true) after we finish playing the last
    // chunk so we don't keep needlessly calling the callback and loading
    // silence into the buffer. Maybe we could call PauseAudioDevice from the
    // callback, when the remaining buffer length is zero?
    version(none) {
        while (audioPos - audioBuffer < audioBufferLength) {
            writefln("Still playing...");
            SDL_Delay(100);
        }

        SDL_PauseAudioDevice(devId, true);
    }
}

void CleanupSound()
{
    SDL_CloseAudio();
    SDL_FreeWAV(cast(ubyte*) audioBuffer);

    SDL_AudioQuit();
}


extern (C) nothrow void AudioCallback(void *userdata, ubyte *stream, int len)
{
    // I don't know if it's necessary to check if len is negative (hopefully
    // SDL won't be *that* evil), but I don't want to try to copy 4294967295
    // bytes just because some bozo decided it'd be funny to pass -1.
    if (len <= 0) {
        return;
    }

    // TODO: Someone should code-review this cast(uint).
    uint availableLen = audioBufferLength - cast(uint)(audioPos - audioBuffer);

    // D uses the same stupid silently-promote-signed-to-unsigned rule as C, so
    // the cast isn't strictly necessary here, but I think it makes the code
    // easier to read.
    uint lenToUse = min(cast(uint)(len), availableLen);

    try {
        writefln("Loading audio from %s.", audioPos);
        writefln("    Requested len: %s of %s; using %s.", len, availableLen,
                 lenToUse);
    } catch {}

    // TODO: Use SDL_MixAudioFormat? We'll need to zero the stream first, I
    // think.
    memcpy(cast(void*)(stream), cast(const(void)*)(audioPos), lenToUse);

    if (lenToUse < cast(uint)(len)) {
        // Fill the rest of the stream with silence.
        memset(cast(void*)(stream + lenToUse), 0, cast(uint)(len) - lenToUse);
    }

    core.atomic.atomicOp!"+="(audioPos, lenToUse);
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


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


class AudioManager {
    private const(ubyte)[] audioBuffer_;
    private ulong          audioPos_;

    this() shared
    {
        audioBuffer_ = [];
        audioPos_    = 0;
    }

    void SetBuffer(const(ubyte)* buffer, ulong bufferLength) shared nothrow
    {
        audioBuffer_.length = bufferLength;
        memcpy(cast(void*)(audioBuffer_.ptr), cast(const(void)*)(buffer),
               cast(size_t)(bufferLength));
    }

    void ConsumeBuffer(ulong usedLength) shared nothrow
    {
        audioPos_ = min(audioPos_ + usedLength, audioBuffer_.length);
    }

    shared(const(ubyte)[]) GetRemainingBuffer() shared nothrow
    {
        return audioBuffer_[audioPos_..$];
    }
}

private shared(AudioManager) audioManager;


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

    audioManager = new shared(AudioManager)();

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

    // TODO: Use userdata?
    //     ... for what? It's not going to get around the fact that there's
    //     data being shared between threads.
    audioManager.SetBuffer(myAudioBuffer, myAudioBufferLength);
    SDL_FreeWAV(cast(ubyte*) myAudioBuffer);

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
        while (audioManager.GetRemainingBuffer().length > 0) {
            writefln("Still playing...");
            SDL_Delay(100);
        }

        SDL_PauseAudioDevice(devId, true);
    }
}

void CleanupSound()
{
    SDL_CloseAudio();
    SDL_AudioQuit();
}


// D "int" isn't really always the same as C "int" but I can't figure out how
// to get a native-sized int, so whatever.
extern (C) nothrow void AudioCallback(void *userdata, ubyte *stream, int len)
{
    // I don't know if it's necessary to check if len is negative (hopefully
    // SDL won't be *that* evil), but I don't want to try to copy 4294967295
    // bytes just because some bozo decided it'd be funny to pass -1.
    if (len <= 0) {
        return;
    }

    shared(const(ubyte)[]) audioBuffer = audioManager.GetRemainingBuffer();

    // We know len > 0, so a cast to unsigned is safe.
    ulong lenToUse = min(audioBuffer.length, cast(ulong)(len));

    try {
        writefln("Loading audio from 0x%s.", audioBuffer.ptr);
        writefln("    Requested len: %s of %s; using %s.",
                 len, audioBuffer.length, lenToUse);
    } catch {}

    // TODO: Use SDL_MixAudioFormat? We'll need to zero the stream first, I
    // think.
    memcpy(cast(void*)(stream), cast(const(void)*)(audioBuffer.ptr),
           cast(size_t)(lenToUse));

    if (lenToUse < cast(ulong)(len)) {
        // Fill the rest of the stream with silence.
        // TODO: Fewer casts plz? Kthx.
        memset(cast(void*)(stream + lenToUse), 0,
               cast(size_t)(cast(ulong)(len) - lenToUse));
    }

    audioManager.ConsumeBuffer(lenToUse);
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


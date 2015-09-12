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


/* *** IMPORTANT NOTE ***
 *
 * Any time you call a method of AudioManager when the audio device is (or
 * might be) playing, you must first lock the audio device. Otherwise horrible
 * race conditions will happen, and you will be a sad panda.
 *
 * If you call a method of AudioManager from inside the audio callback, then
 * you don't need to worry about this because the device will already be locked
 * by the audio thread.
 */
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

        // So we don't start playing immediately.
        audioPos_           = bufferLength;
    }

    // Do this the easy way for now. Don't try to handle simultaneous playback.
    void Restart() shared nothrow
    {
        audioPos_ = 0;
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

private SDL_AudioDeviceID audioDeviceId;


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

    audioDeviceId = SDL_OpenAudioDevice(null, false, &audioSpec,
        null, SDL_AUDIO_ALLOW_ANY_CHANGE);
    SDL_PauseAudioDevice(audioDeviceId, false);

    // Note: I think if you call SDL_PauseAudioDevice, then SDL keeps loading
    // silence into the stream behind the scenes, just without calling your
    // callback. If I'm correct about that, then we don't really gain anything
    // by calling SDL_PauseAudioDevice when we're not actively playing
    // anything.
    version(none) {
        while (audioManager.GetRemainingBuffer().length > 0) {
            writefln("Still playing...");
            SDL_Delay(100);
        }

        SDL_PauseAudioDevice(audioDeviceId, true);
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

    debug {
        // Suppress debug output if nothing to write.
        if (lenToUse > 0) {
            try {
                writefln("Loading audio from 0x%s.", audioBuffer.ptr);
                writefln("    Requested len: %s of %s; using %s.",
                         len, audioBuffer.length, lenToUse);
            } catch {}
        }
    }

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
        debug writefln("Whoosh! Passed left.");
    }
    else if (eventInfo == NotifyType.BALL_PASS_RIGHT) {
        debug writefln("Whoosh! Passed right.");
    }
}

void HitPaddle(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_BOUNCE_LEFT_PADDLE) {
        RestartSound();
        debug writefln("Ding: Bounced off of left paddle.");
    }
    else if (eventInfo == NotifyType.BALL_BOUNCE_RIGHT_PADDLE) {
        RestartSound();
        debug writefln("Dong: Bounced off of right paddle.");
    }
}

void HitWall(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_BOUNCE_BOTTOM_WALL) {
        RestartSound();
        debug writefln("Dang: Bounced off of bottom wall.");
    }
    else if (eventInfo == NotifyType.BALL_BOUNCE_TOP_WALL) {
        RestartSound();
        debug writefln("Dang: Bounced off of top wall.");
    }

}


private void RestartSound()
{
    SDL_LockAudioDevice(audioDeviceId);
    audioManager.Restart();
    SDL_UnlockAudioDevice(audioDeviceId);
}


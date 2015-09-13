import std.stdio;
import std.algorithm: min;
import std.typecons:  tuple;

// It's unfortunate that we have to use the unsafe C functions rather than D
// array operations, but since we need to copy data into an array that's passed
// to us by SDL as a pointer, I don't see any other way.
// TODO: Maybe at least copy the audio data into a D array? We'll still need to
// use memcpy to get it into the stream, but it might be an improvement.
import core.stdc.string: memcpy, memset;

import derelict.sdl2.sdl;

import observer;


enum Track: ulong {DING = 0, DONG = 1, DANG = 2};

struct AudioTrackPosition {
    ulong trackIndex;
    ulong bufferPos;
}

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
    private const(ubyte)[][]     tracks_;

    // In a real game, this would be of bounded length.
    private AudioTrackPosition[] nowPlaying_;

    this() shared
    {
        tracks_     = [];
        nowPlaying_ = [];
    }

    // Returns the index of the added track.
    ulong AddTrack(const(ubyte)* buffer, ulong bufferLength) shared nothrow
    {
        shared(const(ubyte)[]) track;
        track.length = bufferLength;
        memcpy(cast(void*)(track.ptr), cast(const(void)*)(buffer),
               cast(size_t)(bufferLength));

        tracks_ ~= track;

        return tracks_.length - 1;
    }

    // Do this the easy way for now. Don't try to handle simultaneous playback.
    void PlayTrack(ulong trackIndex) shared nothrow
    {
        nowPlaying_ ~= AudioTrackPosition(trackIndex, 0);
    }

    void ConsumeBuffer(ulong usedLength) shared nothrow
    {
        if (nowPlaying_.length > 0) {
            auto track = tracks_[nowPlaying_[0].trackIndex];
            core.atomic.atomicOp!"+="(nowPlaying_[0].bufferPos, usedLength);
            if (nowPlaying_[0].bufferPos >= track.length) {
                // Finished playing this track; remove it.
                nowPlaying_ = nowPlaying_[1..$];
            }
        }
    }

    shared(const(ubyte)[]) GetRemainingBuffer() shared nothrow
    {
        if (nowPlaying_.length == 0) {
            return [];
        }

        auto track = tracks_[nowPlaying_[0].trackIndex];
        return track[nowPlaying_[0].bufferPos..$];
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

    // FIXME: Magic strings still kinda bad?
    alias SoundAndFile = tuple!("expectedIndex", "filename");
    auto soundsToLoad = [
        SoundAndFile(Track.DING, cast(const char *)("sounds/ding.wav")),
        SoundAndFile(Track.DONG, cast(const char *)("sounds/dong.wav")),
        SoundAndFile(Track.DANG, cast(const char *)("sounds/dang.wav"))
    ];

    foreach (sound; soundsToLoad) {
        if (SDL_LoadWAV(sound.filename, &audioSpec,
                        &myAudioBuffer, &myAudioBufferLength) is null) {
            printf(`ERROR: Failed to open audio file "%s": %s\n`,
                   sound.filename, SDL_GetError());
            // FIXME: Raise exception here.
            return;
        }

        if (audioManager.AddTrack(myAudioBuffer, myAudioBufferLength) !=
                sound.expectedIndex) {
            writefln("ERROR: Audio files loaded in wrong order.");
            assert(false);
        }

        SDL_FreeWAV(cast(ubyte*) myAudioBuffer);
    }

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
        debug writefln("Ding: Bounced off of left paddle.");
        PlaySound(Track.DING);
    }
    else if (eventInfo == NotifyType.BALL_BOUNCE_RIGHT_PADDLE) {
        debug writefln("Dong: Bounced off of right paddle.");
        PlaySound(Track.DONG);
    }
}

void HitWall(NotifyType eventInfo)
{
    if (eventInfo == NotifyType.BALL_BOUNCE_BOTTOM_WALL) {
        debug writefln("Dang: Bounced off of bottom wall.");
        PlaySound(Track.DANG);
    }
    else if (eventInfo == NotifyType.BALL_BOUNCE_TOP_WALL) {
        debug writefln("Dang: Bounced off of top wall.");
        PlaySound(Track.DANG);
    }

}


private void PlaySound(ulong trackIndex)
{
    SDL_LockAudioDevice(audioDeviceId);
    audioManager.PlayTrack(trackIndex);
    SDL_UnlockAudioDevice(audioDeviceId);
}


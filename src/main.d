import std.conv;
import std.stdio;

import core.time;
import core.thread;
import core.atomic;

import derelict.sdl2.sdl;
import derelict.sdl2.mixer;

import gamestate;
import control;
import physics;
import graphics;
import observer;
import sound;

bool function(Duration elapsedTime) currentStage = &MainMenuFrame;

// variable declarations
shared ubyte *audio_pos; // global pointer to the audio buffer to be played
shared uint audio_len; // remaining length of the sample we have to play
shared SDL_AudioFormat actualFormat;

void main()
{
    // Current code stolen from
    //     https://gist.github.com/armornick/3447121

    DerelictSDL2.load();
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);

    // local variables
    uint wav_length; // length of our sample
    ubyte *wav_buffer; // buffer containing our audio file
    SDL_AudioSpec wav_spec; // the specs of our piece of music

    writefln("Starting.");

    /* Load the WAV */
    // the specs, length and buffer of our wav are filled
    if( SDL_LoadWAV("sounds/ding.wav", &wav_spec, &wav_buffer, &wav_length) is null ){
        writefln("Failed to load WAV.");
        return;
    }
    writefln("Loaded WAV.");
    // set the callback function
    wav_spec.callback = &my_audio_callback;
    wav_spec.userdata = null;
    // set our global static variables
    audio_pos = cast(shared ubyte*)(wav_buffer); // copy sound buffer
    audio_len = cast(shared uint)(wav_length); // copy file length

    /* Open the audio device */
    SDL_AudioSpec actualSpec;
    SDL_AudioDeviceID devId = SDL_OpenAudioDevice(null, false, &wav_spec, &actualSpec, SDL_AUDIO_ALLOW_ANY_CHANGE);
    if (devId <= 0){
        printf("Couldn't open audio: %s\n", SDL_GetError());
        return;
    }
    writefln("Opened audio.");

    actualFormat = actualSpec.format;

    /* Start playing */
    SDL_PauseAudioDevice(devId, 0);
    writefln("Unpaused audio.");

    // wait until we're done playing
    while ( audio_len > 0 ) {
        writefln("Playing audio...");
        SDL_Delay(100);
    }

    writefln("Okay, we should be done here.");

    // shut everything down
    SDL_CloseAudio();
    SDL_FreeWAV(wav_buffer);



///////////////////////////////////////////////////////////////////////////////
version (UseSDLMixer) {
    InitGraphics();
    scope (exit) CleanupGraphics();

    InitSound();
    scope (exit) CleanupSound();

    InitGameState();
    InitObservers();

    int audio_rate = 22050;
    Uint16 audio_format = AUDIO_S16SYS;
    int audio_channels = 2;
    int audio_buffers = 4096;

    writefln("test 1");

    if(Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers) != 0) {
        printf("Unable to initialize audio: %s\n", Mix_GetError());
        return;
    }

    writefln("test 2");

    Mix_Chunk *sound = Mix_LoadWAV("sounds/ding.wav");
    if (sound is null) {
        printf("Unable to load WAV file: %s\n", Mix_GetError());
        return;
    }

    writefln("test 3");

    int channel = Mix_PlayChannel(-1, sound, 0);
    if(channel == -1) {
        printf("Unable to play WAV file: %s\n", Mix_GetError());
    }

    writefln("test 4");

    while (Mix_Playing(channel) != 0) {}
    Mix_FreeChunk(sound);
    Mix_CloseAudio();
}
///////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////
version(TryItOurselves) {
    SDL_AudioSpec fileSpec = {
        freq:     48000,
        format:   AUDIO_F32,
        channels: 2,
        samples:  4096,
        callback: &MyAudioCallback
    };
    SDL_AudioSpec actualSpec;
    SDL_AudioDeviceID theDevice = SDL_OpenAudioDevice(null, 0,
        &fileSpec, &actualSpec, SDL_AUDIO_ALLOW_ANY_CHANGE);
    if (theDevice == 0) {
        printf("Failed to open audio device: %s\n", SDL_GetError());
    }
    ubyte *theBuf;
    uint   bufLen;
    if (SDL_LoadWAV("sounds/ding.wav", &fileSpec, &theBuf, &bufLen) is null) {
        writefln("Failed to open wav file: %s\n", SDL_GetError());
    }
    // writef("Contents of buffer: [");
    // for (int i=0; i < bufLen; i++) {
    //     writef("%d, ", theBuf[i]);
    // }
    // writefln("]");
    writefln("device: %s, buf: %s, bufLen: %s", theDevice, theBuf, bufLen);
    // writefln("Okay, gonna try queuing.");
    // SDL_QueueAudio(theDevice, theBuf, bufLen);
    // writefln("Queued.");
    writefln("Okay, gonna try playing.");
    SDL_PauseAudioDevice(theDevice, 0);
    writefln("Unpaused.");
    SDL_Delay(5000);
    SDL_FreeWAV(theBuf);
}
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
// Disable this for now because it might mess with the audio code.
version (none) {
    // The time at which the previous iteration of the event loop began.
    MonoTime prevStartTime = MonoTime.currTime;

    // FIXME: Magic number bad.
    int frameRate = 20;
    Duration frameLength = dur!"seconds"(1) / frameRate;

    // Run the main game loop.
    while (true)
    {
        // Get the time at which this iteration of the event loop begins.
        MonoTime currStartTime = MonoTime.currTime;

        // Carry out one frame of the game or current menu.
        if (currentStage(currStartTime - prevStartTime)) {
            break;
        }

        prevStartTime = currStartTime;

        // Sleep for the rest of the frame, unless we've taken too much time
        // already.
        Duration timeToSleep = frameLength -
                               (MonoTime.currTime - currStartTime);
        if (!timeToSleep.isNegative)
            Thread.sleep(timeToSleep);
    }
}
///////////////////////////////////////////////////////////////////////////////

}


// FIXME: These should probably go in another file somewhere. Along with
// currentStage.

bool GameFrame(Duration elapsedTime)
{
    if (HandleEvents()) {
        return true;
    }

    // Update the game state, based on the amount of time elapsed since
    // the previous event loop iteration.
    UpdateWorld(elapsedTime);

    // Draw the current game state.
    RenderGame();

    return false;
}

bool MainMenuFrame(Duration elapsedTime)
{
    SDL_Event event;

    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            return true;
        }
        if (event.type == SDL_KEYDOWN) {
            if (event.key.keysym.sym == SDLK_p) {
                currentStage = &GameFrame;
                break;
            }
            else if (event.key.keysym.sym == SDLK_s) {
                currentStage = &SettingsFrame;
                break;
            }
        }
    }

    RenderMainMenu();

    return false;
}

bool SettingsFrame(Duration elapsedTime)
{
    SDL_Event event;

    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            return true;
        }
        if (event.type == SDL_KEYDOWN) {
            if (event.key.keysym.sym == SDLK_m) {
                currentStage = &MainMenuFrame;
                break;
            }
        }
    }

    RenderSettingsMenu();

    return false;
}

extern (C) void MyAudioCallback(void* userdata, ubyte* stream, int len) nothrow
{
    for (int i=0; i<len; i++) {
        if (i % 8192 < 4096) {
            stream[i] = 0;
        }
        else {
            stream[i] = 255;
        }
    }
    // try {
    //     writefln("Enter callback.");
    // } catch { /* Quack. */ }
    // for (int i=0; i<len; i++) {
    //     stream[i] = 0;
    // }
    // try {
    //     writefln("Leave callback.");
    // } catch { /* Quack. */ }
}


// audio callback function
// here you have to copy the data of your audio buffer into the
// requesting audio buffer (stream)
// you should only copy as much as the requested length (len)
extern (C) void my_audio_callback(void *userdata, ubyte *stream, int len) nothrow {
    try {
        writefln("Callback. len=%s, audio_len=%s", len, audio_len);
    } catch {}

    // if (audio_len ==0)
    //     return;

    int neededLen = ( len > audio_len ? audio_len : len );
    try {
        writefln("    stream=%s, audio_pos=%s, len=%s", stream, audio_pos, len);
    } catch {}
    memcpy(cast(void*)(stream), cast(const(void)*)(audio_pos), neededLen);
    //SDL_MixAudioFormat(stream, cast(ubyte*)(audio_pos), actualFormat, neededLen, SDL_MIX_MAXVOLUME);// mix from one buffer into another
    if (neededLen < len) {
        memset(cast(void*)(stream + neededLen), 0, len - neededLen);
        try {
            writefln("    memsetting");
        } catch {}
    }

    core.atomic.atomicOp!"+="(audio_pos, neededLen);
    core.atomic.atomicOp!"-="(audio_len, neededLen);
}

// Does this work???
extern (C) void * memset(void *s, int c, size_t n) nothrow;
extern (C) void * memcpy(void *dest, const(void)* src, size_t n) nothrow;


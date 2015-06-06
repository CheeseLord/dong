import std.stdio;
import derelict.sdl2.sdl;

int main()
{
    DerelictSDL2.load();

    SDL_Window *window;

    debug writefln("1");

    SDL_Init(SDL_INIT_VIDEO);

    debug writefln("2");

    window = SDL_CreateWindow("Dong", SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED, 640, 480, SDL_WINDOW_OPENGL);

    debug writefln("3");

    if (window == null) {
        writefln("Oh noes! Failed to create window.");
        return 1;
    }

    debug writefln("4");

    SDL_Delay(3000);

    debug writefln("5");

    SDL_DestroyWindow(window);

    debug writefln("6");

    SDL_Quit();

    debug writefln("7");

    return 0;
}


import std.stdio;
import std.string;
import std.conv;

// For drawing.
import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

// We need to read entities' states to draw them.
import gamestate;
import entity;
import worldgeometry;
import score;

private SDL_Window  *window  = null;
private SDL_Surface *surface = null;

private TTF_Font *font;

private SDL_Surface *leftScore = null;
private SDL_Surface *rightScore;

private ScreenRect sWorldRect;

void InitGraphics()
{
    // Set up SDL and TTF.
    DerelictSDL2.load();
    SDL_Init(SDL_INIT_VIDEO);
    DerelictSDL2ttf.load();
    TTF_Init();

    // Try creating a window.
    // FIXME: Remove magic numbers.
    window = SDL_CreateWindow("Dong",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        640, 480, SDL_WINDOW_OPENGL);

    // FIXME: Raise exception here. Above, do a
    // scope (failure) SDL_Quit()..
    if (window == null) {
        writefln("Error: failed to create window.");
        return;
    }

    // FIXME: scope (failure) SDL_DestroyWindow(window);

    // Create a surface and paint it black.
    surface = SDL_GetWindowSurface(window);
    SDL_FillRect(surface, null, SDL_MapRGB(surface.format, 0, 0, 0));

    // FIXME: This will eventually be not the entire screen.
    sWorldRect = ScreenRect(
        cast(int) 0,         // x
        cast(int) 0,         // y
        cast(int) surface.w, // w
        cast(int) surface.h  // h
    );

    // Set up the font.
    // TODO: Get default fonts.
    font = TTF_OpenFont("fonts/UbuntuMono-B.ttf", 96);
}

void CleanupGraphics()
{
    if (window != null) {
        SDL_DestroyWindow(window);
    }

    writefln("Exiting.");
    TTF_Quit();
    SDL_Quit();
}

void RenderGame()
{
    SDL_FillRect(surface, null, SDL_MapRGB(surface.format, 0, 0, 0));

    RenderScores();

    foreach (Entity entity; gameState.entities) {
        ScreenRect sEntityRect = WorldToScreenRect(entity.wRect, sWorldRect);

        SDL_FillRect(surface, &sEntityRect,
                     SDL_MapRGB(surface.format, 0, 191, 0));
    }

    // Update the window to actually display the newly drawn game state.
    SDL_UpdateWindowSurface(window);
}

void RenderScores()
{
    SDL_Color scoreColor = {255, 255, 255};
    leftScore  = TTF_RenderText_Solid(font, to!string(scores.left).toStringz,
                                     scoreColor);
    rightScore = TTF_RenderText_Solid(font, to!string(scores.right).toStringz,
                                     scoreColor);
    // FIXME: Actually display.

    debug writefln("leftScore is %s, rightScore is %s", leftScore, rightScore);
    SDL_Rect tmp = {x:50, y:50, w:0, h:0}; // FIXME
    SDL_BlitSurface(leftScore, null, surface, &tmp);
}


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

private TTF_Font *scoreFont;
private TTF_Font *menuFont;

private SDL_Surface *leftScore = null;
private SDL_Surface *rightScore;

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

    // Set up the fonts.
    // TODO: Get default fonts.
    scoreFont = TTF_OpenFont("fonts/UbuntuMono-B.ttf", 72);
    menuFont  = TTF_OpenFont("fonts/UbuntuMono-B.ttf", 24);
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
        ScreenRect sEntityRect = WorldToScreenRect(entity.wRect);

        SDL_FillRect(surface, &sEntityRect,
                     SDL_MapRGB(surface.format, 0, 191, 0));
    }

    // Update the window to actually display the newly drawn game state.
    SDL_UpdateWindowSurface(window);
}

private void RenderScores()
{
    SDL_Color scoreColor = {0, 50, 255};
    leftScore  = TTF_RenderText_Solid(scoreFont,
                                      toStringz(to!string(scores.left )),
                                      scoreColor);
    rightScore = TTF_RenderText_Solid(scoreFont,
                                      toStringz(to!string(scores.right)),
                                      scoreColor);

    int offset = 200;
    SDL_Rect leftPosition  = {x:offset - leftScore.w, y:50};
    SDL_Rect rightPosition = {x:surface.w - offset, y:50};

    SDL_BlitSurface(leftScore,  null, surface, &leftPosition );
    SDL_BlitSurface(rightScore, null, surface, &rightPosition);
}

void RenderMainMenu()
{
    SDL_Color textColor = {255, 255, 255};

    SDL_FillRect(surface, null, SDL_MapRGB(surface.format, 0, 0, 0));

    SDL_Surface *textSurf1 = TTF_RenderText_Solid(menuFont,
        "Press 'p' to begin playing.", textColor);
    SDL_Surface *textSurf2 = TTF_RenderText_Solid(menuFont,
        "Press 's' for settings.", textColor);

    // FIXME: Magic numbers bad.
    SDL_Rect position = {x:50, y:50};
    SDL_BlitSurface(textSurf1, null, surface, &position);

    // Add a little padding. FIXME: Magic numbers still bad.
    position.y += textSurf1.h + 8;
    SDL_BlitSurface(textSurf2, null, surface, &position);

    SDL_UpdateWindowSurface(window);
}

void RenderSettingsMenu()
{
    SDL_Color textColor = {0, 0, 0};

    SDL_FillRect(surface, null, SDL_MapRGB(surface.format, 191, 191, 191));

    SDL_Surface *textSurf = TTF_RenderText_Solid(menuFont,
        "Press 'm' to return to main menu.", textColor);

    // FIXME: Magic numbers bad.
    SDL_Rect position = {x:50, y:50};
    SDL_BlitSurface(textSurf, null, surface, &position);

    SDL_UpdateWindowSurface(window);
}


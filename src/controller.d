import std.stdio;

// For event handling.
import derelict.sdl2.sdl;

// We need to access entities' states to control them.
import gamestate;
import entity;

/**
 * Returns true if we should exit, false if we should keep going.
 */
bool HandleEvents()
{
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        debug writefln("Got an event. Type = %s (%s)", event.type,
            GetEventTypeName(event.type));
        if (event.type == SDL_QUIT) {
            return true;
        }
    }

    return false;
}

string GetEventTypeName(uint eventType)
{
    switch(eventType) {
        case SDL_QUIT:              return "quit";
        case SDL_KEYDOWN:           return "key down";
        case SDL_KEYUP:             return "key up";
        case SDL_TEXTEDITING:       return "text editing";
        case SDL_TEXTINPUT:         return "text input";
        case SDL_MOUSEMOTION:       return "mouse motion";
        case SDL_MOUSEBUTTONDOWN:   return "mouse button down";
        case SDL_MOUSEBUTTONUP:     return "mouse button up";
        case SDL_MOUSEWHEEL:        return "mouse wheel";
        default:                    return "<something else>";
    }
}


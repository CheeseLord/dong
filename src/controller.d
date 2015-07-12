import std.stdio;

// For event handling.
import derelict.sdl2.sdl;

// We need to access entities' states to control them.
import gamestate;
import entity;

enum MoveDirection {NO_MOVE, LEFT, UP, RIGHT, DOWN}

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
        else {
            foreach (Entity entity; gameState.entities) {
                entity.HandleEvent(event);
            }
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

class ControlComponent {
    private Entity parent_;

    this(Entity parent)
    {
        parent_ = parent;
    }

    void HandleEvent(SDL_Event event)
    {
        // By default, ignore events.
        debug (ShowEntityEvent) {
            writefln("Entity at (%f, %f) got an event. Type = %s (%s)",
            parent_.x, parent_.y,
            event.type, GetEventTypeName(event.type));
        }
    }

    void Update(double elapsedTime)
    {
        // By default, don't modify anything.
    }
}

class KeyControlComponent : ControlComponent {
    // TODO: Support left and right.
    private SDL_Scancode upKey_, downKey_;
    private MoveDirection currDirection_;

    this(Entity parent)
    {
        this(parent, SDL_SCANCODE_UP, SDL_SCANCODE_DOWN);
    }

    this(Entity parent, SDL_Scancode upKey, SDL_Scancode downKey)
    {
        super(parent);
        upKey_ = upKey;
        downKey_ = downKey;
        currDirection_ = MoveDirection.NO_MOVE;
        debug writefln("Constructing a KeyControlComponent.");
    }

    override void HandleEvent(SDL_Event event)
    {
        if (event.key.keysym.scancode == upKey_) {
            debug writefln("Moving up.");
            currDirection_ = MoveDirection.UP;
        }
        if (event.key.keysym.scancode == downKey_) {
            debug writefln("Moving down.");
            currDirection_ = MoveDirection.DOWN;
        }
    }

    override void Update(double elapsedTime)
    {
        if (currDirection_ == MoveDirection.NO_MOVE) {
            parent_.yVel = 0;
        }
        else if (currDirection_ == MoveDirection.UP) {
            parent_.yVel = -float.infinity;
        }
        else if (currDirection_ == MoveDirection.DOWN) {
            parent_.yVel = float.infinity;
        }
        else {
            // TODO: Support horizontal paddles.
        }
        currDirection_ = MoveDirection.NO_MOVE;
    }
}


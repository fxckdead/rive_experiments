#define SDL_MAIN_USE_CALLBACKS 1  /* use the callbacks instead of main() */

#include <glad/glad.h>
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cmath>

#include <rive/artboard.hpp>
#include <rive/math/vec2d.hpp>

/* We will use this renderer to draw into this window every frame. */
static SDL_Window *window = nullptr;
static SDL_GLContext glContext = nullptr;
static bool isPaused = false;

/* This function runs once at startup. */
SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
{
    (void)appstate;  // Suppress unused parameter warning
    (void)argc;      // Suppress unused parameter warning
    (void)argv;      // Suppress unused parameter warning
    
    SDL_SetAppMetadata("SDL3 OpenGL Example", "1.0", "cl.staytrue.rive");

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    window = SDL_CreateWindow("SDL3 + OpenGL", 640, 480, SDL_WINDOW_OPENGL);
    if (!window) {
        SDL_Log("Couldn't create window: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    glContext = SDL_GL_CreateContext(window);
    if (!glContext) {
        SDL_Log("Couldn't create OpenGL context: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    // Initialize GLAD with the loader function
#if defined(__ANDROID__) || defined(__IPHONEOS__) || defined(__EMSCRIPTEN__)
    // Use OpenGL ES on mobile platforms and WebAssembly - for now use desktop GL
    if (!gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress)) {
        SDL_Log("Failed to initialize GLAD (OpenGL)");
        return SDL_APP_FAILURE;
    }
#else
    // Use desktop OpenGL on other platforms  
    if (!gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress)) {
        SDL_Log("Failed to initialize GLAD (OpenGL)");
        return SDL_APP_FAILURE;
    }
#endif

    SDL_Log("OpenGL Version: %s", glGetString(GL_VERSION));
    SDL_Log("OpenGL Renderer: %s", glGetString(GL_RENDERER));
    
    glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
    return SDL_APP_CONTINUE;
}

/* This function runs when a new event (mouse input, keypresses, etc) occurs. */
SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
    (void)appstate;  // Suppress unused parameter warning
    
    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;  /* end the program, reporting success to the OS. */
    }
    return SDL_APP_CONTINUE;  /* carry on with the program! */
}

/* This function runs once per frame, and is the heart of the program. */
SDL_AppResult SDL_AppIterate(void *appstate)
{
    (void)appstate;  // Suppress unused parameter warning
    
    if (!isPaused) {
        const double now = ((double)SDL_GetTicks()) / 1000.0;  /* convert from milliseconds to seconds. */
        /* choose the color for the frame we will draw. The sine wave trick makes it fade between colors smoothly. */
        const float red = (float) (0.5 + 0.5 * SDL_sin(now));
        const float green = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 2 / 3));
        const float blue = (float) (0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 4 / 3));

        glClearColor(red, green, blue, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        SDL_GL_SwapWindow(window);
    }
    return SDL_APP_CONTINUE;
}

/* This function runs once at shutdown. */
void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
    (void)appstate;  // Suppress unused parameter warning
    (void)result;    // Suppress unused parameter warning
    
    if (glContext) {
        SDL_GL_DestroyContext(glContext);
        glContext = nullptr;
    }
    if (window) {
        SDL_DestroyWindow(window);
        window = nullptr;
    }
    SDL_Quit();
}

#ifdef PLATFORM_WEB
#include <emscripten.h>

/* Export functions for JavaScript to call */
extern "C" {
    EMSCRIPTEN_KEEPALIVE void toggle_pause() {
        isPaused = !isPaused;
    }
    
    EMSCRIPTEN_KEEPALIVE int get_pause_state() {
        return isPaused ? 1 : 0;
    }
}
#endif

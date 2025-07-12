#include "opengl_backend.hpp"

#ifndef __APPLE__
OpenGLBackend::~OpenGLBackend()
{
    shutdown();
}

bool OpenGLBackend::initialize(void* windowPtr, int width, int height)
{
    if (m_initialized)
    {
        return true;
    }

    m_window = static_cast<SDL_Window*>(windowPtr);
    m_windowWidth = width;
    m_windowHeight = height;

    // Set OpenGL attributes
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

    // Create OpenGL context
    m_glContext = SDL_GL_CreateContext(m_window);
    if (!m_glContext)
    {
        SDL_Log("Failed to create OpenGL context: %s", SDL_GetError());
        return false;
    }

    // Enable VSync
    SDL_GL_SetSwapInterval(1);

    // Initialize GLAD
#if defined(__ANDROID__) || defined(__EMSCRIPTEN__)
    if (!gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress))
    {
        SDL_Log("Failed to initialize GLAD (OpenGL)");
        return false;
    }
#else
    if (!gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress))
    {
        SDL_Log("Failed to initialize GLAD (OpenGL)");
        return false;
    }
#endif

    SDL_Log("OpenGL Version: %s", glGetString(GL_VERSION));
    SDL_Log("OpenGL Renderer: %s", glGetString(GL_RENDERER));

    // Initialize OpenGL state
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0.2f, 0.2f, 0.2f, 1.0f);

    // Create the render context
    m_renderContext = rive::gpu::RenderContextGLImpl::MakeContext();
    if (!m_renderContext)
    {
        SDL_Log("Failed to create OpenGL render context");
        return false;
    }

    m_initialized = true;
    return true;
}

void OpenGLBackend::shutdown()
{
    // Clean up render context first
    m_renderContext.reset();

    if (m_glContext)
    {
        SDL_GL_DestroyContext(m_glContext);
        m_glContext = nullptr;
    }

    m_initialized = false;
}

void OpenGLBackend::beginFrame()
{
    // Clear the screen
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    // Set up the viewport
    glViewport(0, 0, m_windowWidth, m_windowHeight);
}

void OpenGLBackend::endFrame()
{
    // Swap buffers
    SDL_GL_SwapWindow(m_window);
}

void OpenGLBackend::resize(int width, int height)
{
    m_windowWidth = width;
    m_windowHeight = height;

    if (m_initialized)
    {
        glViewport(0, 0, width, height);
    }
}

std::unique_ptr<rive::Renderer> OpenGLBackend::createRenderer()
{
    return std::make_unique<rive::RiveRenderer>(m_renderContext.get());
}

rive::Factory* OpenGLBackend::createFactory()
{
    // Return the render context as a Factory (it implements the Factory interface)
    return m_renderContext.get();
}

rive::gpu::RenderContext* OpenGLBackend::getRenderContext()
{
    return m_renderContext.get();
}

void* OpenGLBackend::getNativeHandle()
{
    // For OpenGL, we don't need a specific handle for rendering
    // The render context manages the OpenGL state internally
    return nullptr;
}

#endif

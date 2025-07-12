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

    // Set OpenGL attributes (platform-specific)
#ifdef PLATFORM_WEB
    // WebGL 2.0 context (equivalent to OpenGL ES 3.0)
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
#else
    // Desktop OpenGL 4.6 context
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 6);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
#endif
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

    // Initialize OpenGL loader (platform-specific)
#ifdef PLATFORM_WEB
    SDL_Log("WebGL context created successfully");
#else
    if (!gladLoadCustomLoader((GLADloadproc)SDL_GL_GetProcAddress))
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
    // Flush GPU commands before swapping buffers
    rive::gpu::RenderContext::FlushResources flushResources;
    flushResources.renderTarget = getRenderTarget();
    m_renderContext->flush(flushResources);
    
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
        
        // Recreate render target with new dimensions
        m_renderTarget = std::make_unique<rive::gpu::FramebufferRenderTargetGL>(
            width, height, 0, 1); // FBO 0, no MSAA
    }
}

std::unique_ptr<rive::Renderer> OpenGLBackend::createRenderer()
{
    return std::make_unique<rive::RiveRenderer>(m_renderContext.get());
}

rive::Factory* OpenGLBackend::createFactory()
{
    return m_renderContext.get();
}

rive::gpu::RenderContext* OpenGLBackend::getRenderContext()
{
    return m_renderContext.get();
}

rive::gpu::RenderTarget* OpenGLBackend::getRenderTarget()
{
    if (!m_renderTarget) {
        m_renderTarget = std::make_unique<rive::gpu::FramebufferRenderTargetGL>(
            m_windowWidth, m_windowHeight, 0, 1); // FBO 0, no MSAA
    }
    return m_renderTarget.get();
}

void* OpenGLBackend::getNativeHandle()
{
    return nullptr;
}

#endif // __APPLE__

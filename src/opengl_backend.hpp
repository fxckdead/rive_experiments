#pragma once

#include "graphics_backend.hpp"

#ifndef __APPLE__

// Platform-specific includes
#ifdef PLATFORM_WEB
    // Web/Emscripten includes - use WebGL (OpenGL ES)
    #include <SDL3/SDL.h>
    #include <GLES3/gl3.h>
#else
    // Desktop platforms (Windows, Linux) - use desktop OpenGL with GLAD
    #include <SDL3/SDL.h>
    #include <glad/glad.h>
#endif

#include <rive/renderer/gl/render_context_gl_impl.hpp>
#include <rive/renderer/gl/render_target_gl.hpp>

class OpenGLBackend : public GraphicsBackendInterface {
public:
  OpenGLBackend() = default;
  ~OpenGLBackend() override;

  bool initialize(void *windowPtr, int width, int height) override;
  void shutdown() override;
  void beginFrame() override;
  void endFrame() override;
  void resize(int width, int height) override;

  std::unique_ptr<rive::Renderer> createRenderer() override;
  rive::Factory *createFactory() override;
  rive::gpu::RenderContext *getRenderContext() override;
  rive::gpu::RenderTarget *getRenderTarget() override;
  void *getNativeHandle() override;

  GraphicsBackend getBackendType() const override {
    return GraphicsBackend::OpenGL;
  }
  
  std::string getBackendName() const override { 
#ifdef PLATFORM_WEB
    return "WebGL";
#else
    return "OpenGL";
#endif
  }

private:
  SDL_Window *m_window = nullptr;
  SDL_GLContext m_glContext = nullptr;
  std::unique_ptr<rive::gpu::RenderContext> m_renderContext;
  std::unique_ptr<rive::gpu::RenderTarget> m_renderTarget;
  int m_windowWidth = 0;
  int m_windowHeight = 0;
  bool m_initialized = false;
};

#endif // __APPLE__

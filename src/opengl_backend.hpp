#pragma once

#include "graphics_backend.hpp"

#ifndef __APPLE__
#include <SDL3/SDL.h>

#include <glad/glad.h>

#include <rive/renderer/gl/render_context_gl_impl.hpp>
#include <rive/renderer/gl/gl_renderer.hpp>

class OpenGLBackend : public GraphicsBackendInterface {
public:
    OpenGLBackend() = default;
    ~OpenGLBackend() override;

    bool initialize(void* windowPtr, int width, int height) override;
    void shutdown() override;
    void beginFrame() override;
    void endFrame() override;
    void resize(int width, int height) override;

    std::unique_ptr<rive::Renderer> createRenderer() override;
    rive::Factory* createFactory() override;
    rive::gpu::RenderContext* getRenderContext() override;
    void* getNativeHandle() override;

    GraphicsBackend getBackendType() const override { return GraphicsBackend::OpenGL; }
    std::string getBackendName() const override { return "OpenGL"; }

private:
    SDL_Window* m_window = nullptr;
    SDL_GLContext m_glContext = nullptr;
    std::unique_ptr<rive::gpu::RenderContext> m_renderContext;
    int m_windowWidth = 0;
    int m_windowHeight = 0;
    bool m_initialized = false;
};

#endif

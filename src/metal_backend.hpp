#pragma once

#include "graphics_backend.hpp"

#ifdef __APPLE__
#include <SDL3/SDL.h>
#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.h>
#include <rive/renderer/metal/render_context_metal_impl.h>
#include <rive/renderer/rive_renderer.hpp>

class MetalBackend : public GraphicsBackendInterface {
public:
    MetalBackend() = default;
    ~MetalBackend() override;

    bool initialize(void* windowPtr, int width, int height) override;
    void shutdown() override;
    void beginFrame() override;
    void endFrame() override;
    void resize(int width, int height) override;

    std::unique_ptr<rive::Renderer> createRenderer() override;
    rive::Factory* createFactory() override;
    rive::gpu::RenderContext* getRenderContext() override;
    void* getNativeHandle() override;

    GraphicsBackend getBackendType() const override { return GraphicsBackend::Metal; }
    std::string getBackendName() const override { return "Metal"; }

private:
    bool setupMetalLayer();
    void cleanupMetalLayer();

    SDL_Window* window = nullptr;
    id<MTLDevice> device = nullptr;
    id<MTLCommandQueue> commandQueue = nullptr;
    CAMetalLayer* metalLayer = nullptr;
    id<CAMetalDrawable> currentDrawable = nullptr;
    CAMetalLayer* swapchain = nullptr;
    std::unique_ptr<rive::gpu::RenderContext> renderContext;
    rive::rcp<rive::gpu::RenderTargetMetal> renderTarget;
    int windowWidth = 0;
    int windowHeight = 0;
    bool initialized = false;
};

#endif // __APPLE__

#pragma once

#include <memory>
#include <string>

#include <rive/renderer/render_context.hpp>
#include <rive/renderer/rive_renderer.hpp>
#include <rive/factory.hpp>

// Graphics backend enumeration
enum class GraphicsBackend {
    OpenGL,
    Metal
};

// Graphics backend interface
class GraphicsBackendInterface {
public:
    virtual ~GraphicsBackendInterface() = default;

    virtual bool initialize(void* windowPtr, int width, int height) = 0;
    virtual void shutdown() = 0;
    virtual void beginFrame() = 0;
    virtual void endFrame() = 0;
    virtual void resize(int width, int height) = 0;

    virtual std::unique_ptr<rive::Renderer> createRenderer() = 0;
    virtual rive::Factory* createFactory() = 0;
    virtual rive::gpu::RenderContext* getRenderContext() = 0;
    virtual void* getNativeHandle() = 0;

    virtual GraphicsBackend getBackendType() const = 0;
    virtual std::string getBackendName() const = 0;
};

// Factory function
std::unique_ptr<GraphicsBackendInterface> createGraphicsBackend(GraphicsBackend backend);

// Helper function to detect best backend for current platform
GraphicsBackend detectBestBackend();

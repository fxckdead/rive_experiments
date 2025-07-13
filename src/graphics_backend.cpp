#include "graphics_backend.hpp"

#ifdef __APPLE__
#include "metal_backend.hpp"
#else
#include "opengl_backend.hpp"
#endif

#include <iostream>

std::unique_ptr<GraphicsBackendInterface> createGraphicsBackend(GraphicsBackend backend) {
    switch (backend) {
        case GraphicsBackend::OpenGL:
#ifndef __APPLE__
            return std::make_unique<OpenGLBackend>();
#else
            std::cerr << "OpenGL backend is only available on non-Apple platforms" << std::endl;
            return nullptr;
#endif

        case GraphicsBackend::Metal:
#ifdef __APPLE__
            return std::make_unique<MetalBackend>();
#else
            std::cerr << "Metal backend is only available on Apple platforms" << std::endl;
            return nullptr;
#endif

        default:
            std::cerr << "Unknown graphics backend" << std::endl;
            return nullptr;
    }
}

GraphicsBackend detectBestBackend() {
#ifdef __APPLE__
    // On macOS, prefer Metal over OpenGL for better performance
    return GraphicsBackend::Metal;
#else
    // On other platforms, use OpenGL
    return GraphicsBackend::OpenGL;
#endif
}

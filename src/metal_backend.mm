#include "metal_backend.hpp"

#ifdef __APPLE__
#include <SDL3/SDL.h>

#include <iostream>

#import <Cocoa/Cocoa.h>

MetalBackend::~MetalBackend()
{
    shutdown();
}

bool MetalBackend::initialize(void* windowPtr, int width, int height)
{
    if (initialized)
    {
        return true;
    }

    window = static_cast<SDL_Window*>(windowPtr);
    windowWidth = width;
    windowHeight = height;

    // Get the default Metal device
    device = MTLCreateSystemDefaultDevice();
    if (!device)
    {
        SDL_Log("Failed to create Metal device");
        return false;
    }

    // Create command queue
    commandQueue = [device newCommandQueue];
    if (!commandQueue)
    {
        SDL_Log("Failed to create Metal command queue");
        return false;
    }

    // Create the render context
    renderContext = rive::gpu::RenderContextMetalImpl::MakeContext(device);
    if (!renderContext)
    {
        SDL_Log("Failed to create Metal render context");
        return false;
    }

    // Set up Metal layer
    if (!setupMetalLayer())
    {
        SDL_Log("Failed to set up Metal layer");
        return false;
    }

    SDL_Log("Metal Device: %s", [device.name UTF8String]);

    initialized = true;
    return true;
}

void MetalBackend::shutdown() {
    // Clean up render context first
    renderContext.reset();

    cleanupMetalLayer();

    if (commandQueue)
    {
        [commandQueue release];
        commandQueue = nullptr;
    }

    if (device)
    {
        [device release];
        device = nullptr;
    }

    initialized = false;
}

void MetalBackend::beginFrame()
{
    if (!initialized || !metalLayer)
    {
        return;
    }

    // Get the next drawable
    currentDrawable = [metalLayer nextDrawable];
    if (!currentDrawable)
    {
        SDL_Log("Failed to get Metal drawable");
        return;
    }

    // Update render target if needed
    if (renderTarget)
    {
        renderTarget->setTargetTexture(currentDrawable.texture);
    }
}

void MetalBackend::endFrame()
{
    if (!initialized)
    {
        return;
    }

    if (currentDrawable == nil)
    {
        currentDrawable = [swapchain nextDrawable];
        assert(currentDrawable.texture.width == renderTarget->width());
        assert(currentDrawable.texture.height == renderTarget->height());
        renderTarget->setTargetTexture(currentDrawable.texture);
    }

    // Present the drawable
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    renderContext->flush({
        .renderTarget = renderTarget.get(),
        .externalCommandBuffer = (__bridge void*)commandBuffer,
    });

    [commandBuffer presentDrawable:currentDrawable];
    [commandBuffer commit];

    currentDrawable = nullptr;
}

void MetalBackend::resize(int width, int height)
{
    windowWidth = width;
    windowHeight = height;

    if (initialized && metalLayer)
    {
        metalLayer.drawableSize = CGSizeMake(width, height);

        // Recreate render target with new size
        if (renderTarget)
        {
            // The render target will be recreated when needed
            renderTarget.reset();
        }
    }

    SDL_PropertiesID windowProps = SDL_GetWindowProperties(window);
    NSWindow* nsWindow = (__bridge NSWindow *)SDL_GetPointerProperty(
        windowProps,
        SDL_PROP_WINDOW_COCOA_WINDOW_POINTER,
        NULL
    );

    NSView* view = [nsWindow contentView];
    view.wantsLayer = YES;

    swapchain = [CAMetalLayer layer];
    swapchain.device = device;
    swapchain.opaque = YES;
    swapchain.pixelFormat = MTLPixelFormatBGRA8Unorm;
    swapchain.contentsScale = 2.0f;
    view.layer = swapchain;
    swapchain.drawableSize = CGSizeMake(width, height);

    auto renderContextImpl = renderContext->static_impl_cast<rive::gpu::RenderContextMetalImpl>();
    renderTarget = renderContextImpl->makeRenderTarget( MTLPixelFormatBGRA8Unorm, width, height);
}

std::unique_ptr<rive::Renderer> MetalBackend::createRenderer()
{
    return std::make_unique<rive::RiveRenderer>(renderContext.get());
}

rive::Factory* MetalBackend::createFactory()
{
    // Return the render context as a Factory (it implements the Factory interface)
    return renderContext.get();
}

rive::gpu::RenderContext* MetalBackend::getRenderContext()
{
    return renderContext.get();
}

rive::gpu::RenderTarget* MetalBackend::getRenderTarget()
{
    return renderTarget.get();
}

void* MetalBackend::getNativeHandle()
{
    // For Metal, return the current drawable (the render target)
    return (__bridge void*)currentDrawable;
}

bool MetalBackend::setupMetalLayer()
{
    if (!window)
    {
        SDL_Log("MetalBackend::setupMetalLayer - window pointer is NULL");
        return false;
    }

    SDL_PropertiesID windowProps = SDL_GetWindowProperties(window);
    if (!windowProps)
    {
        SDL_Log("MetalBackend::setupMetalLayer - failed to get window properties");
        return false;
    }

    SDL_Log("MetalBackend::setupMetalLayer - window properties ID: %u", windowProps);

    // Try to get the native window handle using SDL3's new property system
    NSWindow* nsWindow = (__bridge NSWindow *)SDL_GetPointerProperty(
        windowProps,
        SDL_PROP_WINDOW_COCOA_WINDOW_POINTER,
        NULL
    );

    if (!nsWindow)
    {
        SDL_Log("Failed to get Cocoa window from SDL3 properties");
        SDL_Log("Window properties available:");

        void* cocoaWindow = SDL_GetPointerProperty(windowProps, SDL_PROP_WINDOW_COCOA_WINDOW_POINTER, NULL);
        SDL_Log("  - SDL_PROP_WINDOW_COCOA_WINDOW_POINTER: %p", cocoaWindow);

        // Try alternative approach - force window events to be processed
        SDL_Log("Trying to pump events and re-attempt getting window...");
        SDL_PumpEvents();
        SDL_SyncWindow(window);

        // Try again after pumping events
        nsWindow = (__bridge NSWindow *)SDL_GetPointerProperty(
            windowProps,
            SDL_PROP_WINDOW_COCOA_WINDOW_POINTER,
            NULL
        );

        if (!nsWindow)
        {
            SDL_Log("Still failed to get Cocoa window after pumping events");
            return false;
        }
        else
        {
            SDL_Log("Successfully got Cocoa window after pumping events");
        }
    }

    resize(windowWidth, windowHeight);

    return true;
}

void MetalBackend::cleanupMetalLayer()
{
    if (metalLayer)
    {
        [metalLayer release];
        metalLayer = nullptr;
    }

    renderTarget.reset();
}

#endif // __APPLE__

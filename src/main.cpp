#define SDL_MAIN_USE_CALLBACKS 1 /* use the callbacks instead of main() */

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <memory>
#include <vector>

// Graphics backend abstraction
#include "graphics_backend.hpp"

// Rive includes
#include <rive/animation/linear_animation_instance.hpp>
#include <rive/artboard.hpp>
#include <rive/file.hpp>
#include <rive/math/aabb.hpp>
#include <rive/renderer/render_context.hpp>
#include <rive/renderer/rive_renderer.hpp>

#include <filesystem>

namespace {

SDL_Window *window = nullptr;
bool isPaused = false;
GraphicsBackend selectedBackend = GraphicsBackend::OpenGL;

// Graphics backend and Rive related variables
std::unique_ptr<GraphicsBackendInterface> graphicsBackend;
std::unique_ptr<rive::File> riveFile;
std::unique_ptr<rive::ArtboardInstance> artboardInstance;
std::unique_ptr<rive::LinearAnimationInstance> animationInstance;
rive::gpu::RenderContext *renderContext;
std::unique_ptr<rive::Renderer> renderer;
rive::Factory *factory;

int windowWidth = 640;
int windowHeight = 480;
float lastTime = 0.0f;

// Helper function to load file contents
std::vector<uint8_t> loadFileContents(const std::filesystem::path &filepath) {
  std::ifstream file(filepath, std::ios::binary | std::ios::ate);
  if (!file.is_open()) {
    SDL_Log("Failed to open file: %s", filepath.generic_string().c_str());
    return {};
  }

  std::streamsize size = file.tellg();
  file.seekg(0, std::ios::beg);

  std::vector<uint8_t> buffer(size);
  if (file.read(reinterpret_cast<char *>(buffer.data()), size)) {
    return buffer;
  }

  SDL_Log("Failed to read file: %s", filepath.generic_string().c_str());
  return {};
}

// Helper function to initialize Rive
bool initializeRive() {
  // Get factory from graphics backend
  factory = graphicsBackend->createFactory();
  if (!factory) {
    SDL_Log("Failed to create Rive factory");
    return false;
  }

  // Load the Rive file
#ifdef PLATFORM_WEB
  // For web builds, use the virtual filesystem path (mounted by --preload-file)
  auto fileContents = loadFileContents("/assets/rive_files/alien.riv");
#else
  // For desktop builds, use relative path from executable
  auto fileContents = loadFileContents(
      std::filesystem::path(__FILE__).parent_path().parent_path() /
      "assets/rive_files/alien.riv");
#endif
  if (fileContents.empty()) {
    SDL_Log("Failed to load Rive file");
    return false;
  }

  // Create Rive file instance with factory
  auto file = rive::File::import(
      rive::Span<const uint8_t>(fileContents.data(), fileContents.size()),
      factory);
  if (!file) {
    SDL_Log("Failed to import Rive file");
    return false;
  }

  riveFile = std::move(file);

  // Get the default artboard
  auto artboard = riveFile->artboardDefault();
  if (!artboard) {
    SDL_Log("No default artboard found");
    return false;
  }

  artboardInstance = artboard->instance();

  // Get the first animation
  if (artboard->animationCount() > 0) {
    auto animation = artboard->animation(0);
    if (animation) {
      animationInstance = std::make_unique<rive::LinearAnimationInstance>(
          animation, artboardInstance.get());
      SDL_Log("Loaded animation: %s", animation->name().c_str());
    }
  }

  // Get render context from graphics backend
  renderContext = graphicsBackend->getRenderContext();
  if (!renderContext) {
    SDL_Log("Failed to get render context from graphics backend");
    return false;
  }

  // Create renderer using the graphics backend
  renderer = graphicsBackend->createRenderer();
  if (!renderer) {
    SDL_Log("Failed to create Rive renderer");
    return false;
  }

  SDL_Log("Rive initialization successful");
  SDL_Log("Artboard size: %.2f x %.2f", artboard->width(), artboard->height());

  return true;
}

// Helper function to parse command line arguments
void parseCommandLine(int argc, char *argv[]) {
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--backend") == 0 && i + 1 < argc) {
      std::string backendName = argv[i + 1];
      if (backendName == "opengl") {
        selectedBackend = GraphicsBackend::OpenGL;
        SDL_Log("Using OpenGL backend (command line)");
      } else if (backendName == "metal") {
        selectedBackend = GraphicsBackend::Metal;
        SDL_Log("Using Metal backend (command line)");
      } else {
        SDL_Log("Unknown backend: %s, using default", backendName.c_str());
      }

      i++; // Skip the next argument as it's the backend name
    }
  }
}

} // namespace

/* This function runs once at startup. */
SDL_AppResult SDL_AppInit([[maybe_unused]] void **appstate, int argc,
                          char *argv[]) {
  SDL_SetAppMetadata("Rive SDL3 Multi-Backend Example", "1.0",
                     "cl.staytrue.rive");

  // Parse command line arguments
  parseCommandLine(argc, argv);

  // If no backend was specified, detect the best one
  if (selectedBackend == GraphicsBackend::OpenGL && argc == 1) {
    selectedBackend = detectBestBackend();
    SDL_Log("Auto-detected backend: %s",
            selectedBackend == GraphicsBackend::Metal ? "Metal" : "OpenGL");
  }

  // Create graphics backend
  graphicsBackend = createGraphicsBackend(selectedBackend);
  if (!graphicsBackend) {
    SDL_Log("Failed to create graphics backend");
    return SDL_APP_FAILURE;
  }

  SDL_Log("Using %s backend", graphicsBackend->getBackendName().c_str());

  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }

  // Create window with backend-specific properties
  SDL_PropertiesID props = SDL_CreateProperties();
  SDL_SetStringProperty(props, SDL_PROP_WINDOW_CREATE_TITLE_STRING,
                        "Rive + SDL3 Multi-Backend");
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_WIDTH_NUMBER,
                        windowWidth);
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_HEIGHT_NUMBER,
                        windowHeight);
  SDL_SetNumberProperty(props, SDL_PROP_WINDOW_CREATE_FLAGS_NUMBER,
                        SDL_WINDOW_RESIZABLE);

  // Enable backend-specific window properties
  if (selectedBackend == GraphicsBackend::Metal) {
    SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_METAL_BOOLEAN, true);
    SDL_Log("Creating window with Metal support enabled");
  } else if (selectedBackend == GraphicsBackend::OpenGL) {
    SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_OPENGL_BOOLEAN, true);
    SDL_Log("Creating window with OpenGL support enabled");
  }

  window = SDL_CreateWindowWithProperties(props);
  SDL_DestroyProperties(props);

  if (!window) {
    SDL_Log("Couldn't create window: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }

  SDL_SetWindowSize(window, windowWidth, windowHeight);
  SDL_ShowWindow(window);

  // For Metal backend, ensure the native window is fully initialized
  if (selectedBackend == GraphicsBackend::Metal) {
    SDL_Log("Waiting for native window initialization (Metal backend)");
    SDL_SyncWindow(window);
    SDL_PumpEvents();
    SDL_Delay(100); // Small delay to ensure native window is ready
  }

  // Initialize the graphics backend
  if (!graphicsBackend->initialize(window, windowWidth, windowHeight)) {
    SDL_Log("Failed to initialize graphics backend");
    return SDL_APP_FAILURE;
  }

  // Initialize Rive
  if (!initializeRive()) {
    SDL_Log("Failed to initialize Rive");
    return SDL_APP_FAILURE;
  }

  lastTime = ((float)SDL_GetTicks()) / 1000.0f;

  return SDL_APP_CONTINUE;
}

/* This function runs when a new event (mouse input, keypresses, etc) occurs. */
SDL_AppResult SDL_AppEvent([[maybe_unused]] void *appstate, SDL_Event *event) {
  if (event->type == SDL_EVENT_QUIT) {
    return SDL_APP_SUCCESS; /* end the program, reporting success to the OS. */
  } else if (event->type == SDL_EVENT_WINDOW_RESIZED) {
    windowWidth = event->window.data1;
    windowHeight = event->window.data2;

    if (graphicsBackend)
      graphicsBackend->resize(windowWidth, windowHeight);

    SDL_Log("Window resized to %dx%d", windowWidth, windowHeight);
  } else if (event->type == SDL_EVENT_KEY_DOWN) {
    if (event->key.key == SDLK_SPACE) {
      isPaused = !isPaused;
      SDL_Log("Animation %s", isPaused ? "paused" : "resumed");
    }
  }

  return SDL_APP_CONTINUE; /* carry on with the program! */
}

/* This function runs once per frame, and is the heart of the program. */
SDL_AppResult SDL_AppIterate([[maybe_unused]] void *appstate) {
  if (!artboardInstance || !renderer || !renderContext) {
    return SDL_APP_CONTINUE;
  }

  // Calculate delta time
  float currentTime = ((float)SDL_GetTicks()) / 1000.0f;
  float deltaTime = currentTime - lastTime;
  lastTime = currentTime;

  // Update animation
  if (!isPaused && animationInstance)
    animationInstance->advanceAndApply(deltaTime);

  // Begin frame (backend-specific preparation)
  graphicsBackend->beginFrame();

  // Setup frame description
  rive::gpu::RenderContext::FrameDescriptor frameDescriptor;
  frameDescriptor.renderTargetWidth = static_cast<uint32_t>(windowWidth);
  frameDescriptor.renderTargetHeight = static_cast<uint32_t>(windowHeight);
  frameDescriptor.loadAction = rive::gpu::LoadAction::clear;
  frameDescriptor.clearColor = 0xFF404040; // Dark gray background
  frameDescriptor.disableRasterOrdering = false;
  frameDescriptor.wireframe = false;
  frameDescriptor.fillsDisabled = false;
  frameDescriptor.strokesDisabled = false;
  frameDescriptor.clockwiseFillOverride = true;

  // Begin context drawing
  renderContext->beginFrame(frameDescriptor);

  // Calculate scale to fit the artboard in the window while maintaining aspect
  // ratio
  float artboardWidth = artboardInstance->width();
  float artboardHeight = artboardInstance->height();
  float scaleX = windowWidth / artboardWidth;
  float scaleY = windowHeight / artboardHeight;
  float scale =
      std::min(scaleX, scaleY) * 0.8f; // Scale down slightly for padding

  // Calculate centering offset
  float scaledWidth = artboardWidth * scale;
  float scaledHeight = artboardHeight * scale;
  float offsetX = (windowWidth - scaledWidth) * 0.5f;
  float offsetY = (windowHeight - scaledHeight) * 0.5f;

  // Set up the transform matrix
  rive::Mat2D transform;
  transform = rive::Mat2D::fromTranslate(offsetX, offsetY) *
              rive::Mat2D::fromScale(scale, scale);

  // Render the artboard
  renderer->save();
  renderer->transform(transform);
  artboardInstance->draw(renderer.get());
  renderer->restore();

  // End frame (backend-specific cleanup and flushing)
  graphicsBackend->endFrame();

  return SDL_APP_CONTINUE;
}

/* This function runs once at shutdown. */
void SDL_AppQuit([[maybe_unused]] void *appstate,
                 [[maybe_unused]] SDL_AppResult result) {
  // Clean up Rive resources
  animationInstance.reset();
  artboardInstance.reset();
  riveFile.reset();
  renderer.reset();
  renderContext =
      nullptr; // Set render context to nullptr (owned by graphics backend)
  factory = nullptr; // Set factory to nullptr to indicate it's no longer valid

  // Shutdown graphics backend
  if (graphicsBackend) {
    graphicsBackend->shutdown();
    graphicsBackend.reset();
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
EMSCRIPTEN_KEEPALIVE void toggle_pause() { isPaused = !isPaused; }

EMSCRIPTEN_KEEPALIVE int get_pause_state() { return isPaused ? 1 : 0; }
}
#endif

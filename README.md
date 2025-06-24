# Rive SDL3/OpenGL Project

This is a minimal C++ project using [SDL3](https://github.com/libsdl-org/SDL), OpenGL, and [Rive](https://rive.app) for rendering interactive graphics.

---

## 🔧 Requirements

Make sure the following tools are installed:

- **Git** – to clone the repository
  - macOS: `brew install git`
  - Linux: `sudo apt install git`
  - Windows: [Git for Windows](https://git-scm.com/download/win)

- **CMake** (version ≥ 3.21) – to configure the project
  - macOS: `brew install cmake`
  - Linux: `sudo apt install cmake`
  - Windows: install from [cmake.org](https://cmake.org/download/) or via `choco install cmake`

- **vcpkg** – dependency manager for C++
  - Install:
    ```bash
    git clone https://github.com/microsoft/vcpkg.git
    ./vcpkg/bootstrap-vcpkg.sh    # or .\vcpkg\bootstrap-vcpkg.bat on Windows
    ```
  - Set the environment variable:
    - macOS/Linux:
      ```bash
      export VCPKG_ROOT=$HOME/vcpkg
      ```
    - Windows:
      ```powershell
      $env:VCPKG_ROOT = "C:\path\to\vcpkg"
      ```

- **Ninja** – fast build backend used by CMake presets
  - macOS: `brew install ninja`
  - Linux: `sudo apt install ninja-build`
  - Windows: `choco install ninja` or [download binaries](https://github.com/ninja-build/ninja/releases)

---

## 📦 Clone the Project

```bash
git clone https://github.com/your-username/rive_tests.git
cd rive_tests
```

---

## 📦 Install Dependencies

Make sure `VCPKG_ROOT` is set.

This project uses [vcpkg manifest mode](https://learn.microsoft.com/en-us/vcpkg/users/manifests), so dependencies are declared in `vcpkg.json`.

If you're using a supported IDE like CLion or VSCode, dependencies will be resolved automatically when you configure the project.

Otherwise, from the root of the project run:

```bash
vcpkg install
```

> 💡 You only need to run this manually if you want to prefetch dependencies or if your IDE doesn't handle it.

To add a new dependency:

```bash
vcpkg add port <port-name>
```

Example:

```bash
vcpkg add port fmt
```

This updates `vcpkg.json`

---

## ⚙️ Configure the Project

> You can use **scripts** or **CMake presets**.

### 🟩 Option 1: Using scripts

```bash
# macOS/Linux
./scripts/configure.sh          # or: ./scripts/configure.sh --release

# Windows
scripts\configure.bat           # or: scripts\configure.bat --release
```

### 🟦 Option 2: Using CMake presets (requires CMake ≥ 3.21)

```bash
cmake --preset debug            # or: cmake --preset release
```

---

## 🛠️ Build

```bash
# Scripts
./scripts/build.sh              # or: ./scripts/build.sh --release
scripts\build.bat               # or: scripts\build.bat --release

# Or CMake preset
cmake --build --preset debug    # or: cmake --build --preset release
```

---

## 🧼 Clean

```bash
./scripts/clean.sh              # or: ./scripts/clean.sh --release
scripts\clean.bat               # or: scripts\clean.bat --release
```

---

## ▶️ Run the App

```bash
./scripts/run.sh                # or: ./scripts/run.sh --release
scripts\run.bat                 # or: scripts\run.bat --release
```

---

## 📝 Notes

- Be sure `VCPKG_ROOT` is correctly set in your environment.
- Scripts assume the app binary is named `rive_tests`.

---

## 📁 Directory Structure

```text
rive_tests/
├── CMakeLists.txt
├── CMakePresets.json
├── scripts/
│   ├── configure.sh / .bat
│   ├── build.sh     / .bat
│   ├── run.sh       / .bat
│   └── clean.sh     / .bat
├── src/
│   └── main.cpp
└── README.md
```

cmake_minimum_required(VERSION 3.19)

project(lampshell-plugin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Qml Gui Concurrent)
qt_standard_project_setup(REQUIRES 6.5)

# Keep the generated module tree inside the build dir so the launcher can point
# QML_IMPORT_PATH at it without installing anything system-wide.
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

add_subdirectory(src)

qt_add_qml_module(lampshell-services
    URI Lampshell.Services
    VERSION 1.0
    SOURCES
        service.cpp
        service.hpp
        tickingservice.cpp
        tickingservice.hpp
        serviceref.cpp
        serviceref.hpp
        sensors.cpp
        sensors.hpp
        imagesampler.cpp
        imagesampler.hpp
        cpu.cpp
        cpu.hpp
        memory.cpp
        memory.hpp
        diskinfo.cpp
        diskinfo.hpp
        storage.cpp
        storage.hpp
        gpu.cpp
        gpu.hpp
        networkusage.cpp
        networkusage.hpp
)

target_link_libraries(lampshell-services PRIVATE
    Qt::Core
    Qt::Qml
    Qt::Concurrent
    Qt::Gui
)

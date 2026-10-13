#pragma once

#include <optional>

namespace lampshell::services::sensors {

// CPU package temperature in degrees celsius, read straight from hwmon so we
// avoid a libsensors dependency. nullopt when no known sensor is present.
[[nodiscard]] std::optional<double> cpuPackageTemp();

// Discrete GPU temperature for the generic (non-nvidia-smi) path. nullopt when
// no known hwmon sensor is present.
[[nodiscard]] std::optional<double> gpuTemp();

} // namespace lampshell::services::sensors

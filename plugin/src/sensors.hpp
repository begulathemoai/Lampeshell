#pragma once

#include <optional>

namespace lampshell::services::sensors {

[[nodiscard]] std::optional<double> cpuPackageTemp();

[[nodiscard]] std::optional<double> gpuTemp();

}

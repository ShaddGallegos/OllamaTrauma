# JVM Perf Workaround (SIGBUS mitigation)

This document describes the -XX:+PerfDisableSharedMemory workaround used by OllamaTrauma_v2.sh.

- `ENABLE_JVM_PERF_WORKAROUND` (default: `1`): when set, the script exports
  `JAVA_TOOL_OPTIONS` and `_JAVA_OPTIONS` with `-XX:+PerfDisableSharedMemory` if not already present.

- `ENABLE_JVM_PERF_WORKAROUND_SPARK` (default: `1`): enable Spark detection.

- `AUTO_APPLY_SPARK` (default: `0`): when set to `1`, the script will modify Sparks

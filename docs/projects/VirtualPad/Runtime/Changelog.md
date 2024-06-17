# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

None.

## 2.116.0 - 2024-06-17

### Changed

- Removed some helper executables from the installer that got false-flagged by some anti-virus ~~garbage~~ solutions for some users.
    - [VirusTotal report](https://www.virustotal.com/gui/file/981924dfb31b1f009c5001ecb06ad2bd2b6a24e6acd1b2208a7c31a6c7a2f8b0?nocache=1) (it's clean, IDK what it hallucinates about 🙄)

## 2.114.0 - 2024-04-17

### Changed

- Updated all dependencies in setup, service and notification components to their respective latest versions.

## 2.112.0 - 2024-02-14

### Changed

- Updated all dependencies in setup, driver, runtime, service and notification components to their respective latest versions.
- Introduced some DRM improvements to further reduce the potential for service interruptions.

## 2.110.0 - 2024-01-14

### Changed

- Switched server services to be provided from single VPS over to Kubernetes Cluster.

## 2.109.0 - 2023-12-30

### Changed

- Updated all installer dependencies to their respective latest version.
- Introduced a fallback HTTP client to use in the installer if the resilience logic failed for some reason.

### Fixed

- A bug that could halt the setup if a pre-existing service binary was somehow corrupted.
- A bug that could halt the setup if loading the EULA text failed.

## 2.103.0 - 2023-12-11

### Added

- Driver and runtime version `2.48.0`.
- New API to submit custom USB Control Request Responses via SDK (currently used to customize the serial number a virtual Xbox 360 device reports).
- Async overloads for device creating in the managed .NET SDK.

### Changed

- State-machine for keeping track of virtual devices got rewritten and streamlined for simpler debugging and better stability.
- Introduced usage of non-executable non-pagable kernel memory on supported systems.

### Fixed

- A bug that could lead to a system crash (BSOD) when switching between emulated devices due to improper reference counting.
- A bug that could lead to a system crash (BSOD) when Driver Verifier with Handle Tracking was enabled on the affected machine.
- A bug that could lead to a system crash (BSOD) when formatting a string that was missing enough space for the NULL terminator.

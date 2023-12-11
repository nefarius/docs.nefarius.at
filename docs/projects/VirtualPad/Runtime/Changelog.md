# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 2.103.0 - 2023-12-11

### Added

- Driver and runtime version `2.48.0`.
- New API to submit custom USB Control Request Responses via SDK (currently used to customize the serial number a virtual Xbox 360 device reports).
- Async overloads for device creating in the managed .NET SDK.

### Changed

- State-machine for keeping track of virtual devices got rewritten and streamlined for simpler debugging and better stability.

### Fixed

- A bug that could lead to a system crash (BSOD) when switching between emulated devices due to improper reference counting.
- A bug that could lead to a system crash (BSOD) when Driver Verifier with Handle Tracking was enabled on the affected machine.

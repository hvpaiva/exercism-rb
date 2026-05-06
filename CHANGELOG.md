# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.1.0 - 2026-05-06

### Added

- `xrb` CLI for downloading, selecting, opening, testing, inspecting, and submitting Exercism Ruby exercises.
- Source installer for users who want to install directly from the repository.
- RubyGems release preparation with CI, packaged gem smoke tests, and Trusted Publishing workflow.
- Colorized CLI output with explicit `XRB_COLOR`, `NO_COLOR`, and `CLICOLOR_FORCE` controls.
- Project documentation for development, security, contribution, and release practices.

### Changed

- Installation documentation now treats RubyGems as the primary distribution channel.

### Fixed

- State saves now use `Process.pid` for temporary files, avoiding Ruby warnings from an uninitialized global variable.

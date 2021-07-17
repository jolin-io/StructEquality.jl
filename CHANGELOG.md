# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2021-07-17
### Changed
- Julia 1.0 seems to be failing, Compat entry is now correctly set to julia 1.1. (The community guidelines says that Compat entry updates are breaking. As it hasn't worked before, this is not breaking, but for auto-merging we increase the version nevertheless.)
- updated TagBot and CompatHelper

## [1.0.1] - 2021-07-16
### Fixed
- strings docs are now ignored instead of throwing an error

## [1.0.0] - 2020-07-30
### Added
- GithubActions for CI, Codecov
- Changelog
- License
- added doc string to `@def_structequal`
### Changed
- dropped dependency on SimpleMatch

## [0.1.0] - 2020-01-16
initial release

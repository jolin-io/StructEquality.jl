# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

##  [2.0.0] - 2022-04-08

### Breaking
- dropped support for Julia versions < 1.6
- renamed `@def_structequal` to `@struct_equal`. The old name is still available for easy transitioning, but `@def_structequal` is going to be removed in an upcoming minor release.
### Deprecated
- `@def_structequal` is deprecated. You can use `@struct_equal` as a direct replacement.

### Changed
- renamed `@def_structequal` to `@struct_equal`

### Added
- added `@struct_hash` for defining `Base.hash`
- added `@struct_equal` for defining `Base.:(==)`
- added `@struct_isequal` for defining `Base.isequal`
- added `@struct_isapprox` for defining `Base.isapprox`
- added combination macros `@struct_hash_equal`, `@struct_hash_equal_isapprox`, `@struct_hash_equal_isequal`, `@struct_hash_equal_isequal_isapprox`, which are straightforward combinations of the other 4 macros
- added generated functions which are now the implementation detail of the respective macros `struct_hash`, `struct_equal`, `struct_isequal` & `struct_isapprox`

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

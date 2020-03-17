# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

* Tweaks .env file feature.

## [0.0.3] - 2020-03-16

### Added

* Support VSCode Remote Development

### Changed

* Run starman with the auto reload option.

## [0.0.2] - 2020-03-11

### Added

* Enable to specify both RECIPE and ARCHIVE.
  * `$ vagrant mt-dev up ARCHIVE=MTA7-R4605.tar.gz RECIPE=shared-preview`

### Changed

* Update default software versions.
  * Perl : 5.28
  * PHP : 7.3
  * DB : MySQL 5.7

## [0.0.1] - 2020-03-09

### Added

* Support multiple recipes.
  * `$ vagrant mt-dev up RECIPE=7.2,shared-preview`
* Support custom mt-config.cgi
  * `$ vagrant mt-dev up RECIPE=7.2 MT_CONFIG_CGI=mt-config.cgi-7.2`

### Fixed

* Fix repository pull bug.

## [0.0.0] - 2020-03-02

Initial release
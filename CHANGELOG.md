# Changelog

Changes to the RT container image. Earlier history is in the git log.

## Unreleased

- `DBD::mysql` is no longer installed from CPAN. We don't use the MySQL
  backend, and the current release (5.013) fails to build against the base
  image. The `DBD::mysql` that comes with the base image is still there, so
  existing MySQL setups keep working — it just isn't kept up to date.
- `DBD::Pg` now comes from the Alpine `perl-dbd-pg` package rather than CPAN.
  Building it from CPAN needs postgresql development headers that the base
  image doesn't carry.
- `Time::ParseDate` is installed without running its tests. One test pins
  `TZ=MST7MDT` and lands an hour off around the epoch, because musl and glibc
  pick different DST defaults for a bare POSIX timezone string. RT uses named
  zones from tzdata, so it doesn't affect the running system.

## 6.0.3

- RT 6.0.3.

## 6.0.2

- RT 6.0.2.

## 5.0.9

- RT 5.0.9, on Alpine 3.23.

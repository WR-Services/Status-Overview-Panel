# Changelog

## [v0.0.7] (dev-release)

Released at 23-09-2025

### Fixed

- Fixed JSX syntax issues in ThresholdEditor.tsx
- Fixed RuleItem.tsx component structure
- Added missing properties in RuleEditor.tsx to match interface requirements
- Fixed custom thresholds not triggering in status evaluation
- Added support for custom colors from custom thresholds

### Added

- Added ability to customize text color alongside background color in custom thresholds

## [v0.0.6] (dev-release)

Released at 23-09-2025

### Added

- Per-rule unit formatting options for different data types
- Enhanced field configuration using Grafana's built-in formatting system
- Improved time display for time-based metrics
- Text spacing customization options (title margin, line height, text spacing, inline spacing)
- Additional threshold levels: "Minor" (between Information and Warning) and "Critical" (between High and Disaster)

### Changed

- Updated authorship: Now maintained by Ferit Sari Tomé
- Original author (Krasnov Sergei) credited in documentation

## [v0.0.4] (dev-release)

Released at 17-06-2023

### Added

- Selecting metrics by regular expression
- Replacing the name of the metric by regular expression

### Changed

- Changed error display for duplicate metrics

### Fixed

- Small fixes

## [v0.0.3] (dev-release)

Released at 11-05-2023

* Initial release.
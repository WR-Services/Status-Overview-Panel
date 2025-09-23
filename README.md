# Status Overview Panel 2

Status Overview Panel 2 is an ideological continuation of the Status Panel plugin, written on the current framework supported by Grafana.
The plugin's task is to display the worst status of any component based on various metrics or one of the metrics of that component.
In this context, the component can be any server, application, IT system, or any other entity that you can think of, combining metrics into a single entity.
The main feature of the plugin is the visual representation of the component's status changes.
This is achieved through a large panel with the component's name, displaying all metrics or metrics that influence the status change, as well as a blinking effect when the status changes.
Audio notifications are also planned for the future.

## Maintainer

This fork is maintained by Ferit Sari Tomé. The original plugin was created by Krasnov Sergei (serrrios).

### Enhancements in this fork
- Added per-rule unit formatting options for proper display of different data types
- Enhanced field configuration for better control over metric display formatting
- Improved time display for time-based metrics
- Added support for various unit formats (time, bytes, percentage, etc.)
- Integrated formatting options directly within rule configuration
- Added text spacing customization options:
  - Adjustable title margin
  - Configurable line height for metrics
  - Customizable spacing between metric rows
  - Control of spacing between inline metrics
- Added additional threshold levels:
  - Minor threshold (between Information and Warning)
  - Critical threshold (between High and Disaster)

# Preview
![Simple work](https://raw.githubusercontent.com/WR-Services/Status-Overview-Panel/master/img/preview_transparent.png)

# Development

## Setup & Deployment
This repository includes VS Code tasks for easy development:

1. **Build the plugin**: Run the "Build Plugin" task or use `npm run build`
2. **Restart Docker**: Run the "Restart Docker" task or use `docker-compose down && docker-compose up -d`
3. **Build and Deploy**: Run the combined "Build and Deploy" task or use the `deploy.ps1` script

## Quick Start
For the fastest development workflow:
1. Press `Ctrl+Shift+P` to open the command palette
2. Type "Tasks: Run Task" and select "Build and Deploy"
3. Access Grafana at http://localhost:3000

# Main Functionality
- General
    - Enable/disable or set the panel to an unknown status
    - Choose the display type of metrics, either in rows or in a single line
    - Enable/disable the blinking effect
    - Add a link in the panel's name to navigate to another level or dashboard
- Select color schemes for possible statuses
- Rules
    - Add, delete, clone, and move rules
    - Rule name
    - Select the metric or metrics by regular expression to which you want to apply the rules.
    - Option to set an alias for displaying metrics, static or regular expression
    - Option to provide additional metric description for display in a tooltip
    - Display metric name
    - Display metric value
    - Choose the display type
        - Numeric threshold
            - Display only when the threshold is reached
            - Reverse logic if you need to assign statuses from the highest metric value to the lowest
            - 7 threshold levels: Information, Minor, Warning, Average, High, Critical, and Disaster (any threshold can be left empty if not needed)
        - String threshold
            - Display only when the threshold is reached
            - 7 threshold levels: Information, Minor, Warning, Average, High, Critical, and Disaster (any threshold can be left empty if not needed)
        - Display only or conditional display without affecting the panel's status
            - Use conditions or not
            - Choose the condition: equal, not equal, greater than, less than, and value. Works for both numeric and string values.

# Recommendations
It is strongly recommended to remove the panel name in the standard panel settings and use the panel name in the plugin settings.

# Data Sources
The plugin is designed to work with any data sources and has been tested with:
- Zabbix
- Prometheus
- Postgres

If you encounter any issues with specific data sources, please leave an issue.

# TODO
- Audio notifications
- ~~Select metrics based on regular expressions~~ added in v0.0.4
- ~~Select and display value types for metrics~~ added in v0.0.5
- Additional plugin for global settings that affect all panels

## Contributing

To contribute to the plugin:
1. Fork the repository from [GitHub](https://github.com/WR-Services/Status-Overview-Panel)
2. Create a feature branch
3. Make your changes following the existing code style
4. Submit a pull request

Use FR, any ideas for development are welcome.

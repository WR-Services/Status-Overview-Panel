import { SelectableValue } from '@grafana/data';

// Common unit formats used in the plugin
export const UnitFormatOptions: SelectableValue[] = [
  { value: 'none', label: 'None' },
  // Time formats
  { value: 'dateTimeAsIso', label: 'ISO DateTime' },
  { value: 'dateTimeAsUS', label: 'US DateTime' },
  { value: 'dateTimeFromNow', label: 'Time from Now' },
  
  // Duration formats
  { value: 's', label: 'Seconds' },
  { value: 'ms', label: 'Milliseconds' },
  { value: 'dtdurations', label: 'Duration (Days/Hours/Minutes/Seconds)' },
  { value: 'dthms', label: 'Days/Hours/Minutes/Seconds' },
  
  // Number formats
  { value: 'percent', label: 'Percent (0-100)' },
  { value: 'percentunit', label: 'Percent (0.0-1.0)' },
  
  // Bytes and bits
  { value: 'bytes', label: 'Bytes' },
  { value: 'bits', label: 'Bits' },
  { value: 'kbytes', label: 'Kilobytes' },
  { value: 'mbytes', label: 'Megabytes' },
  { value: 'gbytes', label: 'Gigabytes' },
  
  // Throughput
  { value: 'ops', label: 'Operations/sec' },
  { value: 'rps', label: 'Requests/sec' },
  { value: 'wps', label: 'Writes/sec' },
  { value: 'iops', label: 'I/O Ops/sec' },
  
  // Temperature
  { value: 'celsius', label: 'Celsius' },
  { value: 'fahrenheit', label: 'Fahrenheit' },
  
  // Misc
  { value: 'none', label: 'None' },
  { value: 'short', label: 'Short' },
  { value: 'hex', label: 'Hexadecimal' },
  { value: 'string', label: 'String' },
];

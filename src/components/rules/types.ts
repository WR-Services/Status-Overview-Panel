
import { SelectableValue } from '@grafana/data';

export interface RuleMember { }

export interface ThresholdItem {
  name: string;        // The threshold name (e.g., "warning", "critical")
  value: string;       // The threshold value as a string
  color: string;       // The background color for this threshold
  textColor?: string;  // The text color for this threshold
  order: number;       // The order of this threshold in severity (lower = less severe)
}

export const DisplayModes: SelectableValue[] = [
  { value: 'number', label: 'Number threshold' },
  { value: 'string', label: 'String threshold' },
  { value: 'show', label: 'Show only ' },
];

export const LogicalModes: SelectableValue[] = [
  { value: 'eq', label: 'Equivalent' },
  { value: 'ne', label: 'Not equivalent' },
  { value: 'ge', label: 'Greater than' },
  { value: 'lt', label: 'Less than' },
];

export interface RuleItemType {
  name: string;
  label: string;
  order: number;
  isTemplated: boolean;
  displayMode: string;
  description?: string | '';
  enabled: boolean;
  showName: boolean;
  showValue: boolean;
  showRule: boolean;
  showMembers: boolean;
  showOnlyOnThreshold: boolean;
  revers: boolean;
  // For backward compatibility
  numberThreshold: {
    information: string;
    minor: string;
    warning: string;
    average: string;
    high: string;
    critical: string;
    disaster: string;
  };
  // For backward compatibility
  stringThreshold: {
    information: string;
    minor: string;
    warning: string;
    average: string;
    high: string;
    critical: string;
    disaster: string;
  };
  // Dynamic thresholds
  customThresholds?: ThresholdItem[];
  useCustomThresholds?: boolean;
  clickThrough: string | '';
  clickThroughSanitize: boolean;
  clickThroughOpenNewTab: boolean;
  logicExpress: boolean;
  logicExpressValue: string;
  logicalMode: string;
  seriesMatch: string | '';
  alias?: string | '';
  shortAlias?: string | '';
  ID?: string;
  // Field formatting options
  unitFormat?: string;
  decimals?: number;
  useCustomFormatting?: boolean;
}

export interface RuleItemTracker {
  rule: RuleItemType;
  order: number;
  ID: string;
}

export interface RuleItemProps {
  rule: RuleItemType;
  ID: string;
  enabled: boolean;
  setter: any;
  remover: any;
  moveUp: any;
  moveDown: any;
  createDuplicate: any;
  context: any;
}

export interface RuleMetricItemProps {

  index: number;
  disabled: boolean;
  removeMetric: any;
  updateMetric: any;
  updateMetricAlias: any;
  context: any;
}

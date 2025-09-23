import { RuleItemType } from '../components/rules/types';
import { MetricHint } from 'types';


interface StatusResult {
  state: string;
  customColor?: string;
  textColor?: string;
}

export function findWorstStatus(metricHints: MetricHint[], rules: RuleItemType[]): string | StatusResult {

  const statusOrder = ['information', 'minor', 'warning', 'average', 'high', 'critical', 'disaster'];
  let worstStatusIndex = -1;
  let customColor: string | undefined = undefined;
  let textColor: string | undefined = undefined;

  if (!rules) { return worstStatusIndex >= 0 ? statusOrder[worstStatusIndex] + '-state' : 'ok-state'; }

  for (const rule of rules) {
    let series;
    for (const hint of metricHints) {
      //if (hint.label === rule.seriesMatch) {
      if (new RegExp(rule.seriesMatch).test(hint.label)) {
        series = hint;
        //break;
        if (!series) { continue; }
        const value = series.value;

        // Handle custom thresholds
        if (rule.displayMode === 'number' && rule.useCustomThresholds && rule.customThresholds && rule.customThresholds.length > 0) {
          // Sort thresholds by order value (ascending)
          const sortedThresholds = [...rule.customThresholds].sort((a, b) => a.order - b.order);

          for (const threshold of sortedThresholds) {
            const thresholdValue = parseFloat(threshold.value);
            if (threshold.value && !isNaN(thresholdValue)) {
              if (typeof value === 'number' && (rule.revers ? (value <= thresholdValue) : (value >= thresholdValue))) {
                const statusIndex = statusOrder.indexOf(threshold.name);
                if (statusIndex > worstStatusIndex) {
                  worstStatusIndex = statusIndex;
                  customColor = threshold.color; // Store the custom color
                  textColor = threshold.textColor; // Store the custom text color if available
                }
              }
            }
          }
        }
        // Handle standard number thresholds
        else if (rule.displayMode === 'number' && rule.numberThreshold) {
          for (const [status, threshold] of Object.entries(rule.numberThreshold)) {
            if (threshold !== null) {
              if (status === 'showOnlyOnThreshold') { continue; }
              if (typeof value === 'number' && (rule.revers ? (value <= parseFloat(threshold)) : (value >= parseFloat(threshold)))) {
                const statusIndex = statusOrder.indexOf(status);
                if (statusIndex > worstStatusIndex) {
                  worstStatusIndex = statusIndex;
                }
              }
            }
          }
        } else if (rule.displayMode === 'string' && rule.stringThreshold) {
          for (const [status, statusValue] of Object.entries(rule.stringThreshold)) {
            if (String(value) === statusValue) {
              const statusIndex = statusOrder.indexOf(status);
              if (statusIndex > worstStatusIndex) {
                worstStatusIndex = statusIndex;
              }
            }
          }
        }
      }
    }


  }

  if (worstStatusIndex >= 0) {
    const state = statusOrder[worstStatusIndex] + '-state';
    if (customColor || textColor) {
      // Return object with state, custom color, and text color
      return {
        state,
        customColor,
        textColor
      };
    }
    return state;
  }

  return 'ok-state';
}



import { compareValues } from './comparisonFunctions';
import { findWorstStatus } from './findWorstStatus';
import { RuleItemType } from '../components/rules/types';
import { AppEvents, getValueFormat, formattedValueToString } from '@grafana/data';
import { getAppEvents } from '@grafana/runtime';
import { MetricHint } from 'types';


export function displaySeriesData(metricHints: MetricHint[], rules: RuleItemType[]) {

    const labelCounts: { [label: string]: number } = {};
    
    metricHints.forEach((hint) => {
        if (labelCounts[hint.label]) {
            labelCounts[hint.label]++;
        } else {
            labelCounts[hint.label] = 1;
        }
    });
    
    Object.entries(labelCounts).forEach(([label, count]) => {
        if (count > 1) {
          getAppEvents().publish({
            type: AppEvents.alertWarning.name,
            payload: [`Warning: multiple metrics with the label "${label}" were found.`],
          });
        }
    });
    
    const result = [];
    if (!rules) { return; }
    for (const rule of rules) {
        let series;
        for (const hint of metricHints) {
            //if (hint.label === rule.seriesMatch) {
            if (new RegExp(rule.seriesMatch).test(hint.label)) {    

                series = hint;
                //break;
                if (!series) {continue;}

                if (series) {
                    if (((rule.displayMode === 'number' || rule.displayMode === 'string') && rule.showOnlyOnThreshold) && findWorstStatus( [series] , [rule]) === 'ok-state') { continue }        
                    const value = series.value;
                    let shouldDisplay = true;

                    if (rule.displayMode === 'show' && rule.logicExpress) {
                        shouldDisplay = compareValues(
                            value,
                            rule.logicExpressValue as string,
                            rule.logicalMode
                        );
                    }   

                    if (shouldDisplay) {
                        let line = '';
                        if (rule.showName) {
                            if (rule.alias) {
                                try {
                                  const regex = new RegExp(rule.alias);
                                  const match = regex.exec(series.label);
                              
                                  if (match && match[1]) {
                                    line += match[1];
                                  } else {
                                    line += rule.alias;
                                  }
                                } catch (error) {
                                  line += rule.alias;
                                }
                            } else {
                                line += series.label;
                            }
                        }
                        if (rule.showName && rule.showValue) { line += `: `; }
                        if (rule.showValue) { 
                            // Apply rule-specific formatting if custom formatting is enabled
                            if (rule.useCustomFormatting && rule.unitFormat) {
                                // Apply custom formatting based on rule settings
                                try {
                                    const formatter = getValueFormat(rule.unitFormat);
                                    const decimals = rule.decimals !== undefined ? rule.decimals : 2;
                                    const formatted = formatter(value, decimals);
                                    line += formattedValueToString(formatted);
                                } catch (error) {
                                    console.error('Error formatting value:', error);
                                    // Fallback to default formatting
                                    if (series.valueFormatted) {
                                        line += series.valueFormatted;
                                    } else {
                                        line += value;
                                    }
                                }
                            } else {
                                // Use standard formatted value if available
                                if (series.valueFormatted) {
                                    line += series.valueFormatted;
                                } else {
                                    line += value;
                                }
                            }
                        }
                        if (rule.showName || rule.showValue) { 
                            result.push({ line, tooltip: ( rule.description ? rule.description : '') });
                        }
                    }
                }
            }
        }

        
    }
  return result;
}



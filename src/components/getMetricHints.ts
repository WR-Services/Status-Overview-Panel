import { DataFrameToMetrics } from './processor'
import { PanelData } from '@grafana/data';


import { MetricHint } from '../types';
  
export function getMetricHints(data: PanelData): MetricHint[] {
    const hints: MetricHint[] = [];
    for (const metric of data.series) {
      const hintsValue = DataFrameToMetrics(metric, 'last');

      for (const hintValue of hintsValue) {
        hints.push({
          label: hintValue.name,
          value: hintValue.valueRounded,
          valueFormatted: hintValue.valueFormatted,
          fieldType: hintValue.fieldType
        });
      }
    }
    return hints;
}

// export function getMetricHints(data: PanelData): MetricHint[] {
//   const hints: MetricHint[] = [];
//   for (const metric of data.series) {
//     const hintValue = DataFrameToMetrics(metric, 'last')[0];
//     hints.push({
//       label: hintValue.name,
//       value: hintValue.value,
//     });
//   }
//   return hints;
// }

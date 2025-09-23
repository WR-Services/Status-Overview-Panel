
interface ColorResult {
  backgroundColor: string;
  textColor?: string;
}

export function getColorByState(state: string | { state: string; customColor?: string; textColor?: string }, options: any): string | ColorResult {
  // If state is an object with custom color, use it
  if (typeof state === 'object') {
    if (state.customColor && state.textColor) {
      return {
        backgroundColor: state.customColor,
        textColor: state.textColor
      };
    } else if (state.customColor) {
      return state.customColor;
    }
  }

  // Otherwise, get the state string and use standard colors
  const stateStr = typeof state === 'object' ? state.state : state;

  switch (stateStr) {
    case 'ok-state':
      return options.ColorOK;
    case 'disaster-state':
      return options.ColorDisaster;
    case 'critical-state':
      return options.ColorCritical;
    case 'high-state':
      return options.ColorHigh;
    case 'average-state':
      return options.ColorAverage;
    case 'warning-state':
      return options.ColorWarning;
    case 'minor-state':
      return options.ColorMinor;
    case 'information-state':
      return options.ColorInformation;
    case 'disable-state':
      return options.ColorDisable;
    case 'na-state':
      return options.ColorNa;
    default:
      return 'rgba(0, 0, 0, 0)';
  }
}


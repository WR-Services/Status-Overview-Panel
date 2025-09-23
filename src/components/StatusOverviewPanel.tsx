import React, { useState, useEffect, useMemo } from 'react';
import { PanelProps } from '@grafana/data';
import { StatusOverviewOptions } from 'types';
import { css, cx } from '@emotion/css';
import { useStyles2, Tooltip } from '@grafana/ui';
import { findWorstStatus } from './findWorstStatus';
import { displaySeriesData } from './displaySeriesData';
import { getColorByState } from './getColorByState';
import { getMetricHints } from './getMetricHints';
interface Props extends PanelProps<StatusOverviewOptions> {}



export const StatusOverviewPanel: React.FC<Props> = ({ options, data, width, height, id, replaceVariables }) => {

  const useStyles = useStyles2(() => {
    return {
      wrapper: css`
        position: relative;
      `,
      svg: css`
        position: absolute;
        top: 0;
        left: 0;
      `,
      textBox: css`
        position: absolute;
        bottom: 0;
        left: 0;
        padding: 10px;
      `,
      valueMap: css`
        font-size: 0.85em;
        line-height: ${options.lineHeight || 1.5}em;
      `,    
      bottom_section: css`
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-content: center; 
        height: 100%;
      `,
      top_section: css`
        box-sizing: inherit;
        vertical-align: middle;
        height: 100%;
      `,
      status_name_row: css`
        color: #080808;
        overflow:hidden;
      `,
      h1: {
        margin: `0px 0px ${options.titleMargin || 10}px`,
        fontSize: '1.4rem',
        'padding-top': '3px',
        'letter-spacing': '-0.01893em',
      },
      a: {
        color: '#080808',
      },
      blink: css`
      animation-name: blinker;
      animation-iteration-count: infinite;
      animation-timing-function: cubic-bezier(1.0,2.0,0,1.0);
      animation-duration: 1s;
      animation-play-state: running;
      -webkit-animation-name: blinker;
      -webkit-animation-iteration-count: infinite;
      -webkit-animation-play-state: running;
      -webkit-animation-timing-function: cubic-bezier(1.0,2.0,0,1.0);
      -webkit-animation-duration: 1s;
      `,
     
    };
  });
  
  
  const [state, setState] = useState<string | null>(null);
  const [blink, setBlink] = useState(false);


  const GlobalPanelState = useMemo(() => {
    return [];
  }, []); 

  useEffect(() => {
    setBlink(false);
    if (options.statePanel === 'enable') { setState(findWorstStatus(getMetricHints(data), options.ruleConfig.rules )); }
    else if (options.statePanel === 'na') { setState('na-state') }
    else { setState('disable-state') }
  }, [data, options.ruleConfig.rules, options.statePanel]);
  

  useEffect(() => {
    setBlink(false);
    if ((GlobalPanelState[id] !== 'not-ok-state') && state === 'ok-state') {
			if (typeof GlobalPanelState[id] !== "undefined") {
				setBlink(true);
			}
      // to be fix..
      // @ts-ignore
			GlobalPanelState[id] = 'not-ok-state';   
		} else if ((GlobalPanelState[id] !== 'not-disaster-state') && state === 'disaster-state') {
			if (typeof GlobalPanelState[id] !== "undefined") {
				setBlink(true);
			}
      // to be fix..
      // @ts-ignore
			GlobalPanelState[id] = 'not-disaster-state';
		} else if ((GlobalPanelState[id] !== 'not-high-state') && state === 'high-state') {
			if (typeof GlobalPanelState[id] !== "undefined") {
				setBlink(true);
			}
      // to be fix..
      // @ts-ignore
			GlobalPanelState[id] = 'not-high-state';
		} else if ((GlobalPanelState[id] !== 'not-average-state') && state === 'average-state') {
			if (typeof GlobalPanelState[id] !== "undefined") {
				setBlink(true);
			}
      // to be fix..
      // @ts-ignore
			GlobalPanelState[id] = 'not-average-state';
    } else if ((GlobalPanelState[id] !== 'not-warning-state') && state === 'warning-state') {
			if (typeof GlobalPanelState[id] !== "undefined") {
				setBlink(true);
			}
      // to be fix..
      // @ts-ignore
			GlobalPanelState[id] = 'not-warning-state';
    } else if ((GlobalPanelState[id] !== 'not-information-state') && state === 'information-state') {
			if (typeof GlobalPanelState[id] !== "undefined") {
				setBlink(true);
			}
      // to be fix..
      // @ts-ignore
			GlobalPanelState[id] = 'not-information-state';  
    }    
  }, [id, state, GlobalPanelState]);
  

  const blinkClass = blink && options.blink ? useStyles.blink : '';
  const backgroundColor = getColorByState(state ?? '', options);
  const [displayData, setDisplayData] = useState<Array<{ line: string; tooltip: string; }>>([]);

  
  useEffect(() => {
    let result = displaySeriesData(getMetricHints(data), options.ruleConfig.rules);
    setDisplayData(result || []);
  }, [data, options]);

  return (
    <div
      className={cx(
        useStyles.wrapper,
        blinkClass,
        blinkKeyframes,
        css`
          width: ${width + 16}px;
          height: ${height + 16}px;
	        text-align: center;
          overflow: hidden;
          position: relative;
          border-radius: 3px;
          backface-visibility: hidden;
          transition: transform 0.5s;
	        margin: -8px 0 0 -8px;
          background-color: ${backgroundColor}};
        `
      )}
    >
      <div className={useStyles.top_section }>	
        <div className={useStyles.bottom_section}>
	        <div className={useStyles.status_name_row}>
	          <h1 style={useStyles.h1}>
            {options.dataLink ? (
              <a style={useStyles.a} href={replaceVariables(options.dataLink)}>
                {replaceVariables(options.panelName)}
              </a>
            ) : (
              <span style={useStyles.a}>{replaceVariables(options.panelName)}</span>
            )}
	          </h1>
            {options.statePanel === 'enable' ? (
            <div className={useStyles.valueMap}>
              {options.modePanel && options.modePanel === 'in' ? (
                displayData.map((item, index) => (
                  <span key={index} style={{ marginRight: index < displayData.length - 1 ? `${options.inlineSpacing || 10}px` : '0' }}>
                    {item.tooltip ? (
                      <Tooltip content={<div style={{ whiteSpace: 'pre-wrap' }}>{item.tooltip}</div>}>
                        <span>
                         {item.line}
                        </span>
                      </Tooltip>
                    ) : (
                      <span>
                        {item.line}
                      </span>
                    )}
                    <span>
                      {index < displayData.length - 1 ? ' / ' : ''}
                    </span>
                  </span>
                ))
              ) : (
                displayData.map((item, index) => (
                  <div key={index} style={{ marginBottom: `${options.textSpacing || 5}px` }}>
                    {item.tooltip ? (
                      <Tooltip content={<div style={{ whiteSpace: 'pre-wrap' }}>{item.tooltip}</div>}>
                        <span>
                         {item.line}
                        </span>
                      </Tooltip>
                    ) : (
                      <span>
                        {item.line}
                      </span>
                    )}
                  </div>
                ))
              )}
            </div>
            ) : '' }
           </div>
          </div>
        </div>
      </div>
  );
};

const blinkKeyframes = css`
    @keyframes blinker {
      from {
        opacity: 1.0;
      }
      50% {
        opacity: 0.5;
      }
      to {
        opacity: 1.0;
      }
    }
  
    @-webkit-keyframes blinker {
      from {
        opacity: 1.0;
      }
      50% {
        opacity: 0.5;
      }
      to {
        opacity: 1.0;
      }
    }
  `;


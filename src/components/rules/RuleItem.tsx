////////////////////////////////////////////////////////////
// Original code by Grafana Polystat Panel https://github.com/grafana/grafana-polystat-panel/blob/main/src/components/composites/CompositeItem.tsx
// Edited by serrrios
////////////////////////////////////////////////////////////
import React, { useState, useEffect } from 'react';
import { IconName, Input, Select, Field, FieldSet, Switch, Card, IconButton, Cascader, TextArea, CascaderOption } from '@grafana/ui';
import { DisplayModes, LogicalModes, RuleItemProps, RuleItemType } from './types';
import { DataFrameToMetrics } from '../processor'
import { SelectableValue, FieldType } from '@grafana/data';
import { UnitFormatOptions } from './unitFormats';

export interface MetricsModel {
  name: string;
  value: number;
}

export const RuleItem: React.FC<RuleItemProps> = (props: RuleItemProps) => {
//  export const RuleItem: React.FC<Props> = ({data, options}) => {
  const [metricHints, setMetricHints] = useState<CascaderOption[]>([]);
  const [rule, _setRule] = useState(props.rule);
  const getDisplayMode = (displayMode: string) => {
    const keys = DisplayModes.keys();
    for (const aKey of keys) {
      if (DisplayModes[aKey].value === displayMode) {
        return DisplayModes[aKey];
      }
    }
    // no match, return all by default
    return DisplayModes[0];
  };
  const [displayMode, setDisplayMode] = useState<SelectableValue<any>>(getDisplayMode(props.rule.displayMode));
  
  const getLogicalMode = (logicalMode: string) => {
    const keys = LogicalModes.keys();
    for (const aKey of keys) {
      if (LogicalModes[aKey].value === logicalMode) {
        return LogicalModes[aKey];
      }
    }
    // no match, return all by default
    return LogicalModes[0];
  };
  const [logicalMode, setLogicalMode] = useState<SelectableValue<any>>(getLogicalMode(props.rule.logicalMode));
//  const [logicalMode, setLogicalMode] = useState<string>(getLogicalMode(props.rule.logicalMode).value);
  const setRule = (value: RuleItemType) => {
    _setRule(value);
    props.setter(rule.order, value);
  };
  const [visibleIcon] = useState<IconName>('eye');
  const [hiddenIcon] = useState<IconName>('eye-slash');
  const removeItem = () => {
    //alert('high');
    props.remover(rule.order);
    // call parent remove function
  };

  const toggleShowName = () => {
    const currentState = rule.showName;
    //setShowName(!currentState);
    setRule({ ...rule, showName: !currentState });
  };

  const toggleShowValue = () => {
    const currentShowValue = rule.showValue;
    //setShowName(!currentState);
    setRule({ ...rule, showValue: !currentShowValue });
  };

  const moveUp = () => {
    props.moveUp(rule.order);
  };
  const moveDown = () => {
    props.moveDown(rule.order);
  };
  const createDuplicate = () => {
    props.createDuplicate(rule.order);
  };


  useEffect(() => {
    if (props.context.data) {
      let hints: CascaderOption[] = [];
      let metricHints = new Set<string>();
      let fieldTypeMap = new Map<string, string>();
      
      for (const metric of props.context.data) {
        let hintsValue = DataFrameToMetrics(metric, 'last');
        for (const hintValue of hintsValue) {
          metricHints.add(hintValue.name);
          // Store field type for each metric
          if (hintValue.fieldType) {
            fieldTypeMap.set(hintValue.name, hintValue.fieldType);
          }
        }  
      }
      
      for (const metricName of metricHints) {
        const fieldType = fieldTypeMap.get(metricName) || 'unknown';
        // Add field type information to the label
        let fieldTypeLabel = '';
        
        if (fieldType === FieldType.time) {
          fieldTypeLabel = ' (time)';
        } else if (fieldType === FieldType.number) {
          fieldTypeLabel = ' (number)';
        } else if (fieldType === FieldType.string) {
          fieldTypeLabel = ' (string)';
        }
        
        hints.push({
          label: `${metricName}${fieldTypeLabel}`,
          value: metricName,
        });
      }
      setMetricHints(hints);
    }
  }, [props.context.data ]);

  return (
    <Card heading="" key={`rule-card-${props.ID}`}>
      <Card.Meta>        
        <FieldSet>
          <Field label="Rule Name" disabled={!rule.showRule}>
            <Input
              value={rule.name}
              placeholder=""
              disabled={!rule.showRule}
              onChange={(e) => setRule({ ...rule, name: e.currentTarget.value })}
            />
          </Field>

          <Field label="Metric" disabled={!rule.showRule} style={{ minWidth: '175px' }} >
            <Cascader
              key={`cmi-index-${props.ID}`}
              initialValue={rule.seriesMatch}
              allowCustomValue
              placeholder="Сhoose a metric or enter a regular expression"
              options={metricHints}
              onSelect={(val: string) => setRule({ ...rule, seriesMatch: val })} 
            />
          </Field>
          <Field label="Alias metric name" description="Used as metric name if exists">
            <Input
              value={rule.alias}
              placeholder="Enter alias or a regular expression"
              disabled={!rule.showRule}
              onChange={(e) => setRule({ ...rule, alias: e.currentTarget.value })}
            />
          </Field>
          <Field label="Description" description="Used on tooltip if exists" >
            <TextArea
              value={rule.description}
              placeholder=""
              style={{ resize: 'both' }}
              disabled={!rule.showRule}
              onChange={(e) => setRule({ ...rule, description: e.currentTarget.value })}
            />
          </Field> 
          <Field label="Show metric name" description="Toggle Display of metric name" disabled={!rule.showRule}>
            <Switch
              transparent={true}
              value={rule.showName}
              disabled={!rule.showRule}
              onChange={toggleShowName}
            ></Switch>
          </Field>
          <Field label="Show metric value" description="Toggle Display of metric value" disabled={!rule.showRule}>
            <Switch
              transparent={true}
              value={rule.showValue}
              disabled={!rule.showRule}
              onChange={toggleShowValue}
            />
          </Field>

          
          <Field
            label="Display Mode"
            description="Metric handler type"
            disabled={!rule.showRule}
          >
            <Select
              menuShouldPortal={true}
              value={displayMode}
              onChange={(v) => {
                setDisplayMode(v);
                setRule({ ...rule, displayMode: v.value });
              }}
              options={DisplayModes}
            />
          </Field>
          { rule.displayMode === 'number' ? (
          <>
          <Field
            label="Show only on Threshold"
            disabled={!rule.showRule}
          >
            <Switch
              transparent={true}
              value={rule.showOnlyOnThreshold}
              disabled={!rule.showRule}
              onChange={() => setRule({ ...rule, showOnlyOnThreshold: !rule.showOnlyOnThreshold, }, )}
            />
          </Field> 
          <Field
            label="Revers logic"
            description="Inverse processing of values, if processing is needed from the largest to the smallest."
            disabled={!rule.showRule}
          >
            <Switch
              transparent={true}
              value={rule.revers}
              disabled={!rule.showRule}
              onChange={() => setRule({ ...rule, revers: !rule.revers, }, )}
            />
          </Field> 
          <Field label="Information threshold"  disabled={!rule.showRule}>
            <Input
              value={rule.numberThreshold?.information?.toString() ?? ''}
              placeholder="1"
              onChange={(e) => setRule({ ...rule, numberThreshold: { ...rule.numberThreshold, information: e.currentTarget.value.match(/^[\d.]*$/) ? e.currentTarget.value : rule.numberThreshold?.information ?? null,  }, }) }
            />
          </Field>
          <Field label="Warning threshold"  disabled={!rule.showRule}>
            <Input
              value={rule.numberThreshold?.warning?.toString() ?? ''}
              placeholder="2"
              onChange={(e) => setRule({ ...rule, numberThreshold: { ...rule.numberThreshold, warning: e.currentTarget.value.match(/^[\d.]*$/) ? e.currentTarget.value : rule.numberThreshold?.warning ?? null,  }, }) }
            />
          </Field>                    
          <Field label="Average threshold"  disabled={!rule.showRule}>
            <Input
              value={rule.numberThreshold?.average?.toString() ?? ''}
              placeholder="3"
              onChange={(e) => setRule({ ...rule, numberThreshold: { ...rule.numberThreshold, average: e.currentTarget.value.match(/^[\d.]*$/) ? e.currentTarget.value : rule.numberThreshold?.average ?? null,  }, }) }
            />
          </Field>
          <Field label="High threshold"  disabled={!rule.showRule}>
            <Input
              value={rule.numberThreshold?.high?.toString() ?? ''}
              placeholder="4"
              onChange={(e) => setRule({ ...rule, numberThreshold: { ...rule.numberThreshold, high: e.currentTarget.value.match(/^[\d.]*$/) ? e.currentTarget.value : rule.numberThreshold?.high ?? null,  }, }) }
            />
          </Field>
          <Field label="Disaster threshold" disabled={!rule.showRule}>
            <Input
              value={rule.numberThreshold?.disaster ?? ''}
              placeholder="5"
              onChange={(e) => setRule({ ...rule, numberThreshold: { ...rule.numberThreshold, disaster: e.currentTarget.value.match(/^[\d.]*$/) ? e.currentTarget.value : rule.numberThreshold?.disaster ?? null, }, }) }
              type="text"
              onKeyDown={ e => ( e.keyCode === 69 || e.keyCode === 190 ) && e.preventDefault() }
            />
          </Field>
          </>  
          ) : null }
          { rule.displayMode === 'string' ? (
          <>
          <Field
            label="Show only on Threshold"
            disabled={!rule.showRule}
          >
            <Switch
              transparent={true}
              value={rule.showOnlyOnThreshold}
              disabled={!rule.showRule}
              onChange={() => setRule({ ...rule, showOnlyOnThreshold: !rule.showOnlyOnThreshold, }, )}
            />
          </Field>  

          <Field label="Information threshold" disabled={!rule.showRule}>
            <Input
              value={rule.stringThreshold?.information}
              placeholder="Information"
              onChange={(e) => setRule({ ...rule, stringThreshold: { ...rule.stringThreshold, information: e.currentTarget.value, }, }) }
            />
          </Field>
          <Field label="Warning threshold"  disabled={!rule.showRule}>
            <Input
              value={rule.stringThreshold?.warning}
              placeholder="Warning"
              onChange={(e) => setRule({ ...rule, stringThreshold: { ...rule.stringThreshold, warning: e.currentTarget.value, }, }) }
            />
          </Field>
          <Field label="Average threshold"  disabled={!rule.showRule}>
            <Input
              value={rule.stringThreshold?.average}
              placeholder="Average"
              onChange={(e) => setRule({ ...rule, stringThreshold: { ...rule.stringThreshold, average: e.currentTarget.value, }, }) }
            />
          </Field>
          <Field label="High threshold"  disabled={!rule.showRule}>
            <Input
              value={rule.stringThreshold?.high}
              placeholder="High"
              onChange={(e) => setRule({ ...rule, stringThreshold: { ...rule.stringThreshold, high: e.currentTarget.value, }, }) }
            />
          </Field>
          <Field label="Disaster threshold"  disabled={!rule.showRule}>
            <Input
              value={rule.stringThreshold?.disaster}
              placeholder="Disaster"
              onChange={(e) => setRule({ ...rule, stringThreshold: { ...rule.stringThreshold, disaster: e.currentTarget.value, }, }) }
            />
          </Field>
          </>  
          ) : null }
          { rule.displayMode === 'show' ? (
            <>
              <Field label="Use logical expressions" disabled={!rule.showRule}>
                <Switch
                  transparent={true}
                  value={rule.logicExpress}
                  disabled={!rule.showRule}
                  onChange={() => setRule({ ...rule, logicExpress: !rule.logicExpress })}
                ></Switch>
              </Field>
            
              { rule.logicExpress ? (
                <>
                  <Field
                    label="Logical Mode"
                    disabled={!rule.showRule}
                  >
                    <Select
                      menuShouldPortal={true}
                      value={logicalMode}
                      onChange={(v) => {
                        setLogicalMode(v);
                        setRule({ ...rule, logicalMode: v.value });
                      }}
                      options={LogicalModes}
                    />
                  </Field>
                  <Field label="Value" disabled={!rule.showRule}>
                    <Input
                      value={rule.logicExpressValue}
                      placeholder="100500"
                      onChange={(e) => setRule({ ...rule, logicExpressValue: e.currentTarget.value }) }
                    />
                  </Field>
                </>
              ) : null }
            </>
          ) : null }
 
          {/* Field Formatting Options */}
          <Field label="Use Custom Formatting" description="Apply custom formatting to this metric" disabled={!rule.showRule}>
            <Switch
              transparent={true}
              value={rule.useCustomFormatting}
              disabled={!rule.showRule}
              onChange={() => setRule({ ...rule, useCustomFormatting: !rule.useCustomFormatting })}
            />
          </Field>

          {rule.useCustomFormatting ? (
            <>
              <Field label="Unit Format" description="Format for displaying values" disabled={!rule.showRule}>
                <Select
                  menuShouldPortal={true}
                  options={UnitFormatOptions}
                  value={UnitFormatOptions.find(option => option.value === rule.unitFormat) || UnitFormatOptions[0]}
                  onChange={(v) => setRule({ ...rule, unitFormat: v.value })}
                  placeholder="Select unit format"
                />
              </Field>
              <Field label="Decimals" description="Number of decimal places to show" disabled={!rule.showRule}>
                <Input
                  value={rule.decimals !== undefined ? rule.decimals.toString() : ''}
                  type="number"
                  placeholder="Auto"
                  min={0}
                  max={20}
                  onChange={(e) => {
                    const value = e.currentTarget.value;
                    const decimals = value !== '' ? parseInt(value, 10) : undefined;
                    setRule({ ...rule, decimals: decimals });
                  }}
                />
              </Field>
            </>
          ) : null}

        </FieldSet>          
      </Card.Meta>
      <Card.Actions>
        <IconButton key="moveUp" name="arrow-up" tooltip="Move Up" onClick={moveUp} />
        <IconButton key="moveDown" name="arrow-down" tooltip="Move Down" onClick={moveDown} />
        <IconButton
          key="showRule"
          name={rule.showRule ? visibleIcon : hiddenIcon}
          tooltip="Hide/Show Rule"
          onClick={() => setRule({ ...rule, showRule: !rule.showRule })}
        />
        <IconButton key="copyRule" name="copy" tooltip="Duplicate" onClick={createDuplicate} />
        <IconButton
          key="deleteRule"
          variant="destructive"
          name="trash-alt"
          tooltip="Delete Rule"
          onClick={removeItem}
        />
      </Card.Actions>
    </Card>
  );
};

import React from 'react';
import { Button, ColorPicker, IconButton, Input, useStyles2 } from '@grafana/ui';
import { css } from '@emotion/css';
import { ThresholdItem } from './types';
import { GrafanaTheme2 } from '@grafana/data';

interface ThresholdEditorProps {
    thresholds: ThresholdItem[];
    onChange: (thresholds: ThresholdItem[]) => void;
}

export const ThresholdEditor: React.FC<ThresholdEditorProps> = ({ thresholds, onChange }) => {
    const styles = useStyles2(getStyles);

    const addThreshold = () => {
        const nextOrder = thresholds.length > 0
            ? Math.max(...thresholds.map(t => t.order)) + 1
            : 0;

        const newThreshold: ThresholdItem = {
            name: `threshold${nextOrder}`,
            value: '',
            color: 'rgb(50, 116, 217)',
            textColor: '#ffffff', // Default to white text
            order: nextOrder,
        }; onChange([...thresholds, newThreshold]);
    };

    const removeThreshold = (index: number) => {
        const updatedThresholds = [...thresholds];
        updatedThresholds.splice(index, 1);
        onChange(updatedThresholds);
    };

    const updateThreshold = (index: number, field: keyof ThresholdItem, value: any) => {
        const updatedThresholds = [...thresholds];
        updatedThresholds[index] = { ...updatedThresholds[index], [field]: value };
        onChange(updatedThresholds);
    };

    const moveThreshold = (index: number, direction: 'up' | 'down') => {
        if ((direction === 'up' && index === 0) ||
            (direction === 'down' && index === thresholds.length - 1)) {
            return;
        }

        const updatedThresholds = [...thresholds];
        const swapIndex = direction === 'up' ? index - 1 : index + 1;

        // Swap positions
        [updatedThresholds[index], updatedThresholds[swapIndex]] =
            [updatedThresholds[swapIndex], updatedThresholds[index]];

        // Update order values
        updatedThresholds[index].order = index;
        updatedThresholds[swapIndex].order = swapIndex;

        onChange(updatedThresholds);
    };

    return (
        <div>
            <h4>Custom Thresholds</h4>
            <div className={styles.thresholdList}>
                {thresholds.map((threshold, index) => (
                    <div key={`threshold-${index}`} className={styles.thresholdRow}>
                        <div className={styles.horizontalGroup}>
                            <Input
                                placeholder="Name"
                                value={threshold.name}
                                onChange={e => updateThreshold(index, 'name', e.currentTarget.value)}
                                width={15}
                            />
                            <Input
                                placeholder="Value"
                                value={threshold.value}
                                onChange={e => updateThreshold(index, 'value', e.currentTarget.value)}
                                width={15}
                            />
                            <div className={styles.colorPickerContainer}>
                                <label>Background:</label>
                                <ColorPicker
                                    color={threshold.color}
                                    onChange={color => updateThreshold(index, 'color', color)}
                                />
                            </div>
                            <div className={styles.colorPickerContainer}>
                                <label>Text:</label>
                                <ColorPicker
                                    color={threshold.textColor || '#080808'}
                                    onChange={color => updateThreshold(index, 'textColor', color)}
                                />
                            </div>
                            <IconButton name="arrow-up" onClick={() => moveThreshold(index, 'up')} />
                            <IconButton name="arrow-down" onClick={() => moveThreshold(index, 'down')} />
                            <IconButton name="trash-alt" onClick={() => removeThreshold(index)} />
                        </div>
                    </div>
                ))}
            </div>
            <Button variant="secondary" icon="plus" onClick={addThreshold} className={styles.addButton}>
                Add Threshold
            </Button>
        </div>
    );
};

const getStyles = (theme: GrafanaTheme2) => {
    return {
        thresholdList: css`
      margin-bottom: ${theme.spacing(2)};
    `,
        thresholdRow: css`
      margin-bottom: ${theme.spacing(1)};
      padding: ${theme.spacing(1)};
      border-radius: ${theme.shape.borderRadius()};
      background: ${theme.colors.background.secondary};
    `,
        horizontalGroup: css`
      display: flex;
      flex-direction: row;
      align-items: center;
      gap: ${theme.spacing(1)};
    `,
        addButton: css`
      margin-top: ${theme.spacing(1)};
    `,
        colorPickerContainer: css`
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      
      label {
        font-size: 0.8rem;
        margin-bottom: 2px;
      }
    `,
    };
};

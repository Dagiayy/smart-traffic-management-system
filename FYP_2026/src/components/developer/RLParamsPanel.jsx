import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Slider } from '@/components/ui/slider';
import { Label } from '@/components/ui/label';
import { useSimulation } from '@/lib/SimulationContext';

function ParamSlider({ label, paramKey, min, max, step = 0.01, section = 'rlParams' }) {
  const { state, dispatch } = useSimulation();
  const value = state[section][paramKey];

  return (
    <div className="space-y-1.5">
      <div className="flex justify-between items-center">
        <Label className="text-[10px] text-muted-foreground font-medium">{label}</Label>
        <span className="text-[10px] font-mono text-foreground bg-muted px-1.5 py-0.5 rounded">{value}</span>
      </div>
      <Slider
        min={min}
        max={max}
        step={step}
        value={[value]}
        onValueChange={([v]) => dispatch({
          type: section === 'rlParams' ? 'SET_RL_PARAM' : 'SET_FIXED_TIMING',
          payload: { key: paramKey, value: parseFloat(v.toFixed(2)) }
        })}
        className="h-1"
      />
    </div>
  );
}

export default function RLParamsPanel() {
  return (
    <div className="space-y-3">
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">State Weights</CardTitle>
          <p className="text-[10px] text-muted-foreground">How much each factor influences the RL state</p>
        </CardHeader>
        <CardContent className="px-4 pb-4 space-y-3">
          <ParamSlider label="Vehicle Count Weight" paramKey="stateWeightVehicles" min={0} max={1} />
          <ParamSlider label="Queue Length Weight" paramKey="stateWeightQueue" min={0} max={1} />
          <ParamSlider label="Wait Time Weight" paramKey="stateWeightWait" min={0} max={1} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Reward Weights</CardTitle>
          <p className="text-[10px] text-muted-foreground">How the agent scores its performance</p>
        </CardHeader>
        <CardContent className="px-4 pb-4 space-y-3">
          <ParamSlider label="Wait Reduction Reward" paramKey="rewardWaitReduction" min={0} max={1} />
          <ParamSlider label="Throughput Reward" paramKey="rewardThroughput" min={0} max={1} />
          <ParamSlider label="Queue Reduction Reward" paramKey="rewardQueueReduction" min={0} max={1} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Signal Timing Constraints</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4 space-y-3">
          <ParamSlider label="Min Green Time (s)" paramKey="minGreenTime" min={4} max={20} step={1} />
          <ParamSlider label="Max Green Time (s)" paramKey="maxGreenTime" min={20} max={90} step={1} />
          <ParamSlider label="Yellow Duration (s)" paramKey="yellowDuration" min={2} max={6} step={1} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Fixed-Time Baseline</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4 space-y-3">
          <ParamSlider label="Fixed Green Duration (s)" paramKey="greenDuration" min={10} max={60} step={1} section="fixedTiming" />
          <ParamSlider label="Fixed Yellow Duration (s)" paramKey="yellowDuration" min={2} max={6} step={1} section="fixedTiming" />
        </CardContent>
      </Card>
    </div>
  );
}
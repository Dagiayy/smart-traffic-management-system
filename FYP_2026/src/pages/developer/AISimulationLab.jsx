import React from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import IntersectionCanvas from '@/components/intersection/IntersectionCanvas';
import LaneStatusGrid from '@/components/shared/LaneStatusGrid';
import DebugPanel from '@/components/developer/DebugPanel';
import { WaitTimeChart, QueueLengthChart } from '@/components/shared/SimulationChart';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Brain, Play, Pause, RotateCcw, Zap, Clock } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';
import PedestrianPanel from '@/components/shared/PedestrianPanel';

export default function AISimulationLab() {
  const { state, dispatch, startSimulation, pauseSimulation, resetSimulation } = useSimulation();
  const setMode = (m) => dispatch({ type: 'SET_MODE', payload: m });

  const avgWait = (LANES.reduce((s, l) => s + state.lanes[l].waitTime, 0) / 4).toFixed(1);
  const avgQueue = (LANES.reduce((s, l) => s + state.lanes[l].queue, 0) / 4).toFixed(1);

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <Brain className="w-5 h-5 text-violet-500" />
          <h1 className="text-xl font-bold">AI Simulation Lab</h1>
          <Badge variant="outline" className="text-[10px] border-violet-400 text-violet-500">RL Engine Active</Badge>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <Button size="sm" className="h-8 text-xs" onClick={startSimulation} disabled={state.running}><Play className="w-3 h-3 mr-1" />Start</Button>
          <Button size="sm" variant="outline" className="h-8 text-xs" onClick={pauseSimulation} disabled={!state.running}><Pause className="w-3 h-3 mr-1" />Pause</Button>
          <Button size="sm" variant="outline" className="h-8 text-xs" onClick={resetSimulation}><RotateCcw className="w-3 h-3 mr-1" />Reset</Button>
          <div className="h-5 w-px bg-border" />
          <Button size="sm" variant={state.mode === 'rl' ? 'default' : 'outline'} className="h-8 text-xs" onClick={() => setMode('rl')}><Zap className="w-3 h-3 mr-1" />RL</Button>
          <Button size="sm" variant={state.mode === 'fixed' ? 'default' : 'outline'} className="h-8 text-xs" onClick={() => setMode('fixed')}><Clock className="w-3 h-3 mr-1" />Fixed</Button>
        </div>
      </div>

      {/* Stats bar */}
      <div className="grid grid-cols-4 gap-2 rounded-xl border border-border bg-card p-3">
        {[
          { label: 'Tick', value: state.tick },
          { label: 'Avg Wait', value: `${avgWait}s` },
          { label: 'Avg Queue', value: avgQueue },
          { label: 'Total Reward', value: state.metrics.totalReward.toFixed(1) },
        ].map(item => (
          <div key={item.label} className="text-center">
            <p className="text-[9px] text-muted-foreground uppercase tracking-wide">{item.label}</p>
            <p className="text-sm font-bold font-mono text-foreground">{item.value}</p>
          </div>
        ))}
      </div>

      {/* Main Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        <div className="lg:col-span-4 flex flex-col items-center gap-3">
          <Card className="w-full">
            <CardHeader className="pb-2 pt-4 px-4">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-semibold">Live Intersection</CardTitle>
                <div className="flex items-center gap-1.5">
                  <div className={`w-2 h-2 rounded-full ${state.running ? 'bg-green-500 animate-pulse' : 'bg-muted-foreground'}`} />
                  <span className="text-[10px] font-mono text-muted-foreground">{state.running ? 'Running' : 'Paused'}</span>
                </div>
              </div>
            </CardHeader>
            <CardContent className="px-4 pb-4 flex justify-center">
              <IntersectionCanvas />
            </CardContent>
          </Card>
          <LaneStatusGrid />
        </div>

        <div className="lg:col-span-4">
          <DebugPanel />
        </div>

        <div className="lg:col-span-4 space-y-3">
          <WaitTimeChart />
          <QueueLengthChart />
          <PedestrianPanel />
        </div>
      </div>
    </div>
  );
}
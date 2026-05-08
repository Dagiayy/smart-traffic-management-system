import React from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import IntersectionCanvas from '@/components/intersection/IntersectionCanvas';
import AdminControls from '@/components/admin/AdminControls';
import LaneStatusGrid from '@/components/shared/LaneStatusGrid';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { TrafficCone, Zap } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';
import PedestrianPanel from '@/components/shared/PedestrianPanel';

export default function LiveTrafficControl() {
  const { state } = useSimulation();

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <TrafficCone className="w-5 h-5 text-orange-500" />
        <h1 className="text-xl font-bold text-foreground">Live Traffic Control</h1>
        <Badge variant={state.running ? 'default' : 'secondary'} className="text-[10px]">
          {state.running ? '● Live' : '⏸ Paused'}
        </Badge>
        <Badge variant="outline" className="text-[10px]">
          {state.mode === 'rl' ? <><Zap className="w-3 h-3 mr-1 inline" />RL Adaptive</> : 'Fixed-Time'}
        </Badge>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Intersection canvas */}
        <div className="lg:col-span-1 flex flex-col items-center gap-3">
          <Card className="w-full">
            <CardHeader className="pb-2 pt-4 px-4">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-semibold">4-Way Intersection</CardTitle>
                <span className="text-[10px] font-mono text-muted-foreground">Phase {state.currentPhase + 1}/2 · T={state.phaseTimer}s</span>
              </div>
            </CardHeader>
            <CardContent className="px-4 pb-4 flex justify-center">
              <IntersectionCanvas />
            </CardContent>
          </Card>
          {/* Signal status */}
          <Card className="w-full">
            <CardHeader className="pb-2 pt-4 px-4">
              <CardTitle className="text-sm font-semibold">Signal Status</CardTitle>
            </CardHeader>
            <CardContent className="px-4 pb-4">
              <div className="grid grid-cols-2 gap-2">
                {LANES.map(lane => {
                  const sig = state.signals[lane];
                  const colors = { green: 'bg-green-500', yellow: 'bg-yellow-400', red: 'bg-red-500' };
                  const textColors = { green: 'text-green-600', yellow: 'text-yellow-600', red: 'text-red-600' };
                  return (
                    <div key={lane} className="flex items-center gap-2 p-2 rounded-lg bg-muted/40">
                      <div className={`w-3 h-3 rounded-full ${colors[sig]}`} />
                      <span className="text-xs font-medium">{lane}</span>
                      <span className={`text-[10px] font-mono ml-auto ${textColors[sig]}`}>{sig.toUpperCase()}</span>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Lane Status */}
        <div className="lg:col-span-1">
          <LaneStatusGrid />
        </div>

        {/* Admin Controls */}
        <div className="lg:col-span-1 space-y-4">
          <AdminControls />
          <PedestrianPanel />
        </div>
      </div>
    </div>
  );
}
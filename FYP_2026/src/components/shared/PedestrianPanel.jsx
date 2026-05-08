import React from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { LANES } from '@/lib/simulationEngine';
import { Zap } from 'lucide-react';

const LANE_ICONS = { North: '⬆', South: '⬇', East: '➡', West: '⬅' };

export default function PedestrianPanel() {
  const { state } = useSimulation();
  const peds = state.pedestrians || {};
  const isRL = state.mode === 'rl';

  const totalPeds = LANES.reduce((s, l) => s + (peds[l]?.count || 0), 0);
  const crossing = LANES.filter(l => peds[l]?.crossing).length;
  const avgWait = (LANES.reduce((s, l) => s + (peds[l]?.waitTime || 0), 0) / 4).toFixed(1);

  return (
    <Card>
      <CardHeader className="pb-2 pt-4 px-4">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold flex items-center gap-2">
            <span className="text-lg">🚶</span> Pedestrian Analysis
            {isRL && (
              <span className="flex items-center gap-0.5 text-[9px] bg-violet-100 text-violet-700 px-1.5 py-0.5 rounded-full font-semibold border border-violet-200">
                <Zap className="w-2.5 h-2.5" /> RL
              </span>
            )}
          </CardTitle>
          <div className="flex items-center gap-3 text-[10px] text-muted-foreground font-mono">
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-sky-500 inline-block" />
              {totalPeds} waiting
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-green-500 inline-block animate-pulse" />
              {crossing} crossing
            </span>
          </div>
        </div>
      </CardHeader>
      <CardContent className="px-4 pb-4 space-y-2">
        {/* Summary row */}
        <div className="grid grid-cols-3 gap-2 mb-3">
          {[
            { label: 'Total Waiting', value: totalPeds, color: 'text-sky-500' },
            { label: 'Active Crossings', value: crossing, color: 'text-green-500' },
            { label: 'Avg Wait (s)', value: avgWait, color: 'text-amber-500' },
          ].map(item => (
            <div key={item.label} className="rounded-lg bg-muted/50 p-2 text-center">
              <p className="text-[9px] text-muted-foreground uppercase tracking-wide mb-0.5">{item.label}</p>
              <p className={`text-base font-bold font-mono ${item.color}`}>{item.value}</p>
            </div>
          ))}
        </div>

        {/* Per-lane rows */}
        <div className="space-y-1.5">
          {LANES.map(lane => {
            const ped = peds[lane] || { count: 0, crossing: false, waitTime: 0, crossingSignal: 'red' };
            const sigColor = ped.crossingSignal === 'green' ? 'bg-green-500' : 'bg-red-500';
            const fillRatio = Math.min(ped.count / 15, 1);
            const barColor = fillRatio > 0.6 ? 'bg-red-400' : fillRatio > 0.35 ? 'bg-amber-400' : 'bg-sky-400';

            return (
              <div key={lane} className="flex items-center gap-3 rounded-lg bg-muted/30 px-3 py-2">
                <span className="text-[11px] text-muted-foreground w-4">{LANE_ICONS[lane]}</span>
                <span className="text-xs font-medium w-11">{lane}</span>
                {/* walk signal dot */}
                <div className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${sigColor} ${ped.crossingSignal === 'green' ? 'animate-pulse' : ''}`} />
                {/* bar */}
                <div className="flex-1 h-2 rounded-full bg-muted overflow-hidden">
                  <div className={`h-full rounded-full transition-all duration-500 ${barColor}`} style={{ width: `${fillRatio * 100}%` }} />
                </div>
                <span className="text-[10px] font-mono text-foreground w-5 text-right">{ped.count}</span>
                <span className="text-[10px] text-muted-foreground w-12 text-right">{ped.waitTime}s wait</span>
                {ped.crossing && (
                  <span className="text-[9px] bg-green-100 text-green-700 px-1.5 py-0.5 rounded-full font-semibold">CROSSING</span>
                )}
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}

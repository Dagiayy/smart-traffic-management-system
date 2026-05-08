import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useSimulation } from '@/lib/SimulationContext';
import { LANES, PHASES, rlDecideGreenTime } from '@/lib/simulationEngine';
import { cn } from '@/lib/utils';

export default function DebugPanel() {
  const { state } = useSimulation();
  const phase = PHASES[state.currentPhase];
  const greenDuration = rlDecideGreenTime(state.lanes, state.rlParams, state.currentPhase);

  return (
    <div className="space-y-3">
      {/* Current RL State */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <div className="flex items-center justify-between">
            <CardTitle className="text-sm font-semibold">Current RL State</CardTitle>
            <Badge variant="outline" className="text-[10px] font-mono">Tick {state.tick}</Badge>
          </div>
        </CardHeader>
        <CardContent className="px-4 pb-4">
          <div className="rounded-lg bg-muted/60 border border-border overflow-hidden">
            <table className="w-full text-[10px]">
              <thead>
                <tr className="border-b border-border bg-muted">
                  <th className="text-left px-2 py-1.5 text-muted-foreground font-semibold">Lane</th>
                  <th className="text-right px-2 py-1.5 text-muted-foreground font-semibold">Vehicles</th>
                  <th className="text-right px-2 py-1.5 text-muted-foreground font-semibold">Queue</th>
                  <th className="text-right px-2 py-1.5 text-muted-foreground font-semibold">Wait(s)</th>
                  <th className="text-right px-2 py-1.5 text-muted-foreground font-semibold">Signal</th>
                </tr>
              </thead>
              <tbody>
                {LANES.map((lane, i) => {
                  const d = state.lanes[lane];
                  const sig = state.signals[lane];
                  return (
                    <tr key={lane} className={cn('border-b border-border/50', i % 2 === 0 ? 'bg-background' : 'bg-muted/30')}>
                      <td className="px-2 py-1.5 font-medium">{lane}</td>
                      <td className="px-2 py-1.5 text-right font-mono">{d.vehicles}</td>
                      <td className="px-2 py-1.5 text-right font-mono">{d.queue}</td>
                      <td className="px-2 py-1.5 text-right font-mono">{d.waitTime}</td>
                      <td className="px-2 py-1.5 text-right">
                        <span className={cn(
                          'font-mono font-bold uppercase',
                          sig === 'green' ? 'text-green-600' : sig === 'yellow' ? 'text-yellow-500' : 'text-red-500'
                        )}>{sig}</span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Selected Action */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Agent Decision</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4 space-y-2">
          <div className="grid grid-cols-2 gap-2">
            <div className="rounded-lg bg-muted/60 border border-border p-3">
              <p className="text-[9px] text-muted-foreground uppercase tracking-wide mb-1">Current Phase</p>
              <p className="text-xs font-mono font-bold">{phase.green.join(' + ')}</p>
              <p className="text-[9px] text-muted-foreground">Green lanes</p>
            </div>
            <div className="rounded-lg bg-muted/60 border border-border p-3">
              <p className="text-[9px] text-muted-foreground uppercase tracking-wide mb-1">Decided Green Time</p>
              <p className="text-xl font-mono font-bold text-primary">{greenDuration}s</p>
              <p className="text-[9px] text-muted-foreground">RL-computed duration</p>
            </div>
          </div>
          <div className="rounded-lg bg-muted/60 border border-border p-3">
            <p className="text-[9px] text-muted-foreground uppercase tracking-wide mb-1">Phase Timer</p>
            <div className="flex items-center gap-2">
              <div className="flex-1 h-2 bg-secondary rounded-full overflow-hidden">
                <div
                  className="h-full bg-primary rounded-full transition-all duration-500"
                  style={{ width: `${Math.min((state.phaseTimer / greenDuration) * 100, 100)}%` }}
                />
              </div>
              <span className="font-mono text-xs">{state.phaseTimer}/{greenDuration}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Reward Stats */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Cumulative Reward</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4">
          <div className="grid grid-cols-2 gap-2">
            <div className="rounded-lg bg-primary/5 border border-primary/20 p-3 text-center">
              <p className="text-[9px] text-muted-foreground mb-1">Total Reward</p>
              <p className="text-lg font-mono font-bold text-primary">{state.metrics.totalReward.toFixed(1)}</p>
            </div>
            <div className="rounded-lg bg-muted/60 border border-border p-3 text-center">
              <p className="text-[9px] text-muted-foreground mb-1">Last Reward</p>
              <p className="text-lg font-mono font-bold">
                {state.metrics.rewardHistory[state.metrics.rewardHistory.length - 1]?.toFixed(2) ?? '—'}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
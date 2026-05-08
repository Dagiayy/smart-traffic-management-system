import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useSimulation } from '@/lib/SimulationContext';
import { LANES } from '@/lib/simulationEngine';
import { cn } from '@/lib/utils';

const SIGNAL_STYLE = {
  green: 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]',
  yellow: 'bg-yellow-400 shadow-[0_0_8px_rgba(234,179,8,0.6)]',
  red: 'bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.6)]',
};

export default function LaneStatusGrid() {
  const { state } = useSimulation();

  return (
    <Card>
      <CardHeader className="pb-2 pt-4 px-4">
        <CardTitle className="text-sm font-semibold">Lane Status</CardTitle>
      </CardHeader>
      <CardContent className="px-4 pb-4 grid grid-cols-2 gap-2">
        {LANES.map(lane => {
          const data = state.lanes[lane];
          const signal = state.signals[lane];
          const queueRatio = data.queue / 20;
          const isEmergency = state.emergency === lane;

          return (
            <div
              key={lane}
              className={cn(
                'rounded-lg border p-3 transition-all',
                isEmergency ? 'border-destructive bg-destructive/5' : 'border-border bg-muted/30'
              )}
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold text-foreground">{lane}</span>
                <div className="flex items-center gap-1.5">
                  {isEmergency && <span className="text-[9px] text-destructive font-bold">EMRG</span>}
                  <div className={cn('w-2.5 h-2.5 rounded-full', SIGNAL_STYLE[signal])} />
                  <span className={cn(
                    'text-[10px] font-mono uppercase font-semibold',
                    signal === 'green' ? 'text-green-600' : signal === 'yellow' ? 'text-yellow-600' : 'text-red-600'
                  )}>{signal}</span>
                </div>
              </div>

              <div className="space-y-1.5">
                <div className="flex justify-between text-[10px] text-muted-foreground">
                  <span>Vehicles</span>
                  <span className="font-mono text-foreground">{data.vehicles}</span>
                </div>
                <div className="flex justify-between text-[10px] text-muted-foreground">
                  <span>Queue</span>
                  <span className="font-mono text-foreground">{data.queue}</span>
                </div>
                {/* Queue bar */}
                <div className="w-full h-1.5 bg-secondary rounded-full overflow-hidden">
                  <div
                    className={cn(
                      'h-full rounded-full transition-all duration-500',
                      queueRatio > 0.7 ? 'bg-destructive' : queueRatio > 0.4 ? 'bg-warning' : 'bg-success'
                    )}
                    style={{ width: `${queueRatio * 100}%` }}
                  />
                </div>
                <div className="flex justify-between text-[10px] text-muted-foreground">
                  <span>Wait</span>
                  <span className="font-mono text-foreground">{data.waitTime}s</span>
                </div>
              </div>
            </div>
          );
        })}
      </CardContent>
    </Card>
  );
}
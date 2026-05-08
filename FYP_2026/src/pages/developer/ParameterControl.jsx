import React from 'react';
import RLParamsPanel from '@/components/developer/RLParamsPanel';
import DebugPanel from '@/components/developer/DebugPanel';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { SlidersHorizontal } from 'lucide-react';
import { useSimulation } from '@/lib/SimulationContext';

export default function ParameterControl() {
  const { state } = useSimulation();

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <SlidersHorizontal className="w-5 h-5 text-violet-500" />
        <h1 className="text-xl font-bold">Parameter Control Panel</h1>
        <Badge variant="outline" className="text-[10px] border-violet-400 text-violet-500">RL Config</Badge>
      </div>

      {/* Current Params Summary */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Active RL Parameter Summary</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4">
          <div className="grid grid-cols-3 lg:grid-cols-6 gap-2">
            {Object.entries(state.rlParams).map(([key, val]) => (
              <div key={key} className="rounded-lg bg-muted/50 border border-border p-2 text-center">
                <p className="text-[8px] text-muted-foreground uppercase leading-tight mb-0.5">{key.replace(/([A-Z])/g, ' $1').replace('rl', '').trim()}</p>
                <p className="text-sm font-mono font-bold text-foreground">{val}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <RLParamsPanel />
        <DebugPanel />
      </div>
    </div>
  );
}
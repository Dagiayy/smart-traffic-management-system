import React from 'react';
import { useMutation } from '@tanstack/react-query';
import RLParamsPanel from '@/components/developer/RLParamsPanel';
import DebugPanel from '@/components/developer/DebugPanel';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { SlidersHorizontal, Upload } from 'lucide-react';
import { useSimulation } from '@/lib/SimulationContext';
import { devApi } from '@/api/developer';
import toast from 'react-hot-toast';

export default function ParameterControl() {
  const { state } = useSimulation();

  const syncMutation = useMutation({
    mutationFn: () => devApi.updateRLParams(state.rlParams),
    onSuccess: () => toast.success('RL params pushed to backend AI session'),
    onError: () => toast.error('No active session to push params to'),
  });

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <SlidersHorizontal className="w-5 h-5 text-violet-500" />
          <h1 className="text-xl font-bold">Parameter Control Panel</h1>
          <Badge variant="outline" className="text-[10px] border-violet-400 text-violet-500">RL Config</Badge>
        </div>
        <Button size="sm" className="h-8 text-xs bg-violet-600 hover:bg-violet-700"
          onClick={() => syncMutation.mutate()}
          disabled={syncMutation.isPending}>
          <Upload className="w-3 h-3 mr-1" />
          {syncMutation.isPending ? 'Pushing…' : 'Push to Backend Session'}
        </Button>
      </div>

      {/* Current params summary */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Active RL Parameter Summary</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4">
          <div className="grid grid-cols-3 lg:grid-cols-6 gap-2">
            {Object.entries(state.rlParams).map(([key, val]) => (
              <div key={key} className="rounded-lg bg-muted/50 border border-border p-2 text-center">
                <p className="text-[8px] text-muted-foreground uppercase leading-tight mb-0.5">
                  {key.replace(/([A-Z])/g, ' $1').replace('rl', '').trim()}
                </p>
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

import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useSimulation } from '@/lib/SimulationContext';
import IntersectionCanvas from '@/components/intersection/IntersectionCanvas';
import AdminControls from '@/components/admin/AdminControls';
import LaneStatusGrid from '@/components/shared/LaneStatusGrid';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { TrafficCone, Zap, MapPin, RefreshCw } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';
import PedestrianPanel from '@/components/shared/PedestrianPanel';
import { trafficApi } from '@/api/admin';
import { openTrafficChannel } from '@/api/websocket';
import toast from 'react-hot-toast';

export default function LiveTrafficControl() {
  const { state, dispatch } = useSimulation();
  const queryClient = useQueryClient();
  const [selectedIntersection, setSelectedIntersection] = useState(null);
  const [liveSignals, setLiveSignals] = useState({});

  const { data: intersectionsData } = useQuery({
    queryKey: ['admin-intersections'],
    queryFn: () => trafficApi.intersections().then(r => r.data),
    staleTime: 60000,
  });

  const intersections = intersectionsData?.results ?? [];

  // Open WS for the selected intersection
  useEffect(() => {
    if (!selectedIntersection) return;
    const ws = openTrafficChannel(selectedIntersection.id, (msg) => {
      if (msg.type === 'signal_update') {
        setLiveSignals(prev => ({
          ...prev,
          [msg.data.phase]: msg.data,
        }));
      }
    });
    return () => ws.close();
  }, [selectedIntersection]);

  const overrideMutation = useMutation({
    mutationFn: ({ id, phase, duration, reason }) =>
      trafficApi.manualOverride(id, { phase, duration_seconds: duration, reason }),
    onSuccess: () => {
      toast.success('Signal override applied');
      queryClient.invalidateQueries({ queryKey: ['admin-intersections'] });
    },
    onError: () => toast.error('Override failed'),
  });

  const releaseMutation = useMutation({
    mutationFn: (id) => trafficApi.releaseOverride(id),
    onSuccess: () => toast.success('Override released — AI control restored'),
  });

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2 flex-wrap">
        <TrafficCone className="w-5 h-5 text-orange-500" />
        <h1 className="text-xl font-bold text-foreground">Live Traffic Control</h1>
        <Badge variant={state.running ? 'default' : 'secondary'} className="text-[10px]">
          {state.running ? '● Sim Running' : '⏸ Sim Paused'}
        </Badge>
        <Badge variant="outline" className="text-[10px]">
          {state.mode === 'rl' ? <><Zap className="w-3 h-3 mr-1 inline" />RL Adaptive</> : 'Fixed-Time'}
        </Badge>
        {selectedIntersection && (
          <Badge className="text-[10px] bg-blue-600">
            <MapPin className="w-3 h-3 mr-1 inline" />{selectedIntersection.name}
          </Badge>
        )}
      </div>

      {/* Intersection selector */}
      {intersections.length > 0 && (
        <Card>
          <CardHeader className="pb-2 pt-3 px-4">
            <div className="flex items-center justify-between">
              <CardTitle className="text-sm font-semibold">Select Intersection</CardTitle>
              <Button size="sm" variant="ghost" className="h-7 text-xs"
                onClick={() => queryClient.invalidateQueries({ queryKey: ['admin-intersections'] })}>
                <RefreshCw className="w-3 h-3 mr-1" /> Refresh
              </Button>
            </div>
          </CardHeader>
          <CardContent className="px-4 pb-3">
            <div className="flex flex-wrap gap-2">
              {intersections.slice(0, 8).map(intr => (
                <button key={intr.id}
                  onClick={() => setSelectedIntersection(intr)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-all ${selectedIntersection?.id === intr.id ? 'bg-primary text-white border-primary' : 'border-border hover:border-primary/50'}`}>
                  {intr.name}
                  {intr.current_signal && (
                    <span className={`ml-1.5 w-2 h-2 rounded-full inline-block ${intr.current_signal.source === 'ADMIN_OVERRIDE' ? 'bg-red-500' : intr.current_signal.source === 'AI' ? 'bg-green-500' : 'bg-gray-400'}`} />
                  )}
                </button>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Main layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Intersection canvas (simulation) */}
        <div className="lg:col-span-1 flex flex-col items-center gap-3">
          <Card className="w-full">
            <CardHeader className="pb-2 pt-4 px-4">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-semibold">4-Way Simulation</CardTitle>
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

        <div className="lg:col-span-1">
          <LaneStatusGrid />
          {/* Backend intersection details */}
          {selectedIntersection && (
            <Card className="mt-3">
              <CardHeader className="pb-2 pt-4 px-4">
                <CardTitle className="text-sm font-semibold">Backend Override</CardTitle>
              </CardHeader>
              <CardContent className="px-4 pb-4 space-y-2">
                <p className="text-xs text-muted-foreground">Override signal at <strong>{selectedIntersection.name}</strong></p>
                <div className="grid grid-cols-2 gap-2">
                  {['NS_GREEN', 'EW_GREEN'].map(phase => (
                    <Button key={phase} size="sm" variant="outline" className="h-8 text-xs"
                      disabled={overrideMutation.isPending}
                      onClick={() => overrideMutation.mutate({
                        id: selectedIntersection.id,
                        phase,
                        duration: 60,
                        reason: `Admin override via dashboard`,
                      })}>
                      {phase.replace('_', ' ')}
                    </Button>
                  ))}
                </div>
                <Button size="sm" variant="destructive" className="w-full h-7 text-xs"
                  disabled={releaseMutation.isPending}
                  onClick={() => releaseMutation.mutate(selectedIntersection.id)}>
                  Release Override
                </Button>
              </CardContent>
            </Card>
          )}
        </div>

        <div className="lg:col-span-1 space-y-4">
          <AdminControls />
          <PedestrianPanel />
        </div>
      </div>
    </div>
  );
}

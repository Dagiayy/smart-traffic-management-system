import React, { useEffect, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useSimulation } from '@/lib/SimulationContext';
import IntersectionCanvas from '@/components/intersection/IntersectionCanvas';
import LaneStatusGrid from '@/components/shared/LaneStatusGrid';
import DebugPanel from '@/components/developer/DebugPanel';
import { WaitTimeChart, QueueLengthChart } from '@/components/shared/SimulationChart';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Brain, Play, Pause, RotateCcw, Zap, Clock, Database, Radio } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';
import PedestrianPanel from '@/components/shared/PedestrianPanel';
import { devApi } from '@/api/developer';
import { openAISessionChannel, openAlertsChannel } from '@/api/websocket';
import toast from 'react-hot-toast';

export default function AISimulationLab() {
  const { state, dispatch, startSimulation, pauseSimulation, resetSimulation } = useSimulation();
  const queryClient = useQueryClient();
  const setMode = (m) => dispatch({ type: 'SET_MODE', payload: m });

  const [activeSession, setActiveSession] = useState(null);
  const [liveEpisodes, setLiveEpisodes] = useState([]);
  const [backendAlerts, setBackendAlerts] = useState([]);

  const { data: sessionsData } = useQuery({
    queryKey: ['dev-sessions'],
    queryFn: () => devApi.sessions().then(r => r.data),
    staleTime: 10000,
  });

  const startMutation = useMutation({
    mutationFn: (data) => devApi.startSession(data),
    onSuccess: (res) => {
      const session = res.data;
      setActiveSession(session);
      queryClient.invalidateQueries({ queryKey: ['dev-sessions'] });
      toast.success(`Session "${session.name}" started`);
    },
    onError: () => toast.error('Failed to start session'),
  });

  const stopMutation = useMutation({
    mutationFn: (id) => devApi.stopSession(id),
    onSuccess: () => {
      setActiveSession(null);
      queryClient.invalidateQueries({ queryKey: ['dev-sessions'] });
      toast.success('Session stopped');
    },
  });

  // Live WebSocket for the active session
  useEffect(() => {
    if (!activeSession) return;
    const ws = openAISessionChannel(activeSession.id, (msg) => {
      if (msg.type === 'training_update') {
        setLiveEpisodes(prev => [...prev.slice(-59), msg.data]);
      }
    });
    return () => ws.close();
  }, [activeSession?.id]);

  // Alerts channel
  useEffect(() => {
    const ws = openAlertsChannel((msg) => {
      if (msg.type === 'alert') setBackendAlerts(prev => [msg.data, ...prev].slice(0, 5));
    });
    return () => ws.close();
  }, []);

  const avgWait = (LANES.reduce((s, l) => s + state.lanes[l].waitTime, 0) / 4).toFixed(1);
  const avgQueue = (LANES.reduce((s, l) => s + state.lanes[l].queue, 0) / 4).toFixed(1);
  const sessions = sessionsData?.results ?? [];
  const running = sessions.filter(s => s.status === 'RUNNING');

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <Brain className="w-5 h-5 text-violet-500" />
          <h1 className="text-xl font-bold">AI Simulation Lab</h1>
          <Badge variant="outline" className="text-[10px] border-violet-400 text-violet-500">RL Engine Active</Badge>
          {running.length > 0 && (
            <Badge className="text-[10px] bg-green-600 animate-pulse">
              <Radio className="w-3 h-3 mr-1 inline" />{running.length} Backend Session{running.length > 1 ? 's' : ''} Live
            </Badge>
          )}
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <Button size="sm" className="h-8 text-xs" onClick={startSimulation} disabled={state.running}><Play className="w-3 h-3 mr-1" />Start Sim</Button>
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

      {/* Backend session controls */}
      <Card>
        <CardHeader className="pb-2 pt-3 px-4">
          <div className="flex items-center justify-between">
            <CardTitle className="text-sm font-semibold flex items-center gap-2">
              <Database className="w-4 h-4 text-violet-500" /> Backend AI Sessions
            </CardTitle>
          </div>
        </CardHeader>
        <CardContent className="px-4 pb-3">
          <div className="flex flex-wrap gap-2 mb-3">
            <Button size="sm" className="h-7 text-xs bg-violet-600 hover:bg-violet-700"
              disabled={startMutation.isPending}
              onClick={() => startMutation.mutate({
                name: `Lab Session ${new Date().toLocaleTimeString()}`,
                scenario_id: 'addis_bole',
                config: state.rlParams,
              })}>
              <Play className="w-3 h-3 mr-1" /> Start Backend Session
            </Button>
            {(activeSession || running[0]) && (
              <Button size="sm" variant="outline" className="h-7 text-xs"
                onClick={() => stopMutation.mutate((activeSession ?? running[0]).id)}>
                Stop Session
              </Button>
            )}
          </div>
          {sessions.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {sessions.slice(0, 4).map(s => (
                <div key={s.id} className={`px-3 py-1.5 rounded-lg border text-[10px] font-medium ${s.status === 'RUNNING' ? 'border-green-400 bg-green-50 text-green-700' : 'border-border text-muted-foreground'}`}>
                  {s.name} · {s.status}
                  {s.total_episodes > 0 && ` · ${s.total_episodes} eps`}
                </div>
              ))}
            </div>
          )}
          {backendAlerts.length > 0 && (
            <div className="mt-2 space-y-1">
              {backendAlerts.slice(0, 2).map((a, i) => (
                <div key={i} className="text-[10px] text-amber-700 bg-amber-50 border border-amber-200 px-2 py-1 rounded">
                  ⚠ {a.message ?? JSON.stringify(a)}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Main layout */}
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

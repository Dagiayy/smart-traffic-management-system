import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useSimulation } from '@/lib/SimulationContext';
import MetricCard from '@/components/shared/MetricCard';
import AlertsPanel from '@/components/shared/AlertsPanel';
import LaneStatusGrid from '@/components/shared/LaneStatusGrid';
import { WaitTimeChart, ThroughputChart } from '@/components/shared/SimulationChart';
import { LANES } from '@/lib/simulationEngine';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Timer, Car, TrendingDown, Activity, Play, Pause, RotateCcw, ShieldCheck, Users, DollarSign, AlertTriangle } from 'lucide-react';
import PedestrianPanel from '@/components/shared/PedestrianPanel';
import { dashboardApi } from '@/api/admin';

export default function AdminDashboardPage() {
  const { state, startSimulation, pauseSimulation, resetSimulation } = useSimulation();

  // Real data from Django backend
  const { data: summary } = useQuery({
    queryKey: ['admin-summary'],
    queryFn: () => dashboardApi.summary().then(r => r.data),
    refetchInterval: 30000,
    staleTime: 15000,
  });

  // Simulation-derived metrics (local RL engine)
  const avgWait = (LANES.reduce((s, l) => s + state.lanes[l].waitTime, 0) / 4).toFixed(1);
  const totalVehicles = LANES.reduce((s, l) => s + state.lanes[l].vehicles, 0);
  const totalQueue = LANES.reduce((s, l) => s + state.lanes[l].queue, 0);
  const totalThroughput = LANES.reduce((s, l) => s + state.lanes[l].throughput, 0);
  const peds = state.pedestrians || {};
  const totalPedestrians = LANES.reduce((s, l) => s + (peds[l]?.count || 0), 0);
  const crossingCount = LANES.filter(l => peds[l]?.crossing).length;

  const formatCurrency = (v) => `ETB ${Number(v || 0).toLocaleString()}`;

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-blue-500" />
            <h1 className="text-xl font-bold text-foreground">Traffic Operations Dashboard</h1>
            <Badge variant={state.running ? 'default' : 'secondary'} className="text-[10px]">
              {state.running ? '● Live' : '⏸ Paused'}
            </Badge>
          </div>
          <p className="text-xs text-muted-foreground mt-0.5">Real-time signal monitoring & enforcement overview</p>
        </div>
        <div className="flex items-center gap-2">
          <Button size="sm" className="h-8 text-xs" onClick={startSimulation} disabled={state.running}>
            <Play className="w-3 h-3 mr-1" /> Start Sim
          </Button>
          <Button size="sm" variant="outline" className="h-8 text-xs" onClick={pauseSimulation} disabled={!state.running}>
            <Pause className="w-3 h-3 mr-1" /> Pause
          </Button>
          <Button size="sm" variant="outline" className="h-8 px-2" onClick={resetSimulation}>
            <RotateCcw className="w-3 h-3" />
          </Button>
        </div>
      </div>

      {/* Real backend stats */}
      {summary && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          <Card className="border-blue-100 bg-blue-50/50">
            <CardContent className="pt-4 pb-3 px-4">
              <div className="flex items-center gap-2 mb-1">
                <AlertTriangle className="w-4 h-4 text-blue-500" />
                <p className="text-[10px] text-muted-foreground uppercase tracking-wide">Violations Today</p>
              </div>
              <p className="text-2xl font-bold font-mono text-blue-600">{summary.total_violations_today ?? 0}</p>
              <p className="text-[10px] text-muted-foreground">This week: {summary.total_violations_week ?? 0}</p>
            </CardContent>
          </Card>
          <Card className="border-green-100 bg-green-50/50">
            <CardContent className="pt-4 pb-3 px-4">
              <div className="flex items-center gap-2 mb-1">
                <DollarSign className="w-4 h-4 text-green-500" />
                <p className="text-[10px] text-muted-foreground uppercase tracking-wide">Fines Collected</p>
              </div>
              <p className="text-xl font-bold font-mono text-green-600">{formatCurrency(summary.fines_collected_today)}</p>
              <p className="text-[10px] text-muted-foreground">Total: {formatCurrency(summary.fines_collected_total)}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-4 pb-3 px-4">
              <div className="flex items-center gap-2 mb-1">
                <Users className="w-4 h-4 text-purple-500" />
                <p className="text-[10px] text-muted-foreground uppercase tracking-wide">Active Officers</p>
              </div>
              <p className="text-2xl font-bold font-mono">{summary.active_officers ?? 0}</p>
              <p className="text-[10px] text-muted-foreground">Users: {summary.total_users ?? 0}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-4 pb-3 px-4">
              <div className="flex items-center gap-2 mb-1">
                <Activity className="w-4 h-4 text-orange-500" />
                <p className="text-[10px] text-muted-foreground uppercase tracking-wide">AI Status</p>
              </div>
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${summary.ai_status === 'ACTIVE' ? 'bg-green-500 animate-pulse' : 'bg-gray-400'}`} />
                <p className="text-sm font-bold">{summary.ai_status ?? 'UNKNOWN'}</p>
              </div>
              <p className="text-[10px] text-muted-foreground">Alerts: {summary.alerts_count ?? 0}</p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Simulation KPIs */}
      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3">
        <MetricCard title="Avg Wait Time" value={avgWait} unit="sec" icon={Timer} color="blue" />
        <MetricCard title="Active Vehicles" value={totalVehicles} icon={Car} color="purple" />
        <MetricCard title="Total Queue" value={totalQueue} unit="vehicles" icon={TrendingDown} color={totalQueue > 30 ? 'red' : totalQueue > 15 ? 'yellow' : 'green'} />
        <MetricCard title="Throughput" value={totalThroughput} unit="veh/tick" icon={Activity} color="green" />
        <MetricCard title="Pedestrians" value={totalPedestrians} unit="waiting" icon={Users} color="blue" />
        <MetricCard title="Active Crossings" value={crossingCount} unit="lanes" icon={Users} color={crossingCount > 2 ? 'yellow' : 'green'} />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-1 space-y-3">
          <LaneStatusGrid />
          <AlertsPanel />
          <PedestrianPanel />
        </div>
        <div className="lg:col-span-2 space-y-3">
          <WaitTimeChart />
          <ThroughputChart />
          <Card>
            <CardHeader className="pb-2 pt-4 px-4">
              <CardTitle className="text-sm font-semibold">System Overview</CardTitle>
            </CardHeader>
            <CardContent className="px-4 pb-4">
              <div className="grid grid-cols-3 gap-3">
                {[
                  { label: 'Control Mode', value: state.mode === 'rl' ? 'RL Adaptive' : 'Fixed-Time', accent: state.mode === 'rl' },
                  { label: 'Sim Ticks', value: state.tick },
                  { label: 'Emergency', value: state.emergency || 'None' },
                  { label: 'Total Reward', value: state.metrics.totalReward.toFixed(1) },
                  { label: 'Phase', value: `${state.currentPhase + 1} / 2` },
                  { label: 'Phase Timer', value: `${state.phaseTimer}s` },
                ].map(item => (
                  <div key={item.label} className="rounded-lg bg-muted/50 p-2.5 text-center">
                    <p className="text-[9px] text-muted-foreground uppercase tracking-wide mb-0.5">{item.label}</p>
                    <p className={`text-sm font-bold font-mono ${item.accent ? 'text-primary' : 'text-foreground'}`}>{item.value}</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

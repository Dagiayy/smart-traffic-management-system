import React from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import MetricCard from '@/components/shared/MetricCard';
import AlertsPanel from '@/components/shared/AlertsPanel';
import LaneStatusGrid from '@/components/shared/LaneStatusGrid';
import { WaitTimeChart, ThroughputChart } from '@/components/shared/SimulationChart';
import { LANES } from '@/lib/simulationEngine';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Timer, Car, TrendingDown, Activity, Zap, Play, Pause, RotateCcw, ShieldCheck, Users } from 'lucide-react';
import PedestrianPanel from '@/components/shared/PedestrianPanel';

export default function AdminDashboardPage() {
  const { state, startSimulation, pauseSimulation, resetSimulation } = useSimulation();

  const avgWait = (LANES.reduce((s, l) => s + state.lanes[l].waitTime, 0) / 4).toFixed(1);
  const totalVehicles = LANES.reduce((s, l) => s + state.lanes[l].vehicles, 0);
  const totalQueue = LANES.reduce((s, l) => s + state.lanes[l].queue, 0);
  const totalThroughput = LANES.reduce((s, l) => s + state.lanes[l].throughput, 0);
  const prevWait = state.metrics.waitHistory[state.metrics.waitHistory.length - 2] || avgWait;
  const waitTrend = parseFloat(avgWait) - prevWait;
  const peds = state.pedestrians || {};
  const totalPedestrians = LANES.reduce((s, l) => s + (peds[l]?.count || 0), 0);
  const crossingCount = LANES.filter(l => peds[l]?.crossing).length;

  return (
    <div className="p-6 space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-blue-500" />
            <h1 className="text-xl font-bold text-foreground">Traffic Operations Dashboard</h1>
            <Badge variant={state.running ? 'default' : 'secondary'} className="text-[10px]">
              {state.running ? '● Live' : '⏸ Paused'}
            </Badge>
          </div>
          <p className="text-xs text-muted-foreground mt-0.5">Real-time signal monitoring & operational control</p>
        </div>
        <div className="flex items-center gap-2">
          <Button size="sm" className="h-8 text-xs" onClick={startSimulation} disabled={state.running}>
            <Play className="w-3 h-3 mr-1" /> Start
          </Button>
          <Button size="sm" variant="outline" className="h-8 text-xs" onClick={pauseSimulation} disabled={!state.running}>
            <Pause className="w-3 h-3 mr-1" /> Pause
          </Button>
          <Button size="sm" variant="outline" className="h-8 px-2" onClick={resetSimulation}>
            <RotateCcw className="w-3 h-3" />
          </Button>
        </div>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3">
        <MetricCard title="Avg Wait Time" value={avgWait} unit="sec" icon={Timer} color="blue" trend={-waitTrend} trendLabel={waitTrend > 0 ? 'increasing' : 'improving'} />
        <MetricCard title="Active Vehicles" value={totalVehicles} icon={Car} color="purple" />
        <MetricCard title="Total Queue" value={totalQueue} unit="vehicles" icon={TrendingDown} color={totalQueue > 30 ? 'red' : totalQueue > 15 ? 'yellow' : 'green'} />
        <MetricCard title="Throughput" value={totalThroughput} unit="veh/tick" icon={Activity} color="green" />
        <MetricCard title="Pedestrians" value={totalPedestrians} unit="waiting" icon={Users} color="blue" />
        <MetricCard title="Active Crossings" value={crossingCount} unit="lanes" icon={Users} color={crossingCount > 2 ? 'yellow' : 'green'} />
      </div>

      {/* System Status */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-1 space-y-3">
          <LaneStatusGrid />
          <AlertsPanel />
          <PedestrianPanel />
        </div>
        <div className="lg:col-span-2 space-y-3">
          <WaitTimeChart />
          <ThroughputChart />
          {/* Quick stats */}
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
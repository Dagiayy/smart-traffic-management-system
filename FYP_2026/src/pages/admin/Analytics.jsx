import React from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { WaitTimeChart, QueueLengthChart, ThroughputChart, RewardTrendChart, PedestrianWaitChart, PedestrianCrossingChart } from '@/components/shared/SimulationChart';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { BarChart2, TrendingUp, TrendingDown } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, RadarChart, Radar, PolarGrid, PolarAngleAxis, PolarRadiusAxis } from 'recharts';

export default function Analytics() {
  const { state } = useSimulation();

  const laneData = LANES.map(lane => ({
    lane,
    vehicles: state.lanes[lane].vehicles,
    queue: state.lanes[lane].queue,
    wait: parseFloat(state.lanes[lane].waitTime.toFixed(1)),
    throughput: state.lanes[lane].throughput,
  }));

  const radarData = LANES.map(lane => ({
    lane,
    Pressure: Math.round((state.lanes[lane].vehicles * 0.4 + state.lanes[lane].queue * 0.35 + state.lanes[lane].waitTime * 0.25) * 10) / 10,
  }));

  const avgWait = (LANES.reduce((s, l) => s + state.lanes[l].waitTime, 0) / 4).toFixed(1);
  const efficiency = state.metrics.rewardHistory.length > 0
    ? Math.max(0, Math.min(100, 50 + state.metrics.totalReward * 0.5)).toFixed(1)
    : '—';

  const peds = state.pedestrians || {};
  const totalPeds = LANES.reduce((s, l) => s + (peds[l]?.count || 0), 0);
  const avgPedWait = (LANES.reduce((s, l) => s + (peds[l]?.waitTime || 0), 0) / 4).toFixed(1);
  const activeCrossings = LANES.filter(l => peds[l]?.crossing).length;
  const pedData = LANES.map(lane => ({
    lane,
    waiting: peds[lane]?.count || 0,
    wait: parseFloat((peds[lane]?.waitTime || 0).toFixed(1)),
  }));

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <BarChart2 className="w-5 h-5 text-blue-500" />
        <h1 className="text-xl font-bold">Traffic Analytics</h1>
        <Badge variant="outline" className="text-[10px]">Tick {state.tick}</Badge>
      </div>

      {/* Summary Row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {[
          { label: 'Avg Wait', value: `${avgWait}s`, trend: 'down' },
          { label: 'System Efficiency', value: `${efficiency}%`, trend: 'up' },
          { label: 'Total Throughput', value: LANES.reduce((s, l) => s + state.lanes[l].throughput, 0), trend: 'up' },
          { label: 'Total Reward', value: state.metrics.totalReward.toFixed(1), trend: 'up' },
        ].map(item => (
          <Card key={item.label}>
            <CardContent className="pt-4 pb-3 px-4">
              <div className="flex items-center justify-between mb-1">
                <p className="text-[10px] text-muted-foreground uppercase tracking-wide">{item.label}</p>
                {item.trend === 'up' ? <TrendingUp className="w-3.5 h-3.5 text-green-500" /> : <TrendingDown className="w-3.5 h-3.5 text-red-500" />}
              </div>
              <p className="text-2xl font-bold font-mono text-foreground">{item.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Lane Comparison Bar */}
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">Lane Vehicle & Queue Comparison</CardTitle>
          </CardHeader>
          <CardContent className="px-2 pb-3">
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={laneData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="lane" tick={{ fontSize: 10 }} stroke="hsl(var(--muted-foreground))" />
                <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
                <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
                <Legend wrapperStyle={{ fontSize: 10 }} />
                <Bar dataKey="vehicles" fill="hsl(var(--chart-1))" name="Vehicles" radius={[2,2,0,0]} />
                <Bar dataKey="queue" fill="hsl(var(--chart-4))" name="Queue" radius={[2,2,0,0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Radar */}
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">Lane Pressure (RL State)</CardTitle>
          </CardHeader>
          <CardContent className="px-2 pb-3 flex justify-center">
            <ResponsiveContainer width="100%" height={200}>
              <RadarChart data={radarData}>
                <PolarGrid stroke="hsl(var(--border))" />
                <PolarAngleAxis dataKey="lane" tick={{ fontSize: 10 }} />
                <PolarRadiusAxis tick={{ fontSize: 8 }} />
                <Radar name="Pressure" dataKey="Pressure" stroke="hsl(var(--chart-1))" fill="hsl(var(--chart-1))" fillOpacity={0.3} />
              </RadarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <WaitTimeChart />
        <QueueLengthChart />
        <ThroughputChart />
        <RewardTrendChart />
      </div>

      {/* Pedestrian Analytics Section */}
      <div className="flex items-center gap-2 pt-2">
        <span className="text-lg">🚶</span>
        <h2 className="text-base font-bold text-foreground">Pedestrian Analytics</h2>
        <span className="text-[10px] bg-sky-100 text-sky-700 border border-sky-200 px-2 py-0.5 rounded-full font-semibold">RL-Optimised</span>
      </div>

      {/* Pedestrian KPI row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {[
          { label: 'Total Waiting', value: totalPeds, color: 'text-sky-600' },
          { label: 'Avg Ped Wait', value: `${avgPedWait}s`, color: 'text-amber-600' },
          { label: 'Active Crossings', value: activeCrossings, color: 'text-green-600' },
          { label: 'Ped Reward Total', value: (state.metrics.pedRewardHistory || []).reduce((a, b) => a + b, 0).toFixed(2), color: 'text-purple-600' },
        ].map(item => (
          <Card key={item.label}>
            <CardContent className="pt-4 pb-3 px-4">
              <p className="text-[10px] text-muted-foreground uppercase tracking-wide mb-1">{item.label}</p>
              <p className={`text-2xl font-bold font-mono ${item.color}`}>{item.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Per-lane pedestrian bar */}
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">Pedestrian Waiting & Wait Time by Lane</CardTitle>
          </CardHeader>
          <CardContent className="px-2 pb-3">
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={pedData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="lane" tick={{ fontSize: 10 }} stroke="hsl(var(--muted-foreground))" />
                <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
                <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
                <Legend wrapperStyle={{ fontSize: 10 }} />
                <Bar dataKey="waiting" fill="#0ea5e9" name="Waiting" radius={[2,2,0,0]} />
                <Bar dataKey="wait" fill="#f97316" name="Wait Time (s)" radius={[2,2,0,0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Radar — pedestrian pressure */}
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">Pedestrian Pressure by Lane (RL State)</CardTitle>
          </CardHeader>
          <CardContent className="px-2 pb-3 flex justify-center">
            <ResponsiveContainer width="100%" height={200}>
              <RadarChart data={LANES.map(lane => ({
                lane,
                Pressure: Math.round(((peds[lane]?.count || 0) * 0.6 + (peds[lane]?.waitTime || 0) * 0.4) * 10) / 10,
              }))}>
                <PolarGrid stroke="hsl(var(--border))" />
                <PolarAngleAxis dataKey="lane" tick={{ fontSize: 10 }} />
                <PolarRadiusAxis tick={{ fontSize: 8 }} />
                <Radar name="Ped Pressure" dataKey="Pressure" stroke="#0ea5e9" fill="#0ea5e9" fillOpacity={0.3} />
              </RadarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <PedestrianWaitChart />
        <PedestrianCrossingChart />
      </div>
    </div>
  );
}
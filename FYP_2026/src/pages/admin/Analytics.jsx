import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useSimulation } from '@/lib/SimulationContext';
import { WaitTimeChart, QueueLengthChart, ThroughputChart, RewardTrendChart, PedestrianWaitChart, PedestrianCrossingChart } from '@/components/shared/SimulationChart';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { BarChart2, TrendingUp, TrendingDown } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, RadarChart, Radar, PolarGrid, PolarAngleAxis, PolarRadiusAxis } from 'recharts';
import { dashboardApi } from '@/api/admin';

export default function Analytics() {
  const { state } = useSimulation();

  const { data: analytics } = useQuery({
    queryKey: ['admin-analytics-week'],
    queryFn: () => dashboardApi.violationAnalytics({ period: 'week' }).then(r => r.data),
    staleTime: 60000,
  });

  const { data: fineAnalytics } = useQuery({
    queryKey: ['admin-fine-analytics-week'],
    queryFn: () => dashboardApi.fineAnalytics({ period: 'week' }).then(r => r.data),
    staleTime: 60000,
  });

  const { data: compliance } = useQuery({
    queryKey: ['admin-compliance'],
    queryFn: () => dashboardApi.complianceAnalytics().then(r => r.data),
    staleTime: 60000,
  });

  // Simulation local data
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
  const peds = state.pedestrians || {};
  const totalPeds = LANES.reduce((s, l) => s + (peds[l]?.count || 0), 0);
  const avgPedWait = (LANES.reduce((s, l) => s + (peds[l]?.waitTime || 0), 0) / 4).toFixed(1);
  const activeCrossings = LANES.filter(l => peds[l]?.crossing).length;

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <BarChart2 className="w-5 h-5 text-blue-500" />
        <h1 className="text-xl font-bold">Traffic Analytics</h1>
        <Badge variant="outline" className="text-[10px]">Sim Tick {state.tick}</Badge>
      </div>

      {/* Backend summary row */}
      {(analytics || fineAnalytics || compliance) && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {analytics && <>
            <Card><CardContent className="pt-4 pb-3 px-4">
              <p className="text-[10px] text-muted-foreground uppercase">Violations This Week</p>
              <p className="text-2xl font-bold font-mono text-red-600">{analytics.total ?? 0}</p>
            </CardContent></Card>
            <Card><CardContent className="pt-4 pb-3 px-4">
              <p className="text-[10px] text-muted-foreground uppercase">Confirmed</p>
              <p className="text-2xl font-bold font-mono text-orange-600">{analytics.confirmed ?? 0}</p>
            </CardContent></Card>
          </>}
          {fineAnalytics && <Card><CardContent className="pt-4 pb-3 px-4">
            <p className="text-[10px] text-muted-foreground uppercase">Fines Collected</p>
            <p className="text-xl font-bold font-mono text-green-600">ETB {Number(fineAnalytics.total_collected ?? 0).toLocaleString()}</p>
          </CardContent></Card>}
          {compliance && <Card><CardContent className="pt-4 pb-3 px-4">
            <p className="text-[10px] text-muted-foreground uppercase">City Compliance</p>
            <p className="text-2xl font-bold font-mono text-blue-600">{compliance.city_compliance_score ?? 0}%</p>
          </CardContent></Card>}
        </div>
      )}

      {/* Backend violation types chart */}
      {analytics?.results?.length > 0 && (
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">Violations by Type (This Week — Backend)</CardTitle>
          </CardHeader>
          <CardContent className="px-2 pb-3">
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={analytics.results.slice(0, 8)} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="name" tick={{ fontSize: 10 }} stroke="hsl(var(--muted-foreground))" />
                <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
                <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
                <Bar dataKey="count" fill="hsl(var(--chart-1))" name="Count" radius={[2, 2, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Simulation charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">Lane Vehicle & Queue (Simulation)</CardTitle>
          </CardHeader>
          <CardContent className="px-2 pb-3">
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={laneData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="lane" tick={{ fontSize: 10 }} stroke="hsl(var(--muted-foreground))" />
                <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
                <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
                <Legend wrapperStyle={{ fontSize: 10 }} />
                <Bar dataKey="vehicles" fill="hsl(var(--chart-1))" name="Vehicles" radius={[2, 2, 0, 0]} />
                <Bar dataKey="queue" fill="hsl(var(--chart-4))" name="Queue" radius={[2, 2, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

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
    </div>
  );
}

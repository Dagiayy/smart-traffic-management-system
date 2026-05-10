import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useSimulation } from '@/lib/SimulationContext';
import { WaitTimeChart, QueueLengthChart, ThroughputChart, RewardTrendChart } from '@/components/shared/SimulationChart';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { GitCompare, Award, Database } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { devApi } from '@/api/developer';

export default function PerformanceComparison() {
  const { state } = useSimulation();

  const { data: backendComparison } = useQuery({
    queryKey: ['dev-perf-comparison'],
    queryFn: () => devApi.performanceComparison().then(r => r.data),
    staleTime: 60000,
  });

  // Simulation local comparison
  const last5RL = state.metrics.waitHistory.slice(-5);
  const last5Fixed = state.metrics.fixedWaitHistory.slice(-5);
  const avgRLWait = last5RL.length ? (last5RL.reduce((a, b) => a + b, 0) / last5RL.length).toFixed(1) : '—';
  const avgFixedWait = last5Fixed.length ? (last5Fixed.reduce((a, b) => a + b, 0) / last5Fixed.length).toFixed(1) : '—';
  const improvement = (avgRLWait !== '—' && avgFixedWait !== '—') ? (parseFloat(avgFixedWait) - parseFloat(avgRLWait)).toFixed(1) : '—';
  const improvePct = (improvement !== '—' && parseFloat(avgFixedWait) > 0) ? ((parseFloat(improvement) / parseFloat(avgFixedWait)) * 100).toFixed(1) : '—';

  const last5RLQueue = state.metrics.queueHistory.slice(-5);
  const last5FixedQueue = state.metrics.fixedQueueHistory.slice(-5);
  const avgRLQueue = last5RLQueue.length ? (last5RLQueue.reduce((a, b) => a + b, 0) / last5RLQueue.length).toFixed(1) : '—';
  const avgFixedQueue = last5FixedQueue.length ? (last5FixedQueue.reduce((a, b) => a + b, 0) / last5FixedQueue.length).toFixed(1) : '—';

  const comparisonBar = [
    { metric: 'Avg Wait', RL: parseFloat(avgRLWait) || 0, Fixed: parseFloat(avgFixedWait) || 0 },
    { metric: 'Avg Queue', RL: parseFloat(avgRLQueue) || 0, Fixed: parseFloat(avgFixedQueue) || 0 },
  ];

  const backendSessions = backendComparison?.results ?? [];

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <GitCompare className="w-5 h-5 text-blue-500" />
        <h1 className="text-xl font-bold">Performance Comparison</h1>
        <Badge variant="outline" className="text-[10px]">RL vs Fixed-Time</Badge>
      </div>

      {/* Simulation comparison */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <Card className="border-blue-200"><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-blue-500 font-semibold uppercase">RL Avg Wait</p>
          <p className="text-2xl font-bold font-mono text-blue-600">{avgRLWait}s</p>
        </CardContent></Card>
        <Card className="border-yellow-200"><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-yellow-500 font-semibold uppercase">Fixed Avg Wait</p>
          <p className="text-2xl font-bold font-mono text-yellow-600">{avgFixedWait}s</p>
        </CardContent></Card>
        <Card className={improvement !== '—' && parseFloat(improvement) > 0 ? 'border-green-200' : 'border-border'}><CardContent className="pt-4 pb-3 px-4">
          <div className="flex items-center gap-2"><Award className="w-4 h-4 text-green-500" />
            <p className="text-[10px] text-green-500 font-semibold uppercase">Improvement</p>
          </div>
          <p className="text-2xl font-bold font-mono text-green-600">{improvement !== '—' ? `${improvement}s` : '—'}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-muted-foreground uppercase">% Better</p>
          <p className={`text-2xl font-bold font-mono ${parseFloat(improvePct) > 0 ? 'text-green-600' : 'text-red-500'}`}>
            {improvePct !== '—' ? `${improvePct}%` : '—'}
          </p>
        </CardContent></Card>
      </div>

      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Direct Metric Comparison (Simulation · Last 5 Ticks)</CardTitle>
        </CardHeader>
        <CardContent className="px-2 pb-3">
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={comparisonBar} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
              <XAxis dataKey="metric" tick={{ fontSize: 10 }} stroke="hsl(var(--muted-foreground))" />
              <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
              <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
              <Legend wrapperStyle={{ fontSize: 10 }} />
              <Bar dataKey="RL" fill="#7c3aed" name="RL Adaptive" radius={[3, 3, 0, 0]} />
              <Bar dataKey="Fixed" fill="#f59e0b" name="Fixed-Time" radius={[3, 3, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Backend sessions comparison */}
      {backendSessions.length > 0 && (
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold flex items-center gap-2">
              <Database className="w-4 h-4 text-violet-500" /> Historical Sessions (Backend)
            </CardTitle>
          </CardHeader>
          <CardContent className="px-4 pb-4">
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead>
                  <tr className="border-b border-border">
                    {['Session', 'Episodes', 'Avg Reward', 'Avg Wait', 'Avg Throughput'].map(h => (
                      <th key={h} className="text-left px-3 py-2 text-[10px] text-muted-foreground uppercase font-semibold">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {backendSessions.map(s => (
                    <tr key={s.session_id} className="border-b border-border/50 hover:bg-muted/20">
                      <td className="px-3 py-2 font-medium">{s.session_name}</td>
                      <td className="px-3 py-2 font-mono">{s.episodes}</td>
                      <td className="px-3 py-2 font-mono text-violet-600">{s.avg_reward?.toFixed(3)}</td>
                      <td className="px-3 py-2 font-mono">{s.avg_wait_time?.toFixed(1)}s</td>
                      <td className="px-3 py-2 font-mono">{s.avg_throughput?.toFixed(0)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <WaitTimeChart />
        <QueueLengthChart />
        <ThroughputChart />
        <RewardTrendChart />
      </div>
    </div>
  );
}

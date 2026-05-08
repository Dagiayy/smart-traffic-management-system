import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { useSimulation } from '@/lib/SimulationContext';

function buildChartData(rlData, fixedData, label) {
  return rlData.map((val, i) => ({
    tick: i + 1,
    RL: parseFloat(val?.toFixed(1)),
    Fixed: parseFloat((fixedData[i] ?? val)?.toFixed(1)),
  }));
}

export function WaitTimeChart() {
  const { state } = useSimulation();
  const data = buildChartData(state.metrics.waitHistory, state.metrics.fixedWaitHistory, 'Wait Time');

  return (
    <Card>
      <CardHeader className="pb-1 pt-4 px-4">
        <CardTitle className="text-sm font-semibold">Avg Wait Time Comparison (s)</CardTitle>
      </CardHeader>
      <CardContent className="px-2 pb-3">
        <ResponsiveContainer width="100%" height={160}>
          <LineChart data={data} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="tick" tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <Tooltip
              contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }}
              labelStyle={{ color: 'hsl(var(--foreground))' }}
            />
            <Legend wrapperStyle={{ fontSize: 10 }} />
            <Line type="monotone" dataKey="RL" stroke="hsl(var(--chart-1))" strokeWidth={2} dot={false} name="RL-Based" />
            <Line type="monotone" dataKey="Fixed" stroke="hsl(var(--chart-3))" strokeWidth={2} dot={false} strokeDasharray="4 2" name="Fixed-Time" />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

export function QueueLengthChart() {
  const { state } = useSimulation();
  const data = buildChartData(state.metrics.queueHistory, state.metrics.fixedQueueHistory, 'Queue');

  return (
    <Card>
      <CardHeader className="pb-1 pt-4 px-4">
        <CardTitle className="text-sm font-semibold">Queue Length Comparison</CardTitle>
      </CardHeader>
      <CardContent className="px-2 pb-3">
        <ResponsiveContainer width="100%" height={160}>
          <LineChart data={data} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="tick" tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <Tooltip
              contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }}
              labelStyle={{ color: 'hsl(var(--foreground))' }}
            />
            <Legend wrapperStyle={{ fontSize: 10 }} />
            <Line type="monotone" dataKey="RL" stroke="hsl(var(--chart-2))" strokeWidth={2} dot={false} name="RL-Based" />
            <Line type="monotone" dataKey="Fixed" stroke="hsl(var(--chart-4))" strokeWidth={2} dot={false} strokeDasharray="4 2" name="Fixed-Time" />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

export function RewardTrendChart() {
  const { state } = useSimulation();
  const data = state.metrics.rewardHistory.map((val, i) => ({ tick: i + 1, Reward: val }));

  return (
    <Card>
      <CardHeader className="pb-1 pt-4 px-4">
        <CardTitle className="text-sm font-semibold">RL Reward Trend</CardTitle>
      </CardHeader>
      <CardContent className="px-2 pb-3">
        <ResponsiveContainer width="100%" height={160}>
          <LineChart data={data} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="tick" tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <Tooltip
              contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }}
              labelStyle={{ color: 'hsl(var(--foreground))' }}
            />
            <Line type="monotone" dataKey="Reward" stroke="hsl(var(--chart-5))" strokeWidth={2} dot={false} name="Reward" />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

export function ThroughputChart() {
  const { state } = useSimulation();
  const data = state.metrics.throughputHistory.map((val, i) => ({ tick: i + 1, Throughput: val }));

  return (
    <Card>
      <CardHeader className="pb-1 pt-4 px-4">
        <CardTitle className="text-sm font-semibold">Vehicle Throughput</CardTitle>
      </CardHeader>
      <CardContent className="px-2 pb-3">
        <ResponsiveContainer width="100%" height={160}>
          <LineChart data={data} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="tick" tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <Tooltip
              contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }}
              labelStyle={{ color: 'hsl(var(--foreground))' }}
            />
            <Line type="monotone" dataKey="Throughput" stroke="hsl(var(--chart-2))" strokeWidth={2} dot={false} name="Vehicles/tick" />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

// ── Pedestrian Charts ──────────────────────────────────────────────────────────

export function PedestrianWaitChart() {
  const { state } = useSimulation();
  const pedWait = state.metrics.pedWaitHistory || [];
  const fixedPedWait = state.metrics.fixedPedWaitHistory || [];
  const data = pedWait.map((val, i) => ({
    tick: i + 1,
    RL: parseFloat(val?.toFixed(1)),
    Fixed: parseFloat((fixedPedWait[i] ?? val)?.toFixed(1)),
  }));

  return (
    <Card>
      <CardHeader className="pb-1 pt-4 px-4">
        <CardTitle className="text-sm font-semibold flex items-center gap-2">
          <span>🚶</span> Pedestrian Avg Wait Time (s) — RL vs Fixed
        </CardTitle>
      </CardHeader>
      <CardContent className="px-2 pb-3">
        <ResponsiveContainer width="100%" height={160}>
          <LineChart data={data} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="tick" tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
            <Legend wrapperStyle={{ fontSize: 10 }} />
            <Line type="monotone" dataKey="RL" stroke="#0ea5e9" strokeWidth={2} dot={false} name="RL-Optimised" />
            <Line type="monotone" dataKey="Fixed" stroke="#f97316" strokeWidth={2} dot={false} strokeDasharray="4 2" name="Fixed-Time" />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

export function PedestrianCrossingChart() {
  const { state } = useSimulation();
  const crossingData = state.metrics.pedCrossingHistory || [];
  const pedRewardData = state.metrics.pedRewardHistory || [];
  const data = crossingData.map((val, i) => ({
    tick: i + 1,
    Crossings: val,
    PedReward: parseFloat((pedRewardData[i] ?? 0).toFixed(3)),
  }));

  return (
    <Card>
      <CardHeader className="pb-1 pt-4 px-4">
        <CardTitle className="text-sm font-semibold flex items-center gap-2">
          <span>🚦</span> Pedestrian Crossings & RL Reward Contribution
        </CardTitle>
      </CardHeader>
      <CardContent className="px-2 pb-3">
        <ResponsiveContainer width="100%" height={160}>
          <LineChart data={data} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="tick" tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
            <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
            <Legend wrapperStyle={{ fontSize: 10 }} />
            <Line type="monotone" dataKey="Crossings" stroke="#22c55e" strokeWidth={2} dot={false} name="Active Crossings" />
            <Line type="monotone" dataKey="PedReward" stroke="#a855f7" strokeWidth={2} dot={false} name="Ped Reward" />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
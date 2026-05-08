import React from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { RewardTrendChart, WaitTimeChart, ThroughputChart, PedestrianWaitChart, PedestrianCrossingChart } from '@/components/shared/SimulationChart';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { TrendingUp, TrendingDown, Zap } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { LANES } from '@/lib/simulationEngine';

export default function RewardAnalytics() {
  const { state } = useSimulation();

  const lastReward = state.metrics.rewardHistory[state.metrics.rewardHistory.length - 1] ?? 0;
  const prevReward = state.metrics.rewardHistory[state.metrics.rewardHistory.length - 2] ?? 0;
  const rewardTrend = lastReward - prevReward;

  const avgReward = state.metrics.rewardHistory.length > 0
    ? (state.metrics.rewardHistory.reduce((a, b) => a + b, 0) / state.metrics.rewardHistory.length).toFixed(3)
    : '—';

  const cumulativeData = state.metrics.rewardHistory.map((val, i) => ({
    tick: i + 1,
    Reward: parseFloat(val.toFixed(3)),
    Cumulative: parseFloat((state.metrics.rewardHistory.slice(0, i + 1).reduce((a, b) => a + b, 0)).toFixed(2)),
  }));

  const efficiencyGain = state.metrics.waitHistory.length > 5
    ? (((state.metrics.fixedWaitHistory.slice(-5).reduce((a, b) => a + b, 0) / 5) - (state.metrics.waitHistory.slice(-5).reduce((a, b) => a + b, 0) / 5))).toFixed(1)
    : '—';

  const pedWaitHistory = state.metrics.pedWaitHistory || [];
  const fixedPedWaitHistory = state.metrics.fixedPedWaitHistory || [];
  const pedRewardHistory = state.metrics.pedRewardHistory || [];
  const totalPedReward = pedRewardHistory.reduce((a, b) => a + b, 0).toFixed(2);
  const pedEfficiencyGain = pedWaitHistory.length > 5
    ? (((fixedPedWaitHistory.slice(-5).reduce((a, b) => a + b, 0) / 5) - (pedWaitHistory.slice(-5).reduce((a, b) => a + b, 0) / 5))).toFixed(1)
    : '—';
  const avgPedWait = pedWaitHistory.length > 0
    ? (pedWaitHistory.reduce((a, b) => a + b, 0) / pedWaitHistory.length).toFixed(1)
    : '—';

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <TrendingUp className="w-5 h-5 text-violet-500" />
        <h1 className="text-xl font-bold">Reward Analytics</h1>
        <Badge variant="outline" className="text-[10px] border-violet-400 text-violet-500">RL Performance</Badge>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <Card><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-muted-foreground uppercase">Total Reward</p>
          <p className="text-2xl font-bold font-mono text-violet-600">{state.metrics.totalReward.toFixed(2)}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-muted-foreground uppercase">Avg Reward</p>
          <p className="text-2xl font-bold font-mono">{avgReward}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-muted-foreground uppercase">Last Reward</p>
          <div className="flex items-center gap-2">
            <p className="text-2xl font-bold font-mono">{lastReward.toFixed(3)}</p>
            {rewardTrend >= 0
              ? <TrendingUp className="w-4 h-4 text-green-500" />
              : <TrendingDown className="w-4 h-4 text-red-500" />}
          </div>
        </CardContent></Card>
        <Card><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-muted-foreground uppercase">Wait Efficiency Gain</p>
          <p className={`text-2xl font-bold font-mono ${parseFloat(efficiencyGain) > 0 ? 'text-green-600' : 'text-red-500'}`}>
            {efficiencyGain !== '—' ? `${efficiencyGain}s` : '—'}
          </p>
        </CardContent></Card>
      </div>

      {/* Cumulative Reward Area Chart */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Reward & Cumulative Reward Over Time</CardTitle>
        </CardHeader>
        <CardContent className="px-2 pb-3">
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={cumulativeData} margin={{ top: 5, right: 10, left: -10, bottom: 0 }}>
              <defs>
                <linearGradient id="rewardGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#7c3aed" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#7c3aed" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="cumulGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#22c55e" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#22c55e" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
              <XAxis dataKey="tick" tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
              <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
              <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
              <Legend wrapperStyle={{ fontSize: 10 }} />
              <Area type="monotone" dataKey="Reward" stroke="#7c3aed" fill="url(#rewardGrad)" strokeWidth={2} dot={false} name="Per-Tick Reward" />
              <Area type="monotone" dataKey="Cumulative" stroke="#22c55e" fill="url(#cumulGrad)" strokeWidth={2} dot={false} name="Cumulative Reward" />
            </AreaChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <RewardTrendChart />
        <WaitTimeChart />
        <ThroughputChart />
      </div>

      {/* Pedestrian RL Section */}
      <div className="flex items-center gap-2 pt-2 border-t border-border">
        <span className="text-lg">🚶</span>
        <h2 className="text-base font-bold">Pedestrian RL Analysis</h2>
        <Badge variant="outline" className="text-[10px] border-sky-400 text-sky-500">Integrated into Reward</Badge>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <Card><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-muted-foreground uppercase">Total Ped Reward</p>
          <p className="text-2xl font-bold font-mono text-purple-600">{totalPedReward}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-muted-foreground uppercase">Avg Ped Wait (RL)</p>
          <p className="text-2xl font-bold font-mono text-sky-600">{avgPedWait !== '—' ? `${avgPedWait}s` : '—'}</p>
        </CardContent></Card>
        <Card><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-muted-foreground uppercase">Ped Wait Gain vs Fixed</p>
          <p className={`text-2xl font-bold font-mono ${parseFloat(pedEfficiencyGain) > 0 ? 'text-green-600' : 'text-red-500'}`}>
            {pedEfficiencyGain !== '—' ? `${pedEfficiencyGain}s` : '—'}
          </p>
        </CardContent></Card>
        <Card><CardContent className="pt-4 pb-3 px-4">
          <p className="text-[10px] text-muted-foreground uppercase">Last Ped Reward</p>
          <p className="text-2xl font-bold font-mono text-violet-600">
            {pedRewardHistory.length > 0 ? pedRewardHistory[pedRewardHistory.length - 1].toFixed(3) : '—'}
          </p>
        </CardContent></Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <PedestrianWaitChart />
        <PedestrianCrossingChart />
      </div>

      {/* RL decision explanation */}
      <Card className="border-sky-200 bg-sky-50/30">
        <CardContent className="px-4 py-3">
          <p className="text-xs font-semibold text-sky-700 mb-1 flex items-center gap-1.5">
            <Zap className="w-3.5 h-3.5" /> How the RL agent balances vehicles & pedestrians
          </p>
          <p className="text-[11px] text-muted-foreground leading-relaxed">
            The RL agent factors pedestrian pressure from <strong>red-lane crosswalks</strong> into its green-time decision. 
            High pedestrian wait on opposing lanes reduces the computed green duration, giving pedestrians earlier crossing windows. 
            This pedestrian component contributes a separate reward signal (ped wait reduction + crossing events), making the agent 
            learn to balance vehicle throughput against pedestrian safety holistically.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
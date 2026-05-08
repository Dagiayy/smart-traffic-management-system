import React, { useState, useEffect, useRef } from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { createInitialState, simulateTick, LANES } from '@/lib/simulationEngine';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { FlaskConical, Play, Square, RotateCcw, TrendingUp } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

const STRATEGIES = [
  { id: 'rl', label: 'RL Adaptive', color: '#7c3aed', desc: 'Dynamic green time based on lane pressure' },
  { id: 'fixed', label: 'Fixed-Time', color: '#f59e0b', desc: 'Constant 30s green for all phases' },
  { id: 'weighted', label: 'Priority Weighted', color: '#22c55e', desc: 'Prioritize highest-queue lane' },
  { id: 'roundrobin', label: 'Round Robin', color: '#3b82f6', desc: 'Equal time rotation for all lanes' },
];

export default function ExperimentMode() {
  const { state: globalState } = useSimulation();
  const [running, setRunning] = useState(false);
  const [selectedStrategies, setSelectedStrategies] = useState(['rl', 'fixed']);
  const [ticks, setTicks] = useState(0);
  const [results, setResults] = useState({});
  const [chartData, setChartData] = useState([]);
  const intervalRef = useRef(null);
  const statesRef = useRef({});

  const initExperiment = () => {
    statesRef.current = {};
    selectedStrategies.forEach(s => {
      statesRef.current[s] = { ...createInitialState(), mode: s === 'rl' ? 'rl' : 'fixed' };
    });
    setTicks(0);
    setResults({});
    setChartData([]);
  };

  const toggleStrategy = (id) => {
    setSelectedStrategies(s =>
      s.includes(id) ? (s.length > 1 ? s.filter(x => x !== id) : s) : [...s, id]
    );
  };

  const runStep = () => {
    const newRow = { tick: ticks + 1 };
    const newResults = {};
    selectedStrategies.forEach(s => {
      const prev = statesRef.current[s];
      if (!prev) return;
      const next = simulateTick({ ...prev, mode: s === 'rl' ? 'rl' : 'fixed' });
      statesRef.current[s] = next;
      const wait = LANES.reduce((a, l) => a + next.lanes[l].waitTime, 0) / 4;
      const queue = LANES.reduce((a, l) => a + next.lanes[l].queue, 0) / 4;
      newRow[`${s}_wait`] = parseFloat(wait.toFixed(1));
      newRow[`${s}_queue`] = parseFloat(queue.toFixed(1));
      newResults[s] = { wait: wait.toFixed(1), queue: queue.toFixed(1), reward: next.metrics.totalReward.toFixed(1) };
    });
    setChartData(d => [...d, newRow].slice(-50));
    setResults(newResults);
    setTicks(t => t + 1);
  };

  useEffect(() => {
    if (running) {
      intervalRef.current = setInterval(runStep, 500);
    } else {
      clearInterval(intervalRef.current);
    }
    return () => clearInterval(intervalRef.current);
  }, [running, selectedStrategies]);

  useEffect(() => { initExperiment(); }, [selectedStrategies]);

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <FlaskConical className="w-5 h-5 text-pink-500" />
        <h1 className="text-xl font-bold">Experiment Mode</h1>
        <Badge variant="outline" className="text-[10px]">Strategy Comparator</Badge>
      </div>

      {/* Strategy Selection */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Select Strategies to Compare</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4">
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 mb-4">
            {STRATEGIES.map(s => (
              <button key={s.id} onClick={() => toggleStrategy(s.id)}
                className={`p-3 rounded-xl border text-left transition-all ${selectedStrategies.includes(s.id) ? 'border-primary bg-primary/10' : 'border-border hover:border-primary/40'}`}>
                <div className="flex items-center gap-2 mb-1">
                  <div className="w-3 h-3 rounded-full" style={{ backgroundColor: s.color }} />
                  <span className="text-xs font-bold">{s.label}</span>
                  {selectedStrategies.includes(s.id) && <Badge className="text-[8px] h-4 ml-auto">Active</Badge>}
                </div>
                <p className="text-[9px] text-muted-foreground">{s.desc}</p>
              </button>
            ))}
          </div>

          <div className="flex items-center gap-2">
            <Button size="sm" className="h-8 text-xs" onClick={() => { initExperiment(); setRunning(true); }} disabled={running}>
              <Play className="w-3 h-3 mr-1" /> Run Experiment
            </Button>
            <Button size="sm" variant="outline" className="h-8 text-xs" onClick={() => setRunning(false)} disabled={!running}>
              <Square className="w-3 h-3 mr-1" /> Stop
            </Button>
            <Button size="sm" variant="outline" className="h-8 text-xs" onClick={() => { setRunning(false); initExperiment(); }}>
              <RotateCcw className="w-3 h-3 mr-1" /> Reset
            </Button>
            <Badge className="ml-auto font-mono">{ticks} ticks</Badge>
          </div>
        </CardContent>
      </Card>

      {/* Results Cards */}
      {Object.keys(results).length > 0 && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {STRATEGIES.filter(s => selectedStrategies.includes(s.id)).map(s => (
            <Card key={s.id} style={{ borderColor: s.color + '40' }}>
              <CardContent className="pt-4 pb-3 px-4">
                <div className="flex items-center gap-2 mb-2">
                  <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: s.color }} />
                  <p className="text-[10px] font-bold">{s.label}</p>
                </div>
                <div className="space-y-1">
                  <div className="flex justify-between text-[10px]"><span className="text-muted-foreground">Avg Wait</span><span className="font-mono font-bold">{results[s.id]?.wait}s</span></div>
                  <div className="flex justify-between text-[10px]"><span className="text-muted-foreground">Avg Queue</span><span className="font-mono font-bold">{results[s.id]?.queue}</span></div>
                  <div className="flex justify-between text-[10px]"><span className="text-muted-foreground">Reward</span><span className="font-mono font-bold">{results[s.id]?.reward}</span></div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Comparison Chart */}
      {chartData.length > 1 && (
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">Wait Time Comparison Across Strategies</CardTitle>
          </CardHeader>
          <CardContent className="px-2 pb-3">
            <ResponsiveContainer width="100%" height={220}>
              <LineChart data={chartData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="tick" tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
                <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
                <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
                <Legend wrapperStyle={{ fontSize: 10 }} />
                {STRATEGIES.filter(s => selectedStrategies.includes(s.id)).map(s => (
                  <Line key={s.id} type="monotone" dataKey={`${s.id}_wait`} stroke={s.color} strokeWidth={2} dot={false} name={`${s.label} Wait`} />
                ))}
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
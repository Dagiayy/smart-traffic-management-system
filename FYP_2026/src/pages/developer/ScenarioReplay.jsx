import React, { useState, useEffect, useRef } from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Slider } from '@/components/ui/slider';
import { RotateCcw, Play, Pause, SkipBack, SkipForward, Film } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine } from 'recharts';

export default function ScenarioReplay() {
  const { state } = useSimulation();
  const [replayTick, setReplayTick] = useState(0);
  const [playing, setPlaying] = useState(false);
  const intervalRef = useRef(null);

  const history = state.metrics.waitHistory;
  const maxTick = Math.max(history.length - 1, 0);

  const chartData = history.map((v, i) => ({
    tick: i + 1,
    Wait: v,
    Queue: state.metrics.queueHistory[i] ?? 0,
    Throughput: state.metrics.throughputHistory[i] ?? 0,
  }));

  useEffect(() => {
    if (playing) {
      intervalRef.current = setInterval(() => {
        setReplayTick(t => {
          if (t >= maxTick) { setPlaying(false); return t; }
          return t + 1;
        });
      }, 300);
    } else {
      clearInterval(intervalRef.current);
    }
    return () => clearInterval(intervalRef.current);
  }, [playing, maxTick]);

  const snapshot = {
    tick: replayTick + 1,
    wait: history[replayTick]?.toFixed(1) ?? '—',
    queue: state.metrics.queueHistory[replayTick]?.toFixed(1) ?? '—',
    throughput: state.metrics.throughputHistory[replayTick] ?? '—',
    reward: state.metrics.rewardHistory[replayTick]?.toFixed(3) ?? '—',
    fixedWait: state.metrics.fixedWaitHistory[replayTick]?.toFixed(1) ?? '—',
  };

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <Film className="w-5 h-5 text-blue-500" />
        <h1 className="text-xl font-bold">Scenario Replay</h1>
        <Badge variant="outline" className="text-[10px]">{history.length} ticks recorded</Badge>
      </div>

      {history.length < 2 ? (
        <Card><CardContent className="py-12 text-center text-muted-foreground text-sm">
          Start and run the simulation for a few ticks to record replay data…
        </CardContent></Card>
      ) : (
        <>
          {/* Playback Controls */}
          <Card>
            <CardContent className="pt-4 pb-4 px-4 space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold">Replay Tick</span>
                <Badge className="font-mono text-xs">{snapshot.tick} / {maxTick + 1}</Badge>
              </div>
              <Slider min={0} max={maxTick} step={1} value={[replayTick]} onValueChange={([v]) => { setReplayTick(v); setPlaying(false); }} />
              <div className="flex items-center justify-center gap-3">
                <Button size="sm" variant="outline" className="h-8" onClick={() => { setReplayTick(0); setPlaying(false); }}><SkipBack className="w-4 h-4" /></Button>
                <Button size="sm" variant="outline" className="h-8" onClick={() => setReplayTick(t => Math.max(0, t - 1))}><RotateCcw className="w-4 h-4" /></Button>
                <Button size="sm" className="h-8 px-6" onClick={() => setPlaying(p => !p)}>
                  {playing ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
                </Button>
                <Button size="sm" variant="outline" className="h-8" onClick={() => setReplayTick(t => Math.min(maxTick, t + 1))}><SkipForward className="w-4 h-4" /></Button>
                <Button size="sm" variant="outline" className="h-8" onClick={() => { setReplayTick(maxTick); setPlaying(false); }}>
                  <SkipForward className="w-4 h-4" /><SkipForward className="w-4 h-4 -ml-2" />
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Snapshot at current tick */}
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
            {[
              { label: 'Avg Wait (RL)', value: `${snapshot.wait}s` },
              { label: 'Avg Wait (Fixed)', value: `${snapshot.fixedWait}s` },
              { label: 'Avg Queue', value: snapshot.queue },
              { label: 'Throughput', value: snapshot.throughput },
              { label: 'Reward', value: snapshot.reward },
            ].map(item => (
              <Card key={item.label}>
                <CardContent className="pt-3 pb-3 px-3 text-center">
                  <p className="text-[9px] text-muted-foreground uppercase">{item.label}</p>
                  <p className="text-lg font-bold font-mono">{item.value}</p>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Timeline Chart with reference line */}
          <Card>
            <CardHeader className="pb-2 pt-4 px-4">
              <CardTitle className="text-sm font-semibold">Timeline — Wait Time & Queue</CardTitle>
            </CardHeader>
            <CardContent className="px-2 pb-3">
              <ResponsiveContainer width="100%" height={220}>
                <LineChart data={chartData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                  <XAxis dataKey="tick" tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
                  <YAxis tick={{ fontSize: 9 }} stroke="hsl(var(--muted-foreground))" />
                  <Tooltip contentStyle={{ fontSize: 11, backgroundColor: 'hsl(var(--card))', border: '1px solid hsl(var(--border))' }} />
                  <ReferenceLine x={replayTick + 1} stroke="#7c3aed" strokeWidth={2} label={{ value: `▶ T${replayTick + 1}`, fontSize: 9, fill: '#7c3aed' }} />
                  <Line type="monotone" dataKey="Wait" stroke="hsl(var(--chart-1))" strokeWidth={2} dot={false} name="Wait Time" />
                  <Line type="monotone" dataKey="Queue" stroke="hsl(var(--chart-4))" strokeWidth={2} dot={false} name="Queue Length" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
import React, { useState, useEffect, useRef } from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ScrollText, Trash2, Download, Filter } from 'lucide-react';
import { PHASES, LANES } from '@/lib/simulationEngine';

const LOG_LEVELS = { INFO: 'text-blue-500', DEBUG: 'text-green-500', WARN: 'text-yellow-500', ACTION: 'text-violet-500', REWARD: 'text-emerald-500' };

function generateLogs(state, prevState) {
  const logs = [];
  const t = state.tick;
  const phase = PHASES[state.currentPhase];

  logs.push({ level: 'INFO', msg: `[Tick ${t}] Phase ${state.currentPhase + 1} active — Green: ${phase.green.join(', ')}`, tick: t });
  logs.push({ level: 'DEBUG', msg: `[Tick ${t}] Phase timer: ${state.phaseTimer}s`, tick: t });

  LANES.forEach(lane => {
    const d = state.lanes[lane];
    const sig = state.signals[lane];
    logs.push({ level: 'DEBUG', msg: `  └ ${lane}: signal=${sig.toUpperCase()} | vehicles=${d.vehicles} | queue=${d.queue} | wait=${d.waitTime.toFixed(1)}s | throughput=${d.throughput}`, tick: t });
  });

  const lastReward = state.metrics.rewardHistory[state.metrics.rewardHistory.length - 1];
  if (lastReward !== undefined) {
    logs.push({ level: 'REWARD', msg: `[Tick ${t}] Reward computed: ${lastReward.toFixed(4)} | Cumulative: ${state.metrics.totalReward.toFixed(2)}`, tick: t });
  }

  if (state.emergency) {
    logs.push({ level: 'WARN', msg: `[Tick ${t}] ⚠ Emergency override active — Lane: ${state.emergency}`, tick: t });
  }

  const avgWait = LANES.reduce((s, l) => s + state.lanes[l].waitTime, 0) / 4;
  if (avgWait > 30) {
    logs.push({ level: 'WARN', msg: `[Tick ${t}] High average wait time: ${avgWait.toFixed(1)}s — consider switching to RL mode`, tick: t });
  }

  LANES.forEach(lane => {
    if (state.lanes[lane].queue >= 12) {
      logs.push({ level: 'WARN', msg: `[Tick ${t}] Congestion alert — ${lane} queue: ${state.lanes[lane].queue} vehicles`, tick: t });
    }
  });

  logs.push({ level: 'ACTION', msg: `[Tick ${t}] Mode: ${state.mode.toUpperCase()} | Next phase in: ${state.phaseTimer}s`, tick: t });

  return logs.map((l, i) => ({ ...l, id: `${t}-${i}` }));
}

export default function SystemLogs() {
  const { state } = useSimulation();
  const [logs, setLogs] = useState([]);
  const [filter, setFilter] = useState('ALL');
  const [autoScroll, setAutoScroll] = useState(true);
  const bottomRef = useRef(null);
  const prevTick = useRef(0);

  useEffect(() => {
    if (state.tick !== prevTick.current && state.tick > 0) {
      prevTick.current = state.tick;
      const newLogs = generateLogs(state);
      setLogs(l => [...l, ...newLogs].slice(-300));
    }
  }, [state.tick]);

  useEffect(() => {
    if (autoScroll && bottomRef.current) {
      bottomRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [logs, autoScroll]);

  const filtered = filter === 'ALL' ? logs : logs.filter(l => l.level === filter);

  const download = () => {
    const text = logs.map(l => `[${l.level}] ${l.msg}`).join('\n');
    const blob = new Blob([text], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = `synapseflow-logs-tick${state.tick}.txt`; a.click();
  };

  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <ScrollText className="w-5 h-5 text-slate-500" />
          <h1 className="text-xl font-bold">System Logs</h1>
          <Badge variant="outline" className="text-[10px] font-mono">{logs.length} entries</Badge>
        </div>
        <div className="flex items-center gap-2">
          <Button size="sm" variant="outline" className="h-8 text-xs" onClick={download}><Download className="w-3 h-3 mr-1" /> Export</Button>
          <Button size="sm" variant="outline" className="h-8 text-xs" onClick={() => setLogs([])}><Trash2 className="w-3 h-3 mr-1" /> Clear</Button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2 items-center">
        <Filter className="w-3.5 h-3.5 text-muted-foreground" />
        {['ALL', ...Object.keys(LOG_LEVELS)].map(level => (
          <button key={level} onClick={() => setFilter(level)} className={`px-2.5 py-1 rounded-full text-[10px] font-semibold transition-all ${filter === level ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>{level}</button>
        ))}
        <label className="ml-auto flex items-center gap-2 text-xs text-muted-foreground cursor-pointer">
          <input type="checkbox" checked={autoScroll} onChange={e => setAutoScroll(e.target.checked)} className="rounded" />
          Auto-scroll
        </label>
      </div>

      {/* Log Terminal */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-red-400" />
            <div className="w-3 h-3 rounded-full bg-yellow-400" />
            <div className="w-3 h-3 rounded-full bg-green-400" />
            <span className="text-xs text-muted-foreground font-mono ml-2">synapseflow://simulation/log</span>
          </div>
        </CardHeader>
        <CardContent className="px-0 pb-0">
          <div className="h-[500px] overflow-y-auto bg-slate-950 rounded-b-xl p-4 font-mono text-[10px] leading-5">
            {filtered.length === 0 ? (
              <span className="text-slate-500">Waiting for simulation events… Start the simulation to generate logs.</span>
            ) : (
              filtered.map(log => (
                <div key={log.id} className="hover:bg-white/5 px-1 rounded">
                  <span className={`font-bold mr-2 ${LOG_LEVELS[log.level]}`}>[{log.level}]</span>
                  <span className="text-slate-300">{log.msg}</span>
                </div>
              ))
            )}
            <div ref={bottomRef} />
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
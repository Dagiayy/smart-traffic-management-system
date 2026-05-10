import React, { useState, useEffect, useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ScrollText, Trash2, Download, Filter, Database } from 'lucide-react';
import { PHASES, LANES } from '@/lib/simulationEngine';
import { devApi } from '@/api/developer';

const LOG_LEVELS = {
  INFO: 'text-blue-500',
  DEBUG: 'text-green-500',
  WARN: 'text-yellow-500',
  WARNING: 'text-yellow-500',
  ACTION: 'text-violet-500',
  REWARD: 'text-emerald-500',
  ERROR: 'text-red-500',
};

function generateSimLogs(state) {
  const logs = [];
  const t = state.tick;
  const phase = PHASES[state.currentPhase];
  logs.push({ level: 'INFO', msg: `[Sim T${t}] Phase ${state.currentPhase + 1} — Green: ${phase.green.join(', ')}`, id: `${t}-0` });
  LANES.forEach((lane, i) => {
    const d = state.lanes[lane];
    logs.push({ level: 'DEBUG', msg: `  └ ${lane}: sig=${state.signals[lane].toUpperCase()} veh=${d.vehicles} q=${d.queue} wait=${d.waitTime.toFixed(1)}s tp=${d.throughput}`, id: `${t}-${i+1}` });
  });
  const r = state.metrics.rewardHistory[state.metrics.rewardHistory.length - 1];
  if (r !== undefined) logs.push({ level: 'REWARD', msg: `[Sim T${t}] Reward: ${r.toFixed(4)} · Total: ${state.metrics.totalReward.toFixed(2)}`, id: `${t}-r` });
  if (state.emergency) logs.push({ level: 'WARN', msg: `[Sim T${t}] ⚠ Emergency: ${state.emergency}`, id: `${t}-e` });
  return logs;
}

export default function SystemLogs() {
  const { state } = useSimulation();
  const [simLogs, setSimLogs] = useState([]);
  const [filter, setFilter] = useState('ALL');
  const [autoScroll, setAutoScroll] = useState(true);
  const [showBackend, setShowBackend] = useState(false);
  const bottomRef = useRef(null);
  const prevTick = useRef(0);

  const { data: backendLogs } = useQuery({
    queryKey: ['dev-system-logs', filter],
    queryFn: () => devApi.systemLogs({ ...(filter !== 'ALL' && { level: filter }), page_size: 50 }).then(r => r.data),
    enabled: showBackend,
    refetchInterval: 5000,
  });

  useEffect(() => {
    if (state.tick !== prevTick.current && state.tick > 0) {
      prevTick.current = state.tick;
      setSimLogs(l => [...l, ...generateSimLogs(state)].slice(-300));
    }
  }, [state.tick]);

  useEffect(() => {
    if (autoScroll && bottomRef.current) bottomRef.current.scrollIntoView({ behavior: 'smooth' });
  }, [simLogs, autoScroll]);

  const displayLogs = showBackend
    ? (backendLogs?.results ?? []).map(l => ({ level: l.level, msg: `[Backend ${l.created_at?.slice(11, 19) ?? ''}] ${l.message}`, id: l.id }))
    : (filter === 'ALL' ? simLogs : simLogs.filter(l => l.level === filter));

  const download = () => {
    const text = simLogs.map(l => `[${l.level}] ${l.msg}`).join('\n');
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([text], { type: 'text/plain' }));
    a.download = `itms-logs-tick${state.tick}.txt`;
    a.click();
  };

  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <ScrollText className="w-5 h-5 text-slate-500" />
          <h1 className="text-xl font-bold">System Logs</h1>
          <Badge variant="outline" className="text-[10px] font-mono">{simLogs.length} sim entries</Badge>
        </div>
        <div className="flex items-center gap-2">
          <Button size="sm" variant={showBackend ? 'default' : 'outline'} className="h-8 text-xs" onClick={() => setShowBackend(p => !p)}>
            <Database className="w-3 h-3 mr-1" /> {showBackend ? 'Sim Logs' : 'Backend Logs'}
          </Button>
          <Button size="sm" variant="outline" className="h-8 text-xs" onClick={download}><Download className="w-3 h-3 mr-1" />Export</Button>
          <Button size="sm" variant="outline" className="h-8 text-xs" onClick={() => setSimLogs([])}><Trash2 className="w-3 h-3 mr-1" />Clear</Button>
        </div>
      </div>

      <div className="flex flex-wrap gap-2 items-center">
        <Filter className="w-3.5 h-3.5 text-muted-foreground" />
        {['ALL', 'INFO', 'DEBUG', 'WARN', 'ACTION', 'REWARD', 'ERROR'].map(level => (
          <button key={level} onClick={() => setFilter(level)}
            className={`px-2.5 py-1 rounded-full text-[10px] font-semibold transition-all ${filter === level ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>
            {level}
          </button>
        ))}
        <label className="ml-auto flex items-center gap-2 text-xs text-muted-foreground cursor-pointer">
          <input type="checkbox" checked={autoScroll} onChange={e => setAutoScroll(e.target.checked)} className="rounded" />
          Auto-scroll
        </label>
      </div>

      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-red-400" />
            <div className="w-3 h-3 rounded-full bg-yellow-400" />
            <div className="w-3 h-3 rounded-full bg-green-400" />
            <span className="text-xs text-muted-foreground font-mono ml-2">
              {showBackend ? 'itms://backend/logs' : 'itms://simulation/log'}
            </span>
          </div>
        </CardHeader>
        <CardContent className="px-0 pb-0">
          <div className="h-[500px] overflow-y-auto bg-slate-950 rounded-b-xl p-4 font-mono text-[10px] leading-5">
            {displayLogs.length === 0
              ? <span className="text-slate-500">No logs yet…</span>
              : displayLogs.map(log => (
                  <div key={log.id} className="hover:bg-white/5 px-1 rounded">
                    <span className={`font-bold mr-2 ${LOG_LEVELS[log.level] ?? 'text-slate-400'}`}>[{log.level}]</span>
                    <span className="text-slate-300">{log.msg}</span>
                  </div>
                ))
            }
            <div ref={bottomRef} />
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

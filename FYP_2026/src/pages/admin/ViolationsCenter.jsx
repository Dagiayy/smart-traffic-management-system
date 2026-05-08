import React, { useState, useEffect } from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { AlertTriangle, Filter, RefreshCw, ChevronDown } from 'lucide-react';

const VIOLATION_TYPES = ['Red Light', 'Speeding', 'Wrong Lane', 'Blocked Box', 'No Stop'];
const LANES = ['North', 'South', 'East', 'West'];
const STATUSES = ['Detected', 'Under Review', 'Confirmed', 'Dismissed'];

function generateViolation(id, tick) {
  const type = VIOLATION_TYPES[Math.floor(Math.random() * VIOLATION_TYPES.length)];
  const lane = LANES[Math.floor(Math.random() * LANES.length)];
  const status = STATUSES[Math.floor(Math.random() * STATUSES.length)];
  const plate = `${String.fromCharCode(65 + Math.floor(Math.random() * 26))}${String.fromCharCode(65 + Math.floor(Math.random() * 26))}-${Math.floor(1000 + Math.random() * 9000)}`;
  return { id, type, lane, status, plate, tick, speed: Math.floor(40 + Math.random() * 60), time: new Date(Date.now() - Math.random() * 3600000).toLocaleTimeString() };
}

export default function ViolationsCenter() {
  const { state } = useSimulation();
  const [violations, setViolations] = useState(() => Array.from({ length: 12 }, (_, i) => generateViolation(i + 1, i + 1)));
  const [filter, setFilter] = useState('All');
  const [statusFilter, setStatusFilter] = useState('All');

  useEffect(() => {
    if (state.running && state.tick % 5 === 0 && state.tick > 0) {
      setViolations(v => [generateViolation(Date.now(), state.tick), ...v].slice(0, 50));
    }
  }, [state.tick]);

  const filtered = violations.filter(v =>
    (filter === 'All' || v.type === filter) &&
    (statusFilter === 'All' || v.status === statusFilter)
  );

  const statusColor = { 'Detected': 'bg-blue-100 text-blue-700', 'Under Review': 'bg-yellow-100 text-yellow-700', 'Confirmed': 'bg-red-100 text-red-700', 'Dismissed': 'bg-gray-100 text-gray-500' };

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <AlertTriangle className="w-5 h-5 text-red-500" />
          <h1 className="text-xl font-bold">Violations Center</h1>
          <Badge variant="destructive" className="text-xs">{violations.length} total</Badge>
        </div>
        <Button size="sm" variant="outline" className="h-8 text-xs" onClick={() => setViolations(v => [generateViolation(Date.now(), state.tick), ...v].slice(0, 50))}>
          <RefreshCw className="w-3 h-3 mr-1" /> Generate New
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {VIOLATION_TYPES.slice(0, 4).map(type => (
          <Card key={type}>
            <CardContent className="pt-4 pb-3 px-4">
              <p className="text-[10px] text-muted-foreground uppercase tracking-wide">{type}</p>
              <p className="text-2xl font-bold font-mono text-foreground">{violations.filter(v => v.type === type).length}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2">
        <div className="flex items-center gap-1">
          <Filter className="w-3.5 h-3.5 text-muted-foreground" />
          <span className="text-xs text-muted-foreground">Type:</span>
          {['All', ...VIOLATION_TYPES].map(f => (
            <button key={f} onClick={() => setFilter(f)} className={`px-2.5 py-1 rounded-full text-[10px] font-medium transition-all ${filter === f ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>{f}</button>
          ))}
        </div>
        <div className="flex items-center gap-1 ml-4">
          <span className="text-xs text-muted-foreground">Status:</span>
          {['All', ...STATUSES].map(s => (
            <button key={s} onClick={() => setStatusFilter(s)} className={`px-2.5 py-1 rounded-full text-[10px] font-medium transition-all ${statusFilter === s ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>{s}</button>
          ))}
        </div>
      </div>

      {/* Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  {['#', 'Plate', 'Type', 'Lane', 'Speed', 'Status', 'Time'].map(h => (
                    <th key={h} className="text-left px-4 py-3 text-[10px] text-muted-foreground font-semibold uppercase tracking-wide">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filtered.map((v, i) => (
                  <tr key={v.id} className={`border-b border-border/50 hover:bg-muted/20 transition-colors ${i % 2 === 0 ? '' : 'bg-muted/10'}`}>
                    <td className="px-4 py-2.5 font-mono text-muted-foreground">{String(i + 1).padStart(3, '0')}</td>
                    <td className="px-4 py-2.5 font-mono font-bold text-foreground">{v.plate}</td>
                    <td className="px-4 py-2.5 font-medium">{v.type}</td>
                    <td className="px-4 py-2.5 text-muted-foreground">{v.lane}</td>
                    <td className="px-4 py-2.5 font-mono">{v.speed} km/h</td>
                    <td className="px-4 py-2.5">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${statusColor[v.status]}`}>{v.status}</span>
                    </td>
                    <td className="px-4 py-2.5 text-muted-foreground font-mono">{v.time}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
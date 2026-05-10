import React, { useState, useEffect, useCallback } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { AlertTriangle, Filter, RefreshCw } from 'lucide-react';
import { violationsApi } from '@/api/admin';
import { openViolationFeed } from '@/api/websocket';

const STATUS_COLOR = {
  DETECTED: 'bg-blue-100 text-blue-700',
  UNDER_REVIEW: 'bg-yellow-100 text-yellow-700',
  CONFIRMED: 'bg-red-100 text-red-700',
  DISMISSED: 'bg-gray-100 text-gray-500',
  SUBMITTED: 'bg-purple-100 text-purple-700',
  SYNCED: 'bg-teal-100 text-teal-700',
};

const SEV_COLOR = {
  MINOR: 'bg-sky-100 text-sky-700',
  MAJOR: 'bg-amber-100 text-amber-700',
  CRITICAL: 'bg-red-100 text-red-700',
};

export default function ViolationsCenter() {
  const { state } = useSimulation();
  const queryClient = useQueryClient();
  const [statusFilter, setStatusFilter] = useState('');
  const [severityFilter, setSeverityFilter] = useState('');

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['admin-violations', statusFilter, severityFilter],
    queryFn: () => violationsApi.list({
      ...(statusFilter && { status: statusFilter }),
      ...(severityFilter && { severity: severityFilter }),
      page_size: 50,
    }).then(r => r.data),
    staleTime: 10000,
  });

  // Live WebSocket feed — new violations appear in real time
  useEffect(() => {
    const ws = openViolationFeed(() => {
      queryClient.invalidateQueries({ queryKey: ['admin-violations'] });
    });
    return () => ws.close();
  }, [queryClient]);

  const violations = data?.results ?? [];

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <AlertTriangle className="w-5 h-5 text-red-500" />
          <h1 className="text-xl font-bold">Violations Center</h1>
          <Badge variant="destructive" className="text-xs">{data?.count ?? 0} total</Badge>
          <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" title="Live feed active" />
        </div>
        <Button size="sm" variant="outline" className="h-8 text-xs" onClick={() => refetch()}>
          <RefreshCw className="w-3 h-3 mr-1" /> Refresh
        </Button>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {[
          { label: 'Detected', status: 'DETECTED', color: 'text-blue-600' },
          { label: 'Under Review', status: 'UNDER_REVIEW', color: 'text-yellow-600' },
          { label: 'Confirmed', status: 'CONFIRMED', color: 'text-red-600' },
          { label: 'Dismissed', status: 'DISMISSED', color: 'text-gray-500' },
        ].map(s => (
          <Card key={s.status} className="cursor-pointer hover:border-primary/30 transition-colors"
            onClick={() => setStatusFilter(f => f === s.status ? '' : s.status)}>
            <CardContent className="pt-4 pb-3 px-4">
              <p className="text-[10px] text-muted-foreground uppercase">{s.label}</p>
              <p className={`text-2xl font-bold font-mono ${s.color}`}>
                {violations.filter(v => v.status === s.status).length}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2">
        <div className="flex items-center gap-1">
          <Filter className="w-3.5 h-3.5 text-muted-foreground" />
          <span className="text-xs text-muted-foreground">Status:</span>
          {['', 'DETECTED', 'UNDER_REVIEW', 'CONFIRMED', 'DISMISSED'].map(s => (
            <button key={s} onClick={() => setStatusFilter(s)}
              className={`px-2.5 py-1 rounded-full text-[10px] font-medium transition-all ${statusFilter === s ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>
              {s || 'All'}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-1 ml-4">
          <span className="text-xs text-muted-foreground">Severity:</span>
          {['', 'MINOR', 'MAJOR', 'CRITICAL'].map(s => (
            <button key={s} onClick={() => setSeverityFilter(s)}
              className={`px-2.5 py-1 rounded-full text-[10px] font-medium transition-all ${severityFilter === s ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>
              {s || 'All'}
            </button>
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
                  {['#', 'Plate', 'Type', 'Severity', 'Source', 'Location', 'Status', 'Date'].map(h => (
                    <th key={h} className="text-left px-4 py-3 text-[10px] text-muted-foreground font-semibold uppercase tracking-wide">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {isLoading && (
                  <tr><td colSpan={8} className="text-center py-8 text-muted-foreground">Loading violations…</td></tr>
                )}
                {!isLoading && violations.length === 0 && (
                  <tr><td colSpan={8} className="text-center py-8 text-muted-foreground">No violations found</td></tr>
                )}
                {violations.map((v, i) => (
                  <tr key={v.id} className={`border-b border-border/50 hover:bg-muted/20 transition-colors ${i % 2 === 0 ? '' : 'bg-muted/10'}`}>
                    <td className="px-4 py-2.5 font-mono text-muted-foreground">{String(i + 1).padStart(3, '0')}</td>
                    <td className="px-4 py-2.5 font-mono font-bold text-foreground">{v.plate_number}</td>
                    <td className="px-4 py-2.5 font-medium">{v.violation_type?.name ?? v.type_code}</td>
                    <td className="px-4 py-2.5">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${SEV_COLOR[v.severity] ?? 'bg-gray-100 text-gray-600'}`}>{v.severity}</span>
                    </td>
                    <td className="px-4 py-2.5 text-muted-foreground">{v.source === 'AI_DETECTION' ? '🤖 AI' : '👮 Officer'}</td>
                    <td className="px-4 py-2.5 text-muted-foreground max-w-[140px] truncate">{v.location_name ?? '—'}</td>
                    <td className="px-4 py-2.5">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${STATUS_COLOR[v.status] ?? 'bg-gray-100 text-gray-500'}`}>{v.status}</span>
                    </td>
                    <td className="px-4 py-2.5 text-muted-foreground font-mono whitespace-nowrap">
                      {new Date(v.detected_at).toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {data?.next && (
            <div className="p-3 text-center border-t border-border">
              <span className="text-xs text-muted-foreground">Showing {violations.length} of {data.count} violations</span>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  ShieldAlert, CheckCircle, XCircle, Clock, Search,
  Filter, Send, BarChart2, TrendingUp, Eye, RefreshCw, DollarSign
} from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, LineChart, Line, CartesianGrid } from 'recharts';
import ViolationReviewModal from '@/components/enforcement/ViolationReviewModal';
import { violationsApi, finesApi, disputesApi } from '@/api/admin';
import toast from 'react-hot-toast';

const STATUS_STYLES = {
  DETECTED:     'bg-blue-100 text-blue-700 border-blue-200',
  UNDER_REVIEW: 'bg-amber-100 text-amber-700 border-amber-200',
  CONFIRMED:    'bg-green-100 text-green-700 border-green-200',
  DISMISSED:    'bg-red-100 text-red-700 border-red-200',
  SUBMITTED:    'bg-purple-100 text-purple-700 border-purple-200',
};

export default function PunishmentSystem() {
  const queryClient = useQueryClient();
  const [statusFilter, setStatusFilter] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedViolation, setSelectedViolation] = useState(null);
  const [activeTab, setActiveTab] = useState('violations');

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['punishment-violations', statusFilter],
    queryFn: () => violationsApi.list({
      ...(statusFilter && { status: statusFilter }),
      page_size: 100,
    }).then(r => r.data),
    staleTime: 15000,
  });

  const { data: finesData } = useQuery({
    queryKey: ['admin-fines'],
    queryFn: () => finesApi.list({ page_size: 50 }).then(r => r.data),
    staleTime: 30000,
    enabled: activeTab === 'analytics',
  });

  const { data: disputesData } = useQuery({
    queryKey: ['admin-disputes'],
    queryFn: () => disputesApi.list({ page_size: 50 }).then(r => r.data),
    staleTime: 30000,
    enabled: activeTab === 'analytics',
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, status }) => violationsApi.update(id, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['punishment-violations'] });
      toast.success('Status updated');
    },
    onError: () => toast.error('Update failed'),
  });

  const violations = data?.results ?? [];

  const filtered = useMemo(() => violations.filter(v => {
    const matchStatus = !statusFilter || v.status === statusFilter;
    const matchSearch = !searchQuery ||
      v.plate_number?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      v.violation_type?.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      v.location_name?.toLowerCase().includes(searchQuery.toLowerCase());
    return matchStatus && matchSearch;
  }), [violations, statusFilter, searchQuery]);

  const counts = {
    total: violations.length,
    pending: violations.filter(v => v.status === 'DETECTED').length,
    confirmed: violations.filter(v => v.status === 'CONFIRMED').length,
    dismissed: violations.filter(v => v.status === 'DISMISSED').length,
    review: violations.filter(v => v.status === 'UNDER_REVIEW').length,
  };

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <ShieldAlert className="w-5 h-5 text-primary" />
          <h1 className="text-xl font-bold text-foreground">Violation & Enforcement</h1>
          <Badge className="text-[10px] bg-primary/10 text-primary border border-primary/20">
            Live · Django Backend
          </Badge>
        </div>
        <Button size="sm" variant="outline" className="h-8 text-xs" onClick={() => refetch()}>
          <RefreshCw className="w-3 h-3 mr-1" /> Refresh
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        {[
          { label: 'Total', value: counts.total, color: 'text-foreground', icon: BarChart2 },
          { label: 'Detected', value: counts.pending, color: 'text-blue-600', icon: Clock },
          { label: 'Confirmed', value: counts.confirmed, color: 'text-green-600', icon: CheckCircle },
          { label: 'Dismissed', value: counts.dismissed, color: 'text-red-600', icon: XCircle },
          { label: 'Under Review', value: counts.review, color: 'text-amber-600', icon: Eye },
        ].map(({ label, value, color, icon: Icon }) => (
          <Card key={label}>
            <CardContent className="pt-4 pb-3 px-4">
              <div className="flex items-center justify-between mb-1">
                <p className="text-[10px] text-muted-foreground uppercase tracking-wide">{label}</p>
                <Icon className={`w-3.5 h-3.5 ${color} opacity-70`} />
              </div>
              <p className={`text-2xl font-bold font-mono ${color}`}>{value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Tabs */}
      <div className="flex border-b border-border gap-0">
        {[
          { id: 'violations', label: 'Violations', icon: ShieldAlert },
          { id: 'analytics', label: 'Analytics', icon: TrendingUp },
        ].map(tab => (
          <button key={tab.id} onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-1.5 px-4 py-2.5 text-xs font-semibold border-b-2 transition-colors ${activeTab === tab.id ? 'border-primary text-primary' : 'border-transparent text-muted-foreground hover:text-foreground'}`}>
            <tab.icon className="w-3.5 h-3.5" />{tab.label}
          </button>
        ))}
      </div>

      {activeTab === 'violations' && (
        <>
          {/* Search & filter */}
          <div className="flex flex-wrap gap-2 items-center">
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
              <Input placeholder="Search plate, type, location..." className="h-8 pl-8 text-xs w-64"
                value={searchQuery} onChange={e => setSearchQuery(e.target.value)} />
            </div>
            <div className="flex items-center gap-1.5">
              <Filter className="w-3.5 h-3.5 text-muted-foreground" />
              {['', 'DETECTED', 'UNDER_REVIEW', 'CONFIRMED', 'DISMISSED'].map(s => (
                <button key={s} onClick={() => setStatusFilter(s)}
                  className={`px-2.5 py-1 rounded-full text-[10px] font-semibold transition-all ${statusFilter === s ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'}`}>
                  {s || 'All'}
                </button>
              ))}
            </div>
          </div>

          <Card>
            <CardContent className="p-0">
              <div className="overflow-x-auto">
                <table className="w-full text-xs">
                  <thead>
                    <tr className="border-b border-border bg-muted/40">
                      {['Time', 'Plate', 'Type', 'Severity', 'Source', 'Location', 'Status', 'Actions'].map(h => (
                        <th key={h} className="text-left px-4 py-3 text-[10px] text-muted-foreground font-semibold uppercase tracking-wide whitespace-nowrap">{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {isLoading && <tr><td colSpan={8} className="text-center py-8 text-muted-foreground">Loading…</td></tr>}
                    {!isLoading && filtered.length === 0 && <tr><td colSpan={8} className="text-center py-8 text-muted-foreground">No violations found</td></tr>}
                    {filtered.map((v, i) => (
                      <tr key={v.id}
                        className={`border-b border-border/40 hover:bg-muted/20 transition-colors cursor-pointer ${i % 2 === 0 ? '' : 'bg-muted/10'}`}
                        onClick={() => setSelectedViolation(v)}>
                        <td className="px-4 py-2.5 font-mono text-[11px] whitespace-nowrap">{new Date(v.detected_at).toLocaleTimeString()}</td>
                        <td className="px-4 py-2.5 font-mono font-bold">{v.plate_number}</td>
                        <td className="px-4 py-2.5 whitespace-nowrap">{v.violation_type?.name ?? v.type_code}</td>
                        <td className="px-4 py-2.5">
                          <span className={`px-1.5 py-0.5 rounded text-[10px] font-semibold ${v.severity === 'CRITICAL' ? 'bg-red-100 text-red-700' : v.severity === 'MAJOR' ? 'bg-amber-100 text-amber-700' : 'bg-sky-100 text-sky-700'}`}>
                            {v.severity}
                          </span>
                        </td>
                        <td className="px-4 py-2.5 text-muted-foreground">{v.source === 'AI_DETECTION' ? '🤖 AI' : '👮 Field'}</td>
                        <td className="px-4 py-2.5 text-muted-foreground max-w-[120px] truncate">{v.location_name ?? '—'}</td>
                        <td className="px-4 py-2.5">
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold border ${STATUS_STYLES[v.status] ?? ''}`}>{v.status}</span>
                        </td>
                        <td className="px-4 py-2.5" onClick={e => e.stopPropagation()}>
                          <div className="flex items-center gap-1">
                            <button title="Review" className="p-1.5 rounded-lg hover:bg-primary/10 text-primary"
                              onClick={() => setSelectedViolation(v)}>
                              <Eye className="w-3.5 h-3.5" />
                            </button>
                            {v.status === 'DETECTED' && <>
                              <button title="Confirm" className="p-1.5 rounded-lg hover:bg-green-100 text-green-600"
                                onClick={() => updateMutation.mutate({ id: v.id, status: 'CONFIRMED' })}>
                                <CheckCircle className="w-3.5 h-3.5" />
                              </button>
                              <button title="Dismiss" className="p-1.5 rounded-lg hover:bg-red-100 text-red-500"
                                onClick={() => updateMutation.mutate({ id: v.id, status: 'DISMISSED' })}>
                                <XCircle className="w-3.5 h-3.5" />
                              </button>
                            </>}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {data?.count > violations.length && (
                <div className="p-3 text-center border-t border-border text-xs text-muted-foreground">
                  Showing {violations.length} of {data.count}
                </div>
              )}
            </CardContent>
          </Card>
        </>
      )}

      {activeTab === 'analytics' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {disputesData && (
            <Card>
              <CardHeader className="pb-2 pt-4 px-4">
                <CardTitle className="text-sm font-semibold">Disputes by Status</CardTitle>
              </CardHeader>
              <CardContent className="px-4 pb-4">
                <div className="grid grid-cols-2 gap-3">
                  {['SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED'].map(s => (
                    <div key={s} className="rounded-lg bg-muted/40 px-3 py-2.5 text-center">
                      <p className="text-[9px] text-muted-foreground">{s}</p>
                      <p className="text-xl font-bold font-mono">{(disputesData.results ?? []).filter(d => d.status === s).length}</p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
          {finesData && (
            <Card>
              <CardHeader className="pb-2 pt-4 px-4">
                <CardTitle className="text-sm font-semibold">Fines Overview</CardTitle>
              </CardHeader>
              <CardContent className="px-4 pb-4">
                <div className="grid grid-cols-2 gap-3">
                  {['UNPAID', 'PAID', 'DISPUTED', 'WAIVED'].map(s => (
                    <div key={s} className={`rounded-lg px-3 py-2.5 text-center ${s === 'UNPAID' ? 'bg-red-50 border border-red-100' : s === 'PAID' ? 'bg-green-50 border border-green-100' : 'bg-muted/40'}`}>
                      <p className="text-[9px] text-muted-foreground">{s}</p>
                      <p className={`text-xl font-bold font-mono ${s === 'UNPAID' ? 'text-red-600' : s === 'PAID' ? 'text-green-600' : ''}`}>
                        {(finesData.results ?? []).filter(f => f.status === s).length}
                      </p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {selectedViolation && (
        <ViolationReviewModal
          violation={{
            ...selectedViolation,
            type: selectedViolation.violation_type?.name,
            intersection: selectedViolation.location_name ?? '—',
            confidence: selectedViolation.ai_confidence ?? 0.85,
            signalState: 'red',
          }}
          onConfirm={(id) => {
            updateMutation.mutate({ id, status: 'CONFIRMED' });
            setSelectedViolation(null);
          }}
          onReject={(id) => {
            updateMutation.mutate({ id, status: 'DISMISSED' });
            setSelectedViolation(null);
          }}
          onClose={() => setSelectedViolation(null)}
        />
      )}
    </div>
  );
}

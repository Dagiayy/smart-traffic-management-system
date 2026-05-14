import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  AlertTriangle, RefreshCw, Search, Filter, X, ChevronLeft,
  ChevronRight, Wifi, WifiOff, Eye, CheckCircle, XCircle, Clock,
  Car, MapPin, User, Zap, TrendingUp, Activity, Shield, Gavel,
} from 'lucide-react';
import { violationsApi } from '@/api/admin';
import { openViolationFeed } from '@/api/websocket';
import ViolationDetailModal from '@/components/enforcement/ViolationDetailModal';

// ── Constants ─────────────────────────────────────────────────────────────

const STATUS_TABS = [
  { key: '',            label: 'All',          icon: Activity,     color: 'text-foreground' },
  { key: 'DETECTED',   label: 'Detected',      icon: Zap,          color: 'text-blue-600' },
  { key: 'UNDER_REVIEW',label:'Under Review',  icon: Clock,        color: 'text-amber-600' },
  { key: 'CONFIRMED',  label: 'Confirmed',     icon: CheckCircle,  color: 'text-red-600' },
  { key: 'DISMISSED',  label: 'Dismissed',     icon: XCircle,      color: 'text-gray-500' },
];

const STATUS_STYLE = {
  DETECTED:     'bg-blue-50 text-blue-700 border-blue-200',
  UNDER_REVIEW: 'bg-amber-50 text-amber-700 border-amber-200',
  CONFIRMED:    'bg-red-50 text-red-700 border-red-200',
  DISMISSED:    'bg-gray-100 text-gray-500 border-gray-200',
  SUBMITTED:    'bg-purple-50 text-purple-700 border-purple-200',
  SYNCED:       'bg-teal-50 text-teal-700 border-teal-200',
  DRAFT:        'bg-slate-100 text-slate-600 border-slate-200',
};

const SEV_STYLE = {
  MINOR:    'bg-sky-50 text-sky-700',
  MAJOR:    'bg-amber-50 text-amber-700',
  CRITICAL: 'bg-red-100 text-red-700 font-bold',
};

// ── Helpers ───────────────────────────────────────────────────────────────

const fmt = (dt) => dt
  ? new Date(dt).toLocaleString('en-ET', { month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' })
  : '—';

const fmtETB = (n) => n != null
  ? `ETB ${parseFloat(n).toLocaleString('en-ET', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`
  : '—';

// ── Skeleton row ──────────────────────────────────────────────────────────
function SkeletonRow() {
  return (
    <tr className="border-b border-border/40 animate-pulse">
      {[40, 88, 140, 100, 80, 72, 130, 80, 100].map((w, i) => (
        <td key={i} className="px-3 py-3">
          <div className="h-3 rounded bg-muted" style={{ width: w }} />
        </td>
      ))}
    </tr>
  );
}

// ── Summary Card ──────────────────────────────────────────────────────────
function SummaryCard({ tab, count, isActive, onClick }) {
  const Icon = tab.icon;
  return (
    <button
      onClick={onClick}
      className={`rounded-xl border p-3 text-left w-full transition-all hover:shadow-sm ${
        isActive
          ? 'border-primary bg-primary/5 shadow-sm'
          : 'border-border bg-card hover:border-primary/30'
      }`}
    >
      <div className="flex items-center justify-between mb-1">
        <Icon className={`w-4 h-4 ${tab.color}`} />
        {isActive && <div className="w-1.5 h-1.5 rounded-full bg-primary" />}
      </div>
      <p className={`text-2xl font-bold font-mono ${tab.color}`}>{count ?? '—'}</p>
      <p className="text-[10px] text-muted-foreground mt-0.5 font-medium">{tab.label}</p>
    </button>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────

export default function ViolationsCenter() {
  const queryClient = useQueryClient();
  const searchRef = useRef(null);

  // ── Filter state ──────────────────────────────────────────────────────
  const [activeStatus, setActiveStatus] = useState('');
  const [severity, setSeverity] = useState('');
  const [source, setSource] = useState('');
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [page, setPage] = useState(1);
  const PAGE_SIZE = 25;

  // ── Detail modal ──────────────────────────────────────────────────────
  const [selectedId, setSelectedId] = useState(null);

  // ── WebSocket live feed ───────────────────────────────────────────────
  const [wsConnected, setWsConnected] = useState(false);
  useEffect(() => {
    let ws;
    try {
      ws = openViolationFeed(() => {
        queryClient.invalidateQueries({ queryKey: ['admin-violations'] });
        queryClient.invalidateQueries({ queryKey: ['admin-violations-counts'] });
      });
      setWsConnected(true);
    } catch {
      setWsConnected(false);
    }
    return () => { try { ws?.close(); } catch {} };
  }, [queryClient]);

  // ── Reset page on filter change ───────────────────────────────────────
  useEffect(() => { setPage(1); }, [activeStatus, severity, source, search, dateFrom, dateTo]);

  // ── Search debounce ───────────────────────────────────────────────────
  useEffect(() => {
    const t = setTimeout(() => setSearch(searchInput.trim()), 400);
    return () => clearTimeout(t);
  }, [searchInput]);

  // ── Counts query (all statuses) ───────────────────────────────────────
  const { data: countsData } = useQuery({
    queryKey: ['admin-violations-counts', severity, source, search, dateFrom, dateTo],
    queryFn: () => violationsApi.list({
      ...(severity && { severity }),
      ...(source && { source }),
      ...(search && { search }),
      ...(dateFrom && { date_from: dateFrom }),
      ...(dateTo && { date_to: dateTo }),
      page_size: 1,
    }).then(r => r.data),
    staleTime: 15000,
    select: (d) => d.count,
  });

  // Counts per status (run 4 light queries in parallel via Promise.all
  // — but since React Query batches well, we do 4 separate queries)
  const statusCounts = {};
  for (const tab of STATUS_TABS.filter(t => t.key)) {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    const { data } = useQuery({
      queryKey: ['admin-violations-count', tab.key, severity, source, search, dateFrom, dateTo],
      queryFn: () => violationsApi.list({
        status: tab.key,
        ...(severity && { severity }),
        ...(source && { source }),
        ...(search && { search }),
        ...(dateFrom && { date_from: dateFrom }),
        ...(dateTo && { date_to: dateTo }),
        page_size: 1,
      }).then(r => r.data.count),
      staleTime: 15000,
    });
    statusCounts[tab.key] = data;
  }

  // ── Main list query ───────────────────────────────────────────────────
  const { data, isLoading, isFetching, refetch } = useQuery({
    queryKey: ['admin-violations', activeStatus, severity, source, search, dateFrom, dateTo, page],
    queryFn: () => violationsApi.list({
      ...(activeStatus && { status: activeStatus }),
      ...(severity && { severity }),
      ...(source && { source }),
      ...(search && { search }),
      ...(dateFrom && { date_from: dateFrom }),
      ...(dateTo && { date_to: dateTo }),
      page,
      page_size: PAGE_SIZE,
    }).then(r => r.data),
    staleTime: 10000,
    keepPreviousData: true,
  });

  const violations = data?.results ?? [];
  const totalCount = data?.count ?? 0;
  const totalPages = Math.ceil(totalCount / PAGE_SIZE);
  const hasFilters = activeStatus || severity || source || search || dateFrom || dateTo;

  const clearFilters = () => {
    setActiveStatus(''); setSeverity(''); setSource('');
    setSearchInput(''); setSearch(''); setDateFrom(''); setDateTo('');
  };

  return (
    <div className="h-full flex flex-col bg-background">
      {/* ── Page Header ── */}
      <div className="px-6 pt-5 pb-3 border-b border-border bg-card/50 flex-shrink-0">
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div className="flex items-center gap-2.5">
            <div className="p-2 bg-red-100 rounded-xl">
              <AlertTriangle className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <h1 className="text-lg font-bold leading-tight">Violations &amp; Enforcement</h1>
              <p className="text-[11px] text-muted-foreground">
                Monitor, review, and act on traffic violations
              </p>
            </div>
            {/* Live indicator */}
            <div className="flex items-center gap-1.5 ml-2 px-2.5 py-1 rounded-full bg-muted/50 border border-border">
              {wsConnected
                ? <><div className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse" /><span className="text-[10px] text-green-600 font-medium">Live</span></>
                : <><WifiOff className="w-3 h-3 text-muted-foreground" /><span className="text-[10px] text-muted-foreground">Offline</span></>
              }
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Badge variant="outline" className="text-xs font-mono">
              {totalCount.toLocaleString()} violations
            </Badge>
            <Button
              size="sm"
              variant="outline"
              className="h-8 text-xs gap-1.5"
              onClick={() => {
                refetch();
                queryClient.invalidateQueries({ queryKey: ['admin-violations-count'] });
              }}
              disabled={isFetching}
            >
              <RefreshCw className={`w-3 h-3 ${isFetching ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
          </div>
        </div>

        {/* ── Summary Cards ── */}
        <div className="mt-4 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-2.5">
          {/* All */}
          <SummaryCard
            tab={STATUS_TABS[0]}
            count={countsData}
            isActive={activeStatus === ''}
            onClick={() => setActiveStatus('')}
          />
          {STATUS_TABS.slice(1).map(tab => (
            <SummaryCard
              key={tab.key}
              tab={tab}
              count={statusCounts[tab.key]}
              isActive={activeStatus === tab.key}
              onClick={() => setActiveStatus(t => t === tab.key ? '' : tab.key)}
            />
          ))}
        </div>
      </div>

      {/* ── Filters ── */}
      <div className="px-6 py-3 border-b border-border bg-muted/20 flex-shrink-0">
        <div className="flex flex-wrap items-center gap-2">
          {/* Search */}
          <div className="relative flex-1 min-w-[180px] max-w-xs">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground pointer-events-none" />
            <input
              ref={searchRef}
              value={searchInput}
              onChange={e => setSearchInput(e.target.value)}
              placeholder="Plate, owner name, type, location…"
              className="w-full pl-8 pr-3 py-1.5 text-xs rounded-lg border border-border bg-background focus:outline-none focus:ring-1 focus:ring-primary/40 placeholder:text-muted-foreground/60"
            />
            {searchInput && (
              <button
                onClick={() => { setSearchInput(''); setSearch(''); }}
                className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                <X className="w-3 h-3" />
              </button>
            )}
          </div>

          {/* Severity */}
          <div className="flex items-center gap-1">
            <span className="text-[10px] text-muted-foreground">Severity:</span>
            {['', 'MINOR', 'MAJOR', 'CRITICAL'].map(s => (
              <button
                key={s}
                onClick={() => setSeverity(s)}
                className={`px-2.5 py-1 rounded-full text-[10px] font-medium transition-all ${
                  severity === s ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'
                }`}
              >
                {s || 'All'}
              </button>
            ))}
          </div>

          {/* Source */}
          <div className="flex items-center gap-1">
            <span className="text-[10px] text-muted-foreground">Source:</span>
            {[
              { v: '', label: 'All' },
              { v: 'AI_DETECTION', label: '🤖 AI' },
              { v: 'OFFICER_FIELD', label: '👮 Officer' },
            ].map(s => (
              <button
                key={s.v}
                onClick={() => setSource(s.v)}
                className={`px-2.5 py-1 rounded-full text-[10px] font-medium transition-all ${
                  source === s.v ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'
                }`}
              >
                {s.label}
              </button>
            ))}
          </div>

          {/* Date range */}
          <div className="flex items-center gap-1.5">
            <span className="text-[10px] text-muted-foreground">From:</span>
            <input
              type="date"
              value={dateFrom}
              onChange={e => setDateFrom(e.target.value)}
              className="text-[10px] rounded border border-border bg-background px-2 py-1 focus:outline-none focus:ring-1 focus:ring-primary/40"
            />
            <span className="text-[10px] text-muted-foreground">To:</span>
            <input
              type="date"
              value={dateTo}
              onChange={e => setDateTo(e.target.value)}
              className="text-[10px] rounded border border-border bg-background px-2 py-1 focus:outline-none focus:ring-1 focus:ring-primary/40"
            />
          </div>

          {/* Clear */}
          {hasFilters && (
            <button
              onClick={clearFilters}
              className="flex items-center gap-1 text-[10px] text-muted-foreground hover:text-foreground transition-colors px-2 py-1 rounded-lg hover:bg-muted"
            >
              <X className="w-3 h-3" /> Clear filters
            </button>
          )}
        </div>
      </div>

      {/* ── Table ── */}
      <div className="flex-1 overflow-hidden flex flex-col px-6 py-3">
        <div className="flex-1 overflow-auto rounded-xl border border-border bg-card shadow-sm">
          <table className="w-full text-xs min-w-[900px]">
            <thead className="sticky top-0 z-10">
              <tr className="bg-muted/60 border-b border-border">
                {[
                  { label: '#',             w: 'w-10' },
                  { label: 'Plate',         w: 'w-24' },
                  { label: 'Owner / Driver',w: 'w-36' },
                  { label: 'Violation Type',w: 'w-40' },
                  { label: 'Severity',      w: 'w-20' },
                  { label: 'Source',        w: 'w-20' },
                  { label: 'Location',      w: 'w-36' },
                  { label: 'Status',        w: 'w-24' },
                  { label: 'Fine',          w: 'w-24' },
                  { label: 'Detected At',   w: 'w-32' },
                  { label: '',              w: 'w-10' },
                ].map(h => (
                  <th key={h.label} className={`text-left px-3 py-2.5 text-[10px] font-semibold uppercase tracking-wide text-muted-foreground ${h.w}`}>
                    {h.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {isLoading && Array.from({ length: 8 }).map((_, i) => <SkeletonRow key={i} />)}

              {!isLoading && violations.length === 0 && (
                <tr>
                  <td colSpan={11} className="text-center py-16">
                    <div className="flex flex-col items-center gap-2 text-muted-foreground">
                      <Shield className="w-10 h-10 opacity-20" />
                      <p className="text-sm font-medium">No violations found</p>
                      {hasFilters && (
                        <button onClick={clearFilters} className="text-xs text-primary hover:underline">
                          Clear filters to see all
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              )}

              {violations.map((v, i) => {
                const rowNum = (page - 1) * PAGE_SIZE + i + 1;
                const st = STATUS_STYLE[v.status] || 'bg-gray-100 text-gray-500 border-gray-200';
                const sv = SEV_STYLE[v.severity] || 'bg-gray-100 text-gray-500';
                const displayName = v.owner_name || v.driver_name || '—';
                return (
                  <tr
                    key={v.id}
                    onClick={() => setSelectedId(v.id)}
                    className={`border-b border-border/40 cursor-pointer hover:bg-primary/5 transition-colors ${
                      selectedId === v.id ? 'bg-primary/5' : i % 2 === 0 ? '' : 'bg-muted/10'
                    }`}
                  >
                    {/* # */}
                    <td className="px-3 py-2.5 font-mono text-[10px] text-muted-foreground">
                      {String(rowNum).padStart(3, '0')}
                    </td>
                    {/* Plate */}
                    <td className="px-3 py-2.5">
                      <span className="font-mono font-bold text-foreground tracking-wider">
                        {v.plate_number}
                      </span>
                    </td>
                    {/* Owner */}
                    <td className="px-3 py-2.5">
                      <div className="flex items-center gap-1.5">
                        <User className="w-3 h-3 text-muted-foreground flex-shrink-0" />
                        <span className="truncate max-w-[120px] text-muted-foreground">
                          {displayName}
                        </span>
                      </div>
                    </td>
                    {/* Type */}
                    <td className="px-3 py-2.5 font-medium max-w-[160px] truncate">
                      {v.violation_type?.name ?? v.type_code ?? '—'}
                    </td>
                    {/* Severity */}
                    <td className="px-3 py-2.5">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${sv}`}>
                        {v.severity}
                      </span>
                    </td>
                    {/* Source */}
                    <td className="px-3 py-2.5 text-muted-foreground whitespace-nowrap">
                      {v.source === 'AI_DETECTION' ? '🤖 AI' : '👮 Officer'}
                    </td>
                    {/* Location */}
                    <td className="px-3 py-2.5">
                      <div className="flex items-center gap-1 text-muted-foreground max-w-[130px] truncate">
                        <MapPin className="w-3 h-3 flex-shrink-0" />
                        <span className="truncate">{v.location_name || '—'}</span>
                      </div>
                    </td>
                    {/* Status */}
                    <td className="px-3 py-2.5">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold border ${st}`}>
                        {v.status?.replace('_', ' ')}
                      </span>
                    </td>
                    {/* Fine */}
                    <td className="px-3 py-2.5 font-mono text-[11px] text-muted-foreground">
                      {fmtETB(v.fine_amount)}
                    </td>
                    {/* Detected At */}
                    <td className="px-3 py-2.5 text-muted-foreground font-mono text-[10px] whitespace-nowrap">
                      {fmt(v.detected_at)}
                    </td>
                    {/* View button */}
                    <td className="px-3 py-2.5">
                      <div className="flex items-center justify-center">
                        <Eye className="w-3.5 h-3.5 text-muted-foreground/50 group-hover:text-primary" />
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* ── Pagination ── */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between pt-3 flex-shrink-0">
            <p className="text-[11px] text-muted-foreground">
              Showing <span className="font-semibold">{(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, totalCount)}</span> of{' '}
              <span className="font-semibold">{totalCount.toLocaleString()}</span> violations
            </p>
            <div className="flex items-center gap-1.5">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1.5 rounded-lg border border-border hover:bg-muted disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              {/* Page numbers */}
              {Array.from({ length: Math.min(7, totalPages) }, (_, i) => {
                const p = totalPages <= 7 ? i + 1
                  : page <= 4 ? i + 1
                  : page >= totalPages - 3 ? totalPages - 6 + i
                  : page - 3 + i;
                if (p < 1 || p > totalPages) return null;
                return (
                  <button
                    key={p}
                    onClick={() => setPage(p)}
                    className={`w-7 h-7 rounded-lg text-[11px] font-medium transition-colors ${
                      p === page
                        ? 'bg-primary text-white'
                        : 'border border-border hover:bg-muted text-muted-foreground'
                    }`}
                  >
                    {p}
                  </button>
                );
              })}
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1.5 rounded-lg border border-border hover:bg-muted disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        )}

        {/* Row count when only 1 page */}
        {totalPages <= 1 && violations.length > 0 && (
          <p className="pt-2 text-[11px] text-muted-foreground">
            {violations.length} violation{violations.length !== 1 ? 's' : ''} shown
            {hasFilters && ' (filtered)'}
          </p>
        )}
      </div>

      {/* ── Detail Modal (slide-in panel) ── */}
      {selectedId && (
        <ViolationDetailModal
          violationId={selectedId}
          onClose={() => setSelectedId(null)}
        />
      )}
    </div>
  );
}

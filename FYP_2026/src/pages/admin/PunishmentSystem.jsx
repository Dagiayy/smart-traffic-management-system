import React, { useState, useEffect, useMemo } from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  ShieldAlert, CheckCircle, XCircle, Clock, Search,
  Filter, Send, BarChart2, TrendingUp, Eye, RefreshCw,
  AlertTriangle, Car, Users
} from 'lucide-react';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, LineChart, Line, CartesianGrid
} from 'recharts';
import ViolationReviewModal from '@/components/enforcement/ViolationReviewModal';

const INTERSECTIONS = ['Main & 1st', 'Oak & 5th', 'Central Ave', 'Harbor Blvd', 'Tech Park Rd'];
const VIOLATION_TYPES = [
  'Red Light Run', 'Speeding', 'Wrong Lane', 'Blocked Box',
  'Illegal U-Turn', 'Pedestrian Zone Violation'
];
const SIGNAL_STATES = ['red', 'yellow'];

function genViolation(id, tick = 0) {
  const type = VIOLATION_TYPES[Math.floor(Math.random() * VIOLATION_TYPES.length)];
  const isPedViolation = type === 'Pedestrian Zone Violation';
  const now = new Date();
  const offsetMs = Math.floor(Math.random() * 3600000);
  const t = new Date(now - offsetMs);
  const hh = String(t.getHours()).padStart(2, '0');
  const mm = String(t.getMinutes()).padStart(2, '0');
  const ss = String(t.getSeconds()).padStart(2, '0');
  return {
    id,
    time: `${hh}:${mm}:${ss}`,
    intersection: INTERSECTIONS[Math.floor(Math.random() * INTERSECTIONS.length)],
    violationType: type,
    confidence: parseFloat((0.55 + Math.random() * 0.45).toFixed(2)),
    status: 'Pending',
    plate: isPedViolation ? null : `${String.fromCharCode(65 + Math.floor(Math.random() * 26))}${String.fromCharCode(65 + Math.floor(Math.random() * 26))}-${Math.floor(1000 + Math.random() * 9000)}`,
    signalState: SIGNAL_STATES[Math.floor(Math.random() * SIGNAL_STATES.length)],
    phase: Math.floor(Math.random() * 2) + 1,
    sentToSystem: false,
    tick,
  };
}

const STATUS_STYLES = {
  Pending:   'bg-amber-100 text-amber-700 border-amber-200',
  Confirmed: 'bg-green-100 text-green-700 border-green-200',
  Rejected:  'bg-red-100 text-red-700 border-red-200',
  Sent:      'bg-blue-100 text-blue-700 border-blue-200',
};

const CONF_COLOR = (c) => {
  const pct = c * 100;
  if (pct >= 85) return 'text-green-600';
  if (pct >= 65) return 'text-amber-600';
  return 'text-red-500';
};

export default function PunishmentSystem() {
  const { state } = useSimulation();
  const [violations, setViolations] = useState(() =>
    Array.from({ length: 20 }, (_, i) => genViolation(i + 1, i))
  );
  const [statusFilter, setStatusFilter] = useState('All');
  const [intersectionFilter, setIntersectionFilter] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedViolation, setSelectedViolation] = useState(null);
  const [activeTab, setActiveTab] = useState('violations');

  // Auto-generate violations while running
  useEffect(() => {
    if (state.running && state.tick % 6 === 0 && state.tick > 0) {
      setViolations(v => [genViolation(Date.now() + Math.random(), state.tick), ...v].slice(0, 100));
    }
  }, [state.tick]);

  const updateStatus = (id, newStatus) =>
    setViolations(v => v.map(vi => vi.id === id ? { ...vi, status: newStatus } : vi));

  const sendToSystem = (id) =>
    setViolations(v => v.map(vi => vi.id === id ? { ...vi, status: 'Sent', sentToSystem: true } : vi));

  const sendAllConfirmed = () =>
    setViolations(v => v.map(vi => vi.status === 'Confirmed' ? { ...vi, status: 'Sent', sentToSystem: true } : vi));

  // Counts
  const todayTotal = violations.length;
  const pending   = violations.filter(v => v.status === 'Pending').length;
  const confirmed = violations.filter(v => v.status === 'Confirmed').length;
  const rejected  = violations.filter(v => v.status === 'Rejected').length;
  const sent      = violations.filter(v => v.status === 'Sent').length;

  // Filtered list
  const filtered = useMemo(() => {
    return violations.filter(v => {
      const matchStatus = statusFilter === 'All' || v.status === statusFilter;
      const matchIntersection = intersectionFilter === 'All' || v.intersection === intersectionFilter;
      const matchSearch = !searchQuery ||
        (v.plate && v.plate.toLowerCase().includes(searchQuery.toLowerCase())) ||
        v.violationType.toLowerCase().includes(searchQuery.toLowerCase()) ||
        v.intersection.toLowerCase().includes(searchQuery.toLowerCase());
      return matchStatus && matchIntersection && matchSearch;
    });
  }, [violations, statusFilter, intersectionFilter, searchQuery]);

  // Analytics data
  const byIntersection = INTERSECTIONS.map(name => ({
    name: name.split(' ')[0],
    count: violations.filter(v => v.intersection === name).length,
  }));

  const hourlyData = useMemo(() => {
    const hours = {};
    violations.forEach(v => {
      const h = v.time.split(':')[0];
      hours[h] = (hours[h] || 0) + 1;
    });
    return Object.entries(hours).sort((a, b) => a[0].localeCompare(b[0])).slice(-8).map(([h, count]) => ({
      hour: `${h}:00`, count,
    }));
  }, [violations]);

  return (
    <div className="p-6 space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <ShieldAlert className="w-5 h-5 text-primary" />
          <h1 className="text-xl font-bold text-foreground">Violation & Enforcement</h1>
          <Badge className="text-[10px] bg-primary/10 text-primary border border-primary/20">
            {state.running ? '● Live Detection' : 'Detection Paused'}
          </Badge>
        </div>
        <div className="flex items-center gap-2">
          <Button
            size="sm" variant="outline" className="h-8 text-xs"
            onClick={() => setViolations(v => [genViolation(Date.now(), state.tick), ...v].slice(0, 100))}
          >
            <RefreshCw className="w-3 h-3 mr-1" /> Simulate Detection
          </Button>
          <Button
            size="sm" className="h-8 text-xs bg-blue-600 hover:bg-blue-700 text-white"
            onClick={sendAllConfirmed}
            disabled={confirmed === 0}
          >
            <Send className="w-3 h-3 mr-1" /> Sync Confirmed ({confirmed})
          </Button>
        </div>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        {[
          { label: 'Total Today', value: todayTotal, color: 'text-foreground', bg: 'bg-muted/50', icon: BarChart2 },
          { label: 'Pending Review', value: pending, color: 'text-amber-600', bg: 'bg-amber-50 border border-amber-100', icon: Clock },
          { label: 'Confirmed', value: confirmed, color: 'text-green-600', bg: 'bg-green-50 border border-green-100', icon: CheckCircle },
          { label: 'Rejected', value: rejected, color: 'text-red-600', bg: 'bg-red-50 border border-red-100', icon: XCircle },
          { label: 'Sent to System', value: sent, color: 'text-blue-600', bg: 'bg-blue-50 border border-blue-100', icon: Send },
        ].map(({ label, value, color, bg, icon: Icon }) => (
          <Card key={label} className={`${bg}`}>
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
          { id: 'violations', label: 'Live Violations', icon: ShieldAlert },
          { id: 'analytics', label: 'Mini Analytics', icon: TrendingUp },
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-1.5 px-4 py-2.5 text-xs font-semibold border-b-2 transition-colors ${
              activeTab === tab.id
                ? 'border-primary text-primary'
                : 'border-transparent text-muted-foreground hover:text-foreground'
            }`}
          >
            <tab.icon className="w-3.5 h-3.5" />
            {tab.label}
          </button>
        ))}
      </div>

      {activeTab === 'violations' && (
        <>
          {/* Filters & Search */}
          <div className="flex flex-wrap gap-2 items-center">
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
              <Input
                placeholder="Search plate, type, intersection..."
                className="h-8 pl-8 text-xs w-56"
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="flex items-center gap-1.5">
              <Filter className="w-3.5 h-3.5 text-muted-foreground" />
              {['All', 'Pending', 'Confirmed', 'Rejected', 'Sent'].map(s => (
                <button
                  key={s}
                  onClick={() => setStatusFilter(s)}
                  className={`px-2.5 py-1 rounded-full text-[10px] font-semibold transition-all ${
                    statusFilter === s ? 'bg-primary text-white' : 'bg-muted text-muted-foreground hover:bg-muted/80'
                  }`}
                >
                  {s}
                </button>
              ))}
            </div>
            <select
              className="h-8 text-xs rounded-lg border border-border bg-background px-2 text-muted-foreground"
              value={intersectionFilter}
              onChange={e => setIntersectionFilter(e.target.value)}
            >
              <option value="All">All Intersections</option>
              {INTERSECTIONS.map(i => <option key={i} value={i}>{i}</option>)}
            </select>
          </div>

          {/* Violations Table */}
          <Card>
            <CardContent className="p-0">
              <div className="overflow-x-auto">
                <table className="w-full text-xs">
                  <thead>
                    <tr className="border-b border-border bg-muted/40">
                      {['Time', 'Intersection', 'Type', 'Plate / Entity', 'AI Confidence', 'Status', 'Actions'].map(h => (
                        <th key={h} className="text-left px-4 py-3 text-[10px] text-muted-foreground font-semibold uppercase tracking-wide whitespace-nowrap">{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {filtered.length === 0 && (
                      <tr><td colSpan={7} className="text-center py-8 text-muted-foreground text-xs">No violations match your filters</td></tr>
                    )}
                    {filtered.map((v, i) => (
                      <tr
                        key={v.id}
                        className={`border-b border-border/40 hover:bg-muted/20 transition-colors cursor-pointer ${i % 2 === 0 ? '' : 'bg-muted/10'}`}
                        onClick={() => setSelectedViolation(v)}
                      >
                        <td className="px-4 py-2.5 font-mono text-[11px] whitespace-nowrap">{v.time}</td>
                        <td className="px-4 py-2.5 whitespace-nowrap">
                          <span className="flex items-center gap-1">
                            {v.intersection}
                          </span>
                        </td>
                        <td className="px-4 py-2.5 whitespace-nowrap">
                          <span className="flex items-center gap-1.5">
                            {v.violationType === 'Pedestrian Zone Violation'
                              ? <Users className="w-3 h-3 text-pink-500" />
                              : <Car className="w-3 h-3 text-blue-500" />}
                            {v.violationType}
                          </span>
                        </td>
                        <td className="px-4 py-2.5 font-mono font-bold">
                          {v.plate || <span className="text-muted-foreground italic font-normal">Pedestrian</span>}
                        </td>
                        <td className="px-4 py-2.5">
                          <div className="flex items-center gap-2">
                            <div className="w-16 h-1.5 rounded-full bg-muted overflow-hidden">
                              <div
                                className={`h-full rounded-full ${v.confidence >= 0.85 ? 'bg-green-500' : v.confidence >= 0.65 ? 'bg-amber-400' : 'bg-red-400'}`}
                                style={{ width: `${v.confidence * 100}%` }}
                              />
                            </div>
                            <span className={`text-[10px] font-mono font-semibold ${CONF_COLOR(v.confidence)}`}>
                              {Math.round(v.confidence * 100)}%
                            </span>
                          </div>
                        </td>
                        <td className="px-4 py-2.5">
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold border ${STATUS_STYLES[v.status] || ''}`}>
                            {v.status}
                          </span>
                        </td>
                        <td className="px-4 py-2.5" onClick={e => e.stopPropagation()}>
                          <div className="flex items-center gap-1">
                            <button
                              title="Review"
                              className="p-1.5 rounded-lg hover:bg-primary/10 text-primary transition-colors"
                              onClick={() => setSelectedViolation(v)}
                            >
                              <Eye className="w-3.5 h-3.5" />
                            </button>
                            {v.status === 'Pending' && (
                              <>
                                <button
                                  title="Confirm"
                                  className="p-1.5 rounded-lg hover:bg-green-100 text-green-600 transition-colors"
                                  onClick={() => updateStatus(v.id, 'Confirmed')}
                                >
                                  <CheckCircle className="w-3.5 h-3.5" />
                                </button>
                                <button
                                  title="Reject"
                                  className="p-1.5 rounded-lg hover:bg-red-100 text-red-500 transition-colors"
                                  onClick={() => updateStatus(v.id, 'Rejected')}
                                >
                                  <XCircle className="w-3.5 h-3.5" />
                                </button>
                              </>
                            )}
                            {v.status === 'Confirmed' && !v.sentToSystem && (
                              <button
                                title="Send to User System"
                                className="p-1.5 rounded-lg hover:bg-blue-100 text-blue-600 transition-colors"
                                onClick={() => sendToSystem(v.id)}
                              >
                                <Send className="w-3.5 h-3.5" />
                              </button>
                            )}
                            {v.sentToSystem && (
                              <span className="text-[9px] bg-blue-50 text-blue-600 border border-blue-200 px-1.5 py-0.5 rounded-full font-semibold">SYNCED</span>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>

          {/* Integration Status Bar */}
          <Card className="border-blue-200 bg-blue-50/50">
            <CardContent className="px-4 py-3 flex flex-wrap items-center gap-4">
              <div className="flex items-center gap-2">
                <div className={`w-2 h-2 rounded-full ${confirmed > 0 ? 'bg-green-500 animate-pulse' : 'bg-muted-foreground'}`} />
                <span className="text-xs font-semibold text-foreground">User App Integration</span>
              </div>
              <div className="flex items-center gap-4 text-[11px] text-muted-foreground">
                <span><span className="font-semibold text-foreground">{sent}</span> cases forwarded</span>
                <span><span className="font-semibold text-amber-600">{confirmed}</span> ready to send</span>
              </div>
              <Button
                size="sm" className="ml-auto h-7 text-[10px] bg-blue-600 hover:bg-blue-700 text-white"
                onClick={sendAllConfirmed}
                disabled={confirmed === 0}
              >
                <Send className="w-3 h-3 mr-1" /> Send All Confirmed
              </Button>
            </CardContent>
          </Card>
        </>
      )}

      {activeTab === 'analytics' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Card>
            <CardHeader className="pb-2 pt-4 px-4">
              <CardTitle className="text-sm font-semibold">Violations by Intersection</CardTitle>
            </CardHeader>
            <CardContent className="px-4 pb-4">
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={byIntersection} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                  <XAxis dataKey="name" tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }} axisLine={false} tickLine={false} />
                  <Tooltip
                    contentStyle={{ fontSize: 11, background: 'hsl(var(--card))', border: '1px solid hsl(var(--border))', borderRadius: 8 }}
                    cursor={{ fill: 'hsl(var(--muted))' }}
                  />
                  <Bar dataKey="count" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2 pt-4 px-4">
              <CardTitle className="text-sm font-semibold">Violations Over Time</CardTitle>
            </CardHeader>
            <CardContent className="px-4 pb-4">
              {hourlyData.length > 1 ? (
                <ResponsiveContainer width="100%" height={200}>
                  <LineChart data={hourlyData} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                    <XAxis dataKey="hour" tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))' }} axisLine={false} tickLine={false} />
                    <Tooltip
                      contentStyle={{ fontSize: 11, background: 'hsl(var(--card))', border: '1px solid hsl(var(--border))', borderRadius: 8 }}
                    />
                    <Line type="monotone" dataKey="count" stroke="hsl(var(--primary))" strokeWidth={2} dot={{ r: 3, fill: 'hsl(var(--primary))' }} />
                  </LineChart>
                </ResponsiveContainer>
              ) : (
                <div className="h-48 flex items-center justify-center text-muted-foreground text-xs">
                  Not enough data yet — run the simulation to generate violations
                </div>
              )}
            </CardContent>
          </Card>

          {/* Violation type breakdown */}
          <Card className="lg:col-span-2">
            <CardHeader className="pb-2 pt-4 px-4">
              <CardTitle className="text-sm font-semibold">Violation Type Breakdown</CardTitle>
            </CardHeader>
            <CardContent className="px-4 pb-4">
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                {VIOLATION_TYPES.map(type => {
                  const count = violations.filter(v => v.violationType === type).length;
                  const pct = todayTotal > 0 ? ((count / todayTotal) * 100).toFixed(0) : 0;
                  return (
                    <div key={type} className="flex items-center gap-3 rounded-lg bg-muted/40 px-3 py-2.5">
                      <div className="flex-1">
                        <p className="text-[10px] text-muted-foreground">{type}</p>
                        <div className="mt-1 h-1.5 rounded-full bg-muted overflow-hidden">
                          <div className="h-full rounded-full bg-primary transition-all" style={{ width: `${pct}%` }} />
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-sm font-bold font-mono">{count}</p>
                        <p className="text-[9px] text-muted-foreground">{pct}%</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Review Modal */}
      {selectedViolation && (
        <ViolationReviewModal
          violation={selectedViolation}
          onConfirm={(id) => updateStatus(id, 'Confirmed')}
          onReject={(id) => updateStatus(id, 'Rejected')}
          onClose={() => setSelectedViolation(null)}
        />
      )}
    </div>
  );
}
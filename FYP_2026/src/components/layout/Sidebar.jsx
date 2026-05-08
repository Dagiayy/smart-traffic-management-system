import React from 'react';
import { cn } from '@/lib/utils';
import { useSimulation } from '@/lib/SimulationContext';
import { Badge } from '@/components/ui/badge';
import {
  LayoutDashboard, TrafficCone, AlertTriangle, Camera, DollarSign,
  BarChart2, Map, Settings, HelpCircle, Brain, TrendingUp,
  RotateCcw, SlidersHorizontal, FlaskConical, ScrollText,
  GitCompare, Shield, Code2, Activity, ChevronRight, ShieldAlert
} from 'lucide-react';

const ADMIN_ITEMS = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'live-traffic', label: 'Live Traffic Control', icon: TrafficCone },
  { id: 'violations', label: 'Violations Center', icon: AlertTriangle },
  { id: 'evidence', label: 'Evidence Panel', icon: Camera },
  { id: 'punishment', label: 'Violation & Enforcement', icon: ShieldAlert },
  { id: 'analytics', label: 'Analytics', icon: BarChart2 },
  { id: 'hotspot', label: 'Hotspot Map', icon: Map },
  { id: 'settings', label: 'Settings', icon: Settings },
  { id: 'help', label: 'Help', icon: HelpCircle },
];

const DEV_ITEMS = [
  { id: 'ai-lab', label: 'AI Simulation Lab', icon: Brain },
  { id: 'reward-analytics', label: 'Reward Analytics', icon: TrendingUp },
  { id: 'scenario-replay', label: 'Scenario Replay', icon: RotateCcw },
  { id: 'param-control', label: 'Parameter Control', icon: SlidersHorizontal },
  { id: 'experiment', label: 'Experiment Mode', icon: FlaskConical },
  { id: 'system-logs', label: 'System Logs', icon: ScrollText },
  { id: 'perf-comparison', label: 'Performance Comparison', icon: GitCompare },
  { id: 'hotspot', label: 'Hotspot Map', icon: Map },
  { id: 'help', label: 'Help', icon: HelpCircle },
];

export default function Sidebar({ activePage, onNavigate }) {
  const { appMode, setAppMode, state } = useSimulation();
  const isAdmin = appMode === 'admin';
  const items = isAdmin ? ADMIN_ITEMS : DEV_ITEMS;

  return (
    <aside className={cn(
      'w-60 min-h-[calc(100vh-56px)] border-r border-border flex flex-col',
      isAdmin ? 'bg-slate-950' : 'bg-[#0f172a]'
    )}>
      {/* Role Badge */}
      <div className="px-4 py-3 border-b border-white/10">
        <div className={cn(
          'flex items-center gap-2 rounded-lg px-3 py-2',
          isAdmin ? 'bg-blue-600/20 border border-blue-500/30' : 'bg-violet-600/20 border border-violet-500/30'
        )}>
          {isAdmin
            ? <Shield className="w-4 h-4 text-blue-400" />
            : <Code2 className="w-4 h-4 text-violet-400" />}
          <div>
            <p className={cn('text-xs font-bold', isAdmin ? 'text-blue-300' : 'text-violet-300')}>
              {isAdmin ? 'Admin Mode' : 'Developer Mode'}
            </p>
            <p className="text-[9px] text-white/40">{isAdmin ? 'Operational Control' : 'RL Analysis System'}</p>
          </div>
        </div>
      </div>

      {/* Nav Items */}
      <nav className="flex-1 py-2 px-2 overflow-y-auto">
        {items.map(item => {
          const Icon = item.icon;
          const isActive = activePage === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={cn(
                'w-full flex items-center gap-3 px-3 py-2.5 rounded-lg mb-0.5 text-left transition-all group',
                isActive
                  ? isAdmin
                    ? 'bg-blue-600 text-white'
                    : 'bg-violet-600 text-white'
                  : 'text-white/60 hover:text-white hover:bg-white/5'
              )}
            >
              <Icon className={cn('w-4 h-4 flex-shrink-0', isActive ? 'text-white' : 'text-white/40 group-hover:text-white/70')} />
              <span className="text-xs font-medium">{item.label}</span>
              {isActive && <ChevronRight className="w-3 h-3 ml-auto text-white/60" />}
            </button>
          );
        })}
      </nav>

      {/* Mode Switcher */}
      <div className="p-3 border-t border-white/10">
        <p className="text-[9px] text-white/30 uppercase tracking-wider mb-2 px-1">Switch Mode</p>
        <div className="grid grid-cols-2 gap-1.5">
          <button
            onClick={() => { setAppMode('admin'); onNavigate('dashboard'); }}
            className={cn(
              'flex items-center justify-center gap-1.5 py-2 rounded-lg text-[10px] font-semibold transition-all',
              isAdmin ? 'bg-blue-600 text-white' : 'bg-white/5 text-white/50 hover:bg-white/10 hover:text-white'
            )}
          >
            <Shield className="w-3 h-3" /> Admin
          </button>
          <button
            onClick={() => { setAppMode('developer'); onNavigate('ai-lab'); }}
            className={cn(
              'flex items-center justify-center gap-1.5 py-2 rounded-lg text-[10px] font-semibold transition-all',
              !isAdmin ? 'bg-violet-600 text-white' : 'bg-white/5 text-white/50 hover:bg-white/10 hover:text-white'
            )}
          >
            <Code2 className="w-3 h-3" /> Dev
          </button>
        </div>
      </div>

      {/* Status */}
      <div className="px-3 pb-3">
        <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-white/5">
          <Activity className="w-3 h-3 text-white/30" />
          <div className="flex-1 min-w-0">
            <p className="text-[9px] text-white/30">Sim Tick</p>
            <p className="text-[10px] font-mono text-white/60">{state.tick} · {state.running ? '▶ Live' : '⏸ Paused'}</p>
          </div>
          <div className={cn('w-1.5 h-1.5 rounded-full', state.running ? 'bg-green-400 animate-pulse' : 'bg-white/20')} />
        </div>
      </div>
    </aside>
  );
}
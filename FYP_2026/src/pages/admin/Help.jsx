import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { HelpCircle, ChevronDown, ChevronRight, ShieldCheck, TrafficCone, AlertTriangle, Camera, DollarSign, BarChart2, Map, Settings } from 'lucide-react';

const SECTIONS = [
  {
    icon: ShieldCheck, label: 'Admin Dashboard', color: 'text-blue-500',
    desc: 'The main operations overview. Displays live KPIs — average wait time, total vehicles, queue length, and throughput. Start/Pause/Reset the simulation from here.',
  },
  {
    icon: TrafficCone, label: 'Live Traffic Control', color: 'text-orange-500',
    desc: 'Real-time intersection canvas showing animated vehicles and traffic lights. Use Manual Override to force specific signals, or activate Emergency Priority for a lane.',
  },
  {
    icon: AlertTriangle, label: 'Violations Center', color: 'text-red-500',
    desc: 'Automatically detects and logs traffic violations (red light runs, speeding, wrong-lane entries). Filter by type or status. New violations appear every 5 simulation ticks.',
  },
  {
    icon: Camera, label: 'Evidence Panel', color: 'text-purple-500',
    desc: 'Simulated CCTV feeds for each lane. Captures violation snapshots with plate recognition, confidence scores, and timestamps.',
  },
  {
    icon: DollarSign, label: 'Punishment System', color: 'text-green-500',
    desc: 'Automated fine issuance based on violation type. Track payment status (Pending/Paid/Disputed/Overdue). Approve or dispute individual fines.',
  },
  {
    icon: BarChart2, label: 'Analytics', color: 'text-blue-400',
    desc: 'Full performance analysis: wait time comparison, queue trends, throughput, lane pressure radar, and RL reward history.',
  },
  {
    icon: Map, label: 'Hotspot Map', color: 'text-orange-400',
    desc: 'Live heatmap of 8 simulated Kuala Lumpur intersections. Colors represent congestion intensity (green = low, red = critical).',
  },
  {
    icon: Settings, label: 'Settings', color: 'text-gray-500',
    desc: 'Configure simulation mode (RL vs Fixed), speed, alert thresholds, notifications, and system toggles.',
  },
];

const FAQ = [
  { q: 'What is RL Adaptive mode?', a: 'The RL agent dynamically calculates optimal green signal durations based on vehicle density, queue length, and wait time per lane.' },
  { q: 'What is Fixed-Time mode?', a: 'Traditional signal timing with a constant green/yellow duration for all phases. Used as a comparison baseline.' },
  { q: 'Are violations real?', a: 'No — all violation data is simulated based on the traffic state in the engine. This is an academic front-end demonstration.' },
  { q: 'How is the reward calculated?', a: 'Reward = (wait reduction × 0.5) + (throughput × 0.3) + (queue reduction × 0.2). Higher = better RL performance.' },
];

export default function AdminHelp() {
  const [openFaq, setOpenFaq] = useState(null);

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <HelpCircle className="w-5 h-5 text-blue-500" />
        <h1 className="text-xl font-bold">Help & Documentation</h1>
        <Badge variant="outline" className="text-[10px]">Admin Mode</Badge>
      </div>

      {/* Overview */}
      <Card className="border-blue-200 bg-blue-50/50 dark:bg-blue-950/20">
        <CardContent className="pt-4 pb-4 px-4">
          <h2 className="text-sm font-bold text-blue-700 mb-2">👮 Admin Mode Overview</h2>
          <p className="text-xs text-muted-foreground leading-relaxed">
            Synapse Flow Admin Mode is an Operational Traffic Control System designed for real-time monitoring, 
            violation tracking, and signal management. It simulates how a smart city traffic intelligence platform 
            would operate from an operational perspective.
          </p>
        </CardContent>
      </Card>

      {/* Section Guide */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
        {SECTIONS.map(section => {
          const Icon = section.icon;
          return (
            <Card key={section.label} className="hover:border-primary/30 transition-colors">
              <CardContent className="pt-4 pb-4 px-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-muted flex items-center justify-center flex-shrink-0">
                    <Icon className={`w-4 h-4 ${section.color}`} />
                  </div>
                  <div>
                    <h3 className="text-xs font-bold text-foreground mb-1">{section.label}</h3>
                    <p className="text-[10px] text-muted-foreground leading-relaxed">{section.desc}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* FAQ */}
      <div>
        <h2 className="text-sm font-bold text-foreground mb-3">Frequently Asked Questions</h2>
        <div className="space-y-2">
          {FAQ.map((faq, i) => (
            <Card key={i} className="cursor-pointer hover:border-primary/30 transition-colors" onClick={() => setOpenFaq(openFaq === i ? null : i)}>
              <CardContent className="py-3 px-4">
                <div className="flex items-center justify-between">
                  <p className="text-xs font-semibold">{faq.q}</p>
                  {openFaq === i ? <ChevronDown className="w-4 h-4 text-muted-foreground" /> : <ChevronRight className="w-4 h-4 text-muted-foreground" />}
                </div>
                {openFaq === i && <p className="text-[10px] text-muted-foreground mt-2 leading-relaxed">{faq.a}</p>}
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
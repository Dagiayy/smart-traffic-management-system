import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { HelpCircle, ChevronDown, ChevronRight, Brain, TrendingUp, RotateCcw, SlidersHorizontal, FlaskConical, ScrollText, GitCompare, Map } from 'lucide-react';

const SECTIONS = [
  {
    icon: Brain, label: 'AI Simulation Lab', color: 'text-violet-500',
    desc: 'Main RL workbench. Start/Pause/Reset the simulation. Switch between RL Adaptive and Fixed-Time modes. View the live intersection, lane state, and debug panel simultaneously.',
  },
  {
    icon: TrendingUp, label: 'Reward Analytics', color: 'text-emerald-500',
    desc: 'Visualizes per-tick reward, cumulative reward, and efficiency gain vs fixed-time baseline. The reward function: R = (wait_reduction × 0.5) + (throughput × 0.3) + (queue_reduction × 0.2).',
  },
  {
    icon: RotateCcw, label: 'Scenario Replay', color: 'text-blue-500',
    desc: 'Step through recorded simulation history tick by tick. Use the slider or playback controls to review how metrics evolved. Reference line marks current replay position.',
  },
  {
    icon: SlidersHorizontal, label: 'Parameter Control', color: 'text-violet-500',
    desc: 'Tune RL state weights (vehicles/queue/wait), reward weights, min/max green time, yellow duration, and fixed-time baseline settings. Changes take effect on the next tick.',
  },
  {
    icon: FlaskConical, label: 'Experiment Mode', color: 'text-pink-500',
    desc: 'Run parallel strategy comparisons (RL vs Fixed vs Priority-Weighted vs Round Robin). Each strategy runs its own independent simulation state for fair comparison.',
  },
  {
    icon: ScrollText, label: 'System Logs', color: 'text-slate-400',
    desc: 'Real-time decision log stream showing state, action, and reward for every tick. Filter by log level (INFO/DEBUG/WARN/ACTION/REWARD). Export as .txt.',
  },
  {
    icon: GitCompare, label: 'Performance Comparison', color: 'text-blue-500',
    desc: 'Side-by-side metrics: RL Adaptive vs Fixed-Time. Shows average wait improvement, % efficiency gain, and full chart comparison over recorded history.',
  },
  {
    icon: Map, label: 'Hotspot Map', color: 'text-orange-400',
    desc: 'Shared heatmap showing intersection congestion intensity derived from lane queue and wait time data from the live simulation.',
  },
];

const RL_CONCEPTS = [
  { term: 'State', def: 'Vehicle density, queue length, waiting time, and current signal phase per lane.' },
  { term: 'Action', def: 'Select which phase gets green, and for how long (dynamic green duration).' },
  { term: 'Reward', def: 'Positive reward for reducing wait time, increasing throughput, and clearing queues.' },
  { term: 'Policy', def: 'Maps lane pressure (weighted state) to green time duration decisions.' },
  { term: 'Episode', def: 'Continuous simulation ticks. No episode boundary — ongoing optimization.' },
  { term: 'Agent', def: 'The rlDecideGreenTime function in simulationEngine.js acts as the policy agent.' },
];

const FAQ = [
  { q: 'Is this real machine learning?', a: 'No. This is a frontend simulation of RL behavior using JavaScript logic. There is no neural network, training loop, or optimization algorithm.' },
  { q: 'How does RL beat Fixed-Time?', a: 'The RL agent adapts green duration based on current lane pressure. Fixed-Time always uses the same duration regardless of traffic conditions.' },
  { q: 'What are state weights?', a: 'They determine how much influence vehicles, queue, and wait time each have on the lane pressure calculation used to decide green time.' },
  { q: 'How is reward calculated?', a: 'R = (avgPrevWait - avgNextWait) × rewardWaitReduction + totalThroughput × rewardThroughput + (avgPrevQueue - avgNextQueue) × rewardQueueReduction' },
];

export default function DevHelp() {
  const [openFaq, setOpenFaq] = useState(null);

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <HelpCircle className="w-5 h-5 text-violet-500" />
        <h1 className="text-xl font-bold">Help & Documentation</h1>
        <Badge variant="outline" className="text-[10px] border-violet-400 text-violet-500">Developer Mode</Badge>
      </div>

      {/* Overview */}
      <Card className="border-violet-200 bg-violet-50/50 dark:bg-violet-950/20">
        <CardContent className="pt-4 pb-4 px-4">
          <h2 className="text-sm font-bold text-violet-700 mb-2">🧠 Developer Mode Overview</h2>
          <p className="text-xs text-muted-foreground leading-relaxed">
            Synapse Flow Developer Mode is an RL Simulation & Debug System for experimenting with reinforcement 
            learning–based traffic signal optimization. All RL logic is implemented purely in JavaScript — there 
            is no ML backend, training process, or neural network. The RL behavior is simulated via weighted 
            decision functions designed to demonstrate the core principles of adaptive traffic control.
          </p>
        </CardContent>
      </Card>

      {/* RL Concepts */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">RL Concepts in Synapse Flow</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-2">
            {RL_CONCEPTS.map(c => (
              <div key={c.term} className="flex gap-3 p-3 rounded-lg bg-muted/40 border border-border">
                <div className="w-20 flex-shrink-0">
                  <p className="text-[10px] font-bold text-violet-500 uppercase">{c.term}</p>
                </div>
                <p className="text-[10px] text-muted-foreground leading-relaxed">{c.def}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Module Guide */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
        {SECTIONS.map(section => {
          const Icon = section.icon;
          return (
            <Card key={section.label} className="hover:border-violet-300/40 transition-colors">
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
        <h2 className="text-sm font-bold text-foreground mb-3">Technical FAQ</h2>
        <div className="space-y-2">
          {FAQ.map((faq, i) => (
            <Card key={i} className="cursor-pointer hover:border-violet-300/40 transition-colors" onClick={() => setOpenFaq(openFaq === i ? null : i)}>
              <CardContent className="py-3 px-4">
                <div className="flex items-center justify-between">
                  <p className="text-xs font-semibold">{faq.q}</p>
                  {openFaq === i ? <ChevronDown className="w-4 h-4 text-muted-foreground" /> : <ChevronRight className="w-4 h-4 text-muted-foreground" />}
                </div>
                {openFaq === i && <p className="text-[10px] text-muted-foreground mt-2 leading-relaxed font-mono">{faq.a}</p>}
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
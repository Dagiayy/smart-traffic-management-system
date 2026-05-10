import React, { useState, useEffect } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { Slider } from '@/components/ui/slider';
import { Settings as SettingsIcon, Zap, Clock, Save, RotateCcw, RefreshCw } from 'lucide-react';
import { settingsApi } from '@/api/admin';
import toast from 'react-hot-toast';

export default function Settings() {
  const { state, dispatch } = useSimulation();
  const [simSpeed, setSimSpeed] = useState(1);
  const [notifications, setNotifications] = useState(true);
  const [autoEmergency, setAutoEmergency] = useState(false);
  const [maxQueue, setMaxQueue] = useState(12);

  const { data: sysSettings, isLoading: loadingSettings } = useQuery({
    queryKey: ['admin-settings'],
    queryFn: () => settingsApi.get().then(r => r.data),
    staleTime: Infinity,
  });

  const updateMutation = useMutation({
    mutationFn: (data) => settingsApi.update(data),
    onSuccess: () => toast.success('Settings saved'),
    onError: () => toast.error('Failed to save settings'),
  });

  const handleSave = () => {
    updateMutation.mutate({
      notifications_enabled: notifications,
      auto_emergency: autoEmergency,
      max_queue_threshold: maxQueue,
    });
  };

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <SettingsIcon className="w-5 h-5 text-gray-500" />
          <h1 className="text-xl font-bold">System Settings</h1>
        </div>
        <Button size="sm" className="h-8 text-xs" onClick={handleSave} disabled={updateMutation.isPending}>
          {updateMutation.isPending
            ? <><RefreshCw className="w-3 h-3 mr-1 animate-spin" /> Saving…</>
            : <><Save className="w-3 h-3 mr-1" /> Save Settings</>}
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Simulation */}
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">Simulation Configuration</CardTitle>
          </CardHeader>
          <CardContent className="px-4 pb-4 space-y-5">
            <div className="space-y-2">
              <Label className="text-xs font-medium">Signal Control Mode</Label>
              <div className="grid grid-cols-2 gap-2">
                <Button size="sm" variant={state.mode === 'rl' ? 'default' : 'outline'} className="h-8 text-xs"
                  onClick={() => dispatch({ type: 'SET_MODE', payload: 'rl' })}>
                  <Zap className="w-3 h-3 mr-1" /> RL Adaptive
                </Button>
                <Button size="sm" variant={state.mode === 'fixed' ? 'default' : 'outline'} className="h-8 text-xs"
                  onClick={() => dispatch({ type: 'SET_MODE', payload: 'fixed' })}>
                  <Clock className="w-3 h-3 mr-1" /> Fixed-Time
                </Button>
              </div>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between">
                <Label className="text-xs font-medium">Simulation Speed</Label>
                <span className="text-xs font-mono bg-muted px-2 py-0.5 rounded">{simSpeed}x</span>
              </div>
              <Slider min={0.5} max={5} step={0.5} value={[simSpeed]} onValueChange={([v]) => setSimSpeed(v)} />
            </div>
            <div className="space-y-2">
              <div className="flex justify-between">
                <Label className="text-xs font-medium">Max Queue Alert Threshold</Label>
                <span className="text-xs font-mono bg-muted px-2 py-0.5 rounded">{maxQueue} vehicles</span>
              </div>
              <Slider min={5} max={20} step={1} value={[maxQueue]} onValueChange={([v]) => setMaxQueue(v)} />
            </div>
          </CardContent>
        </Card>

        {/* Toggles */}
        <Card>
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">System Toggles</CardTitle>
          </CardHeader>
          <CardContent className="px-4 pb-4 space-y-4">
            {[
              { label: 'Congestion Notifications', desc: 'Alert when queue exceeds threshold', value: notifications, set: setNotifications },
              { label: 'Auto Emergency Override', desc: 'Auto-clear emergency after 30 ticks', value: autoEmergency, set: setAutoEmergency },
            ].map(item => (
              <div key={item.label} className="flex items-start justify-between gap-4 p-3 rounded-lg bg-muted/30 border border-border">
                <div>
                  <p className="text-xs font-medium">{item.label}</p>
                  <p className="text-[10px] text-muted-foreground mt-0.5">{item.desc}</p>
                </div>
                <Switch checked={item.value} onCheckedChange={item.set} />
              </div>
            ))}
          </CardContent>
        </Card>

        {/* System info from backend */}
        <Card className="lg:col-span-2">
          <CardHeader className="pb-2 pt-4 px-4">
            <CardTitle className="text-sm font-semibold">System Information (Backend)</CardTitle>
          </CardHeader>
          <CardContent className="px-4 pb-4">
            {loadingSettings ? (
              <p className="text-xs text-muted-foreground">Loading…</p>
            ) : (
              <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
                {Object.entries(sysSettings ?? {}).slice(0, 8).map(([key, val]) => (
                  <div key={key} className="flex flex-col py-2 border-b border-border/50">
                    <span className="text-[9px] text-muted-foreground uppercase">{key.replace(/_/g, ' ')}</span>
                    <span className="text-xs font-mono font-semibold mt-0.5">{String(val)}</span>
                  </div>
                ))}
                {[
                  { label: 'Simulation Engine', value: 'RL-JS v2.1' },
                  { label: 'Current Tick', value: state.tick },
                  { label: 'Active Mode', value: state.mode === 'rl' ? 'Adaptive RL' : 'Fixed-Time' },
                  { label: 'Total Reward', value: state.metrics.totalReward.toFixed(2) },
                ].map(item => (
                  <div key={item.label} className="flex flex-col py-2 border-b border-border/50">
                    <span className="text-[9px] text-muted-foreground uppercase">{item.label}</span>
                    <span className="text-xs font-mono font-semibold mt-0.5">{item.value}</span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

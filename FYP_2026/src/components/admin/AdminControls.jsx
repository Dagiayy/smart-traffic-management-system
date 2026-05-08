import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { useSimulation } from '@/lib/SimulationContext';
import { LANES } from '@/lib/simulationEngine';
import { Play, Pause, RotateCcw, Zap, Clock, AlertCircle } from 'lucide-react';

export default function AdminControls() {
  const { state, dispatch, startSimulation, pauseSimulation, resetSimulation } = useSimulation();

  const setMode = (mode) => dispatch({ type: 'SET_MODE', payload: mode });
  const setEmergency = (lane) => dispatch({ type: 'SET_EMERGENCY', payload: lane === state.emergency ? null : lane });
  const overrideSignal = (lane, color) => dispatch({ type: 'MANUAL_SIGNAL', payload: { lane, color } });

  return (
    <div className="space-y-3">
      {/* Simulation Controls */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Simulation Controls</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4 space-y-3">
          <div className="flex gap-2">
            <Button
              size="sm"
              className="flex-1 h-8 text-xs"
              onClick={startSimulation}
              disabled={state.running}
            >
              <Play className="w-3 h-3 mr-1" /> Start
            </Button>
            <Button
              size="sm"
              variant="outline"
              className="flex-1 h-8 text-xs"
              onClick={pauseSimulation}
              disabled={!state.running}
            >
              <Pause className="w-3 h-3 mr-1" /> Pause
            </Button>
            <Button
              size="sm"
              variant="outline"
              className="h-8 px-2"
              onClick={resetSimulation}
            >
              <RotateCcw className="w-3 h-3" />
            </Button>
          </div>

          <Separator />

          {/* AI Mode Toggle */}
          <div>
            <p className="text-[10px] text-muted-foreground mb-2 font-medium uppercase tracking-wide">Signal Control Mode</p>
            <div className="grid grid-cols-2 gap-2">
              <Button
                size="sm"
                variant={state.mode === 'rl' ? 'default' : 'outline'}
                className="h-8 text-xs"
                onClick={() => setMode('rl')}
              >
                <Zap className="w-3 h-3 mr-1" /> AI / RL
              </Button>
              <Button
                size="sm"
                variant={state.mode === 'fixed' ? 'default' : 'outline'}
                className="h-8 text-xs"
                onClick={() => setMode('fixed')}
              >
                <Clock className="w-3 h-3 mr-1" /> Fixed
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Emergency Mode */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <div className="flex items-center justify-between">
            <CardTitle className="text-sm font-semibold">Emergency Priority</CardTitle>
            {state.emergency && (
              <Badge variant="destructive" className="text-[10px] animate-pulse">ACTIVE</Badge>
            )}
          </div>
        </CardHeader>
        <CardContent className="px-4 pb-4">
          <p className="text-[10px] text-muted-foreground mb-2">Select lane to grant emergency vehicle priority</p>
          <div className="grid grid-cols-2 gap-2">
            {LANES.map(lane => (
              <Button
                key={lane}
                size="sm"
                variant={state.emergency === lane ? 'destructive' : 'outline'}
                className="h-7 text-xs"
                onClick={() => setEmergency(lane)}
              >
                <AlertCircle className="w-3 h-3 mr-1" /> {lane}
              </Button>
            ))}
          </div>
          {state.emergency && (
            <Button
              size="sm"
              variant="ghost"
              className="w-full h-7 text-xs mt-2 text-muted-foreground"
              onClick={() => dispatch({ type: 'SET_EMERGENCY', payload: null })}
            >
              Clear Emergency
            </Button>
          )}
        </CardContent>
      </Card>

      {/* Manual Signal Override */}
      <Card>
        <CardHeader className="pb-2 pt-4 px-4">
          <CardTitle className="text-sm font-semibold">Manual Override</CardTitle>
        </CardHeader>
        <CardContent className="px-4 pb-4 space-y-2">
          <p className="text-[10px] text-muted-foreground">Force signal color per lane (admin override)</p>
          {LANES.map(lane => (
            <div key={lane} className="flex items-center gap-1">
              <span className="text-[10px] w-10 font-medium text-muted-foreground">{lane}</span>
              {['green', 'yellow', 'red'].map(color => (
                <Button
                  key={color}
                  size="sm"
                  variant={state.signals[lane] === color ? 'default' : 'outline'}
                  className="h-6 px-2 text-[9px] flex-1"
                  onClick={() => overrideSignal(lane, color)}
                  style={state.signals[lane] === color ? {
                    backgroundColor: color === 'green' ? '#22c55e' : color === 'yellow' ? '#f59e0b' : '#ef4444',
                    borderColor: 'transparent',
                    color: '#fff'
                  } : {}}
                >
                  {color.charAt(0).toUpperCase() + color.slice(1)}
                </Button>
              ))}
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
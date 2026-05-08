import React, { useState, useEffect, useRef } from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Camera, RefreshCw, Eye, Clock, MapPin } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';

const VIOLATION_TYPES = ['Red Light Run', 'Speed Violation', 'Wrong Lane', 'Blocked Intersection'];

function CameraFeed({ lane, state }) {
  const canvasRef = useRef(null);
  const animRef = useRef(null);
  const frameRef = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    function draw() {
      frameRef.current++;
      const W = canvas.width, H = canvas.height;
      ctx.clearRect(0, 0, W, H);

      // Road background
      ctx.fillStyle = '#1e293b';
      ctx.fillRect(0, 0, W, H);
      ctx.fillStyle = '#334155';
      ctx.fillRect(W / 2 - 40, 0, 80, H);
      ctx.fillRect(0, H / 2 - 25, W, 50);
      ctx.fillStyle = '#0f172a';
      ctx.fillRect(W / 2 - 40, H / 2 - 25, 80, 50);

      // Lane dashes
      ctx.strokeStyle = '#f1f5f9';
      ctx.lineWidth = 1.5;
      ctx.setLineDash([8, 6]);
      ctx.globalAlpha = 0.3;
      ctx.beginPath(); ctx.moveTo(W / 2, 0); ctx.lineTo(W / 2, H / 2 - 25); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(W / 2, H / 2 + 25); ctx.lineTo(W / 2, H); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(0, H / 2); ctx.lineTo(W / 2 - 40, H / 2); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(W / 2 + 40, H / 2); ctx.lineTo(W, H / 2); ctx.stroke();
      ctx.setLineDash([]);
      ctx.globalAlpha = 1;

      // Animated vehicle
      const sig = state.signals[lane];
      const t = (frameRef.current * 1.5) % 200;
      const carX = lane === 'East' ? t : lane === 'West' ? 200 - t : W / 2 - 8;
      const carY = lane === 'North' ? t : lane === 'South' ? 200 - t : H / 2 - 6;
      const moving = sig === 'green' || t < 60;

      if (moving) {
        ctx.fillStyle = '#3b82f6';
        ctx.beginPath();
        ctx.roundRect(carX - 8, carY - 5, 16, 10, 2);
        ctx.fill();
        ctx.fillStyle = 'rgba(255,255,255,0.4)';
        ctx.fillRect(carX - 3, carY - 3, 6, 6);
      }

      // Traffic light indicator
      const lightColor = sig === 'green' ? '#22c55e' : sig === 'yellow' ? '#f59e0b' : '#ef4444';
      ctx.fillStyle = '#1e293b';
      ctx.fillRect(W - 22, 4, 14, 32);
      ['#374151', '#374151', '#374151'].forEach((_, i) => {
        ctx.beginPath();
        ctx.arc(W - 15, 12 + i * 10, 4, 0, Math.PI * 2);
        ctx.fillStyle = i === (sig === 'red' ? 0 : sig === 'yellow' ? 1 : 2) ? lightColor : '#374151';
        ctx.fill();
      });

      // Timestamp overlay
      ctx.fillStyle = 'rgba(0,0,0,0.5)';
      ctx.fillRect(0, H - 16, W, 16);
      ctx.fillStyle = '#94a3b8';
      ctx.font = '8px monospace';
      ctx.fillText(`CAM-${lane.toUpperCase()} ${new Date().toLocaleTimeString()}`, 4, H - 4);

      animRef.current = requestAnimationFrame(draw);
    }
    draw();
    return () => cancelAnimationFrame(animRef.current);
  }, [lane, state.signals]);

  return (
    <canvas ref={canvasRef} width={200} height={150} className="w-full rounded-lg border border-border" style={{ imageRendering: 'crisp-edges' }} />
  );
}

export default function EvidencePanel() {
  const { state } = useSimulation();
  const [snapshots, setSnapshots] = useState([]);
  const [selectedSnap, setSelectedSnap] = useState(null);

  useEffect(() => {
    if (state.running && state.tick % 8 === 0 && state.tick > 0) {
      const lane = LANES[Math.floor(Math.random() * LANES.length)];
      const type = VIOLATION_TYPES[Math.floor(Math.random() * VIOLATION_TYPES.length)];
      setSnapshots(s => [{
        id: state.tick,
        lane,
        type,
        time: new Date().toLocaleTimeString(),
        tick: state.tick,
        plate: `${String.fromCharCode(65 + Math.floor(Math.random() * 26))}${String.fromCharCode(65 + Math.floor(Math.random() * 26))}-${Math.floor(1000 + Math.random() * 9000)}`,
        confidence: Math.floor(85 + Math.random() * 15),
      }, ...s].slice(0, 20));
    }
  }, [state.tick]);

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <Camera className="w-5 h-5 text-purple-500" />
        <h1 className="text-xl font-bold">Evidence Panel</h1>
        <Badge className="text-[10px] bg-purple-600">CCTV Live</Badge>
      </div>

      {/* Live Camera Feeds */}
      <div>
        <h2 className="text-sm font-semibold text-muted-foreground mb-3 uppercase tracking-wide">Live Camera Feeds</h2>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {LANES.map(lane => (
            <Card key={lane}>
              <CardHeader className="pb-1 pt-3 px-3">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-xs font-semibold">{lane} Cam</CardTitle>
                  <div className="flex items-center gap-1">
                    <div className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse" />
                    <span className="text-[9px] text-red-500 font-mono">REC</span>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="px-3 pb-3">
                <CameraFeed lane={lane} state={state} />
                <div className="mt-2 flex items-center justify-between">
                  <span className={`text-[9px] font-mono font-bold ${state.signals[lane] === 'green' ? 'text-green-600' : state.signals[lane] === 'yellow' ? 'text-yellow-600' : 'text-red-600'}`}>
                    {state.signals[lane].toUpperCase()}
                  </span>
                  <span className="text-[9px] text-muted-foreground font-mono">Q:{state.lanes[lane].queue}</span>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Snapshots */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Violation Snapshots</h2>
          <span className="text-xs text-muted-foreground">{snapshots.length} captured</span>
        </div>
        {snapshots.length === 0 ? (
          <Card><CardContent className="py-8 text-center text-muted-foreground text-sm">Start simulation to capture violations…</CardContent></Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {snapshots.map(snap => (
              <Card key={snap.id} className="cursor-pointer hover:border-primary/50 transition-colors" onClick={() => setSelectedSnap(snap)}>
                <CardContent className="p-3 space-y-2">
                  <div className="flex items-center justify-between">
                    <Badge variant="destructive" className="text-[9px]">{snap.type}</Badge>
                    <span className="text-[9px] text-muted-foreground font-mono">{snap.confidence}% conf.</span>
                  </div>
                  <div className="rounded bg-slate-900 h-16 flex items-center justify-center relative overflow-hidden">
                    <div className="text-[10px] font-mono text-slate-400">📸 SNAPSHOT · Tick {snap.tick}</div>
                    <div className="absolute bottom-1 right-1 text-[8px] font-mono text-slate-500">{snap.time}</div>
                  </div>
                  <div className="flex items-center justify-between text-[10px] text-muted-foreground">
                    <span className="flex items-center gap-1"><MapPin className="w-3 h-3" />{snap.lane}</span>
                    <span className="font-mono font-bold text-foreground">{snap.plate}</span>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
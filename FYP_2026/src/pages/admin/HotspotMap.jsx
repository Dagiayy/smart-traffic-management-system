import React, { useEffect, useRef, useState } from 'react';
import { useSimulation } from '@/lib/SimulationContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Map, Flame } from 'lucide-react';
import { LANES } from '@/lib/simulationEngine';

const INTERSECTIONS = [
  { id: 1, name: 'Jalan Ampang / Jalan P.Ramlee', x: 0.35, y: 0.3 },
  { id: 2, name: 'Jalan Bukit Bintang / Jalan Imbi', x: 0.55, y: 0.45 },
  { id: 3, name: 'Jalan Sultan Ismail / Jalan Raja Chulan', x: 0.42, y: 0.52 },
  { id: 4, name: 'Jalan Semarak / Jalan Pahang', x: 0.65, y: 0.28 },
  { id: 5, name: 'MRR2 / Jalan Gombak', x: 0.72, y: 0.38 },
  { id: 6, name: 'Jalan Cheras / Jalan Chan Sow Lin', x: 0.58, y: 0.62 },
  { id: 7, name: 'Jalan Duta / Jalan Ipoh', x: 0.28, y: 0.42 },
  { id: 8, name: 'Federal Highway / Jalan Kinabalu', x: 0.38, y: 0.65 },
];

export default function HotspotMap() {
  const { state } = useSimulation();
  const canvasRef = useRef(null);
  const animRef = useRef(null);
  const [selectedIntersection, setSelectedIntersection] = useState(null);

  const getHeat = (id) => {
    const laneIdx = id % 4;
    const lane = LANES[laneIdx];
    return Math.min(1, (state.lanes[lane].queue / 20 + state.lanes[lane].waitTime / 60) / 2);
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    function draw() {
      const W = canvas.width, H = canvas.height;
      ctx.clearRect(0, 0, W, H);

      // Map background
      const grad = ctx.createLinearGradient(0, 0, W, H);
      grad.addColorStop(0, '#0f172a');
      grad.addColorStop(1, '#1e293b');
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, W, H);

      // Grid lines
      ctx.strokeStyle = 'rgba(148,163,184,0.07)';
      ctx.lineWidth = 1;
      for (let i = 0; i < W; i += 40) { ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, H); ctx.stroke(); }
      for (let j = 0; j < H; j += 40) { ctx.beginPath(); ctx.moveTo(0, j); ctx.lineTo(W, j); ctx.stroke(); }

      // Roads
      ctx.strokeStyle = 'rgba(148,163,184,0.12)';
      ctx.lineWidth = 3;
      [[0.35 * W, 0, 0.35 * W, H], [0.55 * W, 0, 0.55 * W, H], [0.72 * W, 0, 0.72 * W, H],
       [0, 0.3 * H, W, 0.3 * H], [0, 0.45 * H, W, 0.45 * H], [0, 0.62 * H, W, 0.62 * H]
      ].forEach(([x1, y1, x2, y2]) => {
        ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
      });

      // Heat blobs
      INTERSECTIONS.forEach(intersection => {
        const heat = getHeat(intersection.id);
        const px = intersection.x * W;
        const py = intersection.y * H;
        const r = 35 + heat * 30;

        const heatGrad = ctx.createRadialGradient(px, py, 0, px, py, r);
        const color = heat > 0.7 ? [239, 68, 68] : heat > 0.4 ? [245, 158, 11] : [34, 197, 94];
        heatGrad.addColorStop(0, `rgba(${color[0]},${color[1]},${color[2]},${0.5 + heat * 0.4})`);
        heatGrad.addColorStop(0.5, `rgba(${color[0]},${color[1]},${color[2]},${0.15 + heat * 0.2})`);
        heatGrad.addColorStop(1, 'rgba(0,0,0,0)');
        ctx.fillStyle = heatGrad;
        ctx.beginPath();
        ctx.arc(px, py, r, 0, Math.PI * 2);
        ctx.fill();

        // Node
        ctx.fillStyle = `rgb(${color[0]},${color[1]},${color[2]})`;
        ctx.shadowBlur = 12;
        ctx.shadowColor = `rgb(${color[0]},${color[1]},${color[2]})`;
        ctx.beginPath();
        ctx.arc(px, py, 6, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowBlur = 0;

        // Label
        ctx.fillStyle = 'rgba(255,255,255,0.7)';
        ctx.font = 'bold 9px Inter';
        ctx.textAlign = 'center';
        ctx.fillText(`I-${intersection.id}`, px, py - 12);
      });

      // Legend
      const legendItems = [['#22c55e', 'Low'], ['#f59e0b', 'Medium'], ['#ef4444', 'High']];
      legendItems.forEach(([color, label], i) => {
        ctx.fillStyle = color;
        ctx.fillRect(10, H - 70 + i * 20, 10, 10);
        ctx.fillStyle = 'rgba(255,255,255,0.6)';
        ctx.font = '9px Inter';
        ctx.textAlign = 'left';
        ctx.fillText(label, 25, H - 62 + i * 20);
      });

      animRef.current = requestAnimationFrame(draw);
    }
    draw();
    return () => cancelAnimationFrame(animRef.current);
  }, [state.lanes]);

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center gap-2">
        <Map className="w-5 h-5 text-orange-500" />
        <h1 className="text-xl font-bold">Hotspot Map</h1>
        <Badge className="text-[10px] bg-orange-600 animate-pulse">Live Heatmap</Badge>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2">
          <Card>
            <CardHeader className="pb-2 pt-4 px-4">
              <CardTitle className="text-sm font-semibold">Kuala Lumpur — Violation Congestion Heatmap</CardTitle>
            </CardHeader>
            <CardContent className="px-4 pb-4">
              <canvas ref={canvasRef} width={600} height={380} className="w-full rounded-lg" style={{ imageRendering: 'crisp-edges' }} />
            </CardContent>
          </Card>
        </div>

        <div className="space-y-3">
          <Card>
            <CardHeader className="pb-2 pt-4 px-4">
              <CardTitle className="text-sm font-semibold flex items-center gap-2"><Flame className="w-4 h-4 text-orange-500" /> Intersections</CardTitle>
            </CardHeader>
            <CardContent className="px-4 pb-4 space-y-2">
              {INTERSECTIONS.map(inter => {
                const heat = getHeat(inter.id);
                const level = heat > 0.7 ? 'High' : heat > 0.4 ? 'Medium' : 'Low';
                const color = heat > 0.7 ? 'text-red-600' : heat > 0.4 ? 'text-yellow-600' : 'text-green-600';
                const bg = heat > 0.7 ? 'bg-red-500/10 border-red-500/20' : heat > 0.4 ? 'bg-yellow-500/10 border-yellow-500/20' : 'bg-green-500/10 border-green-500/20';
                return (
                  <div key={inter.id} className={`flex items-center justify-between p-2 rounded-lg border ${bg}`}>
                    <div>
                      <p className="text-[10px] font-semibold text-foreground">I-{inter.id}</p>
                      <p className="text-[9px] text-muted-foreground truncate max-w-[140px]">{inter.name}</p>
                    </div>
                    <span className={`text-[10px] font-bold ${color}`}>{level}</span>
                  </div>
                );
              })}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
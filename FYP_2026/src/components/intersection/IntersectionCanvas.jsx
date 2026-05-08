import React, { useEffect, useRef } from 'react';
import { useSimulation } from '@/lib/SimulationContext';

const SIGNAL_COLORS = { red: '#ef4444', yellow: '#f59e0b', green: '#22c55e', off: '#374151' };
const ROAD_COLOR = '#1e293b';
const ASPHALT = '#334155';
const LANE_MARK = '#f1f5f9';
const GRASS = '#dcfce7';

export default function IntersectionCanvas() {
  const canvasRef = useRef(null);
  const { state } = useSimulation();
  const vehiclesRef = useRef([]);
  const animFrameRef = useRef(null);

  // Initialize vehicles
  useEffect(() => {
    vehiclesRef.current = generateVehicles(state.lanes, state.signals);
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    function draw() {
      const W = canvas.width;
      const H = canvas.height;
      const cx = W / 2;
      const cy = H / 2;
      const roadW = 90;
      const laneW = roadW / 2;

      ctx.clearRect(0, 0, W, H);

      // Background (grass)
      ctx.fillStyle = GRASS;
      ctx.fillRect(0, 0, W, H);

      // Roads
      ctx.fillStyle = ASPHALT;
      ctx.fillRect(cx - roadW / 2, 0, roadW, H); // vertical
      ctx.fillRect(0, cy - roadW / 2, W, roadW); // horizontal

      // Lane markings - vertical
      drawDashedLine(ctx, cx, 0, cx, cy - roadW / 2, LANE_MARK);
      drawDashedLine(ctx, cx, cy + roadW / 2, cx, H, LANE_MARK);
      // Lane markings - horizontal
      drawDashedLine(ctx, 0, cy, cx - roadW / 2, cy, LANE_MARK);
      drawDashedLine(ctx, cx + roadW / 2, cy, W, cy, LANE_MARK);

      // Intersection box (darker)
      ctx.fillStyle = ROAD_COLOR;
      ctx.fillRect(cx - roadW / 2, cy - roadW / 2, roadW, roadW);

      // Crosswalk stripes
      drawCrosswalk(ctx, cx - roadW / 2 - 18, cy - roadW / 2, 18, roadW); // West side
      drawCrosswalk(ctx, cx + roadW / 2, cy - roadW / 2, 18, roadW);       // East side
      drawCrosswalkH(ctx, cx - roadW / 2, cy - roadW / 2 - 18, roadW, 18); // North
      drawCrosswalkH(ctx, cx - roadW / 2, cy + roadW / 2, roadW, 18);      // South

      // Traffic lights
      drawTrafficLight(ctx, cx - roadW / 2 - 22, cy - roadW / 2 - 22, state.signals['North'], 'N');
      drawTrafficLight(ctx, cx + roadW / 2 + 6, cy + roadW / 2 + 6, state.signals['South'], 'S');
      drawTrafficLight(ctx, cx + roadW / 2 + 6, cy - roadW / 2 - 22, state.signals['East'], 'E');
      drawTrafficLight(ctx, cx - roadW / 2 - 22, cy + roadW / 2 + 6, state.signals['West'], 'W');

      // Update & draw vehicles
      updateVehicles(vehiclesRef.current, state.lanes, state.signals, cx, cy, roadW);
      vehiclesRef.current.forEach(v => drawVehicle(ctx, v));

      // Queue bars (sides)
      drawQueueBar(ctx, cx - roadW / 2 - 70, cy - 30, state.lanes['North'].queue, 'North');
      drawQueueBar(ctx, cx + roadW / 2 + 52, cy - 30, state.lanes['South'].queue, 'South');
      drawQueueBar(ctx, cx - 30, cy - roadW / 2 - 70, state.lanes['East'].queue, 'East');
      drawQueueBar(ctx, cx - 30, cy + roadW / 2 + 52, state.lanes['West'].queue, 'West');

      animFrameRef.current = requestAnimationFrame(draw);
    }

    draw();
    return () => cancelAnimationFrame(animFrameRef.current);
  }, [state.signals, state.lanes]);

  return (
    <canvas
      ref={canvasRef}
      width={420}
      height={420}
      className="w-full max-w-[420px] rounded-xl border border-border shadow-md"
      style={{ imageRendering: 'crisp-edges' }}
    />
  );
}

function drawDashedLine(ctx, x1, y1, x2, y2, color) {
  ctx.save();
  ctx.strokeStyle = color;
  ctx.lineWidth = 2;
  ctx.setLineDash([12, 10]);
  ctx.globalAlpha = 0.5;
  ctx.beginPath();
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
  ctx.stroke();
  ctx.restore();
}

function drawCrosswalk(ctx, x, y, w, h) {
  ctx.save();
  ctx.fillStyle = '#f8fafc';
  ctx.globalAlpha = 0.3;
  for (let i = 0; i < h; i += 8) {
    ctx.fillRect(x, y + i, w, 4);
  }
  ctx.restore();
}

function drawCrosswalkH(ctx, x, y, w, h) {
  ctx.save();
  ctx.fillStyle = '#f8fafc';
  ctx.globalAlpha = 0.3;
  for (let i = 0; i < w; i += 8) {
    ctx.fillRect(x + i, y, 4, h);
  }
  ctx.restore();
}

function drawTrafficLight(ctx, x, y, signal, label) {
  const W = 16; const H = 40;
  ctx.save();

  // Housing
  ctx.fillStyle = '#1e293b';
  ctx.strokeStyle = '#334155';
  ctx.lineWidth = 1;
  roundRect(ctx, x, y, W, H, 4);
  ctx.fill();
  ctx.stroke();

  // Lights
  const lights = ['red', 'yellow', 'green'];
  lights.forEach((color, i) => {
    const active = signal === color;
    ctx.beginPath();
    ctx.arc(x + W / 2, y + 7 + i * 11, 4, 0, Math.PI * 2);
    ctx.fillStyle = active ? SIGNAL_COLORS[color] : '#374151';
    if (active) {
      ctx.shadowBlur = 10;
      ctx.shadowColor = SIGNAL_COLORS[color];
    } else {
      ctx.shadowBlur = 0;
    }
    ctx.fill();
    ctx.shadowBlur = 0;
  });

  // Label
  ctx.fillStyle = '#94a3b8';
  ctx.font = 'bold 8px Inter';
  ctx.textAlign = 'center';
  ctx.fillText(label, x + W / 2, y + H + 10);

  ctx.restore();
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.arcTo(x + w, y, x + w, y + r, r);
  ctx.lineTo(x + w, y + h - r);
  ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
  ctx.lineTo(x + r, y + h);
  ctx.arcTo(x, y + h, x, y + h - r, r);
  ctx.lineTo(x, y + r);
  ctx.arcTo(x, y, x + r, y, r);
  ctx.closePath();
}

function drawQueueBar(ctx, x, y, queue, direction) {
  const maxQ = 20;
  const ratio = Math.min(queue / maxQ, 1);
  const color = ratio > 0.7 ? '#ef4444' : ratio > 0.4 ? '#f59e0b' : '#22c55e';
  const isHoriz = direction === 'East' || direction === 'West';

  ctx.save();
  ctx.font = '9px Inter';
  ctx.fillStyle = '#64748b';
  ctx.textAlign = 'center';

  if (!isHoriz) {
    ctx.fillText(direction, x + 8, y - 4);
    ctx.fillStyle = '#e2e8f0';
    ctx.fillRect(x, y, 16, 60);
    ctx.fillStyle = color;
    ctx.fillRect(x, y + 60 * (1 - ratio), 16, 60 * ratio);
    ctx.strokeStyle = '#94a3b8';
    ctx.lineWidth = 0.5;
    ctx.strokeRect(x, y, 16, 60);
    ctx.fillStyle = '#334155';
    ctx.fillText(queue, x + 8, y + 60 + 12);
  } else {
    ctx.fillText(direction, x + 30, y - 4);
    ctx.fillStyle = '#e2e8f0';
    ctx.fillRect(x, y, 60, 16);
    ctx.fillStyle = color;
    ctx.fillRect(x, y, 60 * ratio, 16);
    ctx.strokeStyle = '#94a3b8';
    ctx.lineWidth = 0.5;
    ctx.strokeRect(x, y, 60, 16);
    ctx.fillStyle = '#334155';
    ctx.fillText(queue, x + 70, y + 12);
  }

  ctx.restore();
}

function generateVehicles(lanes, signals) {
  const vehicles = [];
  const cx = 210; const cy = 210; const roadW = 90;

  const configs = [
    { lane: 'North', dir: 'south', startX: cx - 22, startY: 20 },
    { lane: 'South', dir: 'north', startX: cx + 22, startY: 400 },
    { lane: 'East', dir: 'west', startX: 400, startY: cy - 22 },
    { lane: 'West', dir: 'east', startX: 20, startY: cy + 22 },
  ];

  configs.forEach(cfg => {
    const count = Math.floor(Math.random() * 3) + 1;
    for (let i = 0; i < count; i++) {
      vehicles.push({
        id: Math.random(),
        lane: cfg.lane,
        dir: cfg.dir,
        x: cfg.dir === 'south' ? cfg.startX : cfg.dir === 'north' ? cfg.startX : cfg.startX - i * 30,
        y: cfg.dir === 'south' ? cfg.startY + i * 30 : cfg.dir === 'north' ? cfg.startY - i * 30 : cfg.startY,
        color: randomCarColor(),
        speed: 1.5 + Math.random(),
        stopped: false,
      });
    }
  });
  return vehicles;
}

const CAR_COLORS = ['#3b82f6', '#f97316', '#8b5cf6', '#ec4899', '#14b8a6', '#f43f5e', '#84cc16'];
function randomCarColor() { return CAR_COLORS[Math.floor(Math.random() * CAR_COLORS.length)]; }

function updateVehicles(vehicles, lanes, signals, cx, cy, roadW) {
  const stopLines = {
    north: cy - roadW / 2 - 10,
    south: cy + roadW / 2 + 10,
    east: cx + roadW / 2 + 10,
    west: cx - roadW / 2 - 10,
  };

  vehicles.forEach(v => {
    const sig = signals[v.lane];
    const canGo = sig === 'green';

    if (v.dir === 'south') {
      if (!canGo && v.y < stopLines.north - 5) { v.stopped = false; }
      else if (!canGo && v.y >= stopLines.north - 30 && v.y <= stopLines.north) { v.stopped = true; }
      if (!v.stopped) v.y += v.speed;
      if (v.y > cy + roadW / 2 + 50) v.y = -20;
    } else if (v.dir === 'north') {
      if (!canGo && v.y > stopLines.south + 5) { v.stopped = false; }
      else if (!canGo && v.y <= stopLines.south + 30 && v.y >= stopLines.south) { v.stopped = true; }
      if (!v.stopped) v.y -= v.speed;
      if (v.y < cy - roadW / 2 - 50) v.y = cy + roadW / 2 + 20 + Math.random() * 50;
    } else if (v.dir === 'west') {
      if (!canGo && v.x > stopLines.east - 5) { v.stopped = false; }
      else if (!canGo && v.x <= stopLines.east + 30 && v.x >= stopLines.east) { v.stopped = true; }
      if (!v.stopped) v.x -= v.speed;
      if (v.x < cx - roadW / 2 - 50) v.x = cx + roadW / 2 + 20 + Math.random() * 50;
    } else if (v.dir === 'east') {
      if (!canGo && v.x < stopLines.west + 5) { v.stopped = false; }
      else if (!canGo && v.x >= stopLines.west - 30 && v.x <= stopLines.west) { v.stopped = true; }
      if (!v.stopped) v.x += v.speed;
      if (v.x > cx + roadW / 2 + 50) v.x = cx - roadW / 2 - 20 - Math.random() * 50;
    }
  });
}

function drawVehicle(ctx, v) {
  ctx.save();
  ctx.fillStyle = v.color;
  ctx.strokeStyle = 'rgba(0,0,0,0.3)';
  ctx.lineWidth = 0.5;

  const isHoriz = v.dir === 'east' || v.dir === 'west';
  const w = isHoriz ? 14 : 9;
  const h = isHoriz ? 9 : 14;

  roundRect(ctx, v.x - w / 2, v.y - h / 2, w, h, 2);
  ctx.fill();
  ctx.stroke();

  // Windshield
  ctx.fillStyle = 'rgba(255,255,255,0.4)';
  if (isHoriz) {
    ctx.fillRect(v.x - 2, v.y - 3, 4, 6);
  } else {
    ctx.fillRect(v.x - 3, v.y - 2, 6, 4);
  }

  ctx.restore();
}
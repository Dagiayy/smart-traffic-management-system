import React from 'react';
import { Button } from '@/components/ui/button';
import { CheckCircle, XCircle, X, Camera, Car, MapPin, Clock, Gauge, AlertTriangle } from 'lucide-react';

const VIOLATION_COLORS = {
  'Red Light Run': 'bg-red-100 text-red-700 border-red-200',
  'Speeding': 'bg-orange-100 text-orange-700 border-orange-200',
  'Wrong Lane': 'bg-blue-100 text-blue-700 border-blue-200',
  'Blocked Box': 'bg-yellow-100 text-yellow-700 border-yellow-200',
  'Illegal U-Turn': 'bg-purple-100 text-purple-700 border-purple-200',
  'Pedestrian Zone Violation': 'bg-pink-100 text-pink-700 border-pink-200',
};

const SIGNAL_COLORS = {
  red: 'bg-red-500',
  green: 'bg-green-500',
  yellow: 'bg-yellow-400',
};

export default function ViolationReviewModal({ violation, onConfirm, onReject, onClose }) {
  if (!violation) return null;

  const confidencePct = Math.round(violation.confidence * 100);
  const confColor = confidencePct >= 85 ? 'text-green-600' : confidencePct >= 65 ? 'text-amber-600' : 'text-red-600';
  const confBg = confidencePct >= 85 ? 'bg-green-50' : confidencePct >= 65 ? 'bg-amber-50' : 'bg-red-50';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4" onClick={onClose}>
      <div
        className="bg-card border border-border rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden"
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border bg-muted/30">
          <div className="flex items-center gap-2">
            <Camera className="w-4 h-4 text-primary" />
            <span className="font-semibold text-sm">Quick Review — Violation #{String(violation.id).slice(-5)}</span>
          </div>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-muted transition-colors">
            <X className="w-4 h-4 text-muted-foreground" />
          </button>
        </div>

        {/* Simulated camera frame */}
        <div className="relative mx-5 mt-4 rounded-xl overflow-hidden bg-slate-900 h-36 flex items-center justify-center border border-border">
          <div className="absolute inset-0 flex items-center justify-center">
            {/* Grid lines */}
            <div className="absolute inset-0 opacity-10">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="absolute border-t border-white/20" style={{ top: `${(i + 1) * (100 / 7)}%`, left: 0, right: 0 }} />
              ))}
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="absolute border-l border-white/20" style={{ left: `${(i + 1) * (100 / 9)}%`, top: 0, bottom: 0 }} />
              ))}
            </div>
            {/* Simulated vehicle */}
            <div className="relative z-10 flex flex-col items-center gap-2">
              <div className="bg-slate-700 border border-slate-500 rounded-lg px-6 py-3 shadow-lg">
                <p className="text-white font-mono font-bold text-lg tracking-widest">{violation.plate}</p>
              </div>
              <div className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border ${VIOLATION_COLORS[violation.violationType] || 'bg-red-100 text-red-700'}`}>
                {violation.violationType}
              </div>
            </div>
            {/* Corner markers */}
            {[['top-1 left-1','rounded-tl'],['top-1 right-1','rounded-tr'],['bottom-1 left-1','rounded-bl'],['bottom-1 right-1','rounded-br']].map(([pos, r]) => (
              <div key={pos} className={`absolute ${pos} w-4 h-4 border-2 border-amber-400 ${r} opacity-80`} />
            ))}
            {/* Timestamp overlay */}
            <div className="absolute bottom-2 left-2 text-[9px] font-mono text-slate-400">{violation.time} · CAM-{violation.intersection.slice(0,3).toUpperCase()}</div>
            {/* Confidence */}
            <div className={`absolute top-2 right-2 text-[9px] font-mono font-bold px-1.5 py-0.5 rounded ${confBg} ${confColor} border`}>
              AI {confidencePct}%
            </div>
          </div>
        </div>

        {/* Details grid */}
        <div className="grid grid-cols-2 gap-2 mx-5 mt-4">
          {[
            { icon: Car, label: 'Plate', value: violation.plate },
            { icon: MapPin, label: 'Intersection', value: violation.intersection },
            { icon: Clock, label: 'Time', value: violation.time },
            { icon: Gauge, label: 'Violation Type', value: violation.violationType },
          ].map(({ icon: Ic, label, value }) => (
            <div key={label} className="flex items-center gap-2 rounded-lg bg-muted/40 px-3 py-2">
              <Ic className="w-3.5 h-3.5 text-muted-foreground flex-shrink-0" />
              <div>
                <p className="text-[9px] text-muted-foreground uppercase tracking-wide">{label}</p>
                <p className="text-xs font-semibold text-foreground">{value}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Signal state */}
        <div className="mx-5 mt-2 flex items-center gap-3 rounded-lg bg-muted/30 px-3 py-2 border border-border">
          <AlertTriangle className="w-3.5 h-3.5 text-amber-500 flex-shrink-0" />
          <span className="text-[10px] text-muted-foreground">Signal at time of violation:</span>
          <div className="flex items-center gap-1.5">
            <div className={`w-3 h-3 rounded-full ${SIGNAL_COLORS[violation.signalState] || 'bg-red-500'}`} />
            <span className="text-xs font-bold uppercase font-mono">{violation.signalState || 'RED'}</span>
          </div>
          <span className="ml-auto text-[10px] font-mono text-muted-foreground">Phase {violation.phase || 1}/2</span>
        </div>

        {/* Actions */}
        <div className="flex gap-3 mx-5 my-4">
          <Button
            className="flex-1 bg-green-600 hover:bg-green-700 text-white h-9 text-xs font-semibold"
            onClick={() => { onConfirm(violation.id); onClose(); }}
          >
            <CheckCircle className="w-3.5 h-3.5 mr-1.5" /> Confirm Violation
          </Button>
          <Button
            variant="outline"
            className="flex-1 border-red-200 text-red-600 hover:bg-red-50 h-9 text-xs font-semibold"
            onClick={() => { onReject(violation.id); onClose(); }}
          >
            <XCircle className="w-3.5 h-3.5 mr-1.5" /> Reject
          </Button>
        </div>
      </div>
    </div>
  );
}
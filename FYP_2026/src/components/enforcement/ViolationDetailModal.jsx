import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
  X, CheckCircle, XCircle, Clock, Car, MapPin, Camera,
  User, Phone, Mail, CreditCard, FileText, AlertTriangle,
  Shield, Activity, Receipt, ChevronDown, ChevronUp,
  Zap, Eye, EyeOff, ExternalLink, Loader2, Image as ImageIcon,
} from 'lucide-react';
import { violationsApi, disputesApi } from '@/api/admin';

// ── Helpers ───────────────────────────────────────────────────────────────

const fmt = (dt) => dt ? new Date(dt).toLocaleString('en-ET', {
  year: 'numeric', month: 'short', day: '2-digit',
  hour: '2-digit', minute: '2-digit',
}) : '—';

const fmtDate = (d) => d ? new Date(d).toLocaleDateString('en-ET', {
  year: 'numeric', month: 'short', day: '2-digit',
}) : '—';

const fmtETB = (n) => n != null
  ? `ETB ${parseFloat(n).toLocaleString('en-ET', { minimumFractionDigits: 2 })}`
  : '—';

const STATUS_BADGE = {
  DETECTED:    { label: 'Detected',    cls: 'bg-blue-100 text-blue-700 border-blue-200' },
  UNDER_REVIEW:{ label: 'Under Review',cls: 'bg-yellow-100 text-yellow-700 border-yellow-200' },
  CONFIRMED:   { label: 'Confirmed',   cls: 'bg-red-100 text-red-700 border-red-200' },
  DISMISSED:   { label: 'Dismissed',   cls: 'bg-gray-100 text-gray-500 border-gray-200' },
  SUBMITTED:   { label: 'Submitted',   cls: 'bg-purple-100 text-purple-700 border-purple-200' },
  SYNCED:      { label: 'Synced',      cls: 'bg-teal-100 text-teal-700 border-teal-200' },
};

const SEV_BADGE = {
  MINOR:    'bg-sky-100 text-sky-700',
  MAJOR:    'bg-amber-100 text-amber-700',
  CRITICAL: 'bg-red-100 text-red-700',
};

const FINE_STATUS = {
  UNPAID:          { label: 'Unpaid',          cls: 'bg-red-100 text-red-700' },
  PAID:            { label: 'Paid',            cls: 'bg-green-100 text-green-700' },
  PARTIALLY_PAID:  { label: 'Partially Paid',  cls: 'bg-amber-100 text-amber-700' },
  WAIVED:          { label: 'Waived',          cls: 'bg-purple-100 text-purple-700' },
  DISPUTED:        { label: 'Disputed',        cls: 'bg-orange-100 text-orange-700' },
};

const DISPUTE_STATUS = {
  SUBMITTED:    { label: 'Submitted',    cls: 'bg-blue-100 text-blue-700' },
  UNDER_REVIEW: { label: 'Under Review', cls: 'bg-yellow-100 text-yellow-700' },
  APPROVED:     { label: 'Approved',     cls: 'bg-green-100 text-green-700' },
  REJECTED:     { label: 'Rejected',     cls: 'bg-red-100 text-red-700' },
  WITHDRAWN:    { label: 'Withdrawn',    cls: 'bg-gray-100 text-gray-500' },
};

// ── Sub-components ────────────────────────────────────────────────────────

function InfoRow({ icon: Icon, label, value, valueClass = '' }) {
  return (
    <div className="flex items-start gap-2.5 py-1.5">
      <Icon className="w-3.5 h-3.5 text-muted-foreground mt-0.5 flex-shrink-0" />
      <span className="text-[11px] text-muted-foreground w-28 flex-shrink-0">{label}</span>
      <span className={`text-[11px] font-medium flex-1 ${valueClass}`}>{value || '—'}</span>
    </div>
  );
}

function SectionTitle({ icon: Icon, title, children }) {
  return (
    <div className="flex items-center justify-between mb-2">
      <div className="flex items-center gap-1.5">
        <Icon className="w-3.5 h-3.5 text-primary" />
        <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">{title}</h3>
      </div>
      {children}
    </div>
  );
}

// Evidence gallery
function EvidenceGallery({ evidence }) {
  const [selected, setSelected] = useState(null);

  if (!evidence || evidence.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-32 bg-muted/30 rounded-lg border border-dashed border-border">
        <ImageIcon className="w-8 h-8 text-muted-foreground/40 mb-1" />
        <p className="text-[11px] text-muted-foreground">No evidence files attached</p>
      </div>
    );
  }

  const images = evidence.filter(e => e.file_type === 'IMAGE' || !e.file_type);
  const videos = evidence.filter(e => e.file_type === 'VIDEO');

  return (
    <div className="space-y-2">
      {selected && (
        <div className="relative rounded-lg overflow-hidden bg-slate-900 border border-border">
          <img
            src={selected}
            alt="Evidence"
            className="w-full max-h-56 object-contain"
            onError={(e) => { e.target.onerror = null; e.target.src = ''; }}
          />
          <button
            onClick={() => setSelected(null)}
            className="absolute top-2 right-2 p-1 bg-black/50 rounded-full"
          >
            <X className="w-3.5 h-3.5 text-white" />
          </button>
          <a
            href={selected}
            target="_blank"
            rel="noopener noreferrer"
            className="absolute bottom-2 right-2 flex items-center gap-1 text-[10px] bg-black/50 text-white px-2 py-1 rounded-full"
          >
            <ExternalLink className="w-3 h-3" /> Open
          </a>
        </div>
      )}
      <div className="flex flex-wrap gap-2">
        {images.map((ev, i) => (
          <button
            key={ev.id || i}
            onClick={() => setSelected(ev.file_url)}
            className={`relative w-20 h-16 rounded-lg overflow-hidden border-2 transition-all ${
              selected === ev.file_url ? 'border-primary' : 'border-border hover:border-primary/50'
            } bg-slate-900`}
          >
            <img
              src={ev.file_url}
              alt={`Evidence ${i + 1}`}
              className="w-full h-full object-cover"
              onError={(e) => {
                e.target.onerror = null;
                e.target.style.display = 'none';
                e.target.parentElement.querySelector('.fallback')?.classList.remove('hidden');
              }}
            />
            <div className="fallback hidden absolute inset-0 flex items-center justify-center">
              <Camera className="w-5 h-5 text-slate-500" />
            </div>
            <div className="absolute bottom-0.5 right-0.5 text-[8px] bg-black/60 text-white px-1 rounded">
              IMG
            </div>
          </button>
        ))}
        {videos.map((ev, i) => (
          <a
            key={ev.id || i}
            href={ev.file_url}
            target="_blank"
            rel="noopener noreferrer"
            className="relative w-20 h-16 rounded-lg overflow-hidden border-2 border-border hover:border-primary/50 bg-slate-900 flex flex-col items-center justify-center gap-1 transition-all"
          >
            <Camera className="w-5 h-5 text-slate-400" />
            <span className="text-[8px] text-slate-400">VIDEO</span>
          </a>
        ))}
      </div>
    </div>
  );
}

// Actions panel
function ActionsPanel({ violation, onStatusChange }) {
  const [notes, setNotes] = useState('');
  const [expanded, setExpanded] = useState(true);
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: ({ action, n }) => {
      if (action === 'CONFIRMED') return violationsApi.confirm(violation.id, n);
      if (action === 'DISMISSED') return violationsApi.dismiss(violation.id, n);
      return violationsApi.underReview(violation.id, n);
    },
    onSuccess: (_, { action }) => {
      queryClient.invalidateQueries({ queryKey: ['admin-violations'] });
      queryClient.invalidateQueries({ queryKey: ['violation-detail', violation.id] });
      onStatusChange(action);
    },
  });

  const canConfirm   = !['CONFIRMED', 'DISMISSED'].includes(violation.status);
  const canDismiss   = !['DISMISSED'].includes(violation.status);
  const canReview    = !['UNDER_REVIEW', 'DISMISSED'].includes(violation.status);

  const act = (action) => mutation.mutate({ action, n: notes });

  return (
    <div className="rounded-lg border border-border bg-card overflow-hidden">
      <button
        onClick={() => setExpanded(v => !v)}
        className="w-full flex items-center justify-between px-3 py-2.5 bg-muted/30 hover:bg-muted/50 transition-colors"
      >
        <div className="flex items-center gap-1.5">
          <Shield className="w-3.5 h-3.5 text-primary" />
          <span className="text-xs font-semibold">Admin Actions</span>
        </div>
        {expanded ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
      </button>
      {expanded && (
        <div className="p-3 space-y-3">
          <textarea
            value={notes}
            onChange={e => setNotes(e.target.value)}
            placeholder="Admin notes / reason for decision (optional)…"
            rows={2}
            className="w-full text-[11px] rounded-lg border border-border bg-muted/20 px-3 py-2 resize-none focus:outline-none focus:ring-1 focus:ring-primary/40 placeholder:text-muted-foreground/60"
          />
          <div className="flex gap-2">
            {canConfirm && (
              <button
                disabled={mutation.isPending}
                onClick={() => act('CONFIRMED')}
                className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-green-600 hover:bg-green-700 text-white text-[11px] font-semibold transition-colors disabled:opacity-50"
              >
                {mutation.isPending && mutation.variables?.action === 'CONFIRMED'
                  ? <Loader2 className="w-3 h-3 animate-spin" />
                  : <CheckCircle className="w-3 h-3" />}
                Confirm
              </button>
            )}
            {canReview && (
              <button
                disabled={mutation.isPending}
                onClick={() => act('UNDER_REVIEW')}
                className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-amber-500 hover:bg-amber-600 text-white text-[11px] font-semibold transition-colors disabled:opacity-50"
              >
                {mutation.isPending && mutation.variables?.action === 'UNDER_REVIEW'
                  ? <Loader2 className="w-3 h-3 animate-spin" />
                  : <Clock className="w-3 h-3" />}
                Under Review
              </button>
            )}
            {canDismiss && (
              <button
                disabled={mutation.isPending}
                onClick={() => act('DISMISSED')}
                className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg border border-red-300 text-red-600 hover:bg-red-50 text-[11px] font-semibold transition-colors disabled:opacity-50"
              >
                {mutation.isPending && mutation.variables?.action === 'DISMISSED'
                  ? <Loader2 className="w-3 h-3 animate-spin" />
                  : <XCircle className="w-3 h-3" />}
                Dismiss
              </button>
            )}
          </div>
          {mutation.isError && (
            <p className="text-[10px] text-red-500">Action failed: {mutation.error?.message}</p>
          )}
          {mutation.isSuccess && (
            <p className="text-[10px] text-green-600">Status updated successfully.</p>
          )}
        </div>
      )}
    </div>
  );
}

// Dispute decision panel
function DisputeDecidePanel({ dispute, violationId }) {
  const [reason, setReason] = useState('');
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: ({ decision }) => disputesApi.decide(dispute.id, decision, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['violation-detail', violationId] });
      queryClient.invalidateQueries({ queryKey: ['admin-violations'] });
    },
  });

  if (['APPROVED', 'REJECTED', 'WITHDRAWN'].includes(dispute.status)) {
    return (
      <div className={`rounded-lg px-3 py-2 text-[11px] ${
        dispute.status === 'APPROVED' ? 'bg-green-50 text-green-700 border border-green-200' :
        dispute.status === 'REJECTED' ? 'bg-red-50 text-red-700 border border-red-200' :
        'bg-gray-50 text-gray-500 border border-gray-200'
      }`}>
        <span className="font-semibold">Decision: {dispute.status}</span>
        {dispute.decision && (
          <span className="ml-2 text-[10px]">— {dispute.decision.reason || 'No reason provided'}</span>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-1.5 mt-2">
      <textarea
        value={reason}
        onChange={e => setReason(e.target.value)}
        placeholder="Decision reason / feedback for citizen…"
        rows={2}
        className="w-full text-[11px] rounded-lg border border-border bg-muted/20 px-3 py-2 resize-none focus:outline-none focus:ring-1 focus:ring-primary/40 placeholder:text-muted-foreground/60"
      />
      <div className="flex gap-2">
        <button
          disabled={mutation.isPending}
          onClick={() => mutation.mutate({ decision: 'APPROVE' })}
          className="flex-1 flex items-center justify-center gap-1 px-3 py-1.5 rounded-lg bg-green-600 hover:bg-green-700 text-white text-[11px] font-semibold disabled:opacity-50"
        >
          {mutation.isPending && mutation.variables?.decision === 'APPROVE'
            ? <Loader2 className="w-3 h-3 animate-spin" /> : <CheckCircle className="w-3 h-3" />}
          Approve
        </button>
        <button
          disabled={mutation.isPending}
          onClick={() => mutation.mutate({ decision: 'REJECT' })}
          className="flex-1 flex items-center justify-center gap-1 px-3 py-1.5 rounded-lg border border-red-300 text-red-600 hover:bg-red-50 text-[11px] font-semibold disabled:opacity-50"
        >
          {mutation.isPending && mutation.variables?.decision === 'REJECT'
            ? <Loader2 className="w-3 h-3 animate-spin" /> : <XCircle className="w-3 h-3" />}
          Reject
        </button>
      </div>
      {mutation.isError && (
        <p className="text-[10px] text-red-500">Failed: {mutation.error?.message}</p>
      )}
    </div>
  );
}

// ── Main Modal ────────────────────────────────────────────────────────────

export default function ViolationDetailModal({ violationId, onClose }) {
  const [currentStatus, setCurrentStatus] = useState(null);

  const { data: violation, isLoading, isError, error } = useQuery({
    queryKey: ['violation-detail', violationId],
    queryFn: () => violationsApi.detail(violationId).then(r => r.data),
    enabled: !!violationId,
  });

  const status = currentStatus || violation?.status;
  const badge = STATUS_BADGE[status] || { label: status, cls: 'bg-gray-100 text-gray-500' };
  const conf = violation?.ai_confidence
    ? Math.round(parseFloat(violation.ai_confidence) * 100)
    : null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-end bg-black/40 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="h-full w-full max-w-2xl bg-background border-l border-border shadow-2xl flex flex-col overflow-hidden"
        onClick={e => e.stopPropagation()}
      >
        {/* ── Header ── */}
        <div className="flex items-center justify-between px-5 py-3.5 border-b border-border bg-muted/30 flex-shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="p-1.5 bg-primary/10 rounded-lg">
              <AlertTriangle className="w-4 h-4 text-primary" />
            </div>
            <div>
              <p className="text-sm font-bold">
                {violation?.plate_number ?? 'Loading…'}
              </p>
              <p className="text-[10px] text-muted-foreground font-mono">
                ID: {violationId?.slice(0, 8).toUpperCase()}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {status && (
              <span className={`px-2.5 py-1 rounded-full text-[10px] font-semibold border ${badge.cls}`}>
                {badge.label}
              </span>
            )}
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg hover:bg-muted transition-colors"
            >
              <X className="w-4 h-4 text-muted-foreground" />
            </button>
          </div>
        </div>

        {/* ── Body ── */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {isLoading && (
            <div className="flex flex-col items-center justify-center py-20 gap-3">
              <Loader2 className="w-8 h-8 animate-spin text-primary" />
              <p className="text-sm text-muted-foreground">Loading violation details…</p>
            </div>
          )}
          {isError && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600">
              Failed to load: {error?.message}
            </div>
          )}

          {violation && (
            <>
              {/* ── Evidence ── */}
              <div>
                <SectionTitle icon={Camera} title="Evidence" />
                <EvidenceGallery evidence={violation.evidence} />
              </div>

              {/* ── Violation Info + Driver Info side by side ── */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Violation Details */}
                <div className="rounded-lg border border-border p-3 bg-card">
                  <SectionTitle icon={AlertTriangle} title="Violation Details" />
                  <div className="divide-y divide-border/50">
                    <InfoRow icon={Car} label="Plate Number" value={violation.plate_number} valueClass="font-mono font-bold" />
                    <InfoRow icon={Zap} label="Type" value={violation.violation_type_name || violation.type_code} />
                    <InfoRow
                      icon={Activity}
                      label="Severity"
                      value={
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${SEV_BADGE[violation.severity] || ''}`}>
                          {violation.severity}
                        </span>
                      }
                    />
                    <InfoRow icon={Eye} label="Source" value={violation.source === 'AI_DETECTION' ? '🤖 AI Detection' : '👮 Officer Field'} />
                    <InfoRow icon={MapPin} label="Location" value={violation.location_name} />
                    <InfoRow icon={Clock} label="Detected At" value={fmt(violation.detected_at)} />
                    {violation.detected_speed && (
                      <InfoRow icon={Zap} label="Speed" value={`${violation.detected_speed} km/h`} valueClass="text-red-600 font-mono" />
                    )}
                    {conf !== null && (
                      <InfoRow
                        icon={Activity}
                        label="AI Confidence"
                        value={`${conf}%`}
                        valueClass={conf >= 85 ? 'text-green-600' : conf >= 65 ? 'text-amber-600' : 'text-red-600'}
                      />
                    )}
                    {violation.officer_name && (
                      <InfoRow icon={User} label="Officer" value={violation.officer_name} />
                    )}
                    {violation.violation_type?.legal_reference && (
                      <InfoRow icon={FileText} label="Legal Ref." value={violation.violation_type.legal_reference} />
                    )}
                    {violation.notes && (
                      <InfoRow icon={FileText} label="Notes" value={violation.notes} />
                    )}
                  </div>
                </div>

                {/* Driver / Owner Info */}
                <div className="space-y-3">
                  {/* Registered Owner */}
                  <div className="rounded-lg border border-border p-3 bg-card">
                    <SectionTitle icon={User} title="Registered Owner" />
                    {violation.owner_name ? (
                      <div className="divide-y divide-border/50">
                        <InfoRow icon={User} label="Full Name" value={violation.owner_name} valueClass="font-semibold" />
                        <InfoRow icon={Phone} label="Phone" value={violation.owner_phone} />
                        <InfoRow icon={Mail} label="Email" value={violation.owner_email} />
                        <InfoRow icon={CreditCard} label="National ID" value={violation.owner_national_id} valueClass="font-mono" />
                      </div>
                    ) : (
                      <p className="text-[11px] text-muted-foreground italic">No registered owner found</p>
                    )}
                  </div>

                  {/* Vehicle Registration */}
                  <div className="rounded-lg border border-border p-3 bg-card">
                    <SectionTitle icon={Car} title="Vehicle Info" />
                    <div className="divide-y divide-border/50">
                      {violation.vehicle_make && (
                        <InfoRow icon={Car} label="Make / Model" value={`${violation.vehicle_make} ${violation.vehicle_model || ''}`} />
                      )}
                      {violation.vehicle_year && (
                        <InfoRow icon={Car} label="Year" value={violation.vehicle_year} />
                      )}
                      <InfoRow icon={Car} label="Type" value={violation.vehicle_reg_type} />
                      <InfoRow icon={Car} label="Color" value={violation.vehicle_reg_color || violation.vehicle_color} />
                      {violation.registration_expiry && (
                        <InfoRow
                          icon={FileText}
                          label="Reg. Expiry"
                          value={fmtDate(violation.registration_expiry)}
                          valueClass={new Date(violation.registration_expiry) < new Date() ? 'text-red-600' : ''}
                        />
                      )}
                    </div>
                  </div>

                  {/* Officer-entered driver info */}
                  {(violation.driver_name || violation.driver_license) && (
                    <div className="rounded-lg border border-amber-200 bg-amber-50/50 p-3">
                      <SectionTitle icon={User} title="Officer-Entered Driver Info" />
                      <div className="divide-y divide-amber-100">
                        {violation.driver_name && (
                          <InfoRow icon={User} label="Driver Name" value={violation.driver_name} />
                        )}
                        {violation.driver_license && (
                          <InfoRow icon={CreditCard} label="License No." value={violation.driver_license} valueClass="font-mono" />
                        )}
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* ── Admin Actions ── */}
              <ActionsPanel
                violation={{ id: violation.id, status }}
                onStatusChange={setCurrentStatus}
              />

              {/* ── Fine & Payment ── */}
              <div className="rounded-lg border border-border bg-card overflow-hidden">
                <div className="flex items-center gap-2 px-3 py-2.5 bg-muted/30 border-b border-border">
                  <Receipt className="w-3.5 h-3.5 text-primary" />
                  <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Fine & Payments</span>
                </div>
                {violation.fine ? (
                  <div className="p-3 space-y-3">
                    {/* Fine summary */}
                    <div className="grid grid-cols-3 gap-2">
                      <div className="rounded-lg bg-muted/40 px-3 py-2 text-center">
                        <p className="text-[9px] text-muted-foreground uppercase mb-1">Fine Amount</p>
                        <p className="text-sm font-bold font-mono text-red-600">{fmtETB(violation.fine.amount)}</p>
                      </div>
                      <div className="rounded-lg bg-muted/40 px-3 py-2 text-center">
                        <p className="text-[9px] text-muted-foreground uppercase mb-1">Amount Paid</p>
                        <p className="text-sm font-bold font-mono text-green-600">{fmtETB(violation.fine.amount_paid)}</p>
                      </div>
                      <div className="rounded-lg bg-muted/40 px-3 py-2 text-center">
                        <p className="text-[9px] text-muted-foreground uppercase mb-1">Status</p>
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${
                          (FINE_STATUS[violation.fine.status] || { cls: 'bg-gray-100 text-gray-500' }).cls
                        }`}>
                          {(FINE_STATUS[violation.fine.status] || { label: violation.fine.status }).label}
                        </span>
                      </div>
                    </div>

                    {/* Due date */}
                    {violation.fine.due_date && (
                      <p className={`text-[11px] flex items-center gap-1 ${
                        violation.fine.is_overdue ? 'text-red-600' : 'text-muted-foreground'
                      }`}>
                        <Clock className="w-3 h-3" />
                        Due: {fmtDate(violation.fine.due_date)}
                        {violation.fine.is_overdue && ' (OVERDUE)'}
                      </p>
                    )}

                    {/* Payment history */}
                    {violation.fine.payments?.length > 0 ? (
                      <div>
                        <p className="text-[10px] font-semibold text-muted-foreground uppercase mb-1.5">Payment History</p>
                        <div className="space-y-1.5">
                          {violation.fine.payments.map((p, i) => (
                            <div key={p.id || i} className="flex items-center justify-between rounded-lg bg-muted/30 px-3 py-2 border border-border/50">
                              <div className="flex items-center gap-2">
                                <div className={`w-1.5 h-1.5 rounded-full ${
                                  p.status === 'COMPLETED' ? 'bg-green-500' :
                                  p.status === 'FAILED' ? 'bg-red-500' : 'bg-amber-500'
                                }`} />
                                <div>
                                  <p className="text-[11px] font-semibold">{fmtETB(p.amount)}</p>
                                  <p className="text-[10px] text-muted-foreground">{p.method} · {fmt(p.paid_at)}</p>
                                </div>
                              </div>
                              <div className="text-right">
                                {p.receipt_number && (
                                  <p className="text-[10px] font-mono text-primary font-semibold">{p.receipt_number}</p>
                                )}
                                <p className={`text-[10px] ${
                                  p.status === 'COMPLETED' ? 'text-green-600' :
                                  p.status === 'FAILED' ? 'text-red-500' : 'text-amber-600'
                                }`}>{p.status}</p>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    ) : (
                      <p className="text-[11px] text-muted-foreground italic">No payments recorded yet</p>
                    )}
                  </div>
                ) : (
                  <div className="p-3">
                    <p className="text-[11px] text-muted-foreground italic">No fine record linked to this violation</p>
                  </div>
                )}
              </div>

              {/* ── Disputes ── */}
              <div className="rounded-lg border border-border bg-card overflow-hidden">
                <div className="flex items-center gap-2 px-3 py-2.5 bg-muted/30 border-b border-border">
                  <Shield className="w-3.5 h-3.5 text-primary" />
                  <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Disputes</span>
                  {violation.disputes?.length > 0 && (
                    <span className="ml-auto text-[10px] bg-primary/10 text-primary px-2 py-0.5 rounded-full font-semibold">
                      {violation.disputes.length} filed
                    </span>
                  )}
                </div>
                <div className="p-3">
                  {!violation.disputes || violation.disputes.length === 0 ? (
                    <p className="text-[11px] text-muted-foreground italic">No disputes filed for this violation</p>
                  ) : (
                    <div className="space-y-3">
                      {violation.disputes.map((d, i) => {
                        const ds = DISPUTE_STATUS[d.status] || { label: d.status, cls: 'bg-gray-100 text-gray-500' };
                        return (
                          <div key={d.id || i} className="rounded-lg border border-border bg-muted/10 p-3 space-y-2">
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <User className="w-3 h-3 text-muted-foreground" />
                                <span className="text-[11px] font-semibold">{d.citizen_name || 'Unknown citizen'}</span>
                                {d.citizen_phone && (
                                  <span className="text-[10px] text-muted-foreground">· {d.citizen_phone}</span>
                                )}
                              </div>
                              <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${ds.cls}`}>
                                {ds.label}
                              </span>
                            </div>
                            <div className="grid grid-cols-2 gap-x-4">
                              <p className="text-[10px] text-muted-foreground">
                                Reason: <span className="text-foreground font-medium">{d.reason?.replace(/_/g, ' ')}</span>
                              </p>
                              <p className="text-[10px] text-muted-foreground">
                                Filed: <span className="text-foreground">{fmtDate(d.submitted_at)}</span>
                              </p>
                            </div>
                            {d.description && (
                              <p className="text-[11px] text-muted-foreground bg-muted/30 rounded-lg px-3 py-2 italic">
                                "{d.description}"
                              </p>
                            )}
                            {d.decision && (
                              <div className={`rounded-lg px-3 py-1.5 text-[10px] border ${
                                d.decision.decision === 'APPROVE'
                                  ? 'bg-green-50 border-green-200 text-green-700'
                                  : 'bg-red-50 border-red-200 text-red-700'
                              }`}>
                                <span className="font-semibold">{d.decision.decision === 'APPROVE' ? '✓ Approved' : '✗ Rejected'}</span>
                                {d.decision.reason && <span className="ml-2">— {d.decision.reason}</span>}
                                <span className="ml-2 text-[9px] opacity-70">by {d.decision.decided_by} · {fmtDate(d.decision.decided_at)}</span>
                              </div>
                            )}
                            <DisputeDecidePanel dispute={d} violationId={violation.id} />
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              </div>

              {/* ── Status History ── */}
              {violation.status_history?.length > 0 && (
                <div className="rounded-lg border border-border bg-card overflow-hidden">
                  <div className="flex items-center gap-2 px-3 py-2.5 bg-muted/30 border-b border-border">
                    <Activity className="w-3.5 h-3.5 text-primary" />
                    <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Status History</span>
                  </div>
                  <div className="p-3 space-y-1.5">
                    {violation.status_history.map((h, i) => (
                      <div key={i} className="flex items-start gap-2.5 text-[11px]">
                        <div className="w-1.5 h-1.5 rounded-full bg-primary mt-1.5 flex-shrink-0" />
                        <div className="flex-1">
                          <span className="font-mono text-muted-foreground">{h.from}</span>
                          <span className="mx-1.5 text-muted-foreground">→</span>
                          <span className="font-mono font-semibold">{h.to}</span>
                          {h.reason && <span className="text-muted-foreground ml-1.5">— {h.reason}</span>}
                        </div>
                        <div className="text-right text-[10px] text-muted-foreground flex-shrink-0">
                          <div>{h.by}</div>
                          <div className="font-mono">{fmtDate(h.at)}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}

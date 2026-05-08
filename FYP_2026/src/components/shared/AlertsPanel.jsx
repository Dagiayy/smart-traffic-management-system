import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useSimulation } from '@/lib/SimulationContext';
import { AlertTriangle, CheckCircle } from 'lucide-react';

export default function AlertsPanel() {
  const { state } = useSimulation();
  const alerts = state.alerts;

  return (
    <Card>
      <CardHeader className="pb-2 pt-4 px-4">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm font-semibold">Congestion Alerts</CardTitle>
          {alerts.length > 0 && (
            <Badge variant="outline" className="border-warning text-warning text-[10px]">
              {alerts.length} active
            </Badge>
          )}
        </div>
      </CardHeader>
      <CardContent className="px-4 pb-4">
        {alerts.length === 0 ? (
          <div className="flex items-center gap-2 text-success py-2">
            <CheckCircle className="w-4 h-4" />
            <span className="text-xs">All lanes flowing normally</span>
          </div>
        ) : (
          <div className="space-y-2">
            {alerts.map((alert, i) => (
              <div key={i} className="flex items-start gap-2 p-2 rounded-lg bg-warning/10 border border-warning/20">
                <AlertTriangle className="w-3.5 h-3.5 text-warning mt-0.5 flex-shrink-0" />
                <span className="text-xs text-foreground">{alert.message}</span>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';

export default function MetricCard({ title, value, unit, icon: Icon, trend, trendLabel, color = 'blue', className }) {
  const colorMap = {
    blue: 'bg-primary/10 text-primary',
    green: 'bg-success/10 text-success',
    yellow: 'bg-warning/10 text-warning',
    red: 'bg-destructive/10 text-destructive',
    purple: 'bg-purple-100 text-purple-600',
  };

  const trendColor = trend > 0 ? 'text-success' : trend < 0 ? 'text-destructive' : 'text-muted-foreground';

  return (
    <Card className={cn('transition-all hover:shadow-md', className)}>
      <CardContent className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex-1 min-w-0">
            <p className="text-xs text-muted-foreground font-medium truncate">{title}</p>
            <div className="flex items-baseline gap-1 mt-1">
              <span className="text-2xl font-bold text-foreground tabular-nums">{value}</span>
              {unit && <span className="text-xs text-muted-foreground">{unit}</span>}
            </div>
            {trendLabel && (
              <p className={cn('text-xs mt-1', trendColor)}>
                {trend > 0 ? '↑' : trend < 0 ? '↓' : '→'} {trendLabel}
              </p>
            )}
          </div>
          {Icon && (
            <div className={cn('w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0 ml-3', colorMap[color])}>
              <Icon className="w-4 h-4" aria-hidden="true" />
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
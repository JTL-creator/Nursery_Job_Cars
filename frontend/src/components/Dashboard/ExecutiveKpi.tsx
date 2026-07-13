import { ReactNode } from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';
import clsx from 'clsx';

interface Props {
  label: string;
  value: string | number;
  icon: ReactNode;
  delta?: number;
  deltaLabel?: string;
  accent?: 'lime' | 'blue' | 'purple' | 'orange' | 'cyan';
}

const accentMap = {
  lime: { glow: 'from-gdm-lime/30 to-gdm-lime/5', icon: 'text-gdm-lime', border: 'border-gdm-lime/30' },
  blue: { glow: 'from-blue-500/30 to-blue-500/5', icon: 'text-blue-400', border: 'border-blue-500/30' },
  purple: { glow: 'from-purple-500/30 to-purple-500/5', icon: 'text-purple-400', border: 'border-purple-500/30' },
  orange: { glow: 'from-orange-500/30 to-orange-500/5', icon: 'text-orange-400', border: 'border-orange-500/30' },
  cyan: { glow: 'from-cyan-500/30 to-cyan-500/5', icon: 'text-cyan-400', border: 'border-cyan-500/30' },
};

export default function ExecutiveKpi({ label, value, icon, delta, deltaLabel, accent = 'lime' }: Props) {
  const a = accentMap[accent];
  const positivo = (delta ?? 0) >= 0;
  return (
    <div className={clsx(
      'relative overflow-hidden rounded-2xl p-4 border shadow-sm dark:shadow-none',
      'bg-white dark:bg-gradient-to-br dark:from-gdm-blue2 dark:to-gdm-blue',
      a.border
    )}>
      <div className={clsx('absolute -top-10 -right-10 w-32 h-32 rounded-full bg-gradient-to-br blur-3xl', a.glow)} />
      <div className="relative">
        <div className="flex items-start justify-between">
          <div className={clsx('w-10 h-10 rounded-xl bg-gray-100 dark:bg-white/5 flex items-center justify-center', a.icon)}>
            {icon}
          </div>
          {delta !== undefined && (
            <div className={clsx(
              'flex items-center gap-0.5 text-[10px] font-bold px-2 py-0.5 rounded-full',
              positivo ? 'text-emerald-500 bg-emerald-500/10 dark:text-emerald-400' : 'text-red-500 bg-red-500/10 dark:text-red-400'
            )}>
              {positivo ? <TrendingUp size={10} /> : <TrendingDown size={10} />}
              {Math.abs(delta)}%
            </div>
          )}
        </div>
        <p className="text-3xl font-bold text-gdm-blue dark:text-white mt-3 tracking-tight">{value}</p>
        <p className="text-[11px] text-gray-500 dark:text-gray-300/80 uppercase tracking-wider mt-1">{label}</p>
        {deltaLabel && (
          <p className="text-[10px] text-gray-400 mt-1">{deltaLabel}</p>
        )}
      </div>
    </div>
  );
}

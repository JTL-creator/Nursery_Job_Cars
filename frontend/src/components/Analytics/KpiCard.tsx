import { ReactNode } from 'react';
import clsx from 'clsx';

interface Props {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: ReactNode;
  color?: 'lime' | 'blue' | 'purple' | 'orange' | 'green' | 'red';
  trend?: { value: string; positive?: boolean };
}

const colorMap = {
  lime:   { bg: 'bg-gdm-lime/20',     text: 'text-gdm-blue dark:text-gdm-lime', border: 'border-gdm-lime' },
  blue:   { bg: 'bg-blue-100',        text: 'text-blue-700',                    border: 'border-blue-300' },
  purple: { bg: 'bg-purple-100',      text: 'text-purple-700',                  border: 'border-purple-300' },
  orange: { bg: 'bg-orange-100',      text: 'text-orange-700',                  border: 'border-orange-300' },
  green:  { bg: 'bg-green-100',       text: 'text-green-700',                   border: 'border-green-300' },
  red:    { bg: 'bg-red-100',         text: 'text-red-700',                     border: 'border-red-300' },
};

export default function KpiCard({ title, value, subtitle, icon, color = 'lime', trend }: Props) {
  const c = colorMap[color];
  return (
    <div className="bg-white dark:bg-gdm-blue2 rounded-xl border border-gray-200 dark:border-gdm-blue p-4 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div className={clsx('w-11 h-11 rounded-xl flex items-center justify-center', c.bg, c.text)}>
          {icon}
        </div>
        {trend && (
          <span className={clsx(
            'text-[10px] font-semibold px-2 py-0.5 rounded-full',
            trend.positive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
          )}>
            {trend.positive ? '+' : ''}{trend.value}
          </span>
        )}
      </div>
      <p className="text-2xl font-bold text-gdm-blue dark:text-white mt-3">{value}</p>
      <p className="text-xs font-medium text-gray-700 dark:text-gray-300 mt-1">{title}</p>
      {subtitle && (
        <p className="text-[10px] text-gray-500 dark:text-gray-400 mt-0.5">{subtitle}</p>
      )}
    </div>
  );
}

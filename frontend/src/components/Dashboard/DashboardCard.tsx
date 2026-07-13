import { ReactNode } from 'react';

interface Props {
  title: string;
  subtitle?: string;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
  height?: number;
}

export default function DashboardCard({ title, subtitle, action, children, className = '', height }: Props) {
  return (
    <div className={`bg-white border-gray-200 shadow-lg dark:bg-gradient-to-br dark:from-gdm-blue2 dark:to-gdm-blue rounded-2xl p-4 border dark:border-white/5 dark:shadow-2xl ${className}`}>
      <div className="flex items-start justify-between mb-3">
        <div>
          <h3 className="text-xs font-bold text-gdm-blue dark:text-gdm-lime uppercase tracking-widest">{title}</h3>
          {subtitle && <p className="text-[10px] text-gray-500 dark:text-gray-400 mt-0.5">{subtitle}</p>}
        </div>
        {action}
      </div>
      <div style={height ? { height } : undefined}>{children}</div>
    </div>
  );
}

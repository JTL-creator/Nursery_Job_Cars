import { ReactNode } from 'react';

interface Props {
  title: string;
  subtitle?: string;
  action?: ReactNode;
  children: ReactNode;
  height?: number;
}

export default function ChartCard({ title, subtitle, action, children, height = 300 }: Props) {
  return (
    <div className="bg-white dark:bg-gdm-blue2 rounded-xl border border-gray-200 dark:border-gdm-blue p-4 shadow-sm">
      <div className="flex items-start justify-between mb-3">
        <div>
          <h3 className="text-sm font-semibold text-gdm-blue dark:text-gdm-lime">{title}</h3>
          {subtitle && <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5">{subtitle}</p>}
        </div>
        {action}
      </div>
      <div style={{ width: '100%', height }}>{children}</div>
    </div>
  );
}

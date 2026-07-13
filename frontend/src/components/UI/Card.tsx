import { ReactNode } from 'react';
import clsx from 'clsx';

export default function Card({
  children, className, title,
}: { children: ReactNode; className?: string; title?: string }) {
  return (
    <div
      className={clsx(
        'bg-white dark:bg-gdm-blue2 rounded-xl shadow-sm border',
        'border-gray-200 dark:border-gdm-blue p-5',
        className
      )}
    >
      {title && (
        <h3 className="text-base font-semibold mb-3 text-gdm-blue dark:text-gdm-lime">
          {title}
        </h3>
      )}
      {children}
    </div>
  );
}

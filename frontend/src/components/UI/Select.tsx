import { SelectHTMLAttributes, ReactNode } from 'react';
import clsx from 'clsx';

interface Option { value: string; label: string; }

interface Props extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  options: Option[];
  error?: string;
  children?: ReactNode;
}

export default function Select({ label, options, error, className, children, ...rest }: Props) {
  return (
    <div className="flex flex-col gap-1 w-full">
      {label && (
        <label className="text-sm font-medium text-gdm-blue dark:text-gray-200">{label}</label>
      )}
      <select
        {...rest}
        className={clsx(
          'px-3 py-2 rounded-lg border bg-white dark:bg-gdm-blue2 dark:text-white',
          'border-gray-300 dark:border-gdm-blue focus:outline-none',
          'focus:ring-2 focus:ring-gdm-lime focus:border-transparent',
          error && 'border-red-500',
          className
        )}
      >
        {children}
        {options.map((o) => (
          <option key={o.value} value={o.value}>{o.label}</option>
        ))}
      </select>
      {error && <span className="text-xs text-red-500">{error}</span>}
    </div>
  );
}

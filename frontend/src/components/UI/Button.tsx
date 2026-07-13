import { ButtonHTMLAttributes, ReactNode } from 'react';
import clsx from 'clsx';

type Variant = 'primary' | 'secondary' | 'danger' | 'ghost';

interface Props extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  loading?: boolean;
  children: ReactNode;
}

export default function Button({
  variant = 'primary', loading, children, className, disabled, ...rest
}: Props) {
  const base = 'inline-flex items-center justify-center gap-2 px-4 py-2 rounded-lg font-medium transition-all disabled:opacity-50 disabled:cursor-not-allowed text-sm';
  const styles: Record<Variant, string> = {
    primary:   'bg-gdm-lime text-gdm-blue hover:brightness-110',
    secondary: 'bg-gdm-blue text-white hover:bg-gdm-blue2',
    danger:    'bg-red-600 text-white hover:bg-red-700',
    ghost:     'bg-transparent text-gdm-blue dark:text-gdm-lime hover:bg-black/5 dark:hover:bg-white/10',
  };
  return (
    <button
      {...rest}
      disabled={disabled || loading}
      className={clsx(base, styles[variant], className)}
    >
      {loading && (
        <span className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
      )}
      {children}
    </button>
  );
}

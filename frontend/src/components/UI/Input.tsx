import { InputHTMLAttributes, forwardRef } from 'react';
import clsx from 'clsx';

interface Props extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

const Input = forwardRef<HTMLInputElement, Props>(
  ({ label, error, className, ...rest }, ref) => (
    <div className="flex flex-col gap-1 w-full">
      {label && (
        <label className="text-sm font-medium text-gdm-blue dark:text-gray-200">
          {label}
        </label>
      )}
      <input
        ref={ref}
        {...rest}
        className={clsx(
          'px-3 py-2 rounded-lg border bg-white dark:bg-gdm-blue2 dark:text-white',
          'border-gray-300 dark:border-gdm-blue focus:outline-none',
          'focus:ring-2 focus:ring-gdm-lime focus:border-transparent transition-all',
          error && 'border-red-500',
          className
        )}
      />
      {error && <span className="text-xs text-red-500">{error}</span>}
    </div>
  )
);
Input.displayName = 'Input';
export default Input;

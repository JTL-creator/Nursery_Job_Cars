import { ReactNode } from 'react';
import { Inbox } from 'lucide-react';

export default function EmptyState({
  title = 'Nenhum dado encontrado',
  description,
  icon,
}: { title?: string; description?: string; icon?: ReactNode }) {
  return (
    <div className="flex flex-col items-center justify-center py-10 text-center">
      <div className="text-gdm-blue/40 dark:text-gdm-lime/40 mb-3">
        {icon || <Inbox size={48} />}
      </div>
      <p className="font-medium text-gdm-blue dark:text-gray-200">{title}</p>
      {description && (
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
          {description}
        </p>
      )}
    </div>
  );
}

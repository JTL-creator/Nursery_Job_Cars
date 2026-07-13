import clsx from 'clsx';
import { useI18n } from '../../hooks/useI18n';

const colors: Record<string, string> = {
  PENDENTE: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/40 dark:text-yellow-200',
  APROVADA: 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-200',
  REJEITADA: 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-200',
  ATIVO: 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-200',
  INATIVO: 'bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-200',
  DISPONIVEL: 'bg-green-100 text-green-800',
  RESERVADO: 'bg-blue-100 text-blue-800',
  MANUTENCAO: 'bg-orange-100 text-orange-800',
  CONFIRMADA: 'bg-blue-100 text-blue-800',
  EM_USO: 'bg-indigo-100 text-indigo-800',
  CONCLUIDA: 'bg-green-100 text-green-800',
  CANCELADA: 'bg-red-100 text-red-800',
};

export default function Badge({ value }: { value: string }) {
  const { t } = useI18n();
  const key = `badge.${value}`;
  const label = t(key);
  return (
    <span
      className={clsx(
        'px-2 py-0.5 rounded-full text-xs font-semibold',
        colors[value] || 'bg-gray-100 text-gray-700'
      )}
    >
      {label === key ? value : label}
    </span>
  );
}

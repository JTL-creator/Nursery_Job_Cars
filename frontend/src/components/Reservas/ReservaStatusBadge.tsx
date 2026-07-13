import { StatusReserva } from '../../types';
import { useI18n } from '../../hooks/useI18n';

const config: Record<StatusReserva, { bg: string; fg: string }> = {
  PENDENTE: { bg: 'bg-amber-100', fg: 'text-amber-800' },
  CONFIRMADA: { bg: 'bg-blue-100', fg: 'text-blue-800' },
  EM_USO: { bg: 'bg-purple-100', fg: 'text-purple-800' },
  CONCLUIDA: { bg: 'bg-green-100', fg: 'text-green-800' },
  CANCELADA: { bg: 'bg-red-100', fg: 'text-red-800' },
  EXPIRADA: { bg: 'bg-gray-200', fg: 'text-gray-700' },
};

export default function ReservaStatusBadge({ status }: { status: StatusReserva }) {
  const { t } = useI18n();
  const c = config[status] || config.PENDENTE;
  return (
    <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${c.bg} ${c.fg}`}>
      {t(`status.${status}`)}
    </span>
  );
}

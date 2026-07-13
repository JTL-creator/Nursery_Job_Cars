import { useEffect, useMemo, useState } from 'react';
import { RefreshCw, Search, Eye } from 'lucide-react';
import { format } from 'date-fns';
import { ptBR, enUS } from 'date-fns/locale';
import Card from '../components/UI/Card';
import Button from '../components/UI/Button';
import Spinner from '../components/UI/Spinner';
import EmptyState from '../components/UI/EmptyState';
import ReservaStatusBadge from '../components/Reservas/ReservaStatusBadge';
import ReservaDetailDrawer from '../components/Reservas/ReservaDetailDrawer';
import { Reserva, StatusReserva } from '../types';
import { listarTodasReservas } from '../services/reservaService';
import { useDebounce } from '../hooks/useDebounce';
import { useI18n } from '../hooks/useI18n';

const STATUS_OPTIONS: { value: StatusReserva | ''; labelKey: string }[] = [
  { value: '', labelKey: 'ativ.filter.allStatus' },
  { value: 'PENDENTE', labelKey: 'status.PENDENTE' },
  { value: 'CONFIRMADA', labelKey: 'status.CONFIRMADA' },
  { value: 'EM_USO', labelKey: 'status.EM_USO' },
  { value: 'CONCLUIDA', labelKey: 'status.CONCLUIDA' },
  { value: 'CANCELADA', labelKey: 'status.CANCELADA' },
  { value: 'EXPIRADA', labelKey: 'status.EXPIRADA' },
];

export default function ReservasAdminPage() {
  const { t, lang } = useI18n();
  const locale = lang === 'en' ? enUS : ptBR;
  const [items, setItems] = useState<Reserva[]>([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState<StatusReserva | ''>('');
  const [busca, setBusca] = useState('');
  const buscaDeb = useDebounce(busca, 350);
  const [drawerId, setDrawerId] = useState<string | null>(null);

  const carregar = async () => {
    try {
      setLoading(true);
      const r = await listarTodasReservas({ status: status || undefined });
      setItems(r.data);
    } catch {/* api interceptor mostra erro */ } finally {
      setLoading(false);
    }
  };

  useEffect(() => { carregar(); /* eslint-disable-next-line */ }, [status]);

  const filtradas = useMemo(() => {
    if (!buscaDeb) return items;
    const q = buscaDeb.toLowerCase();
    return items.filter((r) =>
      r.codigo_interno?.toLowerCase().includes(q) ||
      r.ativo_descricao?.toLowerCase().includes(q) ||
      r.usuario_nome?.toLowerCase().includes(q) ||
      r.motivo?.toLowerCase().includes(q)
    );
  }, [items, buscaDeb]);

  const fmt = (iso: string) => format(new Date(iso), 'dd/MM HH:mm', { locale });

  return (
    <div className="flex flex-col gap-4">
      <Card>
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-gdm-blue dark:text-gdm-lime">
              {t('radm.title')}
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {filtradas.length} {t('radm.reservations')} {status && t('radm.withStatus', { status: t(`status.${status}`) })}
            </p>
          </div>
          <Button variant="ghost" onClick={carregar}>
            <RefreshCw size={14} /> {t('common.refresh')}
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mt-4">
          <div className="relative">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
            <input
              type="text"
              value={busca}
              onChange={(e) => setBusca(e.target.value)}
              placeholder={t('radm.search')}
              className="pl-9 pr-3 py-2 w-full rounded-lg border border-gray-300 dark:border-gdm-blue bg-white dark:bg-gdm-blue2 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-gdm-lime"
            />
          </div>
          <select
            value={status}
            onChange={(e) => setStatus(e.target.value as StatusReserva | '')}
            className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue bg-white dark:bg-gdm-blue2 dark:text-white text-sm"
          >
            {STATUS_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{t(o.labelKey)}</option>
            ))}
          </select>
        </div>
      </Card>

      <Card className="!p-0 overflow-hidden">
        {loading ? (
          <div className="py-10 flex justify-center"><Spinner /></div>
        ) : filtradas.length === 0 ? (
          <EmptyState
            title={t('radm.empty.title')}
            description={t('radm.empty.desc')}
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gdm-blue text-white text-left">
                <tr>
                  <th className="px-4 py-3">{t('radm.col.asset')}</th>
                  <th className="px-4 py-3 hidden md:table-cell">{t('radm.col.user')}</th>
                  <th className="px-4 py-3">{t('radm.col.period')}</th>
                  <th className="px-4 py-3 hidden lg:table-cell">{t('radm.col.reason')}</th>
                  <th className="px-4 py-3">{t('ativ.col.status')}</th>
                  <th className="px-4 py-3 text-right">{t('ativ.col.actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gdm-blue">
                {filtradas.map((r) => (
                  <tr key={r.id} className="hover:bg-gray-50 dark:hover:bg-gdm-blue/40">
                    <td className="px-4 py-3">
                      <p className="font-semibold text-gdm-blue dark:text-white">{r.codigo_interno}</p>
                      <p className="text-[11px] text-gray-500 truncate max-w-[160px]">{r.ativo_descricao}</p>
                      <p className="md:hidden text-[10px] text-gray-400">{r.usuario_nome}</p>
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      <p className="text-xs">{r.usuario_nome || '—'}</p>
                    </td>
                    <td className="px-4 py-3 text-xs">
                      <p>{fmt(r.data_hora_inicio)}</p>
                      <p className="text-gray-500">→ {fmt(r.data_hora_fim)}</p>
                    </td>
                    <td className="px-4 py-3 hidden lg:table-cell">
                      <p className="text-xs truncate max-w-[180px]">{r.motivo || '—'}</p>
                    </td>
                    <td className="px-4 py-3">
                      <ReservaStatusBadge status={r.status} />
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end">
                        <button
                          onClick={() => setDrawerId(r.id)}
                          className="p-1.5 rounded-lg hover:bg-blue-100 text-blue-700"
                          title={t('radm.details')}
                        >
                          <Eye size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <ReservaDetailDrawer
        reservaId={drawerId}
        onClose={() => setDrawerId(null)}
        onChanged={carregar}
      />
    </div>
  );
}

import { useEffect, useState } from 'react';
import { Calendar, RefreshCw, Car, Tractor } from 'lucide-react';
import { format } from 'date-fns';
import { ptBR, enUS } from 'date-fns/locale';
import Card from '../components/UI/Card';
import Button from '../components/UI/Button';
import Spinner from '../components/UI/Spinner';
import EmptyState from '../components/UI/EmptyState';
import ReservaStatusBadge from '../components/Reservas/ReservaStatusBadge';
import { Reserva, StatusReserva } from '../types';
import { cancelarReserva, iniciarReserva, concluirReserva } from '../services/reservaService';
import api from '../services/api';
import toast from 'react-hot-toast';
import { runAction } from '../hooks/useApiData';
import { useI18n } from '../hooks/useI18n';

const TABS: { key: StatusReserva | 'TODAS' | 'ATIVAS'; labelKey: string }[] = [
  { key: 'TODAS', labelKey: 'res.tab.all' },
  { key: 'ATIVAS', labelKey: 'res.tab.active' },
  { key: 'CONCLUIDA', labelKey: 'res.tab.completed' },
  { key: 'CANCELADA', labelKey: 'res.tab.cancelled' },
];

export default function MinhasReservasPage() {
  const { t, lang } = useI18n();
  const locale = lang === 'en' ? enUS : ptBR;
  const [items, setItems] = useState<Reserva[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<typeof TABS[number]['key']>('TODAS');

  const carregar = async () => {
    try {
      setLoading(true);
      const { data } = await api.get('/usuarios/me/reservas');
      setItems(data.data || []);
    } catch {/* interceptor */ } finally {
      setLoading(false);
    }
  };

  useEffect(() => { carregar(); }, []);

  const filtradas = items.filter((r) => {
    if (tab === 'TODAS') return true;
    if (tab === 'ATIVAS') return ['PENDENTE', 'CONFIRMADA', 'EM_USO'].includes(r.status);
    return r.status === tab;
  });

  const acaoCancelar = async (r: Reserva) => {
    if (!confirm(t('res.confirmCancel', { code: r.codigo_interno }))) return;
    const ok = await runAction(() => cancelarReserva(r.id), t('res.toast.cancelled'));
    if (ok) carregar();
  };

  const acaoIniciar = async (r: Reserva) => {
    const ok = await runAction(() => iniciarReserva(r.id), t('res.toast.started'));
    if (ok) carregar();
  };

  const acaoConcluir = async (r: Reserva) => {
    const ok = await runAction(() => concluirReserva(r.id), t('res.toast.completed'));
    if (ok) carregar();
  };

  return (
    <div className="flex flex-col gap-4">
      <Card>
        <div className="flex items-center justify-between mb-3">
          <div>
            <h2 className="text-lg font-semibold text-gdm-blue dark:text-gdm-lime">
              {t('res.title')}
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {filtradas.length} {filtradas.length === 1 ? t('res.singular') : t('res.plural')}
            </p>
          </div>
          <Button variant="ghost" onClick={carregar}>
            <RefreshCw size={14} /> {t('common.refresh')}
          </Button>
        </div>

        <div className="flex gap-2 border-b border-gray-200 dark:border-gdm-blue -mx-4 px-4 pb-0 overflow-x-auto">
          {TABS.map((tb) => (
            <button
              key={tb.key}
              onClick={() => setTab(tb.key)}
              className={`px-3 py-2 text-sm font-medium border-b-2 transition-colors whitespace-nowrap ${tab === tb.key
                  ? 'border-gdm-lime text-gdm-blue dark:text-gdm-lime'
                  : 'border-transparent text-gray-500 hover:text-gdm-blue'
                }`}
            >
              {t(tb.labelKey)}
            </button>
          ))}
        </div>
      </Card>

      {loading ? (
        <Card><div className="py-10 flex justify-center"><Spinner /></div></Card>
      ) : filtradas.length === 0 ? (
        <Card>
          <EmptyState
            icon={<Calendar size={48} />}
            title={t('res.empty.title')}
            description={tab === 'TODAS' ? t('res.empty.descAll') : t('res.empty.descCat')}
          />
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
          {filtradas.map((r) => {
            const Icon = r.tipo_ativo === 'VEICULO' ? Car : Tractor;
            const horas = Math.round(
              (new Date(r.data_hora_fim).getTime() - new Date(r.data_hora_inicio).getTime()) / 3600000
            );
            return (
              <div key={r.id} className="bg-white dark:bg-gdm-blue2 rounded-xl p-4 border border-gray-200 dark:border-gdm-blue shadow-sm">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-start gap-3 flex-1 min-w-0">
                    <div className="w-11 h-11 rounded-lg bg-gdm-lime/20 text-gdm-blue flex items-center justify-center shrink-0">
                      <Icon size={20} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-bold text-gdm-blue dark:text-white">{r.codigo_interno}</p>
                      <p className="text-sm text-gray-700 dark:text-gray-300 truncate">{r.ativo_descricao}</p>
                      {r.placa && <p className="text-xs text-gray-500">{t('disp.plate')}: {r.placa}</p>}
                    </div>
                  </div>
                  <ReservaStatusBadge status={r.status} />
                </div>
                <div className="bg-gray-50 dark:bg-gdm-blue rounded-lg p-2.5 text-xs space-y-1">
                  <div className="flex justify-between">
                    <span className="text-gray-500">{t('res.start')}</span>
                    <span className="font-medium">{format(new Date(r.data_hora_inicio), 'dd/MM/yyyy HH:mm', { locale })}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">{t('res.end')}</span>
                    <span className="font-medium">{format(new Date(r.data_hora_fim), 'dd/MM/yyyy HH:mm', { locale })}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">{t('res.duration')}</span>
                    <span className="font-bold text-gdm-blue dark:text-gdm-lime">{horas}h</span>
                  </div>
                </div>
                {r.motivo && (
                  <p className="text-xs text-gray-600 dark:text-gray-300 mt-2">
                    <strong>{t('res.reason')}</strong> {r.motivo}
                  </p>
                )}
                <div className="flex gap-2 mt-3 flex-wrap">
                  {r.status === 'CONFIRMADA' && (
                    <button onClick={() => acaoIniciar(r)} className="px-3 py-1.5 rounded-lg bg-gdm-lime text-gdm-blue text-xs font-semibold hover:brightness-110">
                      {t('res.startUse')}
                    </button>
                  )}
                  {r.status === 'EM_USO' && (
                    <button onClick={() => acaoConcluir(r)} className="px-3 py-1.5 rounded-lg bg-green-600 text-white text-xs font-semibold hover:bg-green-700">
                      {t('res.finish')}
                    </button>
                  )}
                  {['PENDENTE', 'CONFIRMADA'].includes(r.status) && (
                    <button onClick={() => acaoCancelar(r)} className="px-3 py-1.5 rounded-lg border border-red-300 text-red-600 text-xs font-semibold hover:bg-red-50">
                      {t('res.cancel')}
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

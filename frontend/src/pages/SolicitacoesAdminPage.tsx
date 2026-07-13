import { useCallback, useEffect, useState } from 'react';
import Card from '../components/UI/Card';
import Badge from '../components/UI/Badge';
import Button from '../components/UI/Button';
import Spinner from '../components/UI/Spinner';
import EmptyState from '../components/UI/EmptyState';
import {
  listarSolicitacoes, aprovarSolicitacao, rejeitarSolicitacao,
} from '../services/cadastroService';
import { SolicitacaoCadastro, SolicitacaoStatus } from '../types';
import toast from 'react-hot-toast';
import { Check, X, RefreshCw, Filter } from 'lucide-react';
import { useI18n } from '../hooks/useI18n';

const statusOptions: (SolicitacaoStatus | 'TODAS')[] = ['TODAS', 'PENDENTE', 'APROVADA', 'REJEITADA'];

export default function SolicitacoesAdminPage() {
  const { t } = useI18n();
  const [items, setItems] = useState<SolicitacaoCadastro[]>([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState<SolicitacaoStatus | 'TODAS'>('PENDENTE');
  const [rejecting, setRejecting] = useState<SolicitacaoCadastro | null>(null);
  const [obs, setObs] = useState('');
  const [busyId, setBusyId] = useState<string | null>(null);

  const carregar = useCallback(async () => {
    try {
      setLoading(true);
      const list = await listarSolicitacoes(
        status === 'TODAS' ? undefined : status
      );
      setItems(list);
    } catch {
      /* interceptor cuida */
    } finally {
      setLoading(false);
    }
  }, [status]);

  useEffect(() => { carregar(); }, [carregar]);

  const aprovar = async (s: SolicitacaoCadastro) => {
    try {
      setBusyId(s.id);
      await aprovarSolicitacao(s.id);
      toast.success(t('sol.toast.approved', { name: s.nome_completo }));
      await carregar();
    } finally { setBusyId(null); }
  };

  const confirmarRejeicao = async () => {
    if (!rejecting) return;
    if (obs.trim().length < 3) {
      toast.error(t('sol.err.obs'));
      return;
    }
    try {
      setBusyId(rejecting.id);
      await rejeitarSolicitacao(rejecting.id, obs.trim());
      toast.success(t('sol.toast.rejected'));
      setRejecting(null);
      setObs('');
      await carregar();
    } finally { setBusyId(null); }
  };

  return (
    <div className="flex flex-col gap-4">
      <Card>
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-gdm-blue dark:text-gdm-lime">
              {t('sol.title')}
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {t('sol.subtitle')}
            </p>
          </div>

          <div className="flex items-center gap-2">
            <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-gray-100 dark:bg-gdm-blue">
              <Filter size={14} className="text-gdm-blue dark:text-gdm-lime" />
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value as SolicitacaoStatus | 'TODAS')}
                className="bg-transparent text-sm focus:outline-none dark:text-white"
              >
                {statusOptions.map((s) => (
                  <option key={s} value={s}>{t(`sol.status.${s}`)}</option>
                ))}
              </select>
            </div>
            <Button variant="ghost" onClick={carregar}>
              <RefreshCw size={14} /> {t('common.refresh')}
            </Button>
          </div>
        </div>
      </Card>

      <Card className="!p-0 overflow-hidden">
        {loading ? (
          <div className="py-10 flex justify-center"><Spinner /></div>
        ) : items.length === 0 ? (
          <EmptyState title={t('sol.empty.title')} description={t('sol.empty.desc')} />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gdm-blue text-white text-left">
                <tr>
                  <th className="px-4 py-3">{t('sol.col.name')}</th>
                  <th className="px-4 py-3 hidden md:table-cell">{t('sol.col.registration')}</th>
                  <th className="px-4 py-3 hidden md:table-cell">{t('sol.col.email')}</th>
                  <th className="px-4 py-3 hidden lg:table-cell">{t('sol.col.unit')}</th>
                  <th className="px-4 py-3">{t('ativ.col.status')}</th>
                  <th className="px-4 py-3 text-right">{t('ativ.col.actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gdm-blue">
                {items.map((s) => (
                  <tr key={s.id} className="hover:bg-gray-50 dark:hover:bg-gdm-blue/40">
                    <td className="px-4 py-3">
                      <p className="font-medium text-gdm-blue dark:text-white">{s.nome_completo}</p>
                      <p className="md:hidden text-[11px] text-gray-500">{s.email}</p>
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">{s.matricula}</td>
                    <td className="px-4 py-3 hidden md:table-cell">{s.email}</td>
                    <td className="px-4 py-3 hidden lg:table-cell">{s.unidade_lotacao || '—'}</td>
                    <td className="px-4 py-3"><Badge value={s.status} /></td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end gap-2">
                        {s.status === 'PENDENTE' && (
                          <>
                            <button
                              onClick={() => aprovar(s)}
                              disabled={busyId === s.id}
                              className="p-2 rounded-lg bg-green-100 text-green-700 hover:bg-green-200 disabled:opacity-50"
                              title={t('sol.approve')}
                            >
                              <Check size={16} />
                            </button>
                            <button
                              onClick={() => { setRejecting(s); setObs(''); }}
                              disabled={busyId === s.id}
                              className="p-2 rounded-lg bg-red-100 text-red-700 hover:bg-red-200 disabled:opacity-50"
                              title={t('sol.reject')}
                            >
                              <X size={16} />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Modal de rejeição */}
      {rejecting && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white dark:bg-gdm-blue2 rounded-xl p-6 max-w-md w-full">
            <h3 className="text-base font-semibold text-gdm-blue dark:text-gdm-lime">
              {t('sol.modal.title')}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-300 mt-1">
              {t('sol.modal.desc')}
            </p>
            <textarea
              value={obs}
              onChange={(e) => setObs(e.target.value)}
              rows={4}
              placeholder={t('sol.modal.placeholder')}
              className="mt-3 w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue
                         dark:bg-gdm-blue dark:text-white focus:outline-none focus:ring-2 focus:ring-gdm-lime"
            />
            <div className="flex justify-end gap-2 mt-4">
              <Button variant="ghost" onClick={() => setRejecting(null)}>{t('common.cancel')}</Button>
              <Button variant="danger" onClick={confirmarRejeicao}>{t('sol.modal.confirm')}</Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

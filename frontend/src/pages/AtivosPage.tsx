import { useEffect, useMemo, useState } from 'react';
import { Plus, RefreshCw, Search, Edit2, Trash2 } from 'lucide-react';
import Card from '../components/UI/Card';
import Button from '../components/UI/Button';
import Input from '../components/UI/Input';
import Spinner from '../components/UI/Spinner';
import EmptyState from '../components/UI/EmptyState';
import ConfirmDialog from '../components/UI/ConfirmDialog';
import AtivoFormModal from '../components/Ativos/AtivoFormModal';
import StatusActionMenu from '../components/Ativos/StatusActionMenu';
import { Ativo, TipoAtivo, StatusAtivo } from '../types';
import { listarAtivos, excluirAtivo } from '../services/ativoService';
import { mediaUrl } from '../services/api';
import { useDebounce } from '../hooks/useDebounce';
import { runAction } from '../hooks/useApiData';
import { useI18n } from '../hooks/useI18n';

const TIPOS_FILTRO: { value: TipoAtivo | ''; labelKey: string }[] = [
  { value: '', labelKey: 'ativ.filter.allTypes' },
  { value: 'VEICULO', labelKey: 'ativ.type.vehicle' },
  { value: 'MAQUINA_AGRICOLA', labelKey: 'ativ.type.machine' },
  { value: 'IMPLEMENTO', labelKey: 'ativ.type.implement' },
];

const STATUS_FILTRO: { value: StatusAtivo | ''; labelKey: string }[] = [
  { value: '', labelKey: 'ativ.filter.allStatus' },
  { value: 'DISPONIVEL', labelKey: 'astatus.DISPONIVEL' },
  { value: 'RESERVADO', labelKey: 'astatus.RESERVADO' },
  { value: 'MANUTENCAO', labelKey: 'astatus.MANUTENCAO' },
  { value: 'INDISPONIVEL', labelKey: 'astatus.INDISPONIVEL' },
];

export default function AtivosPage() {
  const { t } = useI18n();
  const [items, setItems] = useState<Ativo[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  const [busca, setBusca] = useState('');
  const buscaDebounced = useDebounce(busca, 400);
  const [tipo, setTipo] = useState<TipoAtivo | ''>('');
  const [status, setStatus] = useState<StatusAtivo | ''>('');

  const [modalAberto, setModalAberto] = useState(false);
  const [ativoEdit, setAtivoEdit] = useState<Ativo | null>(null);
  const [confirmExcluir, setConfirmExcluir] = useState<Ativo | null>(null);

  const filtros = useMemo(() => ({
    q: buscaDebounced || undefined,
    tipo_ativo: tipo || undefined,
    status: status || undefined,
  }), [buscaDebounced, tipo, status]);

  const carregar = async () => {
    try {
      setLoading(true);
      const r = await listarAtivos(filtros);
      setItems(r.data);
      setTotal((r.meta as any)?.total ?? r.data.length);
    } catch {/* api interceptor mostra erro */ } finally {
      setLoading(false);
    }
  };

  useEffect(() => { carregar(); /* eslint-disable-next-line */ }, [JSON.stringify(filtros)]);

  const novoAtivo = () => { setAtivoEdit(null); setModalAberto(true); };
  const editar = (a: Ativo) => { setAtivoEdit(a); setModalAberto(true); };
  const confirmar = async () => {
    if (!confirmExcluir) return;
    const r = await runAction(() => excluirAtivo(confirmExcluir.id), t('ativ.toast.deactivated'));
    if (r) carregar();
  };

  return (
    <div className="flex flex-col gap-4">
      <Card>
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-gdm-blue dark:text-gdm-lime">
              {t('ativ.title')}
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {total} {total === 1 ? t('ativ.count.one') : t('ativ.count.other')}
            </p>
          </div>
          <div className="flex gap-2">
            <Button variant="ghost" onClick={carregar}>
              <RefreshCw size={14} /> {t('common.refresh')}
            </Button>
            <Button onClick={novoAtivo}>
              <Plus size={14} /> {t('ativ.new')}
            </Button>
          </div>
        </div>

        {/* Filtros */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mt-4">
          <div className="relative">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
            <Input
              placeholder={t('ativ.search')}
              value={busca}
              onChange={(e) => setBusca(e.target.value)}
              className="!pl-9"
            />
          </div>
          <select
            value={tipo}
            onChange={(e) => setTipo(e.target.value as TipoAtivo | '')}
            className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue bg-white dark:bg-gdm-blue2 dark:text-white text-sm"
          >
            {TIPOS_FILTRO.map((o) => (
              <option key={o.value} value={o.value}>{t(o.labelKey)}</option>
            ))}
          </select>
          <select
            value={status}
            onChange={(e) => setStatus(e.target.value as StatusAtivo | '')}
            className="px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue bg-white dark:bg-gdm-blue2 dark:text-white text-sm"
          >
            {STATUS_FILTRO.map((o) => (
              <option key={o.value} value={o.value}>{t(o.labelKey)}</option>
            ))}
          </select>
        </div>
      </Card>

      <Card className="!p-0 overflow-hidden">
        {loading ? (
          <div className="py-10 flex justify-center"><Spinner /></div>
        ) : items.length === 0 ? (
          <EmptyState
            title={t('ativ.empty.title')}
            description={t('ativ.empty.desc')}
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gdm-blue text-white text-left">
                <tr>
                  <th className="px-4 py-3 w-14"></th>
                  <th className="px-4 py-3">{t('ativ.col.code')}</th>
                  <th className="px-4 py-3">{t('ativ.col.desc')}</th>
                  <th className="px-4 py-3 hidden md:table-cell">{t('ativ.col.type')}</th>
                  <th className="px-4 py-3 hidden lg:table-cell">{t('ativ.col.plate')}</th>
                  <th className="px-4 py-3 hidden lg:table-cell">{t('ativ.col.unit')}</th>
                  <th className="px-4 py-3 hidden md:table-cell">{t('ativ.col.team')}</th>
                  <th className="px-4 py-3 hidden xl:table-cell">{t('ativ.col.responsible')}</th>
                  <th className="px-4 py-3">{t('ativ.col.status')}</th>
                  <th className="px-4 py-3 text-right">{t('ativ.col.actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gdm-blue">
                {items.map((a) => (
                  <tr key={a.id} className="hover:bg-gray-50 dark:hover:bg-gdm-blue/40">
                    <td className="px-4 py-3">
                      <div className="w-10 h-10 rounded-lg overflow-hidden bg-gray-100 dark:bg-gdm-blue flex items-center justify-center">
                        {a.foto_url ? (
                          <img src={mediaUrl(a.foto_url)} alt="" className="w-full h-full object-cover" />
                        ) : (
                          <span className="text-[10px] text-gray-400">—</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3 font-mono text-xs font-semibold">{a.codigo_interno}</td>
                    <td className="px-4 py-3">
                      <p className="font-medium text-gdm-blue dark:text-white">{a.descricao}</p>
                      <p className="md:hidden text-[11px] text-gray-500">{a.tipo_ativo}</p>
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      <span className="text-xs">{a.tipo_ativo.replace('_', ' ')}</span>
                    </td>
                    <td className="px-4 py-3 hidden lg:table-cell">
                      {a.placa || a.patrimonio || <span className="text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3 hidden lg:table-cell">{a.unidade || '—'}</td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      {a.equipe
                        ? <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-gdm-lime/20 text-gdm-blue dark:text-gdm-lime">{a.equipe}</span>
                        : <span className="text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3 hidden xl:table-cell">
                      {a.responsavel_nome || <span className="text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3">
                      <StatusActionMenu
                        ativoId={a.id}
                        statusAtual={a.status}
                        onChanged={carregar}
                      />
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end gap-1">
                        <button
                          onClick={() => editar(a)}
                          className="p-1.5 rounded-lg hover:bg-blue-100 text-blue-700"
                          title={t('ativ.edit')}
                        >
                          <Edit2 size={14} />
                        </button>
                        <button
                          onClick={() => setConfirmExcluir(a)}
                          className="p-1.5 rounded-lg hover:bg-red-100 text-red-700"
                          title={t('ativ.deactivate')}
                        >
                          <Trash2 size={14} />
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

      <AtivoFormModal
        open={modalAberto}
        ativo={ativoEdit}
        onClose={() => setModalAberto(false)}
        onSaved={carregar}
      />

      <ConfirmDialog
        open={!!confirmExcluir}
        title={t('ativ.deactivateTitle')}
        message={t('ativ.deactivateMsg', { code: confirmExcluir?.codigo_interno || '', desc: confirmExcluir?.descricao || '' })}
        confirmLabel={t('ativ.deactivate')}
        variant="danger"
        onConfirm={confirmar}
        onClose={() => setConfirmExcluir(null)}
      />
    </div>
  );
}

import { useEffect, useState } from 'react';
import { RefreshCw, Filter, Plus } from 'lucide-react';
import Card from '../components/UI/Card';
import Button from '../components/UI/Button';
import Spinner from '../components/UI/Spinner';
import EmptyState from '../components/UI/EmptyState';
import ConfirmDialog from '../components/UI/ConfirmDialog';
import TemplateCard from '../components/Templates/TemplateCard';
import TemplateFormModal from '../components/Templates/TemplateFormModal';
import { ChecklistTemplate, TipoAtivo, EtapaChecklist } from '../types';
import { listarTemplates, excluirTemplate } from '../services/checklistService';
import { runAction } from '../hooks/useApiData';
import { useI18n } from '../hooks/useI18n';

export default function TemplatesPage() {
  const { t } = useI18n();
  const [items, setItems] = useState<ChecklistTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [tipo, setTipo] = useState<TipoAtivo | ''>('');
  const [etapa, setEtapa] = useState<EtapaChecklist | ''>('');

  const [modalAberto, setModalAberto] = useState(false);
  const [templateEdit, setTemplateEdit] = useState<ChecklistTemplate | null>(null);
  const [confirmExcluir, setConfirmExcluir] = useState<ChecklistTemplate | null>(null);

  const carregar = async () => {
    try {
      setLoading(true);
      const list = await listarTemplates({
        tipo_ativo: tipo || undefined,
        etapa: etapa || undefined,
      });
      setItems(list);
    } catch {/* interceptor mostra erro */ } finally {
      setLoading(false);
    }
  };

  useEffect(() => { carregar(); /* eslint-disable-next-line */ }, [tipo, etapa]);

  const novo = () => { setTemplateEdit(null); setModalAberto(true); };
  const editar = (tpl: ChecklistTemplate) => { setTemplateEdit(tpl); setModalAberto(true); };
  const confirmarExcluir = async () => {
    if (!confirmExcluir) return;
    const ok = await runAction(() => excluirTemplate(confirmExcluir.id), t('tf.toast.deleted'));
    if (ok) { setConfirmExcluir(null); carregar(); }
  };

  return (
    <div className="flex flex-col gap-4">
      <Card>
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-gdm-blue dark:text-gdm-lime">
              {t('tpl.title')}
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {items.length} {t('tpl.configured')}
            </p>
          </div>
          <div className="flex gap-2">
            <Button variant="ghost" onClick={carregar}>
              <RefreshCw size={14} /> {t('common.refresh')}
            </Button>
            <Button onClick={novo}>
              <Plus size={14} /> {t('tf.newTemplate')}
            </Button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mt-4">
          <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-gray-100 dark:bg-gdm-blue">
            <Filter size={14} className="text-gdm-blue dark:text-gdm-lime" />
            <select
              value={tipo}
              onChange={(e) => setTipo(e.target.value as TipoAtivo | '')}
              className="bg-transparent text-sm flex-1 focus:outline-none dark:text-white"
            >
              <option value="">{t('tpl.allTypes')}</option>
              <option value="VEICULO">{t('tpl.type.vehicle')}</option>
              <option value="MAQUINA_AGRICOLA">{t('tpl.type.machine')}</option>
              <option value="IMPLEMENTO">{t('tpl.type.implement')}</option>
            </select>
          </div>
          <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-gray-100 dark:bg-gdm-blue">
            <Filter size={14} className="text-gdm-blue dark:text-gdm-lime" />
            <select
              value={etapa}
              onChange={(e) => setEtapa(e.target.value as EtapaChecklist | '')}
              className="bg-transparent text-sm flex-1 focus:outline-none dark:text-white"
            >
              <option value="">{t('tpl.allStages')}</option>
              <option value="RETIRADA">{t('tpl.stage.pickup')}</option>
              <option value="DEVOLUCAO">{t('tpl.stage.return')}</option>
            </select>
          </div>
        </div>
      </Card>

      {loading ? (
        <Card>
          <div className="py-10 flex justify-center"><Spinner /></div>
        </Card>
      ) : items.length === 0 ? (
        <Card>
          <EmptyState
            title={t('tpl.empty.title')}
            description={t('tpl.empty.desc')}
          />
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
          {items.map((tpl) => (
            <TemplateCard
              key={tpl.id}
              template={tpl}
              onEdit={() => editar(tpl)}
              onDelete={() => setConfirmExcluir(tpl)}
            />
          ))}
        </div>
      )}

      <Card>
        <div className="flex items-start gap-3">
          <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center shrink-0">
            i
          </div>
          <div>
            <p className="text-sm font-semibold text-gdm-blue dark:text-gdm-lime">
              {t('tpl.about.title')}
            </p>
            <p className="text-xs text-gray-600 dark:text-gray-300 mt-1">
              {t('tpl.about.desc')}
            </p>
          </div>
        </div>
      </Card>

      <TemplateFormModal
        open={modalAberto}
        template={templateEdit}
        onClose={() => setModalAberto(false)}
        onSaved={carregar}
      />

      <ConfirmDialog
        open={!!confirmExcluir}
        title={t('tf.deleteTitle')}
        message={t('tf.deleteMsg', { name: confirmExcluir?.nome || '' })}
        confirmLabel={t('tf.delete')}
        variant="danger"
        onConfirm={confirmarExcluir}
        onClose={() => setConfirmExcluir(null)}
      />
    </div>
  );
}

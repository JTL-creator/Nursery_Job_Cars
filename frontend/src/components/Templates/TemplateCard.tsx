import { useState } from 'react';
import { ChevronDown, ChevronUp, FileText, Pencil, Trash2 } from 'lucide-react';
import { ChecklistTemplate } from '../../types';
import { useI18n } from '../../hooks/useI18n';

interface Props {
  template: ChecklistTemplate;
  onEdit?: () => void;
  onDelete?: () => void;
}

const TIPO_CAMPO_LABEL: Record<string, { labelKey: string; color: string }> = {
  texto: { labelKey: 'tc.field.texto', color: 'bg-blue-100 text-blue-700' },
  numero: { labelKey: 'tc.field.numero', color: 'bg-purple-100 text-purple-700' },
  booleano: { labelKey: 'tc.field.booleano', color: 'bg-green-100 text-green-700' },
  selecao: { labelKey: 'tc.field.selecao', color: 'bg-orange-100 text-orange-700' },
  data: { labelKey: 'tc.field.data', color: 'bg-cyan-100 text-cyan-700' },
  observacao: { labelKey: 'tc.field.observacao', color: 'bg-gray-100 text-gray-700' },
};

export default function TemplateCard({ template, onEdit, onDelete }: Props) {
  const { t } = useI18n();
  const [expandido, setExpandido] = useState(false);
  const total = template.itens?.length ?? 0;
  const etapaLabel = template.etapa === 'RETIRADA' ? t('chk.pickup') : t('chk.return');

  return (
    <div className="bg-white dark:bg-gdm-blue2 rounded-xl shadow-sm border border-gray-200 dark:border-gdm-blue overflow-hidden">
      <div className="flex items-center">
        <button
          onClick={() => setExpandido((e) => !e)}
          className="flex-1 min-w-0 flex items-center gap-3 p-4 hover:bg-gray-50 dark:hover:bg-gdm-blue/30 text-left"
        >
          <div className="w-10 h-10 rounded-lg bg-gdm-lime/20 text-gdm-blue flex items-center justify-center shrink-0">
            <FileText size={18} />
          </div>
          <div className="flex-1 min-w-0">
            <p className="font-semibold text-gdm-blue dark:text-gdm-lime">{template.nome}</p>
            <p className="text-xs text-gray-500 dark:text-gray-300">
              {template.tipo_ativo.replace('_', ' ')} • {etapaLabel} • v{template.versao} • {total} {total === 1 ? t('tc.item') : t('tc.items')}
            </p>
          </div>
          <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${template.ativo ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}>
            {template.ativo ? t('badge.ATIVO') : t('badge.INATIVO')}
          </span>
          {expandido ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
        </button>
        {(onEdit || onDelete) && (
          <div className="flex items-center gap-1 pr-3">
            {onEdit && (
              <button
                onClick={onEdit}
                className="p-1.5 rounded-lg hover:bg-blue-100 text-blue-700"
                title={t('tf.edit')}
              >
                <Pencil size={15} />
              </button>
            )}
            {onDelete && (
              <button
                onClick={onDelete}
                className="p-1.5 rounded-lg hover:bg-red-100 text-red-700"
                title={t('tf.delete')}
              >
                <Trash2 size={15} />
              </button>
            )}
          </div>
        )}
      </div>


      {expandido && template.itens && (
        <div className="border-t border-gray-200 dark:border-gdm-blue p-4 bg-gray-50 dark:bg-gdm-blue/30">
          <p className="text-xs font-semibold text-gdm-blue dark:text-gdm-lime mb-3">
            {t('tc.itemsTitle')}
          </p>
          <div className="space-y-2">
            {template.itens.map((it) => {
              const cfg = TIPO_CAMPO_LABEL[it.tipo_campo] ?? TIPO_CAMPO_LABEL.texto;
              const opcoes = it.opcoes_json?.opcoes;
              return (
                <div
                  key={it.id}
                  className="flex items-start gap-3 p-2.5 bg-white dark:bg-gdm-blue2 rounded-lg"
                >
                  <div className="w-6 h-6 rounded-full bg-gdm-blue text-white flex items-center justify-center text-[10px] shrink-0 mt-0.5">
                    {it.ordem}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <p className="text-sm font-medium">
                        {it.descricao}
                        {it.obrigatorio && <span className="text-red-500 ml-0.5">*</span>}
                      </p>
                      <span className={`px-1.5 py-0.5 rounded text-[9px] font-semibold ${cfg.color}`}>
                        {t(cfg.labelKey)}
                      </span>
                    </div>
                    <p className="text-[10px] text-gray-500 font-mono mt-0.5">{it.chave_item}</p>
                    {opcoes && opcoes.length > 0 && (
                      <div className="flex flex-wrap gap-1 mt-1.5">
                        {opcoes.map((o) => (
                          <span key={o} className="text-[10px] px-1.5 py-0.5 bg-gdm-lime/20 text-gdm-blue rounded">
                            {o}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

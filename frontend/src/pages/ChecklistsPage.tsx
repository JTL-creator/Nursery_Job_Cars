import { useEffect, useState } from 'react';
import { RefreshCw, ClipboardCheck, Upload, Download } from 'lucide-react';
import { format } from 'date-fns';
import { ptBR, enUS } from 'date-fns/locale';
import Card from '../components/UI/Card';
import Button from '../components/UI/Button';
import Spinner from '../components/UI/Spinner';
import EmptyState from '../components/UI/EmptyState';
import api from '../services/api';
import { useI18n } from '../hooks/useI18n';

interface ChecklistItem {
  id: string;
  reserva_id: string;
  ativo_id: string;
  etapa: 'RETIRADA' | 'DEVOLUCAO';
  tipo_checklist: string;
  data_hora_evento: string;
  local?: string;
  responsavel?: string;
  observacoes?: string;
  codigo_interno?: string;
  ativo_descricao?: string;
}

export default function ChecklistsPage() {
  const { t, lang } = useI18n();
  const locale = lang === 'en' ? enUS : ptBR;
  const [items, setItems] = useState<ChecklistItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filtro, setFiltro] = useState<'TODOS' | 'RETIRADA' | 'DEVOLUCAO'>('TODOS');

  const carregar = async () => {
    try {
      setLoading(true);
      const { data } = await api.get('/usuarios/me/checklists');
      setItems(data.data || []);
    } catch {/* interceptor */ } finally {
      setLoading(false);
    }
  };

  useEffect(() => { carregar(); }, []);

  const filtrados = filtro === 'TODOS' ? items : items.filter((c) => c.etapa === filtro);

  return (
    <div className="flex flex-col gap-4">
      <Card>
        <div className="flex items-center justify-between mb-3">
          <div>
            <h2 className="text-lg font-semibold text-gdm-blue dark:text-gdm-lime">
              {t('chk.title')}
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {t('chk.subtitle')}
            </p>
          </div>
          <Button variant="ghost" onClick={carregar}>
            <RefreshCw size={14} /> {t('common.refresh')}
          </Button>
        </div>

        <div className="flex gap-2">
          {(['TODOS', 'RETIRADA', 'DEVOLUCAO'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFiltro(f)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${filtro === f
                  ? 'bg-gdm-lime text-gdm-blue'
                  : 'bg-gray-100 dark:bg-gdm-blue text-gray-700 dark:text-gray-300 hover:bg-gray-200'
                }`}
            >
              {f === 'TODOS' ? t('chk.tab.all') : f === 'RETIRADA' ? t('chk.tab.pickup') : t('chk.tab.return')}
            </button>
          ))}
        </div>
      </Card>

      {loading ? (
        <Card><div className="py-10 flex justify-center"><Spinner /></div></Card>
      ) : filtrados.length === 0 ? (
        <Card>
          <EmptyState
            icon={<ClipboardCheck size={48} />}
            title={t('chk.empty.title')}
            description={t('chk.empty.desc')}
          />
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
          {filtrados.map((c) => {
            const ehRetirada = c.etapa === 'RETIRADA';
            const Icon = ehRetirada ? Upload : Download;
            return (
              <div key={c.id} className="bg-white dark:bg-gdm-blue2 rounded-xl p-4 border border-gray-200 dark:border-gdm-blue shadow-sm">
                <div className="flex items-start gap-3 mb-3">
                  <div className={`w-11 h-11 rounded-lg flex items-center justify-center shrink-0 ${ehRetirada ? 'bg-blue-100 text-blue-700' : 'bg-green-100 text-green-700'
                    }`}>
                    <Icon size={20} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-gdm-blue dark:text-white">{c.codigo_interno || '—'}</p>
                    <p className="text-sm text-gray-700 dark:text-gray-300 truncate">{c.ativo_descricao}</p>
                  </div>
                  <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${ehRetirada ? 'bg-blue-100 text-blue-800' : 'bg-green-100 text-green-800'
                    }`}>
                    {ehRetirada ? t('chk.pickup') : t('chk.return')}
                  </span>
                </div>
                <div className="bg-gray-50 dark:bg-gdm-blue rounded-lg p-2.5 text-xs space-y-1">
                  <div className="flex justify-between">
                    <span className="text-gray-500">{t('chk.date')}</span>
                    <span className="font-medium">
                      {format(new Date(c.data_hora_evento), 'dd/MM/yyyy HH:mm', { locale })}
                    </span>
                  </div>
                  {c.local && (
                    <div className="flex justify-between">
                      <span className="text-gray-500">{t('chk.location')}</span>
                      <span className="font-medium">{c.local}</span>
                    </div>
                  )}
                  {c.responsavel && (
                    <div className="flex justify-between">
                      <span className="text-gray-500">{t('chk.responsible')}</span>
                      <span className="font-medium">{c.responsavel}</span>
                    </div>
                  )}
                </div>
                {c.observacoes && (
                  <p className="text-xs text-gray-600 dark:text-gray-300 mt-2 line-clamp-2">
                    <strong>{t('chk.notes')}</strong> {c.observacoes}
                  </p>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

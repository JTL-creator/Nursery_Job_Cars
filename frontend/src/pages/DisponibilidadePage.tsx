import { useState } from 'react';
import { Search, Calendar, Car, Tractor } from 'lucide-react';
import { format } from 'date-fns';
import Card from '../components/UI/Card';
import Button from '../components/UI/Button';
import Spinner from '../components/UI/Spinner';
import EmptyState from '../components/UI/EmptyState';
import { Ativo, TipoAtivo } from '../types';
import { consultarDisponibilidade } from '../services/reservaService';
import { useI18n } from '../hooks/useI18n';
import toast from 'react-hot-toast';

export default function DisponibilidadePage() {
  const { t } = useI18n();
  const agora = new Date();
  const fimDefault = new Date(agora.getTime() + 8 * 60 * 60 * 1000);

  const [inicio, setInicio] = useState(format(agora, "yyyy-MM-dd'T'HH:mm"));
  const [fim, setFim] = useState(format(fimDefault, "yyyy-MM-dd'T'HH:mm"));
  const [tipo, setTipo] = useState<TipoAtivo | ''>('');
  const [ativos, setAtivos] = useState<Ativo[]>([]);
  const [loading, setLoading] = useState(false);
  const [consultado, setConsultado] = useState(false);

  const consultar = async () => {
    if (new Date(fim) <= new Date(inicio)) {
      toast.error(t('disp.err.endBeforeStart'));
      return;
    }
    const horas = (new Date(fim).getTime() - new Date(inicio).getTime()) / 3600000;
    if (horas < 1) {
      toast.error(t('disp.err.minPeriod'));
      return;
    }
    setLoading(true);
    setConsultado(true);
    try {
      const list = await consultarDisponibilidade({
        inicio: new Date(inicio).toISOString(),
        fim: new Date(fim).toISOString(),
        tipo_ativo: tipo || undefined,
      });
      setAtivos(list);
    } catch {/* interceptor */ } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <Card>
        <h2 className="text-lg font-semibold text-gdm-blue dark:text-gdm-lime mb-1">
          {t('disp.title')}
        </h2>
        <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">
          {t('disp.subtitle')}
        </p>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
          <div>
            <label className="text-xs font-medium text-gdm-blue dark:text-gray-300 block mb-1">{t('disp.start')}</label>
            <input
              type="datetime-local"
              value={inicio}
              onChange={(e) => setInicio(e.target.value)}
              className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue bg-white dark:bg-gdm-blue2 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-gdm-lime"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-gdm-blue dark:text-gray-300 block mb-1">{t('disp.end')}</label>
            <input
              type="datetime-local"
              value={fim}
              onChange={(e) => setFim(e.target.value)}
              className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue bg-white dark:bg-gdm-blue2 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-gdm-lime"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-gdm-blue dark:text-gray-300 block mb-1">{t('disp.type')}</label>
            <select
              value={tipo}
              onChange={(e) => setTipo(e.target.value as TipoAtivo | '')}
              className="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gdm-blue bg-white dark:bg-gdm-blue2 dark:text-white text-sm"
            >
              <option value="">{t('disp.allTypes')}</option>
              <option value="VEICULO">{t('disp.vehicles')}</option>
              <option value="MAQUINA_AGRICOLA">{t('disp.machines')}</option>
              <option value="IMPLEMENTO">{t('disp.implements')}</option>
            </select>
          </div>
          <div className="flex items-end">
            <Button onClick={consultar} loading={loading} className="w-full justify-center">
              <Search size={14} /> {t('disp.query')}
            </Button>
          </div>
        </div>
      </Card>

      {loading ? (
        <Card><div className="py-10 flex justify-center"><Spinner /></div></Card>
      ) : !consultado ? (
        <Card>
          <EmptyState
            icon={<Calendar size={48} />}
            title={t('disp.empty.title')}
            description={t('disp.empty.desc')}
          />
        </Card>
      ) : ativos.length === 0 ? (
        <Card>
          <EmptyState
            title={t('disp.none.title')}
            description={t('disp.none.desc')}
          />
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {ativos.map((a) => {
            const disponivel = a.disponivel !== false;
            const Icon = a.tipo_ativo === 'VEICULO' ? Car : Tractor;
            return (
              <div
                key={a.id}
                className="bg-white dark:bg-gdm-blue2 rounded-xl p-4 border border-gray-200 dark:border-gdm-blue shadow-sm hover:shadow-md transition-shadow"
              >
                <div className="flex items-start gap-3 mb-3">
                  <div className={`w-11 h-11 rounded-lg flex items-center justify-center shrink-0 ${disponivel ? 'bg-gdm-lime/20 text-gdm-blue' : 'bg-gray-200 text-gray-500'
                    }`}>
                    <Icon size={20} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-gdm-blue dark:text-white">{a.codigo_interno}</p>
                    <p className="text-sm text-gray-700 dark:text-gray-300 truncate">{a.descricao}</p>
                    {a.placa && <p className="text-xs text-gray-500">{t('disp.plate')}: {a.placa}</p>}
                    {a.unidade && <p className="text-xs text-gray-500">{a.unidade}</p>}
                  </div>
                </div>
                <div className={`px-2 py-1 rounded-md text-xs font-semibold text-center ${disponivel
                    ? 'bg-green-100 text-green-800'
                    : 'bg-red-100 text-red-800'
                  }`}>
                  {disponivel ? t('disp.available') : t('disp.unavailable')}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

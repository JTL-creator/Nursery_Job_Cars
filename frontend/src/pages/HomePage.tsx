import { useEffect, useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { useI18n } from '../hooks/useI18n';
import Card from '../components/UI/Card';
import { CalendarCheck, CalendarSearch, ClipboardList, Truck, ArrowRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import { obterResumo } from '../services/analyticsService';
import { AnalyticsResumo } from '../types';

export default function HomePage() {
  const { user, perfil } = useAuth();
  const { t } = useI18n();
  const firstName = user?.nome_completo.split(' ')[0] || 'Usuário';
  const [resumo, setResumo] = useState<AnalyticsResumo | null>(null);

  useEffect(() => {
    obterResumo().then(setResumo).catch(() => {/* ignore */ });
  }, []);

  const isAdmin = perfil === 'ADMINISTRADOR' || perfil === 'GERENTE';

  return (
    <div className="flex flex-col gap-5">
      <Card className="bg-gradient-to-r from-gdm-blue to-gdm-blue2 text-white border-0">
        <h2 className="text-xl font-bold">{t('home.greeting', { name: firstName })}</h2>
        <p className="text-sm opacity-90 mt-1">
          {t('home.profilePrefix')} <strong className="text-gdm-lime">{perfil}</strong>{t('home.profileSuffix')}
        </p>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="!p-4">
          <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-2 bg-gdm-lime/20 text-gdm-blue">
            <CalendarCheck size={20} />
          </div>
          <p className="text-2xl font-bold text-gdm-blue dark:text-white">
            {resumo?.reservas.ativas ?? '—'}
          </p>
          <p className="text-xs text-gray-500 dark:text-gray-300">{t('home.kpi.activeRes')}</p>
        </Card>
        <Card className="!p-4">
          <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-2 bg-blue-100 text-blue-700">
            <CalendarSearch size={20} />
          </div>
          <p className="text-2xl font-bold text-gdm-blue dark:text-white">
            {resumo?.reservas.hoje ?? '—'}
          </p>
          <p className="text-xs text-gray-500 dark:text-gray-300">{t('home.kpi.todayRes')}</p>
        </Card>
        <Card className="!p-4">
          <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-2 bg-orange-100 text-orange-700">
            <ClipboardList size={20} />
          </div>
          <p className="text-2xl font-bold text-gdm-blue dark:text-white">
            {resumo?.checklists.hoje ?? '—'}
          </p>
          <p className="text-xs text-gray-500 dark:text-gray-300">{t('home.kpi.todayChecklists')}</p>
        </Card>
        <Card className="!p-4">
          <div className="w-10 h-10 rounded-lg flex items-center justify-center mb-2 bg-green-100 text-green-700">
            <Truck size={20} />
          </div>
          <p className="text-2xl font-bold text-gdm-blue dark:text-white">
            {resumo?.ativos.disponiveis ?? '—'}
          </p>
          <p className="text-xs text-gray-500 dark:text-gray-300">{t('home.kpi.availableAssets')}</p>
        </Card>
      </div>

      <Card title={t('home.quickActions')}>
        <div className="flex flex-wrap gap-3">
          <Link to="/disponibilidade" className="px-4 py-2 rounded-lg bg-gdm-lime text-gdm-blue font-medium text-sm hover:brightness-110 flex items-center gap-1">
            <CalendarSearch size={14} /> {t('home.action.availability')}
          </Link>
          <Link to="/reservas" className="px-4 py-2 rounded-lg bg-gdm-blue text-white font-medium text-sm hover:bg-gdm-blue2 flex items-center gap-1">
            <CalendarCheck size={14} /> {t('home.action.myReservations')}
          </Link>
          <Link to="/checklists" className="px-4 py-2 rounded-lg border border-gdm-blue text-gdm-blue dark:text-gdm-lime dark:border-gdm-lime font-medium text-sm flex items-center gap-1">
            <ClipboardList size={14} /> {t('home.action.checklists')}
          </Link>
        </div>
      </Card>

      {isAdmin && (
        <Card title={t('home.adminPanel')}>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
            <Link to="/ativos" className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-gdm-blue hover:bg-gray-100 dark:hover:bg-gdm-blue/70 transition">
              <div className="flex items-center gap-2">
                <Truck size={16} className="text-gdm-blue dark:text-gdm-lime" />
                <span className="text-sm font-medium">{t('home.admin.assets')}</span>
              </div>
              <ArrowRight size={14} className="text-gray-400" />
            </Link>
            <Link to="/reservas-admin" className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-gdm-blue hover:bg-gray-100 dark:hover:bg-gdm-blue/70 transition">
              <div className="flex items-center gap-2">
                <CalendarCheck size={16} className="text-gdm-blue dark:text-gdm-lime" />
                <span className="text-sm font-medium">{t('home.admin.allRes')}</span>
              </div>
              <ArrowRight size={14} className="text-gray-400" />
            </Link>
            <Link to="/analytics" className="flex items-center justify-between p-3 rounded-lg bg-gradient-to-r from-gdm-blue to-gdm-blue2 text-white hover:brightness-110 transition">
              <div className="flex items-center gap-2">
                <CalendarSearch size={16} className="text-gdm-lime" />
                <span className="text-sm font-medium">{t('home.admin.analytics')}</span>
              </div>
              <ArrowRight size={14} className="text-gdm-lime" />
            </Link>
          </div>
        </Card>
      )}
    </div>
  );
}

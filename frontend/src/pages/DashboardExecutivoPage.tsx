import { useEffect, useMemo, useState } from 'react';
import {
  ResponsiveContainer, Area, AreaChart, XAxis, YAxis, Tooltip, CartesianGrid,
  RadialBarChart, RadialBar, PolarAngleAxis,
} from 'recharts';
import {
  Truck, Activity, Calendar, Users, Award, RefreshCw, Download,
  Sparkles, Target, Zap, DollarSign,
} from 'lucide-react';
import { format, subDays, eachDayOfInterval } from 'date-fns';
import { ptBR, enUS } from 'date-fns/locale';
import Spinner from '../components/UI/Spinner';
import ExecutiveKpi from '../components/Dashboard/ExecutiveKpi';
import DashboardCard from '../components/Dashboard/DashboardCard';
import HeatmapUso from '../components/Dashboard/HeatmapUso';
import FunilStatus from '../components/Dashboard/FunilStatus';
import MapaUnidades from '../components/Dashboard/MapaUnidades';
import { AnalyticsResumo, Reserva, Ativo, UsoPorAtivo } from '../types';
import { obterResumo, obterUsoPorAtivo } from '../services/analyticsService';
import { listarTodasReservas } from '../services/reservaService';
import { listarAtivos } from '../services/ativoService';
import { useI18n } from '../hooks/useI18n';
import { useTheme } from '../hooks/useTheme';

export default function DashboardExecutivoPage() {
  const [resumo, setResumo] = useState<AnalyticsResumo | null>(null);
  const [reservas, setReservas] = useState<Reserva[]>([]);
  const [ativos, setAtivos] = useState<Ativo[]>([]);
  const [usoAtivos, setUsoAtivos] = useState<UsoPorAtivo[]>([]);
  const [loading, setLoading] = useState(true);
  const { t, lang } = useI18n();
  const { theme } = useTheme();
  const isDark = theme === 'dark';
  const dateLoc = lang === 'en' ? enUS : ptBR;

  const carregar = async () => {
    try {
      setLoading(true);
      const [r, todas, ats, uso] = await Promise.all([
        obterResumo(),
        listarTodasReservas().then((r) => r.data),
        listarAtivos().then((r) => r.data),
        obterUsoPorAtivo(),
      ]);
      setResumo(r);
      setReservas(todas);
      setAtivos(ats);
      setUsoAtivos(uso);
    } catch (e) {/* interceptor */ } finally {
      setLoading(false);
    }
  };

  useEffect(() => { carregar(); }, []);

  // ===== Calculos derivados =====

  const taxaUso = useMemo(() => {
    if (!resumo || resumo.ativos.total === 0) return 0;
    return Math.round(((resumo.ativos.reservados + resumo.ativos.manutencao) / resumo.ativos.total) * 100);
  }, [resumo]);

  const taxaConclusao = useMemo(() => {
    if (reservas.length === 0) return 0;
    const concluidas = reservas.filter((r) => r.status === 'CONCLUIDA').length;
    return Math.round((concluidas / reservas.length) * 100);
  }, [reservas]);

  const taxaCancelamento = useMemo(() => {
    if (reservas.length === 0) return 0;
    const canc = reservas.filter((r) => r.status === 'CANCELADA').length;
    return Math.round((canc / reservas.length) * 100);
  }, [reservas]);

  const reservasUlt30 = useMemo(() => {
    const fim = new Date();
    const ini = subDays(fim, 29);
    const dias = eachDayOfInterval({ start: ini, end: fim });
    return dias.map((d) => {
      const ymd = format(d, 'yyyy-MM-dd');
      const total = reservas.filter((r) => r.criado_em?.startsWith(ymd)).length;
      const concluidas = reservas.filter((r) =>
        r.criado_em?.startsWith(ymd) && r.status === 'CONCLUIDA'
      ).length;
      return { dia: format(d, 'dd/MM', { locale: ptBR }), total, concluidas };
    });
  }, [reservas]);

  // Gauge: percentual de ativos em uso
  const gaugeData = useMemo(() => {
    return [{ name: 'Uso', value: taxaUso, fill: '#B4BD00' }];
  }, [taxaUso]);

  const topAtivo = useMemo(() => {
    if (usoAtivos.length === 0) return null;
    return [...usoAtivos].sort((a, b) => b.total_reservas - a.total_reservas)[0];
  }, [usoAtivos]);

  const horasTotais = useMemo(() => {
    let total = 0;
    reservas.forEach((r) => {
      const ini = new Date(r.data_hora_inicio).getTime();
      const fim = new Date(r.data_hora_fim).getTime();
      total += (fim - ini) / 3600000;
    });
    return Math.round(total);
  }, [reservas]);

  if (loading && !resumo) {
    return <div className="py-20 flex justify-center"><Spinner /></div>;
  }
  if (!resumo) return null;

  return (
    <div className="space-y-4 min-h-screen -m-4 md:-m-6 p-4 md:p-6 bg-gray-100 dark:bg-gradient-to-br dark:from-gdm-blue/95 dark:via-gdm-blue2 dark:to-black">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs text-gdm-lime uppercase tracking-widest font-bold flex items-center gap-1">
            <Sparkles size={12} /> {t('dash.eyebrow')}
          </p>
          <h1 className="text-2xl md:text-3xl font-black text-gdm-blue dark:text-white tracking-tight">
            {t('dash.title')}
          </h1>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            {t('dash.updatedAt')}{' '}
            {lang === 'en'
              ? format(new Date(), "MMM d, yyyy 'at' HH:mm", { locale: dateLoc })
              : format(new Date(), "dd 'de' MMMM 'às' HH:mm", { locale: dateLoc })}
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={carregar}
            className="px-3 py-2 rounded-lg bg-white dark:bg-white/5 text-gdm-blue dark:text-white border border-gray-200 dark:border-transparent hover:bg-gray-50 dark:hover:bg-white/10 text-xs flex items-center gap-1"
          >
            <RefreshCw size={12} /> {t('common.refresh')}
          </button>
          <button
            onClick={() => window.print()}
            className="px-3 py-2 rounded-lg bg-gdm-lime text-gdm-blue hover:brightness-110 text-xs font-bold flex items-center gap-1"
          >
            <Download size={12} /> {t('common.export')}
          </button>
        </div>
      </div>

      {/* Linha 1: 4 KPIs grandes */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <ExecutiveKpi
          label={t('dash.kpi.fleet')}
          value={resumo.ativos.total}
          icon={<Truck size={18} />}
          accent="lime"
          deltaLabel={t('dash.kpi.fleet.delta', { n: resumo.ativos.disponiveis })}
        />
        <ExecutiveKpi
          label={t('dash.kpi.activeRes')}
          value={resumo.reservas.ativas}
          icon={<Calendar size={18} />}
          accent="blue"
          deltaLabel={t('dash.kpi.activeRes.delta', { n: resumo.reservas.hoje })}
        />
        <ExecutiveKpi
          label={t('dash.kpi.ops')}
          value={resumo.checklists.total}
          icon={<Activity size={18} />}
          accent="purple"
          deltaLabel={t('dash.kpi.ops.delta', { n: resumo.checklists.hoje })}
        />
        <ExecutiveKpi
          label={t('dash.kpi.operators')}
          value={resumo.usuarios.total_ativos}
          icon={<Users size={18} />}
          accent="cyan"
          deltaLabel={t('dash.kpi.operators.delta')}
        />
      </div>

      {/* Linha 2: 4 KPIs secundarios */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <ExecutiveKpi
          label={t('dash.kpi.usage')}
          value={`${taxaUso}%`}
          icon={<Target size={18} />}
          accent={taxaUso > 70 ? 'orange' : 'lime'}
        />
        <ExecutiveKpi
          label={t('dash.kpi.completion')}
          value={`${taxaConclusao}%`}
          icon={<Award size={18} />}
          accent="lime"
        />
        <ExecutiveKpi
          label={t('dash.kpi.cancel')}
          value={`${taxaCancelamento}%`}
          icon={<Zap size={18} />}
          accent={taxaCancelamento > 15 ? 'orange' : 'cyan'}
        />
        <ExecutiveKpi
          label={t('dash.kpi.hours')}
          value={horasTotais}
          icon={<DollarSign size={18} />}
          accent="purple"
          deltaLabel={t('dash.kpi.hours.delta')}
        />
      </div>

      {/* Linha 3: Tendencia + Gauge */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-3">
        <DashboardCard
          title={t('dash.trend.title')}
          subtitle={t('dash.trend.subtitle')}
          className="lg:col-span-2"
          height={260}
        >
          <ResponsiveContainer>
            <AreaChart data={reservasUlt30}>
              <defs>
                <linearGradient id="totG" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#B4BD00" stopOpacity={0.6} />
                  <stop offset="95%" stopColor="#B4BD00" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="conG" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#06B6D4" stopOpacity={0.5} />
                  <stop offset="95%" stopColor="#06B6D4" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={isDark ? '#ffffff10' : '#e5e7eb'} />
              <XAxis dataKey="dia" tick={{ fontSize: 9, fill: '#9CA3AF' }} interval={3} />
              <YAxis tick={{ fontSize: 9, fill: '#9CA3AF' }} allowDecimals={false} />
              <Tooltip
                contentStyle={{
                  background: '#092A3B',
                  border: '1px solid #B4BD00',
                  borderRadius: 8,
                  fontSize: 11,
                  color: '#fff',
                }}
              />
              <Area
                type="monotone"
                dataKey="total"
                stroke="#B4BD00"
                strokeWidth={2}
                fill="url(#totG)"
                name={t('dash.trend.created')}
              />
              <Area
                type="monotone"
                dataKey="concluidas"
                stroke="#06B6D4"
                strokeWidth={2}
                fill="url(#conG)"
                name={t('dash.trend.completed')}
              />
            </AreaChart>
          </ResponsiveContainer>
        </DashboardCard>

        <DashboardCard title={t('dash.gauge.title')} subtitle={t('dash.gauge.subtitle')} height={260}>
          <ResponsiveContainer>
            <RadialBarChart innerRadius="60%" outerRadius="100%" data={gaugeData} startAngle={180} endAngle={0}>
              <PolarAngleAxis type="number" domain={[0, 100]} tick={false} />
              <RadialBar background dataKey="value" cornerRadius={20} fill="#B4BD00" />
              <text x="50%" y="60%" textAnchor="middle" className="fill-gdm-blue dark:fill-white" style={{ fontSize: 36, fontWeight: 'bold' }}>
                {taxaUso}%
              </text>
              <text x="50%" y="78%" textAnchor="middle" className="fill-gray-500 dark:fill-gray-400" style={{ fontSize: 11 }}>
                {t('dash.gauge.inUse')}
              </text>
            </RadialBarChart>
          </ResponsiveContainer>
        </DashboardCard>
      </div>

      {/* Linha 4: Funil + Heatmap */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
        <DashboardCard
          title={t('dash.funnel.title')}
          subtitle={t('dash.funnel.subtitle')}
        >
          <FunilStatus reservas={reservas} />
        </DashboardCard>

        <DashboardCard
          title={t('dash.heatmap.title')}
          subtitle={t('dash.heatmap.subtitle')}
        >
          <HeatmapUso reservas={reservas} />
        </DashboardCard>
      </div>

      {/* Linha 5: Mapa de unidades */}
      <DashboardCard
        title={t('dash.units.title')}
        subtitle={t('dash.units.subtitle')}
      >
        <MapaUnidades ativos={ativos} reservas={reservas} />
      </DashboardCard>

      {/* Linha 6: Insights AI */}
      <DashboardCard
        title={t('dash.insights.title')}
        subtitle={t('dash.insights.subtitle')}
        action={<Sparkles size={14} className="text-gdm-lime" />}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <InsightItem
            icon="🎯"
            label={t('dash.insight.usage')}
            value={`${taxaUso}%`}
            status={taxaUso > 70 ? 'critico' : taxaUso > 40 ? 'atencao' : 'ok'}
            descricao={taxaUso > 70 ? t('dash.insight.usage.high') : taxaUso > 40 ? t('dash.insight.usage.mid') : t('dash.insight.usage.low')}
          />
          <InsightItem
            icon="🏆"
            label={t('dash.insight.topAsset')}
            value={topAtivo?.codigo_interno || '—'}
            status="ok"
            descricao={topAtivo ? `${t('dash.insight.topAsset.reservas', { n: topAtivo.total_reservas })} - ${topAtivo.descricao}` : t('dash.insight.topAsset.none')}
          />
          <InsightItem
            icon="✅"
            label={t('dash.insight.completion')}
            value={`${taxaConclusao}%`}
            status={taxaConclusao > 70 ? 'ok' : taxaConclusao > 40 ? 'atencao' : 'critico'}
            descricao={taxaConclusao > 70 ? t('dash.insight.completion.high') : t('dash.insight.completion.low')}
          />
          <InsightItem
            icon="⚡"
            label={t('dash.insight.cancel')}
            value={`${taxaCancelamento}%`}
            status={taxaCancelamento < 10 ? 'ok' : taxaCancelamento < 20 ? 'atencao' : 'critico'}
            descricao={taxaCancelamento < 10 ? t('dash.insight.cancel.ok') : t('dash.insight.cancel.bad')}
          />
        </div>
      </DashboardCard>

      <div className="text-center text-[10px] text-gray-400 dark:text-gray-500 pt-2">
        GDM Job Cars — {t('dash.footer')} — {format(new Date(), 'yyyy')}
      </div>
    </div>
  );
}

function InsightItem({
  icon, label, value, status, descricao,
}: {
  icon: string;
  label: string;
  value: string;
  status: 'ok' | 'atencao' | 'critico';
  descricao: string;
}) {
  const cores = {
    ok: { bg: 'bg-emerald-500/10', border: 'border-emerald-500/30', text: 'text-emerald-600 dark:text-emerald-400' },
    atencao: { bg: 'bg-orange-500/10', border: 'border-orange-500/30', text: 'text-orange-600 dark:text-orange-400' },
    critico: { bg: 'bg-red-500/10', border: 'border-red-500/30', text: 'text-red-600 dark:text-red-400' },
  };
  const c = cores[status];
  return (
    <div className={`rounded-xl p-3 border ${c.bg} ${c.border}`}>
      <div className="flex items-center gap-2">
        <span className="text-xl">{icon}</span>
        <div className="flex-1 min-w-0">
          <p className="text-[10px] text-gray-500 dark:text-gray-400 uppercase tracking-wider">{label}</p>
          <p className={`text-lg font-bold ${c.text}`}>{value}</p>
        </div>
      </div>
      <p className="text-[11px] text-gray-600 dark:text-gray-300 mt-1">{descricao}</p>
    </div>
  );
}

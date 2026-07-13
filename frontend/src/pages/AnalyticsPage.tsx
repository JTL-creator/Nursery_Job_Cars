import { useEffect, useMemo, useState } from 'react';
import {
  ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid,
  PieChart, Pie, Cell, Legend, LineChart, Line, Area, AreaChart,
} from 'recharts';
import {
  Truck, Calendar, Activity, Users, RefreshCw, Wrench, CheckCircle2, AlertTriangle, Award,
} from 'lucide-react';
import { format, subDays, eachDayOfInterval } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import Button from '../components/UI/Button';
import Spinner from '../components/UI/Spinner';
import KpiCard from '../components/Analytics/KpiCard';
import ChartCard from '../components/Analytics/ChartCard';
import EmptyState from '../components/UI/EmptyState';
import Card from '../components/UI/Card';
import { AnalyticsResumo, UsoPorAtivo, Reserva } from '../types';
import { obterResumo, obterUsoPorAtivo } from '../services/analyticsService';
import { listarTodasReservas } from '../services/reservaService';

// Paleta GDM + complementares
const COLORS = {
  blue: '#092A3B',
  lime: '#B4BD00',
  orange: '#F59E0B',
  red: '#DC2626',
  green: '#16A34A',
  gray: '#9CA3AF',
  purple: '#8B5CF6',
};

const STATUS_ATIVO_COLORS: Record<string, string> = {
  DISPONIVEL: COLORS.green,
  RESERVADO: COLORS.blue,
  MANUTENCAO: COLORS.orange,
  INDISPONIVEL: COLORS.gray,
};

const TIPO_ATIVO_LABELS: Record<string, string> = {
  VEICULO: 'Veiculo',
  MAQUINA_AGRICOLA: 'Maquina',
  IMPLEMENTO: 'Implemento',
};

export default function AnalyticsPage() {
  const [resumo, setResumo] = useState<AnalyticsResumo | null>(null);
  const [usoAtivos, setUsoAtivos] = useState<UsoPorAtivo[]>([]);
  const [reservas, setReservas] = useState<Reserva[]>([]);
  const [loading, setLoading] = useState(true);

  const carregar = async () => {
    try {
      setLoading(true);
      const [r, u, todas] = await Promise.all([
        obterResumo(),
        obterUsoPorAtivo(),
        listarTodasReservas().then((r) => r.data),
      ]);
      setResumo(r);
      setUsoAtivos(u);
      setReservas(todas);
    } catch {/* interceptor mostra erro */ } finally {
      setLoading(false);
    }
  };

  useEffect(() => { carregar(); }, []);

  // ======= Dados derivados para os graficos =======

  // 1. Distribuicao de ativos por status (Pie)
  const ativosPorStatus = useMemo(() => {
    if (!resumo) return [];
    return [
      { name: 'Disponivel', value: resumo.ativos.disponiveis, color: COLORS.green },
      { name: 'Reservado', value: resumo.ativos.reservados, color: COLORS.blue },
      { name: 'Manutencao', value: resumo.ativos.manutencao, color: COLORS.orange },
      { name: 'Indisponivel', value: resumo.ativos.indisponiveis, color: COLORS.gray },
    ].filter((s) => s.value > 0);
  }, [resumo]);

  // 2. Top 10 ativos mais usados (Bar horizontal)
  const topAtivos = useMemo(() => {
    return usoAtivos
      .filter((a) => a.total_reservas > 0)
      .sort((a, b) => b.total_reservas - a.total_reservas)
      .slice(0, 10)
      .map((a) => ({
        nome: a.codigo_interno,
        descricao: a.descricao,
        total: a.total_reservas,
        concluidas: a.concluidas,
      }));
  }, [usoAtivos]);

  // 3. Reservas por dia (ultimos 30 dias) (Area)
  const reservasPorDia = useMemo(() => {
    const fim = new Date();
    const inicio = subDays(fim, 29);
    const dias = eachDayOfInterval({ start: inicio, end: fim });

    return dias.map((d) => {
      const ymd = format(d, 'yyyy-MM-dd');
      const total = reservas.filter((r) =>
        r.criado_em && r.criado_em.startsWith(ymd)
      ).length;
      return {
        dia: format(d, 'dd/MM', { locale: ptBR }),
        ymd,
        total,
      };
    });
  }, [reservas]);

  // 4. Distribuicao por tipo de ativo (das reservas)
  const reservasPorTipo = useMemo(() => {
    const cont: Record<string, number> = {};
    reservas.forEach((r) => {
      const t = r.tipo_ativo || 'OUTRO';
      cont[t] = (cont[t] || 0) + 1;
    });
    return Object.entries(cont).map(([k, v]) => ({
      tipo: TIPO_ATIVO_LABELS[k] || k,
      total: v,
    }));
  }, [reservas]);

  // 5. Distribuicao por status de reserva
  const reservasPorStatus = useMemo(() => {
    const cont: Record<string, number> = {};
    reservas.forEach((r) => {
      cont[r.status] = (cont[r.status] || 0) + 1;
    });
    const cores: Record<string, string> = {
      PENDENTE: COLORS.orange,
      CONFIRMADA: COLORS.blue,
      EM_USO: COLORS.purple,
      CONCLUIDA: COLORS.green,
      CANCELADA: COLORS.red,
      REJEITADA: '#EA580C',
      EXPIRADA: COLORS.gray,
    };
    return Object.entries(cont).map(([k, v]) => ({
      name: k.charAt(0) + k.slice(1).toLowerCase(),
      value: v,
      color: cores[k] || COLORS.gray,
    }));
  }, [reservas]);

  // 6. Metricas do fluxo de aprovacao
  const aprovacaoStats = useMemo(() => {
    const c = (s: string) => reservas.filter((r) => r.status === s).length;
    return {
      pendentes: c('PENDENTE'),
      rejeitadas: c('REJEITADA'),
      confirmadas: c('CONFIRMADA'),
      concluidas: c('CONCLUIDA'),
    };
  }, [reservas]);

  // KPIs adicionais
  const taxaUso = useMemo(() => {
    if (!resumo || resumo.ativos.total === 0) return 0;
    return Math.round(((resumo.ativos.reservados + resumo.ativos.manutencao) / resumo.ativos.total) * 100);
  }, [resumo]);

  if (loading && !resumo) {
    return (
      <div className="py-20 flex justify-center">
        <Spinner />
      </div>
    );
  }

  if (!resumo) {
    return (
      <Card>
        <EmptyState
          title="Sem dados para exibir"
          description="Crie ativos e reservas para visualizar os indicadores."
        />
      </Card>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-gdm-blue dark:text-gdm-lime">
            Analytics & Indicadores
          </h2>
          <p className="text-xs text-gray-500 dark:text-gray-400">
            Visao geral em tempo real da operacao
          </p>
        </div>
        <Button variant="ghost" onClick={carregar} loading={loading}>
          <RefreshCw size={14} /> Atualizar
        </Button>
      </div>

      {/* KPIs principais */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <KpiCard
          title="Total de ativos"
          value={resumo.ativos.total}
          subtitle={`${resumo.ativos.disponiveis} disponiveis`}
          icon={<Truck size={20} />}
          color="lime"
        />
        <KpiCard
          title="Reservas ativas"
          value={resumo.reservas.ativas}
          subtitle={`${resumo.reservas.total} no total`}
          icon={<Calendar size={20} />}
          color="blue"
        />
        <KpiCard
          title="Check-lists hoje"
          value={resumo.checklists.hoje}
          subtitle={`${resumo.checklists.total} historicos`}
          icon={<Activity size={20} />}
          color="purple"
        />
        <KpiCard
          title="Usuarios ativos"
          value={resumo.usuarios.total_ativos}
          subtitle="cadastros aprovados"
          icon={<Users size={20} />}
          color="green"
        />
      </div>

      {/* KPIs secundarios */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <KpiCard
          title="Taxa de uso"
          value={`${taxaUso}%`}
          subtitle="ativos ocupados"
          icon={<Award size={20} />}
          color={taxaUso > 70 ? 'red' : taxaUso > 40 ? 'orange' : 'green'}
        />
        <KpiCard
          title="Reservas hoje"
          value={resumo.reservas.hoje}
          subtitle="criadas no dia"
          icon={<Calendar size={20} />}
          color="orange"
        />
        <KpiCard
          title="Em manutencao"
          value={resumo.ativos.manutencao}
          subtitle="indisponiveis no momento"
          icon={<Wrench size={20} />}
          color="orange"
        />
        <KpiCard
          title="Em uso agora"
          value={resumo.ativos.reservados}
          subtitle="ativos com reserva"
          icon={<CheckCircle2 size={20} />}
          color="blue"
        />
      </div>

      {/* KPIs do fluxo de aprovacao */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <KpiCard
          title="Aguardando aprovacao"
          value={aprovacaoStats.pendentes}
          subtitle="reservas pendentes"
          icon={<AlertTriangle size={20} />}
          color="orange"
        />
        <KpiCard
          title="Confirmadas"
          value={aprovacaoStats.confirmadas}
          subtitle="aprovadas / ativas"
          icon={<CheckCircle2 size={20} />}
          color="blue"
        />
        <KpiCard
          title="Rejeitadas"
          value={aprovacaoStats.rejeitadas}
          subtitle="no historico"
          icon={<AlertTriangle size={20} />}
          color="red"
        />
        <KpiCard
          title="Concluidas"
          value={aprovacaoStats.concluidas}
          subtitle="reservas finalizadas"
          icon={<Award size={20} />}
          color="green"
        />
      </div>

      {/* Linha 1 de graficos: Status dos ativos + Status das reservas */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
        <ChartCard
          title="Distribuicao de ativos por status"
          subtitle={`${resumo.ativos.total} ativos cadastrados`}
        >
          {ativosPorStatus.length === 0 ? (
            <EmptyState title="Sem dados" description="Nenhum ativo cadastrado ainda." />
          ) : (
            <ResponsiveContainer>
              <PieChart>
                <Pie
                  data={ativosPorStatus}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={90}
                  paddingAngle={2}
                  dataKey="value"
                  label={({ name, value }) => `${name}: ${value}`}
                >
                  {ativosPorStatus.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend verticalAlign="bottom" height={28} iconType="circle" />
              </PieChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        <ChartCard
          title="Distribuicao por status de reserva"
          subtitle={`${reservas.length} reservas no historico`}
        >
          {reservasPorStatus.length === 0 ? (
            <EmptyState title="Sem reservas" description="Crie reservas para ver o grafico." />
          ) : (
            <ResponsiveContainer>
              <PieChart>
                <Pie
                  data={reservasPorStatus}
                  cx="50%"
                  cy="50%"
                  outerRadius={90}
                  dataKey="value"
                  label={({ name, value }) => `${name}: ${value}`}
                >
                  {reservasPorStatus.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend verticalAlign="bottom" height={28} iconType="circle" />
              </PieChart>
            </ResponsiveContainer>
          )}
        </ChartCard>
      </div>

      {/* Linha 2: Reservas por dia (linha do tempo) */}
      <ChartCard
        title="Reservas criadas nos ultimos 30 dias"
        subtitle="Tendencia diaria de criacao"
        height={260}
      >
        <ResponsiveContainer>
          <AreaChart data={reservasPorDia}>
            <defs>
              <linearGradient id="colorRes" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor={COLORS.lime} stopOpacity={0.8} />
                <stop offset="95%" stopColor={COLORS.lime} stopOpacity={0.1} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
            <XAxis dataKey="dia" tick={{ fontSize: 10 }} interval={3} />
            <YAxis tick={{ fontSize: 10 }} allowDecimals={false} />
            <Tooltip
              contentStyle={{ borderRadius: 8, fontSize: 12 }}
              labelStyle={{ color: COLORS.blue, fontWeight: 600 }}
            />
            <Area
              type="monotone"
              dataKey="total"
              stroke={COLORS.blue}
              strokeWidth={2}
              fill="url(#colorRes)"
              name="Reservas criadas"
            />
          </AreaChart>
        </ResponsiveContainer>
      </ChartCard>

      {/* Linha 3: Top ativos + Reservas por tipo */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-3">
        <div className="lg:col-span-2">
          <ChartCard
            title="Top 10 ativos mais reservados"
            subtitle="Ranking por total de reservas no historico"
          >
            {topAtivos.length === 0 ? (
              <EmptyState title="Sem dados" description="Ainda nao ha reservas no sistema." />
            ) : (
              <ResponsiveContainer>
                <BarChart data={topAtivos} layout="vertical" margin={{ left: 30 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                  <XAxis type="number" tick={{ fontSize: 10 }} allowDecimals={false} />
                  <YAxis dataKey="nome" type="category" tick={{ fontSize: 10 }} width={70} />
                  <Tooltip
                    contentStyle={{ borderRadius: 8, fontSize: 12 }}
                    formatter={(value: any, name: string) => [
                      value,
                      name === 'total' ? 'Reservas' : 'Concluidas',
                    ]}
                  />
                  <Bar dataKey="total" fill={COLORS.blue} name="total" radius={[0, 6, 6, 0]} />
                  <Bar dataKey="concluidas" fill={COLORS.lime} name="concluidas" radius={[0, 6, 6, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </ChartCard>
        </div>

        <ChartCard
          title="Reservas por tipo de ativo"
          subtitle="Distribuicao acumulada"
        >
          {reservasPorTipo.length === 0 ? (
            <EmptyState title="Sem dados" />
          ) : (
            <ResponsiveContainer>
              <BarChart data={reservasPorTipo}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                <XAxis dataKey="tipo" tick={{ fontSize: 10 }} />
                <YAxis tick={{ fontSize: 10 }} allowDecimals={false} />
                <Tooltip contentStyle={{ borderRadius: 8, fontSize: 12 }} />
                <Bar dataKey="total" fill={COLORS.blue} radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </ChartCard>
      </div>

      {/* Card insights */}
      <div className="bg-gradient-to-r from-gdm-blue to-gdm-blue2 rounded-xl p-5 text-white shadow-md">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-lg bg-gdm-lime/30 flex items-center justify-center shrink-0">
            <AlertTriangle size={20} className="text-gdm-lime" />
          </div>
          <div>
            <p className="font-semibold text-gdm-lime mb-1">Insights automaticos</p>
            <ul className="text-sm space-y-1 text-white/90">
              <li>• Taxa de uso atual: <strong>{taxaUso}%</strong> dos ativos ocupados</li>
              {resumo.reservas.hoje > 0 && (
                <li>• Foram criadas <strong>{resumo.reservas.hoje}</strong> reservas hoje</li>
              )}
              {resumo.ativos.manutencao > 0 && (
                <li>• Existem <strong>{resumo.ativos.manutencao}</strong> ativo(s) em manutencao</li>
              )}
              {topAtivos.length > 0 && (
                <li>• Ativo mais reservado: <strong>{topAtivos[0].nome}</strong> ({topAtivos[0].total} reservas)</li>
              )}
              {resumo.usuarios.total_ativos < 5 && (
                <li>• Considere aprovar mais cadastros para escalar o uso</li>
              )}
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}

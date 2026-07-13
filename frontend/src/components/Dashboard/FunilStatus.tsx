import { useMemo } from 'react';
import { Reserva } from '../../types';

interface Props {
  reservas: Reserva[];
}

/**
 * Funil de conversao das reservas pelo ciclo de vida.
 * Pendente -> Confirmada -> Em Uso -> Concluida
 */
export default function FunilStatus({ reservas }: Props) {
  const etapas = useMemo(() => {
    // Cada etapa "acumula" as etapas seguintes (algumas reservas pulam direto)
    const total = reservas.length;
    const confirmadas = reservas.filter((r) =>
      ['CONFIRMADA', 'EM_USO', 'CONCLUIDA'].includes(r.status)
    ).length;
    const emUso = reservas.filter((r) =>
      ['EM_USO', 'CONCLUIDA'].includes(r.status)
    ).length;
    const concluidas = reservas.filter((r) => r.status === 'CONCLUIDA').length;

    return [
      { label: 'Criadas', count: total, cor: 'from-blue-500 to-blue-400' },
      { label: 'Confirmadas', count: confirmadas, cor: 'from-cyan-500 to-cyan-400' },
      { label: 'Em uso', count: emUso, cor: 'from-purple-500 to-purple-400' },
      { label: 'Concluidas', count: concluidas, cor: 'from-emerald-500 to-emerald-400' },
    ];
  }, [reservas]);

  const max = etapas[0].count || 1;

  return (
    <div className="space-y-2">
      {etapas.map((e, i) => {
        const pct = (e.count / max) * 100;
        const conversao = i > 0 ? Math.round((e.count / etapas[i - 1].count || 0) * 100) : 100;
        return (
          <div key={e.label}>
            <div className="flex items-center justify-between text-xs mb-1">
              <span className="text-gray-600 dark:text-gray-300 font-medium">{e.label}</span>
              <div className="flex items-center gap-2">
                <span className="text-gdm-blue dark:text-white font-bold">{e.count}</span>
                {i > 0 && (
                  <span className="text-[9px] text-gdm-blue dark:text-gdm-lime bg-gdm-lime/20 dark:bg-gdm-lime/10 px-1.5 py-0.5 rounded">
                    {conversao}%
                  </span>
                )}
              </div>
            </div>
            <div className="h-7 bg-gray-100 dark:bg-white/5 rounded-lg overflow-hidden relative">
              <div
                className={`h-full bg-gradient-to-r ${e.cor} rounded-lg transition-all duration-500 flex items-center px-2`}
                style={{ width: `${pct}%` }}
              >
                {pct > 15 && (
                  <span className="text-[10px] font-bold text-white drop-shadow">
                    {pct.toFixed(0)}%
                  </span>
                )}
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

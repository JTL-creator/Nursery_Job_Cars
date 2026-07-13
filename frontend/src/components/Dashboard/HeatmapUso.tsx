import { useMemo } from 'react';
import { Reserva } from '../../types';

interface Props {
  reservas: Reserva[];
}

const DIAS = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

/**
 * Heatmap dia da semana x faixa de horario.
 * Mostra densidade de criacao de reservas.
 */
export default function HeatmapUso({ reservas }: Props) {
  const grid = useMemo(() => {
    // grid[dia][hora] = quantidade
    const g: number[][] = Array.from({ length: 7 }, () => Array(24).fill(0));
    let max = 0;
    reservas.forEach((r) => {
      if (!r.data_hora_inicio) return;
      const d = new Date(r.data_hora_inicio);
      const dow = d.getDay();
      const h = d.getHours();
      g[dow][h]++;
      if (g[dow][h] > max) max = g[dow][h];
    });
    return { g, max };
  }, [reservas]);

  const cor = (v: number): string => {
    if (v === 0) return 'bg-gray-200 dark:bg-white/5';
    const intensidade = v / (grid.max || 1);
    if (intensidade > 0.75) return 'bg-gdm-lime';
    if (intensidade > 0.5) return 'bg-gdm-lime/70';
    if (intensidade > 0.25) return 'bg-gdm-lime/40';
    return 'bg-gdm-lime/20';
  };

  if (reservas.length === 0) {
    return (
      <div className="flex items-center justify-center h-32 text-gray-400 text-xs">
        Sem dados para gerar heatmap
      </div>
    );
  }

  return (
    <div className="flex gap-2 overflow-x-auto pb-2">
      <div className="flex flex-col gap-1 pt-4 shrink-0">
        {DIAS.map((d) => (
          <div key={d} className="h-4 text-[9px] text-gray-400 flex items-center">
            {d}
          </div>
        ))}
      </div>
      <div className="flex flex-col gap-1 min-w-0">
        <div className="flex gap-0.5">
          {Array.from({ length: 24 }, (_, h) => (
            <div key={h} className="w-4 text-[8px] text-gray-500 text-center">
              {h % 3 === 0 ? h : ''}
            </div>
          ))}
        </div>
        {grid.g.map((row, i) => (
          <div key={i} className="flex gap-0.5">
            {row.map((v, h) => (
              <div
                key={h}
                className={`w-4 h-4 rounded-sm ${cor(v)} cursor-pointer transition-all hover:scale-150`}
                title={`${DIAS[i]} ${h}h: ${v} reservas`}
              />
            ))}
          </div>
        ))}
        <div className="flex items-center gap-2 mt-1 text-[9px] text-gray-400">
          <span>Menos</span>
          <div className="flex gap-0.5">
            <div className="w-3 h-3 rounded-sm bg-gray-200 dark:bg-white/5" />
            <div className="w-3 h-3 rounded-sm bg-gdm-lime/20" />
            <div className="w-3 h-3 rounded-sm bg-gdm-lime/40" />
            <div className="w-3 h-3 rounded-sm bg-gdm-lime/70" />
            <div className="w-3 h-3 rounded-sm bg-gdm-lime" />
          </div>
          <span>Mais</span>
          <span className="ml-auto">Max: {grid.max}</span>
        </div>
      </div>
    </div>
  );
}

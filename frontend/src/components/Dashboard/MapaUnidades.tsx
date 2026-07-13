import { useMemo } from 'react';
import { MapPin } from 'lucide-react';
import { Ativo, Reserva } from '../../types';

interface Props {
  ativos: Ativo[];
  reservas: Reserva[];
}

/**
 * "Mapa" textual por unidade. Como nao temos coords reais,
 * mostramos cards com indicadores por unidade.
 */
export default function MapaUnidades({ ativos, reservas }: Props) {
  const dados = useMemo(() => {
    const map: Record<string, { ativos: number; reservas: number; disponiveis: number }> = {};
    ativos.forEach((a) => {
      const u = a.unidade || 'Sem unidade';
      map[u] ??= { ativos: 0, reservas: 0, disponiveis: 0 };
      map[u].ativos++;
      if (a.status === 'DISPONIVEL') map[u].disponiveis++;
    });
    reservas.forEach((r) => {
      // tenta inferir unidade pela placa/codigo
      const ativo = ativos.find((a) => a.id === r.ativo_id);
      const u = ativo?.unidade || 'Sem unidade';
      if (map[u]) map[u].reservas++;
    });
    return Object.entries(map)
      .sort(([, a], [, b]) => b.ativos - a.ativos);
  }, [ativos, reservas]);

  if (dados.length === 0) {
    return (
      <div className="flex items-center justify-center h-32 text-gray-400 text-xs">
        Sem dados de unidades
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
      {dados.map(([nome, d]) => {
        const taxa = d.ativos > 0 ? Math.round(((d.ativos - d.disponiveis) / d.ativos) * 100) : 0;
        return (
          <div key={nome} className="bg-gray-50 dark:bg-white/5 rounded-xl p-3 border border-gray-200 dark:border-white/5 hover:border-gdm-lime/30 transition">
            <div className="flex items-start gap-2 mb-2">
              <div className="w-7 h-7 rounded-lg bg-gdm-lime/20 text-gdm-blue dark:text-gdm-lime flex items-center justify-center shrink-0">
                <MapPin size={14} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-gdm-blue dark:text-white truncate">{nome}</p>
                <p className="text-[10px] text-gray-500 dark:text-gray-400">{d.ativos} ativo(s)</p>
              </div>
            </div>
            <div className="grid grid-cols-3 gap-1 text-center">
              <div>
                <p className="text-sm font-bold text-emerald-600 dark:text-emerald-400">{d.disponiveis}</p>
                <p className="text-[9px] text-gray-500 dark:text-gray-400">Livres</p>
              </div>
              <div>
                <p className="text-sm font-bold text-purple-600 dark:text-purple-400">{d.reservas}</p>
                <p className="text-[9px] text-gray-500 dark:text-gray-400">Reservas</p>
              </div>
              <div>
                <p className="text-sm font-bold text-lime-600 dark:text-gdm-lime">{taxa}%</p>
                <p className="text-[9px] text-gray-500 dark:text-gray-400">Uso</p>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

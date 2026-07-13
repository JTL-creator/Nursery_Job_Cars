import { useCallback, useEffect, useState } from 'react';
import toast from 'react-hot-toast';

interface UseApiDataResult<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  setData: React.Dispatch<React.SetStateAction<T | null>>;
}

/**
 * Hook generico para carregar dados de uma API.
 * Faz fetch automatico ao montar e expoe refresh manual.
 */
export function useApiData<T>(
  fetcher: () => Promise<T>,
  deps: unknown[] = []
): UseApiDataResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const result = await fetcher();
      setData(result);
    } catch (e: any) {
      const msg = e?.response?.data?.message || e?.message || 'Erro ao carregar';
      setError(msg);
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => { refresh(); }, [refresh]);

  return { data, loading, error, refresh, setData };
}

/**
 * Helper para acoes (PATCH/POST/DELETE) com toast automatico.
 */
export async function runAction<T>(
  fn: () => Promise<T>,
  msgSucesso: string
): Promise<T | null> {
  try {
    const r = await fn();
    toast.success(msgSucesso);
    return r;
  } catch (e: any) {
    const msg = e?.response?.data?.message || e?.message || 'Erro na operacao';
    toast.error(msg);
    return null;
  }
}

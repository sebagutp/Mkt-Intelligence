import { useQuery, type UseQueryResult } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';

interface UseBigQueryOptions {
  queryName: string;
  params?: Record<string, unknown>;
  enabled?: boolean;
}

async function invokeBqQuery<T>(queryName: string, params: Record<string, unknown>): Promise<T> {
  const { data, error } = await supabase.functions.invoke('bq-query', {
    body: { query_name: queryName, params },
  });

  if (error) throw new Error(error.message);
  return data as T;
}

export function useBigQuery<T>({ queryName, params = {}, enabled = true }: UseBigQueryOptions): UseQueryResult<T> {
  return useQuery<T>({
    queryKey: ['bq', queryName, params],
    queryFn: () => invokeBqQuery<T>(queryName, params),
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
    enabled,
  });
}

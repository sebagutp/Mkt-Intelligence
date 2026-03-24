import { useContext } from 'react';
import { TenantContext } from '@/providers/TenantProvider';
import type { TenantConfig } from '@/types/tenant';

export function useTenant(): TenantConfig {
  const ctx = useContext(TenantContext);
  if (!ctx) {
    throw new Error('useTenant must be used within a TenantProvider with a loaded tenant');
  }
  return ctx;
}

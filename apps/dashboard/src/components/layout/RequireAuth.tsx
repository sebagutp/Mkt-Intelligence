import { Navigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { TenantProvider } from '@/providers/TenantProvider';
import type { ReactNode } from 'react';

export function RequireAuth({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();

  if (loading) return null;
  if (!user) return <Navigate to="/login" replace />;

  return <TenantProvider>{children}</TenantProvider>;
}

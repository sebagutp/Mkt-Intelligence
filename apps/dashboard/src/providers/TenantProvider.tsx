import { createContext, useEffect, useState, type ReactNode } from 'react';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/hooks/useAuth';
import { LoadingSkeleton } from '@/components/shared/LoadingSkeleton';
import type { TenantConfig } from '@/types/tenant';

export const TenantContext = createContext<TenantConfig | null>(null);

function applyBranding(tenant: TenantConfig) {
  const root = document.documentElement;
  root.style.setProperty('--brand-primary', tenant.branding.primary_color);
  root.style.setProperty('--brand-accent', tenant.branding.accent_color);

  document.title = tenant.branding.product_name;

  if (tenant.branding.favicon_url) {
    let link = document.querySelector<HTMLLinkElement>("link[rel~='icon']");
    if (!link) {
      link = document.createElement('link');
      link.rel = 'icon';
      document.head.appendChild(link);
    }
    link.href = tenant.branding.favicon_url;
  }
}

export function TenantProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [tenant, setTenant] = useState<TenantConfig | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) {
      setTenant(null);
      setLoading(false);
      return;
    }

    setLoading(true);
    supabase
      .rpc('get_my_tenant')
      .then(({ data, error }) => {
        if (error) {
          console.error('Failed to load tenant config:', error);
          setLoading(false);
          return;
        }
        const config = data as TenantConfig;
        setTenant(config);
        applyBranding(config);
        setLoading(false);
      });
  }, [user]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center p-8">
        <div className="w-full max-w-md space-y-4">
          <LoadingSkeleton type="text" />
          <LoadingSkeleton type="text" />
          <LoadingSkeleton type="chart" />
        </div>
      </div>
    );
  }

  return (
    <TenantContext.Provider value={tenant}>
      {children}
    </TenantContext.Provider>
  );
}

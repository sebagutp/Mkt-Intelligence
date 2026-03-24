import { useState, useCallback, useEffect } from 'react';
import { Settings, Palette, RotateCcw, Save, Eye } from 'lucide-react';
import { useTenant } from '@/hooks/useTenant';
import { supabase } from '@/lib/supabase';
import type { Branding } from '@/types/tenant';

interface BrandingForm {
  product_name: string;
  logo_url: string;
  primary_color: string;
  accent_color: string;
  support_email: string;
}

function brandingToForm(b: Branding, supportEmail?: string): BrandingForm {
  return {
    product_name: b.product_name,
    logo_url: b.logo_url ?? '',
    primary_color: b.primary_color,
    accent_color: b.accent_color,
    support_email: supportEmail ?? '',
  };
}

function SidebarPreview({ form }: { form: BrandingForm }) {
  return (
    <div className="w-full max-w-[200px] rounded-lg overflow-hidden border border-gray-200 dark:border-gray-700 shadow-sm">
      <div
        className="p-3 text-white text-sm font-semibold flex items-center gap-2"
        style={{ backgroundColor: form.primary_color }}
      >
        {form.logo_url ? (
          <img src={form.logo_url} alt="Logo" className="h-5 w-5 rounded object-contain bg-white/20" />
        ) : (
          <div className="h-5 w-5 rounded bg-white/20" />
        )}
        {form.product_name || 'Dashboard'}
      </div>
      <div className="bg-gray-50 dark:bg-gray-800 p-2 space-y-1">
        {['Overview', 'Channels', 'Insights', 'Reports'].map((item, i) => (
          <div
            key={item}
            className="text-xs px-2 py-1.5 rounded"
            style={i === 0 ? { backgroundColor: form.accent_color + '20', color: form.accent_color } : {}}
          >
            {item}
          </div>
        ))}
      </div>
    </div>
  );
}

function BrandingSection() {
  const tenant = useTenant();
  const isAdmin = tenant.user_role === 'admin' || tenant.user_role === 'owner';
  const [form, setForm] = useState<BrandingForm>(() => brandingToForm(tenant.branding));
  const [saved, setSaved] = useState<BrandingForm>(() => brandingToForm(tenant.branding));
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const isDirty = JSON.stringify(form) !== JSON.stringify(saved);

  // Apply live preview via CSS vars
  useEffect(() => {
    const root = document.documentElement;
    root.style.setProperty('--brand-primary', form.primary_color);
    root.style.setProperty('--brand-accent', form.accent_color);
    return () => {
      // Restore saved values on unmount
      root.style.setProperty('--brand-primary', saved.primary_color);
      root.style.setProperty('--brand-accent', saved.accent_color);
    };
  }, [form.primary_color, form.accent_color, saved.primary_color, saved.accent_color]);

  const update = useCallback((field: keyof BrandingForm, value: string) => {
    setForm(prev => ({ ...prev, [field]: value }));
  }, []);

  const handleSave = async () => {
    setSaving(true);
    const { error } = await supabase
      .from('dashboard_configs')
      .update({
        brand_primary: form.primary_color,
        brand_accent: form.accent_color,
        logo_url: form.logo_url || null,
        company_name: form.product_name,
        config: { support_email: form.support_email },
      })
      .eq('tenant_id', tenant.id);

    setSaving(false);

    if (error) {
      setToast('Failed to save branding settings');
    } else {
      setSaved({ ...form });
      setToast('Branding saved successfully');
    }

    setTimeout(() => setToast(null), 3000);
  };

  const handleReset = () => {
    setForm({ ...saved });
  };

  if (!isAdmin) {
    return null;
  }

  return (
    <section className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
      <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 flex items-center gap-2 mb-6">
        <Palette size={20} />
        Branding
      </h2>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Form */}
        <div className="lg:col-span-2 space-y-5">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Product Name
            </label>
            <input
              type="text"
              value={form.product_name}
              onChange={e => update('product_name', e.target.value)}
              className="w-full px-3 py-2 rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Logo URL
            </label>
            <div className="flex gap-3 items-start">
              <input
                type="text"
                value={form.logo_url}
                onChange={e => update('logo_url', e.target.value)}
                placeholder="https://example.com/logo.png"
                className="flex-1 px-3 py-2 rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              {form.logo_url && (
                <img
                  src={form.logo_url}
                  alt="Preview"
                  className="h-10 w-10 rounded border border-gray-200 dark:border-gray-600 object-contain"
                />
              )}
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Primary Color
              </label>
              <div className="flex gap-2 items-center">
                <input
                  type="color"
                  value={form.primary_color}
                  onChange={e => update('primary_color', e.target.value)}
                  className="h-10 w-14 rounded border border-gray-300 dark:border-gray-600 cursor-pointer"
                />
                <input
                  type="text"
                  value={form.primary_color}
                  onChange={e => update('primary_color', e.target.value)}
                  className="flex-1 px-3 py-2 rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 font-mono text-sm"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Accent Color
              </label>
              <div className="flex gap-2 items-center">
                <input
                  type="color"
                  value={form.accent_color}
                  onChange={e => update('accent_color', e.target.value)}
                  className="h-10 w-14 rounded border border-gray-300 dark:border-gray-600 cursor-pointer"
                />
                <input
                  type="text"
                  value={form.accent_color}
                  onChange={e => update('accent_color', e.target.value)}
                  className="flex-1 px-3 py-2 rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 font-mono text-sm"
                />
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Support Email
            </label>
            <input
              type="email"
              value={form.support_email}
              onChange={e => update('support_email', e.target.value)}
              placeholder="support@company.com"
              className="w-full px-3 py-2 rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-2">
            <button
              onClick={handleSave}
              disabled={!isDirty || saving}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-md bg-blue-600 text-white text-sm font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Save size={16} />
              {saving ? 'Saving...' : 'Save'}
            </button>
            <button
              onClick={handleReset}
              disabled={!isDirty}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-md border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <RotateCcw size={16} />
              Reset
            </button>
          </div>
        </div>

        {/* Preview */}
        <div>
          <p className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3 flex items-center gap-1">
            <Eye size={14} />
            Preview
          </p>
          <SidebarPreview form={form} />
        </div>
      </div>

      {/* Toast */}
      {toast && (
        <div className="fixed bottom-4 right-4 px-4 py-2 rounded-lg bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900 text-sm shadow-lg z-50">
          {toast}
        </div>
      )}
    </section>
  );
}

export function SettingsPage() {
  const tenant = useTenant();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2">
        <Settings size={24} />
        Settings
      </h1>

      {/* General info */}
      <section className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
          Organization
        </h2>
        <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-3 text-sm">
          <div>
            <dt className="text-gray-500 dark:text-gray-400">Name</dt>
            <dd className="text-gray-900 dark:text-gray-100 font-medium">{tenant.name}</dd>
          </div>
          <div>
            <dt className="text-gray-500 dark:text-gray-400">Plan</dt>
            <dd className="text-gray-900 dark:text-gray-100 font-medium capitalize">{tenant.plan.tier}</dd>
          </div>
          <div>
            <dt className="text-gray-500 dark:text-gray-400">Active Channels</dt>
            <dd className="text-gray-900 dark:text-gray-100 font-medium">
              {tenant.channels.filter(c => c.enabled).length} of {tenant.channels.length}
            </dd>
          </div>
          <div>
            <dt className="text-gray-500 dark:text-gray-400">Your Role</dt>
            <dd className="text-gray-900 dark:text-gray-100 font-medium capitalize">{tenant.user_role}</dd>
          </div>
        </dl>
      </section>

      {/* Branding — admin only */}
      <BrandingSection />
    </div>
  );
}

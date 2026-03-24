export type ChannelType =
  | 'google_analytics'
  | 'google_ads'
  | 'meta_ads'
  | 'email'
  | 'linkedin';

export interface Branding {
  primary_color: string;
  accent_color: string;
  logo_url: string | null;
  favicon_url: string | null;
  product_name: string;
}

export interface TenantChannel {
  id: string;
  tenant_id: string;
  channel_type: ChannelType;
  enabled: boolean;
  label: string;
}

export type PlanTier = 'starter' | 'growth' | 'enterprise';

export interface Plan {
  tier: PlanTier;
  max_channels: number;
  max_users: number;
}

export interface TenantConfig {
  id: string;
  slug: string;
  name: string;
  bq_project_id: string;
  bq_dataset: string;
  branding: Branding;
  plan: Plan;
  channels: TenantChannel[];
}

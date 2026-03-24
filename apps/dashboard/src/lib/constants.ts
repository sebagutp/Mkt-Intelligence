import type { ChannelType } from '@/types/tenant';

export const CHANNEL_LABELS: Record<ChannelType, string> = {
  google_analytics: 'Google Analytics',
  google_ads: 'Google Ads',
  meta_ads: 'Meta Ads',
  email: 'Email Marketing',
  linkedin: 'LinkedIn',
};

export const DATE_PRESETS = [
  { label: '7 days', value: 7 },
  { label: '14 days', value: 14 },
  { label: '30 days', value: 30 },
  { label: '90 days', value: 90 },
] as const;

export const SYNC_INTERVAL = 86_400_000; // 24h in ms

export const MAX_CHANNELS: Record<string, number> = {
  starter: 3,
  growth: 5,
  enterprise: 10,
};

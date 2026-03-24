import type { ChannelType } from './tenant';

export interface KPIData {
  total_spend: number;
  total_conversions: number;
  total_conversion_value: number;
  total_impressions: number;
  total_clicks: number;
  blended_cpa: number | null;
  blended_roas: number | null;
  blended_ctr: number | null;
  blended_cpc: number | null;
  blended_cpm: number | null;
  spend_delta_pct: number | null;
  conversions_delta_pct: number | null;
  revenue_delta_pct: number | null;
  cpa_delta_pct: number | null;
  roas_delta_pct: number | null;
}

export interface DailyTrend {
  metric_date: string;
  total_spend: number;
  total_conversions: number;
  total_clicks: number;
  total_impressions: number;
}

export interface ChannelSummary {
  channel: ChannelType;
  total_spend: number;
  total_conversions: number;
  total_clicks: number;
  total_impressions: number;
  pct_of_spend: number;
}

export interface ComparisonRow {
  channel: string;
  current_spend: number;
  previous_spend: number;
  spend_delta_pct: number | null;
  current_conversions: number;
  previous_conversions: number;
  conversions_delta_pct: number | null;
  current_roas: number | null;
  previous_roas: number | null;
  roas_delta_pct: number | null;
}

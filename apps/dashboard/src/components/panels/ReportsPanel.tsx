import { useState, useMemo } from 'react';
import { BarChart3, ArrowUpRight, ArrowDownRight, Minus } from 'lucide-react';
import { useTenant } from '@/hooks/useTenant';
import { useBigQuery } from '@/hooks/useBigQuery';
import { ExportButton } from '@/components/shared/ExportButton';
import { LoadingSkeleton } from '@/components/shared/LoadingSkeleton';
import { formatCurrency, formatNumber, formatPercent } from '@/lib/utils';
import { DATE_PRESETS } from '@/lib/constants';
import type { ComparisonRow } from '@/types/metrics';

function DeltaBadge({ value }: { value: number | null }) {
  if (value === null) return <span className="text-gray-400">—</span>;
  const isPositive = value > 0;
  const isNeutral = Math.abs(value) < 0.5;

  if (isNeutral) {
    return (
      <span className="inline-flex items-center gap-0.5 text-xs text-gray-500">
        <Minus size={12} />
        0%
      </span>
    );
  }

  return (
    <span className={`inline-flex items-center gap-0.5 text-xs font-medium ${isPositive ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
      {isPositive ? <ArrowUpRight size={12} /> : <ArrowDownRight size={12} />}
      {formatPercent(value)}
    </span>
  );
}

export function ReportsPanel() {
  const tenant = useTenant();
  const [days, setDays] = useState(30);
  const [compareEnabled, setCompareEnabled] = useState(true);

  const { data: comparisonData, isLoading } = useBigQuery<ComparisonRow[]>({
    queryName: 'channel_comparison',
    params: { days, compare: compareEnabled },
    enabled: true,
  });

  const rows = comparisonData ?? [];

  const totals = useMemo(() => {
    if (rows.length === 0) return null;
    const cur_spend = rows.reduce((s, r) => s + r.current_spend, 0);
    const prev_spend = rows.reduce((s, r) => s + r.previous_spend, 0);
    const cur_conv = rows.reduce((s, r) => s + r.current_conversions, 0);
    const prev_conv = rows.reduce((s, r) => s + r.previous_conversions, 0);

    return {
      current_spend: cur_spend,
      previous_spend: prev_spend,
      spend_delta: prev_spend ? ((cur_spend - prev_spend) / Math.abs(prev_spend)) * 100 : null,
      current_conversions: cur_conv,
      previous_conversions: prev_conv,
      conversions_delta: prev_conv ? ((cur_conv - prev_conv) / Math.abs(prev_conv)) * 100 : null,
    };
  }, [rows]);

  const exportColumns = [
    { key: 'channel', label: 'Channel' },
    { key: 'current_spend', label: `Spend (${days}d)` },
    { key: 'previous_spend', label: `Spend (prev ${days}d)` },
    { key: 'spend_delta_pct', label: 'Spend Delta %' },
    { key: 'current_conversions', label: `Conv (${days}d)` },
    { key: 'previous_conversions', label: `Conv (prev ${days}d)` },
    { key: 'conversions_delta_pct', label: 'Conv Delta %' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 flex items-center gap-2">
          <BarChart3 size={20} />
          Period Comparison
        </h2>

        <div className="flex items-center gap-3">
          {/* Date range presets */}
          <div className="flex rounded-md border border-gray-300 dark:border-gray-600 overflow-hidden">
            {DATE_PRESETS.map(preset => (
              <button
                key={preset.value}
                onClick={() => setDays(preset.value)}
                className={`px-3 py-1.5 text-xs font-medium transition-colors ${
                  days === preset.value
                    ? 'bg-blue-600 text-white'
                    : 'bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700'
                }`}
              >
                {preset.label}
              </button>
            ))}
          </div>

          {/* Compare toggle */}
          <label className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 cursor-pointer">
            <input
              type="checkbox"
              checked={compareEnabled}
              onChange={e => setCompareEnabled(e.target.checked)}
              className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            Compare
          </label>

          <ExportButton data={rows} filename={`${tenant.slug}-report-${days}d`} columns={exportColumns} />
        </div>
      </div>

      {/* Summary KPIs */}
      {totals && compareEnabled && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <SummaryCard label="Current Spend" value={formatCurrency(totals.current_spend)} delta={totals.spend_delta} />
          <SummaryCard label="Previous Spend" value={formatCurrency(totals.previous_spend)} />
          <SummaryCard label="Current Conv." value={formatNumber(totals.current_conversions)} delta={totals.conversions_delta} />
          <SummaryCard label="Previous Conv." value={formatNumber(totals.previous_conversions)} />
        </div>
      )}

      {/* Comparison Table */}
      {isLoading ? (
        <LoadingSkeleton type="chart" />
      ) : rows.length === 0 ? (
        <div className="text-center py-12 text-gray-500 dark:text-gray-400">
          No data available for this period.
        </div>
      ) : (
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-200 dark:border-gray-700">
                <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Channel</th>
                <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Spend ({days}d)</th>
                {compareEnabled && (
                  <>
                    <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Prev Spend</th>
                    <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Delta</th>
                  </>
                )}
                <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Conv ({days}d)</th>
                {compareEnabled && (
                  <>
                    <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Prev Conv</th>
                    <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Delta</th>
                  </>
                )}
                <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">ROAS</th>
                {compareEnabled && (
                  <th className="text-right px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Delta</th>
                )}
              </tr>
            </thead>
            <tbody>
              {rows.map(row => (
                <tr key={row.channel} className="border-b border-gray-100 dark:border-gray-700/50 hover:bg-gray-50 dark:hover:bg-gray-700/30">
                  <td className="px-4 py-3 font-medium text-gray-900 dark:text-gray-100 capitalize">
                    {row.channel.replace(/_/g, ' ')}
                  </td>
                  <td className="px-4 py-3 text-right text-gray-900 dark:text-gray-100">
                    {formatCurrency(row.current_spend)}
                  </td>
                  {compareEnabled && (
                    <>
                      <td className="px-4 py-3 text-right text-gray-500 dark:text-gray-400">
                        {formatCurrency(row.previous_spend)}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <DeltaBadge value={row.spend_delta_pct} />
                      </td>
                    </>
                  )}
                  <td className="px-4 py-3 text-right text-gray-900 dark:text-gray-100">
                    {formatNumber(row.current_conversions)}
                  </td>
                  {compareEnabled && (
                    <>
                      <td className="px-4 py-3 text-right text-gray-500 dark:text-gray-400">
                        {formatNumber(row.previous_conversions)}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <DeltaBadge value={row.conversions_delta_pct} />
                      </td>
                    </>
                  )}
                  <td className="px-4 py-3 text-right text-gray-900 dark:text-gray-100">
                    {row.current_roas !== null ? row.current_roas.toFixed(2) + 'x' : '—'}
                  </td>
                  {compareEnabled && (
                    <td className="px-4 py-3 text-right">
                      <DeltaBadge value={row.roas_delta_pct} />
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function SummaryCard({ label, value, delta }: { label: string; value: string; delta?: number | null }) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">{label}</p>
      <p className="text-xl font-bold text-gray-900 dark:text-gray-100">{value}</p>
      {delta !== undefined && <DeltaBadge value={delta ?? null} />}
    </div>
  );
}

import { useState } from 'react';
import { Download, FileSpreadsheet, FileText } from 'lucide-react';
import { useTenant } from '@/hooks/useTenant';
import { formatDate } from '@/lib/utils';

interface ExportableRow {
  [key: string]: string | number | null | undefined;
}

interface ExportButtonProps {
  data: ExportableRow[];
  filename?: string;
  columns?: { key: string; label: string }[];
}

function toCsv(data: ExportableRow[], columns?: { key: string; label: string }[]): string {
  if (data.length === 0) return '';

  const cols = columns ?? Object.keys(data[0]).map(key => ({ key, label: key }));
  const header = cols.map(c => `"${c.label}"`).join(',');
  const rows = data.map(row =>
    cols.map(c => {
      const val = row[c.key];
      if (val === null || val === undefined) return '';
      if (typeof val === 'string') return `"${val.replace(/"/g, '""')}"`;
      return String(val);
    }).join(',')
  );

  return [header, ...rows].join('\n');
}

function downloadBlob(content: string, filename: string, type: string) {
  const blob = new Blob([content], { type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function generatePrintHtml(data: ExportableRow[], tenant: { branding: { product_name: string; logo_url: string | null; primary_color: string } }, columns?: { key: string; label: string }[]): string {
  const cols = columns ?? Object.keys(data[0] ?? {}).map(key => ({ key, label: key }));
  const today = formatDate(new Date());

  const headerRows = data.map(row =>
    `<tr>${cols.map(c => `<td style="padding:6px 10px;border-bottom:1px solid #e5e7eb;font-size:13px">${row[c.key] ?? ''}</td>`).join('')}</tr>`
  ).join('');

  return `<!DOCTYPE html>
<html><head><title>${tenant.branding.product_name} Report</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; color: #111 }
  @media print { body { margin: 20px } }
  table { border-collapse: collapse; width: 100% }
  th { text-align: left; padding: 8px 10px; border-bottom: 2px solid ${tenant.branding.primary_color}; font-size: 13px; color: #374151 }
</style>
</head><body>
<div style="display:flex;align-items:center;gap:12px;margin-bottom:24px">
  ${tenant.branding.logo_url ? `<img src="${tenant.branding.logo_url}" height="32"/>` : ''}
  <div>
    <div style="font-size:18px;font-weight:700;color:${tenant.branding.primary_color}">${tenant.branding.product_name}</div>
    <div style="font-size:12px;color:#6b7280">Report — ${today}</div>
  </div>
</div>
<table><thead><tr>${cols.map(c => `<th>${c.label}</th>`).join('')}</tr></thead><tbody>${headerRows}</tbody></table>
</body></html>`;
}

export function ExportButton({ data, filename = 'report', columns }: ExportButtonProps) {
  const tenant = useTenant();
  const [open, setOpen] = useState(false);

  const handleCsv = () => {
    const csv = toCsv(data, columns);
    downloadBlob(csv, `${filename}.csv`, 'text/csv;charset=utf-8');
    setOpen(false);
  };

  const handlePdf = () => {
    const html = generatePrintHtml(data, tenant, columns);
    const win = window.open('', '_blank');
    if (win) {
      win.document.write(html);
      win.document.close();
      setTimeout(() => {
        win.print();
      }, 250);
    }
    setOpen(false);
  };

  if (data.length === 0) return null;

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="inline-flex items-center gap-2 px-3 py-2 rounded-md border border-gray-300 dark:border-gray-600 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
      >
        <Download size={16} />
        Export
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setOpen(false)} />
          <div className="absolute right-0 top-full mt-1 z-20 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg py-1 min-w-[140px]">
            <button
              onClick={handleCsv}
              className="w-full px-3 py-2 text-left text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 flex items-center gap-2"
            >
              <FileSpreadsheet size={14} />
              CSV
            </button>
            <button
              onClick={handlePdf}
              className="w-full px-3 py-2 text-left text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 flex items-center gap-2"
            >
              <FileText size={14} />
              PDF (Print)
            </button>
          </div>
        </>
      )}
    </div>
  );
}

import { FileText } from 'lucide-react';
import { ReportsPanel } from '@/components/panels/ReportsPanel';

export function ReportsPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2">
        <FileText size={24} />
        Reports
      </h1>
      <ReportsPanel />
    </div>
  );
}

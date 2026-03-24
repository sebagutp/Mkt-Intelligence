import { LayoutDashboard } from 'lucide-react';

export function DashboardPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2">
        <LayoutDashboard size={24} />
        Overview
      </h1>
      <p className="text-gray-500 dark:text-gray-400">
        Dashboard panels will be implemented in HU-008.
      </p>
    </div>
  );
}

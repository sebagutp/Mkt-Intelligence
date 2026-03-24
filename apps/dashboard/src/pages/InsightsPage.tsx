import { Lightbulb } from 'lucide-react';

export function InsightsPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2">
        <Lightbulb size={24} />
        Insights
      </h1>
      <p className="text-gray-500 dark:text-gray-400">
        Insights panels will be implemented in a future sprint.
      </p>
    </div>
  );
}

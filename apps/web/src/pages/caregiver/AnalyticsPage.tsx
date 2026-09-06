import { useOutletContext } from "react-router-dom";

export default function AnalyticsPage() {
    const { selectedPatient } = useOutletContext<{ selectedPatient: string }>();

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-gray-900">Cognitive Engagement Trends</h1>
                <p className="text-sm text-gray-500">
                    Assistive engagement metrics, reaction times, and routine adherence.
                </p>
            </div>

            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm text-center py-12 text-gray-500">
                Cognitive progress and game performance trends for: {selectedPatient || "No patient selected"}
            </div>
        </div>
    );
}

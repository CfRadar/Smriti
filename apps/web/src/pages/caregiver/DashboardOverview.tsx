import { useOutletContext } from "react-router-dom";

export default function DashboardOverview() {
    const { selectedPatient } = useOutletContext<{ selectedPatient: string }>();

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-gray-900">Patient Overview</h1>
                <p className="text-sm text-gray-500">
                    Active Patient ID: {selectedPatient || "None selected"}
                </p>
            </div>

            {/* Quick Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                    <p className="text-sm font-medium text-gray-500">Today's Reminders</p>
                    <p className="text-3xl font-bold text-gray-900 mt-2">-- / --</p>
                    <span className="text-xs text-green-600 font-medium">Compliance rate</span>
                </div>

                <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                    <p className="text-sm font-medium text-gray-500">Cognitive Engagement</p>
                    <p className="text-3xl font-bold text-gray-900 mt-2">Active</p>
                    <span className="text-xs text-blue-600 font-medium">Attention & Recall</span>
                </div>

                <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                    <p className="text-sm font-medium text-gray-500">Last Sync Time</p>
                    <p className="text-3xl font-bold text-gray-900 mt-2">Today</p>
                    <span className="text-xs text-gray-500">Offline changes applied</span>
                </div>
            </div>
        </div>
    );
}

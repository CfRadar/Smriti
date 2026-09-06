import { useOutletContext } from "react-router-dom";

export default function RemindersPage() {
    const { selectedPatient } = useOutletContext<{ selectedPatient: string }>();

    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Reminders & Routine</h1>
                    <p className="text-sm text-gray-500">Schedule medication, hydration, and daily tasks.</p>
                </div>
                <button className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700">
                    + New Reminder
                </button>
            </div>

            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm text-center py-12 text-gray-500">
                Reminders list for patient: {selectedPatient || "No patient selected"}
            </div>
        </div>
    );
}

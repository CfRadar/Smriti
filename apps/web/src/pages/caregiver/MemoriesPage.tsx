import { useOutletContext } from "react-router-dom";

export default function MemoriesPage() {
    const { selectedPatient } = useOutletContext<{ selectedPatient: string }>();

    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Family Memories</h1>
                    <p className="text-sm text-gray-500">Upload photos and prompts for reminiscence therapy.</p>
                </div>
                <button className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700">
                    + Upload Photo
                </button>
            </div>

            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm text-center py-12 text-gray-500">
                Photo gallery for patient: {selectedPatient || "No patient selected"}
            </div>
        </div>
    );
}

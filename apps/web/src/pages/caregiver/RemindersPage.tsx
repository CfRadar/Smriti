import React, { useEffect, useState } from "react";
import { useOutletContext } from "react-router-dom";
import {
  Bell,
  Plus,
  Trash2,
  CheckCircle2,
  Clock,
  Volume2,
  Pill,
  Droplets,
  Utensils,
  Calendar,
  Activity,
  X,
  AlertCircle
} from "lucide-react";
import { api } from "../../services/api";

interface ReminderItem {
  _id: string;
  title: string;
  description?: string;
  type: "medication" | "meal" | "hydration" | "activity" | "appointment" | "custom";
  scheduledTime: string;
  repeat?: string;
  isVoicePromptEnabled?: boolean;
  voicePromptText?: string;
  status: "pending" | "acknowledged" | "missed" | "snoozed";
}

export default function RemindersPage() {
  const { selectedPatient, patients } = useOutletContext<{
    selectedPatient: string;
    patients: Array<{ _id: string; name?: string; userId?: { name: string } }>;
  }>();

  const [reminders, setReminders] = useState<ReminderItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [activeTab, setActiveTab] = useState<string>("all");
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Form State
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [type, setType] = useState<ReminderItem["type"]>("medication");
  const [time, setTime] = useState("08:30");
  const [repeat, setRepeat] = useState("daily");
  const [voiceEnabled, setVoiceEnabled] = useState(true);
  const [voicePromptText, setVoicePromptText] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const currentPatient = patients?.find(
    (p) => (p._id || (p as unknown as { id: string }).id) === selectedPatient
  );
  const patientName = currentPatient?.userId?.name || currentPatient?.name || "Patient";

  useEffect(() => {
    if (!selectedPatient) return;
    loadReminders(selectedPatient);
  }, [selectedPatient]);

  const loadReminders = async (patientId: string) => {
    setLoading(true);
    setError("");
    try {
      const data = await api.get(`/reminders/${patientId}`);
      setReminders(Array.isArray(data) ? data : []);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to load reminders";
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleToggleStatus = async (reminder: ReminderItem) => {
    const nextStatus = reminder.status === "acknowledged" ? "pending" : "acknowledged";
    try {
      await api.patch(`/reminders/${reminder._id}/status`, { status: nextStatus });
      setReminders((prev) =>
        prev.map((r) => (r._id === reminder._id ? { ...r, status: nextStatus } : r))
      );
    } catch (err) {
      console.error("Failed to update status:", err);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm("Are you sure you want to remove this reminder?")) return;
    try {
      await api.delete(`/reminders/${id}`);
      setReminders((prev) => prev.filter((r) => r._id !== id));
    } catch (err) {
      console.error("Failed to delete reminder:", err);
    }
  };

  const handleCreateReminder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !selectedPatient) return;

    setSubmitting(true);
    try {
      // Build ISO time for today at the selected time
      const [hours, minutes] = time.split(":").map(Number);
      const scheduledDate = new Date();
      scheduledDate.setHours(hours || 0, minutes || 0, 0, 0);

      const payload = {
        patientId: selectedPatient,
        title: title.trim(),
        description: description.trim(),
        type,
        scheduledTime: scheduledDate.toISOString(),
        repeat,
        isVoicePromptEnabled: voiceEnabled,
        voicePromptText: voicePromptText.trim() || `Time for your ${title}.`,
      };

      const newReminder = await api.post("/reminders", payload);
      if (newReminder) {
        setReminders((prev) => [newReminder, ...prev]);
      }
      setIsModalOpen(false);
      resetForm();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to create reminder";
      alert(msg);
    } finally {
      setSubmitting(false);
    }
  };

  const resetForm = () => {
    setTitle("");
    setDescription("");
    setType("medication");
    setTime("08:30");
    setRepeat("daily");
    setVoiceEnabled(true);
    setVoicePromptText("");
  };

  const getTypeIcon = (itemType: string) => {
    switch (itemType) {
      case "medication":
        return <Pill size={18} className="text-red-500" />;
      case "hydration":
        return <Droplets size={18} className="text-blue-500" />;
      case "meal":
        return <Utensils size={18} className="text-amber-500" />;
      case "appointment":
        return <Calendar size={18} className="text-indigo-500" />;
      default:
        return <Activity size={18} className="text-green-500" />;
    }
  };

  const filteredReminders = reminders.filter((r) => {
    if (activeTab === "all") return true;
    return r.type === activeTab;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Reminders & Routine</h1>
          <p className="text-sm text-gray-500 mt-1">
            Schedule medication, hydration, and daily care tasks with voice guidance for {patientName}.
          </p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-medium shadow-sm transition"
        >
          <Plus size={18} />
          <span>New Reminder</span>
        </button>
      </div>

      {error && (
        <div className="p-4 rounded-xl bg-red-50 border border-red-200 text-red-700 text-sm flex items-center gap-2">
          <AlertCircle size={18} />
          <span>{error}</span>
        </div>
      )}

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 border-b border-gray-200">
        {[
          { id: "all", label: "All Types" },
          { id: "medication", label: "Medication" },
          { id: "hydration", label: "Hydration" },
          { id: "meal", label: "Meals" },
          { id: "activity", label: "Activities" },
          { id: "appointment", label: "Appointments" },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`px-3.5 py-2 text-xs font-semibold rounded-lg transition whitespace-nowrap ${
              activeTab === tab.id
                ? "bg-indigo-600 text-white shadow-sm"
                : "text-gray-600 hover:bg-gray-100"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Reminders List */}
      {loading ? (
        <div className="bg-white rounded-2xl border border-gray-200 p-12 text-center text-sm text-gray-400">
          Loading routine schedule...
        </div>
      ) : filteredReminders.length === 0 ? (
        <div className="bg-white rounded-2xl border border-dashed border-gray-300 p-12 text-center">
          <div className="w-12 h-12 bg-indigo-50 text-indigo-600 rounded-xl flex items-center justify-center mx-auto mb-3">
            <Bell size={24} />
          </div>
          <h3 className="text-base font-semibold text-gray-900">No reminders in this category</h3>
          <p className="text-xs text-gray-500 mt-1 max-w-sm mx-auto">
            Add medication times, water alerts, or lunch reminders to keep routine structured for dementia care.
          </p>
          <button
            onClick={() => setIsModalOpen(true)}
            className="mt-4 px-4 py-2 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 rounded-lg text-xs font-medium transition"
          >
            + Create First Reminder
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredReminders.map((reminder) => {
            const isAck = reminder.status === "acknowledged";
            const timeStr = reminder.scheduledTime
              ? new Date(reminder.scheduledTime).toLocaleTimeString([], {
                  hour: "2-digit",
                  minute: "2-digit",
                })
              : "Set time";

            return (
              <div
                key={reminder._id}
                className={`bg-white rounded-2xl border p-5 transition flex flex-col justify-between ${
                  isAck
                    ? "border-gray-200 bg-gray-50/70 opacity-80"
                    : "border-gray-200 hover:border-indigo-200 hover:shadow-md"
                }`}
              >
                <div>
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-2.5">
                      <div className="p-2 rounded-xl bg-gray-50 border border-gray-100">
                        {getTypeIcon(reminder.type)}
                      </div>
                      <div>
                        <h3 className={`text-base font-semibold ${isAck ? "line-through text-gray-400" : "text-gray-900"}`}>
                          {reminder.title}
                        </h3>
                        <div className="flex items-center gap-2 mt-0.5 text-xs text-gray-500">
                          <span className="capitalize font-medium text-gray-700">{reminder.type}</span>
                          <span>•</span>
                          <span className="capitalize">{reminder.repeat || "Daily"}</span>
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={() => handleDelete(reminder._id)}
                      className="text-gray-400 hover:text-red-600 p-1 rounded-lg hover:bg-red-50 transition"
                      title="Delete reminder"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>

                  {reminder.description && (
                    <p className="mt-3 text-xs text-gray-600 leading-relaxed bg-gray-50/50 p-2 rounded-lg border border-gray-100">
                      {reminder.description}
                    </p>
                  )}
                </div>

                <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between">
                  <div className="flex items-center gap-3 text-xs text-gray-500">
                    <div className="flex items-center gap-1 font-medium text-gray-700">
                      <Clock size={14} className="text-gray-400" />
                      <span>{timeStr}</span>
                    </div>
                    {reminder.isVoicePromptEnabled && (
                      <div className="flex items-center gap-1 text-indigo-600 font-medium" title={reminder.voicePromptText || "Voice prompt active"}>
                        <Volume2 size={14} />
                        <span>Voice</span>
                      </div>
                    )}
                  </div>

                  <button
                    onClick={() => handleToggleStatus(reminder)}
                    className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
                      isAck
                        ? "bg-green-100 text-green-800 hover:bg-green-200"
                        : "bg-gray-100 text-gray-700 hover:bg-indigo-50 hover:text-indigo-600"
                    }`}
                  >
                    <CheckCircle2 size={14} />
                    <span>{isAck ? "Completed" : "Mark Done"}</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Modal: Create Reminder */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-gray-100 animate-fadeIn">
            <div className="flex items-center justify-between pb-4 border-b border-gray-100">
              <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                <Bell size={20} className="text-indigo-600" />
                Add Daily Reminder
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-gray-400 hover:text-gray-600 p-1 rounded-lg"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleCreateReminder} className="mt-4 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                  Reminder Title *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Morning Donepezil & Water"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                    Category
                  </label>
                  <select
                    value={type}
                    onChange={(e) => setType(e.target.value as ReminderItem["type"])}
                    className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-white"
                  >
                    <option value="medication">Medication</option>
                    <option value="hydration">Hydration</option>
                    <option value="meal">Meal</option>
                    <option value="activity">Activity / Walk</option>
                    <option value="appointment">Doctor Appointment</option>
                    <option value="custom">Custom</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                    Scheduled Time
                  </label>
                  <input
                    type="time"
                    required
                    value={time}
                    onChange={(e) => setTime(e.target.value)}
                    className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                  Frequency
                </label>
                <select
                  value={repeat}
                  onChange={(e) => setRepeat(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-white"
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="none">One-time</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1">
                  Instructions / Dosage Note
                </label>
                <textarea
                  rows={2}
                  placeholder="e.g. 1 tablet after breakfast with full glass of water."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full px-3.5 py-2 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none resize-none"
                />
              </div>

              {/* Voice Prompt Option */}
              <div className="p-3.5 rounded-xl bg-indigo-50/60 border border-indigo-100 space-y-2">
                <div className="flex items-center justify-between">
                  <label className="flex items-center gap-2 text-xs font-semibold text-indigo-900 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={voiceEnabled}
                      onChange={(e) => setVoiceEnabled(e.target.checked)}
                      className="rounded text-indigo-600 focus:ring-indigo-500"
                    />
                    Enable Smriti Voice Prompt for Patient
                  </label>
                  <Volume2 size={16} className="text-indigo-600" />
                </div>
                {voiceEnabled && (
                  <input
                    type="text"
                    placeholder="Custom spoken prompt (e.g., Namaste, please take your morning tablet)"
                    value={voicePromptText}
                    onChange={(e) => setVoicePromptText(e.target.value)}
                    className="w-full px-3 py-1.5 bg-white border border-indigo-200 rounded-lg text-xs focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                )}
              </div>

              <div className="pt-3 border-t border-gray-100 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-xl transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-medium transition shadow-sm disabled:opacity-50"
                >
                  {submitting ? "Saving..." : "Save Reminder"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

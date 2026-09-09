import React, { useEffect, useState } from "react";
import { useOutletContext } from "react-router-dom";
import { api } from "../../services/api";

interface PatientContext {
  selectedPatient: string;
  patients: Array<{
    _id: string;
    id?: string;
    name?: string;
    userId?: { name: string };
  }>;
}

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
  const { selectedPatient, patients } = useOutletContext<PatientContext>();

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
    (p) => (p._id || p.id) === selectedPatient
  );
  const patientName =
    currentPatient?.userId?.name || currentPatient?.name || "Shri Biren Bora";

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
        return "medication";
      case "hydration":
        return "water_drop";
      case "meal":
        return "restaurant";
      case "appointment":
        return "calendar_month";
      default:
        return "fitness_center";
    }
  };

  const filteredReminders = reminders.filter((r) => {
    if (activeTab === "all") return true;
    return r.type === activeTab;
  });

  return (
    <div className="w-full max-w-[1600px] mx-auto p-6 md:p-8 space-y-6">
      {/* Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-[#8b716a] text-[11px] font-bold tracking-widest uppercase font-literata">
            <span>Assistive Clinical Routine</span>
            <span>/</span>
            <span className="text-primary font-bold">Daily Reminders</span>
          </div>
          <h1 className="text-[34px] font-bold text-[#2b160e] tracking-tight mt-1 font-newsreader">
            Reminders &amp; Daily Routine
          </h1>
          <p className="text-[15px] text-[#6e5449] font-literata">
            Schedule medication, hydration, meals, and walks with regional voice guidance for {patientName}.
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <button
            onClick={() => setIsModalOpen(true)}
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-[20px_24px_16px_22px] bg-gradient-to-r from-[#b84b25] to-[#c85a32] text-white text-[13px] font-bold hover:from-[#a03d1c] hover:to-[#b84b25] tactile-clay-btn"
          >
            <span className="material-symbols-outlined text-[18px]">add</span>
            <span>New Reminder</span>
          </button>
        </div>
      </div>

      {error && (
        <div className="p-4 rounded-[16px_12px_14px_10px] bg-[#ffdad6] border border-[#ba1a1a]/30 text-[#93000a] text-sm flex items-center gap-2 font-medium">
          <span className="material-symbols-outlined text-[18px]">warning</span>
          <span>{error}</span>
        </div>
      )}

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 border-b border-[#dfcfc0]/70">
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
            className={`px-4 py-2 text-xs font-bold rounded-[16px_12px_14px_10px] transition-all whitespace-nowrap ${
              activeTab === tab.id
                ? "bg-[#c85a32] text-white shadow-xs"
                : "text-[#6e5449] hover:bg-[#f5eee5] hover:text-[#2b160e]"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Reminders List */}
      {loading ? (
        <div className="terracotta-clay-card rounded-[28px] p-12 text-center text-sm text-[#8b716a]">
          Loading routine schedule...
        </div>
      ) : filteredReminders.length === 0 ? (
        <div className="terracotta-clay-card rounded-[28px] p-12 text-center border-dashed border-[#dfcfc0]">
          <div className="w-12 h-12 bg-[#ffede8] text-primary rounded-[16px_12px_14px_10px] flex items-center justify-center mx-auto mb-3">
            <span className="material-symbols-outlined text-[26px]">alarm</span>
          </div>
          <h3 className="text-base font-bold text-[#2b160e] font-newsreader">
            No reminders in this category
          </h3>
          <p className="text-xs text-[#6e5449] mt-1 max-w-sm mx-auto font-literata">
            Add medication times, water alerts, or lunch reminders to keep routine structured for dementia care.
          </p>
          <button
            onClick={() => setIsModalOpen(true)}
            className="mt-4 px-4 py-2 bg-[#f5eee5] hover:bg-[#ebe0d4] text-primary rounded-[14px_10px_12px_8px] text-xs font-bold transition border border-[#dfcfc0]"
          >
            + Create First Reminder
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
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
                className={`terracotta-clay-card rounded-[24px_18px_22px_16px] p-5 flex flex-col justify-between ${
                  isAck ? "opacity-75 bg-[#f5eee5]/50" : ""
                }`}
              >
                <div>
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-2.5">
                      <div className="p-2.5 rounded-[14px_10px_12px_8px] bg-[#f5eee5] text-primary border border-[#dfcfc0]/70">
                        <span className="material-symbols-outlined text-[20px]">
                          {getTypeIcon(reminder.type)}
                        </span>
                      </div>
                      <div>
                        <h3
                          className={`text-[16px] font-bold font-newsreader ${
                            isAck ? "line-through text-[#8b716a]" : "text-[#2b160e]"
                          }`}
                        >
                          {reminder.title}
                        </h3>
                        <div className="flex items-center gap-2 mt-0.5 text-xs text-[#6e5449]">
                          <span className="capitalize font-bold text-secondary">
                            {reminder.type}
                          </span>
                          <span>•</span>
                          <span className="capitalize">{reminder.repeat || "Daily"}</span>
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={() => handleDelete(reminder._id)}
                      className="text-[#8b716a] hover:text-[#ba1a1a] p-1.5 rounded-full hover:bg-[#ffdad6] transition"
                      title="Delete reminder"
                    >
                      <span className="material-symbols-outlined text-[18px]">delete</span>
                    </button>
                  </div>

                  {reminder.description && (
                    <p className="mt-3 text-xs text-[#6e5449] leading-relaxed bg-[#f5eee5]/60 p-2.5 rounded-[12px] border border-[#dfcfc0]/60 font-literata">
                      {reminder.description}
                    </p>
                  )}
                </div>

                <div className="mt-4 pt-3 border-t border-[#dfcfc0]/60 flex items-center justify-between">
                  <div className="flex items-center gap-3 text-xs text-[#6e5449]">
                    <div className="flex items-center gap-1 font-bold text-[#2b160e]">
                      <span className="material-symbols-outlined text-[16px] text-secondary">
                        schedule
                      </span>
                      <span>{timeStr}</span>
                    </div>
                    {reminder.isVoicePromptEnabled && (
                      <div
                        className="flex items-center gap-1 text-primary font-bold"
                        title={reminder.voicePromptText || "Voice prompt active"}
                      >
                        <span className="material-symbols-outlined text-[15px]">volume_up</span>
                        <span>Voice Prompt</span>
                      </div>
                    )}
                  </div>

                  <button
                    onClick={() => handleToggleStatus(reminder)}
                    className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold transition ${
                      isAck
                        ? "bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/30"
                        : "bg-[#ffede8] text-primary border border-primary/20 hover:bg-primary hover:text-white"
                    }`}
                  >
                    <span className="material-symbols-outlined text-[16px]">
                      {isAck ? "check_circle" : "radio_button_unchecked"}
                    </span>
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
          <div className="bg-white rounded-[28px_20px_26px_22px] max-w-lg w-full p-6 shadow-2xl border border-[#dfcfc0]">
            <div className="flex items-center justify-between pb-4 border-b border-[#dfcfc0]/70">
              <h2 className="text-[20px] font-bold text-[#2b160e] font-newsreader flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-[24px]">alarm</span>
                Add Daily Reminder
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-[#8b716a] hover:text-[#2b160e] p-1 rounded-full hover:bg-[#f5eee5]"
              >
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>

            <form onSubmit={handleCreateReminder} className="mt-4 space-y-4 font-literata">
              <div>
                <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                  Reminder Title *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Morning Blood Pressure & Water"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-[#dfcfc0] rounded-[16px_10px_14px_12px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2]"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                    Category
                  </label>
                  <select
                    value={type}
                    onChange={(e) => setType(e.target.value as ReminderItem["type"])}
                    className="w-full px-3.5 py-2.5 border border-[#dfcfc0] rounded-[14px_10px_12px_8px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2]"
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
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                    Scheduled Time
                  </label>
                  <input
                    type="time"
                    required
                    value={time}
                    onChange={(e) => setTime(e.target.value)}
                    className="w-full px-3.5 py-2.5 border border-[#dfcfc0] rounded-[14px_10px_12px_8px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                  Frequency
                </label>
                <select
                  value={repeat}
                  onChange={(e) => setRepeat(e.target.value)}
                  className="w-full px-3.5 py-2.5 border border-[#dfcfc0] rounded-[14px_10px_12px_8px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2]"
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="none">One-time</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1">
                  Instructions / Dosage Note
                </label>
                <textarea
                  rows={2}
                  placeholder="e.g. 1 tablet after breakfast with full glass of water."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full px-3.5 py-2 border border-[#dfcfc0] rounded-[14px_10px_12px_8px] text-sm focus:outline-none focus:border-primary bg-[#fbf7f2] resize-none"
                />
              </div>

              {/* Voice Prompt Option */}
              <div className="p-3.5 rounded-[16px_12px_14px_10px] bg-[#ffede8]/60 border border-primary/20 space-y-2">
                <div className="flex items-center justify-between">
                  <label className="flex items-center gap-2 text-xs font-bold text-[#2b160e] cursor-pointer">
                    <input
                      type="checkbox"
                      checked={voiceEnabled}
                      onChange={(e) => setVoiceEnabled(e.target.checked)}
                      className="rounded text-primary focus:ring-primary"
                    />
                    Enable Smriti Voice Guidance for Patient
                  </label>
                  <span className="material-symbols-outlined text-[18px] text-primary">
                    volume_up
                  </span>
                </div>
                {voiceEnabled && (
                  <input
                    type="text"
                    placeholder="Spoken prompt text (e.g., Namaste, please take your morning tablet)"
                    value={voicePromptText}
                    onChange={(e) => setVoicePromptText(e.target.value)}
                    className="w-full px-3 py-1.5 bg-white border border-[#dfcfc0] rounded-[10px] text-xs focus:outline-none focus:border-primary"
                  />
                )}
              </div>

              <div className="pt-3 border-t border-[#dfcfc0]/70 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 text-sm text-[#6e5449] hover:bg-[#f5eee5] rounded-[14px] transition font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 bg-gradient-to-r from-[#b84b25] to-[#c85a32] text-white rounded-[16px_20px_14px_18px] text-sm font-bold transition shadow-sm disabled:opacity-50 tactile-clay-btn"
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

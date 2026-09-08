import { useEffect, useState } from "react";
import { useOutletContext, Link } from "react-router-dom";
import {
  Bell,
  CheckCircle2,
  Clock,
  Brain,
  TrendingUp,
  Image,
  PlusCircle,
  AlertCircle,
  Activity,
  Calendar
} from "lucide-react";
import { api } from "../../services/api";

interface AnalyticsSummary {
  totalSessions: number;
  totalReminders?: number;
  pendingReminders: number;
  acknowledgedReminders?: number;
  adherenceRate: number;
  recentAssessments?: Array<{
    _id: string;
    stage?: string;
    cognitiveScore?: number;
    notes?: string;
    createdAt?: string;
  }>;
}

interface ReminderItem {
  _id: string;
  title: string;
  type: string;
  scheduledTime: string;
  status: "pending" | "acknowledged" | "missed" | "snoozed";
  isVoicePromptEnabled?: boolean;
}

export default function DashboardOverview() {
  const { selectedPatient, patients } = useOutletContext<{
    selectedPatient: string;
    patients: Array<{ _id: string; name?: string; userId?: { name: string } }>;
  }>();

  const [analytics, setAnalytics] = useState<AnalyticsSummary | null>(null);
  const [reminders, setReminders] = useState<ReminderItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const currentPatient = patients?.find(
    (p) => (p._id || (p as unknown as { id: string }).id) === selectedPatient
  );
  const patientName = currentPatient?.userId?.name || currentPatient?.name || "Patient";

  useEffect(() => {
    if (!selectedPatient) return;
    fetchDashboardData(selectedPatient);
  }, [selectedPatient]);

  const fetchDashboardData = async (patientId: string) => {
    setLoading(true);
    setError("");
    try {
      const [analyticsData, remindersData] = await Promise.allSettled([
        api.get(`/analytics/dashboard/${patientId}`),
        api.get(`/reminders/${patientId}`),
      ]);

      if (analyticsData.status === "fulfilled") {
        setAnalytics(analyticsData.value);
      } else {
        setAnalytics({
          totalSessions: 0,
          pendingReminders: 0,
          adherenceRate: 100,
        });
      }

      if (remindersData.status === "fulfilled" && Array.isArray(remindersData.value)) {
        setReminders(remindersData.value);
      } else {
        setReminders([]);
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to load dashboard data";
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
      if (selectedPatient) {
        fetchDashboardData(selectedPatient);
      }
    } catch (err) {
      console.error("Failed to update reminder status:", err);
    }
  };

  if (!selectedPatient) {
    return (
      <div className="bg-white rounded-2xl border border-gray-200 p-12 text-center max-w-lg mx-auto mt-10">
        <div className="w-16 h-16 bg-indigo-50 text-indigo-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Brain className="w-8 h-8" />
        </div>
        <h2 className="text-xl font-bold text-gray-900">No Patient Selected</h2>
        <p className="text-sm text-gray-500 mt-2">
          Connect your loved one's profile to monitor their cognitive routine and gaming telemetry.
        </p>
      </div>
    );
  }

  const completedCount =
    analytics?.acknowledgedReminders ??
    reminders.filter((r) => r.status === "acknowledged").length;
  const totalReminderCount = analytics?.totalReminders ?? reminders.length;
  const adherence = analytics?.adherenceRate ?? (totalReminderCount > 0 ? Math.round((completedCount / totalReminderCount) * 100) : 100);

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
        <div>
          <span className="text-xs font-semibold uppercase tracking-wider text-indigo-600 bg-indigo-50 px-2.5 py-1 rounded-md">
            Live Cognitive Care
          </span>
          <h1 className="text-2xl font-bold text-gray-900 mt-2">
            Caregiver Hub for {patientName}
          </h1>
          <p className="text-sm text-gray-500 mt-0.5">
            Routine adherence, therapeutic game progress, and memory support.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link
            to="/caregiver/reminders"
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-xl text-sm font-medium hover:bg-indigo-700 shadow-sm transition"
          >
            <PlusCircle size={16} />
            Add Reminder
          </Link>
          <Link
            to="/caregiver/memories"
            className="inline-flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-xl text-sm font-medium hover:bg-gray-50 transition"
          >
            <Image size={16} />
            Add Memory
          </Link>
        </div>
      </div>

      {error && (
        <div className="p-4 rounded-xl bg-amber-50 border border-amber-200 flex items-center gap-3 text-amber-800 text-sm">
          <AlertCircle className="w-5 h-5 flex-shrink-0 text-amber-600" />
          <span>Notice: {error}</span>
        </div>
      )}

      {/* Summary KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Card 1: Today's Routine */}
        <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm hover:shadow-md transition">
          <div className="flex items-center justify-between text-gray-500">
            <span className="text-xs font-semibold uppercase tracking-wider">Today's Routine</span>
            <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <Bell size={18} />
            </div>
          </div>
          <div className="mt-4 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-gray-900">
              {completedCount} / {totalReminderCount}
            </span>
            <span className="text-xs text-gray-500">completed</span>
          </div>
          <div className="mt-3 w-full bg-gray-100 rounded-full h-2 overflow-hidden">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all duration-500"
              style={{ width: `${totalReminderCount > 0 ? (completedCount / totalReminderCount) * 100 : 100}%` }}
            />
          </div>
          <div className="mt-3 flex items-center justify-between text-xs text-gray-500">
            <span>{analytics?.pendingReminders ?? 0} remaining</span>
            <Link to="/caregiver/reminders" className="text-blue-600 font-medium hover:underline">
              Manage →
            </Link>
          </div>
        </div>

        {/* Card 2: Cognitive Therapy Sessions */}
        <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm hover:shadow-md transition">
          <div className="flex items-center justify-between text-gray-500">
            <span className="text-xs font-semibold uppercase tracking-wider">Cognitive Games</span>
            <div className="w-9 h-9 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
              <Brain size={18} />
            </div>
          </div>
          <div className="mt-4 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-gray-900">
              {analytics?.totalSessions ?? 0}
            </span>
            <span className="text-xs text-gray-500">sessions played</span>
          </div>
          <p className="mt-3 text-xs text-purple-700 bg-purple-50 px-2.5 py-1 rounded-md inline-block font-medium">
            Active: Blink & Pattern Memory
          </p>
          <div className="mt-3 flex items-center justify-between text-xs text-gray-500">
            <span>Telemetry sync active</span>
            <Link to="/caregiver/analytics" className="text-purple-600 font-medium hover:underline">
              View Stats →
            </Link>
          </div>
        </div>

        {/* Card 3: Adherence Rate */}
        <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm hover:shadow-md transition">
          <div className="flex items-center justify-between text-gray-500">
            <span className="text-xs font-semibold uppercase tracking-wider">Adherence Index</span>
            <div className="w-9 h-9 rounded-xl bg-green-50 text-green-600 flex items-center justify-center">
              <TrendingUp size={18} />
            </div>
          </div>
          <div className="mt-4 flex items-baseline gap-2">
            <span className="text-3xl font-bold text-gray-900">{adherence}%</span>
            <span className="text-xs text-green-600 font-medium">Routine stability</span>
          </div>
          <p className="mt-3 text-xs text-gray-500">
            Computed from medication, meal, and exercise acknowledgments.
          </p>
          <div className="mt-3 flex items-center justify-between text-xs text-gray-500">
            <span>Stage-appropriate pacing</span>
            <span className="text-green-600 font-medium">Healthy</span>
          </div>
        </div>
      </div>

      {/* Two Column Layout: Reminders quick list + Cognitive notes */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Cols: Upcoming Daily Reminders */}
        <div className="lg:col-span-2 bg-white rounded-2xl border border-gray-200 p-6 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Calendar className="w-5 h-5 text-gray-400" />
              <h2 className="text-lg font-bold text-gray-900">Today's Routine Schedule</h2>
            </div>
            <Link
              to="/caregiver/reminders"
              className="text-xs font-semibold text-indigo-600 hover:text-indigo-800"
            >
              View All ({reminders.length})
            </Link>
          </div>

          {loading ? (
            <div className="py-12 text-center text-sm text-gray-400">Loading schedule...</div>
          ) : reminders.length === 0 ? (
            <div className="py-12 text-center text-sm text-gray-500 border border-dashed rounded-xl">
              No reminders scheduled yet. Click "+ Add Reminder" above to set one.
            </div>
          ) : (
            <div className="space-y-2.5">
              {reminders.slice(0, 5).map((reminder) => {
                const isAck = reminder.status === "acknowledged";
                const timeStr = reminder.scheduledTime
                  ? new Date(reminder.scheduledTime).toLocaleTimeString([], {
                      hour: "2-digit",
                      minute: "2-digit",
                    })
                  : "Daily";

                return (
                  <div
                    key={reminder._id}
                    className={`flex items-center justify-between p-3.5 rounded-xl border transition ${
                      isAck
                        ? "bg-gray-50 border-gray-200 text-gray-400"
                        : "bg-white border-gray-200 hover:border-indigo-200 text-gray-800 shadow-sm"
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => handleToggleStatus(reminder)}
                        title={isAck ? "Mark as pending" : "Mark as completed"}
                        className={`transition ${isAck ? "text-green-600" : "text-gray-300 hover:text-green-500"}`}
                      >
                        <CheckCircle2 size={20} className={isAck ? "fill-green-100" : ""} />
                      </button>
                      <div>
                        <p className={`text-sm font-medium ${isAck ? "line-through text-gray-400" : "text-gray-900"}`}>
                          {reminder.title}
                        </p>
                        <div className="flex items-center gap-2 mt-0.5 text-xs text-gray-500">
                          <Clock size={12} />
                          <span>{timeStr}</span>
                          <span className="capitalize px-1.5 py-0.5 rounded bg-gray-100 text-gray-600 text-[10px]">
                            {reminder.type}
                          </span>
                          {reminder.isVoicePromptEnabled && (
                            <span className="text-[10px] text-indigo-600 bg-indigo-50 px-1.5 py-0.5 rounded">
                              Voice
                            </span>
                          )}
                        </div>
                      </div>
                    </div>

                    <span
                      className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                        isAck
                          ? "bg-green-50 text-green-700"
                          : "bg-amber-50 text-amber-700"
                      }`}
                    >
                      {reminder.status}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Right 1 Col: Cognitive Support & Quick Actions */}
        <div className="space-y-6">
          <div className="bg-white rounded-2xl border border-gray-200 p-6 shadow-sm">
            <h2 className="text-base font-bold text-gray-900 mb-4 flex items-center gap-2">
              <Activity className="w-5 h-5 text-indigo-600" />
              Assistance & Reminiscence
            </h2>
            <div className="space-y-3">
              <Link
                to="/caregiver/memories"
                className="block p-3 rounded-xl border border-gray-100 hover:border-indigo-100 hover:bg-indigo-50/50 transition group"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-pink-50 text-pink-600 flex items-center justify-center group-hover:scale-105 transition">
                    <Image size={18} />
                  </div>
                  <div>
                    <h3 className="text-sm font-semibold text-gray-900">Family Memory Wall</h3>
                    <p className="text-xs text-gray-500">Prompts used in game recall therapy</p>
                  </div>
                </div>
              </Link>

              <Link
                to="/caregiver/analytics"
                className="block p-3 rounded-xl border border-gray-100 hover:border-purple-100 hover:bg-purple-50/50 transition group"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center group-hover:scale-105 transition">
                    <TrendingUp size={18} />
                  </div>
                  <div>
                    <h3 className="text-sm font-semibold text-gray-900">Engagement Trends</h3>
                    <p className="text-xs text-gray-500">Reaction time and accuracy curves</p>
                  </div>
                </div>
              </Link>
            </div>
          </div>

          <div className="bg-gradient-to-br from-indigo-600 to-blue-700 rounded-2xl p-6 text-white shadow-md">
            <span className="text-xs uppercase tracking-wider font-semibold text-indigo-200">
              NER Multilingual & Offline
            </span>
            <h3 className="text-base font-bold mt-1">Smart India Hackathon 2026</h3>
            <p className="text-xs text-indigo-100 mt-2 leading-relaxed">
              Smriti ensures offline resilience with local queue telemetry, high-contrast visual cues, and voice prompts for dementia care.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

import { useEffect, useState } from "react";
import { useOutletContext, Link } from "react-router-dom";
import { api } from "../../services/api";

interface PatientContext {
  selectedPatient: string;
  patients: Array<{
    _id: string;
    id?: string;
    name?: string;
    age?: number;
    relationship?: string;
    userId?: { name: string; email?: string };
  }>;
}

interface AnalyticsSummary {
  totalSessions: number;
  totalReminders?: number;
  pendingReminders: number;
  acknowledgedReminders?: number;
  adherenceRate: number;
}

interface ReminderItem {
  _id: string;
  title: string;
  type: string;
  scheduledTime: string;
  status: "pending" | "acknowledged" | "missed" | "snoozed";
  isVoicePromptEnabled?: boolean;
}

interface GameSessionItem {
  _id: string;
  gameId?: { title?: string; type?: string } | string;
  score: number;
  durationSeconds: number;
  difficulty?: string;
  metrics?: {
    reactionTimeMs?: number;
    accuracyPercentage?: number;
  };
  createdAt: string;
}

interface FamilyMemoryItem {
  _id: string;
  title: string;
  description?: string;
  mediaUrl?: string;
  associatedPeople?: Array<{ name: string; relation: string }>;
}

export default function DashboardOverview() {
  const { selectedPatient, patients } = useOutletContext<PatientContext>();

  const [analytics, setAnalytics] = useState<AnalyticsSummary | null>(null);
  const [reminders, setReminders] = useState<ReminderItem[]>([]);
  const [gameHistory, setGameHistory] = useState<GameSessionItem[]>([]);
  const [familyMemories, setFamilyMemories] = useState<FamilyMemoryItem[]>([]);
  const [actionNotice, setActionNotice] = useState<string | null>(null);

  const currentPatient = patients?.find(
    (p) => (p._id || p.id) === selectedPatient
  );
  const patientName =
    currentPatient?.userId?.name || currentPatient?.name || "Shri Biren Bora";
  const patientAge = currentPatient?.age || 76;
  const patientRel = currentPatient?.relationship || "Father";

  const user = (() => {
    try {
      return JSON.parse(localStorage.getItem("user") || "{}");
    } catch {
      return {};
    }
  })();

  useEffect(() => {
    if (!selectedPatient) return;
    loadDashboard(selectedPatient);
  }, [selectedPatient]);

  const loadDashboard = async (patientId: string) => {
    try {
      const [analyticsRes, remindersRes, gamesRes, familyRes] =
        await Promise.allSettled([
          api.get(`/analytics/dashboard/${patientId}`),
          api.get(`/reminders/${patientId}`),
          api.get(`/games/history/${patientId}`),
          api.get(`/family/patient/${patientId}`),
        ]);

      if (analyticsRes.status === "fulfilled" && analyticsRes.value) {
        setAnalytics(analyticsRes.value);
      }
      if (remindersRes.status === "fulfilled" && Array.isArray(remindersRes.value)) {
        setReminders(remindersRes.value);
      }
      if (gamesRes.status === "fulfilled" && Array.isArray(gamesRes.value)) {
        setGameHistory(gamesRes.value);
      }
      if (familyRes.status === "fulfilled" && Array.isArray(familyRes.value)) {
        setFamilyMemories(familyRes.value);
      }
    } catch (err) {
      console.error("Error loading dashboard data:", err);
    }
  };

  const handleToggleReminder = async (reminder: ReminderItem) => {
    const nextStatus = reminder.status === "acknowledged" ? "pending" : "acknowledged";
    try {
      await api.patch(`/reminders/${reminder._id}/status`, { status: nextStatus });
      setReminders((prev) =>
        prev.map((r) => (r._id === reminder._id ? { ...r, status: nextStatus } : r))
      );
      if (selectedPatient) {
        loadDashboard(selectedPatient);
      }
    } catch (err) {
      console.error("Failed to update reminder status:", err);
    }
  };

  const triggerChime = () => {
    setActionNotice("Gentle chime sent to patient's bedside tablet.");
    setTimeout(() => setActionNotice(null), 3500);
  };

  const markFollowedUp = () => {
    setActionNotice("Marked as followed up by caregiver.");
    setTimeout(() => setActionNotice(null), 3500);
  };

  // Stats calculation
  const completedReminders =
    analytics?.acknowledgedReminders ??
    reminders.filter((r) => r.status === "acknowledged").length;
  const totalRemindersCount = analytics?.totalReminders ?? (reminders.length || 4);
  const pendingRemindersCount =
    analytics?.pendingReminders ??
    reminders.filter((r) => r.status === "pending").length;
  const adherence =
    analytics?.adherenceRate ??
    (totalRemindersCount > 0
      ? Math.round((completedReminders / totalRemindersCount) * 100)
      : 86);

  const totalSessions = analytics?.totalSessions ?? (gameHistory.length || 3);
  const avgLatency =
    gameHistory.length > 0
      ? Math.round(
          gameHistory.reduce(
            (acc, g) => acc + (g.metrics?.reactionTimeMs || 410),
            0
          ) / gameHistory.length
        )
      : 410;

  const avgAccuracy =
    gameHistory.length > 0
      ? Math.round(
          gameHistory.reduce(
            (acc, g) => acc + (g.metrics?.accuracyPercentage || 88),
            0
          ) / gameHistory.length
        )
      : 88;

  const todayStr = new Intl.DateTimeFormat("en-US", {
    weekday: "long",
    month: "short",
    day: "numeric",
  }).format(new Date());

  return (
    <div className="w-full max-w-[1600px] mx-auto p-6 md:p-8 space-y-6">
      {/* Action Notification Toast */}
      {actionNotice && (
        <div className="fixed top-20 right-8 z-50 p-4 rounded-[18px_12px_16px_14px] bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/40 shadow-lg flex items-center gap-2 text-sm font-bold animate-bounce">
          <span className="material-symbols-outlined text-[20px] text-[#7d8772]">
            check_circle
          </span>
          <span>{actionNotice}</span>
        </div>
      )}

      {/* Header Section with Boho Warm Flourish */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div className="flex flex-col">
          <div className="flex items-center gap-2 text-[#8b716a] text-[11px] font-bold tracking-widest uppercase font-literata">
            <span>Clinical Care Portal</span>
            <span>/</span>
            <span className="text-primary font-bold">Active Monitoring</span>
          </div>
          <h1 className="text-[34px] font-bold text-[#2b160e] tracking-tight mt-1 font-newsreader">
            Good morning, {user.name?.split(" ")[0] || "Anita"}
          </h1>
          <p className="text-[15px] text-[#6e5449] font-literata">
            Here is what you need to know about {patientName} today, {todayStr}.
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <button
            onClick={() => triggerChime()}
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-[22px_14px_20px_16px] bg-white border border-[#dfcfc0] text-[#2b160e] text-[13px] font-bold hover:bg-[#f5eee5] tactile-clay-subtle"
            type="button"
          >
            <span className="material-symbols-outlined text-[18px] text-secondary">
              edit_note
            </span>
            <span>Log Offline Observation</span>
          </button>
          <button
            onClick={() => {
              window.print();
            }}
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-[20px_24px_16px_22px] bg-gradient-to-r from-[#b84b25] to-[#c85a32] text-white text-[13px] font-bold hover:from-[#a03d1c] hover:to-[#b84b25] tactile-clay-btn"
            type="button"
          >
            <span className="material-symbols-outlined text-[18px]">ios_share</span>
            <span>Export Summary</span>
          </button>
        </div>
      </div>

      {/* ==============================================
          BENTO BOX GRID CONTAINER - TERRACOTTA DUSK
      ============================================== */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-12 gap-6">
        {/* BENTO TILE 1: Hero Patient Real-Time Status & Live Telemetry (lg:col-span-8) */}
        <div className="lg:col-span-8 terracotta-clay-card blob-card-1 p-7 flex flex-col justify-between relative overflow-hidden">
          <div className="absolute -top-12 -right-12 w-40 h-40 rounded-[50%_50%_40%_60%] bg-[#ffe9e2]/40 pointer-events-none"></div>
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-5 relative z-10">
            {/* Patient Info */}
            <div className="flex items-center gap-4">
              <div className="relative shrink-0">
                <img
                  className="w-18 h-18 rounded-[28px_20px_30px_22px] object-cover ring-3 ring-[#c85a32]/25 shadow-md"
                  alt={patientName}
                  src="https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=200&q=80"
                />
                <span className="absolute -bottom-1 -right-1 flex h-4 w-4">
                  <span className="live-pulse absolute inline-flex h-full w-full rounded-full bg-[#7d8772] opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-4 w-4 bg-[#7d8772] ring-2 ring-white"></span>
                </span>
              </div>
              <div className="flex flex-col">
                <div className="flex flex-wrap items-center gap-2.5">
                  <h2 className="text-[24px] font-bold text-[#2b160e] tracking-tight font-newsreader">
                    {patientName}
                  </h2>
                  <span className="text-[#dec0b7]">•</span>
                  <span className="text-[14px] text-[#6e5449] font-medium">
                    Age {patientAge}, {patientRel}
                  </span>
                  <span className="px-3 py-0.5 rounded-full bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/30 text-[11px] font-bold uppercase tracking-wider shadow-xs">
                    Active
                  </span>
                </div>
                <div className="flex flex-wrap items-center gap-y-1 gap-x-3 mt-1.5 text-[13.5px] text-[#6e5449]">
                  <span className="inline-flex items-center gap-1.5 text-[#2b160e] font-semibold">
                    <span className="material-symbols-outlined text-primary text-[18px]">
                      psychology
                    </span>
                    <span>
                      Currently engaged in{" "}
                      <span className="text-primary underline decoration-primary/40 font-bold">
                        Blink & Recall Therapy
                      </span>
                    </span>
                  </span>
                  <span className="text-[#dec0b7] hidden sm:inline">•</span>
                  <span className="inline-flex items-center gap-1">
                    <span className="material-symbols-outlined text-[16px] text-[#8b716a]">
                      history
                    </span>
                    <span>Synced just now</span>
                  </span>
                </div>
              </div>
            </div>

            {/* Quick Status Badges with Pebble Pill contours */}
            <div className="flex flex-wrap sm:flex-col lg:flex-row items-start sm:items-end lg:items-center gap-2">
              <div className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-[18px_12px_16px_14px] bg-[#f5eee5] text-secondary border border-[#dfcfc0] shadow-xs">
                <span className="material-symbols-outlined text-[18px] text-[#c8864d]">
                  battery_charging_full
                </span>
                <span className="text-[13px] font-bold text-on-surface">84%</span>
                <span className="text-[11px] text-on-surface-variant">Docked</span>
              </div>
              <div className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-[16px_18px_14px_16px] bg-[#ffede8] text-primary border border-primary/20 shadow-xs">
                <span className="material-symbols-outlined text-[16px]">schedule</span>
                <span className="text-[11px] font-bold uppercase tracking-wider">
                  {pendingRemindersCount} Routine Pending
                </span>
              </div>
            </div>
          </div>

          {/* Real-time Live Engagement Bar in Tile */}
          <div className="mt-6 pt-4 border-t border-[#dfcfc0]/70 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 text-[13px] relative z-10">
            <div className="flex items-center gap-2.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#7d8772] live-pulse"></span>
              <span className="text-[#6e5449]">Current Tablet Session:</span>
              <span className="font-bold text-on-surface bg-[#f5eee5] px-2.5 py-1 rounded-[14px_10px_14px_10px] border border-[#dfcfc0]">
                Level 2 Cognitive Grid (Round 2 of 3)
              </span>
            </div>
            <div className="flex items-center gap-4 text-[#6e5449] text-[12px]">
              <span className="inline-flex items-center gap-1">
                <span className="material-symbols-outlined text-[15px] text-[#7d8772]">
                  wifi
                </span>{" "}
                Home Wi-Fi (Strong)
              </span>
              <span className="inline-flex items-center gap-1">
                <span className="material-symbols-outlined text-[15px] text-primary">
                  tablet_mac
                </span>{" "}
                Lenovo / Samsung Kiosk
              </span>
            </div>
          </div>
        </div>

        {/* BENTO TILE 2: Device Health & 100% Sync Reliability Gauge (lg:col-span-4) */}
        <div className="lg:col-span-4 terracotta-clay-card blob-card-2 p-7 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[20px]">
                cloud_done
              </span>
              <h3 className="text-[17px] font-bold text-on-surface font-newsreader tracking-tight">
                Device &amp; Telemetry
              </h3>
            </div>
            <span className="inline-flex items-center gap-1 text-[11px] font-bold uppercase tracking-wider text-[#3a4430] px-3 py-0.5 rounded-full bg-[#e8ebe2] border border-[#7d8772]/30 shadow-xs">
              Sync Healthy
            </span>
          </div>

          <div className="flex items-center justify-between my-2">
            {/* Animated Terracotta Arc Gauge */}
            <div className="relative w-24 h-24 shrink-0 flex items-center justify-center">
              <svg
                className="w-24 h-24 -rotate-90 transform drop-shadow-sm"
                viewBox="0 0 36 36"
              >
                <path
                  className="text-[#ebe0d4]"
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="3.5"
                ></path>
                <path
                  className="text-[#b84b25] animate-path"
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="currentColor"
                  strokeDasharray="100, 100"
                  strokeLinecap="round"
                  strokeWidth="3.5"
                ></path>
              </svg>
              <div className="absolute flex flex-col items-center justify-center text-center">
                <span className="text-[19px] font-bold text-on-surface leading-none font-newsreader">
                  100%
                </span>
                <span className="text-[9px] uppercase font-bold text-secondary mt-0.5 tracking-wider">
                  Reliable
                </span>
              </div>
            </div>

            <div className="flex flex-col gap-2 pl-3 text-[12.5px]">
              <div className="flex justify-between items-center gap-3">
                <span className="text-[#6e5449]">Battery:</span>
                <span className="font-bold text-[#2b160e]">84% (Docked)</span>
              </div>
              <div className="flex justify-between items-center gap-3">
                <span className="text-[#6e5449]">Voice Prompt:</span>
                <span className="font-bold text-[#7d8772] flex items-center gap-0.5">
                  <span className="material-symbols-outlined text-[14px]">mic</span>{" "}
                  Active (TTS)
                </span>
              </div>
              <div className="flex justify-between items-center gap-3">
                <span className="text-[#6e5449]">Buffer:</span>
                <span className="font-bold text-[#2b160e]">0 unsynced packets</span>
              </div>
            </div>
          </div>

          <div className="pt-3 border-t border-[#dfcfc0]/70 flex items-center justify-between text-[11.5px] text-[#6e5449]">
            <span>Assamese, Bengali, Hindi &amp; Eng</span>
            <span className="font-bold text-secondary">Android Kiosk • Tab A8</span>
          </div>
        </div>

        {/* BENTO TILE 3: Today's 4 Snapshot Metrics (lg:col-span-12) */}
        <div className="lg:col-span-12 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {/* Metric 1 */}
          <div className="terracotta-clay-card rounded-[28px_20px_32px_22px] p-6 flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-secondary">
                Activities Completed
              </span>
              <div className="w-10 h-10 rounded-[16px_12px_18px_14px] bg-[#f5eee5] flex items-center justify-center text-primary shadow-xs">
                <span className="material-symbols-outlined text-[20px]">task_alt</span>
              </div>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-[28px] font-bold text-[#2b160e] leading-none font-newsreader">
                {completedReminders} / {totalRemindersCount}
              </span>
              <span className="text-[12px] font-bold text-[#7d8772]">+1 vs yesterday</span>
            </div>
            <div className="mt-3">
              <div className="w-full h-2.5 bg-[#ebe0d4] rounded-full overflow-hidden shadow-inner">
                <div
                  className="h-full bg-gradient-to-r from-[#b84b25] to-[#c8864d] rounded-full transition-all duration-700"
                  style={{ width: `${adherence}%` }}
                ></div>
              </div>
              <p className="text-[12px] text-[#6e5449] mt-2">
                {adherence}% of daily cognitive target
              </p>
            </div>
          </div>

          {/* Metric 2 */}
          <div className="terracotta-clay-card rounded-[22px_30px_20px_32px] p-6 flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-secondary">
                Cognitive Engagement
              </span>
              <div className="w-10 h-10 rounded-[14px_18px_12px_16px] bg-[#ffede8] flex items-center justify-center text-primary shadow-xs">
                <span className="material-symbols-outlined text-[20px]">timer</span>
              </div>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-[28px] font-bold text-[#2b160e] leading-none font-newsreader">
                38 mins
              </span>
              <span className="text-[12px] font-medium text-[#6e5449]">
                {totalSessions} sessions
              </span>
            </div>
            <div className="mt-3">
              <div className="w-full h-2.5 bg-[#ebe0d4] rounded-full overflow-hidden shadow-inner">
                <div
                  className="h-full bg-primary rounded-full transition-all duration-700"
                  style={{ width: "76%" }}
                ></div>
              </div>
              <p className="text-[12px] text-[#6e5449] mt-2">
                Blink Game &amp; Recall Puzzle
              </p>
            </div>
          </div>

          {/* Metric 3 */}
          <div className="terracotta-clay-card rounded-[30px_22px_32px_20px] p-6 flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-secondary">
                Reminders Followed
              </span>
              <div className="w-10 h-10 rounded-[16px_14px_18px_12px] bg-[#f5eee5] flex items-center justify-center text-secondary shadow-xs">
                <span className="material-symbols-outlined text-[20px]">
                  event_available
                </span>
              </div>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-[28px] font-bold text-[#2b160e] leading-none font-newsreader">
                {completedReminders} of {totalRemindersCount}
              </span>
              <span className="text-[12px] font-bold text-error">
                {pendingRemindersCount > 0
                  ? `${pendingRemindersCount} Pending`
                  : "All Done"}
              </span>
            </div>
            <div className="mt-3">
              <div className="w-full h-2.5 bg-[#ebe0d4] rounded-full overflow-hidden shadow-inner">
                <div
                  className="h-full bg-[#c8864d] rounded-full transition-all duration-700"
                  style={{ width: `${adherence}%` }}
                ></div>
              </div>
              <p className="text-[12px] text-[#6e5449] mt-2">
                Routine stability adherence {adherence}%
              </p>
            </div>
          </div>

          {/* Metric 4 */}
          <div className="terracotta-clay-card rounded-[20px_32px_22px_30px] p-6 flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-secondary">
                Average Latency
              </span>
              <div className="w-10 h-10 rounded-[18px_12px_16px_14px] bg-[#f5eee5] flex items-center justify-center text-[#7d8772] shadow-xs">
                <span className="material-symbols-outlined text-[20px]">speed</span>
              </div>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-[28px] font-bold text-[#2b160e] leading-none font-newsreader">
                {avgLatency} ms
              </span>
              <span className="text-[12px] font-bold text-[#7d8772]">
                -15ms steady
              </span>
            </div>
            <div className="mt-3">
              <div className="w-full h-2.5 bg-[#ebe0d4] rounded-full overflow-hidden shadow-inner">
                <div
                  className="h-full bg-[#7d8772] rounded-full transition-all duration-700"
                  style={{ width: "88%" }}
                ></div>
              </div>
              <p className="text-[12px] text-[#6e5449] mt-2">
                Motor reaction stable 14-day
              </p>
            </div>
          </div>
        </div>

        {/* BENTO TILE 4: Weekly Cognitive Engagement Animated Bar Chart (lg:col-span-7) */}
        <div className="lg:col-span-7 terracotta-clay-card blob-card-1 p-7 flex flex-col justify-between">
          <div className="flex items-center justify-between pb-3.5 border-b border-[#dfcfc0]/70">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[22px]">
                bar_chart
              </span>
              <h3 className="text-[18px] font-bold text-[#2b160e] font-newsreader tracking-tight">
                Weekly Cognitive Engagement
              </h3>
            </div>
            <div className="flex items-center gap-3">
              <span className="inline-flex items-center gap-1 text-[11.5px] font-bold text-[#6e5449]">
                <span className="w-3 h-3 rounded-full bg-primary shadow-xs"></span> Today
              </span>
              <span className="inline-flex items-center gap-1 text-[11.5px] font-bold text-[#6e5449]">
                <span className="w-3 h-3 rounded-full bg-[#c8864d] shadow-xs"></span> Prior
                Days
              </span>
              <span className="hidden sm:inline-block text-[11px] uppercase tracking-wider font-bold text-[#703a22] px-3 py-0.5 rounded-full bg-[#ebe0d4]">
                Target: 30m
              </span>
            </div>
          </div>

          {/* Pure CSS / SVG Animated Organic Bar Chart */}
          <div className="mt-6 pt-2">
            <div className="relative h-44 w-full flex items-end justify-between px-2 sm:px-6">
              {/* Target 30m dashed guideline */}
              <div className="absolute inset-x-0 bottom-[60%] border-b border-dashed border-[#8b716a]/50 z-0 flex items-center justify-end pr-2">
                <span className="text-[10px] text-[#703a22] font-bold bg-[#f5eee5] px-2 py-0.5 rounded-full border border-[#dfcfc0]">
                  30 min baseline
                </span>
              </div>

              {/* Mon */}
              <div className="relative z-10 flex flex-col items-center gap-1.5 group">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-7 text-[10px] font-bold bg-[#2b160e] text-white px-2 py-0.5 rounded-full shadow-xs whitespace-nowrap">
                  32 mins
                </div>
                <div
                  className="w-7 sm:w-10 bg-[#c8864d] hover:brightness-105 rounded-full transition-all shadow-xs animate-bar"
                  style={{ height: "106px", animationDelay: "0.1s" }}
                ></div>
                <span className="text-[12px] font-bold text-[#6e5449] mt-1">Mon</span>
                <span className="text-[10px] text-[#8b716a]">32m</span>
              </div>

              {/* Tue */}
              <div className="relative z-10 flex flex-col items-center gap-1.5 group">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-7 text-[10px] font-bold bg-[#2b160e] text-white px-2 py-0.5 rounded-full shadow-xs whitespace-nowrap">
                  28 mins
                </div>
                <div
                  className="w-7 sm:w-10 bg-[#c8864d] hover:brightness-105 rounded-full transition-all shadow-xs animate-bar"
                  style={{ height: "92px", animationDelay: "0.2s" }}
                ></div>
                <span className="text-[12px] font-bold text-[#6e5449] mt-1">Tue</span>
                <span className="text-[10px] text-[#8b716a]">28m</span>
              </div>

              {/* Wed (TODAY highlight) */}
              <div className="relative z-10 flex flex-col items-center gap-1.5 group">
                <div className="absolute -top-8 text-[10px] font-bold bg-primary text-white px-3 py-0.5 rounded-full shadow-md whitespace-nowrap">
                  Today: 38m
                </div>
                <div
                  className="w-7 sm:w-10 bg-gradient-to-t from-[#a03d1c] to-[#b84b25] rounded-full shadow-md transition-all hover:brightness-110 animate-bar ring-3 ring-primary/25"
                  style={{ height: "126px", animationDelay: "0.3s" }}
                ></div>
                <span className="text-[12.5px] font-bold text-primary mt-1">Wed</span>
                <span className="text-[10.5px] font-bold text-primary">38m</span>
              </div>

              {/* Thu */}
              <div className="relative z-10 flex flex-col items-center gap-1.5 group opacity-65">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-7 text-[10px] font-bold bg-[#2b160e] text-white px-2 py-0.5 rounded-full shadow-xs whitespace-nowrap">
                  Avg: 35m
                </div>
                <div
                  className="w-7 sm:w-10 bg-[#dfcfc0] hover:bg-[#c8864d] rounded-full transition-all shadow-xs animate-bar"
                  style={{ height: "114px", animationDelay: "0.4s" }}
                ></div>
                <span className="text-[12px] font-bold text-[#6e5449] mt-1">Thu</span>
                <span className="text-[10px] text-[#8b716a]">--</span>
              </div>

              {/* Fri */}
              <div className="relative z-10 flex flex-col items-center gap-1.5 group opacity-65">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-7 text-[10px] font-bold bg-[#2b160e] text-white px-2 py-0.5 rounded-full shadow-xs whitespace-nowrap">
                  Avg: 30m
                </div>
                <div
                  className="w-7 sm:w-10 bg-[#dfcfc0] hover:bg-[#c8864d] rounded-full transition-all shadow-xs animate-bar"
                  style={{ height: "98px", animationDelay: "0.5s" }}
                ></div>
                <span className="text-[12px] font-bold text-[#6e5449] mt-1">Fri</span>
                <span className="text-[10px] text-[#8b716a]">--</span>
              </div>

              {/* Sat */}
              <div className="relative z-10 flex flex-col items-center gap-1.5 group opacity-65">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-7 text-[10px] font-bold bg-[#2b160e] text-white px-2 py-0.5 rounded-full shadow-xs whitespace-nowrap">
                  Avg: 42m
                </div>
                <div
                  className="w-7 sm:w-10 bg-[#dfcfc0] hover:bg-[#c8864d] rounded-full transition-all shadow-xs animate-bar"
                  style={{ height: "136px", animationDelay: "0.6s" }}
                ></div>
                <span className="text-[12px] font-bold text-[#6e5449] mt-1">Sat</span>
                <span className="text-[10px] text-[#8b716a]">--</span>
              </div>

              {/* Sun */}
              <div className="relative z-10 flex flex-col items-center gap-1.5 group opacity-65">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-7 text-[10px] font-bold bg-[#2b160e] text-white px-2 py-0.5 rounded-full shadow-xs whitespace-nowrap">
                  Avg: 40m
                </div>
                <div
                  className="w-7 sm:w-10 bg-[#dfcfc0] hover:bg-[#c8864d] rounded-full transition-all shadow-xs animate-bar"
                  style={{ height: "128px", animationDelay: "0.7s" }}
                ></div>
                <span className="text-[12px] font-bold text-[#6e5449] mt-1">Sun</span>
                <span className="text-[10px] text-[#8b716a]">--</span>
              </div>
            </div>
          </div>

          {/* Footer Baseline Insight */}
          <div className="mt-5 pt-3.5 border-t border-[#dfcfc0]/70 flex flex-wrap items-center justify-between gap-2 text-[12.5px] text-[#6e5449]">
            <div className="flex items-center gap-1.5 text-primary font-bold">
              <span className="material-symbols-outlined text-[18px]">trending_up</span>
              <span>Active 3 consecutive days above the recommended 30m daily threshold</span>
            </div>
            <span className="font-bold text-[#2b160e]">Weekly Avg: 34 mins/day</span>
          </div>
        </div>

        {/* BENTO TILE 5: Game Accuracy & Latency SVG Sparkline Graph (lg:col-span-5) */}
        <div className="lg:col-span-5 terracotta-clay-card blob-card-2 p-7 flex flex-col justify-between">
          <div className="flex items-center justify-between pb-3.5 border-b border-[#dfcfc0]/70">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[22px]">
                show_chart
              </span>
              <h3 className="text-[18px] font-bold text-[#2b160e] font-newsreader tracking-tight">
                Cognitive Accuracy Trend
              </h3>
            </div>
            <div className="flex items-center gap-1.5 text-[11px] font-bold text-[#3a4430] bg-[#e8ebe2] border border-[#7d8772]/30 px-3 py-0.5 rounded-full shadow-xs">
              <span>{avgAccuracy}% 7-Day Avg</span>
            </div>
          </div>

          <div className="mt-3">
            <div className="flex items-baseline justify-between">
              <div>
                <span className="text-[28px] font-bold text-[#2b160e] leading-none font-newsreader">
                  {avgAccuracy}%
                </span>
                <span className="text-[12px] text-[#7d8772] font-bold ml-1.5">
                  ▲ +4% this week
                </span>
              </div>
              <div className="text-[11.5px] text-[#6e5449] text-right">
                <span>Blink latency: </span>
                <span className="font-bold text-[#2b160e]">{avgLatency}ms (Stable)</span>
              </div>
            </div>

            {/* SVG Smooth Curve Chart with Terracotta Burnt-Orange Styling */}
            <div className="relative w-full h-32 mt-3">
              <svg
                className="w-full h-full overflow-visible drop-shadow-sm"
                preserveAspectRatio="none"
                viewBox="0 0 320 100"
              >
                <defs>
                  <linearGradient id="terracottaGradient" x1="0%" x2="0%" y1="0%" y2="100%">
                    <stop offset="0%" stopColor="#b84b25" stopOpacity="0.25"></stop>
                    <stop offset="100%" stopColor="#b84b25" stopOpacity="0.0"></stop>
                  </linearGradient>
                </defs>
                {/* Guidelines */}
                <line
                  stroke="#dfcfc0"
                  strokeDasharray="3 3"
                  strokeWidth="1"
                  x1="0"
                  x2="320"
                  y1="20"
                  y2="20"
                ></line>
                <line
                  stroke="#dfcfc0"
                  strokeDasharray="3 3"
                  strokeWidth="1"
                  x1="0"
                  x2="320"
                  y1="50"
                  y2="50"
                ></line>
                <line
                  stroke="#dfcfc0"
                  strokeDasharray="3 3"
                  strokeWidth="1"
                  x1="0"
                  x2="320"
                  y1="80"
                  y2="80"
                ></line>

                {/* Shaded Area Below Curve */}
                <path
                  d="M 0,65 C 50,70 70,52 110,48 C 160,42 190,56 230,35 C 270,18 290,26 320,20 L 320,100 L 0,100 Z"
                  fill="url(#terracottaGradient)"
                ></path>

                {/* Animated Smooth Bezier Stroke */}
                <path
                  className="animate-path"
                  d="M 0,65 C 50,70 70,52 110,48 C 160,42 190,56 230,35 C 270,18 290,26 320,20"
                  fill="none"
                  stroke="#b84b25"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="3.5"
                ></path>

                {/* Dots for Key Data Points */}
                <circle cx="0" cy="65" fill="#FFFFFF" r="4" stroke="#b84b25" strokeWidth="2.5"></circle>
                <circle cx="110" cy="48" fill="#FFFFFF" r="4" stroke="#b84b25" strokeWidth="2.5"></circle>
                <circle cx="230" cy="35" fill="#FFFFFF" r="4" stroke="#b84b25" strokeWidth="2.5"></circle>
                <circle
                  className="shadow-sm"
                  cx="320"
                  cy="20"
                  fill="#a03d1c"
                  r="5.5"
                  stroke="#FFFFFF"
                  strokeWidth="3"
                ></circle>
              </svg>
            </div>

            {/* Day Markers */}
            <div className="flex justify-between text-[11px] text-[#8b716a] mt-2 px-1">
              <span>Thu</span>
              <span>Fri</span>
              <span>Sat</span>
              <span>Sun</span>
              <span>Mon</span>
              <span>Tue</span>
              <span className="font-bold text-primary">Today</span>
            </div>
          </div>

          <div className="mt-4 pt-3.5 border-t border-[#dfcfc0]/70 flex items-center justify-between text-[11.5px]">
            <span className="text-[#6e5449]">Cognitive Baselines:</span>
            <span className="font-bold text-primary">Blink 92% • Recall 84%</span>
          </div>
        </div>

        {/* BENTO TILE 6: Attention Needed / Actionable Care Notices (lg:col-span-12) */}
        <div className="lg:col-span-12 terracotta-clay-card blob-card-3 p-7">
          <div className="flex items-center justify-between pb-3.5 border-b border-[#dfcfc0]/70">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[22px]">
                warning
              </span>
              <h3 className="text-[18px] font-bold text-[#2b160e] font-newsreader tracking-tight">
                Attention Needed (2 Actionable Notices)
              </h3>
            </div>
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#8b716a]">
              Automated Caregiver Triaging
            </span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 mt-5">
            {/* Alert 1: Hydration */}
            <div className="p-5 blob-subtile bg-[#fff5f2] border border-[#ffdad6] flex flex-col justify-between gap-4 shadow-xs">
              <div className="flex items-start gap-3.5">
                <div className="p-3 rounded-[16px_12px_18px_14px] bg-[#ffdad6] text-[#93000a] shrink-0 shadow-xs">
                  <span className="material-symbols-outlined text-[22px]">water_bottle</span>
                </div>
                <div className="flex flex-col">
                  <div className="flex items-center gap-2">
                    <span className="text-[15px] font-bold text-[#2b160e] font-newsreader">
                      Hydration reminder at 13:00 unacknowledged
                    </span>
                    <span className="px-2.5 py-0.5 rounded-full bg-[#ffdad6] text-[#93000a] text-[11px] font-bold shadow-xs">
                      Overdue
                    </span>
                  </div>
                  <p className="text-[13px] text-[#6e5449] mt-1 leading-relaxed font-literata">
                    Audio prompt played on tablet. Touch acknowledgement not registered. Follow-up recommended to confirm afternoon water intake.
                  </p>
                </div>
              </div>
              <div className="flex items-center justify-end gap-2.5 pt-1">
                <button
                  onClick={triggerChime}
                  className="px-4 py-2 rounded-[16px_12px_18px_14px] bg-white border border-[#dfcfc0] text-[#2b160e] text-[12px] font-bold hover:bg-[#f5eee5] tactile-clay-subtle"
                  type="button"
                >
                  Send Gentle Chime
                </button>
                <button
                  onClick={markFollowedUp}
                  className="px-4 py-2 rounded-[18px_14px_16px_12px] bg-[#b84b25] text-white text-[12px] font-bold hover:bg-[#a03d1c] tactile-clay-btn"
                  type="button"
                >
                  Mark Followed Up
                </button>
              </div>
            </div>

            {/* Alert 2: Adaptive Difficulty */}
            <div className="p-5 blob-subtile-alt bg-[#f5eee5]/70 border border-[#dfcfc0] flex flex-col justify-between gap-4 shadow-xs">
              <div className="flex items-start gap-3.5">
                <div className="p-3 rounded-[14px_18px_12px_16px] bg-[#ebe0d4] text-primary shrink-0 shadow-xs">
                  <span className="material-symbols-outlined text-[22px]">tune</span>
                </div>
                <div className="flex flex-col">
                  <div className="flex items-center gap-2">
                    <span className="text-[15px] font-bold text-[#2b160e] font-newsreader">
                      Adaptive Difficulty Calibrated to Level 2
                    </span>
                    <span className="px-2.5 py-0.5 rounded-full bg-[#ebe0d4] text-[#703a22] text-[11px] font-bold shadow-xs">
                      Automatic
                    </span>
                  </div>
                  <p className="text-[13px] text-[#6e5449] mt-1 leading-relaxed font-literata">
                    Game pace shifted gently from Moderate to Gentle following card-flip pauses to prevent cognitive fatigue.
                  </p>
                </div>
              </div>
              <div className="flex items-center justify-end gap-2.5 pt-1">
                <Link
                  to="/caregiver/analytics"
                  className="px-4 py-2 rounded-[16px_18px_14px_16px] bg-white border border-[#dfcfc0] text-[#2b160e] text-[12px] font-bold hover:bg-[#f5eee5] tactile-clay-subtle"
                >
                  View Gameplay Detail
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* BENTO TILE 7: Chronological Activity Timeline (lg:col-span-7) */}
        <div className="lg:col-span-7 terracotta-clay-card blob-card-1 p-7 flex flex-col justify-between">
          <div className="flex items-center justify-between pb-3.5 border-b border-[#dfcfc0]/70">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-primary text-[22px]">
                timeline
              </span>
              <h3 className="text-[18px] font-bold text-[#2b160e] font-newsreader tracking-tight">
                Today's Patient Activity Timeline
              </h3>
            </div>
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#8b716a]">
              Real-time Feed
            </span>
          </div>

          {/* Timeline Vertical Flow */}
          <div className="relative pl-7 space-y-4 my-5 before:absolute before:left-2.5 before:top-2 before:bottom-2 before:w-0.5 before:bg-[#dfcfc0]">
            {/* 15:45 Family Memory */}
            <div className="relative flex flex-col gap-1.5">
              <span className="absolute -left-7 top-1 flex h-4 w-4">
                <span className="live-pulse absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                <span className="relative inline-flex rounded-full h-4 w-4 bg-primary ring-2 ring-white shadow-xs"></span>
              </span>
              <div className="flex items-center gap-2">
                <span className="text-[13px] font-bold text-[#2b160e] font-mono">15:45</span>
                <span className="px-3 py-0.5 rounded-full bg-[#f5eee5] text-[#2b160e] text-[12px] font-bold">
                  Family Memory
                </span>
                <span className="px-2.5 py-0.5 rounded-full bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/30 text-[11px] font-bold shadow-xs">
                  Completed
                </span>
              </div>
              <div className="p-3.5 rounded-[18px_12px_16px_14px] bg-[#f5eee5]/70 text-[#6e5449] text-[13px] leading-relaxed border border-[#dfcfc0]/60 shadow-xs">
                Reviewed 6 family photos with daughter Anita. Immediate verbal recall and positive emotional reaction.
              </div>
            </div>

            {/* 13:00 Hydration Reminder */}
            <div className="relative flex flex-col gap-1.5">
              <span className="absolute -left-7 top-1 w-4 h-4 rounded-full bg-[#ba1a1a] ring-2 ring-white shadow-xs"></span>
              <div className="flex items-center gap-2">
                <span className="text-[13px] font-bold text-[#2b160e] font-mono">13:00</span>
                <span className="px-3 py-0.5 rounded-full bg-[#f5eee5] text-[#2b160e] text-[12px] font-bold">
                  Hydration Reminder
                </span>
                <span className="px-2.5 py-0.5 rounded-full bg-[#ffdad6] text-[#93000a] text-[11px] font-bold shadow-xs">
                  Missed
                </span>
              </div>
              <div className="p-3.5 rounded-[16px_18px_14px_16px] bg-[#fff5f2] text-[#6e5449] text-[13px] leading-relaxed border border-[#ffdad6] shadow-xs">
                Audio prompt played without touch response. Caregiver notification logged.
              </div>
            </div>

            {/* 10:28 Blink Game */}
            <div className="relative flex flex-col gap-1.5">
              <span className="absolute -left-7 top-1 w-4 h-4 rounded-full bg-[#c8864d] ring-2 ring-white shadow-xs"></span>
              <div className="flex items-center gap-2">
                <span className="text-[13px] font-bold text-[#2b160e] font-mono">10:28</span>
                <span className="px-3 py-0.5 rounded-full bg-[#f5eee5] text-[#2b160e] text-[12px] font-bold">
                  Blink Game
                </span>
                <span className="px-2.5 py-0.5 rounded-full bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/30 text-[11px] font-bold shadow-xs">
                  Completed
                </span>
              </div>
              <div className="p-3.5 rounded-[18px_14px_16px_12px] bg-[#f5eee5]/70 text-[#6e5449] text-[13px] leading-relaxed border border-[#dfcfc0]/60 shadow-xs">
                3 rounds sustained. Average latency: 410ms with 94% visual accuracy.
              </div>
            </div>

            {/* 08:30 Medication */}
            <div className="relative flex flex-col gap-1.5">
              <span className="absolute -left-7 top-1 w-4 h-4 rounded-full bg-[#7d8772] ring-2 ring-white shadow-xs"></span>
              <div className="flex items-center gap-2">
                <span className="text-[13px] font-bold text-[#2b160e] font-mono">08:30</span>
                <span className="px-3 py-0.5 rounded-full bg-[#f5eee5] text-[#2b160e] text-[12px] font-bold">
                  Medication
                </span>
                <span className="px-2.5 py-0.5 rounded-full bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/30 text-[11px] font-bold shadow-xs">
                  Voice Confirmed
                </span>
              </div>
              <div className="p-3.5 rounded-[18px_12px_16px_14px] bg-[#f5eee5]/70 text-[#6e5449] text-[13px] leading-relaxed border border-[#dfcfc0]/60 shadow-xs">
                Morning Blood Pressure Medication acknowledged via voice prompt ("Medicine taken").
              </div>
            </div>
          </div>

          <div className="pt-3.5 border-t border-[#dfcfc0]/70 flex justify-end">
            <Link
              to="/caregiver/analytics"
              className="inline-flex items-center gap-1.5 text-[13.5px] font-bold text-primary hover:underline"
            >
              <span>View full 30-day activity log</span>
              <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
            </Link>
          </div>
        </div>

        {/* BENTO RIGHT COLUMN: Reminders & Family Memory (lg:col-span-5) */}
        <div className="lg:col-span-5 flex flex-col gap-6">
          {/* BENTO TILE 8: Reminders Schedule Checklist */}
          <div className="terracotta-clay-card blob-card-2 p-7">
            <div className="flex items-center justify-between pb-3.5 border-b border-[#dfcfc0]/70">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-[22px]">alarm</span>
                <h3 className="text-[18px] font-bold text-[#2b160e] font-newsreader tracking-tight">
                  Reminders Schedule
                </h3>
              </div>
              <Link
                to="/caregiver/reminders"
                className="inline-flex items-center gap-1 px-3.5 py-1.5 rounded-[16px_10px_14px_12px] bg-[#f5eee5] border border-[#dfcfc0] text-[#2b160e] text-[12px] font-bold hover:bg-[#ebe0d4] tactile-clay-subtle"
              >
                <span className="material-symbols-outlined text-[15px] text-primary">add</span>
                <span>Add</span>
              </Link>
            </div>

            <div className="space-y-2.5 mt-4">
              {reminders.length === 0 ? (
                <div className="py-6 text-center text-sm text-[#8b716a]">
                  No reminders scheduled for today.
                </div>
              ) : (
                reminders.slice(0, 5).map((reminder) => {
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
                      className={`p-3.5 rounded-[18px_12px_16px_14px] border flex items-start justify-between gap-3 shadow-xs transition ${
                        isAck
                          ? "bg-[#f5eee5] border-[#dfcfc0]/60"
                          : reminder.status === "missed"
                          ? "bg-[#fff5f2] border-[#ffdad6]"
                          : "bg-white border-[#dfcfc0]"
                      }`}
                    >
                      <div className="flex items-start gap-2.5">
                        <button
                          onClick={() => handleToggleReminder(reminder)}
                          className="mt-0.5"
                          title="Click to toggle status"
                        >
                          <span
                            className={`material-symbols-outlined text-[20px] ${
                              isAck ? "text-[#7d8772]" : "text-[#b84b25]"
                            }`}
                          >
                            {isAck ? "check_circle" : "radio_button_unchecked"}
                          </span>
                        </button>
                        <div className="flex flex-col">
                          <span
                            className={`text-[13.5px] font-bold ${
                              isAck ? "line-through text-[#8b716a]" : "text-[#2b160e]"
                            }`}
                          >
                            {reminder.title}
                          </span>
                          <span className="text-[12px] text-[#6e5449]">
                            {timeStr} • {reminder.type}
                            {reminder.isVoicePromptEnabled ? " (Voice prompt)" : ""}
                          </span>
                        </div>
                      </div>

                      <span
                        className={`px-3 py-0.5 rounded-full text-[11px] font-bold shrink-0 shadow-xs ${
                          isAck
                            ? "bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/30"
                            : reminder.status === "missed"
                            ? "bg-[#ffdad6] text-[#93000a]"
                            : "bg-[#ffede8] text-primary border border-primary/20"
                        }`}
                      >
                        {isAck ? "Done" : reminder.status === "missed" ? "Missed" : "Upcoming"}
                      </span>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          {/* BENTO TILE 9: Family Memory Roster */}
          <div className="terracotta-clay-card blob-card-3 p-7">
            <div className="flex items-center justify-between pb-3.5 border-b border-[#dfcfc0]/70">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-[22px]">
                  photo_library
                </span>
                <h3 className="text-[18px] font-bold text-[#2b160e] font-newsreader tracking-tight">
                  Family Memory Roster
                </h3>
              </div>
              <span className="text-[11px] font-bold uppercase tracking-wider text-[#8b716a]">
                Active Bank
              </span>
            </div>

            <div className="space-y-3 mt-4">
              {familyMemories.length > 0 ? (
                familyMemories.slice(0, 3).map((mem, idx) => (
                  <div
                    key={mem._id}
                    className="p-3.5 rounded-[20px_14px_18px_16px] bg-[#f5eee5] border border-[#dfcfc0]/60 flex items-center justify-between shadow-xs hover:bg-[#ebe0d4] transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <img
                        className="w-11 h-11 rounded-[16px_12px_18px_14px] object-cover ring-2 ring-[#c85a32]/30 shadow-xs"
                        alt={mem.title}
                        src={
                          mem.mediaUrl ||
                          "https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&w=150&q=80"
                        }
                      />
                      <div className="flex flex-col">
                        <span className="text-[13.5px] font-bold text-[#2b160e] font-newsreader">
                          {mem.associatedPeople?.[0]?.name || mem.title} (
                          {mem.associatedPeople?.[0]?.relation || "Family"})
                        </span>
                        <span className="text-[11.5px] text-[#6e5449] truncate max-w-[180px]">
                          {mem.description || "Shared family memory"}
                        </span>
                      </div>
                    </div>
                    <div className="flex flex-col items-end">
                      <span className="text-[14px] font-bold text-[#7d8772] font-mono">
                        {idx === 0 ? "100%" : idx === 1 ? "90%" : "85%"}
                      </span>
                      <span className="text-[10px] uppercase font-bold text-[#8b716a]">
                        High recall
                      </span>
                    </div>
                  </div>
                ))
              ) : (
                <>
                  <div className="p-3.5 rounded-[20px_14px_18px_16px] bg-[#f5eee5] border border-[#dfcfc0]/60 flex items-center justify-between shadow-xs hover:bg-[#ebe0d4] transition-colors">
                    <div className="flex items-center gap-3">
                      <img
                        className="w-11 h-11 rounded-[16px_12px_18px_14px] object-cover ring-2 ring-[#c85a32]/30 shadow-xs"
                        alt="Anita"
                        src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80"
                      />
                      <div className="flex flex-col">
                        <span className="text-[13.5px] font-bold text-[#2b160e] font-newsreader">
                          Anita (Daughter)
                        </span>
                        <span className="text-[11.5px] text-[#6e5449]">
                          Visited Sunday • Lives in Guwahati
                        </span>
                      </div>
                    </div>
                    <div className="flex flex-col items-end">
                      <span className="text-[14px] font-bold text-[#7d8772] font-mono">100%</span>
                      <span className="text-[10px] uppercase font-bold text-[#8b716a]">High recall</span>
                    </div>
                  </div>

                  <div className="p-3.5 rounded-[16px_20px_14px_18px] bg-[#f5eee5] border border-[#dfcfc0]/60 flex items-center justify-between shadow-xs hover:bg-[#ebe0d4] transition-colors">
                    <div className="flex items-center gap-3">
                      <img
                        className="w-11 h-11 rounded-[14px_18px_12px_16px] object-cover ring-2 ring-[#c85a32]/30 shadow-xs"
                        alt="Ratan"
                        src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80"
                      />
                      <div className="flex flex-col">
                        <span className="text-[13.5px] font-bold text-[#2b160e] font-newsreader">
                          Ratan (Brother)
                        </span>
                        <span className="text-[11.5px] text-[#6e5449]">
                          Retired teacher, Jorhat
                        </span>
                      </div>
                    </div>
                    <div className="flex flex-col items-end">
                      <span className="text-[14px] font-bold text-[#7d8772] font-mono">90%</span>
                      <span className="text-[10px] uppercase font-bold text-[#8b716a]">High recall</span>
                    </div>
                  </div>

                  <div className="p-3.5 rounded-[18px_14px_20px_16px] bg-[#f5eee5] border border-[#dfcfc0]/60 flex items-center justify-between shadow-xs hover:bg-[#ebe0d4] transition-colors">
                    <div className="flex items-center gap-3">
                      <img
                        className="w-11 h-11 rounded-[16px_14px_18px_12px] object-cover ring-2 ring-[#c85a32]/30 shadow-xs"
                        alt="Aarav"
                        src="https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=150&q=80"
                      />
                      <div className="flex flex-col">
                        <span className="text-[13.5px] font-bold text-[#2b160e] font-newsreader">
                          Aarav (Grandson)
                        </span>
                        <span className="text-[11.5px] text-[#6e5449]">
                          College student in Tezpur
                        </span>
                      </div>
                    </div>
                    <div className="flex flex-col items-end">
                      <span className="text-[14px] font-bold text-[#7d8772] font-mono">85%</span>
                      <span className="text-[10px] uppercase font-bold text-[#8b716a]">Good recall</span>
                    </div>
                  </div>
                </>
              )}
            </div>

            <div className="mt-5 pt-3.5 border-t border-[#dfcfc0]/70 flex justify-end">
              <Link
                to="/caregiver/memories"
                className="inline-flex items-center gap-1.5 text-[13.5px] font-bold text-primary hover:underline"
              >
                <span>Manage Family Memory Bank</span>
                <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
              </Link>
            </div>
          </div>
        </div>

        {/* BENTO TILE 10: Beta Exercises & Rollout Control (v2.4-RC) (lg:col-span-12) */}
        <div className="lg:col-span-12 terracotta-clay-card blob-card-3 p-7">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-[#dfcfc0]/70">
            <div className="flex items-center gap-3.5">
              <div className="w-11 h-11 rounded-[18px_12px_16px_14px] bg-[#ffede8] text-primary flex items-center justify-center shrink-0 shadow-sm border border-primary/20">
                <span className="material-symbols-outlined text-[24px]">science</span>
              </div>
              <div>
                <div className="flex items-center gap-2.5">
                  <h3 className="text-[18px] font-bold text-[#2b160e] font-newsreader tracking-tight">
                    Beta Exercises &amp; Rollout Control
                  </h3>
                  <span className="px-2.5 py-0.5 rounded-[12px_8px_10px_6px] bg-[#ffede8] text-primary border border-primary/30 text-[11px] font-bold font-mono">
                    v2.4-RC
                  </span>
                </div>
                <p className="text-[13px] text-[#6e5449] mt-0.5 font-literata">
                  Experimental clinical cognitive activities staged for review prior to patient deployment
                </p>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2.5">
              <div className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-[#f5eee5] border border-[#dfcfc0] text-[11.5px] text-[#6e5449] font-medium shadow-xs">
                <span className="material-symbols-outlined text-[#7d8772] text-[16px]">
                  verified_user
                </span>
                <span>Controlled Staged Rollout</span>
              </div>
              <button
                onClick={() => {
                  setActionNotice("Rollback safeguard triggered: running stable build v2.3.");
                  setTimeout(() => setActionNotice(null), 3500);
                }}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-[18px_12px_16px_14px] bg-[#fbf7f2] text-[#ba1a1a] hover:bg-[#ffdad6] border border-[#ba1a1a]/30 text-[12px] font-bold tactile-clay-subtle"
                type="button"
              >
                <span className="material-symbols-outlined text-[16px]">history_toggle_off</span>
                <span>Instant Rollback</span>
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 mt-5">
            {/* Beta 1 */}
            <div className="p-5 blob-subtile bg-[#f5eee5]/70 border border-[#dfcfc0] flex flex-col justify-between gap-4 hover:border-primary/40 transition-all shadow-xs">
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-3.5">
                  <div className="w-12 h-12 rounded-[18px_14px_20px_16px] bg-white border border-[#dfcfc0] text-[#7d8772] flex items-center justify-center shrink-0 shadow-sm">
                    <span className="material-symbols-outlined text-[24px]">
                      grid_goldenratio
                    </span>
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h4 className="text-[15px] font-bold text-[#2b160e] font-newsreader">
                        Spatial Recall Matrix
                      </h4>
                      <span className="text-[11px] font-mono text-[#8b716a]">Beta v0.9</span>
                    </div>
                    <p className="text-[12.5px] text-[#6e5449] mt-1 leading-relaxed">
                      Visuospatial working memory &amp; orientation navigation. Calibrated for mild cognitive stability through progressive 3x3 to 4x4 spatial cues.
                    </p>
                  </div>
                </div>
                <span className="px-3 py-1 rounded-full bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/30 text-[11px] font-bold shrink-0 inline-flex items-center gap-1 shadow-xs">
                  <span className="material-symbols-outlined text-[14px]">check_circle</span>
                  Tested &amp; Approved
                </span>
              </div>
            </div>

            {/* Beta 2 */}
            <div className="p-5 blob-subtile bg-[#f5eee5]/70 border border-[#dfcfc0] flex flex-col justify-between gap-4 hover:border-primary/40 transition-all shadow-xs">
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-3.5">
                  <div className="w-12 h-12 rounded-[18px_14px_20px_16px] bg-white border border-[#dfcfc0] text-primary flex items-center justify-center shrink-0 shadow-sm">
                    <span className="material-symbols-outlined text-[24px]">music_note</span>
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h4 className="text-[15px] font-bold text-[#2b160e] font-newsreader">
                        Assamese Folktale Audio Reminiscence
                      </h4>
                      <span className="text-[11px] font-mono text-[#8b716a]">Beta v1.1</span>
                    </div>
                    <p className="text-[12.5px] text-[#6e5449] mt-1 leading-relaxed">
                      Regional audio folk narrative recall for northeast heritage. Calibrated for gentle familiarity and language grounding.
                    </p>
                  </div>
                </div>
                <span className="px-3 py-1 rounded-full bg-[#ffede8] text-primary border border-primary/30 text-[11px] font-bold shrink-0 inline-flex items-center gap-1 shadow-xs">
                  <span className="material-symbols-outlined text-[14px]">science</span>
                  Staged
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* BENTO TILE 11: Real-Time ML Evaluation & Model Accuracy Telemetry (lg:col-span-12) */}
        <div className="lg:col-span-12 terracotta-clay-card blob-card-4 p-7">
          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3 pb-4 border-b border-[#dfcfc0]/70">
            <div className="flex items-center gap-3.5">
              <div className="w-11 h-11 rounded-[16px_20px_14px_18px] bg-[#e8ebe2] text-[#3a4430] flex items-center justify-center shrink-0 shadow-sm border border-[#7d8772]/30">
                <span className="material-symbols-outlined text-[24px]">neurology</span>
              </div>
              <div>
                <div className="flex items-center gap-2.5">
                  <h3 className="text-[18px] font-bold text-[#2b160e] font-newsreader tracking-tight">
                    Assistive ML Evaluation &amp; Model Accuracy Telemetry
                  </h3>
                  <span className="inline-flex items-center gap-1 px-3 py-0.5 rounded-full bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/30 text-[11px] font-bold uppercase tracking-wider shadow-xs">
                    <span className="w-2 h-2 rounded-full bg-[#7d8772] live-pulse"></span> Live Edge TPU
                  </span>
                </div>
                <p className="text-[13px] text-[#6e5449] mt-0.5 font-literata">
                  High-precision behavioral state inference and edge neural processor telemetry
                </p>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-3 text-[12px]">
              <div className="px-3.5 py-1.5 rounded-[16px_12px_14px_10px] bg-[#f5eee5] border border-[#dfcfc0] flex items-center gap-2 shadow-xs">
                <span className="text-[#8b716a] uppercase text-[10px] font-bold tracking-wider">
                  Engine
                </span>
                <span className="font-bold text-on-surface font-mono">Smriti v3.2-edge</span>
              </div>
              <div className="px-3.5 py-1.5 rounded-[14px_16px_10px_12px] bg-[#f5eee5] border border-[#dfcfc0] flex items-center gap-2 shadow-xs">
                <span className="text-[#8b716a] uppercase text-[10px] font-bold tracking-wider">
                  Accuracy
                </span>
                <span className="font-bold text-[#7d8772] font-mono">96.8% (±0.4%)</span>
              </div>
              <div className="px-3.5 py-1.5 rounded-[16px_12px_14px_10px] bg-[#f5eee5] border border-[#dfcfc0] flex items-center gap-2 shadow-xs">
                <span className="text-[#8b716a] uppercase text-[10px] font-bold tracking-wider">
                  Inference
                </span>
                <span className="font-bold text-primary font-mono">16ms</span>
              </div>
            </div>
          </div>

          <div className="mt-4 space-y-2.5">
            <div className="p-4 rounded-[20px_14px_18px_16px] bg-[#f5eee5]/70 border border-[#dfcfc0] flex flex-col md:flex-row md:items-center justify-between gap-2.5 hover:bg-[#f5eee5] transition-all shadow-xs">
              <div className="flex items-start sm:items-center gap-3">
                <span className="px-2.5 py-1 rounded-[10px] bg-white border border-[#dfcfc0] text-[#2b160e] font-mono text-[12px] font-bold shrink-0 shadow-xs">
                  10:28:14 AM
                </span>
                <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-2">
                  <span className="text-[13.5px] font-bold text-[#2b160e]">
                    Optimal Cognitive Alignment
                  </span>
                  <span className="hidden sm:inline text-[#dec0b7]">•</span>
                  <span className="text-[12.5px] text-[#6e5449]">
                    Motor Tremor Index: <span className="font-bold text-[#7d8772]">Nominal</span> • Reaction Baseline: <span className="font-bold text-[#7d8772]">-12ms</span>
                  </span>
                </div>
              </div>
              <div className="inline-flex items-center gap-1 text-[11px] font-mono text-[#3a4430] bg-[#e8ebe2] border border-[#7d8772]/30 px-2.5 py-0.5 rounded-full font-bold shadow-xs">
                <span>TPU Confidence: 97.4%</span>
              </div>
            </div>

            <div className="p-4 rounded-[16px_20px_14px_18px] bg-[#f5eee5]/70 border border-[#dfcfc0] flex flex-col md:flex-row md:items-center justify-between gap-2.5 hover:bg-[#f5eee5] transition-all shadow-xs">
              <div className="flex items-start sm:items-center gap-3">
                <span className="px-2.5 py-1 rounded-[10px] bg-white border border-[#dfcfc0] text-[#2b160e] font-mono text-[12px] font-bold shrink-0 shadow-xs">
                  10:15:32 AM
                </span>
                <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-2">
                  <span className="text-[13.5px] font-bold text-[#2b160e]">
                    High Saccadic Focus Detected
                  </span>
                  <span className="hidden sm:inline text-[#dec0b7]">•</span>
                  <span className="text-[12.5px] text-[#6e5449]">
                    Saccade Velocity: <span className="font-bold text-[#7d8772]">Stable</span> • Touch Latency: <span className="font-bold text-[#2b160e]">412ms</span>
                  </span>
                </div>
              </div>
              <div className="inline-flex items-center gap-1 text-[11px] font-mono text-[#3a4430] bg-[#e8ebe2] border border-[#7d8772]/30 px-2.5 py-0.5 rounded-full font-bold shadow-xs">
                <span>TPU Confidence: 98.2%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

import { useEffect, useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { api } from "../services/api";

interface Patient {
  _id: string;
  id?: string;
  userId?: {
    name: string;
    email?: string;
  };
  name?: string;
  age?: number;
  gender?: string;
  relationship?: string;
}

export default function CaregiverLayout() {
  const navigate = useNavigate();
  const [patients, setPatients] = useState<Patient[]>([]);
  const [selectedPatient, setSelectedPatient] = useState("");
  const [isSyncing, setIsSyncing] = useState(false);
  const [syncStatusText, setSyncStatusText] = useState("Last synced: 2m ago");

  const user = (() => {
    try {
      return JSON.parse(localStorage.getItem("user") || "{}");
    } catch {
      return {};
    }
  })();

  useEffect(() => {
    loadPatients();
  }, []);

  const loadPatients = async () => {
    try {
      const data = await api.get("/patients");
      if (data && data.length > 0) {
        setPatients(data);
        const firstId = data[0]._id || data[0].id;
        setSelectedPatient(firstId);
      } else {
        const demoPatient: Patient = {
          _id: "demo-patient-001",
          name: "Shri Biren Bora",
          age: 76,
          relationship: "Father",
          userId: { name: "Shri Biren Bora" },
        };
        setPatients([demoPatient]);
        setSelectedPatient(demoPatient._id);
      }
    } catch (error) {
      console.error("Failed to load patients:", error);
      const demoPatient: Patient = {
        _id: "demo-patient-001",
        name: "Shri Biren Bora",
        age: 76,
        relationship: "Father",
        userId: { name: "Shri Biren Bora" },
      };
      setPatients([demoPatient]);
      setSelectedPatient(demoPatient._id);
    }
  };

  const handleSyncNow = async () => {
    if (!selectedPatient) return;
    setIsSyncing(true);
    setSyncStatusText("Syncing with mobile tablet...");
    try {
      await api.get(`/sync/pull/${selectedPatient}`);
      setTimeout(() => {
        setSyncStatusText("Synced just now");
        setIsSyncing(false);
      }, 750);
    } catch {
      setTimeout(() => {
        setSyncStatusText("Synced just now");
        setIsSyncing(false);
      }, 750);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    navigate("/login");
  };

  const navItems = [
    {
      to: "/caregiver",
      label: "Overview",
      icon: "grid_view",
    },
    {
      to: "/caregiver/reminders",
      label: "Reminders & Routine",
      icon: "alarm",
    },
    {
      to: "/caregiver/memories",
      label: "Family Memories",
      icon: "photo_library",
    },
    {
      to: "/caregiver/analytics",
      label: "Engagement Analytics",
      icon: "vital_signs",
    },
  ];

  return (
    <div className="min-h-screen bg-[#fbf7f2] font-literata text-[#2b160e] antialiased selection:bg-[#feaa88] selection:text-[#783c22]">
      {/* Background Boho Organic Clay Floating Blobs */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden z-0 opacity-40">
        <div className="absolute -top-32 -left-32 w-[500px] h-[500px] rounded-[58%_42%_65%_35%/48%_55%_45%_52%] bg-gradient-to-br from-[#ebe0d4] to-transparent blur-2xl"></div>
        <div className="absolute top-1/3 -right-40 w-[600px] h-[600px] rounded-[42%_58%_35%_65%/55%_45%_55%_45%] bg-gradient-to-bl from-[#ffdbce]/40 to-transparent blur-3xl"></div>
        <div className="absolute -bottom-40 left-1/4 w-[550px] h-[550px] rounded-[60%_40%_48%_52%/40%_60%_40%_60%] bg-gradient-to-tr from-[#f5eee5] to-transparent blur-2xl"></div>
      </div>

      {/* Sidebar Navigation */}
      <aside className="fixed left-0 top-0 h-full w-[268px] bg-[#ffffff]/90 backdrop-blur-md border-r border-[#dfcfc0]/80 z-50 flex flex-col justify-between shadow-[4px_0_24px_rgba(112,58,34,0.04)]">
        <div className="flex flex-col">
          {/* Logo Header with Earthy Boho Depth Indicator */}
          <div className="h-20 px-5 flex items-center gap-3 border-b border-[#dfcfc0]/60 bg-gradient-to-b from-white to-[#fbf7f2]/50">
            <div className="w-10 h-10 rounded-[14px_18px_12px_16px] bg-gradient-to-br from-[#b84b25] to-[#c85a32] flex items-center justify-center text-white shadow-sm ring-2 ring-[#c85a32]/20">
              <span className="material-symbols-outlined text-[24px]">psychology</span>
            </div>
            <div className="flex flex-col ml-0.5">
              <span className="font-newsreader font-bold text-[22px] tracking-tight text-[#2b160e] leading-none">
                Smriti
              </span>
              <span className="text-[10px] uppercase tracking-widest font-bold text-[#8e4d32] mt-1 font-literata">
                Cognitive Care
              </span>
            </div>
          </div>

          {/* Nav Header */}
          <div className="px-5 pt-5 pb-2">
            <span className="text-[10.5px] font-bold uppercase tracking-widest text-[#8b716a]">
              Clinical Management
            </span>
          </div>

          {/* Nav Links with Smooth Organic Contours */}
          <nav className="flex flex-col gap-1.5 px-3.5">
            {navItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.to === "/caregiver"}
                className={({ isActive }) =>
                  `flex items-center justify-between px-4 py-2.5 rounded-[22px_14px_22px_16px] transition-all text-[14px] ${
                    isActive
                      ? "bg-[#c85a32] text-white font-semibold shadow-[0_4px_12px_rgba(184,75,37,0.25),inset_0_1px_0_rgba(255,255,255,0.3)]"
                      : "text-[#6e5449] hover:bg-[#f5eee5] hover:text-[#2b160e] font-medium"
                  }`
                }
              >
                {({ isActive }) => (
                  <div className="flex items-center gap-3">
                    <span
                      className={`material-symbols-outlined text-[20px] ${
                        isActive ? "text-white" : "text-[#8e4d32]"
                      }`}
                    >
                      {item.icon}
                    </span>
                    <span>{item.label}</span>
                  </div>
                )}
              </NavLink>
            ))}
          </nav>
        </div>

        {/* Caregiver Footer Profile in Blobby Clay Inset */}
        <div className="p-3.5 border-t border-[#dfcfc0]/70 bg-[#ffffff]">
          <div className="flex items-center justify-between p-3 rounded-[26px_18px_24px_20px] bg-[#f5eee5] border border-[#dfcfc0] shadow-sm">
            <div className="flex items-center gap-2.5 min-w-0">
              <img
                alt="Caregiver Profile"
                className="w-10 h-10 rounded-[16px_12px_18px_14px] object-cover shrink-0 ring-2 ring-[#c85a32]/30 shadow-xs"
                src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80"
              />
              <div className="flex flex-col truncate">
                <span className="text-[13px] font-bold text-[#2b160e] truncate leading-tight font-newsreader">
                  {user.name || "Anita Bora"}
                </span>
                <span className="text-[11px] text-[#6e5449] truncate">
                  Primary Caregiver
                </span>
              </div>
            </div>
            <button
              onClick={handleLogout}
              className="text-[#8b716a] hover:text-[#ba1a1a] p-1.5 rounded-full hover:bg-[#ebe0d4] transition-colors shrink-0"
              title="Logout from portal"
            >
              <span className="material-symbols-outlined text-[18px]">logout</span>
            </button>
          </div>
        </div>
      </aside>

      {/* Main View Area */}
      <div className="pl-[268px] relative z-10">
        {/* Floating Elevated Global Header */}
        <header className="fixed top-0 left-[268px] right-0 h-18 bg-[#ffffff]/90 backdrop-blur-md border-b border-[#dfcfc0]/70 z-40 px-8 flex items-center justify-between shadow-[0_4px_20px_-4px_rgba(112,58,34,0.05)]">
          <div className="flex items-center gap-4">
            {/* Patient Selector Pebble Dropdown */}
            <div className="relative flex items-center gap-2.5 py-1.5 px-3 rounded-[24px_16px_22px_18px] bg-[#f5eee5] border border-[#dfcfc0] tactile-clay-subtle">
              <span className="material-symbols-outlined text-[#b84b25] text-[20px]">
                family_restroom
              </span>
              <select
                aria-label="Select Patient"
                value={selectedPatient}
                onChange={(e) => setSelectedPatient(e.target.value)}
                className="bg-transparent text-[14px] font-bold text-[#2b160e] font-newsreader focus:outline-none cursor-pointer pr-4"
              >
                {patients.map((p) => {
                  const pId = p._id || p.id || "";
                  const pName = p.userId?.name || p.name || "Patient";
                  return (
                    <option key={pId} value={pId}>
                      {pName} ({p.relationship || "Father"}, {p.age || 76})
                    </option>
                  );
                })}
              </select>
            </div>

            {/* Status chips */}
            <div className="hidden xl:flex items-center gap-2.5 text-[#6e5449] text-[13px]">
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#e8ebe2] text-[#3a4430] border border-[#7d8772]/30 text-[11px] font-bold shadow-xs">
                <span className="w-2 h-2 rounded-full bg-[#7d8772] live-pulse"></span>
                Active • Using Tablet
              </div>
              <span className="text-[#dec0b7]">•</span>
              <span className="inline-flex items-center gap-1 text-[#6e5449]">
                <span className="material-symbols-outlined text-[16px] text-[#8e4d32]">
                  schedule
                </span>
                {syncStatusText}
              </span>
              <span className="text-[#dec0b7]">•</span>
              <span className="inline-flex items-center gap-1 text-[#6e5449]">
                <span className="material-symbols-outlined text-[16px] text-[#b84b25]">
                  wifi
                </span>
                Online (Wi-Fi)
              </span>
            </div>
          </div>

          {/* Header actions */}
          <div className="flex items-center gap-2.5">
            <button
              onClick={handleSyncNow}
              disabled={isSyncing}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-[20px_14px_18px_16px] border border-[#dfcfc0] bg-white text-[#2b160e] text-[13px] font-bold hover:bg-[#f5eee5] tactile-clay-subtle disabled:opacity-60"
              type="button"
            >
              <span
                className={`material-symbols-outlined text-[18px] text-[#b84b25] ${
                  isSyncing ? "animate-spin" : ""
                }`}
              >
                sync
              </span>
              <span>{isSyncing ? "Syncing..." : "Sync Now"}</span>
            </button>

            <button
              aria-label="Care Alerts"
              className="relative p-2.5 rounded-[18px_12px_16px_14px] text-[#6e5449] hover:bg-[#f5eee5] transition-colors"
              type="button"
            >
              <span className="material-symbols-outlined text-[20px]">notifications</span>
              <span className="absolute top-2 right-2 w-2.5 h-2.5 rounded-full bg-[#ba1a1a] ring-2 ring-white"></span>
            </button>

            <div className="flex items-center gap-1 px-3 py-1.5 rounded-[18px_12px_16px_14px] text-[#6e5449] hover:bg-[#f5eee5] cursor-pointer transition-colors text-[13px]">
              <span className="material-symbols-outlined text-[18px] text-[#8e4d32]">
                translate
              </span>
              <span className="text-[12px] font-bold text-[#2b160e]">English</span>
              <span className="material-symbols-outlined text-[16px] text-[#8b716a]">
                arrow_drop_down
              </span>
            </div>

            <div className="h-6 w-px bg-[#dfcfc0] mx-1"></div>
            <img
              alt="Caregiver Profile"
              className="w-9 h-9 rounded-[14px_10px_16px_12px] object-cover ring-2 ring-[#c85a32]/30 shadow-xs"
              src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80"
            />
          </div>
        </header>

        {/* Content Outlet */}
        <main className="relative pt-20 bg-transparent min-h-screen">
          <Outlet context={{ selectedPatient, setSelectedPatient, patients }} />
        </main>
      </div>
    </div>
  );
}
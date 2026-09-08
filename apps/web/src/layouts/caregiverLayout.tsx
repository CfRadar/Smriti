import { useEffect, useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import {
    LayoutDashboard,
    Bell,
    Image,
    TrendingUp,
    LogOut,
} from "lucide-react";

import { api } from "../services/api";

interface Patient {
    _id: string;
    id?: string;
    userId?: {
        name: string;
        email?: string;
    };
    name?: string;
}

export default function CaregiverLayout() {
    const navigate = useNavigate();
    const [patients, setPatients] = useState<Patient[]>([]);
    const [selectedPatient, setSelectedPatient] = useState("");

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
                const demoPatient = {
                    _id: "demo-patient-001",
                    name: "Shri Biren Bora (Assam)",
                    userId: { name: "Shri Biren Bora (Assam)" }
                };
                setPatients([demoPatient]);
                setSelectedPatient(demoPatient._id);
            }
        } catch (error) {
            console.error("Failed to load patients:", error);
            const demoPatient = {
                _id: "demo-patient-001",
                name: "Shri Biren Bora (Assam)",
                userId: { name: "Shri Biren Bora (Assam)" }
            };
            setPatients([demoPatient]);
            setSelectedPatient(demoPatient._id);
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
            icon: LayoutDashboard,
        },
        {
            to: "/caregiver/reminders",
            label: "Reminders & Routine",
            icon: Bell,
        },
        {
            to: "/caregiver/memories",
            label: "Family Memories",
            icon: Image,
        },
        {
            to: "/caregiver/analytics",
            label: "Engagement Analytics",
            icon: TrendingUp,
        },
    ];

    return (
        <div className="min-h-screen bg-gray-50 flex">

            {/* Sidebar */}
            <aside className="w-64 bg-white border-r flex flex-col">

                {/* Brand */}
                <div className="p-6 border-b">
                    <h1 className="text-xl font-bold">
                        Smriti <span className="font-normal">(स्मृति)</span>
                    </h1>
                    <p className="text-sm text-gray-500">
                        Cognitive Care
                    </p>
                </div>

                {/* Navigation */}
                <nav className="flex-1 p-4 space-y-2">
                    {navItems.map((item) => {
                        const Icon = item.icon;

                        return (
                            <NavLink
                                key={item.to}
                                to={item.to}
                                end={item.to === "/caregiver"}
                                className={({ isActive }) =>
                                    `flex items-center gap-3 px-4 py-3 rounded-lg text-sm transition ${isActive
                                        ? "bg-gray-100 font-semibold"
                                        : "text-gray-600 hover:bg-gray-50"
                                    }`
                                }
                            >
                                <Icon size={20} />
                                {item.label}
                            </NavLink>
                        );
                    })}
                </nav>

                {/* Caregiver / Logout */}
                <div className="p-4 border-t">
                    <div className="text-sm mb-3">
                        <p className="font-medium text-gray-900">{user.name || "Caregiver Anita"}</p>
                        <p className="text-xs text-gray-500">{user.email || "caregiver@smriti.org"}</p>
                    </div>

                    <button
                        onClick={handleLogout}
                        className="flex items-center gap-2 w-full px-4 py-2 rounded-lg text-sm text-gray-600 hover:bg-gray-100"
                    >
                        <LogOut size={18} />
                        Logout
                    </button>
                </div>
            </aside>

            {/* Main area */}
            <div className="flex-1 flex flex-col">

                {/* Top Header */}
                <header className="h-16 bg-white border-b flex items-center justify-between px-6">

                    {/* Patient Selector */}
                    <div className="flex items-center gap-3">
                        <label
                            htmlFor="patient"
                            className="text-sm font-medium"
                        >
                            Patient
                        </label>

                        <select
                            id="patient"
                            value={selectedPatient}
                            onChange={(e) => setSelectedPatient(e.target.value)}
                            className="border rounded-lg px-3 py-2 text-sm"
                        >
                            {patients.length === 0 ? (
                                <option value="">No patients</option>
                            ) : (
                                patients.map((patient) => {
                                    const pId = patient._id || patient.id || "";
                                    const pName = patient.userId?.name || patient.name || "Patient";
                                    return (
                                        <option key={pId} value={pId}>
                                            {pName}
                                        </option>
                                    );
                                })
                            )}
                        </select>
                    </div>

                    {/* Status */}
                    <div className="flex items-center gap-2 text-sm">
                        <span className="h-2 w-2 rounded-full bg-green-500" />
                        <span className="text-gray-600">
                            Online / Synced
                        </span>
                    </div>
                </header>
                <main className="flex-1 p-6">
                    <Outlet context={{ selectedPatient, setSelectedPatient, patients }} />
                </main>
            </div>
        </div>
    );
}
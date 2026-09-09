import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import LandingPage from "./pages/LandingPage";
import LoginPage from "./pages/auth/LoginPage";
import ProtectedRoute from "./components/ProtectedRoute";
import CaregiverLayout from "./layouts/caregiverLayout";
import DashboardOverview from "./pages/caregiver/DashboardOverview";
import RemindersPage from "./pages/caregiver/RemindersPage";
import MemoriesPage from "./pages/caregiver/MemoriesPage";
import AnalyticsPage from "./pages/caregiver/AnalyticsPage";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Public Routes */}
        <Route path="/" element={<LandingPage />} />
        <Route path="/login" element={<LoginPage />} />

        {/* Protected Caregiver Portal */}
        <Route element={<ProtectedRoute />}>
          <Route path="/caregiver" element={<CaregiverLayout />}>
            <Route index element={<DashboardOverview />} />
            <Route path="reminders" element={<RemindersPage />} />
            <Route path="memories" element={<MemoriesPage />} />
            <Route path="analytics" element={<AnalyticsPage />} />
          </Route>
        </Route>

        {/* Fallback */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import LandingPage from "./pages/LandingPage";
import CaregiverLayout from "./layouts/caregiverLayout";
import DashboardOverview from "./pages/caregiver/DashboardOverview";
import RemindersPage from "./pages/caregiver/RemindersPage";
import MemoriesPage from "./pages/caregiver/MemoriesPage";
import AnalyticsPage from "./pages/caregiver/AnalyticsPage";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Landing Page */}
        <Route path="/" element={<LandingPage />} />

        {/* Caregiver Portal */}
        <Route path="/caregiver" element={<CaregiverLayout />}>
          <Route index element={<DashboardOverview />} />
          <Route path="reminders" element={<RemindersPage />} />
          <Route path="memories" element={<MemoriesPage />} />
          <Route path="analytics" element={<AnalyticsPage />} />
        </Route>

        {/* Fallback */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

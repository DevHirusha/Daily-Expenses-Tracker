import { Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import Dashboard from "./pages/DashboardHome/Dashboard";
import ProtectedRoute from "./components/ProtectedRoute";

import GigManagement from "./pages/Gig/GigManagement";
import AnnouncementManagement from "./pages/Announcements/AnnouncementManagement";
import ManageUsers from "./pages/Users/ManageUsers";
import ProfileForm from "./pages/Profile/ProfileForm";
import DashboardHome from "./pages/DashboardHome/DashboardHome";

function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />

      {/* Dashboard Layout Route */}
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <Dashboard /> {/* This will be the Layout component */}
          </ProtectedRoute>
        }
      >
        {/* Child Routes (rendered inside <Outlet /> of Dashboard) */}
        <Route index element={<DashboardHome />} /> {/* Default: /dashboard */}
        <Route path="users" element={<ManageUsers />} /> {/* /dashboard/users */}
        <Route path="gigs" element={<GigManagement />} /> {/* /dashboard/gigs */}
        <Route path="announcements" element={<AnnouncementManagement />} /> {/* /dashboard/announcements */}
        <Route path="profile" element={<ProfileForm />} /> {/* /dashboard/profile */}
      </Route>

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}

export default App;

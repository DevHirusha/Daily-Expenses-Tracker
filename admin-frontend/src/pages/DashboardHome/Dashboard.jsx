import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Menu,
  Home,
  Users,
  Contact,
  FileText,
  User,
  Moon,
  Bell,
  Settings,
  Download,
  LogOut,
} from "lucide-react";
import { assets } from "../../assets/images/assets";

//Right side content components
const DashboardHome = () => (
  <div className="text-white text-xl">Dashboard Content</div>
);
const ManageUsers = () => (
  <div className="text-white text-xl">Manage Users Content</div>
);
const BudgetManagement = () => (
  <div className="text-white text-xl">Budget Management Content</div>
);
const ExpensesManagement = () => (
  <div className="text-white text-xl">Expenses Management Content</div>
);
const GigManagement = () => (
  <div className="text-white text-xl">Gigs Management Content</div>
);
const ProfileForm = () => (
  <div className="text-white text-xl">Profile Form Content</div>
);

const Dashboard = () => {
  const [activeTab, setActiveTab] = useState("dashboard");
  const navigate = useNavigate();

  // Logout function
  const handleLogout = () => {
    localStorage.removeItem("token");

    //  navigate to login page after logout
    navigate("/login");
  };

  const renderContent = () => {
    switch (activeTab) {
      case "dashboard":
        return <DashboardHome />;
      case "users":
        return <ManageUsers />;
      case "budget":
        return <BudgetManagement />;
      case "expenses":
        return <ExpensesManagement />;
      case "gigs":
        return <GigManagement />;
      case "profile":
        return <ProfileForm />;
      default:
        return <DashboardHome />;
    }
  };

  return (
    <div className="flex h-screen bg-[#141B2D] text-gray-100 font-sans overflow-hidden">
      {/* ================= SIDEBAR ================= */}
      <aside className="w-[260px] bg-[#1F2A40] flex flex-col transition-all duration-300">
        <div className="flex items-center justify-between p-6">
          <h5 className="text-sm font-bold tracking-wider text-white">
            ADMIN WORKSPACE
          </h5>
          <button className="text-gray-400 hover:text-white">
            <Menu size={20} />
          </button>
        </div>

        <div className="flex flex-col items-center mt-6 mb-8">
          {/* Image Container */}
          <div className="w-24 h-24 bg-[#141B2D] rounded-full flex items-center justify-center mb-4 overflow-hidden shadow-lg border-2 border-[#141B2D]">
            <img
              src={assets.logo}
              alt="PocketCrew Logo"
              className="w-full h-full object-cover"
            />
          </div>
          {/* Text */}
          <h2 className="text-xl font-semibold text-white">PocketCrew</h2>
          <p className="text-sm text-yellow-600 mt-1">Admin</p>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto px-4 pb-4 flex flex-col">
          <ul className="space-y-2">
            {/* Dashboard */}
            <li
              onClick={() => setActiveTab("dashboard")}
              className={`flex items-center gap-4 px-4 py-3 rounded-md cursor-pointer transition-colors ${
                activeTab === "dashboard"
                  ? "text-yellow-600 bg-[#141B2D]/50"
                  : "text-gray-300 hover:bg-[#141B2D]/30"
              }`}
            >
              <Home size={20} />
              <span className="text-sm font-medium">Dashboard</span>
            </li>

            <li className="px-4 py-4 text-xs font-bold text-gray-400 uppercase tracking-wider mt-4">
              Data
            </li>

            {/* Manage Users */}
            <li
              onClick={() => setActiveTab("users")}
              className={`flex items-center gap-4 px-4 py-3 rounded-md cursor-pointer transition-colors ${
                activeTab === "users"
                  ? "text-yellow-600 bg-[#141B2D]/50"
                  : "text-gray-300 hover:bg-[#141B2D]/30"
              }`}
            >
              <Users size={20} />
              <span className="text-sm font-medium">Manage Users</span>
            </li>

            {/* Budget Management */}
            <li
              onClick={() => setActiveTab("budget")}
              className={`flex items-center gap-4 px-4 py-3 rounded-md cursor-pointer transition-colors ${
                activeTab === "budget"
                  ? "text-yellow-600 bg-[#141B2D]/50"
                  : "text-gray-300 hover:bg-[#141B2D]/30"
              }`}
            >
              <Contact size={20} />
              <span className="text-sm font-medium">Budget Management</span>
            </li>

            {/* Expenses Management */}
            <li
              onClick={() => setActiveTab("expenses")}
              className={`flex items-center gap-4 px-4 py-3 rounded-md cursor-pointer transition-colors ${
                activeTab === "expenses"
                  ? "text-yellow-600 bg-[#141B2D]/50"
                  : "text-gray-300 hover:bg-[#141B2D]/30"
              }`}
            >
              <FileText size={20} />
              <span className="text-sm font-medium">Expenses Management</span>
            </li>

            {/* Gigs Management */}
            <li
              onClick={() => setActiveTab("gigs")}
              className={`flex items-center gap-4 px-4 py-3 rounded-md cursor-pointer transition-colors ${
                activeTab === "gigs"
                  ? "text-yellow-600 bg-[#141B2D]/50"
                  : "text-gray-300 hover:bg-[#141B2D]/30"
              }`}
            >
              <FileText size={20} />
              <span className="text-sm font-medium">Gigs Management</span>
            </li>

            <li className="px-4 py-4 text-xs font-bold text-gray-400 uppercase tracking-wider mt-4">
              Pages
            </li>

            {/* Profile Form */}
            <li
              onClick={() => setActiveTab("profile")}
              className={`flex items-center gap-4 px-4 py-3 rounded-md cursor-pointer transition-colors ${
                activeTab === "profile"
                  ? "text-yellow-600 bg-[#141B2D]/50"
                  : "text-gray-300 hover:bg-[#141B2D]/30"
              }`}
            >
              <User size={20} />
              <span className="text-sm font-medium">Profile Form</span>
            </li>
          </ul>

          {/*  LOGOUT BUTTON */}
          <div className="mt-auto pt-4 border-t border-gray-700/50">
            <button
              onClick={handleLogout}
              className="w-full flex items-center gap-4 px-4 py-3 rounded-md cursor-pointer transition-colors text-red-400 hover:bg-red-500/10 hover:text-red-300"
            >
              <LogOut size={20} />
              <span className="text-sm font-medium">Logout</span>
            </button>
          </div>
        </nav>
      </aside>

      {/* MAIN CONTENT */}
      <main className="flex-1 flex flex-col relative overflow-y-auto">
        {/* Top Bar */}
        <header className="flex justify-between items-center p-6 bg-[#141B2D] sticky top-0 z-10 border-b border-gray-800">
          <div>
            <h1 className="text-2xl font-bold text-white uppercase">
              {activeTab}
            </h1>
            <p className="text-sm text-yellow-600 mt-1">
              Welcome to your {activeTab}
            </p>
          </div>
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-4 text-gray-300">
              <button className="hover:text-white">
                <Moon size={20} />
              </button>
              <button className="hover:text-white">
                <Bell size={20} />
              </button>
              <button className="hover:text-white">
                <Settings size={20} />
              </button>
              <button className="hover:text-white">
                <User size={20} />
              </button>
            </div>
            <button className="bg-[#4c4c9d] hover:bg-[#3d3d80] text-white text-xs font-bold py-3 px-6 rounded flex items-center gap-2 transition-colors">
              <Download size={16} />
              DOWNLOAD REPORTS
            </button>
          </div>
        </header>

        <div className="p-6 pt-0 flex flex-col gap-6 mt-6">
          {renderContent()}
        </div>
      </main>
    </div>
  );
};

export default Dashboard;

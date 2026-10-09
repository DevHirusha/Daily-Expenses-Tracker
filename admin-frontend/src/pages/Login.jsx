import { useEffect, useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import {
  FiEye,
  FiEyeOff,
  FiLock,
  FiMail,
  FiShield,
  FiAlertCircle,
} from "react-icons/fi";
import { MdCopyright } from "react-icons/md";
import { RiAdminFill } from "react-icons/ri";
import { assets } from "../assets/images/assets";
import api from "../api/axios";

function Login() {
  const navigate = useNavigate();
  const location = useLocation();
  const redirectTo = location.state?.from?.pathname || "/dashboard";

  // Form state
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);

  // UI state
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  // Load saved email
  useEffect(() => {
    const savedEmail = localStorage.getItem("admin_email");
    if (savedEmail) {
      setEmail(savedEmail);
      setRememberMe(true);
    }
  }, []);

  // Already logged in? → redirect
  useEffect(() => {
    const token = localStorage.getItem("admin_token");
    if (token) navigate(redirectTo, { replace: true });
  }, [navigate, redirectTo]);

  // Client-side validation
  const validate = () => {
    if (!email.trim()) return "Email is required.";
    if (!/^\S+@\S+\.\S+$/.test(email)) return "Please enter a valid email.";
    if (!password) return "Password is required.";
    if (password.length < 6) return "Password must be at least 6 characters.";
    return null;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    const validationError = validate();
    if (validationError) {
      setError(validationError);
      return;
    }

    setLoading(true);

    try {
      const { data } = await api.post("/admin/login", {
        email: email.trim().toLowerCase(),
        password,
      });

      // Backend response: { token, role, userId, name, email }
      const { token, role, userId, name, email: userEmail } = data;

      if (!token) {
        throw new Error("No token received from server.");
      }

      // Extra safety — even though backend blocks non-admins
      if (role !== "ADMIN" && role !== "SUPER_ADMIN") {
        setError("Access denied. Admin account required.");
        return;
      }

      // Save session
      localStorage.setItem("admin_token", token);
      localStorage.setItem(
        "admin_user",
        JSON.stringify({ userId, name, email: userEmail, role })
      );

      if (rememberMe) {
        localStorage.setItem("admin_email", email.trim().toLowerCase());
      } else {
        localStorage.removeItem("admin_email");
      }

      navigate(redirectTo, { replace: true });
    } catch (err) {
      console.error("Login error:", err);

      if (err.response) {
        // Backend error format: { error: true, message: "..." }
        const msg =
          err.response.data?.message ||
          err.response.data?.error ||
          (err.response.status === 403
            ? "Access denied. Admin account required."
            : "Invalid email or password.");
        setError(msg);
      } else if (err.request) {
        setError("Cannot reach server. Please check your connection.");
      } else {
        setError(err.message || "Something went wrong. Try again.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      className="relative flex min-h-screen items-center justify-center overflow-hidden bg-slate-900 px-4"
      style={{
        backgroundImage: `
          linear-gradient(rgba(15, 23, 42, 0.82), rgba(15, 23, 42, 0.82)),
          url("/login-bg.jpg")
        `,
        backgroundSize: "cover",
        backgroundPosition: "center",
      }}
    >
      <div className="absolute -left-32 -top-32 h-72 w-72 rounded-full bg-blue-600/20 blur-3xl" />
      <div className="absolute -bottom-32 -right-32 h-72 w-72 rounded-full bg-orange-500/20 blur-3xl" />

      <div className="relative z-10 w-full max-w-sm">
        <div className="rounded-2xl border border-white/10 bg-white/95 p-5 shadow-2xl backdrop-blur-xl sm:p-6">
          {/* Logo */}
          <div className="mb-4 flex justify-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-xl bg-white p-1.5 shadow-md ring-1 ring-slate-200">
              <img
                src={assets.logo}
                alt="PocketCrew Logo"
                className="h-full w-full rounded-lg object-contain"
              />
            </div>
          </div>

          {/* Title */}
          <div className="mb-5 text-center">
            <h1 className="text-xl font-bold tracking-tight text-slate-900">
              PocketCrew Admin Portal
            </h1>
            <p className="mt-1 text-xs text-slate-500">
              Manage your platform from one place
            </p>
          </div>

          {/* Error */}
          {error && (
            <div className="mb-4 flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 p-2.5">
              <FiAlertCircle className="mt-0.5 shrink-0 text-sm text-red-500" />
              <p className="text-[11px] font-medium text-red-700">{error}</p>
            </div>
          )}

          {/* Form */}
          <form className="space-y-4" onSubmit={handleSubmit} noValidate>
            {/* Email */}
            <div>
              <label
                htmlFor="email"
                className="mb-1.5 block text-xs font-semibold text-slate-700"
              >
                Email Address
              </label>
              <div className="relative">
                <FiMail className="absolute left-3.5 top-1/2 -translate-y-1/2 text-base text-slate-400" />
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Enter your email"
                  autoComplete="email"
                  disabled={loading}
                  className="h-10 w-full rounded-lg border border-slate-200 bg-slate-50 pl-10 pr-3 text-xs text-slate-800 outline-none transition placeholder:text-slate-400 hover:border-slate-300 focus:border-blue-500 focus:bg-white focus:ring-4 focus:ring-blue-500/10 disabled:opacity-60"
                />
              </div>
            </div>

            {/* Password */}
            <div>
              <div className="mb-1.5 flex items-center justify-between">
                <label
                  htmlFor="password"
                  className="text-xs font-semibold text-slate-700"
                >
                  Password
                </label>
                <button
                  type="button"
                  className="text-[11px] font-semibold text-blue-600 transition hover:text-blue-700"
                >
                  Forgot Password?
                </button>
              </div>
              <div className="relative">
                <FiLock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-base text-slate-400" />
                <input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  autoComplete="current-password"
                  disabled={loading}
                  className="h-10 w-full rounded-lg border border-slate-200 bg-slate-50 pl-10 pr-10 text-xs text-slate-800 outline-none transition placeholder:text-slate-400 hover:border-slate-300 focus:border-blue-500 focus:bg-white focus:ring-4 focus:ring-blue-500/10 disabled:opacity-60"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((s) => !s)}
                  tabIndex={-1}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-base text-slate-400 transition hover:text-slate-600"
                >
                  {showPassword ? <FiEyeOff /> : <FiEye />}
                </button>
              </div>
            </div>

            {/* Remember me */}
            <div className="flex items-center">
              <label className="flex cursor-pointer items-center gap-2">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="h-3.5 w-3.5 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                />
                <span className="text-xs text-slate-600">Remember me</span>
              </label>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading}
              className="group flex h-10 w-full items-center justify-center gap-2 rounded-lg bg-blue-600 text-xs font-semibold text-white shadow-md shadow-blue-600/20 transition hover:bg-blue-700 hover:shadow-blue-600/30 focus:outline-none focus:ring-4 focus:ring-blue-500/20 disabled:cursor-not-allowed disabled:opacity-70"
            >
              {loading ? (
                <>
                  <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white/40 border-t-white" />
                  Signing in...
                </>
              ) : (
                <>
                  Sign In
                  <RiAdminFill className="text-base transition-transform group-hover:translate-x-1" />
                </>
              )}
            </button>
          </form>

          {/* Security message */}
          <div className="mt-5 flex items-center gap-2.5 rounded-lg border border-emerald-100 bg-emerald-50 p-2.5">
            <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-emerald-100 text-emerald-600">
              <FiShield className="text-sm" />
            </div>
            <div>
              <p className="text-[10px] font-semibold text-emerald-800">
                Secure Administrator Access
              </p>
              <p className="mt-0.5 text-[9px] text-emerald-600">
                Only admin accounts can access this panel.
              </p>
            </div>
          </div>

          <div className="mt-5 flex items-center justify-center gap-1 text-[10px] text-slate-400">
            <MdCopyright className="text-[11px]" />
            <span>2026 PocketCrew. All rights reserved.</span>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Login;
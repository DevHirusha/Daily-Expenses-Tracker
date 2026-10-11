import { useEffect, useState } from "react";
import {
  BadgeCheck,
  CalendarDays,
  Check,
  Copy,
  KeyRound,
  Mail,
  RefreshCw,
  ShieldCheck,
  UserRound,
} from "lucide-react";
import { getCurrentAdmin, getAdmin } from "../../api/auth";

const getInitials = (name = "Admin") =>
  name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("") || "A";

const DetailRow = ({ icon: Icon, label, value, copyable = false }) => {
  const [copied, setCopied] = useState(false);

  const copyValue = async () => {
    if (!value || !navigator.clipboard) return;
    await navigator.clipboard.writeText(value);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1600);
  };

  return (
    <div className="flex items-center gap-3 rounded-xl border border-slate-700/70 bg-[#141B2D]/55 px-4 py-3.5">
      <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-indigo-500/15 text-indigo-300">
        <Icon size={17} />
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-[11px] font-medium uppercase tracking-wider text-slate-500">{label}</p>
        <p className="mt-1 truncate text-sm font-medium text-white">{value || "Not available"}</p>
      </div>
      {copyable && value && (
        <button
          type="button"
          onClick={copyValue}
          aria-label={`Copy ${label}`}
          className="rounded-lg p-2 text-slate-500 transition hover:bg-white/10 hover:text-white"
        >
          {copied ? <Check size={15} className="text-emerald-300" /> : <Copy size={15} />}
        </button>
      )}
    </div>
  );
};

const ProfileForm = () => {
  const [profile, setProfile] = useState(() => getAdmin() || {});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const loadProfile = async () => {
    setLoading(true);
    setError("");
    try {
      const { data } = await getCurrentAdmin();
      setProfile(data);
      localStorage.setItem("admin_user", JSON.stringify(data));
    } catch (requestError) {
      setError(requestError.response?.data?.message || "Unable to load the latest profile details.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const timer = window.setTimeout(loadProfile, 0);
    return () => window.clearTimeout(timer);
  }, []);

  const initials = getInitials(profile.name);
  const roleLabel = profile.role === "SUPER_ADMIN" ? "Super administrator" : "Administrator";

  return (
    <section className="space-y-6">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div>
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-indigo-500/15 text-indigo-300"><UserRound size={22} /></div>
            <div><h2 className="text-xl font-semibold text-white">Admin profile</h2><p className="mt-1 text-sm text-slate-400">Your account details and access information.</p></div>
          </div>
        </div>
        <button type="button" onClick={loadProfile} disabled={loading} className="inline-flex items-center justify-center gap-2 rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-sm font-medium text-slate-200 transition hover:border-indigo-400 hover:text-white disabled:cursor-not-allowed disabled:opacity-60"><RefreshCw size={16} className={loading ? "animate-spin" : ""} /> Refresh profile</button>
      </div>

      {error && <div className="rounded-xl border border-amber-400/25 bg-amber-400/10 px-4 py-3 text-sm text-amber-100">{error} Showing your saved session details.</div>}

      <div className="grid gap-6 xl:grid-cols-[0.8fr_1.2fr]">
        <div className="relative overflow-hidden rounded-2xl border border-indigo-400/20 bg-gradient-to-br from-[#29356c] via-[#1F2A40] to-[#182238] p-6 shadow-xl">
          <div className="absolute -right-16 -top-20 h-52 w-52 rounded-full bg-indigo-400/15 blur-3xl" />
          <div className="relative">
            <div className="flex items-center justify-between"><span className="rounded-full border border-emerald-300/20 bg-emerald-300/10 px-3 py-1 text-xs font-medium text-emerald-200">Active account</span><ShieldCheck size={21} className="text-indigo-200" /></div>
            <div className="mt-9 flex h-24 w-24 items-center justify-center rounded-[28px] border border-white/20 bg-white/10 text-3xl font-semibold text-white shadow-2xl">{initials}</div>
            <h3 className="mt-5 text-2xl font-semibold text-white">{loading ? "Loading profile..." : profile.name || "Administrator"}</h3>
            <p className="mt-1 text-sm text-indigo-100/70">{profile.email || "Admin account"}</p>
            <div className="mt-7 flex flex-wrap gap-2"><span className="inline-flex items-center gap-1.5 rounded-full bg-indigo-300/15 px-3 py-1.5 text-xs font-semibold text-indigo-100"><BadgeCheck size={14} /> {roleLabel}</span><span className="inline-flex items-center gap-1.5 rounded-full bg-white/10 px-3 py-1.5 text-xs text-slate-200"><KeyRound size={14} /> Secure access</span></div>
          </div>
        </div>

        <div className="rounded-2xl border border-slate-700/80 bg-[#1F2A40] p-5 shadow-xl sm:p-6">
          <div className="flex items-start gap-3"><div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-500/15 text-violet-300"><UserRound size={19} /></div><div><h3 className="text-lg font-semibold text-white">Profile details</h3><p className="mt-1 text-sm text-slate-400">The information associated with your admin account.</p></div></div>
          <div className="mt-6 grid gap-3 sm:grid-cols-2">
            <DetailRow icon={UserRound} label="Full name" value={profile.name} />
            <DetailRow icon={Mail} label="Email address" value={profile.email} />
            <DetailRow icon={ShieldCheck} label="Access role" value={roleLabel} />
            <DetailRow icon={BadgeCheck} label="Account status" value="Verified administrator" />
            <DetailRow icon={KeyRound} label="User ID" value={profile.userId} copyable />
            <DetailRow icon={CalendarDays} label="Session" value="JWT protected session" />
          </div>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-700/80 bg-[#1F2A40] p-5 shadow-xl sm:p-6"><div className="flex items-start gap-3"><div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-500/15 text-emerald-300"><ShieldCheck size={19} /></div><div><h3 className="text-lg font-semibold text-white">Account security</h3><p className="mt-1 text-sm text-slate-400">You are signed in with administrator permissions. Keep your session private and log out when using a shared device.</p></div></div></div>
    </section>
  );
};

export default ProfileForm;

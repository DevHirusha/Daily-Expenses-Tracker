import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Activity,
  ArrowUpRight,
  BellRing,
  BriefcaseBusiness,
  CheckCircle2,
  ChevronRight,
  CircleAlert,
  ClipboardList,
  Clock3,
  Megaphone,
  RefreshCw,
  ShieldCheck,
  Sparkles,
  TrendingUp,
  UsersRound,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import api from "../../api/axios";

const emptyData = { users: [], gigs: [], applications: [], announcements: [] };

const asArray = (value) => (Array.isArray(value) ? value : []);
const percent = (value, total) => (total > 0 ? Math.round((value / total) * 100) : 0);

const formatDate = (value) => {
  if (!value) return "Recently";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Recently";
  return new Intl.DateTimeFormat(undefined, { month: "short", day: "numeric" }).format(date);
};

const isActiveGig = (gig) => {
  if (!gig.applicationDeadline) return true;
  const deadline = new Date(`${gig.applicationDeadline}T23:59:59`);
  return Number.isNaN(deadline.getTime()) || deadline >= new Date();
};

const getGreeting = () => {
  const hour = new Date().getHours();
  if (hour < 12) return "Good morning";
  if (hour < 18) return "Good afternoon";
  return "Good evening";
};

const ProgressBar = ({ value, tone = "indigo" }) => (
  <div className="dashboard-progress-track" aria-label={`${value}% complete`}>
    <div className={`dashboard-progress-fill dashboard-progress-${tone}`} style={{ width: `${Math.min(100, Math.max(0, value))}%` }} />
  </div>
);

const MetricCard = ({ icon: Icon, label, value, detail, tone, onClick }) => (
  <button type="button" onClick={onClick} className="dashboard-metric-card group text-left">
    <div className="flex items-start justify-between gap-4">
      <div className={`dashboard-icon-badge dashboard-icon-${tone}`}><Icon size={20} strokeWidth={2.2} /></div>
      <ArrowUpRight size={17} className="text-slate-600 transition group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-white" />
    </div>
    <p className="mt-6 text-sm text-slate-400">{label}</p>
    <p className="mt-1 text-3xl font-semibold tracking-tight text-white">{value}</p>
    <p className="mt-2 text-xs text-slate-500">{detail}</p>
  </button>
);

const ProgressCard = ({ icon: Icon, label, value, detail, tone }) => (
  <div className="dashboard-progress-card">
    <div className="flex items-start justify-between gap-4">
      <div className="flex items-center gap-3">
        <div className={`dashboard-icon-badge dashboard-icon-${tone}`}><Icon size={18} /></div>
        <div><p className="text-sm font-medium text-white">{label}</p><p className="mt-1 text-xs text-slate-500">{detail}</p></div>
      </div>
      <span className="text-xl font-semibold text-white">{value}%</span>
    </div>
    <ProgressBar value={value} tone={tone} />
  </div>
);

const LoadingBlock = ({ className = "" }) => <div className={`dashboard-skeleton animate-pulse ${className}`} />;

const DashboardHome = () => {
  const navigate = useNavigate();
  const [data, setData] = useState(emptyData);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState("");
  const adminName = useMemo(() => {
    try {
      return JSON.parse(localStorage.getItem("admin_user") || "{}").name || "Administrator";
    } catch {
      return "Administrator";
    }
  }, []);

  const loadDashboard = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError("");

    const requests = await Promise.allSettled([
      api.get("/admin/users"),
      api.get("/admin/gigs"),
      api.get("/admin/gig-applications"),
      api.get("/admin/announcements"),
    ]);
    const [users, gigs, applications, announcements] = requests;

    setData({
      users: users.status === "fulfilled" ? asArray(users.value.data) : [],
      gigs: gigs.status === "fulfilled" ? asArray(gigs.value.data) : [],
      applications: applications.status === "fulfilled" ? asArray(applications.value.data) : [],
      announcements: announcements.status === "fulfilled" ? asArray(announcements.value.data) : [],
    });
    if (requests.some((request) => request.status === "rejected")) setError("Some live metrics could not be refreshed. Check the API connection and try again.");
    setLoading(false);
    setRefreshing(false);
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(loadDashboard, 0);
    return () => window.clearTimeout(timer);
  }, [loadDashboard]);

  const stats = useMemo(() => {
    const { users, gigs, applications, announcements } = data;
    const verifiedUsers = users.filter((user) => user.isAccountVerified === true).length;
    const reviewedApplications = applications.filter((application) => application.status !== "PENDING").length;
    const approvedApplications = applications.filter((application) => application.status === "APPROVED").length;
    const rejectedApplications = applications.filter((application) => application.status === "REJECTED").length;
    const pendingApplications = applications.filter((application) => application.status === "PENDING").length;
    const activeGigs = gigs.filter(isActiveGig).length;
    const completeListings = gigs.filter((gig) => ["title", "description", "category", "companyName", "companyPhoneNumber", "location"].every((field) => Boolean(gig[field]))).length;
    const recentItems = [
      ...gigs.map((gig) => ({ ...gig, itemType: "gig", itemDate: gig.createdAt })),
      ...announcements.map((announcement) => ({ ...announcement, itemType: "announcement", itemDate: announcement.createdAt })),
      ...applications.map((application) => ({ ...application, itemType: "application", itemDate: application.createdAt })),
    ].sort((a, b) => new Date(b.itemDate || 0) - new Date(a.itemDate || 0)).slice(0, 5);

    return {
      verifiedUsers,
      reviewedApplications,
      approvedApplications,
      rejectedApplications,
      pendingApplications,
      activeGigs,
      completeListings,
      announcementCount: announcements.length,
      verificationRate: percent(verifiedUsers, users.length),
      reviewRate: percent(reviewedApplications, applications.length),
      approvalRate: percent(approvedApplications, applications.length),
      listingReadiness: percent(completeListings, gigs.length),
      recentItems,
    };
  }, [data]);

  const userFirstName = adminName.split(" ")[0];

  return (
    <section className="dashboard-home space-y-6">
      <div className="dashboard-hero overflow-hidden rounded-[28px] border border-white/10 p-6 shadow-2xl shadow-indigo-950/20 sm:p-8">
        <div className="dashboard-hero-glow dashboard-hero-glow-one" />
        <div className="dashboard-hero-glow dashboard-hero-glow-two" />
        <div className="relative z-10 flex flex-col justify-between gap-8 lg:flex-row lg:items-end">
          <div className="max-w-2xl">
            <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-indigo-300/20 bg-indigo-300/10 px-3 py-1.5 text-xs font-medium text-indigo-100"><span className="dashboard-live-dot" /> Live workspace overview</div>
            <h2 className="text-3xl font-semibold tracking-tight text-white sm:text-4xl">{getGreeting()}, {userFirstName}.</h2>
            <p className="mt-3 max-w-xl text-sm leading-6 text-slate-300 sm:text-base">See what is moving across PocketCrew at a glance. Every number below is synced from your admin workspace.</p>
          </div>
          <div className="flex flex-wrap gap-3">
            <button type="button" onClick={() => loadDashboard(true)} disabled={loading || refreshing} className="inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/10 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-white/15 disabled:cursor-not-allowed disabled:opacity-60"><RefreshCw size={16} className={refreshing ? "animate-spin" : ""} />{refreshing ? "Syncing..." : "Refresh data"}</button>
            <button type="button" onClick={() => navigate("/dashboard/gigs")} className="inline-flex items-center gap-2 rounded-xl bg-white px-4 py-2.5 text-sm font-semibold text-slate-950 transition hover:bg-indigo-50">Manage workspace <ChevronRight size={16} /></button>
          </div>
        </div>
        <div className="relative z-10 mt-8 grid gap-3 border-t border-white/10 pt-5 text-xs text-slate-400 sm:grid-cols-3">
          <div className="flex items-center gap-2"><Activity size={15} className="text-emerald-300" /> API connected</div>
          <div className="flex items-center gap-2"><Clock3 size={15} className="text-indigo-300" /> Live metrics enabled</div>
          <div className="flex items-center gap-2"><Sparkles size={15} className="text-amber-300" /> Built for momentum</div>
        </div>
      </div>

      {error && <div className="flex items-start gap-3 rounded-2xl border border-amber-400/25 bg-amber-400/10 px-4 py-3 text-sm text-amber-100"><CircleAlert size={18} className="mt-0.5 shrink-0 text-amber-300" /><span>{error}</span></div>}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {loading ? Array.from({ length: 4 }).map((_, index) => <LoadingBlock key={index} className="h-48 rounded-2xl" />) : <>
          <MetricCard icon={UsersRound} label="Total users" value={data.users.length} detail={`${stats.verifiedUsers} verified accounts`} tone="indigo" onClick={() => navigate("/dashboard/users")} />
          <MetricCard icon={BriefcaseBusiness} label="Active gigs" value={stats.activeGigs} detail={`${data.gigs.length} listings in workspace`} tone="orange" onClick={() => navigate("/dashboard/gigs")} />
          <MetricCard icon={ClipboardList} label="Pending applications" value={stats.pendingApplications} detail={`${stats.approvedApplications} approved so far`} tone="emerald" onClick={() => navigate("/dashboard/gig-applications")} />
          <MetricCard icon={Megaphone} label="Announcements" value={stats.announcementCount} detail="Published workspace updates" tone="violet" onClick={() => navigate("/dashboard/announcements")} />
        </>}
      </div>

      <div className="grid gap-6 xl:grid-cols-[1.35fr_0.65fr]">
        <div className="dashboard-panel rounded-2xl border border-slate-700/80 p-5 sm:p-6">
          <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start">
            <div><div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.18em] text-indigo-300"><TrendingUp size={15} /> Workspace health</div><h3 className="mt-2 text-xl font-semibold text-white">Progress that tells a story</h3><p className="mt-1 text-sm text-slate-400">Track the areas that turn activity into momentum.</p></div>
            {!loading && <div className="rounded-xl bg-white/5 px-3 py-2 text-right"><p className="text-[10px] uppercase tracking-wider text-slate-500">Overall pulse</p><p className="mt-0.5 text-lg font-semibold text-white">{Math.round((stats.verificationRate + stats.reviewRate + stats.listingReadiness) / 3)}%</p></div>}
          </div>
          <div className="mt-7 grid gap-4 md:grid-cols-3">
            {loading ? Array.from({ length: 3 }).map((_, index) => <LoadingBlock key={index} className="h-28 rounded-2xl" />) : <>
              <ProgressCard icon={ShieldCheck} label="Account verification" value={stats.verificationRate} detail={`${stats.verifiedUsers} of ${data.users.length} users`} tone="indigo" />
              <ProgressCard icon={ClipboardList} label="Application review" value={stats.reviewRate} detail={`${stats.reviewedApplications} of ${data.applications.length} reviewed`} tone="emerald" />
              <ProgressCard icon={BriefcaseBusiness} label="Listing readiness" value={stats.listingReadiness} detail={`${stats.completeListings} of ${data.gigs.length} complete`} tone="orange" />
            </>}
          </div>
        </div>

        <div className="dashboard-panel rounded-2xl border border-slate-700/80 p-5 sm:p-6">
          <div className="flex items-start justify-between gap-3"><div><div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.18em] text-orange-300"><Activity size={15} /> Pipeline</div><h3 className="mt-2 text-xl font-semibold text-white">Application flow</h3></div><button type="button" onClick={() => navigate("/dashboard/gig-applications")} className="rounded-lg p-2 text-slate-500 transition hover:bg-white/5 hover:text-white"><ArrowUpRight size={18} /></button></div>
          {loading ? <LoadingBlock className="mt-8 h-36 rounded-2xl" /> : <div className="mt-7 space-y-5">
            {[
              { label: "Pending review", value: stats.pendingApplications, tone: "amber", icon: Clock3 },
              { label: "Approved", value: stats.approvedApplications, tone: "emerald", icon: CheckCircle2 },
              { label: "Rejected", value: stats.rejectedApplications, tone: "rose", icon: CircleAlert },
            ].map(({ label, value, tone, icon: Icon }) => <div key={label}><div className="mb-2 flex items-center justify-between text-sm"><span className="flex items-center gap-2 text-slate-300"><Icon size={15} className={`dashboard-tone-${tone}`} /> {label}</span><span className="font-semibold text-white">{value}</span></div><ProgressBar value={percent(value, data.applications.length)} tone={tone} /></div>)}
            <div className="rounded-xl border border-emerald-400/15 bg-emerald-400/5 px-3 py-2.5 text-xs text-emerald-200">{stats.approvalRate}% of all applications are approved.</div>
          </div>}
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-[1.05fr_0.95fr]">
        <div className="dashboard-panel rounded-2xl border border-slate-700/80 p-5 sm:p-6">
          <div className="flex items-start justify-between gap-3"><div><div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.18em] text-violet-300"><BellRing size={15} /> Recent activity</div><h3 className="mt-2 text-xl font-semibold text-white">What just happened</h3></div><span className="rounded-full bg-white/5 px-2.5 py-1 text-[11px] text-slate-400">Last 5 updates</span></div>
          {loading ? <div className="mt-6 space-y-3"><LoadingBlock className="h-14 rounded-xl" /><LoadingBlock className="h-14 rounded-xl" /><LoadingBlock className="h-14 rounded-xl" /></div> : stats.recentItems.length === 0 ? <div className="mt-6 rounded-xl border border-dashed border-slate-700 px-4 py-8 text-center text-sm text-slate-500">No activity yet. Your next update will appear here.</div> : <div className="mt-6 space-y-2">
            {stats.recentItems.map((item) => {
              const typeConfig = { gig: { label: "New gig listed", icon: BriefcaseBusiness, tone: "orange" }, application: { label: "Application received", icon: ClipboardList, tone: "emerald" }, announcement: { label: "Announcement published", icon: Megaphone, tone: "violet" } }[item.itemType];
              const Icon = typeConfig.icon;
              return <div key={`${item.itemType}-${item.id}`} className="flex items-center gap-3 rounded-xl px-2 py-2.5 transition hover:bg-white/[0.03]"><div className={`dashboard-icon-badge dashboard-icon-${typeConfig.tone} h-9 w-9`}><Icon size={16} /></div><div className="min-w-0 flex-1"><p className="truncate text-sm font-medium text-slate-200">{item.itemType === "application" ? item.gigTitle : item.title}</p><p className="mt-0.5 text-xs text-slate-500">{typeConfig.label} · {formatDate(item.itemDate)}</p></div><ChevronRight size={16} className="shrink-0 text-slate-600" /></div>;
            })}
          </div>}
        </div>

        <div className="dashboard-panel dashboard-panel-accent rounded-2xl border border-slate-700/80 p-5 sm:p-6">
          <div className="flex items-start justify-between gap-3"><div><div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.18em] text-amber-300"><Sparkles size={15} /> Focus area</div><h3 className="mt-2 text-xl font-semibold text-white">Keep the flywheel moving</h3></div><div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-300/10 text-amber-200"><Activity size={19} /></div></div>
          <p className="mt-4 text-sm leading-6 text-slate-400">Your fastest win is clearing the application queue and completing the details on every gig listing.</p>
          <div className="mt-6 space-y-4"><div className="rounded-xl border border-white/10 bg-black/10 p-3.5"><div className="flex items-center justify-between gap-3"><span className="text-sm text-slate-300">Review queue</span><span className="text-sm font-semibold text-amber-200">{stats.pendingApplications} waiting</span></div><ProgressBar value={stats.reviewRate} tone="amber" /></div><div className="rounded-xl border border-white/10 bg-black/10 p-3.5"><div className="flex items-center justify-between gap-3"><span className="text-sm text-slate-300">Profiled listings</span><span className="text-sm font-semibold text-orange-200">{stats.listingReadiness}% ready</span></div><ProgressBar value={stats.listingReadiness} tone="orange" /></div></div>
          <button type="button" onClick={() => navigate(stats.pendingApplications > 0 ? "/dashboard/gig-applications" : "/dashboard/gigs")} className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-white transition hover:text-amber-200">{stats.pendingApplications > 0 ? "Review applications" : "Polish listings"} <ArrowUpRight size={16} /></button>
        </div>
      </div>
    </section>
  );
};

export default DashboardHome;

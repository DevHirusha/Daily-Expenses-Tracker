import { useCallback, useEffect, useMemo, useState } from "react";
import { Briefcase, CheckCircle2, ClipboardList, RefreshCw, Search, UserRound, XCircle } from "lucide-react";
import api from "../../api/axios";

const getErrorMessage = (error, fallback) =>
  error.response?.data?.message ||
  (typeof error.response?.data === "string" ? error.response.data : null) ||
  fallback;

const statusStyles = {
  PENDING: "bg-amber-500/15 text-amber-200",
  APPROVED: "bg-emerald-500/15 text-emerald-200",
  REJECTED: "bg-red-500/15 text-red-200",
};

const formatDate = (value) => {
  if (!value) return "Not available";
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
};

const GigApplications = () => {
  const [applications, setApplications] = useState([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState(null);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  const loadApplications = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const { data } = await api.get("/admin/gig-applications");
      setApplications(data);
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to load gig applications."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(loadApplications, 0);
    return () => window.clearTimeout(timer);
  }, [loadApplications]);

  const filteredApplications = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return applications;
    return applications.filter((application) =>
      [
        application.gigTitle,
        application.companyName,
        application.applicantName,
        application.applicantUsername,
        application.applicantEmail,
        application.status,
      ].some((value) => value?.toLowerCase().includes(query)),
    );
  }, [applications, search]);

  const updateStatus = async (application, status) => {
    setUpdatingId(application.id);
    setError("");
    setNotice("");
    try {
      const { data } = await api.patch(`/admin/gig-applications/${application.id}/status`, { status });
      setApplications((current) => current.map((item) => (item.id === data.id ? data : item)));
      setNotice(status === "APPROVED" ? "Application approved." : "Application rejected.");
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to update application status."));
    } finally {
      setUpdatingId(null);
    }
  };

  return (
    <section className="space-y-6">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-orange-500/15 text-orange-300"><ClipboardList size={22} /></div>
          <div><h2 className="text-xl font-semibold text-white">Gig Applications</h2><p className="text-sm text-slate-400">Review applications submitted by users.</p></div>
        </div>
        <button type="button" onClick={loadApplications} disabled={loading} className="inline-flex items-center justify-center gap-2 rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-sm font-medium text-slate-200 transition hover:border-orange-400 hover:text-white disabled:cursor-not-allowed disabled:opacity-60"><RefreshCw size={16} className={loading ? "animate-spin" : ""} /> Refresh</button>
      </div>

      {error && <div className="rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">{error}</div>}
      {notice && <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-200">{notice}</div>}

      <div className="overflow-hidden rounded-2xl border border-slate-700/80 bg-[#1F2A40] shadow-xl">
        <div className="flex flex-col gap-3 border-b border-slate-700/80 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div><p className="text-sm font-semibold text-white">Submitted applications</p><p className="mt-1 text-xs text-slate-400">{filteredApplications.length} of {applications.length} applications</p></div>
          <label className="relative block sm:w-80"><Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search user or gig..." className="w-full rounded-lg border border-slate-700 bg-[#141B2D] py-2 pl-9 pr-3 text-sm text-white outline-none placeholder:text-slate-500 focus:border-orange-400" /></label>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[1120px] text-left text-sm">
            <thead className="bg-[#141B2D]/70 text-xs uppercase tracking-wide text-slate-400"><tr><th className="px-5 py-4 font-medium">Applicant</th><th className="px-5 py-4 font-medium">Gig</th><th className="px-5 py-4 font-medium">Application details</th><th className="px-5 py-4 font-medium">Status</th><th className="px-5 py-4 text-right font-medium">Actions</th></tr></thead>
            <tbody className="divide-y divide-slate-700/70">
              {loading ? <tr><td colSpan="5" className="px-5 py-12 text-center text-slate-400">Loading applications...</td></tr> : filteredApplications.length === 0 ? <tr><td colSpan="5" className="px-5 py-12 text-center text-slate-400">No gig applications found.</td></tr> : filteredApplications.map((application) => {
                const pending = application.status === "PENDING";
                const updating = updatingId === application.id;
                return (
                  <tr key={application.id} className="transition hover:bg-white/[0.03]">
                    <td className="px-5 py-4"><p className="flex items-center gap-1.5 font-medium text-slate-200"><UserRound size={15} />{application.applicantName || application.applicantUsername || "User"}</p><p className="mt-1 text-xs text-slate-400">{application.applicantEmail}</p></td>
                    <td className="px-5 py-4"><p className="flex items-center gap-1.5 font-medium text-white"><Briefcase size={15} />{application.gigTitle}</p><p className="mt-1 text-xs text-slate-400">{application.companyName || "Company"} · {application.location || "Flexible"}</p></td>
                    <td className="max-w-sm px-5 py-4"><p className="text-xs text-slate-300"><span className="font-semibold text-slate-200">Available:</span> {application.availableFrom || "Not specified"}</p><p className="mt-1 line-clamp-2 text-xs text-slate-400">{application.note || "No note provided."}</p><p className="mt-1 text-[11px] text-slate-500">Submitted {formatDate(application.createdAt)}</p></td>
                    <td className="px-5 py-4"><span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${statusStyles[application.status] || "bg-slate-700 text-slate-200"}`}>{application.status}</span></td>
                    <td className="px-5 py-4"><div className="flex justify-end gap-2">{pending ? <><button type="button" onClick={() => updateStatus(application, "APPROVED")} disabled={updating} className="inline-flex items-center gap-1.5 rounded-lg border border-emerald-500/30 px-3 py-2 text-xs font-semibold text-emerald-300 transition hover:bg-emerald-500/10 disabled:cursor-not-allowed disabled:opacity-50"><CheckCircle2 size={14} /> Approve</button><button type="button" onClick={() => updateStatus(application, "REJECTED")} disabled={updating} className="inline-flex items-center gap-1.5 rounded-lg border border-red-500/30 px-3 py-2 text-xs font-semibold text-red-300 transition hover:bg-red-500/10 disabled:cursor-not-allowed disabled:opacity-50"><XCircle size={14} /> Reject</button></> : <span className="text-xs text-slate-500">Reviewed</span>}</div></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
};

export default GigApplications;

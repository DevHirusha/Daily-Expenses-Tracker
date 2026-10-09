import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Megaphone,
  Pencil,
  RefreshCw,
  Search,
  Trash2,
  UserRound,
  X,
} from "lucide-react";
import api from "../../api/axios";

const emptyForm = { title: "", message: "" };

const getErrorMessage = (error, fallback) =>
  error.response?.data?.message ||
  (typeof error.response?.data === "string" ? error.response.data : null) ||
  fallback;

const AnnouncementManagement = () => {
  const [announcements, setAnnouncements] = useState([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [deletingId, setDeletingId] = useState(null);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [editingAnnouncement, setEditingAnnouncement] = useState(null);
  const [isCreating, setIsCreating] = useState(false);
  const [form, setForm] = useState(emptyForm);

  const loadAnnouncements = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const { data } = await api.get("/admin/announcements");
      setAnnouncements(data);
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to load announcements."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(loadAnnouncements, 0);
    return () => window.clearTimeout(timer);
  }, [loadAnnouncements]);

  const filteredAnnouncements = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return announcements;
    return announcements.filter((announcement) =>
      [announcement.title, announcement.message, announcement.createdByName, announcement.createdByEmail].some((value) =>
        value?.toLowerCase().includes(query),
      ),
    );
  }, [announcements, search]);

  const openAdd = () => {
    setError("");
    setNotice("");
    setEditingAnnouncement(null);
    setIsCreating(true);
    setForm(emptyForm);
  };

  const openEdit = (announcement) => {
    setError("");
    setNotice("");
    setEditingAnnouncement(announcement);
    setIsCreating(false);
    setForm({ title: announcement.title || "", message: announcement.message || "" });
  };

  const closeModal = () => {
    if (!saving) {
      setEditingAnnouncement(null);
      setIsCreating(false);
      setForm(emptyForm);
    }
  };

  const handleChange = (event) => {
    const { name, value } = event.target;
    setForm((current) => ({ ...current, [name]: value }));
  };

  const handleSave = async (event) => {
    event.preventDefault();
    setSaving(true);
    setError("");
    setNotice("");
    try {
      const { data } = isCreating
        ? await api.post("/admin/announcements", form)
        : await api.put(`/admin/announcements/${editingAnnouncement.id}`, form);
      setAnnouncements((current) =>
        isCreating
          ? [data, ...current]
          : current.map((announcement) => (announcement.id === data.id ? data : announcement)),
      );
      setEditingAnnouncement(null);
      setIsCreating(false);
      setForm(emptyForm);
      setNotice(isCreating ? "Announcement added successfully." : "Announcement updated successfully.");
    } catch (requestError) {
      setError(getErrorMessage(requestError, isCreating ? "Unable to add announcement." : "Unable to update announcement."));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (announcement) => {
    if (!window.confirm(`Delete ${announcement.title}? This cannot be undone.`)) return;
    setDeletingId(announcement.id);
    setError("");
    setNotice("");
    try {
      await api.delete(`/admin/announcements/${announcement.id}`);
      setAnnouncements((current) => current.filter((item) => item.id !== announcement.id));
      setNotice("Announcement deleted successfully.");
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to delete announcement."));
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <section className="space-y-6">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-violet-500/15 text-violet-300"><Megaphone size={22} /></div>
          <div><h2 className="text-xl font-semibold text-white">Announcement Management</h2><p className="text-sm text-slate-400">Publish important updates for your users.</p></div>
        </div>
        <div className="flex gap-2">
          <button type="button" onClick={openAdd} className="inline-flex items-center justify-center gap-2 rounded-lg bg-violet-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-violet-500"><span className="text-lg leading-none">+</span> Add announcement</button>
          <button type="button" onClick={loadAnnouncements} disabled={loading} className="inline-flex items-center justify-center gap-2 rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-sm font-medium text-slate-200 transition hover:border-violet-400 hover:text-white disabled:cursor-not-allowed disabled:opacity-60"><RefreshCw size={16} className={loading ? "animate-spin" : ""} /> Refresh</button>
        </div>
      </div>

      {error && <div className="rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">{error}</div>}
      {notice && <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-200">{notice}</div>}

      <div className="overflow-hidden rounded-2xl border border-slate-700/80 bg-[#1F2A40] shadow-xl">
        <div className="flex flex-col gap-3 border-b border-slate-700/80 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div><p className="text-sm font-semibold text-white">All announcements</p><p className="mt-1 text-xs text-slate-400">{filteredAnnouncements.length} of {announcements.length} announcements</p></div>
          <label className="relative block sm:w-80"><Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search announcements..." className="w-full rounded-lg border border-slate-700 bg-[#141B2D] py-2 pl-9 pr-3 text-sm text-white outline-none placeholder:text-slate-500 focus:border-violet-400" /></label>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[850px] text-left text-sm">
            <thead className="bg-[#141B2D]/70 text-xs uppercase tracking-wide text-slate-400"><tr><th className="px-5 py-4 font-medium">Announcement</th><th className="px-5 py-4 font-medium">Created by</th><th className="px-5 py-4 font-medium">Created</th><th className="px-5 py-4 text-right font-medium">Actions</th></tr></thead>
            <tbody className="divide-y divide-slate-700/70">
              {loading ? <tr><td colSpan="4" className="px-5 py-12 text-center text-slate-400">Loading announcements...</td></tr> : filteredAnnouncements.length === 0 ? <tr><td colSpan="4" className="px-5 py-12 text-center text-slate-400">No announcements found. Add the first announcement.</td></tr> : filteredAnnouncements.map((announcement) => (
                <tr key={announcement.id} className="transition hover:bg-white/[0.03]">
                  <td className="max-w-xl px-5 py-4"><p className="font-medium text-white">{announcement.title}</p><p className="mt-1 line-clamp-2 text-xs text-slate-400">{announcement.message}</p></td>
                  <td className="px-5 py-4"><p className="flex items-center gap-1.5 text-slate-200"><UserRound size={14} />{announcement.createdByName}</p><p className="mt-1 text-xs text-slate-400">{announcement.createdByEmail}</p></td>
                  <td className="px-5 py-4 text-slate-300">{announcement.createdAt ? new Date(announcement.createdAt).toLocaleDateString() : "—"}</td>
                  <td className="px-5 py-4"><div className="flex justify-end gap-2"><button type="button" onClick={() => openEdit(announcement)} className="inline-flex items-center gap-1.5 rounded-lg border border-slate-600 px-3 py-2 text-xs font-semibold text-slate-200 transition hover:border-violet-400 hover:bg-violet-500/10 hover:text-white"><Pencil size={14} /> Edit</button><button type="button" onClick={() => handleDelete(announcement)} disabled={deletingId === announcement.id} className="inline-flex items-center gap-1.5 rounded-lg border border-red-500/30 px-3 py-2 text-xs font-semibold text-red-300 transition hover:bg-red-500/10 disabled:cursor-not-allowed disabled:opacity-50"><Trash2 size={14} />{deletingId === announcement.id ? "Deleting..." : "Delete"}</button></div></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {(editingAnnouncement || isCreating) && <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/75 p-4 backdrop-blur-sm"><div className="w-full max-w-xl rounded-2xl border border-slate-700 bg-[#1F2A40] shadow-2xl"><div className="flex items-center justify-between border-b border-slate-700 px-5 py-4"><div><h3 className="font-semibold text-white">{isCreating ? "Add announcement" : "Edit announcement"}</h3><p className="mt-1 text-xs text-slate-400">Write an update that users can read.</p></div><button type="button" onClick={closeModal} className="rounded-lg p-2 text-slate-400 hover:bg-slate-700 hover:text-white"><X size={18} /></button></div><form onSubmit={handleSave} className="space-y-4 p-5"><label className="block text-xs font-medium text-slate-300">Title<input name="title" value={form.title} onChange={handleChange} required maxLength="160" placeholder="System maintenance notice" className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none placeholder:text-slate-500 focus:border-violet-400" /></label><label className="block text-xs font-medium text-slate-300">Message<textarea name="message" value={form.message} onChange={handleChange} required maxLength="10000" rows="7" placeholder="Write the announcement message..." className="mt-1.5 w-full resize-y rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none placeholder:text-slate-500 focus:border-violet-400" /></label><div className="flex justify-end gap-3 border-t border-slate-700 pt-4"><button type="button" onClick={closeModal} disabled={saving} className="rounded-lg px-4 py-2.5 text-sm font-medium text-slate-300 hover:bg-slate-700">Cancel</button><button type="submit" disabled={saving} className="rounded-lg bg-violet-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-60">{saving ? "Saving..." : isCreating ? "Add announcement" : "Save changes"}</button></div></form></div></div>}
    </section>
  );
};

export default AnnouncementManagement;

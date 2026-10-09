import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Briefcase,
  ImagePlus,
  MapPin,
  Pencil,
  RefreshCw,
  Search,
  Trash2,
  Upload,
  UserRound,
  X,
} from "lucide-react";
import api from "../../api/axios";

const emptyForm = {
  title: "",
  description: "",
  requirements: "",
  category: "ONLINE",
  estimatedEarnings: "",
  location: "",
  companyName: "",
  companyPhoneNumber: "",
  imageData: "",
  imageName: "",
};

const getErrorMessage = (error, fallback) =>
  error.response?.data?.message ||
  (typeof error.response?.data === "string" ? error.response.data : null) ||
  fallback;

const GigManagement = () => {
  const [gigs, setGigs] = useState([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [deletingId, setDeletingId] = useState(null);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [editingGig, setEditingGig] = useState(null);
  const [isCreating, setIsCreating] = useState(false);
  const [form, setForm] = useState(emptyForm);

  const loadGigs = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const { data } = await api.get("/admin/gigs");
      setGigs(data);
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to load gigs."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(loadGigs, 0);
    return () => window.clearTimeout(timer);
  }, [loadGigs]);

  const filteredGigs = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return gigs;
    return gigs.filter((gig) =>
      [gig.title, gig.description, gig.category, gig.location, gig.companyName, gig.companyPhoneNumber, gig.createdByName, gig.createdByEmail].some((value) =>
        value?.toLowerCase().includes(query),
      ),
    );
  }, [gigs, search]);

  const openAdd = () => {
    setNotice("");
    setError("");
    setEditingGig(null);
    setIsCreating(true);
    setForm(emptyForm);
  };

  const openEdit = (gig) => {
    setNotice("");
    setError("");
    setEditingGig(gig);
    setIsCreating(false);
    setForm({
      title: gig.title || "",
      description: gig.description || "",
      requirements: gig.requirements || "",
      category: gig.category || "ONLINE",
      estimatedEarnings: gig.estimatedEarnings || "",
      location: gig.location || "",
      companyName: gig.companyName || "",
      companyPhoneNumber: gig.companyPhoneNumber || "",
      imageData: gig.imageData || "",
      imageName: "Current image",
    });
  };

  const closeModal = () => {
    if (!saving) {
      setEditingGig(null);
      setIsCreating(false);
      setForm(emptyForm);
    }
  };

  const handleChange = (event) => {
    const { name, value } = event.target;
    setForm((current) => ({ ...current, [name]: value }));
  };

  const handleImageChange = (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      setError("Photo must be smaller than 5 MB.");
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      setForm((current) => ({ ...current, imageData: reader.result, imageName: file.name }));
      setError("");
    };
    reader.readAsDataURL(file);
  };

  const removeImage = () => {
    setForm((current) => ({ ...current, imageData: "", imageName: "" }));
  };

  const handleSave = async (event) => {
    event.preventDefault();
    setSaving(true);
    setError("");
    setNotice("");

    try {
      const payload = { ...form };
      delete payload.imageName;
      payload.imageData = payload.imageData || null;
      const { data } = isCreating
        ? await api.post("/admin/gigs", payload)
        : await api.put(`/admin/gigs/${editingGig.id}`, payload);

      setGigs((current) =>
        isCreating ? [data, ...current] : current.map((gig) => (gig.id === data.id ? data : gig)),
      );
      setEditingGig(null);
      setIsCreating(false);
      setForm(emptyForm);
      setNotice(isCreating ? "Gig added successfully." : "Gig updated successfully.");
    } catch (requestError) {
      setError(getErrorMessage(requestError, isCreating ? "Unable to add gig." : "Unable to update gig."));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (gig) => {
    if (!window.confirm(`Delete ${gig.title}? This cannot be undone.`)) return;

    setDeletingId(gig.id);
    setError("");
    setNotice("");
    try {
      await api.delete(`/admin/gigs/${gig.id}`);
      setGigs((current) => current.filter((item) => item.id !== gig.id));
      setNotice("Gig deleted successfully.");
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to delete gig."));
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <section className="space-y-6">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-orange-500/15 text-orange-300"><Briefcase size={22} /></div>
          <div><h2 className="text-xl font-semibold text-white">Gigs Management</h2><p className="text-sm text-slate-400">Create and manage gig advertisements.</p></div>
        </div>
        <div className="flex gap-2">
          <button type="button" onClick={openAdd} className="inline-flex items-center justify-center gap-2 rounded-lg bg-orange-500 px-4 py-2 text-sm font-semibold text-white transition hover:bg-orange-400"><span className="text-lg leading-none">+</span> Add gig</button>
          <button type="button" onClick={loadGigs} disabled={loading} className="inline-flex items-center justify-center gap-2 rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-sm font-medium text-slate-200 transition hover:border-orange-400 hover:text-white disabled:cursor-not-allowed disabled:opacity-60"><RefreshCw size={16} className={loading ? "animate-spin" : ""} /> Refresh</button>
        </div>
      </div>

      {error && <div className="rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">{error}</div>}
      {notice && <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-200">{notice}</div>}

      <div className="overflow-hidden rounded-2xl border border-slate-700/80 bg-[#1F2A40] shadow-xl">
        <div className="flex flex-col gap-3 border-b border-slate-700/80 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div><p className="text-sm font-semibold text-white">Gig advertisements</p><p className="mt-1 text-xs text-slate-400">{filteredGigs.length} of {gigs.length} gigs</p></div>
          <label className="relative block sm:w-80"><Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search gigs, category, user..." className="w-full rounded-lg border border-slate-700 bg-[#141B2D] py-2 pl-9 pr-3 text-sm text-white outline-none placeholder:text-slate-500 focus:border-orange-400" /></label>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[980px] text-left text-sm">
            <thead className="bg-[#141B2D]/70 text-xs uppercase tracking-wide text-slate-400"><tr><th className="px-5 py-4 font-medium">Gig</th><th className="px-5 py-4 font-medium">Company</th><th className="px-5 py-4 font-medium">Category</th><th className="px-5 py-4 font-medium">Earnings / location</th><th className="px-5 py-4 font-medium">Created by</th><th className="px-5 py-4 text-right font-medium">Actions</th></tr></thead>
            <tbody className="divide-y divide-slate-700/70">
              {loading ? <tr><td colSpan="6" className="px-5 py-12 text-center text-slate-400">Loading gigs...</td></tr> : filteredGigs.length === 0 ? <tr><td colSpan="6" className="px-5 py-12 text-center text-slate-400">No gigs found. Add the first gig advertisement.</td></tr> : filteredGigs.map((gig) => (
                <tr key={gig.id} className="transition hover:bg-white/[0.03]">
                  <td className="max-w-sm px-5 py-4"><div className="flex items-center gap-3">{gig.imageData ? <img src={gig.imageData} alt={gig.title} className="h-14 w-20 rounded-lg object-cover ring-1 ring-white/10" /> : <div className="flex h-14 w-20 items-center justify-center rounded-lg bg-slate-800 text-slate-500"><ImagePlus size={20} /></div>}<div className="min-w-0"><p className="truncate font-medium text-white">{gig.title}</p><p className="mt-1 line-clamp-2 text-xs text-slate-400">{gig.description}</p></div></div></td>
                  <td className="px-5 py-4"><p className="font-medium text-slate-200">{gig.companyName || "—"}</p><p className="mt-1 text-xs text-slate-400">{gig.companyPhoneNumber || "No phone"}</p></td>
                  <td className="px-5 py-4"><span className="rounded-full bg-orange-500/15 px-2.5 py-1 text-xs font-semibold text-orange-200">{gig.category}</span></td>
                  <td className="px-5 py-4"><p className="text-slate-200">{gig.estimatedEarnings || "—"}</p><p className="mt-1 flex items-center gap-1 text-xs text-slate-400"><MapPin size={12} />{gig.location || "Flexible"}</p></td>
                  <td className="px-5 py-4"><p className="flex items-center gap-1.5 text-slate-200"><UserRound size={14} />{gig.createdByName}</p><p className="mt-1 text-xs text-slate-400">{gig.createdByEmail}</p></td>
                  <td className="px-5 py-4"><div className="flex justify-end gap-2"><button type="button" onClick={() => openEdit(gig)} className="inline-flex items-center gap-1.5 rounded-lg border border-slate-600 px-3 py-2 text-xs font-semibold text-slate-200 transition hover:border-orange-400 hover:bg-orange-500/10 hover:text-white"><Pencil size={14} /> Edit</button><button type="button" onClick={() => handleDelete(gig)} disabled={deletingId === gig.id} className="inline-flex items-center gap-1.5 rounded-lg border border-red-500/30 px-3 py-2 text-xs font-semibold text-red-300 transition hover:bg-red-500/10 disabled:cursor-not-allowed disabled:opacity-50"><Trash2 size={14} />{deletingId === gig.id ? "Deleting..." : "Delete"}</button></div></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {(editingGig || isCreating) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center overflow-y-auto bg-slate-950/75 p-4 backdrop-blur-sm">
          <div className="my-8 w-full max-w-2xl rounded-2xl border border-slate-700 bg-[#1F2A40] shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-700 px-5 py-4"><div><h3 className="font-semibold text-white">{isCreating ? "Add gig advertisement" : "Edit gig advertisement"}</h3><p className="mt-1 text-xs text-slate-400">Store the gig details, creator, category, and photo.</p></div><button type="button" onClick={closeModal} className="rounded-lg p-2 text-slate-400 hover:bg-slate-700 hover:text-white"><X size={18} /></button></div>
            <form onSubmit={handleSave} className="space-y-4 p-5">
              <div className="grid gap-4 sm:grid-cols-2"><label className="text-xs font-medium text-slate-300">Gig title<input name="title" value={form.title} onChange={handleChange} required maxLength="120" placeholder="e.g. Delivery rider" className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none placeholder:text-slate-500 focus:border-orange-400" /></label><label className="text-xs font-medium text-slate-300">Category<select name="category" value={form.category} onChange={handleChange} required className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none focus:border-orange-400"><option value="ONLINE">Online</option><option value="HYBRID">Hybrid</option><option value="ONSITE">Onsite</option></select></label></div>
              <label className="block text-xs font-medium text-slate-300">Description<textarea name="description" value={form.description} onChange={handleChange} required maxLength="5000" rows="4" placeholder="Describe the gig and responsibilities..." className="mt-1.5 w-full resize-y rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none placeholder:text-slate-500 focus:border-orange-400" /></label>
              <label className="block text-xs font-medium text-slate-300">Requirements<textarea name="requirements" value={form.requirements} onChange={handleChange} maxLength="5000" rows="3" placeholder="List requirements, one per line..." className="mt-1.5 w-full resize-y rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none placeholder:text-slate-500 focus:border-orange-400" /></label>
              <div className="grid gap-4 sm:grid-cols-2"><label className="text-xs font-medium text-slate-300">Estimated earnings<input name="estimatedEarnings" value={form.estimatedEarnings} onChange={handleChange} maxLength="100" placeholder="Rs 1,800/day" className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none placeholder:text-slate-500 focus:border-orange-400" /></label><label className="text-xs font-medium text-slate-300">Location<input name="location" value={form.location} onChange={handleChange} maxLength="150" placeholder="Colombo 5 or remote" className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none placeholder:text-slate-500 focus:border-orange-400" /></label></div>
              <div className="grid gap-4 sm:grid-cols-2"><label className="text-xs font-medium text-slate-300">Company name<input name="companyName" value={form.companyName} onChange={handleChange} required maxLength="150" placeholder="QuickBite Ltd" className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none placeholder:text-slate-500 focus:border-orange-400" /></label><label className="text-xs font-medium text-slate-300">Company phone number<input name="companyPhoneNumber" type="tel" value={form.companyPhoneNumber} onChange={handleChange} required maxLength="30" placeholder="+94 77 123 4567" className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none placeholder:text-slate-500 focus:border-orange-400" /></label></div>
              <div><p className="text-xs font-medium text-slate-300">Gig photo</p><div className="mt-1.5 flex flex-wrap items-center gap-3"><label className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-dashed border-slate-600 bg-[#141B2D] px-4 py-3 text-sm text-slate-300 transition hover:border-orange-400 hover:text-white"><Upload size={16} /> {form.imageData ? "Replace photo" : "Upload photo"}<input type="file" accept="image/png,image/jpeg,image/webp" onChange={handleImageChange} className="hidden" /></label>{form.imageData && <><img src={form.imageData} alt="Gig preview" className="h-16 w-24 rounded-lg object-cover ring-1 ring-white/10" /><button type="button" onClick={removeImage} className="text-xs font-medium text-red-300 hover:text-red-200">Remove</button></>}{form.imageName && <span className="text-xs text-slate-500">{form.imageName}</span>}</div><p className="mt-1 text-[11px] text-slate-500">PNG, JPG, or WebP up to 5 MB.</p></div>
              <div className="flex justify-end gap-3 border-t border-slate-700 pt-4"><button type="button" onClick={closeModal} disabled={saving} className="rounded-lg px-4 py-2.5 text-sm font-medium text-slate-300 hover:bg-slate-700">Cancel</button><button type="submit" disabled={saving} className="rounded-lg bg-orange-500 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-orange-400 disabled:cursor-not-allowed disabled:opacity-60">{saving ? "Saving..." : isCreating ? "Add gig" : "Save changes"}</button></div>
            </form>
          </div>
        </div>
      )}
    </section>
  );
};

export default GigManagement;

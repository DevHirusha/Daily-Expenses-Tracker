import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Pencil,
  RefreshCw,
  Search,
  ShieldCheck,
  Trash2,
  UserRound,
  UsersRound,
  X,
} from "lucide-react";
import api from "../../api/axios";

const emptyForm = {
  name: "",
  username: "",
  email: "",
  role: "USER",
  isAccountVerified: false,
  password: "",
};

const getErrorMessage = (error, fallback) =>
  error.response?.data?.message ||
  (typeof error.response?.data === "string" ? error.response.data : null) ||
  fallback;

const isCurrentUserSuperAdmin = () => {
  try {
    return JSON.parse(localStorage.getItem("admin_user") || "{}").role === "SUPER_ADMIN";
  } catch {
    return false;
  }
};

const ManageUsers = () => {
  const isSuperAdmin = isCurrentUserSuperAdmin();
  const [users, setUsers] = useState([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [deletingId, setDeletingId] = useState(null);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [editingUser, setEditingUser] = useState(null);
  const [isCreating, setIsCreating] = useState(false);
  const [form, setForm] = useState(emptyForm);

  const loadUsers = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const { data } = await api.get("/admin/users");
      setUsers(data);
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to load users."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(loadUsers, 0);
    return () => window.clearTimeout(timer);
  }, [loadUsers]);

  const filteredUsers = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return users;
    return users.filter((user) =>
      [user.name, user.username, user.email, user.role].some((value) =>
        value?.toLowerCase().includes(query),
      ),
    );
  }, [search, users]);

  const openEdit = (user) => {
    setNotice("");
    setError("");
    setIsCreating(false);
    setEditingUser(user);
    setForm({
      name: user.name || "",
      username: user.username || "",
      email: user.email || "",
      role: user.role || "USER",
      isAccountVerified: user.isAccountVerified === true,
      password: "",
    });
  };

  const openAdd = () => {
    setNotice("");
    setError("");
    setEditingUser(null);
    setIsCreating(true);
    setForm({ ...emptyForm, isAccountVerified: false });
  };

  const closeEdit = () => {
    if (!saving) {
      setEditingUser(null);
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
      const payload = { ...form };
      if (!payload.password) delete payload.password;
      if (!isSuperAdmin) {
        delete payload.role;
        delete payload.isAccountVerified;
      }
      const { data } = isCreating
        ? await api.post("/admin/users", payload)
        : await api.put(`/admin/users/${editingUser.id}`, payload);
      setUsers((current) =>
        isCreating
          ? [data, ...current]
          : current.map((user) => (user.id === data.id ? data : user)),
      );
      setEditingUser(null);
      setIsCreating(false);
      setForm(emptyForm);
      setNotice(isCreating ? "User added successfully." : "User updated successfully.");
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to update user."));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (user) => {
    if (!window.confirm(`Delete ${user.name || user.email}? This cannot be undone.`)) {
      return;
    }

    setDeletingId(user.id);
    setError("");
    setNotice("");
    try {
      await api.delete(`/admin/users/${user.id}`);
      setUsers((current) => current.filter((item) => item.id !== user.id));
      setNotice("User deleted successfully.");
    } catch (requestError) {
      setError(getErrorMessage(requestError, "Unable to delete user."));
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <section className="space-y-6">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-indigo-500/15 text-indigo-300">
              <UsersRound size={22} />
            </div>
            <div>
              <h2 className="text-xl font-semibold text-white">Manage Users</h2>
              <p className="text-sm text-slate-400">View, edit, and remove platform users.</p>
            </div>
          </div>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={openAdd}
            className="inline-flex items-center justify-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-indigo-500"
          >
            Add user
          </button>
          <button
            type="button"
            onClick={loadUsers}
            disabled={loading}
            className="inline-flex items-center justify-center gap-2 rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-sm font-medium text-slate-200 transition hover:border-indigo-400 hover:text-white disabled:cursor-not-allowed disabled:opacity-60"
          >
            <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
            Refresh
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
          {error}
        </div>
      )}
      {notice && (
        <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-200">
          {notice}
        </div>
      )}

      <div className="overflow-hidden rounded-2xl border border-slate-700/80 bg-[#1F2A40] shadow-xl">
        <div className="flex flex-col gap-3 border-b border-slate-700/80 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-semibold text-white">All users</p>
            <p className="mt-1 text-xs text-slate-400">{filteredUsers.length} of {users.length} users</p>
          </div>
          <label className="relative block sm:w-72">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search users..."
              className="w-full rounded-lg border border-slate-700 bg-[#141B2D] py-2 pl-9 pr-3 text-sm text-white outline-none placeholder:text-slate-500 focus:border-indigo-400"
            />
          </label>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px] text-left text-sm">
            <thead className="bg-[#141B2D]/70 text-xs uppercase tracking-wide text-slate-400">
              <tr>
                <th className="px-5 py-4 font-medium">User</th>
                <th className="px-5 py-4 font-medium">Email</th>
                <th className="px-5 py-4 font-medium">Role</th>
                <th className="px-5 py-4 font-medium">Status</th>
                <th className="px-5 py-4 text-right font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/70">
              {loading ? (
                <tr><td colSpan="5" className="px-5 py-12 text-center text-slate-400">Loading users...</td></tr>
              ) : filteredUsers.length === 0 ? (
                <tr><td colSpan="5" className="px-5 py-12 text-center text-slate-400">No users found.</td></tr>
              ) : filteredUsers.map((user) => (
                <tr key={user.id} className="transition hover:bg-white/[0.03]">
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-indigo-500/20 text-indigo-200">
                        <UserRound size={18} />
                      </div>
                      <div>
                        <p className="font-medium text-white">{user.name || "Unnamed user"}</p>
                        <p className="text-xs text-slate-400">@{user.username}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-4 text-slate-300">{user.email}</td>
                  <td className="px-5 py-4">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-indigo-500/15 px-2.5 py-1 text-xs font-semibold text-indigo-200">
                      {user.role === "SUPER_ADMIN" && <ShieldCheck size={13} />}
                      {user.role}
                    </span>
                  </td>
                  <td className="px-5 py-4">
                    <span className={user.isAccountVerified ? "text-emerald-300" : "text-amber-300"}>
                      {user.isAccountVerified ? "Verified" : "Pending"}
                    </span>
                  </td>
                  <td className="px-5 py-4">
                    <div className="flex justify-end gap-2">
                      <button type="button" onClick={() => openEdit(user)} className="inline-flex items-center gap-1.5 rounded-lg border border-slate-600 px-3 py-2 text-xs font-semibold text-slate-200 transition hover:border-indigo-400 hover:bg-indigo-500/10 hover:text-white">
                        <Pencil size={14} /> Edit
                      </button>
                      <button type="button" onClick={() => handleDelete(user)} disabled={deletingId === user.id} className="inline-flex items-center gap-1.5 rounded-lg border border-red-500/30 px-3 py-2 text-xs font-semibold text-red-300 transition hover:bg-red-500/10 disabled:cursor-not-allowed disabled:opacity-50">
                        <Trash2 size={14} /> {deletingId === user.id ? "Deleting..." : "Delete"}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {(editingUser || isCreating) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/75 p-4 backdrop-blur-sm">
          <div className="w-full max-w-lg rounded-2xl border border-slate-700 bg-[#1F2A40] shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-700 px-5 py-4">
              <div>
                <h3 className="font-semibold text-white">{isCreating ? "Add user" : "Edit user"}</h3>
                <p className="mt-1 text-xs text-slate-400">{isCreating ? "Create a new platform user." : "Update account details and permissions."}</p>
              </div>
              <button type="button" onClick={closeEdit} className="rounded-lg p-2 text-slate-400 hover:bg-slate-700 hover:text-white"><X size={18} /></button>
            </div>
            <form onSubmit={handleSave} className="space-y-4 p-5">
              <div className="grid gap-4 sm:grid-cols-2">
                <label className="text-xs font-medium text-slate-300">Name<input name="name" value={form.name} onChange={handleChange} required className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none focus:border-indigo-400" /></label>
                <label className="text-xs font-medium text-slate-300">Username<input name="username" value={form.username} onChange={handleChange} required className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none focus:border-indigo-400" /></label>
              </div>
              <label className="block text-xs font-medium text-slate-300">Email<input name="email" type="email" value={form.email} onChange={handleChange} required className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none focus:border-indigo-400" /></label>
              <div className="grid gap-4 sm:grid-cols-2">
                <label className="text-xs font-medium text-slate-300">Role<select name="role" value={form.role} onChange={handleChange} disabled={!isSuperAdmin} title={isSuperAdmin ? "Change user role" : "Only a super admin can change roles"} className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none focus:border-indigo-400 disabled:cursor-not-allowed disabled:opacity-60"><option value="USER">User</option><option value="ADMIN">Admin</option><option value="SUPER_ADMIN">Super admin</option></select>{!isSuperAdmin && <span className="mt-1 block font-normal text-slate-500">Only a super admin can change roles.</span>}</label>
                <label className="text-xs font-medium text-slate-300">Verification status<select name="isAccountVerified" value={String(form.isAccountVerified)} onChange={(event) => setForm((current) => ({ ...current, isAccountVerified: event.target.value === "true" }))} disabled={!isSuperAdmin} title={isSuperAdmin ? "Change verification status" : "Only a super admin can change verification status"} className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none focus:border-indigo-400 disabled:cursor-not-allowed disabled:opacity-60"><option value="true">Verified</option><option value="false">Pending</option></select>{!isSuperAdmin && <span className="mt-1 block font-normal text-slate-500">Only a super admin can change status.</span>}</label>
                <label className="text-xs font-medium text-slate-300">{isCreating ? "Password" : "New password"} {!isCreating && <span className="font-normal text-slate-500">(optional)</span>}<input name="password" type="password" minLength="8" required={isCreating} value={form.password} onChange={handleChange} className="mt-1.5 w-full rounded-lg border border-slate-700 bg-[#141B2D] px-3 py-2.5 text-sm text-white outline-none focus:border-indigo-400" /></label>
              </div>
              <div className="flex justify-end gap-3 border-t border-slate-700 pt-4">
                <button type="button" onClick={closeEdit} disabled={saving} className="rounded-lg px-4 py-2.5 text-sm font-medium text-slate-300 hover:bg-slate-700">Cancel</button>
                <button type="submit" disabled={saving} className="rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-60">{saving ? "Saving..." : isCreating ? "Add user" : "Save changes"}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </section>
  );
};

export default ManageUsers

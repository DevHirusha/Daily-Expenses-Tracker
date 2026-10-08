import api from "./axios";

export const loginAdmin = (email, password) =>
  api.post("/admin/login", { email, password });

export const getCurrentAdmin = () => api.get("/admin/me");

export const logout = () => {
  localStorage.removeItem("admin_token");
  localStorage.removeItem("admin_user");
};

export const getToken = () => localStorage.getItem("admin_token");

export const getAdmin = () => {
  const raw = localStorage.getItem("admin_user");
  return raw ? JSON.parse(raw) : null;
};
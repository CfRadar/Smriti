import React, { useState } from "react";
import { useNavigate, useLocation, Link } from "react-router-dom";
import { Heart, Lock, Mail, ArrowRight, ShieldCheck, AlertCircle } from "lucide-react";
import { api } from "../../services/api";

export default function LoginPage() {
  const navigate = useNavigate();
  const location = useLocation();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  const from = (location.state as { from?: { pathname: string } })?.from?.pathname || "/caregiver";

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage("");

    if (!email || !password) {
      setErrorMessage("Please enter both email and password.");
      return;
    }

    setLoading(true);
    try {
      const data = await api.post("/auth/login", { email, password });
      
      if (data?.token) {
        localStorage.setItem("token", data.token);
      }
      if (data?.user) {
        localStorage.setItem("user", JSON.stringify(data.user));
      }

      navigate(from, { replace: true });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Failed to sign in. Please verify your credentials.";
      setErrorMessage(message);
    } finally {
      setLoading(false);
    }
  };

  const fillDemoCaregiver = () => {
    setEmail("caregiver@smriti.org");
    setPassword("Password@123");
    setErrorMessage("");
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-white to-blue-50 flex items-center justify-center p-4">
      <div className="max-w-md w-full">
        {/* Brand Card */}
        <div className="bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
          {/* Logo & Title */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-indigo-600 text-white shadow-lg shadow-indigo-200 mb-4">
              <Heart className="w-8 h-8 fill-current" />
            </div>
            <h1 className="text-2xl font-bold text-gray-900 tracking-tight">
              Smriti <span className="text-indigo-600 font-medium">(स्मृति)</span>
            </h1>
            <p className="text-xs uppercase tracking-widest text-indigo-500 font-semibold mt-1">
              Caregiver Portal
            </p>
            <p className="text-sm text-gray-500 mt-2">
              Sign in to monitor cognitive routines and assist your loved ones.
            </p>
          </div>

          {/* Error Message */}
          {errorMessage && (
            <div className="mb-6 p-3.5 rounded-xl bg-red-50 border border-red-200 flex items-start gap-3 text-red-700 text-sm animate-fadeIn">
              <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5 text-red-500" />
              <span>{errorMessage}</span>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider mb-1.5">
                Email Address
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
                  <Mail size={18} />
                </div>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="caregiver@smriti.org"
                  className="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition"
                />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="block text-xs font-semibold text-gray-700 uppercase tracking-wider">
                  Password
                </label>
              </div>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
                  <Lock size={18} />
                </div>
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full mt-2 py-3 px-4 bg-indigo-600 hover:bg-indigo-700 text-white font-medium rounded-xl text-sm shadow-md shadow-indigo-100 hover:shadow-lg transition flex items-center justify-center gap-2 disabled:opacity-60"
            >
              {loading ? (
                <span>Signing in...</span>
              ) : (
                <>
                  <span>Sign In to Dashboard</span>
                  <ArrowRight size={16} />
                </>
              )}
            </button>
          </form>

          {/* Quick Demo Fill */}
          <div className="mt-6 pt-5 border-t border-gray-100">
            <button
              type="button"
              onClick={fillDemoCaregiver}
              className="w-full py-2.5 px-3 bg-indigo-50 hover:bg-indigo-100 border border-indigo-200 rounded-xl text-xs font-semibold text-indigo-700 transition flex items-center justify-center gap-2"
            >
              <ShieldCheck size={16} />
              Quick Fill Demo Caregiver Credentials
            </button>
          </div>

          <div className="mt-6 text-center">
            <Link
              to="/"
              className="text-xs text-gray-500 hover:text-gray-800 transition"
            >
              ← Back to Smriti Home
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

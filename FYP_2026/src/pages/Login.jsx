import React, { useState, useEffect } from 'react';
import { useAuthStore } from '../store/authStore';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { BrainCircuit, Eye, EyeOff, Shield, AlertCircle } from 'lucide-react';

export default function LoginPage({ onSuccess }) {
  const { login, isLoading, error, clearError } = useAuthStore();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);

  useEffect(() => { clearError(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const user = await login(identifier.trim(), password);
      onSuccess?.(user);
    } catch {
      // error shown from store.error
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 px-4">
      {/* Background grid */}
      <div
        className="absolute inset-0 opacity-[0.03]"
        style={{ backgroundImage: 'radial-gradient(circle, #fff 1px, transparent 1px)', backgroundSize: '30px 30px' }}
      />

      <div className="relative w-full max-w-md">
        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-violet-600 to-blue-600 flex items-center justify-center shadow-xl mb-4">
            <BrainCircuit className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Synapse Flow</h1>
          <p className="text-slate-400 text-sm mt-1">Intelligent Traffic Management System</p>
        </div>

        <Card className="bg-slate-900 border-slate-800 shadow-2xl">
          <CardHeader className="pb-4 pt-6 px-6">
            <div className="flex items-center gap-2">
              <Shield className="w-4 h-4 text-blue-400" />
              <CardTitle className="text-base text-white font-semibold">Authorized Personnel Only</CardTitle>
            </div>
            <p className="text-slate-400 text-xs mt-1">Sign in with your official credentials</p>
          </CardHeader>

          <CardContent className="px-6 pb-6">
            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Error banner */}
              {error && (
                <div className="flex items-center gap-2 p-3 rounded-lg bg-red-900/30 border border-red-700/50 text-red-300 text-xs">
                  <AlertCircle className="w-4 h-4 flex-shrink-0" />
                  {error}
                </div>
              )}

              <div className="space-y-1.5">
                <Label className="text-slate-300 text-xs font-medium">Email / Phone / Badge ID</Label>
                <Input
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  placeholder="officer01 · admin@itms.gov.et · +251911..."
                  required
                  autoComplete="username"
                  className="bg-slate-800 border-slate-700 text-white placeholder:text-slate-500 focus:border-blue-500 h-10"
                />
              </div>

              <div className="space-y-1.5">
                <Label className="text-slate-300 text-xs font-medium">Password</Label>
                <div className="relative">
                  <Input
                    type={showPw ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    required
                    autoComplete="current-password"
                    className="bg-slate-800 border-slate-700 text-white placeholder:text-slate-500 focus:border-blue-500 h-10 pr-10"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPw((s) => !s)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300"
                  >
                    {showPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <Button
                type="submit"
                disabled={isLoading || !identifier || !password}
                className="w-full h-10 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm mt-2"
              >
                {isLoading ? (
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  'Sign In'
                )}
              </Button>
            </form>

            {/* Demo credentials hint */}
            <div className="mt-5 p-3 rounded-lg bg-slate-800/60 border border-slate-700/50">
              <p className="text-slate-400 text-[10px] font-semibold uppercase tracking-wide mb-2">Demo Credentials</p>
              <div className="space-y-1">
                {[
                  { role: 'Admin', user: 'admin', pw: 'admin123' },
                  { role: 'Developer', user: 'developer', pw: 'dev123' },
                  { role: 'Supervisor', user: 'supervisor01', pw: 'super123' },
                ].map(({ role, user, pw }) => (
                  <button
                    key={role}
                    type="button"
                    onClick={() => { setIdentifier(user); setPassword(pw); }}
                    className="w-full flex items-center justify-between px-2 py-1.5 rounded hover:bg-slate-700/50 transition-colors"
                  >
                    <span className="text-[11px] font-semibold text-slate-300">{role}</span>
                    <span className="text-[10px] font-mono text-slate-500">{user} / {pw}</span>
                  </button>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        <p className="text-center text-slate-600 text-[10px] mt-6">
          ITMS v1.0 · Addis Ababa Traffic Authority · All rights reserved
        </p>
      </div>
    </div>
  );
}

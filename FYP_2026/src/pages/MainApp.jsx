import React, { useState, useEffect, useRef } from 'react';
import { SimulationProvider, useSimulation } from '@/lib/SimulationContext';
import Sidebar from '@/components/layout/Sidebar';
import Topbar from '@/components/layout/Topbar';

// Admin pages
import AdminDashboardPage from './admin/Dashboard';
import LiveTrafficControl from './admin/LiveTrafficControl';
import ViolationsCenter from './admin/ViolationsCenter';
import EvidencePanel from './admin/EvidencePanel';
import PunishmentSystem from './admin/PunishmentSystem';
import Analytics from './admin/Analytics';
import HotspotMap from './admin/HotspotMap';
import Settings from './admin/Settings';
import AdminHelp from './admin/Help';

// Developer pages
import AISimulationLab from './developer/AISimulationLab';
import RewardAnalytics from './developer/RewardAnalytics';
import ScenarioReplay from './developer/ScenarioReplay';
import ParameterControl from './developer/ParameterControl';
import ExperimentMode from './developer/ExperimentMode';
import SystemLogs from './developer/SystemLogs';

import PerformanceComparison from './developer/PerformanceComparison';
import DevHelp from './developer/DevHelp';

const ADMIN_ROUTES = {
  'dashboard': AdminDashboardPage,
  'live-traffic': LiveTrafficControl,
  'violations': ViolationsCenter,
  'evidence': EvidencePanel,
  'punishment': PunishmentSystem,
  'analytics': Analytics,
  'hotspot': HotspotMap,
  'settings': Settings,
  'help': AdminHelp,
};

const DEV_ROUTES = {
  'ai-lab': AISimulationLab,
  'reward-analytics': RewardAnalytics,
  'scenario-replay': ScenarioReplay,
  'param-control': ParameterControl,
  'experiment': ExperimentMode,
  'system-logs': SystemLogs,
  'perf-comparison': PerformanceComparison,
  'hotspot': HotspotMap,
  'help': DevHelp,
};

function AppContent() {
  const { appMode } = useSimulation();
  const [activePage, setActivePage] = useState('dashboard');
  const prevMode = useRef(appMode);

  // Reset to default page when mode switches
  useEffect(() => {
    if (prevMode.current !== appMode) {
      prevMode.current = appMode;
      setActivePage(appMode === 'admin' ? 'dashboard' : 'ai-lab');
    }
  }, [appMode]);

  const routes = appMode === 'admin' ? ADMIN_ROUTES : DEV_ROUTES;
  const PageComponent = routes[activePage] || (appMode === 'admin' ? AdminDashboardPage : AISimulationLab);

  const handleNavigate = (page) => {
    setActivePage(page);
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <Topbar />
      <div className="flex flex-1 overflow-hidden">
        <Sidebar activePage={activePage} onNavigate={handleNavigate} />
        <main className="flex-1 overflow-y-auto">
          <PageComponent />
        </main>
      </div>
    </div>
  );
}

export default function MainApp() {
  return (
    <SimulationProvider>
      <AppContent />
    </SimulationProvider>
  );
}
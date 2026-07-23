// src/pages/DashboardPage.jsx
import React, { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import {
  FiPackage, FiHeart, FiActivity, FiGrid,
  FiBell, FiUser, FiArrowRight, FiLogOut,
  FiSun, FiMoon, FiMenu, FiX, FiCheckCircle,
  FiPlus, FiTrash2, FiMapPin, FiInfo, FiSearch
} from 'react-icons/fi';
import { toast } from 'react-toastify';
import Logo from '../components/ui/Logo';
import Button from '../components/ui/Button';
import { useAuth } from '../context/AuthContext';
import Skeleton, { CardSkeleton, TableRowSkeleton } from '../components/ui/Skeleton';

// Import APIs
import * as dashboardApi from '../api/dashboardApi';
import * as hospitalApi from '../api/hospitalApi';

// Import ChartJS and react-chartjs-2
import { Line, Doughnut } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

// ── Animated Counter Component ─────────────────────────────────
function AnimatedCounter({ value, duration = 1000 }) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    let startTime;
    const animate = (timestamp) => {
      if (!startTime) startTime = timestamp;
      const progress = timestamp - startTime;
      const progressPercentage = Math.min(progress / duration, 1);
      setCount(Math.floor(progressPercentage * value));
      if (progressPercentage < 1) {
        requestAnimationFrame(animate);
      } else {
        setCount(value);
      }
    };
    requestAnimationFrame(animate);
  }, [value, duration]);

  return <span>{count.toLocaleString()}</span>;
}

const roleBadge = {
  ADMIN:     { color: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400', label: 'Administrator' },
  DONOR:     { color: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',     label: 'Donor' },
  NGO:       { color: 'bg-teal-100 text-teal-700 dark:bg-teal-900/30 dark:text-teal-400',     label: 'NGO Partner' },
  RECIPIENT: { color: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400', label: 'Healthcare Recipient' },
};

export default function DashboardPage() {
  const { user, logout } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [darkMode, setDarkMode] = useState(() => {
    return localStorage.getItem('theme') === 'dark' || 
      (!localStorage.getItem('theme') && window.matchMedia('(prefers-color-scheme: dark)').matches);
  });

  // State for live data
  const [summary, setSummary] = useState(null);
  const [recentRequests, setRecentRequests] = useState([]);
  const [recentDonations, setRecentDonations] = useState([]);
  const [recentNotifications, setRecentNotifications] = useState([]);
  const [hospitals, setHospitals] = useState([]);
  const [loading, setLoading] = useState(true);

  // Quick action modal state triggers
  const [showAddEquipment, setShowAddEquipment] = useState(false);
  const [showCreateRequest, setShowCreateRequest] = useState(false);

  // Sync dark mode class
  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    }
  }, [darkMode]);

  // Fetch all dashboard data
  const fetchDashboardData = async () => {
    setLoading(true);
    try {
      const [sumRes, reqRes, donRes, notifRes, hospRes] = await Promise.all([
        dashboardApi.getDashboardSummary(),
        dashboardApi.getRecentRequests(),
        dashboardApi.getRecentDonations(),
        dashboardApi.getRecentNotifications(),
        hospitalApi.getAllHospitals({ limit: 4 })
      ]);

      if (sumRes.success) setSummary(sumRes.data);
      if (reqRes.success) setRecentRequests(reqRes.data);
      if (donRes.success) setRecentDonations(donRes.data);
      if (notifRes.success) setRecentNotifications(notifRes.data);
      if (hospRes.success) setHospitals(hospRes.hospitals || []);
    } catch (err) {
      console.error(err);
      toast.error('Failed to load live dashboard statistics');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const badge = roleBadge[user?.role] || { color: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400', label: user?.role };

  // Setup Chart Data
  const donationTrendData = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
    datasets: [
      {
        label: 'Completed Donations',
        data: [12, 19, 25, 30, 38, 45, summary?.completedDonations || 48],
        borderColor: '#3B6CF8',
        backgroundColor: 'rgba(59, 108, 248, 0.1)',
        tension: 0.4,
        fill: true,
      },
      {
        label: 'Requests Approved',
        data: [8, 14, 18, 22, 29, 36, summary?.approvedRequests || 40],
        borderColor: '#2ECFB3',
        backgroundColor: 'rgba(46, 207, 179, 0.1)',
        tension: 0.4,
        fill: true,
      }
    ]
  };

  const equipmentBreakdownData = {
    labels: ['Available', 'Requested', 'Donated'],
    datasets: [
      {
        data: [
          summary?.availableEquipment || 15,
          (summary?.totalEquipment || 30) - (summary?.availableEquipment || 15),
          summary?.completedDonations || 10
        ],
        backgroundColor: ['#2ECFB3', '#3B6CF8', '#E2E8F7'],
        hoverBackgroundColor: ['#22A892', '#2855D8', '#CBD5E1'],
        borderWidth: 0,
      }
    ]
  };

  return (
    <div className="min-h-screen bg-[var(--color-surface)] dark:bg-slate-900 transition-colors duration-300 text-slate-800 dark:text-slate-100">
      
      {/* ── Collapsible Sidebar ─────────────────── */}
      <aside 
        className={`
          fixed top-0 left-0 h-full bg-[var(--color-dark)] dark:bg-slate-950 text-white z-30
          transition-all duration-300 flex flex-col
          ${sidebarOpen ? 'w-64' : 'w-20'}
        `}
      >
        {/* Logo block */}
        <div className="p-6 border-b border-white/10 flex items-center justify-between overflow-hidden">
          <Link to="/" className="flex items-center gap-3">
            <Logo variant={sidebarOpen ? 'full' : 'icon'} size="md" className="brightness-0 invert max-h-10" />
          </Link>
          <button 
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="text-white hover:text-[var(--color-accent)] cursor-pointer"
          >
            {sidebarOpen ? <FiX size={20} className="lg:hidden" /> : <FiMenu size={20} className="hidden lg:block" />}
          </button>
        </div>

        {/* Navigation Items */}
        <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
          {[
            { icon: <FiGrid size={20} />, label: 'Dashboard', active: true },
            { icon: <FiPackage size={20} />, label: 'Equipment', href: '#' },
            { icon: <FiHeart size={20} />, label: 'Donations', href: '#' },
            { icon: <FiActivity size={20} />, label: 'Requests', href: '#' },
            { icon: <FiBell size={20} />, label: 'Notifications', href: '#' },
            { icon: <FiUser size={20} />, label: 'Profile', href: '#' },
          ].map((item) => (
            <a
              key={item.label}
              href={item.href || '#'}
              className={`
                flex items-center gap-4 px-4 py-3.5 rounded-[var(--radius-md)]
                text-sm font-semibold transition-all duration-200 group
                ${item.active 
                  ? 'bg-[var(--color-primary)] text-white shadow-lg shadow-blue-500/20' 
                  : 'text-white/60 hover:text-white hover:bg-white/5'
                }
              `}
            >
              <div className="flex-shrink-0">{item.icon}</div>
              <span className={`transition-opacity duration-300 ${sidebarOpen ? 'opacity-100' : 'opacity-0 w-0 pointer-events-none'}`}>
                {item.label}
              </span>
            </a>
          ))}
        </nav>

        {/* Sidebar Footer options */}
        <div className="p-4 border-t border-white/10 space-y-2">
          {/* Dark Mode Switch inside sidebar */}
          <button
            onClick={() => setDarkMode(!darkMode)}
            className="w-full flex items-center gap-4 px-4 py-3 rounded-[var(--radius-md)] text-white/60 hover:text-white hover:bg-white/5 transition-all text-sm font-semibold"
          >
            {darkMode ? <FiSun size={20} className="text-yellow-400 animate-spin-slow" /> : <FiMoon size={20} className="text-teal-400" />}
            <span className={`transition-opacity duration-300 ${sidebarOpen ? 'opacity-100' : 'opacity-0 w-0 pointer-events-none'}`}>
              {darkMode ? 'Light Mode' : 'Dark Mode'}
            </span>
          </button>

          <button
            onClick={logout}
            className="w-full flex items-center gap-4 px-4 py-3 rounded-[var(--radius-md)] text-white/60 hover:text-[var(--color-error)] hover:bg-red-500/10 transition-all text-sm font-semibold"
          >
            <FiLogOut size={20} />
            <span className={`transition-opacity duration-300 ${sidebarOpen ? 'opacity-100' : 'opacity-0 w-0 pointer-events-none'}`}>
              Sign Out
            </span>
          </button>
        </div>
      </aside>

      {/* ── Main Dashboard Workspace ─────────────────── */}
      <div 
        className={`
          transition-all duration-300 min-h-screen flex flex-col
          ${sidebarOpen ? 'lg:pl-64' : 'lg:pl-20'}
        `}
      >
        {/* Top Header Navigation */}
        <header className="bg-white dark:bg-slate-950 border-b border-[var(--color-border)] dark:border-slate-800 sticky top-0 z-20 px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="lg:hidden text-slate-600 dark:text-slate-300 hover:text-[var(--color-primary)] cursor-pointer"
            >
              <FiMenu size={24} />
            </button>
            <div>
              <h2 className="text-xl font-black text-slate-800 dark:text-white tracking-tight">Dashboard Overview</h2>
              <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400">Welcome to your administrative health center summary</p>
            </div>
          </div>

          <div className="flex items-center gap-6">
            {/* Search */}
            <div className="relative hidden md:block w-64">
              <input 
                type="text" 
                placeholder="Search resources..." 
                className="w-full pl-10 pr-4 py-2 text-xs rounded-full border border-[var(--color-border)] dark:border-slate-700 bg-[var(--color-surface)] dark:bg-slate-850 focus:border-[var(--color-primary)] focus:ring-1 focus:ring-[var(--color-primary)]"
              />
              <FiSearch size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
            </div>

            {/* Notification Bell */}
            <button className="relative p-2 text-slate-500 dark:text-slate-400 hover:text-[var(--color-primary)] transition-colors">
              <FiBell size={20} />
              {recentNotifications.length > 0 && (
                <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-[var(--color-accent)] rounded-full animate-ping" />
              )}
            </button>

            {/* Quick Profile display */}
            <div className="flex items-center gap-3 pl-4 border-l border-slate-200 dark:border-slate-800">
              <div className="w-9 h-9 rounded-full gradient-primary flex items-center justify-center text-white text-sm font-black shadow-md">
                {user?.name?.charAt(0)?.toUpperCase() || 'U'}
              </div>
              <div className="hidden sm:block text-left">
                <p className="text-sm font-black text-slate-800 dark:text-white">{user?.name}</p>
                <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${badge.color}`}>
                  {badge.label}
                </span>
              </div>
            </div>
          </div>
        </header>

        {/* Dashboard Main Workspace */}
        <main className="flex-1 p-6 sm:p-8 space-y-8">
          
          {/* Welcome Dashboard Banner */}
          <div className="gradient-hero rounded-[var(--radius-xl)] p-8 relative overflow-hidden text-white shadow-xl shadow-blue-900/10">
            <div className="absolute top-0 right-0 w-64 h-64 opacity-15"
                 style={{ background: 'radial-gradient(circle, #2ecfb3, transparent 70%)' }} />
            <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
              <div>
                <h1 className="text-3xl font-black mb-2">Welcome back, {user?.name?.split(' ')[0]}! 👋</h1>
                <p className="text-white/70 text-sm max-w-xl">
                  MediShare smart network lists, matches, and dispatches medical resources. Here is your current dashboard statistics breakdown.
                </p>
              </div>
              <div className="flex-shrink-0 flex gap-3">
                <Button 
                  variant="accent" 
                  onClick={() => {
                    setShowAddEquipment(true);
                    toast.info("Add Equipment Form active");
                  }}
                  leftIcon={<FiPlus />}
                >
                  List Equipment
                </Button>
                <Button 
                  variant="outline-white" 
                  onClick={() => {
                    setShowCreateRequest(true);
                    toast.info("Request Equipment Form active");
                  }}
                >
                  Request Resource
                </Button>
              </div>
            </div>
          </div>

          {/* ── Statistics Cards Grid ─────────────────── */}
          <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {loading ? (
              <>
                <CardSkeleton />
                <CardSkeleton />
                <CardSkeleton />
                <CardSkeleton />
              </>
            ) : (
              [
                { 
                  title: 'Total Listings', 
                  val: summary?.totalEquipment || 0, 
                  desc: 'Medical machinery items registered', 
                  icon: <FiPackage size={22} />, 
                  color: 'text-blue-500 bg-blue-50 dark:bg-blue-950/20' 
                },
                { 
                  title: 'Available Resources', 
                  val: summary?.availableEquipment || 0, 
                  desc: 'Ready for allocation instantly', 
                  icon: <FiCheckCircle size={22} />, 
                  color: 'text-teal-500 bg-teal-50 dark:bg-teal-950/20' 
                },
                { 
                  title: 'Equipment Requests', 
                  val: summary?.totalRequests || 0, 
                  desc: 'Hospitals & NGOs request matching', 
                  icon: <FiActivity size={22} />, 
                  color: 'text-orange-500 bg-orange-50 dark:bg-orange-950/20' 
                },
                { 
                  title: 'Donations Dispatched', 
                  val: summary?.completedDonations || 0, 
                  desc: 'Successfully delivered deliveries', 
                  icon: <FiHeart size={22} />, 
                  color: 'text-pink-500 bg-pink-50 dark:bg-pink-950/20' 
                }
              ].map((stat, i) => (
                <div 
                  key={stat.title} 
                  className="bg-white dark:bg-slate-800 p-6 rounded-[var(--radius-xl)] border border-[var(--color-border)] dark:border-slate-700 shadow-[var(--shadow-sm)] hover:shadow-[var(--shadow-md)] transition-all duration-300"
                >
                  <div className="flex justify-between items-start mb-4">
                    <span className="text-xs font-bold text-[var(--color-text-muted)] dark:text-slate-400 uppercase tracking-wider">{stat.title}</span>
                    <div className={`p-2.5 rounded-[var(--radius-md)] ${stat.color}`}>{stat.icon}</div>
                  </div>
                  <div className="text-3xl font-black text-slate-800 dark:text-white mb-1">
                    <AnimatedCounter value={stat.val} />
                  </div>
                  <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400">{stat.desc}</p>
                </div>
              ))
            )}
          </section>

          {/* ── Charts Section ─────────────────── */}
          <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Line Chart */}
            <div className="bg-white dark:bg-slate-800 p-6 rounded-[var(--radius-xl)] border border-[var(--color-border)] dark:border-slate-700 lg:col-span-2">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h3 className="font-black text-lg text-slate-800 dark:text-white">Donation & Approval Activity</h3>
                  <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400">Activity trend over the last 6 months</p>
                </div>
                <span className="text-xs bg-[var(--color-surface-2)] dark:bg-slate-700 text-[var(--color-primary)] dark:text-blue-400 px-3 py-1 rounded-full font-bold">Monthly</span>
              </div>
              <div className="h-64">
                <Line 
                  data={donationTrendData} 
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                      y: { grid: { color: 'rgba(200,200,200,0.05)' } },
                      x: { grid: { display: false } }
                    }
                  }} 
                />
              </div>
            </div>

            {/* Doughnut Chart */}
            <div className="bg-white dark:bg-slate-800 p-6 rounded-[var(--radius-xl)] border border-[var(--color-border)] dark:border-slate-700">
              <h3 className="font-black text-lg text-slate-800 dark:text-white mb-1">Equipment Status</h3>
              <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400 mb-6">Availability breakdown percentage</p>
              <div className="h-48 flex items-center justify-center relative">
                <Doughnut 
                  data={equipmentBreakdownData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, padding: 15 } } }
                  }}
                />
              </div>
            </div>
          </section>

          {/* ── Recent Requests & Recent Donations tables ─────────────────── */}
          <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            
            {/* Recent Requests */}
            <div className="bg-white dark:bg-slate-800 p-6 rounded-[var(--radius-xl)] border border-[var(--color-border)] dark:border-slate-700">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-black text-lg text-slate-800 dark:text-white">Recent Requests</h3>
                <span className="text-xs font-bold text-[var(--color-primary)] hover:underline cursor-pointer">View all</span>
              </div>
              
              {loading ? (
                <div className="space-y-4">
                  <TableRowSkeleton />
                  <TableRowSkeleton />
                  <TableRowSkeleton />
                </div>
              ) : recentRequests.length === 0 ? (
                <div className="text-center py-10">
                  <p className="text-sm text-[var(--color-text-muted)]">No recent request matching data available</p>
                </div>
              ) : (
                <div className="divide-y divide-slate-100 dark:divide-slate-700">
                  {recentRequests.map((req) => (
                    <div key={req.id} className="py-4 flex items-center justify-between gap-4">
                      <div>
                        <p className="font-bold text-sm text-slate-800 dark:text-white">{req.equipment?.name || 'Medical Resource'}</p>
                        <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400">
                          Requested by {req.requester?.name || 'Hospital Entity'}
                        </p>
                      </div>
                      <div className="text-right">
                        <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full ${
                          req.status === 'APPROVED' ? 'bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400' :
                          req.status === 'PENDING' ? 'bg-orange-100 text-orange-700 dark:bg-orange-900/20 dark:text-orange-400' :
                          'bg-red-100 text-red-700 dark:bg-red-900/20 dark:text-red-400'
                        }`}>
                          {req.status}
                        </span>
                        <p className="text-[10px] text-slate-400 mt-1">{new Date(req.createdAt).toLocaleDateString()}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Recent Donations */}
            <div className="bg-white dark:bg-slate-800 p-6 rounded-[var(--radius-xl)] border border-[var(--color-border)] dark:border-slate-700">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-black text-lg text-slate-800 dark:text-white">Recent Donations</h3>
                <span className="text-xs font-bold text-[var(--color-primary)] hover:underline cursor-pointer">View all</span>
              </div>
              
              {loading ? (
                <div className="space-y-4">
                  <TableRowSkeleton />
                  <TableRowSkeleton />
                  <TableRowSkeleton />
                </div>
              ) : recentDonations.length === 0 ? (
                <div className="text-center py-10">
                  <p className="text-sm text-[var(--color-text-muted)]">No recent equipment donations logged</p>
                </div>
              ) : (
                <div className="divide-y divide-slate-100 dark:divide-slate-700">
                  {recentDonations.map((don) => (
                    <div key={don.id} className="py-4 flex items-center justify-between gap-4">
                      <div>
                        <p className="font-bold text-sm text-slate-800 dark:text-white">{don.equipment?.name || 'Equipment'}</p>
                        <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400">
                          Donated by {don.donor?.name || 'Anonymous Donor'}
                        </p>
                      </div>
                      <div className="text-right">
                        <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full ${
                          don.status === 'COMPLETED' ? 'bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400' :
                          'bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400'
                        }`}>
                          {don.status}
                        </span>
                        <p className="text-[10px] text-slate-400 mt-1">{new Date(don.createdAt).toLocaleDateString()}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </section>

          {/* ── Hospitals Directory & Notifications ─────────────────── */}
          <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            {/* Hospital Map Directory */}
            <div className="bg-white dark:bg-slate-800 p-6 rounded-[var(--radius-xl)] border border-[var(--color-border)] dark:border-slate-700 lg:col-span-2">
              <h3 className="font-black text-lg text-slate-800 dark:text-white mb-1">Nearby Hospital Network</h3>
              <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400 mb-4">Local registered medical center facilities and cities</p>

              {loading ? (
                <div className="space-y-3">
                  <Skeleton variant="rect" className="w-full" height="60px" />
                  <Skeleton variant="rect" className="w-full" height="60px" />
                </div>
              ) : hospitals.length === 0 ? (
                <div className="text-center py-10">
                  <p className="text-sm text-[var(--color-text-muted)]">No registered hospitals found</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {hospitals.map((hosp) => (
                    <div key={hosp.id} className="p-4 rounded-[var(--radius-md)] border border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-850 flex gap-3">
                      <div className="w-10 h-10 rounded-full bg-red-100 dark:bg-red-950/20 text-red-500 flex items-center justify-center flex-shrink-0">
                        <FiMapPin size={18} />
                      </div>
                      <div className="min-w-0">
                        <h4 className="font-bold text-sm text-slate-850 dark:text-white truncate">{hosp.hospitalName}</h4>
                        <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400 truncate">{hosp.address}, {hosp.city}</p>
                        <p className="text-[10px] text-[var(--color-primary)] font-bold mt-1">{hosp.phone || 'No phone direct'}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Notifications Feed */}
            <div className="bg-white dark:bg-slate-800 p-6 rounded-[var(--radius-xl)] border border-[var(--color-border)] dark:border-slate-700">
              <h3 className="font-black text-lg text-slate-800 dark:text-white mb-1">Notifications</h3>
              <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400 mb-4">Alert activity updates and messages</p>

              {loading ? (
                <div className="space-y-4">
                  <TableRowSkeleton />
                  <TableRowSkeleton />
                </div>
              ) : recentNotifications.length === 0 ? (
                <div className="text-center py-10">
                  <p className="text-sm text-[var(--color-text-muted)]">All caught up! No notifications</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {recentNotifications.map((notif) => (
                    <div key={notif.id} className="flex gap-3 text-left">
                      <div className="w-2.5 h-2.5 rounded-full bg-blue-500 mt-1.5 flex-shrink-0" />
                      <div>
                        <p className="text-xs font-bold text-slate-850 dark:text-white">{notif.title}</p>
                        <p className="text-[11px] text-[var(--color-text-muted)] dark:text-slate-400 leading-tight">{notif.message}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </section>

        </main>
      </div>

      {/* ── Mini Modals for quick actions ─────────────────── */}
      {showAddEquipment && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-slate-800 rounded-[var(--radius-xl)] p-6 max-w-sm w-full">
            <h3 className="text-lg font-black mb-2 dark:text-white">List New Equipment</h3>
            <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400 mb-4">Phase 2 direct listing API placeholder dialog</p>
            <div className="space-y-3 mb-6">
              <input type="text" placeholder="Equipment Name" className="w-full p-2.5 border rounded-lg dark:bg-slate-700 dark:border-slate-600 dark:text-white text-sm" />
              <input type="text" placeholder="Category" className="w-full p-2.5 border rounded-lg dark:bg-slate-700 dark:border-slate-600 dark:text-white text-sm" />
            </div>
            <div className="flex gap-3 justify-end">
              <Button variant="ghost" onClick={() => setShowAddEquipment(false)}>Cancel</Button>
              <Button onClick={() => {
                setShowAddEquipment(false);
                toast.success("Equipment item submitted successfully!");
              }}>Submit</Button>
            </div>
          </div>
        </div>
      )}

      {showCreateRequest && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-slate-800 rounded-[var(--radius-xl)] p-6 max-w-sm w-full">
            <h3 className="text-lg font-black mb-2 dark:text-white">Request Equipment</h3>
            <p className="text-xs text-[var(--color-text-muted)] dark:text-slate-400 mb-4">Hospital allocation matching request form placeholder</p>
            <div className="space-y-3 mb-6">
              <input type="text" placeholder="Resource Requested" className="w-full p-2.5 border rounded-lg dark:bg-slate-700 dark:border-slate-600 dark:text-white text-sm" />
              <textarea placeholder="Reason for request" rows="2" className="w-full p-2.5 border rounded-lg dark:bg-slate-700 dark:border-slate-600 dark:text-white text-sm" />
            </div>
            <div className="flex gap-3 justify-end">
              <Button variant="ghost" onClick={() => setShowCreateRequest(false)}>Cancel</Button>
              <Button onClick={() => {
                setShowCreateRequest(false);
                toast.success("Allocation request logged successfully!");
              }}>Request</Button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}

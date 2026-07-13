import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import Navbar from './Navbar';
import BottomNav from './BottomNav';

export default function MainLayout() {
  return (
    <div className="min-h-screen">
      <Sidebar />
      <div className="md:ml-[60px] flex flex-col min-h-screen">
        <Navbar />
        <main className="flex-1 p-4 md:p-6 pb-20 md:pb-6">
          <Outlet />
        </main>
      </div>
      <BottomNav />
    </div>
  );
}

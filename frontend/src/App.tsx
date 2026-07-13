import { Routes, Route, Navigate } from 'react-router-dom';
import MainLayout from './components/Layout/MainLayout';
import ProtectedRoute from './components/Layout/ProtectedRoute';
import LoginPage from './pages/LoginPage';
import SolicitarCadastroPage from './pages/SolicitarCadastroPage';
import HomePage from './pages/HomePage';
import DisponibilidadePage from './pages/DisponibilidadePage';
import MinhasReservasPage from './pages/MinhasReservasPage';
import ChecklistsPage from './pages/ChecklistsPage';
import AtivosPage from './pages/AtivosPage';
import ReservasAdminPage from './pages/ReservasAdminPage';
import TemplatesPage from './pages/TemplatesPage';
import SolicitacoesAdminPage from './pages/SolicitacoesAdminPage';
import UsuariosPage from './pages/UsuariosPage';
import DashboardExecutivoPage from './pages/DashboardExecutivoPage';
import NotFoundPage from './pages/NotFoundPage';

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/solicitar-cadastro" element={<SolicitarCadastroPage />} />

      <Route
        path="/"
        element={
          <ProtectedRoute>
            <MainLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/home" replace />} />
        <Route path="home" element={<HomePage />} />
        <Route path="disponibilidade" element={<DisponibilidadePage />} />
        <Route path="reservas" element={<MinhasReservasPage />} />
        <Route path="checklists" element={<ChecklistsPage />} />
        <Route path="ativos" element={<ProtectedRoute roles={['ADMINISTRADOR']}><AtivosPage /></ProtectedRoute>} />
        <Route path="reservas-admin" element={<ProtectedRoute roles={['ADMINISTRADOR', 'GERENTE']}><ReservasAdminPage /></ProtectedRoute>} />
        <Route path="templates" element={<ProtectedRoute roles={['ADMINISTRADOR']}><TemplatesPage /></ProtectedRoute>} />
        <Route path="solicitacoes" element={<ProtectedRoute roles={['ADMINISTRADOR']}><SolicitacoesAdminPage /></ProtectedRoute>} />
        <Route path="usuarios" element={<ProtectedRoute roles={['ADMINISTRADOR']}><UsuariosPage /></ProtectedRoute>} />
        <Route path="analytics" element={<ProtectedRoute roles={['ADMINISTRADOR', 'GERENTE']}><DashboardExecutivoPage /></ProtectedRoute>} />
        <Route path="dashboard-executivo" element={<Navigate to="/analytics" replace />} />
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}

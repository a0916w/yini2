import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './auth.jsx'
import Login from './pages/Login.jsx'
import Overview from './pages/Overview.jsx'
import ModuleList from './pages/ModuleList.jsx'
import './console.css'

function Gate() {
  const { authed } = useAuth()
  if (!authed) return <Login />
  return (
    <Routes>
      <Route path="/" element={<Overview />} />
      <Route path="/:key" element={<ModuleList />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <Gate />
      </AuthProvider>
    </BrowserRouter>
  </React.StrictMode>,
)

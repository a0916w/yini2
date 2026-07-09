import { useState } from 'react'
import { useLogin, useNotify } from 'react-admin'
import { Box, Card, TextField, Button, Typography, CircularProgress } from '@mui/material'

export default function Login() {
  const login = useLogin()
  const notify = useNotify()
  const [account, setAccount] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)

  const submit = async (e) => {
    e.preventDefault()
    setBusy(true)
    try {
      await login({ username: account, password })
    } catch (err) {
      notify(err?.message || '登录失败', { type: 'error' })
    } finally {
      setBusy(false)
    }
  }

  return (
    <Box sx={{
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'radial-gradient(1200px 600px at 20% -10%, #ffcaa1 0%, transparent 55%), linear-gradient(135deg, #fff3ea 0%, #f4f5f8 100%)',
      p: 2,
    }}>
      <Card sx={{ width: 380, maxWidth: '100%', p: 4, borderRadius: 4, boxShadow: '0 20px 60px rgba(255,109,0,.18)' }}>
        <Box sx={{ textAlign: 'center', mb: 3 }}>
          <Box sx={{
            width: 60, height: 60, borderRadius: 3, mx: 'auto', mb: 1.5,
            background: 'linear-gradient(135deg,#ff8a2b,#f0560a)', color: '#fff',
            display: 'grid', placeItems: 'center', fontWeight: 900, fontSize: 28,
            boxShadow: '0 8px 20px rgba(255,109,0,.35)',
          }}>橙</Box>
          <Typography variant="h6" sx={{ fontWeight: 800 }}>Yini 后台管理</Typography>
          <Typography variant="body2" color="text.secondary">Content Management</Typography>
        </Box>

        <form onSubmit={submit}>
          <TextField label="账号 / 邮箱（或粘贴 Token）" fullWidth value={account}
            onChange={(e) => setAccount(e.target.value)} sx={{ mb: 2 }} autoFocus />
          <TextField label="密码（Token 登录留空）" type="password" fullWidth value={password}
            onChange={(e) => setPassword(e.target.value)} sx={{ mb: 3 }} />
          <Button type="submit" variant="contained" fullWidth size="large" disabled={busy}
            sx={{ height: 48, fontSize: 16 }}>
            {busy ? <CircularProgress size={22} color="inherit" /> : '登录'}
          </Button>
        </form>
      </Card>
    </Box>
  )
}

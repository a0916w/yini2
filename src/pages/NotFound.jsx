import { useNavigate } from 'react-router-dom'
import { Header } from '../components/ui.jsx'

export default function NotFound() {
  const nav = useNavigate()
  return (
    <>
      <Header title="页面不存在" />
      <div className="page center">
        <div style={{ textAlign: 'center' }}>
          <div style={{ width: 76, height: 76, borderRadius: 22, background: 'var(--brand-grad)', display: 'grid', placeItems: 'center', fontSize: 34, fontWeight: 900, color: '#fff', margin: '0 auto' }}>橙</div>
          <div style={{ marginTop: 14, fontSize: 16 }}>页面出错了或不存在</div>
          <button className="btn btn--brand" style={{ marginTop: 18 }} onClick={() => nav('/home')}>返回首页</button>
        </div>
      </div>
    </>
  )
}

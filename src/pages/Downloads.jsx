import { Link } from 'react-router-dom'
import { Download } from 'lucide-react'
import { Header, Empty } from '../components/ui.jsx'

export default function Downloads() {
  return (
    <>
      <Header title="下载" />
      <div className="page pad">
        <Empty icon={<Download size={44} />} text="暂无下载内容" />
        <div className="panel" style={{ textAlign: 'center' }}>
          <div className="muted">离线下载为会员专享权益</div>
          <Link to="/vip" className="btn btn--brand" style={{ marginTop: 12 }}>开通会员</Link>
        </div>
      </div>
    </>
  )
}

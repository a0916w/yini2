import { Link, useNavigate } from 'react-router-dom'
import {
  History, Heart, Download, ClipboardList, Gem, Gift, CalendarCheck,
  Sparkles, Mail, Megaphone, FileText, MessageSquare, Headphones, Ticket, Languages,
} from 'lucide-react'
import { Header, TabBar } from '../components/ui.jsx'
import { useStore } from '../store.jsx'
import { t, currentLang, LANGUAGES } from '../i18n.js'

export default function Me() {
  const nav = useNavigate()
  const { user, favorites, history, points, loggedIn, logout, showToast } = useStore()

  const quick = [
    { to: '/history', ic: History, l: '观看记录', v: history.length },
    { to: '/favorites', ic: Heart, l: '我的收藏', v: favorites.length },
    { to: '/downloads', ic: Download, l: '下载', v: 0 },
    { to: '/orders', ic: ClipboardList, l: '我的订单', v: '' },
  ]
  const services = [
    { to: '/vip', ic: Gem, l: '会员中心', val: loggedIn && user.vip ? '已开通' : '未开通' },
    { to: '/redeem', ic: Ticket, l: '兑换码', val: '' },
    { to: '/shop', ic: Gift, l: '积分商城', val: `${points} 积分` },
    { to: '/tasks', ic: CalendarCheck, l: '任务中心', val: '' },
    { to: '/wishes', ic: Sparkles, l: '魔改愿望榜', val: '' },
    { to: '/messages', ic: Mail, l: '站内消息', val: '' },
    { to: '/notices', ic: Megaphone, l: '官方公告', val: '' },
    { to: '/surveys', ic: FileText, l: '问卷调查', val: '' },
    { to: '/feedback', ic: MessageSquare, l: '意见反馈', val: '' },
    { to: '/customer-service', ic: Headphones, l: '联系客服', val: '' },
    { to: '/language', ic: Languages, l: t('language'), val: LANGUAGES.find((x) => x.code === currentLang())?.name || '' },
  ]

  return (
    <>
      <Header showBack={false} align="left" title={t('profile')} />
      <div className="page pad">
        {/* profile card */}
        <Link to={loggedIn ? '/account' : '/login'} className="brand-card between">
          <div className="flex gap" style={{ alignItems: 'center' }}>
            <div style={{ width: 56, height: 56, borderRadius: '50%', background: '#fff', display: 'grid', placeItems: 'center', fontSize: 26, fontWeight: 900, color: 'var(--brand)', boxShadow: '0 2px 8px rgba(0,0,0,.18)' }}>
              {user.avatar}
            </div>
            <div>
              <div style={{ fontWeight: 800, fontSize: 18 }}>{loggedIn ? user.name : '未登录'}</div>
              <div style={{ fontSize: 12, marginTop: 3, opacity: .85 }}>{loggedIn ? user.id : '点击登录 / 注册'}</div>
            </div>
          </div>
          {loggedIn && user.vip ? (
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: 'rgba(255,255,255,.22)', border: '1px solid rgba(255,255,255,.4)', borderRadius: 999, padding: '4px 10px', fontSize: 12, fontWeight: 700 }}>
              <Gem size={12} /> VIP
            </span>
          ) : (
            <span style={{ fontSize: 18, opacity: .8 }}>›</span>
          )}
        </Link>

        {/* quick stats */}
        <div className="panel between" style={{ marginTop: 12, textAlign: 'center' }}>
          {quick.map((q) => (
            <Link key={q.to} to={q.to} style={{ flex: 1 }}>
              <span className="qb-wrap">
                <q.ic size={21} style={{ color: 'var(--text-2)' }} />
                {q.v > 0 && <span className="qb">{q.v}</span>}
              </span>
              <div className="muted" style={{ fontSize: 11, marginTop: 6 }}>{q.l}</div>
            </Link>
          ))}
        </div>

        {/* vip banner */}
        <Link to="/vip" className="panel between" style={{ marginTop: 12, background: 'linear-gradient(135deg,#2b2118,#1f1812)', border: 'none' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 800, color: '#f7d9b8' }}>
              <Gem size={15} /> {loggedIn && user.vip ? '我的会员' : '开通会员'}
            </div>
            <div style={{ fontSize: 12, marginTop: 3, color: '#c9a87e' }}>
              {loggedIn && user.vip ? `有效期至 ${user.vipExpire}` : '海量剧集免费看 · 免广告'}
            </div>
          </div>
          <span className="btn btn--brand btn--sm">{loggedIn && user.vip ? '立即续费' : '立即开通'}</span>
        </Link>

        {/* my services */}
        <div className="sec">
          <div className="sec__title" style={{ marginBottom: 10 }}>我的服务</div>
          <div className="menu">
            {services.map((s) => (
              <Link key={s.to} to={s.to} className="menu__item">
                <span className="menu__ic"><s.ic size={17} style={{ color: 'var(--text-2)' }} /></span>
                <span className="menu__lbl">{s.l}</span>
                {s.val && <span className="menu__val">{s.val}</span>}
                <span className="menu__arrow">›</span>
              </Link>
            ))}
          </div>
        </div>

        <button className="btn btn--ghost btn--block" style={{ marginTop: 20, color: loggedIn ? 'var(--danger)' : 'var(--brand)' }}
          onClick={async () => {
            if (loggedIn) { await logout(); showToast('已退出'); nav('/login') }
            else nav('/login')
          }}>
          {loggedIn ? t('logout') : t('login')}
        </button>
      </div>
      <TabBar active="me" />
    </>
  )
}

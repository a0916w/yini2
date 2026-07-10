import { cleanName, wan, yuan } from '../api/admin.js'

/* ---- line icons (stroke=currentColor) ---- */
const I = (d, extra) => (<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">{d}{extra}</svg>)
export const ICONS = {
  overview: I(<><rect x="3" y="3" width="7" height="9" rx="1.5" /><rect x="14" y="3" width="7" height="5" rx="1.5" /><rect x="14" y="12" width="7" height="9" rx="1.5" /><rect x="3" y="16" width="7" height="5" rx="1.5" /></>),
  videos: I(<><rect x="3" y="4" width="18" height="14" rx="2" /><path d="M10 8.5l5 2.8-5 2.8z" fill="currentColor" stroke="none" /></>),
  categories: I(<path d="M4 6h16M4 12h16M4 18h10" />),
  'vip-plans': I(<><rect x="3" y="6" width="18" height="12" rx="2" /><path d="M3 10h18" /></>),
  orders: I(<path d="M6 4h12l1 4H5zM5 8v10a2 2 0 002 2h10a2 2 0 002-2V8" />),
  users: I(<><circle cx="9" cy="8" r="3" /><path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6M16 11l2 2 4-4" /></>),
  marquees: I(<path d="M4 11l14-6v14L4 13zM4 11v2M18 8a3 3 0 010 6" />),
  banners: I(<><rect x="3" y="5" width="18" height="14" rx="2" /><circle cx="9" cy="10" r="1.6" /><path d="M4 17l5-4 4 3 3-2 4 3" /></>),
  'redeem-codes': I(<><rect x="3" y="7" width="18" height="12" rx="2" /><path d="M3 11h18M8 3v4M16 3v4" /></>),
  events: I(<><path d="M12 3l2.5 5.5L20 9l-4 4 1 6-5-3-5 3 1-6-4-4 5.5-.5z" /></>),
}

/* ---- shared renderers ---- */
const stripe = (color) => <span className="stripe" style={color ? { background: color } : undefined} />
const Status = ({ cls, label }) => <span className={`status ${cls}`}><span className="dot" />{label}</span>

const ORDER_STATUS = { 0: ['待支付', 's-warn'], 1: ['已支付', 's-ok'], 2: ['已取消', 's-mute'], 3: ['退款中', 's-run'], 4: ['已退款', 's-mute'] }
function transcode(v) {
  const s = (v || '').toLowerCase()
  if (!s || s === 'mp4' || s === 'done' || s === 'success' || s === 'ok') return ['s-ok', s && s !== 'done' && s !== 'success' && s !== 'ok' ? 'MP4' : '已完成']
  if (s.includes('process') || s.includes('transcod') || s.includes('running')) return ['s-run', '转码中']
  if (s.includes('queue') || s.includes('pending') || s.includes('wait')) return ['s-warn', '排队']
  if (s.includes('fail') || s.includes('error')) return ['s-crit', '失败']
  return ['s-mute', v]
}
const bool = (v, on = '启用', off = '停用') => v
  ? <Status cls="s-ok" label={on} /> : <Status cls="s-mute" label={off} />

/* ---- module definitions ---- */
export const MODULES = [
  {
    key: 'videos', label: '资源库', group: '内容',
    filters: [{ key: 'q', kind: 'search', ph: '搜索标题' }, { key: 'is_vip', kind: 'select', opts: [['', '全部类型'], [1, 'VIP'], [0, '免费']] }, { key: 'enabled', kind: 'select', opts: [['', '全部状态'], [1, '上架'], [0, '下架']] }],
    columns: [
      { label: '剧集', render: (r) => <div className="cell-title">{stripe(transcode(r.transcode_status)[0] === 's-ok' ? 'var(--ok)' : transcode(r.transcode_status)[0] === 's-run' ? 'var(--signal)' : transcode(r.transcode_status)[0] === 's-crit' ? 'var(--crit)' : 'var(--warn)')}{r.cover_url ? <img className="thumb" src={r.cover_url} alt="" onError={(e) => { e.currentTarget.style.visibility = 'hidden' }} /> : null}<span className="t">{cleanName(r.title)}</span></div> },
      { label: '源ID', render: (r) => <span className="num">{r.source_id || '—'}</span> },
      { label: '分类', render: (r) => <span className="tag">{cleanName(r.category?.name) || '—'}</span> },
      { label: '规格', render: (r) => <span className="num">时长 {Math.round((r.duration || 0) / 60)}′</span> },
      { label: '类型', render: (r) => r.is_vip ? <Status cls="s-run" label="VIP" /> : <Status cls="s-ok" label="免费" /> },
      { label: '播放', render: (r) => <span className="num">{wan(r.view_count)}</span> },
      { label: '转码', render: (r) => { const [c, l] = transcode(r.transcode_status); return <Status cls={c} label={l} /> } },
      { label: '状态', render: (r) => bool(r.enabled, '上架', '下架') },
    ],
    fields: [
      { key: 'title', label: '标题', type: 'text' },
      { key: 'description', label: '简介', type: 'textarea' },
      { key: 'is_vip', label: 'VIP 专享', type: 'switch' },
      { key: 'enabled', label: '上架', type: 'switch' },
      { key: 'sort_order', label: '排序', type: 'number' },
    ],
  },
  {
    key: 'categories', label: '分类管理', group: '内容', create: true,
    filters: [{ key: 'q', kind: 'search', ph: '搜索名称 / slug' }],
    columns: [
      { label: '排序', render: (r) => <span className="num">{r.sort_order ?? '—'}</span> },
      { label: '名称', render: (r) => <span style={{ fontWeight: 600 }}>{cleanName(r.name) || r.slug}</span> },
      { label: 'Slug', render: (r) => <span className="num">{r.slug}</span> },
      { label: '视频数', render: (r) => <span className="num">{r.videos_count ?? '—'}</span> },
      { label: '可选片', render: (r) => bool(r.video_selectable, '是', '否') },
      { label: '状态', render: (r) => bool(r.enabled) },
    ],
    fields: [
      { key: 'name', label: '名称', type: 'text' },
      { key: 'slug', label: 'Slug', type: 'text' },
      { key: 'sort_order', label: '排序', type: 'number' },
      { key: 'enabled', label: '启用', type: 'switch' },
      { key: 'video_selectable', label: '可作为选片分类', type: 'switch' },
    ],
  },
  {
    key: 'vip-plans', label: '会员套餐', group: '增长', create: true,
    columns: [
      { label: 'ID', render: (r) => <span className="num">{r.id}</span> },
      { label: '标识', render: (r) => <span className="tag">{r.key}</span> },
      { label: '天数', render: (r) => <span className="num">{r.days ?? r.months + '月'}</span> },
      { label: '价格', render: (r) => <span className="num" style={{ color: 'var(--signal)', fontWeight: 700 }}>{yuan(r.price)}</span> },
      { label: '原价', render: (r) => <span className="num" style={{ textDecoration: 'line-through', opacity: .7 }}>{yuan(r.original_price)}</span> },
      { label: '排序', render: (r) => <span className="num">{r.sort ?? 0}</span> },
      { label: '状态', render: (r) => bool(r.status) },
    ],
    fields: [
      { key: 'key', label: '标识 key', type: 'text' },
      { key: 'days', label: '天数', type: 'number' },
      { key: 'price', label: '价格(元)', type: 'number' },
      { key: 'original_price', label: '原价(元)', type: 'number' },
      { key: 'sort', label: '排序', type: 'number' },
      { key: 'status', label: '启用', type: 'switch' },
    ],
  },
  {
    key: 'orders', label: '订单', group: '增长', readonly: true,
    filters: [{ key: 'status', kind: 'select', opts: [['', '全部'], [1, '已支付'], [0, '待支付'], [4, '已退款']] }],
    columns: [
      { label: '订单号', render: (r) => <span className="num">{r.order_no}</span> },
      { label: '套餐', render: (r) => <span style={{ fontWeight: 600 }}>{r.plan_name}</span> },
      { label: '金额', render: (r) => <span className="num">{yuan(r.amount)}</span> },
      { label: '状态', render: (r) => { const [l, c] = ORDER_STATUS[r.status] || [r.status, 's-mute']; return <Status cls={c} label={l} /> } },
      { label: '支付方式', render: (r) => <span className="num">{r.payment_method || '—'}</span> },
      { label: '下单时间', render: (r) => <span className="num">{(r.created_at || '').replace('T', ' ').slice(0, 16)}</span> },
    ],
  },
  {
    key: 'users', label: '用户', group: '增长',
    filters: [{ key: 'q', kind: 'search', ph: '搜索昵称 / 邮箱' }],
    columns: [
      { label: 'ID', render: (r) => <span className="num">{r.id}</span> },
      { label: '昵称', render: (r) => <span style={{ fontWeight: 600 }}>{r.nickname}</span> },
      { label: '邮箱', render: (r) => <span className="num">{r.email || '—'}</span> },
      { label: '手机', render: (r) => <span className="num">{r.phone || '—'}</span> },
      { label: 'VIP', render: (r) => (r.vip_level > 0) ? <Status cls="s-run" label={'LV' + r.vip_level} /> : <Status cls="s-mute" label="非会员" /> },
      { label: 'VIP到期', render: (r) => <span className="num">{(r.vip_expired_at || '').slice(0, 10) || '—'}</span> },
      { label: '角色', render: (r) => <span className="tag">{r.role || 'user'}</span> },
    ],
    fields: [
      { key: 'nickname', label: '昵称', type: 'text' },
      { key: 'email', label: '邮箱', type: 'text' },
      { key: 'phone', label: '手机', type: 'text' },
      { key: 'vip_level', label: 'VIP 等级', type: 'number' },
      { key: 'vip_expired_at', label: 'VIP 到期 (YYYY-MM-DD)', type: 'text' },
      { key: 'role', label: '角色', type: 'select', opts: [['user', '普通用户'], ['admin', '管理员'], ['superadmin', '超管']] },
    ],
  },
  {
    key: 'marquees', label: '公告', group: '运营', create: true,
    columns: [
      { label: 'ID', render: (r) => <span className="num">{r.id}</span> },
      { label: '内容', render: (r) => <span style={{ fontWeight: 500 }}>{r.content}</span> },
      { label: '排序', render: (r) => <span className="num">{r.sort_order ?? 0}</span> },
      { label: '状态', render: (r) => bool(r.is_active ?? r.enabled) },
    ],
    fields: [
      { key: 'content', label: '内容', type: 'textarea' },
      { key: 'sort_order', label: '排序', type: 'number' },
      { key: 'is_active', label: '启用', type: 'switch' },
    ],
  },
  {
    key: 'banners', label: 'Banner', group: '运营',
    columns: [
      { label: 'ID', render: (r) => <span className="num">{r.id}</span> },
      { label: '图', render: (r) => (r.desktop || r.mobile) ? <img className="thumb" src={r.desktop || r.mobile} alt="" /> : <span className="num">—</span> },
      { label: '跳转', render: (r) => <span className="num">{r.link || '—'}</span> },
      { label: '排序', render: (r) => <span className="num">{r.sort_order ?? 0}</span> },
      { label: '状态', render: (r) => bool(r.enabled) },
    ],
    fields: [
      { key: 'link', label: '跳转链接', type: 'text' },
      { key: 'sort_order', label: '排序', type: 'number' },
      { key: 'enabled', label: '启用', type: 'switch' },
    ],
  },
  {
    key: 'redeem-codes', label: '兑换码', group: '运营', create: true,
    columns: [
      { label: 'ID', render: (r) => <span className="num">{r.id}</span> },
      { label: '兑换码', render: (r) => <span className="num" style={{ fontWeight: 700 }}>{r.code}</span> },
      { label: '赠送天数', render: (r) => <span className="num">{r.vip_days}</span> },
      { label: '用量', render: (r) => <span className="num">{r.used_count ?? 0}/{r.max_uses ?? '∞'}</span> },
      { label: '状态', render: (r) => bool(r.enabled) },
    ],
    fields: [
      { key: 'code', label: '兑换码', type: 'text' },
      { key: 'vip_days', label: '赠送天数', type: 'number' },
      { key: 'max_uses', label: '最大次数', type: 'number' },
      { key: 'enabled', label: '启用', type: 'switch' },
      { key: 'description', label: '备注', type: 'text' },
    ],
  },
  {
    key: 'events', label: '活动', group: '运营',
    columns: [
      { label: 'ID', render: (r) => <span className="num">{r.id}</span> },
      { label: '类型', render: (r) => <span className="tag">{r.type}</span> },
      { label: '开始', render: (r) => <span className="num">{(r.starts_at || '').replace('T', ' ').slice(0, 16)}</span> },
      { label: '结束', render: (r) => <span className="num">{(r.ends_at || '').replace('T', ' ').slice(0, 16)}</span> },
      { label: '状态', render: (r) => bool(r.enabled) },
    ],
    fields: [
      { key: 'type', label: '类型', type: 'select', opts: [['half_price', '半价'], ['buy_one_free_one', '买一送一'], ['jump_only', '仅跳转']] },
      { key: 'jump_url', label: '跳转链接', type: 'text' },
      { key: 'description', label: '描述', type: 'textarea' },
      { key: 'enabled', label: '启用', type: 'switch' },
    ],
  },
]

export const moduleByKey = (k) => MODULES.find((m) => m.key === k)

// All content here is placeholder/sample data for the UI clone.
import {
  Clapperboard, Ban, Download, Zap, Gem,
  Ticket, CalendarDays, Image, MessageCircle, CreditCard,
} from 'lucide-react'

export const GENRES = [
  '推荐', '都市', '古装', '悬疑', '逆袭', '穿越', '奇幻', '甜宠',
  '玄幻', '大女主', '复仇', '科幻', '恐怖', '异能', '漫改', '精品',
]

// deterministic poster gradient per id (no external assets)
const GRADS = [
  ['#ff8a2b', '#e8480a'], ['#5b8bff', '#2a3f8f'], ['#38c172', '#0f5c3a'],
  ['#b06bff', '#5a2a9a'], ['#ff6a3d', '#8a2010'], ['#ffd75e', '#c08a10'],
  ['#4dd0e1', '#0e5560'], ['#ff4d6d', '#8a1030'], ['#9ae66e', '#3a6a1a'],
  ['#ff9bb3', '#a03050'], ['#7c9cff', '#2a3a8f'], ['#ffb86b', '#a05a10'],
]
export const gradFor = (id) => GRADS[id % GRADS.length]

const TITLES = [
  '重返都市当女王', '龙帝归来', '闪婚老公竟是首富', '穿越之农门贵妃',
  '天才萌宝驾到', '婚后隐婚总裁宠上天', '重生复仇千金归', '神医赘婿',
  '当反派变成我的白月光', '末世重生我囤货称王', '古董局中局', '深海迷踪',
  '规则怪谈之午夜列车', '异能觉醒时代', '大小姐的贴身高手', '一胎三宝爹地追妻',
  '穿书成了恶毒女配', '玄门弃女翻身记', '总裁的隐婚新娘', '星际最强佣兵',
  '离婚后我惊艳了全球', '傅先生的心尖宠', '万渣朝凰', '快穿之炮灰逆袭手册',
]
const SUBS = ['精品·大神原创', '都市', '古装', '穿越', '甜宠', '逆袭', '悬疑', '复仇', '玄幻', '科幻']
const TAGSETS = [
  ['精品', '大神原创'], ['穿越', '甜宠'], ['都市', '逆袭'], ['悬疑', '恐怖'],
  ['古装', '大女主'], ['复仇', '爽文'], ['玄幻', '异能'], ['科幻'],
]

function play(id) {
  const n = 30 + ((id * 37) % 470)
  return n > 100 ? `${(n / 10).toFixed(1)}万` : `${n}万`
}

export const DRAMAS = Array.from({ length: 36 }, (_, i) => {
  const id = 100 + i
  const eps = 12 + ((id * 7) % 60)
  const done = id % 3 === 0
  return {
    id,
    t: TITLES[i % TITLES.length] + (i >= TITLES.length ? ' Ⅱ' : ''),
    sub: SUBS[id % SUBS.length],
    tags: TAGSETS[id % TAGSETS.length],
    plays: play(id),
    eps,
    serial: done ? '已完结' : '连载中',
    free: id % 4 !== 0,
    top: i < 6,
    genre: GENRES[1 + (id % (GENRES.length - 1))],
    desc: '一场跨越身份与命运的逆袭故事。她本是被人轻视的落魄千金，一朝觉醒惊世才华，携手神秘强者，步步为营重夺属于自己的一切，让所有看轻她的人追悔莫及。',
  }
})

export const dramaById = (id) => DRAMAS.find((d) => d.id === Number(id)) || DRAMAS[0]

export const HOT_SEARCH = [
  '重返都市当女王', '闪婚老公竟是首富', '规则怪谈', '一胎三宝', '龙帝归来',
  '穿书恶毒女配', '神医赘婿', '末世囤货', '大小姐贴身高手', '万渣朝凰',
]

export const TOPICS = [
  { id: 1, title: '一口气看完·高分爽剧', sub: '32部精选', count: 32 },
  { id: 2, title: '穿越重生·换个人生', sub: '28部精选', count: 28 },
  { id: 3, title: '霸总甜宠·恋爱脑必看', sub: '41部精选', count: 41 },
  { id: 4, title: '悬疑烧脑·反转到底', sub: '19部精选', count: 19 },
  { id: 5, title: '大女主·乘风破浪', sub: '24部精选', count: 24 },
  { id: 6, title: '规则怪谈·深夜勿看', sub: '15部精选', count: 15 },
]

export const PLANS = [
  { id: 1, name: '月卡', price: 25, origin: 30, unit: '月', duration: 30, sub: '每月自动续费可取消', rights: ['r1', 'r2'] },
  { id: 2, name: '季卡', price: 57, origin: 90, unit: '季', duration: 90, sub: '折合每月19元', rights: ['r1', 'r2', 'r4'], hot: true },
  { id: 3, name: '年卡', price: 228, origin: 360, unit: '年', duration: 365, sub: '折合每月19元 · 超值', rights: ['r1', 'r2', 'r3', 'r4', 'r5'] },
]

export const RIGHTS = [
  { id: 'r1', ic: Clapperboard, name: '全站免费看', desc: '海量剧集畅享无门槛' },
  { id: 'r2', ic: Ban, name: '免广告', desc: '去除片前及暂停广告' },
  { id: 'r3', ic: Download, name: '离线下载', desc: '缓存到本地随时看' },
  { id: 'r4', ic: Zap, name: '抢先更新', desc: '会员专享抢先看' },
  { id: 'r5', ic: Gem, name: '专属标识', desc: '尊贵会员身份标识' },
]

export const SHOP_ITEMS = [
  { id: 1, name: '7天会员体验卡', cost: 800, ic: Ticket, stock: 120 },
  { id: 2, name: '月卡兑换券', cost: 2400, ic: CalendarDays, stock: 45 },
  { id: 3, name: '专属头像框', cost: 300, ic: Image, stock: 999 },
  { id: 4, name: '弹幕彩色特权', cost: 500, ic: MessageCircle, stock: 999 },
  { id: 5, name: '定制身份卡', cost: 1200, ic: CreditCard, stock: 60 },
  { id: 6, name: '免广告7天', cost: 200, ic: Ban, stock: 999 },
]

export const TASKS = [
  { id: 1, name: '每日签到', reward: 10, done: false, action: '签到' },
  { id: 2, name: '观看任意剧集3集', reward: 15, done: true, action: '已完成' },
  { id: 3, name: '收藏1部剧集', reward: 5, done: false, action: '去完成' },
  { id: 4, name: '分享1部剧集', reward: 10, done: false, action: '去完成' },
  { id: 5, name: '发表1条评论', reward: 8, done: false, action: '去完成' },
  { id: 6, name: '连续签到7天', reward: 50, done: false, action: '进行中' },
]

export const WISHES = [
  { id: 1, title: '重返都市当女王', dir: '换个结局：女主称帝', votes: 3820, mine: false },
  { id: 2, title: '龙帝归来', dir: '群像扩写：兄弟七人番外', votes: 2910, mine: true },
  { id: 3, title: '神医赘婿', dir: '反派翻盘：岳父洗白线', votes: 2455, mine: false },
  { id: 4, title: '穿书恶毒女配', dir: '换个结局：女配和女主双赢', votes: 1980, mine: false },
  { id: 5, title: '末世重生囤货', dir: '群像扩写：末世基地日常', votes: 1560, mine: false },
]

export const ORDERS = [
  { id: 'O202607080012', plan: '季卡', amount: 57, status: '已支付', time: '2026-07-05 21:14', pay: '微信支付' },
  { id: 'O202604180934', plan: '月卡', amount: 25, status: '已退款', time: '2026-04-18 09:34', pay: '支付宝' },
  { id: 'O202601120088', plan: '年卡', amount: 228, status: '已支付', time: '2026-01-12 00:08', pay: '微信支付' },
]

export const MESSAGES = [
  { id: 1, title: '会员到期提醒', body: '您的季卡将于 2026-10-03 到期，续费享9折优惠。', time: '07-06 10:20', read: false, from: '系统' },
  { id: 2, title: '你的提名已采纳', body: '感谢参与「魔改愿望榜」，你提名的改编方向已进入制作评估。', time: '07-02 18:41', read: false, from: '官方' },
  { id: 3, title: '积分到账通知', body: '连续签到奖励 50 积分已到账，可前往积分商城兑换好礼。', time: '06-28 08:00', read: true, from: '系统' },
]

export const NOTICES = [
  { id: 1, title: '关于会员服务升级的公告', body: '为提供更优质的观看体验，我们将于近期升级会员服务体系，新增离线下载与抢先更新权益。', time: '2026-07-01', top: true },
  { id: 2, title: '暑期精品剧集上新计划', body: '7月起每周三、周六上新精品短剧，敬请期待。', time: '2026-06-25', top: false },
  { id: 3, title: '账号安全提醒', body: '请勿在非官方渠道充值，谨防诈骗。官方唯一网址请以站内公示为准。', time: '2026-06-10', top: false },
]

export const SURVEYS = [
  {
    id: 1, title: '短剧内容体验调研', people: 1284, status: 'open',
    questions: [
      { id: 1, type: 'single', q: '你最喜欢的题材是？', options: ['都市逆袭', '古装甜宠', '悬疑烧脑', '穿越重生'] },
      { id: 2, type: 'multi', q: '你通常在什么时段看剧？（多选）', options: ['早晨通勤', '午休', '晚上睡前', '周末'] },
      { id: 3, type: 'text', q: '还有什么想对我们说的？', placeholder: '说点什么…（可留空）' },
    ],
  },
]

export const FEEDBACK_TYPES = ['播放卡顿', '内容问题', '会员/订单', '功能建议', '其他']

export const MY_FEEDBACKS = [
  { id: 1, type: '播放卡顿', body: '第5集加载很慢', status: '已解决', reply: '已优化对应线路，感谢反馈。', time: '07-03' },
  { id: 2, type: '功能建议', body: '希望增加倍速播放', status: '待处理', reply: '', time: '07-06' },
]

export const USER = {
  name: '橙子用户_8848',
  id: 'UID 10028848',
  vip: true,
  vipExpire: '2026-10-03',
  points: 1860,
  avatar: '橙',
}

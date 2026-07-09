// mercury-drama API endpoints + adapters that map backend shapes to this UI.
import { get, post, del, getToken, setToken, adminGet, getAdminToken, setAdminToken } from './http.js'

export { getToken, setToken, getAdminToken, setAdminToken }

/* ---------- admin (uses admin token; responses are plaintext) ---------- */
export const adminCategories = (params) => adminGet('/admin/categories', params)
export const adminVideos = (params) => adminGet('/admin/videos', params)

/* ---------- auth ---------- */
export const apiLogin = (account, password) => post('/login', { account, password })
export const apiRegister = (nickname, password) =>
  post('/register', { nickname, password, password_confirmation: password })
export const apiQuickRegister = () => post('/quick-register')
export const apiLogout = () => post('/logout')
export const apiMe = () => get('/me')

/* ---------- content (optional `lang` arg lets us prefetch other locales) ---------- */
export const apiCategories = (lang) => get('/categories', undefined, lang)
export const apiBanners = (lang) => get('/banners', undefined, lang)
export const apiMarquees = (lang) => get('/marquees', undefined, lang)
export const apiSiteSettings = (lang) => get('/site-settings', undefined, lang)
export const apiVideos = (params, lang) => get('/videos', params, lang) // {category_id,is_vip,country,keyword,page,per_page}
export const apiLatest = (lang) => get('/videos/latest', undefined, lang)
export const apiRecommended = (lang) => get('/videos/recommended', undefined, lang)
export const apiVideoDetail = (id, lang) => get(`/videos/${id}`, undefined, lang)

/* ---------- vip / orders ---------- */
export const apiVipPlans = (lang) => get('/vip/plans', undefined, lang) // keyed object {key: plan}
export const apiPaymentOptions = () => get('/vip/payment-options')
export const apiCreateOrder = (plan, gateway_id, pay_type_id) =>
  post('/vip/order', { plan, gateway_id, pay_type_id })
export const apiMyOrders = () => get('/vip/orders')
export const apiActiveEvent = () => get('/event/active')

/* ---------- user data ---------- */
export const apiToggleFavorite = (videoId) => post(`/favorites/${videoId}`)
export const apiFavorites = (params) => get('/favorites', params)
export const apiWatchHistory = (params) => get('/watch-history', params)
export const apiRecordWatch = (videoId) => post(`/watch-history/${videoId}`)
export const apiClearHistory = () => del('/watch-history')
export const apiRedeem = (code) => post('/redeem', { code })
export const apiRedeemHistory = () => get('/redeem/history')

/* ---------- adapters: backend shapes -> UI shapes ---------- */

// Some backend zh translations were entered bilingually ("中文 English").
// Show only the leading CJK part when a Latin tail follows.
export function cleanName(s) {
  if (!s) return s || ''
  if (/[一-鿿]/.test(s)) {
    return s.replace(/\s+[A-Za-z0-9][A-Za-z0-9\s'’&/.,-]*$/, '').trim()
  }
  return s
}

export const fmtPlays = (n) => {
  const num = Number(n) || 0
  return num >= 10000 ? `${(num / 10000).toFixed(1)}万` : String(num)
}

export const fmtDuration = (sec) => {
  const s = Number(sec) || 0
  const m = Math.floor(s / 60)
  return m >= 60 ? `${Math.floor(m / 60)}小时${m % 60}分` : `${m}分钟`
}

// Video (list item / detail) -> UI drama card shape
export function adaptVideo(v) {
  const genre = cleanName(v.category?.name || '')
  return {
    id: v.id,
    t: cleanName(v.title),
    cover: v.cover_url || null,
    plays: fmtPlays(v.view_count),
    viewCount: v.view_count ?? 0,
    duration: v.duration ?? 0,
    eps: 1, // mercury-drama is single-video; UI degrades 选集 to 正片
    serial: v.is_vip ? 'VIP' : '免费',
    free: !v.is_vip,
    genre,
    sub: genre,
    tags: genre ? [genre] : [],
    desc: v.description || '',
    country: v.country || '',
    createdAt: v.created_at,
    // detail-only fields (undefined on list items)
    playUrl: v.play_url,
    playType: v.play_type,
    keyUrl: v.key_url ?? null,
    canPlayFull: v.can_play_full,
    previewUrl: v.preview_url,
    trialSeconds: v.vip_trial_seconds,
    vipMessage: v.vip_required_message,
    isFavorited: v.is_favorited,
  }
}

// keyed plans object -> UI plan array
export function adaptPlans(plansObj) {
  return Object.values(plansObj || {}).map((p) => ({
    id: p.key,
    key: p.key,
    name: p.name,
    price: Number(p.event_price ?? p.price),
    origin: Number(p.original_price ?? p.price),
    duration: p.days,
    sub: p.description || '',
    hot: !!p.tag,
    tag: p.tag || '',
    eventLabel: p.event_label || '',
  }))
}

export const ORDER_STATUS = { 0: '待支付', 1: '已支付', 2: '已取消', 3: '退款中', 4: '已退款' }

export function adaptOrder(o) {
  return {
    id: o.order_no,
    plan: o.plan_name,
    amount: o.amount,
    status: ORDER_STATUS[o.status] ?? String(o.status),
    statusCode: o.status,
    time: (o.created_at || '').replace('T', ' ').slice(0, 16),
    pay: o.payment_method || '—',
    days: o.days,
  }
}

/* Warm the cache for other languages in the background so switching is instant.
   Fires the main content endpoints per locale; per-id detail pages are skipped. */
export function prefetchLanguages(codes, currentLang) {
  const others = codes.filter((c) => c !== currentLang)
  const run = () => {
    for (const lang of others) {
      apiCategories(lang)
      apiVideos({ page: 1, per_page: 18 }, lang)
      apiLatest(lang)
      apiRecommended(lang)
      apiMarquees(lang)
      apiBanners(lang)
      apiVipPlans && apiVipPlans(lang)
      apiSiteSettings(lang)
    }
  }
  if (typeof requestIdleCallback === 'function') requestIdleCallback(run, { timeout: 4000 })
  else setTimeout(run, 1500)
}

/* try API, fall back to local mock so the UI works without a backend */
export async function tryApi(fn, fallback) {
  try {
    const r = await fn()
    return { data: r, live: true }
  } catch {
    return { data: typeof fallback === 'function' ? fallback() : fallback, live: false }
  }
}

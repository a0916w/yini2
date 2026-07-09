// Lightweight UI-chrome i18n. Content (titles, categories, plans) is localized
// server-side via the ?lang= param; this dictionary covers the app shell.
// Language switch persists to localStorage and reloads so every page refetches.
import { getLang, setLang } from './api/http.js'

export const LANGUAGES = [
  { code: 'zh', name: '中文' },
  { code: 'en', name: 'English' },
  { code: 'vi', name: 'Tiếng Việt' },
  { code: 'th', name: 'ภาษาไทย' },
  { code: 'id', name: 'Bahasa Indonesia' },
]

const DICT = {
  home:    { zh: '首页', en: 'Home', vi: 'Trang chủ', th: 'หน้าแรก', id: 'Beranda' },
  remake:  { zh: '魔改', en: 'Remake', vi: 'Chế lại', th: 'รีเมค', id: 'Ubahan' },
  wishlist:{ zh: '心愿榜', en: 'Wishlist', vi: 'Mong muốn', th: 'รายการโปรด', id: 'Keinginan' },
  topics:  { zh: '专题', en: 'Topics', vi: 'Chủ đề', th: 'หัวข้อ', id: 'Topik' },
  me:      { zh: '我的', en: 'Me', vi: 'Tôi', th: 'ฉัน', id: 'Saya' },
  searchPh:{ zh: '搜索短剧、剧情…', en: 'Search dramas…', vi: 'Tìm phim ngắn…', th: 'ค้นหาละคร…', id: 'Cari drama…' },
  search:  { zh: '搜索', en: 'Search', vi: 'Tìm kiếm', th: 'ค้นหา', id: 'Cari' },
  vip:     { zh: '会员', en: 'VIP', vi: 'VIP', th: 'วีไอพี', id: 'VIP' },
  watchNow:{ zh: '立即观看', en: 'Watch Now', vi: 'Xem ngay', th: 'ดูเลย', id: 'Tonton' },
  favorite:{ zh: '收藏', en: 'Favorite', vi: 'Yêu thích', th: 'บันทึก', id: 'Favorit' },
  faved:   { zh: '已收藏', en: 'Favorited', vi: 'Đã lưu', th: 'บันทึกแล้ว', id: 'Tersimpan' },
  comment: { zh: '评论', en: 'Comment', vi: 'Bình luận', th: 'ความคิดเห็น', id: 'Komentar' },
  loadMore:{ zh: '加载更多', en: 'Load more', vi: 'Tải thêm', th: 'โหลดเพิ่ม', id: 'Muat lagi' },
  loading: { zh: '加载中…', en: 'Loading…', vi: 'Đang tải…', th: 'กำลังโหลด…', id: 'Memuat…' },
  empty:   { zh: '暂无内容', en: 'No content', vi: 'Chưa có nội dung', th: 'ไม่มีเนื้อหา', id: 'Tidak ada konten' },
  all:     { zh: '全部', en: 'All', vi: 'Tất cả', th: 'ทั้งหมด', id: 'Semua' },
  login:   { zh: '登录', en: 'Log in', vi: 'Đăng nhập', th: 'เข้าสู่ระบบ', id: 'Masuk' },
  logout:  { zh: '退出登录', en: 'Log out', vi: 'Đăng xuất', th: 'ออกจากระบบ', id: 'Keluar' },
  language:{ zh: '语言', en: 'Language', vi: 'Ngôn ngữ', th: 'ภาษา', id: 'Bahasa' },
  rankings:{ zh: '榜单', en: 'Rankings', vi: 'Xếp hạng', th: 'อันดับ', id: 'Peringkat' },
  profile: { zh: '个人中心', en: 'Profile', vi: 'Cá nhân', th: 'โปรไฟล์', id: 'Profil' },
}

export function t(key) {
  const l = getLang()
  const e = DICT[key]
  return e ? (e[l] ?? e.zh) : key
}

export function currentLang() { return getLang() }

// The app root registers a client-side switcher (no full page reload).
let _switcher = null
export function registerSwitcher(fn) { _switcher = fn }

export function changeLanguage(code) {
  if (code === getLang()) return
  if (_switcher) { _switcher(code); return }
  // fallback: hard navigation if no switcher registered yet
  setLang(code)
  const parts = window.location.pathname.split('/')
  if (LANGUAGES.some((l) => l.code === parts[1])) parts[1] = code
  else parts.splice(1, 0, code)
  window.location.assign(parts.join('/') + window.location.search)
}

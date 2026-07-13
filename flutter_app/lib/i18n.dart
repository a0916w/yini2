import 'api/http.dart';

const _langs = [
  ('zh', '中文'), ('en', 'English'), ('vi', 'Tiếng Việt'), ('th', 'ภาษาไทย'), ('id', 'Bahasa Indonesia'),
];
List<(String, String)> get languages => _langs;

const _dict = <String, Map<String, String>>{
  'home': {'zh': '首页', 'en': 'Home', 'vi': 'Trang chủ', 'th': 'หน้าแรก', 'id': 'Beranda'},
  'topics': {'zh': '专题', 'en': 'Topics', 'vi': 'Chủ đề', 'th': 'หัวข้อ', 'id': 'Topik'},
  'rank': {'zh': '榜单', 'en': 'Rankings', 'vi': 'Xếp hạng', 'th': 'อันดับ', 'id': 'Peringkat'},
  'me': {'zh': '我的', 'en': 'Me', 'vi': 'Tôi', 'th': 'ฉัน', 'id': 'Saya'},
  'searchPh': {'zh': '搜索短剧、剧情…', 'en': 'Search dramas…', 'vi': 'Tìm phim…', 'th': 'ค้นหาละคร…', 'id': 'Cari drama…'},
  'vip': {'zh': '会员', 'en': 'VIP', 'vi': 'VIP', 'th': 'วีไอพี', 'id': 'VIP'},
  'watchNow': {'zh': '立即观看', 'en': 'Watch Now', 'vi': 'Xem ngay', 'th': 'ดูเลย', 'id': 'Tonton'},
  'favorite': {'zh': '收藏', 'en': 'Favorite', 'vi': 'Yêu thích', 'th': 'บันทึก', 'id': 'Favorit'},
  'faved': {'zh': '已收藏', 'en': 'Favorited', 'vi': 'Đã lưu', 'th': 'บันทึกแล้ว', 'id': 'Tersimpan'},
  'all': {'zh': '全部', 'en': 'All', 'vi': 'Tất cả', 'th': 'ทั้งหมด', 'id': 'Semua'},
  'login': {'zh': '登录', 'en': 'Log in', 'vi': 'Đăng nhập', 'th': 'เข้าสู่ระบบ', 'id': 'Masuk'},
  'logout': {'zh': '退出登录', 'en': 'Log out', 'vi': 'Đăng xuất', 'th': 'ออกจากระบบ', 'id': 'Keluar'},
  'loading': {'zh': '加载中…', 'en': 'Loading…', 'vi': 'Đang tải…', 'th': 'กำลังโหลด…', 'id': 'Memuat…'},
  'empty': {'zh': '暂无内容', 'en': 'No content', 'vi': 'Chưa có nội dung', 'th': 'ไม่มีเนื้อหา', 'id': 'Tidak ada'},
  'loadMore': {'zh': '加载更多', 'en': 'Load more', 'vi': 'Tải thêm', 'th': 'โหลดเพิ่ม', 'id': 'Muat lagi'},
};

String t(String key) {
  final e = _dict[key];
  if (e == null) return key;
  return e[Http.lang] ?? e['zh'] ?? key;
}

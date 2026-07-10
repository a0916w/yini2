import { get, post, put, del } from './http.js'

/* auth */
export const apiLogin = (account, password) => post('/login', { account, password })
export const apiMe = () => get('/me')

/* dashboard */
export const apiDashboard = () => get('/admin/dashboard')

/* generic admin CRUD by resource path */
export const listResource = (res, params) => get(`/admin/${res}`, params)
export const getResource = (res, id) => get(`/admin/${res}/${id}`)
export const createResource = (res, data) => post(`/admin/${res}`, data)
export const updateResource = (res, id, data) => put(`/admin/${res}/${id}`, data)
export const deleteResource = (res, id) => del(`/admin/${res}/${id}`)

/* public helpers for the overview */
export const apiRecommended = () => get('/videos/recommended')

/* ---- shape helpers ---- */
// Laravel returns arrays (categories) or paginators (videos/users/orders).
export function unwrapList(body) {
  if (Array.isArray(body)) return { rows: body, total: body.length, page: 1, lastPage: 1 }
  return { rows: body?.data || [], total: body?.total ?? (body?.data || []).length, page: body?.current_page || 1, lastPage: body?.last_page || 1 }
}
export function unwrapOne(body) { return body?.data || body }

export function cleanName(s) {
  if (!s) return s || ''
  if (/[一-鿿]/.test(s)) return s.replace(/\s+[A-Za-z0-9][A-Za-z0-9\s'’&/.,-]*$/, '').trim()
  return s
}
export const wan = (n) => { const v = Number(n) || 0; return v >= 10000 ? (v / 10000).toFixed(1) + '万' : String(v) }
export const yuan = (n) => '¥' + (Number(n) || 0).toLocaleString('en-US')

import { httpClient } from './httpClient.js'

const API = '/api/admin'

// Maps react-admin resource names -> Laravel admin endpoints.
// getList handles both plain arrays (categories) and Laravel paginators (videos).
export const dataProvider = {
  async getList(resource, params) {
    const { page = 1, perPage = 20 } = params.pagination || {}
    const { field, order } = params.sort || {}
    const q = new URLSearchParams()
    q.set('page', page)
    q.set('per_page', perPage)
    if (field === 'sort_order') q.set('sort', 'sort_order')
    const f = params.filter || {}
    if (f.q) q.set('keyword', f.q)
    if (f.enabled !== undefined && f.enabled !== '') q.set('enabled', f.enabled ? 1 : 0)
    if (f.is_vip !== undefined && f.is_vip !== '') q.set('is_vip', f.is_vip ? 1 : 0)
    if (f.category_id) q.set('category_id', f.category_id)

    const { json } = await httpClient(`${API}/${resource}?${q.toString()}`)
    if (Array.isArray(json)) {
      // categories: unpaginated array
      return { data: json, total: json.length }
    }
    return { data: json.data || [], total: json.total ?? (json.data || []).length }
  },

  async getOne(resource, params) {
    const { json } = await httpClient(`${API}/${resource}/${params.id}`)
    return { data: json.data || json }
  },

  async getMany(resource, params) {
    // simple: fetch a big page and filter client-side (categories are small)
    const { json } = await httpClient(`${API}/${resource}?per_page=500`)
    const list = Array.isArray(json) ? json : (json.data || [])
    const ids = params.ids.map(String)
    return { data: list.filter((r) => ids.includes(String(r.id))) }
  },

  async getManyReference(resource, params) {
    const q = new URLSearchParams()
    q.set('per_page', params.pagination?.perPage || 50)
    if (params.target && params.id != null) q.set(params.target, params.id)
    const { json } = await httpClient(`${API}/${resource}?${q.toString()}`)
    const list = Array.isArray(json) ? json : (json.data || [])
    return { data: list, total: json.total ?? list.length }
  },

  async update(resource, params) {
    const { json } = await httpClient(`${API}/${resource}/${params.id}`, {
      method: 'PUT',
      body: JSON.stringify(params.data),
    })
    return { data: json.data || json || params.data }
  },

  async create(resource, params) {
    const { json } = await httpClient(`${API}/${resource}`, {
      method: 'POST',
      body: JSON.stringify(params.data),
    })
    return { data: json.data || json }
  },

  async delete(resource, params) {
    await httpClient(`${API}/${resource}/${params.id}`, { method: 'DELETE' })
    return { data: params.previousData || { id: params.id } }
  },

  async deleteMany(resource, params) {
    await Promise.all(params.ids.map((id) => httpClient(`${API}/${resource}/${id}`, { method: 'DELETE' })))
    return { data: params.ids }
  },
}

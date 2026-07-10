import { useState, useEffect, useCallback } from 'react'
import { useParams } from 'react-router-dom'
import Shell from '../components/Shell.jsx'
import Drawer from '../components/Drawer.jsx'
import { moduleByKey } from '../config/modules.jsx'
import { listResource, getResource, createResource, updateResource, deleteResource, unwrapList, unwrapOne } from '../api/admin.js'

export default function ModuleList() {
  const { key } = useParams()
  const mod = moduleByKey(key)

  const [rows, setRows] = useState([])
  const [meta, setMeta] = useState({ total: 0, page: 1, lastPage: 1 })
  const [loading, setLoading] = useState(true)
  const [err, setErr] = useState('')
  const [filters, setFilters] = useState({})
  const [page, setPage] = useState(1)
  const [editing, setEditing] = useState(null) // {record}|'new'|null
  const [toast, setToast] = useState('')

  const flash = (m) => { setToast(m); setTimeout(() => setToast(''), 1800) }

  const load = useCallback(async () => {
    if (!mod) return
    setLoading(true); setErr('')
    try {
      const body = await listResource(mod.key, { ...filters, page, per_page: 20 })
      const u = unwrapList(body)
      setRows(u.rows); setMeta({ total: u.total, page: u.page, lastPage: u.lastPage })
    } catch (e) { setErr(e.message); setRows([]) }
    finally { setLoading(false) }
  }, [mod, filters, page])

  useEffect(() => { setPage(1); setFilters({}) }, [key])
  useEffect(() => { load() }, [load])

  if (!mod) return <Shell title="未找到"><div className="center">模块不存在</div></Shell>

  const openRow = async (r) => {
    if (mod.readonly || !mod.fields) return
    try { const full = unwrapOne(await getResource(mod.key, r.id)); setEditing(full || r) }
    catch { setEditing(r) }
  }

  const save = async (form) => {
    try {
      if (editing === 'new') { await createResource(mod.key, form); flash('已创建') }
      else { await updateResource(mod.key, editing.id, form); flash('已保存') }
      setEditing(null); load()
    } catch (e) { flash('保存失败：' + e.message) }
  }
  const remove = async (rec) => {
    try { await deleteResource(mod.key, rec.id); flash('已删除'); setEditing(null); load() }
    catch (e) { flash('删除失败：' + e.message) }
  }

  return (
    <Shell title={mod.label} live={`共 ${meta.total} 条`}>
      <div className="scroll">
        <div className="panel">
          <div className="toolbar">
            {(mod.filters || []).map((f) => f.kind === 'search' ? (
              <input key={f.key} className="input" placeholder={f.ph} defaultValue={filters[f.key] || ''}
                onKeyDown={(e) => { if (e.key === 'Enter') { setPage(1); setFilters((s) => ({ ...s, [f.key]: e.target.value })) } }} />
            ) : (
              <select key={f.key} className="select" value={filters[f.key] ?? ''}
                onChange={(e) => { setPage(1); setFilters((s) => ({ ...s, [f.key]: e.target.value })) }}>
                {f.opts.map(([v, l]) => <option key={String(v)} value={v}>{l}</option>)}
              </select>
            ))}
            <div className="spacer" />
            {mod.create && <button className="tbtn tbtn--signal" onClick={() => setEditing('new')}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 5v14M5 12h14" /></svg>新建
            </button>}
          </div>

          {err && <div className="err">加载失败：{err}（确认 admin token 有效）</div>}

          <div className="tbl-wrap">
            <table>
              <thead><tr>{mod.columns.map((c, i) => <th key={i}>{c.label}</th>)}</tr></thead>
              <tbody>
                {loading ? <tr><td colSpan={mod.columns.length}><div className="empty">加载中…</div></td></tr>
                  : rows.length === 0 ? <tr><td colSpan={mod.columns.length}><div className="empty">暂无数据</div></td></tr>
                    : rows.map((r) => (
                      <tr key={r.id || r.order_no} className={mod.readonly ? '' : 'clickable'} onClick={() => openRow(r)}>
                        {mod.columns.map((c, i) => <td key={i}>{c.render(r)}</td>)}
                      </tr>
                    ))}
              </tbody>
            </table>
          </div>

          {meta.lastPage > 1 && (
            <div className="pager">
              <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>上一页</button>
              <span>第 {meta.page} / {meta.lastPage} 页 · 共 {meta.total} 条</span>
              <button disabled={page >= meta.lastPage} onClick={() => setPage((p) => p + 1)}>下一页</button>
            </div>
          )}
        </div>
      </div>

      {editing && mod.fields && (
        <Drawer
          title={editing === 'new' ? `新建${mod.label}` : `编辑${mod.label}`}
          fields={mod.fields}
          initial={editing === 'new' ? null : editing}
          onClose={() => setEditing(null)}
          onSave={save}
          onDelete={mod.create ? remove : undefined}
        />
      )}
      {toast && <div className="toast">{toast}</div>}
    </Shell>
  )
}

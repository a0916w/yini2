import { useState, useEffect } from 'react'

export default function Drawer({ title, fields, initial, onClose, onSave, onDelete }) {
  const [form, setForm] = useState({})
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    const f = {}
    fields.forEach((fd) => { f[fd.key] = initial ? initial[fd.key] : (fd.type === 'switch' ? false : '') })
    setForm(f)
  }, [initial, fields])

  const set = (k, v) => setForm((s) => ({ ...s, [k]: v }))

  const save = async () => {
    setBusy(true)
    try { await onSave(form) } finally { setBusy(false) }
  }

  return (
    <>
      <div className="mask" onClick={onClose} />
      <aside className="drawer" role="dialog" aria-label={title}>
        <div className="drawer__head">
          <span className="drawer__title">{title}</span>
          <div className="spacer" />
          <button className="tbtn" onClick={onClose} aria-label="关闭">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 6l12 12M18 6L6 18" /></svg>
          </button>
        </div>
        <div className="drawer__body">
          {fields.map((fd) => (
            <div className="field" key={fd.key}>
              <label htmlFor={'f_' + fd.key}>{fd.label}</label>
              {fd.type === 'textarea' ? (
                <textarea id={'f_' + fd.key} value={form[fd.key] ?? ''} onChange={(e) => set(fd.key, e.target.value)} />
              ) : fd.type === 'switch' ? (
                <label className="switch">
                  <input type="checkbox" checked={!!form[fd.key]} onChange={(e) => set(fd.key, e.target.checked)} />
                  <span className="switch__track" />
                  <span style={{ fontSize: 13, color: 'var(--ink-dim)' }}>{form[fd.key] ? '开' : '关'}</span>
                </label>
              ) : fd.type === 'select' ? (
                <select className="select" id={'f_' + fd.key} value={form[fd.key] ?? ''} onChange={(e) => set(fd.key, e.target.value)}>
                  {fd.opts.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                </select>
              ) : (
                <input className={`input ${fd.type === 'number' ? 'mono' : ''}`} id={'f_' + fd.key}
                  type={fd.type === 'number' ? 'number' : 'text'}
                  value={form[fd.key] ?? ''} onChange={(e) => set(fd.key, fd.type === 'number' ? (e.target.value === '' ? '' : Number(e.target.value)) : e.target.value)} />
              )}
            </div>
          ))}
        </div>
        <div className="drawer__foot">
          {onDelete && initial && <button className="btn" style={{ color: 'var(--crit)' }} onClick={() => onDelete(initial)}>删除</button>}
          <button className="btn btn--signal btn--block" disabled={busy} onClick={save}>{busy ? '保存中…' : '保存'}</button>
        </div>
      </aside>
    </>
  )
}

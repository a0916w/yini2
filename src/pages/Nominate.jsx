import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Header } from '../components/ui.jsx'
import { useStore } from '../store.jsx'

const DIRS = ['换个结局', '反派翻盘', '群像扩写', '换账号视角', '全员沙雕', '其他']

export default function Nominate() {
  const nav = useNavigate()
  const { showToast } = useStore()
  const [title, setTitle] = useState('')
  const [dir, setDir] = useState(DIRS[0])
  const [detail, setDetail] = useState('')

  const submit = () => {
    if (!title.trim()) return showToast('请填写心愿标题')
    showToast('提交提名成功')
    setTimeout(() => nav('/wishes'), 800)
  }

  return (
    <>
      <Header title="我要提名" />
      <div className="page pad">
        <div className="field">
          <label className="field__label">心愿标题（20字以内）</label>
          <input className="input" maxLength={20} placeholder="想看哪部剧被改编？" value={title} onChange={(e) => setTitle(e.target.value)} />
        </div>
        <div className="field">
          <label className="field__label">改编方向（单选）</label>
          <div className="chips" style={{ flexWrap: 'wrap' }}>
            {DIRS.map((d) => (
              <button key={d} className={`chip ${dir === d ? 'active' : ''}`} onClick={() => setDir(d)}>{d}</button>
            ))}
          </div>
        </div>
        <div className="field">
          <label className="field__label">详细描述（可留空）</label>
          <textarea className="textarea" placeholder="说说你想看的改编脑洞…" value={detail} onChange={(e) => setDetail(e.target.value)} />
        </div>
        <div className="field">
          <label className="field__label">心愿封面（可选）</label>
          <button className="btn btn--ghost btn--block" onClick={() => showToast('上传中…')}>＋ 上传封面</button>
        </div>
        <button className="btn btn--brand btn--block" onClick={submit}>提交提名</button>
      </div>
    </>
  )
}

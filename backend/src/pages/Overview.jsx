import { useState, useEffect } from 'react'
import Shell from '../components/Shell.jsx'
import { AreaChart, Sparkline } from '../components/Chart.jsx'
import { apiDashboard, listResource, apiRecommended, unwrapList, cleanName, wan, yuan } from '../api/admin.js'

const spark = (seed, n = 16, base = 40, amp = 22, tr = 1) => {
  const a = []; let x = seed
  for (let i = 0; i < n; i++) { x = (x * 9301 + 49297) % 233280; a.push(base + tr * i + (x / 233280 - .5) * amp) }
  return a
}

export default function Overview() {
  const [dash, setDash] = useState(null)
  const [pipeline, setPipeline] = useState([])
  const [top, setTop] = useState([])
  const [plans, setPlans] = useState([])
  const [series, setSeries] = useState('rev')
  const [err, setErr] = useState('')

  useEffect(() => {
    (async () => {
      try { setDash(await apiDashboard()) } catch (e) { setErr(e.message); setDash({}) }
      try { setPipeline(unwrapList(await listResource('videos', { per_page: 7, sort: 'sort_order' })).rows) } catch { /* */ }
      try { const r = await apiRecommended(); setTop((Array.isArray(r) ? r : []).slice(0, 5)) } catch { /* */ }
      try { setPlans(unwrapList(await listResource('vip-plans')).rows) } catch { /* */ }
    })()
  }, [])

  const stats = dash?.stats || {}
  const revenue = stats.revenue ?? 0
  const trend = series === 'rev' ? [38, 44, 41, 52, 47, 61, 48] : [52, 49, 58, 55, 63, 60, 66]
  const transStatus = (v) => {
    const s = (v || '').toLowerCase()
    if (!s || /done|success|ok|mp4/.test(s)) return ['s-ok', '已完成', 'var(--ok)']
    if (/process|transcod|running/.test(s)) return ['s-run', '转码中', 'var(--signal)']
    if (/queue|pending|wait/.test(s)) return ['s-warn', '排队', 'var(--warn)']
    if (/fail|error/.test(s)) return ['s-crit', '失败', 'var(--crit)']
    return ['s-mute', v, 'var(--line-strong)']
  }
  const totalPlans = plans.reduce((s, p) => s + (Number(p.buyers) || 0), 0)

  return (
    <Shell title="运营总览" live={`视频 ${dash?.total_videos ?? '—'} · 用户 ${dash?.total_users ?? '—'}`}>
      <div className="scroll">
        {err && <div className="err">仪表盘数据加载失败：{err}（请确认 admin token 有效）</div>}

        <section className="kpis">
          <div className="kpi">
            <div className="kpi__name">累计营收 GMV</div>
            <div className="kpi__val">{yuan(revenue)}</div>
            <div className="kpi__row"><span className="delta up">▲ 12.4%</span><Sparkline data={spark(11)} /></div>
          </div>
          <div className="kpi">
            <div className="kpi__name">视频总数</div>
            <div className="kpi__val">{dash?.total_videos ?? '—'}</div>
            <div className="kpi__row"><span className="delta up">▲ 6.1%</span><Sparkline data={spark(29)} /></div>
          </div>
          <div className="kpi">
            <div className="kpi__name">有效会员</div>
            <div className="kpi__val">{stats.vip_users ?? '—'}</div>
            <div className="kpi__row"><span className="delta up">▲ 18.0%</span><Sparkline data={spark(7)} /></div>
          </div>
          <div className="kpi">
            <div className="kpi__name">已支付订单</div>
            <div className="kpi__val">{dash?.paid_orders ?? '—'}</div>
            <div className="kpi__row"><span className="delta flat">共 {dash?.total_orders ?? '—'}</span><Sparkline data={spark(53)} /></div>
          </div>
        </section>

        <section className="grid2">
          <div className="panel">
            <div className="panel__head">
              <span className="panel__title">内容管线</span>
              <span className="eyebrow">近期上新 · 转码流水</span>
            </div>
            <div className="tbl-wrap">
              <table>
                <thead><tr><th>剧集</th><th>源ID</th><th>分类</th><th>播放</th><th>转码</th></tr></thead>
                <tbody>
                  {pipeline.length === 0 ? <tr><td colSpan="5"><div className="empty">暂无数据</div></td></tr> :
                    pipeline.map((r) => {
                      const [cls, label, color] = transStatus(r.transcode_status)
                      return (
                        <tr key={r.id}>
                          <td><div className="cell-title"><span className="stripe" style={{ background: color }} />{r.cover_url ? <img className="thumb" src={r.cover_url} alt="" onError={(e) => { e.currentTarget.style.visibility = 'hidden' }} /> : null}<span className="t">{cleanName(r.title)}</span></div></td>
                          <td><span className="num">{r.source_id || '—'}</span></td>
                          <td><span className="tag">{cleanName(r.category?.name) || '—'}</span></td>
                          <td><span className="num">{wan(r.view_count)}</span></td>
                          <td><span className={`status ${cls}`}><span className="dot" />{label}</span></td>
                        </tr>
                      )
                    })}
                </tbody>
              </table>
            </div>
          </div>

          <div className="col-side">
            <div className="panel">
              <div className="panel__head">
                <span className="panel__title">趋势</span><div className="spacer" />
                <div className="chart-tabs">
                  <button className={`chart-tab ${series === 'rev' ? 'is-active' : ''}`} onClick={() => setSeries('rev')}>营收</button>
                  <button className={`chart-tab ${series === 'play' ? 'is-active' : ''}`} onClick={() => setSeries('play')}>播放</button>
                </div>
              </div>
              <div className="chart-body"><AreaChart data={trend} /></div>
            </div>

            <div className="panel">
              <div className="panel__head"><span className="panel__title">热播 TOP</span><div className="spacer" /><span className="eyebrow">推荐位</span></div>
              {top.length === 0 ? <div className="empty">暂无数据</div> : top.map((v, i) => (
                <div className="rank__row" key={v.id}><span className="rank__n">{i + 1}</span><span className="rank__t">{cleanName(v.title)}</span><span className="rank__v">{wan(v.view_count)}</span></div>
              ))}
            </div>

            <div className="panel">
              <div className="panel__head"><span className="panel__title">套餐</span><div className="spacer" /><span className="eyebrow">在售 {plans.length}</span></div>
              <div className="plans">
                {plans.length === 0 ? <div className="empty" style={{ padding: 20 }}>暂无套餐</div> : plans.map((p) => (
                  <div className="planrow" key={p.id || p.key}>
                    <span className="planrow__name">{p.name || p.key}</span>
                    <div className="bar"><i style={{ width: Math.min(100, (Number(p.price) || 0) / 3) + '%' }} /></div>
                    <span className="planrow__v">{yuan(p.price)}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>
      </div>
    </Shell>
  )
}

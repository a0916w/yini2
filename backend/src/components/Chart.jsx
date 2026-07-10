import { useEffect, useRef } from 'react'

function cssv(n) { return getComputedStyle(document.documentElement).getPropertyValue(n).trim() }
function toRGB(v) { const s = document.createElement('span'); s.style.color = v; document.body.appendChild(s); const c = getComputedStyle(s).color; s.remove(); return c }
const rgba = (rgb, a) => rgb.replace('rgb', 'rgba').replace(')', `, ${a})`)

export function Sparkline({ data, w = 96, h = 34 }) {
  const ref = useRef(null)
  useEffect(() => {
    const c = ref.current, dpr = window.devicePixelRatio || 1
    c.width = w * dpr; c.height = h * dpr
    const ctx = c.getContext('2d'); ctx.scale(dpr, dpr); ctx.clearRect(0, 0, w, h)
    const sig = toRGB(cssv('--signal')), pad = 3
    const min = Math.min(...data), max = Math.max(...data), rng = (max - min) || 1
    const X = (i) => pad + i * (w - pad * 2) / (data.length - 1)
    const Y = (v) => h - pad - (v - min) / rng * (h - pad * 2)
    const g = ctx.createLinearGradient(0, 0, 0, h)
    g.addColorStop(0, rgba(sig, .28)); g.addColorStop(1, rgba(sig, 0))
    ctx.beginPath(); ctx.moveTo(X(0), Y(data[0])); data.forEach((v, i) => ctx.lineTo(X(i), Y(v)))
    ctx.lineTo(X(data.length - 1), h); ctx.lineTo(X(0), h); ctx.fillStyle = g; ctx.fill()
    ctx.beginPath(); ctx.moveTo(X(0), Y(data[0])); data.forEach((v, i) => ctx.lineTo(X(i), Y(v)))
    ctx.strokeStyle = sig; ctx.lineWidth = 1.6; ctx.lineJoin = 'round'; ctx.stroke()
    ctx.beginPath(); ctx.arc(X(data.length - 1), Y(data.at(-1)), 2.4, 0, 7); ctx.fillStyle = sig; ctx.fill()
  })
  return <canvas ref={ref} style={{ width: w, height: h }} />
}

export function AreaChart({ data, height = 150 }) {
  const ref = useRef(null)
  useEffect(() => {
    const c = ref.current, dpr = window.devicePixelRatio || 1
    const rect = c.getBoundingClientRect(); const w = rect.width, h = height
    c.width = w * dpr; c.height = h * dpr
    const ctx = c.getContext('2d'); ctx.scale(dpr, dpr); ctx.clearRect(0, 0, w, h)
    if (!data.length) return
    const sig = toRGB(cssv('--signal')), grid = cssv('--grid'), panel = cssv('--panel')
    const padT = 12, padB = 8, padX = 6
    const min = Math.min(...data) * 0.82, max = Math.max(...data) * 1.05, rng = (max - min) || 1
    const X = (i) => padX + i * (w - padX * 2) / (data.length - 1)
    const Y = (v) => h - padB - (v - min) / rng * (h - padT - padB)
    ctx.strokeStyle = grid; ctx.lineWidth = 1
    for (let g = 0; g <= 3; g++) { const y = padT + g * (h - padT - padB) / 3; ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke() }
    const grad = ctx.createLinearGradient(0, padT, 0, h)
    grad.addColorStop(0, rgba(sig, .22)); grad.addColorStop(1, rgba(sig, 0))
    ctx.beginPath(); ctx.moveTo(X(0), Y(data[0])); data.forEach((v, i) => ctx.lineTo(X(i), Y(v)))
    ctx.lineTo(X(data.length - 1), h - padB); ctx.lineTo(X(0), h - padB); ctx.fillStyle = grad; ctx.fill()
    ctx.beginPath(); ctx.moveTo(X(0), Y(data[0])); data.forEach((v, i) => ctx.lineTo(X(i), Y(v)))
    ctx.strokeStyle = sig; ctx.lineWidth = 2; ctx.lineJoin = 'round'; ctx.stroke()
    data.forEach((v, i) => {
      const last = i === data.length - 1
      ctx.beginPath(); ctx.arc(X(i), Y(v), last ? 4 : 2.2, 0, 7)
      ctx.fillStyle = last ? sig : panel; ctx.strokeStyle = sig; ctx.lineWidth = 1.6
      ctx.fill(); if (!last) ctx.stroke()
    })
  })
  return <canvas ref={ref} style={{ width: '100%', height }} />
}

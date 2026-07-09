import { Check } from 'lucide-react'
import { Header } from '../components/ui.jsx'
import { LANGUAGES, currentLang, changeLanguage, t } from '../i18n.js'

export default function Language() {
  const cur = currentLang()
  return (
    <>
      <Header title={t('language')} />
      <div className="page pad">
        <div className="menu">
          {LANGUAGES.map((l) => (
            <button key={l.code} className="menu__item" style={{ width: '100%' }}
              onClick={() => { if (l.code !== cur) changeLanguage(l.code) }}>
              <span className="menu__lbl">{l.name}</span>
              {l.code === cur && <Check size={18} style={{ color: 'var(--brand)' }} />}
            </button>
          ))}
        </div>
      </div>
    </>
  )
}

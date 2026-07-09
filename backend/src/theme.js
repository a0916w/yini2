// Custom react-admin (MUI) theme — Hermès-orange brand, matching the front-end.
const BRAND = '#ff6d00'
const BRAND_DARK = '#e85d00'
const BRAND_GRAD = 'linear-gradient(90deg, #ff8a2b 0%, #f0560a 100%)'

const shared = {
  shape: { borderRadius: 12 },
  typography: {
    fontFamily: '-apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
    button: { textTransform: 'none', fontWeight: 700 },
    h6: { fontWeight: 800 },
  },
}

function components(dark) {
  const paperBg = dark ? '#161923' : '#ffffff'
  const border = dark ? '#262c3a' : '#eceef3'
  return {
    MuiAppBar: {
      styleOverrides: {
        root: {
          background: BRAND_GRAD,
          color: '#fff',
          boxShadow: '0 4px 18px rgba(255,109,0,.25)',
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: { borderRadius: 999, paddingInline: 16 },
        containedPrimary: { boxShadow: '0 4px 14px rgba(255,109,0,.3)' },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { backgroundImage: 'none' },
        elevation1: { boxShadow: dark ? '0 6px 20px rgba(0,0,0,.4)' : '0 4px 16px rgba(20,30,50,.08)' },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { borderRadius: 16, border: `1px solid ${border}` },
      },
    },
    RaMenuItemLink: {
      styleOverrides: {
        root: {
          borderRadius: 10,
          margin: '2px 8px',
          '&.RaMenuItemLink-active': {
            color: BRAND,
            fontWeight: 700,
            backgroundColor: dark ? 'rgba(255,109,0,.14)' : 'rgba(255,109,0,.10)',
            borderLeft: `3px solid ${BRAND}`,
          },
          '&.RaMenuItemLink-active .MuiSvgIcon-root': { color: BRAND },
        },
      },
    },
    RaDatagrid: {
      styleOverrides: {
        root: {
          '& .RaDatagrid-headerCell': {
            backgroundColor: dark ? '#1b1f2a' : '#f6f7f9',
            fontWeight: 700,
          },
          '& .RaDatagrid-row:hover': {
            backgroundColor: dark ? 'rgba(255,109,0,.08)' : 'rgba(255,109,0,.05)',
          },
        },
      },
    },
    MuiChip: { styleOverrides: { root: { borderRadius: 8, fontWeight: 600 } } },
    MuiTextField: { defaultProps: { variant: 'outlined' } },
    RaLayout: { styleOverrides: { root: { '& .RaLayout-content': { paddingTop: 8 } } } },
    MuiTableCell: { styleOverrides: { root: { borderColor: border } } },
  }
}

export const lightTheme = {
  ...shared,
  palette: {
    mode: 'light',
    primary: { main: BRAND, dark: BRAND_DARK, contrastText: '#fff' },
    secondary: { main: '#2b2f3a' },
    background: { default: '#f4f5f8', paper: '#ffffff' },
    text: { primary: '#1a1d26', secondary: '#5a6272' },
  },
  components: components(false),
}

export const darkTheme = {
  ...shared,
  palette: {
    mode: 'dark',
    primary: { main: BRAND, dark: BRAND_DARK, contrastText: '#fff' },
    secondary: { main: '#ff8a2b' },
    background: { default: '#0e1119', paper: '#161923' },
    text: { primary: '#f2f4f8', secondary: '#aeb6c6' },
  },
  components: components(true),
}

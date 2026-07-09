import { Admin, Resource } from 'react-admin'
import CategoryIcon from '@mui/icons-material/Category'
import MovieIcon from '@mui/icons-material/Movie'
import { dataProvider } from './dataProvider.js'
import { authProvider } from './authProvider.js'
import { lightTheme, darkTheme } from './theme.js'
import Login from './Login.jsx'
import { CategoryList, CategoryEdit, CategoryCreate } from './resources/categories.jsx'
import { VideoList, VideoEdit } from './resources/videos.jsx'

export default function App() {
  return (
    <Admin
      dataProvider={dataProvider}
      authProvider={authProvider}
      loginPage={Login}
      theme={lightTheme}
      darkTheme={darkTheme}
      defaultTheme="light"
      title="Yini 后台管理"
      disableTelemetry
    >
      <Resource
        name="categories"
        icon={CategoryIcon}
        options={{ label: '分类管理' }}
        list={CategoryList}
        edit={CategoryEdit}
        create={CategoryCreate}
      />
      <Resource
        name="videos"
        icon={MovieIcon}
        options={{ label: '资源库' }}
        list={VideoList}
        edit={VideoEdit}
      />
    </Admin>
  )
}

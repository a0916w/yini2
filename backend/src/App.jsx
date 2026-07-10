import { Admin, Resource } from 'react-admin'
import CategoryIcon from '@mui/icons-material/Category'
import MovieIcon from '@mui/icons-material/Movie'
import CardMembershipIcon from '@mui/icons-material/CardMembership'
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong'
import PeopleIcon from '@mui/icons-material/People'
import CampaignIcon from '@mui/icons-material/Campaign'
import ViewCarouselIcon from '@mui/icons-material/ViewCarousel'
import RedeemIcon from '@mui/icons-material/Redeem'
import CelebrationIcon from '@mui/icons-material/Celebration'
import { dataProvider } from './dataProvider.js'
import { authProvider } from './authProvider.js'
import { lightTheme, darkTheme } from './theme.js'
import Login from './Login.jsx'
import { CategoryList, CategoryEdit, CategoryCreate } from './resources/categories.jsx'
import { VideoList, VideoEdit } from './resources/videos.jsx'
import {
  PlanList, PlanEdit, PlanCreate,
  OrderList,
  UserList, UserEdit,
  MarqueeList, MarqueeEdit, MarqueeCreate,
  BannerList, BannerEdit,
  RedeemList, RedeemEdit, RedeemCreate,
  EventList, EventEdit,
} from './resources/more.jsx'

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
      <Resource name="videos" icon={MovieIcon} options={{ label: '资源库' }} list={VideoList} edit={VideoEdit} />
      <Resource name="categories" icon={CategoryIcon} options={{ label: '分类管理' }} list={CategoryList} edit={CategoryEdit} create={CategoryCreate} />
      <Resource name="vip-plans" icon={CardMembershipIcon} options={{ label: '会员套餐' }} list={PlanList} edit={PlanEdit} create={PlanCreate} />
      <Resource name="orders" icon={ReceiptLongIcon} options={{ label: '订单' }} list={OrderList} />
      <Resource name="users" icon={PeopleIcon} options={{ label: '用户' }} list={UserList} edit={UserEdit} />
      <Resource name="marquees" icon={CampaignIcon} options={{ label: '公告' }} list={MarqueeList} edit={MarqueeEdit} create={MarqueeCreate} />
      <Resource name="banners" icon={ViewCarouselIcon} options={{ label: 'Banner' }} list={BannerList} edit={BannerEdit} />
      <Resource name="redeem-codes" icon={RedeemIcon} options={{ label: '兑换码' }} list={RedeemList} edit={RedeemEdit} create={RedeemCreate} />
      <Resource name="events" icon={CelebrationIcon} options={{ label: '活动' }} list={EventList} edit={EventEdit} />
    </Admin>
  )
}

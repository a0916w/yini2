import { Routes, Route, Navigate } from 'react-router-dom'
import { StoreProvider } from './store.jsx'

import Home from './pages/Home.jsx'
import Search from './pages/Search.jsx'
import DramaDetail from './pages/DramaDetail.jsx'
import Player from './pages/Player.jsx'
import Topics from './pages/Topics.jsx'
import TopicDetail from './pages/TopicDetail.jsx'
import Trends from './pages/Trends.jsx'
import Wishes from './pages/Wishes.jsx'
import Nominate from './pages/Nominate.jsx'
import Vip from './pages/Vip.jsx'
import Shop from './pages/Shop.jsx'
import Tasks from './pages/Tasks.jsx'
import Me from './pages/Me.jsx'
import Account from './pages/Account.jsx'
import Orders from './pages/Orders.jsx'
import Favorites from './pages/Favorites.jsx'
import History from './pages/History.jsx'
import Downloads from './pages/Downloads.jsx'
import Messages from './pages/Messages.jsx'
import MessageDetail from './pages/MessageDetail.jsx'
import Notices from './pages/Notices.jsx'
import Feedback from './pages/Feedback.jsx'
import CustomerService from './pages/CustomerService.jsx'
import Surveys from './pages/Surveys.jsx'
import SurveyDetail from './pages/SurveyDetail.jsx'
import Login from './pages/Login.jsx'
import Redeem from './pages/Redeem.jsx'
import Language from './pages/Language.jsx'
import NotFound from './pages/NotFound.jsx'

export default function App() {
  return (
    <StoreProvider>
      <div className="app">
        <Routes>
          <Route path="/" element={<Navigate to="/home" replace />} />
          <Route path="/home" element={<Home />} />
          <Route path="/search" element={<Search />} />
          <Route path="/dramas/:id" element={<DramaDetail />} />
          <Route path="/watch/:id" element={<Player />} />
          <Route path="/topics" element={<Topics />} />
          <Route path="/topics/:id" element={<TopicDetail />} />
          <Route path="/trends" element={<Trends />} />
          <Route path="/wishes" element={<Wishes />} />
          <Route path="/wishes/nominate" element={<Nominate />} />
          <Route path="/vip" element={<Vip />} />
          <Route path="/shop" element={<Shop />} />
          <Route path="/tasks" element={<Tasks />} />
          <Route path="/me" element={<Me />} />
          <Route path="/account" element={<Account />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/favorites" element={<Favorites />} />
          <Route path="/history" element={<History />} />
          <Route path="/downloads" element={<Downloads />} />
          <Route path="/messages" element={<Messages />} />
          <Route path="/messages/:id" element={<MessageDetail />} />
          <Route path="/notices" element={<Notices />} />
          <Route path="/feedback" element={<Feedback />} />
          <Route path="/customer-service" element={<CustomerService />} />
          <Route path="/surveys" element={<Surveys />} />
          <Route path="/surveys/:id" element={<SurveyDetail />} />
          <Route path="/login" element={<Login />} />
          <Route path="/redeem" element={<Redeem />} />
          <Route path="/language" element={<Language />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </div>
    </StoreProvider>
  )
}

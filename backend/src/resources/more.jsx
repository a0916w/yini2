import {
  List, Datagrid, TextField, NumberField, BooleanField, DateField, EmailField, FunctionField,
  EditButton, Edit, Create, SimpleForm, TextInput, NumberInput, BooleanInput, SelectInput,
  DateTimeInput, SearchInput,
} from 'react-admin'

/* ---------- 会员套餐 vip-plans ---------- */
export const PlanList = () => (
  <List sort={{ field: 'sort', order: 'ASC' }} perPage={50} title="会员套餐">
    <Datagrid rowClick="edit" bulkActionButtons={false}>
      <TextField source="id" label="ID" />
      <TextField source="key" label="标识" />
      <NumberField source="days" label="天数" />
      <NumberField source="price" label="价格" />
      <NumberField source="original_price" label="原价" />
      <NumberField source="sort" label="排序" />
      <FunctionField label="状态" render={(r) => (r.status ? '启用' : '停用')} />
      <EditButton />
    </Datagrid>
  </List>
)
export const PlanEdit = () => (
  <Edit title="编辑套餐"><SimpleForm>
    <TextInput source="key" label="标识 key" fullWidth />
    <NumberInput source="days" label="天数" />
    <NumberInput source="price" label="价格(元)" />
    <NumberInput source="original_price" label="原价(元)" />
    <NumberInput source="sort" label="排序" />
    <BooleanInput source="status" label="启用" parse={(v) => (v ? 1 : 0)} format={(v) => !!v} />
  </SimpleForm></Edit>
)
export const PlanCreate = () => (
  <Create title="新建套餐"><SimpleForm>
    <TextInput source="key" label="标识 key" fullWidth />
    <NumberInput source="days" label="天数" defaultValue={30} />
    <NumberInput source="price" label="价格(元)" />
    <NumberInput source="original_price" label="原价(元)" />
    <NumberInput source="sort" label="排序" defaultValue={0} />
    <BooleanInput source="status" label="启用" defaultValue />
  </SimpleForm></Create>
)

/* ---------- 订单 orders (只读) ---------- */
const ORDER_STATUS = { 0: '待支付', 1: '已支付', 2: '已取消', 3: '退款中', 4: '已退款' }
export const OrderList = () => (
  <List sort={{ field: 'id', order: 'DESC' }} perPage={25} title="订单">
    <Datagrid bulkActionButtons={false}>
      <TextField source="order_no" label="订单号" />
      <TextField source="plan_name" label="套餐" />
      <NumberField source="days" label="天数" />
      <FunctionField label="金额" render={(r) => `¥${r.amount}`} />
      <FunctionField label="状态" render={(r) => ORDER_STATUS[r.status] ?? r.status} />
      <TextField source="payment_method" label="支付方式" emptyText="—" />
      <DateField source="paid_at" label="支付时间" showTime emptyText="—" />
      <DateField source="created_at" label="下单时间" showTime />
    </Datagrid>
  </List>
)

/* ---------- 用户 users ---------- */
export const UserList = () => (
  <List filters={[<SearchInput key="q" source="q" alwaysOn placeholder="搜索昵称/邮箱" />]} sort={{ field: 'id', order: 'DESC' }} perPage={25} title="用户">
    <Datagrid rowClick="edit" bulkActionButtons={false}>
      <NumberField source="id" label="ID" />
      <TextField source="nickname" label="昵称" />
      <EmailField source="email" label="邮箱" emptyText="—" />
      <TextField source="phone" label="手机" emptyText="—" />
      <NumberField source="vip_level" label="VIP等级" />
      <DateField source="vip_expired_at" label="VIP到期" emptyText="—" />
      <TextField source="role" label="角色" emptyText="user" />
      <EditButton />
    </Datagrid>
  </List>
)
export const UserEdit = () => (
  <Edit title="编辑用户"><SimpleForm>
    <TextInput source="nickname" label="昵称" />
    <TextInput source="email" label="邮箱" />
    <TextInput source="phone" label="手机" />
    <NumberInput source="vip_level" label="VIP等级" />
    <DateTimeInput source="vip_expired_at" label="VIP到期时间" />
    <SelectInput source="role" label="角色" choices={[
      { id: 'user', name: '普通用户' }, { id: 'admin', name: '管理员' }, { id: 'superadmin', name: '超管' },
    ]} />
  </SimpleForm></Edit>
)

/* ---------- 跑马灯/公告 marquees ---------- */
export const MarqueeList = () => (
  <List sort={{ field: 'sort_order', order: 'ASC' }} perPage={50} title="公告">
    <Datagrid rowClick="edit" bulkActionButtons={false}>
      <NumberField source="id" label="ID" />
      <TextField source="content" label="内容" />
      <NumberField source="sort_order" label="排序" />
      <BooleanField source="is_active" label="启用" />
      <EditButton />
    </Datagrid>
  </List>
)
export const MarqueeEdit = () => (
  <Edit title="编辑公告"><SimpleForm>
    <TextInput source="content" label="内容" fullWidth multiline />
    <NumberInput source="sort_order" label="排序" />
    <BooleanInput source="is_active" label="启用" />
  </SimpleForm></Edit>
)
export const MarqueeCreate = () => (
  <Create title="新建公告"><SimpleForm>
    <TextInput source="content" label="内容" fullWidth multiline />
    <NumberInput source="sort_order" label="排序" defaultValue={0} />
    <BooleanInput source="is_active" label="启用" defaultValue />
  </SimpleForm></Create>
)

/* ---------- Banner ---------- */
export const BannerList = () => (
  <List sort={{ field: 'sort_order', order: 'ASC' }} perPage={50} title="Banner">
    <Datagrid rowClick="edit" bulkActionButtons={false}>
      <NumberField source="id" label="ID" />
      <FunctionField label="图" render={(r) => (r.desktop || r.mobile) ? <img src={r.desktop || r.mobile} alt="" style={{ height: 40, borderRadius: 4 }} /> : '—'} />
      <TextField source="link" label="跳转" emptyText="—" />
      <NumberField source="sort_order" label="排序" />
      <BooleanField source="enabled" label="启用" />
      <EditButton />
    </Datagrid>
  </List>
)
export const BannerEdit = () => (
  <Edit title="编辑 Banner"><SimpleForm>
    <TextInput source="link" label="跳转链接" fullWidth />
    <NumberInput source="sort_order" label="排序" />
    <BooleanInput source="enabled" label="启用" />
  </SimpleForm></Edit>
)

/* ---------- 兑换码 redeem-codes ---------- */
export const RedeemList = () => (
  <List sort={{ field: 'id', order: 'DESC' }} perPage={25} title="兑换码">
    <Datagrid rowClick="edit" bulkActionButtons={false}>
      <NumberField source="id" label="ID" />
      <TextField source="code" label="兑换码" />
      <NumberField source="vip_days" label="赠送天数" />
      <FunctionField label="用量" render={(r) => `${r.used_count ?? 0}/${r.max_uses ?? '∞'}`} />
      <BooleanField source="enabled" label="启用" />
      <EditButton />
    </Datagrid>
  </List>
)
export const RedeemEdit = () => (
  <Edit title="编辑兑换码"><SimpleForm>
    <TextInput source="code" label="兑换码" />
    <NumberInput source="vip_days" label="赠送天数" />
    <NumberInput source="max_uses" label="最大可用次数" />
    <BooleanInput source="enabled" label="启用" />
    <TextInput source="description" label="备注" fullWidth />
  </SimpleForm></Edit>
)
export const RedeemCreate = () => (
  <Create title="新建兑换码"><SimpleForm>
    <TextInput source="code" label="兑换码" />
    <NumberInput source="vip_days" label="赠送天数" defaultValue={30} />
    <NumberInput source="max_uses" label="最大可用次数" defaultValue={1} />
    <BooleanInput source="enabled" label="启用" defaultValue />
    <TextInput source="description" label="备注" fullWidth />
  </SimpleForm></Create>
)

/* ---------- 活动 events ---------- */
export const EventList = () => (
  <List sort={{ field: 'id', order: 'DESC' }} perPage={25} title="活动">
    <Datagrid rowClick="edit" bulkActionButtons={false}>
      <NumberField source="id" label="ID" />
      <TextField source="type" label="类型" />
      <DateField source="starts_at" label="开始" showTime />
      <DateField source="ends_at" label="结束" showTime />
      <BooleanField source="enabled" label="启用" />
      <EditButton />
    </Datagrid>
  </List>
)
export const EventEdit = () => (
  <Edit title="编辑活动"><SimpleForm>
    <SelectInput source="type" label="类型" choices={[
      { id: 'half_price', name: '半价' }, { id: 'buy_one_free_one', name: '买一送一' }, { id: 'jump_only', name: '仅跳转' },
    ]} />
    <TextInput source="jump_url" label="跳转链接" fullWidth />
    <DateTimeInput source="starts_at" label="开始时间" />
    <DateTimeInput source="ends_at" label="结束时间" />
    <TextInput source="description" label="描述" fullWidth multiline />
    <BooleanInput source="enabled" label="启用" />
  </SimpleForm></Edit>
)

import {
  List, Datagrid, TextField, NumberField, BooleanField, EditButton, FunctionField,
  Edit, SimpleForm, TextInput, NumberInput, BooleanInput,
  SearchInput, SelectInput, ReferenceInput, ReferenceField,
} from 'react-admin'

const Cover = () => (
  <FunctionField
    label="封面"
    render={(r) =>
      r.cover_url
        ? <img src={r.cover_url} alt="" style={{ width: 92, height: 56, objectFit: 'cover', borderRadius: 6 }} />
        : <span style={{ color: '#999' }}>—</span>
    }
  />
)

const filters = [
  <SearchInput key="q" source="q" alwaysOn placeholder="搜索标题" />,
  <SelectInput key="vip" source="is_vip" label="类型" choices={[
    { id: 1, name: 'VIP' }, { id: 0, name: '免费' },
  ]} />,
  <SelectInput key="en" source="enabled" label="状态" choices={[
    { id: 1, name: '上架' }, { id: 0, name: '下架' },
  ]} />,
  <ReferenceInput key="cat" source="category_id" reference="categories">
    <SelectInput label="分类" optionText="name" />
  </ReferenceInput>,
]

export const VideoList = () => (
  <List filters={filters} sort={{ field: 'id', order: 'DESC' }} perPage={20} title="资源库">
    <Datagrid rowClick="edit" bulkActionButtons={false}>
      <NumberField source="id" label="ID" />
      <Cover />
      <TextField source="title" label="标题" />
      <ReferenceField source="category_id" reference="categories" label="分类" link={false}>
        <TextField source="name" />
      </ReferenceField>
      <BooleanField source="is_vip" label="VIP" />
      <BooleanField source="enabled" label="上架" />
      <NumberField source="view_count" label="播放" />
      <TextField source="transcode_status" label="转码" emptyText="mp4" />
      <EditButton />
    </Datagrid>
  </List>
)

export const VideoEdit = () => (
  <Edit title="编辑资源">
    <SimpleForm>
      <TextInput source="title" label="标题" fullWidth />
      <TextInput source="description" label="简介" fullWidth multiline />
      <ReferenceInput source="category_id" reference="categories">
        <SelectInput label="分类" optionText="name" />
      </ReferenceInput>
      <NumberInput source="sort_order" label="排序" />
      <BooleanInput source="is_vip" label="VIP 专享" />
      <BooleanInput source="enabled" label="上架" />
    </SimpleForm>
  </Edit>
)

import {
  List, Datagrid, TextField, NumberField, BooleanField, EditButton,
  Edit, SimpleForm, TextInput, NumberInput, BooleanInput, Create,
  SearchInput,
} from 'react-admin'

const filters = [<SearchInput key="q" source="q" alwaysOn placeholder="搜索名称 / slug" />]

export const CategoryList = () => (
  <List filters={filters} sort={{ field: 'sort_order', order: 'ASC' }} perPage={50} title="分类管理">
    <Datagrid rowClick="edit" bulkActionButtons={false}>
      <NumberField source="id" label="ID" />
      <TextField source="name" label="名称" />
      <TextField source="slug" label="Slug" />
      <NumberField source="videos_count" label="视频数" />
      <NumberField source="sort_order" label="排序" />
      <BooleanField source="enabled" label="启用" />
      <BooleanField source="video_selectable" label="可选片" />
      <EditButton />
    </Datagrid>
  </List>
)

export const CategoryEdit = () => (
  <Edit title="编辑分类">
    <SimpleForm>
      <TextInput source="name" label="名称" fullWidth />
      <TextInput source="slug" label="Slug" fullWidth />
      <NumberInput source="sort_order" label="排序" />
      <BooleanInput source="enabled" label="启用" />
      <BooleanInput source="video_selectable" label="可作为选片分类" />
    </SimpleForm>
  </Edit>
)

export const CategoryCreate = () => (
  <Create title="新建分类">
    <SimpleForm>
      <TextInput source="name" label="名称" fullWidth />
      <TextInput source="slug" label="Slug" fullWidth />
      <NumberInput source="sort_order" label="排序" defaultValue={0} />
      <BooleanInput source="enabled" label="启用" defaultValue={true} />
    </SimpleForm>
  </Create>
)

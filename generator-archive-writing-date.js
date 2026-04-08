// 自定义归档页 generator，按 writing_date 字段全局排序分页
const pagination = require('hexo-pagination');

function getSortVal(item) {
  // writing_date 优先，自动补全仅有日期的情况
  let wd = item.writing_date;
  if (wd && /^\d{4}-\d{2}-\d{2}$/.test(wd)) {
    wd = wd + ' 00:00:00';
  }
  // 若 writing_date 不存在，使用 date 字段
  let dt = item.date;
  if (dt && typeof dt === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(dt)) {
    dt = dt + ' 00:00:00';
  }
  if (wd && dt && wd !== dt) {
    return Math.max(new Date(wd), new Date(dt));
  }
  return new Date(wd || dt);
}

hexo.extend.generator.register('archive', function(locals) {
  // 获取所有文章，按 writing_date 全局降序排序
  const posts = locals.posts.sort((a, b) => getSortVal(b) - getSortVal(a));
  const config = this.config;
  const perPage = config.archive_generator && config.archive_generator.per_page || config.per_page;
  const paginationDir = config.pagination_dir || 'page';

  // 生成归档主页面（分页）
  const archivePages = pagination('/archives/', posts, {
    perPage: perPage,
    layout: ['archive', 'index'],
    format: paginationDir + '/%d/',
    data: { archive: true }
  });

  // 生成按年份归档页面
  const years = {};
  posts.forEach(post => {
    const year = getSortVal(post) instanceof Date ? getSortVal(post).getFullYear() : new Date(getSortVal(post)).getFullYear();
    if (!years[year]) years[year] = [];
    years[year].push(post);
  });
  const yearPages = Object.keys(years).map(year =>
    pagination(`/archives/${year}/`, years[year].sort((a, b) => getSortVal(b) - getSortVal(a)), {
      perPage: perPage,
      layout: ['archive', 'index'],
      format: paginationDir + '/%d/',
      data: { archive: true, year: +year }
    })
  ).flat();

  // 生成按年月归档页面
  const months = {};
  posts.forEach(post => {
    const date = getSortVal(post) instanceof Date ? getSortVal(post) : new Date(getSortVal(post));
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const key = `${year}/${month < 10 ? '0' + month : month}`;
    if (!months[key]) months[key] = [];
    months[key].push(post);
  });
  const monthPages = Object.keys(months).map(key =>
    pagination(`/archives/${key}/`, months[key].sort((a, b) => getSortVal(b) - getSortVal(a)), {
      perPage: perPage,
      layout: ['archive', 'index'],
      format: paginationDir + '/%d/',
      data: { archive: true, year: +key.split('/')[0], month: +key.split('/')[1] }
    })
  ).flat();

  return [...archivePages, ...yearPages, ...monthPages];
});

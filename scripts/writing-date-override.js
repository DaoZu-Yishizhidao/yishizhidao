const moment = require('moment');


// 这个脚本的作用是允许在文章的 Front Matter 中使用 `writing_date` 字段来覆盖默认的 `date` 字段，
// 从而实现自定义的写作日期显示。它会在 Hexo 渲染文章之前检查 `writing_date` 是否存在，
// 并且如果存在且有效，就将其设置为新的 `date`，同时保留原来的 `date` 作为 `writing_date`。
// 交换两个字段的值，以便在模板中可以使用 `writing_date` 来显示原始的写作日期，而 `date` 则用于文章的发布时间。
hexo.extend.filter.register('before_post_render', function(data) {
  if (data.writing_date) {
    const newDate = moment(data.writing_date);
    const oldDate = moment(data.date);
    if (newDate.isValid() && oldDate.isValid()) {
      data.writing_date=oldDate.toISOString();
      data.date = newDate;
      //data.updated = newDate;
    }
  }
  return data;
});

/*
hexo.extend.filter.register('after_generate', function() {
  const posts = this.locals.get('posts');
  posts.forEach(post => {
    if (post.writing_date) {
      const newDate = moment(post.writing_date);
      const oldDate = moment(post.date);
      if (newDate.isValid() && oldDate.isValid()) {
        //post.writing_date = oldDate.toISOString();
        //post.date = newDate;
        //post.updated = newDate;
      }
    }
  });
});
*/
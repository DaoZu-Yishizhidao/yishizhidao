const moment = require('moment');

hexo.extend.filter.register('before_post_render', function(data) {
  if (data.writing_date) {
    const newDate = moment(data.writing_date);
    if (newDate.isValid()) {
      // 赋值为 moment 对象，而不是 Date 对象
      data.date = newDate;
      //data.updated = newDate;
    }
  }
  return data;
});

hexo.extend.filter.register('after_generate', function() {
  const posts = this.locals.get('posts');
  posts.forEach(post => {
    if (post.writing_date) {
      const newDate = moment(post.writing_date);
      if (newDate.isValid()) {
        post.date = newDate;
        //post.updated = newDate;
      }
    }
  });
});
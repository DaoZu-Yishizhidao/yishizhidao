'use strict';

const pagination = require('hexo-pagination');
const moment = require('moment'); // Hexo 自带

hexo.extend.generator.register('multi_archive', function (locals) {
  const config = hexo.config.multi_archive || {};
  const perPage = config.per_page || 10;
  const createYearly = config.yearly !== false;
  const createMonthly = config.monthly !== false;

  // 归档类型配置，可完全自定义,date与writing_date已交换值，date表示写作日期，writing_date表示发布日期
  const archiveTypes = config.types || [
    { field: 'date', path: 'archives/', label: 'by-written' },
    { field: 'writing_date', path: 'archives/date/', label: 'by-date' },
    { field: 'updated', path: 'archives/updated/', label: 'by-updated' }
  ];
  const allPostsArray = locals.posts.toArray();
  const result = [];

  /**
   * 获取文章的日期 Moment 对象
   * @param {object} post 
   * @param {string} field - 日期字段名，date 直接用 post.date，其他用 front-matter 值
   */
  function getPostDate(post, field) {
    if (field === 'date') return post.date;               // 已是 Moment 对象
    const val = post[field];
    return val ? moment(val) : null;
  }

  archiveTypes.forEach(type => {
    // 1. 筛选有对应日期字段的文章
    let posts = allPostsArray.filter(post => {
      if (type.field === 'date') return true;
      return post[type.field] != null;
    });

    // 2. 按日期降序排序（最新在前）
    posts = [...posts].sort((a, b) => {
      const da = getPostDate(a, type.field);
      const db = getPostDate(b, type.field);
      return (db && db.valueOf() || 0) - (da && da.valueOf() || 0);
    });

    if (posts.length === 0) return;

    // 确保路径以 '/' 结尾
    let basePath = type.path;
    if (basePath[basePath.length - 1] !== '/') basePath += '/';

    // 公用 data 基础信息
    const commonData = {
      archiveType: type.label,
      dateField: type.field
    };

    // 3. 生成总归档页（不分年/月，所有文章）
    result.push(...pagination(basePath, posts, {
      perPage: perPage,
      layout: ['archive', 'index'],
      format: 'page/%d/',
      data: Object.assign({}, commonData)
    }));

    // 如果不需要年度/月度，直接跳过
    if (!createYearly) return;

    // 4. 按年/月组织文章
    const byYear = {};  // { year: { _posts: [], months: { month: [] } } }

    posts.forEach(post => {
      const date = getPostDate(post, type.field);
      if (!date) return;

      const year = date.year();
      const month = date.month() + 1; // moment month 范围 0-11

      if (!byYear[year]) {
        byYear[year] = { _posts: [], months: {} };
      }
      byYear[year]._posts.push(post);

      if (!byYear[year].months[month]) {
        byYear[year].months[month] = [];
      }
      byYear[year].months[month].push(post);
    });

    const years = Object.keys(byYear).sort((a, b) => b - a); // 降序年份

    years.forEach(yearStr => {
      const year = parseInt(yearStr, 10);
      const yearData = byYear[year];
      const yearUrl = basePath + year + '/';

      // 年度归档页（该年所有文章，带分页）
      if (yearData._posts.length > 0) {
        result.push(...pagination(yearUrl, yearData._posts, {
          perPage: perPage,
          layout: ['archive', 'index'],
          format: 'page/%d/',
          data: Object.assign({}, commonData, { year })
        }));
      }

      // 月度归档（如果启用）
      if (createMonthly) {
        for (let month = 1; month <= 12; month++) {
          const monthPosts = yearData.months[month];
          if (!monthPosts || monthPosts.length === 0) continue;

          const monthStr = month.toString().padStart(2, '0');
          const monthUrl = yearUrl + monthStr + '/';

          result.push(...pagination(monthUrl, monthPosts, {
            perPage: perPage,
            layout: ['archive', 'index'],
            format: 'page/%d/',
            data: Object.assign({}, commonData, { year, month })
          }));
        }
      }
    });
  });

  return result;
});
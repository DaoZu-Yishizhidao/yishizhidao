---
title: 网站构建
date: 2026-01-28 23:51:28
writing_date: 2026-01-31 23:07:13
permalink: /categories/practice/technology/website-build/index/
tags: [网站构建]
sticky: 1000
categories: [实践方向,技术之道,网站构建]
---
#  一、Hexo 博客自动化部署
## 本地环境构建
### 前期准备
此详细准备步骤要旨在于能够在本地运行Hexo，且其主题是Butterfly。另外对Git进行简单设置与验证<a href="/categories/practice/technology/website-build/CICD/localSet/"  class="btn" style="padding: 0.6em 1.2em; background: #3498db; color: white; border-radius: 4px; text-decoration: none;">详细步骤</a>

## 服务器构建
## Git配置
## 构建日志
### 2026年2月1日16时09分：网站框架基本构建完毕
1、导航菜单完整
2、基础分类完整
3、文章链接修复
### 2026年2月4日00时21分：新文章自动化分类至指定分类目录
1、使用powershell脚本创建自动化文章分类至分类目录
2、<a href="/categories/practice/technology/website-build/1770135975382/">分类映射管理模块</a>
3、<a href="/categories/practice/technology/website-build/1770136163251/">路径转换模块</a>
4、<a href="/categories/practice/technology/website-build/1770136122794/">文件夹扫描模块</a>
5、<a href="/categories/practice/technology/website-build/1770136210495/">智能文章创建脚本</a>
6、使用<a href="/categories/practice/technology/website-build/1770136210495/">智能文章创建脚本</a>本道祖为各分类创建了主体文章

### 2026年2月5日01时03分：修改智能文章创建脚本，增加文章是否在主页显示
1、<a href="/categories/practice/technology/website-build/1770136210495/">智能文章创建脚本</a>

2、增加文章是否在主页显示

```pug

mixin indexPostUI()
  - const indexLayout = theme.index_layout
  - const masonryLayoutClass = (indexLayout === 6 || indexLayout === 7) ? 'masonry' : ''
  //自定义内容，文章是否在主页显示
  - const allVisiblePosts = site.posts.toArray().filter(post => !post.hide)
  - page.total = Math.ceil(allVisiblePosts.length/10)
  //p 总文章数: #{allVisiblePosts.length}
  //p page.total: #{page.total}
  //变量更换：page.posts.data更换allVisiblePosts
  //自定义内容结束
  #recent-posts.recent-posts.nc(class=masonryLayoutClass)
    .recent-post-items
      each article, index in allVisiblePosts

```
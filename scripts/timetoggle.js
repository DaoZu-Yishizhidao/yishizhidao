
/* ============================================
### 《意识之道》
### 文件名：timetoggle.js
### 编程语言：JavaScript
### 功能：带折叠功能的时间轴
### 作者：道祖
### 版本：v1 
### 日期：2026-02-08 02：46
### 更新日期：2026-02-08 02：46

###########使用示例###########

{% timetoggle 2026年 %}
<!-- timetoggle 标题1 -->
内容
<!-- endtimetoggle -->

<!-- timetoggle 标题2 -->
内容
<!-- endtimetoggle -->
{% endtimetoggle %}

###########示例结束###########

# ============================================
*/

'use strict'

const timetoggle = (args, content) => {
  const tlBlock = /<!--\s*timetoggle\s*(?<title>.*?)\s*-->\n(?<content>[\s\S]*?)<!--\s*endtimetoggle\s*-->/g
  
  // 获取 strip_html 辅助函数
  const strip_html = hexo.extend.helper.get('strip_html').bind(hexo)
  
  const renderMd = text => hexo.render.renderSync({ text, engine: 'markdown' })
  
  const [text, bg = false, color = ''] = args.length ? args.join(' ').split(',') : []

  const generateStyle = (bg, color) => {
    let style = 'style="'
    if (bg) style += `background-color: ${bg};`
    if (color) style += `color: ${color}`
    style += '"'
    return style
  }

  const style = generateStyle(bg, color)
  const border = bg ? `style="border: 1px solid ${bg}"` : ''

  const headline = text
    ? `<div class='timeline-item headline'>
        <div class='timeline-item-title'>
          <div class='item-circle'>${renderMd(text)}</div>
        </div>
      </div>`
    : ''

  const items = Array.from(content.matchAll(tlBlock))
    .map(({ groups: { title, content } }) => {
      // 渲染标题，然后去除 HTML 标签
      const renderedTitle = renderMd(title)
      // 使用 strip_html 去除 <p> 标签
      const cleanTitle = strip_html(renderedTitle).trim()
      
      return `<div class='timeline-item'><div class='timeline-item-title'>
        <div class='item-circle'>
         <details class="toggle" ${border} >
        <summary class="toggle-button" ${style} >${cleanTitle}</summary>
        <div class="toggle-content">${renderMd(content)}</div> 
       </details></div></div></div>`
    })
    .join('')

  return `<div class="timeline ${color}">${headline}${items}</div>`
}

hexo.extend.tag.register('timetoggle', timetoggle, { ends: true })
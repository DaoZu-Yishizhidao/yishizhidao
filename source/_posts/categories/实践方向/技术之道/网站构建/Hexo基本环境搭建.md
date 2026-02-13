---
title: 第一阶段：基础环境搭建
date: 2026-01-15 23:58
tags: [Hexo]
categories: [实践方向,技术之道,网站构建]
hide: ture
---





### 📦 第一阶段：基础环境搭建

**目标**：创建一个纯净的 Hexo 项目骨架，并安装核心依赖。

1.  **确保目录为空**
    检查 `G:\yishizhidaoWeb` 目录下，只保留你确定需要保留的个人文件（如文章、自定义脚本等）。删除旧的 `node_modules`、`public`、`db.json`、`_config.butterfly.yml` 等由 Hexo 生成的文件和目录。

2.  **初始化 Hexo 项目**
    在 `G:\yishizhidaoWeb` 目录中打开 PowerShell，执行：
    ```powershell
    # 初始化一个新的 Hexo 项目（注意末尾的点 . 表示当前目录）
    hexo init .

    # 安装基础依赖包
    npm install
    ```

3.  **安装 Butterfly 主题**
    ```powershell
    # 通过 NPM 安装主题（推荐方式）
    npm install hexo-theme-butterfly --save
    ```
    安装完成后，主题文件位于 `node_modules/hexo-theme-butterfly/`。

### ⚙️ 第二阶段：核心配置（数学公式优先）

**目标**：创建并修改核心配置文件，**确保数学公式配置绝对正确**。

1.  **修改 Hexo 主配置**
    打开 `_config.yml`，找到并修改这一行：
    ```yaml
    # 大约在第90行左右
    theme: landscape  # 默认是 landscape
    ```
    将其改为：
    ```yaml
    theme: butterfly  # 指定使用 butterfly 主题
    ```

2.  **创建并配置 Butterfly 主题配置文件**
    这是最关键的一步。在博客根目录创建一个**新的** `_config.butterfly.yml` 文件，并**直接粘贴**以下完整内容：
    ```yaml
    # _config.butterfly.yml - 精简稳定版
    # ==================== 站点信息 ====================
    site:
      title: 《意识之道》思想实验场
      subtitle: 探索意识、哲学与科技的边界
      description: 一个关于意识探索、哲学思考和科技伦理的实验性博客
      keywords: 意识,哲学,科技,人工智能,思想实验
      author: 道祖
      language: zh-CN
      timezone: Asia/Shanghai
      favicon: /favicon.ico  # 稍后请将图标文件放入 source/ 目录

    # ==================== 主题外观 ====================
    theme_color:
      enable: true
      main: '#667eea'

    font:
      font-family: '"Noto Serif SC", -apple-system, sans-serif'
      font-size: 16px

    # ==================== 核心功能配置 ====================
    # 1. 【关键】数学公式支持 (采用最可靠的KaTeX本地化方案)
    katex:
      enable: true
      per_page: true  # 全局启用，无需每篇文章单独设置

    # 2. CDN配置 - 为KaTeX指定CDN，后续可替换为本地文件
    CDN:
      katex_css: https://lf26-cdn-tos.bytecdntp.com/cdn/expire-1-M/KaTeX/0.15.3/katex.min.css
      katex_js: https://lf26-cdn-tos.bytecdntp.com/cdn/expire-1-M/KaTeX/0.15.3/katex.min.js

    # 3. 社交分享 - 直接关闭，避免CDN错误
    social_share:
      enable: false

    # 4. 夜间模式
    darkmode:
      enable: true
      button: true
      autoChangeMode: 1

    # ==================== 页面布局 ====================
    menu:
      主页: / || fas fa-home
      归档: /archives/ || fas fa-archive
      分类: /categories/ || fas fa-folder-open
      标签: /tags/ || fas fa-tags
      关于: /about/ || fas fa-user

    aside:
      enable: true
      card_author:
        enable: true
        description: 《意识之道》创始人 | 思想探索者
      card_recent_post:
        enable: true
        limit: 5
    ```

### 🧪 第三阶段：安装与验证数学公式

**目标**：安装数学公式所需的渲染器和资源，并进行第一次验证。

1.  **更换 Markdown 渲染器**
    ```powershell
    # 卸载默认的渲染器（可能会报错，如果没安装过则忽略）
    npm uninstall hexo-renderer-marked --save
    # 安装与KaTeX兼容性更好的渲染器（hexo-renderer-markdown-it）
    npm install hexo-renderer-markdown-it @renbaoshuo/markdown-it-katex --save
    ```

2.  **配置 markdown-it 渲染器以支持 KaTeX**
    在 Hexo 主配置文件 `_config.yml` 末尾添加：
    ```yaml
    # Markdown-it 配置
    markdown:
      render:
        html: true
        xhtmlOut: false
        breaks: true
        linkify: true
        typographer: true
        quotes: '“”‘’'
      plugins:
        - '@renbaoshuo/markdown-it-katex'
    ```

3.  **创建一篇测试文章**
    ```powershell
    hexo new post “数学公式测试”
    ```
    用编辑器打开 `source/_posts/数学公式测试.md`，在内容中加入公式：
    ```markdown
    ---
    title: 数学公式测试
    date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    ---

    这是一个行内公式 $E = mc^2$。

    这是一个块级公式：
    $$
    \begin{aligned}
    \dot{x} &= \sigma(y - x) \\
    \dot{y} &= \rho x - y - xz
    \end{aligned}
    $$
    ```

4.  **首次生成与验证**
    ```powershell
    hexo clean && hexo g && hexo s
    ```
    在浏览器中打开 `http://localhost:4000`，找到并打开这篇测试文章。
    - **检查点1**：公式是否正常渲染？
    - **检查点2**：按 `F12` 打开浏览器控制台，**是否还有 `ERR_CONNECTION_TIMED_OUT` 等红色网络错误？**（理论上应该没有或极少）。

### 🚀 第四阶段：优化与完善

如果前三阶段成功，你的博客核心已经就绪。接下来进行优化：

1.  **安装本地 Font Awesome (解决图标问题)**
    ```powershell
    npm install @fortawesome/fontawesome-free --save
    ```
    修改 `_config.butterfly.yml` 中的 CDN 配置：
    ```yaml
    CDN:
      # 注释掉或删除原有的katex_css行，因为KaTeX的CSS已通过插件自动注入
      # katex_css: ...
      katex_js: https://lf26-cdn-tos.bytecdntp.com/cdn/expire-1-M/KaTeX/0.15.3/katex.min.js
      # 将fontawesome指向本地NPM包
      fontawesome: //npm/@fortawesome/fontawesome-free/css/all.min.css
    ```

2.  **创建关于页面等**
    ```powershell
    hexo new page "about"
    ```

3.  **部署前检查**
    再次运行 `hexo clean && hexo g && hexo s`，进行全面检查：
    - 浏览各页面，样式是否正常？
    - 浏览器控制台是否干净？
    - 数学公式是否在所有页面都有效？

### 📝 总结与预期成果

通过以上步骤，你将获得一个具备以下特点的新项目：
- **纯净基础**：无历史配置错误。
- **数学公式可用**：采用 **KaTeX** 方案，相比 MathJax 渲染速度更快，且已规避了之前导致失败的 `mathjax` 配置项错误和CDN问题。
- **外部依赖稳定**：Font Awesome 已本地化，社交分享已禁用，最大程度减少外部CDN导致的错误。
- **结构清晰**：配置文件精简，便于后续在此基础上进行个性化定制。

如果在重建过程中的**任何一步**遇到问题，请**立即停止**，并告诉我：
1.  你执行到了第几步的哪个命令？
2.  完整的错误信息是什么？

这将帮助我们快速定位并解决，确保你一次性成功搭建。


已经成功构建
---
title: Git构建
date: 2026-01-16 00:06
tags: [Git]
categories: [实践方向,技术之道,网站构建]
---




### 📋 完整操作步骤总览

| 阶段 | 核心目标 | 关键成果 |
| :--- | :--- | :--- |
| **一、项目初始化** | 创建纯净的 Hexo 项目核心 | 获得一个可本地运行的博客骨架 |
| **二、Git 与环境配置** | 配置高效的本地 Git 环境与 SSH 密钥 | 获得安全的身份标识和稳定的网络连接通道 |
| **三、关联与强制同步仓库** | 将本地项目与远程仓库关联并统一内容 | 本地与远程仓库内容完全一致，建立 SSH 连接 |
| **四、验证与日常使用** | 确认全部配置成功，进入日常创作循环 | 可通过极简命令完成“写作-预览-同步”全流程 |

---

### 🔧 第一阶段：项目初始化（在 `G:\yishizhidaoWeb` 目录）

此阶段目标是创建一个全新的、可本地运行的 Hexo 项目。

1.  **初始化 Hexo**：
    ```powershell
    hexo init .
    npm install
    ```

2.  **安装 Butterfly 主题**：
    ```powershell
    npm install hexo-theme-butterfly --save
    ```

3.  **应用基础配置**：
    *   修改 `_config.yml` 中的 `theme: landscape` 为 `theme: butterfly`。
    *   创建 `_config.butterfly.yml` 文件，并填入主题基本配置（包含数学公式等支持）。

---

### 🔑 第二阶段：Git 与 SSH 环境配置

此阶段配置你的 Git 身份和免密 SSH 登录，这是安全、稳定推送的基础。

1.  **配置全局 Git 身份**：
    ```powershell
    git config --global user.name "DaoZu"
    git config --global user.email "dao@yishizhidao.cn"
    ```

2.  **生成 SSH 密钥对（连接 GitHub 的钥匙）**：
    ```powershell
    ssh-keygen -t ed25519 -C "dao@yishizhidao.cn"
    ```
    *   遇到提示均按回车，使用默认设置即可。

3.  **将 SSH 公钥添加到 GitHub**：
    *   复制公钥内容：`cat ~/.ssh/id_ed25519.pub`
    *   登录 GitHub → Settings → SSH and GPG keys → New SSH Key。
    *   粘贴密钥，添加。

---

### 🔄 第三阶段：关联仓库并强制同步

此阶段解决因历史内容不同导致的冲突，并用本地纯净项目覆盖远程仓库。

1.  **初始化本地 Git 仓库并提交**：
    ```powershell
    git init
    git add .
    git commit -m “初始提交：纯净的 Hexo 博客项目”
    ```

2.  **关联远程仓库**：
    ```powershell
    git remote add origin git@github.com:DaoZu-Yishizhidao/yishizhidao.git
    ```

3.  **强制推送覆盖**（**关键步骤**）：
    ```powershell
    git push origin main --force
    ```
    *   此命令将用你的本地项目 **完全替换** 远程仓库（`yishizhidao`）的所有内容。

---

### ✅ 第四阶段：验证与日常使用

此阶段确认一切就绪，并开始使用极简工作流。

1.  **最终验证**：
    *   **SSH 连接测试**：运行 `ssh -T git@github.com`，看到欢迎词即成功。
    *   **仓库内容验证**：访问 [https://github.com/DaoZu-Yishizhidao/yishizhidao](https://github.com/DaoZu-Yishizhidao/yishizhidao)，确认显示的是你的 Hexo 源码文件。

2.  **安装极简工作脚本**（可选但推荐）：
    *   **上传脚本 `upload.ps1`**：
        ```powershell
        @'
        git add .
        git commit -m “更新：$(Get-Date -Format ‘HH:mm’)”
        git push origin main
        '@ | Out-File “upload.ps1” -Encoding UTF8
        ```
    *   **查看脚本 `view.ps1`**：
        ```powershell
        @‘
        ls | Format-Table Name, @{l=‘类型‘;e={if($_.PSIsContainer){‘📁‘}else{‘📄‘}}}, Length
        ’@ | Out-File “view.ps1” -Encoding UTF8
        ```

3.  **日常创作工作流**：
    1.  **写文章**：`hexo new post "文章标题"`
    2.  **本地预览**：`hexo clean && hexo g && hexo s`
    3.  **同步备份**：`.\upload.ps1` 或直接执行 `git add . && git commit -m "..." && git push`

### ⚠️ 重要提醒
*   **SSH 密钥是唯一凭证**：请保管好 `~/.ssh/` 目录下的私钥文件。在新设备克隆此项目时，务必使用 **SSH 地址** (`git@github.com:...`)。
*   **`.gitignore` 已生效**：系统会自动忽略 `public/`、`node_modules/` 等目录，无需手动提交它们。

至此，你已拥有一个配置稳固、连接顺畅的博客项目，可以完全专注于思想实验与内容创作。如果在新环境中重新部署，可依此步骤复现。
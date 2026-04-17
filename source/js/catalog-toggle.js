/**
 * 《意识之道》目录卡片 - 手风琴折叠逻辑
 * 配合 practice.pug mixin 使用
 * 基于 data-exclusive-toggle 属性实现每张卡片的独立排他展开
 * 移动端默认折叠，桌面端可设置默认展开（按需调整）
 * 2026年04月18日02时45分 by 道祖
 */

(function() {
  // 确保只初始化一次
  if (window.__catalogToggleInitialized) return;
  window.__catalogToggleInitialized = true;

  /**
   * 为单个卡片绑定排他展开逻辑
   * @param {HTMLElement} card - 卡片容器元素
   */
  function bindExclusiveToggle(card) {
    const exclusive = card.getAttribute('data-exclusive-toggle') === 'true';
    if (!exclusive) return;

    const detailsList = card.querySelectorAll('details.toggle');
    if (detailsList.length === 0) return;

    detailsList.forEach(detail => {
      detail.addEventListener('toggle', function() {
        // 仅在展开时触发排他逻辑
        if (!this.open) return;
        detailsList.forEach(other => {
          if (other !== this) other.open = false;
        });
      });
    });
  }

  /**
   * 初始化所有目录卡片
   */
  function initCatalogToggles() {
    const cards = document.querySelectorAll('.catalog-card[data-exclusive-toggle]');
    cards.forEach(card => bindExclusiveToggle(card));
  }

  // 页面加载时初始化
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initCatalogToggles);
  } else {
    initCatalogToggles();
  }

  // 兼容 Pjax 页面切换（Butterfly 主题使用 Pjax 时）
  if (typeof window !== 'undefined' && window.addEventListener) {
    window.addEventListener('pjax:complete', initCatalogToggles);
  }


  // 根据屏幕宽度自动调整 details 的展开状态（移动端默认折叠）
  function adaptDetailsForMobile() {
  const isMobile = window.matchMedia('(max-width: 768px)').matches;
  document.querySelectorAll('.catalog-card details.toggle').forEach(detail => {
    if (isMobile) {
      // 移动端：移除 open 属性（折叠）
      detail.removeAttribute('open');
    } else {
      // 桌面端：若原本无 open，可设置默认打开（按需）
      if (!detail.hasAttribute('open')) {
        detail.setAttribute('open', '');
      }
    }
  });
}

// 初始化时执行
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', adaptDetailsForMobile);
} else {
  adaptDetailsForMobile();
}

// 监听窗口大小变化（可选，若希望旋转设备时也调整）
window.addEventListener('resize', () => {
  requestAnimationFrame(adaptDetailsForMobile);
});

// 兼容 Pjax
window.addEventListener('pjax:complete', adaptDetailsForMobile);


})();
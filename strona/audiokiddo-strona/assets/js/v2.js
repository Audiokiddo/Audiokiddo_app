/* AudioKiddo home, the calm version: gentle reveals, the phone rising with the scroll, the pack
   tabs, the quotes that change by themselves and the Nowości row that can be dragged on a computer.
   Play buttons and videos are handled by strona.js. Nothing moves for visitors who ask for less motion. */
(function () {
  var root = document.querySelector('.v2');
  if (!root) return;
  var still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  document.documentElement.classList.add('v2-js');
  root.classList.add('v2-js');

  // Reveal once, a little before the element is fully in view.
  var items = root.querySelectorAll('[data-v]');
  if (still || !('IntersectionObserver' in window)) {
    items.forEach(function (el) { el.classList.add('is-in'); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add('is-in'); io.unobserve(e.target); }
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.12 });
    items.forEach(function (el) { io.observe(el); });
  }

  // The hero phone rises and grows a little while the first screen scrolls away.
  var stage = root.querySelector('[data-hero-stage]');
  if (stage && !still) {
    var ticking = false;
    var paint = function () {
      ticking = false;
      var r = stage.getBoundingClientRect();
      var p = Math.min(1, Math.max(0, 1 - r.top / window.innerHeight));
      stage.style.setProperty('--hp', p.toFixed(3));
    };
    window.addEventListener('scroll', function () { if (!ticking) { ticking = true; window.requestAnimationFrame(paint); } }, { passive: true });
    paint();
  }

  // Pack tabs: a sliding knob, one panel at a time; a playing sample stops when the tab changes.
  root.querySelectorAll('[data-tabs]').forEach(function (box) {
    var tabs = box.querySelectorAll('[role="tab"]');
    var panels = box.querySelectorAll('[role="tabpanel"]');
    var seg = box.querySelector('.v2-seg');
    function show(i) {
      seg.style.setProperty('--tab', i);
      tabs.forEach(function (t, k) { t.setAttribute('aria-selected', k === i ? 'true' : 'false'); t.tabIndex = k === i ? 0 : -1; });
      panels.forEach(function (p, k) {
        var playing = p.querySelector('.ak-play.is-playing');
        if (playing && k !== i) playing.click();
        p.classList.toggle('is-on', k === i);
      });
    }
    tabs.forEach(function (t, i) {
      t.addEventListener('click', function () { show(i); });
      t.addEventListener('keydown', function (e) {
        var step = e.key === 'ArrowRight' ? 1 : e.key === 'ArrowLeft' ? -1 : 0;
        if (!step) return;
        e.preventDefault();
        var n = (i + step + tabs.length) % tabs.length;
        tabs[n].focus();
        show(n);
      });
    });
  });

  // Quotes: one at a time, every seven seconds, paused while the pointer rests on them.
  root.querySelectorAll('[data-quotes]').forEach(function (box) {
    var quotes = box.querySelectorAll('.v2-quote');
    var dots = box.querySelector('.v2-dots');
    if (quotes.length < 2) return;
    var at = 0;
    var timer = null;
    var buttons = [];
    quotes.forEach(function (_, i) {
      var b = document.createElement('button');
      b.type = 'button';
      b.setAttribute('aria-label', 'Opinia ' + (i + 1));
      b.addEventListener('click', function () { go(i); restart(); });
      dots.appendChild(b);
      buttons.push(b);
    });
    dots.removeAttribute('aria-hidden');
    function go(i) {
      at = i;
      quotes.forEach(function (q, k) { q.classList.toggle('is-on', k === i); });
      buttons.forEach(function (b, k) { b.setAttribute('aria-current', k === i ? 'true' : 'false'); });
    }
    function restart() {
      window.clearInterval(timer);
      if (!still) timer = window.setInterval(function () { go((at + 1) % quotes.length); }, 7000);
    }
    box.addEventListener('mouseenter', function () { window.clearInterval(timer); });
    box.addEventListener('mouseleave', restart);
    go(0);
    restart();
  });

  // Nowości: drag sideways with a mouse (touch scrolls by itself).
  root.querySelectorAll('[data-drag]').forEach(function (row) {
    var down = false, startX = 0, startLeft = 0, moved = false;
    row.addEventListener('pointerdown', function (e) {
      if (e.pointerType !== 'mouse') return;
      down = true; moved = false; startX = e.clientX; startLeft = row.scrollLeft;
    });
    window.addEventListener('pointermove', function (e) {
      if (!down) return;
      var dx = e.clientX - startX;
      if (Math.abs(dx) > 4) { moved = true; row.classList.add('is-dragging'); }
      row.scrollLeft = startLeft - dx;
    });
    window.addEventListener('pointerup', function () {
      if (!down) return;
      down = false;
      row.classList.remove('is-dragging');
    });
    row.addEventListener('click', function (e) { if (moved) { e.preventDefault(); e.stopPropagation(); } }, true);
  });
})();

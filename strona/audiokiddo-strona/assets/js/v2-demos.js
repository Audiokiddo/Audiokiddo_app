/* AudioKiddo home: motion for the two drawn demos (parts/v2-demos.php). Plays when in view,
   pauses when not, shows the last frame still when the visitor asked for less motion. */
(function () {
  'use strict';
  var still = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var wait = function (ms) { return new Promise(function (r) { setTimeout(r, ms); }); };
  var watch = function (el, onIn, onOut, margin) {
    if (!('IntersectionObserver' in window)) { onIn(); return; }
    new IntersectionObserver(function (es) {
      es.forEach(function (e) { e.isIntersecting ? onIn() : onOut && onOut(); });
    }, { threshold: margin || 0.35 }).observe(el);
  };

  /* ---------- W drodze ---------- */
  var trip = document.querySelector('[data-trip]');
  if (trip) {
    var scenes = trip.querySelectorAll('[data-scene]');
    var steps = trip.querySelectorAll('[data-trip-step]');
    var typed = trip.querySelector('.v2d-typed');
    var where = scenes[0], plan = scenes[1], map = scenes[2];
    var car = trip.querySelector('.v2d-car');
    var route = trip.querySelector('.v2d-route');
    var run = 0, visible = false, at = -1;
    var LEN = [5200, 4600, 7400];

    var show = function (n) {
      at = n;
      trip.setAttribute('data-at', String(n));
      scenes.forEach(function (s, i) {
        s.classList.toggle('is-on', i === n);
        s.classList.toggle('is-out', i < n);
        if (i !== n) s.classList.remove('is-results', 'is-picked', 'is-tap', 'is-toast');
      });
      steps.forEach(function (b, i) {
        if (i === n) {
          b.setAttribute('aria-current', 'step');
          b.style.setProperty('--step', LEN[n] + 'ms');
          var bar = b.querySelector('.v2d-step-bar');
          bar.style.animation = 'none'; void bar.offsetWidth; bar.style.animation = '';
        } else b.removeAttribute('aria-current');
      });
    };

    var drive = function (token) {
      if (!car || !route || !route.getTotalLength) return;
      var svg = route.ownerSVGElement, total = route.getTotalLength(), t0 = performance.now(), dur = 6200;
      var stage = car.parentNode;
      var step = function (now) {
        if (token !== run) return;
        var k = Math.min(1, (now - t0) / dur) * 0.62;
        var p = route.getPointAtLength(total * k);
        var m = svg.getScreenCTM(), box = stage.getBoundingClientRect();
        if (m) {
          car.style.left = (m.a * p.x + m.e - box.left) + 'px';
          car.style.top = (m.d * p.y + m.f - box.top) + 'px';
        }
        if (k < 0.62) requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    };

    var type = async function (token) {
      var text = typed.getAttribute('data-type');
      typed.textContent = '';
      for (var i = 1; i <= text.length; i++) {
        if (token !== run) return;
        typed.textContent = text.slice(0, i);
        await wait(70);
      }
    };

    var play = async function (from) {
      var token = ++run;
      trip.classList.remove('is-paused');
      for (var n = from; ; n = (n + 1) % 3) {
        show(n);
        if (n === 0) {
          await wait(500); if (token !== run) return;
          await type(token); if (token !== run) return;
          where.classList.add('is-results');
          await wait(900); if (token !== run) return;
          where.classList.add('is-picked');
          await wait(LEN[0] - 500 - 1000 - 900);
        } else if (n === 1) {
          await wait(LEN[1] - 900); if (token !== run) return;
          plan.classList.add('is-tap');
          await wait(900);
        } else {
          drive(token);
          await wait(2600); if (token !== run) return;
          map.classList.add('is-toast');
          await wait(LEN[2] - 2600);
        }
        if (token !== run) return;
      }
    };

    var finalFrame = function () {
      run++;
      typed.textContent = typed.getAttribute('data-type');
      where.classList.add('is-results', 'is-picked');
      show(0);
    };

    steps.forEach(function (b) {
      b.addEventListener('click', function () {
        var n = +b.getAttribute('data-trip-step');
        if (still) {
          show(n);
          if (n === 0) { typed.textContent = typed.getAttribute('data-type'); where.classList.add('is-results', 'is-picked'); }
          if (n === 2) map.classList.add('is-toast');
          return;
        }
        play(n);
      });
    });

    if (still) finalFrame();
    else {
      typed.textContent = '';
      watch(trip, function () { if (!visible) { visible = true; play(at < 0 ? 0 : at); } },
        function () { if (visible) { visible = false; run++; trip.classList.add('is-paused'); } });
    }
  }

  /* ---------- Szop'en prowadzi ---------- */
  document.querySelectorAll('[data-feat]').forEach(function (card) {
    var mini = card.querySelector('.v2d-mini');
    var day = card.getAttribute('data-feat') === 'day';
    var timer = null, tod = 0;
    if (still) { card.classList.add('is-in'); mini.classList.add('is-play'); if (day) mini.setAttribute('data-tod', '3'); return; }
    if (day) mini.setAttribute('data-tod', '0');
    watch(card, function () {
      card.classList.add('is-in');
      mini.classList.add('is-play');
      if (day && !timer) timer = setInterval(function () { tod = (tod + 1) % 4; mini.setAttribute('data-tod', String(tod)); }, 1900);
    }, function () {
      if (timer) { clearInterval(timer); timer = null; }
      if (!day) mini.classList.remove('is-play'); // replays next time it comes in
    }, 0.5);
  });
})();

/* ---------- 3.35: first screen, how it works, moments, voices, film player, price tip ---------- */
(function () {
  'use strict';
  var still = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var watch = function (el, onIn, onOut, t) {
    if (!('IntersectionObserver' in window)) { onIn(); return; }
    new IntersectionObserver(function (es) { es.forEach(function (e) { e.isIntersecting ? onIn() : onOut && onOut(); }); }, { threshold: t || 0.3 }).observe(el);
  };

  // First screen: the phone shows one screen of the app after another.
  var slides = document.querySelector('[data-slides]');
  if (slides && !still) {
    var imgs = slides.querySelectorAll('img'), cap = document.querySelector('[data-slides-cap]'), at = 0, tm = null;
    var go = function (n) {
      at = n;
      imgs.forEach(function (im, i) { im.classList.toggle('is-on', i === n); });
      if (cap) cap.textContent = imgs[n].getAttribute('data-cap') || '';
    };
    var run = function () { clearInterval(tm); tm = setInterval(function () { go((at + 1) % imgs.length); }, 3400); };
    watch(slides, run, function () { clearInterval(tm); }, 0.2);
  }

  // How it works: the step in the middle of the screen decides which screen the phone shows.
  document.querySelectorAll('[data-how]').forEach(function (box) {
    var steps = box.querySelectorAll('[data-how-step]'), shots = box.querySelectorAll('.v2x-how-phone img'), dots = box.querySelectorAll('.v2x-how-dots i');
    var show = function (n) {
      steps.forEach(function (st, i) { st.classList.toggle('is-on', i === n); });
      shots.forEach(function (im, i) { im.classList.toggle('is-on', i === n); });
      dots.forEach(function (d, i) { d.classList.toggle('is-on', i === n); });
    };
    if (!('IntersectionObserver' in window)) return;
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) show(+e.target.getAttribute('data-how-step')); });
    }, { rootMargin: '-42% 0px -42% 0px' });
    steps.forEach(function (st) { io.observe(st); });
  });

  // Moments of the day: a list, one big card, changes by itself while in view.
  document.querySelectorAll('[data-when]').forEach(function (box) {
    var tabs = box.querySelectorAll('[data-when-tab]'), cards = box.querySelectorAll('.v2x-when-card'), at = 0, tm = null, hover = false;
    var show = function (n, user) {
      at = n;
      tabs.forEach(function (t, i) { t.setAttribute('aria-selected', i === n ? 'true' : 'false'); t.tabIndex = i === n ? 0 : -1; });
      cards.forEach(function (c, i) { c.classList.toggle('is-on', i === n); });
      if (user) restart();
    };
    var restart = function () { clearInterval(tm); if (!still && !hover) tm = setInterval(function () { show((at + 1) % tabs.length); }, 6000); };
    tabs.forEach(function (t, i) {
      t.addEventListener('click', function () { show(i, true); });
      t.addEventListener('keydown', function (e) {
        var d = e.key === 'ArrowDown' || e.key === 'ArrowRight' ? 1 : e.key === 'ArrowUp' || e.key === 'ArrowLeft' ? -1 : 0;
        if (!d) return; e.preventDefault(); var n = (i + d + tabs.length) % tabs.length; tabs[n].focus(); show(n, true);
      });
    });
    box.addEventListener('mouseenter', function () { hover = true; clearInterval(tm); box.classList.add('is-paused'); });
    box.addEventListener('mouseleave', function () { hover = false; box.classList.remove('is-paused'); restart(); });
    watch(box, restart, function () { clearInterval(tm); }, 0.25);
    show(0);
  });

  // Voices: parents / specialists.
  document.querySelectorAll('[data-voices]').forEach(function (box) {
    var tabs = box.querySelectorAll('[data-voice-tab]'), sets = box.querySelectorAll('[data-voice-set]'), tabsBox = box.querySelector('.v2x-voice-tabs');
    tabs.forEach(function (t, i) {
      t.addEventListener('click', function () {
        tabsBox.style.setProperty('--tab', i);
        tabs.forEach(function (x, k) { x.setAttribute('aria-selected', k === i ? 'true' : 'false'); });
        sets.forEach(function (st, k) { st.classList.toggle('is-on', k === i); });
      });
    });
  });

  // The film player: opens a little larger, with a yellow cross.
  var lb = null, lastBtn = null;
  var closeLb = function () {
    if (!lb) return;
    var box = lb; lb = null;
    box.classList.remove('is-on');
    var v = box.querySelector('video'); if (v) { v.pause(); }
    setTimeout(function () { box.remove(); }, 350);
    document.documentElement.style.overflow = '';
    document.removeEventListener('keydown', onKey);
    if (lastBtn) lastBtn.focus();
  };
  var onKey = function (e) { if (e.key === 'Escape') closeLb(); };
  document.addEventListener('click', function (e) {
    var b = e.target.closest && e.target.closest('[data-clip]');
    if (!b) return;
    e.preventDefault();
    lastBtn = b;
    document.querySelectorAll('.ak-play.is-playing').forEach(function (p) { p.click(); });
    var wrap = document.createElement('div');
    wrap.className = 'v2x-lb';
    wrap.setAttribute('role', 'dialog'); wrap.setAttribute('aria-modal', 'true'); wrap.setAttribute('aria-label', b.getAttribute('data-clip-title') || 'Film');
    wrap.innerHTML = '<div class="v2x-lb-box"><button type="button" class="v2x-lb-x" aria-label="Zamknij film"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg></button><video controls playsinline autoplay></video><p class="v2x-lb-t"></p></div>';
    wrap.querySelector('video').src = b.getAttribute('data-clip');
    wrap.querySelector('.v2x-lb-t').textContent = b.getAttribute('data-clip-title') || '';
    wrap.addEventListener('click', function (ev) { if (ev.target === wrap) closeLb(); });
    wrap.querySelector('.v2x-lb-x').addEventListener('click', closeLb);
    document.body.appendChild(wrap);
    document.documentElement.style.overflow = 'hidden';
    document.addEventListener('keydown', onKey);
    requestAnimationFrame(function () { wrap.classList.add('is-on'); wrap.querySelector('.v2x-lb-x').focus(); });
    lb = wrap;
  });

  // Price: Szop'en pops up beside the plans and whispers one tip after another.
  document.querySelectorAll('[data-tip]').forEach(function (tip) {
    var say = tip.querySelector('.v2x-tip-say'), span = say.querySelector('span'), tips = [];
    try { tips = JSON.parse(tip.getAttribute('data-tips') || '[]'); } catch (e) {}
    if (tips.length < 2) return;
    var at = 1, tm = null;
    var swap = function (n) {
      if (still) { span.textContent = tips[n]; return; }
      say.classList.add('is-swap');
      setTimeout(function () { span.textContent = tips[n]; say.classList.remove('is-swap'); }, 260);
    };
    var run = function () { clearInterval(tm); if (!still) tm = setInterval(function () { at = (at + 1) % tips.length; swap(at); }, 4800); };
    watch(tip.parentNode, function () { tip.classList.add('is-in'); run(); }, function () { clearInterval(tm); }, 0.35);
    tip.parentNode.querySelectorAll('.v2-plan').forEach(function (pl, i) {
      pl.addEventListener('mouseenter', function () { at = i === 1 ? 1 : 0; swap(at); run(); });
    });
  });
})();

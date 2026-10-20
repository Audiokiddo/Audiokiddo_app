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

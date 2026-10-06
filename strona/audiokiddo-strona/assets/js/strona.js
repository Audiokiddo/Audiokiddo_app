/* AudioKiddo – strona: menu, the header, things appearing, the typing headline, samples, videos,
   the parents' row, the cart toast, the contents highlight, and Szop'en guiding through the slides. */
(function () {
  'use strict';

  var root = document.documentElement;
  root.classList.add('ak-js');
  window.akReady = true;
  var still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var finePointer = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
  var store = {
    get: function (k) { try { return window.localStorage.getItem(k); } catch (e) { return null; } },
    set: function (k, v) { try { window.localStorage.setItem(k, v); } catch (e) { /* private mode */ } }
  };
  function $(sel, ctx) { return (ctx || document).querySelector(sel); }
  function $$(sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); }
  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

  // Menu on phones
  var menuBtn = $('.ak-menu-btn');
  var nav = document.getElementById('ak-nav');
  if (menuBtn && nav) {
    menuBtn.addEventListener('click', function () {
      var open = nav.classList.toggle('is-open');
      menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    nav.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') {
        nav.classList.remove('is-open');
        menuBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // Things come in as they scroll into view
  var revealed = $$('[data-reveal]');
  if ('IntersectionObserver' in window && !still) {
    var revealer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-in');
          revealer.unobserve(entry.target);
        }
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.12 });
    revealed.forEach(function (el) { revealer.observe(el); });
  } else {
    revealed.forEach(function (el) { el.classList.add('is-in'); });
  }

  // The headline types where the child gets bored
  var typed = $('.ak-type');
  if (typed && !still) {
    var words = JSON.parse(typed.getAttribute('data-words') || '[]');
    var w = 0;
    var c = words[0] ? words[0].length : 0;
    var deleting = true;
    (function tick() {
      var word = words[w] || '';
      if (deleting) {
        c--;
        if (c <= 0) { deleting = false; w = (w + 1) % words.length; }
      } else {
        c++;
        if (c >= word.length) { deleting = true; typed.textContent = word; return setTimeout(tick, 2200); }
      }
      typed.textContent = (words[w] || '').slice(0, Math.max(c, 0)) || ' ';
      setTimeout(tick, deleting ? 38 : 75);
    })();
  }

  // Scrolling: header, progress, the statement lighting up, the hero drifting, the snapping
  var top = $('.ak-top');
  var statement = $('.ak-statement');
  var statementWords = statement ? $$('span', statement) : [];
  var heroImg = $('.ak-hero-img');
  var lastY = window.scrollY;
  var ticking = false;
  var onScrollHooks = [];
  function onScroll() {
    var y = window.scrollY;
    var vh = window.innerHeight;
    if (top) {
      top.classList.toggle('is-scrolled', y > 8);
      var menuOpen = nav && nav.classList.contains('is-open');
      top.classList.toggle('is-hidden', !menuOpen && y > 400 && y > lastY + 4);
      if (y < lastY - 4) top.classList.remove('is-hidden');
      var max = document.documentElement.scrollHeight - vh;
      top.style.setProperty('--scroll', max > 0 ? (y / max).toFixed(4) : 0);
    }
    if (statementWords.length && !still) {
      var r = statement.getBoundingClientRect();
      var p = clamp((vh * 0.88 - r.top) / (r.height + vh * 0.3), 0, 1);
      var lit = Math.round(p * statementWords.length);
      statementWords.forEach(function (s, i) { s.classList.toggle('on', i < lit); });
    }
    if (heroImg && !still && y < vh * 1.2) heroImg.style.setProperty('--para', (y * 0.12).toFixed(1) + 'px');
    onScrollHooks.forEach(function (fn) { fn(y, vh); });
    lastY = y;
    ticking = false;
  }
  window.addEventListener('scroll', function () {
    if (!ticking) { ticking = true; window.requestAnimationFrame(onScroll); }
  }, { passive: true });
  window.addEventListener('resize', onScroll);
  if ($('.ak-slide') && !still && window.matchMedia('(min-width: 961px)').matches) root.classList.add('ak-snap');

  // Samples: one at a time, the ring fills, the bars dance
  var audio = null;
  var playing = null;
  function stopAudio() {
    if (audio) audio.pause();
    if (playing) {
      playing.classList.remove('is-playing');
      playing.style.setProperty('--p', 0);
      var card = playing.closest('.ak-sample');
      if (card) card.classList.remove('is-playing-card');
    }
    playing = null;
  }
  $$('.ak-play').forEach(function (btn) {
    btn.addEventListener('click', function () {
      if (playing === btn) { stopAudio(); return; }
      stopAudio();
      stopVideos();
      audio = new Audio(btn.getAttribute('data-src'));
      playing = btn;
      btn.classList.add('is-playing');
      var card = btn.closest('.ak-sample');
      if (card) card.classList.add('is-playing-card');
      audio.addEventListener('timeupdate', function () {
        if (audio.duration) btn.style.setProperty('--p', audio.currentTime / audio.duration);
      });
      audio.addEventListener('ended', stopAudio);
      audio.play().catch(stopAudio);
    });
  });

  // Children's videos: the poster turns into the film, with sound
  function stopVideos() { $$('.ak-video video').forEach(function (v) { v.pause(); }); }
  $$('.ak-video-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      stopAudio();
      stopVideos();
      var video = document.createElement('video');
      video.src = btn.getAttribute('data-src');
      video.controls = true;
      video.autoplay = true;
      video.playsInline = true;
      video.setAttribute('playsinline', '');
      video.poster = $('img', btn).src;
      video.setAttribute('aria-label', btn.getAttribute('aria-label').replace('Włącz film: ', ''));
      btn.replaceWith(video);
      video.play().catch(function () { /* the controls are there */ });
    });
  });

  // Parents' row: arrows, and dragging with the mouse
  var row = $('.ak-reviews');
  if (row) {
    $$('.ak-arrow').forEach(function (a) {
      a.addEventListener('click', function () {
        var card = $('.ak-review', row);
        var step = card ? card.getBoundingClientRect().width + 20 : 300;
        row.scrollBy({ left: step * Number(a.getAttribute('data-dir')), behavior: still ? 'auto' : 'smooth' });
      });
    });
    var dragX = null;
    var startLeft = 0;
    row.addEventListener('pointerdown', function (e) {
      if (e.pointerType !== 'mouse') return;
      dragX = e.clientX;
      startLeft = row.scrollLeft;
    });
    window.addEventListener('pointermove', function (e) {
      if (dragX === null) return;
      if (Math.abs(e.clientX - dragX) > 4) row.classList.add('is-drag');
      row.scrollLeft = startLeft - (e.clientX - dragX);
    });
    window.addEventListener('pointerup', function () {
      if (dragX === null) return;
      dragX = null;
      row.classList.remove('is-drag');
    });
  }

  // Pack covers lean towards the mouse
  if (finePointer && !still) {
    $$('[data-tilt]').forEach(function (el) {
      var img = $('img', el);
      el.addEventListener('pointermove', function (e) {
        var r = el.getBoundingClientRect();
        var x = (e.clientX - r.left) / r.width - 0.5;
        var y = (e.clientY - r.top) / r.height - 0.5;
        img.style.setProperty('--ry', (x * 10).toFixed(2) + 'deg');
        img.style.setProperty('--rx', (-y * 10).toFixed(2) + 'deg');
      });
      el.addEventListener('pointerleave', function () {
        img.style.setProperty('--ry', '0deg');
        img.style.setProperty('--rx', '0deg');
      });
    });
  }

  // After WooCommerce adds to the cart (its event comes through jQuery)
  var toast = $('.ak-toast');
  var cartLink = $('.ak-cart');
  var hideTimer = null;
  function showToast(name) {
    if (!toast) return;
    toast.textContent = '';
    var text = document.createElement('span');
    text.textContent = name ? 'Dodano: ' + name : 'Dodano do koszyka';
    toast.appendChild(text);
    if (cartLink) {
      var go = document.createElement('a');
      go.href = cartLink.getAttribute('href');
      go.textContent = 'Przejdź do koszyka';
      toast.appendChild(go);
      cartLink.classList.remove('is-bump');
      void cartLink.offsetWidth;
      cartLink.classList.add('is-bump');
    }
    toast.hidden = false;
    clearTimeout(hideTimer);
    hideTimer = setTimeout(function () { toast.hidden = true; }, 6000);
  }
  if (window.jQuery) {
    window.jQuery(document.body).on('added_to_cart', function (e, fragments, hash, button) {
      var label = button && button.attr ? (button.attr('aria-label') || '') : '';
      showToast(label.replace('Dodaj do koszyka: ', ''));
    });
  }

  // The MailerLite form comes with the site's tags; if it never shows up, a mail link does
  var ml = $('.ak-form .ml-embedded');
  if (ml) {
    setTimeout(function () {
      if (!ml.children.length) {
        var form = ml.closest('.ak-form');
        if (form) form.hidden = true;
        var fallback = $('.ak-form-fallback');
        if (fallback) fallback.hidden = false;
      }
    }, 7000);
  }

  // Article contents: mark the section being read
  var tocLinks = $$('.ak-toc a');
  if (tocLinks.length && 'IntersectionObserver' in window) {
    var byId = {};
    tocLinks.forEach(function (a) { byId[a.getAttribute('href').slice(1)] = a; });
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting && byId[entry.target.id]) {
          tocLinks.forEach(function (a) { a.classList.remove('is-here'); });
          byId[entry.target.id].classList.add('is-here');
        }
      });
    }, { rootMargin: '0px 0px -70% 0px' });
    Object.keys(byId).forEach(function (id) {
      var el = document.getElementById(id);
      if (el) observer.observe(el);
    });
  }

  // Slides: which one is on screen; the dots on the side and the menu follow it
  var slides = $$('.ak-slide[data-slide]');
  if (!slides.length) return;
  var dotsNav = $('.ak-dots');
  var dots = [];
  var navLinks = nav ? $$('a', nav) : [];
  if (dotsNav) {
    slides.forEach(function (slide) {
      var dot = document.createElement('button');
      dot.type = 'button';
      dot.className = 'ak-dot';
      dot.setAttribute('aria-label', slide.getAttribute('data-slide'));
      var label = document.createElement('span');
      label.textContent = slide.getAttribute('data-slide');
      dot.appendChild(label);
      dot.addEventListener('click', function () { slide.scrollIntoView({ behavior: still ? 'auto' : 'smooth' }); });
      dotsNav.appendChild(dot);
      dots.push(dot);
    });
  }
  var current = null;
  var settle = null;
  var listeners = [];
  function slideAt(vh) {
    var mark = vh * 0.45;
    for (var i = 0; i < slides.length; i++) {
      var r = slides[i].getBoundingClientRect();
      if (r.top <= mark && r.bottom > mark) return slides[i];
    }
    return null;
  }
  onScrollHooks.push(function (y, vh) {
    var slide = slideAt(vh);
    if (!slide || slide === current) return;
    current = slide;
    var i = slides.indexOf(slide);
    dots.forEach(function (d, k) { d.classList.toggle('is-here', k === i); });
    document.body.classList.toggle('ak-on-dark', slide.classList.contains('ak-dark') || slide.classList.contains('ak-end'));
    navLinks.forEach(function (a) { a.classList.toggle('is-here', a.hash === '#' + slide.id); });
    // Wait until the scrolling settles before Szop'en starts talking about it.
    clearTimeout(settle);
    settle = setTimeout(function () { listeners.forEach(function (fn) { fn(slide); }); }, 450);
  });
  onScroll();

  // Szop'en presents each slide and points at what matters
  var guide = $('.ak-guide');
  var tourData = document.getElementById('ak-tour');
  if (!guide || !tourData) return;
  var tour = JSON.parse(tourData.textContent || '{}');
  var spot = $('.ak-spot');
  var bubbleText = $('.ak-guide-text', guide);
  var stepsEl = $('.ak-guide-steps', guide);
  var poses = {};
  $$('.ak-guide-me img', guide).forEach(function (img) { img.loading = 'eager'; poses[img.getAttribute('data-pose')] = img; });
  var quiet = store.get('ak_szop_cicho') === '1';
  var shown = null;
  var lines = [];
  var at = -1;
  var target = null;
  var seen = {};
  var lineTimer = null;
  var typeTimer = null;
  var spotFrame = null;

  function setPose(name) {
    var img = poses[name] || poses.zadowolony;
    if (!img || img.classList.contains('on')) return;
    Object.keys(poses).forEach(function (k) { poses[k].classList.remove('on', 'is-pop'); });
    img.classList.add('on');
    if (!still) {
      img.classList.add('is-pop');
      setTimeout(function () { img.classList.remove('is-pop'); }, 650);
    }
  }
  function talk(text) {
    clearTimeout(typeTimer);
    if (still) { bubbleText.textContent = text; return; }
    guide.classList.add('is-talking');
    var n = 0;
    (function type() {
      n += 2;
      bubbleText.textContent = text.slice(0, n);
      if (n < text.length) typeTimer = setTimeout(type, 28);
      else guide.classList.remove('is-talking');
    })();
  }
  function placeSpot() {
    if (!target || !spot) return;
    var r = target.getBoundingClientRect();
    var vh = window.innerHeight;
    var pad = 12;
    var t = Math.max(r.top - pad, 72);
    var b = Math.min(r.bottom + pad, vh - 8);
    if (b - t < 40) { spotOff(); return; }
    // The position glides (transform); the size simply follows the element.
    spot.style.transform = 'translate(' + Math.max(r.left - pad, 6) + 'px, ' + t + 'px)';
    spot.style.width = Math.min(r.width + pad * 2, window.innerWidth - 12) + 'px';
    spot.style.height = (b - t) + 'px';
    spotFrame = window.requestAnimationFrame(placeSpot);
  }
  function spotOn(el) {
    target = el;
    if (!spot || quiet) return;
    window.cancelAnimationFrame(spotFrame);
    spot.classList.add('is-on');
    placeSpot();
  }
  function spotOff() {
    if (spot) spot.classList.remove('is-on');
    window.cancelAnimationFrame(spotFrame);
    target = null;
  }
  function drawSteps() {
    stepsEl.textContent = '';
    lines.forEach(function (l, i) {
      var dot = document.createElement('i');
      if (i === at) dot.className = 'on';
      stepsEl.appendChild(dot);
    });
  }
  function showLine(i, point) {
    clearTimeout(lineTimer);
    at = i;
    var line = lines[i];
    talk(line.say);
    drawSteps();
    if (point) spotOn(line.el); else spotOff();
    var wait = Math.max(3800, line.say.length * 60);
    if (i < lines.length - 1) {
      lineTimer = setTimeout(function () { showLine(i + 1, point); }, wait);
    } else {
      seen[shown.id] = true;
      lineTimer = setTimeout(spotOff, wait);
    }
  }
  function present(slide, fromStart) {
    shown = slide;
    clearTimeout(lineTimer);
    var data = tour[slide.id];
    lines = [];
    if (data) {
      data.lines.forEach(function (l) {
        var el = $(l.at, slide);
        if (el) lines.push({ el: el, say: l.say });
      });
    }
    if (!lines.length) { spotOff(); return; }
    setPose(data.pose);
    if (quiet) return;
    // A slide already presented: one line, no spotlight, unless asked to tell it again.
    if (seen[slide.id] && !fromStart) { at = 0; talk(lines[0].say); drawSteps(); spotOff(); return; }
    showLine(0, true);
  }
  function next() {
    if (!shown) return;
    if (at < lines.length - 1) { showLine(at + 1, true); return; }
    var i = slides.indexOf(shown);
    var following = slides[i + 1];
    spotOff();
    if (following) following.scrollIntoView({ behavior: still ? 'auto' : 'smooth' });
  }
  function hush(on) {
    quiet = on;
    store.set('ak_szop_cicho', on ? '1' : '0');
    guide.classList.toggle('is-quiet', on);
    if (on) { clearTimeout(lineTimer); clearTimeout(typeTimer); guide.classList.remove('is-talking'); spotOff(); }
  }

  listeners.push(function (slide) { if (!guide.hidden) present(slide, false); });
  $('.ak-guide-next', guide).addEventListener('click', next);
  $('.ak-guide-hush', guide).addEventListener('click', function () { hush(true); });
  $('.ak-guide-me', guide).addEventListener('click', function () {
    if (quiet) hush(false);
    if (current) present(current, true);
  });
  // A tap anywhere else puts the spotlight away, so it never stands in the way.
  document.addEventListener('pointerdown', function (e) {
    if (!guide.contains(e.target)) spotOff();
  });
  window.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') spotOff();
  });

  guide.classList.toggle('is-quiet', quiet);
  setTimeout(function () {
    guide.hidden = false;
    if (!still) guide.classList.add('is-enter');
    if (current) present(current, false);
  }, 900);
})();

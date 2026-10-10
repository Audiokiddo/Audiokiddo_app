/* AudioKiddo – strona: menu, the header, things appearing, the typing headline, samples, videos,
   the parents' row, the cart confirmation on the button, the contents highlight, and Szop'en guiding through the slides. */
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

  // Phones: the page is a deck of full-screen slides with a dock at the bottom.
  var phone = window.matchMedia('(max-width: 760px)');

  // Menu on phones: the button in the bar and the one in the dock open the same list
  var menuBtns = $$('.ak-menu-btn, .ak-dock-menu');
  var nav = document.getElementById('ak-nav');
  function setMenu(open) {
    if (!nav) return;
    nav.classList.toggle('is-open', open);
    menuBtns.forEach(function (b) { b.setAttribute('aria-expanded', open ? 'true' : 'false'); });
    menuBtns.forEach(function (b) { b.setAttribute('aria-label', open ? 'Zamknij menu' : 'Otwórz menu'); });
  }
  if (menuBtns.length && nav) {
    menuBtns.forEach(function (b) {
      b.addEventListener('click', function () { setMenu(!nav.classList.contains('is-open')); });
    });
    nav.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') setMenu(false);
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && nav.classList.contains('is-open')) {
        setMenu(false);
        menuBtns[0].focus();
      }
    });
    document.addEventListener('click', function (e) {
      if (nav.classList.contains('is-open') && !nav.contains(e.target) && !menuBtns.some(function (b) { return b.contains(e.target); })) setMenu(false);
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

  // The app section: a feature picked beside the phone shows its screen; while the section is in
  // view and nobody has clicked, the features take turns by themselves.
  var appSec = $('.ak-app');
  if (appSec) {
    var feats = $$('.ak-feat', appSec);
    var shots = $$('.ak-phone-shot', appSec);
    var featAt = 0;
    var featTimer = null;
    var featTime = 5500;
    var touched = false;
    appSec.style.setProperty('--feat-time', featTime + 'ms');
    function pick(i) {
      featAt = (i + feats.length) % feats.length;
      var shot = feats[featAt].getAttribute('data-shot');
      feats.forEach(function (f, k) { f.setAttribute('aria-selected', k === featAt ? 'true' : 'false'); });
      shots.forEach(function (img) { img.classList.toggle('is-on', img.getAttribute('data-shot') === shot); });
      // Restart the little progress bar under the picked feature.
      var bar = $('.ak-feat-progress i', feats[featAt]);
      if (bar) { bar.style.animation = 'none'; void bar.offsetWidth; bar.style.animation = ''; }
    }
    function playFeats(on) {
      clearInterval(featTimer);
      appSec.classList.toggle('is-playing', on && !touched && !still);
      if (on && !touched && !still) featTimer = setInterval(function () { pick(featAt + 1); }, featTime);
    }
    feats.forEach(function (f, i) {
      f.addEventListener('click', function () { touched = true; playFeats(false); pick(i); });
      f.addEventListener('keydown', function (e) {
        if (e.key === 'ArrowDown' || e.key === 'ArrowRight') { e.preventDefault(); touched = true; playFeats(false); pick(i + 1); feats[featAt].focus(); }
        if (e.key === 'ArrowUp' || e.key === 'ArrowLeft') { e.preventDefault(); touched = true; playFeats(false); pick(i - 1); feats[featAt].focus(); }
      });
    });
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) { playFeats(entry.isIntersecting); });
      }, { threshold: 0.35 }).observe(appSec);
    }
  }

  // Tabs (the moments, the ages): click or arrow keys pick one; its panel shows, the rest hide.
  function tabs(list, onPick) {
    var btns = $$('[role="tab"]', list);
    function pick(i, focus) {
      btns.forEach(function (b, k) {
        var on = k === i;
        b.setAttribute('aria-selected', on ? 'true' : 'false');
        b.tabIndex = on ? 0 : -1;
        var panel = document.getElementById(b.getAttribute('aria-controls'));
        if (panel) panel.classList.toggle('is-on', on);
      });
      if (focus) btns[i].focus();
      if (onPick) onPick(i);
    }
    btns.forEach(function (b, i) {
      b.addEventListener('click', function () { pick(i, false); });
      b.addEventListener('keydown', function (e) {
        var step = e.key === 'ArrowRight' || e.key === 'ArrowDown' ? 1 : e.key === 'ArrowLeft' || e.key === 'ArrowUp' ? -1 : 0;
        if (!step) return;
        e.preventDefault();
        pick((i + step + btns.length) % btns.length, true);
      });
    });
  }
  var momentsPick = $('.ak-a-times, .ak-moments-pick');
  if (momentsPick) {
    var momentSzop = $('.ak-moments-szop');
    tabs(momentsPick, function () {
      if (!momentSzop || still) return;
      momentSzop.classList.remove('is-pop');
      void momentSzop.offsetWidth;
      momentSzop.classList.add('is-pop');
    });
  }
  // The day with Audiokiddo moves on by itself while it is in view, so nobody has to find the
  // buttons; a click takes over and stops the show.
  var dayTabs = $('.ak-a-times');
  if (dayTabs && !still && 'IntersectionObserver' in window) {
    var dayBtns = $$('[role="tab"]', dayTabs);
    var dayTimer = null;
    var dayHand = false;
    function dayStep() {
      var at = dayBtns.findIndex(function (b) { return b.getAttribute('aria-selected') === 'true'; });
      var nxt = dayBtns[(at + 1) % dayBtns.length];
      nxt.click();
    }
    dayBtns.forEach(function (b) { b.addEventListener('pointerdown', function () { dayHand = true; clearInterval(dayTimer); }); });
    new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        clearInterval(dayTimer);
        if (entry.isIntersecting && !dayHand) dayTimer = setInterval(dayStep, 4200);
      });
    }, { threshold: 0.5 }).observe(dayTabs);
  }
  var agePick = $('.ak-agepick-tabs');
  if (agePick) tabs(agePick);

  // How it works: each step shows its screen on the phone; while the section is in view and
  // nobody has clicked, the steps take turns by themselves.
  var howto = $('.ak-howto');
  if (howto) {
    var steps = $$('.ak-howto-step', howto);
    var stepShots = $$('.ak-phone-shot', howto);
    var stepAt = 0;
    var stepTimer = null;
    var stepTouched = false;
    function pickStep(i) {
      stepAt = (i + steps.length) % steps.length;
      var shot = steps[stepAt].getAttribute('data-shot');
      steps.forEach(function (st, k) { st.setAttribute('aria-selected', k === stepAt ? 'true' : 'false'); });
      stepShots.forEach(function (img) { img.classList.toggle('is-on', img.getAttribute('data-shot') === shot); });
    }
    function runSteps(on) {
      clearInterval(stepTimer);
      if (on && !stepTouched && !still) stepTimer = setInterval(function () { pickStep(stepAt + 1); }, 4200);
    }
    steps.forEach(function (st, i) {
      st.addEventListener('click', function () { stepTouched = true; runSteps(false); pickStep(i); });
    });
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) { runSteps(entry.isIntersecting); });
      }, { threshold: 0.4 }).observe(howto);
    }
  }

  // Szop'en's bubbles next to the content type themselves in when they come into view.
  if (!still && 'IntersectionObserver' in window) {
    var typer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        typer.unobserve(entry.target);
        var cap = $('figcaption', entry.target);
        var node = cap ? cap.lastChild : null;
        if (!node || node.nodeType !== 3) return;
        var full = node.nodeValue;
        var n = 0;
        node.nodeValue = '';
        setTimeout(function type() {
          n += 2;
          node.nodeValue = full.slice(0, n);
          if (n < full.length) setTimeout(type, 26);
        }, 450);
      });
    }, { threshold: 0.6 });
    $$('.ak-szop').forEach(function (el) { typer.observe(el); });
  }

  // Pack page: once the buy box scrolls away, a slim bar with the price and the cart follows.
  var buybar = $('.ak-buybar');
  var buybox = document.getElementById('kup');
  if (buybar && buybox && 'IntersectionObserver' in window) {
    new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        buybar.classList.toggle('is-on', !entry.isIntersecting && entry.boundingClientRect.top < 0);
      });
    }).observe(buybox);
  }

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

  // The cart opens at the side instead of loading the cart page: the items, the total and the
  // way to checkout. WooCommerce keeps its contents fresh (cart fragments); the cart icons still
  // lead to the cart page when the script is off or with a modifier key.
  var drawer = document.getElementById('ak-cart-drawer');
  var veil = $('.ak-drawer-veil');
  var drawerBack = null;
  function openCart(added) {
    if (!drawer) return;
    drawerBack = document.activeElement;
    drawer.hidden = false;
    if (veil) veil.hidden = false;
    var note = $('.ak-drawer-added', drawer);
    if (note) note.hidden = !added;
    void drawer.offsetWidth;
    drawer.classList.add('is-open');
    if (veil) veil.classList.add('is-open');
    root.classList.add('ak-locked');
    $('.ak-drawer-close', drawer).focus({ preventScroll: true });
  }
  function closeCart() {
    if (!drawer || drawer.hidden) return;
    drawer.classList.remove('is-open');
    if (veil) veil.classList.remove('is-open');
    root.classList.remove('ak-locked');
    setTimeout(function () { drawer.hidden = true; if (veil) veil.hidden = true; }, still ? 0 : 350);
    if (drawerBack && drawerBack.focus) drawerBack.focus({ preventScroll: true });
  }
  if (drawer) {
    $$('.ak-cart, .ak-dock-cart').forEach(function (a) {
      a.addEventListener('click', function (e) {
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
        e.preventDefault();
        openCart(false);
      });
    });
    $('.ak-drawer-close', drawer).addEventListener('click', closeCart);
    if (veil) veil.addEventListener('click', closeCart);
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') closeCart();
      // Keep Tab inside the open cart.
      if (e.key === 'Tab' && drawer.classList.contains('is-open')) {
        var f = $$('a[href], button:not([disabled]), input', drawer).filter(function (el) { return el.offsetParent !== null; });
        if (!f.length) return;
        if (e.shiftKey && document.activeElement === f[0]) { e.preventDefault(); f[f.length - 1].focus(); }
        else if (!e.shiftKey && document.activeElement === f[f.length - 1]) { e.preventDefault(); f[0].focus(); }
      }
    });
  }

  // After WooCommerce adds to the cart: the button itself says so and WooCommerce's own link
  // to the cart sits under it; the cart in the bar and the dock bounces. Nothing floats over
  // the page.
  if (window.jQuery) {
    // While WooCommerce works on it, the button says so in Szop's words.
    window.jQuery(document.body).on('adding_to_cart', function (e, button) {
      var el = button && button.get ? button.get(0) : null;
      if (el && el.classList.contains('ak-btn')) {
        el.setAttribute('data-label', el.textContent);
        el.textContent = 'Szop coś grzebie…';
      }
    });
    window.jQuery(document.body).on('added_to_cart', function (e, fragments, hash, button) {
      var el = button && button.get ? button.get(0) : null;
      if (el && el.classList.contains('ak-btn')) {
        el.classList.add('is-added');
        el.textContent = '✓ W koszyku';
      }
      openCart(true);
      $$('.ak-cart, .ak-dock-cart').forEach(function (c) {
        c.classList.remove('is-bump');
        void c.offsetWidth;
        c.classList.add('is-bump');
      });
    });
  }

  // "Pobierz Audiokiddo" goes straight to the store of the phone in hand; on a computer it
  // stays on the section with both store buttons.
  var ua = navigator.userAgent || '';
  var os = /iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && 'ontouchend' in document) ? 'ios' : (/Android/.test(ua) ? 'android' : '');
  if (os) {
    $$('.ak-app-cta').forEach(function (a) {
      var url = a.getAttribute('data-' + os);
      if (url) { a.href = url; a.rel = 'noopener'; }
    });
    $$('.ak-stores').forEach(function (box) {
      var mine = box.querySelector('.ak-store[data-os="' + os + '"]');
      if (mine) box.insertBefore(mine, box.firstChild);
    });
  }

  // Our newsletter sign-up: sent through the site to MailerLite; the cards download right away.
  $$('.ak-signup').forEach(function (form) {
    var msg = $('.ak-signup-msg', form);
    var btn = $('button[type="submit"]', form);
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var email = form.email.value.trim();
      msg.textContent = '';
      form.classList.remove('is-error');
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { msg.textContent = 'Ten adres e-mail wygląda podejrzanie. Sprawdź literówki.'; form.classList.add('is-error'); form.email.focus(); return; }
      if (!form.zgoda.checked) { msg.textContent = 'Zaznacz zgodę na newsletter, wtedy wyślemy Ci materiały.'; form.classList.add('is-error'); return; }
      var label = btn.textContent;
      btn.disabled = true;
      btn.textContent = 'Szop coś grzebie…';
      var body = new URLSearchParams({ action: 'ak_zapis', email: email, zgoda: '1', strona: form.strona.value });
      fetch(form.getAttribute('data-endpoint'), { method: 'POST', body: body, credentials: 'same-origin' }).then(function (r) { return r.json(); }).then(function (data) {
        if (!data || !data.ok) throw new Error(data && data.message ? data.message : '');
        $('.ak-signup-row', form).hidden = true;
        $('.ak-signup-ok', form).hidden = true;
        var done = $('.ak-signup-done', form);
        $('.ak-signup-dl', done).href = data.download;
        done.hidden = false;
        if (window.dataLayer) window.dataLayer.push({ event: 'generate_lead', lead_source: form.id });
      }).catch(function (err) {
        msg.textContent = (err && err.message) || 'Coś się wysypało po drodze. Spróbuj jeszcze raz za chwilę.';
        form.classList.add('is-error');
        btn.disabled = false;
        btn.textContent = label;
      });
    });
  });

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
  var storyBars = $('.ak-story-bars');
  var storyLabel = $('.ak-story-label');
  var bars = [];
  slides.forEach(function (slide, i) {
    slide.setAttribute('data-n', (i < 9 ? '0' : '') + (i + 1));
    if (!storyBars) return;
    var bar = document.createElement('i');
    storyBars.appendChild(bar);
    bars.push(bar);
  });
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
    bars.forEach(function (b, k) { b.className = k < i ? 'done' : k === i ? 'on' : ''; });
    if (storyLabel) storyLabel.textContent = (i + 1) + ' / ' + slides.length + ' · ' + slide.getAttribute('data-slide');
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
  var phoneQuiet = ['start', 'cennik', 'pytania', 'start-aplikacji', 'koniec'];
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
    if (point && line.spot && !phone.matches) spotOn(line.el); else spotOff();
    var wait = Math.max(phone.matches ? 2800 : 3400, line.say.length * (phone.matches ? 45 : 55));
    if (i < lines.length - 1) {
      lineTimer = setTimeout(function () { showLine(i + 1, point); }, wait);
    } else {
      seen[shown.id] = true;
      lineTimer = setTimeout(function () { spotOff(); guide.classList.add('is-idle'); }, wait + 1500);
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
        if (el) lines.push({ el: el, say: l.say, spot: !!l.spot });
      });
    }
    // Each section gets one line, once; after it (and on a section already shown) he sits
    // quietly in the corner, the bubble folded away.
    // On phones the bubble takes a good part of the screen, so he keeps quiet where it would
    // cover the buttons that matter (the hero, the subscription, the forms, the end).
    var stop = lines.length && (fromStart || (!seen[slide.id] && !(phone.matches && phoneQuiet.indexOf(slide.id) > -1)));
    guide.classList.toggle('is-idle', !stop);
    if (!stop) {
      clearTimeout(typeTimer);
      guide.classList.remove('is-talking');
      spotOff();
      setPose('zadowolony');
      return;
    }
    setPose(data.pose);
    if (quiet) return;
    showLine(0, true);
  }
  /** The next slide where Szop'en has something to show. */
  function nextStop(from) {
    for (var i = slides.indexOf(from) + 1; i < slides.length; i++) {
      if (tour[slides[i].id]) return slides[i];
    }
    return null;
  }
  function next() {
    if (!shown) return;
    if (at < lines.length - 1) { showLine(at + 1, true); return; }
    var following = nextStop(shown);
    spotOff();
    guide.classList.add('is-idle');
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
    if (!current) return;
    if (tour[current.id]) { present(current, true); return; }
    var following = nextStop(current);
    if (following) following.scrollIntoView({ behavior: still ? 'auto' : 'smooth' });
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

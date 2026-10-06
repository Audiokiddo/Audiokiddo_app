/* AudioKiddo – strona: menu, previews, the billing switch, the cart toast, the contents highlight. */
(function () {
  'use strict';

  // Menu on phones
  var menuBtn = document.querySelector('.ak-menu-btn');
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

  // Previews: one at a time, the ring fills as it plays
  var audio = null;
  var current = null;
  function stop() {
    if (audio) audio.pause();
    if (current) {
      current.classList.remove('is-playing');
      current.style.setProperty('--p', 0);
    }
    current = null;
  }
  document.querySelectorAll('.ak-listen').forEach(function (btn) {
    btn.addEventListener('click', function () {
      if (current === btn) {
        stop();
        return;
      }
      stop();
      audio = new Audio(btn.getAttribute('data-src'));
      current = btn;
      btn.classList.add('is-playing');
      audio.addEventListener('timeupdate', function () {
        if (audio.duration) btn.style.setProperty('--p', audio.currentTime / audio.duration);
      });
      audio.addEventListener('ended', stop);
      audio.play().catch(stop);
    });
  });

  // Monthly or yearly prices
  var tickets = document.querySelector('.ak-tickets');
  document.querySelectorAll('.ak-period button').forEach(function (btn) {
    btn.addEventListener('click', function () {
      document.querySelectorAll('.ak-period button').forEach(function (b) {
        b.setAttribute('aria-pressed', b === btn ? 'true' : 'false');
      });
      if (tickets) tickets.setAttribute('data-period', btn.getAttribute('data-period'));
    });
  });

  // After WooCommerce adds to the cart (its event comes through jQuery)
  var toast = document.querySelector('.ak-toast');
  var cartLink = document.querySelector('.ak-cart');
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

  // Article contents: mark the section being read
  var tocLinks = document.querySelectorAll('.ak-toc a');
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
})();

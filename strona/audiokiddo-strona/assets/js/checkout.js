/* The order page for a month or a year (inc/checkout.php): the invoice link, the pay bar at the bottom
   of a phone, and a word at once when "Zmień na rok" is pressed. Nothing here is needed to pay. */
(function () {
  'use strict';
  var doc = document;
  function $(s, c) { return (c || doc).querySelector(s); }

  // "Potrzebuję faktury na firmę": the NIP field opens on request
  var nip = $('#billing_tax_no_field');
  if (nip) {
    var wrap = nip.parentNode;
    var link = doc.createElement('button');
    link.type = 'button';
    link.className = 'ak-co-invoice';
    link.textContent = 'Potrzebuję faktury na firmę (NIP)';
    wrap.insertBefore(link, nip);
    link.addEventListener('click', function () {
      nip.classList.add('is-open');
      link.hidden = true;
      var input = $('input', nip);
      if (input) input.focus();
    });
    var filled = $('input', nip);
    if (filled && filled.value) { nip.classList.add('is-open'); link.hidden = true; }
  }

  // The newsletter box says what is in it (the field comes from another plugin, so the words are set here)
  var nl = $('#newsletter_signup_field label');
  if (nl && !nl.querySelector('strong')) {
    var box = $('input', nl);
    nl.textContent = '';
    nl.appendChild(box);
    var words = doc.createElement('span');
    words.innerHTML = '<strong>Tak, chcę wiedzieć pierwszy.</strong> Powiadomię Cię o nowych zabawach, wyślę darmowe karty do druku i sprawdzone porady dla rodziców. Piszemy rzadko, a wypiszesz się jednym kliknięciem.';
    nl.appendChild(words);
  }

  // The bar: the sum and the pay button, only while the real button is not in view (phones)
  var place = $('#place_order');
  function sum() {
    var t = $('.order-total .woocommerce-Price-amount');
    return t ? t.textContent.replace(/\s+/g, ' ').trim() : '';
  }
  if (place && 'IntersectionObserver' in window) {
    var bar = doc.createElement('div');
    bar.className = 'ak-paybar';
    bar.innerHTML = '<div><small>Do zapłaty</small><strong></strong></div><button type="button">Zapłać i odbierz dostęp</button>';
    doc.body.appendChild(bar);
    var strong = $('strong', bar);
    var inView = false;
    var showBar = function () { strong.textContent = sum(); bar.classList.toggle('is-on', !inView && window.matchMedia('(max-width: 899px)').matches); };
    new IntersectionObserver(function (entries) { inView = entries[0].isIntersecting; showBar(); }, { threshold: 0.4 }).observe(place);
    $('button', bar).addEventListener('click', function () {
      var live = $('#place_order');
      if (live) live.click();
      // Something missing: Woo shows what, and the page goes to it
    });
    if (window.jQuery) window.jQuery(doc.body).on('updated_checkout', function () { place = $('#place_order'); showBar(); });
    window.addEventListener('resize', showBar);
    showBar();
  }

  // "Zmień na rok" and the like: a word at once, the server takes a moment
  doc.addEventListener('click', function (e) {
    var a = e.target.closest ? e.target.closest('[data-ak-busy]') : null;
    if (!a || e.defaultPrevented || e.metaKey || e.ctrlKey) return;
    var go = doc.createElement('div');
    go.className = 'ak-go';
    go.setAttribute('role', 'status');
    go.innerHTML = '<strong></strong><span class="ak-go-bar"><i></i></span><small>To chwila, nic nie zamykaj.</small>';
    $('strong', go).textContent = a.getAttribute('data-ak-busy');
    doc.body.appendChild(go);
  });
})();

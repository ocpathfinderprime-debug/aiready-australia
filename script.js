/**
 * AIReady Australia — script.js
 * Minimal JS: smooth scroll, mobile nav toggle, sticky header behaviour.
 * No external dependencies. No frameworks.
 */

(function () {
  'use strict';

  /* ============================================================
     MOBILE NAV TOGGLE
     ============================================================ */
  const navToggle = document.getElementById('navToggle');
  const navMenu   = document.getElementById('navMenu');

  if (navToggle && navMenu) {
    navToggle.addEventListener('click', function () {
      const isOpen = navMenu.classList.toggle('is-open');
      navToggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      navToggle.setAttribute('aria-label', isOpen ? 'Close menu' : 'Open menu');
      // Prevent body scroll when menu is open on mobile
      document.body.style.overflow = isOpen ? 'hidden' : '';
    });

    // Close menu when a nav link is clicked
    navMenu.querySelectorAll('.nav-link').forEach(function (link) {
      link.addEventListener('click', function () {
        navMenu.classList.remove('is-open');
        navToggle.setAttribute('aria-expanded', 'false');
        navToggle.setAttribute('aria-label', 'Open menu');
        document.body.style.overflow = '';
      });
    });

    // Close menu on Escape key
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && navMenu.classList.contains('is-open')) {
        navMenu.classList.remove('is-open');
        navToggle.setAttribute('aria-expanded', 'false');
        navToggle.setAttribute('aria-label', 'Open menu');
        document.body.style.overflow = '';
        navToggle.focus();
      }
    });

    // Close menu if clicking outside it on mobile
    document.addEventListener('click', function (e) {
      if (
        navMenu.classList.contains('is-open') &&
        !navMenu.contains(e.target) &&
        !navToggle.contains(e.target)
      ) {
        navMenu.classList.remove('is-open');
        navToggle.setAttribute('aria-expanded', 'false');
        navToggle.setAttribute('aria-label', 'Open menu');
        document.body.style.overflow = '';
      }
    });
  }

  /* ============================================================
     STICKY HEADER — add shadow on scroll
     ============================================================ */
  const header = document.querySelector('.site-header');

  if (header) {
    const onScroll = function () {
      if (window.scrollY > 20) {
        header.classList.add('is-scrolled');
      } else {
        header.classList.remove('is-scrolled');
      }
    };

    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll(); // run once on load
  }

  /* ============================================================
     ACTIVE NAV LINK — highlight current section in view
     ============================================================ */
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-link[href^="#"]');

  if (sections.length && navLinks.length) {
    const observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            const id = entry.target.id;
            navLinks.forEach(function (link) {
              if (link.getAttribute('href') === '#' + id) {
                link.classList.add('is-active');
              } else {
                link.classList.remove('is-active');
              }
            });
          }
        });
      },
      {
        rootMargin: '-30% 0px -60% 0px',
        threshold: 0,
      }
    );

    sections.forEach(function (section) {
      observer.observe(section);
    });
  }

  /* ============================================================
     SMOOTH SCROLL — for browsers that don't support CSS scroll-behavior
     (fallback — modern browsers handle this via CSS)
     ============================================================ */
  document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
    anchor.addEventListener('click', function (e) {
      const targetId = anchor.getAttribute('href');
      if (targetId === '#') return;

      const target = document.querySelector(targetId);
      if (!target) return;

      // Let CSS smooth scroll handle it; only intervene if not supported
      if (!CSS || !CSS.supports || !CSS.supports('scroll-behavior', 'smooth')) {
        e.preventDefault();
        const headerHeight = header ? header.offsetHeight : 0;
        const top = target.getBoundingClientRect().top + window.scrollY - headerHeight - 16;
        window.scrollTo({ top: top, behavior: 'smooth' });
      }
    });
  });

  /* ============================================================
     FAQ — ensure only one open at a time (native <details> groups)
     This is handled natively by the name="faq" attribute in HTML5,
     but we add this fallback for browsers that don't support it yet.
     ============================================================ */
  const faqItems = document.querySelectorAll('.faq-item');

  if (faqItems.length) {
    faqItems.forEach(function (item) {
      item.addEventListener('toggle', function () {
        if (item.open) {
          faqItems.forEach(function (other) {
            if (other !== item && other.open) {
              other.open = false;
            }
          });
        }
      });
    });
  }

  /* ============================================================
     INTERSECTION OBSERVER — fade-in sections on scroll
     ============================================================ */
  if ('IntersectionObserver' in window) {
    const fadeTargets = document.querySelectorAll(
      '.problem-card, .step-card, .pricing-card, .deliverable-item, .stat-card, .faq-item'
    );

    const fadeObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            fadeObserver.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.1 }
    );

    fadeTargets.forEach(function (el, i) {
      el.style.opacity = '0';
      el.style.transform = 'translateY(20px)';
      el.style.transition = 'opacity 0.5s ease ' + (i % 4) * 0.08 + 's, transform 0.5s ease ' + (i % 4) * 0.08 + 's';
      fadeObserver.observe(el);
    });

    // Add class to trigger animation
    document.addEventListener('DOMContentLoaded', function () {
      document.querySelectorAll('.is-visible').forEach(function (el) {
        el.style.opacity = '1';
        el.style.transform = 'translateY(0)';
      });
    });
  }

})(); // end IIFE

/* ============================================================
   CSS additions injected by JS (sticky header border)
   ============================================================ */
(function () {
  const style = document.createElement('style');
  style.textContent = `
    .site-header.is-scrolled {
      box-shadow: 0 4px 24px rgba(0, 0, 0, 0.4);
    }
    .nav-link.is-active {
      color: #00D4FF !important;
    }
    .is-visible {
      opacity: 1 !important;
      transform: translateY(0) !important;
    }
  `;
  document.head.appendChild(style);
})();

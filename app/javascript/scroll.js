const REVEAL_OFFSET = 275;

const revealVisibleTargets = () => {
  const targets = document.querySelectorAll('.fade-in:not(.scroll-in)');
  const windowHeight = window.innerHeight;
  const revealOffset = Math.min(REVEAL_OFFSET, windowHeight * 0.35);

  targets.forEach((target) => {
    if (target.getBoundingClientRect().top < windowHeight - revealOffset) {
      target.classList.add('scroll-in');
    }
  });
};

window.addEventListener('scroll', revealVisibleTargets, { passive: true });
window.addEventListener('resize', revealVisibleTargets, { passive: true });

document.addEventListener('DOMContentLoaded', revealVisibleTargets);
document.addEventListener('turbo:load', revealVisibleTargets);

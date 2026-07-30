/* Decorative animated background: slow-drifting brand-colored gradient orbs.
   Pure CSS transforms (GPU-friendly); hidden from screen readers and
   frozen automatically by the global prefers-reduced-motion rule. */
export function AnimatedBackground() {
  return (
    <div aria-hidden className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
      <div className="bg-orb bg-orb-1" />
      <div className="bg-orb bg-orb-2" />
      <div className="bg-orb bg-orb-3" />
      <div className="bg-sheen" />
    </div>
  );
}

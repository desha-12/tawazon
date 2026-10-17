/// Shared responsive breakpoint. Below it the app keeps the single-column
/// mobile flow; at or above it the home screen splits into two columns.
const double kDesktopBreakpoint = 900;

/// Horizontal page padding that grows with the viewport so wide screens do not
/// stretch content edge to edge.
double responsivePadding(double width) {
  if (width >= 1400) return 48;
  if (width >= kDesktopBreakpoint) return 32;
  return 20;
}

/// Caps content width on very wide displays so text lines stay readable.
const double kMaxContentWidth = 1440;
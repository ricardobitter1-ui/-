/* @ds-bundle: {"format":3,"namespace":"EximiumDesignSystem_b4169c","components":[{"name":"Brand","sourcePath":"components/brand/Brand.jsx"},{"name":"Icon","sourcePath":"components/brand/Icon.jsx"},{"name":"Icons","sourcePath":"components/brand/Icon.jsx"},{"name":"Button","sourcePath":"components/buttons/Button.jsx"},{"name":"ThemeToggle","sourcePath":"components/buttons/ThemeToggle.jsx"},{"name":"Badge","sourcePath":"components/feedback/Badge.jsx"},{"name":"Spinner","sourcePath":"components/feedback/Spinner.jsx"},{"name":"Input","sourcePath":"components/forms/Input.jsx"},{"name":"Toggle","sourcePath":"components/forms/Toggle.jsx"},{"name":"Card","sourcePath":"components/surfaces/Card.jsx"},{"name":"Divider","sourcePath":"components/surfaces/Divider.jsx"},{"name":"Kbd","sourcePath":"components/surfaces/Kbd.jsx"},{"name":"PageHeader","sourcePath":"components/surfaces/PageHeader.jsx"}],"sourceHashes":{"components/brand/Brand.jsx":"8a001847ee40","components/brand/Icon.jsx":"41e389bd6c1a","components/buttons/Button.jsx":"ee040061f3b4","components/buttons/ThemeToggle.jsx":"473084634499","components/feedback/Badge.jsx":"52036ee347e3","components/feedback/Spinner.jsx":"f53b5b53f941","components/forms/Input.jsx":"93243bd3e01d","components/forms/Toggle.jsx":"5fdafb5047ac","components/surfaces/Card.jsx":"8d87a74c0722","components/surfaces/Divider.jsx":"1ef4328a31ad","components/surfaces/Kbd.jsx":"c74fc1e0844d","components/surfaces/PageHeader.jsx":"9d66d3d516db","ui_kits/dictate/App.jsx":"7a1316839b1d","ui_kits/dictate/HistoryScreen.jsx":"ab25dbea9cc2","ui_kits/dictate/LoginScreen.jsx":"e8dbd29f4573","ui_kits/dictate/RecordingBar.jsx":"ad6bd7f0530f","ui_kits/dictate/SettingsScreen.jsx":"e8e49f22c759","ui_kits/dictate/Sidebar.jsx":"c344c965683b","ui_kits/dictate/TranscriptScreen.jsx":"634de92e93ba","ui_kits/dictate/data.js":"7118273637a7"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.EximiumDesignSystem_b4169c = window.EximiumDesignSystem_b4169c || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/brand/Brand.jsx
try { (() => {
/**
 * Eximium Design System — Brand
 * The brand mark (4 stacked pills) + optional "Eximium [Product]" wordmark.
 */

function Brand({
  size = 18,
  markOnly = false,
  product = '',
  color
}) {
  const markH = size * 1.15;
  const markW = size;
  const fill = color || 'var(--ex-brand-green, #6DE2C0)';
  const mark = /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 369 422",
    width: markW,
    height: markH,
    "aria-hidden": true,
    style: {
      display: 'block',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "0",
    width: "368.99",
    height: "119.63",
    rx: "59.19",
    fill: fill
  }), /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "151.11",
    width: "238.54",
    height: "119.63",
    rx: "59.82",
    fill: fill
  }), /*#__PURE__*/React.createElement("rect", {
    x: "143.92",
    y: "302.23",
    width: "225.07",
    height: "119.63",
    rx: "59.82",
    fill: fill
  }), /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "302.23",
    width: "120.73",
    height: "119.63",
    rx: "59.82",
    fill: fill
  }));
  if (markOnly) return mark;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 9
    }
  }, mark, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: size,
      letterSpacing: '-0.01em',
      lineHeight: 1
    }
  }, /*#__PURE__*/React.createElement("b", {
    style: {
      fontWeight: 700
    }
  }, "Eximium"), product && /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 300,
      color: 'var(--ex-text-secondary, #999)'
    }
  }, ' ', product)));
}
Object.assign(__ds_scope, { Brand });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/Brand.jsx", error: String((e && e.message) || e) }); }

// components/brand/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Eximium Design System — Icon
 * Lucide-style icon set: 24px viewBox, stroke, fill:none, round caps/joins.
 */

function Icon({
  size = 20,
  strokeWidth = 1.7,
  children,
  ...props
}) {
  return /*#__PURE__*/React.createElement("svg", _extends({
    width: size,
    height: size,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: strokeWidth,
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, props), children);
}
const P = (d, extra) => /*#__PURE__*/React.createElement("path", _extends({
  d: d
}, extra));
const L = (x1, y1, x2, y2) => /*#__PURE__*/React.createElement("line", {
  x1: x1,
  y1: y1,
  x2: x2,
  y2: y2
});
const Ci = (cx, cy, r) => /*#__PURE__*/React.createElement("circle", {
  cx: cx,
  cy: cy,
  r: r
});
const R = (x, y, w, h, rx) => /*#__PURE__*/React.createElement("rect", {
  x: x,
  y: y,
  width: w,
  height: h,
  rx: rx
});
const Icons = {
  History: p => /*#__PURE__*/React.createElement(Icon, p, P("M3 3v5h5"), P("M3.05 13A9 9 0 1 0 6 5.3L3 8"), P("M12 7v5l4 2")),
  Layers: p => /*#__PURE__*/React.createElement(Icon, p, P("M12 2 2 7l10 5 10-5-10-5Z"), P("m2 12 10 5 10-5"), P("m2 17 10 5 10-5")),
  Book: p => /*#__PURE__*/React.createElement(Icon, p, P("M4 19.5A2.5 2.5 0 0 1 6.5 17H20"), P("M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2Z")),
  Settings: p => /*#__PURE__*/React.createElement(Icon, p, Ci(12, 12, 3), P("M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z")),
  User: p => /*#__PURE__*/React.createElement(Icon, p, P("M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"), Ci(12, 7, 4)),
  Help: p => /*#__PURE__*/React.createElement(Icon, p, Ci(12, 12, 10), P("M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"), L(12, 17, 12.01, 17)),
  Logout: p => /*#__PURE__*/React.createElement(Icon, p, P("M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"), P("m16 17 5-5-5-5"), L(21, 12, 9, 12)),
  Mic: p => /*#__PURE__*/React.createElement(Icon, p, R(9, 2, 6, 12, 3), P("M19 10v2a7 7 0 0 1-14 0v-2"), L(12, 19, 12, 22)),
  Stop: p => /*#__PURE__*/React.createElement(Icon, p, R(6, 6, 12, 12, 2)),
  X: p => /*#__PURE__*/React.createElement(Icon, p, P("M18 6 6 18"), P("m6 6 12 12")),
  Plus: p => /*#__PURE__*/React.createElement(Icon, p, L(12, 5, 12, 19), L(5, 12, 19, 12)),
  Search: p => /*#__PURE__*/React.createElement(Icon, p, Ci(11, 11, 8), P("m21 21-4.3-4.3")),
  Sparkle: p => /*#__PURE__*/React.createElement(Icon, p, P("M12 3l1.9 5.2L19 10l-5.1 1.8L12 17l-1.9-5.2L5 10l5.1-1.8L12 3Z")),
  Pencil: p => /*#__PURE__*/React.createElement(Icon, p, P("M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"), P("m15 5 4 4")),
  Trash: p => /*#__PURE__*/React.createElement(Icon, p, P("M3 6h18"), P("M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"), L(10, 11, 10, 17), L(14, 11, 14, 17)),
  ChevronRight: p => /*#__PURE__*/React.createElement(Icon, p, P("m9 18 6-6-6-6")),
  ChevronDown: p => /*#__PURE__*/React.createElement(Icon, p, P("m6 9 6 6 6-6")),
  ArrowLeft: p => /*#__PURE__*/React.createElement(Icon, p, L(19, 12, 5, 12), P("m12 19-7-7 7-7")),
  ArrowRight: p => /*#__PURE__*/React.createElement(Icon, p, L(5, 12, 19, 12), P("m12 5 7 7-7 7")),
  More: p => /*#__PURE__*/React.createElement(Icon, p, Ci(12, 5, 1), Ci(12, 12, 1), Ci(12, 19, 1)),
  Message: p => /*#__PURE__*/React.createElement(Icon, p, P("M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5Z")),
  File: p => /*#__PURE__*/React.createElement(Icon, p, P("M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z"), P("M14 2v6h6"), L(16, 13, 8, 13), L(16, 17, 8, 17), P("M10 9H8")),
  Clock: p => /*#__PURE__*/React.createElement(Icon, p, Ci(12, 12, 10), P("M12 6v6l4 2")),
  Check: p => /*#__PURE__*/React.createElement(Icon, p, P("M20 6 9 17l-5-5")),
  Copy: p => /*#__PURE__*/React.createElement(Icon, p, R(9, 9, 13, 13, 2), P("M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1")),
  Waveform: p => /*#__PURE__*/React.createElement(Icon, p, L(4, 10, 4, 14), L(8, 7, 8, 17), L(12, 4, 12, 20), L(16, 8, 16, 16), L(20, 11, 20, 13)),
  Lock: p => /*#__PURE__*/React.createElement(Icon, p, R(3, 11, 18, 11, 2), P("M7 11V7a5 5 0 0 1 10 0v4")),
  Mail: p => /*#__PURE__*/React.createElement(Icon, p, R(2, 4, 20, 16, 2), P("m22 7-10 5L2 7")),
  Filter: p => /*#__PURE__*/React.createElement(Icon, p, P("M22 3H2l8 9.46V19l4 2v-8.54L22 3Z")),
  Command: p => /*#__PURE__*/React.createElement(Icon, p, P("M15 6a3 3 0 1 0 3 3h-3V6Zm-6 0a3 3 0 1 1-3 3h3V6Zm0 12a3 3 0 1 0-3-3h3v3Zm6 0a3 3 0 1 1 3-3h-3v3Z")),
  Eye: p => /*#__PURE__*/React.createElement(Icon, p, P("M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"), Ci(12, 12, 3)),
  EyeOff: p => /*#__PURE__*/React.createElement(Icon, p, P("M9.9 4.24A9.12 9.12 0 0 1 12 4c6.5 0 10 7 10 7a13.2 13.2 0 0 1-1.67 2.68"), P("M6.61 6.61A13.5 13.5 0 0 0 2 12s3.5 7 10 7a9.7 9.7 0 0 0 5.39-1.61"), P("M14.12 14.12A3 3 0 1 1 9.88 9.88"), L(2, 2, 22, 22)),
  Refresh: p => /*#__PURE__*/React.createElement(Icon, p, P("M3 12a9 9 0 0 1 15-6.7L21 8"), P("M21 3v5h-5"), P("M21 12a9 9 0 0 1-15 6.7L3 16"), P("M3 21v-5h5")),
  Keyboard: p => /*#__PURE__*/React.createElement(Icon, p, R(2, 5, 20, 14, 3), L(6, 9, 6.01, 9), L(10, 9, 10.01, 9), L(14, 9, 14.01, 9), L(18, 9, 18.01, 9), L(6, 13, 6.01, 13), L(18, 13, 18.01, 13), L(9, 13, 15, 13)),
  Clipboard: p => /*#__PURE__*/React.createElement(Icon, p, R(8, 2, 8, 4, 1), P("M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2")),
  Volume: p => /*#__PURE__*/React.createElement(Icon, p, P("M11 5 6 9H2v6h4l5 4V5Z"), P("M15.5 8.5a5 5 0 0 1 0 7"), P("M19 5a9 9 0 0 1 0 14")),
  Home: p => /*#__PURE__*/React.createElement(Icon, p, P("M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"), P("M9 22V12h6v10")),
  Bell: p => /*#__PURE__*/React.createElement(Icon, p, P("M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"), P("M13.73 21a2 2 0 0 1-3.46 0")),
  Download: p => /*#__PURE__*/React.createElement(Icon, p, P("M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"), P("m7 10 5 5 5-5"), L(12, 15, 12, 3)),
  Upload: p => /*#__PURE__*/React.createElement(Icon, p, P("M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"), P("m17 8-5-5-5 5"), L(12, 3, 12, 15)),
  Tag: p => /*#__PURE__*/React.createElement(Icon, p, P("M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"), L(7, 7, 7.01, 7)),
  ExternalLink: p => /*#__PURE__*/React.createElement(Icon, p, P("M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"), P("M15 3h6v6"), L(10, 14, 21, 3))
};
Object.assign(__ds_scope, { Icon, Icons });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/Icon.jsx", error: String((e && e.message) || e) }); }

// components/buttons/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Eximium Design System — Button
 * Pill-shaped button. Variants: primary, ghost, subtle, danger. Sizes: sm, md, lg, icon.
 */
const {
  useState,
  forwardRef
} = React;
const btnBase = {
  display: 'inline-flex',
  alignItems: 'center',
  justifyContent: 'center',
  gap: 8,
  borderRadius: 9999,
  fontFamily: 'inherit',
  fontWeight: 700,
  fontSize: 13,
  cursor: 'pointer',
  border: '1px solid transparent',
  transition: 'background 0.15s ease, box-shadow 0.2s ease, border-color 0.2s ease, color 0.15s ease',
  whiteSpace: 'nowrap',
  textDecoration: 'none'
};
const btnSizes = {
  sm: {
    padding: '6px 14px',
    fontSize: 12
  },
  md: {
    padding: '10px 20px',
    fontSize: 13
  },
  lg: {
    padding: '12px 28px',
    fontSize: 15
  },
  icon: {
    width: 36,
    height: 36,
    padding: 0
  }
};
const Button = forwardRef(function Button({
  variant = 'primary',
  size = 'md',
  icon: IconCmp,
  children,
  disabled,
  style,
  ...props
}, ref) {
  const [hovered, setHovered] = useState(false);
  const variants = {
    primary: {
      base: {
        background: '#6DE2C0',
        color: '#04201a',
        borderColor: '#6DE2C0'
      },
      hover: {
        background: '#AEF7E4',
        boxShadow: '0 0 12px rgba(109,226,192,0.20)'
      }
    },
    ghost: {
      base: {
        background: 'transparent',
        color: 'var(--ex-text-accent, #6DE2C0)',
        borderColor: 'rgba(109,226,192,0.40)'
      },
      hover: {
        background: 'rgba(109,226,192,0.08)',
        boxShadow: '0 0 12px rgba(109,226,192,0.15)'
      }
    },
    subtle: {
      base: {
        background: 'var(--ex-surface-2, #1E1E1E)',
        color: 'var(--ex-text-primary, #fff)',
        borderColor: 'var(--ex-border, #2A2A2A)'
      },
      hover: {
        background: 'var(--ex-surface-3, #2A2A2A)'
      }
    },
    danger: {
      base: {
        background: 'transparent',
        color: '#FF6B6B',
        borderColor: 'rgba(255,107,107,0.35)'
      },
      hover: {
        background: 'rgba(255,107,107,0.10)'
      }
    }
  };
  const v = variants[variant] || variants.primary;
  const s = btnSizes[size] || btnSizes.md;
  return /*#__PURE__*/React.createElement("button", _extends({
    ref: ref,
    disabled: disabled,
    onMouseEnter: () => setHovered(true),
    onMouseLeave: () => setHovered(false),
    style: {
      ...btnBase,
      ...s,
      ...v.base,
      ...(hovered && !disabled ? v.hover : {}),
      ...(disabled ? {
        opacity: 0.45,
        cursor: 'not-allowed'
      } : {}),
      ...style
    }
  }, props), IconCmp && /*#__PURE__*/React.createElement(IconCmp, {
    size: size === 'sm' ? 14 : size === 'lg' ? 18 : 16
  }), children);
});
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/buttons/Button.jsx", error: String((e && e.message) || e) }); }

// components/buttons/ThemeToggle.jsx
try { (() => {
/**
 * Eximium Design System — ThemeToggle
 * Minimal ghost icon-button that flips .dark / .light on <html> and persists it.
 */
const {
  useState
} = React;
function ThemeToggle({
  style
}) {
  const [dark, setDark] = useState(() => typeof document !== 'undefined' && document.documentElement.classList.contains('dark'));
  function toggle() {
    const next = !dark;
    setDark(next);
    document.documentElement.classList.toggle('dark', next);
    document.documentElement.classList.toggle('light', !next);
    try {
      localStorage.setItem('eximium-theme', next ? 'dark' : 'light');
    } catch (e) {}
  }
  return /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "ghost",
    size: "icon",
    onClick: toggle,
    "aria-label": "Alternar tema",
    style: style
  }, dark ? /*#__PURE__*/React.createElement(__ds_scope.Icons.Eye, {
    size: 16
  }) : /*#__PURE__*/React.createElement(__ds_scope.Icons.EyeOff, {
    size: 16
  }));
}
Object.assign(__ds_scope, { ThemeToggle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/buttons/ThemeToggle.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Eximium Design System — Badge / Status Pill
 * Uppercase pill; success/info/error/warning/brand/default.
 */

const badgeVariants = {
  success: {
    bg: 'rgba(109,226,192,0.12)',
    color: 'var(--ex-color-success, #6DE2C0)'
  },
  info: {
    bg: 'rgba(124,130,214,0.12)',
    color: 'var(--ex-color-info,    #7C82D6)'
  },
  error: {
    bg: 'rgba(255,107,107,0.12)',
    color: 'var(--ex-color-error,   #FF6B6B)'
  },
  warning: {
    bg: 'rgba(255,196,87,0.12)',
    color: 'var(--ex-color-warning, #FFC457)'
  },
  default: {
    bg: 'var(--ex-surface-3, #2A2A2A)',
    color: 'var(--ex-text-secondary, #999)'
  },
  brand: {
    bg: 'rgba(109,226,192,0.12)',
    color: 'var(--ex-brand-green, #6DE2C0)'
  }
};
function Badge({
  variant = 'default',
  children,
  style,
  ...props
}) {
  const v = badgeVariants[variant] || badgeVariants.default;
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      padding: '3px 10px',
      borderRadius: 9999,
      fontSize: 11,
      fontWeight: 700,
      textTransform: 'uppercase',
      letterSpacing: '0.06em',
      background: v.bg,
      color: v.color,
      whiteSpace: 'nowrap',
      ...style
    }
  }, props), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Badge.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Spinner.jsx
try { (() => {
/**
 * Eximium Design System — Spinner
 * Brand-green indeterminate loading ring.
 */

function Spinner({
  size = 20,
  color = 'var(--ex-brand-green, #6DE2C0)',
  style
}) {
  return /*#__PURE__*/React.createElement("svg", {
    width: size,
    height: size,
    viewBox: "0 0 24 24",
    fill: "none",
    style: {
      animation: 'ex-spin 0.8s linear infinite',
      ...style
    }
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "12",
    cy: "12",
    r: "10",
    stroke: color,
    strokeWidth: "2",
    strokeOpacity: "0.25"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M12 2a10 10 0 0 1 10 10",
    stroke: color,
    strokeWidth: "2",
    strokeLinecap: "round"
  }));
}
Object.assign(__ds_scope, { Spinner });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Spinner.jsx", error: String((e && e.message) || e) }); }

// components/forms/Input.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Eximium Design System — Input
 * Text field with optional label, leading icon, hint and error states.
 */
const {
  useState,
  forwardRef
} = React;
const Input = forwardRef(function Input({
  label,
  error,
  icon: IconCmp,
  hint,
  style,
  containerStyle,
  ...props
}, ref) {
  const [focused, setFocused] = useState(false);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 6,
      ...containerStyle
    }
  }, label && /*#__PURE__*/React.createElement("label", {
    style: {
      fontSize: 11,
      fontWeight: 700,
      textTransform: 'uppercase',
      letterSpacing: '0.08em',
      color: 'var(--ex-text-secondary, #999)'
    }
  }, label), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      display: 'flex',
      alignItems: 'center'
    }
  }, IconCmp && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 12,
      color: focused ? 'var(--ex-brand-green, #6DE2C0)' : 'var(--ex-text-muted, #666)',
      transition: 'color 0.15s',
      pointerEvents: 'none',
      display: 'flex'
    }
  }, /*#__PURE__*/React.createElement(IconCmp, {
    size: 16
  })), /*#__PURE__*/React.createElement("input", _extends({
    ref: ref,
    onFocus: () => setFocused(true),
    onBlur: () => setFocused(false),
    style: {
      width: '100%',
      padding: IconCmp ? '10px 12px 10px 38px' : '10px 14px',
      background: 'var(--ex-surface-2, #1E1E1E)',
      border: `1px solid ${error ? '#FF6B6B' : focused ? 'var(--ex-brand-green, #6DE2C0)' : 'var(--ex-border, #2A2A2A)'}`,
      borderRadius: 12,
      color: 'var(--ex-text-primary, #fff)',
      fontSize: 13,
      fontFamily: 'inherit',
      outline: 'none',
      boxShadow: focused ? error ? '0 0 0 3px rgba(255,107,107,0.12)' : '0 0 0 3px rgba(109,226,192,0.12)' : 'none',
      transition: 'border-color 0.15s, box-shadow 0.15s',
      ...style
    }
  }, props))), (error || hint) && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      color: error ? '#FF6B6B' : 'var(--ex-text-muted, #666)'
    }
  }, error || hint));
});
Object.assign(__ds_scope, { Input });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Input.jsx", error: String((e && e.message) || e) }); }

// components/forms/Toggle.jsx
try { (() => {
/**
 * Eximium Design System — Toggle
 * Pill switch; green track + glow when on, surface-3 when off.
 */

function Toggle({
  checked,
  onChange,
  label,
  disabled,
  style
}) {
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      cursor: disabled ? 'not-allowed' : 'pointer',
      opacity: disabled ? 0.5 : 1,
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    onClick: disabled ? undefined : () => onChange?.(!checked),
    style: {
      width: 42,
      height: 24,
      borderRadius: 9999,
      padding: 3,
      display: 'inline-flex',
      flexShrink: 0,
      background: checked ? '#6DE2C0' : 'var(--ex-surface-3, #2A2A2A)',
      boxShadow: checked ? '0 0 16px rgba(109,226,192,0.35)' : 'none',
      transition: 'background 0.2s, box-shadow 0.2s'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 18,
      height: 18,
      borderRadius: 9999,
      background: checked ? '#04201a' : '#888',
      transform: checked ? 'translateX(18px)' : 'none',
      transition: 'transform 0.2s, background 0.2s'
    }
  })), label && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: 'var(--ex-text-primary, #fff)',
      userSelect: 'none'
    }
  }, label));
}
Object.assign(__ds_scope, { Toggle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Toggle.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Eximium Design System — Card
 * Surface-1 container; radius-lg, border, card shadow. Optional hover accent.
 */
const {
  useState
} = React;
function Card({
  children,
  hoverable = false,
  padding = 'md',
  style,
  ...props
}) {
  const [hovered, setHovered] = useState(false);
  const paddings = {
    sm: 12,
    md: 20,
    lg: 28
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    onMouseEnter: hoverable ? () => setHovered(true) : undefined,
    onMouseLeave: hoverable ? () => setHovered(false) : undefined,
    style: {
      background: 'var(--ex-surface-1, #141414)',
      border: `1px solid ${hovered ? 'var(--ex-border-accent, rgba(109,226,192,0.25))' : 'var(--ex-border, #2A2A2A)'}`,
      borderRadius: 20,
      boxShadow: 'var(--ex-shadow-card, 0 2px 12px rgba(0,0,0,0.4))',
      padding: paddings[padding] ?? padding,
      transition: 'border-color 0.2s ease, box-shadow 0.2s ease',
      ...(hovered ? {
        boxShadow: '0 4px 24px rgba(0,0,0,0.5)'
      } : {}),
      ...style
    }
  }, props), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/Card.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/Divider.jsx
try { (() => {
/**
 * Eximium Design System — Divider
 * Hairline rule, optionally with a centered uppercase label.
 */

function Divider({
  label,
  style
}) {
  if (!label) {
    return /*#__PURE__*/React.createElement("hr", {
      style: {
        border: 'none',
        borderTop: '1px solid var(--ex-border, #2A2A2A)',
        margin: '8px 0',
        ...style
      }
    });
  }
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      margin: '8px 0',
      ...style
    }
  }, /*#__PURE__*/React.createElement("hr", {
    style: {
      flex: 1,
      border: 'none',
      borderTop: '1px solid var(--ex-border, #2A2A2A)'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      fontWeight: 700,
      textTransform: 'uppercase',
      letterSpacing: '0.08em',
      color: 'var(--ex-text-muted, #666)',
      whiteSpace: 'nowrap'
    }
  }, label), /*#__PURE__*/React.createElement("hr", {
    style: {
      flex: 1,
      border: 'none',
      borderTop: '1px solid var(--ex-border, #2A2A2A)'
    }
  }));
}
Object.assign(__ds_scope, { Divider });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/Divider.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/Kbd.jsx
try { (() => {
/**
 * Eximium Design System — Kbd
 * Keyboard key cap; mono, surface-0, thick bottom border.
 */

function Kbd({
  children,
  style
}) {
  return /*#__PURE__*/React.createElement("kbd", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      minWidth: 26,
      height: 26,
      padding: '0 8px',
      background: 'var(--ex-surface-0, #0A0A0A)',
      border: '1px solid var(--ex-border, #2A2A2A)',
      borderBottomWidth: 2,
      borderRadius: 7,
      fontSize: 12,
      fontFamily: 'var(--ex-font-mono)',
      color: 'var(--ex-text-primary, #fff)',
      fontWeight: 500,
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { Kbd });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/Kbd.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/PageHeader.jsx
try { (() => {
/**
 * Eximium Design System — PageHeader
 * Section title + optional subtitle, with a right-aligned action slot.
 */

function PageHeader({
  title,
  subtitle,
  right,
  style
}) {
  return /*#__PURE__*/React.createElement("header", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'flex-end',
      gap: 20,
      marginBottom: 28,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h1", {
    style: {
      margin: 0,
      fontSize: 28,
      fontWeight: 700,
      letterSpacing: '-0.02em',
      color: 'var(--ex-text-primary, #fff)'
    }
  }, title), subtitle && /*#__PURE__*/React.createElement("p", {
    style: {
      margin: '6px 0 0',
      fontSize: 14,
      color: 'var(--ex-text-secondary, #999)'
    }
  }, subtitle)), right);
}
Object.assign(__ds_scope, { PageHeader });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/PageHeader.jsx", error: String((e && e.message) || e) }); }

// ui_kits/dictate/App.jsx
try { (() => {
/* Eximium Dictate — App shell (desktop window + state machine) */
const EX_NS = window.EximiumDesignSystem_b4169c;
const appStyles = {
  window: {
    position: 'absolute',
    inset: 0,
    display: 'flex',
    flexDirection: 'column',
    background: 'var(--ex-surface-0)',
    overflow: 'hidden'
  },
  titlebar: {
    height: 36,
    flexShrink: 0,
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    padding: '0 14px',
    borderBottom: '1px solid var(--ex-border)',
    background: 'var(--ex-surface-0)',
    WebkitAppRegion: 'drag'
  },
  light: c => ({
    width: 12,
    height: 12,
    borderRadius: '50%',
    background: c
  }),
  titleText: {
    marginLeft: 8,
    fontSize: 12,
    color: 'var(--ex-text-muted)',
    fontWeight: 600
  },
  body: {
    flex: 1,
    display: 'flex',
    minHeight: 0
  },
  main: {
    flex: 1,
    display: 'flex',
    flexDirection: 'column',
    minWidth: 0,
    position: 'relative'
  }
};
function App() {
  const {
    transcripts,
    folders
  } = window.DictateData;
  const [authed, setAuthed] = React.useState(false);
  const [view, setView] = React.useState('history');
  const [openId, setOpenId] = React.useState(null);
  const [query, setQuery] = React.useState('');
  const [recording, setRecording] = React.useState(null); // {seconds}
  const [list, setList] = React.useState(transcripts);
  React.useEffect(() => {
    if (!recording) return;
    const id = setInterval(() => setRecording(r => r ? {
      seconds: r.seconds + 1
    } : r), 1000);
    return () => clearInterval(id);
  }, [!!recording]);
  function startRec() {
    setOpenId(null);
    setRecording({
      seconds: 0
    });
  }
  function stopRec() {
    const secs = recording ? recording.seconds : 0;
    setRecording(null);
    const mm = String(Math.floor(secs / 60)).padStart(2, '0');
    const ss = String(secs % 60).padStart(2, '0');
    const fresh = {
      id: 'n' + Date.now(),
      title: 'Nova gravação',
      folder: 'Trabalho',
      duration: `${mm}:${ss}`,
      date: 'Agora',
      words: Math.max(1, secs * 3),
      status: 'done',
      starred: false,
      preview: 'Transcrição pronta — toque para abrir e revisar o texto completo.',
      segments: [{
        t: '00:00',
        s: 'Esta é uma gravação de demonstração criada agora pelo Eximium Dictate.'
      }, {
        t: '00:06',
        s: 'No produto real, o áudio é transcrito em tempo real conforme você fala.'
      }]
    };
    setList(l => [fresh, ...l]);
    setView('history');
    setOpenId(fresh.id);
  }
  const openItem = list.find(t => t.id === openId) || null;
  let listTitle = 'Histórico';
  let listItems = list;
  if (view.startsWith('folder:')) {
    const f = view.slice(7);
    listTitle = f === 'Todas' ? 'Todas' : f;
    listItems = f === 'Todas' ? list : list.filter(t => t.folder === f);
  } else if (view === 'library') {
    listTitle = 'Biblioteca';
  }
  if (!authed) {
    return /*#__PURE__*/React.createElement("div", {
      style: appStyles.window
    }, /*#__PURE__*/React.createElement("div", {
      style: appStyles.titlebar
    }, /*#__PURE__*/React.createElement("span", {
      style: appStyles.light('#FF6B6B')
    }), /*#__PURE__*/React.createElement("span", {
      style: appStyles.light('#FFC457')
    }), /*#__PURE__*/React.createElement("span", {
      style: appStyles.light('#6DE2C0')
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        position: 'relative'
      }
    }, /*#__PURE__*/React.createElement(LoginScreen, {
      onLogin: () => setAuthed(true)
    })));
  }
  return /*#__PURE__*/React.createElement("div", {
    style: appStyles.window
  }, /*#__PURE__*/React.createElement("div", {
    style: appStyles.titlebar
  }, /*#__PURE__*/React.createElement("span", {
    style: appStyles.light('#FF6B6B')
  }), /*#__PURE__*/React.createElement("span", {
    style: appStyles.light('#FFC457')
  }), /*#__PURE__*/React.createElement("span", {
    style: appStyles.light('#6DE2C0')
  }), /*#__PURE__*/React.createElement("span", {
    style: appStyles.titleText
  }, "Eximium Dictate")), /*#__PURE__*/React.createElement("div", {
    style: appStyles.body
  }, /*#__PURE__*/React.createElement(Sidebar, {
    folders: folders,
    current: view,
    settingsActive: view === 'settings',
    onSelect: v => {
      setView(v);
      setOpenId(null);
    },
    onSettings: () => {
      setView('settings');
      setOpenId(null);
    },
    onNew: startRec
  }), /*#__PURE__*/React.createElement("div", {
    style: appStyles.main
  }, view === 'settings' ? /*#__PURE__*/React.createElement(SettingsScreen, null) : openItem ? /*#__PURE__*/React.createElement(TranscriptScreen, {
    item: openItem,
    onBack: () => setOpenId(null)
  }) : /*#__PURE__*/React.createElement(HistoryScreen, {
    items: listItems,
    title: listTitle,
    query: query,
    setQuery: setQuery,
    onOpen: setOpenId,
    onNew: startRec
  }), recording && /*#__PURE__*/React.createElement(RecordingBar, {
    seconds: recording.seconds,
    onStop: stopRec,
    onCancel: () => setRecording(null)
  }))));
}
Object.assign(window, {
  App
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/dictate/App.jsx", error: String((e && e.message) || e) }); }

// ui_kits/dictate/HistoryScreen.jsx
try { (() => {
/* Eximium Dictate — History / list screen */
const {
  Icons: HS_Icons,
  Button: HS_Button,
  Input: HS_Input,
  Badge: HS_Badge,
  PageHeader: HS_PageHeader
} = window.EximiumDesignSystem_b4169c;
const historyStyles = {
  scroll: {
    flex: 1,
    overflowY: 'auto',
    padding: '28px 32px 40px'
  },
  toolbar: {
    display: 'flex',
    gap: 10,
    alignItems: 'center',
    marginBottom: 22
  },
  search: {
    flex: 1,
    maxWidth: 360
  },
  list: {
    display: 'flex',
    flexDirection: 'column',
    gap: 10
  },
  row: active => ({
    display: 'flex',
    alignItems: 'center',
    gap: 16,
    padding: '14px 16px',
    borderRadius: 14,
    cursor: 'pointer',
    background: 'var(--ex-surface-1)',
    border: '1px solid ' + (active ? 'var(--ex-border-accent)' : 'var(--ex-border)'),
    boxShadow: 'var(--ex-shadow-card)',
    transition: 'border-color .2s, transform .1s'
  }),
  play: {
    width: 40,
    height: 40,
    borderRadius: 9999,
    flexShrink: 0,
    display: 'grid',
    placeItems: 'center',
    background: 'rgba(109,226,192,0.12)',
    color: 'var(--ex-text-accent)'
  },
  mid: {
    flex: 1,
    minWidth: 0
  },
  titleRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 8
  },
  title: {
    fontSize: 15,
    fontWeight: 700,
    color: 'var(--ex-text-primary)',
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis'
  },
  preview: {
    fontSize: 13,
    color: 'var(--ex-text-secondary)',
    marginTop: 3,
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis'
  },
  meta: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-end',
    gap: 6,
    flexShrink: 0
  },
  metaTime: {
    fontFamily: 'var(--ex-font-mono)',
    fontSize: 12,
    color: 'var(--ex-text-secondary)'
  },
  metaDate: {
    fontSize: 11,
    color: 'var(--ex-text-muted)'
  }
};
function HistoryScreen({
  items,
  title,
  onOpen,
  onNew,
  query,
  setQuery
}) {
  const filtered = items.filter(t => t.title.toLowerCase().includes(query.toLowerCase()));
  return /*#__PURE__*/React.createElement("div", {
    style: historyStyles.scroll
  }, /*#__PURE__*/React.createElement(HS_PageHeader, {
    title: title,
    subtitle: `${items.length} transcrições`,
    right: /*#__PURE__*/React.createElement(HS_Button, {
      icon: HS_Icons.Mic,
      onClick: onNew
    }, "Nova grava\xE7\xE3o")
  }), /*#__PURE__*/React.createElement("div", {
    style: historyStyles.toolbar
  }, /*#__PURE__*/React.createElement("div", {
    style: historyStyles.search
  }, /*#__PURE__*/React.createElement(HS_Input, {
    icon: HS_Icons.Search,
    placeholder: "Buscar transcri\xE7\xF5es\u2026",
    value: query,
    onChange: e => setQuery(e.target.value)
  })), /*#__PURE__*/React.createElement(HS_Button, {
    variant: "subtle",
    size: "sm",
    icon: HS_Icons.Filter
  }, "Filtros"), /*#__PURE__*/React.createElement(HS_Button, {
    variant: "subtle",
    size: "sm",
    icon: HS_Icons.ArrowDown ? HS_Icons.ArrowDown : HS_Icons.ChevronDown
  }, "Recentes")), /*#__PURE__*/React.createElement("div", {
    style: historyStyles.list
  }, filtered.map(t => /*#__PURE__*/React.createElement("div", {
    key: t.id,
    style: historyStyles.row(false),
    onClick: () => t.status === 'done' && onOpen(t.id),
    onMouseEnter: e => {
      e.currentTarget.style.borderColor = 'var(--ex-border-accent)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.borderColor = 'var(--ex-border)';
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: historyStyles.play
  }, t.status === 'processing' ? /*#__PURE__*/React.createElement(HS_Icons.Refresh, {
    size: 18
  }) : /*#__PURE__*/React.createElement(HS_Icons.Waveform, {
    size: 18
  })), /*#__PURE__*/React.createElement("div", {
    style: historyStyles.mid
  }, /*#__PURE__*/React.createElement("div", {
    style: historyStyles.titleRow
  }, /*#__PURE__*/React.createElement("span", {
    style: historyStyles.title
  }, t.title), t.starred && /*#__PURE__*/React.createElement(HS_Icons.Sparkle, {
    size: 14,
    style: {
      color: 'var(--ex-brand-lavender)'
    }
  }), t.status === 'processing' ? /*#__PURE__*/React.createElement(HS_Badge, {
    variant: "info"
  }, "\u27F3 Processando") : /*#__PURE__*/React.createElement(HS_Badge, {
    variant: "default"
  }, t.folder)), /*#__PURE__*/React.createElement("div", {
    style: historyStyles.preview
  }, t.preview)), /*#__PURE__*/React.createElement("div", {
    style: historyStyles.meta
  }, /*#__PURE__*/React.createElement("span", {
    style: historyStyles.metaTime
  }, t.duration), /*#__PURE__*/React.createElement("span", {
    style: historyStyles.metaDate
  }, t.date))))));
}
Object.assign(window, {
  HistoryScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/dictate/HistoryScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/dictate/LoginScreen.jsx
try { (() => {
/* Eximium Dictate — Login screen */
const {
  Brand: LG_Brand,
  Icons: LG_Icons,
  Input: LG_Input,
  Button: LG_Button,
  Divider: LG_Divider
} = window.EximiumDesignSystem_b4169c;
const loginStyles = {
  wrap: {
    position: 'absolute',
    inset: 0,
    display: 'grid',
    placeItems: 'center',
    background: 'var(--ex-surface-0)',
    backgroundImage: 'radial-gradient(1200px 700px at 75% -10%, rgba(109,226,192,0.07), transparent 60%), radial-gradient(900px 600px at 10% 110%, rgba(124,130,214,0.05), transparent 55%)'
  },
  card: {
    width: 360,
    background: 'var(--ex-surface-1)',
    border: '1px solid var(--ex-border)',
    borderRadius: 20,
    boxShadow: 'var(--ex-shadow-float)',
    padding: 32
  },
  title: {
    fontSize: 22,
    fontWeight: 700,
    letterSpacing: '-0.02em',
    margin: '22px 0 4px',
    color: 'var(--ex-text-primary)'
  },
  sub: {
    fontSize: 13,
    color: 'var(--ex-text-secondary)',
    margin: '0 0 24px'
  },
  fields: {
    display: 'flex',
    flexDirection: 'column',
    gap: 14,
    marginBottom: 18
  },
  primary: {
    width: '100%',
    justifyContent: 'center'
  },
  sso: {
    width: '100%',
    justifyContent: 'center'
  },
  foot: {
    fontSize: 12,
    color: 'var(--ex-text-muted)',
    textAlign: 'center',
    marginTop: 18
  },
  link: {
    color: 'var(--ex-text-accent)',
    textDecoration: 'none',
    fontWeight: 600
  }
};
function LoginScreen({
  onLogin
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: loginStyles.wrap
  }, /*#__PURE__*/React.createElement("div", {
    style: loginStyles.card,
    className: "ex-fade-up"
  }, /*#__PURE__*/React.createElement(LG_Brand, {
    size: 22,
    product: "Dictate"
  }), /*#__PURE__*/React.createElement("h1", {
    style: loginStyles.title
  }, "Bem-vindo de volta"), /*#__PURE__*/React.createElement("p", {
    style: loginStyles.sub
  }, "Entre para acessar suas transcri\xE7\xF5es."), /*#__PURE__*/React.createElement("div", {
    style: loginStyles.fields
  }, /*#__PURE__*/React.createElement(LG_Input, {
    label: "Email",
    placeholder: "voce@eximium.com",
    icon: LG_Icons.Mail,
    defaultValue: "joao@eximium.com"
  }), /*#__PURE__*/React.createElement(LG_Input, {
    label: "Senha",
    type: "password",
    placeholder: "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022",
    icon: LG_Icons.Lock,
    defaultValue: "dictate"
  })), /*#__PURE__*/React.createElement(LG_Button, {
    variant: "primary",
    style: loginStyles.primary,
    onClick: onLogin
  }, "Entrar"), /*#__PURE__*/React.createElement(LG_Divider, {
    label: "ou"
  }), /*#__PURE__*/React.createElement(LG_Button, {
    variant: "subtle",
    style: loginStyles.sso,
    icon: LG_Icons.Command,
    onClick: onLogin
  }, "Continuar com SSO"), /*#__PURE__*/React.createElement("p", {
    style: loginStyles.foot
  }, "N\xE3o tem conta? ", /*#__PURE__*/React.createElement("a", {
    href: "#",
    style: loginStyles.link,
    onClick: e => {
      e.preventDefault();
      onLogin();
    }
  }, "Criar conta"))));
}
Object.assign(window, {
  LoginScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/dictate/LoginScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/dictate/RecordingBar.jsx
try { (() => {
/* Eximium Dictate — Floating recording bar (always-dark signature element) */
const {
  Icons: RB_Icons
} = window.EximiumDesignSystem_b4169c;
const recStyles = {
  wrap: {
    position: 'absolute',
    left: '50%',
    bottom: 28,
    transform: 'translateX(-50%)',
    zIndex: 50
  },
  bar: {
    display: 'flex',
    alignItems: 'center',
    gap: 14,
    padding: '12px 18px',
    background: 'rgba(14,14,14,0.92)',
    backdropFilter: 'blur(20px)',
    WebkitBackdropFilter: 'blur(20px)',
    borderRadius: 9999,
    border: '1px solid rgba(109,226,192,0.50)',
    boxShadow: '0 8px 32px rgba(0,0,0,0.6), 0 0 20px rgba(109,226,192,0.30)',
    animation: 'ex-bar-pulse 2s ease-in-out infinite'
  },
  dot: {
    width: 9,
    height: 9,
    borderRadius: '50%',
    background: '#6DE2C0',
    boxShadow: '0 0 10px #6DE2C0',
    flexShrink: 0
  },
  label: {
    color: '#fff',
    fontSize: 13,
    fontWeight: 700
  },
  wave: {
    display: 'flex',
    alignItems: 'center',
    gap: 3,
    height: 24
  },
  barI: {
    width: 3,
    background: '#6DE2C0',
    borderRadius: 2
  },
  time: {
    color: '#6DE2C0',
    fontFamily: 'var(--ex-font-mono)',
    fontSize: 13,
    minWidth: 42
  },
  stop: {
    width: 34,
    height: 34,
    borderRadius: 9999,
    marginLeft: 4,
    cursor: 'pointer',
    display: 'grid',
    placeItems: 'center',
    flexShrink: 0,
    background: 'rgba(255,107,107,0.16)',
    color: '#FF6B6B',
    border: '1px solid rgba(255,107,107,0.35)'
  },
  cancel: {
    width: 34,
    height: 34,
    borderRadius: 9999,
    cursor: 'pointer',
    display: 'grid',
    placeItems: 'center',
    flexShrink: 0,
    background: 'transparent',
    color: '#999',
    border: '1px solid #2A2A2A'
  }
};
function RecordingBar({
  seconds,
  onStop,
  onCancel
}) {
  const heights = [9, 16, 22, 13, 19, 8, 14, 20, 11];
  const mm = String(Math.floor(seconds / 60)).padStart(2, '0');
  const ss = String(seconds % 60).padStart(2, '0');
  return /*#__PURE__*/React.createElement("div", {
    style: recStyles.wrap,
    className: "ex-fade-up"
  }, /*#__PURE__*/React.createElement("div", {
    style: recStyles.bar,
    className: "ex-always-dark"
  }, /*#__PURE__*/React.createElement("span", {
    style: recStyles.dot
  }), /*#__PURE__*/React.createElement("span", {
    style: recStyles.label
  }, "Gravando"), /*#__PURE__*/React.createElement("div", {
    style: recStyles.wave
  }, heights.map((h, i) => /*#__PURE__*/React.createElement("span", {
    key: i,
    style: {
      ...recStyles.barI,
      height: h,
      opacity: 0.5 + h / 44
    }
  }))), /*#__PURE__*/React.createElement("span", {
    style: recStyles.time
  }, mm, ":", ss), /*#__PURE__*/React.createElement("div", {
    style: recStyles.stop,
    onClick: onStop,
    title: "Parar e transcrever"
  }, /*#__PURE__*/React.createElement(RB_Icons.Stop, {
    size: 15
  })), /*#__PURE__*/React.createElement("div", {
    style: recStyles.cancel,
    onClick: onCancel,
    title: "Cancelar"
  }, /*#__PURE__*/React.createElement(RB_Icons.X, {
    size: 15
  }))));
}
Object.assign(window, {
  RecordingBar
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/dictate/RecordingBar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/dictate/SettingsScreen.jsx
try { (() => {
/* Eximium Dictate — Settings screen */
const {
  Icons: ST_Icons,
  Toggle: ST_Toggle,
  Input: ST_Input,
  Kbd: ST_Kbd,
  Divider: ST_Divider,
  PageHeader: ST_PageHeader,
  ThemeToggle: ST_ThemeToggle
} = window.EximiumDesignSystem_b4169c;
const settingsStyles = {
  scroll: {
    flex: 1,
    overflowY: 'auto',
    padding: '28px 32px 48px'
  },
  group: {
    background: 'var(--ex-surface-1)',
    border: '1px solid var(--ex-border)',
    borderRadius: 16,
    boxShadow: 'var(--ex-shadow-card)',
    padding: '6px 20px',
    marginBottom: 20,
    maxWidth: 640
  },
  groupTitle: {
    fontSize: 11,
    fontWeight: 700,
    textTransform: 'uppercase',
    letterSpacing: '0.08em',
    color: 'var(--ex-text-muted)',
    margin: '20px 0 6px',
    maxWidth: 640
  },
  row: {
    display: 'flex',
    alignItems: 'center',
    gap: 16,
    padding: '16px 0',
    borderBottom: '1px solid var(--ex-border)'
  },
  rowLast: {
    borderBottom: 'none'
  },
  label: {
    fontSize: 14,
    fontWeight: 600,
    color: 'var(--ex-text-primary)'
  },
  desc: {
    fontSize: 12,
    color: 'var(--ex-text-secondary)',
    marginTop: 2
  },
  spacer: {
    marginLeft: 'auto'
  }
};
function SettingRow({
  icon: Ic,
  label,
  desc,
  control,
  last
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      ...settingsStyles.row,
      ...(last ? settingsStyles.rowLast : {})
    }
  }, Ic && /*#__PURE__*/React.createElement(Ic, {
    size: 18,
    style: {
      color: 'var(--ex-text-muted)',
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: settingsStyles.label
  }, label), desc && /*#__PURE__*/React.createElement("div", {
    style: settingsStyles.desc
  }, desc)), /*#__PURE__*/React.createElement("div", {
    style: settingsStyles.spacer
  }, control));
}
function SettingsScreen() {
  const [autoPunct, setAutoPunct] = React.useState(true);
  const [keepAudio, setKeepAudio] = React.useState(true);
  const [cloud, setCloud] = React.useState(false);
  const [launch, setLaunch] = React.useState(true);
  return /*#__PURE__*/React.createElement("div", {
    style: settingsStyles.scroll
  }, /*#__PURE__*/React.createElement(ST_PageHeader, {
    title: "Configura\xE7\xF5es",
    subtitle: "Prefer\xEAncias do Eximium Dictate"
  }), /*#__PURE__*/React.createElement("div", {
    style: settingsStyles.groupTitle
  }, "Transcri\xE7\xE3o"), /*#__PURE__*/React.createElement("div", {
    style: settingsStyles.group
  }, /*#__PURE__*/React.createElement(SettingRow, {
    icon: ST_Icons.Sparkle,
    label: "Auto-pontua\xE7\xE3o",
    desc: "Adiciona v\xEDrgulas e pontos automaticamente.",
    control: /*#__PURE__*/React.createElement(ST_Toggle, {
      checked: autoPunct,
      onChange: setAutoPunct
    })
  }), /*#__PURE__*/React.createElement(SettingRow, {
    icon: ST_Icons.Volume,
    label: "Manter \xE1udio original",
    desc: "Guarda o arquivo de \xE1udio junto com a transcri\xE7\xE3o.",
    control: /*#__PURE__*/React.createElement(ST_Toggle, {
      checked: keepAudio,
      onChange: setKeepAudio
    })
  }), /*#__PURE__*/React.createElement(SettingRow, {
    icon: ST_Icons.Book,
    label: "Idioma padr\xE3o",
    desc: "Idioma usado para novas grava\xE7\xF5es.",
    control: /*#__PURE__*/React.createElement("div", {
      style: {
        width: 160
      }
    }, /*#__PURE__*/React.createElement(ST_Input, {
      defaultValue: "Portugu\xEAs (BR)"
    })),
    last: true
  })), /*#__PURE__*/React.createElement("div", {
    style: settingsStyles.groupTitle
  }, "Aplicativo"), /*#__PURE__*/React.createElement("div", {
    style: settingsStyles.group
  }, /*#__PURE__*/React.createElement(SettingRow, {
    icon: ST_Icons.Upload,
    label: "Sincronizar na nuvem",
    desc: "Dispon\xEDvel no plano Pro.",
    control: /*#__PURE__*/React.createElement(ST_Toggle, {
      checked: cloud,
      onChange: setCloud
    })
  }), /*#__PURE__*/React.createElement(SettingRow, {
    icon: ST_Icons.Refresh,
    label: "Abrir ao iniciar o sistema",
    control: /*#__PURE__*/React.createElement(ST_Toggle, {
      checked: launch,
      onChange: setLaunch
    })
  }), /*#__PURE__*/React.createElement(SettingRow, {
    icon: ST_Icons.Eye,
    label: "Tema",
    desc: "Claro, escuro ou conforme o sistema.",
    control: /*#__PURE__*/React.createElement(ST_ThemeToggle, null)
  }), /*#__PURE__*/React.createElement(SettingRow, {
    icon: ST_Icons.Keyboard,
    label: "Atalho de grava\xE7\xE3o",
    control: /*#__PURE__*/React.createElement("span", {
      style: {
        display: 'flex',
        gap: 6
      }
    }, /*#__PURE__*/React.createElement(ST_Kbd, null, "\u2318"), /*#__PURE__*/React.createElement(ST_Kbd, null, "\u21E7"), /*#__PURE__*/React.createElement(ST_Kbd, null, "D")),
    last: true
  })));
}
Object.assign(window, {
  SettingsScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/dictate/SettingsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/dictate/Sidebar.jsx
try { (() => {
/* Eximium Dictate — Sidebar (nav rail) */
const {
  Brand: SB_Brand,
  Icons: SB_Icons
} = window.EximiumDesignSystem_b4169c;
const sidebarStyles = {
  rail: {
    width: 248,
    flexShrink: 0,
    height: '100%',
    background: 'var(--ex-surface-0)',
    borderRight: '1px solid var(--ex-border)',
    display: 'flex',
    flexDirection: 'column',
    padding: '18px 14px',
    gap: 4
  },
  brandRow: {
    padding: '6px 8px 16px'
  },
  newBtn: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    justifyContent: 'center',
    margin: '0 4px 14px',
    padding: '10px 14px',
    borderRadius: 9999,
    background: '#6DE2C0',
    color: '#04201a',
    border: 'none',
    fontFamily: 'inherit',
    fontWeight: 700,
    fontSize: 13,
    cursor: 'pointer',
    transition: 'background .15s, box-shadow .2s'
  },
  sectionLabel: {
    fontSize: 11,
    fontWeight: 700,
    textTransform: 'uppercase',
    letterSpacing: '0.08em',
    color: 'var(--ex-text-muted)',
    padding: '12px 12px 6px'
  },
  item: active => ({
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '9px 12px',
    borderRadius: 10,
    cursor: 'pointer',
    fontSize: 13,
    fontWeight: active ? 700 : 500,
    color: active ? 'var(--ex-text-accent)' : 'var(--ex-text-secondary)',
    background: active ? 'rgba(109,226,192,0.10)' : 'transparent',
    borderLeft: active ? '2px solid #6DE2C0' : '2px solid transparent',
    transition: 'background .15s, color .15s',
    userSelect: 'none'
  }),
  count: {
    marginLeft: 'auto',
    fontSize: 11,
    color: 'var(--ex-text-muted)',
    fontFamily: 'var(--ex-font-mono)'
  },
  spacer: {
    flex: 1
  },
  user: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '10px 12px',
    borderTop: '1px solid var(--ex-border)',
    marginTop: 8
  },
  avatar: {
    width: 30,
    height: 30,
    borderRadius: 9999,
    flexShrink: 0,
    background: 'linear-gradient(135deg,#014751,#6DE2C0)',
    color: '#04201a',
    display: 'grid',
    placeItems: 'center',
    fontWeight: 700,
    fontSize: 12
  }
};
function Sidebar({
  folders,
  current,
  onSelect,
  onNew,
  onSettings,
  settingsActive
}) {
  const navItems = [{
    key: 'history',
    label: 'Histórico',
    icon: SB_Icons.History
  }, {
    key: 'library',
    label: 'Biblioteca',
    icon: SB_Icons.Layers
  }];
  return /*#__PURE__*/React.createElement("nav", {
    style: sidebarStyles.rail
  }, /*#__PURE__*/React.createElement("div", {
    style: sidebarStyles.brandRow
  }, /*#__PURE__*/React.createElement(SB_Brand, {
    size: 19,
    product: "Dictate"
  })), /*#__PURE__*/React.createElement("button", {
    style: sidebarStyles.newBtn,
    onClick: onNew,
    onMouseEnter: e => {
      e.currentTarget.style.background = '#AEF7E4';
      e.currentTarget.style.boxShadow = '0 0 14px rgba(109,226,192,0.30)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.background = '#6DE2C0';
      e.currentTarget.style.boxShadow = 'none';
    }
  }, /*#__PURE__*/React.createElement(SB_Icons.Mic, {
    size: 16
  }), " Nova grava\xE7\xE3o"), navItems.map(it => {
    const Ic = it.icon;
    const active = current === it.key && !settingsActive;
    return /*#__PURE__*/React.createElement("div", {
      key: it.key,
      style: sidebarStyles.item(active),
      onClick: () => onSelect(it.key)
    }, /*#__PURE__*/React.createElement(Ic, {
      size: 17
    }), " ", it.label);
  }), /*#__PURE__*/React.createElement("div", {
    style: sidebarStyles.sectionLabel
  }, "Pastas"), folders.map(f => {
    const active = current === 'folder:' + f.name && !settingsActive;
    return /*#__PURE__*/React.createElement("div", {
      key: f.name,
      style: sidebarStyles.item(active),
      onClick: () => onSelect('folder:' + f.name)
    }, /*#__PURE__*/React.createElement(SB_Icons.File, {
      size: 17
    }), " ", f.name, /*#__PURE__*/React.createElement("span", {
      style: sidebarStyles.count
    }, f.count));
  }), /*#__PURE__*/React.createElement("div", {
    style: sidebarStyles.spacer
  }), /*#__PURE__*/React.createElement("div", {
    style: sidebarStyles.item(settingsActive),
    onClick: onSettings
  }, /*#__PURE__*/React.createElement(SB_Icons.Settings, {
    size: 17
  }), " Configura\xE7\xF5es"), /*#__PURE__*/React.createElement("div", {
    style: sidebarStyles.user
  }, /*#__PURE__*/React.createElement("div", {
    style: sidebarStyles.avatar
  }, "JM"), /*#__PURE__*/React.createElement("div", {
    style: {
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      fontWeight: 700,
      color: 'var(--ex-text-primary)'
    }
  }, "Jo\xE3o Mendes"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--ex-text-muted)'
    }
  }, "Plano Pro"))));
}
Object.assign(window, {
  Sidebar
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/dictate/Sidebar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/dictate/TranscriptScreen.jsx
try { (() => {
/* Eximium Dictate — Transcript detail screen */
const {
  Icons: TS_Icons,
  Button: TS_Button,
  Badge: TS_Badge
} = window.EximiumDesignSystem_b4169c;
const transcriptStyles = {
  scroll: {
    flex: 1,
    overflowY: 'auto'
  },
  header: {
    position: 'sticky',
    top: 0,
    zIndex: 5,
    display: 'flex',
    alignItems: 'center',
    gap: 14,
    padding: '18px 32px',
    background: 'var(--ex-surface-0)',
    borderBottom: '1px solid var(--ex-border)'
  },
  back: {
    width: 34,
    height: 34,
    borderRadius: 9999,
    flexShrink: 0,
    display: 'grid',
    placeItems: 'center',
    cursor: 'pointer',
    background: 'var(--ex-surface-2)',
    color: 'var(--ex-text-secondary)',
    border: '1px solid var(--ex-border)'
  },
  hTitle: {
    fontSize: 18,
    fontWeight: 700,
    color: 'var(--ex-text-primary)'
  },
  hMeta: {
    fontSize: 12,
    color: 'var(--ex-text-muted)',
    fontFamily: 'var(--ex-font-mono)',
    marginTop: 2
  },
  actions: {
    marginLeft: 'auto',
    display: 'flex',
    gap: 8
  },
  player: {
    display: 'flex',
    alignItems: 'center',
    gap: 16,
    margin: '24px 32px',
    padding: '16px 20px',
    background: 'var(--ex-surface-1)',
    border: '1px solid var(--ex-border)',
    borderRadius: 16,
    boxShadow: 'var(--ex-shadow-card)'
  },
  playBtn: {
    width: 44,
    height: 44,
    borderRadius: 9999,
    flexShrink: 0,
    cursor: 'pointer',
    display: 'grid',
    placeItems: 'center',
    background: '#6DE2C0',
    color: '#04201a',
    border: 'none'
  },
  track: {
    flex: 1,
    height: 6,
    borderRadius: 9999,
    background: 'var(--ex-surface-3)',
    position: 'relative',
    overflow: 'hidden'
  },
  fill: {
    position: 'absolute',
    left: 0,
    top: 0,
    bottom: 0,
    width: '34%',
    background: '#6DE2C0',
    borderRadius: 9999
  },
  time: {
    fontFamily: 'var(--ex-font-mono)',
    fontSize: 12,
    color: 'var(--ex-text-secondary)',
    flexShrink: 0
  },
  body: {
    padding: '4px 32px 48px',
    maxWidth: 760
  },
  seg: {
    display: 'flex',
    gap: 16,
    padding: '12px 0',
    borderBottom: '1px solid var(--ex-border)'
  },
  segT: {
    fontFamily: 'var(--ex-font-mono)',
    fontSize: 12,
    color: 'var(--ex-text-accent)',
    flexShrink: 0,
    width: 52,
    paddingTop: 3
  },
  segS: {
    fontSize: 15,
    lineHeight: 1.65,
    color: 'var(--ex-text-primary)',
    textWrap: 'pretty'
  }
};
function TranscriptScreen({
  item,
  onBack
}) {
  if (!item) return null;
  return /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.scroll
  }, /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.header
  }, /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.back,
    onClick: onBack,
    title: "Voltar"
  }, /*#__PURE__*/React.createElement(TS_Icons.ArrowLeft, {
    size: 17
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.hTitle
  }, item.title), /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.hMeta
  }, item.duration, " \xB7 ", item.words.toLocaleString('pt-BR'), " palavras \xB7 ", item.date)), /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.actions
  }, /*#__PURE__*/React.createElement(TS_Button, {
    variant: "subtle",
    size: "sm",
    icon: TS_Icons.Copy
  }, "Copiar"), /*#__PURE__*/React.createElement(TS_Button, {
    variant: "subtle",
    size: "sm",
    icon: TS_Icons.Download
  }, "Exportar"), /*#__PURE__*/React.createElement(TS_Button, {
    variant: "ghost",
    size: "icon",
    icon: TS_Icons.Sparkle,
    "aria-label": "Resumir com IA"
  }))), /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.player
  }, /*#__PURE__*/React.createElement("button", {
    style: transcriptStyles.playBtn,
    "aria-label": "Reproduzir"
  }, /*#__PURE__*/React.createElement(TS_Icons.ArrowRight, {
    size: 20
  })), /*#__PURE__*/React.createElement("span", {
    style: transcriptStyles.time
  }, "04:58"), /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.track
  }, /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.fill
  })), /*#__PURE__*/React.createElement("span", {
    style: transcriptStyles.time
  }, item.duration), /*#__PURE__*/React.createElement(TS_Icons.Volume, {
    size: 18,
    style: {
      color: 'var(--ex-text-muted)'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: transcriptStyles.body
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginBottom: 16
    }
  }, /*#__PURE__*/React.createElement(TS_Badge, {
    variant: "success"
  }, /*#__PURE__*/React.createElement(TS_Icons.Check, {
    size: 12
  }), " Transcrita"), /*#__PURE__*/React.createElement(TS_Badge, {
    variant: "default"
  }, item.folder), /*#__PURE__*/React.createElement(TS_Badge, {
    variant: "brand"
  }, "pt-BR")), item.segments.map((seg, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: transcriptStyles.seg
  }, /*#__PURE__*/React.createElement("span", {
    style: transcriptStyles.segT
  }, seg.t), /*#__PURE__*/React.createElement("span", {
    style: transcriptStyles.segS
  }, seg.s)))));
}
Object.assign(window, {
  TranscriptScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/dictate/TranscriptScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/dictate/data.js
try { (() => {
/* Eximium Dictate — UI kit demo data (fake, pt-BR) */
(function () {
  const transcripts = [{
    id: 't1',
    title: 'Reunião de produto — Q3',
    folder: 'Trabalho',
    duration: '14:32',
    date: 'Hoje, 09:41',
    words: 2480,
    status: 'done',
    starred: true,
    preview: 'Então, sobre o roadmap do terceiro trimestre — a prioridade número um é fechar o fluxo de onboarding. A gente viu nos dados que 40% dos usuários novos param na segunda tela…',
    segments: [{
      t: '00:00',
      s: 'Bom dia, pessoal. Obrigado por entrarem. Vamos começar pelo roadmap do terceiro trimestre.'
    }, {
      t: '00:09',
      s: 'A prioridade número um é fechar o fluxo de onboarding. A gente viu nos dados que quarenta por cento dos usuários novos param na segunda tela.'
    }, {
      t: '00:24',
      s: 'Eu acho que o problema é o pedido de permissão de microfone vir cedo demais. A gente pede antes de mostrar o valor.'
    }, {
      t: '00:38',
      s: 'Concordo. Vamos mover isso para depois da primeira transcrição de exemplo. Assim a pessoa já viu o produto funcionando.'
    }, {
      t: '00:52',
      s: 'Perfeito. Eu fecho o protótipo até sexta e a gente revisa na próxima.'
    }]
  }, {
    id: 't2',
    title: 'Ideias para o podcast',
    folder: 'Pessoal',
    duration: '03:18',
    date: 'Hoje, 08:02',
    words: 540,
    status: 'done',
    starred: false,
    preview: 'Pauta do próximo episódio: como times pequenos usam IA no dia a dia. Convidar a Marina pra falar sobre transcrição em pesquisa de usuário…',
    segments: [{
      t: '00:00',
      s: 'Pauta do próximo episódio: como times pequenos usam IA no dia a dia.'
    }, {
      t: '00:07',
      s: 'Convidar a Marina pra falar sobre transcrição em pesquisa de usuário. Ela tem uns cases muito bons.'
    }, {
      t: '00:18',
      s: 'Bloco final: ferramentas que a gente usa toda semana. Manter leve, sem virar propaganda.'
    }]
  }, {
    id: 't3',
    title: 'Notas de voz — caminhada',
    folder: 'Pessoal',
    duration: '01:47',
    date: 'Ontem, 19:20',
    words: 290,
    status: 'done',
    starred: false,
    preview: 'Lembrar de responder o e-mail do contador antes de terça. E marcar o dentista. Comprar presente de aniversário da minha irmã…',
    segments: [{
      t: '00:00',
      s: 'Lembrar de responder o e-mail do contador antes de terça.'
    }, {
      t: '00:05',
      s: 'Marcar o dentista — de preferência de manhã.'
    }, {
      t: '00:11',
      s: 'Comprar presente de aniversário da minha irmã. Ela falou de um livro semana passada.'
    }]
  }, {
    id: 't4',
    title: 'Entrevista com cliente — Acme',
    folder: 'Trabalho',
    duration: '28:05',
    date: 'Ontem, 14:10',
    words: 4910,
    status: 'done',
    starred: true,
    preview: 'A gente usa hoje uma planilha gigante e três ferramentas diferentes. O que mais incomoda é ter que copiar e colar tudo na mão entre elas…',
    segments: [{
      t: '00:00',
      s: 'Obrigada por reservar esse tempo. Pode me contar como é o seu fluxo hoje?'
    }, {
      t: '00:06',
      s: 'A gente usa uma planilha gigante e três ferramentas diferentes.'
    }, {
      t: '00:14',
      s: 'O que mais incomoda é ter que copiar e colar tudo na mão entre elas. Toma um tempo absurdo.'
    }, {
      t: '00:27',
      s: 'Se desse pra centralizar isso num lugar só, já mudaria o jogo pra gente.'
    }]
  }, {
    id: 't5',
    title: 'Brainstorm: nome do recurso',
    folder: 'Trabalho',
    duration: '06:54',
    date: '10 jun, 16:45',
    words: 1120,
    status: 'processing',
    starred: false,
    preview: 'Transcrevendo áudio…',
    segments: []
  }];
  const folders = [{
    name: 'Todas',
    count: 5
  }, {
    name: 'Trabalho',
    count: 3
  }, {
    name: 'Pessoal',
    count: 2
  }];
  window.DictateData = {
    transcripts,
    folders
  };
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/dictate/data.js", error: String((e && e.message) || e) }); }

__ds_ns.Brand = __ds_scope.Brand;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.Icons = __ds_scope.Icons;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.ThemeToggle = __ds_scope.ThemeToggle;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Spinner = __ds_scope.Spinner;

__ds_ns.Input = __ds_scope.Input;

__ds_ns.Toggle = __ds_scope.Toggle;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Divider = __ds_scope.Divider;

__ds_ns.Kbd = __ds_scope.Kbd;

__ds_ns.PageHeader = __ds_scope.PageHeader;

})();

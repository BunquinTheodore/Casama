(function () {
  'use strict';
  var NS = 'http://www.w3.org/2000/svg';
  var F = JSON.parse(document.getElementById('findings').textContent);
  var S = JSON.parse(document.getElementById('series').textContent);
  var MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  var DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  var STAGES = { stage_1: 'At purchase', stage_2: 'After shipping', stage_3: 'With weather and holidays' };
  var FEATURES = { estimated_days: 'Days promised', purchase_weekday: 'Weekday', purchase_hour: 'Hour', month_of_year: 'Month of year', handoff_days: 'Seller handoff days', heavy_rain_days: 'Heavy rain days', rain_mm_total: 'Total rain', holiday_in_window: 'Holiday in window' };
  function monthLabel(m) { return MONTHS[+m.slice(5, 7) - 1] + ' ' + m.slice(2, 4); }
  function el(tag, attrs, parent, text) {
    var e = document.createElementNS(NS, tag);
    for (var k in attrs) e.setAttribute(k, attrs[k]);
    if (text != null) e.textContent = text;
    if (parent) parent.appendChild(e);
    return e;
  }
  function tip(node, text) { el('title', {}, node, text); }
  function niceMax(v) {
    if (v <= 0) return 1;
    var p = Math.pow(10, Math.floor(Math.log10(v))), n = v / p;
    return (n <= 1 ? 1 : n <= 2 ? 2 : n <= 2.5 ? 2.5 : n <= 5 ? 5 : 10) * p;
  }
  function fmt(v) { return Math.abs(v) >= 1000 ? Math.round(v).toLocaleString('en-US') : String(Math.round(v * 100) / 100); }
  function tickStep(max) {
    var p = Math.pow(10, Math.floor(Math.log10(max))), steps = [p * 0.2, p * 0.25, p * 0.5, p, p * 2];
    for (var i = 0; i < steps.length; i++) if (max / steps[i] <= 6) return steps[i];
    return steps[steps.length - 1];
  }
  function snap(v, step) { return Math.ceil(v / step - 1e-9) * step; }
  // FORMAT START
  // Same rule as Python's format() and the video: round the exact binary value, an exact tie goes to the even digit.
  function fixed(v, d) {
    var abs = Math.abs(v), exact = abs.toFixed(d + 25), beyond = exact.slice(exact.length - 25), text = abs.toFixed(d);
    if (/^50*$/.test(beyond)) {
      var kept = exact.slice(0, exact.length - 25).replace(/\.$/, '');
      if (Number(kept.slice(-1)) % 2 === 0) text = kept;
    }
    return (v < 0 && !/^[0.]*$/.test(text) ? '-' : '') + text;
  }
  // FORMAT END
  function label1(v, unit) { return unit === '%' ? fixed(v, 1) + '%' : fmt(v) + (unit || ''); }
  // FILTER START
  // Pure filters over series.json, so a filtered chart always shows rows that exist in the data and nothing else.
  function stateRainRows(rows, state) {
    return rows.filter(function (r) { return r.state === state; }).map(function (r) {
      return { group: r.group, n: r.n, late_pct: r.late_pct, ci_low: r.ci_low, ci_high: r.ci_high, reliable: r.reliable };
    });
  }
  function monthRange(rows, from, to) { return rows.filter(function (r) { return r.month >= from && r.month <= to; }); }
  // FILTER END
  function frame(box, H) {
    box.textContent = '';
    var W = Math.max(box.clientWidth, 260);
    var svg = el('svg', { viewBox: '0 0 ' + W + ' ' + H, width: W, height: H, role: 'img' }, box);
    return { svg: svg, W: W, H: H };
  }
  function axes(c, m, max, o) {
    var h = c.H - m.t - m.b, step = tickStep(max), ticks = Math.round(max / step);
    for (var i = 0; i <= ticks; i++) {
      var v = step * i, y = c.H - m.b - h * v / max;
      el('line', { x1: m.l - 4, x2: m.l, y1: y, y2: y, class: 'tick' }, c.svg);
      el('text', { x: m.l - 8, y: y + 4, 'text-anchor': 'end' }, c.svg, fmt(v) + (o.unit || ''));
    }
    el('line', { x1: m.l, x2: m.l, y1: m.t, y2: c.H - m.b, class: 'axis' }, c.svg);
    el('line', { x1: m.l, x2: c.W - m.r, y1: c.H - m.b, y2: c.H - m.b, class: 'axis' }, c.svg);
    if (o.yLabel) el('text', { class: 'axis-title', transform: 'translate(12,' + (m.t + h / 2) + ') rotate(-90)', 'text-anchor': 'middle' }, c.svg, o.yLabel);
    if (o.xLabel) el('text', { class: 'axis-title', x: m.l + (c.W - m.l - m.r) / 2, y: c.H - 6, 'text-anchor': 'middle' }, c.svg, o.xLabel);
  }
  function xText(c, x, y, text, rotate) {
    var t = el('text', { x: x, y: y, 'text-anchor': rotate ? 'end' : 'middle' }, c.svg, text);
    if (rotate) t.setAttribute('transform', 'rotate(-40 ' + x + ' ' + y + ')');
  }

  function bars(box, rows, o) {
    var many = rows.length > 8, W0 = Math.max(box.clientWidth, 260), rot = many && (W0 - 74) / rows.length < 46;
    var m = { l: 60, r: 14, t: 18, b: rot ? 78 : (o.xLabel ? 62 : 42) }, c = frame(box, o.height || 330);
    var vals = rows.map(function (r) { return o.ci && r.ci_high != null ? r.ci_high : r[o.y]; });
    var stepY = tickStep(Math.max.apply(null, vals) * 1.12), max = snap(Math.max.apply(null, vals) * 1.12, stepY), h = c.H - m.t - m.b, step = (c.W - m.l - m.r) / rows.length;
    axes(c, m, max, o);
    rows.forEach(function (r, i) {
      var v = r[o.y], x = m.l + step * (i + 0.5), bw = step * 0.6, top = c.H - m.b - h * v / max;
      var rect = el('rect', { x: x - bw / 2, y: top, width: bw, height: c.H - m.b - top, class: o.hot && o.hot(r, i) ? 'hot' : 'mark' }, c.svg);
      tip(rect, (o.label ? o.label(r) : r[o.x]) + ': ' + fmt(v) + (o.unit || '') + (r.n ? ' (' + fmt(r.n) + ' parcels)' : '') + (r.ci_low != null ? ', interval ' + fmt(r.ci_low) + ' to ' + fmt(r.ci_high) : ''));
      if (o.ci && r.ci_low != null) {
        var lo = c.H - m.b - h * r.ci_low / max, hi = c.H - m.b - h * r.ci_high / max;
        el('line', { x1: x, x2: x, y1: lo, y2: hi, class: 'whisker', stroke: 'var(--bg)' }, c.svg);
        el('line', { x1: x, x2: x, y1: lo, y2: hi, class: 'whisker', style: 'stroke:var(--accent);stroke-width:2.4' }, c.svg);
      }
      if (!many) {
        var above = o.ci && r.ci_high != null ? c.H - m.b - h * r.ci_high / max : top;
        el('text', { x: x, y: above - 7, 'text-anchor': 'middle' }, c.svg, label1(v, o.unit));
      }
      xText(c, x, c.H - m.b + 16, o.tick ? o.tick(r) : r[o.x], rot);
    });
  }

  function hbars(box, rows, o) {
    var m = { l: o.left || 190, r: 70, t: 14, b: 44 }, c = frame(box, 60 + rows.length * 54);
    var max = niceMax(Math.max.apply(null, rows.map(function (r) { return Math.abs(r[o.value]); })) * 1.05), bh = 28, w = c.W - m.l - m.r;
    rows.forEach(function (r, i) {
      var y = m.t + i * 54 + 6, len = w * Math.max(r[o.value], 0) / max;
      var rect = el('rect', { x: m.l, y: y, width: len, height: bh, class: o.hot && o.hot(r, i) ? 'hot' : 'mark' }, c.svg);
      tip(rect, r[o.label] + ': ' + fmt(r[o.value]));
      el('text', { x: m.l - 10, y: y + bh / 2 + 4, 'text-anchor': 'end' }, c.svg, o.name ? o.name(r) : r[o.label]);
      el('text', { x: m.l + len + 8, y: y + bh / 2 + 4 }, c.svg, fmt(r[o.value]));
    });
    el('line', { x1: m.l, x2: m.l, y1: m.t, y2: c.H - m.b + 6, class: 'axis' }, c.svg);
    if (o.xLabel) el('text', { class: 'axis-title', x: m.l + w / 2, y: c.H - 8, 'text-anchor': 'middle' }, c.svg, o.xLabel);
  }

  function hist(box, rows, o) {
    var m = { l: 62, r: 14, t: 18, b: 56 }, c = frame(box, 320), n = rows.length;
    var max = niceMax(Math.max.apply(null, rows.map(function (r) { return r.orders; })) * 1.08), h = c.H - m.t - m.b, bw = (c.W - m.l - m.r) / n;
    axes(c, m, max, o);
    rows.forEach(function (r, i) {
      var top = c.H - m.b - h * r.orders / max;
      var rect = el('rect', { x: m.l + i * bw + 0.5, y: top, width: Math.max(bw - 1, 1), height: c.H - m.b - top, class: o.accentFrom != null && r.bin_start >= o.accentFrom ? 'hot' : 'mark' }, c.svg);
      tip(rect, r.bin_start + ' to ' + (r.bin_start + 1) + ' days: ' + fmt(r.orders) + ' orders');
    });
    var first = rows[0].bin_start, span = n;
    [0, 0.25, 0.5, 0.75, 1].forEach(function (f) {
      var x = m.l + (c.W - m.l - m.r) * f;
      xText(c, x, c.H - m.b + 16, String(Math.round(first + span * f)));
    });
    if (o.vline != null) {
      var x = m.l + (o.vline - first) * bw;
      el('line', { x1: x, x2: x, y1: m.t, y2: c.H - m.b, class: 'hotline' }, c.svg);
      el('text', { x: x + 6, y: m.t + 10, style: 'fill:var(--accent)' }, c.svg, 'median ' + o.vline + ' days');
    }
  }

  function heat(box, rows, o) {
    var rl = o.rows, cl = o.cols, m = { l: o.left || 52, r: 14, t: 14, b: o.rotate ? 130 : 54 }, cw, ch = o.cell || 30;
    var c = frame(box, m.t + m.b + rl.length * ch);
    cw = (c.W - m.l - m.r) / cl.length;
    var vals = rows.map(function (r) { return o.signed ? Math.abs(r[o.v]) : r[o.v]; }), max = Math.max.apply(null, vals) || 1;
    rows.forEach(function (r) {
      var ri = rl.indexOf(r[o.r]), ci = cl.indexOf(r[o.c]);
      if (ri < 0 || ci < 0) return;
      var v = o.signed ? Math.abs(r[o.v]) : r[o.v];
      var rect = el('rect', { x: m.l + ci * cw, y: m.t + ri * ch, width: cw - 1, height: ch - 1, class: 'mark', 'fill-opacity': (0.06 + 0.94 * v / max).toFixed(3) }, c.svg);
      tip(rect, r[o.r] + ', ' + r[o.c] + ': ' + fmt(r[o.v]));
      if (o.values && cw > 34) el('text', { x: m.l + ci * cw + cw / 2, y: m.t + ri * ch + ch / 2 + 4, 'text-anchor': 'middle', style: 'fill:var(--bg);mix-blend-mode:normal;opacity:' + (v / max > 0.5 ? 1 : 0) }, c.svg, fmt(r[o.v]));
    });
    rl.forEach(function (name, i) { el('text', { x: m.l - 8, y: m.t + i * ch + ch / 2 + 4, 'text-anchor': 'end' }, c.svg, o.rowName ? o.rowName(name) : name); });
    cl.forEach(function (name, i) {
      if (o.every && i % o.every !== 0) return;
      var x = m.l + i * cw + cw / 2, y = m.t + rl.length * ch + 14, text = o.colName ? o.colName(name) : name;
      if (!o.rotate) { xText(c, x, y + 2, text, false); return; }
      el('text', { x: x, y: y, 'text-anchor': 'start', transform: 'rotate(40 ' + x + ' ' + y + ')' }, c.svg, text);
    });
    if (o.xLabel) el('text', { class: 'axis-title', x: m.l + (c.W - m.l - m.r) / 2, y: c.H - 6, 'text-anchor': 'middle' }, c.svg, o.xLabel);
  }

  function boxes(box, rows, o) {
    var m = { l: 60, r: 14, t: 18, b: 62 }, c = frame(box, 330), step = (c.W - m.l - m.r) / rows.length;
    var max = niceMax(Math.max.apply(null, rows.map(function (r) { return r.whisker_high; })) * 1.05), h = c.H - m.t - m.b;
    var y = function (v) { return c.H - m.b - h * v / max; };
    axes(c, m, max, o);
    rows.forEach(function (r, i) {
      var x = m.l + step * (i + 0.5), bw = step * 0.5;
      el('line', { x1: x, x2: x, y1: y(r.whisker_low), y2: y(r.whisker_high), class: 'whisker' }, c.svg);
      var rect = el('rect', { x: x - bw / 2, y: y(r.q3), width: bw, height: y(r.q1) - y(r.q3), class: 'mark', 'fill-opacity': '0.18', stroke: 'currentColor' }, c.svg);
      tip(rect, r.bucket + ': median ' + r.median + ' days, middle half ' + r.q1 + ' to ' + r.q3 + ' (' + fmt(r.orders) + ' parcels)');
      el('line', { x1: x - bw / 2, x2: x + bw / 2, y1: y(r.median), y2: y(r.median), class: 'hotline' }, c.svg);
      xText(c, x, c.H - m.b + 16, r.bucket, step < 90);
    });
  }

  function scatter(box, rows, o) {
    var m = { l: 60, r: 14, t: 14, b: 52 }, c = frame(box, Math.min(Math.max(box.clientWidth * 0.8, 300), 460));
    var lim = 50, w = c.W - m.l - m.r, h = c.H - m.t - m.b;
    axes(c, m, lim, o);
    rows.forEach(function (r) { el('circle', { cx: m.l + w * r.promised / lim, cy: c.H - m.b - h * r.actual / lim, r: 1.7, class: 'mark', 'fill-opacity': '0.28' }, c.svg); });
    el('line', { x1: m.l, y1: c.H - m.b, x2: m.l + w, y2: m.t, class: 'hotline' }, c.svg);
    el('text', { x: m.l + w * 0.62, y: m.t + h * 0.18, style: 'fill:var(--accent)' }, c.svg, 'late above this line');
  }

  function lines(box, groups, o) {
    var m = { l: 60, r: 14, t: 18, b: 56 }, c = frame(box, 340), w = c.W - m.l - m.r, h = c.H - m.t - m.b;
    axes(c, m, 1, o);
    el('line', { x1: m.l, y1: c.H - m.b, x2: m.l + w, y2: m.t, class: 'tick', 'stroke-dasharray': '4 4' }, c.svg);
    groups.forEach(function (g, gi) {
      var d = g.points.map(function (p, i) { return (i ? 'L' : 'M') + (m.l + w * p.fpr).toFixed(1) + ' ' + (c.H - m.b - h * p.tpr).toFixed(1); }).join(' ');
      el('path', { d: d, class: g.hot ? 'hotline' : 'axis', 'stroke-dasharray': gi === 0 ? '2 4' : '' }, c.svg);
      var ly = c.H - m.b - 64 + gi * 18; // the lower right corner is empty on a ROC curve
      el('line', { x1: m.l + w * 0.5, x2: m.l + w * 0.5 + 22, y1: ly - 4, y2: ly - 4, class: g.hot ? 'hotline' : 'axis', 'stroke-dasharray': gi === 0 ? '2 4' : '' }, c.svg);
      el('text', { x: m.l + w * 0.5 + 30, y: ly }, c.svg, g.name);
    });
  }

  function barsLine(box, rows, o) {
    var m = { l: 62, r: 52, t: 18, b: 70 }, c = frame(box, 340), step = (c.W - m.l - m.r) / rows.length;
    var max = niceMax(Math.max.apply(null, rows.map(function (r) { return r.orders; })) * 1.08), h = c.H - m.t - m.b;
    var lmax = niceMax(Math.max.apply(null, rows.map(function (r) { return r.late_pct; })) * 1.15);
    axes(c, m, max, { yLabel: 'Orders per month', xLabel: '' });
    var path = [];
    rows.forEach(function (r, i) {
      var x = m.l + step * (i + 0.5), top = c.H - m.b - h * r.orders / max, ly = c.H - m.b - h * r.late_pct / lmax;
      var rect = el('rect', { x: x - step * 0.3, y: top, width: step * 0.6, height: c.H - m.b - top, class: 'mark', 'fill-opacity': '0.28' }, c.svg);
      tip(rect, monthLabel(r.month) + ': ' + fmt(r.orders) + ' orders, ' + r.late_pct + '% late');
      path.push((i ? 'L' : 'M') + x.toFixed(1) + ' ' + ly.toFixed(1));
      xText(c, x, c.H - m.b + 16, monthLabel(r.month), true);
    });
    el('path', { d: path.join(' '), class: 'hotline' }, c.svg);
    for (var i = 0; i <= 4; i++) el('text', { x: c.W - m.r + 8, y: c.H - m.b - h * i / 4 + 4, style: 'fill:var(--accent)' }, c.svg, fmt(lmax * i / 4) + '%');
    el('text', { class: 'axis-title', transform: 'translate(' + (c.W - 6) + ',' + (m.t + h / 2) + ') rotate(90)', 'text-anchor': 'middle', style: 'fill:var(--accent)' }, c.svg, 'Late parcels');
  }

  function stage(rows, name) { return rows.filter(function (r) { return r.stage === name; }); }
  var CHARTS = {
    cleaning_funnel: function (b) { hbars(b, S.cleaning_funnel, { label: 'step', value: 'orders', left: Math.min(b.clientWidth * 0.42, 260), xLabel: 'Orders', hot: function (r, i) { return i === S.cleaning_funnel.length - 1; } }); },
    delivery_hist: function (b) { hist(b, S.delivery_hist, { xLabel: 'Days from purchase to delivery', yLabel: 'Orders', vline: F.delivery_days.median }); },
    estimate_gap_hist: function (b) { hist(b, S.estimate_gap_hist, { xLabel: 'Days delivered before (negative) or after (positive) the estimate', yLabel: 'Orders', accentFrom: 1 }); },
    late_by_month: function (b) { bars(b, monthRange(S.late_by_month, document.getElementById('month-from').value, document.getElementById('month-to').value), { x: 'month', y: 'late_pct', unit: '%', yLabel: 'Late parcels', tick: function (r) { return monthLabel(r.month); }, label: function (r) { return monthLabel(r.month); }, hot: function (r) { return r.late_pct >= 10; } }); },
    late_by_handoff: function (b) { bars(b, S.late_by_handoff, { x: 'bucket', y: 'late_pct', unit: '%', yLabel: 'Late parcels', xLabel: 'Days until the seller hands the parcel to the carrier', hot: function (r, i) { return i === S.late_by_handoff.length - 1; } }); },
    late_by_promise: function (b) { bars(b, S.late_by_promise, { x: 'bucket', y: 'late_pct', unit: '%', yLabel: 'Late parcels', xLabel: 'Days promised at purchase' }); },
    order_rhythm: function (b) { heat(b, S.order_rhythm, { r: 'weekday', c: 'hour', v: 'orders', rows: [0, 1, 2, 3, 4, 5, 6], cols: Array.apply(null, Array(24)).map(function (_, i) { return i; }), rowName: function (i) { return DAYS[i]; }, colName: function (h) { return h + ':00'; }, every: 3, xLabel: 'Hour of purchase', cell: 28 }); },
    volume_vs_late: function (b) { barsLine(b, S.volume_vs_late, {}); },
    delivery_spread: function (b) { boxes(b, S.delivery_spread, { yLabel: 'Total days to deliver', xLabel: 'Days until the seller hands the parcel to the carrier' }); },
    promise_vs_actual: function (b) { scatter(b, S.promise_vs_actual, { xLabel: 'Days promised at purchase', yLabel: 'Days it actually took' }); },
    correlation: function (b) {
      var names = []; S.correlation.forEach(function (r) { if (names.indexOf(r.row) < 0) names.push(r.row); });
      heat(b, S.correlation, { r: 'row', c: 'col', v: 'value', rows: names, cols: names, signed: true, values: true, left: Math.min(b.clientWidth * 0.34, 150), cell: 40, rotate: true });
    },
    rain_dose: function (b) { bars(b, S.rain_dose, { x: 'group', y: 'late_pct', ci: true, unit: '%', yLabel: 'Late parcels', xLabel: 'Heavy rain days in the window', tick: function (r) { return r.group; } }); },
    holiday_effect: function (b) { bars(b, S.holiday_effect, { x: 'group', y: 'late_pct', ci: true, unit: '%', yLabel: 'Late parcels', height: 300 }); },
    state_rain: function (b) {
      var state = document.getElementById('state-filter').value, rows = stateRainRows(S.state_rain, state);
      bars(b, rows, { x: 'group', y: 'late_pct', ci: true, unit: '%', yLabel: 'Late parcels', height: 300, tick: function (r) { return r.group === 'rainy' ? 'At least one heavy rain day' : 'No heavy rain day'; } });
      var parts = rows.map(function (r) { return fmt(r.n) + ' parcels ' + (r.group === 'rainy' ? 'with' : 'without') + ' heavy rain'; });
      var thin = rows.some(function (r) { return !r.reliable; });
      document.getElementById('state-note').textContent = 'State ' + state + ': ' + parts.join(' and ') + '. ' + (thin ? 'Too few parcels in one group for an interval. ' : '');
    },
    roc_curves: function (b) {
      lines(b, ['stage_1', 'stage_2', 'stage_3'].map(function (n) { return { name: STAGES[n], points: stage(S.roc_curves, n), hot: n === 'stage_3' }; }), { yLabel: 'Late parcels caught', xLabel: 'On time parcels wrongly flagged' });
    },
    importance: function (b) {
      var rows = stage(S.importance, 'stage_3').slice().sort(function (a, z) { return z.value - a.value; });
      hbars(b, rows, { label: 'feature', value: 'value', name: function (r) { return FEATURES[r.feature]; }, left: Math.min(b.clientWidth * 0.4, 190), xLabel: 'Drop in AUC when the signal is hidden', hot: function (r) { return r.feature.indexOf('rain') >= 0 || r.feature.indexOf('holiday') >= 0; } });
    },
    risk_deciles: function (b) { bars(b, stage(S.risk_deciles, 'stage_3'), { x: 'decile', y: 'late_pct', unit: '%', yLabel: 'Actually late', xLabel: 'Parcels ranked by predicted risk, 1 safest and 10 riskiest', hot: function (r) { return r.decile === 10; } }); }
  };

  function drawAll() {
    document.querySelectorAll('figure.chart').forEach(function (fig) {
      var box = fig.querySelector('.plot'), draw = CHARTS[fig.getAttribute('data-chart')];
      if (box && draw) draw(box);
    });
  }

  function inkFit(text, family, weight, size, letter) {
    var ctx = document.createElement('canvas').getContext('2d');
    ctx.font = weight + ' ' + size + 'px ' + family;
    if ('letterSpacing' in ctx) ctx.letterSpacing = letter + 'px';
    var m = ctx.measureText(text);
    return { left: m.actualBoundingBoxLeft, ink: m.actualBoundingBoxLeft + m.actualBoundingBoxRight };
  }
  function fitLockup() {
    var h1 = document.querySelector('.hero h1'), tag = document.querySelector('.hero .tagline');
    if (!h1 || !tag) return;
    var W = h1.parentElement.clientWidth, st = getComputedStyle(h1), lines = [].slice.call(h1.querySelectorAll('span'));
    var letter = parseFloat(st.letterSpacing) / parseFloat(st.fontSize) || 0.04, best = 0, lead = 0;
    lines.forEach(function (s) {
      var f = inkFit(s.textContent.trim().toUpperCase(), st.fontFamily, st.fontWeight, 100, letter * 100);
      if (f.ink > best) { best = f.ink; lead = f.left; }
    });
    if (!best) return;
    var size = W / best * 100;
    h1.style.fontSize = size + 'px';
    h1.style.marginLeft = (lead * size / 100) + 'px';
    var ts = getComputedStyle(tag), text = tag.textContent.trim().toUpperCase(), tsize = parseFloat(ts.fontSize);
    var base = inkFit(text, ts.fontFamily, ts.fontWeight, tsize, 0);
    var gap = (W - base.ink) / (text.length - 1);
    if (gap > 0 && gap < tsize * 1.2) {
      tag.style.letterSpacing = gap + 'px';
      tag.style.marginLeft = base.left + 'px';
      tag.style.whiteSpace = 'nowrap';
    } else {
      tag.style.letterSpacing = '';
      tag.style.whiteSpace = '';
    }
  }

  function navigation() {
    var links = [].slice.call(document.querySelectorAll('.pill a[data-s]')), line = document.querySelector('.pill .slide');
    var targets = links.map(function (a) { return document.getElementById(a.getAttribute('data-s')); }), ticking = false, current = -1;
    function set(i) {
      if (i === current) return;
      current = i;
      links.forEach(function (a, j) { a.setAttribute('aria-current', j === i ? 'true' : 'false'); });
      line.style.width = links[i].offsetWidth + 'px';
      line.style.transform = 'translateX(' + links[i].offsetLeft + 'px)';
    }
    function update() {
      ticking = false;
      var y = window.innerHeight * 0.45, idx = 0;
      targets.forEach(function (t, i) { if (t.getBoundingClientRect().top < y) idx = i; });
      if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 4) idx = targets.length - 1;
      set(idx);
    }
    window.addEventListener('scroll', function () { if (!ticking) { ticking = true; requestAnimationFrame(update); } }, { passive: true });
    window.addEventListener('resize', function () { current = -1; update(); });
    update();
  }

  function reveal() {
    var items = document.querySelectorAll('.fade');
    if (!('IntersectionObserver' in window)) { items.forEach(function (n) { n.classList.add('in'); }); return; }
    var io = new IntersectionObserver(function (entries) { entries.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } }); }, { threshold: 0 });
    items.forEach(function (n) { io.observe(n); });
  }

  function redraw(name) {
    var fig = document.querySelector('figure[data-chart="' + name + '"]');
    if (fig && CHARTS[name]) CHARTS[name](fig.querySelector('.plot'));
  }
  function controls() {
    var from = document.getElementById('month-from'), to = document.getElementById('month-to'), state = document.getElementById('state-filter');
    from.addEventListener('change', function () { if (from.value > to.value) to.value = from.value; redraw('late_by_month'); });
    to.addEventListener('change', function () { if (to.value < from.value) from.value = to.value; redraw('late_by_month'); });
    state.addEventListener('change', function () { redraw('state_rain'); });
  }
  function quiz() {
    var button = document.getElementById('quiz-check'), result = document.getElementById('quiz-result');
    if (!button) return;
    button.addEventListener('click', function () {
      var best = ['stage_1', 'stage_2', 'stage_3'].reduce(function (a, k) { return F.h3['auc_' + k] > F.h3['auc_' + a] ? k : a; }, 'stage_1');
      var answers = { h1: F.h1.verdict, h2: F.h2.verdict, model: best }, right = 0, total = 0;
      document.querySelectorAll('#quiz fieldset.q').forEach(function (set) {
        var picked = set.querySelector('input:checked'), good = answers[set.getAttribute('data-answer')];
        total += 1;
        set.querySelectorAll('label').forEach(function (l) { l.classList.toggle('right', l.querySelector('input').value === good); });
        if (picked && picked.value === good) right += 1;
      });
      result.textContent = 'You got ' + right + ' of ' + total + '. The correct answers are underlined.';
    });
  }

  var timer, lastWidth = window.innerWidth;
  function init() {
    controls(); quiz();
    drawAll(); fitLockup(); navigation(); reveal();
    window.addEventListener('resize', function () {
      if (window.innerWidth === lastWidth) return; // address bars changing height must not redraw every chart
      lastWidth = window.innerWidth;
      clearTimeout(timer);
      timer = setTimeout(function () { drawAll(); fitLockup(); }, 120);
    });
    window.__explorerReady = true;
  }
  (document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve()).then(init);
}());

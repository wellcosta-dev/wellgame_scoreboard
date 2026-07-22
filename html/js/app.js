const overlay = document.getElementById('overlay');
const rowsEl = document.getElementById('rows');
const fillEl = document.getElementById('fill');
const countEl = document.getElementById('count');
const brandEl = document.getElementById('brand');
const titleEl = document.getElementById('title');
const colsEl = document.getElementById('cols');

let players = [];
let maxPlayers = 48;
let offset = 0;
let visibleRows = 12;
let afkThreshold = 60;
let open = false;

function calcVisibleRows() {
  const vh = window.innerHeight || 1080;
  const panelMax = vh * 0.6;
  const headerApprox = 48;
  const colsH = 35;
  const progressH = 4;
  const rowH = 35;
  const usable = panelMax - headerApprox - colsH - progressH;
  visibleRows = Math.max(4, Math.floor(usable / rowH) - 1);
}

function formatAfk(sec) {
  const m = Math.floor(sec / 60);
  if (m >= 60) return 'AFK: ' + Math.floor(m / 60) + 'h';
  const s = sec - m * 60;
  return 'AFK: ' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
}

function pingMeta(ping) {
  if (ping == null || ping === false) return null;
  const p = Number(ping);
  if (p >= 300) return { text: (p > 999 ? '999+' : p + 'ms'), cls: 'ping-bad', bars: 1 };
  if (p >= 200) return { text: p + 'ms', cls: 'ping-warn', bars: 2 };
  if (p >= 100) return { text: p + 'ms', cls: 'ping-ok', bars: 3 };
  return { text: p + 'ms', cls: 'ping-good', bars: 4 };
}

function applyPayload(data) {
  if (!data) return;
  players = Array.isArray(data.players) ? data.players : [];
  maxPlayers = Number(data.maxPlayers) || 48;
  afkThreshold = Number(data.afkThreshold) || 60;
  if (data.brand) brandEl.textContent = data.brand;
  if (data.title) titleEl.textContent = data.title;
  if (data.columns) {
    colsEl.querySelector('.col-id').textContent = data.columns.id || 'ID';
    colsEl.querySelector('.col-name').textContent = data.columns.name || 'Név';
    colsEl.querySelector('.col-level').textContent = data.columns.level || 'Szint';
    colsEl.querySelector('.col-ping').textContent = data.columns.ping || 'Ping';
  }
  const maxOffset = Math.max(0, players.length - visibleRows);
  offset = Math.min(offset, maxOffset);
  render();
}

function render() {
  calcVisibleRows();
  const maxOffset = Math.max(0, players.length - visibleRows);
  offset = Math.max(0, Math.min(offset, maxOffset));

  countEl.textContent = players.length + '/' + maxPlayers;
  const fillPct = Math.min(100, (players.length / Math.max(1, maxPlayers)) * 100);
  fillEl.style.width = fillPct + '%';

  rowsEl.innerHTML = '';
  rowsEl.style.maxHeight = (visibleRows * 35) + 'px';

  const slice = players.slice(offset, offset + visibleRows);
  for (const p of slice) {
    const row = document.createElement('div');
    row.className = 'row';
    if (p.isSelf) row.classList.add('is-self');
    if (p.isHelper && !p.adminDuty) row.classList.add('is-helper');
    if (!p.loggedIn) row.classList.add('is-offline');

    let colorStyle = '';
    if (p.adminDuty && p.adminColor) {
      colorStyle = 'color:' + p.adminColor;
      row.style.color = p.adminColor;
    }

    const id = document.createElement('div');
    id.className = 'c-id';
    id.textContent = String(p.id);

    const name = document.createElement('div');
    name.className = 'c-name';
    name.textContent = p.name || '';

    const level = document.createElement('div');
    level.className = 'c-level';

    const ping = document.createElement('div');
    ping.className = 'c-ping';

    const signal = document.createElement('div');
    signal.className = 'signal hidden';
    signal.innerHTML = '<span></span><span></span><span></span><span></span>';

    if (!p.loggedIn) {
      level.textContent = 'nincs bejelentkezve';
      ping.textContent = '';
    } else if (p.adminDuty) {
      level.textContent = p.adminLabel || 'Admin';
      ping.textContent = 'on duty';
    } else {
      level.textContent = (p.level !== false && p.level != null) ? ('Lvl ' + p.level) : '';
      const afk = Number(p.afkSeconds) || 0;
      if (afk >= afkThreshold) {
        ping.textContent = formatAfk(afk);
        if (afk >= 3600 || Math.floor(afk / 60) >= 20) ping.classList.add('afk-bad');
        else if (Math.floor(afk / 60) >= 10) ping.classList.add('afk-warn');
        else ping.classList.add('afk-mild');
      } else {
        const meta = pingMeta(p.ping);
        if (meta) {
          ping.textContent = meta.text;
          ping.classList.add(meta.cls);
          signal.classList.remove('hidden');
          signal.classList.add('bars-' + meta.bars);
          signal.style.color = getComputedStyle(document.body).getPropertyValue('--unused') || '';
          // match ping color via class on signal
          signal.classList.add(meta.cls);
        }
      }
    }

    row.appendChild(id);
    row.appendChild(name);
    row.appendChild(level);
    row.appendChild(ping);
    row.appendChild(signal);
    rowsEl.appendChild(row);
  }
}

function scrollBy(dir) {
  if (!open) return;
  const maxOffset = Math.max(0, players.length - visibleRows);
  offset = Math.max(0, Math.min(maxOffset, offset + dir));
  render();
}

window.addEventListener('message', (e) => {
  const msg = e.data || {};
  if (msg.action === 'open') {
    open = true;
    offset = 0;
    overlay.classList.remove('hidden');
    applyPayload(msg.data);
  } else if (msg.action === 'update') {
    if (!open) return;
    applyPayload(msg.data);
  } else if (msg.action === 'close') {
    open = false;
    overlay.classList.add('hidden');
    rowsEl.innerHTML = '';
  } else if (msg.action === 'scroll') {
    scrollBy(Number(msg.dir) || 0);
  }
});

window.addEventListener('wheel', (e) => {
  if (!open) return;
  if (e.deltaY > 0) scrollBy(1);
  else if (e.deltaY < 0) scrollBy(-1);
}, { passive: true });

window.addEventListener('resize', () => {
  if (open) render();
});

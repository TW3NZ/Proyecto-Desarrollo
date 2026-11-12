'use strict';
const $ = id => document.getElementById(id);
const state = {tables: [], table: null, q: '', filters: {}, page: 1, size: 25, sort: '', direction: 'asc', total: 0, request: 0, loading: false};
const externalPage = location.protocol !== 'file:' &&
  (!/^\/admin\/?$/.test(location.pathname) || /^55\d\d$/.test(location.port));
let apiOrigin = location.origin;
const node = (tag, text, cls) => {const n = document.createElement(tag); if (text !== undefined) n.textContent = text; if (cls) n.className = cls; return n;};
const format = value => value === null ? 'NULL' : typeof value === 'object' ? JSON.stringify(value) : String(value);
function status(text, error = false) {$('status').textContent = text; $('status').className = error ? 'error' : '';}
async function api(path) {
  let response;
  try {
    response = await fetch(apiOrigin + '/admin/api/' + path, {
      credentials: externalPage ? 'omit' : 'same-origin', cache: 'no-store',
      signal: AbortSignal.timeout(45000),
    });
  } catch {
    throw new Error(`No se pudo contactar con ${apiOrigin}. Comprueba que FastAPI esté iniciado y que ADMIN_ALLOWED_ORIGINS incluya ${location.origin}.`);
  }
  if (response.status === 404) throw new Error(`No existe /admin/api/${path.split('?')[0]} en ${apiOrigin}. Usa el puerto del backend (normalmente 8000), no el de Live Server.`);
  if (response.status === 401) throw new Error('El acceso sin contraseña solo está disponible desde este equipo. Abre el panel mediante localhost o 127.0.0.1 y revisa el origen permitido.');
  if (!response.ok) {let body; try {body = await response.json();} catch {} throw new Error(typeof body?.detail === 'string' ? body.detail : 'No se pudo completar la consulta.');}
  if (!response.headers.get('content-type')?.includes('application/json')) throw new Error('El servidor respondió con una página, no con datos. Revisa la dirección de la API.');
  return response.json();
}
function relations() {return state.tables.flatMap(t => t.relations).filter(r => r.source === state.table.name || r.target === state.table.name);}
function menu() {
  const term = $('tableSearch').value.toLowerCase(); $('tables').replaceChildren();
  for (const table of state.tables.filter(t => t.name.toLowerCase().includes(term))) {
    const button = node('button', table.name, state.table?.name === table.name ? 'selected' : '');
    button.setAttribute('aria-current', state.table?.name === table.name ? 'page' : 'false');
    button.onclick = () => select(table.name); $('tables').append(button);
  }
}
function select(name, filters = {}) {
  state.table = state.tables.find(t => t.name === name); if (!state.table) return;
  Object.assign(state, {filters, page: 1, q: '', sort: '', direction: 'asc'}); $('search').value = '';
  $('title').textContent = name; menu(); structure(); tab(false); load();
}
function tab(structure) {
  $('dataView').hidden = structure; $('structureView').hidden = !structure;
  for (const [id, active] of [['dataTab', !structure], ['structureTab', structure]]) {$(id).classList.toggle('active', active); $(id).setAttribute('aria-pressed', String(active));}
}
function structure() {
  const table = $('columns'); table.replaceChildren();
  const head = node('tr'); for (const name of ['Columna', 'Tipo', 'Clave', 'Acepta NULL', 'Visibilidad']) head.append(node('th', name));
  const thead = node('thead'); thead.append(head); table.append(thead); const body = node('tbody');
  for (const col of state.table.columns) {const row = node('tr'); for (const value of [col.name, col.type, col.key_type || '—', col.nullable === 'YES' ? 'Sí' : 'No', col.hidden ? 'Protegida' : 'Visible']) row.append(node('td', value)); body.append(row);} table.append(body);
  $('relations').replaceChildren(); const links = relations(); $('metricRelations').textContent = links.length;
  for (const r of links) $('relations').append(node('div', `${r.source} (${r.columns.map(c => c.source).join(', ')}) → ${r.target} (${r.columns.map(c => c.target).join(', ')})`, 'relation'));
  if (!links.length) $('relations').append(node('p', 'Esta tabla no tiene relaciones declaradas.'));
}
function paging() { $('prev').disabled = state.loading || state.page <= 1; $('next').disabled = state.loading || state.page * state.size >= state.total; }
async function load() {
  if (!state.table) return;
  const id = ++state.request; state.loading = true; paging(); $('grid').replaceChildren(); $('metricRows').textContent = '—'; $('pageInfo').textContent = 'Consultando…'; status('Consultando registros…');
  $('filterBar').hidden = !Object.keys(state.filters).length;
  $('filterText').textContent = Object.entries(state.filters).map(([k,v]) => `${k} = ${format(v)}`).join(' · ');
  const params = new URLSearchParams({q: state.q, filters: JSON.stringify(state.filters), page: state.page, size: state.size, sort: state.sort, direction: state.direction});
  try {
    const data = await api('tables/' + encodeURIComponent(state.table.name) + '?' + params);
    if (id !== state.request) return;
    state.page = data.page; state.total = data.total; $('metricRows').textContent = data.total.toLocaleString('es');
    render(data.rows); status(data.total ? 'Selecciona “Ver” para explorar un registro y sus relaciones.' : 'No hay registros que coincidan con esta consulta.');
    $('pageInfo').textContent = `Página ${data.page} de ${Math.max(1, Math.ceil(data.total / data.size))} · ${data.total} registros`;
  } catch (error) {if (id === state.request) {state.total = 0; status(error.message, true); $('pageInfo').textContent = 'Consulta no disponible';}}
  finally {if (id === state.request) {state.loading = false; paging();}}
}
function render(rows) {
  const table = $('grid'); const head = node('tr'); head.append(node('th', 'Detalle'));
  for (const col of state.table.columns) {
    const th = node('th');
    if (col.hidden) th.textContent = col.name + ' · protegido';
    else {const button = node('button', col.name + (state.sort === col.name ? (state.direction === 'asc' ? ' ↑' : ' ↓') : ' ↕')); button.onclick = () => {state.direction = state.sort === col.name && state.direction === 'asc' ? 'desc' : 'asc'; state.sort = col.name; state.page = 1; load();}; th.append(button);}
    head.append(th);
  }
  const thead = node('thead'); thead.append(head); table.append(thead); const tbody = node('tbody');
  for (const row of rows) {
    const tr = node('tr'); const action = node('td'); const button = node('button', 'Ver'); button.onclick = () => detail(row); action.append(button); tr.append(action);
    for (const col of state.table.columns) {const text = col.hidden ? '••••••' : format(row[col.name]); const td = node('td', text); td.title = text; tr.append(td);} tbody.append(tr);
  } table.append(tbody);
}
function detail(row) {
  $('detailTitle').textContent = state.table.name; $('fields').replaceChildren(); $('links').replaceChildren();
  for (const col of state.table.columns) $('fields').append(node('dt', col.name), node('dd', col.hidden ? 'Campo protegido' : format(row[col.name])));
  let count = 0;
  for (const relation of relations()) {
    const directions = []; if (relation.source === state.table.name) directions.push(true); if (relation.target === state.table.name) directions.push(false);
    for (const forward of directions) {
      const target = forward ? relation.target : relation.source; const filters = {}; let valid = true;
      for (const pair of relation.columns) {const value = row[forward ? pair.source : pair.target]; if (value === null || value === undefined) valid = false; filters[forward ? pair.target : pair.source] = value;}
      if (!valid) continue;
      const button = node('button', `${forward ? 'Ver referencia' : 'Ver relacionados'}: ${target} · ${Object.entries(filters).map(([k,v]) => `${k}=${format(v)}`).join(', ')}`, 'relation');
      button.onclick = () => {$('detail').close(); select(target, filters);}; $('links').append(button); count++;
    }
  }
  if (!count) $('links').append(node('p', 'No hay referencias disponibles para este registro.'));
  $('detail').showModal();
}
async function init() {
  $('refresh').disabled = true; status('Leyendo las tablas de Aiven…');
  try {const data = await api('schema'); state.tables = data.tables; $('metricTables').textContent = $('tableCount').textContent = state.tables.length; menu();
    const current = state.table && state.tables.find(t => t.name === state.table.name);
    if (current) {state.table = current; structure(); await load();} else if (state.tables.length) select(state.tables[0].name); else status('La base de datos no contiene tablas.');
    return true;
  } catch (error) {status(error.message, true); return false;} finally {$('refresh').disabled = false;}
}
$('tableSearch').oninput = menu;
$('searchForm').onsubmit = event => {event.preventDefault(); state.q = $('search').value.trim(); state.page = 1; load();};
$('size').onchange = () => {state.size = Number($('size').value); state.page = 1; load();};
$('prev').onclick = () => {state.page--; load();}; $('next').onclick = () => {state.page++; load();};
$('clearFilter').onclick = () => {state.filters = {}; state.page = 1; load();};
$('dataTab').onclick = () => tab(false); $('structureTab').onclick = () => tab(true);
$('closeDetail').onclick = () => $('detail').close(); $('refresh').onclick = init;
$('connectionButton').onclick = () => $('connectionDialog').showModal();
$('connectionForm').onsubmit = async event => {
  event.preventDefault(); $('connectionError').textContent = ''; $('connectSubmit').disabled = true;
  try {
    const url = new URL($('apiOrigin').value);
    if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.search || url.hash || !['', '/'].includes(url.pathname)) throw new Error('Introduce solo el origen del backend, por ejemplo http://127.0.0.1:8000.');
    if (url.origin === location.origin) throw new Error('Esa es la dirección de Live Server. Indica el puerto del backend, normalmente 8000.');
    if (url.protocol !== 'https:' && !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) throw new Error('Usa HTTPS para conectar a un backend fuera de tu equipo.');
    apiOrigin = url.origin;
    state.request++; state.tables = []; state.table = null; state.total = 0;
    $('grid').replaceChildren(); $('tables').replaceChildren();
    if (await init()) {
      $('connectionDialog').close();
      $('connectionButton').textContent = 'Conexión API';
    } else {
      $('connectionError').textContent = $('status').textContent;
    }
  } catch (error) {$('connectionError').textContent = error.message;}
  finally {$('connectSubmit').disabled = false;}
};
if (location.protocol === 'file:') {
  status('Para consultar datos reales, inicia el backend y abre http://127.0.0.1:8000/admin/. Este archivo solo muestra el diseño.', true);
  $('refresh').disabled = true;
} else if (externalPage) {
  $('connectionButton').hidden = false;
  apiOrigin = 'http://127.0.0.1:8000';
  init().then(ok => {
    if (!ok) { $('connectionError').textContent = $('status').textContent; $('connectionDialog').showModal(); }
    else $('connectionButton').textContent = 'Conexión API';
  });
} else {
  init();
}

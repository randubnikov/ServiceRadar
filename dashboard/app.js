const API_URL = 'REPLACE_WITH_API_URL';

function esc(s) {
  return String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

async function loadData() {
  try {
    const services  = await fetch(API_URL + '/services').then(r => r.json());
    const incidents = await fetch(API_URL + '/incidents').then(r => r.json());

    document.getElementById('services-body').innerHTML = services.map(s => `
      <tr>
        <td class="name-cell">${esc(s.name)}</td>
        <td>${esc(s.url)}</td>
        <td>${esc(s.dev_name)}</td>
        <td>${esc(s.dev_email)}</td>
        <td>${s.created_at ? esc(s.created_at.split(' ')[0]) : '-'}</td>
      </tr>
    `).join('');

    document.getElementById('incidents-body').innerHTML = incidents.map(i => `
      <tr>
        <td class="name-cell">${esc(i.name)}</td>
        <td><span class="badge ${esc(i.status.toLowerCase())}">${esc(i.status)}</span></td>
        <td><span class="error-msg">${esc(i.error_message)}</span></td>
        <td>${new Date(esc(i.created_at) + ' UTC').toLocaleDateString('en-GB', {day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit'})}</td>
      </tr>
    `).join('');

    // Count services whose most recent incident is DOWN (incidents ordered DESC by time)
    const latestStatus = {};
    incidents.forEach(i => { if (!(i.name in latestStatus)) latestStatus[i.name] = i.status; });
    const down = Object.values(latestStatus).filter(s => s === 'DOWN').length;

    document.getElementById('total-services').textContent  = services.length;
    document.getElementById('total-incidents').textContent = incidents.length;
    document.getElementById('down-count').textContent      = down;
    document.getElementById('healthy-count').textContent   = services.length - down;
  } catch (err) {
    console.error('Failed to load data:', err);
    document.getElementById('services-body').innerHTML  = '<tr><td colspan="5" class="loading">Error loading data — check console</td></tr>';
    document.getElementById('incidents-body').innerHTML = '<tr><td colspan="4" class="loading">Error loading data — check console</td></tr>';
  }
}

function switchTab(tab, el) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  el.classList.add('active');
  document.getElementById(tab + '-section').classList.add('active');
}

loadData();
setInterval(loadData, 30000);

const API_URL = 'REPLACE_WITH_API_URL';

async function loadData() {
  const services  = await fetch(API_URL + '/services').then(r => r.json());
  const incidents = await fetch(API_URL + '/incidents').then(r => r.json());

  document.getElementById('services-body').innerHTML = services.map(s => `
    <tr>
      <td class="name-cell">${s.name}</td>
      <td>${s.url}</td>
      <td>${s.dev_name}</td>
      <td>${s.dev_email}</td>
      <td>${s.created_at ? s.created_at.split(' ')[0] : '-'}</td>
    </tr>
  `).join('');

  document.getElementById('incidents-body').innerHTML = incidents.map(i => `
    <tr>
      <td class="name-cell">${i.name}</td>
      <td><span class="badge ${i.status.toLowerCase()}">${i.status}</span></td>
      <td><span class="error-msg">${i.error_message}</span></td>
      <td>${new Date(i.created_at + ' UTC').toLocaleString()}</td>
    </tr>
  `).join('');

  const down = new Set(incidents.filter(i => i.status === 'DOWN').map(i => i.name)).size;
  document.getElementById('total-services').textContent  = services.length;
  document.getElementById('total-incidents').textContent = incidents.length;
  document.getElementById('down-count').textContent      = down;
  document.getElementById('healthy-count').textContent   = services.length - down;
}

function switchTab(tab, el) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  el.classList.add('active');
  document.getElementById(tab + '-section').classList.add('active');
}

loadData();
setInterval(loadData, 30000);

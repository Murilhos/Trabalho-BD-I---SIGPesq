// Front-end do SIGPesq: conversa com a API Java (/api/...) usando fetch.
const $ = (seletor) => document.querySelector(seletor);
const dlg = $('#dlg');
const form = $('#form');
const erro = $('#erro');

async function api(url, opcoes) {
  const resposta = await fetch(url, opcoes);
  const dados = await resposta.json();
  if (!resposta.ok) throw new Error(dados.erro || 'Erro inesperado.');
  return dados;
}

function formatarData(iso) {
  if (!iso) return '';
  const [ano, mes, dia] = iso.split('-');
  return `${dia}/${mes}/${ano}`;
}

function celula(tr, texto) {
  const td = document.createElement('td');
  td.textContent = texto;          // textContent evita injecao de HTML (XSS)
  tr.appendChild(td);
  return td;
}

async function carregarProjetos() {
  const projetos = await api('/api/projetos');
  const corpo = $('#corpo');
  corpo.replaceChildren();
  for (const p of projetos) {
    const tr = document.createElement('tr');
    celula(tr, p.codigo);
    celula(tr, p.titulo);
    celula(tr, p.nomeCoordenador);
    const situacao = celula(tr, '');
    const selo = document.createElement('span');
    selo.className = 'selo';
    selo.textContent = p.situacao;
    situacao.appendChild(selo);
    celula(tr, `${formatarData(p.dataInicio)} a ${formatarData(p.dataTermino)}`);
    corpo.appendChild(tr);
  }
  $('#vazio').hidden = projetos.length > 0;
}

async function carregarDocentes() {
  const docentes = await api('/api/docentes');
  const select = $('#coord');
  select.replaceChildren(new Option('Selecione', ''));
  for (const d of docentes) select.appendChild(new Option(d.nome, d.id));
}

$('#novo').onclick = async () => {
  form.reset();
  erro.textContent = '';
  try {
    await carregarDocentes();
    dlg.showModal();
  } catch (e) {
    alert(e.message);
  }
};

$('#cancelar').onclick = () => dlg.close();

form.onsubmit = async (evento) => {
  evento.preventDefault();
  erro.textContent = '';
  const dados = Object.fromEntries(new FormData(form));
  dados.idCoordenador = dados.idCoordenador ? Number(dados.idCoordenador) : null;
  try {
    await api('/api/projetos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(dados),
    });
    dlg.close();
    await carregarProjetos();
  } catch (e) {
    erro.textContent = e.message;   // mostra a mensagem da regra violada (RN-xx)
  }
};

carregarProjetos().catch((e) => { $('#vazio').hidden = false; $('#vazio').textContent = e.message; });

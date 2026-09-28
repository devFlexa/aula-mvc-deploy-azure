const etapas = [...document.querySelectorAll('.checklist input')];
document.querySelectorAll('.lab-step pre').forEach(block => {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'copy-code';
  button.textContent = 'Copiar';
  button.setAttribute('aria-label', `Copiar ${block.dataset.label}`);
  button.addEventListener('click', async () => {
    const code = block.querySelector('code');
    try {
      if (!navigator.clipboard) throw new Error('Clipboard indisponível');
      await navigator.clipboard.writeText(code.textContent);
      button.textContent = 'Copiado!';
    } catch {
      const range = document.createRange();
      range.selectNodeContents(code);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      button.textContent = 'Ctrl+C / ⌘C';
    }
    setTimeout(() => { button.textContent = 'Copiar'; }, 2500);
  });
  block.append(button);
});
etapas.forEach(etapa => etapa.addEventListener('change', () => {
  const total = etapas.filter(item => item.checked).length;
  document.querySelector('#progresso').textContent = `${total} de 7 etapas concluídas`;
  document.querySelector('progress').value = total;
}));
window.addEventListener('beforeprint', () => {
  document.querySelectorAll('details').forEach(item => {
    item.dataset.wasOpen = String(item.open);
    item.open = true;
  });
});
window.addEventListener('afterprint', () => {
  document.querySelectorAll('details').forEach(item => {
    item.open = item.dataset.wasOpen === 'true';
  });
});

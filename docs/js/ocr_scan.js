// Nécessite d'ajouter Tesseract.js
// <script src="https://unpkg.com/tesseract.js@4.0.2/dist/tesseract.min.js"></script>

window.extractTextFromImage = async function (base64Image, callbackId) {
  const { createWorker } = Tesseract;

  const worker = await createWorker({
    logger: m => console.log(m) // optionnel
  });

  await worker.loadLanguage('fra');
  await worker.initialize('fra');

  const result = await worker.recognize(base64Image);
  const text = result.data.text;

  await worker.terminate();

  // On appelle le callback Flutter
  window.dispatchEvent(new CustomEvent('ocrResult-$callbackId', {
    detail: text
  }));
}

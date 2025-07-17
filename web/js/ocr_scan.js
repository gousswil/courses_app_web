// Nécessite d'ajouter Tesseract.js
// <script src="https://unpkg.com/tesseract.js@4.0.2/dist/tesseract.min.js"></script>

window.extractTextFromImage = async function (base64Image, callbackId) {
  console.log("Base64 reçu dans JS :", base64Image.slice(0, 50));
  const { createWorker } = Tesseract;

  const worker = await createWorker({
    logger: m => console.log(m) // optionnel
  });

  await worker.loadLanguage('fra+eng');
  await worker.initialize('fra+eng');

  const result = await worker.recognize(base64Image);
  const text = result.data.text;

  await worker.terminate();

  // On appelle le callback Flutter
  window.dispatchEvent(new CustomEvent('ocrResult-$callbackId', {
    detail: text
  }));
}

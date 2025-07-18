window.extractTextFromImage = async function (base64Image, callbackId) {
  const { createWorker } = Tesseract;

  const worker = await createWorker({
    logger: m => console.log(m),
  });

  await worker.loadLanguage('fra+eng');
  await worker.initialize('fra+eng');

  const result = await worker.recognize(base64Image, {
    tessedit_char_whitelist: '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ€/.:-',
  });

  const text = result.data.text;
  await worker.terminate();

  window.dispatchEvent(new CustomEvent(`ocrResult-${callbackId}`, {
    detail: text
  }));
}

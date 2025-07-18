// Assure-toi que ce script est chargé après :
// <script src="https://unpkg.com/tesseract.js@4.0.2/dist/tesseract.min.js"></script>

window.extractTextFromImage = async function (base64Image, callbackId) {
  if (!base64Image || !callbackId) {
    console.error("⚠️ Paramètres manquants : base64Image ou callbackId");
    return;
  }

  console.log("📸 Base64 image reçue (début) :", base64Image.slice(0, 50));
  console.log("🔄 OCR lancé avec callbackId :", callbackId);

  try {
    const { createWorker } = Tesseract;

    const worker = await createWorker({
      logger: m => console.log("📊 Tesseract log :", m)
    });

    await worker.loadLanguage('fra+eng');
    await worker.initialize('fra+eng');

    const result = await worker.recognize(base64Image);
    const text = result.data.text;

    console.log("✅ Texte OCR détecté :", text);

    await worker.terminate();

    const eventName = `ocrResult-${callbackId}`;
    console.log("📤 Envoi du CustomEvent vers Flutter :", eventName);

    // Envoi du texte OCR à Flutter via CustomEvent
    const event = new CustomEvent(eventName, {
      detail: text
    });

    window.dispatchEvent(event);
    console.log("✅ CustomEvent envoyé avec succès !");
  } catch (err) {
    console.error("❌ Erreur lors de l'OCR :", err);
  }
};

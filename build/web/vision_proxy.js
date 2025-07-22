async function callVisionAPI(base64Image, callbackId) {
  const apiKey = 'TA_CLE_API_ICI'; // remplace ici

  const cleanBase64 = base64Image.split(',')[1]; // important
  console.log("📷 Image (base64) prête, envoi à Google...");

  const body = {
    requests: [
      {
        image: { content: cleanBase64 },
        features: [{ type: 'TEXT_DETECTION' }],
      },
    ],
  };

  try {
    const response = await fetch(
      `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      }
    );

    const result = await response.json();

    if (response.ok) {
      const text = result.responses[0]?.fullTextAnnotation?.text || '';
      console.log("✅ Texte détecté :", text);
      window.dispatchEvent(
        new CustomEvent(`ocrResult-${callbackId}`, { detail: text })
      );
    } else {
      console.error("❌ Erreur API Vision :", result.error);
    }
  } catch (err) {
    console.error("💥 Erreur réseau ou API :", err);
  }
}

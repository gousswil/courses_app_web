// Ajoute ce fichier dans ton projet Flutter Web, côté public/HTML
async function callVisionAPI(base64Image, callbackId) {
  const apiKey = 'fcb0e64f503d093f321f748d58a72e5e782da7b5';

  const response = await fetch(
    `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        requests: [
          {
            image: { content: base64Image.split(',')[1] },
            features: [{ type: 'TEXT_DETECTION' }],
          },
        ],
      }),
    }
  );

  const result = await response.json();
  const text = result.responses[0]?.fullTextAnnotation?.text || '';

  window.dispatchEvent(
    new CustomEvent(`ocrResult-${callbackId}`, { detail: text })
  );
}

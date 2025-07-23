async function extractTextFromImage(base64Image, callbackId) {
  const apiKey = 'AIzaSyBk-HulAqVpDul1fthoodfgmb3M2w9sx78'; // Remplace par ta vraie clé
  const endpoint = `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`;

  const imageBase64 = base64Image.split(',')[1]; // Supprime le préfixe data:image/png;base64,

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      body: JSON.stringify({
        requests: [
          {
            image: { content: imageBase64 },
            features: [{ type: 'TEXT_DETECTION' }],
          },
        ],
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (
      !data.responses ||
      !data.responses[0] ||
      !data.responses[0].fullTextAnnotation
    ) {
      throw new Error('Texte non trouvé');
    }

    const text = data.responses[0].fullTextAnnotation.text;
    const result = analyzeTicketText(text);

    // ✅ Envoi à Flutter via CustomEvent
    const event = new CustomEvent(`ocrResult-${callbackId}`, {
      detail: JSON.stringify(result),
    });
    window.dispatchEvent(event);
  } catch (err) {
    console.error('Erreur API Vision :', err);
    const event = new CustomEvent(`ocrResult-${callbackId}`, {
      detail: JSON.stringify({
        error: 'Erreur OCR',
        text: '',
      }),
    });
    window.dispatchEvent(event);
  }
}

function analyzeTicketText(text) {
  const lines = text.split('\n').map(l => l.trim()).filter(Boolean);
  const fullTextLower = text.toLowerCase();

  // 💰 Montant total : première ligne avec "total" et un montant
  let total = null;
  total=extractTotal(text);
  console.log("Montant total : "+total);
 /*  for (const line of lines) {
    if (/total/i.test(line) && /\d+[.,]\d{2}/.test(line)) {
      const match = line.match(/(\d+[.,]\d{2})/);
      if (match) {
        total = match[1].replace(',', '.');
        break;
      }
    }
  } */

  // 📅 Date : dernière date détectée
  const dateRegex = /\b(\d{2}[\/\-]\d{2}[\/\-](\d{2}|\d{4}))\b/g;
  const allDates = [...text.matchAll(dateRegex)].map(m => m[1]);
  let parsedDate = null;
  if (allDates.length > 0) {
    const last = allDates[allDates.length - 1];
    const [d, m, y] = last.split(/[\/\-]/);
    const year = y.length === 2 ? '20' + y : y;
    parsedDate = `${year}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`;
  }

  // 🏷️ Catégorie : par mots-clés
  const keywordToCategory = {
    'super u': 'Alimentaire',
    'carrefour': 'Alimentaire',
    'intermarché': 'Alimentaire',
    'monoprix': 'Alimentaire',
    'leclerc': 'Alimentaire',
    'picard': 'Alimentaire',
    'pharmacie': 'Santé',
    'docteur': 'Santé',
    'hopital': 'Santé',
    'train': 'Transport',
    'sncf': 'Transport',
    'uber': 'Transport',
    'essence': 'Transport',
    'carburant': 'Transport',
    'cinema': 'Loisir',
    'netflix': 'Loisir',
    'spotify': 'Loisir',
    'fnac': 'Loisir',
    'restaurant': 'Alimentaire',
    'mcdo': 'Alimentaire',
    'burger king': 'Alimentaire',
    'kfc': 'Alimentaire',
  };

  let matchedCategory = 'Autre';
  for (const key in keywordToCategory) {
    if (fullTextLower.includes(key)) {
      matchedCategory = keywordToCategory[key];
      break;
    }
  }

  return {
    text,
    total,
    date: parsedDate,
    category: matchedCategory,
  };
}

function extractTotal(text) {
  const lines = text.split('\n');
  /* let totalLine = lines.find(line =>
    /total\s*[:\-]?\s*\d+[.,]\d{2}/i.test(line)
  ); */
  let totalLine = lines.find(line =>
  /total\s+(\d+\s+)*\d+\s*(?:€|euros?)?|(?:total|ttc|eur|montant)\s+\d+\s*(?:€|euros?)?/i.test(line)
);

  if (!totalLine) {
    // Fallback : chercher juste le plus gros montant
    const allAmounts = [...text.matchAll(/\d+[.,]\d{2}/g)].map(m => parseFloat(m[0].replace(',', '.')));
    const maxAmount = Math.max(...allAmounts);
    return maxAmount ? maxAmount.toFixed(2) : null;
  }

  const match = totalLine.match(/\d+[.,]\d{2}/);
  return match ? match[0].replace(',', '.') : null;
}

// ✅ Exposer la fonction à Flutter
window.callVisionAPI = function (base64Image, callbackId) {
  extractTextFromImage(base64Image, callbackId);
};
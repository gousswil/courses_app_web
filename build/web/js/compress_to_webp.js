  function analyzeTicketText(text) {
      const lines = text.split('\n').map(l => l.trim()).filter(Boolean);
      const fullTextLower = text.toLowerCase();
      console.log("Text brut 2 : "+text);
      // 💰 Montant total : première ligne avec "total" et un montant
      let total = null;
      total=extractTotal(text);
      console.log("Montant total : "+total);


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
        'biocoop': 'Alimentaire',
        'U) express': 'Alimentaire',
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
      let montant, montantLine;
        if (/^CARTE BANCAIRE/i.test(lines.join('\n'))) {
            // Extraire directement le montant qui finit par EUR ou €
            montantLine = lines.find(line =>
              /\d+[.,]?\d*\s*(?:€|eur)$/i.test(line)
            );
            if (montantLine) {
              // Extraire le nombre de la ligne
                montant = montantLine.match(/(\d+[.,]?\d*)/)?.[1];
              if (montant) {
                // Normaliser (remplacer virgule par point)
                montant = montant.replace(',', '.');
                // Utiliser directement le montant
                console.log("Montant trouvé:", montant);
                // Votre code pour utiliser le montant...
              }
            }
          }
          else{
              //On va capturer toutes suivant ces criètres jusqu'à rencontrer des lignes contenant de nouveau des mots 
              /* let totalLineIndex = lines.findIndex(line =>
                /montant\s+total|ttc|^(?:total|montant)\s*$|total\s+(\d+\s+)*\d+\s*(?:€|euros?)?|(?:total|eur|montant)\s+\d+\s*(?:€|euros?)?/i.test(line)
              ); */
             let totalLineIndex = lines.findIndex((line, index) =>
                /montant\s+total|ttc|^(?:total|montant)\s*$|total\s+(\d+\s+)*\d+\s*(?:€|euros?|eur)?|(?:total|eur|montant)\s+\d+\s*(?:€|euros?|eur)?/i.test(line) ||
                (/^\s*total\s*$/i.test(line) && [1,2,3].some(i => index + i < lines.length && /^\s*\d+[,.]?\d*\s*(?:€|euros?|eur)\s*$/i.test(lines[index + i])))
              );

              let capturedLines = [];
              if (totalLineIndex !== -1) {
                capturedLines.push(lines[totalLineIndex]);
                
                let textLinesCount = 0; // Compteur de lignes contenant du texte
                
                for (let i = totalLineIndex + 1; i < lines.length; i++) {
                  const currentLine = lines[i];
                  
                  // Si c'est un montant, on l'ajoute et on continue
                  if (/^\s*\d+[,.]?\d*\s*(?:€|euros?|eur)?\s*$/i.test(currentLine)) {
                    capturedLines.push(currentLine);
                    continue;
                  }
                  
                  // Si ça contient des lettres
                  if (/[a-zA-ZÀ-ÿ]/.test(currentLine)) {
                    textLinesCount++;
                    // On accepte maximum 2 lignes de texte après TOTAL
                    if (textLinesCount > 3) {
                      break;
                    }
                    // Sinon on ignore cette ligne et on continue
                    continue;
                  }
                  
                  // Si c'est ni un montant ni du texte (ligne vide, symboles...), on l'ajoute
                  capturedLines.push(currentLine);
                }
              }
                
                console.log("capturedLines : "+ capturedLines);
                let highestNumber = Math.max(...capturedLines.flatMap(line => line.match(/\d+[.,]?\d*/g) || []).map(n => parseFloat(n.replace(',', '.'))));
                console.log("highestNumber found : "+ highestNumber); 
                montant =highestNumber;
          }
          
            if (montant) {
            //const match = totalLine.match(/\d+[.,]\d{2}/);
            return montant;
            }else return null;
    }

async function compressAndSendToVisionAPI(base64Image, callbackId) {
  const image = new Image();
  image.src = base64Image;

  image.onload = async () => {
    const canvas = document.createElement('canvas');
    const maxDim = 1000;

    let width = image.width;
    let height = image.height;

    if (width > maxDim || height > maxDim) {
      const ratio = Math.min(maxDim / width, maxDim / height);
      width = width * ratio;
      height = height * ratio;
    }

    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(image, 0, 0, width, height);

    const compressedBase64 = canvas.toDataURL('image/webp', 0.7).replace(/^data:image\/webp;base64,/, '');

    const body = {
      requests: [
        {
          image: { content: compressedBase64 },
          features: [{ type: "TEXT_DETECTION" }]
        }
      ]
    };

    try {
      const response = await fetch("https://vision.googleapis.com/v1/images:annotate?key=AIzaSyBk-HulAqVpDul1fthoodfgmb3M2w9sx78", {
        method: "POST",
        body: JSON.stringify(body),
        headers: { "Content-Type": "application/json" }
      });

      const json = await response.json();

      if (
      !json.responses ||
      !json.responses[0] ||
      !json.responses[0].fullTextAnnotation
    ) {
      throw new Error('Texte non trouvé');
    }    

      const text = json.responses?.[0]?.fullTextAnnotation?.text ?? '';
      const result = analyzeTicketText(text);
    
      const event = new CustomEvent(`ocrResult-${callbackId}`, {
        detail: {
          text: text,
          compressedImage: 'data:image/webp;base64,' + compressedBase64,
          total: result.total,
          category: result.category,
          date: result.date,
        }
      });

      window.dispatchEvent(event);
    } catch (error) {
      console.error("OCR API error:", error);
      const event = new CustomEvent(`ocrResult-${callbackId}`, {
        detail:JSON.stringify({
        error: 'Erreur OCR',
        text: '',
         compressedImage: `data:image/webp;base64,${compressedBase64}`
      })
        
      });
      window.dispatchEvent(event);
    }
  };

  image.onerror = () => {
    const event = new CustomEvent(`ocrResult-${callbackId}`, {
      detail: {
        text: '',
        compressedImage: ''
      }
    });
    window.dispatchEvent(event);
  };

}

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
        // Vérifier si "CARTE BANCAIRE" apparaît au début (avec espaces/retours à la ligne)
        const useFirstDate = /^\s*CARTE\s+BANCAIRE/i.test(text);
        
        const selectedDate = useFirstDate ? allDates[0] : allDates[allDates.length - 1];
        
        const [d, m, y] = selectedDate.split(/[\/\-]/);
        const year = y.length === 2 ? '20' + y : y;
        parsedDate = `${year}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`;
      }

      // 🏷️ Catégorie : par mots-clés
     /*  const keywordToCategory = {
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
      }; */

      /* for (const key in keywordToCategory) {
        if (fullTextLower.includes(key)) {
          matchedCategory = keywordToCategory[key];
          break;
        }
      } */
     // Variables pour stocker les résultats
      // Variables pour stocker les résultats
       let storeName = null;
        let category = 'Autre';
        let confidence = 0;

        const textUpper = text.toUpperCase();

        // 1. Détecter les tickets CB et leur attribuer "Autre"
        if (textUpper.includes('CARTE BANCAIRE') || textUpper.includes('CB COMPTANT')) {
          category = 'Autre';
          confidence = 0.9;
          storeName = 'CARTE BANCAIRE';
        } else {
          // 2. Détection des enseignes avec contexte plus précis
          const knownStores = {
            'SUPER U': 'Alimentation',
            'U EXPRESS': 'Alimentation', 
            'CARREFOUR': 'Alimentation',
            'LECLERC': 'Alimentation',
            'MCDONALD': 'Restauration',
            'KFC': 'Restauration',
            'SHELL': 'Carburant',
            'PHARMACIE': 'Santé'
          };

          // Détecter les enseignes normales (sauf TOTAL)
          for (const [store, storeCategory] of Object.entries(knownStores)) {
            if (textUpper.includes(store)) {
              storeName = store;
              category = storeCategory;
              confidence = 0.9;
              break;
            }
          }

          // Traitement spécial pour TOTAL (station-service)
          if (category === 'Autre') {
            const lines = text.split('\n');
            
            // TOTAL est une enseigne si elle apparaît dans les premières lignes (nom du magasin)
            const firstLines = lines.slice(0, 5).join(' ').toUpperCase();
            
            if (firstLines.includes('TOTAL') && 
                (firstLines.includes('STATION') || 
                firstLines.includes('ESSENCE') || 
                firstLines.includes('CARBURANT') ||
                /TOTAL\s+(?:ACCESS|ENERGIES|MARKETING)/i.test(firstLines))) {
              storeName = 'TOTAL';
              category = 'Carburant';
              confidence = 0.9;
            }
          }

          // 3. Si aucune enseigne trouvée, analyser le contenu avec système de score
          if (category === 'Autre') {
            const productKeywords = {
              'Alimentation': ['CHIPS', 'PAIN', 'LAIT', 'FROMAGE', 'VIANDE', 'LEGUME', 'FRUIT', 'YAOURT', 'BIERE', 'VIN', 'EAU', 'JUS', 'PATES', 'RIZ', 'CONSERVE', 'SURGELE'],
              'Carburant': ['ESSENCE', 'DIESEL', 'GAZOLE', 'CARBURANT', 'SUPER', 'SP95', 'SP98', 'GASOIL'],
              'Santé': ['MEDICAMENT', 'SIROP', 'COMPRIMES', 'PANSEMENT', 'VITAMINE', 'HOMEOPATHIE', 'ORDONNANCE'],
              'Mode': ['JEAN', 'CHEMISE', 'ROBE', 'CHAUSSURE', 'SAC', 'VETEMENT', 'PANTALON', 'PULL', 'MANTEAU'],
              'Beauté': ['PARFUM', 'SHAMPOING', 'CREME', 'MAQUILLAGE', 'DENTIFRICE', 'COSMETIQUE', 'BROSSE'],
              'Maison': ['LESSIVE', 'PRODUIT MENAGER', 'EPONGE', 'AMPOULE', 'PILE', 'VAISSELLE', 'DECO'],
              'Bricolage': ['VIS', 'CLOU', 'PEINTURE', 'OUTIL', 'PERCEUSE', 'MARTEAU', 'BOIS', 'PLANCHE'],
              'Transport': ['TICKET', 'ABONNEMENT', 'METRO', 'BUS', 'TRAIN', 'PARKING', 'PEAGE', 'TAXI']
            };
            
            const categoryScores = {};
            
            for (const [categoryName, keywords] of Object.entries(productKeywords)) {
              let score = 0;
              
              for (const keyword of keywords) {
                if (textUpper.includes(keyword)) {
                  score++;
                }
              }
              
              if (score > 0) {
                categoryScores[categoryName] = score;
              }
            }
            
            if (Object.keys(categoryScores).length > 0) {
              const bestCategory = Object.entries(categoryScores).reduce((max, [cat, score]) => 
                score > max.score ? { category: cat, score } : max, 
                { category: '', score: 0 }
              );
              
              category = bestCategory.category;
              confidence = 0.6;
            }
          }
        }

        console.log(`Enseigne: ${storeName}`);
        console.log(`Catégorie: ${category}`);
        console.log(`Confiance: ${confidence}`);


      return {
        text,
        total,
        date: parsedDate,
        category: category,
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
                  // Code existant quand TOTAL est trouvé
                  capturedLines.push(lines[totalLineIndex]);                                  
                  let textLinesCount = 0;                                  
                  for (let i = totalLineIndex + 1; i < lines.length; i++) {                   
                      const currentLine = lines[i];                                      
                      if (/^\s*\d+[,.]?\d*\s*(?:€|euros?|eur)?\s*$/i.test(currentLine)) {                     
                          capturedLines.push(currentLine);                     
                          continue;                   
                      }                                      
                      if (/[a-zA-ZÀ-ÿ]/.test(currentLine)) {                     
                          textLinesCount++;                     
                          if (textLinesCount > 3) {                       
                              break;                     
                          }                     
                          continue;                   
                      }                                      
                      capturedLines.push(currentLine);                 
                  }               
              } else {
                  // NOUVEAU : Quand TOTAL n'est pas trouvé, récupérer le montant le plus élevé
                  console.log("Aucun TOTAL trouvé, recherche du montant le plus élevé...");
                  
                  // Extraire tous les montants du texte
                  const allAmounts = [];
                  
                  lines.forEach((line, index) => {
                      // Regex pour capturer les montants avec €, EUR, euros
                      const amountMatches = line.match(/\d+[,.]?\d*\s*(?:€|euros?|eur)/gi);
                      if (amountMatches) {
                          amountMatches.forEach(match => {
                              const numericValue = parseFloat(match.replace(/[€euros?eur]/gi, '').replace(',', '.').trim());
                              if (numericValue > 0) {
                                  allAmounts.push({
                                      value: numericValue,
                                      original: match.trim(),
                                      line: line.trim(),
                                      lineIndex: index
                                  });
                              }
                          });
                      }
                  });
                  
                  if (allAmounts.length > 0) {
                      // Trier par valeur décroissante et prendre le plus élevé
                      allAmounts.sort((a, b) => b.value - a.value);
                      const highestAmount = allAmounts[0];
                      
                      console.log(`Montant le plus élevé trouvé: ${highestAmount.original} (${highestAmount.value}€)`);
                      
                      // Capturer la ligne contenant le montant le plus élevé
                      capturedLines.push(highestAmount.line);
                      
                      // Optionnel : capturer aussi les lignes adjacentes
                      const targetIndex = highestAmount.lineIndex;
                      for (let i = Math.max(0, targetIndex - 1); i <= Math.min(lines.length - 1, targetIndex + 2); i++) {
                          if (i !== targetIndex && lines[i].trim() !== '') {
                              capturedLines.push(lines[i].trim());
                          }
                      }
                  } else {
                      console.log("Aucun montant trouvé dans le texte");
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
          image: { content: compressedBase64 }, //base64Image.split(',')[1]
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

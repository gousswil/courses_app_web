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
      const text = json.responses?.[0]?.fullTextAnnotation?.text ?? '';

      const event = new CustomEvent(`ocrResult-${callbackId}`, {
        detail: {
          text: text,
          compressedImage: `data:image/webp;base64,${compressedBase64}`
        },
      });

      window.dispatchEvent(event);
    } catch (error) {
      console.error("OCR API error:", error);
      const event = new CustomEvent(`ocrResult-${callbackId}`, {
        detail: {
          text: '',
          compressedImage: `data:image/webp;base64,${compressedBase64}`
        }
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

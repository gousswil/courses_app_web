import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:js' as js;
import 'package:js/js_util.dart' show allowInterop;
import 'services/indexeddb_service.dart';

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _categoryController = TextEditingController();
  final IndexedDbService _indexedDbService = IndexedDbService();

  bool _isAnalyzing = false;
  

  String _selectedCategory = 'Alimentaire';
  DateTime _selectedDate = DateTime.now();
  String? _ocrSummary;
  String? _ticketImageBase64;
  String? _ticketImageId;


    bool _showMobileOptions = false;
    

    bool get _isMobile {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('android') || userAgent.contains('iphone') || userAgent.contains('ipad');
    }

    @override
    void initState() {
      super.initState();
      _indexedDbService.init(); // 🔑 Initialisation de IndexedDB
    }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

      void _onScanTicketPressed() {
        if (_isMobile) {
          setState(() {
            _showMobileOptions = true;
          });
        } else {
          _uploadAndScanImage();
        }
      }

     void _uploadAndScanImage({bool useCamera = false}) {
        final uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/*';

        if (useCamera) {
          uploadInput.setAttribute('capture', 'environment'); // ou 'user' pour caméra frontale
        }

        uploadInput.click();

        uploadInput.onChange.listen((event) {
          final file = uploadInput.files?.first;
          if (file == null) return;

          final reader = html.FileReader();
          reader.readAsDataUrl(file);
           reader.onLoadEnd.listen((event) {
              final base64Image = reader.result as String;
              _ticketImageBase64 = base64Image;

              final callbackId = 'ocr_callback_${DateTime.now().millisecondsSinceEpoch}';
              final eventKey = "ocrResult-$callbackId";

              html.EventListener? listener;

              listener = allowInterop((e) async {
                final customEvent = e as html.CustomEvent;
                final detail = customEvent.detail as Map;

                final text = detail['text'] as String;
                final compressedBase64 = detail['compressedImage'] as String;

                // ✅ Créer un ID unique pour l'image
                final imageId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';

                // ✅ Convertir et sauvegarder dans IndexedDB
                final Uint8List imageBytes = base64Decode(
                  compressedBase64.split(',').last,
                );
                await _indexedDbService.saveImage(imageId, imageBytes); // Instance globale du service

                // ✅ Créer la dépense avec miniature et imageId
                final expense = {
                  'amount': _amountController.text,
                  'category': _selectedCategory,
                  'date': _selectedDate.toIso8601String(),
                  'thumbnail': 'data:image/webp;base64,$compressedBase64',
                  'imageId': imageId,
                };

                // ✅ Enregistrer dans localStorage
                final List<String> expenses = (html.window.localStorage['expenses'] != null)
                    ? List<String>.from(json.decode(html.window.localStorage['expenses']!))
                    : [];
                expenses.add(json.encode(expense));
                html.window.localStorage['expenses'] = json.encode(expenses);

                // ✅ Mettre à jour les champs à partir de l’OCR
                updateFormFieldsFromOCR(text);

                // ✅ Réinitialiser l’état
                setState(() {
                  _isAnalyzing = false;
                });

                // ✅ Nettoyer le listener
                if (listener != null) {
                  html.window.removeEventListener(eventKey, listener);
                }
              });

              // ✅ Attacher le listener
              html.window.addEventListener(eventKey, listener);

              // ✅ Déclencher l'état d'analyse
              setState(() {
                _isAnalyzing = true;
                _ocrSummary = null;
              });

              // ✅ Lancer l’appel JS
              if (!js.context.hasProperty('compressAndSendToVisionAPI')) {
                print("❌ Fonction compressAndSendToVisionAPI non disponible !");
                return;
              }

              js.context.callMethod('compressAndSendToVisionAPI', [base64Image, callbackId]);
            });         

          setState(() {
            _showMobileOptions = false;
          });
        });
      }

    void updateFormFieldsFromOCR(String text) {
          print('🔍 Texte OCR brut : $text');

          final dateRegex = RegExp(r'(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{2,4})');
          final amountRegex = RegExp(r'(\d+([.,]\d{2}))');
          final categoryRegex = RegExp(r'(alimentation|loisir|transport|santé|logement)', caseSensitive: false);

          // ✅ Cherche une date
          final dateMatch = dateRegex.firstMatch(text);
          if (dateMatch != null) {
            final rawDate = dateMatch.group(1)!;
            try {
              // Gère plusieurs formats
              final parsedDate = _parseDate(rawDate);
              setState(() {
                _selectedDate = parsedDate;
              });
            } catch (e) {
              print('❌ Erreur de parsing de la date : $e');
            }
          } else {
            print("❌ Aucune date détectée");
          }

          // ✅ Montant
          final amountMatch = amountRegex.allMatches(text).lastOrNull;
          if (amountMatch != null) {
            final amountStr = amountMatch.group(1)!.replaceAll(',', '.');
            _amountController.text = amountStr;
          }

          // ✅ Catégorie
          final categoryMatch = categoryRegex.firstMatch(text);
          if (categoryMatch != null) {
            _selectedCategory = categoryMatch.group(0)!.toLowerCase();
            print("🏷️ Catégorie détectée : $_selectedCategory");
          } else {
            print("🏷️ Catégorie non reconnue");
          }
        }


    DateTime _parseDate(String rawDate) {
      // Gère formats du type : 12/07/2025, 12-07-25, 12.07.2025
      final separators = ['/', '-', '.'];
      for (final sep in separators) {
        if (rawDate.contains(sep)) {
          final parts = rawDate.split(sep);
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            var year = int.tryParse(parts[2]);
            if (year != null && year < 100) {
              year += 2000; // Corrige les années en deux chiffres
            }
            if (day != null && month != null && year != null) {
              return DateTime(year, month, day);
            }
          }
        }
      }
      throw FormatException('Format de date non reconnu : $rawDate');
    }



  void _saveExpense() {
    final amount = _amountController.text;
    if (amount.isEmpty) return;

    final expense = {
      'amount': amount,
      'category': _selectedCategory,
      'date': _selectedDate.toIso8601String()
      /* 'thumbnail': compressedBase64,  */// ✅ miniature WebP
      /* 'imageId': imageId, */ // On y revient
    };

    final List<String> expenses =
        (html.window.localStorage['expenses'] != null)
            ? List<String>.from(json.decode(html.window.localStorage['expenses']!))
            : [];

    expenses.add(json.encode(expense));
    html.window.localStorage['expenses'] = json.encode(expenses);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('💾 Dépense ajoutée')),
    );

    _amountController.clear();
    _dateController.clear();
    setState(() {
      _selectedCategory = 'Alimentaire';
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  @override
      Widget build(BuildContext context) {
        final isSmallScreen = MediaQuery.of(context).size.width < 600;
        return Scaffold(
          appBar: AppBar(title: const Text('Ajouter une dépense')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ElevatedButton.icon(
                  onPressed: _isAnalyzing
                      ? null // 🔒 Désactive le bouton si analyse en cours
                      : () {
                          if (isSmallScreen) {
                            setState(() {
                              _showMobileOptions = !_showMobileOptions;
                            });
                          } else {
                            _uploadAndScanImage(useCamera: false);
                          }
                        },
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Scanner un ticket'),
                ),
               if (_showMobileOptions && !_isAnalyzing) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _uploadAndScanImage(useCamera: true),
                    child: const Text('📷 Prendre une photo'),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => _uploadAndScanImage(useCamera: false),
                    child: const Text('📁 Choisir un fichier'),
                  ),
                ],
                if (_isAnalyzing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 12),
                        Text('Analyse du ticket en cours...'),
                      ],
                    ),
                  ),
                if (_ocrSummary != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _ocrSummary!,
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Montant (€)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: const [
                    DropdownMenuItem(value: 'Alimentaire', child: Text('Alimentaire')),
                    DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'Hygiène', child: Text('Hygiène')),
                    DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Date'),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveExpense,
                  child: const Text('Ajouter la dépense'),
                ),
              ],
            ),
          ),
        );
      }
}

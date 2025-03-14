import 'package:ciyue/ai.dart';
import 'package:ciyue/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import "package:ciyue/src/generated/i18n/app_localizations.dart";

class AiTranslatePage extends StatefulWidget {
  const AiTranslatePage({super.key});

  @override
  State<AiTranslatePage> createState() => _AiTranslatePageState();
}

class _AiTranslatePageState extends State<AiTranslatePage> {
  String _inputText = '';
  String _translatedText = '';
  String _sourceLanguage = 'English';
  String _targetLanguage = 'Chinese';
  bool _isRichOutput = true;
  bool _isLoading = false;

  void _showMoreDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.more),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<bool>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.outputType,
                  border: const OutlineInputBorder(),
                ),
                value: _isRichOutput,
                items: [
                  DropdownMenuItem(
                      value: true,
                      child: Text(AppLocalizations.of(context)!.richOutput)),
                  DropdownMenuItem(
                      value: false,
                      child: Text(AppLocalizations.of(context)!.simpleOutput)),
                ],
                onChanged: (bool? newValue) {
                  setState(() {
                    _isRichOutput = newValue!;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _translateText() async {
    setState(() {
      _isLoading = true;
      _translatedText = '';
    });

    try {
      final ai = AI(
        provider: settings.aiProvider,
        model: settings.getAiProviderConfig(settings.aiProvider)['model'] ?? '',
        apikey:
            settings.getAiProviderConfig(settings.aiProvider)['apiKey'] ?? '',
      );

      final prompt = _isRichOutput
          ? 'Translate the following text from $_sourceLanguage to $_targetLanguage. Please provide multiple translation options if possible. You must output the translation entirely and exclusively in $_targetLanguage: $_inputText'
          : 'Translate this $_sourceLanguage sentence to $_targetLanguage, only return the translated text: "$_inputText"';
      final translationResult = await ai.request(prompt);

      setState(() {
        _translatedText = translationResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _translatedText = 'Error: Failed to translate. $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: AppLocalizations.of(context)!.more,
            onPressed: _showMoreDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildInput(),
            buildLanguageSelection(),
            buildTranslateButton(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            buildTranslatedText(),
          ],
        ),
      ),
    );
  }

  Padding buildInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.enterTextToTranslate,
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) {
          setState(() {
            _inputText = text;
          });
        },
      ),
    );
  }

  Expanded buildTranslatedText() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Markdown(
          selectable: true,
          data: _translatedText,
        ),
      ),
    );
  }

  Padding buildTranslateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: _inputText.isEmpty
            ? null
            : _translateText, // Disable button if input is empty
        child: Text(AppLocalizations.of(context)!.translate),
      ),
    );
  }

  Row buildLanguageSelection() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.sourceLanguage,
              border: const OutlineInputBorder(),
            ),
            value: _sourceLanguage,
            items: <String>['English', 'Chinese']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _sourceLanguage = newValue!;
              });
            },
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.targetLanguage,
              border: const OutlineInputBorder(),
            ),
            value: _targetLanguage,
            items: <String>['English', 'Chinese']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _targetLanguage = newValue!;
              });
            },
          ),
        ),
      ],
    );
  }
}

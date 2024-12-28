import "dart:convert";
import "dart:io";

import "package:ciyue/database/app.dart";
import "package:ciyue/dictionary.dart";
import "package:ciyue/main.dart";
import "package:ciyue/settings.dart";
import "package:ciyue/widget/text_buttons.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:go_router/go_router.dart";
import "package:html_unescape/html_unescape_small.dart";
import "package:mime/mime.dart";
import "package:path/path.dart";

class Button extends StatefulWidget {
  final String word;

  const Button({super.key, required this.word});

  @override
  State<Button> createState() => _ButtonState();
}

class LocalResourcesPathHandler extends CustomPathHandler {
  final int dictId;

  LocalResourcesPathHandler({required super.path, required this.dictId});

  @override
  Future<WebResourceResponse?> handle(String path) async {
    if (path == "favicon.ico") {
      return WebResourceResponse(data: null);
    }

    if (path == dictManager.dicts[dictId]!.fontName) {
      final file = File(dictManager.dicts[dictId]!.fontPath!);
      final data = await file.readAsBytes();
      return WebResourceResponse(data: data, contentType: lookupMimeType(path));
    }

    try {
      Uint8List? data;

      if (dictManager.dicts[dictId]!.readerResource == null) {
        // Find resource under directory if no mdd
        final file = File("${dirname(dictManager.dicts[dictId]!.path)}/$path");
        data = await file.readAsBytes();
      } else {
        try {
          final result = await dictManager.dicts[dictId]!.db.readResource(path);
          data = await dictManager.dicts[dictId]!.readerResource!.readOne(
              result.blockOffset,
              result.startOffset,
              result.endOffset,
              result.compressedSize);
        } catch (e) {
          // Find resource under directory if resource is not in mdd
          final file =
              File("${dirname(dictManager.dicts[dictId]!.path)}/$path");
          data = await file.readAsBytes();
        }
      }
      return WebResourceResponse(data: data, contentType: lookupMimeType(path));
    } catch (e) {
      return WebResourceResponse(data: null);
    }
  }
}

class TagsList extends StatefulWidget {
  final List<WordbookTag> tags;
  final List<int> tagsOfWord;
  final List<int> toAdd;
  final List<int> toDel;

  const TagsList(
      {super.key,
      required this.tags,
      required this.tagsOfWord,
      required this.toAdd,
      required this.toDel});

  @override
  State<StatefulWidget> createState() => _TagsListState();
}

class WebView extends StatelessWidget {
  final String content;
  final int dictId;

  const WebView({super.key, required this.content, required this.dictId});

  @override
  Widget build(BuildContext context) {
    final settings = InAppWebViewSettings(
      useWideViewPort: false,
      algorithmicDarkeningAllowed: true,
      resourceCustomSchemes: ["entry"],
      transparentBackground: true,
      webViewAssetLoader: WebViewAssetLoader(
          domain: "ciyue.internal",
          httpAllowed: true,
          pathHandlers: [LocalResourcesPathHandler(path: "/", dictId: dictId)]),
    );

    InAppWebViewController? webViewController;
    String selectedText = "";

    final locale = AppLocalizations.of(context)!;

    final contextMenu = ContextMenu(
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
      menuItems: [
        ContextMenuItem(
            id: 1,
            title: locale.copy,
            action: () async {
              await webViewController!.clearFocus();
              Clipboard.setData(ClipboardData(text: selectedText));
            }),
        ContextMenuItem(
            id: 2,
            title: locale.lookup,
            action: () async {
              context.push("/word", extra: {"word": selectedText});
            }),
        ContextMenuItem(
            id: 3,
            title: locale.readLoudly,
            action: () async {
              await webViewController!.clearFocus();
              await flutterTts.speak(selectedText);
            })
      ],
      onCreateContextMenu: (hitTestResult) async {
        selectedText = await webViewController?.getSelectedText() ?? "";
      },
    );

    return InAppWebView(
      initialData: InAppWebViewInitialData(
          data: content, baseUrl: WebUri("http://ciyue.internal/")),
      initialSettings: settings,
      contextMenu: contextMenu,
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url;
        if (url!.scheme == "entry") {
          final word = await dictManager.dicts[dictId]!.db.getOffset(
              Uri.decodeFull(url.toString().replaceFirst("entry://", "")));

          final String data = await dictManager.dicts[dictId]!.reader.readOne(
              word.blockOffset,
              word.startOffset,
              word.endOffset,
              word.compressedSize);

          if (context.mounted) {
            context.push("/word", extra: {"content": data, "word": word.key});
          }
        }

        return NavigationActionPolicy.CANCEL;
      },
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onPageCommitVisible: (controller, url) async {
        if (dictManager.dicts[dictId]!.fontName != null) {
          await controller.evaluateJavascript(source: """
const font = new FontFace('Custom Font', 'url(/${dictManager.dicts[dictId]!.fontName})');
font.load();
document.fonts.add(font);
document.body.style.fontFamily = 'Custom Font';
          """);
        }
      },
    );
  }
}

class WebviewDisplay extends StatelessWidget {
  final String word;

  const WebviewDisplay({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        initialIndex: 0,
        length: dictManager.dicts.length,
        child: Scaffold(
            appBar: AppBar(
                leading: BackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      // When opened from context menu
                      SystemChannels.platform
                          .invokeMethod('SystemNavigator.pop');
                    }
                  },
                ),
                bottom: TabBar(
                  tabs: [
                    for (final dict in dictManager.dicts.values)
                      Tab(text: basename(dict.path))
                  ],
                )),
            floatingActionButton: Button(word: word),
            body: TabBarView(children: [
              for (final dict in dictManager.dicts.values)
                FutureBuilder(
                    future: dict.readWord(word),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return WebView(
                          content: snapshot.data!,
                          dictId: dict.id,
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text(AppLocalizations.of(context)!.notFound,
                                style: Theme.of(context).textTheme.titleLarge));
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    })
            ])));
  }
}

class WebviewDisplayDescription extends StatelessWidget {
  const WebviewDisplayDescription({super.key});

  @override
  Widget build(BuildContext context) {
    String html = dictManager.dicts.values.first.reader.header["Description"]!;
    html = HtmlUnescape().convert(html);

    return Scaffold(
        appBar: AppBar(leading: BackButton(
          onPressed: () {
            context.pop();
          },
        )),
        body: WebView(
          content: html,
          dictId: dictManager.dicts.values.first.id,
        ));
  }
}

class _ButtonState extends State<Button> {
  Future<bool>? stared;

  Future<void> autoExport() async {
    if (settings.autoExport &&
        dictManager.dicts.values.first.backupPath != null) {
      final words = await mainDatabase.getAllWords(),
          tags = await mainDatabase.getAllTags();

      final wordsOutput = jsonEncode(words), tagsOutput = jsonEncode(tags);

      final file = File(dictManager.dicts.values.first.backupPath!);

      await file.writeAsString("$wordsOutput\n$tagsOutput");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        buildReadLoudlyButton(context, widget.word),
        buildStarButton(context)
      ],
    );
  }

  Widget buildReadLoudlyButton(BuildContext context, word) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.small(
      foregroundColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: const Icon(Icons.volume_up),
      onPressed: () async {
        await flutterTts.speak(word);
      },
    );
  }

  Widget buildStarButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!;

    return FutureBuilder(
        future: stared,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            return FloatingActionButton.small(
              foregroundColor: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              child: const Icon(Icons.star_outline),
              onPressed: () {},
            );
          }

          return FloatingActionButton.small(
            foregroundColor: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            child: Icon(snapshot.data! ? Icons.star : Icons.star_outline),
            onPressed: () async {
              Future<void> star() async {
                if (snapshot.data!) {
                  await mainDatabase.removeWord(widget.word);
                } else {
                  await mainDatabase.addWord(widget.word);
                }

                await autoExport();
                checkStared();
              }

              if (mainDatabase.tagExist) {
                final tagsOfWord = await mainDatabase.tagsOfWord(widget.word),
                    tags = await mainDatabase.getAllTags();

                final toAdd = <int>[], toDel = <int>[];

                if (!context.mounted) return;

                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(locale.tags),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TagsList(
                              tags: tags,
                              tagsOfWord: tagsOfWord,
                              toAdd: toAdd,
                              toDel: toDel,
                            ),
                          ],
                        ),
                        actions: [
                          TextCloseButton(),
                          TextButton(
                            child: Text(locale.remove),
                            onPressed: () async {
                              await mainDatabase
                                  .removeWordWithAllTags(widget.word);

                              if (context.mounted) context.pop();

                              await autoExport();
                              checkStared();
                            },
                          ),
                          TextButton(
                            child: Text(locale.confirm),
                            onPressed: () async {
                              if (!snapshot.data!) {
                                await mainDatabase.addWord(widget.word);
                              }

                              for (final tag in toAdd) {
                                await mainDatabase.addWord(widget.word,
                                    tag: tag);
                              }

                              for (final tag in toDel) {
                                await mainDatabase.removeWord(widget.word,
                                    tag: tag);
                              }

                              if (context.mounted) context.pop();

                              await autoExport();
                              checkStared();
                            },
                          ),
                        ],
                      );
                    });
              } else {
                await star();
              }
            },
          );
        });
  }

  void checkStared() {
    setState(() {
      stared = mainDatabase.wordExist(widget.word);
    });
  }

  @override
  void initState() {
    super.initState();

    stared = mainDatabase.wordExist(widget.word);
  }
}

class _TagsListState extends State<TagsList> {
  List<int>? oldTagsOfWord;

  @override
  Widget build(BuildContext context) {
    final checkboxListTile = <Widget>[];

    oldTagsOfWord ??= List<int>.from(widget.tagsOfWord);

    for (final tag in widget.tags) {
      checkboxListTile.add(CheckboxListTile(
        title: Text(tag.tag),
        value: widget.tagsOfWord.contains(tag.id),
        onChanged: (value) {
          setState(() {
            if (value == true) {
              if (!oldTagsOfWord!.contains(tag.id)) {
                widget.toAdd.add(tag.id);
              }

              widget.toDel.remove(tag.id);

              widget.tagsOfWord.add(tag.id);
            } else {
              if (oldTagsOfWord!.contains(tag.id)) {
                widget.toDel.add(tag.id);
              }

              widget.toAdd.remove(tag.id);

              widget.tagsOfWord.remove(tag.id);
            }
          });
        },
      ));
    }

    return Column(children: checkboxListTile);
  }
}

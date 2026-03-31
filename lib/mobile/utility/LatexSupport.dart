import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:latext/latext.dart';
import 'package:markdown/markdown.dart' as md;

class LatexElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return LaTexT(
      laTeXCode: Text(element.textContent, style: preferredStyle,),
      onErrorFallback: (text) {return Text(element.textContent, style: preferredStyle,);},
    );
  }
}
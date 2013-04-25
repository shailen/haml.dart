part of haml;

class _HamlEnum {
  final String value;
  const _HamlEnum(this.value);
  String toString() => '* $value *';
}

class _SpecialInstruction extends _HamlEnum {
  static const _SpecialInstruction SELF_CLOSING =
      const _SpecialInstruction('self-closing');

  static const _SpecialInstruction REMOVE_WHITESPACE_SURROUNDING =
      const _SpecialInstruction('remove-whitespace-surrounding');

  static const _SpecialInstruction REMOVE_WHITESPACE_WITHIN =
      const _SpecialInstruction('remove-whitespace-within');

  const _SpecialInstruction(String value) : super(value);
}

class HamlEntityGrammar extends CompositeParser {

  void initialize() {
    def('start', ref('entity').end());

    def('entity', ref('doctype').or(ref('element')).or(ref('text')));

    def('element', ref('named-element').or(ref('implicit-div-element'))
        .seq(ref('attributes').optional())
        .seq(ref('special-instructions').optional())
        .seq(ref('content').optional()));

    def('attributes', ref('html-attributes').or(ref('ruby-attributes')));

    def('html-attributes', char('(')
        .seq(char(')').neg().star())
        .seq(char(')'))
        .flatten());

    def('ruby-attributes', char('{')
        .seq(char('}').neg().star())
        .seq(char('}'))
        .flatten());

    def('text', any().star().flatten());

    def('special-instructions', char('/').or(char('>')).or(char('<')));

    def('implicit-div-element', ref('id-def').or(ref('class-def')).plus());

    def('named-element', ref('element-name')
        .seq(ref('id-def').or(ref('class-def')).star()));

    def('id-def', char('#').seq(ref('css-name')));

    def('class-def', char('.').seq(ref('css-name')));

    def('element-name', char('%').seq(ref('nameToken')));

    // TODO: this is likely wrong for css names. Need to investigate.
    def('css-name', ref('nameToken'));

    def('content', ref('spaces').seq(any().star().flatten()).pick(1));

    def('nameToken', ElementEntry.elementNameParser);

    def('doctype', string('!!!')
        .seq(ref('spaces')
            .seq(word().or(char('.')).plus().flatten())
            .pick(1).optional())
         .pick(-1));

    def('spaces', char(' ').plus());

  }
}

class HamlEntityParser extends HamlEntityGrammar {

  @override
  void initialize() {
    super.initialize();

    action('doctype', (value) => new DocTypeEntry(value));
    action('element', (List value) {
      assert(value.length == 4);

      List head = value[0];
      assert(head.length == 2);
      String name = head[0];

      // TODO: actually support content
      Map<String, List<String>> idAndClassValues = head[1];

      final String attributes = value[1];

      final specialInstructions = value[2];

      bool selfClosing = null;
      if(specialInstructions == '/') {
        selfClosing = true;
      }

      final content = value[3];

      return new ElementEntry(name, selfClosing: selfClosing);
    });

    action('implicit-div-element', (List value) {
      assert(!value.isEmpty);
      Map<String, dynamic> values = { 'ids': [], 'classes': [] };

      // TODO: actually populate the ids and classes
      // TODO: share code w/ named-element when we get there

      return ['div', values];
    });

    action('named-element', (List value) {
      assert(value.length == 2);
      List namedList = value[0];
      assert(namedList.length == 2);
      assert(namedList[0] == '%');

      String name = namedList[1];
      assert(name != null && !name.isEmpty);

      var values = { };

      // TODO: actually populate the ids and classes
      // TODO: share code w/ implicit-div-element when we get there

      return [name, values];
    });

    action('text', (String value) {
      return new StringEntry(value);
    });
  }
}

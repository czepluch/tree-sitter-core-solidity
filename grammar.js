/**
 * Tree-sitter grammar for Core Solidity (.solc).
 *
 * Ground truth: solcore/src/Solcore/Frontend/Parser/SolcoreParser.y
 *               solcore/src/Solcore/Frontend/Lexer/SolcoreLexer.x
 *
 * Precedence ladder mirrors the Happy parser (low -> high):
 *   1  nonassoc  +=  -=
 *   2  left      :            (type ascription)
 *   3  left      ||
 *   4  left      &&
 *   5  nonassoc  !
 *   6  nonassoc  ==  !=
 *   7  nonassoc  <  >  <=  >=
 *   8  left      +  -
 *   9  left      *  /  %
 *   10 left      [           (indexing)
 *   11 left      .           (member access)
 *   12 right     if          (conditional expression)
 *   13 right     else
 */

const PREC = {
  STMT_ASSIGN: 1,
  ASCRIPTION: 2,
  LOR: 3,
  LAND: 4,
  LNOT: 5,
  EQ: 6,
  CMP: 7,
  ADD: 8,
  MUL: 9,
  INDEX: 10,
  MEMBER: 11,
  IF: 12,
  ELSE: 13,
  CALL: 14,
  PROXY: 15,
};

module.exports = grammar({
  name: 'core_solidity',

  externals: $ => [$.block_comment],

  extras: $ => [/\s/, $.line_comment, $.block_comment],

  word: $ => $.identifier,

  conflicts: $ => [],

  rules: {
    source_file: $ => seq(
      repeat($.import_decl),
      repeat($._top_decl),
    ),

    // ----- imports -----

    import_decl: $ => seq(
      'import',
      field('name', $.identifier),
      ';',
    ),

    // ----- top-level declarations -----

    _top_decl: $ => choice(
      $.contract_decl,
      $.function_decl,
      $.class_decl,
      $.instance_decl,
      $.data_decl,
      $.type_synonym,
      $.pragma_decl,
    ),

    // ----- pragma -----

    pragma_decl: $ => seq(
      'pragma',
      field('kind', choice(
        'no-coverage-condition',
        'no-patterson-condition',
        'no-bounded-variable-condition',
      )),
      optional(field('names', commaSep1($.identifier))),
      ';',
    ),

    // ----- data -----

    data_decl: $ => seq(
      'data',
      field('name', $.identifier),
      optional(field('params', $.type_params)),
      optional(seq('=', field('variants', $._data_constrs))),
      ';',
    ),

    _data_constrs: $ => seq(
      $.data_variant,
      repeat(seq('|', $.data_variant)),
    ),

    data_variant: $ => seq(
      field('name', $.identifier),
      optional(field('args', $.type_args)),
    ),

    // ----- type synonym -----

    type_synonym: $ => seq(
      'type',
      field('name', $.identifier),
      optional(field('params', $.type_params)),
      '=',
      field('type', $._type),
      ';',
    ),

    type_params: $ => seq('(', commaSep1($.identifier), ')'),
    type_args:   $ => seq('(', commaSep1($._type), ')'),

    // ----- class -----

    class_decl: $ => seq(
      optional(field('sig_prefix', $.sig_prefix)),
      'class',
      field('self', $.identifier),
      ':',
      field('name', $.identifier),
      optional(field('params', $.type_params)),
      field('body', $.class_body),
    ),

    class_body: $ => seq('{', repeat($.signature), '}'),

    signature: $ => seq(
      optional(field('sig_prefix', $.sig_prefix)),
      'function',
      field('name', $.identifier),
      '(',
      optional(field('params', $.param_list)),
      ')',
      optional(seq('->', field('return_type', $._type))),
      ';',
    ),

    // ----- instance -----

    instance_decl: $ => seq(
      optional(field('sig_prefix', $.sig_prefix)),
      optional(field('default', 'default')),
      'instance',
      field('head', $._type),
      ':',
      field('class', $.identifier),
      optional(field('args', $.type_args)),
      field('body', $.instance_body),
    ),

    instance_body: $ => seq('{', repeat($.function_decl), '}'),

    // ----- forall / constraints -----

    sig_prefix: $ => seq(
      'forall',
      repeat1($.identifier),
      '.',
      optional(seq(commaSep1($.constraint), '=>')),
    ),

    constraint: $ => seq(
      field('head', $._type),
      ':',
      field('class', $.identifier),
      optional(field('args', $.type_args)),
    ),

    // ----- contract -----

    contract_decl: $ => seq(
      'contract',
      field('name', $.identifier),
      optional(field('params', $.type_params)),
      field('body', $.contract_body),
    ),

    contract_body: $ => seq('{', repeat($._contract_member), '}'),

    _contract_member: $ => choice(
      $.field_decl,
      $.data_decl,
      $.function_decl,
      $.constructor_decl,
    ),

    field_decl: $ => seq(
      field('name', $.identifier),
      ':',
      field('type', $._type),
      optional(seq('=', field('value', $._expression))),
      ';',
    ),

    constructor_decl: $ => seq(
      'constructor',
      '(',
      optional(field('params', $.param_list)),
      ')',
      field('body', $.body),
    ),

    // ----- function -----

    function_decl: $ => seq(
      optional(field('sig_prefix', $.sig_prefix)),
      'function',
      field('name', $.identifier),
      '(',
      optional(field('params', $.param_list)),
      ')',
      optional(seq('->', field('return_type', $._type))),
      field('body', choice($.body, $.expression_body)),
    ),

    // Rust-style short return: `function f(x) { 2*x }`
    expression_body: $ => seq('{', $._expression, '}'),

    param_list: $ => commaSep1($.param),

    param: $ => seq(
      field('name', $.identifier),
      optional(seq(':', field('type', $._type))),
    ),

    body: $ => seq('{', repeat($._statement), '}'),

    // ----- statements -----

    _statement: $ => choice(
      $.let_decl,
      $.assign_stmt,
      $.compound_assign_stmt,
      $.return_stmt,
      $.match_stmt,
      $.assembly_stmt,
      $.if_stmt,
      $.expression_statement,
    ),

    let_decl: $ => seq(
      'let',
      field('name', $.identifier),
      optional(seq(':', field('type', $._type))),
      optional(seq('=', field('value', $._expression))),
      ';',
    ),

    // Any expression can appear on the LHS of an assignment (real parser is
    // even more permissive - any Expr). Disambiguation vs expression_statement
    // is declared in the conflicts block above.
    _expression_statement_lhs: $ => $._expression,

    assign_stmt: $ => prec(PREC.STMT_ASSIGN, seq(
      field('left',  $._expression_statement_lhs),
      '=',
      field('right', $._expression),
      ';',
    )),

    compound_assign_stmt: $ => prec(PREC.STMT_ASSIGN, seq(
      field('left',  $._expression_statement_lhs),
      field('operator', choice('+=', '-=')),
      field('right', $._expression),
      ';',
    )),

    return_stmt: $ => seq(
      'return',
      field('value', $._expression),
      ';',
    ),

    expression_statement: $ => seq($._expression, ';'),

    if_stmt: $ => prec.right(PREC.ELSE, seq(
      'if',
      '(',
      field('condition', $._expression),
      ')',
      field('consequence', $.body),
      optional(seq('else', field('alternative', $.body))),
    )),

    match_stmt: $ => seq(
      'match',
      field('scrutinees', commaSep1($._expression)),
      '{',
      repeat($.match_arm),
      '}',
    ),

    match_arm: $ => seq(
      '|',
      field('patterns', commaSep1($._pattern)),
      '=>',
      repeat($._statement),
    ),

    // ----- patterns -----

    _pattern: $ => choice(
      $.wildcard_pattern,
      $.literal_pattern,
      $.constructor_pattern,
      $.tuple_pattern,
      $.parenthesized_pattern,
    ),

    wildcard_pattern: $ => '_',
    literal_pattern:  $ => $._literal,

    constructor_pattern: $ => seq(
      field('name', $.identifier),
      optional(field('args', $.pattern_args)),
    ),

    pattern_args: $ => seq('(', commaSep1($._pattern), ')'),

    parenthesized_pattern: $ => seq('(', $._pattern, ')'),

    tuple_pattern: $ => seq(
      '(',
      $._pattern,
      ',',
      commaSep1($._pattern),
      ')',
    ),

    // ----- assembly (Yul injection point) -----

    assembly_stmt: $ => seq('assembly', $.assembly_block),

    // An assembly_block holds balanced braces; actual Yul parsing is deferred
    // to tree-sitter-yul via queries/injections.scm.
    assembly_block: $ => seq(
      '{',
      repeat($._assembly_content),
      '}',
    ),

    _assembly_content: $ => choice(
      $.assembly_block,
      $._assembly_token,
    ),

    // Any run of characters that does not contain a brace. Strings that
    // contain braces will break this (rare in Yul); acceptable for v1.
    _assembly_token: $ => token(prec(-1, /[^{}]+/)),

    // ----- expressions -----

    _expression: $ => choice(
      $.call_expression,
      $.identifier,
      $._literal,
      $.parenthesized_expression,
      $.tuple_expression,
      $.member_expression,
      $.method_call_expression,
      $.index_expression,
      $.lambda_expression,
      $.ascription_expression,
      $.binary_expression,
      $.unary_expression,
      $.ternary_expression,
      $.proxy_expression,
    ),

    call_expression: $ => prec(PREC.CALL, seq(
      field('function', $.identifier),
      field('arguments', $.arguments),
    )),

    arguments: $ => seq('(', optional(commaSep1($._expression)), ')'),

    parenthesized_expression: $ => seq('(', $._expression, ')'),

    // Unit `()` and 2+ element tuples. A one-element "tuple" is just parens.
    tuple_expression: $ => choice(
      seq('(', ')'),
      seq('(', $._expression, ',', commaSep1($._expression), ')'),
    ),

    member_expression: $ => prec.left(PREC.MEMBER, seq(
      field('object', $._expression),
      '.',
      field('property', $.identifier),
    )),

    method_call_expression: $ => prec.left(PREC.MEMBER, seq(
      field('object', $._expression),
      '.',
      field('property', $.identifier),
      field('arguments', $.arguments),
    )),

    index_expression: $ => prec.left(PREC.INDEX, seq(
      field('object', $._expression),
      '[',
      field('index', $._expression),
      ']',
    )),

    lambda_expression: $ => seq(
      'lam',
      '(',
      optional(field('params', $.param_list)),
      ')',
      optional(seq('->', field('return_type', $._type))),
      field('body', $.body),
    ),

    ascription_expression: $ => prec.left(PREC.ASCRIPTION, seq(
      field('value', $._expression),
      ':',
      field('type', $._type),
    )),

    binary_expression: $ => {
      // Happy declares comparison ops as nonassoc. Tree-sitter needs some
      // associativity to produce a parse tree - picking left mirrors what
      // most users expect and simply accepts ill-formed chains rather than
      // rejecting them.
      const table = [
        [PREC.LOR, '||'],
        [PREC.LAND, '&&'],
        [PREC.EQ,  '=='],
        [PREC.EQ,  '!='],
        [PREC.CMP, '<' ],
        [PREC.CMP, '>' ],
        [PREC.CMP, '<='],
        [PREC.CMP, '>='],
        [PREC.ADD, '+' ],
        [PREC.ADD, '-' ],
        [PREC.MUL, '*' ],
        [PREC.MUL, '/' ],
        [PREC.MUL, '%' ],
      ];
      return choice(...table.map(([p, op]) =>
        prec.left(p, seq(
          field('left', $._expression),
          field('operator', op),
          field('right', $._expression),
        ))
      ));
    },

    unary_expression: $ => prec(PREC.LNOT, seq(
      field('operator', '!'),
      field('argument', $._expression),
    )),

    // `if e1 then e2 else e3` — expression form. Stmt-level `if` uses parens.
    ternary_expression: $ => prec.right(PREC.IF, seq(
      'if',
      field('condition', $._expression),
      'then',
      field('consequence', $._expression),
      'else',
      field('alternative', $._expression),
    )),

    proxy_expression: $ => prec(PREC.PROXY, seq('@', field('type', $._type))),

    // ----- types -----

    _type: $ => choice(
      $.type_identifier,
      $.function_type,
      $.tuple_type,
      $.proxy_type,
    ),

    type_identifier: $ => seq(
      field('name', $.identifier),
      optional(field('args', $.type_args)),
    ),

    function_type: $ => prec.right(seq(
      '(',
      optional(commaSep1($._type)),
      ')',
      '->',
      field('return_type', $._type),
    )),

    tuple_type: $ => seq(
      '(',
      optional(commaSep1($._type)),
      ')',
    ),

    proxy_type: $ => prec(PREC.PROXY, seq('@', field('type', $._type))),

    // ----- literals -----

    _literal: $ => choice(
      $.hex_literal,
      $.integer_literal,
      $.string_literal,
    ),

    integer_literal: $ => /[0-9]+/,
    hex_literal:     $ => /0x[0-9a-fA-F]+/,

    string_literal: $ => seq(
      '"',
      repeat(choice(
        alias($._string_content, $.string_content),
        $.escape_sequence,
      )),
      '"',
    ),

    _string_content: $ => token.immediate(/[^"\\\n]+/),
    escape_sequence: $ => token.immediate(/\\[nt"]/),

    // ----- comments / identifier -----

    line_comment: $ => token(seq('//', /[^\n]*/)),

    identifier: $ => /[A-Za-z][A-Za-z0-9_]*/,
  },
});

function commaSep(rule) {
  return optional(commaSep1(rule));
}

function commaSep1(rule) {
  return seq(rule, repeat(seq(',', rule)));
}

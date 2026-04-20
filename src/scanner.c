#include "tree_sitter/parser.h"

#include <wctype.h>

enum TokenType {
    BLOCK_COMMENT,
};

void *tree_sitter_core_solidity_external_scanner_create(void) { return NULL; }
void  tree_sitter_core_solidity_external_scanner_destroy(void *p) { (void)p; }
unsigned tree_sitter_core_solidity_external_scanner_serialize(void *p, char *b) {
    (void)p; (void)b; return 0;
}
void  tree_sitter_core_solidity_external_scanner_deserialize(void *p, const char *b, unsigned l) {
    (void)p; (void)b; (void)l;
}

static inline void advance(TSLexer *lexer) { lexer->advance(lexer, false); }
static inline void skip(TSLexer *lexer)    { lexer->advance(lexer, true);  }

bool tree_sitter_core_solidity_external_scanner_scan(
    void *payload,
    TSLexer *lexer,
    const bool *valid_symbols
) {
    (void)payload;

    if (!valid_symbols[BLOCK_COMMENT]) return false;

    // Let the default extras mechanism consume whitespace. We only wake up
    // when the lexer is at the start of a potential block comment.
    while (iswspace(lexer->lookahead)) skip(lexer);

    if (lexer->lookahead != '/') return false;
    advance(lexer);
    if (lexer->lookahead != '*') return false;
    advance(lexer);

    unsigned depth = 1;
    while (depth > 0) {
        if (lexer->eof(lexer)) return false;
        if (lexer->lookahead == '/') {
            advance(lexer);
            if (lexer->lookahead == '*') {
                depth++;
                advance(lexer);
            }
        } else if (lexer->lookahead == '*') {
            advance(lexer);
            if (lexer->lookahead == '/') {
                depth--;
                advance(lexer);
            }
        } else {
            advance(lexer);
        }
    }

    lexer->result_symbol = BLOCK_COMMENT;
    return true;
}

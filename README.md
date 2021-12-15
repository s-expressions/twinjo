Twinjo specification (2011-10-11)
=================================

This SRFI specifies Twinjo, a general and extensible method of
serializing Scheme data in a way that other languages can
straightforwardly handle. 
A distinctive feature of Twinjo is that it provides both a text and a
binary format, and the two formats can encode the same data. This makes
it convenient to switch between text and binary as needed.

Twinjo Text is a variant of Lisp S-expressions, and Twinjo Binary is a
subset of ASN.1 Basic Encoding Rules. It makes no use of ASN.1 schemas.

It also arranges for there to be just one encoding for each datum
represented, although the Twinjo Text rules don't quite correspond to
any Lisp syntax, and the Twinjo Binary rules don't conform to either of
the usual subsets, ASN.1 Canonical Encoding Rules (CER) or ASN.1
Distinguished Encoding Rules (DER). Twinjo provides effectively
unlimited extensibility and attempts to maintain a balance between ease
and efficiency for both reading and writing.

Though the formats are being designed under Scheme, there is nothing
Scheme-specific about them. Libraries for other languages, especially
other Lisps, are planned.

Text syntax
-----------

Twinjo Text syntax is an upward compatible extension of
[POSE syntax](https://github.com/s-expressions/twinjo/blob/master/README.md#Grammar)
and has the same meaning.  The new and updated rules are marked with `[TWINJO]`.
```
expressions  = (atmosphere* expression)* atmosphere*

atmosphere   = whitespace | comment
whitespace   = HT | VT | FF | space | newline
newline      = CR | LF
comment      = ';' and all subsequent characters until newline or eof

expression   = '#' list | '#' letter | '#' tag simple-expr | simple-expr     [TWINJO]
simple-expr  = list | string | number | symbol | bytevector                  [TWINJO]
tag          = letter letdigit+                                              [TWINJO]

list         = '(' expressions ')'

string       = '"' string-char* '"'
string-char  = string-esc | any-char-except-backslash
string-esc   = \\ | \" | \|                                                  [TWINJO]

number       = '0' | decimal
decimal      = minus? onenine digit* fraction? exponent?
fraction     = '.' digit+
exponent     = 'e' sign digit+

symbol       = wordsym | signsym | colonsym | vbarsym                        [TWINJO]
wordsym      = wordsym-1st wordsym-cont*
wordsym-1st  = letter | punct-1st
wordsym-cont = letter | punct-cont | digit
signsym      = sign signsym-rest?
signsym-rest = signsym-2nd signsym-cont*
signsym-2nd  = letter | punct-cont
signsym-cont = letter | punct-cont | digit
colonsym     = ':' wordsym
vbarsym      = '|' string-char* '|'                                          [TWINJO]
punct-1st    = '!' | '$' | '&' | '*' | '+' | '-' | '/' | '<' | '=' | '>' | '_'
punct-cont   = punct-1st | '.' | '?' | '@'

bytevector   = '{' hexpairs '}'                                              [TWINJO]
hexpairs     = hexpair | hexpair '-'? hexpairs                               [TWINJO]
hexpair      = hexdig hexdig                                                 [TWINJO]

letter       = a-z
digit        = 0-9
letdig       = a-z0-9                                                        [TWINJO]
hexdig       = 0-9a-f                                                        [TWINJO]
onenine      = 1-9
minus        = '-'
sign         = '-' | '+'

```
Tags begin with `#` and are Twinjo Text's extensibility mechanism.  The empty tag
represents a vector, as in most Lisps. Single-letter tags are `#t` for true, `#f`
for false, `#n` for null (not a Lisp concept, but useful for other languages),
and `#u` for the undefined value.

Bytevectors have their own syntax for compactness (the optional hyphens for readability)
and also to allow tagged bytevectors without having to allow more than one tag
on an expression.

Binary syntax
-------------

Depending on its type, an object is represented as either a sequence of
bytes or a sequence of subobjects.

All byte objects have the same general format:

-   1 or 2 type bytes
-   1-9 length bytes
-   the number of content bytes specified in the length.

All objects with subobjects also have the same general format:

-   1 or 2 type bytes
-   an `80` pseudo-length byte
-   the encoded subobjects
-   an end of content (EOC) marker (two consecutive `00` bytes)

Length bytes format:

-   If length is indeterminate, pseudo-length byte is `80`.
-   If length is less than 2<sup>7</sup> bytes, then length byte is `00` through
    `7F`.
-   If length is less than 2<sup>16</sup> bytes, then meta-length byte is `82`,
    followed by 2 length bytes representing a big-endian unsigned
    integer.
    -   If length is less than 2<sup>24</sup> bytes, then meta-length byte is
        `83`, followed by 3 length bytes representing the length as a
        big-endian unsigned integer.
-   \...
-   If length is less than 2<sup>64</sup> bytes, then meta-length byte is `88`,
    followed by 8 length bytes representing the length as a unsigned
    2\'s-complement integer.
-   Larger objects are not representable.

Examples
--------

Here are a few examples of how different kinds of objects are
represented. For all known types, see this Google spreadsheet: [Twinjo
data type serializations at](https://tinyurl.com/asn1-ler)
<https://tinyurl.com/asn1-ler>.

Note: If binary interoperability with other ASN.1 systems is important,
encode only the types marked \"X.690\" in the Origin column of the
spreadsheet.

Lists: Type byte `E0`,: pseudo-length byte `80`, the encoded elements of
the list, an EOC marker `00 00`.

Text: subobjects in parentheses

Vectors: Type byte `30`, length bytes, the encoded elements of the
vector, an EOC marker `00 00`.

Text: the empty tag `#` followed by a list.

Booleans: Type byte `01`, length byte `01`, either `00` for false or
`FF` for true.

Text: `#t` or `#f`.

Integers: Type byte `02`, 1-9 length bytes, content bytes representing a
big-endian 2\'s-complement integer.

Text: optional sign followed by sequence of decimal digits.

IEEE double floats: Type byte `DB`, length byte `08`, 8 content bytes
representing a big-endian IEEE binary64 float.

Text: optional sign followed by sequence of decimal digits, with either
a decimal point or an exponent.

Strings: Type byte `OC`, 1-9 length bytes representing the length of the
string in bytes when encoded as UTF-8, corresponding content bytes.
Text: characters enclosed in double quotes, with `\\` and `\"` as
escapes.

Symbols: Type byte `DD`, 1-9 length bytes representing the length of the
string in bytes when encoded as UTF-8, corresponding content bytes.
Text: lower-case ASCII letters, or characters enclosed in vertical bars,
with `\\` and `\|` as escapes.

Nulls: Type byte `05`, length byte `00`.
Text: `#n`.
Note: This is not the same as `#f` or `()`; there is no natural
representation in Lisp.

Mappings / hash tables: Type byte `E4`, pseudo-length byte `80`, the
encoded elements of the list alternating between keys and values, an EOC
marker `00 00`.

Timestamps: Type byte `18`, 1 length byte, ASCII encoding of a ISO 8601
timestamp without hyphens, colons, or spaces.
Text: `#date` followed by a string.

Skipping unknown binary types
-----------------------------

-   If first type byte is `1F`, `3F`, `5F`, `7F`, `9F`, `BF`, `DF`, or
    `FF`, skip one additional type byte.
-   Read and interpret length bytes.
-   If length byte is not `80`, skip number of bytes equal to the
    length.
-   If length byte is `80`, recursively skip subobjects until the EOC
    marker has been read.

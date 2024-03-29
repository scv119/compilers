/*
 *  The scanner definition for COOL.
 */

import java_cup.runtime.Symbol;

%%

%{

/*  Stuff enclosed in %{ %} is copied verbatim to the lexer class
 *  definition, all the extra variables/functions you want to use in the
 *  lexer actions should go here.  Don't remove or modify anything that
 *  was there initially.  */

    // Max size of string constants
    static int MAX_STR_CONST = 1025;

    // For assembling string constants
    StringBuffer string_buf = new StringBuffer();

    private int curr_lineno = 1;
    private int comment_depth = 0;
    private String errMsg = null;
    private boolean strError = false; 
    int get_curr_lineno() {
	return curr_lineno;
    }

    private AbstractSymbol filename;

    void set_filename(String fname) {
	filename = AbstractTable.stringtable.addString(fname);
    }

    AbstractSymbol curr_filename() {
	return filename;
    }
%}

%init{

/*  Stuff enclosed in %init{ %init} is copied verbatim to the lexer
 *  class constructor, all the extra initialization you want to do should
 *  go here.  Don't remove or modify anything that was there initially. */

    // empty for now
%init}

%eofval{

/*  Stuff enclosed in %eofval{ %eofval} specifies java code that is
 *  executed when end-of-file is reached.  If you use multiple lexical
 *  states and want to do something special if an EOF is encountered in
 *  one of those states, place your code in the switch statement.
 *  Ultimately, you should return the EOF symbol, or your lexer won't
 *  work.  */
    String errMsg = null;
    switch(yy_lexical_state) {
    case YYINITIAL:
	    break;
    case COMMENT:
        yybegin(EOF);
        errMsg = "LEXER BUG - EOF in comment, file\n \"" + curr_filename() + "\", line " + yyline + ": " +  yytext();
        System.err.println(errMsg);
        return new Symbol(TokenConstants.ERROR, "EOF in comment");
    case STRING:
        yybegin(EOF);
        errMsg = "LEXER BUG - EOF in string, file\n \"" + curr_filename() + "\", line " + yyline + ": " +  yytext();
        System.err.println(errMsg);
        return new Symbol(TokenConstants.ERROR, "EOF in string constant");
    default:
        break;
    }
    return new Symbol(TokenConstants.EOF);
%eofval}

%class CoolLexer
%cup
%line
%ignorecase

DIGIT = [0-9]+
ALPHA = [a-z]+

ID = [a-z]({DIGIT}|{ALPHA}|_)*

WHITE_SPACE = [\b\f\v\t\ \x0b]
NEWLINE = [\r\n]

COMMENT_LINE = [-][-][^\n]*{NEWLINE}
OP_COMMENT = "(*"
CL_COMMENT = "*)"
%state COMMENT

STRING_CONST = [^\"^\n^\\^\0]*
OP_STRING  = [\"]
CL_STRING  = [\"]
%state STRING
%state STRING_BACK_SLASH
%state EOF

%%

<YYINITIAL>"class" { return new Symbol(TokenConstants.CLASS); }
<YYINITIAL>"else" { return new Symbol(TokenConstants.ELSE); }
<YYINITIAL>"fi" { return new Symbol(TokenConstants.FI); }
<YYINITIAL>"if" { return new Symbol(TokenConstants.IF); }
<YYINITIAL>"in" { return new Symbol(TokenConstants.IN); }
<YYINITIAL>"inherits" { return new Symbol(TokenConstants.INHERITS); }
<YYINITIAL>"isvoid" { return new Symbol(TokenConstants.ISVOID); }
<YYINITIAL>"let" { return new Symbol(TokenConstants.LET); }
<YYINITIAL>"loop" { return new Symbol(TokenConstants.LOOP); }
<YYINITIAL>"pool" { return new Symbol(TokenConstants.POOL); }
<YYINITIAL>"then" { return new Symbol(TokenConstants.THEN); }
<YYINITIAL>"while" { return new Symbol(TokenConstants.WHILE); }
<YYINITIAL>"case" { return new Symbol(TokenConstants.CASE); }
<YYINITIAL>"esac" { return new Symbol(TokenConstants.ESAC); }
<YYINITIAL>"new" { return new Symbol(TokenConstants.NEW); }
<YYINITIAL>"of" { return new Symbol(TokenConstants.OF); }
<YYINITIAL>"not" { return new Symbol(TokenConstants.NOT); }

<YYINITIAL>"{" { return new Symbol(TokenConstants.LBRACE); }
<YYINITIAL>"}" { return new Symbol(TokenConstants.RBRACE); }
<YYINITIAL>"*" { return new Symbol(TokenConstants.MULT); }
<YYINITIAL>"(" { return new Symbol(TokenConstants.LPAREN); }
<YYINITIAL>")" { return new Symbol(TokenConstants.RPAREN); }
<YYINITIAL>";" { return new Symbol(TokenConstants.SEMI); }
<YYINITIAL>"-" { return new Symbol(TokenConstants.MINUS); }
<YYINITIAL>"~" { return new Symbol(TokenConstants.NEG); }
<YYINITIAL>"<" { return new Symbol(TokenConstants.LT); }
<YYINITIAL>"," { return new Symbol(TokenConstants.COMMA); }
<YYINITIAL>"/" { return new Symbol(TokenConstants.DIV); }
<YYINITIAL>"+" { return new Symbol(TokenConstants.PLUS); }
<YYINITIAL>"<-" { return new Symbol(TokenConstants.ASSIGN); }
<YYINITIAL>"." { return new Symbol(TokenConstants.DOT); }
<YYINITIAL>"<=" { return new Symbol(TokenConstants.LE); }
<YYINITIAL>"=" { return new Symbol(TokenConstants.EQ); }
<YYINITIAL>":" { return new Symbol(TokenConstants.COLON); }
<YYINITIAL>"@" { return new Symbol(TokenConstants.AT); }
<YYINITIAL>"=>" { return new Symbol(TokenConstants.DARROW); }

<YYINITIAL, COMMENT> {WHITE_SPACE} { }
<YYINITIAL, COMMENT> {NEWLINE} {
                curr_lineno ++;
            }

<YYINITIAL> {ID} { 
            String objectStr = yytext(); 
            if (objectStr.charAt(0) == 't' && objectStr.toLowerCase().equals("true"))
                return new Symbol(TokenConstants.BOOL_CONST, true);
            else if (objectStr.charAt(0) == 'f' && objectStr.toLowerCase().equals("false"))
                return new Symbol(TokenConstants.BOOL_CONST, false);
            else if (objectStr.charAt(0) <= 'z' && objectStr.charAt(0) >= 'a')
                return new Symbol(TokenConstants.OBJECTID, AbstractTable.idtable.addString(objectStr));
            return new Symbol(TokenConstants.TYPEID, AbstractTable.idtable.addString(objectStr));
            }


<YYINITIAL> {OP_STRING} {
                strError = false;
                yybegin(STRING);
            }

<STRING>    \\ {
                yybegin(STRING_BACK_SLASH); 
            }

<STRING_BACK_SLASH> ([^\0]) {
                char c = yytext().charAt(0);
                switch (c) {
                    case 'b':
                        c = '\b';
                        break;
                    case 't':
                        c = '\t';
                        break;
                    case 'n':
                        c = '\n';
                        break;
                    case 'f':
                        c= '\f';
                        break;
                    case '\n':
                        curr_lineno ++;
                        break;
                    default:
                        break;
                }

                string_buf.append(c);
                yybegin(STRING);
            }

<STRING>    {CL_STRING} { 
                yybegin(YYINITIAL);
                String str = string_buf.toString();
                string_buf = new StringBuffer();
                if (strError)
                    return new Symbol(TokenConstants.ERROR, "Invalid character");
                if (str.length()  > MAX_STR_CONST)
                    return new Symbol(TokenConstants.ERROR, "EOF in string constant");
                return new Symbol(TokenConstants.STR_CONST, AbstractTable.stringtable.addString(str));
            }

<STRING, STRING_BACK_SLASH> [\0] {
                strError = true;
                yybegin(STRING);
            }

<STRING> {NEWLINE} {
                yybegin(YYINITIAL);
                curr_lineno ++;
                string_buf = new StringBuffer();
                return new Symbol(TokenConstants.ERROR, "Unterminated string constant");
            }

<STRING>    {STRING_CONST} {
                String str = yytext();
                string_buf.append(str);
            } 

<YYINITIAL> {DIGIT} {
                return new Symbol(TokenConstants.INT_CONST, AbstractTable.inttable.addString(yytext()));
            }

<YYINITIAL> {COMMENT_LINE} { curr_lineno ++; }

<YYINITIAL> {CL_COMMENT}  { return new Symbol(TokenConstants.ERROR, "Unmatched *)"); }

<YYINITIAL,COMMENT> {OP_COMMENT} {
                comment_depth ++;
                yybegin(COMMENT);
            }

<COMMENT>   {CL_COMMENT} {
                comment_depth --;
                if (comment_depth == 0)
                    yybegin(YYINITIAL);
            }

<COMMENT>   .  { }

<EOF> .* { 
    return new Symbol(TokenConstants.EOF);
    }

.   {
        errMsg = "LEXER BUG - UNMATCHED file\n \"" + curr_filename() + "\", line " + yyline + ": " +  yytext();
        System.err.println(errMsg);
        return new Symbol(TokenConstants.ERROR, errMsg);
    }


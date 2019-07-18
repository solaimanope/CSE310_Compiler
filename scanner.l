%option noyywrap

%{
/// Please Compile lex.yy.c in C++11
#include<bits/stdc++.h>
#include "SymbolTable.h"
#include "y.tab.h"
using namespace std;

void yyerror(char *);

/// Symbol Table Implementation Ends

SymbolTable stable(5);

int line_count = 1, tmp_line_count;
int error_count = 0;
string tokenString, logString;
bool lastBackSlash, lastAsterisk;

//ofstream logout;
extern ofstream errorout;

void printError(const string &errorString)
{
    error_count++;
    errorout << "Error at line " << line_count << ": ";
    errorout << errorString << " " << yytext << "\n\n";
}

void printLogError(const string &errorString)
{
    error_count++;
    errorout << "Error at line " << line_count << ": ";
    errorout << errorString << " " << logString << "\n\n";
}

char getSlashChar(char c)
{
    if (c=='n') c = '\n';
    else if (c=='t') c = '\t';
    else if (c=='\\') c = '\\';
    else if (c=='\"') c = '\"';
    else if (c=='a') c = '\a';
    else if (c=='f') c = '\f';
    else if (c=='r') c = '\r';
    else if (c=='b') c = '\b';
    else if (c=='v') c = '\v';
    else if (c=='0') c = '\0';
    return c;
}
%}

%x INSIDE_ONE_LINE_COMMENT
%x INSIDE_MULTI_LINE_COMMENT
%x INSIDE_STRING

WHITESPACE [ \t\f\r\v]+
UALPHA [a-zA-Z_]
UALPHANUM [0-9a-zA-Z_]
LETTER [a-zA-Z]
DIGIT [0-9]
EXPONENT [Ee][+-]?{DIGIT}+
ILLEXPONENT [Ee][+-]?({DIGIT}*"."{DIGIT}*)*
DECIMAL {DIGIT}+"."{DIGIT}*|"."{DIGIT}+
NEWLINE \n

%%
{WHITESPACE}            /// ignore whitespaces
{NEWLINE}               {
                            line_count++;
                            //tokenout << "\n";
                        }

"if" 					{ return IF; 		}
"else" 					{ return ELSE; 		}
"for" 					{ return FOR; 		}
"while" 				{ return WHILE; 	}
"do" 					{ return DO; 		}
"break" 				{ return BREAK; 	}
"int" 					{ return INT; 		}
"char" 					{ /*return CHAR;*/ 		}
"float" 				{ return FLOAT; 	}
"double" 				{ /*return DOUBLE;*/ 	}
"void" 					{ return VOID; 		}
"return" 				{ return RETURN; 	}
"switch" 				{ return SWITCH; 	}
"case" 					{ return CASE; 		}
"default" 				{ return DEFAULT; 	}
"continue" 				{ return CONTINUE; 	}

{DIGIT}+ 				{
							yylval.info = new SymbolInfo(yytext, "CONST_INT");
							return CONST_INT;
						}
{DECIMAL}{EXPONENT}?|({DIGIT}+{EXPONENT}) {
							yylval.info = new SymbolInfo(yytext, "CONST_FLOAT");
							return CONST_FLOAT;
						}
{DECIMAL}"."({DIGIT}|".")*|("."{2,}){DIGIT}({DIGIT}|".")* {
                            printError("Too many decimal point");
                        }
{DECIMAL}{ILLEXPONENT}?|({DIGIT}+{ILLEXPONENT})|{EXPONENT} {
                            printError("Ill formed number");
                        }

\'[^\n\t\f\r\v\\\"\']\' { return CONST_CHAR; }
\'\\[^\n\t\f\r\v]\'     { return CONST_CHAR; }
\'\'                    { 
							printError("Empty character constant error");   
						}
\'\\\'|\'               { 
							printError("Unterminated character");           
						}
\'[^\n\t\f\r\v\']*/[\n\t\f\r\v<<EOF>>] {
                          printError("Unterminated character");
                        }
\'[^\n\t\f\r\v\']{2,}\' {
                            printError("Multi character constant error");
                        }

[+-] 					{
							yylval.info = new SymbolInfo(yytext, "ADDOP");
							return ADDOP;
						}
[*/%] 					{
							yylval.info = new SymbolInfo(yytext, "MULOP");
							return MULOP;
						}
"++"	 				{
							return INCOP;
						}
"--" 					{
							return DECOP;
						}
"<"|"<="|">"|">="|"=="|"!="	{
							yylval.info = new SymbolInfo(yytext, "RELOP");
							return RELOP;
						}
"=" 					{
							return ASSIGNOP;
						}
"&&"|"||" 				{
							yylval.info = new SymbolInfo(yytext, "LOGICOP");
							return LOGICOP;
						}
"&"|"|"|"^"|"<<"|">>"|"~" {
							yylval.info = new SymbolInfo(yytext, "BITOP");
							return BITOP;
						}
"!"                     {   return NOT;			}
"("                     {   return LPAREN;		}
")"                     {   return RPAREN;		}
"{"                     {   return LCURL;		}
"}"                     {   return RCURL;		}
"["                     {   return LTHIRD;		}
"]"                     {   return RTHIRD;		}
","                     {   return COMMA;		}
";"                     {   return SEMICOLON;	}


{UALPHA}{UALPHANUM}* 	{
							yylval.info = new SymbolInfo(yytext, "ID");
							return ID;
						}
{DIGIT}+{UALPHA}{UALPHANUM}* {
                            printError("Invalid prefix on ID or invalid suffix on Number");
                        }

\"                      {
                            tmp_line_count = 0;
                            tokenString = "";
                            logString = "\"";
                            BEGIN(INSIDE_STRING);
                        }

<INSIDE_STRING>\"       {
                            logString += yytext;
                            //printString();
                            line_count += tmp_line_count;
                            BEGIN(INITIAL);
                        }
<INSIDE_STRING>[^\"\\\n]+ {
                            tokenString += yytext;
                            logString += yytext;
                        }
<INSIDE_STRING>\\[\r]*\n  {
                            tmp_line_count++;
                            logString += yytext;
                        }
<INSIDE_STRING>\\.      {
                            tokenString += getSlashChar(yytext[1]);
                            logString += yytext;
                        }
<INSIDE_STRING>[\n<<EOF>>] {
                            if (yytext[0]=='\n') tmp_line_count++;
                            printLogError("Unterminated String");
                            line_count += tmp_line_count;
                            BEGIN(INITIAL);
                        }
"//"                    {
                            lastBackSlash = false;
                            logString = yytext;
                            tmp_line_count = 0;
                            BEGIN(INSIDE_ONE_LINE_COMMENT);
                        }
<INSIDE_ONE_LINE_COMMENT>[\r]*\n {
                            if (lastBackSlash) {
                                logString += yytext;
                                tmp_line_count++;
                                lastBackSlash = false;
                            } else {
                                //printComment();
                                line_count += tmp_line_count+1;
                                BEGIN(INITIAL);
                            }
                        }
<INSIDE_ONE_LINE_COMMENT><<EOF>> {
                                //printComment();
                                line_count += tmp_line_count+1;
                                BEGIN(INITIAL);
                        }
<INSIDE_ONE_LINE_COMMENT>[^\\\n]+ {
                            lastBackSlash = false;
                            logString += yytext;
                        }
<INSIDE_ONE_LINE_COMMENT>[\\]+ {
                            lastBackSlash = true;
                            logString += yytext;
                        }

"/*"                    {
                            lastAsterisk = false;
                            logString = yytext;
                            tmp_line_count = 0;
                            BEGIN(INSIDE_MULTI_LINE_COMMENT);
                        }
<INSIDE_MULTI_LINE_COMMENT>[^*/\n]+ {
                            lastAsterisk = false;
                            logString += yytext;
                        }
<INSIDE_MULTI_LINE_COMMENT>\n {
                            lastAsterisk = false;
                            logString += yytext;
                            tmp_line_count++;
                        }
<INSIDE_MULTI_LINE_COMMENT>[*]+ {
                            lastAsterisk = true;
                            logString += yytext;
                        }
<INSIDE_MULTI_LINE_COMMENT>"/" {
                            logString += yytext;
                            if (lastAsterisk) {
                                //printComment();
                                line_count += tmp_line_count;
                                BEGIN(INITIAL);
                            }
                        }
<INSIDE_MULTI_LINE_COMMENT><<EOF>> {
                            printLogError("Unterminated comment");
                            line_count += tmp_line_count;
                            BEGIN(INITIAL);
                        }

.                       {
                            printError("Unrecognized character found");
                        }
%%


%{
#include<bits/stdc++.h>
#include "SymbolTable.h"

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE *fin;
ofstream logout;
ofstream errorout;
extern int line_count;

//SymbolTable *table;
int ScopeTable::objectCounter = 0;

void yyerror(char *s)
{
	//write your code
}

SymbolInfo *handleRule(string LHS, string RHS, string total)
{
	logout << "At line no: " << line_count << " " << LHS << " : " << RHS << "\n\n";
	logout << total << "\n\n";
	return new SymbolInfo(total, LHS);
}

string indentate(string s)
{
	string t;
	t += '\t';
	for (int i = 0; i < s.size(); i++) {
		char c = s[i];
		t += c;
		if (i+1 < s.size() && c=='\n') t += '\t';
	}
	return t;
}

#define ONE_PART { }

%}

%union {
SymbolInfo* info;
}

%token IF ELSE FOR WHILE DO BREAK VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN
%token NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%token ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP BITOP
%token CONST_INT CONST_FLOAT CONST_CHAR
%token ID INT FLOAT 

%left ADDOP 
%left MULOP
%left RELOP 
%left LOGICOP 
%left BITOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%start start
//%start expression_statement
%%

start : program{
			$<info>$ = handleRule("start",
			"program",
			$<info>1->getName());
		}
		;

program : program unit {
			$<info>$ = handleRule("program",
			"program unit",
			$<info>1->getName() + $<info>2->getName());
		}
		| unit {
			$<info>$ = handleRule("program",
			"unit",
			$<info>1->getName());
		}
		;
	
unit : var_declaration {
			$<info>$ = handleRule("unit",
			"var_declaration",
			$<info>1->getName());
		}
     	| func_declaration {
			$<info>$ = handleRule("unit",
			"func_declaration",
			$<info>1->getName());
		}
     	| func_definition {
			$<info>$ = handleRule("unit",
			"func_definition",
			$<info>1->getName());
		}
     	;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
			$<info>$ = handleRule("func_declaration",
			"type_specifier ID LPAREN parameter_list RPAREN SEMICOLON",
			$<info>1->getName() + " " + $<info>2->getName() + "(" + 
			$<info>4->getName() + ")" + ";"  + "\n");
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON {
			$<info>$ = handleRule("func_declaration",
			"type_specifier ID LPAREN RPAREN SEMICOLON",
			$<info>1->getName() + " " + $<info>2->getName() + "(" + ")" + ";" + "\n");
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement {
			$<info>$ = handleRule("func_definition",
			"type_specifier ID LPAREN parameter_list RPAREN compound_statement",
			$<info>1->getName() + " " + $<info>2->getName() + "(" + 
			$<info>4->getName() + ")" + $<info>6->getName() );
		}
		| type_specifier ID LPAREN RPAREN compound_statement {
			$<info>$ = handleRule("func_definition",
			"type_specifier ID LPAREN RPAREN compound_statement",
			$<info>1->getName() + " " + $<info>2->getName() + 
			"(" + ")" + $<info>5->getName() );
		}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID {
			$<info>$ = handleRule("parameter_list",
			"parameter_list COMMA type_specifier ID",
			$<info>1->getName() + "," + 
			$<info>3->getName() + " " + $<info>4->getName());
		}
		| parameter_list COMMA type_specifier {
			$<info>$ = handleRule("parameter_list",
			"parameter_list COMMA type_specifier",
			$<info>1->getName() + "," + $<info>3->getName());
		}
 		| type_specifier ID {
			$<info>$ = handleRule("parameter_list",
			"type_specifier ID",
			$<info>1->getName() + " " + $<info>2->getName());
		}
		| type_specifier {
			$<info>$ = handleRule("parameter_list",
			"type_specifier",
			$<info>1->getName());
		}
 		;

 		
compound_statement : LCURL statements RCURL {
			$<info>$ = handleRule("compound_statement", 
			"LCURL statements RCURL", 
			"{\n" + indentate($<info>2->getName()) + "}" + "\n");
		}
 		| LCURL RCURL {
			$<info>$ = handleRule("compound_statement", 
			"LCURL RCURL", 
			"{}");
		}
 		;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
			$<info>$ = handleRule("var_declaration", 
			"type_specifier declaration_list SEMICOLON", 
			$<info>1->getName() + " " + $<info>2->getName() + ";" + "\n");
		}
 		;
 		 
type_specifier	: INT {
			$<info>$ = handleRule("type_specifier", 
			"INT", 
			"int");
		}
 		| FLOAT {
			$<info>$ = handleRule("type_specifier", 
			"FLOAT", 
			"float");
		}
 		| VOID {
			$<info>$ = handleRule("type_specifier", 
			"VOID", 
			"void");
		}
 		;
 		
declaration_list : declaration_list COMMA ID {
			$<info>$ = handleRule("declaration_list", 
			"declaration_list COMMA ID", 
			$<info>1->getName() + "," + $<info>3->getName());
		}
 		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
			$<info>$ = handleRule("declaration_list", 
			"declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", 
			$<info>1->getName() + "," + $<info>3->getName() + 
			"[" + $<info>5->getName() + "]");
		}
	  	| ID {
			$<info>$ = handleRule("declaration_list", 
			"ID", 
			$<info>1->getName());
		}
		| ID LTHIRD CONST_INT RTHIRD {
			$<info>$ = handleRule("declaration_list", 
			"ID LTHIRD CONST_INT RTHIRD", 
			$<info>1->getName() + "[" + $<info>3->getName() + "]");
		}
 		;
 		  
statements : statement {
			$<info>$ = handleRule("statements", 
			"statement", 
			$<info>1->getName());	
		}
	   	| statements statement {
			$<info>$ = handleRule("statements", 
			"statements statement", 
			$<info>1->getName() + $<info>2->getName());
		}
	   	;
	   
statement : var_declaration	{
			$<info>$ = handleRule("statement", 
			"var_declaration", 
			$<info>1->getName());	
		}
	  	| expression_statement {
			$<info>$ = handleRule("statement", 
			"expression_statement", 
			$<info>1->getName());	
		}
	  	| compound_statement {
			$<info>$ = handleRule("statement", 
			"compound_statement", 
			$<info>1->getName());	
		}
	  	| FOR LPAREN expression_statement expression_statement expression RPAREN statement {
			$<info>$ = handleRule("statement", 
			"FOR LPAREN expression_statement expression_statement expression RPAREN statement", 
			"for (" + $<info>3->getName() + $<info>4->getName() + 
			$<info>5->getName() + ") " + $<info>7->getName() );
		}
	  	| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
			$<info>$ = handleRule("statement", 
			"IF LPAREN expression RPAREN statement", 
			"if (" + $<info>3->getName() + ") " + $<info>5->getName());
		}
	  	| IF LPAREN expression RPAREN statement ELSE statement {
			$<info>$ = handleRule("statement", 
			"IF LPAREN expression RPAREN statement ELSE statement", 
			"if (" + $<info>3->getName() + ") " + $<info>5->getName() + 
			"else " + $<info>7->getName());
		}
	  	| WHILE LPAREN expression RPAREN statement {
			$<info>$ = handleRule("statement", 
			"WHILE LPAREN expression RPAREN statement", 
			"while (" + $<info>3->getName() + ") " + $<info>5->getName());
		}
	  	| PRINTLN LPAREN ID RPAREN SEMICOLON {
			$<info>$ = handleRule("statement", 
			"PRINTLN LPAREN ID RPAREN SEMICOLON", 
			"println(" + $<info>3->getName() + ");" + "\n");
		}
	  	| RETURN expression SEMICOLON {
			$<info>$ = handleRule("statement", 
			"RETURN expression SEMICOLON", 
			"return " + $<info>2->getName() + ";" + "\n");
		}
	  	;
	  
expression_statement : SEMICOLON {
			$<info>$ = handleRule("expression_statement", 
			"SEMICOLON", 
			";\n");		
		}
		| expression SEMICOLON {
			$<info>$ = handleRule("expression_statement", 
			"expression SEMICOLON", 
			$<info>1->getName() + ";\n");
		}
		;
	  
variable : ID {
			$<info>$ = handleRule("variable", 
			"ID", 
			$<info>1->getName());		
		}
	 	| ID LTHIRD expression RTHIRD {
			$<info>$ = handleRule("variable", 
			"ID LTHIRD expression RTHIRD", 
			$<info>1->getName() + "[" + 
			$<info>3->getName() + "]");
		}
	 	;
	 
expression : logic_expression {
			$<info>$ = handleRule("expression", 
			"logic_expression", 
			$<info>1->getName());		
		}
	   	| variable ASSIGNOP logic_expression {
			$<info>$ = handleRule("expression", 
			"variable ASSIGNOP logic_expression", 
			$<info>1->getName() + " = " + $<info>3->getName());
		}
	   	;
			
logic_expression : rel_expression {
			$<info>$ = handleRule("logic_expression", 
			"rel_expression", 
			$<info>1->getName());		
		}	
		| rel_expression LOGICOP rel_expression {
			$<info>$ = handleRule("logic_expression", 
			"rel_expression LOGICOP rel_expression", 
			$<info>1->getName() + $<info>2->getName() + $<info>3->getName());
		}
		;
			
rel_expression	: simple_expression {
			$<info>$ = handleRule("rel_expression", 
			"simple_expression", 
			$<info>1->getName());		
		}
		| simple_expression RELOP simple_expression {
			$<info>$ = handleRule("rel_expression", 
			"simple_expression RELOP simple_expression", 
			$<info>1->getName() + $<info>2->getName() + $<info>3->getName());
		}
		;
				
simple_expression : term  {
			$<info>$ = handleRule("simple_expression", 
			"term", 
			$<info>1->getName());		
		}
		| simple_expression ADDOP term {
			$<info>$ = handleRule("simple_expression", 
			"simple_expression ADDOP term", 
			$<info>1->getName() + $<info>2->getName() + $<info>3->getName());
		}
		;
					
term :	unary_expression {
			$<info>$ = handleRule("term", 
			"unary_expression", 
			$<info>1->getName());		
		}
     	|  term MULOP unary_expression {
			$<info>$ = handleRule("term", 
			"term MULOP unary_expression", 
			$<info>1->getName() + $<info>2->getName() + $<info>3->getName());
		}
     	;

unary_expression : ADDOP unary_expression {
			$<info>$ = handleRule("unary_expression", 
			"ADDOP unary_expression", 
			$<info>1->getName() + $<info>2->getName());
		}
		| NOT unary_expression {
			$<info>$ = handleRule("unary_expression", 
			"NOT unary_expression", 
			"!" + $<info>2->getName());
		}
		| factor {
			$<info>$ = handleRule("unary_expression", 
			"factor", 
			$<info>1->getName());		
		}
		;
	
factor	: variable {
			$<info>$ = handleRule("factor", 
			"variable", 
			$<info>1->getName());		
		}
		| ID LPAREN argument_list RPAREN {
			$<info>$ = handleRule("factor", 
			"ID LPAREN argument_list RPAREN", 
			$<info>1->getName() + "(" + 
			$<info>3->getName() + ")");
		}
		| LPAREN expression RPAREN {
			$<info>$ = handleRule("factor", 
			"LPAREN expression RPAREN", 
			"(" + $<info>2->getName() + ")");
		}
		| CONST_INT {
			$<info>$ = handleRule("factor", 
			"CONST_INT", 
			$<info>1->getName());		
		}
		| CONST_FLOAT {
			$<info>$ = handleRule("factor", 
			"CONST_FLOAT", 
			$<info>1->getName());		
		}
		| variable INCOP {
			$<info>$ = handleRule("factor", 
			"variable INCOP", 
			$<info>1->getName() + "++");
		}
		| variable DECOP {
			$<info>$ = handleRule("factor", 
			"variable DECOP", 
			$<info>1->getName() + "--");
		}
		;
	
argument_list : arguments {
			$<info>$ = handleRule("argument_list", 
			"arguments", 
			$<info>1->getName());
		}
		|
		;
	
arguments : arguments COMMA logic_expression {
			$<info>$ = handleRule("arguments", 
			"arguments COMMA logic_expression", 
			$<info>1->getName() + "," + $<info>3->getName());
		}
	   	| logic_expression {
			$<info>$ = handleRule("arguments", 
			"logic_expression", 
			$<info>1->getName());
		}
	  	;
 

%%
int main(int argc,char *argv[])
{

	if((fin=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}


	logout.open("log.txt");
	errorout.open("error.txt");

	yyin=fin;
	yyparse();
	
	fclose(fin);
	logout.close();
    errorout.close();

	return 0;
}


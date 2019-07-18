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

//%start start
%start expression_statement
%%

start : program
	{
		//write your code in this block in all the similar blocks below
	}
	;

program : program unit 
	| unit
	;
	
unit : var_declaration
     | func_declaration
     | func_definition
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		| type_specifier ID LPAREN RPAREN SEMICOLON
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		| type_specifier ID LPAREN RPAREN compound_statement
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		| parameter_list COMMA type_specifier
 		| type_specifier ID
		| type_specifier
 		;

 		
compound_statement : LCURL statements RCURL
 		    | LCURL RCURL
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
 		 ;
 		 
type_specifier	: INT
 		| FLOAT
 		| VOID
 		;
 		
declaration_list : declaration_list COMMA ID
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		  | ID
 		  | ID LTHIRD CONST_INT RTHIRD
 		  ;
 		  
statements : statement
	   | statements statement
	   ;
	   
statement : var_declaration		
	  | expression_statement
	  | compound_statement
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  | IF LPAREN expression RPAREN statement ELSE statement
	  | WHILE LPAREN expression RPAREN statement
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  | RETURN expression SEMICOLON
	  ;
	  
expression_statement : SEMICOLON {
			$<info>$ = handleRule("expression_statement", 
			"SEMICOLON", 
			";");		
		}
		| expression SEMICOLON {
			$<info>$ = handleRule("expression_statement", 
			"expression SEMICOLON", 
			$<info>1->getName() + ";");
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
			$<info>1->getName() + "=" + $<info>3->getName());
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


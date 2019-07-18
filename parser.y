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
	  
expression_statement 	: SEMICOLON			
			| expression SEMICOLON 
			;
	  
variable : ID 		
	 | ID LTHIRD expression RTHIRD 
	 ;
	 
 expression : logic_expression	
	   | variable ASSIGNOP logic_expression 	
	   ;
			
logic_expression : rel_expression 	
		 | rel_expression LOGICOP rel_expression 	
		 ;
			
rel_expression	: simple_expression 
		| simple_expression RELOP simple_expression	
		;
				
simple_expression : term 
		  | simple_expression ADDOP term 
		  ;
					
term :	unary_expression
     |  term MULOP unary_expression
     ;

unary_expression : ADDOP unary_expression  
		 | NOT unary_expression 
		 | factor 
		 ;
	
factor	: variable 
	| ID LPAREN argument_list RPAREN
	| LPAREN expression RPAREN
	| CONST_INT 
	| CONST_FLOAT
	| variable INCOP 
	| variable DECOP
	;
	
argument_list : arguments
			  |
			  ;
	
arguments : arguments COMMA logic_expression
	      | logic_expression
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


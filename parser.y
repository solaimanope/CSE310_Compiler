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
extern int error_count;

SymbolTable *table;
int ScopeTable::objectCounter = 0;

vector< SymbolInfo* >declared;
vector< Variable >parameters;
vector< string >argTypes;
bool scopeCreated = false;

void yyerror(const char *s) {
	//write your code
	string ss(s);
	error_count++;	
	errorout << "Error at Line " << line_count << ": ";
	errorout << ss << "\n\n";
}

void showError(string text) {
	error_count++;	
	errorout << "Error at Line " << line_count << ": ";
	errorout << text << "\n\n";
}


string convert(string type1, string type2) {
	string ret = type1;
	if (type1=="int" && type2=="float") ret = type2;	
	return ret;
}

string binaryOperator(SymbolInfoPtr info1, string oprtr, SymbolInfoPtr info2) {
	string ret = "int";	// default to skip redundant errors
	if (oprtr=="%") {
		if (!info1->isInt() || !info2->isInt()) {
			showError("Non-Integer operand on modulus operator");
		}
	} else {
		if (info1->isVoid() || info2->isVoid()) {
			//errorout << info1->getName() << ", " << info2->getName() << "\n";
			showError("Type mismatch : void in expression");
		} else {
			info1->getVariableType();
			if (oprtr == "=" && info1->getVariableType() != info2->getVariableType()) {
				showError("Type mismatch");
			}
			ret = convert(info1->getVariableType(), info2->getVariableType());
		}
	}
	return ret;
}

SymbolInfo *handleRule(string LHS, string RHS, string total)
{
	logout << "At line no: " << line_count << " " << LHS << " : " << RHS << "\n\n";
	logout << total << "\n\n";
	return new SymbolInfo(total, LHS);
}

void handleFunctionDeclaration(SymbolInfoPtr type, SymbolInfoPtr id) {
	if (table->insert(id->getName(), id->getType())) {
		SymbolInfoPtr inside = table->lookUp(id->getName());
		inside->setFunction();
		FunctionInfoPtr fip = inside->getFunctionInfo();
		fip->returnType = type->getName();
		fip->isDefined = false;
		for (Variable v : parameters) {
			fip->parameters.emplace_back(v.type);
		}
	} else {
		showError("Multiple Declaration of " + id->getName());
	}
	parameters.clear();
}

void insertVarToTable(Variable var) {
	table->insert(var.id, "ID");
	SymbolInfoPtr sip = table->lookUp(var.id);
	sip->setVariableType(var.type);
}

void handleFunctionDefinition(SymbolInfoPtr type, SymbolInfoPtr id) {
	SymbolInfoPtr inside = table->lookUp(id->getName());
	if (inside == nullptr) {
		///function was not declared
		table->insert(id->getName(), id->getType());
	}
	scopeCreated =  true;
	table->enterScope(); 	/// needs global treatment
	if (inside == nullptr) {
		///function was not declared
		inside = table->lookUp(id->getName());
		inside->setFunction();
		
		FunctionInfoPtr fip = inside->getFunctionInfo();
		fip->returnType = type->getName();
		fip->isDefined = true;
		for (Variable v : parameters) {
			if (v.id.empty()) {
				showError("Parameter doesn't have name");
			} else {
				fip->parameters.push_back(v);
				insertVarToTable(v);
			}
		}
	} else if (inside->isUndefinedFunction()) {
		FunctionInfoPtr fip = inside->getFunctionInfo();
		if (fip->returnType != type->getName()) {
			showError("Return type doesn't match with declaration");
		}
		fip->isDefined = true;

		if (fip->parameters.size()!=parameters.size()) {
			showError("Parameter list size doesn't match with declaration");
		}
		int minsize = min(fip->parameters.size(), parameters.size());
		while (parameters.size() > minsize) parameters.pop_back();
		while (fip->parameters.size() > minsize) fip->parameters.pop_back();
		for (int i = 0; i < minsize; i++) {
			Variable v = parameters[i];
			Variable w = fip->parameters[i];
			if (v.id.empty()) {
				showError("Parameter doesn't have name");
			} else if (v.type != w.type) {
				showError("Parameter type doesn't match with declaration");
			} else {
				fip->parameters[i] = v;
				insertVarToTable(v);
			}
		}
	} else {
		showError("Multiple Declaration of " + id->getName());
	}
	parameters.clear();
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
%error-verbose

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
			handleFunctionDeclaration($<info>1, $<info>2);
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON {
			$<info>$ = handleRule("func_declaration",
			"type_specifier ID LPAREN RPAREN SEMICOLON",
			$<info>1->getName() + " " + $<info>2->getName() + "(" + ")" + ";" + "\n");
			handleFunctionDeclaration($<info>1, $<info>2);
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
				handleFunctionDefinition($<info>1, $<info>2);
			} compound_statement {
			$<info>$ = handleRule("func_definition",
			"type_specifier ID LPAREN parameter_list RPAREN compound_statement",
			$<info>1->getName() + " " + $<info>2->getName() + "(" + 
			$<info>4->getName() + ")" + $<info>7->getName() );
		}
		| type_specifier ID LPAREN RPAREN {
				handleFunctionDefinition($<info>1, $<info>2);
			} compound_statement {
			$<info>$ = handleRule("func_definition",
			"type_specifier ID LPAREN RPAREN compound_statement",
			$<info>1->getName() + " " + $<info>2->getName() + 
			"(" + ")" + $<info>6->getName() );
		}
 		;


parameter_list  : parameter_list COMMA type_specifier ID {
			$<info>$ = handleRule("parameter_list",
			"parameter_list COMMA type_specifier ID",
			$<info>1->getName() + "," + 
			$<info>3->getName() + " " + $<info>4->getName());
			parameters.emplace_back($<info>3->getName(), $<info>4->getName());
		}
		| parameter_list COMMA type_specifier {
			$<info>$ = handleRule("parameter_list",
			"parameter_list COMMA type_specifier",
			$<info>1->getName() + "," + $<info>3->getName());
			parameters.emplace_back($<info>3->getName());
		}
 		| type_specifier ID {
			$<info>$ = handleRule("parameter_list",
			"type_specifier ID",
			$<info>1->getName() + " " + $<info>2->getName());
			parameters.emplace_back($<info>1->getName(), $<info>2->getName());
		}
		| type_specifier {
			$<info>$ = handleRule("parameter_list",
			"type_specifier",
			$<info>1->getName());
			parameters.emplace_back($<info>1->getName());
		}
 		;

 		
compound_statement : LCURL { if (!scopeCreated) table->enterScope();
				scopeCreated = false;
			} statements RCURL {
			$<info>$ = handleRule("compound_statement", 
			"LCURL statements RCURL", 
			"{\n" + indentate($<info>3->getName()) + "}" + "\n");
			table->printAllScopeTable(logout);
			table->exitScope();
		}
 		| LCURL { if (!scopeCreated) table->enterScope();
				scopeCreated = false;
			} RCURL {
			$<info>$ = handleRule("compound_statement", 
			"LCURL RCURL", 
			"{}");
			table->printAllScopeTable(logout);
			table->exitScope();
		}
 		;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
			$<info>$ = handleRule("var_declaration", 
			"type_specifier declaration_list SEMICOLON", 
			$<info>1->getName() + " " + $<info>2->getName() + ";" + "\n");
			
			if ($<info>1->getName()=="void") {
				showError("Variables declared with void type specifier");
			} else {
				for (SymbolInfoPtr sip : declared) {
					sip->setVariableType($<info>1->getName());
					if (table->insert(sip->getName(), sip->getType())) {
						SymbolInfoPtr inside = table->lookUp(sip->getName());
						inside->copyValues(sip);
					} else {
						showError("Multiple Declaration of " + sip->getName());
					}
				}
			}
			declared.clear();
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
			declared.push_back($<info>3);
		}
 		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
			$<info>$ = handleRule("declaration_list", 
			"declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", 
			$<info>1->getName() + "," + $<info>3->getName() + 
			"[" + $<info>5->getName() + "]");
			$<info>3->setArray();
			declared.push_back($<info>3);
		}
	  	| ID {
			$<info>$ = handleRule("declaration_list", 
			"ID", 
			$<info>1->getName());
			declared.push_back($<info>1);
		}
		| ID LTHIRD CONST_INT RTHIRD {
			$<info>$ = handleRule("declaration_list", 
			"ID LTHIRD CONST_INT RTHIRD", 
			$<info>1->getName() + "[" + $<info>3->getName() + "]");
			$<info>1->setArray();
			declared.push_back($<info>1);
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
			$<info>$ = handleRule("variable", "ID", $<info>1->getName());

			SymbolInfoPtr sip = table->lookUp($<info>1->getName());
			$<info>$->setVariableType("int");
			if (sip==nullptr) {
				showError("Undeclared Variable: " + $<info>1->getName());
			} else {
				$<info>$->setVariableType(sip->getVariableType());
				if (sip->isArray()) {
					showError("Array " + $<info>1->getName() + 
					" accessed without index");
				} else if (sip->isFunction()) {
					showError("Function " + $<info>1->getName() + 
					" accessed without parameters");
				}
			}
		}
	 	| ID LTHIRD expression RTHIRD {
			$<info>$ = handleRule("variable", "ID LTHIRD expression RTHIRD",
			$<info>1->getName() + "[" + $<info>3->getName() + "]");

			$<info>$->setVariableType("int");
			SymbolInfoPtr sip = table->lookUp($<info>1->getName());
			if (sip==nullptr) {
				showError("Undeclared Array: " + $<info>1->getName());
			} else {
				$<info>$->setVariableType(sip->getVariableType());
				if (!sip->isArray()) {
					showError("Declared " + $<info>1->getName() + " is not an array");
				}
				if (!$<info>3->isInt()) {
					showError("Non-integer Array Index");
				}
			}
		}
	 	;
	 
expression : logic_expression {
			$<info>$ = handleRule("expression", 
			"logic_expression", 
			$<info>1->getName());
			$<info>$->setVariableType($<info>1->getVariableType());	
		}
	   	| variable ASSIGNOP logic_expression {
			$<info>$ = handleRule("expression", 
			"variable ASSIGNOP logic_expression", 
			$<info>1->getName() + " = " + $<info>3->getName());
			$<info>$->setVariableType(
			binaryOperator($<info>1, "=", $<info>3));
			$<info>$->setVariableType($<info>1->getVariableType());	// forced set
		}
	   	;
			
logic_expression : rel_expression {
			$<info>$ = handleRule("logic_expression", 
			"rel_expression", 
			$<info>1->getName());
			$<info>$->setVariableType($<info>1->getVariableType());	
		}	
		| rel_expression LOGICOP rel_expression {
			$<info>$ = handleRule("logic_expression", 
			"rel_expression LOGICOP rel_expression", 
			$<info>1->getName() + $<info>2->getName() + $<info>3->getName());
			$<info>$->setVariableType(
			binaryOperator($<info>1, $<info>2->getName(), $<info>3));
			$<info>$->setVariableType("int");	// forced set
		}
		;
			
rel_expression	: simple_expression {
			$<info>$ = handleRule("rel_expression", 
			"simple_expression",
			$<info>1->getName());
			$<info>$->setVariableType($<info>1->getVariableType());	
		}
		| simple_expression RELOP simple_expression {
			$<info>$ = handleRule("rel_expression", 
			"simple_expression RELOP simple_expression", 
			$<info>1->getName() + $<info>2->getName() + $<info>3->getName());
			$<info>$->setVariableType(
			binaryOperator($<info>1, $<info>2->getName(), $<info>3));
			$<info>$->setVariableType("int");	// forced set
		}
		;
				
simple_expression : term  {
			$<info>$ = handleRule("simple_expression", 
			"term", 
			$<info>1->getName());
			$<info>$->setVariableType($<info>1->getVariableType());		
		}
		| simple_expression ADDOP term {
			$<info>$ = handleRule("simple_expression", 
			"simple_expression ADDOP term",
			$<info>1->getName() + $<info>2->getName() + $<info>3->getName());
			$<info>$->setVariableType(
			binaryOperator($<info>1, $<info>2->getName(), $<info>3));
		}
		;
					
term :	unary_expression {
			$<info>$ = handleRule("term", 
			"unary_expression", 
			$<info>1->getName());
			$<info>$->setVariableType($<info>1->getVariableType());	
		}
     	|  term MULOP unary_expression {
			$<info>$ = handleRule("term", 
			"term MULOP unary_expression", 
			$<info>1->getName() + $<info>2->getName() + $<info>3->getName());
			$<info>$->setVariableType(
			binaryOperator($<info>1, $<info>2->getName(), $<info>3));
		}
     	;

unary_expression : ADDOP unary_expression {
			$<info>$ = handleRule("unary_expression", 
			"ADDOP unary_expression", 
			$<info>1->getName() + $<info>2->getName());
			$<info>$->setVariableType($<info>2->getVariableType());	
		}
		| NOT unary_expression {
			$<info>$ = handleRule("unary_expression", 
			"NOT unary_expression", 
			"!" + $<info>2->getName());
			$<info>$->setVariableType("int");
		}
		| factor {
			$<info>$ = handleRule("unary_expression", 
			"factor", 
			$<info>1->getName());
			$<info>$->setVariableType($<info>1->getVariableType());	
		}
		;
	
factor	: variable {
			$<info>$ = handleRule("factor", 
			"variable", 
			$<info>1->getName());
			$<info>$->setVariableType($<info>1->getVariableType());
		}
		| ID LPAREN argument_list RPAREN {
			$<info>$ = handleRule("factor",
			"ID LPAREN argument_list RPAREN", 
			$<info>1->getName() + "(" + 
			$<info>3->getName() + ")");
			
			$<info>$->setVariableType("int");	/// default to skip redundant errors
			SymbolInfoPtr sip = table->lookUp($<info>1->getName());
			if (sip==nullptr) {
				showError("Undeclared Function: " + $<info>1->getName());
			} else {
				$<info>$->setVariableType(sip->getVariableType());
				if (!sip->isFunction()) {
					showError("Declared " + $<info>1->getName() + " is not a function");
				} else {
					FunctionInfoPtr fip = sip->getFunctionInfo();
					$<info>$->setVariableType(fip->returnType);
					if (argTypes.size() != fip->parameters.size()) {
						showError("Argument list size doesn't match parameter list");
					} else {
						for (int i = 0; i < argTypes.size(); i++) {
							argTypes[i] = convert(argTypes[i], fip->parameters[i].type);
							if (fip->parameters[i].type != argTypes[i]) {
								showError("Type mismatch for parameter: " + 
								fip->parameters[i].id);								
							}
						}
					}
				}
			}
			argTypes.clear();
		}
		| LPAREN expression RPAREN {
			$<info>$ = handleRule("factor", 
			"LPAREN expression RPAREN", 
			"(" + $<info>2->getName() + ")");
			$<info>$->setVariableType($<info>2->getVariableType());
		}
		| CONST_INT {
			$<info>$ = handleRule("factor", 
			"CONST_INT", 
			$<info>1->getName());
			$<info>$->setVariableType("int");
		}
		| CONST_FLOAT {
			$<info>$ = handleRule("factor", 
			"CONST_FLOAT", 
			$<info>1->getName());
			$<info>$->setVariableType("float");
		}
		| variable INCOP {
			$<info>$ = handleRule("factor", 
			"variable INCOP", 
			$<info>1->getName() + "++");
			$<info>$->setVariableType($<info>1->getVariableType());
		}
		| variable DECOP {
			$<info>$ = handleRule("factor", 
			"variable DECOP", 
			$<info>1->getName() + "--");
			$<info>$->setVariableType($<info>1->getVariableType());
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
			argTypes.push_back($<info>3->getVariableType());
		}
	   	| logic_expression {
			$<info>$ = handleRule("arguments", 
			"logic_expression", 
			$<info>1->getName());
			argTypes.push_back($<info>1->getVariableType());
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

	table = new SymbolTable(10);
	table->enterScope();
	yyparse();
	table->printAllScopeTable(logout);

	logout << "Total Lines: " << line_count << "\n\n";
	logout << "Total Errors: " << error_count << "\n";
	errorout << "Total Errors: " << error_count << "\n";

	delete table;
	fclose(fin);
	logout.close();
    errorout.close();

	return 0;
}


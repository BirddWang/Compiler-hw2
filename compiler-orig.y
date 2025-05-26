/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_common.h"
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void insert_symbol();
    static void lookup_symbol();
    static void dump_symbol();

    /* Global variables */
    bool HAS_ERROR = false;
    int scope_level = 0; // Current scope level
    int addr_counter = 0; // Current address counter

    typedef struct {
        char name[64];
        char type[16];
        int mut;
        int addr;
        int line;
        int scope;
    } Symbol;

    Symbol symbol_table[1024]; // Symbol table, you can change the size
    int symbol_count = 0; // Current symbol count
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    /* ... */
}

/* Token without return */
%token LET MUT NEWLINE
%token INT FLOAT BOOL STR
%token TRUE FALSE
%token GEQ LEQ EQL NEQ LOR LAND
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN
%token IF ELSE FOR WHILE LOOP
%token PRINT PRINTLN
%token FUNC RETURN BREAK
%token ID ARROW AS IN DOTDOT RSHIFT LSHIFT

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <s_val> IDENT

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : GlobalStatementList
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | GlobalStatement
;

GlobalStatement
    : FunctionDeclStmt
    | NEWLINE
;

FunctionDeclStmt
    : FUNC ID 
        {
            printf("func: %s\n", $2);
            create_symbol();
            insert_symbol();
        }
    '(' ')' FunctionBlock
;

FunctionBlock
    : '{'
        {
            create_symbol();
            scope_level++;
            addr_counter = 0;
        }
      StatementList '}'
        {
            dump_symbol();
            scope_level--;
            if(scope_level == 0) {
                dump_symbol();
            }
        }
;

StatementList
    : StatementList Statement
    | /* empty */
;

Statement
    : VariableDeclStmt
    | PrintStmt
    | /* empty */
;

VariableDeclStmt
    : LET ID ':' Type '=' Expression ';'
        {
            printf("INT_LIT: %d\n", $<i_val>6);
            insert_symbol();
        }
;

PrintStmt
    : PRINTLN '(' Expression ')' ';'
        {
            printf("PRINTLN: %s\n", $<s_val>3);
        }
;

Expression
    : Expression '+' Expression
        {
            printf("ADD: %s + %s\n", $<s_val>1, $<s_val>3);
        }
    | Expression '-' Expression
        {
            printf("SUB: %s - %s\n", $<s_val>1, $<s_val>3);
        }
    | Expression '*' Expression
        {
            printf("MUL: %s * %s\n", $<s_val>1, $<s_val>3);
        }
    | Expression '/' Expression
        {
            printf("DIV: %s / %s\n", $<s_val>1, $<s_val>3);
        }
    | Expression '%' Expression
        {
            printf("REM: %s %% %s\n", $<s_val>1, $<s_val>3);
        }
    | ID
        {
            int addr = lookup_symbol($1);
            if (addr >= 0) {
                printf("IDENT (name: %s, addr: %d)\n", $1, addr);
            }
        }
    | INT_LIT
        {
            printf("INT_LIT: %d\n", $<i_val>1);
        }
    | FLOAT_LIT
        {
            printf("FLOAT_LIT: %f\n", $<f_val>1);
        }
    | STRING_LIT
        {
            printf("STRING_LIT: %s\n", $<s_val>1);
        }
    | '(' Expression ')'
;

Type
    : INT
        {
            $$ = strdup("i32");
        }
    | FLOAT
        {
            $$ = strdup("f32");
        }
    | BOOL
        {
            $$ = strdup("bool");
        }
    | STR
        {
            $$ = strdup("str");
        }

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yylineno = 0;
    yyparse();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_symbol() {
    printf("> Create symbol table (scope level %d)\n", 0);
}

static void insert_symbol() {
    printf("> Insert `%s` (addr: %d) to scope level %d\n", "XXX", 0, 0);
}

static void lookup_symbol() {
}

static void dump_symbol() {
    printf("\n> Dump symbol table (scope level: %d)\n", 0);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s%-10s\n",
        "Index", "Name", "Mut","Type", "Addr", "Lineno", "Func_sig");
    printf("%-10d%-10s%-10d%-10s%-10d%-10d%-10s\n",
            0, "name", 0, "type", 0, 0, "func_sig");
}

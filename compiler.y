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

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void insert_symbol(char* name, char* type, int mut, int line);
    static int lookup_symbol(char* name);
    static void dump_symbol();

    /* Global variables */
    bool HAS_ERROR = false;
    int scope_level = 0;
    int addr_counter = 0;
    
    // 簡單的符號表結構
    typedef struct {
        char name[64];
        char type[16];
        int mut;
        int addr;
        int line;
        int scope;
    } Symbol;
    
    Symbol symbol_table[1000];
    int symbol_count = 0;
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
%token ARROW AS IN DOTDOT RSHIFT LSHIFT

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <s_val> ID

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type
%type <s_val> Expression

/* 運算符優先級和結合性 */
%left LOR
%left LAND
%left '|'
%left '&'
%left EQL NEQ
%left '<' '>' LEQ GEQ
%left LSHIFT RSHIFT
%left '+' '-'
%left '*' '/' '%'
%right '!' '~'
%right UMINUS

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
    | /* empty */
;

FunctionDeclStmt
    : FUNC ID 
        {
            printf("func: %s\n", $2);
            insert_symbol($2, "func", -1, yylineno);
        }
      '(' ')' FunctionBlock
;

FunctionBlock
    : '{' 
        {
            scope_level++;
            create_symbol();
            addr_counter = 0;
        }
      StatementList '}'
        {
            printf("\n");
            dump_symbol();
            printf("\n");
            scope_level--;
            dump_symbol();
        }
;

StatementList
    : StatementList Statement
    | /* empty */
;

Statement
    : VariableDeclStmt
    | PrintStmt ';'
    | ';'
    | /* empty */
;

VariableDeclStmt
    : LET ID ':' Type '=' Expression ';'
        {
            insert_symbol($2, $4, 0, yylineno);
        }
;

PrintStmt 
    : PRINTLN '('  Expression  ')'
        {
            printf("PRINTLN %s\n", $3);
        }
;

Expression
    : Expression '+' Expression
        {
            $$ = $1;
            printf("ADD\n");
        }
    | Expression '-' Expression
        {
            $$ = $1;
            printf("SUB\n");
        }
    | Expression '*' Expression
        {
            $$ = $1;
            printf("MUL\n");
        }
    | Expression '/' Expression
        {
            $$ = $1;
            printf("DIV\n");
        }
    | Expression '%' Expression
        {
            $$ = $1;
            printf("REM\n");
        }
    | ID
        {
            int idx = lookup_symbol($1);
            if (idx >= 0) {
                printf("IDENT (name=%s, address=%d)\n", $1, symbol_table[idx].addr);
                $$ = symbol_table[idx].type;
            }
        }
    | INT_LIT
        {
            printf("INT_LIT %d\n", $1);
            $$ = "i32";
        }
    | FLOAT_LIT
        {
            printf("FLOAT_LIT %f\n", $1);
            $$ = "f32";
        }
    | '"' STRING_LIT '"'
        {
            printf("STRING_LIT \"%s\"\n", $2);
            $$ = "str";
        }
    | '(' Expression ')'
        {
            $$ = $2;
        }
;

Type
    : INT    { $$ = "i32"; }
    | FLOAT  { $$ = "f32"; }
    | BOOL   { $$ = "bool"; }
    | STR    { $$ = "str"; }
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yylineno = 1;
    create_symbol();  // 創建全域符號表
    yyparse();

    printf("Total lines: %d\n", yylineno);
    if (argc == 2) {
        fclose(yyin);
    }
    return 0;
}

static void create_symbol() {
    printf("> Create symbol table (scope level %d)\n", scope_level);
}

static void insert_symbol(char* name, char* type, int mut, int line) {
    if (strcmp(type, "func") == 0) {
        printf("> Insert `%s` (addr: %d) to scope level %d\n", name, -1, scope_level);
        // 添加到符號表
        strcpy(symbol_table[symbol_count].name, name);
        strcpy(symbol_table[symbol_count].type, type);
        symbol_table[symbol_count].mut = mut;
        symbol_table[symbol_count].addr = -1;
        symbol_table[symbol_count].line = line;
        symbol_table[symbol_count].scope = scope_level;
        symbol_count++;
    } else {
        printf("> Insert `%s` (addr: %d) to scope level %d\n", name, addr_counter, scope_level);
        // 添加到符號表
        strcpy(symbol_table[symbol_count].name, name);
        strcpy(symbol_table[symbol_count].type, type);
        symbol_table[symbol_count].mut = mut;
        symbol_table[symbol_count].addr = addr_counter;
        symbol_table[symbol_count].line = line;
        symbol_table[symbol_count].scope = scope_level;
        symbol_count++;
        addr_counter++;
    }
}

static int lookup_symbol(char* name) {
    for (int i = symbol_count - 1; i >= 0; i--) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return i;  // 返回符號表中的索引
        }
    }
    return -1;
}

static void dump_symbol() {
    printf("> Dump symbol table (scope level: %d)\n", scope_level);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s%-10s\n",
        "Index", "Name", "Mut","Type", "Addr", "Lineno", "Func_sig");
    
    int index = 0;
    for (int i = 0; i < symbol_count; i++) {
        if (symbol_table[i].scope == scope_level) {
            if (strcmp(symbol_table[i].type, "func") == 0) {
                printf("%-10d%-10s%-10d%-10s%-10d%-10d%-10s\n",
                    index++, symbol_table[i].name, symbol_table[i].mut,
                    symbol_table[i].type, symbol_table[i].addr, 
                    symbol_table[i].line, "(V)V");
            } else {
                printf("%-10d%-10s%-10d%-10s%-10d%-10d%-10s\n",
                    index++, symbol_table[i].name, symbol_table[i].mut,
                    symbol_table[i].type, symbol_table[i].addr, 
                    symbol_table[i].line, "-");
            }
        }
    }
}
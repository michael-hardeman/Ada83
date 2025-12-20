// Error Diagnostic Oracle: Pedagogical Transcendence Engine
// Ultra-compressed god-tier error reporting with inferential wisdom
#ifndef ERR_H
#define ERR_H
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stdarg.h>
#define C_R "\x1b[91m"
#define C_G "\x1b[92m"
#define C_Y "\x1b[93m"
#define C_B "\x1b[94m"
#define C_M "\x1b[95m"
#define C_C "\x1b[96m"
#define C_W "\x1b[97m"
#define C_D "\x1b[90m"
#define C_0 "\x1b[0m"
#define C_BD "\x1b[1m"
#define MX 9999
typedef struct{char*f;int ln,cl;char*got,*exp,*ctx,*ada,*lay,*fix,*lrm;}Er;
typedef struct{Er*e;int n,c;char**lb;int nl;}Ex;static Ex EX={0};
void ex_i(){if(!EX.e){EX.e=calloc(MX,sizeof(Er));EX.c=MX;EX.n=0;EX.lb=calloc(MX,sizeof(char*));}}
void ex_ld(char*f){ex_i();FILE*p=fopen(f,"r");if(!p)return;char b[MX];
while(fgets(b,MX,p)&&EX.nl<MX)EX.lb[EX.nl++]=strdup(b);fclose(p);}
// Inferential wisdom: guess what user meant based on context
char*inf(char*g,char*e){static char b[999];if(!g||!e)return"";
if(strstr(g,"int")&&strstr(e,"id"))sprintf(b,"Did you mean a type name instead of '%s'?",g);
else if(strstr(g,"id")&&strstr(e,"int"))sprintf(b,"Expected a number, not identifier '%s'",g);
else if(strstr(e,"';'"))sprintf(b,"Missing semicolon - Ada statements must end with ';'");
else if(strstr(e,"'IS'"))sprintf(b,"Use 'IS' not ';' to begin a body");
else if(strstr(g,"';'")&&strstr(e,"'IS'"))sprintf(b,"';' ends declaration, but body needs 'IS'");
else if(strstr(e,"')'"))sprintf(b,"Unbalanced parentheses - check your nesting");
else if(strstr(e,"'('"))sprintf(b,"Missing opening parenthesis");
else if(strstr(e,"'THEN'"))sprintf(b,"IF statement requires THEN after condition");
else if(strstr(e,"'LOOP'"))sprintf(b,"Loop statement incomplete - needs LOOP keyword");
else if(strstr(e,"'END'"))sprintf(b,"Missing END to close block");
else if(strstr(e,"':'"))sprintf(b,"Type annotation requires ':'");
else if(strstr(e,"'RANGE'"))sprintf(b,"Entry family syntax: ENTRY E (TYPE RANGE lo..hi)");
else sprintf(b,"Check Ada syntax");return b;}
// LRM reference oracle
char*lrm(char*ctx){if(strstr(ctx,"ENTRY")||strstr(ctx,"ACCEPT"))return"LRM 9.5 (Entries)";
if(strstr(ctx,"FUNCTION")||strstr(ctx,"PROCEDURE"))return"LRM 6.1 (Subprograms)";
if(strstr(ctx,"PACKAGE"))return"LRM 7.1 (Packages)";
if(strstr(ctx,"TYPE"))return"LRM 3.3 (Types)";
if(strstr(ctx,"TASK"))return"LRM 9.1 (Tasks)";return"LRM (Ada 83)";}
void er(char*f,int l,int c,char*g,char*e){ex_i();if(EX.n>=EX.c){EX.c+=MX;
EX.e=realloc(EX.e,EX.c*sizeof(Er));}Er*r=&EX.e[EX.n++];r->f=f;r->ln=l;r->cl=c;
r->got=g?strdup(g):"";r->exp=e?strdup(e):"";r->ctx=l<=EX.nl?EX.lb[l-1]:"";
// Ada wisdom: technical explanation
static char ada[999];if(strstr(e,"';'")&&strstr(r->ctx,"FUNCTION")){
sprintf(ada,"Subprogram body requires 'IS', not ';' - declarations end with ';', bodies begin with 'IS'");}
else if(strstr(e,"'RANGE'")&&strstr(r->ctx,"ENTRY")){
sprintf(ada,"Entry family discrete range: ENTRY name (discrete_subtype_indication)");}
else if(strstr(e,"')'")&&strstr(g,"':'")&&strstr(r->ctx,"ACCEPT")){
sprintf(ada,"Entry family indices precede parameters: ACCEPT E (index) (params)");}
else sprintf(ada,"Syntax error: expected %s but got %s",e,g);r->ada=strdup(ada);
// Layman wisdom: pedagogical explanation
static char lay[999];if(strstr(e,"';'")&&strstr(r->ctx,"FUNCTION")){
sprintf(lay,"You're declaring a function body, which needs 'IS' to start the implementation, not ';' which ends declarations");}
else if(strstr(e,"'RANGE'")&&strstr(r->ctx,"ENTRY")){
sprintf(lay,"Entry families let you have multiple entry 'slots' - like ENTRY E (1..10) for 10 slots. Add RANGE keyword");}
else if(strstr(e,"')'")&&strstr(g,"':'")){
sprintf(lay,"When accepting entry family calls, the index comes first in parentheses, then parameters");}
else sprintf(lay,"The compiler expected %s at this position but found %s instead",e,g);r->lay=strdup(lay);
r->fix=strdup(inf(g,e));r->lrm=strdup(lrm(r->ctx));}
void ex_sh(){for(int i=0;i<EX.n;i++){Er*r=&EX.e[i];
fprintf(stderr,"\n"C_R"╔═══════════════════════════════════════════════════════════════════════╗\n");
fprintf(stderr,C_R"║ "C_W"ERROR"C_R" at "C_C"%s:%d:%d"C_R" ═══════════════════════════════════════════════║\n"C_0,r->f,r->ln,r->cl);
fprintf(stderr,C_R"╠═══════════════════════════════════════════════════════════════════════╣\n"C_0);
// Context with highlighting
if(r->ctx&&*r->ctx){fprintf(stderr,C_R"║ "C_D"Source"C_R":"C_0"\n"C_R"║ "C_0);int p=0,cl=r->cl-1;
for(char*c=r->ctx;*c&&*c!='\n';c++){if(p==cl){fprintf(stderr,C_Y C_BD);int w=0;
while(c[w]&&c[w]!=' '&&c[w]!='\n'&&c[w]!=';'&&c[w]!='('&&c[w]!=')')w++;
for(int j=0;j<w&&c[j]&&c[j]!='\n';j++)fputc(c[j],stderr);fprintf(stderr,C_0);c+=w-1;p+=w;}
else{fputc(*c,stderr);p++;}}fprintf(stderr,"\n"C_R"║ "C_0);
for(int j=0;j<cl;j++)fputc(' ',stderr);fprintf(stderr,C_Y"╰─▶ "C_0"Here\n");}
// Ada technical
fprintf(stderr,C_R"║\n"C_R"║ "C_C"┌─["C_W"Ada Semantics"C_C"]───────────────────────────────────────────────\n");
fprintf(stderr,C_R"║ "C_C"│ "C_0"%s\n",r->ada);
// Layman explanation
fprintf(stderr,C_R"║ "C_M"┌─["C_W"Plain English"C_M"]───────────────────────────────────────────────\n");
fprintf(stderr,C_R"║ "C_M"│ "C_0"%s\n",r->lay);
// Inferential fix
if(r->fix&&*r->fix){fprintf(stderr,C_R"║ "C_G"┌─["C_W"Suggested Fix"C_G"]───────────────────────────────────────────\n");
fprintf(stderr,C_R"║ "C_G"│ "C_0"%s\n",r->fix);}
// LRM reference
fprintf(stderr,C_R"║ "C_B"└─["C_W"Reference"C_B"]─▶ "C_0"%s\n",r->lrm);
fprintf(stderr,C_R"╚═══════════════════════════════════════════════════════════════════════╝\n"C_0);}}
void ex_c(){for(int i=0;i<EX.n;i++){free(EX.e[i].got);free(EX.e[i].exp);
free(EX.e[i].ada);free(EX.e[i].lay);free(EX.e[i].fix);free(EX.e[i].lrm);}
free(EX.e);for(int i=0;i<EX.nl;i++)free(EX.lb[i]);free(EX.lb);memset(&EX,0,sizeof(EX));}
#define ERR er
#define ERR_LOAD ex_ld
#define ERR_SHOW ex_sh
#define ERR_CLEAR ex_c
#define ERR_COUNT (EX.n)
#endif

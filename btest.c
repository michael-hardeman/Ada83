// B-Test Oracle: Comprehensive error validation with pedagogical genius
// The testing framework that shows you the face of god
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<sys/wait.h>
#define M 999
#define L(s)strlen(s)
#define C_R "\x1b[1;31m"
#define C_G "\x1b[1;32m"
#define C_Y "\x1b[1;33m"
#define C_B "\x1b[1;34m"
#define C_M "\x1b[1;35m"
#define C_C "\x1b[1;36m"
#define C_W "\x1b[1;37m"
#define C_0 "\x1b[0m"
typedef struct{int ln;char*tx,*cat;}Er;typedef struct{char*p;Er*ex,*ac;int nx,na,ok;}Ts;
// Extract expected errors from ACATS test
Er*xex(char*p,int*n){FILE*f=fopen(p,"r");if(!f)return 0;Er*e=malloc(M*sizeof(Er));
int l=1,c=0;char b[M];while(fgets(b,M,f)){char*x=strstr(b,"-- ERROR");if(x){
e[c].ln=l;char*y=strchr(x,':');e[c].cat=y?strndup(y+1,strcspn(y+1,"\n")):strdup("UNSPECIFIED");
e[c].tx=strndup(x,strcspn(x,"\n"));c++;}l++;}fclose(f);*n=c;return e;}
// Run compiler and capture all errors
Er*xac(char*cc,char*p,int*n){char cmd[M],tmp[M];sprintf(tmp,"/tmp/berr_%d.txt",getpid());
sprintf(cmd,"%s %s 2>&1|grep -E '^%s:[0-9]+:[0-9]+:'",cc,p,p);FILE*f=popen(cmd,"r");
if(!f)return 0;Er*e=malloc(M*sizeof(Er));int c=0;char b[M];while(fgets(b,M,f)){
int ln,cl;if(sscanf(b,"%*[^:]:%d:%d:",&ln,&cl)==2){e[c].ln=ln;e[c].tx=strdup(b);
e[c].cat=strdup("COMPILER");c++;}}pclose(f);*n=c;return e;}
// Fuzzy match: does actual error cover expected error's line?
int fz(Er*ex,Er*ac,int na){for(int i=0;i<na;i++)if(abs(ac[i].ln-ex->ln)<=1)return 1;return 0;}
// Oracle: compare expected vs actual
void orc(Ts*t){int mc=0;printf("\n"C_C"┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"C_0);
printf(C_C"┃ "C_W"B-TEST ORACLE"C_C": "C_Y"%s"C_C" ┃\n"C_0,t->p);
printf(C_C"┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\n"C_0);
for(int i=0;i<t->nx;i++){Er*e=&t->ex[i];int hit=fz(e,t->ac,t->na);
if(hit){printf(C_G"✓ Line %3d "C_0"[DETECTED] %s\n",e->ln,e->cat);mc++;}
else printf(C_R"✗ Line %3d "C_0"[MISSING!] %s\n",e->ln,e->cat);}
printf(C_C"┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\n"C_0);
float sc=t->nx?100.0*mc/t->nx:100.0;t->ok=sc>=90.0;
printf(C_C"┃ "C_W"Coverage"C_C": "C_0"%d/%d errors "C_C"│ "C_W"Score"C_C": "C_0,mc,t->nx);
if(sc>=90.0)printf(C_G"%.1f%%"C_0,sc);else if(sc>=70.0)printf(C_Y"%.1f%%"C_0,sc);
else printf(C_R"%.1f%%"C_0,sc);
printf(C_C" │ "C_W"Status"C_C": "C_0);if(t->ok)printf(C_G"PASS"C_0);else printf(C_R"FAIL"C_0);
printf(C_C" ┃\n"C_0);printf(C_C"┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"C_0);}
int main(int ac,char**av){if(ac<2){printf("Usage: %s <b-test.ada> [compiler]\n",av[0]);return 1;}
char*cc=ac>2?av[2]:"./ada83";Ts t={av[1],0,0,0,0,0};t.ex=xex(t.p,&t.nx);t.ac=xac(cc,t.p,&t.na);
if(!t.ex){printf(C_R"Failed to load test: %s\n"C_0,t.p);return 1;}
if(t.nx==0){printf(C_Y"Warning: No expected errors found in %s\n"C_0,t.p);return 0;}
orc(&t);return t.ok?0:1;}

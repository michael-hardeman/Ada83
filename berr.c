// B-test Error Oracle: Extract expected errors from ACATS B tests
// Ultra-compressed pedagogical diagnostic engine
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<ctype.h>
#define M 999
#define L(s)strlen(s)
typedef struct{int ln;char*tx;}Er;typedef struct{char*pth;Er*es;int n,c;}Ts;
Er*xer(FILE*f,int*n){Er*e=malloc(M*sizeof(Er));int l=1,c=0;char b[999];
while(fgets(b,999,f)){char*p=strstr(b,"-- ERROR");if(p){e[c].ln=l;
int i=0;while(p[i]&&p[i]!='\n')i++;e[c].tx=strndup(p,i);c++;}l++;}*n=c;return e;}
void prf(Er*e,int n){for(int i=0;i<n;i++)printf("%d:%s\n",e[i].ln,e[i].tx);}
Ts*ld(char*d){Ts*ts=malloc(M*sizeof(Ts));char cmd[999];
sprintf(cmd,"find %s -name 'b*.ada'|head -100",d);FILE*p=popen(cmd,"r");
char pth[999];int c=0;while(fgets(pth,999,p)){pth[L(pth)-1]=0;
FILE*f=fopen(pth,"r");if(f){ts[c].pth=strdup(pth);ts[c].es=xer(f,&ts[c].n);
ts[c].c=0;fclose(f);c++;}}pclose(p);ts[c].pth=0;return ts;}
int main(int ac,char**av){Ts*ts=ld(ac>1?av[1]:"acats");
for(int i=0;ts[i].pth;i++){printf("\n\x1b[1;36m%s\x1b[0m (%d errors expected)\n",
ts[i].pth,ts[i].n);prf(ts[i].es,ts[i].n);}return 0;}

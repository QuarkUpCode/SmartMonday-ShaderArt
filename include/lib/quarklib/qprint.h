#ifndef QPRINT
#define QPRINT

#define QPRINT_ERROR 1
#define QPRINT_DEBUG 1
#define QPRINT_LOG 1

#define QDOXX qprint("$cb%s$0 @ $cb%s$0 : ", __FILE__, __FUNCTION__);
#define qlog(...) if(QPRINT_LOG){QDOXX qprint(__VA_ARGS__);}
#define qdebug(...) if(QPRINT_DEBUG){qprint(__VA_ARGS__);}
#define qerror(...) if(QPRINT_ERROR){qprint("$cr$bERROR$0$b "); QDOXX qprint(__VA_ARGS__);}
#define qvald(x) if(QPRINT_DEBUG){qprint("%s = %d\n", #x, x);}
#define qvalf(x) if(QPRINT_DEBUG){qprint("%s = %f\n", #x, x);}

void qprint(char* str, ...);

#endif /* QPRINT */
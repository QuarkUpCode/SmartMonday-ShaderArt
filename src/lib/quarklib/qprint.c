#include <stdarg.h>
#include <unistd.h>

#include "qprint.h"


/*

	hey so uuuhhh i never really intended for anyone to read this so uuhh, its ugly af i prototyped it in 30 minutes drunk on sleep deprivation, please dont read any code further down here :c

*/


void send_float(double f, int lm, int pm){

	char c;
	float base = 10.f;
	int bi = 10;
	float t=f;
	float d=1.f;
	int e=0;
	float whole = 0;
	// qvald(e);
	while(t>1.f){
		t/=base;
		d*=base;
		e++;
	}

	// qlog("e : %d")
	int s = lm-e;
	while(s>0){
		c = ' ';
		write(1, &c, 1);
		s--;
	}
	int i=0;
	while(i<e){
		d/=base;
		c = '0' + ((int)(f/d)%bi);
		//extremely ugly please change in the future
		whole *= base;
		whole += (int)(f/d)%bi;
		write(1, &c, 1);
		i++;
	}
	c = '.';
	write(1, &c, 1);
	i=0;
	d = 1.f;
	t = f-whole;
	t *= base;
	while(i<pm){
		c = '0' + (((int)t) % bi);
		t *= base;
		t -= base * ((int)t / bi);
		write(1, &c, 1);
		// qvalf((f*d));
		// printf("%f\n", (t));
		// qvald(c);
		d*=base;
		i++;
	}

}

void send_int(int n, int lm, char hex){
	
	char c;

	if(n == 0){
		c = '0';
		write(1, &c, 1);
		return;
	}

	int base = 10;
	if(hex) base = 16;
	
	int t=n;
	int d=1;
	int e=0;
	while(t>0){
		t/=base;
		d*=base;
		e++;
	}
	int s = lm-e;
	while(s > 0){
		c = ' ';
		if(hex) c='0';
		write(1, &c, 1);
		s--;
	}

	int i=0;
	while(i<e){
		d/=base;
		c = '0' + ((n/d)%base);
		if(hex && '9'<c) c+= 'a' - '0';
		write(1, &c, 1);
		i++;
	}

	return;
}

int parse_lm(int* ip, char* str){
	
	int l = 0;
	int base=10;
	int i = *ip;
	// printf("i = %d\n", i);

	if(str[i] == '0'){
		i++;
		base = 8;
	}
	while(('0' <= str[i] && str[i] <= '9')){
		l*=base;
		l+=str[i]-'0';
		i++;
	}
	*ip = i;
	// printf("i = %d\n", i);
	return l;
}

// int count_args(char* str){
// 	int count=0;
// 	int i=0;
// 	while(str[i]) if(str[i] == '%') count++;
// 	return count;
// }

void qesc(){
	write(1, "\e[", 2);
}
void qend(){
	write(1, "m", 1);
}
void qres(){
	write(1, "\e[0m", 4);
}

int qcolor(int n){
	qesc();
	send_int(n, 0, 0);
	qend();
}


void qprint(char* str, ...){
	
	va_list ap;

	char c;

	int i=0;
	int lenght_modifier;
	int precision_modifier;
	int base;

	char modifiers = 0;

	va_start(ap, str);
	while(str[i]){
		
		if(str[i] == '%'){
			i++;
			if(!str[i]) return;
			// printf("i = %d\n", i);
			lenght_modifier = parse_lm(&i, str);
			precision_modifier = 4;
			if(str[i] == '.'){
				i++;
				if(!str[i]) return;
				precision_modifier = parse_lm(&i, str);
			}
			// printf("i = %d\n", i);
			switch(str[i]){
				case 'd':
					send_int(va_arg(ap, int), lenght_modifier, 0);
					break;
				case 'x':
					send_int(va_arg(ap, int), lenght_modifier, 1);
					break;
				case 'f':
					send_float(va_arg(ap, double), lenght_modifier, precision_modifier);
					break;
				case 's':
					char* ss = va_arg(ap, char*);
					while(*(ss++)) write(1, ss-1, 1);
					break;
				default:
					// c = 'e';
					// write(1, &(str[i]), 1);
					// printf("0x%x", str[i]);
					break;
			}
		}
		else if(str[i] == '$'){
			i++;
			switch(str[i]){
				case '0':
					qres();
					break;
				case 'b':
					modifiers^=0x01;
					qcolor((21*(~modifiers&0x01)) + 1);
					break;
				case 'c':
					i++;
					if(!str[i]) return;
					switch(str[i]){
						case 'r':
							qcolor(91);
							break;
						case 'g':
							qcolor(92);
							break;
						case 'b':
							qcolor(94);
							break;
						case 'm':
							qcolor(95);
							break;
						default:
							break;
					}
					break;
				default:
					break;
			}
		}
		else{
			write(1, &(str[i]), 1);
		}
		i++;
	}
	va_end(ap);
}
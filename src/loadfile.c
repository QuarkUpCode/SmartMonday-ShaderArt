#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include "qprint.h"

char* loadfile(char* filename){
	
	FILE* fp = fopen(filename, "r");
	
	if(fp == NULL){
		// fprintf(stderr, "loadfile.c @ loadfile : Unable to open %s\n", filename);
		qerror("Unable to open %s\n", filename);
		return NULL;
	}

	fseek(fp, 0, SEEK_END);
	uint32_t len = ftell(fp);
	fseek(fp, 0, SEEK_SET);

	char* ret = malloc(len*sizeof(char));

	if(ret == NULL){
		// fprintf(stderr, "loadfile.c @ loadfile : Unable to malloc %d bytes\n", len*sizeof(char));
		qerror("Unable to malloc %d bytes\n", len*sizeof(char));
		return NULL;
	}

	int delta = -1;
	int offset = 0;
	while(delta != 0){
		delta = fread(ret+offset, sizeof(char), 4096, fp);
		offset += delta;
	}
	ret[len] = 0x00;

	return ret;
}
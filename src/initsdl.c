#include <SDL2/SDL.h>

#include "qprint.h"

#include "config.h"



SDL_Window* initSDL(char* title){
	
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

	SDL_Window* window = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);

	if(!window){
		// fprintf(stderr, "[Error] SDL_CreateWindow failed\n");
		qerror("SDL_CreateWindow failed\n");
		SDL_Quit();
		return NULL;
	}

	SDL_GLContext glContext = SDL_GL_CreateContext(window);
	if(!glContext){
		// fprintf(stderr, "[Error] SDL_GL_CreateContext failed\n");
		qerror("SDL_GL_CreateContext failed\n");
		SDL_DestroyWindow(window);
		SDL_Quit();
		return NULL;
	}

	return window;
}
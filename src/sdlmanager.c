#include <stdint.h>

#include <SDL2/SDL.h>

#include "config.h"


const uint32_t frameDelay = 1000/FPS;


char m_handleInput(char** keyboardState){

	char done = 0;
	SDL_Event event;

	while(SDL_PollEvent(&event)){
			
		if (event.type == SDL_QUIT) done = 1;
		
		if(event.type == SDL_KEYDOWN){
			switch(event.key.keysym.sym){
				case 'q':
					done = 1;
					break;
				default:
					break;
			}
		}
	}

	*keyboardState = SDL_GetKeyboardState(NULL);

	return done;
}

char m_getkey(char* keyboardState, char key){
	return keyboardState[SDL_GetScancodeFromKey(key)];
}

void m_endFrame(SDL_Window* window, uint32_t* frameStart, uint32_t* frameTime){
	SDL_UpdateWindowSurface(window);
	*frameTime = (SDL_GetTicks() - *frameStart);
	if(*frameTime < frameDelay){
		SDL_Delay(frameDelay - *frameTime);
	};
	*frameStart = SDL_GetTicks();
}
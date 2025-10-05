
#include <SDL2/SDL.h>
#include <CL/cl.h>
#include <stdlib.h>

#include "qprint.h"

#include "config.h"
#include "loadfile.h"
#include "initsdl.h"
#include "sdlmanager.h"

int main(int argc, char** argv){

	/*
		Wrong Usage
	*/
	
	if(argc < 2){
		qprint("Usage : %s filename [-p]\n", argv[0]);
		return;
	}

	/*
		Magic Tool for Later
	*/

	uint8_t flag_post = 0x00;
	if(argc >= 3){
		for(int i=2; i<argc; i++){
			if(argv[i][0] == 0x00) continue;
			if(argv[i][1] == 0x00) continue;
			if(argv[i][0] == '-' && argv[i][1] == 'p') flag_post = 0x01;
		}
	}
	qlog("Flag post : %x\n", flag_post);


	/*
		OpenCL Initialization
	*/
	
	cl_int CL_err = CL_SUCCESS;
	cl_uint numPlatforms = 0;
	CL_err = clGetPlatformIDs(0, NULL, &numPlatforms);
	
	if(!CL_err){
		// printf("%u platform(s) found.\n", numPlatforms);
		qprint("%d platform(s) found.\n", numPlatforms);
	}
	else{
		// printf("Err %d\n", CL_err);
		qerror("CL_err %d", CL_err);
	}
	

	// const char* kernelSource = loadfile("src/kernel/shader.cl");
	qlog("Using kernel source file $b%s$b.\n", argv[1]);
	const char* kernelSource = loadfile(argv[1]);
	if(kernelSource == NULL){
		qerror("loadfile returned $b$cbNULL$0$b pointer, aborting.\n");
		return;
	}


	cl_platform_id platform;
	cl_device_id device;
	cl_context context;
	cl_command_queue queue;
	
	cl_program program;
	
	cl_kernel kernel;
	cl_kernel kernelPost;
	
	cl_mem d_pixelBuffer;
	cl_mem d_pixelBuffer2;
	cl_mem d_depthBuffer;
	cl_mem d_wallBuffer;
	cl_mem d_textureBuffer;
	cl_mem d_textureMetaBuffer;

	size_t dataSize = sizeof(uint32_t) * WIDTH * HEIGHT;

	CL_err = clGetPlatformIDs(1, &platform, NULL);
	CL_err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);

	context = clCreateContext(NULL, 1, &device, NULL, NULL, &CL_err);
	queue = clCreateCommandQueueWithProperties(context, device, NULL, &CL_err);


	/*
		Buffer Creation
	*/

	d_pixelBuffer = clCreateBuffer(context, CL_MEM_READ_WRITE , dataSize, NULL, &CL_err);
	d_pixelBuffer2 = clCreateBuffer(context, CL_MEM_READ_WRITE , dataSize, NULL, &CL_err);
	d_depthBuffer = clCreateBuffer(context, CL_MEM_READ_WRITE , dataSize*sizeof(float)/sizeof(uint32_t), NULL, &CL_err);


	/*
		Program Compilation + Kernel Creation
	*/

	program = clCreateProgramWithSource(context, 1, &kernelSource, NULL, &CL_err);
	
	qlog("Building program\n");
	qdebug("Miaou %d\n", CL_err);
	CL_err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
	qdebug("Miaou %d\n", CL_err);

	kernel = clCreateKernel(program, "shader", &CL_err);
	if(flag_post) kernelPost = clCreateKernel(program, "post", &CL_err);
	

	/*
		SDL stuff
	*/

	SDL_Window* window = initSDL(WINDOWNAME);
	char* keyboardstate;
	// SDL_Event e;

	char done = 0;

	uint32_t frameStart = 0;
	uint32_t frameTime;
	float time = 0.;

	size_t global_size;
	uint32_t size[2] = {WIDTH, HEIGHT};

	cl_mem outputbuffer = d_pixelBuffer;
	if(flag_post) outputbuffer = d_pixelBuffer2;

	while(!done){
		printf("%f\n", time);
		done = m_handleInput(&keyboardstate);

		clSetKernelArg(kernel, 0, sizeof(float), &time);
		clSetKernelArg(kernel, 1, sizeof(size), &size);
		clSetKernelArg(kernel, 2, sizeof(cl_mem), &d_pixelBuffer);
		clSetKernelArg(kernel, 3, sizeof(cl_mem), &d_depthBuffer);

		global_size = WIDTH*HEIGHT;

		CL_err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &global_size, NULL, 0, NULL, NULL);

		clFinish(queue);
		
		if(flag_post){
			clSetKernelArg(kernelPost, 0, sizeof(float), &time);
			clSetKernelArg(kernelPost, 1, sizeof(size), &size);
			clSetKernelArg(kernelPost, 2, sizeof(cl_mem), &d_pixelBuffer);
			clSetKernelArg(kernelPost, 3, sizeof(cl_mem), &d_depthBuffer);
			clSetKernelArg(kernelPost, 4, sizeof(cl_mem), &d_pixelBuffer2);

			global_size = WIDTH*HEIGHT;

			CL_err = clEnqueueNDRangeKernel(queue, kernelPost, 1, NULL, &global_size, NULL, 0, NULL, NULL);

			clFinish(queue);
		}
		
		// CL_err = clEnqueueReadBuffer(queue, d_pixelBuffer, CL_TRUE, 0, dataSize, SDL_GetWindowSurface(window)->pixels, 0, NULL, NULL);
		CL_err = clEnqueueReadBuffer(queue, outputbuffer, CL_TRUE, 0, dataSize, SDL_GetWindowSurface(window)->pixels, 0, NULL, NULL);


		m_endFrame(window, &frameStart, &frameTime);
		time += 1. / ((float)FPS);

	}

	return 0;
}
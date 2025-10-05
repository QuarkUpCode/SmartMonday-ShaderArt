
// uint bgra(float4 color){
// 	uint c = 0x00000000;
// 	c |= ((int)(0xff * color.z) & 0xff)<<24;
// 	c |= ((int)(0xff * color.y) & 0xff)<<16;
// 	c |= ((int)(0xff * color.x) & 0xff)<<8;
// 	c |= ((int)(0xff * color.w) & 0xff)<<0;
// 	return c;
// }

void put_pixel(__global uint* addr, float4 c){
	if(c.x<0.) c.x = 0.;
	if(c.y<0.) c.y = 0.;
	if(c.z<0.) c.z = 0.;
	if(c.x>1.) c.x = 1.;
	if(c.y>1.) c.y = 1.;
	if(c.z>1.) c.z = 1.;
	uchar r,g,b;
	r = (uchar) 255*c.x;
	g = (uchar) 255*c.y;
	b = (uchar) 255*c.z;
	
	//!!! NOPE DO THE ALPHA MULTIPLICATION ETC AT SOME POINT PLEASE
	if(c.w > 0) *addr = 0xff000000 | (r<<16) | (g<<8) | (b<<0);
}

float4 color_mult(float scalar, float4 color){
	return (float4){color.x*scalar, color.y*scalar, color.z*scalar, color.w};
}

float square(float x){
	return x*x;
}

// float4 circle(float2 p, float2 center, float radius, float width, float4 color){
// 	float d = sqrt((p.x-center.x)*(p.x-center.x)  +  (p.y-center.y)*(p.y-center.y)) - radius;
// 	float4 c = {0.f, 0.f, 0.f, 1.f};
// 	if(fabs(d) < width/2.f){
// 		// c = (fabs(d) / width/2.f) * color;
// 		// c = (float4){0.25, 0.5, 0.75, 1.};
// 		c = color_mult((1.f-square(fabs(d) / (width/2.f))), color);
// 	}
// 	return c;
// }

float sdf_circle(float2 p, float2 center, float radius){
	float d = sqrt((p.x-center.x)*(p.x-center.x)  +  (p.y-center.y)*(p.y-center.y)) - radius;
	return d;
}

float4 sdf(float2 p, float4 color){

	float4 c = color;

	float rainbow = fabs(sdf_circle(p, (float2){0.5f, 0.f}, 0.4f-0.05f) - 0.2f);

	c = color_mult(fabs(rainbow), c);
	return c;
}

__kernel void shader(float time, uint2 size, __global uint* pixels, __global uint* depths){

	int id = get_global_id(0);
	int x = id%size.x;
	int y = id/size.x;
	
	float u = (float)x / (float)size.x;
	float v = 1. - ((float)y / (float)size.y);

	// pixels[(y*size.x)+x] = bgra((float4){u, v, u*v, 1.f});
	// pixels[(y*size.x)+x] = 0xffffffff;
	float4 c;

	// c = circle((float2){u-0.5f, (v-0.5f)*((float)size.y/(float)size.x)}, (float2){0.f, 0.f}, 0.2, 0.0625f, (float4){1., 1., 1., 1.});
	c = sdf((float2){u, v}, (float4){1.f, 1.f, 1.f, 1.f});
	// c.x = u;
	// c.y = v;
	// c.z = 0.;
	// c.w = 1.;
	put_pixel(&pixels[(y*size.x)+x], c);
}
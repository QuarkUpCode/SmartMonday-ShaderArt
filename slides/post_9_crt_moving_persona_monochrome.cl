
/*

	Utils

*/

float4 hsva2rgba(float4 hsva){
	
	float4 rgba;
	
	float h,s,v,a;
	if(hsva.x < 0.f) h = (2.f*M_PI_F) + fmod(hsva.x, 2.f*M_PI_F);
	// if(hsva.x < 0.f) h = -hsva.x;
	else h = fmod(hsva.x, 2.f*M_PI_F);
	s = min(max(0.f, hsva.y), 1.f);
	v = min(max(0.f, hsva.z), 1.f);
	a = hsva.w;
	
	float C = v*s;
	float Hp = h / (M_PI_F/3.f);
	float X = C*(1.f-fabs(fmod(Hp, 2.f) - 1.f));
	float m = v-C;
	
	if(0.f<=Hp && Hp<1.f){
		rgba = (float4){C, X, 0.f, a};
	}
	else if(1.f<=Hp && Hp<2.f){
		rgba = (float4){X, C, 0.f, a};
	}
	else if(2.f<=Hp && Hp<3.f){
		rgba = (float4){0.f, C, X, a};
	}
	else if(3.f<=Hp && Hp<4.f){
		rgba = (float4){0.f, X, C, a};
	}
	else if(4.f<=Hp && Hp<5.f){
		rgba = (float4){X, 0.f, C, a};
	}
	else if(5.f<=Hp && Hp<6.f){
		rgba = (float4){C, 0.f, X, a};
	}
	
	rgba += (float4){m, m, m, 0.f};
	
	return rgba;
}

float4 rgba2hsva(float4 rgba){
	float Xmax = max(rgba.x, max(rgba.y, rgba.z));
	float Xmin = min(rgba.x, min(rgba.y, rgba.z));
	float C = Xmax - Xmin;
	float H;
	float S;
	float V = Xmax;
	if(C == 0){
		H = 0.f;
	}
	if(Xmax == rgba.x){
		H = (M_PI_F/3.f) * fmod((rgba.y - rgba.z)/C, 6.f);
	}
	else if(Xmax == rgba.y){
		H = (M_PI_F/3.f) * (((rgba.z - rgba.x)/C) + 2.f);
	}
	else if(Xmax == rgba.z){
		H = (M_PI_F/3.f) * (((rgba.x - rgba.y)/C) + 4.f);
	}
	if(V == 0.f) S=0.f;
	else S = (C/V);
	return (float4){H, S, V, rgba.w};
}

float4 rgba(float r, float g, float b, float a){
	return (float4){r, g, b, a};
}
float4 irgba(int r, int g, int b, int a){
	return (float4){(float)r/255.f, (float)g/255.f, (float)b/255.f, (float)a/255.f};
}

float4 get_pixel(__global uint* addr){
	float4 rgba;
	uchar r, g, b, a;
	uint v = *addr;
	a = (v>>24)&0xff;
	r = (v>>16)&0xff;
	g = (v>>8)&0xff;
	b = (v>>0)&0xff;
	rgba = (float4){(float)r / 255.f, (float)g / 255.f, (float)b / 255.f, (float)a / 255.f};
	return rgba;
}

void put_pixel(__global uint* addr, float4 c){
	
	float4 res;
	
	if(c.x<0.f) c.x = 0.f;
	if(c.y<0.f) c.y = 0.f;
	if(c.z<0.f) c.z = 0.f;
	if(c.x>1.f) c.x = 1.f;
	if(c.y>1.f) c.y = 1.f;
	if(c.z>1.f) c.z = 1.f;

	float4 prev = get_pixel(addr);
	res.w = 1.f - ((1.f - c.w) * (1.f - prev.w));
	res.x = c.x * c.w / res.w + prev.x * prev.w * (1 - c.w) / res.w;
	res.y = c.y * c.w / res.w + prev.y * prev.w * (1 - c.w) / res.w;
	res.z = c.z * c.w / res.w + prev.z * prev.w * (1 - c.w) / res.w;
	
	
	uchar r,g,b,a;
	r = (uchar) 255*res.x;
	g = (uchar) 255*res.y;
	b = (uchar) 255*res.z;
	a = (uchar) 255*res.w;

	*addr = (a<<24) | (r<<16) | (g<<8) | (b<<0);

}

float4 sample(__global uint* pixels, float u, float v, uint2 size){
	if(u<0.f || u>=1.f || v<=0.f || v>1.f) return irgba(0, 0, 0, 0xff);
	int x = (int)(u*((float)size.x));
	int y = (int)((1.f - v)*((float)size.y));
	return get_pixel(&pixels[(y*size.x)+x]);
}

float4 color_add(float4 a, float4 b){
	return (float4){a.x+b.x, a.y+b.y, a.z+b.z, a.w+b.w};
}

float4 color_mult(float scalar, float4 color){
	return (float4){color.x*scalar, color.y*scalar, color.z*scalar, color.w};
}

float square(float x){
	return x*x;
}

float2 uv_scale(float u, float v, float scale){
	float target_u = (u/scale) + 0.5f*(1.f-(1.f/scale));
	float target_v = (v/scale) + 0.5f*(1.f-(1.f/scale));
	return (float2){target_u, target_v};
}

float2 uv_rotate(float uc, float vc, float ratio, float theta){
	float target_u = (uc * cos(theta)) + (vc * sin(theta)) + 0.5f;
	float target_v = (-(uc * sin(theta)) + (vc * cos(theta)))*ratio + 0.5f;
	return (float2){target_u, target_v};
}

/*

	Fun Stuff

*/

float sdf_persona_star(float2 p, float2 center, float n, float dtheta, float radius, char inv){

	float x = p.x-center.x;
	float y = p.y-center.y;

	float d = length((float2){x, y});

	float theta = atan2(y, x) + dtheta;
	
	float k = 1.f;
	float m = 2.f;

	float r = radius*cos(((2.f * asin(k)) + (M_PI_F*m)) / (2.f*n)) / cos((2.f*asin(k * cos(n*theta)) + (M_PI_F*m))/(2.f*n));

	/* return value ( /!\ not orthogonal distance)*/
	float f = radius*2.f;
	if(d<=r){
		if(!inv) return ((d/r) * f);
		return -((d/r) * f);
	}
	return INFINITY;
}

float4 sdf(float2 p, float4 colorA, float4 colorB, float4 colorC, float t){

	const float2 origin = {0.f, 0.f};

	const float F = 8.f;
	const float phi = -0.5f * 2.f*M_PI_F;
	const float outline = 0.005f;

	float v = INFINITY;
	
	const float4 BLACK = irgba(0x00, 0x00, 0x00, 0xff);
	const float4 GREY = irgba(0x60, 0x60, 0x60, 0xff);
	float4 color = GREY;

	/*
		i sincerely apologize to anyone reading the following code
		to anyone interested in the subject :
		usually you would have an array of those parameters, an loop over each element,
		this could even come from CPUland, with a previous HOST->DEVICE bus trip
	*/
	
	float sdf_val;

	float2 c = origin;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.f, 0.2f, 0)+1.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;
	
	c.x = 0.1f; c.y = 0.1f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.2f, 0.2f, 1)+0.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = GREY;
	
	c.x = 0.2f; c.y = 0.15f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.4f, 0.225f, 0)+3.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;
	
	c.x = 0.1f; c.y = -0.2f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.6f, 0.2f, 0)+4.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = GREY;
	
	c.x = 0.25f; c.y = -0.025f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.8f, 0.175f, 0)-1.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;
	
	c.x = -0.1f; c.y = -0.15f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.8f, 0.2f, 1)+2.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;

	c.x = 0.25f; c.y = -0.185f;
	sdf_val = sdf_persona_star(p, c, 5.f, 1.2f, 0.15f, 0)+8.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = GREY;

	c.x = 0.f; c.y = 0.275f;
	sdf_val = sdf_persona_star(p, c, 5.f, 1.4f, 0.2f, 0)+7.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;

	c.x = -0.1f; c.y = 0.1f;
	sdf_val = sdf_persona_star(p, c, 5.f, 1.6f, 0.2f, 1)+6.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = GREY;

	c.x = 0.4f; c.y = 0.2f;
	sdf_val = sdf_persona_star(p, c, 5.f, 1.8f, 0.225f, 1)+9.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;

	c.x = 0.35f; c.y = 0.05f;
	sdf_val = sdf_persona_star(p, c, 5.f, 2.0f, 0.2f, 0)+10.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = GREY;

	c.x = 0.4f; c.y = -0.25f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.f, 0.225f, 1)+11.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;

	c.x = 0.375f; c.y = -0.1f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.f, 0.1f, 0)+12.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;

	c.x = 0.15f; c.y = -0.1f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.f, 0.1f, 1)+14.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;

	c.x = 0.5f; c.y = 0.1f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.4f, 0.175f, 1)+15.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = BLACK;

	c.x = 0.5f; c.y = -0.1f;
	sdf_val = sdf_persona_star(p, c, 5.f, 0.4f, 0.175f, 1)+15.f;
	v = min(v, sdf_val);
	if(v == sdf_val) color = GREY;



	if(v == INFINITY) return irgba(0xBA, 0x01, 0x00, 0xff);
	if(sin(v*2.f*M_PI_F*F + (phi*t)) > 0.f) return color;
	
	return (float4){1.f, 1.f, 1.f, 1.f};
}

__kernel void shader(float time, uint2 size, __global uint* pixels, __global uint* depths){

	/*
		Setup
	*/
	int id = get_global_id(0);
	int x = id%size.x;
	int y = id/size.x;
	
	float u = (float)x / (float)size.x;
	float v = 1.f - ((float)y / (float)size.y);

	float ratio = (float)size.x / (float)size.y;
	float iratio = 1.f/ratio;

	float uc = ((u - 0.5f));
	float vc = ((v - 0.5f) * iratio);
	
	float4 c = {0.f, 0.f, 0.f, 1.f};
	
	float theta = atan2(vc, uc);
	
	/*
		Code :3
	*/
	float4 a = irgba(0xC7, 0x92, 0xEA, 0xFF);
	float4 b = irgba(0x29, 0x2D, 0x3E, 0xFF);
	c = sdf((float2){uc, vc}, a, b, c, time);

	/*
		CRT Line Effect
	*/

	float linedist = 0.05f;

	float4 c_hsva = rgba2hsva(c);
	float n = (v-(0.05f*time)) / linedist;
	float dec = (n - floor(n));
	if(dec < (0.5f)) c_hsva.z *= 0.5f;
	c = hsva2rgba(c_hsva);
	// c *= (float4){0.6f, 1.f, 0.6f, 1.f};
	c = (float4){0.1f, c_hsva.z, 0.1f, 1.f};
	// to anyone interested : here i used c_hsva.z so the hsV V value. It probably is not the best choice in most cases, a Luminosity L or Y value would probably have been a better choice. None the less, here the result suited me.

	/*
		Saving our results
	*/
	put_pixel(&pixels[(y*size.x)+x], c);
}


__kernel void post(float time, uint2 size, __global uint* pixels, __global uint* depths, __global uint* output){

	int id = get_global_id(0);
	int x = id%size.x;
	int y = id/size.x;

	float u = (float)x / (float)size.x;
	float v = 1.f - ((float)y / (float)size.y);

	float ratio = (float)size.x / (float)size.y;
	float iratio = 1.f/ratio;

	float uc = ((u - 0.5f));
	float vc = ((v - 0.5f) * iratio);

	float2 target;
	
	float scale = 0.5f;
	target = uv_scale(u, v, 1.f-length((float2){uc, vc}));

	float4 c = sample(pixels, target.x, target.y, size);

	put_pixel(&output[(y*size.x)+x], c);
}
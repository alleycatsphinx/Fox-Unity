#ifndef COLOR_GRADIENTS
    #define COLOR_GRADIENTS

    float3 hsv(in float h, in float s, in float v)
	{
		return lerp(float3(1.,1.,1.), clamp((abs(frac(h+float3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
	}
 

	float3 turbo(float x) 
	{
	    float r = .1357 + x * (  4.5974 - x * ( 42.3277 - x * ( 130.5887 - x * ( 150.5666 - x * 58.1375 ))));
	    float g = .0914 + x * (  2.1856 + x * (  4.8052 - x * (  14.0195 - x * (   4.2109 + x *  2.7747 ))));
	    float b = .1067 + x * ( 12.5925 - x * ( 60.1097 - x * ( 109.0745 - x * (  88.5066 - x * 26.8183 ))));
	    return float3(r,g,b);
	}


    float3 bump3y (float3 x, float3 yoffset)
    {
        float3 y    = float3(1.,1.,1.) - x * x;
        y           = saturate(y - yoffset);
        return y;
    }


    float3 spectral_zucconi6W(float w)
    {
        // w: [400, 700]
        // x: [0,   1]
    
        float x = clamp((w - 400.0)/ 300.0, 0., 1.);

        float3 c1 = float3(3.54585104, 2.93225262, 2.41593945);
        float3 x1 = float3(0.69549072, 0.49228336, 0.27699880);
        float3 y1 = float3(0.02312639, 0.15225084, 0.52607955);

        float3 c2 = float3(3.90307140, 3.21182957, 3.96587128);
        float3 x2 = float3(0.11748627, 0.86755042, 0.66077860);
        float3 y2 = float3(0.84897130, 0.88445281, 0.73949448);
        
        return bump3y(c1 * (x - x1), y1) + bump3y(c2 * (x - x2), y2);
    }


    float3 spectral_zucconi6(float x)
    {
        const float3 c1 = float3(3.54585104, 2.93225262, 2.41593945);
        const float3 x1 = float3(0.69549072, 0.49228336, 0.27699880);
        const float3 y1 = float3(0.02312639, 0.15225084, 0.52607955);

        const float3 c2 = float3(3.90307140, 3.21182957, 3.96587128);
        const float3 x2 = float3(0.11748627, 0.86755042, 0.66077860);
        const float3 y2 = float3(0.84897130, 0.88445281, 0.73949448);
        
        return bump3y(c1 * (x - x1), y1) + bump3y(c2 * (x - x2), y2);
    }


    float3 rainbow(float x)
    {		
        x = 1.-x;
        return clamp(pow(spectral_zucconi6(x * .75 + .1), 2.2), 0., 1.);
    }

    
    float3 tonemap(float3 color, float gamma)
    {
        float A         = 0.15;
        float B         = 0.50;
        float C         = 0.10;
        float D         = 0.20;
        float G         = 0.02;
        float F         = 0.30;
        float W         = 11.2;
        float exposure  = 2.;
        color           *= exposure;
        color           = ((color * (A * color + C * B) + D * G) / (color * (A * color + B) + D * F)) - G / F;
        float white     = ((W * (A * W + C * B) + D * G) / (W * (A * W + B) + D * F)) - G / F;
        color           /= white;
        color           = pow(color, float3(1.,1.,1.) / gamma); 
        return color;
    }


    float3 grayscale(float3 color)
    {
        float gray = dot(color, float3(0.299, 0.587, 0.114));
        return float3(gray, gray, gray);
    }
#endif


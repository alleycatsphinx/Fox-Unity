#ifndef SKILLING
	#define SKILLING

	//The skilling transform converts the Z-Order (aka Morton Order) curve into a Hilbert Curve 
	//it does so rotating the spatial subdivision volumes using a series of bit flips such that 
	//the hamming distance between any successive points is always 1 (as in greycode vs binary.)
	//
    //      "Z Order Curve"                        "Hilbert Curve"
    //    ┌10────11┐ ┌14───15─                 ┌5──────6┐  ┌9──────10┐
    //    └─┐      │ └─┐                       │        │  │         │
    //      └─┐    │   └─┐                     │        │  │         │
    //        └─┐  │     └─┐           \\      │        │  │         │
    //          └─┐│       └─┐          \\     │        │  │         │
    //    ┌8─────9┘└──12───13┘    =======\\    4        7  8        11
    //    └──────────────────┐    =======//    |        └──┘         │
    //    ┌2─────3─┐ ┌6─────7┘          //     └3──────2┐  ┌13─────12┘
    //    └─┐      │ └─┐               //               │  │  
    //      └─┐    │   └─┐                              │  │
    //        └─┐  │     └─┐                            │  │ 
    //          └─┐│       └─┐                          │  │
    //    ─0─────1┘└──4─────5┘                 ─0──────1┘  └14─────15─
	//
	//Observe that, unlike base z order,  rotations in the hilbert transform require the octave
	//to be specified when encoding and decoding.

    //2D
    //transforms a z order curve into a hilbert curve
    //https://github.com/Wunkolo/qHilbert 
 	uint skilling(uint octave, uint v)
    {
		v = v | (0x55555555<<(octave*2)); 	// Pad s on left with 01
		uint sr = (v >> 1) & 0x55555555;  	// (no change) groups.
		uint cs = ((v & 0x55555555) + sr) 	// Compute complement &
		    ^ 0x55555555;           		// swap info in two-bit
		                            		// groups.

		// Parallel prefix xor op to propagate both complement
		// and swap info together from left to right (there is
		// no step "cs ^= cs >> 1", so in effect it computes
		// two independent parallel prefix operations on two
		// interleaved sets of sixteen bits).		    
		cs = cs ^ (cs >> 2);
		cs = cs ^ (cs >> 4);
		cs = cs ^ (cs >> 8);
		cs = cs ^ (cs >> 16);

		uint swap = cs & 0x55555555;      		// Separate the swap and
		uint comp = (cs >> 1) & 0x55555555;  	// complement bits.

		uint t = (v & swap) ^ comp;       		// Calculate x and y in
		v = v ^ sr ^ t ^ (t << 1);   			// the odd & even bit
		                            			// positions, resp.
		v = v & ((1 << (2*octave)) - 1);    			// Clear out any junk
		                            			// on the left (unpad).
		return v;
	}


    //3D
    //transforms a z order curve into a hilbert curve (input should be in grey code)
    //it operates per component, but it might be nice to have a version that works on 1D directly
    uint3 skilling(in uint octave, in uint3 p)
    {                
        int mask = 0;
        for(int i = 2; i < (1 << octave); i <<= 1)
        {
            mask = i - 1;
            p.xz ^= (p.x & i) != 0 ? int2(   0, mask) : (p.x ^ p.z) & mask;
            p.yz ^= (p.y & i) != 0 ? int2(   0, mask) : (p.y ^ p.z) & mask;
            p.z  ^= (p.z & i) != 0 ?            mask  :                  0;
        }

        return p;
    }

    //Note on 4D skilling - it is unnecessary in 4D; the gray code input is already a proper hilbert curve ("snake on a box")

    //6D Someone please write an efficient 6D skilling for me kkthx <3

    uint gray_to_binary(uint x)
    {
        x ^= (x >> 0x00000010);
        x ^= (x >> 0x00000008);
        x ^= (x >> 0x00000004);
        x ^= (x >> 0x00000002);
        x ^= (x >> 0x00000001);
        return(x);
    } 

	uint rol(uint x, uint bits, uint n)
	{
	    //if(bits < n) return 0;
	    return ((x << bits) & ((0x00000001 << n) - 1)) | (x >> (n - bits));
	}
	
	
	uint ror(uint x, uint bits, uint n)
	{
	    //if(bits < n) return 0;
	    return ((x << (n - bits)) & ((0x00000001 << n) - 1)) | (x >> bits);
	}
	
	
	uint ctz(uint x)
	{
	    // if(x == 0x00000000) 
	    // { 
	    // 	return 0; 
	    // }
	
	    for(uint i = 0; i < 32; i++)
	    {
	        if((x & (0x00000001 << i)) != 0) 
	        {
	        	return i; //or I+1???
	        }
	    }
	
	    return 0;
	}
	 
	uint hilbertToMortonN(uint index, uint dim, uint bits)
	{
		dim 		= max(dim, 0);

	    uint c = 0;
	    uint n = 0;
	
	    uint mask = (1U << dim) - 1;
	    uint hibit = 1U << (dim - 1);
		
	    uint morton = 0;
	
	    for (uint i = 0; i < bits; ++i)
	    {
	        uint I = mask & (index >> (dim * (bits - i - 1)));
	
	        uint gray = I ^ (I >> 1);
	
	        uint M = rol(gray, n, dim) ^ c;
	
	        morton = (morton << dim) | M;
	
	        uint N = 2 + ctz(gray & ~hibit);
	
	        uint C = I == 0 ? 0 : gray ^ (I & -int(I) | 1);
	
	        c = rol(C, n, dim) ^ c;
	
	        n = (n + N) % dim;
	    }
	
	    return morton;
	}	
	
	uint mortonToHilbertN(uint morton, uint dim, uint bits)
	{
		dim 		= max(dim, 0);

	    uint c = 0;
	    uint n = 0;
		uint x = 0;
		
	    uint mask 	= (1U << dim) - 1;
	    uint hibit 	= 1U << (dim - 1);
		uint gray 	= 0;
	    uint index 	= 0;
		
	    for (uint i = 0; i < bits; ++i)
	    {
	        uint M = mask & (morton >> (dim * (bits - i - 1)));
	        gray 	= ror(c ^ M, n, dim);
		
	        uint I = gray_to_binary(gray);
	
	        index = (index << dim) | I;
			x = ctz(gray & ~hibit);
	        uint N = 2 + x;
	        uint C = I == 0 ? 0 : gray ^ (I & -int(I) | 1);
	
	        c = rol(C, n, dim) ^ c;
	        n = (n + N) % dim;
	    }
	
	    return index;
	}
#endif

#ifndef BITWISE
    #define BITWISE
    //note : some of these have builtin intrinsic functions which must be emulated on some systems
     
    void set_32(in bool n, in uint i, inout uint x)
    {
        x = n ? x | i : x & ~i;
    }


    bool get_32(in uint x, in uint y)
    {
        return (x & y) != 0;
    }


    bool read_32(uint x, uint i)
    {
        return x & 0x00000001 << i;
    }


	void copy_32(in uint mask, in uint src, in uint dst)
	{
		set_32(get_32(mask, src), mask, dst);
	}


	void map_32(in uint src_mask, in uint dst_mask, in uint src, inout uint dst)
	{
		set_32(get_32(src_mask, src), dst_mask, dst);
	}


    bool read_64(uint2 x, uint i)
    {
        uint j = i & 0x0000001F;
        return i < 0x00000020 ? read_32(x.x, j)
             :                  read_32(x.y, j);
    }


    bool read_128(uint4 x, uint i)
    {
        uint j = i & 0x0000001F;
        return i < 0x00000020 ? read_32(x.x, j)
             : i < 0x00000040 ? read_32(x.y, j)
             : i < 0x00000060 ? read_32(x.z, j)
             :                  read_32(x.w, j);
    }


    uint write_32(uint x, uint i)
    {
        return x | 0x00000001 << i;
    }


    uint2 write_64(uint2 x, uint i)
    {
        uint j = i & 0x0000001F;
        return i < 0x00000020 ? uint2(write_32(x.x, j), x.y)
             :                  uint2(x.x, write_32(x.y, j));
    }


    uint4 write_128(uint4 x, uint i)
    {
        uint j = i & 0x000000Ff;
        return i < 0x00000020 ? uint4(write_32(x.x, j), x.y, x.z, x.w)
             : i < 0x00000040 ? uint4(x.x, write_32(x.y, j), x.z, x.w)
             : i < 0x00000060 ? uint4(x.x, x.y, write_32(x.z, j), x.w)
             :                  uint4(x.x, x.y, x.z, write_32(x.w, j));
    }


    uint clear_32(uint x, int i)
    {
        return (~0x0000001 << i) & x;
    }


    uint2 clear_64(uint2 x, uint i)
    {
        uint j = i & 0x0000001F;
        return i < 0x00000020 ? uint2(clear_32(x.x, j), x.y)
             :                  uint2(x.x, clear_32(x.y, j));
    }

    uint4 clear_128(uint4 x, uint i)
    {
        uint j = i & 0x0000001F;
        return i < 0x00000020 ? uint4(clear_32(x.x, j), x.y, x.z, x.w)
             : i < 0x00000040 ? uint4(x.x, clear_32(x.y, j), x.z, x.w)
             : i < 0x00000060 ? uint4(x.x, x.y, clear_32(x.z, j), x.w)
             :                  uint4(x.x, x.y, x.z, clear_32(x.w, j));
    }


    uint flip_32(uint x, int i)
    {
        return (0x00000001 << i) ^ x;
    }


    uint2 flip_64(uint2 x, uint i)
    {
        uint j = i & 0x0000001F;
        return i < 0x00000020 ? uint2(flip_32(x.x, j), x.y)
             :                  uint2(x.x, flip_32(x.y, j));
    }


    uint4 flip_128(uint4 x, uint i)
    {
        uint j = i & 0x0000001F;
        return i < 0x00000020 ? uint4(flip_32(x.x, j), x.y, x.z, x.w)
             : i < 0x00000040 ? uint4(x.x, flip_32(x.y, j), x.z, x.w)
             : i < 0x00000060 ? uint4(x.x, x.y, flip_32(x.z, j), x.w)
             :                  uint4(x.x, x.y, x.z, flip_32(x.w, j));
    }


    uint count_32(uint x)
    {
        //needs testing
        //b ░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█ //u 1431655765  //h 0x55555555
        //b ░░██░░██░░██░░██░░██░░██░░██░░██ //u  858993459  //h 0x33333333
        //b ░░░░████░░░░████░░░░████░░░░████ //u  252645135  //h 0x0F0F0F0F

        // x -= (x >> 0x00000001)      & 0x55555555;
        // x = ((x >> 0x00000002)      & 0x33333333) + (x & 0x33333333);
        // x = ((x >> 0x00000004) + x) & 0x0F0F0F0F;
        // x +=  x >> 0x00000008;
        // x +=  x >> 0x00000010;
        // return x & 0x0000001F;

        return countbits(x);
    }


    uint count_64(uint2 x)
    {
        return count_32(x.x) + count_32(x.y);
	}


	uint count_96(uint3 x)
	{
		return count_32(x.x) + count_32(x.y) + count_32(x.z);
	}


    uint count_128(uint4 x)
    {
        return count_32(x.x) + count_32(x.y) + count_32(x.z) + count_32(x.w);
    }


    uint pack_bytes(uint x, uint y, uint z, uint w)
    {
        return (x & 0x000000FF) << 0x00000018
             | (y & 0x000000FF) << 0x00000010
             | (z & 0x000000FF) << 0x00000008
             | (w & 0x000000FF);
    }


    uint4 unpack_bytes(uint x)
    {
        return uint4(x >> 0x00000018,
                     x >> 0x00000010,
                     x >> 0x00000008,
                     x) & 0x000000FF;
    }


    uint swap_bits(uint x, uint a, uint b, uint n)
    {
        return ((x >> a) ^ (x >> b)) & ((0x00000001 << n) - 0x00000001) ^ ((x << a) | (x << b));
    }


    void split(in uint x, in uint i, out uint a, out uint b)
    {
        a   = 0xFFFFFFFF >> 0x0000001F - i & x;
        b   = a ^ x;
    }


    uint swizzle(in uint x, in uint i)
    {
        uint a = 0xFFFFFFFF >> 0x0000001F - i & x;
        return (((a & 0xAAAAAAAA) >> 0x00000001)) | (((a & 0x55555555) << 0x00000001)) | (a ^ x);
    }


    //needs testing
    uint reflect_bits(in uint x, in uint y, in uint z)
    {
        return (0x00000001 << (z % (y*0x00000002) < y ? ((y-0x00000001) - z % y) : (z % y)));
    }


    uint rotate_right(in uint x, in uint i)
    {
        return (x >> i) | (x << (32-i));
    }


    uint rotate_left(in uint x, in uint i)
    {
        return (x << i) | (x >> (32-i));
    }


    uint npot(in uint x)
    {
        x--;
        x |= x >> 1;
        x |= x >> 2;
        x |= x >> 4;
        x |= x >> 8;
        x |= x >> 16;
        return x+1;
    }
#endif


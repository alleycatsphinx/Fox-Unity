using System.Linq;

namespace secantastronomy
{
    public static class Int32Extensions
    {
        public static bool[] ToBooleanArray(this uint i)
        {
            return System.Convert.ToString(i, 0x02).Select(s => s.Equals('1')).ToArray();
        }
    }
    
    public static class Bitwise
    {
        //combines both inputs
        public static uint Union(uint x, uint y)
        {
            return x | y;
        }


        //returns bits that exist in both inputs
        public static uint Mask(uint x, uint y)
        {
            return x & y;
        }


        //flip the bit if x contains y
        public static uint Toggle(uint x, uint y)
        {
            return x ^ y;       
        }
        
        
        //set the bit at the index to one
        public static uint Set(uint x, int index)
        {
            return (((uint)1 << index)) | x;
        }


        //set the bit at the index to zero
        public static uint Clear(uint x, int index)
        {
            return (~(((uint)1 << index)) & x);
        }


        //toggle the bit at the index
        public static uint Toggle(uint x, int index)
        {
            return ((uint)1 << index) ^ x;
        }


        //return true if x contains y
        public static bool Read(uint x, int index)
        {
            return (((uint)1 << index) & x) != 0;
        }

        public static bool Test(uint x, uint y)
        {
            return Bitwise.Mask(x, y) != 0;
        }

                    
        public static uint Count(uint x)
        {
            x       = x - ((x >> 1) & 0x55555555);
            x       = (x & 0x33333333) + ((x >> 2) & 0x33333333);
            x       = x + (x >> 4);
            x       &= 0xF0F0F0F;
            return (x * 0x01010101) >> 24;
        }


        public static uint Binary_To_Gray(uint x)
        {
            return (x >> 1) ^ x;
        }

        public static ulong Binary_To_Gray(ulong x)
        {
            return (x >> 1) ^ x;
        }


        public static uint Gray_To_Binary(uint x)
        {
            x ^= (x >> 16);
            x ^= (x >> 8);                            
            x ^= (x >> 4);
            x ^= (x >> 2);
            x ^= (x >> 1);
            return(x);
        }
              

        public static uint MaskHighBit(uint x)
        {
            x &= (x & 0xFFFF0000) != 0x00000000 ? 0xFFFF0000 : 0x0000FFFF; 
            x &= (x & 0xFF00FF00) != 0x00000000 ? 0xFF00FF00 : 0x00FF00FF;
            x &= (x & 0xF0F0F0F0) != 0x00000000 ? 0xF0F0F0F0 : 0x0F0F0F0F;
            x &= (x & 0xCCCCCCCC) != 0x00000000 ? 0xCCCCCCCC : 0x33333333;
            x &= (x & 0xAAAAAAAA) != 0x00000000 ? 0xAAAAAAAA : 0x55555555;        
            return x;
        }


        public static uint MaskLowBit(uint x)
        {
            x &= (x & 0x0000FFFF) != 0x00000000 ? 0x0000FFFF : 0xFFFF0000; 
            x &= (x & 0x00FF00FF) != 0x00000000 ? 0x00FF00FF : 0xFF00FF00;
            x &= (x & 0x0F0F0F0F) != 0x00000000 ? 0x0F0F0F0F : 0xF0F0F0F0;
            x &= (x & 0x33333333) != 0x00000000 ? 0x33333333 : 0xCCCCCCCC;
            x &= (x & 0x55555555) != 0x00000000 ? 0x55555555 : 0xAAAAAAAA;        
            return x;
        }


        public static uint FindSingleBit(uint x)
        {
            uint b = 0;
            b += (x & 0xFFFF0000) != 0x00000000? 16u : 0u;
            b += (x & 0xFF00FF00) != 0x00000000?  8u : 0u;
            b += (x & 0xF0F0F0F0) != 0x00000000?  4u : 0u;
            b += (x & 0xCCCCCCCC) != 0x00000000?  2u : 0u;
            b += (x & 0xAAAAAAAA) != 0x00000000?  1u : 0u;
            return b;
        }
 

        public static uint FirstHighBit(uint x)
        {
            return FindSingleBit(MaskHighBit(x));
        }


        public static uint FirstLowBit(uint x)
        {
            return FindSingleBit(MaskLowBit(x));
        }


        public static uint CountLowerBits(uint x, uint i)
        {            
            int c = 0;        
            for(uint h = (uint)(1 << (int)i); h > 0; h >>= 1)
            {
                c += (h & x) != 0x00000000 ? 0x00000001 : 0x00000000;
                if(h == 0x0000000) break;
            }
            return (uint)c; 
        }


        public static uint Skilling(uint x)
        {   
            for(int i = 2; i < 32; i++)
            {       
                uint y = 0xFFFFFFFF >> 31 - i;
                if((x >> i & 1) == 1)
                {                                   
                    x = x >> i << i | y & ~(x ^ 0x55555555);                    
                }
                else if((~i % 2) == 0)
                {               
                    y &= x;                     
                    x = (y & 0xAAAAAAAA) >> 1 | (y & 0x55555555) << 1 | y ^ x;          
                }                       
            }
            //x = ((x >> 1) & 0x55555555) | ((x & 0x55555555) << 1);
            return x;
        }

        // █ ░ ■ □ ▀ ▄ ▲ ▼ ► ◄ ▪ ▫ ● ○ ▬ ┬─┴
        public static string String(uint u)
        {                    
            string binary   = "";
            for(int i = 31; i >= 0; i--)
            {
                // binary += Read(u, i) ? "█" : "░";
                binary += Read(u, i) ? "■" : "□";
                // binary += Read(u, i) ? "1" : "0";
            }
            return binary;
        }

        public static string String(uint u, int limit)
        {            
            string binary   = "";   
            limit = limit > 1 ? limit - 1 : 1;
            for(int i = limit; i >= 0; i--)
            {
                binary += Read(u, i) ? "1," : "0,";
                // binary += Read(u, i) ? "█" : "░";
                // binary += Read(u, i) ? "■" : "□";
                // binary += Read(u, i) ? "1" : "0";
            }
            return binary;
        }

        public static string BitString(uint u, int limit)
        {            
            string binary   = "";   
            limit = limit > 1 ? limit - 1 : 1;
            for(int i = limit; i >= 0; i--)
            {
                // binary += Read(u, i) ? "1," : "0,";
                // binary += Read(u, i) ? "█" : "░";
                binary += Read(u,i) ? "█" : "—";
                // binary += Read(u, i) ? "■" : "□";
                // binary += Read(u, i) ? "1" : "0";
            }
            return binary;
        }

        public static string String(ulong u)
        {            
            string binary   = "";
            for(int i = 63; i >= 0; i--)
            {
                // binary += (((ulong)1 << i) & u) != 0 ? "█" : "░";
                binary += (((ulong)1 << i) & u) != 0 ? "█" : "—";
                // binary += (((ulong)1 << i) & u) != 0 ? "1" : "0";
            }
            return binary;
        }


        public static string InterlacedString(uint u, int d)
        {            
            string binary  = "";              
            for(int i = 31; i >= 0; i--)
            // for(int i = 0; i < 32; i++)
            {
                // binary += Read(u, i) ? "█" : "░";

                binary += Read(u, i) ? "■" : "□";
                
                // binary += Read(u, i) ? "1" : "0";
            }
            return binary;
        }

        public static string HexString(in uint x)
        {
            return "0x" + x.ToString("X").PadLeft(8, 0.ToString().ToCharArray()[0]);
        }

        public static string BinaryHexDecimalString(in uint x)
        {
            //example output for x == 1 
            //b -——————————————————————————————█  //h 0x00000001  //d          1            
            return "//b " + BitString(x, 32) + " //h " + HexString(x) + " //d " + x.ToString().PadLeft(10);            
        }
    }
}


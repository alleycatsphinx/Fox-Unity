using System;
using System.Runtime.InteropServices;
using Unity.Mathematics;
using UnityEngine;
using static GaussianSplatting.Runtime.GaussianSplatAsset;
using GaussianSplatting.Runtime;

public static class GaussianPositionParser
{
    // Must match the asset's layout exactly.
    [StructLayout(LayoutKind.Sequential)]
    private struct ChunkInfoLayout
    {
        public uint colR, colG, colB, colA; // not used here
        public float2 posX, posY, posZ;     // (min,max) for each axis
        public uint sclX, sclY, sclZ;       // not used here
        public uint shR, shG, shB;          // not used here
    }

    const int CHUNK = GaussianSplatAsset.kChunkSize;

    public static Vector3 GetPosition(in GaussianSplatAsset asset, int i)
    {
        if ((uint)i >= (uint)asset.splatCount) throw new ArgumentOutOfRangeException(nameof(i));

        // 1) read the packed (u_x,u_y,u_z) in [0,1] depending on posFormat
        var u = ReadUnitVector(asset, i);

        // 2) choose ranges: per-chunk if available, otherwise global bounds
        float2 rx, ry, rz;
        if (asset.chunkData != null && asset.chunkData.bytes != null && asset.chunkData.bytes.Length != 0)
        {
            var ci = ReadChunk(asset, i / CHUNK);
            rx = ci.posX; ry = ci.posY; rz = ci.posZ; // (min,max) per axis
        }
        else
        {
            rx = new float2(asset.boundsMin.x, asset.boundsMax.x);
            ry = new float2(asset.boundsMin.y, asset.boundsMax.y);
            rz = new float2(asset.boundsMin.z, asset.boundsMax.z);
        }

        return new Vector3(u.x, u.y, u.z);

        // // 3) de-quantize from [0,1] to world coordinates
        // return new Vector3(math.lerp(rx.x, rx.y, u.x),
        //                    math.lerp(ry.x, ry.y, u.y),
        //                    math.lerp(rz.x, rz.y, u.z));
    }

    private static float3 ReadUnitVector(in GaussianSplatAsset asset, int i)
    {
        var bytes = asset.posData.bytes;
        switch (asset.posFormat)
        {
            case GaussianSplatAsset.VectorFormat.Float32:
            {
                int o = i * 12;
                float x = BitConverter.ToSingle(bytes, o + 0);
                float y = BitConverter.ToSingle(bytes, o + 4);
                float z = BitConverter.ToSingle(bytes, o + 8);

                return new float3(x, y, z);

                // // Float32 positions are already in world space; remap to [0,1] using bounds
                // // so the same de-quantization path works. If you prefer, you can just return (x,y,z).
                // var rx = new float2(asset.boundsMin.x, asset.boundsMax.x);
                // var ry = new float2(asset.boundsMin.y, asset.boundsMax.y);
                // var rz = new float2(asset.boundsMin.z, asset.boundsMax.z);
                // float ux = (x - rx.x) / math.max(1e-20f, (rx.y - rx.x));
                // float uy = (y - ry.x) / math.max(1e-20f, (ry.y - ry.x));
                // float uz = (z - rz.x) / math.max(1e-20f, (rz.y - rz.x));
                
                // return new float3(ux, uy, uz);
            }

            case GaussianSplatAsset.VectorFormat.Norm16:
            {
                int o = i * 6;
                uint ix = BitConverter.ToUInt16(bytes, o + 0);
                uint iy = BitConverter.ToUInt16(bytes, o + 2);
                uint iz = BitConverter.ToUInt16(bytes, o + 4);
                const float dx = 1f / 65535f, dy = 1f / 65535f, dz = 1f / 65535f;
                return new float3(ix * dx, iy * dy, iz * dz);
            }

            case GaussianSplatAsset.VectorFormat.Norm11:
            {
                // Packed as 11|10|11 bits -> x,y,z (assumed layout: x in least-significant 11, y next 10, z top 11)
                int o = i * 4;
                uint packed = BitConverter.ToUInt32(bytes, o);
                uint ix =  packed        & 0x7FFu;        // 11 bits
                uint iy = (packed >> 11) & 0x3FFu;        // 10 bits
                uint iz = (packed >> 21) & 0x7FFu;        // 11 bits
                const float dx = 1f / 2047f;              // 2^11 - 1
                const float dy = 1f / 1023f;              // 2^10 - 1
                const float dz = 1f / 2047f;
                return new float3(ix * dx, iy * dy, iz * dz);
            }

            case GaussianSplatAsset.VectorFormat.Norm6:
            {
                // Packed as 6|5|5 bits -> x,y,z (assumed layout: x LSB 6, then y 5, z top 5)
                int o = i * 2;
                uint packed = BitConverter.ToUInt16(bytes, o);
                uint ix =  packed        & 0x3Fu;         // 6 bits
                uint iy = (packed >> 6)  & 0x1Fu;         // 5 bits
                uint iz = (packed >> 11) & 0x1Fu;         // 5 bits
                const float dx = 1f / 63f;
                const float dy = 1f / 31f;
                const float dz = 1f / 31f;
                return new float3(ix * dx, iy * dy, iz * dz);
            }

            default:
                throw new ArgumentOutOfRangeException(nameof(asset.posFormat), asset.posFormat, null);
        }
    }

    private static ChunkInfoLayout ReadChunk(in GaussianSplatAsset asset, int chunkIndex)
    {
        var cbytes = asset.chunkData.bytes;
        int stride = Marshal.SizeOf<ChunkInfoLayout>();
        int offset = chunkIndex * stride;
        if (offset + stride > cbytes.Length) throw new IndexOutOfRangeException("chunkData truncated");

        ChunkInfoLayout ci;
        // Marshal copy is fine here; you can also do unsafe fixed/UnsafeUtility.MemCpy.
        var handle = GCHandle.Alloc(cbytes, GCHandleType.Pinned);
        try
        {
            IntPtr ptr = handle.AddrOfPinnedObject() + offset;
            ci = Marshal.PtrToStructure<ChunkInfoLayout>(ptr);
        }
        finally { handle.Free(); }
        return ci;
    }
}
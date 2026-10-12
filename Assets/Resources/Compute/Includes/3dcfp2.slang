 import std;

// ============================================================
// 3D resonant convolution field
// Clean rewrite:
// - free camera
// - hover + picked voxel
// - pulse emission
// - DDA picking + DDA rendering
// - explicit persistent initialization
// Camera fixes applied:
// - corrected camera basis
// - corrected yaw sign
// - lower look sensitivity
// - center-screen aim when unlocked
// - no camera jump on lock toggle
// ============================================================

// ------------------------------------------------------------
// Simulation constants
// ------------------------------------------------------------
static const int ZS = 128;
static const int ZT = 3;
static const int ZF = 1;
static const int R  = 4;

static const int VOXELS     = ZS * ZS * ZS;
static const int FRAME_SIZE = VOXELS;
static const int TOTAL_SIZE = VOXELS * ZT;

// ------------------------------------------------------------
// Workgroup layout
// ------------------------------------------------------------
static const int WGX = 4;
static const int WGY = 4;
static const int WGZ = 4;

static const int GCX = ZS / WGX;
static const int GCY = ZS / WGY;
static const int GCZ = ZS / WGZ;

// ------------------------------------------------------------
// Camera / render constants
// ------------------------------------------------------------
static const float CAM_FOVY          = 1.04719755; // 60 deg
static const int   MAX_DDA_STEPS     = ZS * 4;

static const float LOOK_SENS_X       = 0.0050;
static const float LOOK_SENS_Y       = 0.0040;
static const float CAM_SPEED         = 45.0;
static const float DT_FALLBACK       = 1.0 / 60.0;
static const float DT_MAX_CLAMP      = 0.25;

static const float EDGE_WIDTH        = 0.10;
static const float EDGE_STRENGTH     = 1.35;
static const float DENSITY_STRENGTH  = 1.00;
static const float OCC_THRESH        = 0.035;
static const float GAMMA             = 0.8;

// ------------------------------------------------------------
// Picking / pulse constants
// ------------------------------------------------------------
static const float PICK_THRESHOLD    = 0.12;
static const float PICK_EMIT_SIGMA2  = 9.0;
static const float PICK_EMIT_GAIN    = 0.45;
static const int   PULSE_FRAMES      = 10;

// ------------------------------------------------------------
// Key codes
// ------------------------------------------------------------
static const uint KEY_SPACE = 32u;
static const uint KEY_A     = 65u;
static const uint KEY_D     = 68u;
static const uint KEY_E     = 69u;
static const uint KEY_Q     = 81u;
static const uint KEY_S     = 83u;
static const uint KEY_W     = 87u;

// ------------------------------------------------------------
// Persistent storage
// ------------------------------------------------------------

// simulation field ring buffer
[StorageBuffer(TOTAL_SIZE)]
RWStructuredBuffer<float> D;

// camera state
// CamA[0] = float4(pos.xyz, yaw)
// CamB[0] = float4(pitch, unlockedFlag, reserved, reserved)
[StorageBuffer(1)]
RWStructuredBuffer<float4> CamA;
[StorageBuffer(1)]
RWStructuredBuffer<float4> CamB;

// general persistent flags
// StateFlags[0].x = global initialized
// StateFlags[0].y = sim seeded
[StorageBuffer(1)]
RWStructuredBuffer<int4> StateFlags;

// input state
// InputState[0].x = previous space down
// InputState[0].y = previous mouse down
[StorageBuffer(1)]
RWStructuredBuffer<int4> InputState;

// previous mouse position
[StorageBuffer(1)]
RWStructuredBuffer<float4> MouseState;

// previous elapsed + frame dt estimate
// TimeState[0].x = previous elapsed
// TimeState[0].y = frame dt estimate
[StorageBuffer(1)]
RWStructuredBuffer<float4> TimeState;

// hover voxel
// Hover[0].xyz = voxel coord
// Hover[0].w   = valid
[StorageBuffer(1)]
RWStructuredBuffer<int4> Hover;

// picked voxel
// Pick[0].xyz = voxel coord
// Pick[0].w   = valid
[StorageBuffer(1)]
RWStructuredBuffer<int4> Pick;

// pulse countdown
// Pulse[0].x = frames remaining
[StorageBuffer(1)]
RWStructuredBuffer<int4> Pulse;

// ------------------------------------------------------------
// Kernel constants
// ------------------------------------------------------------
static const float kernelA = 1.0;
static const float kernelB = 0.25;

// ============================================================
// Utility
// ============================================================

uint hash32(uint x)
{
    x ^= x >> 17;
    x *= 0xed5ad4bbu;
    x ^= x >> 11;
    x *= 0xac4c1b51u;
    x ^= x >> 15;
    x *= 0x31848babu;
    x ^= x >> 14;
    return x;
}

float rnd(uint a)
{
    uint h = hash32(a);
    uint m = (1u << 23u) - 1u;
    return float(h & m) / float(m);
}

int wrap1(int x, int n)
{
    int r = x % n;
    return (r < 0) ? (r + n) : r;
}

int flatten3(int3 p)
{
    return p.x + p.y * ZS + p.z * ZS * ZS;
}

int ringBase(int t)
{
    int tt = t % ZT;
    if (tt < 0) tt += ZT;
    return tt * FRAME_SIZE;
}

float kernelFromL2(int l2)
{
    return cos(sqrt((float)l2) * kernelA) * exp(-(float)l2 * kernelB);
}

float fastAmp(float d)
{
    return min(pow(abs(d), 0.2), 1.0);
}

float saturate1(float x)
{
    return clamp(x, 0.0, 1.0);
}

float3 toneMap(float3 x)
{
    return x / (1.0 + x);
}

bool voxelInBounds(int3 ip)
{
    return
        ip.x >= 0 && ip.x < ZS &&
        ip.y >= 0 && ip.y < ZS &&
        ip.z >= 0 && ip.z < ZS;
}

float manifoldAtVoxel(int3 ip, int frA, int frB)
{
    ip = clamp(ip, int3(0, 0, 0), int3(ZS - 1, ZS - 1, ZS - 1));
    int idx = flatten3(ip);
    float a = D[frA + idx];
    float b = D[frB + idx];
    return sqrt(a * a + b * b);
}

float voxelEdgeMask(float3 p, float width)
{
    float3 f = frac(p);
    float3 d = min(f, 1.0 - f);

    float3 nearFace = 1.0.xxx - clamp(d / width, 0.0.xxx, 1.0.xxx);
    float eXY = nearFace.x * nearFace.y;
    float eYZ = nearFace.y * nearFace.z;
    float eZX = nearFace.z * nearFace.x;

    return max(max(eXY, eYZ), eZX);
}

// ============================================================
// Persistent initialization
// ============================================================

void loadCamera(out float3 pos, out float yaw, out float pitch, out bool unlocked)
{
    float4 a = CamA[0];
    float4 b = CamB[0];

    pos      = a.xyz;
    yaw      = a.w;
    pitch    = b.x;
    unlocked = (b.y > 0.5);
}

void storeCamera(float3 pos, float yaw, float pitch, bool unlocked)
{
    CamA[0] = float4(pos, yaw);
    CamB[0] = float4(pitch, unlocked ? 1.0 : 0.0, 0.0, 0.0);
}

bool ensureInitialized()
{
    if (StateFlags[0].x != 0)
        return false;

    float2 mousePos = float2(mouse.pos);

    float3 pos = float3(0.5 * ZS, 0.5 * ZS, -0.9 * ZS);
    float yaw = 1.5707963;
    float pitch = 0.0;
    bool unlocked = false;

    storeCamera(pos, yaw, pitch, unlocked);

    InputState[0] = int4(0, 0, 0, 0);
    MouseState[0] = float4(mousePos, 0.0, 0.0);
    TimeState[0]  = float4(time.elapsed, DT_FALLBACK, 0.0, 0.0);

    Hover[0] = int4(-1, -1, -1, 0);
    Pick[0]  = int4(-1, -1, -1, 0);
    Pulse[0] = int4(0, 0, 0, 0);

    StateFlags[0] = int4(1, 0, 0, 0);
    return true;
}

// ============================================================
// Camera
// ============================================================

void getCameraBasis(float yaw, float pitch, out float3 fwd, out float3 right, out float3 up)
{
    float cy = cos(yaw);
    float sy = sin(yaw);
    float cp = cos(pitch);
    float sp = sin(pitch);

    fwd = normalize(float3(cp * cy, sp, cp * sy));

    float3 upRef = float3(0.0, 1.0, 0.0);
    if (abs(dot(fwd, upRef)) > 0.98)
        upRef = float3(0.0, 0.0, 1.0);

    right = normalize(cross(upRef, fwd));
    up    = normalize(cross(fwd, right));
}

float2 clampYawPitch(float yaw, float pitch)
{
    return float2(yaw, clamp(pitch, -1.55, 1.55));
}

float3 rayDirFromScreen(float2 fragXY, float2 res, float yaw, float pitch)
{
    float2 uv = (fragXY + 0.5) / res * 2.0 - 1.0;
    uv.x *= res.x / res.y;

    float3 fwd, right, up;
    getCameraBasis(yaw, pitch, fwd, right, up);

    float tanHalf = tan(0.5 * CAM_FOVY);
    return normalize(fwd + right * (uv.x * tanHalf) + up * (uv.y * tanHalf));
}

void makeFreeCamera(float2 fragXY, float2 res, out float3 ro, out float3 rd)
{
    float3 pos;
    float yaw, pitch;
    bool unlocked;
    loadCamera(pos, yaw, pitch, unlocked);

    ro = pos;
    rd = rayDirFromScreen(fragXY, res, yaw, pitch);
}

float2 getAimScreenPos()
{
    uint W, H;
    screen.GetDimensions(W, H);

    float3 pos;
    float yaw, pitch;
    bool unlocked;
    loadCamera(pos, yaw, pitch, unlocked);

    if (unlocked)
        return 0.5 * float2(W, H);

    return float2(mouse.pos);
}

[DispatchOnce]
[WorkgroupCount(1,1,1)]
[shader("compute")]
[numthreads(1,1,1)]
void camera_update(uint3 tid : SV_DispatchThreadID)
{
    if (ensureInitialized())
        return;

    float2 currMousePos = float2(mouse.pos);
    float2 prevMousePos = MouseState[0].xy;

    float prevElapsed = TimeState[0].x;
    float dtFrame = time.elapsed - prevElapsed;
    if (dtFrame <= 0.0 || dtFrame > DT_MAX_CLAMP)
        dtFrame = DT_FALLBACK;

    float3 pos;
    float yaw, pitch;
    bool unlocked;
    loadCamera(pos, yaw, pitch, unlocked);

    int prevSpaceDown = InputState[0].x;
    int currSpaceDown = keyDown(KEY_SPACE) ? 1 : 0;
    bool spacePressed = (currSpaceDown != 0) && (prevSpaceDown == 0);

    if (spacePressed)
    {
        unlocked = !unlocked;
        prevMousePos = currMousePos;
    }

    if (unlocked)
    {
        float2 mouseStep = currMousePos - prevMousePos;
        yaw   -= LOOK_SENS_X * mouseStep.x;
        pitch -= LOOK_SENS_Y * mouseStep.y;

        float2 yp = clampYawPitch(yaw, pitch);
        yaw   = yp.x;
        pitch = yp.y;

        float3 fwd, right, up;
        getCameraBasis(yaw, pitch, fwd, right, up);

        float camStep = CAM_SPEED * dtFrame;
        if (keyDown(KEY_W)) pos += fwd   * camStep;
        if (keyDown(KEY_S)) pos -= fwd   * camStep;
        if (keyDown(KEY_A)) pos -= right * camStep;
        if (keyDown(KEY_D)) pos += right * camStep;
        if (keyDown(KEY_Q)) pos -= up    * camStep;
        if (keyDown(KEY_E)) pos += up    * camStep;
    }

    storeCamera(pos, yaw, pitch, unlocked);
    MouseState[0] = float4(currMousePos, 0.0, 0.0);
    InputState[0] = int4(currSpaceDown, InputState[0].y, 0, 0);
    TimeState[0]  = float4(time.elapsed, dtFrame, 0.0, 0.0);
}

// ============================================================
// Ray box and DDA
// ============================================================

bool rayBox(float3 ro, float3 rd, out float t0, out float t1)
{
    float3 bmin = float3(0.0, 0.0, 0.0);
    float3 bmax = float3(float(ZS), float(ZS), float(ZS));

    float3 inv  = 1.0 / rd;
    float3 tA   = (bmin - ro) * inv;
    float3 tB   = (bmax - ro) * inv;

    float3 tmin3 = min(tA, tB);
    float3 tmax3 = max(tA, tB);

    t0 = max(max(tmin3.x, tmin3.y), tmin3.z);
    t1 = min(min(tmax3.x, tmax3.y), tmax3.z);

    return t1 > max(t0, 0.0);
}

bool initDDA(
    float3 ro,
    float3 rd,
    out float tEnter,
    out float tExit,
    out int3 ip,
    out int3 stepI,
    out float3 tHit,
    out float3 tStep)
{
    float t0, t1;
    if (!rayBox(ro, rd, t0, t1))
    {
        tEnter = 0.0;
        tExit  = 0.0;
        ip     = int3(-1, -1, -1);
        stepI  = int3(0, 0, 0);
        tHit   = 0.0.xxx;
        tStep  = 0.0.xxx;
        return false;
    }

    tEnter = max(t0, 0.0);
    tExit  = t1;

    float3 pos = ro + rd * tEnter;
    pos += rd * 1e-4;

    ip = int3(floor(pos));
    ip = clamp(ip, int3(0,0,0), int3(ZS-1,ZS-1,ZS-1));

    stepI = int3(
        rd.x >= 0.0 ? 1 : -1,
        rd.y >= 0.0 ? 1 : -1,
        rd.z >= 0.0 ? 1 : -1);

    tStep = float3(
        abs(rd.x) > 1e-8 ? abs(1.0 / rd.x) : 1e30,
        abs(rd.y) > 1e-8 ? abs(1.0 / rd.y) : 1e30,
        abs(rd.z) > 1e-8 ? abs(1.0 / rd.z) : 1e30);

    float nextBx = (rd.x >= 0.0) ? float(ip.x + 1) : float(ip.x);
    float nextBy = (rd.y >= 0.0) ? float(ip.y + 1) : float(ip.y);
    float nextBz = (rd.z >= 0.0) ? float(ip.z + 1) : float(ip.z);

    tHit = float3(
        abs(rd.x) > 1e-8 ? tEnter + (nextBx - pos.x) / rd.x : 1e30,
        abs(rd.y) > 1e-8 ? tEnter + (nextBy - pos.y) / rd.y : 1e30,
        abs(rd.z) > 1e-8 ? tEnter + (nextBz - pos.z) / rd.z : 1e30);

    return true;
}

float ddaNextT(float3 tHit, float tExit)
{
    return min(min(tHit.x, tHit.y), min(tHit.z, tExit));
}

void ddaAdvance(inout int3 ip, int3 stepI, inout float3 tHit, float3 tStep)
{
    if (tHit.x <= tHit.y && tHit.x <= tHit.z)
    {
        ip.x += stepI.x;
        tHit.x += tStep.x;
    }
    else if (tHit.y <= tHit.z)
    {
        ip.y += stepI.y;
        tHit.y += tStep.y;
    }
    else
    {
        ip.z += stepI.z;
        tHit.z += tStep.z;
    }
}

// ============================================================
// Hover / pick / pulse
// ============================================================

bool isHoverVoxel(int3 p)
{
    int4 s = Hover[0];
    return s.w != 0 && all(p == s.xyz);
}

bool isPickedVoxel(int3 p)
{
    int4 s = Pick[0];
    return s.w != 0 && all(p == s.xyz);
}

bool findHoverVoxel(out int3 pick)
{
    uint W, H;
    screen.GetDimensions(W, H);
    float2 res = float2(W, H);

    float2 aimPos = getAimScreenPos();

    float3 ro, rd;
    makeFreeCamera(aimPos, res, ro, rd);

    // use the last fully completed visible pair before comb1
    int tim = (int(time.frame) + ZT) * ZF;
    int frA = ringBase(tim - 1);
    int frB = ringBase(tim - 2);

    float tEnter, tExit;
    int3 ip, stepI;
    float3 tHit, tStep;

    if (!initDDA(ro, rd, tEnter, tExit, ip, stepI, tHit, tStep))
    {
        pick = int3(-1, -1, -1);
        return false;
    }

    float t = tEnter;

    [loop]
    for (int i = 0; i < MAX_DDA_STEPS; ++i)
    {
        if (!voxelInBounds(ip) || t >= tExit)
            break;

        float m = manifoldAtVoxel(ip, frA, frB);
        if (m > PICK_THRESHOLD)
        {
            pick = ip;
            return true;
        }

        float tNext = ddaNextT(tHit, tExit);
        if (tNext <= t) break;

        t = tNext;
        ddaAdvance(ip, stepI, tHit, tStep);
    }

    pick = int3(-1, -1, -1);
    return false;
}

[DispatchOnce]
[WorkgroupCount(1,1,1)]
[shader("compute")]
[numthreads(1,1,1)]
void pointer_update(uint3 tid : SV_DispatchThreadID)
{
    if (ensureInitialized())
        return;

    int prevMouseDown = InputState[0].y;
    int currMouseDown = (mouse.click != 0) ? 1 : 0;
    bool mousePressed = (currMouseDown != 0) && (prevMouseDown == 0);

    int3 p;
    bool ok = findHoverVoxel(p);

    if (ok)
        Hover[0] = int4(p.x, p.y, p.z, 1);
    else
        Hover[0] = int4(-1, -1, -1, 0);

    int pulseFrames = Pulse[0].x;

    if (mousePressed && ok)
    {
        Pick[0] = int4(p.x, p.y, p.z, 1);
        pulseFrames = PULSE_FRAMES;
    }
    else if (pulseFrames > 0)
    {
        pulseFrames -= 1;
    }

    Pulse[0] = int4(pulseFrames, 0, 0, 0);
    InputState[0] = int4(InputState[0].x, currMouseDown, 0, 0);
}

// ============================================================
// Simulation
// ============================================================

[DispatchCount(ZF)]
[WorkgroupCount(GCX, GCY, GCZ)]
[shader("compute")]
[numthreads(WGX, WGY, WGZ)]
void comb1(uint3 tid : SV_DispatchThreadID)
{
    if (ensureInitialized())
        return;

    if (tid.x >= ZS || tid.y >= ZS || tid.z >= ZS) return;

    int tim   = (int(time.frame) + ZT) * ZF + int(dispatch.id);
    int frNew = ringBase(tim - 0);
    int frCur = ringBase(tim - 1);
    int frOld = ringBase(tim - 2);

    int3 p  = int3(tid);
    int idx = flatten3(p);

    // explicit one-time field seeding
    if (StateFlags[0].y == 0)
    {
        float3 pf = float3(p) + 0.5;
        float3 u = pf / float(ZS) - 0.5;
        float uu = dot(u, u);

        float d =
            rnd((uint)idx) * exp(-2222.0 * uu) +
            exp(-333.0 * uu);

        D[frNew + idx] = d;
        D[frCur + idx] = d;
        D[frOld + idx] = d;

        if (dispatch.id == 0 && all(tid == uint3(0,0,0)))
            StateFlags[0] = int4(1, 1, 0, 0);

        return;
    }

    float dOld = D[frOld + idx];

    float wByL2[(R * R) + 1];
    [unroll]
    for (int i = 0; i <= R * R; ++i)
        wByL2[i] = kernelFromL2(i);

    float accum = 0.0;
    float norm  = 0.0;

    [unroll]
    for (int z = -R; z <= R; ++z)
    {
        [unroll]
        for (int y = -R; y <= R; ++y)
        {
            [unroll]
            for (int x = -R; x <= R; ++x)
            {
                int l2 = x * x + y * y + z * z;
                if (l2 > R * R) continue;

                int3 q = int3(
                    wrap1(p.x + x, ZS),
                    wrap1(p.y + y, ZS),
                    wrap1(p.z + z, ZS));

                float d = D[frCur + flatten3(q)];
                float w = wByL2[l2];

                accum += d * fastAmp(d) * w;
                norm  += abs(w);
            }
        }
    }

    float outv = (norm > 0.0 ? accum / norm : 0.0) - dOld;

    // pulse emission only
    {
        int pulseFrames = Pulse[0].x;
        int4 ps = Pick[0];

        if (pulseFrames > 0 && ps.w != 0)
        {
            float pulseAmp = PICK_EMIT_GAIN * (float(pulseFrames) / float(PULSE_FRAMES));
            float3 dp = (float3(p) + 0.5) - (float3(ps.xyz) + 0.5);
            float r2 = dot(dp, dp);
            outv += pulseAmp * exp(-r2 / PICK_EMIT_SIGMA2);
        }
    }

    D[frNew + idx] = outv;
}

// ============================================================
// Rendering
// ============================================================

[shader("compute")]
[numthreads(8,8,1)]
void main_image(uint3 tid : SV_DispatchThreadID)
{
    if (ensureInitialized())
    {
        if (tid.x == 0 && tid.y == 0)
            screen[int2(0,0)] = float4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    uint W, H;
    screen.GetDimensions(W, H);

    if (tid.x >= W || tid.y >= H) return;

    float2 res  = float2(W, H);
    float2 frag = float2(tid.xy);

    int tim = (int(time.frame) + ZT) * ZF;
    int fr1 = ringBase(tim - 0);
    int fr2 = ringBase(tim - 1);

    float3 ro, rd;
    makeFreeCamera(frag, res, ro, rd);

    float tEnter, tExit;
    int3 ip, stepI;
    float3 tHit, tStep;

    float3 col = 0.0.xxx;

    if (initDDA(ro, rd, tEnter, tExit, ip, stepI, tHit, tStep))
    {
        float t = tEnter;

        [loop]
        for (int i = 0; i < MAX_DDA_STEPS; ++i)
        {
            if (!voxelInBounds(ip) || t >= tExit)
                break;

            float tNext  = ddaNextT(tHit, tExit);
            float segLen = max(tNext - t, 0.0);

            int idx = flatten3(ip);
            float a = D[fr1 + idx];
            float b = D[fr2 + idx];
            float tl = sqrt(a * a + b * b);

            float3 stepCol;

            if (isPickedVoxel(ip))
            {
                float pulseBoost = 0.0;
                int pulseFrames = Pulse[0].x;
                if (pulseFrames > 0)
                    pulseBoost = 2.0 * (float(pulseFrames) / float(PULSE_FRAMES));

                stepCol = float3(3.0 + pulseBoost, 0.0, 0.0);
            }
            else if (isHoverVoxel(ip))
            {
                stepCol = float3(1.4, 0.5, 0.1);
            }
            else
            {
                float absorb = saturate1(tl * segLen * DENSITY_STRENGTH);
                float dens   = tl * absorb;

                float3 posMid = ro + rd * (t + 0.5 * segLen);
                float occ      = saturate1((tl - OCC_THRESH) / max(OCC_THRESH, 1e-5));
                float edgeMask = voxelEdgeMask(posMid, EDGE_WIDTH) * occ;
                float edge     = edgeMask * EDGE_STRENGTH * segLen;

                float v = dens + edge;
                stepCol = float3(v, v, v);
            }

            col += stepCol;

            t = tNext;
            ddaAdvance(ip, stepI, tHit, tStep);
        }
    }

    col = pow(toneMap(col), float3(GAMMA, GAMMA, GAMMA));
    screen[tid.xy] = float4(col, 1.0);
}
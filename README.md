# Fox Unity

Standalone Unity 6.3 project (Editor 6000.3.10f1).

Open this folder in Unity Hub. Main scene: Assets/Scenes/main.unity.
The Gaussian renderer and both scenes use the retained gs_Maya_s_Beach
asset and its four binary components. Other splat datasets were removed.

Large binary files (*.bytes, *.fbx) use Git LFS; install Git LFS
and run git lfs pull after cloning. Unity Library, Temp, Logs, and
UserSettings are generated locally and are not committed.

The local GaussianSplatting package is by Aras Pranckevicius;
see GaussianSplatting/LICENSE.md (MIT license).
Keep Unity .meta files alongside their assets to retain GUID references.
